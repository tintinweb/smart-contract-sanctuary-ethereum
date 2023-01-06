/**
 *Submitted for verification at Etherscan.io on 2023-01-06
*/

pragma solidity ^0.8.0;

//SPDX-License-Identifier: BUSL-1.1

// replace with your initials
contract TokenEF {
    mapping(address => uint256) public balanceOf;
    mapping(address => bool) public mintList;
    mapping(address => mapping(address => uint256)) public allowance;
    uint256 public totalSupply;
    string public name = "EricFToken"; // replace with your name
    string public symbol = "EFT";  // replace with your initials
    uint256 public immutable decimals = 6; // replace with your decimals

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    constructor() {
        mintList[msg.sender] = true;
        mint(msg.sender, 1e15);  // this is 1 billion times 1eMyDecimals, 1e6*1e9
    }

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function mint(address _to, uint256 _value) public returns (bool) {
        require(mintList[msg.sender], "Only singular live contract can mint");
        totalSupply += _value;
        unchecked {
            balanceOf[_to] += _value;
        }
        emit Transfer(address(0), _to, _value);
        return true;
    }

    function burn(address from, uint256 _value) external returns (bool) {
        require(from != address(0), "ERC20: burn from the zero address");
        require(balanceOf[from] >= _value);
        balanceOf[from] -= _value;
        unchecked {
            totalSupply -= _value;
        }
        emit Transfer(from, address(0), _value);
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool) {
        uint256 allowed = allowance[_from][msg.sender];
        uint256 balance = balanceOf[_from];
        if (_value <= allowed && _value <= balance) {
            allowance[_from][msg.sender] -= allowed;
            balanceOf[_from] -= _value;
            unchecked {
                balanceOf[_to] += _value;
                emit Transfer(_from, _to, _value);
                return true;
            }
        } else {
            return false;
        }
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        uint256 balance = balanceOf[msg.sender];
        if (_value <= balance) {
            balanceOf[msg.sender] -= _value;
            unchecked {
                balanceOf[_to] += _value;
                emit Transfer(msg.sender, _to, _value);
                return true;
            }
        } else {
            return false;
        }
    }

}