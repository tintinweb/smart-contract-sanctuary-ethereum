/**
 *Submitted for verification at Etherscan.io on 2022-07-30
*/

//SPDX-License-Identifier: MIT
pragma solidity >= 0.8.7;


contract Ranking{

    address owner;
    uint leaderboardLength = 100;
    mapping(uint => User) public leaderboard;
    uint new_ = 0;


    struct User{
        string user;
        uint score;
        address _address;

    }

    function add_member ( string memory n_user, uint256 n_score, address n_address) public returns (bool transaction){

        leaderboard [new_] = User({
            user: n_user,
            score: n_score,
            _address: n_address
        });

        new_ = new_ + 1;
        transaction = true;

        return transaction;

    }

    function view_user(uint n) public view returns (string memory _user){

        _user = leaderboard[n].user;
        return _user;
    }

    function view_address(uint n) public view returns (address v_address){

        v_address = leaderboard[n]._address;
        return v_address;
    }

    function view_score (uint n) public view returns (uint v_score){
        v_score = leaderboard[n].score;
        return v_score;
         }

}