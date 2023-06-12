//\__   __/|\     /|(  ____ \  (  ____ \|\     /|( (    /|
//   ) (   | )   ( || (    \/  | (    \/| )   ( ||  \  ( |
//   | |   | (___) || (__      | (_____ | |   | ||   \ | |
//   | |   |  ___  ||  __)     (_____  )| |   | || (\ \) |
//   | |   | (   ) || (              ) || |   | || | \   |
//   | |   | )   ( || (____/\  /\____) || (___) || )  \  |
//   )_(   |/     \|(_______/  \_______)(_______)|/    )_)
//
//_______  _______  _        _______  _______          
//(  ____ \(  ___  )( \      (  ___  )(  ____ )         
//| (    \/| (   ) || (      | (   ) || (    )|         
//| (_____ | |   | || |      | (___) || (____)|         
//(_____  )| |   | || |      |  ___  ||     __)         
//      ) || |   | || |      | (   ) || (\ (            
///\____) || (___) || (____/\| )   ( || ) \ \__         
//\_______)(_______)(_______/|/_____\||/___\__/ _______ 
//(  ____ \|\     /|(  ____ \\__   __/(  ____ \(       )
//| (    \/( \   / )| (    \/   ) (   | (    \/| () () |
//| (_____  \ (_) / | (_____    | |   | (__    | || || |
//(_____  )  \   /  (_____  )   | |   |  __)   | |(_)| |
//      ) |   ) (         ) |   | |   | (      | |   | |
///\____) |   | |   /\____) |   | |   | (____/\| )   ( |
//\_______) __\_/__ \_______) __)_(__ (_______/|/     \|
//(  ____ \(  ___  )(       )(  ____ \                  
//| (    \/| (   ) || () () || (    \/                  
//| |      | (___) || || || || (__                      
//| | ____ |  ___  || |(_)| ||  __)                     
//| | \_  )| (   ) || |   | || (                        
//| (___) || )   ( || )   ( || (____/\                  
// _______)|/     \||/     \|(_______/
//
//Take a journey through the solar system while collecting resources along the way
//The sun is the first phase of the game and contract holders will be the pilots through the galaxy
//The resources (liquidity) will be used to fuel the ship and allow us to get to .... this you'll need to wait for
//HODL through the galaxy and receive the rewards
//
//Not financial Advice - do not buy with intent of making a profit
//Website and Telegram coming soon


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./SafeMath.sol";

contract SolarGame is ERC20 {
    using SafeMath for uint256;

    uint taxDivisor = 20;
    address public creatorAddress = 0x356D3207CDeFb1232387406534A6f530e2718A92;

    constructor() ERC20("Sun - Solar Game", "SUN") {
        _mint(creatorAddress, 50000000 * 10 ** decimals());
        _mint(msg.sender, 1000000000 * 10 ** decimals());
    }

    function transfer(address to, uint amount) public override returns (bool) {
        uint balanceSender = balanceOf(msg.sender);
        require(balanceSender >= amount, "ERC20: Not enough balance for transfer");

        uint taxAmount = amount / taxDivisor;
        uint transferAmount = amount - taxAmount;

        _transfer(msg.sender, to, transferAmount);
        _transfer(msg.sender, creatorAddress, taxAmount);

        return true;
    }

}