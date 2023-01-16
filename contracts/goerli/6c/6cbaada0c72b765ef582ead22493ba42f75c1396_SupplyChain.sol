/**
 *Submitted for verification at Etherscan.io on 2023-01-16
*/

// SPDX-License-Identifier: Unlicense
// File: contracts/Structs.sol


pragma solidity ^0.8.17;

  // Struct definitions
  struct MedicalCompany {
    string name;
    string phone;
    address etheruemAddress;
    int id;
    uint[] drugIds;
    uint[] packageIds;
  }
  struct Verifier {
    string name;
    int id;
    string phone;
    address etheruemAddress;
  }
  struct Supplier {
    string name;
    int id;
    string phone;
    address etheruemAddress;
    uint[] packageIds;
  }
  struct Hospital {
    string name;
    int id;
    string phone;
    address etheruemAddress;
    uint[] packageIds;
  }
  struct Patient {
    string name;
    int id;
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
    address hospitalAddress;
    address verifiedBy;
    bool isVerified;
  }
  // send package request used by mdedical company , hospital , supplier
  struct SendRequest {
  address from;
  address to;
  uint drugPackageId;
}
  // Drug Request Model for a patient to receive a drug from a hospital
struct DrugRequest {
  address patient;
  address hospital;
  uint drugId;
  bool IsApproved;
  uint drugPackageId;  
  uint packaingNumber;
}

// File: contracts/SupplyChain.sol


pragma solidity ^0.8.17;


contract SupplyChain {
    // Mapping from Ethereum address to MedicalCompany
    mapping(address => MedicalCompany) public  medicalCompanies;
    address[] public medicalCompaniesList;
    // Mapping from Ethereum address to Verifier
    mapping(address => Verifier) public verifiers;
    address[] public verifiersList;
    // Mapping from Ethereum address to Supplier
    mapping(address => Supplier) public suppliers;
    address[] public suppliersList;
    // Mapping from Ethereum address to Hospital
    mapping(address => Hospital) public hospitals;
    address[] public hospitalsList;
    // Mapping from Ethereum address to Patient
    mapping(address => Patient) private patients;
    address[] public patientsList;
    // Mapping from drug ID to Drug struct
    mapping(uint => Drug) public  drugs;
    // Mapping from drug package ID to DrugPackage struct
    mapping(uint => DrugPackage) public drugPackages;
    // Mapping to store the verification queue
    mapping(uint => bool) public verificationQueue;
        // Mapping to store the verification queue
    mapping(uint => bool) public verificationPackageQueue;
    // drug packages request
    mapping(address => SendRequest) public sendRequests;
    // drugs requests 
    mapping(address => DrugRequest) private drugRequests;
      //  Events
    event AddedMedicalCompany(address indexed medicalCompanie,string name,string phone);
    event AddedVerifier(address indexed medicalCompanie,string name,string phone);
    event AddedSupplier(address indexed medicalCompanie,string name,string phone);
    event AddedHospital(address indexed medicalCompanie,string name,string phone);
    event AddedPatient(address indexed medicalCompanie,string name,string phone);
    event DrugAdded(address indexed medicalCompanie, uint drugId, string name);
    event DrugVerificationRequested(address indexed medicalCompanie,uint drugId);
    event DrugVerified(address indexed verifier,uint drugId);
    event DrugPackageCreated(address indexed medicalCompanie, uint drugId,uint NumberOfDrugsInPackage);
    event DrugPackageVerificationRequested(address indexed medicalCompanie,uint drugPackageId );
    event DrugPackageVerified(address indexed verifier,uint drugPackageId);
    event PackageSendRequest(address indexed from, address indexed to, uint drugPackageId);
    event PackageReceived(address indexed from, address indexed to, uint drugPackageId);
  // Transaction  Errors 
  error AccessDenied__OnlyAdmin();
  error AccessDenied__OnlyMedicalCompany();
  error AccessDenied__OnlyVerifier();
  error AccessDenied__OnlySupplier();
  error AccessDenied__OnlyPatient();
  error AccessDenied__OnlyHospital();
  error AccessDenied__OnlyCurrentHolder();
  error Drug__NotVerified();
  error Drug__AllreadyVerified();
  error Drug__NotEnoughQuantity();
  error Drug__NotFound();
  error Drug__Duplicate();
  error DrugPackage__NotVerified();
  error DrugPackage__AllreadyVerified();
  error DrugPackage__NotEnoughQuantity();
  error DrugPackage__NotFound();
  error DrugPackage__Duplicate();
  error Request__NotApproved();
  error Request__NotFound();
  error Request__Duplicate();
  // Admin address
  address public admin;

  // Constructor function to set the admin address
  constructor()  {
    admin = msg.sender;
  }
  // apply this to all entities and test them please
  // modify the other mapping then implement get functions

  
   // Function to add a Patient to the supply chain system
  function addPatient(address _patientaddress, string memory _name,  string memory _phone) public {
    if(msg.sender != admin)
   revert AccessDenied__OnlyAdmin();
    Patient memory patient;
    patient.etheruemAddress = _patientaddress;
    patient.name = _name;
    patient.phone = _phone;
    patients[_patientaddress] = patient;
    patientsList.push(_patientaddress);
    patient.id = int(patientsList.length -1 );
  }
    // Function to delete a Patient from the supply chain system
  function deletePatient(address etheruemAddress) public {
    if(msg.sender != admin)
   revert AccessDenied__OnlyAdmin();

    uint rowToDelete = uint(patients[etheruemAddress].id);
    address keyToMove   = patientsList[patientsList.length-1];
    patientsList[rowToDelete] = keyToMove;
    patients[keyToMove].id = int(rowToDelete);
    patientsList.pop();
  }
   // Function to add a Hospitals to the supply chain system
  function addHospital(address _hospitaladdress, string memory _name,  string memory _phone) public {
    if(msg.sender != admin)
   revert AccessDenied__OnlyAdmin();
    Hospital memory hospital;
    hospital.etheruemAddress = _hospitaladdress;
    hospital.name = _name;
    hospital.phone = _phone;
    hospitals[_hospitaladdress] = hospital;
    hospitalsList.push(_hospitaladdress);
    hospital.id = int(hospitalsList.length -1 );
  }
    // Function to delete a Hospital from the supply chain system
  function deleteHospital(address etheruemAddress) public {
    if(msg.sender != admin)
   revert AccessDenied__OnlyAdmin();
    //delete hospitals[etheruemAddress];
    uint rowToDelete = uint(hospitals[etheruemAddress].id);
    address keyToMove   = hospitalsList[hospitalsList.length-1];
    hospitalsList[rowToDelete] = keyToMove;
    hospitals[keyToMove].id = int(rowToDelete);
    hospitalsList.pop();

  }
 // Function to add a Suppliers to the supply chain system
  function addSupplier(address _supplieraddress, string memory _name,  string memory _phone) public {
    if(msg.sender != admin)
   revert AccessDenied__OnlyAdmin();
    Supplier memory supplier;
    supplier.etheruemAddress = _supplieraddress;
    supplier.name = _name;
    supplier.phone = _phone;
    suppliers[_supplieraddress] = supplier;
    suppliersList.push(_supplieraddress);
    supplier.id = int(suppliersList.length -1 );
  }
    // Function to delete a Supplier from the supply chain system
  function deleteSupplier(address etheruemAddress) public {
    if(msg.sender != admin)
   revert AccessDenied__OnlyAdmin();
    //delete suppliers[etheruemAddress];
    uint rowToDelete = uint(suppliers[etheruemAddress].id);
    address keyToMove   = suppliersList[suppliersList.length-1];
    suppliersList[rowToDelete] = keyToMove;
    suppliers[keyToMove].id = int(rowToDelete);
    suppliersList.pop();
  }
 // Function to add a Verifier to the supply chain system
  function addVerifiers(address _verifieraddress, string memory _name,  string memory _phone) public {
    if(msg.sender != admin)
   revert AccessDenied__OnlyAdmin();
    Verifier memory verifier;
    verifier.etheruemAddress = _verifieraddress;
    verifier.name = _name;
    verifier.phone = _phone;
    verifiers[_verifieraddress] = verifier;
    verifiersList.push(_verifieraddress);
    verifier.id = int(verifiersList.length -1 );
  }
    // Function to delete a Verifier from the supply chain system
  function deleteVerifier(address etheruemAddress) public {
    if(msg.sender != admin)
   revert AccessDenied__OnlyAdmin();
    //delete verifiers[etheruemAddress];
    uint rowToDelete = uint(verifiers[etheruemAddress].id);
    address keyToMove   = verifiersList[verifiersList.length-1];
    verifiersList[rowToDelete] = keyToMove;
    verifiers[keyToMove].id = int(rowToDelete);
    verifiersList.pop();
  }
 // Function to add a MedicalCompany to the supply chain system
  function addMedicalCompany(address _medicalCompanyaddress, string memory _name,  string memory _phone) public {
    if(msg.sender != admin)
   revert AccessDenied__OnlyAdmin();
    MedicalCompany memory medicalCompany;
    medicalCompany.etheruemAddress = _medicalCompanyaddress;
    medicalCompany.name = _name;
    medicalCompany.phone = _phone;
    medicalCompanies[_medicalCompanyaddress] = medicalCompany;
    medicalCompaniesList.push(_medicalCompanyaddress);
    medicalCompany.id = int(medicalCompaniesList.length -1 );

    emit AddedMedicalCompany(_medicalCompanyaddress,_name,_phone);
  }
  // Function to delete a MedicalCompany from the supply chain system
  function deleteMedicalCompany(address etheruemAddress) public {
    if(msg.sender != admin)
   revert AccessDenied__OnlyAdmin();
    //delete medicalCompanies[etheruemAddress];
    uint rowToDelete = uint(medicalCompanies[etheruemAddress].id);
    address keyToMove   = medicalCompaniesList[medicalCompaniesList.length-1];
    medicalCompaniesList[rowToDelete] = keyToMove;
    medicalCompanies[keyToMove].id = int(rowToDelete);
    medicalCompaniesList.pop();
  }
  // Function for a MedicalCompany to list a drug 
  function listDrug(string memory _name, uint _id,string memory _serialNumber) public {
    if(medicalCompanies[msg.sender].etheruemAddress != msg.sender)
    {
        revert AccessDenied__OnlyMedicalCompany();
    }
    Drug memory drug;
    drug.name = _name;
    drug.id = _id;
    drug.serialNumber = _serialNumber;
    drug.currentHolder = msg.sender;
    drug.isVerified = false;
    drugs[_id] = drug;
    //adding drug id to medicalCompanies drugs id 
    medicalCompanies[msg.sender].drugIds.push(_id);
    emit DrugAdded(msg.sender,_id,_name);
  }
  // Function for a MedicalCompany to add a drugpackage to using listed drug inventory and desired hospital address
  function addDrugPackage(string memory _name,address _hospitaladdress, uint256 _id, uint256 _drugId, uint256 _quantity,string memory _expirationDate) public {
    if(medicalCompanies[msg.sender].etheruemAddress != msg.sender)
    {
        revert AccessDenied__OnlyMedicalCompany();
    }
    if(drugs[_drugId].currentHolder != msg.sender)
    {
        revert AccessDenied__OnlyMedicalCompany();
    }
    if(drugs[_drugId].isVerified != true )
    {
      revert Drug__NotVerified();
    }
    if(drugPackages[_id].id == _id)
    {
      revert Drug__Duplicate();
    }
    // Create an array of drugs from the same drug ID
    DrugPackage storage Package = drugPackages[_id];
    Package.id = _id;
    Package.name = _name;
    Package.numberOfDrugsInPackage =_quantity;
    Package.currentHolder =msg.sender;
    Package.medicalCompanyAddress =msg.sender;
    Package.isVerified =false;
    Package.expirationDate = _expirationDate;
    Package.hospitalAddress = _hospitaladdress;
    //add package details 
    for (uint256 i = 0; i < _quantity; i++)
    {
        Package.drugs.push(Drug(
                    drugs[_drugId].name,
                    drugs[_drugId].id,
                    i,
                    drugs[_drugId].serialNumber,
                    drugs[_drugId].isVerified,
                    drugs[_drugId].verifiedBy,
                    msg.sender
        ));
    }
   emit DrugPackageCreated(msg.sender,  _drugId, _quantity);
}
// Function for medicalCompanies to add a drug to the verification queue
function requestDrugVerification(uint256 _id) public {
  if(medicalCompanies[msg.sender].etheruemAddress != msg.sender) revert AccessDenied__OnlyMedicalCompany();
  if(drugs[_id].id != _id) revert Drug__NotFound();
  if(drugs[_id].isVerified == true) revert Drug__AllreadyVerified();
  if(verificationQueue[_id]) revert Request__Duplicate();
    verificationQueue[_id] = true;
    emit DrugVerificationRequested(msg.sender,_id);
}
// Function for verifiers to verify a drug
function verifyDrug(uint256 _id) public {
  if(verifiers[msg.sender].etheruemAddress != msg.sender ) revert AccessDenied__OnlyVerifier();
  if(!verificationQueue[_id]) revert Drug__NotFound();
    delete verificationQueue[_id];
    drugs[_id].isVerified = true;
    drugs[_id].verifiedBy = msg.sender;
    emit DrugVerified(msg.sender,_id);
}
// Function for medicalCompanies to add a drugPackage to the verification queue
function requestDrugPackageVerification(uint256 _id) public {
    if(medicalCompanies[msg.sender].etheruemAddress != msg.sender) revert AccessDenied__OnlyMedicalCompany();
    if(drugPackages[_id].id != _id) revert DrugPackage__NotFound();
    if(drugPackages[_id].isVerified == true) revert DrugPackage__AllreadyVerified();
    if(verificationPackageQueue[_id]) revert Request__Duplicate();
    verificationPackageQueue[_id] = true;
    emit DrugPackageVerificationRequested(msg.sender,_id);
}
// Function for verifiers to verify a drugPackage
function verifyDrugPackage(uint256 _id) public {
  if(verifiers[msg.sender].etheruemAddress != msg.sender) revert AccessDenied__OnlyVerifier();
  if(!verificationPackageQueue[_id]) revert DrugPackage__NotFound();
    delete verificationPackageQueue[_id];
    drugPackages[_id].isVerified = true;
    drugPackages[_id].verifiedBy = msg.sender;
    emit DrugPackageVerified(msg.sender,_id);
}
//  can be used by package holder to send to this contract participants 
function sendPackage( address _to, uint _drugPackageId) public {

  if(drugPackages[_drugPackageId].currentHolder != msg.sender) revert AccessDenied__OnlyCurrentHolder();
  if(sendRequests[msg.sender].drugPackageId == _drugPackageId) revert Request__Duplicate();
  sendRequests[msg.sender] = SendRequest(msg.sender, _to,_drugPackageId);
  emit PackageSendRequest(msg.sender, _to, _drugPackageId);
}
// used to receive a packeg from sender 
function receivePackage(address _from,uint _drugPackageId) public {
  if(sendRequests[_from].to != msg.sender || sendRequests[_from].drugPackageId != _drugPackageId) revert Request__NotFound();
   drugPackages[_drugPackageId].currentHolder = msg.sender;
 
  if(_from == medicalCompanies[_from].etheruemAddress)
    {
    suppliers[msg.sender].packageIds.push(_drugPackageId);
    }
  if(_from == suppliers[_from].etheruemAddress)
    {
    hospitals[msg.sender].packageIds.push(_drugPackageId);
    }
  delete sendRequests[_from];

  emit PackageReceived(_from, msg.sender, _drugPackageId);
}

// ******************************* Patient operation section ******** 
    event DrugRequestCreated(address indexed patient, address indexed hospital, uint drugId);
    event DrugRequestApproved(address indexed patient, address indexed hospital,uint drugId);
    event DrugReceived(address indexed hospital, address indexed patient, uint drugId);  

function sendDrugRequest(uint _drugId,address _hospital) public {
  // Only patients can send drug requests
  if(patients[msg.sender].etheruemAddress != msg.sender) revert AccessDenied__OnlyPatient();

  // Create a new drug request with a unique ID
  if(drugRequests[msg.sender].patient == msg.sender && drugRequests[msg.sender].hospital == _hospital && drugRequests[msg.sender].drugId == _drugId) 
  {
    revert Request__Duplicate();
  }
  DrugRequest memory request = DrugRequest(msg.sender,_hospital, _drugId, false,0,0);
  drugRequests[msg.sender] = request;

  // Emit an event to indicate that the request has been created
  emit DrugRequestCreated(msg.sender,_hospital, _drugId);
}
// Function to allow hospitals to approve or reject drug requests
function approvedDrugRequest(address _patient, uint _drugPackageId,uint _packingNumber) public {
  // Only hospitals can approve or reject drug requests
  if(hospitals[msg.sender].etheruemAddress != msg.sender) revert AccessDenied__OnlyHospital();
  // Get the drug request with the specified ID
  DrugRequest storage request = drugRequests[_patient];
   
  if(request.hospital != msg.sender)  revert  AccessDenied__OnlyHospital();
  // Only owned packages can be given from
  if(drugPackages[_drugPackageId].currentHolder != msg.sender) revert AccessDenied__OnlyCurrentHolder();
  // Quantity check 
  if(drugPackages[_drugPackageId].numberOfDrugsInPackage < 1) revert Drug__NotEnoughQuantity();

  // Update the status of the request to approved 
  request.IsApproved = true;
  request.drugPackageId = _drugPackageId;
  request.packaingNumber = _packingNumber;
  // Emit an event to indicate that the request status has changed
  emit DrugRequestApproved(_patient,msg.sender,request.drugId);
}
// Function to allow patients to accept a drug sent by a hospital
function receiveDrug(uint _drugId , address _hospital) public {
  // Check The request 
  if(patients[msg.sender].etheruemAddress != msg.sender) revert AccessDenied__OnlyPatient();
  // Check The states of request 
  if(drugRequests[msg.sender].patient!= msg.sender ||
         drugRequests[msg.sender].hospital != _hospital ||
         drugRequests[msg.sender].drugId != _drugId) revert Request__NotFound();
  if(drugRequests[msg.sender].IsApproved == false) revert Request__NotApproved(); 
  // change the current holder and reduce quantity 
  drugPackages[drugRequests[msg.sender].drugPackageId].drugs[drugRequests[msg.sender].packaingNumber].currentHolder = msg.sender;
  drugPackages[drugRequests[msg.sender].drugPackageId].numberOfDrugsInPackage--;
  // Emit an event to indicate that the drug has been accepted
  emit DrugReceived(drugRequests[msg.sender].hospital, msg.sender,_drugId);
  //delete request 
  delete drugRequests[msg.sender];
}



//******************************* data retrive section ************************************ 
function getAllMedicalCompanies() external view returns (MedicalCompany[] memory) {
    MedicalCompany[] memory companies = new MedicalCompany[](medicalCompaniesList.length);
    for (uint i = 0; i < medicalCompaniesList.length; i++) {
        companies[i] = medicalCompanies[medicalCompaniesList[i]];
    }
    return companies;
}
function getAllVerifiers() external view returns (Verifier[] memory) {
    Verifier[] memory data = new Verifier[](verifiersList.length);
    for (uint i = 0; i < verifiersList.length; i++) {
        data[i] = verifiers[verifiersList[i]];
    }
    return data;
}
function getAllHospitals() external view returns (Hospital[] memory) {
    Hospital[] memory data = new Hospital[](hospitalsList.length);
    for (uint i = 0; i < medicalCompaniesList.length; i++) {
        data[i] = hospitals[hospitalsList[i]];
    }
    return data;
}
function getAllSuppliers() external view returns (Supplier[] memory) {
    Supplier[] memory data = new Supplier[](suppliersList.length);
    for (uint i = 0; i < suppliersList.length; i++) {
        data[i] = suppliers[suppliersList[i]];
    }
    return data;
}
function getAllPatients() external view returns (Patient[] memory) {
    Patient[] memory data = new Patient[](patientsList.length);
    for (uint i = 0; i < patientsList.length; i++) {
        data[i] = patients[patientsList[i]];
    }
    return data;
}
function getMyDrugs() external view returns (Drug[] memory){

    if(msg.sender == medicalCompanies[msg.sender].etheruemAddress)
    {
    Drug[] memory data = new Drug[](medicalCompanies[msg.sender].drugIds.length);
    for (uint i = 0; i < medicalCompanies[msg.sender].drugIds.length; i++) {
       if(drugs[medicalCompanies[msg.sender].drugIds[i]].currentHolder == msg.sender) 
        data[i] = drugs[medicalCompanies[msg.sender].drugIds[i]];
    }
    return data;
    }
    else revert AccessDenied__OnlyHospital();
}
function getDrugsInPackage(uint _drugPackageId) external view returns (Drug[] memory){
    Drug[] memory data = new Drug[](drugPackages[_drugPackageId].drugs.length);
    for (uint i = 0; i < data.length; i++) {
        data[i] = drugPackages[_drugPackageId].drugs[i];
      }
    return data;
}

}