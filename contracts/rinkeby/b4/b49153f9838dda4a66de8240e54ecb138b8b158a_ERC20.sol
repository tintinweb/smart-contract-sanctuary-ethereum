/**
 *Submitted for verification at Etherscan.io on 2022-02-28
*/

// File: contracts/IERC20.sol


pragma solidity ^0.8.7;

// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.0.0/contracts/token/ERC20/IERC20.sol
interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}
// File: contracts/Fruits.sol


pragma solidity ^0.8.7;


contract ERC20 is IERC20 {
    uint private theTotalSupply;
    mapping(address => uint) private theBalanceOf;
    mapping(address => mapping(address => uint)) private theAllowance;
    string public name = "Solidity by Example";
    string public symbol = "SOLBYEX";
    uint8 public decimals = 18;



    function totalSupply() external view override returns (uint)
    {
        return theTotalSupply;
    }

    function allowance(address owner, address spender) external view override returns (uint)
    {
        return theAllowance[owner][spender];
    }
    function balanceOf(address account) external view override returns (uint)
    {
        return theBalanceOf[account];
    }

    function transfer(address recipient, uint amount) external override returns (bool) {
        theBalanceOf[msg.sender] -= amount;
        theBalanceOf[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint amount) external override returns (bool) {
        theAllowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender,address recipient,uint amount) external override returns (bool) {
        theAllowance[sender][msg.sender] -= amount;
        theBalanceOf[sender] -= amount;
        theBalanceOf[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function mint(uint amount) external {
        theBalanceOf[msg.sender] += amount;
        theTotalSupply += amount;
        emit Transfer(address(0), msg.sender, amount);
    }

    function burn(uint amount) external {
        theBalanceOf[msg.sender] -= amount;
        theTotalSupply -= amount;
        emit Transfer(msg.sender, address(0), amount);
    }
}