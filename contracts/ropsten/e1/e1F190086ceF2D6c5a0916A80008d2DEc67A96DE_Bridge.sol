/**
 *Submitted for verification at Etherscan.io on 2022-05-19
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

contract Bridge{
    address public bridgeOwner;
    mapping(address => bool) public AirDrops;

    event owner(uint wallclock_time, address indexed owner);
    event newfaucet(uint wallclock_time, address indexed faucet);
    event removefaucet(uint wallclock_time, address indexed faucet);

    constructor(){
        bridgeOwner = msg.sender;
        emit owner(block.timestamp, bridgeOwner);
    }

    function authorize() external view returns(bool){
        require(AirDrops[msg.sender] == true,'only faucet');
        if(tx.origin == bridgeOwner)
            return true;
        else
            return false;
    }

    function allowance(address faucet) external returns(bool){
        require(msg.sender == bridgeOwner,'only owner');
        require(faucet != address(0),'faulty faucet address');
        AirDrops[faucet] = true;
        emit newfaucet(block.timestamp, faucet);
        return true;
    }

    function disallowance(address faucet) external returns(bool){
        require(msg.sender == bridgeOwner,'only owner');
        require(faucet != address(0),'faulty faucet address');
        AirDrops[faucet] = false;
        emit removefaucet(block.timestamp, faucet);
        return true;
    }
}