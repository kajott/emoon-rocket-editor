module(..., package.seeall)

local nodegen  = require "tundra.nodegen"
local boot     = require "tundra.boot"
local util     = require "tundra.util"
local path     = require "tundra.path"
local scanner  = require "tundra.scanner"
local depgraph = require "tundra.depgraph"

local scanner_cache = {}

function get_cpp_scanner(env, fn)
  local paths = util.map(env:get_list("CPPPATH"), function (v) return env:interpolate(v) end)
  return scanner.make_cpp_scanner(paths)
end

-- Register implicit make functions for C, C++ and Objective-C files.
-- These functions are called to transform source files in unit lists into
-- object files. This function is registered as a setup function so it will be
-- run after user modifications to the environment, but before nodes are
-- processed. This way users can override the extension lists.
local function generic_cpp_setup(env)
  local _anyc_compile = function(env, pass, fn, label, action)
    local object_fn = path.make_object_filename(env, fn, '$(OBJECTSUFFIX)')

    local output_files = { object_fn }

    local pch_source = env:get('_PCH_SOURCE', '')
    local implicit_inputs = nil
    
    if fn == pch_source then
      
      label = 'Precompiled header'
      pass = nodegen.resolve_pass(env:get('_PCH_PASS', ''))
      action = "$(PCHCOMPILE)"
      output_files = { "$(_PCH_FILE)", object_fn }

    elseif pch_source ~= '' and fn ~= pch_source then

      -- It would be good to make all non-pch source files dependent upon the .pch node.
      -- That would require that we generate the .pch node before generating these nodes.
      -- As it stands presently, when .pch compilation fails, the remaining sources
      -- fail to compile, but if the dependencies were correctly setup, then they wouldn't
      -- even try to compile.
      
    end

    return depgraph.make_node {
      Env            = env,
      Label          = label .. ' $(<)',
      Pass           = pass,
      Action         = action,
      InputFiles     = { fn },
      OutputFiles    = output_files,
      ImplicitInputs = implicit_inputs,
      Scanner        = get_cpp_scanner(env, fn),
    }
  end

  local mappings = {
    ["CCEXTS"] = { Label="Cc", Action="$(CCCOM)" },
    ["CXXEXTS"] = { Label="C++", Action="$(CXXCOM)" },
    ["OBJCEXTS"] = { Label="ObjC", Action="$(OBJCCOM)" },
  }

  for key, setup in pairs(mappings) do
    for _, ext in ipairs(env:get_list(key)) do
      env:register_implicit_make_fn(ext, function(env, pass, fn)
        return _anyc_compile(env, pass, fn, setup.Label, setup.Action)
      end)
    end
  end
end

function apply(_outer_env, options)

  _outer_env:add_setup_function(generic_cpp_setup)

  _outer_env:set_many {
    ["IGNORED_AUTOEXTS"] = { ".h", ".hpp", ".hh", ".hxx", ".inl" },
    ["CCEXTS"] = { "c" },
    ["CXXEXTS"] = { "cpp", "cxx", "cc" },
    ["OBJCEXTS"] = { "m" },
    ["PROGSUFFIX"] = "$(HOSTPROGSUFFIX)",
    ["SHLIBSUFFIX"] = "$(HOSTSHLIBSUFFIX)",
    ["CPPPATH"] = "",
    ["CPPDEFS"] = "",
    ["LIBS"] = "",
    ["LIBPATH"] = "$(OBJECTDIR)",
    ["CCOPTS"] = "",
    ["CXXOPTS"] = "",
    ["CPPDEFS_DEBUG"] = "",
    ["CPPDEFS_PRODUCTION"] = "",
    ["CPPDEFS_RELEASE"] = "",
    ["CCOPTS_DEBUG"] = "",
    ["CCOPTS_PRODUCTION"] = "",
    ["CCOPTS_RELEASE"] = "",
    ["CXXOPTS_DEBUG"] = "",
    ["CXXOPTS_PRODUCTION"] = "",
    ["CXXOPTS_RELEASE"] = "",
    ["SHLIBLINKSUFFIX"] = "",
  }
end
