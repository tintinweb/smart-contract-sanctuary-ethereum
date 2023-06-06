// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
    struct SpentItem {
        uint256 itemType;
        address token;
        uint256 identifier;
        uint256 amount;
    }

    struct SpentItem2 {
        uint256 itemType;
        uint256 token;
        uint256 identifier;
        uint256 amount;
    }

contract Storage {
    event eventArr(SpentItem[] item);
    event eventArr2(SpentItem[] item, SpentItem[] item2);

    function store(SpentItem[] calldata item) public {
        emit eventArr(item);
        emit eventArr2(item,item);
    }
}