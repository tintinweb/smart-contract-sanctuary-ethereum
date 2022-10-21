/**
 *Submitted for verification at Etherscan.io on 2022-10-21
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

contract Voting {

    // Declare vote parameter
    mapping (string => uint256) public votes;
  
    // Declare title list
    string [] public title;

    // Declare owner
    address public owner;         // จะเก็บเลขกระเป๋าเอาไว้
    constructor() {               // ทำตอน Deploy แค่ครั้งเดียว
        owner = msg.sender;       // 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
    }

    // Create title function
    function createTitle(string memory _title) public {
        require(owner == msg.sender, "Only owner can create title.");  //owner = คนที่ทำ transaction เท่านั้น
        title.push(_title);
        votes[_title] = 0;
    }
    
    // Vote
    function vote(string memory _title) public {    
        votes[_title] += 1;     
    }
    function checklength() public view returns(uint) {
        return title.length;
    }
}