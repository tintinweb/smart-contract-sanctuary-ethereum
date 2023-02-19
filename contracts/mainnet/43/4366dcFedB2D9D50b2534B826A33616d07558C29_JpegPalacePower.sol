// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./IERC20.sol";
import "./Ownable.sol";

contract JpegPalacePower is IERC20, Ownable {
    uint private _totalSupply;
    mapping(address => uint) private _balanceOf;
    mapping(address => mapping(address => uint)) private _allowance;
    string public name = "JpegPalace Power";
    string public symbol = "JPP";
    uint8 public decimals = 18;
    
    event PowerTransfer(address indexed from, address indexed to, uint256 value);

    function totalSupply() external view returns (uint) {
        return _totalSupply;
    }

    function balance() public view returns(uint) {
        return _balanceOf[msg.sender];
    }

    function balanceOf(address account) public view returns(uint) {
        return _balanceOf[account];
    }

    function transfer(address recipient, uint amount) external returns (bool) {
        _balanceOf[msg.sender] -= amount;
        _balanceOf[recipient] += amount;
        emit PowerTransfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) external view returns (uint) {
        return _allowance[owner][spender];
    }

    function approve(address spender, uint amount) external returns (bool) {
        _allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool) {
        _allowance[sender][msg.sender] -= amount;
        _balanceOf[sender] -= amount;
        _balanceOf[recipient] += amount;
        emit PowerTransfer(sender, recipient, amount);
        return true;
    }

    function makePower(uint amount) external onlyOwner {
        _balanceOf[msg.sender] += amount;
        _totalSupply += amount;
        emit PowerTransfer(address(0), msg.sender, amount);
    }

    function burnPower(uint amount) external onlyOwner {
        _balanceOf[msg.sender] -= amount;
        _totalSupply -= amount;
        emit PowerTransfer(msg.sender, address(0), amount);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        owner = payable(newOwner);
        emit OwnershipTransferred(owner, newOwner);
    }
}