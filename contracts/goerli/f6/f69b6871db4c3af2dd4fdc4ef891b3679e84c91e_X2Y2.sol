/**
 *Submitted for verification at Etherscan.io on 2022-11-10
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface IDelegate {}
interface IWETHUpgradable {}
interface IERC20Upgradeable {}

library Market {
  uint256 constant INTENT_SELL = 1;
  uint256 constant INTENT_AUCTION = 2;
  uint256 constant INTENT_BUY = 3;

  uint8 constant SIGN_V1 = 1;
  uint8 constant SIGN_V3 = 3;

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
    Market.Op op;
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
}

contract X2Y2 {

  function run(Market.RunInput memory input) public payable {}

}