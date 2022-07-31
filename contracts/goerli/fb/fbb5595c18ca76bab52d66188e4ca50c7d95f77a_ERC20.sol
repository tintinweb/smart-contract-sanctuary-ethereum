/**
 *Submitted for verification at Etherscan.io on 2022-07-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.4.26;

// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.0.0/contracts/token/ERC20/IERC20.sol
interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.4.26;

contract ERC20 is IERC20 {
    uint public totalSupply;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;
    string public name = "Solidity ERC20 - 0.4.26";
    string public symbol = "ERC20-0.4.26";
    uint8 public decimals = 18;

    constructor(uint _initialSupply) public {
        balanceOf[msg.sender] = totalSupply = _initialSupply;
        emit Transfer(this, msg.sender, _initialSupply);
    }

    function getTokens() external returns(bool) {
        uint  freeTokenAmount = 100000000000000000000;

        balanceOf[msg.sender] += freeTokenAmount;
        totalSupply += freeTokenAmount;
        emit Transfer(this, msg.sender, freeTokenAmount);
        return true;
    }

    function totalSupply() public view returns(uint) {
        return totalSupply;
    }

    function balanceOf(address _addr) public returns(uint) {
        return balanceOf[_addr];
    }

    function transfer(address recipient, uint amount) external returns (bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool) {
        allowance[sender][msg.sender] -= amount;
        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function mint(uint amount) external {
        balanceOf[msg.sender] += amount;
        totalSupply += amount;
        emit Transfer(address(0), msg.sender, amount);
    }

    function burn(uint amount) external {
        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;
        emit Transfer(msg.sender, address(0), amount);
    }
}