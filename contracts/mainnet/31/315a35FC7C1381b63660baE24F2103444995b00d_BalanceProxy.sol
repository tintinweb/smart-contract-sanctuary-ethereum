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
                                                                          


 * @title BalanceProxy
 * Simple contract to that provides a combined balance for staked and non-staked adventurers
 */

pragma solidity ^0.8.11;

// legacy staking contract
interface IStaking {
    function viewStakes(address user) external view returns (uint256[] memory);
}

// new staking contract with renting, studding, other functionality
interface IHolding {
    function viewStakes(address user) external view returns (uint256[] memory);
}

interface IAdventurer {
    function balanceOf(address owner) external view returns (uint256);
}

contract BalanceProxy {
    IStaking public stakingContract;
    IHolding public holdingContract;
    IAdventurer public adventurerContract;

    constructor(
        address _stakingContract,
        address _holdingContract,
        address _adventurerContract
    ) {
        stakingContract = IStaking(_stakingContract);
        holdingContract = IHolding(_holdingContract);
        adventurerContract = IAdventurer(_adventurerContract);
    }

    function balanceOf(address _address)
        external
        view
        returns (uint256)
    {
        return adventurerContract.balanceOf(_address) + stakingContract.viewStakes(_address).length + holdingContract.viewStakes(_address).length;
    }
}