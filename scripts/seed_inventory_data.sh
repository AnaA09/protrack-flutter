#!/bin/bash

# Seed sample inventory data for testing
REGION="us-east-1"
TABLE_NAME="Instruments"

echo "🌱 Seeding sample inventory data..."

# Generate UUIDs for consistent references
LAB1_ID=$(uuidgen | tr '[:upper:]' '[:lower:]')
LAB2_ID=$(uuidgen | tr '[:upper:]' '[:lower:]')
LAB3_ID=$(uuidgen | tr '[:upper:]' '[:lower:]')

# Chemistry Lab Categories
CHEM_INSTRUMENTS_ID=$(uuidgen | tr '[:upper:]' '[:lower:]')
CHEM_CHEMICALS_ID=$(uuidgen | tr '[:upper:]' '[:lower:]')

# Biology Lab Categories  
BIO_INSTRUMENTS_ID=$(uuidgen | tr '[:upper:]' '[:lower:]')
BIO_CHEMICALS_ID=$(uuidgen | tr '[:upper:]' '[:lower:]')
BIO_CULTURES_ID=$(uuidgen | tr '[:upper:]' '[:lower:]')

# Physics Lab Categories
PHYS_INSTRUMENTS_ID=$(uuidgen | tr '[:upper:]' '[:lower:]')

echo "Creating Labs..."

# Lab 1: Chemistry Lab
aws dynamodb put-item \
    --region $REGION \
    --table-name $TABLE_NAME \
    --item '{
        "instrumentId": {"S": "'$LAB1_ID'"},
        "type": {"S": "LAB"},
        "labId": {"S": "'$LAB1_ID'"},
        "name": {"S": "Advanced Chemistry Laboratory"},
        "description": {"S": "State-of-the-art chemistry lab for analytical and organic chemistry research"},
        "location": {"S": "Building A, Floor 3, Room 301"},
        "createdAt": {"S": "'$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")'"},
        "updatedAt": {"S": "'$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")'"},
        "status": {"S": "ACTIVE"}
    }'

# Lab 2: Biology Lab
aws dynamodb put-item \
    --region $REGION \
    --table-name $TABLE_NAME \
    --item '{
        "instrumentId": {"S": "'$LAB2_ID'"},
        "type": {"S": "LAB"},
        "labId": {"S": "'$LAB2_ID'"},
        "name": {"S": "Molecular Biology Laboratory"},
        "description": {"S": "Specialized facility for molecular biology, genetics, and microbiology research"},
        "location": {"S": "Building B, Floor 2, Room 205"},
        "createdAt": {"S": "'$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")'"},
        "updatedAt": {"S": "'$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")'"},
        "status": {"S": "ACTIVE"}
    }'

# Lab 3: Physics Lab
aws dynamodb put-item \
    --region $REGION \
    --table-name $TABLE_NAME \
    --item '{
        "instrumentId": {"S": "'$LAB3_ID'"},
        "type": {"S": "LAB"},
        "labId": {"S": "'$LAB3_ID'"},
        "name": {"S": "Materials Physics Laboratory"},
        "description": {"S": "Research facility for materials science and condensed matter physics"},
        "location": {"S": "Building C, Floor 1, Room 101"},
        "createdAt": {"S": "'$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")'"},
        "updatedAt": {"S": "'$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")'"},
        "status": {"S": "ACTIVE"}
    }'

echo "Creating Categories..."

# Chemistry Lab - Instruments Category
aws dynamodb put-item \
    --region $REGION \
    --table-name $TABLE_NAME \
    --item '{
        "instrumentId": {"S": "'$CHEM_INSTRUMENTS_ID'"},
        "type": {"S": "CATEGORY"},
        "labId": {"S": "'$LAB1_ID'"},
        "categoryId": {"S": "'$CHEM_INSTRUMENTS_ID'"},
        "name": {"S": "Analytical Instruments"},
        "categoryType": {"S": "INSTRUMENTS"},
        "description": {"S": "Precision instruments for chemical analysis and measurement"},
        "createdAt": {"S": "'$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")'"},
        "updatedAt": {"S": "'$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")'"},
        "status": {"S": "ACTIVE"}
    }'

# Chemistry Lab - Chemicals Category
aws dynamodb put-item \
    --region $REGION \
    --table-name $TABLE_NAME \
    --item '{
        "instrumentId": {"S": "'$CHEM_CHEMICALS_ID'"},
        "type": {"S": "CATEGORY"},
        "labId": {"S": "'$LAB1_ID'"},
        "categoryId": {"S": "'$CHEM_CHEMICALS_ID'"},
        "name": {"S": "Chemical Reagents"},
        "categoryType": {"S": "CHEMICALS"},
        "description": {"S": "High-purity chemicals and reagents for synthesis and analysis"},
        "createdAt": {"S": "'$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")'"},
        "updatedAt": {"S": "'$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")'"},
        "status": {"S": "ACTIVE"}
    }'

# Biology Lab - Instruments Category
aws dynamodb put-item \
    --region $REGION \
    --table-name $TABLE_NAME \
    --item '{
        "instrumentId": {"S": "'$BIO_INSTRUMENTS_ID'"},
        "type": {"S": "CATEGORY"},
        "labId": {"S": "'$LAB2_ID'"},
        "categoryId": {"S": "'$BIO_INSTRUMENTS_ID'"},
        "name": {"S": "Laboratory Equipment"},
        "categoryType": {"S": "INSTRUMENTS"},
        "description": {"S": "Essential equipment for biological research and analysis"},
        "createdAt": {"S": "'$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")'"},
        "updatedAt": {"S": "'$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")'"},
        "status": {"S": "ACTIVE"}
    }'

# Biology Lab - Chemicals Category
aws dynamodb put-item \
    --region $REGION \
    --table-name $TABLE_NAME \
    --item '{
        "instrumentId": {"S": "'$BIO_CHEMICALS_ID'"},
        "type": {"S": "CATEGORY"},
        "labId": {"S": "'$LAB2_ID'"},
        "categoryId": {"S": "'$BIO_CHEMICALS_ID'"},
        "name": {"S": "Biochemical Reagents"},
        "categoryType": {"S": "CHEMICALS"},
        "description": {"S": "Specialized chemicals for biological and biochemical applications"},
        "createdAt": {"S": "'$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")'"},
        "updatedAt": {"S": "'$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")'"},
        "status": {"S": "ACTIVE"}
    }'

# Biology Lab - Cultures Category
aws dynamodb put-item \
    --region $REGION \
    --table-name $TABLE_NAME \
    --item '{
        "instrumentId": {"S": "'$BIO_CULTURES_ID'"},
        "type": {"S": "CATEGORY"},
        "labId": {"S": "'$LAB2_ID'"},
        "categoryId": {"S": "'$BIO_CULTURES_ID'"},
        "name": {"S": "Microbial Cultures"},
        "categoryType": {"S": "CULTURES"},
        "description": {"S": "Live bacterial, fungal, and cell cultures for research"},
        "createdAt": {"S": "'$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")'"},
        "updatedAt": {"S": "'$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")'"},
        "status": {"S": "ACTIVE"}
    }'

# Physics Lab - Instruments Category
aws dynamodb put-item \
    --region $REGION \
    --table-name $TABLE_NAME \
    --item '{
        "instrumentId": {"S": "'$PHYS_INSTRUMENTS_ID'"},
        "type": {"S": "CATEGORY"},
        "labId": {"S": "'$LAB3_ID'"},
        "categoryId": {"S": "'$PHYS_INSTRUMENTS_ID'"},
        "name": {"S": "Measurement Devices"},
        "categoryType": {"S": "INSTRUMENTS"},
        "description": {"S": "Precision instruments for physics measurements and experiments"},
        "createdAt": {"S": "'$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")'"},
        "updatedAt": {"S": "'$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")'"},
        "status": {"S": "ACTIVE"}
    }'

echo "Creating Entries..."

# Chemistry Lab - Instruments
aws dynamodb put-item \
    --region $REGION \
    --table-name $TABLE_NAME \
    --item '{
        "instrumentId": {"S": "'$(uuidgen | tr [:upper:] [:lower:])'"},
        "type": {"S": "ENTRY"},
        "categoryId": {"S": "'$CHEM_INSTRUMENTS_ID'"},
        "labId": {"S": "'$LAB1_ID'"},
        "entryId": {"S": "'$(uuidgen | tr [:upper:] [:lower:])'"},
        "name": {"S": "HPLC System"},
        "model": {"S": "Agilent 1260 Infinity II"},
        "manufacturer": {"S": "Agilent Technologies"},
        "serialNumber": {"S": "AG12345678"},
        "description": {"S": "High Performance Liquid Chromatography system for analytical separations"},
        "specifications": {"M": {
            "flowRate": {"S": "0.001-10 mL/min"},
            "pressure": {"S": "600 bar max"},
            "temperature": {"S": "4-80°C"}
        }},
        "quantity": {"N": "1"},
        "availableQuantity": {"N": "1"},
        "location": {"S": "Bench 3, Section A"},
        "calibrationDate": {"S": "'$(date -u +"%Y-%m-%d")'"},
        "maintenanceSchedule": {"S": "Quarterly"},
        "createdAt": {"S": "'$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")'"},
        "updatedAt": {"S": "'$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")'"},
        "status": {"S": "AVAILABLE"}
    }'

aws dynamodb put-item \
    --region $REGION \
    --table-name $TABLE_NAME \
    --item '{
        "instrumentId": {"S": "'$(uuidgen | tr [:upper:] [:lower:])'"},
        "type": {"S": "ENTRY"},
        "categoryId": {"S": "'$CHEM_INSTRUMENTS_ID'"},
        "labId": {"S": "'$LAB1_ID'"},
        "entryId": {"S": "'$(uuidgen | tr [:upper:] [:lower:])'"},
        "name": {"S": "FT-IR Spectrometer"},
        "model": {"S": "Bruker Alpha II"},
        "manufacturer": {"S": "Bruker Corporation"},
        "serialNumber": {"S": "BR98765432"},
        "description": {"S": "Fourier Transform Infrared Spectrometer for molecular identification"},
        "specifications": {"M": {
            "range": {"S": "4000-400 cm⁻¹"},
            "resolution": {"S": "0.5 cm⁻¹"},
            "detector": {"S": "DLaTGS"}
        }},
        "quantity": {"N": "1"},
        "availableQuantity": {"N": "1"},
        "location": {"S": "Bench 1, Section B"},
        "calibrationDate": {"S": "'$(date -u +"%Y-%m-%d")'"},
        "maintenanceSchedule": {"S": "Annual"},
        "createdAt": {"S": "'$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")'"},
        "updatedAt": {"S": "'$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")'"},
        "status": {"S": "AVAILABLE"}
    }'

# Chemistry Lab - Chemicals
aws dynamodb put-item \
    --region $REGION \
    --table-name $TABLE_NAME \
    --item '{
        "instrumentId": {"S": "'$(uuidgen | tr [:upper:] [:lower:])'"},
        "type": {"S": "ENTRY"},
        "categoryId": {"S": "'$CHEM_CHEMICALS_ID'"},
        "labId": {"S": "'$LAB1_ID'"},
        "entryId": {"S": "'$(uuidgen | tr [:upper:] [:lower:])'"},
        "name": {"S": "Sodium Chloride"},
        "model": {"S": "ACS Grade"},
        "manufacturer": {"S": "Sigma-Aldrich"},
        "serialNumber": {"S": "SA-NaCl-001"},
        "description": {"S": "High purity sodium chloride for analytical applications"},
        "specifications": {"M": {
            "purity": {"S": "≥99.5%"},
            "molecularWeight": {"S": "58.44 g/mol"},
            "cas": {"S": "7647-14-5"}
        }},
        "quantity": {"N": "5"},
        "availableQuantity": {"N": "5"},
        "location": {"S": "Chemical Storage, Shelf A2"},
        "createdAt": {"S": "'$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")'"},
        "updatedAt": {"S": "'$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")'"},
        "status": {"S": "AVAILABLE"}
    }'

aws dynamodb put-item \
    --region $REGION \
    --table-name $TABLE_NAME \
    --item '{
        "instrumentId": {"S": "'$(uuidgen | tr [:upper:] [:lower:])'"},
        "type": {"S": "ENTRY"},
        "categoryId": {"S": "'$CHEM_CHEMICALS_ID'"},
        "labId": {"S": "'$LAB1_ID'"},
        "entryId": {"S": "'$(uuidgen | tr [:upper:] [:lower:])'"},
        "name": {"S": "Acetonitrile"},
        "model": {"S": "HPLC Grade"},
        "manufacturer": {"S": "Fisher Scientific"},
        "serialNumber": {"S": "FS-ACN-002"},
        "description": {"S": "High purity acetonitrile for chromatographic applications"},
        "specifications": {"M": {
            "purity": {"S": "≥99.9%"},
            "waterContent": {"S": "≤0.003%"},
            "cas": {"S": "75-05-8"}
        }},
        "quantity": {"N": "3"},
        "availableQuantity": {"N": "2"},
        "location": {"S": "Solvent Cabinet, Section C"},
        "createdAt": {"S": "'$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")'"},
        "updatedAt": {"S": "'$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")'"},
        "status": {"S": "AVAILABLE"}
    }'

# Biology Lab - Instruments
aws dynamodb put-item \
    --region $REGION \
    --table-name $TABLE_NAME \
    --item '{
        "instrumentId": {"S": "'$(uuidgen | tr [:upper:] [:lower:])'"},
        "type": {"S": "ENTRY"},
        "categoryId": {"S": "'$BIO_INSTRUMENTS_ID'"},
        "labId": {"S": "'$LAB2_ID'"},
        "entryId": {"S": "'$(uuidgen | tr [:upper:] [:lower:])'"},
        "name": {"S": "Fluorescence Microscope"},
        "model": {"S": "Zeiss Axio Observer 7"},
        "manufacturer": {"S": "Carl Zeiss AG"},
        "serialNumber": {"S": "ZS11223344"},
        "description": {"S": "Advanced fluorescence microscope for live cell imaging"},
        "specifications": {"M": {
            "magnification": {"S": "10x-100x"},
            "illumination": {"S": "LED + HBO"},
            "camera": {"S": "sCMOS"}
        }},
        "quantity": {"N": "1"},
        "availableQuantity": {"N": "0"},
        "location": {"S": "Imaging Room, Station 1"},
        "calibrationDate": {"S": "'$(date -u +"%Y-%m-%d")'"},
        "maintenanceSchedule": {"S": "Semi-annual"},
        "createdAt": {"S": "'$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")'"},
        "updatedAt": {"S": "'$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")'"},
        "status": {"S": "IN_USE"}
    }'

aws dynamodb put-item \
    --region $REGION \
    --table-name $TABLE_NAME \
    --item '{
        "instrumentId": {"S": "'$(uuidgen | tr [:upper:] [:lower:])'"},
        "type": {"S": "ENTRY"},
        "categoryId": {"S": "'$BIO_INSTRUMENTS_ID'"},
        "labId": {"S": "'$LAB2_ID'"},
        "entryId": {"S": "'$(uuidgen | tr [:upper:] [:lower:])'"},
        "name": {"S": "PCR Thermal Cycler"},
        "model": {"S": "Bio-Rad T100"},
        "manufacturer": {"S": "Bio-Rad Laboratories"},
        "serialNumber": {"S": "BR55667788"},
        "description": {"S": "Thermal cycler for DNA amplification and qPCR"},
        "specifications": {"M": {
            "blocks": {"S": "2 x 96-well"},
            "tempRange": {"S": "4-100°C"},
            "rampRate": {"S": "5°C/s max"}
        }},
        "quantity": {"N": "2"},
        "availableQuantity": {"N": "2"},
        "location": {"S": "PCR Station, Bench 2"},
        "calibrationDate": {"S": "'$(date -u +"%Y-%m-%d")'"},
        "maintenanceSchedule": {"S": "Annual"},
        "createdAt": {"S": "'$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")'"},
        "updatedAt": {"S": "'$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")'"},
        "status": {"S": "AVAILABLE"}
    }'

# Biology Lab - Chemicals
aws dynamodb put-item \
    --region $REGION \
    --table-name $TABLE_NAME \
    --item '{
        "instrumentId": {"S": "'$(uuidgen | tr [:upper:] [:lower:])'"},
        "type": {"S": "ENTRY"},
        "categoryId": {"S": "'$BIO_CHEMICALS_ID'"},
        "labId": {"S": "'$LAB2_ID'"},
        "entryId": {"S": "'$(uuidgen | tr [:upper:] [:lower:])'"},
        "name": {"S": "Taq DNA Polymerase"},
        "model": {"S": "High Fidelity"},
        "manufacturer": {"S": "New England Biolabs"},
        "serialNumber": {"S": "NEB-TAQ-003"},
        "description": {"S": "Thermostable DNA polymerase for PCR amplification"},
        "specifications": {"M": {
            "concentration": {"S": "5 U/μL"},
            "storage": {"S": "-20°C"},
            "bufferSystem": {"S": "Standard Taq Buffer"}
        }},
        "quantity": {"N": "10"},
        "availableQuantity": {"N": "8"},
        "location": {"S": "Enzyme Freezer, Box 3"},
        "createdAt": {"S": "'$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")'"},
        "updatedAt": {"S": "'$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")'"},
        "status": {"S": "AVAILABLE"}
    }'

# Biology Lab - Cultures
aws dynamodb put-item \
    --region $REGION \
    --table-name $TABLE_NAME \
    --item '{
        "instrumentId": {"S": "'$(uuidgen | tr [:upper:] [:lower:])'"},
        "type": {"S": "ENTRY"},
        "categoryId": {"S": "'$BIO_CULTURES_ID'"},
        "labId": {"S": "'$LAB2_ID'"},
        "entryId": {"S": "'$(uuidgen | tr [:upper:] [:lower:])'"},
        "name": {"S": "E. coli DH5α"},
        "model": {"S": "Competent Cells"},
        "manufacturer": {"S": "Invitrogen"},
        "serialNumber": {"S": "INV-DH5-004"},
        "description": {"S": "Chemically competent E. coli cells for cloning applications"},
        "specifications": {"M": {
            "competency": {"S": "1 x 10⁸ cfu/μg"},
            "genotype": {"S": "F- endA1 glnV44 thi-1 recA1 relA1 gyrA96 deoR nupG"},
            "storage": {"S": "-80°C"}
        }},
        "quantity": {"N": "20"},
        "availableQuantity": {"N": "15"},
        "location": {"S": "-80°C Freezer, Rack 2"},
        "createdAt": {"S": "'$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")'"},
        "updatedAt": {"S": "'$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")'"},
        "status": {"S": "AVAILABLE"}
    }'

aws dynamodb put-item \
    --region $REGION \
    --table-name $TABLE_NAME \
    --item '{
        "instrumentId": {"S": "'$(uuidgen | tr [:upper:] [:lower:])'"},
        "type": {"S": "ENTRY"},
        "categoryId": {"S": "'$BIO_CULTURES_ID'"},
        "labId": {"S": "'$LAB2_ID'"},
        "entryId": {"S": "'$(uuidgen | tr [:upper:] [:lower:])'"},
        "name": {"S": "HeLa Cells"},
        "model": {"S": "CCL-2"},
        "manufacturer": {"S": "ATCC"},
        "serialNumber": {"S": "ATCC-HELA-005"},
        "description": {"S": "Human cervical cancer cell line for research applications"},
        "specifications": {"M": {
            "morphology": {"S": "Epithelial"},
            "medium": {"S": "DMEM + 10% FBS"},
            "passage": {"S": "P15-P25"}
        }},
        "quantity": {"N": "5"},
        "availableQuantity": {"N": "3"},
        "location": {"S": "Cell Culture Incubator 2"},
        "createdAt": {"S": "'$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")'"},
        "updatedAt": {"S": "'$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")'"},
        "status": {"S": "AVAILABLE"}
    }'

# Physics Lab - Instruments
aws dynamodb put-item \
    --region $REGION \
    --table-name $TABLE_NAME \
    --item '{
        "instrumentId": {"S": "'$(uuidgen | tr [:upper:] [:lower:])'"},
        "type": {"S": "ENTRY"},
        "categoryId": {"S": "'$PHYS_INSTRUMENTS_ID'"},
        "labId": {"S": "'$LAB3_ID'"},
        "entryId": {"S": "'$(uuidgen | tr [:upper:] [:lower:])'"},
        "name": {"S": "X-ray Diffractometer"},
        "model": {"S": "Rigaku MiniFlex 600"},
        "manufacturer": {"S": "Rigaku Corporation"},
        "serialNumber": {"S": "RG99887766"},
        "description": {"S": "Benchtop X-ray diffractometer for crystalline material analysis"},
        "specifications": {"M": {
            "xraySource": {"S": "Cu Kα (40 kV, 15 mA)"},
            "detector": {"S": "D/teX Ultra 250"},
            "resolution": {"S": "0.02° 2θ"}
        }},
        "quantity": {"N": "1"},
        "availableQuantity": {"N": "1"},
        "location": {"S": "XRD Room, Station A"},
        "calibrationDate": {"S": "'$(date -u +"%Y-%m-%d")'"},
        "maintenanceSchedule": {"S": "Quarterly"},
        "createdAt": {"S": "'$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")'"},
        "updatedAt": {"S": "'$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")'"},
        "status": {"S": "AVAILABLE"}
    }'

aws dynamodb put-item \
    --region $REGION \
    --table-name $TABLE_NAME \
    --item '{
        "instrumentId": {"S": "'$(uuidgen | tr [:upper:] [:lower:])'"},
        "type": {"S": "ENTRY"},
        "categoryId": {"S": "'$PHYS_INSTRUMENTS_ID'"},
        "labId": {"S": "'$LAB3_ID'"},
        "entryId": {"S": "'$(uuidgen | tr [:upper:] [:lower:])'"},
        "name": {"S": "AFM System"},
        "model": {"S": "Park NX10"},
        "manufacturer": {"S": "Park Systems"},
        "serialNumber": {"S": "PS44556677"},
        "description": {"S": "Atomic Force Microscope for nanoscale surface characterization"},
        "specifications": {"M": {
            "resolution": {"S": "0.1 nm (vertical)"},
            "scanRange": {"S": "100 × 100 μm"},
            "modes": {"S": "Contact, Non-contact, Tapping"}
        }},
        "quantity": {"N": "1"},
        "availableQuantity": {"N": "0"},
        "location": {"S": "Clean Room, AFM Station"},
        "calibrationDate": {"S": "'$(date -u +"%Y-%m-%d")'"},
        "maintenanceSchedule": {"S": "Monthly"},
        "createdAt": {"S": "'$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")'"},
        "updatedAt": {"S": "'$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")'"},
        "status": {"S": "MAINTENANCE"}
    }'

echo "✅ Sample inventory data seeded successfully!"
echo ""
echo "📊 Summary:"
echo "   Labs created: 3"
echo "   Categories created: 6"
echo "   Entries created: 12"
echo ""
echo "🏢 Labs:"
echo "   1. Advanced Chemistry Laboratory (Building A, Floor 3)"
echo "   2. Molecular Biology Laboratory (Building B, Floor 2)"
echo "   3. Materials Physics Laboratory (Building C, Floor 1)"
echo ""
echo "📱 You can now test the inventory system in your Flutter app!" 