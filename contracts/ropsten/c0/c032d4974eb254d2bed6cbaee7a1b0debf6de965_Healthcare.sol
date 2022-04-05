/**
 *Submitted for verification at Etherscan.io on 2022-04-05
*/

pragma solidity ^0.5.2;
pragma experimental ABIEncoderV2;
contract Healthcare{

    address admin ;

    struct Patient{
        uint id;
         uint policyNum;
        uint Aadhar;
       uint phone;
       address wallet;
       uint history ;
       
    }
    uint nextPationtId;
    constructor() public{
        admin= msg.sender;
    }

    address[] public doctors;
   mapping(uint=>Patient) public patients;


    //add doctors
    function addDoctor(address _doctor) public{
        require(msg.sender==admin);
        doctors.push(_doctor);
    }

    //add pacent data
    function addData(uint _policyNum,uint _adhar,uint _phone,address _wallet,uint _history) public{
      patients[nextPationtId]= Patient(nextPationtId,_policyNum,_adhar,_phone,_wallet,_history);
    }

    // function retriveData(uint _id)public{
        
    // }

}