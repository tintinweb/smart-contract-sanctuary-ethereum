// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./interfaces/IWETH.sol";

error Unauthorized(address caller);
error InsufficientTokenSupply();
error TransferFailed();

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
    if(isOwner() != true)
      revert Unauthorized(msg.sender);
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
  uint256 public immutable maxTokenSupply;
  uint256 public immutable presalePriceWei; 
  uint256 public tokenSupply;
  IWETH private wETH; 
  
  // Define bids map
  mapping(address => uint256) public selectedBids;

  // Define contract's events
  event BidSelected(address bidderAddress, uint256 tokenQuantity);
  event Withdraw(uint256 amount);

  constructor(address _wETHAddress, 
    uint256 _maxTokenSupply, 
    uint256 _presalePriceWei) { 
    wETH = IWETH(_wETHAddress);
    maxTokenSupply = _maxTokenSupply;
    presalePriceWei = _presalePriceWei;
    tokenSupply = maxTokenSupply;
    }

  /*
    *
    * Select a bid by transfering the money from the selectedAddress acount to the contract's address. 
    * It is only added by the contract owner. 
    * This function should be invoked when the contract owner wants to select a presale bid.
    * 
  */
  function selectBid(address _selectedAddress, uint256 _bidQuantity) external onlyOwner {
    if(_bidQuantity > tokenSupply)
      revert InsufficientTokenSupply();

    uint256 amountWei = _bidQuantity * presalePriceWei;
    tokenSupply -= _bidQuantity;
    selectedBids[_selectedAddress] = _bidQuantity;

    if(wETH.transferFrom(_selectedAddress, address(this), amountWei) != true)
      revert TransferFailed();

    emit BidSelected(_selectedAddress, _bidQuantity);
  }

  /**
   * 
   * Withdraw all the money from the contract's account.
   * Only the contract owner can withdraw and send the money to their account.
   * 
   */
  function withdraw() external onlyOwner {
    uint256 amount = wETH.balanceOf(address(this));
    
    wETH.transfer(owner(), amount);
    emit Withdraw(amount);
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