/**
 *Submitted for verification at Etherscan.io on 2022-01-28
*/

// hevm: flattened sources of src/Goerli-DssSpell.sol
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
    function vow()        public view returns (address) { return getChangelogAddress("MCD_VOW"); }
    function end()        public view returns (address) { return getChangelogAddress("MCD_END"); }
    function reg()        public view returns (address) { return getChangelogAddress("ILK_REGISTRY"); }
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
    function setValue(address _base, bytes32 _what, uint256 _amt) public {}
    function setValue(address _base, bytes32 _ilk, bytes32 _what, uint256 _amt) public {}
    function setSurplusBuffer(uint256 _amount) public {}
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

////// src/Goerli-DssSpellCollateralOnboarding.sol
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

    // --- Math ---

    // --- DEPLOYED COLLATERAL ADDRESSES ---

    function onboardNewCollaterals() internal {
        // ----------------------------- Collateral onboarding -----------------------------
        //  Add ______________ as a new Vault Type
        //  Poll Link:

        // DssExecLib.addNewCollateral(
        //     CollateralOpts({
        //         ilk:                   ,
        //         gem:                   ,
        //         join:                  ,
        //         clip:                  ,
        //         calc:                  ,
        //         pip:                   ,
        //         isLiquidatable:        ,
        //         isOSM:                 ,
        //         whitelistOSM:          ,
        //         ilkDebtCeiling:        ,
        //         minVaultAmount:        ,
        //         maxLiquidationAmount:  ,
        //         liquidationPenalty:    ,
        //         ilkStabilityFee:       ,
        //         startingPriceFactor:   ,
        //         breakerTolerance:      ,
        //         auctionDuration:       ,
        //         permittedDrop:         ,
        //         liquidationRatio:      ,
        //         kprFlatReward:         ,
        //         kprPctReward:
        //     })
        // );

        // DssExecLib.setStairstepExponentialDecrease(
        //     CALC_ADDR,
        //     DURATION,
        //     PCT_BPS
        // );

        // DssExecLib.setIlkAutoLineParameters(
        //     ILK,
        //     AMOUNT,
        //     GAP,
        //     TTL
        // );

        // ChainLog Updates
        // Add the new flip and join to the Chainlog
        // address constant CHAINLOG        = DssExecLib.LOG();
        // ChainlogAbstract(CHAINLOG).setAddress("<join-name>", <join-address>);
        // ChainlogAbstract(CHAINLOG).setAddress("<clip-name>", <clip-address>);
        // ChainlogAbstract(CHAINLOG).setVersion("<new-version>");
    }
}

////// src/Goerli-DssSpell.sol
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
//// pragma experimental ABIEncoderV2;

/* import "dss-exec-lib/DssExec.sol"; */
/* import "dss-exec-lib/DssAction.sol"; */

/* import { DssSpellCollateralOnboardingAction } from "./Goerli-DssSpellCollateralOnboarding.sol"; */

contract DssSpellAction is DssAction, DssSpellCollateralOnboardingAction {
    // Provides a descriptive tag for bot consumption
    string public constant override description = "Goerli Spell";

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
    //    https://ipfs.io/ipfs/QmefQMseb3AiTapiAKKexdKHig8wroKuZbmLtPLv4u2YwW
    //

    address constant SB_LERP = address(0x98bbDDe76EB5753578280bEA86Ed8401f2831213);
    address constant NEW_MCD_ESM = address(0x023A960cb9BE7eDE35B433256f4AfE9013334b55);
    bytes32 constant MCD_ESM = "MCD_ESM";

    // Math
    uint256 constant MILLION = 10**6;
    uint256 constant WAD = 10**18;

    function actions() public override {


        // ---------------------------------------------------------------------
        // Includes changes from the DssSpellCollateralOnboardingAction
        // onboardNewCollaterals();


        address OLD_MCD_ESM = DssExecLib.getChangelogAddress(MCD_ESM);

        address addr;

        // Set the ESM threshold to 100k MKR
        // https://vote.makerdao.com/polling/QmQSVmrh?network=mainnet#poll-detail
        DssExecLib.setValue(NEW_MCD_ESM, "min", 100_000 * WAD);

        // MCD_END
        addr = DssExecLib.getChangelogAddress("MCD_END");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_ETH_A
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_ETH_A");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_ETH_B
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_ETH_B");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_ETH_C
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_ETH_C");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_BAT_A
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_BAT_A");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_USDC_A
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_USDC_A");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_USDC_B
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_USDC_B");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_TUSD_A
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_TUSD_A");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_WBTC_A
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_WBTC_A");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_ZRX_A
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_ZRX_A");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_KNC_A
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_KNC_A");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_MANA_A
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_MANA_A");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_USDT_A
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_USDT_A");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_PAXUSD_A
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_PAXUSD_A");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_COMP_A
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_COMP_A");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_LRC_A
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_LRC_A");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_LINK_A
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_LINK_A");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_BAL_A
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_BAL_A");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_YFI_A
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_YFI_A");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_GUSD_A
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_GUSD_A");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_UNI_A
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_UNI_A");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_RENBTC_A
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_RENBTC_A");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_AAVE_A
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_AAVE_A");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_PSM_USDC_A
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_PSM_USDC_A");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_MATIC_A
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_MATIC_A");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_UNIV2DAIETH_A
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_UNIV2DAIETH_A");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_UNIV2WBTCETH_A
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_UNIV2WBTCETH_A");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_UNIV2USDCETH_A
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_UNIV2USDCETH_A");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_UNIV2DAIUSDC_A
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_UNIV2DAIUSDC_A");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_UNIV2ETHUSDT_A
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_UNIV2ETHUSDT_A");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_UNIV2LINKETH_A
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_UNIV2LINKETH_A");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_UNIV2UNIETH_A
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_UNIV2UNIETH_A");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_UNIV2WBTCDAI_A
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_UNIV2WBTCDAI_A");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_UNIV2AAVEETH_A
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_UNIV2AAVEETH_A");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_UNIV2DAIUSDT_A
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_UNIV2DAIUSDT_A");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_PSM_PAX_A
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_PSM_PAX_A");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_GUNIV3DAIUSDC1_A
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_GUNIV3DAIUSDC1_A");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_WSTETH_A
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_WSTETH_A");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_WBTC_B
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_WBTC_B");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_WBTC_C
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_WBTC_C");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_PSM_GUSD_A
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_PSM_GUSD_A");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_GUNIV3DAIUSDC2_A
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_GUNIV3DAIUSDC2_A");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_VAT
        addr = DssExecLib.getChangelogAddress("MCD_VAT");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        DssExecLib.setChangelogAddress(MCD_ESM, NEW_MCD_ESM);
        DssExecLib.setChangelogVersion("1.10.0");


        // -----------
        // Deauthorize the existing lerp to prevent additional overwrites of hump.
        // https://vote.makerdao.com/executive/template-executive-vote-temporarily-prevent-surplus-flap-auctions-and-mkr-burn-january-24-2022?network=mainnet#proposal-detail
        DssExecLib.deauthorize(DssExecLib.vow(), SB_LERP);

        DssExecLib.setSurplusBuffer(250 * MILLION);
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) public {}
}