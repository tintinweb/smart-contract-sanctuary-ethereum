//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IlliniTask {
    function publicKey() external view returns (bytes memory);

    function sendTask(string calldata data) external;
}

contract DevTakeHome {
    function send(address _contractAddr, string calldata _data) public {
        IlliniTask(_contractAddr).sendTask(_data);
    }

    function getKey(address _contractAddr) public view returns (bytes memory) {
        return IlliniTask(_contractAddr).publicKey();
    } 
}