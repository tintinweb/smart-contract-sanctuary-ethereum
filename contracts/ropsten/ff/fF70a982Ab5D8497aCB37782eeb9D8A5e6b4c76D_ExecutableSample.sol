// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import { IAxelarExecutable } from './IAxelarExecutable.sol';
import {IAxelarGasService} from './IAxelarGasService.sol';
contract ExecutableSample is IAxelarExecutable {
    string public value;
    string public sourceChain;
    string public sourceAddress;
    string public destinationChain;
    string public destinationAddress;
    string public returnVal;
    IAxelarGasService gasReceiver;

    constructor(address gateway_, address gasReceiver_) IAxelarExecutable(gateway_) {
        gasReceiver = IAxelarGasService(gasReceiver_);
    }

    function setDestinationChain (string memory _chain) public  returns(bool){
        destinationChain = _chain;
        return true;
    }

    function setDestinationAddress (string memory _address) public  returns(bool){
        destinationAddress = _address;
        return true;
    }

    function callContract (string memory message) external payable{
        bytes memory payload = abi.encode(message);
        if(msg.value > 0) {
            gasReceiver.payNativeGasForContractCall{ value: msg.value }(
                address(this),
                destinationChain,
                destinationAddress,
                payload,
                msg.sender
            );
        }
        gateway.callContract(destinationChain, destinationAddress,payload);
    }


    function _execute (
        string memory sourceChain_,
        string memory sourceAddress_, 
        bytes calldata payload_
    ) internal override {
        (value) = abi.decode(payload_, (string));
        sourceChain = sourceChain_;
        sourceAddress = sourceAddress_;
        returnVal = value;
    }
}