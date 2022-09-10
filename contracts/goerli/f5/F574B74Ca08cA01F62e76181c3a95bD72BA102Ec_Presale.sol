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

  /**
   * 
   * TODO:
   * 1. Generalize the contract and initiate this values in the constructor
   * 2. Add guards on limits of how the contract can take in total from bidders
   * 
   */

  uint256 maximumSupply = 500;
  uint256 presalePriceWei = 25000000000000000; 
  uint256 maxApprovedAddresses = 1000; 
  uint256 limitWithdraw = 125000000000000000000;
  
  // Define bids map
  mapping(address => uint) public bids;

  // Define contract's events
  event BidAdded(address bidderAddress, uint256 tokenAmount);
  event BidCanceled(address canceledBidAddres); 
  event BidSelected(address bidderAddress, uint256 tokenAmount);
  event Withdraw(uint256 amount);

  constructor( address _WETH) { 
    WETH = _WETH;
  }

  /*
    *
    * Add a bid into the contract. It is only added by the contract owner. 
    * This function should be invoked after a user approves the contract to spend an amount of dollars.
    * 
  */
  function makeBid(address bidderAddress, uint256 tokenAmount) onlyOwner public {
    require(tokenAmount > 0 && tokenAmount <= 5, "Can't buy more than 5 NFTs"); 
    require(IWETH(WETH).balanceOf(bidderAddress) >= tokenAmount * presalePriceWei, "Not enough funds in account");
    bids[bidderAddress] = tokenAmount;
    emit BidAdded(bidderAddress, tokenAmount);
  }

  /*
    *
    * Select a bid by transfering the money from the selectedAddress acount to the contract's address. 
    * It is only added by the contract owner. 
    * This function should be invoked when the contract owner wants to select a presale bid.
    * 
  */
  function selectBid(address _selectedAddress) onlyOwner public {
    IWETH wEth = IWETH(WETH);
    uint256 allowance = wEth.allowance(_selectedAddress, address(this));
    uint256 amount = bids[_selectedAddress] * presalePriceWei;
    require(amount >= wEth.balanceOf(_selectedAddress), "Not enough tokens on this address");
    require(allowance >= amount, "Check the token allowance");
    wEth.transferFrom(_selectedAddress, address(this), amount);
    emit BidSelected(_selectedAddress, bids[_selectedAddress]);
  }

  /**
   * 
   * Withdraw all the money from the contract's account.
   * Only the contract owner can withdraw and send the money to their account.
   * 
   */
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