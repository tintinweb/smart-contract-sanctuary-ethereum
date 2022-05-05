/**
 *Submitted for verification at Etherscan.io on 2022-05-05
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

pragma solidity 0.8.13;

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

interface TrustedRelayLike {
  function file(bytes32 what, uint256 data) external;

  function kiss(address usr) external;

  function ethPriceOracle() external view returns (address);
}

interface MedianLike {
  function kiss(address usr) external;
}

contract DssSpellAction is DssAction {
  string public constant override description = "Kovan Optimism TrustedRelay configuration spell";

  function officeHours() public pure override returns (bool) {
    return false;
  }

  function actions() public override {
    TrustedRelayLike trustedRelay = TrustedRelayLike(0xAAFa36901AdC6C03df8B935fFA129677D1D7Eb81);
    MedianLike median = MedianLike(trustedRelay.ethPriceOracle());
    median.kiss(address(trustedRelay));
  }
}

contract L1KovanConfigureTrustedRelaySpell is DssExec {
  constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) {}
}