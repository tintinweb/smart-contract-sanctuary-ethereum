/**
 *Submitted for verification at Etherscan.io on 2022-12-10
*/

// SPDX-License-Identifier: UNLICENSED

/*
- Create a simple smart contract that manages a basic token system using Ethereum and Solidity.
- The contract should have the ability to create and issue tokens, as well as transfer tokens between accounts.
- Provide the contract code and instructions for testing it using a local blockchain emulator or test network.
*/
pragma solidity ^0.8.0;

interface IStreaX {
    function getBalance(address) external view returns (uint256);

    function transfer(
        address _to,
        address _from,
        uint256 _amount
    ) external;

    function mint(address _to, uint256 _amount) external;

    function getTotalSupply() external view returns (uint256);
}
contract StreaXToken is IStreaX {
    string public name;
    string public symbol;
    uint256 public decimals;
    uint256 public totalSupply;
    address public owner;
    mapping(address => uint256) public balances;

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
        decimals = 18;
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "msg.sender is not owner of the smart contract"
        );
        _;
    }

    event Mint(address indexed to, uint256 amount);

    event Transfer(address indexed from, address indexed to, uint256 amount);

    function getBalance(address _of) external view returns (uint256) {
        return balances[_of];
    }

    function getTotalSupply() external view returns (uint256) {
        return totalSupply;
    }

    function mint(address _to, uint256 _amount) external onlyOwner {
        require(_to != address(0));
        // require(
        //     balances[_to] + _amount <= totalSupply,
        //     "amount exceeds total supply"
        // );
        balances[_to] += _amount;
        totalSupply += _amount;
        emit Mint(_to, _amount);
    }

    function transfer(
        address _to,
        address _from,
        uint256 _amount
    ) external {
        require(_amount <= balances[_from], "token balance insufficient");
        require(_from == msg.sender, "msg.sender is not _from");

        balances[_from] -= _amount;
        balances[_to] += _amount;

        emit Transfer(_from, _to, _amount);
    }
}