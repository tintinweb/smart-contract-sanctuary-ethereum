/**
 *Submitted for verification at Etherscan.io on 2023-02-15
*/

// SPDX-FileCopyrightText: © 2021 Dai Foundation <www.daifoundation.org>
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity ^0.8.14;


/**
    @title D3M Plan Interface
    @notice Plan contracts are contracts that the Hub uses to determine how
    much to change its position.
*/
interface ID3MPlan {
    event Disable();

    /**
        @notice Determines what the position should be based on current assets
        and the custom plan rules.
        @param currentAssets asset balance from a specific pool in Dai [wad]
        denomination
        @return uint256 target assets the Hub should wind or unwind to in Dai
    */
    function getTargetAssets(uint256 currentAssets) external view returns (uint256);

    /// @notice Reports whether the plan is active
    function active() external view returns (bool);

    /**
        @notice Disables the plan so that it would instruct the Hub to unwind
        its entire position.
        @dev Implementation should be permissioned.
    */
    function disable() external;
}

interface TokenLike {
    function totalSupply() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
}

interface ATokenLike {
    function ATOKEN_REVISION() external view returns (uint256);
}

interface LendingPoolLike {
    function getReserveData(address asset) external view returns (
        uint256, // configuration
        uint128, // the liquidity index. Expressed in ray
        uint128, // variable borrow index. Expressed in ray
        uint128, // the current supply rate. Expressed in ray
        uint128, // the current variable borrow rate. Expressed in ray
        uint128, // the current stable borrow rate. Expressed in ray
        uint40,  // last updated timestamp
        address, // address of the adai interest bearing token
        address, // address of the stable debt token
        address, // address of the variable debt token
        address, // address of the interest rate strategy
        uint8    // the id of the reserve
    );
}

interface InterestRateStrategyLike {
    function OPTIMAL_UTILIZATION_RATE() external view returns (uint256);
    function EXCESS_UTILIZATION_RATE() external view returns (uint256);
    function variableRateSlope1() external view returns (uint256);
    function variableRateSlope2() external view returns (uint256);
    function baseVariableBorrowRate() external view returns (uint256);
    function getMaxVariableBorrowRate() external view returns (uint256);
}

contract D3MAavePlan is ID3MPlan {

    mapping (address => uint256) public wards;
    InterestRateStrategyLike     public tack;
    uint256                      public bar; // Target Interest Rate [ray]

    LendingPoolLike public immutable pool;
    TokenLike       public immutable stableDebt;
    TokenLike       public immutable variableDebt;
    TokenLike       public immutable dai;
    address         public immutable adai;
    uint256         public immutable adaiRevision;

    // --- Events ---
    event Rely(address indexed usr);
    event Deny(address indexed usr);
    event File(bytes32 indexed what, uint256 data);
    event File(bytes32 indexed what, address data);

    constructor(address dai_, address pool_) {
        dai = TokenLike(dai_);
        pool = LendingPoolLike(pool_);

        // Fetch the reserve data from Aave
        (,,,,,,, address adai_, address stableDebt_, address variableDebt_, address interestStrategy_,) = pool.getReserveData(dai_);
        require(adai_             != address(0), "D3MAavePlan/invalid-adai");
        require(stableDebt_       != address(0), "D3MAavePlan/invalid-stableDebt");
        require(variableDebt_     != address(0), "D3MAavePlan/invalid-variableDebt");
        require(interestStrategy_ != address(0), "D3MAavePlan/invalid-interestStrategy");

        adai         = adai_;
        adaiRevision = ATokenLike(adai_).ATOKEN_REVISION();
        stableDebt   = TokenLike(stableDebt_);
        variableDebt = TokenLike(variableDebt_);
        tack         = InterestRateStrategyLike(interestStrategy_);

        wards[msg.sender] = 1;
        emit Rely(msg.sender);
    }

    modifier auth {
        require(wards[msg.sender] == 1, "D3MAavePlan/not-authorized");
        _;
    }

    // --- Math ---
    uint256 constant RAY = 10 ** 27;
    function _rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = (x * y) / RAY;
    }
    function _rdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = (x * RAY) / y;
    }

    // --- Admin ---
    function rely(address usr) external auth {
        wards[usr] = 1;
        emit Rely(usr);
    }
    function deny(address usr) external auth {
        wards[usr] = 0;
        emit Deny(usr);
    }

    function file(bytes32 what, uint256 data) external auth {
        if (what == "bar") bar = data;
        else revert("D3MAavePlan/file-unrecognized-param");
        emit File(what, data);
    }
    function file(bytes32 what, address data) external auth {
        if (what == "tack") tack = InterestRateStrategyLike(data);
        else revert("D3MAavePlan/file-unrecognized-param");
        emit File(what, data);
    }

    // --- Automated Rate targeting ---
    function _calculateTargetSupply(uint256 targetInterestRate, uint256 totalDebt) internal view returns (uint256) {
        uint256 base = tack.baseVariableBorrowRate();
        if (targetInterestRate <= base || targetInterestRate > tack.getMaxVariableBorrowRate()) {
            return 0;
        }

        // Do inverse calculation of interestStrategy
        uint256 variableRateSlope1 = tack.variableRateSlope1();

        uint256 targetUtil;
        if (targetInterestRate > base + variableRateSlope1) {
            // Excess interest rate
            uint256 r;
            unchecked {
                r = targetInterestRate - base - variableRateSlope1;
            }
            targetUtil = _rdiv(
                            _rmul(
                                tack.EXCESS_UTILIZATION_RATE(),
                                r
                            ),
                            tack.variableRateSlope2()
                         ) + tack.OPTIMAL_UTILIZATION_RATE();
        } else {
            // Optimal interest rate
            unchecked {
                targetUtil = _rdiv(
                                _rmul(
                                    targetInterestRate - base,
                                    tack.OPTIMAL_UTILIZATION_RATE()
                                ),
                                variableRateSlope1
                             );
            }
        }

        return _rdiv(totalDebt, targetUtil);
    }

    // Note: This view function has no reentrancy protection.
    //       On chain integrations should consider verifying `hub.locked()` is zero before relying on it.
    function getTargetAssets(uint256 currentAssets) external override view returns (uint256) {
        uint256 targetInterestRate = bar;
        if (targetInterestRate == 0) return 0; // De-activated

        uint256 totalDebt = stableDebt.totalSupply() + variableDebt.totalSupply();
        uint256 totalPoolSize = dai.balanceOf(adai) + totalDebt;
        uint256 targetTotalPoolSize = _calculateTargetSupply(targetInterestRate, totalDebt);

        if (targetTotalPoolSize >= totalPoolSize) {
            // Increase debt (or same)
            return currentAssets + (targetTotalPoolSize - totalPoolSize);
        } else {
            // Decrease debt
            unchecked {
                uint256 decrease = totalPoolSize - targetTotalPoolSize;
                if (currentAssets >= decrease) {
                    return currentAssets - decrease;
                } else {
                    return 0;
                }
            }
        }
    }

    function active() public view override returns (bool) {
        if (bar == 0) return false;
        (,,,,,,, address adai_, address stableDebt_, address variableDebt_, address strategy,) = pool.getReserveData(address(dai));
        uint256 adaiRevision_ = ATokenLike(adai_).ATOKEN_REVISION();
        return strategy      == address(tack)          &&
               adai_         == address(adai)          &&
               adaiRevision_ == adaiRevision           &&
               stableDebt_   == address(stableDebt)    &&
               variableDebt_ == address(variableDebt);
    }

    function disable() external override {
        require(wards[msg.sender] == 1 || !active(), "D3MAavePlan/not-authorized");
        bar = 0; // ensure deactivation even if active conditions return later
        emit Disable();
    }
}