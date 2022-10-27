// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./Game.sol";

contract Hub {
    Game[] private games;
    address public owner;

    event GameCreated(uint indexed id, address indexed player1, address indexed player2, uint createdAt);

    constructor() {
        owner = msg.sender;
    }

    function createGame(address _p1, address _p2, address _admin) public {
        require(_p1 != address(0) && _p1 != address(0), "incorrect player addresses");
        uint id = games.length;
        Game game = new Game(id, _p1, _p2, _admin);
        games.push(game);
        emit GameCreated(id, _p1, _p2, block.timestamp);
    }

    function getGame(uint _id) public view returns(Game) {
        require(_id <= games.length, "not enough game");
        return games[_id];
    }

    function totalGames() public view returns(uint) {
        return games.length;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Game {
    bool gameOver = false;
    uint public id;
    address public p1;
    address public p2;
    address public admin;
    bool public isP1Turn = true;
    Move[] public moves;

    struct Move {
        string from;
        string to;
    }

    event GameStarted();
    event Movement();
    event GameEnded();

    modifier onlyPlayer {
        require(msg.sender == p1 || msg.sender == p2 || msg.sender == admin, "not a player or trusted admin");
        _;
    }

    modifier gameNotOver() {
        require(!gameOver, "game over");
        _;
    }

    constructor(uint _id, address _p1, address _p2, address _admin) {
        id = _id;
        p1 = _p1;
        p2 = _p2;
        admin = _admin;

        emit GameStarted();
    }

    function isPlayer(address _address) public view returns(bool) {
        return _address == p1 || _address == p2 ? true : false;
    }

    function isAdmin(address _address) public view returns(bool) {
        return _address == admin ? true : false;
    }

    function move(string memory _from, string memory _to) public onlyPlayer() gameNotOver() {
        if (msg.sender == p1 && isP1Turn) {
            Move memory movement = Move({
                from: _from,
                to: _to
            });
        
            moves.push(movement);

            isP1Turn = !isP1Turn;

            emit Movement();
        } else if (msg.sender == p2 && !isP1Turn) {
            Move memory movement = Move({
                from: _from,
                to: _to
            });
        
            moves.push(movement);

            isP1Turn = !isP1Turn;

            emit Movement();
        } else {
            revert("now it's another player's turn");
        }
    }

    function leave() public onlyPlayer {
        gameOver = true;
        emit GameEnded();
    }
}