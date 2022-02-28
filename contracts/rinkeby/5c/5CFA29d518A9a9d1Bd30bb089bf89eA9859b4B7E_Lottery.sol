//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Lottery {
    mapping(address => uint) public senderToNumber;
    
    modifier haveNumber() {
        require(
            senderToNumber[msg.sender] == 0,
            "You already have a number."
        );
        _;
    }

    modifier notZero(uint _num) {
        require(_num > 0, "Number should not be 0.");
        _;
    }
    function sum(uint _a, uint _b) public pure returns(uint) {
        return _a + _b;
    }

    function getSender() public view returns(address) {
        return msg.sender;
    }

    function saveNumber(uint _num) external notZero(_num) haveNumber {
        senderToNumber[msg.sender] = _num;
    }

    function getNumber() external view returns(uint) {
        return senderToNumber[msg.sender];
    }
}