/**
 *Submitted for verification at Etherscan.io on 2022-08-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
contract college{
    bytes32 public hash;
    address public owner;
    bool public certificatevalid;
    bytes32 public hash2;

constructor(){
    owner= msg.sender;
}
modifier onlyowner(){
    require(msg.sender==owner);
    _;
}

    function getinfo(string memory name, string memory yearofpassing, uint rollno)public pure returns(bytes32){
        return keccak256(abi.encodePacked(name,yearofpassing,rollno));
}
   function givecertificate(string memory name, string memory yearofpassing, uint rollno)public onlyowner{
       hash = getinfo(name,yearofpassing,rollno);
   }

   function verifycertificate(string memory name, string memory yearofpassing, uint rollno)public {
       hash2 = getinfo(name,yearofpassing,rollno);
       if(hash == hash2){
        certificatevalid = true;
        }

   }


}