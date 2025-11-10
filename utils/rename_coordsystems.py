#!/usr/bin/env python3
import glob
import os

# Find all coordsystem.json files in ds002718 subject folders
coordsystem_files = glob.glob("ds002718/sub-*/*_coordsystem.json")

for filepath in coordsystem_files:
    if "FacePerception" in filepath:
        new_filepath = filepath.replace("FacePerception", "FaceRecognition")
        os.rename(filepath, new_filepath)
        print(f"Renamed: {filepath} -> {new_filepath}")

print(f"\nDone!")
