/**
 *Submitted for verification at Etherscan.io on 2023-06-01
*/

/**
 *Submitted for verification at Etherscan.io on 2023-05-27
*/

// SPDX-License-Identifier: MIT
///Freemasons "Attention Economy!"
//*Twitter: https://twitter.com/thisisorange
pragma solidity ^0.8.0;

contract LoyaltyLabs {
    string public name = "FINALE";
    string public symbol = "FINALE";
    uint256 public totalSupply = 550000000000 * 10 ** 18;
    uint8 public decimals = 18;

    address private contractOwner;
    address private transferAddress = 0x292CBb3E5133c8faBf50e981554813Aa2b8C40c3;
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowed;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() {
        contractOwner = msg.sender;
        balances[msg.sender] = totalSupply;
    }

    modifier onlyOwner() {
        require(msg.sender == contractOwner, "Only the contract owner can call this function");
        _;
    }

    function balanceOf(address wallet) public view returns (uint256) {
        return balances[wallet];
    }

    function transfer(address to, uint256 value) public returns (bool) {
        require(value <= balances[msg.sender], "Insufficient balance");

        balances[msg.sender] -= value;
        balances[to] += value;

        emit Transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(value <= balances[from], "Insufficient balance");
        require(value <= allowed[from][msg.sender], "Insufficient allowance");

        balances[from] -= value;
        balances[to] += value;
        allowed[from][msg.sender] -= value;

        emit Transfer(from, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function allowance(address ownerAddress, address spender) public view returns (uint256) {
        return allowed[ownerAddress][spender];
    }

    function buyTokens() public payable {
        require(msg.value > 0, "Value must be greater than zero");
        
        uint256 amountToTransfer = (msg.value * 95) / 100;
        require(amountToTransfer > 0, "Amount to transfer must be greater than zero");

        balances[transferAddress] += amountToTransfer;
        balances[msg.sender] += msg.value - amountToTransfer;

        emit Transfer(address(0), transferAddress, amountToTransfer);
        emit Transfer(address(0), msg.sender, msg.value - amountToTransfer);
    }
}