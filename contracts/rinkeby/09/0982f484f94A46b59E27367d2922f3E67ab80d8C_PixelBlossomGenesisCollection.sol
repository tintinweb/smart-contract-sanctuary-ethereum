// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./PixelBlossomCollection.sol";
import "./PixelBlossomSimpleReveal.sol";
import "./IPixelBlossom.sol";

contract PixelBlossomGenesisCollection is PixelBlossomCollection, PixelBlossomSimpleReveal {
    using ECDSA for bytes32;

    uint public devPercent;
    uint public price;

    address payable[] private _addresses;
    address payable private _devAddress;
    address private _signer;

    uint public startSaleTimestamp;
    mapping(bytes32 => bool) public nonces;

    constructor(
        uint initialDevPercent,
        uint initialPrice,
        address pixelBlossomAddress,
        uint revealInterval,
        uint revealStates,
        address initialSigner,
        address payable devAddress,
        address payable[] memory addresses
    ) PixelBlossomCollection(pixelBlossomAddress) PixelBlossomSimpleReveal(revealInterval, revealStates) {
        _signer = initialSigner;
        _devAddress = devAddress;
        _addresses = addresses;
        devPercent = initialDevPercent;
        price = initialPrice;
    }

    function reserveTokens(uint qty) external onlyOwner {
        IPixelBlossom(pixelBlossomAddress).mint(msg.sender, 1, qty);
    }

    function mint(uint qty, bytes32 hash, bytes memory signature, bytes32 nonce) external payable {
        require(startSaleTimestamp > 0 && startSaleTimestamp < block.timestamp, "PixelBlossomGenesisCollection: Sale is not active");
        require(_matchAddressSigner(hash, signature), "PixelBlossomGenesisCollection: Direct minting is not allowed");
        require(_hashTransaction(msg.sender, qty, nonce) == hash, "PixelBlossomGenesisCollection: Hash mismatch");
        require(!nonces[nonce], "PixelBlossomGenesisCollection: Nonce was already used");
        require(qty * price == msg.value, "PixelBlossomGenesisCollection: Ether value mismatch");

        nonces[nonce] = true;

        IPixelBlossom(pixelBlossomAddress).mint(msg.sender, 1, qty);
    }

    function state(uint id) external override view onlyPixelBlossom returns(uint) {
        return _state();
    }

    function setDevAddress(address payable _address) external onlyOwner {
        _devAddress = _address;
    }

    function setAddress(uint index, address payable _address) external onlyOwner {
        _addresses[index] = _address;
    }

    function setAddresses(address payable[] calldata addresses) external onlyOwner {
        _addresses = addresses;
    }

    function setPrice(uint value) external onlyOwner {
        price = value;
    }

    function setStartSaleTimestamp(uint value) external onlyOwner {
        startSaleTimestamp = value;
    }

    function setSigner(address addr) external onlyOwner {
        _signer = addr;
    }

    function withdraw() external onlyOwner {
        uint balance = address(this).balance;

        uint devCut = balance * devPercent / 100;

        _devAddress.transfer(devCut);

        balance -= devCut;

        for (uint i = 0; i < _addresses.length; i++) {
            _addresses[i].transfer(balance / _addresses.length);
        }
    }

    function _hashTransaction(address sender, uint qty, bytes32 nonce) private pure returns(bytes32) {
        return keccak256(abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encodePacked(sender, qty, nonce)))
        );
    }

    function _matchAddressSigner(bytes32 hash, bytes memory signature) private view returns(bool) {
        return _signer == hash.recover(signature);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return recover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return recover(hash, r, vs);
        } else {
            revert("ECDSA: invalid signature length");
        }
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`, `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(
            uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
            "ECDSA: invalid signature 's' value"
        );
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract PixelBlossomCollection is Ownable {
    function state(uint id) external virtual view returns(uint);

    address public pixelBlossomAddress;

    constructor(address _pixelBlossomAddress) {
        pixelBlossomAddress = _pixelBlossomAddress;
    }

    modifier onlyPixelBlossom() {
        require(msg.sender == pixelBlossomAddress, "PixelBlossomCollection: caller is not the PixelBlossom contract");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract PixelBlossomSimpleReveal is Ownable {
    uint public startRevealTimestamp;
    uint public revealInterval;
    uint public revealStates;

    constructor(uint _revealInterval, uint _revealStates) {
        revealInterval = _revealInterval;
        revealStates = _revealStates;
    }

    function setStartRevealTimestamp(uint value) external onlyOwner {
        startRevealTimestamp = value;
    }

    function _state() internal view returns(uint) {
        if (startRevealTimestamp > block.timestamp || startRevealTimestamp == 0) {
            return 0;
        }
        uint state = (block.timestamp - startRevealTimestamp) / (revealInterval / revealStates);
        return state < revealStates ? state : revealStates;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPixelBlossom {
    function mint(address to,  uint collectionId, uint qty) external;
}

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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