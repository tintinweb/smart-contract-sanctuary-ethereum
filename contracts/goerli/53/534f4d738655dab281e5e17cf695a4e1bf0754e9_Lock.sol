/**
 *Submitted for verification at Etherscan.io on 2022-09-22
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";
contract Lock {
    int public c;
    int public d;
    address public admin;

    //Work on tommorow
        string public constant name = "indian";
        string public constant symbol = "inr";
        uint8 public constant decimals = 1;
    //end

    mapping(address => int) public balance;

    constructor(int _c, int _d) payable {
        admin = msg.sender;
        c = _c;
        d =_d;
    }


    //Its look like a middleware
    modifier onlyOwner() {
        require(msg.sender == admin, "only owner can do this action");
        _;
    }
    //end

    function add_numbers(int a, int b) public pure returns (int) {
        return a + b;
    }

    function add_to_constant(int a) public view returns (int) {
        return a + c;
    }

    function update_c(int new_value_of_c) external onlyOwner {
        c = new_value_of_c;
    }


    function multiply(int num1, int num2) public pure returns(int){
        return num1*num2;
    }

    function add_constant_d(int num1) public view returns(int){
        return num1 * d;
    }
    function update_value_of_d(int new_value_of_d) external onlyOwner{
        d = new_value_of_d;
    }

    function add_points(address to) external onlyOwner {
        balance[to] += 10;
    }

    function view_points(address to) public view returns (int) {
        return balance[to];
    }

    function deduct_points(address to) external onlyOwner {
        balance[to] = balance[to] - 2;
    }

    function transfer_points(address from, address to, int amount) external {
        require(balance[from] >= amount);
        require(from == msg.sender);

        balance[from] = balance[from] - amount;
        balance[to] = balance[to] + amount;
    }

    function transfer(address to, int amount) external {
        require(balance[msg.sender] >= amount);
        balance[msg.sender] = balance[msg.sender] - amount;
        balance[to] = balance[to] + amount;
    }
}