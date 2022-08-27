/**
 *Submitted for verification at Etherscan.io on 2022-08-27
*/

// SPDX-License-Identifier: UNLICENCED
pragma solidity 0.8.7;

contract ModifierCode {

    address owner;

    //Modifier
    modifier onlyowner{
        require(msg.sender == owner,"You are Not Owner, Only owner can call this Function");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    struct student {
        uint256 rollNo;
        string name;
        uint256 marks;
    }

    mapping (uint256 => student) students; //Mapping

    //msg.sender is callers Wallet Address
    function storeData (uint256 _rollNo, string memory name, uint256 _marks) public onlyowner {
        students[_rollNo] = student(_rollNo, name, _marks);
    }

    function getData (uint256 _rollNo) public view returns(uint256, string memory, uint256){
        return(students[_rollNo].rollNo, students[_rollNo].name, students[_rollNo].marks);
    }
}