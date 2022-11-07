// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IERC721 {
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;
}

interface IERC1155 {
  function safeTransferFrom(
    address from,
    address to,
    uint256 id,
    uint256 amount,
    bytes calldata data
  ) external;
}

interface IERC20 {
  function transferFrom(
    address from,
    address to,
    uint256 amount
  ) external;

  function balanceOf(address account) external view returns (uint256);

  function allowance(address owner, address spender)
    external
    view
    returns (uint);
}

interface INFT {
  function isApprovedForAll(address account, address operator)
    external
    view
    returns (bool);
}

error Unauthorized();
error NotSubscribedOrInsufficientValue();
error NotSubscribed();
error ZeroAddress();
error AlreadySubscribed();
error ValueIsLessThanMinimumFee();
error TokenNotApproved();
error ArraysHaveDifferentLength();
error InsufficientBalance();
error InsufficientAllowance();

contract NFTEasyDropV2 {
  address payable public owner;

  uint public txFee;
  uint[4] public subscriptionFees;

  mapping(address => uint) public subscribers;

  uint private received;

  event AirdropERC1155(
    address indexed _from,
    address indexed _nft,
    uint _timestamp
  );

  event AirdropERC721(
    address indexed _from,
    address indexed _nft,
    uint _timestamp
  );

  event AirdropERC20(
    address indexed _from,
    address indexed _token,
    uint _timestamp
  );

  event Subscription(
    address indexed _subscriber,
    uint _timestamp,
    uint indexed _period
  );

  event ReceivedUndefiendETH(
    address indexed _from,
    uint indexed _value,
    uint _timestamp
  );

  modifier onlyOwner() {
    if (msg.sender != owner) revert Unauthorized();
    _;
  }

  modifier isEligible() {
    if (
      subscribers[msg.sender] == 0 && msg.value < txFee && msg.sender != owner
    ) revert NotSubscribedOrInsufficientValue();
    _;
  }

  modifier checkApproval(address token) {
    if (!isApproved(token)) revert TokenNotApproved();
    _;
  }

  modifier zeroAddress(address addr) {
    if (addr == address(0)) revert ZeroAddress();
    _;
  }

  function initialize() external {
    owner = payable(msg.sender);
    txFee = 0.03 ether;
    subscriptionFees = [0.15 ether, 0.3 ether, 0.5 ether, 1 ether];
  }

  receive() external payable {
    _receive();
  }

  fallback() external payable {
    _receive();
  }

  function setOwner(address newOwner) external onlyOwner zeroAddress(newOwner) {
    owner = payable(newOwner);
  }

  function setTxFee(uint _txFee) external onlyOwner {
    txFee = _txFee;
  }

  function setSubFees(
    uint _day,
    uint _week,
    uint _month,
    uint _year
  ) external onlyOwner {
    subscriptionFees = [_day, _week, _month, _year];
  }

  function subscribe() external payable {
    if (subscribers[msg.sender] != 0) revert AlreadySubscribed();
    if (msg.value < subscriptionFees[0]) revert ValueIsLessThanMinimumFee();
    uint32[4] memory periods = [86400, 604800, 2629743, 31556926];
    uint[4] memory subFees = subscriptionFees;
    bool sub;
    for (uint i = 0; i < subFees.length; i++) {
      if (msg.value == subFees[i]) {
        _addSub(msg.sender, periods[i]);
        sub = true;
        received += msg.value;
        break;
      }
    }
    if (sub == false) _receive();
  }

  function addCustomSub(address _sub, uint _period)
    external
    onlyOwner
    zeroAddress(_sub)
  {
    if (subscribers[_sub] != 0) revert AlreadySubscribed();
    _addSub(_sub, _period);
  }

  function removeSub(address _sub) external onlyOwner zeroAddress(_sub) {
    if (subscribers[_sub] == 0) revert NotSubscribed();
    delete subscribers[_sub];
  }

  function removeAllExpiredSubs(address[] calldata _subscribers)
    external
    onlyOwner
  {
    for (uint i = 0; i < _subscribers.length; i++) {
      if (
        subscribers[_subscribers[i]] > 0 &&
        subscribers[_subscribers[i]] < block.timestamp
      ) delete subscribers[_subscribers[i]];
    }
  }

  function airdropERC721(
    address _token,
    address[] calldata _to,
    uint[] calldata _id
  ) external payable isEligible checkApproval(_token) {
    if (_to.length != _id.length) revert ArraysHaveDifferentLength();
    for (uint i = 0; i < _to.length; i++) {
      IERC721(_token).safeTransferFrom(msg.sender, _to[i], _id[i]);
    }
    received += msg.value;
    emit AirdropERC721(msg.sender, _token, block.timestamp);
  }

  function airdropERC1155(
    address _token,
    address[] calldata _to,
    uint[] calldata _id,
    uint[] calldata _amount
  ) external payable isEligible checkApproval(_token) {
    if (_to.length != _id.length || _to.length != _amount.length)
      revert ArraysHaveDifferentLength();
    for (uint i = 0; i < _to.length; i++) {
      IERC1155(_token).safeTransferFrom(
        msg.sender,
        _to[i],
        _id[i],
        _amount[i],
        ''
      );
    }
    received += msg.value;
    emit AirdropERC1155(msg.sender, _token, block.timestamp);
  }

  function airdropERC20(
    address _token,
    address[] calldata _to,
    uint[] calldata _amount,
    uint totalAmount
  ) external payable isEligible {
    if (checkBalance(_token) < totalAmount) revert InsufficientBalance();
    if (checkAllowance(_token) < totalAmount) revert InsufficientAllowance();
    if (_to.length != _amount.length) revert ArraysHaveDifferentLength();
    for (uint i = 0; i < _to.length; i++) {
      IERC20(_token).transferFrom(msg.sender, _to[i], _amount[i] * 10**18);
    }
    received += msg.value;
    emit AirdropERC20(msg.sender, _token, block.timestamp);
  }

  function _receive() private {
    received += msg.value;
    emit ReceivedUndefiendETH(msg.sender, msg.value, block.timestamp);
  }

  function _addSub(address _sub, uint _period) private zeroAddress(_sub) {
    subscribers[_sub] = block.timestamp + _period;
    emit Subscription(_sub, block.timestamp, _period);
  }

  function isApproved(address _token) public view returns (bool) {
    return INFT(_token).isApprovedForAll(msg.sender, address(this));
  }

  function checkAllowance(address _token) public view returns (uint) {
    return IERC20(_token).allowance(msg.sender, address(this));
  }

  function checkBalance(address _token) public view returns (uint) {
    return IERC20(_token).balanceOf(msg.sender);
  }

  function contractBalance() public view returns (uint) {
    return address(this).balance;
  }

  function receivedTotal() public view onlyOwner returns (uint) {
    return received;
  }

  function withdraw() external onlyOwner {
    owner.transfer(address(this).balance);
  }
}