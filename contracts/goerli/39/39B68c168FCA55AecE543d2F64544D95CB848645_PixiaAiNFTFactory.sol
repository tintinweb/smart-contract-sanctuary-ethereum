// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library ClonesUpgradeable {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
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
pragma solidity ^0.8.0;

interface IPixiaAiNFT {
    /// @notice Initialize the nft collection contract with given args
    function initialize() external;

    /// @notice Set Contract Owner;
    /// @param owner_ Collection Owner Address
    function updateOwner(address owner_) external;

    /// @notice Set the Mint Price
    /// @param price_ mint price from factory
    function setMintPrice(uint256 price_) external;

    /// @notice Set the Base URI
    /// @param baseURI_ baseURI from factory
    function setBaseURI(string memory baseURI_) external;

    /// @notice Update Royalty Info
    /// @param royaltyReceiver_ The Royalty Receiver Address from factory
    /// @param royaltyBasisPoints_ The Royalty Basis Points from factory
    function updateRoyaltyInfo(address royaltyReceiver_, uint16 royaltyBasisPoints_) external;
}

// SPDX-License-Identifier: MIT 
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";
import "./IPixiaAiNFT.sol";

contract PixiaAiNFTFactory is Ownable{

	enum Plan {
        FREE,
        PAID
    }

    address[] public collections;

	uint256 public PRICE = 0.001 ether;

	uint16 public royaltyBasisPoints = 300; //3%
	address public royaltyReceiver = 0xdDf3e4D035a75d3a5bB11F9CaD79fa555D3aa957;

	address public defaultAdmin = 0x79543b9490110668c32c7EC5a0dE1a8BCA661b17;
	address public nftImpl;
    
	/** Events */
    event CollectionCreated(address collection_address, uint256 collectionId, address owner);
	
	constructor (
        address defaultAdmin_,
        address nftImpl_
	) {
		defaultAdmin = defaultAdmin_;
		nftImpl = nftImpl_;
	}

	function setAdminAddr(address _defaultAdmin) external onlyOwner {
		defaultAdmin = _defaultAdmin;
	}

	function setNftImpl(address _nftImpl) external onlyOwner {
		nftImpl = _nftImpl;
	}

	/// @notice setPrice
	/// @param _price Collection Creation Price
	function setPrice(uint256 _price) external onlyOwner{
		PRICE = _price;
	}
	/////--------Collection------------////

	/// @notice Set Contract Owner;
    /// @param owner_ Collection Owner Address
    function updateOwner(address owner_) external onlyOwner {
		for ( uint64 i = 0 ; i < collections.length ; i++){
			IPixiaAiNFT(collections[i]).updateOwner(owner_);
		}
	}

	/// @notice setMintPrice
	///	@param _price NFT Collection Mint Price
	function setMintPrice( uint256 _price ) external onlyOwner{
		for ( uint64 i = 0 ; i < collections.length ; i++){
			IPixiaAiNFT(collections[i]).setMintPrice(_price);
		}
	}

	/// @notice setBaseURI
	///	@param _baseUri NFT Token Base URI
	function setBaseURI( string memory _baseUri ) external onlyOwner{
		for ( uint64 i = 0 ; i < collections.length ; i++){
			IPixiaAiNFT(collections[i]).setBaseURI(_baseUri);
		}
	}

	/// @notice setRoyaltyInfos
	///	@param _receiver royalty fee address
	/// @param _fee royalty fee percent 1% = 100;
	function setRoyaltyInfos(  address _receiver, uint16 _fee) external onlyOwner{
		royaltyBasisPoints = _fee;
		royaltyReceiver = _receiver;
		for ( uint64 i = 0 ; i < collections.length ; i++){
			IPixiaAiNFT(collections[i]).updateRoyaltyInfo(_receiver, _fee);
		}
	}

	/// @notice setRoyaltyInfos
	/// @param _collections collection addres list to change the infos
	///	@param _receiver royalty fee address
	/// @param _fee royalty fee percent 1% = 100;
	function setRoyaltyInfoForCollections( address[] memory _collections, address _receiver, uint16 _fee) public onlyOwner{
		for ( uint64 i = 0 ; i < _collections.length ; i++){
			IPixiaAiNFT(_collections[i]).updateRoyaltyInfo(_receiver, _fee);
		}
	}

	function createCollection(Plan _plan, uint256 collectionId) external payable returns(address collection)  {
		if (_plan == Plan.PAID) payable(defaultAdmin).transfer(PRICE);
		collection = ClonesUpgradeable.clone(nftImpl);
		IPixiaAiNFT(collection).initialize();
        IPixiaAiNFT(collection).updateOwner(msg.sender);
		IPixiaAiNFT(collection).updateRoyaltyInfo( royaltyReceiver, _plan == Plan.PAID ? royaltyBasisPoints : 0);
		collections.push(collection);
		emit CollectionCreated(collection, collectionId, msg.sender);
	}
}