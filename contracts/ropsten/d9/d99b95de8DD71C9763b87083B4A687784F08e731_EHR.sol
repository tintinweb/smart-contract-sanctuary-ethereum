/**
 *Submitted for verification at Etherscan.io on 2022-03-27
*/

pragma solidity >=0.7.0 <0.9.0;

contract EHR {

    uint patientCount = 0;
    uint doctorCount = 0;


    struct Patient{
        string firstName;
        string lastName;
        /// public key of patient
        bytes pubKey;
        /// doctors authorized to read/write this patient's EHR
        mapping (address => bool) authorized;
        bool valid;
    }

    struct Doctor{
        string firstName;
        string lastName;
        /// public key of doctor
        bytes pubKey;
        bool valid;
    }

    struct MedicalRecord{
        /// address of the doctor who created this record
        address doctorAddress;
        /// hash of latest file version
        bytes32 hash;
        bool valid;
    }
    
    /// associate patient's wallet address with Patient struct
    mapping (address => Patient) patients;
    /// associate doctot's wallet address with Doctor struct
    mapping (address => Doctor) doctors;
    /// associate patient's wallet address with doctor address
    mapping (address => address) patientProviders;
    /// associate patient's wallet address with MedicalRecord
    mapping (address => MedicalRecord) records;

    event PatientCreation(address indexed _patient, address indexed _doctor);
    event DoctorCreation(address indexed _doctor);
    event DoctorAuth(address indexed _patient, address indexed _doctor, bool isAuthorized);
    event MedicalRecordView(address indexed _patient, address indexed _viewer);
    event MedicalRecordUpdate(address indexed _patient, address indexed _updator, bytes32 fileHash);


    function createPatient(
        string memory _firstName, 
        string memory _lastName, 
        address _patientAddress, 
        bytes memory _patientPublicKey
    ) 
        public 
    {
        /// only allow doctors to create patients, and patient can't already exist
        require(doctors[msg.sender].valid && !patients[_patientAddress].valid);
        patients[_patientAddress].firstName = _firstName;
        patients[_patientAddress].lastName = _lastName;
        patients[_patientAddress].pubKey = _patientPublicKey;
        patients[_patientAddress].authorized[msg.sender] = true;
        patients[_patientAddress].valid = true;
        records[_patientAddress].doctorAddress = msg.sender;
        /// hash of null data
        records[_patientAddress].hash = 0xe3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855;
        patientCount++;
        emit PatientCreation(_patientAddress, msg.sender);
    }

    function createDoctor(
        string memory _firstName, 
        string memory _lastName, 
        address _doctorAddress, 
        bytes memory _doctorPublicKey
    ) 
        public
    {
        /// only admin can create doctor, and doctor must not already exist
        require(!doctors[_doctorAddress].valid);
        doctors[_doctorAddress].firstName = _firstName;
        doctors[_doctorAddress].lastName = _lastName;
        doctors[_doctorAddress].pubKey = _doctorPublicKey;
        doctors[_doctorAddress].valid = true;
        doctorCount++;
        emit DoctorCreation(_doctorAddress);
    }

    function authorizeDoctor(address _doctorAddress) public
    {
        /// doctor should exist and patient should exist and doctor shouldn't already have authorization
        require(doctors[_doctorAddress].valid 
                && patients[msg.sender].valid
                && !patients[msg.sender].authorized[_doctorAddress]);
        patients[msg.sender].authorized[_doctorAddress] = true;
        emit DoctorAuth(msg.sender, _doctorAddress, true);
    }

    function deauthorizeDoctor(address _doctorAddress) public
    {
        /// doctor should exist and patient should exist and doctor should have authorization
        require(doctors[_doctorAddress].valid 
                && patients[msg.sender].valid 
                && patients[msg.sender].authorized[_doctorAddress]);
        patients[msg.sender].authorized[_doctorAddress] = false;
        emit DoctorAuth(msg.sender, _doctorAddress, false);
    }

    function updateRecordHash(address _patientAddress, bytes32 _hash) public {
        /// patient should exist and either (sender is patient) or (sender is doctor and doctor is authorized)
        require(patients[_patientAddress].valid && (patients[msg.sender].valid || (doctors[msg.sender].valid && patients[_patientAddress].authorized[msg.sender])));
        records[_patientAddress].hash = _hash;
    }

    function patientExists(address _patientAddress) public view returns (bool) {
        return patients[_patientAddress].valid;
    }

    function doctorExists(address _doctorAddress) public view returns (bool) {
        return doctors[_doctorAddress].valid;
    }

    function doctorAuthorized(address _doctorAddress, address _patientAddress) public view returns (bool) {
        require(doctors[_doctorAddress].valid && patients[_patientAddress].valid);
        return patients[_patientAddress].authorized[_doctorAddress];
    }

    function getAddress(bytes memory pubkey) public pure returns (address) {
        return address(uint160(uint256(keccak256(pubkey))));
    }

    //input a signature and determine the v, r and s values
    function splitSignature(bytes memory signature) public pure
        returns (uint8 v, bytes32 r, bytes32 s)
    {
        require(signature.length == 65);

        assembly {
            // first 32 bytes, after the length prefix.
            r := mload(add(signature, 32))
            // second 32 bytes.
            s := mload(add(signature, 64))
            // final byte (first byte of the next 32 bytes).
            v := byte(0, mload(add(signature, 96)))
        }

        return (v, r, s);
    }

    //input a message hash, v, r and s values and generate the public key
    function recoverPublicAddress (bytes32 messagehash, uint8 v, bytes32 r, bytes32 s) public pure
    returns (address sender) {
        return ecrecover(messagehash, v, r, s);
  }

}