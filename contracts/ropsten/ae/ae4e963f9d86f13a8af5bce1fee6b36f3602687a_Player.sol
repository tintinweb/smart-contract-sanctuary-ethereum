pragma solidity >=0.8.7;
import "./2_character.sol";
import "./3_weapon.sol";

contract Player is Character, Weapon{
    string[] defeatedPlayers;
    string public wasDefeated;
    uint public level;
    uint public score;

    constructor (string memory _name, string memory _race, string memory _class, string memory _weapon){
        name = _name;
        race = _race;
        class = _class;
        weaponName = _weapon;
        health = 100;
        damage = 10;
        level = 1;
        score = 0;
        owner = msg.sender;
        wasDefeated = "was not defeated";
    }

    modifier isOwner() {
        require(msg.sender == owner);
        _;
    }

    event Attack(address attacking, address defeating, uint damage, uint health);
    event Win(address winner, address loser, uint level, uint score);
    event Treatment(address player, uint health, uint score);
    event AttackEncreasing(address player, uint damage, uint score);

    function attack(address enemy) isOwner public{
        require(health > 0, "You are dead");
        require(Player(enemy).health() > 0, "The player is dead dead");
        Player(enemy).setHealth(damage);
        emit Attack(msg.sender, enemy, damage, Player(enemy).health());
        if (Player(enemy).health() == 0){
            level += 1;
            score += 5;
            emit Win(msg.sender, enemy, level, score);
            defeatedPlayers.push(Player(enemy).name());
        }
    }

    function getDefeated() public view returns (string[] memory){
        return defeatedPlayers;
    }

    function setHealth(uint8 damage) override external {
        if (damage > health){
            health = 0;
            wasDefeated = Player(msg.sender).name();
            emit Win(msg.sender, owner, Player(msg.sender).level(), Player(msg.sender).score());
        }
        else{
            health -= damage;
        }
        emit Attack(msg.sender, owner, damage, health);
    }

    function cure() isOwner public{
        if (score > 0){
            score--;
            health += 5;
            emit Treatment(owner, health, score);
        }
    }

    function improveAttack() isOwner public {
        if (score > 0){
            damage++;
            score--;
            emit AttackEncreasing(owner, damage, score);
        }
    }
}