/**
 *Submitted for verification at Etherscan.io on 2023-02-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
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

contract PuppyPledge is Ownable {

  event Received(address, uint);
  event Pledge(address, uint, uint);

  uint public immutable weiSoftcap;
  uint public immutable weiHardcap;
  uint public immutable rate;
  uint public immutable startTime;
  uint public endTime;
  uint public weiRaised;
  uint public totalPuppyAllocations;
  uint public participants;

  address payable public projectOwnerAddress;
  address public claimContractAddress;

  address[] private puppyAddressList;

  mapping(address => uint) public tokensAllocationPerAddress;

  
  constructor(uint _weiSoftcap, uint _weiHardcap, uint _startTime, uint _endTime, uint _rate, address payable _projectOwnerAddress) {
    
    require(_endTime > _startTime, "End Time must be after Start time");
    require(_rate > 0, "Rate is 0");
    require(_weiSoftcap > 0, "weiSoftcap must be > to 0");
    require(_weiHardcap > _weiSoftcap, "weiHardcap must be > to weiSoftcap");
    require(_projectOwnerAddress != address(0), "Wallet cannot be dead address");

    rate = _rate;
    weiSoftcap = _weiSoftcap;
    weiHardcap = _weiHardcap;
    startTime = _startTime;
    endTime = _endTime;
    projectOwnerAddress = _projectOwnerAddress;
    totalPuppyAllocations = 0;

  }

  receive() external payable {
    getSomePuppies();
    emit Received(msg.sender, msg.value);
  }

  function getBalance() public view returns (uint) {

    return address(this).balance;

  }

  function weiAmountLeft() public view returns (uint) {

    return (weiHardcap - weiRaised);

  }

  function setNewEndTime(uint _endTime) public onlyOwner {

    require(_endTime > endTime, "New End Time must be after current End Time");
    endTime = _endTime;

  }

  function setClaimContractAddress(address _newClaimContractAddress) public onlyOwner {

    claimContractAddress = _newClaimContractAddress;

  }

  function getSomePuppies() public payable {

    uint weiAmount = msg.value;

    _preValidate(weiAmount);

    uint tokensAmount = weiAmount * rate;

    weiRaised = weiRaised + weiAmount;

    _forwardFunds();

    _allocateTokens(msg.sender, tokensAmount);

    emit Pledge(msg.sender, weiAmount, tokensAmount);

  }

  function getPuppyAddressList() external view returns (address[] memory) {

    require(msg.sender == claimContractAddress, 'Only the claim contract can read');
    return puppyAddressList;

  }

  function _preValidate(uint weiAmount) internal view {

    require(block.timestamp <= endTime, "Pledge ended");
    require((weiRaised + weiAmount) <= weiHardcap, "Hardcap reached");
    this;

  }

  function _allocateTokens(address puppyAddress, uint tokens) internal {

    if (tokensAllocationPerAddress[puppyAddress] > 0) {

      tokensAllocationPerAddress[puppyAddress] += tokens;

    } else {

      puppyAddressList.push(puppyAddress);
      participants += 1;
      tokensAllocationPerAddress[puppyAddress] = tokens;

    }

    totalPuppyAllocations += tokens;

  }

  function _forwardFunds() internal {

    projectOwnerAddress.transfer(msg.value);
    
  }
  
}