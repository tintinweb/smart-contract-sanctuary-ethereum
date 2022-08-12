/**
 *Submitted for verification at Etherscan.io on 2022-08-12
*/

pragma solidity 0.8.7;
// SPDX-License-Identifier: Unlicensed

contract ContractDeployer {

    ContractToDeploy public contractInstance;

    function deployContract() public {
        bytes32 salt = bytes32(uint256(0x01));
        contractInstance = new ContractToDeploy{salt: salt}();
    }
}

contract ContractToDeploy {

    function testFunc() public pure returns(string memory) {
        return "test";
    }
}