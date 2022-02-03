/**
 *Submitted for verification at Etherscan.io on 2022-02-03
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

//TODO:
//Get a script to estimate gas cost
//Fix overlaping players
//Write unit tests
//Make a BattleRoyaleDeployer
//Abstract Vault
//Make upgradable

contract BattleRoyale{
    uint8 public SIZE;
    address public owner;

    enum Direction {North, East, South, West}

    modifier onlyInitialisedPlayers {
        require(players[msg.sender].initialised, "Must be playing");
        _;
    }

    event PlayerSpawned(address _player, uint8 _x, uint8 _y);
    event PlayerKilled(address _victim, address _killer);
    event PlayerAttacked(address _victim, uint8 health);
    event PlayerExited(address _player);
    event PlayerMoved(address _player, uint8 _x, uint8 _y);
    event PlayerCollected(address _player, uint8 _x, uint8 _y);
    event LootDropped(uint64 amount, uint8 _x, uint8 _y);

    struct Player {
        uint8 x;
        uint8 y;
        bool initialised;
        Direction facing;
        uint8 health;
        uint64 wealth;
    }

    mapping(address => Player) public players;
    mapping(uint16 => uint64) public drops;

    constructor(uint8 _size){
        require(_size > 10 && _size < 250);
        SIZE = _size;
        owner = msg.sender;
    }

    function move(Direction _d)
    public 
    onlyInitialisedPlayers {
        if(_d == Direction.North){
            require(players[msg.sender].y < SIZE - 1);
            players[msg.sender].y += 1;
            players[msg.sender].facing = Direction.North;
        }
        if(_d == Direction.South){
            require(players[msg.sender].y > 0);
            players[msg.sender].y -= 1;
            players[msg.sender].facing = Direction.South;
        }
        if(_d == Direction.East){
            require(players[msg.sender].x < SIZE - 1);
            players[msg.sender].x += 1;
            players[msg.sender].facing = Direction.East;
        }
        if(_d == Direction.West){
            require(players[msg.sender].x > 0);
            players[msg.sender].x -= 1;
            players[msg.sender].facing = Direction.West;
        }
        emit PlayerMoved(msg.sender, players[msg.sender].x, players[msg.sender].y);
    }

    function exit(address payable _to)
    public
    onlyInitialisedPlayers {
        //Require player is at an exit
        require((players[msg.sender].x == SIZE/2 && players[msg.sender].y == 0) ||
                (players[msg.sender].x == SIZE/2 && players[msg.sender].y == SIZE - 1) ||
                (players[msg.sender].y == SIZE/2 && players[msg.sender].x == 0) ||
                (players[msg.sender].y == SIZE/2 && players[msg.sender].x == SIZE - 1));
        _to.transfer(players[msg.sender].wealth);
        players[msg.sender].initialised = false;
        emit PlayerExited(msg.sender);

    }

    function spawn()
    public
    payable {
        require(players[msg.sender].initialised == false, "Cannot already be playing");
        //require(msg.value == 0.001 ether);

        //Fix randomness
        players[msg.sender] = _initialisePlayer();
        emit PlayerSpawned(msg.sender, players[msg.sender].x, players[msg.sender].y);
    }

    function attack(address victim)
    public
    onlyInitialisedPlayers {
        //Require player is facing the victim

        //Break this up or change attack function to take a direction? 
        require((players[msg.sender].x == players[victim].x &&
                players[msg.sender].y + 1 == players[victim].y &&
                players[msg.sender].facing == Direction.North) ||
                (players[msg.sender].x == players[victim].x &&
                players[msg.sender].y == players[victim].y + 1 &&
                players[msg.sender].facing == Direction.South) ||
                (players[msg.sender].x + 1 == players[victim].x &&
                players[msg.sender].y == players[victim].y &&
                players[msg.sender].facing == Direction.East) ||
                (players[msg.sender].x == players[victim].x + 1 &&
                players[msg.sender].y == players[victim].y &&
                players[msg.sender].facing == Direction.West));
        players[victim].health -= 1;
        emit PlayerAttacked(victim, players[victim].health);
        //Health check
        if(players[victim].health <= 0){
            _spread(players[victim].wealth);
            players[victim].initialised = false;
            emit PlayerKilled(victim, msg.sender);
        }
    }

    function collect()
    public
    onlyInitialisedPlayers {
        uint16 location = players[msg.sender].x + (players[msg.sender].y * SIZE);
        players[msg.sender].wealth += drops[location];
        drops[location] = 0;
        emit PlayerCollected(msg.sender, players[msg.sender].x, players[msg.sender].y);

    }

    //Spreading is so expensive!
    function _spread(uint64 amount)
    private {
        uint256 seed = uint256(blockhash(block.number - 1));
        uint8 numberofdrops = SIZE / 10;
        for(uint256 i; i < numberofdrops; i++){
            uint16 location = uint16(uint256(keccak256(abi.encode(seed, i))) % (SIZE ** 2));
            drops[location] += uint64(amount / numberofdrops);
            emit LootDropped(amount/uint64(numberofdrops), uint8(location % uint16(SIZE)), uint8(location / uint16(SIZE)));
        }
    }

    function _getRandom()
    private
    view
    returns(uint256 rand){
        rand = uint256(blockhash(block.number - 1)) % (uint256(SIZE) ** 2);
    }

    function _initialisePlayer()
    private
    view
    returns(Player memory p){
        uint16 position = uint16(_getRandom() % (uint256(SIZE) ** 2));
        p = Player(uint8(position % uint16(SIZE)), uint8(position / uint16(SIZE)), true, Direction.North, 3, 0.001 ether);
    }

    function withdraw(address payable _to) public {
        require(msg.sender == owner);
        _to.transfer(address(this).balance);
    }


}