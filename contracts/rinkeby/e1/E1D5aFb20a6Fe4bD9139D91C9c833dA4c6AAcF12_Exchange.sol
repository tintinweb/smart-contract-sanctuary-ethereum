// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./IERC20.sol";

contract Exchange {
    event Purchase(address indexed buyer, uint amount);
    event Sold(address indexed seller, uint amount);

    IERC20 public immutable token;
    address owner;
    address public exchangeAddress = address(this);

    uint public rate = 0.01 ether;
    
    constructor(address _token){
        token = IERC20(_token);
        owner = msg.sender;
    }

    modifier onlyOwner(){
        require(msg.sender == owner, "You are not an owner =(");
        _;
    }

    function getEthBalance() public view returns(uint){
        return address(this).balance;
    }
    function getTokenBalance() public view returns(uint){
        return token.balanceOf(exchangeAddress);
    }

    function setRate(uint _rate) external onlyOwner{
        rate = _rate;
    }

    function buyToken() public payable{
        require(msg.value >= rate, "Pay up");
        uint tokenAvalible = getTokenBalance();
        uint tokensToBuy = msg.value / rate; 

        require(tokensToBuy <= tokenAvalible, "Not enough tokens");

        token.transfer(msg.sender, tokensToBuy);
        emit Purchase(msg.sender, tokensToBuy);
    }

    function sellToken(uint _amount) external{
        require(_amount > 0, "Amount must be grater than 0");

        uint allowance = token.allowance(msg.sender, exchangeAddress);
        require(allowance >= _amount, "Wrong allowance");

        token.transferFrom(msg.sender, exchangeAddress, _amount);
        payable(msg.sender).transfer(_amount * rate);
        emit Sold(msg.sender, _amount);
    }

    function withdraw(uint amount) external onlyOwner{
        require(amount <= getEthBalance(), "Not enough funds");
        payable(msg.sender).transfer(amount);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IERC20 {

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);
 
    function approve(address spender, uint256 amount) external returns (bool);
 
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}