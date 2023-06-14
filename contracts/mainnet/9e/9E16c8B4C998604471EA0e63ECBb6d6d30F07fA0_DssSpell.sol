/**
 *Submitted for verification at Etherscan.io on 2023-06-14
*/

// hevm: flattened sources of src/DssSpell.sol
// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity =0.8.16 >=0.5.12 >=0.8.16 <0.9.0;

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
    function rdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {}
    function mkr()        public view returns (address) { return getChangelogAddress("MCD_GOV"); }
    function vat()        public view returns (address) { return getChangelogAddress("MCD_VAT"); }
    function jug()        public view returns (address) { return getChangelogAddress("MCD_JUG"); }
    function pot()        public view returns (address) { return getChangelogAddress("MCD_POT"); }
    function end()        public view returns (address) { return getChangelogAddress("MCD_END"); }
    function esm()        public view returns (address) { return getChangelogAddress("MCD_ESM"); }
    function reg()        public view returns (address) { return getChangelogAddress("ILK_REGISTRY"); }
    function spotter()    public view returns (address) { return getChangelogAddress("MCD_SPOT"); }
    function autoLine()   public view returns (address) { return getChangelogAddress("MCD_IAM_AUTO_LINE"); }
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
    function setDSR(uint256 _rate, bool _doDrip) public {}
    function setIlkDebtCeiling(bytes32 _ilk, uint256 _amount) public {}
    function increaseIlkDebtCeiling(bytes32 _ilk, uint256 _amount, bool _global) public {}
    function setIlkAutoLineParameters(bytes32 _ilk, uint256 _amount, uint256 _gap, uint256 _ttl) public {}
    function removeIlkFromAutoLine(bytes32 _ilk) public {}
    function setIlkLiquidationRatio(bytes32 _ilk, uint256 _pct_bps) public {}
    function setIlkStabilityFee(bytes32 _ilk, uint256 _rate, bool _doDrip) public {}
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

////// lib/dss-test/lib/dss-interfaces/src/ERC/GemAbstract.sol
/* pragma solidity >=0.5.12; */

// A base ERC-20 abstract class
// https://eips.ethereum.org/EIPS/eip-20
interface GemAbstract {
    function totalSupply() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function allowance(address, address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

////// lib/dss-test/lib/dss-interfaces/src/dss/IlkRegistryAbstract.sol
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
/* import "dss-interfaces/dss/IlkRegistryAbstract.sol"; */
/* import "dss-interfaces/ERC/GemAbstract.sol"; */

interface GemLike {
    function transfer(address, uint256) external returns (bool);
}

interface VatLike {
    function ilks(bytes32) external view returns (uint256 Art, uint256 rate, uint256 spot, uint256 line, uint256 dust);
}

interface RwaLiquidationLike_1 {
    function ilks(bytes32) external view returns (string memory doc, address pip, uint48 tau, uint48 toc);
    function init(bytes32 ilk, uint256 val, string memory doc, uint48 tau) external;
    function bump(bytes32 ilk, uint256 val) external;
}

interface ACLManagerLike_1 {
    function addPoolAdmin(address admin) external;
}

interface ProxyLike {
    function exec(address target, bytes calldata args) external payable returns (bytes memory out);
}

interface Initializable_2 {
    function init(bytes32 ilk) external;
}

interface RwaUrnLike_1 {
    function hope(address usr) external;
    function nope(address usr) external;
    function lock(uint256 wad) external;
    function draw(uint256 wad) external;
}

interface RwaInputConduitLike_1 {
    function mate(address usr) external;
    function hate(address usr) external;
    function file(bytes32 what, address data) external;
}

interface RwaOutputConduitLike_1 {
    function file(bytes32 what, address data) external;
    function hope(address usr) external;
    function nope(address usr) external;
    function mate(address usr) external;
    function hate(address usr) external;
    function kiss(address who) external;
    function pick(address who) external;
    function push() external;
}

contract DssSpellAction is DssAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget 'https://raw.githubusercontent.com/makerdao/community/c55480785534ee1f75bda65afb9761ffaebe072f/governance/votes/Executive%20vote%20-%20June%2014%2C%202023.md' -q -O - 2>/dev/null)"
    string public constant override description =
        "2023-06-14 MakerDAO Executive Spell | Hash: 0x8d9ac29d96cec17771f198f641e3c7148aa281d6f32b276edb50084c84ab098e";

    // Set office hours according to the summary
    function officeHours() public pure override returns (bool) {
        return true;
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

    uint256 internal constant THREE_PT_FOUR_NINE_PCT_RATE    = 1000000001087798189708544327;
    uint256 internal constant THREE_PT_SEVEN_FOUR_PCT_RATE   = 1000000001164306917698440949;
    uint256 internal constant FOUR_PT_TWO_FOUR_PCT_RATE      = 1000000001316772794769098706;
    uint256 internal constant FIVE_PT_EIGHT_PCT_RATE         = 1000000001787808646832390371;
    uint256 internal constant SIX_PT_THREE_PCT_RATE          = 1000000001937312893803622469;
    uint256 internal constant FIVE_PT_FIVE_FIVE_PCT_RATE     = 1000000001712791360746325100;

    uint256 internal constant MILLION           = 10 ** 6;
    uint256 internal constant WAD               = 10 ** 18;
    uint256 internal constant RAD               = 10 ** 45;

    address internal immutable MIP21_LIQUIDATION_ORACLE = DssExecLib.getChangelogAddress("MIP21_LIQUIDATION_ORACLE");
    address internal immutable REGISTRY = DssExecLib.reg();
    address internal immutable MCD_JUG  = DssExecLib.jug();
    address internal immutable MCD_SPOT = DssExecLib.spotter();
    address internal immutable MCD_ESM  = DssExecLib.esm();
    address internal immutable MCD_VAT  = DssExecLib.vat();
    GemLike internal immutable MKR      = GemLike(DssExecLib.mkr());


    // -- Spark Components --
    address internal constant SPARK_ACL_MANAGER = 0xdA135Cd78A086025BcdC87B038a1C462032b510C;
    address internal constant SPARK_PROXY       = 0x3300f198988e4C9C63F75dF86De36421f06af8c4;
    address internal constant SPARK_SPELL       = 0x41D7c79aE5Ecba7428283F66998DedFD84451e0e;

    // -- RWA015 components --
    address internal constant RWA015                     = 0xf5E5E706EfC841BeD1D24460Cd04028075cDbfdE;
    address internal constant MCD_JOIN_RWA015_A          = 0x8938988f7B368f74bEBdd3dcd8D6A3bd18C15C0b;
    address internal constant RWA015_A_URN               = 0xebFDaa143827FD0fc9C6637c3604B75Bbcfb7284;
    address internal constant RWA015_A_JAR               = 0xc27C3D3130563C1171feCC4F76C217Db603997cf;
    address internal constant RWA015_A_INPUT_CONDUIT_URN = 0xe08cb5E24862eA86328295D5E5c08972203C20D8;
    address internal constant RWA015_A_INPUT_CONDUIT_JAR = 0xB9373C557f3aE8cDdD068c1644ED226CfB18A997;
    address internal constant RWA015_A_OUTPUT_CONDUIT    = 0xC35E60736ec2E3de612535dba2dFB1f4130C82c3;
    // Operator address
    address internal constant RWA015_A_OPERATOR          = 0x23a10f09Fac6CCDbfb6d9f0215C795F9591D7476;
    // Custody address
    address internal constant RWA015_A_CUSTODY           = 0x65729807485F6f7695AF863d97D62140B7d69d83;

    // Ilk registry params
    uint256 internal constant RWA015_A_REG_CLASS_RWA = 3;

    // RWA Oracle Params
    uint256 internal constant RWA015_A_INITIAL_PRICE = 2_500_000 * WAD;
    string  internal constant RWA015_A_DOC           = "QmdbPyQLDdGQhKGXBgod7TbQmrUJ7tiN9aX1zSL7bmtkTN";
    uint48  internal constant RWA015_A_TAU           = 0;

    // Remaining params
    uint256 internal constant RWA015_A_LINE = 2_500_000;
    uint256 internal constant RWA015_A_MAT  = 100_00;
    // -- RWA015 END --

    // -- MKR TRANSFERS --
    address internal constant SIDESTREAM_WALLET = 0xb1f950a51516a697E103aaa69E152d839182f6Fe;
    address internal constant DUX_WALLET        = 0x5A994D8428CCEbCC153863CCdA9D2Be6352f89ad;

    function _updateDoc(bytes32 ilk, string memory doc) internal {
        ( , address pip, uint48 tau, ) = RwaLiquidationLike_1(MIP21_LIQUIDATION_ORACLE).ilks(ilk);
        require(pip != address(0), "DssSpell/nonexistent-rwa-ilk");

        // Init the RwaLiquidationOracle to reset the doc
        RwaLiquidationLike_1(MIP21_LIQUIDATION_ORACLE).init(
            ilk, // ilk to update
            0,   // price ignored if init() has already been called
            doc, // new legal document
            tau  // old tau value
        );
    }

    function _onboardRWA015A() internal {
        bytes32 ilk = "RWA015-A";

        // Init the RwaLiquidationOracle
        RwaLiquidationLike_1(MIP21_LIQUIDATION_ORACLE).init(ilk, RWA015_A_INITIAL_PRICE, RWA015_A_DOC, RWA015_A_TAU);
        (, address pip, , ) = RwaLiquidationLike_1(MIP21_LIQUIDATION_ORACLE).ilks(ilk);

        // Init RWA015 in Vat
        Initializable_2(MCD_VAT).init(ilk);
        // Init RWA015 in Jug
        Initializable_2(MCD_JUG).init(ilk);

        // Allow RWA015 Join to modify Vat registry
        DssExecLib.authorize(MCD_VAT, MCD_JOIN_RWA015_A);

        // Stability Fee is 0 for this ilk

        // 2_500_000 debt ceiling
        DssExecLib.increaseIlkDebtCeiling(ilk, RWA015_A_LINE, /* _global = */ true);

        // Set price feed for RWA015
        DssExecLib.setContract(MCD_SPOT, ilk, "pip", pip);

        // Set minimum collateralization ratio
        DssExecLib.setIlkLiquidationRatio(ilk, RWA015_A_MAT);

        // Poke the spotter to pull in a price
        DssExecLib.updateCollateralPrice(ilk);

        // Give the urn permissions on the join adapter
        DssExecLib.authorize(MCD_JOIN_RWA015_A, RWA015_A_URN);

        // OPERATOR permission on URN
        RwaUrnLike_1(RWA015_A_URN).hope(RWA015_A_OPERATOR);

        // OPERATOR permission on RWA015_A_OUTPUT_CONDUIT
        RwaOutputConduitLike_1(RWA015_A_OUTPUT_CONDUIT).hope(RWA015_A_OPERATOR);
        RwaOutputConduitLike_1(RWA015_A_OUTPUT_CONDUIT).mate(RWA015_A_OPERATOR);
        // Custody whitelist for output conduit destination address
        RwaOutputConduitLike_1(RWA015_A_OUTPUT_CONDUIT).kiss(RWA015_A_CUSTODY);
        // Set "quitTo" address for RWA015_A_OUTPUT_CONDUIT
        RwaOutputConduitLike_1(RWA015_A_OUTPUT_CONDUIT).file("quitTo", RWA015_A_URN);

        // OPERATOR permission on RWA015_A_INPUT_CONDUIT_URN
        RwaInputConduitLike_1(RWA015_A_INPUT_CONDUIT_URN).mate(RWA015_A_OPERATOR);
        // Set "quitTo" address for RWA015_A_INPUT_CONDUIT_URN
        RwaInputConduitLike_1(RWA015_A_INPUT_CONDUIT_URN).file("quitTo", RWA015_A_CUSTODY);

        // OPERATOR permission on RWA015_A_INPUT_CONDUIT_JAR
        RwaInputConduitLike_1(RWA015_A_INPUT_CONDUIT_JAR).mate(RWA015_A_OPERATOR);
        // Set "quitTo" address for RWA015_A_INPUT_CONDUIT_JAR
        RwaInputConduitLike_1(RWA015_A_INPUT_CONDUIT_JAR).file("quitTo", RWA015_A_CUSTODY);

        // Add RWA015 contract to the changelog
        DssExecLib.setChangelogAddress("RWA015",                     RWA015);
        DssExecLib.setChangelogAddress("PIP_RWA015",                 pip);
        DssExecLib.setChangelogAddress("MCD_JOIN_RWA015_A",          MCD_JOIN_RWA015_A);
        DssExecLib.setChangelogAddress("RWA015_A_URN",               RWA015_A_URN);
        DssExecLib.setChangelogAddress("RWA015_A_JAR",               RWA015_A_JAR);
        DssExecLib.setChangelogAddress("RWA015_A_INPUT_CONDUIT_URN", RWA015_A_INPUT_CONDUIT_URN);
        DssExecLib.setChangelogAddress("RWA015_A_INPUT_CONDUIT_JAR", RWA015_A_INPUT_CONDUIT_JAR);
        DssExecLib.setChangelogAddress("RWA015_A_OUTPUT_CONDUIT",    RWA015_A_OUTPUT_CONDUIT);

        // Add RWA015 to ILK REGISTRY
        IlkRegistryAbstract(REGISTRY).put(
            ilk,
            MCD_JOIN_RWA015_A,
            RWA015,
            GemAbstract(RWA015).decimals(),
            RWA015_A_REG_CLASS_RWA,
            pip,
            address(0),
            "RWA015-A: BlockTower Andromeda",
            GemAbstract(RWA015).symbol()
        );

        // ----- Additional ESM authorization -----
        DssExecLib.authorize(MCD_JOIN_RWA015_A,          MCD_ESM);
        DssExecLib.authorize(RWA015_A_URN,               MCD_ESM);
        DssExecLib.authorize(RWA015_A_OUTPUT_CONDUIT,    MCD_ESM);
        DssExecLib.authorize(RWA015_A_INPUT_CONDUIT_URN, MCD_ESM);
        DssExecLib.authorize(RWA015_A_INPUT_CONDUIT_JAR, MCD_ESM);

        // Bootstrap
        // Grant all required permissions for MCD_PAUSE_PROXY
        RwaUrnLike_1(RWA015_A_URN).hope(address(this));
        RwaOutputConduitLike_1(RWA015_A_OUTPUT_CONDUIT).hope(address(this));
        RwaOutputConduitLike_1(RWA015_A_OUTPUT_CONDUIT).mate(address(this));
        RwaInputConduitLike_1(RWA015_A_INPUT_CONDUIT_URN).mate(address(this));
        RwaInputConduitLike_1(RWA015_A_INPUT_CONDUIT_JAR).mate(address(this));

        // Lock RWA015 Token in the URN
        GemAbstract(RWA015).approve(RWA015_A_URN, 1 * WAD);
        RwaUrnLike_1(RWA015_A_URN).lock(1 * WAD);
        // Draw until the current debt ceiling
        RwaUrnLike_1(RWA015_A_URN).draw(RWA015_A_LINE * WAD);

        // Pick the destination for the assets
        RwaOutputConduitLike_1(RWA015_A_OUTPUT_CONDUIT).pick(RWA015_A_CUSTODY);
        // Swap Dai for the chosen stablecoin through the PSM and send it to the picked address.
        RwaOutputConduitLike_1(RWA015_A_OUTPUT_CONDUIT).push();

        // Revoke all granted permissions from MCD_PAUSE_PROXY
        RwaUrnLike_1(RWA015_A_URN).nope(address(this));
        RwaOutputConduitLike_1(RWA015_A_OUTPUT_CONDUIT).nope(address(this));
        RwaOutputConduitLike_1(RWA015_A_OUTPUT_CONDUIT).hate(address(this));
        RwaInputConduitLike_1(RWA015_A_INPUT_CONDUIT_URN).hate(address(this));
        RwaInputConduitLike_1(RWA015_A_INPUT_CONDUIT_JAR).hate(address(this));

    }

    function actions() public override {
        // --- BlockTower Vault Debt Ceiling Adjustments ---
        // Poll: https://vote.makerdao.com/polling/QmPMrvfV#poll-detail
        // Forum: https://forum.makerdao.com/t/blocktower-credit-rwa-vaults-parameters-shift/20707

        (uint256 RWA010_A_ART, , , ,) = VatLike(MCD_VAT).ilks("RWA010-A");
        (uint256 RWA011_A_ART, , , ,) = VatLike(MCD_VAT).ilks("RWA011-A");

        if (RWA010_A_ART + RWA011_A_ART == 0) {
            // Decrease the Debt Ceiling (line) of BlockTower S1 (RWA010-A) from 20 million DAI to 0 DAI.
            DssExecLib.setIlkDebtCeiling("RWA010-A", 0);
            // Decrease the Debt Ceiling (line) of BlockTower S2 (RWA011-A) from 30 million DAI to 0 DAI.
            DssExecLib.setIlkDebtCeiling("RWA011-A", 0);
            // Increase the Debt Ceiling (line) of BlockTower S3 (RWA012-A) from 30 million DAI to 80 million DAI.
            // Note: Do not increase global Line because there is no net change from these operations
            DssExecLib.setIlkDebtCeiling("RWA012-A", 80 * MILLION);

            // Increase the price to enable DAI to be drawn -- value corresponds to
            // Debt ceiling * [ (1 + RWA stability fee ) ^ (minimum deal duration in years) ] * liquidation ratio
            // 80M * 1.04^5 * 1.00 as a WAD
            RwaLiquidationLike_1(MIP21_LIQUIDATION_ORACLE).bump(
                "RWA012-A",
                 97_332_233 * WAD
            );
            // Update the RWA012-A `spot` value in Vat
            DssExecLib.updateCollateralPrice("RWA012-A");
        }


        _updateDoc("RWA010-A", "QmY382BPa5UQfmpTfi6KhjqQHtqq1fFFg2owBfsD2LKmYU");
        _updateDoc("RWA011-A", "QmY382BPa5UQfmpTfi6KhjqQHtqq1fFFg2owBfsD2LKmYU");
        _updateDoc("RWA012-A", "QmY382BPa5UQfmpTfi6KhjqQHtqq1fFFg2owBfsD2LKmYU");
        _updateDoc("RWA013-A", "QmY382BPa5UQfmpTfi6KhjqQHtqq1fFFg2owBfsD2LKmYU");

        // --- MKR Vesting Transfers ---
        // Sidestream - 348.28 MKR - 0xb1f950a51516a697E103aaa69E152d839182f6Fe
        // Poll: N/A
        // MIP: https://mips.makerdao.com/mips/details/MIP40c3SP44#estimated-mkr-expenditure

        MKR.transfer(SIDESTREAM_WALLET, 348.28 ether); // NOTE: 'ether' is a keyword helper, only MKR is transferred here

        // DUX - 225.12 MKR - 0x5A994D8428CCEbCC153863CCdA9D2Be6352f89ad
        // Poll: N/A
        // MIP: https://mips.makerdao.com/mips/details/MIP40c3SP27#total-mkr-expenditure-cap

        MKR.transfer(DUX_WALLET, 225.12 ether); // NOTE: 'ether' is a keyword helper, only MKR is transferred here

        // --- Stability Scope Defined Parameter Adjustments ---
        // Poll: https://vote.makerdao.com/polling/QmaoGpAQ#poll-detail
        // Forum: https://forum.makerdao.com/t/stability-scope-parameter-changes-2-non-scope-defined-parameter-changes-may-2023/20981#stability-scope-parameter-changes-proposal-6

        // Increase the DSR from 1.00% to 3.49%
        DssExecLib.setDSR(THREE_PT_FOUR_NINE_PCT_RATE, /* doDrip = */ true);

        // Increase the ETH-A Stability Fee from 1.75% to 3.74%
        DssExecLib.setIlkStabilityFee("ETH-A",    THREE_PT_SEVEN_FOUR_PCT_RATE, /* doDrip = */ true);

        // Increase the ETH-B Stability Fee from 3.25% to 4.24%
        DssExecLib.setIlkStabilityFee("ETH-B",    FOUR_PT_TWO_FOUR_PCT_RATE,    /* doDrip = */ true);

        // Increase the ETH-C Stability Fee from 1.00% to 3.49%
        DssExecLib.setIlkStabilityFee("ETH-C",    THREE_PT_FOUR_NINE_PCT_RATE,  /* doDrip = */ true);

        // Increase the WSTETH-A Stability Fee from 1.75% to 3.74%
        DssExecLib.setIlkStabilityFee("WSTETH-A", THREE_PT_SEVEN_FOUR_PCT_RATE, /* doDrip = */ true);

        // Increase the WSTETH-B Stability Fee from 1.00% to 3.49%
        DssExecLib.setIlkStabilityFee("WSTETH-B", THREE_PT_FOUR_NINE_PCT_RATE,  /* doDrip = */ true);

        // --- Spark Protocol Parameter Changes ---
        // D3M Parameter Adjustments Poll: https://vote.makerdao.com/polling/QmWatYqy#poll-detail
        // Executive Proxy Poll: https://vote.makerdao.com/polling/Qmc9fd3j#poll-detail
        // Onboard rETH Poll: https://vote.makerdao.com/polling/QmeEV7ph#vote-breakdown (Inside Proxy Spell)
        // DAI Interest Rate Strategy Poll: https://vote.makerdao.com/polling/QmWodV1J#poll-detail (Inside Proxy Spell)
        // Forum: https://forum.makerdao.com/t/2023-05-24-spark-protocol-updates/20958
        DssExecLib.setIlkAutoLineParameters("DIRECT-SPARK-DAI", /* line */ 20 * MILLION, /* gap */ 20 * MILLION, /* ttl */ 8 hours);
        DssExecLib.authorize(SPARK_PROXY, DssExecLib.esm());
        ACLManagerLike_1(SPARK_ACL_MANAGER).addPoolAdmin(SPARK_PROXY);
        ProxyLike(SPARK_PROXY).exec(SPARK_SPELL, abi.encodeWithSignature("execute()"));

        // --- Non-Scope Defined Parameter Adjustments ---
        // Poll: https://vote.makerdao.com/polling/QmQXhS3Z#poll-detail
        // Forum: https://forum.makerdao.com/t/stability-scope-parameter-changes-2-non-scope-defined-parameter-changes-may-2023/20981

        // Increase RETH-A line from 20 million DAI to 50 million DAI
        // Increase RETH-A gap from 3 million DAI to 5 million DAI
        DssExecLib.setIlkAutoLineParameters("RETH-A", /* line */ 50 * MILLION, /* gap */ 5 * MILLION, /* ttl */ 8 hours);

        // Increase the RETH-A Stability Fee from 0.75% to 3.74%
        DssExecLib.setIlkStabilityFee("RETH-A", THREE_PT_SEVEN_FOUR_PCT_RATE, true);

        // Increase the CRVV1ETHSTETH-A Stability Fee from 1.75% to 4.24%
        DssExecLib.setIlkStabilityFee("CRVV1ETHSTETH-A", FOUR_PT_TWO_FOUR_PCT_RATE, true);

        // Increase the WBTC-A Stability Fee from 4.90% to 5.80%
        DssExecLib.setIlkStabilityFee("WBTC-A", FIVE_PT_EIGHT_PCT_RATE, true);

        // Increase the WBTC-B Stability Fee from 4.90% to 6.30%
        DssExecLib.setIlkStabilityFee("WBTC-B", SIX_PT_THREE_PCT_RATE, true);

        // Increase the WBTC-C Stability Fee from 4.90% to 5.55%
        DssExecLib.setIlkStabilityFee("WBTC-C", FIVE_PT_FIVE_FIVE_PCT_RATE, true);

        // --- RWA015 (BlockTower Andromeda) ---
        // Poll: https://vote.makerdao.com/polling/QmbudkVR#poll-detail
        // Forum links:
        //   - https://forum.makerdao.com/t/mip90-liquid-aaa-structured-credit-money-market-fund/18428
        //   - https://forum.makerdao.com/t/project-andromeda-risk-legal-assessment/20969
        //   - https://forum.makerdao.com/t/rwa015-project-andromeda-technical-assessment/20974
        _onboardRWA015A();
        DssExecLib.setChangelogVersion("1.14.13");

        // --- USDP PSM Debt Ceiling ---
        // Poll: https://vote.makerdao.com/polling/QmQYSLHH#poll-detail
        // Forum: https://forum.makerdao.com/t/reducing-psm-usdp-a-debt-ceiling/20980
        // Reduce the PSM-PAX-A Debt Ceiling from 500 million DAI to 0 DAI

        // Do not decrease the global Line according to the point in
        // https://github.com/makerdao/spells-goerli/pull/202#discussion_r1217131039
        DssExecLib.removeIlkFromAutoLine("PSM-PAX-A");
        DssExecLib.setIlkDebtCeiling("PSM-PAX-A", 0);
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) {}
}