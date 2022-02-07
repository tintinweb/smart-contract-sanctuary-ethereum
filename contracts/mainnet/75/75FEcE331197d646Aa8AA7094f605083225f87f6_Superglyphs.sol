//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @title INiftyForge721
/// @author Simon Fremaux (@dievardump)
/// @notice Interface to interact with a NiftyFroge721 on a network
interface INiftyForge721 {
    struct ModuleInit {
        address module;
        bool enabled;
        bool minter;
    }

    /// @notice totalSupply access
    function totalSupply() external view returns (uint256);

    /// @notice helper to know if everyone can mint or only minters
    function isMintingOpenToAll() external view returns (bool);

    /// @notice Toggle minting open to all state
    /// @param isOpen if the new state is open or not
    function setMintingOpenToAll(bool isOpen) external;

    /// @notice Mint token to `to` with `uri`
    /// @param to address of recipient
    /// @param uri token metadata uri
    /// @param feeRecipient the recipient of royalties
    /// @param feeAmount the royalties amount. From 0 to 10000
    ///        where 10000 == 100.00%; 1000 == 10.00%; 250 == 2.50%
    /// @param transferTo the address to transfer the NFT to after mint
    ///        this is used when we want to mint the NFT to the creator address
    ///        before transferring it to a recipient
    /// @return tokenId the tokenId
    function mint(
        address to,
        string memory uri,
        address feeRecipient,
        uint256 feeAmount,
        address transferTo
    ) external returns (uint256 tokenId);

    /// @notice Mint batch tokens to `to[i]` with `uri[i]`
    /// @param to array of address of recipients
    /// @param uris array of token metadata uris
    /// @param feeRecipients the recipients of royalties for each id
    /// @param feeAmounts the royalties amounts for each id. From 0 to 10000
    ///        where 10000 == 100.00%; 1000 == 10.00%; 250 == 2.50%
    /// @return tokenIds the tokenIds
    function mintBatch(
        address[] memory to,
        string[] memory uris,
        address[] memory feeRecipients,
        uint256[] memory feeAmounts
    ) external returns (uint256[] memory tokenIds);

    /// @notice Mint `tokenId` to to` with `uri`
    ///         Because not all tokenIds have incremental ids
    ///         be careful with this function, it does not increment lastTokenId
    ///         and expects the minter to actually know what it is doing.
    ///         this also means, this function does not verify _maxTokenId
    /// @param to address of recipient
    /// @param uri token metadata uri
    /// @param tokenId token id wanted
    /// @param feeRecipient the recipient of royalties
    /// @param feeAmount the royalties amount. From 0 to 10000
    ///        where 10000 == 100.00%; 1000 == 10.00%; 250 == 2.50%
    /// @param transferTo the address to transfer the NFT to after mint
    ///        this is used when we want to mint the NFT to the creator address
    ///        before transferring it to a recipient
    /// @return tokenId the tokenId
    function mint(
        address to,
        string memory uri,
        uint256 tokenId_,
        address feeRecipient,
        uint256 feeAmount,
        address transferTo
    ) external returns (uint256 tokenId);

    /// @notice Mint batch tokens to `to[i]` with `uris[i]`
    ///         Because not all tokenIds have incremental ids
    ///         be careful with this function, it does not increment lastTokenId
    ///         and expects the minter to actually know what it's doing.
    ///         this also means, this function does not verify _maxTokenId
    /// @param to array of address of recipients
    /// @param uris array of token metadata uris
    /// @param tokenIds array of token ids wanted
    /// @param feeRecipients the recipients of royalties for each id
    /// @param feeAmounts the royalties amounts for each id. From 0 to 10000
    ///        where 10000 == 100.00%; 1000 == 10.00%; 250 == 2.50%
    /// @return tokenIds the tokenIds
    function mintBatch(
        address[] memory to,
        string[] memory uris,
        uint256[] memory tokenIds,
        address[] memory feeRecipients,
        uint256[] memory feeAmounts
    ) external returns (uint256[] memory);

    /// @notice Attach a module
    /// @param module a module to attach
    /// @param enabled if the module is enabled by default
    /// @param canModuleMint if the module has to be given the minter role
    function attachModule(
        address module,
        bool enabled,
        bool canModuleMint
    ) external;

    /// @dev Allows owner to enable a module
    /// @param module to enable
    /// @param canModuleMint if the module has to be given the minter role
    function enableModule(address module, bool canModuleMint) external;

    /// @dev Allows owner to disable a module
    /// @param module to disable
    function disableModule(address module, bool keepListeners) external;

    /// @notice function that returns a string that can be used to render the current token
    /// @param tokenId tokenId
    /// @return the URI to render token
    function renderTokenURI(uint256 tokenId)
        external
        view
        returns (string memory);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/utils/introspection/IERC165.sol';

interface INFModule is IERC165 {
    /// @notice Called by a Token Registry whenever the module is Attached
    /// @return if the attach worked
    function onAttach() external returns (bool);

    /// @notice Called by a Token Registry whenever the module is Enabled
    /// @return if the enabling worked
    function onEnable() external returns (bool);

    /// @notice Called by a Token Registry whenever the module is Disabled
    function onDisable() external;

    /// @notice returns an URI with information about the module
    /// @return the URI where to find information about the module
    function contractURI() external view returns (string memory);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import './INFModule.sol';

interface INFModuleTokenURI is INFModule {
    function tokenURI(uint256 tokenId) external view returns (string memory);

    function tokenURI(address registry, uint256 tokenId)
        external
        view
        returns (string memory);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import './INFModule.sol';

interface INFModuleWithRoyalties is INFModule {
    /// @notice Return royalties (recipient, basisPoint) for tokenId
    /// @dev Contrary to EIP2981, modules are expected to return basisPoint for second parameters
    ///      This in order to allow right royalties on marketplaces not supporting 2981 (like Rarible)
    /// @param tokenId token to check
    /// @return recipient and basisPoint for this tokenId
    function royaltyInfo(uint256 tokenId)
        external
        view
        returns (address recipient, uint256 basisPoint);

    /// @notice Return royalties (recipient, basisPoint) for tokenId
    /// @dev Contrary to EIP2981, modules are expected to return basisPoint for second parameters
    ///      This in order to allow right royalties on marketplaces not supporting 2981 (like Rarible)
    /// @param registry registry to check id of
    /// @param tokenId token to check
    /// @return recipient and basisPoint for this tokenId
    function royaltyInfo(address registry, uint256 tokenId)
        external
        view
        returns (address recipient, uint256 basisPoint);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';
import './INFModule.sol';

/// @title NFBaseModule
/// @author Simon Fremaux (@dievardump)
contract NFBaseModule is INFModule, ERC165 {
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet internal _attached;

    event NewContractURI(string contractURI);

    string private _contractURI;

    modifier onlyAttached(address registry) {
        require(_attached.contains(registry), '!NOT_ATTACHED!');
        _;
    }

    constructor(string memory contractURI_) {
        _setContractURI(contractURI_);
    }

    /// @inheritdoc	INFModule
    function contractURI()
        external
        view
        virtual
        override
        returns (string memory)
    {
        return _contractURI;
    }

    /// @inheritdoc	INFModule
    function onAttach() external virtual override returns (bool) {
        if (_attached.add(msg.sender)) {
            return true;
        }

        revert('!ALREADY_ATTACHED!');
    }

    /// @notice this contract doesn't really care if it's enabled or not
    ///         since trying to mint on a contract where it's not enabled will fail
    /// @inheritdoc	INFModule
    function onEnable() external pure virtual override returns (bool) {
        return true;
    }

    /// @inheritdoc	INFModule
    function onDisable() external virtual override {}

    function _setContractURI(string memory contractURI_) internal {
        _contractURI = contractURI_;
        emit NewContractURI(contractURI_);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';

/// @title SignedAllowance
/// @author Simon Fremaux (@dievardump)
contract SignedAllowance {
    using ECDSA for bytes32;

    // list of already used allowances
    mapping(bytes32 => bool) public usedAllowances;

    // address used to sign the allowances
    address private _allowancesSigner;

    /// @notice Helper to know allowancesSigner address
    /// @return the allowance signer address
    function allowancesSigner() public view virtual returns (address) {
        return _allowancesSigner;
    }

    /// @notice Helper that creates the message that signer needs to sign to allow a mint
    ///         this is usually also used when creating the allowances, to ensure "message"
    ///         is the same
    /// @param account the account to allow
    /// @param nonce the nonce
    /// @return the message to sign
    function createMessage(address account, uint256 nonce)
        public
        view
        returns (bytes32)
    {
        return keccak256(abi.encode(account, nonce, address(this)));
    }

    /// @notice Helper that creates a list of messages that signer needs to sign to allow mintings
    /// @param accounts the accounts to allow
    /// @param nonces the corresponding nonces
    /// @return messages the messages to sign
    function createMessages(address[] memory accounts, uint256[] memory nonces)
        external
        view
        returns (bytes32[] memory messages)
    {
        require(accounts.length == nonces.length, '!LENGTH_MISMATCH!');
        messages = new bytes32[](accounts.length);
        for (uint256 i; i < accounts.length; i++) {
            messages[i] = createMessage(accounts[i], nonces[i]);
        }
    }

    /// @notice This function verifies that the current request is valid
    /// @dev It ensures that _allowancesSigner signed a message containing (account, nonce, address(this))
    ///      and that this message was not already used
    /// @param account the account the allowance is associated to
    /// @param nonce the nonce associated to this allowance
    /// @param signature the signature by the allowance signer wallet
    /// @return the message to mark as used
    function validateSignature(
        address account,
        uint256 nonce,
        bytes memory signature
    ) public view returns (bytes32) {
        return
            _validateSignature(account, nonce, signature, allowancesSigner());
    }

    /// @dev It ensures that signer signed a message containing (account, nonce, address(this))
    ///      and that this message was not already used
    /// @param account the account the allowance is associated to
    /// @param nonce the nonce associated to this allowance
    /// @param signature the signature by the allowance signer wallet
    /// @param signer the signer
    /// @return the message to mark as used
    function _validateSignature(
        address account,
        uint256 nonce,
        bytes memory signature,
        address signer
    ) internal view returns (bytes32) {
        bytes32 message = createMessage(account, nonce)
            .toEthSignedMessageHash();

        // verifies that the sha3(account, nonce, address(this)) has been signed by signer
        require(message.recover(signature) == signer, '!INVALID_SIGNATURE!');

        // verifies that the allowances was not already used
        require(usedAllowances[message] == false, '!ALREADY_USED!');

        return message;
    }

    /// @notice internal function that verifies an allowance and marks it as used
    ///         this function throws if signature is wrong or this nonce for this user has already been used
    /// @param account the account the allowance is associated to
    /// @param nonce the nonce
    /// @param signature the signature by the allowance wallet
    function _useAllowance(
        address account,
        uint256 nonce,
        bytes memory signature
    ) internal {
        bytes32 message = validateSignature(account, nonce, signature);
        usedAllowances[message] = true;
    }

    /// @notice Allows to change the allowance signer. This can be used to revoke any signed allowance not already used
    /// @param newSigner the new signer address
    function _setAllowancesSigner(address newSigner) internal {
        _allowancesSigner = newSigner;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/ECDSA.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '../utils/Randomize.sol';

/// @title ISuperglyphsRenderer
/// @author Simon Fremaux (@dievardump)
interface ISuperglyphsRenderer {
    struct Configuration {
        uint256 seed;
        uint256 mod;
        int256 z1;
        int256 z2;
        bool randStroke;
        bool fullSymmetry;
        bool darkTheme;
        bytes9[2] colors;
        bytes16 symbols;
    }

    function start(
        uint256 seed,
        uint256 colorSeed,
        bytes16 selectedColors,
        bytes16 selectedSymbols
    )
        external
        pure
        returns (Randomize.Random memory random, Configuration memory config);

    /// @dev Rendering function
    /// @param name the token name
    /// @param tokenId the tokenId
    /// @param colorSeed the seed used for coloring, if no color selected
    /// @param selectedColors the user selected colors
    /// @param selectedSymbols the symbols selected by the user
    /// @param frozen if the token customization is frozen
    /// @return the json
    function render(
        string memory name,
        uint256 tokenId,
        uint256 colorSeed,
        bytes16 selectedColors,
        bytes16 selectedSymbols,
        bool frozen
    ) external view returns (string memory);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';

import '@dievardump-web3/niftyforge/contracts/Modules/NFBaseModule.sol';
import '@dievardump-web3/niftyforge/contracts/Modules/INFModuleTokenURI.sol';
import '@dievardump-web3/niftyforge/contracts/Modules/INFModuleWithRoyalties.sol';
import '@dievardump-web3/niftyforge/contracts/INiftyForge721.sol';

import '@dievardump-web3/signed-allowances/contracts/SignedAllowance.sol';

import './utils/Randomize.sol';
import './utils/StringHelpers.sol';

import './Renderer/ISuperglyphsRenderer.sol';

/// @title Superglyphs
/// @author Simon Fremaux (@dievardump)
contract Superglyphs is
    Ownable,
    NFBaseModule,
    INFModuleTokenURI,
    INFModuleWithRoyalties,
    SignedAllowance
{
    // withdraw
    error WithdrawError();

    // auth
    error NotAuthorized();

    // custom / freeze
    error InvalidName();
    error NameAlreadyUsed();
    error WrongCharacter();
    error AlreadyFrozen();
    error OnlyForCustom();
    error CollabSplitterFactoryNotSet();

    // claim
    error WrongParameters();
    error WrongLength();

    error NotOnMainnet();

    event TokenChanged(uint256 tokenId);

    struct TokenMeta {
        bytes16 colors;
        bytes16 symbols;
        address royaltiesSplit;
        string name;
    }

    /// @notice contract on which nfts are created
    address public nftContract;

    /// @notice contract used to do the rendering
    address public renderer;

    /// @notice contract used to extend the list of symbols available
    address public symbolExtension;

    /// @notice collab splitter factory for when people freeze updates
    address public collabSplitterFactory;

    /// @notice token metadata
    mapping(uint256 => TokenMeta) public tokenMetas;

    /// @notice list of already used names
    mapping(bytes32 => bool) private usedNames;

    constructor(
        string memory contractURI_,
        address renderer_,
        address owner_,
        address collabSplitterFactory_,
        address signer
    ) NFBaseModule(contractURI_) {
        renderer = renderer_;

        if (signer != address(0)) {
            _setAllowancesSigner(signer);
        }

        if (collabSplitterFactory_ != address(0)) {
            collabSplitterFactory = collabSplitterFactory_;
        }

        if (owner_ != address(0)) {
            transferOwnership(owner_);
        }
    }

    modifier approvedAndNotFrozen(address operator, uint256 tokenId) {
        if (!isApprovedOrOwner(operator, tokenId)) {
            revert NotAuthorized();
        }
        if (tokenMetas[tokenId].royaltiesSplit != address(0)) {
            revert AlreadyFrozen();
        }
        _;
    }

    /// @dev Receive, for royalties
    receive() external payable {}

    ////////////////////////////////////////////////////
    ///// Module                                      //
    ////////////////////////////////////////////////////

    /// @inheritdoc	INFModule
    function onAttach()
        external
        virtual
        override(INFModule, NFBaseModule)
        returns (bool)
    {
        if (nftContract == address(0)) {
            nftContract = msg.sender;
            return true;
        }

        // only allows attachment if nftContract if not set
        return false;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(INFModuleTokenURI).interfaceId ||
            interfaceId == type(INFModuleWithRoyalties).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /// @inheritdoc	INFModuleWithRoyalties
    function royaltyInfo(uint256 tokenId)
        public
        view
        override
        returns (address, uint256)
    {
        return royaltyInfo(address(0), tokenId);
    }

    /// @inheritdoc	INFModuleWithRoyalties
    function royaltyInfo(address, uint256 tokenId)
        public
        view
        override
        returns (address receiver, uint256 basisPoint)
    {
        TokenMeta memory tokenMeta = tokenMetas[tokenId];

        // if the token has a royaltiesSplit address, it's a frozen token
        // and the person who froze it is as much its creator as I am
        // so any royalties will be splitted, using a royalties split contract
        // see https://collab-splitter.org
        if (tokenMeta.royaltiesSplit != address(0)) {
            receiver = tokenMeta.royaltiesSplit;
        } else {
            receiver = address(this);
        }

        // 8% royalties
        basisPoint = 800;
    }

    /// @inheritdoc	INFModuleTokenURI
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        return tokenURI(address(0), tokenId);
    }

    /// @inheritdoc	INFModuleTokenURI
    function tokenURI(address, uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        TokenMeta memory tokenMeta = tokenMetas[tokenId];

        uint256 autoColorSeed = tokenMeta.colors != 0
            ? 0
            : getAutoColorSeed(tokenId, IERC721(nftContract).ownerOf(tokenId));

        return
            renderWith(
                _getName(tokenMeta.name),
                tokenId,
                autoColorSeed,
                tokenMeta.colors,
                tokenMeta.symbols,
                tokenMeta.royaltiesSplit != address(0)
            );
    }

    ////////////////////////////////////////////////////
    ///// Getters / Views                             //
    ////////////////////////////////////////////////////

    /// @notice helper to know if a name can be used
    /// @param newName the name to check
    /// @return if the name can be used
    function canUseName(string memory newName) external view returns (bool) {
        if (bytes(newName).length == 0) return true;

        bytes32 slugBytes = keccak256(bytes(StringHelpers.slugify(newName)));
        return (StringHelpers.isNameValid(newName) && !usedNames[slugBytes]);
    }

    /// @notice returns a token name
    /// @param tokenId the token id
    /// @return the token name
    function getName(uint256 tokenId) external view returns (string memory) {
        return _getName(tokenMetas[tokenId].name);
    }

    /// @notice generates the color seed for a tokenId and its owner
    ///         non customised tokens have colors bound to the current owner
    ///         if the owner changes, the colors change
    /// @param tokenId the token id
    /// @param owner_ the owner address
    /// @return the auto generated color seed
    function getAutoColorSeed(uint256 tokenId, address owner_)
        public
        pure
        returns (uint256)
    {
        return uint256(keccak256(abi.encode(tokenId, owner_)));
    }

    /// @notice renders with given parameters
    /// @param tokenName the name
    /// @param tokenId thhe token id (and seed)
    /// @param colorSeed the seed to use for colors (if not selected before)
    /// @param selectedColors the selected colors
    /// @param selectedSymbols the selected symbols
    /// @param frozen if the token is frozen
    /// @return the json for the token
    function renderWith(
        string memory tokenName,
        uint256 tokenId,
        uint256 colorSeed,
        bytes16 selectedColors,
        bytes16 selectedSymbols,
        bool frozen
    ) public view returns (string memory) {
        return
            ISuperglyphsRenderer(renderer).render(
                tokenName,
                tokenId,
                colorSeed,
                selectedColors,
                selectedSymbols,
                frozen
            );
    }

    /// @notice Gets a symbol from the "symbolExtension"
    /// @param symbolId the symbolId not already existing in renderer
    /// @param random the current randomizer
    /// @return the symbol (empty if not existing)
    function getSymbol(uint256 symbolId, Randomize.Random memory random)
        public
        view
        returns (bytes memory)
    {
        address extension = symbolExtension;
        if (extension != address(0)) {
            return ISymbolExtension(extension).getSymbol(symbolId, random);
        }

        return bytes('');
    }

    /// @notice helper to know if operator is owner or approvedForAll on a token
    /// @param operator the current operator
    /// @param tokenId the tokenId
    /// @return true if operator is owner or approved on the token else false
    function isApprovedOrOwner(address operator, uint256 tokenId)
        public
        view
        returns (bool)
    {
        address nftContract_ = nftContract;
        address owner_ = IERC721(nftContract_).ownerOf(tokenId);
        return (owner_ == operator ||
            IERC721(nftContract_).isApprovedForAll(owner_, operator));
    }

    ////////////////////////////////////////////////////
    ///// Collectors                                  //
    ////////////////////////////////////////////////////

    /// @notice Claiming function
    /// @param recipient the recipient address (the one that did the migration)
    /// @param allocation for the claim (can be 1 or 2 since there are 2 collections that were migrated)
    /// @param signature for the claim
    function claim(
        address recipient,
        uint256 allocation,
        bytes memory signature
    ) public {
        if (allocation == 0 || allocation > 2) {
            revert WrongParameters();
        }

        _useAllowance(recipient, allocation, signature);

        _mint(recipient, allocation);
    }

    /// @notice allows an owner to freeze the Superglyph forever in its curent state
    ///         and become 50% secondary sales royalties recipient for this token, forever
    ///         The owner at the time this function is called will be the recipient
    /// @param tokenId the token id
    function freeze(uint256 tokenId)
        external
        approvedAndNotFrozen(msg.sender, tokenId)
    {
        address collabSplitterFactory_ = collabSplitterFactory;
        if (address(0) == collabSplitterFactory_) {
            revert CollabSplitterFactoryNotSet();
        }

        TokenMeta memory meta = tokenMetas[tokenId];

        // need to be fully customized
        if (
            bytes(meta.name).length == 0 ||
            meta.colors == 0 ||
            meta.symbols == 0
        ) {
            revert OnlyForCustom();
        }

        // this creates what is called a CollabSplitter that will be the new RoyaltiesRecipient
        // and will allow to share the royalties between dievardump and the user who freezes their Superglyph
        // https://collab-splitter.org
        address recipient = IERC721(nftContract).ownerOf(tokenId);
        address self = address(this);

        bytes32 leftNode = keccak256(abi.encode(recipient, 5000));
        bytes32 rightNode = keccak256(abi.encode(self, 5000));

        // because of how OZ MerkleTree implementation is done
        if (leftNode > rightNode) {
            (leftNode, rightNode) = (rightNode, leftNode);
        }

        // calculate root with only 2 nodes.
        bytes32 root = keccak256(abi.encodePacked(leftNode, rightNode));

        address[] memory recipients = new address[](2);
        recipients[0] = recipient;
        recipients[1] = self;

        // divide royalties 50/50
        uint256[] memory allocations = new uint256[](2);
        allocations[0] = 5000;
        allocations[1] = 5000;

        // create collabSplitter and associate it with the token
        tokenMetas[tokenId].royaltiesSplit = ICollabSplitterFactory(
            collabSplitterFactory_
        ).createSplitter(
                string(abi.encodePacked('Superglyphs Splitter - ', meta.name)),
                root,
                recipients,
                allocations
            );
    }

    /// @notice allows an owner to customize their NFT all at once
    /// @param tokenId the token id
    /// @param name the custom name
    /// @param selectedColors the selected colors
    /// @param selectedSymbols the selected symbols
    function customize(
        uint256 tokenId,
        string memory name,
        bytes16 selectedColors,
        bytes16 selectedSymbols
    ) external approvedAndNotFrozen(msg.sender, tokenId) {
        if (selectedColors != 0) {
            _validateColors(selectedColors);
        }

        if (
            keccak256(abi.encodePacked(tokenMetas[tokenId].name)) !=
            keccak256(abi.encodePacked(name))
        ) {
            _setName(tokenId, name);
        }

        tokenMetas[tokenId].colors = selectedColors;
        tokenMetas[tokenId].symbols = selectedSymbols;

        emit TokenChanged(tokenId);
    }

    /// @notice Colors setters for a token
    /// @param tokenId the token Id to set the colors for
    /// @param selectedColors the seclected colors, in 16bytes
    function setColors(uint256 tokenId, bytes16 selectedColors)
        external
        approvedAndNotFrozen(msg.sender, tokenId)
    {
        _validateColors(selectedColors);
        tokenMetas[tokenId].colors = selectedColors;
        emit TokenChanged(tokenId);
    }

    /// @notice Symbols setters for a token
    /// @param tokenId the token Id to set the colors for
    /// @param selectedSymbols the seclected symbols, in 16bytes
    function setSymbols(uint256 tokenId, bytes16 selectedSymbols)
        external
        approvedAndNotFrozen(msg.sender, tokenId)
    {
        tokenMetas[tokenId].symbols = selectedSymbols;
        emit TokenChanged(tokenId);
    }

    /// @notice Function allowing an owner (or Approved) to set a token name
    ///         User needs to be extra careful. Some characters might completly break the token.
    ///         Since the metadata are generated in the contract.
    ///         if this ever happens, you can simply reset the name to nothing or for something else
    /// @dev sender must be tokenId owner
    /// @param tokenId the token to name
    /// @param newName the name
    function setName(uint256 tokenId, string memory newName)
        external
        approvedAndNotFrozen(msg.sender, tokenId)
    {
        _setName(tokenId, newName);
        emit TokenChanged(tokenId);
    }

    ////////////////////////////////////////////////////
    ///// Contract Owner                              //
    ////////////////////////////////////////////////////

    /// @dev Owner withdraw balance function
    function withdraw() external onlyOwner {
        address owner_ = owner();
        (bool success, ) = owner_.call{value: address(this).balance}('');
        if (!success) revert WithdrawError();
    }

    /// @notice sets contract uri
    /// @param newURI the new uri
    function setContractURI(string memory newURI) external onlyOwner {
        _setContractURI(newURI);
    }

    /// @notice sets the collab splitter factory
    /// @param newCollabSplitterFactory the new collab splitter address
    function setCollabSplitterFactory(address newCollabSplitterFactory)
        external
        onlyOwner
    {
        collabSplitterFactory = newCollabSplitterFactory;
    }

    /// @notice Allows to later add an extension to the current symbols
    /// @param extension the address of the extension
    function setSymbolExtension(address extension) public onlyOwner {
        symbolExtension = extension;
    }

    /// @notice Allows to update the renderer contract
    /// @param newRenderer the new renderer address
    function setRenderer(address newRenderer) public onlyOwner {
        renderer = newRenderer;
    }

    ////////////////////////////////////////////////////
    ///// Internal                                    //
    ////////////////////////////////////////////////////

    function _mint(address recipient, uint256 howMany) internal {
        // start seed with values linked to this tx
        bytes32 seed = keccak256(
            abi.encodePacked(
                block.timestamp,
                msg.sender,
                block.coinbase,
                block.difficulty,
                tx.gasprice,
                recipient,
                howMany
            )
        );

        address nftContract_ = nftContract;
        uint256 lastTokenId = INiftyForge721Extended(nftContract_)
            .lastTokenId();

        for (uint256 i; i < howMany; i++) {
            // then play with the allocation id
            seed = keccak256(abi.encode(i, seed, lastTokenId + i + 1));

            // the seed is the token id
            INiftyForge721(nftContract_).mint(
                recipient,
                '',
                uint256(seed),
                address(0),
                0,
                address(0)
            );
        }
    }

    function _getName(string memory name_)
        internal
        pure
        returns (string memory)
    {
        return bytes(name_).length > 0 ? name_ : 'Superglyph';
    }

    /// @dev Validate colors
    /// @param selectedColors the colors in one string (ex: #ffffff#000000)
    function _validateColors(bytes16 selectedColors) internal pure {
        uint256 temp;
        for (uint256 i; i < selectedColors.length; i++) {
            if (i == 14 || i == 15) {
                if (selectedColors[i] != 0) {
                    revert WrongCharacter();
                }
            } else if (i == 0 || i == 7) {
                if (selectedColors[i] != 0x23) {
                    revert WrongCharacter();
                }
            } else {
                temp = uint8(selectedColors[i]);
                if (
                    !(temp >= 97 && temp <= 102) && // a - f
                    !(temp >= 65 && temp <= 70) && // A - F
                    !(temp >= 48 && temp <= 57) // 0 - 9
                ) {
                    revert WrongCharacter();
                }
            }
        }
    }

    /// @dev allows to set a name internally.
    ///      checks that the name is valid and not used, else throws
    /// @param tokenId the token to name
    /// @param newName the name
    function _setName(uint256 tokenId, string memory newName) internal {
        bytes32 slugBytes;

        // if the name is not empty, require that it's valid and not used
        if (bytes(newName).length > 0) {
            if (!StringHelpers.isNameValid(newName)) revert InvalidName();

            // also requires the name is not already used
            slugBytes = keccak256(bytes(StringHelpers.slugify(newName)));
            if (usedNames[slugBytes]) revert NameAlreadyUsed();

            // set as used
            usedNames[slugBytes] = true;
        }

        // if it already has a name, mark the old name as unused
        string memory oldName = tokenMetas[tokenId].name;
        if (bytes(oldName).length > 0) {
            slugBytes = keccak256(bytes(StringHelpers.slugify(oldName)));
            usedNames[slugBytes] = false;
        }

        tokenMetas[tokenId].name = newName;
    }
}

interface ICollabSplitterFactory {
    function createSplitter(
        string memory name_,
        bytes32 merkleRoot,
        address[] memory recipients,
        uint256[] memory amounts
    ) external payable returns (address newContract);
}

interface INiftyForge721Extended {
    function lastTokenId() external view returns (uint256);
}

interface ISymbolExtension {
    function getSymbol(uint256 symbolId, Randomize.Random memory random)
        external
        pure
        returns (bytes memory);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// small library to randomize using (min, max, seed)
// all number returned are considered with 3 decimals
library Randomize {
    struct Random {
        uint256 seed;
    }

    /// @notice This function uses seed to return a pseudo random interger between [min and max[
    /// @param random the random seed
    /// @return the pseudo random number
    function next(Random memory random, uint256 min, uint256 max) internal pure returns (uint256) {
        random.seed ^= random.seed << 13;
        random.seed ^= random.seed >> 17;
        random.seed ^= random.seed << 5;
        return min + random.seed % (max - min);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// small helpers for strings
library StringHelpers {
    /// @notice Checks if the string is valid (0-9a-zA-Z,- ) with no leading, trailing or consecutives spaces
    ///         This function is a modified version of the one in the Hashmasks contract
    /// @param str the name to validate
    /// @return if the name is valid
    function isNameValid(string memory str) internal pure returns (bool) {
        bytes memory strBytes = bytes(str);
        if (strBytes.length < 1) return false;
        if (strBytes.length > 32) return false; // Cannot be longer than 32 characters

        uint8 charCode;
        for (uint256 i; i < strBytes.length; i++) {
            charCode = uint8(strBytes[i]);

            if (
                !(charCode >= 97 && charCode <= 122) && // a - z
                !(charCode >= 65 && charCode <= 90) && // A - Z
                !(charCode >= 48 && charCode <= 57) // 0 - 9
            ) {
                return false;
            }
        }

        return true;
    }

    /// @notice Slugify a name (tolower and replace all non 0-9az by -)
    /// @param str the string to keyIfy
    /// @return the key
    function slugify(string memory str) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory lowerCase = new bytes(strBytes.length);
        uint8 charCode;
        bytes1 char;
        for (uint256 i; i < strBytes.length; i++) {
            char = strBytes[i];
            charCode = uint8(char);

            // if 0-9, a-z use the character
            if (
                (charCode >= 48 && charCode <= 57) ||
                (charCode >= 97 && charCode <= 122)
            ) {
                lowerCase[i] = char;
            } else if (charCode >= 65 && charCode <= 90) {
                // if A-Z, use lowercase
                lowerCase[i] = bytes1(charCode + 32);
            } else {
                // for all others, use a -
                lowerCase[i] = 0x2D;
            }
        }

        return string(lowerCase);
    }
}