/**
 *Submitted for verification at Etherscan.io on 2022-02-16
*/

/**
 *Submitted for verification at
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract goldenEgg {
    string public constant name = "golden egg";
    string public constant symbol = "egg";
    uint8 public constant decimals = 18;

    uint public totalSupply = 0;

    mapping(address => mapping (address => uint)) public allowance;
    mapping(address => uint) public balanceOf;//余额
    

    event Transfer(address indexed from, address indexed to, uint amount);
    event Approval(address indexed from, address indexed to, uint amount);

    function claim(address ads) external {
        _mint(ads, 1000000000000000000);
    }

    

    function _mint(address dst, uint amount) internal {
        totalSupply += amount;
        balanceOf[dst] += amount;
        emit Transfer(dst, dst, amount);
    }

    function approve(address from, address spender, uint amount) external returns (bool) {
        allowance[from][spender] = amount;

        emit Approval(from, spender, amount);
        return true;
    }

    function transfer(address from, address to, uint amount) external returns (bool) {
        _transferTokens(from, to, amount);
        return true;
    }

    function _transferTokens(address from, address to, uint amount) internal {
        balanceOf[from] -= amount;
        balanceOf[to] += amount;

        emit Transfer(from, to, amount);
    }
}