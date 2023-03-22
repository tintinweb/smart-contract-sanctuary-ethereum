// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ILayerrToken.sol";

contract LayerrFactory is Ownable {
  struct ContractImplementation {
    address implementationAddress;
    bool active;
  }

  error InactiveImplementation();

  address public LayerrXYZ;

  mapping(address => address[]) public allClones;
  mapping(string => address) public projectIdToAddress;
  mapping(uint256 => ContractImplementation) public contractImplementations;

  /**
    * @dev Sets the `implementation` address for the `implementationId`.
    * @param implementationId The id of the implementation to be set.
    * @param _implementation The address of the implementation.
    * @param active Whether the implementation is active or not.
    */
  function setImplementation(uint256 implementationId, address _implementation, bool active) external onlyOwner {
    ContractImplementation storage contractImplementation = contractImplementations[implementationId];
    contractImplementation.implementationAddress = _implementation;
    contractImplementation.active = active;
  }

  /**
    * @dev Sets the `LayerrVariables` address to be passed to clones to read fees and addresses.
    */
  function setLayerrXYZ(address _LayerrXYZ) external onlyOwner {
    LayerrXYZ = _LayerrXYZ;
  }
  
  /**
    * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
    *
    * This function uses the create opcode, which should never revert.
    */
  function clone(address _implementation) internal returns (address instance) {
    assembly {
      let ptr := mload(0x40)
      mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
      mstore(add(ptr, 0x14), shl(0x60, _implementation))
      mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
      instance := create(0, ptr, 0x37)
    }
    require(instance != address(0), "ERC1167: create failed");
  }

  /**
    * @dev Deploys a clone of the implementation with the given `implementationId`.
    * @param implementationId The id of the implementation to be deployed.
    * @param data The data to be passed to the clone's `initialize` function.
    * @param projectId The id of the project to be deployed.
    */
  function deployContract(string calldata projectId, uint256 implementationId, bytes calldata data) external {
    ContractImplementation storage contractImplementation = contractImplementations[implementationId];
    if(!contractImplementation.active) { revert InactiveImplementation(); }

    address identicalChild = clone(contractImplementation.implementationAddress);
    allClones[msg.sender].push(identicalChild);
    projectIdToAddress[projectId] = identicalChild;
    ILayerrToken(identicalChild).initialize(data, LayerrXYZ);
  }

  function returnClones(address _owner) external view returns (address[] memory){
      return allClones[_owner];
  }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

interface ILayerrToken {
  /**
  * @dev initializes the proxy contract
  * @param data: the data to be passed to the proxy contract is abi encoded
  * @param _LayerrXYZ: the address of the LayerrVariables contract
  */
  function initialize(
    bytes calldata data,
    address _LayerrXYZ
  ) external;
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