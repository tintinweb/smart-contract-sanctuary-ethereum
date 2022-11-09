/**
 *Submitted for verification at Etherscan.io on 2022-11-09
*/

/**
 *Submitted for verification at Etherscan.io on 2022-11-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title The Lost Kitty
/// @author https://twitter.com/Cryptonicle1
/// @notice Lucas is a scientist who has lost his cat in a big house that has 2^256 rooms, anon can you find it?
/// @custom:url https://www.ctfprotocol.com/tracks/eko2022/hidden-kittycat
contract HiddenKittyCat {
    address private immutable _owner;

    constructor() {
        _owner = msg.sender;
        bytes32 slot = keccak256(abi.encodePacked(block.timestamp, blockhash(block.number - 69)));

        assembly {
            sstore(slot, "KittyCat!")
        }
    }

    function areYouHidingHere(bytes32 slot) external view returns (bool) {
        require(msg.sender == _owner, "!owner");
        bytes32 kittyPointer;

        assembly {
            kittyPointer := sload(slot)
        }

        return kittyPointer == "KittyCat!";
    }

    function destroyMe() external {
        require(msg.sender == _owner, "!owner");
        selfdestruct(payable(address(0)));
    }
}

contract House {
    bool public catFound;

    function isKittyCatHere(bytes32 _slot) external {
        if (catFound) {
            return;
        }
        HiddenKittyCat hiddenKittyCat = new HiddenKittyCat();
        bool found = hiddenKittyCat.areYouHidingHere(_slot);

        if (!found) {
          //  hiddenKittyCat.destroyMe();
        } else {
            catFound = true;
        }
    }

    function getHash(uint256 blockNumber,uint256 hash) public view returns(bytes32) {
        return (keccak256(abi.encodePacked(blockNumber, blockhash(hash))));
    }
}