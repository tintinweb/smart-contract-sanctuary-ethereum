// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
/*

Duck Duck, Goose.


                                  ___
                               ,-""   `.
                             ,'  _   e )`-._
                            /  ,' `-._<.===-'
                           /  /
                          /  ;
              _          /   ;
 (`._    _.-"" ""--..__,'    |
 <_  `-""                     \
  <`-                          :
   (__   <__.                  ;
     `-.   '-.__.      _.'    /
        \      `-.__,-'    _,'
         `._    ,    /__,-'
            ""._\__,'< <____
                 | |  `----.`.
                 | |        \ `.
                 ; |___      \-``
                 \   --<
                  `.`.<
                    `-'

GM GOOSERS, 

https://t.me/goosereum

This will be a community ran TG group. Proper measures have been put in place to stop bot attacks and spam. 

0/0 TAX

Low Slippage Only

Will be locked for 1 year and properly renounced. 
Goosereum will purely be a meme currency.
Enjoy yourself everyone :) 

- Goose

*/


import "./Ownable.sol";
import "./ERC20.sol";
import "./SafeMath.sol";

contract Goosereum is ERC20, Ownable {

    using SafeMath for uint256;

    mapping(address => bool) private pair;
    bool public tradingOpen;
    uint256 public _maxWalletSize = 2000000 * 10 ** decimals();
    uint256 private _totalSupply = 100000000 * 10 ** decimals();

    constructor() ERC20("Goosereum", "GUCKER") {

        _mint(msg.sender, 100000000 * 10 ** decimals());
        
    }

    function addPair(address toPair) public onlyOwner {
        require(!pair[toPair], "This pair is already excluded");
        pair[toPair] = true;
    }

    function setTrading(bool _tradingOpen) public onlyOwner {
        tradingOpen = _tradingOpen;
    }

    function setMaxWalletSize(uint256 maxWalletSize) public onlyOwner {
        _maxWalletSize = maxWalletSize;
    }

    function removeLimits() public onlyOwner{
        _maxWalletSize = _totalSupply;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

       if(from != owner() && to != owner()) {

            //Trade start check
            if (!tradingOpen) {
                require(from == owner(), "TOKEN: This account cannot send tokens until trading is enabled");
            }

            //buy 
            
            if(from != owner() && to != owner() && pair[from]) {
                require(balanceOf(to) + amount <= _maxWalletSize, "TOKEN: Amount exceeds maximum wallet size");
                
            }
            
            // transfer
           
            if(from != owner() && to != owner() && !(pair[to]) && !(pair[from])) {
                require(balanceOf(to) + amount <= _maxWalletSize, "TOKEN: Balance exceeds max wallet size!");
            }

       }

       super._transfer(from, to, amount);

    }

}