/**
 *Submitted for verification at Etherscan.io on 2023-01-10
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
    function setAuthority(address _base, address _authority) public {}
    function canCast(uint40 _ts, bool _officeHours) public pure returns (bool) {}
    function nextCastTime(uint40 _eta, uint40 _ts, bool _officeHours) public pure returns (uint256 castTime) {}
    function sendPaymentFromSurplusBuffer(address _target, uint256 _amount) public {}
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

interface VestLike {
    function restrict(uint256) external;
    function create(address, uint256, uint256, uint256, uint256, address) external returns (uint256);
}

interface GemLike {
    function allowance(address, address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
}

contract DssSpellAction is DssAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/f20339d4956d043c53968d3bdef474959f1021c7/governance/votes/Executive%20vote%20-%20January%2011%2C%202023.md -q -O - 2>/dev/null)"
    string public constant override description =
        "2023-01-11 MakerDAO Executive Spell | Hash: 0xeb7cc87f7514362c910303c532230161b435e5b2626027a3f065cec7ce8f52cb";

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

    // uint256 internal constant MILLION = 10 ** 6;
    // uint256 internal constant RAY     = 10 ** 27;
    uint256 internal constant WAD                = 10 ** 18;

    GemLike  internal immutable MKR              = GemLike(DssExecLib.mkr());
    VestLike internal immutable MCD_VEST_MKR     = VestLike(DssExecLib.getChangelogAddress("MCD_VEST_MKR_TREASURY"));
    VestLike internal immutable MCD_VEST_DAI     = VestLike(DssExecLib.getChangelogAddress("MCD_VEST_DAI"));

    // Start Dates - Start of Day
    uint256 internal constant AUG_01_2022        = 1659312000;
    uint256 internal constant FEB_01_2023        = 1675209600;
    uint256 internal constant APR_30_2025        = 1745971200; // This aligns with other fin values of April 30 2025 00:00:00
    // End Dates - End of Day
    uint256 internal constant JUL_31_2023        = 1690847999;
    uint256 internal constant JAN_31_2024        = 1706745599;

    address internal constant DUX_WALLET         = 0x5A994D8428CCEbCC153863CCdA9D2Be6352f89ad;
    address internal constant SES_WALLET         = 0x87AcDD9208f73bFc9207e1f6F0fDE906bcA95cc6;

    address internal constant DECO_WALLET        = 0xF482D1031E5b172D42B2DAA1b6e5Cbf6519596f7;
    address internal constant RISK_WALLET        = 0x5d67d5B1fC7EF4bfF31967bE2D2d7b9323c1521c;
    address internal constant ORA_WALLET         = 0x2d09B7b95f3F312ba6dDfB77bA6971786c5b50Cf;

    address internal constant STABLENODE         = 0x3B91eBDfBC4B78d778f62632a4004804AC5d2DB0;
    address internal constant ULTRASCHUPPI       = 0xCCffDBc38B1463847509dCD95e0D9AAf54D1c167;
    address internal constant FLIPFLOPFLAP       = 0x688d508f3a6B0a377e266405A1583B3316f9A2B3;
    address internal constant FLIPSIDE           = 0x1ef753934C40a72a60EaB12A68B6f8854439AA78;
    address internal constant FEEDBLACKLOOPS     = 0x80882f2A36d49fC46C3c654F7f9cB9a2Bf0423e1;
    address internal constant PENNBLOCKCHAIN     = 0x2165D41aF0d8d5034b9c266597c1A415FA0253bd;
    address internal constant MHONKASALOTEEMULAU = 0x97Fb39171ACd7C82c439b6158EA2F71D26ba383d;
    address internal constant GFXLABS            = 0xa6e8772af29b29B9202a073f8E36f447689BEef6;
    address internal constant JUSTINCASE         = 0xE070c2dCfcf6C6409202A8a210f71D51dbAe9473;
    address internal constant LBSBLOCKCHAIN      = 0xB83b3e9C8E3393889Afb272D354A7a3Bd1Fbcf5C;
    address internal constant CALBLOCKCHAIN      = 0x7AE109A63ff4DC852e063a673b40BED85D22E585;
    address internal constant BLOCKCHAINCOLUMBIA = 0xdC1F98682F4F8a5c6d54F345F448437b83f5E432;
    address internal constant FRONTIERRESEARCH   = 0xA2d55b89654079987CF3985aEff5A7Bd44DA15A8;
    address internal constant CHRISBLEC          = 0xa3f0AbB4Ba74512b5a736C5759446e9B50FDA170;
    address internal constant CODEKNIGHT         = 0x46dFcBc2aFD5DD8789Ef0737fEdb03489D33c428;
    address internal constant ONESTONE           = 0x4eFb12d515801eCfa3Be456B5F348D3CD68f9E8a;
    address internal constant PVL                = 0x6ebB1A9031177208A4CA50164206BF2Fa5ff7416;
    address internal constant CONSENSYS          = 0xE78658A8acfE982Fde841abb008e57e6545e38b3;

    function actions() public override {

        // ----- Core Unit DAI Budget Streams -----

        // VEST.restrict( Only recipient can request funds
        //     VEST.create(
        //         Recipient of vest,
        //         Total token amount of vest over period,
        //         Start timestamp of vest,
        //         Duration of the vesting period (in seconds),
        //         Length of cliff period (in seconds),
        //         Manager address
        //     )
        // );

        // DUX-001 | 2023-02-01 to 2024-01-31 | 1,611,420 DAI | 0x5A994D8428CCEbCC153863CCdA9D2Be6352f89ad
        // https://vote.makerdao.com/polling/QmdhJVvN#vote-breakdown
        MCD_VEST_DAI.restrict(
            MCD_VEST_DAI.create(
                DUX_WALLET,
                1_611_420 * WAD,
                FEB_01_2023,
                JAN_31_2024 - FEB_01_2023,
                0,
                address(0)
            )
        );

        // SES-001 | 2023-02-01 to 2024-01-31 | 3,199,200 DAI | 0x87AcDD9208f73bFc9207e1f6F0fDE906bcA95cc6
        // https://vote.makerdao.com/polling/QmegsRNC#vote-breakdown
        MCD_VEST_DAI.restrict(
            MCD_VEST_DAI.create(
                SES_WALLET,
                3_199_200 * WAD,
                FEB_01_2023,
                JAN_31_2024 - FEB_01_2023,
                0,
                address(0)
            )
        );

        // ------ Core Unit MKR Transfers -----
        // DECO-001 - 125.0 MKR - 0xF482D1031E5b172D42B2DAA1b6e5Cbf6519596f7
        // https://mips.makerdao.com/mips/details/MIP40c3SP36
        MKR.transfer(DECO_WALLET, 125 * WAD);

        // RISK-001 - 175.00 MKR - 0x5d67d5B1fC7EF4bfF31967bE2D2d7b9323c1521c
        // https://mips.makerdao.com/mips/details/MIP40c3SP25
        MKR.transfer(RISK_WALLET, 175 * WAD);

        // ORA-001 - 843.69 MKR - 0x2d09B7b95f3F312ba6dDfB77bA6971786c5b50Cf
        // https://forum.makerdao.com/t/psa-oracle-core-unit-mkr-distribution/19030
        MKR.transfer(ORA_WALLET, 843.69 * 100 * WAD / 100);

        // ----- MKR Vesting Stream ------
        // Increase allowance by new vesting delta
        MKR.approve(address(MCD_VEST_MKR), MKR.allowance(address(this), address(MCD_VEST_MKR)) + 675 ether);
// Vest for PE member
        MCD_VEST_MKR.restrict(
            MCD_VEST_MKR.create(
                0xa91c40621D63599b00476eC3e528E06940B03B9D, // usr
                675 ether,                                  // tot
                AUG_01_2022,                                // bgn
                APR_30_2025 - AUG_01_2022,                  // tau
                365 days,                                   // eta
                0xe2c16c308b843eD02B09156388Cb240cEd58C01c  // mgr
            )
        );

        // ----- Delegate Compensation for December 2022 -----
        // Link: https://forum.makerdao.com/t/recognized-delegate-compensation-december-2022/19313
        // StableNode - 12000 DAI - 0x3B91eBDfBC4B78d778f62632a4004804AC5d2DB0
        DssExecLib.sendPaymentFromSurplusBuffer(STABLENODE,          12_000);
        // schuppi - 12000 DAI - 0xCCffDBc38B1463847509dCD95e0D9AAf54D1c167
        DssExecLib.sendPaymentFromSurplusBuffer(ULTRASCHUPPI,        12_000);
        // Flip Flop Flap Delegate LLC - 12000 DAI - 0x688d508f3a6B0a377e266405A1583B3316f9A2B3
        DssExecLib.sendPaymentFromSurplusBuffer(FLIPFLOPFLAP,        12_000);
        // Flipside Crypto - 11400 DAI - 0x1ef753934C40a72a60EaB12A68B6f8854439AA78
        DssExecLib.sendPaymentFromSurplusBuffer(FLIPSIDE,            11_400);
        // Feedblack Loops LLC - 10808 DAI - 0x80882f2A36d49fC46C3c654F7f9cB9a2Bf0423e1
        DssExecLib.sendPaymentFromSurplusBuffer(FEEDBLACKLOOPS,      10_808);
        // Penn Blockchain - 10385 DAI - 0x2165d41af0d8d5034b9c266597c1a415fa0253bd
        DssExecLib.sendPaymentFromSurplusBuffer(PENNBLOCKCHAIN,      10_385);
        // mhonkasalo & teemulau - 9484 DAI - 0x97Fb39171ACd7C82c439b6158EA2F71D26ba383d
        DssExecLib.sendPaymentFromSurplusBuffer(MHONKASALOTEEMULAU,   9_484);
        // GFX Labs - 8903 DAI - 0xa6e8772af29b29B9202a073f8E36f447689BEef6
        DssExecLib.sendPaymentFromSurplusBuffer(GFXLABS,              8_903);
        // JustinCase - 7235 DAI - 0xE070c2dCfcf6C6409202A8a210f71D51dbAe9473
        DssExecLib.sendPaymentFromSurplusBuffer(JUSTINCASE,           7_235);
        // London Business School Blockchain - 3798 DAI - 0xB83b3e9C8E3393889Afb272D354A7a3Bd1Fbcf5C
        DssExecLib.sendPaymentFromSurplusBuffer(LBSBLOCKCHAIN,        3_798);
        // CalBlockchain - 3421 DAI - 0x7AE109A63ff4DC852e063a673b40BED85D22E585
        DssExecLib.sendPaymentFromSurplusBuffer(CALBLOCKCHAIN,        3_421);
        // [email protected] - 2851 DAI - 0xdC1F98682F4F8a5c6d54F345F448437b83f5E432
        DssExecLib.sendPaymentFromSurplusBuffer(BLOCKCHAINCOLUMBIA,   2_851);
        // Frontier Research LLC - 2285 DAI - 0xA2d55b89654079987CF3985aEff5A7Bd44DA15A8
        DssExecLib.sendPaymentFromSurplusBuffer(FRONTIERRESEARCH,     2_285);
        // Chris Blec - 1334 DAI - 0xa3f0AbB4Ba74512b5a736C5759446e9B50FDA170
        DssExecLib.sendPaymentFromSurplusBuffer(CHRISBLEC,            1_334);
        // CodeKnight - 355 DAI - 0x46dFcBc2aFD5DD8789Ef0737fEdb03489D33c428
        DssExecLib.sendPaymentFromSurplusBuffer(CODEKNIGHT,             355);
        // ONESTONE - 342 DAI - 0x4eFb12d515801eCfa3Be456B5F348D3CD68f9E8a
        DssExecLib.sendPaymentFromSurplusBuffer(ONESTONE,               342);
        // pvl - 56 DAI - 0x6ebB1A9031177208A4CA50164206BF2Fa5ff7416
        DssExecLib.sendPaymentFromSurplusBuffer(PVL,                     56);
        // ConsenSys - 33 DAI - 0xE78658A8acfE982Fde841abb008e57e6545e38b3
        DssExecLib.sendPaymentFromSurplusBuffer(CONSENSYS,               33);

    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) {}
}