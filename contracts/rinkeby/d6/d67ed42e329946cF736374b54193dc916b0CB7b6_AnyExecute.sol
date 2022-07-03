// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract AnyExecute {
    uint256 counter;
    function execute(address contractToExecute, bytes memory databytes) public returns(bool success, bytes memory data) {
        counter ++;
        return (contractToExecute).call{value:1*10**17, gas: 100000}(databytes);  
    }

    function getCounter() public view returns (uint256 ) {
        return counter;
    }
}