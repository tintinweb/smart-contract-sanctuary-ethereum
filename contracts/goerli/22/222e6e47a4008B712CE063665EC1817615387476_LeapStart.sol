// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract LeapStart is Ownable {
  struct IP {
    address ipOwner;
    string ipMetadata; // ipfs link of IP providers description
    bool approved;
  }

  mapping(uint256 => IP) public ips;

  // optional: possibly cancel in second version
  mapping(address => uint256) public providerToIp;

  uint256 public totalIPs;

  bool public auditOn;

  /** ========== view functions ========== */
  function verifiedIP(uint256 _ipId) public view returns (bool) {
    return ips[_ipId].approved;
  }

  /** ========== main functions ========== */
  /**
   * @notice temporarily one address is only allowed to register one ip
   */
  function registerIP(string memory _ipMetadata) external {
    require(providerToIp[msg.sender] == 0, "caller has registered one ip");

    uint256 currentIP = ++totalIPs;
    IP memory ip;
    ip.ipOwner = msg.sender;
    ip.ipMetadata = _ipMetadata;
    ip.approved = !auditOn ? true : false;
    ips[currentIP] = ip;
    providerToIp[msg.sender] = currentIP;

    emit NewIPRegistered(currentIP, msg.sender, _ipMetadata);
  }

  /** ========== admin functions =========== */
  function auditSwitch() external onlyOwner {
    auditOn = !auditOn;
  }

  // optional: utilize chainlink oracle to verify ip provider's web2 authentication(i.e. twitter)
  function approveNewIP(uint256 _ipId) external onlyOwner {
    require(ips[_ipId].approved == true, "please registry IP firstly");

    _approveIP(_ipId);
  }

  /** ========== internal functions ========== */
  function _approveIP(uint256 _ipId) internal {
    require(ips[_ipId].approved = false, "target IP has been activated");

    ips[_ipId].approved = true;

    emit IPApproved(_ipId);
  }

  /** ========== event ========== */
  event NewIPRegistered(uint256 indexed _newIPId, address indexed _registerAddress, string _ipMetadata);

  event IPApproved(uint256 indexed _ipId);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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