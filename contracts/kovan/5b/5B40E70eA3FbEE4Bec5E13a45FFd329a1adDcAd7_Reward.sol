// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.10;


interface IERC20_TOKEN {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract Reward {

    IERC20_TOKEN public rewardsToken;

    mapping(address => uint ) public participants;

    uint rewardAmount = 10;

    address owner;

    uint private number;

    bool public finish;

    constructor(address _token) {
        rewardsToken = IERC20_TOKEN(_token);
        owner = msg.sender;
        finish = true;
    }


    function getRandomNumber() public {
        require(msg.sender == owner && finish==true);
        uint d = block.timestamp;
        number = uint(keccak256(abi.encodePacked("Test Random",d, msg.sender)))%10;
        finish = false;
    }


    function getNumber() public view returns(uint){
        require(msg.sender == owner);
        return number;
    }


    function selectNumber(uint _number) public{
        require(finish == false);
        require(rewardsToken.approve(address(this),10));
        require(rewardsToken.transferFrom(msg.sender, address(this), 10));
        if(_number == number){
            participants[msg.sender] += rewardAmount;
            finish = true;
        }
    }


    function getReward() public{
        require(participants[msg.sender] >= 0);
        uint _value = participants[msg.sender];
        participants[msg.sender] = 0;
        rewardsToken.transfer(msg.sender,_value);
    }


    function changeRewardAmount(uint _value) public {
        require(msg.sender == owner);
        rewardAmount = _value;
    }
}