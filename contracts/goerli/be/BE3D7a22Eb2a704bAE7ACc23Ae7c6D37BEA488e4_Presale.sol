// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./interfaces/IWETH.sol";

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
    "NOT OWNER!!");
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
  address public immutable wETHAddress;
  uint256 public immutable maxTokenSupply;
  uint256 public immutable presalePriceWei; 
  uint256 public tokenSupply;
  uint256 public minBidQuantity;
  uint256 public maxBidQuantity;
  
  // Define bids map
  mapping(address => uint256) public bids;
  mapping(address => uint256) public selectedBids;
  address[] public selectedAddresses;

  // Define contract's events
  event BidAdded(address bidderAddress, uint256 tokenQuantity);
  event BidSelected(address bidderAddress, uint256 tokenQuantity);
  event Withdraw(uint256 amount);

  constructor(address _wETHAddress, 
    uint256 _maxTokenSupply, 
    uint256 _presalePriceWei, 
    uint256 _minBidQuantity,
    uint256 _maxBidQuantity) { 
    wETHAddress= _wETHAddress;
    maxTokenSupply = _maxTokenSupply;
    presalePriceWei = _presalePriceWei;
    tokenSupply = maxTokenSupply;
    minBidQuantity = _minBidQuantity;
    maxBidQuantity = _maxBidQuantity;
    }

  /*
    *
    * Add a bid into the contract. It is only added by the contract owner. 
    * This function should be invoked after a user approves the contract to spend an amount of dollars.
    * 
  */
  function makeBid(address bidderAddress, uint256 bidQuantity) public onlyOwner {
    require(bidQuantity > minBidQuantity - 1 && bidQuantity < maxBidQuantity + 1, "Out of range"); 
    require(IWETH(wETHAddress).balanceOf(bidderAddress) > bidQuantity * presalePriceWei - 1, "Not enough funds");
    bids[bidderAddress] = bidQuantity;
    emit BidAdded(bidderAddress, bidQuantity);
  }

  /*
    *
    * Select a bid by transfering the money from the selectedAddress acount to the contract's address. 
    * It is only added by the contract owner. 
    * This function should be invoked when the contract owner wants to select a presale bid.
    * 
  */
  function selectBid(address _selectedAddress) public onlyOwner {
    IWETH wEth = IWETH(wETHAddress);
    uint256 tokensBought;
    if(bids[_selectedAddress] < tokenSupply) {
      tokensBought = bids[_selectedAddress];
    } else {
      tokensBought = tokenSupply;
    }

    uint256 amountWei = tokensBought * presalePriceWei;
    uint256 allowance = wEth.allowance(_selectedAddress, address(this));

    require(tokensBought > 0, "No tokens in bid");
    require(amountWei <= wEth.balanceOf(_selectedAddress), "Not enough tokens");
    require(allowance >= amountWei, "Token allowance small");

    tokenSupply -= tokensBought;
    selectedBids[_selectedAddress] = tokensBought;
    selectedAddresses.push(_selectedAddress);
    bids[_selectedAddress] = 0;

    require(wEth.transferFrom(_selectedAddress, address(this), amountWei), "transfer failed!");
    emit BidSelected(_selectedAddress, tokensBought);
  }

  /**
   * 
   * Withdraw all the money from the contract's account.
   * Only the contract owner can withdraw and send the money to their account.
   * 
   */
  function withdraw() public onlyOwner {
    IWETH wEth = IWETH(wETHAddress); 
    uint256 amount = wEth.balanceOf(address(this));
    wEth.transfer(this.owner(), amount);
    emit Withdraw(amount);
  }

  /**
   * Returns a list of all addresses of all selected bids
   */
  function getSelectedAddresses() public view returns(address[] memory){
    return selectedAddresses;
  }

  /**
   * Returns bid quantity
   */
  function getBidQuantity(address _bidderAddress) public view returns(uint256) {
    if (selectedBids[_bidderAddress] != 0) {
      return selectedBids[_bidderAddress];
    }
    return bids[_bidderAddress];
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address guy, uint256 wad) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function withdraw(uint256) external;

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}