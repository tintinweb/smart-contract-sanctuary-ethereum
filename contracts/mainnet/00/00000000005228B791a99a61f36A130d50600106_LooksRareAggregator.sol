// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {OwnableTwoSteps} from "@looksrare/contracts-libs/contracts/OwnableTwoSteps.sol";
import {ReentrancyGuard} from "@looksrare/contracts-libs/contracts/ReentrancyGuard.sol";
import {LowLevelERC20Approve} from "@looksrare/contracts-libs/contracts/lowLevelCallers/LowLevelERC20Approve.sol";
import {LowLevelERC20Transfer} from "@looksrare/contracts-libs/contracts/lowLevelCallers/LowLevelERC20Transfer.sol";
import {LowLevelERC721Transfer} from "@looksrare/contracts-libs/contracts/lowLevelCallers/LowLevelERC721Transfer.sol";
import {LowLevelERC1155Transfer} from "@looksrare/contracts-libs/contracts/lowLevelCallers/LowLevelERC1155Transfer.sol";
import {IERC20} from "@looksrare/contracts-libs/contracts/interfaces/generic/IERC20.sol";
import {TokenReceiver} from "./TokenReceiver.sol";
import {ILooksRareAggregator} from "./interfaces/ILooksRareAggregator.sol";
import {TokenTransfer} from "./libraries/OrderStructs.sol";
import {InvalidOrderLength, TradeExecutionFailed, ZeroAddress} from "./libraries/SharedErrors.sol";

/**
 * @title LooksRareAggregator
 * @notice This contract allows NFT sweepers to buy NFTs from
 *         different marketplaces by passing high-level structs
 *         + low-level bytes as calldata.
 * @author LooksRare protocol team (👀,💎)
 */
contract LooksRareAggregator is
    ILooksRareAggregator,
    TokenReceiver,
    ReentrancyGuard,
    LowLevelERC20Approve,
    LowLevelERC20Transfer,
    LowLevelERC721Transfer,
    LowLevelERC1155Transfer,
    OwnableTwoSteps
{
    /**
     * @notice Transactions that only involve ETH orders should be submitted to
     *         this contract directly. Transactions that involve ERC20 orders
     *         should be submitted to the contract ERC20EnabledLooksRareAggregator
     *         and it will call this contract's execution function. The purpose
     *         is to prevent a malicious proxy from stealing users' ERC20 tokens
     *         if this contract's ownership is compromised. By not providing any
     *         allowances to this aggregator, even if a malicious proxy is added,
     *         it cannot call token.transferFrom(victim, attacker, amount) inside
     *         the proxy within the context of the aggregator.
     */
    address public erc20EnabledLooksRareAggregator;
    mapping(address => mapping(bytes4 => uint256)) private _proxyFunctionSelectors;

    constructor(address _owner) OwnableTwoSteps(_owner) {}

    /**
     * @inheritdoc ILooksRareAggregator
     */
    function execute(
        TokenTransfer[] calldata tokenTransfers,
        TradeData[] calldata tradeData,
        address originator,
        address recipient,
        bool isAtomic
    ) external payable nonReentrant {
        if (recipient == address(0)) {
            revert ZeroAddress();
        }
        uint256 tradeDataLength = tradeData.length;
        if (tradeDataLength == 0) {
            revert InvalidOrderLength();
        }

        if (tokenTransfers.length == 0) {
            originator = msg.sender;
        } else if (msg.sender != erc20EnabledLooksRareAggregator) {
            revert UseERC20EnabledLooksRareAggregator();
        }

        for (uint256 i; i < tradeDataLength; ) {
            TradeData calldata singleTradeData = tradeData[i];
            address proxy = singleTradeData.proxy;
            if (_proxyFunctionSelectors[proxy][singleTradeData.selector] != 1) {
                revert InvalidFunction();
            }

            (bool success, bytes memory returnData) = proxy.delegatecall(
                abi.encodeWithSelector(
                    singleTradeData.selector,
                    singleTradeData.orders,
                    singleTradeData.ordersExtraData,
                    singleTradeData.extraData,
                    recipient,
                    isAtomic
                )
            );

            if (!success) {
                if (isAtomic) {
                    if (returnData.length != 0) {
                        assembly {
                            let returnDataSize := mload(returnData)
                            revert(add(32, returnData), returnDataSize)
                        }
                    } else {
                        revert TradeExecutionFailed();
                    }
                }
            }

            unchecked {
                ++i;
            }
        }

        if (tokenTransfers.length != 0) {
            _returnERC20TokensIfAny(tokenTransfers, originator);
        }

        bool status = true;
        assembly {
            if gt(selfbalance(), 1) {
                status := call(gas(), originator, sub(selfbalance(), 1), 0, 0, 0, 0)
            }
        }
        if (!status) {
            revert ETHTransferFail();
        }

        emit Sweep(originator);
    }

    /**
     * @notice Enable making ERC20 trades by setting the ERC20 enabled LooksRare aggregator
     * @dev Must be called by the current owner. It can only be set once to prevent
     *      a malicious aggregator from being set in case of an ownership compromise.
     * @param _erc20EnabledLooksRareAggregator The ERC20 enabled LooksRare aggregator's address
     */
    function setERC20EnabledLooksRareAggregator(address _erc20EnabledLooksRareAggregator) external onlyOwner {
        if (erc20EnabledLooksRareAggregator != address(0)) {
            revert AlreadySet();
        }
        erc20EnabledLooksRareAggregator = _erc20EnabledLooksRareAggregator;
    }

    /**
     * @notice Enable calling the specified proxy's trade function
     * @dev Must be called by the current owner
     * @param proxy The marketplace proxy's address
     * @param selector The marketplace proxy's function selector
     */
    function addFunction(address proxy, bytes4 selector) external onlyOwner {
        _proxyFunctionSelectors[proxy][selector] = 1;
        emit FunctionAdded(proxy, selector);
    }

    /**
     * @notice Disable calling the specified proxy's trade function
     * @dev Must be called by the current owner
     * @param proxy The marketplace proxy's address
     * @param selector The marketplace proxy's function selector
     */
    function removeFunction(address proxy, bytes4 selector) external onlyOwner {
        delete _proxyFunctionSelectors[proxy][selector];
        emit FunctionRemoved(proxy, selector);
    }

    /**
     * @notice Approve marketplaces to transfer ERC20 tokens from the aggregator
     * @param currency The ERC20 token address to approve
     * @param marketplace The marketplace address to approve
     * @param amount The amount of ERC20 token to approve
     */
    function approve(
        address currency,
        address marketplace,
        uint256 amount
    ) external onlyOwner {
        _executeERC20Approve(currency, marketplace, amount);
    }

    /**
     * @param proxy The marketplace proxy's address
     * @param selector The marketplace proxy's function selector
     * @return isSupported Whether the marketplace proxy's function can be called from the aggregator
     */
    function supportsProxyFunction(address proxy, bytes4 selector) external view returns (bool isSupported) {
        isSupported = _proxyFunctionSelectors[proxy][selector] == 1;
    }

    /**
     * @notice Rescue any of the contract's trapped ERC721 tokens
     * @dev Must be called by the current owner
     * @param collection The address of the ERC721 token to rescue from the contract
     * @param tokenId The token ID of the ERC721 token to rescue from the contract
     * @param to Send the contract's specified ERC721 token ID to this address
     */
    function rescueERC721(
        address collection,
        address to,
        uint256 tokenId
    ) external onlyOwner {
        _executeERC721TransferFrom(collection, address(this), to, tokenId);
    }

    /**
     * @notice Rescue any of the contract's trapped ERC1155 tokens
     * @dev Must be called by the current owner
     * @param collection The address of the ERC1155 token to rescue from the contract
     * @param tokenIds The token IDs of the ERC1155 token to rescue from the contract
     * @param amounts The amount of each token ID to rescue
     * @param to Send the contract's specified ERC1155 token ID to this address
     */
    function rescueERC1155(
        address collection,
        address to,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) external onlyOwner {
        _executeERC1155SafeBatchTransferFrom(collection, address(this), to, tokenIds, amounts);
    }

    /**
     * @dev If any order fails, the ETH paid to the marketplace
     *      is refunded to the aggregator contract. The aggregator then has to refund
     *      the ETH back to the user through _returnETHIfAny.
     */
    receive() external payable {}

    function _returnERC20TokensIfAny(TokenTransfer[] calldata tokenTransfers, address recipient) private {
        uint256 tokenTransfersLength = tokenTransfers.length;
        for (uint256 i; i < tokenTransfersLength; ) {
            uint256 balance = IERC20(tokenTransfers[i].currency).balanceOf(address(this));
            if (balance != 0) {
                _executeERC20DirectTransfer(tokenTransfers[i].currency, recipient, balance);
            }

            unchecked {
                ++i;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

abstract contract TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external virtual returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {BasicOrder, TokenTransfer} from "../libraries/OrderStructs.sol";

interface ILooksRareAggregator {
    /**
     * @param proxy The marketplace proxy's address
     * @param selector The marketplace proxy's function selector
     * @param orders Orders to be executed by the marketplace
     * @param ordersExtraData Extra data for each order, specific for each marketplace
     * @param extraData Extra data specific for each marketplace
     */
    struct TradeData {
        address proxy;
        bytes4 selector;
        BasicOrder[] orders;
        bytes[] ordersExtraData;
        bytes extraData;
    }

    /**
     * @notice Execute NFT sweeps in different marketplaces in a
     *         single transaction
     * @param tokenTransfers Aggregated ERC20 token transfers for all markets
     * @param tradeData Data object to be passed downstream to each
     *                  marketplace's proxy for execution
     * @param originator The address that originated the transaction,
     *                   hard coded as msg.sender if it is called directly
     * @param recipient The address to receive the purchased NFTs
     * @param isAtomic Flag to enable atomic trades (all or nothing)
     *                 or partial trades
     */
    function execute(
        TokenTransfer[] calldata tokenTransfers,
        TradeData[] calldata tradeData,
        address originator,
        address recipient,
        bool isAtomic
    ) external payable;

    /**
     * @notice Emitted when a marketplace proxy's function is enabled.
     * @param proxy The marketplace proxy's address
     * @param selector The marketplace proxy's function selector
     */
    event FunctionAdded(address proxy, bytes4 selector);

    /**
     * @notice Emitted when a marketplace proxy's function is disabled.
     * @param proxy The marketplace proxy's address
     * @param selector The marketplace proxy's function selector
     */
    event FunctionRemoved(address proxy, bytes4 selector);

    /**
     * @notice Emitted when execute is complete
     * @param sweeper The address that submitted the transaction
     */
    event Sweep(address sweeper);

    error AlreadySet();
    error ETHTransferFail();
    error InvalidFunction();
    error UseERC20EnabledLooksRareAggregator();
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

enum CollectionType {
    ERC721,
    ERC1155
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {CollectionType} from "./OrderEnums.sol";

/**
 * @param signer The order's maker
 * @param collection The address of the ERC721/ERC1155 token to be purchased
 * @param collectionType 0 for ERC721, 1 for ERC1155
 * @param tokenIds The IDs of the tokens to be purchased
 * @param amounts Always 1 when ERC721, can be > 1 if ERC1155
 * @param price The *taker bid* price to pay for the order
 * @param currency The order's currency, address(0) for ETH
 * @param startTime The timestamp when the order starts becoming valid
 * @param endTime The timestamp when the order stops becoming valid
 * @param signature split to v,r,s for LooksRare
 */
struct BasicOrder {
    address signer;
    address collection;
    CollectionType collectionType;
    uint256[] tokenIds;
    uint256[] amounts;
    uint256 price;
    address currency;
    uint256 startTime;
    uint256 endTime;
    bytes signature;
}

/**
 * @param amount ERC20 transfer amount
 * @param currency ERC20 transfer currency
 */
struct TokenTransfer {
    uint256 amount;
    address currency;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

error InvalidOrderLength();
error TradeExecutionFailed();
error ZeroAddress();

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// Interfaces
import {IOwnableTwoSteps} from "./interfaces/IOwnableTwoSteps.sol";

/**
 * @title OwnableTwoSteps
 * @notice This contract offers transfer of ownership in two steps with potential owner
 *         having to confirm the transaction to become the owner.
 *         Renouncement of the ownership is also a two-step process since the next potential owner is the address(0).
 * @author LooksRare protocol team (👀,💎)
 */
abstract contract OwnableTwoSteps is IOwnableTwoSteps {
    /**
     * @notice Address of the current owner.
     */
    address public owner;

    /**
     * @notice Address of the potential owner.
     */
    address public potentialOwner;

    /**
     * @notice Ownership status.
     */
    Status public ownershipStatus;

    /**
     * @notice Modifier to wrap functions for contracts that inherit this contract.
     */
    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    /**
     * @notice Constructor
     * @param _owner The contract's owner
     */
    constructor(address _owner) {
        owner = _owner;
        emit NewOwner(_owner);
    }

    /**
     * @notice This function is used to cancel the ownership transfer.
     * @dev This function can be used for both cancelling a transfer to a new owner and
     *      cancelling the renouncement of the ownership.
     */
    function cancelOwnershipTransfer() external onlyOwner {
        Status _ownershipStatus = ownershipStatus;
        if (_ownershipStatus == Status.NoOngoingTransfer) {
            revert NoOngoingTransferInProgress();
        }

        if (_ownershipStatus == Status.TransferInProgress) {
            delete potentialOwner;
        }

        delete ownershipStatus;

        emit CancelOwnershipTransfer();
    }

    /**
     * @notice This function is used to confirm the ownership renouncement.
     */
    function confirmOwnershipRenouncement() external onlyOwner {
        if (ownershipStatus != Status.RenouncementInProgress) {
            revert RenouncementNotInProgress();
        }

        delete owner;
        delete ownershipStatus;

        emit NewOwner(address(0));
    }

    /**
     * @notice This function is used to confirm the ownership transfer.
     * @dev This function can only be called by the current potential owner.
     */
    function confirmOwnershipTransfer() external {
        if (ownershipStatus != Status.TransferInProgress) {
            revert TransferNotInProgress();
        }

        if (msg.sender != potentialOwner) {
            revert WrongPotentialOwner();
        }

        owner = msg.sender;
        delete ownershipStatus;
        delete potentialOwner;

        emit NewOwner(msg.sender);
    }

    /**
     * @notice This function is used to initiate the transfer of ownership to a new owner.
     * @param newPotentialOwner New potential owner address
     */
    function initiateOwnershipTransfer(address newPotentialOwner) external onlyOwner {
        if (ownershipStatus != Status.NoOngoingTransfer) {
            revert TransferAlreadyInProgress();
        }

        ownershipStatus = Status.TransferInProgress;
        potentialOwner = newPotentialOwner;

        /**
         * @dev This function can only be called by the owner, so msg.sender is the owner.
         *      We don't have to SLOAD the owner again.
         */
        emit InitiateOwnershipTransfer(msg.sender, newPotentialOwner);
    }

    /**
     * @notice This function is used to initiate the ownership renouncement.
     */
    function initiateOwnershipRenouncement() external onlyOwner {
        if (ownershipStatus != Status.NoOngoingTransfer) {
            revert TransferAlreadyInProgress();
        }

        ownershipStatus = Status.RenouncementInProgress;

        emit InitiateOwnershipRenouncement();
    }

    function _onlyOwner() private view {
        if (msg.sender != owner) revert NotOwner();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// Interfaces
import {IReentrancyGuard} from "./interfaces/IReentrancyGuard.sol";

/**
 * @title ReentrancyGuard
 * @notice This contract protects against reentrancy attacks.
 *         It is adjusted from OpenZeppelin.
 * @author LooksRare protocol team (👀,💎)
 */
abstract contract ReentrancyGuard is IReentrancyGuard {
    uint256 private _status;

    /**
     * @notice Modifier to wrap functions to prevent reentrancy calls.
     */
    modifier nonReentrant() {
        if (_status == 2) {
            revert ReentrancyFail();
        }

        _status = 2;
        _;
        _status = 1;
    }

    constructor() {
        _status = 1;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @notice It is emitted if the call recipient is not a contract.
 */
error NotAContract();

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @notice It is emitted if the ETH transfer fails.
 */
error ETHTransferFail();

/**
 * @notice It is emitted if the ERC20 approval fails.
 */
error ERC20ApprovalFail();

/**
 * @notice It is emitted if the ERC20 transfer fails.
 */
error ERC20TransferFail();

/**
 * @notice It is emitted if the ERC20 transferFrom fails.
 */
error ERC20TransferFromFail();

/**
 * @notice It is emitted if the ERC721 transferFrom fails.
 */
error ERC721TransferFromFail();

/**
 * @notice It is emitted if the ERC1155 safeTransferFrom fails.
 */
error ERC1155SafeTransferFromFail();

/**
 * @notice It is emitted if the ERC1155 safeBatchTransferFrom fails.
 */
error ERC1155SafeBatchTransferFromFail();

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @title IOwnableTwoSteps
 * @author LooksRare protocol team (👀,💎)
 */
interface IOwnableTwoSteps {
    /**
     * @notice This enum keeps track of the ownership status.
     * @param NoOngoingTransfer The default status when the owner is set
     * @param TransferInProgress The status when a transfer to a new owner is initialized
     * @param RenouncementInProgress The status when a transfer to address(0) is initialized
     */
    enum Status {
        NoOngoingTransfer,
        TransferInProgress,
        RenouncementInProgress
    }

    /**
     * @notice This is returned when there is no transfer of ownership in progress.
     */
    error NoOngoingTransferInProgress();

    /**
     * @notice This is returned when the caller is not the owner.
     */
    error NotOwner();

    /**
     * @notice This is returned when there is no renouncement in progress but
     *         the owner tries to validate the ownership renouncement.
     */
    error RenouncementNotInProgress();

    /**
     * @notice This is returned when the transfer is already in progress but the owner tries
     *         initiate a new ownership transfer.
     */
    error TransferAlreadyInProgress();

    /**
     * @notice This is returned when there is no ownership transfer in progress but the
     *         ownership change tries to be approved.
     */
    error TransferNotInProgress();

    /**
     * @notice This is returned when the ownership transfer is attempted to be validated by the
     *         a caller that is not the potential owner.
     */
    error WrongPotentialOwner();

    /**
     * @notice This is emitted if the ownership transfer is cancelled.
     */
    event CancelOwnershipTransfer();

    /**
     * @notice This is emitted if the ownership renouncement is initiated.
     */
    event InitiateOwnershipRenouncement();

    /**
     * @notice This is emitted if the ownership transfer is initiated.
     * @param previousOwner Previous/current owner
     * @param potentialOwner Potential/future owner
     */
    event InitiateOwnershipTransfer(address previousOwner, address potentialOwner);

    /**
     * @notice This is emitted when there is a new owner.
     */
    event NewOwner(address newOwner);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @title IReentrancyGuard
 * @author LooksRare protocol team (👀,💎)
 */
interface IReentrancyGuard {
    /**
     * @notice This is returned when there is a reentrant call.
     */
    error ReentrancyFail();
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IERC1155 {
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    event URI(string value, uint256 indexed id);

    function balanceOf(address account, uint256 id) external view returns (uint256);

    function balanceOfBatch(
        address[] calldata accounts,
        uint256[] calldata ids
    ) external view returns (uint256[] memory);

    function setApprovalForAll(address operator, bool approved) external;

    function isApprovedForAll(address account, address operator) external view returns (bool);

    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

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

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IERC721 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    function transferFrom(address from, address to, uint256 tokenId) external;

    function approve(address to, uint256 tokenId) external;

    function setApprovalForAll(address operator, bool _approved) external;

    function getApproved(uint256 tokenId) external view returns (address operator);

    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// Interfaces
import {IERC1155} from "../interfaces/generic/IERC1155.sol";

// Errors
import {ERC1155SafeTransferFromFail, ERC1155SafeBatchTransferFromFail} from "../errors/LowLevelErrors.sol";
import {NotAContract} from "../errors/GenericErrors.sol";

/**
 * @title LowLevelERC1155Transfer
 * @notice This contract contains low-level calls to transfer ERC1155 tokens.
 * @author LooksRare protocol team (👀,💎)
 */
contract LowLevelERC1155Transfer {
    /**
     * @notice Execute ERC1155 safeTransferFrom
     * @param collection Address of the collection
     * @param from Address of the sender
     * @param to Address of the recipient
     * @param tokenId tokenId to transfer
     * @param amount Amount to transfer
     */
    function _executeERC1155SafeTransferFrom(
        address collection,
        address from,
        address to,
        uint256 tokenId,
        uint256 amount
    ) internal {
        if (collection.code.length == 0) {
            revert NotAContract();
        }

        (bool status, ) = collection.call(abi.encodeCall(IERC1155.safeTransferFrom, (from, to, tokenId, amount, "")));

        if (!status) {
            revert ERC1155SafeTransferFromFail();
        }
    }

    /**
     * @notice Execute ERC1155 safeBatchTransferFrom
     * @param collection Address of the collection
     * @param from Address of the sender
     * @param to Address of the recipient
     * @param tokenIds Array of tokenIds to transfer
     * @param amounts Array of amounts to transfer
     */
    function _executeERC1155SafeBatchTransferFrom(
        address collection,
        address from,
        address to,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) internal {
        if (collection.code.length == 0) {
            revert NotAContract();
        }

        (bool status, ) = collection.call(
            abi.encodeCall(IERC1155.safeBatchTransferFrom, (from, to, tokenIds, amounts, ""))
        );

        if (!status) {
            revert ERC1155SafeBatchTransferFromFail();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// Interfaces
import {IERC20} from "../interfaces/generic/IERC20.sol";

// Errors
import {ERC20ApprovalFail} from "../errors/LowLevelErrors.sol";
import {NotAContract} from "../errors/GenericErrors.sol";

/**
 * @title LowLevelERC20Approve
 * @notice This contract contains low-level calls to approve ERC20 tokens.
 * @author LooksRare protocol team (👀,💎)
 */
contract LowLevelERC20Approve {
    /**
     * @notice Execute ERC20 approve
     * @param currency Currency address
     * @param to Operator address
     * @param amount Amount to approve
     */
    function _executeERC20Approve(address currency, address to, uint256 amount) internal {
        if (currency.code.length == 0) {
            revert NotAContract();
        }

        (bool status, bytes memory data) = currency.call(abi.encodeCall(IERC20.approve, (to, amount)));

        if (!status) {
            revert ERC20ApprovalFail();
        }

        if (data.length > 0) {
            if (!abi.decode(data, (bool))) {
                revert ERC20ApprovalFail();
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// Interfaces
import {IERC20} from "../interfaces/generic/IERC20.sol";

// Errors
import {ERC20TransferFail, ERC20TransferFromFail} from "../errors/LowLevelErrors.sol";
import {NotAContract} from "../errors/GenericErrors.sol";

/**
 * @title LowLevelERC20Transfer
 * @notice This contract contains low-level calls to transfer ERC20 tokens.
 * @author LooksRare protocol team (👀,💎)
 */
contract LowLevelERC20Transfer {
    /**
     * @notice Execute ERC20 transferFrom
     * @param currency Currency address
     * @param from Sender address
     * @param to Recipient address
     * @param amount Amount to transfer
     */
    function _executeERC20TransferFrom(address currency, address from, address to, uint256 amount) internal {
        if (currency.code.length == 0) {
            revert NotAContract();
        }

        (bool status, bytes memory data) = currency.call(abi.encodeCall(IERC20.transferFrom, (from, to, amount)));

        if (!status) {
            revert ERC20TransferFromFail();
        }

        if (data.length > 0) {
            if (!abi.decode(data, (bool))) {
                revert ERC20TransferFromFail();
            }
        }
    }

    /**
     * @notice Execute ERC20 (direct) transfer
     * @param currency Currency address
     * @param to Recipient address
     * @param amount Amount to transfer
     */
    function _executeERC20DirectTransfer(address currency, address to, uint256 amount) internal {
        if (currency.code.length == 0) {
            revert NotAContract();
        }

        (bool status, bytes memory data) = currency.call(abi.encodeCall(IERC20.transfer, (to, amount)));

        if (!status) {
            revert ERC20TransferFail();
        }

        if (data.length > 0) {
            if (!abi.decode(data, (bool))) {
                revert ERC20TransferFail();
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// Interfaces
import {IERC721} from "../interfaces/generic/IERC721.sol";

// Errors
import {ERC721TransferFromFail} from "../errors/LowLevelErrors.sol";
import {NotAContract} from "../errors/GenericErrors.sol";

/**
 * @title LowLevelERC721Transfer
 * @notice This contract contains low-level calls to transfer ERC721 tokens.
 * @author LooksRare protocol team (👀,💎)
 */
contract LowLevelERC721Transfer {
    /**
     * @notice Execute ERC721 transferFrom
     * @param collection Address of the collection
     * @param from Address of the sender
     * @param to Address of the recipient
     * @param tokenId tokenId to transfer
     */
    function _executeERC721TransferFrom(address collection, address from, address to, uint256 tokenId) internal {
        if (collection.code.length == 0) {
            revert NotAContract();
        }

        (bool status, ) = collection.call(abi.encodeCall(IERC721.transferFrom, (from, to, tokenId)));

        if (!status) {
            revert ERC721TransferFromFail();
        }
    }
}