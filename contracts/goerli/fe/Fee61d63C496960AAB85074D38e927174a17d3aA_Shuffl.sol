pragma solidity 0.8.12;

interface IERC721 {
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

pragma solidity 0.8.12;

interface IUsdt {
    function transferFrom(address from, address to, uint value) external;
    function balanceOf(address who) external view returns (uint);
    function approve(address spender, uint value) external;
    function allowance(address owner, address spender) external view returns (uint);
    function transfer(address to, uint value) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.12;

import "./IERC721.sol";
import "./Strings.sol";
import "./IUsdt.sol";

contract Shuffl {
    event Swapped(
        address indexed _nftContract,
        uint256 indexed _tokenId,
        address indexed _sender,
        uint256 _price
    );

    event OwnershipTransferred(
        address indexed _oldOwner,
        address indexed _newOwner
    );

    using Strings for uint256;

    address public owner;

    IUsdt public immutable usdt;

    constructor(IUsdt _usdt) payable {
        owner = msg.sender;
        usdt = _usdt;
    }

    function transferOwnership(address _newOwner) external {
        require(msg.sender == owner, "Not owner");

        owner = _newOwner;

        emit OwnershipTransferred(owner, _newOwner);
    }

    function swap(
        IERC721 _nftContract,
        uint256 _tokenId,
        uint256 _price,
        uint256 _expirationTimestamp,
        uint8 v,
        bytes32 r,
        bytes32 s) public {

        string memory addressString = Strings.toHexString(address(_nftContract));
        string memory message = string.concat(addressString, _tokenId.toString(), _price.toString(), _expirationTimestamp.toString());
        address signer = verifyString(message, v, r, s);

        require(signer == owner, "Signer must be owner");
        require(block.timestamp < _expirationTimestamp, "Expired");

        _nftContract.transferFrom(msg.sender, owner, _tokenId);

        usdt.transferFrom(owner, msg.sender, _price);

        emit Swapped(address(_nftContract), _tokenId, msg.sender, _price);
    }

    // Returns the address that signed a given string message
    function verifyString(
        string memory message,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) private pure returns (address signer) {

        // The message header; we will fill in the length next
        string memory header = "\x19Ethereum Signed Message:\n000000";

        uint256 lengthOffset;
        uint256 length;
        assembly {
        // The first word of a string is its length
            length := mload(message)
        // The beginning of the base-10 message length in the prefix
            lengthOffset := add(header, 57)
        }

        // Maximum length we support
        require(length <= 999999);

        // The length of the message's length in base-10
        uint256 lengthLength = 0;

        // The divisor to get the next left-most message length digit
        uint256 divisor = 100000;

        // Move one digit of the message length to the right at a time
        while (divisor != 0) {

            // The place value at the divisor
            uint256 digit = length / divisor;
            if (digit == 0) {
                // Skip leading zeros
                if (lengthLength == 0) {
                    divisor /= 10;
                    continue;
                }
            }

            // Found a non-zero digit or non-leading zero digit
            lengthLength++;

            // Remove this digit from the message length's current value
            length -= digit * divisor;

            // Shift our base-10 divisor over
            divisor /= 10;

            // Convert the digit to its ASCII representation (man ascii)
            digit += 0x30;
            // Move to the next character and write the digit
            lengthOffset++;

            assembly {
                mstore8(lengthOffset, digit)
            }
        }

        // The null string requires exactly 1 zero (unskip 1 leading 0)
        if (lengthLength == 0) {
            lengthLength = 1 + 0x19 + 1;
        } else {
            lengthLength += 1 + 0x19;
        }

        // Truncate the tailing zeros from the header
        assembly {
            mstore(header, lengthLength)
        }

        // Perform the elliptic curve recover operation
        bytes32 check = keccak256(abi.encodePacked(header, message));

        return ecrecover(check, v, r, s);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity 0.8.12;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
    * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }

    /**
    * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }
}