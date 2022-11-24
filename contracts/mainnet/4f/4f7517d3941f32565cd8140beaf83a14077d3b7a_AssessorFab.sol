// SPDX-License-Identifier: AGPL-3.0-only
// Copyright (C) Centrifuge 2020, based on MakerDAO dss https://github.com/makerdao/dss
pragma solidity >=0.5.15;

contract Auth {
    mapping (address => uint256) public wards;
    
    event Rely(address indexed usr);
    event Deny(address indexed usr);

    function rely(address usr) external auth {
        wards[usr] = 1;
        emit Rely(usr);
    }
    function deny(address usr) external auth {
        wards[usr] = 0;
        emit Deny(usr);
    }

    modifier auth {
        require(wards[msg.sender] == 1, "not-authorized");
        _;
    }

}

// SPDX-License-Identifier: AGPL-3.0-only
// Copyright (C) 2018 Rain <[email protected]> and Centrifuge, referencing MakerDAO dss => https://github.com/makerdao/dss/blob/master/src/pot.sol
pragma solidity >=0.5.15;

import "./math.sol";

contract Interest is Math {
    // @notice This function provides compounding in seconds
    // @param chi Accumulated interest rate over time
    // @param ratePerSecond Interest rate accumulation per second in RAD(10ˆ27)
    // @param lastUpdated When the interest rate was last updated
    // @param pie Total sum of all amounts accumulating under one interest rate, divided by that rate
    // @return The new accumulated rate, as well as the difference between the debt calculated with the old and new accumulated rates.
    function compounding(uint chi, uint ratePerSecond, uint lastUpdated, uint pie) public view returns (uint, uint) {
        require(block.timestamp >= lastUpdated, "tinlake-math/invalid-timestamp");
        require(chi != 0);
        // instead of a interestBearingAmount we use a accumulated interest rate index (chi)
        uint updatedChi = _chargeInterest(chi ,ratePerSecond, lastUpdated, block.timestamp);
        return (updatedChi, safeSub(rmul(updatedChi, pie), rmul(chi, pie)));
    }

    // @notice This function charge interest on a interestBearingAmount
    // @param interestBearingAmount is the interest bearing amount
    // @param ratePerSecond Interest rate accumulation per second in RAD(10ˆ27)
    // @param lastUpdated last time the interest has been charged
    // @return interestBearingAmount + interest
    function chargeInterest(uint interestBearingAmount, uint ratePerSecond, uint lastUpdated) public view returns (uint) {
        if (block.timestamp >= lastUpdated) {
            interestBearingAmount = _chargeInterest(interestBearingAmount, ratePerSecond, lastUpdated, block.timestamp);
        }
        return interestBearingAmount;
    }

    function _chargeInterest(uint interestBearingAmount, uint ratePerSecond, uint lastUpdated, uint current) internal pure returns (uint) {
        return rmul(rpow(ratePerSecond, current - lastUpdated, ONE), interestBearingAmount);
    }


    // convert pie to debt/savings amount
    function toAmount(uint chi, uint pie) public pure returns (uint) {
        return rmul(pie, chi);
    }

    // convert debt/savings amount to pie
    function toPie(uint chi, uint amount) public pure returns (uint) {
        return rdivup(amount, chi);
    }

    function rpow(uint x, uint n, uint base) public pure returns (uint z) {
        assembly {
            switch x case 0 {switch n case 0 {z := base} default {z := 0}}
            default {
                switch mod(n, 2) case 0 { z := base } default { z := x }
                let half := div(base, 2)  // for rounding.
                for { n := div(n, 2) } n { n := div(n,2) } {
                let xx := mul(x, x)
                if iszero(eq(div(xx, x), x)) { revert(0,0) }
                let xxRound := add(xx, half)
                if lt(xxRound, xx) { revert(0,0) }
                x := div(xxRound, base)
                if mod(n,2) {
                    let zx := mul(z, x)
                    if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) { revert(0,0) }
                    let zxRound := add(zx, half)
                    if lt(zxRound, zx) { revert(0,0) }
                    z := div(zxRound, base)
                }
            }
            }
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
// Copyright (C) 2018 Rain <[email protected]>
pragma solidity >=0.5.15;

contract Math {
    uint256 constant ONE = 10 ** 27;

    function safeAdd(uint x, uint y) public pure returns (uint z) {
        require((z = x + y) >= x, "safe-add-failed");
    }

    function safeSub(uint x, uint y) public pure returns (uint z) {
        require((z = x - y) <= x, "safe-sub-failed");
    }

    function safeMul(uint x, uint y) public pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "safe-mul-failed");
    }

    function safeDiv(uint x, uint y) public pure returns (uint z) {
        z = x / y;
    }

    function rmul(uint x, uint y) public pure returns (uint z) {
        z = safeMul(x, y) / ONE;
    }

    function rdiv(uint x, uint y) public pure returns (uint z) {
        require(y > 0, "division by zero");
        z = safeAdd(safeMul(x, ONE), y / 2) / y;
    }

    function rdivup(uint x, uint y) internal pure returns (uint z) {
        require(y > 0, "division by zero");
        // always rounds up
        z = safeAdd(safeMul(x, ONE), safeSub(y, 1)) / y;
    }


}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.6;

/// @notice abstract contract for FixedPoint math operations
/// defining ONE with 10^27 precision
abstract contract FixedPoint {
    struct Fixed27 {
        uint256 value;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.6;

import "tinlake-auth/auth.sol";
import "tinlake-math/interest.sol";
import "./definitions.sol";

interface NAVFeedLike {
    function calcUpdateNAV() external returns (uint256);
    function latestNAV() external view returns (uint256);
    function currentNAV() external view returns (uint256);
    function lastNAVUpdate() external view returns (uint256);
}

interface TrancheLike {
    function tokenSupply() external view returns (uint256);
}

interface ReserveLike {
    function totalBalance() external view returns (uint256);
    function file(bytes32 what, uint256 currencyAmount) external;
    function currencyAvailable() external view returns (uint256);
}

interface LendingAdapter {
    function remainingCredit() external view returns (uint256);
    function juniorStake() external view returns (uint256);
    function calcOvercollAmount(uint256 amount) external view returns (uint256);
    function stabilityFee() external view returns (uint256);
    function debt() external view returns (uint256);
}

/// @notice Assessor contract manages two tranches of a pool and calculates the token prices.
contract Assessor is Definitions, Auth, Interest {
    // senior ratio from the last epoch executed
    Fixed27 public seniorRatio;

    // the seniorAsset value is stored in two variables
    // seniorDebt is the interest bearing amount for senior
    uint256 public seniorDebt_;
    // senior balance is the rest which is not used as interest
    // bearing amount
    uint256 public seniorBalance_;

    // interest rate per second for senior tranche
    Fixed27 public seniorInterestRate;

    // last time the senior interest has been updated
    uint256 public lastUpdateSeniorInterest;

    Fixed27 public maxSeniorRatio;
    Fixed27 public minSeniorRatio;

    uint256 public maxReserve;

    uint256 public creditBufferTime = 1 days;
    uint256 public maxStaleNAV = 1 days;

    TrancheLike public seniorTranche;
    TrancheLike public juniorTranche;
    NAVFeedLike public navFeed;
    ReserveLike public reserve;
    LendingAdapter public lending;

    uint256 public constant supplyTolerance = 5;

    event Depend(bytes32 indexed contractName, address addr);
    event File(bytes32 indexed name, uint256 value);

    constructor() {
        seniorInterestRate.value = ONE;
        lastUpdateSeniorInterest = block.timestamp;
        seniorRatio.value = 0;
        wards[msg.sender] = 1;
        emit Rely(msg.sender);
    }

    /// @notice manages dependencies to other pool contracts
    /// @param contractName name of the contract
    /// @param addr address of the contract
    function depend(bytes32 contractName, address addr) public auth {
        if (contractName == "navFeed") {
            navFeed = NAVFeedLike(addr);
        } else if (contractName == "seniorTranche") {
            seniorTranche = TrancheLike(addr);
        } else if (contractName == "juniorTranche") {
            juniorTranche = TrancheLike(addr);
        } else if (contractName == "reserve") {
            reserve = ReserveLike(addr);
        } else if (contractName == "lending") {
            lending = LendingAdapter(addr);
        } else {
            revert();
        }
        emit Depend(contractName, addr);
    }

    /// @notice allows wards to set parameters of the contract
    /// @param name name of the parameter
    /// @param value value of the parameter
    function file(bytes32 name, uint256 value) public auth {
        if (name == "seniorInterestRate") {
            dripSeniorDebt();
            seniorInterestRate = Fixed27(value);
        } else if (name == "maxReserve") {
            maxReserve = value;
        } else if (name == "maxSeniorRatio") {
            require(value > minSeniorRatio.value, "value-too-small");
            maxSeniorRatio = Fixed27(value);
        } else if (name == "minSeniorRatio") {
            require(value < maxSeniorRatio.value, "value-too-big");
            minSeniorRatio = Fixed27(value);
        } else if (name == "creditBufferTime") {
            creditBufferTime = value;
        } else if (name == "maxStaleNAV") {
            maxStaleNAV = value;
        } else {
            revert("unknown-variable");
        }
        emit File(name, value);
    }

    /// @notice rebalance the debt and balance of the senior tranche according to
    /// the current ratio between senior and junior
    function reBalance() public {
        reBalance(calcExpectedSeniorAsset(seniorBalance_, dripSeniorDebt()));
    }

    /// @notice internal function for the rebalance of senior debt and balance
    /// @param seniorAsset_ the expected senior asset value (senior debt + senior balance)
    function reBalance(uint256 seniorAsset_) internal {
        // re-balancing according to new ratio
        // we use the approximated NAV here because because during the submission period
        // new loans might have been repaid in the meanwhile
        // which are not considered in the epochNAV
        uint256 nav_ = getNAV();
        uint256 reserve_ = reserve.totalBalance();

        uint256 seniorRatio_ = calcSeniorRatio(seniorAsset_, nav_, reserve_);

        // in that case the entire juniorAsset is lost
        // the senior would own everything that' left
        if (seniorRatio_ > ONE) {
            seniorRatio_ = ONE;
        }

        seniorDebt_ = rmul(nav_, seniorRatio_);
        if (seniorDebt_ > seniorAsset_) {
            seniorDebt_ = seniorAsset_;
            seniorBalance_ = 0;
        } else {
            seniorBalance_ = safeSub(seniorAsset_, seniorDebt_);
        }
        seniorRatio = Fixed27(seniorRatio_);
    }

    /// @notice changes the senior asset value based on new supply or redeems
    /// @param seniorSupply senior supply amount
    /// @param seniorRedeem senior redeem amount
    function changeSeniorAsset(uint256 seniorSupply, uint256 seniorRedeem) external auth {
        reBalance(calcExpectedSeniorAsset(seniorRedeem, seniorSupply, seniorBalance_, dripSeniorDebt()));
    }

    /// @notice returns the minimum and maximum senior ratio
    /// @return minSeniorRatio_ minimum senior ratio (in RAY 10^27)
    /// @return maxSeniorRatio_ maximum senior ratio (in RAY 10^27)
    function seniorRatioBounds() public view returns (uint256 minSeniorRatio_, uint256 maxSeniorRatio_) {
        return (minSeniorRatio.value, maxSeniorRatio.value);
    }

    /// @notice calls the NAV feed to update and store the current NAV
    /// @return nav_ the current NAV
    function calcUpdateNAV() external returns (uint256 nav_) {
        return navFeed.calcUpdateNAV();
    }

    /// @notice calculates the senior token price
    /// @return seniorTokenPrice_ the senior token price
    function calcSeniorTokenPrice() external view returns (uint256 seniorTokenPrice_) {
        return calcSeniorTokenPrice(getNAV(), reserve.totalBalance());
    }

    /// @notice calculates the senior token price for a given NAV
    /// interface doesn't use the provided total balance
    /// @param nav_ the NAV
    /// @return seniorTokenPrice_ the senior token price
    function calcSeniorTokenPrice(uint256 nav_, uint256) public view returns (uint256 seniorTokenPrice_) {
        return _calcSeniorTokenPrice(nav_, reserve.totalBalance());
    }

    /// @notice calculates the junior token price
    /// @return juniorTokenPrice_ the junior token price
    function calcJuniorTokenPrice() external view returns (uint256 juniorTokenPrice_) {
        return _calcJuniorTokenPrice(getNAV(), reserve.totalBalance());
    }

    /// @notice calculates the junior token price for a given NAV
    /// interface doesn't use the provided total balance
    /// @param nav_ the NAV
    /// @return juniorTokenPrice_ the junior token price
    function calcJuniorTokenPrice(uint256 nav_, uint256) public view returns (uint256 juniorTokenPrice_) {
        return _calcJuniorTokenPrice(nav_, reserve.totalBalance());
    }

    /// @notice calculates the senior and junior token price based on current NAV and reserve
    /// @return juniorTokenPrice_ the junior token price
    /// @return seniorTokenPrice_ the senior token price
    function calcTokenPrices() external view returns (uint256 juniorTokenPrice_, uint256 seniorTokenPrice_) {
        uint256 epochNAV = getNAV();
        uint256 epochReserve = reserve.totalBalance();
        return calcTokenPrices(epochNAV, epochReserve);
    }

    /// @notice calculates the senior and junior token price based on NAV and reserve as params
    /// @param epochNAV the NAV of an epoch
    /// @param epochReserve the reserve of an epoch
    /// @return juniorTokenPrice_ the junior token price
    /// @return seniorTokenPrice_ the senior token price
    function calcTokenPrices(uint256 epochNAV, uint256 epochReserve)
        public
        view
        returns (uint256 juniorTokenPrice_, uint256 seniorTokenPrice_)
    {
        return (_calcJuniorTokenPrice(epochNAV, epochReserve), _calcSeniorTokenPrice(epochNAV, epochReserve));
    }

    /// @notice internal function to calculate the senior token price
    /// @param nav_ the NAV
    /// @param reserve_ the reserve
    /// @return seniorTokenPrice_ the senior token price
    function _calcSeniorTokenPrice(uint256 nav_, uint256 reserve_) internal view returns (uint256 seniorTokenPrice_) {
        // the coordinator interface will pass the reserveAvailable

        if ((nav_ == 0 && reserve_ == 0) || seniorTranche.tokenSupply() <= supplyTolerance) {
            // we are using a tolerance of 2 here, as there can be minimal supply leftovers after all redemptions due to rounding
            // initial token price at start 1.00
            return ONE;
        }

        uint256 totalAssets = safeAdd(nav_, reserve_);
        uint256 seniorAssetValue = calcExpectedSeniorAsset(seniorDebt(), seniorBalance_);

        if (totalAssets < seniorAssetValue) {
            seniorAssetValue = totalAssets;
        }
        return rdiv(seniorAssetValue, seniorTranche.tokenSupply());
    }

    /// @notice internal function to calculate the junior token price
    /// @param nav_ the NAV
    /// @param reserve_ the reserve
    /// @return juniorTokenPrice_ the junior token price
    function _calcJuniorTokenPrice(uint256 nav_, uint256 reserve_) internal view returns (uint256 juniorTokenPrice_) {
        if ((nav_ == 0 && reserve_ == 0) || juniorTranche.tokenSupply() <= supplyTolerance) {
            // we are using a tolerance of 2 here, as there can be minimal supply leftovers after all redemptions due to rounding
            // initial token price at start 1.00
            return ONE;
        }
        // reserve includes creditline from maker
        uint256 totalAssets = safeAdd(nav_, reserve_);

        // includes creditline from mkr
        uint256 seniorAssetValue = calcExpectedSeniorAsset(seniorDebt(), seniorBalance_);

        if (totalAssets < seniorAssetValue) {
            return 0;
        }

        // the junior tranche only needs to pay for the mkr over-collateralization if
        // the mkr vault is liquidated, if that is true juniorStake=0
        uint256 juniorStake = 0;
        if (address(lending) != address(0)) {
            juniorStake = lending.juniorStake();
        }

        return rdiv(safeAdd(safeSub(totalAssets, seniorAssetValue), juniorStake), juniorTranche.tokenSupply());
    }

    /// @notice accumulates the senior interest
    /// @return _seniorDebt the senior debt
    function dripSeniorDebt() public returns (uint256 _seniorDebt) {
        seniorDebt_ = seniorDebt();
        lastUpdateSeniorInterest = block.timestamp;
        return seniorDebt_;
    }

    /// @notice returns the senior debt with up to date interest
    /// @return _seniorDebt senior debt
    function seniorDebt() public view returns (uint256 _seniorDebt) {
        if (block.timestamp >= lastUpdateSeniorInterest) {
            return chargeInterest(seniorDebt_, seniorInterestRate.value, lastUpdateSeniorInterest);
        }
        return seniorDebt_;
    }

    /// @notice returns the senior balance including unused creditline from adapters
    /// @return _seniorBalance senior balance
    function seniorBalance() public view returns (uint256 _seniorBalance) {
        return safeAdd(seniorBalance_, remainingOvercollCredit());
    }

    /// @notice returns the effective senior balance without unused creditline from adapters
    /// @return _seniorBalance senior balance
    function effectiveSeniorBalance() public view returns (uint256 _seniorBalance) {
        return seniorBalance_;
    }

    /// @notice returns the effective total balance
    /// @return _effectiveTotalBalance total balance
    function effectiveTotalBalance() public view returns (uint256 _effectiveTotalBalance) {
        return reserve.totalBalance();
    }

    /// @notice returns the total balance including unused creditline from adapters
    /// which means the total balance if the creditline were fully used
    /// @return _totalBalance total balance
    function totalBalance() public view returns (uint256 _totalBalance) {
        return safeAdd(reserve.totalBalance(), remainingCredit());
    }

    /// @notice returns the latest stored NAV or forces an update if a stale period has passed
    /// @return _nav the NAV
    function getNAV() public view returns (uint256 _nav) {
        if (block.timestamp >= navFeed.lastNAVUpdate() + maxStaleNAV) {
            return navFeed.currentNAV();
        }

        return navFeed.latestNAV();
    }

    /// @notice ward call to communicate the amount of currency available for new loan originations
    /// in the next epoch
    /// @param currencyAmount the amount of currency available for new loan originations in the next epoch
    function changeBorrowAmountEpoch(uint256 currencyAmount) public auth {
        reserve.file("currencyAvailable", currencyAmount);
    }

    /// @notice returns the amount left for new loan originations in the current epoch
    function borrowAmountEpoch() public view returns (uint256 currencyAvailable_) {
        return reserve.currencyAvailable();
    }

    /// @notice returns the current junior ratio protection in the Tinlake
    /// @return juniorRatio_ is denominated in RAY (10^27)
    function calcJuniorRatio() public view returns (uint256 juniorRatio_) {
        uint256 seniorAsset = safeAdd(seniorDebt(), seniorBalance_);
        uint256 assets = safeAdd(getNAV(), reserve.totalBalance());

        if (seniorAsset == 0 && assets == 0) {
            return 0;
        }

        if (seniorAsset == 0 && assets > 0) {
            return ONE;
        }

        if (seniorAsset > assets) {
            return 0;
        }

        return safeSub(ONE, rdiv(seniorAsset, assets));
    }

    /// @notice returns the remainingCredit plus a buffer for the interest increase
    /// @return _remainingCredit remaining credit
    function remainingCredit() public view returns (uint256 _remainingCredit) {
        if (address(lending) == address(0)) {
            return 0;
        }

        // over the time the remainingCredit will decrease because of the accumulated debt interest
        // therefore a buffer is reduced from the  remainingCredit to prevent the usage of currency which is not available
        uint256 debt = lending.debt();
        uint256 stabilityBuffer = safeSub(rmul(rpow(lending.stabilityFee(), creditBufferTime, ONE), debt), debt);
        uint256 remainingCredit_ = lending.remainingCredit();
        if (remainingCredit_ > stabilityBuffer) {
            return safeSub(remainingCredit_, stabilityBuffer);
        }

        return 0;
    }

    /// @notice returns the remainingCredit considering a potential required overcollataralization
    /// @return remainingOvercollCredit_ remaining credit
    function remainingOvercollCredit() public view returns (uint256 remainingOvercollCredit_) {
        if (address(lending) == address(0)) {
            return 0;
        }

        return lending.calcOvercollAmount(remainingCredit());
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.6;

import "tinlake-math/math.sol";
import "./../fixed_point.sol";

/// @notice contract without a state which defines the relevant formulas for the assessor
abstract contract Definitions is FixedPoint, Math {
    /// @notice calculates the expected Senior asset value
    /// @param _seniorDebt the current senior debt
    /// @param _seniorBalance the current senior balance
    /// @return _seniorAsset returns the senior asset value
    function calcExpectedSeniorAsset(uint256 _seniorDebt, uint256 _seniorBalance)
        public
        pure
        returns (uint256 _seniorAsset)
    {
        return safeAdd(_seniorDebt, _seniorBalance);
    }

    /// @notice calculates the senior ratio
    /// @param seniorAsset the current senior asset value
    /// @param nav the current NAV
    /// @param reserve the current reserve
    /// @return seniorRatio the senior ratio
    function calcSeniorRatio(uint256 seniorAsset, uint256 nav, uint256 reserve)
        public
        pure
        returns (uint256 seniorRatio)
    {
        // note: NAV + reserve == seniorAsset + juniorAsset (invariant: always true)
        // if expectedSeniorAsset is passed ratio can be greater than ONE
        uint256 assets = calcAssets(nav, reserve);
        if (assets == 0) {
            return 0;
        }

        return rdiv(seniorAsset, assets);
    }

    /// @notice calculates supply and redeem impact on the senior ratio
    /// @param seniorRedeem the senior redeem amount
    /// @param seniorSupply the senior supply amount
    /// @param currSeniorAsset the current senior asset value
    /// @param newReserve the new reserve (including the supply and redeem amounts)
    /// @param nav the current NAV
    function calcSeniorRatio(
        uint256 seniorRedeem,
        uint256 seniorSupply,
        uint256 currSeniorAsset,
        uint256 newReserve,
        uint256 nav
    ) public pure returns (uint256 seniorRatio) {
        return calcSeniorRatio(
            calcSeniorAssetValue(seniorRedeem, seniorSupply, currSeniorAsset, newReserve, nav), nav, newReserve
        );
    }

    /// @notice calculates the net wealth in the system
    /// @param nav_ the current NAV
    /// @param reserve_ the current reserve
    /// @return assets_ the total asset value (NAV + reserve)
    function calcAssets(uint256 nav_, uint256 reserve_) public pure returns (uint256 assets_) {
        return safeAdd(nav_, reserve_);
    }

    /// @notice calculates a new senior asset value based on senior redeem and senior supply
    /// @param seniorRedeem the senior redeem amount
    /// @param seniorSupply the senior supply amount
    /// @param currSeniorAsset the current senior asset value
    /// @param reserve_ the current reserve
    /// @param nav_ the current NAV
    /// @return seniorAsset the new senior asset value
    function calcSeniorAssetValue(
        uint256 seniorRedeem,
        uint256 seniorSupply,
        uint256 currSeniorAsset,
        uint256 reserve_,
        uint256 nav_
    ) public pure returns (uint256 seniorAsset) {
        seniorAsset = safeSub(safeAdd(currSeniorAsset, seniorSupply), seniorRedeem);
        uint256 assets = calcAssets(nav_, reserve_);
        if (seniorAsset > assets) {
            seniorAsset = assets;
        }

        return seniorAsset;
    }

    /// @notice expected senior return if no losses occur
    /// @param seniorRedeem the senior redeem amount
    /// @param seniorSupply the senior supply amount
    /// @param seniorBalance_ the current senior balance
    /// @param seniorDebt_ the current senior debt
    /// @return expectedSeniorAsset_ the expected senior asset value
    function calcExpectedSeniorAsset(
        uint256 seniorRedeem,
        uint256 seniorSupply,
        uint256 seniorBalance_,
        uint256 seniorDebt_
    ) public pure returns (uint256 expectedSeniorAsset_) {
        return safeSub(safeAdd(safeAdd(seniorDebt_, seniorBalance_), seniorSupply), seniorRedeem);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.6;

import {Assessor} from "./../assessor.sol";

interface AssessorFabLike {
    function newAssessor() external returns (address);
}

contract AssessorFab {
    function newAssessor() public returns (address) {
        Assessor assessor = new Assessor();
        assessor.rely(msg.sender);
        assessor.deny(address(this));
        return address(assessor);
    }
}