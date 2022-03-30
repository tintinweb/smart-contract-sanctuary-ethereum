// SPDX-License-Identifier: MIT
/**

 ________  ___    ___ ________  ___  ___  _______   ________  _________   
|\   __  \|\  \  /  /|\   __  \|\  \|\  \|\  ___ \ |\   ____\|\___   ___\ 
\ \  \|\  \ \  \/  / | \  \|\  \ \  \\\  \ \   __/|\ \  \___|\|___ \  \_| 
 \ \   ____\ \    / / \ \  \\\  \ \  \\\  \ \  \_|/_\ \_____  \   \ \  \  
  \ \  \___|/     \/   \ \  \\\  \ \  \\\  \ \  \_|\ \|____|\  \   \ \  \ 
   \ \__\  /  /\   \    \ \_____  \ \_______\ \_______\____\_\  \   \ \__\
    \|__| /__/ /\ __\    \|___| \__\|_______|\|_______|\_________\   \|__|
          |__|/ \|__|          \|__|                  \|_________|        
                                                                          


 * @title CollabProxy
 * Simple contract to proxy calls for collabland to staking contract
 */

pragma solidity ^0.8.11;

interface IStaking {
    function viewStakes(address user) external view returns (uint256[] memory);
}

interface IAdventurer {
    function balanceOf(address owner) external view returns (uint256);
}

contract CollabProxy {
    IStaking public stakingContract;
    IAdventurer public adventurerContract;

    constructor(
        address _stakingContract,
        address _adventurerContract
    ) {
        stakingContract = IStaking(_stakingContract);
        adventurerContract = IAdventurer(_adventurerContract);
    }

    function balanceOf(address _address)
        external
        view
        returns (uint256)
    {
        return adventurerContract.balanceOf(_address) + stakingContract.viewStakes(_address).length;
    }
}