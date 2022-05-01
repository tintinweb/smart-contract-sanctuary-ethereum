// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./FxBaseRootTunnel.sol";

contract RootETH is FxBaseRootTunnel {


    constructor(address _checkPointManager, address _fxRoot) FxBaseRootTunnel(_checkPointManager, _fxRoot){

    }


    function _processMessageFromChild(bytes memory message) internal override {
        // We don't need a message from child
    }


    function sendMsgToChild(string memory _message) public {
        _sendMessageToChild(abi.encode(msg.sender, _message, block.timestamp));
    }

    function setFxChildTunnel(address _fxChildTunnel) public override {
        fxChildTunnel = _fxChildTunnel;
    }
    
    
    
}