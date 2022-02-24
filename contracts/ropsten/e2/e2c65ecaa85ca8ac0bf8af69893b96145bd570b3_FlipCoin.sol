/**
 *Submitted for verification at Etherscan.io on 2022-02-24
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract FlipCoin {

    uint256 private _gameID;
    address public owner;

    struct Games {
        uint256 gameID;
        address coinFlipper;
        uint256 betAmount;
        uint256 userBet;
        uint256 gameResult;
        uint256 collected;
    }

    mapping(uint256 => Games) private _games;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    function getGameID() public view returns (uint256) {
        return _gameID;
    }

    function writeResult(address _coinFlipper, uint256 _betAmount, uint256 _userBet, uint256 _gameResult) public onlyOwner {
        Games storage game = _games[_gameID];
        game.coinFlipper = _coinFlipper;
        game.betAmount = _betAmount;
        game.userBet = _userBet;
        game.gameResult = _gameResult;
        _gameID++;
    }
    
}