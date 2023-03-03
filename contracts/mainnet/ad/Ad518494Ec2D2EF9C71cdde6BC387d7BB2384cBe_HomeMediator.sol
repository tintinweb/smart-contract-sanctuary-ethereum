// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "./IAM.sol";

contract HomeMediator {
    
    address HOMEAMB;
    // address ForeignAMB;

    uint256 public value;
    // address public lastSender;
    // bytes32 public messageId;
    // bytes32 public txHash;
    // uint256 public messageSourceChainId;

    constructor(address _HOMEAMB){
        HOMEAMB = _HOMEAMB;

    }

    function setValue(uint256 _value) external{

        value = _value;

        // lastSender = IAMB(msg.sender).messageSender();
        // messageId = IAMB(msg.sender).messageId();
        // txHash = IAMB(msg.sender).transactionHash();
        // messageSourceChainId = uint256(IAMB(msg.sender).messageSourceChainId());

    
    }

    function setValueOnOtherNetwork(uint256 _value,address _foreignMediator)public{
        bytes4 methodSelector = this.setValue.selector;
        bytes memory encodedData = abi.encodeWithSelector(methodSelector, _value);
        IAMB(HOMEAMB).requireToPassMessage(_foreignMediator,encodedData, 20000);
    }
}