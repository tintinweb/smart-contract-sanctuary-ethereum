/**
 *Submitted for verification at Etherscan.io on 2022-06-23
*/

// Sources flattened with hardhat v2.6.0 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/access/[email protected]

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/token/ERC20/[email protected]

// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/utils/cryptography/[email protected]

// OpenZeppelin Contracts v4.4.1 (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
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
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
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
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

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
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
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
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
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


// File @openzeppelin/contracts/utils/cryptography/[email protected]

// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    address private immutable _CACHED_THIS;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _CACHED_THIS = address(this);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}


// File contracts/Seedster.sol

//Author: Christian B. Martinez
pragma solidity >=0.8.0 <0.9.0;




contract Seedster is EIP712, Ownable {
    bool internal locked;
    address public developer;
    address public globalSigner; //shared signer for those funder that do not choose to use their own signer
    address private withdrawAddress;
    struct Recipient {
        uint256 roundsClaimed; // incremental based on the amounts the client has claimed
    }
    struct Funder {
        uint256 funded; //amount initially funded. able to add more funds to this using the update function
        uint256 dist; //amount distributted. incremental increased based on the claims and the amount claimed
        bool launched; //when launched, token is true. it can be paused in which case there can be no claims against funder's assets
        address signer; //if user chooses to bring their own signer
    }
    //asset, funder details
    mapping(address => mapping(address => Funder)) funderAseetDetails;
    //asset, funder, recipient details
    mapping(address => mapping(address => mapping(address => Recipient))) recipientFunderAssetDetails;
    //strict hash message function that must be followed in order for signatures to be verified
    bytes32 public constant TXN_CALL_HASH_TYPE =
        keccak256(
            "Claim(address receiver,uint256 amount,uint256 maxRounds,uint256 globalCurrentRound,address assetAddress,address funderAddress,uint256 blocknum)"
        );
    modifier noReentrant() {
        require(!locked);
        locked = true;
        _;
        locked = false;
    }
    modifier OnlyDeveloperOrFunder(address _assetAddress) {
        require(
            funderAseetDetails[_assetAddress][msg.sender].funded > 0 ||
                msg.sender == developer
        );
        _;
    }
    modifier OnlyWealthyFunder(address _assetAddress, uint256 _fundingAmount) {
        require(_assetAddress != address(this));
        require(_assetAddress != address(0));
        require(_fundingAmount <= IERC20(_assetAddress).balanceOf(msg.sender));
        _;
    }
    //event emitted everytime a funder's assets have been claimed
    event AssetClaimed(
        bytes _signature,
        address assetAddress,
        address funderAddress,
        address clientAddress
    );
    //event emitted in the receive function when eth has been sent to this contract
    event EthReceived(uint256 amount, address from);

    //EIP712 passed parameters are strict. used when creating signatures for claims. must follow as is.
    constructor(
        address _owner,
        address _dev,
        string memory _name,
        string memory _version
    ) EIP712(_name, _version) {
        developer = _dev;
        transferOwnership(_owner);
    }

    //claimees can claim their funder's assets as they are allowed. Successful claims require a valid signature
    function claim(
        bytes memory _signature,
        uint256 _totalAmountAllottedToClient,
        uint256 _maxRoundsForClient,
        uint256 _scheduleCurrentRound,
        address _assetAddress,
        address _funderAddress,
        uint256 _blockNumber
    ) public noReentrant {
        uint256 contractBlockNumber = block.number;
        require(funderAseetDetails[_assetAddress][_funderAddress].launched);
        require(
            funderAseetDetails[_assetAddress][_funderAddress].funded > 0 &&
                funderAseetDetails[_assetAddress][_funderAddress].dist <
                funderAseetDetails[_assetAddress][_funderAddress].funded
        );
        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    TXN_CALL_HASH_TYPE,
                    msg.sender,
                    _totalAmountAllottedToClient,
                    _maxRoundsForClient,
                    _scheduleCurrentRound,
                    _assetAddress,
                    _funderAddress,
                    _blockNumber
                )
            )
        );
        address _signer = ECDSA.recover(digest, _signature);
        if (
            funderAseetDetails[_assetAddress][_funderAddress].signer !=
            address(0)
        ) {
            require(
                _signer ==
                    funderAseetDetails[_assetAddress][_funderAddress].signer
            );
        } else {
            require(_signer == globalSigner);
        }
        require(_blockNumber > contractBlockNumber);
        require(
            recipientFunderAssetDetails[_assetAddress][_funderAddress][
                msg.sender
            ].roundsClaimed < _maxRoundsForClient
        );
        require(
            _totalAmountAllottedToClient <=
                funderAseetDetails[_assetAddress][_funderAddress].funded
        );
        require(
            _scheduleCurrentRound >
                recipientFunderAssetDetails[_assetAddress][_funderAddress][
                    msg.sender
                ].roundsClaimed
        );
        uint256 amountToSend = calculateAmountToSend(
            _totalAmountAllottedToClient,
            _maxRoundsForClient,
            _scheduleCurrentRound,
            recipientFunderAssetDetails[_assetAddress][_funderAddress][
                msg.sender
            ].roundsClaimed
        );
        require(amountToSend <= _totalAmountAllottedToClient);
        recipientFunderAssetDetails[_assetAddress][_funderAddress][msg.sender]
            .roundsClaimed = _scheduleCurrentRound;
        require(
            (funderAseetDetails[_assetAddress][_funderAddress]
                .dist += amountToSend) <=
                funderAseetDetails[_assetAddress][_funderAddress].funded
        );
        IERC20(_assetAddress).transfer(msg.sender, amountToSend);
        emit AssetClaimed(
            _signature,
            _assetAddress,
            _funderAddress,
            msg.sender
        );
    }

    //calculate the amount to distribute based on vesting rounds.
    function calculateAmountToSend(
        uint256 fullAmount,
        uint256 maxRounds,
        uint256 currentGlobalRound,
        uint256 _roundsClaimed
    ) internal pure returns (uint256) {
        if ((currentGlobalRound - _roundsClaimed) > maxRounds) {
            return (fullAmount / maxRounds) * (maxRounds - _roundsClaimed);
        } else {
            return
                (fullAmount / maxRounds) *
                (currentGlobalRound - _roundsClaimed);
        }
    }

    //get funder's asset details - launched? how much distributed? how much funded?
    function getFunderAseetDetails(address _assetAddress, address _funder)
        public
        view
        returns (
            address,
            address,
            uint256,
            uint256,
            bool,
            address
        )
    {
        return (
            _assetAddress,
            _funder,
            funderAseetDetails[_assetAddress][_funder].funded,
            funderAseetDetails[_assetAddress][_funder].dist,
            funderAseetDetails[_assetAddress][_funder].launched,
            funderAseetDetails[_assetAddress][_funder].signer
        );
    }

    //only the owner can assign the developer to continiously maintain app.
    function setDeveloper(address _dev) public onlyOwner {
        developer = _dev;
    }

    //only owner can set/reset the globalSigner to ensure signers are vetted at the highest levels.
    function setGlobalSigner(address _signer) public onlyOwner {
        require(_signer != address(this));
        require(_signer != address(0));
        require(_signer != globalSigner);
        globalSigner = _signer;
    }

    //only funder with sufficient assets can launch a schedule for that asset
    function launchSchedule(address _assetAddress, uint256 _fundingAmount)
        public
        noReentrant
        OnlyWealthyFunder(_assetAddress, _fundingAmount)
    {
        require(_fundingAmount > 0);
        require(funderAseetDetails[_assetAddress][msg.sender].funded <= 0);
        funderAseetDetails[_assetAddress][msg.sender].funded = _fundingAmount;
        funderAseetDetails[_assetAddress][msg.sender].dist = 0;
        funderAseetDetails[_assetAddress][msg.sender].launched = true;
        IERC20(_assetAddress).transferFrom(
            msg.sender,
            address(this),
            _fundingAmount
        );
    }

    //only funder with sufficient assets can add more funds to that asset
    function updateSchedule(address _assetAddress, uint256 _fundingAmount)
        public
        noReentrant
        OnlyWealthyFunder(_assetAddress, _fundingAmount)
    {
        require(_fundingAmount > 0);
        require(funderAseetDetails[_assetAddress][msg.sender].funded > 0);
        funderAseetDetails[_assetAddress][msg.sender].funded += _fundingAmount;
        IERC20(_assetAddress).transferFrom(
            msg.sender,
            address(this),
            _fundingAmount
        );
    }

    //only the owner of the token, or the developer, can pause the vesting schedule
    function pauseSchedule(address _assetAddress, address _funderAddress)
        public
        OnlyDeveloperOrFunder(_assetAddress)
    {
        require(funderAseetDetails[_assetAddress][_funderAddress].launched);
        funderAseetDetails[_assetAddress][_funderAddress].launched = false;
    }

    //only the owner of the token, or the developer, can restart the vesting schedule
    function startSchedule(address _assetAddress, address _funderAddress)
        public
        OnlyDeveloperOrFunder(_assetAddress)
    {
        require(!funderAseetDetails[_assetAddress][_funderAddress].launched);
        funderAseetDetails[_assetAddress][_funderAddress].launched = true;
    }

    //only the owner can change the signer. Signer is needed for signature verification purposes
    //used when funder's want to have their own private signer as opposed to the global shared one
    function changeSigner(
        address _assetAddress,
        address _funderAddress,
        address _signer
    ) public onlyOwner {
        require(_signer != globalSigner);
        require(funderAseetDetails[_assetAddress][_funderAddress].funded > 0);
        funderAseetDetails[_assetAddress][_funderAddress].signer = _signer;
    }

    //only the owner can reset the signer back to factory
    //will revert back to the ZeroAddress; funders will have to use the shared global signer
    //used when funder's does not want to have their own private signer anymore
    function resetSigner(address _assetAddress, address _funderAddress)
        public
        onlyOwner
    {
        require(funderAseetDetails[_assetAddress][_funderAddress].funded > 0);
        funderAseetDetails[_assetAddress][_funderAddress].signer = address(0);
    }

    //to receive eth funds
    receive() external payable {
        emit EthReceived(msg.value, msg.sender);
    }

    //only owner can set the withdrawl address
    function setWithdrawalAccount(address _withdraw) public onlyOwner {
        require(_withdraw != withdrawAddress);
        withdrawAddress = _withdraw;
    }

    //to withdraw eth send to this contract
    function withdraw() public onlyOwner {
        require(address(this).balance > 0);
        require(withdrawAddress != address(0));
        payable(withdrawAddress).transfer(address(this).balance);
    }
}