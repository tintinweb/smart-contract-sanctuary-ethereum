/**
 *Submitted for verification at Etherscan.io on 2022-12-18
*/

// SPDX-License-Identifier: MIT
// Credits to OpenZeppelin
pragma solidity ^0.8.0;
/**
* @dev Provides information about the current execution context, including
the
* sender of the transaction and its data. While these are generally available
* via msg.sender and msg.data, they should not be accessed in such a direct
* manner, since when dealing with meta-transactions the account sending and
* paying for execution may not be the actual sender (as far as an application
* is concerned).
*/

  // MedicalRecord contains information about the record
  struct MedicalRecord { 
      string disease_description;
      string treatment_description;
      string prescription;
      string health_provider_type;
      address patient;
      address health_provider;
      uint256 time_record;
      uint256 record_id;
  }

  // Patient information contains information about the patient
  struct Patient {
      address id;
      string insurance_number;
      string date_birth;
      MedicalRecord[] all_records;
  }

  // HealthProvider contains information about the health provider
  struct HealthProvider {
      address id;
      string health_provider_type;
  }

// create contract MedicalRecordTemplate
contract MedicalRecordTemplate {
  
    // map address to patients
    mapping(address => Patient) private patients;
    
    // map address to health providers
    mapping(address => HealthProvider) private health_providers;

    // add allowance to observe MedicalRecord
    mapping(address => mapping(address => uint256[])) private _allowances;

    // create event to be emitted 
    event AddPatient(address indexed patient_address);
    event AddHealthProvider(address indexed health_provider_address);
    event AddRecord(address indexed patient_address, address indexed health_provider_address, uint256 record_id);

    event Approval(
        address indexed patient_address,
        address indexed health_provider_address,
        uint256 record_id
    );

    string private _name;
    string private _symbol;

    // set name and symbol
    constructor() {
        _name = "TempalteMedicalRecord";
        _symbol = "TMR";
    }

    //return address of the message sender
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    //return data of the message sender
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
    * @dev Returns the name of the token.
    */
    function name() public view virtual returns (string memory) {
        return _name;
    }
    /**
    * @dev Returns the symbol of the token, usually a shorter version of the
    * name.
    */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
    * @dev Returns the number of records of a patient.
    */
    function numberOfRecords(address patient) public view virtual returns (uint256){
        return patients[patient].all_records.length;
    }

    /** 
    * @dev The patient gets all of his records
    *
    * Returns all patient's records
    * Requirements: 
    *
    * - the sender should be the patient
    * 
    */
    function getAllRecordsPatient() public view virtual returns (MedicalRecord[] memory){
        
      address patient =_msgSender();

      require(patients[patient].id == patient, "This patient does not exists.");
        
      return patients[patient].all_records;
    }

    /** 
    * @dev The health provider access paticular record
    *
    * Returns patient's record
    * Requirements: 
    *
    * - if the sender is not the patient, the sender should be authorised to observe the record
    * 
    */
    function getRecord(address patient, uint256 record_id) public view virtual returns (MedicalRecord memory) {
        
      address sender = _msgSender();

      // check if the sender is the patient
      if (sender != patient) {
        
        // require permission to observe the particular record
        // we save id of 0 for to check if a record exists
        uint256 id = 0;
        for (uint i; i < _allowances[patient][sender].length; i++) {
            if (_allowances[patient][sender][i] == record_id) {
                
                // save the id of the record   
                id = record_id;
            }
        }
        require(id == record_id, "You are not allowed to observe this record");
      }

      // iterate through the records of the patient
      for (uint i; i < patients[patient].all_records.length; i++) {
        if (patients[patient].all_records[i].record_id == record_id) {

            // return the corresponding record   
            return patients[patient].all_records[i];
        }
      }
      revert("The record does not exist");
    }

    /** 
    * @dev Adds record to the patient
    *
    * Returns a boolean value indicating whether the operation succeeded.
    * Requirements:
    *
    * - only health providers can add records
    * - the patient should exist
    * 
    */
    function addRecord(
        string memory disease_description,
        string memory treatment_description,
        string memory prescription,
        address patient) public virtual returns (bool) {
  
      address health_provider = _msgSender();

      //require sender to be a health provider
      require(health_providers[health_provider].id == health_provider, "This health provider does not exist.");
      require(patients[patient].id == patient, "This patient does not exist.");
      
      // create new medical record
      uint256 record_id = numberOfRecords(patient) + 1;

      patients[patient].all_records.push(MedicalRecord(
                                        disease_description,
                                        treatment_description,
                                        prescription,
                                        health_providers[health_provider].health_provider_type,
                                        patient,
                                        health_provider,
                                        block.timestamp,
                                        record_id));

      emit AddRecord(patient, health_provider, record_id);

      return true;
    }
    /** 
    * @dev Adds new patient
    *
    * Returns a boolean value indicating whether the operation succeeded.
    * Requirements:
    *
    * - the patient should not exist
    * - the sender should be the patien
    * - the patient should not be the zero address
    */
    function addPatient(string memory insurance_number, string memory date_birth) public virtual returns (bool) {
      address patient =_msgSender();

      require(patient != address(0));
      require(patients[patient].id != patient, "This patient already exists.");
      
      patients[patient].id = patient;
      patients[patient].insurance_number = insurance_number;
      patients[patient].date_birth = date_birth;

      emit AddPatient(patient);
      return true;
    }

    /** 
    * @dev Adds new health provider
    *
    * Returns a boolean value indicating whether the operation succeeded.
    * Requirements:
    *
    * - the health provider should not exist
    * - the sender should be the health provider
    * - health provider should not be the zero address
    */
    function addHealthProvider(string memory health_provider_type) public  virtual returns (bool) {
    
      address health_provider =_msgSender();

      require(health_provider != address(0));
      require(health_providers[health_provider].id != health_provider, "This health provider already exists.");
      
      health_providers[health_provider].id = health_provider;
      health_providers[health_provider].health_provider_type = health_provider_type;

      emit AddHealthProvider(health_provider);
      
      return true;
   }
    /** 
    * @dev Returns a list of medical record IDs that the particualr health provider
    * can access for a particular patient
    */
    function allowance(address patient, address health_provider)
        public
        view
        virtual
        returns (uint256[] memory)
    {
        return _allowances[patient][health_provider];
    }

    /** 
    * @dev Allows a health provider to observe patient's record
    *
    * Returns a boolean value indicating whether the operation succeeded.
    *
    * Requirements:
    *
    * - message sender should be patient
    */
    function approve(address health_provider, uint256 record_id)
        public
        virtual
        returns (bool)
    {
        // only the patient can approve who can observe their records

        address patient = _msgSender();

        // the sender should be the patient
        require(patients[patient].id == patient, "This patient does not exist.");
        
        // check if the health provider can see the record
        for (uint i; i < _allowances[patient][health_provider].length; i++) {
          if (_allowances[patient][health_provider][i] == record_id) {
                  revert("The health provider can already observe this record");
          }
        }

        _approve(patient, health_provider, record_id);
        return true;
    }
   
    /** 
    * @dev Removes the allowance of a health provider to observe particular record
    *
    * Returns a boolean value indicating whether the operation succeeded.
    *
    * Requirements:
    *
    * - message sender should be patient
    * - the patient should exist
    */
    function removeAllowance(address health_provider, uint256 record_id)
        public
        virtual
        returns (bool)
    {
        address patient = _msgSender();
        require(patients[patient].id == patient, "This patient does not exist.");

        for (uint i; i < _allowances[patient][health_provider].length; i++) {
          if (_allowances[patient][health_provider][i] == record_id) {

            // delete the corresponding record   
            delete _allowances[patient][health_provider][i];

            // fill the gap with the last item
            _allowances[patient][health_provider][i] = _allowances[patient][health_provider][_allowances[patient][health_provider].length - 1];
            _allowances[patient][health_provider].pop();
          }
        }
        return true;
    }

    /** 
    * @dev Approves the health_provider to observe patient's record
    *
    * Requirements:
    *
    * - `patient` cannot be the zero address.
    * - `health_provider` cannot be the zero address.
    */
    function _approve(
        address patient,
        address health_provider,
        uint256 record_id
    ) internal virtual {
        require(patient != address(0));
        require(health_provider != address(0));
        
        _allowances[patient][health_provider].push(record_id);

        emit Approval(patient, health_provider, record_id);
    }
   
}