/**
 *Submitted for verification at Etherscan.io on 2022-05-23
*/

// SPDX-License-Identifier: GPL3-3.0

pragma solidity >=0.8.7;

interface MyERC20Token1{
    function balanceOf(address owner) external returns (uint);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
}

contract ERC20StakingContract{

    mapping(address => uint) public stakes;
    mapping(address => uint) public maturityTime;
    uint public balance;
    MyERC20Token1 public token;

    constructor(MyERC20Token1 _token){
        token = MyERC20Token1(_token);
    }

    function deposit(address _owner, uint _amount) public payable{
        maturityTime[msg.sender] = block.timestamp + 60;
        stakes[msg.sender] = _amount;
        token.transferFrom(_owner, address(this), _amount);
    }

    function getBalanceOfToken() public {
        balance = token.balanceOf(address(this));
    }
    
    function isMatured() public view returns(bool){
        return maturityTime[msg.sender] <= block.timestamp;
    }

    function withdraw() public payable {
        require(isMatured(), "Maturity time is not reached");
        require(stakes[msg.sender] > 0, "Not enough amount staked");
        stakes[msg.sender] = 0;
        token.transfer(msg.sender, stakes[msg.sender]);
    }
}