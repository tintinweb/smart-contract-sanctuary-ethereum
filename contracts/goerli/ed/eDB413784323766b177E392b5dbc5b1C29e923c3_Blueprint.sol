// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Base64.sol";

contract Blueprint is Ownable {   

    address public deadlyPerksAddress;
    mapping (address => address) public referenceAddresses;

    string[] public formation = [
        "0%",
        "1%",
        "2%",
        "4%",
        "8%",
        "16%",
        "32%"
    ];
    string[] public greed = [
       "???"
    ];

    string[] public lust = [
       "???"
    ];

    string[] public wrath = [
       "???"
    ];

    string[] public gluttony = [
       "???"
    ];

    string[] public pride = [
       "???"
    ];

    string[] public envy = [
       "???"
    ];

    string[] public sloth = [
        "???"
    ];

    string[] public key = [
       "Bronze Key",
       "Silver Key",
       "Golden Key",
       "Platinium Key",
       "Titanium Key",
       "Diamond Key",
       "Ethereal Key",
       "Cursed Key"
    ];

    string[] public prefixes = [
        "Father Discount: ",
        "Greed: ",
        "Lust: ",
        "Wrath: ",
        "Gluttony: ",
        "Pride: ",
        "Envy: ",
        "Sloth: ",
        "???: "
    ];
    function setFormation(string[] memory inputs) external onlyOwner {
        formation = inputs;
    }
    function setGreed(string[] memory inputs) external onlyOwner {
        greed = inputs;
    }
    function setLust(string[] memory inputs) external onlyOwner {
        lust = inputs;
    }
    function setWrath(string[] memory inputs) external onlyOwner {
        wrath = inputs;
    }
    function setGluttony(string[] memory inputs) external onlyOwner {
        gluttony = inputs;
    }
    function setPride(string[] memory inputs) external onlyOwner {
        pride = inputs;
    }
    function setEnvy(string[] memory inputs) external onlyOwner {
        envy = inputs;
    }
    function setSloth(string[] memory inputs) external onlyOwner {
        sloth = inputs;
    }
    function setDeadlyPerksAddress (address _address) external onlyOwner {
        deadlyPerksAddress = _address;
    }

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }
    function getFormation(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, prefixes[0], formation);
    }

    // rework into single string to be decoded on L2
    function getPerkPositions(
        uint256 tokenId
    ) public view returns (uint256[] memory) {
        uint256 rand;
        uint256[] memory positions = new uint256[](9);
        rand = random(
            string(abi.encodePacked(prefixes[0], toString(tokenId)))
        );
        positions[0] = rand % formation.length;
        rand = random(
            string(abi.encodePacked(prefixes[1], toString(tokenId)))
        );
        positions[1] = rand % greed.length;
        rand = random(
            string(abi.encodePacked(prefixes[2], toString(tokenId)))
        );
        positions[2] = rand % lust.length;
        rand = random(
            string(abi.encodePacked(prefixes[3], toString(tokenId)))
        );
        positions[3] = rand % wrath.length;
        rand = random(
            string(abi.encodePacked(prefixes[4], toString(tokenId)))
        );
        positions[4] = rand % gluttony.length;
        rand = random(
            string(abi.encodePacked(prefixes[5], toString(tokenId)))
        );
        positions[5] = rand % pride.length;
        rand = random(
            string(abi.encodePacked(prefixes[6], toString(tokenId)))
        );
        positions[6] = rand % envy.length;
        rand = random(
            string(abi.encodePacked(prefixes[7], toString(tokenId)))
        );
        positions[7] = rand % sloth.length;
        rand = random(
            string(abi.encodePacked(prefixes[8], toString(tokenId)))
        );
        positions[8] = rand % key.length;
        return positions;
    }

    function getPerk(uint256 tokenId, uint256 prefix) public view returns (string memory) {
        string[] memory perkList;
        if (prefix == 0) {
            perkList = formation;
        } else if (prefix == 1) {
            perkList = greed;
        } else if (prefix == 2) {
            perkList = lust;
        } else if (prefix == 3) {
            perkList = wrath;
        } else if (prefix == 4) {
            perkList = gluttony;
        } else if (prefix == 5) {
            perkList = pride;
        } else if (prefix == 6) {
            perkList = envy;
        } else if (prefix == 7) {
            perkList = sloth;
        } else if (prefix == 8) {
            perkList = key;
        }
        return pluck(tokenId, prefixes[prefix], perkList);
    }

    function pluck(
        uint256 tokenId,
        string memory keyPrefix,
        string[] memory sourceArray
    ) internal pure returns (string memory) {
        uint256 rand = random(
            string(abi.encodePacked(keyPrefix, toString(tokenId)))
        );
        string memory output = sourceArray[rand % sourceArray.length];
        output = string(abi.encodePacked(keyPrefix, output));
        return output;
    }
    function toString(uint256 value) public pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
    function tokenURI(uint256 tokenId)
        public
        view
        returns (string memory)
    {
        string[19] memory parts;
        parts[
            0
        ] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="10" y="20" class="base">';

        parts[1] = getPerk(tokenId,0);
        parts[2] = '</text><text x="10" y="40" class="base">';
        parts[3] = getPerk(tokenId,1);
        parts[4] = '</text><text x="10" y="60" class="base">';
        parts[5] = getPerk(tokenId,2);
        parts[6] = '</text><text x="10" y="80" class="base">';
        parts[7] = getPerk(tokenId,3);
        parts[8] = '</text><text x="10" y="100" class="base">';
        parts[9] = getPerk(tokenId,4);
        parts[10] = '</text><text x="10" y="120" class="base">';
        parts[11] = getPerk(tokenId,5);
        parts[12] = '</text><text x="10" y="140" class="base">';
        parts[13] = getPerk(tokenId,6);
        parts[14] = '</text><text x="10" y="160" class="base">';
        parts[15] = getPerk(tokenId,7);
        parts[16] = '</text><text x="10" y="180" class="base">';
        parts[17] = getPerk(tokenId,8);
        parts[18] = "</text></svg>";

        string memory output = string(
            abi.encodePacked(
                parts[0],
                parts[1],
                parts[2],
                parts[3],
                parts[4],
                parts[5],
                parts[6],
                parts[7],
                parts[8],
                parts[9]
            )
        );
        output = string(
            abi.encodePacked(
                output,
                parts[10],
                parts[11],
                parts[12],
                parts[13],
                parts[14],
                parts[15],
                parts[16],
                parts[17],
                parts[18]
            )
        );

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "Deadly Perks #',
                        toString(tokenId),
                        '", "description": "Deadly Perks are dynamic primitives, generated for Deadly Games and stored on chain. Each perk will be revealed when the game is announced.", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(output)),
                        '"}'
                    )
                )
            )
        );

        output = string(
            abi.encodePacked("data:application/json;base64,", json)
        );

        return output;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

library Base64 {
    bytes internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);
        
        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(input, 0x3F))), 0xFF)
                )
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}