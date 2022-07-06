// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {
  Initializable
} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {
  OwnableUpgradeable
} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {IRegistrar} from "../interfaces/IRegistrar.sol";
import {IZNSHub} from "../interfaces/IZNSHub.sol";

contract ClaimWithChildSale is Initializable, OwnableUpgradeable {
  // zNS Hub
  IZNSHub public zNSHub;

  IRegistrar public registrarOfClaimDomain;

  event RefundedEther(address buyer, uint256 amount);

  event SaleStarted(uint256 block);

  // Domains under this parent will be allowed to make claims.
  uint256 public claimingParentId;

  // The parent domain to mint sold domains under
  uint256 public newDomainParentId;

  // Price of each domain to be sold
  uint256 public salePrice;

  // The wallet to transfer proceeds to
  address public sellerWallet;

  // Total number of domains to be sold
  uint256 public totalForSale;

  // Number of domains sold so far
  uint256 public domainsSold;

  // Indicating whether the sale has started or not
  bool public saleStarted;

  // The block number that a sale started on
  uint256 public saleStartBlock;

  // If a sale has been paused
  bool public paused;

  // The number with which to start the metadata index (e.g. number is 100, so indicies are 100, 101, ...)
  uint256 public startingMetadataIndex;

  // The ID of the folder group that has been set up for this sale - needs to be initialized in advance
  uint256 public folderGroupID;

  // Time in blocks that the claiming period will occur
  uint256 public saleDuration;

  // Mapping to keep track of who has purchased which domain.
  mapping(uint256 => address) public domainsClaimedWithBy;

  function __ClaimWithChildSale_init(
    uint256 newDomainParentId_,
    uint256 price_,
    IZNSHub zNSHub_,
    address sellerWallet_,
    uint256 saleDuration_,
    uint256 startingMetadataIndex_,
    uint256 folderGroupID_,
    uint256 totalForSale_,
    IRegistrar registrarOfClaimDomain_,
    uint256 claimingParentId_
  ) public initializer {
    __Ownable_init();

    newDomainParentId = newDomainParentId_;
    salePrice = price_;
    zNSHub = zNSHub_;
    sellerWallet = sellerWallet_;
    startingMetadataIndex = startingMetadataIndex_;
    folderGroupID = folderGroupID_;
    saleDuration = saleDuration_;
    totalForSale = totalForSale_;
    registrarOfClaimDomain = registrarOfClaimDomain_;
    claimingParentId = claimingParentId_;
  }

  function setHub(IZNSHub zNSHub_) external onlyOwner {
    require(zNSHub != zNSHub_, "Same hub");
    zNSHub = zNSHub_;
  }

  // Start the sale if not started
  function startSale() external onlyOwner {
    require(!saleStarted, "Sale already started");
    saleStarted = true;
    saleStartBlock = block.number;
    emit SaleStarted(saleStartBlock);
  }

  // Stop the sale if started
  function stopSale() external onlyOwner {
    require(saleStarted, "Sale not started");
    saleStarted = false;
  }

  // Pause a sale
  function setPauseStatus(bool pauseStatus) external onlyOwner {
    require(paused != pauseStatus, "No state change");
    paused = pauseStatus;
  }

  // Set the price of this sale
  function setSalePrice(uint256 price) external onlyOwner {
    require(salePrice != price, "No price change");
    salePrice = price;
  }

  // Modify the address of the seller wallet
  function setSellerWallet(address wallet) external onlyOwner {
    require(wallet != sellerWallet, "Same Wallet");
    sellerWallet = wallet;
  }

  // Modify parent domain ID of a domain
  function setNewDomainParentId(uint256 parentId) external onlyOwner {
    require(newDomainParentId != parentId, "Same parent id");
    newDomainParentId = parentId;
  }

  function setClaimingParentId(uint256 parentId) external onlyOwner {
    require(claimingParentId != parentId, "Same parent id");
    claimingParentId = parentId;
  }

  // Update the number of blocks that the sale will occur
  function setSaleDuration(uint256 durationInBlocks) external onlyOwner {
    require(saleDuration != durationInBlocks, "No state change");
    saleDuration = durationInBlocks;
  }

  // Set the number with which to start the metadata index (e.g. number is 100, so indicies are 100, 101, ...)
  function setStartIndex(uint256 index) external onlyOwner {
    require(index != startingMetadataIndex, "Cannot set to the same index");
    startingMetadataIndex = index;
  }

  // Set the hash of the base IPFS folder that contains the domain metadata
  function setFolderGroupID(uint256 folderGroupID_) external onlyOwner {
    require(folderGroupID != folderGroupID_, "Cannot set to same folder group");
    folderGroupID = folderGroupID_;
  }

  // Add new metadata URIs to be sold
  function setAmountOfDomainsForSale(uint256 forSale) public onlyOwner {
    totalForSale = forSale;
  }

  function setregistrarOfClaimDomain(IRegistrar registrarOfClaimDomain_)
    public
  {
    require(
      registrarOfClaimDomain != registrarOfClaimDomain_,
      "No state change"
    );
    registrarOfClaimDomain = registrarOfClaimDomain_;
  }

  // Remove a domain from this sale
  function releaseDomain() external onlyOwner {
    IRegistrar zNSRegistrar = zNSHub.getRegistrarForDomain(newDomainParentId);
    zNSRegistrar.transferFrom(address(this), owner(), newDomainParentId);
  }

  // Purchase `count` domains
  // Not the `purchaseLimit` you provide must be
  // less than or equal to what is in the mintlist
  function claimDomains(uint256[] calldata claimingIds) public payable {
    _canAccountClaim(claimingIds);
    _claimDomains(claimingIds);
  }

  function _canAccountClaim(uint256[] calldata claimingIds) internal view {
    require(claimingIds.length > 0, "Zero purchase count");
    require(domainsSold < totalForSale, "No domains left for claim");
    require(
      msg.value >= salePrice * claimingIds.length,
      "Not enough funds in purchase"
    );
    require(!paused, "paused");
    require(saleStarted, "Sale hasn't started or has ended");
    require(block.number <= saleStartBlock + saleDuration, "Sale has ended");
    for (uint256 i = 0; i < claimingIds.length; i++) {
      require(
        domainsClaimedWithBy[claimingIds[i]] == address(0),
        "NFT already claimed"
      );
      IRegistrar zNSRegistrar = zNSHub.getRegistrarForDomain(claimingIds[i]);
      require(
        zNSHub.ownerOf(claimingIds[i]) == msg.sender,
        "Claiming with unowned NFT"
      );
      require(
        zNSRegistrar.parentOf(claimingIds[i]) == claimingParentId,
        "Claiming with ineligible NFT"
      );
    }
  }

  function _claimDomains(uint256[] calldata claimingIds) internal {
    uint256 numPurchased = _reserveDomainsForPurchase(claimingIds.length);
    uint256 proceeds = salePrice * numPurchased;
    if (proceeds > 0) {
      _sendPayment(proceeds);
    }
    _mintDomains(numPurchased, claimingIds);
  }

  function _reserveDomainsForPurchase(uint256 count)
    internal
    returns (uint256)
  {
    uint256 numPurchased = count;
    // If we are trying to purchase more than is available, purchase the remainder
    if (domainsSold + count > totalForSale) {
      numPurchased = totalForSale - domainsSold;
    }
    domainsSold += numPurchased;

    return numPurchased;
  }

  // Transfer funds to the buying user, refunding if necessary
  function _sendPayment(uint256 proceeds) internal {
    payable(sellerWallet).transfer(proceeds);

    // Send refund if neceesary for any unclaimed domains
    if (msg.value - proceeds > 0) {
      payable(msg.sender).transfer(msg.value - proceeds);
      emit RefundedEther(msg.sender, msg.value - proceeds);
    }
  }

  function _mintDomains(uint256 numPurchased, uint256[] calldata claimingIds)
    internal
  {
    // Mint the domains after they have been claimed
    uint256 startingIndex = startingMetadataIndex + domainsSold - numPurchased;

    registrarOfClaimDomain.registerDomainInGroupBulk(
      newDomainParentId, //parentId
      folderGroupID, //groupId
      0, //namingOffset
      startingIndex, //startingIndex
      startingIndex + numPurchased, //endingIndex
      sellerWallet, //minter
      0, //royaltyAmount
      msg.sender //sendTo
    );
    for (uint256 i = 0; i < numPurchased; ++i) {
      domainsClaimedWithBy[claimingIds[i]] = msg.sender;
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

interface IRegistrar {
  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;

  function registerDomainAndSend(
    uint256 parentId,
    string memory label,
    address minter,
    string memory metadataUri,
    uint256 royaltyAmount,
    bool locked,
    address sendToUser
  ) external returns (uint256);

  function registerDomainInGroupBulk(
    uint256 parentId,
    uint256 groupId,
    uint256 namingOffset,
    uint256 startingIndex,
    uint256 endingIndex,
    address minter,
    uint256 royaltyAmount,
    address sendTo
  ) external;

  function createDomainGroup(string memory baseMetadataUri) external;

  function tokenByIndex(uint256 index) external view returns (uint256);

  function parentOf(uint256 id) external view returns (uint256);

  function ownerOf(uint256 id) external view returns (address);

  function numDomainGroups() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import {IRegistrar} from "./IRegistrar.sol";

interface IZNSHub {
  function addRegistrar(uint256 rootDomainId, address registrar) external;

  function isController(address controller) external returns (bool);

  function getRegistrarForDomain(uint256 domainId)
    external
    view
    returns (IRegistrar);

  function ownerOf(uint256 domainId) external view returns (address);

  function domainExists(uint256 domainId) external view returns (bool);

  function owner() external view returns (address);

  function registrarBeacon() external view returns (address);

  function domainTransferred(
    address from,
    address to,
    uint256 tokenId
  ) external;

  function domainCreated(
    uint256 id,
    string calldata name,
    uint256 nameHash,
    uint256 parent,
    address minter,
    address controller,
    string calldata metadataUri,
    uint256 royaltyAmount
  ) external;

  function metadataLockChanged(
    uint256 id,
    address locker,
    bool isLocked
  ) external;

  function metadataChanged(uint256 id, string calldata uri) external;

  function royaltiesAmountChanged(uint256 id, uint256 amount) external;

  // Returns the parent domain of a child domain
  function parentOf(uint256 id) external view returns (uint256);

  function subdomainRegistrars(uint256 id) external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}