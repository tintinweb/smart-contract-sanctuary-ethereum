// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import './interfaces/IWETH.sol';

contract Ownable 
{    
  // Variable that maintains 
  // owner address
  address private _owner;
  
  // Sets the original owner of 
  // contract when it is deployed
  constructor()
  {
    _owner = msg.sender;
  }
  
  // Publicly exposes who is the
  // owner of this contract
  function owner() public view returns(address) 
  {
    return _owner;
  }
  
  // onlyOwner modifier that validates only 
  // if caller of function is contract owner, 
  // otherwise not
  modifier onlyOwner() 
  {
    require(isOwner(),
    "Function accessible only by the owner !!");
    _;
  }
  
  // function for owners to verify their ownership. 
  // Returns true for owners otherwise false
  function isOwner() public view returns(bool) 
  {
    return msg.sender == _owner;
  }
}

contract Presale is Ownable {
  address public immutable WETH;

  uint256 maximumSupply = 500;
  uint256 presalePriceWei = 250000000000000000; 
  uint256 maxApprovedAddresses = 1000; 
  uint256 limitWithdraw = 125000000000000000000;
  
  // Define maps
  mapping(address => uint) public bids;

  // Define contract's events
  event BidAdded(address bidderAddress, uint256 tokenAmount);
  event BidCanceled(address canceledBidAddres); 
  event BidSelected(address bidderAddress, uint256 tokenAmount);
  event Withdraw(uint256 amount);

  constructor( address _WETH) { 
    WETH = _WETH;
  }

  function makeBid(address bidderAddress, uint256 tokenAmount) onlyOwner public {
    require(tokenAmount > 0 && tokenAmount <= 5, "Can't buy more than 5 NFTs"); 
    require(address(bidderAddress).balance >= tokenAmount * presalePriceWei);
    bids[bidderAddress] = tokenAmount;
    emit BidAdded(bidderAddress, tokenAmount);
  }

  function selectBid(address _selectedAddress) onlyOwner public {
    IWETH wEth = IWETH(WETH);
    uint256 allowance = wEth.allowance(_selectedAddress, address(this));
    uint256 amount = bids[_selectedAddress] * presalePriceWei;
    require(amount >= wEth.balanceOf(_selectedAddress), "Not enough tokens on this address");
    require(allowance >= amount, "Check the token allowance");
    wEth.transferFrom(_selectedAddress, address(this), amount);
    emit BidSelected(_selectedAddress, bids[_selectedAddress]);
  }

  function withdraw() onlyOwner public {
    IWETH wEth = IWETH(WETH); 
    uint256 amount = wEth.balanceOf(address(this));
    wEth.transfer(this.owner(), amount);
    emit Withdraw(amount);
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function withdraw(uint) external;
    
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}