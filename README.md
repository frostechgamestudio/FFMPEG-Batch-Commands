# FFMPEG Batch Commands

Efficient H.264 video processing with optimized quality-to-size ratio using two-process encoding (HEVC first pass). GIF encoding uses palette generation for best quality at minimal file size. PNG optimization with advanced dithering algorithms.

## Files
- `QueueEncodeGPU_Mp4.bat` - GPU-accelerated HEVC encoding and two-process H.264 encoding (two-process mean input to HEVC to H.264)
- `QueueEncode_Gif.bat` - Palette-optimized GIF creation
- `QueueEncode_TinyPng.bat` - Advanced PNG compression with dithering

*Note: GitHub Copilot assisted with command structure layout. All FFmpeg parameters are based on personal research and optimization.* 
