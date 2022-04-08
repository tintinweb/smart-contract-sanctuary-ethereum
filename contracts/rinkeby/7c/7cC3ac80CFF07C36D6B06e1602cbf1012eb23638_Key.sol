pragma solidity ^0.6.0;

import "GatekeeperOne.sol";

contract Key {
    GatekeeperOne gk;

    constructor() public {
        address GatekeeperOneAddress = 0x9b261b23cE149422DE75907C6ac0C30cEc4e652A;
        gk = GatekeeperOne(GatekeeperOneAddress);
    }

    function exploit(bytes8 _gateKey) public {
        gk.enter(_gateKey);
    }
}