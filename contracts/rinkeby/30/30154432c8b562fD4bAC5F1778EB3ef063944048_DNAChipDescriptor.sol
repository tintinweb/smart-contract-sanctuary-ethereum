// SPDX-License-Identifier: MIT
/* solhint-disable quotes */
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Interfaces.sol";
import "./AnonymiceLibrary.sol";

contract DNAChipDescriptor is Ownable {
    address public dnaChipAddress;
    FreakChip public freakChip;
    RobotChip public robotChip;
    UnderworldChip public underworldChip;
    AlienChip public alienChip;
    mapping(uint8 => string) public basesToNames;

    constructor() {
        freakChip = new FreakChip();
        robotChip = new RobotChip();
        underworldChip = new UnderworldChip();
        alienChip = new AlienChip();
        basesToNames[1] = "Freak";
        basesToNames[2] = "Robot";
        basesToNames[3] = "Underworld";
        basesToNames[4] = "Alien";
    }

    function setAddresses(address _dnaChipAddress) external onlyOwner {
        dnaChipAddress = _dnaChipAddress;
    }

    function tokenURI(uint256 _tokenId) public view returns (string memory) {
        uint8 base = IDNAChip(dnaChipAddress).tokenIdToBase(_tokenId);
        uint8 level = IDNAChip(dnaChipAddress).tokenIdToLevel(_tokenId);
        string memory name = string(
            abi.encodePacked(
                '{"name": "DNA Chip #',
                AnonymiceLibrary.toString(_tokenId)
            )
        );

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    AnonymiceLibrary.encode(
                        bytes(
                            string(
                                abi.encodePacked(
                                    name,
                                    '", "image": "data:image/svg+xml;base64,',
                                    AnonymiceLibrary.encode(
                                        bytes(getBaseSVG(base, level))
                                    ),
                                    '","attributes":',
                                    getMetadata(base, level),
                                    ', "description": "DNA Chips is a collection of 3,550 DNA Chips. All the metadata and images are generated and stored 100% on-chain. No IPFS, no API. Just the Ethereum blockchain."',
                                    "}"
                                )
                            )
                        )
                    )
                )
            );
    }

    function getBaseSVG(uint8 base, uint8 level)
        internal
        view
        returns (string memory)
    {
        if (base == 1) {
            return freakChip.getSvg(level);
        }
        if (base == 2) {
            return robotChip.getSvg(level);
        }
        if (base == 3) {
            return underworldChip.getSvg(level);
        }
        if (base == 4) {
            return alienChip.getSvg(level);
        }
        revert("invalid base");
    }

    function getMetadata(uint8 base, uint8 level)
        internal
        view
        returns (string memory)
    {
        string memory metadataString;
        metadataString = string(
            abi.encodePacked(
                metadataString,
                '{"trait_type": "Type","value":"',
                basesToNames[base],
                '"}',
                ","
            )
        );
        metadataString = string(
            abi.encodePacked(
                metadataString,
                '{"trait_type": "Level","value":"',
                AnonymiceLibrary.toString(level),
                '"}'
            )
        );

        return string(abi.encodePacked("[", metadataString, "]"));
    }
}

contract FreakChip {
    function getSvg(uint8 level) public pure returns (string memory) {
        if (level == 1)
            return
                '<svg id="dna-chip" width="100%" height="100%" version="1.1" viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"> <text x="41" y="20" fill="red">Level 1</text> <image x="10" y="20" width="100" height="100" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,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" /> </svg>';
        if (level == 2)
            return
                '<svg id="dna-chip" width="100%" height="100%" version="1.1" viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"> <text x="41" y="20" fill="red">Level 2</text> <image x="10" y="20" width="100" height="100" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,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" /> </svg>';
        if (level == 3)
            return
                '<svg id="dna-chip" width="100%" height="100%" version="1.1" viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"> <text x="41" y="20" fill="red">Level 3</text> <image x="10" y="20" width="100" height="100" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,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" /> </svg>';
        revert("invalid level");
    }
}

contract RobotChip {
    function getSvg(uint8 level) public pure returns (string memory) {
        if (level == 1)
            return
                '<svg id="dna-chip" width="100%" height="100%" version="1.1" viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"> <text x="41" y="20" fill="red">Level 1</text> <image x="10" y="20" width="100" height="100" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,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" /> </svg>';
        if (level == 2)
            return
                '<svg id="dna-chip" width="100%" height="100%" version="1.1" viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"> <text x="41" y="20" fill="red">Level 2</text> <image x="10" y="20" width="100" height="100" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,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" /> </svg>';
        if (level == 3)
            return
                '<svg id="dna-chip" width="100%" height="100%" version="1.1" viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"> <text x="41" y="20" fill="red">Level 3</text> <image x="10" y="20" width="100" height="100" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,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" /> </svg>';
        revert("invalid level");
    }
}

contract UnderworldChip {
    function getSvg(uint8 level) public pure returns (string memory) {
        if (level == 1)
            return
                '<svg id="dna-chip" width="100%" height="100%" version="1.1" viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"> <text x="41" y="20" fill="red">Level 1</text> <image x="10" y="20" width="100" height="100" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,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" /> </svg>';
        if (level == 2)
            return
                '<svg id="dna-chip" width="100%" height="100%" version="1.1" viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"> <text x="41" y="20" fill="red">Level 2</text> <image x="10" y="20" width="100" height="100" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,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" /> </svg>';
        if (level == 3)
            return
                '<svg id="dna-chip" width="100%" height="100%" version="1.1" viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"> <text x="41" y="20" fill="red">Level 3</text> <image x="10" y="20" width="100" height="100" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,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" /> </svg>';
        revert("invalid level");
    }
}

contract AlienChip {
    function getSvg(uint8 level) public pure returns (string memory) {
        if (level == 1)
            return
                '<svg id="dna-chip" width="100%" height="100%" version="1.1" viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"> <text x="41" y="20" fill="red">Level 1</text> <image x="10" y="20" width="100" height="100" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,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"/> </svg>';
        if (level == 2)
            return
                '<svg id="dna-chip" width="100%" height="100%" version="1.1" viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"> <text x="41" y="20" fill="red">Level 2</text> <image x="10" y="20" width="100" height="100" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,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" /> </svg>';
        if (level == 3)
            return
                '<svg id="dna-chip" width="100%" height="100%" version="1.1" viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"> <text x="41" y="20" fill="red">Level 3</text> <image x="10" y="20" width="100" height="100" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,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"/> </svg>';
        revert("invalid level");
    }
}

/* solhint-enable quotes */

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

pragma solidity ^0.8.7;

interface RewardLike {
    function mintMany(address to, uint256 amount) external;
}

interface IDNAChip is RewardLike {
    function tokenIdToBase(uint256 tokenId) external view returns (uint8);

    function tokenIdToLevel(uint256 tokenId) external view returns (uint8);
}

interface IDescriptor {
    function tokenURI(uint256 _tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library AnonymiceLibrary {
    string internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load the table into memory
        string memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {

            } lt(dataPtr, endPtr) {

            } {
                dataPtr := add(dataPtr, 3)

                // read 3 bytes
                let input := mload(dataPtr)

                // write 4 characters
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(input, 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
        }

        return result;
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
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

    function parseInt(string memory _a)
        internal
        pure
        returns (uint8 _parsedInt)
    {
        bytes memory bresult = bytes(_a);
        uint8 mint = 0;
        for (uint8 i = 0; i < bresult.length; i++) {
            if (
                (uint8(uint8(bresult[i])) >= 48) &&
                (uint8(uint8(bresult[i])) <= 57)
            ) {
                mint *= 10;
                mint += uint8(bresult[i]) - 48;
            }
        }
        return mint;
    }

    function substring(
        string memory str,
        uint256 startIndex,
        uint256 endIndex
    ) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = strBytes[i];
        }
        return string(result);
    }

    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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