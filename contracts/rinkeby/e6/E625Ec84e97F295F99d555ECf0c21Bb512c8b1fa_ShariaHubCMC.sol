/**
 *Submitted for verification at Etherscan.io on 2022-04-09
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
//    modifier onlyShariaHubContracts() {_;}

    // Setters
    function setAddress(bytes32 _key, address _value) external;
    function setUint(bytes32 _key, uint _value) external;
    function setString(bytes32 _key, string memory _value) external;
    function setBytes(bytes32 _key, bytes memory _value) external;
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
    function getString(bytes32 _key) external view returns (string memory );
    function getBytes(bytes32 _key) external view returns (bytes memory );
    function getBool(bytes32 _key) external view returns (bool);
    function getInt(bytes32 _key) external view returns (int);
}

// File: ShariaHubBase.sol


pragma solidity ^0.8.9;



contract ShariaHubBase {

    uint8 public version;

    ShariaHubStorageInterface public ShariaHubStorage;

    constructor(address _storageAddress) {
        require(_storageAddress != address(0));
        ShariaHubStorage = ShariaHubStorageInterface(_storageAddress);
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

// File: ShariaHubCMC.sol



pragma solidity ^0.8.9;



/**
 * @title ShariahubCMC
 * @dev This contract manage Shariahub contracts creation and update.
 */

contract ShariaHubCMC is ShariaHubBase, Ownable {

    event ContractUpgraded (
        address indexed _oldContractAddress,                    // Address of the contract being upgraded
        address indexed _newContractAddress,                    // Address of the new contract
        uint256 created                                         // Creation timestamp
    );

    modifier onlyOwnerOrLocalNode() {
        bool isLocalNode = ShariaHubStorage.getBool(keccak256(abi.encodePacked("user", "localNode", msg.sender)));
        require(isLocalNode || owner() == msg.sender);
        _;
    }

    constructor(address _storageAddress) ShariaHubBase(_storageAddress) {
        // Version
        version = 1;
    }

    function addNewLendingContract(address _lendingAddress) public onlyOwnerOrLocalNode {
        require(_lendingAddress != address(0));
        ShariaHubStorage.setAddress(keccak256(abi.encodePacked("contract.address", _lendingAddress)), _lendingAddress);
    }

    function upgradeContract(address _newContractAddress, string memory _contractName) public onlyOwner {
        require(_newContractAddress != address(0));
        require(keccak256(abi.encodePacked("contract.name","")) != keccak256(abi.encodePacked("contract.name",_contractName)));
        address oldAddress = ShariaHubStorage.getAddress(keccak256(abi.encodePacked("contract.name", _contractName)));
        ShariaHubStorage.setAddress(keccak256(abi.encodePacked("contract.address", _newContractAddress)), _newContractAddress);
        ShariaHubStorage.setAddress(keccak256(abi.encodePacked("contract.name", _contractName)), _newContractAddress);
        ShariaHubStorage.deleteAddress(keccak256(abi.encodePacked("contract.address", oldAddress)));
        emit ContractUpgraded(oldAddress, _newContractAddress, block.timestamp);
    }
}