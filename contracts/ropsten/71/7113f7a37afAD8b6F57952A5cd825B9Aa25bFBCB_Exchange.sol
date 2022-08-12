/**
 *Submitted for verification at Etherscan.io on 2022-08-12
*/

/**
 *Submitted for verification at BscScan.com on 2022-04-25
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;
pragma experimental ABIEncoderV2;

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

pragma solidity ^0.8.0;

/**
 * @dev Interface of the BEP1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[BEP-1271].
 *
 * _Available since v4.1._
 */
interface IBEP1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}

pragma solidity ^0.8.0;

/**
 * @dev Signature verification helper: Provide a single mechanism to verify both private-key (EOA) ECDSA signature and
 * BEP1271 contract sigantures. Using this instead of ECDSA.recover in your contract will make them compatible with
 * smart contract wallets such as Argent and Gnosis.
 *
 * Note: unlike ECDSA signatures, contract signature's are revocable, and the outcome of this function can thus change
 * through time. It could return true at block N and false at block N+1 (or the opposite).
 *
 * _Available since v4.1._
 */
library SignatureChecker {
    function isValidSignatureNow(
        address signer,
        bytes32 hash,
        bytes memory signature
    ) internal view returns (bool) {
        (address recovered, ECDSA.RecoverError error) = ECDSA.tryRecover(hash, signature);
        if (error == ECDSA.RecoverError.NoError && recovered == signer) {
            return true;
        }

        (bool success, bytes memory result) = signer.staticcall(
            abi.encodeWithSelector(IBEP1271.isValidSignature.selector, hash, signature)
        );
        return (success && result.length == 32 && abi.decode(result, (bytes4)) == IBEP1271.isValidSignature.selector);
    }
}

interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

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
     * @dev Moves `amountvalidateBuyerFeeSigView
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}

interface IWETH{
    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor ()  {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract OrderBook is Ownable{

    enum AssetType {ERC20, ERC721, ERC1155}
    
    struct Asset {
        address token;
        uint tokenId;
        AssetType assetType;
    }

    struct OrderKey {
        /* who signed the order */
        address payable owner;
        /* what has owner */
        Asset sellAsset;
        /* what wants owner */
        Asset buyAsset;
    }

    struct Order {
        OrderKey key;
        /* how much has owner (in wei, or UINT256_MAX if ERC-721) */
        uint selling;
        /* how much wants owner (in wei, or UINT256_MAX if ERC-721) */
        uint buying;
        /* fee for selling  secoundary sale*/
        uint sellerFee;
        /* random numbers*/
        uint salt;
        /* expiry time for order*/
        uint expiryTime; // 1.0 for no expiry limit. now + days count. 2. for bid auction auction time + bidexpiry
        /* order Type */
        uint orderType; // 1.sell , 2.buy, 3. bid
    }

    /* An ECDSA signature. */
    struct Sig {
        /* v parameter */
        uint8 v;
        /* r parameter */
        bytes32 r;
        /* s parameter */
        bytes32 s;
    }
}

contract OrderState is OrderBook  {

    using ECDSA for bytes32;

    mapping(bytes32 => bool) public completed; // 1.completed

    function getCompleted(OrderBook.Order calldata order) view external returns (bool) {
        return completed[getCompletedKey(order)];
    }

    function setCompleted(OrderBook.Order memory order, bool newCompleted) internal  {
        completed[getCompletedKey(order)] = newCompleted;
    }
    
    function setCompletedBidOrder(OrderBook.Order memory order, bool newCompleted, address buyer, uint256 buyingAmount) internal  {
        completed[getBidOrderCompletedKey(order, buyer, buyingAmount)] = newCompleted;
    }

    function getCompletedKey(OrderBook.Order memory order) public pure returns (bytes32) {
        return prepareOrderHash(order);
    }
    
    function getBidOrderCompletedKey(OrderBook.Order memory order, address buyer, uint256 buyingAmount) public pure returns (bytes32) {
        return prepareBidOrderHash(order, buyer, buyingAmount);
    }
    
    function validateOrderSignature( Order memory order, Sig memory sig ) internal view {
        require(completed[getCompletedKey(order)] != true, "exist signature");
        if (sig.v == 0 && sig.r == bytes32(0x0) && sig.s == bytes32(0x0)) {
            revert("incorrect signature");
        } else {
            require(prepareOrderHash(order).recover(sig.v, sig.r, sig.s) == order.key.owner, "incorrect signature");
        }
    }
    
    function validateOrderSignatureView( Order memory order, Sig memory sig ) public view returns (address _signer, string memory message) {
        require(completed[getCompletedKey(order)] != true, "exist signature");
        if (sig.v == 0 && sig.r == bytes32(0x0) && sig.s == bytes32(0x0)) {
            return ( address(0x00),"incorrect signature");
        } else {
            _signer = prepareOrderHash(order).recover(sig.v, sig.r, sig.s);
            return ( _signer, "success");
        }
    }
    
    function validateBidOrderSignature( Order memory order, Sig memory sig, address bidder, uint256 buyingAmount) internal view {
        require(completed[getBidOrderCompletedKey(order, bidder, buyingAmount)] != true, "exist signature");
        if (sig.v == 0 && sig.r == bytes32(0x0) && sig.s == bytes32(0x0)) {
            revert("incorrect bid signature");
        } else {
            require(prepareBidOrderHash(order, bidder, buyingAmount).recover(sig.v, sig.r, sig.s) == bidder, "incorrect bid1 signature");
        }
    }
    
    function validateBidOrderSignatureView( Order memory order, Sig memory sig, address bidder, uint256 buyingAmount) public view returns (address _bidder, string memory message) {
        require(completed[getCompletedKey(order)] != true, "exist signature");
        if (sig.v == 0 && sig.r == bytes32(0x0) && sig.s == bytes32(0x0)) {
            return ( address(0x00),"incorrect bid signature");
        } else {
            _bidder = prepareBidOrderHash(order, bidder, buyingAmount).recover(sig.v, sig.r, sig.s);
            return ( _bidder, "success");
        }
    }
    
    function prepareOrderHash(OrderBook.Order memory order) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(order.key.owner,abi.encodePacked(order.key.sellAsset.token,order.key.sellAsset.tokenId, order.key.sellAsset.assetType,
                            order.key.buyAsset.token,order.key.buyAsset.tokenId,order.key.buyAsset.assetType),order.selling,order.buying, order.sellerFee, order.salt, order.expiryTime,order.orderType));
    }
    
    function prepareBidOrderHash(OrderBook.Order memory order, address bidder, uint256 buyingAmount) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(bidder,abi.encodePacked(order.key.buyAsset.token,order.key.buyAsset.tokenId,order.key.buyAsset.assetType,
        order.key.sellAsset.token, order.key.sellAsset.tokenId, order.key.sellAsset.assetType), buyingAmount, order.selling, order.sellerFee, order.salt,
        order.expiryTime, order.orderType));
    }
    
    function prepareBuyerFeeMessage(Order memory order) public pure returns (bytes32) {
       return keccak256(abi.encodePacked(abi.encodePacked(order.key.owner,abi.encodePacked(order.key.sellAsset.token,order.key.sellAsset.tokenId,order.key.buyAsset.token,order.key.buyAsset.tokenId),order.selling,order.buying, order.sellerFee,order.salt, order.expiryTime,order.orderType)));
    }
}

contract TransferSafe {
    function erc721safeTransferFrom(IERC721 token, address from, address to, uint256 tokenId) internal  {
        token.safeTransferFrom(from, to, tokenId);
    }

    function erc1155safeTransferFrom(IERC1155 token, address from, address to, uint256 id, uint256 value) internal {
        token.safeTransferFrom(from, to, id, value, "0x");
    }
}

contract Exchange is OrderState, TransferSafe {
    
    using ECDSA for bytes32;

    event Buy(address indexed sellToken, uint256 indexed sellTokenId, uint256 sellValue, address owner,
              address buyToken, uint256 buyTokenId, uint256 buyValue, address buyer);
    event Cancel(address indexed sellToken, uint256 indexed sellTokenId,address owner, address buyToken, uint256 buyTokenId);
    event Beneficiary(address newBeneficiary);
    event BuyerFeeSigner(address newBuyerFeeSigner);
    event BeneficiaryFee(uint newbeneficiaryfee);
   
    event Allow(address token, bool status);

    address payable public beneficiaryAddress;
    address public buyerFeeSigner;
    address public weth;
    
    uint256 public beneficiaryFee; //
    
    uint256 private constant UINT256_MAX = 2 ** 256 - 1;
    
    // auth token for exchange
    mapping(address => bool) public isAllowed;
    
    constructor(address payable beneficiary, address payable buyerfeesigner, address wethAddr, uint beneficiaryfee) {
        beneficiaryAddress = beneficiary;
        buyerFeeSigner = buyerfeesigner;
        beneficiaryFee = beneficiaryfee;
        weth = wethAddr;
    }
    
    function sell(Order calldata order, Sig calldata sig, Sig calldata buyerFeeSig ) payable external {
       require((block.timestamp <= order.expiryTime ), "signature expired" );
       require(order.orderType == 1, "invalid order type");
       require(order.key.owner != msg.sender, "invalid owner");
                                                                                                                                                          
       _executeInternal(order, sig, buyerFeeSig,2);
    }
    
    function buy(Order calldata order, Sig calldata sig, Sig calldata buyerFeeSig ) external {
       require( ( block.timestamp<= order.expiryTime ), "signature expired" );
       require(order.orderType == 2, "invalid order");
       require(order.key.owner != msg.sender, "invalid owner");

       _executeInternal(order, sig, buyerFeeSig, 1);
    }
    
    function _executeInternal(Order calldata order, Sig calldata sig, Sig calldata buyerFeeSig, uint8 _type) internal {
        validateOrderSignature(order, sig);
        validateBuyerFeeSig(order, buyerFeeSig);
        
        if(_type == 1)
            transferBuyFee(order, msg.sender);
        else
            transferSellFee(order, msg.sender);
        
        setCompleted(order,true);
        transferToken(order, msg.sender);
        emitBuy(order, msg.sender);
    }
    
    // seller need create based on minimum bidding price
    // buyer can create signature => with expiry end 
    // auction expiry + some days = expiry to accept tx 
    function bidExchange(Order calldata order, Sig calldata sig,Sig calldata buyerSig, Sig calldata buyerFeeSig, address buyer, uint256 buyingAmount ) payable external {
        require(( block.timestamp <= order.expiryTime ), "signature expired" );
        require(buyingAmount >= order.buying , "buyingAmount invalid"); 
        require(order.orderType == 3, "invalid order");
        require(order.key.owner == msg.sender, "not owner");

        _executeBidExchangeInternal(order, sig, buyerSig, buyerFeeSig, buyer, buyingAmount );
    }
    
    function _executeBidExchangeInternal(Order calldata order, Sig calldata sig,Sig calldata buyerSig, Sig calldata buyerFeeSig, address buyer, uint256 buyingAmount ) internal {
        validateOrderSignature(order, sig);
        validateBidOrderSignature(order, buyerSig, buyer, buyingAmount);
        validateBuyerFeeSig(order, buyerFeeSig);
        
        setCompleted(order,true);
        setCompletedBidOrder(order, true, buyer, buyingAmount);

        transferBidFee(order.key.buyAsset.token,order.key.owner,buyingAmount, buyer);
        transferToken(order, buyer);
        emitBuy(order, buyer);
    }

    function transferToken(Order calldata order, address buyer) internal {
        if(order.key.sellAsset.assetType == AssetType.ERC721 || order.key.buyAsset.assetType == AssetType.ERC721){
            if(order.orderType == 1 || order.orderType == 3) {
                erc721safeTransferFrom(IERC721(order.key.sellAsset.token), order.key.owner, buyer,order.key.sellAsset.tokenId);
            }
            else if(order.orderType == 2){
                erc721safeTransferFrom(IERC721(order.key.buyAsset.token), buyer, order.key.owner,order.key.buyAsset.tokenId);
            }
        }
        else if(order.key.sellAsset.assetType == AssetType.ERC1155 || order.key.buyAsset.assetType == AssetType.ERC1155){
            if(order.orderType == 1 || order.orderType == 3) {
                erc1155safeTransferFrom(IERC1155(order.key.sellAsset.token), order.key.owner, buyer, order.key.sellAsset.tokenId, order.selling);
            }
            else if(order.orderType == 2) {
                erc1155safeTransferFrom(IERC1155(order.key.buyAsset.token), buyer, order.key.owner, order.key.buyAsset.tokenId, order.buying);
            }
        }
        else {
            revert("invalid assest ");
        }
    }

    function transferSellFee(Order calldata order, address buyer) internal {
        if(order.key.buyAsset.token == address(0x00)){
            require(msg.value == order.buying, "msg.value is invalid");
            transferEthFee(order.buying, order.key.owner);
        } else if(order.key.buyAsset.token == weth){
            transferWethFee(order.buying, order.key.owner, buyer);
        } else {
            transferErc20Fee(order.key.buyAsset.token,order.buying, order.key.owner, buyer);
        }
    }
    
    function transferBuyFee(Order calldata order, address buyer) internal {
        if(order.key.sellAsset.token == weth){
            transferWethFee(order.selling, buyer, order.key.owner);
        } else {
            transferErc20Fee(order.key.sellAsset.token,order.selling, buyer, order.key.owner);
        }
    }
    
    function transferBidFee(address assest,address payable seller, uint256 buyingAmount, address buyer) internal {
        if(assest == weth){
            transferWethFee(buyingAmount, seller, buyer);
        } else {
            transferErc20Fee(assest, buyingAmount, seller, buyer);
        }
    }
    
    function transferEthFee(uint256 amount, address payable _seller ) internal{
        (uint256 protocalfee, uint256 remaining) = transferFeeView(amount);
        if(protocalfee > 0){
            (beneficiaryAddress).transfer(protocalfee);
        }
       
        if(remaining > 0){
            _seller.transfer(remaining);
        }
    }

    function transferWethFee(uint256 amount, address  _seller, address buyer ) internal{
        (uint256 protocalfee, uint256 remaining) = transferFeeView(amount);
        if(protocalfee > 0){
            require(IWETH(weth).transferFrom(buyer,beneficiaryAddress,protocalfee),"invalid 1");
        }
        
        if(remaining > 0){
            require(IWETH(weth).transferFrom(buyer,_seller,remaining),"invalid 3");
        }
    }
    
    function transferErc20Fee(address token, uint256 amount, address  _seller, address buyer) internal{
        require(isAllowed[token] , "Not authorized token");

        (uint256 protocalfee, uint256 remaining) = transferFeeView(amount);
        if(protocalfee > 0){
            require(IERC20(token).transferFrom(buyer,beneficiaryAddress,protocalfee),"invalid 1");
        }
        
        if(remaining > 0){
            require(IERC20(token).transferFrom(buyer,_seller,remaining),"invalid 3");
        }
    }
    

    function transferFeeView(uint256 amount ) public view returns(uint256,uint256){
        uint256 protocalFee = (amount*(beneficiaryFee))/(1000);
       
               
        uint256 remaining = amount-(protocalFee);

       return (protocalFee,remaining);
    }
    
    function emitBuy(Order memory order, address buyer) internal {
        emit Buy(order.key.sellAsset.token, order.key.sellAsset.tokenId, order.selling,
            order.key.owner,
            order.key.buyAsset.token, order.key.buyAsset.tokenId, order.buying,
            buyer
        );
    }
    
    function cancel(Order calldata order) external {
        require(order.key.owner == msg.sender, "not an owner");
        setCompleted(order, true);
        emit Cancel(order.key.sellAsset.token, order.key.sellAsset.tokenId, msg.sender, order.key.buyAsset.token, order.key.buyAsset.tokenId);
    }
    
     function validateBuyerFeeSig( Order memory order, Sig memory sig ) internal view {
        require(prepareBuyerFeeMessage(order).recover(sig.v, sig.r, sig.s) == buyerFeeSigner, "incorrect buyer fee signature");
    }
    
    function validateBuyerFeeSigView( Order memory order, Sig memory sig ) public view {
        require(prepareBuyerFeeMessage(order).recover(sig.v, sig.r, sig.s) == buyerFeeSigner, "incorrect buyer fee signature");
    }
    
    function toEthSignedMessageHash(bytes32 hash, Sig memory sig ) public pure returns (address signer) {
         signer = hash.recover(sig.v, sig.r, sig.s);
    }
    
    function setBeneficiary(address payable newBeneficiary) external onlyOwner {
        require(newBeneficiary != address(0x00), "Zero address");
        beneficiaryAddress = newBeneficiary;
        emit Beneficiary(newBeneficiary);
    }

    function setBuyerFeeSigner(address newBuyerFeeSigner) external onlyOwner {
        require(newBuyerFeeSigner != address(0x00), "Zero address");
        buyerFeeSigner = newBuyerFeeSigner;
        emit BuyerFeeSigner(newBuyerFeeSigner);
    }
    
    function setBeneficiaryFee(uint newbeneficiaryfee) external onlyOwner {
        beneficiaryFee = newbeneficiaryfee;
        emit BeneficiaryFee(newbeneficiaryfee);
    }

    
    function setTokenStatus(address token, bool status) external onlyOwner {
        require(token != address(0x00), "Zero address");
        isAllowed[token] = status;
        emit Allow(token, status);
    }

}