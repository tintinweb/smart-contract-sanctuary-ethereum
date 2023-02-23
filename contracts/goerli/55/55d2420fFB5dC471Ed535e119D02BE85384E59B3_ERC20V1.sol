/**
 *Submitted for verification at Etherscan.io on 2023-02-23
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

//event Approval与Transfer 将交易等日志信息写入区块链，非常重要

// V1
interface IERC20V1 {
    event Approval(address indexed owner, address indexed spender, uint256 amount);
    event Transfer(address indexed from, address indexed to, uint256 amount);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256);
    function approve(address spender, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address to, uint amount) external returns (bool);
    function transferFrom(address from, address to, uint amount) external returns (bool);
}

contract ERC20V1 is IERC20V1 {
    string public constant name = "ThinkingChain";
    string public constant symbol = "TKC";
    uint8 public constant decimals = 18;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;

    address public _owner;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor(uint256 _initTotalSupply) {
        _owner = msg.sender;
          mint(msg.sender,_initTotalSupply);
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    
    function mint(address to, uint256 amount) public onlyOwner {
        totalSupply = totalSupply += amount;
        balanceOf[to] = balanceOf[to] +=amount;
        emit Transfer(address(0), to, amount);
    }

    function burn(uint256 amount) public {
        address from = msg.sender;
        balanceOf[from] = balanceOf[from] -= amount;
        totalSupply = totalSupply -= amount;
        emit Transfer(from, address(0), amount);
    }

    function _approve(address owner, address spender, uint amount) private {
        allowance[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function approve(address spender, uint amount) external returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function _transfer(address from, address to, uint amount) private {
        balanceOf[from] = balanceOf[from] -= amount;
        balanceOf[to] = balanceOf[to] += amount;
        emit Transfer(from, to, amount);
    }

    function transfer(address to, uint amount) external returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }
    
    function transferFrom(address from, address to, uint amount) external returns (bool) {
        uint256 currentAllowance = allowance[from][msg.sender];
        require(currentAllowance >= amount, "ERC20: insufficient allowance");
        allowance[from][msg.sender] = currentAllowance -= amount;
        _transfer(from, to, amount);
        return true;
    }

}