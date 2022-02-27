/**
 *Submitted for verification at Etherscan.io on 2022-02-26
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract N2BridgeETH {

  uint chainId;
  address public admin;
  IERC20 public token;
  
  mapping(address => mapping(uint => bool)) public processedNonces;
  mapping(address => uint) public nonces;

  enum Step { Deposit, Withdraw }
  event Transfer(
    address from,
    address to,
    uint destChainId,
    uint amount,
    uint date,
    uint nonce,
    bytes32 signature,
    Step indexed step
  );

  constructor() {
    admin = msg.sender;
    uint _chainId;
    assembly {
        _chainId := chainid()
    }
    chainId = _chainId;
  }

  modifier onlyAdmin() {
    require(admin == msg.sender, "Only Admin can perform this operation.");
    _;
  }

  function setToken(address _token) external onlyAdmin {
    token = IERC20(_token);
    token.approve(address(this), type(uint).max);
  }

  function deposit(uint amount)  public onlyAdmin {
    require(token.balanceOf(admin) >= amount, "not sufficient fund");

    // deposit from the admin to the bridge
    token.transferFrom(admin, address(this), amount);
  }

  function deposit(address to, uint destChainId, uint amount, uint nonce)  public {
    require(nonces[msg.sender] == nonce, 'transfer already processed');
    nonces[msg.sender] += 1;

    // send tokens via the owner
    token.transferFrom(msg.sender, admin, amount);

    bytes32 signature = keccak256(abi.encodePacked(msg.sender, to, chainId, destChainId, amount, nonce));
    
    emit Transfer(
      msg.sender,
      to,
      destChainId,
      amount,
      block.timestamp,
      nonce,
      signature,
      Step.Deposit
    );
  }

  function withdraw(
    address from, 
    address to, 
    uint srcChainId,
    uint amount, 
    uint nonce,
    bytes32 signature
  )  public {
    bytes32 _signature = keccak256(abi.encodePacked(
      from, 
      to, 
      srcChainId,
      chainId,
      amount,
      nonce
    ));
    require(_signature == signature , 'wrong signature');
    require(processedNonces[from][nonce] == false, 'transfer already processed');
    processedNonces[from][nonce] = true;
    
    // send tokens via the owner
    token.transferFrom(admin, to, amount);

    emit Transfer(
      from,
      to,
      chainId,
      amount,
      block.timestamp,
      nonce,
      signature,
      Step.Withdraw
    );
  }

}