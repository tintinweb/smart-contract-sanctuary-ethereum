// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./IERC20.sol";


contract ERC20 is IERC20 {
    uint public override totalSupply;
    uint constant tokenSupplyCap = 1000000;
    uint pricePerThousandToken = 1 ether;
    mapping(address => uint) public override balanceOf;
    mapping(address => mapping(address => uint)) public override allowance;
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    address public owner;

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
        owner = msg.sender;
    }

    function buyToken(address receiver) external payable {
        require(totalSupply < tokenSupplyCap, "Total supply limit exceeded");
        require(msg.value >= pricePerThousandToken, "Amount not up to 1 ether");
        uint amountOfToken = (msg.value * 1000) / pricePerThousandToken;
        _mint(amountOfToken, receiver);
    }

    function getContractEtherBalance() external view returns (uint) {
        return address(this).balance;
    }

    function _mint(uint amountOfToken, address receiver) private {
        balanceOf[receiver] += amountOfToken;
        totalSupply += amountOfToken;
        emit Transfer(address(0), receiver, amountOfToken);
    }

    function burn(uint amount) external {
        require(msg.sender == owner, "Only contract owner can perform this action");
        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;
        emit Transfer(msg.sender, address(0), amount);
    }


    function transfer(address recipient, uint amount) external override returns (bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint amount) external override returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external override returns (bool) {
        allowance[sender][msg.sender] -= amount;
        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

}

// SPDX-License-Identifier: MIT
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