/**
 *Submitted for verification at Etherscan.io on 2022-11-01
*/

// hevm: flattened sources of src/DssSpell.sol
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
    function dai()        public view returns (address) { return getChangelogAddress("MCD_DAI"); }
    function mkr()        public view returns (address) { return getChangelogAddress("MCD_GOV"); }
    function vat()        public view returns (address) { return getChangelogAddress("MCD_VAT"); }
    function vow()        public view returns (address) { return getChangelogAddress("MCD_VOW"); }
    function end()        public view returns (address) { return getChangelogAddress("MCD_END"); }
    function reg()        public view returns (address) { return getChangelogAddress("ILK_REGISTRY"); }
    function daiJoin()    public view returns (address) { return getChangelogAddress("MCD_JOIN_DAI"); }
    function lerpFab()    public view returns (address) { return getChangelogAddress("LERP_FAB"); }
    function clip(bytes32 _ilk) public view returns (address _clip) {}
    function flip(bytes32 _ilk) public view returns (address _flip) {}
    function calc(bytes32 _ilk) public view returns (address _calc) {}
    function getChangelogAddress(bytes32 _key) public view returns (address) {}
    function authorize(address _base, address _ward) public {}
    function deauthorize(address _base, address _ward) public {}
    function setAuthority(address _base, address _authority) public {}
    function canCast(uint40 _ts, bool _officeHours) public pure returns (bool) {}
    function nextCastTime(uint40 _eta, uint40 _ts, bool _officeHours) public pure returns (uint256 castTime) {}
    function addReaderToWhitelist(address _oracle, address _reader) public {}
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

////// src/DssSpellCollateral.sol
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
    // https://ipfs.io/ipfs/QmVp4mhhbwWGTfbh2BzwQB9eiBrQBKiqcPRZCaAxNUaar6
    //
    //uint256 internal constant ONE_FIVE_PCT_RATE = 1000000000472114805215157978;

    // --- Math ---
    //uint256 constant THOUSAND   = 10 ** 3;
    //uint256 constant MILLION    = 10 ** 6;
    //uint256 constant BILLION    = 10 ** 9;


    function collateralAction() internal {
        onboardCollaterals();
        updateCollaterals();
        offboardCollaterals();
    }

    function onboardCollaterals() internal {
        // ----------------------------- Collateral onboarding -----------------------------
        //  Add ______________ as a new Vault Type
        //  Poll Link:

        // DssExecLib.addNewCollateral(
        //     CollateralOpts({
        //         ilk:                   "XXX-A",
        //         gem:                   XXX,
        //         join:                  MCD_JOIN_XXX_A,
        //         clip:                  MCD_CLIP_XXX_A,
        //         calc:                  MCD_CLIP_CALC_XXX_A,
        //         pip:                   PIP_XXX,
        //         isLiquidatable:        BOOL,
        //         isOSM:                 BOOL,
        //         whitelistOSM:          BOOL,
        //         ilkDebtCeiling:        line,
        //         minVaultAmount:        dust,
        //         maxLiquidationAmount:  hole,
        //         liquidationPenalty:    chop,
        //         ilkStabilityFee:       duty,
        //         startingPriceFactor:   buf,
        //         breakerTolerance:      tolerance,
        //         auctionDuration:       tail,
        //         permittedDrop:         cusp,
        //         liquidationRatio:      mat,
        //         kprFlatReward:         tip,
        //         kprPctReward:          chip
        //     })
        // );

        // DssExecLib.setStairstepExponentialDecrease(
        //     CALC_ADDR,
        //     DURATION,
        //     PCT_BPS
        // );

        // DssExecLib.setIlkAutoLineParameters(
        //     "XXX-A",
        //     AMOUNT,
        //     GAP,
        //     TTL
        // );

        // ChainLog Updates
        // DssExecLib.setChangelogAddress("XXX", XXX);
        // DssExecLib.setChangelogAddress("PIP_XXX", PIP_XXX);
        // DssExecLib.setChangelogAddress("MCD_JOIN_XXX_A", MCD_JOIN_XXX_A);
        // DssExecLib.setChangelogAddress("MCD_CLIP_XXX_A", MCD_CLIP_XXX_A);
        // DssExecLib.setChangelogAddress("MCD_CLIP_CALC_XXX_A", MCD_CLIP_CALC_XXX_A);
    }

    function updateCollaterals() internal {
        // ------------------------------- Collateral updates -------------------------------

        // Enable autoline for XXX-A
        // Poll Link:
        // Forum Link:
        // DssExecLib.setIlkAutoLineParameters(
        //    XXX-A,
        //    AMOUNT,
        //    GAP,
        //    TTL
        // );
    }

    function offboardCollaterals() internal {
        // ----------------------------- Collateral offboarding -----------------------------
        // 1st Stage of Collateral Offboarding Process
        // Poll Link:
        // uint256 line;
        // uint256 lineReduction;

        // Set XXX-A Maximum Debt Ceiling to 0
        // (,,,line,) = vat.ilks("XXX-A");
        // lineReduction += line;
        // DssExecLib.removeIlkFromAutoLine("XXX-A");
        // DssExecLib.setIlkDebtCeiling("XXX-A", 0);

        // Set XXX-A Maximum Debt Ceiling to 0
        // (,,,line,) = vat.ilks("XXX-A");
        // lineReduction += line;
        // DssExecLib.removeIlkFromAutoLine("XXX-A");
        // DssExecLib.setIlkDebtCeiling("XXX-A", 0);

        // Decrease Global Debt Ceiling by total amount of offboarded ilks
        // vat.file("Line", _sub(vat.Line(), lineReduction));

        // 2nd Stage of Collateral Offboarding Process
        // address spotter = DssExecLib.spotter();

        // Offboard XXX-A
        // Poll Link:
        // Forum Link:

        // DssExecLib.setIlkLiquidationPenalty("XXX-A", 0);
        // DssExecLib.setKeeperIncentiveFlatRate("XXX-A", 0);
        // DssExecLib.linearInterpolation({
        //     _name:      "XXX-A Offboarding",
        //     _target:    spotter,
        //     _ilk:       "XXX-A",
        //     _what:      "mat",
        //     _startTime: block.timestamp,
        //     _start:     CURRENT_XXX_A_MAT,
        //     _end:       TARGET_XXX_A_MAT,
        //     _duration:  30 days
        // });

        // Offboard XXX-A
        // Poll Link:
        // Forum Link:

        // DssExecLib.setIlkLiquidationPenalty("XXX-A", 0);
        // DssExecLib.setKeeperIncentiveFlatRate("XXX-A", 0);
        // DssExecLib.linearInterpolation({
        //     _name:      "XXX-A Offboarding",
        //     _target:    spotter,
        //     _ilk:       "XXX-A",
        //     _what:      "mat",
        //     _startTime: block.timestamp,
        //     _start:     CURRENT_XXX_A_MAT,
        //     _end:       TARGET_XXX_A_MAT,
        //     _duration:  30 days
        // });
    }

    // --- Offboarding: Current Liquidation Ratio ---
    // uint256 constant CURRENT_XXX_A_MAT              =  XYZ * RAY / 100;

    // --- Offboarding: Target Liquidation Ratio ---
    // uint256 constant TARGET_XXX_A_MAT               =  XYZ * RAY / 100;

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

/* pragma solidity 0.6.12; */
// Enable ABIEncoderV2 when onboarding collateral through `DssExecLib.addNewCollateral()`
// // pragma experimental ABIEncoderV2;

/* import "dss-exec-lib/DssExec.sol"; */
/* import "dss-exec-lib/DssAction.sol"; */

/* import { DssSpellCollateralAction } from "./DssSpellCollateral.sol"; */

interface DssVestLike {
    function yank(uint256) external;
}

interface GemLike {
    function transfer(address, uint256) external returns (bool);
}

contract DssSpellAction is DssAction, DssSpellCollateralAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/59474706f0597f9feb331a2325928e343a4e3fef/governance/votes/Executive%20vote%20-%20November%202%2C%202022.md -q -O - 2>/dev/null)"

    string public constant override description =
        "2022-11-02 MakerDAO Executive Spell | Hash: 0x08cf79923a6aa3e9f67acd8d0bb650a17dd1cea99a6556bc505f3929af15923d";



    // Turn office hours off
    function officeHours() public override returns (bool) {
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

    // --- Rates ---
    // uint256 internal constant ONE_FIVE_PCT_RATE = 1000000000472114805215157978;

    // --- Math ---
    // uint256 internal constant WAD = 10 ** 18;

    address constant EVENTS_001 = 0x3D274fbAc29C92D2F624483495C0113B44dBE7d2;
    address constant SH_001     = 0xc657aC882Fb2D6CcF521801da39e910F8519508d;
    address constant RWF_001    = 0x96d7b01Cc25B141520C717fa369844d34FF116ec;
    address constant BLOCKTOWER = 0x117786ad59BC2f13cf25B2359eAa521acB0aDCD9;
    address constant OASISAPP   = 0x55Dc2Be8020bCa72E58e665dC931E03B749ea5E0;

    DssVestLike immutable MCD_VEST_DAI          = DssVestLike(DssExecLib.getChangelogAddress("MCD_VEST_DAI"));
    DssVestLike immutable MCD_VEST_DAI_LEGACY   = DssVestLike(DssExecLib.getChangelogAddress("MCD_VEST_DAI_LEGACY"));
    DssVestLike immutable MCD_VEST_MKR_TREASURY = DssVestLike(DssExecLib.getChangelogAddress("MCD_VEST_MKR_TREASURY"));
    GemLike     immutable MKR                   = GemLike(DssExecLib.mkr());
    address     immutable PIP_RETH              = DssExecLib.getChangelogAddress("PIP_RETH");
    address     immutable STARKNET_DAI_BRIDGE   = DssExecLib.getChangelogAddress("STARKNET_DAI_BRIDGE");
    address     immutable STARKNET_ESCROW_MOM   = DssExecLib.getChangelogAddress("STARKNET_ESCROW_MOM");

    function actions() public override {


        // Includes changes from the DssSpellCollateralAction
        // collateralAction();


        // CU Offboarding - Yank DAI Streams
        // https://forum.makerdao.com/t/executive-vote-cu-offboarding-next-steps/18522

        // Yank DAI Stream #4 (EVENTS-001)
        // https://mips.makerdao.com/mips/details/MIP39c3SP4#sentence-summary
        MCD_VEST_DAI.yank(4);

        // Yank DAI Stream #5 (SH-001)
        // https://mips.makerdao.com/mips/details/MIP39c3SP3#sentence-summary
        MCD_VEST_DAI.yank(5);

        // Yank DAI Stream #35 (RWF-001)
        // https://mips.makerdao.com/mips/details/MIP39c3SP5#sentence-summary
        MCD_VEST_DAI_LEGACY.yank(35);


        // CU Offboarding - Yank MKR Stream

        // Yank MKR Stream #23 (SH-001)
        // https://mips.makerdao.com/mips/details/MIP39c3SP3#sentence-summary
        MCD_VEST_MKR_TREASURY.yank(23);


        // CU Offboarding - DAI Golden Parachutes

        // EVENTS-001 - 167,666 DAI - 0x3D274fbAc29C92D2F624483495C0113B44dBE7d2
        // https://mips.makerdao.com/mips/details/MIP39c3SP4#sentence-summary
        DssExecLib.sendPaymentFromSurplusBuffer(EVENTS_001, 167_666);

        // SH-001 - 43,332.0 DAI - 0xc657aC882Fb2D6CcF521801da39e910F8519508d
        // https://mips.makerdao.com/mips/details/MIP39c3SP3#sentence-summary
        DssExecLib.sendPaymentFromSurplusBuffer(SH_001, 43_332);


        // CU Offboarding - MKR Golden Parachutes
        // https://forum.makerdao.com/t/executive-vote-cu-offboarding-next-steps/18522

        // SH-001 - 26.04 MKR - 0xc657aC882Fb2D6CcF521801da39e910F8519508d
        // https://mips.makerdao.com/mips/details/MIP39c3SP3#sentence-summary
        MKR.transfer(SH_001, 26.04 ether);  // note: ether is a keyword helper, only MKR is transferred here

        // RWF-001 - 143.46 MKR - 0x96d7b01Cc25B141520C717fa369844d34FF116ec
        // https://mips.makerdao.com/mips/details/MIP39c3SP5#sentence-summary
        MKR.transfer(RWF_001, 143.46 ether);  // note: ether is a keyword helper, only MKR is transferred here

        // SPF Funding

        // BlockTower Legal and Risk Work SPF - 258,000 DAI - 0x117786ad59BC2f13cf25B2359eAa521acB0aDCD9
        // https://mips.makerdao.com/mips/details/MIP55c3SP9#sentence-summary
        // https://vote.makerdao.com/polling/QmcV2pMZ#vote-breakdown
        DssExecLib.sendPaymentFromSurplusBuffer(BLOCKTOWER, 258_000);


        // Oracle Whitelisting
        // https://vote.makerdao.com/polling/QmZzFPFs#vote-breakdown

        // Whitelist Oasis.app on RETH/USD oracle
        // https://forum.makerdao.com/t/mip10c9-sp31-proposal-to-whitelist-oasis-app-on-rethusd-oracle/18195
        // Oasis.app - 0x55Dc2Be8020bCa72E58e665dC931E03B749ea5E0 - OSM
        DssExecLib.addReaderToWhitelist(PIP_RETH, OASISAPP);


        // PE Housekeeping

        // Clean up unnecessary ESCROW_MOM auth on Starknet Bridge
        DssExecLib.deauthorize(STARKNET_DAI_BRIDGE, STARKNET_ESCROW_MOM);
    }
}

contract DssSpell is DssExec {

    string public constant in_memory_of = "Nikolai Mushegian";

    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) public {}
}