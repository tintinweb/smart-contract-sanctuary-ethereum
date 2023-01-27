/**
 *Submitted for verification at Etherscan.io on 2023-01-26
*/

// hevm: flattened sources of src/DssSpell.sol
// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity =0.8.16 >=0.8.16 <0.9.0;

////// lib/dss-exec-lib/src/CollateralOpts.sol
//
// CollateralOpts.sol -- Data structure for onboarding collateral
//
// Copyright (C) 2020-2022 Dai Foundation
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

/* pragma solidity ^0.8.16; */

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
// Copyright (C) 2020-2022 Dai Foundation
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

/* pragma solidity ^0.8.16; */

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
    function suck(address, address, uint256) external;
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
    function join(address, uint256) external;
    function exit(address, uint256) external;
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

interface RegistryLike_1 {
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

interface RwaOracleLike {
    function bump(bytes32 ilk, uint256 val) external;
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
    function mkr()        public view returns (address) { return getChangelogAddress("MCD_GOV"); }
    function vat()        public view returns (address) { return getChangelogAddress("MCD_VAT"); }
    function dog()        public view returns (address) { return getChangelogAddress("MCD_DOG"); }
    function jug()        public view returns (address) { return getChangelogAddress("MCD_JUG"); }
    function end()        public view returns (address) { return getChangelogAddress("MCD_END"); }
    function esm()        public view returns (address) { return getChangelogAddress("MCD_ESM"); }
    function reg()        public view returns (address) { return getChangelogAddress("ILK_REGISTRY"); }
    function autoLine()   public view returns (address) { return getChangelogAddress("MCD_IAM_AUTO_LINE"); }
    function lerpFab()    public view returns (address) { return getChangelogAddress("LERP_FAB"); }
    function clip(bytes32 _ilk) public view returns (address _clip) {}
    function flip(bytes32 _ilk) public view returns (address _flip) {}
    function calc(bytes32 _ilk) public view returns (address _calc) {}
    function getChangelogAddress(bytes32 _key) public view returns (address) {}
    function setChangelogVersion(string memory _version) public {}
    function authorize(address _base, address _ward) public {}
    function deauthorize(address _base, address _ward) public {}
    function setAuthority(address _base, address _authority) public {}
    function canCast(uint40 _ts, bool _officeHours) public pure returns (bool) {}
    function nextCastTime(uint40 _eta, uint40 _ts, bool _officeHours) public pure returns (uint256 castTime) {}
    function setValue(address _base, bytes32 _what, uint256 _amt) public {}
    function setValue(address _base, bytes32 _ilk, bytes32 _what, uint256 _amt) public {}
    function setIlkAutoLineParameters(bytes32 _ilk, uint256 _amount, uint256 _gap, uint256 _ttl) public {}
    function removeIlkFromAutoLine(bytes32 _ilk) public {}
    function setIlkStabilityFee(bytes32 _ilk, uint256 _rate, bool _doDrip) public {}
    function linearInterpolation(bytes32 _name, address _target, bytes32 _ilk, bytes32 _what, uint256 _startTime, uint256 _start, uint256 _end, uint256 _duration) public returns (address) {}
}

////// lib/dss-exec-lib/src/DssAction.sol
//
// DssAction.sol -- DSS Executive Spell Actions
//
// Copyright (C) 2020-2022 Dai Foundation
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

/* pragma solidity ^0.8.16; */

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
    function officeHours() public view virtual returns (bool) {
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
    function description() external view virtual returns (string memory);

    // Returns the next available cast time
    function nextCastTime(uint256 eta) external view returns (uint256 castTime) {
        require(eta <= type(uint40).max);
        castTime = DssExecLib.nextCastTime(uint40(eta), uint40(block.timestamp), officeHours());
    }
}

////// lib/dss-exec-lib/src/DssExec.sol
//
// DssExec.sol -- MakerDAO Executive Spell Template
//
// Copyright (C) 2020-2022 Dai Foundation
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

/* pragma solidity ^0.8.16; */

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
    // @param _expiration   The timestamp this spell will expire. (Ex. block.timestamp + 30 days)
    // @param _spellAction  The address of the spell action
    constructor(uint256 _expiration, address _spellAction) {
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
        require(block.timestamp <= expiration, "This contract has expired");
        require(eta == 0, "This spell has already been scheduled");
        eta = block.timestamp + PauseAbstract(pause).delay();
        pause.plot(action, tag, sig, eta);
    }

    function cast() public {
        require(!done, "spell-already-cast");
        done = true;
        pause.exec(action, tag, sig, eta);
    }
}

////// src/DssSpell.sol
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

/* pragma solidity 0.8.16; */

/* import "dss-exec-lib/DssExec.sol"; */
/* import "dss-exec-lib/DssAction.sol"; */

interface ChainLogLike {
    function removeAddress(bytes32) external;
}

interface GemLike {
    function transfer(address, uint256) external returns (bool);
}

interface CageLike {
    function cage() external;
}

interface D3MLegacyMomLike {
    function setAuthority(address) external;
    function setOwner(address) external;
}

interface RegistryLike_2 {
    function remove(bytes32) external;
}

interface VatLike {
    function Line() external view returns (uint256);
    function ilks(bytes32) external returns (uint256 Art, uint256 rate, uint256 spot, uint256 line, uint256 dust);
}

contract DssSpellAction is DssAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/2d14219f8850d2261c1e65b7faa7cfecd138951f/governance/votes/Executive%20vote%20-%20January%2027%2C%202023.md -q -O - 2>/dev/null)"
    string public constant override description =
        "2023-01-27 MakerDAO Executive Spell | Hash: 0x0544972c4fa0e63df554701e9a8ed2d16fc8ca17b7ea719a35933913f9794967";

    // Turn office hours off
    function officeHours() public pure override returns (bool) {
        return false;
    }

    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    // A table of rates can be found at
    //    https://ipfs.io/ipfs/QmVp4mhhbwWGTfbh2BzwQB9eiBrQBKiqcPRZCaAxNUaar6
    //
    // uint256 internal constant X_PCT_RATE      = ;
    uint256 internal constant ZERO_PT_TWO_FIVE_PCT_RATE = 1000000000079175551708715274;

    uint256 internal constant MILLION = 10 ** 6;
    // uint256 internal constant RAY  = 10 ** 27;
    uint256 internal constant WAD     = 10 ** 18;

    ChainLogLike internal immutable chainlog    = ChainLogLike(DssExecLib.getChangelogAddress("CHANGELOG"));
    VatLike      internal immutable vat         = VatLike(DssExecLib.vat());
    address      internal immutable DOG         = DssExecLib.dog();

    address internal immutable FLASH_KILLER     = DssExecLib.getChangelogAddress("FLASH_KILLER");
    address internal immutable MCD_FLASH        = DssExecLib.getChangelogAddress("MCD_FLASH");
    address internal immutable MCD_FLASH_LEGACY = DssExecLib.getChangelogAddress("MCD_FLASH_LEGACY");

    address internal immutable MCD_PSM_PAX_A    = DssExecLib.getChangelogAddress("MCD_PSM_PAX_A");
    address internal immutable MCD_PSM_GUSD_A   = DssExecLib.getChangelogAddress("MCD_PSM_GUSD_A");

    address internal immutable MCD_JOIN_DIRECT_AAVEV2_DAI = DssExecLib.getChangelogAddress("MCD_JOIN_DIRECT_AAVEV2_DAI");
    address internal immutable MCD_CLIP_DIRECT_AAVEV2_DAI = DssExecLib.getChangelogAddress("MCD_CLIP_DIRECT_AAVEV2_DAI");
    address internal immutable MCD_CLIP_CALC_DIRECT_AAVEV2_DAI = DssExecLib.getChangelogAddress("MCD_CLIP_CALC_DIRECT_AAVEV2_DAI");
    address internal immutable DIRECT_MOM_LEGACY = DssExecLib.getChangelogAddress("DIRECT_MOM_LEGACY");

    address internal immutable CES_WALLET = 0x25307aB59Cd5d8b4E2C01218262Ddf6a89Ff86da;

    function actions() public override {

        // MOMC Parameter Changes
        // https://vote.makerdao.com/polling/QmYUi9Tk

        // Increase WSTETH-B Stability Fee to 0.25%
        DssExecLib.setIlkStabilityFee("WSTETH-B", ZERO_PT_TWO_FIVE_PCT_RATE, true);

        // Increase Compound v2 D3M Maximum Debt Ceiling to 20 million
        // Set Compound v2 D3M Target Available Debt to 5 million DAI (this might already be the case)
        DssExecLib.setIlkAutoLineParameters("DIRECT-COMPV2-DAI", 20 * MILLION, 5 * MILLION, 12 hours);

        // Increase the USDP PSM tin to 0.2%
        DssExecLib.setValue(MCD_PSM_PAX_A, "tin", 20 * WAD / 10000);   // 20 BPS


        // MKR Transfer for CES
        // https://vote.makerdao.com/polling/QmbNVQ1E

        // CES-001 - 96.15 MKR - 0x25307aB59Cd5d8b4E2C01218262Ddf6a89Ff86da
        GemLike(DssExecLib.mkr()).transfer(CES_WALLET, 96.15 ether); // ether as solidity alias


        // Cage DIRECT-AAVEV2-DAI
        // https://forum.makerdao.com/t/housekeeping-tasks-for-next-executive/19472
        CageLike(MCD_JOIN_DIRECT_AAVEV2_DAI).cage();

        // Deconstruct module for extra safety
        DssExecLib.deauthorize(MCD_CLIP_DIRECT_AAVEV2_DAI, DOG);
        DssExecLib.deauthorize(MCD_JOIN_DIRECT_AAVEV2_DAI, DIRECT_MOM_LEGACY);

        // Remove module relies on end and esm so we know if our end keeper calls are out of date
        DssExecLib.deauthorize(MCD_CLIP_DIRECT_AAVEV2_DAI, DssExecLib.end());
        DssExecLib.deauthorize(MCD_CLIP_DIRECT_AAVEV2_DAI, DssExecLib.esm());
        DssExecLib.deauthorize(MCD_JOIN_DIRECT_AAVEV2_DAI, DssExecLib.esm());

        // Remove module from core
        bytes32 _ilk = "DIRECT-AAVEV2-DAI";
        DssExecLib.removeIlkFromAutoLine(_ilk);
        (,,, uint256 _line,) = vat.ilks(_ilk);

        // set core values to 0/stopped
        DssExecLib.setValue(address(vat), _ilk, "line", 0);
        DssExecLib.setValue(address(vat), "Line", vat.Line() - _line);
        DssExecLib.setValue(MCD_CLIP_DIRECT_AAVEV2_DAI, "stopped", 3);

        // Remove Core Authorizations
        DssExecLib.deauthorize(address(vat), MCD_JOIN_DIRECT_AAVEV2_DAI);
        DssExecLib.deauthorize(address(vat), MCD_CLIP_DIRECT_AAVEV2_DAI);
        DssExecLib.deauthorize(DOG,          MCD_CLIP_DIRECT_AAVEV2_DAI);

        // Ensure governance can't interact with unused modules
        // NOTE: This is potentially dangerous, only use if you're sure we never need
        // the auth again in the future
        DssExecLib.deauthorize(MCD_JOIN_DIRECT_AAVEV2_DAI,      address(this));
        DssExecLib.deauthorize(MCD_CLIP_DIRECT_AAVEV2_DAI,      address(this));
        DssExecLib.deauthorize(MCD_CLIP_CALC_DIRECT_AAVEV2_DAI, address(this));

        // Ensure governance can't call unused MOM
        D3MLegacyMomLike(DIRECT_MOM_LEGACY).setAuthority(address(0));
        D3MLegacyMomLike(DIRECT_MOM_LEGACY).setOwner(address(0));

        // Remove chainlog and ilk records
        chainlog.removeAddress("DIRECT_MOM_LEGACY");
        chainlog.removeAddress("MCD_JOIN_DIRECT_AAVEV2_DAI");
        chainlog.removeAddress("MCD_CLIP_DIRECT_AAVEV2_DAI");
        chainlog.removeAddress("MCD_CLIP_CALC_DIRECT_AAVEV2_DAI");

        RegistryLike_2(DssExecLib.reg()).remove("DIRECT-AAVEV2-DAI");

        // Flash Mint Module Upgrade Completion
        // https://forum.makerdao.com/t/flashmint-module-housekeeping-task-for-next-executive/19472

        // Sunset MCD_FLASH_LEGACY and reduce DC to 0
        DssExecLib.setValue(MCD_FLASH_LEGACY, "max", 0);
        DssExecLib.deauthorize(address(vat), MCD_FLASH_LEGACY);
        DssExecLib.deauthorize(MCD_FLASH_LEGACY, FLASH_KILLER);
        DssExecLib.deauthorize(MCD_FLASH_LEGACY, DssExecLib.esm());
        DssExecLib.deauthorize(MCD_FLASH_LEGACY, address(this));
        chainlog.removeAddress("MCD_FLASH_LEGACY");

        // Increase DC of MCD_FLASH to 500 million DAI
        DssExecLib.setValue(MCD_FLASH, "max", 500 * MILLION * WAD);

        // Deauth FLASH_KILLER and remove from Chainlog
        // NOTE: Flash Killer's only ward is MCD_FLASH_LEGACY, Pause Proxy cannot deauth
        chainlog.removeAddress("FLASH_KILLER");


        // PSM_GUSD_A tout decrease
        // Poll: https://vote.makerdao.com/polling/QmRRceEo
        // Forum: https://forum.makerdao.com/t/request-to-poll-psm-gusd-a-parameters/19416
        // Reduce PSM-GUSD-A tout from 0.1% to 0%
        DssExecLib.setValue(MCD_PSM_GUSD_A, "tout", 0);


        DssExecLib.setChangelogVersion("1.14.8");
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) {}
}