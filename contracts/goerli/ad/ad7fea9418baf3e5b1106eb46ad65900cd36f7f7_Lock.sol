/**
 *Submitted for verification at Etherscan.io on 2022-10-11
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";
contract Lock {
    uint public c = 5;
    address public admin;

    //Work on tommorow
        string public constant name = "indian";
        string public constant symbol = "inr";
        uint8 public constant decimals = 1;
    //end

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping(address => uint) public balance;

    constructor() payable {
        admin = msg.sender;
    }


    //Its look like a middleware
    modifier onlyOwner() {
        require(msg.sender == admin, "Only admin can do this action");
        _;
    }
    //end

    function add_numbers(uint a, uint b) public pure returns (uint) {
        return a + b;
    }

    function add_to_constant(uint a) public view returns (uint) {
        return a + c;
    }

    function update_c(uint new_value_of_c) external onlyOwner {
        c = new_value_of_c;
    }

    function add_points(address to) external onlyOwner {
        balance[to] += 10;
    }

    function view_points(address to) public view returns (uint) {
        return balance[to];
    }

    function deduct_points(address to) external onlyOwner {
        balance[to] = balance[to] - 2;
    }


    function transfer(address to, uint amount) external {
        
        require(balance[msg.sender] >= amount);
        balance[msg.sender] = balance[msg.sender] - amount;
        balance[to] = balance[to] + amount;
    }



    
    function transferFrom(address from, address to, uint amount) external {
        require(balance[from] >= amount);
        require(from == msg.sender);

        balance[from] = balance[from] - amount;
        balance[to] = balance[to] + amount;
    }

    





    
}