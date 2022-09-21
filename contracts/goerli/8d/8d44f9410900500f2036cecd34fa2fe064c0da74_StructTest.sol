/**
 *Submitted for verification at Etherscan.io on 2022-09-21
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;


contract StructTest {

    struct Model {
        address receiverAddress;
        uint256 amount;
        MiddleModel middleModel;
        BridgeModel bridgeModel;
    }

    struct MiddleModel {
        uint256 middleAmount;
        bytes data;
    }

    struct BridgeModel {
        uint256 bridgeAmount;
        address bridgeAddress;
        bytes data;
    }

    Model public model;


    function setModel(Model calldata _model) public {
        model = _model;
    }
	
}