/**
 *Submitted for verification at Etherscan.io on 2023-01-19
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
// import "hardhat/console.sol";

contract HealthCareSystem {

    struct patient {
        string paitentName;
        string addres;
        uint256 phoneNo;
        string bloodGroup;
        uint256 insuranceCompanyId;
        uint256 emergencyContact;
        string Precautions;
        uint256[] treatmentId;
        bool insuranceValid;
    }
    
    struct insuranceCompany {
        uint companyId;
        string name;
        uint256 phoneNo;
        string[] notCovered;
    }

    struct doctor {
        uint256 doctorId;
        string doctorName;
        string practiceType;
        string areaOfExpertize;
        uint256 phoneNo;
        string Address;
    }

    struct treatment {
        uint256 _patientId;
        uint256 _doctorId;
        string diagnosis;
        string test_conducted;
        uint256 bill;
        string medicine;
        string[] InsuranceKeep;
    }
    struct chemist {
        uint256 chemistId;
        string Address;
        string name;
        uint256 phoneNo;
        string[] medicines;
    }

    struct denoteNum{
        uint patientEn;
        uint doctorEn;
        uint insuranceEn;
        uint chemistEn;
    }
    mapping(uint256 => uint) public verify;
    mapping(uint256 => chemist) chemistInfo;
    mapping(uint256 => treatment) treatmentInfo;
    mapping(uint256 => doctor) doctorInfo;
    mapping(uint256 => uint256) public Otp;
    mapping(uint256 => insuranceCompany) InsuranceComInfo;
    mapping(uint => denoteNum) entitie;
    mapping(uint256 => patient) paitentInfo;
    mapping(address => uint256) addresstoId;
    mapping(uint256 => address) IdtoAdress;

    constructor(){
        entitie[0].patientEn = 1;
        entitie[0].doctorEn = 2;
        entitie[0].insuranceEn = 3;
        entitie[0].chemistEn = 4;
    }

    function addDoctor(
        uint256 doctorId,
        string memory doctorName,
        string memory practiceType,
        string memory areaOfExpertize,
        uint256 phoneNo,
        string memory Address
    ) public {
        require(verify[doctorId] == 0 && addresstoId[msg.sender] == 0,"Address is already registered/associated with another Id");
        doctorInfo[doctorId] = doctor(
            doctorId,
            doctorName,
            practiceType,
            areaOfExpertize,
            phoneNo,
            Address
        );
       verify[doctorId] = 2;
       addresstoId[msg.sender] = doctorId;
       IdtoAdress[doctorId] = msg.sender;
    }


    function addInsurancecompany(
        uint256 _companyId,
        string memory _name,
        uint256 phoneNo
    ) public {
        require(verify[_companyId] == 0 && addresstoId[msg.sender] == 0, "Company or Address is already registerd/associated with another id");
        InsuranceComInfo[_companyId].companyId = _companyId ;
        InsuranceComInfo[_companyId].name = _name ;
        InsuranceComInfo[_companyId].phoneNo = phoneNo;
        addresstoId[msg.sender] = _companyId;
        verify[_companyId] = 3;
        addresstoId[msg.sender] = _companyId;
        IdtoAdress[_companyId] = msg.sender;
    }

    function addNotCoverdMedicationInInsurance(string memory _Medication) public {
        uint256 Id = addresstoId[msg.sender];
        require(verify[Id] == 3 , "Company or Address is not registered");
        InsuranceComInfo[Id].notCovered.push(_Medication);
    }
    
    
    function getInsuranceCompany(uint256 InsuranceId)
        public
        view
        returns (string memory name, uint256 phoneNo,string[] memory notCovered)
    {
        uint256 Id = addresstoId[msg.sender];
        require(verify[Id] == 3 , "Company or Address is not registered");
        InsuranceComInfo[InsuranceId].notCovered.length;
        return (InsuranceComInfo[InsuranceId].name, InsuranceComInfo[InsuranceId].phoneNo,InsuranceComInfo[InsuranceId].notCovered);
    }


    function addChemist(
        uint256 _chemistId,
        string memory name,
        string memory Address,
        uint256 phoneNo
    ) public {
        require(verify[_chemistId] == 0 && addresstoId[msg.sender] == 0,"Chemist or Address is already registered with id");
        chemistInfo[_chemistId].chemistId = _chemistId;
        chemistInfo[_chemistId].name = name;
        chemistInfo[_chemistId].Address = Address;
        chemistInfo[_chemistId].phoneNo = phoneNo;
        verify[_chemistId] = 4;
        addresstoId[msg.sender] = _chemistId;
        IdtoAdress[_chemistId] = msg.sender;
    }

    function getchemistinfo(uint256 _chemistId)
        public
        view
        returns (
            string memory Address,
            string memory name,
            uint256 phoneNo
        )
    {
        require(verify[_chemistId] == 4, "Chemist Id is Incorrect");
        return (
            chemistInfo[_chemistId].Address,
            chemistInfo[_chemistId].name,
            chemistInfo[_chemistId].phoneNo
        );
    }
    function addPatientInfo(
        uint256 _adharCardNumber,
        string memory _paitentName,
        string memory _addres,
        uint256 _phoneNo,
        string memory _bloodGroup,
        uint256 _insuranceCompany,
        uint256 _emergencyContact
    ) public {
        require(verify[_adharCardNumber] == 0 && addresstoId[msg.sender] == 0, "Aadhar card or Address is already registerd/associated with another id");
        require(InsuranceComInfo[_insuranceCompany].companyId == _insuranceCompany,"Insurance company is not registered");
        paitentInfo[_adharCardNumber].paitentName = _paitentName;
        paitentInfo[_adharCardNumber].addres = _addres;
        paitentInfo[_adharCardNumber].phoneNo = _phoneNo;
        paitentInfo[_adharCardNumber].bloodGroup = _bloodGroup;
        paitentInfo[_adharCardNumber].insuranceCompanyId = _insuranceCompany;
        paitentInfo[_adharCardNumber].emergencyContact = _emergencyContact;
        verify[_adharCardNumber] = 1;
        addresstoId[msg.sender] = _adharCardNumber;
        IdtoAdress[_adharCardNumber] = msg.sender;
    }

    function requestAccessToPatient(uint256 _adharCardNumber) public {
        uint Id = addresstoId[msg.sender];
        require((verify[Id]==1|| verify[Id] == 2) && verify[_adharCardNumber]==1 , "Caller should be Doctor/Patient And Aadhar Card number should be registered");
        uint256 otp = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender))) % 43234;
        Otp[_adharCardNumber] = otp;
    }


    function getOtp(uint256 _adharCardNumber) public view returns(uint256){
        uint Id = addresstoId[msg.sender];
        require((verify[Id]==1|| verify[Id] == 2) && verify[_adharCardNumber]==1 , "Caller should be Doctor/Patient And Aadhar Card number should be registered");
        uint256 otp = Otp[_adharCardNumber];
        return otp;
    }


    function getDetailsOfAllTID(uint256 _adharCardNumber, uint256 OTP)
        public
        view
        returns (uint256[] memory)
    {
        uint Id = addresstoId[msg.sender];
        require(verify[Id] == 2 || verify[_adharCardNumber] == 1, "Caller should be Doctor/Patient");
        require(Otp[_adharCardNumber] == OTP, "Incorrect OTP");
        return (paitentInfo[_adharCardNumber].treatmentId);
    }


    function TreatPatient(
        uint256 _patientId,
        uint256 _doctorId,
        string memory diagnosis,
        string memory test_conducted,
        uint256 bill,
        string memory medicine,
        string memory _Precautions
    ) public returns(uint256[] memory){
        require(IdtoAdress[_doctorId] == msg.sender, "Caller is not registered Doctor");
        require(verify[_patientId] ==  1, "PatientId is not registered");
        uint256 latestTreatmentid = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, "123434231"))) % 13421;
        paitentInfo[_patientId].treatmentId.push(latestTreatmentid);
        treatmentInfo[latestTreatmentid]._patientId = _patientId;
        treatmentInfo[latestTreatmentid]._doctorId = _doctorId;
        treatmentInfo[latestTreatmentid].diagnosis = diagnosis;
        treatmentInfo[latestTreatmentid].test_conducted = test_conducted;
        treatmentInfo[latestTreatmentid].bill = bill;
        treatmentInfo[latestTreatmentid].medicine = medicine;
        paitentInfo[_patientId].Precautions = _Precautions;
        return (paitentInfo[_patientId].treatmentId);
    }

    function getTreatmentDetails(uint256 _treatmentId)
        public
        view
        returns (
            uint256 _patientId,
            uint256 drId,
            string memory diagnosis,
            string memory test_conducted,
            uint256 bill,
            string memory medicine,
            string[] memory InsuranceKeep
        )
    {
        return (
            treatmentInfo[_treatmentId]._patientId,
            treatmentInfo[_treatmentId]._doctorId,
            treatmentInfo[_treatmentId].diagnosis,
            treatmentInfo[_treatmentId].test_conducted,
            treatmentInfo[_treatmentId].bill,
            treatmentInfo[_treatmentId].medicine,
            treatmentInfo[_treatmentId].InsuranceKeep
        );
    }

    function UpdatePrecautions(
        uint256 _adharCardNumber,
        string memory _Precautions
    ) public {
        uint256 Id = addresstoId[msg.sender];
        require(verify[Id] == 2, "Caller is not registered doctor");
        paitentInfo[_adharCardNumber].Precautions = _Precautions;
    }


    function addInsuranceKeep(uint256 _patientId, string memory _medication) public {
        uint256 Id = addresstoId[msg.sender];
        require(verify[Id] == 1||verify[Id] == 2,"Caller is not registered user");
        uint256 _treatmentid = paitentInfo[_patientId].treatmentId[paitentInfo[_patientId].treatmentId.length - 1];
        string memory medicines = treatmentInfo[_treatmentid].medicine;
        require(keccak256(bytes(medicines)) == keccak256(bytes(_medication)), "Medicines should be match for clamming insurance");
        treatmentInfo[_treatmentid].InsuranceKeep.push(_medication);
    }
    

    function givenMedicines(uint256 _patientId) public view returns (string memory) {
        string memory medicatines = treatmentInfo[
            paitentInfo[_patientId].treatmentId[
                paitentInfo[_patientId].treatmentId.length - 1
            ]
        ].medicine;
        return (medicatines);
    }


    
// All Get Function

     function getPatientInfo(uint256 _adharCardNumber)
        public
        view
        returns (
            string memory name,
            string memory addres,
            uint256 phoneNo,
            string memory bloodGroup,
            uint256 _insuranceCompany,
            uint256 emergencyContacts,
            string memory Precautions
        )
    {
        return (
            paitentInfo[_adharCardNumber].paitentName,
            paitentInfo[_adharCardNumber].addres,
            paitentInfo[_adharCardNumber].phoneNo,
            paitentInfo[_adharCardNumber].bloodGroup,
            paitentInfo[_adharCardNumber].insuranceCompanyId,
            paitentInfo[_adharCardNumber].emergencyContact,
            paitentInfo[_adharCardNumber].Precautions
        );
    }

    function getDoctorDetails(uint256 docId)
        public
        view
        returns (
            uint256 doctorId,
            string memory doctorName,
            string memory practiceType,
            string memory areaOfExpertize,
            uint256 phoneNo,
            string memory Address
        )
    {
        require(verify[docId] == 2, "Doctor Id is inccorect");
        return (
            doctorInfo[docId].doctorId,
            doctorInfo[docId].doctorName,
            doctorInfo[docId].practiceType,
            doctorInfo[docId].areaOfExpertize,
            doctorInfo[docId].phoneNo,
            doctorInfo[docId].Address
        );
    }


    function getEntitie() public view returns(uint patientEn,
        uint doctorEn,
        uint insuranceEn,
        uint chemistEn){
        return (entitie[0].patientEn,entitie[0].doctorEn,entitie[0].insuranceEn,entitie[0].chemistEn);
    }
}