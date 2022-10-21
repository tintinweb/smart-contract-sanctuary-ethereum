/**
 *Submitted for verification at Etherscan.io on 2022-10-21
*/

//SPDX-License-Identifier; MIT
pragma solidity ^0.8.10;

contract voting{

    //Declare vote parameter
    mapping (string => uint256) public votes;
    // votes["ม่วง"] = 5
     // votes["เขียว"] = 7

    //Declare title 
    string [] public title;

    //Declare owner
    address public owner; // 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
    constructor(){
        owner = msg.sender;
    }

    //craete title function 
    function creatTitle(string memory _title) public {
        require(owner == msg.sender, "Only owner can create title."); //ต้องเป็นคนที่สร้างเท่านั้น
        title.push(_title);
        votes[_title] = 0;
    }
    //vote
    function vote(string memory _title) public {
        votes[_title] += 1;
        // votes["ม่วง"] = 5+1
    }

    function checkLength() public view returns(uint) {
        return title.length;
    }
}