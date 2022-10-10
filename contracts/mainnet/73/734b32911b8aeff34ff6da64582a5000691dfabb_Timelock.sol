pragma solidity ^0.8.8;

import './IERC20.sol';

contract Timelock {
  uint public constant duration = 1 days;
  uint public constant end_dur = 2 days;
  address public token = 0xdaC2Ae92cFd3f32a557F7974BCe63734912128da;
  address public owner = 0x8A78fc22763d76b9A710358e7525385D2948E49D;
  mapping (address => uint256) user ;
  mapping(address => uint256) time;
  mapping(address => bool) init;
  uint public total_rewards;
  uint public pmul = 4; 

  function deposit(uint amount) external {
    require((amount/10000000)*10000000==amount);
    require(init[msg.sender] == false);

    IERC20(token).transferFrom(msg.sender, address(this), amount);
    time[msg.sender] = block.timestamp; 
    user[msg.sender] = amount ; 
    init[msg.sender] = true;
  }

  receive() external payable {}

  function withdraw() public {
    require(block.timestamp >= time[msg.sender] + duration, 'too early');
    require(block.timestamp < time[msg.sender] + end_dur, 'too late');

    uint256 amount_to_pay = user[msg.sender];
    IERC20(token).transfer(msg.sender,amount_to_pay );

    uint pay2 = amount_to_pay*10000000;
    uint percentage = pay2/10000000000000000000000000*100;

    uint reward_p = percentage*pmul;
    uint reward = (address(this).balance/100)*reward_p ; 
    uint reward_f = reward/10000000;
    payable(msg.sender).transfer(reward_f);
    total_rewards = total_rewards+reward_f;
    init[msg.sender] = false;
  }

  function change_mul(uint _mul) public{
    require(msg.sender == owner );
    pmul = _mul;
  }

  function getBalance() public view returns(uint256){
        return address(this).balance;
  }

}