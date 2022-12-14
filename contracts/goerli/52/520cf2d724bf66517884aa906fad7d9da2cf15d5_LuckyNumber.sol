/**
 *Submitted for verification at Etherscan.io on 2022-12-14
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title LuckyNumber
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract LuckyNumber {
    uint256 luckyNumber;
    string luckyReason;

    // Storing
    function saveLuckyNumber(uint256 num) public {
        luckyNumber = num;
    }

    function saveLuckyNumberAndReason(uint256 num, string memory reason) public {
        luckyNumber = num;
        luckyReason = reason;
    }

    function saveLuckyReason(string memory reason) public {
        luckyReason = reason;
    }

    // retrieving
    function getLuckyNumber() public view returns (uint256) {
        return luckyNumber;
    }

    function getLuckyReason() public view returns (string memory) {
        return luckyReason;
    }
}