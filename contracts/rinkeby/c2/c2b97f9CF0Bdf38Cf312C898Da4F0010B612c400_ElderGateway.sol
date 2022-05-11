/**
 *Submitted for verification at Etherscan.io on 2022-05-11
*/

// Sources flattened with hardhat v2.9.2 https://hardhat.org

// File contracts/quests_skills/ElderGateway.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface INFT {
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external;
}

contract ElderGateway {

    struct Details {
        address user; // owner of tokenId
        uint256 blockNo; // block.number when locked
    }
    mapping(address => mapping(uint256 => Details)) public lockedData;

    struct StakeItem {
        address nft;
        uint256[] tokenIds;
    }

    event Locked(address indexed nft, uint256[] tokenIds, address indexed user);
    event Unlocked(address indexed nft, uint256[] tokenIds, address indexed user);

    /**
    * @dev Locks multiple tokenIds from multiple collections.
    * @param items list of items to be locked.
    */
    function lock(StakeItem[] calldata items) external {
        for (uint8 i = 0; i < items.length; i++) {
            for (uint8 j = 0; j < items[i].tokenIds.length; j++) {
                INFT(items[i].nft).transferFrom(msg.sender, address(this), items[i].tokenIds[j]);
                lockedData[items[i].nft][items[i].tokenIds[j]].user = msg.sender;
                lockedData[items[i].nft][items[i].tokenIds[j]].blockNo = block.number;
            }
            emit Locked(items[i].nft, items[i].tokenIds, msg.sender);
        }
    }

    /**
    * @dev Unlocks multiple tokenIds from multiple collections.
    * @param items list of items to be unlocked.
    */
    function unlock(StakeItem[] calldata items) external {
        for (uint8 i = 0; i < items.length; i++) {
            for (uint8 j = 0; j < items[i].tokenIds.length; j++) {
                require(msg.sender == lockedData[items[i].nft][items[i].tokenIds[j]].user, "Invalid tokenId.");
                require(block.number > lockedData[items[i].nft][items[i].tokenIds[j]].blockNo, "Unlock too fast.");

                INFT(items[i].nft).transferFrom(address(this), msg.sender, items[i].tokenIds[j]);
                delete lockedData[items[i].nft][items[i].tokenIds[j]];
            }
            emit Unlocked(items[i].nft, items[i].tokenIds, msg.sender);
        }
    }

}