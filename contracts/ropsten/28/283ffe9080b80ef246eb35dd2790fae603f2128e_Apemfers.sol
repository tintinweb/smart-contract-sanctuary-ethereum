// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import "./ERC20.sol";
import "./Ownable.sol";

contract Apemfers is ERC20, Ownable{

    uint256 private _totalSupply = 1800 * 10 ** 8;

    uint256 private _price = 85000000000000000;

    uint256 private _supply;

    constructor (string memory name, string memory symbol) ERC20(name, symbol) {
        _mint(address(this), _totalSupply);
    }
    
    function burn(uint256 amount) external  {
        _burn(msg.sender, amount);
    }
    
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function changePrice(uint256 _newPrice) external onlyOwner {
        _price = _newPrice;
    }

    function buy(address recipient, uint256 amount) public payable  {
        require(amount <= 1000000000,"Maximum 10 tokens can be minted per transaction");
        require(_supply + amount <= _totalSupply, "Exceeds maximum supply");
        require(msg.value >= _price * (amount / 10 ** 8),"Ether sent with this transaction is not correct");
        _supply += amount;
        _transfer(address(this), recipient, amount);
    }

    function withdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function getPrice() public view returns (uint256){
        return _price;
    }
}