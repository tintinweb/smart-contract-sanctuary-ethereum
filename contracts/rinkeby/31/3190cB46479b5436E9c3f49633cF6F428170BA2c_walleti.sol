/**
 *Submitted for verification at Etherscan.io on 2022-05-09
*/

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

library SafeMath {
  //anti overflow
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);
    return c;
  }
  
  //anti underflow
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;
    return c;
  }
}

contract walleti {
    using SafeMath for *;
    mapping(address => bool) private locked;
    mapping(address => bool) private untrustedEOA;
    mapping(address => uint) private EOA;
    address payable public owner;

    constructor(){
        owner = payable(msg.sender);
    }

    //transfer to walleti
    fallback() external payable{
        get();
    }
    receive() external payable{
        get();
    }

    function get() internal{
        require(!untrustedEOA[msg.sender],'sender has been untrusted');
        EOA[msg.sender] = EOA[msg.sender].add(msg.value);
    }

    modifier reentrancyGuard(){
        require(!locked[msg.sender],'reject');
        locked[msg.sender] = true;
        _;
        locked[msg.sender] = false;
    }

    function transfer(uint value) reentrancyGuard external{
        require(address(this).balance >= value, 'contract has no balance');
        require(!untrustedEOA[msg.sender],'sender has been untrusted');
        require(EOA[msg.sender] >= value, 'sender has no balance');
        require(msg.sender != address(0), 'sender address invalid');
        //send
        (bool flag,) = payable(msg.sender).call{value: value}("");
        require(flag, "Failed to send Ether");
        //update
        EOA[msg.sender] = EOA[msg.sender].sub(value);
    }

    function add_untrustedparty(address untrustedparty) external{
        require(owner == msg.sender, 'only owner');
        require(untrustedparty != address(0), 'untrustedparty address invalid');
        require(!untrustedEOA[untrustedparty],'untrustedparty already set');
        untrustedEOA[untrustedparty] = true;
    }

    function remove_untrustedparty(address untrustedparty) external{
        require(owner == msg.sender, 'only owner');
        require(untrustedparty != address(0), 'untrustedparty address invalid');
        require(untrustedEOA[untrustedparty],'untrustedparty not set before');
        untrustedEOA[untrustedparty] = false;
    }

    function EOAbalance(address account) external view returns(uint){
        require(account != address(0), 'account address invalid');
        return EOA[account];
    }

    function EOAstatus(address account) external view returns(bool){
        require(account != address(0), 'account address invalid');
        return untrustedEOA[account];
    }
}