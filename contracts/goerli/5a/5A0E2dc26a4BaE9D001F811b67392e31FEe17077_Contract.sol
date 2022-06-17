/**
 *Submitted for verification at Etherscan.io on 2022-06-17
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
        price = 1000 wei ; // à voir comment mettre le prix correctement
    }

    struct Enemy {
        uint difficulty;
        uint enemyHealth;
        uint enemyPosition;
    }

    function start() external payable {
        enemy[msg.sender] = Enemy(0,0,0);
        isParticipant[msg.sender] = false;
        require (msg.value == price, "You must deposit 1000 wei"); // à vérifier le "+ price"
        balances[msg.sender] += price;
        isParticipant[msg.sender] = true;
        playerHealth[msg.sender] = 3;
    }

    function selectDifficulty (uint _difficulty) external OnlyParticipant DifficultyIsSet {
        if (_difficulty == 1) {
            enemy[msg.sender] = Enemy(1,1,0);
        }
        if (_difficulty == 2) {
            enemy[msg.sender] = Enemy(2,2,0);
        }
        if (_difficulty == 3) {
            enemy[msg.sender] = Enemy(3,3,0);
        }
    }

// solo duel
    function soloAttack (uint _position) external OnlyParticipant {
        require(playerHealth[msg.sender] > 0, "You have no more health !");
        require(enemy[msg.sender].enemyHealth > 0, "Enemy is already defeated !");
        require((2 - _position) >=0, "Your position should be between 0 and 2");
        
        enemy[msg.sender].enemyPosition = randomNumber();
        playerHealth[msg.sender]--;
        
        if (playerHealth[msg.sender] == 0 && enemy[msg.sender].enemyHealth > 0) {
            isParticipant[msg.sender] = false;
            balances[msg.sender] = 0;
        }
        if (_position == enemy[msg.sender].enemyPosition) {
            enemy[msg.sender].enemyHealth--;
            if (enemy[msg.sender].enemyHealth == 0 && playerHealth[msg.sender] >= 0) {
                isWinner[msg.sender] = true;
            }
          }
    }

// random number between 0, 1 and 2
    function randomNumber() private view returns(uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp))) % 3;
    }

    function claimPrice() external payable OnlyParticipant OnlyWinner {
        uint amount = balances[msg.sender];
        balances[msg.sender] = 0;
        isParticipant[msg.sender] = false;
        isWinner[msg.sender] = false;
        playerHealth[msg.sender] = 0;
        enemy[msg.sender] = Enemy(0,0,0);
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

    function getHealth() public view returns (uint256) {
        return playerHealth[msg.sender]; 
    }

    function getEnemyHealth() public view returns (uint256) {
        return enemy[msg.sender].enemyHealth;
    }    

    function getIsParticipant() public view returns (string memory) {
        if (isParticipant[msg.sender]) {
            return "Yes";
        } else {
            return "No";
        }
    }
    
    function getIsWinner() public view returns (string memory) {
        if (isWinner[msg.sender]) {
            return "Yes, you did it !";
        } else {
            return "Not yet";
        }
    }

    function getInGameBalance() public view returns (uint) {
        return balances[msg.sender];
    }

    function getDifficulty() public view returns (string memory) {
        if (enemy[msg.sender].difficulty == 1) {
            return "Easy";
        }
        else if (enemy[msg.sender].difficulty == 2) {
            return "Normal";
        }
        else {
            return "Hard";
        }
    } 
    
    function getEnemyLastPos() public view returns (uint) {
        return enemy[msg.sender].enemyPosition;
    } 

    modifier OnlyParticipant {
        require(isParticipant[msg.sender], "You have to be a participant");
        _;
    }

    modifier OnlyWinner {
        require(isWinner[msg.sender], "You have to defeat the enemy");
        _;
    }

    modifier IsOwner {
        require((msg.sender == owner), "You have to be the owner");
        _;
    }

    modifier DifficultyIsSet {
        require((enemy[msg.sender].difficulty == 0), "You already choose your difficulty");
        _;
    }
}