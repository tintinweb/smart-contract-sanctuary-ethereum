// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;


contract PatientRecordContract {
    
    struct Record {
        string admissionNo;
        string name;
        string hospital;
        string doctor;
        string therapeuticArea;
        string keyDiagnosis;
        uint timestamp;
        address publicKey;
    }

    struct Patient {
        Record[] PatientRecordData;
    }

    mapping(address=>Record) RecordSet;
    mapping(address=>bool) IsPatient;
    mapping(address=>Patient) PatientRecord;

    //hospitals can Enter patient Record. whenever he visit to the hospitals.
    //when patient will go to hospital they will put his detail in Blockchain with their public key assigned to it. 
    function addRecord(string memory _number, string memory _name, string memory _hospital, string memory _doctor, string memory keyDiagnosis, string memory therapeuticArea,address _publicKey) public returns(bool) {
        Record storage record=RecordSet[_publicKey];
        record.admissionNo=_number;
        record.name=_name;
        record.hospital=_hospital;
        record.doctor=_doctor;
        record.keyDiagnosis=keyDiagnosis;
        record.therapeuticArea=therapeuticArea;
        record.timestamp= block.timestamp;
        record.publicKey=_publicKey;
        IsPatient[_publicKey]=true;
        
        Patient storage patient=PatientRecord[_publicKey];
        patient.PatientRecordData.push(record);
        
        return true;
    }
    
    modifier onlyPatient() {
        require(IsPatient[msg.sender] == true);
        _;
    }
    //patient can fetch total count of records.
    //only the person to whom records belong to will only able to see the total number of records
    //and details of each record. 
    function totalRecord() public view returns(uint){
        Record storage record=RecordSet[msg.sender];
        require(record.publicKey==msg.sender);
        Patient storage patient=PatientRecord[msg.sender];
        return(patient.PatientRecordData.length);
    }
    
    function getRecord(uint index) public view returns( string memory, string memory, string memory,string memory,string memory,string memory,uint){
       Record storage record=RecordSet[msg.sender];
       require(record.publicKey==msg.sender);
       Patient storage patient=PatientRecord[msg.sender];
       Record memory p = patient.PatientRecordData[index];
       return(
           p.admissionNo,
           p.name,
           p.hospital,
           p.doctor,
           p.keyDiagnosis,
           p.therapeuticArea,
           p.timestamp
        );
    }
    
}