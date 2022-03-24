/**
 *Submitted for verification at Etherscan.io on 2022-03-23
*/

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
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

// File: contracts/ICE.sol


// ICE (In Chain Entropy)

pragma solidity ^0.8.13;


contract ICE is Ownable {

  uint128 public lastEntropyIndex;
  uint128 public entropyCount;

  struct Entropy {
    address EntropyAddress;
    uint64 previousValue;
  }

  mapping (uint => Entropy) entropyList;
  mapping (address => bool) entropyAddresses;

  event entropyAdded(address _entropyAddress);
  event entropyModified(uint256 _index, address _newAddress, uint256 _previousValue);    
  event checkForStaleIndex(uint128 _lastIndex, uint256 _lastEntropyValue);
  event entropyServed(address _contractServed, uint256 _entropyValue);

  function viewEntropyEntryDetails(uint256 _index) external view returns (address SavedEntropyAddress) {
    require(entropyCount > 0, "No entropy defined");
    require(entropyList[_index].EntropyAddress != 0x0000000000000000000000000000000000000000, "Entry with this index doesn't exist");
    return (entropyList[_index].EntropyAddress) ;
  }
  
  function addToEntropylist(address _entropyAddress) external onlyOwner returns (bool) {
    require(!entropyAddresses[_entropyAddress], "Entropy address is already in the list");
    Entropy memory newEntropyEntry = Entropy(_entropyAddress, 0);
    entropyCount = entropyCount + 1;
    entropyList[entropyCount] = newEntropyEntry;
    entropyAddresses[_entropyAddress] = true;
    emit entropyAdded(_entropyAddress);
    return true;
  }

  function modifyEntropyByIndex(uint256 _index, address _newAddress) external onlyOwner returns (bool) {
    address oldEntropyAddress = entropyList[_index].EntropyAddress;
    delete entropyAddresses[oldEntropyAddress];
    entropyList[_index].EntropyAddress = _newAddress;
    entropyList[_index].previousValue = 0;
    emit entropyModified(_index, _newAddress, 0);
    return true;
  }

  function deleteEntropyList() external onlyOwner returns (bool) {
    require(entropyCount > 0, "No entropy defined");
    for (uint i = 1; i <= entropyCount; i++){
        delete entropyAddresses[entropyList[i].EntropyAddress];
        delete entropyList[i];
    }
    entropyCount = 0;
    return true;
  }

  function getEntropy() external returns(uint256 entropy){
    uint256 returnedEntropy;
    bool returnedStale;
    (returnedEntropy, returnedStale) = getCurrentEntropy();
    if (returnedStale == true) {
        (returnedEntropy, returnedStale) = getCurrentEntropy();}
    if (returnedStale == true) {
        (returnedEntropy, returnedStale) = getCurrentEntropy();}
 
    uint256 hashedEntropy = (uint256(keccak256(abi.encode(returnedEntropy + block.timestamp))));    
    emit entropyServed(msg.sender, hashedEntropy);
    
    return(hashedEntropy);
  }

  function getCurrentEntropy() private returns(uint256 currentEntropy, bool StaleQuery){
    lastEntropyIndex = lastEntropyIndex + 1;
    if (lastEntropyIndex > entropyCount) (lastEntropyIndex = 1);
    uint256 currentEntropyValue = entropyList[lastEntropyIndex].EntropyAddress.balance;
    if (currentEntropyValue == 0 || currentEntropyValue == entropyList[lastEntropyIndex].previousValue) {
        emit checkForStaleIndex(lastEntropyIndex, currentEntropyValue);
        return(currentEntropyValue, true);
    }
    entropyList[lastEntropyIndex].previousValue = uint64(currentEntropyValue);
    return(currentEntropyValue, false);
  }
}