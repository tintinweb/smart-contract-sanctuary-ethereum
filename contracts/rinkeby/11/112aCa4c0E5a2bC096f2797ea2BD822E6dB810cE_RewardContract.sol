// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import "./ERC20.sol";
import "./Ownable.sol";

contract RewardContract is ERC20, Ownable {
    uint256 private  _totalSupply = 80000000000 * 10 ** 18;
    address private  minter ;

    constructor (string memory name, string memory symbol) ERC20(name, symbol) {
        _mint(address(this), _totalSupply);
    }
    
    function burn(uint256 amount) external  {
        _burn(msg.sender, amount);
    }

    function mint(address to, address reciever, uint256 amount) external  {
        require(to == minter, "Unauthorized");
        _mint(reciever, amount);
    }

    function set_minter( address reciever) external onlyOwner {
        minter = reciever;
    }
}