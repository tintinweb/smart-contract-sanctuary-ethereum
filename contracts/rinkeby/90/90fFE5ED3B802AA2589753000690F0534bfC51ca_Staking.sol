/**
 *Submitted for verification at Etherscan.io on 2022-06-19
*/

pragma solidity >=0.7.0 <0.9.0;

contract Staking {
    address public owner;

    mapping(address => uint256) public stakers;

    constructor() {
        owner = msg.sender;
    }

    modifier _onlyOwner() {
        require(msg.sender == owner, "Rights restricted.");
        _;
    }

    function stake() external payable {
        stakers[msg.sender] += msg.value;
    }

    function unstake() external payable {
        require(stakers[msg.sender] > msg.value, "Not enough balance");

        stakers[msg.sender] -= msg.value;
    }
}