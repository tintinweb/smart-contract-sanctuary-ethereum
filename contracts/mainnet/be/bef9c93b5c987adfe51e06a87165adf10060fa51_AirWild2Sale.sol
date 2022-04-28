// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {
  Initializable
} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {
  OwnableUpgradeable
} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {IRegistrar} from "./interfaces/IRegistrar.sol";
import {
  MerkleProofUpgradeable
} from "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";

contract AirWild2Sale is Initializable, OwnableUpgradeable {
  // zNS Registrar
  IRegistrar public zNSRegistrar;

  event RefundedEther(address buyer, uint256 amount);

  event SaleStarted(uint256 block);

  // The parent domain to mint sold domains under
  uint256 public parentDomainId;

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

  // The containing folder hash without a Qm prefix
  string public baseFolderHash;

  // Merkle root data to verify on mintlist
  bytes32[] public mintlistMerkleRoots;

  // Time in blocks that each mintlist will last (in order)
  uint256[] public mintlistDurations;

  // There are multiple mintlists in this sale. Which one are we using now?
  uint256 public currentMerkleRootIndex;

  // Mapping to keep track of how many domains an account has purchased so far
  mapping(address => uint256) public domainsPurchasedByAccount;

  function __AirWild2Sale_init(
    uint256 parentDomainId_,
    uint256 price_,
    IRegistrar zNSRegistrar_,
    address sellerWallet_,
    uint256[] memory mintlistDurations_,
    bytes32[] memory merkleRoots_,
    uint256 startingMetadataIndex_,
    string calldata baseFolderHash_, // in the following format: ipfs://Qm.../
    uint256 numForSale_
  ) public initializer {
    __Ownable_init();

    require(mintlistDurations_.length == merkleRoots_.length, "Mintlist and merkle mismatch");

    parentDomainId = parentDomainId_;
    salePrice = price_;
    zNSRegistrar = zNSRegistrar_;
    sellerWallet = sellerWallet_;
    mintlistDurations = mintlistDurations_;
    mintlistMerkleRoots = merkleRoots_;
    startingMetadataIndex = startingMetadataIndex_;
    baseFolderHash = baseFolderHash_;
    totalForSale = numForSale_;
  }

  function setRegistrar(IRegistrar zNSRegistrar_) external onlyOwner {
    require(zNSRegistrar != zNSRegistrar_, "Same registrar");
    require(address(zNSRegistrar_) != address(0), "Registrar not initialized");
    zNSRegistrar = zNSRegistrar_;
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

  // Update the merkle list roots
  function setMerkleRules(bytes32[] memory mintlistMerkleRoots_, uint256[] memory mintlistDurations_) external onlyOwner {
    require(mintlistMerkleRoots_.length == mintlistDurations_.length, "List length mismatch");
    require(mintlistMerkleRoots_.length > 0, "Empty roots array");
    // Assume lists are equivalent...
    bool listsAreEquivalent = mintlistMerkleRoots.length == mintlistMerkleRoots_.length;
    if(listsAreEquivalent){
      for(uint256 i = 0; i < mintlistMerkleRoots_.length; i++){
        // ...until proven otherwise
        if(mintlistMerkleRoots[i] != mintlistMerkleRoots_[i] || mintlistDurations_[i] != mintlistDurations[i]){
          listsAreEquivalent = false;
          break;
        }
      }
    }
    require(!listsAreEquivalent, "No state change");
    mintlistDurations = mintlistDurations_;
    mintlistMerkleRoots = mintlistMerkleRoots_;
  }

  function setMerkleRootIndex(uint8 newIndex_) external onlyOwner {
    require(currentMerkleRootIndex!=newIndex_, "Same index");
    require(mintlistMerkleRoots[newIndex_] != bytes32(0), "No mintlist stored at that index");
    // Consider this the start of a new sale
    saleStartBlock = block.number;
    currentMerkleRootIndex = newIndex_;
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
  function setParentDomainId(uint256 parentId) external onlyOwner {
    require(parentDomainId != parentId, "Same parent id");
    parentDomainId = parentId;
  }

  // Update the number of blocks that each mintlist will last
  function setMintlistDuration(uint256 index, uint256 durationInBlocks) external onlyOwner {
    require(mintlistDurations.length > index, "Index out of bounds");
    require(mintlistDurations[index] != durationInBlocks, "No state change");
    mintlistDurations[index] = durationInBlocks;
  }

  // Set the number with which to start the metadata index (e.g. number is 100, so indicies are 100, 101, ...)
  function setStartIndex(uint256 index) external onlyOwner {
    require(index != startingMetadataIndex, "Cannot set to the same index");
    startingMetadataIndex = index;
  }

  // Set the hash of the base IPFS folder that contains the domain metadata
  function setBaseFolderHash(string calldata folderHash)
    external
    onlyOwner
  {
    require(
      keccak256(bytes(folderHash)) !=
        keccak256(bytes(baseFolderHash)),
      "Cannot set to same folder uri"
    );
    baseFolderHash = folderHash;
  }

  // Add new metadata URIs to be sold
  function setAmountOfDomainsForSale(uint256 forSale) public onlyOwner {
    totalForSale = forSale;
  }

  // Remove a domain from this sale
  function releaseDomain() external onlyOwner {
    zNSRegistrar.transferFrom(address(this), owner(), parentDomainId);
  }

  // Purchase `count` domains
  // Not the `purchaseLimit` you provide must be
  // less than or equal to what is in the mintlist
  function purchaseDomains(
    uint8 count,
    uint256 index,
    uint256 purchaseLimit,
    bytes32[] calldata merkleProof
  ) public payable {
    _canAccountPurchase(msg.sender, count, purchaseLimit);
    _requireVariableMerkleProof(index, purchaseLimit, merkleProof);
    _purchaseDomains(count);
  }

  function getNftByIndex(uint256 index) public view returns (string memory) {
    return
      string(
        abi.encodePacked(
          baseFolderHash, 
          Strings.toString(startingMetadataIndex + index)
        )
      );
  }

  function _canAccountPurchase(
    address account,
    uint8 count,
    uint256 purchaseLimit
  ) internal view {
    require(count > 0, "Zero purchase count");
    require(domainsSold < totalForSale, "No domains left for sale");
    require(
      domainsPurchasedByAccount[account] + count <= purchaseLimit,
      "Purchasing beyond limit."
    );
    require(msg.value >= salePrice * count, "Not enough funds in purchase");
    require(!paused, "paused");
    require(saleStarted, "Sale hasn't started or has ended");
    require(
      block.number <= saleStartBlock + mintlistDurations[currentMerkleRootIndex],
      "Sale has ended"
    );
  }

  function _purchaseDomains(uint8 count) internal {
    uint256 numPurchased = _reserveDomainsForPurchase(count);
    uint256 proceeds = salePrice * numPurchased;
    _sendPayment(proceeds);
    _mintDomains(numPurchased);
  }

  function _reserveDomainsForPurchase(uint8 count) internal returns (uint256) {
    uint256 numPurchased = count;
    // If we would are trying to purchase more than is available, purchase the remainder
    if (domainsSold + count > totalForSale) {
      numPurchased = totalForSale - domainsSold;
    }
    domainsSold += numPurchased;

    // Update number of domains this account has purchased
    // This is done before minting domains or sending any eth to prevent
    // a re-entrance attack through a recieve() or a safe transfer callback
    domainsPurchasedByAccount[msg.sender] =
      domainsPurchasedByAccount[msg.sender] +
      numPurchased;

    return numPurchased;
  }

  // Transfer funds to the buying user, refunding if necessary
  function _sendPayment(uint256 proceeds) internal {
    payable(sellerWallet).transfer(proceeds);

    // Send refund if neceesary for any unpurchased domains
    if (msg.value - proceeds > 0) {
      payable(msg.sender).transfer(msg.value - proceeds);
      emit RefundedEther(msg.sender, msg.value - proceeds);
    }
  }

  function _mintDomains(uint256 numPurchased) internal {
    // Mint the domains after they have been purchased
    for (uint256 i = 0; i < numPurchased; ++i) {
      // The sale contract will be the minter and own them at this point
      zNSRegistrar.registerDomainAndSend(
        parentDomainId,
        Strings.toString(startingMetadataIndex + domainsSold - numPurchased + i), 
        sellerWallet,
        getNftByIndex(startingMetadataIndex + domainsSold - numPurchased + i),
        0,
        true,
        msg.sender
      );
    }
  }

  function _requireVariableMerkleProof(
    uint256 index,
    uint256 quantity,
    bytes32[] calldata merkleProof
  ) internal view {
    bytes32 node = keccak256(abi.encodePacked(index, msg.sender, quantity));
    bytes32 currentMerkleRoot = mintlistMerkleRoots[currentMerkleRootIndex];
    require(
      MerkleProofUpgradeable.verify(merkleProof, currentMerkleRoot, node),
      "Invalid Merkle Proof"
    );
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

  function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProofUpgradeable {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
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