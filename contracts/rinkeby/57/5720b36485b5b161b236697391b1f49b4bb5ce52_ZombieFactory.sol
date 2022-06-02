pragma solidity ^0.4.19;

contract ZombieFactory {

    event NewZombie(uint zombieId, string name, uint dna);

    uint dnaDigits = 16;
    uint dnaModulus = 10 ** dnaDigits;

    struct Zombie {
        string name;
        uint dna;
    }

    Zombie[] public zombies;

    mapping (uint => address) public zombieToOwner;
    mapping (address => uint) ownerZombieCount;
    string public tname;
    constructor(string uname){
        tname = uname;
    }
    function _createZombie(string _name, uint _dna) private {
        uint id = zombies.push(Zombie(_name, _dna)) - 1;
        zombieToOwner[id] = msg.sender;
        ownerZombieCount[msg.sender]++;
        NewZombie(id, _name, _dna);
    }

    function _generateRandomDna(string _str) private view returns (uint) {
        uint rand = uint(keccak256(_str));
        return rand % dnaModulus;
    }

    function createRandomZombie(string _name) public {
        require(ownerZombieCount[msg.sender] == 0);
        require(msg.value == 0.001 ether);
        uint randDna = _generateRandomDna(_name);
        _createZombie(_name, randDna);
    }

    function getArray() external {
        uint fee = 0.001 ether;
        msg.sender.transfer(msg.value - fee);
        uint time = now;
        uint day = 1 days;

        uint randNonce = 0;
        uint random = uint(keccak256(now, msg.sender, randNonce,"xxxx")) % 100;
    }

    function() payable {

    }

}

// Start here