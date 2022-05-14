// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {IERC165, IERC2981} from '@openzeppelin/contracts/interfaces/IERC2981.sol';
import {IFeeManager, FeeParty} from '../interfaces/IFeeManager.sol';
import {IOwnable} from '../interfaces/IOwnable.sol';
import {IRoyaltyEngine} from '../interfaces/IRoyaltyEngine.sol';
import {IFeeRegistry} from '../interfaces/IFeeRegistry.sol';

// import 'hardhat/console.sol';

/**
 * @title InfinityCreatorsFeeManager
 * @notice handles creator fees aka royalties
 */
contract InfinityCreatorsFeeManager is IFeeManager, Ownable {
  FeeParty public PARTY_NAME = FeeParty.CREATORS;
  IRoyaltyEngine public royaltyEngine;
  uint16 public MAX_CREATOR_FEE_BPS = 1000;
  address public immutable CREATORS_FEE_REGISTRY;

  event NewRoyaltyEngine(address newEngine);
  event NewMaxBPS(uint16 newBps);

  /**
   * @notice Constructor
   */
  constructor(address _royaltyEngine, address _creatorsFeeRegistry) {
    royaltyEngine = IRoyaltyEngine(_royaltyEngine);
    CREATORS_FEE_REGISTRY = _creatorsFeeRegistry;
  }

  /**
   * @notice Calculate creator fees and get recipients
   * @param collection address of the NFT contract
   * @param tokenId tokenId
   * @param amount sale amount
   */
  function calcFeesAndGetRecipients(
    address,
    address collection,
    uint256 tokenId,
    uint256 amount
  )
    external
    view
    override
    returns (
      FeeParty,
      address[] memory,
      uint256[] memory
    )
  {
    // check if the creators fee is registered
    (, address[] memory recipients, , uint256[] memory amounts) = _getCreatorsFeeInfo(collection, tokenId, amount);
    return (PARTY_NAME, recipients, amounts);
  }

  /**
   * @notice supports creator fee (royalty) sharing for a collection via self service of
   * owner/admin of collection or by owner of this contract
   * @param collection collection address
   * @param feeDestinations fee destinations
   * @param bpsSplits bpsSplits between destinations
   */
  function setupCollectionForCreatorFeeShare(
    address collection,
    address[] calldata feeDestinations,
    uint16[] calldata bpsSplits
  ) external {
    bytes4 INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 INTERFACE_ID_ERC1155 = 0xd9b67a26;
    require(
      (IERC165(collection).supportsInterface(INTERFACE_ID_ERC721) ||
        IERC165(collection).supportsInterface(INTERFACE_ID_ERC1155)),
      'Collection is not ERC721/ERC1155'
    );

    // see if collection has admin
    address collAdmin;
    try IOwnable(collection).owner() returns (address _owner) {
      collAdmin = _owner;
    } catch {
      try IOwnable(collection).admin() returns (address _admin) {
        collAdmin = _admin;
      } catch {
        collAdmin = address(0);
      }
    }

    require(msg.sender == owner() || msg.sender == collAdmin, 'unauthorized');
    // check total bps
    uint32 totalBps = 0;
    for (uint256 i = 0; i < bpsSplits.length; ) {
      totalBps += bpsSplits[i];
      unchecked {
        ++i;
      }
    }
    require(totalBps <= MAX_CREATOR_FEE_BPS, 'bps too high');

    // setup
    IFeeRegistry(CREATORS_FEE_REGISTRY).registerFeeDestinations(collection, msg.sender, feeDestinations, bpsSplits);
  }

  // ============================================== INTERNAL FUNCTIONS ==============================================

  function _getCreatorsFeeInfo(
    address collection,
    uint256 tokenId,
    uint256 amount
  )
    internal
    view
    returns (
      address,
      address[] memory,
      uint16[] memory,
      uint256[] memory
    )
  {
    bytes4 INTERFACE_ID_ERC2981 = 0x2a55205a;
    uint256[] memory amounts;
    // check if the creators fee is registered
    (address setter, address[] memory destinations, uint16[] memory bpsSplits) = IFeeRegistry(CREATORS_FEE_REGISTRY)
      .getFeeInfo(collection);
    if (destinations.length > 0) {
      uint256[] memory creatorsFees = new uint256[](bpsSplits.length);
      for (uint256 i = 0; i < bpsSplits.length; ) {
        creatorsFees[i] = (bpsSplits[i] * amount) / 10000;
        unchecked {
          ++i;
        }
      }
      return (setter, destinations, bpsSplits, creatorsFees);
    } else if (IERC165(collection).supportsInterface(INTERFACE_ID_ERC2981)) {
      destinations = new address[](1);
      amounts = new uint256[](1);
      (destinations[0], amounts[0]) = IERC2981(collection).royaltyInfo(tokenId, amount);
      return (address(0), destinations, bpsSplits, amounts);
    } else {
      // lookup from royaltyregistry.eth
      (destinations, amounts) = royaltyEngine.getRoyaltyView(collection, tokenId, amount);
      return (address(0), destinations, bpsSplits, amounts);
    }
  }

  // ============================================== VIEW FUNCTIONS ==============================================

  function getCreatorsFeeInfo(
    address collection,
    uint256 tokenId,
    uint256 amount
  )
    external
    view
    returns (
      address,
      address[] memory,
      uint16[] memory,
      uint256[] memory
    )
  {
    return _getCreatorsFeeInfo(collection, tokenId, amount);
  }

  // ===================================================== ADMIN FUNCTIONS =====================================================

  function setMaxCreatorFeeBps(uint16 _maxBps) external onlyOwner {
    MAX_CREATOR_FEE_BPS = _maxBps;
    emit NewMaxBPS(_maxBps);
  }

  function updateRoyaltyEngine(address _royaltyEngine) external onlyOwner {
    royaltyEngine = IRoyaltyEngine(_royaltyEngine);
    emit NewRoyaltyEngine(_royaltyEngine);
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
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be payed in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

enum FeeParty {
  CREATORS,
  COLLECTORS,
  CURATORS
}

interface IFeeManager {
  function calcFeesAndGetRecipients(
    address complication,
    address collection,
    uint256 tokenId,
    uint256 amount
  )
    external
    view
    returns (
      FeeParty partyName,
      address[] memory,
      uint256[] memory
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOwnable {
  function owner() external view returns (address);

  function admin() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IRoyaltyEngine {
  function getRoyaltyView(
    address tokenAddress,
    uint256 tokenId,
    uint256 value
  ) external view returns (address[] memory recipients, uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFeeRegistry {
  function registerFeeDestinations(
    address collection,
    address setter,
    address[] calldata destinations,
    uint16[] calldata bpsSplits
  ) external;

  function getFeeInfo(address collection)
    external
    view
    returns (
      address,
      address[] calldata,
      uint16[] calldata
    );
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}