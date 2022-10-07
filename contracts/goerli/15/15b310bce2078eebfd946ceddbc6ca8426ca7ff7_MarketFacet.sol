// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { TradingCommissions, MarketInfo, Modifiers, LibConstants, LibHelpers, LibObject } from "../AppStorage.sol";
import { LibMarket } from "../libs/LibMarket.sol";
import { LibFeeRouter } from "../libs/LibFeeRouter.sol";

import { ReentrancyGuard } from "../../../utils/ReentrancyGuard.sol";

/**
 * @title Matching Market (inspired by MakerOTC: https://github.com/nayms/maker-otc/blob/master/contracts/matching_market.sol)
 * @notice Trade entity tokens
 * @dev This should only be called through an entity, never directly by an EOA
 */
contract MarketFacet is Modifiers, ReentrancyGuard {
    /**
     * @notice Cancel offer #`_offerId`. This will cancel the offer so that it's no longer active.
     *
     * @dev This function can be frontrun: In the scenario where a user wants to cancel an unfavorable market offer, an attacker can potentially monitor and identify
     *       that the user has called this method, determine that filling this market offer is profitable, and as a result call executeLimitOffer with a higher gas price to have
     *       their transaction filled before the user can have cancelOffer filled. The most ideal situation for the user is to not have placed the unfavorable market offer
     *       in the first place since an attacker can always monitor our marketplace and potentially identify profitable market offers. Our UI will aide users in not placing
     *       market offers that are obviously unfavorable to the user and/or seem like mistake orders. In the event that a user needs to cancel an offer, it is recommended to
     *       use Flashbots in order to privately send your transaction so an attack cannot be triggered from monitoring the mempool for calls to cancelOffer. A user is recommended
     *       to change their RPC endpoint to point to https://rpc.flashbots.net when calling cancelOffer. We will add additional documentation to aide our users in this process.
     *       More information on using Flashbots: https://docs.flashbots.net/flashbots-protect/rpc/quick-start/
     *
     * @param _offerId offer ID
     */
    function cancelOffer(uint256 _offerId) external nonReentrant {
        require(s.offers[_offerId].state == LibConstants.OFFER_STATE_ACTIVE, "offer not active");
        bytes32 creator = LibMarket._getOffer(_offerId).creator;
        require(LibObject._getParent(LibHelpers._getIdForAddress(msg.sender)) == creator, "only creator can cancel");
        LibMarket._cancelOffer(_offerId);
    }

    /**
     * @notice Execute a limit offer.
     *
     * @param _sellToken Token to sell.
     * @param _sellAmount Amount to sell.
     * @param _buyToken Token to buy.
     * @param _buyAmount Amount to buy.
     * @return offerId_ returns >0 if a limit offer was created on the market because the offer couldn't be totally fulfilled immediately. In this case the return value is the created offer's id.
     * @return buyTokenCommissionsPaid_ The amount of the buy token paid as commissions on this particular order.
     * @return sellTokenCommissionsPaid_ The amount of the sell token paid as commissions on this particular order.
     */
    function executeLimitOffer(
        bytes32 _sellToken,
        uint256 _sellAmount,
        bytes32 _buyToken,
        uint256 _buyAmount
    )
        external
        nonReentrant
        returns (
            uint256 offerId_,
            uint256 buyTokenCommissionsPaid_,
            uint256 sellTokenCommissionsPaid_
        )
    {
        // Get the msg.sender's entityId. The parent is the entityId associated with the child, aka the msg.sender.
        // note: Only the entity associated with the msg.sender can make an offer on the market
        bytes32 parentId = LibObject._getParentFromAddress(msg.sender);
        return LibMarket._executeLimitOffer(parentId, _sellToken, _sellAmount, _buyToken, _buyAmount, LibConstants.FEE_SCHEDULE_STANDARD);
    }

    /**
     * @dev Get last created offer.
     *
     * @return offer id.
     */
    function getLastOfferId() external view returns (uint256) {
        return LibMarket._getLastOfferId();
    }

    /**
     * @notice Get current best offer for given token pair.
     *
     * @dev This means finding the highest sellToken-per-buyToken price, i.e. price = sellToken / buyToken
     *
     * @return offerId, or 0 if no current best is available.
     */
    function getBestOfferId(bytes32 _sellToken, bytes32 _buyToken) external view returns (uint256) {
        return LibMarket._getBestOfferId(_sellToken, _buyToken);
    }

    /**
     * @dev Get the details of the offer #`_offerId`
     * @param _offerId ID of a particular offer
     * @return _offerState details of the offer
     */
    function getOffer(uint256 _offerId) external view returns (MarketInfo memory _offerState) {
        return LibMarket._getOffer(_offerId);
    }

    /**
     * @dev Check if the offer #`_offerId` is active or not.
     * @param _offerId ID of a particular offer
     * @return active or not
     */
    function isActiveOffer(uint256 _offerId) external view returns (bool) {
        return LibMarket._isActiveOffer(_offerId);
    }

    /**
     * @dev Calculate the trading commissions based on a buy amount.
     * @param buyAmount The amount that the commissions payments are calculated from.
     * @return tc TradingCommissions struct todo
     */
    function calculateTradingCommissions(uint256 buyAmount) external view returns (TradingCommissions memory tc) {
        tc = LibFeeRouter._calculateTradingCommissions(buyAmount);
    }

    /**
     * @dev Get the basis points earned from trading commissions for Nayms Ltd.
     * @return bp Nayms Ltd commissions basis points
     */
    function getNaymsLtdBP() external view returns (uint256 bp) {
        bp = LibFeeRouter._getNaymsLtdBP();
    }

    /**
     * @dev Get the basis points earned from trading commissions for Nayms discretionary Fund.
     * @return bp Nayms Ltd commissions basis points
     */
    function getNDFBP() external view returns (uint256 bp) {
        bp = LibFeeRouter._getNDFBP();
    }

    /**
     * @dev Get the basis points earned from trading commissions for Nayms token stakers.
     * @return bp Nayms Ltd commissions basis points
     */
    function getSTMBP() external view returns (uint256 bp) {
        bp = LibFeeRouter._getSTMBP();
    }

    /**
     * @dev Get the basis points earned from trading commissions for the market maker.
     * @return bp Nayms Ltd commissions basis points
     */
    function getMakerBP() external view returns (uint256 bp) {
        bp = LibFeeRouter._getMakerBP();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

/// @notice storage for nayms v3 decentralized insurance platform

import "./interfaces/FreeStructs.sol";

import { LibMeta } from "../shared/libs/LibMeta.sol";

import { LibAdmin } from "./libs/LibAdmin.sol";
import { LibConstants } from "./libs/LibConstants.sol";
import { LibHelpers } from "./libs/LibHelpers.sol";
import { LibObject } from "./libs/LibObject.sol";

import { LibACL } from "./libs/LibACL.sol";

struct AppStorage {
    //// NAYMS ERC20 TOKEN ////
    mapping(address => uint256) nonces; //is this used?
    mapping(address => mapping(address => uint256)) allowance;
    uint256 totalSupply;
    mapping(bytes32 => bool) internalToken;
    mapping(address => uint256) balances;
    //// Object ////
    mapping(bytes32 => bool) existingObjects; // objectId => is an object?
    mapping(bytes32 => bytes32) objectParent; // objectId => parentId
    mapping(bytes32 => bytes32) objectDataHashes;
    mapping(bytes32 => bytes32) objectTokenSymbol;
    mapping(bytes32 => bool) existingEntities; // entityId => is an entity?
    mapping(bytes32 => bool) existingSimplePolicies; // simplePolicyId => is a simple policy?
    //// ENTITY ////
    mapping(bytes32 => Entity) entities; // objectId => Entity struct
    //// SIMPLE POLICY ////
    mapping(bytes32 => SimplePolicy) simplePolicies; // objectId => SimplePolicy struct
    // External Tokens
    // mapping(bytes32 => bool) externalTokens; // bytes32 ID of external token => is external token?
    mapping(address => bool) externalTokenSupported;
    address[] supportedExternalTokens;
    //// TokenizedObject ////
    mapping(bytes32 => mapping(bytes32 => uint256)) tokenBalances; // tokenId => (ownerId => balance)
    mapping(bytes32 => uint256) tokenSupply; // tokenId => Total Token Supply
    //    mapping(address => uint256) permitExternalDepositNonce; // Is this used?
    // limit to three when updating???

    //// Dividends ////
    uint8 maxDividendDenominations;
    mapping(bytes32 => bytes32[]) dividendDenominations; // object => tokenId of the dividend it allows
    mapping(bytes32 => mapping(bytes32 => uint8)) dividendDenominationIndex; // entity ID => (token ID => index of dividend denomination)
    mapping(bytes32 => mapping(uint8 => bytes32)) dividendDenominationAtIndex; // entity ID => (token ID => index of dividend denomination)
    mapping(bytes32 => mapping(bytes32 => uint256)) totalDividends; // token ID => (denomination ID => total dividend)
    mapping(bytes32 => mapping(bytes32 => mapping(bytes32 => uint256))) withdrawnDividendPerOwner; // entity => (tokenId => (owner => total withdrawn dividend)) NOT per share!!! this is TOTAL
    // // Keep track of the different dividends issued on chain
    // mapping(bytes32 => mapping(bytes32 => uint8)) issuedDividendsTokensIndex; // ownerId => dividendTokenId => index
    // mapping(bytes32 => mapping(uint8 => bytes32)) issuedDividendTokens; // ownerId => index => dividendTokenId
    // mapping(bytes32 => uint8) numIssuedDividends; //starts at 1. 0 means no dividends issued
    // //// DIVIDEND PAYOUT LOGIC ////
    // mapping(bytes32 => mapping(bytes32 => uint256)) divPerTokens; // entity ID => token ID => dividend per token ratio
    // mapping(bytes32 => mapping(bytes32 => EntityDividendInfo)) dividendInfos; // entity ID => token ID => dividend info

    // When a dividend is payed, you divide by the total supply and add it to the totalDividendPerToken
    // Dividends are held by the diamond contract LibHelpers._getIdForAddress(address(this))
    // When dividends are paid, they are transfered OUT of the diamond contract.
    //
    //
    // To calculate withdrawableDividiend = ownedTokens * totalDividendPerToken - totalWithdrawnDividendPerOwner
    //
    // When a dividend is collected you set the totalWithdrawnDividendPerOwner to the total amount the owner withdrew
    //
    // When you trasnsfer, you pay out all dividends to previous owner first, then transfer ownership
    // !!!YOU ALSO TRANSFER totalWithdrawnDividendPerOwner for those shares!!!
    // totalWithdrawnDividendPerOwner(for new owner) += numberOfSharesTransfered * totalDividendPerToken
    // totalWithdrawnDividendPerOwner(for previous owner) -= numberOfSharesTransfered * totalDividendPerToken (can be optimized)
    //
    // When minting
    // Add the token balance to the new owner
    // totalWithdrawnDividendPerOwner(for new owner) += numberOfSharesMinted * totalDividendPerToken
    //
    // When doing the division theser will be dust. Leave the dust in the diamond!!!

    //// ACL Configuration////
    mapping(bytes32 => mapping(bytes32 => bool)) groups; //role => (group => isRoleInGroup)
    mapping(bytes32 => bytes32) canAssign; //role => Group that can assign/unassign that role
    string[][] groupsConfig;
    string[][] canAssignConfig;
    //// User Data ////
    mapping(bytes32 => mapping(bytes32 => bytes32)) roles; // userId => (contextId => role)
    //// ACL Non Essential ////
    //these are only for user viewing. They can be removed.

    //// MARKET ////
    uint256 lastOfferId;
    mapping(uint256 => MarketInfo) offers; // offer Id => MarketInfo struct
    mapping(bytes32 => mapping(bytes32 => uint256)) bestOfferId; // sell token => buy token => best offer Id
    mapping(bytes32 => mapping(bytes32 => uint256)) span; // sell token => buy token => span
    ////  STAKING  ////
    mapping(bytes32 => LockedBalance) userLockedBalances; // userID => LockedBalance struct todo NOT YET READY TO BE REMOVED
    mapping(bytes32 => uint256) userLockedEndTime; // userID => locked end time
    mapping(uint256 => StakingCheckpoint) globalStakingCheckpointHistory; // epoch => StakingCheckpoint struct
    mapping(bytes32 => mapping(uint256 => StakingCheckpoint)) userStakingCheckpointHistory; // userID => epoch => StakingCheckpoint
    mapping(bytes32 => uint256) userStakingCheckpointEpoch; // userID => user_epoch
    mapping(uint256 => int128) stakingSlopeChanges; // timestamp => signed slope change
    uint256 stakingEpoch;
    // Keep track of the different tokens owned on chain
    mapping(bytes32 => mapping(bytes32 => uint8)) ownedTokenIndex; // ownerId => tokenId => index
    mapping(bytes32 => mapping(uint8 => bytes32)) ownedTokenAtIndex; // ownerId => index => tokenId
    mapping(bytes32 => uint8) numOwnedTokens; //starts at 1. 0 means no tokens owned
    // issuedDividendsIndex
    // issuedDividendsAtIndex
    // numIssuedDividends

    // mapping(ownerid => tokenid => index =) issuedDividends
    // mapping() numIssuedDividends //starts at 0

    ////
    //// FROM HERE ON, EVERYTHING IS DEPRECATED. MOVE TO USING THE SAME VARIABLE IN THE "Settings" STRUCTURE
    //// Use LibAdminFunctions._getSettings() to get the instance of settings you need
    ////

    // //// FEE BANK ////
    // bytes32 feeBankId;
    // bytes32 naymsLtdId;
    // bytes32 brokerFeeBankId; // the internal address that the fees all brokers have earned get distribuited to
    // bytes32 marketplaceBankId;
    // bytes32 dividendBankId;
    // bytes32 ndfBankId;
    ////  NDF  ////
    uint256 equilibriumLevel;
    uint256 actualDiscount;
    uint256 maxDiscount;
    uint256 actualNaymsAllocation;
    uint256 targetNaymsAllocation;
    address discountToken;
    uint24 poolFee;
    //// SSF ////
    uint256 rewardsCoefficient;
    mapping(bytes32 => uint256) userRewards;
    //// LP ////
    address lpAddress;
    ////  NAYMS  ////
    string wrappedTokenName;
    string wrappedTokenSymbol;
    uint8 wrappedTokenDecimals;
    address naymsToken; // represents the address key for this NAYMS token in AppStorage 1155 system
    bytes32 naymsTokenId; // represents the bytes32 key for this NAYMS token in AppStorage 1155 system
    //Token addresses for quotes and swaps
    address token0;
    address token1;
    //address token2;
    address pool;
    address uniswapFactory;
    /// Trading Commissions (all in basis points) ///
    uint16 tradingCommissionTotalBP; // the total amount that is deducted for trading commissions (BP)
    // The total commission above is further divided as follows:
    uint16 tradingCommissionNaymsLtdBP;
    uint16 tradingCommissionNDFBP;
    uint16 tradingCommissionSTMBP;
    uint16 tradingCommissionMakerBP;
    // Premium Commissions
    uint16 premiumCommissionNaymsLtdBP;
    uint16 premiumCommissionNDFBP;
    uint16 premiumCommissionSTMBP;
    // A policy can pay out additional commissions on premiums to entities having a variety of roles on the policy

    mapping(bytes32 => mapping(bytes32 => uint256)) marketLockedBalances; // to keep track of an owner's tokens that are on sale in the marketplace, ownerId => lockedTokenId => amount
}

library LibAppStorage {
    function diamondStorage() internal pure returns (AppStorage storage ds) {
        assembly {
            ds.slot := 0
        }
    }
}

contract Modifiers {
    AppStorage internal s;

    modifier assertSysAdmin() {
        require(
            LibACL._isInGroup(LibHelpers._getIdForAddress(LibMeta.msgSender()), LibAdmin._getSystemId(), LibHelpers._stringToBytes32(LibConstants.GROUP_SYSTEM_ADMINS)),
            "not a system admin"
        );
        _;
    }

    modifier assertSysMgr() {
        require(
            LibACL._isInGroup(LibHelpers._getIdForAddress(LibMeta.msgSender()), LibAdmin._getSystemId(), LibHelpers._stringToBytes32(LibConstants.GROUP_SYSTEM_MANAGERS)),
            "not a system manager"
        );
        _;
    }

    modifier assertEntityAdmin(bytes32 _context) {
        require(
            LibACL._isInGroup(LibHelpers._getIdForAddress(LibMeta.msgSender()), _context, LibHelpers._stringToBytes32(LibConstants.GROUP_ENTITY_ADMINS)),
            "not the entity's admin"
        );
        _;
    }

    modifier assertIsInGroup(
        bytes32 _objectId,
        bytes32 _contextId,
        bytes32 _group
    ) {
        require(LibACL._isInGroup(_objectId, _contextId, _group), "not in group");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { AppStorage, LibAppStorage, MarketInfo, TokenAmount, TradingCommissions } from "../AppStorage.sol";
import { LibHelpers } from "./LibHelpers.sol";
import { LibAdmin } from "./LibAdmin.sol";
import { LibTokenizedVault } from "./LibTokenizedVault.sol";
import { LibConstants } from "./LibConstants.sol";
import { LibFeeRouter } from "./LibFeeRouter.sol";

library LibMarket {
    /// @notice order has been added
    event OrderAdded(
        uint256 indexed orderId,
        bytes32 indexed maker,
        bytes32 indexed sellToken,
        uint256 sellAmount,
        uint256 sellAmountInitial,
        bytes32 buyToken,
        uint256 buyAmount,
        uint256 buyAmountInitial,
        uint256 state
    );

    /// @notice order has been executed
    event OrderExecuted(uint256 indexed orderId, bytes32 indexed taker, bytes32 indexed sellToken, uint256 sellAmount, bytes32 buyToken, uint256 buyAmount, uint256 state);

    /// @notice order has been canceled
    event OrderCancelled(uint256 indexed orderId, bytes32 indexed taker, bytes32 sellToken);

    struct MatchingOfferResult {
        uint256 remainingBuyAmount;
        uint256 remainingSellAmount;
        uint256 buyTokenCommissionsPaid;
        uint256 sellTokenCommissionsPaid;
    }

    function _getBestOfferId(bytes32 _sellToken, bytes32 _buyToken) internal view returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        return s.bestOfferId[_sellToken][_buyToken];
    }

    function _insertOfferIntoSortedList(uint256 _offerId) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        // check that offer is NOT in the sorted list
        require(!_isOfferInSortedList(_offerId), "offer already in sorted list");

        bytes32 sellToken = s.offers[_offerId].sellToken;
        bytes32 buyToken = s.offers[_offerId].buyToken;

        uint256 prevId;

        // find position of next highest offer
        uint256 top = s.bestOfferId[sellToken][buyToken];
        uint256 oldTop;

        while (top != 0 && _isOfferPricedLtOrEq(_offerId, top)) {
            oldTop = top;
            top = s.offers[top].rankPrev;
        }

        uint256 pos = oldTop;

        // insert offer at position
        if (pos != 0) {
            prevId = s.offers[pos].rankPrev;
            s.offers[pos].rankPrev = _offerId;
            s.offers[_offerId].rankNext = pos;
        }
        // else this is the new best offer, so insert at top
        else {
            prevId = s.bestOfferId[sellToken][buyToken];
            s.bestOfferId[sellToken][buyToken] = _offerId;
        }

        if (prevId != 0) {
            // requirement below is satisfied by statements above
            // require(!_isOfferPricedLtOrEq(_offerId, prevId));
            s.offers[prevId].rankNext = _offerId;
            s.offers[_offerId].rankPrev = prevId;
        }

        s.span[sellToken][buyToken]++;
    }

    function _removeOfferFromSortedList(uint256 _offerId) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        // check that offer is in the sorted list
        require(_isOfferInSortedList(_offerId), "offer not in sorted list");

        bytes32 sellToken = s.offers[_offerId].sellToken;
        bytes32 buyToken = s.offers[_offerId].buyToken;

        require(s.span[sellToken][buyToken] > 0, "token pair list does not exist");

        // if offer is not the highest offer
        if (_offerId != s.bestOfferId[sellToken][buyToken]) {
            uint256 nextId = s.offers[_offerId].rankNext;
            require(s.offers[nextId].rankPrev == _offerId, "sort check failed");
            s.offers[nextId].rankPrev = s.offers[_offerId].rankPrev;
        }
        // if offer is the highest offer
        else {
            s.bestOfferId[sellToken][buyToken] = s.offers[_offerId].rankPrev;
        }

        // if offer is not the lowest offer
        if (s.offers[_offerId].rankPrev != 0) {
            uint256 prevId = s.offers[_offerId].rankPrev;
            require(s.offers[prevId].rankNext == _offerId, "sort check failed");
            s.offers[prevId].rankNext = s.offers[_offerId].rankNext;
        }

        // nullify
        delete s.offers[_offerId].rankNext;
        delete s.offers[_offerId].rankPrev;

        s.span[sellToken][buyToken]--;
    }

    function _isOfferPricedLtOrEq(uint256 _lowOfferId, uint256 _highOfferId) internal view returns (bool) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        uint256 lowSellAmount = s.offers[_lowOfferId].sellAmount;
        uint256 lowBuyAmount = s.offers[_lowOfferId].buyAmount;

        uint256 highSellAmount = s.offers[_highOfferId].sellAmount;
        uint256 highBuyAmount = s.offers[_highOfferId].buyAmount;

        return lowBuyAmount * highSellAmount >= highBuyAmount * lowSellAmount;
    }

    function _isOfferInSortedList(uint256 _offerId) internal view returns (bool) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        bytes32 sellToken = s.offers[_offerId].sellToken;
        bytes32 buyToken = s.offers[_offerId].buyToken;

        return _offerId != 0 && (s.offers[_offerId].rankNext != 0 || s.offers[_offerId].rankPrev != 0 || s.bestOfferId[sellToken][buyToken] == _offerId);
    }

    function _matchToExistingOffers(
        bytes32 _fromEntityId,
        bytes32 _sellToken,
        uint256 _sellAmount,
        bytes32 _buyToken,
        uint256 _buyAmount
    ) internal returns (MatchingOfferResult memory result) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        result.remainingBuyAmount = _buyAmount;
        result.remainingSellAmount = _sellAmount;

        // _buyAmount == 0  means it's a market offer

        while (result.remainingSellAmount != 0) {
            // there is at least one offer stored for token pair
            uint256 bestOfferId = s.bestOfferId[_buyToken][_sellToken];
            if (bestOfferId == 0) {
                break;
            }

            uint256 bestBuyAmount = s.offers[bestOfferId].buyAmount;
            uint256 bestSellAmount = s.offers[bestOfferId].sellAmount;

            // check if price is better or same as the one taker is willing to pay, within error margin
            // Ugly hack to work around rounding errors. Based on the idea that
            // the furthest the amounts can stray from their "true" values is 1.
            // Ergo the worst case has `sellAmount` and `bestSellAmount` at +1 away from
            // their "correct" values and `bestBuyAmount` and `buyAmount` at -1.
            // Since (c - 1) * (d - 1) > (a + 1) * (b + 1) is equivalent to
            // c * d > a * b + a + b + c + d, we write...
            //
            // (For detailed breakdown see https://hiddentao.com/archives/2019/09/08/maker-otc-on-chain-orderbook-deep-dive)
            //
            if (
                bestBuyAmount * result.remainingBuyAmount >
                result.remainingSellAmount * bestSellAmount + bestBuyAmount + result.remainingBuyAmount + result.remainingSellAmount + bestSellAmount
            ) {
                break;
            }

            // ^ The `rounding` parameter is a compromise borne of a couple days of discussion.

            // avoid stack-too-deep
            {
                // do the buy
                uint256 finalSellAmount = bestBuyAmount < result.remainingSellAmount ? bestBuyAmount : result.remainingSellAmount;
                (uint256 nextBuyTokenCommissionsPaid, uint256 nextSellTokenCommissionsPaid) = _buy(bestOfferId, _fromEntityId, finalSellAmount);

                // Keep track of total commissions
                result.buyTokenCommissionsPaid += nextBuyTokenCommissionsPaid;
                result.sellTokenCommissionsPaid += nextSellTokenCommissionsPaid;

                // calculate how much is left to buy/sell
                uint256 sellAmountOld = result.remainingSellAmount;
                result.remainingSellAmount = result.remainingSellAmount - finalSellAmount;
                result.remainingBuyAmount = (result.remainingSellAmount * result.remainingBuyAmount) / sellAmountOld;
            }
        }
    }

    function _createOffer(
        bytes32 _creator,
        bytes32 _sellToken,
        uint256 _sellAmount,
        uint256 _sellAmountInitial,
        bytes32 _buyToken,
        uint256 _buyAmount,
        uint256 _buyAmountInitial,
        uint256 _feeSchedule
    ) internal returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        uint256 lastOfferId = ++s.lastOfferId;

        MarketInfo memory marketInfo = s.offers[lastOfferId];
        marketInfo.creator = _creator;
        marketInfo.sellToken = _sellToken;
        marketInfo.sellAmount = _sellAmount;
        marketInfo.sellAmountInitial = _sellAmountInitial;
        marketInfo.buyToken = _buyToken;
        marketInfo.buyAmount = _buyAmount;
        marketInfo.buyAmountInitial = _buyAmountInitial;
        marketInfo.feeSchedule = _feeSchedule;

        if (_sellAmount <= LibConstants.DUST) {
            marketInfo.state = LibConstants.OFFER_STATE_FULFILLED;
        } else {
            marketInfo.state = LibConstants.OFFER_STATE_ACTIVE;

            // lock tokens!
            s.marketLockedBalances[_creator][_sellToken] += _sellAmount;
        }

        s.offers[lastOfferId] = marketInfo;
        emit OrderAdded(lastOfferId, marketInfo.creator, _sellToken, _sellAmount, _sellAmountInitial, _buyToken, _buyAmount, _buyAmountInitial, marketInfo.state);

        return lastOfferId;
    }

    function _buy(
        uint256 _offerId,
        bytes32 _makerId,
        uint256 _requestedBuyAmount
    ) internal returns (uint256 buyTokenCommissionsPaid_, uint256 sellTokenCommissionsPaid_) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        // (a / b) * c = c * a / b  -> multiply first, to avoid underflow
        uint256 actualSellAmount = (_requestedBuyAmount * s.offers[_offerId].sellAmount) / s.offers[_offerId].buyAmount; // nWETH

        // check bounds and update balances
        _checkBoundsAndUpdateBalances(_offerId, actualSellAmount, _requestedBuyAmount);

        // Check before paying commissions
        if (s.offers[_offerId].feeSchedule == LibConstants.FEE_SCHEDULE_STANDARD) {
            // Fees are paid by the taker, maker pays no fees
            // Fees are paid only in external token
            // If the _buyToken is external, commissions are paid from _buyAmount in _buyToken.
            // If the _buyToken is internal and the _sellToken is external, commissions are paid from _sellAmount in _sellToken.
            if (LibAdmin._isSupportedExternalToken(s.offers[_offerId].buyToken)) {
                buyTokenCommissionsPaid_ = LibFeeRouter._payTradingCommissions(s.offers[_offerId].creator, _makerId, s.offers[_offerId].buyToken, _requestedBuyAmount);
            } else {
                sellTokenCommissionsPaid_ = LibFeeRouter._payTradingCommissions(s.offers[_offerId].creator, _makerId, s.offers[_offerId].sellToken, actualSellAmount);
            }
        }

        s.marketLockedBalances[s.offers[_offerId].creator][s.offers[_offerId].sellToken] -= actualSellAmount;

        LibTokenizedVault._internalTransfer(s.offers[_offerId].creator, _makerId, s.offers[_offerId].sellToken, actualSellAmount);
        LibTokenizedVault._internalTransfer(_makerId, s.offers[_offerId].creator, s.offers[_offerId].buyToken, _requestedBuyAmount);

        // cancel offer if it has become dust
        if (s.offers[_offerId].sellAmount < LibConstants.DUST) {
            s.offers[_offerId].state = LibConstants.OFFER_STATE_FULFILLED;
            _cancelOffer(_offerId);
        }

        emit OrderExecuted(
            _offerId,
            _makerId,
            s.offers[_offerId].sellToken,
            s.offers[_offerId].sellAmount,
            s.offers[_offerId].buyToken,
            s.offers[_offerId].buyAmount,
            s.offers[_offerId].state
        );
    }

    function _checkBoundsAndUpdateBalances(
        uint256 _offerId,
        uint256 _sellAmount,
        uint256 _buyAmount
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        (TokenAmount memory offerSell, TokenAmount memory offerBuy) = _getOfferTokenAmounts(_offerId);

        _assertAmounts(_sellAmount, _buyAmount);

        require(_buyAmount <= offerBuy.amount, "requested buy amount too large");
        require(_sellAmount <= offerSell.amount, "calculated sell amount too large");

        // update balances
        s.offers[_offerId].sellAmount = offerSell.amount - _sellAmount;
        s.offers[_offerId].buyAmount = offerBuy.amount - _buyAmount;
    }

    function _cancelOffer(uint256 _offerId) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        if (_isOfferInSortedList(_offerId)) {
            _removeOfferFromSortedList(_offerId);
        }

        MarketInfo memory marketInfo = s.offers[_offerId];

        // unlock the remaining sell amount back to creator
        if (marketInfo.sellAmount > 0) {
            // note nothing is transferred since tokens for sale are UN-escrowed. Just unlock!
            s.marketLockedBalances[s.offers[_offerId].creator][s.offers[_offerId].sellToken] -= marketInfo.sellAmount;
        }

        // don't emit event stating market order is canceled if the market order was executed and fulfilled
        if (marketInfo.state != LibConstants.OFFER_STATE_FULFILLED) {
            s.offers[_offerId].state = LibConstants.OFFER_STATE_CANCELLED;
            emit OrderCancelled(_offerId, marketInfo.creator, marketInfo.sellToken);
        }
    }

    function _assertAmounts(uint256 _sellAmount, uint256 _buyAmount) internal pure {
        require(uint128(_sellAmount) == _sellAmount, "sell amount exceeds uint128 limit");
        require(uint128(_buyAmount) == _buyAmount, "buy amount exceeds uint128 limit");
        require(_sellAmount > 0, "sell amount must be >0");
        require(_buyAmount > 0, "buy amount must be >0");
    }

    function _assertValidOffer(
        bytes32 _entityId,
        bytes32 _sellToken,
        uint256 _sellAmount,
        bytes32 _buyToken,
        uint256 _buyAmount,
        uint256 _feeSchedule
    ) internal view {
        AppStorage storage s = LibAppStorage.diamondStorage();

        require(_entityId != 0 && s.existingEntities[_entityId], "must belong to entity to make an offer");

        bool sellTokenIsEntity = s.existingEntities[_sellToken];
        bool sellTokenIsSupported = s.externalTokenSupported[LibHelpers._getAddressFromId(_sellToken)];
        bool buyTokenIsEntity = s.existingEntities[_buyToken];
        bool buyTokenIsSupported = s.externalTokenSupported[LibHelpers._getAddressFromId(_buyToken)];

        _assertAmounts(_sellAmount, _buyAmount);

        require(sellTokenIsEntity || sellTokenIsSupported, "sell token must be valid");
        require(buyTokenIsEntity || buyTokenIsSupported, "buy token must be valid");
        require(_sellToken != _buyToken, "cannot sell and buy same token");
        require((sellTokenIsEntity && buyTokenIsSupported) || (sellTokenIsSupported && buyTokenIsEntity), "must be one platform token");

        // note: add restriction to not be able to sell tokens that are already for sale
        // maker must own sell amount and it must not be locked
        require(s.tokenBalances[_sellToken][_entityId] - s.marketLockedBalances[_entityId][_sellToken] >= _sellAmount, "tokens locked in market");

        // must have a valid fee schedule
        require(_feeSchedule == LibConstants.FEE_SCHEDULE_PLATFORM_ACTION || _feeSchedule == LibConstants.FEE_SCHEDULE_STANDARD, "fee schedule invalid");
    }

    function _getOfferTokenAmounts(uint256 _offerId) internal view returns (TokenAmount memory sell_, TokenAmount memory buy_) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        sell_.token = s.offers[_offerId].sellToken;
        sell_.amount = s.offers[_offerId].sellAmount;
        buy_.token = s.offers[_offerId].buyToken;
        buy_.amount = s.offers[_offerId].buyAmount;
    }

    function _executeLimitOffer(
        bytes32 _creator,
        bytes32 _sellToken,
        uint256 _sellAmount,
        bytes32 _buyToken,
        uint256 _buyAmount,
        uint256 _feeSchedule
    )
        internal
        returns (
            uint256 offerId_,
            uint256 buyTokenCommissionsPaid_,
            uint256 sellTokenCommissionsPaid_
        )
    {
        _assertValidOffer(_creator, _sellToken, _sellAmount, _buyToken, _buyAmount, _feeSchedule);

        MatchingOfferResult memory result = _matchToExistingOffers(_creator, _sellToken, _sellAmount, _buyToken, _buyAmount);
        buyTokenCommissionsPaid_ = result.buyTokenCommissionsPaid;
        sellTokenCommissionsPaid_ = result.sellTokenCommissionsPaid;

        offerId_ = _createOffer(_creator, _sellToken, result.remainingSellAmount, _sellAmount, _buyToken, result.remainingBuyAmount, _buyAmount, _feeSchedule);

        // if still some left
        if (result.remainingBuyAmount > 0 && result.remainingSellAmount > 0 && result.remainingSellAmount >= LibConstants.DUST) {
            // ensure it's in the right position in the list
            _insertOfferIntoSortedList(offerId_);
        }
    }

    function _getOffer(uint256 _offerId) internal view returns (MarketInfo memory _offerState) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.offers[_offerId];
    }

    function _getLastOfferId() internal view returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.lastOfferId;
    }

    function _isActiveOffer(uint256 _offerId) internal view returns (bool) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.offers[_offerId].state == LibConstants.OFFER_STATE_ACTIVE;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { AppStorage, LibAppStorage, SimplePolicy, TokenAmount, TradingCommissions } from "../AppStorage.sol";
import { LibHelpers } from "../libs/LibHelpers.sol";
import { LibObject } from "../libs/LibObject.sol";
import { LibConstants } from "../libs/LibConstants.sol";
import { LibTokenizedVault } from "../libs/LibTokenizedVault.sol";

library LibFeeRouter {
    event DistributeFees(address operator, uint256 totalFeesDistributed);
    event RecordDividend(bytes32 entityId, bytes32 dividendDenomination, uint256 amount);

    function _payPremiumCommissions(bytes32 _policyId, uint256 _premiumPaid) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        SimplePolicy memory simplePolicy = s.simplePolicies[_policyId];

        bytes32 policyEntityId = LibObject._getParent(_policyId);

        uint256 commissionsCount = simplePolicy.commissionReceivers.length;
        for (uint256 i = 0; i < commissionsCount; i++) {
            uint256 commission = (_premiumPaid * simplePolicy.commissionBasisPoints[i]) / 1000;
            LibTokenizedVault._internalTransfer(policyEntityId, simplePolicy.commissionReceivers[i], simplePolicy.asset, commission);
        }

        uint256 commissionNaymsLtd = (_premiumPaid * s.premiumCommissionNaymsLtdBP) / 1000;
        uint256 commissionNDF = (_premiumPaid * s.premiumCommissionNDFBP) / 1000;
        uint256 commissionSTM = (_premiumPaid * s.premiumCommissionSTMBP) / 1000;
        LibTokenizedVault._internalTransfer(policyEntityId, LibHelpers._stringToBytes32(LibConstants.NAYMS_LTD_IDENTIFIER), simplePolicy.asset, commissionNaymsLtd);
        LibTokenizedVault._internalTransfer(policyEntityId, LibHelpers._stringToBytes32(LibConstants.NDF_IDENTIFIER), simplePolicy.asset, commissionNDF);
        LibTokenizedVault._internalTransfer(policyEntityId, LibHelpers._stringToBytes32(LibConstants.STM_IDENTIFIER), simplePolicy.asset, commissionSTM);
    }

    function _payTradingCommissions(
        bytes32 _makerId,
        bytes32 _takerId,
        bytes32 _tokenId,
        uint256 _requestedBuyAmount
    ) internal returns (uint256 commissionPaid_) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(s.tradingCommissionNaymsLtdBP + s.tradingCommissionNDFBP + s.tradingCommissionSTMBP + s.tradingCommissionMakerBP <= 1000, "commissions sum over 1000 bp");
        require(s.tradingCommissionTotalBP <= 1000, "commission total must be<1000bp");

        TradingCommissions memory tc = _calculateTradingCommissions(_requestedBuyAmount);
        // The rough commission deducted. The actual total might be different due to integer division

        // Pay Nayms, LTD commission
        LibTokenizedVault._internalTransfer(_takerId, LibHelpers._stringToBytes32(LibConstants.NAYMS_LTD_IDENTIFIER), _tokenId, tc.commissionNaymsLtd);

        // Pay Nayms Discretionsry Fund commission
        LibTokenizedVault._internalTransfer(_takerId, LibHelpers._stringToBytes32(LibConstants.NDF_IDENTIFIER), _tokenId, tc.commissionNDF);

        // Pay Staking Mechanism commission
        LibTokenizedVault._internalTransfer(_takerId, LibHelpers._stringToBytes32(LibConstants.STM_IDENTIFIER), _tokenId, tc.commissionSTM);

        // Pay market maker commission
        LibTokenizedVault._internalTransfer(_takerId, _makerId, _tokenId, tc.commissionMaker);

        // Work it out again so the math is precise, ignoring remainers
        commissionPaid_ = tc.totalCommissions;
    }

    function _calculateTradingCommissions(uint256 buyAmount) internal view returns (TradingCommissions memory tc) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        // The rough commission deducted. The actual total might be different due to integer division
        tc.roughCommissionPaid = (s.tradingCommissionTotalBP * buyAmount) / 1000;

        // Pay Nayms, LTD commission
        tc.commissionNaymsLtd = (s.tradingCommissionNaymsLtdBP * tc.roughCommissionPaid) / 1000;

        // Pay Nayms Discretionsry Fund commission
        tc.commissionNDF = (s.tradingCommissionNDFBP * tc.roughCommissionPaid) / 1000;

        // Pay Staking Mechanism commission
        tc.commissionSTM = (s.tradingCommissionSTMBP * tc.roughCommissionPaid) / 1000;

        // Pay market maker commission
        tc.commissionMaker = (s.tradingCommissionMakerBP * tc.roughCommissionPaid) / 1000;

        // Work it out again so the math is precise, ignoring remainers
        tc.totalCommissions = tc.commissionNaymsLtd + tc.commissionNDF + tc.commissionSTM + tc.commissionMaker;
    }

    function _getNaymsLtdBP() internal view returns (uint256 bp) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        bp = s.tradingCommissionNaymsLtdBP;
    }

    function _getNDFBP() internal view returns (uint256 bp) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        bp = s.tradingCommissionNDFBP;
    }

    function _getSTMBP() internal view returns (uint256 bp) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        bp = s.tradingCommissionSTMBP;
    }

    function _getMakerBP() internal view returns (uint256 bp) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        bp = s.tradingCommissionMakerBP;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

// From OpenZeppellin: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status = _NOT_ENTERED;

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

struct MarketInfo {
    bytes32 creator; // entity ID
    bytes32 sellToken;
    uint256 sellAmount;
    uint256 sellAmountInitial;
    bytes32 buyToken;
    uint256 buyAmount;
    uint256 buyAmountInitial;
    // uint256 averagePrice;
    uint256 feeSchedule;
    uint256 state;
    uint256 rankNext;
    uint256 rankPrev;
}

struct TokenAmount {
    bytes32 token;
    uint256 amount;
}

struct MultiToken {
    string tokenUri;
    // kp NOTE todo: what is this struct for?
    mapping(uint256 => mapping(bytes32 => uint256)) tokenBalances; // token ID to account balance
    mapping(bytes32 => mapping(bytes32 => bool)) tokenOpApprovals; // account to operator approvals
}

/**
 * @param maxCapacity Maxmimum allowable amount of capacity that an entity is given. Denominated by assetId.
 * @param utilizedCapacity The utilized capacity of the entity. Denominated by assetId.
 */
struct Entity {
    bytes32 assetId;
    uint256 collateralRatio;
    uint256 maxCapacity;
    uint256 utilizedCapacity;
    bool simplePolicyEnabled;
}

struct SimplePolicy {
    uint256 startDate;
    uint256 maturationDate;
    bytes32 asset;
    uint256 limit;
    bool fundsLocked;
    uint256 claimsPaid;
    uint256 premiumsPaid;
    bytes32[] commissionReceivers;
    uint256[] commissionBasisPoints;
    uint256 sponsorCommissionBasisPoints; //underwriter is parent
}

struct Stakeholders {
    bytes32[] roles;
    bytes32[] entityIds;
    bytes[] signatures;
}

// Used in StakingFacet
struct LockedBalance {
    uint256 amount;
    uint256 endTime;
}

struct StakingCheckpoint {
    int128 bias;
    int128 slope; // - dweight / dt
    uint256 ts; // timestamp
    uint256 blk; // block number
}

struct FeeRatio {
    uint256 brokerShareRatio;
    uint256 naymsLtdShareRatio;
    uint256 ndfShareRatio;
}

struct TradingCommissions {
    uint256 roughCommissionPaid;
    uint256 commissionNaymsLtd;
    uint256 commissionNDF;
    uint256 commissionSTM;
    uint256 commissionMaker;
    uint256 totalCommissions;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

library LibMeta {
    function msgSender() internal view returns (address sender_) {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender_ := and(mload(add(array, index)), 0xffffffffffffffffffffffffffffffffffffffff)
            }
        } else {
            sender_ = msg.sender;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { AppStorage, LibAppStorage } from "../AppStorage.sol";
import { LibConstants } from "../libs/LibConstants.sol";
import { LibHelpers } from "../libs/LibHelpers.sol";
import { LibObject } from "../libs/LibObject.sol";

library LibAdmin {
    event BalanceUpdated(uint256 oldBalance, uint256 newBalance);
    event EquilibriumLevelUpdated(uint256 oldLevel, uint256 newLevel);
    event MaxDividendDenominationsUpdated(uint8 oldMax, uint8 newMax);
    event MaxDiscountUpdated(uint256 oldDiscount, uint256 newDiscount);
    event TargetNaymsAllocationUpdated(uint256 oldTarget, uint256 newTarget);
    event DiscountTokenUpdated(address oldToken, address newToken);
    event PoolFeeUpdated(uint256 oldFee, uint256 newFee);
    event CoefficientUpdated(uint256 oldCoefficient, uint256 newCoefficient);
    event RoleGroupUpdated(string role, string group, bool roleInGroup);
    event RoleCanAssignUpdated(string role, string group);
    event SupportedTokenAdded(address tokenAddress);

    function _getSystemId() internal pure returns (bytes32) {
        return LibHelpers._stringToBytes32(LibConstants.SYSTEM_IDENTIFIER);
    }

    function _getEmptyId() internal pure returns (bytes32) {
        return LibHelpers._stringToBytes32(LibConstants.EMPTY_IDENTIFIER);
    }

    function _updateMaxDividendDenominations(uint8 _newMaxDividendDenominations) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(_newMaxDividendDenominations > s.maxDividendDenominations, "_updateMaxDividendDenominations: cannot reduce");
        uint8 old = s.maxDividendDenominations;
        s.maxDividendDenominations = _newMaxDividendDenominations;

        emit MaxDividendDenominationsUpdated(old, _newMaxDividendDenominations);
    }

    function _getMaxDividendDenominations() internal view returns (uint8) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.maxDividendDenominations;
    }

    function _setEquilibriumLevel(uint256 _newLevel) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 oldLevel = s.equilibriumLevel;
        s.equilibriumLevel = _newLevel;

        emit EquilibriumLevelUpdated(oldLevel, _newLevel);
    }

    function _setMaxDiscount(uint256 _newDiscount) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 oldDiscount = s.maxDiscount;
        s.maxDiscount = _newDiscount;

        emit MaxDiscountUpdated(oldDiscount, _newDiscount);
    }

    function _setTargetNaymsAllocation(uint256 _newTarget) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 oldTarget = s.targetNaymsAllocation;
        s.targetNaymsAllocation = _newTarget;

        emit TargetNaymsAllocationUpdated(oldTarget, _newTarget);
    }

    function _setDiscountToken(address _newToken) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        address oldToken = s.discountToken;
        s.discountToken = _newToken;

        emit DiscountTokenUpdated(oldToken, _newToken);
    }

    function _setPoolFee(uint24 _newFee) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 oldFee = s.poolFee;
        s.poolFee = _newFee;

        emit PoolFeeUpdated(oldFee, _newFee);
    }

    function _setCoefficient(uint256 _newCoefficient) internal {
        require(_newCoefficient <= 1000, "Coefficient too high");

        AppStorage storage s = LibAppStorage.diamondStorage();

        uint256 oldCoefficient = s.rewardsCoefficient;

        s.rewardsCoefficient = _newCoefficient;

        emit CoefficientUpdated(oldCoefficient, s.rewardsCoefficient);
    }

    function _updateRoleAssigner(string memory _role, string memory _assignerGroup) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        s.canAssign[LibHelpers._stringToBytes32(_role)] = LibHelpers._stringToBytes32(_assignerGroup);
        emit RoleCanAssignUpdated(_role, _assignerGroup);
    }

    function _updateRoleGroup(
        string memory _role,
        string memory _group,
        bool _roleInGroup
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        s.groups[LibHelpers._stringToBytes32(_role)][LibHelpers._stringToBytes32(_group)] = _roleInGroup;
        emit RoleGroupUpdated(_role, _group, _roleInGroup);
    }

    function _isSupportedExternalToken(bytes32 _tokenId) internal view returns (bool) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.externalTokenSupported[LibHelpers._getAddressFromId(_tokenId)];
    }

    function _addSupportedExternalToken(address _tokenAddress) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        bool alreadyAdded;
        s.externalTokenSupported[_tokenAddress] = true;

        // Supported tokens cannot be removed because they may exist in the system!
        for (uint256 i = 0; i < s.supportedExternalTokens.length; i++) {
            if (s.supportedExternalTokens[i] == _tokenAddress) {
                alreadyAdded = true;
                break;
            }
        }
        if (!alreadyAdded) {
            LibObject._createObject(LibHelpers._getIdForAddress(_tokenAddress));
            s.supportedExternalTokens.push(_tokenAddress);

            emit SupportedTokenAdded(_tokenAddress);
        }
    }

    function _getSupportedExternalTokens() internal view returns (address[] memory) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        // Supported tokens cannot be removed because they may exist in the system!
        return s.supportedExternalTokens;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { LibHelpers } from "./LibHelpers.sol";

/**
 * @dev Settings keys.
 */
library LibConstants {
    //Reserved IDs
    string internal constant EMPTY_IDENTIFIER = "";
    string internal constant SYSTEM_IDENTIFIER = "System";
    string internal constant NDF_IDENTIFIER = "NDF";
    string internal constant STM_IDENTIFIER = "Staking Mechanism";
    string internal constant SSF_IDENTIFIER = "SSF";
    string internal constant NAYM_TOKEN_IDENTIFIER = "NAYM"; //This is the ID in the system as well as the token ID
    string internal constant DIVIDEND_BANK_IDENTIFIER = "Dividend Bank"; //This will hold all the dividends
    string internal constant NAYMS_LTD_IDENTIFIER = "Nayms Ltd";

    //Roles
    string internal constant ROLE_SYSTEM_ADMIN = "System Admin";
    string internal constant ROLE_SYSTEM_MANAGER = "System Manager";
    string internal constant ROLE_ENTITY_ADMIN = "Entity Admin";
    string internal constant ROLE_ENTITY_MANAGER = "Entity Manager";
    string internal constant ROLE_BROKER = "Broker";
    string internal constant ROLE_INSURED_PARTY = "Insured";
    string internal constant ROLE_UNDERWRITER = "Underwriter";
    string internal constant ROLE_CAPITAL_PROVIDER = "Capital Provider";
    string internal constant ROLE_CLAIMS_ADMIN = "Claims Admin";
    string internal constant ROLE_TRADER = "Trader";

    //Groups
    string internal constant GROUP_SYSTEM_ADMINS = "System Admins";
    string internal constant GROUP_SYSTEM_MANAGERS = "System Managers";
    string internal constant GROUP_ENTITY_ADMINS = "Entity Admins";
    string internal constant GROUP_ENTITY_MANAGERS = "Entity Managers";
    string internal constant GROUP_APPROVED_USERS = "Approved Users";
    string internal constant GROUP_BROKERS = "Brokers";
    string internal constant GROUP_INSURED_PARTIES = "Insured Parties";
    string internal constant GROUP_UNDERWRITERS = "Underwriters";
    string internal constant GROUP_CAPITAL_PROVIDERS = "Capital Providers";
    string internal constant GROUP_CLAIMS_ADMINS = "Claims Admins";
    string internal constant GROUP_TRADERS = "Traders";

    /*///////////////////////////////////////////////////////////////////////////
                        Market Fee Schedules
    ///////////////////////////////////////////////////////////////////////////*/

    /**
     * @dev Standard fee is charged.
     */
    uint256 internal constant FEE_SCHEDULE_STANDARD = 1;
    /**
     * @dev Platform-initiated trade, e.g. token sale or buyback.
     */
    uint256 internal constant FEE_SCHEDULE_PLATFORM_ACTION = 2;

    /*///////////////////////////////////////////////////////////////////////////
                        MARKET OFFER STATES
    ///////////////////////////////////////////////////////////////////////////*/

    uint256 internal constant OFFER_STATE_ACTIVE = 1;
    uint256 internal constant OFFER_STATE_CANCELLED = 2;
    uint256 internal constant OFFER_STATE_FULFILLED = 3;

    uint256 internal constant DUST = 1;

    /*///////////////////////////////////////////////////////////////////////////
                        SIMPLE POLICY STATES
    ///////////////////////////////////////////////////////////////////////////*/

    uint256 internal constant SIMPLE_POLICY_STATE_CREATED = 0;
    uint256 internal constant SIMPLE_POLICY_STATE_APPROVED = 1;
    uint256 internal constant SIMPLE_POLICY_STATE_ACTIVE = 2;
    uint256 internal constant SIMPLE_POLICY_STATE_MATURED = 3;
    uint256 internal constant SIMPLE_POLICY_STATE_CANCELLED = 4;
    uint256 internal constant STAKING_WEEK = 7 days;
    uint256 internal constant STAKING_MINTIME = 60 days; // 60 days min lock
    uint256 internal constant STAKING_MAXTIME = 4 * 365 days; // 4 years max lock
    uint256 internal constant SCALE = 1e18; //10 ^ 18

    /// _depositFor Types for events
    int128 internal constant STAKING_DEPOSIT_FOR_TYPE = 0;
    int128 internal constant STAKING_CREATE_LOCK_TYPE = 1;
    int128 internal constant STAKING_INCREASE_LOCK_AMOUNT = 2;
    int128 internal constant STAKING_INCREASE_UNLOCK_TIME = 3;

    string internal constant VE_NAYM_NAME = "veNAYM";
    string internal constant VE_NAYM_SYMBOL = "veNAYM";
    uint8 internal constant VE_NAYM_DECIMALS = 18;
    uint8 internal constant INTERNAL_TOKEN_DECIMALS = 18;
    address internal constant DAI_CONSTANT = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

/// @notice Pure functions
library LibHelpers {
    function _getIdForObjectAtIndex(uint256 _index) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_index));
    }

    function _getIdForAddress(address _addr) internal pure returns (bytes32) {
        return bytes32(bytes20(_addr));
    }

    function _getSenderId() internal view returns (bytes32) {
        return _getIdForAddress(msg.sender);
    }

    function _getAddressFromId(bytes32 _id) internal pure returns (address) {
        return address(bytes20(_id));
    }

    // Conversion Utilities

    function _addressToBytes32(address addr) internal pure returns (bytes32 result) {
        return _bytesToBytes32(abi.encode(addr));
    }

    function _stringToBytes32(string memory strIn) internal pure returns (bytes32 result) {
        return _bytesToBytes32(bytes(strIn));
    }

    function _bytes32ToString(bytes32 bytesIn) internal pure returns (string memory) {
        return string(_bytes32ToBytes(bytesIn));
    }

    function _bytesToBytes32(bytes memory source) internal pure returns (bytes32 result) {
        if (source.length == 0) {
            return 0x0;
        }
        assembly {
            result := mload(add(source, 32))
        }
    }

    function _bytes32ToBytes(bytes32 input) internal pure returns (bytes memory) {
        bytes memory b = new bytes(32);
        assembly {
            mstore(add(b, 32), input)
        }
        return b;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { AppStorage, LibAppStorage } from "../AppStorage.sol";
import { LibHelpers } from "./LibHelpers.sol";
import { LibAdmin } from "./LibAdmin.sol";

/// @notice Contains internal methods for core Nayms system functionality
library LibObject {
    function _createObject(
        bytes32 _objectId,
        bytes32 _parentId,
        bytes32 _dataHash
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        // check if the id has been used (has a parent account associated with it) and revert if it has
        require(!s.existingObjects[_objectId], "object already exists");

        s.existingObjects[_objectId] = true;
        s.objectParent[_objectId] = _parentId;
        s.objectDataHashes[_objectId] = _dataHash;
    }

    function _createObject(bytes32 _objectId, bytes32 _dataHash) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        require(!s.existingObjects[_objectId], "object already exists");

        s.existingObjects[_objectId] = true;
        s.objectDataHashes[_objectId] = _dataHash;
    }

    function _createObject(bytes32 _objectId) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        require(!s.existingObjects[_objectId], "object already exists");

        s.existingObjects[_objectId] = true;
    }

    function _setDataHash(bytes32 _objectId, bytes32 _dataHash) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        require(s.existingObjects[_objectId], "setDataHash: object doesn't exist");
        s.objectDataHashes[_objectId] = _dataHash;
    }

    function _getDataHash(bytes32 _objectId) internal view returns (bytes32 objectDataHash) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.objectDataHashes[_objectId];
    }

    function _getParent(bytes32 _objectId) internal view returns (bytes32) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.objectParent[_objectId];
    }

    function _getParentFromAddress(address addr) internal view returns (bytes32) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        bytes32 objectId = LibHelpers._getIdForAddress(addr);
        return s.objectParent[objectId];
    }

    function _setParent(bytes32 _objectId, bytes32 _parentId) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        s.objectParent[_objectId] = _parentId;
    }

    function _isObjectTokenizable(bytes32 _objectId) internal view returns (bool) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return (s.objectTokenSymbol[_objectId] != LibAdmin._getEmptyId());
    }

    function _enableObjectTokenization(bytes32 _objectId, string memory _symbol) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(bytes(_symbol).length < 16, "symbol more than 16 characters");
        require(s.objectTokenSymbol[_objectId] == LibAdmin._getEmptyId(), "object already tokenized");

        s.objectTokenSymbol[_objectId] = LibHelpers._stringToBytes32(_symbol);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { AppStorage, LibAppStorage, Modifiers } from "../AppStorage.sol";
import { LibHelpers } from "./LibHelpers.sol";
import { LibAdmin } from "./LibAdmin.sol";
import { LibObject } from "./LibObject.sol";

library LibACL {
    /**
     * @dev Emitted when a role gets updated. Empty roleId is assigned upon role removal
     * @param objectId The user or object that was assigned the role.
     * @param contextId The context where the role was assigned to.
     * @param roleId The ID of the role which got unassigned. (empty ID when unassigned)
     * @param functionName The function performing the action
     */
    event RoleUpdate(bytes32 indexed objectId, bytes32 contextId, bytes32 roleId, string functionName);

    function _assignRole(
        bytes32 _objectId,
        bytes32 _contextId,
        bytes32 _roleId
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        s.roles[_objectId][_contextId] = _roleId;
        emit RoleUpdate(_objectId, _contextId, _roleId, "_assignRole");
    }

    function _unassignRole(bytes32 _objectId, bytes32 _contextId) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        emit RoleUpdate(_objectId, _contextId, s.roles[_objectId][_contextId], "_unassignRole");
        delete s.roles[_objectId][_contextId];
    }

    function _isInGroup(
        bytes32 _objectId,
        bytes32 _contextId,
        bytes32 _groupId
    ) internal view returns (bool ret) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        // Check for the role in the context
        bytes32 objectRoleInContext = s.roles[_objectId][_contextId];

        if (s.groups[objectRoleInContext][_groupId]) {
            ret = true;
        } else {
            // A role in the context of the system covers all objects
            bytes32 objectRoleInSystem = s.roles[_objectId][LibAdmin._getSystemId()];

            if (s.groups[objectRoleInSystem][_groupId]) {
                ret = true;
            }
        }
    }

    function _isParentInGroup(
        bytes32 _objectId,
        bytes32 _contextId,
        bytes32 _groupId
    ) internal view returns (bool) {
        bytes32 parentId = LibObject._getParent(_objectId);
        return _isInGroup(parentId, _contextId, _groupId);
    }

    /// Can a user (or object) assign a role in a given context
    function _canAssign(
        bytes32 _assignerId,
        bytes32 _objectId,
        bytes32 _contextId,
        bytes32 _roleId
    ) internal view returns (bool) {
        // we might impose additional restrictions on _objectId in the future
        require(_objectId != "", "invalid object ID");
        bool ret = false;
        AppStorage storage s = LibAppStorage.diamondStorage();
        bytes32 assignerGroup = s.canAssign[_roleId];

        // Check for group membership in the given context
        if (_isInGroup(_assignerId, _contextId, assignerGroup)) {
            ret = true;
        } else {
            // A role in the context of the system covers all objects
            if (_isParentInGroup(_assignerId, LibAdmin._getSystemId(), assignerGroup)) {
                ret = true;
            }
        }
        return ret;
    }

    function _getRoleInContext(bytes32 _objectId, bytes32 _contextId) internal view returns (bytes32) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.roles[_objectId][_contextId];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { AppStorage, LibAppStorage, LibAdmin, LibConstants, LibHelpers } from "../AppStorage.sol";

library LibTokenizedVault {
    /**
     * @notice Entity funds deposit
     * @dev Thrown when entity is funded
     * @param caller address of the funder
     * @param receivingEntityId Unique ID of the entity receiving the funds
     * @param assetId Unique ID of the asset being deposited
     * @param shares Amount deposited
     */
    event EntityDeposit(address indexed caller, bytes32 indexed receivingEntityId, bytes32 assetId, uint256 shares);

    /**
     * @notice Entity funds withdrawn
     * @dev Thrown when entity funds are withdrawn
     * @param caller address of the account initiating the transfer
     * @param receiver address of the account receiving the funds
     * @param assetId Unique ID of the asset being transferred
     * @param shares Withdrawn amount
     */
    event EntityWithdraw(address indexed caller, address indexed receiver, address assetId, uint256 shares);

    /**
     * @dev Emitted when a token balance gets updated.
     * @param ownerId Id of owner
     * @param tokenId ID of token
     * @param newAmountOwned new amount owned
     * @param functionName Function name
     * @param msgSender msg.sende
     */
    event InternalTokenBalanceUpdate(bytes32 indexed ownerId, bytes32 tokenId, uint256 newAmountOwned, string functionName, address msgSender);

    /**
     * @dev Emitted when a token supply gets updated.
     * @param tokenId ID of token
     * @param newTokenSupply New token supply
     * @param functionName Function name
     * @param msgSender msg.sende
     */
    event InternalTokenSupplyUpdate(bytes32 indexed tokenId, uint256 newTokenSupply, string functionName, address msgSender);

    /**
     * @dev Emitted when a dividend gets payed out.
     * @param guid divident distribution ID
     * @param from distribution intiator
     * @param to distribution receiver
     * @param amount distributed amount
     */
    event DividendDistribution(bytes32 indexed guid, bytes32 from, bytes32 to, bytes32 dividendTokenId, uint256 amount);

    function _internalBalanceOf(bytes32 _ownerId, bytes32 _tokenId) internal view returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.tokenBalances[_tokenId][_ownerId];
    }

    function _internalTokenSupply(bytes32 _objectId) internal view returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.tokenSupply[_objectId];
    }

    function _internalTransfer(
        bytes32 _from,
        bytes32 _to,
        bytes32 _tokenId,
        uint256 _amount
    ) internal returns (bool success) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        if (s.marketLockedBalances[_from][_tokenId] > 0) {
            require(s.tokenBalances[_tokenId][_from] - s.marketLockedBalances[_from][_tokenId] >= _amount, "_internalTransferFrom: tokens for sale in mkt");
        } else {
            require(s.tokenBalances[_tokenId][_from] >= _amount, "_internalTransferFrom: must own the funds");
        }
        _withdrawAllDividends(_from, _tokenId);
        s.tokenBalances[_tokenId][_from] -= _amount;
        s.tokenBalances[_tokenId][_to] += _amount;

        emit InternalTokenBalanceUpdate(_from, _tokenId, s.tokenBalances[_tokenId][_from], "_internalTransferFrom", msg.sender);
        emit InternalTokenBalanceUpdate(_to, _tokenId, s.tokenBalances[_tokenId][_to], "_internalTransferFrom", msg.sender);

        success = true;
    }

    function _internalMint(
        bytes32 _to,
        bytes32 _tokenId,
        uint256 _amount
    ) internal {
        require(_to != "", "MultiToken: mint to zero address");
        require(_amount > 0, "MultiToken: mint zero tokens");

        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 supply = _internalTokenSupply(_tokenId);

        // This must be done BEFORE the supply increases!!!
        // This will calcualte the hypothetical dividends that would correspond to this number of shares.
        // It must be added to the withdrawn dividend for every denomination for the user who receives the minted tokens
        bytes32[] memory dividendDenominations = s.dividendDenominations[_tokenId];

        for (uint256 i = 0; i < dividendDenominations.length; ++i) {
            bytes32 dividendDenominationId = dividendDenominations[i];
            uint256 totalDividend = s.totalDividends[_tokenId][dividendDenominationId];
            uint256 withdrawnSoFar = s.withdrawnDividendPerOwner[_tokenId][dividendDenominationId][_to];

            (, uint256 dividendDeduction) = _getWithdrawableDividendAndDeductionMath(_amount, supply, totalDividend, withdrawnSoFar);
            s.withdrawnDividendPerOwner[_tokenId][dividendDenominationId][_to] += dividendDeduction;
        }

        // Now you can bump the token supply and the balance for the user
        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        s.tokenSupply[_tokenId] += _amount;
        s.tokenBalances[_tokenId][_to] += _amount;

        emit InternalTokenSupplyUpdate(_tokenId, s.tokenSupply[_tokenId], "_internalMint", msg.sender);
        emit InternalTokenBalanceUpdate(_to, _tokenId, s.tokenBalances[_tokenId][_to], "_internalMint", msg.sender);
    }

    function _internalBurn(
        bytes32 _from,
        bytes32 _tokenId,
        uint256 _amount
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        if (s.marketLockedBalances[_from][_tokenId] > 0) {
            require(s.tokenBalances[_tokenId][_from] - s.marketLockedBalances[_from][_tokenId] >= _amount, "_internalBurn: tokens for sale in mkt");
        } else {
            require(s.tokenBalances[_tokenId][_from] >= _amount, "_internalBurn: must own the funds");
        }

        _withdrawAllDividends(_from, _tokenId);
        s.tokenSupply[_tokenId] -= _amount;
        s.tokenBalances[_tokenId][_from] -= _amount;

        emit InternalTokenSupplyUpdate(_tokenId, s.tokenSupply[_tokenId], "_internalBurn", msg.sender);
        emit InternalTokenBalanceUpdate(_from, _tokenId, s.tokenBalances[_tokenId][_from], "_internalBurn", msg.sender);
    }

    function _withdrawDividend(
        bytes32 _ownerId,
        bytes32 _tokenId,
        bytes32 _dividendTokenId
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        bytes32 dividendBankId = LibHelpers._stringToBytes32(LibConstants.DIVIDEND_BANK_IDENTIFIER);

        uint256 amountOwned = s.tokenBalances[_tokenId][_ownerId];
        uint256 supply = _internalTokenSupply(_tokenId);
        uint256 totalDividend = s.totalDividends[_tokenId][_dividendTokenId];
        uint256 withdrawnSoFar = s.withdrawnDividendPerOwner[_tokenId][_dividendTokenId][_ownerId];

        (uint256 withdrawableDividend, uint256 dividendDeduction) = _getWithdrawableDividendAndDeductionMath(amountOwned, supply, totalDividend, withdrawnSoFar);
        require(withdrawableDividend > 0, "_withdrawDividend: no dividend");

        // Bump the withdrawn dividends for the owner
        s.withdrawnDividendPerOwner[_tokenId][_dividendTokenId][_ownerId] += dividendDeduction;

        // Move the dividend
        s.tokenBalances[_dividendTokenId][dividendBankId] -= withdrawableDividend;
        s.tokenBalances[_dividendTokenId][_ownerId] += withdrawableDividend;

        emit InternalTokenBalanceUpdate(dividendBankId, _dividendTokenId, s.tokenBalances[_dividendTokenId][dividendBankId], "_withdrawDividend", msg.sender);
        emit InternalTokenBalanceUpdate(_ownerId, _dividendTokenId, s.tokenBalances[_dividendTokenId][_ownerId], "_withdrawDividend", msg.sender);
    }

    function _getWithdrawableDividend(
        bytes32 _ownerId,
        bytes32 _tokenId,
        bytes32 _dividendTokenId
    ) internal view returns (uint256 withdrawableDividend_) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        uint256 amount = s.tokenBalances[_tokenId][_ownerId];
        uint256 supply = _internalTokenSupply(_tokenId);
        uint256 totalDividend = s.totalDividends[_tokenId][_dividendTokenId];
        uint256 withdrawnSoFar = s.withdrawnDividendPerOwner[_tokenId][_dividendTokenId][_ownerId];

        (withdrawableDividend_, ) = _getWithdrawableDividendAndDeductionMath(amount, supply, totalDividend, withdrawnSoFar);
    }

    function _withdrawAllDividends(bytes32 _ownerId, bytes32 _tokenId) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        bytes32[] memory dividendDenominations = s.dividendDenominations[_tokenId];
        bytes32 dividendDenominationId;

        for (uint256 i = 0; i < dividendDenominations.length; ++i) {
            dividendDenominationId = dividendDenominations[i];
            _withdrawDividend(_ownerId, _tokenId, dividendDenominationId);
        }
    }

    function _payDividend(
        bytes32 _guid,
        bytes32 _from,
        bytes32 _to,
        bytes32 _dividendTokenId,
        uint256 _amount
    ) internal {
        require(_amount > 0, "dividend amount must be > 0");
        require(LibAdmin._isSupportedExternalToken(_dividendTokenId), "must be supported dividend token");

        AppStorage storage s = LibAppStorage.diamondStorage();
        bytes32 dividendBankId = LibHelpers._stringToBytes32(LibConstants.DIVIDEND_BANK_IDENTIFIER);

        // If no tokens are issued, then deposit directly.
        if (_internalTokenSupply(_to) == 0) {
            _internalTransfer(_from, _to, _dividendTokenId, _amount);
        }
        // Otherwise pay as dividend
        else {
            // issue dividend. if you are owed dividends on the _dividendTokenId, they will be collected
            // Check for possible infinite loop, but probably not
            _internalTransfer(_from, dividendBankId, _dividendTokenId, _amount);
            s.totalDividends[_to][_dividendTokenId] += _amount;

            // keep track of the dividend denominations
            // if dividend has not yet been issued in this token, add it to the list and update mappings
            if (s.dividendDenominationIndex[_to][_dividendTokenId] == 0) {
                // We must limit the number of different tokens dividends are paid in
                if (s.dividendDenominations[_to].length > LibAdmin._getMaxDividendDenominations()) {
                    revert("exceeds max div denominations");
                }

                s.dividendDenominationIndex[_to][_dividendTokenId] = uint8(s.dividendDenominations[_to].length);
                s.dividendDenominationAtIndex[_to][uint8(s.dividendDenominations[_to].length)] = _dividendTokenId;
                s.dividendDenominations[_to].push(_dividendTokenId);
            }
        }
        // Events are emitted from the _internalTransfer()
        emit DividendDistribution(_guid, _from, _to, _dividendTokenId, _amount);
    }

    function _getTokenSymbol(bytes32 _objectId) internal view returns (string memory) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return LibHelpers._bytes32ToString(s.objectTokenSymbol[_objectId]);
    }

    function _getWithdrawableDividendAndDeductionMath(
        uint256 _amount,
        uint256 _supply,
        uint256 _totalDividend,
        uint256 _withdrawnSoFar
    ) internal pure returns (uint256 _withdrawableDividend, uint256 _dividendDeduction) {
        // The holder dividend is: holderDividend = (totalDividend/tokenSupply) * _amount. The remainer (dust) is lost.
        // To get a smaller remainder we re-arrange to: holderDividend = (totalDividend * _amount) / _supply
        uint256 totalDividendTimesAmount = _totalDividend * _amount;
        uint256 holderDividend = _supply == 0 ? 0 : (totalDividendTimesAmount / _supply);

        _withdrawableDividend = (_withdrawnSoFar >= holderDividend) ? 0 : holderDividend - _withdrawnSoFar;
        _dividendDeduction = _withdrawableDividend;

        // If there is a remainder, add 1 to the _dividendDeduction
        if (totalDividendTimesAmount > _withdrawableDividend * _supply) {
            _dividendDeduction += 1;
        }
    }
}