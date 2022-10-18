// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.16;

/**
 * @title AssetManagement
 * @author @InsureDAO
 * @notice InsureDAO's Depeg insurance management of protocol assets and lending protocols.
 **/
import {IAaveV3Pool, IAaveV3Reward, IManagerParameters, IAssetManagement, IMigrationAsset, IExchangeLogic, IMarket} from "../interfaces/AllInterfaces.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../securities/AbstractOwner.sol";
import "../twaps/ChainlinkTwap.sol";
import "../libs/ERC20Decimals.sol";
import "../libs/AaveFlashLoanBase.sol";

// import "forge-std/console2.sol";

contract AssetManagement is IAssetManagement, AbstractOwner, AaveFlashLoanBase {
    using SafeERC20 for IERC20;

    /**
     * Storage
     */
    //internal multiplication scale 1e8 to reduce decimal truncation
    uint256 private constant MAGIC_SCALE_1E8 = 1e8;
    uint256 private constant FLASH_LOAN_SCALE_1E4 = 1e4;

    uint8 private constant OPERATION_TYPE_UTILIZE = 0;
    uint8 private constant OPERATION_TYPE_UNUTILIZE = 1;

    /// @notice External contract call addresses
    IManagerParameters public immutable parameters;
    address public immutable market;

    address public immutable baseToken;
    address public immutable targetToken;
    AaveTokens public aaveTokens;
    IAaveV3Pool public aave;
    IAaveV3Reward public immutable aaveReward;
    address public immutable aaveRewardToken;
    address[] private _rewardPair;
    IExchangeLogic public exchangeLogic;

    /// @notice variables
    uint256 public override originalDebt;
    uint256 public originalSupply;
    uint256 public premiumReserve;
    uint256 public protocolReserve;

    /**
     * Modifiers
     */
    modifier onlyMarket() {
        if (msg.sender != market) revert OnlyMarket();
        _;
    }

    /**
     * Initialize interaction
     */
    constructor(
        address _parameters,
        address _market,
        address _exchangeLogic,
        address _aave,
        address _aaveReward,
        address _aaveRewardToken,
        address _baseToken,
        address _targetToken,
        AaveTokens memory _aaveTokens
    ) {
        baseToken = _baseToken;
        targetToken = _targetToken;
        aaveTokens = _aaveTokens;

        parameters = IManagerParameters(_parameters);
        market = _market;
        _setExchangeLogic(_exchangeLogic);
        _setAave(_aave);
        aaveReward = IAaveV3Reward(_aaveReward);
        _rewardPair.push(_aaveTokens.aBaseToken);
        _rewardPair.push(_aaveTokens.vTargetDebt);
        aaveRewardToken = _aaveRewardToken;
    }

    /**
     * Core Functions
     */
    /// @inheritdoc IAssetManagement
    function addValue(uint256 _amount, address _from) external override onlyMarket {
        // check aave utilization cap
        if (_amount > calcAaveAvailableSupplyUsdc()) revert AaveOccupyTooMuch();

        IERC20(baseToken).safeTransferFrom(_from, address(this), _amount);
        aave.supply(baseToken, _amount, address(this), 0);
        originalSupply += _amount;
    }

    /// @inheritdoc IAssetManagement
    function withdrawValue(uint256 _amount, address _to) external override onlyMarket {
        if (_to == address(0)) revert ZeroAddress();
        if (_amount == 0) revert ZeroAmount();
        if (_amount > getWithdrawable()) revert AmmountExceeded();

        //withdraw performance fee
        (uint256 principal, uint256 _protocolPerformance, uint256 _underwritersPerformance) = getPerformance();
        uint256 _protocolRevenue = (_amount * _protocolPerformance) / principal;
        if (_protocolRevenue > 0)
            aave.withdraw(baseToken, _protocolRevenue, parameters.getPerformancePool(address(this)));

        uint256 _underwritersRevenue = (_amount * _underwritersPerformance) / principal;
        uint256 _subOriginalSupply = _amount - _underwritersRevenue;
        originalSupply -= _subOriginalSupply;
        aave.withdraw(baseToken, _amount, _to);
    }

    /// @inheritdoc IAssetManagement
    function utilize(
        uint256 _amount,
        uint256 _premium,
        uint256 _protocolFee,
        address _from
    ) external override onlyMarket {
        _utilize(_amount, _premium, _protocolFee, _from);
    }

    function _utilize(
        uint256 _amount,
        uint256 _premium,
        uint256 _protocolFee,
        address _from
    ) private {
        if (_amount == 0) revert ZeroAmount();
        if (_amount > getAvailable()) revert AmmountExceeded();
        if (_amount > calcAaveAvailableBorrow()) revert AaveExceedUtilizationCap();
        _payFees(_premium, _protocolFee, _from);
        //calculate baseToken needed to borrow by flashloan
        uint256 _borrowFlashLoan = _alignDecimalToBase(_amount);
        //flashloan
        bytes memory _params = abi.encode(OPERATION_TYPE_UTILIZE, _amount, _premium);
        callFlashLoan(baseToken, _borrowFlashLoan, _params);
        // record storage
        originalDebt += _amount;
        originalSupply += _borrowFlashLoan;
    }

    /// @inheritdoc IAssetManagement
    function unutilize(uint256 _amount) external override onlyMarket {
        _unutilize(_amount);
    }

    function _unutilize(uint256 _amount) private {
        (
            uint256 _repayAmount,
            uint256 _estimatedBaseTokenAmount,
            uint256 _deductionFromSupply,
            uint256 _interestInBaseToken,

        ) = _calculateRepayInterest(_amount);

        //flashloan
        bytes memory _params = abi.encode(OPERATION_TYPE_UNUTILIZE, _estimatedBaseTokenAmount, _deductionFromSupply);
        callFlashLoan(targetToken, _repayAmount, _params);
        // record storage
        unchecked {
            premiumReserve -= _interestInBaseToken;
        }
        originalSupply -= _deductionFromSupply;
        originalDebt -= _amount;
    }

    /// @inheritdoc IAssetManagement
    function repayAndRedeem(
        uint256 _amount,
        address _from,
        address _redeemToken
    ) external override onlyMarket {
        _repayAndRedeem(_amount, _from);

        uint256 _paybackAmount = _alignDecimalToBase(_amount);
        if (_redeemToken == aaveTokens.aBaseToken) {
            IERC20(aaveTokens.aBaseToken).safeTransfer(_from, _paybackAmount);
        } else if (_redeemToken == address(0) || _redeemToken == baseToken) {
            if (_paybackAmount != aave.withdraw(baseToken, _paybackAmount, address(this))) revert AaveMismatch();
            IERC20(baseToken).safeTransfer(_from, _paybackAmount);
        } else {
            revert UnsupportedRedeemToken();
        }
    }

    function _repayAndRedeem(uint256 _amount, address _from) private {
        IERC20(targetToken).safeTransferFrom(_from, address(this), _amount);

        (
            uint256 _repayAmount,
            ,
            uint256 _deductionFromSupply,
            uint256 _interestInBaseToken,
            uint256 _decuctionFromReserve
        ) = _calculateRepayInterest(_amount);

        //withdraw collateral
        //if _interestInBaseToken cannot be covered by premiumReserve, withdraw exceeded amount(=deduction)
        if (_decuctionFromReserve > 0) aave.withdraw(baseToken, _decuctionFromReserve, address(this));
        //repay
        uint256 _swapped = _swap(baseToken, targetToken, _interestInBaseToken + _decuctionFromReserve);
        if ((_amount + _swapped) < _repayAmount) revert LessSwappedThanEstimated();
        if (_repayAmount != aave.repay(targetToken, _repayAmount, 2, address(this))) revert AaveMismatch();
        // record storage
        unchecked {
            premiumReserve -= _interestInBaseToken;
        }
        originalSupply -= _deductionFromSupply;
        originalDebt -= _amount;
    }

    /// @inheritdoc IAssetManagement
    function payFees(
        uint256 _premium,
        uint256 _protocolFee,
        address _from
    ) external override onlyMarket {
        _payFees(_premium, _protocolFee, _from);
    }

    function _payFees(
        uint256 _premium,
        uint256 _protocolFee,
        address _from
    ) internal {
        IERC20(baseToken).safeTransferFrom(_from, address(this), _premium + _protocolFee);
        protocolReserve += _protocolFee;
        premiumReserve += _premium;
    }

    /// @inheritdoc IAssetManagement
    function cancel(
        uint256 _amount,
        uint256[] memory _params,
        address _to
    ) external override onlyMarket {
        //do something here after updates
    }

    /// @inheritdoc IAssetManagement
    function withdrawReward(uint256 _rewardAmount, address _to) external override onlyMarket {
        if (_to == address(0)) revert ZeroAddress();
        if (_rewardAmount == 0) revert ZeroAmount();
        if (_rewardAmount > getAccruedReward()) revert AmmountExceeded();
        // claim
        aaveReward.claimRewards(_rewardPair, _rewardAmount, _to, aaveRewardToken);
    }

    /**
     * Utilities
     */

    /**
     * @notice calculate baseToken amount to be repaid and interests by shorted position
     * @param _shortAmount short position to unutilize
     * @return _repayAmount amount of targetToken to repay including interest
     * @return _estimatedBaseTokenAmount amount of baseToken to repay debt
     * @return _deductionFromSupply need to withdraw amount of baseToken to repay debt except interest
     * @return _interestInBaseToken amount of baseToken to repay debt interest (filled by premiumReserve)
     * @return _decuctionFromReserve amount of _interestInBaseToken beyond premiumReserve
     */
    function _calculateRepayInterest(uint256 _shortAmount)
        internal
        view
        returns (
            uint256 _repayAmount,
            uint256 _estimatedBaseTokenAmount,
            uint256 _deductionFromSupply,
            uint256 _interestInBaseToken,
            uint256 _decuctionFromReserve
        )
    {
        if (originalDebt == 0) return (0, 0, 0, 0, 0);

        uint256 _debt = IERC20(aaveTokens.vTargetDebt).balanceOf(address(this));
        _repayAmount = (_shortAmount * _debt) / originalDebt;
        // add FlashLoan premium
        uint256 _flashLoanRepay = _repayAmount + _getFlashLoanPremium(_repayAmount);
        _estimatedBaseTokenAmount = exchangeLogic.estimateAmountIn(baseToken, targetToken, _flashLoanRepay);
        _deductionFromSupply = _alignDecimalToBase(_shortAmount);
        if (_estimatedBaseTokenAmount > _deductionFromSupply) {
            // debt interest is to be paid by premiumReserve
            unchecked {
                _interestInBaseToken = _estimatedBaseTokenAmount - _deductionFromSupply;
            }
            if (premiumReserve < _interestInBaseToken) {
                // if debt interest beyond premiumReserve, set deduct amount on _decuctionFromReserve
                unchecked {
                    _decuctionFromReserve = _interestInBaseToken - premiumReserve;
                }
                _interestInBaseToken = premiumReserve;
                //and add deduct amount to withdraw amount
                _deductionFromSupply += _decuctionFromReserve;
            }
        } else {
            // withdrawCollateral less than estimated
            _deductionFromSupply = _estimatedBaseTokenAmount;
        }
    }

    /// @inheritdoc IAssetManagement
    function getPrincipal() public view override returns (uint256) {
        (uint256 _principal, , ) = getPerformance();
        return _principal;
    }

    /// @inheritdoc IAssetManagement
    function getPerformance()
        public
        view
        override
        returns (
            uint256 _principal,
            uint256 _protocolPerformance,
            uint256 _underwritersPerformance
        )
    {
        (, , uint256 _deductionFromSupply, , uint256 _decuctionFromReserve) = _calculateRepayInterest(originalDebt);
        //performance is originally supply interest sub debt interest
        //but debt interest is to be paid by premiumReserve, so calculate only supply's
        //(deduction is beyond premiumReserve)
        uint256 _supply = IERC20(aaveTokens.aBaseToken).balanceOf(address(this));

        // happening only immediately after supplying aave
        if (_supply < originalSupply) _supply = originalSupply;

        if (_supply - originalSupply > _decuctionFromReserve) {
            uint256 _performance = _supply - originalSupply - _decuctionFromReserve;
            _protocolPerformance = (_performance * parameters.getPerformanceFeeRate(address(this))) / MAGIC_SCALE_1E8;
            _underwritersPerformance = _performance - _protocolPerformance;
            _principal = _supply - _protocolPerformance - _deductionFromSupply;
        } else {
            // debt interest more than premiumReserve and supply. no performance fee
            _protocolPerformance = 0;
            _underwritersPerformance = 0;
            _principal = _supply - _deductionFromSupply; // _deductionFromSupply includes deduction
        }
    }

    /// @inheritdoc IAssetManagement
    function getWithdrawable() public view override returns (uint256) {
        uint256 _maxAvailable = getMaxBorrowable() - _alignDecimalToTarget(getPrincipal());
        return (getPrincipal() * getAvailable()) / _maxAvailable;
    }

    /// @inheritdoc IAssetManagement
    function getMaxBorrowable() public view override returns (uint256) {
        return _getBorrowable(getPrincipal());
    }

    function _getBorrowable(uint256 _deposit) private view returns (uint256 _totalBorrow) {
        uint256 _leverage = parameters.getLeverage(address(this));
        for (uint256 i; i < _leverage; i++) {
            uint256 _target = _alignDecimalToTarget(_deposit);
            _totalBorrow += _target;
            uint256 _swapped = exchangeLogic.estimateAmountOut(targetToken, baseToken, _target);
            _deposit = _swapped;
        }
    }

    /// @inheritdoc IAssetManagement
    function getAvailable() public view override returns (uint256) {
        // it happens because maxBorrowable is leveraged subbed borrowing power but originalDebt isn't subbed
        if (getMaxBorrowable() - originalDebt < _alignDecimalToTarget(getPrincipal())) return 0;
        return getMaxBorrowable() - originalDebt - _alignDecimalToTarget(getPrincipal());
    }

    /// @inheritdoc IAssetManagement
    function getAvailableOrAaveAvailable() public view override returns (uint256) {
        uint256 _available = getAvailable();
        uint256 _availableBorrow = calcAaveAvailableBorrow();
        if (_available <= _availableBorrow) {
            return _available;
        } else {
            return _availableBorrow;
        }
    }

    /// @inheritdoc IAssetManagement
    function calcAaveAvailableBorrow() public view override returns (uint256) {
        uint256 _utilization = IERC20(aaveTokens.vTargetDebt).totalSupply() +
            IERC20(aaveTokens.sTargetDebt).totalSupply();
        uint256 _reserve = IERC20(aaveTokens.aTargetToken).totalSupply();
        uint256 _limitedUtilization = (_reserve * parameters.getMaxUtilizationRateAfterBorrow(address(this))) /
            MAGIC_SCALE_1E8;
        if (_limitedUtilization < _utilization) return 0;
        unchecked {
            return _limitedUtilization - _utilization;
        }
    }

    /// @inheritdoc IAssetManagement
    function calcAaveAvailableSupplyUsdc() public view override returns (uint256 avairableSupply) {
        uint256 _reserve = IERC20(aaveTokens.aBaseToken).totalSupply();
        unchecked {
            avairableSupply = (_reserve * parameters.getMaxOccupancyRate(address(this))) / MAGIC_SCALE_1E8;
        }
    }

    /// @inheritdoc IAssetManagement
    function getAccruedReward() public view override returns (uint256) {
        return aaveReward.getUserAccruedRewards(address(this), aaveRewardToken);
    }

    /// @notice inherit AbstractOwner
    function getOwner() public view override returns (address) {
        return parameters.getOwner();
    }

    /**
     * Admin Functions
     */
    /// @inheritdoc IAssetManagement
    function setExchangeLogic(address _exchangeLogic) public override onlyOwner {
        _setExchangeLogic(_exchangeLogic);
    }

    function _setExchangeLogic(address _exchangeLogic) private {
        exchangeLogic = IExchangeLogic(_exchangeLogic);

        // approve targetToken
        address _swapper = exchangeLogic.swapper();
        IERC20(targetToken).safeApprove(_swapper, 0);
        IERC20(targetToken).safeApprove(_swapper, type(uint256).max);
        IERC20(baseToken).safeApprove(_swapper, type(uint256).max);

        emit ExchangeLogic(_exchangeLogic);
    }

    /// @inheritdoc IAssetManagement
    function setAave(address _aave) external override onlyOwner {
        _setAave(_aave);
    }

    function _setAave(address _aave) private {
        aave = IAaveV3Pool(_aave);
        IERC20(targetToken).safeApprove(_aave, 0);
        IERC20(targetToken).safeApprove(_aave, type(uint256).max);
        IERC20(baseToken).safeApprove(_aave, type(uint256).max);

        //emode
        aave.setUserEMode(1);

        emit Aave(_aave);
    }

    /// @inheritdoc IAssetManagement
    function withdrawRedundant(address _token, address _to) external override onlyOwner {
        if (_token == aaveTokens.aBaseToken || _token == aaveRewardToken || _token == targetToken)
            revert NonWithdrawableToken();

        uint256 _tokenBalance = IERC20(_token).balanceOf(address(this));
        if (_token == baseToken) {
            uint256 _reserve = premiumReserve + protocolReserve;
            if (_tokenBalance <= _reserve) revert ExceedReserved();
            uint256 _redundant;
            unchecked {
                _redundant = _tokenBalance - _reserve;
            }
            IERC20(_token).safeTransfer(_to, _redundant);
        } else {
            if (_tokenBalance == 0) revert ZeroBalance();
            IERC20(_token).safeTransfer(_to, _tokenBalance);
        }
    }

    /// @inheritdoc IAssetManagement
    function supplyRedundantTargetToken() external override onlyOwner returns (uint256 _supplyed) {
        uint256 _amountIn = IERC20(targetToken).balanceOf(address(this));
        _supplyed = _swap(targetToken, baseToken, _amountIn);
        aave.supply(baseToken, _supplyed, address(this), 0);
    }

    /// @inheritdoc IAssetManagement
    function withdrawProtocolReserve(address _to) external override onlyOwner {
        if (protocolReserve > 0) {
            IERC20(baseToken).safeTransfer(_to, protocolReserve);
            protocolReserve = 0;
        }
    }

    /**
     * Migration Functions
     */

    /// @inheritdoc IMigrationAsset
    function immigrate(
        uint256 _principal,
        uint256 _premiumReserve,
        uint256 _shortPosition,
        uint256 _deposit,
        address[] calldata _references,
        uint256[] calldata _params
    ) external override {
        // This implemetation is an example.

        // check if the caller is legit
        if (msg.sender != address(IMarket(market).manager())) revert OnlyFromManager();

        address _fromManager = address(IMarket(market).manager());
        IERC20(aaveTokens.aBaseToken).safeTransferFrom(
            _fromManager,
            address(this),
            IERC20(aaveTokens.aBaseToken).balanceOf(_fromManager)
        );
        originalSupply += _deposit;

        // reconstcut the position. This operation may differ in another contract.
        _utilize(_shortPosition, _premiumReserve, _params[0], _references[1]);
        IERC20(baseToken).safeTransferFrom(_fromManager, address(this), IERC20(baseToken).balanceOf(_fromManager));
        emit Immigration(_fromManager, _principal, premiumReserve, _shortPosition, _references, _params);
    }

    /// @inheritdoc IMigrationAsset
    // _references[0]: rewardPool's address
    // _references[1]: the address pays premium(=this address)
    // _params[0]: protocolFee
    function emigrate(
        address _to,
        address[] calldata _references,
        uint256[] calldata _params
    ) external override onlyMarket {
        // know current positon
        uint256 _principal = getPrincipal();
        uint256 _originalDebt = originalDebt;
        // clear the positon
        _unutilize(_originalDebt);
        // claim reward
        aaveReward.claimRewards(_rewardPair, getAccruedReward(), _references[0], aaveRewardToken);
        // export the assets
        IERC20(baseToken).safeApprove(_to, 0);
        IERC20(baseToken).safeApprove(_to, type(uint256).max);
        IERC20(aaveTokens.aBaseToken).safeApprove(_to, 0);
        IERC20(aaveTokens.aBaseToken).safeApprove(_to, type(uint256).max);
        // migrate the positon
        IMigrationAsset(_to).immigrate(_principal, premiumReserve, _originalDebt, originalSupply, _references, _params);
        emit Emigration(_to, _principal, premiumReserve, _originalDebt, _references, _params);
    }

    /**
     * Internal Functions
     */

    /***
     *@notice token exchange
     *@param _tokenIn address of token to be used for exchange
     *@param _tokenOut address of token to get
     *@param _amountIn amount of a token for exchange of another token
     */
    function _swap(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn
    ) internal returns (uint256) {
        (bool success, bytes memory result) = exchangeLogic.swapper().call(
            exchangeLogic.abiEncodeSwap(_tokenIn, _tokenOut, _amountIn, 0, address(this))
        );
        if (!success) revert SwapFailed();
        uint256 _swapped = abi.decode(result, (uint256));
        //slippage check
        uint256 _amountOut = ERC20Decimals.alignDecimal(_tokenIn, _tokenOut, _amountIn);
        uint256 _amountOutMin = (_amountOut * parameters.getSlippageTolerance(address(this))) / MAGIC_SCALE_1E8;
        if (_swapped < _amountOutMin) {
            revert BeyondSlippageTolerance();
        }
        return _swapped;
    }

    ///@notice ERC20Decimals functions
    function _alignDecimalToTarget(uint256 _amount) internal view returns (uint256) {
        return ERC20Decimals.alignDecimal(baseToken, targetToken, _amount);
    }

    function _alignDecimalToBase(uint256 _amount) internal view returns (uint256) {
        return ERC20Decimals.alignDecimal(targetToken, baseToken, _amount);
    }

    /**
     * FlashLoan
     */
    //unused
    function ADDRESSES_PROVIDER() external view override returns (IPoolAddressesProvider) {}

    function POOL() public view override returns (IAaveV3Pool) {
        return aave;
    }

    ///@notice get FlashLoans premium by aave
    function _getFlashLoanPremium(uint256 _borrow) internal view returns (uint256) {
        return (_borrow * aave.FLASHLOAN_PREMIUM_TOTAL()) / FLASH_LOAN_SCALE_1E4;
    }

    /**
     * @notice call AaveFlashLoanBase's function
     * @param _asset The address of the flash-borrowed asset
     * @param _amount The amount of the flash-borrowed asset
     * @param _params The byte-encoded params passed when initiating the flashloan
     */
    function callFlashLoan(
        address _asset,
        uint256 _amount,
        bytes memory _params
    ) internal {
        _callFlashLoan(address(this), _asset, _amount, _params, 0);
    }

    /**
     * @notice executed in AaveFlashLoanBase's after receiving the flash-loan
     * @param _amount The amount of the flash-borrowed asset
     * @param _premium The fee of the flash-borrowed asset
     * @param _params first param is uint8 _operationType
     */
    function _executeOperation(
        address,
        uint256 _amount,
        uint256 _premium,
        address,
        bytes calldata _params
    ) internal override {
        uint8 _operationType = abi.decode(_params, (uint8));
        if (_operationType == OPERATION_TYPE_UTILIZE) {
            // utilize
            _operateUtilize(_amount, _premium, _params);
        } else if (_operationType == OPERATION_TYPE_UNUTILIZE) {
            //unutilize
            _operateUnutilize(_amount, _premium, _params);
        }
    }

    /**
     * @notice executes utilize in flash-loan
     * @param _amount The amount of the flash-borrowed asset(=baseToken)
     * @param _premium The fee of the flash-borrowed asset
     * @param _params encoded (uint8 _operationType, uint256 _shortAmount, uint256 _premiumPayment: paid premium by insurer)
     */
    function _operateUtilize(
        uint256 _amount,
        uint256 _premium,
        bytes calldata _params
    ) internal {
        (, uint256 _shortAmount, uint256 _premiumPayment) = abi.decode(_params, (uint8, uint256, uint256));
        // make leveraged position
        aave.supply(baseToken, _amount, address(this), 0);
        aave.borrow(targetToken, _shortAmount, 2, 0, address(this));
        uint256 _swapped = _swap(targetToken, baseToken, _shortAmount);
        // compensate flashLoan's premium and swapping slippage by premiumReserve
        if (_amount + _premium > _swapped) {
            uint256 _fillAmount = _amount + _premium - _swapped;
            if (_premiumPayment < _fillAmount) revert LackOfPremium();
            unchecked {
                premiumReserve -= _fillAmount;
            }
        } else {
            unchecked {
                premiumReserve += _swapped - (_amount + _premium);
            }
        }
    }

    /**
     * @notice executes unutilize in flash-loan
     * @param _amount The amount of the flash-borrowed asset(=targetToken)
     * @param _premium The fee of the flash-borrowed asset
     * @param _params encoded (uint8 _operationType, uint256 _estimatedBaseTokenAmount, uint256 _deductionFromSupply)
     */
    function _operateUnutilize(
        uint256 _amount,
        uint256 _premium,
        bytes calldata _params
    ) internal {
        (, uint256 _estimatedBaseTokenAmount, uint256 _deductionFromSupply) = abi.decode(
            _params,
            (uint8, uint256, uint256)
        );
        if (_amount != aave.repay(targetToken, _amount, 2, address(this))) revert AaveMismatch();
        //withdraw collateral
        aave.withdraw(baseToken, _deductionFromSupply, address(this));
        //repay
        uint256 _swapped = _swap(baseToken, targetToken, _estimatedBaseTokenAmount);
        if (_swapped < _amount + _premium) revert LessSwappedThanEstimated();
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;
/**
 * @title AbstractOwner
 * @author @InsureDAO
 * @notice InsureDAO's Depeg insurance access management of owner
 **/
abstract contract AbstractOwner {
    error OnlyOwner();

    modifier onlyOwner() {
        if (getOwner() != msg.sender) revert OnlyOwner();
        _;
    }

    function getOwner() public virtual returns(address);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import {IAaveV3Pool} from "./IAaveV3Pool.sol";
import {IAaveV3Reward} from "./IAaveV3Reward.sol";
import {IAssetManagement} from "./IAssetManagement.sol";
import {IExchangeLogic} from "./IExchangeLogic.sol";
import {IFungibleInitializer} from "./IFungibleInitializer.sol";
import {IFungiblePolicy} from "./IFungiblePolicy.sol";
import {IManagerParameters} from "./IManagerParameters.sol";
import {IMarket} from "./IMarket.sol";
import {IMarketParameters} from "./IMarketParameters.sol";
import {IMarketVolatility} from "./IMarketVolatility.sol";
import {IMigrationAsset} from "./IMigrationAsset.sol";
import {IOwnership} from "./IOwnership.sol";
import {IPlatypusPool} from "./IPlatypusPool.sol";
import {IPolicyFactory} from "./IPolicyFactory.sol";
import {IRefundModel} from "./IRefundModel.sol";
import {IPremiumModel} from "./IPremiumModel.sol";
import {IRewardPool} from "./IRewardPool.sol";
// import {ITwapOracle} from "./ITwapOracle.sol";

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IAaveV3Pool} from "../interfaces/IAaveV3Pool.sol";
import {IFlashLoanSimpleReceiver} from "../interfaces/IFlashLoanSimpleReceiver.sol";
import {IPoolAddressesProvider} from "../interfaces/IPoolAddressesProvider.sol";

// import "forge-std/console2.sol";

abstract contract AaveFlashLoanBase is IFlashLoanSimpleReceiver {
    using SafeERC20 for IERC20;

    /// @notice errors
    error OnlyPool(address _sender);
    error OnlyCaller(address _initiator);
    error FlashLoanLackOfBalance();

    /// @notice inherit IFlashLoanSimpleReceiver
    function ADDRESSES_PROVIDER() external view virtual returns (IPoolAddressesProvider);

    /// @notice inherit IFlashLoanSimpleReceiver
    function POOL() public view virtual returns (IAaveV3Pool);

    /**
     * @notice call Aave flash loan simple
     * @param _receiverAddress The address of the flash-borrowed asset
     * @param _asset The address of the flash-borrowed asset
     * @param _amount The amount of the flash-borrowed asset
     * @param _params The byte-encoded params passed when initiating the flashloan
     * @param _referralCode Code used to register the integrator originating the operation, for potential rewards (maybe 0)
     */
    function _callFlashLoan(
        address _receiverAddress,
        address _asset,
        uint256 _amount,
        bytes memory _params,
        uint16 _referralCode
    ) internal {
        POOL().flashLoanSimple(_receiverAddress, _asset, _amount, _params, _referralCode);
    }

    function _executeOperation(
        address _asset,
        uint256 _amount,
        uint256 _premium,
        address _initiator,
        bytes calldata _params
    ) internal virtual;

    /// @notice inherit IFlashLoanSimpleReceiver
    function executeOperation(
        address _asset,
        uint256 _amount,
        uint256 _premium,
        address _initiator,
        bytes calldata _params
    ) external override returns (bool) {
        if (msg.sender != address(POOL())) revert OnlyPool(msg.sender);
        if (_initiator != address(this)) revert OnlyCaller(_initiator);

        _executeOperation(_asset, _amount, _premium, _initiator, _params);

        if (IERC20(_asset).allowance(address(this), address(POOL())) < _amount + _premium) {
            IERC20(_asset).safeApprove(address(POOL()), _amount + _premium);
        }
        if (IERC20(_asset).balanceOf(address(this)) < _amount + _premium) revert FlashLoanLackOfBalance();
        return true;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

interface IERC20Decimals {
    function decimals() external view returns (uint256);
}

/**
 * @title ERC20Decimals
 * @author @InsureDAO
 * @notice InsureDAO's ERC20 decimals aligner
 **/
library ERC20Decimals {
    /**
     * @notice align decimal from tokenIn decimal to tokenOut's
     * @param _tokenIn input address
     * @param _tokenOut output address
     * @param _amount amount of _tokenIn's decimal
     * @return _amountOut decimal aligned amount
     */
    function alignDecimal(
        address _tokenIn,
        address _tokenOut,
        uint256 _amount
    ) external view returns (uint256) {
        return alignDecimal(IERC20Decimals(_tokenIn).decimals(), IERC20Decimals(_tokenOut).decimals(), _amount);
    }

    /**
     * @notice align decimal from tokenIn decimal to tokenOut's by decimal value
     * @param _decimalsIn input decimal
     * @param _decimalsOut output decimal
     * @param _amount amount of _decimalsIn
     * @return _amountOut decimal aligned amount
     */
    function alignDecimal(
        uint256 _decimalsIn,
        uint256 _decimalsOut,
        uint256 _amount
    ) public pure returns (uint256) {
        uint256 _decimals;
        if (_decimalsIn == _decimalsOut) {
            return _amount;
        } else if (_decimalsIn > _decimalsOut) {
            unchecked {
                _decimals = _decimalsIn - _decimalsOut;
            }
            return _amount / (10**_decimals);
        } else {
            unchecked {
                _decimals = _decimalsOut - _decimalsIn;
            }
            return _amount * (10**_decimals);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

import "./ChainlinkRoundIdFetcher.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV2V3Interface.sol";

// import "forge-std/console2.sol";

/**
 * @title ChainlinkTwap
 * @author @InsureDAO
 * @notice InsureDAO's Depeg insurance twap for chainlink oracle
 **/
library ChainlinkTwap {
    error RoundNotComplete();
    error FrequencyTooLow();

    /**
     * @notice returns price by timestamp
     * @param _feed address of price feed
     * @param _timestamp timestamp
     * @return _price spot price
     */
    function getHistoricalPrice(AggregatorV2V3Interface _feed, uint256 _timestamp) public view returns (uint256) {
        uint80 _roundId = ChainlinkRoundIdFetcher.getRoundId(_feed, _timestamp);
        (, int256 _price, , uint256 _updatedAt, ) = _feed.getRoundData(_roundId);
        if (_updatedAt == 0) revert RoundNotComplete();
        return uint256(_price);
    }

    /**
     * @notice returns latest price
     * @param _feed address of price feed
     * @return _price spot price
     */
    function getLatestPrice(AggregatorV2V3Interface _feed) public view returns (uint256) {
        int256 _latestPrice = _feed.latestAnswer();
        return uint256(_latestPrice);
    }

    /**
     * Returns TWAP price for a specified span.
     */
    /**
     * @notice returns twap price of target currency set by parameters
     * @param _feed address of price feed
     * @param _length twap length
     * @param _frequency number of twap price points within length
     * @return _twap twap price
     */
    function getTwap(
        AggregatorV2V3Interface _feed,
        uint256 _length,
        uint256 _frequency
    ) public view returns (uint256) {
        if (_length == 0) return getLatestPrice(_feed);
        if (_frequency < 2) revert FrequencyTooLow();

        // get start and end price
        (, int256 _latestPrice, , uint256 _latestUpdatedAt, ) = _feed.latestRoundData();
        uint256 _oldestTimestamp = _latestUpdatedAt - _length;
        uint256 _oldestPrice = getHistoricalPrice(_feed, _oldestTimestamp);

        // calculate cumlative price while getting price between start and end
        uint256 _cumlativePrice = uint256(_latestPrice) + _oldestPrice;
        uint256 _remainingFrequency = _frequency - 2; // deduct start and end
        uint256 _span = _length / (_frequency - 1);
        uint256 _targetTimestamp = _oldestTimestamp + _span;
        for (uint256 i; i < _remainingFrequency; ) {
            _cumlativePrice += getHistoricalPrice(_feed, _targetTimestamp);
            _targetTimestamp += _span;
            unchecked {
                i++;
            }
        }
        // calculate twap
        return _cumlativePrice / _frequency;
    }

    /**
     * @notice returns frequency
     * @param _length twap length
     * @param _span time span of next price points
     * @return _frequency frequency
     */
    function calcFrequency(uint256 _length, uint256 _span) external pure returns (uint256) {
        uint256 _frequency = _length / _span;
        return _frequency + 2;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

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
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
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
        IERC20 token,
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
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./IMigrationAsset.sol";

/**
 * @title IAssetManagement
 * @author @InsureDAO
 * @notice Defines the basic interface for an InsureDAO Asset Management.
 **/
interface IAssetManagement is IMigrationAsset {
    /**
     * STRUCTS
     */
    ///@notice aave tokens
    struct AaveTokens {
        address aBaseToken;
        address aTargetToken;
        address vTargetDebt;
        address sTargetDebt;
    }
    struct Performance {
        int256 lastUnderwriterFee;
        uint256 withdrawableProtocolFee;
    }

    /**
     * EVENTS
     */
    event ExchangeLogic(address exchangeLogic);
    event Aave(address _aave);

    /**
     * FUNCTIONS
     */

    /**
     * @notice A market contract can deposit collateral and get attribution point in return
     * @param  _amount amount of tokens to deposit
     * @param _from sender's address
     */
    function addValue(uint256 _amount, address _from) external;

    /**
     * @notice an address that has balance in the vault can withdraw underlying value
     * @param _amount amount of tokens to withdraw
     * @param _to address to get underlying tokens
     */
    function withdrawValue(uint256 _amount, address _to) external;

    /**
     * @notice apply leverage and create position of depeg coverage. used when insure() is called
     * @param _amount amount of USDT position
     * @param _premium premium amount
     * @param _protocolFee fee amount
     * @param _from who pays fees
     */
    function utilize(
        uint256 _amount,
        uint256 _premium,
        uint256 _protocolFee,
        address _from
    ) external;

    /**
     * @notice dissolve and deleverage positions
     * @param _amount amount to unutilize
     */
    function unutilize(uint256 _amount) external;

    /**
     * @notice unutilize and pay premium back
     * @param _amount amount to unutilize
     * @param _params parameters
     * @param _to address to get premium back
     */
    function cancel(
        uint256 _amount,
        uint256[] memory _params,
        address _to
    ) external;

    /**
     * @notice repay USDT debt and redeem USDC. Expected to be used when depeg happend.
     * @param _amount amount to redeem
     * @param _from redeem destination
     */
    function repayAndRedeem(
        uint256 _amount,
        address _from,
        address _redeemToken
    ) external;

    /**
     * @notice pay fees. Expected to use when extend the position holding length.
     * @param _premium premium amount
     * @param _protocolFee fee amount
     * @param _from who pays fees
     */
    function payFees(
        uint256 _premium,
        uint256 _protocolFee,
        address _from
    ) external;

    /**
     * @notice withdraw Aave's accrued reward tokens
     * @param _rewardAmount market's receipient amount
     * @param _to receipient of reward
     */
    function withdrawReward(uint256 _rewardAmount, address _to) external;

    /**
     * @notice get debt amount without interest
     */
    function originalDebt() external view returns (uint256);

    /**
     * @notice get principal value in USDC.
     */
    function getPrincipal() external view returns (uint256);

    /**
     * @notice get the latest status of performance and principal
     */
    function getPerformance()
        external
        view
        returns (
            uint256 _principal,
            uint256 _protocolPerformance,
            uint256 _underwritersPerformance
        );

    /**
     * @notice get how much can one withdraw USDC.
     */
    function getWithdrawable() external view returns (uint256);

    /**
     * @notice get maximum USDT short positions can be hold in the contract.
     */
    function getMaxBorrowable() external view returns (uint256);

    /**
     * @notice get how much USDT short positions can be hold in the contract.
     */
    function getAvailable() external view returns (uint256);

    /**
     * @notice avairable for deposit USDC within aave max utilization(USDT borrowable).
     */
    function getAvailableOrAaveAvailable() external view returns (uint256);

    /**
     * @notice get how much usdt short position can be taken safely from this account.
     * maxUtilizationRateAfterBorrow prevents borrwing too much and increase utilization beyond allowance.
     */
    function calcAaveAvailableBorrow() external view returns (uint256 avairableBorrow);

    /**
     * @notice get how much usdc deposit position can be taken safely from this account.
     * maxOccupancyRate prevents supplying too much
     */
    function calcAaveAvailableSupplyUsdc() external view returns (uint256 avairableSupply);

    /**
     * @notice get Aave's accrured rewards
     */
    function getAccruedReward() external view returns (uint256);

    /**
     * @notice set exchangeLogic and approve it
     * @param _exchangeLogic exchangeLogic
     */
    function setExchangeLogic(address _exchangeLogic) external;

    /**
     * @notice set aave lending pool address and approve it
     * @param _aave aave lending pool address
     */
    function setAave(address _aave) external;

    /**
     * @notice withdraw redundant token stored in this contract
     * @param _token token address
     * @param _to beneficiary's address
     */
    function withdrawRedundant(address _token, address _to) external;

    /**
     * @notice swap redundant targetToken and supply it
     */
    function supplyRedundantTargetToken() external returns (uint256 _supplyed);

    /**
     * @notice withdraw accrued protocol fees.
     * @param _to withdrawn fee destination
     */
    function withdrawProtocolReserve(address _to) external;

    /**
     * ERRORS
     */
    error OnlyMarket();
    error ZeroAddress();
    error AmmountExceeded();
    error LackOfPremium();
    error AaveMismatch();
    error AaveExceedUtilizationCap();
    error AaveOccupyTooMuch();
    error UnsupportedRedeemToken();
    error LessSwappedThanEstimated();
    error ExceedReserved();
    error ZeroBalance();
    error NonWithdrawableToken();
    error ZeroAmount();
    error SwapFailed();
    error BeyondSlippageTolerance();
    error LackOfOriginalSupply();
}

// SPDX-License-Identifier: AGPL-3.0
// Forked and minimized from https://github.com/aave/aave-v3-core/blob/master/contracts/interfaces/IPool.sol
pragma solidity ^0.8.0;

/**
 * @title IPool
 * @author Aave
 * @notice Defines the basic interface for an Aave Pool.
 **/
interface IAaveV3Pool {
    /**
     * @notice Supplies an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
     * - E.g. User supplies 100 USDC and gets in return 100 aUSDC
     * @param asset The address of the underlying asset to supply
     * @param amount The amount to be supplied
     * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
     *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
     *   is a different wallet
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     **/
    function supply(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    /**
     * @notice Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
     * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
     * @param asset The address of the underlying asset to withdraw
     * @param amount The underlying amount to be withdrawn
     *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
     * @param to The address that will receive the underlying, same as msg.sender if the user
     *   wants to receive it on his own wallet, or a different address if the beneficiary is a
     *   different wallet
     * @return The final amount withdrawn
     **/
    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256);

    /**
     * @notice Allows users to borrow a specific `amount` of the reserve underlying asset, provided that the borrower
     * already supplied enough collateral, or he was given enough allowance by a credit delegator on the
     * corresponding debt token (StableDebtToken or VariableDebtToken)
     * - E.g. User borrows 100 USDC passing as `onBehalfOf` his own address, receiving the 100 USDC in his wallet
     *   and 100 stable/variable debt tokens, depending on the `interestRateMode`
     * @param asset The address of the underlying asset to borrow
     * @param amount The amount to be borrowed
     * @param interestRateMode The interest rate mode at which the user wants to borrow: 1 for Stable, 2 for Variable
     * @param referralCode The code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     * @param onBehalfOf The address of the user who will receive the debt. Should be the address of the borrower itself
     * calling the function if he wants to borrow against his own collateral, or the address of the credit delegator
     * if he has been given credit delegation allowance
     **/
    function borrow(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        uint16 referralCode,
        address onBehalfOf
    ) external;

    /**
     * @notice Repays a borrowed `amount` on a specific reserve, burning the equivalent debt tokens owned
     * - E.g. User repays 100 USDC, burning 100 variable/stable debt tokens of the `onBehalfOf` address
     * @param asset The address of the borrowed underlying asset previously borrowed
     * @param amount The amount to repay
     * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
     * @param interestRateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
     * @param onBehalfOf The address of the user who will get his debt reduced/removed. Should be the address of the
     * user calling the function if he wants to reduce/remove his own debt, or the address of any other
     * other borrower whose debt should be removed
     * @return The final amount repaid
     **/
    function repay(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        address onBehalfOf
    ) external returns (uint256);

    /**
     * @notice Repays a borrowed `amount` on a specific reserve using the reserve aTokens, burning the
     * equivalent debt tokens
     * - E.g. User repays 100 USDC using 100 aUSDC, burning 100 variable/stable debt tokens
     * @dev  Passing uint256.max as amount will clean up any residual aToken dust balance, if the user aToken
     * balance is not enough to cover the whole debt
     * @param asset The address of the borrowed underlying asset previously borrowed
     * @param amount The amount to repay
     * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
     * @param interestRateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
     * @return The final amount repaid
     **/
    function repayWithATokens(
        address asset,
        uint256 amount,
        uint256 interestRateMode
    ) external returns (uint256);

    /**
     * @notice Allows a user to use the protocol in eMode
     * @param categoryId The id of the category
     */
    function setUserEMode(uint8 categoryId) external;

    /**
     * @notice Supplies an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
     * - E.g. User supplies 100 USDC and gets in return 100 aUSDC
     * @dev Deprecated: Use the `supply` function instead
     * @param asset The address of the underlying asset to supply
     * @param amount The amount to be supplied
     * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
     *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
     *   is a different wallet
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     **/
    function deposit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    /**
     * @notice Returns the normalized income normalized income of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The reserve's normalized income
     */
    function getReserveNormalizedIncome(address asset) external view returns (uint256);

    /**
     * @notice Returns the normalized variable debt per unit of asset
     * @param asset The address of the underlying asset of the reserve
     * @return The reserve normalized variable debt
     */
    function getReserveNormalizedVariableDebt(address asset) external view returns (uint256);

    /**
     * @notice Returns the user account data across all the reserves
     * @param user The address of the user
     * @return totalCollateralBase The total collateral of the user in the base currency used by the price feed
     * @return totalDebtBase The total debt of the user in the base currency used by the price feed
     * @return availableBorrowsBase The borrowing power left of the user in the base currency used by the price feed
     * @return currentLiquidationThreshold The liquidation threshold of the user
     * @return ltv The loan to value of The user
     * @return healthFactor The current health factor of the user
     **/
    function getUserAccountData(address user)
        external
        view
        returns (
            uint256 totalCollateralBase,
            uint256 totalDebtBase,
            uint256 availableBorrowsBase,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        );

    /**
     * @notice Allows smartcontracts to access the liquidity of the pool within one transaction,
     * as long as the amount taken plus a fee is returned.
     * @dev IMPORTANT There are security concerns for developers of flashloan receiver contracts that must be kept
     * into consideration. For further details please visit https://developers.aave.com
     * @param receiverAddress The address of the contract receiving the funds, implementing IFlashLoanSimpleReceiver interface
     * @param asset The address of the asset being flash-borrowed
     * @param amount The amount of the asset being flash-borrowed
     * @param params Variadic packed params to pass to the receiver as extra information
     * @param referralCode The code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     **/
    function flashLoanSimple(
        address receiverAddress,
        address asset,
        uint256 amount,
        bytes calldata params,
        uint16 referralCode
    ) external;

    /**
     * @notice Returns the total fee on flash loans
     * @return The total fee on flashloans
     */
    function FLASHLOAN_PREMIUM_TOTAL() external view returns (uint128);

    /**
     * @notice Returns the part of the flashloan fees sent to protocol
     * @return The flashloan fee sent to the protocol treasury
     */
    function FLASHLOAN_PREMIUM_TO_PROTOCOL() external view returns (uint128);
}

// SPDX-License-Identifier: agpl-3.0
// Forked and minimized from https://github.com/aave/aave-v3-periphery/blob/master/contracts/rewards/interfaces/IRewardsDistributor.sol
pragma solidity ^0.8.0;

interface IAaveV3Reward {
    // /**
    //  * @dev Sets the end date for the distribution
    //  * @param asset The asset to incentivize
    //  * @param reward The reward token that incentives the asset
    //  * @param newDistributionEnd The end date of the incentivization, in unix time format
    //  **/
    // function setDistributionEnd(
    //   address asset,
    //   address reward,
    //   uint32 newDistributionEnd
    // ) external;

    // /**
    //  * @dev Sets the emission per second of a set of reward distributions
    //  * @param asset The asset is being incentivized
    //  * @param rewards List of reward addresses are being distributed
    //  * @param newEmissionsPerSecond List of new reward emissions per second
    //  */
    // function setEmissionPerSecond(
    //   address asset,
    //   address[] calldata rewards,
    //   uint88[] calldata newEmissionsPerSecond
    // ) external;

    // /**
    //  * @dev Gets the end date for the distribution
    //  * @param asset The incentivized asset
    //  * @param reward The reward token of the incentivized asset
    //  * @return The timestamp with the end of the distribution, in unix time format
    //  **/
    // function getDistributionEnd(address asset, address reward) external view returns (uint256);

    // /**
    //  * @dev Returns the index of a user on a reward distribution
    //  * @param user Address of the user
    //  * @param asset The incentivized asset
    //  * @param reward The reward token of the incentivized asset
    //  * @return The current user asset index, not including new distributions
    //  **/
    // function getUserAssetIndex(
    //   address user,
    //   address asset,
    //   address reward
    // ) external view returns (uint256);

    // /**
    //  * @dev Returns the configuration of the distribution reward for a certain asset
    //  * @param asset The incentivized asset
    //  * @param reward The reward token of the incentivized asset
    //  * @return The index of the asset distribution
    //  * @return The emission per second of the reward distribution
    //  * @return The timestamp of the last update of the index
    //  * @return The timestamp of the distribution end
    //  **/
    // function getRewardsData(address asset, address reward)
    //   external
    //   view
    //   returns (
    //     uint256,
    //     uint256,
    //     uint256,
    //     uint256
    //   );

    // /**
    //  * @dev Returns the list of available reward token addresses of an incentivized asset
    //  * @param asset The incentivized asset
    //  * @return List of rewards addresses of the input asset
    //  **/
    // function getRewardsByAsset(address asset) external view returns (address[] memory);

    // /**
    //  * @dev Returns the list of available reward addresses
    //  * @return List of rewards supported in this contract
    //  **/
    // function getRewardsList() external view returns (address[] memory);

    /**
     * @dev Returns the accrued rewards balance of a user, not including virtually accrued rewards since last distribution.
     * @param user The address of the user
     * @param reward The address of the reward token
     * @return Unclaimed rewards, not including new distributions
     **/
    function getUserAccruedRewards(address user, address reward) external view returns (uint256);

    // /**
    //  * @dev Returns a single rewards balance of a user, including virtually accrued and unrealized claimable rewards.
    //  * @param assets List of incentivized assets to check eligible distributions
    //  * @param user The address of the user
    //  * @param reward The address of the reward token
    //  * @return The rewards amount
    //  **/
    // function getUserRewards(
    //   address[] calldata assets,
    //   address user,
    //   address reward
    // ) external view returns (uint256);

    // /**
    //  * @dev Returns a list all rewards of a user, including already accrued and unrealized claimable rewards
    //  * @param assets List of incentivized assets to check eligible distributions
    //  * @param user The address of the user
    //  * @return The list of reward addresses
    //  * @return The list of unclaimed amount of rewards
    //  **/
    // function getAllUserRewards(address[] calldata assets, address user)
    //   external
    //   view
    //   returns (address[] memory, uint256[] memory);

    // /**
    //  * @dev Returns the decimals of an asset to calculate the distribution delta
    //  * @param asset The address to retrieve decimals
    //  * @return The decimals of an underlying asset
    //  */
    // function getAssetDecimals(address asset) external view returns (uint8);

    // /**
    //  * @dev Returns the address of the emission manager
    //  * @return The address of the EmissionManager
    //  */
    // function getEmissionManager() external view returns (address);

    // /**
    //  * @dev Updates the address of the emission manager
    //  * @param emissionManager The address of the new EmissionManager
    //  */
    // function setEmissionManager(address emissionManager) external;

    //   /**
    //  * @dev Whitelists an address to claim the rewards on behalf of another address
    //  * @param user The address of the user
    //  * @param claimer The address of the claimer
    //  */
    // function setClaimer(address user, address claimer) external;

    // /**
    //  * @dev Sets a TransferStrategy logic contract that determines the logic of the rewards transfer
    //  * @param reward The address of the reward token
    //  * @param transferStrategy The address of the TransferStrategy logic contract
    //  */
    // // function setTransferStrategy(address reward, ITransferStrategyBase transferStrategy) external;

    // /**
    //  * @dev Sets an Aave Oracle contract to enforce rewards with a source of value.
    //  * @notice At the moment of reward configuration, the Incentives Controller performs
    //  * a check to see if the reward asset oracle is compatible with IEACAggregator proxy.
    //  * This check is enforced for integrators to be able to show incentives at
    //  * the current Aave UI without the need to setup an external price registry
    //  * @param reward The address of the reward to set the price aggregator
    //  * @param rewardOracle The address of price aggregator that follows IEACAggregatorProxy interface
    //  */
    // // function setRewardOracle(address reward, IEACAggregatorProxy rewardOracle) external;

    // /**
    //  * @dev Get the price aggregator oracle address
    //  * @param reward The address of the reward
    //  * @return The price oracle of the reward
    //  */
    // function getRewardOracle(address reward) external view returns (address);

    // /**
    //  * @dev Returns the whitelisted claimer for a certain address (0x0 if not set)
    //  * @param user The address of the user
    //  * @return The claimer address
    //  */
    // function getClaimer(address user) external view returns (address);

    // /**
    //  * @dev Returns the Transfer Strategy implementation contract address being used for a reward address
    //  * @param reward The address of the reward
    //  * @return The address of the TransferStrategy contract
    //  */
    // function getTransferStrategy(address reward) external view returns (address);

    // /**
    //  * @dev Configure assets to incentivize with an emission of rewards per second until the end of distribution.
    //  * @param config The assets configuration input, the list of structs contains the following fields:
    //  *   uint104 emissionPerSecond: The emission per second following rewards unit decimals.
    //  *   uint256 totalSupply: The total supply of the asset to incentivize
    //  *   uint40 distributionEnd: The end of the distribution of the incentives for an asset
    //  *   address asset: The asset address to incentivize
    //  *   address reward: The reward token address
    //  *   ITransferStrategy transferStrategy: The TransferStrategy address with the install hook and claim logic.
    //  *   IEACAggregatorProxy rewardOracle: The Price Oracle of a reward to visualize the incentives at the UI Frontend.
    //  *                                     Must follow Chainlink Aggregator IEACAggregatorProxy interface to be compatible.
    //  */
    // // function configureAssets(RewardsDataTypes.RewardsConfigInput[] memory config) external;

    // /**
    //  * @dev Called by the corresponding asset on any update that affects the rewards distribution
    //  * @param user The address of the user
    //  * @param userBalance The user balance of the asset
    //  * @param totalSupply The total supply of the asset
    //  **/
    // function handleAction(
    //   address user,
    //   uint256 userBalance,
    //   uint256 totalSupply
    // ) external;

    /**
     * @dev Claims reward for a user to the desired address, on all the assets of the pool, accumulating the pending rewards
     * @param assets List of assets to check eligible distributions before claiming rewards
     * @param amount The amount of rewards to claim
     * @param to The address that will be receiving the rewards
     * @param reward The address of the reward token
     * @return The amount of rewards claimed
     **/
    function claimRewards(
        address[] calldata assets,
        uint256 amount,
        address to,
        address reward
    ) external returns (uint256);

    // /**
    //  * @dev Claims reward for a user on behalf, on all the assets of the pool, accumulating the pending rewards. The
    //  * caller must be whitelisted via "allowClaimOnBehalf" function by the RewardsAdmin role manager
    //  * @param assets The list of assets to check eligible distributions before claiming rewards
    //  * @param amount The amount of rewards to claim
    //  * @param user The address to check and claim rewards
    //  * @param to The address that will be receiving the rewards
    //  * @param reward The address of the reward token
    //  * @return The amount of rewards claimed
    //  **/
    // function claimRewardsOnBehalf(
    //   address[] calldata assets,
    //   uint256 amount,
    //   address user,
    //   address to,
    //   address reward
    // ) external returns (uint256);

    // /**
    //  * @dev Claims reward for msg.sender, on all the assets of the pool, accumulating the pending rewards
    //  * @param assets The list of assets to check eligible distributions before claiming rewards
    //  * @param amount The amount of rewards to claim
    //  * @param reward The address of the reward token
    //  * @return The amount of rewards claimed
    //  **/
    // function claimRewardsToSelf(
    //   address[] calldata assets,
    //   uint256 amount,
    //   address reward
    // ) external returns (uint256);

    /**
     * @dev Claims all rewards for a user to the desired address, on all the assets of the pool, accumulating the pending rewards
     * @param assets The list of assets to check eligible distributions before claiming rewards
     * @param to The address that will be receiving the rewards
     * @return rewardsList List of addresses of the reward tokens
     * @return claimedAmounts List that contains the claimed amount per reward, following same order as "rewardList"
     **/
    function claimAllRewards(address[] calldata assets, address to)
        external
        returns (address[] memory rewardsList, uint256[] memory claimedAmounts);

    // /**
    //  * @dev Claims all rewards for a user on behalf, on all the assets of the pool, accumulating the pending rewards. The caller must
    //  * be whitelisted via "allowClaimOnBehalf" function by the RewardsAdmin role manager
    //  * @param assets The list of assets to check eligible distributions before claiming rewards
    //  * @param user The address to check and claim rewards
    //  * @param to The address that will be receiving the rewards
    //  * @return rewardsList List of addresses of the reward tokens
    //  * @return claimedAmounts List that contains the claimed amount per reward, following same order as "rewardsList"
    //  **/
    // function claimAllRewardsOnBehalf(
    //   address[] calldata assets,
    //   address user,
    //   address to
    // ) external returns (address[] memory rewardsList, uint256[] memory claimedAmounts);

    // /**
    //  * @dev Claims all reward for msg.sender, on all the assets of the pool, accumulating the pending rewards
    //  * @param assets The list of assets to check eligible distributions before claiming rewards
    //  * @return rewardsList List of addresses of the reward tokens
    //  * @return claimedAmounts List that contains the claimed amount per reward, following same order as "rewardsList"
    //  **/
    // function claimAllRewardsToSelf(address[] calldata assets)
    //   external
    //   returns (address[] memory rewardsList, uint256[] memory claimedAmounts);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/**
 * @title IExchangeLogic
 * @author @InsureDAO
 * @notice Defines the basic interface for an InsureDAO Exchange Logic.
 **/
interface IExchangeLogic {
    /**
     * @notice get swapper(router) address
     * @return swapper_ swapper address
     */
    function swapper() external returns (address);

    /**
     * @notice get encoded bytes of swapping to call swap by sender address
     * @param _tokenIn address of input token
     * @param _tokenOut address of output token
     * @param _amountIn amount of input token
     * @param _amountOutMin amount of minimum output token
     * @param _to to address
     * @return abiEncoded returns encoded bytes
     */
    function abiEncodeSwap(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        uint256 _amountOutMin,
        address _to
    ) external view returns (bytes memory);

    /**
     * @notice estimate being swapped amounts of _tokenOut
     * @param _tokenIn address of input token
     * @param _tokenOut address of output token
     * @param _amountIn amount of input token
     * @return amountOut_ returns the amount of _tokenOut swapped
     */
    function estimateAmountOut(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn
    ) external view returns (uint256);

    /**
     * @notice estimate needed amounts of _tokenIn
     * @param _tokenIn address of input token
     * @param _tokenOut address of output token
     * @param _amountOutMin amount of minimum output token
     * @return amountIn_ returns the amount of _tokenIn needed
     */
    function estimateAmountIn(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountOutMin
    ) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/**
 * @title IFungibleInitializer
 * @author @InsureDAO
 * @notice Defines the basic interface for an InsureDAO Fungible Initializer.
 **/
interface IFungibleInitializer {
    /**
     * @notice initialize functions for proxy contracts.
     * @param  _name contract's name
     * @param  _symbol contract's symbol (supported ERC20)
     * @param  _params initilizing params
     * @param  _references initilizing addresses
     */
    function initialize(
        string memory _name,
        string memory _symbol,
        uint256[] calldata _params,
        address[] calldata _references
    ) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./IFungibleInitializer.sol";

/**
 * @title IFungiblePolicy
 * @author @InsureDAO
 * @notice Defines the basic interface for an InsureDAO Fungible Policy.
 **/
interface IFungiblePolicy is IFungibleInitializer {
    /**
     * FUNCTIONS
     */

    /**
     * @notice get insurance end time
     * @return endTime
     */
    function endTime() external returns (uint48);

    /**
     * @notice purchase a fungible position of depeg insurance with a fixed date end policy
     * mint ERC20 token in exchange for paying a premium
     * @param _amount amount to redeem
     */
    function insure(uint256 _amount) external;

    /**
     * @notice redeem usdc in exchange for usdt.
     * @param _amount amount to redeem
     * @param _redeemToken option to redeem usdc as collateral tokens
     */
    function redeem(uint256 _amount, address _redeemToken) external;

    /**
     * ERRORS
     */
    error RequestExceedBalance();
    error AmountZero();
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./IAssetManagement.sol";

/**
 * @title IMarket
 * @author @InsureDAO
 * @notice Defines the basic interface for an InsureDAO Market.
 **/
interface IMarket {
    /**
     * STRUCTS
     */
    ///@notice user's withdrawal status management
    struct Withdrawal {
        uint256 timestamp;
        uint256 amount;
    }

    ///@notice insurance status management
    struct Insurance {
        uint256 id; //each insuance has their own id
        uint48 startTime; //timestamp of starttime
        uint48 endTime; //timestamp of endtime
        uint256 amount; //insured amount
        address insured; //the address holds the right to get insured
        bool status; //true if insurance is not expired
    }

    /**
     * EVENTS
     */
    event Deposit(address indexed depositor, uint256 amount, uint256 mint, uint256 pricePerToken);
    event WithdrawRequested(address indexed withdrawer, uint256 amount, uint256 unlockTime);
    event Withdraw(address indexed withdrawer, uint256 amount, uint256 retVal, uint256 pricePerToken);
    event Unlocked(uint256 indexed id, uint256 amount);
    event Terminated(uint256 indexed id, uint256 amount);
    event Insured(
        uint256 indexed id,
        uint256 amount,
        uint256 startTime,
        uint256 indexed endTime,
        address indexed insured,
        uint256 premium
    );
    event InsuranceIncreased(uint256 indexed id, uint256 amount);
    event InsuranceExtended(uint256 indexed id, uint256 endTime);
    event Redeemed(uint256 indexed id, uint256 payout, uint256 amount, address insured, bool status);
    event UnInsured(uint256 indexed id, uint256 feeback, uint256 amount, address insured, bool status);

    event Manager(address manager);
    event Migration(address from, address to);
    event InsuranceDecreased(uint256 id, uint256 amount, uint256 _newAmount, address insured, bool status);
    event TransferInsurance(uint256 indexed id, address from, address indexed newInsured);

    /**
     * FUNCTIONS
     */
    /**
     * @notice A liquidity provider supplies tokens to the pool and receives iTokens
     * @param _amount amount of tokens to deposit
     * @return _mintAmount the amount of iTokens minted from the transaction
     */
    function deposit(uint256 _amount) external returns (uint256);

    /**
     * @notice A liquidity provider request withdrawal of collateral
     * @param _amount amount of iTokens to burn
     */
    function requestWithdraw(uint256 _amount) external;

    /**
     * @notice A liquidity provider burns iTokens and receives collateral from the pool
     * @param _amount amount of iTokens to burn
     * @return _retVal the amount underlying tokens returned
     */
    function withdraw(uint256 _amount) external returns (uint256 _retVal);

    /**
     * @notice Unlocks an array of insurances
     * @param _ids array of ids to unlock
     */
    function unlockBatch(uint256[] calldata _ids) external;

    /**
     * @notice Unlock an insurance
     * @param _id id of the insurance policy to unlock liquidity
     */
    function unlock(uint256 _id) external;

    /**
     * @notice Terminates an array of insurances
     * @param _ids array of ids to unlock
     */
    function terminateBatch(uint256[] calldata _ids) external;

    /**
     * @notice Terminates an insurance
     * @param _id id of the insurance policy to unlock liquidity
     */
    function terminate(uint256 _id) external;

    /**
     * @notice Get insured for the specified amount for specified period
     * @param _amount target amount to get covered
     * @param _period end date to be covered(timestamp)
     * @return _id of the insurance policy
     */
    function insureByPeriod(uint256 _amount, uint48 _period) external returns (uint256);

    /**
     * @notice Get insured for the specified amount for specified period by delegator
     * @param _amount target amount to get covered
     * @param _period end date to be covered(timestamp)
     * @param _consignor consignor(payer) address
     * @return _id of the insurance policy
     */
    function insureByPeriodDelegate(
        uint256 _amount,
        uint48 _period,
        address _consignor
    ) external returns (uint256);

    /**
     * @notice Get insured for the specified amount for specified span
     * @param _amount target amount to get covered
     * @param _span length to get covered(e.g. 7 days)
     * @return _id of the insurance policy
     */
    function insure(uint256 _amount, uint256 _span) external returns (uint256);

    /**
     * @notice Get insured for the specified amount for specified span by delegator
     * @param _amount target amount to get covered
     * @param _span length to get covered(e.g. 7 days)
     * @param _consignor consignor(payer) address
     * @return _id of the insurance policy
     */
    function insureDelegate(
        uint256 _amount,
        uint256 _span,
        address _consignor
    ) external returns (uint256);

    /**
     * @notice extend end time of an insurance policy
     * @param _id id of a policy
     * @param _span length to extend(e.g. 7 days)
     */
    function extendInsurance(uint256 _id, uint48 _span) external;

    /**
     * @notice increase the coverage of an insurance policy by delegator
     * @param _id id of a policy
     * @param _amount coverage to increase
     * @param _consignor consignor(payer) address
     */
    function increaseInsuranceDelegate(
        uint256 _id,
        uint256 _amount,
        address _consignor
    ) external;

    /**
     * @notice increase the coverage of an insurance policy
     * @param _id id of a policy
     * @param _amount coverage to increase
     */
    function increaseInsurance(uint256 _id, uint256 _amount) external;

    /**
     * @notice Transfers an active insurance
     * @param _id id of the insurance policy
     * @param _newInsured new insured address
     */
    function transferInsurance(uint256 _id, address _newInsured) external;

    /**
     * @notice Transfers an active insurance
     * @param _id id of the insurance policy
     * @param _amount new insured address
     * @param _consignor address paid fee back
     */
    function decreaseInsurance(
        uint256 _id,
        uint256 _amount,
        address _consignor
    ) external;

    /**
     * @notice Redeem an insurance policy.
     * Allow split redemption for multiple times within the coverage amount.
     * @param _id the id of the insurance policy
     * @param _amount redeem amount
     */
    function redeem(uint256 _id, uint256 _amount) external;

    /**
     * @notice Redeem an insurance policy by delegator
     * Allow split redemption for multiple times within the coverage amount.
     * @param _id the id of the insurance policy
     * @param _amount redeem amount
     * @param _beneficiary address to get paid fee
     */
    function redeemDelegate(
        uint256 _id,
        uint256 _amount,
        address _beneficiary
    ) external;

    /**
     * @notice Redeem an insurance policy to payout other token
     * Allow split redemption for multiple times within the coverage amount.
     * @param _id the id of the insurance policy
     * @param _amount redeem amount
     * @param _redeemToken redeem by other tokens
     */
    function redeemByToken(
        uint256 _id,
        uint256 _amount,
        address _redeemToken
    ) external;

    /**
     * @notice Redeem an insurance policy to payout other token by delegator
     * Allow split redemption for multiple times within the coverage amount.
     * @param _id the id of the insurance policy
     * @param _amount redeem amount
     * @param _redeemToken redeem by other tokens
     * @param _beneficiary address to get paid token
     */
    function redeemByTokenDelegate(
        uint256 _id,
        uint256 _amount,
        address _beneficiary,
        address _redeemToken
    ) external;

    /**
     * @notice Get how much premium + fee for the specified amount and span
     * @param _amount amount to get insured
     * @param _endTime end time to get covered(timestamp)
     */
    function getCostByPeriod(uint256 _amount, uint48 _endTime) external view returns (uint256);

    /**
     * @notice Get how much premium + fee for the specified amount and span
     * @param _amount amount to get insured
     * @param _span span to get covered
     */
    function getCost(uint256 _amount, uint256 _span) external view returns (uint256);

    /**
     * @notice get how much value per one iToken supply. scaled by 1e8
     */
    function rate() external view returns (uint256);

    /**
     * @notice Get the underlying balance of the `owner`
     * @param _owner the target address to look up value
     * @return _value The balance of underlying tokens for the specified address
     */
    function valueOfUnderlying(address _owner) external view returns (uint256);

    /**
     * @notice Get token number for the specified underlying value
     * @param _value the amount of the underlying
     * @return _amount the number of the iTokens corresponding to _value
     */
    function worth(uint256 _value) external view returns (uint256);

    /**
     * @notice Returns the availability of cover
     * @return available liquidity of this pool
     */
    function availableBalance() external view returns (uint256);

    /**
     * @notice Pool's Liquidity
     * @return total liquidity of this pool
     */
    function totalLiquidity() external view returns (uint256);

    /**
     * @notice Deposited amount not utilized yet
     * @return withdrawableAmount max withdrawable amount
     */
    function withdrawableAmount() external view returns (uint256);

    /**
     * @notice Return short positions (=covered amount)
     * @return amount short positions
     */
    function shortPositions() external view returns (uint256);

    /**
     * @notice Pool's max capacity
     * @return total capacity of this pool
     */
    function maxCapacity() external view returns (uint256);

    /**
     * @notice manager address
     * @return manager AssetManagement address
     */
    function manager() external view returns (IAssetManagement);

    /**
     * @notice set delegators
     * @param _manager manager address
     */
    function setManager(address _manager) external;

    /**
     * @notice set delegators
     * @param _delegator delegator address
     * @param _allowance allowed or not
     */
    function setDelegator(address _delegator, bool _allowance) external;

    /**
     * @notice Enable mmigration of manager contract.
     * Expected to use when there is updates on contract or underlying conditions
     * @param _to next manager contract
     * @param _references address params to pass to the new manager
     * @param _params parameters to pass to the new contract
     */
    function migrate(
        address _to,
        address[] calldata _references,
        uint256[] calldata _params
    ) external;

    /**
     * ERRORS
     */
    error NotApplicable();
    error NotTerminatable();
    error TooVolatile();
    error OnlyDelegator();
    error AmountZero();
    error RequestExceedBalance();
    error YetTime();
    error OverTime();
    error AmountExceeded();
    error NoSupply();
    error ZeroAddress();
    error BeforeNow();
    error OutOfSpan();
    error InsuranceNotActive();
    error InsuranceExpired();
    error InsuranceNotExpired();
    error InsureExceededMaxSpan();
    error NotYourInsurance();
    error MigrationFailed();
    error OnlyManager();
    error AlreadySetManager();
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/**
 * @title IMarketParameters
 * @author @InsureDAO
 * @notice Defines the basic interface for an InsureDAO Market Parameters.
 **/
interface IMarketParameters {
    /**
     * FUNCTIONS
     */
    function setLockup(address _target, uint256 _value) external;

    function getLockup(address _target) external view returns (uint256);

    function setMaxDate(address _target, uint256 _value) external;

    function getMaxDate(address _target) external view returns (uint256);

    function setMinDate(address _target, uint256 _value) external;

    function getMinDate(address _target) external view returns (uint256);

    function setPremiumModel(address _target, address _address) external;

    function getPremiumModel(address _market) external view returns (address);

    function setPremiumRate(address _target, uint256 _value) external;

    function getPremiumRate(address _target) external view returns (uint256);

    function setCommissionRate(address _target, uint256 _value) external;

    function getCommissionRate(address _target) external view returns (uint256);

    function setWithdrawablePeriod(address _target, uint256 _value) external;

    function getWithdrawablePeriod(address _target) external view returns (uint256);

    function setGrace(address _target, uint256 _value) external;

    function getGrace(address _target) external view returns (uint256);

    function setTwapLength(address _target, uint256 _value) external;

    function getTwapLength(address _target) external view returns (uint256);

    function setTwapFrequency(address _target, uint256 _value) external;

    function getTwapFrequency(address _target) external view returns (uint256);

    function setDepegThreshold(address _target, uint256 _value) external;

    function getDepegThreshold(address _target) external view returns (uint256);

    function setThreshold(address _target, uint256 _value) external;

    function getThreshold(address _target) external view returns (uint256);

    function setSpotThreshold(address _target, uint256 _value) external;

    function getSpotThreshold(address _target) external view returns (uint256);

    function setVolatilityAllowance(address _target, uint256 _value) external;

    function getVolatilityAllowance(address _target) external view returns (uint256);

    function setRewardMode(address _target, uint256 _value) external;

    function getRewardMode(address _target) external view returns (uint256);

    function setRewardPool(address _target, address _address) external;

    function getRewardPool(address _target) external view returns (address);

    function setChainlinkTarget(address _target, address _address) external;

    function getChainlinkTarget(address _target) external view returns (address);

    function setChainlinkBase(address _target, address _address) external;

    function getChainlinkBase(address _target) external view returns (address);

    function setRefundModel(address _target, address _address) external;

    function getRefundModel(address _market) external view returns (address);

    function setFeeRate(address _target, uint256 _value) external;

    function getFeeRate(address _target) external view returns (uint256);

    function getOwner() external view returns (address);

    /**
     * ERRORS
     */
    error ZeroAddress();
    error SmallerThanMindate();
    error LargerThanMaxdate();
    error ExceedMaxFeeRate();
    error ExceedOneDoller();
    error SameNumber();
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/**
 * @title IOwnership
 * @author @InsureDAO
 * @notice Defines the basic interface for an InsureDAO Ownership.
 **/
interface IOwnership {
    function owner() external view returns (address);

    function futureOwner() external view returns (address);

    function commitTransferOwnership(address newOwner) external;

    function acceptTransferOwnership() external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV2V3Interface.sol";

/**
 * @title IMarketVolatility
 * @author @InsureDAO
 * @notice Defines the basic interface for an InsureDAO Market Volatility.
 **/
interface IMarketVolatility {

    /**
     * @notice returns true if the coverage can be applied
     */
    function isDepeg() external view returns (bool);
    /**
     * @notice returns true if insurance positions can be terminated
     */
    function isTerminatable() external view returns (bool);
    /**
     * @notice returns true if volatility is beyond a certain level
     */
    function isVolatile() external view returns (bool);

    /**
     * @notice returns twap price of target currency set by parameters
     */
    function targetTwap() external view returns(uint256);
    /**
     * @notice returns twap price of base currency set by parameters
     */
    function baseTwap() external view returns(uint256);
    /**
     * @notice returns spot price of target currency set by parameters
     */
    function targetSpotPrice() external view returns(uint256);
    /**
     * @notice returns spot price of base currency set by parameters
     */
    function baseSpotPrice() external view returns(uint256);
    /**
     * @notice returns twap rate of target currency / base currency
     */
    function twapRate() external view returns(uint256);
    /**
     * @notice returns spot rate of target currency / base currency
     */
    function spotRate() external view returns(uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./IFungibleInitializer.sol";

/**
 * @title IPolicyFactory
 * @author @InsureDAO
 * @notice Defines the basic interface for an InsureDAO Policy Factory.
 **/
interface IPolicyFactory {
    /**
     * EVENTS
     */
    event TemplateApproved(address _templateAddr, bool _approval);
    event FungibleCreated(
        address indexed _fungible,
        address indexed _template,
        string  _name,
        string _symbol,
        uint256[] _params,
        address[] _references
    );

    /**
     * FUNCTIONS
     */
    /**
     * @notice A function to approve or disapprove templates.
     * Only owner of the contract can operate.
     * @param _template template address, which must be registered
     * @param _approval true if a market is allowed to create based on the template
     */
    function approveTemplate(IFungibleInitializer _template, bool _approval) external;

    /**
     * @notice A function to create markets.
     * This function is market model agnostic.
     * @param _template template address, which must be registered
     * @param _name token name
     * @param _symbol token symbol
     * @param _params initialized parameters
     * @param _references initialized reference addresses
     * @return created market address
     */
    function createFungible(
        IFungibleInitializer _template,
        string memory _name,
        string memory _symbol,
        uint256[] calldata _params,
        address[] calldata _references
    ) external returns (address);

    /**
     * ERRORS
     */
    error ZeroAddress();
    error UnauthorizedTemplate();
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/**
 * @title IMigrationAsset
 * @author @InsureDAO
 * @notice Defines the basic interface for an InsureDAO Asset Migration.
 **/
interface IMigrationAsset {
    /**
     * EVENTS
     */
    event Immigration(
        address _from,
        uint256 _principal,
        uint256 _feePool,
        uint256 _shortPosition,
        address[] _references,
        uint256[] _params
    );

    event Emigration(
        address _to,
        uint256 _principal,
        uint256 _feePool,
        uint256 _shortPosition,
        address[] _references,
        uint256[] _params
    );

    /**
     * FUNCTIONS
     */
    /**
     * @notice immigrate positon settings to a new manager contract
     * @param _principal principal amount that is migtated to new manager
     * @param _feePool fee reserve that is migrated to new manager
     * @param _shortPosition constructed short position to new manager to reconstruct
     * @param _deposit deposit amount
     * @param _references address params to pass to the new manager
     * @param _params parameters to pass to the new contract
     */
    function immigrate(
        uint256 _principal,
        uint256 _feePool,
        uint256 _shortPosition,
        uint256 _deposit,
        address[] calldata _references,
        uint256[] calldata _params
    ) external;

    /**
     * @notice emmigrate positon settings to a new manager contract
     * @param _to next manager contract
     * @param _references address params to pass to the new manager
     * @param _params parameters to pass to the new contract
     */
    function emigrate(
        address _to,
        address[] calldata _references,
        uint256[] calldata _params
    ) external;

    /**
     * ERRORS
     */
    error OnlyFromManager();
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/**
 * @title IManagerParameters
 * @author @InsureDAO
 * @notice Defines the basic interface for an InsureDAO Manager Parameters.
 **/
interface IManagerParameters {
    function setLeverage(address _target, uint256 _value) external;

    function getLeverage(address _target) external view returns (uint256);

    function setPerformanceFeeRate(address _target, uint256 _value) external;

    function getPerformanceFeeRate(address _target) external view returns (uint256);

    function setBorrowingPower(address _target, uint256 _value) external;

    function getBorrowingPower(address _target) external view returns (uint256);

    function setMaxUtilizationRateAfterBorrow(address _target, uint256 _value) external;

    function getMaxUtilizationRateAfterBorrow(address _target) external view returns (uint256);

    function setMaxOccupancyRate(address _target, uint256 _value) external;

    function getMaxOccupancyRate(address _target) external view returns (uint256);

    function setSlippageTolerance(address _target, uint256 _value) external;

    function getSlippageTolerance(address _target) external view returns (uint256);

    function setPerformancePool(address _target, address _address) external;

    function getPerformancePool(address _target) external view returns (address);

    function getOwner() external view returns (address);

    error OnlyUpper();
    error ZeroAddress();
}

// SPDX-License-Identifier: BUSL-1.1
// Forked and minimized from https://github.com/platypus-finance/core/blob/master/contracts/interfaces/IPool.sol
pragma solidity ^0.8.0;

interface IPlatypusPool {
    function assetOf(address token) external view returns (address);

    function deposit(
        address token,
        uint256 amount,
        address to,
        uint256 deadline
    ) external returns (uint256 liquidity);

    function withdraw(
        address token,
        uint256 liquidity,
        uint256 minimumAmount,
        address to,
        uint256 deadline
    ) external returns (uint256 amount);

    function withdrawFromOtherAsset(
        address initialToken,
        address wantedToken,
        uint256 liquidity,
        uint256 minimumAmount,
        address to,
        uint256 deadline
    ) external returns (uint256 amount);

    function swap(
        address fromToken,
        address toToken,
        uint256 fromAmount,
        uint256 minimumToAmount,
        address to,
        uint256 deadline
    ) external returns (uint256 actualToAmount, uint256 haircut);

    function quotePotentialSwap(
        address fromToken,
        address toToken,
        uint256 fromAmount
    ) external view returns (uint256 potentialOutcome, uint256 haircut);

    function quotePotentialWithdraw(address token, uint256 liquidity)
        external
        view
        returns (
            uint256 amount,
            uint256 fee,
            bool enoughCash
        );

    function quotePotentialWithdrawFromOtherAsset(
        address initialToken,
        address wantedToken,
        uint256 liquidity
    ) external view returns (uint256 amount, uint256 fee);

    function quoteMaxInitialAssetWithdrawable(address initialToken, address wantedToken)
        external
        view
        returns (uint256 maxInitialAssetAmount);

    function getTokenAddresses() external view returns (address[] memory);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/**
 * @title IRefundModel
 * @author @InsureDAO
 * @notice Defines the basic interface for an InsureDAO Premium Back Model.
 **/
interface IRefundModel {
    /**
     * @notice get fee rate for the specified conditions
     * @param _amount premium amount
     * @param _endTime insure's end time
     * @return fee insure back fee
     */
    function getRefundAmount(uint256 _amount, uint48 _endTime) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/**
 * @title IPremiumModel
 * @author @InsureDAO
 * @notice Defines the basic interface for an InsureDAO Premium Model.
 **/
interface IPremiumModel {
    /**
     * FUNCTIONS
     */
    /**
     * @notice get fee rate for the specified conditions
     * @param _amount premium amount
     * @param _term insure's term
     * @param _targetRate target contract's rate
     * @return fee
     */
    function getFee(
        uint256 _amount,
        uint256 _term,
        uint256 _targetRate
    ) external view returns (uint256);

    /**
     * @notice get fee rate for the specified conditions
     * @param _amount premium amount
     * @param _term insure's term
     * @param _targetRate target contract's rate
     * @param _totalLiquidity total liquidity
     * @param _lockedAmount locked amount
     * @return fee
     */
    function getPremium(
        uint256 _amount,
        uint256 _term,
        uint256 _targetRate,
        uint256 _commissionRate,
        uint256 _totalLiquidity,
        uint256 _lockedAmount
    ) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/**
 * @title IRewardPool
 * @author @InsureDAO
 * @notice Defines the basic interface for an InsureDAO Reward Pool.
 **/
interface IRewardPool {
    /**
     * EVENTS
     */
    event Market(address _market);
    event RewardAdded(uint256 _reward, address _account);
    event RewardWithdrawal(uint256 _reward, address _account);
    event OwnerWithdrawableTimestamp(uint256 _ownerWithdrawableTimestamp);

    /**
     * FUNCTIONS
     */
    /**
     * @notice add reward amount
     * @param _reward reward amount
     * @param _account rewarded address
     */
    function addReward(uint256 _reward, address _account) external;
    /**
     * @notice withdraw reward
     * @param _reward reward amount
     */
    function withdrawReward(uint256 _reward) external;
    /**
     * @notice withdraw all reward
     */
    function withdrawAllReward() external;
    /**
     * @notice withdraw token stored in this contract
     * @param _token token address
     * @param _to beneficiary's address
     */
    function withdrawRedundant(address _token, address _to) external;
    /**
     * @notice get reward amount
     * @param _account reward address
     */
    function rewards(address _account) external returns(uint256);
    /**
     * @notice set owner withdrawable timestamp (for withdrawRedundant)
     * @param _ownerWithdrawableTimestamp new withdrawable timestamp must be bigger than old
     */
    function setOwnerWithdrawableTimestamp(uint256 _ownerWithdrawableTimestamp) external;
    /**
     * @notice set market address
     * @param _market market address
     */
    function setMarket(address _market) external;

    /**
     * ERRORS
     */
    error YetWithdrawableTime();
    error OnlyMarket();
    error ZeroAddress();
    error AmountZero();
    error AmountExceeded();
    error OnlyUpper();
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AggregatorInterface.sol";
import "./AggregatorV3Interface.sol";

interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);

  function latestTimestamp() external view returns (uint256);

  function latestRound() external view returns (uint256);

  function getAnswer(uint256 roundId) external view returns (int256);

  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);

  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {IPoolAddressesProvider} from "./IPoolAddressesProvider.sol";
import {IAaveV3Pool} from "./IAaveV3Pool.sol";

/**
 * @title IFlashLoanSimpleReceiver
 * @author Aave
 * @notice Defines the basic interface of a flashloan-receiver contract.
 * @dev Implement this interface to develop a flashloan-compatible flashLoanReceiver contract
 **/
interface IFlashLoanSimpleReceiver {
    /**
     * @notice Executes an operation after receiving the flash-borrowed asset
     * @dev Ensure that the contract can return the debt + premium, e.g., has
     *      enough funds to repay and has approved the Pool to pull the total amount
     * @param asset The address of the flash-borrowed asset
     * @param amount The amount of the flash-borrowed asset
     * @param premium The fee of the flash-borrowed asset
     * @param initiator The address of the flashloan initiator
     * @param params The byte-encoded params passed when initiating the flashloan
     * @return True if the execution of the operation succeeds, false otherwise
     */
    function executeOperation(
        address asset,
        uint256 amount,
        uint256 premium,
        address initiator,
        bytes calldata params
    ) external returns (bool);

    /**
     * @notice get aave provider address
     * @return addressProvider
     */
    function ADDRESSES_PROVIDER() external view returns (IPoolAddressesProvider);

    /**
     * @notice get aave pool address
     * @return pool
     */
    function POOL() external view returns (IAaveV3Pool);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

/**
 * @title IPoolAddressesProvider
 * @author Aave
 * @notice Defines the basic interface for a Pool Addresses Provider.
 **/
interface IPoolAddressesProvider {
  /**
   * @dev Emitted when the market identifier is updated.
   * @param oldMarketId The old id of the market
   * @param newMarketId The new id of the market
   */
  event MarketIdSet(string indexed oldMarketId, string indexed newMarketId);

  /**
   * @dev Emitted when the pool is updated.
   * @param oldAddress The old address of the Pool
   * @param newAddress The new address of the Pool
   */
  event PoolUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when the pool configurator is updated.
   * @param oldAddress The old address of the PoolConfigurator
   * @param newAddress The new address of the PoolConfigurator
   */
  event PoolConfiguratorUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when the price oracle is updated.
   * @param oldAddress The old address of the PriceOracle
   * @param newAddress The new address of the PriceOracle
   */
  event PriceOracleUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when the ACL manager is updated.
   * @param oldAddress The old address of the ACLManager
   * @param newAddress The new address of the ACLManager
   */
  event ACLManagerUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when the ACL admin is updated.
   * @param oldAddress The old address of the ACLAdmin
   * @param newAddress The new address of the ACLAdmin
   */
  event ACLAdminUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when the price oracle sentinel is updated.
   * @param oldAddress The old address of the PriceOracleSentinel
   * @param newAddress The new address of the PriceOracleSentinel
   */
  event PriceOracleSentinelUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when the pool data provider is updated.
   * @param oldAddress The old address of the PoolDataProvider
   * @param newAddress The new address of the PoolDataProvider
   */
  event PoolDataProviderUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when a new proxy is created.
   * @param id The identifier of the proxy
   * @param proxyAddress The address of the created proxy contract
   * @param implementationAddress The address of the implementation contract
   */
  event ProxyCreated(
    bytes32 indexed id,
    address indexed proxyAddress,
    address indexed implementationAddress
  );

  /**
   * @dev Emitted when a new non-proxied contract address is registered.
   * @param id The identifier of the contract
   * @param oldAddress The address of the old contract
   * @param newAddress The address of the new contract
   */
  event AddressSet(bytes32 indexed id, address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when the implementation of the proxy registered with id is updated
   * @param id The identifier of the contract
   * @param proxyAddress The address of the proxy contract
   * @param oldImplementationAddress The address of the old implementation contract
   * @param newImplementationAddress The address of the new implementation contract
   */
  event AddressSetAsProxy(
    bytes32 indexed id,
    address indexed proxyAddress,
    address oldImplementationAddress,
    address indexed newImplementationAddress
  );

  /**
   * @notice Returns the id of the Aave market to which this contract points to.
   * @return The market id
   **/
  function getMarketId() external view returns (string memory);

  /**
   * @notice Associates an id with a specific PoolAddressesProvider.
   * @dev This can be used to create an onchain registry of PoolAddressesProviders to
   * identify and validate multiple Aave markets.
   * @param newMarketId The market id
   */
  function setMarketId(string calldata newMarketId) external;

  /**
   * @notice Returns an address by its identifier.
   * @dev The returned address might be an EOA or a contract, potentially proxied
   * @dev It returns ZERO if there is no registered address with the given id
   * @param id The id
   * @return The address of the registered for the specified id
   */
  function getAddress(bytes32 id) external view returns (address);

  /**
   * @notice General function to update the implementation of a proxy registered with
   * certain `id`. If there is no proxy registered, it will instantiate one and
   * set as implementation the `newImplementationAddress`.
   * @dev IMPORTANT Use this function carefully, only for ids that don't have an explicit
   * setter function, in order to avoid unexpected consequences
   * @param id The id
   * @param newImplementationAddress The address of the new implementation
   */
  function setAddressAsProxy(bytes32 id, address newImplementationAddress) external;

  /**
   * @notice Sets an address for an id replacing the address saved in the addresses map.
   * @dev IMPORTANT Use this function carefully, as it will do a hard replacement
   * @param id The id
   * @param newAddress The address to set
   */
  function setAddress(bytes32 id, address newAddress) external;

  /**
   * @notice Returns the address of the Pool proxy.
   * @return The Pool proxy address
   **/
  function getPool() external view returns (address);

  /**
   * @notice Updates the implementation of the Pool, or creates a proxy
   * setting the new `pool` implementation when the function is called for the first time.
   * @param newPoolImpl The new Pool implementation
   **/
  function setPoolImpl(address newPoolImpl) external;

  /**
   * @notice Returns the address of the PoolConfigurator proxy.
   * @return The PoolConfigurator proxy address
   **/
  function getPoolConfigurator() external view returns (address);

  /**
   * @notice Updates the implementation of the PoolConfigurator, or creates a proxy
   * setting the new `PoolConfigurator` implementation when the function is called for the first time.
   * @param newPoolConfiguratorImpl The new PoolConfigurator implementation
   **/
  function setPoolConfiguratorImpl(address newPoolConfiguratorImpl) external;

  /**
   * @notice Returns the address of the price oracle.
   * @return The address of the PriceOracle
   */
  function getPriceOracle() external view returns (address);

  /**
   * @notice Updates the address of the price oracle.
   * @param newPriceOracle The address of the new PriceOracle
   */
  function setPriceOracle(address newPriceOracle) external;

  /**
   * @notice Returns the address of the ACL manager.
   * @return The address of the ACLManager
   */
  function getACLManager() external view returns (address);

  /**
   * @notice Updates the address of the ACL manager.
   * @param newAclManager The address of the new ACLManager
   **/
  function setACLManager(address newAclManager) external;

  /**
   * @notice Returns the address of the ACL admin.
   * @return The address of the ACL admin
   */
  function getACLAdmin() external view returns (address);

  /**
   * @notice Updates the address of the ACL admin.
   * @param newAclAdmin The address of the new ACL admin
   */
  function setACLAdmin(address newAclAdmin) external;

  /**
   * @notice Returns the address of the price oracle sentinel.
   * @return The address of the PriceOracleSentinel
   */
  function getPriceOracleSentinel() external view returns (address);

  /**
   * @notice Updates the address of the price oracle sentinel.
   * @param newPriceOracleSentinel The address of the new PriceOracleSentinel
   **/
  function setPriceOracleSentinel(address newPriceOracleSentinel) external;

  /**
   * @notice Returns the address of the data provider.
   * @return The address of the DataProvider
   */
  function getPoolDataProvider() external view returns (address);

  /**
   * @notice Updates the address of the data provider.
   * @param newDataProvider The address of the new DataProvider
   **/
  function setPoolDataProvider(address newDataProvider) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// Forked as library from https://github.com/altalabsdev/bartrr/blob/main/contracts/RoundIdFetcher.sol
pragma solidity ^0.8.16;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV2V3Interface.sol";

/// @title Chainlink RoundId Fetcher
/// @dev Used to get historical pricing data from Chainlink data feeds
library ChainlinkRoundIdFetcher {

    /// @notice Gets the phase that contains the target time
    /// @param _feed Address of the chainlink data feed

    /// @param _targetTime Target time to fetch the round id for
    /// @return The first roundId of the phase that contains the target time
    /// @return The timestamp of the phase that contains the target time
    /// @return The first roundId of the current phase
    function getPhaseForTimestamp(AggregatorV2V3Interface _feed, uint256 _targetTime) public view returns (uint80, uint256, uint80) {
        uint16 currentPhase = uint16(_feed.latestRound() >> 64);
        uint80 firstRoundOfCurrentPhase = (uint80(currentPhase) << 64) + 1;
        
        for (uint16 phase = currentPhase; phase >= 1; phase--) {
            uint80 firstRoundOfPhase = (uint80(phase) << 64) + 1;
            uint256 firstTimeOfPhase = _feed.getTimestamp(firstRoundOfPhase);

            if (_targetTime > firstTimeOfPhase) {
                return (firstRoundOfPhase, firstTimeOfPhase, firstRoundOfCurrentPhase);
            }
        }
        return (0,0, firstRoundOfCurrentPhase);
    }

    /// @notice Performs a binary search on the data feed to find the first round id after the target time
    /// @param _feed Address of the chainlink data feed
    /// @param _targetTime Target time to fetch the round id for
    /// @param _lhRound Lower bound roundId (typically the first roundId of the targeted phase)
    /// @param _lhTime Lower bound timestamp (typically the first timestamp of the targeted phase)
    /// @param _rhRound Upper bound roundId (typically the last roundId of the targeted phase)
    /// @return targetRound The first roundId after the target timestamp
    function _binarySearchForTimestamp(AggregatorV2V3Interface _feed, uint256 _targetTime, uint80 _lhRound, uint256 _lhTime, uint80 _rhRound) public view returns (uint80 targetRound) {

        if (_lhTime > _targetTime) return 0; // targetTime not in range

        uint80 guessRound = _rhRound;
        while (_rhRound - _lhRound > 1) {
            guessRound = uint80(int80(_lhRound) + int80(_rhRound - _lhRound)/2);
            uint256 guessTime = _feed.getTimestamp(uint256(guessRound));
            if (guessTime == 0 || guessTime > _targetTime) {
                _rhRound = guessRound;
            } else if (guessTime < _targetTime) {
                (_lhRound, _lhTime) = (guessRound, guessTime);
            }
        }
        return guessRound;
    }

    /// @notice Gets the round id for a given timestamp
    /// @param _feed Address of the chainlink data feed
    /// @param _timeStamp Target time to fetch the round id for
    /// @return roundId The roundId for the given timestamp
    function getRoundId(AggregatorV2V3Interface _feed, uint256 _timeStamp) public view returns (uint80 roundId) {

        (uint80 lhRound, uint256 lhTime, uint80 firstRoundOfCurrentPhase) = getPhaseForTimestamp(_feed, _timeStamp);

        uint80 rhRound;
        if (lhRound == 0) {
            // Date is too far in the past, no data available
            return 0;
        } else if (lhRound == firstRoundOfCurrentPhase) {
            (rhRound,,,,) = _feed.latestRoundData();
        } else {
            // No good way to get last round of phase from Chainlink feed, so our binary search function will have to use trial & error.
            // Use 2**16 == 65536 as a upper bound on the number of rounds to search in a single Chainlink phase.
            
            rhRound = lhRound + 2**16; 
        } 

        uint80 foundRoundId = _binarySearchForTimestamp(_feed, _timeStamp, lhRound, lhTime, rhRound);
        roundId = getRoundIdForTimestamp(_feed, _timeStamp, foundRoundId, lhRound);
        
        return roundId;
    }

    function getRoundIdForTimestamp(AggregatorV2V3Interface _feed, uint256 _timeStamp, uint80 _roundId, uint80 _firstRoundOfPhase) internal view returns (uint80) {
        uint256 roundTimeStamp = _feed.getTimestamp(_roundId);

        if (roundTimeStamp > _timeStamp && _roundId > _firstRoundOfPhase) {
            _roundId = getRoundIdForTimestamp(_feed, _timeStamp, _roundId - 1, _firstRoundOfPhase);
        } else if (roundTimeStamp > _timeStamp && _roundId == _firstRoundOfPhase) {
            _roundId = 0;
        }
            return _roundId;
    }
}