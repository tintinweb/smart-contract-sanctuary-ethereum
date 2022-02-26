// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./DappToken.sol";

contract DappTokenSale {

    address payable admin;
    DappToken public tokenContract;
    uint256 public tokenPrice;
    uint256 public tokensSold;

    event Sell(address _buyer, uint256 _amount);
    event EndSale(uint256 _totalAmountSold);

    constructor(DappToken _tokenContract, uint256 _tokenPrice) {
        admin = payable(msg.sender);
        tokenContract = _tokenContract;
        tokenPrice = _tokenPrice;
    }

    function multiply(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    function buyTokens(uint256 _numberOfTokens) public payable {
        require(msg.value == multiply(_numberOfTokens, tokenPrice), 'msg.value must equal number of tokens in wei');
        require(tokenContract.balanceOf(tokenContract.owner()) >= _numberOfTokens, 'cannot purchase more tokens than available');
        require(tokenContract.transfer(msg.sender, _numberOfTokens), 'Unable to send tokens');
        // emit Balance(address(this), _numberOfTokens);

        tokensSold += _numberOfTokens;

        emit Sell(msg.sender, _numberOfTokens);
    }

    function endSale() public {
        require(msg.sender == admin);
        require(tokenContract.transfer(admin, tokenContract.balanceOf(address(this))));
        // require(tokenContract.transfer(admin, tokenContract.balanceOf(address(this))));
        // UPDATE: Let's not destroy the contract here
        // Just transfer the balance to the admin
        admin.transfer(address(this).balance);

        emit EndSale(tokensSold);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract DappToken {
    string  public name = "DApp Token";
    string  public symbol = "DAPP";
    string  public standard = "DApp Token v1.0";
    uint256 public totalSupply = 75000;
    address public owner;

    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _value
    );

    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor (uint256 _initialSupply) {
        owner = msg.sender;
        balanceOf[owner] = _initialSupply;
        totalSupply = _initialSupply;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[owner] >= _value, "Insufficient sender balance");

        balanceOf[owner] -= _value;
        balanceOf[_to] += _value;

        emit Transfer(msg.sender, _to, _value);

        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);

        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= balanceOf[_from], 'Amount should not exceed balance');
        require(_value <= allowance[_from][msg.sender], 'Amount should not exceed allowance');

        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;

        allowance[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, _value);

        return true;
    }
}