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

import {DssExec} from "./DssExec.sol";
import {DssAction} from "./DssAction.sol";

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
    WormholeJoinLike wormholeJoin = WormholeJoinLike(0x556D9076A42Bba1892E3F4cA331daE587185Cef9);
    address vow = 0x0F4Cbe6CBA918b7488C26E29d9ECd7368F38EA3b;
    VatLike vat = VatLike(0xbA987bDB501d131f766fEe8180Da5d81b34b69d9);
    uint256 globalLine = 10000000000 * RAD;
    RouterLike router = RouterLike(0xb15e4cfb29C587c924f547c4Fcbf440B195f3EF8);
    OracleAuthLike oracleAuth = OracleAuthLike(0x0b0D629e294Af96A6cc245a89A5CEa92C8Be9da4);
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
    address constantFees = 0xf61A6F9d13aF9BBf4df95657Db5698c04A97EF85;
    address slaveDomainGateway = 0xBD8605d11b8D3557b7399eFE1866992Eed6F9A7c;
    L1EscrowLike escrow = L1EscrowLike(0x8FdA2c4323850F974C7Abf4B16eD129D45f9E2e2);
    address dai = 0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa;
    GovernanceRelayLike l1GovRelay = GovernanceRelayLike(
      0xAeFc25750d8C2bd331293076E2DC5d5ad414b4a2
    );
    address l2ConfigureDomainSpell = 0xEd326504C77Dcd0Ffbb554a7925338EEd3F5fE01;

    router.file(bytes32("gateway"), slaveDomain, slaveDomainGateway);
    wormholeJoin.file(bytes32("fees"), slaveDomain, constantFees);
    wormholeJoin.file(bytes32("line"), slaveDomain, optimismSlaveLine);
    escrow.approve(dai, slaveDomainGateway, type(uint256).max);
    l1GovRelay.relay(l2ConfigureDomainSpell, abi.encodeWithSignature("execute()"), 3_000_000);
  }
}

contract L1KovanAddWormholeDomainSpell is DssExec {
  constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) {}
}