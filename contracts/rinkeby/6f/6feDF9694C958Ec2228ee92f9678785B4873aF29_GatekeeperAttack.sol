pragma solidity ^0.8.10;

interface GatekeeperOne {
  function enter(bytes8 _gateKey) external returns (bool);
}

contract GatekeeperAttack {
    function attack(address _address, bytes8 _gateKey) external {
        GatekeeperOne(_address).enter(_gateKey);
    }
}