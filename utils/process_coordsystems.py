#!/usr/bin/env python3
import json
import glob
import os

# Find all coordsystem.json files in ds002718 subject folders
coordsystem_files = glob.glob("ds002718/sub-*/*_coordsystem.json")

for filepath in coordsystem_files:
    # Read the JSON file
    with open(filepath, 'r') as f:
        data = json.load(f)

    # Extract only the 3 required fields
    new_data = {
        "EEGCoordinateUnits": "cm",
        "EEGCoordinateSystem": "EEGLAB",
        "AnatomicalLandmarkCoordinates": {}
    }

    # Transform the anatomical landmark coordinates
    if "AnatomicalLandmarkCoordinates" in data:
        for label, coords in data["AnatomicalLandmarkCoordinates"].items():
            x, y, z = coords
            # Divide by 10, then: new_y = old_x, new_x = -old_y, new_z = old_z
            new_x = y / 10.0
            new_y = -x / 10.0
            new_z = z / 10.0
            new_data["AnatomicalLandmarkCoordinates"][label] = [new_x, new_y, new_z]

    # Write back to the same file
    with open(filepath, 'w') as f:
        json.dump(new_data, f, indent=2)

    print(f"Processed: {filepath}")

print(f"\nTotal files processed: {len(coordsystem_files)}")
