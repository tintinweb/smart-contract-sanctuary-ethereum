/**
 *Submitted for verification at Etherscan.io on 2022-03-01
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2021 Dai Foundation
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

pragma solidity 0.8.9;

//
//  Spell boilerplate (section of code not directly related to Wormhole deployment)
//

interface PauseAbstract {
  function delay() external view returns (uint256);

  function plot(
    address,
    bytes32,
    bytes calldata,
    uint256
  ) external;

  function exec(
    address,
    bytes32,
    bytes calldata,
    uint256
  ) external returns (bytes memory);
}

interface Changelog {
  function getAddress(bytes32) external view returns (address);
}

interface SpellAction {
  function officeHours() external view returns (bool);

  function description() external view returns (string memory);

  function nextCastTime(uint256) external view returns (uint256);
}

library DssExecLib {
  /**
        @dev Returns true if a time is within office hours range
        @param _ts           The timestamp to check, usually block.timestamp
        @param _officeHours  true if office hours is enabled.
        @return              true if time is in castable range
    */
  function canCast(uint40 _ts, bool _officeHours) internal pure returns (bool) {
    if (_officeHours) {
      uint256 day = (_ts / 1 days + 3) % 7;
      if (day >= 5) {
        return false;
      } // Can only be cast on a weekday
      uint256 hour = (_ts / 1 hours) % 24;
      if (hour < 14 || hour >= 21) {
        return false;
      } // Outside office hours
    }
    return true;
  }

  /**
        @dev Calculate the next available cast time in epoch seconds
        @param _eta          The scheduled time of the spell plus the pause delay
        @param _ts           The current timestamp, usually block.timestamp
        @param _officeHours  true if office hours is enabled.
        @return castTime     The next available cast timestamp
    */
  function nextCastTime(
    uint40 _eta,
    uint40 _ts,
    bool _officeHours
  ) internal pure returns (uint256 castTime) {
    require(_eta != 0); // "DssExecLib/invalid eta"
    require(_ts != 0); // "DssExecLib/invalid ts"
    castTime = _ts > _eta ? _ts : _eta; // Any day at XX:YY

    if (_officeHours) {
      uint256 day = (castTime / 1 days + 3) % 7;
      uint256 hour = (castTime / 1 hours) % 24;
      uint256 minute = (castTime / 1 minutes) % 60;
      uint256 second = castTime % 60;

      if (day >= 5) {
        castTime += (6 - day) * 1 days; // Go to Sunday XX:YY
        castTime += (24 - hour + 14) * 1 hours; // Go to 14:YY UTC Monday
        castTime -= minute * 1 minutes + second; // Go to 14:00 UTC
      } else {
        if (hour >= 21) {
          if (day == 4) castTime += 2 days; // If Friday, fast forward to Sunday XX:YY
          castTime += (24 - hour + 14) * 1 hours; // Go to 14:YY UTC next day
          castTime -= minute * 1 minutes + second; // Go to 14:00 UTC
        } else if (hour < 14) {
          castTime += (14 - hour) * 1 hours; // Go to 14:YY UTC same day
          castTime -= minute * 1 minutes + second; // Go to 14:00 UTC
        }
      }
    }
  }
}

contract DssExec {
  Changelog public constant log = Changelog(0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F);
  uint256 public eta;
  bytes public sig;
  bool public done;
  bytes32 public immutable tag;
  address public immutable action;
  uint256 public immutable expiration;
  PauseAbstract public immutable pause;

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
  constructor(uint256 _expiration, address _spellAction) {
    pause = PauseAbstract(log.getAddress("MCD_PAUSE"));
    expiration = _expiration;
    action = _spellAction;

    sig = abi.encodeWithSignature("execute()");
    bytes32 _tag; // Required for assembly access
    address _action = _spellAction; // Required for assembly access
    assembly {
      _tag := extcodehash(_action)
    }
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

abstract contract DssAction {
  using DssExecLib for *;

  // Modifier used to limit execution time when office hours is enabled
  modifier limited() {
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
  function description() external view virtual returns (string memory);

  // Returns the next available cast time
  function nextCastTime(uint256 eta) external returns (uint256 castTime) {
    require(eta <= type(uint40).max);
    castTime = DssExecLib.nextCastTime(uint40(eta), uint40(block.timestamp), officeHours());
  }
}

//
//  Spell core (section of code directly related to Wormhole deployment)
//

interface VatLike {
  function rely(address usr) external;

  function init(bytes32 ilk) external;

  function file(
    bytes32 ilk,
    bytes32 what,
    uint256 data
  ) external;
}

interface WormholeJoinLike {
  function file(bytes32 what, address val) external;

  function file(
    bytes32 what,
    bytes32 domain_,
    address data
  ) external;

  function file(
    bytes32 what,
    bytes32 domain_,
    uint256 data
  ) external;

  function ilk() external returns (bytes32);
}

interface OracleAuthLike {
  function file(bytes32 what, uint256 data) external;

  function addSigners(address[] calldata signers_) external;
}

interface RouterLike {
  function file(
    bytes32 what,
    bytes32 domain,
    address data
  ) external;
}

interface L1EscrowLike {
  function approve(
    address token,
    address spender,
    uint256 value
  ) external;
}

interface GovernanceRelayLike {
  function relay(
    address target,
    bytes calldata targetData,
    uint32 l2gas
  ) external;
}

contract DssSpellAction is DssAction {
  uint256 public constant RAY = 10**27;
  uint256 public constant RAD = 10**45;

  string public constant override description = "Kovan Optimism Wormhole deployment spell";

  function officeHours() public pure override returns (bool) {
    return false;
  }

  function actions() public override {
    bytes32 masterDomain = "KOVAN-MASTER-1";
    WormholeJoinLike wormholeJoin = WormholeJoinLike(0x5B321180cC155a6fd38bc14a64205d1344317975);
    address vow = 0x0F4Cbe6CBA918b7488C26E29d9ECd7368F38EA3b;
    VatLike vat = VatLike(0xbA987bDB501d131f766fEe8180Da5d81b34b69d9);
    uint256 globalLine = 10000000000 * RAD;
    RouterLike router = RouterLike(0x7e178860F560c8eb8a493113bDeB23A5db8B945F);
    OracleAuthLike oracleAuth = OracleAuthLike(0xcEBe310e86d44a55EC6Be05e0c233B033979BC67);
    address[] memory oracles = new address[](5);
    oracles[0] = 0xC4756A9DaE297A046556261Fa3CD922DFC32Db78; // OCU
    oracles[1] = 0x23ce419DcE1De6b3647Ca2484A25F595132DfBd2; // OCU
    oracles[2] = 0x774D5AA0EeE4897a9a6e65Cbed845C13Ffbc6d16; // OCU
    oracles[3] = 0xb41E8d40b7aC4Eb34064E079C8Eca9d7570EBa1d; // OCU
    oracles[4] = 0xc65EF2D17B05ADbd8e4968bCB01b325ab799aBd8; // PECU

    wormholeJoin.file(bytes32("vow"), vow);
    router.file(bytes32("gateway"), masterDomain, address(wormholeJoin));
    vat.rely(address(wormholeJoin));
    bytes32 ilk = wormholeJoin.ilk();
    vat.init(ilk);
    vat.file(ilk, bytes32("spot"), RAY);
    vat.file(ilk, bytes32("line"), globalLine);
    oracleAuth.file(bytes32("threshold"), 1);
    oracleAuth.addSigners(oracles);

    // configure optimism wormhole
    bytes32 slaveDomain = "KOVAN-SLAVE-OPTIMISM-1";
    uint256 optimismSlaveLine = 100 * RAD;
    address constantFees = 0x2aE3853F2B7a410e2789D7Dd38D42FC63eB982e5;
    address slaveDomainBridge = 0x646231dFDAF583E2eB77FEdc47433C30519FF448;
    L1EscrowLike escrow = L1EscrowLike(0x8FdA2c4323850F974C7Abf4B16eD129D45f9E2e2);
    address dai = 0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa;
    GovernanceRelayLike l1GovRelay = GovernanceRelayLike(
      0xAeFc25750d8C2bd331293076E2DC5d5ad414b4a2
    );
    address l2ConfigureDomainSpell = 0x992C01191D62C0C333ef23935978749B50eDbC82;

    router.file(bytes32("gateway"), slaveDomain, slaveDomainBridge);
    wormholeJoin.file(bytes32("fees"), slaveDomain, constantFees);
    wormholeJoin.file(bytes32("line"), slaveDomain, optimismSlaveLine);
    escrow.approve(dai, slaveDomainBridge, type(uint256).max);
    l1GovRelay.relay(l2ConfigureDomainSpell, abi.encodeWithSignature("execute()"), 3_000_000);
  }
}

contract L1KovanAddWormholeDomainSpell is DssExec {
  constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) {}
}