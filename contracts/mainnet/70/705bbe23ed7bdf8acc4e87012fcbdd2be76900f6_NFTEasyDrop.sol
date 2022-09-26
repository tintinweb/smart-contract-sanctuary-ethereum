/**
 *Submitted for verification at Etherscan.io on 2022-09-26
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IERC721 {
  function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

interface IERC1155 {
  function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;
}

interface INFT {
  function isApprovedForAll(address account, address operator) external view returns (bool);
}

contract NFTEasyDrop {
  
  address payable public owner;

  uint public txFee = 0.07 ether;
  uint[4] public subscriptionFees = [0.25 ether, 0.5 ether, 1 ether, 3 ether];

  struct Sub {
    bool subscribed;
    uint until;
  }

  mapping(address => Sub) public subscribers;
  
  uint internal received;

  event Airdrop1155(address indexed _from, address indexed _nft, uint _timestamp);
  event Airdrop721(address indexed _from, address indexed _nft, uint _timestamp);
  event Subscription(address indexed _subscriber, uint _timestamp, uint indexed _period);
  event ReceivedUndefiendETH(address indexed _from, uint indexed _value, uint _timestamp);

  modifier onlyOwner {
    require(msg.sender == owner, "Not an owner");
    _;
  }
  
  modifier isEligible {
    require(subscribers[msg.sender].subscribed || msg.value >= txFee || msg.sender == owner, "Not subscribed or trying to pay less than the fee size");
    _;
  }

  constructor() {
    owner = payable(msg.sender);
  }

  receive() external payable {
    received += msg.value;
    emit ReceivedUndefiendETH(msg.sender, msg.value, block.timestamp);
  }

  function setOwner(address newOwner) external onlyOwner {
     require(newOwner != address(0), "Trying to set zero address");
     owner = payable(newOwner);
  }

  function setTxFee(uint _txFee) external onlyOwner {
    txFee = _txFee;
  }

  function setSubFees(uint _day, uint _week, uint _month, uint _year) external onlyOwner {
    subscriptionFees = [_day, _week, _month, _year];
  }

  function subscribe() external payable {
    require(!subscribers[msg.sender].subscribed, "Already subscribed");
    require(msg.value >= subscriptionFees[0], "Trying to pay less than minimum subscription fee");
    received += msg.value;
    uint32[4] memory periods = [86400, 604800, 2629743, 31556926];
    bool sub;
    for (uint i = 0; i < subscriptionFees.length; i++) {
      if (msg.value == subscriptionFees[i]) {
        _addSub(msg.sender, periods[i]);
        sub = true;
      }
    }
    if (sub == false) emit ReceivedUndefiendETH(msg.sender, msg.value, block.timestamp);
  }

  function addCustomSub(address _sub, uint _period) external onlyOwner {
    require(!subscribers[_sub].subscribed, "Already subscribed");
    _addSub(_sub, _period);
  }

  function removeSub(address _sub) external onlyOwner {
    require(subscribers[_sub].subscribed && subscribers[_sub].until < block.timestamp, "Not subscribed or subscription is not expired yet");
    subscribers[_sub].subscribed = false;
  }

  function removeAllExpiredSubs(address[] calldata _subscribers) external onlyOwner {
    for (uint i = 0; i < _subscribers.length; i++) {
      if (subscribers[_subscribers[i]].subscribed && subscribers[_subscribers[i]].until < block.timestamp) subscribers[_subscribers[i]].subscribed = false;
    }
  }

  function airdrop721(address _token, address[] calldata _to, uint[] calldata _id) external payable isEligible {
    require(isApproved(_token), "Token not approved");
    require(_to.length == _id.length, "Arrays should be the same length");
    received += msg.value;
    for (uint i = 0; i < _to.length; i++) {
      IERC721(_token).safeTransferFrom(msg.sender, _to[i], _id[i]);
    }
    emit Airdrop721(msg.sender, _token, block.timestamp);
  }

  function airdrop1155(address _token, address[] calldata _to, uint[] calldata _id, uint[] calldata _amount) external payable isEligible {
    require(isApproved(_token), "Token not approved");
    require(_to.length == _id.length && _to.length ==  _amount.length, "Arrays should be the same length");
    received += msg.value;
    for (uint i = 0; i < _to.length; i++) {
      IERC1155(_token).safeTransferFrom(msg.sender, _to[i], _id[i], _amount[i], "");
    }
    emit Airdrop1155(msg.sender, _token, block.timestamp);
  }

  function _addSub(address _sub, uint _period) private {
    subscribers[_sub].subscribed = true;
    subscribers[_sub].until = block.timestamp + _period;
    emit Subscription(_sub, block.timestamp, _period);
  }

  function isApproved(address _token) public view returns (bool) {
    return INFT(_token).isApprovedForAll(msg.sender, address(this));
  }
  
  function receivedTotal() public view onlyOwner returns (uint) {
      return received;
  }

  function checkBalance() public view onlyOwner returns (uint) {
      return address(this).balance;
  }

  function withdraw() external onlyOwner {
    owner.transfer(address(this).balance);
  }

}