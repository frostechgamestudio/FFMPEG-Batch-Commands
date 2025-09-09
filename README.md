# FFMPEG Batch Commands

- Efficient H.264 video processing with optimized quality-to-size ratio using two-process encoding (HEVC first pass).
- The Encoding commands intented for archival purposes only, meaning not ment for live steaming.
- Extemetly slow encoding thats why you need to have a GPU to make this work (Nvidia, Intel and AMD)
- GIF And PNG encoding uses palette generation for best quality at minimal file size.

## Requirements:
 - Any one of Nvidia Cuda GPU Or Intel quick sync GPU Or AMD DX11 GPU
 - [FFMPEG](https://ffmpeg.org/download.html) v7.1.1
 - Windows OS to run batch command files as is. (though ffmpeg cammands used this scripts should get exact results on any ffmpeg supported platfroms).

## Files
- `QueueEncodeGPU_Mp4.bat` - GPU-accelerated HEVC encoding and two-process H.264 encoding (two-process mean input to HEVC to H.264)
- `QueueEncode_Gif.bat` - Palette-optimized GIF creation
- `QueueEncode_TinyPng.bat` - Palette-optimized PNG creation

*Note: GitHub Copilot assisted with command structure layout. But all FFmpeg parameters are based on personal research and optimization.* 
