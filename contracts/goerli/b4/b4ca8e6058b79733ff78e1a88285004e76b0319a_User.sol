/**
 *Submitted for verification at Etherscan.io on 2022-11-11
*/

contract User {

    mapping(address=>string) internal roles;
    mapping(address=>User) internal Users;

    struct   User{
        address userAddress;
        string userRole;
        uint flag;
        uint confirmedAppointmentsFlag;
        uint verifiedPrescriptionsFlag;
        address[] approvedAddress;
        string[]  verifiedPrescriptions;
        uint[] verifiedPrescriptionTimeStamp;
        uint timestampFlag;
        bool doesExist;
        string[] confirmedAppointments;

    }


    constructor() {

    }


    function createUser(address _address) public returns(User memory) {
        address[] memory arr;
        string[] memory arr2;
        uint[] memory arr3;
        string[] memory confirmedAppointments;
        bool exist = true;
        uint confirmedFlag;
        User memory user = User({userAddress:_address,userRole:"",flag:0,approvedAddress:arr,verifiedPrescriptions:arr2,verifiedPrescriptionsFlag:0,timestampFlag:0,verifiedPrescriptionTimeStamp:arr3,doesExist:exist,confirmedAppointments:confirmedAppointments,confirmedAppointmentsFlag:confirmedFlag});
        Users[_address] = user;
        return Users[_address];
    }

    function doesUserExist(address _address) external view returns(bool) {
        return Users[_address].doesExist;
    }

    function assignRoleToPatient(address _address) external  returns(string memory){
        Users[_address].userRole = "PATIENT";
        return Users[_address].userRole;
    }

    function assignRoleAsDoctor(address _address) external returns(string memory) {
        Users[_address].userRole = "DOCTOR";
        return Users[_address].userRole;

    }

    function assignRoleAsChemist(address _address) external returns(string memory) {
        Users[_address].userRole = "CHEMIST";
        return Users[_address].userRole;

    }

    function getUserRole(address _address) view external returns(string memory){
        return Users[_address].userRole;
    }



    function giveApproval(address userToBeApproved, address user) external returns(address[] memory){
        uint i = 0;
        ++i;
        Users[user].approvedAddress.push(userToBeApproved);
        Users[user].flag = i;
        return Users[user].approvedAddress;
    }



    function getApprovedArray(address user) view external returns(address[] memory){
        return Users[user].approvedAddress;
    }

    modifier onlyPatient(address walletAddress) {
        require(compareStrings(Users[walletAddress].userRole,"PATIENT")==true);
        _;
    }

    modifier onlyDoctor(address walletAddress) {
        require(compareStrings(Users[walletAddress].userRole,"DOCTOR")==true);
        _;
    }

    function approvedPrescription(address _address,string memory prescription_id) onlyPatient(_address) external returns(string memory){
        uint i = 0;
        ++i;
        Users[_address].verifiedPrescriptions.push(prescription_id);
        Users[_address].verifiedPrescriptionsFlag = i;
        return "SUCCESS";
    }

    function confirmAppointment(address _addressToConfirm,string memory appointID,address doctorAddress) onlyDoctor(doctorAddress) external returns(string memory){
        uint i = 0;
        ++i;
        Users[_addressToConfirm].confirmedAppointments.push(appointID);
        Users[_addressToConfirm].confirmedAppointmentsFlag = i;
        return "Confirmed";
    }


    function getApprovedPrescriptionArray(address _address) view external returns(string[] memory){
        return Users[_address].verifiedPrescriptions;
    }

    function compareStrings(string memory a, string memory b) public pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

}