/**
 *Submitted for verification at Etherscan.io on 2023-02-03
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

interface OptimismGovRelayLike {
    function relay(address target, bytes calldata targetData, uint32 l2gas) external;
}

interface ArbitrumGovRelayLike {
    function relay(
        address target,
        bytes calldata targetData,
        uint256 l1CallValue,
        uint256 maxGas,
        uint256 gasPriceBid,
        uint256 maxSubmissionCost
    ) external payable;
}

interface StarknetGovRelayLike_1 {
    function relay(uint256 spell) external payable;
}

interface StarknetEscrowLike_1 {
    function approve(address token, address spender, uint256 value) external;
}

contract DssSpellAction is DssAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/9e70dc89aae808906cfe700a2a3767c993e4ad3c/governance/votes/Executive%20vote%20-%20February%203%2C%202023.md -q -O - 2>/dev/null)"
    string public constant override description =
        "2023-02-03 MakerDAO Executive Spell | Hash: 0x6e907ec7609bdc3cd6ba3cfbf33436f9c7a388670b66beca7e58c0b9c2cb8f93";

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

    address internal constant TECH_WALLET = 0x2dC0420A736D1F40893B9481D8968E4D7424bC0B;
    address internal constant COM_WALLET  = 0x1eE3ECa7aEF17D1e74eD7C447CcBA61aC76aDbA9;
    address internal constant SF01_WALLET = 0x4Af6f22d454581bF31B2473Ebe25F5C6F55E028D;

    address immutable internal OPTIMISM_GOV_RELAY = DssExecLib.getChangelogAddress("OPTIMISM_GOV_RELAY");
    address immutable internal ARBITRUM_GOV_RELAY = DssExecLib.getChangelogAddress("ARBITRUM_GOV_RELAY");
    address immutable internal STARKNET_GOV_RELAY = DssExecLib.getChangelogAddress("STARKNET_GOV_RELAY");

    address immutable internal DAI = DssExecLib.getChangelogAddress("MCD_DAI");
    address immutable internal STARKNET_ESCROW = DssExecLib.getChangelogAddress("STARKNET_ESCROW");
    address immutable internal STARKNET_DAI_BRIDGE_LEGACY = DssExecLib.getChangelogAddress("STARKNET_DAI_BRIDGE_LEGACY");

    address constant internal OPTIMISM_L2_SPELL = 0x9495632F53Cc16324d2FcFCdD4EB59fb88dDab12;
    address constant internal ARBITRUM_L2_SPELL = 0x852CCBB823D73b3e35f68AD6b14e29B02360FD3d;
    uint256 constant internal STARKNET_L2_SPELL = 0x4e7d83cd693f8b518f9638ce47d573fd2d642371ee266d6ed55e1276d5b43c3;

    // run ./scripts/get-opt-relay-cost.sh to help determine Optimism relay param
    uint32 public constant OPT_MAX_GAS = 100_000; // = 44582 gas (estimated L2 execution cost) + margin

    // run ./scripts/get-arb-relay-cost.sh to help determine Arbitrum relay params
    uint256 public constant ARB_MAX_GAS = 100_000; // = 38_920 gas (estimated L1 calldata + L2 execution cost) + margin (to account for surge in L1 basefee)
    uint256 public constant ARB_GAS_PRICE_BID = 1_000_000_000; // = 0.1 gwei + 0.9 gwei margin
    uint256 public constant ARB_MAX_SUBMISSION_COST = 1e15; // = ~0.7 * 10^15 (@ ~15 gwei L1 basefee) rounded up to 1*10^15
    uint256 public constant ARB_L1_CALL_VALUE = ARB_MAX_SUBMISSION_COST + ARB_MAX_GAS * ARB_GAS_PRICE_BID;

    // see: https://github.com/makerdao/starknet-spells-mainnet/blob/55401e8121f93d09f57f61c4e77dc0b6c73fb4f8/README.md#estimate-l1-l2-fee
    uint256 public constant STA_GAS_USAGE_ESTIMATION = 28460;

    // 500gwei, ~upper bound of monthly avg gas price in `21-`22,
    // ~100x max monthly median gas price in `21-`22
    // https://explorer.bitquery.io/ethereum/gas?from=2021-01-01&till=2023-01-31
    uint256 public constant STA_GAS_PRICE = 500000000000;
    uint256 public constant STA_L1_CALL_VALUE = STA_GAS_USAGE_ESTIMATION * STA_GAS_PRICE;

    function actions() public override {
        // ------------------ Pause Optimism Goerli L2DaiTeleportGateway -----------------
        // Forum: https://forum.makerdao.com/t/community-notice-pecu-to-redeploy-teleport-l2-gateways/19550
        // L2 Spell to execute via OPTIMISM_GOV_RELAY:
        // https://optimistic.etherscan.io/address/0x9495632f53cc16324d2fcfcdd4eb59fb88ddab12#code
        OptimismGovRelayLike(OPTIMISM_GOV_RELAY).relay(
            OPTIMISM_L2_SPELL,
            abi.encodeWithSignature("execute()"),
            OPT_MAX_GAS
        );

        // ------------------ Pause Arbitrum Goerli L2DaiTeleportGateway -----------------
        // Forum: https://forum.makerdao.com/t/community-notice-pecu-to-redeploy-teleport-l2-gateways/19550
        // L2 Spell to execute via ARBITRUM_GOV_RELAY:
        // https://arbiscan.io/address/0x852ccbb823d73b3e35f68ad6b14e29b02360fd3d#code
        // Note: ARBITRUM_GOV_RELAY must have been pre-funded with at least ARB_L1_CALL_VALUE worth of Ether
        ArbitrumGovRelayLike(ARBITRUM_GOV_RELAY).relay(
            ARBITRUM_L2_SPELL,
            abi.encodeWithSignature("execute()"),
            ARB_L1_CALL_VALUE,
            ARB_MAX_GAS,
            ARB_GAS_PRICE_BID,
            ARB_MAX_SUBMISSION_COST
        );

        // ------------------ Pause Starknet Goerli L2DaiTeleportGateway -----------------
        // Forum: https://forum.makerdao.com/t/community-notice-pecu-to-redeploy-teleport-l2-gateways/19550
        // L2 Spell to execute via STARKNET_GOV_RELAY:
        // src: https://github.com/makerdao/starknet-spells-mainnet/blob/55401e8121f93d09f57f61c4e77dc0b6c73fb4f8/src/spell.cairo
        // contract: https://starkscan.co/class/0x4e7d83cd693f8b518f9638ce47d573fd2d642371ee266d6ed55e1276d5b43c3#code 
        StarknetGovRelayLike_1(STARKNET_GOV_RELAY).relay{value: STA_L1_CALL_VALUE}(STARKNET_L2_SPELL);

        // disallow legacy bridge on escrow
        // Forum: https://forum.makerdao.com/t/starknet-changes-for-executive-spell-on-the-week-of-2023-01-30/19607
        StarknetEscrowLike_1(STARKNET_ESCROW).approve(DAI, STARKNET_DAI_BRIDGE_LEGACY, 0);

        // Tech-Ops DAI Transfer
        // https://vote.makerdao.com/polling/QmUMnuGb
        DssExecLib.sendPaymentFromSurplusBuffer(TECH_WALLET, 138_894);

        // GovComms offboarding
        // https://vote.makerdao.com/polling/QmV9iktK
        // https://forum.makerdao.com/t/mip39c3-sp7-core-unit-offboarding-com-001/19068/65
        DssExecLib.sendPaymentFromSurplusBuffer(COM_WALLET, 131_200);
        DssExecLib.sendPaymentFromSurplusBuffer(0x50D2f29206a76aE8a9C2339922fcBCC4DfbdD7ea, 1_336);
        DssExecLib.sendPaymentFromSurplusBuffer(0xeD27986bf84Fa8E343aA9Ff90307291dAeF234d3, 1_983);
        DssExecLib.sendPaymentFromSurplusBuffer(0x3dfE26bEDA4282ECCEdCaF2a0f146712712e81EA, 715);
        DssExecLib.sendPaymentFromSurplusBuffer(0x74520D1690348ba882Af348223A30D760BCbD72a, 1_376);
        DssExecLib.sendPaymentFromSurplusBuffer(0x471C5806cadAFB297D9b95B914B65f626fDCD1a7, 583);
        DssExecLib.sendPaymentFromSurplusBuffer(0x051cCee0CfBF1Fe9BD891117E85bEbDFa42aFaA9, 1_026);
        DssExecLib.sendPaymentFromSurplusBuffer(0x1c138352C779af714b6cE328C9d962E5c82EBA07, 631);
        DssExecLib.sendPaymentFromSurplusBuffer(0x55f2E8728cFCCf260040cfcc24E14A6047fF4d31, 255);
        DssExecLib.sendPaymentFromSurplusBuffer(0xE004DAabEfe0322Ac1ab46A3CF382a2A0bA81Ab4, 1_758);
        DssExecLib.sendPaymentFromSurplusBuffer(0xC2bE81CeB685eea53c77975b5F9c5f82641deBC8, 3_013);
        DssExecLib.sendPaymentFromSurplusBuffer(0xdB7c1777b5d4502b3d1228c2449F1816EB507748, 2_683);

        // SPF Funding: Expanded SF-001 Domain Work
        // https://vote.makerdao.com/polling/QmTjgcHY
        DssExecLib.sendPaymentFromSurplusBuffer(SF01_WALLET, 209_000);
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) {}
}