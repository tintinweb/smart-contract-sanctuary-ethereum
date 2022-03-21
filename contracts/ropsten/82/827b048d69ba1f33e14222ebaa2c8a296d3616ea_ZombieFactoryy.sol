/**
 *Submitted for verification at Etherscan.io on 2022-03-20
*/

pragma solidity ^0.4.19;

contract ZombieFactoryy {

    uint dnaDigits = 16;
    uint dnaModulus = 10 ** dnaDigits;

    struct Zombie {
        string name;
        uint dna;
    }

    Zombie[] public zombies;

    function _createZombie(string _name, uint _dna) private {
        zombies.push(Zombie(_name, _dna));
    }
}