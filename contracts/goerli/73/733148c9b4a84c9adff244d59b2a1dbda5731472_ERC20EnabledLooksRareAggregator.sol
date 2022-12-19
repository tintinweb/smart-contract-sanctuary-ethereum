// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {LowLevelERC20Transfer} from "@looksrare/contracts-libs/contracts/lowLevelCallers/LowLevelERC20Transfer.sol";
import {IERC20EnabledLooksRareAggregator} from "./interfaces/IERC20EnabledLooksRareAggregator.sol";
import {ILooksRareAggregator} from "./interfaces/ILooksRareAggregator.sol";
import {TokenTransfer} from "./libraries/OrderStructs.sol";

/**
 * @title ERC20EnabledLooksRareAggregator
 * @notice This contract allows NFT sweepers to buy NFTs from
 *         different marketplaces using ERC20 tokens by passing
 *         high-level structs + low-level bytes as calldata.
 * @author LooksRare protocol team (👀,💎)
 */
contract ERC20EnabledLooksRareAggregator is IERC20EnabledLooksRareAggregator, LowLevelERC20Transfer {
    ILooksRareAggregator public immutable aggregator;

    /**
     * @param _aggregator LooksRareAggregator's address
     */
    constructor(address _aggregator) {
        aggregator = ILooksRareAggregator(_aggregator);
    }

    /**
     * @inheritdoc IERC20EnabledLooksRareAggregator
     */
    function execute(
        TokenTransfer[] calldata tokenTransfers,
        ILooksRareAggregator.TradeData[] calldata tradeData,
        address recipient,
        bool isAtomic
    ) external payable {
        if (tokenTransfers.length == 0) revert UseLooksRareAggregatorDirectly();
        _pullERC20Tokens(tokenTransfers, msg.sender);
        aggregator.execute{value: msg.value}(tokenTransfers, tradeData, msg.sender, recipient, isAtomic);
    }

    function _pullERC20Tokens(TokenTransfer[] calldata tokenTransfers, address source) private {
        uint256 tokenTransfersLength = tokenTransfers.length;
        for (uint256 i; i < tokenTransfersLength; ) {
            _executeERC20TransferFrom(
                tokenTransfers[i].currency,
                source,
                address(aggregator),
                tokenTransfers[i].amount
            );
            unchecked {
                ++i;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {TokenTransfer} from "../libraries/OrderStructs.sol";
import {ILooksRareAggregator} from "./ILooksRareAggregator.sol";

interface IERC20EnabledLooksRareAggregator {
    /**
     * @notice Execute NFT sweeps in different marketplaces
     *         in a single transaction
     * @param tokenTransfers Aggregated ERC20 token transfers for all markets
     * @param tradeData Data object to be passed downstream to
     *                  each marketplace's proxy for execution
     * @param recipient The address to receive the purchased NFTs
     * @param isAtomic Flag to enable atomic trades (all or nothing)
     *                 or partial trades
     */
    function execute(
        TokenTransfer[] calldata tokenTransfers,
        ILooksRareAggregator.TradeData[] calldata tradeData,
        address recipient,
        bool isAtomic
    ) external payable;

    error UseLooksRareAggregatorDirectly();
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
     *                   hardcoded as msg.sender if it is called directly
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

enum CollectionType { ERC721, ERC1155 }

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
pragma solidity ^0.8.0;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import {IERC20} from "../interfaces/generic/IERC20.sol";

/**
 * @title LowLevelERC20Transfer
 * @notice This contract contains low-level calls to transfer ERC20 tokens.
 * @author LooksRare protocol team (👀,💎)
 */
contract LowLevelERC20Transfer {
    error ERC20TransferFail();
    error ERC20TransferFromFail();

    /**
     * @notice Execute ERC20 transferFrom
     * @param currency Currency address
     * @param from Sender address
     * @param to Recipient address
     * @param amount Amount to transfer
     */
    function _executeERC20TransferFrom(
        address currency,
        address from,
        address to,
        uint256 amount
    ) internal {
        (bool status, bytes memory data) = currency.call(
            abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, amount)
        );

        if (!status) revert ERC20TransferFromFail();
        if (data.length > 0) {
            if (!abi.decode(data, (bool))) revert ERC20TransferFromFail();
        }
    }

    /**
     * @notice Execute ERC20 (direct) transfer
     * @param currency Currency address
     * @param to Recipient address
     * @param amount Amount to transfer
     */
    function _executeERC20DirectTransfer(
        address currency,
        address to,
        uint256 amount
    ) internal {
        (bool status, bytes memory data) = currency.call(abi.encodeWithSelector(IERC20.transfer.selector, to, amount));

        if (!status) revert ERC20TransferFail();
        if (data.length > 0) {
            if (!abi.decode(data, (bool))) revert ERC20TransferFail();
        }
    }
}