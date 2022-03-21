/**
 *Submitted for verification at Etherscan.io on 2022-03-21
*/

//SPDX-License-Identifier: AFL-1.1
pragma solidity >= 0.5.0 < 0.9.0;
pragma experimental ABIEncoderV2;

contract ElmiMaximoSC {

    mapping(string => string) workorders;
    mapping(string => string) assets;
    mapping(string => string[]) hashesHistory;

    event StatusAdded(string woNum, string data);

    function getWorkOrder(string memory woNum) public view returns (string memory) {
        string memory wo = workorders[woNum];
        return wo;
    }

    function getAsset(string memory assetNum) public view returns (string memory) {
        string memory asset = assets[assetNum];
        return asset;
    }

    function getHistory(string memory woNum) public view returns (string[] memory) {
        string[] memory statusesHistory = hashesHistory[woNum];
        return statusesHistory;
    }

    
    function addWorkOrder(string memory woNum, string memory workorder) public
    {
        workorders[woNum] = workorder;
    }

    
    function addAsset(string memory assetNum, string memory asset) public
    {
        assets[assetNum] = asset;
    }

    function addHashes(string memory woNum, string memory data) public
    {
        /* Data should be something like JSON.stringify of: {statusID, ethHash, hlfHash}. */
        hashesHistory[woNum].push(data);
        
        emit StatusAdded(woNum, data);
    }
}