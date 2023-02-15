/**
 *Submitted for verification at Etherscan.io on 2023-02-15
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

contract ERC20 {
    uint256 public totalSupply;
    string public name;
    string public symbol;

    mapping (address => uint256) public balanceOf;

    constructor (string memory _name, string memory _symbol){
        name = _name;
        symbol = _symbol;
    }

    function decimals() external pure returns(uint8) {
        return 18;
    }

    function transfer( address recipient, uint256 amount ) external returns(bool) {
        require( recipient != address(0), "ERC20: transfer to the null address" );
        require( balanceOf[msg.sender] >= amount, "ERC20: insuficient balance to transfer");

        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amount;

        return true;
    }

    function buy() external payable {
        balanceOf[msg.sender] += msg.value;
        totalSupply += msg.value;
    }

    function redeem(uint256 amount) external {
        require( balanceOf[msg.sender] >= amount );
        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require( success, "Failed to send ETH");
    }
}