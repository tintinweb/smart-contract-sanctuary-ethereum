// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "../BaseStrategy.sol";

import "../../interfaces/euler/IEToken.sol";
import "../../interfaces/euler/IDToken.sol";
import "../../interfaces/euler/IMarkets.sol";
import "../../interfaces/euler/IExec.sol";
import "../../interfaces/euler/IEulerGeneralView.sol";
import "../../interfaces/euler/IEulDistributor.sol";
import "../../interfaces/ISwapRouter.sol";

contract IdleLeveragedEulerStrategy is BaseStrategy {
    using SafeERC20Upgradeable for IERC20Detailed;

    /// @notice Euler markets contract
    IMarkets internal constant EULER_MARKETS = IMarkets(0x3520d5a913427E6F0D6A83E07ccD4A4da316e4d3);

    /// @notice Euler general view contract
    IEulerGeneralView internal constant EULER_GENERAL_VIEW =
        IEulerGeneralView(0xACC25c4d40651676FEEd43a3467F3169e3E68e42);

    /// @notice Euler general Exec contract
    IExec internal constant EULER_EXEC = IExec(0x59828FdF7ee634AaaD3f58B19fDBa3b03E2D9d80);

    /// @notice Euler Governance Token
    IERC20Detailed internal constant EUL = IERC20Detailed(0xd9Fcd98c322942075A5C3860693e9f4f03AAE07b);

    uint256 internal constant EXP_SCALE = 1e18;

    uint256 internal constant ONE_FACTOR_SCALE = 1_000_000_000;

    uint256 internal constant CONFIG_FACTOR_SCALE = 4_000_000_000;

    uint256 internal constant SELF_COLLATERAL_FACTOR = 0.95 * 4_000_000_000;

    /// @notice Euler account id
    uint256 internal constant SUB_ACCOUNT_ID = 0;

    /// @notice EToken contract
    IEToken public eToken;

    /// @notice DToken contract
    IDToken public dToken;

    /// @notice target health score is defined as adjusted collateral divided by adjusted liability.
    /// @dev 18 decimals. 1 == 1e18. must be greater 1e18
    uint256 public targetHealthScore;

    /// @notice price used to mint tranche tokens if current tranche price < last harvest
    uint256 public mintPrice;

    /// @notice Eul reward distributor
    IEulDistributor public eulDistributor;

    /// @notice uniswap v3 router
    ISwapRouter public router;

    /// @notice uniswap v3 router path
    bytes public path;

    /// @notice address used to manage targetHealth
    address public rebalancer;

    event UpdateTargetHealthScore(uint256 oldHeathScore, uint256 newHeathScore);

    event UpdateEulDistributor(address oldEulDistributor, address newEulDistributor);

    event UpdateSwapRouter(address oldRouter, address newRouter);

    event UpdateRouterPath(bytes oldRouter, bytes _path);

    function initialize(
        address _euler,
        address _eToken,
        address _dToken,
        address _underlying,
        address _owner,
        address _eulDistributor,
        address _router,
        bytes memory _path,
        uint256 _targetHealthScore
    ) public initializer {
        _initialize(
            string(abi.encodePacked("Idle ", IERC20Detailed(_underlying).name(), " Euler Leverege Strategy")),
            string(abi.encodePacked("idleEulLev", IERC20Detailed(_underlying).symbol())),
            _underlying, 
            _owner
        );
        eToken = IEToken(_eToken);
        dToken = IDToken(_dToken);
        eulDistributor = IEulDistributor(_eulDistributor);
        router = ISwapRouter(_router);
        path = _path;
        targetHealthScore = _targetHealthScore;
        // This should be more than the Euler epoch period
        releaseBlocksPeriod = 108900; // ~15 days in blocks (counting 11.9 sec per block with PoS)
        mintPrice = oneToken;

        // Enter the collateral market (collateral's address, *not* the eToken address)
        EULER_MARKETS.enterMarket(SUB_ACCOUNT_ID, _underlying);

        underlyingToken.safeApprove(_euler, type(uint256).max);
    }

    /// @return _price net in underlyings of 1 strategyToken
    function price() public view override returns (uint256 _price) {
        uint256 _totalSupply = totalSupply();
        uint256 _tokenValue = eToken.balanceOfUnderlying(address(this)) - dToken.balanceOf(address(this));
        if (_totalSupply == 0) {
            _price = oneToken;
        } else {
            _price = ((_tokenValue - _lockedTokens()) * EXP_SCALE) / _totalSupply;
        }
    }

    function _setMintPrice() internal {
        uint256 _tokenValue = eToken.balanceOfUnderlying(address(this)) - dToken.balanceOf(address(this));
        // count all tokens as unlocked so price will be higher for mint (otherwise interest unlocked is stealed from others)
        mintPrice = (_tokenValue * EXP_SCALE) / totalSupply();
    }

    /// @param _amount amount of underlying to deposit
    function _deposit(uint256 _amount) internal override returns (uint256 amountUsed) {
        if (_amount == 0) {
            return 0;
        }
        IEToken _eToken = eToken;
        IERC20Detailed _underlyingToken = underlyingToken;
        uint256 balanceBefore = _underlyingToken.balanceOf(address(this));
        // get amount to deposit to retain a target health score
        uint256 amountToMint = getSelfAmountToMint(targetHealthScore, _amount);

        // some of the amount should be deposited to make the health score close to the target one.
        _eToken.deposit(SUB_ACCOUNT_ID, _amount);

        // self borrow
        if (amountToMint != 0) {
            _eToken.mint(SUB_ACCOUNT_ID, amountToMint);
        }

        amountUsed = balanceBefore - _underlyingToken.balanceOf(address(this));
    }

    function _redeemRewards(bytes calldata data) internal override returns (uint256[] memory rewards) {
        rewards = new uint256[](1);
        IEulDistributor _eulDistributor = eulDistributor;
        ISwapRouter _router = router;
        if (address(_eulDistributor) != address(0) && address(_router) != address(0) && data.length != 0) {
            (uint256 claimable, bytes32[] memory proof, uint256 minAmountOut) = abi.decode(
                data,
                (uint256, bytes32[], uint256)
            );

            if (claimable == 0) {
                return rewards;
            }
            // claim EUL by verifying a merkle root
            _eulDistributor.claim(address(this), address(EUL), claimable, proof, address(0));
            uint256 amountIn = EUL.balanceOf(address(this));

            // swap EUL for underlying
            EUL.safeApprove(address(_router), amountIn);
            _router.exactInput(
                ISwapRouter.ExactInputParams({
                    path: path,
                    recipient: address(this),
                    deadline: block.timestamp,
                    amountIn: amountIn,
                    amountOutMinimum: minAmountOut
                })
            );

            rewards[0] = underlyingToken.balanceOf(address(this));
        }
    }

    /// @notice redeem the rewards
    /// @return rewards amount of reward that is deposited to the ` strategy`
    ///         rewards[0] : mintedUnderlyings
    function redeemRewards(bytes calldata data)
        public
        override
        onlyIdleCDO
        returns (uint256[] memory rewards)
    {
        rewards = super.redeemRewards(data);
        _setMintPrice();
    }

    function _withdraw(uint256 _amountToWithdraw, address _destination)
        internal
        override
        returns (uint256 amountWithdrawn)
    {
        IERC20Detailed _underlyingToken = underlyingToken;
        IEToken _eToken = eToken;
        uint256 balanceBefore = _underlyingToken.balanceOf(address(this));
        uint256 amountToBurn = getSelfAmountToBurn(targetHealthScore, _amountToWithdraw);

        if (amountToBurn != 0) {
            // Pay off dToken liability with eTokens ("self-repay")
            _eToken.burn(SUB_ACCOUNT_ID, amountToBurn);
        }

        uint256 balanceInUnderlying = _eToken.balanceOfUnderlying(address(this));
        if (_amountToWithdraw > balanceInUnderlying) {
            _amountToWithdraw = balanceInUnderlying;
        }
        // withdraw underlying
        _eToken.withdraw(SUB_ACCOUNT_ID, _amountToWithdraw);

        amountWithdrawn = _underlyingToken.balanceOf(address(this)) - balanceBefore;
        _underlyingToken.safeTransfer(_destination, amountWithdrawn);
    }

    /// @dev Pay off dToken liability with eTokens ("self-repay") and depost the withdrawn underlying
    function deleverageManually(uint256 _targetHealthScore) external {
        require(msg.sender == owner() || msg.sender == rebalancer, '!AUTH');
        require(_targetHealthScore > EXP_SCALE || _targetHealthScore == 0, "!VALID");

        // set target health score
        targetHealthScore = _targetHealthScore;

        IEToken _eToken = eToken;
        if (_targetHealthScore == 0) {
            // deleverage all
            _eToken.burn(SUB_ACCOUNT_ID, dToken.balanceOf(address(this)));
        } else {
            uint256 amountToBurn = getSelfAmountToBurn(_targetHealthScore, 0);
            if (amountToBurn != 0) {
                _eToken.burn(SUB_ACCOUNT_ID, amountToBurn);
            }
        }
        _eToken.deposit(SUB_ACCOUNT_ID, underlyingToken.balanceOf(address(this)));
    }

    /// @dev Leverage position by setting target health score
    function leverageManually(uint256 _targetHealthScore) external {
        require(msg.sender == owner() || msg.sender == rebalancer, '!AUTH');
        require(_targetHealthScore > EXP_SCALE, "!VALID");
        // set target health score
        targetHealthScore = _targetHealthScore;

        IEToken _eToken = eToken;
        uint256 amountToMint = _getSelfAmount(_targetHealthScore, 0);
        if (amountToMint != 0) {
            _eToken.mint(SUB_ACCOUNT_ID, amountToMint);
        }
    }

    function setTargetHealthScore(uint256 _healthScore) external {
        require(msg.sender == owner() || msg.sender == rebalancer, '!AUTH');
        require(_healthScore > EXP_SCALE || _healthScore == 0, "strat/invalid-target-hs");

        uint256 _oldTargetHealthScore = targetHealthScore;
        targetHealthScore = _healthScore;

        emit UpdateTargetHealthScore(_oldTargetHealthScore, _healthScore);
    }

    function setEulDistributor(address _eulDistributor) external onlyOwner {
        address oldEulDistributor = address(eulDistributor);
        eulDistributor = IEulDistributor(_eulDistributor);

        emit UpdateEulDistributor(oldEulDistributor, _eulDistributor);
    }

    function setRebalancer(address _rebalancer) external onlyOwner {
        require(_rebalancer != address(0), '0');
        rebalancer = _rebalancer;
    }

    function setSwapRouter(address _router) external onlyOwner {
        address oldRouter = address(router);
        router = ISwapRouter(_router);

        emit UpdateSwapRouter(oldRouter, _router);
    }

    function setRouterPath(bytes calldata _path) external onlyOwner {
        bytes memory oldPath = path;
        path = _path;

        emit UpdateRouterPath(oldPath, _path);
    }

    /// @notice For example
    /// - deposit $1000 RBN
    /// - mint $10,00 RBN
    /// in the end this contract holds $11000 RBN deposits and $10,000 RBN debts.
    /// will have a health score of exactly 1.
    /// Changes in price of RBN will have no effect on a user's health score,
    /// because their collateral deposits rise and fall at the same rate as their debts.
    /// So, is a user at risk of liquidation? This depends on how much more interest they are
    /// paying on their debts than they are earning on their deposits.
    /// @dev
    /// Euler fi defines health score a little differently
    /// Health score = risk adjusted collateral / risk adjusted liabilities
    /// Collateral amount * collateral factor = risk adjusted collateral
    /// Borrow amount / borrow factor = risk adjusted liabilities
    /// ref: https://github.com/euler-xyz/euler-contracts/blob/0fade57d9ede7b010f943fa8ad3ad74b9c30e283/contracts/modules/RiskManager.sol#L314
    /// @param _targetHealthScore  health score 1.0 == 1e18
    /// @param _amount _amount to deposit or withdraw. _amount greater than zero means `deposit`. _amount less than zero means `withdraw`
    function _getSelfAmount(uint256 _targetHealthScore, int256 _amount) internal view returns (uint256 selfAmount) {
        // target health score has 1e18 decimals.
        require(_targetHealthScore > EXP_SCALE || _targetHealthScore == 0, "strat/invalid-target-hs");
        if (_targetHealthScore == 0) {
            // no leverage
            return 0;
        }

        // Calculate amount to `mint` or `burn` to maintain a target health score.
        // Let `h` denote the target health score we want to maintain.
        // Let `ac` denote the balance of collateral and `sc` denote the self-collateralized balance of collateral.
        // Let `fc` denote the collateral factor of a asset,
        // `fb` denote its borrow factor and `fs` denote the collateral factor of a self-collateralized asset (called self-collateralized factor).

        // Let `x` denote its newly added collateral by user and `xs` denote its newly added collateral with recursive borrowing/repay (`eToken.mint()` or `eToken.burn()`).
        // Heath score is:
        // h = {fc[ac + x + xs - (sc + xs)/fs] + sc + xs} / (sc + xs)

        // Resolve the equation for xs.
        // xs = {fc(ac + x) - (h + fc/fs - 1)sc} / {h + fc(1/fs -1) - 1}
        // Here, we define term1 := fc(ac + x) and term2 := (h + fc/fs - 1)sc.

        uint256 debtInUnderlying = dToken.balanceOf(address(this)); // liability in underlying `sc`

        uint256 cf; // underlying collateral factor
        // collateral balance in underlying
        // this is `a` which is the summation of usual collateral and self-borrowed collateral
        uint256 balanceInUnderlying;
        {
            // avoid stack too deep error
            IMarkets.AssetConfig memory config = EULER_MARKETS.underlyingToAssetConfig(token);
            cf = config.collateralFactor;
            balanceInUnderlying = IEToken(config.eTokenAddress).balanceOfUnderlying(address(this));
        }

        {
            int256 collateral = int256(balanceInUnderlying) + _amount; // `ac` + `x`
            require(collateral > 0, "strat/exceed-balance");

            uint256 term1 = ((cf * uint256(collateral))) / CONFIG_FACTOR_SCALE; // in underlying terms
            // health score must be normalized
            uint256 term2 = (((_targetHealthScore * ONE_FACTOR_SCALE) /
                EXP_SCALE +
                (cf * ONE_FACTOR_SCALE) /
                SELF_COLLATERAL_FACTOR -
                ONE_FACTOR_SCALE) * debtInUnderlying) / ONE_FACTOR_SCALE; // in underlying terms

            uint256 denominator = (_targetHealthScore * ONE_FACTOR_SCALE) /
                EXP_SCALE +
                (cf * ONE_FACTOR_SCALE) /
                SELF_COLLATERAL_FACTOR -
                (cf * ONE_FACTOR_SCALE) /
                CONFIG_FACTOR_SCALE -
                ONE_FACTOR_SCALE; // in ONE_FACTOR_SCALE terms

            // `selfAmount` := abs(xs) = abs(term1 - term2) / denominator.
            // when depositing, xs is greater than zero.
            // when withdrawing, xs is less than current debt and less than zero.
            if (term1 >= term2) {
                // when withdrawing, maximum value of xs is zero.
                if (_amount < 0) return 0;
                selfAmount = ((term1 - term2) * ONE_FACTOR_SCALE) / denominator;
            } else {
                // when depositing, minimum value of xs is zero.
                if (_amount > 0) return 0;
                selfAmount = ((term2 - term1) * ONE_FACTOR_SCALE) / denominator;
                if (selfAmount > debtInUnderlying) {
                    // maximum repayable value is current debt value.
                    selfAmount = debtInUnderlying;
                }
            }
        }
    }

    function getSelfAmountToMint(uint256 _targetHealthScore, uint256 _amount) public view returns (uint256) {
        return _getSelfAmount(_targetHealthScore, int256(_amount));
    }

    function getSelfAmountToBurn(uint256 _targetHealthScore, uint256 _amount) public view returns (uint256) {
        return _getSelfAmount(_targetHealthScore, -int256(_amount));
    }

    function getCurrentHealthScore() public view returns (uint256) {
        IRiskManager.LiquidityStatus memory status = EULER_EXEC.liquidity(address(this));
        // approximately equal to `eToken.balanceOfUnderlying(address(this))` divide by ` dToken.balanceOf(address(this))`
        if (status.liabilityValue == 0) {
            return 0;
        }
        return (status.collateralValue * EXP_SCALE) / status.liabilityValue;
    }

    function getCurrentLeverage() public view returns (uint256) {
        uint256 balanceInUnderlying = eToken.balanceOfUnderlying(address(this));
        uint256 debtInUnderlying = dToken.balanceOf(address(this));
        uint256 principal = balanceInUnderlying - debtInUnderlying;
        if (principal == 0) {
            return EXP_SCALE;
        }
        // leverage = debt / principal
        return debtInUnderlying * oneToken / principal;
    }

    /// @notice this should be empty as rewards are sold directly in the strategy and 
    /// `getRewardTokens` is used only in IdleCDO for selling rewards
    function getRewardTokens() external pure override returns (address[] memory) {
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "../interfaces/IIdleCDOStrategy.sol";
import "../interfaces/IERC20Detailed.sol";

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

abstract contract BaseStrategy is
    Initializable,
    OwnableUpgradeable,
    ERC20Upgradeable,
    ReentrancyGuardUpgradeable,
    IIdleCDOStrategy
{
    using SafeERC20Upgradeable for IERC20Detailed;

    uint256 private constant EXP_SCALE = 1e18;

    /// @notice one year, used to calculate the APR
    uint256 private constant YEAR = 365 days;

    /// @notice underlying token address (ex: DAI)
    address public override token;

    /// @notice strategy token address (ex: fDAI)
    address public override strategyToken;

    /// @notice decimals of the underlying asset
    uint256 public override tokenDecimals;

    /// @notice one underlying token
    uint256 public override oneToken;

    /// @notice underlying ERC20 token contract
    IERC20Detailed public underlyingToken;

    /// @notice address of the IdleCDO
    address public idleCDO;

    /// @notice total underlying tokens staked
    uint256 public totalTokensStaked;

    /// @notice total underlying tokens locked
    uint256 public totalTokensLocked;

    /// @notice time when last deposit/redeem was made, used for calculating the APR
    uint256 public lastIndexedTime;

    ///@dev packed into the same storage slot as lastApr and blocks period.
    /// @notice latest harvest
    uint128 public latestHarvestBlock;

    /// @notice latest saved apr
    uint96 internal lastApr;

    /// @notice harvested tokens release delay
    uint32 public releaseBlocksPeriod;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        token = address(1);
    }

    /// @notice can be only called once
    /// @param _name name of this strategy ERC20 tokens
    /// @param _symbol symbol of this strategy ERC20 tokens
    /// @param _token address of the underlying token
    function _initialize(
        string memory _name,
        string memory _symbol,
        address _token,
        address _owner
    ) internal initializer {
        OwnableUpgradeable.__Ownable_init();
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
        require(token == address(0), "Token is already initialized");

        //----- // -------//
        strategyToken = address(this);
        token = _token;
        underlyingToken = IERC20Detailed(token);
        tokenDecimals = underlyingToken.decimals();
        oneToken = 10**(tokenDecimals); // underlying decimals
        // note tokenized position has 18 decimals

        // Set basic parameters
        lastIndexedTime = block.timestamp;
        releaseBlocksPeriod = 6400;

        ERC20Upgradeable.__ERC20_init(_name, _symbol);
        //------//-------//

        transferOwnership(_owner);
    }

    /// @dev makes the actual deposit into the `strategy`
    /// @param _amount amount of tokens to deposit
    function _deposit(uint256 _amount) internal virtual returns (uint256 amountUsed);

    /// @dev makes the actual withdraw from the 'strategy'
    /// @return amountWithdrawn returns the amount withdrawn
    function _withdraw(uint256 _amountToWithdraw, address _destination)
        internal
        virtual
        returns (uint256 amountWithdrawn);

    /// @dev msg.sender should approve this contract first to spend `_amount` of `token`
    /// @param _amount amount of `token` to deposit
    /// @return shares strategyTokens minted
    function deposit(uint256 _amount) external override onlyIdleCDO returns (uint256 shares) {
        if (_amount != 0) {
            // Get current price
            uint256 _price = price();

            // Send tokens to the strategy
            IERC20Detailed(token).safeTransferFrom(msg.sender, address(this), _amount);

            // Calls our internal deposit function
            _amount = _deposit(_amount);

            // Adjust with actual staked amount
            if (_amount != 0) {
                totalTokensStaked += _amount;
            }

            // Mint shares
            shares = (_amount * EXP_SCALE) / _price;
            _mint(msg.sender, shares);
        }
    }

    /// @dev msg.sender should approve this contract first to spend `_amount` of `strategyToken`
    /// @param _shares amount of strategyTokens to redeem
    /// @return amountRedeemed  amount of underlyings redeemed
    function redeem(uint256 _shares) external override onlyIdleCDO returns (uint256 amountRedeemed) {
        if (_shares != 0) {
            amountRedeemed = _positionWithdraw(_shares, msg.sender, price(), 0);
        }
    }

    /// @notice Redeem Tokens
    /// @param _amount amount of underlying tokens to redeem
    /// @return amountRedeemed Amount of underlying tokens received
    function redeemUnderlying(uint256 _amount) external virtual onlyIdleCDO returns (uint256 amountRedeemed) {
        uint256 _price = price(); // in underlying terms
        uint256 _shares = (_amount * EXP_SCALE) / _price;
        if (_shares != 0) {
            amountRedeemed = _positionWithdraw(_shares, msg.sender, _price, 0);
        }
    }

    /// @dev msg.sender should approve this contract first to spend `_amount` of `strategyToken`
    /// @param _shares amount of strategyTokens to redeem
    /// @param _destination The destination to send the output to
    /// @param _underlyingPerShare The precomputed shares per underlying
    /// @param _minUnderlying The min amount of output to produce. useful for mannualy harvesting
    /// @return amountWithdrawn amount of underlyings redeemed
    function _positionWithdraw(
        uint256 _shares,
        address _destination,
        uint256 _underlyingPerShare,
        uint256 _minUnderlying
    ) internal returns (uint256 amountWithdrawn) {
        uint256 amountNeeded = (_shares * _underlyingPerShare) / EXP_SCALE;

        _burn(msg.sender, _shares);

        // Withdraw amount needed
        amountWithdrawn = _withdraw(amountNeeded, _destination);

        // Adjust with actual unstaked amount
        if (amountWithdrawn != 0) {
            totalTokensStaked -= amountWithdrawn;
        }

        // We revert if this call doesn't produce enough underlying
        // This security feature is useful in some edge cases
        require(amountWithdrawn >= _minUnderlying, "Not enough underlying");
    }

    /// @notice redeem the rewards
    /// @return rewards amount of reward that is deposited to the ` strategy`
    ///         rewards[0] : mintedUnderlyings
    function redeemRewards(bytes calldata data)
        public
        virtual
        onlyIdleCDO
        nonReentrant
        returns (uint256[] memory rewards)
    {
        rewards = _redeemRewards(data);
        uint256 mintedUnderlyings = rewards[0];
        if (mintedUnderlyings == 0) {
            return rewards;
        }

        // reinvest the generated/minted underlying to the the `strategy`
        uint256 underlyingsStaked = _reinvest(mintedUnderlyings);
        // save the block in which rewards are swapped and the amount
        latestHarvestBlock = uint128(block.number);
        totalTokensLocked = underlyingsStaked;
        totalTokensStaked += underlyingsStaked;

        // update the apr after claiming the rewards
        _updateApr(underlyingsStaked);
    }

    /// @dev reinvest underlyings` to the `strategy`
    ///      this method should be used in the `_redeemRewards` method
    ///      Ussually don't mint new shares.
    function _reinvest(uint256 underlyings) internal virtual returns (uint256 underlyingsStaked) {
        underlyingsStaked = _deposit(underlyings);
    }

    /// @return rewards rewards[0] : mintedUnderlying
    function _redeemRewards(bytes calldata data) internal virtual returns (uint256[] memory rewards);

    /// @notice update last saved apr
    /// @param _gain amount of underlying tokens to mint/redeem
    function _updateApr(uint256 _gain) internal {
        uint256 _totalSupply = totalSupply();
        uint256 timeIncrease = block.timestamp - lastIndexedTime;

        if (_totalSupply != 0 && timeIncrease != 0) {
            uint256 priceIncrease = (_gain * EXP_SCALE) / _totalSupply;
            // normalized to 1e18 decimals
            lastApr = uint96(
                priceIncrease * (YEAR / timeIncrease) * 100 * (10 ** (18 - tokenDecimals))
            ); // prettier-ignore
            lastIndexedTime = block.timestamp;
        }
    }

    /// @dev deprecated method
    /// @notice pull stkedAave
    function pullStkAAVE() external override returns (uint256 pulledAmount) {}

    /// @notice net price in underlyings of 1 strategyToken
    /// @return _price denominated in decimals of underlyings
    function price() public view virtual override returns (uint256 _price) {
        uint256 _totalSupply = totalSupply();

        if (_totalSupply == 0) {
            _price = oneToken;
        } else {
            _price = ((totalTokensStaked - _lockedTokens()) * EXP_SCALE) / _totalSupply;
        }
    }

    function _lockedTokens() internal view returns (uint256 _locked) {
        uint256 _totalLockedTokens = totalTokensLocked;
        uint256 _releaseBlocksPeriod = releaseBlocksPeriod;
        uint256 _blocksSinceLastHarvest = block.number - latestHarvestBlock;

        if (_totalLockedTokens != 0 && _blocksSinceLastHarvest < _releaseBlocksPeriod) {
            // progressively release harvested rewards
            _locked = (_totalLockedTokens * (_releaseBlocksPeriod - _blocksSinceLastHarvest)) / _releaseBlocksPeriod; // prettier-ignore
        }
    }

    function getApr() external view returns (uint256 apr) {
        apr = lastApr;
    }

    function setReleaseBlocksPeriod(uint32 _releaseBlocksPeriod) external onlyOwner {
        require(_releaseBlocksPeriod != 0, "IS_0");
        releaseBlocksPeriod = _releaseBlocksPeriod;
    }

    /// @notice This contract should not have funds at the end of each tx (except for stkAAVE), this method is just for leftovers
    /// @dev Emergency method
    /// @param _token address of the token to transfer
    /// @param value amount of `_token` to transfer
    /// @param _to receiver address
    function transferToken(
        address _token,
        uint256 value,
        address _to
    ) external onlyOwner nonReentrant {
        IERC20Detailed(_token).safeTransfer(_to, value);
    }

    /// @notice allow to update whitelisted address
    function setWhitelistedCDO(address _cdo) external onlyOwner {
        require(_cdo != address(0), "IS_0");
        idleCDO = _cdo;
    }

    /// @notice Modifier to make sure that caller os only the idleCDO contract
    modifier onlyIdleCDO() {
        require(idleCDO == msg.sender, "Only IdleCDO can call");
        _;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.10;

import "@openzeppelin/contracts/interfaces/IERC20.sol";

interface IEToken is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint256);

    /// @notice Transfer underlying tokens from sender to the Euler pool, and increase account's eTokens
    /// @param subAccountId 0 for primary, 1-255 for a sub-account
    /// @param amount In underlying units (use max uint256 for full underlying token balance)
    function deposit(uint256 subAccountId, uint256 amount) external;

    /// @notice Mint eTokens and a corresponding amount of dTokens ("self-borrow")
    /// @param subAccountId 0 for primary, 1-255 for a sub-account
    /// @param amount In underlying units
    function mint(uint256 subAccountId, uint256 amount) external;

    /// @notice Transfer underlying tokens from Euler pool to sender, and decrease account's eTokens
    /// @param subAccountId 0 for primary, 1-255 for a sub-account
    /// @param amount In underlying units (use max uint256 for full pool balance)
    function withdraw(uint256 subAccountId, uint256 amount) external;

    /// @notice Pay off dToken liability with eTokens ("self-repay")
    /// @param subAccountId 0 for primary, 1-255 for a sub-account
    /// @param amount In underlying units (use max uint256 to repay the debt in full or up to the available underlying balance)
    function burn(uint256 subAccountId, uint256 amount) external;

    /// @notice Balance of a particular account, in underlying units (increases as interest is earned)
    function balanceOfUnderlying(address account) external view returns (uint256);

    /// @notice Convert an eToken balance to an underlying amount, taking into account current exchange rate
    /// @param balance eToken balance, in internal book-keeping units (18 decimals)
    /// @return Amount in underlying units, (same decimals as underlying token)
    function convertBalanceToUnderlying(uint256 balance) external view returns (uint256);

    /// @notice Convert an underlying amount to an eToken balance, taking into account current exchange rate
    /// @param underlyingAmount Amount in underlying units (same decimals as underlying token)
    /// @return eToken balance, in internal book-keeping units (18 decimals)
    function convertUnderlyingToBalance(uint256 underlyingAmount) external view returns (uint256);

    /// @notice Sum of all balances, in underlying units (increases as interest is earned)
    function totalSupplyUnderlying() external view returns (uint256);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.10;

import "@openzeppelin/contracts/interfaces/IERC20.sol";

interface IDToken is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint256);

    /// @notice Transfer underlying tokens from the Euler pool to the sender, and increase sender's dTokens
    /// @param subAccountId 0 for primary, 1-255 for a sub-account
    /// @param amount In underlying units (use max uint256 for all available tokens)
    function borrow(uint256 subAccountId, uint256 amount) external;

    /// @notice Transfer underlying tokens from the sender to the Euler pool, and decrease sender's dTokens
    /// @param subAccountId 0 for primary, 1-255 for a sub-account
    /// @param amount In underlying units (use max uint256 for full debt owed)
    function repay(uint256 subAccountId, uint256 amount) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.10;

interface IMarkets {
    struct AssetConfig {
        address eTokenAddress;
        bool borrowIsolated;
        uint32 collateralFactor;
        uint32 borrowFactor;
        uint24 twapWindow;
    }

    /// @notice Given an underlying, lookup the associated DToken
    /// @param underlying Token address
    /// @return DToken address, or address(0) if not activated
    function underlyingToDToken(address underlying) external view returns (address);

    /// @notice Retrieves the current interest rate for an asset
    /// @param underlying Token address
    /// @return The interest rate in yield-per-second, scaled by 10**27
    function interestRate(address underlying) external view returns (int96);

    /// @notice Retrieves the reserve fee in effect for an asset
    /// @param underlying Token address
    /// @return Amount of interest that is redirected to the reserves, as a fraction scaled by RESERVE_FEE_SCALE (4e9)
    function reserveFee(address underlying) external view returns (uint32);

    function enterMarket(uint256 subAccountId, address newMarket) external;

    function underlyingToAssetConfig(address underlying) external view returns (AssetConfig memory);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.10;

import "./IRiskManager.sol";

interface IExec {
    /// @notice Compute aggregate liquidity for an account
    /// @param account User address
    /// @return status Aggregate liquidity (sum of all entered assets)
    function liquidity(address account) external view returns (IRiskManager.LiquidityStatus memory status);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.10;

interface IEulerGeneralView {
    function computeAPYs(uint borrowSPY, uint totalBorrows, uint totalBalancesUnderlying, uint32 reserveFee) external pure returns (uint borrowAPY, uint supplyAPY);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity 0.8.10;

interface IEulDistributor {
    /// @notice Claim distributed tokens
    /// @param account Address that should receive tokens
    /// @param token Address of token being claimed (ie EUL)
    /// @param proof Merkle proof that validates this claim
    /// @param stake If non-zero, then the address of a token to auto-stake to, instead of claiming
    function claim(
        address account,
        address token,
        uint256 claimable,
        bytes32[] calldata proof,
        address stake
    ) external;

    function claimed(address account, address token) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import "./IUniswapV3SwapCallback.sol";

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

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.10;

interface IIdleCDOStrategy {
  function strategyToken() external view returns(address);
  function token() external view returns(address);
  function tokenDecimals() external view returns(uint256);
  function oneToken() external view returns(uint256);
  function redeemRewards(bytes calldata _extraData) external returns(uint256[] memory);
  function pullStkAAVE() external returns(uint256);
  function price() external view returns(uint256);
  function getRewardTokens() external view returns(address[] memory);
  function deposit(uint256 _amount) external returns(uint256);
  // _amount in `strategyToken`
  function redeem(uint256 _amount) external returns(uint256);
  // _amount in `token`
  function redeemUnderlying(uint256 _amount) external returns(uint256);
  function getApr() external view returns(uint256);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.10;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IERC20Detailed is IERC20Upgradeable {
  function name() external view returns(string memory);
  function symbol() external view returns(string memory);
  function decimals() external view returns(uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";
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

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(IERC20Upgradeable token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20Upgradeable token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
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
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overloaded;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return 18;
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

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

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

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

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

        _totalSupply += amount;
        _balances[account] += amount;
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

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

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
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
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
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

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
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity 0.8.10;

interface IRiskManager {
    struct LiquidityStatus {
        uint256 collateralValue;
        uint256 liabilityValue;
        uint256 numBorrows;
        bool borrowIsolated;
    }

    function computeLiquidity(address account) external view returns (LiquidityStatus memory status);

    function getPrice(address underlying) external view returns (uint256 twap, uint256 twapPeriod);
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