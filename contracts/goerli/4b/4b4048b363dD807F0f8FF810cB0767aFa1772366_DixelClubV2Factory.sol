// SPDX-License-Identifier: BSD-3-Clause

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./lib/StringUtils.sol";
import "./Constants.sol";
import "./Shared.sol";
import "./IDixelClubV2NFT.sol";

/**
* @title Dixel Club (V2) NFT Factory
*
* Create an ERC721 Dixel Club NFTs using proxy pattern to save gas
*/
contract DixelClubV2Factory is Constants, Ownable {
    error DixelClubV2Factory__BlankedName();
    error DixelClubV2Factory__BlankedSymbol();
    error DixelClubV2Factory__DescriptionTooLong();
    error DixelClubV2Factory__InvalidMaxSupply();
    error DixelClubV2Factory__InvalidRoyalty();
    error DixelClubV2Factory__NameContainedMalicious();
    error DixelClubV2Factory__SymbolContainedMalicious();
    error DixelClubV2Factory__DescriptionContainedMalicious();
    error DixelClubV2Factory__InvalidCreationFee();
    error DixelClubV2Factory__ZeroAddress();
    error DixelClubV2Factory__InvalidFee();

    /**
     *  EIP-1167: Minimal Proxy Contract - ERC721 Token implementation contract
     *  REF: https://github.com/optionality/clone-factory
     */
    address public nftImplementation;

    address public beneficiary = address(0x82CA6d313BffE56E9096b16633dfD414148D66b1);
    uint256 public creationFee = 0.02 ether; // 0.02 ETH (~$50)
    uint256 public mintingFee = 500; // 5%;

    // Array of all created nft collections
    address[] public collections;

    event CollectionCreated(address indexed nftAddress, string name, string symbol);

    constructor(address DixelClubV2NFTImpl) {
        nftImplementation = DixelClubV2NFTImpl;
    }

    function _createClone(address target) private returns (address result) {
        bytes20 targetBytes = bytes20(target);
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone, 0x14), targetBytes)
            mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            result := create(0, clone, 0x37)
        }
    }

    function createCollection(
        string calldata name,
        string calldata symbol,
        string calldata description,
        Shared.MetaData memory metaData,
        uint24[PALETTE_SIZE] calldata palette,
        uint8[PIXEL_ARRAY_SIZE] calldata pixels
    ) external payable returns (address) {
        if(bytes(name).length == 0) revert DixelClubV2Factory__BlankedName();
        if(bytes(symbol).length == 0) revert DixelClubV2Factory__BlankedSymbol();
        if(bytes(description).length > 1000) revert DixelClubV2Factory__DescriptionTooLong(); // ~900 gas per character
        if(metaData.maxSupply == 0 || metaData.maxSupply > MAX_SUPPLY) revert DixelClubV2Factory__InvalidMaxSupply();
        if(metaData.royaltyFriction > MAX_ROYALTY_FRACTION) revert DixelClubV2Factory__InvalidRoyalty();

        // Validate `symbol`, `name` and `description` to ensure generateJSON() creates a valid JSON
        if(StringUtils.contains(name, 0x22)) revert DixelClubV2Factory__NameContainedMalicious();
        if(StringUtils.contains(symbol, 0x22)) revert DixelClubV2Factory__SymbolContainedMalicious();
        if(StringUtils.contains(description, 0x22)) revert DixelClubV2Factory__DescriptionContainedMalicious();

        // Neutralize minting starts date
        if (metaData.mintingBeginsFrom < block.timestamp) {
            metaData.mintingBeginsFrom = uint40(block.timestamp);
        }

        if (creationFee > 0) {
            if(msg.value != creationFee) revert DixelClubV2Factory__InvalidCreationFee();

            // Send fee to the beneficiary
            (bool sent, ) = beneficiary.call{ value: creationFee }("");
            require(sent, "CREATION_FEE_TRANSFER_FAILED");
        }

        address nftAddress = _createClone(nftImplementation);
        IDixelClubV2NFT newNFT = IDixelClubV2NFT(nftAddress);
        newNFT.init(msg.sender, name, symbol, description, metaData, palette, pixels);

        collections.push(nftAddress);

        emit CollectionCreated(nftAddress, name, symbol);

        return nftAddress;
    }

    // MARK: Admin functions

    // This will update NFT contract implementaion and it won't affect existing collections
    function updateImplementation(address newImplementation) external onlyOwner {
        nftImplementation = newImplementation;
    }

    function updateBeneficiary(address newAddress, uint256 newCreationFee, uint256 newMintingFee) external onlyOwner {
        if(newAddress == address(0)) revert DixelClubV2Factory__ZeroAddress();
        if(newMintingFee > FRICTION_BASE) revert DixelClubV2Factory__InvalidFee();

        beneficiary = newAddress;
        mintingFee = newMintingFee;
        creationFee = newCreationFee;
    }

    // MARK: - Utility functions

    function collectionCount() external view returns (uint256) {
        return collections.length;
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

// SPDX-License-Identifier: BSD-3-Clause

import "@openzeppelin/contracts/utils/Strings.sol";

pragma solidity ^0.8.13;

library StringUtils {
    function contains(string memory haystack, bytes1 needle) internal pure returns (bool) {
        bytes memory haystackBytes = bytes(haystack);
        uint256 length = haystackBytes.length;
        for (uint256 i; i != length; ) {
            if (haystackBytes[i] == needle) {
                return true;
            }
            unchecked {
                ++i;
            }
        }

        return false;
    }

    function address2str(address addr) internal pure returns (string memory) {
        return Strings.toHexString(uint160(addr), 20);
    }
}

// SPDX-License-Identifier: BSD-3-Clause

pragma solidity ^0.8.13;

abstract contract Constants {
    uint256 public constant MAX_SUPPLY = 1000000; // 1M hardcap max
    uint256 public constant MAX_ROYALTY_FRACTION = 1000; // 10%
    uint256 public constant FRICTION_BASE = 10000;

    uint256 internal constant PALETTE_SIZE = 16; // 16 colors max - equal to the data type max value of CANVAS_SIZE (2^8 = 16)
    uint256 internal constant CANVAS_SIZE = 24; // 24x24 pixels
    uint256 internal constant TOTAL_PIXEL_COUNT = CANVAS_SIZE * CANVAS_SIZE; // 24x24
    uint256 internal constant PIXEL_ARRAY_SIZE = TOTAL_PIXEL_COUNT / 2; // packing 2 pixels in each uint8
}

// SPDX-License-Identifier: BSD-3-Clause

pragma solidity ^0.8.13;

library Shared {
    struct MetaData {
        bool whitelistOnly;
        bool hidden;
        uint24 maxSupply; // can be minted up to MAX_SUPPLY
        uint24 royaltyFriction; // used for `royaltyInfo` (ERC2981) and `seller_fee_basis_points` (Opeansea's Contract-level metadata)
        uint40 mintingBeginsFrom; // Timestamp that minting event begins
        uint152 mintingCost; // Native token (ETH, BNB, KLAY, etc)
    }
}

// SPDX-License-Identifier: BSD-3-Clause

pragma solidity ^0.8.13;

import "./Shared.sol";

interface IDixelClubV2NFT {
    function init(
        address owner_,
        string calldata name_,
        string calldata symbol_,
        string calldata description_,
        Shared.MetaData calldata metaData_,
        uint24[16] calldata palette_,
        uint8[288] calldata pixels_
    ) external;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}