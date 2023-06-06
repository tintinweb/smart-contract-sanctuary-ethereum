/**
 *Submitted for verification at Etherscan.io on 2023-06-05
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
contract Yasin{
    string public  name;
    int public  RollNo;
    uint public PhoneNumber;
    address public MetaMaskAddress;
     
     function setName(string memory _name)public {
     name=_name;
}

function setRollNo(int _RollNo)public {
     RollNo=_RollNo;
}
function setPhoneNumber(uint _PhoneNumber)public {
 PhoneNumber=_PhoneNumber;
}
function setAddress(address _address)public {
MetaMaskAddress=_address;
}
}