/**
 *Submitted for verification at Etherscan.io on 2023-02-15
*/

// SPDX-License-Identifier: GPL-3.0
 
pragma solidity 0.8.17;

contract Casino {
    mapping(address => uint[]) dealer;
    mapping(address => uint[]) player;
    mapping(address => uint) bids;
    mapping(address => bool) gameStarted;
    mapping(address => uint[]) deck;
    mapping(address => uint[]) cards_tmp;

    uint multiplier;

    uint last_random = 1;
    
    constructor(uint _multiplier){
        multiplier = _multiplier;
    }

    function generateCard(address addr) public returns (uint){
        delete cards_tmp[addr];
        for (uint256 i = 0; i < deck[addr].length; i++) {
            if(deck[addr][i] != 0){
                cards_tmp[addr].push(deck[addr][i]);
            }
        } 
        uint lr = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, msg.sender, last_random)));
        uint rand_it = lr % cards_tmp[addr].length;
        uint result = cards_tmp[addr][rand_it];
        deck[addr][rand_it] = 0;
        last_random = lr;
        return result;
    }

    function sumOnArray(uint[] memory array) pure internal returns (uint result){
        for (uint i = 0; i < array.length; i++) {
            result += array[i];
        }
        return result;
    }

    function startGame() payable public returns(uint[] memory, uint[] memory){
        require(!gameStarted[msg.sender], "You have already started the game.");
        gameStarted[msg.sender] = true;
        bids[msg.sender] = msg.value;
        uint8[40] memory _deck = [2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 
                                2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 
                                2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 
                                2, 3, 4, 5, 6, 7, 8, 9, 10, 11];
        deck[msg.sender] = _deck;
        uint[] memory dealer_cards = new uint[](12);
        uint[] memory your_cards = new uint[](12);
        your_cards[0] = generateCard(msg.sender);
        for (uint i = 0; i < 2; i++) {
            dealer_cards[i] = generateCard(msg.sender);
        }
        dealer[msg.sender] = dealer_cards;
        player[msg.sender] = your_cards;
        return (dealer_cards, your_cards);
    }

    function move() public returns(uint[] memory, uint[] memory){
        require(gameStarted[msg.sender], "You must first start the game.");
        require(sumOnArray(player[msg.sender]) <= 21, "You lost. Stop game and start a new one.");
        uint it = 0;
        while(player[msg.sender][it] != 0){
            it++;
        }
        player[msg.sender][it] = generateCard(msg.sender);
        return (dealer[msg.sender], player[msg.sender]);
    }

    function stopGame() payable public returns(bool){
        require(gameStarted[msg.sender], "You must first start the game.");
        uint win = bids[msg.sender] * multiplier / 100;
        delete player[msg.sender];
        delete dealer[msg.sender];
        gameStarted[msg.sender] = false;
        delete bids[msg.sender];
        delete deck[msg.sender];
        if(sumOnArray(player[msg.sender]) > 21){
            return false;
        }else{
            if(sumOnArray(dealer[msg.sender]) > 21){
                payable(msg.sender).transfer(win);
                return true;
            }else if(sumOnArray(dealer[msg.sender]) > sumOnArray(player[msg.sender])){
                return false;
            }else{
                payable(msg.sender).transfer(win);
                return true;
            }
        }
    }
}