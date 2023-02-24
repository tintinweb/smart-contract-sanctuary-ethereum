// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.10;

import {IPnL} from "IPnL.sol";
import {IGTranche} from "IGTranche.sol";
import {PnLErrors} from "PnLErrors.sol";

//  ________  ________  ________
//  |\   ____\|\   __  \|\   __  \
//  \ \  \___|\ \  \|\  \ \  \|\  \
//   \ \  \  __\ \   _  _\ \  \\\  \
//    \ \  \|\  \ \  \\  \\ \  \\\  \
//     \ \_______\ \__\\ _\\ \_______\
//      \|_______|\|__|\|__|\|_______|

// gro protocol: https://github.com/groLabs/GSquared

/// @title PnLFixedRate
/// @notice PnL - Separate contract for defining profit and loss calculation for the GTranche.
///     This implementation provides fix rate income to the Senior tranche. Fixed rate being
///     defined as a % APY for the senior tranche. The implementation gives a constant stream
///     of assets from the junior to the senior tranche, independent of yields or other system
///     wide gains for the tranche. Its recommended that the tranches underlying 4626 tokens
///     support slow release, and that this slow release is adjusted accordingly to the fixed
///     rate, as to not create intermediary loss for the junior tranche between yield generating
///     events. Note that all normal yields (from 4626 harvests) are distributed to the junior
///     tranche, and that the Senior tranche
contract PnLFixedRate is IPnL {
    int256 internal constant DEFAULT_DECIMALS = 10_000;
    int256 internal constant YEAR_IN_SECONDS = 31556952;

    // tranche logic
    uint256 constant NO_OF_TRANCHES = 2;
    address internal immutable gTranche;

    address public owner;

    struct FixedRate {
        int64 rate;
        int64 pendingRate;
        uint64 lastDistribution;
    }

    FixedRate public fixedRate;

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event LogNewFixedRate(int64 rate);
    event LogNewPendingFixedRate(int64 pendingRate);
    event LogNewFixedRateDistribution(int256 seniorProfit);
    event LogOwnershipTransferred(address oldOwner, address newOwner);

    constructor(address _gTranche) {
        gTranche = _gTranche;
        owner = msg.sender;
        fixedRate.rate = 200;
        fixedRate.lastDistribution = uint64(block.timestamp);
    }

    /*//////////////////////////////////////////////////////////////
                            SETTERS
    //////////////////////////////////////////////////////////////*/

    /// @notice Change owner of the strategy
    /// @param _owner new strategy owner
    function setOwner(address _owner) external {
        if (msg.sender != owner) revert PnLErrors.NotOwner();
        address previous_owner = msg.sender;
        owner = _owner;

        emit LogOwnershipTransferred(previous_owner, _owner);
    }

    /// @notice Sets a new fixed rate for the tranche, the
    ///     rate will take affect during the next interaction
    function setRate(int64 _rate) external {
        if (_rate < 0 || _rate > DEFAULT_DECIMALS) revert PnLErrors.BadRate();
        if (msg.sender != owner) revert PnLErrors.NotOwner();
        fixedRate.pendingRate = _rate;
        emit LogNewPendingFixedRate(_rate);
    }

    /*//////////////////////////////////////////////////////////////
                            CORE LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Calculate fixed rate distribution for senior tranche
    function _calc_rate(int256 _seniorBalance)
        internal
        view
        returns (int256 seniorProfit)
    {
        FixedRate storage _rates = fixedRate;
        int256 _timeDiff = int256(block.timestamp - _rates.lastDistribution);
        seniorProfit =
            (_seniorBalance * _rates.rate * _timeDiff) /
            (DEFAULT_DECIMALS * YEAR_IN_SECONDS);
    }

    /// @notice Calculate distribution of assets changes of underlying yield tokens
    /// @param _amount amount of loss to distribute
    /// @param _trancheBalances balances of current tranches in common denominator
    function distributeAssets(
        bool _loss,
        int256 _amount,
        int256[NO_OF_TRANCHES] calldata _trancheBalances
    ) external override returns (int256[NO_OF_TRANCHES] memory amounts) {
        if (msg.sender != gTranche) revert PnLErrors.NotTranche();
        if (_loss) {
            amounts = distributeLoss(_amount, _trancheBalances);
        } else {
            amounts = distributeProfit(_amount, _trancheBalances);
        }
        int64 _pendingRate = fixedRate.pendingRate;
        if (_pendingRate > 0) {
            fixedRate.rate = _pendingRate;
            fixedRate.pendingRate = 0;
            emit LogNewFixedRate(_pendingRate);
        }
        fixedRate.lastDistribution = uint64(block.timestamp);
        emit LogNewFixedRateDistribution(amounts[1]);
    }

    /// @notice Calculate distribution of negative changes of underlying yield tokens
    /// @param _amount amount of loss to distribute
    /// @param _trancheBalances balances of current tranches in common denominator
    function distributeLoss(
        int256 _amount,
        int256[NO_OF_TRANCHES] calldata _trancheBalances
    ) public view override returns (int256[NO_OF_TRANCHES] memory loss) {
        int256 seniorProfit = _calc_rate(_trancheBalances[1]);
        if (_amount + seniorProfit > _trancheBalances[0]) {
            loss[0] = _trancheBalances[0];
            loss[1] = _amount - _trancheBalances[0];
        } else {
            loss[0] = _amount + seniorProfit;
            // The senior tranche will experience negative loss == fixed rate profit
            loss[1] = -1 * seniorProfit;
        }
    }

    /// @notice Calculate distribution of positive changes of underlying yield tokens
    /// @param _amount amount of profit to distribute
    /// @param _trancheBalances balances of current tranches in common denominator
    function distributeProfit(
        int256 _amount,
        int256[NO_OF_TRANCHES] calldata _trancheBalances
    ) public view override returns (int256[NO_OF_TRANCHES] memory profit) {
        int256 _utilisation = (_trancheBalances[1] * DEFAULT_DECIMALS) /
            (_trancheBalances[0] + 1);
        if (_utilisation < int256(IGTranche(gTranche).utilisationThreshold())) {
            int256 seniorProfit = _calc_rate(_trancheBalances[1]);
            // if rate distribution is greater than profit, the junior tranche
            //  will experience negative profit, e.g. a loss
            if (_trancheBalances[0] < seniorProfit - _amount) {
                profit[0] = -_trancheBalances[0];
                profit[1] = _amount + _trancheBalances[0];
            } else {
                profit[0] = _amount - seniorProfit;
                profit[1] = seniorProfit;
            }
        } else {
            profit[0] = _amount;
        }
    }
}

// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.10;

/// @title IPnL
/// @notice PnL interface for a dsitribution module with two tranches
interface IPnL {
    function distributeAssets(
        bool _loss,
        int256 _amount,
        int256[2] calldata _trancheBalances
    ) external returns (int256[2] memory amounts);

    function distributeLoss(int256 _amount, int256[2] calldata _trancheBalances)
        external
        view
        returns (int256[2] memory loss);

    function distributeProfit(
        int256 _amount,
        int256[2] calldata _trancheBalances
    ) external view returns (int256[2] memory profit);
}

// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.10;

interface IGTranche {
    function deposit(
        uint256 _amount,
        uint256 _index,
        bool _tranche,
        address recipient
    ) external returns (uint256, uint256);

    function withdraw(
        uint256 _amount,
        uint256 _index,
        bool _tranche,
        address recipient
    ) external returns (uint256, uint256);

    function finalizeMigration() external;

    function utilisationThreshold() external view returns (uint256);
}

// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.10;

library PnLErrors {
    error NotOwner(); // 0x30cd7471
    error NotTranche(); // 0x40fff8ff
    error BadRate(); // 0x491dee21
}