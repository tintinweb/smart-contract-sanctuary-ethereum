// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract AnyExecuteV3 {
    uint256 counter;
    mapping(uint256=>uint32) public results ;
    mapping(uint256=>bytes) public resultBytes;
    function makeCall(address contractToExecute, bytes memory databytes) public returns(bool, bytes memory) {
        (bool success, bytes memory retData) = (contractToExecute).call(databytes);  
        if (success) results[counter] = 100;
        else results[counter] = 999;
        resultBytes[counter] = retData;
        counter ++;
        return (success, retData);
    }

    function makeDelegateCall(address contractToExecute, bytes memory databytes) public returns(bool, bytes memory) {
        (bool success, bytes memory retData) = (contractToExecute).delegatecall(databytes);  
        if (success) results[counter] = 100;
        else results[counter] = 999;
        resultBytes[counter] = retData;
        counter ++;
        return (success, retData);
    }
    function makeStaticCall(address contractToExecute, bytes memory databytes) public returns(bool, bytes memory) {
        (bool success, bytes memory retData) = (contractToExecute).staticcall(databytes);  
        if (success) results[counter] = 100;
        else results[counter] = 999;
        resultBytes[counter] = retData;
        counter ++;
        return (success, retData);
    }

    function getCounter() public view returns (uint256 ) {
        return counter;
    }


    function getResults(uint256 i) public view returns (uint32 ) {
        return results[i];
    }

    function getResultBytes(uint256 i) public view returns (bytes memory) {
        return resultBytes[i];
    }
}