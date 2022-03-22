// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.6;

import '../interfaces/IERC20.sol';
import '../libraries/SafeMath.sol';

contract Token1 {
    using SafeMath for uint;

    string public constant name = 'USDT Test';
    string public constant symbol = 'USDT';
    uint8 public constant decimals = 18;
    uint public totalSupply;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    /**
     * @dev this internal function mints token to given address
     */
    function mint(address to, uint value) external {
        require(value <= uint256(-1) - totalSupply, "Token1: Total supply exceeded max limit.");
        totalSupply = totalSupply.add(value);
        require(value <= uint256(-1) - balanceOf[to], "Token1: Balance of minter exceeded max limit.");
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }
    /**
     * @dev this internal function burns rewards token from the given address
     */
    function burn(address from, uint value) external {
        require(from != address(0), "Token1: burn from the zero address");
        require(balanceOf[from] >= value, "Token1: burn amount exceeds balance of the holder");
        balanceOf[from] = balanceOf[from].sub(value);
        require(value <= totalSupply, "Token1: Insufficient total supply.");
        totalSupply = totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    function _approve(address owner, address spender, uint value) private {
        require(spender != address(0), "Token1: approve to the invalid or zero address");
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(address from, address to, uint value) private {
        require(from != address(0), "Token1: Invalid Sender Address");
        require(to != address(0), "Token1: Invalid Recipient Address");
        require(balanceOf[from] >= value, "Token1: Transfer amount exceeds balance of sender");
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) external returns (bool) {
        require(allowance[from][msg.sender] >= value, "Token1: transfer amount exceeds allowance");
        if (allowance[from][msg.sender] != uint256(-1)) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        }
        _transfer(from, to, value);
        return true;
    }
}

pragma solidity =0.6.6;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}

pragma solidity >=0.5.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}