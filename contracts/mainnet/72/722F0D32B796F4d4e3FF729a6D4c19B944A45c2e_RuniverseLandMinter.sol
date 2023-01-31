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
     * by making the `nonReentrant` function external, and make it call a
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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
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

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ECDSA.sol";

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
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (block.chainid == _CACHED_CHAIN_ID) {
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

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRuniverseLand {
    enum PlotSize {
        _8,
        _16,
        _32,
        _64,
        _128,
        _256,
        _512,
        _1024,
        _2048,
        _4096
    }

    event LandMinted(address to, uint256 tokenId, IRuniverseLand.PlotSize size);

    function mintTokenId(
        address recipient,
        uint256 tokenId,
        PlotSize size
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IRuniverseLand.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract RuniverseLandMinter is Ownable, ReentrancyGuard {
    using Address for address payable;

    /// @notice Address to the ERC721 RuniverseLand contract
    IRuniverseLand public runiverseLand;

    /// @notice Address to the vault where we can withdraw
    address payable public vault;

    uint256[] plotsAvailablePerSize = [
        52500, // 8x8
        16828, // 16x16
        560, // 32x32
        105, // 64x64
        7 // 128x128
    ];

    uint256[] public plotSizeLocalOffset = [
        1, // 8x8
        1, // 16x16
        1, // 32x32
        1, // 64x64
        1 // 128x128
    ];    

    uint256 public plotGlobalOffset = 1;

    uint256[] public plotPrices = [
        type(uint256).max,
        type(uint256).max,
        type(uint256).max,
        type(uint256).max,
        type(uint256).max
    ];

    uint256 public publicMintStartTime = type(uint256).max;
    uint256 public mintlistStartTime = type(uint256).max;
    uint256 public claimsStartTime = type(uint256).max;

    /// @notice The primary merkle root
    bytes32 public mintlistMerkleRoot1;

    /// @notice The secondary Merkle root
    bytes32 public mintlistMerkleRoot2;

    /// @notice The claimslist Merkle root
    bytes32 public claimlistMerkleRoot;

    /// @notice stores the number actually minted per plot size
    mapping(uint256 => uint256) public plotsMinted;

    /// @notice stores the number minted by this address in the mintlist by size
    mapping(address => mapping(uint256 => uint256))
        public mintlistMintedPerSize;

    /// @notice stores the number minted by this address in the claimslist by size
    mapping(address => mapping(uint256 => uint256))
        public claimlistMintedPerSize;

    /**
     * @dev Create the contract and set the initial baseURI
     * @param _runiverseLand address the initial base URI for the token metadata URL
     */
    constructor(IRuniverseLand _runiverseLand) {
        setRuniverseLand(_runiverseLand);
        setVaultAddress(payable(msg.sender));
    }

    /**
     * @dev returns true if the whitelisted mintlist started.
     * @return mintlistStarted true if mintlist started.
     */
    function mintlistStarted() public view returns (bool) {
        return block.timestamp >= mintlistStartTime;
    }

    /**
     * @dev returns true if the whitelisted claimlist started.
     * @return mintlistStarted true if claimlist started.
     */
    function claimsStarted() public view returns (bool) {
        return block.timestamp >= claimsStartTime;
    }

    /**
     * @dev returns true if the public minting started.
     * @return mintlistStarted true if public minting started.
     */
    function publicStarted() public view returns (bool) {
        return block.timestamp >= publicMintStartTime;
    }

    /**
     * @dev returns how many plots were avialable since the begining.
     * @return getPlotsAvailablePerSize array uint256 of 5 elements.
     */
    function getPlotsAvailablePerSize() external view returns (uint256[] memory) {
        return plotsAvailablePerSize;
    }

    /**
     * @dev returns the eth cost of each plot.
     * @return getPlotPrices array uint256 of 5 elements.
     */
    function getPlotPrices() external view returns (uint256[] memory) {
        return plotPrices;
    }

    /**
     * @dev returns the plot type of a token id.
     * @param tokenId uint256 token id.
     * @return getPlotPrices uint256 plot type.
     */
    function getTokenIdPlotType(uint256 tokenId) external pure returns (uint256) {
        return tokenId&255;
    }

    /**
     * @dev return the total number of minted plots
     * @return getTotalMintedLands uint256 number of minted plots.
     */
    function getTotalMintedLands() external view returns (uint256) {
        uint256 totalMintedLands;
        totalMintedLands =  plotsMinted[0] +
                            plotsMinted[1] +
                            plotsMinted[2] +                             
                            plotsMinted[3] +
                            plotsMinted[4];
        return totalMintedLands;                                                        
    }
    
    /**
     * @dev return the total number of minted plots of each size.
     * @return getTotalMintedLandsBySize array uint256 number of minted plots of each size.
     */

    function getTotalMintedLandsBySize() external view returns (uint256[] memory) {
        uint256[] memory plotsMintedBySize = new uint256[](5);

        plotsMintedBySize[0] = plotsMinted[0];
        plotsMintedBySize[1] = plotsMinted[1];
        plotsMintedBySize[2] = plotsMinted[2];
        plotsMintedBySize[3] = plotsMinted[3];
        plotsMintedBySize[4] = plotsMinted[4];

        return plotsMintedBySize;
    }

    /**
     * @dev returns the number of plots left of each size.
     * @return getAvailableLands array uint256 of 5 elements.
     */
    function getAvailableLands() external view returns (uint256[] memory) {
        uint256[] memory plotsAvailableBySize = new uint256[](5);

        plotsAvailableBySize[0] = plotsAvailablePerSize[0] - plotsMinted[0];
        plotsAvailableBySize[1] = plotsAvailablePerSize[1] - plotsMinted[1];
        plotsAvailableBySize[2] = plotsAvailablePerSize[2] - plotsMinted[2];
        plotsAvailableBySize[3] = plotsAvailablePerSize[3] - plotsMinted[3];
        plotsAvailableBySize[4] = plotsAvailablePerSize[4] - plotsMinted[4];

        return plotsAvailableBySize;
    }    

    /**
     * @dev mint public method to mint when the whitelist (mintlist) is active.
     * @param _who address address that is minting. 
     * @param _leaf bytes32 merkle leaf.
     * @param _merkleProof bytes32[] merkle proof.
     * @return mintlisted bool success mint.
     */
    function mintlisted(
        address _who,
        bytes32 _leaf,
        bytes32[] calldata _merkleProof
    ) external view returns (bool) {
        bytes32 node = keccak256(abi.encodePacked(_who));
        
        if (node != _leaf) return false;
        if (
            MerkleProof.verify(_merkleProof, mintlistMerkleRoot1, _leaf) ||
            MerkleProof.verify(_merkleProof, mintlistMerkleRoot2, _leaf)
        ) {
            return true;
        }
        return false;
    }

    /**
     * @dev public method  for public minting.
     * @param plotSize PlotSize enum with plot size.
     * @param numPlots uint256 number of plots to be minted.     
     */
    function mint(IRuniverseLand.PlotSize plotSize, uint256 numPlots)
        external
        payable
        nonReentrant
    {
        if(!publicStarted()){
            revert WrongDateForProcess({
                correct_date: publicMintStartTime,
                current_date: block.timestamp
            });
        }
        if(numPlots <= 0 && numPlots > 20){
            revert IncorrectPurchaseLimit();
        }
        _mintTokensCheckingValue(plotSize, numPlots, msg.sender);
    }

    /**
     * @dev public method to mint when the whitelist (mintlist) is active.
     * @param plotSize PlotSize enum with plot size.
     * @param numPlots uint256 number of plots to be minted. 
     * @param claimedMaxPlots uint256 maximum number of plots of plotSize size  that the address mint.
     * @param _merkleProof bytes32[] merkle proof.
     */
    function mintlistMint(
        IRuniverseLand.PlotSize plotSize,
        uint256 numPlots,
        uint256 claimedMaxPlots,
        bytes32[] calldata _merkleProof
    ) external payable nonReentrant {
        if(!mintlistStarted()){
            revert WrongDateForProcess({
                correct_date:mintlistStartTime,
                current_date: block.timestamp
            });
        }
        if(numPlots <= 0 && numPlots > 20){
            revert IncorrectPurchaseLimit();
        }
        // verify allowlist        
        bytes32 _leaf = keccak256(
            abi.encodePacked(
                msg.sender,
                ":",
                uint256(plotSize),
                ":",
                claimedMaxPlots
            )
        );

        require(
            MerkleProof.verify(_merkleProof, mintlistMerkleRoot1, _leaf) ||
                MerkleProof.verify(_merkleProof, mintlistMerkleRoot2, _leaf),
            "Invalid proof."
        );

        mapping(uint256 => uint256) storage mintedPerSize = mintlistMintedPerSize[msg.sender];

        require(
            mintedPerSize[uint256(plotSize)] + numPlots <=
                claimedMaxPlots, // this is verified by the merkle proof
            "Minting more than allowed"
        );
        mintedPerSize[uint256(plotSize)] += numPlots;
        _mintTokensCheckingValue(plotSize, numPlots, msg.sender);
    }

    /**
     * @dev public method to claim a plot, only when (claimlist) is active.
     * @param plotSize PlotSize enum with plot size.
     * @param numPlots uint256 number of plots to be minted. 
     * @param claimedMaxPlots uint256 maximum number of plots of plotSize size  that the address mint.
     * @param _merkleProof bytes32[] merkle proof.
     */
    function claimlistMint(
        IRuniverseLand.PlotSize plotSize,
        uint256 numPlots,
        uint256 claimedMaxPlots,
        bytes32[] calldata _merkleProof
    ) external payable nonReentrant {
        if(!claimsStarted()){
            revert WrongDateForProcess({
                correct_date:claimsStartTime,
                current_date: block.timestamp
            });
        }

        // verify allowlist                
        bytes32 _leaf = keccak256(
            abi.encodePacked(
                msg.sender,
                ":",
                uint256(plotSize),
                ":",
                claimedMaxPlots
            )
        );

        require(
            MerkleProof.verify(_merkleProof, claimlistMerkleRoot, _leaf),
            "Invalid proof."
        );

        mapping(uint256 => uint256) storage mintedPerSize = claimlistMintedPerSize[msg.sender];

        require(
            mintedPerSize[uint256(plotSize)] + numPlots <=
                claimedMaxPlots, // this is verified by the merkle proof
            "Claiming more than allowed"
        );
        mintedPerSize[uint256(plotSize)] += numPlots;
        _mintTokens(plotSize, numPlots, msg.sender);
    }

    /**
     * @dev checks if the amount sent is correct. Continue minting if it is correct.
     * @param plotSize PlotSize enum with plot size.
     * @param numPlots uint256 number of plots to be minted. 
     * @param recipient address  address that sent the mint.          
     */
    function _mintTokensCheckingValue(
        IRuniverseLand.PlotSize plotSize,
        uint256 numPlots,
        address recipient
    ) private {
        if(plotPrices[uint256(plotSize)] <= 0){
            revert MisconfiguredPrices();
        }
        require(
            msg.value == plotPrices[uint256(plotSize)] * numPlots,
            "Ether value sent is not accurate"
        );        
        _mintTokens(plotSize, numPlots, recipient);
    }


    /**
     * @dev checks if there are plots available. Final step before sending it to RuniverseLand contract.
     * @param plotSize PlotSize enum with plot size.
     * @param numPlots uint256 number of plots to be minted. 
     * @param recipient address  address that sent the mint.          
     */
    function _mintTokens(
        IRuniverseLand.PlotSize plotSize,
        uint256 numPlots,
        address recipient
    ) private {       
        require(
            plotsMinted[uint256(plotSize)] + numPlots <=
                plotsAvailablePerSize[uint256(plotSize)],
            "Trying to mint too many plots"
        );
        
        for (uint256 i; i < numPlots; ++i) {

            uint256 tokenId = ownerGetNextTokenId(plotSize);            
            ++plotsMinted[uint256(plotSize)];
               
            runiverseLand.mintTokenId(recipient, tokenId, plotSize);
        }        
    }

    /**
     * @dev Method to mint many plot and assign it to an addresses without any requirement. Used for private minting.
     * @param plotSizes PlotSize[] enums with plot sizes.
     * @param recipients address[]  addresses where the token will be transferred.          
     */
    function ownerMint(
        IRuniverseLand.PlotSize[] calldata plotSizes,
        address[] calldata recipients
    ) external onlyOwner {
        require(
            plotSizes.length == recipients.length,
            "Arrays should have the same size"
        );
        for (uint256 i; i < recipients.length; ++i) {
            _mintTokens(plotSizes[i], 1, recipients[i]);
        }
    }

    /**
     * @dev Encodes the next token id.
     * @param plotSize PlotSize enum with plot size.
     * @return ownerGetNextTokenId uint256 encoded next toknId.
     */
    function ownerGetNextTokenId(IRuniverseLand.PlotSize plotSize) private view returns (uint256) {
        uint256 globalCounter = plotsMinted[0] + plotsMinted[1] + plotsMinted[2] + plotsMinted[3] + plotsMinted[4] + plotGlobalOffset;
        uint256 localCounter  = plotsMinted[uint256(plotSize)] + plotSizeLocalOffset[uint256(plotSize)];
        require( localCounter <= 4294967295, "Local index overflow" );
        require( uint256(plotSize) <= 255, "Plot index overflow" );
        
        return (globalCounter<<40) + (localCounter<<8) + uint256(plotSize);
    }

    /**
     * Owner Controls
     */
    /**
     * @dev Assigns a new public start minting time.
     * @param _newPublicMintStartTime uint256 echo time in seconds.     
     */
    function setPublicMintStartTime(uint256 _newPublicMintStartTime)
        external
        onlyOwner
    {
        publicMintStartTime = _newPublicMintStartTime;
    }

    /**
     * @dev Assigns a new mintlist start minting time.
     * @param _newAllowlistMintStartTime uint256 echo time in seconds.     
     */
    function setMintlistStartTime(uint256 _newAllowlistMintStartTime)
        external
        onlyOwner
    {
        mintlistStartTime = _newAllowlistMintStartTime;
    }

    /**
     * @dev Assigns a new claimlist start minting time.
     * @param _newClaimsStartTime uint256 echo time in seconds.     
     */
    function setClaimsStartTime(uint256 _newClaimsStartTime) external onlyOwner {
        claimsStartTime = _newClaimsStartTime;
    }

    /**
     * @dev Assigns a merkle root to the main tree for mintlist.
     * @param newMerkleRoot bytes32 merkle root
     */
    function setMintlistMerkleRoot1(bytes32 newMerkleRoot) external onlyOwner {
        mintlistMerkleRoot1 = newMerkleRoot;
    }

    /**
     * @dev Assigns a merkle root to the second tree for mintlist. Used for double buffer.
     * @param newMerkleRoot bytes32 merkle root
     */
    function setMintlistMerkleRoot2(bytes32 newMerkleRoot) external onlyOwner {
        mintlistMerkleRoot2 = newMerkleRoot;
    }

    /**
     * @dev Assigns a merkle root to the main tree for claimlist.
     * @param newMerkleRoot bytes32 merkle root
     */
    function setClaimlistMerkleRoot(bytes32 newMerkleRoot) external onlyOwner {
        claimlistMerkleRoot = newMerkleRoot;
    }

    /**
     * @dev Assigns the main contract.
     * @param _newRuniverseLandAddress IRuniverseLand Main contract.
     */
    function setRuniverseLand(IRuniverseLand _newRuniverseLandAddress)
        public
        onlyOwner
    {
        runiverseLand = _newRuniverseLandAddress;
    }

    /**
     * @dev Assigns the vault address.
     * @param _newVaultAddress address vault address.
     */
    function setVaultAddress(address payable _newVaultAddress)
        public
        onlyOwner
    {
        vault = _newVaultAddress;
    }

    /**
     * @dev Assigns the offset to the global ids. This value will be added to the global id when a token is generated.
     * @param _newGlobalIdOffset uint256 offset
     */
    function setGlobalIdOffset(uint256 _newGlobalIdOffset) external onlyOwner {
        if(mintlistStarted()){
            revert DeniedProcessDuringMinting();
        }
        plotGlobalOffset = _newGlobalIdOffset;
    }

    /**
     * @dev Assigns the offset to the local ids. This value will be added to the local id of each plot size  when a token of some size is generated.
     * @param _newPlotSizeLocalOffset uint256[] offsets
     */
    function setLocalIdOffsets(uint256[] calldata _newPlotSizeLocalOffset) external onlyOwner {
        if(_newPlotSizeLocalOffset.length != 5){
            revert GivedValuesNotValid({
                sended_values: _newPlotSizeLocalOffset.length,
                expected: 5
            });
        }
        if(mintlistStarted()){
            revert DeniedProcessDuringMinting();
        }
        plotSizeLocalOffset = _newPlotSizeLocalOffset;
    }

    /**
     * @dev Assigns the new plot prices for each plot size.
     * @param _newPrices uint256[] plots prices.
     */
    function setPrices(uint256[] calldata _newPrices) external onlyOwner {
        if(mintlistStarted()){
            revert DeniedProcessDuringMinting();
        }
        if(_newPrices.length < 5){
            revert GivedValuesNotValid({
                sended_values: _newPrices.length,
                expected: 5
            });
        }
        plotPrices = _newPrices;
    }

    /**
     * @notice Withdraw funds to the vault using sendValue
     * @param _amount uint256 the amount to withdraw
     */
    function withdraw(uint256 _amount) external onlyOwner {
        (bool success, ) = vault.call{value: _amount}("");
         require(success, "withdraw was not succesfull");
    }

    /**
     * @notice Withdraw all the funds to the vault using sendValue     
     */
    function withdrawAll() external onlyOwner {
        (bool success, ) = vault.call{value: address(this).balance}("");
         require(success, "withdraw all was not succesfull");
    }

    /**
     * @notice Transfer amount to a token.
     * @param _token IERC20 token to transfer
     * @param _amount uint256 amount to transfer
     */
    function forwardERC20s(IERC20 _token, uint256 _amount) external onlyOwner {
        if(address(msg.sender) == address(0)){
            revert Address0Error();
        }
        _token.transfer(msg.sender, _amount);
    }

    /// Wrong date for process, Come back on `correct_data` for complete this successfully
    /// @param correct_date date when the public/ mint is on.
    /// @param current_date date when the process was executed.
    error WrongDateForProcess(uint256 correct_date, uint256 current_date);

    /// Denied Process During Minting
    error DeniedProcessDuringMinting();

    /// Incorrect Purchase Limit, the limits are from 1 to 20 plots
    error IncorrectPurchaseLimit();

    /// MisconfiguredPrices, the price of that land-size is not configured yet
    error MisconfiguredPrices();

    /// Configured Prices Error, please send exactly 5 values
    /// @param sended_values Total gived values.
    /// @param expected Total needed values.
    error GivedValuesNotValid(uint256 sended_values, uint256 expected);

    error Address0Error();
}