/**
 *Submitted for verification at Etherscan.io on 2022-06-12
*/

// SPDX-License-Identifier: MIT

pragma solidity  >=0.4.22 <0.9.0;

contract refer{
    
struct User {
    bool referred;
    address referred_by;
}

struct Referal_levels {
    uint256 level_1;
    uint256 level_2;
    uint256 level_3;
    uint256 level_4;
    uint256 level_5;
    uint256 level_6;
    uint256 level_7;
    uint256 level_8;
    uint256 level_9;
    uint256 level_10;
}

mapping(address => Referal_levels) public refer_info;
mapping(address => User) public user_info;

function referee(address ref_add) public {
        require(user_info[msg.sender].referred == false, " Already referred ");
        require(ref_add != msg.sender, " You cannot refer yourself ");

        user_info[msg.sender].referred_by = ref_add;
        user_info[msg.sender].referred = true;

        address level1 = user_info[msg.sender].referred_by;
        address level2 = user_info[level1].referred_by;
        address level3 = user_info[level2].referred_by;
        address level4 = user_info[level3].referred_by;
        address level5 = user_info[level4].referred_by;
        address level6 = user_info[level5].referred_by;
        address level7 = user_info[level6].referred_by;
        address level8 = user_info[level7].referred_by;
        address level9 = user_info[level8].referred_by;
        address level10 = user_info[level9].referred_by;

        if ((level1 != msg.sender) && (level1 != address(0))) {
            refer_info[level1].level_1 += 1;
        }
        if ((level2 != msg.sender) && (level2 != address(0))) {
            refer_info[level2].level_2 += 1;
        }
        if ((level3 != msg.sender) && (level3 != address(0))) {
            refer_info[level3].level_3 += 1;
        }
        if ((level4 != msg.sender) && (level4 != address(0))) {
            refer_info[level4].level_4 += 1;
        }
        if ((level5 != msg.sender) && (level5 != address(0))) {
            refer_info[level5].level_5 += 1;
        } 
        if ((level6 != msg.sender) && (level6 != address(0))) {
            refer_info[level6].level_6 += 1;
        } 
        if ((level7 != msg.sender) && (level7 != address(0))) {
            refer_info[level7].level_7 += 1;
        } 
        if ((level8 != msg.sender) && (level8 != address(0))) {
            refer_info[level8].level_8 += 1;
        }
        if ((level9 != msg.sender) && (level9 != address(0))) {
            refer_info[level9].level_9 += 1;
        }
        if ((level10 != msg.sender) && (level10 != address(0))) {
            refer_info[level10].level_10 += 1;
        }                 
}

}