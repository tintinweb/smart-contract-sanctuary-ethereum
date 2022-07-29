/**
 *Submitted for verification at Etherscan.io on 2022-07-29
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
    function rdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {}
    function dai()        public view returns (address) { return getChangelogAddress("MCD_DAI"); }
    function vat()        public view returns (address) { return getChangelogAddress("MCD_VAT"); }
    function jug()        public view returns (address) { return getChangelogAddress("MCD_JUG"); }
    function pot()        public view returns (address) { return getChangelogAddress("MCD_POT"); }
    function end()        public view returns (address) { return getChangelogAddress("MCD_END"); }
    function reg()        public view returns (address) { return getChangelogAddress("ILK_REGISTRY"); }
    function spotter()    public view returns (address) { return getChangelogAddress("MCD_SPOT"); }
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
    function setIlkLiquidationRatio(bytes32 _ilk, uint256 _pct_bps) public {}
    function setIlkStabilityFee(bytes32 _ilk, uint256 _rate, bool _doDrip) public {}
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

////// lib/dss-interfaces/src/ERC/GemAbstract.sol
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

////// lib/dss-interfaces/src/dss/ChainlogAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/makerdao/dss-chain-log
interface ChainlogAbstract {
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function keys() external view returns (bytes32[] memory);
    function version() external view returns (string memory);
    function ipfs() external view returns (string memory);
    function setVersion(string calldata) external;
    function setSha256sum(string calldata) external;
    function setIPFS(string calldata) external;
    function setAddress(bytes32,address) external;
    function removeAddress(bytes32) external;
    function count() external view returns (uint256);
    function get(uint256) external view returns (bytes32,address);
    function list() external view returns (bytes32[] memory);
    function getAddress(bytes32) external view returns (address);
}

// Helper function for returning address or abstract of Chainlog
//  Valid on Mainnet, Kovan, Rinkeby, Ropsten, and Goerli
contract ChainlogHelper {
    address          public constant ADDRESS  = 0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F;
    ChainlogAbstract public constant ABSTRACT = ChainlogAbstract(ADDRESS);
}

////// lib/dss-interfaces/src/dss/GemJoinAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/makerdao/dss/blob/master/src/join.sol
interface GemJoinAbstract {
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function vat() external view returns (address);
    function ilk() external view returns (bytes32);
    function gem() external view returns (address);
    function dec() external view returns (uint256);
    function live() external view returns (uint256);
    function cage() external;
    function join(address, uint256) external;
    function exit(address, uint256) external;
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

////// src/DssSpellCollateral.sol
// SPDX-FileCopyrightText: © 2022 Dai Foundation <www.daifoundation.org>
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

/* import "dss-exec-lib/DssExecLib.sol"; */
/* import "dss-interfaces/dss/ChainlogAbstract.sol"; */
/* import "dss-interfaces/dss/GemJoinAbstract.sol"; */
/* import "dss-interfaces/dss/IlkRegistryAbstract.sol"; */
/* import "dss-interfaces/ERC/GemAbstract.sol"; */

interface RwaLiquidationLike_2 {
    function ilks(bytes32) external returns (string memory, address, uint48, uint48);
    function init(bytes32, uint256, string calldata, uint48) external;
}

interface RwaUrnLike_3 {
    function vat() external view returns(address);
    function jug() external view returns(address);
    function gemJoin() external view returns(address);
    function daiJoin() external view returns(address);
    function outputConduit() external view returns(address);
    function hope(address) external;
}

interface RwaOutputConduitLike_2 {
    function dai() external view returns(address);
    function hope(address) external;
    function mate(address) external;
}

interface RwaInputConduitLike_2 {
    function dai() external view returns(address);
    function to() external view returns(address);
    function mate(address usr) external;
}

contract DssSpellCollateralAction {
    // --- Rates ---
    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    // A table of rates can be found at
    //    https://ipfs.io/ipfs/QmX2QMoM1SZq2XMoTbMak8pZP86Y2icpgPAKDjQg4r4YHn

    uint256 constant ZERO_PCT_RATE           = 1000000000000000000000000000;
    uint256 constant ZERO_ZERO_FIVE_PCT_RATE = 1000000000015850933588756013;

    // --- Math ---
    uint256 public constant WAD = 10**18;
    uint256 public constant RAY = 10**27;
    uint256 public constant RAD = 10**45;

    // -- RWA008 MIP21 components --
    address constant RWA008                    = 0xb9737098b50d7c536b6416dAeB32879444F59fCA;
    address constant MCD_JOIN_RWA008_A         = 0x56eDD5067d89D4E65Bf956c49eAF054e6Ff0b262;
    address constant RWA008_A_URN              = 0x495215cabc630830071F80263a908E8826a66121;
    address constant RWA008_A_URN_CLOSE_HELPER = 0xCfc4043675EE82EEAe63C90D6eb3aB2dcf833431;
    address constant RWA008_A_INPUT_CONDUIT    = 0xa397a23dDA051186F202C67148c90683c413383C;
    address constant RWA008_A_OUTPUT_CONDUIT   = 0x21CF5Ad1311788D762f9035829f81B9f54610F0C;
    // SocGen's wallet
    address constant RWA008_A_OPERATOR         = 0x03f1A14A5b31e2f1751b6db368451dFCEA5A0439;
    // DIIS Group wallet
    address constant RWA008_A_MATE             = 0xb9444802F0831A3EB9f90E24EFe5FfA20138d684;

    string  constant RWA008_DOC                = "QmdfzY6p5EpkYMN8wcomF2a1GsJbhkPiRQVRYSPfS4NZtB";
    /**
     * The Future Value of the debt ceiling by the end of the agreement:
     *   - 30,000,00 USD: Debt Ceiling
     *   - 0.05% per year: Stability Fee
     *   - 2.9 years: Duration of the Loan
     *
     *     bc -l <<< 'scale=18; (30000000 * e( l(1.0005) * 2.9 ))'
     *
     * There is no DssExecLib helper, so WAD precision is used.
     */
    uint256 constant RWA008_A_INITIAL_PRICE    = 30_043_520_665599336150000000;
    uint48  constant RWA008_A_TAU              = 0;

    // Ilk registry params
    uint256 constant RWA008_REG_CLASS_RWA      = 3;

    // Remaining params
    uint256 constant RWA008_A_LINE             = 30_000_000;
    uint256 constant RWA008_A_MAT              = 100_00; // 100% in basis-points
    uint256 constant RWA008_A_RATE             = ZERO_ZERO_FIVE_PCT_RATE;
    // -- RWA008 end --

    // -- RWA009 MIP21 components --
    address constant RWA009                  = 0x8b9734bbaA628bFC0c9f323ba08Ed184e5b88Da2;
    address constant MCD_JOIN_RWA009_A       = 0xEe0FC514280f09083a32AE906cCbD2FAc4c680FA;
    address constant RWA009_A_URN            = 0x1818EE501cd28e01E058E7C283E178E9e04a1e79;
    address constant RWA009_A_JAR            = 0x6C6d4Be2223B5d202263515351034861dD9aFdb6;
    // Goerli: CES Goerli Multisig / Mainnet: Genesis
    address constant RWA009_A_OUTPUT_CONDUIT = 0x508D982e13263Fc8e1b5A4E6bf59b335202e36b4;

    // MIP21_LIQUIDATION_ORACLE params
    string  constant RWA009_DOC              = "QmRe77P2JsvQWygVr9ZAMs4SHnjUQXz6uawdSboAaj2ryF";
    // There is no DssExecLib helper, so WAD precision is used.
    uint256 constant RWA009_A_INITIAL_PRICE  = 100_000_000 * WAD;
    uint48  constant RWA009_A_TAU            = 0;

    // Ilk registry params
    uint256 constant RWA009_REG_CLASS_RWA    = 3;

    // Remaining params
    uint256 constant RWA009_A_LINE           = 100_000_000;
    uint256 constant RWA009_A_MAT            = 100_00; // 100% in basis-points
    uint256 constant RWA009_A_RATE           = ZERO_PCT_RATE;

    // -- RWA009 END --

    function onboardRwa008(
        ChainlogAbstract CHANGELOG,
        IlkRegistryAbstract REGISTRY,
        address MIP21_LIQUIDATION_ORACLE,
        address MCD_VAT,
        address MCD_JUG,
        address MCD_SPOT,
        address MCD_JOIN_DAI,
        address MCD_DAI
    ) internal {
        // RWA008-A collateral deploy
        bytes32 ilk      = "RWA008-A";
        uint256 decimals = GemAbstract(RWA008).decimals();

        // Sanity checks
        require(GemJoinAbstract(MCD_JOIN_RWA008_A).vat() == MCD_VAT,  "join-vat-not-match");
        require(GemJoinAbstract(MCD_JOIN_RWA008_A).ilk() == ilk,      "join-ilk-not-match");
        require(GemJoinAbstract(MCD_JOIN_RWA008_A).gem() == RWA008,   "join-gem-not-match");
        require(GemJoinAbstract(MCD_JOIN_RWA008_A).dec() == decimals, "join-dec-not-match");

        require(RwaUrnLike_3(RWA008_A_URN).vat()           == MCD_VAT,                 "urn-vat-not-match");
        require(RwaUrnLike_3(RWA008_A_URN).jug()           == MCD_JUG,                 "urn-jug-not-match");
        require(RwaUrnLike_3(RWA008_A_URN).daiJoin()       == MCD_JOIN_DAI,            "urn-daijoin-not-match");
        require(RwaUrnLike_3(RWA008_A_URN).gemJoin()       == MCD_JOIN_RWA008_A,       "urn-gemjoin-not-match");
        require(RwaUrnLike_3(RWA008_A_URN).outputConduit() == RWA008_A_OUTPUT_CONDUIT, "urn-outputconduit-not-match");

        require(RwaInputConduitLike_2(RWA008_A_INPUT_CONDUIT).dai() == MCD_DAI,      "inputconduit-dai-not-match");
        require(RwaInputConduitLike_2(RWA008_A_INPUT_CONDUIT).to()  == RWA008_A_URN, "inputconduit-to-not-match");

        require(RwaOutputConduitLike_2(RWA008_A_OUTPUT_CONDUIT).dai() == MCD_DAI, "outputconduit-dai-not-match");

        // Init the RwaLiquidationOracle
        RwaLiquidationLike_2(MIP21_LIQUIDATION_ORACLE).init(ilk, RWA008_A_INITIAL_PRICE, RWA008_DOC, RWA008_A_TAU);
        (, address pip, , ) = RwaLiquidationLike_2(MIP21_LIQUIDATION_ORACLE).ilks(ilk);

        // Set price feed for RWA008
        DssExecLib.setContract(MCD_SPOT, ilk, "pip", pip);

        // Init RWA008 in Vat
        Initializable(MCD_VAT).init(ilk);
        // Init RWA008 in Jug
        Initializable(MCD_JUG).init(ilk);

        // Allow RWA008 Join to modify Vat registry
        DssExecLib.authorize(MCD_VAT, MCD_JOIN_RWA008_A);

        // Set the debt ceiling
        DssExecLib.increaseIlkDebtCeiling(ilk, RWA008_A_LINE, /* _global = */ true);

        // Set the stability fee
        DssExecLib.setIlkStabilityFee(ilk, RWA008_A_RATE, /* _doDrip = */ false);

        // Set the collateralization ratio
        DssExecLib.setIlkLiquidationRatio(ilk, RWA008_A_MAT);

        // Poke the spotter to pull in a price
        DssExecLib.updateCollateralPrice(ilk);

        // Give the urn permissions on the join adapter
        DssExecLib.authorize(MCD_JOIN_RWA008_A, RWA008_A_URN);

        // Helper contract permisison on URN
        RwaUrnLike_3(RWA008_A_URN).hope(RWA008_A_URN_CLOSE_HELPER);
        RwaUrnLike_3(RWA008_A_URN).hope(RWA008_A_OPERATOR);

        // Set up output conduit
        //
        // We are not hope-ing the operator wallet in this spell because SocGen could not verify their addess in time.
        //
        // There is a potential front-running attack:
        //   1. The operator choses a legit `to` address with `pick()`
        //   2. The mate calls `push()` on the output conduit
        //   3. The operator front-runs the `push()` transaction and `pick()`s a fraudulent address.
        //
        // Once SocGen verifies the ownership of the address, it will be hope-d in the output conduit.
        //
        // RwaOutputConduitLike(RWA008_A_OUTPUT_CONDUIT).hope(RWA008_A_OPERATOR);

        // Whitelist DIIS Group in the conduits
        RwaOutputConduitLike_2(RWA008_A_OUTPUT_CONDUIT).mate(RWA008_A_MATE);
        RwaInputConduitLike_2(RWA008_A_INPUT_CONDUIT)  .mate(RWA008_A_MATE);

        // Whitelist Socgen in the conduits as a fallback for DIIS Group
        RwaOutputConduitLike_2(RWA008_A_OUTPUT_CONDUIT).mate(RWA008_A_OPERATOR);
        RwaInputConduitLike_2(RWA008_A_INPUT_CONDUIT)  .mate(RWA008_A_OPERATOR);

        // Add RWA008 contract to the changelog
        CHANGELOG.setAddress("RWA008",                  RWA008);
        CHANGELOG.setAddress("PIP_RWA008",              pip);
        CHANGELOG.setAddress("MCD_JOIN_RWA008_A",       MCD_JOIN_RWA008_A);
        CHANGELOG.setAddress("RWA008_A_URN",            RWA008_A_URN);
        CHANGELOG.setAddress("RWA008_A_INPUT_CONDUIT",  RWA008_A_INPUT_CONDUIT);
        CHANGELOG.setAddress("RWA008_A_OUTPUT_CONDUIT", RWA008_A_OUTPUT_CONDUIT);

        REGISTRY.put(
            ilk,
            MCD_JOIN_RWA008_A,
            RWA008,
            decimals,
            RWA008_REG_CLASS_RWA,
            pip,
            address(0),
            "RWA008-A: SG Forge OFH",
            GemAbstract(RWA008).symbol()
        );
    }

    function onboardRwa009(
        ChainlogAbstract CHANGELOG,
        IlkRegistryAbstract REGISTRY,
        address MIP21_LIQUIDATION_ORACLE,
        address MCD_VAT,
        address MCD_JUG,
        address MCD_SPOT,
        address MCD_JOIN_DAI
    ) internal {
        // RWA009-A collateral deploy
        bytes32 ilk      = "RWA009-A";
        uint256 decimals = GemAbstract(RWA009).decimals();

        // Sanity checks
        require(GemJoinAbstract(MCD_JOIN_RWA009_A).vat() == MCD_VAT,  "join-vat-not-match");
        require(GemJoinAbstract(MCD_JOIN_RWA009_A).ilk() == ilk,      "join-ilk-not-match");
        require(GemJoinAbstract(MCD_JOIN_RWA009_A).gem() == RWA009,   "join-gem-not-match");
        require(GemJoinAbstract(MCD_JOIN_RWA009_A).dec() == decimals, "join-dec-not-match");

        require(RwaUrnLike_3(RWA009_A_URN).vat()           == MCD_VAT,                 "urn-vat-not-match");
        require(RwaUrnLike_3(RWA009_A_URN).jug()           == MCD_JUG,                 "urn-jug-not-match");
        require(RwaUrnLike_3(RWA009_A_URN).daiJoin()       == MCD_JOIN_DAI,            "urn-daijoin-not-match");
        require(RwaUrnLike_3(RWA009_A_URN).gemJoin()       == MCD_JOIN_RWA009_A,       "urn-gemjoin-not-match");
        require(RwaUrnLike_3(RWA009_A_URN).outputConduit() == RWA009_A_OUTPUT_CONDUIT, "urn-outputconduit-not-match");

        // Init the RwaLiquidationOracle
        RwaLiquidationLike_2(MIP21_LIQUIDATION_ORACLE).init(ilk, RWA009_A_INITIAL_PRICE, RWA009_DOC, RWA009_A_TAU);
        (, address pip, , ) = RwaLiquidationLike_2(MIP21_LIQUIDATION_ORACLE).ilks(ilk);

        // Set price feed for RWA009
        DssExecLib.setContract(MCD_SPOT, ilk, "pip", pip);

        // Init RWA009 in Vat
        Initializable(MCD_VAT).init(ilk);
        // Init RWA009 in Jug
        Initializable(MCD_JUG).init(ilk);

        // Allow RWA009 Join to modify Vat registry
        DssExecLib.authorize(MCD_VAT, MCD_JOIN_RWA009_A);

        // 100m debt ceiling
        DssExecLib.increaseIlkDebtCeiling(ilk, RWA009_A_LINE, /* _global = */ true);

        // Set the stability fee
        DssExecLib.setIlkStabilityFee(ilk, RWA009_A_RATE, /* _doDrip = */ false);

        // Set collateralization ratio
        DssExecLib.setIlkLiquidationRatio(ilk, RWA009_A_MAT);

        // Poke the spotter to pull in a price
        DssExecLib.updateCollateralPrice(ilk);

        // Give the urn permissions on the join adapter
        DssExecLib.authorize(MCD_JOIN_RWA009_A, RWA009_A_URN);

        // MCD_PAUSE_PROXY permission on URN
        RwaUrnLike_3(RWA009_A_URN).hope(address(this));

        // Add RWA009 contract to the changelog
        CHANGELOG.setAddress("RWA009",                  RWA009);
        CHANGELOG.setAddress("PIP_RWA009",              pip);
        CHANGELOG.setAddress("MCD_JOIN_RWA009_A",       MCD_JOIN_RWA009_A);
        CHANGELOG.setAddress("RWA009_A_URN",            RWA009_A_URN);
        CHANGELOG.setAddress("RWA009_A_JAR",            RWA009_A_JAR);
        CHANGELOG.setAddress("RWA009_A_OUTPUT_CONDUIT", RWA009_A_OUTPUT_CONDUIT);

        // Add RWA009 to ILK REGISTRY
        REGISTRY.put(
            ilk,
            MCD_JOIN_RWA009_A,
            RWA009,
            decimals,
            RWA009_REG_CLASS_RWA,
            pip,
            address(0),
            "RWA009-A: H. V. Bank",
            GemAbstract(RWA009).symbol()
        );
    }

    function onboardNewCollaterals() internal {
        ChainlogAbstract CHANGELOG       = ChainlogAbstract(DssExecLib.LOG);
        IlkRegistryAbstract REGISTRY     = IlkRegistryAbstract(DssExecLib.reg());
        address MIP21_LIQUIDATION_ORACLE = CHANGELOG.getAddress("MIP21_LIQUIDATION_ORACLE");
        address MCD_VAT                  = DssExecLib.vat();
        address MCD_DAI                  = DssExecLib.dai();
        address MCD_JUG                  = DssExecLib.jug();
        address MCD_SPOT                 = DssExecLib.spotter();
        address MCD_JOIN_DAI             = DssExecLib.daiJoin();

        // --------------------------- RWA Collateral onboarding ---------------------------

        // Onboard SocGen: https://vote.makerdao.com/polling/QmajCtnG
        onboardRwa008(CHANGELOG, REGISTRY, MIP21_LIQUIDATION_ORACLE, MCD_VAT, MCD_JUG, MCD_SPOT, MCD_JOIN_DAI, MCD_DAI);

        // Onboard HvB: https://vote.makerdao.com/polling/QmQMDasC
        onboardRwa009(CHANGELOG, REGISTRY, MIP21_LIQUIDATION_ORACLE, MCD_VAT, MCD_JUG, MCD_SPOT, MCD_JOIN_DAI);
    }

    function offboardCollaterals() internal {}
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

/* import { DssSpellCollateralAction } from "./DssSpellCollateral.sol"; */

interface ERC20Like {
    function approve(address, uint256) external returns (bool);
}

interface RwaUrnLike_1 {
    function lock(uint256) external;
    function draw(uint256) external;
}

contract DssSpellAction is DssAction, DssSpellCollateralAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/969f04cfec25e56791fbe4503bcbe2df7a58df1e/governance/votes/Executive%20vote%20-%20July%2029%2C%202022.md -q -O - 2>/dev/null)"
    string public constant override description =
        "2022-07-29 MakerDAO Executive Spell | Hash: 0x18850080b101bb43125dd2bec32e5e7196586c5614bb9a0f05f9bbe392901d64";

    address constant RWA_TOKEN_FAB = 0x2B3a4c18705e99bC29b22222dA7E10b643658552;

    uint256 constant RWA009_DRAW_AMOUNT = 25_000_000 * WAD;

    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    // A table of rates can be found at
    //    https://ipfs.io/ipfs/QmX2QMoM1SZq2XMoTbMak8pZP86Y2icpgPAKDjQg4r4YHn
    //

    function officeHours() public override returns (bool) {
        return true;
    }

    function actions() public override {

        // ---------------------------------------------------------------------
        // Includes changes from the DssSpellCollateralAction
        onboardNewCollaterals();
        // offboardCollaterals();

        drawFromRWA009Urn();

        // Add RWA_TOKEN_FAB to changelog
        DssExecLib.setChangelogAddress("RWA_TOKEN_FAB", RWA_TOKEN_FAB);

        DssExecLib.setChangelogVersion("1.13.3");
    }

    function drawFromRWA009Urn() internal {
        // lock RWA009 Token in the URN
        ERC20Like(RWA009).approve(RWA009_A_URN, 1 * WAD);
        RwaUrnLike_1(RWA009_A_URN).lock(1 * WAD);

        // draw DAI to genesis address
        RwaUrnLike_1(RWA009_A_URN).draw(RWA009_DRAW_AMOUNT);
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) public {}
}