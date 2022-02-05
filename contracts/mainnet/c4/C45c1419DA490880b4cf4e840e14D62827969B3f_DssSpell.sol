/**
 *Submitted for verification at Etherscan.io on 2022-02-04
*/

// hevm: flattened sources of src/DssSpell.sol
// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity =0.6.12 >=0.5.12 >=0.6.12 <0.7.0;
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
    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {}
    function rdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {}
    function dai()        public view returns (address) { return getChangelogAddress("MCD_DAI"); }
    function vat()        public view returns (address) { return getChangelogAddress("MCD_VAT"); }
    function jug()        public view returns (address) { return getChangelogAddress("MCD_JUG"); }
    function vow()        public view returns (address) { return getChangelogAddress("MCD_VOW"); }
    function end()        public view returns (address) { return getChangelogAddress("MCD_END"); }
    function reg()        public view returns (address) { return getChangelogAddress("ILK_REGISTRY"); }
    function autoLine()   public view returns (address) { return getChangelogAddress("MCD_IAM_AUTO_LINE"); }
    function daiJoin()    public view returns (address) { return getChangelogAddress("MCD_JOIN_DAI"); }
    function lerpFab()    public view returns (address) { return getChangelogAddress("LERP_FAB"); }
    function clip(bytes32 _ilk) public view returns (address _clip) {}
    function flip(bytes32 _ilk) public view returns (address _flip) {}
    function calc(bytes32 _ilk) public view returns (address _calc) {}
    function getChangelogAddress(bytes32 _key) public view returns (address) {}
    function setChangelogAddress(bytes32 _key, address _val) public {}
    function setChangelogVersion(string memory _version) public {}
    function authorize(address _base, address _ward) public {}
    function deauthorize(address _base, address _ward) public {}
    function setAuthority(address _base, address _authority) public {}
    function canCast(uint40 _ts, bool _officeHours) public pure returns (bool) {}
    function nextCastTime(uint40 _eta, uint40 _ts, bool _officeHours) public pure returns (uint256 castTime) {}
    function setValue(address _base, bytes32 _what, uint256 _amt) public {}
    function setValue(address _base, bytes32 _ilk, bytes32 _what, uint256 _amt) public {}
    function setIlkAutoLineParameters(bytes32 _ilk, uint256 _amount, uint256 _gap, uint256 _ttl) public {}
    function setIlkAutoLineDebtCeiling(bytes32 _ilk, uint256 _amount) public {}
    function setIlkStabilityFee(bytes32 _ilk, uint256 _rate, bool _doDrip) public {}
    function setD3MTargetInterestRate(address _d3m, uint256 _pct_bps) public {}
    function sendPaymentFromSurplusBuffer(address _target, uint256 _amount) public {}
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

////// lib/dss-interfaces/src/dss/DaiJoinAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/makerdao/dss/blob/master/src/join.sol
interface DaiJoinAbstract {
    function wards(address) external view returns (uint256);
    function rely(address usr) external;
    function deny(address usr) external;
    function vat() external view returns (address);
    function dai() external view returns (address);
    function live() external view returns (uint256);
    function cage() external;
    function join(address, uint256) external;
    function exit(address, uint256) external;
}

////// lib/dss-interfaces/src/dss/ESMAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/makerdao/esm/blob/master/src/ESM.sol
interface ESMAbstract {
    function gem() external view returns (address);
    function proxy() external view returns (address);
    function wards(address) external view returns (uint256);
    function sum(address) external view returns (address);
    function Sum() external view returns (uint256);
    function min() external view returns (uint256);
    function end() external view returns (address);
    function live() external view returns (uint256);
    function revokesGovernanceAccess() external view returns (bool);
    function rely(address) external;
    function deny(address) external;
    function file(bytes32, uint256) external;
    function file(bytes32, address) external;
    function cage() external;
    function fire() external;
    function denyProxy(address) external;
    function join(uint256) external;
    function burn() external;
}

////// lib/dss-interfaces/src/dss/VatAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/makerdao/dss/blob/master/src/vat.sol
interface VatAbstract {
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function can(address, address) external view returns (uint256);
    function hope(address) external;
    function nope(address) external;
    function ilks(bytes32) external view returns (uint256, uint256, uint256, uint256, uint256);
    function urns(bytes32, address) external view returns (uint256, uint256);
    function gem(bytes32, address) external view returns (uint256);
    function dai(address) external view returns (uint256);
    function sin(address) external view returns (uint256);
    function debt() external view returns (uint256);
    function vice() external view returns (uint256);
    function Line() external view returns (uint256);
    function live() external view returns (uint256);
    function init(bytes32) external;
    function file(bytes32, uint256) external;
    function file(bytes32, bytes32, uint256) external;
    function cage() external;
    function slip(bytes32, address, int256) external;
    function flux(bytes32, address, address, uint256) external;
    function move(address, address, uint256) external;
    function frob(bytes32, address, address, address, int256, int256) external;
    function fork(bytes32, address, address, int256, int256) external;
    function grab(bytes32, address, address, address, int256, int256) external;
    function heal(uint256) external;
    function suck(address, address, uint256) external;
    function fold(bytes32, address, int256) external;
}

////// lib/dss-interfaces/src/dss/VestAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/makerdao/dss-vest/blob/master/src/DssVest.sol
interface VestAbstract {
    function TWENTY_YEARS() external view returns (uint256);
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function awards(uint256) external view returns (address, uint48, uint48, uint48, address, uint8, uint128, uint128);
    function ids() external view returns (uint256);
    function cap() external view returns (uint256);
    function usr(uint256) external view returns (address);
    function bgn(uint256) external view returns (uint256);
    function clf(uint256) external view returns (uint256);
    function fin(uint256) external view returns (uint256);
    function mgr(uint256) external view returns (address);
    function res(uint256) external view returns (uint256);
    function tot(uint256) external view returns (uint256);
    function rxd(uint256) external view returns (uint256);
    function file(bytes32, uint256) external;
    function create(address, uint256, uint256, uint256, uint256, address) external returns (uint256);
    function vest(uint256) external;
    function vest(uint256, uint256) external;
    function accrued(uint256) external view returns (uint256);
    function unpaid(uint256) external view returns (uint256);
    function restrict(uint256) external;
    function unrestrict(uint256) external;
    function yank(uint256) external;
    function yank(uint256, uint256) external;
    function move(uint256, address) external;
    function valid(uint256) external view returns (bool);
}

////// src/DssSpellCollateralOnboarding.sol
//
// Copyright (C) 2021-2022 Dai Foundation
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

/* import "dss-exec-lib/DssExecLib.sol"; */

contract DssSpellCollateralOnboardingAction {

    // --- Rates ---
    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    // A table of rates can be found at
    //    https://ipfs.io/ipfs/QmTRiQ3GqjCiRhh1ojzKzgScmSsiwQPLyjhgYSxZASQekj
    //

    // --- Math ---

    // --- DEPLOYED COLLATERAL ADDRESSES ---

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
}

////// src/DssSpell.sol
//
// Copyright (C) 2021-2022 Dai Foundation
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
// Enable ABIEncoderV2 when onboarding collateral
//// pragma experimental ABIEncoderV2;
/* import "dss-exec-lib/DssExec.sol"; */
/* import "dss-exec-lib/DssAction.sol"; */
/* import "dss-interfaces/dss/DaiJoinAbstract.sol"; */
/* import "dss-interfaces/dss/VatAbstract.sol"; */
/* import "dss-interfaces/dss/VestAbstract.sol"; */
/* import "dss-interfaces/dss/ESMAbstract.sol"; */

/* import { DssSpellCollateralOnboardingAction } from "./DssSpellCollateralOnboarding.sol"; */


contract DssSpellAction is DssAction, DssSpellCollateralOnboardingAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/21f922bcb595218ef3a27b8e744d54fa1952241a/governance/votes/Executive%20Vote%20-%20February%204%2C%202022.md -q -O - 2>/dev/null)"
    string public constant override description =
        "2022-02-04 MakerDAO Executive Spell | Hash: 0x0657ea988166b3dfd3ae97e4edbf3c15de78c6abb24f8685e1964df754d6f235";

    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    // A table of rates can be found at
    //    https://ipfs.io/ipfs/QmefQMseb3AiTapiAKKexdKHig8wroKuZbmLtPLv4u2YwW
    //
    uint256 constant ZERO_PCT_RATE                = 1000000000000000000000000000;
    uint256 constant ZERO_PT_TWO_FIVE_PCT_RATE    = 1000000000079175551708715274;
    uint256 constant ZERO_PT_SEVEN_FIVE_PCT_RATE  = 1000000000236936036262880196;
    uint256 constant ONE_PCT_RATE                 = 1000000000315522921573372069;
    uint256 constant ONE_PT_FIVE_PCT_RATE         = 1000000000472114805215157978;
    uint256 constant TWO_PCT_RATE                 = 1000000000627937192491029810;
    uint256 constant TWO_PT_TWO_FIVE_PCT_RATE     = 1000000000705562181084137268;
    uint256 constant TWO_PT_FIVE_PCT_RATE         = 1000000000782997609082909351;
    uint256 constant THREE_PT_SEVEN_FIVE_PCT_RATE = 1000000001167363430498603315;
    uint256 constant FOUR_PCT_RATE                = 1000000001243680656318820312;
    uint256 constant FIVE_PCT_RATE                = 1000000001547125957863212448;

    address constant NEW_MCD_ESM  = 0x09e05fF6142F2f9de8B6B65855A1d56B6cfE4c58;
    bytes32 constant MCD_ESM_NAME = "MCD_ESM";

    address constant FLIP_FLOP_FLAP_WALLET  = 0x688d508f3a6B0a377e266405A1583B3316f9A2B3;
    address constant FEEDBLACK_LOOPS_WALLET = 0x80882f2A36d49fC46C3c654F7f9cB9a2Bf0423e1;
    address constant SCHUPPI_WALLET         = 0x89C5d54C979f682F40b73a9FC39F338C88B434c6;
    address constant MAKERMAN_WALLET        = 0x9AC6A6B24bCd789Fa59A175c0514f33255e1e6D0;
    address constant MONETSUPPLY_WALLET     = 0x4Bd73eeE3d0568Bb7C52DFCad7AD5d47Fff5E2CF;
    address constant ACRE_INVEST_WALLET     = 0x5b9C98e8A3D9Db6cd4B4B4C1F92D0A551D06F00D;
    address constant JUSTIN_CASE_WALLET     = 0xE070c2dCfcf6C6409202A8a210f71D51dbAe9473;
    address constant GFX_LABS_WALLET        = 0xa6e8772af29b29B9202a073f8E36f447689BEef6;

    VestAbstract immutable VEST             = VestAbstract(DssExecLib.getChangelogAddress("MCD_VEST_DAI"));
    address immutable      MCD_VAT          = DssExecLib.getChangelogAddress("MCD_VAT");
    address immutable      MCD_VOW          = DssExecLib.getChangelogAddress("MCD_VOW");
    address immutable      MCD_JOIN_DAI     = DssExecLib.getChangelogAddress("MCD_JOIN_DAI");
    address immutable      OLD_MCD_ESM      = DssExecLib.getChangelogAddress(MCD_ESM_NAME);

    address constant SF_001_WALLET          = 0xf737C76D2B358619f7ef696cf3F94548fEcec379;
    address constant SNE_001_WALLET         = 0x6D348f18c88D45243705D4fdEeB6538c6a9191F1;

    uint256 constant MAR_01_2022            = 1646092800;
    uint256 constant JUL_31_2022            = 1659225600;

    // Math
    uint256 constant MILLION = 10**6;
    uint256 constant WAD = 10**18;
    uint256 constant RAY = 10**27;

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "sub-underflow");
    }

    function actions() public override {

        // Includes changes from the DssSpellCollateralOnboardingAction
        // onboardNewCollaterals();

        address addr;


        //////////////////////////////////////////////////////////
        // Update rates to mainnet
        // PPG - Open Market Committee Proposal - January 31, 2022
        // https://vote.makerdao.com/polling/QmWReBMh?network=mainnet#poll-detail

        /// Stability Fee Decreases

        // Decrease the ETH-A Stability Fee from 2.5% to 2.25%.
        DssExecLib.setIlkStabilityFee("ETH-A", TWO_PT_TWO_FIVE_PCT_RATE, true);

        // Decrease the ETH-B Stability Fee from 6.5% to 4%.
        DssExecLib.setIlkStabilityFee("ETH-B", FOUR_PCT_RATE, true);

        // Decrease the WSTETH-A Stability Fee from 3% to 2.5%.
        DssExecLib.setIlkStabilityFee("WSTETH-A", TWO_PT_FIVE_PCT_RATE, true);

        // Decrease the WBTC-A Stability Fee from 4% to 3.75%.
        DssExecLib.setIlkStabilityFee("WBTC-A", THREE_PT_SEVEN_FIVE_PCT_RATE, true);

        // Decrease the WBTC-B Stability Fee from 7% to 5%.
        DssExecLib.setIlkStabilityFee("WBTC-B", FIVE_PCT_RATE, true);

        // Decrease the WBTC-C Stability Fee from 1.5% to 0.75%.
        DssExecLib.setIlkStabilityFee("WBTC-C", ZERO_PT_SEVEN_FIVE_PCT_RATE, true);

        // Decrease the UNIV2DAIETH-A Stability Fee from 2% to 1%.
        DssExecLib.setIlkStabilityFee("UNIV2DAIETH-A", ONE_PCT_RATE, true);

        // Decrease the UNIV2WBTCETH-A Stability Fee from 3% to 2%.
        DssExecLib.setIlkStabilityFee("UNIV2WBTCETH-A", TWO_PCT_RATE, true);

        // Decrease the UNIV2USDCETH-A Stability Fee from 2.5% to 1.5%.
        DssExecLib.setIlkStabilityFee("UNIV2USDCETH-A", ONE_PT_FIVE_PCT_RATE, true);

        // Decrease the GUNIV3DAIUSDC2-A Stability Fee from 0.5% to 0.25%.
        DssExecLib.setIlkStabilityFee("GUNIV3DAIUSDC2-A", ZERO_PT_TWO_FIVE_PCT_RATE, true);

        // Decrease the TUSD-A Stability Fee from 1% to 0%.
        DssExecLib.setIlkStabilityFee("TUSD-A", ZERO_PCT_RATE, true);


        /// DIRECT-AAVEV2-DAI (Aave D3M) Target Borrow Rate Decrease

        // Decrease the DIRECT-AAVEV2-DAI Target Borrow Rate from 3.75% to 3.5%.
        DssExecLib.setD3MTargetInterestRate(DssExecLib.getChangelogAddress("MCD_JOIN_DIRECT_AAVEV2_DAI"), 350); // 3.5%

        /// Maximum Debt Ceiling Changes + GUNIV3DAIUSDC2-A Target Available Debt Increase

        // Decrease the GUNIV3DAIUSDC1-A Maximum Debt Ceiling from 500 million DAI to 100 million DAI.
        DssExecLib.setIlkAutoLineDebtCeiling("GUNIV3DAIUSDC1-A", 100 * MILLION);

        // Increase the GUNIV3DAIUSDC2-A Maximum Debt Ceiling from 500 million DAI to 750 million DAI.
        // Increase the GUNIV3DAIUSDC2-A Target Available Debt (gap) from 10 million DAI to 50 million DAI.
        DssExecLib.setIlkAutoLineParameters("GUNIV3DAIUSDC2-A", 750 * MILLION, 50 * MILLION, 8 hours);


        //////////////////////////////////////////////////////////
        // Set the ESM threshold to 100k MKR
        // https://vote.makerdao.com/polling/QmQSVmrh?network=mainnet#poll-detail

        require(ESMAbstract(NEW_MCD_ESM).min() == 100_000 * WAD, "DssSpellAction/error-esm-min");
        require(ESMAbstract(NEW_MCD_ESM).end() == DssExecLib.getChangelogAddress("MCD_END"), "DssSpellAction/error-esm-end");
        require(ESMAbstract(NEW_MCD_ESM).gem() == DssExecLib.getChangelogAddress("MCD_GOV"), "DssSpellAction/error-esm-gov");
        require(ESMAbstract(NEW_MCD_ESM).proxy() == address(this), "DssSpellAction/error-esm-proxy");

        bytes32[] memory keys = new bytes32[](51);
        keys[0]  = bytes32("MCD_END");
        keys[1]  = bytes32("MCD_CLIP_ETH_A");
        keys[2]  = bytes32("MCD_CLIP_ETH_B");
        keys[3]  = bytes32("MCD_CLIP_ETH_C");
        keys[4]  = bytes32("MCD_CLIP_BAT_A");
        keys[5]  = bytes32("MCD_CLIP_USDC_A");
        keys[6]  = bytes32("MCD_CLIP_USDC_B");
        keys[7]  = bytes32("MCD_CLIP_TUSD_A");
        keys[8]  = bytes32("MCD_CLIP_WBTC_A");
        keys[9]  = bytes32("MCD_CLIP_ZRX_A");
        keys[10] = bytes32("MCD_CLIP_KNC_A");
        keys[11] = bytes32("MCD_CLIP_MANA_A");
        keys[12] = bytes32("MCD_CLIP_USDT_A");
        keys[13] = bytes32("MCD_CLIP_PAXUSD_A");
        keys[14] = bytes32("MCD_CLIP_COMP_A");
        keys[15] = bytes32("MCD_CLIP_LRC_A");
        keys[16] = bytes32("MCD_CLIP_LINK_A");
        keys[17] = bytes32("MCD_CLIP_BAL_A");
        keys[18] = bytes32("MCD_CLIP_YFI_A");
        keys[19] = bytes32("MCD_CLIP_GUSD_A");
        keys[20] = bytes32("MCD_CLIP_UNI_A");
        keys[21] = bytes32("MCD_CLIP_RENBTC_A");
        keys[22] = bytes32("MCD_CLIP_AAVE_A");
        keys[23] = bytes32("MCD_CLIP_PSM_USDC_A");
        keys[24] = bytes32("MCD_CLIP_MATIC_A");
        keys[25] = bytes32("MCD_CLIP_UNIV2DAIETH_A");
        keys[26] = bytes32("MCD_CLIP_UNIV2WBTCETH_A");
        keys[27] = bytes32("MCD_CLIP_UNIV2USDCETH_A");
        keys[28] = bytes32("MCD_CLIP_UNIV2DAIUSDC_A");
        keys[29] = bytes32("MCD_CLIP_UNIV2ETHUSDT_A");
        keys[30] = bytes32("MCD_CLIP_UNIV2LINKETH_A");
        keys[31] = bytes32("MCD_CLIP_UNIV2UNIETH_A");
        keys[32] = bytes32("MCD_CLIP_UNIV2WBTCDAI_A");
        keys[33] = bytes32("MCD_CLIP_UNIV2AAVEETH_A");
        keys[34] = bytes32("MCD_CLIP_UNIV2DAIUSDT_A");
        keys[35] = bytes32("MCD_CLIP_PSM_PAX_A");
        keys[36] = bytes32("MCD_CLIP_GUNIV3DAIUSDC1_A");
        keys[37] = bytes32("MCD_CLIP_WSTETH_A");
        keys[38] = bytes32("MCD_CLIP_WBTC_B");
        keys[39] = bytes32("MCD_CLIP_WBTC_C");
        keys[40] = bytes32("MCD_CLIP_PSM_GUSD_A");
        keys[41] = bytes32("MCD_CLIP_GUNIV3DAIUSDC2_A");
        keys[42] = bytes32("MCD_VAT");
        keys[43] = bytes32("MCD_CLIP_DIRECT_AAVEV2_DAI");
        keys[44] = bytes32("OPTIMISM_DAI_BRIDGE");
        keys[45] = bytes32("OPTIMISM_ESCROW");
        keys[46] = bytes32("OPTIMISM_GOV_RELAY");
        keys[47] = bytes32("ARBITRUM_DAI_BRIDGE");
        keys[48] = bytes32("ARBITRUM_ESCROW");
        keys[49] = bytes32("ARBITRUM_GOV_RELAY");
        keys[50] = bytes32("MCD_JOIN_DIRECT_AAVEV2_DAI");

        for (uint256 i = 0; i < keys.length; i++) {
            addr = DssExecLib.getChangelogAddress(keys[i]);
            DssExecLib.deauthorize(addr, OLD_MCD_ESM);
            DssExecLib.authorize(addr, NEW_MCD_ESM);
        }

        DssExecLib.setChangelogAddress(MCD_ESM_NAME, NEW_MCD_ESM);
        DssExecLib.setChangelogVersion("1.10.0");

        //////////////////////////////////////////////////////////
        // Delegate Compensation January Distribution
        // https://forum.makerdao.com/t/recognized-delegate-compensation-breakdown-january-2022/13001

        DssExecLib.sendPaymentFromSurplusBuffer(FLIP_FLOP_FLAP_WALLET,  12_000);
        DssExecLib.sendPaymentFromSurplusBuffer(FEEDBLACK_LOOPS_WALLET, 12_000);
        DssExecLib.sendPaymentFromSurplusBuffer(SCHUPPI_WALLET,         12_000);
        DssExecLib.sendPaymentFromSurplusBuffer(MAKERMAN_WALLET,         8_620);
        DssExecLib.sendPaymentFromSurplusBuffer(MONETSUPPLY_WALLET,      4_807);
        DssExecLib.sendPaymentFromSurplusBuffer(ACRE_INVEST_WALLET,      3_795);
        DssExecLib.sendPaymentFromSurplusBuffer(JUSTIN_CASE_WALLET,        889);
        DssExecLib.sendPaymentFromSurplusBuffer(GFX_LABS_WALLET,           641);


        //////////////////////////////////////////////////////////
        // Repair Dai Streams
        // https://forum.makerdao.com/t/correction-to-last-weeks-executive/13022

        // MIP40c3-SP47: Core Unit Budget (SNE-001) - Phase II StarkNet Fast Withdrawal and Wormhole
        // https://mips.makerdao.com/mips/details/MIP40c3SP47
        uint256 _sneId = 24;
        // Send first month payment minus accrued amount
        uint256 snePayment = sub(42_917 * WAD, VEST.accrued(_sneId));
        VatAbstract(MCD_VAT).suck(MCD_VOW, address(this), snePayment * RAY);  // WAD * RAY == RAD
        DaiJoinAbstract(MCD_JOIN_DAI).exit(SNE_001_WALLET, snePayment);
        // Cancel
        VEST.unrestrict(_sneId);
        VEST.vest(_sneId); // Pay unpaid stream amount
        VEST.yank(_sneId);
        // Stream payments for months 2-6
        VEST.restrict(
            VEST.create(SNE_001_WALLET,     214_583 * WAD, MAR_01_2022, JUL_31_2022 - MAR_01_2022,            0, address(0))
        );
        // Total of payments = 257_500

        // MIP40c3-SP46: Adding Strategic Finance Core Unit Budget (SF-001)
        // https://mips.makerdao.com/mips/details/MIP40c3SP46
        uint256 _sfId = 26;
        // Send first month payment minus accrued amount
        uint256 sfPayment = sub(82_417 * WAD, VEST.accrued(_sfId));
        VatAbstract(MCD_VAT).suck(MCD_VOW, address(this), sfPayment * RAY);
        DaiJoinAbstract(MCD_JOIN_DAI).exit(SF_001_WALLET, sfPayment);
        // Cancel stream
        VEST.unrestrict(_sfId);
        VEST.vest(_sfId); // Pay unpaid stream amount
        VEST.yank(_sfId);
        // Stream payments for months 2-6
        VEST.restrict(
            VEST.create(SF_001_WALLET,      412_085 * WAD, MAR_01_2022, JUL_31_2022 - MAR_01_2022,            0, address(0))
        );
        // Total of payments = 494_502

    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) public {}
}