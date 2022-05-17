pragma solidity ^0.8.0;

contract Hipogame {
    mapping(address => Twice) public gameLists;
    mapping(address => uint256) public balances;
    address public owner;
    uint256 public roomprice = 0.05 ether;
    
    struct Twice {
        address first;
        address second;
        bool status;
    }

    constructor() public {
        owner = msg.sender;
    }

    function addFund() public payable {
        balances[msg.sender] += msg.value;
    }

    function withdraw(uint256 _amount) public {
        uint256 curAmount = balances[msg.sender];
        require(curAmount >= _amount, "too much amount.");
        balances[msg.sender] -= _amount;
        payable(msg.sender).transfer(_amount);
    }

    function createRoom() public {
        require(balances[msg.sender] >= roomprice, "Can't create this room.");
        balances[msg.sender] -= roomprice;
        gameLists[msg.sender] = Twice(msg.sender, address(0), false);
    }

    function joinRoom(address _room) public {
        require(balances[msg.sender] >= roomprice, "Can't create this room.");
        balances[msg.sender] -= roomprice;
        require(gameLists[_room].status == false, "Game is already started!");
        gameLists[_room].second = msg.sender;
        gameLists[_room].status = true;
    }

    function gameOver(address _room , address _winner) public {
        require(msg.sender == owner, "This game is controlled by only owner!");
        require(gameLists[_room].status == true, "Game is not started!");
        require(gameLists[_room].first == _winner || gameLists[_room].second == _winner, "winner address is wrong!");
        balances[_winner] += roomprice * 2 *95 / 100;
    }

    function claim() public {
        require(msg.sender == owner, "This function is allowed by only owner!");
        payable(msg.sender).transfer(address(this).balance);
    }
}