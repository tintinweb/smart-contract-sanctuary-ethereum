// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import "../tokens/IERC721.sol";
import "../party/Party.sol";
import "../utils/Implementation.sol";
import "../utils/LibSafeERC721.sol";
import "../utils/LibRawResult.sol";
import "../globals/IGlobals.sol";
import "../gatekeepers/IGateKeeper.sol";

import "../market-wrapper/IMarketWrapper.sol";
import "./Crowdfund.sol";

/// @notice A crowdfund that can repeatedly bid on an auction for a specific NFT
///         (i.e. with a known token ID) until it wins.
contract AuctionCrowdfund is Crowdfund {
    using LibSafeERC721 for IERC721;
    using LibSafeCast for uint256;
    using LibRawResult for bytes;

    enum AuctionCrowdfundStatus {
        // The crowdfund has been created and contributions can be made and
        // acquisition functions may be called.
        Active,
        // An temporary state set by the contract during complex operations to
        // act as a reentrancy guard.
        Busy,
        // The crowdfund is over and has either won or lost.
        Finalized
    }

    struct AuctionCrowdfundOptions {
        // The name of the crowdfund.
        // This will also carry over to the governance party.
        string name;
        // The token symbol for both the crowdfund and the governance NFTs.
        string symbol;
        // Customization preset ID to use for the crowdfund and governance NFTs.
        uint256 customizationPresetId;
        // The auction ID (specific to the IMarketWrapper).
        uint256 auctionId;
        // IMarketWrapper contract that handles interactions with auction markets.
        IMarketWrapper market;
        // The ERC721 contract of the NFT being bought.
        IERC721 nftContract;
        // ID of the NFT being bought.
        uint256 nftTokenId;
        // How long this crowdfund has to bid on the NFT, in seconds.
        uint40 duration;
        // Maximum bid allowed.
        uint96 maximumBid;
        // An address that receives a portion of the final voting power
        // when the party transitions into governance.
        address payable splitRecipient;
        // What percentage (in bps) of the final total voting power `splitRecipient`
        // receives.
        uint16 splitBps;
        // If ETH is attached during deployment, it will be interpreted
        // as a contribution. This is who gets credit for that contribution.
        address initialContributor;
        // If there is an initial contribution, this is who they will delegate their
        // voting power to when the crowdfund transitions to governance.
        address initialDelegate;
        // The gatekeeper contract to use (if non-null) to restrict who can
        // contribute to this crowdfund. If used, only contributors or hosts can
        // call `bid()`.
        IGateKeeper gateKeeper;
        // The gate ID within the gateKeeper contract to use.
        bytes12 gateKeeperId;
        // Whether the party is only allowing a host to call `bid()`.
        bool onlyHostCanBid;
        // Fixed governance options (i.e. cannot be changed) that the governance
        // `Party` will be created with if the crowdfund succeeds.
        FixedGovernanceOpts governanceOpts;
    }

    event Bid(uint256 bidAmount);
    event Won(uint256 bid, Party party);
    event Lost();

    error InvalidAuctionIdError();
    error AuctionFinalizedError(uint256 auctionId);
    error AlreadyHighestBidderError();
    error ExceedsMaximumBidError(uint256 bidAmount, uint256 maximumBid);
    error MinimumBidExceedsMaximumBidError(uint256 bidAmount, uint256 maximumBid);
    error NoContributionsError();
    error AuctionNotExpiredError();

    /// @notice The NFT contract to buy.
    IERC721 public nftContract;
    /// @notice The NFT token ID to buy.
    uint256 public nftTokenId;
    /// @notice An adapter for the auction market (Zora, OpenSea, etc).
    /// @dev This will be delegatecalled into to execute bids.
    IMarketWrapper public market;
    /// @notice The auction ID to identify the auction on the `market`.
    uint256 public auctionId;
    /// @notice The maximum possible bid this crowdfund can make.
    uint96 public maximumBid;
    /// @notice The last successful bid() amount.
    uint96 public lastBid;
    /// @notice When this crowdfund expires. If the NFT has not been bought
    ///         by this time, participants can withdraw their contributions.
    uint40 public expiry;
    /// @notice Whether the party is only allowing a host to call `bid()`.
    bool public onlyHostCanBid;
    // Track extra status of the crowdfund specific to bids.
    AuctionCrowdfundStatus private _bidStatus;

    // Set the `Globals` contract.
    constructor(IGlobals globals) Crowdfund(globals) {}

    /// @notice Initializer to be delegatecalled by `Proxy` constructor. Will
    ///         revert if called outside the constructor.
    /// @param opts Options used to initialize the crowdfund. These are fixed
    ///             and cannot be changed later.
    function initialize(AuctionCrowdfundOptions memory opts)
        external
        payable
        onlyConstructor
    {
        if (opts.onlyHostCanBid && opts.governanceOpts.hosts.length == 0) {
            revert MissingHostsError();
        }
        nftContract = opts.nftContract;
        nftTokenId = opts.nftTokenId;
        market = opts.market;
        expiry = uint40(opts.duration + block.timestamp);
        auctionId = opts.auctionId;
        maximumBid = opts.maximumBid;
        onlyHostCanBid = opts.onlyHostCanBid;
        Crowdfund._initialize(CrowdfundOptions({
            name: opts.name,
            symbol: opts.symbol,
            customizationPresetId: opts.customizationPresetId,
            splitRecipient: opts.splitRecipient,
            splitBps: opts.splitBps,
            initialContributor: opts.initialContributor,
            initialDelegate: opts.initialDelegate,
            gateKeeper: opts.gateKeeper,
            gateKeeperId: opts.gateKeeperId,
            governanceOpts: opts.governanceOpts
        }));

        // Check that the auction can be bid on and is valid.
        if (!market.auctionIdMatchesToken(
            opts.auctionId,
            address(opts.nftContract),
            opts.nftTokenId))
        {
            revert InvalidAuctionIdError();
        }

        // Check that the minimum bid is less than the maximum bid.
        uint256 minimumBid = market.getMinimumBid(opts.auctionId);
        if (minimumBid > opts.maximumBid) {
            revert MinimumBidExceedsMaximumBidError(minimumBid, opts.maximumBid);
        }
    }

    /// @notice Accept naked ETH, e.g., if an auction needs to return ETH to us.
    receive() external payable {}

    /// @notice Place a bid on the NFT using the funds in this crowdfund,
    ///         placing the minimum possible bid to be the highest bidder, up to
    ///         `maximumBid`.
    /// @param governanceOpts The governance options the crowdfund was created with.
    /// @param hostIndex If the caller is a host, this is the index of the caller in the
    ///                  `governanceOpts.hosts` array.
    function bid(FixedGovernanceOpts memory governanceOpts, uint256 hostIndex)
        external
        onlyDelegateCall
    {
        // This function can be optionally restricted in different ways.
        if (onlyHostCanBid) {
            // Only a host can call this function.
            _assertIsHost(msg.sender, governanceOpts, hostIndex);
        } else if (address(gateKeeper) != address(0)) {
            // `onlyHostCanBid` is false and we are using a gatekeeper.
            // Only a contributor can call this function.
            _assertIsContributor(msg.sender);
        }

        // Check that the auction is still active.
        {
            CrowdfundLifecycle lc = getCrowdfundLifecycle();
            if (lc != CrowdfundLifecycle.Active) {
                revert WrongLifecycleError(lc);
            }
        }

        // Mark as busy to prevent `burn()`, `bid()`, and `contribute()`
        // getting called because this will result in a `CrowdfundLifecycle.Busy`.
        _bidStatus = AuctionCrowdfundStatus.Busy;

        // Make sure the auction is not finalized.
        IMarketWrapper market_ = market;
        uint256 auctionId_ = auctionId;
        if (market_.isFinalized(auctionId_)) {
            revert AuctionFinalizedError(auctionId_);
        }

        // Only bid if we are not already the highest bidder.
        if (market_.getCurrentHighestBidder(auctionId_) == address(this)) {
            revert AlreadyHighestBidderError();
        }

        // Get the minimum necessary bid to be the highest bidder.
        uint96 bidAmount = market_.getMinimumBid(auctionId_).safeCastUint256ToUint96();
        // Prevent unaccounted ETH from being used to inflate the bid and
        // create "ghost shares" in voting power.
        uint96 totalContributions_ = totalContributions;
        if (bidAmount > totalContributions_) {
            revert ExceedsTotalContributionsError(bidAmount, totalContributions_);
        }
        // Make sure the bid is less than the maximum bid.
        uint96 maximumBid_ = maximumBid;
        if (bidAmount > maximumBid_) {
            revert ExceedsMaximumBidError(bidAmount, maximumBid_);
        }
        lastBid = bidAmount;

        // No need to check that we have `bidAmount` since this will attempt to
        // transfer `bidAmount` ETH to the auction platform.
        (bool s, bytes memory r) = address(market_).delegatecall(abi.encodeCall(
            IMarketWrapper.bid,
            (auctionId_, bidAmount)
        ));
        if (!s) {
            r.rawRevert();
        }
        emit Bid(bidAmount);

        _bidStatus = AuctionCrowdfundStatus.Active;
    }

    /// @notice Calls finalize() on the market adapter, which will claim the NFT
    ///         (if necessary) if we won, or recover our bid (if necessary)
    ///         if we lost. If we won, a governance party will also be created.
    /// @param governanceOpts The options used to initialize governance in the
    ///                       `Party` instance created if the crowdfund wins.
    /// @return party_ Address of the `Party` instance created if successful.
    function finalize(FixedGovernanceOpts memory governanceOpts)
        external
        onlyDelegateCall
        returns (Party party_)
    {
        // Check that the auction is still active and has not passed the `expiry` time.
        CrowdfundLifecycle lc = getCrowdfundLifecycle();
        if (lc != CrowdfundLifecycle.Active && lc != CrowdfundLifecycle.Expired) {
            revert WrongLifecycleError(lc);
        }
        // Mark as busy to prevent burn(), bid(), and contribute()
        // getting called because this will result in a `CrowdfundLifecycle.Busy`.
        _bidStatus = AuctionCrowdfundStatus.Busy;
        uint96 lastBid_ = lastBid;
        {
            uint256 auctionId_ = auctionId;
            IMarketWrapper market_ = market;
            // If we've bid before or the CF is not expired,
            // finalize the auction.
            if (lastBid_ != 0 || lc == CrowdfundLifecycle.Active) {
                if (!market_.isFinalized(auctionId_)) {
                    // Note that even if this crowdfund has expired but the auction is still
                    // ongoing, this call can fail and block finalization until the auction ends.
                    (bool s, bytes memory r) = address(market_).call(abi.encodeCall(
                        IMarketWrapper.finalize,
                        auctionId_
                    ));
                    if (!s) {
                        r.rawRevert();
                    }
                }
            }
        }
        IERC721 nftContract_ = nftContract;
        uint256 nftTokenId_ = nftTokenId;
        // Are we now in possession of the NFT?
        if (nftContract_.safeOwnerOf(nftTokenId_) == address(this) && lastBid_ != 0) {
            // If we placed a bid before then consider it won for that price.
            // Create a governance party around the NFT.
            party_ = _createParty(
                governanceOpts,
                false,
                nftContract_,
                nftTokenId_
            );
            emit Won(lastBid_, party_);
        } else {
            // Otherwise we lost the auction or the NFT was gifted to us.
            // Clear `lastBid` so `_getFinalPrice()` is 0 and people can redeem their
            // full contributions when they burn their participation NFTs.
            lastBid = 0;
            emit Lost();
        }
        _bidStatus = AuctionCrowdfundStatus.Finalized;
    }

    /// @inheritdoc Crowdfund
    function getCrowdfundLifecycle() public override view returns (CrowdfundLifecycle) {
        // Do not rely on `market.isFinalized()` in case `auctionId` gets reused.
        AuctionCrowdfundStatus status = _bidStatus;
        if (status == AuctionCrowdfundStatus.Busy) {
            // In the midst of finalizing/bidding (trying to reenter).
            return CrowdfundLifecycle.Busy;
        }
        if (status == AuctionCrowdfundStatus.Finalized) {
            return address(party) != address(0)
                // If we're fully finalized and we have a party instance then we won.
                ? CrowdfundLifecycle.Won
                // Otherwise we lost.
                : CrowdfundLifecycle.Lost;
        }
        if (block.timestamp >= expiry) {
            // Expired. `finalize()` needs to be called.
            return CrowdfundLifecycle.Expired;
        }
        return CrowdfundLifecycle.Active;
    }

    function _getFinalPrice()
        internal
        override
        view
        returns (uint256 price)
    {
        return lastBid;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import "../tokens/IERC721.sol";
import "../party/Party.sol";
import "../utils/LibSafeERC721.sol";
import "../globals/IGlobals.sol";
import "../gatekeepers/IGateKeeper.sol";

import "./BuyCrowdfundBase.sol";

/// @notice A crowdfund that purchases a specific NFT (i.e., with a known token
///         ID) listing for a known price.
contract BuyCrowdfund is BuyCrowdfundBase {
    using LibSafeERC721 for IERC721;
    using LibSafeCast for uint256;

    struct BuyCrowdfundOptions {
        // The name of the crowdfund.
        // This will also carry over to the governance party.
        string name;
        // The token symbol for both the crowdfund and the governance NFTs.
        string symbol;
        // Customization preset ID to use for the crowdfund and governance NFTs.
        uint256 customizationPresetId;
        // The ERC721 contract of the NFT being bought.
        IERC721 nftContract;
        // ID of the NFT being bought.
        uint256 nftTokenId;
        // How long this crowdfund has to bid on the NFT, in seconds.
        uint40 duration;
        // Maximum amount this crowdfund will pay for the NFT.
        // If zero, no maximum.
        uint96 maximumPrice;
        // An address that receives a portion of the final voting power
        // when the party transitions into governance.
        address payable splitRecipient;
        // What percentage (in bps) of the final total voting power `splitRecipient`
        // receives.
        uint16 splitBps;
        // If ETH is attached during deployment, it will be interpreted
        // as a contribution. This is who gets credit for that contribution.
        address initialContributor;
        // If there is an initial contribution, this is who they will delegate their
        // voting power to when the crowdfund transitions to governance.
        address initialDelegate;
        // The gatekeeper contract to use (if non-null) to restrict who can
        // contribute to this crowdfund. If used, only contributors or hosts can
        // call `buy()`.
        IGateKeeper gateKeeper;
        // The gate ID within the gateKeeper contract to use.
        bytes12 gateKeeperId;
        // Whether the party is only allowing a host to call `buy()`.
        bool onlyHostCanBuy;
        // Fixed governance options (i.e. cannot be changed) that the governance
        // `Party` will be created with if the crowdfund succeeds.
        FixedGovernanceOpts governanceOpts;
    }

    /// @notice The NFT token ID to buy.
    uint256 public nftTokenId;
    /// @notice The NFT contract to buy.
    IERC721 public nftContract;
    /// @notice Whether the party is only allowing a host to call `buy()`.
    bool public onlyHostCanBuy;

    // Set the `Globals` contract.
    constructor(IGlobals globals) BuyCrowdfundBase(globals) {}

    /// @notice Initializer to be delegatecalled by `Proxy` constructor. Will
    ///         revert if called outside the constructor.
    /// @param opts Options used to initialize the crowdfund. These are fixed
    ///             and cannot be changed later.
    function initialize(BuyCrowdfundOptions memory opts)
        external
        payable
        onlyConstructor
    {
        if (opts.onlyHostCanBuy && opts.governanceOpts.hosts.length == 0) {
            revert MissingHostsError();
        }
        BuyCrowdfundBase._initialize(BuyCrowdfundBaseOptions({
            name: opts.name,
            symbol: opts.symbol,
            customizationPresetId: opts.customizationPresetId,
            duration: opts.duration,
            maximumPrice: opts.maximumPrice,
            splitRecipient: opts.splitRecipient,
            splitBps: opts.splitBps,
            initialContributor: opts.initialContributor,
            initialDelegate: opts.initialDelegate,
            gateKeeper: opts.gateKeeper,
            gateKeeperId: opts.gateKeeperId,
            governanceOpts: opts.governanceOpts
        }));
        onlyHostCanBuy = opts.onlyHostCanBuy;
        nftTokenId = opts.nftTokenId;
        nftContract = opts.nftContract;
    }

    /// @notice Execute arbitrary calldata to perform a buy, creating a party
    ///         if it successfully buys the NFT.
    /// @param callTarget The target contract to call to buy the NFT.
    /// @param callValue The amount of ETH to send with the call.
    /// @param callData The calldata to execute.
    /// @param governanceOpts The options used to initialize governance in the
    ///                       `Party` instance created if the buy was successful.
    /// @param hostIndex If the caller is a host, this is the index of the caller in the
    ///                  `governanceOpts.hosts` array.
    /// @return party_ Address of the `Party` instance created after its bought.
    function buy(
        address payable callTarget,
        uint96 callValue,
        bytes memory callData,
        FixedGovernanceOpts memory governanceOpts,
        uint256 hostIndex
    )
        external
        returns (Party party_)
    {
        // This function can be optionally restricted in different ways.
        bool isValidatedGovernanceOpts;
        if (onlyHostCanBuy) {
            // Only a host can call this function.
            isValidatedGovernanceOpts =
                _assertIsHost(msg.sender, governanceOpts, hostIndex);
        } else if (address(gateKeeper) != address(0)) {
            // `onlyHostCanBuy` is false and we are using a gatekeeper.
            // Only a contributor can call this function.
            _assertIsContributor(msg.sender);
        }

        return _buy(
            nftContract,
            nftTokenId,
            callTarget,
            callValue,
            callData,
            governanceOpts,
            isValidatedGovernanceOpts
        );
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import "../tokens/IERC721.sol";
import "../party/Party.sol";
import "../utils/Implementation.sol";
import "../utils/LibSafeERC721.sol";
import "../utils/LibRawResult.sol";
import "../globals/IGlobals.sol";
import "../gatekeepers/IGateKeeper.sol";

import "./Crowdfund.sol";

// Base for BuyCrowdfund and CollectionBuyCrowdfund
abstract contract BuyCrowdfundBase is Crowdfund {
    using LibSafeERC721 for IERC721;
    using LibSafeCast for uint256;
    using LibRawResult for bytes;

    struct BuyCrowdfundBaseOptions {
        // The name of the crowdfund.
        // This will also carry over to the governance party.
        string name;
        // The token symbol for both the crowdfund and the governance NFTs.
        string symbol;
        // Customization preset ID to use for the crowdfund and governance NFTs.
        uint256 customizationPresetId;
        // How long this crowdfund has to bid on the NFT, in seconds.
        uint40 duration;
        // Maximum amount this crowdfund will pay for the NFT.
        uint96 maximumPrice;
        // An address that receives an extra share of the final voting power
        // when the party transitions into governance.
        address payable splitRecipient;
        // What percentage (in bps) of the final total voting power `splitRecipient`
        // receives.
        uint16 splitBps;
        // If ETH is attached during deployment, it will be interpreted
        // as a contribution. This is who gets credit for that contribution.
        address initialContributor;
        // If there is an initial contribution, this is who they will delegate their
        // voting power to when the crowdfund transitions to governance.
        address initialDelegate;
        // The gatekeeper contract to use (if non-null) to restrict who can
        // contribute to this crowdfund.
        IGateKeeper gateKeeper;
        // The gatekeeper contract to use (if non-null).
        bytes12 gateKeeperId;
        // Governance options.
        FixedGovernanceOpts governanceOpts;
    }

    event Won(Party party, IERC721 token, uint256 tokenId, uint256 settledPrice);
    event Lost();

    error MaximumPriceError(uint96 callValue, uint96 maximumPrice);
    error NoContributionsError();
    error FailedToBuyNFTError(IERC721 token, uint256 tokenId);
    error CallProhibitedError(address target, bytes data);

    /// @notice When this crowdfund expires.
    uint40 public expiry;
    /// @notice Maximum amount this crowdfund will pay for the NFT. If zero, no maximum.
    uint96 public maximumPrice;
    /// @notice What the NFT was actually bought for.
    uint96 public settledPrice;

    // Set the `Globals` contract.
    constructor(IGlobals globals) Crowdfund(globals) {}

    // Initialize storage for proxy contracts.
    function _initialize(BuyCrowdfundBaseOptions memory opts)
        internal
    {
        expiry = uint40(opts.duration + block.timestamp);
        maximumPrice = opts.maximumPrice;
        Crowdfund._initialize(CrowdfundOptions({
            name: opts.name,
            symbol: opts.symbol,
            customizationPresetId: opts.customizationPresetId,
            splitRecipient: opts.splitRecipient,
            splitBps: opts.splitBps,
            initialContributor: opts.initialContributor,
            initialDelegate: opts.initialDelegate,
            gateKeeper: opts.gateKeeper,
            gateKeeperId: opts.gateKeeperId,
            governanceOpts: opts.governanceOpts
        }));
    }

    // Execute arbitrary calldata to perform a buy, creating a party
    // if it successfully buys the NFT.
    function _buy(
        IERC721 token,
        uint256 tokenId,
        address payable callTarget,
        uint96 callValue,
        bytes memory callData,
        FixedGovernanceOpts memory governanceOpts,
        bool isValidatedGovernanceOpts
    )
        internal
        onlyDelegateCall
        returns (Party party_)
    {
        // Check that the call is not prohibited.
        if (!_isCallAllowed(callTarget, callData, token)) {
            revert CallProhibitedError(callTarget, callData);
        }
        // Check that the crowdfund is still active.
        CrowdfundLifecycle lc = getCrowdfundLifecycle();
        if (lc != CrowdfundLifecycle.Active) {
            revert WrongLifecycleError(lc);
        }
        // Prevent unaccounted ETH from being used to inflate the price and
        // create "ghost shares" in voting power.
        {
            uint96 totalContributions_ = totalContributions;
            if (callValue > totalContributions_) {
                revert ExceedsTotalContributionsError(callValue, totalContributions_);
            }
        }
        // Check that the call value is under the maximum price.
        {
            uint96 maximumPrice_ = maximumPrice;
            if (callValue > maximumPrice_) {
                revert MaximumPriceError(callValue, maximumPrice_);
            }
        }
        // Temporarily set to non-zero as a reentrancy guard.
        settledPrice = type(uint96).max;

        // Execute the call to buy the NFT, but only if we have a nonzero callValue
        // because a zero callValue will cause the CF to lose anyawy.
        if (callValue != 0) {
            (bool s, bytes memory r) = callTarget.call{ value: callValue }(callData);
            if (!s) {
                r.rawRevert();
            }
        }
        // Make sure we acquired the NFT we want.
        if (token.safeOwnerOf(tokenId) == address(this)) {
            if (callValue == 0) {
                // If the purchase was free or the NFT was "gifted" to us,
                // refund all contributors by declaring we lost.
                settledPrice = 0;
                // Set the expiry to now so people can withdraw their contributions.
                expiry = uint40(block.timestamp);
                emit Lost();
            } else {
                settledPrice = callValue;
                emit Won(
                    // Create a party around the newly bought NFT.
                    party_ = _createParty(
                        governanceOpts,
                        isValidatedGovernanceOpts,
                        token,
                        tokenId
                    ),
                    token,
                    tokenId,
                    callValue
                );
            }
        } else {
            revert FailedToBuyNFTError(token, tokenId);
        }
    }

    /// @inheritdoc Crowdfund
    function getCrowdfundLifecycle() public override view returns (CrowdfundLifecycle) {
        // If there is a settled price then we tried to buy the NFT.
        if (settledPrice != 0) {
            return address(party) != address(0)
                // If we have a party, then we succeeded buying the NFT.
                ? CrowdfundLifecycle.Won
                // Otherwise we're in the middle of the `buy()`.
                : CrowdfundLifecycle.Busy;
        }
        if (block.timestamp >= expiry) {
            // Expired, but nothing to do so skip straight to lost, or NFT was
            // acquired for free so refund contributors and trigger lost.
            return CrowdfundLifecycle.Lost;
        }
        return CrowdfundLifecycle.Active;
    }

    function _getFinalPrice()
        internal
        override
        view
        returns (uint256)
    {
        return settledPrice;
    }

    function _isCallAllowed(
        address payable callTarget,
        bytes memory callData,
        IERC721 token
    )
        private
        view
        returns (bool isAllowed)
    {
        // Ensure the call target isn't trying to reenter
        if (callTarget == address(this)) {
            return false;
        }
        if (callTarget == address(token) && callData.length >= 4) {
            // Get the function selector of the call (first 4 bytes of calldata).
            bytes4 selector;
            assembly {
                selector := and(
                    mload(add(callData, 32)),
                    0xffffffff00000000000000000000000000000000000000000000000000000000
                )
            }
            // Prevent approving the NFT to be transferred out from the crowdfund.
            if (
                selector == IERC721.approve.selector ||
                selector == IERC721.setApprovalForAll.selector
            ) {
                return false;
            }
        }
        // All other calls are allowed.
        return true;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import "../tokens/IERC721.sol";
import "../party/Party.sol";
import "../utils/LibSafeERC721.sol";
import "../utils/LibRawResult.sol";
import "../globals/IGlobals.sol";
import "../gatekeepers/IGateKeeper.sol";

import "./BuyCrowdfundBase.sol";

/// @notice A crowdfund that purchases any NFT from a collection (i.e., any
/// token ID) from a collection for a known price. Like `BuyCrowdfund` but allows
/// any token ID to be bought.
contract CollectionBuyCrowdfund is BuyCrowdfundBase {
    using LibSafeERC721 for IERC721;
    using LibSafeCast for uint256;

    struct CollectionBuyCrowdfundOptions {
        // The name of the crowdfund.
        // This will also carry over to the governance party.
        string name;
        // The token symbol for both the crowdfund and the governance NFTs.
        string symbol;
        // Customization preset ID to use for the crowdfund and governance NFTs.
        uint256 customizationPresetId;
        // The ERC721 contract of the NFT being bought.
        IERC721 nftContract;
        // How long this crowdfund has to bid on the NFT, in seconds.
        uint40 duration;
        // Maximum amount this crowdfund will pay for the NFT.
        // If zero, no maximum.
        uint96 maximumPrice;
        // An address that receives a portion of the final voting power
        // when the party transitions into governance.
        address payable splitRecipient;
        // What percentage (in bps) of the final total voting power `splitRecipient`
        // receives.
        uint16 splitBps;
        // If ETH is attached during deployment, it will be interpreted
        // as a contribution. This is who gets credit for that contribution.
        address initialContributor;
        // If there is an initial contribution, this is who they will delegate their
        // voting power to when the crowdfund transitions to governance.
        address initialDelegate;
        // The gatekeeper contract to use (if non-null) to restrict who can
        // contribute to this crowdfund.
        IGateKeeper gateKeeper;
        // The gate ID within the gateKeeper contract to use.
        bytes12 gateKeeperId;
        // Fixed governance options (i.e. cannot be changed) that the governance
        // `Party` will be created with if the crowdfund succeeds.
        FixedGovernanceOpts governanceOpts;
    }

    /// @notice The NFT contract to buy.
    IERC721 public nftContract;

    // Set the `Globals` contract.
    constructor(IGlobals globals) BuyCrowdfundBase(globals) {}

    /// @notice Initializer to be delegatecalled by `Proxy` constructor. Will
    ///         revert if called outside the constructor.
    /// @param opts Options used to initialize the crowdfund. These are fixed
    ///             and cannot be changed later.
    function initialize(CollectionBuyCrowdfundOptions memory opts)
        external
        payable
        onlyConstructor
    {
        if (opts.governanceOpts.hosts.length == 0) {
            revert MissingHostsError();
        }
        BuyCrowdfundBase._initialize(BuyCrowdfundBaseOptions({
            name: opts.name,
            symbol: opts.symbol,
            customizationPresetId: opts.customizationPresetId,
            duration: opts.duration,
            maximumPrice: opts.maximumPrice,
            splitRecipient: opts.splitRecipient,
            splitBps: opts.splitBps,
            initialContributor: opts.initialContributor,
            initialDelegate: opts.initialDelegate,
            gateKeeper: opts.gateKeeper,
            gateKeeperId: opts.gateKeeperId,
            governanceOpts: opts.governanceOpts
        }));
        nftContract = opts.nftContract;
    }

    /// @notice Execute arbitrary calldata to perform a buy, creating a party
    ///         if it successfully buys the NFT. Only a host may call this.
    /// @param tokenId The token ID of the NFT in the collection to buy.
    /// @param callTarget The target contract to call to buy the NFT.
    /// @param callValue The amount of ETH to send with the call.
    /// @param callData The calldata to execute.
    /// @param governanceOpts The options used to initialize governance in the
    ///                       `Party` instance created if the buy was successful.
    /// @param hostIndex If the caller is a host, this is the index of the caller in the
    ///                  `governanceOpts.hosts` array.
    /// @return party_ Address of the `Party` instance created after its bought.
    function buy(
        uint256 tokenId,
        address payable callTarget,
        uint96 callValue,
        bytes memory callData,
        FixedGovernanceOpts memory governanceOpts,
        uint256 hostIndex
    )
        external
        returns (Party party_)
    {
        // This function is always restricted to hosts.
        bool isValidatedGovernanceOpts =
                _assertIsHost(msg.sender, governanceOpts, hostIndex);
        return _buy(
            nftContract,
            tokenId,
            callTarget,
            callValue,
            callData,
            governanceOpts,
            isValidatedGovernanceOpts
        );
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import "../utils/LibAddress.sol";
import "../utils/LibRawResult.sol";
import "../utils/LibSafeCast.sol";
import "../tokens/ERC721Receiver.sol";
import "../party/Party.sol";
import "../globals/IGlobals.sol";
import "../gatekeepers/IGateKeeper.sol";
import "../renderers/RendererStorage.sol";

import "./CrowdfundNFT.sol";

// Base contract for AuctionCrowdfund/BuyCrowdfund.
// Holds post-win/loss logic. E.g., burning contribution NFTs and creating a
// party after winning.
abstract contract Crowdfund is Implementation, ERC721Receiver, CrowdfundNFT {
    using LibRawResult for bytes;
    using LibSafeCast for uint256;
    using LibAddress for address payable;

    enum CrowdfundLifecycle {
        Invalid,
        Active,
        Expired,
        Busy, // Temporary. mid-settlement state
        Lost,
        Won
    }

    // PartyGovernance options that must be known and fixed at crowdfund creation.
    // This is a subset of PartyGovernance.GovernanceOpts.
    struct FixedGovernanceOpts {
        // Address of initial party hosts.
        address[] hosts;
        // How long people can vote on a proposal.
        uint40 voteDuration;
        // How long to wait after a proposal passes before it can be
        // executed.
        uint40 executionDelay;
        // Minimum ratio of accept votes to consider a proposal passed,
        // in bps, where 10,000 == 100%.
        uint16 passThresholdBps;
        // Fee bps for governance distributions.
        uint16 feeBps;
        // Fee recipeint for governance distributions.
        address payable feeRecipient;
    }

    // Options to be passed into `_initialize()` when the crowdfund is created.
    struct CrowdfundOptions {
        string name;
        string symbol;
        uint256 customizationPresetId;
        address payable splitRecipient;
        uint16 splitBps;
        address initialContributor;
        address initialDelegate;
        IGateKeeper gateKeeper;
        bytes12 gateKeeperId;
        FixedGovernanceOpts governanceOpts;
    }

    // A record of a single contribution made by a user.
    // Stored in `_contributionsByContributor`.
    struct Contribution {
        // The value of `Crowdfund.totalContributions` when this contribution was made.
        uint96 previousTotalContributions;
        // How much was this contribution.
        uint96 amount;
    }

    // A record of the refund and governance NFT owed to a contributor if it
    // could not be received by them from `burn()`.
    struct Claim {
        uint256 refund;
        uint256 governanceTokenId;
    }

    error PartyAlreadyExistsError(Party party);
    error WrongLifecycleError(CrowdfundLifecycle lc);
    error InvalidGovernanceOptionsError();
    error InvalidDelegateError();
    error NoPartyError();
    error NotAllowedByGateKeeperError(address contributor, IGateKeeper gateKeeper, bytes12 gateKeeperId, bytes gateData);
    error SplitRecipientAlreadyBurnedError();
    error InvalidBpsError(uint16 bps);
    error ExceedsTotalContributionsError(uint96 value, uint96 totalContributions);
    error NothingToClaimError();
    error OnlyPartyHostError();
    error OnlyContributorError();
    error MissingHostsError();

    event Burned(address contributor, uint256 ethUsed, uint256 ethOwed, uint256 votingPower);
    event Contributed(address contributor, uint256 amount, address delegate, uint256 previousTotalContributions);

    // The `Globals` contract storing global configuration values. This contract
    // is immutable and it’s address will never change.
    IGlobals private immutable _GLOBALS;

    /// @notice The party instance created by `_createParty()`, if any after a
    ///         successful crowdfund.
    Party public party;
    /// @notice The total (recorded) ETH contributed to this crowdfund.
    uint96 public totalContributions;
    /// @notice The gatekeeper contract to use (if non-null) to restrict who can
    ///         contribute to the party.
    IGateKeeper public gateKeeper;
    /// @notice The ID of the gatekeeper strategy to use.
    bytes12 public gateKeeperId;
    /// @notice Who will receive a reserved portion of governance power when
    ///         the governance party is created.
    address payable public splitRecipient;
    /// @notice How much governance power to reserve for `splitRecipient`,
    ///         in bps, where 10,000 = 100%.
    uint16 public splitBps;
    // Whether the share for split recipient has been claimed through `burn()`.
    bool private _splitRecipientHasBurned;
    /// @notice Hash of party governance options passed into `initialize()`.
    ///         Used to check whether the `GovernanceOpts` passed into
    ///         `_createParty()` matches.
    bytes32 public governanceOptsHash;
    /// @notice Who a contributor last delegated to.
    mapping(address => address) public delegationsByContributor;
    // Array of contributions by a contributor.
    // One is created for every nonzero contribution made.
    // `internal` for testing purposes only.
    mapping(address => Contribution[]) internal _contributionsByContributor;
    /// @notice Stores the amount of ETH owed back to a contributor and governance NFT
    ///         that should be minted to them if it could not be transferred to
    ///         them with `burn()`.
    mapping(address => Claim) public claims;

    // Set the `Globals` contract.
    constructor(IGlobals globals) CrowdfundNFT(globals) {
        _GLOBALS = globals;
    }

    // Initialize storage for proxy contracts, credit initial contribution (if
    // any), and setup gatekeeper.
    function _initialize(CrowdfundOptions memory opts)
        internal
    {
        CrowdfundNFT._initialize(opts.name, opts.symbol, opts.customizationPresetId);
        // Check that BPS values do not exceed the max.
        if (opts.governanceOpts.feeBps > 1e4) {
            revert InvalidBpsError(opts.governanceOpts.feeBps);
        }
        if (opts.governanceOpts.passThresholdBps > 1e4) {
            revert InvalidBpsError(opts.governanceOpts.passThresholdBps);
        }
        if (opts.splitBps > 1e4) {
            revert InvalidBpsError(opts.splitBps);
        }
        governanceOptsHash = _hashFixedGovernanceOpts(opts.governanceOpts);
        splitRecipient = opts.splitRecipient;
        splitBps = opts.splitBps;
        // If the deployer passed in some ETH during deployment, credit them
        // for the initial contribution.
        uint96 initialContribution = msg.value.safeCastUint256ToUint96();
        if (initialContribution > 0) {
            // If this contract has ETH, either passed in during deployment or
            // pre-existing, credit it to the `initialContributor`.
            _contribute(opts.initialContributor, initialContribution, opts.initialDelegate, 0, "");
        }
        // Set up gatekeeper after initial contribution (initial always gets in).
        gateKeeper = opts.gateKeeper;
        gateKeeperId = opts.gateKeeperId;
    }

    /// @notice Burn the participation NFT for `contributor`, potentially
    ///         minting voting power and/or refunding unused ETH. `contributor`
    ///         may also be the split recipient, regardless of whether they are
    ///         also a contributor or not. This can be called by anyone on a
    ///         contributor's behalf to unlock their voting power in the
    ///         governance stage ensuring delegates receive their voting
    ///         power and governance is not stalled.
    /// @dev If the party has won, someone needs to call `_createParty()` first. After
    ///      which, `burn()` will refund unused ETH and mint governance tokens for the
    ///      given `contributor`.
    ///      If the party has lost, this will only refund unused ETH (all of it) for
    ///      the given `contributor`.
    /// @param contributor The contributor whose NFT to burn for.
    function burn(address payable contributor) public {
        return _burn(contributor, getCrowdfundLifecycle(), party);
    }

    /// @dev Alias for `burn()`.
    function activateOrRefund(address payable contributor) external {
        burn(contributor);
    }

    /// @notice `burn()` in batch form.
    ///         Will not revert if any individual burn fails.
    /// @param contributors The contributors whose NFT to burn for.
    /// @param revertOnFailure If true, revert if any burn fails.
    function batchBurn(address payable[] calldata contributors, bool revertOnFailure) public {
        for (uint256 i = 0; i < contributors.length; ++i) {
            (bool s, bytes memory r) = address(this).delegatecall(
                abi.encodeCall(this.burn, (contributors[i]))
            );
            if (revertOnFailure && !s) {
                r.rawRevert();
            }
        }
    }

    /// @dev Alias for `batchBurn()`.
    function batchActivateOrRefund(
        address payable[] calldata contributors,
        bool revertOnFailure
    )
        external
    {
        batchBurn(contributors, revertOnFailure);
    }

    /// @notice Claim a governance NFT or refund that is owed back but could not be
    ///         given due to error in `_burn()` (eg. a contract that does not
    ///         implement `onERC721Received()` or cannot receive ETH). Only call
    ///         this if refund and governance NFT minting could not be returned
    ///         with `burn()`.
    /// @param receiver The address to receive the NFT or refund.
    function claim(address payable receiver) external {
        Claim memory claimInfo = claims[msg.sender];
        delete claims[msg.sender];

        if (claimInfo.refund == 0 && claimInfo.governanceTokenId == 0) {
            revert NothingToClaimError();
        }

        if (claimInfo.refund != 0) {
            receiver.transferEth(claimInfo.refund);
        }

        if (claimInfo.governanceTokenId != 0) {
            party.safeTransferFrom(address(this), receiver, claimInfo.governanceTokenId);
        }
    }

    /// @notice Contribute to this crowdfund and/or update your delegation for the
    ///         governance phase should the crowdfund succeed.
    ///         For restricted crowdfunds, `gateData` can be provided to prove
    ///         membership to the gatekeeper.
    /// @param delegate The address to delegate to for the governance phase.
    /// @param gateData Data to pass to the gatekeeper to prove eligibility.
    function contribute(address delegate, bytes memory gateData)
        public
        payable
        onlyDelegateCall
    {
        _contribute(
            msg.sender,
            msg.value.safeCastUint256ToUint96(),
            delegate,
            // We cannot use `address(this).balance - msg.value` as the previous
            // total contributions in case someone forces (suicides) ETH into this
            // contract. This wouldn't be such a big deal for open crowdfunds
            // but private ones (protected by a gatekeeper) could be griefed
            // because it would ultimately result in governance power that
            // is unattributed/unclaimable, meaning that party will never be
            // able to reach 100% consensus.
            totalContributions,
            gateData
        );
    }

    /// @inheritdoc EIP165
    function supportsInterface(bytes4 interfaceId)
        public
        override(ERC721Receiver, CrowdfundNFT)
        pure
        returns (bool)
    {
        return ERC721Receiver.supportsInterface(interfaceId) ||
            CrowdfundNFT.supportsInterface(interfaceId);
    }

    /// @notice Retrieve info about a participant's contributions.
    /// @dev This will only be called off-chain so doesn't have to be optimal.
    /// @param contributor The contributor to retrieve contributions for.
    /// @return ethContributed The total ETH contributed by `contributor`.
    /// @return ethUsed The total ETH used by `contributor` to acquire the NFT.
    /// @return ethOwed The total ETH refunded back to `contributor`.
    /// @return votingPower The total voting power minted to `contributor`.
    function getContributorInfo(address contributor)
        external
        view
        returns (
            uint256 ethContributed,
            uint256 ethUsed,
            uint256 ethOwed,
            uint256 votingPower
        )
    {
        CrowdfundLifecycle lc = getCrowdfundLifecycle();
        if (lc == CrowdfundLifecycle.Won || lc == CrowdfundLifecycle.Lost) {
            (ethUsed, ethOwed, votingPower) = _getFinalContribution(contributor);
            ethContributed = ethUsed + ethOwed;
        } else {
            Contribution[] memory contributions =
                _contributionsByContributor[contributor];
            uint256 numContributions = contributions.length;
            for (uint256 i; i < numContributions; ++i) {
                ethContributed += contributions[i].amount;
            }
        }
    }

    /// @notice Get the current lifecycle of the crowdfund.
    function getCrowdfundLifecycle() public virtual view returns (CrowdfundLifecycle lifecycle);

    // Get the final sale price of the bought assets. This will also be the total
    // voting power of the governance party.
    function _getFinalPrice() internal virtual view returns (uint256);

    // Assert that `who` is a host at `governanceOpts.hosts[hostIndex]` and,
    // if so, assert that the governance opts is the same as the crowdfund
    // was created with.
    // Return true if `governanceOpts` was validated in the process.
    function _assertIsHost(
        address who,
        FixedGovernanceOpts memory governanceOpts,
        uint256 hostIndex
    )
        internal
        view
        returns (bool isValidatedGovernanceOpts)
    {
        if (who == governanceOpts.hosts[hostIndex]) {
            _assertValidGovernanceOpts(governanceOpts);
            return true;
        }
        revert OnlyPartyHostError();
    }

    // Assert that `who` is a contributor to the crowdfund.
    function _assertIsContributor(address who)
        internal
        view
    {
        if (_contributionsByContributor[who].length == 0) {
            revert OnlyContributorError();
        }
    }

    // Can be called after a party has won.
    // Deploys and initializes a `Party` instance via the `PartyFactory`
    // and transfers the bought NFT to it.
    // After calling this, anyone can burn CF tokens on a contributor's behalf
    // with the `burn()` function.
    function _createParty(
        FixedGovernanceOpts memory governanceOpts,
        bool governanceOptsAlreadyValidated,
        IERC721[] memory preciousTokens,
        uint256[] memory preciousTokenIds
    )
        internal
        returns (Party party_)
    {
        if (party != Party(payable(0))) {
            revert PartyAlreadyExistsError(party);
        }
        // If the governance opts haven't already been validated, make sure that
        // it hasn't been tampered with.
        if (!governanceOptsAlreadyValidated) {
            _assertValidGovernanceOpts(governanceOpts);
        }
        // Create a party.
        party = party_ = _getPartyFactory()
            .createParty(
                address(this),
                Party.PartyOptions({
                    name: name,
                    symbol: symbol,
                    // Indicates to the party to use the same customization preset as the crowdfund.
                    customizationPresetId: 0,
                    governance: PartyGovernance.GovernanceOpts({
                        hosts: governanceOpts.hosts,
                        voteDuration: governanceOpts.voteDuration,
                        executionDelay: governanceOpts.executionDelay,
                        passThresholdBps: governanceOpts.passThresholdBps,
                        totalVotingPower: _getFinalPrice().safeCastUint256ToUint96(),
                        feeBps: governanceOpts.feeBps,
                        feeRecipient: governanceOpts.feeRecipient
                    })
                }),
                preciousTokens,
                preciousTokenIds
            );
        // Transfer the acquired NFTs to the new party.
        for (uint256 i; i < preciousTokens.length; ++i) {
            preciousTokens[i].transferFrom(address(this), address(party_), preciousTokenIds[i]);
        }
    }

    // Overloaded single token wrapper for _createParty()
    function _createParty(
        FixedGovernanceOpts memory governanceOpts,
        bool governanceOptsAlreadyValidated,
        IERC721 preciousToken,
        uint256 preciousTokenId
    )
        internal
        returns (Party party_)
    {
        IERC721[] memory tokens = new IERC721[](1);
        tokens[0] = preciousToken;
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = preciousTokenId;
        return _createParty(governanceOpts, governanceOptsAlreadyValidated, tokens, tokenIds);
    }

    // Assert that the hash of `opts` matches the hash this crowdfund was initialized with.
    function _assertValidGovernanceOpts(FixedGovernanceOpts memory governanceOpts)
        private
        view
    {
        bytes32 governanceOptsHash_ = _hashFixedGovernanceOpts(governanceOpts);
        if (governanceOptsHash_ != governanceOptsHash) {
            revert InvalidGovernanceOptionsError();
        }
    }

    function _hashFixedGovernanceOpts(FixedGovernanceOpts memory opts)
        internal
        pure
        returns (bytes32 h)
    {
        // Hash in place.
        assembly {
            // Replace the address[] hosts field with its hash temporarily.
            let oldHostsFieldValue := mload(opts)
            mstore(opts, keccak256(add(oldHostsFieldValue, 0x20), mul(mload(oldHostsFieldValue), 32)))
            // Hash the entire struct.
            h := keccak256(opts, 0xC0)
            // Restore old hosts field value.
            mstore(opts, oldHostsFieldValue)
        }
    }

    function _getFinalContribution(address contributor)
        internal
        view
        returns (uint256 ethUsed, uint256 ethOwed, uint256 votingPower)
    {
        uint256 totalEthUsed = _getFinalPrice();
        {
            Contribution[] memory contributions = _contributionsByContributor[contributor];
            uint256 numContributions = contributions.length;
            for (uint256 i; i < numContributions; ++i) {
                Contribution memory c = contributions[i];
                if (c.previousTotalContributions >= totalEthUsed) {
                    // This entire contribution was not used.
                    ethOwed += c.amount;
                } else if (c.previousTotalContributions + c.amount <= totalEthUsed) {
                    // This entire contribution was used.
                    ethUsed += c.amount;
                } else {
                    // This contribution was partially used.
                    uint256 partialEthUsed = totalEthUsed - c.previousTotalContributions;
                    ethUsed += partialEthUsed;
                    ethOwed = c.amount - partialEthUsed;
                }
            }
        }
        // one SLOAD with optimizer on
        address splitRecipient_ = splitRecipient;
        uint256 splitBps_ = splitBps;
        if (splitRecipient_ == address(0)) {
            splitBps_ = 0;
        }
        votingPower = ((1e4 - splitBps_) * ethUsed) / 1e4;
        if (splitRecipient_ == contributor) {
            // Split recipient is also the contributor so just add the split
            // voting power.
            votingPower += (splitBps_ * totalEthUsed + (1e4 - 1)) / 1e4; // round up
        }
    }

    function _contribute(
        address contributor,
        uint96 amount,
        address delegate,
        uint96 previousTotalContributions,
        bytes memory gateData
    )
        private
    {
        // Require a non-null delegate.
        if (delegate == address(0)) {
            revert InvalidDelegateError();
        }
        // Must not be blocked by gatekeeper.
        IGateKeeper _gateKeeper = gateKeeper;
        if (_gateKeeper != IGateKeeper(address(0))) {
            if (!_gateKeeper.isAllowed(contributor, gateKeeperId, gateData)) {
                revert NotAllowedByGateKeeperError(
                    contributor,
                    _gateKeeper,
                    gateKeeperId,
                    gateData
                );
            }
        }

        // Update delegate.
        // OK if this happens out of cycle.
        delegationsByContributor[contributor] = delegate;
        emit Contributed(contributor, amount, delegate, previousTotalContributions);

        // OK to contribute with zero just to update delegate.
        if (amount != 0) {
            // Only allow contributions while the crowdfund is active.
            {
                CrowdfundLifecycle lc = getCrowdfundLifecycle();
                if (lc != CrowdfundLifecycle.Active) {
                    revert WrongLifecycleError(lc);
                }
            }
            // Increase total contributions.
            totalContributions += amount;
            // Create contributions entry for this contributor.
            Contribution[] storage contributions = _contributionsByContributor[contributor];
            uint256 numContributions = contributions.length;
            if (numContributions >= 1) {
                Contribution memory lastContribution = contributions[numContributions - 1];
                // If no one else (other than this contributor) has contributed since,
                // we can just reuse this contributor's last entry.
                uint256 totalContributionsAmountForReuse =
                    lastContribution.previousTotalContributions + lastContribution.amount;
                if (totalContributionsAmountForReuse == previousTotalContributions) {
                    lastContribution.amount += amount;
                    contributions[numContributions - 1] = lastContribution;
                    return;
                }
            }
            // Add a new contribution entry.
            contributions.push(Contribution({
                previousTotalContributions: previousTotalContributions,
                amount: amount
            }));
            // Mint a participation NFT if this is their first contribution.
            if (numContributions == 0) {
                _mint(contributor);
            }
        }
    }

    function _burn(address payable contributor, CrowdfundLifecycle lc, Party party_) private {
        // If the CF has won, a party must have been created prior.
        if (lc == CrowdfundLifecycle.Won) {
            if (party_ == Party(payable(0))) {
                revert NoPartyError();
            }
        } else if (lc != CrowdfundLifecycle.Lost) {
            // Otherwise it must have lost.
            revert WrongLifecycleError(lc);
        }
        // Split recipient can burn even if they don't have a token.
        {
            address splitRecipient_ = splitRecipient;
            if (contributor == splitRecipient_) {
                if (_splitRecipientHasBurned) {
                    revert SplitRecipientAlreadyBurnedError();
                }
                _splitRecipientHasBurned = true;
            }
            // Revert if already burned or does not exist.
            if (splitRecipient_ != contributor || _doesTokenExistFor(contributor)) {
                CrowdfundNFT._burn(contributor);
            }
        }
        // Compute the contributions used and owed to the contributor, along
        // with the voting power they'll have in the governance stage.
        (uint256 ethUsed, uint256 ethOwed, uint256 votingPower) =
            _getFinalContribution(contributor);
        if (votingPower > 0) {
            // Get the address to delegate voting power to. If null, delegate to self.
            address delegate = delegationsByContributor[contributor];
            if (delegate == address(0)) {
                // Delegate can be unset for the split recipient if they never
                // contribute. Self-delegate if this occurs.
                delegate = contributor;
            }
            // Mint governance NFT for the contributor.
            try party_.mint(contributor, votingPower, delegate) returns (uint256) {
                // OK
            } catch {
                // Mint to the crowdfund itself to escrow for contributor to
                // come claim later on.
                uint256 tokenId = party_.mint(address(this), votingPower, delegate);
                claims[contributor].governanceTokenId = tokenId;
            }
        }
        // Refund any ETH owed back to the contributor.
        (bool s, ) = contributor.call{value: ethOwed}("");
        if (!s) {
            // If the transfer fails, the contributor can still come claim it
            // from the crowdfund.
            claims[contributor].refund = ethOwed;
        }
        emit Burned(contributor, ethUsed, ethOwed, votingPower);
    }

    function _getPartyFactory() internal view returns (IPartyFactory) {
        return IPartyFactory(_GLOBALS.getAddress(LibGlobals.GLOBAL_PARTY_FACTORY));
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import "../globals/IGlobals.sol";
import "../utils/LibRawResult.sol";
import "../utils/Proxy.sol";
import "../renderers/RendererStorage.sol";

import "./AuctionCrowdfund.sol";
import "./BuyCrowdfund.sol";
import "./CollectionBuyCrowdfund.sol";

/// @notice Factory used to deploys new proxified `Crowdfund` instances.
contract CrowdfundFactory {
    using LibRawResult for bytes;

    event BuyCrowdfundCreated(BuyCrowdfund crowdfund, BuyCrowdfund.BuyCrowdfundOptions opts);
    event AuctionCrowdfundCreated(AuctionCrowdfund crowdfund, AuctionCrowdfund.AuctionCrowdfundOptions opts);
    event CollectionBuyCrowdfundCreated(CollectionBuyCrowdfund crowdfund, CollectionBuyCrowdfund.CollectionBuyCrowdfundOptions opts);

    // The `Globals` contract storing global configuration values. This contract
    // is immutable and it’s address will never change.
    IGlobals private immutable _GLOBALS;

    // Set the `Globals` contract.
    constructor(IGlobals globals) {
        _GLOBALS = globals;
    }

    /// @notice Create a new crowdfund to purchase a specific NFT (i.e., with a
    ///         known token ID) listing for a known price.
    /// @param opts Options used to initialize the crowdfund. These are fixed
    ///             and cannot be changed later.
    /// @param createGateCallData Encoded calldata used by `createGate()` to
    ///                           create the crowdfund if one is specified in `opts`.
    function createBuyCrowdfund(
        BuyCrowdfund.BuyCrowdfundOptions memory opts,
        bytes memory createGateCallData
    )
        public
        payable
        returns (BuyCrowdfund inst)
    {
        opts.gateKeeperId = _prepareGate(
            opts.gateKeeper,
            opts.gateKeeperId,
            createGateCallData
        );
        inst = BuyCrowdfund(payable(new Proxy{ value: msg.value }(
            _GLOBALS.getImplementation(LibGlobals.GLOBAL_BUY_CF_IMPL),
            abi.encodeCall(BuyCrowdfund.initialize, (opts))
        )));
        emit BuyCrowdfundCreated(inst, opts);
    }

    /// @notice Create a new crowdfund to bid on an auction for a specific NFT
    ///         (i.e. with a known token ID).
    /// @param opts Options used to initialize the crowdfund. These are fixed
    ///             and cannot be changed later.
    /// @param createGateCallData Encoded calldata used by `createGate()` to create
    ///                           the crowdfund if one is specified in `opts`.
    function createAuctionCrowdfund(
        AuctionCrowdfund.AuctionCrowdfundOptions memory opts,
        bytes memory createGateCallData
    )
        public
        payable
        returns (AuctionCrowdfund inst)
    {
        opts.gateKeeperId = _prepareGate(
            opts.gateKeeper,
            opts.gateKeeperId,
            createGateCallData
        );
        inst = AuctionCrowdfund(payable(new Proxy{ value: msg.value }(
            _GLOBALS.getImplementation(LibGlobals.GLOBAL_AUCTION_CF_IMPL),
            abi.encodeCall(AuctionCrowdfund.initialize, (opts))
        )));
        emit AuctionCrowdfundCreated(inst, opts);
    }

    /// @notice Create a new crowdfund to purchase any NFT from a collection
    ///         (i.e. any token ID) from a collection for a known price.
    /// @param opts Options used to initialize the crowdfund. These are fixed
    ///             and cannot be changed later.
    /// @param createGateCallData Encoded calldata used by `createGate()` to create
    ///                           the crowdfund if one is specified in `opts`.
    function createCollectionBuyCrowdfund(
        CollectionBuyCrowdfund.CollectionBuyCrowdfundOptions memory opts,
        bytes memory createGateCallData
    )
        public
        payable
        returns (CollectionBuyCrowdfund inst)
    {
        opts.gateKeeperId = _prepareGate(
            opts.gateKeeper,
            opts.gateKeeperId,
            createGateCallData
        );
        inst = CollectionBuyCrowdfund(payable(new Proxy{ value: msg.value }(
            _GLOBALS.getImplementation(LibGlobals.GLOBAL_COLLECTION_BUY_CF_IMPL),
            abi.encodeCall(CollectionBuyCrowdfund.initialize, (opts))
        )));
        emit CollectionBuyCrowdfundCreated(inst, opts);
    }

    function _prepareGate(
        IGateKeeper gateKeeper,
        bytes12 gateKeeperId,
        bytes memory createGateCallData
    )
        private
        returns (bytes12 newGateKeeperId)
    {
        if (
            address(gateKeeper) == address(0) ||
            gateKeeperId != bytes12(0)
        ) {
            // Using an existing gate on the gatekeeper
            // or not using a gate at all.
            return gateKeeperId;
        }
        // Call the gate creation function on the gatekeeper.
        (bool s, bytes memory r) = address(gateKeeper).call(createGateCallData);
        if (!s) {
            r.rawRevert();
        }
        // Result is always a bytes12.
        return abi.decode(r, (bytes12));
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import "../tokens/IERC721.sol";
import "../utils/ReadOnlyDelegateCall.sol";
import "../utils/EIP165.sol";
import "../globals/IGlobals.sol";
import "../globals/LibGlobals.sol";
import "../renderers/RendererStorage.sol";

/// @notice NFT functionality for crowdfund types. This NFT is soulbound and read-only.
contract CrowdfundNFT is IERC721, EIP165, ReadOnlyDelegateCall {
    error AlreadyMintedError(address owner, uint256 tokenId);
    error AlreadyBurnedError(address owner, uint256 tokenId);
    error InvalidTokenError(uint256 tokenId);
    error InvalidAddressError();

    // The `Globals` contract storing global configuration values. This contract
    // is immutable and it’s address will never change.
    IGlobals private immutable _GLOBALS;

    /// @notice The name of the crowdfund. This will also carry over to the
    ///         governance party.
    string public name;
    /// @notice The token symbol for the crowdfund. This will also carry over to
    ///         the governance party.
    string public symbol;

    mapping (uint256 => address) private _owners;

    modifier alwaysRevert() {
        revert('ALWAYS FAILING');
        _; // Compiler requires this.
    }

    // Set the `Globals` contract.
    constructor(IGlobals globals) {
        _GLOBALS = globals;
    }

    // Initialize name and symbol for crowdfund.
    function _initialize(
        string memory name_,
        string memory symbol_,
        uint256 customizationPresetId
    )
        internal
        virtual
    {
        name = name_;
        symbol = symbol_;
        if (customizationPresetId != 0) {
            RendererStorage(_GLOBALS.getAddress(LibGlobals.GLOBAL_RENDERER_STORAGE))
                .useCustomizationPreset(customizationPresetId);
        }
    }

    /// @notice DO NOT CALL. This is a soulbound NFT and cannot be transferred.
    ///         Attempting to call this function will always fail.
    function transferFrom(address, address, uint256)
        external
        pure
        alwaysRevert
    {}

    /// @notice DO NOT CALL. This is a soulbound NFT and cannot be transferred.
    ///         Attempting to call this function will always fail.
    function safeTransferFrom(address, address, uint256)
        external
        pure
        alwaysRevert
    {}

    /// @notice DO NOT CALL. This is a soulbound NFT and cannot be transferred.
    ///         Attempting to call this function will always fail.
    function safeTransferFrom(address, address, uint256, bytes calldata)
        external
        pure
        alwaysRevert
    {}

    /// @notice DO NOT CALL. This is a soulbound NFT and cannot be transferred.
    ///         Attempting to call this function will always fail.
    function approve(address, uint256)
        external
        pure
        alwaysRevert
    {}

    /// @notice DO NOT CALL. This is a soulbound NFT and cannot be transferred.
    ///         Attempting to call this function will always fail.
    function setApprovalForAll(address, bool)
        external
        pure
        alwaysRevert
    {}

    /// @notice This is a soulbound NFT and cannot be transferred.
    ///         Attempting to call this function will always return null.
    function getApproved(uint256)
        external
        pure
        returns (address)
    {
        return address(0);
    }

    /// @notice This is a soulbound NFT and cannot be transferred.
    ///         Attempting to call this function will always return false.
    function isApprovedForAll(address, address)
        external
        pure
        returns (bool)
    {
        return false;
    }

    /// @inheritdoc EIP165
    function supportsInterface(bytes4 interfaceId)
        public
        virtual
        override
        pure
        returns (bool)
    {
        return super.supportsInterface(interfaceId) ||
            interfaceId == type(IERC721).interfaceId;
    }

    /// @notice Returns a URI to render the NFT.
    function tokenURI(uint256) external view returns (string memory) {
        return _delegateToRenderer();
    }

    /// @notice Returns a URI for the storefront-level metadata for your contract.
    function contractURI() external view returns (string memory) {
        return _delegateToRenderer();
    }

    /// @inheritdoc IERC721
    function ownerOf(uint256 tokenId) external view returns (address owner) {
        owner = _owners[tokenId];
        if (owner == address(0)) {
            revert InvalidTokenError(tokenId);
        }
    }

    /// @inheritdoc IERC721
    function balanceOf(address owner) external view returns (uint256 numTokens) {
        return _doesTokenExistFor(owner) ? 1 : 0;
    }

    function _doesTokenExistFor(address owner) internal view returns (bool) {
        return _owners[uint256(uint160(owner))] != address(0);
    }

    function _mint(address owner) internal returns (uint256 tokenId) {
        if (owner == address(0)) revert InvalidAddressError();
        tokenId = uint256(uint160(owner));
        if (_owners[tokenId] != owner) {
            _owners[tokenId] = owner;
            emit Transfer(address(0), owner, tokenId);
        } else {
            revert AlreadyMintedError(owner, tokenId);
        }
    }

    function _burn(address owner) internal {
        uint256 tokenId = uint256(uint160(owner));
        if (_owners[tokenId] == owner) {
            _owners[tokenId] = address(0);
            emit Transfer(owner, address(0), tokenId);
            return;
        }
        revert AlreadyBurnedError(owner, tokenId);
    }

    function _delegateToRenderer() private view returns (string memory) {
        _readOnlyDelegateCall(
            // Instance of IERC721Renderer.
            _GLOBALS.getAddress(LibGlobals.GLOBAL_CF_NFT_RENDER_IMPL),
            msg.data
        );
        assert(false); // Will not be reached.
        return "";
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import "../tokens/IERC20.sol";

import "./ITokenDistributorParty.sol";

/// @notice Creates token distributions for parties.
interface ITokenDistributor {
    enum TokenType {
        Native,
        Erc20
    }

    // Info on a distribution, created by createDistribution().
    struct DistributionInfo {
        // Type of distribution/token.
        TokenType tokenType;
        // ID of the distribution. Assigned by createDistribution().
        uint256 distributionId;
        // The party whose members can claim the distribution.
        ITokenDistributorParty party;
        // Who can claim `fee`.
        address payable feeRecipient;
        // The token being distributed.
        address token;
        // Total amount of `token` that can be claimed by party members.
        uint128 memberSupply;
        // Amount of `token` to be redeemed by `feeRecipient`.
        uint128 fee;
    }

    event DistributionCreated(
        ITokenDistributorParty indexed party,
        DistributionInfo info
    );
    event DistributionFeeClaimed(
        ITokenDistributorParty indexed party,
        address indexed feeRecipient,
        TokenType tokenType,
        address token,
        uint256 amount
    );
    event DistributionClaimedByPartyToken(
        ITokenDistributorParty indexed party,
        uint256 indexed partyTokenId,
        address indexed owner,
        TokenType tokenType,
        address token,
        uint256 amountClaimed
    );

    /// @notice Create a new distribution for an outstanding native token balance
    ///         governed by a party.
    /// @dev Native tokens should be transferred directly into this contract
    ///      immediately prior (same tx) to calling `createDistribution()` or
    ///      attached to the call itself.
    /// @param party The party whose members can claim the distribution.
    /// @param feeRecipient Who can claim `fee`.
    /// @param feeBps Percentage (in bps) of the distribution `feeRecipient` receives.
    /// @return info Information on the created distribution.
    function createNativeDistribution(
        ITokenDistributorParty party,
        address payable feeRecipient,
        uint16 feeBps
    )
        external
        payable
        returns (DistributionInfo memory info);

    /// @notice Create a new distribution for an outstanding ERC20 token balance
    ///         governed by a party.
    /// @dev ERC20 tokens should be transferred directly into this contract
    ///      immediately prior (same tx) to calling `createDistribution()` or
    ///      attached to the call itself.
    /// @param token The ERC20 token to distribute.
    /// @param party The party whose members can claim the distribution.
    /// @param feeRecipient Who can claim `fee`.
    /// @param feeBps Percentage (in bps) of the distribution `feeRecipient` receives.
    /// @return info Information on the created distribution.
    function createErc20Distribution(
        IERC20 token,
        ITokenDistributorParty party,
        address payable feeRecipient,
        uint16 feeBps
    )
        external
        returns (DistributionInfo memory info);

    /// @notice Claim a portion of a distribution owed to a `partyTokenId` belonging
    ///         to the party that created the distribution. The caller
    ///         must own this token.
    /// @param info Information on the distribution being claimed.
    /// @param partyTokenId The ID of the party token to claim for.
    /// @return amountClaimed The amount of the distribution claimed.
    function claim(DistributionInfo calldata info, uint256 partyTokenId)
        external
        returns (uint128 amountClaimed);

    /// @notice Claim the fee for a distribution. Only a distribution's `feeRecipient`
    ///         can call this.
    /// @param info Information on the distribution being claimed.
    /// @param recipient The address to send the fee to.
    function claimFee(DistributionInfo calldata info, address payable recipient)
        external;

    /// @notice Batch version of `claim()`.
    /// @param infos Information on the distributions being claimed.
    /// @param partyTokenIds The ID of the party tokens to claim for.
    /// @return amountsClaimed The amount of the distributions claimed.
    function batchClaim(DistributionInfo[] calldata infos, uint256[] calldata partyTokenIds)
        external
        returns (uint128[] memory amountsClaimed);

    /// @notice Batch version of `claimFee()`.
    /// @param infos Information on the distributions to claim fees for.
    /// @param recipients The addresses to send the fees to.
    function batchClaimFee(DistributionInfo[] calldata infos, address payable[] calldata recipients)
        external;

    /// @notice Compute the amount of a distribution's token are owed to a party
    ///         member, identified by the `partyTokenId`.
    /// @param party The party to use for computing the claim amount.
    /// @param memberSupply Total amount of tokens that can be claimed in the distribution.
    /// @param partyTokenId The ID of the party token to claim for.
    /// @return claimAmount The amount of the distribution owed to the party member.
    function getClaimAmount(
        ITokenDistributorParty party,
        uint256 memberSupply,
        uint256 partyTokenId
    )
        external
        view
        returns (uint128);

    /// @notice Check whether the fee has been claimed for a distribution.
    /// @param party The party to use for checking whether the fee has been claimed.
    /// @param distributionId The ID of the distribution to check.
    /// @return feeClaimed Whether the fee has been claimed.
    function wasFeeClaimed(ITokenDistributorParty party, uint256 distributionId)
        external
        view
        returns (bool);

    /// @notice Check whether a `partyTokenId` has claimed their share of a distribution.
    /// @param party The party to use for checking whether the `partyTokenId` has claimed.
    /// @param partyTokenId The ID of the party token to check.
    /// @param distributionId The ID of the distribution to check.
    /// @return hasClaimed Whether the `partyTokenId` has claimed.
    function hasPartyTokenIdClaimed(
        ITokenDistributorParty party,
        uint256 partyTokenId,
        uint256 distributionId
    )
        external
        view returns (bool);

    /// @notice Get how much unclaimed member tokens are left in a distribution.
    /// @param party The party to use for checking the unclaimed member tokens.
    /// @param distributionId The ID of the distribution to check.
    /// @return remainingMemberSupply The amount of distribution supply remaining.
    function getRemainingMemberSupply(
        ITokenDistributorParty party,
        uint256 distributionId
    )
        external
        view
        returns (uint128);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

// Interface the caller of `ITokenDistributor.createDistribution()` must implement.
interface ITokenDistributorParty {
    /// @notice Return the owner of a token.
    /// @param tokenId The token ID to query.
    /// @return owner The owner of `tokenId`.
    function ownerOf(uint256 tokenId) external view returns (address);
    /// @notice Return the distribution share of a token. Denominated fractions
    ///         of 1e18. I.e., 1e18 = 100%.
    /// @param tokenId The token ID to query.
    /// @return share The distribution percentage of `tokenId`.
    function getDistributionShareOf(uint256 tokenId) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

// Interface for a gatekeeper contract used for private crowdfund instances.
interface IGateKeeper {
    /// @notice Check if a participant is eligible to participate in a crowdfund.
    /// @param participant The address of the participant.
    /// @param id The ID of the gate to eligibility against.
    /// @param userData The data used to check eligibility.
    /// @return `true` if the participant is allowed to participate, `false` otherwise.
    function isAllowed(
        address participant,
        bytes12 id,
        bytes memory userData
    ) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import "../utils/Implementation.sol";

// Single registry of global values controlled by multisig.
// See `LibGlobals` for all valid keys.
interface IGlobals {
    function getBytes32(uint256 key) external view returns (bytes32);
    function getUint256(uint256 key) external view returns (uint256);
    function getBool(uint256 key) external view returns (bool);
    function getAddress(uint256 key) external view returns (address);
    function getImplementation(uint256 key) external view returns (Implementation);
    function getIncludesBytes32(uint256 key, bytes32 value) external view returns (bool);
    function getIncludesUint256(uint256 key, uint256 value) external view returns (bool);
    function getIncludesAddress(uint256 key, address value) external view returns (bool);

    function setBytes32(uint256 key, bytes32 value) external;
    function setUint256(uint256 key, uint256 value) external;
    function setBool(uint256 key, bool value) external;
    function setAddress(uint256 key, address value) external;
    function setIncludesBytes32(uint256 key, bytes32 value, bool isIncluded) external;
    function setIncludesUint256(uint256 key, uint256 value, bool isIncluded) external;
    function setIncludesAddress(uint256 key, address value, bool isIncluded) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

// Valid keys in `IGlobals`. Append-only.
library LibGlobals {
    uint256 internal constant GLOBAL_PARTY_IMPL                     = 1;
    uint256 internal constant GLOBAL_PROPOSAL_ENGINE_IMPL           = 2;
    uint256 internal constant GLOBAL_PARTY_FACTORY                  = 3;
    uint256 internal constant GLOBAL_GOVERNANCE_NFT_RENDER_IMPL     = 4;
    uint256 internal constant GLOBAL_CF_NFT_RENDER_IMPL             = 5;
    uint256 internal constant GLOBAL_OS_ZORA_AUCTION_TIMEOUT        = 6;
    uint256 internal constant GLOBAL_OS_ZORA_AUCTION_DURATION       = 7;
    uint256 internal constant GLOBAL_AUCTION_CF_IMPL                = 8;
    uint256 internal constant GLOBAL_BUY_CF_IMPL                    = 9;
    uint256 internal constant GLOBAL_COLLECTION_BUY_CF_IMPL         = 10;
    uint256 internal constant GLOBAL_DAO_WALLET                     = 11;
    uint256 internal constant GLOBAL_TOKEN_DISTRIBUTOR              = 12;
    uint256 internal constant GLOBAL_OPENSEA_CONDUIT_KEY            = 13;
    uint256 internal constant GLOBAL_OPENSEA_ZONE                   = 14;
    uint256 internal constant GLOBAL_PROPOSAL_MAX_CANCEL_DURATION   = 15;
    uint256 internal constant GLOBAL_ZORA_MIN_AUCTION_DURATION      = 16;
    uint256 internal constant GLOBAL_ZORA_MAX_AUCTION_DURATION      = 17;
    uint256 internal constant GLOBAL_ZORA_MAX_AUCTION_TIMEOUT       = 18;
    uint256 internal constant GLOBAL_OS_MIN_ORDER_DURATION          = 19;
    uint256 internal constant GLOBAL_OS_MAX_ORDER_DURATION          = 20;
    uint256 internal constant GLOBAL_DISABLE_PARTY_ACTIONS          = 21;
    uint256 internal constant GLOBAL_RENDERER_STORAGE               = 22;
    uint256 internal constant GLOBAL_PROPOSAL_MIN_CANCEL_DURATION   = 23;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.17;

/**
 * @title IMarketWrapper
 * @author Anna Carroll
 * @notice IMarketWrapper provides a common interface for
 * interacting with NFT auction markets.
 * Contracts can abstract their interactions with
 * different NFT markets using IMarketWrapper.
 * NFT markets can become compatible with any contract
 * using IMarketWrapper by deploying a MarketWrapper contract
 * that implements this interface using the logic of their Market.
 *
 * WARNING: MarketWrapper contracts should NEVER write to storage!
 * When implementing a MarketWrapper, exercise caution; a poorly implemented
 * MarketWrapper contract could permanently lose access to the NFT or user funds.
 */
interface IMarketWrapper {
    /**
     * @notice Given the auctionId, nftContract, and tokenId, check that:
     * 1. the auction ID matches the token
     * referred to by tokenId + nftContract
     * 2. the auctionId refers to an *ACTIVE* auction
     * (e.g. an auction that will accept bids)
     * within this market contract
     * 3. any additional validation to ensure that
     * a PartyBid can bid on this auction
     * (ex: if the market allows arbitrary bidding currencies,
     * check that the auction currency is ETH)
     * Note: This function probably should have been named "isValidAuction"
     * @dev Called in PartyBid.sol in `initialize` at line 174
     * @return TRUE if the auction is valid
     */
    function auctionIdMatchesToken(
        uint256 auctionId,
        address nftContract,
        uint256 tokenId
    ) external view returns (bool);

    /**
     * @notice Calculate the minimum next bid for this auction.
     * PartyBid contracts always submit the minimum possible
     * bid that will be accepted by the Market contract.
     * usually, this is either the reserve price (if there are no bids)
     * or a certain percentage increase above the current highest bid
     * @dev Called in PartyBid.sol in `bid` at line 251
     * @return minimum bid amount
     */
    function getMinimumBid(uint256 auctionId) external view returns (uint256);

    /**
     * @notice Query the current highest bidder for this auction
     * It is assumed that there is always 1 winning highest bidder for an auction
     * This is used to ensure that PartyBid cannot outbid itself if it is already winning
     * @dev Called in PartyBid.sol in `bid` at line 241
     * @return highest bidder
     */
    function getCurrentHighestBidder(uint256 auctionId)
        external
        view
        returns (address);

    /**
     * @notice Submit bid to Market contract
     * @dev Called in PartyBid.sol in `bid` at line 259
     */
    function bid(uint256 auctionId, uint256 bidAmount) external;

    /**
     * @notice Determine whether the auction has been finalized
     * Used to check if it is still possible to bid
     * And to determine whether the PartyBid should finalize the auction
     * @dev Called in PartyBid.sol in `bid` at line 247
     * @dev and in `finalize` at line 288
     * @return TRUE if the auction has been finalized
     */
    function isFinalized(uint256 auctionId) external view returns (bool);

    /**
     * @notice Finalize the results of the auction
     * on the Market contract
     * It is assumed  that this operation is performed once for each auction,
     * that after it is done the auction is over and the NFT has been
     * transferred to the auction winner.
     * @dev Called in PartyBid.sol in `finalize` at line 289
     */
    function finalize(uint256 auctionId) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import "../globals/IGlobals.sol";
import "../tokens/IERC721.sol";

import "./Party.sol";

// Creates generic Party instances.
interface IPartyFactory {
    event PartyCreated(
        Party indexed party,
        Party.PartyOptions opts,
        IERC721[] preciousTokens,
        uint256[] preciousTokenIds,
        address creator
    );

    /// @notice Deploy a new party instance. Afterwards, governance NFTs can be minted
    ///         for party members using the `mint()` function from the newly
    ///         created party.
    /// @param authority The address that can call `mint()`.
    /// @param opts Options used to initialize the party. These are fixed
    ///             and cannot be changed later.
    /// @param preciousTokens The tokens that are considered precious by the
    ///                       party.These are protected assets and are subject
    ///                       to extra restrictions in proposals vs other
    ///                       assets.
    /// @param preciousTokenIds The IDs associated with each token in `preciousTokens`.
    /// @return party The newly created `Party` instance.
    function createParty(
        address authority,
        Party.PartyOptions calldata opts,
        IERC721[] memory preciousTokens,
        uint256[] memory preciousTokenIds
    )
        external
        returns (Party party);

    /// @notice The `Globals` contract storing global configuration values. This contract
    ///         is immutable and it’s address will never change.
    function GLOBALS() external view returns (IGlobals);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import "../tokens/IERC721.sol";

import "./PartyGovernanceNFT.sol";
import "./PartyGovernance.sol";

/// @notice The governance contract that also custodies the precious NFTs. This
///         is also the Governance NFT 721 contract.
contract Party is PartyGovernanceNFT {
    // Arguments used to initialize the party.
    struct PartyOptions {
        PartyGovernance.GovernanceOpts governance;
        string name;
        string symbol;
        uint256 customizationPresetId;
    }

    // Arguments used to initialize the `PartyGovernanceNFT`.
    struct PartyInitData {
        PartyOptions options;
        IERC721[] preciousTokens;
        uint256[] preciousTokenIds;
        address mintAuthority;
    }

    // Set the `Globals` contract.
    constructor(IGlobals globals) PartyGovernanceNFT(globals) {}

    /// @notice Initializer to be delegatecalled by `Proxy` constructor. Will
    ///         revert if called outside the constructor.
    /// @param initData Options used to initialize the party governance.
    function initialize(PartyInitData memory initData)
        external
        onlyConstructor
    {
        PartyGovernanceNFT._initialize(
            initData.options.name,
            initData.options.symbol,
            initData.options.customizationPresetId,
            initData.options.governance,
            initData.preciousTokens,
            initData.preciousTokenIds,
            initData.mintAuthority
        );
    }

    receive() external payable {}
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import "../distribution/ITokenDistributorParty.sol";
import "../distribution/ITokenDistributor.sol";
import "../utils/ReadOnlyDelegateCall.sol";
import "../tokens/IERC721.sol";
import "../tokens/IERC20.sol";
import "../tokens/IERC1155.sol";
import "../tokens/ERC721Receiver.sol";
import "../tokens/ERC1155Receiver.sol";
import "../utils/LibERC20Compat.sol";
import "../utils/LibRawResult.sol";
import "../utils/LibSafeCast.sol";
import "../globals/IGlobals.sol";
import "../globals/LibGlobals.sol";
import "../proposals/IProposalExecutionEngine.sol";
import "../proposals/LibProposal.sol";
import "../proposals/ProposalStorage.sol";

import "./IPartyFactory.sol";

/// @notice Base contract for a Party encapsulating all governance functionality.
abstract contract PartyGovernance is
    ITokenDistributorParty,
    ERC721Receiver,
    ERC1155Receiver,
    ProposalStorage,
    Implementation,
    ReadOnlyDelegateCall
{
    using LibERC20Compat for IERC20;
    using LibRawResult for bytes;
    using LibSafeCast for uint256;
    using LibSafeCast for int192;
    using LibSafeCast for uint96;

    // States a proposal can be in.
    enum ProposalStatus {
        // The proposal does not exist.
        Invalid,
        // The proposal has been proposed (via `propose()`), has not been vetoed
        // by a party host, and is within the voting window. Members can vote on
        // the proposal and party hosts can veto the proposal.
        Voting,
        // The proposal has either exceeded its voting window without reaching
        // `passThresholdBps` of votes or was vetoed by a party host.
        Defeated,
        // The proposal reached at least `passThresholdBps` of votes but is still
        // waiting for `executionDelay` to pass before it can be executed. Members
        // can continue to vote on the proposal and party hosts can veto at this time.
        Passed,
        // Same as `Passed` but now `executionDelay` has been satisfied. Any member
        // may execute the proposal via `execute()`, unless `maxExecutableTime`
        // has arrived.
        Ready,
        // The proposal has been executed at least once but has further steps to
        // complete so it needs to be executed again. No other proposals may be
        // executed while a proposal is in the `InProgress` state. No voting or
        // vetoing of the proposal is allowed, however it may be forcibly cancelled
        // via `cancel()` if the `cancelDelay` has passed since being first executed.
        InProgress,
        // The proposal was executed and completed all its steps. No voting or
        // vetoing can occur and it cannot be cancelled nor executed again.
        Complete,
        // The proposal was executed at least once but did not complete before
        // `cancelDelay` seconds passed since the first execute and was forcibly cancelled.
        Cancelled
    }

    struct GovernanceOpts {
        // Address of initial party hosts.
        address[] hosts;
        // How long people can vote on a proposal.
        uint40 voteDuration;
        // How long to wait after a proposal passes before it can be
        // executed.
        uint40 executionDelay;
        // Minimum ratio of accept votes to consider a proposal passed,
        // in bps, where 10,000 == 100%.
        uint16 passThresholdBps;
        // Total voting power of governance NFTs.
        uint96 totalVotingPower;
        // Fee bps for distributions.
        uint16 feeBps;
        // Fee recipeint for distributions.
        address payable feeRecipient;
    }

    // Subset of `GovernanceOpts` that are commonly read together for
    // efficiency.
    struct GovernanceValues {
        uint40 voteDuration;
        uint40 executionDelay;
        uint16 passThresholdBps;
        uint96 totalVotingPower;
    }

    // A snapshot of voting power for a member.
    struct VotingPowerSnapshot {
        // The timestamp when the snapshot was taken.
        uint40 timestamp;
        // Voting power that was delegated to this user by others.
        uint96 delegatedVotingPower;
        // The intrinsic (not delegated from someone else) voting power of this user.
        uint96 intrinsicVotingPower;
        // Whether the user was delegated to another at this snapshot.
        bool isDelegated;
    }

    // Proposal details chosen by proposer.
    struct Proposal {
        // Time beyond which the proposal can no longer be executed.
        // If the proposal has already been executed, and is still InProgress,
        // this value is ignored.
        uint40 maxExecutableTime;
        // The minimum seconds this proposal can remain in the InProgress status
        // before it can be cancelled.
        uint40 cancelDelay;
        // Encoded proposal data. The first 4 bytes are the proposal type, followed
        // by encoded proposal args specific to the proposal type. See
        // ProposalExecutionEngine for details.
        bytes proposalData;
    }

    // Accounting and state tracking values for a proposal.
    // Fits in a word.
    struct ProposalStateValues {
        // When the proposal was proposed.
        uint40 proposedTime;
        // When the proposal passed the vote.
        uint40 passedTime;
        // When the proposal was first executed.
        uint40 executedTime;
        // When the proposal completed.
        uint40 completedTime;
        // Number of accept votes.
        uint96 votes; // -1 == vetoed
    }

    // Storage states for a proposal.
    struct ProposalState {
        // Accounting and state tracking values.
        ProposalStateValues values;
        // Hash of the proposal.
        bytes32 hash;
        // Whether a member has voted for (accepted) this proposal already.
        mapping (address => bool) hasVoted;
    }

    event Proposed(
        uint256 proposalId,
        address proposer,
        Proposal proposal
    );
    event ProposalAccepted(
        uint256 proposalId,
        address voter,
        uint256 weight
    );
    event EmergencyExecute(address target, bytes data, uint256 amountEth);

    event ProposalPassed(uint256 indexed proposalId);
    event ProposalVetoed(uint256 indexed proposalId, address host);
    event ProposalExecuted(uint256 indexed proposalId, address executor, bytes nextProgressData);
    event ProposalCancelled(uint256 indexed proposalId);
    event DistributionCreated(ITokenDistributor.TokenType tokenType, address token, uint256 tokenId);
    event VotingPowerDelegated(address indexed owner, address indexed delegate);
    event HostStatusTransferred(address oldHost, address newHost);
    event EmergencyExecuteDisabled();

    error MismatchedPreciousListLengths();
    error BadProposalStatusError(ProposalStatus status);
    error BadProposalHashError(bytes32 proposalHash, bytes32 actualHash);
    error ExecutionTimeExceededError(uint40 maxExecutableTime, uint40 timestamp);
    error OnlyPartyHostError();
    error OnlyActiveMemberError();
    error InvalidDelegateError();
    error BadPreciousListError();
    error OnlyPartyDaoError(address notDao, address partyDao);
    error OnlyPartyDaoOrHostError(address notDao, address partyDao);
    error OnlyWhenEmergencyActionsAllowedError();
    error OnlyWhenEnabledError();
    error AlreadyVotedError(address voter);
    error InvalidNewHostError();
    error ProposalCannotBeCancelledYetError(uint40 currentTime, uint40 cancelTime);
    error InvalidBpsError(uint16 bps);

    uint256 constant private UINT40_HIGH_BIT = 1 << 39;
    uint96 constant private VETO_VALUE = type(uint96).max;

    // The `Globals` contract storing global configuration values. This contract
    // is immutable and it’s address will never change.
    IGlobals private immutable _GLOBALS;

    /// @notice Whether the DAO has emergency powers for this party.
    bool public emergencyExecuteDisabled;
    /// @notice Distribution fee bps.
    uint16 public feeBps;
    /// @notice Distribution fee recipient.
    address payable public feeRecipient;
    /// @notice The hash of the list of precious NFTs guarded by the party.
    bytes32 public preciousListHash;
    /// @notice The last proposal ID that was used. 0 means no proposals have been made.
    uint256 public lastProposalId;
    /// @notice Whether an address is a party host.
    mapping(address => bool) public isHost;
    /// @notice The last person a voter delegated its voting power to.
    mapping(address => address) public delegationsByVoter;
    // Constant governance parameters, fixed from the inception of this party.
    GovernanceValues internal _governanceValues;
    // ProposalState by proposal ID.
    mapping(uint256 => ProposalState) private _proposalStateByProposalId;
    // Snapshots of voting power per user, each sorted by increasing time.
    mapping(address => VotingPowerSnapshot[]) private _votingPowerSnapshotsByVoter;

    modifier onlyHost() {
        if (!isHost[msg.sender]) {
            revert OnlyPartyHostError();
        }
        _;
    }

    // Caller must have voting power at the current time.
    modifier onlyActiveMember() {
        {
            VotingPowerSnapshot memory snap =
                _getLastVotingPowerSnapshotForVoter(msg.sender);
            // Must have either delegated voting power or intrinsic voting power.
            if (snap.intrinsicVotingPower == 0 && snap.delegatedVotingPower == 0) {
                revert OnlyActiveMemberError();
            }
        }
        _;
    }

    // Caller must have voting power at the current time or be the `Party` instance.
    modifier onlyActiveMemberOrSelf() {
        // Ignore if the party is calling functions on itself, like with
        // `FractionalizeProposal` calling `distribute()`.
        if (msg.sender != address(this)) {
            VotingPowerSnapshot memory snap =
                _getLastVotingPowerSnapshotForVoter(msg.sender);
            // Must have either delegated voting power or intrinsic voting power.
            if (snap.intrinsicVotingPower == 0 && snap.delegatedVotingPower == 0) {
                revert OnlyActiveMemberError();
            }
        }
        _;
    }

    // Only the party DAO multisig can call.
    modifier onlyPartyDao() {
        {
            address partyDao = _GLOBALS.getAddress(LibGlobals.GLOBAL_DAO_WALLET);
            if (msg.sender != partyDao) {
                revert OnlyPartyDaoError(msg.sender, partyDao);
            }
        }
        _;
    }

    // Only the party DAO multisig or a party host can call.
    modifier onlyPartyDaoOrHost() {
        address partyDao = _GLOBALS.getAddress(LibGlobals.GLOBAL_DAO_WALLET);
        if (msg.sender != partyDao && !isHost[msg.sender]) {
            revert OnlyPartyDaoOrHostError(msg.sender, partyDao);
        }
        _;
    }

    // Only if `emergencyExecuteDisabled` is not true.
    modifier onlyWhenEmergencyExecuteAllowed() {
        if (emergencyExecuteDisabled) {
            revert OnlyWhenEmergencyActionsAllowedError();
        }
        _;
    }

    modifier onlyWhenNotGloballyDisabled() {
        if (_GLOBALS.getBool(LibGlobals.GLOBAL_DISABLE_PARTY_ACTIONS)) {
            revert OnlyWhenEnabledError();
        }
        _;
    }

    // Set the `Globals` contract.
    constructor(IGlobals globals) {
        _GLOBALS = globals;
    }

    // Initialize storage for proxy contracts and initialize the proposal execution engine.
    function _initialize(
        GovernanceOpts memory opts,
        IERC721[] memory preciousTokens,
        uint256[] memory preciousTokenIds
    )
        internal
        virtual
    {
        // Check BPS are valid.
        if (opts.feeBps > 1e4) {
            revert InvalidBpsError(opts.feeBps);
        }
        if (opts.passThresholdBps > 1e4) {
            revert InvalidBpsError(opts.passThresholdBps);
        }
        // Initialize the proposal execution engine.
        _initProposalImpl(
            IProposalExecutionEngine(
                _GLOBALS.getAddress(LibGlobals.GLOBAL_PROPOSAL_ENGINE_IMPL)
            ),
            ""
        );
        // Set the governance parameters.
        _governanceValues = GovernanceValues({
            voteDuration: opts.voteDuration,
            executionDelay: opts.executionDelay,
            passThresholdBps: opts.passThresholdBps,
            totalVotingPower: opts.totalVotingPower
        });
        // Set fees.
        feeBps = opts.feeBps;
        feeRecipient = opts.feeRecipient;
        // Set the precious list.
        _setPreciousList(preciousTokens, preciousTokenIds);
        // Set the party hosts.
        for (uint256 i=0; i < opts.hosts.length; ++i) {
            isHost[opts.hosts[i]] = true;
        }
    }

    /// @dev Forward all unknown read-only calls to the proposal execution engine.
    ///      Initial use case is to facilitate eip-1271 signatures.
    fallback() external {
        _readOnlyDelegateCall(
            address(_getProposalExecutionEngine()),
            msg.data
        );
    }

    /// @inheritdoc EIP165
    /// @dev Combined logic for `ERC721Receiver` and `ERC1155Receiver`.
    function supportsInterface(bytes4 interfaceId)
        public
        override(ERC721Receiver, ERC1155Receiver)
        virtual
        pure
        returns (bool)
    {
        return ERC721Receiver.supportsInterface(interfaceId) ||
            ERC1155Receiver.supportsInterface(interfaceId);
    }

    /// @notice Get the current `ProposalExecutionEngine` instance.
    function getProposalExecutionEngine()
        external
        view
        returns (IProposalExecutionEngine)
    {
        return _getProposalExecutionEngine();
    }

    /// @notice Get the total voting power of `voter` at a `timestamp`.
    /// @param voter The address of the voter.
    /// @param timestamp The timestamp to get the voting power at.
    /// @return votingPower The total voting power of `voter` at `timestamp`.
    function getVotingPowerAt(address voter, uint40 timestamp)
        external
        view
        returns (uint96 votingPower)
    {
        return getVotingPowerAt(voter, timestamp, type(uint256).max);
    }

    /// @notice Get the total voting power of `voter` at a snapshot `snapIndex`, with checks to
    ///         make sure it is the latest voting snapshot =< `timestamp`.
    /// @param voter The address of the voter.
    /// @param timestamp The timestamp to get the voting power at.
    /// @param snapIndex The index of the snapshot to get the voting power at.
    /// @return votingPower The total voting power of `voter` at `timestamp`.
    function getVotingPowerAt(address voter, uint40 timestamp, uint256 snapIndex)
        public
        view
        returns (uint96 votingPower)
    {
        VotingPowerSnapshot memory snap = _getVotingPowerSnapshotAt(voter, timestamp, snapIndex);
        return (snap.isDelegated ? 0 : snap.intrinsicVotingPower) + snap.delegatedVotingPower;
    }

    /// @notice Get the state of a proposal.
    /// @param proposalId The ID of the proposal.
    /// @return status The status of the proposal.
    /// @return values The state of the proposal.
    function getProposalStateInfo(uint256 proposalId)
        external
        view
        returns (ProposalStatus status, ProposalStateValues memory values)
    {
        values = _proposalStateByProposalId[proposalId].values;
        status = _getProposalStatus(values);
    }

    /// @notice Retrieve fixed governance parameters.
    /// @return gv The governance parameters of this party.
    function getGovernanceValues() external view returns (GovernanceValues memory gv) {
        return _governanceValues;
    }

    /// @notice Get the hash of a proposal.
    /// @dev Proposal details are not stored on-chain so the hash is used to enforce
    ///      consistency between calls.
    /// @param proposal The proposal to hash.
    /// @return proposalHash The hash of the proposal.
    function getProposalHash(Proposal memory proposal)
        public
        pure
        returns (bytes32 proposalHash)
    {
        // Hash the proposal in-place. Equivalent to:
        // keccak256(abi.encode(
        //   proposal.maxExecutableTime,
        //   proposal.cancelDelay,
        //   keccak256(proposal.proposalData)
        // ))
        bytes32 dataHash = keccak256(proposal.proposalData);
        assembly {
            // Overwrite the data field with the hash of its contents and then
            // hash the struct.
            let dataPos := add(proposal, 0x40)
            let t := mload(dataPos)
            mstore(dataPos, dataHash)
            proposalHash := keccak256(proposal, 0x60)
            // Restore the data field.
            mstore(dataPos, t)
        }
    }

    /// @notice Get the index of the most recent voting power snapshot <= `timestamp`.
    /// @param voter The address of the voter.
    /// @param timestamp The timestamp to get the snapshot index at.
    /// @return index The index of the snapshot.
    function findVotingPowerSnapshotIndex(address voter, uint40 timestamp)
        public
        view
        returns (uint256 index)
    {
        VotingPowerSnapshot[] storage snaps = _votingPowerSnapshotsByVoter[voter];

        // Derived from Open Zeppelin binary search
        // ref: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Checkpoints.sol#L39
        uint256 high = snaps.length;
        uint256 low = 0;
        while (low < high) {
            uint256 mid = (low + high) / 2;
            if (snaps[mid].timestamp > timestamp) {
                // Entry is too recent.
                high = mid;
            } else {
                // Entry is older. This is our best guess for now.
                low = mid + 1;
            }
        }

        // Return `type(uint256).max` if no valid voting snapshots found.
        return high == 0 ? type(uint256).max : high - 1;
    }

    /// @notice Pledge your intrinsic voting power to a new delegate, removing it from
    ///         the old one (if any).
    /// @param delegate The address to delegating voting power to.
    function delegateVotingPower(address delegate) external onlyDelegateCall {
        _adjustVotingPower(msg.sender, 0, delegate);
        emit VotingPowerDelegated(msg.sender, delegate);
    }

    /// @notice Transfer party host status to another.
    /// @param newPartyHost The address of the new host.
    function abdicate(address newPartyHost) external onlyHost onlyDelegateCall {
        // 0 is a special case burn address.
        if (newPartyHost != address(0)) {
            // Cannot transfer host status to an existing host.
            if(isHost[newPartyHost]) {
                revert InvalidNewHostError();
            }
            isHost[newPartyHost] = true;
        }
        isHost[msg.sender] = false;
        emit HostStatusTransferred(msg.sender, newPartyHost);
    }

    /// @notice Create a token distribution by moving the party's entire balance
    ///         to the `TokenDistributor` contract and immediately creating a
    ///         distribution governed by this party.
    /// @dev The `feeBps` and `feeRecipient` this party was created with will be
    ///      propagated to the distribution. Party members are entitled to a
    ///      share of the distribution's tokens proportionate to their relative
    ///      voting power in this party (less the fee).
    /// @dev Allow this to be called by the party itself for `FractionalizeProposal`.
    /// @param tokenType The type of token to distribute.
    /// @param token The address of the token to distribute.
    /// @param tokenId The ID of the token to distribute. Currently unused but
    ///                may be used in the future to support other distribution types.
    /// @return distInfo The information about the created distribution.
    function distribute(
        ITokenDistributor.TokenType tokenType,
        address token,
        uint256 tokenId
    )
        external
        onlyActiveMemberOrSelf
        onlyWhenNotGloballyDisabled
        onlyDelegateCall
        returns (ITokenDistributor.DistributionInfo memory distInfo)
    {
        // Get the address of the token distributor.
        ITokenDistributor distributor = ITokenDistributor(
            _GLOBALS.getAddress(LibGlobals.GLOBAL_TOKEN_DISTRIBUTOR)
        );
        emit DistributionCreated(tokenType, token, tokenId);
        // Create a native token distribution.
        address payable feeRecipient_ = feeRecipient;
        uint16 feeBps_ = feeBps;
        if (tokenType == ITokenDistributor.TokenType.Native) {
            return distributor.createNativeDistribution
                { value: address(this).balance }(this, feeRecipient_, feeBps_);
        }
        // Otherwise must be an ERC20 token distribution.
        assert(tokenType == ITokenDistributor.TokenType.Erc20);
        IERC20(token).compatTransfer(
            address(distributor),
            IERC20(token).balanceOf(address(this))
        );
        return distributor.createErc20Distribution(
            IERC20(token),
            this,
            feeRecipient_,
            feeBps_
        );
    }

    /// @notice Make a proposal for members to vote on and cast a vote to accept it
    ///         as well.
    /// @dev Only an active member (has voting power) can call this.
    ///      Afterwards, members can vote to support it with `accept()` or a party
    ///      host can unilaterally reject the proposal with `veto()`.
    /// @param proposal The details of the proposal.
    /// @param latestSnapIndex The index of the caller's most recent voting power
    ///                        snapshot before the proposal was created. Should
    ///                        be retrieved off-chain and passed in.
    function propose(Proposal memory proposal, uint256 latestSnapIndex)
        external
        onlyActiveMember
        onlyDelegateCall
        returns (uint256 proposalId)
    {
        proposalId = ++lastProposalId;
        // Store the time the proposal was created and the proposal hash.
        (
            _proposalStateByProposalId[proposalId].values,
            _proposalStateByProposalId[proposalId].hash
        ) = (
            ProposalStateValues({
                proposedTime: uint40(block.timestamp),
                passedTime: 0,
                executedTime: 0,
                completedTime: 0,
                votes: 0
            }),
            getProposalHash(proposal)
        );
        emit Proposed(proposalId, msg.sender, proposal);
        accept(proposalId, latestSnapIndex);
    }

    /// @notice Vote to support a proposed proposal.
    /// @dev The voting power cast will be the effective voting power of the caller
    ///      just before `propose()` was called (see `getVotingPowerAt()`).
    ///      If the proposal reaches `passThresholdBps` acceptance ratio then the
    ///      proposal will be in the `Passed` state and will be executable after
    ///      the `executionDelay` has passed, putting it in the `Ready` state.
    /// @param proposalId The ID of the proposal to accept.
    /// @param snapIndex The index of the caller's last voting power snapshot
    ///                  before the proposal was created. Should be retrieved
    ///                  off-chain and passed in.
    /// @return totalVotes The total votes cast on the proposal.
    function accept(uint256 proposalId, uint256 snapIndex)
        public
        onlyDelegateCall
        returns (uint256 totalVotes)
    {
        // Get the information about the proposal.
        ProposalState storage info = _proposalStateByProposalId[proposalId];
        ProposalStateValues memory values = info.values;

        // Can only vote in certain proposal statuses.
        {
            ProposalStatus status = _getProposalStatus(values);
            // Allow voting even if the proposal is passed/ready so it can
            // potentially reach 100% consensus, which unlocks special
            // behaviors for certain proposal types.
            if (
                status != ProposalStatus.Voting &&
                status != ProposalStatus.Passed &&
                status != ProposalStatus.Ready
            ) {
                revert BadProposalStatusError(status);
            }
        }

        // Cannot vote twice.
        if (info.hasVoted[msg.sender]) {
            revert AlreadyVotedError(msg.sender);
        }
        // Mark the caller as having voted.
        info.hasVoted[msg.sender] = true;

        // Increase the total votes that have been cast on this proposal.
        uint96 votingPower = getVotingPowerAt(msg.sender, values.proposedTime - 1, snapIndex);
        values.votes += votingPower;
        info.values = values;
        emit ProposalAccepted(proposalId, msg.sender, votingPower);

        // Update the proposal status if it has reached the pass threshold.
        if (values.passedTime == 0 && _areVotesPassing(
            values.votes,
            _governanceValues.totalVotingPower,
            _governanceValues.passThresholdBps))
        {
            info.values.passedTime = uint40(block.timestamp);
            emit ProposalPassed(proposalId);
        }
        return values.votes;
    }

    /// @notice As a party host, veto a proposal, unilaterally rejecting it.
    /// @dev The proposal will never be executable and cannot be voted on anymore.
    ///      A proposal that has been already executed at least once (in the `InProgress` status)
    ///      cannot be vetoed.
    /// @param proposalId The ID of the proposal to veto.
    function veto(uint256 proposalId) external onlyHost onlyDelegateCall {
        // Setting `votes` to -1 indicates a veto.
        ProposalState storage info = _proposalStateByProposalId[proposalId];
        ProposalStateValues memory values = info.values;

        {
            ProposalStatus status = _getProposalStatus(values);
            // Proposal must be in one of the following states.
            if (
                status != ProposalStatus.Voting &&
                status != ProposalStatus.Passed &&
                status != ProposalStatus.Ready
            ) {
                revert BadProposalStatusError(status);
            }
        }

        // -1 indicates veto.
        info.values.votes = VETO_VALUE;
        emit ProposalVetoed(proposalId, msg.sender);
    }

    /// @notice Executes a proposal that has passed governance.
    /// @dev The proposal must be in the `Ready` or `InProgress` status.
    ///      A `ProposalExecuted` event will be emitted with a non-empty `nextProgressData`
    ///      if the proposal has extra steps (must be executed again) to carry out,
    ///      in which case `nextProgressData` should be passed into the next `execute()` call.
    ///      The `ProposalExecutionEngine` enforces that only one `InProgress` proposal
    ///      is active at a time, so that proposal must be completed or cancelled via `cancel()`
    ///      in order to execute a different proposal.
    ///      `extraData` is optional, off-chain data a proposal might need to execute a step.
    /// @param proposalId The ID of the proposal to execute.
    /// @param proposal The details of the proposal.
    /// @param preciousTokens The tokens that the party considers precious.
    /// @param preciousTokenIds The token IDs associated with each precious token.
    /// @param progressData The data returned from the last `execute()` call, if any.
    /// @param extraData Off-chain data a proposal might need to execute a step.
    function execute(
        uint256 proposalId,
        Proposal memory proposal,
        IERC721[] memory preciousTokens,
        uint256[] memory preciousTokenIds,
        bytes calldata progressData,
        bytes calldata extraData
    )
        external
        payable
        onlyActiveMember
        onlyWhenNotGloballyDisabled
        onlyDelegateCall
    {
        // Get information about the proposal.
        ProposalState storage proposalState = _proposalStateByProposalId[proposalId];
        // Proposal details must remain the same from `propose()`.
        _validateProposalHash(proposal, proposalState.hash);
        ProposalStateValues memory values = proposalState.values;
        ProposalStatus status = _getProposalStatus(values);
        // The proposal must be executable or have already been executed but still
        // has more steps to go.
        if (status != ProposalStatus.Ready && status != ProposalStatus.InProgress) {
            revert BadProposalStatusError(status);
        }
        if (status == ProposalStatus.Ready) {
            // If the proposal has not been executed yet, make sure it hasn't
            // expired. Note that proposals that have been executed
            // (but still have more steps) ignore `maxExecutableTime`.
            if (proposal.maxExecutableTime < block.timestamp) {
                revert ExecutionTimeExceededError(
                    proposal.maxExecutableTime,
                    uint40(block.timestamp)
                );
            }
            proposalState.values.executedTime = uint40(block.timestamp);
        }
        // Check that the precious list is valid.
        if (!_isPreciousListCorrect(preciousTokens, preciousTokenIds)) {
            revert BadPreciousListError();
        }
        // Preemptively set the proposal to completed to avoid it being executed
        // again in a deeper call.
        proposalState.values.completedTime = uint40(block.timestamp);
        // Execute the proposal.
        bool completed = _executeProposal(
            proposalId,
            proposal,
            preciousTokens,
            preciousTokenIds,
            _getProposalFlags(values),
            progressData,
            extraData
        );
        if (!completed) {
            // Proposal did not complete.
            proposalState.values.completedTime = 0;
        }
    }

    /// @notice Cancel a (probably stuck) InProgress proposal.
    /// @dev `proposal.cancelDelay` seconds must have passed since it was first
    ///      executed for this to be valid. The currently active proposal will
    ///      simply be yeeted out of existence so another proposal can execute.
    ///      This is intended to be a last resort and can leave the party in a
    ///      broken state. Whenever possible, active proposals should be
    ///      allowed to complete their lifecycle.
    /// @param proposalId The ID of the proposal to cancel.
    /// @param proposal The details of the proposal to cancel.
    function cancel(uint256 proposalId, Proposal calldata proposal)
        external
        onlyActiveMember
        onlyDelegateCall
    {
        // Get information about the proposal.
        ProposalState storage proposalState = _proposalStateByProposalId[proposalId];
        // Proposal details must remain the same from `propose()`.
        _validateProposalHash(proposal, proposalState.hash);
        ProposalStateValues memory values = proposalState.values;
        {
            // Must be `InProgress`.
            ProposalStatus status = _getProposalStatus(values);
            if (status != ProposalStatus.InProgress) {
                revert BadProposalStatusError(status);
            }
        }
        {
            // Limit the `cancelDelay` to the global max and min cancel delay
            // to mitigate parties accidentally getting stuck forever by setting an
            // unrealistic `cancelDelay` or being reckless with too low a
            // cancel delay.
            uint256 cancelDelay = proposal.cancelDelay;
            uint256 globalMaxCancelDelay =
                _GLOBALS.getUint256(LibGlobals.GLOBAL_PROPOSAL_MAX_CANCEL_DURATION);
            uint256 globalMinCancelDelay =
                _GLOBALS.getUint256(LibGlobals.GLOBAL_PROPOSAL_MIN_CANCEL_DURATION);
            if (globalMaxCancelDelay != 0) { // Only if we have one set.
                if (cancelDelay > globalMaxCancelDelay) {
                    cancelDelay = globalMaxCancelDelay;
                }
            }
            if (globalMinCancelDelay != 0) { // Only if we have one set.
                if (cancelDelay < globalMinCancelDelay) {
                    cancelDelay = globalMinCancelDelay;
                }
            }
            uint256 cancelTime = values.executedTime + cancelDelay;
            // Must not be too early.
            if (block.timestamp < cancelTime) {
                revert ProposalCannotBeCancelledYetError(
                    uint40(block.timestamp),
                    uint40(cancelTime)
                );
            }
        }
        // Mark the proposal as cancelled by setting the completed time to the current
        // time with the high bit set.
        proposalState.values.completedTime = uint40(block.timestamp | UINT40_HIGH_BIT);
        {
            // Delegatecall into the proposal engine impl to perform the cancel.
            (bool success, bytes memory resultData) =
            (address(_getProposalExecutionEngine())).delegatecall(abi.encodeCall(
                IProposalExecutionEngine.cancelProposal,
                (proposalId)
            ));
            if (!success) {
                resultData.rawRevert();
            }
        }
        emit ProposalCancelled(proposalId);
    }

    /// @notice As the DAO, execute an arbitrary function call from this contract.
    /// @dev Emergency actions must not be revoked for this to work.
    /// @param targetAddress The contract to call.
    /// @param targetCallData The data to pass to the contract.
    /// @param amountEth The amount of ETH to send to the contract.
    function emergencyExecute(
        address targetAddress,
        bytes calldata targetCallData,
        uint256 amountEth
    )
        external
        payable
        onlyPartyDao
        onlyWhenEmergencyExecuteAllowed
        onlyDelegateCall
    {
        (bool success, bytes memory res) = targetAddress.call{value: amountEth}(targetCallData);
        if (!success) {
            res.rawRevert();
        }
        emit EmergencyExecute(targetAddress, targetCallData, amountEth);
    }

    /// @notice Revoke the DAO's ability to call emergencyExecute().
    /// @dev Either the DAO or the party host can call this.
    function disableEmergencyExecute() external onlyPartyDaoOrHost onlyDelegateCall {
        emergencyExecuteDisabled = true;
        emit EmergencyExecuteDisabled();
    }

    function _executeProposal(
        uint256 proposalId,
        Proposal memory proposal,
        IERC721[] memory preciousTokens,
        uint256[] memory preciousTokenIds,
        uint256 flags,
        bytes memory progressData,
        bytes memory extraData
    )
        private
        returns (bool completed)
    {
        // Setup the arguments for the proposal execution engine.
        IProposalExecutionEngine.ExecuteProposalParams memory executeParams =
            IProposalExecutionEngine.ExecuteProposalParams({
                proposalId: proposalId,
                proposalData: proposal.proposalData,
                progressData: progressData,
                extraData: extraData,
                preciousTokens: preciousTokens,
                preciousTokenIds: preciousTokenIds,
                flags: flags
            });
        // Get the progress data returned after the proposal is executed.
        bytes memory nextProgressData;
        {
            // Execute the proposal.
            (bool success, bytes memory resultData) =
                address(_getProposalExecutionEngine()).delegatecall(abi.encodeCall(
                    IProposalExecutionEngine.executeProposal,
                    (executeParams)
                ));
            if (!success) {
                resultData.rawRevert();
            }
            nextProgressData = abi.decode(resultData, (bytes));
        }
        emit ProposalExecuted(proposalId, msg.sender, nextProgressData);
        // If the returned progress data is empty, then the proposal completed
        // and it should not be executed again.
        return nextProgressData.length == 0;
    }

    // Get the most recent voting power snapshot <= timestamp using `hintindex` as a "hint".
    function _getVotingPowerSnapshotAt(address voter, uint40 timestamp, uint256 hintIndex)
        internal
        view
        returns (VotingPowerSnapshot memory snap)
    {
        VotingPowerSnapshot[] storage snaps = _votingPowerSnapshotsByVoter[voter];
        uint256 snapsLength = snaps.length;
        if (snapsLength != 0) {
            if (
                // Hint is within bounds.
                hintIndex < snapsLength &&
                // Snapshot is not too recent.
                snaps[hintIndex].timestamp <= timestamp &&
                // Snapshot is not too old.
                (hintIndex == snapsLength - 1 || snaps[hintIndex+1].timestamp > timestamp)
            ) {
                return snaps[hintIndex];
            }

            // Hint was wrong, fallback to binary search to find snapshot.
            hintIndex = findVotingPowerSnapshotIndex(voter, timestamp);
            // Check that snapshot was found.
            if (hintIndex != type(uint256).max) {
                return snaps[hintIndex];
            }
        }

        // No snapshot found.
        return snap;
    }

    // Transfers some voting power of `from` to `to`. The total voting power of
    // their respective delegates will be updated as well.
    function _transferVotingPower(address from, address to, uint256 power)
        internal
    {
        int192 powerI192 = power.safeCastUint256ToInt192();
        _adjustVotingPower(from, -powerI192, address(0));
        _adjustVotingPower(to, powerI192, address(0));
    }

    // Increase `voter`'s intrinsic voting power and update their delegate if delegate is nonzero.
    function _adjustVotingPower(address voter, int192 votingPower, address delegate)
        internal
    {
        VotingPowerSnapshot memory oldSnap =
            _getLastVotingPowerSnapshotForVoter(voter);
        address oldDelegate = delegationsByVoter[voter];
        // If `oldDelegate` is zero and `voter` never delegated, then have
        // `voter` delegate to themself.
        oldDelegate = oldDelegate == address(0) ? voter : oldDelegate;
        // If the new `delegate` is zero, use the current (old) delegate.
        delegate = delegate == address(0) ? oldDelegate : delegate;

        VotingPowerSnapshot memory newSnap = VotingPowerSnapshot({
            timestamp: uint40(block.timestamp),
            delegatedVotingPower: oldSnap.delegatedVotingPower,
            intrinsicVotingPower: (
                    oldSnap.intrinsicVotingPower.safeCastUint96ToInt192() + votingPower
                ).safeCastInt192ToUint96(),
            isDelegated: delegate != voter
        });
        _insertVotingPowerSnapshot(voter, newSnap);
        delegationsByVoter[voter] = delegate;
        // Handle rebalancing delegates.
        _rebalanceDelegates(voter, oldDelegate, delegate, oldSnap, newSnap);
    }

    function _getTotalVotingPower() internal view returns (uint256) {
        return _governanceValues.totalVotingPower;
    }

    // Update the delegated voting power of the old and new delegates delegated to
    // by `voter` based on the snapshot change.
    function _rebalanceDelegates(
        address voter,
        address oldDelegate,
        address newDelegate,
        VotingPowerSnapshot memory oldSnap,
        VotingPowerSnapshot memory newSnap
    )
        private
    {
        if (newDelegate == address(0) || oldDelegate == address(0)) {
            revert InvalidDelegateError();
        }
        if (oldDelegate != voter && oldDelegate != newDelegate) {
            // Remove past voting power from old delegate.
            VotingPowerSnapshot memory oldDelegateSnap =
                _getLastVotingPowerSnapshotForVoter(oldDelegate);
            VotingPowerSnapshot memory updatedOldDelegateSnap =
                VotingPowerSnapshot({
                    timestamp: uint40(block.timestamp),
                    delegatedVotingPower:
                        oldDelegateSnap.delegatedVotingPower -
                            oldSnap.intrinsicVotingPower,
                    intrinsicVotingPower: oldDelegateSnap.intrinsicVotingPower,
                    isDelegated: oldDelegateSnap.isDelegated
                });
            _insertVotingPowerSnapshot(oldDelegate, updatedOldDelegateSnap);
        }
        if (newDelegate != voter) { // Not delegating to self.
            // Add new voting power to new delegate.
            VotingPowerSnapshot memory newDelegateSnap =
                _getLastVotingPowerSnapshotForVoter(newDelegate);
            uint96 newDelegateDelegatedVotingPower =
                newDelegateSnap.delegatedVotingPower + newSnap.intrinsicVotingPower;
            if (newDelegate == oldDelegate) {
                // If the old and new delegate are the same, subtract the old
                // intrinsic voting power of the voter, or else we will double
                // count a portion of it.
                newDelegateDelegatedVotingPower -= oldSnap.intrinsicVotingPower;
            }
            VotingPowerSnapshot memory updatedNewDelegateSnap =
                VotingPowerSnapshot({
                    timestamp: uint40(block.timestamp),
                    delegatedVotingPower: newDelegateDelegatedVotingPower,
                    intrinsicVotingPower: newDelegateSnap.intrinsicVotingPower,
                    isDelegated: newDelegateSnap.isDelegated
                });
            _insertVotingPowerSnapshot(newDelegate, updatedNewDelegateSnap);
        }
    }

    // Append a new voting power snapshot, overwriting the last one if possible.
    function _insertVotingPowerSnapshot(address voter, VotingPowerSnapshot memory snap)
        private
    {
        VotingPowerSnapshot[] storage voterSnaps = _votingPowerSnapshotsByVoter[voter];
        uint256 n = voterSnaps.length;
        // If same timestamp as last entry, overwrite the last snapshot, otherwise append.
        if (n != 0) {
            VotingPowerSnapshot memory lastSnap = voterSnaps[n - 1];
            if (lastSnap.timestamp == snap.timestamp) {
                voterSnaps[n - 1] = snap;
                return;
            }
        }
        voterSnaps.push(snap);
    }

    function _getLastVotingPowerSnapshotForVoter(address voter)
        private
        view
        returns (VotingPowerSnapshot memory snap)
    {
        VotingPowerSnapshot[] storage voterSnaps = _votingPowerSnapshotsByVoter[voter];
        uint256 n = voterSnaps.length;
        if (n != 0) {
            snap = voterSnaps[n - 1];
        }
    }

    function _getProposalFlags(ProposalStateValues memory pv)
        private
        view
        returns (uint256)
    {
        if (_isUnanimousVotes(pv.votes, _governanceValues.totalVotingPower)) {
            return LibProposal.PROPOSAL_FLAG_UNANIMOUS;
        }
        return 0;
    }

    function _getProposalStatus(ProposalStateValues memory pv)
        private
        view
        returns (ProposalStatus status)
    {
        // Never proposed.
        if (pv.proposedTime == 0) {
            return ProposalStatus.Invalid;
        }
        // Executed at least once.
        if (pv.executedTime != 0) {
            if (pv.completedTime == 0) {
                return ProposalStatus.InProgress;
            }
            // completedTime high bit will be set if cancelled.
            if (pv.completedTime & UINT40_HIGH_BIT == UINT40_HIGH_BIT) {
                return ProposalStatus.Cancelled;
            }
            return ProposalStatus.Complete;
        }
        // Vetoed.
        if (pv.votes == type(uint96).max) {
            return ProposalStatus.Defeated;
        }
        uint40 t = uint40(block.timestamp);
        GovernanceValues memory gv = _governanceValues;
        if (pv.passedTime != 0) {
            // Ready.
            if (pv.passedTime + gv.executionDelay <= t) {
                return ProposalStatus.Ready;
            }
            // If unanimous, we skip the execution delay.
            if (_isUnanimousVotes(pv.votes, gv.totalVotingPower)) {
                return ProposalStatus.Ready;
            }
            // Passed.
            return ProposalStatus.Passed;
        }
        // Voting window expired.
        if (pv.proposedTime + gv.voteDuration <= t) {
            return ProposalStatus.Defeated;
        }
        return ProposalStatus.Voting;
    }

    function _isUnanimousVotes(uint96 totalVotes, uint96 totalVotingPower)
        private
        pure
        returns (bool)
    {
        uint256 acceptanceRatio = (totalVotes * 1e4) / totalVotingPower;
        // If >= 99.99% acceptance, consider it unanimous.
        // The minting formula for voting power is a bit lossy, so we check
        // for slightly less than 100%.
        return acceptanceRatio >= 0.9999e4;
    }

    function _areVotesPassing(
        uint96 voteCount,
        uint96 totalVotingPower,
        uint16 passThresholdBps
    )
        private
        pure
        returns (bool)
    {
          return uint256(voteCount) * 1e4
            / uint256(totalVotingPower) >= uint256(passThresholdBps);
    }

    function _setPreciousList(
        IERC721[] memory preciousTokens,
        uint256[] memory preciousTokenIds
    )
        private
    {
        if (preciousTokens.length != preciousTokenIds.length) {
            revert MismatchedPreciousListLengths();
        }
        preciousListHash = _hashPreciousList(preciousTokens, preciousTokenIds);
    }

    function _isPreciousListCorrect(
        IERC721[] memory preciousTokens,
        uint256[] memory preciousTokenIds
    )
        private
        view
        returns (bool)
    {
        return preciousListHash == _hashPreciousList(preciousTokens, preciousTokenIds);
    }

    function _hashPreciousList(
        IERC721[] memory preciousTokens,
        uint256[] memory preciousTokenIds
    )
        internal
        pure
        returns (bytes32 h)
    {
        assembly {
            mstore(0x00, keccak256(
                add(preciousTokens, 0x20),
                mul(mload(preciousTokens), 0x20)
            ))
            mstore(0x20, keccak256(
                add(preciousTokenIds, 0x20),
                mul(mload(preciousTokenIds), 0x20)
            ))
            h := keccak256(0x00, 0x40)
        }
    }

    // Assert that the hash of a proposal matches expectedHash.
    function _validateProposalHash(Proposal memory proposal, bytes32 expectedHash)
        private
        pure
    {
        bytes32 actualHash = getProposalHash(proposal);
        if (expectedHash != actualHash) {
            revert BadProposalHashError(actualHash, expectedHash);
        }
    }

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import "../utils/ReadOnlyDelegateCall.sol";
import "../utils/LibSafeCast.sol";
import "openzeppelin/contracts/interfaces/IERC2981.sol";
import "../globals/IGlobals.sol";
import "../tokens/IERC721.sol";
import "../vendor/solmate/ERC721.sol";
import "./PartyGovernance.sol";
import "../renderers/RendererStorage.sol";

/// @notice ERC721 functionality built on top of `PartyGovernance`.
contract PartyGovernanceNFT is
    PartyGovernance,
    ERC721,
    IERC2981
{
    using LibSafeCast for uint256;
    using LibSafeCast for uint96;

    error OnlyMintAuthorityError(address actual, address expected);

    // The `Globals` contract storing global configuration values. This contract
    // is immutable and it’s address will never change.
    IGlobals private immutable _GLOBALS;

    /// @notice Who can call `mint()`. Usually this will be the crowdfund contract that
    /// created the party.
    address public mintAuthority;
    /// @notice The number of tokens that have been minted.
    uint96 public tokenCount;
    /// @notice The total minted voting power.
    ///         Capped to `_governanceValues.totalVotingPower`
    uint96 public mintedVotingPower;
    /// @notice The voting power of `tokenId`.
    mapping (uint256 => uint256) public votingPowerByTokenId;

    modifier onlyMinter() {
        address minter = mintAuthority;
        if (msg.sender != minter) {
            revert OnlyMintAuthorityError(msg.sender, minter);
        }
        _;
    }

    // Set the `Globals` contract. The name of symbol of ERC721 does not matter;
    // it will be set in `_initialize()`.
    constructor(IGlobals globals) PartyGovernance(globals) ERC721('', '') {
        _GLOBALS = globals;
    }

    // Initialize storage for proxy contracts.
    function _initialize(
        string memory name_,
        string memory symbol_,
        uint256 customizationPresetId,
        PartyGovernance.GovernanceOpts memory governanceOpts,
        IERC721[] memory preciousTokens,
        uint256[] memory preciousTokenIds,
        address mintAuthority_
    )
        internal
    {
        PartyGovernance._initialize(governanceOpts, preciousTokens, preciousTokenIds);
        name = name_;
        symbol = symbol_;
        mintAuthority = mintAuthority_;
        if (customizationPresetId != 0) {
            RendererStorage(_GLOBALS.getAddress(LibGlobals.GLOBAL_RENDERER_STORAGE))
                .useCustomizationPreset(customizationPresetId);
        }
    }

    /// @inheritdoc ERC721
    function ownerOf(uint256 tokenId)
        public
        view
        override(ERC721, ITokenDistributorParty)
        returns (address owner)
    {
        return ERC721.ownerOf(tokenId);
    }

    /// @inheritdoc EIP165
    function supportsInterface(bytes4 interfaceId)
        public
        pure
        override(PartyGovernance, ERC721, IERC165)
        returns (bool)
    {
        return PartyGovernance.supportsInterface(interfaceId) ||
            ERC721.supportsInterface(interfaceId) ||
            interfaceId == type(IERC2981).interfaceId;
    }

    /// @inheritdoc ERC721
    function tokenURI(uint256) public override view returns (string memory) {
        _delegateToRenderer();
        return ""; // Just to make the compiler happy.
    }

    /// @notice Returns a URI for the storefront-level metadata for your contract.
    function contractURI() external view returns (string memory) {
        _delegateToRenderer();
        return ""; // Just to make the compiler happy.
    }

    /// @notice Called with the sale price to determine how much royalty
    //          is owed and to whom.
    function royaltyInfo(uint256, uint256)
        external
        view
        returns (address, uint256)
    {
        _delegateToRenderer();
        return (address(0), 0); // Just to make the compiler happy.
    }

    /// @inheritdoc ITokenDistributorParty
    function getDistributionShareOf(uint256 tokenId) external view returns (uint256) {
        return votingPowerByTokenId[tokenId] * 1e18 / _getTotalVotingPower();
    }

    /// @notice Mint a governance NFT for `owner` with `votingPower` and
    /// immediately delegate voting power to `delegate.`
    /// @param owner The owner of the NFT.
    /// @param votingPower The voting power of the NFT.
    /// @param delegate The address to delegate voting power to.
    function mint(
        address owner,
        uint256 votingPower,
        address delegate
    )
        external
        onlyMinter
        onlyDelegateCall
        returns (uint256 tokenId)
    {
        (uint96 tokenCount_, uint96 mintedVotingPower_) = (tokenCount, mintedVotingPower);
        uint96 totalVotingPower = _governanceValues.totalVotingPower;
        // Cap voting power to remaining unminted voting power supply.
        uint96 votingPower_ = votingPower.safeCastUint256ToUint96();
        if (totalVotingPower - mintedVotingPower_ < votingPower_) {
            votingPower_ = totalVotingPower - mintedVotingPower_;
        }
        mintedVotingPower_ += votingPower_;
        // Update state.
        tokenId = tokenCount = tokenCount_ + 1;
        mintedVotingPower = mintedVotingPower_;
        votingPowerByTokenId[tokenId] = votingPower_;

        // Use delegate from party over the one set during crowdfund.
        address delegate_ = delegationsByVoter[owner];
        if (delegate_ != address(0)) {
            delegate = delegate_;
        }

        _adjustVotingPower(owner, votingPower_.safeCastUint96ToInt192(), delegate);
        _safeMint(owner, tokenId);
    }

    /// @inheritdoc ERC721
    function transferFrom(address owner, address to, uint256 tokenId)
        public
        override
        onlyDelegateCall
    {
        // Transfer voting along with token.
        _transferVotingPower(owner, to, votingPowerByTokenId[tokenId]);
        super.transferFrom(owner, to, tokenId);
    }

    /// @inheritdoc ERC721
    function safeTransferFrom(address owner, address to, uint256 tokenId)
        public
        override
        onlyDelegateCall
    {
        // super.safeTransferFrom() will call transferFrom() first which will
        // transfer voting power.
        super.safeTransferFrom(owner, to, tokenId);
    }

    /// @inheritdoc ERC721
    function safeTransferFrom(address owner, address to, uint256 tokenId, bytes calldata data)
        public
        override
        onlyDelegateCall
    {
        // super.safeTransferFrom() will call transferFrom() first which will
        // transfer voting power.
        super.safeTransferFrom(owner, to, tokenId, data);
    }

    /// @notice Relinquish the ability to call `mint()` by an authority.
    function abdicate() external onlyMinter onlyDelegateCall {
        delete mintAuthority;
    }

    function _delegateToRenderer() private view {
        _readOnlyDelegateCall(
            // Instance of IERC721Renderer.
            _GLOBALS.getAddress(LibGlobals.GLOBAL_GOVERNANCE_NFT_RENDER_IMPL),
            msg.data
        );
        assert(false); // Will not be reached.
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import "../tokens/IERC721.sol";

// Upgradeable proposals logic contract interface.
interface IProposalExecutionEngine {
    struct ExecuteProposalParams {
        uint256 proposalId;
        bytes proposalData;
        bytes progressData;
        bytes extraData;
        uint256 flags;
        IERC721[] preciousTokens;
        uint256[] preciousTokenIds;
    }

    function initialize(address oldImpl, bytes memory initData) external;

    /// @notice Execute a proposal.
    /// @dev Must be delegatecalled into by PartyGovernance.
    ///      If the proposal is incomplete, continues its next step (if possible).
    ///      If another proposal is incomplete, this will fail. Only one
    ///      incomplete proposal is allowed at a time.
    /// @param params The data needed to execute the proposal.
    /// @return nextProgressData Bytes to be passed into the next `execute()` call,
    ///         if the proposal execution is incomplete. Otherwise, empty bytes
    ///         to indicate the proposal is complete.
    function executeProposal(ExecuteProposalParams memory params)
        external returns (bytes memory nextProgressData);

    /// @notice Forcibly cancel an incomplete proposal.
    /// @param proposalId The ID of the proposal to cancel.
    /// @dev This is intended to be a last resort as it can leave a party in a
    ///      broken step. Whenever possible, proposals should be allowed to
    ///      complete their entire lifecycle.
    function cancelProposal(uint256 proposalId) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import "../tokens/IERC721.sol";

library LibProposal {
    uint256 internal constant PROPOSAL_FLAG_UNANIMOUS = 0x1;

    function isTokenPrecious(IERC721 token, IERC721[] memory preciousTokens)
        internal
        pure
        returns (bool)
    {
        for (uint256 i; i < preciousTokens.length; ++i) {
            if (token == preciousTokens[i]) {
                return true;
            }
        }
        return false;
    }

    function isTokenIdPrecious(
        IERC721 token,
        uint256 tokenId,
        IERC721[] memory preciousTokens,
        uint256[] memory preciousTokenIds
    )
        internal
        pure
        returns (bool)
    {
        for (uint256 i; i < preciousTokens.length; ++i) {
            if (token == preciousTokens[i] && tokenId == preciousTokenIds[i]) {
                return true;
            }
        }
        return false;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import "./IProposalExecutionEngine.sol";
import "../utils/LibRawResult.sol";

// The storage bucket shared by `PartyGovernance` and the `ProposalExecutionEngine`.
// Read this for more context on the pattern motivating this:
// https://github.com/dragonfly-xyz/useful-solidity-patterns/tree/main/patterns/explicit-storage-buckets
abstract contract ProposalStorage {
    using LibRawResult for bytes;

    struct SharedProposalStorage {
        IProposalExecutionEngine engineImpl;
    }

    uint256 internal constant PROPOSAL_FLAG_UNANIMOUS = 0x1;
    uint256 private constant SHARED_STORAGE_SLOT = uint256(keccak256("ProposalStorage.SharedProposalStorage"));

    function _getProposalExecutionEngine()
        internal
        view
        returns (IProposalExecutionEngine impl)
    {
        return _getSharedProposalStorage().engineImpl;
    }

    function _setProposalExecutionEngine(IProposalExecutionEngine impl) internal {
        _getSharedProposalStorage().engineImpl = impl;
    }

    function _initProposalImpl(IProposalExecutionEngine impl, bytes memory initData)
        internal
    {
        SharedProposalStorage storage stor = _getSharedProposalStorage();
        IProposalExecutionEngine oldImpl = stor.engineImpl;
        stor.engineImpl = impl;
        (bool s, bytes memory r) = address(impl).delegatecall(
            abi.encodeCall(
                IProposalExecutionEngine.initialize,
                (address(oldImpl), initData)
            )
        );
        if (!s) {
            r.rawRevert();
        }
    }

    function _getSharedProposalStorage()
        private
        pure
        returns (SharedProposalStorage storage stor)
    {
        uint256 s = SHARED_STORAGE_SLOT;
        assembly { stor.slot := s }
    }

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import "solmate/utils/SSTORE2.sol";
import "../utils/Multicall.sol";

contract RendererStorage is Multicall {
    error AlreadySetError();
    error NotOwnerError(address caller, address owner);

    event OwnershipTransferred(address previousOwner, address newOwner);

    uint256 constant CROWDFUND_CARD_DATA = 0;
    uint256 constant PARTY_CARD_DATA = 1;

    /// @notice Address allowed to store new data.
    address public owner;

    /// @notice Customization presets by ID, used for rendering cards. Begins at
    ///         1, 0 is reserved to indicate in `getPresetFor()` that a
    ///         party instance use the preset set by the crowdfund instance that
    ///         created it.
    mapping(uint256 => bytes) public customizationPresets;
    /// @notice Customization preset used by a crowdfund or party instance.
    mapping(address => uint256) public getPresetFor;
    /// @notice Addresses where URI data chunks are stored.
    mapping(uint256 => address) public files;

    modifier onlyOwner() {
        address owner_ = owner;
        if (msg.sender != owner_) {
            revert NotOwnerError(msg.sender, owner_);
        }

        _;
    }

    constructor(address _owner) {
        // Set the address allowed to write new data.
        owner = _owner;

        // Write URI data used by V1 of the renderers:

        files[CROWDFUND_CARD_DATA] = SSTORE2.write(bytes(
            '<path class="o" d="M118.4 419.5h5.82v1.73h-4.02v1.87h3.74v1.73h-3.74v1.94h4.11v1.73h-5.91v-9Zm9.93 1.76h-2.6v-1.76h7.06v1.76h-2.61v7.24h-1.85v-7.24Zm6.06-1.76h1.84v3.55h3.93v-3.55H142v9h-1.84v-3.67h-3.93v3.67h-1.84v-9Z"/><path class="o" d="M145 413a4 4 0 0 1 4 4v14a4 4 0 0 1-4 4H35a4 4 0 0 1-4-4v-14a4 4 0 0 1 4-4h110m0-1H35a5 5 0 0 0-5 5v14a5 5 0 0 0 5 5h110a5 5 0 0 0 5-5v-14a5 5 0 0 0-5-5Z"/><path d="M239.24 399.83h3.04c1.7 0 2.82 1 2.82 2.55 0 2.1-1.27 3.32-3.57 3.32h-1.97l-.71 3.3h-1.56l1.96-9.17Zm2.34 4.38c1.23 0 1.88-.58 1.88-1.68 0-.73-.49-1.2-1.48-1.2h-1.51l-.6 2.88h1.7Zm3.57 1.86c0-2.27 1.44-3.83 3.57-3.83 1.82 0 3.06 1.25 3.06 3.09 0 2.28-1.43 3.83-3.57 3.83-1.82 0-3.06-1.25-3.06-3.09Zm3.13 1.74c1.19 0 1.93-1.02 1.93-2.52 0-1.06-.62-1.69-1.56-1.69-1.19 0-1.93 1.02-1.93 2.52 0 1.06.62 1.69 1.56 1.69Zm4.74-5.41h1.49l.28 4.73 2.25-4.73h1.64l.23 4.77 2.25-4.77h1.56l-3.3 6.61h-1.62l-.25-5.04-2.42 5.04h-1.63l-.48-6.61Zm9.54 3.66c0-2.27 1.45-3.81 3.6-3.81 2 0 3.05 1.58 2.33 3.92h-4.46c0 1.1.81 1.68 2.05 1.68.8 0 1.45-.2 2.1-.59l-.31 1.46a4.2 4.2 0 0 1-2.04.44c-2.06 0-3.26-1.19-3.26-3.11Zm4.7-1.07c.12-.86-.31-1.46-1.22-1.46s-1.57.61-1.82 1.46h3.05Zm3.46-2.59h1.55l-.28 1.28c.81-1.7 2.56-1.36 2.77-1.29l-.35 1.46c-.18-.06-2.3-.63-2.82 1.68l-.74 3.48h-1.55l1.42-6.61Zm3.91 3.66c0-2.27 1.45-3.81 3.6-3.81 2 0 3.05 1.58 2.33 3.92h-4.46c0 1.1.81 1.68 2.05 1.68.8 0 1.45-.2 2.1-.59l-.31 1.46a4.2 4.2 0 0 1-2.04.44c-2.06 0-3.26-1.19-3.26-3.11Zm4.7-1.07c.12-.86-.31-1.46-1.22-1.46s-1.57.61-1.82 1.46h3.05Zm2.25 1.36c0-2.44 1.36-4.1 3.26-4.1 1 0 1.76.53 2.05 1.31l.79-3.72h1.55l-1.96 9.17h-1.55l.2-.92a2.15 2.15 0 0 1-1.92 1.08c-1.49 0-2.43-1.18-2.43-2.82Zm3 1.51c.88 0 1.51-.58 1.73-1.56l.17-.81c.24-1.1-.31-1.93-1.36-1.93-1.19 0-1.94 1.08-1.94 2.59 0 1.06.55 1.71 1.4 1.71Zm9.6-.01-.25 1.16h-1.55l1.96-9.17h1.55l-.73 3.47a2.35 2.35 0 0 1 1.99-1.05c1.49 0 2.35 1.16 2.35 2.76 0 2.52-1.36 4.16-3.21 4.16-.98 0-1.81-.53-2.1-1.32Zm1.83.01c1.16 0 1.87-1.06 1.87-2.61 0-1.04-.5-1.69-1.39-1.69s-1.52.56-1.73 1.55l-.17.79c-.24 1.14.34 1.97 1.42 1.97Zm5.68 1.16-1.04-6.62h1.52l.66 4.75 2.66-4.75h1.69l-5.31 9.13h-1.73l1.55-2.51Zm23.48-6.8a42.14 42.14 0 0 0-.75 6.01 43.12 43.12 0 0 0 5.58 2.35 42.54 42.54 0 0 0 5.58-2.35 45.32 45.32 0 0 0-.75-6.01c-.91-.79-2.6-2.21-4.83-3.66a42.5 42.5 0 0 0-4.83 3.66Zm13.07-7.95s.82-.29 1.76-.45a14.9 14.9 0 0 0-9.53-3.81c.66.71 1.28 1.67 1.84 2.75 1.84.22 4.07.7 5.92 1.51Zm-2.71 18.36c-2.06-.4-4.05-.97-5.53-1.51a38.65 38.65 0 0 1-5.53 1.51c.12 1.5.35 3.04.76 4.58 0 0 1.54 1.82 4.78 2.8 3.23-.98 4.78-2.8 4.78-2.8.4-1.53.64-3.08.76-4.58Zm-13.77-18.37a22.3 22.3 0 0 1 5.93-1.51 12.4 12.4 0 0 1 1.84-2.75 14.97 14.97 0 0 0-9.53 3.81c.95.16 1.76.45 1.76.45Zm-4.72 8.77a25.74 25.74 0 0 0 3.58 2.94 37.48 37.48 0 0 1 4.08-4.04c.27-1.56.77-3.57 1.46-5.55a25.24 25.24 0 0 0-4.34-1.63s-2.35.42-4.81 2.74c-.77 3.29.04 5.54.04 5.54Zm25.92 0s.81-2.25.04-5.54c-2.46-2.31-4.81-2.74-4.81-2.74-1.53.42-2.99.99-4.34 1.63a37.79 37.79 0 0 1 1.46 5.55 37.44 37.44 0 0 1 4.08 4.04 25.86 25.86 0 0 0 3.58-2.94Zm-26.38.2s-.66-.56-1.27-1.3c-.7 3.34-.27 6.93 1.46 10.16.28-.93.8-1.94 1.46-2.97a22.32 22.32 0 0 1-1.66-5.88Zm8.24 14.27a22.07 22.07 0 0 1-4.27-4.38c-1.22.06-2.36 0-3.3-.22a14.91 14.91 0 0 0 8.07 6.34c-.34-.9-.5-1.75-.5-1.75Zm18.6-14.27s.66-.56 1.27-1.3c.7 3.34.27 6.93-1.46 10.16-.28-.93-.8-1.94-1.46-2.97a22.32 22.32 0 0 0 1.66-5.88Zm-8.24 14.27a22.07 22.07 0 0 0 4.27-4.38c1.22.06 2.36 0 3.3-.22a14.91 14.91 0 0 1-8.07 6.34c.34-.9.5-1.75.5-1.75ZM330 391.84l-4.12 2.45 1.26 3.91h5.72l1.26-3.91-4.12-2.45Zm-11.4 19.74 4.18 2.35 2.75-3.05-2.86-4.95-4.02.86-.06 4.79Zm22.79 0-.06-4.79-4.02-.86-2.86 4.95 2.75 3.05 4.18-2.35Z" style="fill:#00c1fa"/><use height="300" transform="matrix(1 0 0 .09 29.85 444)" width="300.15" xlink:href="#a"/><use height="21.15" transform="translate(30 446.92)" width="300" xlink:href="#b"/><g><path d="m191.54 428.67-28.09-24.34A29.98 29.98 0 0 0 143.8 397H30a15 15 0 0 0-15 15v98a15 15 0 0 0 15 15h300a15 15 0 0 0 15-15v-59a15 15 0 0 0-15-15H211.19a30 30 0 0 1-19.65-7.33Z" style="fill:url(#i)"/></g></svg>'
        ));

        files[PARTY_CARD_DATA] = SSTORE2.write(bytes(
            ' d="M30 444.28h4.3c3.05 0 5.17 2.13 5.17 5.36s-2.11 5.35-5.17 5.35H30v-10.72Zm3.95 8.61c2.07 0 3.24-1.2 3.24-3.25s-1.16-3.26-3.24-3.26h-1.77v6.51h1.77Zm7.78-8.61h2.19V455h-2.19v-10.72Zm4.79 10.02v-2.31c1 .74 2.13 1.13 3.25 1.13s1.68-.45 1.68-1.23c0-.69-.39-.95-1.23-1.19l-1.19-.34c-1.78-.48-2.65-1.46-2.65-3.1 0-1.95 1.5-3.18 3.87-3.18 1.05 0 2.09.21 2.91.66V447a5.53 5.53 0 0 0-2.96-.84c-.93 0-1.57.35-1.57 1.06.01.6.39.91 1.16 1.12l1.32.39c1.82.5 2.61 1.42 2.61 3.07 0 2.1-1.53 3.39-3.82 3.39a6.08 6.08 0 0 1-3.38-.9Zm11.93-7.92h-3.1v-2.1h8.41v2.1h-3.11V455h-2.2v-8.62Zm7.56-2.1h4.5c2 0 3.33 1.26 3.33 3.25 0 1.86-1.18 3.1-3.01 3.19l3.53 4.27H71.7l-3.54-4.43v4.43h-2.14v-10.72Zm4.1 4.85c.98 0 1.54-.55 1.54-1.44s-.56-1.43-1.54-1.43h-1.96v2.87h1.96Zm6.04-4.85h2.19V455h-2.19v-10.72Zm5.07 0h4.5c1.99 0 3.21 1.15 3.21 2.79 0 1.06-.5 1.93-1.36 2.32a2.46 2.46 0 0 1 1.78 2.49c0 1.9-1.33 3.11-3.52 3.11h-4.61v-10.72Zm4.17 4.4c.87 0 1.37-.45 1.37-1.26s-.5-1.26-1.37-1.26h-2.06v2.52h2.06Zm.34 4.44c.88 0 1.46-.46 1.46-1.29s-.57-1.3-1.46-1.3h-2.39v2.59h2.39Zm5.63-2.51v-6.33h2.18v6.29c0 1.6.88 2.52 2.3 2.52s2.28-.92 2.28-2.52v-6.29h2.18v6.33c0 2.86-1.72 4.58-4.47 4.58s-4.48-1.72-4.48-4.58Zm14.21-4.23h-3.1v-2.1h8.41v2.1h-3.11V455h-2.2v-8.62Zm7.56-2.1h2.18V455h-2.18v-10.72Zm4.45 5.36c0-3.25 2.21-5.56 5.32-5.56s5.28 2.31 5.28 5.56-2.2 5.55-5.28 5.55-5.32-2.31-5.32-5.55Zm5.32 3.45c1.85 0 3-1.34 3-3.45s-1.15-3.46-3-3.46-3.04 1.34-3.04 3.46 1.16 3.45 3.04 3.45Zm7.54-8.81h2.94l4.03 8.17v-8.17h2.07V455h-2.93l-4.03-8.17V455h-2.09v-10.72Zm11.65 10.02v-2.31c.99.74 2.13 1.13 3.25 1.13s1.68-.45 1.68-1.23c0-.69-.39-.95-1.23-1.19l-1.19-.34c-1.78-.48-2.65-1.46-2.65-3.1 0-1.95 1.5-3.18 3.87-3.18 1.05 0 2.09.21 2.91.66V447a5.53 5.53 0 0 0-2.96-.84c-.92 0-1.57.35-1.57 1.06.01.6.39.91 1.16 1.12l1.32.39c1.82.5 2.61 1.42 2.61 3.07 0 2.1-1.53 3.39-3.82 3.39a6.08 6.08 0 0 1-3.38-.9Zm45.9-10.02h2.38l2.63 8.18 2.72-8.18h2.33L194.39 455h-2.76l-3.64-10.72Zm11.19 5.36c0-3.25 2.21-5.56 5.32-5.56s5.28 2.31 5.28 5.56-2.2 5.55-5.28 5.55-5.32-2.31-5.32-5.55Zm5.32 3.45c1.85 0 3-1.34 3-3.45s-1.15-3.46-3-3.46-3.04 1.34-3.04 3.46 1.16 3.45 3.04 3.45Zm9.41-6.71h-3.1v-2.1h8.41v2.1h-3.11V455h-2.2v-8.62Zm7.56-2.1h6.93v2.06h-4.79v2.23h4.45v2.06h-4.45v2.31h4.89V455h-7.03v-10.72Zm14.17 0h4.27c2.25 0 3.66 1.33 3.66 3.52s-1.4 3.53-3.66 3.53h-2.11V455h-2.16v-10.72Zm4.08 4.99c1.06 0 1.61-.53 1.61-1.47s-.55-1.46-1.61-1.46h-1.92v2.93h1.92Zm5.49.38c0-3.25 2.21-5.56 5.32-5.56s5.28 2.31 5.28 5.56-2.2 5.55-5.28 5.55-5.32-2.31-5.32-5.55Zm5.32 3.45c1.85 0 3-1.34 3-3.45s-1.15-3.46-3-3.46-3.04 1.34-3.04 3.46 1.16 3.45 3.04 3.45Zm6.54-8.81h2.34l1.69 7.84 1.86-7.84h2.41l1.82 7.84 1.75-7.84h2.27l-2.66 10.72H266l-1.88-8.15-1.85 8.15h-2.55l-2.66-10.72Zm16.11 0h6.93v2.06h-4.79v2.23h4.45v2.06h-4.45v2.31h4.89v2.06h-7.03v-10.72Zm9.69 0h4.5c2 0 3.33 1.26 3.33 3.25 0 1.86-1.18 3.1-3.01 3.19l3.53 4.27h-2.66l-3.54-4.43V455h-2.14v-10.72Zm4.1 4.85c.98 0 1.54-.55 1.54-1.44s-.56-1.43-1.54-1.43h-1.96v2.87h1.96ZM30 259.28h4.27c2.25 0 3.66 1.33 3.66 3.52s-1.4 3.53-3.66 3.53h-2.12V270h-2.16v-10.72Zm4.08 4.99c1.06 0 1.61-.53 1.61-1.47s-.55-1.46-1.61-1.46h-1.92v2.93h1.92Zm6.1-4.99h4.5c2 0 3.33 1.26 3.33 3.25 0 1.86-1.18 3.1-3.01 3.19l3.53 4.27h-2.66l-3.54-4.43v4.43h-2.14v-10.72Zm4.1 4.85c.98 0 1.54-.55 1.54-1.44s-.56-1.43-1.54-1.43h-1.96v2.87h1.96Zm5.43.52c0-3.25 2.21-5.56 5.32-5.56s5.28 2.31 5.28 5.56-2.2 5.55-5.28 5.55-5.32-2.31-5.32-5.55Zm5.32 3.45c1.85 0 3-1.34 3-3.45s-1.15-3.46-3-3.46-3.04 1.34-3.04 3.46 1.16 3.45 3.04 3.45Zm7.54-8.81h4.27c2.25 0 3.66 1.33 3.66 3.52s-1.4 3.53-3.66 3.53h-2.11v3.67h-2.16v-10.72Zm4.08 4.99c1.06 0 1.61-.53 1.61-1.47s-.55-1.46-1.61-1.46h-1.92v2.93h1.92Zm5.49.38c0-3.25 2.21-5.56 5.32-5.56s5.28 2.31 5.28 5.56-2.2 5.55-5.28 5.55-5.32-2.31-5.32-5.55Zm5.32 3.45c1.85 0 3-1.34 3-3.45s-1.15-3.46-3-3.46-3.04 1.34-3.04 3.46 1.16 3.45 3.04 3.45Zm7.26 1.21v-2.31c.99.74 2.13 1.13 3.25 1.13s1.68-.45 1.68-1.23c0-.69-.39-.95-1.23-1.19l-1.19-.34c-1.78-.48-2.65-1.46-2.65-3.1 0-1.95 1.5-3.18 3.87-3.18 1.05 0 2.09.21 2.91.66v2.26a5.53 5.53 0 0 0-2.96-.84c-.92 0-1.57.35-1.57 1.06.01.6.39.91 1.16 1.12l1.32.39c1.82.5 2.61 1.42 2.61 3.07 0 2.1-1.53 3.39-3.82 3.39a6.08 6.08 0 0 1-3.38-.9Zm12.22-10.02h2.83l3.67 10.72h-2.28l-.83-2.55h-4.02l-.83 2.55h-2.2l3.66-10.72Zm2.76 6.25-1.39-4.24-1.37 4.24h2.76Zm5.72-6.25h2.19v8.61h4.73v2.1h-6.92v-10.72Zm9.06 10.02v-2.31c.99.74 2.13 1.13 3.25 1.13s1.68-.45 1.68-1.23c0-.69-.39-.95-1.23-1.19l-1.19-.34c-1.78-.48-2.65-1.46-2.65-3.1 0-1.95 1.5-3.18 3.87-3.18 1.05 0 2.09.21 2.91.66v2.26a5.53 5.53 0 0 0-2.96-.84c-.92 0-1.57.35-1.57 1.06.01.6.39.91 1.16 1.12l1.32.39c1.82.5 2.61 1.42 2.61 3.07 0 2.1-1.53 3.39-3.82 3.39a6.08 6.08 0 0 1-3.38-.9ZM30 199.28h2.94l4.03 8.17v-8.17h2.07V210h-2.93l-4.03-8.17V210h-2.09v-10.72Zm14.7 0h2.83L51.2 210h-2.28l-.83-2.55h-4.02l-.83 2.55h-2.2l3.66-10.72Zm2.76 6.25-1.39-4.24-1.37 4.24h2.76Zm5.72-6.25h3.28l2.49 8.21 2.45-8.21h3.33V210h-2.04v-8.62L59.96 210h-2.07l-2.7-8.47V210h-2v-10.72Zm14.43 0h6.93v2.06h-4.79v2.23h4.45v2.06h-4.45v2.31h4.89V210h-7.03v-10.72Z" /><path d="M239.24 24.83h3.04c1.7 0 2.82 1 2.82 2.55 0 2.1-1.27 3.32-3.57 3.32h-1.97l-.71 3.3h-1.56l1.96-9.17Zm2.34 4.38c1.23 0 1.88-.58 1.88-1.68 0-.73-.49-1.2-1.48-1.2h-1.51l-.6 2.88h1.7Zm3.57 1.86c0-2.27 1.44-3.83 3.57-3.83 1.82 0 3.06 1.25 3.06 3.09 0 2.28-1.43 3.83-3.57 3.83-1.82 0-3.06-1.25-3.06-3.09Zm3.13 1.74c1.19 0 1.93-1.02 1.93-2.52 0-1.06-.62-1.69-1.56-1.69-1.19 0-1.93 1.02-1.93 2.52 0 1.06.62 1.69 1.56 1.69Zm4.74-5.41h1.49l.28 4.73 2.25-4.73h1.64l.23 4.77 2.25-4.77h1.56l-3.3 6.61h-1.62l-.25-5.04-2.42 5.04h-1.63l-.48-6.61Zm9.54 3.66c0-2.27 1.45-3.81 3.6-3.81 2 0 3.05 1.58 2.33 3.92h-4.46c0 1.1.81 1.68 2.05 1.68.8 0 1.45-.2 2.1-.59l-.31 1.46a4.2 4.2 0 0 1-2.04.44c-2.06 0-3.26-1.19-3.26-3.11Zm4.7-1.07c.12-.86-.31-1.46-1.22-1.46s-1.57.61-1.82 1.46h3.05Zm3.46-2.59h1.55l-.28 1.28c.81-1.7 2.56-1.36 2.77-1.29l-.35 1.46c-.18-.06-2.3-.63-2.82 1.68l-.74 3.48h-1.55l1.42-6.61Zm3.91 3.66c0-2.27 1.45-3.81 3.6-3.81 2 0 3.05 1.58 2.33 3.92h-4.46c0 1.1.81 1.68 2.05 1.68.8 0 1.45-.2 2.1-.59l-.31 1.46a4.2 4.2 0 0 1-2.04.44c-2.06 0-3.26-1.19-3.26-3.11Zm4.7-1.07c.12-.86-.31-1.46-1.22-1.46s-1.57.61-1.82 1.46h3.05Zm2.25 1.36c0-2.44 1.36-4.1 3.26-4.1 1 0 1.76.53 2.05 1.31l.79-3.72h1.55l-1.96 9.17h-1.55l.2-.92a2.15 2.15 0 0 1-1.92 1.08c-1.49 0-2.43-1.18-2.43-2.82Zm3 1.51c.88 0 1.51-.58 1.73-1.56l.17-.81c.24-1.1-.31-1.93-1.36-1.93-1.19 0-1.94 1.08-1.94 2.59 0 1.06.55 1.71 1.4 1.71Zm9.6-.01-.25 1.16h-1.55l1.96-9.17h1.55l-.73 3.47a2.35 2.35 0 0 1 1.99-1.05c1.49 0 2.35 1.16 2.35 2.76 0 2.52-1.36 4.16-3.21 4.16-.98 0-1.81-.53-2.1-1.32Zm1.83.01c1.16 0 1.87-1.06 1.87-2.61 0-1.04-.5-1.69-1.39-1.69s-1.52.56-1.73 1.55l-.17.79c-.24 1.14.34 1.97 1.42 1.97Zm5.68 1.16-1.04-6.62h1.52l.66 4.75 2.66-4.75h1.69l-5.31 9.13h-1.73l1.55-2.51Zm23.47-6.8c.91-.79 2.6-2.21 4.83-3.66a42.5 42.5 0 0 1 4.83 3.66c.23 1.18.62 3.36.75 6.01a43.12 43.12 0 0 1-5.58 2.35 42.54 42.54 0 0 1-5.58-2.35c.14-2.65.53-4.83.75-6.01Zm13.07-7.95s.82-.29 1.76-.45a14.9 14.9 0 0 0-9.53-3.81c.66.71 1.28 1.67 1.84 2.75 1.84.22 4.07.7 5.92 1.51Zm-2.71 18.36c-2.06-.4-4.05-.97-5.53-1.51a38.65 38.65 0 0 1-5.53 1.51c.12 1.5.35 3.04.76 4.58 0 0 1.54 1.82 4.78 2.8 3.23-.98 4.78-2.8 4.78-2.8.4-1.53.64-3.08.76-4.58Zm-13.77-18.37a22.3 22.3 0 0 1 5.93-1.51 12.4 12.4 0 0 1 1.84-2.75 14.97 14.97 0 0 0-9.53 3.81c.95.16 1.76.45 1.76.45Zm-4.72 8.77a25.74 25.74 0 0 0 3.58 2.94 37.48 37.48 0 0 1 4.08-4.04c.27-1.56.77-3.57 1.46-5.55a25.24 25.24 0 0 0-4.34-1.63s-2.35.42-4.81 2.74c-.77 3.29.04 5.54.04 5.54Zm25.92 0s.81-2.25.04-5.54c-2.46-2.31-4.81-2.74-4.81-2.74-1.53.42-2.99.99-4.34 1.63a37.79 37.79 0 0 1 1.46 5.55 37.44 37.44 0 0 1 4.08 4.04 25.86 25.86 0 0 0 3.58-2.94Zm-26.38.2s-.66-.56-1.27-1.3c-.7 3.34-.27 6.93 1.46 10.16.28-.93.8-1.94 1.46-2.97a22.32 22.32 0 0 1-1.66-5.88Zm8.24 14.27a22.07 22.07 0 0 1-4.27-4.38c-1.22.06-2.36 0-3.3-.22a14.91 14.91 0 0 0 8.07 6.34c-.34-.9-.5-1.75-.5-1.75Zm18.6-14.27s.66-.56 1.27-1.3c.7 3.34.27 6.93-1.46 10.16-.28-.93-.8-1.94-1.46-2.97a22.32 22.32 0 0 0 1.66-5.88Zm-8.24 14.27a22.07 22.07 0 0 0 4.27-4.38c1.22.06 2.36 0 3.3-.22a14.91 14.91 0 0 1-8.07 6.34c.34-.9.5-1.75.5-1.75Zm-5.18-25.66-4.12 2.45 1.26 3.91h5.72l1.26-3.91-4.12-2.45Zm-11.4 19.74 4.18 2.35 2.75-3.05-2.86-4.95-4.02.86-.06 4.79Zm22.79 0-.06-4.79-4.02-.86-2.86 4.95 2.75 3.05 4.18-2.35Z" style="fill:#00c1fa"/><path d="M106.67 109.1a304.9 304.9 0 0 0-3.72-10.89c5.04-5.53 35.28-40.74 24.54-68.91 10.57 10.67 8.19 28.85 3.59 41.95-4.79 13.14-13.43 26.48-24.4 37.84Zm30.89 20.82c-5.87 6.12-20.46 17.92-21.67 18.77a99.37 99.37 0 0 0 7.94 6.02 133.26 133.26 0 0 0 20.09-18.48 353.47 353.47 0 0 0-6.36-6.31Zm-29.65-16.74a380.9 380.9 0 0 1 3.13 11.56c-4.8-1.37-8.66-2.53-12.36-3.82a123.4 123.4 0 0 1-21.16 13.21l15.84 5.47c14.83-8.23 28.13-20.82 37.81-34.68 0 0 8.56-12.55 12.42-23.68 2.62-7.48 4.46-16.57 3.49-24.89-2.21-12.27-6.95-15.84-9.32-17.66 6.16 5.72 3.25 27.8-2.79 39.89-6.08 12.16-15.73 24.27-27.05 34.59Zm59.05-37.86c-.03 7.72-3.05 15.69-6.44 22.69 1.7 2.2 3.18 4.36 4.42 6.49 7.97-16.51 3.74-26.67 2.02-29.18ZM61.18 128.51l12.5 4.3a101.45 101.45 0 0 0 21.42-13.19 163.26 163.26 0 0 1-10.61-4.51 101.28 101.28 0 0 1-23.3 13.4Zm87.78-42.73c.86.77 5.44 5.18 6.75 6.59 6.39-16.61.78-28.86-1.27-30.56.72 8.05-2.02 16.51-5.48 23.98Zm-14.29 40.62-2.47-15.18a142.42 142.42 0 0 1-35.74 29.45c6.81 2.36 12.69 4.4 15.45 5.38a115.98 115.98 0 0 0 22.75-19.66Zm-42.62 34.73c4.48 2.93 12.94 4.24 18.8 1.23 6.03-3.84-.6-8.34-8.01-9.88-9.8-2.03-16.82 1.22-13.4 6.21.41.6 1.19 1.5 2.62 2.44m-1.84.4c-3.56-2.37-6.77-7.2-.23-10.08 10.41-3.43 28.39 3.2 24.99 9.22-.58 1.04-1.46 1.6-2.38 2.19h-.03v.02h-.03v.02h-.03c-7.04 3.65-17.06 2.13-22.3-1.36m5.48-3.86a4.94 4.94 0 0 0 5.06.49l1.35-.74-4.68-2.38-1.47.79c-.38.22-1.53.88-.26 1.84m-1.7.59c-2.35-1.57-.78-2.61-.02-3.11 1.09-.57 2.19-1.15 3.28-1.77 6.95 3.67 7.22 3.81 13.19 6.17l-1.38.81c-1.93-.78-4.52-1.82-6.42-2.68.86 1.4 1.99 3.27 2.9 4.64l-1.68.87c-.75-1.28-1.76-2.99-2.47-4.29-3.19 2.06-6.99-.36-7.42-.64" style="fill:url(#f2)"/><path d="M159.13 52.37C143.51 24.04 119.45 15 103.6 15c-11.92 0-25.97 5.78-36.84 13.17 9.54 4.38 21.86 15.96 22.02 16.11-7.94-3.05-17.83-6.72-33.23-7.87a135.1 135.1 0 0 0-19.77 20.38c.77 7.66 2.88 15.68 2.88 15.68-6.28-4.75-11.02-4.61-18 9.45-5.4 12.66-6.93 24.25-4.65 33.18 0 0 4.72 26.8 36.23 40.07-1.3-4.61-1.58-9.91-.93-15.73a87.96 87.96 0 0 1-15.63-9.87c.79-6.61 2.79-13.82 6-21.36 4.42-10.66 4.35-15.14 4.35-15.19.03.07 5.48 12.43 12.95 22.08 4.23-8.84 9.46-16.08 13.67-21.83l-3.77-6.75a143.73 143.73 0 0 1 18.19-18.75c2.05 1.07 4.79 2.47 6.84 3.58 8.68-7.27 19.25-14.05 30.56-18.29-7-11.49-16.02-19.27-16.02-19.27s27.7 2.74 42.02 15.69a25.8 25.8 0 0 1 8.65 2.89ZM28.58 107.52a70.1 70.1 0 0 0-2.74 12.52 55.65 55.65 0 0 1-6.19-8.84 69.17 69.17 0 0 1 2.65-12.1c1.77-5.31 3.35-5.91 5.86-2.23v-.05c2.14 3.07 1.81 6.14.42 10.7ZM61.69 72.2l-.05.05a221.85 221.85 0 0 1-7.77-18.1l.14-.14a194.51 194.51 0 0 1 18.56 6.98 144.44 144.44 0 0 0-10.88 11.22Zm54.84-47.38c-4.42.7-9.02 1.95-13.67 3.72a65.03 65.03 0 0 0-7.81-5.31 66.04 66.04 0 0 1 13.02-3.54c1.53-.19 6.23-.79 10.32 2.42v-.05c2.47 1.91.14 2.37-1.86 2.75Z" style="fill:url(#h)"/>'
        ));
    }

    /// @notice Transfer ownership to a new owner.
    /// @param newOwner The address to transfer ownership to.
    function transferOwnership(address newOwner) external onlyOwner {
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    /// @notice Write data to be accessed by a given file key.
    /// @param key The key to access the written data.
    /// @param data The data to be written.
    function writeFile(uint256 key, string memory data) external onlyOwner {
        files[key] = SSTORE2.write(bytes(data));
    }

    /// @notice Read data using a given file key.
    /// @param key The key to access the stored data.
    /// @return data The data stored at the given key.
    function readFile(uint256 key) external view returns (string memory data) {
        return string(SSTORE2.read(files[key]));
    }

    /// @notice Create or set a customization preset for renderers to use.
    /// @param id The ID of the customization preset.
    /// @param customizationData Data decoded by renderers used to render the SVG according to the preset.
    function createCustomizationPreset(uint256 id, bytes memory customizationData) external onlyOwner {
        customizationPresets[id] = customizationData;
    }

    /// @notice For crowdfund or party instances to set the customization preset they want to use.
    /// @param id The ID of the customization preset.
    function useCustomizationPreset(uint256 id) external {
        getPresetFor[msg.sender] = id;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8;

import "../vendor/solmate/ERC1155.sol";
import "../utils/EIP165.sol";

abstract contract ERC1155Receiver is EIP165, ERC1155TokenReceiverBase {
    /// @inheritdoc EIP165
    function supportsInterface(bytes4 interfaceId)
        public
        override
        virtual
        pure
        returns (bool)
    {
        return super.supportsInterface(interfaceId) ||
            interfaceId == type(ERC1155TokenReceiverBase).interfaceId;
    }

}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8;

import "./IERC721Receiver.sol";
import "../utils/EIP165.sol";
import "../vendor/solmate/ERC721.sol";

/// @notice Mixin for contracts that want to receive ERC721 tokens.
/// @dev Use this instead of solmate's ERC721TokenReceiver because the
///      compiler has issues when overriding EIP165/IERC721Receiver functions.
abstract contract ERC721Receiver is IERC721Receiver, EIP165, ERC721TokenReceiver {
    /// @inheritdoc IERC721Receiver
    function onERC721Received(address, address, uint256, bytes memory)
        public
        virtual
        override(IERC721Receiver, ERC721TokenReceiver)
        returns (bytes4)
    {
        return IERC721Receiver.onERC721Received.selector;
    }

    /// @inheritdoc EIP165
    function supportsInterface(bytes4 interfaceId)
        public
        pure
        virtual
        override
        returns (bool)
    {
        return EIP165.supportsInterface(interfaceId) ||
            interfaceId == type(IERC721Receiver).interfaceId;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8;

// Minimal ERC1155 interface.
interface IERC1155 {
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

    function setApprovalForAll(address operator, bool approved) external;
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
    function balanceOf(address owner, uint256 tokenId) external view returns (uint256);
    function isApprovedForAll(address owner, address spender) external view returns (bool);
    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory balances);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8;

// Minimal ERC20 interface.
interface IERC20 {
    event Transfer(address indexed owner, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 allowance);

    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function approve(address spender, uint256 allowance) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8;

// Minimal ERC721 interface.
interface IERC721 {
    event Transfer(address indexed owner, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed operator, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function transferFrom(address from, address to, uint256 tokenId) external;
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function approve(address operator, uint256 tokenId) external;
    function setApprovalForAll(address operator, bool isApproved) external;
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function getApproved(uint256 tokenId) external view returns (address);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function ownerOf(uint256 tokenId) external view returns (address);
    function balanceOf(address owner) external view returns (uint256);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8;

interface IERC721Receiver {

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes memory data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

abstract contract EIP165 {
    /// @notice Query if a contract implements an interface.
    /// @param interfaceId The interface identifier, as specified in ERC-165
    /// @return `true` if the contract implements `interfaceId` and
    ///         `interfaceId` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceId)
        public
        virtual
        pure
        returns (bool)
    {
        return interfaceId == this.supportsInterface.selector;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

// Base contract for all contracts intended to be delegatecalled into.
abstract contract Implementation {
    error OnlyDelegateCallError();
    error OnlyConstructorError();

    address public immutable IMPL;

    constructor() { IMPL = address(this); }

    // Reverts if the current function context is not inside of a delegatecall.
    modifier onlyDelegateCall() virtual {
        if (address(this) == IMPL) {
            revert OnlyDelegateCallError();
        }
        _;
    }

    // Reverts if the current function context is not inside of a constructor.
    modifier onlyConstructor() {
        uint256 codeSize;
        assembly { codeSize := extcodesize(address()) }
        if (codeSize != 0) {
            revert OnlyConstructorError();
        }
        _;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

library LibAddress {
    error EthTransferFailed(address receiver, bytes errData);

    // Transfer ETH with full gas stipend.
    function transferEth(address payable receiver, uint256 amount)
        internal
    {
        if (amount == 0) return;

        (bool s, bytes memory r) = receiver.call{value: amount}("");
        if (!s) {
            revert EthTransferFailed(receiver, r);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import "../tokens/IERC20.sol";

// Compatibility helpers for ERC20s.
library LibERC20Compat {
    error NotATokenError(IERC20 token);
    error TokenTransferFailedError(IERC20 token, address to, uint256 amount);

    // Perform an `IERC20.transfer()` handling non-compliant implementations.
    function compatTransfer(IERC20 token, address to, uint256 amount)
        internal
    {
        (bool s, bytes memory r) =
            address(token).call(abi.encodeCall(IERC20.transfer, (to, amount)));
        if (s) {
            if (r.length == 0) {
                uint256 cs;
                assembly { cs := extcodesize(token) }
                if (cs == 0) {
                    revert NotATokenError(token);
                }
                return;
            }
            if (abi.decode(r, (bool))) {
                return;
            }
        }
        revert TokenTransferFailedError(token, to, amount);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

library LibRawResult {
    // Revert with the data in `b`.
    function rawRevert(bytes memory b)
        internal
        pure
    {
        assembly { revert(add(b, 32), mload(b)) }
    }

    // Return with the data in `b`.
    function rawReturn(bytes memory b)
        internal
        pure
    {
        assembly { return(add(b, 32), mload(b)) }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

library LibSafeCast {
    error Uint256ToUint96CastOutOfRange(uint256 v);
    error Uint256ToInt192CastOutOfRange(uint256 v);
    error Int192ToUint96CastOutOfRange(int192 i192);
    error Uint256ToInt128CastOutOfRangeError(uint256 u256);
    error Uint256ToUint128CastOutOfRangeError(uint256 u256);
    error Uint256ToUint40CastOutOfRangeError(uint256 u256);

    function safeCastUint256ToUint96(uint256 v) internal pure returns (uint96) {
        if (v > uint256(type(uint96).max)) {
            revert Uint256ToUint96CastOutOfRange(v);
        }
        return uint96(v);
    }

    function safeCastUint256ToUint128(uint256 v) internal pure returns (uint128) {
        if (v > uint256(type(uint128).max)) {
            revert Uint256ToUint128CastOutOfRangeError(v);
        }
        return uint128(v);
    }

    function safeCastUint256ToInt192(uint256 v) internal pure returns (int192) {
        if (v > uint256(uint192(type(int192).max))) {
            revert Uint256ToInt192CastOutOfRange(v);
        }
        return int192(uint192(v));
    }

    function safeCastUint96ToInt192(uint96 v) internal pure returns (int192) {
        return int192(uint192(v));
    }

    function safeCastInt192ToUint96(int192 i192) internal pure returns (uint96) {
        if (i192 < 0 || i192 > int192(uint192(type(uint96).max))) {
            revert Int192ToUint96CastOutOfRange(i192);
        }
        return uint96(uint192(i192));
    }

    function safeCastUint256ToInt128(uint256 x)
        internal
        pure
        returns (int128)
    {
        if (x > uint256(uint128(type(int128).max))) {
            revert Uint256ToInt128CastOutOfRangeError(x);
        }
        return int128(uint128(x));
    }

    function safeCastUint256ToUint40(uint256 x)
        internal
        pure
        returns (uint40)
    {
        if (x > uint256(type(uint40).max)) {
            revert Uint256ToUint40CastOutOfRangeError(x);
        }
        return uint40(x);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import "../tokens/IERC721.sol";
import "./LibRawResult.sol";

library LibSafeERC721 {
    using LibRawResult for bytes;

    // Call `IERC721.ownerOf()` without reverting and return `address(0)` if:
    // - `tokenID` does not exist.
    // - `token` is an EOA
    // - `token` is an empty contract
    // - `token` is a "bad" implementation of ERC721 that returns nothing for
    //   `ownerOf()`
    function safeOwnerOf(IERC721 token, uint256 tokenId)
        internal
        view
        returns (address owner)
    {
        (bool s, bytes memory r) = address(token).staticcall(
            abi.encodeCall(token.ownerOf, (tokenId))
        );

        if (!s || r.length < 32) {
            return address(0);
        }

        return abi.decode(r, (address));
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import "../utils/LibRawResult.sol";

abstract contract Multicall {
    using LibRawResult for bytes;

    /// @notice Perform multiple delegatecalls on ourselves.
    function multicall(bytes[] calldata multicallData) external {
        for (uint256 i; i < multicallData.length; ++i) {
            (bool s, bytes memory r) = address(this).delegatecall(multicallData[i]);
            if (!s) {
                r.rawRevert();
            }
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import "./LibRawResult.sol";
import "./Implementation.sol";

/// @notice Base class for all proxy contracts.
contract Proxy {
    using LibRawResult for bytes;

    /// @notice The address of the implementation contract used by this proxy.
    Implementation public immutable IMPL;

    // Made `payable` to allow initialized crowdfunds to receive ETH as an
    // initial contribution.
    constructor(Implementation impl, bytes memory initCallData) payable {
        IMPL = impl;
        (bool s, bytes memory r) = address(impl).delegatecall(initCallData);
        if (!s) {
            r.rawRevert();
        }
    }

    // Forward all calls to the implementation.
    fallback() external payable {
        Implementation impl = IMPL;
        assembly {
            calldatacopy(0x00, 0x00, calldatasize())
            let s := delegatecall(gas(), impl, 0x00, calldatasize(), 0x00, 0)
            returndatacopy(0x00, 0x00, returndatasize())
            if iszero(s) {
                revert(0x00, returndatasize())
            }
            return(0x00, returndatasize())
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import "./LibRawResult.sol";

interface IReadOnlyDelegateCall {
    // Marked `view` so that `_readOnlyDelegateCall` can be `view` as well.
    function delegateCallAndRevert(address impl, bytes memory callData)
        external
        view;
}

// Inherited by contracts to perform read-only delegate calls.
abstract contract ReadOnlyDelegateCall {
    using LibRawResult for bytes;

    // Delegatecall into implement and revert with the raw result.
    function delegateCallAndRevert(address impl, bytes memory callData) external {
        // Attempt to gate to only `_readOnlyDelegateCall()` invocations.
        require(msg.sender == address(this));
        (bool s, bytes memory r) = impl.delegatecall(callData);
        // Revert with success status and return data.
        abi.encode(s, r).rawRevert();
    }

    // Perform a `delegateCallAndRevert()` then return the raw result data.
    function _readOnlyDelegateCall(address impl, bytes memory callData) internal view {
        try IReadOnlyDelegateCall(address(this)).delegateCallAndRevert(impl, callData) {
            // Should never happen.
            assert(false);
        }
        catch (bytes memory r) {
            (bool success, bytes memory resultData) = abi.decode(r, (bool, bytes));
            if (!success) {
                resultData.rawRevert();
            }
            resultData.rawReturn();
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
// Based on solmate commit 1681dc505f4897ef636f0435d01b1aa027fdafaf (v6.4.0)
//  @ https://github.com/Rari-Capital/solmate/blob/1681dc505f4897ef636f0435d01b1aa027fdafaf/src/tokens/ERC1155.sol
// Only modified to inherit IERC1155 and rename ERC1155TokenReceiver -> ERC1155TokenReceiverBase.
pragma solidity ^0.8;

import "../../tokens/IERC1155.sol";

/// @notice Minimalist and gas efficient standard ERC1155 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155 is IERC1155 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

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
                : ERC1155TokenReceiverBase(to).onERC1155Received(msg.sender, from, id, amount, data) ==
                    ERC1155TokenReceiverBase.onERC1155Received.selector,
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

        for (uint256 i; i < ids.length; ) {
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
                : ERC1155TokenReceiverBase(to).onERC1155BatchReceived(msg.sender, from, ids, amounts, data) ==
                    ERC1155TokenReceiverBase.onERC1155BatchReceived.selector,
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
            for (uint256 i; i < owners.length; ++i) {
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
                : ERC1155TokenReceiverBase(to).onERC1155Received(msg.sender, address(0), id, amount, data) ==
                    ERC1155TokenReceiverBase.onERC1155Received.selector,
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

        for (uint256 i; i < idsLength; ) {
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
                : ERC1155TokenReceiverBase(to).onERC1155BatchReceived(msg.sender, address(0), ids, amounts, data) ==
                    ERC1155TokenReceiverBase.onERC1155BatchReceived.selector,
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

        for (uint256 i; i < idsLength; ) {
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
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155TokenReceiverBase {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiverBase.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiverBase.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
// Based on solmate commit 1681dc505f4897ef636f0435d01b1aa027fdafaf (v6.4.0)
//  @ https://github.com/Rari-Capital/solmate/blob/1681dc505f4897ef636f0435d01b1aa027fdafaf/src/tokens/ERC1155.sol
// Only modified to inherit IERC721 and EIP165.
pragma solidity >=0.8.0;

// NOTE: Only modified to inherit IERC20 and EIP165
import "../../tokens/IERC721.sol";
import "../../utils/EIP165.sol";


/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721 is IERC721, EIP165 {

    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public /* view */ virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) internal _ownerOf;

    mapping(address => uint256) internal _balanceOf;

    function ownerOf(uint256 id) public view virtual returns (address owner) {
        require((owner = _ownerOf[id]) != address(0), "NOT_MINTED");
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "ZERO_ADDRESS");

        return _balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = _ownerOf[id];

        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        require(from == _ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[id],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[from]--;

            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public pure virtual override returns (bool) {
        // NOTE: modified from original to call super.
        return super.supportsInterface(interfaceId) ||
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(_ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = _ownerOf[id];

        require(owner != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            _balanceOf[owner]--;
        }

        delete _ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
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

/// @notice Read and write to persistent storage at a fraction of the cost.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SSTORE2.sol)
/// @author Modified from 0xSequence (https://github.com/0xSequence/sstore2/blob/master/contracts/SSTORE2.sol)
library SSTORE2 {
    uint256 internal constant DATA_OFFSET = 1; // We skip the first byte as it's a STOP opcode to ensure the contract can't be called.

    /*//////////////////////////////////////////////////////////////
                               WRITE LOGIC
    //////////////////////////////////////////////////////////////*/

    function write(bytes memory data) internal returns (address pointer) {
        // Prefix the bytecode with a STOP opcode to ensure it cannot be called.
        bytes memory runtimeCode = abi.encodePacked(hex"00", data);

        bytes memory creationCode = abi.encodePacked(
            //---------------------------------------------------------------------------------------------------------------//
            // Opcode  | Opcode + Arguments  | Description  | Stack View                                                     //
            //---------------------------------------------------------------------------------------------------------------//
            // 0x60    |  0x600B             | PUSH1 11     | codeOffset                                                     //
            // 0x59    |  0x59               | MSIZE        | 0 codeOffset                                                   //
            // 0x81    |  0x81               | DUP2         | codeOffset 0 codeOffset                                        //
            // 0x38    |  0x38               | CODESIZE     | codeSize codeOffset 0 codeOffset                               //
            // 0x03    |  0x03               | SUB          | (codeSize - codeOffset) 0 codeOffset                           //
            // 0x80    |  0x80               | DUP          | (codeSize - codeOffset) (codeSize - codeOffset) 0 codeOffset   //
            // 0x92    |  0x92               | SWAP3        | codeOffset (codeSize - codeOffset) 0 (codeSize - codeOffset)   //
            // 0x59    |  0x59               | MSIZE        | 0 codeOffset (codeSize - codeOffset) 0 (codeSize - codeOffset) //
            // 0x39    |  0x39               | CODECOPY     | 0 (codeSize - codeOffset)                                      //
            // 0xf3    |  0xf3               | RETURN       |                                                                //
            //---------------------------------------------------------------------------------------------------------------//
            hex"60_0B_59_81_38_03_80_92_59_39_F3", // Returns all code in the contract except for the first 11 (0B in hex) bytes.
            runtimeCode // The bytecode we want the contract to have after deployment. Capped at 1 byte less than the code size limit.
        );

        assembly {
            // Deploy a new contract with the generated creation code.
            // We start 32 bytes into the code to avoid copying the byte length.
            pointer := create(0, add(creationCode, 32), mload(creationCode))
        }

        require(pointer != address(0), "DEPLOYMENT_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                               READ LOGIC
    //////////////////////////////////////////////////////////////*/

    function read(address pointer) internal view returns (bytes memory) {
        return readBytecode(pointer, DATA_OFFSET, pointer.code.length - DATA_OFFSET);
    }

    function read(address pointer, uint256 start) internal view returns (bytes memory) {
        start += DATA_OFFSET;

        return readBytecode(pointer, start, pointer.code.length - start);
    }

    function read(
        address pointer,
        uint256 start,
        uint256 end
    ) internal view returns (bytes memory) {
        start += DATA_OFFSET;
        end += DATA_OFFSET;

        require(pointer.code.length >= end, "OUT_OF_BOUNDS");

        return readBytecode(pointer, start, end - start);
    }

    /*//////////////////////////////////////////////////////////////
                          INTERNAL HELPER LOGIC
    //////////////////////////////////////////////////////////////*/

    function readBytecode(
        address pointer,
        uint256 start,
        uint256 size
    ) private view returns (bytes memory data) {
        assembly {
            // Get a pointer to some free memory.
            data := mload(0x40)

            // Update the free memory pointer to prevent overriding our data.
            // We use and(x, not(31)) as a cheaper equivalent to sub(x, mod(x, 32)).
            // Adding 31 to size and running the result through the logic above ensures
            // the memory pointer remains word-aligned, following the Solidity convention.
            mstore(0x40, add(data, and(add(add(size, 32), 31), not(31))))

            // Store the size of the data in the first 32 byte chunk of free memory.
            mstore(data, size)

            // Copy the code into memory right after the 32 bytes we used to store the size.
            extcodecopy(pointer, add(data, 32), start, size)
        }
    }
}