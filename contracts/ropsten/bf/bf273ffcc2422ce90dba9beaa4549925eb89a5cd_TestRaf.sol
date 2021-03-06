pragma solidity ^0.4.0;
contract owned {
    address public owner;
    constructor() public {
        owner = msg.sender;
    }
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

contract TestRaf is owned {
    
    uint public Raffle_ID;
    //string public Raffle_Prize;
    uint public Total_Entries;
    uint public Date_Started;
    bool public is_Started;
    bool public is_Finished;
    address public Winner;
    uint public getRand;
    uint public winningNumber;
    
    address[] public RaffleWinners;
    address[] public RaffleEntries;
    mapping (address => bool) public Submitted;
    
    event RaffleWinner(address target, uint TotalEntries);
    
    constructor() public {
        is_Started = false;       
        is_Finished = false;
        Raffle_ID = 0;
        RaffleWinners.push(Winner);
    }
    
    function setupRaffle() onlyOwner public {
        require(is_Started == false);
        Raffle_ID += 1;
        is_Started = true;
        is_Finished = false;
        winningNumber = 0;
        delete RaffleEntries;
    }

    function addEntry(address _target) onlyOwner public {
        require(Submitted[_target] == false);
        RaffleEntries.push(_target);
        Submitted[_target] = true;
        Total_Entries = RaffleEntries.length;
        getRand =  random(); //uint(blockhash(block.number-1)) % RaffleEntries.length;
    }
    function raffleDraw() onlyOwner public {
        _raffleDraw();
    }
    function _raffleDraw() private {
        require(is_Started == true);
        require(is_Finished == false);
        uint winnerIndex = random();
        winningNumber = winnerIndex;
        Winner = RaffleEntries[winnerIndex];
        RaffleWinners.push(Winner);
        emit RaffleWinner(Winner, RaffleEntries.length);
        is_Finished = true;
        is_Started = false;
    }
    
    function random() private view returns (uint8) {
        return uint8(uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty))) % RaffleEntries.length);
    }
    
    function shutdown() onlyOwner public {
        selfdestruct(owner);
    }
    
}