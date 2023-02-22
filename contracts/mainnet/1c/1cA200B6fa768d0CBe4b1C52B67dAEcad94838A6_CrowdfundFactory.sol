// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import "./AuctionCrowdfundBase.sol";

/// @notice A crowdfund that can repeatedly bid on an auction for a specific NFT
///         (i.e. with a known token ID) until it wins.
contract AuctionCrowdfund is AuctionCrowdfundBase {
    using LibSafeERC721 for IERC721;
    using LibSafeCast for uint256;
    using LibRawResult for bytes;

    // Set the `Globals` contract.
    constructor(IGlobals globals) AuctionCrowdfundBase(globals) {}

    /// @notice Initializer to be delegatecalled by `Proxy` constructor. Will
    ///         revert if called outside the constructor.
    /// @param opts Options used to initialize the crowdfund. These are fixed
    ///             and cannot be changed later.
    function initialize(AuctionCrowdfundOptions memory opts) external payable onlyConstructor {
        AuctionCrowdfundBase._initialize(opts);
    }

    /// @notice Calls `finalize()` on the market adapter, which will claim the NFT
    ///         (if necessary) if we won, or recover our bid (if necessary)
    ///         if we lost. If we won, a governance party will also be created.
    /// @param governanceOpts The options used to initialize governance in the
    ///                       `Party` instance created if the crowdfund wins.
    /// @return party_ Address of the `Party` instance created if successful.
    function finalize(
        FixedGovernanceOpts memory governanceOpts
    ) external onlyDelegateCall returns (Party party_) {
        // Check that the auction is still active and has not passed the `expiry` time.
        CrowdfundLifecycle lc = getCrowdfundLifecycle();
        if (lc != CrowdfundLifecycle.Active && lc != CrowdfundLifecycle.Expired) {
            revert WrongLifecycleError(lc);
        }

        // Finalize the auction if it is not already finalized.
        uint96 lastBid_ = lastBid;
        _finalizeAuction(lc, market, auctionId, lastBid_);

        IERC721 nftContract_ = nftContract;
        uint256 nftTokenId_ = nftTokenId;
        // Are we now in possession of the NFT?
        if (nftContract_.safeOwnerOf(nftTokenId_) == address(this) && lastBid_ != 0) {
            // If we placed a bid before then consider it won for that price.
            // Create a governance party around the NFT.
            party_ = _createParty(governanceOpts, false, nftContract_, nftTokenId_);
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

import "../market-wrapper/IMarketWrapper.sol";
import "./Crowdfund.sol";

abstract contract AuctionCrowdfundBase is Crowdfund {
    using LibSafeERC721 for IERC721;
    using LibSafeCast for uint256;
    using LibRawResult for bytes;

    enum AuctionCrowdfundStatus {
        // The crowdfund has been created and contributions can be made and
        // acquisition functions may be called.
        Active,
        // A temporary state set by the contract during complex operations to
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
        // Minimum amount of ETH that can be contributed to this crowdfund per address.
        uint96 minContribution;
        // Maximum amount of ETH that can be contributed to this crowdfund per address.
        uint96 maxContribution;
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
    AuctionCrowdfundStatus internal _bidStatus;

    // Set the `Globals` contract.
    constructor(IGlobals globals) Crowdfund(globals) {}

    /// @notice Initializer to be delegatecalled by `Proxy` constructor. Will
    ///         revert if called outside the constructor.
    /// @param opts Options used to initialize the crowdfund. These are fixed
    ///             and cannot be changed later.
    function _initialize(AuctionCrowdfundOptions memory opts) internal {
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
        Crowdfund._initialize(
            CrowdfundOptions({
                name: opts.name,
                symbol: opts.symbol,
                customizationPresetId: opts.customizationPresetId,
                splitRecipient: opts.splitRecipient,
                splitBps: opts.splitBps,
                initialContributor: opts.initialContributor,
                initialDelegate: opts.initialDelegate,
                minContribution: opts.minContribution,
                maxContribution: opts.maxContribution,
                gateKeeper: opts.gateKeeper,
                gateKeeperId: opts.gateKeeperId,
                governanceOpts: opts.governanceOpts
            })
        );

        // Check that the auction can be bid on and is valid.
        _validateAuction(opts.market, opts.auctionId, opts.nftContract, opts.nftTokenId);

        // Check that the minimum bid is less than the maximum bid.
        uint256 minimumBid = opts.market.getMinimumBid(opts.auctionId);
        if (minimumBid > opts.maximumBid) {
            revert MinimumBidExceedsMaximumBidError(minimumBid, opts.maximumBid);
        }
    }

    /// @notice Accept naked ETH, e.g., if an auction needs to return ETH to us.
    receive() external payable {}

    /// @notice Place a bid on the NFT using the funds in this crowdfund,
    ///         placing the minimum possible bid to be the highest bidder, up to
    ///         `maximumBid`. Only callable by contributors if `onlyHostCanBid`
    ///         is not enabled.
    function bid() external {
        if (onlyHostCanBid) revert OnlyPartyHostError();

        // Bid with the minimum amount to be the highest bidder.
        _bid(type(uint96).max);
    }

    /// @notice Place a bid on the NFT using the funds in this crowdfund,
    ///         placing the minimum possible bid to be the highest bidder, up to
    ///         `maximumBid`.
    /// @param governanceOpts The governance options the crowdfund was created
    ///                       with. Only used for crowdfunds where only a host
    ///                       can bid to verify the caller is a host.
    /// @param hostIndex If the caller is a host, this is the index of the caller in the
    ///                  `governanceOpts.hosts` array. Only used for crowdfunds where only
    ///                  a host can bid to verify the caller is a host.
    function bid(FixedGovernanceOpts memory governanceOpts, uint256 hostIndex) external {
        // This function can be optionally restricted in different ways.
        if (onlyHostCanBid) {
            // Only a host can call this function.
            _assertIsHost(msg.sender, governanceOpts, hostIndex);
        } else if (address(gateKeeper) != address(0)) {
            // `onlyHostCanBid` is false and we are using a gatekeeper.
            // Only a contributor can call this function.
            _assertIsContributor(msg.sender);
        }

        // Bid with the minimum amount to be the highest bidder.
        _bid(type(uint96).max);
    }

    /// @notice Place a bid on the NFT using the funds in this crowdfund,
    ///         placing a bid, up to `maximumBid`. Only host can call this.
    /// @param amount The amount to bid.
    /// @param governanceOpts The governance options the crowdfund was created
    ///                       with. Used to verify the caller is a host.
    /// @param hostIndex If the caller is a host, this is the index of the caller in the
    ///                  `governanceOpts.hosts` array. Used to verify the caller is a host.
    function bid(
        uint96 amount,
        FixedGovernanceOpts memory governanceOpts,
        uint256 hostIndex
    ) external {
        // Only a host can specify a custom bid amount.
        _assertIsHost(msg.sender, governanceOpts, hostIndex);

        _bid(amount);
    }

    function _bid(uint96 amount) private onlyDelegateCall {
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

        if (amount == type(uint96).max) {
            // Get the minimum necessary bid to be the highest bidder.
            amount = market_.getMinimumBid(auctionId_).safeCastUint256ToUint96();
        }

        // Prevent unaccounted ETH from being used to inflate the bid and
        // create "ghost shares" in voting power.
        uint96 totalContributions_ = totalContributions;
        if (amount > totalContributions_) {
            revert ExceedsTotalContributionsError(amount, totalContributions_);
        }
        // Make sure the bid is less than the maximum bid.
        uint96 maximumBid_ = maximumBid;
        if (amount > maximumBid_) {
            revert ExceedsMaximumBidError(amount, maximumBid_);
        }
        lastBid = amount;

        // No need to check that we have `amount` since this will attempt to
        // transfer `amount` ETH to the auction platform.
        (bool s, bytes memory r) = address(market_).delegatecall(
            abi.encodeCall(IMarketWrapper.bid, (auctionId_, amount))
        );
        if (!s) {
            r.rawRevert();
        }
        emit Bid(amount);

        _bidStatus = AuctionCrowdfundStatus.Active;
    }

    /// @inheritdoc Crowdfund
    function getCrowdfundLifecycle() public view override returns (CrowdfundLifecycle) {
        // Do not rely on `market.isFinalized()` in case `auctionId` gets reused.
        AuctionCrowdfundStatus status = _bidStatus;
        if (status == AuctionCrowdfundStatus.Busy) {
            // In the midst of finalizing/bidding (trying to reenter).
            return CrowdfundLifecycle.Busy;
        }
        if (status == AuctionCrowdfundStatus.Finalized) {
            return
                address(party) != address(0) // If we're fully finalized and we have a party instance then we won.
                    ? CrowdfundLifecycle.Won // Otherwise we lost.
                    : CrowdfundLifecycle.Lost;
        }
        if (block.timestamp >= expiry) {
            // Expired. `finalize()` needs to be called.
            return CrowdfundLifecycle.Expired;
        }
        return CrowdfundLifecycle.Active;
    }

    function _getFinalPrice() internal view override returns (uint256 price) {
        return lastBid;
    }

    function _validateAuction(
        IMarketWrapper market_,
        uint256 auctionId_,
        IERC721 nftContract_,
        uint256 nftTokenId_
    ) internal view {
        if (!market_.auctionIdMatchesToken(auctionId_, address(nftContract_), nftTokenId_)) {
            revert InvalidAuctionIdError();
        }
    }

    function _finalizeAuction(
        CrowdfundLifecycle lc,
        IMarketWrapper market_,
        uint256 auctionId_,
        uint96 lastBid_
    ) internal {
        // Mark as busy to prevent `burn()`, `bid()`, and `contribute()`
        // getting called because this will result in a `CrowdfundLifecycle.Busy`.
        _bidStatus = AuctionCrowdfundStatus.Busy;

        // If we've bid before or the CF is not expired, finalize the auction.
        if (lastBid_ != 0 || lc == CrowdfundLifecycle.Active) {
            if (!market_.isFinalized(auctionId_)) {
                // If the crowdfund has expired and we are not the highest
                // bidder, skip finalization because there is no chance of
                // winning the auction.
                if (
                    lc == CrowdfundLifecycle.Expired &&
                    market_.getCurrentHighestBidder(auctionId_) != address(this)
                ) return;

                (bool s, bytes memory r) = address(market_).call(
                    abi.encodeCall(IMarketWrapper.finalize, auctionId_)
                );
                if (!s) {
                    r.rawRevert();
                }
            }
        }
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
    using LibRawResult for bytes;

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
        // How long this crowdfund has to buy the NFT, in seconds.
        uint40 duration;
        // Maximum amount this crowdfund will pay for the NFT.
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
        // Minimum amount of ETH that can be contributed to this crowdfund per address.
        uint96 minContribution;
        // Maximum amount of ETH that can be contributed to this crowdfund per address.
        uint96 maxContribution;
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
    function initialize(BuyCrowdfundOptions memory opts) external payable onlyConstructor {
        if (opts.onlyHostCanBuy && opts.governanceOpts.hosts.length == 0) {
            revert MissingHostsError();
        }
        BuyCrowdfundBase._initialize(
            BuyCrowdfundBaseOptions({
                name: opts.name,
                symbol: opts.symbol,
                customizationPresetId: opts.customizationPresetId,
                duration: opts.duration,
                maximumPrice: opts.maximumPrice,
                splitRecipient: opts.splitRecipient,
                splitBps: opts.splitBps,
                initialContributor: opts.initialContributor,
                initialDelegate: opts.initialDelegate,
                minContribution: opts.minContribution,
                maxContribution: opts.maxContribution,
                gateKeeper: opts.gateKeeper,
                gateKeeperId: opts.gateKeeperId,
                governanceOpts: opts.governanceOpts
            })
        );
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
    ) external onlyDelegateCall returns (Party party_) {
        // This function can be optionally restricted in different ways.
        bool isValidatedGovernanceOpts;
        if (onlyHostCanBuy) {
            // Only a host can call this function.
            _assertIsHost(msg.sender, governanceOpts, hostIndex);
            // If _assertIsHost() succeeded, the governance opts were validated.
            isValidatedGovernanceOpts = true;
        } else if (address(gateKeeper) != address(0)) {
            // `onlyHostCanBuy` is false and we are using a gatekeeper.
            // Only a contributor can call this function.
            _assertIsContributor(msg.sender);
        }
        {
            // Ensure that the crowdfund is still active.
            CrowdfundLifecycle lc = getCrowdfundLifecycle();
            if (lc != CrowdfundLifecycle.Active) {
                revert WrongLifecycleError(lc);
            }
        }

        // Temporarily set to non-zero as a reentrancy guard.
        settledPrice = type(uint96).max;

        // Buy the NFT and check NFT is owned by the crowdfund.
        (bool success, bytes memory revertData) = _buy(
            nftContract,
            nftTokenId,
            callTarget,
            callValue,
            callData
        );

        if (!success) {
            if (revertData.length > 0) {
                revertData.rawRevert();
            } else {
                revert FailedToBuyNFTError(nftContract, nftTokenId);
            }
        }

        return
            _finalize(
                nftContract,
                nftTokenId,
                callValue,
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

    struct BuyCrowdfundBaseOptions {
        // The name of the crowdfund.
        // This will also carry over to the governance party.
        string name;
        // The token symbol for both the crowdfund and the governance NFTs.
        string symbol;
        // Customization preset ID to use for the crowdfund and governance NFTs.
        uint256 customizationPresetId;
        // How long this crowdfund has to buy the NFT, in seconds.
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
        // Minimum amount of ETH that can be contributed to this crowdfund per address.
        uint96 minContribution;
        // Maximum amount of ETH that can be contributed to this crowdfund per address.
        uint96 maxContribution;
        // The gatekeeper contract to use (if non-null) to restrict who can
        // contribute to this crowdfund.
        IGateKeeper gateKeeper;
        // The gatekeeper contract to use (if non-null).
        bytes12 gateKeeperId;
        // Governance options.
        FixedGovernanceOpts governanceOpts;
    }

    event Won(Party party, IERC721[] tokens, uint256[] tokenIds, uint256 settledPrice);
    event Lost();

    error MaximumPriceError(uint96 callValue, uint96 maximumPrice);
    error NoContributionsError();
    error CallProhibitedError(address target, bytes data);
    error FailedToBuyNFTError(IERC721 token, uint256 tokenId);

    /// @notice When this crowdfund expires.
    uint40 public expiry;
    /// @notice Maximum amount this crowdfund will pay for the NFT.
    uint96 public maximumPrice;
    /// @notice What the NFT was actually bought for.
    uint96 public settledPrice;

    // Set the `Globals` contract.
    constructor(IGlobals globals) Crowdfund(globals) {}

    // Initialize storage for proxy contracts.
    function _initialize(BuyCrowdfundBaseOptions memory opts) internal {
        expiry = uint40(opts.duration + block.timestamp);
        maximumPrice = opts.maximumPrice;
        Crowdfund._initialize(
            CrowdfundOptions({
                name: opts.name,
                symbol: opts.symbol,
                customizationPresetId: opts.customizationPresetId,
                splitRecipient: opts.splitRecipient,
                splitBps: opts.splitBps,
                initialContributor: opts.initialContributor,
                initialDelegate: opts.initialDelegate,
                minContribution: opts.minContribution,
                maxContribution: opts.maxContribution,
                gateKeeper: opts.gateKeeper,
                gateKeeperId: opts.gateKeeperId,
                governanceOpts: opts.governanceOpts
            })
        );
    }

    // Execute arbitrary calldata to perform a buy, creating a party
    // if it successfully buys the NFT.
    function _buy(
        IERC721 token,
        uint256 tokenId,
        address payable callTarget,
        uint96 callValue,
        bytes memory callData
    ) internal returns (bool success, bytes memory revertData) {
        // Check that the call is not prohibited.
        if (!_isCallAllowed(callTarget, callData, token)) {
            revert CallProhibitedError(callTarget, callData);
        }
        // Check that the call value is under the maximum price.
        {
            uint96 maximumPrice_ = maximumPrice;
            if (callValue > maximumPrice_) {
                revert MaximumPriceError(callValue, maximumPrice_);
            }
        }
        // Execute the call to buy the NFT.
        (bool s, bytes memory r) = callTarget.call{ value: callValue }(callData);
        if (!s) {
            return (false, r);
        }
        // Return whether the NFT was successfully bought.
        return (token.safeOwnerOf(tokenId) == address(this), "");
    }

    function _finalize(
        IERC721[] memory tokens,
        uint256[] memory tokenIds,
        uint96 totalEthUsed,
        FixedGovernanceOpts memory governanceOpts,
        bool isValidatedGovernanceOpts
    ) internal returns (Party party_) {
        {
            // Prevent unaccounted ETH from being used to inflate the price and
            // create "ghost shares" in voting power.
            uint96 totalContributions_ = totalContributions;
            if (totalEthUsed > totalContributions_) {
                revert ExceedsTotalContributionsError(totalEthUsed, totalContributions_);
            }
        }
        if (totalEthUsed != 0) {
            // Create a party around the newly bought NFTs and finalize a win.
            settledPrice = totalEthUsed;
            party_ = _createParty(governanceOpts, isValidatedGovernanceOpts, tokens, tokenIds);
            emit Won(party_, tokens, tokenIds, totalEthUsed);
        } else {
            // If all NFTs were purchased for free or were all "gifted" to us,
            // refund all contributors by finalizing a loss.
            settledPrice = 0;
            expiry = uint40(block.timestamp);
            emit Lost();
        }
    }

    function _finalize(
        IERC721 token,
        uint256 tokenId,
        uint96 totalEthUsed,
        FixedGovernanceOpts memory governanceOpts,
        bool isValidatedGovernanceOpts
    ) internal returns (Party party_) {
        IERC721[] memory tokens = new IERC721[](1);
        tokens[0] = token;
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = tokenId;
        return _finalize(tokens, tokenIds, totalEthUsed, governanceOpts, isValidatedGovernanceOpts);
    }

    /// @inheritdoc Crowdfund
    function getCrowdfundLifecycle() public view override returns (CrowdfundLifecycle) {
        // If there is a settled price then we tried to buy the NFT.
        if (settledPrice != 0) {
            return
                address(party) != address(0)
                    ? CrowdfundLifecycle.Won // If we have a party, then we succeeded buying the NFT.
                    : CrowdfundLifecycle.Busy; // Otherwise we're in the middle of the `buy()`.
        }
        if (block.timestamp >= expiry) {
            // Expired, but nothing to do so skip straight to lost, or NFT was
            // acquired for free so refund contributors and trigger lost.
            return CrowdfundLifecycle.Lost;
        }
        return CrowdfundLifecycle.Active;
    }

    function _getFinalPrice() internal view override returns (uint256) {
        return settledPrice;
    }

    function _isCallAllowed(
        address payable callTarget,
        bytes memory callData,
        IERC721 token
    ) private view returns (bool isAllowed) {
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

// SPDX-License-Identifier: Beta Software
// http://ipfs.io/ipfs/QmbGX2MFCaMAsMNMugRFND6DtYygRkwkvrqEyTKhTdBLo5
pragma solidity 0.8.17;

import "../tokens/IERC721.sol";
import "../party/Party.sol";
import "../utils/Implementation.sol";
import "../utils/LibSafeERC721.sol";
import "../globals/IGlobals.sol";
import "../gatekeepers/IGateKeeper.sol";
import "openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "./BuyCrowdfundBase.sol";

contract CollectionBatchBuyCrowdfund is BuyCrowdfundBase {
    using LibSafeERC721 for IERC721;
    using LibSafeCast for uint256;
    using LibRawResult for bytes;

    struct CollectionBatchBuyCrowdfundOptions {
        // The name of the crowdfund.
        // This will also carry over to the governance party.
        string name;
        // The token symbol for both the crowdfund and the governance NFTs.
        string symbol;
        // Customization preset ID to use for the crowdfund and governance NFTs.
        uint256 customizationPresetId;
        // The ERC721 contract of the NFTs being bought.
        IERC721 nftContract;
        // The merkle root of the token IDs that can be bought. If null, any
        // token ID in the collection can be bought.
        bytes32 nftTokenIdsMerkleRoot;
        // How long this crowdfund has to buy the NFTs, in seconds.
        uint40 duration;
        // Maximum amount this crowdfund will pay for an NFT.
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
        // Minimum amount of ETH that can be contributed to this crowdfund per address.
        uint96 minContribution;
        // Maximum amount of ETH that can be contributed to this crowdfund per address.
        uint96 maxContribution;
        // The gatekeeper contract to use (if non-null) to restrict who can
        // contribute to this crowdfund.
        IGateKeeper gateKeeper;
        // The gate ID within the gateKeeper contract to use.
        bytes12 gateKeeperId;
        // Fixed governance options (i.e. cannot be changed) that the governance
        // `Party` will be created with if the crowdfund succeeds.
        FixedGovernanceOpts governanceOpts;
    }

    struct BatchBuyArgs {
        uint256[] tokenIds;
        address payable[] callTargets;
        uint96[] callValues;
        bytes[] callDatas;
        bytes32[][] proofs;
        uint256 minTokensBought;
        uint256 minTotalEthUsed;
        FixedGovernanceOpts governanceOpts;
        uint256 hostIndex;
    }

    error NothingBoughtError();
    error InvalidMinTokensBoughtError(uint256 minTokensBought);
    error InvalidTokenIdError();
    error ContributionsSpentForFailedBuyError();
    error NotEnoughTokensBoughtError(uint256 tokensBought, uint256 minTokensBought);
    error NotEnoughEthUsedError(uint256 ethUsed, uint256 minTotalEthUsed);
    error MismatchedCallArgLengthsError();

    /// @notice The contract of NFTs to buy.
    IERC721 public nftContract;
    /// @notice The merkle root of the token IDs that can be bought. If null,
    ///         allow any token ID in the collection can be bought.
    bytes32 public nftTokenIdsMerkleRoot;

    // Set the `Globals` contract.
    constructor(IGlobals globals) BuyCrowdfundBase(globals) {}

    /// @notice Initializer to be delegatecalled by `Proxy` constructor. Will
    ///         revert if called outside the constructor.
    /// @param opts Options used to initialize the crowdfund. These are fixed
    ///             and cannot be changed later.
    function initialize(
        CollectionBatchBuyCrowdfundOptions memory opts
    ) external payable onlyConstructor {
        if (opts.governanceOpts.hosts.length == 0) {
            revert MissingHostsError();
        }
        BuyCrowdfundBase._initialize(
            BuyCrowdfundBaseOptions({
                name: opts.name,
                symbol: opts.symbol,
                customizationPresetId: opts.customizationPresetId,
                duration: opts.duration,
                maximumPrice: opts.maximumPrice,
                splitRecipient: opts.splitRecipient,
                splitBps: opts.splitBps,
                initialContributor: opts.initialContributor,
                initialDelegate: opts.initialDelegate,
                minContribution: opts.minContribution,
                maxContribution: opts.maxContribution,
                gateKeeper: opts.gateKeeper,
                gateKeeperId: opts.gateKeeperId,
                governanceOpts: opts.governanceOpts
            })
        );
        nftContract = opts.nftContract;
        nftTokenIdsMerkleRoot = opts.nftTokenIdsMerkleRoot;
    }

    /// @notice Execute arbitrary calldata to perform a batch buy, creating a party
    ///         if it successfully buys the NFT. Only a host may call this.
    /// @param args Arguments for the batch buy.
    /// @return party_ Address of the `Party` instance created after its bought.
    function batchBuy(BatchBuyArgs memory args) external onlyDelegateCall returns (Party party_) {
        // This function is restricted to hosts.
        _assertIsHost(msg.sender, args.governanceOpts, args.hostIndex);

        {
            // Ensure that the crowdfund is still active.
            CrowdfundLifecycle lc = getCrowdfundLifecycle();
            if (lc != CrowdfundLifecycle.Active) {
                revert WrongLifecycleError(lc);
            }
        }

        if (args.minTokensBought == 0) {
            // Must buy at least one token.
            revert InvalidMinTokensBoughtError(0);
        }

        // Check length of all arg arrays.
        if (
            args.tokenIds.length != args.callTargets.length ||
            args.tokenIds.length != args.callValues.length ||
            args.tokenIds.length != args.callDatas.length ||
            args.tokenIds.length != args.proofs.length
        ) {
            revert MismatchedCallArgLengthsError();
        }

        // Temporarily set to non-zero as a reentrancy guard.
        settledPrice = type(uint96).max;

        uint96 totalEthUsed;
        uint256 tokensBought;
        IERC721[] memory tokens = new IERC721[](args.tokenIds.length);
        IERC721 token = nftContract;
        bytes32 root = nftTokenIdsMerkleRoot;
        for (uint256 i; i < args.tokenIds.length; ++i) {
            if (root != bytes32(0)) {
                // Verify the token ID is in the merkle tree.
                _verifyTokenId(args.tokenIds[i], root, args.proofs[i]);
            }

            // Used to ensure no ETH is spent if the call fails.
            uint256 balanceBefore = address(this).balance;

            // Execute the call to buy the NFT.
            (bool success, bytes memory revertData) = _buy(
                token,
                args.tokenIds[i],
                args.callTargets[i],
                args.callValues[i],
                args.callDatas[i]
            );

            if (!success) {
                if (args.minTokensBought >= args.tokenIds.length) {
                    // If the call failed with revert data, revert with that data.
                    if (revertData.length > 0) {
                        revertData.rawRevert();
                    } else {
                        revert FailedToBuyNFTError(token, args.tokenIds[i]);
                    }
                } else {
                    // If the call failed, ensure no ETH was spent and skip this NFT.
                    if (address(this).balance != balanceBefore) {
                        revert ContributionsSpentForFailedBuyError();
                    }

                    continue;
                }
            }

            totalEthUsed += args.callValues[i];

            ++tokensBought;
            tokens[tokensBought - 1] = token;
            args.tokenIds[tokensBought - 1] = args.tokenIds[i];
        }

        // This is to prevent this crowdfund from finalizing a loss if nothing
        // was attempted to be bought (ie. `tokenIds` is empty) or all NFTs were
        // bought for free.
        if (totalEthUsed == 0) revert NothingBoughtError();

        // Check number of tokens bought is not less than the minimum.
        if (tokensBought < args.minTokensBought) {
            revert NotEnoughTokensBoughtError(tokensBought, args.minTokensBought);
        }

        // Check total ETH used is not less than the minimum.
        if (totalEthUsed < args.minTotalEthUsed) {
            revert NotEnoughEthUsedError(totalEthUsed, args.minTotalEthUsed);
        }

        assembly {
            // Update length of `tokens`
            mstore(tokens, tokensBought)
            // Update length of `tokenIds`
            mstore(0x1A0, tokensBought)
        }

        return
            _finalize(
                tokens,
                args.tokenIds,
                totalEthUsed,
                args.governanceOpts,
                // If `_assertIsHost()` succeeded, the governance opts were validated.
                true
            );
    }

    function _verifyTokenId(uint256 tokenId, bytes32 root, bytes32[] memory proof) private pure {
        bytes32 leaf;
        assembly {
            mstore(0x00, tokenId)
            leaf := keccak256(0x00, 0x20)
        }

        if (!MerkleProof.verify(proof, root, leaf)) revert InvalidTokenIdError();
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
///         token ID) from a collection for a known price. Like `BuyCrowdfund`
///         but allows any token ID to be bought.
contract CollectionBuyCrowdfund is BuyCrowdfundBase {
    using LibSafeERC721 for IERC721;
    using LibSafeCast for uint256;
    using LibRawResult for bytes;

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
        // How long this crowdfund has to buy the NFT, in seconds.
        uint40 duration;
        // Maximum amount this crowdfund will pay for the NFT.
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
        // Minimum amount of ETH that can be contributed to this crowdfund per address.
        uint96 minContribution;
        // Maximum amount of ETH that can be contributed to this crowdfund per address.
        uint96 maxContribution;
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
    function initialize(
        CollectionBuyCrowdfundOptions memory opts
    ) external payable onlyConstructor {
        if (opts.governanceOpts.hosts.length == 0) {
            revert MissingHostsError();
        }
        BuyCrowdfundBase._initialize(
            BuyCrowdfundBaseOptions({
                name: opts.name,
                symbol: opts.symbol,
                customizationPresetId: opts.customizationPresetId,
                duration: opts.duration,
                maximumPrice: opts.maximumPrice,
                splitRecipient: opts.splitRecipient,
                splitBps: opts.splitBps,
                initialContributor: opts.initialContributor,
                initialDelegate: opts.initialDelegate,
                minContribution: opts.minContribution,
                maxContribution: opts.maxContribution,
                gateKeeper: opts.gateKeeper,
                gateKeeperId: opts.gateKeeperId,
                governanceOpts: opts.governanceOpts
            })
        );
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
    /// @param hostIndex This is the index of the caller in the `governanceOpts.hosts` array.
    /// @return party_ Address of the `Party` instance created after its bought.
    function buy(
        uint256 tokenId,
        address payable callTarget,
        uint96 callValue,
        bytes memory callData,
        FixedGovernanceOpts memory governanceOpts,
        uint256 hostIndex
    ) external onlyDelegateCall returns (Party party_) {
        // This function is always restricted to hosts.
        _assertIsHost(msg.sender, governanceOpts, hostIndex);

        {
            // Ensure that the crowdfund is still active.
            CrowdfundLifecycle lc = getCrowdfundLifecycle();
            if (lc != CrowdfundLifecycle.Active) {
                revert WrongLifecycleError(lc);
            }
        }

        // Temporarily set to non-zero as a reentrancy guard.
        settledPrice = type(uint96).max;

        // Buy the NFT and check NFT is owned by the crowdfund.
        (bool success, bytes memory revertData) = _buy(
            nftContract,
            tokenId,
            callTarget,
            callValue,
            callData
        );

        if (!success) {
            if (revertData.length > 0) {
                revertData.rawRevert();
            } else {
                revert FailedToBuyNFTError(nftContract, tokenId);
            }
        }

        return
            _finalize(
                nftContract,
                tokenId,
                callValue,
                governanceOpts,
                // If `_assertIsHost()` succeeded, the governance opts were validated.
                true
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
        uint96 minContribution;
        uint96 maxContribution;
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
    error InvalidContributorError();
    error NoPartyError();
    error NotAllowedByGateKeeperError(
        address contributor,
        IGateKeeper gateKeeper,
        bytes12 gateKeeperId,
        bytes gateData
    );
    error SplitRecipientAlreadyBurnedError();
    error InvalidBpsError(uint16 bps);
    error ExceedsTotalContributionsError(uint96 value, uint96 totalContributions);
    error NothingToClaimError();
    error OnlyPartyHostError();
    error OnlyContributorError();
    error MissingHostsError();
    error OnlyPartyDaoError(address notDao);
    error OnlyPartyDaoOrHostError(address notDao);
    error OnlyWhenEmergencyActionsAllowedError();
    error BelowMinimumContributionsError(uint96 contributions, uint96 minContributions);
    error AboveMaximumContributionsError(uint96 contributions, uint96 maxContributions);

    event Burned(address contributor, uint256 ethUsed, uint256 ethOwed, uint256 votingPower);
    event Contributed(
        address sender,
        address contributor,
        uint256 amount,
        address delegate,
        uint256 previousTotalContributions
    );
    event EmergencyExecute(address target, bytes data, uint256 amountEth);
    event EmergencyExecuteDisabled();

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
    /// @notice Minimum amount of ETH that can be contributed to this crowdfund per address.
    uint96 public minContribution;
    /// @notice Maximum amount of ETH that can be contributed to this crowdfund per address.
    uint96 public maxContribution;
    /// @notice Whether the DAO has emergency powers for this party.
    bool public emergencyExecuteDisabled;

    // Set the `Globals` contract.
    constructor(IGlobals globals) CrowdfundNFT(globals) {
        _GLOBALS = globals;
    }

    // Initialize storage for proxy contracts, credit initial contribution (if
    // any), and setup gatekeeper.
    function _initialize(CrowdfundOptions memory opts) internal {
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
        // Set the minimum and maximum contribution amounts.
        minContribution = opts.minContribution;
        maxContribution = opts.maxContribution;
        // If the deployer passed in some ETH during deployment, credit them
        // for the initial contribution.
        uint96 initialContribution = msg.value.safeCastUint256ToUint96();
        if (initialContribution > 0) {
            _setDelegate(opts.initialContributor, opts.initialDelegate);
            // If this ETH is passed in, credit it to the `initialContributor`.
            _contribute(opts.initialContributor, opts.initialDelegate, initialContribution, 0, "");
        }
        // Set up gatekeeper after initial contribution (initial always gets in).
        gateKeeper = opts.gateKeeper;
        gateKeeperId = opts.gateKeeperId;
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
    ) external payable onlyDelegateCall {
        // Must be called by the DAO.
        if (!_isPartyDao(msg.sender)) {
            revert OnlyPartyDaoError(msg.sender);
        }
        // Must not be disabled by DAO or host.
        if (emergencyExecuteDisabled) {
            revert OnlyWhenEmergencyActionsAllowedError();
        }
        (bool success, bytes memory res) = targetAddress.call{ value: amountEth }(targetCallData);
        if (!success) {
            res.rawRevert();
        }
        emit EmergencyExecute(targetAddress, targetCallData, amountEth);
    }

    /// @notice Revoke the DAO's ability to call emergencyExecute().
    /// @dev Either the DAO or the party host can call this.
    /// @param governanceOpts The fixed governance opts the crowdfund was created with.
    /// @param hostIndex The index of the party host (caller).
    function disableEmergencyExecute(
        FixedGovernanceOpts memory governanceOpts,
        uint256 hostIndex
    ) external onlyDelegateCall {
        // Only the DAO or a host can call this.
        if (!_isHost(msg.sender, governanceOpts, hostIndex) && !_isPartyDao(msg.sender)) {
            revert OnlyPartyDaoOrHostError(msg.sender);
        }
        emergencyExecuteDisabled = true;
        emit EmergencyExecuteDisabled();
    }

    /// @notice Burn the participation NFT for `contributor`, potentially
    ///         minting voting power and/or refunding unused ETH. `contributor`
    ///         may also be the split recipient, regardless of whether they are
    ///         also a contributor or not. This can be called by anyone on a
    ///         contributor's behalf to unlock their voting power in the
    ///         governance stage ensuring delegates receive their voting
    ///         power and governance is not stalled.
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
    ) external {
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
    function contribute(address delegate, bytes memory gateData) external payable onlyDelegateCall {
        _setDelegate(msg.sender, delegate);

        _contribute(
            msg.sender,
            delegate,
            msg.value.safeCastUint256ToUint96(),
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

    /// @notice Contribute to this crowdfund on behalf of another address.
    /// @param recipient The address to record the contribution under.
    /// @param initialDelegate The address to delegate to for the governance phase if recipient hasn't delegated.
    /// @param gateData Data to pass to the gatekeeper to prove eligibility.
    function contributeFor(
        address recipient,
        address initialDelegate,
        bytes memory gateData
    ) external payable onlyDelegateCall {
        _setDelegate(recipient, initialDelegate);

        _contribute(
            recipient,
            initialDelegate,
            msg.value.safeCastUint256ToUint96(),
            totalContributions,
            gateData
        );
    }

    /// @notice `contributeFor()` in batch form.
    ///         May not revert if any individual contribution fails.
    /// @param recipients The addresses to record the contributions under.
    /// @param initialDelegates The addresses to delegate to for each recipient.
    /// @param values The ETH to contribute for each recipient.
    /// @param gateDatas Data to pass to the gatekeeper to prove eligibility.
    /// @param revertOnFailure If true, revert if any contribution fails.
    function batchContributeFor(
        address[] memory recipients,
        address[] memory initialDelegates,
        uint256[] memory values,
        bytes[] memory gateDatas,
        bool revertOnFailure
    ) external payable {
        for (uint256 i; i < recipients.length; ++i) {
            (bool s, bytes memory r) = address(this).call{ value: values[i] }(
                abi.encodeCall(
                    this.contributeFor,
                    (recipients[i], initialDelegates[i], gateDatas[i])
                )
            );
            if (revertOnFailure && !s) {
                r.rawRevert();
            }
        }
    }

    /// @inheritdoc EIP165
    function supportsInterface(
        bytes4 interfaceId
    ) public pure override(ERC721Receiver, CrowdfundNFT) returns (bool) {
        return
            ERC721Receiver.supportsInterface(interfaceId) ||
            CrowdfundNFT.supportsInterface(interfaceId);
    }

    /// @notice Retrieve info about a participant's contributions.
    /// @dev This will only be called off-chain so doesn't have to be optimal.
    /// @param contributor The contributor to retrieve contributions for.
    /// @return ethContributed The total ETH contributed by `contributor`.
    /// @return ethUsed The total ETH used by `contributor` to acquire the NFT.
    /// @return ethOwed The total ETH refunded back to `contributor`.
    /// @return votingPower The total voting power minted to `contributor`.
    function getContributorInfo(
        address contributor
    )
        external
        view
        returns (uint256 ethContributed, uint256 ethUsed, uint256 ethOwed, uint256 votingPower)
    {
        CrowdfundLifecycle lc = getCrowdfundLifecycle();
        if (lc == CrowdfundLifecycle.Won || lc == CrowdfundLifecycle.Lost) {
            (ethUsed, ethOwed, votingPower) = _getFinalContribution(contributor);
            ethContributed = ethUsed + ethOwed;
        } else {
            Contribution[] memory contributions = _contributionsByContributor[contributor];
            uint256 numContributions = contributions.length;
            for (uint256 i; i < numContributions; ++i) {
                ethContributed += contributions[i].amount;
            }
        }
    }

    /// @notice Get the current lifecycle of the crowdfund.
    function getCrowdfundLifecycle() public view virtual returns (CrowdfundLifecycle lifecycle);

    // Get the final sale price of the bought assets. This will also be the total
    // voting power of the governance party.
    function _getFinalPrice() internal view virtual returns (uint256);

    // Assert that `who` is a host at `governanceOpts.hosts[hostIndex]` and,
    // if so, assert that the governance opts is the same as the crowdfund
    // was created with.
    // Return true if `governanceOpts` was validated in the process.
    function _assertIsHost(
        address who,
        FixedGovernanceOpts memory governanceOpts,
        uint256 hostIndex
    ) internal view {
        if (!_isHost(who, governanceOpts, hostIndex)) {
            revert OnlyPartyHostError();
        }
    }

    // Check if `who` is a host at `hostIndex` index. Validates governance opts if so.
    function _isHost(
        address who,
        FixedGovernanceOpts memory governanceOpts,
        uint256 hostIndex
    ) private view returns (bool isHost) {
        if (hostIndex < governanceOpts.hosts.length && who == governanceOpts.hosts[hostIndex]) {
            // Validate governance opts if the host was found.
            _assertValidGovernanceOpts(governanceOpts);
            return true;
        }
        return false;
    }

    function _isPartyDao(address who) private view returns (bool isPartyDao) {
        return who == _GLOBALS.getAddress(LibGlobals.GLOBAL_DAO_WALLET);
    }

    // Assert that `who` is a contributor to the crowdfund.
    function _assertIsContributor(address who) internal view {
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
    ) internal returns (Party party_) {
        if (party != Party(payable(0))) {
            revert PartyAlreadyExistsError(party);
        }
        // If the governance opts haven't already been validated, make sure that
        // it hasn't been tampered with.
        if (!governanceOptsAlreadyValidated) {
            _assertValidGovernanceOpts(governanceOpts);
        }
        // Create a party.
        party = party_ = _getPartyFactory().createParty(
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
    ) internal returns (Party party_) {
        IERC721[] memory tokens = new IERC721[](1);
        tokens[0] = preciousToken;
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = preciousTokenId;
        return _createParty(governanceOpts, governanceOptsAlreadyValidated, tokens, tokenIds);
    }

    // Assert that the hash of `opts` matches the hash this crowdfund was initialized with.
    function _assertValidGovernanceOpts(FixedGovernanceOpts memory governanceOpts) private view {
        bytes32 governanceOptsHash_ = _hashFixedGovernanceOpts(governanceOpts);
        if (governanceOptsHash_ != governanceOptsHash) {
            revert InvalidGovernanceOptionsError();
        }
    }

    function _hashFixedGovernanceOpts(
        FixedGovernanceOpts memory opts
    ) internal pure returns (bytes32 h) {
        // Hash in place.
        assembly {
            // Replace the address[] hosts field with its hash temporarily.
            let oldHostsFieldValue := mload(opts)
            mstore(
                opts,
                keccak256(add(oldHostsFieldValue, 0x20), mul(mload(oldHostsFieldValue), 32))
            )
            // Hash the entire struct.
            h := keccak256(opts, 0xC0)
            // Restore old hosts field value.
            mstore(opts, oldHostsFieldValue)
        }
    }

    function _getFinalContribution(
        address contributor
    ) internal view returns (uint256 ethUsed, uint256 ethOwed, uint256 votingPower) {
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

    function _setDelegate(address contributor, address delegate) private {
        if (delegate == address(0)) revert InvalidDelegateError();

        // Only need to update delegate if there was a change.
        address oldDelegate = delegationsByContributor[contributor];
        if (oldDelegate == delegate) return;

        // Only allow setting delegate on another's behalf if the delegate is unset.
        if (msg.sender != contributor && oldDelegate != address(0)) return;

        // Update delegate.
        delegationsByContributor[contributor] = delegate;
    }

    /// @dev While it is not necessary to pass in `delegate` to this because the
    ///      function does not require it, it is here to emit in the
    ///      `Contribute` event so that the PartyBid frontend can access it more
    ///      easily.
    function _contribute(
        address contributor,
        address delegate,
        uint96 amount,
        uint96 previousTotalContributions,
        bytes memory gateData
    ) private {
        if (contributor == address(this)) revert InvalidContributorError();

        if (amount == 0) return;

        // Must not be blocked by gatekeeper.
        {
            IGateKeeper _gateKeeper = gateKeeper;
            if (_gateKeeper != IGateKeeper(address(0))) {
                if (!_gateKeeper.isAllowed(msg.sender, gateKeeperId, gateData)) {
                    revert NotAllowedByGateKeeperError(
                        msg.sender,
                        _gateKeeper,
                        gateKeeperId,
                        gateData
                    );
                }
            }
        }
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
        uint96 ethContributed;
        for (uint256 i; i < numContributions; ++i) {
            ethContributed += contributions[i].amount;
        }
        // Check contribution is greater than minimum contribution.
        if (ethContributed + amount < minContribution) {
            revert BelowMinimumContributionsError(ethContributed + amount, minContribution);
        }
        // Check contribution is less than maximum contribution.
        if (ethContributed + amount > maxContribution) {
            revert AboveMaximumContributionsError(ethContributed + amount, maxContribution);
        }

        emit Contributed(msg.sender, contributor, amount, delegate, previousTotalContributions);

        if (numContributions >= 1) {
            Contribution memory lastContribution = contributions[numContributions - 1];
            // If no one else (other than this contributor) has contributed since,
            // we can just reuse this contributor's last entry.
            uint256 totalContributionsAmountForReuse = lastContribution.previousTotalContributions +
                lastContribution.amount;
            if (totalContributionsAmountForReuse == previousTotalContributions) {
                lastContribution.amount += amount;
                contributions[numContributions - 1] = lastContribution;
                return;
            }
        }
        // Add a new contribution entry.
        contributions.push(
            Contribution({ previousTotalContributions: previousTotalContributions, amount: amount })
        );
        // Mint a participation NFT if this is their first contribution.
        if (numContributions == 0) {
            _mint(contributor);
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
        (uint256 ethUsed, uint256 ethOwed, uint256 votingPower) = _getFinalContribution(
            contributor
        );
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
        (bool s, ) = contributor.call{ value: ethOwed }("");
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
import "./RollingAuctionCrowdfund.sol";
import "./CollectionBatchBuyCrowdfund.sol";

/// @notice Factory used to deploys new proxified `Crowdfund` instances.
contract CrowdfundFactory {
    using LibRawResult for bytes;

    event BuyCrowdfundCreated(BuyCrowdfund crowdfund, BuyCrowdfund.BuyCrowdfundOptions opts);
    event AuctionCrowdfundCreated(
        AuctionCrowdfund crowdfund,
        AuctionCrowdfundBase.AuctionCrowdfundOptions opts
    );
    event CollectionBuyCrowdfundCreated(
        CollectionBuyCrowdfund crowdfund,
        CollectionBuyCrowdfund.CollectionBuyCrowdfundOptions opts
    );
    event RollingAuctionCrowdfundCreated(
        RollingAuctionCrowdfund crowdfund,
        RollingAuctionCrowdfund.RollingAuctionCrowdfundOptions opts
    );
    event CollectionBatchBuyCrowdfundCreated(
        CollectionBatchBuyCrowdfund crowdfund,
        CollectionBatchBuyCrowdfund.CollectionBatchBuyCrowdfundOptions opts
    );

    // The `Globals` contract storing global configuration values. This contract
    // is immutable and it’s address will never change.
    IGlobals private immutable _GLOBALS;

    // Set the `Globals` contract.
    constructor(IGlobals globals) {
        _GLOBALS = globals;
    }

    address constant AUCTION_CROWDFUND_IMPL = 0xC45e57873C1a2366F44Cbe5851a376f0Ab9093DA;
    address constant ROLLING_AUCTION_CROWDFUND_IMPL = 0x0d212feaE711aE9a065649ca577b4d6F4d67A0C6;
    address constant BUY_CROWDFUND_IMPL = 0x79EbABbF5afA3763B6259Cb0a7d7f72ab59A2c47;
    address constant COLLECTION_BUY_CROWDFUND_IMPL = 0xe944ecd23Dd7839077e1Fe04872eF93BfDe58bB3;
    address constant COLLECTION_BATCH_BUY_CROWDFUND_IMPL =
        0x8e357490dC8E94E9594AE910BA261163631a6a3a;

    /// @notice Create a new crowdfund to purchase a specific NFT (i.e., with a
    ///         known token ID) listing for a known price.
    /// @param opts Options used to initialize the crowdfund. These are fixed
    ///             and cannot be changed later.
    /// @param createGateCallData Encoded calldata used by `createGate()` to
    ///                           create the crowdfund if one is specified in `opts`.
    function createBuyCrowdfund(
        BuyCrowdfund.BuyCrowdfundOptions memory opts,
        bytes memory createGateCallData
    ) public payable returns (BuyCrowdfund inst) {
        opts.gateKeeperId = _prepareGate(opts.gateKeeper, opts.gateKeeperId, createGateCallData);
        inst = BuyCrowdfund(
            payable(
                new Proxy{ value: msg.value }(
                    Implementation(BUY_CROWDFUND_IMPL),
                    abi.encodeCall(BuyCrowdfund.initialize, (opts))
                )
            )
        );
        emit BuyCrowdfundCreated(inst, opts);
    }

    /// @notice Create a new crowdfund to bid on an auction for a specific NFT
    ///         (i.e. with a known token ID).
    /// @param opts Options used to initialize the crowdfund. These are fixed
    ///             and cannot be changed later.
    /// @param createGateCallData Encoded calldata used by `createGate()` to create
    ///                           the crowdfund if one is specified in `opts`.
    function createAuctionCrowdfund(
        AuctionCrowdfundBase.AuctionCrowdfundOptions memory opts,
        bytes memory createGateCallData
    ) public payable returns (AuctionCrowdfund inst) {
        opts.gateKeeperId = _prepareGate(opts.gateKeeper, opts.gateKeeperId, createGateCallData);
        inst = AuctionCrowdfund(
            payable(
                new Proxy{ value: msg.value }(
                    Implementation(AUCTION_CROWDFUND_IMPL),
                    abi.encodeCall(AuctionCrowdfund.initialize, (opts))
                )
            )
        );
        emit AuctionCrowdfundCreated(inst, opts);
    }

    /// @notice Create a new crowdfund to bid on an auctions for an NFT from a collection
    ///         on a market (eg. Nouns).
    /// @param opts Options used to initialize the crowdfund. These are fixed
    ///             and cannot be changed later.
    /// @param createGateCallData Encoded calldata used by `createGate()` to create
    ///                           the crowdfund if one is specified in `opts`.
    function createRollingAuctionCrowdfund(
        RollingAuctionCrowdfund.RollingAuctionCrowdfundOptions memory opts,
        bytes memory createGateCallData
    ) public payable returns (RollingAuctionCrowdfund inst) {
        opts.gateKeeperId = _prepareGate(opts.gateKeeper, opts.gateKeeperId, createGateCallData);
        inst = RollingAuctionCrowdfund(
            payable(
                new Proxy{ value: msg.value }(
                    Implementation(ROLLING_AUCTION_CROWDFUND_IMPL),
                    abi.encodeCall(RollingAuctionCrowdfund.initialize, (opts))
                )
            )
        );
        emit RollingAuctionCrowdfundCreated(inst, opts);
    }

    /// @notice Create a new crowdfund to purchases any NFT from a collection
    ///         (i.e. any token ID) from a collection for a known price.
    /// @param opts Options used to initialize the crowdfund. These are fixed
    ///             and cannot be changed later.
    /// @param createGateCallData Encoded calldata used by `createGate()` to create
    ///                           the crowdfund if one is specified in `opts`.
    function createCollectionBuyCrowdfund(
        CollectionBuyCrowdfund.CollectionBuyCrowdfundOptions memory opts,
        bytes memory createGateCallData
    ) public payable returns (CollectionBuyCrowdfund inst) {
        opts.gateKeeperId = _prepareGate(opts.gateKeeper, opts.gateKeeperId, createGateCallData);
        inst = CollectionBuyCrowdfund(
            payable(
                new Proxy{ value: msg.value }(
                    Implementation(COLLECTION_BUY_CROWDFUND_IMPL),
                    abi.encodeCall(CollectionBuyCrowdfund.initialize, (opts))
                )
            )
        );
        emit CollectionBuyCrowdfundCreated(inst, opts);
    }

    /// @notice Create a new crowdfund to purchase multiple NFTs from a collection
    ///         (i.e. any token ID) from a collection for known prices.
    /// @param opts Options used to initialize the crowdfund. These are fixed
    ///             and cannot be changed later.
    /// @param createGateCallData Encoded calldata used by `createGate()` to create
    ///                           the crowdfund if one is specified in `opts`.
    function createCollectionBatchBuyCrowdfund(
        CollectionBatchBuyCrowdfund.CollectionBatchBuyCrowdfundOptions memory opts,
        bytes memory createGateCallData
    ) public payable returns (CollectionBatchBuyCrowdfund inst) {
        opts.gateKeeperId = _prepareGate(opts.gateKeeper, opts.gateKeeperId, createGateCallData);
        inst = CollectionBatchBuyCrowdfund(
            payable(
                new Proxy{ value: msg.value }(
                    Implementation(COLLECTION_BATCH_BUY_CROWDFUND_IMPL),
                    abi.encodeCall(CollectionBatchBuyCrowdfund.initialize, (opts))
                )
            )
        );
        emit CollectionBatchBuyCrowdfundCreated(inst, opts);
    }

    function _prepareGate(
        IGateKeeper gateKeeper,
        bytes12 gateKeeperId,
        bytes memory createGateCallData
    ) private returns (bytes12 newGateKeeperId) {
        if (address(gateKeeper) == address(0) || gateKeeperId != bytes12(0)) {
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

    mapping(uint256 => address) private _owners;

    modifier alwaysRevert() {
        revert("ALWAYS FAILING");
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
    ) internal virtual {
        name = name_;
        symbol = symbol_;
        if (customizationPresetId != 0) {
            RendererStorage(_GLOBALS.getAddress(LibGlobals.GLOBAL_RENDERER_STORAGE))
                .useCustomizationPreset(customizationPresetId);
        }
    }

    /// @notice DO NOT CALL. This is a soulbound NFT and cannot be transferred.
    ///         Attempting to call this function will always fail.
    function transferFrom(address, address, uint256) external pure alwaysRevert {}

    /// @notice DO NOT CALL. This is a soulbound NFT and cannot be transferred.
    ///         Attempting to call this function will always fail.
    function safeTransferFrom(address, address, uint256) external pure alwaysRevert {}

    /// @notice DO NOT CALL. This is a soulbound NFT and cannot be transferred.
    ///         Attempting to call this function will always fail.
    function safeTransferFrom(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure alwaysRevert {}

    /// @notice DO NOT CALL. This is a soulbound NFT and cannot be transferred.
    ///         Attempting to call this function will always fail.
    function approve(address, uint256) external pure alwaysRevert {}

    /// @notice DO NOT CALL. This is a soulbound NFT and cannot be transferred.
    ///         Attempting to call this function will always fail.
    function setApprovalForAll(address, bool) external pure alwaysRevert {}

    /// @notice This is a soulbound NFT and cannot be transferred.
    ///         Attempting to call this function will always return null.
    function getApproved(uint256) external pure returns (address) {
        return address(0);
    }

    /// @notice This is a soulbound NFT and cannot be transferred.
    ///         Attempting to call this function will always return false.
    function isApprovedForAll(address, address) external pure returns (bool) {
        return false;
    }

    /// @inheritdoc EIP165
    function supportsInterface(bytes4 interfaceId) public pure virtual override returns (bool) {
        return
            super.supportsInterface(interfaceId) ||
            // ERC721 interface ID
            interfaceId == 0x80ac58cd;
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

// SPDX-License-Identifier: Beta Software
// http://ipfs.io/ipfs/QmbGX2MFCaMAsMNMugRFND6DtYygRkwkvrqEyTKhTdBLo5
pragma solidity 0.8.17;

import "openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "./AuctionCrowdfundBase.sol";

/// @notice A crowdfund that can repeatedly bid on auctions for an NFT from a
///         specific collection on a specific market (eg. Nouns) and can
///         continue bidding on new auctions until it wins.
contract RollingAuctionCrowdfund is AuctionCrowdfundBase {
    using LibSafeERC721 for IERC721;
    using LibSafeCast for uint256;
    using LibRawResult for bytes;

    struct RollingAuctionCrowdfundOptions {
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
        // Maximum bid allowed per auction.
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
        // Minimum amount of ETH that can be contributed to this crowdfund per address.
        uint96 minContribution;
        // Maximum amount of ETH that can be contributed to this crowdfund per address.
        uint96 maxContribution;
        // The gatekeeper contract to use (if non-null) to restrict who can
        // contribute to this crowdfund.
        IGateKeeper gateKeeper;
        // The gate ID within the gateKeeper contract to use.
        bytes12 gateKeeperId;
        // Whether the party is only allowing a host to call `bid()`.
        bool onlyHostCanBid;
        // Merkle root of list of allowed next auctions that can be rolled over
        // to if the current auction loses. Each leaf should be hashed as
        // `keccak256(abi.encodePacked(bytes32(0), auctionId, tokenId)))` where `auctionId`
        // is the auction ID of the auction to allow and `tokenId` is the
        // `tokenId` of the NFT being auctioned.
        bytes32 allowedAuctionsMerkleRoot;
        // Fixed governance options (i.e. cannot be changed) that the governance
        // `Party` will be created with if the crowdfund succeeds.
        FixedGovernanceOpts governanceOpts;
    }

    event AuctionUpdated(uint256 nextNftTokenId, uint256 nextAuctionId, uint256 nextMaximumBid);

    error BadNextAuctionError();

    /// @notice Merkle root of list of allowed next auctions that can be rolled
    ///         over to if the current auction loses. Each leaf should be hashed
    ///         as `keccak256(abi.encodePacked(auctionId, tokenId)))` where
    ///         `auctionId` is the auction ID of the auction to allow and
    ///         `tokenId` is the `tokenId` of the NFT being auctioned.
    bytes32 public allowedAuctionsMerkleRoot;

    // Set the `Globals` contract.
    constructor(IGlobals globals) AuctionCrowdfundBase(globals) {}

    /// @notice Initializer to be delegatecalled by `Proxy` constructor. Will
    ///         revert if called outside the constructor.
    /// @param opts Options used to initialize the crowdfund. These are fixed
    ///             and cannot be changed later.
    function initialize(
        RollingAuctionCrowdfundOptions memory opts
    ) external payable onlyConstructor {
        // Initialize the base contract.
        AuctionCrowdfundBase._initialize(
            AuctionCrowdfundBase.AuctionCrowdfundOptions({
                name: opts.name,
                symbol: opts.symbol,
                customizationPresetId: opts.customizationPresetId,
                auctionId: opts.auctionId,
                market: opts.market,
                nftContract: opts.nftContract,
                nftTokenId: opts.nftTokenId,
                duration: opts.duration,
                maximumBid: opts.maximumBid,
                splitRecipient: opts.splitRecipient,
                splitBps: opts.splitBps,
                initialContributor: opts.initialContributor,
                initialDelegate: opts.initialDelegate,
                minContribution: opts.minContribution,
                maxContribution: opts.maxContribution,
                gateKeeper: opts.gateKeeper,
                gateKeeperId: opts.gateKeeperId,
                onlyHostCanBid: opts.onlyHostCanBid,
                governanceOpts: opts.governanceOpts
            })
        );

        allowedAuctionsMerkleRoot = opts.allowedAuctionsMerkleRoot;
    }

    /// @notice Calls `finalize()` on the market adapter, which will claim the NFT
    ///         (if necessary) if we won, or recover our bid (if necessary)
    ///         if the crowfund expired and we lost the current auction. If we
    ///         lost but the crowdfund has not expired, this will revert. Only
    ///         call this to finalize the result of a won or expired crowdfund,
    ///         otherwise call `finalizeOrRollOver()`.
    /// @param governanceOpts The options used to initialize governance in the
    ///                       `Party` instance created if the crowdfund wins.
    /// @return party_ Address of the `Party` instance created if successful.
    function finalize(
        FixedGovernanceOpts memory governanceOpts
    ) external onlyDelegateCall returns (Party party_) {
        // If the crowdfund won, only `governanceOpts` is relevant. The rest are ignored.
        return finalizeOrRollOver(0, 0, 0, new bytes32[](0), governanceOpts, 0);
    }

    /// @notice Calls `finalize()` on the market adapter, which will claim the NFT
    ///         (if necessary) if we won, or recover our bid (if necessary)
    ///         if the crowfund expired and we lost. If we lost but the
    ///         crowdfund has not expired, it will move on to the next auction
    ///         specified (if allowed).
    /// @param governanceOpts The options used to initialize governance in the
    ///                       `Party` instance created if the crowdfund wins.
    /// @param hostIndex If the caller is a host, this is the index of the caller in the
    ///                  `governanceOpts.hosts` array. Only used if the
    ///                  crowdfund lost the current auction AND host are allowed
    ///                  to choose any next auction.
    /// @param nextNftTokenId The `tokenId` of the next NFT to bid on in the next
    ///                       auction. Only used if the crowdfund lost the
    ///                       current auction.
    /// @param nextAuctionId The `auctionId` of the the next auction. Only
    ///                      used if the crowdfund lost the current auction.
    /// @param nextMaximumBid The maximum bid the party can place for the next
    ///                       auction. Only used if the crowdfund lost the
    ///                       current auction.
    /// @param proof The Merkle proof used to verify that `nextAuctionId` and
    ///              `nextNftTokenId` are allowed. Only used if the crowdfund
    ///              lost the current auction.
    /// @return party_ Address of the `Party` instance created if successful.
    function finalizeOrRollOver(
        uint256 nextNftTokenId,
        uint256 nextAuctionId,
        uint96 nextMaximumBid,
        bytes32[] memory proof,
        FixedGovernanceOpts memory governanceOpts,
        uint256 hostIndex
    ) public onlyDelegateCall returns (Party party_) {
        // Check that the auction is still active and has not passed the `expiry` time.
        CrowdfundLifecycle lc = getCrowdfundLifecycle();
        if (lc != CrowdfundLifecycle.Active && lc != CrowdfundLifecycle.Expired) {
            revert WrongLifecycleError(lc);
        }

        // Finalize the auction if it is not already finalized.
        uint96 lastBid_ = lastBid;
        _finalizeAuction(lc, market, auctionId, lastBid_);

        IERC721 nftContract_ = nftContract;
        uint256 nftTokenId_ = nftTokenId;
        // Are we now in possession of the NFT?
        if (nftContract_.safeOwnerOf(nftTokenId_) == address(this) && lastBid_ != 0) {
            // Create a governance party around the NFT.
            party_ = _createParty(governanceOpts, false, nftContract, nftTokenId);
            emit Won(lastBid, party_);

            _bidStatus = AuctionCrowdfundStatus.Finalized;
        } else if (lc == CrowdfundLifecycle.Expired) {
            // Crowdfund expired without NFT; finalize a loss.

            // Clear `lastBid` so `_getFinalPrice()` is 0 and people can redeem their
            // full contributions when they burn their participation NFTs.
            lastBid = 0;
            emit Lost();

            _bidStatus = AuctionCrowdfundStatus.Finalized;
        } else {
            // Move on to the next auction if this one has been lost (or, in
            // rare cases, if the NFT was acquired for free and funds remain
            // unused).

            if (allowedAuctionsMerkleRoot != bytes32(0)) {
                // Check that the next `auctionId` and `tokenId` for the next
                // auction to roll over have been allowed.
                if (
                    !MerkleProof.verify(
                        proof,
                        allowedAuctionsMerkleRoot,
                        // Hash leaf with extra (empty) 32 bytes to prevent a second
                        // preimage attack by hashing >64 bytes.
                        keccak256(abi.encodePacked(bytes32(0), nextAuctionId, nextNftTokenId))
                    )
                ) {
                    revert BadNextAuctionError();
                }
            } else {
                // Let the host change to any next auction.
                _assertIsHost(msg.sender, governanceOpts, hostIndex);
            }

            // Check that the new auction can be bid on and is valid.
            _validateAuction(market, nextAuctionId, nftContract, nextNftTokenId);

            // Check that the next maximum bid is greater than the auction's minimum bid.
            uint256 minimumBid = market.getMinimumBid(nextAuctionId);
            if (nextMaximumBid < minimumBid) {
                revert MinimumBidExceedsMaximumBidError(minimumBid, nextMaximumBid);
            }

            // Update state for next auction.
            nftTokenId = nextNftTokenId;
            auctionId = nextAuctionId;
            maximumBid = nextMaximumBid;
            lastBid = 0;

            emit AuctionUpdated(nextNftTokenId, nextAuctionId, nextMaximumBid);

            // Change back the auction status from `Busy` to `Active`.
            _bidStatus = AuctionCrowdfundStatus.Active;
        }
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

    event DistributionCreated(ITokenDistributorParty indexed party, DistributionInfo info);
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
    ) external payable returns (DistributionInfo memory info);

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
    ) external returns (DistributionInfo memory info);

    /// @notice Claim a portion of a distribution owed to a `partyTokenId` belonging
    ///         to the party that created the distribution. The caller
    ///         must own this token.
    /// @param info Information on the distribution being claimed.
    /// @param partyTokenId The ID of the party token to claim for.
    /// @return amountClaimed The amount of the distribution claimed.
    function claim(
        DistributionInfo calldata info,
        uint256 partyTokenId
    ) external returns (uint128 amountClaimed);

    /// @notice Claim the fee for a distribution. Only a distribution's `feeRecipient`
    ///         can call this.
    /// @param info Information on the distribution being claimed.
    /// @param recipient The address to send the fee to.
    function claimFee(DistributionInfo calldata info, address payable recipient) external;

    /// @notice Batch version of `claim()`.
    /// @param infos Information on the distributions being claimed.
    /// @param partyTokenIds The ID of the party tokens to claim for.
    /// @return amountsClaimed The amount of the distributions claimed.
    function batchClaim(
        DistributionInfo[] calldata infos,
        uint256[] calldata partyTokenIds
    ) external returns (uint128[] memory amountsClaimed);

    /// @notice Batch version of `claimFee()`.
    /// @param infos Information on the distributions to claim fees for.
    /// @param recipients The addresses to send the fees to.
    function batchClaimFee(
        DistributionInfo[] calldata infos,
        address payable[] calldata recipients
    ) external;

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
    ) external view returns (uint128);

    /// @notice Check whether the fee has been claimed for a distribution.
    /// @param party The party to use for checking whether the fee has been claimed.
    /// @param distributionId The ID of the distribution to check.
    /// @return feeClaimed Whether the fee has been claimed.
    function wasFeeClaimed(
        ITokenDistributorParty party,
        uint256 distributionId
    ) external view returns (bool);

    /// @notice Check whether a `partyTokenId` has claimed their share of a distribution.
    /// @param party The party to use for checking whether the `partyTokenId` has claimed.
    /// @param partyTokenId The ID of the party token to check.
    /// @param distributionId The ID of the distribution to check.
    /// @return hasClaimed Whether the `partyTokenId` has claimed.
    function hasPartyTokenIdClaimed(
        ITokenDistributorParty party,
        uint256 partyTokenId,
        uint256 distributionId
    ) external view returns (bool);

    /// @notice Get how much unclaimed member tokens are left in a distribution.
    /// @param party The party to use for checking the unclaimed member tokens.
    /// @param distributionId The ID of the distribution to check.
    /// @return remainingMemberSupply The amount of distribution supply remaining.
    function getRemainingMemberSupply(
        ITokenDistributorParty party,
        uint256 distributionId
    ) external view returns (uint128);
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
    uint256 internal constant GLOBAL_PARTY_IMPL = 1;
    uint256 internal constant GLOBAL_PROPOSAL_ENGINE_IMPL = 2;
    uint256 internal constant GLOBAL_PARTY_FACTORY = 3;
    uint256 internal constant GLOBAL_GOVERNANCE_NFT_RENDER_IMPL = 4;
    uint256 internal constant GLOBAL_CF_NFT_RENDER_IMPL = 5;
    uint256 internal constant GLOBAL_OS_ZORA_AUCTION_TIMEOUT = 6;
    uint256 internal constant GLOBAL_OS_ZORA_AUCTION_DURATION = 7;
    uint256 internal constant GLOBAL_AUCTION_CF_IMPL = 8;
    uint256 internal constant GLOBAL_BUY_CF_IMPL = 9;
    uint256 internal constant GLOBAL_COLLECTION_BUY_CF_IMPL = 10;
    uint256 internal constant GLOBAL_DAO_WALLET = 11;
    uint256 internal constant GLOBAL_TOKEN_DISTRIBUTOR = 12;
    uint256 internal constant GLOBAL_OPENSEA_CONDUIT_KEY = 13;
    uint256 internal constant GLOBAL_OPENSEA_ZONE = 14;
    uint256 internal constant GLOBAL_PROPOSAL_MAX_CANCEL_DURATION = 15;
    uint256 internal constant GLOBAL_ZORA_MIN_AUCTION_DURATION = 16;
    uint256 internal constant GLOBAL_ZORA_MAX_AUCTION_DURATION = 17;
    uint256 internal constant GLOBAL_ZORA_MAX_AUCTION_TIMEOUT = 18;
    uint256 internal constant GLOBAL_OS_MIN_ORDER_DURATION = 19;
    uint256 internal constant GLOBAL_OS_MAX_ORDER_DURATION = 20;
    uint256 internal constant GLOBAL_DISABLE_PARTY_ACTIONS = 21;
    uint256 internal constant GLOBAL_RENDERER_STORAGE = 22;
    uint256 internal constant GLOBAL_PROPOSAL_MIN_CANCEL_DURATION = 23;
    uint256 internal constant GLOBAL_ROLLING_AUCTION_CF_IMPL = 24;
    uint256 internal constant GLOBAL_COLLECTION_BATCH_BUY_CF_IMPL = 25;
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
    function getCurrentHighestBidder(uint256 auctionId) external view returns (address);

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
    ) external returns (Party party);

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
    function initialize(PartyInitData memory initData) external onlyConstructor {
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
        mapping(address => bool) hasVoted;
    }

    event Proposed(uint256 proposalId, address proposer, Proposal proposal);
    event ProposalAccepted(uint256 proposalId, address voter, uint256 weight);
    event EmergencyExecute(address target, bytes data, uint256 amountEth);

    event ProposalPassed(uint256 indexed proposalId);
    event ProposalVetoed(uint256 indexed proposalId, address host);
    event ProposalExecuted(uint256 indexed proposalId, address executor, bytes nextProgressData);
    event ProposalCancelled(uint256 indexed proposalId);
    event DistributionCreated(
        ITokenDistributor.TokenType tokenType,
        address token,
        uint256 tokenId
    );
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

    uint256 private constant UINT40_HIGH_BIT = 1 << 39;
    uint96 private constant VETO_VALUE = type(uint96).max;

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
            VotingPowerSnapshot memory snap = _getLastVotingPowerSnapshotForVoter(msg.sender);
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
            VotingPowerSnapshot memory snap = _getLastVotingPowerSnapshotForVoter(msg.sender);
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
    ) internal virtual {
        // Check BPS are valid.
        if (opts.feeBps > 1e4) {
            revert InvalidBpsError(opts.feeBps);
        }
        if (opts.passThresholdBps > 1e4) {
            revert InvalidBpsError(opts.passThresholdBps);
        }
        // Initialize the proposal execution engine.
        _initProposalImpl(
            IProposalExecutionEngine(_GLOBALS.getAddress(LibGlobals.GLOBAL_PROPOSAL_ENGINE_IMPL)),
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
        for (uint256 i = 0; i < opts.hosts.length; ++i) {
            isHost[opts.hosts[i]] = true;
        }
    }

    /// @dev Forward all unknown read-only calls to the proposal execution engine.
    ///      Initial use case is to facilitate eip-1271 signatures.
    fallback() external {
        _readOnlyDelegateCall(address(_getProposalExecutionEngine()), msg.data);
    }

    /// @inheritdoc EIP165
    /// @dev Combined logic for `ERC721Receiver` and `ERC1155Receiver`.
    function supportsInterface(
        bytes4 interfaceId
    ) public pure virtual override(ERC721Receiver, ERC1155Receiver) returns (bool) {
        return
            ERC721Receiver.supportsInterface(interfaceId) ||
            ERC1155Receiver.supportsInterface(interfaceId);
    }

    /// @notice Get the current `ProposalExecutionEngine` instance.
    function getProposalExecutionEngine() external view returns (IProposalExecutionEngine) {
        return _getProposalExecutionEngine();
    }

    /// @notice Get the total voting power of `voter` at a `timestamp`.
    /// @param voter The address of the voter.
    /// @param timestamp The timestamp to get the voting power at.
    /// @return votingPower The total voting power of `voter` at `timestamp`.
    function getVotingPowerAt(
        address voter,
        uint40 timestamp
    ) external view returns (uint96 votingPower) {
        return getVotingPowerAt(voter, timestamp, type(uint256).max);
    }

    /// @notice Get the total voting power of `voter` at a snapshot `snapIndex`, with checks to
    ///         make sure it is the latest voting snapshot =< `timestamp`.
    /// @param voter The address of the voter.
    /// @param timestamp The timestamp to get the voting power at.
    /// @param snapIndex The index of the snapshot to get the voting power at.
    /// @return votingPower The total voting power of `voter` at `timestamp`.
    function getVotingPowerAt(
        address voter,
        uint40 timestamp,
        uint256 snapIndex
    ) public view returns (uint96 votingPower) {
        VotingPowerSnapshot memory snap = _getVotingPowerSnapshotAt(voter, timestamp, snapIndex);
        return (snap.isDelegated ? 0 : snap.intrinsicVotingPower) + snap.delegatedVotingPower;
    }

    /// @notice Get the state of a proposal.
    /// @param proposalId The ID of the proposal.
    /// @return status The status of the proposal.
    /// @return values The state of the proposal.
    function getProposalStateInfo(
        uint256 proposalId
    ) external view returns (ProposalStatus status, ProposalStateValues memory values) {
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
    function getProposalHash(Proposal memory proposal) public pure returns (bytes32 proposalHash) {
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
    function findVotingPowerSnapshotIndex(
        address voter,
        uint40 timestamp
    ) public view returns (uint256 index) {
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
            if (isHost[newPartyHost]) {
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
            return
                distributor.createNativeDistribution{ value: address(this).balance }(
                    this,
                    feeRecipient_,
                    feeBps_
                );
        }
        // Otherwise must be an ERC20 token distribution.
        assert(tokenType == ITokenDistributor.TokenType.Erc20);
        IERC20(token).compatTransfer(address(distributor), IERC20(token).balanceOf(address(this)));
        return distributor.createErc20Distribution(IERC20(token), this, feeRecipient_, feeBps_);
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
    function propose(
        Proposal memory proposal,
        uint256 latestSnapIndex
    ) external onlyActiveMember onlyDelegateCall returns (uint256 proposalId) {
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
    function accept(
        uint256 proposalId,
        uint256 snapIndex
    ) public onlyDelegateCall returns (uint256 totalVotes) {
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
        if (
            values.passedTime == 0 &&
            _areVotesPassing(
                values.votes,
                _governanceValues.totalVotingPower,
                _governanceValues.passThresholdBps
            )
        ) {
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
    ) external payable onlyActiveMember onlyWhenNotGloballyDisabled onlyDelegateCall {
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
    function cancel(
        uint256 proposalId,
        Proposal calldata proposal
    ) external onlyActiveMember onlyDelegateCall {
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
            uint256 globalMaxCancelDelay = _GLOBALS.getUint256(
                LibGlobals.GLOBAL_PROPOSAL_MAX_CANCEL_DURATION
            );
            uint256 globalMinCancelDelay = _GLOBALS.getUint256(
                LibGlobals.GLOBAL_PROPOSAL_MIN_CANCEL_DURATION
            );
            if (globalMaxCancelDelay != 0) {
                // Only if we have one set.
                if (cancelDelay > globalMaxCancelDelay) {
                    cancelDelay = globalMaxCancelDelay;
                }
            }
            if (globalMinCancelDelay != 0) {
                // Only if we have one set.
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
            (bool success, bytes memory resultData) = (address(_getProposalExecutionEngine()))
                .delegatecall(
                    abi.encodeCall(IProposalExecutionEngine.cancelProposal, (proposalId))
                );
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
    ) external payable onlyPartyDao onlyWhenEmergencyExecuteAllowed onlyDelegateCall {
        (bool success, bytes memory res) = targetAddress.call{ value: amountEth }(targetCallData);
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
    ) private returns (bool completed) {
        // Setup the arguments for the proposal execution engine.
        IProposalExecutionEngine.ExecuteProposalParams
            memory executeParams = IProposalExecutionEngine.ExecuteProposalParams({
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
            (bool success, bytes memory resultData) = address(_getProposalExecutionEngine())
                .delegatecall(
                    abi.encodeCall(IProposalExecutionEngine.executeProposal, (executeParams))
                );
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
    function _getVotingPowerSnapshotAt(
        address voter,
        uint40 timestamp,
        uint256 hintIndex
    ) internal view returns (VotingPowerSnapshot memory snap) {
        VotingPowerSnapshot[] storage snaps = _votingPowerSnapshotsByVoter[voter];
        uint256 snapsLength = snaps.length;
        if (snapsLength != 0) {
            if (
                // Hint is within bounds.
                hintIndex < snapsLength &&
                // Snapshot is not too recent.
                snaps[hintIndex].timestamp <= timestamp &&
                // Snapshot is not too old.
                (hintIndex == snapsLength - 1 || snaps[hintIndex + 1].timestamp > timestamp)
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
    function _transferVotingPower(address from, address to, uint256 power) internal {
        int192 powerI192 = power.safeCastUint256ToInt192();
        _adjustVotingPower(from, -powerI192, address(0));
        _adjustVotingPower(to, powerI192, address(0));
    }

    // Increase `voter`'s intrinsic voting power and update their delegate if delegate is nonzero.
    function _adjustVotingPower(address voter, int192 votingPower, address delegate) internal {
        VotingPowerSnapshot memory oldSnap = _getLastVotingPowerSnapshotForVoter(voter);
        address oldDelegate = delegationsByVoter[voter];
        // If `oldDelegate` is zero and `voter` never delegated, then have
        // `voter` delegate to themself.
        oldDelegate = oldDelegate == address(0) ? voter : oldDelegate;
        // If the new `delegate` is zero, use the current (old) delegate.
        delegate = delegate == address(0) ? oldDelegate : delegate;

        VotingPowerSnapshot memory newSnap = VotingPowerSnapshot({
            timestamp: uint40(block.timestamp),
            delegatedVotingPower: oldSnap.delegatedVotingPower,
            intrinsicVotingPower: (oldSnap.intrinsicVotingPower.safeCastUint96ToInt192() +
                votingPower).safeCastInt192ToUint96(),
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
    ) private {
        if (newDelegate == address(0) || oldDelegate == address(0)) {
            revert InvalidDelegateError();
        }
        if (oldDelegate != voter && oldDelegate != newDelegate) {
            // Remove past voting power from old delegate.
            VotingPowerSnapshot memory oldDelegateSnap = _getLastVotingPowerSnapshotForVoter(
                oldDelegate
            );
            VotingPowerSnapshot memory updatedOldDelegateSnap = VotingPowerSnapshot({
                timestamp: uint40(block.timestamp),
                delegatedVotingPower: oldDelegateSnap.delegatedVotingPower -
                    oldSnap.intrinsicVotingPower,
                intrinsicVotingPower: oldDelegateSnap.intrinsicVotingPower,
                isDelegated: oldDelegateSnap.isDelegated
            });
            _insertVotingPowerSnapshot(oldDelegate, updatedOldDelegateSnap);
        }
        if (newDelegate != voter) {
            // Not delegating to self.
            // Add new voting power to new delegate.
            VotingPowerSnapshot memory newDelegateSnap = _getLastVotingPowerSnapshotForVoter(
                newDelegate
            );
            uint96 newDelegateDelegatedVotingPower = newDelegateSnap.delegatedVotingPower +
                newSnap.intrinsicVotingPower;
            if (newDelegate == oldDelegate) {
                // If the old and new delegate are the same, subtract the old
                // intrinsic voting power of the voter, or else we will double
                // count a portion of it.
                newDelegateDelegatedVotingPower -= oldSnap.intrinsicVotingPower;
            }
            VotingPowerSnapshot memory updatedNewDelegateSnap = VotingPowerSnapshot({
                timestamp: uint40(block.timestamp),
                delegatedVotingPower: newDelegateDelegatedVotingPower,
                intrinsicVotingPower: newDelegateSnap.intrinsicVotingPower,
                isDelegated: newDelegateSnap.isDelegated
            });
            _insertVotingPowerSnapshot(newDelegate, updatedNewDelegateSnap);
        }
    }

    // Append a new voting power snapshot, overwriting the last one if possible.
    function _insertVotingPowerSnapshot(address voter, VotingPowerSnapshot memory snap) private {
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

    function _getLastVotingPowerSnapshotForVoter(
        address voter
    ) private view returns (VotingPowerSnapshot memory snap) {
        VotingPowerSnapshot[] storage voterSnaps = _votingPowerSnapshotsByVoter[voter];
        uint256 n = voterSnaps.length;
        if (n != 0) {
            snap = voterSnaps[n - 1];
        }
    }

    function _getProposalFlags(ProposalStateValues memory pv) private view returns (uint256) {
        if (_isUnanimousVotes(pv.votes, _governanceValues.totalVotingPower)) {
            return LibProposal.PROPOSAL_FLAG_UNANIMOUS;
        }
        return 0;
    }

    function _getProposalStatus(
        ProposalStateValues memory pv
    ) private view returns (ProposalStatus status) {
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

    function _isUnanimousVotes(
        uint96 totalVotes,
        uint96 totalVotingPower
    ) private pure returns (bool) {
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
    ) private pure returns (bool) {
        return (uint256(voteCount) * 1e4) / uint256(totalVotingPower) >= uint256(passThresholdBps);
    }

    function _setPreciousList(
        IERC721[] memory preciousTokens,
        uint256[] memory preciousTokenIds
    ) private {
        if (preciousTokens.length != preciousTokenIds.length) {
            revert MismatchedPreciousListLengths();
        }
        preciousListHash = _hashPreciousList(preciousTokens, preciousTokenIds);
    }

    function _isPreciousListCorrect(
        IERC721[] memory preciousTokens,
        uint256[] memory preciousTokenIds
    ) private view returns (bool) {
        return preciousListHash == _hashPreciousList(preciousTokens, preciousTokenIds);
    }

    function _hashPreciousList(
        IERC721[] memory preciousTokens,
        uint256[] memory preciousTokenIds
    ) internal pure returns (bytes32 h) {
        assembly {
            mstore(0x00, keccak256(add(preciousTokens, 0x20), mul(mload(preciousTokens), 0x20)))
            mstore(0x20, keccak256(add(preciousTokenIds, 0x20), mul(mload(preciousTokenIds), 0x20)))
            h := keccak256(0x00, 0x40)
        }
    }

    // Assert that the hash of a proposal matches expectedHash.
    function _validateProposalHash(Proposal memory proposal, bytes32 expectedHash) private pure {
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
contract PartyGovernanceNFT is PartyGovernance, ERC721, IERC2981 {
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
    mapping(uint256 => uint256) public votingPowerByTokenId;

    modifier onlyMinter() {
        address minter = mintAuthority;
        if (msg.sender != minter) {
            revert OnlyMintAuthorityError(msg.sender, minter);
        }
        _;
    }

    // Set the `Globals` contract. The name of symbol of ERC721 does not matter;
    // it will be set in `_initialize()`.
    constructor(IGlobals globals) PartyGovernance(globals) ERC721("", "") {
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
    ) internal {
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
    function ownerOf(
        uint256 tokenId
    ) public view override(ERC721, ITokenDistributorParty) returns (address owner) {
        return ERC721.ownerOf(tokenId);
    }

    /// @inheritdoc EIP165
    function supportsInterface(
        bytes4 interfaceId
    ) public pure override(PartyGovernance, ERC721, IERC165) returns (bool) {
        return
            PartyGovernance.supportsInterface(interfaceId) ||
            ERC721.supportsInterface(interfaceId) ||
            interfaceId == type(IERC2981).interfaceId;
    }

    /// @inheritdoc ERC721
    function tokenURI(uint256) public view override returns (string memory) {
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
    function royaltyInfo(uint256, uint256) external view returns (address, uint256) {
        _delegateToRenderer();
        return (address(0), 0); // Just to make the compiler happy.
    }

    /// @inheritdoc ITokenDistributorParty
    function getDistributionShareOf(uint256 tokenId) external view returns (uint256) {
        return (votingPowerByTokenId[tokenId] * 1e18) / _getTotalVotingPower();
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
    ) external onlyMinter onlyDelegateCall returns (uint256 tokenId) {
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
    function transferFrom(
        address owner,
        address to,
        uint256 tokenId
    ) public override onlyDelegateCall {
        // Transfer voting along with token.
        _transferVotingPower(owner, to, votingPowerByTokenId[tokenId]);
        super.transferFrom(owner, to, tokenId);
    }

    /// @inheritdoc ERC721
    function safeTransferFrom(
        address owner,
        address to,
        uint256 tokenId
    ) public override onlyDelegateCall {
        // super.safeTransferFrom() will call transferFrom() first which will
        // transfer voting power.
        super.safeTransferFrom(owner, to, tokenId);
    }

    /// @inheritdoc ERC721
    function safeTransferFrom(
        address owner,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) public override onlyDelegateCall {
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
    function executeProposal(
        ExecuteProposalParams memory params
    ) external returns (bytes memory nextProgressData);

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

    function isTokenPrecious(
        IERC721 token,
        IERC721[] memory preciousTokens
    ) internal pure returns (bool) {
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
    ) internal pure returns (bool) {
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
    uint256 private constant SHARED_STORAGE_SLOT =
        uint256(keccak256("ProposalStorage.SharedProposalStorage"));

    function _getProposalExecutionEngine() internal view returns (IProposalExecutionEngine impl) {
        return _getSharedProposalStorage().engineImpl;
    }

    function _setProposalExecutionEngine(IProposalExecutionEngine impl) internal {
        _getSharedProposalStorage().engineImpl = impl;
    }

    function _initProposalImpl(IProposalExecutionEngine impl, bytes memory initData) internal {
        SharedProposalStorage storage stor = _getSharedProposalStorage();
        IProposalExecutionEngine oldImpl = stor.engineImpl;
        stor.engineImpl = impl;
        (bool s, bytes memory r) = address(impl).delegatecall(
            abi.encodeCall(IProposalExecutionEngine.initialize, (address(oldImpl), initData))
        );
        if (!s) {
            r.rawRevert();
        }
    }

    function _getSharedProposalStorage() private pure returns (SharedProposalStorage storage stor) {
        uint256 s = SHARED_STORAGE_SLOT;
        assembly {
            stor.slot := s
        }
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

        files[CROWDFUND_CARD_DATA] = SSTORE2.write(
            bytes(
                '<path class="o" d="M118.4 419.5h5.82v1.73h-4.02v1.87h3.74v1.73h-3.74v1.94h4.11v1.73h-5.91v-9Zm9.93 1.76h-2.6v-1.76h7.06v1.76h-2.61v7.24h-1.85v-7.24Zm6.06-1.76h1.84v3.55h3.93v-3.55H142v9h-1.84v-3.67h-3.93v3.67h-1.84v-9Z"/><path class="o" d="M145 413a4 4 0 0 1 4 4v14a4 4 0 0 1-4 4H35a4 4 0 0 1-4-4v-14a4 4 0 0 1 4-4h110m0-1H35a5 5 0 0 0-5 5v14a5 5 0 0 0 5 5h110a5 5 0 0 0 5-5v-14a5 5 0 0 0-5-5Z"/><path d="M239.24 399.83h3.04c1.7 0 2.82 1 2.82 2.55 0 2.1-1.27 3.32-3.57 3.32h-1.97l-.71 3.3h-1.56l1.96-9.17Zm2.34 4.38c1.23 0 1.88-.58 1.88-1.68 0-.73-.49-1.2-1.48-1.2h-1.51l-.6 2.88h1.7Zm3.57 1.86c0-2.27 1.44-3.83 3.57-3.83 1.82 0 3.06 1.25 3.06 3.09 0 2.28-1.43 3.83-3.57 3.83-1.82 0-3.06-1.25-3.06-3.09Zm3.13 1.74c1.19 0 1.93-1.02 1.93-2.52 0-1.06-.62-1.69-1.56-1.69-1.19 0-1.93 1.02-1.93 2.52 0 1.06.62 1.69 1.56 1.69Zm4.74-5.41h1.49l.28 4.73 2.25-4.73h1.64l.23 4.77 2.25-4.77h1.56l-3.3 6.61h-1.62l-.25-5.04-2.42 5.04h-1.63l-.48-6.61Zm9.54 3.66c0-2.27 1.45-3.81 3.6-3.81 2 0 3.05 1.58 2.33 3.92h-4.46c0 1.1.81 1.68 2.05 1.68.8 0 1.45-.2 2.1-.59l-.31 1.46a4.2 4.2 0 0 1-2.04.44c-2.06 0-3.26-1.19-3.26-3.11Zm4.7-1.07c.12-.86-.31-1.46-1.22-1.46s-1.57.61-1.82 1.46h3.05Zm3.46-2.59h1.55l-.28 1.28c.81-1.7 2.56-1.36 2.77-1.29l-.35 1.46c-.18-.06-2.3-.63-2.82 1.68l-.74 3.48h-1.55l1.42-6.61Zm3.91 3.66c0-2.27 1.45-3.81 3.6-3.81 2 0 3.05 1.58 2.33 3.92h-4.46c0 1.1.81 1.68 2.05 1.68.8 0 1.45-.2 2.1-.59l-.31 1.46a4.2 4.2 0 0 1-2.04.44c-2.06 0-3.26-1.19-3.26-3.11Zm4.7-1.07c.12-.86-.31-1.46-1.22-1.46s-1.57.61-1.82 1.46h3.05Zm2.25 1.36c0-2.44 1.36-4.1 3.26-4.1 1 0 1.76.53 2.05 1.31l.79-3.72h1.55l-1.96 9.17h-1.55l.2-.92a2.15 2.15 0 0 1-1.92 1.08c-1.49 0-2.43-1.18-2.43-2.82Zm3 1.51c.88 0 1.51-.58 1.73-1.56l.17-.81c.24-1.1-.31-1.93-1.36-1.93-1.19 0-1.94 1.08-1.94 2.59 0 1.06.55 1.71 1.4 1.71Zm9.6-.01-.25 1.16h-1.55l1.96-9.17h1.55l-.73 3.47a2.35 2.35 0 0 1 1.99-1.05c1.49 0 2.35 1.16 2.35 2.76 0 2.52-1.36 4.16-3.21 4.16-.98 0-1.81-.53-2.1-1.32Zm1.83.01c1.16 0 1.87-1.06 1.87-2.61 0-1.04-.5-1.69-1.39-1.69s-1.52.56-1.73 1.55l-.17.79c-.24 1.14.34 1.97 1.42 1.97Zm5.68 1.16-1.04-6.62h1.52l.66 4.75 2.66-4.75h1.69l-5.31 9.13h-1.73l1.55-2.51Zm23.48-6.8a42.14 42.14 0 0 0-.75 6.01 43.12 43.12 0 0 0 5.58 2.35 42.54 42.54 0 0 0 5.58-2.35 45.32 45.32 0 0 0-.75-6.01c-.91-.79-2.6-2.21-4.83-3.66a42.5 42.5 0 0 0-4.83 3.66Zm13.07-7.95s.82-.29 1.76-.45a14.9 14.9 0 0 0-9.53-3.81c.66.71 1.28 1.67 1.84 2.75 1.84.22 4.07.7 5.92 1.51Zm-2.71 18.36c-2.06-.4-4.05-.97-5.53-1.51a38.65 38.65 0 0 1-5.53 1.51c.12 1.5.35 3.04.76 4.58 0 0 1.54 1.82 4.78 2.8 3.23-.98 4.78-2.8 4.78-2.8.4-1.53.64-3.08.76-4.58Zm-13.77-18.37a22.3 22.3 0 0 1 5.93-1.51 12.4 12.4 0 0 1 1.84-2.75 14.97 14.97 0 0 0-9.53 3.81c.95.16 1.76.45 1.76.45Zm-4.72 8.77a25.74 25.74 0 0 0 3.58 2.94 37.48 37.48 0 0 1 4.08-4.04c.27-1.56.77-3.57 1.46-5.55a25.24 25.24 0 0 0-4.34-1.63s-2.35.42-4.81 2.74c-.77 3.29.04 5.54.04 5.54Zm25.92 0s.81-2.25.04-5.54c-2.46-2.31-4.81-2.74-4.81-2.74-1.53.42-2.99.99-4.34 1.63a37.79 37.79 0 0 1 1.46 5.55 37.44 37.44 0 0 1 4.08 4.04 25.86 25.86 0 0 0 3.58-2.94Zm-26.38.2s-.66-.56-1.27-1.3c-.7 3.34-.27 6.93 1.46 10.16.28-.93.8-1.94 1.46-2.97a22.32 22.32 0 0 1-1.66-5.88Zm8.24 14.27a22.07 22.07 0 0 1-4.27-4.38c-1.22.06-2.36 0-3.3-.22a14.91 14.91 0 0 0 8.07 6.34c-.34-.9-.5-1.75-.5-1.75Zm18.6-14.27s.66-.56 1.27-1.3c.7 3.34.27 6.93-1.46 10.16-.28-.93-.8-1.94-1.46-2.97a22.32 22.32 0 0 0 1.66-5.88Zm-8.24 14.27a22.07 22.07 0 0 0 4.27-4.38c1.22.06 2.36 0 3.3-.22a14.91 14.91 0 0 1-8.07 6.34c.34-.9.5-1.75.5-1.75ZM330 391.84l-4.12 2.45 1.26 3.91h5.72l1.26-3.91-4.12-2.45Zm-11.4 19.74 4.18 2.35 2.75-3.05-2.86-4.95-4.02.86-.06 4.79Zm22.79 0-.06-4.79-4.02-.86-2.86 4.95 2.75 3.05 4.18-2.35Z" style="fill:#00c1fa"/><use height="300" transform="matrix(1 0 0 .09 29.85 444)" width="300.15" xlink:href="#a"/><use height="21.15" transform="translate(30 446.92)" width="300" xlink:href="#b"/><g><path d="m191.54 428.67-28.09-24.34A29.98 29.98 0 0 0 143.8 397H30a15 15 0 0 0-15 15v98a15 15 0 0 0 15 15h300a15 15 0 0 0 15-15v-59a15 15 0 0 0-15-15H211.19a30 30 0 0 1-19.65-7.33Z" style="fill:url(#i)"/></g></svg>'
            )
        );

        files[PARTY_CARD_DATA] = SSTORE2.write(
            bytes(
                ' d="M188 444.3h2.4l2.6 8.2 2.7-8.2h2.3l-3.7 10.7h-2.8l-3.5-10.7zm10.5 5.3c0-3.2 2.2-5.6 5.3-5.6 3.1 0 5.3 2.3 5.3 5.6 0 3.2-2.2 5.5-5.3 5.5-3.1.1-5.3-2.2-5.3-5.5zm5.3 3.5c1.8 0 3-1.3 3-3.4 0-2.1-1.1-3.5-3-3.5s-3 1.3-3 3.5c0 2.1 1.1 3.4 3 3.4zm8.7-6.7h-3.1v-2.1h8.4v2.1h-3.1v8.6h-2.2v-8.6zm6.9-2.1h2.2V455h-2.2v-10.7zm4.3 0h2.9l4 8.2v-8.2h2.1V455h-2.9l-4-8.2v8.2h-2.1v-10.7zm10.6 5.4c0-3.4 2.3-5.6 6-5.6 1.2 0 2.3.2 3.1.6v2.3c-.9-.6-1.9-.8-3.1-.8-2.4 0-3.8 1.3-3.8 3.5 0 2.1 1.3 3.4 3.5 3.4.5 0 .9-.1 1.3-.2v-2.2h-2.2v-1.9h4.3v5.6c-1 .5-2.2.8-3.4.8-3.5 0-5.7-2.2-5.7-5.5zm15.1-5.4h4.3c2.3 0 3.7 1.3 3.7 3.5s-1.4 3.5-3.7 3.5h-2.1v3.7h-2.2v-10.7zm4.1 5c1.1 0 1.6-.5 1.6-1.5s-.5-1.5-1.6-1.5h-1.9v2.9h1.9zm4.8.3c0-3.2 2.2-5.6 5.3-5.6 3.1 0 5.3 2.3 5.3 5.6 0 3.2-2.2 5.5-5.3 5.5-3.1.1-5.3-2.2-5.3-5.5zm5.3 3.5c1.8 0 3-1.3 3-3.4 0-2.1-1.1-3.5-3-3.5s-3 1.3-3 3.5c0 2.1 1.1 3.4 3 3.4zm5.8-8.8h2.3l1.7 7.8 1.9-7.8h2.4l1.8 7.8 1.8-7.8h2.3l-2.7 10.7h-2.5l-1.9-8.2-1.8 8.2h-2.5l-2.8-10.7zm15.4 0h6.9v2.1H287v2.2h4.5v2.1H287v2.3h4.9v2.1h-7v-10.8zm9 0h4.5c2 0 3.3 1.3 3.3 3.2 0 1.9-1.2 3.1-3 3.2l3.5 4.3h-2.7l-3.5-4.4v4.4h-2.1v-10.7zm4.1 4.8c1 0 1.5-.5 1.5-1.4 0-.9-.6-1.4-1.5-1.4h-2v2.9h2zM30 444.3h4.3c3 0 5.2 2.1 5.2 5.4s-2.1 5.4-5.2 5.4H30v-10.8zm4 8.6c2.1 0 3.2-1.2 3.2-3.2s-1.2-3.3-3.2-3.3h-1.8v6.5H34zm7.7-8.6h2.2V455h-2.2v-10.7zm4.8 10V452c1 .7 2.1 1.1 3.2 1.1s1.7-.5 1.7-1.2-.4-1-1.2-1.2l-1.2-.3c-1.8-.5-2.7-1.5-2.7-3.1 0-2 1.5-3.2 3.9-3.2 1 0 2.1.2 2.9.7v2.3c-.9-.6-1.9-.8-3-.8-.9 0-1.6.4-1.6 1.1 0 .6.4.9 1.2 1.1l1.3.4c1.8.5 2.6 1.4 2.6 3.1 0 2.1-1.5 3.4-3.8 3.4-1.1-.2-2.3-.5-3.3-1.1zm12-7.9h-3.1v-2.1h8.4v2.1h-3.1v8.6h-2.2v-8.6zm7.5-2.1h4.5c2 0 3.3 1.3 3.3 3.2 0 1.9-1.2 3.1-3 3.2l3.5 4.3h-2.7l-3.5-4.4v4.4H66v-10.7zm4.1 4.8c1 0 1.5-.5 1.5-1.4s-.6-1.4-1.5-1.4h-2v2.9h2zm6.1-4.8h2.2V455h-2.2v-10.7zm5 0h4.5c2 0 3.2 1.1 3.2 2.8 0 1.1-.5 1.9-1.4 2.3 1.1.3 1.8 1.3 1.8 2.5 0 1.9-1.3 3.1-3.5 3.1h-4.6v-10.7zm4.2 4.4c.9 0 1.4-.5 1.4-1.3s-.5-1.3-1.4-1.3h-2.1v2.5l2.1.1zm.3 4.4c.9 0 1.5-.5 1.5-1.3s-.6-1.3-1.5-1.3h-2.4v2.6h2.4zm5.7-2.5v-6.3h2.2v6.3c0 1.6.9 2.5 2.3 2.5s2.3-.9 2.3-2.5v-6.3h2.2v6.3c0 2.9-1.7 4.6-4.5 4.6s-4.6-1.7-4.5-4.6zm14.2-4.2h-3.1v-2.1h8.4v2.1h-3.1v8.6h-2.2v-8.6zm7.5-2.1h2.2V455h-2.2v-10.7zm4.5 5.3c0-3.2 2.2-5.6 5.3-5.6s5.3 2.3 5.3 5.6-2.2 5.5-5.3 5.5-5.3-2.2-5.3-5.5zm5.3 3.5c1.8 0 3-1.3 3-3.5s-1.2-3.5-3-3.5-3 1.3-3 3.5 1.1 3.5 3 3.5zm7.5-8.8h2.9l4 8.2v-8.2h2.1V455h-2.9l-4-8.2v8.2h-2.1v-10.7zm11.7 10V452c1 .7 2.1 1.1 3.2 1.1s1.7-.5 1.7-1.2-.4-1-1.2-1.2l-1.2-.3c-1.8-.5-2.6-1.5-2.6-3.1 0-2 1.5-3.2 3.9-3.2 1.1 0 2.1.2 2.9.7v2.3c-.9-.6-1.9-.8-3-.8-.9 0-1.6.4-1.6 1.1 0 .6.4.9 1.2 1.1l1.3.4c1.8.5 2.6 1.4 2.6 3.1 0 2.1-1.5 3.4-3.8 3.4a9.7 9.7 0 0 1-3.4-1.1zM30 259.3h4.3c2.2 0 3.7 1.3 3.7 3.5s-1.4 3.5-3.7 3.5h-2.1v3.7H30v-10.7zm4.1 5c1.1 0 1.6-.5 1.6-1.5s-.5-1.5-1.6-1.5h-1.9v2.9h1.9zm6.1-5h4.5c2 0 3.3 1.3 3.3 3.2 0 1.9-1.2 3.1-3 3.2l3.5 4.3h-2.7l-3.5-4.4v4.4h-2.1v-10.7zm4.1 4.8c1 0 1.5-.5 1.5-1.4s-.6-1.4-1.5-1.4h-2v2.9h2zm5.4.5c0-3.2 2.2-5.6 5.3-5.6s5.3 2.3 5.3 5.6-2.2 5.5-5.3 5.5-5.3-2.2-5.3-5.5zm5.3 3.5c1.8 0 3-1.3 3-3.5s-1.2-3.5-3-3.5-3 1.3-3 3.5 1.1 3.5 3 3.5zm7.6-8.8h4.3c2.2 0 3.7 1.3 3.7 3.5s-1.4 3.5-3.7 3.5h-2.1v3.7h-2.2v-10.7zm4.1 5c1.1 0 1.6-.5 1.6-1.5s-.6-1.5-1.6-1.5h-1.9v2.9h1.9zm5.4.4c0-3.2 2.2-5.6 5.3-5.6s5.3 2.3 5.3 5.6-2.2 5.5-5.3 5.5-5.3-2.3-5.3-5.5zm5.4 3.4c1.8 0 3-1.3 3-3.5s-1.2-3.5-3-3.5-3 1.3-3 3.5 1.1 3.5 3 3.5zm7.2 1.2V267c1 .7 2.1 1.1 3.2 1.1s1.7-.5 1.7-1.2-.4-1-1.2-1.2l-1.2-.3c-1.8-.5-2.7-1.5-2.7-3.1 0-2 1.5-3.2 3.9-3.2 1.1 0 2.1.2 2.9.7v2.3c-.9-.6-1.9-.8-3-.8-.9 0-1.6.4-1.6 1.1 0 .6.4.9 1.2 1.1l1.3.4c1.8.5 2.6 1.4 2.6 3.1 0 2.1-1.5 3.4-3.8 3.4-1.1-.2-2.3-.5-3.3-1.1zm12.2-10h2.8l3.7 10.7h-2.3l-.8-2.5h-4l-.8 2.5h-2.2l3.6-10.7zm2.8 6.3-1.4-4.2-1.4 4.2h2.8zm5.7-6.3h2.2v8.6h4.7v2.1h-6.9v-10.7zm9.1 10V267c1 .7 2.1 1.1 3.2 1.1s1.7-.5 1.7-1.2-.4-1-1.2-1.2l-1.2-.3c-1.8-.5-2.7-1.5-2.7-3.1 0-2 1.5-3.2 3.9-3.2 1.1 0 2.1.2 2.9.7v2.3c-.9-.6-1.9-.8-3-.8-.9 0-1.6.4-1.6 1.1 0 .6.4.9 1.2 1.1l1.3.4c1.8.5 2.6 1.4 2.6 3.1 0 2.1-1.5 3.4-3.8 3.4-1.1-.2-2.3-.5-3.3-1.1zm-84.5-70h2.9l4 8.2v-8.2H39V210h-2.9l-4-8.2v8.2H30v-10.7zm14.7 0h2.8l3.7 10.7h-2.3l-.8-2.6h-4l-.8 2.6H41l3.7-10.7zm2.8 6.2-1.4-4.2-1.4 4.2h2.8zm5.7-6.2h3.3l2.5 8.2 2.5-8.2h3.3V210h-2v-8.6L60 210h-2.1l-2.7-8.5v8.5h-2v-10.7zm14.4 0h6.9v2.1h-4.8v2.2h4.4v2.1h-4.4v2.3h4.9v2.1h-7v-10.8z" /><path d="M239.24 24.83h3.04c1.7 0 2.82 1 2.82 2.55 0 2.1-1.27 3.32-3.57 3.32h-1.97l-.71 3.3h-1.56l1.96-9.17Zm2.34 4.38c1.23 0 1.88-.58 1.88-1.68 0-.73-.49-1.2-1.48-1.2h-1.51l-.6 2.88h1.7Zm3.57 1.86c0-2.27 1.44-3.83 3.57-3.83 1.82 0 3.06 1.25 3.06 3.09 0 2.28-1.43 3.83-3.57 3.83-1.82 0-3.06-1.25-3.06-3.09Zm3.13 1.74c1.19 0 1.93-1.02 1.93-2.52 0-1.06-.62-1.69-1.56-1.69-1.19 0-1.93 1.02-1.93 2.52 0 1.06.62 1.69 1.56 1.69Zm4.74-5.41h1.49l.28 4.73 2.25-4.73h1.64l.23 4.77 2.25-4.77h1.56l-3.3 6.61h-1.62l-.25-5.04-2.42 5.04h-1.63l-.48-6.61Zm9.54 3.66c0-2.27 1.45-3.81 3.6-3.81 2 0 3.05 1.58 2.33 3.92h-4.46c0 1.1.81 1.68 2.05 1.68.8 0 1.45-.2 2.1-.59l-.31 1.46a4.2 4.2 0 0 1-2.04.44c-2.06 0-3.26-1.19-3.26-3.11Zm4.7-1.07c.12-.86-.31-1.46-1.22-1.46s-1.57.61-1.82 1.46h3.05Zm3.46-2.59h1.55l-.28 1.28c.81-1.7 2.56-1.36 2.77-1.29l-.35 1.46c-.18-.06-2.3-.63-2.82 1.68l-.74 3.48h-1.55l1.42-6.61Zm3.91 3.66c0-2.27 1.45-3.81 3.6-3.81 2 0 3.05 1.58 2.33 3.92h-4.46c0 1.1.81 1.68 2.05 1.68.8 0 1.45-.2 2.1-.59l-.31 1.46a4.2 4.2 0 0 1-2.04.44c-2.06 0-3.26-1.19-3.26-3.11Zm4.7-1.07c.12-.86-.31-1.46-1.22-1.46s-1.57.61-1.82 1.46h3.05Zm2.25 1.36c0-2.44 1.36-4.1 3.26-4.1 1 0 1.76.53 2.05 1.31l.79-3.72h1.55l-1.96 9.17h-1.55l.2-.92a2.15 2.15 0 0 1-1.92 1.08c-1.49 0-2.43-1.18-2.43-2.82Zm3 1.51c.88 0 1.51-.58 1.73-1.56l.17-.81c.24-1.1-.31-1.93-1.36-1.93-1.19 0-1.94 1.08-1.94 2.59 0 1.06.55 1.71 1.4 1.71Zm9.6-.01-.25 1.16h-1.55l1.96-9.17h1.55l-.73 3.47a2.35 2.35 0 0 1 1.99-1.05c1.49 0 2.35 1.16 2.35 2.76 0 2.52-1.36 4.16-3.21 4.16-.98 0-1.81-.53-2.1-1.32Zm1.83.01c1.16 0 1.87-1.06 1.87-2.61 0-1.04-.5-1.69-1.39-1.69s-1.52.56-1.73 1.55l-.17.79c-.24 1.14.34 1.97 1.42 1.97Zm5.68 1.16-1.04-6.62h1.52l.66 4.75 2.66-4.75h1.69l-5.31 9.13h-1.73l1.55-2.51Zm23.47-6.8c.91-.79 2.6-2.21 4.83-3.66a42.5 42.5 0 0 1 4.83 3.66c.23 1.18.62 3.36.75 6.01a43.12 43.12 0 0 1-5.58 2.35 42.54 42.54 0 0 1-5.58-2.35c.14-2.65.53-4.83.75-6.01Zm13.07-7.95s.82-.29 1.76-.45a14.9 14.9 0 0 0-9.53-3.81c.66.71 1.28 1.67 1.84 2.75 1.84.22 4.07.7 5.92 1.51Zm-2.71 18.36c-2.06-.4-4.05-.97-5.53-1.51a38.65 38.65 0 0 1-5.53 1.51c.12 1.5.35 3.04.76 4.58 0 0 1.54 1.82 4.78 2.8 3.23-.98 4.78-2.8 4.78-2.8.4-1.53.64-3.08.76-4.58Zm-13.77-18.37a22.3 22.3 0 0 1 5.93-1.51 12.4 12.4 0 0 1 1.84-2.75 14.97 14.97 0 0 0-9.53 3.81c.95.16 1.76.45 1.76.45Zm-4.72 8.77a25.74 25.74 0 0 0 3.58 2.94 37.48 37.48 0 0 1 4.08-4.04c.27-1.56.77-3.57 1.46-5.55a25.24 25.24 0 0 0-4.34-1.63s-2.35.42-4.81 2.74c-.77 3.29.04 5.54.04 5.54Zm25.92 0s.81-2.25.04-5.54c-2.46-2.31-4.81-2.74-4.81-2.74-1.53.42-2.99.99-4.34 1.63a37.79 37.79 0 0 1 1.46 5.55 37.44 37.44 0 0 1 4.08 4.04 25.86 25.86 0 0 0 3.58-2.94Zm-26.38.2s-.66-.56-1.27-1.3c-.7 3.34-.27 6.93 1.46 10.16.28-.93.8-1.94 1.46-2.97a22.32 22.32 0 0 1-1.66-5.88Zm8.24 14.27a22.07 22.07 0 0 1-4.27-4.38c-1.22.06-2.36 0-3.3-.22a14.91 14.91 0 0 0 8.07 6.34c-.34-.9-.5-1.75-.5-1.75Zm18.6-14.27s.66-.56 1.27-1.3c.7 3.34.27 6.93-1.46 10.16-.28-.93-.8-1.94-1.46-2.97a22.32 22.32 0 0 0 1.66-5.88Zm-8.24 14.27a22.07 22.07 0 0 0 4.27-4.38c1.22.06 2.36 0 3.3-.22a14.91 14.91 0 0 1-8.07 6.34c.34-.9.5-1.75.5-1.75Zm-5.18-25.66-4.12 2.45 1.26 3.91h5.72l1.26-3.91-4.12-2.45Zm-11.4 19.74 4.18 2.35 2.75-3.05-2.86-4.95-4.02.86-.06 4.79Zm22.79 0-.06-4.79-4.02-.86-2.86 4.95 2.75 3.05 4.18-2.35Z" style="fill:#00c1fa"/><path d="M106.67 109.1a304.9 304.9 0 0 0-3.72-10.89c5.04-5.53 35.28-40.74 24.54-68.91 10.57 10.67 8.19 28.85 3.59 41.95-4.79 13.14-13.43 26.48-24.4 37.84Zm30.89 20.82c-5.87 6.12-20.46 17.92-21.67 18.77a99.37 99.37 0 0 0 7.94 6.02 133.26 133.26 0 0 0 20.09-18.48 353.47 353.47 0 0 0-6.36-6.31Zm-29.65-16.74a380.9 380.9 0 0 1 3.13 11.56c-4.8-1.37-8.66-2.53-12.36-3.82a123.4 123.4 0 0 1-21.16 13.21l15.84 5.47c14.83-8.23 28.13-20.82 37.81-34.68 0 0 8.56-12.55 12.42-23.68 2.62-7.48 4.46-16.57 3.49-24.89-2.21-12.27-6.95-15.84-9.32-17.66 6.16 5.72 3.25 27.8-2.79 39.89-6.08 12.16-15.73 24.27-27.05 34.59Zm59.05-37.86c-.03 7.72-3.05 15.69-6.44 22.69 1.7 2.2 3.18 4.36 4.42 6.49 7.97-16.51 3.74-26.67 2.02-29.18ZM61.18 128.51l12.5 4.3a101.45 101.45 0 0 0 21.42-13.19 163.26 163.26 0 0 1-10.61-4.51 101.28 101.28 0 0 1-23.3 13.4Zm87.78-42.73c.86.77 5.44 5.18 6.75 6.59 6.39-16.61.78-28.86-1.27-30.56.72 8.05-2.02 16.51-5.48 23.98Zm-14.29 40.62-2.47-15.18a142.42 142.42 0 0 1-35.74 29.45c6.81 2.36 12.69 4.4 15.45 5.38a115.98 115.98 0 0 0 22.75-19.66Zm-42.62 34.73c4.48 2.93 12.94 4.24 18.8 1.23 6.03-3.84-.6-8.34-8.01-9.88-9.8-2.03-16.82 1.22-13.4 6.21.41.6 1.19 1.5 2.62 2.44m-1.84.4c-3.56-2.37-6.77-7.2-.23-10.08 10.41-3.43 28.39 3.2 24.99 9.22-.58 1.04-1.46 1.6-2.38 2.19h-.03v.02h-.03v.02h-.03c-7.04 3.65-17.06 2.13-22.3-1.36m5.48-3.86a4.94 4.94 0 0 0 5.06.49l1.35-.74-4.68-2.38-1.47.79c-.38.22-1.53.88-.26 1.84m-1.7.59c-2.35-1.57-.78-2.61-.02-3.11 1.09-.57 2.19-1.15 3.28-1.77 6.95 3.67 7.22 3.81 13.19 6.17l-1.38.81c-1.93-.78-4.52-1.82-6.42-2.68.86 1.4 1.99 3.27 2.9 4.64l-1.68.87c-.75-1.28-1.76-2.99-2.47-4.29-3.19 2.06-6.99-.36-7.42-.64" style="fill:url(#f2)"/><path d="M159.13 52.37C143.51 24.04 119.45 15 103.6 15c-11.92 0-25.97 5.78-36.84 13.17 9.54 4.38 21.86 15.96 22.02 16.11-7.94-3.05-17.83-6.72-33.23-7.87a135.1 135.1 0 0 0-19.77 20.38c.77 7.66 2.88 15.68 2.88 15.68-6.28-4.75-11.02-4.61-18 9.45-5.4 12.66-6.93 24.25-4.65 33.18 0 0 4.72 26.8 36.23 40.07-1.3-4.61-1.58-9.91-.93-15.73a87.96 87.96 0 0 1-15.63-9.87c.79-6.61 2.79-13.82 6-21.36 4.42-10.66 4.35-15.14 4.35-15.19.03.07 5.48 12.43 12.95 22.08 4.23-8.84 9.46-16.08 13.67-21.83l-3.77-6.75a143.73 143.73 0 0 1 18.19-18.75c2.05 1.07 4.79 2.47 6.84 3.58 8.68-7.27 19.25-14.05 30.56-18.29-7-11.49-16.02-19.27-16.02-19.27s27.7 2.74 42.02 15.69a25.8 25.8 0 0 1 8.65 2.89ZM28.58 107.52a70.1 70.1 0 0 0-2.74 12.52 55.65 55.65 0 0 1-6.19-8.84 69.17 69.17 0 0 1 2.65-12.1c1.77-5.31 3.35-5.91 5.86-2.23v-.05c2.14 3.07 1.81 6.14.42 10.7ZM61.69 72.2l-.05.05a221.85 221.85 0 0 1-7.77-18.1l.14-.14a194.51 194.51 0 0 1 18.56 6.98 144.44 144.44 0 0 0-10.88 11.22Zm54.84-47.38c-4.42.7-9.02 1.95-13.67 3.72a65.03 65.03 0 0 0-7.81-5.31 66.04 66.04 0 0 1 13.02-3.54c1.53-.19 6.23-.79 10.32 2.42v-.05c2.47 1.91.14 2.37-1.86 2.75Z" style="fill:url(#h)"/>'
            )
        );
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
    function createCustomizationPreset(
        uint256 id,
        bytes memory customizationData
    ) external onlyOwner {
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
    function supportsInterface(bytes4 interfaceId) public pure virtual override returns (bool) {
        return
            super.supportsInterface(interfaceId) ||
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
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override(IERC721Receiver, ERC721TokenReceiver) returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    /// @inheritdoc EIP165
    function supportsInterface(bytes4 interfaceId) public pure virtual override returns (bool) {
        return
            EIP165.supportsInterface(interfaceId) ||
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

    function balanceOfBatch(
        address[] calldata owners,
        uint256[] calldata ids
    ) external view returns (uint256[] memory balances);
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

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

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
    function supportsInterface(bytes4 interfaceId) public pure virtual returns (bool) {
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

    constructor() {
        IMPL = address(this);
    }

    // Reverts if the current function context is not inside of a delegatecall.
    modifier onlyDelegateCall() virtual {
        if (address(this) == IMPL) {
            revert OnlyDelegateCallError();
        }
        _;
    }

    // Reverts if the current function context is not inside of a constructor.
    modifier onlyConstructor() {
        if (address(this).code.length != 0) {
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
    function transferEth(address payable receiver, uint256 amount) internal {
        if (amount == 0) return;

        (bool s, bytes memory r) = receiver.call{ value: amount }("");
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
    function compatTransfer(IERC20 token, address to, uint256 amount) internal {
        (bool s, bytes memory r) = address(token).call(
            abi.encodeCall(IERC20.transfer, (to, amount))
        );
        if (s) {
            if (r.length == 0) {
                uint256 cs;
                assembly {
                    cs := extcodesize(token)
                }
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
    function rawRevert(bytes memory b) internal pure {
        assembly {
            revert(add(b, 32), mload(b))
        }
    }

    // Return with the data in `b`.
    function rawReturn(bytes memory b) internal pure {
        assembly {
            return(add(b, 32), mload(b))
        }
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

    function safeCastUint256ToInt128(uint256 x) internal pure returns (int128) {
        if (x > uint256(uint128(type(int128).max))) {
            revert Uint256ToInt128CastOutOfRangeError(x);
        }
        return int128(uint128(x));
    }

    function safeCastUint256ToUint40(uint256 x) internal pure returns (uint40) {
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
    function safeOwnerOf(IERC721 token, uint256 tokenId) internal view returns (address owner) {
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
    function delegateCallAndRevert(address impl, bytes memory callData) external view;
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
        } catch (bytes memory r) {
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
                : ERC1155TokenReceiverBase(to).onERC1155Received(
                    msg.sender,
                    from,
                    id,
                    amount,
                    data
                ) == ERC1155TokenReceiverBase.onERC1155Received.selector,
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
                : ERC1155TokenReceiverBase(to).onERC1155BatchReceived(
                    msg.sender,
                    from,
                    ids,
                    amounts,
                    data
                ) == ERC1155TokenReceiverBase.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function balanceOfBatch(
        address[] calldata owners,
        uint256[] calldata ids
    ) public view virtual returns (uint256[] memory balances) {
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

    function _mint(address to, uint256 id, uint256 amount, bytes memory data) internal virtual {
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, address(0), to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiverBase(to).onERC1155Received(
                    msg.sender,
                    address(0),
                    id,
                    amount,
                    data
                ) == ERC1155TokenReceiverBase.onERC1155Received.selector,
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
                : ERC1155TokenReceiverBase(to).onERC1155BatchReceived(
                    msg.sender,
                    address(0),
                    ids,
                    amounts,
                    data
                ) == ERC1155TokenReceiverBase.onERC1155BatchReceived.selector,
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

    function _burn(address from, uint256 id, uint256 amount) internal virtual {
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

    function tokenURI(uint256 id /* view */) public virtual returns (string memory);

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

    function transferFrom(address from, address to, uint256 id) public virtual {
        require(from == _ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from ||
                isApprovedForAll[from][msg.sender] ||
                msg.sender == getApproved[id],
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

    function safeTransferFrom(address from, address to, uint256 id) public virtual {
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
        return
            super.supportsInterface(interfaceId) ||
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

    function _safeMint(address to, uint256 id, bytes memory data) internal virtual {
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The tree and the proofs can be generated using our
 * https://github.com/OpenZeppelin/merkle-tree[JavaScript library].
 * You will find a quickstart guide in the readme.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 * OpenZeppelin's JavaScript library generates merkle trees that are safe
 * against this attack out of the box.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be simultaneously proven to be a part of a merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and sibling nodes in `proof`. The reconstruction
     * proceeds by incrementally reconstructing all inner nodes by combining a leaf/inner node with either another
     * leaf/inner node or a proof sibling node, depending on whether each `proofFlags` item is true or false
     * respectively.
     *
     * CAUTION: Not all merkle trees admit multiproofs. To use multiproofs, it is sufficient to ensure that: 1) the tree
     * is complete (but not necessarily perfect), 2) the leaves to be proven are in the opposite order they are in the
     * tree (i.e., as seen from right to left starting at the deepest layer and continuing at the next layer).
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuilds the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i]
                ? (leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++])
                : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuilds the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i]
                ? (leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++])
                : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
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

        /// @solidity memory-safe-assembly
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
        /// @solidity memory-safe-assembly
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