// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./Interfaces/ICdpManager.sol";
import "./Interfaces/ISortedCdps.sol";
import "./Dependencies/LiquityBase.sol";

contract HintHelpers is LiquityBase {
    string public constant NAME = "HintHelpers";

    ISortedCdps public immutable sortedCdps;
    ICdpManager public immutable cdpManager;

    // --- Events ---

    event SortedCdpsAddressChanged(address _sortedCdpsAddress);
    event CdpManagerAddressChanged(address _cdpManagerAddress);
    event CollateralAddressChanged(address _collTokenAddress);

    struct LocalVariables_getRedemptionHints {
        uint remainingEbtcToRedeem;
        uint minNetDebtInBTC;
        bytes32 currentCdpId;
        address currentCdpUser;
    }

    // --- Dependency setters ---
    constructor(
        address _sortedCdpsAddress,
        address _cdpManagerAddress,
        address _collateralAddress,
        address _activePoolAddress,
        address _priceFeedAddress
    ) LiquityBase(_activePoolAddress, _priceFeedAddress, _collateralAddress) {
        sortedCdps = ISortedCdps(_sortedCdpsAddress);
        cdpManager = ICdpManager(_cdpManagerAddress);

        emit SortedCdpsAddressChanged(_sortedCdpsAddress);
        emit CdpManagerAddressChanged(_cdpManagerAddress);
        emit CollateralAddressChanged(_collateralAddress);
    }

    // --- Functions ---

    /**
     * @notice Get the redemption hints for the specified amount of eBTC, price and maximum number of iterations.
     * @param _EBTCamount The amount of eBTC to be redeemed.
     * @param _price The current price of the asset.
     * @param _maxIterations The maximum number of iterations to be performed.
     * @return firstRedemptionHint The identifier of the first CDP to be considered for redemption.
     * @return partialRedemptionHintNICR The new Nominal Collateral Ratio (NICR) of the CDP after partial redemption.
     * @return truncatedEBTCamount The actual amount of eBTC that can be redeemed.
     * @return partialRedemptionNewColl The new collateral amount after partial redemption.
     */
    function getRedemptionHints(
        uint _EBTCamount,
        uint _price,
        uint _maxIterations
    )
        external
        view
        returns (
            bytes32 firstRedemptionHint,
            uint partialRedemptionHintNICR,
            uint truncatedEBTCamount,
            uint partialRedemptionNewColl
        )
    {
        LocalVariables_getRedemptionHints memory vars;
        {
            vars.remainingEbtcToRedeem = _EBTCamount;
            vars.currentCdpId = sortedCdps.getLast();
            vars.currentCdpUser = sortedCdps.getOwnerAddress(vars.currentCdpId);

            while (
                vars.currentCdpUser != address(0) &&
                cdpManager.getCurrentICR(vars.currentCdpId, _price) < MCR
            ) {
                vars.currentCdpId = sortedCdps.getPrev(vars.currentCdpId);
                vars.currentCdpUser = sortedCdps.getOwnerAddress(vars.currentCdpId);
            }
            firstRedemptionHint = vars.currentCdpId;
        }

        if (_maxIterations == 0) {
            _maxIterations = type(uint256).max;
        }

        // Underflow is intentionally used in _maxIterations-- > 0
        unchecked {
            while (
                vars.currentCdpUser != address(0) &&
                vars.remainingEbtcToRedeem > 0 &&
                _maxIterations-- > 0
            ) {
                // Apply pending debt
                uint currentCdpDebt = cdpManager.getCdpDebt(vars.currentCdpId) +
                    cdpManager.getPendingEBTCDebtReward(vars.currentCdpId);

                // If this CDP has more debt than the remaining to redeem, attempt a partial redemption
                if (currentCdpDebt > vars.remainingEbtcToRedeem) {
                    uint _cachedEbtcToRedeem = vars.remainingEbtcToRedeem;
                    (partialRedemptionNewColl, partialRedemptionHintNICR) = _calculatePartialRedeem(
                        vars,
                        currentCdpDebt,
                        _price
                    );

                    // If the partial redemption would leave the CDP with less than the minimum allowed coll, bail out of partial redemption and return only the fully redeemable
                    // TODO: This seems to return the original coll? why?
                    if (partialRedemptionNewColl < MIN_NET_COLL) {
                        partialRedemptionHintNICR = 0; //reset to 0 as there is no partial redemption in this case
                        vars.remainingEbtcToRedeem = _cachedEbtcToRedeem;
                        break;
                    }
                } else {
                    vars.remainingEbtcToRedeem = vars.remainingEbtcToRedeem - currentCdpDebt;
                }

                vars.currentCdpId = sortedCdps.getPrev(vars.currentCdpId);
                vars.currentCdpUser = sortedCdps.getOwnerAddress(vars.currentCdpId);
            }
        }

        truncatedEBTCamount = _EBTCamount - vars.remainingEbtcToRedeem;
    }

    /**
     * @notice Calculate the partial redemption information.
     * @dev This is an internal function used by getRedemptionHints.
     * @param vars The local variables of the getRedemptionHints function.
     * @param currentCdpDebt The net eBTC debt of the CDP.
     * @param _price The current price of the asset.
     * @return newColl The new collateral amount after partial redemption.
     * @return newNICR The new Nominal Collateral Ratio (NICR) of the CDP after partial redemption.
     */
    function _calculatePartialRedeem(
        LocalVariables_getRedemptionHints memory vars,
        uint currentCdpDebt,
        uint _price
    ) internal view returns (uint, uint) {
        // maxReemable = min(remainingToRedeem, currentDebt)
        uint maxRedeemableEBTC = LiquityMath._min(vars.remainingEbtcToRedeem, currentCdpDebt);

        uint newColl;
        uint _oldIndex = cdpManager.stFPPSg();
        uint _newIndex = collateral.getPooledEthByShares(1e18);

        if (_oldIndex < _newIndex) {
            newColl = _getCollateralWithSplitFeeApplied(vars.currentCdpId, _newIndex, _oldIndex);
        } else {
            (, newColl, ) = cdpManager.getEntireDebtAndColl(vars.currentCdpId);
        }

        vars.remainingEbtcToRedeem = vars.remainingEbtcToRedeem - maxRedeemableEBTC;
        uint collToReceive = collateral.getSharesByPooledEth(
            (maxRedeemableEBTC * DECIMAL_PRECISION) / _price
        );

        uint _newCollAfter = newColl - collToReceive;
        return (
            _newCollAfter,
            LiquityMath._computeNominalCR(_newCollAfter, currentCdpDebt - maxRedeemableEBTC)
        );
    }

    /**
     * @notice Get the collateral amount of a CDP after applying split fee.
     * @dev This is an internal function used by _calculatePartialRedeem.
     * @param _cdpId The identifier of the CDP.
     * @param _newIndex The new index after the split fee is applied.
     * @param _oldIndex The old index before the split fee is applied.
     * @return newColl The new collateral amount after applying split fee.
     */
    function _getCollateralWithSplitFeeApplied(
        bytes32 _cdpId,
        uint _newIndex,
        uint _oldIndex
    ) internal view returns (uint) {
        uint _deltaFeePerUnit;
        uint _newStFeePerUnit;
        uint _perUnitError;
        uint _feeTaken;

        (_feeTaken, _deltaFeePerUnit, _perUnitError) = cdpManager.calcFeeUponStakingReward(
            _newIndex,
            _oldIndex
        );
        _newStFeePerUnit = _deltaFeePerUnit + cdpManager.stFeePerUnitg();
        (, uint newColl) = cdpManager.getAccumulatedFeeSplitApplied(
            _cdpId,
            _newStFeePerUnit,
            _perUnitError,
            cdpManager.totalStakes()
        );
        return newColl;
    }

    /* getApproxHint() - return address of a Cdp that is, on average, (length / numTrials) positions away in the 
    sortedCdps list from the correct insert position of the Cdp to be inserted. 
    
    Note: The output address is worst-case O(n) positions away from the correct insert position, however, the function 
    is probabilistic. Input can be tuned to guarantee results to a high degree of confidence, e.g:

    Submitting numTrials = k * sqrt(length), with k = 15 makes it very, very likely that the ouput address will 
    be <= sqrt(length) positions away from the correct insert position.
    */
    function getApproxHint(
        uint _CR,
        uint _numTrials,
        uint _inputRandomSeed
    ) external view returns (bytes32 hint, uint diff, uint latestRandomSeed) {
        uint arrayLength = cdpManager.getCdpIdsCount();

        if (arrayLength == 0) {
            return (sortedCdps.nonExistId(), 0, _inputRandomSeed);
        }

        hint = sortedCdps.getLast();
        diff = LiquityMath._getAbsoluteDifference(_CR, cdpManager.getNominalICR(hint));
        latestRandomSeed = _inputRandomSeed;

        uint i = 1;

        while (i < _numTrials) {
            latestRandomSeed = uint(keccak256(abi.encodePacked(latestRandomSeed)));

            uint arrayIndex = latestRandomSeed % arrayLength;
            bytes32 _cId = cdpManager.getIdFromCdpIdsArray(arrayIndex);
            uint currentNICR = cdpManager.getNominalICR(_cId);

            // check if abs(current - CR) > abs(closest - CR), and update closest if current is closer
            uint currentDiff = LiquityMath._getAbsoluteDifference(currentNICR, _CR);

            if (currentDiff < diff) {
                diff = currentDiff;
                hint = _cId;
            }
            i++;
        }
    }

    /// @notice Compute nominal CR for a specified collateral and debt amount
    function computeNominalCR(uint _coll, uint _debt) external pure returns (uint) {
        return LiquityMath._computeNominalCR(_coll, _debt);
    }

    /// @notice Compute CR for a specified collateral and debt amount
    function computeCR(uint _coll, uint _debt, uint _price) external pure returns (uint) {
        return LiquityMath._computeCR(_coll, _debt, _price);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract BaseMath {
    uint public constant DECIMAL_PRECISION = 1e18;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./IERC20.sol";

/**
 * Based on the stETH:
 *  -   https://docs.lido.fi/contracts/lido#
 */
interface ICollateralToken is IERC20 {
    // Returns the amount of shares that corresponds to _ethAmount protocol-controlled Ether
    function getSharesByPooledEth(uint256 _ethAmount) external view returns (uint256);

    // Returns the amount of Ether that corresponds to _sharesAmount token shares
    function getPooledEthByShares(uint256 _sharesAmount) external view returns (uint256);

    // Moves `_sharesAmount` token shares from the caller's account to the `_recipient` account.
    function transferShares(address _recipient, uint256 _sharesAmount) external returns (uint256);

    // Returns the amount of shares owned by _account
    function sharesOf(address _account) external view returns (uint256);

    // Returns authorized oracle address
    function getOracle() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * Based on the stETH:
 *  -   https://docs.lido.fi/contracts/lido#
 */
interface ICollateralTokenOracle {
    // Return beacon specification data.
    function getBeaconSpec()
        external
        view
        returns (
            uint64 epochsPerFrame,
            uint64 slotsPerEpoch,
            uint64 secondsPerSlot,
            uint64 genesisTime
        );
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

/**
 * Based on the OpenZeppelin IER20 interface:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol
 *
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

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

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

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

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

pragma solidity 0.8.17;

/**
 * @dev Interface of the ERC2612 standard as defined in the EIP.
 *
 * Adds the {permit} method, which can be used to change one's
 * {IERC20-allowance} without having to send a transaction, by signing a
 * message. This allows users to spend tokens without having to hold Ether.
 *
 * See https://eips.ethereum.org/EIPS/eip-2612.
 *
 * Code adapted from https://github.com/OpenZeppelin/openzeppelin-contracts/pull/2237/
 */
interface IERC2612 {
    /**
     * @dev Sets `amount` as the allowance of `spender` over `owner`'s tokens,
     * given `owner`'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
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
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current ERC2612 nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases `owner`'s nonce by one. This
     * prevents a signature from being used multiple times.
     *
     * `owner` can limit the time a Permit is valid for by setting `deadline` to
     * a value in the near future. The deadline argument can be set to uint(-1) to
     * create Permits that effectively never expire.
     */
    function nonces(address owner) external view returns (uint256);

    function version() external view returns (string memory);

    function permitTypeHash() external view returns (bytes32);

    function domainSeparator() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./BaseMath.sol";
import "./LiquityMath.sol";
import "../Interfaces/IActivePool.sol";
import "../Interfaces/IPriceFeed.sol";
import "../Interfaces/ILiquityBase.sol";
import "../Dependencies/ICollateralToken.sol";

/*
 * Base contract for CdpManager, BorrowerOperations. Contains global system constants and
 * common functions.
 */
contract LiquityBase is BaseMath, ILiquityBase {
    uint public constant _100pct = 1000000000000000000; // 1e18 == 100%
    uint public constant _105pct = 1050000000000000000; // 1.05e18 == 105%
    uint public constant _5pct = 50000000000000000; // 5e16 == 5%

    // Collateral Ratio applied for Liquidation Incentive
    // i.e., liquidator repay $1 worth of debt to get back $1.03 worth of collateral
    uint public constant LICR = 1030000000000000000; // 103%

    // Minimum collateral ratio for individual cdps
    uint public constant MCR = 1100000000000000000; // 110%

    // Critical system collateral ratio. If the system's total collateral ratio (TCR) falls below the CCR, Recovery Mode is triggered.
    uint public constant CCR = 1250000000000000000; // 125%

    // Amount of stETH collateral to be locked in active pool on opening cdps
    uint public constant LIQUIDATOR_REWARD = 2e17;

    // Minimum amount of stETH collateral a CDP must have
    uint public constant MIN_NET_COLL = 2e18;

    uint public constant PERCENT_DIVISOR = 200; // dividing by 200 yields 0.5%

    uint public constant BORROWING_FEE_FLOOR = 0; // 0.5%

    uint public constant STAKING_REWARD_SPLIT = 2_500; // taking 25% cut from staking reward

    uint public constant MAX_REWARD_SPLIT = 10_000;

    IActivePool public immutable activePool;

    IPriceFeed public immutable override priceFeed;

    // the only collateral token allowed in CDP
    ICollateralToken public immutable collateral;

    constructor(address _activePoolAddress, address _priceFeedAddress, address _collateralAddress) {
        activePool = IActivePool(_activePoolAddress);
        priceFeed = IPriceFeed(_priceFeedAddress);
        collateral = ICollateralToken(_collateralAddress);
    }

    // --- Gas compensation functions ---

    function _getNetColl(uint _coll) internal pure returns (uint) {
        return _coll - LIQUIDATOR_REWARD;
    }

    // Return the amount of ETH to be drawn from a cdp's collateral and sent as gas compensation.
    function _getCollGasCompensation(uint _entireColl) internal pure returns (uint) {
        return _entireColl / PERCENT_DIVISOR;
    }

    /**
        @notice Get the entire system collateral
        @notice Entire system collateral = collateral stored in ActivePool, using their internal accounting
        @dev Coll stored for liquidator rewards or coll in CollSurplusPool are not included
     */
    function getEntireSystemColl() public view returns (uint entireSystemColl) {
        return (activePool.getStEthColl());
    }

    /**
        @notice Get the entire system debt
        @notice Entire system collateral = collateral stored in ActivePool, using their internal accounting
     */
    function _getEntireSystemDebt() internal view returns (uint entireSystemDebt) {
        return (activePool.getEBTCDebt());
    }

    function _getTCR(uint256 _price) internal view returns (uint TCR) {
        (TCR, , ) = _getTCRWithTotalCollAndDebt(_price);
    }

    function _getTCRWithTotalCollAndDebt(
        uint256 _price
    ) internal view returns (uint TCR, uint _coll, uint _debt) {
        uint entireSystemColl = getEntireSystemColl();
        uint entireSystemDebt = _getEntireSystemDebt();

        uint _underlyingCollateral = collateral.getPooledEthByShares(entireSystemColl);
        TCR = LiquityMath._computeCR(_underlyingCollateral, entireSystemDebt, _price);

        return (TCR, entireSystemColl, entireSystemDebt);
    }

    function _checkRecoveryMode(uint256 _price) internal view returns (bool) {
        return _getTCR(_price) < CCR;
    }

    function _requireUserAcceptsFee(uint _fee, uint _amount, uint _maxFeePercentage) internal pure {
        uint feePercentage = (_fee * DECIMAL_PRECISION) / _amount;
        require(feePercentage <= _maxFeePercentage, "Fee exceeded provided maximum");
    }

    // Convert ETH/BTC price to BTC/ETH price
    function _getPriceReciprocal(uint _price) internal pure returns (uint) {
        return (DECIMAL_PRECISION * DECIMAL_PRECISION) / _price;
    }

    // Convert debt denominated in BTC to debt denominated in ETH given that _price is ETH/BTC
    // _debt is denominated in BTC
    // _price is ETH/BTC
    function _convertDebtDenominationToEth(uint _debt, uint _price) internal pure returns (uint) {
        uint priceReciprocal = _getPriceReciprocal(_price);
        return (_debt * priceReciprocal) / DECIMAL_PRECISION;
    }

    // Convert debt denominated in ETH to debt denominated in BTC given that _price is ETH/BTC
    // _debt is denominated in ETH
    // _price is ETH/BTC
    function _convertDebtDenominationToBtc(uint _debt, uint _price) internal pure returns (uint) {
        return (_debt * _price) / DECIMAL_PRECISION;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

library LiquityMath {
    uint internal constant DECIMAL_PRECISION = 1e18;

    /* Precision for Nominal ICR (independent of price). Rationale for the value:
     *
     * - Making it “too high” could lead to overflows.
     * - Making it “too low” could lead to an ICR equal to zero, due to truncation from Solidity floor division.
     *
     * This value of 1e20 is chosen for safety: the NICR will only overflow for numerator > ~1e39 ETH,
     * and will only truncate to 0 if the denominator is at least 1e20 times greater than the numerator.
     *
     */
    uint internal constant NICR_PRECISION = 1e20;

    function _min(uint _a, uint _b) internal pure returns (uint) {
        return (_a < _b) ? _a : _b;
    }

    function _max(uint _a, uint _b) internal pure returns (uint) {
        return (_a >= _b) ? _a : _b;
    }

    /*
     * Multiply two decimal numbers and use normal rounding rules:
     * -round product up if 19'th mantissa digit >= 5
     * -round product down if 19'th mantissa digit < 5
     *
     * Used only inside the exponentiation, _decPow().
     */
    function decMul(uint x, uint y) internal pure returns (uint decProd) {
        uint prod_xy = x * y;

        decProd = (prod_xy + (DECIMAL_PRECISION / 2)) / DECIMAL_PRECISION;
    }

    /*
     * _decPow: Exponentiation function for 18-digit decimal base, and integer exponent n.
     *
     * Uses the efficient "exponentiation by squaring" algorithm. O(log(n)) complexity.
     *
     * Called by two functions that represent time in units of minutes:
     * 1) CdpManager._calcDecayedBaseRate
     * 2) CommunityIssuance._getCumulativeIssuanceFraction
     *
     * The exponent is capped to avoid reverting due to overflow. The cap 525600000 equals
     * "minutes in 1000 years": 60 * 24 * 365 * 1000
     *
     * If a period of > 1000 years is ever used as an exponent in either of the above functions, the result will be
     * negligibly different from just passing the cap, since:
     *
     * In function 1), the decayed base rate will be 0 for 1000 years or > 1000 years
     * In function 2), the difference in tokens issued at 1000 years and any time > 1000 years, will be negligible
     */
    function _decPow(uint _base, uint _minutes) internal pure returns (uint) {
        if (_minutes > 525600000) {
            _minutes = 525600000;
        } // cap to avoid overflow

        if (_minutes == 0) {
            return DECIMAL_PRECISION;
        }

        uint y = DECIMAL_PRECISION;
        uint x = _base;
        uint n = _minutes;

        // Exponentiation-by-squaring
        while (n > 1) {
            if (n % 2 == 0) {
                x = decMul(x, x);
                n = n / 2;
            } else {
                // if (n % 2 != 0)
                y = decMul(x, y);
                x = decMul(x, x);
                n = (n - 1) / 2;
            }
        }

        return decMul(x, y);
    }

    function _getAbsoluteDifference(uint _a, uint _b) internal pure returns (uint) {
        return (_a >= _b) ? (_a - _b) : (_b - _a);
    }

    function _computeNominalCR(uint _coll, uint _debt) internal pure returns (uint) {
        if (_debt > 0) {
            return (_coll * NICR_PRECISION) / _debt;
        }
        // Return the maximal value for uint256 if the Cdp has a debt of 0. Represents "infinite" CR.
        else {
            // if (_debt == 0)
            return 2 ** 256 - 1;
        }
    }

    function _computeCR(uint _coll, uint _debt, uint _price) internal pure returns (uint) {
        if (_debt > 0) {
            uint newCollRatio = (_coll * _price) / _debt;

            return newCollRatio;
        }
        // Return the maximal value for uint256 if the Cdp has a debt of 0. Represents "infinite" CR.
        else {
            // if (_debt == 0)
            return 2 ** 256 - 1;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./IPool.sol";

interface IActivePool is IPool {
    // --- Events ---
    event BorrowerOperationsAddressChanged(address _newBorrowerOperationsAddress);
    event CdpManagerAddressChanged(address _newCdpManagerAddress);
    event ActivePoolEBTCDebtUpdated(uint _EBTCDebt);
    event ActivePoolCollBalanceUpdated(uint _coll);
    event CollateralAddressChanged(address _collTokenAddress);
    event FeeRecipientAddressChanged(address _feeRecipientAddress);
    event CollSurplusPoolAddressChanged(address _collSurplusAddress);
    event ActivePoolFeeRecipientClaimableCollIncreased(uint _coll, uint _fee);
    event ActivePoolFeeRecipientClaimableCollDecreased(uint _coll, uint _fee);
    event FlashLoanSuccess(address _receiver, address _token, uint _amount, uint _fee);
    event SweepTokenSuccess(address _token, uint _amount, address _recipient);

    // --- Functions ---
    function sendStEthColl(address _account, uint _amount) external;

    function receiveColl(uint _value) external;

    function sendStEthCollAndLiquidatorReward(
        address _account,
        uint _shares,
        uint _liquidatorRewardShares
    ) external;

    function allocateFeeRecipientColl(uint _shares) external;

    function claimFeeRecipientColl(uint _shares) external;

    function feeRecipientAddress() external view returns (address);

    function getFeeRecipientClaimableColl() external view returns (uint);

    function setFeeRecipientAddress(address _feeRecipientAddress) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./ILiquityBase.sol";
import "./IEBTCToken.sol";
import "./IFeeRecipient.sol";
import "./ICollSurplusPool.sol";
import "./ICdpManagerData.sol";

// Common interface for the Cdp Manager.
interface ICdpManager is ILiquityBase, ICdpManagerData {
    // --- Functions ---
    function getCdpIdsCount() external view returns (uint);

    function getIdFromCdpIdsArray(uint _index) external view returns (bytes32);

    function getNominalICR(bytes32 _cdpId) external view returns (uint);

    function getCurrentICR(bytes32 _cdpId, uint _price) external view returns (uint);

    function liquidate(bytes32 _cdpId) external;

    function partiallyLiquidate(
        bytes32 _cdpId,
        uint256 _partialAmount,
        bytes32 _upperPartialHint,
        bytes32 _lowerPartialHint
    ) external;

    function liquidateCdps(uint _n) external;

    function batchLiquidateCdps(bytes32[] calldata _cdpArray) external;

    function redeemCollateral(
        uint _EBTCAmount,
        bytes32 _firstRedemptionHint,
        bytes32 _upperPartialRedemptionHint,
        bytes32 _lowerPartialRedemptionHint,
        uint _partialRedemptionHintNICR,
        uint _maxIterations,
        uint _maxFee
    ) external;

    function updateStakeAndTotalStakes(bytes32 _cdpId) external returns (uint);

    function updateCdpRewardSnapshots(bytes32 _cdpId) external;

    function addCdpIdToArray(bytes32 _cdpId) external returns (uint index);

    function applyPendingRewards(bytes32 _cdpId) external;

    function getTotalStakeForFeeTaken(uint _feeTaken) external view returns (uint, uint);

    function syncUpdateIndexInterval() external returns (uint);

    function getPendingEBTCDebtReward(bytes32 _cdpId) external view returns (uint);

    function hasPendingRewards(bytes32 _cdpId) external view returns (bool);

    function getEntireDebtAndColl(
        bytes32 _cdpId
    ) external view returns (uint debt, uint coll, uint pendingEBTCDebtReward);

    function closeCdp(bytes32 _cdpId) external;

    function removeStake(bytes32 _cdpId) external;

    function getRedemptionRate() external view returns (uint);

    function getRedemptionRateWithDecay() external view returns (uint);

    function getRedemptionFeeWithDecay(uint _ETHDrawn) external view returns (uint);

    function getBorrowingRate() external view returns (uint);

    function getBorrowingRateWithDecay() external view returns (uint);

    function getBorrowingFee(uint EBTCDebt) external view returns (uint);

    function getBorrowingFeeWithDecay(uint _EBTCDebt) external view returns (uint);

    function decayBaseRateFromBorrowing() external;

    function getCdpStatus(bytes32 _cdpId) external view returns (uint);

    function getCdpStake(bytes32 _cdpId) external view returns (uint);

    function getCdpDebt(bytes32 _cdpId) external view returns (uint);

    function getCdpColl(bytes32 _cdpId) external view returns (uint);

    function getCdpLiquidatorRewardShares(bytes32 _cdpId) external view returns (uint);

    function setCdpStatus(bytes32 _cdpId, uint num) external;

    function increaseCdpColl(bytes32 _cdpId, uint _collIncrease) external returns (uint);

    function decreaseCdpColl(bytes32 _cdpId, uint _collDecrease) external returns (uint);

    function increaseCdpDebt(bytes32 _cdpId, uint _debtIncrease) external returns (uint);

    function decreaseCdpDebt(bytes32 _cdpId, uint _collDecrease) external returns (uint);

    function setCdpLiquidatorRewardShares(bytes32 _cdpId, uint _liquidatorRewardShares) external;

    function getTCR(uint _price) external view returns (uint);

    function checkRecoveryMode(uint _price) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./ICollSurplusPool.sol";
import "./IEBTCToken.sol";
import "./ISortedCdps.sol";
import "./IActivePool.sol";
import "../Dependencies/ICollateralTokenOracle.sol";

// Common interface for the Cdp Manager.
interface ICdpManagerData {
    // --- Events ---

    event LiquidationLibraryAddressChanged(address _liquidationLibraryAddress);
    event BorrowerOperationsAddressChanged(address _newBorrowerOperationsAddress);
    event PriceFeedAddressChanged(address _newPriceFeedAddress);
    event EBTCTokenAddressChanged(address _newEBTCTokenAddress);
    event ActivePoolAddressChanged(address _activePoolAddress);
    event CollSurplusPoolAddressChanged(address _collSurplusPoolAddress);
    event SortedCdpsAddressChanged(address _sortedCdpsAddress);
    event FeeRecipientAddressChanged(address _feeRecipientAddress);
    event CollateralAddressChanged(address _collTokenAddress);
    event StakingRewardSplitSet(uint256 _stakingRewardSplit);
    event RedemptionFeeFloorSet(uint256 _redemptionFeeFloor);
    event MinuteDecayFactorSet(uint256 _minuteDecayFactor);
    event BetaSet(uint256 _beta);

    event Liquidation(uint _liquidatedDebt, uint _liquidatedColl, uint _liqReward);
    event Redemption(uint _attemptedEBTCAmount, uint _actualEBTCAmount, uint _ETHSent, uint _ETHFee);
    event CdpUpdated(
        bytes32 indexed _cdpId,
        address indexed _borrower,
        uint _oldDebt,
        uint _oldColl,
        uint _debt,
        uint _coll,
        uint _stake,
        CdpManagerOperation _operation
    );
    event CdpLiquidated(
        bytes32 indexed _cdpId,
        address indexed _borrower,
        uint _debt,
        uint _coll,
        CdpManagerOperation _operation
    );
    event CdpPartiallyLiquidated(
        bytes32 indexed _cdpId,
        address indexed _borrower,
        uint _debt,
        uint _coll,
        CdpManagerOperation operation
    );
    event BaseRateUpdated(uint _baseRate);
    event LastFeeOpTimeUpdated(uint _lastFeeOpTime);
    event TotalStakesUpdated(uint _newTotalStakes);
    event SystemSnapshotsUpdated(uint _totalStakesSnapshot, uint _totalCollateralSnapshot);
    event LTermsUpdated(uint _L_EBTCDebt);
    event CdpSnapshotsUpdated(bytes32 _cdpId, uint _L_EBTCDebt);
    event CdpIndexUpdated(bytes32 _cdpId, uint _newIndex);
    event CollateralGlobalIndexUpdated(uint _oldIndex, uint _newIndex, uint _updTimestamp);
    event CollateralIndexUpdateIntervalUpdated(uint _oldInterval, uint _newInterval);
    event CollateralFeePerUnitUpdated(uint _oldPerUnit, uint _newPerUnit, uint _feeTaken);
    event CdpFeeSplitApplied(
        bytes32 _cdpId,
        uint _oldPerUnitCdp,
        uint _newPerUnitCdp,
        uint _collReduced,
        uint collLeft
    );

    enum CdpManagerOperation {
        applyPendingRewards,
        liquidateInNormalMode,
        liquidateInRecoveryMode,
        redeemCollateral,
        partiallyLiquidate
    }

    enum Status {
        nonExistent,
        active,
        closedByOwner,
        closedByLiquidation,
        closedByRedemption
    }

    // Store the necessary data for a cdp
    struct Cdp {
        uint debt;
        uint coll;
        uint stake;
        uint liquidatorRewardShares;
        Status status;
        uint128 arrayIndex;
    }

    /*
     * --- Variable container structs for liquidations ---
     *
     * These structs are used to hold, return and assign variables inside the liquidation functions,
     * in order to avoid the error: "CompilerError: Stack too deep".
     **/

    struct LocalVar_CdpDebtColl {
        uint256 entireDebt;
        uint256 entireColl;
        uint256 pendingDebtReward;
    }

    struct LocalVar_InternalLiquidate {
        bytes32 _cdpId;
        uint256 _partialAmount; // used only for partial liquidation, default 0 means full liquidation
        uint256 _price;
        uint256 _ICR;
        bytes32 _upperPartialHint;
        bytes32 _lowerPartialHint;
        bool _recoveryModeAtStart;
        uint256 _TCR;
        uint256 totalColSurplus;
        uint256 totalColToSend;
        uint256 totalDebtToBurn;
        uint256 totalDebtToRedistribute;
        uint256 totalColReward;
        bool sequenceLiq;
    }

    struct LocalVar_RecoveryLiquidate {
        uint256 entireSystemDebt;
        uint256 entireSystemColl;
        uint256 totalDebtToBurn;
        uint256 totalColToSend;
        uint256 totalColSurplus;
        bytes32 _cdpId;
        uint256 _price;
        uint256 _ICR;
        uint256 totalDebtToRedistribute;
        uint256 totalColReward;
        bool sequenceLiq;
    }

    struct LocalVariables_OuterLiquidationFunction {
        uint price;
        bool recoveryModeAtStart;
        uint liquidatedDebt;
        uint liquidatedColl;
    }

    struct LocalVariables_LiquidationSequence {
        uint i;
        uint ICR;
        bytes32 cdpId;
        bool backToNormalMode;
        uint entireSystemDebt;
        uint entireSystemColl;
        uint price;
        uint TCR;
    }

    struct LocalVariables_RedeemCollateralFromCdp {
        bytes32 _cdpId;
        uint _maxEBTCamount;
        uint _price;
        bytes32 _upperPartialRedemptionHint;
        bytes32 _lowerPartialRedemptionHint;
        uint _partialRedemptionHintNICR;
    }

    struct LiquidationValues {
        uint entireCdpDebt;
        uint debtToOffset;
        uint totalCollToSendToLiquidator;
        uint debtToRedistribute;
        uint collToRedistribute;
        uint collSurplus;
        uint collReward;
    }

    struct LiquidationTotals {
        uint totalDebtInSequence;
        uint totalDebtToOffset;
        uint totalCollToSendToLiquidator;
        uint totalDebtToRedistribute;
        uint totalCollToRedistribute;
        uint totalCollSurplus;
        uint totalCollReward;
    }

    // --- Variable container structs for redemptions ---

    struct RedemptionTotals {
        uint remainingEBTC;
        uint totalEBTCToRedeem;
        uint totalETHDrawn;
        uint ETHFee;
        uint ETHToSendToRedeemer;
        uint decayedBaseRate;
        uint price;
        uint totalEBTCSupplyAtStart;
    }

    struct SingleRedemptionValues {
        uint eBtcToRedeem;
        uint stEthToRecieve;
        bool cancelledPartial;
        bool fullRedemption;
    }

    function totalStakes() external view returns (uint);

    function ebtcToken() external view returns (IEBTCToken);

    function stFeePerUnitg() external view returns (uint);

    function stFeePerUnitgError() external view returns (uint);

    function stFPPSg() external view returns (uint);

    function calcFeeUponStakingReward(
        uint256 _newIndex,
        uint256 _prevIndex
    ) external view returns (uint256, uint256, uint256);

    function claimStakingSplitFee() external;

    function getAccumulatedFeeSplitApplied(
        bytes32 _cdpId,
        uint _stFeePerUnitg,
        uint _stFeePerUnitgError,
        uint _totalStakes
    ) external view returns (uint, uint);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface ICollSurplusPool {
    // --- Events ---

    event BorrowerOperationsAddressChanged(address _newBorrowerOperationsAddress);
    event CdpManagerAddressChanged(address _newCdpManagerAddress);
    event ActivePoolAddressChanged(address _newActivePoolAddress);
    event CollateralAddressChanged(address _collTokenAddress);

    event CollBalanceUpdated(address indexed _account, uint _newBalance);
    event CollateralSent(address _to, uint _amount);

    event SweepTokenSuccess(address _token, uint _amount, address _recipient);

    // --- Contract setters ---

    function getStEthColl() external view returns (uint);

    function getCollateral(address _account) external view returns (uint);

    function accountSurplus(address _account, uint _amount) external;

    function claimColl(address _account) external;

    function receiveColl(uint _value) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "../Dependencies/IERC20.sol";
import "../Dependencies/IERC2612.sol";

interface IEBTCToken is IERC20, IERC2612 {
    // --- Events ---

    event CdpManagerAddressChanged(address _cdpManagerAddress);
    event BorrowerOperationsAddressChanged(address _newBorrowerOperationsAddress);

    event EBTCTokenBalanceUpdated(address _user, uint _amount);

    // --- Functions ---

    function mint(address _account, uint256 _amount) external;

    function burn(address _account, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IFeeRecipient {
    // --- Events --

    event EBTCTokenAddressSet(address _ebtcTokenAddress);
    event CdpManagerAddressSet(address _cdpManager);
    event BorrowerOperationsAddressSet(address _borrowerOperationsAddress);
    event ActivePoolAddressSet(address _activePoolAddress);
    event CollateralAddressSet(address _collTokenAddress);

    event ReceiveFee(address indexed _sender, address indexed _token, uint _amount);
    event CollateralSent(address _account, uint _amount);

    // --- Functions ---

    function receiveStEthFee(uint _ETHFee) external;

    function receiveEbtcFee(uint _EBTCFee) external;

    function claimStakingSplitFee() external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./IPriceFeed.sol";

interface ILiquityBase {
    function priceFeed() external view returns (IPriceFeed);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

// Common interface for the Pools.
interface IPool {
    // --- Events ---

    event ETHBalanceUpdated(uint _newBalance);
    event EBTCBalanceUpdated(uint _newBalance);
    event ActivePoolAddressChanged(address _newActivePoolAddress);
    event CollateralSent(address _to, uint _amount);

    // --- Functions ---

    function getStEthColl() external view returns (uint);

    function getEBTCDebt() external view returns (uint);

    function increaseEBTCDebt(uint _amount) external;

    function decreaseEBTCDebt(uint _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IPriceFeed {
    // --- Events ---
    event LastGoodPriceUpdated(uint _lastGoodPrice);
    event PriceFeedStatusChanged(Status newStatus);
    event FallbackCallerChanged(address _oldFallbackCaller, address _newFallbackCaller);
    event UnhealthyFallbackCaller(address _fallbackCaller, uint256 timestamp);

    // --- Structs ---

    struct ChainlinkResponse {
        uint80 roundEthBtcId;
        uint80 roundStEthEthId;
        uint256 answer;
        uint256 timestampEthBtc;
        uint256 timestampStEthEth;
        bool success;
    }

    struct FallbackResponse {
        uint256 answer;
        uint256 timestamp;
        bool success;
    }

    // --- Enum ---

    enum Status {
        chainlinkWorking,
        usingFallbackChainlinkUntrusted,
        bothOraclesUntrusted,
        usingFallbackChainlinkFrozen,
        usingChainlinkFallbackUntrusted
    }

    // --- Function ---
    function fetchPrice() external returns (uint);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

// Common interface for the SortedCdps Doubly Linked List.
interface ISortedCdps {
    // --- Events ---

    event CdpManagerAddressChanged(address _cdpManagerAddress);
    event SortedCdpsAddressChanged(address _sortedDoublyLLAddress);
    event BorrowerOperationsAddressChanged(address _borrowerOperationsAddress);
    event NodeAdded(bytes32 _id, uint _NICR);
    event NodeRemoved(bytes32 _id);

    // --- Functions ---

    function remove(bytes32 _id) external;

    function batchRemove(bytes32[] memory _ids) external;

    function reInsert(bytes32 _id, uint256 _newICR, bytes32 _prevId, bytes32 _nextId) external;

    function contains(bytes32 _id) external view returns (bool);

    function isFull() external view returns (bool);

    function isEmpty() external view returns (bool);

    function getSize() external view returns (uint256);

    function getMaxSize() external view returns (uint256);

    function getFirst() external view returns (bytes32);

    function getLast() external view returns (bytes32);

    function getNext(bytes32 _id) external view returns (bytes32);

    function getPrev(bytes32 _id) external view returns (bytes32);

    function validInsertPosition(
        uint256 _ICR,
        bytes32 _prevId,
        bytes32 _nextId
    ) external view returns (bool);

    function findInsertPosition(
        uint256 _ICR,
        bytes32 _prevId,
        bytes32 _nextId
    ) external view returns (bytes32, bytes32);

    function insert(
        address owner,
        uint256 _ICR,
        bytes32 _prevId,
        bytes32 _nextId
    ) external returns (bytes32);

    function getOwnerAddress(bytes32 _id) external pure returns (address);

    function existCdpOwners(bytes32 _id) external view returns (address);

    function nonExistId() external view returns (bytes32);

    function cdpCountOf(address owner) external view returns (uint256);

    function getCdpsOf(address owner) external view returns (bytes32[] memory);

    function cdpOfOwnerByIndex(address owner, uint256 index) external view returns (bytes32);

    // Mapping from cdp owner to list of owned cdp IDs
    // mapping(address => mapping(uint256 => bytes32)) public _ownedCdps;
    function _ownedCdps(address, uint256) external view returns (bytes32);

    // Mapping from cdp ID to index within owner cdp list
    // mapping(bytes32 => uint256) public _ownedCdpIndex;
    function _ownedCdpIndex(bytes32) external view returns (uint256);

    // Mapping from cdp owner to its owned cdps count
    // mapping(address => uint256) public _ownedCount;
    function _ownedCount(address) external view returns (uint256);
}