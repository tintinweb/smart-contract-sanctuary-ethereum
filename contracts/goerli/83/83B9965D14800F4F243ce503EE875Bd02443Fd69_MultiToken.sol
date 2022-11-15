// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/interfaces/IERC20.sol';
import '@openzeppelin/contracts/interfaces/IERC721.sol';
import '@openzeppelin/contracts/interfaces/IERC1155.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol';

contract MultiToken {
    /**
     * @title Category
     * @dev enum representation Asset category
     */
    enum Category {
        ERC20,
        ERC721,
        ERC1155
    }

    /**
     * @title Asset
     * @param category Corresponding asset category
     * @param assetAddress Address of the token contract defining the asset
     * @param id TokenID of an NFT or 0
     * @param amount Amount of fungible tokens or 0 -> 1
     */
    struct Asset {
        Category category;
        address assetAddress;
        uint256 id;
        uint256 amount;
    }

    /*----------------------------------------------------------*|
    |*  # TRANSFER ASSET                                        *|
    |*----------------------------------------------------------*/

    /**
     * transferAsset
     * @dev wrapping function for transfer calls on various token interfaces
     * @param _asset Struct defining all necessary context of a token
     * @param _dest Destination address
     */
    function transferAsset(Asset memory _asset, address _dest) internal {
        _transferAssetFrom(_asset, address(this), _dest);
    }

    /**
     * transferAssetFrom
     * @dev wrapping function for transferFrom calls on various token interfaces
     * @param _asset Struct defining all necessary context of a token
     * @param _source Account/address that provided the allowance
     * @param _dest Destination address
     */
    function transferAssetFrom(
        Asset memory _asset,
        address _source,
        address _dest
    ) internal {
        _transferAssetFrom(_asset, _source, _dest);
    }

    function _transferAssetFrom(
        Asset memory _asset,
        address _source,
        address _dest
    ) private {
        if (_asset.category == Category.ERC20) {
            if (_source == address(this))
                require(
                    IERC20(_asset.assetAddress).transfer(_dest, _asset.amount),
                    'MultiToken: ERC20 transfer failed'
                );
            else
                require(
                    IERC20(_asset.assetAddress).transferFrom(
                        _source,
                        _dest,
                        _asset.amount
                    ),
                    'MultiToken: ERC20 transferFrom failed'
                );
        } else if (_asset.category == Category.ERC721) {
            IERC721(_asset.assetAddress).safeTransferFrom(
                _source,
                _dest,
                _asset.id
            );
        } else if (_asset.category == Category.ERC1155) {
            IERC1155(_asset.assetAddress).safeTransferFrom(
                _source,
                _dest,
                _asset.id,
                _asset.amount == 0 ? 1 : _asset.amount,
                ''
            );
        } else {
            revert('MultiToken: Unsupported category');
        }
    }

    /*----------------------------------------------------------*|
    |*  # TRANSFER ASSET CALLDATA                               *|
    |*----------------------------------------------------------*/

    /**
     * transferAssetCalldata
     * @dev wrapping function for transfer calldata on various token interfaces
     * @param _asset Struct defining all necessary context of a token
     * @param _source Account/address that should initiate the transfer
     * @param _dest Destination address
     */
    function transferAssetCalldata(
        Asset memory _asset,
        address _source,
        address _dest
    ) internal pure returns (bytes memory) {
        return _transferAssetFromCalldata(true, _asset, _source, _dest);
    }

    /**
     * transferAssetFromCalldata
     * @dev wrapping function for transferFrom calladata on various token interfaces
     * @param _asset Struct defining all necessary context of a token
     * @param _source Account/address that provided the allowance
     * @param _dest Destination address
     */
    function transferAssetFromCalldata(
        Asset memory _asset,
        address _source,
        address _dest
    ) internal pure returns (bytes memory) {
        return _transferAssetFromCalldata(false, _asset, _source, _dest);
    }

    function _transferAssetFromCalldata(
        bool fromSender,
        Asset memory _asset,
        address _source,
        address _dest
    ) private pure returns (bytes memory) {
        if (_asset.category == Category.ERC20) {
            if (fromSender) {
                return
                    abi.encodeWithSelector(
                        IERC20.transfer.selector,
                        _dest,
                        _asset.amount
                    );
            } else {
                return
                    abi.encodeWithSelector(
                        IERC20.transferFrom.selector,
                        _source,
                        _dest,
                        _asset.amount
                    );
            }
        } else if (_asset.category == Category.ERC721) {
            return
                abi.encodeWithSignature(
                    'safeTransferFrom(address,address,uint256)',
                    _source,
                    _dest,
                    _asset.id
                );
        } else if (_asset.category == Category.ERC1155) {
            return
                abi.encodeWithSelector(
                    IERC1155.safeTransferFrom.selector,
                    _source,
                    _dest,
                    _asset.id,
                    _asset.amount == 0 ? 1 : _asset.amount,
                    ''
                );
        } else {
            revert('MultiToken: Unsupported category');
        }
    }

    /*----------------------------------------------------------*|
    |*  # PERMIT                                                *|
    |*----------------------------------------------------------*/

    /**
     * permit
     * @dev wrapping function for granting approval via permit signature
     * @param _asset Struct defining all necessary context of a token
     * @param _owner Account/address that signed the permit
     * @param _spender Account/address that would be granted approval to `_asset`
     * @param _permit Data about permit deadline (uint256) and permit signature (64/65 bytes).
     * Deadline and signature should be pack encoded together.
     * Signature can be standard (65 bytes) or compact (64 bytes) defined in EIP-2098.
     */
    function permit(
        Asset memory _asset,
        address _owner,
        address _spender,
        bytes memory _permit
    ) internal {
        if (_asset.category == Category.ERC20) {
            // Parse deadline and permit signature parameters
            uint256 deadline;
            bytes32 r;
            bytes32 s;
            uint8 v;

            // Parsing signature parameters used from OpenZeppelins ECDSA library
            // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/83277ff916ac4f58fec072b8f28a252c1245c2f1/contracts/utils/cryptography/ECDSA.sol

            // Deadline (32 bytes) + standard signature data (65 bytes) -> 97 bytes
            if (_permit.length == 97) {
                assembly {
                    deadline := mload(add(_permit, 0x20))
                    r := mload(add(_permit, 0x40))
                    s := mload(add(_permit, 0x60))
                    v := byte(0, mload(add(_permit, 0x80)))
                }
            }
            // Deadline (32 bytes) + compact signature data (64 bytes) -> 96 bytes
            else if (_permit.length == 96) {
                bytes32 vs;

                assembly {
                    deadline := mload(add(_permit, 0x20))
                    r := mload(add(_permit, 0x40))
                    vs := mload(add(_permit, 0x60))
                }

                s =
                    vs &
                    bytes32(
                        0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
                    );
                v = uint8((uint256(vs) >> 255) + 27);
            } else {
                revert('MultiToken::Permit: Invalid permit length');
            }

            // Call permit with parsed parameters
            IERC20Permit(_asset.assetAddress).permit(
                _owner,
                _spender,
                _asset.amount,
                deadline,
                v,
                r,
                s
            );
        } else {
            // Currently supporting only ERC20 signed approvals via ERC2612
            revert('MultiToken::Permit: Unsupported category');
        }
    }

    /*----------------------------------------------------------*|
    |*  # BALANCE OF                                            *|
    |*----------------------------------------------------------*/

    /**
     * balanceOf
     * @dev wrapping function for checking balances on various token interfaces
     * @param _asset Struct defining all necessary context of a token
     * @param _target Target address to be checked
     */
    function balanceOf(Asset memory _asset, address _target)
        internal
        view
        returns (uint256)
    {
        if (_asset.category == Category.ERC20) {
            return IERC20(_asset.assetAddress).balanceOf(_target);
        } else if (_asset.category == Category.ERC721) {
            if (IERC721(_asset.assetAddress).ownerOf(_asset.id) == _target) {
                return 1;
            } else {
                return 0;
            }
        } else if (_asset.category == Category.ERC1155) {
            return IERC1155(_asset.assetAddress).balanceOf(_target, _asset.id);
        } else {
            revert('MultiToken: Unsupported category');
        }
    }

    /*----------------------------------------------------------*|
    |*  # APPROVE ASSET                                         *|
    |*----------------------------------------------------------*/

    /**
     * approveAsset
     * @dev wrapping function for approve calls on various token interfaces
     * @param _asset Struct defining all necessary context of a token
     * @param _target Account/address that would be granted approval to `_asset`
     */
    function approveAsset(Asset memory _asset, address _target) internal {
        if (_asset.category == Category.ERC20) {
            IERC20(_asset.assetAddress).approve(_target, _asset.amount);
        } else if (_asset.category == Category.ERC721) {
            IERC721(_asset.assetAddress).approve(_target, _asset.id);
        } else if (_asset.category == Category.ERC1155) {
            IERC1155(_asset.assetAddress).setApprovalForAll(_target, true);
        } else {
            revert('MultiToken: Unsupported category');
        }
    }

    /*----------------------------------------------------------*|
    |*  # ASSET CHECKS                                          *|
    |*----------------------------------------------------------*/

    /**
     * isValid
     * @dev checks that assets amount and id is valid in stated category
     * @dev this function don't check that stated category is indeed the category of a contract on a stated address
     * @param _asset Asset that is examined
     * @return True if assets amount and id is valid in stated category
     */
    function isValid(Asset memory _asset) internal pure returns (bool) {
        // ERC20 token has to have id set to 0
        if (_asset.category == Category.ERC20 && _asset.id != 0) return false;

        // ERC721 token has to have amount set to 1
        if (_asset.category == Category.ERC721 && _asset.amount != 1)
            return false;

        // Any categories have to have non-zero amount
        if (_asset.amount == 0) return false;

        return true;
    }

    /**
     * isSameAs
     * @dev compare two assets, ignoring their amounts
     * @param _asset First asset to examine
     * @param _otherAsset Second asset to examine
     * @return True if both structs represents the same asset
     */
    function isSameAs(Asset memory _asset, Asset memory _otherAsset)
        internal
        pure
        returns (bool)
    {
        return
            _asset.category == _otherAsset.category &&
            _asset.assetAddress == _otherAsset.assetAddress &&
            _asset.id == _otherAsset.id;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1155.sol)

pragma solidity ^0.8.0;

import "../token/ERC1155/IERC1155.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
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