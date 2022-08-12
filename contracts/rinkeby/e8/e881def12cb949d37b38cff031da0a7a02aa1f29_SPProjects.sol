/**
 *Submitted for verification at Etherscan.io on 2022-08-12
*/

// File: contracts/structs/SPProjectMetadata.sol


pragma solidity 0.8.6;

struct SPProjectMetadata {
  uint256 totalPrice;
  uint256 tokenPrice;
  string propertyAddress;
  string ipfsDomain;
}

interface ISPProjects {
  event Create(
    uint256 indexed projectId,
    address indexed owner,
    SPProjectMetadata metadata,
    address caller
  );

  event SetMetadata(uint256 indexed projectId, SPProjectMetadata metadata, address caller);

  function count() external view returns (uint256);

  function getMetadataOf(uint256 _projectId) external view returns (SPProjectMetadata memory meta);

  function createFor(address _owner, SPProjectMetadata calldata _metadata)
    external
    returns (uint256 projectId);

  function setMetadataOf(uint256 _projectId, SPProjectMetadata calldata _metadata) external;
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


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// File: contracts/SPProjects.sol


pragma solidity 0.8.6;




contract SPProjects is ISPProjects, Ownable {
  //*********************************************************************//
  // --------------------- public stored properties -------------------- //
  //*********************************************************************//

  /** 
    @notice 
    The number of projects that have been created using this contract.

    @dev
    The count is incremented with each new project created. 
    The resulting ERC-721 token ID for each project is the newly incremented count value.
  */
  uint256 public override count = 0;

  /** 
    @notice 
  */
  mapping(uint256 => SPProjectMetadata) public metadataContentOf;

  constructor()
  // solhint-disable-next-line no-empty-blocks
  {
    
  }

  /**
    @notice 
    Create a new project for the specified owner

    @dev 
    Anyone can create a project on an owner's behalf.

    @param _owner The address that will be the owner of the project.
    @param _metadata A struct containing metadata content about the project, and domain within which the metadata applies.

    @return projectId The token ID of the newly created project.
  */
  function createFor(address _owner, SPProjectMetadata calldata _metadata)
    external
    override
    returns (uint256 projectId)
  {
    // Increment the count, which will be used as the ID.
    projectId = ++count;
    // Set the metadata if one was provided.
    if (bytes(_metadata.ipfsDomain).length > 0)
      metadataContentOf[projectId] = _metadata;

    emit Create(projectId, _owner, _metadata, msg.sender);
  }

  /**
    @notice 
    Allows a project owner to set the project's metadata content for a particular domain namespace. 

    @dev 
    Only a project's owner or operator can set its metadata.

    @dev 
    Applications can use the domain namespace as they wish.

    @param _projectId The ID of the project who's metadata is being changed.
    @param _metadata A struct containing metadata content, and domain within which the metadata applies. 
  */
  function setMetadataOf(uint256 _projectId, SPProjectMetadata calldata _metadata)
    external
    override
  {
    // Set the project's new metadata content within the specified domain.
    metadataContentOf[_projectId] = _metadata;

    emit SetMetadata(_projectId, _metadata, msg.sender);
  }

  function getMetadataOf(uint256 _projectId) external override view returns (SPProjectMetadata memory meta) {
    meta = metadataContentOf[_projectId];
    return meta;
  }
}