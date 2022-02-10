/**
 *Submitted for verification at Etherscan.io on 2022-02-09
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

interface WormholeJoinLike {
  function file(
    bytes32 what,
    bytes32 domain_,
    uint256 data
  ) external;

  function file(
    bytes32 what,
    bytes32 domain_,
    address data
  ) external;
}

interface RouterLike {
  function file(
    bytes32 what,
    bytes32 domain,
    address data
  ) external;
}

interface L1Escrow {
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

contract L1AddWormholeDomainSpell {
  uint256 public constant RAY = 10**27;

  bytes32 public immutable slaveDomain;

  WormholeJoinLike public immutable wormholeJoin;
  address public immutable constantFees;

  uint256 public immutable line;

  RouterLike public immutable router;
  address public immutable slaveDomainBridge;

  L1Escrow public immutable escrow;
  address public immutable dai;

  GovernanceRelayLike public immutable l1GovRelay;
  address public immutable l2ConfigureDomainSpell;

  constructor(
    bytes32 _slaveDomain,
    WormholeJoinLike _wormholeJoin,
    address _constantFees,
    uint256 _line,
    RouterLike _router,
    address _slaveDomainBridge,
    L1Escrow _escrow,
    address _dai,
    GovernanceRelayLike _l1GovRelay,
    address _l2ConfigureDomainSpell
  ) {
    slaveDomain = _slaveDomain;
    wormholeJoin = _wormholeJoin;
    constantFees = _constantFees;
    line = _line;
    router = _router;
    slaveDomainBridge = _slaveDomainBridge;
    escrow = _escrow;
    dai = _dai;
    l1GovRelay = _l1GovRelay;
    l2ConfigureDomainSpell = _l2ConfigureDomainSpell;
  }

  function execute() external {
    router.file(bytes32("gateway"), slaveDomain, slaveDomainBridge);

    wormholeJoin.file(bytes32("fees"), slaveDomain, constantFees);
    wormholeJoin.file(bytes32("line"), slaveDomain, line);

    escrow.approve(dai, slaveDomainBridge, type(uint256).max);

    l1GovRelay.relay(l2ConfigureDomainSpell, abi.encodeWithSignature("execute()"), 3_000_000);
  }
}