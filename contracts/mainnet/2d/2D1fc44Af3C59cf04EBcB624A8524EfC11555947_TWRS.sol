// SPDX-License-Identifier: MIT
// Official Token of Tsuka Warrior,
// an web3 & Unity 3d RPG game where player can purchase various items from NFT market place like opensea and can use those NFTs in game. 
//Player needs to login into game using crypto wallet like Metamask.

/*

Telegram https://t.me/gameTWS

*/
pragma solidity 0.8.17;

import "./ERC20.sol";

contract TWRS is ERC20,Ownable {
    using SafeMath for uint256;
    uint8 dec = 9;
    uint public _totalSupply=2500000 * 10**dec;
    constructor() ERC20(unicode"Tsuka Warriors",unicode"TWRS",dec,msg.sender,false) {
        _mint(msg.sender, _totalSupply);
    }

    fallback() external payable { }
    receive() external payable { }
}