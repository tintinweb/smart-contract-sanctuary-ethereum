/**
 *Submitted for verification at Etherscan.io on 2022-05-12
*/

// File: contracts/HW8.sol


pragma solidity ^0.8.10;

contract SimpleBank {
    uint public InputValue;
    address public owner;
    constructor() payable {
        InputValue = msg.value;
        owner = msg.sender;
    }
    mapping( address => uint ) private JOJOMap;
    
    function getBalance() public view returns (uint) {
        return JOJOMap[owner];
    }
    function deposit() external payable returns (uint) {
        JOJOMap[owner] += InputValue;
        if(! (JOJOMap[owner] > 0))
            JOJOMap[owner] = InputValue;
        else
            JOJOMap[owner] = JOJOMap[owner] + msg.value;
        return JOJOMap[owner];
    }

    function withdraw(uint amount) external payable {
        require(JOJOMap[owner] >= amount,"not enough");
        uint amount_Gwei = amount*10*6;
        JOJOMap[owner] = JOJOMap[owner] - amount_Gwei;
        owner.call{value: amount_Gwei}("");
   }


}