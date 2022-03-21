/**
 *Submitted for verification at Etherscan.io on 2022-03-21
*/

//SPDX-License-Identifier: GPL-3.0

        pragma solidity ^0.8.0;

        contract loteria{

            address payable[] public players;
            address public manager;

            constructor(){
                manager = msg.sender;
            }

            receive() external payable{
                require(msg.value == 0.1 ether, "valor incorreto");
                players.push(payable(msg.sender));
            }

            function getbalance() public view returns(uint){
                require(msg.sender == manager, "apenas o manager ");
                return address(this).balance;
            }

            function random() public view returns(uint){
                return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players.length)));
            }

            function pickwinner() public{
                require(msg.sender==manager);
                require(players.length >=3);

                uint r = random();
                address payable winner;

                uint index = r % players.length;
                winner = players[index];

                winner.transfer(getbalance());

                players = new address payable[](0);
            }

        }