// SPDX-License-Identifier: MIT
/* solhint-disable quotes */
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Interfaces.sol";
import "./AnonymiceLibrary.sol";

contract PodFragmentDescriptor is Ownable {
    function tokenURI(uint256 id) public pure returns (string memory) {
        string memory name = string(abi.encodePacked('{"name": "Pod Fragments'));

        if (id == 1) {
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
                                        AnonymiceLibrary.encode(bytes(getSvg())),
                                        '","attributes": [],',
                                        '"description": "Pod Fragments are lost artifacts, salvaged from hidden worlds in the Anonymice universe. 3 fragments are required to assemble an Anonymice Evolution Pod. All the metadata and images are generated and stored 100% on-chain. No IPFS, no API. Just the Ethereum blockchain."',
                                        "}"
                                    )
                                )
                            )
                        )
                    )
                );
        }
        revert("unknown item id");
    }

    function getSvg() public pure returns (string memory) {
        return
            '<svg id="pod-fragment" width="100%" height="100%" version="1.1" viewBox="0 0 80 80" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"> <image x="0" y="0" width="80" height="80" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,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" /> </svg>';
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

pragma solidity ^0.8.7;

interface RewardLike {
    function mintMany(address to, uint256 amount) external;
}

interface IDNAChip is RewardLike {
    function tokenIdToTraits(uint256 tokenId) external view returns (uint256);

    function isEvolutionPod(uint256 tokenId) external view returns (bool);

    function breedingIdToEvolutionPod(uint256 tokenId) external view returns (uint256);
}

interface IDescriptor {
    function tokenURI(uint256 _tokenId) external view returns (string memory);

    function tokenBreedingURI(uint256 _tokenId, uint256 _breedingId) external view returns (string memory);
}

interface IEvolutionTraits {
    function getDNAChipSVG(uint256 base) external view returns (string memory);

    function getEvolutionPodImageTag(uint256 base) external view returns (string memory);

    function getTraitsImageTags(uint8[8] memory traits) external view returns (string memory);

    function getMetadata(uint8[8] memory traits) external view returns (string memory);
}

interface IERC721Like {
    function transferFrom(
        address from,
        address to,
        uint256 id
    ) external;

    function transfer(address to, uint256 id) external;

    function ownerOf(uint256 id) external returns (address owner);

    function mint(address to, uint256 tokenid) external;
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