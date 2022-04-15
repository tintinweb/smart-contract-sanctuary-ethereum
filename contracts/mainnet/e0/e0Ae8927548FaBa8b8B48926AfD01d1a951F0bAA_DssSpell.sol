/**
 *Submitted for verification at Etherscan.io on 2022-04-15
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
    function wdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {}
    function rdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {}
    function dai()        public view returns (address) { return getChangelogAddress("MCD_DAI"); }
    function vat()        public view returns (address) { return getChangelogAddress("MCD_VAT"); }
    function cat()        public view returns (address) { return getChangelogAddress("MCD_CAT"); }
    function dog()        public view returns (address) { return getChangelogAddress("MCD_DOG"); }
    function pot()        public view returns (address) { return getChangelogAddress("MCD_POT"); }
    function vow()        public view returns (address) { return getChangelogAddress("MCD_VOW"); }
    function end()        public view returns (address) { return getChangelogAddress("MCD_END"); }
    function reg()        public view returns (address) { return getChangelogAddress("ILK_REGISTRY"); }
    function spotter()    public view returns (address) { return getChangelogAddress("MCD_SPOT"); }
    function clipperMom() public view returns (address) { return getChangelogAddress("CLIPPER_MOM"); }
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
    function setIlkLiquidationPenalty(bytes32 _ilk, uint256 _pct_bps) public {}
    function setIlkMaxLiquidationAmount(bytes32 _ilk, uint256 _amount) public {}
    function setIlkLiquidationRatio(bytes32 _ilk, uint256 _pct_bps) public {}
    function setStartingPriceMultiplicativeFactor(bytes32 _ilk, uint256 _pct_bps) public {}
    function setAuctionTimeBeforeReset(bytes32 _ilk, uint256 _duration) public {}
    function setAuctionPermittedDrop(bytes32 _ilk, uint256 _pct_bps) public {}
    function setKeeperIncentivePercent(bytes32 _ilk, uint256 _pct_bps) public {}
    function setKeeperIncentiveFlatRate(bytes32 _ilk, uint256 _amount) public {}
    function setLinearDecrease(address _calc, uint256 _duration) public {}
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
        //  Add CRVV1ETHSTETH-A as a new Vault Type
        //  Poll Link: https://vote.makerdao.com/polling/Qmek9vzo?network=mainnet#poll-detail
        // DssExecLib.addNewCollateral(
        //     CollateralOpts({
        //         ilk:                   "XXX-A",
        //         gem:                   XXX,
        //         join:                  MCD_JOIN_XXX_A,
        //         clip:                  MCD_CLIP_XXX_A,
        //         calc:                  MCD_CLIP_CALC_XXX_A,
        //         pip:                   PIP_XXX,
        //         isLiquidatable:        true,
        //         isOSM:                 true,
        //         whitelistOSM:          false,           // We need to whitelist OSM, but Curve Oracle orbs() function is not supported
        //         ilkDebtCeiling:        3 * MILLION,
        //         minVaultAmount:        25 * THOUSAND,
        //         maxLiquidationAmount:  3 * MILLION,
        //         liquidationPenalty:    1300,
        //         ilkStabilityFee:       NUMBER_PCT,
        //         startingPriceFactor:   13000,
        //         breakerTolerance:      5000,
        //         auctionDuration:       140 minutes,
        //         permittedDrop:         4000,
        //         liquidationRatio:      15500,
        //         kprFlatReward:         300,
        //         kprPctReward:          10
        //     })
        // );
        // DssExecLib.setStairstepExponentialDecrease(
        //     MCD_CLIP_CALC_XXX_A,
        //     90 seconds,
        //     9900
        // );
        // DssExecLib.setIlkAutoLineParameters(
        //     "XXX-A",
        //     3 * MILLION,
        //     3 * MILLION,
        //     8 hours
        // );

        // Whitelist OSM - normally handled in addNewCollateral, but Curve LP Oracle format is not supported yet
        // DssExecLib.addReaderToWhitelistCall(CurveLPOracleLike(PIP_ETHSTETH).orbs(0), PIP_ETHSTETH);
        // DssExecLib.addReaderToWhitelistCall(CurveLPOracleLike(PIP_ETHSTETH).orbs(1), PIP_ETHSTETH);

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

interface DssVestLike {
    function create(address, uint256, uint256, uint256, uint256, address) external returns (uint256);
    function restrict(uint256) external;
    function yank(uint256) external;
}

contract DssSpellAction is DssAction, DssSpellCollateralOnboardingAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/7ce9c1b474cfe9e609f6d4610aef4871577ea606/governance/votes/Executive%20vote%20-%20April%2015%2C%202022.md -q -O - 2>/dev/null)"
    string public constant override description =
        "2022-04-15 MakerDAO Executive Spell | Hash: 0x7cef7448dd5d231b101dcf8c548e3f65557d2b0515c0728de5ff641f10b94179";

    // Math
    uint256 constant internal MILLION  = 10 ** 6;
    uint256 constant internal WAD      = 10 ** 18;

    DssVestLike immutable MCD_VEST_DAI = DssVestLike(DssExecLib.getChangelogAddress("MCD_VEST_DAI"));

    address constant internal MCD_CLIP_CALC_TUSD_A = 0x9B207AfAAAD1ae300Ea659e71306a7Bd6D81C160;
    address constant internal       GRO_001_WALLET = 0x7800C137A645c07132886539217ce192b9F0528e;
    address constant internal    AMBASSADOR_WALLET = 0xF411d823a48D18B32e608274Df16a9957fE33E45;
    address constant internal    GELATO_WALLET_OLD = 0x926c21602FeC84d6d0fA6450b40Edba595B5c6e4;
    address constant internal    GELATO_WALLET_NEW = 0x478c7Ce3e1df09130f8D65a23AD80e05b352af62;

    uint256 constant APR_15_2022 = 1649980800;
    // 2022-04-15 to 2022-10-15 00:00:00 UTC
    uint256 constant SIX_MONTHS = 183 days;

    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    // A table of rates can be found at
    //    https://ipfs.io/ipfs/QmPgPVrVxDCGyNR5rGp9JC5AUxppLzUAqvncRJDcxQnX1u
    //

    // --- Rates ---
    //uint256 constant FOUR_FIVE_PCT_RATE      = 1000000001395766281313196627;


    function actions() public override {
        // ---------------------------------------------------------------------
        // Includes changes from the DssSpellCollateralOnboardingAction
        // onboardNewCollaterals();

        // ----------------- Core Unit Budgets -----------------
        // https://mips.makerdao.com/mips/details/MIP40c3SP37#budget-implementation
        DssExecLib.sendPaymentFromSurplusBuffer(GRO_001_WALLET, 474_683);

        // -------------- Fund Ambassador Program --------------
        // https://vote.makerdao.com/polling/QmPpQ49p#poll-detail
        DssExecLib.sendPaymentFromSurplusBuffer(AMBASSADOR_WALLET, 25_000);

        // ---- Replace Gelato Keeper Top Up Contract Stream ---
        // https://forum.makerdao.com/t/update-to-the-gelato-keeper-network-top-up-contract/14524
        // Yank existing stream
        MCD_VEST_DAI.yank(36);
        // Replace stream
        // Address: 0x478c7Ce3e1df09130f8D65a23AD80e05b352af62
        // Amount: 1,000 DAI/day
        // Start Date: Apr 15, 2022
        // End Date: Oct 14, 2022 23:59:59 UTC
        MCD_VEST_DAI.restrict(
            MCD_VEST_DAI.create(
                GELATO_WALLET_NEW,
                183_000 * WAD,
                APR_15_2022,
                SIX_MONTHS,
                0,
                address(0)
            )
        );

        // ------------------ Offboard TUSD-A -------------------
        // https://vote.makerdao.com/polling/QmVkRdjg#poll-detail
        bytes32 _ilk  = bytes32("TUSD-A");
        address _clip = DssExecLib.getChangelogAddress("MCD_CLIP_TUSD_A");
        //
        // Enable liquidations for TUSD-A
        // Note: ClipperMom cannot circuit-break on a DS-Value but we're adding
        //       the rely for consistency with other collaterals and in case the PIP
        //       changes to an OSM.
        DssExecLib.authorize(_clip, DssExecLib.clipperMom());
        DssExecLib.setValue(_clip, "stopped", 0);
        // Use Abacus/LinearDecrease
        DssExecLib.setContract(_clip, "calc", MCD_CLIP_CALC_TUSD_A);
        // Set Liquidation Penalty to 0
        DssExecLib.setIlkLiquidationPenalty(_ilk, 0);
        // Set Liquidation Ratio to 150%
        DssExecLib.setIlkLiquidationRatio(_ilk, 15000);
        // Set Auction Price Multiplier (buf) to 1
        DssExecLib.setStartingPriceMultiplicativeFactor(_ilk, 10000);
        // Set Local Liquidation Limit (ilk.hole) to 5 million DAI
        DssExecLib.setIlkMaxLiquidationAmount(_ilk, 5 * MILLION);
        // Set tau for Abacus/LinearDecrease to 21,600,000 second (estimated 10bps drop per 6 hours = 250 days till 0)
        DssExecLib.setLinearDecrease(MCD_CLIP_CALC_TUSD_A, 21_600_000);
        // Set Max Auction Duration (tail) to 432,000 seconds (5 days, implies minimum price of 0.98)
        DssExecLib.setAuctionTimeBeforeReset(_ilk, 432_000);
        // Inferred by risk. Enforcing here with approval https://discord.com/channels/893112320329396265/897483518316265553/963575806653767720
        DssExecLib.setAuctionPermittedDrop(_ilk, 9800);
        // Set Proportional Kick Incentive (chip) to 0
        DssExecLib.setKeeperIncentivePercent(_ilk, 0);
        // Set Flat Kick Incentive (tip) to 500
        // NOTE: PECU rejected the incentive update to 500.
        //       https://forum.makerdao.com/t/tusd-offloading-flat-kick-incentive-change/14645
        DssExecLib.setKeeperIncentiveFlatRate(_ilk, 0);
        // Update spotter price
        DssExecLib.updateCollateralPrice(_ilk);
        // Update calc in changelog
        DssExecLib.setChangelogAddress("MCD_CLIP_CALC_TUSD_A", MCD_CLIP_CALC_TUSD_A);

        // Update changelog version
        DssExecLib.setChangelogVersion("1.11.1");
    }

}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) public {}
}