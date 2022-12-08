/**
 *Submitted for verification at Etherscan.io on 2022-12-08
*/

pragma solidity >=0.7.0 <0.9.0;

interface USDC {
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract FlipBank {
    USDC private USDc;
    address private _owner;
    uint private rooms;
    uint private _rate;

    struct Player {
        uint index;
        uint side;
        uint winner;
        uint256 amount;
        address player1;
        address player2; 
        string status;  // true: wait false: init 
        uint update;
    }

    Player[] private players;

    constructor() {
        USDc = USDC(0xA2025B15a1757311bfD68cb14eaeFCc237AF5b43);
        _owner = msg.sender; 
        _rate = 20;
    }  
   
    event msgGame(Player[], uint, string);
    event msgService(string, uint, address);

    function initGame(uint number_rooms) public {
        require(msg.sender == _owner, "No permission");
        delete players;
        rooms = number_rooms;
        for(uint i = 0; i < rooms; i++){
            Player memory player = Player({index: i, side: 0, winner: 2, amount: 0, player1: address(0), player2: address(0), status: "init", update: block.timestamp});
            players.push(player);
        }     
        emit msgGame(players, 0, "flip_inited");       
        emit msgService("Init Game", block.timestamp, msg.sender);
    }

    function openFlip(uint side, uint256 amount) public {
        require(amount>0, "Amount should be greater than 0");
        require(( 0 <= side && side < 2 ), "Out of range");
        bool hasRoom = false;
        for(uint i = 0; i < rooms; i++) { 
            if( keccak256(abi.encodePacked(players[i].status)) == keccak256(abi.encodePacked("init")) ){
                Player memory player = Player({index: i, side: side, winner: 2, amount: amount, player1: msg.sender, player2: address(0), status: "wait", update: block.timestamp});
                players[i] = player;
                USDc.transferFrom(msg.sender, address(this), amount);
                hasRoom = true; 
                emit msgGame(players, i, "flip_created");
                break;
            }
        }
        if(!hasRoom) {
            emit msgService("no rest room", block.timestamp, msg.sender);
            require(hasRoom, "no rest room");
        }
    }  

    function closeFlip(uint index, uint256 amount) public {
        require((index >= 0 && index < rooms), "Out of Rooms");
        require(players[index].amount == amount, "Logic Error");
        USDc.transferFrom(msg.sender, address(this), amount);
        uint _side = uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender))) % 2;
        Player memory player = Player({index: index, side: players[index].side, winner: _side, amount: players[index].amount, player1: players[index].player1, player2: msg.sender, status: "init", update: block.timestamp});
        players[index] = player;
        if(_side == player.side) {
            USDc.transfer(player.player1, amount * 2 * (100 - _rate) / 100);
        }else {
            USDc.transfer(player.player2, amount * 2 * (100 - _rate) / 100);
        }    
        emit msgGame(players, index, "flip_closed");
        emit msgService("flip_closed", index, msg.sender);   
        USDc.transfer(_owner, amount * 2 * _rate / 100);     
    }  


}