// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./interfaces/INightWatchMetadata.sol";
import "@solmate/utils/LibString.sol";
import "@solmate/auth/Owned.sol";

/// @title Metadata contract of Night Watch
/// @notice Separate metadata contract to support future possible on-chain image generation
/// @author Yigit Duman
/// @custom:experimental This is an experimental contract and does not represent the final work.
contract NightWatchMetadata is INightWatchMetadata, Owned {
    string private _baseURI = "";

    constructor(string memory baseURI) Owned(msg.sender) {
        _baseURI = baseURI;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseURI = baseURI;
    }

    function tokenURI(uint256 tokenId)
        external
        view
        virtual
        override
        returns (string memory)
    {
        return string(abi.encodePacked(_baseURI, LibString.toString(tokenId)));
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

/// @title Metadata contract interface of Night Watch
/// @author Yigit Duman
/// @custom:experimental This is an experimental contract and does not represent the final work.
interface INightWatchMetadata {
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice Efficient library for creating string representations of integers.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/LibString.sol)
/// @author Modified from Solady (https://github.com/Vectorized/solady/blob/main/src/utils/LibString.sol)
library LibString {
    function toString(uint256 value) internal pure returns (string memory str) {
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit), but we allocate 160 bytes
            // to keep the free memory pointer word aligned. We'll need 1 word for the length, 1 word for the
            // trailing zeros padding, and 3 other words for a max of 78 digits. In total: 5 * 32 = 160 bytes.
            let newFreeMemoryPointer := add(mload(0x40), 160)

            // Update the free memory pointer to avoid overriding our string.
            mstore(0x40, newFreeMemoryPointer)

            // Assign str to the end of the zone of newly allocated memory.
            str := sub(newFreeMemoryPointer, 32)

            // Clean the last word of memory it may not be overwritten.
            mstore(str, 0)

            // Cache the end of the memory to calculate the length later.
            let end := str

            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for { let temp := value } 1 {} {
                // Move the pointer 1 byte to the left.
                str := sub(str, 1)

                // Write the character to the pointer.
                // The ASCII index of the '0' character is 48.
                mstore8(str, add(48, mod(temp, 10)))

                // Keep dividing temp until zero.
                temp := div(temp, 10)

                 // prettier-ignore
                if iszero(temp) { break }
            }

            // Compute and cache the final total length of the string.
            let length := sub(end, str)

            // Move the pointer 32 bytes leftwards to make room for the length.
            str := sub(str, 32)

            // Store the string's length at the start of memory allocated for our string.
            mstore(str, length)
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnershipTransferred(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnershipTransferred(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function transferOwnership(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnershipTransferred(msg.sender, newOwner);
    }
}