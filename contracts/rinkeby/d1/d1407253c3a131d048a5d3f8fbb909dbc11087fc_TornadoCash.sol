/**
 *Submitted for verification at Etherscan.io on 2022-09-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/// @title Ownable contract
contract Ownable {
    
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  
    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}
/// @title Mortal contract - used to selfdestruct once we have no use of this contract
contract Mortal is Ownable {
    function executeSelfdestruct() public onlyOwner {
        selfdestruct(payable(owner));
    }
}

/// @title ERC20 contract
/// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
interface ERC20 {
    function totalSupply() external view returns(uint);
    function balanceOf(address who) external view returns (uint);
    function transfer(address to, uint value) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    
    function allowance(address owner, address spender) external view returns (uint);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function approve(address spender, uint value) external returns (bool);
    event Approval(address indexed owner, address indexed spender, uint value);
}

/// @title WizzleInfinityHelper contract
contract TornadoCash is Mortal {
    address public relayer;
     bytes32[] public allInfos;
     struct allInfo {
        address sendAddress;
        uint256 amount;
        string hash;
        bool state;
        uint256 time;
    }
    allInfo[] _info;
    mapping (string=> allInfo) datas;
    
    function deposit(string memory _hash, uint256 _amount) public payable {
        require(_amount == msg.value, "wrong value");
        allInfo memory newInfo;
        newInfo.sendAddress = msg.sender;
        newInfo.amount = _amount;
        newInfo.hash = _hash;
        newInfo.state = true;
        newInfo.time = block.timestamp;
        datas[_hash] = newInfo;
    }

    function withdraw(address _recipient, string memory _hash) public {
        require(_recipient != address(0), "can not transfer to zero address");
        require(datas[_hash].time!=0,"wrong hash");
        require(datas[_hash].state, "already done withdraw");
        datas[_hash].state = false;
        uint256 balance = datas[_hash].amount;
        payable(_recipient).transfer(balance-balance*3/1000);
        payable(relayer).transfer(balance*3/1000);
    }

     function setRelayer(address _relayer) public onlyOwner{
        require(_relayer != address(0), "can not set to zero address");
        relayer = _relayer;
    }
}