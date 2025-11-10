#!/usr/bin/env python3
import json
import glob
import os

# Find all channel location files
chanloc_files = glob.glob("chanlocs/sub*_channel_loc.txt")

for chanloc_file in chanloc_files:
    # Extract subject number from filename (e.g., sub002 from sub002_channel_loc.txt)
    subject_no_hyphen = os.path.basename(chanloc_file).split('_')[0]  # e.g., 'sub002'
    # Convert to hyphenated format (sub002 -> sub-002)
    subject = subject_no_hyphen[:3] + '-' + subject_no_hyphen[3:]  # e.g., 'sub-002'

    # Read the channel location file and find fiducial coordinates
    fiducials = {}
    with open(chanloc_file, 'r') as f:
        for line in f:
            parts = line.strip().split()
            if len(parts) >= 5:
                label = parts[4]
                if label in ['LPA', 'RPA', 'nazion']:
                    x = float(parts[1])
                    y = float(parts[2])
                    z = float(parts[3])

                    # Transform: multiply by 100, then newx = y, newy = -x
                    new_x = round(y * 100, 4)
                    new_y = round(-x * 100, 4)
                    new_z = round(z * 100, 4)

                    # Store with correct label (nazion -> Nasion)
                    if label == 'nazion':
                        fiducials['Nasion'] = [new_x, new_y, new_z]
                    else:
                        fiducials[label] = [new_x, new_y, new_z]

    # Find and update the corresponding coordsystem JSON file
    coordsystem_file = f"ds002718/{subject}/{subject}_task-FaceRecognition_coordsystem.json"

    if os.path.exists(coordsystem_file):
        # Save backup of original file
        backup_file = coordsystem_file.replace('.json', '_backup.json')
        with open(coordsystem_file, 'r') as f:
            backup_data = f.read()
        with open(backup_file, 'w') as f:
            f.write(backup_data)

        # Read the JSON file
        with open(coordsystem_file, 'r') as f:
            data = json.load(f)

        # Update the anatomical landmark coordinates
        data['AnatomicalLandmarkCoordinates'] = fiducials

        # Write back to the file
        with open(coordsystem_file, 'w') as f:
            json.dump(data, f, indent=2)

        print(f"Updated: {coordsystem_file}")
        print(f"  LPA: {fiducials.get('LPA')}")
        print(f"  RPA: {fiducials.get('RPA')}")
        print(f"  Nasion: {fiducials.get('Nasion')}")
    else:
        print(f"Warning: {coordsystem_file} not found")

print(f"\nDone!")
