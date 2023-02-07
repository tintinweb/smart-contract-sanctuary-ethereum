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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "./interfaces/IWETH.sol";

error Unauthorized(address caller);
error InsufficientTokenSupply();
error TransferFailed();

contract Ownable
{    
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  
  /**
   * @dev Sets the original owner of contract when deployed
   */
  constructor()
  {
    _owner = msg.sender;
  }

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() public view returns(address) 
  {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() 
  {
    if(_isOwner() != true)
      revert Unauthorized(msg.sender);
    _;
  }

  /**
   * @dev Returns bool depending on message sender's ownership.
   */
  function _isOwner() internal view returns(bool)
  {
    return msg.sender == _owner;
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public virtual onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Internal function without access restriction.
   */
  function _transferOwnership(address newOwner) internal virtual {
    address oldOwner = _owner;
    _owner = newOwner;
    emit OwnershipTransferred(oldOwner, newOwner);
  }
}

contract WaaaPresale is Ownable {
  address private _bidSelector;
  uint256 public immutable presalePriceWei; 
  IWETH private wETH; 
  
  mapping(address => uint256) public selectedBids;

  event BidSelected(address bidderAddress, uint256 quantity);
  event Withdraw(uint256 amount);

  constructor(address _wETHAddress, uint256 _presalePriceWei) { 
    wETH = IWETH(_wETHAddress);
    presalePriceWei = _presalePriceWei;
  }
  
  function setBidSelector(address _newBidSelector) external onlyOwner {
    _bidSelector = _newBidSelector;
  }

  /**
   * @notice Transfers wETH from (`_selectedAddress`) to contract.
   * wETH is calculated using (`_quantity`) and base price of 1 bid.
   * This function should only be invoked when the contract owner wants to select a presale bid.
   */
  function selectBid(address _selectedAddress, uint256 _quantity) external {
    if ( !(msg.sender == _bidSelector || _isOwner()) ) {
        revert Unauthorized(msg.sender);
    }
    uint256 amountWei = _quantity * presalePriceWei;
    selectedBids[_selectedAddress] = _quantity;

    if(wETH.transferFrom(_selectedAddress, address(this), amountWei) != true)
      revert TransferFailed();

    emit BidSelected(_selectedAddress, _quantity);
  }

  /**
   * @notice Withdraw all wETH from contract and transfer to owner.
   */
  function withdraw() external onlyOwner {
    uint256 amount = wETH.balanceOf(address(this));
    
    wETH.transfer(owner(), amount);
    emit Withdraw(amount);
  }
}