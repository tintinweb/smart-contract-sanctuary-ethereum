/**
 *Submitted for verification at Etherscan.io on 2023-06-08
*/

//SPDX-License-Identifier: MIT 

pragma solidity ^0.8.0;

contract PatientRecords_GDPR{

    /* Main Parties */
    string  public medicalFacilityName; //data controler name
    address public medicalFacility;    //data controller block address

    string  public researcherName;     //data processor name
    address public researcher;         //data processor

    /* Research Details*/ 
    bool    public isEncrypted;
    string  public encryptionType;
    string  public researchPurpose;
    //int     public researchDuration;

    /* GDPR principles */
    bool    public isConsented;     
    bool    public isLegalObligation;
   // bool    public isRightToForget;
    bool    public isPublicTask;
    
    /* Status and Metadata */
    string  public status;
    uint256 public firstAccess; 
    //uint    public deletionTime;

    modifier onlyMedicalFacility() {
        require (msg.sender == medicalFacility, "Only Medical Facility Admin can execute this function");
        _;
    }
    constructor() {
        /*Initializing the medical facility with Account 1 on Metamask*/
        medicalFacility = 0x7876d277C8c107D7b77d1Cecca6af5e54FF9c56d;
        medicalFacilityName = " Medical Facility 1 " ; 


        researcher = 0x07dd10aD40B49E648c73bD29856DCaB2Cff69ceA ;
        researcherName = " Researcher 1 " ;
    }



    function initializeGDPRVariables(
    string memory _medicalFacilityName,
    address _medicalFacility,
    string memory _researcherName,
    address _researcher,
    bool _isEncrypted,
    string memory _encryptionType,
    string memory _researchPurpose,
    bool _isConsented,
    string memory _status,
    uint256 _firstAccess
) public {
    medicalFacilityName = _medicalFacilityName;
    medicalFacility = _medicalFacility;
    researcherName = _researcherName;
    researcher = _researcher;
    isEncrypted = _isEncrypted;
    if(isEncrypted == true){
    encryptionType = _encryptionType;
    }
    else
    {
        encryptionType = "No Encryption";
    }

    researchPurpose = _researchPurpose;
    isConsented = _isConsented;
    status = _status;
    firstAccess = _firstAccess;
}

function displayTransactionValues() public view returns (
    string memory _medicalFacilityName,
    address _medicalFacility,
    string memory _researcherName,
    address _researcher,
    bool _isEncrypted,
    string memory _encryptionType,
    string memory _researchPurpose,
    bool _isConsented,
    string memory _status,
    uint256 _firstAccess
) {
    return (
        medicalFacilityName,
        medicalFacility,
        researcherName,
        researcher,
        isEncrypted,
        encryptionType,
        researchPurpose,
        isConsented,
        status,
        firstAccess
    );
}   
    





 
}