// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IDogeWorld.sol";
import "./interfaces/ITOPIA.sol";
import "./interfaces/IHub.sol";

contract DogeWorldEarnings is Ownable, ReentrancyGuard {

	ITOPIA public TOPIAToken;
    IHub public HUB;
    IDogeWorld public DogeWorld;

	uint256 public dogAdjuster = 2500;
	uint256 public veterinarianAdjuster = 833;

	struct Earnings {
		uint256 unadjustedClaimed;
		uint256 adjustedClaimed;
	}
	mapping(uint16 => Earnings) public dog;
	mapping(uint16 => Earnings) public veterinarian;
	mapping(uint16 => uint8) public genesisType;

	uint256 public totalTOPIAEarned;

	event DogClaimed(uint256 indexed tokenId, uint256 earned);
	event VeterinarianClaimed(uint256 indexed tokenId, uint256 earned);

	constructor(address _topia, address _hub, address _dogeworld) {
    	TOPIAToken = ITOPIA(_topia);
    	HUB = IHub(_hub);
    	DogeWorld = IDogeWorld(_dogeworld);
    }

    function updateContracts(address _topia, address _hub, address _dogeworld) external onlyOwner {
    	TOPIAToken = ITOPIA(_topia);
    	HUB = IHub(_hub);
    	DogeWorld = IDogeWorld(_dogeworld);
    }

    function updateAdjusters(uint256 _dog, uint256 _veterinarian) external onlyOwner {
    	dogAdjuster = _dog;
    	veterinarianAdjuster = _veterinarian;
    }

    // mass update the nftType mapping
    function setBatchNFTType(uint16[] calldata tokenIds, uint8[] calldata _types) external onlyOwner {
        require(tokenIds.length == _types.length , " _idNumbers.length != _types.length: Each token ID must have exactly 1 corresponding type!");
        for (uint16 i = 0; i < tokenIds.length; i++) {
            require(_types[i] == 2 || _types[i] == 3, "Invalid nft type - must be 2 or 3");
            genesisType[tokenIds[i]] = _types[i];
        }
    }

	function claimMany(uint16[] calldata tokenIds) external nonReentrant {
		require(tx.origin == msg.sender, "Only EOA");
		uint256 owed = 0;
		for(uint i = 0; i < tokenIds.length; i++) {
			if (genesisType[tokenIds[i]] == 2) {
				owed += claimDogEarnings(tokenIds[i]);
			} else if (genesisType[tokenIds[i]] == 3) {
				owed += claimVeterinarianEarnings(tokenIds[i]);
			} else if (genesisType[tokenIds[i]] == 0) {
				revert('invalid token id');
			}
		}
		totalTOPIAEarned += owed;
	    TOPIAToken.mint(msg.sender, owed);
	    HUB.emitTopiaClaimed(msg.sender, owed);
	}

	function claimDogEarnings(uint16 _tokenId) internal returns (uint256) {
		uint256 unclaimed = DogeWorld.getUnclaimedGenesis(_tokenId);
		if(unclaimed <= dog[_tokenId].unadjustedClaimed) { return 0; }
		uint256 adjustedEarnings = unclaimed * dogAdjuster / 100;
		uint256 owed = adjustedEarnings - dog[_tokenId].unadjustedClaimed;	
		dog[_tokenId].unadjustedClaimed += unclaimed;
		dog[_tokenId].adjustedClaimed += adjustedEarnings;
		emit DogClaimed(_tokenId, owed);
		return owed;
	}

	function claimVeterinarianEarnings(uint16 _tokenId) internal returns (uint256) {
		uint256 unclaimed = DogeWorld.getUnclaimedGenesis(_tokenId);
		if(unclaimed <= veterinarian[_tokenId].unadjustedClaimed) { return 0; }
		uint256 adjustedEarnings = unclaimed * veterinarianAdjuster / 100;
		uint256 owed = adjustedEarnings - veterinarian[_tokenId].unadjustedClaimed;	
		veterinarian[_tokenId].unadjustedClaimed += unclaimed;
		veterinarian[_tokenId].adjustedClaimed += adjustedEarnings;
		emit VeterinarianClaimed(_tokenId, owed);
		return owed;
	}

	function getUnclaimedGenesis(uint16 _tokenId) external view returns (uint256) {
		uint256 unclaimed = DogeWorld.getUnclaimedGenesis(_tokenId);
		if(genesisType[_tokenId] == 2) {
			if(unclaimed <= dog[_tokenId].unadjustedClaimed) { return 0; }
			uint256 adjustedEarnings = unclaimed * dogAdjuster / 100;
			uint256 owed = adjustedEarnings - dog[_tokenId].unadjustedClaimed;	
			return owed;
		} else if(genesisType[_tokenId] == 3) {
			if(unclaimed <= veterinarian[_tokenId].unadjustedClaimed) { return 0; }
			uint256 adjustedEarnings = unclaimed * veterinarianAdjuster / 100;
			uint256 owed = adjustedEarnings - veterinarian[_tokenId].unadjustedClaimed;	
			return owed;
		} else {
			return 0;
		}
	}
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface IHub {
    function emitGenesisStaked(address owner, uint16[] calldata tokenIds, uint8 gameId) external;
    function emitAlphaStaked(address owner, uint16[] calldata tokenIds, uint8 gameId) external;
    function emitGenesisUnstaked(address owner, uint16[] calldata tokenIds) external;
    function emitAlphaUnstaked(address owner, uint16[] calldata tokenIds) external;
    function emitTopiaClaimed(address owner, uint256 amount) external;
    function balanceOf(address owner) external view returns (uint256);
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface ITOPIA {
    function mint(address to, uint256 amount) external;
    function burn(uint256 amount) external;
    function burnFrom(address from, uint256 amount) external;
    function updateOriginAccess() external;
    function transferFrom(address sender, address recipient, uint256 amount) external returns(bool);
}

// SPDX-License-Identifier: MIT LICENSE 

pragma solidity ^0.8.0;

interface IDogeWorld {
  function addManyToStakingPool(address account, uint16[] calldata tokenIds) external;
  function isOwner(uint16 tokenId, address owner) external view returns (bool);
  function getUnclaimedGenesis(uint16 tokenId) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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