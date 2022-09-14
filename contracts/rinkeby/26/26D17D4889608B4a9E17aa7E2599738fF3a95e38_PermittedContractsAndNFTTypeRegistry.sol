// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IPermittedContracts.sol";
import "./interfaces/INFTTypeRegistry.sol";

/**
 * @title  PermittedNFTsAndTypeRegistry
 * @dev Registry for NFT contracts supported by DStage.
 * Each NFT is associated with an NFT Type.
 */
contract PermittedContractsAndNFTTypeRegistry is Ownable, IPermittedContracts {
  /**
    * @notice A mapping from an Token type of the contract to the Wrapper contract address of that type.
    */
  mapping(bytes32 => address) private _nftTypes;

  /**
    * @notice A mapping from an NFT contract's address to the Token type of that contract. A zero Token Type indicates
    * non-permitted.
    */
  mapping(address => bytes32) private _nftPermits;

  /**
    * @notice A mapping from an ERC20 currency address to whether that currency
    * is permitted to be used by this contract.
   */
  mapping(address => bool) private _erc20Permits;

  /* ****** */
  /* EVENTS */
  /* ****** */

  /**
    * @notice This event is fired whenever the admins register a ntf type.
    *
    * @param nftType - Nft type represented by keccak256('nft type').
    * @param nftWrapper - Address of the wrapper contract.
    */
  event TypeUpdated(bytes32 indexed nftType, address indexed nftWrapper);

  /**
    * @notice This event is fired whenever the admin sets a NFT's permit.
    *
    * @param nftContract - Address of the NFT contract.
    * @param nftType - NTF type e.g. bytes32("ERC721")
    */
  event NFTPermit(address indexed nftContract, bytes32 indexed nftType);

  /**
    * @notice This event is fired whenever the admin sets a ERC20 permit.
    *
    * @param erc20Contract - Address of the ERC20 contract.
    * @param isPermitted - Signals ERC20 permit.
    */
  event ERC20Permit(address indexed erc20Contract, bool isPermitted);

  /* *********** */
  /* CONSTRUCTOR */
  /* *********** */

  /**
    * @dev Sets `NFTTypeRegistry`
    * Initialize `nftPermits` with a batch of permitted NFTs
    *s
    * @param _definedNFTTypes - All the ossible NFT types
    * @param _definedNFTWrappers - All the possible wrappers for the types
    * @param _permittedNFTContracts - The addresses of the NFT contracts.
    * @param _permittedNFTTypes - The NFT Types. e.g. "ERC721"
    * - "" means "disable this permit"
    * - != "" means "enable permit with the given NFT Type"
    *@param _permittedERC20s - The addresses of ERC20 contracts.
    */
  constructor(
    string[] memory _definedNFTTypes,
    address[] memory _definedNFTWrappers,
    address[] memory _permittedNFTContracts,
    string[] memory _permittedNFTTypes,
    address[] memory _permittedERC20s
  ) {
    _setNFTTypes(_definedNFTTypes, _definedNFTWrappers);
    _setNFTPermits(_permittedNFTContracts, _permittedNFTTypes);
    for(uint256 i=0; i < _permittedERC20s.length; i++) {
      _setERC20Permit(_permittedERC20s[i], true);
    }
  }

  /* ********* */
  /* FUNCTIONS */
  /* ********* */

  /**
    * @notice This function can be called by admins to change the permitted list status of an NFT contract. This
    * includes both adding an NFT contract to the permitted list and removing it.
    * `nftContract` can not be zero address.
    *
    * @param nftContract - The address of the NFT contract.
    * @param nftType - The NFT Type. e.g. "ERC721"
    * - "" means "disable this permit"
    * - != "" means "enable permit with the given NFT Type"
    */
  function setNFTPermit(address nftContract, string memory nftType)
    external
    override
    onlyOwner
  {
    _setNFTPermit(nftContract, nftType);
  }

  /**
    * @notice This function can be called by admins to change the permitted list status of a batch NFT contracts. This
    * includes both adding an NFT contract to the permitted list and removing it.
    * `nftContract` can not be zero address.
    *
    * @param nftContracts - The addresses of the NFT contracts.
    * @param nftTypes - The NFT Types. e.g. "ERC721"
    * - "" means "disable this permit"
    * - != "" means "enable permit with the given NFT Type"
    */
  function setNFTPermits(address[] memory nftContracts, string[] memory nftTypes) external onlyOwner {
    _setNFTPermits(nftContracts, nftTypes);
  }

  /**
    * @notice This function can be called by anyone to lookup the NFT Type associated with the contract.
    * @param  nftContract - The address of the NFT contract.
    * @notice Returns the NFT Type:
    * - bytes32("") means "not permitted"
    * - != bytes32("") means "permitted with the given NFT Type"
    */
  function getNFTPermit(address nftContract) external view override returns (bytes32) {
    return _nftPermits[nftContract];
  }

  /**
    * @notice This function can be called by anyone to lookup the address of the NFTWrapper associated to the
    * `nftContract` type.
    * @param nftContract - The address of the NFT contract.
    */
  function getNFTWrapper(address nftContract) external view override returns (address) {
    bytes32 nftType = _nftPermits[nftContract];
    return getNFTTypeWrapper(nftType);
  }

  /**
    * @notice Set or update the wrapper contract address for the given NFT Type.
    * Set address(0) for a nft type for un-register such type.
    *
    * @param nftType - The NFT type, e.g. "ERC721", or "ERC1155".
    * @param nftWrapper - The address of the wrapper contract that implements INFTWrapper behaviour for dealing with
    * NFTs.
    */
  function setNFTType(string memory nftType, address nftWrapper) external onlyOwner {
    _setNFTType(nftType, nftWrapper);
  }

  /**
    * @notice Batch set or update the wrappers contract address for the given batch of NFT Types.
    * Set address(0) for a NFT type for un-register such type.
    *
    * @param nftTypes - The NFT types, e.g. "ERC721", or "ERC1155".
    * @param nftWrappers - The addresses of the wrapper contract that implements INFTWrapper behaviour for dealing
    * with NFTs.
    */
  function setNFTTypes(string[] memory nftTypes, address[] memory nftWrappers) external onlyOwner {
    _setNFTTypes(nftTypes, nftWrappers);
  }

  /**
    * @notice This function can be called by anyone to get the contract address that implements the given NFT type.
    *
    * @param  nftType - The NFT type, e.g. bytes32("ERC721"), or bytes32("ERC1155").
    */
  function getNFTTypeWrapper(bytes32 nftType) public view returns (address) {
    return _nftTypes[nftType];
  }

  /**
    * @notice Set or update the wrapper contract address for the given NFT Type.
    * Set address(0) for a NFT type for un-register such type.
    *
    * @param nftType - The NFT type, e.g. "ERC721", or "ERC1155".
    * @param nftWrapper - The address of the wrapper contract that implements INFTWrapper behaviour for dealing with
    * NFTs.
    */
  function _setNFTType(string memory nftType, address nftWrapper) internal {
    require(bytes(nftType).length != 0, "nftType is empty");
    bytes32 nftTypeKey = _getTypeFromString(nftType);

    _nftTypes[nftTypeKey] = nftWrapper;

    emit TypeUpdated(nftTypeKey, nftWrapper);
  }

  /**
    * @notice Batch set or update the wrappers contract address for the given batch of NFT Types.
    * Set address(0) for a nft type for un-register such type.
    *
    * @param nftTypes - The NFT types, e.g. keccak256("ERC721"), or keccak256("ERC1155").
    * @param nftWrappers - The addresses of the wrapper contract that implements INFTWrapper behaviour for dealing
    * with NFTs.
    */
  function _setNFTTypes(string[] memory nftTypes, address[] memory nftWrappers) internal {
    require(nftTypes.length == nftWrappers.length, "setNFTTypes function information arity mismatch");

    for (uint256 i = 0; i < nftWrappers.length; i++) {
        _setNFTType(nftTypes[i], nftWrappers[i]);
    }
  }

  /**
    * @notice This function changes the permitted list status of an NFT contract. This includes both adding an NFT
    * contract to the permitted list and removing it.
    * @param nftContract - The address of the NFT contract.
    * @param nftType - The NFT Type. e.g. bytes32("ERC721")
    * - bytes32("") means "disable this permit"
    * - != bytes32("") means "enable permit with the given NFT Type"
    */
  function _setNFTPermit(address nftContract, string memory nftType) internal {
    require(nftContract != address(0), "nftContract is zero address");
    bytes32 nftTypeKey = _getTypeFromString(nftType);

    if (nftTypeKey != 0) {
        require(getNFTTypeWrapper(nftTypeKey) != address(0), "NFT type not registered");
    }

    _nftPermits[nftContract] = nftTypeKey;
    emit NFTPermit(nftContract, nftTypeKey);
  }

  /**
    * @notice This function changes the permitted list status of a batch NFT contracts. This includes both adding an
    * NFT contract to the permitted list and removing it.
    * @param nftContracts - The addresses of the NFT contracts.
    * @param nftTypes - The NFT Types. e.g. "ERC721"
    * - "" means "disable this permit"
    * - != "" means "enable permit with the given NFT Type"
    */
  function _setNFTPermits(address[] memory nftContracts, string[] memory nftTypes) internal {
    require(nftContracts.length == nftTypes.length, "setNFTPermits function information arity mismatch");

    for (uint256 i = 0; i < nftContracts.length; i++) {
        _setNFTPermit(nftContracts[i], nftTypes[i]);
    }
  }

  /**
    * @notice This function can be called by admins to change the permitted status of an ERC20 currency. This includes
    * both adding an ERC20 currency to the permitted list and removing it.
    *
    * @param erc20Contract - The address of the ERC20 currency whose permit list status changed.
    * @param permit - The new status of whether the currency is permitted or not.
    */
  function setERC20Permit(address erc20Contract, bool permit) external override onlyOwner {
      _setERC20Permit(erc20Contract, permit);
  }

  /**
    * @notice This function can be called by admins to change the permitted status of a batch of ERC20 currency. This
    * includes both adding an ERC20 currency to the permitted list and removing it.
    *
    * @param erc20Contract - The addresses of the ERC20 currencies whose permit list status changed.
    * @param permits - The new statuses of whether the currency is permitted or not.
    */
  function setERC20Permits(address[] memory erc20Contract, bool[] memory permits) external onlyOwner {
      require(erc20Contract.length == permits.length, "setERC20Permits function information arity mismatch");

      for (uint256 i = 0; i < erc20Contract.length; i++) {
          _setERC20Permit(erc20Contract[i], permits[i]);
      }
  }

  /**
    * @notice This function can be called by anyone to get the permit associated with the erc20 contract.
    *
    * @param erc20Contract - The address of the erc20 contract.
    *
    * @return Returns whether the erc20 is permitted
    */
  function getERC20Permit(address erc20Contract) public view override returns (bool) {
      return _erc20Permits[erc20Contract];
  }

  /**
    * @notice This function can be called by admins to change the permitted status of an ERC20 currency. This includes
    * both adding an ERC20 currency to the permitted list and removing it.
    *
    * @param erc20Contract - The address of the ERC20 currency whose permit list status changed.
    * @param permit - The new status of whether the currency is permitted or not.
    */
  function _setERC20Permit(address erc20Contract, bool permit) internal {
    require(erc20Contract != address(0), "erc20 is zero address");

    _erc20Permits[erc20Contract] = permit;

    emit ERC20Permit(erc20Contract, permit);
  }

  /**
   *@notice Returns the bytes32 representation of a string
   *
   *@param nftType - the string key
   *@return nftTypeBytes - bytes32 representation
   */
  function _getTypeFromString(string memory nftType) internal pure returns (bytes32 nftTypeBytes) {
    require(bytes(nftType).length <= 32, "Invalid NFT Type");

    // solhint-disable-next-line no-inline-assembly
    assembly {
        nftTypeBytes := mload(add(nftType, 32))
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

/**
 *@title Whitelisted NFT/ERC20 contracts
 *@dev Interface for whitelisted NFT/ERC20 contracts
 */
interface IPermittedContracts {
  function setNFTPermit(address nftContract, string memory nftType) external;
  function getNFTPermit(address nftContract) external view returns (bytes32);
  function getNFTWrapper(address nftContract) external view returns (address);

  function setERC20Permit(address erc20, bool permit) external;
  function getERC20Permit(address erc20) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

/**
 * @title INFTTypeRegistry
 * @dev Interface for NFT Types Registry supported by DStage.
 */
interface INFTTypeRegistry {
    function setNFTType(bytes32 nftType, address nftWrapper) external;

    function getNFTTypeWrapper(bytes32 nftType) external view returns (address);
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