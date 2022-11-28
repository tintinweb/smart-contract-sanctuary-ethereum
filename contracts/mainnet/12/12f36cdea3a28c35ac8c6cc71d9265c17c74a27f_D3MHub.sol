/**
 *Submitted for verification at Etherscan.io on 2022-11-28
*/

// hevm: flattened sources of src/D3MHub.sol
// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.8.14 <0.9.0;

////// src/plans/ID3MPlan.sol
// SPDX-FileCopyrightText: © 2022 Dai Foundation <www.daifoundation.org>
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

/* pragma solidity ^0.8.14; */

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

////// src/pools/ID3MPool.sol
// SPDX-FileCopyrightText: © 2022 Dai Foundation <www.daifoundation.org>
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

/* pragma solidity ^0.8.14; */

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

////// src/D3MHub.sol
// SPDX-FileCopyrightText: © 2021 Dai Foundation <www.daifoundation.org>
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

/* pragma solidity ^0.8.14; */

/* import "./pools/ID3MPool.sol"; */
/* import "./plans/ID3MPlan.sol"; */

interface VatLike_1 {
    function debt() external view returns (uint256);
    function hope(address) external;
    function ilks(bytes32) external view returns (uint256, uint256, uint256, uint256, uint256);
    function Line() external view returns (uint256);
    function urns(bytes32, address) external view returns (uint256, uint256);
    function gem(bytes32, address) external view returns (uint256);
    function live() external view returns (uint256);
    function slip(bytes32, address, int256) external;
    function move(address, address, uint256) external;
    function frob(bytes32, address, address, address, int256, int256) external;
    function grab(bytes32, address, address, address, int256, int256) external;
    function suck(address, address, uint256) external;
}

interface EndLike_1 {
    function debt() external view returns (uint256);
    function skim(bytes32, address) external;
}

interface DaiJoinLike_1 {
    function vat() external view returns (address);
    function dai() external view returns (address);
    function join(address, uint256) external;
    function exit(address, uint256) external;
}

interface TokenLike_1 {
    function approve(address, uint256) external returns (bool);
}

/**
    @title D3M Hub
    @notice This is the main D3M contract and is responsible for winding and
    unwinding pools, interacting with DSS and tracking the plans and pools and
    their states.
*/
contract D3MHub {

    // --- Auth ---
    /**
        @notice Maps address that have permission in the Pool.
        @dev 1 = allowed, 0 = no permission
        @return authorization 1 or 0
    */
    mapping (address => uint256) public wards;

    address public vow;
    EndLike_1 public end;
    uint256 public locked;

    /// @notice maps ilk bytes32 to the D3M tracking struct.
    mapping (bytes32 => Ilk) public ilks;

    VatLike_1     public immutable vat;
    DaiJoinLike_1 public immutable daiJoin;

    /**
        @notice Tracking struct for each of the D3M ilks.
        @param pool   Contract to access external pool and hold balances
        @param plan   Contract used to calculate target debt
        @param tau    Time until you can write off the debt [sec]
        @param culled Debt write off triggered (1 or 0)
        @param tic    Timestamp when the pool is caged
    */
    struct Ilk {
        ID3MPool pool;   // Access external pool and holds balances
        ID3MPlan plan;   // How we calculate target debt
        uint256  tau;    // Time until you can write off the debt [sec]
        uint256  culled; // Debt write off triggered
        uint256  tic;    // Timestamp when the d3m can be culled (tau + timestamp when caged)
    }

    // --- Events ---
    event Rely(address indexed usr);
    event Deny(address indexed usr);
    event File(bytes32 indexed what, address data);
    event File(bytes32 indexed ilk, bytes32 indexed what, address data);
    event File(bytes32 indexed ilk, bytes32 indexed what, uint256 data);
    event Wind(bytes32 indexed ilk, uint256 amt);
    event Unwind(bytes32 indexed ilk, uint256 amt);
    event NoOp(bytes32 indexed ilk);
    event Fees(bytes32 indexed ilk, uint256 amt);
    event Exit(bytes32 indexed ilk, address indexed usr, uint256 amt);
    event Cage(bytes32 indexed ilk);
    event Cull(bytes32 indexed ilk, uint256 ink, uint256 art);
    event Uncull(bytes32 indexed ilk, uint256 wad);

    /**
        @dev sets msg.sender as authed.
        @param daiJoin_ address of the DSS Dai Join contract
    */
    constructor(address daiJoin_) {
        daiJoin = DaiJoinLike_1(daiJoin_);
        vat = VatLike_1(daiJoin.vat());
        TokenLike_1(daiJoin.dai()).approve(daiJoin_, type(uint256).max);
        vat.hope(daiJoin_);

        wards[msg.sender] = 1;
        emit Rely(msg.sender);
    }

    /// @notice Modifier will revoke if msg.sender is not authorized.
    modifier auth {
        require(wards[msg.sender] == 1, "D3MHub/not-authorized");
        _;
    }

    /// @notice Mutex to prevent reentrancy on external functions
    modifier lock {
        require(locked == 0, "D3MHub/system-locked");
        locked = 1;
        _;
        locked = 0;
    }

    // --- Math ---
    uint256 internal constant WAD = 10 ** 18;
    uint256 internal constant RAY = 10 ** 27;
    uint256 internal constant MAXINT256 = uint256(type(int256).max);
    uint256 internal constant SAFEMAX = MAXINT256 / RAY;

    function _min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x <= y ? x : y;
    }
    function _max(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x >= y ? x : y;
    }
    function _divup(uint256 x, uint256 y) internal pure returns (uint256 z) {
        unchecked {
            z = x != 0 ? ((x - 1) / y) + 1 : 0;
        }
    }

    // --- Administration ---
    /**
        @notice Makes an address authorized to perform auth'ed functions.
        @dev msg.sender must be authorized.
        @param usr address to be authorized
    */
    function rely(address usr) external auth {
        wards[usr] = 1;
        emit Rely(usr);
    }

    /**
        @notice De-authorizes an address from performing auth'ed functions.
        @dev msg.sender must be authorized.
        @param usr address to be de-authorized
    */
    function deny(address usr) external auth {
        wards[usr] = 0;
        emit Deny(usr);
    }

    /**
        @notice update vow or end addresses.
        @dev msg.sender must be authorized.
        @param what name of what we are updating bytes32("vow"|"end")
        @param data address we are setting it to
    */
    function file(bytes32 what, address data) external auth {
        require(vat.live() == 1, "D3MHub/no-file-during-shutdown");

        if (what == "vow") vow = data;
        else if (what == "end") end = EndLike_1(data);
        else revert("D3MHub/file-unrecognized-param");
        emit File(what, data);
    }

    /**
        @notice update tau value for D3M ilk.
        @dev msg.sender must be authorized.
        @param ilk  bytes32 of the D3M ilk to be updated
        @param what bytes32("tau") or it will revert
        @param data number of seconds to wait after caging a pool to write off debt
    */
    function file(bytes32 ilk, bytes32 what, uint256 data) external auth {
        if (what == "tau") ilks[ilk].tau = data;
        else revert("D3MHub/file-unrecognized-param");

        emit File(ilk, what, data);
    }

    /**
        @notice update plan or pool addresses for D3M ilk.
        @dev msg.sender must be authorized.
        @param ilk  bytes32 of the D3M ilk to be updated
        @param what bytes32("pool"|"plan") or it will revert
        @param data address we are setting it to
    */
    function file(bytes32 ilk, bytes32 what, address data) external auth {
        require(vat.live() == 1, "D3MHub/no-file-during-shutdown");
        require(ilks[ilk].tic == 0, "D3MHub/pool-not-live");

        if (what == "pool") ilks[ilk].pool = ID3MPool(data);
        else if (what == "plan") ilks[ilk].plan = ID3MPlan(data);
        else revert("D3MHub/file-unrecognized-param");
        emit File(ilk, what, data);
    }

    // --- Internal functions that are called from exec(bytes32 ilk) ---

    function _wipe(bytes32 ilk, ID3MPool _pool, address urn) internal {
        uint256 amount = _pool.maxWithdraw();
        if (amount > 0) {
            _pool.withdraw(amount);
            daiJoin.join(address(this), amount);
            vat.move(address(this), vow, amount * RAY);

            uint256 toSlip = _min(vat.gem(ilk, urn), amount);
            // amount bounds toSlip and amount * RAY bounds amount to be much less than MAXINT256
            vat.slip(ilk, urn, -int256(toSlip));
            emit Unwind(ilk, amount);
        } else {
            emit NoOp(ilk);
        }
    }

    function _exec(bytes32 ilk, ID3MPool _pool, uint256 Art, uint256 lineWad) internal {
        require(lineWad <= SAFEMAX, "D3MHub/lineWad-above-max-safe");
        (uint256 ink, uint256 art) = vat.urns(ilk, address(_pool));
        require(ink <= SAFEMAX, "D3MHub/ink-above-max-safe");
        require(ink >= art, "D3MHub/ink-not-greater-equal-art");
        require(art == Art, "D3MHub/more-than-one-urn");
        uint256 currentAssets = _pool.assetBalance(); // Should return DAI owned by D3MPool
        uint256 maxWithdraw = _min(_pool.maxWithdraw(), SAFEMAX);

        // Determine if fees were generated and try to account them (or the most that it is possible)
        if (currentAssets > ink) {
            uint256 fixInk = _min(
                _min(
                    currentAssets - ink, // fees generated
                    ink < lineWad // if previously CDP was under debt ceiling
                        ? (lineWad - ink) + maxWithdraw // up to gap to reach debt ceiling + maxWithdraw
                        : maxWithdraw // up to maxWithdraw
                ),
                SAFEMAX + art - ink //  ensures that fixArt * RAY (rate) will be <= MAXINT256 (in vat.grab)
            );
            vat.slip(ilk, address(_pool), int256(fixInk)); // Generate extra collateral
            vat.frob(ilk, address(_pool), address(_pool), address(this), int256(fixInk), 0); // Lock it
            unchecked {
                ink += fixInk; // can not overflow as worst case will be the value of currentAssets
            }
            emit Fees(ilk, fixInk);
        }
        // Get the DAI and send as surplus (if there was permissionless DAI paid or fees accounted)
        if (art < ink) {
            address _vow = vow;
            uint256 fixArt;
            unchecked {
                fixArt = ink - art; // Amount of fees + permissionless DAI paid we will now transform to debt
            }
            art = ink;
            vat.suck(_vow, _vow, fixArt * RAY); // This needs to be done to make sure we can deduct sin[vow] and vice in the next call
            // No need for `fixArt <= MAXINT256` require as:
            // MAXINT256 >>> MAXUINT256 / RAY which is already restricted above
            // Also fixArt should be always <= SAFEMAX (MAXINT256 / RAY)
            vat.grab(ilk, address(_pool), address(_pool), _vow, 0, int256(fixArt)); // Generating the debt
        }

        // Determine if it needs to unwind or wind
        uint256 toUnwind;
        uint256 toWind;

        // Determine if it needs to fully unwind due to D3M ilk being caged (but not culled), plan is not active or something
        // wrong is going with the third party and we are entering in the ilegal situation of having less assets than registered
        // It's adding up `WAD` due possible rounding errors
        if (ilks[ilk].tic != 0 || !ilks[ilk].plan.active() || currentAssets + WAD < ink) {
            toUnwind = maxWithdraw;
        } else {
            uint256 Line = vat.Line();
            uint256 debt = vat.debt();
            uint256 targetAssets = ilks[ilk].plan.getTargetAssets(currentAssets);

            // Determine if it needs to unwind due to:
            unchecked {
                toUnwind = _max(
                                _max(
                                    art > lineWad ? art - lineWad : 0, // ilk debt ceiling exceeded
                                    debt > Line ? _divup(debt - Line, RAY) : 0 // global debt ceiling exceeded
                                ),
                                targetAssets < currentAssets ? currentAssets - targetAssets : 0 // plan targetAssets
                            );
                if (toUnwind > 0) {
                    toUnwind = _min(toUnwind, maxWithdraw);
                } else {
                    // Determine up to which value to wind:
                    // subtractions are safe as otherwise toUnwind > 0 conditional would be true
                    toWind = _min(
                                _min(
                                    _min(
                                        lineWad - art, // amount to reach ilk debt ceiling
                                        (Line - debt) / RAY  // amount to reach global debt ceiling
                                    ),
                                    targetAssets - currentAssets // plan targetAssets
                                ),
                                _pool.maxDeposit() // restricts winding if the pool has a max deposit
                            );
                }
            }
        }

        if (toUnwind > 0) {
            _pool.withdraw(toUnwind);
            daiJoin.join(address(this), toUnwind);
            // SAFEMAX bounds toUnwind making sure is <<< than MAXINT256
            vat.frob(ilk, address(_pool), address(_pool), address(this), -int256(toUnwind), -int256(toUnwind));
            vat.slip(ilk, address(_pool), -int256(toUnwind));
            emit Unwind(ilk, toUnwind);
        } else if (toWind > 0) {
            require(art + toWind <= SAFEMAX, "D3MHub/wind-overflow");
            vat.slip(ilk, address(_pool), int256(toWind));
            vat.frob(ilk, address(_pool), address(_pool), address(this), int256(toWind), int256(toWind));
            daiJoin.exit(address(_pool), toWind);
            _pool.deposit(toWind);
            emit Wind(ilk, toWind);
        } else {
            emit NoOp(ilk);
        }
    }

    /**
        @notice Main function for updating a D3M position.
        Determines the current state and either winds or unwinds as necessary.
        @dev Winding the target position will be constrained by the Ilk debt
        ceiling, the overall DSS debt ceiling and the maximum deposit by the
        pool. Unwinding the target position will be constrained by the number
        of assets available to be withdrawn from the pool.
        @param ilk bytes32 of the D3M ilk name
    */
    function exec(bytes32 ilk) external lock {
        // IMPORTANT: this function assumes Vat rate of D3M ilks will always be == 1 * RAY (no fees).
        // That's why this module converts normalized debt (art) to Vat DAI generated with a simple RAY multiplication or division

        (uint256 Art, uint256 rate, uint256 spot, uint256 line,) = vat.ilks(ilk);
        require(rate == RAY, "D3MHub/rate-not-one");
        require(spot == RAY, "D3MHub/spot-not-one");

        ID3MPool _pool = ilks[ilk].pool;

        _pool.preDebtChange();

        if (vat.live() == 0) {
            // MCD caged
            // The main reason to have this case is trying to unwind the highest amount of DAI from the pool before end.debt is established.
            // That has the advantage to simplify End process, the best scenario would be unwinding everything which will decrease to the
            // minimum the amount of circulating supply of DAI, giving directly more value of other collaterals for each unit of DAI.
            // If this is not called, anyone can still call end.skim permissionlesly at any moment leaving remaining amount of pool shares
            // available to DAI holders to redeem it. This type of collateral is a cyclical one though, where user will need to go from
            // DAI -> pool share -> DAI -> ... making it not the most practical to handle. However, at the end, the net value of other
            // collaterals received per unit of DAI should end up being the same one (assuming there is liquidity in the pool to withdraw).
            EndLike_1 _end = end;
            require(_end.debt() == 0, "D3MHub/end-debt-already-set");
            require(ilks[ilk].culled == 0, "D3MHub/module-has-to-be-unculled-first");
            _end.skim(ilk, address(_pool));
            _wipe(
                ilk,
                _pool,
                address(_end)
            );
        } else if (ilks[ilk].culled == 1) {
            _wipe(
                ilk,
                _pool,
                address(_pool)
            );
        } else {
            _exec(
                ilk,
                _pool,
                Art,
                line / RAY // round down ilk line in wad format
            );
        }

        _pool.postDebtChange();
    }

    /**
        @notice Allow Users to return vat gem for Pool Shares.
        This will only occur during Global Settlement when users receive
        collateral for their Dai.
        @param ilk bytes32 of the D3M ilk name
        @param usr address that should receive the shares from the pool
        @param wad amount of gems that the msg.sender is returning
    */
    function exit(bytes32 ilk, address usr, uint256 wad) external lock {
        require(wad <= MAXINT256, "D3MHub/overflow");
        vat.slip(ilk, msg.sender, -int256(wad));
        ilks[ilk].pool.exit(usr, wad);
        emit Exit(ilk, usr, wad);
    }

    /**
        @notice Shutdown a pool.
        This starts the countdown to when the debt can be written off (cull).
        Once called, subsequent calls to `exec` will unwind as much of the
        position as possible.
        @dev msg.sender must be authorized.
        @param ilk bytes32 of the D3M ilk name
    */
    function cage(bytes32 ilk) external auth {
        require(vat.live() == 1, "D3MHub/no-cage-during-shutdown");
        require(ilks[ilk].tic == 0, "D3MHub/pool-already-caged");

        ilks[ilk].tic = block.timestamp + ilks[ilk].tau;
        emit Cage(ilk);
    }

    /**
        @notice Write off the debt for a caged pool.
        This must occur while vat is live. Can be triggered by auth or
        after tau number of seconds has passed since the pool was caged.
        @dev This will send the pool's debt to the vow as sin and convert its
        collateral to gems.
        @param ilk bytes32 of the D3M ilk name
    */
    function cull(bytes32 ilk) external {
        require(vat.live() == 1, "D3MHub/no-cull-during-shutdown");

        uint256 _tic = ilks[ilk].tic;
        require(_tic > 0, "D3MHub/pool-live");

        require(_tic <= block.timestamp || wards[msg.sender] == 1, "D3MHub/unauthorized-cull");
        require(ilks[ilk].culled == 0, "D3MHub/already-culled");

        ID3MPool _pool = ilks[ilk].pool;

        (uint256 ink, uint256 art) = vat.urns(ilk, address(_pool));
        require(ink <= MAXINT256, "D3MHub/overflow");
        require(art <= MAXINT256, "D3MHub/overflow");
        vat.grab(ilk, address(_pool), address(_pool), vow, -int256(ink), -int256(art));

        ilks[ilk].culled = 1;
        emit Cull(ilk, ink, art);
    }

    /**
        @notice Rollback Write-off (cull) if General Shutdown happened.
        This function is required to have the collateral back in the vault so it
        can be taken by End module and eventually be shared to DAI holders (as
        any other collateral) or maybe even unwinded.
        @dev This pulls gems from the pool and reopens the urn with the gem
        amount of ink/art.
        @param ilk bytes32 of the D3M ilk name
    */
    function uncull(bytes32 ilk) external {
        ID3MPool _pool = ilks[ilk].pool;

        require(ilks[ilk].culled == 1, "D3MHub/not-prev-culled");
        require(vat.live() == 0, "D3MHub/no-uncull-normal-operation");

        address _vow = vow;
        uint256 wad = vat.gem(ilk, address(_pool));
        vat.suck(_vow, _vow, wad * RAY); // This needs to be done to make sure we can deduct sin[vow] and vice in the next call
        // wad * RAY bounds wad to be much less than MAXINT256
        vat.grab(ilk, address(_pool), address(_pool), _vow, int256(wad), int256(wad));

        ilks[ilk].culled = 0;
        emit Uncull(ilk, wad);
    }

    // Ilk Getters
    /**
        @notice Return pool of an ilk
        @param ilk   bytes32 of the D3M ilk
        @return pool address of pool contract
    */
    function pool(bytes32 ilk) external view returns (address) {
        return address(ilks[ilk].pool);
    }

    /**
        @notice Return plan of an ilk
        @param ilk   bytes32 of the D3M ilk
        @return plan address of plan contract
    */
    function plan(bytes32 ilk) external view returns (address) {
        return address(ilks[ilk].plan);
    }

    /**
        @notice Return tau of an ilk
        @param ilk  bytes32 of the D3M ilk
        @return tau sec until debt can be written off
    */
    function tau(bytes32 ilk) external view returns (uint256) {
        return ilks[ilk].tau;
    }

    /**
        @notice Return culled status of an ilk
        @param ilk  bytes32 of the D3M ilk
        @return culled whether or not the d3m has been culled
    */
    function culled(bytes32 ilk) external view returns (uint256) {
        return ilks[ilk].culled;
    }

    /**
        @notice Return tic of an ilk
        @param ilk  bytes32 of the D3M ilk
        @return tic timestamp of when d3m is caged
    */
    function tic(bytes32 ilk) external view returns (uint256) {
        return ilks[ilk].tic;
    }
}