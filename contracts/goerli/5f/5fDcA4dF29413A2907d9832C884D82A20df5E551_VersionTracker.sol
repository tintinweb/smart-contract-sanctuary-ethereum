// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";

contract VersionTracker is Ownable {

    struct Version {
        uint16 major;
        uint16 minor;
        address coreLocation;
        address registrarLocation;
        address resolverLocation;
    }

    enum ContractType { CORE, REGISTRAR, RESOLVER }

    Version[] coreVersions;

    function updateMajor(address coreContract, address registrarContract, address resolverContract) external onlyOwner returns(Version memory){
        require(coreContract != address(0));
        require(registrarContract != address(0));
        require(resolverContract != address(0));
        Version memory nextMajor;
        if (coreVersions.length == 0){
            nextMajor = Version(0, 0, coreContract, registrarContract, resolverContract);
        } else {
            Version memory currentVersion = getCurrentVersion();
            nextMajor = Version(currentVersion.major + 1, 0, coreContract, registrarContract, resolverContract);
        }
        return storeVersion(nextMajor);
    }

    function updateMinor(address coreContract, address registrarContract, address resolverContract) external onlyOwner returns(Version memory) {
        require(coreContract != address(0));
        require(registrarContract != address(0));
        require(resolverContract != address(0));
        Version memory nextMinor;
        if (coreVersions.length == 0){
            nextMinor = Version(0, 0, coreContract, registrarContract, resolverContract);
        } else {
            Version memory currentVersion = getCurrentVersion();
            nextMinor = Version(currentVersion.major, currentVersion.minor+1, coreContract, registrarContract, resolverContract);
        }
        return storeVersion(nextMinor);
    }

    function getPhotochromicCore() external view returns (address){
        if (coreVersions.length == 0) revert();
        return getCurrentVersion().coreLocation;
    }

    function getPhotochromicCore(uint major) external view returns (address){
        (Version memory version, ) = findVersion(major);
        return version.coreLocation;
    }

    function getPhotochromicCore(uint major, uint minor) external view returns (address){
        (Version memory version, ) = findVersion(major, minor);
        return version.coreLocation;
    }

    function getVersionMajor() external view returns (uint) {
        return getCurrentVersion().major;
    }

    function getVersionMinor() external view returns (uint) {
        return getCurrentVersion().minor;
    }

    function getCurrentVersion() public view returns (Version memory){
        require(coreVersions.length > 0, "No version set");
        return coreVersions[coreVersions.length-1];
    }

    function getVersion(uint major) external view returns (Version memory version){
        (version, ) = findVersion(major);
        return version;
    }

    function getVersion(uint major, uint minor) external view returns(Version memory version){
        (version, ) = findVersion(major, minor);
        return version;
    }

    function getVersionForAddress(address contractAddress, ContractType contractType) external view returns (Version memory){
        Version memory v;
        for (uint i = coreVersions.length; i > 0; i--){
            v = coreVersions[i];
            if (contractType == ContractType.CORE && v.coreLocation == contractAddress) return v;
            if (contractType == ContractType.REGISTRAR && v.registrarLocation == contractAddress) return v;
            if (contractType == ContractType.RESOLVER && v.resolverLocation == contractAddress) return v;
        }
        revert();
    }

    function findVersion(uint major) internal view returns (Version memory, uint) {
        for (uint i = coreVersions.length; i > 0; i--) {
            Version memory version = coreVersions[i - 1];
            if (version.major == major) return (version, i - 1);
        }
        revert();
    }

    function findVersion(uint major, uint minor) internal view returns (Version memory, uint){
        for (uint i = coreVersions.length; i > 0; i--) {
            Version memory version = coreVersions[i - 1];
            if ((version.major == major) && (version.minor == minor)) return (version, i - 1);
        }
        revert();
    }

    function storeVersion(Version memory version) internal returns(Version memory) {
        coreVersions.push(version);
        return getCurrentVersion();
    }
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