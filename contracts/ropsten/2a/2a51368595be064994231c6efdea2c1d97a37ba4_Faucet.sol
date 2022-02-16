/**
 *Submitted for verification at Etherscan.io on 2022-02-15
*/

// File: fomowhatfaucet.sol

pragma solidity ^0.5.1;

interface ERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract Faucet {
    uint256 constant public tokenAmount = 1000;
    uint256 constant public waitTime = 30 minutes;

    ERC20 public tokenInstance = ERC20(0x700ED1e83B9210DbeFa570b9B57c6B325b033Cd7);
    
    mapping(address => uint256) lastAccessTime;

    constructor() public {
      // No longer require a constructor.
    }

    function requestTokens() public {
        require(allowedToWithdraw(msg.sender));
        tokenInstance.transfer(msg.sender, tokenAmount);
        lastAccessTime[msg.sender] = block.timestamp + waitTime;
    }

    function allowedToWithdraw(address _address) public view returns (bool) {
        if(lastAccessTime[_address] == 0) {
            return true;
        } else if(block.timestamp >= lastAccessTime[_address]) {
            return true;
        }
        return false;
    }
}