/**
 *Submitted for verification at Etherscan.io on 2022-12-26
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

//Uploaded By suhail khalifa
contract SupplyChain {
    // Struct definitions
    struct MedicalCompany {
        string name;
        string phone;
        address etheruemAddress;
        uint[] drugIds;
        uint[] packageIds;
    }
    struct Verifier {
        string name;
        string phone;
        address etheruemAddress;
    }
    struct Supplier {
        string name;
        string phone;
        address etheruemAddress;
        uint[] packageIds;
    }
    struct Hospital {
        string name;
        string phone;
        address etheruemAddress;
        uint[] packageIds;
    }
    struct Patient {
        string name;
        string phone;
        address etheruemAddress;
    }
    struct Drug {
        string name;
        uint id;
        uint packingNumber;
        string serialNumber;
        bool isVerified;
        address currentHolder;
        address verifiedBy;
    }
    struct DrugPackage {
        string name;
        uint id;
        Drug[] drugs;
        uint numberOfDrugsInPackage;
        string expirationDate;
        address currentHolder;
        address medicalCompanyAddress;
        address verifiedBy;
        bool isVerified;
    }

    // Mapping from Ethereum address to MedicalCompany
    mapping(address => MedicalCompany) public medicalCompanies;
    // Mapping from Ethereum address to Verifier
    mapping(address => Verifier) public verifiers;
    // Mapping from Ethereum address to Supplier
    mapping(address => Supplier) public suppliers;
    // Mapping from Ethereum address to Hospital
    mapping(address => Hospital) public hospitals;
    // Mapping from Ethereum address to Patient
    mapping(address => Patient) public patients;
    // Mapping from drug ID to Drug struct
    mapping(uint => Drug) public drugs;
    // Mapping from drug package ID to DrugPackage struct
    mapping(uint => DrugPackage) public drugPackages;
    // Mapping to store the verification queue
    mapping(uint256 => bool) public verificationQueue;
    // Mapping to store the verification queue
    mapping(uint256 => bool) public verificationPackageQueue;
    //  Events
    event AddedMedicalCompany(
        address indexed medicalCompanie,
        string name,
        string phone
    );
    event AddedVerifier(
        address indexed medicalCompanie,
        string name,
        string phone
    );
    event AddedSupplier(
        address indexed medicalCompanie,
        string name,
        string phone
    );
    event AddedHospital(
        address indexed medicalCompanie,
        string name,
        string phone
    );
    event AddedPatient(
        address indexed medicalCompanie,
        string name,
        string phone
    );
    event DrugAdded(address indexed medicalCompanie, uint drugId, string name);
    event DrugVerificationRequested(
        address indexed medicalCompanie,
        uint drugId
    );
    event DrugVerified(address indexed verifier, uint drugId);
    event DrugPackageCreated(
        address indexed medicalCompanie,
        uint drugId,
        uint NumberOfDrugsInPackage
    );
    event DrugPackageVerificationRequested(
        address indexed medicalCompanie,
        uint drugPackageId
    );
    event DrugPackageVerified(address indexed verifier, uint drugPackageId);
    event PackageSendRequest(
        address indexed from,
        address indexed to,
        uint drugPackageId
    );
    event PackageReceived(
        address indexed from,
        address indexed to,
        uint drugPackageId
    );
    // Admin address
    address public admin;

    // Constructor function to set the admin address
    constructor() {
        admin = msg.sender;
    }

    // Function to add a Patient to the supply chain system
    function addPatient(
        address _patientaddress,
        string memory _name,
        string memory _phone
    ) public {
        require(msg.sender == admin, "Only the admin can add patient.");
        Patient memory patient;
        patient.etheruemAddress = _patientaddress;
        patient.name = _name;
        patient.phone = _phone;
        patients[_patientaddress] = patient;
    }

    // Function to delete a Patient from the supply chain system
    function deletePatient(address etheruemAddress) public {
        require(msg.sender == admin, "Only the admin can delete patient.");
        delete patients[etheruemAddress];
    }

    // Function to add a Hospitals to the supply chain system
    function addHospital(
        address _hospitaladdress,
        string memory _name,
        string memory _phone
    ) public {
        require(msg.sender == admin, "Only the admin can add hospital.");
        Hospital memory hospital;
        hospital.etheruemAddress = _hospitaladdress;
        hospital.name = _name;
        hospital.phone = _phone;
        hospitals[_hospitaladdress] = hospital;
    }

    // Function to delete a Hospital from the supply chain system
    function deleteHospital(address etheruemAddress) public {
        require(msg.sender == admin, "Only the admin can delete hospital.");
        delete hospitals[etheruemAddress];
    }

    // Function to add a Suppliers to the supply chain system
    function addSupplier(
        address _supplieraddress,
        string memory _name,
        string memory _phone
    ) public {
        require(msg.sender == admin, "Only the admin can add supplier.");
        Supplier memory supplier;
        supplier.etheruemAddress = _supplieraddress;
        supplier.name = _name;
        supplier.phone = _phone;
        suppliers[_supplieraddress] = supplier;
    }

    // Function to delete a Supplier from the supply chain system
    function deleteSupplier(address etheruemAddress) public {
        require(msg.sender == admin, "Only the admin can delete supplier.");
        delete suppliers[etheruemAddress];
    }

    // Function to add a Verifier to the supply chain system
    function addVerifiers(
        address _verifieraddress,
        string memory _name,
        string memory _phone
    ) public {
        require(msg.sender == admin, "Only the admin can add verifier.");
        Verifier memory verifier;
        verifier.etheruemAddress = _verifieraddress;
        verifier.name = _name;
        verifier.phone = _phone;
        verifiers[_verifieraddress] = verifier;
    }

    // Function to delete a Verifier from the supply chain system
    function deleteVerifier(address etheruemAddress) public {
        require(msg.sender == admin, "Only the admin can delete verifier.");
        delete verifiers[etheruemAddress];
    }

    // Function to add a MedicalCompany to the supply chain system
    function addMedicalCompany(
        address _medicalCompanyaddress,
        string memory _name,
        string memory _phone
    ) public {
        require(
            msg.sender == admin,
            "Only the admin can add medicalCompanies."
        );
        MedicalCompany memory medicalCompany;
        medicalCompany.etheruemAddress = _medicalCompanyaddress;
        medicalCompany.name = _name;
        medicalCompany.phone = _phone;
        medicalCompanies[_medicalCompanyaddress] = medicalCompany;
        emit AddedMedicalCompany(_medicalCompanyaddress, _name, _phone);
    }

    // Function to delete a MedicalCompany from the supply chain system
    function deleteMedicalCompany(address etheruemAddress) public {
        require(
            msg.sender == admin,
            "Only the admin can delete medicalCompanies."
        );
        delete medicalCompanies[etheruemAddress];
    }

    // Function for a MedicalCompany to add a drug to their inventory
    function addDrug(
        string memory _name,
        uint _id,
        string memory _serialNumber
    ) public {
        require(
            msg.sender == medicalCompanies[msg.sender].etheruemAddress,
            "Only the manufacturers can add a drug."
        );
        Drug memory drug;
        drug.name = _name;
        drug.id = _id;
        drug.serialNumber = _serialNumber;
        drug.currentHolder = msg.sender;
        drug.isVerified = false;
        drugs[_id] = drug;
        //adding drug id to medicalCompanies drugs id
        medicalCompanies[msg.sender].drugIds.push(_id);
        emit DrugAdded(msg.sender, _id, _name);
    }

    // Function for a MedicalCompany to add a drugpackage to their inventory
    function createDrugPackage(
        string memory _name,
        uint256 _id,
        uint256 _drugId,
        uint256 _quantity,
        string memory _expirationDate
    ) public {
        require(
            medicalCompanies[msg.sender].etheruemAddress == msg.sender,
            "Only medicalCompanies can create drug packages."
        );
        require(
            drugs[_drugId].currentHolder == msg.sender,
            "This drug does not exist."
        );
        require(
            drugs[_drugId].isVerified == true,
            "This drug is not verified."
        );
        require(
            drugPackages[_id].id != _id,
            "A drug package with this ID already exists."
        );

        // Create an array of drugs from the same drug ID
        DrugPackage storage Package = drugPackages[_id];
        Package.id = _id;
        Package.name = _name;
        Package.numberOfDrugsInPackage = _quantity;
        Package.currentHolder = msg.sender;
        Package.medicalCompanyAddress = msg.sender;
        Package.isVerified = false;
        Package.expirationDate = _expirationDate;
        //add package details
        for (uint256 i = 0; i < _quantity; i++) {
            Package.drugs.push(
                Drug(
                    drugs[_drugId].name,
                    drugs[_drugId].id,
                    i,
                    drugs[_drugId].serialNumber,
                    drugs[_drugId].isVerified,
                    drugs[_drugId].verifiedBy,
                    msg.sender
                )
            );
        }
        emit DrugPackageCreated(msg.sender, _drugId, _quantity);
    }

    // Function for medicalCompanies to add a drug to the verification queue
    function requestDrugVerification(uint256 _id) public {
        require(
            medicalCompanies[msg.sender].etheruemAddress == msg.sender,
            "Only medicalCompanies can request verification."
        );
        require(drugs[_id].id == _id, "This drug does not exist.");
        require(
            drugs[_id].isVerified != true,
            "This drug has already been verified."
        );
        require(
            !verificationQueue[_id],
            "This drug is already in the verification queue."
        );
        verificationQueue[_id] = true;
        emit DrugVerificationRequested(msg.sender, _id);
    }

    // Function for verifiers to verify a drug
    function verifyDrug(uint256 _id) public {
        require(
            verifiers[msg.sender].etheruemAddress == msg.sender,
            "Only verifiers can verify drugs."
        );
        require(
            verificationQueue[_id],
            "This drug is not in the verification queue."
        );
        delete verificationQueue[_id];
        drugs[_id].isVerified = true;
        drugs[_id].verifiedBy = msg.sender;
        emit DrugVerified(msg.sender, _id);
    }

    // Function for medicalCompanies to add a drugPackage to the verification queue
    function requestDrugPackageVerification(uint256 _id) public {
        require(
            medicalCompanies[msg.sender].etheruemAddress == msg.sender,
            "Only medicalCompanies can request verification."
        );
        require(drugPackages[_id].id == _id, "This Package does not exist.");
        require(
            drugPackages[_id].isVerified != true,
            "This Package has already been verified."
        );
        require(
            !verificationPackageQueue[_id],
            "This Package is already in the verification queue."
        );
        verificationPackageQueue[_id] = true;
        emit DrugPackageVerificationRequested(msg.sender, _id);
    }

    // Function for verifiers to verify a drugPackage
    function verifyDrugPackage(uint256 _id) public {
        require(
            verifiers[msg.sender].etheruemAddress == msg.sender,
            "Only verifiers can verify Packagedrugs."
        );
        require(
            verificationPackageQueue[_id],
            "This Packagedrug is not in the verification queue."
        );
        delete verificationPackageQueue[_id];
        drugPackages[_id].isVerified = true;
        drugPackages[_id].verifiedBy = msg.sender;
        emit DrugPackageVerified(msg.sender, _id);
    }

    struct SendRequest {
        address from;
        address to;
        uint drugPackageId;
    }
    mapping(address => SendRequest) public sendRequests;

    function sendPackage(address _to, uint _drugPackageId) public {
        require(
            drugPackages[_drugPackageId].currentHolder == msg.sender,
            "send must be owner of the pacakage"
        );
        require(
            sendRequests[msg.sender].drugPackageId != _drugPackageId,
            "send request already exists for this package"
        );
        sendRequests[msg.sender] = SendRequest(msg.sender, _to, _drugPackageId);
        emit PackageSendRequest(msg.sender, _to, _drugPackageId);
    }

    function receivePackage(address _from, uint _drugPackageId) public {
        require(
            sendRequests[_from].to == msg.sender &&
                sendRequests[_from].drugPackageId == _drugPackageId,
            "Matching request not found"
        );
        drugPackages[_drugPackageId].currentHolder = msg.sender;
        if (_from == medicalCompanies[_from].etheruemAddress) {
            suppliers[msg.sender].packageIds.push(_drugPackageId);
        }
        if (_from == suppliers[_from].etheruemAddress) {
            hospitals[msg.sender].packageIds.push(_drugPackageId);
        }
        delete sendRequests[_from];
        emit PackageReceived(_from, msg.sender, _drugPackageId);
    }

    // Function for a patient to request a drug from a hospital

    // Function for a patient to receive a drug from a hospital

    // Adding Event For Each Function
}