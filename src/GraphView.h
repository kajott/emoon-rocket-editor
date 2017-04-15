#pragma once

#include <stdint.h>

struct TrackData;
struct TrackViewInfo;

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

typedef struct GraphSettings
{
	uint32_t borderColor; 
	uint32_t curveColor;

	int singleTrack;
} GraphSettings;

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

typedef struct Rect
{
	int x;
	int y;
	int width;
	int height;
} Rect;

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

typedef struct GraphView
{
	const struct TrackData* activeTrack;
	Rect rect;
} GraphView;
