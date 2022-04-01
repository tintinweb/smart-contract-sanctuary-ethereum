/**
 *Submitted for verification at Etherscan.io on 2022-04-01
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
    //    https://ipfs.io/ipfs/QmTRiQ3GqjCiRhh1ojzKzgScmSsiwQPLyjhgYSxZASQekj
    //
    uint256 constant NUMBER_PCT = 1000000001234567890123456789;

    // --- Math ---
    uint256 constant THOUSAND   = 10 ** 3;
    uint256 constant MILLION    = 10 ** 6;

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

interface GemLike {
    function transfer(address, uint256) external returns (bool);
}

contract DssSpellAction is DssAction, DssSpellCollateralOnboardingAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/a7095d5b92ee825bef28b6f5d22baec50718d438/governance/votes/Executive%20vote%20-%20April%201%2C%202022.md -q -O - 2>/dev/null)"
    string public constant override description =
        "2022-04-01 MakerDAO Executive Spell | Hash: 0x4ac0f251ca491bf27799ebe04452ad4a6f48f2c5c8a09a5c2880a984c2f26178";

    uint256 constant WAD = 10**18;

    DssVestLike immutable MCD_VEST_DAI = DssVestLike(DssExecLib.getChangelogAddress("MCD_VEST_DAI"));
    DssVestLike immutable MCD_VEST_MKR_TREASURY = DssVestLike(DssExecLib.getChangelogAddress("MCD_VEST_MKR_TREASURY"));


    // Gov Dai Transfer, Stream and MKR vesting (41.20 MKR)
    address constant GOV_WALLET_1      = 0x01D26f8c5cC009868A4BF66E268c17B057fF7A73;
    // Gov MKR vesting (73.70 MKR) and MKR Transfer (60 MKR)
    address constant GOV_WALLET_2      = 0xC818Ae5f27B76b4902468C6B02Fd7a089F12c07b;
    // Gov MKR vesting (52.74 MKR)
    address constant GOV_WALLET_3      = 0xbfDD0E744723192f7880493b66501253C34e1241;
    // Immunefi Core Unit
    address constant ISCU_WALLET       = 0xd1F2eEf8576736C1EbA36920B957cd2aF07280F4;
    // Real World Finance Core Unit
    address constant RWF_WALLET        = 0x96d7b01Cc25B141520C717fa369844d34FF116ec;
    // Gelato Keeper Network Contract for Dai Stream
    address constant GELATO_WALLET     = 0x926c21602FeC84d6d0fA6450b40Edba595B5c6e4;

    // Start Dates - Start of Day
    uint256 constant FEB_08_2022 = 1644278400;
    uint256 constant MAR_01_2022 = 1646092800;
    uint256 constant APR_01_2022 = 1648771200;

    // End Dates - End of Day
    uint256 constant ONE_YEAR = 365 days;
    // 2022-03-01 to 2022-08-01 00:00:00 UTC
    uint256 constant FIVE_MONTHS = 153 days;
    // 2022-04-01 to 2022-09-30 23:59:59 UTC
    uint256 constant SIX_MONTHS = 183 days;
    // 2022-04-01 to 2022-12-31 00:00:00 UTC
    uint256 constant NINE_MONTHS = 274 days;

    // Amounts with decimals
    uint256 constant ISCU_DAI_STREAM_AMOUNT = 700_356.9 * 10 * WAD / 10;
    uint256 constant GOV_2_MKR = 73.70 * 10 * WAD / 10;
    uint256 constant GOV_3_MKR = 52.74 * 100 * WAD / 100;
    uint256 constant GOV_1_MKR = 41.20 * 10 * WAD / 10;


    function officeHours() public override returns (bool) {
        return false;
    }

    function actions() public override {
        // onboardNewCollaterals();

        // Core Unit DAI Budget Transfers
        // GOV-001 - 30,000 DAI - 0x01D26f8c5cC009868A4BF66E268c17B057fF7A73 https://forum.makerdao.com/t/mip40c3-sp59-govalpha-budget-2022-23/13144
        DssExecLib.sendPaymentFromSurplusBuffer(GOV_WALLET_1,  30_000);
        // IS-001 - 348,452.30 DAI - 0xd1F2eEf8576736C1EbA36920B957cd2aF07280F4 https://github.com/makerdao/mips/pull/463/files
        // Rounded up from 348,452.30 to 348,453
        DssExecLib.sendPaymentFromSurplusBuffer(ISCU_WALLET,  348_453);
        // RWF-001 - 2,055,000 DAI - 0x96d7b01Cc25B141520C717fa369844d34FF116ec https://mips.makerdao.com/mips/details/MIP40c3SP61#transactions
        DssExecLib.sendPaymentFromSurplusBuffer(RWF_WALLET,  2_055_000);

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

        // Core Unit DAI Budget Streams
        // GOV-001 | 2022-04-01 to 2023-04-01 | 1,079,793 DAI | 0x01D26f8c5cC009868A4BF66E268c17B057fF7A73 https://forum.makerdao.com/t/mip40c3-sp59-govalpha-budget-2022-23/13144
        MCD_VEST_DAI.restrict(
            MCD_VEST_DAI.create(
                GOV_WALLET_1,
                1_079_793 * WAD,
                APR_01_2022,
                ONE_YEAR,
                0,
                address(0)
            )
        );
        // IS-001 | 2022-03-01 to 2022-08-01 | 700,356.90 DAI | 0xd1F2eEf8576736C1EbA36920B957cd2aF07280F4 https://github.com/makerdao/mips/pull/463/files
        MCD_VEST_DAI.restrict(
            MCD_VEST_DAI.create(
                ISCU_WALLET,
                ISCU_DAI_STREAM_AMOUNT,
                MAR_01_2022,
                FIVE_MONTHS,
                0,
                address(0)
            )
        );
        // RWF-001 | 2022-04-01 to 2022-12-31 | 6,165,000 DAI | 0x96d7b01Cc25B141520C717fa369844d34FF116ec https://mips.makerdao.com/mips/details/MIP40c3SP61#transactions
        MCD_VEST_DAI.restrict(
            MCD_VEST_DAI.create(
                RWF_WALLET,
                6_165_000 * WAD,
                APR_01_2022,
                NINE_MONTHS,
                0,
                address(0)
            )
        );
        // Remove/Revoke Stream #27 (RWF-001) on DssVestSuckable https://mips.makerdao.com/mips/details/MIP40c3SP61#transactions
        MCD_VEST_DAI.yank(27);

        // Gelato Keeper Network DAI Budget Stream
        // https://mips.makerdao.com/mips/details/MIP63c4SP3
        // Address: 0x926c21602fec84d6d0fa6450b40edba595b5c6e4
        // Amount: 1,000 DAI/day
        // Start Date: Apr 1, 2022
        // End Date: Sep 30, 2022 23:59:59 UTC
        MCD_VEST_DAI.restrict(
            MCD_VEST_DAI.create(
                GELATO_WALLET,
                183_000 * WAD,
                APR_01_2022,
                SIX_MONTHS,
                0,
                address(0)
            )
        );

        // Core Unit MKR Vesting Streams (sourced from treasury)
        // GOV-001 | 2022-02-08 to 2023-02-08 | Cliff: 2023-02-08 (1 year) | 73.70 MKR | 0xC818Ae5f27B76b4902468C6B02Fd7a089F12c07b https://mips.makerdao.com/mips/details/MIP40c3SP60#list-of-budget-breakdowns
        MCD_VEST_MKR_TREASURY.restrict(
            MCD_VEST_MKR_TREASURY.create(
                GOV_WALLET_2,
                GOV_2_MKR,
                FEB_08_2022,
                ONE_YEAR,
                ONE_YEAR,
                address(0)
            )
        );
        // GOV-001 | 2022-02-08 to 2023-02-08 | Cliff: 2023-02-08 (1 year) | 52.74 MKR | 0xbfDD0E744723192f7880493b66501253C34e1241 https://mips.makerdao.com/mips/details/MIP40c3SP60#list-of-budget-breakdowns
        MCD_VEST_MKR_TREASURY.restrict(
            MCD_VEST_MKR_TREASURY.create(
                GOV_WALLET_3,
                GOV_3_MKR,
                FEB_08_2022,
                ONE_YEAR,
                ONE_YEAR,
                address(0)
            )
        );
        // GOV-001 | 2022-02-08 to 2023-02-08 | Cliff: 2023-02-08 (1 year) | 41.20 MKR | 0x01D26f8c5cC009868A4BF66E268c17B057fF7A73 https://mips.makerdao.com/mips/details/MIP40c3SP60#list-of-budget-breakdowns
        MCD_VEST_MKR_TREASURY.restrict(
            MCD_VEST_MKR_TREASURY.create(
                GOV_WALLET_1,
                GOV_1_MKR,
                FEB_08_2022,
                ONE_YEAR,
                ONE_YEAR,
                address(0)
            )
        );

        // Core Unit MKR Transfer (sourced from treasury)
        // GOV-001 - 60 MKR - 0xC818Ae5f27B76b4902468C6B02Fd7a089F12c07b https://mips.makerdao.com/mips/details/MIP40c3SP60#list-of-budget-breakdowns
        GemLike(DssExecLib.mkr()).transfer(GOV_WALLET_2, 60 * WAD);
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) public {}
}