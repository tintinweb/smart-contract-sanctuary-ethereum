/**
 *Submitted for verification at Etherscan.io on 2022-02-02
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
  function settle(bytes32 sourceDomain, uint256 batchedDaiToFlush) external;
}

interface VatLike {
  function suck(
    address u,
    address v,
    uint256 rad
  ) external;
}

interface DaiJoinLike {
  function exit(address usr, uint256 wad) external;
}

contract TestBadDebtPushSpell {
  uint256 public constant RAY = 10**27;

  WormholeJoinLike public immutable wormholeJoin;
  VatLike public immutable vat;
  DaiJoinLike public immutable daiJoin;
  address public immutable vow;
  bytes32 public immutable sourceDomain;
  uint256 public immutable badDebt;

  constructor(
    WormholeJoinLike _wormholeJoin,
    VatLike _vat,
    DaiJoinLike _daiJoin,
    address _vow,
    bytes32 _sourceDomain,
    uint256 _badDebt
  ) {
    wormholeJoin = _wormholeJoin;
    vat = _vat;
    daiJoin = _daiJoin;
    vow = _vow;
    sourceDomain = _sourceDomain;
    badDebt = _badDebt;
  }

  function execute() external {
    vat.suck(vow, address(this), badDebt * RAY);
    daiJoin.exit(address(wormholeJoin), badDebt);
    wormholeJoin.settle(sourceDomain, badDebt);
  }
}