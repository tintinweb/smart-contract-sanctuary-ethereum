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

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.14;

import {LiqRequest} from "../types/socketTypes.sol";

interface IDestination {
    function directDeposit(
        address srcSender,
        LiqRequest memory liqData,
        uint256[] memory vaultIds,
        uint256[] memory amounts
    ) external payable returns (uint256[] memory dstAmounts);

    function directWithdraw(
        address srcSender,
        uint256[] memory vaultIds,
        uint256[] memory amounts,
        LiqRequest memory _liqData
    ) external payable;

    function stateSync(bytes memory _payload) external payable;

    function safeGasParam() external view returns (bytes memory);
}

pragma solidity ^0.8.14;

interface IController {
    function chainId() external returns (uint16);

    function totalTransactions() external returns (uint256);

    function stateSync(bytes memory _payload) external payable;
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.14;

interface IStateHandler {
    function dispatchState(
        uint16 dstChainId,
        bytes memory data,
        bytes memory adapterParam
    ) external payable;
}

/**
 * SPDX-License-Identifier: Apache-2.0
 */
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

import {IStateHandler} from "./interface/layerzero/IStateHandler.sol";
import {IController} from "./interface/ISource.sol";
import {IDestination} from "./interface/IDestination.sol";

import {StateReq, InitData, StateData, TransactionType, CallbackType} from "./types/lzTypes.sol";
import {LiqRequest} from "./types/socketTypes.sol";

contract RouterPatch is ERC1155Holder {
    address public constant ROUTER_ADDRESS =
        0xfF3aFb7d847AeD8f2540f7b5042F693242e01ebD;
    address public constant STATE_ADDRESS =
        0x908da814cc9725616D410b2978E88fF2fb9482eE;
    address public constant DESTINATION_ADDRESS =
        0xc8884edE1ae44bDfF60da4B9c542C34A69648A87;

    uint256 public totalTransactions;
    uint16 public chainId;

    /* ================ Mapping =================== */
    mapping(uint256 => StateData) public txHistory;

    /* ================ Events =================== */
    event Initiated(uint256 txId, address fromToken, uint256 fromAmount);
    event Completed(uint256 txId);

    constructor(uint16 chainId_) {
        chainId = chainId_;
        totalTransactions = IController(ROUTER_ADDRESS).totalTransactions();
    }

    receive() external payable {}

    function withdraw(
        StateReq[] calldata _stateReq,
        LiqRequest[] calldata _liqReq
    ) external payable {
        address sender = msg.sender;
        uint256 l1 = _stateReq.length;
        uint256 l2 = _liqReq.length;

        require(l1 == l2, "Router: Invalid Input Length");
        if (l1 > 1) {
            for (uint256 i = 0; i < l1; ++i) {
                singleWithdrawal(_stateReq[i], sender);
            }
        } else {
            singleWithdrawal(_stateReq[0], sender);
        }

        // refunding any unused gas fees.
        payable(sender).transfer(address(this).balance);
    }

    function singleWithdrawal(StateReq calldata _stateData, address sender)
        internal
    {
        uint16 dstChainId = _stateData.dstChainId;
        require(dstChainId != 0, "Router: Invalid Destination Chain");

        /// burn is not exposed externally; TBD: whether to move them here and burn.
        IERC1155(ROUTER_ADDRESS).safeBatchTransferFrom(
            sender,
            address(this),
            _stateData.vaultIds,
            _stateData.amounts,
            "0x"
        );

        totalTransactions++;

        /// generating a dummy request - that will override user's inbound req
        LiqRequest memory data = LiqRequest(
            0,
            "",
            address(0),
            address(0),
            0,
            0
        );

        InitData memory initData = InitData(
            chainId,
            _stateData.dstChainId,
            sender,
            _stateData.vaultIds,
            _stateData.amounts,
            _stateData.maxSlippage,
            totalTransactions,
            abi.encode(data)
        );

        StateData memory info = StateData(
            TransactionType.WITHDRAW,
            CallbackType.INIT,
            abi.encode(initData)
        );

        txHistory[totalTransactions] = info;

        if (chainId == dstChainId) {
            /// @dev srcSuperDestination can only transfer tokens back to this SuperRouter
            /// @dev to allow bridging somewhere else requires arch change
            IDestination(DESTINATION_ADDRESS).directWithdraw(
                sender,
                _stateData.vaultIds,
                _stateData.amounts,
                data
            );

            emit Completed(totalTransactions);
        } else {
            /// @dev _liqReq should have path encoded for withdraw to SuperRouter on chain different than chainId
            /// @dev construct txData in this fashion: from FTM SOURCE send message to BSC DESTINATION
            /// @dev so that BSC DISPATCHTOKENS sends tokens to AVAX receiver (EOA/contract/user-specified)
            /// @dev sync could be a problem, how long Socket path stays vaild vs. how fast we bridge/receive on Dst
            IStateHandler(STATE_ADDRESS).dispatchState{
                value: _stateData.msgValue
            }(dstChainId, abi.encode(info), _stateData.adapterParam);
        }

        emit Initiated(totalTransactions, address(0), 0);
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.14;

/// @notice We should optimize those types more
enum TransactionType {
    DEPOSIT,
    WITHDRAW
}

enum CallbackType {
    INIT,
    RETURN
}

enum PayloadState {
    STORED,
    UPDATED,
    PROCESSED
}

struct StateReq {
    uint16 dstChainId;
    uint256[] amounts;
    uint256[] vaultIds;
    uint256[] maxSlippage;
    bytes adapterParam;
    uint256 msgValue;
}

// [["106", ["8720"], ["4311413"], ["1000"], "0x000100000000000000000000000000000000000000000000000000000000004c4b40", "1548277010953360"]]
// [["0", "0x", "0x0000000000000000000000000000000000000000", "0x0000000000000000000000000000000000000000", "0", "0"]]

// ["0xbb906bc787fbc9207e254ff87be398f4e86ea39f"]["0xA36c9FEB786A79E60E5583622D1Fb42294003411"] = true
// [{operator: "0xA36c9FEB786A79E60E5583622D1Fb42294003411"}]

/// Created during deposit by contract from Liq+StateReqs
/// @dev using this for communication between src & dst transfers
struct StateData {
    TransactionType txType;
    CallbackType flag;
    bytes params;
}

struct InitData {
    uint16 srcChainId;
    uint16 dstChainId;
    address user;
    uint256[] vaultIds;
    uint256[] amounts;
    uint256[] maxSlippage;
    uint256 txId;
    bytes liqData;
}

struct ReturnData {
    bool status;
    uint16 srcChainId;
    uint16 dstChainId;
    uint256 txId;
    uint256[] amounts;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.14;

struct LiqRequest {
    uint8 bridgeId;
    bytes txData;
    address token;
    address allowanceTarget; /// @dev should check with socket.
    uint256 amount;
    uint256 nativeAmount;
}

struct BridgeRequest {
    uint256 id;
    uint256 optionalNativeAmount;
    address inputToken;
    bytes data;
}

struct MiddlewareRequest {
    uint256 id;
    uint256 optionalNativeAmount;
    address inputToken;
    bytes data;
}

struct UserRequest {
    address receiverAddress;
    uint256 toChainId;
    uint256 amount;
    MiddlewareRequest middlewareRequest;
    BridgeRequest bridgeRequest;
}

struct LiqStruct {
    address inputToken;
    address bridge;
    UserRequest socketInfo;
}