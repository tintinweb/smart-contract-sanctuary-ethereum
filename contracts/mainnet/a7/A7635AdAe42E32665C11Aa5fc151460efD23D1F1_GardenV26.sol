// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.7.6;
import {Address} from '@openzeppelin/contracts/utils/Address.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {IERC721} from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import {ReentrancyGuard} from '@openzeppelin/contracts/utils/ReentrancyGuard.sol';
import {ECDSA} from '@openzeppelin/contracts/cryptography/ECDSA.sol';
import {ERC20Upgradeable} from '@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol';

import {LowGasSafeMath} from '../lib/LowGasSafeMath.sol';
import {SafeDecimalMath} from '../lib/SafeDecimalMath.sol';
import {SafeCast} from '@openzeppelin/contracts/utils/SafeCast.sol';
import {SignedSafeMath} from '@openzeppelin/contracts/math/SignedSafeMath.sol';
import {Errors, _require, _revert} from '../lib/BabylonErrors.sol';
import {AddressArrayUtils} from '../lib/AddressArrayUtils.sol';
import {PreciseUnitMath} from '../lib/PreciseUnitMath.sol';
import {Math} from '../lib/Math.sol';
import {SignatureChecker} from '../lib/SignatureChecker.sol';

import {IPriceOracle} from '../interfaces/IPriceOracle.sol';
import {IRewardsDistributor} from '../interfaces/IRewardsDistributor.sol';
import {IBabController} from '../interfaces/IBabController.sol';
import {IStrategyFactory} from '../interfaces/IStrategyFactory.sol';
import {IGardenValuer} from '../interfaces/IGardenValuer.sol';
import {IStrategy} from '../interfaces/IStrategy.sol';
import {IGarden, ICoreGarden} from '../interfaces/IGarden.sol';
import {IGardenNFT} from '../interfaces/IGardenNFT.sol';
import {IMardukGate} from '../interfaces/IMardukGate.sol';
import {IWETH} from '../interfaces/external/weth/IWETH.sol';
import {IHeart} from '../interfaces/IHeart.sol';
import {IERC1271} from '../interfaces/IERC1271.sol';

import {VTableBeaconProxy} from '../proxy/VTableBeaconProxy.sol';
import {VTableBeacon} from '../proxy/VTableBeacon.sol';

import {TimeLockedToken} from '../token/TimeLockedToken.sol';

/**
 * @title Garden
 *
 * User facing features of Garden plus BeaconProxy
 */
contract Garden is ERC20Upgradeable, ReentrancyGuard, VTableBeaconProxy, ICoreGarden, IERC1271 {
    using SafeCast for int256;
    using SignedSafeMath for int256;
    using PreciseUnitMath for int256;
    using SafeDecimalMath for int256;

    using SafeCast for uint256;
    using LowGasSafeMath for uint256;
    using PreciseUnitMath for uint256;
    using SafeDecimalMath for uint256;

    using Address for address;
    using AddressArrayUtils for address[];

    using SafeERC20 for IERC20;
    using ECDSA for bytes32;

    using SignatureChecker for address;

    /* ============ Events ============ */

    // DO NOT TOUCH for the love of GOD
    event GardenDeposit(address indexed _to, uint256 reserveToken, uint256 reserveTokenQuantity, uint256 timestamp);
    event GardenWithdrawal(
        address indexed _from,
        address indexed _to,
        uint256 reserveToken,
        uint256 reserveTokenQuantity,
        uint256 timestamp
    );

    event RewardsForContributor(address indexed _contributor, uint256 indexed _amount);
    event BABLRewardsForContributor(address indexed _contributor, uint256 _rewards);
    event StakeBABLRewards(address indexed _contributor, uint256 _babl);

    /* ============ Constants ============ */

    // Wrapped ETH address
    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    IERC20 private immutable BABL;

    // Strategy cooldown period
    uint256 private constant MIN_COOLDOWN_PERIOD = 60 seconds;
    uint256 private constant MAX_COOLDOWN_PERIOD = 7 days;

    uint8 private constant MAX_EXTRA_CREATORS = 4;
    uint256 private constant EARLY_WITHDRAWAL_PENALTY = 25e15;
    uint256 private constant TEN_PERCENT = 1e17;

    bytes32 private constant DEPOSIT_BY_SIG_TYPEHASH =
        keccak256(
            'DepositBySig(uint256 _amountIn,uint256 _minAmountOut,uint256 _nonce,uint256 _maxFee,address _to,address _referrer)'
        );
    bytes32 private constant WITHDRAW_BY_SIG_TYPEHASH =
        keccak256(
            'WithdrawBySig(uint256 _amountIn,uint256 _minAmountOut,uint256,_nonce,uint256 _maxFee,uint256 _withPenalty)'
        );
    bytes32 private constant REWARDS_BY_SIG_TYPEHASH =
        keccak256('RewardsBySig(uint256 _babl,uint256 _profits,uint256 _nonce,uint256 _maxFee)');

    bytes32 private constant STAKE_REWARDS_BY_SIG_TYPEHASH =
        keccak256(
            'StakeRewardsBySig(uint256 _babl,uint256 _profits,uint256 _minAmountOut,uint256 _nonce,uint256 _nonceHeart,uint256 _maxFee,address _to)'
        );

    uint256 private constant CLAIM_BY_SIG_CAP = 5_500e18; // 5.5K BABL cap per user per bySig tx

    uint256 private constant MAX_HEART_LOCK_VALUE = 4 * 365 days;

    /* ============ Structs ============ */

    /* ============ State Variables ============ */

    // Reserve Asset of the garden
    address public override reserveAsset;

    // Address of the controller
    IBabController public override controller;

    // Address of the rewards distributor
    IRewardsDistributor private rewardsDistributor;

    // The person that creates the garden
    address public override creator;

    bool private active; // DEPRECATED;
    bool public override privateGarden;

    uint256 private principal; // DEPRECATED;

    // The amount of funds set aside to be paid as rewards. Should NEVER be spent
    // on anything else ever.
    uint256 public override reserveAssetRewardsSetAside;

    uint256 private reserveAssetPrincipalWindow; // DEPRECATED
    int256 public override absoluteReturns; // Total profits or losses of this garden

    // Indicates the minimum liquidity the asset needs to have to be tradable by this garden
    uint256 public override minLiquidityAsset;

    uint256 public override depositHardlock; // Window of time after deposits when withdraws are disabled for that user
    uint256 private withdrawalsOpenUntil; // DEPRECATED

    // Contributors
    mapping(address => IGarden.Contributor) private contributors;
    uint256 public override totalContributors;
    uint256 private maxContributors; // DEPRECATED
    uint256 public override maxDepositLimit; // Limits the amount of deposits

    uint256 public override gardenInitializedAt; // Garden Initialized at timestamp
    // Number of garden checkpoints used to control the garden power and each contributor power with accuracy
    uint256 private pid;

    // Min contribution in the garden
    uint256 public override minContribution; // In reserve asset
    uint256 private minGardenTokenSupply; // DEPRECATED

    // Strategies variables
    uint256 public override totalStake;
    uint256 public override minVotesQuorum; // 10%. (0.01% = 1e14, 1% = 1e16)
    uint256 public override minVoters;
    uint256 public override minStrategyDuration; // Min duration for an strategy
    uint256 public override maxStrategyDuration; // Max duration for an strategy
    // Window for the strategy to cooldown after approval before receiving capital
    uint256 public override strategyCooldownPeriod;

    address[] private strategies; // Strategies that are either in candidate or active state
    address[] private finalizedStrategies; // Strategies that have finalized execution
    mapping(address => bool) public override strategyMapping;
    mapping(address => bool) public override isGardenStrategy; // Security control mapping

    // Keeper debt in reserve asset if any, repaid upon every strategy finalization
    uint256 public override keeperDebt;
    uint256 public override totalKeeperFees;

    // Allow public strategy creators for certain gardens
    bool public override publicStrategists;

    // Allow public strategy stewards for certain gardens
    bool public override publicStewards;

    // Addresses for extra creators
    address[MAX_EXTRA_CREATORS] public override extraCreators;

    // last recorded price per share of the garden during deposit or withdrawal operation
    uint256 public override lastPricePerShare;

    // last recorded time of the deposit or withdraw in seconds
    uint256 public override lastPricePerShareTS;

    // Decay rate of the slippage for pricePerShare over time
    uint256 public override pricePerShareDecayRate;

    // Base slippage for pricePerShare of the garden
    uint256 public override pricePerShareDelta;

    // Whether or not governance has verified and the category
    uint256 public override verifiedCategory;

    // Variable that overrides the depositLock with a global one
    uint256 public override hardlockStartsAt;

    // EIP-1271 signer
    address private signer;

    // Variable that controls whether the NFT can be minted after x amount of time
    uint256 public override canMintNftAfter;

    // Variable that controls whether this garden has custom integrations enabled
    bool public override customIntegrationsEnabled;

    // Variable that controls the user locks (only used by heart for now)
    mapping(address => uint256) public override userLock;

    /* ============ Modifiers ============ */

    function _onlyUnpaused() private view {
        // Do not execute if Globally or individually paused
        _require(!controller.isPaused(address(this)), Errors.ONLY_UNPAUSED);
    }

    /**
     * Check if msg.sender is keeper
     */
    function _onlyKeeperAndFee(uint256 _fee, uint256 _maxFee) private view {
        _require(controller.isValidKeeper(msg.sender), Errors.ONLY_KEEPER);
        _require(_fee <= _maxFee, Errors.FEE_TOO_HIGH);
    }

    /**
     * Check if array of finalized strategies to claim rewards has duplicated strategies
     */
    function _onlyNonDuplicateStrategies(address[] calldata _finalizedStrategies) private pure {
        _require(_finalizedStrategies.length < 20, Errors.DUPLICATED_STRATEGIES);
        for (uint256 i = 0; i < _finalizedStrategies.length; i++) {
            for (uint256 j = i + 1; j < _finalizedStrategies.length; j++) {
                _require(_finalizedStrategies[i] != _finalizedStrategies[j], Errors.DUPLICATED_STRATEGIES);
            }
        }
    }

    /**
     * Check if is a valid _signer with a valid nonce
     */
    function _onlyValidSigner(
        address _signer,
        address _to,
        uint256 _nonce,
        bytes32 _hash,
        bytes memory _signature
    ) private view {
        _require(contributors[_to].nonce == _nonce, Errors.INVALID_NONCE);
        // to prevent replay attacks
        _require(_signer.isValidSignatureNow(_hash, _signature), Errors.INVALID_SIGNER);
    }

    function _onlyNonZero(address _address) private pure {
        _require(_address != address(0), Errors.ADDRESS_IS_ZERO);
    }

    /* ============ Constructor ============ */

    constructor(VTableBeacon _beacon, IERC20 _babl) VTableBeaconProxy(_beacon) {
        BABL = _babl;
    }

    /* ============ External Functions ============ */

    /**
     * @notice
     *   Deposits the _amountIn in reserve asset into the garden. Gurantee to
     *   recieve at least _minAmountOut.
     * @dev
     *   WARN: If the reserve asset is different than ETH the sender needs to
     *   have approved the garden.
     *   Efficient to use of strategies.length == 0, otherwise can consume a lot
     *   of gas ~2kk. Use `depositBySig` for gas efficiency.
     * @param _amountIn               Amount of the reserve asset that is received from contributor
     * @param _minAmountOut           Min amount of Garden shares to receive by contributor
     * @param _to                     Address to mint Garden shares to
     * @param _referrer               The user that referred the deposit
     */
    function deposit(
        uint256 _amountIn,
        uint256 _minAmountOut,
        address _to,
        address _referrer
    ) external payable override nonReentrant {
        _internalDeposit(_amountIn, _minAmountOut, _to, msg.sender, _getPricePerShare(), minContribution, _referrer);
    }

    /**
     * @notice
     *   Deposits the _amountIn in reserve asset into the garden. Gurantee to
     *   recieve at least _minAmountOut.
     * @param _amountIn               Amount of the reserve asset that is received from contributor.
     * @param _minAmountOut           Min amount of Garden shares to receive by contributor.
     * @param _nonce                  Current nonce to prevent replay attacks.
     * @param _maxFee                 Max fee user is willing to pay keeper. Fee is
     *                                substracted from the withdrawn amount. Fee is
     *                                expressed in reserve asset.
     * @param _pricePerShare          Price per share of the garden calculated off-chain by Keeper.
     * @param _to                     Address to mint shares to.
     * @param _fee                    Actual fee keeper demands. Have to be less than _maxFee.
     * @param _signer                 The user to who signed the signature.
     * @param _referrer               The user that referred the deposit
     * @param _signature              Signature by the user to verify deposit parmas.
     */
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
        bytes memory _signature
    ) external override nonReentrant {
        _onlyKeeperAndFee(_fee, _maxFee);

        bytes32 hash =
            keccak256(
                abi.encode(
                    DEPOSIT_BY_SIG_TYPEHASH,
                    address(this),
                    _amountIn,
                    _minAmountOut,
                    _nonce,
                    _maxFee,
                    _to,
                    _referrer
                )
            )
                .toEthSignedMessageHash();
        _onlyValidSigner(_signer, _to, _nonce, hash, _signature);

        // If a Keeper fee is greater than zero then reduce user shares to
        // exchange and pay keeper the fee.
        if (_fee > 0) {
            // account for non 18 decimals ERC20 tokens, e.g. USDC
            uint256 feeShares = _reserveToShares(_fee, _pricePerShare);
            _internalDeposit(
                _amountIn.sub(_fee),
                _minAmountOut.sub(feeShares),
                _to,
                _signer,
                _pricePerShare,
                minContribution > _fee ? minContribution.sub(_fee) : 0,
                _referrer
            );
            // pay Keeper the fee
            IERC20(reserveAsset).safeTransferFrom(_signer, msg.sender, _fee);
        } else {
            _internalDeposit(_amountIn, _minAmountOut, _to, _signer, _pricePerShare, minContribution, _referrer);
        }
    }

    /**
     * @notice
     *   Exchanges a contributor gardens shares for at least minimum amount in reserve asset.
     * @dev
     *   ATTENTION. Do not call withPenalty unless certain. If penalty is set,
     *   it will be applied regardless of the garden state.
     *   It is advised to first try to withdraw with no penalty and it this
     *   reverts then try to with penalty.
     * @param _amountIn         Quantity of the garden token to withdrawal
     * @param _minAmountOut     Min quantity of reserve asset to receive
     * @param _to               Address to send component assets to
     * @param _withPenalty      Whether or not this is an immediate withdrawal
     * @param _unwindStrategy   Strategy to unwind
     */
    function withdraw(
        uint256 _amountIn,
        uint256 _minAmountOut,
        address payable _to,
        bool _withPenalty,
        address _unwindStrategy
    ) external override nonReentrant {
        _require(msg.sender == _to, Errors.ONLY_CONTRIBUTOR);

        _withdrawInternal(
            _amountIn,
            _minAmountOut,
            _to,
            _withPenalty,
            _unwindStrategy,
            _getPricePerShare(),
            _withPenalty ? IStrategy(_unwindStrategy).getNAV() : 0,
            0
        );
    }

    /**
     * @notice
     *   Exchanges user's gardens shairs for amount in reserve asset. This
     *   method allows users to leave garden and reclaim their inital investment
     *   plus profits or losses.
     * @dev
     *   Should be called instead of the `withdraw` to save gas due to
     *   pricePerShare caculated off-chain. Doesn't allow to unwind strategies
     *   contrary to `withdraw`.
     *   The Keeper fee is paid out of user's shares.
     *   The true _minAmountOut is actually _minAmountOut - _maxFee due to the
     *   Keeper fee.
     * @param _amountIn        Quantity of the garden tokens to withdraw.
     * @param _minAmountOut    Min quantity of reserve asset to receive.
     * @param _nonce           Current nonce to prevent replay attacks.
     * @param _maxFee          Max fee user is willing to pay keeper. Fee is
     *                         substracted from the withdrawn amount. Fee is
     *                         expressed in reserve asset.
     * @param _withPenalty     Whether or not this is an immediate withdrawal
     * @param _unwindStrategy  Strategy to unwind
     * @param _pricePerShare   Price per share of the garden calculated off-chain by Keeper.
     * @param _strategyNAV     NAV of the strategy to unwind.
     * @param _fee             Actual fee keeper demands. Have to be less than _maxFee.
     * @param _signer          The user to who signed the signature
     * @param _signature       Signature by the user to verify withdraw parmas.
     */
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
        bytes memory _signature
    ) external override nonReentrant {
        _onlyKeeperAndFee(_fee, _maxFee);

        bytes32 hash =
            keccak256(
                abi.encode(
                    WITHDRAW_BY_SIG_TYPEHASH,
                    address(this),
                    _amountIn,
                    _minAmountOut,
                    _nonce,
                    _maxFee,
                    _withPenalty
                )
            )
                .toEthSignedMessageHash();

        _onlyValidSigner(_signer, _signer, _nonce, hash, _signature);

        _withdrawInternal(
            _amountIn,
            _minAmountOut.sub(_maxFee),
            payable(_signer),
            _withPenalty,
            _unwindStrategy,
            _pricePerShare,
            _strategyNAV,
            _fee
        );
    }

    /**
     * @notice
     *   Claims a contributor rewards in BABL and reserve asset.
     * @param _finalizedStrategies  Finalized strategies to process
     */
    function claimReturns(address[] calldata _finalizedStrategies) external override nonReentrant {
        _onlyNonDuplicateStrategies(_finalizedStrategies);
        uint256[] memory rewards = new uint256[](8);
        rewards = rewardsDistributor.getRewards(address(this), msg.sender, _finalizedStrategies);
        _sendRewardsInternal(msg.sender, rewards[5], rewards[6], false);
    }

    /**
     * @notice
     *   User can claim the rewards from the strategies that his principal was
     *   invested in and stake BABL into Heart Garden
     * @param _minAmountOut         Minimum hBABL as part of the Heart garden BABL staking
     * @param _finalizedStrategies  Finalized strategies to process
     */
    function claimAndStakeReturns(uint256 _minAmountOut, address[] calldata _finalizedStrategies)
        external
        override
        nonReentrant
    {
        _onlyNonDuplicateStrategies(_finalizedStrategies);
        uint256[] memory rewards = new uint256[](8);
        rewards = rewardsDistributor.getRewards(address(this), msg.sender, _finalizedStrategies);
        IGarden heartGarden = IGarden(address(IHeart(controller.heart()).heartGarden()));
        // User non BABL rewards are sent to user wallet (_profits)
        // User BABL rewards are sent to this garden from RD to stake them into Heart Garden
        // on behalf of user
        _sendRewardsInternal(msg.sender, rewards[5], rewards[6], true); // true = stake babl rewards, false = no stake
        _approveBABL(address(heartGarden), rewards[5]);
        heartGarden.deposit(rewards[5], _minAmountOut, msg.sender, address(0));

        emit StakeBABLRewards(msg.sender, rewards[5]);
    }

    /**
     * @notice
     *   Claims a contributor rewards in BABL and reserve asset.
     * @dev
     *   Should be called instead of the `claimRewards at RD` to save gas due to
     *   getRewards caculated off-chain. The Keeper fee is paid out of user's
     *   reserveAsset and it is calculated off-chain.
     * @param _babl            BABL rewards from mining program.
     * @param _profits         Profit rewards in reserve asset.
     * @param _nonce           Current nonce to prevent replay attacks.
     * @param _maxFee          Max fee user is willing to pay keeper. Fee is
     *                         substracted from user wallet in reserveAsset. Fee is
     *                         expressed in reserve asset.
     * @param _fee             Actual fee keeper demands. Have to be less than _maxFee.
     * @param _signer          The user to who signed the signature
     * @param _signature       Signature by the user to verify claim parmas.
     */
    function claimRewardsBySig(
        uint256 _babl,
        uint256 _profits,
        uint256 _nonce,
        uint256 _maxFee,
        uint256 _fee,
        address _signer,
        bytes memory _signature
    ) external override nonReentrant {
        _onlyKeeperAndFee(_fee, _maxFee);
        bytes32 hash =
            keccak256(abi.encode(REWARDS_BY_SIG_TYPEHASH, address(this), _babl, _profits, _nonce, _maxFee))
                .toEthSignedMessageHash();
        _require(_fee > 0, Errors.FEE_TOO_LOW);

        _onlyValidSigner(_signer, _signer, _nonce, hash, _signature);
        _require(_babl <= CLAIM_BY_SIG_CAP, Errors.MAX_BABL_CAP_REACHED);
        // pay to Keeper the fee to execute the tx on behalf
        IERC20(reserveAsset).safeTransferFrom(_signer, msg.sender, _fee);
        _sendRewardsInternal(_signer, _babl, _profits, false);
    }

    /**
     * @notice
     *   This method allows users to stake their BABL rewards and claim their
     *   profit rewards.
     * @dev
     *   Should be called instead of the `claimAndStakeReturns` to save gas due
     *   to getRewards caculated off-chain. The Keeper fee is paid out of user's
     *   reserveAsset and it is calculated off-chain.
     * @param _babl            BABL rewards from mining program.
     * @param _profits         Profit rewards in reserve asset.
     * @param _minAmountOut    Minimum hBABL as part of the Heart Garden BABL staking
     * @param _nonce           Current nonce of user in the claiming garden at to prevent replay attacks.
     * @param _nonceHeart      Current nonce of user in Heart Garden to prevent replay attacks.
     * @param _maxFee          Max fee user is willing to pay keeper. Fee is
     *                         substracted from user wallet in reserveAsset. Fee is
     *                         expressed in reserve asset.
     * @param _fee             Actual fee keeper demands. Have to be less than _maxFee.
     * @param _pricePerShare   Price per share of Heart Garden
     * @param _signer          Signer of the tx
     * @param _signature       Signature of signer
     */
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
    ) external override nonReentrant {
        _onlyKeeperAndFee(_fee, _maxFee);
        IGarden heartGarden = IHeart(controller.heart()).heartGarden();
        bytes32 hash =
            keccak256(
                abi.encode(
                    STAKE_REWARDS_BY_SIG_TYPEHASH,
                    address(heartGarden),
                    _babl,
                    _profits,
                    _minAmountOut,
                    _nonce,
                    _nonceHeart,
                    _maxFee,
                    _signer
                )
            )
                .toEthSignedMessageHash();
        _onlyValidSigner(_signer, _signer, _nonce, hash, _signature);
        _require(_fee > 0, Errors.FEE_TOO_LOW);
        _require(_babl <= CLAIM_BY_SIG_CAP, Errors.MAX_BABL_CAP_REACHED);

        // pay to Keeper the fee to execute the tx on behalf
        IERC20(reserveAsset).safeTransferFrom(_signer, msg.sender, _fee);

        // User non BABL rewards are sent to user wallet (_profits)
        // User BABL rewards are sent to this garden from RD to later stake them into Heart Garden
        // on behalf of the user
        _sendRewardsInternal(_signer, _babl, _profits, true); // true = stake babl rewards, false = no stake
        _approveBABL(address(heartGarden), _babl);
        // grant permission to deposit
        signer = _signer;
        // Now this garden makes a deposit on Heart Garden on behalf of user
        heartGarden.stakeBySig(
            _babl,
            _profits,
            _minAmountOut,
            _nonce,
            _nonceHeart,
            _maxFee,
            _signer,
            _pricePerShare,
            address(this),
            _signature
        );
        // revoke permission to deposit
        signer = address(0);
        emit StakeBABLRewards(_signer, _babl);
    }

    /**
     * @notice
     *   Stakes _amountIn of BABL into the Heart garden.
     * @dev
     *   Staking is in practical terms is depositing BABL into Heart garden.
     * @param _amountIn               Amount of the reserve asset that is received from contributor.
     * @param _profits                Amount of the reserve asset that is received from contributor.
     * @param _minAmountOut           Min amount of Garden shares to receive by contributor.
     * @param _nonce                  Current nonce to prevent replay attacks.
     * @param _nonceHeart             Current nonce of the Heart garden to prevent replay attacks.
     * @param _maxFee                 Max fee user is willing to pay keeper. Fee is
     *                                substracted from the withdrawn amount. Fee is
     *                                expressed in reserve asset.
     * @param _pricePerShare          Price per share of the garden calculated off-chain by Keeper.
     * @param _to                     Address to mint shares to.
     * @param _signer                 The user to who signed the signature.
     * @param _signature              Signature by the user to verify deposit params.
     */
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
    ) external override nonReentrant {
        _require(controller.isGarden(msg.sender), Errors.ONLY_ACTIVE_GARDEN);
        _require(address(this) == address(IHeart(controller.heart()).heartGarden()), Errors.ONLY_HEART_GARDEN);

        bytes32 hash =
            keccak256(
                abi.encode(
                    STAKE_REWARDS_BY_SIG_TYPEHASH,
                    address(this),
                    _amountIn,
                    _profits,
                    _minAmountOut,
                    _nonce,
                    _nonceHeart,
                    _maxFee,
                    _to
                )
            )
                .toEthSignedMessageHash();
        _onlyValidSigner(_signer, _to, _nonceHeart, hash, _signature);

        // Keeper fee must have been paid in the original garden
        _internalDeposit(_amountIn, _minAmountOut, _to, _signer, _pricePerShare, minContribution, address(0));
    }

    /**
     * Allows a contributor to claim an NFT.
     */
    function claimNFT() external override {
        // minContribution is in reserve asset while balance of contributor in
        // garden shares which can lead to undesired results if reserve assets
        // decimals are not 18
        _require(balanceOf(msg.sender) >= minContribution, Errors.ONLY_CONTRIBUTOR);
        IGarden.Contributor storage contributor = contributors[msg.sender];
        _require(
            canMintNftAfter > 0 && block.timestamp.sub(contributor.initialDepositAt) > canMintNftAfter,
            Errors.CLAIM_GARDEN_NFT
        );
        IGardenNFT(controller.gardenNFT()).grantGardenNFT(msg.sender);
    }

    /**
     * Update user hardlock for this garden
     * @param _contributor        Address of the contributor
     * @param _userLock           Amount in seconds tht the user principal will be locked since deposit
     */
    function updateUserLock(address _contributor, uint256 _userLock) external override {
        _require(controller.isGarden(address(this)), Errors.ONLY_ACTIVE_GARDEN);
        _require(address(this) == address(IHeart(controller.heart()).heartGarden()), Errors.ONLY_HEART_GARDEN);
        _require(_userLock <= MAX_HEART_LOCK_VALUE && _userLock >= 183 days, Errors.SET_GARDEN_USER_LOCK);
        // Only the heart or the user can update the lock
        _require(
            balanceOf(_contributor) >= minContribution &&
                (msg.sender == controller.heart() || msg.sender == _contributor),
            Errors.ONLY_CONTRIBUTOR
        );
        // Can only increase the lock if lock expired
        _require(
            _userLock > userLock[_contributor] ||
                block.timestamp.sub(_getLastDepositAt(_contributor)) >= _getDepositHardlock(_contributor),
            Errors.SET_GARDEN_USER_LOCK
        );
        userLock[_contributor] = _userLock;
    }

    /**
     * Implements EIP-1271
     */
    function isValidSignature(bytes32 _hash, bytes memory _signature) public view override returns (bytes4 magicValue) {
        return
            ECDSA.recover(_hash, _signature) == signer && signer != address(0)
                ? this.isValidSignature.selector
                : bytes4(0);
    }

    /* ============ External Getter Functions ============ */

    /**
     * Gets current strategies
     *
     * @return  address[]        Returns list of addresses
     */

    function getStrategies() external view override returns (address[] memory) {
        return strategies;
    }

    /**
     * Gets finalized strategies
     *
     * @return  address[]        Returns list of addresses
     */

    function getFinalizedStrategies() external view override returns (address[] memory) {
        return finalizedStrategies;
    }

    /**
     * Returns the heart voting power of a specific user
     * @param _contributor      Address of the contributor
     * @return uint256          Voting power of the contributor
     */
    function getVotingPower(address _contributor) public view override returns (uint256) {
        address heartGarden = address(IHeart(controller.heart()).heartGarden());
        uint256 balance = balanceOf(_contributor);
        if (address(this) != heartGarden) {
            return balance;
        }
        uint256 lock = userLock[_contributor];
        if (lock == 0) {
            return balance.div(8);
        }
        if (lock >= MAX_HEART_LOCK_VALUE) {
            return balance;
        }
        return balance.preciseMul(lock.preciseDiv(MAX_HEART_LOCK_VALUE));
    }

    /**
     * @notice
     *   Gets the contributor data
     * @param  _contributor       The contributor address
     * @return lastDepositAt      Timestamp of the last deposit
     * @return initialDepositAt   Timestamp of the initial deposit
     * @return claimedAt          Timestamp of the last claim
     * @return claimedBABL        Total amount of claimed BABL
     * @return claimedRewards     Total amount of claimed rewards
     * @return withdrawnSince     Timestamp of last withdrawal
     * @return totalDeposits      Total amount of deposits
     * @return nonce              Contributor nonce
     * @return lockedBalance      Locked balance of the contributor
     */
    function getContributor(address _contributor)
        external
        view
        override
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
        )
    {
        IGarden.Contributor memory contributor = contributors[_contributor];
        return (
            contributor.lastDepositAt,
            contributor.initialDepositAt,
            contributor.claimedAt,
            contributor.claimedBABL,
            contributor.claimedRewards,
            contributor.withdrawnSince,
            contributor.totalDeposits,
            contributor.nonce,
            contributor.lockedBalance
        );
    }

    /* ============ Internal Functions ============ */

    /**
     * Converts garden shares to amount in reserve asset accounting for decimal difference
     */
    function _sharesToReserve(uint256 _shares, uint256 _pricePerShare) internal view returns (uint256) {
        return _shares.preciseMul(_pricePerShare).preciseMul(10**ERC20Upgradeable(reserveAsset).decimals());
    }

    /**
     * Converts amount in reserve asset to garden shares accounting for decimal difference
     */
    function _reserveToShares(uint256 _reserve, uint256 _pricePerShare) internal view returns (uint256) {
        return _reserve.preciseDiv(10**ERC20Upgradeable(reserveAsset).decimals()).preciseDiv(_pricePerShare);
    }

    /**
     * @notice
     *   Exchanges a contributor gardens shares for at least minimum amount in reserve asset.
     * @dev
     *   See withdraw and withdrawBySig for params and comments.
     */
    function _withdrawInternal(
        uint256 _amountIn,
        uint256 _minAmountOut,
        address payable _to,
        bool _withPenalty,
        address _unwindStrategy,
        uint256 _pricePerShare,
        uint256 _strategyNAV,
        uint256 _fee
    ) internal {
        _onlyUnpaused();
        _checkLastPricePerShare(_pricePerShare);

        uint256 prevBalance = balanceOf(_to);
        _require(prevBalance > 0, Errors.ONLY_CONTRIBUTOR);
        // Flashloan protection
        _require(block.timestamp.sub(_getLastDepositAt(_to)) >= _getDepositHardlock(_to), Errors.DEPOSIT_HARDLOCK);

        // Strategists cannot withdraw locked stake while in active strategies
        // Withdrawal amount has to be equal or less than msg.sender balance minus the locked balance
        // any amountIn higher than user balance is treated as withdrawAll
        uint256 lockedBalance = contributors[_to].lockedBalance;
        _amountIn = _amountIn > prevBalance.sub(lockedBalance) ? prevBalance.sub(lockedBalance) : _amountIn;
        _require(_amountIn <= prevBalance.sub(lockedBalance), Errors.TOKENS_STAKED);

        uint256 amountOut = _sharesToReserve(_amountIn, _pricePerShare);

        // if withPenaltiy then unwind strategy
        if (_withPenalty && !(_liquidReserve() >= amountOut)) {
            amountOut = amountOut.sub(amountOut.preciseMul(EARLY_WITHDRAWAL_PENALTY));
            // When unwinding a strategy, a slippage on integrations will result in receiving less tokens
            // than desired so we have have to account for this with a 5% slippage.
            // TODO: if there is more than 5% slippage that will block
            // withdrawal
            _onlyNonZero(_unwindStrategy);
            IStrategy(_unwindStrategy).unwindStrategy(amountOut.add(amountOut.preciseMul(5e16)), _strategyNAV);
        }

        _require(amountOut >= _minAmountOut && _amountIn > 0, Errors.RECEIVE_MIN_AMOUNT);

        _require(_liquidReserve() >= amountOut, Errors.MIN_LIQUIDITY);

        _burn(_to, _amountIn);
        if (_fee > 0) {
            // If fee > 0 pay Accountant
            IERC20(reserveAsset).safeTransfer(msg.sender, _fee);
        }
        _updateContributorWithdrawalInfo(_to, amountOut, prevBalance, balanceOf(_to), _amountIn);
        contributors[_to].nonce++;

        _safeSendReserveAsset(_to, amountOut.sub(_fee));

        emit GardenWithdrawal(_to, _to, amountOut, _amountIn, block.timestamp);
    }

    /**
     * Returns price per share of a garden.
     */
    function _getPricePerShare() internal view returns (uint256) {
        if (strategies.length == 0) {
            return
                totalSupply() == 0
                    ? PreciseUnitMath.preciseUnit()
                    : _liquidReserve().preciseDiv(uint256(10)**ERC20Upgradeable(reserveAsset).decimals()).preciseDiv(
                        totalSupply()
                    );
        } else {
            // Get valuation of the Garden with the quote asset as the reserve asset.
            return IGardenValuer(controller.gardenValuer()).calculateGardenValuation(address(this), reserveAsset);
        }
    }

    /**
     * @notice
     *   Deposits the _amountIn in reserve asset into the garden. Gurantee to
     *   recieve at least _minAmountOut.
     * @param _amountIn         Amount of the reserve asset that is received from contributor
     * @param _minAmountOut     Min amount of garden shares to receive by the contributor
     * @param _to               Address to mint shares to
     * @param _from             Address providing incoming funds
     * @param _pricePerShare    Price per share of the garden calculated off-chain by Keeper
     * @param _minContribution  Minimum contribution to be made during the deposit nominated in reserve asset
     * @param _referrer         The user that referred the deposit
     */
    function _internalDeposit(
        uint256 _amountIn,
        uint256 _minAmountOut,
        address _to,
        address _from,
        uint256 _pricePerShare,
        uint256 _minContribution,
        address _referrer
    ) private {
        _onlyUnpaused();
        _onlyNonZero(_to);
        _checkLastPricePerShare(_pricePerShare);

        bool canDeposit = !privateGarden || IMardukGate(controller.mardukGate()).canJoinAGarden(address(this), _to);
        _require(_isCreator(_to) || canDeposit, Errors.USER_CANNOT_JOIN);

        if (maxDepositLimit > 0) {
            // This is wrong; but calculate principal would be gas expensive
            _require(_liquidReserve().add(_amountIn) <= maxDepositLimit, Errors.MAX_DEPOSIT_LIMIT);
        }

        _require(_amountIn >= _minContribution, Errors.MIN_CONTRIBUTION);

        uint256 reserveAssetBalanceBefore = IERC20(reserveAsset).balanceOf(address(this));
        // If reserve asset is WETH and user sent ETH then wrap it
        if (reserveAsset == WETH && msg.value > 0) {
            IWETH(WETH).deposit{value: msg.value}();
        } else {
            // Transfer ERC20 to the garden
            IERC20(reserveAsset).safeTransferFrom(_from, address(this), _amountIn);
        }

        // Make sure we received the correct amount of reserve asset
        _require(
            IERC20(reserveAsset).balanceOf(address(this)).sub(reserveAssetBalanceBefore) == _amountIn,
            Errors.MSG_VALUE_DO_NOT_MATCH
        );

        uint256 previousBalance = balanceOf(_to);
        uint256 normalizedAmountIn = _amountIn.preciseDiv(uint256(10)**ERC20Upgradeable(reserveAsset).decimals());
        uint256 sharesToMint = normalizedAmountIn.preciseDiv(_pricePerShare);

        // make sure contributor gets desired amount of shares
        _require(sharesToMint >= _minAmountOut, Errors.RECEIVE_MIN_AMOUNT);

        // mint shares
        _mint(_to, sharesToMint);

        // Adds rewards
        controller.addAffiliateReward(_from, _referrer != address(0) ? _referrer : _from, _amountIn);
        // We need to update at Rewards Distributor smartcontract for rewards accurate calculations
        _updateContributorDepositInfo(_to, previousBalance, _amountIn, sharesToMint);
        contributors[_to].nonce++;

        emit GardenDeposit(_to, _minAmountOut, _amountIn, block.timestamp);
    }

    /**
     * @notice  Sends BABL and reserve asset rewards to a contributor
     * @param _contributor     Contributor address to send rewards to
     * @param _babl            BABL rewards from mining program.
     * @param _profits         Profit rewards in reserve asset.
     * @param _stake           Whether user wants to stake in Heart or not its BABL rewards.
     */
    function _sendRewardsInternal(
        address _contributor,
        uint256 _babl,
        uint256 _profits,
        bool _stake
    ) internal {
        IGarden.Contributor storage contributor = contributors[_contributor];

        _onlyUnpaused();
        _require(contributor.nonce > 0, Errors.ONLY_CONTRIBUTOR); // have been user garden
        _require(_babl > 0 || _profits > 0, Errors.NO_REWARDS_TO_CLAIM);
        _require(reserveAssetRewardsSetAside >= _profits, Errors.RECEIVE_MIN_AMOUNT);
        _require(block.timestamp > contributor.claimedAt, Errors.ALREADY_CLAIMED);

        // Avoid replay attack between claimRewardsBySig and claimRewards or even between 2 of each
        contributor.nonce++;
        contributor.claimedAt = block.timestamp; // Checkpoint of this claim

        if (_profits > 0) {
            contributor.claimedRewards = contributor.claimedRewards.add(_profits); // Rewards claimed properly
            reserveAssetRewardsSetAside = reserveAssetRewardsSetAside.sub(_profits);
            _safeSendReserveAsset(payable(_contributor), _profits);
            emit RewardsForContributor(_contributor, _profits);
        }
        if (_babl > 0) {
            // If _stake = true, the BABL is sent first to this garden
            // then it is deposited into Heart Garden on behalf of user
            uint256 bablSent = rewardsDistributor.sendBABLToContributor(_stake ? address(this) : _contributor, _babl);
            contributor.claimedBABL = contributor.claimedBABL.add(bablSent); // BABL Rewards claimed properly
            emit BABLRewardsForContributor(_contributor, bablSent);
        }
    }

    /**
     * @notice
     *   Returns available liquidity where
     *   liquidity = balance - (reserveAssetRewardsSetAside + keeperDebt)
     * @return  Amount of liquidity available in reserve asset
     */
    function _liquidReserve() private view returns (uint256) {
        uint256 reserve = IERC20(reserveAsset).balanceOf(address(this)).sub(reserveAssetRewardsSetAside);
        return reserve > keeperDebt ? reserve.sub(keeperDebt) : 0;
    }

    /**
     * @notice
     *   Updates contributor data upon token transfers. Garden token transfers
     *   are not enabled for all gardens.
     * @dev
     *   Locked balance of the contributor can't be transfered.
     * @param _from           Address of the contributor sending tokens
     * @param _to             Address of the contributor receiving tokens
     * @param _amount         Amount to send
     */
    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _amount
    ) internal virtual override {
        super._beforeTokenTransfer(_from, _to, _amount);
        _require(
            _from == address(0) || _to == address(0) || (controller.gardenTokensTransfersEnabled() && !privateGarden),
            Errors.GARDEN_TRANSFERS_DISABLED
        );

        if (_from != address(0) && _to != address(0)) {
            uint256 fromBalance = balanceOf(_from);

            uint256 lockedBalance = contributors[_from].lockedBalance;
            _require(fromBalance.sub(lockedBalance) >= _amount, Errors.TOKENS_STAKED);

            _updateContributorWithdrawalInfo(_from, 0, fromBalance, fromBalance.sub(_amount), _amount);
            _updateContributorDepositInfo(_to, balanceOf(_to), 0, _amount);
        }
    }

    /**
     * @notice
     *   Sends the amount of reserve asset to the addressee
     * @dev
     *   Watch out of reentrancy attacks on `sendValue`
     * @param _to             Address to send ERC20/ETH to
     * @param _amount         Amount to send
     */
    function _safeSendReserveAsset(address payable _to, uint256 _amount) private {
        if (reserveAsset == WETH) {
            // Check that the withdrawal is possible
            // Unwrap WETH if ETH balance lower than amount
            if (address(this).balance < _amount) {
                IWETH(WETH).withdraw(_amount.sub(address(this).balance));
            }
            // Send ETH
            Address.sendValue(_to, _amount);
        } else {
            // Send reserve asset
            IERC20(reserveAsset).safeTransfer(_to, _amount);
        }
    }

    /**
     * @notice
     *   Approves spending of BABL token to an address
     * @dev
     *   Approves BABL staking amount for claim and stake rewards
     *   Only used to approve Heart Garden to stake
     * @param _to             Address to approve to
     * @param _amount         Amount of allowance
     */
    function _approveBABL(address _to, uint256 _amount) internal {
        IERC20(BABL).safeApprove(_to, _amount);
    }

    /**
     * @notice                  Updates the contributor data upon deposit
     * @param _contributor      Contributor to update
     * @param _previousBalance  Previous balance of the contributor
     * @param _amountIn         Amount deposited in reserve asset
     * @param _sharesToMint     Amount of garden shares to mint
     */
    function _updateContributorDepositInfo(
        address _contributor,
        uint256 _previousBalance,
        uint256 _amountIn,
        uint256 _sharesToMint
    ) private {
        IGarden.Contributor storage contributor = contributors[_contributor];
        // If new contributor, create one, increment count, and set the current TS
        if (_previousBalance == 0 || contributor.initialDepositAt == 0) {
            totalContributors = totalContributors.add(1);
            contributor.initialDepositAt = block.timestamp;
        }
        // We make checkpoints around contributor deposits to give the right rewards afterwards
        contributor.totalDeposits = contributor.totalDeposits.add(_amountIn);
        contributor.lastDepositAt = block.timestamp;
        // RD checkpoint for accurate rewards
        rewardsDistributor.updateGardenPowerAndContributor(
            address(this),
            _contributor,
            _previousBalance,
            _sharesToMint,
            true // true = deposit , false = withdraw
        );
    }

    /**
     * @notice                  Updates the contributor data upon withdrawal
     * @param _contributor      Contributor to update
     * @param _amountOut        Amount withdrawn in reserve asset
     * @param _previousBalance  Previous balance of the contributor
     * @param _balance          New balance
     * @param _amountToBurn     Amount of garden shares to burn
     */
    function _updateContributorWithdrawalInfo(
        address _contributor,
        uint256 _amountOut,
        uint256 _previousBalance,
        uint256 _balance,
        uint256 _amountToBurn
    ) private {
        IGarden.Contributor storage contributor = contributors[_contributor];
        // If withdrawn everything
        if (_balance == 0) {
            contributor.lastDepositAt = 0;
            contributor.initialDepositAt = 0;
            contributor.withdrawnSince = 0;
            contributor.totalDeposits = 0;
            userLock[_contributor] = 0;
            totalContributors = totalContributors.sub(1);
        } else {
            contributor.withdrawnSince = contributor.withdrawnSince.add(_amountOut);
        }
        // RD checkpoint for accurate rewards
        rewardsDistributor.updateGardenPowerAndContributor(
            address(this),
            _contributor,
            _previousBalance,
            _amountToBurn,
            false // true = deposit , false = withdraw
        );
    }

    /**
     * @notice          Checks if an address is a creator
     * @param _creator  Creator address
     * @return          True if creator
     */
    function _isCreator(address _creator) private view returns (bool) {
        return
            _creator != address(0) &&
            (extraCreators[0] == _creator ||
                extraCreators[1] == _creator ||
                extraCreators[2] == _creator ||
                extraCreators[3] == _creator ||
                _creator == creator);
    }

    /**
     * @notice
     *   Validates that pricePerShare is within acceptable range; if not reverts
     * @dev
     *   Allowed slippage between deposits and withdrawals in terms of the garden price per share is:
     *
     *     slippage = lastPricePerShare % (pricePerShareDelta + timePast * pricePerShareDecayRate);
     *
     *   For example, if lastPricePerShare is 1e18 and slippage is 10% then deposits with pricePerShare between
     *   9e17 and 11e17 allowed immediately. After one year (100% change in time) and with a decay rate 1x;
     *   deposits between 5e17 and 2e18 are possible. Different gardens should have different settings for
     *   slippage and decay rate due to various volatility of the strategies. For example, stable gardens
     *   would have low slippage and decay rate while some moonshot gardens may have both of them
     *   as high as 100% and 10x.
     * @param _pricePerShare  Price of the graden share to validate against historical data
     */
    function _checkLastPricePerShare(uint256 _pricePerShare) private {
        uint256 slippage = pricePerShareDelta > 0 ? pricePerShareDelta : 25e16;
        uint256 decay = pricePerShareDecayRate > 0 ? pricePerShareDecayRate : 1e18;
        // if no previous record then just pass the check
        if (lastPricePerShare != 0) {
            slippage = slippage.add(block.timestamp.sub(lastPricePerShareTS).preciseDiv(365 days).preciseMul(decay));
            if (_pricePerShare > lastPricePerShare) {
                _require(
                    _pricePerShare.sub(lastPricePerShare) <= lastPricePerShare.preciseMul(slippage),
                    Errors.PRICE_PER_SHARE_WRONG
                );
            } else {
                _require(
                    lastPricePerShare.sub(_pricePerShare) <=
                        lastPricePerShare.sub(lastPricePerShare.preciseDiv(slippage.add(1e18))),
                    Errors.PRICE_PER_SHARE_WRONG
                );
            }
        }
        lastPricePerShare = _pricePerShare;
        lastPricePerShareTS = block.timestamp;
    }

    /**
     * @notice     Returns last timestamp of the last contributor deposit
     * @param _to  Contributor address
     * @return     Timestamp of the last contributor desposit
     */
    function _getLastDepositAt(address _to) private view returns (uint256) {
        return hardlockStartsAt > contributors[_to].lastDepositAt ? hardlockStartsAt : contributors[_to].lastDepositAt;
    }

    /**
     * @notice     Returns the hardlock in seconds for this user
     * @param _to  Contributor address
     * @return     Time that the principal is locked since last deposit
     */
    function _getDepositHardlock(address _to) private view returns (uint256) {
        return userLock[_to] > 0 ? userLock[_to] : depositHardlock;
    }
}

contract GardenV26 is Garden {
    constructor(VTableBeacon _beacon, IERC20 _babl) Garden(_beacon, _babl) {}
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

pragma solidity >=0.6.2 <0.8.0;

import "../../introspection/IERC165.sol";

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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
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

    constructor () internal {
        _status = _NOT_ENTERED;
    }

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/ContextUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "../../math/SafeMathUpgradeable.sol";
import "../../proxy/Initializable.sol";

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
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable {
    using SafeMathUpgradeable for uint256;

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
    function __ERC20_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal initializer {
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
    uint256[44] private __gap;
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;


/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value < 2**128, "SafeCast: value doesn\'t fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value < 2**64, "SafeCast: value doesn\'t fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value < 2**32, "SafeCast: value doesn\'t fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value < 2**16, "SafeCast: value doesn\'t fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value < 2**8, "SafeCast: value doesn\'t fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= -2**127 && value < 2**127, "SafeCast: value doesn\'t fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= -2**63 && value < 2**63, "SafeCast: value doesn\'t fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= -2**31 && value < 2**31, "SafeCast: value doesn\'t fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= -2**15 && value < 2**15, "SafeCast: value doesn\'t fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= -2**7 && value < 2**7, "SafeCast: value doesn\'t fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        require(value < 2**255, "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
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

/**
 * @title AddressArrayUtils
 * @author Set Protocol
 *
 * Utility functions to handle Address Arrays
 */
library AddressArrayUtils {
    /**
     * Finds the index of the first occurrence of the given element.
     * @param A The input array to search
     * @param a The value to find
     * @return Returns (index and isIn) for the first occurrence starting from index 0
     */
    function indexOf(address[] memory A, address a) internal pure returns (uint256, bool) {
        uint256 length = A.length;
        for (uint256 i = 0; i < length; i++) {
            if (A[i] == a) {
                return (i, true);
            }
        }
        return (uint256(-1), false);
    }

    /**
     * Returns true if the value is present in the list. Uses indexOf internally.
     * @param A The input array to search
     * @param a The value to find
     * @return Returns isIn for the first occurrence starting from index 0
     */
    function contains(address[] memory A, address a) internal pure returns (bool) {
        (, bool isIn) = indexOf(A, a);
        return isIn;
    }

    /**
     * Returns true if there are 2 elements that are the same in an array
     * @param A The input array to search
     * @return Returns boolean for the first occurrence of a duplicate
     */
    function hasDuplicate(address[] memory A) internal pure returns (bool) {
        require(A.length > 0, 'A is empty');

        for (uint256 i = 0; i < A.length - 1; i++) {
            address current = A[i];
            for (uint256 j = i + 1; j < A.length; j++) {
                if (current == A[j]) {
                    return true;
                }
            }
        }
        return false;
    }

    /**
     * @param A The input array to search
     * @param a The address to remove
     * @return Returns the array with the object removed.
     */
    function remove(address[] memory A, address a) internal pure returns (address[] memory) {
        (uint256 index, bool isIn) = indexOf(A, a);
        if (!isIn) {
            revert('Address not in array.');
        } else {
            (address[] memory _A, ) = pop(A, index);
            return _A;
        }
    }

    /**
     * Removes specified index from array
     * @param A The input array to search
     * @param index The index to remove
     * @return Returns the new array and the removed entry
     */
    function pop(address[] memory A, uint256 index) internal pure returns (address[] memory, address) {
        uint256 length = A.length;
        require(index < A.length, 'Index must be < A length');
        address[] memory newAddresses = new address[](length - 1);
        for (uint256 i = 0; i < index; i++) {
            newAddresses[i] = A[i];
        }
        for (uint256 j = index + 1; j < length; j++) {
            newAddresses[j - 1] = A[j];
        }
        return (newAddresses, A[index]);
    }

    /**
     * Returns the combination of the two arrays
     * @param A The first array
     * @param B The second array
     * @return Returns A extended by B
     */
    function extend(address[] memory A, address[] memory B) internal pure returns (address[] memory) {
        uint256 aLength = A.length;
        uint256 bLength = B.length;
        address[] memory newAddresses = new address[](aLength + bLength);
        for (uint256 i = 0; i < aLength; i++) {
            newAddresses[i] = A[i];
        }
        for (uint256 j = 0; j < bLength; j++) {
            newAddresses[aLength + j] = B[j];
        }
        return newAddresses;
    }

    /*
      Unfortunately Solidity does not support convertion of the fixed array to dynamic array so these functions are
      required. This functionality would be supported in the future so these methods can be removed.
    */
    function toDynamic(address _one, address _two) internal pure returns (address[] memory) {
        address[] memory arr = new address[](2);
        arr[0] = _one;
        arr[1] = _two;
        return arr;
    }

    function toDynamic(
        address _one,
        address _two,
        address _three
    ) internal pure returns (address[] memory) {
        address[] memory arr = new address[](3);
        arr[0] = _one;
        arr[1] = _two;
        arr[2] = _three;
        return arr;
    }

    function toDynamic(
        address _one,
        address _two,
        address _three,
        address _four
    ) internal pure returns (address[] memory) {
        address[] memory arr = new address[](4);
        arr[0] = _one;
        arr[1] = _two;
        arr[2] = _three;
        arr[3] = _four;
        return arr;
    }
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

// Libraries
import './SafeDecimalMath.sol';

// https://docs.synthetix.io/contracts/source/libraries/math
library Math {
    using LowGasSafeMath for uint256;
    using SafeDecimalMath for uint256;

    /**
     * @dev Uses "exponentiation by squaring" algorithm where cost is 0(logN)
     * vs 0(N) for naive repeated multiplication.
     * Calculates x^n with x as fixed-point and n as regular unsigned int.
     * Calculates to 18 digits of precision with SafeDecimalMath.unit()
     */
    function powDecimal(uint256 x, uint256 n) internal pure returns (uint256) {
        // https://mpark.github.io/programming/2014/08/18/exponentiation-by-squaring/

        uint256 result = SafeDecimalMath.unit();
        while (n > 0) {
            if (n % 2 != 0) {
                result = result.multiplyDecimal(x);
            }
            x = x.multiplyDecimal(x);
            n /= 2;
        }
        return result;
    }

    function abs(int256 x) internal pure returns (int256) {
        return x >= 0 ? x : -x;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import {ECDSA} from '@openzeppelin/contracts/cryptography/ECDSA.sol';
import {Address} from '@openzeppelin/contracts/utils/Address.sol';

import {IERC1271} from '../interfaces/IERC1271.sol';

/**
 * @dev Signature verification helper: Provide a single mechanism to verify both private-key (EOA) ECDSA signature and
 * ERC1271 contract sigantures. Using this instead of ECDSA.recover in your contract will make them compatible with
 * smart contract wallets such as Argent and Gnosis.
 *
 * Note: unlike ECDSA signatures, contract signature's are revocable, and the outcome of this function can thus change
 * through time. It could return true at block N and false at block N+1 (or the opposite).
 *
 */

library SignatureChecker {
    function isValidSignatureNow(
        address signer,
        bytes32 hash,
        bytes memory signature
    ) internal view returns (bool) {
        if (Address.isContract(signer)) {
            try IERC1271(signer).isValidSignature(hash, signature) returns (bytes4 magicValue) {
                return magicValue == IERC1271(signer).isValidSignature.selector;
            } catch {
                return false;
            }
        } else {
            return ECDSA.recover(hash, signature) == signer;
        }
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.7.6;

import {ITokenIdentifier} from './ITokenIdentifier.sol';

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

    function getCompoundExchangeRate(address _asset, address _finalAsset) external view returns (uint256);

    function getCreamExchangeRate(address _asset, address _finalAsset) external view returns (uint256);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.7.6;

import {TimeLockedToken} from '../token/TimeLockedToken.sol';

/**
 * @title IRewardsDistributor
 * @author Babylon Finance
 *
 * Interface for the rewards distributor in charge of the BABL Mining Program.
 */

interface IRewardsDistributor {
    /* ========== View functions ========== */

    function babltoken() external view returns (TimeLockedToken);

    function getStrategyRewards(address _strategy) external view returns (uint256);

    function getRewards(
        address _garden,
        address _contributor,
        address[] calldata _finalizedStrategies
    ) external view returns (uint256[] memory);

    function getGardenProfitsSharing(address _garden) external view returns (uint256[3] memory);

    function checkMining(uint256 _quarterNum, address _strategy) external view returns (uint256[17] memory);

    function estimateUserRewards(address _strategy, address _contributor) external view returns (uint256[] memory);

    function estimateStrategyRewards(address _strategy) external view returns (uint256);

    function getPriorBalance(
        address _garden,
        address _contributor,
        uint256 _timestamp
    )
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    /* ============ External Functions ============ */

    function setProfitRewards(
        address _garden,
        uint256 _strategistShare,
        uint256 _stewardsShare,
        uint256 _lpShare
    ) external;

    function migrateAddressToCheckpoints(address _garden, bool _toMigrate) external;

    function setBABLMiningParameters(uint256[12] memory _newMiningParams) external;

    function updateProtocolPrincipal(uint256 _capital, bool _addOrSubstract) external;

    function updateGardenPowerAndContributor(
        address _garden,
        address _contributor,
        uint256 _previousBalance,
        uint256 _tokenDiff,
        bool _addOrSubstract
    ) external;

    function sendBABLToContributor(address _to, uint256 _babl) external returns (uint256);
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

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.7.6;

import {IIntegration} from './IIntegration.sol';

/**
 * @title IStrategyFactory
 * @author Babylon Finance
 *
 * Interface for the strategy factory
 */
interface IStrategyFactory {
    function createStrategy(
        string memory _name,
        string memory _symbol,
        address _strategist,
        address _garden,
        uint256[] calldata _stratParams
    ) external returns (address);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.7.6;

interface IGardenValuer {
    function calculateGardenValuation(address _garden, address _quoteAsset) external view returns (uint256);

    function getLossesGarden(address _garden, uint256 _since) external view returns (uint256);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.7.6;

import {IGarden} from '../interfaces/IGarden.sol';

/**
 * @title IStrategy
 * @author Babylon Finance
 *
 * Interface for strategy
 */
interface IStrategy {
    function initialize(
        address _strategist,
        address _garden,
        address _controller,
        uint256 _maxCapitalRequested,
        uint256 _stake,
        uint256 _strategyDuration,
        uint256 _expectedReturn,
        uint256 _maxAllocationPercentage,
        uint256 _maxGasFeePercentage,
        uint256 _maxTradeSlippagePercentage
    ) external;

    function resolveVoting(
        address[] calldata _voters,
        int256[] calldata _votes,
        uint256 fee
    ) external;

    function updateParams(uint256[5] calldata _params) external;

    function sweep(address _token, uint256 _newSlippage) external;

    function setData(
        uint8[] calldata _opTypes,
        address[] calldata _opIntegrations,
        bytes memory _opEncodedData
    ) external;

    function executeStrategy(uint256 _capital, uint256 fee) external;

    function getNAV() external view returns (uint256);

    function opEncodedData() external view returns (bytes memory);

    function getOperationsCount() external view returns (uint256);

    function getOperationByIndex(uint8 _index)
        external
        view
        returns (
            uint8,
            address,
            bytes memory
        );

    function finalizeStrategy(
        uint256 fee,
        string memory _tokenURI,
        uint256 _minReserveOut
    ) external;

    function unwindStrategy(uint256 _amountToUnwind, uint256 _strategyNAV) external;

    function invokeFromIntegration(
        address _target,
        uint256 _value,
        bytes calldata _data
    ) external returns (bytes memory);

    function invokeApprove(
        address _spender,
        address _asset,
        uint256 _quantity
    ) external;

    function trade(
        address _sendToken,
        uint256 _sendQuantity,
        address _receiveToken
    ) external returns (uint256);

    function trade(
        address _sendToken,
        uint256 _sendQuantity,
        address _receiveToken,
        uint256 _overrideSlippage
    ) external returns (uint256);

    function handleWeth(bool _isDeposit, uint256 _wethAmount) external;

    function signalUnlock(uint256 _fee) external;

    function updateStrategyRewards(uint256 _newTotalBABLRewards, uint256 _newCapitalReturned) external;

    function getStrategyState()
        external
        view
        returns (
            address,
            bool,
            bool,
            bool,
            uint256,
            uint256,
            uint256
        );

    function getStrategyRewardsContext()
        external
        view
        returns (
            address,
            uint256[15] memory,
            bool[2] memory
        );

    function isStrategyActive() external view returns (bool);

    function getUserVotes(address _address) external view returns (int256);

    function strategist() external view returns (address);

    function enteredAt() external view returns (uint256);

    function enteredCooldownAt() external view returns (uint256);

    function stake() external view returns (uint256);

    function strategyRewards() external view returns (uint256);

    function maxCapitalRequested() external view returns (uint256);

    function maxAllocationPercentage() external view returns (uint256);

    function maxTradeSlippagePercentage() external view returns (uint256);

    function maxGasFeePercentage() external view returns (uint256);

    function expectedReturn() external view returns (uint256);

    function duration() external view returns (uint256);

    function totalPositiveVotes() external view returns (uint256);

    function totalNegativeVotes() external view returns (uint256);

    function capitalReturned() external view returns (uint256);

    function capitalAllocated() external view returns (uint256);

    function garden() external view returns (IGarden);
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
        uint256 _newRewardsToSetAside
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

    function updateUserLock(address _contributor, uint256 _userLock) external;
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
import {IBabController} from './IBabController.sol';

/**
 * @title IGardenNFT
 * @author Babylon Finance
 *
 * Interface for operating with a Garden NFT.
 */
interface IGardenNFT {
    function grantGardenNFT(address _user) external returns (uint256);

    function saveGardenURIAndSeed(
        address _garden,
        string memory _gardenTokenURI,
        uint256 _seed
    ) external;

    function gardenTokenURIs(address _garden) external view returns (string memory);

    function gardenSeeds(address _garden) external view returns (uint256);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.7.6;

import {IBabylonGate} from './IBabylonGate.sol';

/**
 * @title IMardukGate
 * @author Babylon Finance
 *
 * Interface for interacting with the Gate Guestlist NFT
 */
interface IMardukGate is IBabylonGate {
    /* ============ Functions ============ */

    function canAccessBeta(address _user) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 wad) external;
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

    function setMinTradeAmount(address _asset, uint256 _minAmount) external;

    function setTradeSlippage(uint256 _tradeSlippage) external;

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

pragma solidity 0.7.6;
pragma abicoder v2;

import '@openzeppelin/contracts/proxy/Proxy.sol';

import './VTableBeacon.sol';

/**
 * @title VTableBeaconProxy
 */
contract VTableBeaconProxy is Proxy {
    VTableBeacon public immutable beacon;

    constructor(VTableBeacon _beacon) {
        beacon = _beacon;
    }

    function _implementation() internal view virtual override returns (address module) {
        return beacon.implementation(msg.sig);
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.7.6;
pragma abicoder v2;

import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';

/**
 * @title VTableBeacon
 * @notice Redirects calls to an implementation based on the method signature
 */
contract VTableBeacon is Ownable {
    struct ModuleDefinition {
        address implementation;
        bytes4[] selectors;
    }

    bytes4 private constant _FALLBACK_SIGN = 0xffffffff;

    // Mapping of methods signatures to their implementations
    mapping(bytes4 => address) public delegates;

    event VTableUpdate(bytes4 indexed selector, address oldImplementation, address newImplementation);

    function implementation(bytes4 _selector) external view virtual returns (address module) {
        module = delegates[_selector];
        if (module != address(0)) return module;

        module = delegates[_FALLBACK_SIGN];
        if (module != address(0)) return module;

        revert('VTableBeacon: No implementation found');
    }

    /**
     * @dev Updates the vtable
     */
    function updateVTable(ModuleDefinition[] calldata modules) external onlyOwner {
        for (uint256 i = 0; i < modules.length; ++i) {
            ModuleDefinition memory module = modules[i];
            for (uint256 j = 0; j < module.selectors.length; ++j) {
                bytes4 selector = module.selectors[j];
                emit VTableUpdate(selector, delegates[selector], module.implementation);
                delegates[selector] = module.implementation;
            }
        }
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.7.6;

import {IBabController} from '../interfaces/IBabController.sol';
import {TimeLockRegistry} from './TimeLockRegistry.sol';
import {IRewardsDistributor} from '../interfaces/IRewardsDistributor.sol';
import {VoteToken} from './VoteToken.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {Errors, _require} from '../lib/BabylonErrors.sol';
import {LowGasSafeMath} from '../lib/LowGasSafeMath.sol';
import {IBabController} from '../interfaces/IBabController.sol';

/**
 * @title TimeLockedToken
 * @notice Time Locked ERC20 Token
 * @author Babylon Finance
 * @dev Contract which gives the ability to time-lock tokens specially for vesting purposes usage
 *
 * By overriding the balanceOf() and transfer() functions in ERC20,
 * an account can show its full, post-distribution balance and use it for voting power
 * but only transfer or spend up to an allowed amount
 *
 * A portion of previously non-spendable tokens are allowed to be transferred
 * along the time depending on each vesting conditions, and after all epochs have passed, the full
 * account balance is unlocked. In case on non-completion vesting period, only the Time Lock Registry can cancel
 * the delivery of the pending tokens and only can cancel the remaining locked ones.
 */

abstract contract TimeLockedToken is VoteToken {
    using LowGasSafeMath for uint256;

    /* ============ Events ============ */

    /// @notice An event that emitted when a new lockout ocurr
    event NewLockout(
        address account,
        uint256 tokenslocked,
        bool isTeamOrAdvisor,
        uint256 startingVesting,
        uint256 endingVesting
    );

    /// @notice An event that emitted when a new Time Lock is registered
    event NewTimeLockRegistration(address previousAddress, address newAddress);

    /// @notice An event that emitted when a new Rewards Distributor is registered
    event NewRewardsDistributorRegistration(address previousAddress, address newAddress);

    /// @notice An event that emitted when a cancellation of Lock tokens is registered
    event Cancel(address account, uint256 amount);

    /// @notice An event that emitted when a claim of tokens are registered
    event Claim(address _receiver, uint256 amount);

    /// @notice An event that emitted when a lockedBalance query is done
    event LockedBalance(address _account, uint256 amount);

    /* ============ Modifiers ============ */

    modifier onlyTimeLockRegistry() {
        require(
            msg.sender == address(timeLockRegistry),
            'TimeLockedToken:: onlyTimeLockRegistry: can only be executed by TimeLockRegistry'
        );
        _;
    }

    modifier onlyTimeLockOwner() {
        if (address(timeLockRegistry) != address(0)) {
            require(
                msg.sender == Ownable(timeLockRegistry).owner(),
                'TimeLockedToken:: onlyTimeLockOwner: can only be executed by the owner of TimeLockRegistry'
            );
        }
        _;
    }
    modifier onlyUnpaused() {
        // Do not execute if Globally or individually paused
        _require(!IBabController(controller).isPaused(address(this)), Errors.ONLY_UNPAUSED);
        _;
    }

    /* ============ State Variables ============ */

    // represents total distribution for locked balances
    mapping(address => uint256) distribution;

    /// @notice The profile of each token owner under its particular vesting conditions
    /**
     * @param team Indicates whether or not is a Team member or Advisor (true = team member/advisor, false = private investor)
     * @param vestingBegin When the vesting begins for such token owner
     * @param vestingEnd When the vesting ends for such token owner
     * @param lastClaim When the last claim was done
     */
    struct VestedToken {
        bool teamOrAdvisor;
        uint256 vestingBegin;
        uint256 vestingEnd;
        uint256 lastClaim;
    }

    /// @notice A record of token owners under vesting conditions for each account, by index
    mapping(address => VestedToken) public vestedToken;

    // address of Time Lock Registry contract
    IBabController public controller;

    // address of Time Lock Registry contract
    TimeLockRegistry public timeLockRegistry;

    // address of Rewards Distriburor contract
    IRewardsDistributor public rewardsDistributor;

    // Enable Transfer of ERC20 BABL Tokens
    // Only Minting or transfers from/to TimeLockRegistry and Rewards Distributor can transfer tokens until the protocol is fully decentralized
    bool private tokenTransfersEnabled;
    bool private tokenTransfersWereDisabled;

    /* ============ Functions ============ */

    /* ============ Constructor ============ */

    constructor(string memory _name, string memory _symbol) VoteToken(_name, _symbol) {
        tokenTransfersEnabled = true;
    }

    /* ============ External Functions ============ */

    /* ===========  Token related Gov Functions ====== */

    /**
     * PRIVILEGED GOVERNANCE FUNCTION. Disables transfers of ERC20 BABL Tokens
     */
    function disableTokensTransfers() external onlyOwner {
        require(!tokenTransfersWereDisabled, 'BABL must flow');
        tokenTransfersEnabled = false;
        tokenTransfersWereDisabled = true;
    }

    /**
     * PRIVILEGED GOVERNANCE FUNCTION. Allows transfers of ERC20 BABL Tokens
     * Can only happen after the protocol is fully decentralized.
     */
    function enableTokensTransfers() external onlyOwner {
        tokenTransfersEnabled = true;
    }

    /**
     * PRIVILEGED GOVERNANCE FUNCTION. Set the Time Lock Registry contract to control token vesting conditions
     *
     * @notice Set the Time Lock Registry contract to control token vesting conditions
     * @param newTimeLockRegistry Address of TimeLockRegistry contract
     */
    function setTimeLockRegistry(TimeLockRegistry newTimeLockRegistry) external onlyTimeLockOwner returns (bool) {
        require(address(newTimeLockRegistry) != address(0), 'cannot be zero address');
        require(address(newTimeLockRegistry) != address(this), 'cannot be this contract');
        require(address(newTimeLockRegistry) != address(timeLockRegistry), 'must be new TimeLockRegistry');
        emit NewTimeLockRegistration(address(timeLockRegistry), address(newTimeLockRegistry));

        timeLockRegistry = newTimeLockRegistry;

        return true;
    }

    /**
     * PRIVILEGED GOVERNANCE FUNCTION. Set the Rewards Distributor contract to control either BABL Mining or profit rewards
     *
     * @notice Set the Rewards Distriburor contract to control both types of rewards (profit and BABL Mining program)
     * @param newRewardsDistributor Address of Rewards Distributor contract
     */
    function setRewardsDistributor(IRewardsDistributor newRewardsDistributor) external onlyOwner returns (bool) {
        require(address(newRewardsDistributor) != address(0), 'cannot be zero address');
        require(address(newRewardsDistributor) != address(this), 'cannot be this contract');
        require(address(newRewardsDistributor) != address(rewardsDistributor), 'must be new Rewards Distributor');
        emit NewRewardsDistributorRegistration(address(rewardsDistributor), address(newRewardsDistributor));

        rewardsDistributor = newRewardsDistributor;

        return true;
    }

    /**
     * PRIVILEGED GOVERNANCE FUNCTION. Register new token lockup conditions for vested tokens defined only by Time Lock Registry
     *
     * @notice Tokens are completely delivered during the registration however lockup conditions apply for vested tokens
     * locking them according to the distribution epoch periods and the type of recipient (Team, Advisor, Investor)
     * Emits a transfer event showing a transfer to the recipient
     * Only the registry can call this function
     * @param _receiver Address to receive the tokens
     * @param _amount Tokens to be transferred
     * @param _profile True if is a Team Member or Advisor
     * @param _vestingBegin Unix Time when the vesting for that particular address
     * @param _vestingEnd Unix Time when the vesting for that particular address
     * @param _lastClaim Unix Time when the claim was done from that particular address
     *
     */
    function registerLockup(
        address _receiver,
        uint256 _amount,
        bool _profile,
        uint256 _vestingBegin,
        uint256 _vestingEnd,
        uint256 _lastClaim
    ) external onlyTimeLockRegistry returns (bool) {
        require(balanceOf(msg.sender) >= _amount, 'insufficient balance');
        require(_receiver != address(0), 'cannot be zero address');
        require(_receiver != address(this), 'cannot be this contract');
        require(_receiver != address(timeLockRegistry), 'cannot be the TimeLockRegistry contract itself');
        require(_receiver != msg.sender, 'the owner cannot lockup itself');

        // update amount of locked distribution
        distribution[_receiver] = distribution[_receiver].add(_amount);

        VestedToken storage newVestedToken = vestedToken[_receiver];

        newVestedToken.teamOrAdvisor = _profile;
        newVestedToken.vestingBegin = _vestingBegin;
        newVestedToken.vestingEnd = _vestingEnd;
        newVestedToken.lastClaim = _lastClaim;

        // transfer tokens to the recipient
        _transfer(msg.sender, _receiver, _amount);
        emit NewLockout(_receiver, _amount, _profile, _vestingBegin, _vestingEnd);

        return true;
    }

    /**
     * PRIVILEGED GOVERNANCE FUNCTION. Cancel and remove locked tokens due to non-completion of vesting period
     * applied only by Time Lock Registry and specifically to Team or Advisors as it does not apply to investors.
     *
     * @dev Cancel distribution registration
     * @param lockedAccount that should have its still locked distribution removed due to non-completion of its vesting period
     */
    function cancelVestedTokens(address lockedAccount) external onlyTimeLockRegistry returns (uint256) {
        return _cancelVestedTokensFromTimeLock(lockedAccount);
    }

    /**
     * GOVERNANCE FUNCTION. Each token owner can claim its own specific tokens with its own specific vesting conditions from the Time Lock Registry
     *
     * @dev Claim msg.sender tokens (if any available in the registry)
     */
    function claimMyTokens() external {
        // claim msg.sender tokens from timeLockRegistry
        uint256 amount = timeLockRegistry.claim(msg.sender);
        // After a proper claim, locked tokens of Team and Advisors profiles are under restricted special vesting conditions so they automatic grant
        // rights to the Time Lock Registry to only retire locked tokens if non-compliance vesting conditions take places along the vesting periods.
        // It does not apply to Investors under vesting (their locked tokens cannot be removed).
        if (vestedToken[msg.sender].teamOrAdvisor == true) {
            approve(address(timeLockRegistry), amount);
        }
        // emit claim event
        emit Claim(msg.sender, amount);
    }

    /**
     * GOVERNANCE FUNCTION. Get unlocked balance for an account
     *
     * @notice Get unlocked balance for an account
     * @param account Account to check
     * @return Amount that is unlocked and available eg. to transfer
     */
    function unlockedBalance(address account) public returns (uint256) {
        // totalBalance - lockedBalance
        return balanceOf(account).sub(lockedBalance(account));
    }

    /**
     * GOVERNANCE FUNCTION. View the locked balance for an account
     *
     * @notice View locked balance for an account
     * @param account Account to check
     * @return Amount locked in the time of checking
     */

    function viewLockedBalance(address account) public view returns (uint256) {
        // distribution of locked tokens
        // get amount from distributions

        uint256 amount = distribution[account];
        uint256 lockedAmount = amount;

        // Team and investors cannot transfer tokens in the first year
        if (vestedToken[account].vestingBegin.add(365 days) > block.timestamp && amount != 0) {
            return lockedAmount;
        }

        // in case of vesting has passed, all tokens are now available, if no vesting lock is 0 as well
        if (block.timestamp >= vestedToken[account].vestingEnd || amount == 0) {
            lockedAmount = 0;
        } else if (amount != 0) {
            // in case of still under vesting period, locked tokens are recalculated
            lockedAmount = amount.mul(vestedToken[account].vestingEnd.sub(block.timestamp)).div(
                vestedToken[account].vestingEnd.sub(vestedToken[account].vestingBegin)
            );
        }
        return lockedAmount;
    }

    /**
     * GOVERNANCE FUNCTION. Get locked balance for an account
     *
     * @notice Get locked balance for an account
     * @param account Account to check
     * @return Amount locked in the time of checking
     */
    function lockedBalance(address account) public returns (uint256) {
        // get amount from distributions locked tokens (if any)
        uint256 lockedAmount = viewLockedBalance(account);
        // in case of vesting has passed, all tokens are now available so we set mapping to 0 only for accounts under vesting
        if (
            block.timestamp >= vestedToken[account].vestingEnd &&
            msg.sender == account &&
            lockedAmount == 0 &&
            vestedToken[account].vestingEnd != 0
        ) {
            delete distribution[account];
        }
        emit LockedBalance(account, lockedAmount);
        return lockedAmount;
    }

    /**
     * PUBLIC FUNCTION. Get the address of Time Lock Registry
     *
     * @notice Get the address of Time Lock Registry
     * @return Address of the Time Lock Registry
     */
    function getTimeLockRegistry() external view returns (address) {
        return address(timeLockRegistry);
    }

    /**
     * PRIVILEGED GOVERNANCE FUNCTION. Override the Approval of allowances of ERC20 with special conditions for vesting
     *
     * @notice Override of "Approve" function to allow the `spender` to transfer up to `amount` from `src`
     * @dev This will overwrite the approval amount for `spender` except in the case of spender is Time Lock Registry
     * and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
     * @param spender The address of the account which may transfer tokens
     * @param rawAmount The number of tokens that are approved (2^256-1 means infinite)
     * @return Whether or not the approval succeeded
     */
    function approve(address spender, uint256 rawAmount) public override nonReentrant returns (bool) {
        require(spender != address(0), 'TimeLockedToken::approve: spender cannot be zero address');
        require(spender != msg.sender, 'TimeLockedToken::approve: spender cannot be the msg.sender');

        uint96 amount;
        if (rawAmount == uint256(-1)) {
            amount = uint96(-1);
        } else {
            amount = safe96(rawAmount, 'TimeLockedToken::approve: amount exceeds 96 bits');
        }

        // There is no option to decreaseAllowance to timeLockRegistry in case of vested tokens
        if ((spender == address(timeLockRegistry)) && (amount < allowance(msg.sender, address(timeLockRegistry)))) {
            amount = safe96(
                allowance(msg.sender, address(timeLockRegistry)),
                'TimeLockedToken::approve: cannot decrease allowance to timelockregistry'
            );
        }
        _approve(msg.sender, spender, amount);
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /**
     * PRIVILEGED GOVERNANCE FUNCTION. Override the Increase of allowances of ERC20 with special conditions for vesting
     *
     * @notice Atomically increases the allowance granted to `spender` by the caller.
     *
     * @dev This is an override with respect to the fulfillment of vesting conditions along the way
     * However an user can increase allowance many times, it will never be able to transfer locked tokens during vesting period
     * @return Whether or not the increaseAllowance succeeded
     */
    function increaseAllowance(address spender, uint256 addedValue) public override nonReentrant returns (bool) {
        require(
            unlockedBalance(msg.sender) >= allowance(msg.sender, spender).add(addedValue) ||
                spender == address(timeLockRegistry),
            'TimeLockedToken::increaseAllowance:Not enough unlocked tokens'
        );
        require(spender != address(0), 'TimeLockedToken::increaseAllowance:Spender cannot be zero address');
        require(spender != msg.sender, 'TimeLockedToken::increaseAllowance:Spender cannot be the msg.sender');
        _approve(msg.sender, spender, allowance(msg.sender, spender).add(addedValue));
        return true;
    }

    /**
     * PRIVILEGED GOVERNANCE FUNCTION. Override the decrease of allowances of ERC20 with special conditions for vesting
     *
     * @notice Atomically decrease the allowance granted to `spender` by the caller.
     *
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     * This is an override with respect to the fulfillment of vesting conditions along the way
     * An user cannot decrease the allowance to the Time Lock Registry who is in charge of vesting conditions
     * @return Whether or not the decreaseAllowance succeeded
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public override nonReentrant returns (bool) {
        require(spender != address(0), 'TimeLockedToken::decreaseAllowance:Spender cannot be zero address');
        require(spender != msg.sender, 'TimeLockedToken::decreaseAllowance:Spender cannot be the msg.sender');
        require(
            allowance(msg.sender, spender) >= subtractedValue,
            'TimeLockedToken::decreaseAllowance:Underflow condition'
        );

        // There is no option to decreaseAllowance to timeLockRegistry in case of vested tokens
        require(
            address(spender) != address(timeLockRegistry),
            'TimeLockedToken::decreaseAllowance:cannot decrease allowance to timeLockRegistry'
        );

        _approve(msg.sender, spender, allowance(msg.sender, spender).sub(subtractedValue));
        return true;
    }

    /* ============ Internal Only Function ============ */

    /**
     * PRIVILEGED GOVERNANCE FUNCTION. Override the _transfer of ERC20 BABL tokens only allowing the transfer of unlocked tokens
     *
     * @dev Transfer function which includes only unlocked tokens
     * Locked tokens can always be transfered back to the returns address
     * Transferring to owner allows re-issuance of funds through registry
     *
     * @param _from The address to send tokens from
     * @param _to The address that will receive the tokens
     * @param _value The amount of tokens to be transferred
     */
    function _transfer(
        address _from,
        address _to,
        uint256 _value
    ) internal override onlyUnpaused {
        require(_from != address(0), 'TimeLockedToken:: _transfer: cannot transfer from the zero address');
        require(_to != address(0), 'TimeLockedToken:: _transfer: cannot transfer to the zero address');
        require(
            _to != address(this),
            'TimeLockedToken:: _transfer: do not transfer tokens to the token contract itself'
        );

        require(balanceOf(_from) >= _value, 'TimeLockedToken:: _transfer: insufficient balance');

        // check if enough unlocked balance to transfer
        require(unlockedBalance(_from) >= _value, 'TimeLockedToken:: _transfer: attempting to transfer locked funds');
        super._transfer(_from, _to, _value);
        // voting power
        _moveDelegates(
            delegates[_from],
            delegates[_to],
            safe96(_value, 'TimeLockedToken:: _transfer: uint96 overflow')
        );
    }

    /**
     * PRIVILEGED GOVERNANCE FUNCTION. Disable BABL token transfer until certain conditions are met
     *
     * @dev Override the _beforeTokenTransfer of ERC20 BABL tokens until certain conditions are met:
     * Only allowing minting or transfers from Time Lock Registry and Rewards Distributor until transfers are allowed in the controller
     * Transferring to owner allows re-issuance of funds through registry
     *
     * @param _from The address to send tokens from
     * @param _to The address that will receive the tokens
     * @param _value The amount of tokens to be transferred
     */

    // Disable garden token transfers. Allow minting and burning.
    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _value
    ) internal virtual override {
        super._beforeTokenTransfer(_from, _to, _value);
        _require(
            _from == address(0) ||
                _from == address(timeLockRegistry) ||
                _from == address(rewardsDistributor) ||
                _to == address(timeLockRegistry) ||
                tokenTransfersEnabled,
            Errors.BABL_TRANSFERS_DISABLED
        );
    }

    /**
     * PRIVILEGED GOVERNANCE FUNCTION. Cancel and remove locked tokens due to non-completion of  vesting period
     * applied only by Time Lock Registry and specifically to Team or Advisors
     *
     * @dev Cancel distribution registration
     * @param lockedAccount that should have its still locked distribution removed due to non-completion of its vesting period
     */
    function _cancelVestedTokensFromTimeLock(address lockedAccount) internal onlyTimeLockRegistry returns (uint256) {
        require(distribution[lockedAccount] != 0, 'TimeLockedToken::cancelTokens:Not registered');

        // get an update on locked amount from distributions at this precise moment
        uint256 loosingAmount = lockedBalance(lockedAccount);

        require(loosingAmount > 0, 'TimeLockedToken::cancelTokens:There are no more locked tokens');
        require(
            vestedToken[lockedAccount].teamOrAdvisor == true,
            'TimeLockedToken::cancelTokens:cannot cancel locked tokens to Investors'
        );

        // set distribution mapping to 0
        delete distribution[lockedAccount];

        // set tokenVested mapping to 0
        delete vestedToken[lockedAccount];

        // transfer only locked tokens back to TimeLockRegistry Owner (msg.sender)
        require(
            transferFrom(lockedAccount, address(timeLockRegistry), loosingAmount),
            'TimeLockedToken::cancelTokens:Transfer failed'
        );

        // emit cancel event
        emit Cancel(lockedAccount, loosingAmount);

        return loosingAmount;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

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
library SafeMathUpgradeable {
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
pragma experimental ABIEncoderV2;
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {Address} from '@openzeppelin/contracts/utils/Address.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import {TimeLockedToken} from './TimeLockedToken.sol';
import {AddressArrayUtils} from '../lib/AddressArrayUtils.sol';

import {LowGasSafeMath} from '../lib/LowGasSafeMath.sol';

/**
 * @title TimeLockRegistry
 * @notice Register Lockups for TimeLocked ERC20 Token BABL (e.g. vesting)
 * @author Babylon Finance
 * @dev This contract allows owner to register distributions for a TimeLockedToken
 *
 * To register a distribution, register method should be called by the owner.
 * claim() should be called only by the BABL Token smartcontract (modifier onlyBABLToken)
 *  when any account registered to receive tokens make its own claim
 * If case of a mistake, owner can cancel registration before the claim is done by the account
 *
 * Note this contract address must be setup in the TimeLockedToken's contract pointing
 * to interact with (e.g. setTimeLockRegistry() function)
 */

contract TimeLockRegistry is Ownable {
    using LowGasSafeMath for uint256;
    using Address for address;
    using AddressArrayUtils for address[];

    /* ============ Events ============ */

    event Register(address receiver, uint256 distribution);
    event Cancel(address receiver, uint256 distribution);
    event Claim(address account, uint256 distribution);

    /* ============ Modifiers ============ */

    modifier onlyBABLToken() {
        require(msg.sender == address(token), 'only BABL Token');
        _;
    }

    /* ============ State Variables ============ */

    // time locked token
    TimeLockedToken public token;

    /**
     * @notice The profile of each token owner under vesting conditions and its special conditions
     * @param receiver Account being registered
     * @param investorType Indicates whether or not is a Team member (true = team member / advisor, false = private investor)
     * @param vestingStarting Date When the vesting begins for such token owner
     * @param distribution Tokens amount that receiver is due to get
     */
    struct Registration {
        address receiver;
        uint256 distribution;
        bool investorType;
        uint256 vestingStartingDate;
    }

    /**
     * @notice The profile of each token owner under vesting conditions and its special conditions
     * @param team Indicates whether or not is a Team member (true = team member / advisor, false = private investor)
     * @param vestingBegin When the vesting begins for such token owner
     * @param vestingEnd When the vesting ends for such token owner
     * @param lastClaim When the last claim was done
     */
    struct TokenVested {
        bool team;
        bool cliff;
        uint256 vestingBegin;
        uint256 vestingEnd;
        uint256 lastClaim;
    }

    /// @notice A record of token owners under vesting conditions for each account, by index
    mapping(address => TokenVested) public tokenVested;

    // mapping from token owners under vesting conditions to BABL due amount (e.g. SAFT addresses, team members, advisors)
    mapping(address => uint256) public registeredDistributions;

    // array of all registrations
    address[] public registrations;

    // total amount of tokens registered
    uint256 public totalTokens;

    // vesting for Team Members
    uint256 private constant teamVesting = 365 days * 4;

    // vesting for Investors and Advisors
    uint256 private constant investorVesting = 365 days * 3;

    /* ============ Functions ============ */

    /* ============ Constructor ============ */

    /**
     * @notice Construct a new Time Lock Registry and gives ownership to sender
     * @param _token TimeLockedToken contract to use in this registry
     */
    constructor(TimeLockedToken _token) {
        token = _token;
    }

    /* ============ External Functions ============ */

    /* ============ External Getter Functions ============ */

    /**
     * Gets registrations
     *
     * @return  address[]        Returns list of registrations
     */

    function getRegistrations() external view returns (address[] memory) {
        return registrations;
    }

    /* ===========  Token related Gov Functions ====== */

    /**
     * PRIVILEGED GOVERNANCE FUNCTION
     *
     * @notice Register multiple investors/team in a batch
     * @param _registrations Registrations to process
     */
    function registerBatch(Registration[] memory _registrations) external onlyOwner {
        for (uint256 i = 0; i < _registrations.length; i++) {
            register(
                _registrations[i].receiver,
                _registrations[i].distribution,
                _registrations[i].investorType,
                _registrations[i].vestingStartingDate
            );
        }
    }

    /**
     * PRIVILEGED GOVERNANCE FUNCTION
     *
     * @notice Register new account under vesting conditions (Team, Advisors, Investors e.g. SAFT purchaser)
     * @param receiver Address belonging vesting conditions
     * @param distribution Tokens amount that receiver is due to get
     */
    function register(
        address receiver,
        uint256 distribution,
        bool investorType,
        uint256 vestingStartingDate
    ) public onlyOwner {
        require(receiver != address(0), 'TimeLockRegistry::register: cannot register the zero address');
        require(
            receiver != address(this),
            'TimeLockRegistry::register: Time Lock Registry contract cannot be an investor'
        );
        require(distribution != 0, 'TimeLockRegistry::register: Distribution = 0');
        require(
            registeredDistributions[receiver] == 0,
            'TimeLockRegistry::register:Distribution for this address is already registered'
        );
        require(vestingStartingDate >= 1614553200, 'Cannot register earlier than March 2021'); // 1614553200 is UNIX TIME of 2021 March the 1st
        require(
            vestingStartingDate <= block.timestamp.add(30 days),
            'Cannot register more than 30 days ahead in the future'
        );
        require(totalTokens.add(distribution) <= IERC20(token).balanceOf(address(this)), 'Not enough tokens');

        totalTokens = totalTokens.add(distribution);
        // register distribution
        registeredDistributions[receiver] = distribution;
        registrations.push(receiver);

        // register token vested conditions
        TokenVested storage newTokenVested = tokenVested[receiver];
        newTokenVested.team = investorType;
        newTokenVested.vestingBegin = vestingStartingDate;

        if (newTokenVested.team == true) {
            newTokenVested.vestingEnd = vestingStartingDate.add(teamVesting);
        } else {
            newTokenVested.vestingEnd = vestingStartingDate.add(investorVesting);
        }
        newTokenVested.lastClaim = vestingStartingDate;

        tokenVested[receiver] = newTokenVested;

        // emit register event
        emit Register(receiver, distribution);
    }

    /**
     * PRIVILEGED GOVERNANCE FUNCTION. Cancel distribution registration in case of mistake and before a claim is done
     *
     * @notice Cancel distribution registration
     * @dev A claim has not to be done earlier
     * @param receiver Address that should have it's distribution removed
     * @return Whether or not it succeeded
     */
    function cancelRegistration(address receiver) external onlyOwner returns (bool) {
        require(registeredDistributions[receiver] != 0, 'Not registered');

        // get amount from distributions
        uint256 amount = registeredDistributions[receiver];

        // set distribution mapping to 0
        delete registeredDistributions[receiver];

        // set tokenVested mapping to 0
        delete tokenVested[receiver];

        // remove from the list of all registrations
        registrations.remove(receiver);

        // decrease total tokens
        totalTokens = totalTokens.sub(amount);

        // emit cancel event
        emit Cancel(receiver, amount);

        return true;
    }

    /**
     * PRIVILEGED GOVERNANCE FUNCTION. Cancel distribution registration in case of mistake and before a claim is done
     *
     * @notice Cancel already delivered tokens. It might only apply when non-completion of vesting period of Team members or Advisors
     * @dev An automatic override allowance is granted during the claim process
     * @param account Address that should have it's distribution removed
     * @return Whether or not it succeeded
     */
    function cancelDeliveredTokens(address account) external onlyOwner returns (bool) {
        uint256 loosingAmount = token.cancelVestedTokens(account);

        // emit cancel event
        emit Cancel(account, loosingAmount);
        return true;
    }

    /**
     * PRIVILEGED GOVERNANCE FUNCTION. Recover tokens in Time Lock Registry smartcontract address by the owner
     *
     * @notice Send tokens from smartcontract address to the owner.
     * It might only apply after a cancellation of vested tokens
     * @param amount Amount to be recovered by the owner of the Time Lock Registry smartcontract from its balance
     * @return Whether or not it succeeded
     */
    function transferToOwner(uint256 amount) external onlyOwner returns (bool) {
        SafeERC20.safeTransfer(token, msg.sender, amount);
        return true;
    }

    /**
     * PRIVILEGED GOVERNANCE FUNCTION. Claim locked tokens by the registered account
     *
     * @notice Claim tokens due amount.
     * @dev Claim is done by the user in the TimeLocked contract and the contract is the only allowed to call
     * this function on behalf of the user to make the claim
     * @return The amount of tokens registered and delivered after the claim
     */
    function claim(address _receiver) external onlyBABLToken returns (uint256) {
        require(registeredDistributions[_receiver] != 0, 'Not registered');

        // get amount from distributions
        uint256 amount = registeredDistributions[_receiver];
        TokenVested storage claimTokenVested = tokenVested[_receiver];

        claimTokenVested.lastClaim = block.timestamp;

        // set distribution mapping to 0
        delete registeredDistributions[_receiver];

        // decrease total tokens
        totalTokens = totalTokens.sub(amount);

        // register lockup in TimeLockedToken
        // this will transfer funds from this contract and lock them for sender
        token.registerLockup(
            _receiver,
            amount,
            claimTokenVested.team,
            claimTokenVested.vestingBegin,
            claimTokenVested.vestingEnd,
            claimTokenVested.lastClaim
        );

        // set tokenVested mapping to 0
        delete tokenVested[_receiver];

        // emit claim event
        emit Claim(_receiver, amount);

        return amount;
    }

    /* ============ Getter Functions ============ */

    function checkVesting(address address_)
        external
        view
        returns (
            bool team,
            uint256 start,
            uint256 end,
            uint256 last
        )
    {
        TokenVested storage checkTokenVested = tokenVested[address_];

        return (
            checkTokenVested.team,
            checkTokenVested.vestingBegin,
            checkTokenVested.vestingEnd,
            checkTokenVested.lastClaim
        );
    }

    function checkRegisteredDistribution(address address_) external view returns (uint256 amount) {
        return registeredDistributions[address_];
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.7.6;

import {ERC20} from '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import {IVoteToken} from '../interfaces/IVoteToken.sol';
import {ReentrancyGuard} from '@openzeppelin/contracts/utils/ReentrancyGuard.sol';
import {LowGasSafeMath} from '../lib/LowGasSafeMath.sol';
import {Context} from '@openzeppelin/contracts/utils/Context.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {Address} from '@openzeppelin/contracts/utils/Address.sol';

/**
 * @title VoteToken
 * @notice Custom token which tracks voting power for governance
 * @dev This is an abstraction of a fork of the Compound governance contract
 * VoteToken is used by BABL to allow tracking voting power
 * Checkpoints are created every time state is changed which record voting power
 * Inherits standard ERC20 behavior
 */

abstract contract VoteToken is Context, ERC20, Ownable, IVoteToken, ReentrancyGuard {
    using LowGasSafeMath for uint256;
    using Address for address;

    /* ============ Events ============ */

    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);
    event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);

    /* ============ Modifiers ============ */

    /* ============ State Variables ============ */

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH =
        keccak256('EIP712Domain(string name,uint256 chainId,address verifyingContract)');

    /// @notice The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATION_TYPEHASH =
        keccak256('Delegation(address delegatee,uint256 nonce,uint256 expiry)');

    /// @dev A record of votes checkpoints for each account, by index
    mapping(address => address) public delegates;

    /// @notice A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint32 fromBlock;
        uint96 votes;
    }

    /// @notice A record of votes checkpoints for each account, by index
    mapping(address => mapping(uint32 => Checkpoint)) public checkpoints;

    /// @notice The number of checkpoints for each account
    mapping(address => uint32) public numCheckpoints;

    /// @notice A record of states for signing / validating signatures
    mapping(address => uint256) public nonces;

    /* ============ Functions ============ */

    /* ============ Constructor ============ */

    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {}

    /* ============ External Functions ============ */

    /* ===========  Token related Gov Functions ====== */

    /**
     * PRIVILEGED GOVERNANCE FUNCTION. Delegating votes from msg.sender to delegatee
     *
     * @notice Delegate votes from `msg.sender` to `delegatee`
     * @param delegatee The address to delegate votes to
     */

    function delegate(address delegatee) external override {
        return _delegate(msg.sender, delegatee);
    }

    /**
     * PRIVILEGED GOVERNANCE FUNCTION. Delegate votes using signature to 'delegatee'
     *
     * @notice Delegates votes from signatory to `delegatee`
     * @param delegatee The address to delegate votes to
     * @param nonce The contract state required to match the signature
     * @param expiry The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */

    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s,
        bool prefix
    ) external override {
        address signatory;
        bytes32 domainSeparator =
            keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name())), getChainId(), address(this)));
        bytes32 structHash = keccak256(abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry));
        bytes32 digest = keccak256(abi.encodePacked('\x19\x01', domainSeparator, structHash));
        if (prefix) {
            bytes32 digestHash = keccak256(abi.encodePacked('\x19Ethereum Signed Message:\n32', digest));
            signatory = ecrecover(digestHash, v, r, s);
        } else {
            signatory = ecrecover(digest, v, r, s);
        }

        require(balanceOf(signatory) > 0, 'VoteToken::delegateBySig: invalid delegator');
        require(signatory != address(0), 'VoteToken::delegateBySig: invalid signature');
        require(nonce == nonces[signatory], 'VoteToken::delegateBySig: invalid nonce');
        nonces[signatory]++;
        require(block.timestamp <= expiry, 'VoteToken::delegateBySig: signature expired');
        return _delegate(signatory, delegatee);
    }

    /**
     * GOVERNANCE FUNCTION. Check Delegate votes using signature to 'delegatee'
     *
     * @notice Get current voting power for an account
     * @param account Account to get voting power for
     * @return Voting power for an account
     */
    function getCurrentVotes(address account) external view virtual override returns (uint96) {
        uint32 nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }

    /**
     * GOVERNANCE FUNCTION. Get voting power at a specific block for an account
     *
     * @param account Account to get voting power for
     * @param blockNumber Block to get voting power at
     * @return Voting power for an account at specific block
     */
    function getPriorVotes(address account, uint256 blockNumber) external view virtual override returns (uint96) {
        require(blockNumber < block.number, 'BABLToken::getPriorVotes: not yet determined');
        uint32 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            return checkpoints[account][nCheckpoints - 1].votes;
        }

        // Next check implicit zero balance
        if (checkpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = checkpoints[account][center];
            if (cp.fromBlock == blockNumber) {
                return cp.votes;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[account][lower].votes;
    }

    function getMyDelegatee() external view override returns (address) {
        return delegates[msg.sender];
    }

    function getDelegatee(address account) external view override returns (address) {
        return delegates[account];
    }

    function getCheckpoints(address account, uint32 id)
        external
        view
        override
        returns (uint32 fromBlock, uint96 votes)
    {
        Checkpoint storage getCheckpoint = checkpoints[account][id];
        return (getCheckpoint.fromBlock, getCheckpoint.votes);
    }

    function getNumberOfCheckpoints(address account) external view override returns (uint32) {
        return numCheckpoints[account];
    }

    /* ============ Internal Only Function ============ */

    /**
     * GOVERNANCE FUNCTION. Make a delegation
     *
     * @dev Internal function to delegate voting power to an account
     * @param delegator The address of the account delegating votes from
     * @param delegatee The address to delegate votes to
     */

    function _delegate(address delegator, address delegatee) internal {
        address currentDelegate = delegates[delegator];
        uint96 delegatorBalance = safe96(_balanceOf(delegator), 'VoteToken::_delegate: uint96 overflow');
        delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    function _balanceOf(address account) internal view virtual returns (uint256) {
        return balanceOf(account);
    }

    /**
     * GOVERNANCE FUNCTION. Move the delegates
     *
     * @dev Internal function to move delegates between accounts
     * @param srcRep The address of the account delegating votes from
     * @param dstRep The address of the account delegating votes to
     * @param amount The voting power to move
     */
    function _moveDelegates(
        address srcRep,
        address dstRep,
        uint96 amount
    ) internal {
        if (srcRep != dstRep && amount > 0) {
            // It must not revert but do nothing in cases of address(0) being part of the move
            // Sub voting amount to source in case it is not the zero address (e.g. transfers)
            if (srcRep != address(0)) {
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint96 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint96 srcRepNew = sub96(srcRepOld, amount, 'VoteToken::_moveDelegates: vote amount underflows');
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }
            if (dstRep != address(0)) {
                // Add it to destination in case it is not the zero address (e.g. any transfer of tokens or delegations except a first mint to a specific address)
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint96 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                uint96 dstRepNew = add96(dstRepOld, amount, 'VoteToken::_moveDelegates: vote amount overflows');
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    /**
     * GOVERNANCE FUNCTION. Internal function to write a checkpoint for voting power
     *
     * @dev internal function to write a checkpoint for voting power
     * @param delegatee The address of the account delegating votes to
     * @param nCheckpoints The num checkpoint
     * @param oldVotes The previous voting power
     * @param newVotes The new voting power
     */
    function _writeCheckpoint(
        address delegatee,
        uint32 nCheckpoints,
        uint96 oldVotes,
        uint96 newVotes
    ) internal {
        uint32 blockNumber = safe32(block.number, 'VoteToken::_writeCheckpoint: block number exceeds 32 bits');

        if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
            checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
        } else {
            checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
            numCheckpoints[delegatee] = nCheckpoints + 1;
        }

        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

    /**
     * INTERNAL FUNCTION. Internal function to convert from uint256 to uint32
     *
     * @dev internal function to convert from uint256 to uint32
     */
    function safe32(uint256 n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    /**
     * INTERNAL FUNCTION. Internal function to convert from uint256 to uint96
     *
     * @dev internal function to convert from uint256 to uint96
     */
    function safe96(uint256 n, string memory errorMessage) internal pure returns (uint96) {
        require(n < 2**96, errorMessage);
        return uint96(n);
    }

    /**
     * INTERNAL FUNCTION. Internal function to add two uint96 numbers
     *
     * @dev internal safe math function to add two uint96 numbers
     */
    function add96(
        uint96 a,
        uint96 b,
        string memory errorMessage
    ) internal pure returns (uint96) {
        uint96 c = a + b;
        require(c >= a, errorMessage);
        return c;
    }

    /**
     * INTERNAL FUNCTION. Internal function to subtract two uint96 numbers
     *
     * @dev internal safe math function to subtract two uint96 numbers
     */
    function sub96(
        uint96 a,
        uint96 b,
        string memory errorMessage
    ) internal pure returns (uint96) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * INTERNAL FUNCTION. Internal function to get chain ID
     *
     * @dev internal function to get chain ID
     */
    function getChainId() internal pure returns (uint256) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";
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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
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

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.7.6;

/**
 * @title IIntegration
 * @author Babylon Finance
 *
 * Interface for protocol integrations
 */
interface IIntegration {
    function getName() external view returns (string memory);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.7.6;

/**
 * @title IBabylonGate
 * @author Babylon Finance
 *
 * Interface for interacting with the Guestlists
 */
interface IBabylonGate {
    /* ============ Functions ============ */

    function setGardenAccess(
        address _user,
        address _garden,
        uint8 _permission
    ) external returns (uint256);

    function setCreatorPermissions(address _user, bool _canCreate) external returns (uint256);

    function grantGardenAccessBatch(
        address _garden,
        address[] calldata _users,
        uint8[] calldata _perms
    ) external returns (bool);

    function maxNumberOfInvites() external view returns (uint256);

    function setMaxNumberOfInvites(uint256 _maxNumberOfInvites) external;

    function grantCreatorsInBatch(address[] calldata _users, bool[] calldata _perms) external returns (bool);

    function canCreate(address _user) external view returns (bool);

    function canJoinAGarden(address _garden, address _user) external view returns (bool);

    function canVoteInAGarden(address _garden, address _user) external view returns (bool);

    function canAddStrategiesInAGarden(address _garden, address _user) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    /**
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback () external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive () external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {
    }
}