//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./FlashToken.sol";

contract Swapp {
    string private name = "decentralized token swapper";
    Flashtoken public token;
    uint public rate = 100;

    event TokenPurchased(
        address account,
        address token,
        uint amount,
        uint rate
    );

    event TokenSold(address account, address token, uint amount, uint rate);

    constructor(Flashtoken _token) {
        token = _token;
    }

    function buyTokens(uint tokenamount) public payable {
        require(token.balanceOf(address(this)) >= tokenamount);
        tokenamount = msg.value * rate;
        token.transfer(msg.sender, tokenamount);
        emit TokenPurchased(msg.sender, address(token), tokenamount, rate);
    }

    function sellTokens(uint tokenamount) public {
        require(token.balanceOf(msg.sender) >= tokenamount);
        uint etheramount = tokenamount / rate;
        require(address(this).balance >= etheramount);
        payable(msg.sender).transfer(etheramount);
        token.transferFrom(msg.sender, address(this), tokenamount);
        emit TokenSold(msg.sender, address(token), tokenamount, rate);
    }
}

// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Flashtoken {
    uint256 public totalsupply = 1000000000000000000000000;
    string public name = "Flashtoken";
    string public symbol = "FLS";
    uint8 public decimal = 18;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor() {
        balanceOf[msg.sender] = totalsupply;
    }

    function transfer(address _to, uint _amount) public returns (bool success) {
        require(balanceOf[msg.sender] >= _amount, "amount too low");
        require(_to != address(0), "invalid address");
        balanceOf[msg.sender] -= _amount;
        balanceOf[_to] += _amount;
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }

    function approve(address _spender, uint256 _value)
        public
        returns (bool success)
    {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool success) {
        require(balanceOf[_from] >= _value);
        require(allowance[_from][msg.sender] >= _value);
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;
        emit Approval(_from, _to, _value);
        return true;
    }
}