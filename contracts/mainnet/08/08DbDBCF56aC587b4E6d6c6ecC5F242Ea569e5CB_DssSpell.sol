/**
 *Submitted for verification at Etherscan.io on 2022-12-02
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
    function wdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {}
    function rdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {}
    function dai()        public view returns (address) { return getChangelogAddress("MCD_DAI"); }
    function mkr()        public view returns (address) { return getChangelogAddress("MCD_GOV"); }
    function vat()        public view returns (address) { return getChangelogAddress("MCD_VAT"); }
    function cat()        public view returns (address) { return getChangelogAddress("MCD_CAT"); }
    function dog()        public view returns (address) { return getChangelogAddress("MCD_DOG"); }
    function jug()        public view returns (address) { return getChangelogAddress("MCD_JUG"); }
    function pot()        public view returns (address) { return getChangelogAddress("MCD_POT"); }
    function vow()        public view returns (address) { return getChangelogAddress("MCD_VOW"); }
    function end()        public view returns (address) { return getChangelogAddress("MCD_END"); }
    function reg()        public view returns (address) { return getChangelogAddress("ILK_REGISTRY"); }
    function spotter()    public view returns (address) { return getChangelogAddress("MCD_SPOT"); }
    function clipperMom() public view returns (address) { return getChangelogAddress("CLIPPER_MOM"); }
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
    function setAuthority(address _base, address _authority) public {}
    function canCast(uint40 _ts, bool _officeHours) public pure returns (bool) {}
    function nextCastTime(uint40 _eta, uint40 _ts, bool _officeHours) public pure returns (uint256 castTime) {}
    function updateCollateralPrice(bytes32 _ilk) public {}
    function setContract(address _base, bytes32 _what, address _addr) public {}
    function setContract(address _base, bytes32 _ilk, bytes32 _what, address _addr) public {}
    function setValue(address _base, bytes32 _what, uint256 _amt) public {}
    function setValue(address _base, bytes32 _ilk, bytes32 _what, uint256 _amt) public {}
    function increaseGlobalDebtCeiling(uint256 _amount) public {}
    function increaseIlkDebtCeiling(bytes32 _ilk, uint256 _amount, bool _global) public {}
    function setIlkAutoLineParameters(bytes32 _ilk, uint256 _amount, uint256 _gap, uint256 _ttl) public {}
    function setIlkLiquidationPenalty(bytes32 _ilk, uint256 _pct_bps) public {}
    function setIlkMaxLiquidationAmount(bytes32 _ilk, uint256 _amount) public {}
    function setStartingPriceMultiplicativeFactor(bytes32 _ilk, uint256 _pct_bps) public {}
    function setAuctionTimeBeforeReset(bytes32 _ilk, uint256 _duration) public {}
    function setAuctionPermittedDrop(bytes32 _ilk, uint256 _pct_bps) public {}
    function setKeeperIncentivePercent(bytes32 _ilk, uint256 _pct_bps) public {}
    function setKeeperIncentiveFlatRate(bytes32 _ilk, uint256 _amount) public {}
    function setLinearDecrease(address _calc, uint256 _duration) public {}
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

////// lib/dss-interfaces/src/dss/JugAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/makerdao/dss/blob/master/src/jug.sol
interface JugAbstract {
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function ilks(bytes32) external view returns (uint256, uint256);
    function vat() external view returns (address);
    function vow() external view returns (address);
    function base() external view returns (address);
    function init(bytes32) external;
    function file(bytes32, bytes32, uint256) external;
    function file(bytes32, uint256) external;
    function file(bytes32, address) external;
    function drip(bytes32) external returns (uint256);
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

/* import { VatAbstract } from "dss-interfaces/dss/VatAbstract.sol"; */
/* import { JugAbstract } from "dss-interfaces/dss/JugAbstract.sol"; */
/* import { IlkRegistryAbstract } from "dss-interfaces/dss/IlkRegistryAbstract.sol"; */

interface D3MHubLike_1 {
    function vat() external view returns (address);
    function daiJoin() external view returns (address);
}

interface D3MCompoundPoolLike_1 {
    function hub() external view returns (address);
    function ilk() external view returns (bytes32);
    function vat() external view returns (address);
    function comptroller() external view returns (address);
    function comp() external view returns (address);
    function dai() external view returns (address);
    function cDai() external view returns (address);
}

interface D3MCompoundPlanLike_1 {
    function tack() external view returns (address);
    function delegate() external view returns (address);
    function cDai() external view returns (address);
}

interface D3MOracleLike_1 {
    function vat() external view returns (address);
    function ilk() external view returns (bytes32);
}

interface CDaiLike {
    function interestRateModel() external view returns (address);
    function implementation() external view returns (address);
}

interface StarknetGovRelayLike_1 {
    function relay(uint256 spell) external;
}

interface OSMLike {
    function src() external view returns (address);
}

interface OracleLiftLike {
    function lift(address[] calldata) external;
}

interface TokenLike {
    function transfer(address, uint256) external returns (bool);
    function decimals() external view returns (uint8);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
}

contract DssSpellAction is DssAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/c94660aff7fa774aacb5c78ee7068ef4b5d9d243/governance/votes/Executive%20vote%20-%20December%202%2C%202022.md -q -O - 2>/dev/null)"

    string public constant override description =
        "2022-12-02 MakerDAO Executive Spell | Hash: 0xd2c190b0173eec16d7039cae64ce076e7abb18572af5d5a7fcb9b1b1c30bf170";

    uint256 constant internal RAY = 10 ** 27;
    uint256 constant internal MILLION = 10 ** 6;

    bytes32 constant internal ILK = "DIRECT-COMPV2-DAI";

    address constant internal D3M_HUB = 0x12F36cdEA3A28C35aC8C6Cc71D9265c17C74A27F;
    address constant internal D3M_MOM = 0x1AB3145E281c01a1597c8c62F9f060E8e3E02fAB;
    address immutable internal D3M_MOM_LEGACY = DssExecLib.getChangelogAddress("DIRECT_MOM");
    address constant internal D3M_COMPOUND_POOL = 0x621fE4Fde2617ea8FFadE08D0FF5A862aD287EC2;
    address constant internal D3M_COMPOUND_PLAN = 0xD0eA20f9f9e64A3582d569c8745DaCD746274AEe;
    address constant internal D3M_ORACLE = 0x0e2bf18273c953B54FE0a9dEC5429E67851D9468;
    address constant internal D3M_CDAI = 0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643;
    address constant internal D3M_COMPTROLLER = 0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B;
    address constant internal D3M_COMP = 0xc00e94Cb662C3520282E6f5717214004A7f26888;
    address constant internal D3M_TACK = 0xFB564da37B41b2F6B6EDcc3e56FbF523bD9F2012;
    address constant internal D3M_DELEGATE = 0x3363BAe2Fc44dA742Df13CD3ee94b6bB868ea376;

    // target 2% borrow apy, see top of D3MCompoundPlan for the formula explanation
    // ((2.00 / 100) + 1) ^ (1 / 365) - 1) / 7200) * 10^18
    uint256 constant internal D3M_COMP_BORROW_RATE = 7535450719;

    address constant internal MCD_CLIP_CALC_GUSD_A = 0xC287E4e9017259f3b21C86A0Ef7840243eC3f4d6;
    address constant internal MCD_CLIP_CALC_USDC_A = 0x00A0F90666c6Cd3E615cF8459A47e89A08817602;
    address constant internal MCD_CLIP_CALC_PAXUSD_A = 0xA2a4aeFEd398661B0a873d3782DA121c194a0201;

    address constant internal RETH_ORACLE = 0xF86360f0127f8A441Cfca332c75992D1C692b3D1;
    address constant internal RETH_LIGHTFEED = 0xa580BBCB1Cee2BCec4De2Ea870D20a12A964819e;

    address immutable internal STARKNET_GOV_RELAY = DssExecLib.getChangelogAddress("STARKNET_GOV_RELAY");
    address constant internal NEW_STARKNET_GOV_RELAY = 0x2385C60D2756Ed8CA001817fC37FDa216d7466c0;
    uint256 constant internal L2_GOV_RELAY_SPELL = 0x013c117c7bdb9dbbb45813fd6de8e301bbceed2cfad7c4c589cafa4478104672;

    address constant internal DUX_WALLET = 0x5A994D8428CCEbCC153863CCdA9D2Be6352f89ad;

    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    // A table of rates can be found at
    //    https://ipfs.io/ipfs/QmVp4mhhbwWGTfbh2BzwQB9eiBrQBKiqcPRZCaAxNUaar6
    //

    function actions() public override {
        // ----------------- Compound v2 D3M Onboarding -----------------
        // https://vote.makerdao.com/polling/QmWYfgY2#poll-detail
        {
            VatAbstract vat = VatAbstract(DssExecLib.vat());
            address spot = DssExecLib.spotter();

            // Sanity checks
            require(D3MHubLike_1(D3M_HUB).vat() == address(vat), "Hub vat mismatch");
            require(D3MHubLike_1(D3M_HUB).daiJoin() == DssExecLib.daiJoin(), "Hub daiJoin mismatch");

            require(D3MCompoundPoolLike_1(D3M_COMPOUND_POOL).hub() == D3M_HUB, "Pool hub mismatch");
            require(D3MCompoundPoolLike_1(D3M_COMPOUND_POOL).ilk() == ILK, "Pool ilk mismatch");
            require(D3MCompoundPoolLike_1(D3M_COMPOUND_POOL).vat() == address(vat), "Pool vat mismatch");
            require(D3MCompoundPoolLike_1(D3M_COMPOUND_POOL).comptroller() == D3M_COMPTROLLER, "Pool comptroller mismatch");
            require(D3MCompoundPoolLike_1(D3M_COMPOUND_POOL).comp() == D3M_COMP, "Pool comp mismatch");
            require(D3MCompoundPoolLike_1(D3M_COMPOUND_POOL).dai() == DssExecLib.dai(), "Pool dai mismatch");
            require(D3MCompoundPoolLike_1(D3M_COMPOUND_POOL).cDai() == D3M_CDAI, "Pool cDai mismatch");

            require(D3MCompoundPlanLike_1(D3M_COMPOUND_PLAN).tack() == D3M_TACK, "Plan tack mismatch");
            require(CDaiLike(D3M_CDAI).interestRateModel() == D3M_TACK, "Plan tack mismatch");
            require(D3MCompoundPlanLike_1(D3M_COMPOUND_PLAN).delegate() == D3M_DELEGATE, "Plan delegate mismatch");
            require(CDaiLike(D3M_CDAI).implementation() == D3M_DELEGATE, "Plan delegate mismatch");
            require(D3MCompoundPlanLike_1(D3M_COMPOUND_PLAN).cDai() == D3M_CDAI, "Plan cDai mismatch");

            require(D3MOracleLike_1(D3M_ORACLE).vat() == address(vat), "Oracle vat mismatch");
            require(D3MOracleLike_1(D3M_ORACLE).ilk() == ILK, "Oracle ilk mismatch");

            DssExecLib.setContract(D3M_HUB, ILK, "pool", D3M_COMPOUND_POOL);
            DssExecLib.setContract(D3M_HUB, ILK, "plan", D3M_COMPOUND_PLAN);
            DssExecLib.setValue(D3M_HUB, ILK, "tau", 7 days);
            DssExecLib.setContract(D3M_HUB, "vow", DssExecLib.vow());
            DssExecLib.setContract(D3M_HUB, "end", DssExecLib.end());

            DssExecLib.setAuthority(D3M_MOM, DssExecLib.getChangelogAddress("MCD_ADM"));

            DssExecLib.setContract(D3M_COMPOUND_POOL, "king", address(this));

            DssExecLib.authorize(D3M_COMPOUND_PLAN, D3M_MOM);
            DssExecLib.setValue(D3M_COMPOUND_PLAN, "barb", D3M_COMP_BORROW_RATE);

            DssExecLib.setContract(D3M_ORACLE, "hub", D3M_HUB);

            DssExecLib.setContract(spot, ILK, "pip", D3M_ORACLE);
            DssExecLib.setValue(spot, ILK, "mat", RAY);
            DssExecLib.authorize(address(vat), D3M_HUB);
            vat.init(ILK);
            JugAbstract(DssExecLib.jug()).init(ILK);
            DssExecLib.increaseIlkDebtCeiling(ILK, 5 * MILLION, true);
            DssExecLib.setIlkAutoLineParameters(ILK, 5 * MILLION, 5 * MILLION, 12 hours);
            DssExecLib.updateCollateralPrice(ILK);

            // Add to ilk registry
            IlkRegistryAbstract(DssExecLib.reg()).put(
                ILK,
                D3M_HUB,
                D3M_CDAI,
                TokenLike(D3M_CDAI).decimals(),
                4,
                D3M_ORACLE,
                address(0),
                TokenLike(D3M_CDAI).name(),
                TokenLike(D3M_CDAI).symbol()
            );
        }

        // ----------------- Activate Liquidations for GUSD-A, USDC-A and USDP-A -----------------
        // Poll: https://vote.makerdao.com/polling/QmZbsHqu#poll-detail
        // Forum: https://forum.makerdao.com/t/usdc-a-usdp-a-gusd-a-liquidation-parameters-auctions-activation/18744
        {
            bytes32 _ilk  = bytes32("GUSD-A");
            address _clip = DssExecLib.getChangelogAddress("MCD_CLIP_GUSD_A");
            //
            // Enable liquidations for GUSD-A
            // Note: ClipperMom cannot circuit-break on a DS-Value but we're adding
            //       the rely for consistency with other collaterals and in case the PIP
            //       changes to an OSM.
            DssExecLib.authorize(_clip, DssExecLib.clipperMom());
            DssExecLib.setValue(_clip, "stopped", 0);
            // Use Abacus/LinearDecrease
            DssExecLib.setContract(_clip, "calc", MCD_CLIP_CALC_GUSD_A);
            // Set Liquidation Penalty to 0
            DssExecLib.setIlkLiquidationPenalty(_ilk, 0);
            // Set Auction Price Multiplier (buf) to 1
            DssExecLib.setStartingPriceMultiplicativeFactor(_ilk, 100_00);
            // Set Local Liquidation Limit (ilk.hole) to 300k DAI
            DssExecLib.setIlkMaxLiquidationAmount(_ilk, 300_000);
            // Set tau for Abacus/LinearDecrease to 4,320,000 second
            DssExecLib.setLinearDecrease(MCD_CLIP_CALC_GUSD_A, 4_320_000);
            // Set Max Auction Duration (tail) to 43,200 seconds
            DssExecLib.setAuctionTimeBeforeReset(_ilk, 43_200);
            // Set Max Auction Drawdown / Permitted Drop (cusp) to 0.99
            DssExecLib.setAuctionPermittedDrop(_ilk, 99_00);
            // Set Proportional Kick Incentive (chip) to 0
            DssExecLib.setKeeperIncentivePercent(_ilk, 0);
            // Set Flat Kick Incentive (tip) to 0
            DssExecLib.setKeeperIncentiveFlatRate(_ilk, 0);
        }
        {
            bytes32 _ilk  = bytes32("USDC-A");
            address _clip = DssExecLib.getChangelogAddress("MCD_CLIP_USDC_A");
            //
            // Enable liquidations for USDC-A
            // Note: ClipperMom cannot circuit-break on a DS-Value but we're adding
            //       the rely for consistency with other collaterals and in case the PIP
            //       changes to an OSM.
            DssExecLib.authorize(_clip, DssExecLib.clipperMom());
            DssExecLib.setValue(_clip, "stopped", 0);
            // Use Abacus/LinearDecrease
            DssExecLib.setContract(_clip, "calc", MCD_CLIP_CALC_USDC_A);
            // Set Liquidation Penalty to 0
            DssExecLib.setIlkLiquidationPenalty(_ilk, 0);
            // Set Auction Price Multiplier (buf) to 1
            DssExecLib.setStartingPriceMultiplicativeFactor(_ilk, 100_00);
            // Set Local Liquidation Limit (ilk.hole) to 20m DAI
            DssExecLib.setIlkMaxLiquidationAmount(_ilk, 20_000_000);
            // Set tau for Abacus/LinearDecrease to 4,320,000 second
            DssExecLib.setLinearDecrease(MCD_CLIP_CALC_USDC_A, 4_320_000);
            // Set Max Auction Duration (tail) to 43,200 seconds
            DssExecLib.setAuctionTimeBeforeReset(_ilk, 43_200);
            // Set Max Auction Drawdown / Permitted Drop (cusp) to 0.99
            DssExecLib.setAuctionPermittedDrop(_ilk, 99_00);
            // Set Proportional Kick Incentive (chip) to 0
            DssExecLib.setKeeperIncentivePercent(_ilk, 0);
            // Set Flat Kick Incentive (tip) to 0
            DssExecLib.setKeeperIncentiveFlatRate(_ilk, 0);
        }
        {
            bytes32 _ilk  = bytes32("PAXUSD-A");
            address _clip = DssExecLib.getChangelogAddress("MCD_CLIP_PAXUSD_A");
            //
            // Enable liquidations for PAXUSD-A
            // Note: ClipperMom cannot circuit-break on a DS-Value but we're adding
            //       the rely for consistency with other collaterals and in case the PIP
            //       changes to an OSM.
            DssExecLib.authorize(_clip, DssExecLib.clipperMom());
            DssExecLib.setValue(_clip, "stopped", 0);
            // Use Abacus/LinearDecrease
            DssExecLib.setContract(_clip, "calc", MCD_CLIP_CALC_PAXUSD_A);
            // Set Liquidation Penalty to 0
            DssExecLib.setIlkLiquidationPenalty(_ilk, 0);
            // Set Auction Price Multiplier (buf) to 1
            DssExecLib.setStartingPriceMultiplicativeFactor(_ilk, 100_00);
            // Set Local Liquidation Limit (ilk.hole) to 3m DAI
            DssExecLib.setIlkMaxLiquidationAmount(_ilk, 3_000_000);
            // Set tau for Abacus/LinearDecrease to 4,320,000 second
            DssExecLib.setLinearDecrease(MCD_CLIP_CALC_PAXUSD_A, 4_320_000);
            // Set Max Auction Duration (tail) to 43,200 seconds
            DssExecLib.setAuctionTimeBeforeReset(_ilk, 43_200);
            // Set Max Auction Drawdown / Permitted Drop (cusp) to 0.99
            DssExecLib.setAuctionPermittedDrop(_ilk, 99_00);
            // Set Proportional Kick Incentive (chip) to 0
            DssExecLib.setKeeperIncentivePercent(_ilk, 0);
            // Set Flat Kick Incentive (tip) to 0
            DssExecLib.setKeeperIncentiveFlatRate(_ilk, 0);
        }

        // ----------------- Whitelist Light Feed on Oracle for rETH -----------------
        // https://forum.makerdao.com/t/whitelist-light-feed-for-reth-oracle/18908
        require(OSMLike(DssExecLib.getChangelogAddress("PIP_RETH")).src() == RETH_ORACLE, "Bad oracle address");
        address[] memory lightFeeds = new address[](1);
        lightFeeds[0] = RETH_LIGHTFEED;
        OracleLiftLike(RETH_ORACLE).lift(lightFeeds);

        // ------------------ Setup new Starknet Governance Relay -----------------
        // Forum: https://forum.makerdao.com/t/starknet-changes-for-executive-spell-on-the-week-of-2022-11-29/18818
        // Relay l2 part of the spell
        // L2 Spell: https://voyager.online/contract/0x013c117c7bdb9dbbb45813fd6de8e301bbceed2cfad7c4c589cafa4478104672#code
        StarknetGovRelayLike_1(STARKNET_GOV_RELAY).relay(L2_GOV_RELAY_SPELL);

        // ----------------- MKR Transfer -----------------
        // https://mips.makerdao.com/mips/details/MIP40c3SP27#sentence-summary
        TokenLike(DssExecLib.mkr()).transfer(DUX_WALLET, 180.6 ether);

        // Configure Chainlog
        DssExecLib.setChangelogAddress("DIRECT_HUB", D3M_HUB);
        DssExecLib.setChangelogAddress("DIRECT_MOM", D3M_MOM);
        DssExecLib.setChangelogAddress("DIRECT_MOM_LEGACY", D3M_MOM_LEGACY);

        DssExecLib.setChangelogAddress("DIRECT_COMPV2_DAI_POOL", D3M_COMPOUND_POOL);
        DssExecLib.setChangelogAddress("DIRECT_COMPV2_DAI_PLAN", D3M_COMPOUND_PLAN);
        DssExecLib.setChangelogAddress("DIRECT_COMPV2_DAI_ORACLE", D3M_ORACLE);

        DssExecLib.setChangelogAddress("MCD_CLIP_CALC_GUSD_A", MCD_CLIP_CALC_GUSD_A);
        DssExecLib.setChangelogAddress("MCD_CLIP_CALC_USDC_A", MCD_CLIP_CALC_USDC_A);
        DssExecLib.setChangelogAddress("MCD_CLIP_CALC_PAXUSD_A", MCD_CLIP_CALC_PAXUSD_A);

        DssExecLib.setChangelogAddress("STARKNET_GOV_RELAY_LEGACY", STARKNET_GOV_RELAY);
        DssExecLib.setChangelogAddress("STARKNET_GOV_RELAY", NEW_STARKNET_GOV_RELAY);

        DssExecLib.setChangelogVersion("1.14.6");
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) public {}
}