/**
 *Submitted for verification at Etherscan.io on 2023-01-13
*/

pragma solidity ^0.8.9;

interface IContract {
    function attempt() external;
}

contract Winner {
    address public targetAddress;
    address public owner;

    constructor(address _targetAddress) {
        owner = msg.sender;
        targetAddress = _targetAddress;
    }

    function attemptWinner() external onlyOwner {
        IContract(targetAddress).attempt();
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }
}