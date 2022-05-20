// SPDX-License-Identifier: UNLICENSED
// Copyright 2017 Bittrex
pragma solidity ^0.8.0;

abstract contract AbstractSweeper {
  function sweep(address token, uint256 amount) public virtual returns (bool);

  Controller controller;

  constructor(address _controller) {
    controller = Controller(_controller);
  }

  modifier canSweep() {
    require(
      msg.sender == controller.authorizedCaller() ||
        msg.sender == controller.owner(),
      "Not admin"
    );
    require(!controller.halted(), "Is halted");
    _;
  }
}

interface Token {
  function balanceOf(address a) external view returns (uint256);

  function transfer(address a, uint256 val) external returns (bool);
}

contract DefaultSweeper is AbstractSweeper {
  constructor(address controller) AbstractSweeper(controller) {}

  function sweep(address _token, uint256 _amount)
    public
    override
    canSweep
    returns (bool)
  {
    bool success = false;
    address payable destination = controller.destination();

    if (_token != address(0)) {
      Token token = Token(_token);
      uint256 amount = _amount;
      if (amount > token.balanceOf(address(this))) {
        return false;
      }

      success = token.transfer(destination, amount);
    } else {
      // If _token address is set to 0, we assume that the token is ETH
      uint256 amountInWei = _amount;
      if (amountInWei > address(this).balance) {
        return false;
      }

      success = destination.send(amountInWei);
    }

    if (success) {
      controller.logSweep(address(this), destination, _token, _amount);
    }
    return success;
  }
}

contract UserWallet {
  Controller sweeperList;

  constructor(address _sweeperlist) {
    sweeperList = Controller(_sweeperlist);
  }

  receive() external payable {
    address payable destination = sweeperList.destination();
    destination.transfer(msg.value);
    // Log ether forwarding. Refer to ether with the zero address
    sweeperList.logSweep(address(this), destination, address(0), msg.value);
  }

  // ERC223 added this function to the interface after solidity v0.6.0
  // https://github.com/ethereum/EIPs/issues/223#issuecomment-921846478
  function tokenReceived(
    address _from,
    uint256 _value,
    bytes calldata _data
  ) public pure {
    (_from);
    (_value);
    (_data);
  }

  function tokenFallback(
    address _from,
    uint256 _amount,
    bytes calldata _data
  ) public pure {
    tokenReceived(_from, _amount, _data);
  }

  function sweep(address _token, uint256 _amount)
    public
    returns (bool, bytes memory)
  {
    (_amount);
    return sweeperList.sweeperOf(_token).delegatecall(msg.data);
  }
}

contract Controller {
  address public owner;
  address public authorizedCaller;

  address payable public destination;

  bool public halted;

  // event Bytecode(bytes payload);
  event LogNewWallet(address receiver);
  event LogSweep(
    address indexed from,
    address indexed to,
    address indexed token,
    uint256 amount
  );

  modifier onlyOwner() {
    require(msg.sender == owner, "OnlyOwner:Sender has not permissions");
    _;
  }

  modifier onlyAuthorizedCaller() {
    // This modifier is not used
    require(msg.sender == authorizedCaller, "Not authorized");
    _;
  }

  modifier onlyAdmins() {
    require(msg.sender == authorizedCaller || msg.sender == owner, "Not admin");
    _;
  }

  constructor() {
    owner = msg.sender;
    destination = payable(msg.sender);
    authorizedCaller = msg.sender;
  }

  function changeAuthorizedCaller(address _newCaller) public onlyOwner {
    authorizedCaller = _newCaller;
  }

  function changeDestination(address payable _dest) public onlyOwner {
    destination = _dest;
  }

  function changeOwner(address _owner) public onlyOwner {
    owner = _owner;
  }

  function expectedNewWallet(bytes32 salt)
    public
    view
    returns (address predictedAddress)
  {
    predictedAddress = address(
      uint160(
        uint256(
          keccak256(
            abi.encodePacked(
              bytes1(0xff),
              address(this),
              salt,
              keccak256(
                abi.encodePacked(
                  type(UserWallet).creationCode,
                  abi.encode(address(this))
                )
              )
            )
          )
        )
      )
    );
  }

  function makeWallet(bytes32 salt) public returns (address newAddr) {
    UserWallet newWallet = new UserWallet{salt: salt}(address(this));
    newAddr = address(newWallet);
    emit LogNewWallet(newAddr);
  }

  function halt() public onlyAdmins {
    halted = true;
  }

  function start() public onlyOwner {
    halted = false;
  }

  // DefaultSweeper is deployed automatically together with Controller
  DefaultSweeper defaultSweeper = new DefaultSweeper(address(this));
  address public defaultSweeperAddress = address(defaultSweeper);

  mapping(address => address) sweepers;

  function addSweeper(address _token, address _sweeper) public onlyOwner {
    sweepers[_token] = _sweeper;
  }

  function sweeperOf(address _token) public view returns (address) {
    address sweeper = sweepers[_token];
    if (sweeper == address(0)) sweeper = defaultSweeperAddress;
    return sweeper;
  }

  function logSweep(
    address from,
    address to,
    address token,
    uint256 amount
  ) public {
    emit LogSweep(from, to, token, amount);
  }
}