/**
 *Submitted for verification at Etherscan.io on 2022-03-17
*/

//SPDX-License-Identifier: AFL-1.1
pragma solidity >= 0.5.0 < 0.9.0;
pragma experimental ABIEncoderV2;

contract WebinarElmi2022SC {

    mapping(string => string) workorders;
    mapping(string => string) assets;

    function getWorkOrder(string memory woNum) public view returns (string memory) {
        string memory wo = workorders[woNum];
        return wo;
    }

    function getAsset(string memory assetNum) public view returns (string memory) {
        string memory asset = assets[assetNum];
        return asset;
    }

    
    function addWorkOrder(string memory woNum, string memory workorder) public
    {
        workorders[woNum] = workorder;
    }

    
    function addAsset(string memory assetNum, string memory asset) public
    {
        assets[assetNum] = asset;
    }
}