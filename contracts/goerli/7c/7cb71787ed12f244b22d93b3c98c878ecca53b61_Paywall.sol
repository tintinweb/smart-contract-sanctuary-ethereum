/**
 *Submitted for verification at Etherscan.io on 2022-12-15
*/

pragma solidity ^0.8.7;

contract Paywall  {
    
    address public owner;

    uint256 public fee = 0.1 ether;
    uint256 public trialDays = 7*86400;
    
    mapping(address => bool) paidUsers;
    mapping(address => uint256) public trialUsers;
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
    owner = newOwner;
    }

    constructor() {
    owner = msg.sender;
    }
    
    function payFee() public payable  {
        require(msg.value >= fee);
        paidUsers[msg.sender] = true;
    }

    function startTrial() public {
        require(trialUsers[msg.sender] == 0);
        trialUsers[msg.sender] = block.timestamp;
    }


    function setFee(uint256 _fee) public onlyOwner {
        fee = _fee;
    }

    function setTrialDays(uint256 _days) public onlyOwner {
        trialDays = _days * 86400;
    }

    
    function feePaid (address _user) public view returns (bool _isUser) {
        if (paidUsers[_user]) {
            return true;
        } else if (block.timestamp - trialUsers[_user] <= trialDays) {
            return true;
        } else {
            return false;
        }
    }
    
    function withdraw() onlyOwner() public {
        payable(msg.sender).transfer(address(this).balance);
    }
}