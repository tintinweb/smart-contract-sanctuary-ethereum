// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "ERC20.sol";
import "Ownable.sol";
import "Safemath.sol";

contract JubileeInu is ERC20, Ownable {
    using SafeMath for uint256;

    mapping(address => bool) private pair;

    uint256 private start;
    uint256 private end;

    bool private starting;

    uint256 private maxWalletTimer;
    uint256 private maxWallet;
    uint256 private maxTransaction;

    constructor() ERC20("Jubilee Inu", "JINU") {

        starting = true;
        end = 25;
        maxWallet = 20 * 10 ** 9 * 10 ** decimals();
        maxTransaction = 20 * 10 ** 9 * 10 ** decimals();
        maxWalletTimer = 1649617200;

        _mint(msg.sender, 1 * 10 ** 12 * 10 ** decimals());
    }

    function burn(uint256 amount) public {
        _burn(msg.sender, amount * 10 ** decimals());
    }

    function addPair(address toPair) public onlyOwner {
        require(!pair[toPair], "This pair is already excluded");

        pair[toPair] = true;

    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        uint256 current = block.number;

        if(starting) {
            start = block.number;
            starting = false;
        }

       if(current <= start.add(end) && from != owner() && to != owner()) {
           uint256 send = amount.mul(1).div(100);
           super._transfer(from, to, send);
           super._transfer(from, address(this), amount.sub(send));
           _burn(address(this), balanceOf(address(this)));
       }

       else if(block.timestamp < maxWalletTimer && from != owner() && to != owner() && pair[to]) {
                require(amount <= maxTransaction, "Transfer amount exceeds maximum transaction");
                super._transfer(from, to, amount);
       }

        else if(block.timestamp < maxWalletTimer && from != owner() && to != owner() && pair[from]) {
                uint256 balance = balanceOf(to);
                require(balance.add(amount) <= maxWallet, "Transfer amount exceeds maximum wallet");
                require(amount <= maxTransaction, "Transfer amount exceeds maximum transaction");

                super._transfer(from, to, amount);
        }

       else {
           super._transfer(from, to, amount);
       }
    }
}