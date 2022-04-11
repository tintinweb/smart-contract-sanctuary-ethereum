/**
 *Submitted for verification at Etherscan.io on 2022-04-11
*/

// File: storage/ShariaHubStorageInterface.sol

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;


/**
 * Interface for the eternal storage.
 * Thanks RocketPool!
 * https://github.com/rocket-pool/rocketpool/blob/master/contracts/interface/RocketStorageInterface.sol
 */
interface ShariaHubStorageInterface {

    //modifier for access in sets and deletes
    // modifier onlyEthicHubContracts() {_;}

    // Setters
    function setAddress(bytes32 _key, address _value) external;
    function setUint(bytes32 _key, uint _value) external;
    function setString(bytes32 _key, string calldata _value) external;
    function setBytes(bytes32 _key, bytes calldata _value) external;
    function setBool(bytes32 _key, bool _value) external;
    function setInt(bytes32 _key, int _value) external;
    // Deleters
    function deleteAddress(bytes32 _key) external;
    function deleteUint(bytes32 _key) external;
    function deleteString(bytes32 _key) external;
    function deleteBytes(bytes32 _key) external;
    function deleteBool(bytes32 _key) external;
    function deleteInt(bytes32 _key) external;

    // Getters
    function getAddress(bytes32 _key) external view returns (address);
    function getUint(bytes32 _key) external view returns (uint);
    function getString(bytes32 _key) external view returns (string memory);
    function getBytes(bytes32 _key) external view returns (bytes memory);
    function getBool(bytes32 _key) external view returns (bool);
    function getInt(bytes32 _key) external view returns (int);
}

// File: @openzeppelin/upgrades/contracts/Initializable.sol

pragma solidity ^0.8.9;


/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

// File: ShariaHubBase.sol



pragma solidity ^0.8.9;



contract ShariaHubBase is Initializable {

    uint8 public version;

    ShariaHubStorageInterface public shariaHubStorage;

    function initialize(address _shariaHubStorage, uint8 _version) public initializer {
        require(address(_shariaHubStorage) != address(0), "Storage address cannot be zero address");
        shariaHubStorage = ShariaHubStorageInterface(_shariaHubStorage);
        version = _version;
    }
}

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.9;


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

// File: arbitrage/ShariaHubArbitrage.sol


pragma solidity ^0.8.9;




/**
 * @title ShariaHubArbitrage
 * @dev This contract will assign an arbiter for a lending contract.
 * The arbiter is the only role allowed to change the borrower address for a lending contract
 * The nature of the arbiter (wallet, voting contract...) will be determined each case.
 * This is an emergency mechanism only, in case of compromised or lost borrower accounts.
 */

contract ShariaHubArbitrage is ShariaHubBase, Ownable {

    // uint8 public version;
    // ShariaHubStorageInterface public ShariaHubStorage;

    event ArbiterAssigned (
        address indexed _arbiter, // Address of the arbiter
        address indexed _lendingContract // Address of the lending contract
    );

    event ArbiterRevoked (
        address indexed _arbiter, // Address of the arbiter
        address indexed _lendingContract // Address of the lending contract
    );

    constructor(address _shariaHubStorage)  {
        require(address(_shariaHubStorage) != address(0), "Storage address cannot be zero address");

        shariaHubStorage = ShariaHubStorageInterface(_shariaHubStorage);
        version = 1;

        // Ownable.initialize(msg.sender);
    }

    function assignArbiterForLendingContract(address _arbiter, address _lendingContract) public onlyOwner {
        require(_arbiter != address(0), "Aribter address is not valid");
        require(_lendingContract != address(0), "Lending contract address is not valid");
        require(_lendingContract == shariaHubStorage.getAddress(keccak256(abi.encodePacked("contract.address", _lendingContract))));
        shariaHubStorage.setAddress(keccak256(abi.encodePacked("arbiter", _lendingContract)), _arbiter);
        emit ArbiterAssigned(_arbiter, _lendingContract);
    }

    function revokeArbiterForLendingContract(address _arbiter, address _lendingContract) public onlyOwner {
        require(_arbiter != address(0), "Aribter address is not valid");
        require(_lendingContract != address(0), "Lending contract address is not valid");
        require(_lendingContract == shariaHubStorage.getAddress(keccak256(abi.encodePacked("contract.address", _lendingContract))));
        require(arbiterForLendingContract(_lendingContract) == _arbiter);
        shariaHubStorage.deleteAddress(keccak256(abi.encodePacked("arbiter", _lendingContract)));
        emit ArbiterRevoked(_arbiter, _lendingContract);
    }

    function arbiterForLendingContract(address _lendingContract) public view returns(address) {
        return shariaHubStorage.getAddress(keccak256(abi.encodePacked("arbiter", _lendingContract)));
    }
}