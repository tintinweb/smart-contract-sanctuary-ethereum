// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import { MarketInfo, Modifiers } from "../AppStorage.sol";
import { LibHelpers } from "../libs/LibHelpers.sol";
import { LibConstants } from "../libs/LibConstants.sol";
import { LibMarket } from "../libs/LibMarket.sol";
import { LibObject } from "../libs/LibObject.sol";

import { ReentrancyGuard } from "../../../utils/ReentrancyGuard.sol";

/**
 * inspired by https://github.com/nayms/maker-otc/blob/master/contracts/matching_market.sol
 */
contract MarketFacet is Modifiers, ReentrancyGuard {
    function cancelOffer(uint256 _offerId) external nonReentrant {
        require(s.offers[_offerId].state == LibConstants.OFFER_STATE_ACTIVE, "offer not active");
        bytes32 creator = LibMarket._getOffer(_offerId).creator;
        require(LibHelpers._getAddressFromId(LibObject._getParent(creator)) == msg.sender, "only creator can cancel");
        LibMarket._cancelOffer(_offerId);
    }

    function executeLimitOffer(
        bytes32 _from,
        bytes32 _sellToken,
        uint256 _sellAmount,
        bytes32 _buyToken,
        uint256 _buyAmount,
        uint256 _feeSchedule
    )
        external
        nonReentrant
        returns (
            uint256 offerId_,
            uint256 buyTokenComissionsPaid_,
            uint256 sellTokenComissionsPaid_
        )
    {
        return LibMarket._executeLimitOffer(_from, _sellToken, _sellAmount, _buyToken, _buyAmount, _feeSchedule);
    }

    function executeMarketOffer(
        bytes32 _from,
        bytes32 _sellToken,
        uint256 _sellAmount,
        bytes32 _buyToken,
        uint256 _feeSchedule
    )
        external
        nonReentrant
        returns (
            uint256 offerId_,
            uint256 buyTokenComissionsPaid_,
            uint256 sellTokenComissionsPaid_
        )
    {
        return LibMarket._executeLimitOffer(_from, _sellToken, _sellAmount, _buyToken, 0, _feeSchedule);
    }

    function getLastOfferId() external view returns (uint256) {
        return LibMarket._getLastOfferId();
    }

    function getBestOfferId(bytes32 _sellToken, bytes32 _buyToken) external view returns (uint256) {
        return LibMarket._getBestOfferId(_sellToken, _buyToken);
    }

    function simulateMarketOffer(
        bytes32 _sellToken,
        uint256 _sellAmount,
        bytes32 _buyToken
    ) external view returns (uint256) {
        return LibMarket._simulateMarketOffer(_sellToken, _sellAmount, _buyToken);
    }

    function getOffer(uint256 _offerId) external view returns (MarketInfo memory _offerState) {
        return LibMarket._getOffer(_offerId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

/// @notice storage for nayms v3 decentralized insurance platform

import "./FreeStructs.sol";

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
    address[] approvedContracts; // Is this used?
    mapping(address => uint256) approvedContractIndexes; // Is this used?
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
    uint256 groupsConfigUpdateIndex;
    uint256 canAssignConfigUpdateIndex;
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
    // uint256 stakedSupply; // todo READY TO BE REMOVED. use the internal total supply variable instead
    // Keep track of the different tokens owned on chain
    mapping(bytes32 => mapping(bytes32 => uint8)) ownedTokenIndex; // ownerId => tokenId => index
    mapping(bytes32 => mapping(uint8 => bytes32)) ownedTokenAtIndex; // ownerId => index => tokenId
    mapping(bytes32 => uint8) numOwnedTokens; //starts at 1. 0 means no tokens owned
    // ownedTokenIndex
    // ownedTokenAtIndex
    // numOwnedTokens

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
    uint16 tradingComissionTotalBP; // the total amount that is deducted for trading commissions (BP)
    // The total comission above is further divided as follows:
    uint16 tradingComissionNaymsLtdBP;
    uint16 tradingComissionNDFBP;
    uint16 tradingComissionSTMBP;
    uint16 tradingComissionMakerBP;
    // Premium Commissions
    uint16 premiumComissionNaymsLtdBP;
    uint16 premiumComissionNDFBP;
    uint16 premiumComissionSTMBP;
    // A policy can pay out additional comissions on premiums to entities having a variety of roles on the policy

    mapping(bytes32 => mapping(bytes32 => uint256)) marketLockedBalances; // to keep track of an owner's tokens that are on sale in the marketplace, ownerId => lockedTokenId => amount
}

library LibAppStorage {
    function diamondStorage() internal pure returns (AppStorage storage ds) {
        assembly {
            ds.slot := 0
        }
    }

    function abs(int256 x) internal pure returns (uint256) {
        return uint256(x >= 0 ? x : -x);
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
pragma solidity >0.8.12;

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

    function _getNaymsVaultTokenIdForAddress(address _addr) internal pure returns (bytes32) {
        uint256 naymsVaultTokenId = uint256(uint160(_addr)) << 1;
        return bytes32(naymsVaultTokenId);
    }

    function _getAddressFromId(bytes32 _id) internal pure returns (address) {
        return address(bytes20(_id));
    }

    // Conversion Utilities

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

    function _strEqual(string memory s1, string memory s2) internal pure returns (bool) {
        return (keccak256(abi.encode(s1)) == keccak256(abi.encode(s2)));
    }

    function isZeroAddress(bytes32 accountId) internal pure returns (bool) {
        return _getAddressFromId(accountId) == address(0);
    }

    function _asSingletonArray(bytes32 element) internal pure returns (bytes32[] memory) {
        bytes32[] memory array = new bytes32[](1);
        array[0] = element;
        return array;
    }

    function _asSingletonArray(uint256 element) internal pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;
        return array;
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
    string internal constant MARKET_IDENTIFIER = "Market";
    string internal constant NAYM_TOKEN_IDENTIFIER = "NAYM"; //This is the ID in the system as well as the token ID
    string internal constant DIVIDEND_BANK_IDENTIFIER = "Dividend Bank"; //This will hold all the dividends
    string internal constant NAYMS_LTD_IDENTIFIER = "Nayms Ltd";
    // These should go directly to the receivers
    string internal constant FEE_BANK_IDENTIFIER = "Deprecated!!!";
    string internal constant BROKER_FEE_BANK_IDENTIFIER = "Also Deprecated!!!";

    //Roles
    string internal constant ROLE_SYSTEM_ADMIN = "System Admin";
    string internal constant ROLE_SYSTEM_MANAGER = "System Manager";
    string internal constant ROLE_ENTITY_ADMIN = "Entity Admin";
    string internal constant ROLE_ENTITY_MANAGER = "Entity Manager";
    string internal constant ROLE_APPROVED_USER = "Approved User";
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
    uint256 internal constant BP_FACTOR = 1000;

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
pragma solidity >=0.8.9;

import { AppStorage, LibAppStorage, MarketInfo, TokenAmount } from "../AppStorage.sol";
import { LibMath } from "./LibMath.sol";
import { LibHelpers } from "./LibHelpers.sol";
import { LibAdmin } from "./LibAdmin.sol";
import { LibTokenizedVault } from "./LibTokenizedVault.sol";
import { LibConstants } from "./LibConstants.sol";
import { LibFeeRouter } from "./LibFeeRouter.sol";

library LibMarket {
    /// @notice order has been added
    event OrderAdded(uint256 indexed orderId, bytes32 indexed seller, bytes32 indexed sellToken, uint256 sellAmount, bytes32 buyToken, uint256 buyAmount, uint256 state);

    /// @notice order has been executed
    event OrderExecuted(uint256 indexed orderId, bytes32 indexed seller, bytes32 indexed sellToken, uint256 sellAmount, bytes32 buyToken, uint256 buyAmount, uint256 category);

    /// @notice order has been canceled
    event OrderCancelled(uint256 indexed orderId, bytes32 indexed seller, bytes32 sellToken);

    struct MatchingOfferResult {
        uint256 remainingBuyAmount;
        uint256 remainingSellAmount;
        uint256 buyTokenComissionsPaid;
        uint256 sellTokenComissionsPaid;
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

        return s.offers[_offerId].rankNext != 0 || s.offers[_offerId].rankPrev != 0 || s.bestOfferId[sellToken][buyToken] == _offerId;
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
            // uint256 bestOfferId = s.bestOfferId[_sellToken][_buyToken];
            if (bestOfferId == 0) {
                break;
            }

            uint256 bestBuyAmount = s.offers[bestOfferId].buyAmount;
            uint256 bestSellAmount = s.offers[bestOfferId].sellAmount;

            if (_buyAmount == 0) {
                // market offer pay_amt is smaller than 1 wei of the other token
                if (result.remainingSellAmount * 1 ether < LibMath.wdiv(bestBuyAmount, bestSellAmount)) {
                    break; // We consider that all amount is sold
                }
            }
            // Ugly hack to work around rounding errors. Based on the idea that
            // the furthest the amounts can stray from their "true" values is 1.
            // Ergo the worst case has `sellAmount` and `bestSellAmount` at +1 away from
            // their "correct" values and `bestBuyAmount` and `buyAmount` at -1.
            // Since (c - 1) * (d - 1) > (a + 1) * (b + 1) is equivalent to
            // c * d > a * b + a + b + c + d, we write...
            //
            // (For detailed breakdown see https://hiddentao.com/archives/2019/09/08/maker-otc-on-chain-orderbook-deep-dive)
            //
            else if (
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
                // matchedAmount_ += finalSellAmount;
                (uint256 nextBuyTokenComissionsPaid, uint256 nextSellTokenComissionsPaid) = _buy(bestOfferId, _fromEntityId, finalSellAmount);

                // Keep track of total commissions
                result.buyTokenComissionsPaid += nextBuyTokenComissionsPaid;
                result.sellTokenComissionsPaid += nextSellTokenComissionsPaid;

                // calculate how much is left to buy/sell
                uint256 sellAmountOld = result.remainingSellAmount;
                result.remainingSellAmount = result.remainingSellAmount - finalSellAmount;
                result.remainingBuyAmount = (result.remainingSellAmount * result.remainingBuyAmount) / sellAmountOld;
            }
        }
    }

    function _createOffer(
        bytes32 _from,
        bytes32 _sellToken,
        uint256 _sellAmount,
        uint256 _sellAmountInitial,
        bytes32 _buyToken,
        uint256 _buyAmount,
        uint256 _buyAmountInitial,
        uint256 _feeSchedule
    ) internal returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        s.lastOfferId++;
        uint256 lastOfferId = s.lastOfferId;

        MarketInfo memory marketInfo = s.offers[lastOfferId];
        marketInfo.creator = _from;
        marketInfo.sellToken = _sellToken;
        marketInfo.sellAmount = _sellAmount;
        marketInfo.sellAmountInitial = _sellAmountInitial;
        marketInfo.buyToken = _buyToken;
        marketInfo.buyAmount = _buyAmount;
        marketInfo.buyAmountInitial = _buyAmountInitial;
        marketInfo.feeSchedule = _feeSchedule;

        if (_sellAmount == 0) {
            marketInfo.state = LibConstants.OFFER_STATE_FULFILLED;
        } else {
            marketInfo.state = LibConstants.OFFER_STATE_ACTIVE;

            // lock tokens!
            s.marketLockedBalances[_from][_sellToken] += _sellAmount;
        }

        s.offers[lastOfferId] = marketInfo;
        emit OrderAdded(lastOfferId, marketInfo.creator, _sellToken, _sellAmount, _buyToken, _buyAmount, marketInfo.state);

        return lastOfferId;
    }

    function _buy(
        uint256 _offerId,
        bytes32 _takerId,
        uint256 _requestedBuyAmount // entity token(?)
    ) internal returns (uint256 buyTokenComissionsPaid_, uint256 sellTokenComissionsPaid_) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        // (a / b) * c = c * a / b  -> do multiplication first to avoid underflow
        uint256 thisSaleSellAmount = (_requestedBuyAmount * s.offers[_offerId].sellAmount) / s.offers[_offerId].buyAmount; // nWETH

        // check bounds and update balances
        _checkBoundsAndUpdateBalances(_offerId, thisSaleSellAmount, _requestedBuyAmount);

        // Check before paying commissions
        if (s.offers[_offerId].feeSchedule == LibConstants.FEE_SCHEDULE_STANDARD) {
            // Fees are paid by the taker.
            // Maker pays no fees
            // Fees are paid only in external token
            // If the _buyToken is external, commissions are paid from _buyAmount in _buyToken.
            // If the _buyToken is internal and the _sellToken is external, commissions are paid from _sellAmount in _sellToken.
            // If both are internal tokens no commissions are paid
            if (LibAdmin._isSupportedExternalToken(s.offers[_offerId].buyToken)) {
                buyTokenComissionsPaid_ = LibFeeRouter._payTradingComissions(s.offers[_offerId].creator, _takerId, s.offers[_offerId].buyToken, _requestedBuyAmount);
            } else if (LibAdmin._isSupportedExternalToken(s.offers[_offerId].sellToken)) {
                sellTokenComissionsPaid_ = LibFeeRouter._payTradingComissions(s.offers[_offerId].creator, _takerId, s.offers[_offerId].sellToken, thisSaleSellAmount);
            }
        }

        s.marketLockedBalances[s.offers[_offerId].creator][s.offers[_offerId].sellToken] -= _requestedBuyAmount;

        require(LibTokenizedVault._internalTransfer(s.offers[_offerId].creator, _takerId, s.offers[_offerId].sellToken, _requestedBuyAmount), "maker transfer failed");
        require(LibTokenizedVault._internalTransfer(_takerId, s.offers[_offerId].creator, s.offers[_offerId].buyToken, thisSaleSellAmount), "taker transfer failed");

        // cancel offer if it has become dust
        if (s.offers[_offerId].sellAmount < LibConstants.DUST) {
            s.offers[_offerId].state = LibConstants.OFFER_STATE_FULFILLED;
            _cancelOffer(_offerId);
        }

        emit OrderExecuted(_offerId, _takerId, s.offers[_offerId].sellToken, thisSaleSellAmount, s.offers[_offerId].buyToken, _requestedBuyAmount, s.offers[_offerId].state);
    }

    function _checkBoundsAndUpdateBalances(
        uint256 _offerId,
        uint256 _sellAmount,
        uint256 _buyAmount
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        (TokenAmount memory offerSell, TokenAmount memory offerBuy) = _getOfferTokenAmounts(_offerId);

        require(uint128(_buyAmount) == _buyAmount, "buy amount exceeds int limit");
        require(uint128(_sellAmount) == _sellAmount, "sell amount exceeds int limit");

        require(_buyAmount > 0, "requested buy amount is 0");
        require(_buyAmount <= offerBuy.amount, "requested buy amount too large");
        require(_sellAmount > 0, "calculated sell amount is 0");
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

        // transfer remaining sell amount back from marketplace (LibConstants.MARKET_IDENTIFIER) to creator
        if (marketInfo.sellAmount > 0) {
            // note nothing is transferred since tokens for sale are UN-escrowed. Just unlock!
            s.marketLockedBalances[s.offers[_offerId].creator][s.offers[_offerId].sellToken] -= marketInfo.sellAmount;
        }

        // don't emit event stating market order is canceled if the market order was executed and fulfilled
        if (marketInfo.state != LibConstants.OFFER_STATE_FULFILLED) emit OrderCancelled(_offerId, marketInfo.creator, marketInfo.sellToken);
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

        require(uint128(_sellAmount) == _sellAmount, "sell amount must be uint128");
        require(uint128(_buyAmount) == _buyAmount, "buy amount must be uint128");
        require(_sellAmount > 0, "sell amount must be >0");
        require(_sellToken != "", "sell token must be valid");
        require(_buyAmount > 0, "buy amount must be >0");
        require(_buyToken != "", "buy token must be valid");
        require(_sellToken != _buyToken, "cannot sell and buy same token");

        // note: add restriction to not be able to sell tokens that are already for sale
        // maker must own sell amount and it must not be locked
        require(s.tokenBalances[_sellToken][_entityId] - s.marketLockedBalances[_entityId][_sellToken] >= _sellAmount, "verify offer: tokens for sale in mkt");

        // if caller requested the 'platform action' fee schedule then check that they're allowed to do so
        if (_feeSchedule == LibConstants.FEE_SCHEDULE_PLATFORM_ACTION) {
            require(address(this) == msg.sender, "only system can omit fees");
        }
    }

    function _getOfferTokenAmounts(uint256 _offerId) internal view returns (TokenAmount memory sell_, TokenAmount memory buy_) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        sell_.token = s.offers[_offerId].sellToken;
        sell_.amount = s.offers[_offerId].sellAmount;
        buy_.token = s.offers[_offerId].buyToken;
        buy_.amount = s.offers[_offerId].buyAmount;
    }

    function _executeLimitOffer(
        bytes32 _from,
        bytes32 _sellToken,
        uint256 _sellAmount,
        bytes32 _buyToken,
        uint256 _buyAmount,
        uint256 _feeSchedule
    )
        internal
        returns (
            uint256 offerId_,
            uint256 buyTokenComissionsPaid_,
            uint256 sellTokenComissionsPaid_
        )
    {
        _assertValidOffer(_from, _sellToken, _sellAmount, _buyToken, _buyAmount, _feeSchedule);

        MatchingOfferResult memory result = _matchToExistingOffers(_from, _sellToken, _sellAmount, _buyToken, _buyAmount);
        buyTokenComissionsPaid_ = result.buyTokenComissionsPaid;
        sellTokenComissionsPaid_ = result.sellTokenComissionsPaid;

        // if still some left
        if (result.remainingBuyAmount > 0 && result.remainingSellAmount > 0 && result.remainingSellAmount >= LibConstants.DUST) {
            // new offer should be created
            uint256 lastOfferId = _createOffer(_from, _sellToken, result.remainingSellAmount, _sellAmount, _buyToken, result.remainingBuyAmount, _buyAmount, _feeSchedule);

            // ensure it's in the right position in the list
            _insertOfferIntoSortedList(lastOfferId);

            offerId_ = lastOfferId;
        } else {
            offerId_ = 0; // no limit offer created, fully matched
        }
    }

    function _getMarketId() internal pure returns (bytes32) {
        return LibHelpers._stringToBytes32(LibConstants.MARKET_IDENTIFIER);
    }

    function _getOffer(uint256 _offerId) internal view returns (MarketInfo memory _offerState) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.offers[_offerId];
    }

    function _getLastOfferId() internal view returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.lastOfferId;
    }

    function _simulateMarketOffer(
        bytes32 _sellToken,
        uint256 _sellAmount,
        bytes32 _buyToken
    ) internal view returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 boughtAmount_;
        uint256 soldAmount_;
        uint256 sellAmount = _sellAmount;

        uint256 bestOfferId = s.bestOfferId[_sellToken][_buyToken];

        while (sellAmount > 0 && bestOfferId > 0) {
            uint256 offerBuyAmount = s.offers[bestOfferId].buyAmount;
            uint256 offerSellAmount = s.offers[bestOfferId].sellAmount;

            // There is a chance that pay_amt is smaller than 1 wei of the other token
            if (sellAmount * 1 ether < LibMath.wdiv(offerBuyAmount, offerSellAmount)) {
                break; // We consider that all amount is sold
            }

            // if sell amount >= offer buy amount then lets buy the whole offer
            if (sellAmount >= offerBuyAmount) {
                soldAmount_ = soldAmount_ + offerBuyAmount;
                boughtAmount_ = boughtAmount_ + offerSellAmount;
                sellAmount = sellAmount - offerBuyAmount;
            }
            // otherwise, let's just buy what we can
            else {
                soldAmount_ = soldAmount_ + sellAmount;
                boughtAmount_ = boughtAmount_ + ((sellAmount * offerSellAmount) / offerBuyAmount);
                sellAmount = 0;
            }

            // move to next best offer
            bestOfferId = s.offers[bestOfferId].rankPrev;
        }

        require(_sellAmount <= soldAmount_, "not enough orders in market");

        return boughtAmount_;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

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

        require(!s.existingObjects[_objectId], "object already exists");
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
pragma solidity >=0.8.9;

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
pragma solidity >=0.7.6;
pragma abicoder v2;

// should add to 100% (1000)
struct FeeTotal {
    uint8 tradingComissionNaymsLtdBP;
    uint8 tradingComissionNDFBP;
    uint8 tradingComissionSTMBP;
    uint8 tradingComissionMakerBP;
}

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

struct Entity {
    bytes32 assetId;
    uint256 collateralRatio;
    uint256 maxCapital;
    uint256 totalLimit;
    bool simplePolicyEnabled;
}

struct SimplePolicy {
    uint256 startDate;
    uint256 maturationDate;
    bytes32 asset;
    uint256 limit;
    uint256 state;
    uint256 claimsPaid;
    uint256 premiumsPaid;
    uint256[] premiums;
    uint256[] premiumDueDates;
    bytes32[] commissionReceivers;
    uint256[] comissionBasisPoints;
    uint256 sponsorComissionBasisPoints; //underwriter is  parent
}

struct Stakeholders {
    bytes32[] roles;
    bytes32[] entityIds;
    bytes[] signatures;
}

struct OfferState {
    address creator;
    address sellToken;
    uint256 sellAmount;
    uint256 sellAmountInitial;
    address buyToken;
    uint256 buyAmount;
    uint256 buyAmountInitial;
    uint256 averagePrice;
    uint256 feeSchedule;
    uint256 state;
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

// todo where's the most optimal place to put this struct that passes into initialization()?
struct Args {
    bytes32 systemContext;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.1 <0.9.0;

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
pragma solidity >0.8.12;

import { AppStorage, LibAppStorage } from "../AppStorage.sol";
import { LibConstants } from "../libs/LibConstants.sol";
import { LibHelpers } from "../libs/LibHelpers.sol";
import { LibObject } from "../libs/LibObject.sol";

library LibAdmin {
    event BalanceUpdated(uint256 oldBalance, uint256 newBalance);
    event EquilibriumLevelUpdated(uint256 oldLevel, uint256 newLevel);
    event MaxDiscountUpdated(uint256 oldDiscount, uint256 newDiscount);
    event TargetNaymsAllocationUpdated(uint256 oldTarget, uint256 newTarget);
    event DiscountTokenUpdated(address oldToken, address newToken);
    event PoolFeeUpdated(uint256 oldFee, uint256 newFee);
    event CoefficientUpdated(uint256 oldCoefficient, uint256 newCoefficient);
    event RoleGroupUpdated(string role, string group, bool roleInGroup, uint256 index);
    event RoleCanAssignUpdated(string role, string group, uint256 index);

    function initSystem() internal {
        _initReserveObjectIds();
        // TODO Ted have a look
        //Init all reserved IDs from constants
        //Init supported tokens by calling _addSupportedTokens() with supported tokens array from deployment
    }

    function _reserveObject(bytes32 objectId) internal {}

    function _initReserveObjectIds() internal {
        _reserveObject(LibHelpers._stringToBytes32(LibConstants.SYSTEM_IDENTIFIER));
        _reserveObject(LibHelpers._stringToBytes32(LibConstants.NDF_IDENTIFIER));
        _reserveObject(LibHelpers._stringToBytes32(LibConstants.STM_IDENTIFIER));
        _reserveObject(LibHelpers._stringToBytes32(LibConstants.SSF_IDENTIFIER));
        _reserveObject(LibHelpers._stringToBytes32(LibConstants.NAYM_TOKEN_IDENTIFIER));
    }

    function _getSystemId() internal pure returns (bytes32) {
        return LibHelpers._stringToBytes32(LibConstants.SYSTEM_IDENTIFIER);
    }

    function _getEmptyId() internal pure returns (bytes32) {
        return LibHelpers._stringToBytes32(LibConstants.EMPTY_IDENTIFIER);
    }

    function _updateMaxDividendDenominations(uint8 _newMaxDividendDenominations) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(_newMaxDividendDenominations > s.maxDividendDenominations, "_updateMaxDividendDenominations: cannot reduce");
        s.maxDividendDenominations = _newMaxDividendDenominations;
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
        require(_newCoefficient >= 0, "Coefficient too low");

        AppStorage storage s = LibAppStorage.diamondStorage();

        uint256 oldCoefficient = s.rewardsCoefficient;

        s.rewardsCoefficient = _newCoefficient;

        emit CoefficientUpdated(oldCoefficient, s.rewardsCoefficient);
    }
    function _updateRoleAssigner(string memory _role, string memory _assignerGroup) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        s.canAssign[LibHelpers._stringToBytes32(_role)] = LibHelpers._stringToBytes32(_assignerGroup);
        s.canAssignConfigUpdateIndex++;
        emit RoleCanAssignUpdated(_role, _assignerGroup, s.canAssignConfigUpdateIndex);
    }

    function _updateRoleGroup(
        string memory _role,
        string memory _group,
        bool _roleInGroup
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        s.groups[LibHelpers._stringToBytes32(_role)][LibHelpers._stringToBytes32(_group)] = _roleInGroup;
        s.groupsConfigUpdateIndex++;
        emit RoleGroupUpdated(_role, _group, _roleInGroup, s.groupsConfigUpdateIndex);
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
        }
    }

    function _getSupportedExternalTokens() internal view returns (address[] memory) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        // Supported tokens cannot be removed because they may exist in the system!
        return s.supportedExternalTokens;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.8.12;

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
     * @param txOrigin tx.origin
     * @param msgSender msg.sender
     */
    event RoleUpdate(bytes32 indexed objectId, bytes32 contextId, bytes32 roleId, string functionName, address txOrigin, address msgSender);

    function _assignRole(
        bytes32 _objectId,
        bytes32 _contextId,
        bytes32 _roleId
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        s.roles[_objectId][_contextId] = _roleId;
        emit RoleUpdate(_objectId, _contextId, _roleId, "_assignRole", tx.origin, msg.sender);
    }

    function _unassignRole(bytes32 _objectId, bytes32 _contextId) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        emit RoleUpdate(_objectId, _contextId, s.roles[_objectId][_contextId], "_unassignRole", tx.origin, msg.sender);
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
pragma solidity >=0.8.9;

library LibMath {
    // These are from https://github.com/nayms/maker-otc/blob/master/contracts/math.sol
    function wdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = ((x * 10**18) + (y / 2)) / y;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { AppStorage, LibAppStorage, LibAdmin, LibConstants, LibHelpers } from "../AppStorage.sol";

library LibTokenizedVault {
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
        bytes32 dividendDenominationId;

        for (uint256 i = 0; i < dividendDenominations.length; ++i) {
            dividendDenominationId = dividendDenominations[i];
            uint256 totalDividend = s.totalDividends[_tokenId][dividendDenominationId];

            (, uint256 dividendDeduction) = _getWithdrawableDividendAndDeductionMath(_amount, supply, totalDividend);
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

        uint256 amount = s.tokenBalances[_tokenId][_ownerId];
        uint256 supply = _internalTokenSupply(_tokenId);
        uint256 totalDividend = s.totalDividends[_tokenId][_dividendTokenId];

        uint256 withdrawableDividend;
        uint256 dividendDeduction;
        (withdrawableDividend, dividendDeduction) = _getWithdrawableDividendAndDeductionMath(amount, supply, totalDividend);
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

        (withdrawableDividend_, ) = _getWithdrawableDividendAndDeductionMath(amount, supply, totalDividend);
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
    }

    function _getTokenSymbol(bytes32 _objectId) internal view returns (string memory) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return LibHelpers._bytes32ToString(s.objectTokenSymbol[_objectId]);
    }

    function _getWithdrawableDividendAndDeductionMath(
        uint256 _amount,
        uint256 _supply,
        uint256 _totalDividend
    ) internal pure returns (uint256 _withdrawableDividend, uint256 _dividendDeduction) {
        // The dividend that can be withdrawn is: withdrawableDividend = (totalDividend/tokenSupply) * _amount. The remainer (dust) is lost.
        // To get a smaller remainder we re-arrange to: withdrawableDividend = (totalDividend * _amount) / _supply

        uint256 totalDividendTimesAmount = _totalDividend * _amount;

        _withdrawableDividend = _supply == 0 ? 0 : (totalDividendTimesAmount / _supply);
        _dividendDeduction = _withdrawableDividend;

        // If there is a remainder, add 1 to the _dividendDeduction
        if (totalDividendTimesAmount > _withdrawableDividend * _supply) {
            _dividendDeduction += 1;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { AppStorage, LibAppStorage, SimplePolicy, TokenAmount } from "../AppStorage.sol";
import { LibHelpers } from "../libs/LibHelpers.sol";
import { LibObject } from "../libs/LibObject.sol";
import { LibConstants } from "../libs/LibConstants.sol";
import { LibTokenizedVault } from "../libs/LibTokenizedVault.sol";

library LibFeeRouter {
    event DistributeFees(address operator, uint256 totalFeesDistributed);
    event RecordDividend(bytes32 entityId, bytes32 dividendDenomination, uint256 amount);

    function _payPremiumComissions(bytes32 _policyId, uint256 _premiumPaid) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        SimplePolicy memory simplePolicy = s.simplePolicies[_policyId];

        bytes32 policyEntityId = LibObject._getParent(_policyId);

        uint256 commissionsCount = simplePolicy.commissionReceivers.length;
        for (uint256 i = 0; i < commissionsCount; i++) {
            uint256 commission = (_premiumPaid * simplePolicy.comissionBasisPoints[i]) / 1000;
            LibTokenizedVault._internalTransfer(policyEntityId, simplePolicy.commissionReceivers[i], simplePolicy.asset, commission);
        }

        uint256 comissionNaymsLtd = (_premiumPaid * s.premiumComissionNaymsLtdBP) / 1000;
        uint256 comissionNDF = (_premiumPaid * s.premiumComissionNDFBP) / 1000;
        uint256 comissionSTM = (_premiumPaid * s.premiumComissionSTMBP) / 1000;
        LibTokenizedVault._internalTransfer(policyEntityId, LibHelpers._stringToBytes32(LibConstants.NAYMS_LTD_IDENTIFIER), simplePolicy.asset, comissionNaymsLtd);
        LibTokenizedVault._internalTransfer(policyEntityId, LibHelpers._stringToBytes32(LibConstants.NDF_IDENTIFIER), simplePolicy.asset, comissionNDF);
        LibTokenizedVault._internalTransfer(policyEntityId, LibHelpers._stringToBytes32(LibConstants.STM_IDENTIFIER), simplePolicy.asset, comissionSTM);
    }

    function _payTradingComissions(
        bytes32 _makerId,
        bytes32 _takerId,
        bytes32 _tokenId,
        uint256 _requestedBuyAmount
    ) internal returns (uint256 commissionPaid_) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(s.tradingComissionNaymsLtdBP + s.tradingComissionNDFBP + s.tradingComissionSTMBP + s.tradingComissionMakerBP <= 1000, "commissions sum over 1000 bp");
        require(s.tradingComissionTotalBP <= 1000, "commission total must be<1000bp");

        // The rough commission deducted. The actual total might be different due to integer division
        uint256 roughCommissionPaid = (s.tradingComissionTotalBP * _requestedBuyAmount) / 1000;

        // Pay Nayms, LTD commission
        uint256 comissionNaymsLtd = (s.tradingComissionNaymsLtdBP * roughCommissionPaid) / 1000;
        LibTokenizedVault._internalTransfer(_takerId, LibHelpers._stringToBytes32(LibConstants.NAYMS_LTD_IDENTIFIER), _tokenId, comissionNaymsLtd);

        // Pay Nayms Discretionsry Fund commission
        uint256 comissionNDF = (s.tradingComissionNDFBP * roughCommissionPaid) / 1000;
        LibTokenizedVault._internalTransfer(_takerId, LibHelpers._stringToBytes32(LibConstants.NDF_IDENTIFIER), _tokenId, comissionNDF);

        // Pay Staking Mechanism commission
        uint256 comissionSTM = (s.tradingComissionSTMBP * roughCommissionPaid) / 1000;
        LibTokenizedVault._internalTransfer(_takerId, LibHelpers._stringToBytes32(LibConstants.STM_IDENTIFIER), _tokenId, comissionSTM);

        // Pay market maker commission
        uint256 comissionMaker = (s.tradingComissionMakerBP * roughCommissionPaid) / 1000;
        LibTokenizedVault._internalTransfer(_takerId, _makerId, _tokenId, comissionMaker);

        // Work it out again so the math is precise, ignoring remainers
        commissionPaid_ = comissionNaymsLtd + comissionNDF + comissionSTM + comissionMaker;
    }
}