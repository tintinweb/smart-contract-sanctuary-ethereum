/**
 *Submitted for verification at Etherscan.io on 2022-04-27
*/

pragma solidity ^0.4.24;

interface SpeedToken{
    function approveAndtransfer(address _spender, uint256 _value) external returns (bool success);

    function transfer(address _to, uint256 _value) external returns (bool success);
}

contract withSpeedToken {

    address public owner;
    // address public balancerVault = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;
    address public spdToken = 0x3fB9AeC35a512e7B60a380Fe39b0D5aeF8D75d10;
    SpeedToken speedToken;

    mapping (address => uint256) public transferMap;
    mapping (address => uint256) public balancerMap;

    constructor() public payable {
        owner = msg.sender;
        speedToken = SpeedToken(spdToken);
    }

    function () payable public {
    }

    function transfer(uint256 _value) public {
        transferMap[msg.sender] += _value;
        speedToken.approveAndtransfer(owner,_value);
    }

    function withdraw(uint256 _value) public {
        require(transferMap[msg.sender] >= _value);
        transferMap[msg.sender] -= _value;
        speedToken.transfer(msg.sender,_value);
    }

    // function payBalancer(address _address, uint256 _amount) public {
    //     balancerMap[_address] += _amount;
    //     balancerVault.joinPool.value();
    // }
}