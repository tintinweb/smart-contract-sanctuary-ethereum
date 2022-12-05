/**
 *Submitted for verification at Etherscan.io on 2022-12-04
*/

//SPDX-License-Identifier: MIT

pragma solidity 0.8.8;

contract FortuneWheel{

    address[] public players_adress; 
    uint256 public players_number;


    uint256 immutable capacity;  
    constructor () {
          capacity = 3;
    }

    mapping (address => uint) times_play;   

    function Play() external payable{
        //accept only 0.01 ETH 
        //everyone can pay one time for the roude 
            require(times_play[msg.sender] == 0, "You can use only one ticket for this Fortune");
                uint256 play_value = 1e16;
                    require(msg.value == play_value, "You must pay exaclly 0.01 ETH");
                        
                        times_play[msg.sender]++;
                        players_adress.push(msg.sender);
                        players_number = players_adress.length;
                        if (players_number == capacity){
                            Winner();
                        }

    }

    function Winner() internal{
        
            (bool callSuccess, ) = msg.sender.call{value: address(this).balance}("");
            require(callSuccess, "Transfer awards Failed");

                //init all varaibles of players
                for(uint256 i = 0; i < players_number; i++){
                        times_play[players_adress[i]] = 0;
                }
                players_adress = new address[](0);
                players_number = players_adress.length;
    }

    
}