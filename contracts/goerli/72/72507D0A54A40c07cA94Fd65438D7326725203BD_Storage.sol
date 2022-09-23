/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract Storage {

    uint256 sredstva;

    function smesti() public payable {
        sredstva = msg.value;
    }

    function uzmi() public {
        payable(address(msg.sender)).transfer(sredstva / 10);
        sredstva = sredstva / 10;
    }

}