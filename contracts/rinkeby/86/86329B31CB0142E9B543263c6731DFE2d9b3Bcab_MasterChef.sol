/**
 *Submitted for verification at Etherscan.io on 2022-09-03
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <=0.8.0;
pragma experimental ABIEncoderV2;

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
    function div(uint x, uint y) internal pure returns (uint) {
        return x/y;
    }
}
/*
-------------------------------------- MasterChef.sol ---------------------------------
*/

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
      * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract MasterChef is Ownable{
    using SafeMath for uint256;

    address public team;

    struct UserStats {
        uint total;
        uint first;
        uint second;
        uint third;
    }

    mapping(address => UserStats) public userLogs;

    struct GameResult {
        address first;
        address second;
        address third;
    }

    struct Game {
        GameResult gameResult;
        uint rewardSize;
    }

    mapping(string => Game) public games;
    mapping(string => address[]) public palyers;

    constructor(address _team) {
        team = _team;
    }

function createGame(string memory _gameid, uint256 _rewardsize) public payable {
        Game memory temp_game;
        GameResult memory temp_result;
        temp_game.gameResult = temp_result;
        temp_game.rewardSize = _rewardsize;
        palyers[_gameid].push(msg.sender);

        require(msg.value >= _rewardsize, "Insufficent funds");

        games[_gameid] = temp_game;

        UserStats memory temp_stats = userLogs[msg.sender];

        if(temp_stats.total == 0) {
            temp_stats.total = 1;
        } else {
            temp_stats.total = temp_stats.total + 1;
        }

        userLogs[msg.sender] = temp_stats;
    }

    function joinGame(string memory _gameid) public payable {
        Game memory temp_game = games[_gameid];
        require(msg.value >= temp_game.rewardSize, "Insufficent funds");

        palyers[_gameid].push(msg.sender);
        games[_gameid] = temp_game;

        UserStats memory temp_stats = userLogs[msg.sender];

        if(temp_stats.total == 0) {
            temp_stats.total = 1;
        } else {
            temp_stats.total = temp_stats.total + 1;
        }

        userLogs[msg.sender] = temp_stats;
    }

    function rewardGame(string memory _gameid, uint256 _rank, address _winner) public onlyOwner {
        if(_rank == 1) {
            Game memory temp_game = games[_gameid];
            GameResult memory temp_result = temp_game.gameResult;

            if(temp_result.first == address(0x0)) {
                GameResult memory temp1 = GameResult({first: address(0x0),second: address(0x0), third: address(0x0)});
                temp1.first = _winner;
                temp_result = temp1;
            } else {
                GameResult memory temp1 = temp_result;
                temp1.first = _winner;
                temp_result = temp1;
            }
            
            games[_gameid] = temp_game;

            UserStats memory state = userLogs[msg.sender];
            state.first = state.first + 1;

            address payable receiver = payable(_winner);
            receiver.transfer(temp_game.rewardSize * 4);

            address payable payteam = payable(team);
            payteam.transfer(temp_game.rewardSize * 2);
        }

        if(_rank == 2) {
            Game memory temp_game = games[_gameid];
            GameResult memory temp_result = temp_game.gameResult;

            if(temp_result.second == address(0x0)) {
                GameResult memory temp1 = GameResult({first: address(0x0),second: address(0x0), third: address(0x0)});
                temp1.second = _winner;
                temp_result = temp1;
            } else {
                GameResult memory temp1 = temp_result;
                temp1.second = _winner;
                temp_result = temp1;
            }
            
            games[_gameid] = temp_game;

            UserStats memory state = userLogs[msg.sender];
            state.second = state.second + 1;

            address payable receiver = payable(_winner);
            receiver.transfer(temp_game.rewardSize * 2);
        }

        if(_rank == 3) {
            Game memory temp_game = games[_gameid];
            GameResult memory temp_result = temp_game.gameResult;

            if(temp_result.third == address(0x0)) {
                GameResult memory temp1 = GameResult({first: address(0x0),second: address(0x0), third: address(0x0)});
                temp1.third = _winner;
                temp_result = temp1;
            } else {
                GameResult memory temp1 = temp_result;
                temp1.third = _winner;
                temp_result = temp1;
            }
            
            games[_gameid] = temp_game;

            UserStats memory state = userLogs[msg.sender];
            state.third = state.third + 1;

            address payable receiver = payable(_winner);
            receiver.transfer(temp_game.rewardSize);
        }
    }
    
    // Function to receive Ether. msg.data must be empty
    receive() external payable {}
}