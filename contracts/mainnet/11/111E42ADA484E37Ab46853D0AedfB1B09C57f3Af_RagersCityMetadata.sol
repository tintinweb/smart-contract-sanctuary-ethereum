// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

// @title:  Ragers City
// @desc:   Ragers City is a next-gen decentralized Manga owned by the community, featuring a collection of 5000 NFTs.
// @team:   https://twitter.com/RagersCity
// @author: https://linkedin.com/in/antoine-andrieux/
// @url:    https://ragerscity.com

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./interface/IRagersCityMetadata.sol";
import "./extensions/UnrevealedURI.sol";

contract RagersCityMetadata is IRagersCityMetadata, UnrevealedURI, Ownable {
    using Strings for uint256;

    // ======== URI =========
    string public uriPrefix = "";
    string public uriSuffix = ".json";

    // ======== Lock =========
    bool public locked = false;

    // ======== Events =========
    event UriPrefixUpdated(string _uriPrefix);
    event UriSuffixUpdated(string _uriSuffix);
    event Locked();

    // ======== Constructor =========
    constructor(string memory _unrevealedMetadata) {
        uriPrefix = _unrevealedMetadata;
    }

    modifier isUnlocked() {
        require(!locked, "Contract is locked!");
        _;
    }

    function lock() public override onlyOwner isUnlocked {
        locked = true;
        emit Locked();
    }

    function setUriPrefix(string calldata _uriPrefix) public onlyOwner isUnlocked {
        uriPrefix = _uriPrefix;
        emit UriPrefixUpdated(_uriPrefix);
    }

    function setEncryptedPrefix(bytes calldata _encryptedPrefix) external onlyOwner isUnlocked {
        _setEncryptedURI(_encryptedPrefix);
    }

    function setUriSuffix(string calldata _uriSuffix) external onlyOwner isUnlocked {
        uriSuffix = _uriSuffix;
        emit UriSuffixUpdated(_uriSuffix);
    }

    function reveal(bytes calldata _key)
        external
        onlyOwner
        override
        isUnlocked
        returns (string memory revealedURI)
    {
        // bytes memory key = bytes(_key);
        revealedURI = getRevealURI(_key);

        _setEncryptedURI("");
        uriPrefix = revealedURI;

        emit TokenURIRevealed(revealedURI);
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        string memory uri = _baseURI();

        if (isEncryptedURI()) {
            return uri;
        } else {
            return 
                bytes(uri).length > 0 ?
                    string(
                        abi.encodePacked(
                            uri, 
                            _tokenId.toString(), 
                            uriSuffix
                        )
                )
                : uri;
        }
    }

    function _baseURI() internal view virtual returns (string memory) {
        return uriPrefix;
    }

    // ======== Withdraw =========
    function withdraw() external onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

// @title:  Ragers City
// @desc:   Ragers City is a next-gen decentralized Manga owned by the community, featuring a collection of 5000 NFTs.
// @team:   https://twitter.com/RagersCity
// @author: https://linkedin.com/in/antoine-andrieux
// @url:    https://ragerscity.com

abstract contract IRagersCityMetadata {
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        returns (string memory);

    function lock() public virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

// @title:  Ragers City
// @desc:   Ragers City is a next-gen decentralized Manga owned by the community, featuring a collection of 5000 NFTs.
// @team:   https://twitter.com/RagersCity
// @author: https://linkedin.com/in/antoine-andrieux
// @url:    https://ragerscity.com

import "./interface/IUnrevealedURI.sol";

abstract contract UnrevealedURI is IUnrevealedURI {
    bytes public encryptedURI;

    // Set the encrypted URI
    function _setEncryptedURI(bytes memory _encryptedURI) internal {
        encryptedURI = _encryptedURI;
    }

    // Get the decrypted revealed URI
    function getRevealURI(bytes calldata _key) public view returns (string memory revealedURI) {
        bytes memory _encryptedURI = encryptedURI;
        if (_encryptedURI.length == 0) {
            revert("Nothing to reveal");
        }

        revealedURI = string(encryptDecrypt(_encryptedURI, _key));
    }

    // Encrypt/decrypt string data
    function encryptDecryptString(string memory _data, bytes calldata _key) public pure returns (bytes memory result) {
        return encryptDecrypt(bytes(_data), _key);
    }

    // https://ethereum.stackexchange.com/questions/69825/decrypt-message-on-chain
    function encryptDecrypt(bytes memory data, bytes calldata key) public pure override returns (bytes memory result) {
        // Store data length on stack for later use
        uint256 length = data.length;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Set result to free memory pointer
            result := mload(0x40)
            // Increase free memory pointer by lenght + 32
            mstore(0x40, add(add(result, length), 32))
            // Set result length
            mstore(result, length)
        }

        // Iterate over the data stepping by 32 bytes
        for (uint256 i = 0; i < length; i += 32) {
            // Generate hash of the key and offset
            bytes32 hash = keccak256(abi.encodePacked(key, i));

            bytes32 chunk;
            // solhint-disable-next-line no-inline-assembly
            assembly {
                // Read 32-bytes data chunk
                chunk := mload(add(data, add(i, 32)))
            }
            // XOR the chunk with hash
            chunk ^= hash;
            // solhint-disable-next-line no-inline-assembly
            assembly {
                // Write 32-byte encrypted chunk
                mstore(add(result, add(i, 32)), chunk)
            }
        }
    }

    function isEncryptedURI() public view returns (bool) {
        return encryptedURI.length != 0;
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

// @title:  Ragers City
// @desc:   Ragers City is a next-gen decentralized Manga owned by the community, featuring a collection of 5000 NFTs.
// @team:   https://twitter.com/RagersCity
// @author: https://linkedin.com/in/antoine-andrieux
// @url:    https://ragerscity.com

interface IUnrevealedURI {
    
    event TokenURIRevealed(string revealedURI);

    // Reveal an unrevealed URI
    function reveal(bytes calldata key) external returns (string memory revealedURI);

    // Encrypt/decrypt data (CTR encryption mode)
    function encryptDecrypt(bytes memory data, bytes calldata key) external pure returns (bytes memory result);
}