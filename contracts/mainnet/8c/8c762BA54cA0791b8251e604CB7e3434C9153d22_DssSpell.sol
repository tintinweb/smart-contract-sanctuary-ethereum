/**
 *Submitted for verification at Etherscan.io on 2022-12-09
*/

// hevm: flattened sources of src/DssSpell.sol
// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity =0.6.12 >=0.6.12 <0.7.0;
pragma experimental ABIEncoderV2;

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
/* pragma experimental ABIEncoderV2; */

/* import { CollateralOpts } from "./CollateralOpts.sol"; */

interface Initializable_1 {
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
    function esm()        public view returns (address) { return getChangelogAddress("MCD_ESM"); }
    function reg()        public view returns (address) { return getChangelogAddress("ILK_REGISTRY"); }
    function spotter()    public view returns (address) { return getChangelogAddress("MCD_SPOT"); }
    function osmMom()     public view returns (address) { return getChangelogAddress("OSM_MOM"); }
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
    function deauthorize(address _base, address _ward) public {}
    function setAuthority(address _base, address _authority) public {}
    function canCast(uint40 _ts, bool _officeHours) public pure returns (bool) {}
    function nextCastTime(uint40 _eta, uint40 _ts, bool _officeHours) public pure returns (uint256 castTime) {}
    function updateCollateralPrice(bytes32 _ilk) public {}
    function setContract(address _base, bytes32 _what, address _addr) public {}
    function setContract(address _base, bytes32 _ilk, bytes32 _what, address _addr) public {}
    function setValue(address _base, bytes32 _what, uint256 _amt) public {}
    function setValue(address _base, bytes32 _ilk, bytes32 _what, uint256 _amt) public {}
    function increaseGlobalDebtCeiling(uint256 _amount) public {}
    function setDSR(uint256 _rate, bool _doDrip) public {}
    function setIlkDebtCeiling(bytes32 _ilk, uint256 _amount) public {}
    function increaseIlkDebtCeiling(bytes32 _ilk, uint256 _amount, bool _global) public {}
    function setIlkAutoLineParameters(bytes32 _ilk, uint256 _amount, uint256 _gap, uint256 _ttl) public {}
    function setIlkAutoLineDebtCeiling(bytes32 _ilk, uint256 _amount) public {}
    function removeIlkFromAutoLine(bytes32 _ilk) public {}
    function setIlkMinVaultAmount(bytes32 _ilk, uint256 _amount) public {}
    function setIlkLiquidationPenalty(bytes32 _ilk, uint256 _pct_bps) public {}
    function setIlkMaxLiquidationAmount(bytes32 _ilk, uint256 _amount) public {}
    function setIlkLiquidationRatio(bytes32 _ilk, uint256 _pct_bps) public {}
    function setStartingPriceMultiplicativeFactor(bytes32 _ilk, uint256 _pct_bps) public {}
    function setAuctionTimeBeforeReset(bytes32 _ilk, uint256 _duration) public {}
    function setAuctionPermittedDrop(bytes32 _ilk, uint256 _pct_bps) public {}
    function setKeeperIncentivePercent(bytes32 _ilk, uint256 _pct_bps) public {}
    function setKeeperIncentiveFlatRate(bytes32 _ilk, uint256 _amount) public {}
    function setLiquidationBreakerPriceTolerance(address _clip, uint256 _pct_bps) public {}
    function setIlkStabilityFee(bytes32 _ilk, uint256 _rate, bool _doDrip) public {}
    function setStairstepExponentialDecrease(address _calc, uint256 _duration, uint256 _pct_bps) public {}
    function whitelistOracleMedians(address _oracle) public {}
    function addReaderToWhitelist(address _oracle, address _reader) public {}
    function addReaderToWhitelistCall(address _oracle, address _reader) public {}
    function allowOSMFreeze(address _osm, bytes32 _ilk) public {}
    function addCollateralBase(
        bytes32 _ilk,
        address _gem,
        address _join,
        address _clip,
        address _calc,
        address _pip
    ) public {}
    function addNewCollateral(CollateralOpts memory co) public {}
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
/* pragma experimental ABIEncoderV2; */

/* import "dss-exec-lib/DssExec.sol"; */
/* import "dss-exec-lib/DssAction.sol"; */

interface GemLike {
    function allowance(address, address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
    function decimals() external view returns (uint8);
}

interface VatLike {
    function ilks(bytes32) external view returns (uint256, uint256, uint256, uint256, uint256);
    function Line() external view returns (uint256);
}

interface Initializable_2 {
    function init(bytes32) external;
}

interface GemJoinLike {
    function rely(address) external;
    function vat() external view returns (address);
    function ilk() external view returns (bytes32);
    function gem() external view returns (address);
    function dec() external view returns (uint256);
}

interface IlkRegistryLike {
    function put(bytes32, address, address, uint256, uint256, address, address, string calldata, string calldata) external;
}

interface RwaLiquidationLike_1 {
    function ilks(bytes32) external returns (string memory,address,uint48,uint48);
    function init(bytes32, uint256, string calldata, uint48) external;
}

interface RwaUrnLike_1 {
    function daiJoin() external view returns(address);
    function gemJoin() external view returns(address);
    function hope(address) external;
    function jug() external view returns(address);
    function outputConduit() external view returns(address);
    function vat() external view returns(address);
}

interface TinlakeManagerLike_1 {
    function file(bytes32, address) external;
    function dai() external view returns (address);
    function daiJoin() external view returns (address);
    function end() external view returns (address);
    function liq() external view returns (address);
    function lock(uint256) external;
    function owner() external view returns (address);
    function pool() external view returns (address);
    function tranche() external view returns (address);
    function urn() external view returns (address);
    function vat() external view returns (address);
    function vow() external view returns (address);
    function gem() external view returns (address);
}

interface StarknetLike {
    function setCeiling(uint256) external;
    function setMaxDeposit(uint256) external;
}

struct CentrifugeCollateralValues {
    // MIP21 addresses
    address GEM_JOIN;
    address GEM;
    address OPERATOR;       // MGR
    address INPUT_CONDUIT;  // MGR
    address OUTPUT_CONDUIT; // MGR
    address URN;

    // Centrifuge addresses
    address DROP;
    address OWNER;
    address POOL;
    address TRANCHE;
    address ROOT;

    // Changelog keys
    bytes32 gemID;
    bytes32 joinID;
    bytes32 urnID;
    bytes32 inputConduitID;
    bytes32 outputConduitID;
    bytes32 pipID;

    // Misc
    bytes32 ilk;
    string  ilkString;
    string  ilkRegistryName;
    uint256 RATE;
    uint256 CEIL;
    uint256 PRICE;
    uint256 MAT;
    uint48  TAU;
    string  DOC;
}

contract DssSpellAction is DssAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/8ef80506bda5a3115105ec227733e68b4a63430d/governance/votes/Executive%20Vote%20-%20December%209%2C%202022.md -q -O - 2>/dev/null)"
    string public constant override description =
        "2022-12-09 MakerDAO Executive Spell | Hash: 0xc1363d6a233492ab13d88e8bb9d9cab0033439f0817e152f0b3a4218989983ef";


    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    // A table of rates can be found at
    //    https://ipfs.io/ipfs/QmVp4mhhbwWGTfbh2BzwQB9eiBrQBKiqcPRZCaAxNUaar6
    //
    uint256 internal constant ONE_PCT_RATE      = 1000000000315522921573372069;
    uint256 internal constant TWO_FIVE_PCT_RATE = 1000000000782997609082909351;
    uint256 internal constant FOUR_PCT_RATE     = 1000000001243680656318820312;

    // --- MATH ---
    uint256 internal constant MILLION = 10 ** 6;
    uint256 internal constant WAD     = 10 ** 18;
    uint256 internal constant RAY     = 10 ** 27;

    uint256 internal constant PSM_TEN_BASIS_POINTS = 10 * WAD / 10000;

    function _sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }

    // --- Ilk Registry ---
    uint256 internal constant REG_RWA_CLASS = 3;

    address internal immutable VAT                    = DssExecLib.vat();
    address internal immutable MCD_PSM_PAX_A          = DssExecLib.getChangelogAddress("MCD_PSM_PAX_A");
    address internal immutable MCD_PSM_GUSD_A         = DssExecLib.getChangelogAddress("MCD_PSM_GUSD_A");
    address internal immutable STARKNET_DAI_BRIDGE    = DssExecLib.getChangelogAddress("STARKNET_DAI_BRIDGE");
    address internal immutable DAI                    = DssExecLib.dai();
    address internal immutable DAI_JOIN               = DssExecLib.daiJoin();
    address internal immutable END                    = DssExecLib.end();
    address internal immutable JUG                    = DssExecLib.jug();
    address internal immutable SPOTTER                = DssExecLib.spotter();
    address internal immutable VOW                    = DssExecLib.vow();
    address internal immutable ILK_REG                = DssExecLib.getChangelogAddress("ILK_REGISTRY");
    address internal immutable ORACLE                 = DssExecLib.getChangelogAddress("MIP21_LIQUIDATION_ORACLE");

    GemLike internal immutable MKR                    = GemLike(DssExecLib.mkr());

    address constant internal STABLENODE              = 0x3B91eBDfBC4B78d778f62632a4004804AC5d2DB0;
    address constant internal ULTRASCHUPPI            = 0xCCffDBc38B1463847509dCD95e0D9AAf54D1c167;
    address constant internal FLIPFLOPFLAP            = 0x688d508f3a6B0a377e266405A1583B3316f9A2B3;
    address constant internal FLIPSIDE                = 0x1ef753934C40a72a60EaB12A68B6f8854439AA78;
    address constant internal FEEDBLACKLOOPS          = 0x80882f2A36d49fC46C3c654F7f9cB9a2Bf0423e1;
    address constant internal PENNBLOCKCHAIN          = 0x2165D41aF0d8d5034b9c266597c1A415FA0253bd;
    address constant internal MHONKASALOTEEMULAU      = 0x97Fb39171ACd7C82c439b6158EA2F71D26ba383d;
    address constant internal BLOCKCHAINCOLUMBIA      = 0xdC1F98682F4F8a5c6d54F345F448437b83f5E432;
    address constant internal ACREINVEST              = 0x5b9C98e8A3D9Db6cd4B4B4C1F92D0A551D06F00D;
    address constant internal LBSBLOCKCHAIN           = 0xB83b3e9C8E3393889Afb272D354A7a3Bd1Fbcf5C;
    address constant internal CALBLOCKCHAIN           = 0x7AE109A63ff4DC852e063a673b40BED85D22E585;
    address constant internal JUSTINCASE              = 0xE070c2dCfcf6C6409202A8a210f71D51dbAe9473;
    address constant internal FRONTIERRESEARCH        = 0xA2d55b89654079987CF3985aEff5A7Bd44DA15A8;
    address constant internal CHRISBLEC               = 0xa3f0AbB4Ba74512b5a736C5759446e9B50FDA170;
    address constant internal GFXLABS                 = 0xa6e8772af29b29B9202a073f8E36f447689BEef6;
    address constant internal ONESTONE                = 0x4eFb12d515801eCfa3Be456B5F348D3CD68f9E8a;
    address constant internal CODEKNIGHT              = 0x46dFcBc2aFD5DD8789Ef0737fEdb03489D33c428;
    address constant internal LLAMA                   = 0xA519a7cE7B24333055781133B13532AEabfAC81b;
    address constant internal PVL                     = 0x6ebB1A9031177208A4CA50164206BF2Fa5ff7416;
    address constant internal CONSENSYS               = 0xE78658A8acfE982Fde841abb008e57e6545e38b3;

    address constant internal TECH_001                = 0x2dC0420A736D1F40893B9481D8968E4D7424bC0B;

    // --- DEPLOYED COLLATERAL ADDRESSES ---
    address internal constant GNO                     = 0x6810e776880C02933D47DB1b9fc05908e5386b96;
    address internal constant PIP_GNO                 = 0xd800ca44fFABecd159c7889c3bf64a217361AEc8;
    address internal constant MCD_JOIN_GNO_A          = 0x7bD3f01e24E0f0838788bC8f573CEA43A80CaBB5;
    address internal constant MCD_CLIP_GNO_A          = 0xd9e758bd239e5d568f44D0A748633f6a8d52CBbb;
    address internal constant MCD_CLIP_CALC_GNO_A     = 0x17b6D0e4237ea7F880aF5F58257cd232a04171D9;

    address constant internal RWA010                  = 0x20C72C1fdd589C4Aaa8d9fF56a43F3B17BA129f8;
    address constant internal MCD_JOIN_RWA010_A       = 0xde2828c3F7B2161cF2a1711edc36c73C56EA72aE;
    address constant internal RWA010_A_URN            = 0x4866d5d24CdC6cc094423717663b2D3343d4EFF9;
    address constant internal RWA010_A_OUTPUT_CONDUIT = 0x1F5C294EF3Ff2d2Da30ea9EDAd490C28096C91dF;
    address constant internal RWA010_A_INPUT_CONDUIT  = 0x1F5C294EF3Ff2d2Da30ea9EDAd490C28096C91dF;
    address constant internal RWA010_A_OPERATOR       = 0x1F5C294EF3Ff2d2Da30ea9EDAd490C28096C91dF;
    string  internal constant RWA010_A_DOC            = "QmRqsQRnLfaRuhFr5wCfDQZKzNo7FRVUyTJPhS76nfz6nX";

    address constant internal RWA011                  = 0x0b126F85285d1786F52FC911AfFaaf0d9253e37a;
    address constant internal MCD_JOIN_RWA011_A       = 0x9048cb84F46e94Ff312DcC50f131191c399D9bC3;
    address constant internal RWA011_A_URN            = 0x32C9bBA0841F2557C10d3f0d30092f138251aFE6;
    address constant internal RWA011_A_OUTPUT_CONDUIT = 0x8e74e529049bB135CF72276C1845f5bD779749b0;
    address constant internal RWA011_A_INPUT_CONDUIT  = 0x8e74e529049bB135CF72276C1845f5bD779749b0;
    address constant internal RWA011_A_OPERATOR       = 0x8e74e529049bB135CF72276C1845f5bD779749b0;
    string  internal constant RWA011_A_DOC            = "QmRqsQRnLfaRuhFr5wCfDQZKzNo7FRVUyTJPhS76nfz6nX";

    address constant internal RWA012                  = 0x3c7f1379B5ac286eB3636668dEAe71EaA5f7518c;
    address constant internal MCD_JOIN_RWA012_A       = 0x75646F68B8c5d8F415891F7204978Efb81ec6410;
    address constant internal RWA012_A_URN            = 0xB22E9DBF60a5b47c8B2D0D6469548F3C2D036B7E;
    address constant internal RWA012_A_OUTPUT_CONDUIT = 0x795b917eBe0a812D406ae0f99D71caf36C307e21;
    address constant internal RWA012_A_INPUT_CONDUIT  = 0x795b917eBe0a812D406ae0f99D71caf36C307e21;
    address constant internal RWA012_A_OPERATOR       = 0x795b917eBe0a812D406ae0f99D71caf36C307e21;
    string  internal constant RWA012_A_DOC            = "QmRqsQRnLfaRuhFr5wCfDQZKzNo7FRVUyTJPhS76nfz6nX";

    address constant internal RWA013                  = 0xD6C7FD4392D328e4a8f8bC50F4128B64f4dB2d4C;
    address constant internal MCD_JOIN_RWA013_A       = 0x779D0fD012815D4239BAf75140e6B2971BEd5113;
    address constant internal RWA013_A_URN            = 0x9C170dd80Ee2CA5bfDdF00cbE93e8faB2D05bA6D;
    address constant internal RWA013_A_OUTPUT_CONDUIT = 0x615984F33604011Fcd76E9b89803Be3816276E61;
    address constant internal RWA013_A_INPUT_CONDUIT  = 0x615984F33604011Fcd76E9b89803Be3816276E61;
    address constant internal RWA013_A_OPERATOR       = 0x615984F33604011Fcd76E9b89803Be3816276E61;
    string  internal constant RWA013_A_DOC            = "QmRqsQRnLfaRuhFr5wCfDQZKzNo7FRVUyTJPhS76nfz6nX";

    function actions() public override {

        // Delegate Compensation - November 2022
        // https://forum.makerdao.com/t/recognized-delegate-compensation-november-2022/19012
        // StableNode - 12000 DAI - 0x3B91eBDfBC4B78d778f62632a4004804AC5d2DB0
        DssExecLib.sendPaymentFromSurplusBuffer(STABLENODE,          12_000);
        // schuppi - 12000 DAI - 0xCCffDBc38B1463847509dCD95e0D9AAf54D1c167
        DssExecLib.sendPaymentFromSurplusBuffer(ULTRASCHUPPI,        12_000);
        // Flip Flop Flap Delegate LLC - 12000 DAI - 0x688d508f3a6B0a377e266405A1583B3316f9A2B3
        DssExecLib.sendPaymentFromSurplusBuffer(FLIPFLOPFLAP,        12_000);
        // Flipside Crypto - 11396 DAI - 0x1ef753934C40a72a60EaB12A68B6f8854439AA78
        DssExecLib.sendPaymentFromSurplusBuffer(FLIPSIDE,            11_396);
        // Feedblack Loops LLC - 10900 DAI - 0x80882f2A36d49fC46C3c654F7f9cB9a2Bf0423e1
        DssExecLib.sendPaymentFromSurplusBuffer(FEEDBLACKLOOPS,      10_900);
        // Penn Blockchain - 10385 DAI - 0x2165d41af0d8d5034b9c266597c1a415fa0253bd
        DssExecLib.sendPaymentFromSurplusBuffer(PENNBLOCKCHAIN,      10_385);
        // mhonkasalo & teemulau - 8945 DAI - 0x97Fb39171ACd7C82c439b6158EA2F71D26ba383d
        DssExecLib.sendPaymentFromSurplusBuffer(MHONKASALOTEEMULAU,   8_945);
        // [email protected] - 5109 DAI - 0xdC1F98682F4F8a5c6d54F345F448437b83f5E432
        DssExecLib.sendPaymentFromSurplusBuffer(BLOCKCHAINCOLUMBIA,   5_109);
        // AcreInvest - 4568 DAI - 0x5b9C98e8A3D9Db6cd4B4B4C1F92D0A551D06F00D
        DssExecLib.sendPaymentFromSurplusBuffer(ACREINVEST,           4_568);
        // London Business School Blockchain - 3797 DAI - 0xB83b3e9C8E3393889Afb272D354A7a3Bd1Fbcf5C
        DssExecLib.sendPaymentFromSurplusBuffer(LBSBLOCKCHAIN,        3_797);
        // CalBlockchain - 3421 DAI - 0x7AE109A63ff4DC852e063a673b40BED85D22E585
        DssExecLib.sendPaymentFromSurplusBuffer(CALBLOCKCHAIN,        3_421);
        // JustinCase - 3208 DAI - 0xE070c2dCfcf6C6409202A8a210f71D51dbAe9473
        DssExecLib.sendPaymentFromSurplusBuffer(JUSTINCASE,           3_208);
        // Frontier Research LLC - 2278 DAI - 0xA2d55b89654079987CF3985aEff5A7Bd44DA15A8
        DssExecLib.sendPaymentFromSurplusBuffer(FRONTIERRESEARCH,     2_278);
        // Chris Blec - 1883 DAI - 0xa3f0AbB4Ba74512b5a736C5759446e9B50FDA170
        DssExecLib.sendPaymentFromSurplusBuffer(CHRISBLEC,            1_883);
        // GFX Labs - 532 DAI - 0xa6e8772af29b29B9202a073f8E36f447689BEef6
        DssExecLib.sendPaymentFromSurplusBuffer(GFXLABS,                532);
        // ONESTONE - 299 DAI - 0x4eFb12d515801eCfa3Be456B5F348D3CD68f9E8a
        DssExecLib.sendPaymentFromSurplusBuffer(ONESTONE,               299);
        // CodeKnight - 271 DAI - 0x46dFcBc2aFD5DD8789Ef0737fEdb03489D33c428
        DssExecLib.sendPaymentFromSurplusBuffer(CODEKNIGHT,             271);
        // Llama - 145 DAI - 0xA519a7cE7B24333055781133B13532AEabfAC81b
        DssExecLib.sendPaymentFromSurplusBuffer(LLAMA,                  145);
        // pvl - 65 DAI - 0x6ebB1A9031177208A4CA50164206BF2Fa5ff7416
        DssExecLib.sendPaymentFromSurplusBuffer(PVL,                     65);
        // ConsenSys - 28 DAI - 0xE78658A8acfE982Fde841abb008e57e6545e38b3
        DssExecLib.sendPaymentFromSurplusBuffer(CONSENSYS,               28);

        // Tech-Ops MKR Transfer
        // https://mips.makerdao.com/mips/details/MIP40c3SP54
        // TECH-001 - 257.31 MKR - 0x2dC0420A736D1F40893B9481D8968E4D7424bC0B
        MKR.transfer(TECH_001, 257.31 ether);

        // MOMC Parameter Changes
        // https://vote.makerdao.com/polling/QmVXj9cW

        // Increase WSTETH-A line from 150 million DAI to 500 million DAI
        // Reduce WSTETH-A gap from 30 million DAI to 15 million DAI
        DssExecLib.setIlkAutoLineParameters("WSTETH-A", 500 * MILLION, 15 * MILLION, 6 hours);
        // Increase WSTETH-B line from 200 million DAI to 500 million DAI
        // Reduce WSTETH-B gap from 30 million DAI to 15 million DAI
        DssExecLib.setIlkAutoLineParameters("WSTETH-B", 500 * MILLION, 15 * MILLION, 8 hours);
        // Reduce ETH-B line from 500 million to 250 million DAI
        DssExecLib.setIlkAutoLineDebtCeiling("ETH-B", 250 * MILLION);
        // Reduce WBTC-A line from 2 billion DAI to 500 million DAI
        // Reduce WBTC-A gap from 80 million DAI to 20 million DAI
        // Increase WBTC-A ttl from 6 hours to 24 hours
        DssExecLib.setIlkAutoLineParameters("WBTC-A", 500 * MILLION, 20 * MILLION, 24 hours);
        // Reduce WBTC-B line from 500 million DAI to 250 million DAI
        // Reduce WBTC-B gap from 30 million DAI to 10 million DAI
        // Increase WBTC-B ttl from 8 hours to 24 hours
        DssExecLib.setIlkAutoLineParameters("WBTC-B", 250 * MILLION, 10 * MILLION, 24 hours);
        // Reduce WBTC-C line from 1 billion DAI to 500 million DAI
        // Reduce WBTC-C gap from 100 million DAI to 20 million DAI
        // Increase WBTC-C ttl from 8 hours to 24 hours
        DssExecLib.setIlkAutoLineParameters("WBTC-C", 500 * MILLION, 20 * MILLION, 24 hours);
        // Reduce MANA-A line from 1 million DAI to 0 DAI
        bytes32 _ilk = "MANA-A";
        DssExecLib.removeIlkFromAutoLine(_ilk);
        (,,, uint256 _line,) = VatLike(VAT).ilks(_ilk);
        DssExecLib.setValue(VAT, _ilk, "line", 0);
        DssExecLib.setValue(VAT, "Line", _sub(VatLike(VAT).Line(), _line));
        // Reduce GUNIV3DAIUSDC1-A line from 1 billion DAI to 100 million DAI
        DssExecLib.setIlkAutoLineDebtCeiling("GUNIV3DAIUSDC1-A", 100 * MILLION);
        // Reduce GUNIV3DAIUSDC2-A line from 1.25 billion DAI to 100 million DAI
        DssExecLib.setIlkAutoLineDebtCeiling("GUNIV3DAIUSDC2-A", 100 * MILLION);
        // Reduce the UNIV2DAIUSDC-A line from 300 million DAI to 100 million DAI
        DssExecLib.setIlkAutoLineDebtCeiling("UNIV2DAIUSDC-A", 100 * MILLION);
        // Reduce the PSM-USDP-A line from 500 million DAI to 450 million DAI
        DssExecLib.setIlkAutoLineDebtCeiling("PSM-PAX-A", 450 * MILLION);
        // Reduce LINK-A gap from 7 million DAI to 2.5 million DAI
        DssExecLib.setIlkAutoLineParameters("LINK-A", 5 * MILLION, 2_500_000, 8 hours);
        // Reduce YFI-A gap from 7 million DAI to 1.5 million DAI
        DssExecLib.setIlkAutoLineParameters("YFI-A", 3 * MILLION, 1_500_000, 8 hours);


        // PSM tin increases
        // Increase PSM-USDP-A tin from 0% to 0.1%
        DssExecLib.setValue(MCD_PSM_PAX_A, "tin", PSM_TEN_BASIS_POINTS);
        // Increase PSM-GUSD-A tin from 0% to 0.1%
        DssExecLib.setValue(MCD_PSM_GUSD_A, "tin", PSM_TEN_BASIS_POINTS);

        // PSM tout decrease
        // Reduce PSM-GUSD-A tout from 0.2% to 0.1%
        DssExecLib.setValue(MCD_PSM_GUSD_A, "tout", PSM_TEN_BASIS_POINTS);


        // DSR Adjustment
        // https://vote.makerdao.com/polling/914#vote-breakdown
        // Increase the DSR to 1%
        DssExecLib.setDSR(ONE_PCT_RATE, true);


        // ----------------------------- Collateral onboarding -----------------------------
        //  Add GNO-A as a new Vault Type
        //  Poll Link:   https://vote.makerdao.com/polling/QmUBoGiu#poll-detail
        //  Forum Post:  https://forum.makerdao.com/t/gno-collateral-onboarding-risk-evaluation/18820

        DssExecLib.addNewCollateral(
            CollateralOpts({
                ilk:                  "GNO-A",
                gem:                  GNO,
                join:                 MCD_JOIN_GNO_A,
                clip:                 MCD_CLIP_GNO_A,
                calc:                 MCD_CLIP_CALC_GNO_A,
                pip:                  PIP_GNO,
                isLiquidatable:       true,
                isOSM:                true,
                whitelistOSM:         true,
                ilkDebtCeiling:       3_000_000,         // line starts at IAM gap value
                minVaultAmount:       100_000,           // debt floor - dust in DAI
                maxLiquidationAmount: 2_000_000,
                liquidationPenalty:   13_00,             // 13% penalty on liquidation
                ilkStabilityFee:      TWO_FIVE_PCT_RATE, // 2.50% stability fee
                startingPriceFactor:  120_00,            // Auction price begins at 120% of oracle price
                breakerTolerance:     50_00,             // Allows for a 50% hourly price drop before disabling liquidation
                auctionDuration:      8400,
                permittedDrop:        25_00,             // 25% price drop before reset
                liquidationRatio:     350_00,            // 350% collateralization
                kprFlatReward:        250,               // 250 DAI tip - flat fee per kpr
                kprPctReward:         10                 // 0.1% chip - per kpr
            })
        );

        DssExecLib.setStairstepExponentialDecrease(MCD_CLIP_CALC_GNO_A, 60 seconds, 99_00);
        DssExecLib.setIlkAutoLineParameters("GNO-A", 5_000_000, 3_000_000, 8 hours);

        // -------------------- Changelog Update ---------------------
        DssExecLib.setChangelogAddress("GNO",                 GNO);
        DssExecLib.setChangelogAddress("PIP_GNO",             PIP_GNO);
        DssExecLib.setChangelogAddress("MCD_JOIN_GNO_A",      MCD_JOIN_GNO_A);
        DssExecLib.setChangelogAddress("MCD_CLIP_GNO_A",      MCD_CLIP_GNO_A);
        DssExecLib.setChangelogAddress("MCD_CLIP_CALC_GNO_A", MCD_CLIP_CALC_GNO_A);


        // RWA-010 Onboarding
        // https://vote.makerdao.com/polling/QmNucsGt
        _addCentrifugeCollateral(CentrifugeCollateralValues({
            GEM_JOIN:        MCD_JOIN_RWA010_A,
            GEM:             RWA010,
            URN:             RWA010_A_URN,
            OPERATOR:        RWA010_A_OPERATOR,
            INPUT_CONDUIT:   RWA010_A_INPUT_CONDUIT,
            OUTPUT_CONDUIT:  RWA010_A_OUTPUT_CONDUIT,
            DROP:            0x0b304DfFa350B32f608FF3c69f1cE511c11554cF,
            OWNER:           0x58C2fdCa82B7C564777E3547eA13bf8113A015cC, // Tinlake Clerk
            POOL:            0x1C8Fb0Ab3694Bc4c0B49402be01ae881ae0D3212, // Tinlake Operator
            TRANCHE:         0xb913dd925Fdd34867CBFa492c538B7BdB047F3Cd, // Tinlake Tranche
            ROOT:            0x4597f91cC06687Bdb74147C80C097A79358Ed29b, // Tinlake Root
            gemID:           "RWA010",
            joinID:          "MCD_JOIN_RWA010_A",
            urnID:           "RWA010_A_URN",
            inputConduitID:  "RWA010_A_INPUT_CONDUIT",
            outputConduitID: "RWA010_A_OUTPUT_CONDUIT",
            pipID:           "PIP_RWA010",
            ilk:             "RWA010-A",
            ilkString:       "RWA010",
            ilkRegistryName: "RWA010-A: Centrifuge: BlockTower Credit (I)",
            RATE:            FOUR_PCT_RATE,
            CEIL:            20_000_000,
            PRICE:           24_333_058 * WAD,
            MAT:             100_00, // Liquidation ratio
            TAU:             0,      // Remediation period
            DOC:             RWA010_A_DOC
        }));

        // RWA-011 Onboarding
        // https://vote.makerdao.com/polling/QmNucsGt
        _addCentrifugeCollateral(CentrifugeCollateralValues({
            GEM_JOIN:        MCD_JOIN_RWA011_A,
            GEM:             RWA011,
            URN:             RWA011_A_URN,
            OPERATOR:        RWA011_A_OPERATOR,
            INPUT_CONDUIT:   RWA011_A_INPUT_CONDUIT,
            OUTPUT_CONDUIT:  RWA011_A_OUTPUT_CONDUIT,
            DROP:            0x1a9cfB3c4D7202a428955D2baBdE5Bbb19621170,
            OWNER:           0x0411179607F426A001B948C1Be8F25A2522bE9D7, // Tinlake Clerk
            POOL:            0xD171E4AaBfC8c6d15e6F354608Ca661D367F97ab, // Tinlake Operator
            TRANCHE:         0x512EC4ec3143A4a586747F049ED76F722cCE8f03, // Tinlake Tranche
            ROOT:            0xB5c08534d1E73582FBd79e7C45694CAD6A5C5aB2, // Tinlake Root
            gemID:           "RWA011",
            joinID:          "MCD_JOIN_RWA011_A",
            urnID:           "RWA011_A_URN",
            inputConduitID:  "RWA011_A_INPUT_CONDUIT",
            outputConduitID: "RWA011_A_OUTPUT_CONDUIT",
            pipID:           "PIP_RWA011",
            ilk:             "RWA011-A",
            ilkString:       "RWA011",
            ilkRegistryName: "RWA011-A: Centrifuge: BlockTower Credit (II)",
            RATE:            FOUR_PCT_RATE,
            CEIL:            30_000_000,
            PRICE:           36_499_587 * WAD,
            MAT:             100_00, // Liquidation ratio
            TAU:             0,      // Remediation period
            DOC:             RWA011_A_DOC
        }));


        // RWA-012 Onboarding
        // https://vote.makerdao.com/polling/QmNucsGt
        _addCentrifugeCollateral(CentrifugeCollateralValues({
            GEM_JOIN:        MCD_JOIN_RWA012_A,
            GEM:             RWA012,
            URN:             RWA012_A_URN,
            OPERATOR:        RWA012_A_OPERATOR,
            INPUT_CONDUIT:   RWA012_A_INPUT_CONDUIT,
            OUTPUT_CONDUIT:  RWA012_A_OUTPUT_CONDUIT,
            DROP:            0x1407e60059121780f05e90D4bCE14B14D003b8EF,
            OWNER:           0x17dF3e3722Fc39A6318A0a70127aAceB86b96Da0, // Tinlake Clerk
            POOL:            0xbaa869bB8964FfB84f897cC52A994816605e84E4, // Tinlake Operator
            TRANCHE:         0x8b35c25eD7f60bDeCacA2AC093f1DC8522642B48, // Tinlake Tranche
            ROOT:            0x90040F96aB8f291b6d43A8972806e977631aFFdE, // Tinlake Root
            gemID:           "RWA012",
            joinID:          "MCD_JOIN_RWA012_A",
            urnID:           "RWA012_A_URN",
            inputConduitID:  "RWA012_A_INPUT_CONDUIT",
            outputConduitID: "RWA012_A_OUTPUT_CONDUIT",
            pipID:           "PIP_RWA012",
            ilk:             "RWA012-A",
            ilkString:       "RWA012",
            ilkRegistryName: "RWA012-A: Centrifuge: BlockTower Credit (III)",
            RATE:            FOUR_PCT_RATE,
            CEIL:            30_000_000,
            PRICE:           36_499_587 * WAD,
            MAT:             100_00, // Liquidation ratio
            TAU:             0,      // Remediation period
            DOC:             RWA010_A_DOC
        }));


        // RWA-013 Onboarding
        // https://vote.makerdao.com/polling/QmNucsGt
        _addCentrifugeCollateral(CentrifugeCollateralValues({
            GEM_JOIN:        MCD_JOIN_RWA013_A,
            GEM:             RWA013,
            URN:             RWA013_A_URN,
            OPERATOR:        RWA013_A_OPERATOR,
            INPUT_CONDUIT:   RWA013_A_INPUT_CONDUIT,
            OUTPUT_CONDUIT:  RWA013_A_OUTPUT_CONDUIT,
            DROP:            0x306cC70e3BCB03f47586b83d35698dd783C91390,
            OWNER:           0xe015FF153fa731f0399E65f08736ae71B6fD1a9F, // Tinlake Clerk
            POOL:            0x2dE79b227dB3cEf2bD9b841f77b154879Ef4A278, // Tinlake Operator
            TRANCHE:         0xc39E5cB1055Bff2202695FDbA9CCa5412831240a, // Tinlake Tranche
            ROOT:            0x55d86d51Ac3bcAB7ab7d2124931FbA106c8b60c7, // Tinlake Root
            gemID:           "RWA013",
            joinID:          "MCD_JOIN_RWA013_A",
            urnID:           "RWA013_A_URN",
            inputConduitID:  "RWA013_A_INPUT_CONDUIT",
            outputConduitID: "RWA013_A_OUTPUT_CONDUIT",
            pipID:           "PIP_RWA013",
            ilk:             "RWA013-A",
            ilkString:       "RWA013",
            ilkRegistryName: "RWA013-A: Centrifuge: BlockTower Credit (IV)",
            RATE:            FOUR_PCT_RATE,
            CEIL:            70_000_000,
            PRICE:           85_165_703 * WAD,
            MAT:             100_00, // Liquidation ratio
            TAU:             0,      // Remediation period
            DOC:             RWA013_A_DOC
        }));



        // ----------------------------- Collateral offboarding -----------------------------
        //  Offboard RENBTC-A
        //  Poll Link:   https://vote.makerdao.com/polling/QmTNMDfb#poll-detail
        //  Forum Post:  https://forum.makerdao.com/t/renbtc-a-proposed-offboarding-parameters-context/18864

        DssExecLib.setIlkLiquidationPenalty("RENBTC-A", 0);
        DssExecLib.setKeeperIncentiveFlatRate("RENBTC-A", 0);
        // setIlkLiquidationRatio to 5000%
        // We are using low level methods because DssExecLib allow to set `mat < 1000%`: https://github.com/makerdao/dss-exec-lib/blob/2afff4373e8a827659df28f6d349feb25f073e59/src/DssExecLib.sol#L733
        DssExecLib.setValue(DssExecLib.spotter(), "RENBTC-A", "mat", 50 * RAY); // 5000%
        DssExecLib.setIlkMaxLiquidationAmount("RENBTC-A", 350_000);

        // Increase Starknet Bridge Limit from 200,000 DAI to 1,000,000 DAI
        StarknetLike(STARKNET_DAI_BRIDGE).setCeiling(1_000_000 * WAD);
        // Remove Starknet Bridge Deposit Limit
        StarknetLike(STARKNET_DAI_BRIDGE).setMaxDeposit(type(uint256).max);

        // Bump changelog
        DssExecLib.setChangelogVersion("1.14.7");
    }

    function _addCentrifugeCollateral(CentrifugeCollateralValues memory collateral) internal {
        uint256 gemDecimals = GemLike(collateral.GEM).decimals();

        // Sanity checks
        {
            GemJoinLike gemJoin = GemJoinLike(collateral.GEM_JOIN);

            require(gemJoin.vat() == VAT,            "join-vat-not-match");
            require(gemJoin.ilk() == collateral.ilk, "join-ilk-not-match");
            require(gemJoin.gem() == collateral.GEM, "join-gem-not-match");
            require(gemJoin.dec() == gemDecimals,    "join-dec-not-match");

            // Setup the gemjoin
            gemJoin.rely(collateral.URN);
        }

        {
            RwaUrnLike_1 urn = RwaUrnLike_1(collateral.URN);

            require(urn.vat()           == VAT,                       "urn-vat-not-match");
            require(urn.jug()           == JUG,                       "urn-jug-not-match");
            require(urn.daiJoin()       == DAI_JOIN,                  "urn-daijoin-not-match");
            require(urn.gemJoin()       == collateral.GEM_JOIN,       "urn-gemjoin-not-match");
            require(urn.outputConduit() == collateral.OUTPUT_CONDUIT, "urn-outputconduit-not-match");

            // Set up the urn
            urn.hope(collateral.OPERATOR);
        }

        {
            TinlakeManagerLike_1 mgr = TinlakeManagerLike_1(collateral.OPERATOR);

            // Constructor params
            require(mgr.dai()     == DAI,                "mgr-dai-not-match");
            require(mgr.daiJoin() == DAI_JOIN,           "mgr-daijoin-not-match");
            require(mgr.vat()     == VAT,                "mgr-vat-not-match");
            require(mgr.gem()     == collateral.DROP,    "mgr-drop-not-match");
            // Fileable constructor params
            require(mgr.vow()     == VOW,                "mgr-vow-not-match");
            require(mgr.end()     == END,                "mgr-end-not-match");
            // Fileable centrifuge-only params
            require(mgr.pool()    == collateral.POOL,    "mgr-pool-not-match");
            require(mgr.tranche() == collateral.TRANCHE, "mgr-tranche-not-match");
            require(mgr.owner()   == collateral.OWNER,   "mgr-owner-not-match");
        }

        // Initialize the liquidation oracle for RWA0XY
        RwaLiquidationLike_1(ORACLE).init(collateral.ilk, collateral.PRICE, collateral.DOC, collateral.TAU);
        (, address pip, , ) = RwaLiquidationLike_1(ORACLE).ilks(collateral.ilk);

        // Set price feed for RWA0XY
        DssExecLib.setContract(SPOTTER, collateral.ilk, "pip", pip);

        // Init RWA0XY in Vat
        Initializable_2(VAT).init(collateral.ilk);

        // Init RWA0XY in Jug
        Initializable_2(JUG).init(collateral.ilk);

        // Allow RWA0XY_JOIN to modify the Vat registry
        DssExecLib.authorize(VAT, collateral.GEM_JOIN);

        // Set ilk/global DC
        DssExecLib.increaseIlkDebtCeiling(collateral.ilk, collateral.CEIL, /* global = */ true);

        // Set stability fee
        DssExecLib.setIlkStabilityFee(collateral.ilk, collateral.RATE, /* doDrip = */ false);

        // Set liquidation ratio
        DssExecLib.setIlkLiquidationRatio(collateral.ilk, collateral.MAT);

        // Poke the spotter to pull in a price
        DssExecLib.updateCollateralPrice(collateral.ilk);

        // Transfer the RwaToken from DSPauseProxy to the operator and lock it into the urn
        GemLike(collateral.GEM).transfer(collateral.OPERATOR, 1 * WAD);

        // Set TinlakeManager MIP21 components
        TinlakeManagerLike_1(collateral.OPERATOR).file("liq", address(ORACLE));
        TinlakeManagerLike_1(collateral.OPERATOR).file("urn", collateral.URN);
        // Lock the RWA Token in the RWA Urn
        TinlakeManagerLike_1(collateral.OPERATOR).lock(1 * WAD);
        // Rely Tinlake Root
        DssExecLib.authorize(collateral.OPERATOR, collateral.ROOT);
        // Deny DSPauseProxy
        DssExecLib.deauthorize(collateral.OPERATOR, address(this));

        // Add RWA-00x contracts to the changelog
        DssExecLib.setChangelogAddress(collateral.gemID, collateral.GEM);
        DssExecLib.setChangelogAddress(collateral.pipID, pip);
        DssExecLib.setChangelogAddress(collateral.joinID, collateral.GEM_JOIN);
        DssExecLib.setChangelogAddress(collateral.urnID, collateral.URN);
        DssExecLib.setChangelogAddress(collateral.inputConduitID, collateral.INPUT_CONDUIT);
        DssExecLib.setChangelogAddress(collateral.outputConduitID, collateral.OUTPUT_CONDUIT);

        // Add RWA0XY to the ilk registry
        IlkRegistryLike(ILK_REG).put(
            collateral.ilk,
            collateral.GEM_JOIN,
            collateral.GEM,
            gemDecimals,
            REG_RWA_CLASS,
            pip,
            address(0),
            collateral.ilkRegistryName,
            collateral.ilkString
        );
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) public {}
}