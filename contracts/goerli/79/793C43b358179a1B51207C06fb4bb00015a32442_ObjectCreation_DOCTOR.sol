// SPDX-License-Identifier: MIT
pragma solidity 0.8.9   ;
import "contracts/SimpleStorage_DOCTOR.sol";
contract ObjectCreation_DOCTOR{
    SimpleStorage_DOCTOR doctor;
    function set(string memory doctor_description, string memory doctor_name) public payable{
        doctor = new SimpleStorage_DOCTOR(doctor_description, doctor_name);
    }
    function infoD() public view returns (string memory){
        return doctor.getDes();
    }
    function infoNm() public view returns (string memory){
        return doctor.getNm();
    }
}

/*
CONTRACTY NAME: SimpleStorage_DOCTOR
THIS CONTRACT SERVES AS A SINGLE CONTRACT FILE FOR : STORING DOCTOR META DATA
TO GET USER CAT: DOCTOR TO CREATE A NEW BLOCK CHAIN
*/
// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
contract SimpleStorage_DOCTOR   {
    string    DESCRIPTION_DOCTOR;
    string    DOCTOR_NAME;


    constructor(string memory doctor_description, 
    string memory doctor_name)    {
        DESCRIPTION_DOCTOR  =   doctor_description;
        DOCTOR_NAME         =   doctor_name;
    }



    function getDes() external view returns(string memory){
        return DESCRIPTION_DOCTOR;
    }


    function getNm() external view returns(string memory){
        
        
        return DOCTOR_NAME;
    }
}