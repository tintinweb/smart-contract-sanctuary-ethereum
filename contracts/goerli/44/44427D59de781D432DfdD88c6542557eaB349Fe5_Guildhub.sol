/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./interfaces/IGuildhub.sol";

contract Guildhub is IGuildHub, Pausable {
    using ECDSA for bytes32;

    /// Signer who sign EOA 
    address private immutable signer;

    /// Contract owner who can execute onlyOwner functions
    address private immutable contractOwner;

    /// unique key
    uint256 private lendingId;

    /// details stored against lendingId
    mapping(uint256 => IGuildHub.StakeLedger) private stakeLedger;

    /// check address is verified
    mapping(address => bool) private verifiedEOA;

    /// Events
    event DirectLended(
        uint256 indexed lendingId,
        address nft,
        uint256 tokenid,
        uint256 lendAmount,
        address indexed borrower,
        address rewardToken,
        uint256 split,
        address adapter
    );

    event Borrowed(uint256 indexed lendingId, address indexed msgsender);
    event Unlended(uint256 indexed lendingId, address indexed msgsender);
    event Claimed(uint256 indexed lendingId, address indexed borrower);
    event Withdrawn(uint256 indexed lendingId, address borrower);
    event EOAVerified(address indexed msgsender, address indexed EOA, string encrypted);

    constructor(address _signer, address _contractOwner) {
        require(_signer != address(0), "ZERO_ADDRESS");
        require(_contractOwner != address(0), "ZERO_ADDRESS");
        signer = _signer;
        contractOwner = _contractOwner;
    }

    modifier onlyOwner() {
        require(msg.sender == contractOwner, "ONLY_ADMIN");
        _;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
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
        for (uint256 i; i < data.length; ) {
            /// if borrwer address is not verified
            if (!verifiedEOA[data[i].borrower]) {
                verifyEOA(data[i].borrower, sig[i], key[i]);
            }

            /// Skip overflow check as for loop is indexed starting at zero.
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
        /// These variable could be declared inside the loop, but that causes the compiler to allocate memory on each
        /// loop iteration, increasing gas costs.
        DirectLendRequest memory _lendData;
        StakeLedger memory _lend;

        /// loading state variable into memory as memory operations are cheaper than state operations
        uint256 _lendingId = lendingId;

        for (uint256 i; i < data.length; ) {
            /// By indexing the array only once, we don't spend extra gas in the same bounds check.
            _lendData = data[i];

            /// check borrower address is verified
            require(verifiedEOA[_lendData.borrower], "NOT_VERIFIED_ADDRESS");

            _lend.lenderAddress = msg.sender;
            _lend.tokenId = _lendData.tokenId;
            _lend.nft = _lendData.nft;
            _lend.lendAmount = _lendData.lendAmount;
            _lend.borrower = _lendData.borrower;

            _transferToken(_lendData.nft, msg.sender, address(this), _lendData.tokenId, _lendData.lendAmount);

            ///update state from memory
            stakeLedger[_lendingId] = _lend;

            emit DirectLended(
                _lendingId,
                _lendData.nft,
                _lendData.tokenId,
                _lendData.lendAmount,
                _lendData.borrower,
                _lendData.rewardToken,
                _lendData.split,
                _lendData.adapter
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
     * @notice Borrow NFT
     * @notice only lender's provided address can borrow that NFT;
     * Emits {borrowed} event.
     */

    function borrow(uint256[] calldata _lendingId) external whenNotPaused {
        /// These variable could be declared inside the loop, but that causes the compiler to allocate memory on each
        /// loop iteration, increasing gas costs.
        uint256 _id;
        StakeLedger memory _borrow;

        for (uint256 i; i < _lendingId.length; ) {
            ///Load states into memory as state read(sload) & write(sstore) conusmes more gas than (mload & mstore)
            _id = _lendingId[i];
            _borrow = stakeLedger[_id];
            if (_borrow.borrower == msg.sender) {
                _transferToken(_borrow.nft, address(this), msg.sender, _borrow.tokenId, _borrow.lendAmount);
            } else {
                revert("INVALID-BORROWER");
            }

            emit Borrowed(_id, msg.sender);

            /// Skip overflow check as for loop is indexed starting at zero.
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice claim back NFTs from borrowers
     * @dev Point a:
     *    -check if msg.sender is orignal lender
     *    -tranfer NFT to lender
     *    -deleting the storage to refund gas
     *
     * Emits {Claimed} event.
     */

    function claimBacKTokens(uint256[] calldata _lendingId) external {
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

                emit Claimed(_id, _claimBack.borrower);
            } else {
                revert("INVALID-CALL");
            }

            /// Skip overflow check as for loop is indexed starting at zero.
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice unlend NFTs if its not borrowed
     * @dev Point a:
     *    -check if msg.sender is orignal lender
     *    -tranfer NFT to lender
     *    -deleting the storage to refund gas
     *
     * Emits {unLended} event.
     */

    function unLend(uint256[] calldata _lendingId) external {
        /// These variable could be declared inside the loop, but that causes the compiler to allocate memory on each
        /// loop iteration, increasing gas costs.
        StakeLedger memory _unLend;
        uint256 _id;

        for (uint256 i; i < _lendingId.length; ) {
            _id = _lendingId[i];

            ///Load states into memory as state read(sload) & write(sstore) conusmes more gas than (mload & mstore)
            _unLend = stakeLedger[_id];

            //check Point a
            if (_unLend.lenderAddress == msg.sender) {
                _transferToken(_unLend.nft, address(this), msg.sender, _unLend.tokenId, _unLend.lendAmount);

                ///free up storage to refund gas cost
                delete stakeLedger[_id];

                emit Unlended(_id, msg.sender);
            } else {
                revert("INVALID-CALL");
            }

            /// Skip overflow check as for loop is indexed starting at zero.
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Transfer NFTs from borrowers to contract
     * @notice this function can only be called by owner & when contract on paused state;
     * @notice this function execution can exceed block GAS_LIMIT   
     * @param _lendingId of NFTs which are not borrowed yet
     */
    function emergencyWithdraw(uint256[] calldata _lendingId) external whenPaused onlyOwner {
        StakeLedger memory _withDraw;
        uint256 _id;

        for (uint256 i; i < _lendingId.length; ) {
            _id = _lendingId[i];
            _withDraw = stakeLedger[_id];
            if (_withDraw.nft == address(0)) {
                ///skip if incorrect lendingId
            } else if (is721(_withDraw.nft)) {
                if (IERC721(_withDraw.nft).ownerOf(_withDraw.tokenId) == _withDraw.borrower) {
                    IERC721(_withDraw.nft).transferFrom(_withDraw.borrower, address(this), _withDraw.tokenId);
                }
            } else if (is1155(_withDraw.nft)) {
                if (IERC1155(_withDraw.nft).balanceOf(_withDraw.borrower, _withDraw.tokenId) != 0) {
                    IERC1155(_withDraw.nft).safeTransferFrom(
                        _withDraw.borrower,
                        address(this),
                        _withDraw.tokenId,
                        _withDraw.lendAmount,
                        ""
                    );
                }
            }

            /// Skip overflow check as for loop is indexed starting at zero.
            unchecked {
                ++i;
            }

            emit Withdrawn(_id, _withDraw.borrower);
        }
    }

    /**
     * @notice only verified externaly owned account can borrow NFT
     * @param EOA,
     * @param signature, after signing the provided EOA
     * @param encryptedKey, EOA's encriptedKey
     */

    function verifyEOA(address EOA, bytes calldata signature, string calldata encryptedKey) public whenNotPaused {
        require(!verifiedEOA[EOA], "ALREADY_VERIFIED");
        require(
            signer == keccak256(abi.encodePacked(EOA, encryptedKey)).toEthSignedMessageHash().recover(signature),
            "INVALID_SIGNER"
        );

        verifiedEOA[EOA] = true;

        emit EOAVerified(msg.sender, EOA, encryptedKey);
    }

    function batchTransfer(
        address[] calldata nft,
        address[] calldata to,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) external {
        for (uint256 i; i < to.length; ) {
            _transferToken(nft[i], msg.sender, to[i], ids[i], amounts[i]);

            /// Skip overflow check as for loop is indexed starting at zero.
            unchecked {
                ++i;
            }
        }
    }

    /**
        GETTER FUNCTIONS
    */

    function checkEOAVerifed(address EOA) external view returns (bool) {
        return verifiedEOA[EOA];
    }

    /**
        VIRTUAL FUNCTIONS
    */
    function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual returns (bytes4) {
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

    function onERC721Received(address, address, uint256, bytes memory) public virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /**
        INTERNAL FUNCTIONS
    */

    function _transferToken(address _nft, address _from, address _to, uint256 _tokenId, uint256 _lentAmounts) internal {
        if (is721(_nft)) {
            IERC721(_nft).transferFrom(_from, _to, _tokenId);
        } else if (is1155(_nft)) {
            IERC1155(_nft).safeTransferFrom(_from, _to, _tokenId, _lentAmounts, "");
        } else {
            revert("UNSUPPORTED-TOKEN-TYPE");
        }
    }

    function is721(address _nft) public view returns (bool) {
        return IERC165(_nft).supportsInterface(type(IERC721).interfaceId);
    }

    function is1155(address _nft) public view returns (bool) {
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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
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