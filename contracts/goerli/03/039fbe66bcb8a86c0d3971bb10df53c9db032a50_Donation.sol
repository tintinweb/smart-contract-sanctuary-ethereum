/**
 *Submitted for verification at Etherscan.io on 2022-11-16
*/

pragma solidity ^0.8.17;
pragma experimental ABIEncoderV2;

contract Donation { 
    address public onwer;
    mapping(address => uint256) donationlist;

    event Donate(address indexed sender, uint256 value);
    event Withdraw(address indexed onwer, uint256 value);

    modifier onlyOnwer() {
        require(msg.sender == onwer, "Only onwercan acess this function");
        _;
    }

    constructor() {
        onwer = msg.sender;
    }

    function donate() public payable {
        donationlist[msg.sender] += msg.value;
        emit Donate(msg.sender, msg.value);
    }

    function getHistory() public view returns (uint256) {
        return donationlist[msg.sender];
    }

    function withdraw() onlyOnwer public {
        address payable receiver = payable(onwer);
        uint256 value = address(this).balance;
        receiver.transfer(value);
        emit Withdraw(receiver, value);
    }
}