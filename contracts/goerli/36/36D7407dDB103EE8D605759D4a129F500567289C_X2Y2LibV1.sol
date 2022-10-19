// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./X2Y2/structs.sol";

interface IX2Y2 {
    function run(
        RunInput memory input
    ) external;
}

error InvalidChain();

library X2Y2LibV1 {
    function _run(
        RunInput memory _input,
        uint256 _msgValue,
        bool _revertIfTrxFails
    ) external {
        bytes memory _data = abi.encodeWithSelector(
            IX2Y2.run.selector,
            _input
        );

        address X2Y2;
        if (block.chainid == 1) {
            // mainnet
            X2Y2 = 0x74312363e45DCaBA76c59ec49a7Aa8A65a67EeD3;
        } else if (block.chainid == 5 || block.chainid == 31337) {
            X2Y2 = 0x1891EcD5F7b1E751151d857265D6e6D08ae8989e;
        } else {
            revert InvalidChain();
        }

        (bool success, ) = X2Y2.call{ value: _msgValue }(_data);

        if (!success && _revertIfTrxFails) {
            // Copy revert reason from call
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./IERC20Upgradeable.sol";
import "./IDelegate.sol";

enum InvStatus {
    NEW,
    AUCTION,
    COMPLETE,
    CANCELLED,
    REFUNDED
}

enum Op {
    INVALID,
    // off-chain
    COMPLETE_SELL_OFFER,
    COMPLETE_BUY_OFFER,
    CANCEL_OFFER,
    // auction
    BID,
    COMPLETE_AUCTION,
    REFUND_AUCTION,
    REFUND_AUCTION_STUCK_ITEM
}

enum DelegationType {
    INVALID,
    ERC721,
    ERC1155
}

struct OrderItem {
    uint256 price;
    bytes data;
}

struct Order {
    uint256 salt;
    address user;
    uint256 network;
    uint256 intent;
    uint256 delegateType;
    uint256 deadline;
    IERC20Upgradeable currency;
    bytes dataMask;
    OrderItem[] items;
    // signature
    bytes32 r;
    bytes32 s;
    uint8 v;
    uint8 signVersion;
}

struct Fee {
    uint256 percentage;
    address to;
}

struct SettleDetail {
    Op op;
    uint256 orderIdx;
    uint256 itemIdx;
    uint256 price;
    bytes32 itemHash;
    IDelegate executionDelegate;
    bytes dataReplacement;
    uint256 bidIncentivePct;
    uint256 aucMinIncrementPct;
    uint256 aucIncDurationSecs;
    Fee[] fees;
}

struct SettleShared {
    uint256 salt;
    uint256 deadline;
    uint256 amountToEth;
    uint256 amountToWeth;
    address user;
    bool canFail;
}

struct RunInput {
    Order[] orders;
    SettleDetail[] details;
    SettleShared shared;
    // signature
    bytes32 r;
    bytes32 s;
    uint8 v;
}

struct OngoingAuction {
    uint256 price;
    uint256 netPrice;
    uint256 endAt;
    address bidder;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity >=0.8.4;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// SPDX-License-Identifier: Unlicensed

pragma solidity >=0.8.4;
pragma abicoder v2;

interface IDelegate {
    function delegateType() external view returns (uint256);

    function executeSell(
        address seller,
        address buyer,
        bytes calldata data
    ) external returns (bool);

    function executeBuy(
        address seller,
        address buyer,
        bytes calldata data
    ) external returns (bool);

    function executeBid(
        address seller,
        address previousBidder,
        address bidder,
        bytes calldata data
    ) external returns (bool);

    function executeAuctionComplete(
        address seller,
        address buyer,
        bytes calldata data
    ) external returns (bool);

    function executeAuctionRefund(
        address seller,
        address lastBidder,
        bytes calldata data
    ) external returns (bool);
}