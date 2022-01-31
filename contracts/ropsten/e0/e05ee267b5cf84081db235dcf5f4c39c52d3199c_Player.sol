// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.7;

import "./2_character.sol";
import "./3_weapon.sol";
import "./4_armor.sol";
import "./5_shop.sol";
import "./6_token.sol";


contract Player is Character, Weapon, Armor, Shop, Token {
    uint8 public player_level;

    modifier onlyOwner(address _adr){
        require(_adr == owner_address);
        _;
    }

    constructor(string memory _character_name, string memory _character_species, string memory _character_class, string memory _weapon_name){
        character_name = _character_name;
        character_species = _character_species;
        character_class = _character_class;
        weapon_name = _weapon_name;

        health_point = 1000;
        weapon_damage = 69;
        armor_points = 1000;
        player_level = 1;
        balances[msg.sender] = 65535;

        is_in_dungeon = false;

    }

    // Main PvP function
    function Player_attack(address enemy_address) public onlyOwner(msg.sender){

        require(health_point > 0, "You are dead");
            require(Player(enemy_address).health_point() > 0, "The player is dead");
            require(Player(enemy_address).is_in_dungeon() == false, "The player in dungeon");

                Player enemy = Player(enemy_address);

                emit Player_battle(msg.sender, enemy_address, weapon_damage, health_point);

                if (enemy.health_point() == 0){
                    player_level += 1;
                    balances[msg.sender] += 10;

                    emit Player_victory(msg.sender, enemy_address, player_level, balances[msg.sender]);
                }                
    }

    //==========Dungeon Block==========================================================================================
    
    function Player_go_to_the_dungeon() public {
        require(health_point > 0, "You are dead");
            is_in_dungeon = true;
            if (current_monster.monster_health_points <= 0){
                balances[msg.sender] += 10;
            }

            monster_attack(weapon_damage);

            if (armor_points >= current_monster.monster_damage * 20 / 100){
                Character_setHealth(current_monster.monster_damage * 80 / 100);
                Armor_setPoints(current_monster.monster_damage * 20 / 100);
            } else {
                Character_setHealth(current_monster.monster_damage);
            }
  
    }


    function Player_leave_dungeon() public {
        is_in_dungeon = false;
    }

    //==========Block of Upgrade functions==============================================================================

    function Player_cure() public onlyOwner(msg.sender){
        require(balances[msg.sender] > 0, "Not enough score");

            health_point += 50;
            balances[msg.sender] -= 3;

            emit Player_healing(msg.sender, health_point);
    }


    function Player_improveAttack() public onlyOwner(msg.sender){
        require(balances[msg.sender] > 0, "Not enough score");
        require(weapon_upgr_counter < 5, "Max upgrade");
        require(keccak256(abi.encodePacked(weapon_name)) != keccak256(abi.encodePacked("Shaverma")), "YOU GOT SHAVERMA!!!!!!!!");

            weapon_damage += 2;
            weapon_upgr_counter++;
            balances[msg.sender] -= 5;

            emit Player_smithing(msg.sender, weapon_damage);
    }


    function Player_armorFix() public onlyOwner(msg.sender){
        require(balances[msg.sender] > 0, "Not enough score");
        require(wear_counter < 5, "Can not be fixed");

            armor_points = max_armor_points;
            wear_counter++;
            balances[msg.sender] -= 15;

            emit Player_smithing(msg.sender, weapon_damage);
    }

    //==========Block of Shop functions==============================================================================

    function Player_buy_weapon(uint8 _id) public onlyOwner(msg.sender){
        require(balances[msg.sender] >= weapon_shop[_id].product_weapon_cost, "Not enough score");

            weapon_damage = weapon_shop[_id].product_weapon_damage;
            weapon_name = weapon_shop[_id].product_weapon_name;
            weapon_upgr_counter = 0;

            balances[msg.sender] -= weapon_shop[_id].product_weapon_cost;

            emit Player_buying(msg.sender, weapon_shop[_id].product_weapon_name, weapon_shop[_id].product_weapon_cost);

            if (keccak256(abi.encodePacked(weapon_shop[_id].product_weapon_name)) == keccak256(abi.encodePacked("Shaverma"))){
                weapon_shop.pop();
            }

    }
    

    function Player_buy_armor(uint8 _id) public onlyOwner(msg.sender){
        require(balances[msg.sender] >= armor_shop[_id].product_armor_cost, "Not enough score");

            armor_points = armor_shop[_id].product_armor_points;
            max_armor_points = armor_shop[_id].product_armor_points;

            balances[msg.sender] -= armor_shop[_id].product_armor_cost;
            armor_name = armor_shop[_id].product_armor_name;

            wear_counter = 0;
            
            emit Player_buying(msg.sender, armor_shop[_id].product_armor_name, armor_shop[_id].product_armor_cost);

    }
    //==================================================================================================================
}