//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ISerumNFT.sol";
import "./ICollabVoiceNFT.sol";
import "./ICollabFactory.sol";


contract TALKENS_Coordinator is Ownable {

  uint256 public maxSerumsPerId = 5;
  address public voiceAddress;
  address public serumAddress;
  address public factoryAddress;


  constructor(address _voiceAddress,
              address _serumAddress,
              address _factoryAddress
  ) {
    voiceAddress = _voiceAddress;
    serumAddress = _serumAddress;
    factoryAddress = _factoryAddress;
  }

  function mintSerum(uint256 _voiceNftId, uint256 _amount) external {
    require(ICollabVoiceNFT(voiceAddress).ownerOf(_voiceNftId) == _msgSender(), "NFT not owned");
    require(_amount + ISerumNFT(serumAddress).getSerumsMintedById(_voiceNftId) <= maxSerumsPerId, "Exceed max serums for NFT");

    ISerumNFT(serumAddress).mint(_msgSender(), _amount, _voiceNftId);
  }
  
  function ownerMintSerum(address _recepient, uint256 _amount) external onlyOwner {
    ISerumNFT(serumAddress).mint(_recepient, _amount, 1);
  }

  function createCollabVoiceNFT(address _collection, uint256 _collectionNftId, uint256 _serumNftId) external {
    require(ICollabFactory(factoryAddress).isCollectionSupported(_collection), "Collection unsupported");
    require(ICollabVoiceNFT(_collection).ownerOf(_collectionNftId) == _msgSender(), "NFT not owned");

    ISerumNFT(serumAddress).burn(_msgSender(), _serumNftId);

    ICollabVoiceNFT(ICollabFactory(factoryAddress).getCollabAddress(_collection)).create(_msgSender(), _collectionNftId);
  }


  // Owner setters

  // creates a new Smart Contract
  function addSupportForCollection(address _collectionAddress, string memory collabBaseURI) external onlyOwner {
    require(!ICollabFactory(factoryAddress).isCollectionSupported(_collectionAddress), "Collection exists");
    ICollabFactory(factoryAddress).generateCollabCollection(owner(), _collectionAddress, collabBaseURI);
  }

  function removeSupportForCollection(address _collectionAddress) external onlyOwner{
    ICollabFactory(factoryAddress).deprecateCollabCollection(_collectionAddress);
  }

  function setMaxSerumsPerId(uint256 _newMaxSerumsPerId) external onlyOwner {
      maxSerumsPerId = _newMaxSerumsPerId;
  }

  function setSerumAddress(address _serumAddress) external onlyOwner {
    serumAddress = _serumAddress;
  }

  function setFactoryAddress(address _factoryAddress) external onlyOwner {
    factoryAddress = _factoryAddress;
  }

  function setVoiceAddress(address _voiceAddress) external onlyOwner {
    voiceAddress = _voiceAddress;
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface ISerumNFT {
  function mint(address _recepient, uint256 _amount, uint256 _voiceId) external;
  function burn(address _recepient, uint256 _serumId) external;
  function getSerumsMintedById(uint256 _nftId) external view returns(uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface ICollabVoiceNFT {
  function create(address _recepient, uint256 _collectionNftId) external;
  function initialize(address _owner, address _supportedCollection, address _coordinator, string memory _newBaseURI) external;
  function ownerOf(uint256 tokenId) external view returns (address owner);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface ICollabFactory {
  function generateCollabCollection(address owner, address supportedCollection, string memory baseURI) external;
  function deprecateCollabCollection(address _supportedCollection) external;
  function isCollectionSupported(address _collectionAddress) external view returns(bool);
  function getCollabAddress(address _collectionAddress) external view returns(address);
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