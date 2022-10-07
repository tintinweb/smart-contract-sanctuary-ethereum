// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17 <0.9.0;

import './Ownable.sol';

contract ChallengeAccount is Ownable {
  mapping(address => uint256) public athleteFunds;

  constructor() {}

  function getBalance(address athlete) public view returns (uint256 balance) {
    return athleteFunds[athlete];
  }

  function deposit() external payable {
    athleteFunds[msg.sender] += msg.value;
  }

  function withdraw(uint256 amount) external {
    require(
      amount <= athleteFunds[msg.sender],
      'ChallengeAccount: cannot withdraw more than you have'
    );
    athleteFunds[msg.sender] -= amount;

    (bool sent, ) = payable(msg.sender).call{value: amount}('');
    require(sent, 'ChallengeAccount: Failed to send Ether');
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.17 <0.9.0;

abstract contract Ownable {
  //todo add abstract after compiler upgrade
  address private _owner;
  bool private isFirstCall = true;
  bool private isFirstCallToken = true;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  constructor() {
    _transferOwnership(msg.sender);
  }

  function owner() public view returns (address) {
    //todo add virtual
    return _owner;
  }

  modifier onlyOwner() {
    require(owner() == msg.sender, 'Ownable: caller is not the owner');
    _;
  }

  modifier onlyOwnerOrFirst() {
    require(
      owner() == msg.sender || isFirstCall,
      'Ownable: caller is not the owner'
    );
    isFirstCall = false;
    _;
  }

  modifier onlyOwnerOrFirstToken() {
    //todo find a better alternative
    require(
      owner() == msg.sender || isFirstCallToken,
      'Ownable: caller is not the owner'
    );
    isFirstCallToken = false;
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    //todo add virtual
    require(newOwner != address(0), 'Ownable: new owner is the zero address');
    _transferOwnership(newOwner);
  }

  function _transferOwnership(address newOwner) internal {
    //todo add virtual
    address oldOwner = _owner;
    _owner = newOwner;
    emit OwnershipTransferred(oldOwner, newOwner);
  }
}