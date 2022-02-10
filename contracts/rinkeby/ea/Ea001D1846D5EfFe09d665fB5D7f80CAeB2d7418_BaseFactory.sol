// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./ZombieOwnership.sol";

/// @dev this is a base factory that wrap all contract, because this is the last node in contract tree that already inherit all contract

contract BaseFactory is ZombieOwnership {

}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ZombieAttack.sol";

abstract contract ZombieOwnership is ZombieAttack, ERC721 {
    using SafeMath for uint256;

    mapping(uint256 => address) zombieApprovals;

    function balanceOf(address _owner)
        external
        view
        override
        returns (uint256)
    {
        return ownerZombieCount[_owner];
    }

    function ownerOf(uint256 _zombieId)
        external
        view
        override
        returns (address)
    {
        return zombieToOwner[_zombieId];
    }

    function _transfer(
        address _from,
        address _to,
        uint256 _zombieId
    ) private {
        ownerZombieCount[_to].add(1);
        ownerZombieCount[_from].sub(1);
        zombieToOwner[_zombieId] = _to;
        emit Transfer(_from, _to, _zombieId);
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _zombieId
    ) external payable override {
        require(
            zombieToOwner[_zombieId] == msg.sender ||
                zombieApprovals[_zombieId] == msg.sender
        );
        _transfer(_from, _to, _zombieId);
    }

    function approve(address _approved, uint256 _zombieId)
        external
        payable
        override
        onlyOwnerOf(_zombieId)
    {
        zombieApprovals[_zombieId] = _approved;
        emit Approval(msg.sender, _approved, _zombieId);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/// @dev Tokens, the ERC721 standard, and tradable assets/zombies

abstract contract ERC721 {
    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 indexed _tokenId
    );
    event Approval(
        address indexed _owner,
        address indexed _approved,
        uint256 indexed _tokenId
    );

    function balanceOf(address _owner) external view virtual returns (uint256);

    function ownerOf(uint256 _tokenId) external view virtual returns (address);

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external payable virtual;

    function approve(address _approved, uint256 _tokenId)
        external
        payable
        virtual;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./ZombieHelper.sol";

contract ZombieAttack is ZombieHelper {
    using SafeMath for uint256;

    uint256 randNonce = 0;
    uint256 attackVictoryProbability = 70;

    // random modulus 100
    function randMod(uint256 _modulus) internal view returns (uint256) {
        randNonce.add(1);
        return
            uint256(
                keccak256(
                    abi.encodePacked(block.timestamp, msg.sender, randNonce)
                )
            ) % _modulus;
    }

    function attack(uint256 _zombieId, uint256 _targetId)
        external
        onlyOwnerOf(_zombieId)
    {
        Zombie storage myZombie = zombies[_zombieId];
        Zombie storage enemyZombie = zombies[_targetId];
        uint256 rand = randMod(100);
        if (rand <= attackVictoryProbability) {
            myZombie.winCount++;
            myZombie.level++;
            enemyZombie.loseCount++;
            feedAndMultiply(_zombieId, enemyZombie.dna, "zombie");
        } else {
            myZombie.loseCount++;
            enemyZombie.winCount++;
            _triggerCooldown(myZombie);
        }
    }

    function getEnemies(uint256 level) external view returns (Zombie[] memory) {
        Zombie[] memory result = new Zombie[](zombies.length);

        uint256 counter = 0;

        for (uint256 i = 0; i < zombies.length; i++) {
            if (zombieToOwner[i] != msg.sender && zombies[i].level == level) {
                result[counter] = zombies[i];
                counter++;
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./ZombieFeeding.sol";

contract ZombieHelper is ZombieFeeding {
    uint256 levelUpFee = 0.001 ether;

    modifier aboveLevel(uint256 _level, uint256 _zombieId) {
        require(zombies[_zombieId].level >= _level);
        _;
    }

    function withdraw() external onlyOwner {
        address payable _owner = payable(owner());
        _owner.transfer(address(this).balance);
    }

    function setLevelUpFee(uint256 _fee) external onlyOwner {
        levelUpFee = _fee;
    }

    function levelUp(uint256 _zombieId) external payable {
        require(msg.value == levelUpFee);
        zombies[_zombieId].level += 1;
    }

    function changeName(uint256 _zombieId, string calldata _newName)
        external
        aboveLevel(_zombieId, 2)
        onlyOwnerOf(_zombieId)
    {
        zombies[_zombieId].name = _newName;
    }

    function changeDna(uint256 _zombieId, uint256 _newDna)
        external
        aboveLevel(_zombieId, 20)
        onlyOwnerOf(_zombieId)
    {
        zombies[_zombieId].dna = _newDna;
    }

    function getZombiesByOwner(address _owner)
        external
        view
        returns (Zombie[] memory)
    {
        Zombie[] memory result = new Zombie[](ownerZombieCount[_owner]);

        uint256 counter = 0;

        for (uint256 i = 0; i < zombies.length; i++) {
            if (zombieToOwner[i] == _owner) {
                result[counter] = zombies[i];
                counter++;
            }
        }

        return result;
    }

    // pure function not access any data from contract
    function _multiply(uint256 a, uint256 b) private pure returns (uint256) {
        return a * b;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./ZombieFactory.sol";

abstract contract KittyInterface {
    function getKitty(uint256 _id)
        external
        view
        virtual
        returns (
            bool isGestating,
            bool isReady,
            uint256 cooldownIndex,
            uint256 nextActionAt,
            uint256 siringWithId,
            uint256 birthTime,
            uint256 matronId,
            uint256 sireId,
            uint256 generation,
            uint256 genes
        );
}

contract ZombieFeeding is ZombieFactory {
    KittyInterface kittyContract;

    modifier onlyOwnerOf(uint256 _zombieId) {
        require(msg.sender == zombieToOwner[_zombieId]);
        _;
    }

    function setKittyContractAddress(address _address) external onlyOwner {
        kittyContract = KittyInterface(_address);
    }

    function _triggerCooldown(Zombie storage _zombie) internal {
        _zombie.readyTime = uint32(block.timestamp + cooldownTime);
    }

    function _isReady(Zombie storage _zombie) internal view returns (bool) {
        return (_zombie.readyTime <= block.timestamp);
    }

    function feedAndMultiply(
        uint256 _zombie_id,
        uint256 _targetDna,
        string memory _species
    ) internal onlyOwnerOf(_zombie_id) {
        Zombie storage myZombie = zombies[_zombie_id];

        require(_isReady(myZombie));

        uint256 newDna = (myZombie.dna + (_targetDna % dnaModulus)) / 2;

        if (
            keccak256(abi.encodePacked(_species)) ==
            keccak256((abi.encodePacked("kitty")))
        ) {
            newDna = newDna - (newDna % 100) + 99;
        }

        _createZombie("NoName", newDna);
        _triggerCooldown(myZombie);
    }

    function feedOnKitty(uint256 _zombieId, uint256 _kittyId) public {
        uint256 kittyDna;
        (, , , , , , , , , kittyDna) = kittyContract.getKitty(_kittyId);
        feedAndMultiply(_zombieId, kittyDna, "kitty");
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./SafeMath.sol";

/// @title A contract CryptoZombie
/// @author bws
/// @notice this project is just personal learning purpose

contract ZombieFactory is Ownable {
    using SafeMath for uint256;

    event NewZombie(uint256 zombieId, string name, uint256 dna);

    uint256 cooldownTime = 30 seconds;

    uint256 dnaDigits = 16;
    uint256 dnaModulus = 10**dnaDigits;

    struct Zombie {
        string name;
        uint256 id;
        uint256 dna;
        uint32 level;
        uint32 readyTime;
        uint16 winCount;
        uint16 loseCount;
    }

    Zombie[] public zombies;

    mapping(uint256 => address) public zombieToOwner;
    mapping(address => uint256) ownerZombieCount;

    /// @dev This function for create zombie
    function _createZombie(string memory _name, uint256 _dna) internal {
        uint256 id = zombies.length;
        zombies.push(
            Zombie(
                _name,
                id,
                _dna,
                1,
                uint32(block.timestamp + cooldownTime),
                0,
                0
            )
        );
        zombieToOwner[id] = msg.sender;
        ownerZombieCount[msg.sender] += 1;
        emit NewZombie(id, _name, _dna);
    }

    function _generateRandomDna(string memory _str)
        private
        view
        returns (uint256)
    {
        uint256 rand = uint256(keccak256(abi.encodePacked(_str)));
        return rand % dnaModulus;
    } /** view: only read data from contract without modify */

    function createRandomZombie(string memory _name) public {
        require(
            ownerZombieCount[msg.sender] == 0,
            "You already have one zombie"
        );
        uint256 randDna = _generateRandomDna(_name);
        _createZombie(_name, randDna);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * @notice Renouncing to ownership will leave the contract without an owner.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/// @dev this library is to prevent overflows and underflows

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    /**
     * @dev Multiplies two numbers, throws on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
     * @dev Integer division of two numbers, truncating the quotient.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    /**
     * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
     * @dev Adds two numbers, throws on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}