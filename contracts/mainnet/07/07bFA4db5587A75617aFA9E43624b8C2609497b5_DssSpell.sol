/**
 *Submitted for verification at Etherscan.io on 2022-09-07
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
    function setAuthority(address _base, address _authority) public {}
    function canCast(uint40 _ts, bool _officeHours) public pure returns (bool) {}
    function nextCastTime(uint40 _eta, uint40 _ts, bool _officeHours) public pure returns (uint256 castTime) {}
    function setValue(address _base, bytes32 _what, uint256 _amt) public {}
    function setValue(address _base, bytes32 _ilk, bytes32 _what, uint256 _amt) public {}
    function setIlkAutoLineParameters(bytes32 _ilk, uint256 _amount, uint256 _gap, uint256 _ttl) public {}
    function setIlkAutoLineDebtCeiling(bytes32 _ilk, uint256 _amount) public {}
    function setIlkStabilityFee(bytes32 _ilk, uint256 _rate, bool _doDrip) public {}
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
// // pragma experimental ABIEncoderV2;

/* import "dss-exec-lib/DssExec.sol"; */
/* import "dss-exec-lib/DssAction.sol"; */

// import { DssSpellCollateralAction } from "./DssSpellCollateral.sol";

interface GemLike {
    function transfer(address, uint256) external returns (bool);
    function approve(address, uint256) external returns (bool);
    function allowance(address, address) external view returns (uint256);
}

interface DssVestLike {
    function create(
        address _usr,
        uint256 _tot,
        uint256 _bgn,
        uint256 _tau,
        uint256 _eta,
        address _mgr
    ) external returns (uint256);
    function restrict(uint256) external;
}

contract DssSpellAction is DssAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/7e054d5ba9b9cc7566cf93ba7e19309fb9f59ab5/governance/votes/Executive%20vote%20-%20September%207%2C%202022.md -q -O - 2>/dev/null)"

    string public constant override description =
        "2022-09-07 MakerDAO Executive Spell | Hash: 0x2734d98cd923a8714496b77534dc3f7734f87a2eb5936da3e710e3f55530f930";

    DssVestLike public immutable MCD_VEST_MKR_TREASURY = DssVestLike(DssExecLib.getChangelogAddress("MCD_VEST_MKR_TREASURY"));

    uint256 internal constant JUL_01_2022 = 1656633600;

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

    uint256 internal constant ONE_FIVE_PCT_RATE     = 1000000000472114805215157978;
    uint256 internal constant TWO_PCT_RATE          = 1000000000627937192491029810;
    uint256 internal constant TWO_TWO_FIVE_PCT_RATE = 1000000000705562181084137268;
    uint256 internal constant THREE_PCT_RATE        = 1000000000937303470807876289;
    uint256 internal constant THREE_FIVE_PCT_RATE   = 1000000001090862085746321732;
    uint256 internal constant FOUR_FIVE_PCT_RATE    = 1000000001395766281313196627;

    address internal constant RWF_WALLET  = 0x96d7b01Cc25B141520C717fa369844d34FF116ec;
    address internal constant DECO_WALLET = 0xF482D1031E5b172D42B2DAA1b6e5Cbf6519596f7;
    address internal constant GRO_WALLET  = 0x7800C137A645c07132886539217ce192b9F0528e;

    address internal constant FLIP_FLOP_FLAP_WALLET  = 0x688d508f3a6B0a377e266405A1583B3316f9A2B3;
    address internal constant JUSTIN_CASE_WALLET     = 0xE070c2dCfcf6C6409202A8a210f71D51dbAe9473;
    address internal constant DOO_WALLET             = 0x3B91eBDfBC4B78d778f62632a4004804AC5d2DB0;
    address internal constant FEEDBLACK_LOOPS_WALLET = 0x80882f2A36d49fC46C3c654F7f9cB9a2Bf0423e1;
    address internal constant ULTRASCHUPPI_WALLET    = 0xCCffDBc38B1463847509dCD95e0D9AAf54D1c167;
    address internal constant FLIPSIDE_CRYPTO_WALLET = 0x62a43123FE71f9764f26554b3F5017627996816a;
    address internal constant PENN_BLOCKCHAIN        = 0x2165D41aF0d8d5034b9c266597c1A415FA0253bd;
    address internal constant GFX_LABS_WALLET        = 0xa6e8772af29b29B9202a073f8E36f447689BEef6;
    address internal constant CHRIS_BLEC             = 0xa3f0AbB4Ba74512b5a736C5759446e9B50FDA170;
    address internal constant ACRE_INVEST_WALLET     = 0x5b9C98e8A3D9Db6cd4B4B4C1F92D0A551D06F00D;
    address internal constant MHONKASALO_TEEMULAU    = 0x97Fb39171ACd7C82c439b6158EA2F71D26ba383d;
    address internal constant LLAMA                  = 0xA519a7cE7B24333055781133B13532AEabfAC81b;
    address internal constant MAKERMAN_WALLET        = 0x9AC6A6B24bCd789Fa59A175c0514f33255e1e6D0;
    address internal constant BLOCKCHAIN_COLUMBIA    = 0xdC1F98682F4F8a5c6d54F345F448437b83f5E432;
    address internal constant CODEKNIGHT             = 0x46dFcBc2aFD5DD8789Ef0737fEdb03489D33c428;
    address internal constant FRONTIER_RESEARCH      = 0xA2d55b89654079987CF3985aEff5A7Bd44DA15A8;

    uint256 internal constant MILLION = 10**6;

    uint256 internal constant WAD = 10**18;

    function _add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "DssSpellAction/add-overflow");
    }

    // Turn office hours off
    function officeHours() public override returns (bool) {
        return false;
    }

    function actions() public override {
        // ---------------------------------------------------------------------
        // Includes changes from the DssSpellCollateralAction
        // onboardNewCollaterals();
        // offboardCollaterals();

        GemLike mkr = GemLike(DssExecLib.mkr());

        // ----------------------- MKR Vesting Transfers -----------------------
        // RWF-001 - 38 MKR - 0x96d7b01Cc25B141520C717fa369844d34FF116ec
        mkr.transfer(RWF_WALLET, 38 * WAD);

        // DECO-001 - 125 MKR - 0xF482D1031E5b172D42B2DAA1b6e5Cbf6519596f7
        mkr.transfer(DECO_WALLET, 125 * WAD);

        // ------------------------ MKR Vesting Stream -------------------------
        // GRO-001 | 2022-07-01 to 2023-07-01 | 803 MKR | 0x7800C137A645c07132886539217ce192b9F0528e Cliff Date = 2022-07-01
        uint256 prevAllowance = mkr.allowance(address(this), address(MCD_VEST_MKR_TREASURY));
        mkr.approve(address(MCD_VEST_MKR_TREASURY), _add(prevAllowance, 803 * WAD));

        MCD_VEST_MKR_TREASURY.restrict(
           MCD_VEST_MKR_TREASURY.create({
                _usr: GRO_WALLET,
                _tot: 803 * WAD,
                _bgn: JUL_01_2022,
                _tau: 365 days,
                _eta: 0 days, // cliff is the start date
                _mgr: address(0)
            })
        );

        // ------------------------ Delegate Compensation ------------------------
        // https://forum.makerdao.com/t/recognized-delegate-compensation-august-2022/17584

        DssExecLib.sendPaymentFromSurplusBuffer(FLIP_FLOP_FLAP_WALLET,  12_000);
        DssExecLib.sendPaymentFromSurplusBuffer(JUSTIN_CASE_WALLET,     12_000);
        DssExecLib.sendPaymentFromSurplusBuffer(DOO_WALLET,             12_000);
        DssExecLib.sendPaymentFromSurplusBuffer(FEEDBLACK_LOOPS_WALLET, 11_970);
        DssExecLib.sendPaymentFromSurplusBuffer(ULTRASCHUPPI_WALLET,    11_844);
        DssExecLib.sendPaymentFromSurplusBuffer(FLIPSIDE_CRYPTO_WALLET, 11_392);
        DssExecLib.sendPaymentFromSurplusBuffer(PENN_BLOCKCHAIN,         9_773);
        DssExecLib.sendPaymentFromSurplusBuffer(GFX_LABS_WALLET,         8_512);
        DssExecLib.sendPaymentFromSurplusBuffer(CHRIS_BLEC,              8_090);
        DssExecLib.sendPaymentFromSurplusBuffer(ACRE_INVEST_WALLET,      6_681);
        DssExecLib.sendPaymentFromSurplusBuffer(MHONKASALO_TEEMULAU,     4_492);
        DssExecLib.sendPaymentFromSurplusBuffer(LLAMA,                   3_797);
        DssExecLib.sendPaymentFromSurplusBuffer(MAKERMAN_WALLET,         2_670);
        DssExecLib.sendPaymentFromSurplusBuffer(BLOCKCHAIN_COLUMBIA,     1_809);
        DssExecLib.sendPaymentFromSurplusBuffer(CODEKNIGHT,                208);
        DssExecLib.sendPaymentFromSurplusBuffer(FRONTIER_RESEARCH,         207);

        // ------------------ PPG - Maker Open Market Committee ------------------
        // https://vote.makerdao.com/polling/QmXHnn2u#poll-detail

        ////// Stability Fee Changes //////

        // Decrease the CRVV1ETHSTETH-A Stability Fee from 2.25% to 2.0%.
        DssExecLib.setIlkStabilityFee("CRVV1ETHSTETH-A", TWO_PCT_RATE, true);

        // Decrease the MANA-A Stability Fee from 6% to 4.5%.
        DssExecLib.setIlkStabilityFee("MANA-A", FOUR_FIVE_PCT_RATE, true);

        // Decrease the ETH-A Stability Fee from 2.25% to 1.5%.
        DssExecLib.setIlkStabilityFee("ETH-A", ONE_FIVE_PCT_RATE, true);

        // Decrease the ETH-B Stability Fee from 3.75% to 3.0%.
        DssExecLib.setIlkStabilityFee("ETH-B", THREE_PCT_RATE, true);

        // Decrease the WSTETH-A Stability Fee from 2.25% to 1.5%.
        DssExecLib.setIlkStabilityFee("WSTETH-A", ONE_FIVE_PCT_RATE, true);

        // Decrease the WBTC-A Stability Fee from 2.25% to 2%.
        DssExecLib.setIlkStabilityFee("WBTC-A", TWO_PCT_RATE, true);

        // Decrease the WBTC-B Stability Fee from 3.75% to 3.5%.
        DssExecLib.setIlkStabilityFee("WBTC-B", THREE_FIVE_PCT_RATE, true);

        // Decrease the RENBTC-A Stability Fee from 2.5% to 2.25%.
        DssExecLib.setIlkStabilityFee("RENBTC-A", TWO_TWO_FIVE_PCT_RATE, true);

        ////// Maximum Debt Ceiling Changes + Target Available Debt Change //////

        // Increase the WSTETH-B Maximum Debt Ceiling from 100 million DAI to 200 million DAI.
        DssExecLib.setIlkAutoLineDebtCeiling("WSTETH-B", 200 * MILLION);

        // Increase the CRVV1ETHSTETH-A Maximum Debt Ceiling from 5 million DAI to 20 million DAI
        // https://forum.makerdao.com/t/2022-09-07-executive-inclusion-update-crvv1ethsteth-a-maximum-debt-ceiling/17628
        // Increase the CRVV1ETHSTETH-A Target Available Debt from 3 million DAI to 10 million DAI.
        DssExecLib.setIlkAutoLineParameters("CRVV1ETHSTETH-A", 20 * MILLION, 10 * MILLION, 8 hours);
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) public {}
}