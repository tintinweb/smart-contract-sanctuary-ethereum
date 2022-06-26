// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.7.6;
pragma abicoder v2;

import {OwnableUpgradeable} from '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import {ERC20} from '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import {ECDSA} from '@openzeppelin/contracts/cryptography/ECDSA.sol';

import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol';
import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';
import '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';
import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';

import {IHypervisor} from './interfaces/IHypervisor.sol';
import {IBabController} from './interfaces/IBabController.sol';
import {IGovernor} from './interfaces/external/oz/IGovernor.sol';
import {IGarden} from './interfaces/IGarden.sol';
import {IHeart} from './interfaces/IHeart.sol';
import {IWETH} from './interfaces/external/weth/IWETH.sol';
import {ICToken} from './interfaces/external/compound/ICToken.sol';
import {ICEther} from './interfaces/external/compound/ICEther.sol';
import {IComptroller} from './interfaces/external/compound/IComptroller.sol';
import {IPriceOracle} from './interfaces/IPriceOracle.sol';
import {IMasterSwapper} from './interfaces/IMasterSwapper.sol';
import {IVoteToken} from './interfaces/IVoteToken.sol';
import {IERC1271} from './interfaces/IERC1271.sol';

import {PreciseUnitMath} from './lib/PreciseUnitMath.sol';
import {SafeDecimalMath} from './lib/SafeDecimalMath.sol';
import {LowGasSafeMath as SafeMath} from './lib/LowGasSafeMath.sol';
import {Errors, _require, _revert} from './lib/BabylonErrors.sol';
import {ControllerLib} from './lib/ControllerLib.sol';

/**
 * @title Heart
 * @author Babylon Finance
 *
 * Contract that assists The Heart of Babylon garden with BABL staking.
 *
 */
contract Heart is OwnableUpgradeable, IHeart, IERC1271 {
    using SafeERC20 for IERC20;
    using PreciseUnitMath for uint256;
    using SafeMath for uint256;
    using SafeDecimalMath for uint256;
    using ControllerLib for IBabController;

    /* ============ Modifiers ============ */

    /**
     * Throws if the sender is not a keeper in the protocol
     */
    function _onlyKeeper() private view {
        _require(controller.isValidKeeper(msg.sender), Errors.ONLY_KEEPER);
    }

    function _onlyValidBond(
        address _assetToBond,
        uint256 _amountToBond,
        uint256 _userLock
    ) private view {
        _require(
            (_assetToBond == address(BABL) || bondAssets[_assetToBond] > 0) && _amountToBond > 0,
            Errors.AMOUNT_TOO_LOW
        );
        _require(_userLock >= MIN_HEART_LOCK_VALUE && _userLock <= MAX_HEART_LOCK_VALUE, Errors.SET_GARDEN_USER_LOCK);
    }

    /* ============ Events ============ */

    event FeesCollected(uint256 _timestamp, uint256 _amount);
    event LiquidityAdded(uint256 _timestamp, uint256 _wethBalance, uint256 _bablBalance);
    event BablBuyback(uint256 _timestamp, uint256 _wethSpent, uint256 _bablBought);
    event GardenSeedInvest(uint256 _timestamp, address indexed _garden, uint256 _wethInvested);
    event FuseLentAsset(uint256 _timestamp, address indexed _asset, uint256 _assetAmount);
    event BABLRewardSent(uint256 _timestamp, uint256 _bablSent);
    event ProposalVote(uint256 _timestamp, uint256 _proposalId, bool _isApprove);
    event UpdatedGardenWeights(uint256 _timestamp);
    event ShieldAmountIncreased(uint256 _timestamp, uint256 _wethAmount);

    /* ============ Constants ============ */

    // Only for offline use by keeper/fauna
    bytes32 private constant VOTE_PROPOSAL_TYPEHASH =
        keccak256('ProposalVote(uint256 _proposalId,uint256 _amount,bool _isApprove)');
    bytes32 private constant VOTE_GARDEN_TYPEHASH = keccak256('GardenVote(address _garden,uint256 _amount)');

    // Visor
    IHypervisor private constant visor = IHypervisor(0xF19F91d7889668A533F14d076aDc187be781a458);

    // Address of Uniswap factory
    IUniswapV3Factory internal constant factory = IUniswapV3Factory(0x1F98431c8aD98523631AE4a59f267346ea31F984);
    uint24 private constant FEE_LOW = 500;
    uint24 private constant FEE_MEDIUM = 3000;
    uint24 private constant FEE_HIGH = 10000;
    uint256 private constant DEFAULT_TRADE_SLIPPAGE = 25e15; // 2.5%

    // Tokens
    IWETH private constant WETH = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IERC20 private constant BABL = IERC20(0xF4Dc48D260C93ad6a96c5Ce563E70CA578987c74);
    IERC20 private constant DAI = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    IERC20 private constant USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IERC20 private constant WBTC = IERC20(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599);
    IERC20 private constant FRAX = IERC20(0x853d955aCEf822Db058eb8505911ED77F175b99e);
    IERC20 private constant FEI = IERC20(0x956F47F50A910163D8BF957Cf5846D573E7f87CA);

    // Fuse
    address private constant BABYLON_FUSE_POOL_ADDRESS = 0xC7125E3A2925877C7371d579D29dAe4729Ac9033;

    // Value Amount for protect purchases in DAI
    uint256 private constant PROTECT_BUY_AMOUNT_DAI = 2e21;

    uint256 private constant MIN_PUMP_WETH = 15e17; // 1.5 ETH
    // Min & max value for the heart lock
    uint256 private constant MIN_HEART_LOCK_VALUE = 183 days;
    uint256 private constant MAX_HEART_LOCK_VALUE = 4 * 365 days;

    /* ============ Immutables ============ */

    IBabController private immutable controller;
    IGovernor private immutable governor;
    address private immutable treasury;

    /* ============ State Variables ============ */

    // Instance of the Controller contract

    // Heart garden address
    IGarden public override heartGarden;

    // Variables to handle garden seed investments
    address[] public override votedGardens;
    uint256[] public override gardenWeights;

    // Min Amounts to trade
    mapping(address => uint256) public override minAmounts;

    // Fuse pool Variables
    // Mapping of asset addresses to cToken addresses in the fuse pool
    mapping(address => address) public override assetToCToken;
    // Which asset is going to receive the next batch of liquidity in fuse
    address public override assetToLend;

    // Timestamp when the heart was last pumped
    uint256 public override lastPumpAt;

    // Timestamp when the votes were sent by the keeper last
    uint256 public override lastVotesAt;

    // Amount to gift to the Heart of Babylon Garden weekly
    uint256 public override weeklyRewardAmount;
    uint256 public override bablRewardLeft;

    // Array with the weights to distribute to different heart activities
    // 0: Treasury
    // 1: Buybacks
    // 2: Liquidity BABL-ETH
    // 3: Garden Seed Investments
    // 4: Fuse Pool
    // 5: Shield
    uint256[] public override feeDistributionWeights;

    // Metric Totals
    // 0: fees accumulated in weth
    // 1: Money sent to treasury
    // 2: babl bought in babl
    // 3: liquidity added in weth
    // 4: amount invested in gardens in weth
    // 5: amount lent on fuse in weth
    // 6: weekly rewards paid in babl
    uint256[7] public override totalStats;

    // Trade slippage to apply in trades
    uint256 public override tradeSlippage;

    // Asset to use to buy protocol wanted assets
    address public override assetForPurchases;

    // Bond Assets with the discount
    mapping(address => uint256) public override bondAssets;

    // EIP-1271 signer
    address private signer;

    uint256 private shieldStats;

    /* ============ Initializer ============ */

    /**
     * Set controller and governor addresses
     *
     * @param _controller             Address of controller contract
     * @param _governor               Address of governor contract
     */
    constructor(IBabController _controller, IGovernor _governor) initializer {
        _require(address(_controller) != address(0) && address(_governor) != address(0), Errors.ADDRESS_IS_ZERO);

        controller = _controller;
        treasury = _controller.treasury();
        governor = _governor;
    }

    /**
     * Set state variables and map asset pairs to their oracles
     *
     * @param _feeWeights             Weights of the fee distribution
     */
    function initialize(uint256[] calldata _feeWeights) external initializer {
        OwnableUpgradeable.__Ownable_init();
        updateFeeWeights(_feeWeights);
        updateMarkets();
        updateAssetToLend(address(DAI));
        minAmounts[address(DAI)] = 500e18;
        minAmounts[address(USDC)] = 500e6;
        minAmounts[address(WETH)] = 5e17;
        minAmounts[address(WBTC)] = 3e6;
        tradeSlippage = DEFAULT_TRADE_SLIPPAGE;
        // Self-delegation to be able to use BABL balance as voting power
        IVoteToken(address(BABL)).delegate(address(this));
    }

    /* ============ External Functions ============ */

    /**
     * Function to pump blood to the heart
     *
     * Note: Anyone can call this. Keeper in Defender will be set up to do it for convenience.
     */
    function pump(uint256 _bablMinAmountOut) public override {
        _require(
            address(heartGarden) != address(0) &&
                block.timestamp.sub(lastPumpAt) >= 1 weeks &&
                block.timestamp.sub(lastVotesAt) < 1 weeks,
            Errors.HEART_ALREADY_PUMPED
        );
        // Consolidate all fees
        _consolidateFeesToWeth();
        uint256 wethBalance = WETH.balanceOf(address(this));
        // Use fei to pump if needed
        if (wethBalance < MIN_PUMP_WETH) {
            uint256 feiPriceInWeth = IPriceOracle(controller.priceOracle()).getPrice(address(FEI), address(WETH));
            uint256 feiNeeded = MIN_PUMP_WETH.sub(wethBalance).preciseMul(feiPriceInWeth).preciseMul(105e16); // a bit more just in case
            if (FEI.balanceOf(address(this)) >= feiNeeded) {
                _trade(address(FEI), address(WETH), feiNeeded);
            }
        }
        _require(wethBalance >= 15e17, Errors.HEART_MINIMUM_FEES);
        // Send 45% to the treasury
        IERC20(WETH).safeTransferFrom(address(this), treasury, wethBalance.preciseMul(feeDistributionWeights[0]));
        totalStats[1] = totalStats[1].add(wethBalance.preciseMul(feeDistributionWeights[0]));
        // 10% for buybacks
        _buyback(wethBalance.preciseMul(feeDistributionWeights[1]), _bablMinAmountOut);
        // 10% to BABL-ETH pair
        _addLiquidity(wethBalance.preciseMul(feeDistributionWeights[2]));
        // 20% to Garden Investments
        _investInGardens(wethBalance.preciseMul(feeDistributionWeights[3]));
        // 10% lend in fuse pool
        _lendFusePool(address(WETH), wethBalance.preciseMul(feeDistributionWeights[4]), address(assetToLend));
        // 5% to reserve pool
        _shield(wethBalance.preciseMul(feeDistributionWeights[5]));
        // Add BABL reward to stakers (if any)
        _sendWeeklyReward();
        lastPumpAt = block.timestamp;
    }

    /**
     * Function to vote for a proposal
     *
     * Note: Only keeper can call this. Votes need to have been resolved offchain.
     * Warning: Gardens need to delegate to heart first.
     */
    function voteProposal(uint256 _proposalId, bool _isApprove) external override {
        _onlyKeeper();
        // Governor does revert if trying to cast a vote twice or if proposal is not active
        IGovernor(governor).castVote(_proposalId, _isApprove ? 1 : 0);
        emit ProposalVote(block.timestamp, _proposalId, _isApprove);
    }

    /**
     * Resolves garden votes for this cycle
     *
     * Note: Only keeper can call this
     * @param _gardens             Gardens that are going to receive investment
     * @param _weights             Weight for the investment in each garden normalied to 1e18 precision
     */
    function resolveGardenVotes(address[] memory _gardens, uint256[] memory _weights) public override {
        _onlyKeeper();
        _require(_gardens.length == _weights.length, Errors.HEART_VOTES_LENGTH);
        delete votedGardens;
        delete gardenWeights;
        for (uint256 i = 0; i < _gardens.length; i++) {
            votedGardens.push(_gardens[i]);
            gardenWeights.push(_weights[i]);
        }
        lastVotesAt = block.timestamp;
        emit UpdatedGardenWeights(block.timestamp);
    }

    function resolveGardenVotesAndPump(
        address[] memory _gardens,
        uint256[] memory _weights,
        uint256 _bablMinAmountOut
    ) external override {
        resolveGardenVotes(_gardens, _weights);
        pump(_bablMinAmountOut);
    }

    /**
     * Updates fuse pool market information and enters the markets
     *
     */
    function updateMarkets() public override {
        controller.onlyGovernanceOrEmergency();
        // Enter markets of the fuse pool for all these assets
        address[] memory markets = IComptroller(BABYLON_FUSE_POOL_ADDRESS).getAllMarkets();
        for (uint256 i = 0; i < markets.length; i++) {
            address underlying = ICToken(markets[i]).underlying();
            assetToCToken[underlying] = markets[i];
        }
        IComptroller(BABYLON_FUSE_POOL_ADDRESS).enterMarkets(markets);
    }

    /**
     * Set the weights to allocate to different heart initiatives
     *
     * @param _feeWeights             Array of % (up to 1e18) with the fee weights
     */
    function updateFeeWeights(uint256[] calldata _feeWeights) public override {
        controller.onlyGovernanceOrEmergency();
        delete feeDistributionWeights;
        for (uint256 i = 0; i < _feeWeights.length; i++) {
            feeDistributionWeights.push(_feeWeights[i]);
        }
    }

    /**
     * Updates the next asset to lend on fuse pool
     *
     * @param _assetToLend             New asset to lend
     */
    function updateAssetToLend(address _assetToLend) public override {
        controller.onlyGovernanceOrEmergency();
        assetToLend = _assetToLend;
    }

    /**
     * Updates the next asset to purchase assets from strategies at a premium
     *
     * @param _purchaseAsset             New asset to purchase
     */
    function updateAssetToPurchase(address _purchaseAsset) external override {
        controller.onlyGovernanceOrEmergency();
        assetForPurchases = _purchaseAsset;
    }

    /**
     * Updates the next asset to purchase assets from strategies at a premium
     *
     * @param _assetToBond              Bond to update
     * @param _bondDiscount             Bond discount to apply 1e18
     */
    function updateBond(address _assetToBond, uint256 _bondDiscount) public override {
        controller.onlyGovernanceOrEmergency();
        bondAssets[_assetToBond] = _bondDiscount;
    }

    /**
     * Adds a BABL reward to be distributed weekly back to the heart garden
     *
     * @param _bablAmount             Total amount to distribute
     * @param _weeklyRate             Weekly amount to distribute
     */
    function addReward(uint256 _bablAmount, uint256 _weeklyRate) external override {
        controller.onlyGovernanceOrEmergency();
        // Get the BABL reward
        IERC20(BABL).safeTransferFrom(msg.sender, address(this), _bablAmount);
        bablRewardLeft = bablRewardLeft.add(_bablAmount);
        weeklyRewardAmount = _weeklyRate;
    }

    /**
     * Updates the heart garden address
     *
     * @param _heartGarden                New heart garden address
     */
    function setHeartGardenAddress(address _heartGarden) external override {
        controller.onlyGovernanceOrEmergency();
        heartGarden = IGarden(_heartGarden);
    }

    /**
     * Sets heart config param
     *
     * @param _index                Specify which param to update
     * @param _param                New param
     */
    function setHeartConfigParam(
        uint8 _index,
        uint256 _param,
        address _addressParam
    ) external override {
        controller.onlyGovernanceOrEmergency();
        if (_index == 0) {
            tradeSlippage = _param;
        }
        minAmounts[_addressParam] = _param;
    }

    /**
     * Tell the heart to lend an asset on Fuse
     *
     * @param _assetToLend                  Address of the asset to lend
     * @param _lendAmount                   Amount of the asset to lend
     */
    function lendFusePool(address _assetToLend, uint256 _lendAmount) external override {
        controller.onlyGovernanceOrEmergency();
        // Lend into fuse
        _lendFusePool(_assetToLend, _lendAmount, _assetToLend);
    }

    /**
     * Heart borrows using its liquidity
     * Note: Heart must have enough liquidity
     *
     * @param _assetToBorrow              Asset that the heart is receiving from sender
     * @param _borrowAmount               Amount of asset to transfet
     */
    function borrowFusePool(address _assetToBorrow, uint256 _borrowAmount) external override {
        controller.onlyGovernanceOrEmergency();
        _require(ICToken(assetToCToken[_assetToBorrow]).borrow(_borrowAmount) == 0, Errors.NOT_ENOUGH_COLLATERAL);
    }

    /**
     * Repays Heart fuse pool position
     * Note: We must have the asset in the heart
     *
     * @param _borrowedAsset              Borrowed asset that we want to pay
     * @param _amountToRepay              Amount of asset to transfer
     */
    function repayFusePool(address _borrowedAsset, uint256 _amountToRepay) external override {
        controller.onlyGovernanceOrEmergency();
        address cToken = assetToCToken[_borrowedAsset];
        IERC20(_borrowedAsset).safeApprove(cToken, _amountToRepay);
        _require(ICToken(cToken).repayBorrow(_amountToRepay) == 0, Errors.AMOUNT_TOO_LOW);
    }

    /**
    * Trades one asset for another in the heart
    * Note: We must have the _fromAsset _fromAmount available.

    * @param _fromAsset                  Asset to exchange
    * @param _toAsset                    Asset to receive
    * @param _fromAmount                 Amount of asset to exchange
    * @param _minAmountOut                  Min amount of received asset
    */
    function trade(
        address _fromAsset,
        address _toAsset,
        uint256 _fromAmount,
        uint256 _minAmountOut
    ) external override {
        controller.onlyGovernanceOrEmergency();
        uint256 boughtAmount = _trade(_fromAsset, _toAsset, _fromAmount);
        _require(boughtAmount >= _minAmountOut, Errors.SLIPPAGE_TOO_HIH);
    }

    /**
     * Strategies can sell wanted assets by the protocol to the heart.
     * Heart will buy them using borrowings in stables.
     * Heart returns WETH so master swapper will take it from there.
     * Note: Strategy needs to have approved the heart.
     *
     * @param _assetToSell                  Asset that the heart is receiving from strategy to sell
     * @param _amountToSell                 Amount of asset to sell
     */
    function sellWantedAssetToHeart(address _assetToSell, uint256 _amountToSell) external override {
        _require(
            controller.isSystemContract(msg.sender) && controller.protocolWantedAssets(_assetToSell),
            Errors.HEART_ASSET_PURCHASE_INVALID
        );
        // Uses on chain oracle to fetch prices
        uint256 pricePerTokenUnit = IPriceOracle(controller.priceOracle()).getPrice(_assetToSell, assetForPurchases);
        _require(pricePerTokenUnit != 0, Errors.NO_PRICE_FOR_TRADE);
        uint256 amountInPurchaseAssetOffered = pricePerTokenUnit.preciseMul(_amountToSell);
        _require(
            IERC20(assetForPurchases).balanceOf(address(this)) >= amountInPurchaseAssetOffered,
            Errors.BALANCE_TOO_LOW
        );
        IERC20(_assetToSell).safeTransferFrom(msg.sender, address(this), _amountToSell);
        // Buy it from the strategy plus 1% premium
        uint256 wethTraded = _trade(assetForPurchases, address(WETH), amountInPurchaseAssetOffered.preciseMul(101e16));
        // Send weth back to the strategy
        IERC20(WETH).safeTransfer(msg.sender, wethTraded);
    }

    /**
     * Users can bond an asset that belongs to the program and receive a discount on hBABL.
     * Note: Heart needs to have enough BABL to satisfy the discount.
     * Note: User needs to approve the asset to bond first.
     *
     * @param _assetToBond                  Asset that the user wants to bond
     * @param _amountToBond                 Amount to be bonded
     * @param _minAmountOut                 Min amount of Heart garden shares to recieve
     * @param _userLock                     Amount of time to lock the principal in the heart garden
     */
    function bondAsset(
        address _assetToBond,
        uint256 _amountToBond,
        uint256 _minAmountOut,
        address _referrer,
        uint256 _userLock
    ) external override {
        _onlyValidBond(_assetToBond, _amountToBond, _userLock);
        // Total value adding the premium and the lock premium
        uint256 bondValueInBABL =
            _bondToBABL(
                _assetToBond,
                _amountToBond,
                IPriceOracle(controller.priceOracle()).getPrice(_assetToBond, address(BABL)),
                _userLock
            );
        // Get asset to bond from sender
        IERC20(_assetToBond).safeTransferFrom(
            msg.sender,
            _assetToBond == address(DAI) ? treasury : address(this),
            _amountToBond
        );

        // Deposit on behalf of the user
        _require(BABL.balanceOf(address(this)) >= bondValueInBABL, Errors.AMOUNT_TOO_LOW);

        BABL.safeApprove(address(heartGarden), bondValueInBABL);

        uint256 balanceBefore = heartGarden.balanceOf(address(heartGarden));
        heartGarden.deposit(bondValueInBABL, _minAmountOut, msg.sender, _referrer);

        // Updates the lock
        heartGarden.updateUserLock(msg.sender, _userLock, balanceBefore);
    }

    /**
     * Users can bond an asset that belongs to the program and receive a discount on hBABL.
     * Note: Heart needs to have enough BABL to satisfy the discount.
     * Note: User needs to approve the asset to bond first.
     *
     * @param _assetToBond                  Asset that the user wants to bond
     * @param _amountToBond                 Amount to be bonded
     */
    function bondAssetBySig(
        address _assetToBond,
        uint256 _amountToBond,
        uint256 _amountIn,
        uint256 _minAmountOut,
        uint256 _nonce,
        uint256 _maxFee,
        uint256 _priceInBABL,
        uint256 _pricePerShare,
        uint256[2] calldata _feeAndLock,
        address _contributor,
        address _referrer,
        bytes memory _signature
    ) external override {
        _onlyKeeper();
        _onlyValidBond(_assetToBond, _amountToBond, _feeAndLock[1]);
        _require(_feeAndLock[0] <= _maxFee, Errors.FEE_TOO_HIGH);
        // Get asset to bond from contributor
        IERC20(_assetToBond).safeTransferFrom(
            _contributor,
            _assetToBond == address(DAI) ? treasury : address(this),
            _amountToBond
        );
        // Deposit on behalf of the user
        _require(BABL.balanceOf(address(this)) >= _amountIn, Errors.AMOUNT_TOO_LOW);

        // verify that _amountIn is correct compare to _amountToBond
        uint256 val = _bondToBABL(_assetToBond, _amountToBond, _priceInBABL, _feeAndLock[1]);
        val = val > _amountIn ? val.sub(_amountIn) : _amountIn.sub(val);
        // allow 0.1% deviation
        _require(val < _amountIn.div(1000), Errors.INVALID_AMOUNT);

        BABL.safeApprove(address(heartGarden), _amountIn);

        // Pay the fee to the Keeper
        IERC20(BABL).safeTransfer(msg.sender, _feeAndLock[0]);

        // grant permission to deposit
        signer = _contributor;
        uint256 balanceBefore = heartGarden.balanceOf(address(heartGarden));
        heartGarden.depositBySig(
            _amountIn,
            _minAmountOut,
            _nonce,
            _maxFee,
            _contributor,
            _pricePerShare,
            0,
            address(this),
            _referrer,
            _signature
        );
        // Update user lock
        heartGarden.updateUserLock(_contributor, _feeAndLock[1], balanceBefore);
        // revoke permission to deposit
        signer = address(0);
    }

    /**
     * Heart will protect and buyback BABL whenever the price dips below the intended price protection.
     * Note: Asset for purchases needs to be setup and have enough balance.
     *
     * @param _bablPriceProtectionAt        BABL Price in DAI to protect
     * @param _bablPrice                    Market price of BABL in DAI
     * @param _purchaseAssetPrice           Price of purchase asset in DAI
     * @param _slippage                     Trade slippage on UinV3 to control amount of arb
     * @param _hopToken            Hop token to use for UniV3 trade
     */
    function protectBABL(
        uint256 _bablPriceProtectionAt,
        uint256 _bablPrice,
        uint256 _purchaseAssetPrice,
        uint256 _slippage,
        address _hopToken
    ) external override {
        _onlyKeeper();
        _require(_bablPriceProtectionAt > 0 && _bablPrice <= _bablPriceProtectionAt, Errors.AMOUNT_TOO_HIGH);

        _require(
            SafeDecimalMath.normalizeAmountTokens(
                assetForPurchases,
                address(DAI),
                _purchaseAssetPrice.preciseMul(IERC20(assetForPurchases).balanceOf(address(this)))
            ) >= PROTECT_BUY_AMOUNT_DAI,
            Errors.NOT_ENOUGH_AMOUNT
        );

        uint256 exactAmount = PROTECT_BUY_AMOUNT_DAI.preciseDiv(_bablPrice);
        uint256 minAmountOut = exactAmount.sub(exactAmount.preciseMul(_slippage == 0 ? tradeSlippage : _slippage));

        uint256 bablBought =
            _trade(
                assetForPurchases,
                address(BABL),
                SafeDecimalMath.normalizeAmountTokens(
                    address(DAI),
                    assetForPurchases,
                    PROTECT_BUY_AMOUNT_DAI.preciseDiv(_purchaseAssetPrice)
                ),
                minAmountOut,
                _hopToken != address(0) ? _hopToken : address(WETH)
            );

        totalStats[2] = totalStats[2].add(bablBought);

        emit BablBuyback(block.timestamp, PROTECT_BUY_AMOUNT_DAI, bablBought);
    }

    // solhint-disable-next-line
    receive() external payable {}

    /* ============ External View Functions ============ */

    /**
     * Getter to get the whole array of voted gardens
     *
     * @return            The array of voted gardens
     */
    function getVotedGardens() external view override returns (address[] memory) {
        return votedGardens;
    }

    /**
     * Getter to get the whole array of garden weights
     *
     * @return            The array of weights for voted gardens
     */
    function getGardenWeights() external view override returns (uint256[] memory) {
        return gardenWeights;
    }

    /**
     * Getter to get the whole array of fee weights
     *
     * @return            The array of weights for the fees
     */
    function getFeeDistributionWeights() external view override returns (uint256[] memory) {
        return feeDistributionWeights;
    }

    /**
     * Getter to get the whole array of total stats
     *
     * @return            The array of stats for the fees
     */
    function getTotalStats() external view override returns (uint256[] memory) {
        uint256[] memory stats = new uint256[](totalStats.length + 1);
        for (uint8 i = 0; i < totalStats.length; i++) {
            stats[i] = totalStats[i];
        }
        stats[totalStats.length] = shieldStats;
        return stats;
    }

    /**
     * Implements EIP-1271
     */
    function isValidSignature(bytes32 _hash, bytes memory _signature) public view override returns (bytes4 magicValue) {
        address recovered = ECDSA.recover(_hash, _signature);
        return recovered == signer && recovered != address(0) ? this.isValidSignature.selector : bytes4(0);
    }

    /* ============ Internal Functions ============ */

    function _bondToBABL(
        address _assetToBond,
        uint256 _amountToBond,
        uint256 _priceInBABL,
        uint256 _userLock
    ) private view returns (uint256) {
        uint256 bondPremium = bondAssets[_assetToBond];

        // Check time premium
        if (_userLock >= 365 days && _userLock < 730 days) {
            bondPremium = bondPremium.add(2e16); //2%
        }
        if (_userLock >= 730 days && _userLock < MAX_HEART_LOCK_VALUE) {
            bondPremium = bondPremium.add(45e15); //4.5%
        }
        if (_userLock >= MAX_HEART_LOCK_VALUE) {
            bondPremium = bondPremium.add(1e17); //10%
        }

        return
            SafeDecimalMath.normalizeAmountTokens(_assetToBond, address(BABL), _amountToBond).preciseMul(
                _priceInBABL.preciseMul(uint256(1e18).add(bondPremium))
            );
    }

    /**
     * Consolidates all reserve asset fees to weth
     *
     */
    function _consolidateFeesToWeth() private {
        address[] memory reserveAssets = controller.getReserveAssets();
        for (uint256 i = 0; i < reserveAssets.length; i++) {
            address reserveAsset = reserveAssets[i];
            uint256 balance = IERC20(reserveAsset).balanceOf(address(this));
            // Trade if it's above a min amount (otherwise wait until next pump)
            if (reserveAsset != address(BABL) && reserveAsset != address(WETH) && balance > minAmounts[reserveAsset]) {
                totalStats[0] = totalStats[0].add(_trade(reserveAsset, address(WETH), balance));
            }
            if (reserveAsset == address(WETH)) {
                totalStats[0] = totalStats[0].add(balance);
            }
        }
        emit FeesCollected(block.timestamp, IERC20(WETH).balanceOf(address(this)));
    }

    /**
     * Buys back BABL through the uniswap V3 BABL-ETH pool
     *
     */
    function _buyback(uint256 _amount, uint256 _bablMinAmountOut) private {
        // Gift 50% BABL back to garden and send 50% to the treasury
        // _bablMinAmountOut to avoid MEV sandwhich attacks
        uint256 bablBought = _trade(address(WETH), address(BABL), _amount, _bablMinAmountOut, address(0)); // 50%
        IERC20(BABL).safeTransfer(address(heartGarden), bablBought.div(2));
        IERC20(BABL).safeTransfer(treasury, bablBought.div(2));
        totalStats[2] = totalStats[2].add(bablBought);
        emit BablBuyback(block.timestamp, _amount, bablBought);
    }

    /**
     * Adds liquidity to the BABL-ETH pair through the hypervisor
     *
     * Note: Address of the heart needs to be whitelisted by Visor.
     */
    function _addLiquidity(uint256 _wethBalance) private {
        // Buy BABL again with half to add 50/50
        uint256 wethToDeposit = _wethBalance.preciseMul(5e17);
        uint256 bablTraded = _trade(address(WETH), address(BABL), wethToDeposit); // 50%
        BABL.safeApprove(address(visor), bablTraded);
        IERC20(WETH).safeApprove(address(visor), wethToDeposit);
        uint256 oldTreasuryBalance = visor.balanceOf(treasury);
        uint256 shares = visor.deposit(wethToDeposit, bablTraded, treasury);
        _require(
            shares == visor.balanceOf(treasury).sub(oldTreasuryBalance) && visor.balanceOf(treasury) > 0,
            Errors.HEART_LP_TOKENS
        );
        totalStats[3] += _wethBalance;
        emit LiquidityAdded(block.timestamp, wethToDeposit, bablTraded);
    }

    /**
     * Invests in gardens using WETH converting it to garden reserve asset first
     *
     * @param _wethAmount             Total amount of weth to invest in all gardens
     */
    function _investInGardens(uint256 _wethAmount) private {
        for (uint256 i = 0; i < votedGardens.length; i++) {
            address reserveAsset = IGarden(votedGardens[i]).reserveAsset();
            uint256 amountTraded;
            if (reserveAsset != address(WETH)) {
                amountTraded = _trade(address(WETH), reserveAsset, _wethAmount.preciseMul(gardenWeights[i]));
            } else {
                amountTraded = _wethAmount.preciseMul(gardenWeights[i]);
            }
            // Gift it to garden
            IERC20(reserveAsset).safeTransfer(votedGardens[i], amountTraded);
            emit GardenSeedInvest(block.timestamp, votedGardens[i], _wethAmount.preciseMul(gardenWeights[i]));
        }
        totalStats[4] += _wethAmount;
    }

    /**
     * Lends an amount of WETH converting it first to the pool asset that is the lowest (except BABL)
     *
     * @param _fromAsset            Which asset to convert
     * @param _fromAmount           Total amount of weth to lend
     * @param _lendAsset            Address of the asset to lend
     */
    function _lendFusePool(
        address _fromAsset,
        uint256 _fromAmount,
        address _lendAsset
    ) private {
        address cToken = assetToCToken[_lendAsset];
        _require(cToken != address(0), Errors.HEART_INVALID_CTOKEN);
        uint256 assetToLendBalance = _fromAmount;
        // Trade to asset to lend if needed
        if (_fromAsset != _lendAsset) {
            assetToLendBalance = _trade(
                address(_fromAsset),
                _lendAsset == address(0) ? address(WETH) : _lendAsset,
                _fromAmount
            );
        }
        if (_lendAsset == address(0)) {
            // Convert WETH to ETH
            IWETH(WETH).withdraw(_fromAmount);
            ICEther(cToken).mint{value: _fromAmount}();
        } else {
            IERC20(_lendAsset).safeApprove(cToken, assetToLendBalance);
            _require(ICToken(cToken).mint(assetToLendBalance) == 0, Errors.MINT_ERROR);
        }
        uint256 assetToLendWethPrice = IPriceOracle(controller.priceOracle()).getPrice(_lendAsset, address(WETH));
        uint256 assettoLendBalanceInWeth = assetToLendBalance.preciseMul(assetToLendWethPrice);
        totalStats[5] = totalStats[5].add(assettoLendBalanceInWeth);
        emit FuseLentAsset(block.timestamp, _lendAsset, assettoLendBalanceInWeth);
    }

    /**
     * Sends 5% to the reserve pool to buy coverage and create an incidentals reserve
     *
     * @param _amount             Total amount of weth to allocate to the shield
     */
    function _shield(uint256 _amount) private {
        // Convert to ETH
        WETH.withdraw(_amount);
        shieldStats = shieldStats.add(_amount);
        emit ShieldAmountIncreased(block.timestamp, _amount);
    }

    /**
     * Sends the weekly BABL reward to the garden (if any)
     */
    function _sendWeeklyReward() private {
        if (bablRewardLeft > 0) {
            uint256 bablToSend = bablRewardLeft < weeklyRewardAmount ? bablRewardLeft : weeklyRewardAmount;
            uint256 currentBalance = IERC20(BABL).balanceOf(address(this));
            bablToSend = currentBalance < bablToSend ? currentBalance : bablToSend;
            IERC20(BABL).safeTransfer(address(heartGarden), bablToSend);
            bablRewardLeft = bablRewardLeft.sub(bablToSend);
            emit BABLRewardSent(block.timestamp, bablToSend);
            totalStats[6] = totalStats[6].add(bablToSend);
        }
    }

    /**
     * Trades _tokenIn to _tokenOut using Uniswap V3
     *
     * @param _tokenIn             Token that is sold
     * @param _tokenOut            Token that is purchased
     * @param _amount              Amount of tokenin to sell
     */
    function _trade(
        address _tokenIn,
        address _tokenOut,
        uint256 _amount
    ) private returns (uint256) {
        if (_tokenIn == _tokenOut) {
            return _amount;
        }
        // Uses on chain oracle for all internal strategy operations to avoid attacks
        uint256 pricePerTokenUnit = IPriceOracle(controller.priceOracle()).getPrice(_tokenIn, _tokenOut);
        _require(pricePerTokenUnit != 0, Errors.NO_PRICE_FOR_TRADE);

        // minAmount must have receive token decimals
        uint256 exactAmount =
            SafeDecimalMath.normalizeAmountTokens(_tokenIn, _tokenOut, _amount.preciseMul(pricePerTokenUnit));
        uint256 minAmountOut = exactAmount.sub(exactAmount.preciseMul(tradeSlippage));

        return _trade(_tokenIn, _tokenOut, _amount, minAmountOut, address(0));
    }

    /**
     * Trades _tokenIn to _tokenOut using Uniswap V3
     *
     * @param _tokenIn             Token that is sold
     * @param _tokenOut            Token that is purchased
     * @param _amount              Amount of tokenin to sell
     * @param _minAmountOut        Min amount of tokens out to recive
     * @param _hopToken            Hop token to use for UniV3 trade
     */
    function _trade(
        address _tokenIn,
        address _tokenOut,
        uint256 _amount,
        uint256 _minAmountOut,
        address _hopToken
    ) private returns (uint256) {
        ISwapRouter swapRouter = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
        // Approve the router to spend token in.
        TransferHelper.safeApprove(_tokenIn, address(swapRouter), _amount);
        bytes memory path;
        if (
            (_tokenIn == address(FRAX) && _tokenOut != address(DAI)) ||
            (_tokenOut == address(FRAX) && _tokenIn != address(DAI))
        ) {
            _hopToken = address(DAI);
        } else {
            if (
                (_tokenIn == address(FEI) && _tokenOut != address(USDC)) ||
                (_tokenOut == address(FEI) && _tokenIn != address(USDC))
            ) {
                _hopToken = address(USDC);
            }
        }
        if (_hopToken != address(0)) {
            uint24 fee0 = _getUniswapPoolFeeWithHighestLiquidity(_tokenIn, _hopToken);
            uint24 fee1 = _getUniswapPoolFeeWithHighestLiquidity(_tokenOut, _hopToken);
            // Have to use WETH for BABL because the most liquid pari is WETH/BABL
            if (_tokenOut == address(BABL) && _hopToken != address(WETH)) {
                path = abi.encodePacked(
                    _tokenIn,
                    fee0,
                    _hopToken,
                    fee1,
                    address(WETH),
                    _getUniswapPoolFeeWithHighestLiquidity(address(WETH), _tokenOut),
                    _tokenOut
                );
            } else {
                path = abi.encodePacked(_tokenIn, fee0, _hopToken, fee1, _tokenOut);
            }
        } else {
            uint24 fee = _getUniswapPoolFeeWithHighestLiquidity(_tokenIn, _tokenOut);
            path = abi.encodePacked(_tokenIn, fee, _tokenOut);
        }

        ISwapRouter.ExactInputParams memory params =
            ISwapRouter.ExactInputParams(path, address(this), block.timestamp, _amount, _minAmountOut);
        return swapRouter.exactInput(params);
    }

    /**
     * Returns the FEE of the highest liquidity pool in univ3 for this pair
     * @param sendToken               Token that is sold
     * @param receiveToken            Token that is purchased
     */
    function _getUniswapPoolFeeWithHighestLiquidity(address sendToken, address receiveToken)
        private
        view
        returns (uint24)
    {
        IUniswapV3Pool poolLow = IUniswapV3Pool(factory.getPool(sendToken, receiveToken, FEE_LOW));
        IUniswapV3Pool poolMedium = IUniswapV3Pool(factory.getPool(sendToken, receiveToken, FEE_MEDIUM));
        IUniswapV3Pool poolHigh = IUniswapV3Pool(factory.getPool(sendToken, receiveToken, FEE_HIGH));

        uint128 liquidityLow = address(poolLow) != address(0) ? poolLow.liquidity() : 0;
        uint128 liquidityMedium = address(poolMedium) != address(0) ? poolMedium.liquidity() : 0;
        uint128 liquidityHigh = address(poolHigh) != address(0) ? poolHigh.liquidity() : 0;
        if (liquidityLow >= liquidityMedium && liquidityLow >= liquidityHigh) {
            return FEE_LOW;
        }
        if (liquidityMedium >= liquidityLow && liquidityMedium >= liquidityHigh) {
            return FEE_MEDIUM;
        }
        return FEE_HIGH;
    }
}

contract HeartV7 is Heart {
    constructor(IBabController _controller, IGovernor _governor) Heart(_controller, _governor) {}
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Check the signature length
        if (signature.length != 65) {
            revert("ECDSA: invalid signature length");
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover-bytes32-bytes-} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * replicates the behavior of the
     * https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign[`eth_sign`]
     * JSON-RPC method.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title The interface for the Uniswap V3 Factory
/// @notice The Uniswap V3 Factory facilitates creation of Uniswap V3 pools and control over the protocol fees
interface IUniswapV3Factory {
    /// @notice Emitted when the owner of the factory is changed
    /// @param oldOwner The owner before the owner was changed
    /// @param newOwner The owner after the owner was changed
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    /// @notice Emitted when a pool is created
    /// @param token0 The first token of the pool by address sort order
    /// @param token1 The second token of the pool by address sort order
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks
    /// @param pool The address of the created pool
    event PoolCreated(
        address indexed token0,
        address indexed token1,
        uint24 indexed fee,
        int24 tickSpacing,
        address pool
    );

    /// @notice Emitted when a new fee amount is enabled for pool creation via the factory
    /// @param fee The enabled fee, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks for pools created with the given fee
    event FeeAmountEnabled(uint24 indexed fee, int24 indexed tickSpacing);

    /// @notice Returns the current owner of the factory
    /// @dev Can be changed by the current owner via setOwner
    /// @return The address of the factory owner
    function owner() external view returns (address);

    /// @notice Returns the tick spacing for a given fee amount, if enabled, or 0 if not enabled
    /// @dev A fee amount can never be removed, so this value should be hard coded or cached in the calling context
    /// @param fee The enabled fee, denominated in hundredths of a bip. Returns 0 in case of unenabled fee
    /// @return The tick spacing
    function feeAmountTickSpacing(uint24 fee) external view returns (int24);

    /// @notice Returns the pool address for a given pair of tokens and a fee, or address 0 if it does not exist
    /// @dev tokenA and tokenB may be passed in either token0/token1 or token1/token0 order
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @return pool The pool address
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);

    /// @notice Creates a pool for the given two tokens and fee
    /// @param tokenA One of the two tokens in the desired pool
    /// @param tokenB The other of the two tokens in the desired pool
    /// @param fee The desired fee for the pool
    /// @dev tokenA and tokenB may be passed in either order: token0/token1 or token1/token0. tickSpacing is retrieved
    /// from the fee. The call will revert if the pool already exists, the fee is invalid, or the token arguments
    /// are invalid.
    /// @return pool The address of the newly created pool
    function createPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external returns (address pool);

    /// @notice Updates the owner of the factory
    /// @dev Must be called by the current owner
    /// @param _owner The new owner of the factory
    function setOwner(address _owner) external;

    /// @notice Enables a fee amount with the given tickSpacing
    /// @dev Fee amounts may never be removed once enabled
    /// @param fee The fee amount to enable, denominated in hundredths of a bip (i.e. 1e-6)
    /// @param tickSpacing The spacing between ticks to be enforced for all pools created with the given fee amount
    function enableFeeAmount(uint24 fee, int24 tickSpacing) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');
    }

    /// @notice Approves the stipulated contract to spend the given allowance in the given token
    /// @dev Errors with 'SA' if transfer fails
    /// @param token The contract address of the token to be approved
    /// @param to The target of the approval
    /// @param value The amount of the given token the target will be allowed to spend
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SA');
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import './pool/IUniswapV3PoolImmutables.sol';
import './pool/IUniswapV3PoolState.sol';
import './pool/IUniswapV3PoolDerivedState.sol';
import './pool/IUniswapV3PoolActions.sol';
import './pool/IUniswapV3PoolOwnerActions.sol';
import './pool/IUniswapV3PoolEvents.sol';

/// @title The interface for a Uniswap V3 Pool
/// @notice A Uniswap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IUniswapV3Pool is
    IUniswapV3PoolImmutables,
    IUniswapV3PoolState,
    IUniswapV3PoolDerivedState,
    IUniswapV3PoolActions,
    IUniswapV3PoolOwnerActions,
    IUniswapV3PoolEvents
{

}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.7.6;
pragma abicoder v2;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IHypervisor {
    // @param deposit0 Amount of token0 transfered from sender to Hypervisor
    // @param deposit1 Amount of token0 transfered from sender to Hypervisor
    // @param to Address to which liquidity tokens are minted
    // @return shares Quantity of liquidity tokens minted as a result of deposit
    function deposit(
        uint256 deposit0,
        uint256 deposit1,
        address to
    ) external returns (uint256);

    // @param shares Number of liquidity tokens to redeem as pool assets
    // @param to Address to which redeemed pool assets are sent
    // @param from Address from which liquidity tokens are sent
    // @return amount0 Amount of token0 redeemed by the submitted liquidity tokens
    // @return amount1 Amount of token1 redeemed by the submitted liquidity tokens
    function withdraw(
        uint256 shares,
        address to,
        address from
    ) external returns (uint256, uint256);

    function rebalance(
        int24 _baseLower,
        int24 _baseUpper,
        int24 _limitLower,
        int24 _limitUpper,
        address _feeRecipient,
        int256 swapQuantity
    ) external;

    function addBaseLiquidity(uint256 amount0, uint256 amount1) external;

    function addLimitLiquidity(uint256 amount0, uint256 amount1) external;

    function pullLiquidity(uint256 shares)
        external
        returns (
            uint256 base0,
            uint256 base1,
            uint256 limit0,
            uint256 limit1
        );

    function token0() external view returns (IERC20);

    function token1() external view returns (IERC20);

    function pool() external view returns (address);

    function balanceOf(address) external view returns (uint256);

    function approve(address, uint256) external returns (bool);

    function transferFrom(
        address,
        address,
        uint256
    ) external returns (bool);

    function transfer(address, uint256) external returns (bool);

    function getTotalAmounts() external view returns (uint256 total0, uint256 total1);

    function pendingFees() external returns (uint256 fees0, uint256 fees1);

    function totalSupply() external view returns (uint256);

    function setMaxTotalSupply(uint256 _maxTotalSupply) external;

    function setDepositMax(uint256 _deposit0Max, uint256 _deposit1Max) external;

    function appendList(address[] memory listed) external;

    function toggleWhitelist() external;

    function transferOwnership(address newOwner) external;
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.7.6;

/**
 * @title IBabController
 * @author Babylon Finance
 *
 * Interface for interacting with BabController
 */
interface IBabController {
    /* ============ Functions ============ */

    function createGarden(
        address _reserveAsset,
        string memory _name,
        string memory _symbol,
        string memory _tokenURI,
        uint256 _seed,
        uint256[] calldata _gardenParams,
        uint256 _initialContribution,
        bool[] memory _publicGardenStrategistsStewards,
        uint256[] memory _profitSharing
    ) external payable returns (address);

    function removeGarden(address _garden) external;

    function addReserveAsset(address _reserveAsset) external;

    function removeReserveAsset(address _reserveAsset) external;

    function updateProtocolWantedAsset(address _wantedAsset, bool _wanted) external;

    function updateGardenAffiliateRate(address _garden, uint256 _affiliateRate) external;

    function addAffiliateReward(
        address _depositor,
        address _referrer,
        uint256 _reserveAmount
    ) external;

    function claimRewards() external;

    function editPriceOracle(address _priceOracle) external;

    function editMardukGate(address _mardukGate) external;

    function editGardenValuer(address _gardenValuer) external;

    function editTreasury(address _newTreasury) external;

    function editHeart(address _newHeart) external;

    function editRewardsDistributor(address _rewardsDistributor) external;

    function editGardenFactory(address _newGardenFactory) external;

    function editGardenNFT(address _newGardenNFT) external;

    function editStrategyNFT(address _newStrategyNFT) external;

    function editStrategyFactory(address _newStrategyFactory) external;

    function setOperation(uint8 _kind, address _operation) external;

    function setMasterSwapper(address _newMasterSwapper) external;

    function addKeeper(address _keeper) external;

    function addKeepers(address[] memory _keepers) external;

    function removeKeeper(address _keeper) external;

    function enableGardenTokensTransfers() external;

    function editLiquidityReserve(address _reserve, uint256 _minRiskyPairLiquidityEth) external;

    function patchIntegration(address _old, address _new) external;

    function gardenCreationIsOpen() external view returns (bool);

    function owner() external view returns (address);

    function EMERGENCY_OWNER() external view returns (address);

    function guardianGlobalPaused() external view returns (bool);

    function guardianPaused(address _address) external view returns (bool);

    function setPauseGuardian(address _guardian) external;

    function setGlobalPause(bool _state) external returns (bool);

    function setSomePause(address[] memory _address, bool _state) external returns (bool);

    function isPaused(address _contract) external view returns (bool);

    function priceOracle() external view returns (address);

    function gardenValuer() external view returns (address);

    function heart() external view returns (address);

    function gardenNFT() external view returns (address);

    function strategyNFT() external view returns (address);

    function rewardsDistributor() external view returns (address);

    function gardenFactory() external view returns (address);

    function treasury() external view returns (address);

    function ishtarGate() external view returns (address);

    function mardukGate() external view returns (address);

    function strategyFactory() external view returns (address);

    function masterSwapper() external view returns (address);

    function gardenTokensTransfersEnabled() external view returns (bool);

    function bablMiningProgramEnabled() external view returns (bool);

    function allowPublicGardens() external view returns (bool);

    function enabledOperations(uint256 _kind) external view returns (address);

    function getGardens() external view returns (address[] memory);

    function getReserveAssets() external view returns (address[] memory);

    function getOperations() external view returns (address[20] memory);

    function isGarden(address _garden) external view returns (bool);

    function protocolWantedAssets(address _wantedAsset) external view returns (bool);

    function gardenAffiliateRates(address _wantedAsset) external view returns (uint256);

    function affiliateRewards(address _user) external view returns (uint256);

    function patchedIntegrations(address _integration) external view returns (address);

    function isValidReserveAsset(address _reserveAsset) external view returns (bool);

    function isValidKeeper(address _keeper) external view returns (bool);

    function isSystemContract(address _contractAddress) external view returns (bool);

    function protocolPerformanceFee() external view returns (uint256);

    function protocolManagementFee() external view returns (uint256);

    function minLiquidityPerReserve(address _reserve) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (governance/IGovernor.sol)

pragma solidity ^0.7.6;
pragma abicoder v2;

/**
 * @dev Interface of the {Governor} core.
 *
 * _Available since v4.3._
 */
abstract contract IGovernor {
    enum ProposalState {Pending, Active, Canceled, Defeated, Succeeded, Queued, Expired, Executed}

    /**
     * @dev Emitted when a proposal is created.
     */
    event ProposalCreated(
        uint256 proposalId,
        address proposer,
        address[] targets,
        uint256[] values,
        string[] signatures,
        bytes[] calldatas,
        uint256 startBlock,
        uint256 endBlock,
        string description
    );

    /**
     * @dev Emitted when a proposal is canceled.
     */
    event ProposalCanceled(uint256 proposalId);

    /**
     * @dev Emitted when a proposal is executed.
     */
    event ProposalExecuted(uint256 proposalId);

    /**
     * @dev Emitted when a vote is cast.
     *
     * Note: `support` values should be seen as buckets. There interpretation depends on the voting module used.
     */
    event VoteCast(address indexed voter, uint256 proposalId, uint8 support, uint256 weight, string reason);

    /**
     * @notice module:core
     * @dev Name of the governor instance (used in building the ERC712 domain separator).
     */
    function name() public view virtual returns (string memory);

    /**
     * @notice module:core
     * @dev Version of the governor instance (used in building the ERC712 domain separator). Default: "1"
     */
    function version() public view virtual returns (string memory);

    function proposals(uint256 _proposalId)
        public
        view
        virtual
        returns (
            uint256,
            address,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            bool,
            bool
        );

    /**
     * @notice module:voting
     * @dev A description of the possible `support` values for {castVote} and the way these votes are counted, meant to
     * be consumed by UIs to show correct vote options and interpret the results. The string is a URL-encoded sequence of
     * key-value pairs that each describe one aspect, for example `support=bravo&quorum=for,abstain`.
     *
     * There are 2 standard keys: `support` and `quorum`.
     *
     * - `support=bravo` refers to the vote options 0 = Against, 1 = For, 2 = Abstain, as in `GovernorBravo`.
     * - `quorum=bravo` means that only For votes are counted towards quorum.
     * - `quorum=for,abstain` means that both For and Abstain votes are counted towards quorum.
     *
     * NOTE: The string can be decoded by the standard
     * https://developer.mozilla.org/en-US/docs/Web/API/URLSearchParams[`URLSearchParams`]
     * JavaScript class.
     */
    // solhint-disable-next-line func-name-mixedcase
    function COUNTING_MODE() public pure virtual returns (string memory);

    /**
     * @notice module:core
     * @dev Hashing function used to (re)build the proposal id from the proposal details..
     */
    function hashProposal(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata calldatas,
        bytes32 descriptionHash
    ) public pure virtual returns (uint256);

    /**
     * @notice module:core
     * @dev Current state of a proposal, following Compound's convention
     */
    function state(uint256 proposalId) public view virtual returns (ProposalState);

    /**
     * @notice module:core
     * @dev Block number used to retrieve user's votes and quorum. As per Compound's Comp and OpenZeppelin's
     * ERC20Votes, the snapshot is performed at the end of this block. Hence, voting for this proposal starts at the
     * beginning of the following block.
     */
    function proposalSnapshot(uint256 proposalId) public view virtual returns (uint256);

    /**
     * @notice module:core
     * @dev Block number at which votes close. Votes close at the end of this block, so it is possible to cast a vote
     * during this block.
     */
    function proposalDeadline(uint256 proposalId) public view virtual returns (uint256);

    /**
     * @notice module:user-config
     * @dev Delay, in number of block, between the proposal is created and the vote starts. This can be increassed to
     * leave time for users to buy voting power, of delegate it, before the voting of a proposal starts.
     */
    function votingDelay() public view virtual returns (uint256);

    /**
     * @notice module:user-config
     * @dev Delay, in number of blocks, between the vote start and vote ends.
     *
     * NOTE: The {votingDelay} can delay the start of the vote. This must be considered when setting the voting
     * duration compared to the voting delay.
     */
    function votingPeriod() public view virtual returns (uint256);

    /**
     * @notice module:user-config
     * @dev Minimum number of cast voted required for a proposal to be successful.
     *
     * Note: The `blockNumber` parameter corresponds to the snaphot used for counting vote. This allows to scale the
     * quroum depending on values such as the totalSupply of a token at this block (see {ERC20Votes}).
     */
    function quorum(uint256 blockNumber) public view virtual returns (uint256);

    /**
     * @notice module:reputation
     * @dev Voting power of an `account` at a specific `blockNumber`.
     *
     * Note: this can be implemented in a number of ways, for example by reading the delegated balance from one (or
     * multiple), {ERC20Votes} tokens.
     */
    function getVotes(address account, uint256 blockNumber) public view virtual returns (uint256);

    /**
     * @notice module:voting
     * @dev Returns weither `account` has cast a vote on `proposalId`.
     */
    function hasVoted(uint256 proposalId, address account) public view virtual returns (bool);

    /**
     * @dev Create a new proposal. Vote start {IGovernor-votingDelay} blocks after the proposal is created and ends
     * {IGovernor-votingPeriod} blocks after the voting starts.
     *
     * Emits a {ProposalCreated} event.
     */
    function propose(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) public virtual returns (uint256 proposalId);

    /**
     * @dev Execute a successful proposal. This requires the quorum to be reached, the vote to be successful, and the
     * deadline to be reached.
     *
     * Emits a {ProposalExecuted} event.
     *
     * Note: some module can modify the requirements for execution, for example by adding an additional timelock.
     */
    function execute(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) public payable virtual returns (uint256 proposalId);

    /**
     * @dev Cast a vote
     *
     * Emits a {VoteCast} event.
     */
    function castVote(uint256 proposalId, uint8 support) public virtual returns (uint256 balance);

    /**
     * @dev Cast a vote with a reason
     *
     * Emits a {VoteCast} event.
     */
    function castVoteWithReason(
        uint256 proposalId,
        uint8 support,
        string calldata reason
    ) public virtual returns (uint256 balance);

    /**
     * @dev Cast a vote using the user cryptographic signature.
     *
     * Emits a {VoteCast} event.
     */
    function castVoteBySig(
        uint256 proposalId,
        uint8 support,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual returns (uint256 balance);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.7.6;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {IERC1271} from '../interfaces/IERC1271.sol';

import {IBabController} from './IBabController.sol';

/**
 * @title IEmergencyGarden
 */
interface IEmergencyGarden {
    /* ============ Write ============ */

    function wrap() external;
}

/**
 * @title IStrategyGarden
 */
interface IStrategyGarden {
    /* ============ Write ============ */

    function finalizeStrategy(
        uint256 _profits,
        int256 _returns,
        uint256 _burningAmount
    ) external;

    function allocateCapitalToStrategy(uint256 _capital) external;

    function expireCandidateStrategy() external;

    function addStrategy(
        string memory _name,
        string memory _symbol,
        uint256[] calldata _stratParams,
        uint8[] calldata _opTypes,
        address[] calldata _opIntegrations,
        bytes calldata _opEncodedDatas
    ) external;

    function payKeeper(address payable _keeper, uint256 _fee) external;

    function updateStrategyRewards(
        address _strategy,
        uint256 _newTotalBABLAmount,
        uint256 _newCapitalReturned,
        uint256 _diffRewardsToSetAside,
        bool _addOrSubstractSetAside
    ) external;
}

/**
 * @title IAdminGarden
 */
interface IAdminGarden {
    /* ============ Write ============ */
    function initialize(
        address _reserveAsset,
        IBabController _controller,
        address _creator,
        string memory _name,
        string memory _symbol,
        uint256[] calldata _gardenParams,
        uint256 _initialContribution,
        bool[] memory _publicGardenStrategistsStewards
    ) external payable;

    function makeGardenPublic() external;

    function transferCreatorRights(address _newCreator, uint8 _index) external;

    function addExtraCreators(address[4] memory _newCreators) external;

    function setPublicRights(bool _publicStrategist, bool _publicStewards) external;

    function delegateVotes(address _token, address _address) external;

    function updateCreators(address _newCreator, address[4] memory _newCreators) external;

    function updateGardenParams(uint256[13] memory _newParams) external;

    function verifyGarden(uint256 _verifiedCategory) external;

    function resetHardlock(uint256 _hardlockStartsAt) external;
}

/**
 * @title IGarden
 */
interface ICoreGarden {
    /* ============ Constructor ============ */

    /* ============ View ============ */

    function privateGarden() external view returns (bool);

    function publicStrategists() external view returns (bool);

    function publicStewards() external view returns (bool);

    function controller() external view returns (IBabController);

    function creator() external view returns (address);

    function isGardenStrategy(address _strategy) external view returns (bool);

    function getContributor(address _contributor)
        external
        view
        returns (
            uint256 lastDepositAt,
            uint256 initialDepositAt,
            uint256 claimedAt,
            uint256 claimedBABL,
            uint256 claimedRewards,
            uint256 withdrawnSince,
            uint256 totalDeposits,
            uint256 nonce,
            uint256 lockedBalance
        );

    function reserveAsset() external view returns (address);

    function verifiedCategory() external view returns (uint256);

    function canMintNftAfter() external view returns (uint256);

    function customIntegrationsEnabled() external view returns (bool);

    function hardlockStartsAt() external view returns (uint256);

    function totalContributors() external view returns (uint256);

    function gardenInitializedAt() external view returns (uint256);

    function minContribution() external view returns (uint256);

    function depositHardlock() external view returns (uint256);

    function minLiquidityAsset() external view returns (uint256);

    function minStrategyDuration() external view returns (uint256);

    function maxStrategyDuration() external view returns (uint256);

    function reserveAssetRewardsSetAside() external view returns (uint256);

    function absoluteReturns() external view returns (int256);

    function totalStake() external view returns (uint256);

    function minVotesQuorum() external view returns (uint256);

    function minVoters() external view returns (uint256);

    function maxDepositLimit() external view returns (uint256);

    function strategyCooldownPeriod() external view returns (uint256);

    function getStrategies() external view returns (address[] memory);

    function extraCreators(uint256 index) external view returns (address);

    function getFinalizedStrategies() external view returns (address[] memory);

    function getVotingPower(address _contributor) external view returns (uint256);

    function strategyMapping(address _strategy) external view returns (bool);

    function keeperDebt() external view returns (uint256);

    function totalKeeperFees() external view returns (uint256);

    function lastPricePerShare() external view returns (uint256);

    function lastPricePerShareTS() external view returns (uint256);

    function pricePerShareDecayRate() external view returns (uint256);

    function pricePerShareDelta() external view returns (uint256);

    function userLock(address _contributor) external view returns (uint256);

    /* ============ Write ============ */

    function deposit(
        uint256 _amountIn,
        uint256 _minAmountOut,
        address _to,
        address _referrer
    ) external payable;

    function depositBySig(
        uint256 _amountIn,
        uint256 _minAmountOut,
        uint256 _nonce,
        uint256 _maxFee,
        address _to,
        uint256 _pricePerShare,
        uint256 _fee,
        address _signer,
        address _referrer,
        bytes memory signature
    ) external;

    function withdraw(
        uint256 _amountIn,
        uint256 _minAmountOut,
        address payable _to,
        bool _withPenalty,
        address _unwindStrategy
    ) external;

    function withdrawBySig(
        uint256 _amountIn,
        uint256 _minAmountOut,
        uint256 _nonce,
        uint256 _maxFee,
        bool _withPenalty,
        address _unwindStrategy,
        uint256 _pricePerShare,
        uint256 _strategyNAV,
        uint256 _fee,
        address _signer,
        bytes memory signature
    ) external;

    function claimReturns(address[] calldata _finalizedStrategies) external;

    function claimAndStakeReturns(uint256 _minAmountOut, address[] calldata _finalizedStrategies) external;

    function claimRewardsBySig(
        uint256 _babl,
        uint256 _profits,
        uint256 _nonce,
        uint256 _maxFee,
        uint256 _fee,
        address signer,
        bytes memory signature
    ) external;

    function claimAndStakeRewardsBySig(
        uint256 _babl,
        uint256 _profits,
        uint256 _minAmountOut,
        uint256 _nonce,
        uint256 _nonceHeart,
        uint256 _maxFee,
        uint256 _pricePerShare,
        uint256 _fee,
        address _signer,
        bytes memory _signature
    ) external;

    function stakeBySig(
        uint256 _amountIn,
        uint256 _profits,
        uint256 _minAmountOut,
        uint256 _nonce,
        uint256 _nonceHeart,
        uint256 _maxFee,
        address _to,
        uint256 _pricePerShare,
        address _signer,
        bytes memory _signature
    ) external;

    function claimNFT() external;

    function updateUserLock(
        address _contributor,
        uint256 _userLock,
        uint256 _balanceBefore
    ) external;
}

interface IERC20Metadata {
    function name() external view returns (string memory);
}

interface IGarden is ICoreGarden, IAdminGarden, IStrategyGarden, IEmergencyGarden, IERC20, IERC20Metadata, IERC1271 {
    struct Contributor {
        uint256 lastDepositAt;
        uint256 initialDepositAt;
        uint256 claimedAt;
        uint256 claimedBABL;
        uint256 claimedRewards;
        uint256 withdrawnSince;
        uint256 totalDeposits;
        uint256 nonce;
        uint256 lockedBalance;
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.7.6;
import {IGarden} from './IGarden.sol';

/**
 * @title IHeart
 * @author Babylon Finance
 *
 * Interface for interacting with the Heart
 */
interface IHeart {
    // View functions

    function getVotedGardens() external view returns (address[] memory);

    function heartGarden() external view returns (IGarden);

    function getGardenWeights() external view returns (uint256[] memory);

    function minAmounts(address _reserve) external view returns (uint256);

    function assetToCToken(address _asset) external view returns (address);

    function bondAssets(address _asset) external view returns (uint256);

    function assetToLend() external view returns (address);

    function assetForPurchases() external view returns (address);

    function lastPumpAt() external view returns (uint256);

    function lastVotesAt() external view returns (uint256);

    function tradeSlippage() external view returns (uint256);

    function weeklyRewardAmount() external view returns (uint256);

    function bablRewardLeft() external view returns (uint256);

    function getFeeDistributionWeights() external view returns (uint256[] memory);

    function getTotalStats() external view returns (uint256[] memory);

    function votedGardens(uint256 _index) external view returns (address);

    function gardenWeights(uint256 _index) external view returns (uint256);

    function feeDistributionWeights(uint256 _index) external view returns (uint256);

    function totalStats(uint256 _index) external view returns (uint256);

    // Non-view

    function pump(uint256 _bablMinAmountOut) external;

    function voteProposal(uint256 _proposalId, bool _isApprove) external;

    function resolveGardenVotesAndPump(
        address[] memory _gardens,
        uint256[] memory _weights,
        uint256 _bablMinAmountOut
    ) external;

    function resolveGardenVotes(address[] memory _gardens, uint256[] memory _weights) external;

    function updateMarkets() external;

    function setHeartGardenAddress(address _heartGarden) external;

    function updateFeeWeights(uint256[] calldata _feeWeights) external;

    function updateAssetToLend(address _assetToLend) external;

    function updateAssetToPurchase(address _purchaseAsset) external;

    function updateBond(address _assetToBond, uint256 _bondDiscount) external;

    function lendFusePool(address _assetToLend, uint256 _lendAmount) external;

    function borrowFusePool(address _assetToBorrow, uint256 _borrowAmount) external;

    function repayFusePool(address _borrowedAsset, uint256 _amountToRepay) external;

    function protectBABL(
        uint256 _bablPriceProtectionAt,
        uint256 _bablPrice,
        uint256 _pricePurchasingAsset,
        uint256 _slippage,
        address _hopToken
    ) external;

    function trade(
        address _fromAsset,
        address _toAsset,
        uint256 _fromAmount,
        uint256 _minAmount
    ) external;

    function sellWantedAssetToHeart(address _assetToSell, uint256 _amountToSell) external;

    function addReward(uint256 _bablAmount, uint256 _weeklyRate) external;

    function setHeartConfigParam(
        uint8 _index,
        uint256 _param,
        address _addressParam
    ) external;

    function bondAsset(
        address _assetToBond,
        uint256 _amountToBond,
        uint256 _minAmountOut,
        address _referrer,
        uint256 _userLock
    ) external;

    function bondAssetBySig(
        address _assetToBond,
        uint256 _amountToBond,
        uint256 _amountIn,
        uint256 _minAmountOut,
        uint256 _nonce,
        uint256 _maxFee,
        uint256 _priceInBABL,
        uint256 _pricePerShare,
        uint256[2] calldata _feeAndLock,
        address _contributor,
        address _referrer,
        bytes memory _signature
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 wad) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface ICToken is IERC20 {
    function mint(uint256 mintAmount) external returns (uint256);

    function redeem(uint256 redeemTokens) external returns (uint256);

    function accrueInterest() external returns (uint256);

    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

    function borrow(uint256 borrowAmount) external returns (uint256);

    function repayBorrow(uint256 repayAmount) external returns (uint256);

    function exchangeRateStored() external view returns (uint256);

    function getCash() external view returns (uint256);

    function borrowRatePerBlock() external view returns (uint256);

    function totalBorrows() external view returns (uint256);

    function underlying() external view returns (address);

    function getAccountSnapshot(address account)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );

    function repayBorrowBehalf(address borrower, uint256 amount) external payable returns (uint256);

    function borrowBalanceCurrent(address account) external view returns (uint256);

    function supplyRatePerBlock() external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

interface ICEther {
    function mint() external payable;

    function borrow(uint256 borrowAmount) external returns (uint256);

    function redeem(uint256 redeemTokens) external returns (uint256);

    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

    function repayBorrow() external payable;

    function getCash() external view returns (uint256);

    function repayBorrowBehalf(address borrower) external payable;

    function borrowBalanceCurrent(address account) external returns (uint256);

    function borrowBalanceStored(address account) external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function getAccountSnapshot(address account)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );

    function exchangeRateCurrent() external returns (uint256);

    function supplyRatePerBlock() external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

interface IComptroller {
    /**
     * @notice Marker function used for light validation when updating the comptroller of a market
     * @dev Implementations should simply return true.
     * @return true
     */
    function isComptroller() external view returns (bool);

    function markets(address _cToken) external view returns (bool, uint256);

    function getRewardsDistributors() external view returns (address[] memory);

    /*** Assets You Are In ***/

    function enterMarkets(address[] calldata cTokens) external returns (uint256[] memory);

    function exitMarket(address cToken) external returns (uint256);

    function getAllMarkets() external view returns (address[] memory);

    function _borrowGuardianPaused() external view returns (bool);

    function borrowGuardianPaused(address _asset) external view returns (bool);

    function borrowCaps(address _asset) external view returns (uint256);

    function compAccrued(address holder) external view returns (uint256);

    /*** Policy Hooks ***/

    function getAccountLiquidity(address account)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    function getAssetsIn(address account) external view returns (address[] memory);

    function mintAllowed(
        address cToken,
        address minter,
        uint256 mintAmount
    ) external returns (uint256);

    function mintVerify(
        address cToken,
        address minter,
        uint256 mintAmount,
        uint256 mintTokens
    ) external;

    function redeemAllowed(
        address cToken,
        address redeemer,
        uint256 redeemTokens
    ) external returns (uint256);

    function redeemVerify(
        address cToken,
        address redeemer,
        uint256 redeemAmount,
        uint256 redeemTokens
    ) external;

    function borrowAllowed(
        address cToken,
        address borrower,
        uint256 borrowAmount
    ) external returns (uint256);

    function borrowVerify(
        address cToken,
        address borrower,
        uint256 borrowAmount
    ) external;

    function repayBorrowAllowed(
        address cToken,
        address payer,
        address borrower,
        uint256 repayAmount
    ) external returns (uint256);

    function repayBorrowVerify(
        address cToken,
        address payer,
        address borrower,
        uint256 repayAmount,
        uint256 borrowerIndex
    ) external;

    function liquidateBorrowAllowed(
        address cTokenBorrowed,
        address cTokenCollateral,
        address liquidator,
        address borrower,
        uint256 repayAmount
    ) external returns (uint256);

    function liquidateBorrowVerify(
        address cTokenBorrowed,
        address cTokenCollateral,
        address liquidator,
        address borrower,
        uint256 repayAmount,
        uint256 seizeTokens
    ) external;

    function seizeAllowed(
        address cTokenCollateral,
        address cTokenBorrowed,
        address liquidator,
        address borrower,
        uint256 seizeTokens
    ) external returns (uint256);

    function seizeVerify(
        address cTokenCollateral,
        address cTokenBorrowed,
        address liquidator,
        address borrower,
        uint256 seizeTokens
    ) external;

    function transferAllowed(
        address cToken,
        address src,
        address dst,
        uint256 transferTokens
    ) external returns (uint256);

    function transferVerify(
        address cToken,
        address src,
        address dst,
        uint256 transferTokens
    ) external;

    /*** Liquidity/Liquidation Calculations ***/

    function liquidateCalculateSeizeTokens(
        address cTokenBorrowed,
        address cTokenCollateral,
        uint256 repayAmount
    ) external view returns (uint256, uint256);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.7.6;

import {ITokenIdentifier} from './ITokenIdentifier.sol';
import {ICurveMetaRegistry} from './ICurveMetaRegistry.sol';
import {IConvexRegistry} from './IConvexRegistry.sol';
import {IPickleJarRegistry} from './IPickleJarRegistry.sol';

/**
 * @title IPriceOracle
 * @author Babylon Finance
 *
 * Interface for interacting with PriceOracle
 */
interface IPriceOracle {
    /* ============ Functions ============ */

    function getPrice(address _assetOne, address _assetTwo) external view returns (uint256);

    function getPriceNAV(address _assetOne, address _assetTwo) external view returns (uint256);

    function updateReserves(address[] memory list) external;

    function updateMaxTwapDeviation(int24 _maxTwapDeviation) external;

    function updateTokenIdentifier(ITokenIdentifier _tokenIdentifier) external;

    function updateCurveMetaRegistry(ICurveMetaRegistry _newCurveMetaRegistry) external;

    function updateConvexRegistry(IConvexRegistry _newConvexRegistry) external;

    function updatePickleRegistry(IPickleJarRegistry _newPickleRegistry) external;

    function getCompoundExchangeRate(address _asset, address _finalAsset) external view returns (uint256);

    function getCreamExchangeRate(address _asset, address _finalAsset) external view returns (uint256);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.7.6;

import {ITradeIntegration} from './ITradeIntegration.sol';

/**
 * @title IIshtarGate
 * @author Babylon Finance
 *
 * Interface for interacting with the Gate Guestlist NFT
 */
interface IMasterSwapper is ITradeIntegration {
    /* ============ Functions ============ */

    function isTradeIntegration(address _integration) external view returns (bool);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.7.6;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IVoteToken {
    function delegate(address delegatee) external;

    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s,
        bool prefix
    ) external;

    function getCurrentVotes(address account) external view returns (uint96);

    function getPriorVotes(address account, uint256 blockNumber) external view returns (uint96);

    function getMyDelegatee() external view returns (address);

    function getDelegatee(address account) external view returns (address);

    function getCheckpoints(address account, uint32 id) external view returns (uint32 fromBlock, uint96 votes);

    function getNumberOfCheckpoints(address account) external view returns (uint32);
}

interface IVoteTokenWithERC20 is IVoteToken, IERC20 {}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 */
interface IERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}

// SPDX-License-Identifier: Apache-2.0

/*
    Copyright 2020 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/

pragma solidity 0.7.6;

import {SignedSafeMath} from '@openzeppelin/contracts/math/SignedSafeMath.sol';

import {LowGasSafeMath} from './LowGasSafeMath.sol';

/**
 * @title PreciseUnitMath
 * @author Set Protocol
 *
 * Arithmetic for fixed-point numbers with 18 decimals of precision. Some functions taken from
 * dYdX's BaseMath library.
 *
 * CHANGELOG:
 * - 9/21/20: Added safePower function
 */
library PreciseUnitMath {
    using LowGasSafeMath for uint256;
    using SignedSafeMath for int256;

    // The number One in precise units.
    uint256 internal constant PRECISE_UNIT = 10**18;
    int256 internal constant PRECISE_UNIT_INT = 10**18;

    // Max unsigned integer value
    uint256 internal constant MAX_UINT_256 = type(uint256).max;
    // Max and min signed integer value
    int256 internal constant MAX_INT_256 = type(int256).max;
    int256 internal constant MIN_INT_256 = type(int256).min;

    /**
     * @dev Getter function since constants can't be read directly from libraries.
     */
    function decimals() internal pure returns (uint256) {
        return 18;
    }

    /**
     * @dev Getter function since constants can't be read directly from libraries.
     */
    function preciseUnit() internal pure returns (uint256) {
        return PRECISE_UNIT;
    }

    /**
     * @dev Getter function since constants can't be read directly from libraries.
     */
    function preciseUnitInt() internal pure returns (int256) {
        return PRECISE_UNIT_INT;
    }

    /**
     * @dev Getter function since constants can't be read directly from libraries.
     */
    function maxUint256() internal pure returns (uint256) {
        return MAX_UINT_256;
    }

    /**
     * @dev Getter function since constants can't be read directly from libraries.
     */
    function maxInt256() internal pure returns (int256) {
        return MAX_INT_256;
    }

    /**
     * @dev Getter function since constants can't be read directly from libraries.
     */
    function minInt256() internal pure returns (int256) {
        return MIN_INT_256;
    }

    /**
     * @dev Multiplies value a by value b (result is rounded down). It's assumed that the value b is the significand
     * of a number with 18 decimals precision.
     */
    function preciseMul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a.mul(b).div(PRECISE_UNIT);
    }

    /**
     * @dev Multiplies value a by value b (result is rounded towards zero). It's assumed that the value b is the
     * significand of a number with 18 decimals precision.
     */
    function preciseMul(int256 a, int256 b) internal pure returns (int256) {
        return a.mul(b).div(PRECISE_UNIT_INT);
    }

    /**
     * @dev Multiplies value a by value b (result is rounded up). It's assumed that the value b is the significand
     * of a number with 18 decimals precision.
     */
    function preciseMulCeil(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0 || b == 0) {
            return 0;
        }
        return a.mul(b).sub(1).div(PRECISE_UNIT).add(1);
    }

    /**
     * @dev Divides value a by value b (result is rounded down).
     */
    function preciseDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        return a.mul(PRECISE_UNIT).div(b);
    }

    /**
     * @dev Divides value a by value b (result is rounded towards 0).
     */
    function preciseDiv(int256 a, int256 b) internal pure returns (int256) {
        return a.mul(PRECISE_UNIT_INT).div(b);
    }

    /**
     * @dev Divides value a by value b (result is rounded up or away from 0).
     */
    function preciseDivCeil(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, 'Cant divide by 0');

        return a > 0 ? a.mul(PRECISE_UNIT).sub(1).div(b).add(1) : 0;
    }

    /**
     * @dev Divides value a by value b (result is rounded down - positive numbers toward 0 and negative away from 0).
     */
    function divDown(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, 'Cant divide by 0');
        require(a != MIN_INT_256 || b != -1, 'Invalid input');

        int256 result = a.div(b);
        if (a ^ b < 0 && a % b != 0) {
            result -= 1;
        }

        return result;
    }

    /**
     * @dev Multiplies value a by value b where rounding is towards the lesser number.
     * (positive values are rounded towards zero and negative values are rounded away from 0).
     */
    function conservativePreciseMul(int256 a, int256 b) internal pure returns (int256) {
        return divDown(a.mul(b), PRECISE_UNIT_INT);
    }

    /**
     * @dev Divides value a by value b where rounding is towards the lesser number.
     * (positive values are rounded towards zero and negative values are rounded away from 0).
     */
    function conservativePreciseDiv(int256 a, int256 b) internal pure returns (int256) {
        return divDown(a.mul(PRECISE_UNIT_INT), b);
    }

    /**
     * @dev Performs the power on a specified value, reverts on overflow.
     */
    function safePower(uint256 a, uint256 pow) internal pure returns (uint256) {
        require(a > 0, 'Value must be positive');

        uint256 result = 1;
        for (uint256 i = 0; i < pow; i++) {
            uint256 previousResult = result;

            // Using safemath multiplication prevents overflows
            result = previousResult.mul(a);
        }

        return result;
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.7.6;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import {LowGasSafeMath} from '../lib/LowGasSafeMath.sol';
import {UniversalERC20} from '../lib/UniversalERC20.sol';

library SafeDecimalMath {
    using LowGasSafeMath for uint256;
    using UniversalERC20 for IERC20;

    /* Number of decimal places in the representations. */
    uint8 internal constant decimals = 18;

    /* The number representing 1.0. */
    uint256 internal constant UNIT = 10**uint256(decimals);

    /**
     * @return Provides an interface to UNIT.
     */
    function unit() internal pure returns (uint256) {
        return UNIT;
    }

    /**
     * @return The result of multiplying x and y, interpreting the operands as fixed-point
     * decimals.
     *
     * @dev A unit factor is divided out after the product of x and y is evaluated,
     * so that product must be less than 2**256. As this is an integer division,
     * the internal division always rounds down. This helps save on gas. Rounding
     * is more expensive on gas.
     */
    function multiplyDecimal(uint256 x, uint256 y) internal pure returns (uint256) {
        /* Divide by UNIT to remove the extra factor introduced by the product. */
        return x.mul(y) / UNIT;
    }

    /**
     * @return The result of safely multiplying x and y, interpreting the operands
     * as fixed-point decimals of the specified precision unit.
     *
     * @dev The operands should be in the form of a the specified unit factor which will be
     * divided out after the product of x and y is evaluated, so that product must be
     * less than 2**256.
     *
     * Unlike multiplyDecimal, this function rounds the result to the nearest increment.
     * Rounding is useful when you need to retain fidelity for small decimal numbers
     * (eg. small fractions or percentages).
     */
    function _multiplyDecimalRound(
        uint256 x,
        uint256 y,
        uint256 precisionUnit
    ) private pure returns (uint256) {
        /* Divide by UNIT to remove the extra factor introduced by the product. */
        uint256 quotientTimesTen = x.mul(y) / (precisionUnit / 10);

        if (quotientTimesTen % 10 >= 5) {
            quotientTimesTen += 10;
        }

        return quotientTimesTen / 10;
    }

    /**
     * @return The result of safely multiplying x and y, interpreting the operands
     * as fixed-point decimals of a standard unit.
     *
     * @dev The operands should be in the standard unit factor which will be
     * divided out after the product of x and y is evaluated, so that product must be
     * less than 2**256.
     *
     * Unlike multiplyDecimal, this function rounds the result to the nearest increment.
     * Rounding is useful when you need to retain fidelity for small decimal numbers
     * (eg. small fractions or percentages).
     */
    function multiplyDecimalRound(uint256 x, uint256 y) internal pure returns (uint256) {
        return _multiplyDecimalRound(x, y, UNIT);
    }

    /**
     * @return The result of safely dividing x and y. The return value is a high
     * precision decimal.
     *
     * @dev y is divided after the product of x and the standard precision unit
     * is evaluated, so the product of x and UNIT must be less than 2**256. As
     * this is an integer division, the result is always rounded down.
     * This helps save on gas. Rounding is more expensive on gas.
     */
    function divideDecimal(uint256 x, uint256 y) internal pure returns (uint256) {
        /* Reintroduce the UNIT factor that will be divided out by y. */
        return x.mul(UNIT).div(y);
    }

    /**
     * @return The result of safely dividing x and y. The return value is as a rounded
     * decimal in the precision unit specified in the parameter.
     *
     * @dev y is divided after the product of x and the specified precision unit
     * is evaluated, so the product of x and the specified precision unit must
     * be less than 2**256. The result is rounded to the nearest increment.
     */
    function _divideDecimalRound(
        uint256 x,
        uint256 y,
        uint256 precisionUnit
    ) private pure returns (uint256) {
        uint256 resultTimesTen = x.mul(precisionUnit * 10).div(y);

        if (resultTimesTen % 10 >= 5) {
            resultTimesTen += 10;
        }

        return resultTimesTen / 10;
    }

    /**
     * @return The result of safely dividing x and y. The return value is as a rounded
     * standard precision decimal.
     *
     * @dev y is divided after the product of x and the standard precision unit
     * is evaluated, so the product of x and the standard precision unit must
     * be less than 2**256. The result is rounded to the nearest increment.
     */
    function divideDecimalRound(uint256 x, uint256 y) internal pure returns (uint256) {
        return _divideDecimalRound(x, y, UNIT);
    }

    /**
     * Normalizing amount decimals between tokens
     * @param _from       ERC20 asset address
     * @param _to     ERC20 asset address
     * @param _amount Value _to normalize (e.g. capital)
     */
    function normalizeAmountTokens(
        address _from,
        address _to,
        uint256 _amount
    ) internal view returns (uint256) {
        uint256 fromDecimals = IERC20(_from).universalDecimals();
        uint256 toDecimals = IERC20(_to).universalDecimals();

        if (fromDecimals == toDecimals) {
            return _amount;
        }
        if (toDecimals > fromDecimals) {
            return _amount.mul(10**(toDecimals - (fromDecimals)));
        }
        return _amount.div(10**(fromDecimals - (toDecimals)));
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity 0.7.6;

/// @title Optimized overflow and underflow safe math operations
/// @notice Contains methods for doing math operations that revert on overflow or underflow for minimal gas cost
library LowGasSafeMath {
    /// @notice Returns x + y, reverts if sum overflows uint256
    /// @param x The augend
    /// @param y The addend
    /// @return z The sum of x and y
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x);
    }

    /// @notice Returns x - y, reverts if underflows
    /// @param x The minuend
    /// @param y The subtrahend
    /// @return z The difference of x and y
    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x);
    }

    /// @notice Returns x * y, reverts if overflows
    /// @param x The multiplicand
    /// @param y The multiplier
    /// @return z The product of x and y
    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(x == 0 || (z = x * y) / x == y);
    }

    /// @notice Returns x + y, reverts if overflows or underflows
    /// @param x The augend
    /// @param y The addend
    /// @return z The sum of x and y
    function add(int256 x, int256 y) internal pure returns (int256 z) {
        require((z = x + y) >= x == (y >= 0));
    }

    /// @notice Returns x - y, reverts if overflows or underflows
    /// @param x The minuend
    /// @param y The subtrahend
    /// @return z The difference of x and y
    function sub(int256 x, int256 y) internal pure returns (int256 z) {
        require((z = x - y) <= x == (y >= 0));
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, 'SafeMath: division by zero');
        return a / b;
    }
}

// SPDX-License-Identifier: Apache-2.0

/*
    Original version by Synthetix.io
    https://docs.synthetix.io/contracts/source/libraries/safedecimalmath

    Adapted by Babylon Finance.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/

pragma solidity 0.7.6;

// solhint-disable

/**
 * @notice Forked from https://github.com/balancer-labs/balancer-core-v2/blob/master/contracts/lib/helpers/BalancerErrors.sol
 * @dev Reverts if `condition` is false, with a revert reason containing `errorCode`. Only codes up to 999 are
 * supported.
 */
function _require(bool condition, uint256 errorCode) pure {
    if (!condition) _revert(errorCode);
}

/**
 * @dev Reverts with a revert reason containing `errorCode`. Only codes up to 999 are supported.
 */
function _revert(uint256 errorCode) pure {
    // We're going to dynamically create a revert string based on the error code, with the following format:
    // 'BAB#{errorCode}'
    // where the code is left-padded with zeroes to three digits (so they range from 000 to 999).
    //
    // We don't have revert strings embedded in the contract to save bytecode size: it takes much less space to store a
    // number (8 to 16 bits) than the individual string characters.
    //
    // The dynamic string creation algorithm that follows could be implemented in Solidity, but assembly allows for a
    // much denser implementation, again saving bytecode size. Given this function unconditionally reverts, this is a
    // safe place to rely on it without worrying about how its usage might affect e.g. memory contents.
    assembly {
        // First, we need to compute the ASCII representation of the error code. We assume that it is in the 0-999
        // range, so we only need to convert three digits. To convert the digits to ASCII, we add 0x30, the value for
        // the '0' character.

        let units := add(mod(errorCode, 10), 0x30)

        errorCode := div(errorCode, 10)
        let tenths := add(mod(errorCode, 10), 0x30)

        errorCode := div(errorCode, 10)
        let hundreds := add(mod(errorCode, 10), 0x30)

        // With the individual characters, we can now construct the full string. The "BAB#" part is a known constant
        // (0x42414223): we simply shift this by 24 (to provide space for the 3 bytes of the error code), and add the
        // characters to it, each shifted by a multiple of 8.
        // The revert reason is then shifted left by 200 bits (256 minus the length of the string, 7 characters * 8 bits
        // per character = 56) to locate it in the most significant part of the 256 slot (the beginning of a byte
        // array).

        let revertReason := shl(200, add(0x42414223000000, add(add(units, shl(8, tenths)), shl(16, hundreds))))

        // We can now encode the reason in memory, which can be safely overwritten as we're about to revert. The encoded
        // message will have the following layout:
        // [ revert reason identifier ] [ string location offset ] [ string length ] [ string contents ]

        // The Solidity revert reason identifier is 0x08c739a0, the function selector of the Error(string) function. We
        // also write zeroes to the next 28 bytes of memory, but those are about to be overwritten.
        mstore(0x0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
        // Next is the offset to the location of the string, which will be placed immediately after (20 bytes away).
        mstore(0x04, 0x0000000000000000000000000000000000000000000000000000000000000020)
        // The string length is fixed: 7 characters.
        mstore(0x24, 7)
        // Finally, the string itself is stored.
        mstore(0x44, revertReason)

        // Even if the string is only 7 bytes long, we need to return a full 32 byte slot containing it. The length of
        // the encoded message is therefore 4 + 32 + 32 + 32 = 100.
        revert(0, 100)
    }
}

library Errors {
    // Max deposit limit needs to be under the limit
    uint256 internal constant MAX_DEPOSIT_LIMIT = 0;
    // Creator needs to deposit
    uint256 internal constant MIN_CONTRIBUTION = 1;
    // Min Garden token supply >= 0
    uint256 internal constant MIN_TOKEN_SUPPLY = 2;
    // Deposit hardlock needs to be at least 1 block
    uint256 internal constant DEPOSIT_HARDLOCK = 3;
    // Needs to be at least the minimum
    uint256 internal constant MIN_LIQUIDITY = 4;
    // _reserveAssetQuantity is not equal to msg.value
    uint256 internal constant MSG_VALUE_DO_NOT_MATCH = 5;
    // Withdrawal amount has to be equal or less than msg.sender balance
    uint256 internal constant MSG_SENDER_TOKENS_DO_NOT_MATCH = 6;
    // Tokens are staked
    uint256 internal constant TOKENS_STAKED = 7;
    // Balance too low
    uint256 internal constant BALANCE_TOO_LOW = 8;
    // msg.sender doesn't have enough tokens
    uint256 internal constant MSG_SENDER_TOKENS_TOO_LOW = 9;
    //  There is an open redemption window already
    uint256 internal constant REDEMPTION_OPENED_ALREADY = 10;
    // Cannot request twice in the same window
    uint256 internal constant ALREADY_REQUESTED = 11;
    // Rewards and profits already claimed
    uint256 internal constant ALREADY_CLAIMED = 12;
    // Value have to be greater than zero
    uint256 internal constant GREATER_THAN_ZERO = 13;
    // Must be reserve asset
    uint256 internal constant MUST_BE_RESERVE_ASSET = 14;
    // Only contributors allowed
    uint256 internal constant ONLY_CONTRIBUTOR = 15;
    // Only controller allowed
    uint256 internal constant ONLY_CONTROLLER = 16;
    // Only creator allowed
    uint256 internal constant ONLY_CREATOR = 17;
    // Only keeper allowed
    uint256 internal constant ONLY_KEEPER = 18;
    // Fee is too high
    uint256 internal constant FEE_TOO_HIGH = 19;
    // Only strategy allowed
    uint256 internal constant ONLY_STRATEGY = 20;
    // Only active allowed
    uint256 internal constant ONLY_ACTIVE = 21;
    // Only inactive allowed
    uint256 internal constant ONLY_INACTIVE = 22;
    // Address should be not zero address
    uint256 internal constant ADDRESS_IS_ZERO = 23;
    // Not within range
    uint256 internal constant NOT_IN_RANGE = 24;
    // Value is too low
    uint256 internal constant VALUE_TOO_LOW = 25;
    // Value is too high
    uint256 internal constant VALUE_TOO_HIGH = 26;
    // Only strategy or protocol allowed
    uint256 internal constant ONLY_STRATEGY_OR_CONTROLLER = 27;
    // Normal withdraw possible
    uint256 internal constant NORMAL_WITHDRAWAL_POSSIBLE = 28;
    // User does not have permissions to join garden
    uint256 internal constant USER_CANNOT_JOIN = 29;
    // User does not have permissions to add strategies in garden
    uint256 internal constant USER_CANNOT_ADD_STRATEGIES = 30;
    // Only Protocol or garden
    uint256 internal constant ONLY_PROTOCOL_OR_GARDEN = 31;
    // Only Strategist
    uint256 internal constant ONLY_STRATEGIST = 32;
    // Only Integration
    uint256 internal constant ONLY_INTEGRATION = 33;
    // Only garden and data not set
    uint256 internal constant ONLY_GARDEN_AND_DATA_NOT_SET = 34;
    // Only active garden
    uint256 internal constant ONLY_ACTIVE_GARDEN = 35;
    // Contract is not a garden
    uint256 internal constant NOT_A_GARDEN = 36;
    // Not enough tokens
    uint256 internal constant STRATEGIST_TOKENS_TOO_LOW = 37;
    // Stake is too low
    uint256 internal constant STAKE_HAS_TO_AT_LEAST_ONE = 38;
    // Duration must be in range
    uint256 internal constant DURATION_MUST_BE_IN_RANGE = 39;
    // Duplicated strategies
    uint256 internal constant DUPLICATED_STRATEGIES = 40;
    // Max Capital Requested
    uint256 internal constant MAX_CAPITAL_REQUESTED = 41;
    // Votes are already resolved
    uint256 internal constant VOTES_ALREADY_RESOLVED = 42;
    // Voting window is closed
    uint256 internal constant VOTING_WINDOW_IS_OVER = 43;
    // Strategy needs to be active
    uint256 internal constant STRATEGY_NEEDS_TO_BE_ACTIVE = 44;
    // Max capital reached
    uint256 internal constant MAX_CAPITAL_REACHED = 45;
    // Capital is less then rebalance
    uint256 internal constant CAPITAL_IS_LESS_THAN_REBALANCE = 46;
    // Strategy is in cooldown period
    uint256 internal constant STRATEGY_IN_COOLDOWN = 47;
    // Strategy is not executed
    uint256 internal constant STRATEGY_IS_NOT_EXECUTED = 48;
    // Strategy is not over yet
    uint256 internal constant STRATEGY_IS_NOT_OVER_YET = 49;
    // Strategy is already finalized
    uint256 internal constant STRATEGY_IS_ALREADY_FINALIZED = 50;
    // No capital to unwind
    uint256 internal constant STRATEGY_NO_CAPITAL_TO_UNWIND = 51;
    // Strategy needs to be inactive
    uint256 internal constant STRATEGY_NEEDS_TO_BE_INACTIVE = 52;
    // Duration needs to be less
    uint256 internal constant DURATION_NEEDS_TO_BE_LESS = 53;
    // Can't sweep reserve asset
    uint256 internal constant CANNOT_SWEEP_RESERVE_ASSET = 54;
    // Voting window is opened
    uint256 internal constant VOTING_WINDOW_IS_OPENED = 55;
    // Strategy is executed
    uint256 internal constant STRATEGY_IS_EXECUTED = 56;
    // Min Rebalance Capital
    uint256 internal constant MIN_REBALANCE_CAPITAL = 57;
    // Not a valid strategy NFT
    uint256 internal constant NOT_STRATEGY_NFT = 58;
    // Garden Transfers Disabled
    uint256 internal constant GARDEN_TRANSFERS_DISABLED = 59;
    // Tokens are hardlocked
    uint256 internal constant TOKENS_HARDLOCKED = 60;
    // Max contributors reached
    uint256 internal constant MAX_CONTRIBUTORS = 61;
    // BABL Transfers Disabled
    uint256 internal constant BABL_TRANSFERS_DISABLED = 62;
    // Strategy duration range error
    uint256 internal constant DURATION_RANGE = 63;
    // Checks the min amount of voters
    uint256 internal constant MIN_VOTERS_CHECK = 64;
    // Ge contributor power error
    uint256 internal constant CONTRIBUTOR_POWER_CHECK_WINDOW = 65;
    // Not enough reserve set aside
    uint256 internal constant NOT_ENOUGH_RESERVE = 66;
    // Garden is already public
    uint256 internal constant GARDEN_ALREADY_PUBLIC = 67;
    // Withdrawal with penalty
    uint256 internal constant WITHDRAWAL_WITH_PENALTY = 68;
    // Withdrawal with penalty
    uint256 internal constant ONLY_MINING_ACTIVE = 69;
    // Overflow in supply
    uint256 internal constant OVERFLOW_IN_SUPPLY = 70;
    // Overflow in power
    uint256 internal constant OVERFLOW_IN_POWER = 71;
    // Not a system contract
    uint256 internal constant NOT_A_SYSTEM_CONTRACT = 72;
    // Strategy vs Garden mismatch
    uint256 internal constant STRATEGY_GARDEN_MISMATCH = 73;
    // Minimum quarters is 1
    uint256 internal constant QUARTERS_MIN_1 = 74;
    // Too many strategy operations
    uint256 internal constant TOO_MANY_OPS = 75;
    // Only operations
    uint256 internal constant ONLY_OPERATION = 76;
    // Strat params wrong length
    uint256 internal constant STRAT_PARAMS_LENGTH = 77;
    // Garden params wrong length
    uint256 internal constant GARDEN_PARAMS_LENGTH = 78;
    // Token names too long
    uint256 internal constant NAME_TOO_LONG = 79;
    // Contributor power overflows over garden power
    uint256 internal constant CONTRIBUTOR_POWER_OVERFLOW = 80;
    // Contributor power window out of bounds
    uint256 internal constant CONTRIBUTOR_POWER_CHECK_DEPOSITS = 81;
    // Contributor power window out of bounds
    uint256 internal constant NO_REWARDS_TO_CLAIM = 82;
    // Pause guardian paused this operation
    uint256 internal constant ONLY_UNPAUSED = 83;
    // Reentrant intent
    uint256 internal constant REENTRANT_CALL = 84;
    // Reserve asset not supported
    uint256 internal constant RESERVE_ASSET_NOT_SUPPORTED = 85;
    // Withdrawal/Deposit check min amount received
    uint256 internal constant RECEIVE_MIN_AMOUNT = 86;
    // Total Votes has to be positive
    uint256 internal constant TOTAL_VOTES_HAVE_TO_BE_POSITIVE = 87;
    // Signer has to be valid
    uint256 internal constant INVALID_SIGNER = 88;
    // Nonce has to be valid
    uint256 internal constant INVALID_NONCE = 89;
    // Garden is not public
    uint256 internal constant GARDEN_IS_NOT_PUBLIC = 90;
    // Setting max contributors
    uint256 internal constant MAX_CONTRIBUTORS_SET = 91;
    // Profit sharing mismatch for customized gardens
    uint256 internal constant PROFIT_SHARING_MISMATCH = 92;
    // Max allocation percentage
    uint256 internal constant MAX_STRATEGY_ALLOCATION_PERCENTAGE = 93;
    // new creator must not exist
    uint256 internal constant NEW_CREATOR_MUST_NOT_EXIST = 94;
    // only first creator can add
    uint256 internal constant ONLY_FIRST_CREATOR_CAN_ADD = 95;
    // invalid address
    uint256 internal constant INVALID_ADDRESS = 96;
    // creator can only renounce in some circumstances
    uint256 internal constant CREATOR_CANNOT_RENOUNCE = 97;
    // no price for trade
    uint256 internal constant NO_PRICE_FOR_TRADE = 98;
    // Max capital requested
    uint256 internal constant ZERO_CAPITAL_REQUESTED = 99;
    // Unwind capital above the limit
    uint256 internal constant INVALID_CAPITAL_TO_UNWIND = 100;
    // Mining % sharing does not match
    uint256 internal constant INVALID_MINING_VALUES = 101;
    // Max trade slippage percentage
    uint256 internal constant MAX_TRADE_SLIPPAGE_PERCENTAGE = 102;
    // Max gas fee percentage
    uint256 internal constant MAX_GAS_FEE_PERCENTAGE = 103;
    // Mismatch between voters and votes
    uint256 internal constant INVALID_VOTES_LENGTH = 104;
    // Only Rewards Distributor
    uint256 internal constant ONLY_RD = 105;
    // Fee is too LOW
    uint256 internal constant FEE_TOO_LOW = 106;
    // Only governance or emergency
    uint256 internal constant ONLY_GOVERNANCE_OR_EMERGENCY = 107;
    // Strategy invalid reserve asset amount
    uint256 internal constant INVALID_RESERVE_AMOUNT = 108;
    // Heart only pumps once a week
    uint256 internal constant HEART_ALREADY_PUMPED = 109;
    // Heart needs garden votes to pump
    uint256 internal constant HEART_VOTES_MISSING = 110;
    // Not enough fees for heart
    uint256 internal constant HEART_MINIMUM_FEES = 111;
    // Invalid heart votes length
    uint256 internal constant HEART_VOTES_LENGTH = 112;
    // Heart LP tokens not received
    uint256 internal constant HEART_LP_TOKENS = 113;
    // Heart invalid asset to lend
    uint256 internal constant HEART_ASSET_LEND_INVALID = 114;
    // Heart garden not set
    uint256 internal constant HEART_GARDEN_NOT_SET = 115;
    // Heart asset to lend is the same
    uint256 internal constant HEART_ASSET_LEND_SAME = 116;
    // Heart invalid ctoken
    uint256 internal constant HEART_INVALID_CTOKEN = 117;
    // Price per share is wrong
    uint256 internal constant PRICE_PER_SHARE_WRONG = 118;
    // Heart asset to purchase is same
    uint256 internal constant HEART_ASSET_PURCHASE_INVALID = 119;
    // Reset hardlock bigger than timestamp
    uint256 internal constant RESET_HARDLOCK_INVALID = 120;
    // Invalid referrer
    uint256 internal constant INVALID_REFERRER = 121;
    // Only Heart Garden
    uint256 internal constant ONLY_HEART_GARDEN = 122;
    // Max BABL Cap to claim by sig
    uint256 internal constant MAX_BABL_CAP_REACHED = 123;
    // Not enough BABL
    uint256 internal constant NOT_ENOUGH_BABL = 124;
    // Claim garden NFT
    uint256 internal constant CLAIM_GARDEN_NFT = 125;
    // Not enough collateral
    uint256 internal constant NOT_ENOUGH_COLLATERAL = 126;
    // Amount too low
    uint256 internal constant AMOUNT_TOO_LOW = 127;
    // Amount too high
    uint256 internal constant AMOUNT_TOO_HIGH = 128;
    // Not enough to repay debt
    uint256 internal constant SLIPPAGE_TOO_HIH = 129;
    // Invalid amount
    uint256 internal constant INVALID_AMOUNT = 130;
    // Not enough BABL
    uint256 internal constant NOT_ENOUGH_AMOUNT = 131;
    // Error minting
    uint256 internal constant MINT_ERROR = 132;
    // Error no unlock signal needed
    uint256 internal constant NO_SIGNAL_NEEDED = 133;
    // Error setting garden user lock
    uint256 internal constant SET_GARDEN_USER_LOCK = 134;
    // Error setting garden user lock
    uint256 internal constant RARI_HACK_STRAT = 135;
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.7.6;

import {IBabController} from '../interfaces/IBabController.sol';

library ControllerLib {
    /**
     * Throws if the sender is not the protocol
     */
    function onlyGovernanceOrEmergency(IBabController _controller) internal view {
        require(
            msg.sender == _controller.owner() || msg.sender == _controller.EMERGENCY_OWNER(),
            'Only governance or emergency can call this'
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that never changes
/// @notice These parameters are fixed for a pool forever, i.e., the methods will always return the same values
interface IUniswapV3PoolImmutables {
    /// @notice The contract that deployed the pool, which must adhere to the IUniswapV3Factory interface
    /// @return The contract address
    function factory() external view returns (address);

    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);

    /// @notice The pool's fee in hundredths of a bip, i.e. 1e-6
    /// @return The fee
    function fee() external view returns (uint24);

    /// @notice The pool tick spacing
    /// @dev Ticks can only be used at multiples of this value, minimum of 1 and always positive
    /// e.g.: a tickSpacing of 3 means ticks can be initialized every 3rd tick, i.e., ..., -6, -3, 0, 3, 6, ...
    /// This value is an int24 to avoid casting even though it is always positive.
    /// @return The tick spacing
    function tickSpacing() external view returns (int24);

    /// @notice The maximum amount of position liquidity that can use any tick in the range
    /// @dev This parameter is enforced per tick to prevent liquidity from overflowing a uint128 at any point, and
    /// also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool
    /// @return The max amount of liquidity per tick
    function maxLiquidityPerTick() external view returns (uint128);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that can change
/// @notice These methods compose the pool's state, and can change with any frequency including multiple times
/// per transaction
interface IUniswapV3PoolState {
    /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
    /// when accessed externally.
    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// observationIndex The index of the last oracle observation that was written,
    /// observationCardinality The current maximum number of observations stored in the pool,
    /// observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// feeProtocol The protocol fee for both tokens of the pool.
    /// Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0
    /// is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
    /// unlocked Whether the pool is currently locked to reentrancy
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );

    /// @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal0X128() external view returns (uint256);

    /// @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal1X128() external view returns (uint256);

    /// @notice The amounts of token0 and token1 that are owed to the protocol
    /// @dev Protocol fees will never exceed uint128 max in either token
    function protocolFees() external view returns (uint128 token0, uint128 token1);

    /// @notice The currently in range liquidity available to the pool
    /// @dev This value has no relationship to the total liquidity across all ticks
    function liquidity() external view returns (uint128);

    /// @notice Look up information about a specific tick in the pool
    /// @param tick The tick to look up
    /// @return liquidityGross the total amount of position liquidity that uses the pool either as tick lower or
    /// tick upper,
    /// liquidityNet how much liquidity changes when the pool price crosses the tick,
    /// feeGrowthOutside0X128 the fee growth on the other side of the tick from the current tick in token0,
    /// feeGrowthOutside1X128 the fee growth on the other side of the tick from the current tick in token1,
    /// tickCumulativeOutside the cumulative tick value on the other side of the tick from the current tick
    /// secondsPerLiquidityOutsideX128 the seconds spent per liquidity on the other side of the tick from the current tick,
    /// secondsOutside the seconds spent on the other side of the tick from the current tick,
    /// initialized Set to true if the tick is initialized, i.e. liquidityGross is greater than 0, otherwise equal to false.
    /// Outside values can only be used if the tick is initialized, i.e. if liquidityGross is greater than 0.
    /// In addition, these values are only relative and must be used only in comparison to previous snapshots for
    /// a specific position.
    function ticks(int24 tick)
        external
        view
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128,
            int56 tickCumulativeOutside,
            uint160 secondsPerLiquidityOutsideX128,
            uint32 secondsOutside,
            bool initialized
        );

    /// @notice Returns 256 packed tick initialized boolean values. See TickBitmap for more information
    function tickBitmap(int16 wordPosition) external view returns (uint256);

    /// @notice Returns the information about a position by the position's key
    /// @param key The position's key is a hash of a preimage composed by the owner, tickLower and tickUpper
    /// @return _liquidity The amount of liquidity in the position,
    /// Returns feeGrowthInside0LastX128 fee growth of token0 inside the tick range as of the last mint/burn/poke,
    /// Returns feeGrowthInside1LastX128 fee growth of token1 inside the tick range as of the last mint/burn/poke,
    /// Returns tokensOwed0 the computed amount of token0 owed to the position as of the last mint/burn/poke,
    /// Returns tokensOwed1 the computed amount of token1 owed to the position as of the last mint/burn/poke
    function positions(bytes32 key)
        external
        view
        returns (
            uint128 _liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    /// @notice Returns data about a specific observation index
    /// @param index The element of the observations array to fetch
    /// @dev You most likely want to use #observe() instead of this method to get an observation as of some amount of time
    /// ago, rather than at a specific index in the array.
    /// @return blockTimestamp The timestamp of the observation,
    /// Returns tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the observation timestamp,
    /// Returns secondsPerLiquidityCumulativeX128 the seconds per in range liquidity for the life of the pool as of the observation timestamp,
    /// Returns initialized whether the observation has been initialized and the values are safe to use
    function observations(uint256 index)
        external
        view
        returns (
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulativeX128,
            bool initialized
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that is not stored
/// @notice Contains view functions to provide information about the pool that is computed rather than stored on the
/// blockchain. The functions here may have variable gas costs.
interface IUniswapV3PoolDerivedState {
    /// @notice Returns the cumulative tick and liquidity as of each timestamp `secondsAgo` from the current block timestamp
    /// @dev To get a time weighted average tick or liquidity-in-range, you must call this with two values, one representing
    /// the beginning of the period and another for the end of the period. E.g., to get the last hour time-weighted average tick,
    /// you must call it with secondsAgos = [3600, 0].
    /// @dev The time weighted average tick represents the geometric time weighted average price of the pool, in
    /// log base sqrt(1.0001) of token1 / token0. The TickMath library can be used to go from a tick value to a ratio.
    /// @param secondsAgos From how long ago each cumulative tick and liquidity value should be returned
    /// @return tickCumulatives Cumulative tick values as of each `secondsAgos` from the current block timestamp
    /// @return secondsPerLiquidityCumulativeX128s Cumulative seconds per liquidity-in-range value as of each `secondsAgos` from the current block
    /// timestamp
    function observe(uint32[] calldata secondsAgos)
        external
        view
        returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s);

    /// @notice Returns a snapshot of the tick cumulative, seconds per liquidity and seconds inside a tick range
    /// @dev Snapshots must only be compared to other snapshots, taken over a period for which a position existed.
    /// I.e., snapshots cannot be compared if a position is not held for the entire period between when the first
    /// snapshot is taken and the second snapshot is taken.
    /// @param tickLower The lower tick of the range
    /// @param tickUpper The upper tick of the range
    /// @return tickCumulativeInside The snapshot of the tick accumulator for the range
    /// @return secondsPerLiquidityInsideX128 The snapshot of seconds per liquidity for the range
    /// @return secondsInside The snapshot of seconds per liquidity for the range
    function snapshotCumulativesInside(int24 tickLower, int24 tickUpper)
        external
        view
        returns (
            int56 tickCumulativeInside,
            uint160 secondsPerLiquidityInsideX128,
            uint32 secondsInside
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissionless pool actions
/// @notice Contains pool methods that can be called by anyone
interface IUniswapV3PoolActions {
    /// @notice Sets the initial price for the pool
    /// @dev Price is represented as a sqrt(amountToken1/amountToken0) Q64.96 value
    /// @param sqrtPriceX96 the initial sqrt price of the pool as a Q64.96
    function initialize(uint160 sqrtPriceX96) external;

    /// @notice Adds liquidity for the given recipient/tickLower/tickUpper position
    /// @dev The caller of this method receives a callback in the form of IUniswapV3MintCallback#uniswapV3MintCallback
    /// in which they must pay any token0 or token1 owed for the liquidity. The amount of token0/token1 due depends
    /// on tickLower, tickUpper, the amount of liquidity, and the current price.
    /// @param recipient The address for which the liquidity will be created
    /// @param tickLower The lower tick of the position in which to add liquidity
    /// @param tickUpper The upper tick of the position in which to add liquidity
    /// @param amount The amount of liquidity to mint
    /// @param data Any data that should be passed through to the callback
    /// @return amount0 The amount of token0 that was paid to mint the given amount of liquidity. Matches the value in the callback
    /// @return amount1 The amount of token1 that was paid to mint the given amount of liquidity. Matches the value in the callback
    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        bytes calldata data
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Collects tokens owed to a position
    /// @dev Does not recompute fees earned, which must be done either via mint or burn of any amount of liquidity.
    /// Collect must be called by the position owner. To withdraw only token0 or only token1, amount0Requested or
    /// amount1Requested may be set to zero. To withdraw all tokens owed, caller may pass any value greater than the
    /// actual tokens owed, e.g. type(uint128).max. Tokens owed may be from accumulated swap fees or burned liquidity.
    /// @param recipient The address which should receive the fees collected
    /// @param tickLower The lower tick of the position for which to collect fees
    /// @param tickUpper The upper tick of the position for which to collect fees
    /// @param amount0Requested How much token0 should be withdrawn from the fees owed
    /// @param amount1Requested How much token1 should be withdrawn from the fees owed
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);

    /// @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position
    /// @dev Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0
    /// @dev Fees must be collected separately via a call to #collect
    /// @param tickLower The lower tick of the position for which to burn liquidity
    /// @param tickUpper The upper tick of the position for which to burn liquidity
    /// @param amount How much liquidity to burn
    /// @return amount0 The amount of token0 sent to the recipient
    /// @return amount1 The amount of token1 sent to the recipient
    function burn(
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Swap token0 for token1, or token1 for token0
    /// @dev The caller of this method receives a callback in the form of IUniswapV3SwapCallback#uniswapV3SwapCallback
    /// @param recipient The address to receive the output of the swap
    /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
    /// @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
    /// @param sqrtPriceLimitX96 The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
    /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
    /// @param data Any data to be passed through to the callback
    /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
    /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    /// @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
    /// @dev The caller of this method receives a callback in the form of IUniswapV3FlashCallback#uniswapV3FlashCallback
    /// @dev Can be used to donate underlying tokens pro-rata to currently in-range liquidity providers by calling
    /// with 0 amount{0,1} and sending the donation amount(s) from the callback
    /// @param recipient The address which will receive the token0 and token1 amounts
    /// @param amount0 The amount of token0 to send
    /// @param amount1 The amount of token1 to send
    /// @param data Any data to be passed through to the callback
    function flash(
        address recipient,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;

    /// @notice Increase the maximum number of price and liquidity observations that this pool will store
    /// @dev This method is no-op if the pool already has an observationCardinalityNext greater than or equal to
    /// the input observationCardinalityNext.
    /// @param observationCardinalityNext The desired minimum number of observations for the pool to store
    function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissioned pool actions
/// @notice Contains pool methods that may only be called by the factory owner
interface IUniswapV3PoolOwnerActions {
    /// @notice Set the denominator of the protocol's % share of the fees
    /// @param feeProtocol0 new protocol fee for token0 of the pool
    /// @param feeProtocol1 new protocol fee for token1 of the pool
    function setFeeProtocol(uint8 feeProtocol0, uint8 feeProtocol1) external;

    /// @notice Collect the protocol fee accrued to the pool
    /// @param recipient The address to which collected protocol fees should be sent
    /// @param amount0Requested The maximum amount of token0 to send, can be 0 to collect fees in only token1
    /// @param amount1Requested The maximum amount of token1 to send, can be 0 to collect fees in only token0
    /// @return amount0 The protocol fee collected in token0
    /// @return amount1 The protocol fee collected in token1
    function collectProtocol(
        address recipient,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Events emitted by a pool
/// @notice Contains all events emitted by the pool
interface IUniswapV3PoolEvents {
    /// @notice Emitted exactly once by a pool when #initialize is first called on the pool
    /// @dev Mint/Burn/Swap cannot be emitted by the pool before Initialize
    /// @param sqrtPriceX96 The initial sqrt price of the pool, as a Q64.96
    /// @param tick The initial tick of the pool, i.e. log base 1.0001 of the starting price of the pool
    event Initialize(uint160 sqrtPriceX96, int24 tick);

    /// @notice Emitted when liquidity is minted for a given position
    /// @param sender The address that minted the liquidity
    /// @param owner The owner of the position and recipient of any minted liquidity
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity minted to the position range
    /// @param amount0 How much token0 was required for the minted liquidity
    /// @param amount1 How much token1 was required for the minted liquidity
    event Mint(
        address sender,
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted when fees are collected by the owner of a position
    /// @dev Collect events may be emitted with zero amount0 and amount1 when the caller chooses not to collect fees
    /// @param owner The owner of the position for which fees are collected
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount0 The amount of token0 fees collected
    /// @param amount1 The amount of token1 fees collected
    event Collect(
        address indexed owner,
        address recipient,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount0,
        uint128 amount1
    );

    /// @notice Emitted when a position's liquidity is removed
    /// @dev Does not withdraw any fees earned by the liquidity position, which must be withdrawn via #collect
    /// @param owner The owner of the position for which liquidity is removed
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity to remove
    /// @param amount0 The amount of token0 withdrawn
    /// @param amount1 The amount of token1 withdrawn
    event Burn(
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted by the pool for any swaps between token0 and token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the output of the swap
    /// @param amount0 The delta of the token0 balance of the pool
    /// @param amount1 The delta of the token1 balance of the pool
    /// @param sqrtPriceX96 The sqrt(price) of the pool after the swap, as a Q64.96
    /// @param liquidity The liquidity of the pool after the swap
    /// @param tick The log base 1.0001 of price of the pool after the swap
    event Swap(
        address indexed sender,
        address indexed recipient,
        int256 amount0,
        int256 amount1,
        uint160 sqrtPriceX96,
        uint128 liquidity,
        int24 tick
    );

    /// @notice Emitted by the pool for any flashes of token0/token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the tokens from flash
    /// @param amount0 The amount of token0 that was flashed
    /// @param amount1 The amount of token1 that was flashed
    /// @param paid0 The amount of token0 paid for the flash, which can exceed the amount0 plus the fee
    /// @param paid1 The amount of token1 paid for the flash, which can exceed the amount1 plus the fee
    event Flash(
        address indexed sender,
        address indexed recipient,
        uint256 amount0,
        uint256 amount1,
        uint256 paid0,
        uint256 paid1
    );

    /// @notice Emitted by the pool for increases to the number of observations that can be stored
    /// @dev observationCardinalityNext is not the observation cardinality until an observation is written at the index
    /// just before a mint/swap/burn.
    /// @param observationCardinalityNextOld The previous value of the next observation cardinality
    /// @param observationCardinalityNextNew The updated value of the next observation cardinality
    event IncreaseObservationCardinalityNext(
        uint16 observationCardinalityNextOld,
        uint16 observationCardinalityNextNew
    );

    /// @notice Emitted when the protocol fee is changed by the pool
    /// @param feeProtocol0Old The previous value of the token0 protocol fee
    /// @param feeProtocol1Old The previous value of the token1 protocol fee
    /// @param feeProtocol0New The updated value of the token0 protocol fee
    /// @param feeProtocol1New The updated value of the token1 protocol fee
    event SetFeeProtocol(uint8 feeProtocol0Old, uint8 feeProtocol1Old, uint8 feeProtocol0New, uint8 feeProtocol1New);

    /// @notice Emitted when the collected protocol fees are withdrawn by the factory owner
    /// @param sender The address that collects the protocol fees
    /// @param recipient The address that receives the collected protocol fees
    /// @param amount0 The amount of token0 protocol fees that is withdrawn
    /// @param amount0 The amount of token1 protocol fees that is withdrawn
    event CollectProtocol(address indexed sender, address indexed recipient, uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.7.6;

import {ICurveMetaRegistry} from './ICurveMetaRegistry.sol';
import {IPickleJarRegistry} from './IPickleJarRegistry.sol';
import {IConvexRegistry} from './IConvexRegistry.sol';
import {IYearnVaultRegistry} from './IYearnVaultRegistry.sol';

/**
 * @title IPriceOracle
 * @author Babylon Finance
 *
 * Interface for interacting with PriceOracle
 */
interface ITokenIdentifier {
    /* ============ View Functions ============ */

    function identifyTokens(address _tokenIn, address _tokenOut)
        external
        view
        returns (
            uint8,
            uint8,
            address,
            address
        );

    function convexPools(address _pool) external view returns (bool);

    function jars(address _jar) external view returns (uint8);

    function pickleGauges(address _gauge) external view returns (bool);

    function visors(address _visor) external view returns (bool);

    function vaults(address _vault) external view returns (bool);

    function aTokenToAsset(address _aToken) external view returns (address);

    function cTokenToAsset(address _cToken) external view returns (address);

    function jarRegistry() external view returns (IPickleJarRegistry);

    function vaultRegistry() external view returns (IYearnVaultRegistry);

    function curveMetaRegistry() external view returns (ICurveMetaRegistry);

    function convexRegistry() external view returns (IConvexRegistry);

    /* ============ Functions ============ */

    function updateVisor(address[] calldata _vaults, bool[] calldata _values) external;

    function updateCurveMetaRegistry(ICurveMetaRegistry _newCurveMetaRegistry) external;

    function updateConvexRegistry(IConvexRegistry _newConvexRegistry) external;

    function updatePickleRegistry(IPickleJarRegistry _newJarRegistry) external;

    function updateYearnVaultRegistry(IYearnVaultRegistry _newYearnVaultRegistry) external;

    function refreshAAveReserves() external;

    function refreshCompoundTokens() external;

    function updateYearnVaults() external;

    function updatePickleJars() external;

    function updateConvexPools() external;

    function updateYearnVault(address[] calldata _vaults, bool[] calldata _values) external;

    function updateAavePair(address[] calldata _aaveTokens, address[] calldata _underlyings) external;

    function updateCompoundPair(address[] calldata _cTokens, address[] calldata _underlyings) external;
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.7.6;

/**
 * @title ICurveMetaRegistry
 * @author Babylon Finance
 *
 * Interface for interacting with all the curve registries
 */
interface ICurveMetaRegistry {
    /* ============ Functions ============ */

    function updatePoolsList() external;

    function updateCryptoRegistries() external;

    /* ============ View Functions ============ */

    function isPool(address _poolAddress) external view returns (bool);

    function gaugeToPool(address _gaugeAddress) external view returns (address);

    function getGauge(address _pool) external view returns (address);

    function getCoinAddresses(address _pool, bool _getUnderlying) external view returns (address[8] memory);

    function getNCoins(address _pool) external view returns (uint256);

    function getLpToken(address _pool) external view returns (address);

    function getPoolFromLpToken(address _lpToken) external view returns (address);

    function getVirtualPriceFromLpToken(address _pool) external view returns (uint256);

    function isMeta(address _pool) external view returns (bool);

    function getUnderlyingAndRate(address _pool, uint256 _i) external view returns (address, uint256);

    function findBestPoolForCoins(address _fromToken, address _toToken) external view returns (address);

    function getCoinIndices(
        address _pool,
        address _fromToken,
        address _toToken
    )
        external
        view
        returns (
            uint256,
            uint256,
            bool
        );
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.7.6;

import {IBooster} from './external/convex/IBooster.sol';

/**
 * @title IConvexRegistry
 * @author Babylon Finance
 *
 * Interface for interacting with all the convex pools
 */
interface IConvexRegistry {
    /* ============ Functions ============ */

    function updateCache() external;

    /* ============ View Functions ============ */

    function getPid(address _asset) external view returns (bool, uint256);

    function convexPools(address _convexAddress) external view returns (bool);

    function booster() external view returns (IBooster);

    function getRewardPool(address _asset) external view returns (address reward);

    function getConvexInputToken(address _pool) external view returns (address inputToken);

    function getAllConvexPools() external view returns (address[] memory);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.7.6;

/**
 * @title IPickleJarRegistry
 * @author Babylon Finance
 *
 * Interface for interacting with all the pickle jars
 */
interface IPickleJarRegistry {
    /* ============ Functions ============ */

    function updateJars(
        address[] calldata _jars,
        bool[] calldata _values,
        bool[] calldata _uniflags
    ) external;

    /* ============ View Functions ============ */

    function jars(address _jarAddress) external view returns (bool);

    function noSwapParam(address _jarAddress) external view returns (bool);

    function isUniv3(address _jarAddress) external view returns (bool);

    function getJarStrategy(address _jarAddress) external view returns (address);

    function getJarGauge(address _jarAddress) external view returns (address);

    function getJarFromGauge(address _gauge) external view returns (address);

    function getAllJars() external view returns (address[] memory);

    function getAllGauges() external view returns (address[] memory);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.7.6;

/**
 * @title IYearnVaultRegistry
 * @author Babylon Finance
 *
 * Interface for interacting with all the pickle jars
 */
interface IYearnVaultRegistry {
    /* ============ Functions ============ */

    function updateVaults(address[] calldata _jars, bool[] calldata _values) external;

    /* ============ View Functions ============ */

    function vaults(address _vaultAddress) external view returns (bool);

    function getAllVaults() external view returns (address[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

interface IBooster {
    function depositAll(uint256 _pid, bool _stake) external returns (bool);

    function poolInfo(uint256)
        external
        view
        returns (
            address,
            address,
            address,
            address,
            address,
            bool
        );

    function deposit(
        uint256 _pid,
        uint256 _amount,
        bool _stake
    ) external returns (bool);

    function withdraw(uint256 _pid, uint256 _amount) external returns (bool);

    function withdrawAll(uint256 _pid) external returns (bool);

    function poolLength() external view returns (uint256);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.7.6;

import {IBaseIntegration} from '../interfaces/IBaseIntegration.sol';

/**
 * @title ITrade
 * @author Babylon Finance
 *
 * Interface for trading protocol integrations
 */
interface ITradeIntegration is IBaseIntegration {
    function trade(
        address _strategy,
        address _sendToken,
        uint256 _sendQuantity,
        address _receiveToken,
        uint256 _minReceiveQuantity
    ) external;

    function trade(
        address _strategy,
        address _sendToken,
        uint256 _sendQuantity,
        address _receiveToken,
        uint256 _minReceiveQuantity,
        address _hopToken
    ) external;
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.7.6;

interface IBaseIntegration {
    function name() external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @title SignedSafeMath
 * @dev Signed math operations with safety checks that revert on error.
 */
library SignedSafeMath {
    int256 constant private _INT256_MIN = -2**255;

    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == _INT256_MIN), "SignedSafeMath: multiplication overflow");

        int256 c = a * b;
        require(c / a == b, "SignedSafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "SignedSafeMath: division by zero");
        require(!(b == -1 && a == _INT256_MIN), "SignedSafeMath: division overflow");

        int256 c = a / b;

        return c;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

        return c;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

        return c;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {SafeMath} from '@openzeppelin/contracts/math/SafeMath.sol';

library UniversalERC20 {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 private constant ZERO_ADDRESS = IERC20(0x0000000000000000000000000000000000000000);
    IERC20 private constant ETH_ADDRESS = IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    function universalTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal returns (bool) {
        if (amount == 0) {
            return true;
        }

        if (isETH(token)) {
            address(uint160(to)).transfer(amount);
            return true;
        } else {
            token.safeTransfer(to, amount);
            return true;
        }
    }

    function universalTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        if (amount == 0) {
            return;
        }

        if (isETH(token)) {
            require(from == msg.sender && msg.value >= amount, 'msg.value is zero');
            if (to != address(this)) {
                address(uint160(to)).transfer(amount);
            }
            if (msg.value > amount) {
                msg.sender.transfer(msg.value.sub(amount));
            }
        } else {
            token.safeTransferFrom(from, to, amount);
        }
    }

    function universalApprove(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        if (!isETH(token)) {
            if (amount > 0 && token.allowance(address(this), to) > 0) {
                token.safeApprove(to, 0);
            }
            token.safeApprove(to, amount);
        }
    }

    function universalBalanceOf(IERC20 token, address who) internal view returns (uint256) {
        if (isETH(token)) {
            return who.balance;
        } else {
            return token.balanceOf(who);
        }
    }

    function universalDecimals(IERC20 token) internal view returns (uint256) {
        if (isETH(token)) {
            return 18;
        }

        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSignature('decimals()'));

        return success ? abi.decode(data, (uint256)) : 18;
    }

    function isETH(IERC20 token) internal pure returns (bool) {
        return address(token) == address(ZERO_ADDRESS) || address(token) == address(ETH_ADDRESS);
    }
}