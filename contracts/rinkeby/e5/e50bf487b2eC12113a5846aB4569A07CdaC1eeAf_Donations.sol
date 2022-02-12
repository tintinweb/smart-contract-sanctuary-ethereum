pragma solidity ^0.7.0;

contract Donations {
    address public owner;
    address[] public benefactors;

    mapping(address => uint256) balances;

    constructor() {
        owner = msg.sender;
    }

    function donate() external payable { 
        require(msg.value > 0, "Amount must be greater than zero");
        if (balances[msg.sender] == 0) {
            benefactors.push(msg.sender);
        }
        balances[msg.sender] += msg.value;
    }

    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }

    function showAllbenefactors() external view returns (address[] memory) {
        return benefactors;
    }

    function transfer(address payable destination, uint256 amount) external onlyOwner {
        (bool success,) = destination.call{value: amount}("");
        require(success, "Failed to send money");
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, 'Function only for owner');
        _;
    }
}