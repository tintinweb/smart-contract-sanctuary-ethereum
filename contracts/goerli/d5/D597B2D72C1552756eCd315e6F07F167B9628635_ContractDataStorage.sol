// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * Explaining the `init` variable within saveData:
 *
 * 61_00_00 -- PUSH2 (size)
 * 60_00 -- PUSH1 (code position)
 * 60_00 -- PUSH1 (mem position)
 * 39 CODECOPY
 * 61_00_00 PUSH2 (size)
 * 60_00 PUSH1 (mem position)
 * f3 RETURN
 *
 **/

contract ContractDataStorage is Ownable {

  struct ContractData {
    address rawContract;
    uint128 size;
    uint128 offset;
  }

  struct ContractDataPages {
    uint256 maxPageNumber;
    bool exists;
    mapping (uint256 => ContractData) pages;
  }

  mapping (string => ContractDataPages) internal _contractDataPages;

  mapping (address => bool) internal _controllers;

  constructor() {
    updateController(_msgSender(), true);
  }

  /**
   * Access Control
   **/
  function updateController(address _controller, bool _status) public onlyOwner {
    _controllers[_controller] = _status;
  }

  modifier onlyController() {
    require(_controllers[_msgSender()], "ContractDataStorage: caller is not a controller");
    _;
  }

  /**
   * Storage & Revocation
   **/

  function saveData(
    string memory _key,
    uint128 _pageNumber,
    bytes memory _b
  )
    public
    onlyController
  {
    require(_b.length < 24576, "SvgStorage: Exceeded 24,576 bytes max contract size");

    // Create the header for the contract data
    bytes memory init = hex"610000_600e_6000_39_610000_6000_f3";
    bytes1 size1 = bytes1(uint8(_b.length));
    bytes1 size2 = bytes1(uint8(_b.length >> 8));
    init[2] = size1;
    init[1] = size2;
    init[10] = size1;
    init[9] = size2;

    // Prepare the code for storage in a contract
    bytes memory code = abi.encodePacked(init, _b);

    // Create the contract
    address dataContract;
    assembly {
      dataContract := create(0, add(code, 32), mload(code))
      if eq(dataContract, 0) {
        returndatacopy(0, 0, returndatasize())
        revert(0, returndatasize())
      }
    }

    // Store the record of the contract
    saveDataForDeployedContract(
      _key,
      _pageNumber,
      dataContract,
      uint128(_b.length),
      0
    );
  }

  function saveDataForDeployedContract(
    string memory _key,
    uint256 _pageNumber,
    address dataContract,
    uint128 _size,
    uint128 _offset
  )
    public
    onlyController
  {
    // Pull the current data for the contractData
    ContractDataPages storage _cdPages = _contractDataPages[_key];

    // Store the maximum page
    if (_cdPages.maxPageNumber < _pageNumber) {
      _cdPages.maxPageNumber = _pageNumber;
    }

    // Keep track of the existance of this key
    _cdPages.exists = true;

    // Add the page to the location needed
    _cdPages.pages[_pageNumber] = ContractData(
      dataContract,
      _size,
      _offset
    );
  }

  function revokeContractData(
    string memory _key
  )
    public
    onlyController
  {
    delete _contractDataPages[_key];
  }

  function getSizeOfPages(
    string memory _key
  )
    public
    view
    returns (uint256)
  {
    // For all data within the contract data pages, iterate over and compile them
    ContractDataPages storage _cdPages = _contractDataPages[_key];

    // Determine the total size
    uint256 totalSize;
    for (uint256 idx; idx <= _cdPages.maxPageNumber; idx++) {
      totalSize += _cdPages.pages[idx].size;
    }

    return totalSize;
  }

  function getData(
    string memory _key
  )
    public
    view
    returns (bytes memory)
  {
    // Get the total size
    uint256 totalSize = getSizeOfPages(_key);

    // Create a region large enough for all of the data
    bytes memory _totalData = new bytes(totalSize);

    // Retrieve the pages
    ContractDataPages storage _cdPages = _contractDataPages[_key];

    // For each page, pull and compile
    uint256 currentPointer = 32;
    for (uint256 idx; idx <= _cdPages.maxPageNumber; idx++) {
      ContractData storage dataPage = _cdPages.pages[idx];
      address dataContract = dataPage.rawContract;
      uint256 size = uint256(dataPage.size);
      uint256 offset = uint256(dataPage.offset);

      // Copy directly to total data
      assembly {
        extcodecopy(dataContract, add(_totalData, currentPointer), offset, size)
      }

      // Update the current pointer
      currentPointer += size;
    }

    return _totalData;
  }

  function getDataForAll(string[] memory _keys)
    public
    view
    returns (bytes memory)
  {
    // Get the total size of all of the keys
    uint256 totalSize;
    for (uint256 idx; idx < _keys.length; idx++) {
      totalSize += getSizeOfPages(_keys[idx]);
    }

    // Create a region large enough for all of the data
    bytes memory _totalData = new bytes(totalSize);

    // For each key, pull down all data
    uint256 currentPointer = 32;
    for (uint256 idx; idx < _keys.length; idx++) {
      // Retrieve the set of pages
      ContractDataPages storage _cdPages = _contractDataPages[_keys[idx]];

      // For each page, pull and compile
      for (uint256 innerIdx; innerIdx <= _cdPages.maxPageNumber; innerIdx++) {
        ContractData storage dataPage = _cdPages.pages[innerIdx];
        address dataContract = dataPage.rawContract;
        uint256 size = uint256(dataPage.size);
        uint256 offset = uint256(dataPage.offset);

        // Copy directly to total data
        assembly {
          extcodecopy(dataContract, add(_totalData, currentPointer), offset, size)
        }

        // Update the current pointer
        currentPointer += size;
      }
    }

    return _totalData;
  }

  function hasKey(string memory _key)
    public
    view
    returns (bool)
  {
    return _contractDataPages[_key].exists;
  }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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