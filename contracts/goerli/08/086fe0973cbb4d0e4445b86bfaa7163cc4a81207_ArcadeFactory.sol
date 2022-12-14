//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./Arcade.sol";

contract ArcadeFactory is Ownable {
    Arcade[] public arcades;

    function createArcade(
        string memory _leaderboardName,
        string memory _leaderboardGame,
        bool _hasWhiteList,
        uint256 _costOfPlaying,
        address _protocolPayoutWallet,
        address _gameDevPayoutWallet
    ) public onlyOwner {
        Arcade arcade = new Arcade(
            _leaderboardName,
            _leaderboardGame,
            _hasWhiteList,
            _costOfPlaying,
            _protocolPayoutWallet,
            _gameDevPayoutWallet,
            msg.sender
        );
        arcades.push(arcade);
    }

    function getAllArcades() public view returns (Arcade[] memory arcade) {
        return arcades;
    }
}