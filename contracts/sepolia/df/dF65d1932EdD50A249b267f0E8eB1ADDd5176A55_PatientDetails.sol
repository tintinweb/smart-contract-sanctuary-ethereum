// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15 ;
pragma experimental ABIEncoderV2;
import "./Doctor.sol";
contract PatientDetails is DoctorDetails {
    modifier userOrAdmin(){
          bool checkAccess;
      if (PatientsPersonalDetails[msg.sender].walletAddress==msg.sender || PatientsMedicalDetails[msg.sender].walletAddress==msg.sender || OnlyOwner[msg.sender]) {
          checkAccess=true;
      }
      require(checkAccess, "You have no access to fetch the details");

      _;
    }
      struct PatientPersonalDetails{
        bool isAlive;
        string name;
        address walletAddress;
        string gender;
        string Occupation;
        uint256 dayOfBirth;
        uint256 monthOfBirth;
        uint256 yearOfBirth;
        uint256 age;
      
        }
      
        struct PatientMedicalDetails{
        address walletAddress;
        bool isAlcoholic;
        bool isSmoker;
        bool isSmokelessTobaccoUser;
        string surgicalHistory_ifAny;
        string physicalActivityLevel;
        string pastMedicationDetails_IfAny;
        
        }
        struct PatientHealthCondition{
        
        address walletAddress;
        address physician;
        string Department_uint;
        string BloodPressure;
        string HeartRate;
        string RespiratoryRate;
        string Dosage;
    }
    mapping (address => PatientPersonalDetails) public PatientsPersonalDetails;
    mapping(address=> PatientMedicalDetails)public PatientsMedicalDetails;
    mapping (address=>PatientHealthCondition[])public HealthCondition;
    uint256 public totalPatient;

    function AddPatientsMedicalDetails(
        address _walletAddress,
        bool _isAlcoholic,
        bool _isSmoker,
        bool _isSmokelessTobaccoUser,
        string memory _surgicalHistory_ifAny,
        string memory _physicalActivityLevel,
        string memory _pastMedicationDetails_IfAny
     
        )
        public {
            require(PatientsMedicalDetails[_walletAddress].walletAddress!=_walletAddress,"Patient medical details already exist!!");
            require(_walletAddress!=address(0), "Kindly fill all the mandatory feilds!!");
            PatientsMedicalDetails[_walletAddress]=PatientMedicalDetails(_walletAddress,
            _isAlcoholic,
            _isSmoker,
            _isSmokelessTobaccoUser,
            _surgicalHistory_ifAny,
            _physicalActivityLevel,
            _pastMedicationDetails_IfAny
        
            );
            if (PatientsPersonalDetails[_walletAddress].walletAddress==_walletAddress) {
                totalPatient++;
            } 
           
    }
     function AddPatientsPersonalDetails(
        bool _isAlive,
        string memory _name,
        address _walletAddress,
        string memory _gender,
        string memory _Occupation,
        uint256 _dayOfBirth,
        uint256 _monthOfBirth,
        uint256 _yearOfBirth)public _onlyAdmin{
            require(PatientsPersonalDetails[_walletAddress].walletAddress!=_walletAddress,"Patient's personal details already exist!!");
        require(_walletAddress!=address(0) && bytes(_gender).length>0 && bytes(_Occupation).length>0 && _dayOfBirth!=0 && _dayOfBirth<30 && _monthOfBirth!=0 && _monthOfBirth<12 && _yearOfBirth!=0 ,"Kindly fill all the mandatory feilds!!");
    
        uint256 age=getAge(_yearOfBirth);
       
        PatientsPersonalDetails[_walletAddress] = PatientPersonalDetails(_isAlive,
        _name,
        _walletAddress,
        _gender,
        _Occupation,
        _dayOfBirth,
        _monthOfBirth,
        _yearOfBirth,
        age
        );
        if (PatientsMedicalDetails[_walletAddress].walletAddress==_walletAddress) {
            totalPatient++;
        } 
    }
    

    function addPatientHealthDetails(
        address _walletAddress,
        address _physician,
        string memory _Department_uint,
        string memory _BloodPressure,
        string memory _HeartRate,
        string memory _RespiratoryRate,
        string memory _Dosage

        ) public  {

        require(PatientsPersonalDetails[_walletAddress].isAlive, "We regret to say that,this Patient is dead and cannot add Health details anymore!!");
        require(PatientsPersonalDetails[_walletAddress].walletAddress==_walletAddress && PatientsMedicalDetails[_walletAddress].walletAddress==_walletAddress,"Incorrect Patient wallet address or The Patient detail for the address provided not available in the chain!!");

        require(DoctorsPersonalInfo[_walletAddress].walletAddress==_physician, "Incorrect Physician wallet address or The Physician detail for the address provided not available in the chain!! ");

        HealthCondition[_walletAddress].push(PatientHealthCondition(_walletAddress,
        _physician,
        _Department_uint,
        _BloodPressure,
        _HeartRate,
        _RespiratoryRate,
        _Dosage
        ));
        Doctors_ProfessionalDetails[_physician].treatedPatients.push(_walletAddress);
    }

      function getPatientDetails(address _walletAddress) public userOrAdmin view returns(PatientPersonalDetails memory,PatientMedicalDetails memory){
        require(_walletAddress!=address(0),"Wallet Address cannot be empty");
        require(PatientsPersonalDetails[_walletAddress].walletAddress==_walletAddress && PatientsMedicalDetails[_walletAddress].walletAddress==_walletAddress,"Incorrect Patient wallet address or The Patient detail for the address provided is not completly available in the chain!!");
        return (
            PatientsPersonalDetails[_walletAddress],PatientsMedicalDetails[_walletAddress]
        );
    }

    function getPatientHealthDetails(address _walletAddress)public userOrAdmin view  returns(PatientHealthCondition[] memory){
        return HealthCondition[_walletAddress];
    }
function EditPatientMedicalDetails(
    bool _isAlcoholic,
        bool _isSmoker,
        bool _isSmokelessTobaccoUser,
        string memory _surgicalHistory_ifAny,
        string memory _physicalActivityLevel,
        string memory _pastMedicationDetails_IfAny
        
)public _onlyAdmin(){
    
}
function EditPatinetMedicalDetails(
      address _walletAddress,
        bool _isAlcoholic,
        bool _isSmoker,
        bool _isSmokelessTobaccoUser,
        string memory _surgicalHistory_ifAny,
        string memory _physicalActivityLevel,
        string memory _pastMedicationDetails_IfAny
       
)public {
    require(_walletAddress!=address(0) ,"Kindly fill all the mandatory feilds!!");

        require(PatientsPersonalDetails[_walletAddress].walletAddress==_walletAddress,"Incorrect Patient wallet address or The Patient detail for the address provided not available in the chain!!");
        PatientsMedicalDetails[_walletAddress]=PatientMedicalDetails(_walletAddress,
        _isAlcoholic,
        _isSmoker,
        _isSmokelessTobaccoUser,
        _surgicalHistory_ifAny,
        _physicalActivityLevel,
        _pastMedicationDetails_IfAny

        );
}
    function EditPatientPersonalDetails(bool _isAlive,
        string memory _name,
        address _walletAddress,
        string memory _gender,
        string memory _Occupation,
        uint256 _dayOfBirth,
        uint256 _monthOfBirth,
        uint256 _yearOfBirth)public _onlyAdmin(){
           
        require(_walletAddress!=address(0) && bytes(_gender).length>0 && bytes(_Occupation).length>0 && _dayOfBirth!=0 &&_monthOfBirth!=0 && _yearOfBirth!=0  ,"Kindly fill all the mandatory feilds!!");

        require(PatientsPersonalDetails[_walletAddress].walletAddress==_walletAddress,"Incorrect Patient wallet address or The Patient detail for the address provided not available in the chain!!");
            
      
        uint256 age=getAge(_yearOfBirth);

       
         PatientsPersonalDetails[_walletAddress] = PatientPersonalDetails( _isAlive,
        _name,
        _walletAddress,
        _gender,
        _Occupation,
        _dayOfBirth,
        _monthOfBirth,
        _yearOfBirth,
        age
        );
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;
// import "./Patient.sol";
contract DoctorDetails {
    address public owner;
  constructor () {
    owner = msg.sender;
    AddAdminAccess(msg.sender);
  }
     modifier _onlyOwner() {
        require(msg.sender==owner, "Accesseble only for Owners");
        _;
    }
  modifier _onlyAdmin(){
      bool checkAccess;
      if (OnlyOwner[msg.sender]) {
          checkAccess=true;
      }
    require(OnlyOwner[msg.sender]   ,"Only the Admin can call this function due to security reasons!!!");
    _;
  }

    struct DoctorPersonalInfo{
        string name;
        address walletAddress;
        uint256 dayOfBirth;
        uint256 monthOfBirth;
        uint256 yearOfBirth;
        uint256 age;
        uint256 phoneNumber;
        string email;
    }
    struct DoctorProfessionalDetails{
        address walletAddress;
        string MedicalSchoolAttended;
        string MedicalLicenseNumber;
        string Specialization;
        string AvailableTimings;
        uint ExperienceInYear;
        address[] treatedPatients;
        bool isLicenseValid;
        }
                   
    address[] public AdminAccess;
    mapping (address=>bool)public OnlyOwner;
    mapping(address=>DoctorPersonalInfo)public DoctorsPersonalInfo;
    mapping (address=>DoctorProfessionalDetails)public Doctors_ProfessionalDetails;
    uint256 public totalDoctors;
    uint256 public totalAdmin;

 

    function getYear(uint256 timestamp) public pure returns (uint256) {
        return timestamp / (365 * 24 * 60 * 60);
    }

    function getAge(uint256 _yearOfBirth)public view returns(uint256){
       
         uint256 yearDifference=getYear(block.timestamp);
        uint256 age=(1970+yearDifference)-_yearOfBirth;
        require(age>0, "Enter correct birth year");
        return age;
    }
    
    function AddAdminAccess(address _walletAddress)public _onlyOwner(){
        require(msg.sender==owner,"Only owner has privilege to add owner access!!");
        require(!OnlyOwner[_walletAddress], "Address already has admin access");
        require(_walletAddress!=address(0), "Invalid Address");
        AdminAccess.push(_walletAddress);
        OnlyOwner[_walletAddress]=true;
        totalAdmin++;
    }
    function DeleteAdminAccess(address _walletAddress)public _onlyOwner() {
        require(msg.sender==owner,"Only owner has privilege to delete owner access!!");
        require(_walletAddress!=address(0), "Invalid Address");
        require(OnlyOwner[_walletAddress], "Provided address must be an AdminAccessAddress to remove AdminAccess!!");
        OnlyOwner[_walletAddress]=false;
    }
    
    function AddDoctorProfessionalInfo( address _walletAddress,string memory _MedicalLicenseNumber,
        string memory _Specialization,
        string memory _AvailableTimings,
        uint _ExperienceInYear,
          string memory _MedicalSchoolAttended,
        bool _isLicenseValid)public  _onlyOwner{
             require(Doctors_ProfessionalDetails[_walletAddress].walletAddress!=_walletAddress, "Physician Professional details already exist!!");
        require(Doctors_ProfessionalDetails[_walletAddress].walletAddress!=_walletAddress && bytes(_MedicalSchoolAttended).length>0 &&  bytes(_MedicalLicenseNumber).length>0 && bytes(_Specialization).length>0 && bytes(_AvailableTimings).length>0,
        "Enter Correct details");
        Doctors_ProfessionalDetails[_walletAddress]=DoctorProfessionalDetails(
                _walletAddress,
                 _MedicalSchoolAttended,
                _MedicalLicenseNumber,
                _Specialization,
                _AvailableTimings,
                _ExperienceInYear,
                new address[](0),
                _isLicenseValid
            );
            if (DoctorsPersonalInfo[_walletAddress].walletAddress==_walletAddress) {
                AddAdminAccess(_walletAddress);
                totalDoctors++;
            }
         }
    function AddDoctorPersonalInfo( 
        string  memory _name,
        address _walletAddress,
      
        uint256 _dayOfBirth,
        uint256 _monthOfBirth,
        uint256 _yearOfBirth,
        uint256 _phoneNumber,
        string memory _email
        
        )public _onlyOwner{
require(DoctorsPersonalInfo[_walletAddress].walletAddress!=_walletAddress , "Physician personal detail already exist!!");
// uint getCurrentYear=getYear(block.timestamp / (365 * 24 * 60 * 60))+1970;
       require( _walletAddress!=address(0) &&  _dayOfBirth>0 && _dayOfBirth<=31 && _monthOfBirth>0 && _monthOfBirth<=12 &&_yearOfBirth>0&&  _phoneNumber>0 &&bytes(_email).length>0 &&bytes(_name).length>0 
        ,"Kindly fill all the mandatory feilds properly!!");
       uint256 age=getAge(_yearOfBirth);
     
            DoctorsPersonalInfo[_walletAddress]=DoctorPersonalInfo(_name,
                _walletAddress,
                _dayOfBirth,
                _monthOfBirth,
                _yearOfBirth,
                age,
                _phoneNumber,
                _email
               
            );
          
          if (Doctors_ProfessionalDetails[_walletAddress].walletAddress==_walletAddress) {
              AddAdminAccess(_walletAddress);
              totalDoctors++;
          }
            
    }
    function getDoctor(address _walletAddress) public _onlyOwner view returns(DoctorPersonalInfo memory,DoctorProfessionalDetails memory){
       require(_walletAddress!=address(0),"Wallet Address cannot be empty");
        require(DoctorsPersonalInfo[_walletAddress].walletAddress==_walletAddress && Doctors_ProfessionalDetails[_walletAddress].walletAddress==_walletAddress ,"Incorrect Patient wallet address or The Patient detail for the address provided is not completely available in the chain!!");
       
       return (
            DoctorsPersonalInfo[_walletAddress],Doctors_ProfessionalDetails[_walletAddress]
        );
       
    }
    function EditDoctorProfessionalDetails(address _walletAddress,string memory _MedicalLicenseNumber,
        string memory _Specialization, 
        string memory _AvailableTimings,
        uint _ExperienceInYear,
        string memory _MedicalSchoolAttended,
        bool _isLicenseValid,
        address[] memory _treatedPatients)public _onlyOwner{
        require(_walletAddress!=address(0) && bytes(_MedicalSchoolAttended).length>0 && bytes(_MedicalLicenseNumber).length>0 && bytes(_Specialization).length>0 && 
         bytes(_AvailableTimings).length>0,"enter correct details" );
         require(Doctors_ProfessionalDetails[_walletAddress].walletAddress==_walletAddress, "Incorrect Doctor's wallet address or The Doctor detail for the address provided not available in the chain!!");
        Doctors_ProfessionalDetails[_walletAddress]=DoctorProfessionalDetails( _walletAddress,
                _MedicalSchoolAttended,
                _MedicalLicenseNumber,
                _Specialization,
                _AvailableTimings,
                _ExperienceInYear,
                _treatedPatients,
                _isLicenseValid
            );
         }
        function EditDoctorPersonalDetails( 
        string memory _name,
        address _walletAddress,
     
        uint256 _dayOfBirth,
        uint256 _monthOfBirth,
        uint256 _yearOfBirth,
        uint256 _phoneNumber,
        string memory _email
        
        )public _onlyOwner{

       require(_walletAddress!=address(0) 
        && _dayOfBirth>0 && _monthOfBirth>0 && _yearOfBirth>0&& _phoneNumber>0 &&bytes(_email).length>0
         &&bytes(_name).length>0 ,"Kindly fill all the mandatory feilds properly!!");

        require(DoctorsPersonalInfo[_walletAddress].walletAddress==_walletAddress,"Incorrect Doctor's wallet address or The Doctor detail for the address provided not available in the chain!!");

       uint256 age=getAge(_yearOfBirth);
  
            DoctorsPersonalInfo[_walletAddress]=DoctorPersonalInfo(
                _name,
                _walletAddress,
                _dayOfBirth,
                _monthOfBirth,
                _yearOfBirth,
                age,
                _phoneNumber,
                _email
               
            );
         
    }

}