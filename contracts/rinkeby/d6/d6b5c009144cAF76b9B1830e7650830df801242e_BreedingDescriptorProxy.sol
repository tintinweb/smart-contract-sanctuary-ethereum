// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./AnonymiceLibrary.sol";
import "./RedactedLibrary.sol";
import "./Interfaces.sol";

contract BreedingDescriptorProxy is Ownable {
    address public breedingDescriptorAddress;
    address public dnaChipDescriptorAddress;
    address public dnaChipAddress;

    function setAddresses(
        address _breedingDescriptorAddress,
        address _dnaChipDescriptorAddress,
        address _dnaChipAddress
    ) external onlyOwner {
        breedingDescriptorAddress = _breedingDescriptorAddress;
        dnaChipDescriptorAddress = _dnaChipDescriptorAddress;
        dnaChipAddress = _dnaChipAddress;
    }

    function tokenURI(uint256 _tokenId) public view returns (string memory) {
        uint256 evolutionPodId = IDNAChip(dnaChipAddress).breedingIdToEvolutionPod(_tokenId);
        if (evolutionPodId > 0) {
            return IDescriptor(dnaChipDescriptorAddress).tokenBreedingURI(evolutionPodId);
        }
        return IDescriptor(breedingDescriptorAddress).tokenURI(_tokenId);
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
pragma solidity ^0.8.7;

library RedactedLibrary {
    struct Traits {
        uint256 base;
        uint256 earrings;
        uint256 eyes;
        uint256 hats;
        uint256 mouths;
        uint256 necks;
        uint256 noses;
        uint256 whiskers;
    }

    struct TightTraits {
        uint8 base;
        uint8 earrings;
        uint8 eyes;
        uint8 hats;
        uint8 mouths;
        uint8 necks;
        uint8 noses;
        uint8 whiskers;
    }

    function traitsToRepresentation(Traits memory traits) internal pure returns (uint256) {
        uint256 representation = uint256(traits.base);
        representation |= traits.earrings << 8;
        representation |= traits.eyes << 16;
        representation |= traits.hats << 24;
        representation |= traits.mouths << 32;
        representation |= traits.necks << 40;
        representation |= traits.noses << 48;
        representation |= traits.whiskers << 56;

        return representation;
    }

    function representationToTraits(uint256 representation) internal pure returns (Traits memory traits) {
        traits.base = uint8(representation);
        traits.earrings = uint8(representation >> 8);
        traits.eyes = uint8(representation >> 16);
        traits.hats = uint8(representation >> 24);
        traits.mouths = uint8(representation >> 32);
        traits.necks = uint8(representation >> 40);
        traits.noses = uint8(representation >> 48);
        traits.whiskers = uint8(representation >> 56);
    }

    function representationToTraitsArray(uint256 representation) internal pure returns (uint8[8] memory traitsArray) {
        traitsArray[0] = uint8(representation); // base
        traitsArray[1] = uint8(representation >> 8); // earrings
        traitsArray[2] = uint8(representation >> 16); // eyes
        traitsArray[3] = uint8(representation >> 24); // hats
        traitsArray[4] = uint8(representation >> 32); // mouths
        traitsArray[5] = uint8(representation >> 40); // necks
        traitsArray[6] = uint8(representation >> 48); // noses
        traitsArray[7] = uint8(representation >> 56); // whiskers
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

    function tokenIdToTraits(uint256 tokenId) external view returns (uint256);

    function breedingIdToEvolutionPod(uint256 tokenId) external view returns (uint256);
}

interface IDescriptor {
    function tokenURI(uint256 _tokenId) external view returns (string memory);

    function tokenBreedingURI(uint256 _tokenId) external view returns (string memory);
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