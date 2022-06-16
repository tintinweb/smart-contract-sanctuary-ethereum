/**
 *Submitted for verification at Etherscan.io on 2022-06-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract Contract {
    
    address payable owner;
    uint public health;
    uint public price;
    uint public enemyPosition;
    mapping (address => uint) public balances;
    mapping (address => bool) public isParticipant;
    mapping (address => uint) public playerHealth;
    mapping (address => bool) public isWinner;
    mapping (address => Enemy) public enemy;

    constructor() {
        owner = payable(msg.sender);
        price = 1000 ; // à voir comment mettre le prix correctement
    }

    struct Enemy {
        uint difficulty;
        uint enemyHealth;
    }

    function selectDifficulty (uint _difficulty) external {
        if (_difficulty == 1) {
            enemy[msg.sender] = Enemy(1,1);
        }
        if (_difficulty == 2) {
            enemy[msg.sender] = Enemy(2,2);
        }
        if (_difficulty == 3) {
            enemy[msg.sender] = Enemy(3,3);
        }
    }

    function start() external payable {
        isParticipant[msg.sender] = false;
        require (msg.value == price, "You must deposit 1000 wei"); // à vérifier le "+ price"
        balances[msg.sender] += price;
        isParticipant[msg.sender] = true;
        playerHealth[msg.sender] = 3;
    }

// solo duel
    function soloAttack (uint _position) external OnlyParticipant {
        require(playerHealth[msg.sender] > 0, "You have no more health !");
        require(enemy[msg.sender].enemyHealth > 0, "Enemy is already defeated !");
        enemyPosition = randomNumber();
        playerHealth[msg.sender]--;
        if (_position != enemyPosition) {
            enemy[msg.sender].enemyHealth;         // console.log ?
        } else {
            enemy[msg.sender].enemyHealth--;
            if (enemy[msg.sender].enemyHealth == 0) {
                isWinner[msg.sender] = true;
            }
          }
    }

// random number between 0, 1, 2 and 3
    function randomNumber() private view returns(uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp))) % 4;
    }

    function claimPrice() external payable OnlyParticipant IsWinner {
        uint amount = balances[msg.sender];
        balances[msg.sender] = 0;
        isParticipant[msg.sender] = false;
        isWinner[msg.sender] = false;
        (bool success, ) = msg.sender.call{ value: amount * 2 }("");
        require(success, "Failed to transfer to the sender.");
    }

    function changePrice(uint256 _price) private IsOwner {
        price = _price;
    }

    receive() external payable {}

    function withdraw() external IsOwner {
        owner.transfer(address(this).balance);
    }

    function getHealth() external view returns (uint256) {
        return playerHealth[msg.sender];
    }

    modifier OnlyParticipant {
        require(isParticipant[msg.sender]);
        _;
    }

    modifier IsWinner {
        require(isWinner[msg.sender]);
        _;
    }

    modifier IsOwner {
        require(msg.sender == owner);
        _;
    }
}