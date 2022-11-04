// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "boc-contract-core/contracts/strategy/BaseStrategy.sol";
import "./../../../enums/ProtocolEnum.sol";

import "../../../../external/cream/CTokenInterface.sol";
import "../../../../external/cream/Comptroller.sol";
import "../../../../external/cream/IPriceOracle.sol";
import "../../../../external/convex/IConvex.sol";
import "../../../../external/convex/IConvexReward.sol";
import "../../../../external/curve/ICurveFi.sol";
import "../../../../external/weth/IWeth.sol";

import "../../../../external/uniswap/IUniswapV2Router2.sol";

import "../../../../external/curve/ICurveMini.sol";

/// @title ConvexIBUsdtStrategy
/// @notice Investment strategy for investing stablecoins to IronBank-Usdt pool via Convex 
/// @author Bank of Chain Protocol Inc
contract ConvexIBUsdtStrategy is Initializable, BaseStrategy {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // IronBank
    Comptroller public constant COMPTROLLER =
        Comptroller(0xAB1c342C7bf5Ec5F02ADEA1c2270670bCa144CbB);
    
    /// @notice The priceOracle interface
    IPriceOracle public priceOracle;

    address public constant COLLATERAL_TOKEN = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    CTokenInterface public constant COLLATERAL_CTOKEN =
        CTokenInterface(0x48759F220ED983dB51fA7A8C0D2AAb8f3ce4166a);

    /// @notice The CToken interface
    CTokenInterface public borrowCToken;

    /// @notice The address of the reward pool
    address public rewardPool;

    uint256 internal pId;

    /// @notice The borrow factor
    uint256 public borrowFactor;

    // minimum amount to be liquidation
    uint256 public constant SELL_FLOOR = 1e16;
    uint256 public constant BPS = 10000;
    address public constant BOOSTER = 0xF403C135812408BFbE8713b5A23a04b3D48AAE31;
    address public constant REWARD_CRV = 0xD533a949740bb3306d119CC777fa900bA034cd52;
    address public constant REWARD_CVX = 0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B;
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    // rkp3r
    address internal constant RKPR = 0xEdB67Ee1B171c4eC66E6c10EC43EDBbA20FaE8e9;

    // use Curve to sell our CVX and CRV rewards to WETH
    address internal constant CRV_ETH_POOL = 0x8301AE4fc9c624d1D396cbDAa1ed877821D7C511; // use curve's new CRV-ETH crypto pool to sell our CRV
    address internal constant CVX_ETH_POOL = 0xB576491F1E6e5E62f1d8F26062Ee822B40B0E0d4; // use curve's new CVX-ETH crypto pool to sell our CVX

    //sushi router
    address internal constant SUSHI_ROUTER_ADDR = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;
    //uni router
    address internal constant UNI_ROUTER_ADDR = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    //uni v3
    address internal constant UNISWAP_V3 = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    //reward swap path
    mapping(address => address[]) public rewardRoutes;

    address public curveUsdcIbforexPool;

    /// @param _borrowFactor The new borrow factor
    event UpdateBorrowFactor(uint256 _borrowFactor);

    /// @param _strategy The specified strategy emitted this event
    /// @param _rewards The address list of reward tokens
    /// @param _rewardAmounts The amount list of of reward tokens
    /// @param _wants The address list of wantted tokens
    /// @param _wantAmounts The amount list of wantted tokens
    event SwapRewardsToWants(
        address _strategy,
        address[] _rewards,
        uint256[] _rewardAmounts,
        address[] _wants,
        uint256[] _wantAmounts
    );

    ////// fallback and receive //////
    receive() external payable {}

    fallback() external payable {}

    /// @notice Initialize this contract
    /// @param _vault The Vault contract
    /// @param _harvester The harvester contract address
    /// @param _strategyName The name of strategy
    /// @param _borrowCToken The borrow asset of this strategy
    /// @param _curve_usdc_ibforex_pool The curve usdc-ibforex pool invested 
    /// @param _rewardPool The address of the base reward pool which issue reward linearly
    function initialize(
        address _vault,
        address _harvester,
        string memory _strategyName,
        address _borrowCToken,
        address _rewardPool,
        address _curve_usdc_ibforex_pool
    ) external initializer {
        borrowCToken = CTokenInterface(_borrowCToken);
        rewardPool = _rewardPool;
        pId = IConvexReward(rewardPool).pid();
        curveUsdcIbforexPool = _curve_usdc_ibforex_pool;
        address[] memory _wants = new address[](1);
        _wants[0] = COLLATERAL_TOKEN;

        priceOracle = IPriceOracle(COMPTROLLER.oracle());

        _initialize(_vault, _harvester, _strategyName, uint16(ProtocolEnum.Convex), _wants);

        borrowFactor = 8300;

        uint256 _uintMax = type(uint256).max;
        // approve sell rewards
        IERC20Upgradeable(REWARD_CRV).safeApprove(address(CRV_ETH_POOL), _uintMax);
        IERC20Upgradeable(REWARD_CVX).safeApprove(address(CVX_ETH_POOL), _uintMax);

        // approve deposit
        address _curveForexPool = getCurveLpToken();
        address _borrowToken = borrowCToken.underlying();
        IERC20Upgradeable(_borrowToken).safeApprove(_curveForexPool, _uintMax);

        IERC20Upgradeable(_borrowToken).safeApprove(SUSHI_ROUTER_ADDR, _uintMax);
        IERC20Upgradeable(USDC).safeApprove(UNI_ROUTER_ADDR, _uintMax);
        IERC20Upgradeable(WETH).safeApprove(SUSHI_ROUTER_ADDR, _uintMax);

        //init reward swap path
        address[] memory _ib2usdc = new address[](2);
        _ib2usdc[0] = _borrowToken;
        _ib2usdc[1] = USDC;
        rewardRoutes[_borrowToken] = _ib2usdc;
        address[] memory _weth2usdc = new address[](2);
        _weth2usdc[0] = WETH;
        _weth2usdc[1] = USDC;
        rewardRoutes[WETH] = _weth2usdc;
        address[] memory _usdc2usdt = new address[](2);
        _usdc2usdt[0] = USDC;
        _usdc2usdt[1] = COLLATERAL_TOKEN;
        rewardRoutes[USDC] = _usdc2usdt;
    }

    /// @notice Return the version of strategy
    function getVersion() external pure override returns (string memory) {
        return "1.0.0";
    }

    // ==== External === //
    /// @notice Return the third party protocol's pool total assets in USD(1e18).
    function get3rdPoolAssets() public view override returns (uint256 targetPoolTotalAssets) {
        address _curvePool = getCurveLpToken();
        uint256 _virtualPrice = ICurveFi(_curvePool).get_virtual_price();
        uint256 _totalSupply = IERC20Upgradeable(_curvePool).totalSupply();
        //30 = 18+12,div 1e12 for normalized,div 1e18 for _virtualPrice
        targetPoolTotalAssets =
            (_virtualPrice * _totalSupply * _borrowTokenPrice()) /
            decimalUnitOfToken(getIronBankForex()) /
            1e30;
    }

    /// @notice Return the underlying token list and ratio list needed by the strategy
    /// @return _assets the address list of token to deposit
    /// @return _ratios the ratios list of `_assets`. 
    ///     The ratio is the proportion of each asset to total assets
    function getWantsInfo()
        public
        view
        override
        returns (address[] memory _assets, uint256[] memory _ratios)
    {
        _assets = wants;

        _ratios = new uint256[](1);
        _ratios[0] = 1e18;
    }

    /// @notice Return the output path list of the strategy when withdraw.
    function getOutputsInfo()
        external
        view
        virtual
        override
        returns (OutputInfo[] memory _outputsInfo)
    {
        _outputsInfo = new OutputInfo[](1);
        OutputInfo memory _info0 = _outputsInfo[0];
        _info0.outputCode = 0;
        _info0.outputTokens = wants;
    }

    /// @notice Returns the position details of the strategy.
    /// @return _tokens The list of the position token
    /// @return _amounts The list of the position amount
    /// @return _isUsd Whether to count in USD
    /// @return _usdValue The USD value of positions held
    function getPositionDetail()
        public
        view
        override
        returns (
            address[] memory _tokens,
            uint256[] memory _amounts,
            bool _isUsd,
            uint256 _usdValue
        )
    {
        _isUsd = true;
        uint256 _assetsValue = assets();
        uint256 _debtsValue = debts();
        // The usdValue needs to be filled with precision
        _usdValue = _assetsValue - _debtsValue;
    }

    
    /// @notice Return the total valuation of this strategy, in currency denominated units
    function curvePoolAssets() public view returns (uint256 _depositedAssets) {
        uint256 _rewardBalance = balanceOfToken(rewardPool);
        if (_rewardBalance > 0) {
            _depositedAssets =
                (_borrowTokenPrice() *
                    ICurveFi(getCurveLpToken()).calc_withdraw_one_coin(_rewardBalance, 0)) /
                1e12 /
                decimalUnitOfToken(getCurveLpToken());
        } else {
            _depositedAssets = 0;
        }
    }

    
    /// @notice Gets the current debt Rate    
    function debtRate() public view returns (uint256) {
        //_collateral Assets
        uint256 _collateral = collateralAssets();
        //debts
        uint256 _debt = debts();
        if (_collateral == 0) {
            return 0;
        }
        return (_debt * BPS) / _collateral;
    }

    /// @notice Gets the total value of all assets in USD (1e18) 
    function assets() public view returns (uint256 _value) {
        // estimatedDepositedAssets
        uint256 deposited = curvePoolAssets();
        _value += deposited;
        // CToken _value
        _value += collateralAssets();
        address _collateralToken = COLLATERAL_TOKEN;
        // balance
        uint256 _underlyingBalance = balanceOfToken(_collateralToken);
        if (_underlyingBalance > 0) {
            _value +=
                ((_underlyingBalance * _collateralTokenPrice()) /
                    decimalUnitOfToken(_collateralToken)) /
                1e12;
        }
    }

    /// @notice Gets the value of debts in USD (1e18) 
    function debts() public view returns (uint256 _value) {
        CTokenInterface _borrowCToken = borrowCToken;
        //for saving gas
        uint256 _borrowBalanceCurrent = _borrowCToken.borrowBalanceStored(address(this));
        address _borrowToken = _borrowCToken.underlying();
        uint256 _borrowTokenPrice = _borrowTokenPrice();
        _value =
            (_borrowBalanceCurrent * _borrowTokenPrice) /
            decimalUnitOfToken(_borrowToken) /
            1e12; //div 1e12 for normalized
    }

    /// @notice Gets the value of collateral assets in USD (1e18) 
    function collateralAssets() public view returns (uint256 _value) {
        CTokenInterface _collateralC = COLLATERAL_CTOKEN;
        address _collateralToken = COLLATERAL_TOKEN;
        //saving gas
        uint256 _exchangeRateMantissa = _collateralC.exchangeRateStored();
        uint256 _collaterTokenPrecision = decimalUnitOfToken(_collateralToken);
        //Multiply by 18e to prevent loss of precision
        uint256 _collateralTokenAmount = (balanceOfToken(address(_collateralC)) *
            _exchangeRateMantissa *
            _collaterTokenPrecision *
            1e18) /
            1e16 /
            decimalUnitOfToken(address(_collateralC));

        _value =
            (_collateralTokenAmount * _collateralTokenPrice()) /
            _collaterTokenPrecision /
            1e18 /
            1e12; //div 1e12 for normalized
    }

    /// @notice Gets the info of current borrow in USD (1e18) 
    /// @return _space The absolute value of the difference 
    ///     between `_borrowAvaible` and `_currentBorrow`
    /// @return _overflow The absolute value of the difference 
    ///     between `_borrowAvaible` and `_currentBorrow`
    function borrowInfo() public view returns (uint256 _space, uint256 _overflow) {
        uint256 _borrowAvaible = _currentBorrowAvaible();
        uint256 _currentBorrow = borrowCToken.borrowBalanceStored(address(this));
        if (_borrowAvaible > _currentBorrow) {
            _space = _borrowAvaible - _currentBorrow;
        } else {
            _overflow = _currentBorrow - _borrowAvaible;
        }
    }

    /// @notice Gets the curve LP token invested by this strategy
    function getCurveLpToken() public view returns (address) {
        return IConvex(BOOSTER).poolInfo(pId).lptoken;
    }

    /// @notice Gets the IronBankForex token of the curve LP token
    function getIronBankForex() public view returns (address) {
        ICurveFi _curveForexPool = ICurveFi(getCurveLpToken());
        return _curveForexPool.coins(0);
    }

    
    
    /// @notice Harvests by the Strategy, 
    ///     recognizing any profits or losses and adjusting the Strategy's position.
    /// @dev Sell reward and reinvestment logic
    /// @return _rewardsTokens The list of the reward token
    /// @return _claimAmounts The list of the reward amount claimed
    function harvest()
        public
        virtual
        override
        returns (address[] memory _rewardsTokens, uint256[] memory _claimAmounts)
    {
        // for report
        _rewardsTokens = new address[](3);
        _rewardsTokens[0] = REWARD_CRV;
        _rewardsTokens[1] = REWARD_CVX;
        _rewardsTokens[2] = RKPR;
        _claimAmounts = new uint256[](3);
        // for event
        address[] memory _rewardTokens;
        uint256[] memory _rewardAmounts;
        address[] memory _wantTokens;
        uint256[] memory _wantAmounts;
        IConvexReward _convexReward = IConvexReward(rewardPool);
        if (_convexReward.earned(address(this)) > SELL_FLOOR) {
            _convexReward.getReward();
            uint256 _crvBalance = balanceOfToken(REWARD_CRV);
            uint256 _cvxBalance = balanceOfToken(REWARD_CVX);
            (_rewardTokens, _rewardAmounts, _wantTokens, _wantAmounts) = _sellCrvAndCvx(
                _crvBalance,
                _cvxBalance
            );

            uint256 _ibForexAmount = balanceOfToken(getIronBankForex());
            if (_ibForexAmount > 0) {
                _invest(_ibForexAmount);
            }
            //sell kpr
            uint256 _rkprBalance = balanceOfToken(RKPR);
            if (_rkprBalance > 0) {
                IERC20Upgradeable(RKPR).safeTransfer(harvester, _rkprBalance);
            }

            _claimAmounts[0] = _crvBalance;
            _claimAmounts[1] = _cvxBalance;
            _claimAmounts[2] = _rkprBalance;
        }
        // report empty array for _profit
        vault.report(_rewardsTokens, _claimAmounts);

        // emit 'SwapRewardsToWants' event after vault report
        emit SwapRewardsToWants(
            address(this),
            _rewardTokens,
            _rewardAmounts,
            _wantTokens,
            _wantAmounts
        );
    }

    
    /// @dev sell crv and cvx
    function _sellCrvAndCvx(uint256 _crvAmount, uint256 _convexAmount)
        internal
        returns (
            address[] memory _rewardTokens,
            uint256[] memory _rewardAmounts,
            address[] memory _wantTokens,
            uint256[] memory _wantAmounts
        )
    {
        uint256 _ethBalanceInit = address(this).balance;

        if (_crvAmount > 0) {
            ICurveFi(CRV_ETH_POOL).exchange(1, 0, _crvAmount, 0, true);
        }
        uint256 _ethBalanceAfterSellCrv = address(this).balance;

        if (_convexAmount > 0) {
            ICurveFi(CVX_ETH_POOL).exchange(1, 0, _convexAmount, 0, true);
        }

        // fulfill 'SwapRewardsToWants' event data
        _rewardTokens = new address[](2);
        _rewardAmounts = new uint256[](2);
        _wantTokens = new address[](2);
        _wantAmounts = new uint256[](2);

        _rewardTokens[0] = REWARD_CRV;
        _rewardTokens[1] = REWARD_CVX;
        _rewardAmounts[0] = _crvAmount;
        _rewardAmounts[1] = _convexAmount;
        _wantTokens[0] = USDC;
        _wantTokens[1] = USDC;

        uint256 _ethBalanceAfterSellTotal = address(this).balance;
        uint256 _usdcBalanceInit = balanceOfToken(USDC);
        uint256 _usdcBalanceAfterSellWeth;
        uint256 _usdcAmountSell;

        if (_ethBalanceAfterSellTotal > 0) {
            //ETH wrap to WETH
            IWeth(WETH).deposit{value: _ethBalanceAfterSellTotal}();
            //swap from WETH to USDC
            IUniswapV2Router2(SUSHI_ROUTER_ADDR).swapExactTokensForTokens(
                balanceOfToken(WETH),
                0,
                rewardRoutes[WETH],
                address(this),
                block.timestamp
            );
            _usdcBalanceAfterSellWeth = balanceOfToken(USDC);
            _usdcAmountSell = _usdcBalanceAfterSellWeth - _usdcBalanceInit;

            // fulfill 'SwapRewardsToWants' event data
            if (_ethBalanceAfterSellTotal - _ethBalanceInit > 0) {
                _wantAmounts[0] =
                    (_usdcAmountSell * (_ethBalanceAfterSellCrv - _ethBalanceInit)) /
                    (_ethBalanceAfterSellTotal - _ethBalanceInit);
                _wantAmounts[1] = _usdcAmountSell - _wantAmounts[0];
            }

            IERC20Upgradeable(USDC).safeApprove(curveUsdcIbforexPool, 0);
            IERC20Upgradeable(USDC).safeApprove(curveUsdcIbforexPool, _usdcBalanceAfterSellWeth);
            ICurveMini(curveUsdcIbforexPool).exchange(1, 0, _usdcBalanceAfterSellWeth, 0);
        }
    }

    /// @dev Return the price in USD (1e30) of collateral token
    function _collateralTokenPrice() internal view returns (uint256) {
        return priceOracle.getUnderlyingPrice(address(COLLATERAL_CTOKEN));
    }

    /// @dev Return the price in USD (1e30) of borrow token
    function _borrowTokenPrice() internal view returns (uint256) {
        return _getNormalizedBorrowToken();
    }

    function _getNormalizedBorrowToken() internal view returns (uint256) {
        return priceOracle.getUnderlyingPrice(address(borrowCToken)) * 1e12;
    }

    /// @dev Return the maximum number of borrowing under the specified amount of _collateral assets
    function _borrowAvaiable(uint256 liqudity) internal view returns (uint256 _borrowAvaible) {
        address _borrowToken = getIronBankForex();
        uint256 _borrowTokenPrice = _borrowTokenPrice(); // decimals 1e30
        //Maximum number of loans available
        uint256 _maxBorrowAmount = (liqudity * decimalUnitOfToken(_borrowToken)) /
            _borrowTokenPrice;
        //Borrowable quantity under the current borrowFactor factor
        _borrowAvaible = (_maxBorrowAmount * borrowFactor) / BPS;
    }

    /// @dev Return the amount of current total available borrow
    function _currentBorrowAvaible() internal view returns (uint256 _borrowAvaible) {
        // Pledge discount _rate, base 1e18
        (, uint256 _rate) = COMPTROLLER.markets(address(COLLATERAL_CTOKEN));
        uint256 _liquidity = (collateralAssets() * 1e12 * _rate) / 1e18; //multi 1e12 for liquidity convert to 1e30
        _borrowAvaible = _borrowAvaiable(_liquidity);
    }

    /// @dev Add _collateral to IronBank
    function _mintCollateralCToken(uint256 mintAmount) internal {
        address _collateralC = address(COLLATERAL_CTOKEN);
        //saving gas
        // mint Collateral
        IERC20Upgradeable(COLLATERAL_TOKEN).safeApprove(_collateralC, 0);
        IERC20Upgradeable(COLLATERAL_TOKEN).safeApprove(_collateralC, mintAmount);
        COLLATERAL_CTOKEN.mint(mintAmount);
        // enter market
        address[] memory _markets = new address[](1);
        _markets[0] = _collateralC;
        COMPTROLLER.enterMarkets(_markets);
    }

    /// @dev Added Forex to Curve pool
    function curveAddLiquidity(uint256 _ibTokenAmount) internal {
        ICurveFi(getCurveLpToken()).add_liquidity([_ibTokenAmount, 0], 0);
    }

    /// @dev Curve remove liquidity
    function curveRemoveLiquidity(uint256 shareAmount) internal {
        ICurveFi(getCurveLpToken()).remove_liquidity_one_coin(shareAmount, 0, 0);
    }

    /// @dev Invest IronBank token to Curve pool by Convex
    function _invest(uint256 _ibTokenAmount) internal {
        curveAddLiquidity(_ibTokenAmount);

        address lpToken = getCurveLpToken();
        uint256 _liquidity = balanceOfToken(lpToken);
        address _booster = BOOSTER;
        //saving gas
        if (_liquidity > 0) {
            IERC20Upgradeable(lpToken).safeApprove(_booster, 0);
            IERC20Upgradeable(lpToken).safeApprove(_booster, _liquidity);
            IConvex(_booster).deposit(pId, _liquidity, true);
        }
    }

    /// @dev Borrow forex
    function _borrowForex(uint256 _borrowAmount) internal returns (uint256 _receiveAmount) {
        CTokenInterface _borrowC = borrowCToken;
        //saving gas
        _borrowC.borrow(_borrowAmount);
        _receiveAmount = balanceOfToken(_borrowC.underlying());
    }

    /// @dev Repay forex
    function _repayForex(uint256 _repayAmount) internal {
        CTokenInterface _borrowC = borrowCToken;
        //saving gas
        address _borrowToken = _borrowC.underlying();
        IERC20Upgradeable(_borrowToken).safeApprove(address(_borrowC), 0);
        IERC20Upgradeable(_borrowToken).safeApprove(address(_borrowC), _repayAmount);
        _borrowC.repayBorrow(_repayAmount);
    }

    /// @dev Increase the amount of borrow
    function increaseBorrow() public isKeeper {
        (uint256 _space, ) = borrowInfo();
        if (_space > 0) {
            //borrow forex
            uint256 _receiveAmount = _borrowForex(_space);
            _invest(_receiveAmount);
        }
    }

    /// @dev  decrease borrow
    function decreaseBorrow() public isKeeper {
        //The number of borrowing that will be out of range after redemption
        (, uint256 _overflow) = borrowInfo();
        if (_overflow > 0) {
            uint256 _totalStaking = balanceOfToken(rewardPool);
            uint256 _currentBorrow = borrowCToken.borrowBalanceCurrent(address(this));
            uint256 _cvxLpAmount = (_totalStaking * _overflow) / _currentBorrow;
            _redeem(_cvxLpAmount);
            uint256 _borrowTokenBalance = balanceOfToken(borrowCToken.underlying());
            _repayForex(_borrowTokenBalance);
        }
    }

    /// @notice Sets `_borrowFactor` to `borrowFactor`
    /// @param _borrowFactor The new value of `borrowFactor`
    /// Requirements: only vault manager can call
    function setBorrowFactor(uint256 _borrowFactor) external isVaultManager {
        require(_borrowFactor < BPS, "setting output the range");
        borrowFactor = _borrowFactor;

        emit UpdateBorrowFactor(_borrowFactor);
    }

    /// @dev Redeem assets invested by this strategy
    function _redeem(uint256 _cvxLpAmount) internal {
        IConvexReward(rewardPool).withdraw(_cvxLpAmount, false);
        IConvex(BOOSTER).withdraw(pId, _cvxLpAmount);
        //curve remove liquidity
        curveRemoveLiquidity(_cvxLpAmount);
    }

    /// @notice Strategy deposit funds to third party pool.
    /// @param _assets the address list of token to deposit
    /// @param _amounts the amount list of token to deposit
    function depositTo3rdPool(address[] memory _assets, uint256[] memory _amounts)
        internal
        override
    {
        require(_assets[0] == address(COLLATERAL_TOKEN) && _amounts[0] > 0);
        uint256 _collateralAmount = _amounts[0];
        _mintCollateralCToken(_collateralAmount);
        (uint256 _space, ) = borrowInfo();
        if (_space > 0) {
            // borrow forex
            uint256 _receiveAmount = _borrowForex(_space);
            _invest(_receiveAmount);
        }
    }

    /// @notice Strategy withdraw the funds from third party pool
    /// @param _withdrawShares The amount of shares to withdraw
    /// @param _totalShares The total amount of shares owned by this strategy
    /// @param _outputCode The code of output
    function withdrawFrom3rdPool(
        uint256 _withdrawShares,
        uint256 _totalShares,
        uint256 _outputCode
    ) internal override {
        // if withdraw all,force claim reward.
        if (_withdrawShares == _totalShares) {
            harvest();
        }
        uint256 _totalStaking = balanceOfToken(rewardPool);
        uint256 _cvxLpAmount = (_totalStaking * _withdrawShares) / _totalShares;
        //saving gas
        CTokenInterface _borrowC = borrowCToken;
        //saving gas
        CTokenInterface _collateralC = COLLATERAL_CTOKEN;
        if (_cvxLpAmount > 0) {
            _redeem(_cvxLpAmount);
            // ib Token Amount
            address _borrowToken = _borrowC.underlying();
            uint256 _borrowTokenBalance = balanceOfToken(_borrowToken);
            uint256 _currentBorrow = _borrowC.borrowBalanceCurrent(address(this));
            uint256 _repayAmount = (_currentBorrow * _withdrawShares) / _totalShares;
            _repayAmount = MathUpgradeable.min(_repayAmount, _borrowTokenBalance);
            _repayForex(_repayAmount);
            uint256 _burnAmount = (balanceOfToken(address(_collateralC)) * _repayAmount) /
                _currentBorrow;
            _collateralC.redeem(_burnAmount);
            //The excess _borrowToken is exchanged for U
            uint256 _profit = balanceOfToken(_borrowToken);
            if (_profit > 0) {
                IUniswapV2Router2(SUSHI_ROUTER_ADDR).swapExactTokensForTokens(
                    _profit,
                    0,
                    rewardRoutes[_borrowToken],
                    address(this),
                    block.timestamp
                );
                uint256 _usdcBalance = balanceOfToken(USDC);
                IUniswapV2Router2(UNI_ROUTER_ADDR).swapExactTokensForTokens(
                    _usdcBalance,
                    0,
                    rewardRoutes[USDC],
                    address(this),
                    block.timestamp
                );
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

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

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./../access-control/AccessControlMixin.sol";
import "./../library/BocRoles.sol";
import "../library/StableMath.sol";
import "../price-feeds/IValueInterpreter.sol";
import "./IStrategy.sol";

abstract contract BaseStrategy is IStrategy, Initializable, AccessControlMixin {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using StableMath for uint256;

    IVault public override vault;
    IValueInterpreter public valueInterpreter;
    address public override harvester;
    uint16 public override protocol;
    string public override name;
    address[] public wants;
    bool public override isWantRatioIgnorable;

    modifier onlyVault() {
        require(msg.sender == address(vault));
        _;
    }

    function _initialize(
        address _vault,
        address _harvester,
        string memory _name,
        uint16 _protocol,
        address[] memory _wants
    ) internal {
        protocol = _protocol;
        harvester = _harvester;
        name = _name;
        vault = IVault(_vault);
        valueInterpreter = IValueInterpreter(vault.valueInterpreter());

        _initAccessControl(vault.accessControlProxy());

        require(_wants.length > 0, "wants is required");
        for (uint256 i = 0; i < _wants.length; i++) {
            require(_wants[i] != address(0), "SAI");
        }
        wants = _wants;
    }

    /// @notice Version of strategy
    function getVersion() external pure virtual override returns (string memory);

    /// @notice True means that can ignore ratios given by wants info
    function setIsWantRatioIgnorable(bool _isWantRatioIgnorable) external override isVaultManager {
        bool _oldValue = isWantRatioIgnorable;
        isWantRatioIgnorable = _isWantRatioIgnorable;
        emit SetIsWantRatioIgnorable(_oldValue, _isWantRatioIgnorable);
    }

    /// @notice Provide the strategy need underlying token and ratio
    function getWantsInfo()
        external
        view
        virtual
        override
        returns (address[] memory _assets, uint256[] memory _ratios);

    /// @notice Provide the strategy need underlying tokens
    function getWants() external view override returns (address[] memory) {
        return wants;
    }

    // @notice Provide the strategy output path when withdraw.
    function getOutputsInfo() external view virtual override returns (OutputInfo[] memory _outputsInfo);

    /// @notice Returns the position details of the strategy.
    function getPositionDetail()
        public
        view
        virtual
        override
        returns (
            address[] memory _tokens,
            uint256[] memory _amounts,
            bool _isUsd,
            uint256 _usdValue
        );

    /// @notice Total assets of strategy in USD.
    function estimatedTotalAssets() external view virtual override returns (uint256) {
        (
            address[] memory _tokens,
            uint256[] memory _amounts,
            bool _isUsd,
            uint256 _usdValue
        ) = getPositionDetail();
        if (_isUsd) {
            return _usdValue;
        } else {
            uint256 _totalUsdValue = 0;
            for (uint256 i = 0; i < _tokens.length; i++) {
                _totalUsdValue += queryTokenValue(_tokens[i], _amounts[i]);
            }
            return _totalUsdValue;
        }
    }

    /// @notice 3rd prototcol's pool total assets in USD.
    function get3rdPoolAssets() external view virtual override returns (uint256);

    /// @notice Harvests the Strategy, recognizing any profits or losses and adjusting the Strategy's position.
    function harvest()
        external
        virtual
        override
        returns (address[] memory _rewardsTokens, uint256[] memory _claimAmounts)
    {
        vault.report(_rewardsTokens, _claimAmounts);
    }

    /// @notice Strategy borrow funds from vault
    /// @param _assets borrow token address
    /// @param _amounts borrow token amount
    function borrow(address[] memory _assets, uint256[] memory _amounts) external override onlyVault {
        depositTo3rdPool(_assets, _amounts);
        emit Borrow(_assets, _amounts);
    }

    /// @notice Strategy repay the funds to vault
    /// @param _repayShares Numerator
    /// @param _totalShares Denominator
    function repay(
        uint256 _repayShares,
        uint256 _totalShares,
        uint256 _outputCode
    ) public virtual override onlyVault returns (address[] memory _assets, uint256[] memory _amounts) {
        require(_repayShares > 0 && _totalShares >= _repayShares, "cannot repay 0 shares");
        _assets = wants;
        uint256[] memory _balancesBefore = new uint256[](_assets.length);
        for (uint256 i = 0; i < _assets.length; i++) {
            _balancesBefore[i] = balanceOfToken(_assets[i]);
        }

        withdrawFrom3rdPool(_repayShares, _totalShares, _outputCode);
        _amounts = new uint256[](_assets.length);
        for (uint256 i = 0; i < _assets.length; i++) {
            uint256 _balanceAfter = balanceOfToken(_assets[i]);
            _amounts[i] =
                _balanceAfter -
                _balancesBefore[i] +
                (_balancesBefore[i] * _repayShares) /
                _totalShares;
        }

        transferTokensToTarget(address(vault), _assets, _amounts);

        emit Repay(_repayShares, _totalShares, _assets, _amounts);
    }

    /// @notice Investable amount of strategy in USD
    function poolQuota() public view virtual override returns (uint256) {
        return type(uint256).max;
    }

    /// @notice Strategy deposit funds to 3rd pool.
    /// @param _assets deposit token address
    /// @param _amounts deposit token amount
    function depositTo3rdPool(address[] memory _assets, uint256[] memory _amounts) internal virtual;

    /// @notice Strategy withdraw the funds from 3rd pool.
    /// @param _withdrawShares Numerator
    /// @param _totalShares Denominator
    function withdrawFrom3rdPool(
        uint256 _withdrawShares,
        uint256 _totalShares,
        uint256 _outputCode
    ) internal virtual;

    /// @notice Return the token's balance Of this contract
    function balanceOfToken(address _tokenAddress) internal view returns (uint256) {
        return IERC20Upgradeable(_tokenAddress).balanceOf(address(this));
    }

    /// @notice Query the value of Token.
    function queryTokenValue(address _token, uint256 _amount)
        internal
        view
        returns (uint256 _valueInUSD)
    {
        _valueInUSD = valueInterpreter.calcCanonicalAssetValueInUsd(_token, _amount);
    }

    /// @notice Return the uint with decimal of one token
    function decimalUnitOfToken(address _token) internal view returns (uint256) {
        return 10**IERC20MetadataUpgradeable(_token).decimals();
    }

    /// @notice Transfer `_assets` token from this contract to target address.
    /// @param _target The target address to receive token
    /// @param _assets deposit token address list
    /// @param _amounts deposit token amount list
    function transferTokensToTarget(
        address _target,
        address[] memory _assets,
        uint256[] memory _amounts
    ) internal {
        for (uint256 i = 0; i < _assets.length; i++) {
            uint256 _amount = _amounts[i];
            if (_amount > 0) {
                IERC20Upgradeable(_assets[i]).safeTransfer(address(_target), _amount);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

enum ProtocolEnum {
    Balancer,
    UniswapV2,
    Dodo,
    Sushi_Kashi,
    Sushi_Swap,
    Convex,
    Rari,
    UniswapV3,
    YearnEarn,
    YearnV2,
    YearnIronBank,
    GUni,
    Stargate,
    DForce,
    Synapse,
    Aura,
    Aave
}

pragma solidity >=0.8.0 <0.9.0;

interface CTokenInterface {
    function mint(uint256) external returns (uint256);

    function redeem(uint redeemTokens) external returns (uint);

    function borrow(uint256) external returns (uint256);

    function borrowRatePerBlock() external view returns (uint256);

    function borrowBalanceCurrent(address) external returns (uint256);
    function borrowBalanceStored(address) external view returns (uint256);
    function getCash() external view returns (uint);
    function totalBorrows() external view returns (uint);
    function totalReserves() external view returns (uint);
    function interestRateModel() external view returns(address);

    function repayBorrow(uint256) external returns (uint256);

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
        
    function exchangeRateStored() external view returns (uint256);
}

pragma solidity >=0.8.0 <0.9.0;

interface Comptroller {
    function markets(address) external view returns (bool, uint256);

    function enterMarkets(address[] calldata)
        external
        returns (uint256[] memory);
    function exitMarket(address cTokenAddress) external returns (uint256);

    function getAccountLiquidity(address)
        external
        view
        returns (uint256, uint256, uint256);

    function redeemAllowed(
        address cToken,
        address redeemer,
        uint256 redeemTokens
    ) external returns (uint256);

    function getHypotheticalAccountLiquidity(
        address account,
        address cTokenModify,
        uint256 redeemTokens,
        uint256 borrowAmount
    )
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );
        
    function oracle() external view returns(address);
    function _setPriceOracle(address _newPriceOracle) external;
}

pragma solidity >=0.8.0 <0.9.0;

interface IPriceOracle {

    /**
      * @notice Get the underlying price of a cToken asset
      * @param cToken The cToken to get the underlying price of
      * @return The underlying asset price mantissa (scaled by 1e18).
      *  Zero means the price is unavailable.
      */
    function getUnderlyingPrice(address cToken) external view returns (uint);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

/// @title ICurveAddressProvider interface
/// @author Enzyme Council <[email protected]>

    struct PoolInfo {
        address lptoken;
        address token;
        address gauge;
        address crvRewards;
        address stash;
        bool shutdown;
    }
interface IConvex {

    function poolInfo(uint256 _pid) external view returns(PoolInfo memory);

    function deposit(uint256 _pid, uint256 _amount, bool _stake) external returns(bool);
    function deposit(uint256 _amount, bool _lock, address _stakeAddress) external;

    function withdraw(uint256 _pid, uint256 _amount) external returns(bool);

}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

/// @title ICurveAddressProvider interface
/// @author Enzyme Council <[email protected]>

interface IConvexReward{
    function pid() external view returns(uint256);
    //get balance of an address
    function balanceOf(address _account) external view returns(uint256);
    function totalSupply() external view returns (uint256);
    //withdraw to a convex tokenized deposit
    function withdraw(uint256 _amount, bool _claim) external returns(bool);
    //withdraw directly to curve LP token
    function withdrawAndUnwrap(uint256 _amount, bool _claim) external returns(bool);
    function earned(address _account) external view returns(uint256);
    //claim rewards
    function getReward() external returns(bool);
    //stake a convex tokenized deposit
    function stake(uint256 _amount) external returns(bool);
    //stake a convex tokenized deposit for another address(transfering ownership)
    function stakeFor(address _account,uint256 _amount) external returns(bool);
}

pragma solidity >=0.8.0 <0.9.0;

interface ICurveFi {
    function get_virtual_price() external view returns (uint256);

    function coins(uint256) external view returns (address);

    function add_liquidity(
        // EURt
        uint256[2] calldata amounts,
        uint256 min_mint_amount
    ) external payable;

    function add_liquidity(
        // Compound, sAave
        uint256[2] calldata amounts,
        uint256 min_mint_amount,
        bool _use_underlying
    ) external payable returns (uint256);

    function add_liquidity(
        // Iron Bank, Aave
        uint256[3] calldata amounts,
        uint256 min_mint_amount,
        bool _use_underlying
    ) external payable returns (uint256);

    function add_liquidity(
        // 3Crv Metapools
        address pool,
        uint256[4] calldata amounts,
        uint256 min_mint_amount
    ) external;

    function add_liquidity(
        // Y and yBUSD
        uint256[4] calldata amounts,
        uint256 min_mint_amount,
        bool _use_underlying
    ) external payable returns (uint256);

    function add_liquidity(
        // 3pool
        uint256[3] calldata amounts,
        uint256 min_mint_amount
    ) external payable;

    function add_liquidity(
        // sUSD
        uint256[4] calldata amounts,
        uint256 min_mint_amount
    ) external payable;

    function remove_liquidity_imbalance(
        uint256[2] calldata amounts,
        uint256 max_burn_amount
    ) external;

    function remove_liquidity(uint256 _amount, uint256[2] calldata amounts)
        external;

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 min_amount
    ) external;

    function exchange(
        // CRV-ETH and CVX-ETH
        uint256 from,
        uint256 to,
        uint256 _from_amount,
        uint256 _min_to_amount,
        bool use_eth
    ) external;

    function exchange(
        // sETH
        int128 from,
        int128 to,
        uint256 _from_amount,
        uint256 _min_to_amount
    ) external payable returns (uint256);

    function balances(uint256) external view returns (uint256);

    function price_oracle() external view returns (uint256);

    function get_dy(
        int128 from,
        int128 to,
        uint256 _from_amount
    ) external view returns (uint256);

    // EURt
    function calc_token_amount(uint256[2] calldata _amounts, bool _is_deposit)
        external
        view
        returns (uint256);

    // 3Crv Metapools
    function calc_token_amount(
        address _pool,
        uint256[4] calldata _amounts,
        bool _is_deposit
    ) external view returns (uint256);

    // sUSD, Y pool, etc
    function calc_token_amount(uint256[4] calldata _amounts, bool _is_deposit)
        external
        view
        returns (uint256);

    // 3pool, Iron Bank, etc
    function calc_token_amount(uint256[3] calldata _amounts, bool _is_deposit)
        external
        view
        returns (uint256);

    function calc_withdraw_one_coin(uint256 amount, int128 i)
        external
        view
        returns (uint256);
}

pragma solidity >=0.8.0 <0.9.0;

interface IWeth {
    function deposit() external payable;
    function withdraw(uint256 wad) external;
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.
    (c) Enzyme Council <[email protected]>
    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity >=0.8.0 <0.9.0;

/// @title UniswapV2Router2 Interface
/// @author Enzyme Council <[email protected]>
/// @dev Minimal interface for our interactions with Uniswap V2's Router2
interface IUniswapV2Router2 {
    function addLiquidity(
        address,
        address,
        uint256,
        uint256,
        uint256,
        uint256,
        address,
        uint256
    )
    external
    returns (
        uint256,
        uint256,
        uint256
    );

    function removeLiquidity(
        address,
        address,
        uint256,
        uint256,
        uint256,
        address,
        uint256
    ) external returns (uint256, uint256);

    function swapExactTokensForTokens(
        uint256,
        uint256,
        address[] calldata,
        address,
        uint256
    ) external returns (uint256[] memory);
}

pragma solidity >=0.8.0 <0.9.0;

interface ICurveMini {
    function balances(uint256) external view returns (uint256);

    function coins(uint256) external view returns (address);

    function get_dy(
        uint256 from,
        uint256 to,
        uint256 _from_amount
    ) external view returns (uint256);

    function exchange(
        uint256 from,
        uint256 to,
        uint256 _from_amount,
        uint256 _min_to_amount
    ) external payable returns (uint256);

    // CRV-ETH and CVX-ETH
    function exchange(
        uint256 from,
        uint256 to,
        uint256 _from_amount,
        uint256 _min_to_amount,
        bool use_eth
    ) external;

    function calc_withdraw_one_coin(uint256 amount, uint256 i) external view returns (uint256);

    function add_liquidity(uint256[2] calldata amounts, uint256 min_mint_amount) external payable;

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        uint256 i,
        uint256 min_amount
    ) external;

    function remove_liquidity(uint256 _amount, uint256[2] calldata amounts) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity >=0.6.0 <0.9.0;

import "./IAccessControlProxy.sol";

abstract contract AccessControlMixin {
    IAccessControlProxy public accessControlProxy;

    function _initAccessControl(address _accessControlProxy) internal {
        accessControlProxy = IAccessControlProxy(_accessControlProxy);
    }

    modifier hasRole(bytes32 _role, address _account) {
        accessControlProxy.checkRole(_role, _account);
        _;
    }

    modifier onlyRole(bytes32 _role) {
        accessControlProxy.checkRole(_role, msg.sender);
        _;
    }

    modifier onlyGovOrDelegate() {
        accessControlProxy.checkGovOrDelegate(msg.sender);
        _;
    }

    modifier isVaultManager() {
        accessControlProxy.checkVaultOrGov(msg.sender);
        _;
    }

    modifier isKeeper() {
        accessControlProxy.checkKeeperOrVaultOrGov(msg.sender);
        _;
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity >=0.6.0 <0.9.0;

library BocRoles {
    bytes32 internal constant GOV_ROLE = 0x00;

    bytes32 internal constant DELEGATE_ROLE = keccak256("DELEGATE_ROLE");

    bytes32 internal constant VAULT_ROLE = keccak256("VAULT_ROLE");

    bytes32 internal constant KEEPER_ROLE = keccak256("KEEPER_ROLE");
}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";

// Based on StableMath from Stability Labs Pty. Ltd.
// https://github.com/mstable/mStable-contracts/blob/master/contracts/shared/StableMath.sol

library StableMath {

    /**
     * @dev Scaling unit for use in specific calculations,
     * where 1 * 10**18, or 1e18 represents a unit '1'
     */
    uint256 private constant FULL_SCALE = 1e18;

    /***************************************
                    Helpers
    ****************************************/

    /**
     * @dev Adjust the scale of an integer
     * @param to Decimals to scale to
     * @param from Decimals to scale from
     */
    function scaleBy(
        uint256 x,
        uint256 to,
        uint256 from
    ) internal pure returns (uint256) {
        if (to > from) {
            x = x * (10 ** (to - from));
        } else if (to < from) {
            x = x / (10 ** (from - to));
        }
        return x;
    }

    /***************************************
               Precise Arithmetic
    ****************************************/

    /**
     * @dev Multiplies two precise units, and then truncates by the full scale
     * @param x Left hand input to multiplication
     * @param y Right hand input to multiplication
     * @return Result after multiplying the two inputs and then dividing by the shared
     *         scale unit
     */
    function mulTruncate(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulTruncateScale(x, y, FULL_SCALE);
    }

    /**
     * @dev Multiplies two precise units, and then truncates by the given scale. For example,
     * when calculating 90% of 10e18, (10e18 * 9e17) / 1e18 = (9e36) / 1e18 = 9e18
     * @param x Left hand input to multiplication
     * @param y Right hand input to multiplication
     * @param scale Scale unit
     * @return Result after multiplying the two inputs and then dividing by the shared
     *         scale unit
     */
    function mulTruncateScale(
        uint256 x,
        uint256 y,
        uint256 scale
    ) internal pure returns (uint256) {
        // e.g. assume scale = fullScale
        // z = 10e18 * 9e17 = 9e36
        uint256 z = x * y;
        // return 9e36 / 1e18 = 9e18
        return z / scale;
    }

    /**
     * @dev Multiplies two precise units, and then truncates by the full scale, rounding up the result
     * @param x Left hand input to multiplication
     * @param y Right hand input to multiplication
     * @return Result after multiplying the two inputs and then dividing by the shared
     *          scale unit, rounded up to the closest base unit.
     */
    function mulTruncateCeil(uint256 x, uint256 y)
    internal
    pure
    returns (uint256)
    {
        // e.g. 8e17 * 17268172638 = 138145381104e17
        uint256 scaled = x * y;
        // e.g. 138145381104e17 + 9.99...e17 = 138145381113.99...e17
        uint256 ceil = scaled + (FULL_SCALE - 1);
        // e.g. 13814538111.399...e18 / 1e18 = 13814538111
        return ceil / FULL_SCALE;
    }

    /**
     * @dev Precisely divides two units, by first scaling the left hand operand. Useful
     *      for finding percentage weightings, i.e. 8e18/10e18 = 80% (or 8e17)
     * @param x Left hand input to division
     * @param y Right hand input to division
     * @return Result after multiplying the left operand by the scale, and
     *         executing the division on the right hand input.
     */
    function divPrecisely(uint256 x, uint256 y)
    internal
    pure
    returns (uint256)
    {
        // e.g. 8e18 * 1e18 = 8e36
        uint256 z = x * FULL_SCALE;
        // e.g. 8e36 / 10e18 = 8e17
        return z / y;
    }

    /**
     * @dev Precisely divides two units, by first scaling the left hand operand. Useful
     *      for finding percentage weightings, i.e. 8e18/10e18 = 80% (or 8e17)
     * @param x Left hand input to division
     * @param y Right hand input to division
     * @return Result after multiplying the left operand by the scale, and
     *         executing the division on the right hand input.
     */
    function divPreciselyScale(uint256 x, uint256 y, uint256 scale)
    internal
    pure
    returns (uint256)
    {
        // e.g. 8e18 * 1e18 = 8e36
        uint256 z = x * scale;
        // e.g. 8e36 / 10e18 = 8e17
        return z / y;
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

interface IValueInterpreter {

    /// @notice Calculates the value of a given amount of one asset in terms of another asset
    /// @param _baseAsset The asset from which to convert
    /// @param _amount The amount of the _baseAsset to convert
    /// @param _quoteAsset The asset to which to convert
    /// @return _value The equivalent quantity in the _quoteAsset
    /// @dev Does not alter protocol state,
    /// but not a view because calls to price feeds can potentially update third party state
    function calcCanonicalAssetValue(
        address _baseAsset,
        uint256 _amount,
        address _quoteAsset
    ) external view returns (uint256);

    /// @notice Calculates the total value of given amounts of assets in a single quote asset
    /// @param _baseAssets The assets to convert
    /// @param _amounts The amounts of the _baseAssets to convert
    /// @param _quoteAsset The asset to which to convert
    /// @return _value The sum value of _baseAssets, denominated in the _quoteAsset
    /// @dev Does not alter protocol state,
    /// but not a view because calls to price feeds can potentially update third party state.
    /// Does not handle a derivative quote asset.
    function calcCanonicalAssetsTotalValue(
        address[] calldata _baseAssets,
        uint256[] calldata _amounts,
        address _quoteAsset
    ) external view returns (uint256);

    
    /// @dev Calculate the usd value of a specified number of assets
    /// @param _baseAsset Source token address
    /// @param _amount The amount of source token
    /// @return usd(1e18)
    function calcCanonicalAssetValueInUsd(
        address _baseAsset,
        uint256 _amount
    ) external view returns (uint256);

     
    /// @dev Calculate the usd value of baseUnit volume assets
    /// @param _baseAsset The ssset token address
    /// @return usd(1e18)
    function price(address _baseAsset) external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

import "../vault/IVault.sol";

interface IStrategy {
    struct OutputInfo {
        uint256 outputCode; //0：default path，Greater than 0：specify output path
        address[] outputTokens; //output tokens
    }

    event Borrow(address[] _assets, uint256[] _amounts);

    event Repay(uint256 _withdrawShares, uint256 _totalShares, address[] _assets, uint256[] _amounts);

    event SetIsWantRatioIgnorable(bool _oldValue, bool _newValue);

    /// @notice Version of strategy
    function getVersion() external pure returns (string memory);

    /// @notice Name of strategy
    function name() external view returns (string memory);

    /// @notice ID of strategy
    function protocol() external view returns (uint16);

    /// @notice Vault address
    function vault() external view returns (IVault);

    /// @notice Harvester address
    function harvester() external view returns (address);

    /// @notice Provide the strategy need underlying token and ratio
    function getWantsInfo() external view returns (address[] memory _assets, uint256[] memory _ratios);

    /// @notice Provide the strategy need underlying token
    function getWants() external view returns (address[] memory _wants);

    // @notice Provide the strategy output path when withdraw.
    function getOutputsInfo() external view returns (OutputInfo[] memory _outputsInfo);

    /// @notice True means that can ignore ratios given by wants info
    function setIsWantRatioIgnorable(bool _isWantRatioIgnorable) external;

    /// @notice Returns the position details of the strategy.
    function getPositionDetail()
        external
        view
        returns (
            address[] memory _tokens,
            uint256[] memory _amounts,
            bool _isUsd,
            uint256 _usdValue
        );

    /// @notice Total assets of strategy in USD.
    function estimatedTotalAssets() external view returns (uint256);

    /// @notice 3rd protocol's pool total assets in USD.
    function get3rdPoolAssets() external view returns (uint256);

    /// @notice Harvests the Strategy, recognizing any profits or losses and adjusting the Strategy's position.
    function harvest() external returns (address[] memory _rewardsTokens, uint256[] memory _claimAmounts);

    /// @notice Strategy borrow funds from vault
    /// @param _assets borrow token address
    /// @param _amounts borrow token amount
    function borrow(address[] memory _assets, uint256[] memory _amounts) external;

    /// @notice Strategy repay the funds to vault
    /// @param _withdrawShares Numerator
    /// @param _totalShares Denominator
    function repay(
        uint256 _withdrawShares,
        uint256 _totalShares,
        uint256 _outputCode
    ) external returns (address[] memory _assets, uint256[] memory _amounts);

    /// @notice getter isWantRatioIgnorable
    function isWantRatioIgnorable() external view returns (bool);

    /// @notice Investable amount of strategy in USD
    function poolQuota() external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity >=0.6.0 <0.9.0;

interface IAccessControlProxy {
    function isGovOrDelegate(address _account) external view returns (bool);

    function isVaultOrGov(address _account) external view returns (bool);

    function isKeeperOrVaultOrGov(address _account) external view returns (bool);

    function hasRole(bytes32 _role, address _account) external view returns (bool);

    function checkRole(bytes32 _role, address _account) external view;

    function checkGovOrDelegate(address _account) external view;

    function checkVaultOrGov(address _account) external view;

    function checkKeeperOrVaultOrGov(address _account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "../exchanges/IExchangeAggregator.sol";

interface IVault {
    /// @param lastReport The last report timestamp
    /// @param totalDebt The total asset of this strategy
    /// @param profitLimitRatio The limited ratio of profit
    /// @param lossLimitRatio The limited ratio for loss
    /// @param enforceChangeLimit The switch of enforce change Limit
    struct StrategyParams {
        uint256 lastReport;
        uint256 totalDebt;
        uint256 profitLimitRatio;
        uint256 lossLimitRatio;
        bool enforceChangeLimit;
    }

    /// @param strategy The new strategy to add
    /// @param profitLimitRatio The limited ratio of profit
    /// @param lossLimitRatio The limited ratio for loss
    struct StrategyAdd {
        address strategy;
        uint256 profitLimitRatio;
        uint256 lossLimitRatio;
    }

    event AddAsset(address _asset);
    event RemoveAsset(address _asset);
    event AddStrategies(address[] _strategies);
    event RemoveStrategies(address[] _strategies);
    event RemoveStrategyByForce(address _strategy);
    event Mint(address _account, address[] _assets, uint256[] _amounts, uint256 _mintAmount);
    event Burn(
        address _account,
        uint256 _amount,
        uint256 _actualAmount,
        uint256 _shareAmount,
        address[] _assets,
        uint256[] _amounts
    );
    event Exchange(
        address _platform,
        address _srcAsset,
        uint256 _srcAmount,
        address _distAsset,
        uint256 _distAmount
    );
    event Redeem(address _strategy, uint256 _debtChangeAmount, address[] _assets, uint256[] _amounts);
    event LendToStrategy(
        address indexed _strategy,
        address[] _wants,
        uint256[] _amounts,
        uint256 _lendValue
    );
    event RepayFromStrategy(
        address indexed _strategy,
        uint256 _strategyWithdrawValue,
        uint256 _strategyTotalValue,
        address[] _assets,
        uint256[] _amounts
    );
    event RemoveStrategyFromQueue(address[] _strategies);
    event SetEmergencyShutdown(bool _shutdown);
    event RebasePaused();
    event RebaseUnpaused();
    event RebaseThresholdUpdated(uint256 _threshold);
    event TrusteeFeeBpsChanged(uint256 _basis);
    event MaxTimestampBetweenTwoReportedChanged(uint256 _maxTimestampBetweenTwoReported);
    event MinCheckedStrategyTotalDebtChanged(uint256 _minCheckedStrategyTotalDebt);
    event MinimumInvestmentAmountChanged(uint256 _minimumInvestmentAmount);
    event TreasuryAddressChanged(address _address);
    event ExchangeManagerAddressChanged(address _address);
    event SetAdjustPositionPeriod(bool _adjustPositionPeriod);
    event RedeemFeeUpdated(uint256 _redeemFeeBps);
    event SetWithdrawalQueue(address[] _queues);
    event Rebase(uint256 _totalShares, uint256 _totalValue, uint256 _newUnderlyingUnitsPerShare);
    event StrategyReported(
        address indexed _strategy,
        uint256 _gain,
        uint256 _loss,
        uint256 _lastStrategyTotalDebt,
        uint256 _nowStrategyTotalDebt,
        address[] _rewardTokens,
        uint256[] _claimAmounts,
        uint256 _type
    );
    event StartAdjustPosition(
        uint256 _totalDebtOfBeforeAdjustPosition,
        address[] _trackedAssets,
        uint256[] _vaultCashDetatil,
        uint256[] _vaultBufferCashDetail
    );
    event EndAdjustPosition(
        uint256 _transferValue,
        uint256 _redeemValue,
        uint256 _totalDebt,
        uint256 _totalValueOfAfterAdjustPosition,
        uint256 _totalValueOfBeforeAdjustPosition
    );
    event PegTokenSwapCash(uint256 _pegTokenAmount, address[] _assets, uint256[] _amounts);

    /// @notice Version of vault
    function getVersion() external pure returns (string memory);

    /// @notice Minting USDi supported assets
    function getSupportAssets() external view returns (address[] memory _assets);

    /// @notice Check '_asset' is supported or not
    function checkIsSupportAsset(address _asset) external view;

    /// @notice Assets held by Vault
    function getTrackedAssets() external view returns (address[] memory _assets);

    /// @notice Vault holds asset value directly in USD
    function valueOfTrackedTokens() external view returns (uint256 _totalValue);

    /// @notice Vault and vault buffer holds asset value directly in USD
    function valueOfTrackedTokensIncludeVaultBuffer() external view returns (uint256 _totalValue);

    /// @notice Vault total asset in USD
    function totalAssets() external view returns (uint256);

    /// @notice Vault and vault buffer total asset in USD
    function totalAssetsIncludeVaultBuffer() external view returns (uint256);

    /// @notice Vault total value(by chainlink price) in USD(1e18)
    function totalValue() external view returns (uint256);

    /// @notice Start adjust position
    function startAdjustPosition() external;

    /// @notice End adjust position
    function endAdjustPosition() external;

    /// @notice Return underlying token per share token
    function underlyingUnitsPerShare() external view returns (uint256);

    /// @notice Get pegToken price in USD(1e18)
    function getPegTokenPrice() external view returns (uint256);

    /**
     * @dev Internal to calculate total value of all assets held in Vault.
     * @return _value Total value(by chainlink price) in USD (1e18)
     */
    function totalValueInVault() external view returns (uint256 _value);

    /**
     * @dev Internal to calculate total value of all assets held in Strategies.
     * @return _value Total value(by chainlink price) in USD (1e18)
     */
    function totalValueInStrategies() external view returns (uint256 _value);

    /// @notice Return all strategy addresses
    function getStrategies() external view returns (address[] memory _strategies);

    /// @notice Check '_strategy' is active or not
    function checkActiveStrategy(address _strategy) external view;

    /// @notice estimate Minting share with stablecoins
    /// @param _assets Address of the asset being deposited
    /// @param _amounts Amount of the asset being deposited
    /// @dev Support single asset or multi-assets
    /// @return _shareAmount
    function estimateMint(address[] memory _assets, uint256[] memory _amounts)
        external
        view
        returns (uint256 _shareAmount);

    /// @notice Minting share with stablecoins
    /// @param _assets Address of the asset being deposited
    /// @param _amounts Amount of the asset being deposited
    /// @dev Support single asset or multi-assets
    /// @return _shareAmount
    function mint(
        address[] memory _assets,
        uint256[] memory _amounts,
        uint256 _minimumAmount
    ) external returns (uint256 _shareAmount);

    /// @notice burn USDi,return stablecoins
    /// @param _amount Amount of USDi to burn
    /// @param _minimumAmount Minimum usd to receive in return
    function burn(uint256 _amount, uint256 _minimumAmount)
        external
        returns (address[] memory _assets, uint256[] memory _amounts);

    /// @notice Change USDi supply with Vault total assets.
    function rebase() external;

    /// @notice Allocate funds in Vault to strategies.
    function lend(address _strategy, IExchangeAggregator.ExchangeToken[] calldata _exchangeTokens)
        external;

    /// @notice Withdraw the funds from specified strategy.
    function redeem(
        address _strategy,
        uint256 _amount,
        uint256 _outputCode
    ) external;

    /**
     * @dev Exchange from '_fromToken' to '_toToken'
     * @param _fromToken The token swap from
     * @param _toToken The token swap to
     * @param _amount The amount to swap
     * @param _exchangeParam The struct of ExchangeParam, see {ExchangeParam} struct
     * @return _exchangeAmount The real amount to exchange
     * Emits a {Exchange} event.
     */
    function exchange(
        address _fromToken,
        address _toToken,
        uint256 _amount,
        IExchangeAggregator.ExchangeParam memory _exchangeParam
    ) external returns (uint256);

    /**
     * @dev Report the current asset of strategy caller
     * @param _rewardTokens The reward token list
     * @param _claimAmounts The claim amount list
     * Emits a {StrategyReported} event.
     */
    function report(address[] memory _rewardTokens, uint256[] memory _claimAmounts) external;

    /// @notice Shutdown the vault when an emergency occurs, cannot mint/burn.
    function setEmergencyShutdown(bool _active) external;

    /// @notice set adjustPositionPeriod true when adjust position occurs, cannot remove add asset/strategy and cannot mint/burn.
    function setAdjustPositionPeriod(bool _adjustPositionPeriod) external;

    /**
     * @dev Set a minimum difference ratio automatically rebase.
     * rebase
     * @param _threshold _threshold is the numerator and the denominator is 10000000 (x/10000000).
     */
    function setRebaseThreshold(uint256 _threshold) external;

    /**
     * @dev Set a fee in basis points to be charged for a redeem.
     * @param _redeemFeeBps Basis point fee to be charged
     */
    function setRedeemFeeBps(uint256 _redeemFeeBps) external;

    /**
     * @dev Sets the treasuryAddress that can receive a portion of yield.
     *      Setting to the zero address disables this feature.
     */
    function setTreasuryAddress(address _address) external;

    /**
     * @dev Sets the exchangeManagerAddress that can receive a portion of yield.
     */
    function setExchangeManagerAddress(address _exchangeManagerAddress) external;

    /**
     * @dev Sets the TrusteeFeeBps to the percentage of yield that should be
     *      received in basis points.
     */
    function setTrusteeFeeBps(uint256 _basis) external;

    /// @notice set '_queues' as advance withdrawal queue
    function setWithdrawalQueue(address[] memory _queues) external;

    function setStrategyEnforceChangeLimit(address _strategy, bool _enabled) external;

    function setStrategySetLimitRatio(
        address _strategy,
        uint256 _lossRatioLimit,
        uint256 _profitLimitRatio
    ) external;

    /**
     * @dev Set the deposit paused flag to true to prevent rebasing.
     */
    function pauseRebase() external;

    /**
     * @dev Set the deposit paused flag to true to allow rebasing.
     */
    function unpauseRebase() external;

    /// @notice Added support for specific asset.
    function addAsset(address _asset) external;

    /// @notice Remove support for specific asset.
    function removeAsset(address _asset) external;

    /// @notice Add strategy to strategy list
    /// @dev The strategy added to the strategy list,
    ///      Vault may invest funds into the strategy,
    ///      and the strategy will invest the funds in the 3rd protocol
    function addStrategy(StrategyAdd[] memory _strategyAdds) external;

    /// @notice Remove strategy from strategy list
    /// @dev The removed policy withdraws funds from the 3rd protocol and returns to the Vault
    function removeStrategy(address[] memory _strategies) external;

    function forceRemoveStrategy(address _strategy) external;

    /***************************************
                     WithdrawalQueue
     ****************************************/
    function getWithdrawalQueue() external view returns (address[] memory);

    function removeStrategyFromQueue(address[] memory _strategies) external;

    /// @notice Return the period of adjust position
    function adjustPositionPeriod() external view returns (bool);

    /// @notice Return the status of emergency shutdown switch
    function emergencyShutdown() external view returns (bool);

    /// @notice Return the status of rebase paused switch
    function rebasePaused() external view returns (bool);

    /// @notice Return the rebaseThreshold value,
    /// over this difference ratio automatically rebase.
    /// rebaseThreshold is the numerator and the denominator is 10000000 x/10000000.
    function rebaseThreshold() external view returns (uint256);

    /// @notice Return the Amount of yield collected in basis points
    function trusteeFeeBps() external view returns (uint256);

    /// @notice Return the redemption fee in basis points
    function redeemFeeBps() external view returns (uint256);

    /// @notice Return the total asset of all strategy
    function totalDebt() external view returns (uint256);

    /// @notice Return the exchange manager address
    function exchangeManager() external view returns (address);

    /// @notice Return all info of '_strategy'
    function strategies(address _strategy) external view returns (StrategyParams memory);

    /// @notice Return withdraw strategy address list
    function withdrawQueue() external view returns (address[] memory);

    /// @notice Return the address of treasury
    function treasury() external view returns (address);

    /// @notice Return the address of price oracle
    function valueInterpreter() external view returns (address);

    /// @notice Return the address of access control proxy contract
    function accessControlProxy() external view returns (address);

    /// @notice Set the minimum strategy total debt that will be checked for the strategy reporting
    function setMinCheckedStrategyTotalDebt(uint256 _minCheckedStrategyTotalDebt) external;

    /// @notice Return the minimum strategy total debt that will be checked for the strategy reporting
    function minCheckedStrategyTotalDebt() external view returns (uint256);

    /// @notice Set the maximum timestamp between two reported
    function setMaxTimestampBetweenTwoReported(uint256 _maxTimestampBetweenTwoReported) external;

    /// @notice The maximum timestamp between two reported
    function maxTimestampBetweenTwoReported() external view returns (uint256);

    /// @notice Set the minimum investment amount
    function setMinimumInvestmentAmount(uint256 _minimumInvestmentAmount) external;

    /// @notice Return the minimum investment amount
    function minimumInvestmentAmount() external view returns (uint256);

    /// @notice Set the address of vault buffer contract
    function setVaultBufferAddress(address _address) external;

    /// @notice Return the address of vault buffer contract
    function vaultBufferAddress() external view returns (address);

    /// @notice Set the address of PegToken contract
    function setPegTokenAddress(address _address) external;

    /// @notice Return the address of PegToken contract
    function pegTokenAddress() external view returns (address);

    /// @notice Set the new implement contract address
    function setAdminImpl(address _newImpl) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

import "./IExchangeAdapter.sol";

interface IExchangeAggregator {
    /**
     * @param platform Called exchange platforms
     * @param method The method of the exchange platform
     * @param encodeExchangeArgs The encoded parameters to call
     * @param slippage The slippage when exchange
     * @param oracleAdditionalSlippage The additional slippage for oracle estimated
     */
    struct ExchangeParam {
        address platform;
        uint8 method;
        bytes encodeExchangeArgs;
        uint256 slippage;
        uint256 oracleAdditionalSlippage;
    }

    /**
     * @param platform Called exchange platforms
     * @param method The method of the exchange platform
     * @param data The encoded parameters to call
     * @param swapDescription swap info
     */
    struct SwapParam {
        address platform;
        uint8 method;
        bytes data;
        IExchangeAdapter.SwapDescription swapDescription;
    }

    /**
     * @param srcToken The token swap from
     * @param dstToken The token swap to
     * @param amount The amount to swap
     * @param exchangeParam The struct of ExchangeParam
     */
    struct ExchangeToken {
        address fromToken;
        address toToken;
        uint256 fromAmount;
        ExchangeParam exchangeParam;
    }

    event ExchangeAdapterAdded(address[] _exchangeAdapters);

    event ExchangeAdapterRemoved(address[] _exchangeAdapters);

    event Swap(
        address _platform,
        uint256 _amount,
        address _srcToken,
        address _dstToken,
        uint256 _exchangeAmount,
        address indexed _receiver,
        address _sender
    );

    function swap(
        address _platform,
        uint8 _method,
        bytes calldata _data,
        IExchangeAdapter.SwapDescription calldata _sd
    ) external payable returns (uint256);

    function batchSwap(SwapParam[] calldata _swapParams) external payable returns (uint256[] memory);

    function getExchangeAdapters()
        external
        view
        returns (address[] memory _exchangeAdapters, string[] memory _identifiers);

    function addExchangeAdapters(address[] calldata _exchangeAdapters) external;

    function removeExchangeAdapters(address[] calldata _exchangeAdapters) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity >=0.6.0 <0.9.0;
pragma experimental ABIEncoderV2;

interface IExchangeAdapter {
    /**
     * @param amount The amount to swap
     * @param srcToken The token swap from
     * @param dstToken The token swap to
     * @param receiver The user to receive `dstToken`
     */
    struct SwapDescription {
        uint256 amount;
        address srcToken;
        address dstToken;
        address receiver;
    }

    /// @notice The identifier of this exchange adapter
    function identifier() external pure returns (string memory _identifier);

    /**
     * @notice Swap with `_sd` data by using `_method` and `_data` on `_platform`.
     * @param _method The method of the exchange platform
     * @param _encodedCallArgs The encoded parameters to call
     * @param _sd The description info of this swap
     * @return The expected amountIn to swap
     */
    function swap(
        uint8 _method,
        bytes calldata _encodedCallArgs,
        SwapDescription calldata _sd
    ) external payable returns (uint256);
}