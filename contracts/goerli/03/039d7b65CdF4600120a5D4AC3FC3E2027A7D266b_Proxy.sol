// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IOperator.sol";
import "./IProxy.sol";

contract Proxy is Ownable, IProxy {

    IOperator public operator;

    mapping(string => address) public resourceContractAddress;
    mapping(string => bool) public enabled;

    // owners for each resourceId
    mapping(string => address) public owners;

    constructor(address operatorAddress) {
        operator = IOperator(operatorAddress);
    }

    function getOperator() external view returns (address) {
        return address(operator);
    }
    
    function updateOperator(address newOperatorAddress) external onlyOwner() {
        operator = IOperator(newOperatorAddress);
        emit UpdateOperator(newOperatorAddress);
    }

    modifier onlyRegisteredProviders() {
        require(operator.isRegisteredProvider(msg.sender), "Not a registed provider");
        _;
    }

    function isRegisteredProvider(address addr) external view returns (bool) {
    return operator.isRegisteredProvider(addr);
  }

    modifier onlyProvider(string memory resourceId) {
        require(owners[resourceId] == msg.sender || owner() == msg.sender, "Operation not allowed");
        _;
    }

    function registerResource(string memory resourceId, address contractAddress) external payable onlyRegisteredProviders() {
        require(resourceContractAddress[resourceId] == address(0), "ResourceId already exists");
        require(msg.value == operator.getManagementFee(), "Exact fee must provided");
        resourceContractAddress[resourceId] = contractAddress;
        enabled[resourceId] = true;
        owners[resourceId] = msg.sender;
        emit ResourceRegistered(contractAddress, resourceId);
    }
    
    function enable(string memory resourceId) external onlyProvider(resourceId) {
        enabled[resourceId] = true;
        emit ResourceEnabled(resourceId);
    }
    
    function disable(string memory resourceId) external onlyProvider(resourceId) {
        enabled[resourceId] = false;
        emit ResourceDisabled(resourceId);
    }
    
    function modifyResource(string memory resourceId, address newResourceContractAddress)
        external onlyProvider(resourceId)
    {
        require(resourceContractAddress[resourceId] != address(0) && newResourceContractAddress != address(0), "Wrong parameter value");
        address currentAddress = resourceContractAddress[resourceId];
        resourceContractAddress[resourceId] = newResourceContractAddress;
        emit ResourceModified(resourceId, currentAddress, newResourceContractAddress);
    }

    function deleteResource(string memory resourceId) external onlyProvider(resourceId) {
        
        enabled[resourceId] = false;
        resourceContractAddress[resourceId] = address(0);
        emit ResourceDeleted(resourceId);
    }

    function withdraw(uint256 amount) external onlyOwner() {
        uint256 currentBalance = address(this).balance;
        require(
            currentBalance >= amount,
            "Not enough balance to withdraw specified amount"
        );
        require(
            amount > 0,
            "Withdraw: cannot withdraw zero amount"
        );
        _transfer(payable(owner()), amount);
        emit Withdraw(amount);
    }

    function _transfer(address payable _to, uint256 amount) internal {
        (bool success, ) = _to.call{value: amount}("");
        require(success, "Unable to send value, recipient may have reverted");
    }

    receive() external payable {}
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

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

interface IOperator {
  event UpdateFee(FeeType indexed feeType, uint256 oldValue, uint256 newValue);
  event RegisterProvider(address indexed provider);
  event UnRegisterProvider(address indexed provider);

  enum FeeType {
    MaxFeeBPS,
    BaseFeeBPS,
    ManagementFee
  }

  function setMaxFee(uint256 feeBPS) external;
  function setBaseFee(uint256 baseFeeBPS) external;
  function registerAsProvider() external;
  function unRegisterAsProvider() external;
  function isRegisteredProvider(address addr) external view returns (bool);
  function setSpecialConditionFee(address provider, uint256 specialFee) external;
  function getBaseFee(address provider) external view returns (uint256);
  function getManagementFee() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

interface IProxy {
  event ResourceRegistered(address indexed resource, string indexed resourceId);
  event ResourceModified(
      string indexed resourceId,
      address currentAddress,
      address newAddress
  );
  event ResourceEnabled(string indexed resourceContractAddress);
  event ResourceDisabled(string indexed resourceContractAddress);
  event ResourceDeleted(string indexed resourceId);
  event Withdraw(uint256 amount);
  event UpdateOperator(address indexed newOperatorAddress);

  function getOperator() external view returns (address);
  function isRegisteredProvider(address addr) external view returns (bool);
  function updateOperator(address newOperatorAddress) external;
  function registerResource(string memory resourceId, address contractAddress) external payable;
  function enable(string memory resourceId) external;
  function disable(string memory resourceId) external;
  function modifyResource(string memory resourceId, address newResourceContractAddress) external;
  function deleteResource(string memory resourceId) external;
  function withdraw(uint256 amount) external;
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