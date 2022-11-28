/**
 *Submitted for verification at Etherscan.io on 2022-11-28
*/

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

pragma solidity ^0.8.14;

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

// cDai - https://etherscan.io/token/0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643
interface CErc20Like is TokenLike {
    function underlying() external view returns (address);
    function comptroller() external view returns (address);
    function exchangeRateStored() external view returns (uint256);
    function getCash() external view returns (uint256);
    function getAccountSnapshot(address account) external view returns (uint256, uint256, uint256, uint256);
    function mint(uint256 mintAmount) external returns (uint256);
    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);
    function accrueInterest() external returns (uint256);
    function exchangeRateCurrent() external returns (uint256);
}

// Comptroller - https://etherscan.io/address/0x3d9819210a31b4961b30ef54be2aed79b9c9cd3b
interface ComptrollerLike {
    function getCompAddress() external view returns (address);
    function claimComp(address[] memory holders, address[] memory cTokens, bool borrowers, bool suppliers) external;
}

contract D3MCompoundPool is ID3MPool {

    mapping (address => uint256) public wards;
    address                      public hub;
    address                      public king; // Who gets the rewards
    uint256                      public exited;

    bytes32         public immutable ilk;
    VatLike         public immutable vat;
    ComptrollerLike public immutable comptroller;
    TokenLike       public immutable comp;
    TokenLike       public immutable dai;
    CErc20Like      public immutable cDai;

    // --- Events ---
    event Rely(address indexed usr);
    event Deny(address indexed usr);
    event File(bytes32 indexed what, address data);
    event Collect(address indexed king, address indexed gift, uint256 amt);

    constructor(bytes32 ilk_, address hub_, address cDai_) {
        ilk         = ilk_;
        cDai        = CErc20Like(cDai_);
        dai         = TokenLike(cDai.underlying());
        comptroller = ComptrollerLike(cDai.comptroller());
        comp        = TokenLike(comptroller.getCompAddress());

        require(address(comp) != address(0), "D3MCompoundPool/invalid-comp");

        dai.approve(cDai_, type(uint256).max);

        hub = hub_;
        vat = VatLike(D3mHubLike(hub_).vat());
        vat.hope(hub_);

        wards[msg.sender] = 1;
        emit Rely(msg.sender);
    }

    modifier auth {
        require(wards[msg.sender] == 1, "D3MCompoundPool/not-authorized");
        _;
    }

    modifier onlyHub {
        require(msg.sender == hub, "D3MCompoundPool/only-hub");
        _;
    }

    // --- Math ---
    uint256 internal constant WAD = 10 ** 18;
    function _wmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = (x * y) / WAD;
    }
    function _wdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = (x * WAD) / y;
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
        require(vat.live() == 1, "D3MCompoundPool/no-file-during-shutdown");
        if (what == "hub") {
            vat.nope(hub);
            hub = data;
            vat.hope(data);
        } else if (what == "king") king = data;
        else revert("D3MCompoundPool/file-unrecognized-param");
        emit File(what, data);
    }

    function deposit(uint256 wad) external override onlyHub {
        uint256 prev = cDai.balanceOf(address(this));
        require(cDai.mint(wad) == 0, "D3MCompoundPool/mint-failure");

        // As interest was accrued on `mint` we can use the non accruing `exchangeRateStored`
        require(
            cDai.balanceOf(address(this)) ==
            prev + _wdiv(wad, cDai.exchangeRateStored()), "D3MCompoundPool/incorrect-cdai-credit"
        );
    }

    function withdraw(uint256 wad) external override onlyHub {
        uint256 prevDai = dai.balanceOf(msg.sender);

        require(cDai.redeemUnderlying(wad) == 0, "D3MCompoundPool/redeemUnderlying-failure");
        dai.transfer(msg.sender, wad);

        require(dai.balanceOf(msg.sender) == prevDai + wad, "D3MCompoundPool/incorrect-dai-balance-received");
    }

    function exit(address dst, uint256 wad) external override onlyHub {
        uint256 exited_ = exited;
        exited = exited_ + wad;
        uint256 amt = wad * cDai.balanceOf(address(this)) / (D3mHubLike(hub).end().Art(ilk) - exited_);
        require(cDai.transfer(dst, amt), "D3MCompoundPool/transfer-failed");
    }

    function quit(address dst) external override auth {
        require(vat.live() == 1, "D3MCompoundPool/no-quit-during-shutdown");
        require(cDai.transfer(dst, cDai.balanceOf(address(this))), "D3MCompoundPool/transfer-failed");
    }

    function preDebtChange() external override {
        require(cDai.accrueInterest() == 0, "D3MCompoundPool/accrueInterest-failure");
    }

    function postDebtChange() external override {}

    // Does not accrue interest (as opposed to cToken's balanceOfUnderlying() which is not a view function).
    function assetBalance() public view override returns (uint256) {
        (uint256 error, uint256 cTokenBalance,, uint256 exchangeRate) = cDai.getAccountSnapshot(address(this));
        require(error == 0, "D3MCompoundPool/getAccountSnapshot-failure");
        return _wmul(cTokenBalance, exchangeRate);
    }

    function maxDeposit() external pure override returns (uint256) {
        return type(uint256).max;
    }

    function maxWithdraw() external view override returns (uint256) {
        return _min(cDai.getCash(), assetBalance());
    }

    function redeemable() external view override returns (address) {
        return address(cDai);
    }

    function collect(bool claim) external {
        require(king != address(0), "D3MCompoundPool/king-not-set");

        if (claim) {
            address[] memory holders = new address[](1);
            holders[0] = address(this);
            address[] memory cTokens = new address[](1);
            cTokens[0] = address(cDai);
            comptroller.claimComp(holders, cTokens, false, true);
        }

        uint256 amt = comp.balanceOf(address(this));
        comp.transfer(king, amt);

        emit Collect(king, address(comp), amt);
    }
}