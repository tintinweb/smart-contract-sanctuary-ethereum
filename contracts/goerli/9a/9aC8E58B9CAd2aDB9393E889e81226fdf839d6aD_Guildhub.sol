/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./interfaces/IGuildhub.sol";
import "./utils/EmberError.sol";

contract Guildhub is IGuildHub {
    using ECDSA for bytes32;

    /// admin who can add signers
    address private immutable signer;

    /// unique key
    uint256 private lendingId;

    ///  all lend, rent & sublet details stored against lendingId
    mapping(uint256 => IGuildHub.StakeLedger) private stakeLedger;

    /// check address is verified
    mapping(address => bool) private verifiedEOA;

    /// Events

    
    event DirectLended(
        uint256 indexed lendingId,
        address nft,
        uint256 tokenid,
        uint256 lendAmount,
        address borrower,
        address rewardToken,
        uint256 split
    );
    
    event Borrowed(uint256 indexed lendingId);
    event Unlended(uint256 indexed lendingId);
    event ForceClaimed(uint256 indexed lendingId);
    event EOAVerified(
        address indexed msgsender,
        address indexed EOA,
        string encrypted
    );
    

    constructor(address _signer) { 
        _require(_signer != address(0), Errors.ZERO_ADDRESS);
        signer = _signer;
        
    }

    /**
     * @notice Can bulk directLend NFTs for spilt sharing.
     * @dev  Provided borrower addresses will be verified against signatures
     */

    function verifyAndDirectLend(
        DirectLendRequest[] calldata data,
        bytes[] calldata sig,
        string[] calldata key
    ) external {
        _require(data.length != 0, Errors.ZERO_LENGTH);

        for (uint256 i; i < data.length; ) {
            if (!verifiedEOA[data[i].borrower]) {
                verifyEOA(data[i].borrower, sig[i], key[i]);
            }

            unchecked {
                ++i;
            }
        }
        directLend(data);
    }

    

    /**
     * @notice Can bulk Lend NFTs for spilt sharing.
     * @dev  Provided borrower addresses must be verified
     */

    function directLend(DirectLendRequest[] memory data) public {
        DirectLendRequest memory _lendData;
        StakeLedger memory _lend;

        /// loading state variable into memory as memory operations are cheaper than state operations
        uint256 _lendingId = lendingId;

        for (uint256 i; i < data.length; ) {

            /// By indexing the array only once, we don't spend extra gas in the same bounds check.
            _lendData = data[i];

            /// check borrower address is verified
            _require(
                verifiedEOA[_lendData.borrower],
                Errors.NOT_VERIFIED_ADDRESS
            );

            _lend.lenderAddress = msg.sender;
            _lend.tokenId = _lendData.tokenId;
            _lend.nft = _lendData.nft;
            _lend.lendAmount = _lendData.lendAmount;
            _lend.borrower = _lendData.borrower;

            _transferToken(
                _lendData.nft,
                msg.sender,
                address(this),
                _lendData.tokenId,
                _lendData.lendAmount
            );

            ///update state from memory
            stakeLedger[_lendingId] = _lend;

            emit DirectLended(
                _lendingId,
                _lendData.nft,
                _lendData.tokenId,
                _lendData.lendAmount,
                _lendData.borrower,
                _lendData.rewardToken,
                _lendData.split
            );
            _lendingId++;

            /// Skip overflow check as for loop is indexed starting at zero.
            unchecked {
                ++i;
            }
        }
        ///assigining back to state variable
        lendingId = _lendingId;
    }

    
    /**
     * @notice Direct rent when NFT is lend for revenue split
     * @notice only lender's provided address can borrow that NFT;
     * @dev execute _executeBorrow when NFT is not borrowed
     * @dev execute _executeSubletBorrow when NFT sublended by 1st borrower
     * Emits {borrowed} event.
     */

    function borrow(uint256[] calldata _lendingId) external {
        /// These variable could be declared inside the loop, but that causes the compiler to allocate memory on each
        /// loop iteration, increasing gas costs.
        uint256 _id;
        StakeLedger memory _borrow;
        
        for (uint256 i; i < _lendingId.length; ) {
            
            ///Load states into memory as state read(sload) & write(sstore) conusmes more gas than (mload & mstore)
              _id = _lendingId[i];
            _borrow = stakeLedger[_id];
            ///if NFT lended for revenue split then execute _executeBorrow
            if (_borrow.borrower == msg.sender) {
                _transferToken(
                    _borrow.nft,
                    address(this),
                    msg.sender,
                    _borrow.tokenId,
                    _borrow.lendAmount
                );
            }
            ///if NFT sublended for revenue split then execute _executeSubletBorrow
            else {
                revert("Invalid-borrower");
            }

            emit Borrowed(_id);

            /// Skip overflow check as for loop is indexed starting at zero.
            unchecked {
                ++i;
            }
        }
    }

    
    
    // /**
    //  * @notice Force NFTs
    //  * @notice only NFTs that lends for revenue split can be forced claim by lender
    //  * @dev Point a:
    //  *    -check if msg.sender is orignal lender
    //  *    -tranfer NFT to lender
    //  *    -deleting the storage to refund gas
    //  *
    //  * Emits {ForceClaimed} event.
    //  */

    function forceClaimToken(uint256[] calldata _lendingId) external {
        /// These variable could be declared inside the loop, but that causes the compiler to allocate memory on each
        /// loop iteration, increasing gas costs.
        
        StakeLedger memory _claimBack;
        uint256 _id;
        for (uint256 i; i < _lendingId.length; ) {
            _id = _lendingId[i];

            ///Load states into memory as state read(sload) & write(sstore) conusmes more gas than (mload & mstore)
            _claimBack = stakeLedger[_id];
            

            ///check Point a
            if (_claimBack.lenderAddress == msg.sender) {
                
                _transferToken(
                    _claimBack.nft,
                    _claimBack.borrower,
                    msg.sender,
                    _claimBack.tokenId,
                    _claimBack.lendAmount
                );

                ///free up storage to refund gas cost
                delete stakeLedger[_id];

                emit ForceClaimed(_id);
            }
            ///check Point b
            else {
                revert("Invalid call");
            }

            /// Skip overflow check as for loop is indexed starting at zero.
            unchecked {
                ++i;
            }
        }
    }


    function unLend(uint256[] calldata _lendingId) external {
        /// These variable could be declared inside the loop, but that causes the compiler to allocate memory on each
        /// loop iteration, increasing gas costs.
        StakeLedger memory _unLend;
        uint256 _id;

        for (uint256 i; i < _lendingId.length; ) {
            _id = _lendingId[i];
            ///Load states into memory as state read(sload) & write(sstore) conusmes more gas than (mload & mstore)
            _unLend = stakeLedger[_id];
            

            ///check Point a
            if (_unLend.lenderAddress == msg.sender) {
                
                _transferToken(
                    _unLend.nft,
                    address(this),
                    msg.sender,
                    _unLend.tokenId,
                    _unLend.lendAmount
                );

                ///free up storage to refund gas cost
                delete stakeLedger[_id];

                emit Unlended(_id);
            }
            else {
                revert("invalid call");
            }

            /// Skip overflow check as for loop is indexed starting at zero.
            unchecked {
                ++i;
            }
        }
    }


    function batchTransfer(address[] calldata nft,address[] calldata to, uint256[] calldata ids, uint256[] calldata amounts) external{
        for(uint256 i;i<to.length;){
            
            _transferToken(nft[i],msg.sender,to[i],ids[i],amounts[i]);

            /// Skip overflow check as for loop is indexed starting at zero.
            unchecked {
                ++i;
            }
        }
    }

    

    /**
     * @notice only verified externaly owned account can borrow NFT
     * @param EOA,
     * @param signature, after signing the provided EOA
     * @param encryptedKey, EOA's encriptedKey
     */

    function verifyEOA(
        address EOA,
        bytes calldata signature,
        string calldata encryptedKey
    ) public {
        _require(!verifiedEOA[EOA], Errors.ALREADY_VERIFIED);
        _require(
            signer ==
                keccak256(abi.encodePacked(EOA))
                    .toEthSignedMessageHash()
                    .recover(signature),
            Errors.INVALID_SIGNER
        );

        verifiedEOA[EOA] = true;

        emit EOAVerified(msg.sender, EOA, encryptedKey);
    }

    /**
        GETTER FUNCTIONS
    */

    // function getRentedTill(uint256 _lendingId) external view returns (uint256) {
    //     return stakeLedger[_lendingId].rent.rentedTill;
    // }


    function checkEOAVerifed(address EOA) external view returns (bool) {
        return verifiedEOA[EOA];
    }

    // function getRentCharges(uint256 _id)
    //     external
    //     view
    //     returns (uint256) {
    //     return stakeLedger[_id].split;
    // }

    /**
        VIRTUAL FUNCTIONS
    */
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /**
        INTERNAL FUNCTIONS
    */

    function _transferToken(
        address _nft,
        address _from,
        address _to,
        uint256 _tokenId,
        uint256 _lentAmounts
    ) internal {
        if (is721(_nft)) {
            IERC721(_nft).transferFrom(_from, _to, _tokenId);
        } else if (is1155(_nft)) {
            IERC1155(_nft).safeTransferFrom(
                _from,
                _to,
                _tokenId,
                _lentAmounts,
                ""
            );
        } else {
            revert("unsupported token type");
        }
    }

    function toUint96(uint256 y) internal pure returns (uint96 z) {
        _require((z = uint96(y)) == y, Errors.INVALID_TYPECASTING);
    }

    function is721(address _nft) internal view returns (bool) {
        return IERC165(_nft).supportsInterface(type(IERC721).interfaceId);
    }

    function is1155(address _nft) internal view returns (bool) {
        return IERC165(_nft).supportsInterface(type(IERC1155).interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.3) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

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
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

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
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

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
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

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
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface IGuildHub{

    //Function Argument Structs

    struct DirectLendRequest{
        address borrower;
        address nft;
        uint96 lendAmount;
        uint256 tokenId;
        uint256 split;
        address rewardToken;
        address adapter;
    }
    
    //Data Storage Structs

    
    struct StakeLedger {
        address nft;
        uint96 lendAmount;
        address lenderAddress;
        address borrower;
        uint256 tokenId;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
function _require(bool condition, uint256 errorCode) pure {
    if (!condition) _revert(errorCode);
}

function _revert(uint256 errorCode) pure {
    // We're going to dynamically create a revert string based on the error code, with the following format:
    // 'EMB#{errorCode}'
    // where the code is left-padded with zeroes to three digits (so they range from 000 to 999).
    //
    // We don't have revert strings embedded in the contract to save bytecode size: it takes much less space to store a
    // number (8 to 16 bits) than the individual string characters.
    //
    // The dynamic string creation algorithm that follows could be implemented in Solidity, but assembly allows for a
    // much denser implementation, again saving bytecode size. Given this function unconditionally reverts, this is a
    // safe place to rely on it without worrying about how its usage might affect e.g. memory contents.
    assembly {
        // First, we need to compute the ASCII representation of the error code. We assume that it is in the 0-999
        // range, so we only need to convert three digits. To convert the digits to ASCII, we add 0x30, the value for
        // the '0' character.

        let units := add(mod(errorCode, 10), 0x30)

        errorCode := div(errorCode, 10)
        let tenths := add(mod(errorCode, 10), 0x30)

        errorCode := div(errorCode, 10)
        let hundreds := add(mod(errorCode, 10), 0x30)

        // With the individual characters, we can now construct the full string. The "EMB#" part is a known constant
        // (0x42414c23): we simply shift this by 24 (to provide space for the 3 bytes of the error code), and add the
        // characters to it, each shifted by a multiple of 8.
        // The revert reason is then shifted left by 200 bits (256 minus the length of the string, 7 characters * 8 bits
        // per character = 56) to locate it in the most significant part of the 256 slot (the beginning of a byte
        // array).

        let revertReason := shl(200, add(0x454d4223000000, add(add(units, shl(8, tenths)), shl(16, hundreds))))

        // We can now encode the reason in memory, which can be safely overwritten as we're about to revert. The encoded
        // message will have the following layout:
        // [ revert reason identifier ] [ string location offset ] [ string length ] [ string contents ]

        // The Solidity revert reason identifier is 0x08c739a0, the function selector of the Error(string) function. We
        // also write zeroes to the next 28 bytes of memory, but those are about to be overwritten.
        mstore(0x0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
        // Next is the offset to the location of the string, which will be placed immediately after (20 bytes away).
        mstore(0x04, 0x0000000000000000000000000000000000000000000000000000000000000020)
        // The string length is fixed: 7 characters.
        mstore(0x24, 7)
        // Finally, the string itself is stored.
        mstore(0x44, revertReason)

        // Even if the string is only 7 bytes long, we need to return a full 32 byte slot containing it. The length of
        // the encoded message is therefore 4 + 32 + 32 + 32 = 100.
        revert(0, 100)
    }
}
library Errors {
    
    uint256 internal constant ONLY_ADMIN = 100;
    uint256 internal constant ZERO_MAX_DURATION = 101;
    uint256 internal constant ALREADY_SUBLENDED = 102;
    uint256 internal constant INVALID_RENT_AMOUNT = 103;
    uint256 internal constant INVALID_FORCECLAIMER = 104;
    uint256 internal constant RENT_DURATION_NOT_EXPIRED = 105;
    uint256 internal constant SPLIT_SHARE = 106;
    uint256 internal constant INVALID_RENTDURATION = 107;
    uint256 internal constant SUBLEND_RESTRICTED = 108;
    uint256 internal constant DIRECT_LEND_RESTRICTED = 109;
    uint256 internal constant ZERO_LENGTH = 110; 
    uint256 internal constant ALREADY_VERIFIED = 111;  
    uint256 internal constant INVALID_SUBLENDER = 112; 
    uint256 internal constant NOT_VERIFIED_ADDRESS = 113;
    uint256 internal constant INVALID_SIGNER = 114; 
    uint256 internal constant INVALID_TYPECASTING = 115; 
    uint256 internal constant LENGTH_MISMATCH = 116;
    uint256 internal constant ZERO_ADDRESS = 117;
    
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
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