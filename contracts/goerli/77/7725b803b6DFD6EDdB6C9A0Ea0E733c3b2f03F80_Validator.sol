// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./utils/cryptography/ECDSA.sol";

contract Validator is Ownable {
    using EC for bytes32;

    mapping (uint => mapping(address => bool)) validatorMap;
    mapping (uint => address[]) public validators; // postchain block height => validators
    uint[] public validatorHeights;

    event ValidatorAdded(uint height, address indexed _validator);
    event ValidatorRemoved(uint height, address indexed _validator);

    constructor(address[] memory _validators) {
        validators[0] = _validators;
        for (uint i = 0; i < validators[0].length; i++) {
            validatorMap[0][validators[0][i]] = true;
        }
        validatorHeights.push(0);
    }

    function isValidator(uint _height, address _addr) public view returns (bool) {
        return validatorMap[_height][_addr];
    }
    
    function addValidator(uint _height, address _validator) external onlyOwner {
        if (_height < validatorHeights[validatorHeights.length-1]) {
            revert("Validator: cannot update previous heights' validator");
        } else if (_height > validatorHeights[validatorHeights.length-1]) {
            validatorHeights.push(_height);
        }
        require(!validatorMap[_height][_validator]);
        validators[_height].push(_validator);
        validatorMap[_height][_validator] = true;
        emit ValidatorAdded(_height, _validator);
    }

    function removeValidator(uint _height, address _validator) external onlyOwner {
        if (_height < validatorHeights[validatorHeights.length-1]) {
            revert("Validator: cannot update previous heights' validator");
        }
        require(isValidator(_height, _validator));
        uint index;
        uint validatorCount = validators[_height].length;
        for (uint i = 0; i < validatorCount; i++) {
            if (validators[_height][i] == _validator) {
                index = i;
                break;
            }
        }

        validatorMap[_height][_validator] = false;
        validators[_height][index] = validators[_height][validatorCount - 1];
        validators[_height].pop();

        emit ValidatorRemoved(_height, _validator);
    }

    function getValidatorHeight(uint _height) external view returns (uint) {
        return _getValidatorHeight(_height);
    }

    function _getValidatorHeight(uint _height) internal view returns (uint) {
        uint lastIndex = validatorHeights.length-1;
        uint lastHeight = validatorHeights[lastIndex];
        if (_height >= lastHeight) {
            return lastHeight;
        } else {
            for (uint i = lastIndex; i > 0; i--) {
                if (_height < validatorHeights[i] && _height >= validatorHeights[i-1]) {
                    return validatorHeights[i-1];
                }
            }
            return 0;
        }
    }

    function isValidSignatures(uint height, bytes32 hash, bytes[] memory signatures, address[] memory signers) external view returns (bool) {
        uint _actualSignature = 0;
        uint _requiredSignature = _calculateBFTRequiredNum(validators[height].length);
        address _lastSigner = address(0);
        for (uint i = 0; i < signatures.length; i++) {
            for (uint k = 0; k < signers.length; k++) {
                require(isValidator(height, signers[k]), "Validator: signer is not validator");
                if (_isValidSignature(hash, signatures[i], signers[k])) {
                    _actualSignature++;
                    require(signers[k] > _lastSigner, "Validator: duplicate signature or signers is out of order");
                    _lastSigner = signers[k];
                    break;
                }
            }
        }
        return (_actualSignature >= _requiredSignature);
    }

    function _calculateBFTRequiredNum(uint total) internal pure returns (uint) {
        if (total == 0) return 0;
        return (total - (total - 1) / 3);
    }

    function _isValidSignature(bytes32 hash, bytes memory signature, address signer) internal pure returns (bool) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedProof = keccak256(abi.encodePacked(prefix, hash));
        return (prefixedProof.recover(signature) == signer || hash.recover(signature) == signer);
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

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

library EC {
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
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Check the signature length
        if (signature.length != 65) {
            revert("ECDSA: invalid signature length");
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        return _ecrecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover-bytes32-bytes-} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function _ecrecover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        // require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
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