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

import "./ID3MPool.sol";

interface TokenLike {
    function balanceOf(address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
}

interface VatLike {
    function live() external view returns (uint256);
    function hope(address) external;
    function nope(address) external;
}

interface D3mHubLike {
    function vat() external view returns (address);
    function end() external view returns (EndLike);
}

interface EndLike {
    function Art(bytes32) external view returns (uint256);
}

// aDai: https://etherscan.io/address/0x028171bCA77440897B824Ca71D1c56caC55b68A3
interface ATokenLike is TokenLike {
    function scaledBalanceOf(address) external view returns (uint256);
    function getIncentivesController() external view returns (address);
}

// Aave Lending Pool v2: https://etherscan.io/address/0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9
interface LendingPoolLike {
    function deposit(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;
    function withdraw(address asset, uint256 amount, address to) external;
    function getReserveNormalizedIncome(address asset) external view returns (uint256);
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

// Aave Incentives Controller: https://etherscan.io/address/0xd784927ff2f95ba542bfc824c8a8a98f3495f6b5
interface RewardsClaimerLike {
    function REWARD_TOKEN() external returns (address);
    function claimRewards(address[] calldata assets, uint256 amount, address to) external returns (uint256);
}

contract D3MAavePool is ID3MPool {

    mapping (address => uint256) public wards;
    address                      public hub;
    address                      public king; // Who gets the rewards
    uint256                      public exited;

    bytes32         public immutable ilk;
    VatLike         public immutable vat;
    LendingPoolLike public immutable pool;
    ATokenLike      public immutable stableDebt;
    ATokenLike      public immutable variableDebt;
    ATokenLike      public immutable adai;
    TokenLike       public immutable dai; // Asset

    // --- Events ---
    event Rely(address indexed usr);
    event Deny(address indexed usr);
    event File(bytes32 indexed what, address data);
    event Collect(address indexed king, address indexed gift, uint256 amt);

    constructor(bytes32 ilk_, address hub_, address dai_, address pool_) {
        ilk = ilk_;
        dai = TokenLike(dai_);
        pool = LendingPoolLike(pool_);

        // Fetch the reserve data from Aave
        (,,,,,,, address adai_, address stableDebt_, address variableDebt_,,) = pool.getReserveData(dai_);
        require(adai_         != address(0), "D3MAavePool/invalid-adai");
        require(stableDebt_   != address(0), "D3MAavePool/invalid-stableDebt");
        require(variableDebt_ != address(0), "D3MAavePool/invalid-variableDebt");

        adai = ATokenLike(adai_);
        stableDebt = ATokenLike(stableDebt_);
        variableDebt = ATokenLike(variableDebt_);

        dai.approve(pool_, type(uint256).max);

        hub = hub_;
        vat = VatLike(D3mHubLike(hub_).vat());
        vat.hope(hub_);

        wards[msg.sender] = 1;
        emit Rely(msg.sender);
    }

    modifier auth {
        require(wards[msg.sender] == 1, "D3MAavePool/not-authorized");
        _;
    }

    modifier onlyHub {
        require(msg.sender == hub, "D3MAavePool/only-hub");
        _;
    }

    // --- Math ---
    uint256 internal constant RAY = 10 ** 27;
    function _rdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = (x * RAY) / y;
    }
    function _min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x <= y ? x : y;
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

    function file(bytes32 what, address data) external auth {
        require(vat.live() == 1, "D3MAavePool/no-file-during-shutdown");
        if (what == "hub") {
            vat.nope(hub);
            hub = data;
            vat.hope(data);
        } else if (what == "king") king = data;
        else revert("D3MAavePool/file-unrecognized-param");
        emit File(what, data);
    }

    // Deposits Dai to Aave in exchange for adai which is received by this contract
    // Aave: https://docs.aave.com/developers/v/2.0/the-core-protocol/lendingpool#deposit
    function deposit(uint256 wad) external override onlyHub {
        uint256 scaledPrev = adai.scaledBalanceOf(address(this));

        pool.deposit(address(dai), wad, address(this), 0);

        // Verify the correct amount of adai shows up
        uint256 interestIndex = pool.getReserveNormalizedIncome(address(dai));
        uint256 scaledAmount = _rdiv(wad, interestIndex);
        require(adai.scaledBalanceOf(address(this)) >= (scaledPrev + scaledAmount), "D3MAavePool/incorrect-adai-balance-received");
    }

    // Withdraws Dai from Aave in exchange for adai
    // Aave: https://docs.aave.com/developers/v/2.0/the-core-protocol/lendingpool#withdraw
    function withdraw(uint256 wad) external override onlyHub {
        uint256 prevDai = dai.balanceOf(msg.sender);

        pool.withdraw(address(dai), wad, msg.sender);

        require(dai.balanceOf(msg.sender) == prevDai + wad, "D3MAavePool/incorrect-dai-balance-received");
    }

    function exit(address dst, uint256 wad) external override onlyHub {
        uint256 exited_ = exited;
        exited = exited_ + wad;
        uint256 amt = wad * assetBalance() / (D3mHubLike(hub).end().Art(ilk) - exited_);
        require(adai.transfer(dst, amt), "D3MAavePool/transfer-failed");
    }

    function quit(address dst) external override auth {
        require(vat.live() == 1, "D3MAavePool/no-quit-during-shutdown");
        require(adai.transfer(dst, adai.balanceOf(address(this))), "D3MAavePool/transfer-failed");
    }

    function preDebtChange() external override {}

    function postDebtChange() external override {}

    // --- Balance of the underlying asset (Dai)
    function assetBalance() public view override returns (uint256) {
        return adai.balanceOf(address(this));
    }

    function maxDeposit() external pure override returns (uint256) {
        return type(uint256).max;
    }

    function maxWithdraw() external view override returns (uint256) {
        return _min(dai.balanceOf(address(adai)), assetBalance());
    }

    function redeemable() external view override returns (address) {
        return address(adai);
    }

    // --- Collect any rewards ---
    function collect() external returns (uint256 amt) {
        require(king != address(0), "D3MAavePool/king-not-set");

        address[] memory assets = new address[](1);
        assets[0] = address(adai);

        RewardsClaimerLike rewardsClaimer = RewardsClaimerLike(adai.getIncentivesController());

        amt = rewardsClaimer.claimRewards(assets, type(uint256).max, king);
        address gift = rewardsClaimer.REWARD_TOKEN();
        emit Collect(king, gift, amt);
    }
}

// SPDX-FileCopyrightText: © 2022 Dai Foundation <www.daifoundation.org>
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

pragma solidity >=0.8.0;

/**
    @title D3M Pool Interface
    @notice Pool contracts are contracts that the Hub uses to standardize
    interactions with external Pools.
    @dev Implementing contracts will hold any balance provided by the external
    pool as well as the balance in the Vat. This interface aims to use EIP-4626
    guidelines for assets/shares/maxWithdraw etc.
*/
interface ID3MPool {
    /**
        @notice Deposit assets (Dai) in the external pool.
        @dev If the external pool requires a different amount to be passed in, the
        conversion should occur here as the Hub passes Dai [wad] amounts.
        msg.sender must be the hub.
        @param wad amount in asset (Dai) terms that we want to deposit
    */
    function deposit(uint256 wad) external;

    /**
        @notice Withdraw assets (Dai) from the external pool.
        @dev If the external pool requires a different amount to be passed in
        the conversion should occur here as the Hub passes Dai [wad] amounts.
        msg.sender must be the hub.
        @param wad amount in asset (Dai) terms that we want to withdraw
    */
    function withdraw(uint256 wad) external;

     /**
        @notice Exit proportional amount of shares.
        @dev If the external pool/token contract requires a different amount to be
        passed in the conversion should occur here as the Hub passes Gem [wad]
        amounts. msg.sender must be the hub.
        @param dst address that should receive the redeemable tokens
        @param wad amount in Gem terms that we want to withdraw
    */
    function exit(address dst, uint256 wad) external;

    /**
        @notice Transfer all shares from this pool.
        @dev msg.sender must be authorized.
        @param dst address that should receive the shares.
    */
    function quit(address dst) external;

    /**
        @notice Some external pools require actions before debt changes
    */
    function preDebtChange() external;

    /**
        @notice Some external pools require actions after debt changes
    */
    function postDebtChange() external;

    /**
        @notice Balance of assets this pool "owns".
        @dev This could be greater than the amount the pool can withdraw due to
        lack of liquidity.
        @return uint256 number of assets in Dai [wad]
    */
    function assetBalance() external view returns (uint256);

    /**
        @notice Maximum number of assets the pool could deposit at present.
        @return uint256 number of assets in Dai [wad]
    */
    function maxDeposit() external view returns (uint256);

    /**
        @notice Maximum number of assets the pool could withdraw at present.
        @return uint256 number of assets in Dai [wad]
    */
    function maxWithdraw() external view returns (uint256);

    /// @notice returns address of redeemable tokens (if any)
    function redeemable() external view returns (address);
}