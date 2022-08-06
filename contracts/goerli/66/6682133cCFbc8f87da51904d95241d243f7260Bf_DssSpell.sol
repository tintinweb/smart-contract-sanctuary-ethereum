/**
 *Submitted for verification at Etherscan.io on 2022-08-05
*/

// hevm: flattened sources of src/Goerli-DssSpell.sol
// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity =0.6.12 >=0.6.12 <0.7.0;
// pragma experimental ABIEncoderV2;

////// lib/dss-exec-lib/src/CollateralOpts.sol
/* pragma solidity ^0.6.12; */

struct CollateralOpts {
    bytes32 ilk;
    address gem;
    address join;
    address clip;
    address calc;
    address pip;
    bool    isLiquidatable;
    bool    isOSM;
    bool    whitelistOSM;
    uint256 ilkDebtCeiling;
    uint256 minVaultAmount;
    uint256 maxLiquidationAmount;
    uint256 liquidationPenalty;
    uint256 ilkStabilityFee;
    uint256 startingPriceFactor;
    uint256 breakerTolerance;
    uint256 auctionDuration;
    uint256 permittedDrop;
    uint256 liquidationRatio;
    uint256 kprFlatReward;
    uint256 kprPctReward;
}

////// lib/dss-exec-lib/src/DssExecLib.sol
//
// DssExecLib.sol -- MakerDAO Executive Spellcrafting Library
//
// Copyright (C) 2020 Maker Ecosystem Growth Holdings, Inc.
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
/* pragma solidity ^0.6.12; */
/* // pragma experimental ABIEncoderV2; */

/* import { CollateralOpts } from "./CollateralOpts.sol"; */

interface Initializable {
    function init(bytes32) external;
}

interface Authorizable {
    function rely(address) external;
    function deny(address) external;
    function setAuthority(address) external;
}

interface Fileable {
    function file(bytes32, address) external;
    function file(bytes32, uint256) external;
    function file(bytes32, bytes32, uint256) external;
    function file(bytes32, bytes32, address) external;
}

interface Drippable {
    function drip() external returns (uint256);
    function drip(bytes32) external returns (uint256);
}

interface Pricing {
    function poke(bytes32) external;
}

interface ERC20 {
    function decimals() external returns (uint8);
}

interface DssVat {
    function hope(address) external;
    function nope(address) external;
    function ilks(bytes32) external returns (uint256 Art, uint256 rate, uint256 spot, uint256 line, uint256 dust);
    function Line() external view returns (uint256);
    function suck(address, address, uint) external;
}

interface ClipLike {
    function vat() external returns (address);
    function dog() external returns (address);
    function spotter() external view returns (address);
    function calc() external view returns (address);
    function ilk() external returns (bytes32);
}

interface DogLike {
    function ilks(bytes32) external returns (address clip, uint256 chop, uint256 hole, uint256 dirt);
}

interface JoinLike {
    function vat() external returns (address);
    function ilk() external returns (bytes32);
    function gem() external returns (address);
    function dec() external returns (uint256);
    function join(address, uint) external;
    function exit(address, uint) external;
}

// Includes Median and OSM functions
interface OracleLike_2 {
    function src() external view returns (address);
    function lift(address[] calldata) external;
    function drop(address[] calldata) external;
    function setBar(uint256) external;
    function kiss(address) external;
    function diss(address) external;
    function kiss(address[] calldata) external;
    function diss(address[] calldata) external;
    function orb0() external view returns (address);
    function orb1() external view returns (address);
}

interface MomLike {
    function setOsm(bytes32, address) external;
    function setPriceTolerance(address, uint256) external;
}

interface RegistryLike {
    function add(address) external;
    function xlip(bytes32) external view returns (address);
}

// https://github.com/makerdao/dss-chain-log
interface ChainlogLike {
    function setVersion(string calldata) external;
    function setIPFS(string calldata) external;
    function setSha256sum(string calldata) external;
    function getAddress(bytes32) external view returns (address);
    function setAddress(bytes32, address) external;
    function removeAddress(bytes32) external;
}

interface IAMLike {
    function ilks(bytes32) external view returns (uint256,uint256,uint48,uint48,uint48);
    function setIlk(bytes32,uint256,uint256,uint256) external;
    function remIlk(bytes32) external;
    function exec(bytes32) external returns (uint256);
}

interface LerpFactoryLike {
    function newLerp(bytes32 name_, address target_, bytes32 what_, uint256 startTime_, uint256 start_, uint256 end_, uint256 duration_) external returns (address);
    function newIlkLerp(bytes32 name_, address target_, bytes32 ilk_, bytes32 what_, uint256 startTime_, uint256 start_, uint256 end_, uint256 duration_) external returns (address);
}

interface LerpLike {
    function tick() external returns (uint256);
}


library DssExecLib {

    /* WARNING

The following library code acts as an interface to the actual DssExecLib
library, which can be found in its own deployed contract. Only trust the actual
library's implementation.

    */

    address constant public LOG = 0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F;
    uint256 constant internal WAD      = 10 ** 18;
    uint256 constant internal RAY      = 10 ** 27;
    uint256 constant internal RAD      = 10 ** 45;
    uint256 constant internal THOUSAND = 10 ** 3;
    uint256 constant internal MILLION  = 10 ** 6;
    uint256 constant internal BPS_ONE_PCT             = 100;
    uint256 constant internal BPS_ONE_HUNDRED_PCT     = 100 * BPS_ONE_PCT;
    uint256 constant internal RATES_ONE_HUNDRED_PCT   = 1000000021979553151239153027;
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {}
    function jug()        public view returns (address) { return getChangelogAddress("MCD_JUG"); }
    function end()        public view returns (address) { return getChangelogAddress("MCD_END"); }
    function reg()        public view returns (address) { return getChangelogAddress("ILK_REGISTRY"); }
    function autoLine()   public view returns (address) { return getChangelogAddress("MCD_IAM_AUTO_LINE"); }
    function lerpFab()    public view returns (address) { return getChangelogAddress("LERP_FAB"); }
    function clip(bytes32 _ilk) public view returns (address _clip) {}
    function flip(bytes32 _ilk) public view returns (address _flip) {}
    function calc(bytes32 _ilk) public view returns (address _calc) {}
    function getChangelogAddress(bytes32 _key) public view returns (address) {}
    function setAuthority(address _base, address _authority) public {}
    function canCast(uint40 _ts, bool _officeHours) public pure returns (bool) {}
    function nextCastTime(uint40 _eta, uint40 _ts, bool _officeHours) public pure returns (uint256 castTime) {}
    function setValue(address _base, bytes32 _what, uint256 _amt) public {}
    function setValue(address _base, bytes32 _ilk, bytes32 _what, uint256 _amt) public {}
    function setIlkAutoLineDebtCeiling(bytes32 _ilk, uint256 _amount) public {}
    function setIlkStabilityFee(bytes32 _ilk, uint256 _rate, bool _doDrip) public {}
    function linearInterpolation(bytes32 _name, address _target, bytes32 _ilk, bytes32 _what, uint256 _startTime, uint256 _start, uint256 _end, uint256 _duration) public returns (address) {}
}

////// lib/dss-exec-lib/src/DssAction.sol
//
// DssAction.sol -- DSS Executive Spell Actions
//
// Copyright (C) 2020 Maker Ecosystem Growth Holdings, Inc.
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

/* pragma solidity ^0.6.12; */

/* import { DssExecLib } from "./DssExecLib.sol"; */
/* import { CollateralOpts } from "./CollateralOpts.sol"; */

interface OracleLike_1 {
    function src() external view returns (address);
}

abstract contract DssAction {

    using DssExecLib for *;

    // Modifier used to limit execution time when office hours is enabled
    modifier limited {
        require(DssExecLib.canCast(uint40(block.timestamp), officeHours()), "Outside office hours");
        _;
    }

    // Office Hours defaults to true by default.
    //   To disable office hours, override this function and
    //    return false in the inherited action.
    function officeHours() public virtual returns (bool) {
        return true;
    }

    // DssExec calls execute. We limit this function subject to officeHours modifier.
    function execute() external limited {
        actions();
    }

    // DssAction developer must override `actions()` and place all actions to be called inside.
    //   The DssExec function will call this subject to the officeHours limiter
    //   By keeping this function public we allow simulations of `execute()` on the actions outside of the cast time.
    function actions() public virtual;

    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: seth keccak -- "$(wget https://<executive-vote-canonical-post> -q -O - 2>/dev/null)"
    function description() external virtual view returns (string memory);

    // Returns the next available cast time
    function nextCastTime(uint256 eta) external returns (uint256 castTime) {
        require(eta <= uint40(-1));
        castTime = DssExecLib.nextCastTime(uint40(eta), uint40(block.timestamp), officeHours());
    }
}

////// lib/dss-exec-lib/src/DssExec.sol
//
// DssExec.sol -- MakerDAO Executive Spell Template
//
// Copyright (C) 2020 Maker Ecosystem Growth Holdings, Inc.
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

/* pragma solidity ^0.6.12; */

interface PauseAbstract {
    function delay() external view returns (uint256);
    function plot(address, bytes32, bytes calldata, uint256) external;
    function exec(address, bytes32, bytes calldata, uint256) external returns (bytes memory);
}

interface Changelog {
    function getAddress(bytes32) external view returns (address);
}

interface SpellAction {
    function officeHours() external view returns (bool);
    function description() external view returns (string memory);
    function nextCastTime(uint256) external view returns (uint256);
}

contract DssExec {

    Changelog      constant public log   = Changelog(0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F);
    uint256                 public eta;
    bytes                   public sig;
    bool                    public done;
    bytes32       immutable public tag;
    address       immutable public action;
    uint256       immutable public expiration;
    PauseAbstract immutable public pause;

    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: seth keccak -- "$(wget https://<executive-vote-canonical-post> -q -O - 2>/dev/null)"
    function description() external view returns (string memory) {
        return SpellAction(action).description();
    }

    function officeHours() external view returns (bool) {
        return SpellAction(action).officeHours();
    }

    function nextCastTime() external view returns (uint256 castTime) {
        return SpellAction(action).nextCastTime(eta);
    }

    // @param _description  A string description of the spell
    // @param _expiration   The timestamp this spell will expire. (Ex. now + 30 days)
    // @param _spellAction  The address of the spell action
    constructor(uint256 _expiration, address _spellAction) public {
        pause       = PauseAbstract(log.getAddress("MCD_PAUSE"));
        expiration  = _expiration;
        action      = _spellAction;

        sig = abi.encodeWithSignature("execute()");
        bytes32 _tag;                    // Required for assembly access
        address _action = _spellAction;  // Required for assembly access
        assembly { _tag := extcodehash(_action) }
        tag = _tag;
    }

    function schedule() public {
        require(now <= expiration, "This contract has expired");
        require(eta == 0, "This spell has already been scheduled");
        eta = now + PauseAbstract(pause).delay();
        pause.plot(action, tag, sig, eta);
    }

    function cast() public {
        require(!done, "spell-already-cast");
        done = true;
        pause.exec(action, tag, sig, eta);
    }
}

////// src/Goerli-DssSpellCollateral.sol
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

/* pragma solidity 0.6.12; */
// Enable ABIEncoderV2 when onboarding collateral through `DssExecLib.addNewCollateral()`
// // pragma experimental ABIEncoderV2;

/* import "dss-exec-lib/DssExecLib.sol"; */

contract DssSpellCollateralAction {
    // --- Rates ---
    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    // A table of rates can be found at
    //    https://ipfs.io/ipfs/QmX2QMoM1SZq2XMoTbMak8pZP86Y2icpgPAKDjQg4r4YHn
    //

    function onboardNewCollaterals() internal {
        // ----------------------------- Collateral onboarding -----------------------------
        //  Add ______________ as a new Vault Type
        //  Poll Link:

        // DssExecLib.addNewCollateral(
        //     CollateralOpts({
        //         ilk:                   ,
        //         gem:                   ,
        //         join:                  ,
        //         clip:                  ,
        //         calc:                  ,
        //         pip:                   ,
        //         isLiquidatable:        ,
        //         isOSM:                 ,
        //         whitelistOSM:          ,
        //         ilkDebtCeiling:        ,
        //         minVaultAmount:        ,
        //         maxLiquidationAmount:  ,
        //         liquidationPenalty:    ,
        //         ilkStabilityFee:       ,
        //         startingPriceFactor:   ,
        //         breakerTolerance:      ,
        //         auctionDuration:       ,
        //         permittedDrop:         ,
        //         liquidationRatio:      ,
        //         kprFlatReward:         ,
        //         kprPctReward:
        //     })
        // );

        // DssExecLib.setStairstepExponentialDecrease(
        //     CALC_ADDR,
        //     DURATION,
        //     PCT_BPS
        // );

        // DssExecLib.setIlkAutoLineParameters(
        //     ILK,
        //     AMOUNT,
        //     GAP,
        //     TTL
        // );

        // ChainLog Updates
        // Add the new flip and join to the Chainlog
        // address constant CHAINLOG        = DssExecLib.LOG();
        // ChainlogAbstract(CHAINLOG).setAddress("<join-name>", <join-address>);
        // ChainlogAbstract(CHAINLOG).setAddress("<clip-name>", <clip-address>);
        // ChainlogAbstract(CHAINLOG).setVersion("<new-version>");
    }

    function offboardCollaterals() internal {}
}

////// src/Goerli-DssSpell.sol
// SPDX-FileCopyrightText: © 2020 Dai Foundation <www.daifoundation.org>
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

/* pragma solidity 0.6.12; */
// Enable ABIEncoderV2 when onboarding collateral through `DssExecLib.addNewCollateral()`
// // pragma experimental ABIEncoderV2;

/* import "dss-exec-lib/DssExec.sol"; */
/* import "dss-exec-lib/DssAction.sol"; */

/* import { DssSpellCollateralAction } from "./Goerli-DssSpellCollateral.sol"; */

interface RwaUrnLike {
    function draw(uint256) external;
}

contract DssSpellAction is DssAction, DssSpellCollateralAction {

    // Provides a descriptive tag for bot consumption
    string public constant override description = "Goerli Spell";

    uint256 constant internal MILLION  = 10 **  6;
    uint256 constant internal BILLION  = 10 **  9;
    uint256 constant internal WAD      = 10 ** 18;

    // address constant RWA008_A_OPERATOR       = 0x03f1A14A5b31e2f1751b6db368451dFCEA5A0439;
    // address constant RWA008_A_OUTPUT_CONDUIT = 0x1aA21d2E39EC0da185CA04609c8868bC324d8553;
    uint256 constant RWA009_DRAW_AMOUNT      = 25_000_000 * WAD;

    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    // A table of rates can be found at
    //    https://ipfs.io/ipfs/QmVp4mhhbwWGTfbh2BzwQB9eiBrQBKiqcPRZCaAxNUaar6
    //

    // --- Rates ---
    uint256 constant ZERO_PCT_RATE             = 1000000000000000000000000000;
    uint256 constant ZERO_ZERO_TWO_PCT_RATE    = 1000000000006341324285480111;
    uint256 constant ZERO_ZERO_SIX_PCT_RATE    = 1000000000019020169709960675;
    uint256 constant TWO_TWO_FIVE_PCT_RATE     = 1000000000705562181084137268;
    uint256 constant THREE_SEVEN_FIVE_PCT_RATE = 1000000001167363430498603315;

    function officeHours() public override returns (bool) {
        return false;
    }

    function actions() public override {
        // ---------------------------------------------------------------------
        // Includes changes from the DssSpellCollateralAction
        // onboardNewCollaterals();

        // ----------------------------- RWA Draws -----------------------------
        // https://vote.makerdao.com/polling/QmQMDasC#poll-detail
        // Weekly Draw for HVB
        address RWA009_A_URN = DssExecLib.getChangelogAddress("RWA009_A_URN");
        // Draw once to catch up to mainnet since there was no goerli spell last week
        RwaUrnLike(RWA009_A_URN).draw(RWA009_DRAW_AMOUNT);
        // Draw again for Aug 10 Exec Draw
        RwaUrnLike(RWA009_A_URN).draw(RWA009_DRAW_AMOUNT);

        // --------------------------- Rates updates ---------------------------
        // https://vote.makerdao.com/polling/QmfMRfE4#poll-detail

        // Reduce Stability Fee for    ETH-B   from 4% to 3.75%
        DssExecLib.setIlkStabilityFee("ETH-B", THREE_SEVEN_FIVE_PCT_RATE, true);

        // Reduce Stability Fee for    WSTETH-A   from 2.50% to 2.25%
        DssExecLib.setIlkStabilityFee("WSTETH-A", TWO_TWO_FIVE_PCT_RATE, true);

        // Reduce Stability Fee for    WSTETH-B   from 0.75% to 0%
        DssExecLib.setIlkStabilityFee("WSTETH-B", ZERO_PCT_RATE, true);

        // Reduce Stability Fee for    WBTC-B   from 4.00% to 3.75%
        DssExecLib.setIlkStabilityFee("WBTC-B", THREE_SEVEN_FIVE_PCT_RATE, true);

        // Increase Stability Fee for  GUNIV3DAIUSDC1-A   from 0.01% to 0.02%
        DssExecLib.setIlkStabilityFee("GUNIV3DAIUSDC1-A", ZERO_ZERO_TWO_PCT_RATE, true);

        // Increase Stability Fee for  GUNIV3DAIUSDC2-A   from 0.05% to 0.06%
        DssExecLib.setIlkStabilityFee("GUNIV3DAIUSDC2-A", ZERO_ZERO_SIX_PCT_RATE, true);

        // Increase Stability Fee for  UNIV2DAIUSDC-A   from 0.01% to 0.02%
        DssExecLib.setIlkStabilityFee("UNIV2DAIUSDC-A", ZERO_ZERO_TWO_PCT_RATE, true);

        // ------------------------ Debt Ceiling updates -----------------------
        // https://vote.makerdao.com/polling/QmfMRfE4#poll-detail

        // Increase the line for              GUNIV3DAIUSDC2-A from   1 billion to 1.25 billion DAI
        DssExecLib.setIlkAutoLineDebtCeiling("GUNIV3DAIUSDC2-A",                   1250 * MILLION);
        // Increase the line for              GUINV3DAIUSDC1-A from 750 million to 1 billion DAI
        DssExecLib.setIlkAutoLineDebtCeiling("GUNIV3DAIUSDC1-A",                   1 * BILLION);
        // Increase the line for              MANA-A           from  15 million to 17 million DAI
        DssExecLib.setIlkAutoLineDebtCeiling("MANA-A",                             17 * MILLION);

        // ----------------------- Activate SocGen Vault -----------------------
        // NOTE: ignore in goerli
        // call hope() on RWA008_A_OUTPUT_CONDUIT
        // https://discord.com/channels/893112320329396265/897483518316265553/1004725159506231316
        // Hopeable(RWA008_A_OUTPUT_CONDUIT).hope(RWA008_A_OPERATOR);

        // ------------------------- Delegate Payments -------------------------
        // NOTE: ignore in goerli
        // Recognized Delegate Compensation - July 2022
        // Flip Flop Flap Delegate LLC - 12000 DAI - 0x688d508f3a6B0a377e266405A1583B3316f9A2B3
        // Feedblack Loops LLC         - 12000 DAI - 0x80882f2A36d49fC46C3c654F7f9cB9a2Bf0423e1
        // JustinCase                  - 12000 DAI - 0xE070c2dCfcf6C6409202A8a210f71D51dbAe9473
        // Doo                         - 12000 DAI - 0x3B91eBDfBC4B78d778f62632a4004804AC5d2DB0
        // schuppi                     - 11918 DAI - 0xCCffDBc38B1463847509dCD95e0D9AAf54D1c167
        // Flipside Crypto             - 11387 DAI - 0x62a43123FE71f9764f26554b3F5017627996816a
        // Penn Blockchain             -  9438 DAI - 0x2165d41af0d8d5034b9c266597c1a415fa0253bd
        // Chris Blec                  -  9174 DAI - 0xa3f0AbB4Ba74512b5a736C5759446e9B50FDA170
        // GFX Labs                    -  8512 DAI - 0xa6e8772af29b29B9202a073f8E36f447689BEef6
        // MakerMan                    -  6912 DAI - 0x9AC6A6B24bCd789Fa59A175c0514f33255e1e6D0
        // ACREInvest                  -  6628 DAI - 0x5b9C98e8A3D9Db6cd4B4B4C1F92D0A551D06F00D
        // mhonkasalo & teemulau       -  4029 DAI - 0x97Fb39171ACd7C82c439b6158EA2F71D26ba383d
        // Llama                       -  3797 DAI - 0x82cD339Fa7d6f22242B31d5f7ea37c1B721dB9C3
        // [email protected]         -  2013 DAI - 0xdC1F98682F4F8a5c6d54F345F448437b83f5E432

    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) public {}
}