// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

import "@dlsl/dev-modules/diamond/DiamondStorage.sol";

import "../libs/Commands.sol";
import "../libs/ErrorHelper.sol";
import "./MasterRouterStorage.sol";
import "../SwapDiamondStorage.sol";
import "../integration-facets/routers/BridgeRouter.sol";
import "../integration-facets/routers/TransferRouter.sol";
import "../integration-facets/routers/WrapRouter.sol";
import "../integration-facets/routers/MulticallRouter.sol";
import "../integration-facets/routers/UniswapV2Router.sol";
import "../integration-facets/routers/UniswapV3Router.sol";
import "../integration-facets/routers/TraderJoeRouter.sol";

contract MasterRouter is
    DiamondStorage,
    MasterRouterStorage,
    SwapDiamondStorage,
    ERC721Holder,
    ERC1155Holder
{
    using ErrorHelper for *;

    struct Payload {
        uint256 command;
        bool skipRevert;
        bytes data;
    }

    function make(Payload[] calldata payloads_) external payable onlyCaller {
        for (uint256 i = 0; i < payloads_.length; ++i) {
            _handle(payloads_[i]);
        }
    }

    function _handle(Payload calldata payload_) internal {
        bytes4 funcSelector_ = _getSelector(payload_.command);

        require(
            getSelectorType(funcSelector_) == SelectorType.MasterRouter,
            "MasterRouter: invalid command"
        );

        (bool ok_, bytes memory data_) = getFacetBySelector(funcSelector_).delegatecall(
            abi.encodePacked(funcSelector_, payload_.data)
        );

        require(ok_ || payload_.skipRevert, data_.toStringReason().wrap("MasterRouter"));
    }

    function _getSelector(uint256 command_) internal pure returns (bytes4 funcSelector_) {
        if (command_ < 10) {
            funcSelector_ = _getBridgeSelector(command_);
        } else if (command_ < 20) {
            funcSelector_ = _getTransferSelector(command_);
        } else if (command_ < 25) {
            funcSelector_ = _getWrapSelector(command_);
        } else if (command_ < 30) {
            funcSelector_ = _getMulticallSelector(command_);
        } else if (command_ < 60) {
            funcSelector_ = _getUniswapV2Selector(command_);
        } else if (command_ < 70) {
            funcSelector_ = _getUniswapV3Selector(command_);
        } else if (command_ < 80) {
            funcSelector_ = _getTraderJoeSelector(command_);
        }
    }

    function _getBridgeSelector(uint256 command_) internal pure returns (bytes4 bridgeSelector_) {
        if (command_ == Commands.BRIDGE_ERC20) {
            bridgeSelector_ = BridgeRouter.bridgeERC20.selector;
        } else if (command_ == Commands.BRIDGE_ERC721) {
            bridgeSelector_ = BridgeRouter.bridgeERC721.selector;
        } else if (command_ == Commands.BRIDGE_ERC1155) {
            bridgeSelector_ = BridgeRouter.bridgeERC1155.selector;
        } else if (command_ == Commands.BRIDGE_NATIVE) {
            bridgeSelector_ = BridgeRouter.bridgeNative.selector;
        }
    }

    function _getTransferSelector(
        uint256 command_
    ) internal pure returns (bytes4 transferSelector_) {
        if (command_ == Commands.TRANSFER_ERC20) {
            transferSelector_ = TransferRouter.transferERC20.selector;
        } else if (command_ == Commands.TRANSFER_ERC721) {
            transferSelector_ = TransferRouter.transferERC721.selector;
        } else if (command_ == Commands.TRANSFER_ERC1155) {
            transferSelector_ = TransferRouter.transferERC1155.selector;
        } else if (command_ == Commands.TRANSFER_NATIVE) {
            transferSelector_ = TransferRouter.transferNative.selector;
        } else if (command_ == Commands.TRANSFER_FROM_ERC20) {
            transferSelector_ = TransferRouter.transferFromERC20.selector;
        } else if (command_ == Commands.TRANSFER_FROM_ERC721) {
            transferSelector_ = TransferRouter.transferFromERC721.selector;
        } else if (command_ == Commands.TRANSFER_FROM_ERC1155) {
            transferSelector_ = TransferRouter.transferFromERC1155.selector;
        }
    }

    function _getWrapSelector(uint256 command_) internal pure returns (bytes4 wrapSelector_) {
        if (command_ == Commands.WRAP_NATIVE) {
            wrapSelector_ = WrapRouter.wrap.selector;
        } else if (command_ == Commands.UNWRAP_NATIVE) {
            wrapSelector_ = WrapRouter.unwrap.selector;
        }
    }

    function _getMulticallSelector(
        uint256 command_
    ) internal pure returns (bytes4 multicallSelector_) {
        if (command_ == Commands.MULTICALL) {
            multicallSelector_ = MulticallRouter.multicall.selector;
        }
    }

    function _getUniswapV2Selector(
        uint256 command_
    ) internal pure returns (bytes4 uniswapV2Selector_) {
        if (command_ == Commands.SWAP_EXACT_TOKENS_FOR_TOKENS_V2) {
            uniswapV2Selector_ = UniswapV2Router.swapExactTokensForTokensV2.selector;
        } else if (command_ == Commands.SWAP_TOKENS_FOR_EXACT_TOKENS_V2) {
            uniswapV2Selector_ = UniswapV2Router.swapTokensForExactTokensV2.selector;
        } else if (command_ == Commands.SWAP_EXACT_ETH_FOR_TOKENS) {
            uniswapV2Selector_ = UniswapV2Router.swapExactETHForTokens.selector;
        } else if (command_ == Commands.SWAP_TOKENS_FOR_EXACT_ETH) {
            uniswapV2Selector_ = UniswapV2Router.swapTokensForExactETH.selector;
        } else if (command_ == Commands.SWAP_EXACT_TOKENS_FOR_ETH) {
            uniswapV2Selector_ = UniswapV2Router.swapExactTokensForETH.selector;
        } else if (command_ == Commands.SWAP_ETH_FOR_EXACT_TOKENS) {
            uniswapV2Selector_ = UniswapV2Router.swapETHForExactTokens.selector;
        }
    }

    function _getUniswapV3Selector(
        uint256 command_
    ) internal pure returns (bytes4 uniswapV3Selector_) {
        if (command_ == Commands.EXACT_INPUT) {
            uniswapV3Selector_ = UniswapV3Router.exactInput.selector;
        } else if (command_ == Commands.EXACT_OUTPUT) {
            uniswapV3Selector_ = UniswapV3Router.exactOutput.selector;
        }
    }

    function _getTraderJoeSelector(
        uint256 command_
    ) internal pure returns (bytes4 traderJoeSelector_) {
        if (command_ == Commands.SWAP_EXACT_TOKENS_FOR_TOKENS_TJ) {
            traderJoeSelector_ = TraderJoeRouter.swapExactTokensForTokensTJ.selector;
        } else if (command_ == Commands.SWAP_TOKENS_FOR_EXACT_TOKENS_TJ) {
            traderJoeSelector_ = TraderJoeRouter.swapTokensForExactTokensTJ.selector;
        } else if (command_ == Commands.SWAP_EXACT_AVAX_FOR_TOKENS) {
            traderJoeSelector_ = TraderJoeRouter.swapExactAVAXForTokens.selector;
        } else if (command_ == Commands.SWAP_TOKENS_FOR_EXACT_AVAX) {
            traderJoeSelector_ = TraderJoeRouter.swapTokensForExactAVAX.selector;
        } else if (command_ == Commands.SWAP_EXACT_TOKENS_FOR_AVAX) {
            traderJoeSelector_ = TraderJoeRouter.swapExactTokensForAVAX.selector;
        } else if (command_ == Commands.SWAP_AVAX_FOR_EXACT_TOKENS) {
            traderJoeSelector_ = TraderJoeRouter.swapAVAXForExactTokens.selector;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/**
 *  @notice The Diamond standard module
 *
 *  This is the storage contract for the diamond proxy
 */
contract DiamondStorage {
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using EnumerableSet for EnumerableSet.AddressSet;

    /**
     *  @notice The struct slot where the storage is
     */
    bytes32 public constant DIAMOND_STORAGE_SLOT = keccak256("diamond.standard.diamond.storage");

    /**
     *  @notice The storage of the Diamond proxy
     */
    struct DStorage {
        mapping(bytes4 => address) selectorToFacet;
        mapping(address => EnumerableSet.Bytes32Set) facetToSelectors;
        EnumerableSet.AddressSet facets;
    }

    /**
     *  @notice The internal function to get the diamond proxy storage
     *  @return _ds the struct from the DIAMOND_STORAGE_SLOT
     */
    function _getDiamondStorage() internal pure returns (DStorage storage _ds) {
        bytes32 slot_ = DIAMOND_STORAGE_SLOT;

        assembly {
            _ds.slot := slot_
        }
    }

    /**
     *  @notice The function to get all the facets of this diamond
     *  @return facets_ the array of facets' addresses
     */
    function getFacets() public view returns (address[] memory facets_) {
        return _getDiamondStorage().facets.values();
    }

    /**
     *  @notice The function to get all the selectors assigned to the facet
     *  @param facet_ the facet to get assigned selectors of
     *  @return selectors_ the array of assigned selectors
     */
    function getFacetSelectors(address facet_) public view returns (bytes4[] memory selectors_) {
        EnumerableSet.Bytes32Set storage _f2s = _getDiamondStorage().facetToSelectors[facet_];

        selectors_ = new bytes4[](_f2s.length());

        for (uint256 i = 0; i < selectors_.length; i++) {
            selectors_[i] = bytes4(_f2s.at(i));
        }
    }

    /**
     *  @notice The function to get associated facet by the selector
     *  @param selector_ the selector
     *  @return facet_ the associated facet address
     */
    function getFacetBySelector(bytes4 selector_) public view returns (address facet_) {
        return _getDiamondStorage().selectorToFacet[selector_];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 *  @notice The storage contract of Ownable Diamond preset
 */
contract OwnableDiamondStorage {
    bytes32 public constant OWNABLE_DIAMOND_STORAGE_SLOT =
        keccak256("diamond.standard.ownablediamond.storage");

    struct ODStorage {
        address owner;
    }

    modifier onlyOwner() {
        address diamondOwner_ = owner();

        require(
            diamondOwner_ == address(0) || diamondOwner_ == msg.sender,
            "ODStorage: not an owner"
        );
        _;
    }

    function _getOwnableDiamondStorage() internal pure returns (ODStorage storage _ods) {
        bytes32 slot_ = OWNABLE_DIAMOND_STORAGE_SLOT;

        assembly {
            _ods.slot := slot_
        }
    }

    function owner() public view returns (address) {
        return _getOwnableDiamondStorage().owner;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

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
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
        return verifyCallResult(success, returndata, errorMessage);
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
        return verifyCallResult(success, returndata, errorMessage);
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
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/structs/EnumerableSet.sol)

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
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../handlers/IERC20Handler.sol";
import "../handlers/IERC721Handler.sol";
import "../handlers/IERC1155Handler.sol";
import "../handlers/INativeHandler.sol";

/**
 * @notice The Bridge contract
 *
 * The Bridge contract acts as a permissioned way of transfering assets (ERC20, ERC721, ERC1155, Native) between
 * 2 different blockchains.
 *
 * In order to correctly use the Bridge, one has to deploy both instances of the contract on the base chain and the
 * destination chain, as well as setup a trusted backend that will act as a `signer`.
 *
 * Each Bridge contract can either give or take the user assets when they want to transfer tokens. Both liquidity pool
 * and mint-and-burn way of transferring assets are supported.
 *
 * The bridge enables the transaction bundling feature as well.
 */
interface IBridge is IBundler, IERC20Handler, IERC721Handler, IERC1155Handler, INativeHandler {
    /**
     * @notice function for withdrawing erc20 tokens
     * @param tokenData_ the encoded token address and amount
     * @param bundle_ the encoded transaction bundle with encoded salt
     * @param receiver_ the address who will receive tokens
     * @param originHash_ the keccak256 hash of abi.encodePacked(origin chain name . origin tx hash . event nonce)
     * @param proof_ the abi encoded merkle path with the signature of a merkle root the signer signed
     * @param isWrapped_ the boolean flag, if true - tokens will minted, false - tokens will transferred
     */
    function withdrawERC20(
        bytes calldata tokenData_,
        IBundler.Bundle calldata bundle_,
        bytes32 originHash_,
        address receiver_,
        bytes calldata proof_,
        bool isWrapped_
    ) external;

    /**
     * @notice function for withdrawing erc721 tokens
     * @param tokenData_ the encoded token address, token id and token URI
     * @param bundle_ the encoded transaction bundle with encoded salt
     * @param originHash_ the keccak256 hash of abi.encodePacked(origin chain name . origin tx hash . event nonce)
     * @param receiver_ the address who will receive tokens
     * @param proof_ the abi encoded merkle path with the signature of a merkle root the signer signed
     * @param isWrapped_ the boolean flag, if true - tokens will minted, false - tokens will transferred
     */
    function withdrawERC721(
        bytes calldata tokenData_,
        IBundler.Bundle calldata bundle_,
        bytes32 originHash_,
        address receiver_,
        bytes calldata proof_,
        bool isWrapped_
    ) external;

    /**
     * @notice function for withdrawing sbt tokens
     * @param tokenData_ the encoded token address, token id and token URI
     * @param bundle_ the encoded transaction bundle with encoded salt
     * @param originHash_ the keccak256 hash of abi.encodePacked(origin chain name . origin tx hash . event nonce)
     * @param receiver_ the address who will receive tokens
     * @param proof_ the abi encoded merkle path with the signature of a merkle root the signer signed
     */
    function withdrawSBT(
        bytes calldata tokenData_,
        IBundler.Bundle calldata bundle_,
        bytes32 originHash_,
        address receiver_,
        bytes calldata proof_
    ) external;

    /**
     * @notice function for withdrawing erc1155 tokens
     * @param tokenData_ the encoded token address, token id, token URI and amount
     * @param bundle_ the encoded transaction bundle with encoded salt
     * @param originHash_ the keccak256 hash of abi.encodePacked(origin chain name . origin tx hash . event nonce)
     * @param receiver_ the address who will receive tokens
     * @param proof_ the abi encoded merkle path with the signature of a merkle root the signer signed
     * @param isWrapped_ the boolean flag, if true - tokens will minted, false - tokens will transferred
     */
    function withdrawERC1155(
        bytes calldata tokenData_,
        IBundler.Bundle calldata bundle_,
        bytes32 originHash_,
        address receiver_,
        bytes calldata proof_,
        bool isWrapped_
    ) external;

    /**
     * @notice function for withdrawing native currency
     * @param tokenData_ the encoded native amount
     * @param bundle_ the encoded transaction bundle
     * @param originHash_ the keccak256 hash of abi.encodePacked(origin chain name . origin tx hash . event nonce)
     * @param receiver_ the address who will receive tokens
     * @param proof_ the abi encoded merkle path with the signature of a merkle root the signer signed
     */
    function withdrawNative(
        bytes calldata tokenData_,
        IBundler.Bundle calldata bundle_,
        bytes32 originHash_,
        address receiver_,
        bytes calldata proof_
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IBundler {
    /**
     * @notice the struct that stores bundling info
     * @param salt the salt used to determine the proxy address
     * @param bundle the encoded transaction bundle
     */
    struct Bundle {
        bytes32 salt;
        bytes bundle;
    }

    /**
     * @notice function to get the bundle executor proxy address for the given salt and bundle
     * @param salt_ the salt for create2 (origin hash)
     * @return the bundle executor proxy address
     */
    function determineProxyAddress(bytes32 salt_) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../bundle/IBundler.sol";

interface IERC1155Handler is IBundler {
    /**
     * @notice event emits from depositERC1155 function
     */
    event DepositedERC1155(
        address token,
        uint256 tokenId,
        uint256 amount,
        bytes32 salt,
        bytes bundle,
        string network,
        string receiver,
        bool isWrapped
    );

    /**
     * @notice function for depositing erc1155 tokens, emits event DepositedERC115
     * @param token_ the address of deposited tokens
     * @param tokenId_ the id of deposited tokens
     * @param amount_ the amount of deposited tokens
     * @param bundle_ the encoded transaction bundle with salt
     * @param network_ the network name of destination network, information field for event
     * @param receiver_ the receiver address in destination network, information field for event
     * @param isWrapped_ the boolean flag, if true - tokens will burned, false - tokens will transferred
     */
    function depositERC1155(
        address token_,
        uint256 tokenId_,
        uint256 amount_,
        IBundler.Bundle calldata bundle_,
        string calldata network_,
        string calldata receiver_,
        bool isWrapped_
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../bundle/IBundler.sol";

interface IERC20Handler is IBundler {
    /**
     * @notice event emits from depositERC20 function
     */
    event DepositedERC20(
        address token,
        uint256 amount,
        bytes32 salt,
        bytes bundle,
        string network,
        string receiver,
        bool isWrapped
    );

    /**
     * @notice function for depositing erc20 tokens, emits event DepositedERC20
     * @param token_ the address of deposited token
     * @param amount_ the amount of deposited tokens
     * @param bundle_ the encoded transaction bundle with salt
     * @param network_ the network name of destination network, information field for event
     * @param receiver_ the receiver address in destination network, information field for event
     * @param isWrapped_ the boolean flag, if true - tokens will burned, false - tokens will transferred
     */
    function depositERC20(
        address token_,
        uint256 amount_,
        IBundler.Bundle calldata bundle_,
        string calldata network_,
        string calldata receiver_,
        bool isWrapped_
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../bundle/IBundler.sol";

interface IERC721Handler is IBundler {
    /**
     * @notice event emits from depositERC721 function
     */
    event DepositedERC721(
        address token,
        uint256 tokenId,
        bytes32 salt,
        bytes bundle,
        string network,
        string receiver,
        bool isWrapped
    );

    /**
     * @notice event emits from depositSBT function
     */
    event DepositedSBT(
        address token,
        uint256 tokenId,
        bytes32 salt,
        bytes bundle,
        string network,
        string receiver
    );

    /**
     * @notice function for depositing erc721 tokens, emits event DepositedERC721
     * @param token_ the address of deposited token
     * @param tokenId_ the id of deposited token
     * @param bundle_ the encoded transaction bundle with salt
     * @param network_ the network name of destination network, information field for event
     * @param receiver_ the receiver address in destination network, information field for event
     * @param isWrapped_ the boolean flag, if true - token will burned, false - token will transferred
     */
    function depositERC721(
        address token_,
        uint256 tokenId_,
        IBundler.Bundle calldata bundle_,
        string calldata network_,
        string calldata receiver_,
        bool isWrapped_
    ) external;

    /**
     * @notice function for depositing sbt tokens, emits event DepositedSBT
     * @param token_ the address of deposited token
     * @param tokenId_ the id of deposited token
     * @param bundle_ the encoded transaction bundle with salt
     * @param network_ the network name of destination network, information field for event
     * @param receiver_ the receiver address in destination network, information field for event
     */
    function depositSBT(
        address token_,
        uint256 tokenId_,
        IBundler.Bundle calldata bundle_,
        string calldata network_,
        string calldata receiver_
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../bundle/IBundler.sol";

interface INativeHandler is IBundler {
    /**
     * @notice event emits from depositNative function
     */
    event DepositedNative(
        uint256 amount,
        bytes32 salt,
        bytes bundle,
        string network,
        string receiver
    );

    /**
     * @notice function for depositing native currency, emits event DepositedNative
     * @param bundle_ the encoded transaction bundle with salt
     * @param network_ the network name of destination network, information field for event
     * @param receiver_ the receiver address in destination network, information field for event
     */
    function depositNative(
        IBundler.Bundle calldata bundle_,
        string calldata network_,
        string calldata receiver_
    ) external payable;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.2;

interface IJoeRouter01 {
    function factory() external pure returns (address);

    function WAVAX() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityAVAX(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountAVAX,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityAVAX(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountAVAX);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityAVAXWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountAVAX);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactAVAXForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactAVAX(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForAVAX(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapAVAXForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;

/// @title Periphery Payments
/// @notice Functions to ease deposits and withdrawals of ETH
interface IPeripheryPayments {
    /// @notice Unwraps the contract's WETH9 balance and sends it to recipient as ETH.
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing WETH9 from users.
    /// @param amountMinimum The minimum amount of WETH9 to unwrap
    /// @param recipient The address receiving ETH
    function unwrapWETH9(uint256 amountMinimum, address recipient) external payable;

    /// @notice Refunds any ETH balance held by this contract to the `msg.sender`
    /// @dev Useful for bundling with mint or increase liquidity that uses ether, or exact output swaps
    /// that use ether for the input amount
    function refundETH() external payable;

    /// @notice Transfers the full amount of a token held by this contract to recipient
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing the token from users
    /// @param token The contract address of the token which will be transferred to `recipient`
    /// @param amountMinimum The minimum amount of token required for a transfer
    /// @param recipient The destination address of the token
    function sweepToken(
        address token,
        uint256 amountMinimum,
        address recipient
    ) external payable;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "@dlsl/dev-modules/diamond/presets/OwnableDiamond/OwnableDiamondStorage.sol";

import "@rarimo/evm-bridge/interfaces/bridge/IBridge.sol";
import "@rarimo/evm-bridge/interfaces/bundle/IBundler.sol";

import "../../libs/Approver.sol";
import "../../libs/Constants.sol";
import "../../libs/Resolver.sol";
import "../../master-facet/MasterRouterStorage.sol";
import "../storages/BridgeRouterStorage.sol";

contract BridgeRouter is OwnableDiamondStorage, MasterRouterStorage, BridgeRouterStorage {
    using Approver for *;
    using Resolver for uint256;
    using SafeERC20 for IERC20;

    function setBridgeAddress(address bridge_) external onlyOwner {
        _getBridgeRouterStorage().bridge = bridge_;
    }

    function bridgeERC20(
        address token_,
        uint256 amount_,
        IBundler.Bundle calldata bundle_,
        string calldata network_,
        string calldata receiver_,
        bool isWrapped_
    ) external payable {
        address bridge_ = getBridgeAddress();

        IERC20(token_).approveMax(bridge_);
        IBridge(bridge_).depositERC20(
            token_,
            amount_.resolve(IERC20(token_)),
            bundle_,
            network_,
            receiver_,
            isWrapped_
        );
    }

    function bridgeERC721(
        address token_,
        uint256 tokenId_,
        IBundler.Bundle calldata bundle_,
        string calldata network_,
        string calldata receiver_,
        bool isWrapped_
    ) external payable {
        address bridge_ = getBridgeAddress();

        IERC721(token_).approveMax(bridge_);
        IBridge(bridge_).depositERC721(token_, tokenId_, bundle_, network_, receiver_, isWrapped_);
    }

    function bridgeERC1155(
        address token_,
        uint256 tokenId_,
        uint256 amount_,
        IBundler.Bundle calldata bundle_,
        string calldata network_,
        string calldata receiver_,
        bool isWrapped_
    ) external payable {
        address bridge_ = getBridgeAddress();

        IERC1155(token_).approveMax(bridge_);
        IBridge(bridge_).depositERC1155(
            token_,
            tokenId_,
            amount_.resolve(IERC1155(token_), tokenId_),
            bundle_,
            network_,
            receiver_,
            isWrapped_
        );
    }

    function bridgeNative(
        uint256 amount_,
        IBundler.Bundle calldata bundle_,
        string calldata network_,
        string calldata receiver_
    ) external payable {
        IBridge(getBridgeAddress()).depositNative{value: amount_.resolve()}(
            bundle_,
            network_,
            receiver_
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../../libs/Resolver.sol";
import "../../libs/ErrorHelper.sol";

contract MulticallRouter {
    using Resolver for *;
    using ErrorHelper for *;

    function multicall(
        address[] calldata targets_,
        uint256[] calldata values_,
        bytes[] calldata data_
    ) external payable {
        require(
            targets_.length == values_.length && values_.length == data_.length,
            "MulticallRouter: lengths mismatch"
        );

        for (uint256 i = 0; i < targets_.length; ++i) {
            (bool ok_, bytes memory revertData_) = targets_[i].resolve().call{
                value: values_[i].resolve()
            }(data_[i]);

            require(ok_, revertData_.toStringReason().wrap("MulticallRouter"));
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "@dlsl/dev-modules/diamond/presets/OwnableDiamond/OwnableDiamondStorage.sol";

import "@traderjoe-xyz/core/contracts/traderjoe/interfaces/IJoeRouter01.sol";

import "../../libs/Approver.sol";
import "../../libs/Resolver.sol";
import "../../libs/Constants.sol";
import "../../master-facet/MasterRouterStorage.sol";
import "../storages/TraderJoeRouterStorage.sol";
import "./TransferRouter.sol";

contract TraderJoeRouter is
    OwnableDiamondStorage,
    MasterRouterStorage,
    TraderJoeRouterStorage,
    TransferRouter
{
    using SafeERC20 for IERC20;
    using Approver for *;
    using Resolver for address;

    function setTraderJoeRouterAddress(address traderJoeRouter_) external onlyOwner {
        _getTraderJoeRouterStorage().traderJoeRouter = traderJoeRouter_;
    }

    function swapExactTokensForTokensTJ(
        address receiver_,
        uint256 amountIn_,
        uint256 amountOutMin_,
        address[] calldata path_
    ) external payable {
        _validatePath(path_);

        address traderJoeRouter_ = getTraderJoeRouter();

        IERC20(path_[0]).approveMax(traderJoeRouter_);
        IJoeRouter01(traderJoeRouter_).swapExactTokensForTokens(
            amountIn_,
            amountOutMin_,
            path_,
            receiver_.resolve(),
            block.timestamp
        );
    }

    function swapTokensForExactTokensTJ(
        address receiver_,
        uint256 amountOut_,
        uint256 amountInMax_,
        address[] calldata path_
    ) external payable {
        _validatePath(path_);

        address tokenIn_ = path_[0];
        address traderJoeRouter_ = getTraderJoeRouter();

        IERC20(tokenIn_).approveMax(traderJoeRouter_);
        uint256 spentFundsAmount_ = IJoeRouter01(traderJoeRouter_).swapTokensForExactTokens(
            amountOut_,
            amountInMax_,
            path_,
            receiver_.resolve(),
            block.timestamp
        )[0];

        if (amountInMax_ > spentFundsAmount_) {
            transferERC20(tokenIn_, Constants.CALLER_ADDRESS, amountInMax_ - spentFundsAmount_);
        }
    }

    function swapExactAVAXForTokens(
        address receiver_,
        uint256 amountIn_,
        uint256 amountOutMin_,
        address[] calldata path_
    ) external payable {
        _validatePath(path_);

        IJoeRouter01(getTraderJoeRouter()).swapExactAVAXForTokens{value: amountIn_}(
            amountOutMin_,
            path_,
            receiver_.resolve(),
            block.timestamp
        );
    }

    function swapTokensForExactAVAX(
        address receiver_,
        uint256 amountOut_,
        uint256 amountInMax_,
        address[] calldata path_
    ) external payable {
        _validatePath(path_);

        address tokenIn_ = path_[0];
        address traderJoeRouter_ = getTraderJoeRouter();

        IERC20(tokenIn_).approveMax(traderJoeRouter_);
        uint256 spentFundsAmount_ = IJoeRouter01(traderJoeRouter_).swapTokensForExactAVAX(
            amountOut_,
            amountInMax_,
            path_,
            receiver_.resolve(),
            block.timestamp
        )[0];

        if (amountInMax_ > spentFundsAmount_) {
            transferERC20(tokenIn_, Constants.CALLER_ADDRESS, amountInMax_ - spentFundsAmount_);
        }
    }

    function swapExactTokensForAVAX(
        address receiver_,
        uint256 amountIn_,
        uint256 amountOutMin_,
        address[] calldata path_
    ) external payable {
        _validatePath(path_);

        address traderJoeRouter_ = getTraderJoeRouter();

        IERC20(path_[0]).approveMax(traderJoeRouter_);
        IJoeRouter01(traderJoeRouter_).swapExactTokensForAVAX(
            amountIn_,
            amountOutMin_,
            path_,
            receiver_.resolve(),
            block.timestamp
        );
    }

    function swapAVAXForExactTokens(
        address receiver_,
        uint256 amountOut_,
        uint256 amountInMax_,
        address[] calldata path_
    ) external payable {
        _validatePath(path_);

        uint256 spentFundsAmount_ = IJoeRouter01(getTraderJoeRouter()).swapAVAXForExactTokens{
            value: amountInMax_
        }(amountOut_, path_, receiver_.resolve(), block.timestamp)[0];

        if (amountInMax_ > spentFundsAmount_) {
            transferNative(Constants.CALLER_ADDRESS, amountInMax_ - spentFundsAmount_);
        }
    }

    function _validatePath(address[] calldata path_) internal pure {
        require(path_.length >= 2, "TraderJoeRouter: invalid path");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../../libs/Resolver.sol";

contract TransferRouter is MasterRouterStorage {
    using SafeERC20 for IERC20;
    using Resolver for *;

    function transferERC20(address token_, address receiver_, uint256 amount_) public payable {
        receiver_ = receiver_.resolve();

        if (receiver_ == address(this)) {
            return;
        }

        IERC20(token_).safeTransfer(receiver_, amount_.resolve(IERC20(token_)));
    }

    function transferERC721(
        address token_,
        address receiver_,
        uint256[] calldata nftIds_
    ) external payable {
        receiver_ = receiver_.resolve();

        if (receiver_ == address(this)) {
            return;
        }

        for (uint256 i = 0; i < nftIds_.length; ++i) {
            IERC721(token_).safeTransferFrom(address(this), receiver_, nftIds_[i], "");
        }
    }

    function transferERC1155(
        address token_,
        address receiver_,
        uint256[] calldata tokenIds_,
        uint256[] calldata amounts_
    ) external payable {
        require(tokenIds_.length == amounts_.length, "TransferRouter: lengths mismatch");

        receiver_ = receiver_.resolve();

        if (receiver_ == address(this)) {
            return;
        }

        for (uint256 i = 0; i < tokenIds_.length; ++i) {
            uint256 tokenId_ = tokenIds_[i];

            IERC1155(token_).safeTransferFrom(
                address(this),
                receiver_,
                tokenId_,
                amounts_[i].resolve(IERC1155(token_), tokenId_),
                ""
            );
        }
    }

    function transferFromERC20(address token_, uint256 amount_) external payable {
        IERC20(token_).safeTransferFrom(getCallerAddress(), address(this), amount_);
    }

    function transferFromERC721(address token_, uint256[] calldata nftIds_) external payable {
        for (uint256 i = 0; i < nftIds_.length; i++) {
            IERC721(token_).safeTransferFrom(getCallerAddress(), address(this), nftIds_[i], "");
        }
    }

    function transferFromERC1155(
        address token_,
        uint256[] calldata tokenIds_,
        uint256[] calldata amounts_
    ) external payable {
        IERC1155(token_).safeBatchTransferFrom(
            getCallerAddress(),
            address(this),
            tokenIds_,
            amounts_,
            ""
        );
    }

    function transferNative(address receiver_, uint256 amount_) public payable {
        receiver_ = receiver_.resolve();

        if (receiver_ == address(this)) {
            return;
        }

        (bool ok_, ) = receiver_.call{value: amount_.resolve()}("");
        require(ok_, "TransferRouter: failed to transfer native");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "@dlsl/dev-modules/diamond/presets/OwnableDiamond/OwnableDiamondStorage.sol";

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol";

import "../../libs/Approver.sol";
import "../../libs/Resolver.sol";
import "../../libs/Constants.sol";
import "../../master-facet/MasterRouterStorage.sol";
import "../storages/UniswapV2RouterStorage.sol";
import "./TransferRouter.sol";

contract UniswapV2Router is
    OwnableDiamondStorage,
    MasterRouterStorage,
    UniswapV2RouterStorage,
    TransferRouter
{
    using SafeERC20 for IERC20;
    using Approver for *;
    using Resolver for address;

    function setUniswapV2RouterAddress(address swapV2Router_) external onlyOwner {
        _getUniswapV2RouterStorage().swapV2Router = swapV2Router_;
    }

    function swapExactTokensForTokensV2(
        address receiver_,
        uint256 amountIn_,
        uint256 amountOutMin_,
        address[] calldata path_
    ) external payable {
        _validatePath(path_);

        address swapV2router_ = getSwapV2Router();

        IERC20(path_[0]).approveMax(swapV2router_);
        IUniswapV2Router01(swapV2router_).swapExactTokensForTokens(
            amountIn_,
            amountOutMin_,
            path_,
            receiver_.resolve(),
            block.timestamp
        );
    }

    function swapTokensForExactTokensV2(
        address receiver_,
        uint256 amountOut_,
        uint256 amountInMax_,
        address[] calldata path_
    ) external payable {
        _validatePath(path_);

        address tokenIn_ = path_[0];
        address swapV2router_ = getSwapV2Router();

        IERC20(tokenIn_).approveMax(swapV2router_);
        uint256 spentFundsAmount_ = IUniswapV2Router01(swapV2router_).swapTokensForExactTokens(
            amountOut_,
            amountInMax_,
            path_,
            receiver_.resolve(),
            block.timestamp
        )[0];

        if (amountInMax_ > spentFundsAmount_) {
            transferERC20(tokenIn_, Constants.CALLER_ADDRESS, amountInMax_ - spentFundsAmount_);
        }
    }

    function swapExactETHForTokens(
        address receiver_,
        uint256 amountIn_,
        uint256 amountOutMin_,
        address[] calldata path_
    ) external payable {
        _validatePath(path_);

        IUniswapV2Router01(getSwapV2Router()).swapExactETHForTokens{value: amountIn_}(
            amountOutMin_,
            path_,
            receiver_.resolve(),
            block.timestamp
        );
    }

    function swapTokensForExactETH(
        address receiver_,
        uint256 amountOut_,
        uint256 amountInMax_,
        address[] calldata path_
    ) external payable {
        _validatePath(path_);

        address tokenIn_ = path_[0];
        address swapV2router_ = getSwapV2Router();

        IERC20(tokenIn_).approveMax(swapV2router_);
        uint256 spentFundsAmount_ = IUniswapV2Router01(swapV2router_).swapTokensForExactETH(
            amountOut_,
            amountInMax_,
            path_,
            receiver_.resolve(),
            block.timestamp
        )[0];

        if (amountInMax_ > spentFundsAmount_) {
            transferERC20(tokenIn_, Constants.CALLER_ADDRESS, amountInMax_ - spentFundsAmount_);
        }
    }

    function swapExactTokensForETH(
        address receiver_,
        uint256 amountIn_,
        uint256 amountOutMin_,
        address[] calldata path_
    ) external payable {
        _validatePath(path_);

        address swapV2router_ = getSwapV2Router();

        IERC20(path_[0]).approveMax(swapV2router_);
        IUniswapV2Router01(swapV2router_).swapExactTokensForETH(
            amountIn_,
            amountOutMin_,
            path_,
            receiver_.resolve(),
            block.timestamp
        );
    }

    function swapETHForExactTokens(
        address receiver_,
        uint256 amountOut_,
        uint256 amountInMax_,
        address[] calldata path_
    ) external payable {
        _validatePath(path_);

        uint256 spentFundsAmount_ = IUniswapV2Router01(getSwapV2Router()).swapETHForExactTokens{
            value: amountInMax_
        }(amountOut_, path_, receiver_.resolve(), block.timestamp)[0];

        if (amountInMax_ > spentFundsAmount_) {
            transferNative(Constants.CALLER_ADDRESS, amountInMax_ - spentFundsAmount_);
        }
    }

    function _validatePath(address[] calldata path_) internal pure {
        require(path_.length >= 2, "UniswapV2Router: invalid path");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "@dlsl/dev-modules/diamond/presets/OwnableDiamond/OwnableDiamondStorage.sol";

import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/interfaces/IPeripheryPayments.sol";

import "../../libs/BytesHelper.sol";
import "../../libs/Approver.sol";
import "../../libs/Resolver.sol";
import "../../libs/Constants.sol";
import "../../master-facet/MasterRouterStorage.sol";
import "../storages/UniswapV3RouterStorage.sol";
import "./TransferRouter.sol";

contract UniswapV3Router is
    OwnableDiamondStorage,
    MasterRouterStorage,
    UniswapV3RouterStorage,
    TransferRouter
{
    using SafeERC20 for IERC20;
    using BytesHelper for bytes;
    using Approver for *;
    using Resolver for address;

    function setUniswapV3RouterAddress(address swapV3Router_) external onlyOwner {
        _getUniswapV3RouterStorage().swapV3Router = swapV3Router_;
    }

    function exactInput(
        bool isNative_,
        address receiver_,
        uint256 amountIn_,
        uint256 amountOutMinimum_,
        bytes calldata path_
    ) external payable {
        address swapV3Router_ = getSwapV3Router();

        if (!isNative_) {
            IERC20(path_.getFirstToken()).approveMax(swapV3Router_);
        }

        ISwapRouter(swapV3Router_).exactInput{value: isNative_ ? amountIn_ : 0}(
            ISwapRouter.ExactInputParams({
                path: path_,
                recipient: receiver_.resolve(),
                deadline: block.timestamp,
                amountIn: amountIn_,
                amountOutMinimum: amountOutMinimum_
            })
        );
    }

    function exactOutput(
        bool isNative_,
        address receiver_,
        uint256 amountOut_,
        uint256 amountInMaximum_,
        bytes calldata path_
    ) external payable {
        address tokenIn_ = path_.getLastToken();

        address swapV3Router_ = getSwapV3Router();

        if (!isNative_) {
            IERC20(tokenIn_).approveMax(swapV3Router_);
        }

        uint256 spentFundsAmount_ = ISwapRouter(swapV3Router_).exactOutput{
            value: isNative_ ? amountInMaximum_ : 0
        }(
            ISwapRouter.ExactOutputParams({
                path: path_,
                recipient: receiver_.resolve(),
                deadline: block.timestamp,
                amountOut: amountOut_,
                amountInMaximum: amountInMaximum_
            })
        );

        if (amountInMaximum_ > spentFundsAmount_) {
            if (isNative_) {
                IPeripheryPayments(swapV3Router_).refundETH();

                transferNative(Constants.CALLER_ADDRESS, amountInMaximum_ - spentFundsAmount_);
            } else {
                transferERC20(
                    tokenIn_,
                    Constants.CALLER_ADDRESS,
                    amountInMaximum_ - spentFundsAmount_
                );
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@dlsl/dev-modules/diamond/presets/OwnableDiamond/OwnableDiamondStorage.sol";

import "../../libs/Resolver.sol";
import "../../interfaces/tokens/IWrappedNative.sol";
import "../../master-facet/MasterRouterStorage.sol";
import "../storages/WrapRouterRouterStorage.sol";
import "./TransferRouter.sol";

contract WrapRouter is OwnableDiamondStorage, WrapRouterStorage, TransferRouter {
    using Resolver for uint256;

    function setWrappedNativeAddress(address wrappedNative_) external onlyOwner {
        _getWrapRouterStorage().wrappedNative = wrappedNative_;
    }

    function wrap(address receiver_, uint256 amount_) external payable {
        address weth9_ = getWrappedNativeAddress();

        amount_ = amount_.resolve();

        IWrappedNative(weth9_).deposit{value: amount_}();
        transferERC20(weth9_, receiver_, amount_);
    }

    function unwrap(address receiver_, uint256 amount_) external payable {
        address weth9_ = getWrappedNativeAddress();

        amount_ = amount_.resolve(IERC20(weth9_));

        IWrappedNative(weth9_).withdraw(amount_);
        transferNative(receiver_, amount_);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract BridgeRouterStorage {
    bytes32 public constant BRIDGE_ROUTER_STORAGE_SLOT =
        keccak256("diamond.standard.bridgerouter.storage");

    struct BRStorage {
        address bridge;
    }

    function getBridgeAddress() public view returns (address bridge_) {
        return _getBridgeRouterStorage().bridge;
    }

    function _getBridgeRouterStorage() internal pure returns (BRStorage storage _ds) {
        bytes32 slot_ = BRIDGE_ROUTER_STORAGE_SLOT;

        assembly {
            _ds.slot := slot_
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract TraderJoeRouterStorage {
    bytes32 public constant TRADER_JOE_ROUTER_STORAGE_SLOT =
        keccak256("diamond.standard.traderjoerouter.storage");

    struct TJStorage {
        address traderJoeRouter;
    }

    function getTraderJoeRouter() public view returns (address traderJoeRouter_) {
        return _getTraderJoeRouterStorage().traderJoeRouter;
    }

    function _getTraderJoeRouterStorage() internal pure returns (TJStorage storage _ds) {
        bytes32 slot_ = TRADER_JOE_ROUTER_STORAGE_SLOT;

        assembly {
            _ds.slot := slot_
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract UniswapV2RouterStorage {
    bytes32 public constant UNISWAP_V2_ROUTER_STORAGE_SLOT =
        keccak256("diamond.standard.uniswapv2router.storage");

    struct U2Storage {
        address swapV2Router;
    }

    function getSwapV2Router() public view returns (address swapV2Router_) {
        return _getUniswapV2RouterStorage().swapV2Router;
    }

    function _getUniswapV2RouterStorage() internal pure returns (U2Storage storage _ds) {
        bytes32 slot_ = UNISWAP_V2_ROUTER_STORAGE_SLOT;

        assembly {
            _ds.slot := slot_
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract UniswapV3RouterStorage {
    bytes32 public constant UNISWAP_V3_ROUTER_STORAGE_SLOT =
        keccak256("diamond.standard.uniswapv3router.storage");

    struct U3Storage {
        address swapV3Router;
    }

    function getSwapV3Router() public view returns (address swapV3Router_) {
        return _getUniswapV3RouterStorage().swapV3Router;
    }

    function _getUniswapV3RouterStorage() internal pure returns (U3Storage storage _ds) {
        bytes32 slot_ = UNISWAP_V3_ROUTER_STORAGE_SLOT;

        assembly {
            _ds.slot := slot_
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract WrapRouterStorage {
    bytes32 public constant WRAP_ROUTER_STORAGE_SLOT =
        keccak256("diamond.standard.wraprouter.storage");

    struct WRStorage {
        address wrappedNative;
    }

    function getWrappedNativeAddress() public view returns (address wrappedNative_) {
        return _getWrapRouterStorage().wrappedNative;
    }

    function _getWrapRouterStorage() internal pure returns (WRStorage storage _ds) {
        bytes32 slot_ = WRAP_ROUTER_STORAGE_SLOT;

        assembly {
            _ds.slot := slot_
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Interface for WETH9
interface IWrappedNative is IERC20 {
    /// @notice Deposit ether to get wrapped ether
    function deposit() external payable;

    /// @notice Withdraw wrapped ether to get ether
    function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

library Approver {
    function approveMax(IERC20 erc20_, address to_) internal {
        if (erc20_.allowance(address(this), to_) == 0) {
            erc20_.approve(to_, type(uint256).max);
        }
    }

    function approveMax(IERC721 erc721_, address to_) internal {
        erc721_.setApprovalForAll(to_, true);
    }

    function approveMax(IERC1155 erc1155_, address to_) internal {
        erc1155_.setApprovalForAll(to_, true);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library BytesHelper {
    function getFirstToken(bytes calldata path_) internal pure returns (address) {
        require(path_.length > 42, "BytesHelper: invalid path length");

        return toAddress(path_, 0);
    }

    function getLastToken(bytes calldata path_) internal pure returns (address) {
        require(path_.length > 42, "BytesHelper: invalid path length");

        return toAddress(path_, path_.length - 20);
    }

    function toAddress(
        bytes memory path_,
        uint256 start_
    ) internal pure returns (address tokenAddress_) {
        assembly {
            tokenAddress_ := shr(96, mload(add(add(path_, 0x20), start_)))
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library Commands {
    /// @dev bridge facet commands: 1 <= command <= 9
    uint256 internal constant BRIDGE_ERC20 = 1;
    uint256 internal constant BRIDGE_ERC721 = 2;
    uint256 internal constant BRIDGE_ERC1155 = 3;
    uint256 internal constant BRIDGE_NATIVE = 4;

    /// @dev transfer facet commands: 10 <= command <= 19
    uint256 internal constant TRANSFER_ERC20 = 10;
    uint256 internal constant TRANSFER_ERC721 = 11;
    uint256 internal constant TRANSFER_ERC1155 = 12;
    uint256 internal constant TRANSFER_NATIVE = 13;
    uint256 internal constant TRANSFER_FROM_ERC20 = 14;
    uint256 internal constant TRANSFER_FROM_ERC721 = 15;
    uint256 internal constant TRANSFER_FROM_ERC1155 = 16;

    /// @dev wrap facet commands: 20 <= command <= 24
    uint256 internal constant WRAP_NATIVE = 20;
    uint256 internal constant UNWRAP_NATIVE = 21;

    /// @dev multicall facet commands: 25 <= command <= 29
    uint256 internal constant MULTICALL = 25;

    /// @dev UniswapV2 facet commands: 50 <= command <= 59
    uint256 internal constant SWAP_EXACT_TOKENS_FOR_TOKENS_V2 = 50;
    uint256 internal constant SWAP_TOKENS_FOR_EXACT_TOKENS_V2 = 51;
    uint256 internal constant SWAP_EXACT_ETH_FOR_TOKENS = 52;
    uint256 internal constant SWAP_TOKENS_FOR_EXACT_ETH = 53;
    uint256 internal constant SWAP_EXACT_TOKENS_FOR_ETH = 54;
    uint256 internal constant SWAP_ETH_FOR_EXACT_TOKENS = 55;

    /// @dev UniswapV3 facet commands: 60 <= command <= 69
    uint256 internal constant EXACT_INPUT = 60;
    uint256 internal constant EXACT_OUTPUT = 61;

    /// @dev TraderJoe facet commands: 70 <= command <= 79
    uint256 internal constant SWAP_EXACT_TOKENS_FOR_TOKENS_TJ = 70;
    uint256 internal constant SWAP_TOKENS_FOR_EXACT_TOKENS_TJ = 71;
    uint256 internal constant SWAP_EXACT_AVAX_FOR_TOKENS = 72;
    uint256 internal constant SWAP_TOKENS_FOR_EXACT_AVAX = 73;
    uint256 internal constant SWAP_EXACT_TOKENS_FOR_AVAX = 74;
    uint256 internal constant SWAP_AVAX_FOR_EXACT_TOKENS = 75;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library Constants {
    uint256 internal constant CONTRACT_BALANCE =
        0x8000000000000000000000000000000000000000000000000000000000000000;

    address internal constant THIS_ADDRESS = 0x0000000000000000000000000000000000000001;
    address internal constant CALLER_ADDRESS = 0x0000000000000000000000000000000000000002;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library ErrorHelper {
    string internal constant ERROR_DELIMITER = ": ";

    function toStringReason(bytes memory data_) internal pure returns (string memory) {
        if (data_.length < 68) {
            return "ErrorHelper: command reverted silently";
        }

        assembly {
            data_ := add(data_, 0x04)
        }

        return abi.decode(data_, (string));
    }

    function wrap(
        string memory error_,
        string memory prefix_
    ) internal pure returns (string memory) {
        return string(abi.encodePacked(prefix_, ERROR_DELIMITER, error_));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import "./Constants.sol";
import "../master-facet/MasterRouterStorage.sol";

library Resolver {
    function resolve(address address_) internal view returns (address) {
        if (address_ == Constants.THIS_ADDRESS) {
            return address(this);
        }

        if (address_ == Constants.CALLER_ADDRESS) {
            return MasterRouterStorage(address(this)).getCallerAddress();
        }

        return address_;
    }

    function resolve(uint256 amount_) internal view returns (uint256) {
        if (amount_ == Constants.CONTRACT_BALANCE) {
            return address(this).balance;
        }

        return amount_;
    }

    function resolve(uint256 amount_, IERC20 erc20_) internal view returns (uint256) {
        if (amount_ == Constants.CONTRACT_BALANCE) {
            return erc20_.balanceOf(address(this));
        }

        return amount_;
    }

    function resolve(
        uint256 amount_,
        IERC1155 erc1155_,
        uint256 tokenId_
    ) internal view returns (uint256) {
        if (amount_ == Constants.CONTRACT_BALANCE) {
            return erc1155_.balanceOf(address(this), tokenId_);
        }

        return amount_;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract MasterRouterStorage {
    bytes32 public constant MASTER_ROUTER_STORAGE_SLOT =
        keccak256("diamond.standard.masterrouter.storage");

    struct MRStorage {
        address caller;
    }

    modifier onlyCaller() {
        MRStorage storage _ds = getMasterRouterStorage();

        require(_ds.caller == address(0), "MasterRouterStorage: new caller");

        _ds.caller = msg.sender;
        _;
        _ds.caller = address(0);
    }

    function getMasterRouterStorage() internal pure returns (MRStorage storage _ds) {
        bytes32 slot_ = MASTER_ROUTER_STORAGE_SLOT;

        assembly {
            _ds.slot := slot_
        }
    }

    function getCallerAddress() public view returns (address caller_) {
        return getMasterRouterStorage().caller;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract SwapDiamondStorage {
    bytes32 public constant SWAP_DIAMOND_STORAGE_SLOT =
        keccak256("diamond.standard.swapdiamond.storage");

    enum SelectorType {
        Undefined,
        SwapDiamond,
        MasterRouter
    }

    struct SDStorage {
        mapping(bytes4 => SelectorType) selectorTypes;
    }

    function getSelectorType(bytes4 selector_) public view returns (SelectorType selectorType_) {
        return _getSwapDiamondStorage().selectorTypes[selector_];
    }

    function _getSwapDiamondStorage() internal pure returns (SDStorage storage _ds) {
        bytes32 slot_ = SWAP_DIAMOND_STORAGE_SLOT;

        assembly {
            _ds.slot := slot_
        }
    }
}