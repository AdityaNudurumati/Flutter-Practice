# 30 · Google Maps

## Introduction

This module covers embedding and driving **Google Maps** in Flutter with `google_maps_flutter`: **setup** (API keys per platform, the `GoogleMap` widget, `GoogleMapController`), **overlays** (markers, polylines, polygons, circles, info windows), **camera control** (move/animate, bounds, gestures), and advanced patterns — **custom markers, live location on the map, and clustering** for large datasets. It builds on device location ([Module 29](../29%20Device%20Features/geolocation.md)) and platform views ([Module 27](../27%20Native%20Android/platform_views_android.md)/[28](../28%20Native%20iOS/platform_views_ios.md)).

## Why this module exists

Maps power delivery, ride-hailing, real estate, fitness, and "near me" apps. `google_maps_flutter` embeds a native map via platform views — powerful but with real costs (API keys/billing, compositing, marker/state management). You must set it up per platform, manage overlays and camera imperatively via a controller, and scale to thousands of markers without jank.

## Module map

| # | File | Topic | Level |
|---|------|-------|-------|
| 1 | [maps_setup_and_widget.md](maps_setup_and_widget.md) | API keys, `GoogleMap` widget, `GoogleMapController`, camera position | 🔵 |
| 2 | [markers_and_overlays.md](markers_and_overlays.md) | Markers, polylines, polygons, circles, info windows | 🔵 |
| 3 | [camera_control.md](camera_control.md) | Move/animate camera, bounds, zoom, gestures, map styling | 🟡 |
| 4 | [live_location_and_clustering.md](live_location_and_clustering.md) | Custom markers, live location, marker clustering at scale | 🔴 |
| 5 | [maps_integration.md](maps_integration.md) | Capstone: map behind a controller/repository, live tracking | 🔴 |

> **Cross-references:** Location source: [29 · geolocation](../29%20Device%20Features/geolocation.md). Platform views (how the map embeds): [27](../27%20Native%20Android/platform_views_android.md)/[28](../28%20Native%20iOS/platform_views_ios.md). Compositing cost: [09 · compositing](../09%20Rendering%20Pipeline/compositing_and_repaint_boundaries.md). Performance: [Module 21](../21%20Performance/README.md). State management: [Module 11](../11%20State%20Management/README.md).

## Prerequisites

[29 Device Features](../29%20Device%20Features/README.md) (geolocation), platform-view basics ([27](../27%20Native%20Android/README.md)/[28](../28%20Native%20iOS/README.md)), [11 State Management](../11%20State%20Management/README.md) (managing marker/camera state).

## What you'll be able to do after this module

- Set up Google Maps with per-platform API keys and embed the `GoogleMap` widget.
- Add and update markers, polylines, polygons, circles, and info windows.
- Control the camera (move/animate, fit bounds, zoom) and style the map.
- Render custom markers, show live user location, and cluster thousands of points.
- Wrap the map behind a controller/repository for clean, testable state.

## Capstone

**Live map slice:** A map that shows the user's live location (from [Module 29](../29%20Device%20Features/geolocation.md)), plots many place markers with clustering, draws a route polyline, animates the camera to fit results/follow the user, and surfaces marker taps — with all map state driven through a controller/repository.

## Summary

Google Maps in Flutter = a native map embedded via platform views, driven imperatively through a `GoogleMapController`: set up keys, manage overlays (markers/lines/shapes), control the camera, and scale with custom markers + clustering. Wrap it behind a controller/repository and mind the compositing/billing costs.
