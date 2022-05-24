/**
 *Submitted for verification at Etherscan.io on 2022-05-24
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
    function mkr()        public view returns (address) { return getChangelogAddress("MCD_GOV"); }
    function end()        public view returns (address) { return getChangelogAddress("MCD_END"); }
    function esm()        public view returns (address) { return getChangelogAddress("MCD_ESM"); }
    function reg()        public view returns (address) { return getChangelogAddress("ILK_REGISTRY"); }
    function flap()       public view returns (address) { return getChangelogAddress("MCD_FLAP"); }
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

////// lib/dss-interfaces/src/dapp/DSTokenAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/dapphub/ds-token/blob/master/src/token.sol
interface DSTokenAbstract {
    function name() external view returns (bytes32);
    function symbol() external view returns (bytes32);
    function decimals() external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function transfer(address, uint256) external returns (bool);
    function allowance(address, address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function approve(address) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
    function push(address, uint256) external;
    function pull(address, uint256) external;
    function move(address, address, uint256) external;
    function mint(uint256) external;
    function mint(address,uint) external;
    function burn(uint256) external;
    function burn(address,uint) external;
    function setName(bytes32) external;
    function authority() external view returns (address);
    function owner() external view returns (address);
    function setOwner(address) external;
    function setAuthority(address) external;
}

////// lib/dss-interfaces/src/dss/EndAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/makerdao/dss/blob/master/src/end.sol
interface EndAbstract {
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function vat() external view returns (address);
    function cat() external view returns (address);
    function dog() external view returns (address);
    function vow() external view returns (address);
    function pot() external view returns (address);
    function spot() external view returns (address);
    function live() external view returns (uint256);
    function when() external view returns (uint256);
    function wait() external view returns (uint256);
    function debt() external view returns (uint256);
    function tag(bytes32) external view returns (uint256);
    function gap(bytes32) external view returns (uint256);
    function Art(bytes32) external view returns (uint256);
    function fix(bytes32) external view returns (uint256);
    function bag(address) external view returns (uint256);
    function out(bytes32, address) external view returns (uint256);
    function WAD() external view returns (uint256);
    function RAY() external view returns (uint256);
    function file(bytes32, address) external;
    function file(bytes32, uint256) external;
    function cage() external;
    function cage(bytes32) external;
    function skip(bytes32, uint256) external;
    function snip(bytes32, uint256) external;
    function skim(bytes32, address) external;
    function free(bytes32) external;
    function thaw() external;
    function flow(bytes32) external;
    function pack(uint256) external;
    function cash(bytes32, uint256) external;
}

////// lib/dss-interfaces/src/dss/FlashAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/makerdao/dss-flash/blob/master/src/flash.sol
interface FlashAbstract {
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function vat() external view returns (address);
    function daiJoin() external view returns (address);
    function dai() external view returns (address);
    function vow() external view returns (address);
    function max() external view returns (uint256);
    function toll() external view returns (uint256);
    function CALLBACK_SUCCESS() external view returns (bytes32);
    function CALLBACK_SUCCESS_VAT_DAI() external view returns (bytes32);
    function file(bytes32, uint256) external;
    function maxFlashLoan(address) external view returns (uint256);
    function flashFee(address, uint256) external view returns (uint256);
    function flashLoan(address, address, uint256, bytes calldata) external returns (bool);
    function vatDaiFlashLoan(address, uint256, bytes calldata) external returns (bool);
    function convert() external;
    function accrue() external;
}

////// lib/dss-interfaces/src/dss/IlkRegistryAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/makerdao/ilk-registry
interface IlkRegistryAbstract {
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function vat() external view returns (address);
    function dog() external view returns (address);
    function cat() external view returns (address);
    function spot() external view returns (address);
    function ilkData(bytes32) external view returns (
        uint96, address, address, uint8, uint96, address, address, string memory, string memory
    );
    function ilks() external view returns (bytes32[] memory);
    function ilks(uint) external view returns (bytes32);
    function add(address) external;
    function remove(bytes32) external;
    function update(bytes32) external;
    function removeAuth(bytes32) external;
    function file(bytes32, address) external;
    function file(bytes32, bytes32, address) external;
    function file(bytes32, bytes32, uint256) external;
    function file(bytes32, bytes32, string calldata) external;
    function count() external view returns (uint256);
    function list() external view returns (bytes32[] memory);
    function list(uint256, uint256) external view returns (bytes32[] memory);
    function get(uint256) external view returns (bytes32);
    function info(bytes32) external view returns (
        string memory, string memory, uint256, uint256, address, address, address, address
    );
    function pos(bytes32) external view returns (uint256);
    function class(bytes32) external view returns (uint256);
    function gem(bytes32) external view returns (address);
    function pip(bytes32) external view returns (address);
    function join(bytes32) external view returns (address);
    function xlip(bytes32) external view returns (address);
    function dec(bytes32) external view returns (uint256);
    function symbol(bytes32) external view returns (string memory);
    function name(bytes32) external view returns (string memory);
    function put(bytes32, address, address, uint256, uint256, address, address, string calldata, string calldata) external;
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
    //    https://ipfs.io/ipfs/QmPgPVrVxDCGyNR5rGp9JC5AUxppLzUAqvncRJDcxQnX1u
    //
    // uint256 constant NUMBER_PCT = 1000000001234567890123456789;

    // --- Math ---
    // uint256 constant THOUSAND   = 10 ** 3;
    // uint256 constant MILLION    = 10 ** 6;
    // uint256 constant BILLION    = 10 ** 9;

    // --- DEPLOYED COLLATERAL ADDRESSES ---
    // address constant XXX                  = 0x0000000000000000000000000000000000000000;
    // address constant PIP_XXX              = 0x0000000000000000000000000000000000000000;
    // address constant MCD_JOIN_XXX_A       = 0x0000000000000000000000000000000000000000;
    // address constant MCD_CLIP_XXX_A       = 0x0000000000000000000000000000000000000000;
    // address constant MCD_CLIP_CALC_XXX_A  = 0x0000000000000000000000000000000000000000;

    function onboardNewCollaterals() internal {
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
// // pragma experimental ABIEncoderV2;
/* import "dss-exec-lib/DssExec.sol"; */
/* import "dss-exec-lib/DssAction.sol"; */

/* import { DssSpellCollateralOnboardingAction } from "./DssSpellCollateralOnboarding.sol"; */

/* import "dss-interfaces/dss/EndAbstract.sol"; */
/* import "dss-interfaces/dss/IlkRegistryAbstract.sol"; */
/* import "dss-interfaces/dss/FlashAbstract.sol"; */
/* import "dss-interfaces/dapp/DSTokenAbstract.sol"; */

contract DssSpellAction is DssAction, DssSpellCollateralOnboardingAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/45d2525f0b3f57a3e102fbd7034d1d912dea921a/governance/votes/Executive%20vote%20-%20May%2025%2C%202022.md -q -O - 2>/dev/null)"

    string public constant override description =
        "2022-05-25 MakerDAO Executive Spell | Hash: 0x308785a5c5d12cf03a48ce076a72b12ac887590da1b84ef68e4272a2d026ed9c";

    // Math
    uint256 constant WAD = 10 ** 18;
    uint256 constant RAD = 10 ** 45;

    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    // A table of rates can be found at
    //    https://ipfs.io/ipfs/QmPgPVrVxDCGyNR5rGp9JC5AUxppLzUAqvncRJDcxQnX1u
    //

    // Turn office hours off
    function officeHours() public override returns (bool) {
        return false;
    }

    address immutable MCD_FLAP = DssExecLib.flap();
    address immutable MCD_ESM  = DssExecLib.esm();
    address immutable MCD_GOV  = DssExecLib.mkr();

    address immutable SIDESTREAM_WALLET = 0xb1f950a51516a697E103aaa69E152d839182f6Fe;
    address immutable DUX_WALLET =        0x5A994D8428CCEbCC153863CCdA9D2Be6352f89ad;

    function actions() public override {
        // ---------------------------------------------------------------------
        // Includes changes from the DssSpellCollateralOnboardingAction
        // onboardNewCollaterals();

        // ---------------------------- Lid for Flap ---------------------------
        // https://vote.makerdao.com/polling/QmREdTJK
        DssExecLib.setValue(MCD_FLAP, "lid", 30_000 * RAD);

        // ------------------------------ ESM Min ------------------------------
        // https://vote.makerdao.com/polling/QmQgab4a
        DssExecLib.setValue(MCD_ESM, "min", 150_000 * WAD);

        // ---------------------------- Transfer MKR ---------------------------
        // https://vote.makerdao.com/polling/QmPnAkS4
        DSTokenAbstract(MCD_GOV).transfer(SIDESTREAM_WALLET, 243.7953 ether);

        // Original Proposal: https://forum.makerdao.com/t/mip40c3-sp27-development-ux-core-unit-mkr-budget-dux-001/9777
        // Adjusted Amounts in Monthly Report:
        // Apr 2022: https://github.com/makerdao-dux/transparency-reporting/blob/main/Monthy%20Budget%20Statements/2022-04.md#3-mkr-vesting-overview
        DSTokenAbstract(MCD_GOV).transfer(DUX_WALLET, 355.86 ether);

    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) public {}
}