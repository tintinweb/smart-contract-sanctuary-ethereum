// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

/**

    -+#@@@@***#%%#*=.                                                           
      [email protected]@@%      -%@@#:                                                         
      [email protected]@@%        %@@@+     .=   .==.    :===-:        .=  :==-       :-=-.  -.
      [email protected]@@%        [email protected]@@@. .=%@@.=%@@@# .*@#. :%@@+   .=%@@[email protected]@@@@*.  [email protected]@+::=+%@:
      [email protected]@@%        [email protected]@@@=.-%@@@:..#@@%:@@@-    @@@@..-%@@@=::-#@@@%  @@@*:   [email protected]:
      [email protected]@@%        :@@@@-  #@@@   ++- #@@@-    [email protected]@@#  #@@@.    #@@@= *@@@@@*- :.
      [email protected]@@%        *@@@%   #@@@       %@@@=    [email protected]@@@  #@@@.    [email protected]@@= .:[email protected]@@@@@*.
      [email protected]@@%       :@@@#    #@@@       [email protected]@@%    :@@@*  #@@@.    %@@@..%.  :+%@@@%
      [email protected]@@%      [email protected]@#-     #@@@        [email protected]@@=   [email protected]@#   #@@@=..:#@@@: [email protected]@=    *@@#
    -+#####****+++-      .=####+-.      .=#@#=+#+:    #@@@:*@@@%+.  .%:.+**#@%= 
                                                      #@@@.                     
    -----------------------------------------         #@@@.                     
     F R O M   S A M   K I N G   S T U D I O        .=####+-.
    -----------------------------------------

 */

import "solmate/tokens/ERC1155.sol";
import "openzeppelin/utils/cryptography/ECDSA.sol";
import "openzeppelin/utils/cryptography/draft-EIP712.sol";
import "./lib/Auth.sol";
import "./IMetadata.sol";

/**
 * @title  Drops from Sam King Studio
 * @author Sam King (samkingstudio.eth)
 * @notice
 * Allows Sam King Studio to drop NFTs to any ETH address
 *   - NFTs are ERC-1155 tokens
 *   - Can be dropped by the studio directly
 *   - Can also be claimed by an address with a valid EIP-712 signature
 * For more details and license info, check out https://drops.samking.studio
 */
contract Drops is ERC1155, EIP712, Auth {
    /* ------------------------------------------------------------------------
       S T O R A G E
    ------------------------------------------------------------------------ */

    string public name = "Drops from Sam King Studio";
    string public symbol = "SKSDRP";

    /// @dev EIP-712 signing domain
    string public constant SIGNING_DOMAIN = "SamKingStudioDrops";

    /// @dev EIP-712 signature version
    string public constant SIGNATURE_VERSION = "1";

    /// @dev EIP-712 signed data type hash for claiming drops
    bytes32 public constant CLAIM_DROP_TYPEHASH =
        keccak256("ClaimDropData(uint256 dropId,uint256 amount,address to,uint256 nonce)");

    /// @dev EIP-712 signed data struct for claiming drops
    struct ClaimDropData {
        uint256 dropId;
        uint256 amount;
        address to;
        uint256 nonce;
        bytes signature;
    }

    /// @dev Approved signer public addresses
    mapping(address => bool) public approvedSigners;

    /// @dev Nonce management to avoid signature replay attacks
    mapping(address => uint256) public nonces;

    /// @notice Set a token metadata URI per drop
    mapping(uint256 => string) public dropURI;

    /// @notice Optional token metadata contract per drop
    mapping(uint256 => address) public dropMetadataAddress;

    /* ------------------------------------------------------------------------
       I N I T
    ------------------------------------------------------------------------ */

    event Initialised();

    /**
     * @notice Init the contract
     * @param owner_ The owner of the contract. Can use drops.
     * @param admin_ The initial admin of the contract. Can use drops.
     * @param signer_ An initial EIP-712 signing address
     */
    constructor(
        address owner_,
        address admin_,
        address signer_
    ) EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION) Auth(owner_, admin_) {
        approvedSigners[signer_] = true;
        emit SignerAdded(signer_);
        emit Initialised();
    }

    /* ------------------------------------------------------------------------
       M O D I F I E R S
    ------------------------------------------------------------------------ */

    /**
     * @dev
     * Only allows the function to be called when a URI or metadata address has been
     * set for the particular drop
     *
     * @param dropId The id of the drop to check
     */
    modifier onlyWhenDropIsReady(uint256 dropId) {
        // If there's no metadata address, then check if there's a uri set
        if (dropMetadataAddress[dropId] == address(0)) {
            bytes memory dropUri = bytes(dropURI[dropId]);
            require(dropUri.length > 0, "DROP_NOT_READY");
        }
        _;
    }

    /* ------------------------------------------------------------------------
       D R O P S
    ------------------------------------------------------------------------ */

    /// @dev Emitted when an admin has called any of the drop functions
    event Dropped(uint256 indexed dropId);

    /**
     * @notice Mints one token from the specified drop to each recipient
     *
     * @param dropId The id of the drop
     * @param recipients The list of address to mint tokens to
     */
    function drop(uint256 dropId, address[] calldata recipients)
        external
        onlyWhenDropIsReady(dropId)
        onlyOwnerOrAdmin
    {
        for (uint256 i = 0; i < recipients.length; i++) {
            _mint(recipients[i], dropId, 1, "");
        }
        emit Dropped(dropId);
    }

    /**
     * @notice Mints multiple tokens from the specified drop to each recipient
     *
     * @param dropId The id of the drop
     * @param recipients The list of address to mint tokens to
     * @param amount The amount of tokens to mint to each recipient
     */
    function drop(
        uint256 dropId,
        address[] calldata recipients,
        uint256 amount
    ) external onlyWhenDropIsReady(dropId) onlyOwnerOrAdmin {
        if (amount > 0) {
            for (uint256 i = 0; i < recipients.length; i++) {
                _mint(recipients[i], dropId, amount, "");
            }
        }
        emit Dropped(dropId);
    }

    /**
     * @notice Mints multiple tokens from the specified drop to each recipient
     *
     * @param dropId The id of the drop
     * @param recipients The list of address to mint tokens to
     * @param amounts The amount of tokens to mint per recipient
     */
    function drop(
        uint256 dropId,
        address[] calldata recipients,
        uint256[] calldata amounts
    ) external onlyWhenDropIsReady(dropId) onlyOwnerOrAdmin {
        require(recipients.length == amounts.length, "LENGTH_MISMATCH");
        for (uint256 i = 0; i < recipients.length; i++) {
            if (amounts[i] > 0) {
                _mint(recipients[i], dropId, amounts[i], "");
            }
        }
        emit Dropped(dropId);
    }

    /**
     * @notice Mints tokens from the specified drop to a specific address,
     * usually the Sam King Studio or owner address.
     *
     * @param dropId The id of the drop
     * @param to The list of address to mint tokens to
     * @param amount The amount of tokens to mint per recipient
     */
    function studioMint(
        uint256 dropId,
        address to,
        uint256 amount
    ) external onlyWhenDropIsReady(dropId) onlyOwnerOrAdmin {
        _mint(to, dropId, amount, "");
        emit Dropped(dropId);
    }

    /// @dev Emitted when a drop is claimed using EIP-712
    event DropClaimed(uint256 indexed dropId, address indexed by, uint256 indexed amount);

    /**
     * @notice Claims a drop using an EIP-712 signature. Caller pays gas to claim
     * instead of being airdropped by Sam King Studio.
     *
     * @param dropId The id of the drop
     * @param amount The amount of tokens to mint
     * @param signature A valid EIP-712 signature
     */
    function claimDrop(
        uint256 dropId,
        uint256 amount,
        bytes calldata signature
    ) external onlyWhenDropIsReady(dropId) {
        // Reconstruct the signed data on-chain
        ClaimDropData memory data = ClaimDropData({
            dropId: dropId,
            amount: amount,
            to: msg.sender,
            nonce: nonces[msg.sender],
            signature: signature
        });

        // Hash the data for verification
        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    CLAIM_DROP_TYPEHASH,
                    data.dropId,
                    data.amount,
                    data.to,
                    nonces[data.to]++
                )
            )
        );

        // Verifiy signature is ok
        address addr = ECDSA.recover(digest, data.signature);
        require(approvedSigners[addr] && addr != address(0), "INVALID_SIGNATURE");

        // Claim the drop
        if (data.amount > 0) {
            _mint(data.to, data.dropId, data.amount, "");
            emit DropClaimed(data.dropId, data.to, data.amount);
        }
    }

    /* ------------------------------------------------------------------------
       A D M I N
    ------------------------------------------------------------------------ */

    /**
     * @notice Admin function to set the URI for a particular drop
     * @dev Emits the URI event from ERC1155
     *
     * @param dropId The id of the drop to set the URI for
     * @param uri_ The new URI
     */
    function setDropURI(uint256 dropId, string calldata uri_) external onlyOwnerOrAdmin {
        dropURI[dropId] = uri_;
        emit URI(uri_, dropId);
    }

    /**
     * @notice Admin function to set the URI for a particular drop
     * @dev Emits the URI event from ERC1155
     *
     * @param dropId The id of the drop to set the URI for
     * @param metadata The new metadata contract address
     */
    function setDropMetadataAddress(uint256 dropId, address metadata) external onlyOwnerOrAdmin {
        dropMetadataAddress[dropId] = metadata;
        emit URI(IMetadata(metadata).uri(dropId), dropId);
    }

    /// @dev Emitted when a new signer is added to this contract
    event SignerAdded(address indexed signer);

    /**
     * @notice Admin function to add a new EIP-712 signer address
     * @dev Emits the SignerAdded event
     *
     * @param signer The address of the new signer
     */
    function addSigner(address signer) external onlyOwnerOrAdmin {
        approvedSigners[signer] = true;
        emit SignerAdded(signer);
    }

    /// @dev Emitted when an existing signer is removed from this contract
    event SignerRemoved(address indexed signer);

    /**
     * @notice Admin function to remove an existing EIP-712 signer address
     * @dev Emits the SignerRemoved event
     *
     * @param signer The address of the signer to remove
     */
    function removeSigner(address signer) external onlyOwnerOrAdmin {
        approvedSigners[signer] = false;
        emit SignerRemoved(signer);
    }

    /* ------------------------------------------------------------------------
       M E T A D A T A
    ------------------------------------------------------------------------ */

    /**
     * @notice ERC1155 token URI
     * @param id The token id to get token metadata for
     * @return metadata The token metadata URI or Base64 encoded JSON token metadata
     */
    function uri(uint256 id) public view override returns (string memory) {
        address metadata = dropMetadataAddress[id];
        if (metadata != address(0)) return IMetadata(metadata).uri(id);
        return dropURI[id];
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Minimalist and gas efficient standard ERC1155 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 amount
    );

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] amounts
    );

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    event URI(string value, uint256 indexed id);

    /*//////////////////////////////////////////////////////////////
                             ERC1155 STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(address => mapping(uint256 => uint256)) public balanceOf;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                             METADATA LOGIC
    //////////////////////////////////////////////////////////////*/

    function uri(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                              ERC1155 LOGIC
    //////////////////////////////////////////////////////////////*/

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public virtual {
        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        balanceOf[from][id] -= amount;
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, from, to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(msg.sender, from, id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public virtual {
        require(ids.length == amounts.length, "LENGTH_MISMATCH");

        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        // Storing these outside the loop saves ~15 gas per iteration.
        uint256 id;
        uint256 amount;

        for (uint256 i = 0; i < ids.length; ) {
            id = ids[i];
            amount = amounts[i];

            balanceOf[from][id] -= amount;
            balanceOf[to][id] += amount;

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, from, ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids)
        public
        view
        virtual
        returns (uint256[] memory balances)
    {
        require(owners.length == ids.length, "LENGTH_MISMATCH");

        balances = new uint256[](owners.length);

        // Unchecked because the only math done is incrementing
        // the array index counter which cannot possibly overflow.
        unchecked {
            for (uint256 i = 0; i < owners.length; ++i) {
                balances[i] = balanceOf[owners[i]][ids[i]];
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0xd9b67a26 || // ERC165 Interface ID for ERC1155
            interfaceId == 0x0e89341c; // ERC165 Interface ID for ERC1155MetadataURI
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, address(0), to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(msg.sender, address(0), id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchMint(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[to][ids[i]] += amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, address(0), to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, address(0), ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchBurn(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[from][ids[i]] -= amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, address(0), ids, amounts);
    }

    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        balanceOf[from][id] -= amount;

        emit TransferSingle(msg.sender, from, address(0), id, amount);
    }
}

/// @notice A generic interface for a contract which properly accepts ERC1155 tokens.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155TokenReceiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/ECDSA.sol)

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
        InvalidSignatureV // Deprecated in v4.8
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

pragma solidity ^0.8.0;

// EIP-712 is Final as of 2022-08-11. This file is deprecated.

import "./EIP712.sol";

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

/**
 * @author Sam King (samkingstudio.eth)
 * @title  Simple owner and admin authentication
 * @notice Allows the management of a contract by using simple ownership and admin modifiers.
 */
abstract contract Auth {
    /* ------------------------------------------------------------------------
       S T O R A G E
    ------------------------------------------------------------------------ */

    /// @notice Current owner of the contract
    address public owner;

    /// @notice Current admins of the contract
    mapping(address => bool) public admins;

    /* ------------------------------------------------------------------------
       E V E N T S
    ------------------------------------------------------------------------ */

    /**
     * @notice When the contract owner is updated
     * @param user The account that updated the new owner
     * @param newOwner The new owner of the contract
     */
    event OwnerUpdated(address indexed user, address indexed newOwner);

    /**
     * @notice When an admin is added to the contract
     * @param user The account that added the new admin
     * @param newAdmin The admin that was added
     */
    event AdminAdded(address indexed user, address indexed newAdmin);

    /**
     * @notice When an admin is removed from the contract
     * @param user The account that removed an admin
     * @param prevAdmin The admin that got removed
     */
    event AdminRemoved(address indexed user, address indexed prevAdmin);

    /* ------------------------------------------------------------------------
       M O D I F I E R S
    ------------------------------------------------------------------------ */

    /**
     * @dev Only the owner can call
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "UNAUTHORIZED");
        _;
    }

    /**
     * @dev Only an admin can call
     */
    modifier onlyAdmin() {
        require(admins[msg.sender], "UNAUTHORIZED");
        _;
    }

    /**
     * @dev Only the owner or an admin can call
     */
    modifier onlyOwnerOrAdmin() {
        require((msg.sender == owner || admins[msg.sender]), "UNAUTHORIZED");
        _;
    }

    /* ------------------------------------------------------------------------
       I N I T
    ------------------------------------------------------------------------ */

    /**
     * @dev Sets the initial owner and a first admin upon creation.
     * @param owner_ The initial owner of the contract
     * @param admin_ An initial admin of the contract
     */
    constructor(address owner_, address admin_) {
        owner = owner_;
        emit OwnerUpdated(address(0), owner_);

        admins[admin_] = true;
        emit AdminAdded(address(0), admin_);
    }

    /* ------------------------------------------------------------------------
       A D M I N
    ------------------------------------------------------------------------ */

    /**
     * @notice Transfers ownership of the contract to `newOwner`
     * @dev Can only be called by the current owner or an admin
     * @param newOwner The new owner of the contract
     */
    function setOwner(address newOwner) public virtual onlyOwnerOrAdmin {
        owner = newOwner;
        emit OwnerUpdated(msg.sender, newOwner);
    }

    /**
     * @notice Adds `newAdmin` as an amdin of the contract
     * @dev Can only be called by the current owner or an admin
     * @param newAdmin A new admin of the contract
     */
    function addAdmin(address newAdmin) public virtual onlyOwnerOrAdmin {
        admins[newAdmin] = true;
        emit AdminAdded(address(0), newAdmin);
    }

    /**
     * @notice Removes `prevAdmin` as an amdin of the contract
     * @dev Can only be called by the current owner or an admin
     * @param prevAdmin The admin to remove
     */
    function removeAdmin(address prevAdmin) public virtual onlyOwnerOrAdmin {
        admins[prevAdmin] = false;
        emit AdminRemoved(address(0), prevAdmin);
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

interface IMetadata {
    function uri(uint256 id) external view returns (string memory);
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