/**
 *Submitted for verification at Etherscan.io on 2022-06-08
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
    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {}
    function rdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {}
    function dai()        public view returns (address) { return getChangelogAddress("MCD_DAI"); }
    function vat()        public view returns (address) { return getChangelogAddress("MCD_VAT"); }
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
    function setAuthority(address _base, address _authority) public {}
    function canCast(uint40 _ts, bool _officeHours) public pure returns (bool) {}
    function nextCastTime(uint40 _eta, uint40 _ts, bool _officeHours) public pure returns (uint256 castTime) {}
    function setValue(address _base, bytes32 _what, uint256 _amt) public {}
    function setValue(address _base, bytes32 _ilk, bytes32 _what, uint256 _amt) public {}
    function setIlkDebtCeiling(bytes32 _ilk, uint256 _amount) public {}
    function setIlkAutoLineParameters(bytes32 _ilk, uint256 _amount, uint256 _gap, uint256 _ttl) public {}
    function setIlkAutoLineDebtCeiling(bytes32 _ilk, uint256 _amount) public {}
    function removeIlkFromAutoLine(bytes32 _ilk) public {}
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

////// src/DssSpellCollateralOnboarding.sol
// SPDX-FileCopyrightText: © 2021-2022 Dai Foundation <www.daifoundation.org>
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
// SPDX-FileCopyrightText: © 2021-2022 Dai Foundation <www.daifoundation.org>
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

interface VatLike {
    function Line() external view returns (uint256);
    function file(bytes32, uint256) external;
    function ilks(bytes32) external returns (uint256 Art, uint256 rate, uint256 spot, uint256 line, uint256 dust);
}

interface DssVestLike {
    function create(address, uint256, uint256, uint256, uint256, address) external returns (uint256);
    function restrict(uint256) external;
}

interface StarknetLike_1 {
    function setCeiling(uint256) external;
}

contract DssSpellAction is DssAction, DssSpellCollateralOnboardingAction {

    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/428d97b75ec8bdb4f2b87e69dcc917ad750b8c76/governance/votes/Executive%20vote%20-%20June%208%2C%202022.md -q -O - 2>/dev/null)"
    string public constant override description =
        "2022-06-08 MakerDAO Executive Spell | Hash: 0xf962d424ea3663316d9d91fc3854d8864b7b45165d949688117ffba9798e90b9";

    VatLike     immutable vat                   = VatLike(DssExecLib.vat());

    DssVestLike immutable MCD_VEST_DAI          = DssVestLike(DssExecLib.getChangelogAddress("MCD_VEST_DAI"));
    DssVestLike immutable MCD_VEST_MKR_TREASURY = DssVestLike(DssExecLib.getChangelogAddress("MCD_VEST_MKR_TREASURY"));

    address constant STARKNET_ESCROW_MOM    = 0xc238E3D63DfD677Fa0FA9985576f0945C581A266;
    address constant STARKNET_ESCROW        = 0x0437465dfb5B79726e35F08559B0cBea55bb585C;
    address constant STARKNET_DAI_BRIDGE    = 0x659a00c33263d9254Fed382dE81349426C795BB6;
    address constant STARKNET_GOV_RELAY     = 0x9eed6763BA8D89574af1478748a7FDF8C5236fE0;

    address constant SH_MULTISIG            = 0xc657aC882Fb2D6CcF521801da39e910F8519508d;
    address constant SH_WALLET              = 0x955993Df48b0458A01cfB5fd7DF5F5DCa6443550;

    address constant FLIPFLOPFLAP_WALLET    = 0x688d508f3a6B0a377e266405A1583B3316f9A2B3;
    address constant SCHUPPI_WALLET         = 0xCCffDBc38B1463847509dCD95e0D9AAf54D1c167;
    address constant FEEDBLACKLOOPS_WALLET  = 0x80882f2A36d49fC46C3c654F7f9cB9a2Bf0423e1;
    address constant MAKERMAN_WALLET        = 0x9AC6A6B24bCd789Fa59A175c0514f33255e1e6D0;
    address constant ACREINVEST_WALLET      = 0x5b9C98e8A3D9Db6cd4B4B4C1F92D0A551D06F00D;
    address constant MONETSUPPLY_WALLET     = 0x4Bd73eeE3d0568Bb7C52DFCad7AD5d47Fff5E2CF;
    address constant JUSTINCASE_WALLET      = 0xE070c2dCfcf6C6409202A8a210f71D51dbAe9473;
    address constant GFXLABS_WALLET         = 0xa6e8772af29b29B9202a073f8E36f447689BEef6;
    address constant DOO_WALLET             = 0x3B91eBDfBC4B78d778f62632a4004804AC5d2DB0;
    address constant FLIPSIDECRYPTO_WALLET  = 0x62a43123FE71f9764f26554b3F5017627996816a;
    address constant PENNBLOCKCHAIN_WALLET  = 0x070341aA5Ed571f0FB2c4a5641409B1A46b4961b;


    // Wed 01 Jun 2022 12:00:00 AM UTC
    uint256 constant JUN_01_2022 = 1654041600;
    // Wed 15 Mar 2023 12:00:00 AM UTC
    uint256 constant MAR_15_2023 = 1678838400;
    // Thu 23 Nov 2023 12:00:00 AM UTC
    uint256 constant NOV_23_2023 = 1700697600;


    // Math
    uint256 constant MILLION = 10 ** 6;
    uint256 constant WAD     = 10 ** 18;
    uint256 constant RAD     = 10 ** 45;

    function _sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "sub-underflow");
    }

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

    function actions() public override {
        // ---------------------------------------------------------------------
        // Includes changes from the DssSpellCollateralOnboardingAction
        // onboardNewCollaterals();


        // Core Unit Budget DAI Transfer
        // https://mips.makerdao.com/mips/details/MIP40c3SP67#budget-request-up-front
        //
        //    SH-001 - 230,000 DAI - 0xc657aC882Fb2D6CcF521801da39e910F8519508d
        DssExecLib.sendPaymentFromSurplusBuffer(SH_MULTISIG, 230_000);

        // Core Unit DAI Budget Stream
        // https://mips.makerdao.com/mips/details/MIP40c3SP67#budget-request-up-front
        //
        //    SH-001 | 2022-06-01 to 2023-03-15 | 540,000 DAI | 0xc657aC882Fb2D6CcF521801da39e910F8519508d
        MCD_VEST_DAI.restrict(
            MCD_VEST_DAI.create(
                SH_MULTISIG,
                540_000 * WAD,
                JUN_01_2022,
                MAR_15_2023 - JUN_01_2022,
                0,
                address(0)
            )
        );

        // Core Unit MKR Budget Stream
        // https://mips.makerdao.com/mips/details/MIP40c3SP67#budget-request-up-front
        //
        //    SH-001 | 2022-06-01 to 2026-06-01 | Cliff 2023-11-23 | 250 MKR | 0x955993Df48b0458A01cfB5fd7DF5F5DCa6443550
        MCD_VEST_MKR_TREASURY.restrict(
            MCD_VEST_MKR_TREASURY.create(
                SH_WALLET,
                250 * WAD,
                JUN_01_2022,
                4 * 365 days,
                NOV_23_2023 - JUN_01_2022,
                SH_WALLET
            )
        );


        // MOMC Proposal
        // https://vote.makerdao.com/polling/QmYx9e3k#poll-detail
        //
        // Maximum Debt Ceiling Decreases
        //
        //    Decrease WSTETH-A Maximum Debt Ceiling from 300 million to 200 million
        DssExecLib.setIlkAutoLineDebtCeiling("WSTETH-A", 200 * MILLION);

        //    Reduce Aave D3M Maximum Debt Ceiling from 300 million to 100 million
        DssExecLib.setIlkAutoLineDebtCeiling("DIRECT-AAVEV2-DAI", 100 * MILLION);

        //    Reduce LINK-A Maximum Debt Ceiling from 100 million DAI to 50 million DAI
        DssExecLib.setIlkAutoLineDebtCeiling("LINK-A", 50 * MILLION);

        // Maximum Debt Ceiling Increase
        //
        //    Increase MANA-A Maximum Debt Ceiling from 10 million DAI to 15 million DAI
        DssExecLib.setIlkAutoLineDebtCeiling("MANA-A", 15 * MILLION);

        // D3M Target Borrow Rate Decrease
        //
        //    Reduce DIRECT-AAVEV2-DAI Target Borrow Rate from 3.5% to 2.75%
        DssExecLib.setD3MTargetInterestRate(DssExecLib.getChangelogAddress("MCD_JOIN_DIRECT_AAVEV2_DAI"), 275);

        // Target Available Debt Increase
        //
        //    Increase WSTETH-B Target Available Debt from 15 million DAI to 30 million DAI
        DssExecLib.setIlkAutoLineParameters("WSTETH-B", 150 * MILLION, 30 * MILLION, 8 hours);


        // 1st Stage of Collateral Offboarding Process
        // https://forum.makerdao.com/t/signal-request-offboard-uni-univ2daieth-univ2wbtceth-univ2unieth-and-univ2wbtcdai/15160
        //
        uint256 line;
        uint256 lineReduction;

        //    Set UNI-A Maximum Debt Ceiling to 0
        (,,,line,) = vat.ilks("UNI-A");
        lineReduction += line;
        DssExecLib.removeIlkFromAutoLine("UNI-A");
        DssExecLib.setIlkDebtCeiling("UNI-A", 0);

        //    Set UNIV2DAIETH-A Maximum Debt Ceiling to 0
        (,,,line,) = vat.ilks("UNIV2DAIETH-A");
        lineReduction += line;
        DssExecLib.removeIlkFromAutoLine("UNIV2DAIETH-A");
        DssExecLib.setIlkDebtCeiling("UNIV2DAIETH-A", 0);

        //    Set UNIV2WBTCETH-A Maximum Debt Ceiling to 0
        (,,,line,) = vat.ilks("UNIV2WBTCETH-A");
        lineReduction += line;
        DssExecLib.removeIlkFromAutoLine("UNIV2WBTCETH-A");
        DssExecLib.setIlkDebtCeiling("UNIV2WBTCETH-A", 0);

        //    Set UNIV2UNIETH-A Maximum Debt Ceiling to 0
        (,,,line,) = vat.ilks("UNIV2UNIETH-A");
        lineReduction += line;
        DssExecLib.removeIlkFromAutoLine("UNIV2UNIETH-A");
        DssExecLib.setIlkDebtCeiling("UNIV2UNIETH-A", 0);

        //    Set UNIV2WBTCDAI-A Maximum Debt Ceiling to 0
        (,,,line,) = vat.ilks("UNIV2WBTCDAI-A");
        lineReduction += line;
        DssExecLib.removeIlkFromAutoLine("UNIV2WBTCDAI-A");
        DssExecLib.setIlkDebtCeiling("UNIV2WBTCDAI-A", 0);

        // Decrease Global Debt Ceiling by total amount of offboarded ilks
        vat.file("Line", _sub(vat.Line(), lineReduction));


        // Recognized Delegate Compensation
        //    https://forum.makerdao.com/t/recognized-delegate-compensation-breakdown-may-2022/15536
        //
        //    Flip Flop Flap Delegate LLC - 12000 DAI - 0x688d508f3a6B0a377e266405A1583B3316f9A2B3
        DssExecLib.sendPaymentFromSurplusBuffer(FLIPFLOPFLAP_WALLET, 12_000);
        //    schuppi - 12000 DAI - 0xCCffDBc38B1463847509dCD95e0D9AAf54D1c167
        DssExecLib.sendPaymentFromSurplusBuffer(SCHUPPI_WALLET, 12_000);
        //    Feedblack Loops LLC - 12000 DAI - 0x80882f2A36d49fC46C3c654F7f9cB9a2Bf0423e1
        DssExecLib.sendPaymentFromSurplusBuffer(FEEDBLACKLOOPS_WALLET, 12_000);
        //    MakerMan - 11025 DAI - 0x9AC6A6B24bCd789Fa59A175c0514f33255e1e6D0
        DssExecLib.sendPaymentFromSurplusBuffer(MAKERMAN_WALLET, 11025);
        //    ACREInvest - 9372 DAI - 0x5b9C98e8A3D9Db6cd4B4B4C1F92D0A551D06F00D
        DssExecLib.sendPaymentFromSurplusBuffer(ACREINVEST_WALLET, 9372);
        //    monetsupply - 6275 DAI - 0x4Bd73eeE3d0568Bb7C52DFCad7AD5d47Fff5E2CF
        DssExecLib.sendPaymentFromSurplusBuffer(MONETSUPPLY_WALLET, 6275);
        //    JustinCase - 7626 DAI - 0xE070c2dCfcf6C6409202A8a210f71D51dbAe9473
        DssExecLib.sendPaymentFromSurplusBuffer(JUSTINCASE_WALLET, 7626);
        //    GFX Labs - 6607 DAI - 0xa6e8772af29b29B9202a073f8E36f447689BEef6
        DssExecLib.sendPaymentFromSurplusBuffer(GFXLABS_WALLET, 6607);
        //    Doo - 622 DAI - 0x3B91eBDfBC4B78d778f62632a4004804AC5d2DB0
        DssExecLib.sendPaymentFromSurplusBuffer(DOO_WALLET, 622);
        //    Flipside Crypto - 270 DAI - 0x62a43123FE71f9764f26554b3F5017627996816a
        DssExecLib.sendPaymentFromSurplusBuffer(FLIPSIDECRYPTO_WALLET, 270);
        //    Penn Blockchain - 265 DAI - 0x070341aA5Ed571f0FB2c4a5641409B1A46b4961b
        DssExecLib.sendPaymentFromSurplusBuffer(PENNBLOCKCHAIN_WALLET, 265);


        // Starknet Bridge Changes
        // https://forum.makerdao.com/t/details-about-spells-to-be-included-in-june-8th-2022-executive-vote/15532
        //
        //    Increase Starknet Bridge Limit from 100,000 DAI to 200,000 DAI
        StarknetLike_1(STARKNET_DAI_BRIDGE).setCeiling(200_000 * WAD);
        //    Give DSChief control over L1EscrowMom
        DssExecLib.setAuthority(STARKNET_ESCROW_MOM, DssExecLib.getChangelogAddress("MCD_ADM"));


        // Changelog
        DssExecLib.setChangelogAddress("STARKNET_ESCROW_MOM", STARKNET_ESCROW_MOM);
        DssExecLib.setChangelogAddress("STARKNET_ESCROW", STARKNET_ESCROW);
        DssExecLib.setChangelogAddress("STARKNET_DAI_BRIDGE", STARKNET_DAI_BRIDGE);
        DssExecLib.setChangelogAddress("STARKNET_GOV_RELAY", STARKNET_GOV_RELAY);
        DssExecLib.setChangelogVersion("1.13.1");
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) public {}
}