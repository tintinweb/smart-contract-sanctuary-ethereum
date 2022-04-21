// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ERC20 } from "./ERC20.sol";
import { Ownable } from "./ownable.sol";
import { SafeMath } from "./SafeMath.sol";

contract Kakubi is ERC20, Ownable {
    
    uint8 private ownerFeeDenominator = 100;

    constructor(uint256 initialSupply) ERC20("Kakubi", "KKB") {
        _mint(_msgSender(), initialSupply);
    }

    function topUpBalance(address account, uint256 amount) public onlyOwner {
        require(amount > 0, "ERC20Kakubi: top up amount less than or equal to 0");
        _mint(account, amount);
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        if(_msgSender() == owner) {
            _transfer(_msgSender(), recipient, amount);
            return true;
        }
        uint256 ownerFee = SafeMath.div(amount, ownerFeeDenominator);
        amount = SafeMath.sub(amount, ownerFee);
        _transfer(_msgSender(), owner, ownerFee);
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

     function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
            unchecked {
                _approve(sender, _msgSender(), currentAllowance - amount);
            }
        }
        if(_msgSender() == owner) {
            _transfer(sender, recipient, amount);
            return true;
        }
        uint256 ownerFee = SafeMath.div(amount, ownerFeeDenominator);
        amount = SafeMath.sub(amount, ownerFee);
        _transfer(sender, owner, ownerFee);
        _transfer(sender, recipient, amount);
        return true;
    }
}