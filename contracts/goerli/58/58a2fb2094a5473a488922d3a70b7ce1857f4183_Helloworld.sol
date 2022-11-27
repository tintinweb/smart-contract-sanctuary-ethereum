/**
 *Submitted for verification at Etherscan.io on 2022-11-27
*/

pragma solidity ^0.8.0;

contract Helloworld {
    uint256 public age = 22;
    string public name ="Ratchanon Nisakulrat";
    address public deployer;

    constructor() {//run 1 ครั้ง
        deployer = msg.sender; //ตัวแปรหาคนเรียก
    }
    function setName(string memory newName) public {
        require(msg.sender == deployer,"You're not authorized!");
        name = newName;
    }

    function setAge(uint256 newAge) public {
        age=newAge;
    }
}