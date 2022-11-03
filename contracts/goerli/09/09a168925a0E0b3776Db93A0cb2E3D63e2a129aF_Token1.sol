// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

// Author: https://github.com/cocodrilette

contract Token1 {
    string public name;
    string public symbol;

    uint8 public totalSupply;

    address public owner;

    mapping(address => uint256) balances;
    uint256 mints = 0;

    event Transfer(address indexed _from, address indexed _to);
    event Minted(address indexed _by);

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _totalSupply
    ) {
        require(_totalSupply <= 200, "You can onl created 200 tokens.");

        owner = msg.sender;
        name = _name;
        symbol = _symbol;
        totalSupply = _totalSupply;
    }

    function mintToken() public payable {
        require(balances[msg.sender] <= 10);
        require(msg.value == 0.00001 ether);

        uint256 currBalances = balances[msg.sender];
        balances[msg.sender] = currBalances + 1;

        totalSupply -= 1;
        mints += 1;

        emit Minted(msg.sender);
    }

    function transferToken(address _to, uint256 _amount) public {
        require(balances[msg.sender] > 0);
        uint256 currSenderBalance = balances[msg.sender];
        uint256 currRecieverBalance = balances[_to];

        if (currRecieverBalance == 10)
            revert("The recieve have reach the token limits.");

        if (currSenderBalance - _amount < 0)
            revert("You have not enought balance.");

        if (currRecieverBalance + _amount > 10)
            revert("The reciever cannot recieve that amount.");

        // console.log(
        //     "Tranfering from %s to %s %s tokens.",
        //     msg.sender,
        //     _to,
        //     _amount
        // );

        balances[msg.sender] = currSenderBalance - 1;
        balances[_to] = currRecieverBalance + 1;

        emit Transfer(msg.sender, _to);
    }

    function balancesOf(address _account) public view returns (uint256) {
        return balances[_account];
    }
}