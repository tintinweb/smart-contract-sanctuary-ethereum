// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {LSSVMPairETH} from "./LSSVMPairETH.sol";
import {LSSVMPairMissingEnumerable} from "./LSSVMPairMissingEnumerable.sol";
import {ILSSVMPairFactoryLike} from "./ILSSVMPairFactoryLike.sol";

contract LSSVMPairMissingEnumerableETH is
    LSSVMPairMissingEnumerable,
    LSSVMPairETH
{
    function pairVariant()
        public
        pure
        override
        returns (ILSSVMPairFactoryLike.PairVariant)
    {
        return ILSSVMPairFactoryLike.PairVariant.MISSING_ENUMERABLE_ETH;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {ERC20} from "@rari-capital/solmate/src/tokens/ERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {SafeTransferLib} from "@rari-capital/solmate/src/utils/SafeTransferLib.sol";
import {LSSVMPair} from "./LSSVMPair.sol";
import {ILSSVMPairFactoryLike} from "./ILSSVMPairFactoryLike.sol";
import {ICurve} from "./bonding-curves/ICurve.sol";

/**
    @title An NFT/Token pair where the token is ETH
    @author boredGenius and 0xmons
 */
abstract contract LSSVMPairETH is LSSVMPair {
    using SafeTransferLib for address payable;
    using SafeTransferLib for ERC20;

    uint256 internal constant IMMUTABLE_PARAMS_LENGTH = 61;

    /// @inheritdoc LSSVMPair
    function _pullTokenInputAndPayProtocolFee(
        uint256 inputAmount,
        bool, /*isRouter*/
        address, /*routerCaller*/
        ILSSVMPairFactoryLike _factory,
        uint256 protocolFee
    ) internal override {
        require(msg.value >= inputAmount, "Sent too little ETH");

        // Transfer inputAmount ETH to assetRecipient if it's been set
        address payable _assetRecipient = getAssetRecipient();
        if (_assetRecipient != address(this)) {
            _assetRecipient.safeTransferETH(inputAmount - protocolFee);
        }

        // Take protocol fee
        if (protocolFee > 0) {
            // Round down to the actual ETH balance if there are numerical stability issues with the bonding curve calculations
            if (protocolFee > address(this).balance) {
                protocolFee = address(this).balance;
            }

            if (protocolFee > 0) {
                payable(address(_factory)).safeTransferETH(protocolFee);
            }
        }
    }

    /// @inheritdoc LSSVMPair
    function _refundTokenToSender(uint256 inputAmount) internal override {
        // Give excess ETH back to caller
        if (msg.value > inputAmount) {
            payable(msg.sender).safeTransferETH(msg.value - inputAmount);
        }
    }

    /// @inheritdoc LSSVMPair
    function _payProtocolFeeFromPair(
        ILSSVMPairFactoryLike _factory,
        uint256 protocolFee
    ) internal override {
        // Take protocol fee
        if (protocolFee > 0) {
            // Round down to the actual ETH balance if there are numerical stability issues with the bonding curve calculations
            if (protocolFee > address(this).balance) {
                protocolFee = address(this).balance;
            }

            if (protocolFee > 0) {
                payable(address(_factory)).safeTransferETH(protocolFee);
            }
        }
    }

    /// @inheritdoc LSSVMPair
    function _sendTokenOutput(
        address payable tokenRecipient,
        uint256 outputAmount
    ) internal override {
        // Send ETH to caller
        if (outputAmount > 0) {
            tokenRecipient.safeTransferETH(outputAmount);
        }
    }

    /// @inheritdoc LSSVMPair
    // @dev see LSSVMPairCloner for params length calculation
    function _immutableParamsLength() internal pure override returns (uint256) {
        return IMMUTABLE_PARAMS_LENGTH;
    }

    /**
        @notice Withdraws all token owned by the pair to the owner address.
        @dev Only callable by the owner.
     */
    function withdrawAllETH() external onlyOwner {
        withdrawETH(address(this).balance);
    }

    /**
        @notice Withdraws a specified amount of token owned by the pair to the owner address.
        @dev Only callable by the owner.
        @param amount The amount of token to send to the owner. If the pair's balance is less than
        this value, the transaction will be reverted.
     */
    function withdrawETH(uint256 amount) public onlyOwner {
        payable(owner()).safeTransferETH(amount);

        // emit event since ETH is the pair token
        emit TokenWithdrawal(amount);
    }

    /// @inheritdoc LSSVMPair
    function withdrawERC20(ERC20 a, uint256 amount)
        external
        override
        onlyOwner
    {
        a.safeTransfer(msg.sender, amount);
    }

    /**
        @dev All ETH transfers into the pair are accepted. This is the main method
        for the owner to top up the pair's token reserves.
     */
    receive() external payable {
        emit TokenDeposit(msg.value);
    }

    /**
        @dev All ETH transfers into the pair are accepted. This is the main method
        for the owner to top up the pair's token reserves.
     */
    fallback() external payable {
        // Only allow calls without function selector
        require (msg.data.length == _immutableParamsLength()); 
        emit TokenDeposit(msg.value);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {LSSVMRouter} from "./LSSVMRouter.sol";

interface ILSSVMPairFactoryLike {
    enum PairVariant {
        ENUMERABLE_ETH,
        MISSING_ENUMERABLE_ETH,
        ENUMERABLE_ERC20,
        MISSING_ENUMERABLE_ERC20
    }

    function protocolFeeMultiplier() external view returns (uint256);

    function protocolFeeRecipient() external view returns (address payable);

    function callAllowed(address target) external view returns (bool);

    function routerStatus(LSSVMRouter router)
        external
        view
        returns (bool allowed, bool wasEverAllowed);

    function isPair(address potentialPair, PairVariant variant)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {LSSVMPair} from "./LSSVMPair.sol";
import {LSSVMRouter} from "./LSSVMRouter.sol";
import {ILSSVMPairFactoryLike} from "./ILSSVMPairFactoryLike.sol";

/**
    @title An NFT/Token pair for an NFT that does not implement ERC721Enumerable
    @author boredGenius and 0xmons
 */
abstract contract LSSVMPairMissingEnumerable is LSSVMPair {
    using EnumerableSet for EnumerableSet.UintSet;

    // Used for internal ID tracking
    EnumerableSet.UintSet private idSet;

    /// @inheritdoc LSSVMPair
    function _sendAnyNFTsToRecipient(
        IERC721 _nft,
        address nftRecipient,
        uint256 numNFTs
    ) internal override {
        // Send NFTs to recipient
        // We're missing enumerable, so we also update the pair's own ID set
        // NOTE: We start from last index to first index to save on gas
        uint256 lastIndex = idSet.length() - 1;
        for (uint256 i; i < numNFTs; ) {
            uint256 nftId = idSet.at(lastIndex);
            _nft.safeTransferFrom(address(this), nftRecipient, nftId);
            idSet.remove(nftId);

            unchecked {
                --lastIndex;
                ++i;
            }
        }
    }

    /// @inheritdoc LSSVMPair
    function _sendSpecificNFTsToRecipient(
        IERC721 _nft,
        address nftRecipient,
        uint256[] calldata nftIds
    ) internal override {
        // Send NFTs to caller
        // If missing enumerable, update pool's own ID set
        uint256 numNFTs = nftIds.length;
        for (uint256 i; i < numNFTs; ) {
            _nft.safeTransferFrom(address(this), nftRecipient, nftIds[i]);
            // Remove from id set
            idSet.remove(nftIds[i]);

            unchecked {
                ++i;
            }
        }
    }

    /// @inheritdoc LSSVMPair
    function getAllHeldIds() external view override returns (uint256[] memory) {
        uint256 numNFTs = idSet.length();
        uint256[] memory ids = new uint256[](numNFTs);
        for (uint256 i; i < numNFTs; ) {
            ids[i] = idSet.at(i);

            unchecked {
                ++i;
            }
        }
        return ids;
    }

    /**
        @dev When safeTransfering an ERC721 in, we add ID to the idSet
        if it's the same collection used by pool. (As it doesn't auto-track because no ERC721Enumerable)
     */
    function onERC721Received(
        address,
        address,
        uint256 id,
        bytes memory
    ) public virtual returns (bytes4) {
        IERC721 _nft = nft();
        // If it's from the pair's NFT, add the ID to ID set
        if (msg.sender == address(_nft)) {
            idSet.add(id);
        }
        return this.onERC721Received.selector;
    }

    /// @inheritdoc LSSVMPair
    function withdrawERC721(IERC721 a, uint256[] calldata nftIds)
        external
        override
        onlyOwner
    {
        IERC721 _nft = nft();
        uint256 numNFTs = nftIds.length;

        // If it's not the pair's NFT, just withdraw normally
        if (a != _nft) {
            for (uint256 i; i < numNFTs; ) {
                a.safeTransferFrom(address(this), msg.sender, nftIds[i]);

                unchecked {
                    ++i;
                }
            }
        }
        // Otherwise, withdraw and also remove the ID from the ID set
        else {
            for (uint256 i; i < numNFTs; ) {
                _nft.safeTransferFrom(address(this), msg.sender, nftIds[i]);
                idSet.remove(nftIds[i]);

                unchecked {
                    ++i;
                }
            }

            emit NFTWithdrawal();
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {ERC20} from "@rari-capital/solmate/src/tokens/ERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {OwnableWithTransferCallback} from "./lib/OwnableWithTransferCallback.sol";
import {ReentrancyGuard} from "./lib/ReentrancyGuard.sol";
import {ICurve} from "./bonding-curves/ICurve.sol";
import {LSSVMRouter} from "./LSSVMRouter.sol";
import {ILSSVMPairFactoryLike} from "./ILSSVMPairFactoryLike.sol";
import {CurveErrorCodes} from "./bonding-curves/CurveErrorCodes.sol";
import {ERC1155Holder} from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

/// @title The base contract for an NFT/TOKEN AMM pair
/// @author boredGenius and 0xmons
/// @notice This implements the core swap logic from NFT to TOKEN
abstract contract LSSVMPair is
    OwnableWithTransferCallback,
    ReentrancyGuard,
    ERC1155Holder
{
    enum PoolType {
        TOKEN,
        NFT,
        TRADE
    }

    // 90%, must <= 1 - MAX_PROTOCOL_FEE (set in LSSVMPairFactory)
    uint256 internal constant MAX_FEE = 0.90e18;

    // The current price of the NFT
    // @dev This is generally used to mean the immediate sell price for the next marginal NFT.
    // However, this should NOT be assumed, as future bonding curves may use spotPrice in different ways.
    // Use getBuyNFTQuote and getSellNFTQuote for accurate pricing info.
    uint128 public spotPrice;

    // The parameter for the pair's bonding curve.
    // Units and meaning are bonding curve dependent.
    uint128 public delta;

    // The spread between buy and sell prices, set to be a multiplier we apply to the buy price
    // Fee is only relevant for TRADE pools
    // Units are in base 1e18
    uint96 public fee;

    // If set to 0, NFTs/tokens sent by traders during trades will be sent to the pair.
    // Otherwise, assets will be sent to the set address. Not available for TRADE pools.
    address payable public assetRecipient;

    // Events
    event SwapNFTInPair();
    event SwapNFTOutPair();
    event SpotPriceUpdate(uint128 newSpotPrice);
    event TokenDeposit(uint256 amount);
    event TokenWithdrawal(uint256 amount);
    event NFTWithdrawal();
    event DeltaUpdate(uint128 newDelta);
    event FeeUpdate(uint96 newFee);
    event AssetRecipientChange(address a);

    // Parameterized Errors
    error BondingCurveError(CurveErrorCodes.Error error);

    /**
      @notice Called during pair creation to set initial parameters
      @dev Only called once by factory to initialize.
      We verify this by making sure that the current owner is address(0). 
      The Ownable library we use disallows setting the owner to be address(0), so this condition
      should only be valid before the first initialize call. 
      @param _owner The owner of the pair
      @param _assetRecipient The address that will receive the TOKEN or NFT sent to this pair during swaps. NOTE: If set to address(0), they will go to the pair itself.
      @param _delta The initial delta of the bonding curve
      @param _fee The initial % fee taken, if this is a trade pair 
      @param _spotPrice The initial price to sell an asset into the pair
     */
    function initialize(
        address _owner,
        address payable _assetRecipient,
        uint128 _delta,
        uint96 _fee,
        uint128 _spotPrice
    ) external payable {
        require(owner() == address(0), "Initialized");
        __Ownable_init(_owner);
        __ReentrancyGuard_init();

        ICurve _bondingCurve = bondingCurve();
        PoolType _poolType = poolType();

        if ((_poolType == PoolType.TOKEN) || (_poolType == PoolType.NFT)) {
            require(_fee == 0, "Only Trade Pools can have nonzero fee");
            assetRecipient = _assetRecipient;
        } else if (_poolType == PoolType.TRADE) {
            require(_fee < MAX_FEE, "Trade fee must be less than 90%");
            require(
                _assetRecipient == address(0),
                "Trade pools can't set asset recipient"
            );
            fee = _fee;
        }
        require(_bondingCurve.validateDelta(_delta), "Invalid delta for curve");
        require(
            _bondingCurve.validateSpotPrice(_spotPrice),
            "Invalid new spot price for curve"
        );
        delta = _delta;
        spotPrice = _spotPrice;
    }

    /**
     * External state-changing functions
     */

    /**
        @notice Sends token to the pair in exchange for any `numNFTs` NFTs
        @dev To compute the amount of token to send, call bondingCurve.getBuyInfo.
        This swap function is meant for users who are ID agnostic
        @param numNFTs The number of NFTs to purchase
        @param maxExpectedTokenInput The maximum acceptable cost from the sender. If the actual
        amount is greater than this value, the transaction will be reverted.
        @param nftRecipient The recipient of the NFTs
        @param isRouter True if calling from LSSVMRouter, false otherwise. Not used for
        ETH pairs.
        @param routerCaller If isRouter is true, ERC20 tokens will be transferred from this address. Not used for
        ETH pairs.
        @return inputAmount The amount of token used for purchase
     */
    function swapTokenForAnyNFTs(
        uint256 numNFTs,
        uint256 maxExpectedTokenInput,
        address nftRecipient,
        bool isRouter,
        address routerCaller
    ) external payable virtual nonReentrant returns (uint256 inputAmount) {
        // Store locally to remove extra calls
        ILSSVMPairFactoryLike _factory = factory();
        ICurve _bondingCurve = bondingCurve();
        IERC721 _nft = nft();

        // Input validation
        {
            PoolType _poolType = poolType();
            require(
                _poolType == PoolType.NFT || _poolType == PoolType.TRADE,
                "Wrong Pool type"
            );
            require(
                (numNFTs > 0) && (numNFTs <= _nft.balanceOf(address(this))),
                "Ask for > 0 and <= balanceOf NFTs"
            );
        }

        // Call bonding curve for pricing information
        uint256 protocolFee;
        (protocolFee, inputAmount) = _calculateBuyInfoAndUpdatePoolParams(
            numNFTs,
            maxExpectedTokenInput,
            _bondingCurve,
            _factory
        );

        _pullTokenInputAndPayProtocolFee(
            inputAmount,
            isRouter,
            routerCaller,
            _factory,
            protocolFee
        );

        _sendAnyNFTsToRecipient(_nft, nftRecipient, numNFTs);

        _refundTokenToSender(inputAmount);

        emit SwapNFTOutPair();
    }

    /**
        @notice Sends token to the pair in exchange for a specific set of NFTs
        @dev To compute the amount of token to send, call bondingCurve.getBuyInfo
        This swap is meant for users who want specific IDs. Also higher chance of
        reverting if some of the specified IDs leave the pool before the swap goes through.
        @param nftIds The list of IDs of the NFTs to purchase
        @param maxExpectedTokenInput The maximum acceptable cost from the sender. If the actual
        amount is greater than this value, the transaction will be reverted.
        @param nftRecipient The recipient of the NFTs
        @param isRouter True if calling from LSSVMRouter, false otherwise. Not used for
        ETH pairs.
        @param routerCaller If isRouter is true, ERC20 tokens will be transferred from this address. Not used for
        ETH pairs.
        @return inputAmount The amount of token used for purchase
     */
    function swapTokenForSpecificNFTs(
        uint256[] calldata nftIds,
        uint256 maxExpectedTokenInput,
        address nftRecipient,
        bool isRouter,
        address routerCaller
    ) external payable virtual nonReentrant returns (uint256 inputAmount) {
        // Store locally to remove extra calls
        ILSSVMPairFactoryLike _factory = factory();
        ICurve _bondingCurve = bondingCurve();

        // Input validation
        {
            PoolType _poolType = poolType();
            require(
                _poolType == PoolType.NFT || _poolType == PoolType.TRADE,
                "Wrong Pool type"
            );
            require((nftIds.length > 0), "Must ask for > 0 NFTs");
        }

        // Call bonding curve for pricing information
        uint256 protocolFee;
        (protocolFee, inputAmount) = _calculateBuyInfoAndUpdatePoolParams(
            nftIds.length,
            maxExpectedTokenInput,
            _bondingCurve,
            _factory
        );

        _pullTokenInputAndPayProtocolFee(
            inputAmount,
            isRouter,
            routerCaller,
            _factory,
            protocolFee
        );

        _sendSpecificNFTsToRecipient(nft(), nftRecipient, nftIds);

        _refundTokenToSender(inputAmount);

        emit SwapNFTOutPair();
    }

    /**
        @notice Sends a set of NFTs to the pair in exchange for token
        @dev To compute the amount of token to that will be received, call bondingCurve.getSellInfo.
        @param nftIds The list of IDs of the NFTs to sell to the pair
        @param minExpectedTokenOutput The minimum acceptable token received by the sender. If the actual
        amount is less than this value, the transaction will be reverted.
        @param tokenRecipient The recipient of the token output
        @param isRouter True if calling from LSSVMRouter, false otherwise. Not used for
        ETH pairs.
        @param routerCaller If isRouter is true, ERC20 tokens will be transferred from this address. Not used for
        ETH pairs.
        @return outputAmount The amount of token received
     */
    function swapNFTsForToken(
        uint256[] calldata nftIds,
        uint256 minExpectedTokenOutput,
        address payable tokenRecipient,
        bool isRouter,
        address routerCaller
    ) external virtual nonReentrant returns (uint256 outputAmount) {
        // Store locally to remove extra calls
        ILSSVMPairFactoryLike _factory = factory();
        ICurve _bondingCurve = bondingCurve();

        // Input validation
        {
            PoolType _poolType = poolType();
            require(
                _poolType == PoolType.TOKEN || _poolType == PoolType.TRADE,
                "Wrong Pool type"
            );
            require(nftIds.length > 0, "Must ask for > 0 NFTs");
        }

        // Call bonding curve for pricing information
        uint256 protocolFee;
        (protocolFee, outputAmount) = _calculateSellInfoAndUpdatePoolParams(
            nftIds.length,
            minExpectedTokenOutput,
            _bondingCurve,
            _factory
        );

        _sendTokenOutput(tokenRecipient, outputAmount);

        _payProtocolFeeFromPair(_factory, protocolFee);

        _takeNFTsFromSender(nft(), nftIds, _factory, isRouter, routerCaller);

        emit SwapNFTInPair();
    }

    /**
     * View functions
     */

    /**
        @dev Used as read function to query the bonding curve for buy pricing info
        @param numNFTs The number of NFTs to buy from the pair
     */
    function getBuyNFTQuote(uint256 numNFTs)
        external
        view
        returns (
            CurveErrorCodes.Error error,
            uint256 newSpotPrice,
            uint256 newDelta,
            uint256 inputAmount,
            uint256 protocolFee
        )
    {
        (
            error,
            newSpotPrice,
            newDelta,
            inputAmount,
            protocolFee
        ) = bondingCurve().getBuyInfo(
            spotPrice,
            delta,
            numNFTs,
            fee,
            factory().protocolFeeMultiplier()
        );
    }

    /**
        @dev Used as read function to query the bonding curve for sell pricing info
        @param numNFTs The number of NFTs to sell to the pair
     */
    function getSellNFTQuote(uint256 numNFTs)
        external
        view
        returns (
            CurveErrorCodes.Error error,
            uint256 newSpotPrice,
            uint256 newDelta,
            uint256 outputAmount,
            uint256 protocolFee
        )
    {
        (
            error,
            newSpotPrice,
            newDelta,
            outputAmount,
            protocolFee
        ) = bondingCurve().getSellInfo(
            spotPrice,
            delta,
            numNFTs,
            fee,
            factory().protocolFeeMultiplier()
        );
    }

    /**
        @notice Returns all NFT IDs held by the pool
     */
    function getAllHeldIds() external view virtual returns (uint256[] memory);

    /**
        @notice Returns the pair's variant (NFT is enumerable or not, pair uses ETH or ERC20)
     */
    function pairVariant()
        public
        pure
        virtual
        returns (ILSSVMPairFactoryLike.PairVariant);

    function factory() public pure returns (ILSSVMPairFactoryLike _factory) {
        uint256 paramsLength = _immutableParamsLength();
        assembly {
            _factory := shr(
                0x60,
                calldataload(sub(calldatasize(), paramsLength))
            )
        }
    }

    /**
        @notice Returns the type of bonding curve that parameterizes the pair
     */
    function bondingCurve() public pure returns (ICurve _bondingCurve) {
        uint256 paramsLength = _immutableParamsLength();
        assembly {
            _bondingCurve := shr(
                0x60,
                calldataload(add(sub(calldatasize(), paramsLength), 20))
            )
        }
    }

    /**
        @notice Returns the NFT collection that parameterizes the pair
     */
    function nft() public pure returns (IERC721 _nft) {
        uint256 paramsLength = _immutableParamsLength();
        assembly {
            _nft := shr(
                0x60,
                calldataload(add(sub(calldatasize(), paramsLength), 40))
            )
        }
    }

    /**
        @notice Returns the pair's type (TOKEN/NFT/TRADE)
     */
    function poolType() public pure returns (PoolType _poolType) {
        uint256 paramsLength = _immutableParamsLength();
        assembly {
            _poolType := shr(
                0xf8,
                calldataload(add(sub(calldatasize(), paramsLength), 60))
            )
        }
    }

    /**
        @notice Returns the address that assets that receives assets when a swap is done with this pair
        Can be set to another address by the owner, if set to address(0), defaults to the pair's own address
     */
    function getAssetRecipient()
        public
        view
        returns (address payable _assetRecipient)
    {
        // If it's a TRADE pool, we know the recipient is 0 (TRADE pools can't set asset recipients)
        // so just return address(this)
        if (poolType() == PoolType.TRADE) {
            return payable(address(this));
        }

        // Otherwise, we return the recipient if it's been set
        // or replace it with address(this) if it's 0
        _assetRecipient = assetRecipient;
        if (_assetRecipient == address(0)) {
            // Tokens will be transferred to address(this)
            _assetRecipient = payable(address(this));
        }
    }

    /**
     * Internal functions
     */

    /**
        @notice Calculates the amount needed to be sent into the pair for a buy and adjusts spot price or delta if necessary
        @param numNFTs The amount of NFTs to purchase from the pair
        @param maxExpectedTokenInput The maximum acceptable cost from the sender. If the actual
        amount is greater than this value, the transaction will be reverted.
        @param protocolFee The percentage of protocol fee to be taken, as a percentage
        @return protocolFee The amount of tokens to send as protocol fee
        @return inputAmount The amount of tokens total tokens receive
     */
    function _calculateBuyInfoAndUpdatePoolParams(
        uint256 numNFTs,
        uint256 maxExpectedTokenInput,
        ICurve _bondingCurve,
        ILSSVMPairFactoryLike _factory
    ) internal returns (uint256 protocolFee, uint256 inputAmount) {
        CurveErrorCodes.Error error;
        // Save on 2 SLOADs by caching
        uint128 currentSpotPrice = spotPrice;
        uint128 newSpotPrice;
        uint128 currentDelta = delta;
        uint128 newDelta;
        (
            error,
            newSpotPrice,
            newDelta,
            inputAmount,
            protocolFee
        ) = _bondingCurve.getBuyInfo(
            currentSpotPrice,
            currentDelta,
            numNFTs,
            fee,
            _factory.protocolFeeMultiplier()
        );

        // Revert if bonding curve had an error
        if (error != CurveErrorCodes.Error.OK) {
            revert BondingCurveError(error);
        }

        // Revert if input is more than expected
        require(inputAmount <= maxExpectedTokenInput, "In too many tokens");

        // Consolidate writes to save gas
        if (currentSpotPrice != newSpotPrice || currentDelta != newDelta) {
            spotPrice = newSpotPrice;
            delta = newDelta;
        }

        // Emit spot price update if it has been updated
        if (currentSpotPrice != newSpotPrice) {
            emit SpotPriceUpdate(newSpotPrice);
        }

        // Emit delta update if it has been updated
        if (currentDelta != newDelta) {
            emit DeltaUpdate(newDelta);
        }
    }

    /**
        @notice Calculates the amount needed to be sent by the pair for a sell and adjusts spot price or delta if necessary
        @param numNFTs The amount of NFTs to send to the the pair
        @param minExpectedTokenOutput The minimum acceptable token received by the sender. If the actual
        amount is less than this value, the transaction will be reverted.
        @param protocolFee The percentage of protocol fee to be taken, as a percentage
        @return protocolFee The amount of tokens to send as protocol fee
        @return outputAmount The amount of tokens total tokens receive
     */
    function _calculateSellInfoAndUpdatePoolParams(
        uint256 numNFTs,
        uint256 minExpectedTokenOutput,
        ICurve _bondingCurve,
        ILSSVMPairFactoryLike _factory
    ) internal returns (uint256 protocolFee, uint256 outputAmount) {
        CurveErrorCodes.Error error;
        // Save on 2 SLOADs by caching
        uint128 currentSpotPrice = spotPrice;
        uint128 newSpotPrice;
        uint128 currentDelta = delta;
        uint128 newDelta;
        (
            error,
            newSpotPrice,
            newDelta,
            outputAmount,
            protocolFee
        ) = _bondingCurve.getSellInfo(
            currentSpotPrice,
            currentDelta,
            numNFTs,
            fee,
            _factory.protocolFeeMultiplier()
        );

        // Revert if bonding curve had an error
        if (error != CurveErrorCodes.Error.OK) {
            revert BondingCurveError(error);
        }

        // Revert if output is too little
        require(
            outputAmount >= minExpectedTokenOutput,
            "Out too little tokens"
        );

        // Consolidate writes to save gas
        if (currentSpotPrice != newSpotPrice || currentDelta != newDelta) {
            spotPrice = newSpotPrice;
            delta = newDelta;
        }

        // Emit spot price update if it has been updated
        if (currentSpotPrice != newSpotPrice) {
            emit SpotPriceUpdate(newSpotPrice);
        }

        // Emit delta update if it has been updated
        if (currentDelta != newDelta) {
            emit DeltaUpdate(newDelta);
        }
    }

    /**
        @notice Pulls the token input of a trade from the trader and pays the protocol fee.
        @param inputAmount The amount of tokens to be sent
        @param isRouter Whether or not the caller is LSSVMRouter
        @param routerCaller If called from LSSVMRouter, store the original caller
        @param _factory The LSSVMPairFactory which stores LSSVMRouter allowlist info
        @param protocolFee The protocol fee to be paid
     */
    function _pullTokenInputAndPayProtocolFee(
        uint256 inputAmount,
        bool isRouter,
        address routerCaller,
        ILSSVMPairFactoryLike _factory,
        uint256 protocolFee
    ) internal virtual;

    /**
        @notice Sends excess tokens back to the caller (if applicable)
        @dev We send ETH back to the caller even when called from LSSVMRouter because we do an aggregate slippage check for certain bulk swaps. (Instead of sending directly back to the router caller) 
        Excess ETH sent for one swap can then be used to help pay for the next swap.
     */
    function _refundTokenToSender(uint256 inputAmount) internal virtual;

    /**
        @notice Sends protocol fee (if it exists) back to the LSSVMPairFactory from the pair
     */
    function _payProtocolFeeFromPair(
        ILSSVMPairFactoryLike _factory,
        uint256 protocolFee
    ) internal virtual;

    /**
        @notice Sends tokens to a recipient
        @param tokenRecipient The address receiving the tokens
        @param outputAmount The amount of tokens to send
     */
    function _sendTokenOutput(
        address payable tokenRecipient,
        uint256 outputAmount
    ) internal virtual;

    /**
        @notice Sends some number of NFTs to a recipient address, ID agnostic
        @dev Even though we specify the NFT address here, this internal function is only 
        used to send NFTs associated with this specific pool.
        @param _nft The address of the NFT to send
        @param nftRecipient The receiving address for the NFTs
        @param numNFTs The number of NFTs to send  
     */
    function _sendAnyNFTsToRecipient(
        IERC721 _nft,
        address nftRecipient,
        uint256 numNFTs
    ) internal virtual;

    /**
        @notice Sends specific NFTs to a recipient address
        @dev Even though we specify the NFT address here, this internal function is only 
        used to send NFTs associated with this specific pool.
        @param _nft The address of the NFT to send
        @param nftRecipient The receiving address for the NFTs
        @param nftIds The specific IDs of NFTs to send  
     */
    function _sendSpecificNFTsToRecipient(
        IERC721 _nft,
        address nftRecipient,
        uint256[] calldata nftIds
    ) internal virtual;

    /**
        @notice Takes NFTs from the caller and sends them into the pair's asset recipient
        @dev This is used by the LSSVMPair's swapNFTForToken function. 
        @param _nft The NFT collection to take from
        @param nftIds The specific NFT IDs to take
        @param isRouter True if calling from LSSVMRouter, false otherwise. Not used for
        ETH pairs.
        @param routerCaller If isRouter is true, ERC20 tokens will be transferred from this address. Not used for
        ETH pairs.
     */
    function _takeNFTsFromSender(
        IERC721 _nft,
        uint256[] calldata nftIds,
        ILSSVMPairFactoryLike _factory,
        bool isRouter,
        address routerCaller
    ) internal virtual {
        {
            address _assetRecipient = getAssetRecipient();
            uint256 numNFTs = nftIds.length;

            if (isRouter) {
                // Verify if router is allowed
                LSSVMRouter router = LSSVMRouter(payable(msg.sender));
                (bool routerAllowed, ) = _factory.routerStatus(router);
                require(routerAllowed, "Not router");

                // Call router to pull NFTs
                // If more than 1 NFT is being transfered, we can do a balance check instead of an ownership check, as pools are indifferent between NFTs from the same collection
                if (numNFTs > 1) {
                    uint256 beforeBalance = _nft.balanceOf(_assetRecipient);
                    for (uint256 i = 0; i < numNFTs; ) {
                        router.pairTransferNFTFrom(
                            _nft,
                            routerCaller,
                            _assetRecipient,
                            nftIds[i],
                            pairVariant()
                        );

                        unchecked {
                            ++i;
                        }
                    }
                    require(
                        (_nft.balanceOf(_assetRecipient) - beforeBalance) ==
                            numNFTs,
                        "NFTs not transferred"
                    );
                } else {
                    router.pairTransferNFTFrom(
                        _nft,
                        routerCaller,
                        _assetRecipient,
                        nftIds[0],
                        pairVariant()
                    );
                    require(
                        _nft.ownerOf(nftIds[0]) == _assetRecipient,
                        "NFT not transferred"
                    );
                }
            } else {
                // Pull NFTs directly from sender
                for (uint256 i; i < numNFTs; ) {
                    _nft.safeTransferFrom(
                        msg.sender,
                        _assetRecipient,
                        nftIds[i]
                    );

                    unchecked {
                        ++i;
                    }
                }
            }
        }
    }

    /**
        @dev Used internally to grab pair parameters from calldata, see LSSVMPairCloner for technical details
     */
    function _immutableParamsLength() internal pure virtual returns (uint256);

    /**
     * Owner functions
     */

    /**
        @notice Rescues a specified set of NFTs owned by the pair to the owner address. (onlyOwnable modifier is in the implemented function)
        @dev If the NFT is the pair's collection, we also remove it from the id tracking (if the NFT is missing enumerable).
        @param a The NFT to transfer
        @param nftIds The list of IDs of the NFTs to send to the owner
     */
    function withdrawERC721(IERC721 a, uint256[] calldata nftIds)
        external
        virtual;

    /**
        @notice Rescues ERC20 tokens from the pair to the owner. Only callable by the owner (onlyOwnable modifier is in the implemented function).
        @param a The token to transfer
        @param amount The amount of tokens to send to the owner
     */
    function withdrawERC20(ERC20 a, uint256 amount) external virtual;

    /**
        @notice Rescues ERC1155 tokens from the pair to the owner. Only callable by the owner.
        @param a The NFT to transfer
        @param ids The NFT ids to transfer
        @param amounts The amounts of each id to transfer
     */
    function withdrawERC1155(
        IERC1155 a,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) external onlyOwner {
        a.safeBatchTransferFrom(address(this), msg.sender, ids, amounts, "");
    }

    /**
        @notice Updates the selling spot price. Only callable by the owner.
        @param newSpotPrice The new selling spot price value, in Token
     */
    function changeSpotPrice(uint128 newSpotPrice) external onlyOwner {
        ICurve _bondingCurve = bondingCurve();
        require(
            _bondingCurve.validateSpotPrice(newSpotPrice),
            "Invalid new spot price for curve"
        );
        if (spotPrice != newSpotPrice) {
            spotPrice = newSpotPrice;
            emit SpotPriceUpdate(newSpotPrice);
        }
    }

    /**
        @notice Updates the delta parameter. Only callable by the owner.
        @param newDelta The new delta parameter
     */
    function changeDelta(uint128 newDelta) external onlyOwner {
        ICurve _bondingCurve = bondingCurve();
        require(
            _bondingCurve.validateDelta(newDelta),
            "Invalid delta for curve"
        );
        if (delta != newDelta) {
            delta = newDelta;
            emit DeltaUpdate(newDelta);
        }
    }

    /**
        @notice Updates the fee taken by the LP. Only callable by the owner.
        Only callable if the pool is a Trade pool. Reverts if the fee is >=
        MAX_FEE.
        @param newFee The new LP fee percentage, 18 decimals
     */
    function changeFee(uint96 newFee) external onlyOwner {
        PoolType _poolType = poolType();
        require(_poolType == PoolType.TRADE, "Only for Trade pools");
        require(newFee < MAX_FEE, "Trade fee must be less than 90%");
        if (fee != newFee) {
            fee = newFee;
            emit FeeUpdate(newFee);
        }
    }

    /**
        @notice Changes the address that will receive assets received from
        trades. Only callable by the owner.
        @param newRecipient The new asset recipient
     */
    function changeAssetRecipient(address payable newRecipient)
        external
        onlyOwner
    {
        PoolType _poolType = poolType();
        require(_poolType != PoolType.TRADE, "Not for Trade pools");
        if (assetRecipient != newRecipient) {
            assetRecipient = newRecipient;
            emit AssetRecipientChange(newRecipient);
        }
    }

    /**
        @notice Allows the pair to make arbitrary external calls to contracts
        whitelisted by the protocol. Only callable by the owner.
        @param target The contract to call
        @param data The calldata to pass to the contract
     */
    function call(address payable target, bytes calldata data)
        external
        onlyOwner
    {
        ILSSVMPairFactoryLike _factory = factory();
        require(_factory.callAllowed(target), "Target must be whitelisted");
        (bool result, ) = target.call{value: 0}(data);
        require(result, "Call failed");
    }

    /**
        @notice Allows owner to batch multiple calls, forked from: https://github.com/boringcrypto/BoringSolidity/blob/master/contracts/BoringBatchable.sol 
        @dev Intended for withdrawing/altering pool pricing in one tx, only callable by owner, cannot change owner
        @param calls The calldata for each call to make
        @param revertOnFail Whether or not to revert the entire tx if any of the calls fail
     */
    function multicall(bytes[] calldata calls, bool revertOnFail)
        external
        onlyOwner
    {
        for (uint256 i; i < calls.length; ) {
            (bool success, bytes memory result) = address(this).delegatecall(
                calls[i]
            );
            if (!success && revertOnFail) {
                revert(_getRevertMsg(result));
            }

            unchecked {
                ++i;
            }
        }

        // Prevent multicall from malicious frontend sneaking in ownership change
        require(
            owner() == msg.sender,
            "Ownership cannot be changed in multicall"
        );
    }

    /**
      @param _returnData The data returned from a multicall result
      @dev Used to grab the revert string from the underlying call
     */
    function _getRevertMsg(bytes memory _returnData)
        internal
        pure
        returns (string memory)
    {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return "Transaction reverted silently";

        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string)); // All that remains is the revert string
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {CurveErrorCodes} from "./CurveErrorCodes.sol";

interface ICurve {
    /**
        @notice Validates if a delta value is valid for the curve. The criteria for
        validity can be different for each type of curve, for instance ExponentialCurve
        requires delta to be greater than 1.
        @param delta The delta value to be validated
        @return valid True if delta is valid, false otherwise
     */
    function validateDelta(uint128 delta) external pure returns (bool valid);

    /**
        @notice Validates if a new spot price is valid for the curve. Spot price is generally assumed to be the immediate sell price of 1 NFT to the pool, in units of the pool's paired token.
        @param newSpotPrice The new spot price to be set
        @return valid True if the new spot price is valid, false otherwise
     */
    function validateSpotPrice(uint128 newSpotPrice)
        external
        view
        returns (bool valid);

    /**
        @notice Given the current state of the pair and the trade, computes how much the user
        should pay to purchase an NFT from the pair, the new spot price, and other values.
        @param spotPrice The current selling spot price of the pair, in tokens
        @param delta The delta parameter of the pair, what it means depends on the curve
        @param numItems The number of NFTs the user is buying from the pair
        @param feeMultiplier Determines how much fee the LP takes from this trade, 18 decimals
        @param protocolFeeMultiplier Determines how much fee the protocol takes from this trade, 18 decimals
        @return error Any math calculation errors, only Error.OK means the returned values are valid
        @return newSpotPrice The updated selling spot price, in tokens
        @return newDelta The updated delta, used to parameterize the bonding curve
        @return inputValue The amount that the user should pay, in tokens
        @return protocolFee The amount of fee to send to the protocol, in tokens
     */
    function getBuyInfo(
        uint128 spotPrice,
        uint128 delta,
        uint256 numItems,
        uint256 feeMultiplier,
        uint256 protocolFeeMultiplier
    )
        external
        view
        returns (
            CurveErrorCodes.Error error,
            uint128 newSpotPrice,
            uint128 newDelta,
            uint256 inputValue,
            uint256 protocolFee
        );

    /**
        @notice Given the current state of the pair and the trade, computes how much the user
        should receive when selling NFTs to the pair, the new spot price, and other values.
        @param spotPrice The current selling spot price of the pair, in tokens
        @param delta The delta parameter of the pair, what it means depends on the curve
        @param numItems The number of NFTs the user is selling to the pair
        @param feeMultiplier Determines how much fee the LP takes from this trade, 18 decimals
        @param protocolFeeMultiplier Determines how much fee the protocol takes from this trade, 18 decimals
        @return error Any math calculation errors, only Error.OK means the returned values are valid
        @return newSpotPrice The updated selling spot price, in tokens
        @return newDelta The updated delta, used to parameterize the bonding curve
        @return outputValue The amount that the user should receive, in tokens
        @return protocolFee The amount of fee to send to the protocol, in tokens
     */
    function getSellInfo(
        uint128 spotPrice,
        uint128 delta,
        uint256 numItems,
        uint256 feeMultiplier,
        uint256 protocolFeeMultiplier
    )
        external
        view
        returns (
            CurveErrorCodes.Error error,
            uint128 newSpotPrice,
            uint128 newDelta,
            uint256 outputValue,
            uint256 protocolFee
        );
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
abstract contract ERC20 {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*///////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*///////////////////////////////////////////////////////////////
                           EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    bytes32 public constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*///////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*///////////////////////////////////////////////////////////////
                              ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        if (allowance[from][msg.sender] != type(uint256).max) {
            allowance[from][msg.sender] -= amount;
        }

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*///////////////////////////////////////////////////////////////
                              EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            bytes32 digest = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
                )
            );

            address recoveredAddress = ecrecover(digest, v, r, s);
            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_PERMIT_SIGNATURE");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256(bytes("1")),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Modified from Gnosis (https://github.com/gnosis/gp-v2-contracts/blob/main/src/contracts/libraries/GPv2SafeERC20.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
library SafeTransferLib {
    /*///////////////////////////////////////////////////////////////
                            ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool callStatus;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            callStatus := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(callStatus, "ETH_TRANSFER_FAILED");
    }

    /*///////////////////////////////////////////////////////////////
                           ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(from, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "from" argument.
            mstore(add(freeMemoryPointer, 36), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 100 because the calldata length is 4 + 32 * 3.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 100, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 68 because the calldata length is 4 + 32 * 2.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 68, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 68 because the calldata length is 4 + 32 * 2.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 68, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "APPROVE_FAILED");
    }

    /*///////////////////////////////////////////////////////////////
                         INTERNAL HELPER LOGIC
    //////////////////////////////////////////////////////////////*/

    function didLastOptionalReturnCallSucceed(bool callStatus) private pure returns (bool success) {
        assembly {
            // Get how many bytes the call returned.
            let returnDataSize := returndatasize()

            // If the call reverted:
            if iszero(callStatus) {
                // Copy the revert message into memory.
                returndatacopy(0, 0, returnDataSize)

                // Revert with the same message.
                revert(0, returnDataSize)
            }

            switch returnDataSize
            case 32 {
                // Copy the return data into memory.
                returndatacopy(0, 0, returnDataSize)

                // Set success to whether it returned true.
                success := iszero(iszero(mload(0)))
            }
            case 0 {
                // There was no return data.
                success := 1
            }
            default {
                // It returned some malformed input.
                success := 0
            }
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ERC20} from "@rari-capital/solmate/src/tokens/ERC20.sol";
import {SafeTransferLib} from "@rari-capital/solmate/src/utils/SafeTransferLib.sol";
import {LSSVMPair} from "./LSSVMPair.sol";
import {ILSSVMPairFactoryLike} from "./ILSSVMPairFactoryLike.sol";
import {CurveErrorCodes} from "./bonding-curves/CurveErrorCodes.sol";

contract LSSVMRouter {
    using SafeTransferLib for address payable;
    using SafeTransferLib for ERC20;

    struct PairSwapAny {
        LSSVMPair pair;
        uint256 numItems;
    }

    struct PairSwapSpecific {
        LSSVMPair pair;
        uint256[] nftIds;
    }

    struct RobustPairSwapAny {
        PairSwapAny swapInfo;
        uint256 maxCost;
    }

    struct RobustPairSwapSpecific {
        PairSwapSpecific swapInfo;
        uint256 maxCost;
    }

    struct RobustPairSwapSpecificForToken {
        PairSwapSpecific swapInfo;
        uint256 minOutput;
    }

    struct NFTsForAnyNFTsTrade {
        PairSwapSpecific[] nftToTokenTrades;
        PairSwapAny[] tokenToNFTTrades;
    }

    struct NFTsForSpecificNFTsTrade {
        PairSwapSpecific[] nftToTokenTrades;
        PairSwapSpecific[] tokenToNFTTrades;
    }

    struct RobustPairNFTsFoTokenAndTokenforNFTsTrade {
        RobustPairSwapSpecific[] tokenToNFTTrades;
        RobustPairSwapSpecificForToken[] nftToTokenTrades;
        uint256 inputAmount;
        address payable tokenRecipient;
        address nftRecipient;
    }

    modifier checkDeadline(uint256 deadline) {
        _checkDeadline(deadline);
        _;
    }

    ILSSVMPairFactoryLike public immutable factory;

    constructor(ILSSVMPairFactoryLike _factory) {
        factory = _factory;
    }

    /**
        ETH swaps
     */

    /**
        @notice Swaps ETH into NFTs using multiple pairs.
        @param swapList The list of pairs to trade with and the number of NFTs to buy from each.
        @param ethRecipient The address that will receive the unspent ETH input
        @param nftRecipient The address that will receive the NFT output
        @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
        @return remainingValue The unspent ETH amount
     */
    function swapETHForAnyNFTs(
        PairSwapAny[] calldata swapList,
        address payable ethRecipient,
        address nftRecipient,
        uint256 deadline
    )
        external
        payable
        checkDeadline(deadline)
        returns (uint256 remainingValue)
    {
        return
            _swapETHForAnyNFTs(swapList, msg.value, ethRecipient, nftRecipient);
    }

    /**
        @notice Swaps ETH into specific NFTs using multiple pairs.
        @param swapList The list of pairs to trade with and the IDs of the NFTs to buy from each.
        @param ethRecipient The address that will receive the unspent ETH input
        @param nftRecipient The address that will receive the NFT output
        @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
        @return remainingValue The unspent ETH amount
     */
    function swapETHForSpecificNFTs(
        PairSwapSpecific[] calldata swapList,
        address payable ethRecipient,
        address nftRecipient,
        uint256 deadline
    )
        external
        payable
        checkDeadline(deadline)
        returns (uint256 remainingValue)
    {
        return
            _swapETHForSpecificNFTs(
                swapList,
                msg.value,
                ethRecipient,
                nftRecipient
            );
    }

    /**
        @notice Swaps one set of NFTs into another set of specific NFTs using multiple pairs, using
        ETH as the intermediary.
        @param trade The struct containing all NFT-to-ETH swaps and ETH-to-NFT swaps.
        @param minOutput The minimum acceptable total excess ETH received
        @param ethRecipient The address that will receive the ETH output
        @param nftRecipient The address that will receive the NFT output
        @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
        @return outputAmount The total ETH received
     */
    function swapNFTsForAnyNFTsThroughETH(
        NFTsForAnyNFTsTrade calldata trade,
        uint256 minOutput,
        address payable ethRecipient,
        address nftRecipient,
        uint256 deadline
    ) external payable checkDeadline(deadline) returns (uint256 outputAmount) {
        // Swap NFTs for ETH
        // minOutput of swap set to 0 since we're doing an aggregate slippage check
        outputAmount = _swapNFTsForToken(
            trade.nftToTokenTrades,
            0,
            payable(address(this))
        );

        // Add extra value to buy NFTs
        outputAmount += msg.value;

        // Swap ETH for any NFTs
        // cost <= inputValue = outputAmount - minOutput, so outputAmount' = (outputAmount - minOutput - cost) + minOutput >= minOutput
        outputAmount =
            _swapETHForAnyNFTs(
                trade.tokenToNFTTrades,
                outputAmount - minOutput,
                ethRecipient,
                nftRecipient
            ) +
            minOutput;
    }

    /**
        @notice Swaps one set of NFTs into another set of specific NFTs using multiple pairs, using
        ETH as the intermediary.
        @param trade The struct containing all NFT-to-ETH swaps and ETH-to-NFT swaps.
        @param minOutput The minimum acceptable total excess ETH received
        @param ethRecipient The address that will receive the ETH output
        @param nftRecipient The address that will receive the NFT output
        @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
        @return outputAmount The total ETH received
     */
    function swapNFTsForSpecificNFTsThroughETH(
        NFTsForSpecificNFTsTrade calldata trade,
        uint256 minOutput,
        address payable ethRecipient,
        address nftRecipient,
        uint256 deadline
    ) external payable checkDeadline(deadline) returns (uint256 outputAmount) {
        // Swap NFTs for ETH
        // minOutput of swap set to 0 since we're doing an aggregate slippage check
        outputAmount = _swapNFTsForToken(
            trade.nftToTokenTrades,
            0,
            payable(address(this))
        );

        // Add extra value to buy NFTs
        outputAmount += msg.value;

        // Swap ETH for specific NFTs
        // cost <= inputValue = outputAmount - minOutput, so outputAmount' = (outputAmount - minOutput - cost) + minOutput >= minOutput
        outputAmount =
            _swapETHForSpecificNFTs(
                trade.tokenToNFTTrades,
                outputAmount - minOutput,
                ethRecipient,
                nftRecipient
            ) +
            minOutput;
    }

    /**
        ERC20 swaps

        Note: All ERC20 swaps assume that a single ERC20 token is used for all the pairs involved.
        Swapping using multiple tokens in the same transaction is possible, but the slippage checks
        & the return values will be meaningless, and may lead to undefined behavior.

        Note: The sender should ideally grant infinite token approval to the router in order for NFT-to-NFT
        swaps to work smoothly.
     */

    /**
        @notice Swaps ERC20 tokens into NFTs using multiple pairs.
        @param swapList The list of pairs to trade with and the number of NFTs to buy from each.
        @param inputAmount The amount of ERC20 tokens to add to the ERC20-to-NFT swaps
        @param nftRecipient The address that will receive the NFT output
        @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
        @return remainingValue The unspent token amount
     */
    function swapERC20ForAnyNFTs(
        PairSwapAny[] calldata swapList,
        uint256 inputAmount,
        address nftRecipient,
        uint256 deadline
    ) external checkDeadline(deadline) returns (uint256 remainingValue) {
        return _swapERC20ForAnyNFTs(swapList, inputAmount, nftRecipient);
    }

    /**
        @notice Swaps ERC20 tokens into specific NFTs using multiple pairs.
        @param swapList The list of pairs to trade with and the IDs of the NFTs to buy from each.
        @param inputAmount The amount of ERC20 tokens to add to the ERC20-to-NFT swaps
        @param nftRecipient The address that will receive the NFT output
        @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
        @return remainingValue The unspent token amount
     */
    function swapERC20ForSpecificNFTs(
        PairSwapSpecific[] calldata swapList,
        uint256 inputAmount,
        address nftRecipient,
        uint256 deadline
    ) external checkDeadline(deadline) returns (uint256 remainingValue) {
        return _swapERC20ForSpecificNFTs(swapList, inputAmount, nftRecipient);
    }

    /**
        @notice Swaps NFTs into ETH/ERC20 using multiple pairs.
        @param swapList The list of pairs to trade with and the IDs of the NFTs to sell to each.
        @param minOutput The minimum acceptable total tokens received
        @param tokenRecipient The address that will receive the token output
        @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
        @return outputAmount The total tokens received
     */
    function swapNFTsForToken(
        PairSwapSpecific[] calldata swapList,
        uint256 minOutput,
        address tokenRecipient,
        uint256 deadline
    ) external checkDeadline(deadline) returns (uint256 outputAmount) {
        return _swapNFTsForToken(swapList, minOutput, payable(tokenRecipient));
    }

    /**
        @notice Swaps one set of NFTs into another set of specific NFTs using multiple pairs, using
        an ERC20 token as the intermediary.
        @param trade The struct containing all NFT-to-ERC20 swaps and ERC20-to-NFT swaps.
        @param inputAmount The amount of ERC20 tokens to add to the ERC20-to-NFT swaps
        @param minOutput The minimum acceptable total excess tokens received
        @param nftRecipient The address that will receive the NFT output
        @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
        @return outputAmount The total ERC20 tokens received
     */
    function swapNFTsForAnyNFTsThroughERC20(
        NFTsForAnyNFTsTrade calldata trade,
        uint256 inputAmount,
        uint256 minOutput,
        address nftRecipient,
        uint256 deadline
    ) external checkDeadline(deadline) returns (uint256 outputAmount) {
        // Swap NFTs for ERC20
        // minOutput of swap set to 0 since we're doing an aggregate slippage check
        // output tokens are sent to msg.sender
        outputAmount = _swapNFTsForToken(
            trade.nftToTokenTrades,
            0,
            payable(msg.sender)
        );

        // Add extra value to buy NFTs
        outputAmount += inputAmount;

        // Swap ERC20 for any NFTs
        // cost <= maxCost = outputAmount - minOutput, so outputAmount' = outputAmount - cost >= minOutput
        // input tokens are taken directly from msg.sender
        outputAmount =
            _swapERC20ForAnyNFTs(
                trade.tokenToNFTTrades,
                outputAmount - minOutput,
                nftRecipient
            ) +
            minOutput;
    }

    /**
        @notice Swaps one set of NFTs into another set of specific NFTs using multiple pairs, using
        an ERC20 token as the intermediary.
        @param trade The struct containing all NFT-to-ERC20 swaps and ERC20-to-NFT swaps.
        @param inputAmount The amount of ERC20 tokens to add to the ERC20-to-NFT swaps
        @param minOutput The minimum acceptable total excess tokens received
        @param nftRecipient The address that will receive the NFT output
        @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
        @return outputAmount The total ERC20 tokens received
     */
    function swapNFTsForSpecificNFTsThroughERC20(
        NFTsForSpecificNFTsTrade calldata trade,
        uint256 inputAmount,
        uint256 minOutput,
        address nftRecipient,
        uint256 deadline
    ) external checkDeadline(deadline) returns (uint256 outputAmount) {
        // Swap NFTs for ERC20
        // minOutput of swap set to 0 since we're doing an aggregate slippage check
        // output tokens are sent to msg.sender
        outputAmount = _swapNFTsForToken(
            trade.nftToTokenTrades,
            0,
            payable(msg.sender)
        );

        // Add extra value to buy NFTs
        outputAmount += inputAmount;

        // Swap ERC20 for specific NFTs
        // cost <= maxCost = outputAmount - minOutput, so outputAmount' = outputAmount - cost >= minOutput
        // input tokens are taken directly from msg.sender
        outputAmount =
            _swapERC20ForSpecificNFTs(
                trade.tokenToNFTTrades,
                outputAmount - minOutput,
                nftRecipient
            ) +
            minOutput;
    }

    /**
        Robust Swaps
        These are "robust" versions of the NFT<>Token swap functions which will never revert due to slippage
        Instead, users specify a per-swap max cost. If the price changes more than the user specifies, no swap is attempted. This allows users to specify a batch of swaps, and execute as many of them as possible.
     */

    /**
        @dev We assume msg.value >= sum of values in maxCostPerPair
        @notice Swaps as much ETH for any NFTs as possible, respecting the per-swap max cost.
        @param swapList The list of pairs to trade with and the number of NFTs to buy from each.
        @param ethRecipient The address that will receive the unspent ETH input
        @param nftRecipient The address that will receive the NFT output
        @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
        @return remainingValue The unspent token amount
     */
    function robustSwapETHForAnyNFTs(
        RobustPairSwapAny[] calldata swapList,
        address payable ethRecipient,
        address nftRecipient,
        uint256 deadline
    )
        external
        payable
        virtual
        checkDeadline(deadline)
        returns (uint256 remainingValue)
    {
        remainingValue = msg.value;

        // Try doing each swap
        uint256 pairCost;
        CurveErrorCodes.Error error;
        uint256 numSwaps = swapList.length;
        for (uint256 i; i < numSwaps; ) {
            // Calculate actual cost per swap
            (error, , , pairCost, ) = swapList[i].swapInfo.pair.getBuyNFTQuote(
                swapList[i].swapInfo.numItems
            );

            // If within our maxCost and no error, proceed
            if (
                pairCost <= swapList[i].maxCost &&
                error == CurveErrorCodes.Error.OK
            ) {
                // We know how much ETH to send because we already did the math above
                // So we just send that much
                remainingValue -= swapList[i].swapInfo.pair.swapTokenForAnyNFTs{
                    value: pairCost
                }(
                    swapList[i].swapInfo.numItems,
                    pairCost,
                    nftRecipient,
                    true,
                    msg.sender
                );
            }

            unchecked {
                ++i;
            }
        }

        // Return remaining value to sender
        if (remainingValue > 0) {
            ethRecipient.safeTransferETH(remainingValue);
        }
    }

    /**
        @dev We assume msg.value >= sum of values in maxCostPerPair
        @param swapList The list of pairs to trade with and the IDs of the NFTs to buy from each.
        @param ethRecipient The address that will receive the unspent ETH input
        @param nftRecipient The address that will receive the NFT output
        @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
        @return remainingValue The unspent token amount
     */
    function robustSwapETHForSpecificNFTs(
        RobustPairSwapSpecific[] calldata swapList,
        address payable ethRecipient,
        address nftRecipient,
        uint256 deadline
    )
        public
        payable
        virtual
        checkDeadline(deadline)
        returns (uint256 remainingValue)
    {
        remainingValue = msg.value;
        uint256 pairCost;
        CurveErrorCodes.Error error;

        // Try doing each swap
        uint256 numSwaps = swapList.length;
        for (uint256 i; i < numSwaps; ) {
            // Calculate actual cost per swap
            (error, , , pairCost, ) = swapList[i].swapInfo.pair.getBuyNFTQuote(
                swapList[i].swapInfo.nftIds.length
            );

            // If within our maxCost and no error, proceed
            if (
                pairCost <= swapList[i].maxCost &&
                error == CurveErrorCodes.Error.OK
            ) {
                // We know how much ETH to send because we already did the math above
                // So we just send that much
                remainingValue -= swapList[i]
                    .swapInfo
                    .pair
                    .swapTokenForSpecificNFTs{value: pairCost}(
                    swapList[i].swapInfo.nftIds,
                    pairCost,
                    nftRecipient,
                    true,
                    msg.sender
                );
            }

            unchecked {
                ++i;
            }
        }

        // Return remaining value to sender
        if (remainingValue > 0) {
            ethRecipient.safeTransferETH(remainingValue);
        }
    }

    /**
        @notice Swaps as many ERC20 tokens for any NFTs as possible, respecting the per-swap max cost.
        @param swapList The list of pairs to trade with and the number of NFTs to buy from each.
        @param inputAmount The amount of ERC20 tokens to add to the ERC20-to-NFT swaps
        @param nftRecipient The address that will receive the NFT output
        @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
        @return remainingValue The unspent token amount

     */
    function robustSwapERC20ForAnyNFTs(
        RobustPairSwapAny[] calldata swapList,
        uint256 inputAmount,
        address nftRecipient,
        uint256 deadline
    )
        external
        virtual
        checkDeadline(deadline)
        returns (uint256 remainingValue)
    {
        remainingValue = inputAmount;
        uint256 pairCost;
        CurveErrorCodes.Error error;

        // Try doing each swap
        uint256 numSwaps = swapList.length;
        for (uint256 i; i < numSwaps; ) {
            // Calculate actual cost per swap
            (error, , , pairCost, ) = swapList[i].swapInfo.pair.getBuyNFTQuote(
                swapList[i].swapInfo.numItems
            );

            // If within our maxCost and no error, proceed
            if (
                pairCost <= swapList[i].maxCost &&
                error == CurveErrorCodes.Error.OK
            ) {
                remainingValue -= swapList[i].swapInfo.pair.swapTokenForAnyNFTs(
                        swapList[i].swapInfo.numItems,
                        pairCost,
                        nftRecipient,
                        true,
                        msg.sender
                    );
            }

            unchecked {
                ++i;
            }
        }
    }

    /**
        @notice Swaps as many ERC20 tokens for specific NFTs as possible, respecting the per-swap max cost.
        @param swapList The list of pairs to trade with and the IDs of the NFTs to buy from each.
        @param inputAmount The amount of ERC20 tokens to add to the ERC20-to-NFT swaps

        @param nftRecipient The address that will receive the NFT output
        @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
        @return remainingValue The unspent token amount
     */
    function robustSwapERC20ForSpecificNFTs(
        RobustPairSwapSpecific[] calldata swapList,
        uint256 inputAmount,
        address nftRecipient,
        uint256 deadline
    ) public virtual checkDeadline(deadline) returns (uint256 remainingValue) {
        remainingValue = inputAmount;
        uint256 pairCost;
        CurveErrorCodes.Error error;

        // Try doing each swap
        uint256 numSwaps = swapList.length;
        for (uint256 i; i < numSwaps; ) {
            // Calculate actual cost per swap
            (error, , , pairCost, ) = swapList[i].swapInfo.pair.getBuyNFTQuote(
                swapList[i].swapInfo.nftIds.length
            );

            // If within our maxCost and no error, proceed
            if (
                pairCost <= swapList[i].maxCost &&
                error == CurveErrorCodes.Error.OK
            ) {
                remainingValue -= swapList[i]
                    .swapInfo
                    .pair
                    .swapTokenForSpecificNFTs(
                        swapList[i].swapInfo.nftIds,
                        pairCost,
                        nftRecipient,
                        true,
                        msg.sender
                    );
            }

            unchecked {
                ++i;
            }
        }
    }

    /**
        @notice Swaps as many NFTs for tokens as possible, respecting the per-swap min output
        @param swapList The list of pairs to trade with and the IDs of the NFTs to sell to each.
        @param tokenRecipient The address that will receive the token output
        @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
        @return outputAmount The total ETH/ERC20 received
     */
    function robustSwapNFTsForToken(
        RobustPairSwapSpecificForToken[] calldata swapList,
        address payable tokenRecipient,
        uint256 deadline
    ) public virtual checkDeadline(deadline) returns (uint256 outputAmount) {
        // Try doing each swap
        uint256 numSwaps = swapList.length;
        for (uint256 i; i < numSwaps; ) {
            uint256 pairOutput;

            // Locally scoped to avoid stack too deep error
            {
                CurveErrorCodes.Error error;
                (error, , , pairOutput, ) = swapList[i]
                    .swapInfo
                    .pair
                    .getSellNFTQuote(swapList[i].swapInfo.nftIds.length);
                if (error != CurveErrorCodes.Error.OK) {
                    unchecked {
                        ++i;
                    }
                    continue;
                }
            }

            // If at least equal to our minOutput, proceed
            if (pairOutput >= swapList[i].minOutput) {
                // Do the swap and update outputAmount with how many tokens we got
                outputAmount += swapList[i].swapInfo.pair.swapNFTsForToken(
                    swapList[i].swapInfo.nftIds,
                    0,
                    tokenRecipient,
                    true,
                    msg.sender
                );
            }

            unchecked {
                ++i;
            }
        }
    }

    /**
        @notice Buys NFTs with ETH and sells them for tokens in one transaction
        @param params All the parameters for the swap (packed in struct to avoid stack too deep), containing:
        - ethToNFTSwapList The list of NFTs to buy
        - nftToTokenSwapList The list of NFTs to sell
        - inputAmount The max amount of tokens to send (if ERC20)
        - tokenRecipient The address that receives tokens from the NFTs sold
        - nftRecipient The address that receives NFTs
        - deadline UNIX timestamp deadline for the swap
     */
    function robustSwapETHForSpecificNFTsAndNFTsToToken(
        RobustPairNFTsFoTokenAndTokenforNFTsTrade calldata params
    )
        external
        payable
        virtual
        returns (uint256 remainingValue, uint256 outputAmount)
    {
        {
            remainingValue = msg.value;
            uint256 pairCost;
            CurveErrorCodes.Error error;

            // Try doing each swap
            uint256 numSwaps = params.tokenToNFTTrades.length;
            for (uint256 i; i < numSwaps; ) {
                // Calculate actual cost per swap
                (error, , , pairCost, ) = params
                    .tokenToNFTTrades[i]
                    .swapInfo
                    .pair
                    .getBuyNFTQuote(
                        params.tokenToNFTTrades[i].swapInfo.nftIds.length
                    );

                // If within our maxCost and no error, proceed
                if (
                    pairCost <= params.tokenToNFTTrades[i].maxCost &&
                    error == CurveErrorCodes.Error.OK
                ) {
                    // We know how much ETH to send because we already did the math above
                    // So we just send that much
                    remainingValue -= params
                        .tokenToNFTTrades[i]
                        .swapInfo
                        .pair
                        .swapTokenForSpecificNFTs{value: pairCost}(
                        params.tokenToNFTTrades[i].swapInfo.nftIds,
                        pairCost,
                        params.nftRecipient,
                        true,
                        msg.sender
                    );
                }

                unchecked {
                    ++i;
                }
            }

            // Return remaining value to sender
            if (remainingValue > 0) {
                params.tokenRecipient.safeTransferETH(remainingValue);
            }
        }
        {
            // Try doing each swap
            uint256 numSwaps = params.nftToTokenTrades.length;
            for (uint256 i; i < numSwaps; ) {
                uint256 pairOutput;

                // Locally scoped to avoid stack too deep error
                {
                    CurveErrorCodes.Error error;
                    (error, , , pairOutput, ) = params
                        .nftToTokenTrades[i]
                        .swapInfo
                        .pair
                        .getSellNFTQuote(
                            params.nftToTokenTrades[i].swapInfo.nftIds.length
                        );
                    if (error != CurveErrorCodes.Error.OK) {
                        unchecked {
                            ++i;
                        }
                        continue;
                    }
                }

                // If at least equal to our minOutput, proceed
                if (pairOutput >= params.nftToTokenTrades[i].minOutput) {
                    // Do the swap and update outputAmount with how many tokens we got
                    outputAmount += params
                        .nftToTokenTrades[i]
                        .swapInfo
                        .pair
                        .swapNFTsForToken(
                            params.nftToTokenTrades[i].swapInfo.nftIds,
                            0,
                            params.tokenRecipient,
                            true,
                            msg.sender
                        );
                }

                unchecked {
                    ++i;
                }
            }
        }
    }

    /**
        @notice Buys NFTs with ERC20, and sells them for tokens in one transaction
        @param params All the parameters for the swap (packed in struct to avoid stack too deep), containing:
        - ethToNFTSwapList The list of NFTs to buy
        - nftToTokenSwapList The list of NFTs to sell
        - inputAmount The max amount of tokens to send (if ERC20)
        - tokenRecipient The address that receives tokens from the NFTs sold
        - nftRecipient The address that receives NFTs
        - deadline UNIX timestamp deadline for the swap
     */
    function robustSwapERC20ForSpecificNFTsAndNFTsToToken(
        RobustPairNFTsFoTokenAndTokenforNFTsTrade calldata params
    )
        external
        payable
        virtual
        returns (uint256 remainingValue, uint256 outputAmount)
    {
        {
            remainingValue = params.inputAmount;
            uint256 pairCost;
            CurveErrorCodes.Error error;

            // Try doing each swap
            uint256 numSwaps = params.tokenToNFTTrades.length;
            for (uint256 i; i < numSwaps; ) {
                // Calculate actual cost per swap
                (error, , , pairCost, ) = params
                    .tokenToNFTTrades[i]
                    .swapInfo
                    .pair
                    .getBuyNFTQuote(
                        params.tokenToNFTTrades[i].swapInfo.nftIds.length
                    );

                // If within our maxCost and no error, proceed
                if (
                    pairCost <= params.tokenToNFTTrades[i].maxCost &&
                    error == CurveErrorCodes.Error.OK
                ) {
                    remainingValue -= params
                        .tokenToNFTTrades[i]
                        .swapInfo
                        .pair
                        .swapTokenForSpecificNFTs(
                            params.tokenToNFTTrades[i].swapInfo.nftIds,
                            pairCost,
                            params.nftRecipient,
                            true,
                            msg.sender
                        );
                }

                unchecked {
                    ++i;
                }
            }
        }
        {
            // Try doing each swap
            uint256 numSwaps = params.nftToTokenTrades.length;
            for (uint256 i; i < numSwaps; ) {
                uint256 pairOutput;

                // Locally scoped to avoid stack too deep error
                {
                    CurveErrorCodes.Error error;
                    (error, , , pairOutput, ) = params
                        .nftToTokenTrades[i]
                        .swapInfo
                        .pair
                        .getSellNFTQuote(
                            params.nftToTokenTrades[i].swapInfo.nftIds.length
                        );
                    if (error != CurveErrorCodes.Error.OK) {
                        unchecked {
                            ++i;
                        }
                        continue;
                    }
                }

                // If at least equal to our minOutput, proceed
                if (pairOutput >= params.nftToTokenTrades[i].minOutput) {
                    // Do the swap and update outputAmount with how many tokens we got
                    outputAmount += params
                        .nftToTokenTrades[i]
                        .swapInfo
                        .pair
                        .swapNFTsForToken(
                            params.nftToTokenTrades[i].swapInfo.nftIds,
                            0,
                            params.tokenRecipient,
                            true,
                            msg.sender
                        );
                }

                unchecked {
                    ++i;
                }
            }
        }
    }

    receive() external payable {}

    /**
        Restricted functions
     */

    /**
        @dev Allows an ERC20 pair contract to transfer ERC20 tokens directly from
        the sender, in order to minimize the number of token transfers. Only callable by an ERC20 pair.
        @param token The ERC20 token to transfer
        @param from The address to transfer tokens from
        @param to The address to transfer tokens to
        @param amount The amount of tokens to transfer
        @param variant The pair variant of the pair contract
     */
    function pairTransferERC20From(
        ERC20 token,
        address from,
        address to,
        uint256 amount,
        ILSSVMPairFactoryLike.PairVariant variant
    ) external {
        // verify caller is a trusted pair contract
        require(factory.isPair(msg.sender, variant), "Not pair");

        // verify caller is an ERC20 pair
        require(
            variant == ILSSVMPairFactoryLike.PairVariant.ENUMERABLE_ERC20 ||
                variant ==
                ILSSVMPairFactoryLike.PairVariant.MISSING_ENUMERABLE_ERC20,
            "Not ERC20 pair"
        );

        // transfer tokens to pair
        token.safeTransferFrom(from, to, amount);
    }

    /**
        @dev Allows a pair contract to transfer ERC721 NFTs directly from
        the sender, in order to minimize the number of token transfers. Only callable by a pair.
        @param nft The ERC721 NFT to transfer
        @param from The address to transfer tokens from
        @param to The address to transfer tokens to
        @param id The ID of the NFT to transfer
        @param variant The pair variant of the pair contract
     */
    function pairTransferNFTFrom(
        IERC721 nft,
        address from,
        address to,
        uint256 id,
        ILSSVMPairFactoryLike.PairVariant variant
    ) external {
        // verify caller is a trusted pair contract
        require(factory.isPair(msg.sender, variant), "Not pair");

        // transfer NFTs to pair
        nft.safeTransferFrom(from, to, id);
    }

    /**
        Internal functions
     */

    /**
        @param deadline The last valid time for a swap
     */
    function _checkDeadline(uint256 deadline) internal view {
        require(block.timestamp <= deadline, "Deadline passed");
    }

    /**
        @notice Internal function used to swap ETH for any NFTs
        @param swapList The list of pairs and swap calldata
        @param inputAmount The total amount of ETH to send
        @param ethRecipient The address receiving excess ETH
        @param nftRecipient The address receiving the NFTs from the pairs
        @return remainingValue The unspent token amount
     */
    function _swapETHForAnyNFTs(
        PairSwapAny[] calldata swapList,
        uint256 inputAmount,
        address payable ethRecipient,
        address nftRecipient
    ) internal virtual returns (uint256 remainingValue) {
        remainingValue = inputAmount;

        uint256 pairCost;
        CurveErrorCodes.Error error;

        // Do swaps
        uint256 numSwaps = swapList.length;
        for (uint256 i; i < numSwaps; ) {
            // Calculate the cost per swap first to send exact amount of ETH over, saves gas by avoiding the need to send back excess ETH
            (error, , , pairCost, ) = swapList[i].pair.getBuyNFTQuote(
                swapList[i].numItems
            );

            // Require no error
            require(error == CurveErrorCodes.Error.OK, "Bonding curve error");

            // Total ETH taken from sender cannot exceed inputAmount
            // because otherwise the deduction from remainingValue will fail
            remainingValue -= swapList[i].pair.swapTokenForAnyNFTs{
                value: pairCost
            }(
                swapList[i].numItems,
                remainingValue,
                nftRecipient,
                true,
                msg.sender
            );

            unchecked {
                ++i;
            }
        }

        // Return remaining value to sender
        if (remainingValue > 0) {
            ethRecipient.safeTransferETH(remainingValue);
        }
    }

    /**
        @notice Internal function used to swap ETH for a specific set of NFTs
        @param swapList The list of pairs and swap calldata
        @param inputAmount The total amount of ETH to send
        @param ethRecipient The address receiving excess ETH
        @param nftRecipient The address receiving the NFTs from the pairs
        @return remainingValue The unspent token amount
     */
    function _swapETHForSpecificNFTs(
        PairSwapSpecific[] calldata swapList,
        uint256 inputAmount,
        address payable ethRecipient,
        address nftRecipient
    ) internal virtual returns (uint256 remainingValue) {
        remainingValue = inputAmount;

        uint256 pairCost;
        CurveErrorCodes.Error error;

        // Do swaps
        uint256 numSwaps = swapList.length;
        for (uint256 i; i < numSwaps; ) {
            // Calculate the cost per swap first to send exact amount of ETH over, saves gas by avoiding the need to send back excess ETH
            (error, , , pairCost, ) = swapList[i].pair.getBuyNFTQuote(
                swapList[i].nftIds.length
            );

            // Require no errors
            require(error == CurveErrorCodes.Error.OK, "Bonding curve error");

            // Total ETH taken from sender cannot exceed inputAmount
            // because otherwise the deduction from remainingValue will fail
            remainingValue -= swapList[i].pair.swapTokenForSpecificNFTs{
                value: pairCost
            }(
                swapList[i].nftIds,
                remainingValue,
                nftRecipient,
                true,
                msg.sender
            );

            unchecked {
                ++i;
            }
        }

        // Return remaining value to sender
        if (remainingValue > 0) {
            ethRecipient.safeTransferETH(remainingValue);
        }
    }

    /**
        @notice Internal function used to swap an ERC20 token for any NFTs
        @dev Note that we don't need to query the pair's bonding curve first for pricing data because
        we just calculate and take the required amount from the caller during swap time.
        However, we can't "pull" ETH, which is why for the ETH->NFT swaps, we need to calculate the pricing info
        to figure out how much the router should send to the pool.
        @param swapList The list of pairs and swap calldata
        @param inputAmount The total amount of ERC20 tokens to send
        @param nftRecipient The address receiving the NFTs from the pairs
        @return remainingValue The unspent token amount
     */
    function _swapERC20ForAnyNFTs(
        PairSwapAny[] calldata swapList,
        uint256 inputAmount,
        address nftRecipient
    ) internal virtual returns (uint256 remainingValue) {
        remainingValue = inputAmount;

        // Do swaps
        uint256 numSwaps = swapList.length;
        for (uint256 i; i < numSwaps; ) {
            // Tokens are transferred in by the pair calling router.pairTransferERC20From
            // Total tokens taken from sender cannot exceed inputAmount
            // because otherwise the deduction from remainingValue will fail
            remainingValue -= swapList[i].pair.swapTokenForAnyNFTs(
                swapList[i].numItems,
                remainingValue,
                nftRecipient,
                true,
                msg.sender
            );

            unchecked {
                ++i;
            }
        }
    }

    /**
        @notice Internal function used to swap an ERC20 token for specific NFTs
        @dev Note that we don't need to query the pair's bonding curve first for pricing data because
        we just calculate and take the required amount from the caller during swap time.
        However, we can't "pull" ETH, which is why for the ETH->NFT swaps, we need to calculate the pricing info
        to figure out how much the router should send to the pool.
        @param swapList The list of pairs and swap calldata
        @param inputAmount The total amount of ERC20 tokens to send
        @param nftRecipient The address receiving the NFTs from the pairs
        @return remainingValue The unspent token amount
     */
    function _swapERC20ForSpecificNFTs(
        PairSwapSpecific[] calldata swapList,
        uint256 inputAmount,
        address nftRecipient
    ) internal virtual returns (uint256 remainingValue) {
        remainingValue = inputAmount;

        // Do swaps
        uint256 numSwaps = swapList.length;
        for (uint256 i; i < numSwaps; ) {
            // Tokens are transferred in by the pair calling router.pairTransferERC20From
            // Total tokens taken from sender cannot exceed inputAmount
            // because otherwise the deduction from remainingValue will fail
            remainingValue -= swapList[i].pair.swapTokenForSpecificNFTs(
                swapList[i].nftIds,
                remainingValue,
                nftRecipient,
                true,
                msg.sender
            );

            unchecked {
                ++i;
            }
        }
    }

    /**
        @notice Swaps NFTs for tokens, designed to be used for 1 token at a time
        @dev Calling with multiple tokens is permitted, BUT minOutput will be
        far from enough of a safety check because different tokens almost certainly have different unit prices.
        @param swapList The list of pairs and swap calldata
        @param minOutput The minimum number of tokens to be receieved from the swaps
        @param tokenRecipient The address that receives the tokens
        @return outputAmount The number of tokens to be received
     */
    function _swapNFTsForToken(
        PairSwapSpecific[] calldata swapList,
        uint256 minOutput,
        address payable tokenRecipient
    ) internal virtual returns (uint256 outputAmount) {
        // Do swaps
        uint256 numSwaps = swapList.length;
        for (uint256 i; i < numSwaps; ) {
            // Do the swap for token and then update outputAmount
            // Note: minExpectedTokenOutput is set to 0 since we're doing an aggregate slippage check below
            outputAmount += swapList[i].pair.swapNFTsForToken(
                swapList[i].nftIds,
                0,
                tokenRecipient,
                true,
                msg.sender
            );

            unchecked {
                ++i;
            }
        }

        // Aggregate slippage check
        require(outputAmount >= minOutput, "outputAmount too low");
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.4;

import {ERC165Checker} from "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import {IOwnershipTransferCallback} from "./IOwnershipTransferCallback.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

abstract contract OwnableWithTransferCallback {
    using ERC165Checker for address;
    using Address for address;

    bytes4 constant TRANSFER_CALLBACK =
        type(IOwnershipTransferCallback).interfaceId;

    error Ownable_NotOwner();
    error Ownable_NewOwnerZeroAddress();

    address private _owner;

    event OwnershipTransferred(address indexed newOwner);

    /// @dev Initializes the contract setting the deployer as the initial owner.
    function __Ownable_init(address initialOwner) internal {
        _owner = initialOwner;
    }

    /// @dev Returns the address of the current owner.
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /// @dev Throws if called by any account other than the owner.
    modifier onlyOwner() {
        if (owner() != msg.sender) revert Ownable_NotOwner();
        _;
    }

    /// @dev Transfers ownership of the contract to a new account (`newOwner`).
    /// Disallows setting to the zero address as a way to more gas-efficiently avoid reinitialization
    /// When ownership is transferred, if the new owner implements IOwnershipTransferCallback, we make a callback
    /// Can only be called by the current owner.
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) revert Ownable_NewOwnerZeroAddress();
        _transferOwnership(newOwner);

        // Call the on ownership transfer callback if it exists
        // @dev try/catch is around 5k gas cheaper than doing ERC165 checking
        if (newOwner.isContract()) {
            try
                IOwnershipTransferCallback(newOwner).onOwnershipTransfer(msg.sender)
            {} catch (bytes memory) {}
        }
    }

    /// @dev Transfers ownership of the contract to a new account (`newOwner`).
    /// Internal function without access restriction.
    function _transferOwnership(address newOwner) internal virtual {
        _owner = newOwner;
        emit OwnershipTransferred(newOwner);
    }
}

// SPDX-License-Identifier: MIT
// Forked from OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol), 
// removed initializer check as we already do that in our modified Ownable

pragma solidity ^0.8.0;

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

    uint256 private _status;

    function __ReentrancyGuard_init() internal {
      _status = _NOT_ENTERED;
    } 

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
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

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

contract CurveErrorCodes {
    enum Error {
        OK, // No error
        INVALID_NUMITEMS, // The numItem value is 0
        SPOT_PRICE_OVERFLOW // The updated spot price doesn't fit into 128 bits
    }
}

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

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.4;

interface IOwnershipTransferCallback {
  function onOwnershipTransfer(address oldOwner) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
                /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts (last updated v4.7.2) (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            _supportsERC165Interface(account, type(IERC165).interfaceId) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        // prepare call
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);

        // perform static call
        bool success;
        uint256 returnSize;
        uint256 returnValue;
        assembly {
            success := staticcall(30000, account, add(encodedParams, 0x20), mload(encodedParams), 0x00, 0x20)
            returnSize := returndatasize()
            returnValue := mload(0x00)
        }

        return success && returnSize >= 0x20 && returnValue > 0;
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

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
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
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

        /// @solidity memory-safe-assembly
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

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}