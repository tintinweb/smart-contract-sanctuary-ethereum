/**
 *Submitted for verification at Etherscan.io on 2022-06-06
*/

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.13;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// File: vesting.sol

//SPDX-License-Identifier: UNLICENSED

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

// File: @openzeppelin/contracts/utils/cryptography/ECDSA.sol


// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

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
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
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

// File: @openzeppelin/contracts/utils/cryptography/draft-EIP712.sol


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




pragma solidity ^0.8.0;


contract uniChecker is EIP712 {

    string private constant SIGNING_DOMAIN = "Uniplay";
    string private constant SIGNATURE_VERSION = "1";

     struct Uniplay{
        address userAddress;
        address contractAddress;
        uint256 amount;
        uint256 saleType;
        uint256 timestamp;
        bytes signature;
    }
    constructor() EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION){

    }

    function getSigner(Uniplay memory whitelist) public view returns(address){
        return _verify(whitelist);
    }

    /// @notice Returns a hash of the given whitelist, prepared using EIP712 typed data hashing rules.

function _hash(Uniplay memory whitelist) internal view returns (bytes32) {
        return _hashTypedDataV4(keccak256(abi.encode(
                keccak256("Uniplay(address userAddress,address contractAddress,uint256 amount,uint256 saleType,uint256 timestamp)"),
                whitelist.userAddress,
                whitelist.contractAddress,
                whitelist.amount,
                whitelist.saleType,
                whitelist.timestamp
            )));
    }
    function _verify(Uniplay memory whitelist) internal view returns (address) {
        bytes32 digest = _hash(whitelist);
        return ECDSA.recover(digest, whitelist.signature);
    }

}


contract UniplayVesting is Ownable,ReentrancyGuard,uniChecker {

    IERC20 public token;

    uint256 public startDate;
    uint256 public activeLockDate;
    bool isremoved;
    bool public isStart;
    mapping(address=>bool) public isSameInvestor;
    address public signer;

    mapping(address=>mapping(uint=>bool)) public usedNonce;

    uint[7] public  lockEnd=[0,seedLockEndDate,privateLockEndDate,teamLockEndDate,launchpadLockEndDate,marketdevelopmentLockEndDate,airdropcampaignLockEndDate];
    uint[7] public vestEnd=[0,seedVestingEndDate,privateVestingEndDate,teamVestingEndDate,launchpadVestingEndDate,marketdevelopmentVestingEndDate,airdropcampaignVestingEndDate];
    uint256 day = 1 days;

    modifier setStart{
        require(isStart==true,"wait for start");
        _;
    }

    event TokenWithdraw(address indexed buyer, uint value);
    event InvestersAddress(address accoutt, uint _amout,uint saletype);

    mapping(address => InvestorDetails) public Investors;

  

    uint256 public seedStartDate;
    uint256 public privateStartDate;
    uint256 public teamStartDate;
    uint256 public launchpadStartDate;
    uint256 public marketdevelopmentStartDate;
    uint256 public airdropcampaignStartDate;

    uint256 public seedLockEndDate;
    uint256 public privateLockEndDate;
    uint256 public teamLockEndDate;
    uint256 public launchpadLockEndDate;
    uint256 public marketdevelopmentLockEndDate;
    uint256 public airdropcampaignLockEndDate;

    uint256 public seedVestingEndDate;
    uint256 public privateVestingEndDate;
    uint256 public teamVestingEndDate;
    uint256 public launchpadVestingEndDate;
    uint256 public marketdevelopmentVestingEndDate;
    uint256 public airdropcampaignVestingEndDate;
   
    receive() external payable {
    }
    
    /* Withdraw the contract's ETH balance to owner wallet*/
    function extractETH() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function getInvestorDetails(address _addr) public view returns(InvestorDetails memory){
        return Investors[_addr];
    }

    
    function getContractTokenBalance() public view returns(uint256) {
        return token.balanceOf(address(this));
    }
    
    
    /* 
        Transfer the remining token to different wallet. 
        Once the ICO is completed and if there is any remining tokens it can be transfered other wallets.
    */
    function transferToken(address ERC20Address, uint256 value) public onlyOwner {
        require(value <= IERC20(ERC20Address).balanceOf(address(this)), 'Insufficient balance to withdraw');
        IERC20(ERC20Address).transfer(msg.sender, value);
    }

    /* Utility function for testing. The token address used in this ICO contract can be changed. */
    function setTokenAddress(address _addr) public onlyOwner {
        token = IERC20(_addr);
    }


    struct Investor {
        address account;
        uint256 amount;
        uint256 saleType;
    }

    struct InvestorDetails {
        uint256 totalBalance;
        uint256 timeDifference;
        uint256 lastVestedTime;
        uint256 reminingUnitsToVest;
        uint256 tokensPerUnit;
        uint256 vestingBalance;
        uint256 investorType;
        uint256 initialAmount;
        bool isInitialAmountClaimed;
    }
//reminingUnitsToVest = [0,365,300,1095,240,730,180]
uint[] public saleTypeUnitsToVest = [0,365,300,1095,240,730,180];
uint[] public saleTypeMultiplier = [0,5,8,0,10,0,0];
uint[] public saleTypeTimeframe = [0,365,300,1095,240,730,180];



    function adminAddInvestors(Investor[] memory investorArray) public onlyOwner{
        for(uint16 i = 0; i < investorArray.length; i++) {

         if(isremoved){
                 isSameInvestor[investorArray[i].account]=true;
                 isremoved=false;
            }
         else{
                require(!isSameInvestor[investorArray[i].account],"Investor Exist");
                isSameInvestor[investorArray[i].account]=true;
            }
             uint256 saleType = investorArray[i].saleType;
            InvestorDetails memory investor;
            investor.totalBalance = (investorArray[i].amount) * (10 ** 18);
            investor.investorType = investorArray[i].saleType;
            investor.vestingBalance = investor.totalBalance;

            investor.reminingUnitsToVest = saleTypeUnitsToVest[saleType];
            investor.initialAmount = (investor.totalBalance * saleTypeMultiplier[saleType]) / 100;
            investor.tokensPerUnit = ((investor.totalBalance)- (investor.initialAmount))/saleTypeTimeframe[saleType];

            Investors[investorArray[i].account] = investor; 
            emit InvestersAddress(investorArray[i].account,investorArray[i].amount, investorArray[i].saleType);
        }
    }
    function addInvestors(Uniplay memory uniplay) external{
            require(getSigner(uniplay)==signer,"!signer");
            require(uniplay.userAddress==msg.sender,"!User");
            require(!usedNonce[msg.sender][uniplay.timestamp],"Nonce Used");
            usedNonce[msg.sender][uniplay.timestamp]=true;
         if(isremoved){
                 isSameInvestor[uniplay.userAddress]=true;
                 isremoved=false;
            }
         else{
                require(!isSameInvestor[uniplay.userAddress],"Investor Exist");
                isSameInvestor[uniplay.userAddress]=true;
            }
             uint256 saleType = uniplay.saleType;
            InvestorDetails memory investor;
            investor.totalBalance = (uniplay.amount) * (10 ** 18);
            investor.investorType = uniplay.saleType;
            investor.vestingBalance = investor.totalBalance;

            investor.reminingUnitsToVest = saleTypeUnitsToVest[saleType];
            investor.initialAmount = (investor.totalBalance * saleTypeMultiplier[saleType]) / 100;
            investor.tokensPerUnit = ((investor.totalBalance)- (investor.initialAmount))/saleTypeTimeframe[saleType];

            Investors[uniplay.userAddress] = investor; 
            emit InvestersAddress(uniplay.userAddress,uniplay.amount,uniplay.saleType);
    }


    
    function withdrawTokens() public   nonReentrant setStart {
        require(block.timestamp >=seedStartDate,"wait for start date");
        require(Investors[msg.sender].investorType >0,"Investor Not Found");
        vestEnd=[0,seedVestingEndDate,privateVestingEndDate,teamVestingEndDate,launchpadVestingEndDate,marketdevelopmentVestingEndDate,airdropcampaignVestingEndDate];
        lockEnd=[0,seedLockEndDate,privateLockEndDate,teamLockEndDate,launchpadLockEndDate,marketdevelopmentLockEndDate,airdropcampaignLockEndDate];           
        if(Investors[msg.sender].isInitialAmountClaimed || Investors[msg.sender].investorType == 3 || Investors[msg.sender].investorType == 5 || Investors[msg.sender].investorType == 6) {
            require(block.timestamp>=lockEnd[Investors[msg.sender].investorType],"wait until lock period complete");
            activeLockDate = lockEnd[Investors[msg.sender].investorType] ;
            /* Time difference to calculate the interval between now and last vested time. */
            uint256 timeDifference;
            if(Investors[msg.sender].lastVestedTime == 0) {
                require(activeLockDate > 0, "Active lockdate was zero");
                timeDifference = (block.timestamp) - (activeLockDate);
            } else {
                timeDifference = (block.timestamp) -(Investors[msg.sender].lastVestedTime);
            }
            
            /* Number of units that can be vested between the time interval */
            uint256 numberOfUnitsCanBeVested = (timeDifference)/(day);
            
            /* Remining units to vest should be greater than 0 */
            require(Investors[msg.sender].reminingUnitsToVest > 0, "All units vested!");
            
            /* Number of units can be vested should be more than 0 */
            require(numberOfUnitsCanBeVested > 0, "Please wait till next vesting period!");

            if(numberOfUnitsCanBeVested >= Investors[msg.sender].reminingUnitsToVest) {
                numberOfUnitsCanBeVested = Investors[msg.sender].reminingUnitsToVest;
            }
            
            /*
                1. Calculate number of tokens to transfer
                2. Update the investor details
                3. Transfer the tokens to the wallet
            */
            uint256 tokenToTransfer = numberOfUnitsCanBeVested * Investors[msg.sender].tokensPerUnit;
            uint256 reminingUnits = Investors[msg.sender].reminingUnitsToVest;
            uint256 balance = Investors[msg.sender].vestingBalance;
            Investors[msg.sender].reminingUnitsToVest -= numberOfUnitsCanBeVested;
            Investors[msg.sender].vestingBalance -= numberOfUnitsCanBeVested * Investors[msg.sender].tokensPerUnit;
            Investors[msg.sender].lastVestedTime = block.timestamp;
            if(numberOfUnitsCanBeVested == reminingUnits) { 
                token.transfer(msg.sender, balance);
                emit TokenWithdraw(msg.sender, balance);
            } else {
                token.transfer(msg.sender, tokenToTransfer);
                emit TokenWithdraw(msg.sender, tokenToTransfer);
            }  
        }
        else {
            require(!Investors[msg.sender].isInitialAmountClaimed, "Amount already withdrawn!");
            require(block.timestamp >seedStartDate,"wait for start date");
            Investors[msg.sender].vestingBalance -= Investors[msg.sender].initialAmount;
            Investors[msg.sender].isInitialAmountClaimed = true;
            uint256 amount = Investors[msg.sender].initialAmount;
            Investors[msg.sender].initialAmount = 0;
            token.transfer(msg.sender, amount);
            emit TokenWithdraw(msg.sender, amount);
            
        }
    }

    function setSigner(address _addr) external onlyOwner{
        signer=_addr;
    }
    function setDates(uint256 StartDate,bool _isStart) public onlyOwner{
        seedStartDate = StartDate;
        privateStartDate = StartDate;
        teamStartDate = StartDate;
        launchpadStartDate = StartDate;
        marketdevelopmentStartDate = StartDate;
        airdropcampaignStartDate = StartDate;
        isStart=_isStart;


        seedLockEndDate = seedStartDate + 30 days;
        privateLockEndDate = privateStartDate + 30 days;
        teamLockEndDate = teamStartDate + 180 days;
        launchpadLockEndDate = launchpadStartDate + 30 days;
        marketdevelopmentLockEndDate = marketdevelopmentStartDate + 90 days;
        airdropcampaignLockEndDate = airdropcampaignStartDate + 30 days;

        seedVestingEndDate = seedLockEndDate + 365 days;
        privateVestingEndDate = privateLockEndDate + 300 days;
        teamVestingEndDate = teamLockEndDate + 1095 days;
        launchpadVestingEndDate = launchpadLockEndDate + 240 days ;
        marketdevelopmentVestingEndDate = marketdevelopmentLockEndDate + 730 days ;
        airdropcampaignVestingEndDate = airdropcampaignLockEndDate + 180 days;
    }

    function setDay(uint256 _value) public onlyOwner {
        day = _value;
    }
  

  function removeSingleInvestor(address  _addr) public onlyOwner{
        isremoved=true;
        require(!isStart,"Vesting Started , Unable to Remove Investor");
        require(Investors[_addr].investorType >0,"Investor Not Found");
            delete Investors[_addr];
  }
  
    function removeMultipleInvestors(address[] memory _addr) external onlyOwner{
        for(uint i=0;i<_addr.length;i++){
            removeSingleInvestor(_addr[i]);
        }
    }

     function getAvailableBalance(address _addr) external view returns(uint256, uint256, uint256){
     uint VestEnd=vestEnd[Investors[_addr].investorType];
     uint lockDate=lockEnd[Investors[_addr].investorType];
           if(Investors[_addr].isInitialAmountClaimed || Investors[_addr].investorType == 3 || Investors[_addr].investorType == 5 || Investors[_addr].investorType == 6 ){
            uint hello= day;
            uint timeDifference;
            // uint lockDateteam = teamLockEndDate;
                   if(Investors[_addr].lastVestedTime == 0) {

                           if(block.timestamp>=VestEnd)return(Investors[_addr].reminingUnitsToVest*Investors[_addr].tokensPerUnit,0,0);
                           if(block.timestamp<lockDate) return(0,0,0);
                           if(lockDate + day> 0)return (((block.timestamp-lockDate)/day) *Investors[_addr].tokensPerUnit,0,0);//, "Active lockdate was zero");
                                timeDifference = (block.timestamp) -(lockDate);}
            else{ 
                 timeDifference = (block.timestamp) - (Investors[_addr].lastVestedTime);
               }

            
            uint numberOfUnitsCanBeVested;
            uint tokenToTransfer ;
            numberOfUnitsCanBeVested = (timeDifference)/(hello);
            if(numberOfUnitsCanBeVested >= Investors[_addr].reminingUnitsToVest) {
                numberOfUnitsCanBeVested = Investors[_addr].reminingUnitsToVest;}
            tokenToTransfer = numberOfUnitsCanBeVested * Investors[_addr].tokensPerUnit;
            uint reminingUnits = Investors[_addr].reminingUnitsToVest;
            uint balance = Investors[_addr].vestingBalance;
                    if(numberOfUnitsCanBeVested == reminingUnits) return(balance,0,0) ;  
                    else return(tokenToTransfer,reminingUnits,balance);
                     }
        else {
                   if(!isStart)return(0,0,0);
                   if(block.timestamp<seedStartDate)return(0,0,0);
                    Investors[_addr].initialAmount == 0 ;
            return (Investors[_addr].initialAmount,0,0);}
        
         
    }

}