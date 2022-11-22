// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IOperator.sol";

contract Operator is Ownable, IOperator {
  uint256 internal _maxFeeBPS = 3000; // default value is 30%
  uint256 internal _baseFeeBPS;
  uint256 internal _managementFee;

  mapping(address => uint256) public particularFees; // particularFees[clientAddress]

  mapping(address => bool) internal _isRegisteredProvider;

  constructor(uint256 baseFeeBPS, uint256 managementFee) {
    setBaseFee(baseFeeBPS);
    setManagementFee(managementFee);
  }

  function setMaxFee(uint256 feeBPS) external onlyOwner() {
    require(
        (feeBPS <= 10000) && (feeBPS >= 0),
        "maxFeeBPS outside limits"
    );
    emit UpdateFee(FeeType.MaxFeeBPS, _maxFeeBPS, feeBPS);
    _maxFeeBPS = feeBPS;
	}

  function setBaseFee(uint256 baseFeeBPS) public onlyOwner() {
    require(
        (baseFeeBPS <= _maxFeeBPS) && (baseFeeBPS >= 0),
        "baseFeeBPS outside limits"
    );
    emit UpdateFee(FeeType.BaseFeeBPS, _baseFeeBPS, baseFeeBPS);
    _baseFeeBPS = baseFeeBPS;
	}

  function setManagementFee(uint256 managementFee) public onlyOwner() {
    emit UpdateFee(FeeType.ManagementFee, _managementFee, managementFee);
    _managementFee = managementFee;
	}

  function registerAsProvider() external {
    require(
        !_isRegisteredProvider[msg.sender],
        "Provider already registered"
    );
    _isRegisteredProvider[msg.sender] = true;
    emit RegisterProvider(msg.sender);
  }

  function unRegisterAsProvider() external {
    require(
        _isRegisteredProvider[msg.sender],
        "Provider should be registered"
    );
    _isRegisteredProvider[msg.sender] = false;
    emit UnRegisterProvider(msg.sender);
  }

  function isRegisteredProvider(address addr) external view returns (bool) {
    return _isRegisteredProvider[addr];
  }

  function setSpecialConditionFee(address provider, uint256 specialFee) external onlyOwner() {
    require(
        (specialFee <= _maxFeeBPS) && (specialFee >= 0),
        "specialFee outside limits"
    );
    particularFees[provider] = specialFee;
  } 

  function getBaseFee(address provider) external view returns (uint256) {
    return
      (particularFees[provider] == 0)
          ? _baseFeeBPS
          : particularFees[provider];
  }

  function getManagementFee() external view returns (uint256) {
    return _managementFee;
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