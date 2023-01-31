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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnershipTransferred(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnershipTransferred(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function transferOwnership(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnershipTransferred(msg.sender, newOwner);
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private locked = 1;

    modifier nonReentrant() virtual {
        require(locked == 1, "REENTRANCY");

        locked = 2;

        _;

        locked = 1;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface IETHReceiverChild {
    function forwardFundsETH() external;
    function flipContractActive() external;
    function setMintToken(uint _mintToken) external returns (bool);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;
/// @title ERC1155 Advanced Contract
/// @author Mr. Millipede
/// @notice This contract is feature rich and is meant to be deployed by experienced developers.

import "solmate/auth/Owned.sol";
import "solmate/tokens/ERC1155.sol";
import "solmate/utils/ReentrancyGuard.sol";
import "openzeppelin-contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/token/ERC721/IERC721.sol";
import "openzeppelin-contracts/token/ERC721/IERC721Receiver.sol";
import "openzeppelin-contracts/token/ERC1155/IERC1155.sol";
import "openzeppelin-contracts/token/ERC1155/IERC1155Receiver.sol";
import "../../interfaces/IETHReceiverChild.sol";
import "../../utils/ETHReceiverChild.sol";

/// @title GAN Marketplace Contract
/// @author Mr. Millipede
contract ERC1155Advanced is ERC1155, Owned, ReentrancyGuard {

    string public name;
    string public symbol;

    ETHReceiverChild[] public ethReceiverChildren;

    mapping (uint => string) private tokenURIs;

    mapping (uint => uint) public tokenCostETH;
    mapping (uint => uint) public tokenMaxSupply;
    mapping (uint => uint) public tokenCurrentSupply;
    mapping (uint => uint) public tokenMaxPerWallet;
    mapping (uint => bool) public tokenMintActive;
    mapping (uint => mapping (address => bool)) public tokenApprovedCurrencyERC20;
    mapping (uint => mapping (address => uint)) public tokenApprovedCurrencyERC20Amount;
    mapping (uint => mapping (address => bool)) public tokenApprovedCurrencyERC721;
    mapping (uint => mapping (address => uint)) public tokenApprovedCurrencyERC721Amount;
    mapping (uint => mapping (address => bool)) public tokenApprovedCurrencyERC1155;
    mapping (uint => mapping (address => uint)) public tokenApprovedCurrencyERC1155Amount;
    mapping (address => mapping (uint => uint)) public tokenMintsByReceiverByToken;
    mapping (address => bool) public proxyAddresses;
    mapping (address => uint) public proxyAddressToTokenId;
    
    /*//////////////////////////////////////////////////////////////
                             EVENTS
    //////////////////////////////////////////////////////////////*/

    event URIUpdated(string value, uint indexed id);
    event MintSingleNoLimits(address indexed tokenReceiver, uint indexed id, uint indexed amount);
    event MintSingleMaxSupply(address indexed tokenReceiver, uint indexed id, uint indexed amount);
    event MintSingleMaxSupplyMaxPerWallet(address indexed tokenReceiver, uint indexed id, uint indexed amount);
    event ProxyPaymentReceived(address indexed forwarderAddress, uint indexed amount); 

    /*//////////////////////////////////////////////////////////////
                             CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory setName,
        string memory setSymbol,
        address setOwner
    )Owned(setOwner){
        name = setName;
        symbol = setSymbol;
    }

    /*//////////////////////////////////////////////////////////////
                             MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /// @notice This modifier is used to check if the caller of a function is an approved operator.
    
    modifier proxyOpperatorApproval() {
        require(proxyAddresses[msg.sender], "You are not an approved operator.");
        _;
    }

    
    /// @notice Modifier used to check if the token amount is mintable by the caller of the function.
    /// @param id The id of the token to be minted.
    /// @param amount The amount of the token to be minted.
    /// @dev If the token has not been asigned a max supply then the token amount is mintable.
    /// @dev If the token has not been asign a max per wallet then the token amount is mintable.

    modifier tokenNumericLimits(uint id, uint amount) {
        if (tokenMaxSupply[id] > 0) {
            require(tokenCurrentSupply[id] + amount <= tokenMaxSupply[id], "This token has reached its max supply.");
        }
        if (tokenMaxPerWallet[id] > 0) {
            require(tokenMintsByReceiverByToken[msg.sender][id] + amount <= tokenMaxPerWallet[id], "You have reached your max mints for this token.");
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////
                             UTILITIES
    //////////////////////////////////////////////////////////////*/

    function _postMintNumericAdjustments(address mintReceiver, uint id, uint amount) internal {
        tokenCurrentSupply[id] += amount;
        tokenMintsByReceiverByToken[mintReceiver][id] += amount;
    }

    function _postBurnNumericAdjustments(address burnReceiver, uint id, uint amount) internal {
        tokenCurrentSupply[id] -= amount;
        tokenMintsByReceiverByToken[burnReceiver][id] -= amount;
    }

    /*//////////////////////////////////////////////////////////////
                             MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function mintCurrencyERC20(address paymentCurrency, uint mintTokenId, uint mintTokenAmount) external tokenNumericLimits(mintTokenId, mintTokenAmount) {
        require(tokenApprovedCurrencyERC20[mintTokenId][paymentCurrency], "This currency is not approved for this token.");
        uint paymentCurrencyAmount = tokenApprovedCurrencyERC20Amount[mintTokenId][paymentCurrency] * mintTokenAmount;
        IERC20(paymentCurrency).transferFrom(msg.sender, address(this), paymentCurrencyAmount);
        _mint(msg.sender, mintTokenId, mintTokenAmount, "");
        _postMintNumericAdjustments(msg.sender, mintTokenId, mintTokenAmount);
    }

    /// @dev This function needs to implement safeTransferFrom

    function mintCurrencyERC721(address paymentCurrency, uint[] memory paymentTokenIds, uint mintTokenId, uint mintTokenAmount) external tokenNumericLimits(mintTokenId, mintTokenAmount) {
        require(tokenApprovedCurrencyERC721[mintTokenId][paymentCurrency], "This currency is not approved for this token.");
        require(paymentTokenIds.length == tokenApprovedCurrencyERC721Amount[mintTokenId][paymentCurrency] * mintTokenAmount, "You have not sent the correct amount of payment tokens.");
        for (uint i = 0; i < paymentTokenIds.length; i++) {
            IERC721(paymentCurrency).safeTransferFrom(msg.sender, address(this), paymentTokenIds[i]);
        }
        _mint(msg.sender, mintTokenId, mintTokenAmount, "");
        _postMintNumericAdjustments(msg.sender, mintTokenId, mintTokenAmount);
    }

    /// @dev This function needs to implement safeBatchTransferFrom

    function mintCurrencyERC1155(address paymentCurrency, uint[] memory paymentTokenIds, uint[] memory paymentTokenAmounts, uint mintTokenId, uint mintTokenAmount) external tokenNumericLimits(mintTokenId, mintTokenAmount) {
        require(tokenApprovedCurrencyERC1155[mintTokenId][paymentCurrency], "This currency is not approved for this token.");
        require(paymentTokenIds.length == tokenApprovedCurrencyERC1155Amount[mintTokenId][paymentCurrency] * mintTokenAmount, "You have not sent the correct amount of payment tokens.");
        IERC1155(paymentCurrency).safeBatchTransferFrom(msg.sender, address(this), paymentTokenIds, paymentTokenAmounts, "");
        _mint(msg.sender, mintTokenId, mintTokenAmount, "");
        _postMintNumericAdjustments(msg.sender, mintTokenId, mintTokenAmount);
    }

    /*//////////////////////////////////////////////////////////////
                             PROXY LOGIC
    //////////////////////////////////////////////////////////////*/

    function proxyMint(address to, uint id, uint amount, bytes memory data) public proxyOpperatorApproval {
        _mint(to, id, amount, data);
        _postMintNumericAdjustments(to, id, amount);
    }

    function proxyBatchMint(address to, uint[] memory ids, uint[] memory amounts, bytes memory data) public proxyOpperatorApproval {
        _batchMint(to, ids, amounts, data);
        for (uint i = 0; i < ids.length; i++) {
            _postMintNumericAdjustments(to, ids[i], amounts[i]);
        }
    }

    function proxyBurnSingle(address tokenOwner, uint id, uint amount) external proxyOpperatorApproval {
        _burn(tokenOwner, id, amount);
        _postBurnNumericAdjustments(tokenOwner, id, amount);
    }

    function proxyBurnBatch(address tokenOwner, uint[] calldata ids, uint[] calldata amounts) external proxyOpperatorApproval {
        _batchBurn(tokenOwner, ids, amounts);
        for (uint i = 0; i < ids.length; i++) {
            _postBurnNumericAdjustments(tokenOwner, ids[i], amounts[i]);
        }
    }

    /*//////////////////////////////////////////////////////////////
                        CHILD DEPLOYMENT LOGIC
    //////////////////////////////////////////////////////////////*/

    function deployETHReceiverChildContract(uint mintToken) external onlyOwner {
        ETHReceiverChild ethReceiverChild = new ETHReceiverChild(address(this), mintToken);
        ethReceiverChildren.push(ethReceiverChild);
        proxyAddressToTokenId[address(ethReceiverChild)] = mintToken;
    }

    /*//////////////////////////////////////////////////////////////
                            RECEIVE LOGIC
    //////////////////////////////////////////////////////////////*/

    receive() external payable {
        require(proxyAddresses[msg.sender], "We are not expecting payment from you.");
        emit ProxyPaymentReceived(msg.sender, msg.value);
    }

    /*//////////////////////////////////////////////////////////////
                             METADATA LOGIC
    //////////////////////////////////////////////////////////////*/

    function uri(uint id) public view override returns (string memory) {
        return tokenURIs[id];
    }

    /*//////////////////////////////////////////////////////////////
                    CORE VARIABLE UPDATE LOGIC
    //////////////////////////////////////////////////////////////*/
    

    function updateTokenURI(uint tokenID, string calldata newURI) external onlyOwner {
        tokenURIs[tokenID] = newURI;
        emit URIUpdated(newURI, tokenID);
    }

    function updateTokenCostETH(uint tokenID, uint newCost) external onlyOwner {
        tokenCostETH[tokenID] = newCost;
    }

    function updateTokenMaxSupply(uint tokenID, uint newMaxSupply) external onlyOwner {
        tokenMaxSupply[tokenID] = newMaxSupply;
    }

    function updateTokenMaxPerWallet(uint tokenID, uint newMaxPerWallet) external onlyOwner {
        tokenMaxPerWallet[tokenID] = newMaxPerWallet;
    }

    function updateTokenApprovedCurrencyERC20(uint tokenID, address currencyAddress) external onlyOwner {
        tokenApprovedCurrencyERC20[tokenID][currencyAddress] = !tokenApprovedCurrencyERC20[tokenID][currencyAddress];
    }

    function updateTokenApprovedCurrencyERC20Amount(uint tokenID, address currencyAddress, uint newAmount) external onlyOwner {
        tokenApprovedCurrencyERC20Amount[tokenID][currencyAddress] = newAmount;
    }

    function updateTokenApprovedCurrencyERC721(uint tokenID, address currencyAddress) external onlyOwner {
        tokenApprovedCurrencyERC721[tokenID][currencyAddress] = !tokenApprovedCurrencyERC721[tokenID][currencyAddress];
    }

    function updateTokenApprovedCurrencyERC721Amount(uint tokenID, address currencyAddress, uint newAmount) external onlyOwner {
        tokenApprovedCurrencyERC721Amount[tokenID][currencyAddress] = newAmount;
    }

    function updateTokenApprovedCurrencyERC1155(uint tokenID, address currencyAddress) external onlyOwner {
        tokenApprovedCurrencyERC1155[tokenID][currencyAddress] = !tokenApprovedCurrencyERC1155[tokenID][currencyAddress];
    }

    function updateTokenApprovedCurrencyERC1155Amount(uint tokenID, address currencyAddress, uint newAmount) external onlyOwner {
        tokenApprovedCurrencyERC1155Amount[tokenID][currencyAddress] = newAmount;
    }

    function flipProxyAddressActive(address proxyAddress) external onlyOwner {
        proxyAddresses[proxyAddress] = !proxyAddresses[proxyAddress];
    }

    /*//////////////////////////////////////////////////////////////
                     CHILD VARIABLE UPDATE LOGIC
    //////////////////////////////////////////////////////////////*/

    function updateChildMintToken(address childAddress, uint id) external onlyOwner {
        IETHReceiverChild(childAddress).setMintToken(id);
    }

    function updateChildContractActive(address childAddress) external onlyOwner {
        IETHReceiverChild(childAddress).flipContractActive();
    }

    /*//////////////////////////////////////////////////////////////
                        CHILD WITHDRAW LOGIC
    //////////////////////////////////////////////////////////////*/

    function forwardChildFundsETH(address childAddress) external onlyOwner {
        IETHReceiverChild(childAddress).forwardFundsETH();
    }

    /*//////////////////////////////////////////////////////////////
                        CORE WITHDRAW LOGIC
    //////////////////////////////////////////////////////////////*/

    function withdrawETH() external onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function withdrawERC20(address tokenAddress) external onlyOwner {
        IERC20(tokenAddress).transfer(msg.sender, IERC20(tokenAddress).balanceOf(address(this)));
    }

    function withdrawERC721(address tokenAddress, uint tokenID) external onlyOwner {
        IERC721(tokenAddress).transferFrom(address(this), msg.sender, tokenID);
    }

    function withdrawERC1155(address tokenAddress, uint tokenID, uint amount) external onlyOwner {
        IERC1155(tokenAddress).safeTransferFrom(address(this), msg.sender, tokenID, amount, "");
    }

}

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

contract ETHReceiverChild {
    
    address public parent;
    uint public mintToken;

    constructor(address _parent, uint _mintToken) {
        parent = _parent;
        mintToken = _mintToken;
    }
    
    receive() external payable {
        
    }
}