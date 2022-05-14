// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./IToken.sol";

contract DutchAuctionRefundable is Ownable, Pausable, ReentrancyGuard {
  // ======== Supply =========
  uint256 public immutable maxMintPerAccount;
  uint256 public immutable maxSupply;
  uint256 public immutable maxMintPerTx;
  address public immutable treasury;

  // ======== Auction Mechanics =========
  uint256 public immutable auctionStartPrice;
  uint256 public immutable refundEndTs;
  uint256 public immutable auctionEndPrice;
  uint256 public finalRestingPrice;
  uint256 public immutable auctionAlloc;
  uint256 public immutable priceCurveLength;
  uint256 public immutable priceDropInterval;
  uint256 public immutable priceDropPerStep;
  uint256 public totalSoldDuringAuction;
  

  // ======== Sale Status =========
  bool public isSaleActive = false;
  uint256 public immutable auctionSaleStart; 
  uint256 public immutable whitelistSaleStart; 
  uint256 public immutable publicSaleStart;

  // ======== Whitelist Validation =========
  bytes32 public whitelistMerkleRoot;
  uint256 public whitelistSold;
  uint256 public whitelistPercPrice;

  // ======== External Storage Contract =========
  IToken public immutable token;

  struct UserPurchase {
    uint128 paid;
    uint128 qty;
  }

  mapping(address => uint256) public userCount;
  mapping (address => uint256) public whitelistCount;
  mapping (address => UserPurchase[]) public userPurchases;

  event WhitelistSale(address indexed user, uint256 qty);
  event PublicSale(address indexed user, uint256 qty);
  
  /// @notice Ctor
  /// @param nftCollection The adress of the NFT smart contract
  /// @param _treasury The address that will be receiving the funds from the sale
  /// @param dates The following dates
  ///              _auctionSaleStart The start date of the auction
  ///              _whitelistSaleStart The start date of the whitelist sale
  ///              _refundEndTs The end date of the refund window
  ///              _publicSaleStart The start date of the public sale
  /// @param auctionParams The starting, end price and total allocation of the auction
  /// @param auctionCurve The curve length and drop interval of the auction
  /// @param maxMintPerAccountAndTx The max amount one can mint per tx and per a single account
  /// @param maxTokenSupply The max supply of NFT to be minted
  /// @param _whitelistMerkleRoot The merkle root of the whitelisted accountes and their allocation
  /// @param _whitelistPercPrice The percentage of the final resting price that whitelisted account will pay for each NFT; 
  ///                            should be a value in the range[0, 10_000]
  constructor(
    address nftCollection,
    address _treasury,
    uint256[4] memory dates,
    uint256[3] memory auctionParams,
    uint256[2] memory auctionCurve,
    uint256[2] memory maxMintPerAccountAndTx,
    uint256 maxTokenSupply,
    bytes32 _whitelistMerkleRoot,
    uint256 _whitelistPercPrice
  ) {
    token = IToken(nftCollection);
    treasury = _treasury;
    auctionSaleStart = dates[0];
    whitelistSaleStart = dates[1];
    refundEndTs = dates[2];
    publicSaleStart = dates[3];
    auctionStartPrice = auctionParams[0];
    auctionEndPrice = auctionParams[1];
    auctionAlloc = auctionParams[2];
    priceCurveLength = auctionCurve[0];
    priceDropInterval = auctionCurve[1];
    priceDropPerStep = (auctionStartPrice - auctionEndPrice) / (priceCurveLength / priceDropInterval);
    maxMintPerAccount = maxMintPerAccountAndTx[0];
    maxMintPerTx = maxMintPerAccountAndTx[1];
    maxSupply = maxTokenSupply;
    whitelistMerkleRoot = _whitelistMerkleRoot;
    whitelistPercPrice = _whitelistPercPrice;
  }

  /// @notice Allows owner to mint team tokens
  /// @param to The address to send the minted tokens to
  /// @param qty The amount of tokens to mint
  /// @dev Only owner can call this method
  function mintTeamTokens(address to, uint256 qty) external onlyOwner {
      require(token.tokenCount() + qty <= maxSupply, "sold out");
      token.mint(qty, to);
  }

  /// @notice Toggles the status of the sale
  /// @dev Only owner can call this method
  function toggleSale() external onlyOwner {
    isSaleActive = !isSaleActive;
  }
  
  /// @notice Fetches the list of the purchases for the given user
  /// @param user The account for which we retrieve the purchases
  /// @return UserPurchase[] the list of all the purchases for the given user
  function getUserPurchases(address user) external view returns(UserPurchase[] memory) {
    return userPurchases[user];
  }

  /// @notice Returns the current price of the auction
  function getCurrentPrice() public view returns (uint256) {
    if (block.timestamp < auctionSaleStart) {
      return auctionStartPrice;
    }

    uint256 elapsed = block.timestamp - auctionSaleStart;
    if (elapsed >= priceCurveLength) {
      return auctionEndPrice;
    } else {
      uint256 steps = elapsed / priceDropInterval;
      return auctionStartPrice - (steps * priceDropPerStep);
    }
  }

  /// @notice Allow anyone to participate in the auction and seal a purchase at the given auction price.
  /// Any users that paid above the final resting price will be able to claim a refund for the difference.
  /// @param qty The number of NFTs one wants to purchase
  function auctionMint(uint256 qty) external payable nonReentrant whenNotPaused {
    require(block.timestamp >= auctionSaleStart, "auction not started");
    require(isSaleActive, "auction sale not active");
    require(totalSoldDuringAuction + qty <= auctionAlloc, "sold out");
    require(qty <= maxMintPerTx, "max mint per tx");
    require(qty + userCount[_msgSender()] <= maxMintPerAccount, "too many mints");

    uint256 currentPrice = getCurrentPrice();
    require(msg.value == qty * currentPrice, "wrong amount");

    totalSoldDuringAuction += qty;
    userCount[_msgSender()] += qty;
    userPurchases[_msgSender()].push(
      UserPurchase(uint128(msg.value), uint128(qty))
    );

    if (totalSoldDuringAuction == auctionAlloc) {
      finalRestingPrice = currentPrice;
    }

    token.mint(qty, _msgSender());
  }

  /// @notice Checks if the given account in in the whitelist
  /// @dev Validates the given merkle proof
  /// @param account account to check if it's whitelisted
  /// @param proof The merkle proof that validates whether the given user is whitelisted
  /// @param qty The number of NFTs user willing to mint. MUST qty <= alloc
  /// @return true if the user is whitelisted, false otherwise
  function isWhitelisted(
    address account,
    bytes32[] memory proof,
    uint256 qty
  ) view public returns(bool) {
    return MerkleProof.verify(proof, whitelistMerkleRoot, keccak256(abi.encodePacked(keccak256(abi.encodePacked(account, qty)))));
  }

  /// @notice transfers the given amount of ETH to the destination address
  /// @param dest Account to receive the funds
  /// @param amount Amount to be transfered
  function transferETH(address dest, uint256 amount) private {
    (bool success, ) = payable(dest).call{value: amount}("");
    require(success, "transfer failed");
  }

  /// @notice transfers the given amount of ETH to the destination address.
  /// @dev Used when ETH are send from an EOA
  /// @param dest Account to receive the funds
  /// @param amount Amount to be transfered
  function transferFunds(address dest, uint256 amount) private {
    require(msg.value == amount, "wrong amount");
    transferETH(dest, amount);
  }

  /// @notice Allows whitelisted accounts to directly purchase the NFT as percentage of the final resting price
  /// @dev Whitelitesting is done via a merkle tree
  /// @param proof The merkle proof that validates whether the given user is whitelisted
  /// @param qty The number of NFTs user willing to mint. MUST qty <= alloc
  function whitelistSale(
    bytes32[] memory proof,
    uint256 qty
  ) external payable nonReentrant whenNotPaused {
    require(isSaleActive, "whitelist sale not active");
    require(
      block.timestamp >= whitelistSaleStart,
      "auction not finished"
    );
    require(
      isWhitelisted(_msgSender(), proof, qty),
      "not whitelisted"
    );
    require(whitelistCount[_msgSender()] == 0, "all NFTs purchased");

    whitelistSold += qty;
    whitelistCount[_msgSender()] += qty;
    
    uint256 totalCost = (qty * finalRestingPrice * whitelistPercPrice) / 10_000;
    transferFunds(treasury, totalCost);

    token.mint(qty, _msgSender());

    emit WhitelistSale(_msgSender(), qty);
  }

  /// @notice Allows the dev team to set the merkle root used for whitelist
  /// @param merkleRoot The merkle root generated offchain
  /// @dev Only owner can call this method
  function setWhitelistMerkleRoot(bytes32 merkleRoot) external onlyOwner {
    whitelistMerkleRoot = merkleRoot;
  }

  /// @notice Allows anyone to participate in the public sale to buy any leftovers
  /// @param qty The number of NFTs user willing to mint
  function publicSale(uint256 qty) external payable nonReentrant whenNotPaused {
    require(isSaleActive, "public sale not active");
    require(
      block.timestamp >= publicSaleStart,
      "public sale not started"
    );
    require(token.tokenCount() + qty <= maxSupply, "sold out");

    upsertFinalRestingPrice();
    transferFunds(treasury, qty * finalRestingPrice);

    token.mint(qty, _msgSender());
    
    emit PublicSale(_msgSender(), qty);
  }

  /// @notice Sets the final resting price if needed to be the auctionEndPrice.
  /// this will happen in case the predetermined allocation is not sold during the auction
  function upsertFinalRestingPrice() private {
    if(finalRestingPrice == 0) {
      finalRestingPrice = auctionEndPrice;
    }
  }
  
  /// @notice Any users that paid above the final resting price will be able to claim a refund for the difference.
  function refundETH() external {
    require(block.timestamp <= refundEndTs, "refund ended");
    require(block.timestamp > auctionSaleStart + priceCurveLength, "auction still running");
    require(userPurchases[_msgSender()].length > 0, "no purchases found");
    
    upsertFinalRestingPrice();

    uint256 totalRefund;

    for (uint256 i = userPurchases[_msgSender()].length; i > 0; i--) {
      UserPurchase memory userPurchase = userPurchases[_msgSender()][i - 1];
      
      uint256 expectedPrice = userPurchase.qty * finalRestingPrice;
      uint256 refund = userPurchase.paid - expectedPrice;

      userPurchases[_msgSender()].pop();

      totalRefund += refund;
    }

    if(totalRefund > 0) {
      transferETH(_msgSender(), totalRefund);
    }
  }

  /// @notice Returns true if auction is currently active.
  function isAuctionActive() external view returns (bool) {
    return block.timestamp >= auctionSaleStart && block.timestamp < whitelistSaleStart && block.timestamp < publicSaleStart && isSaleActive;
  }

  /// @notice Returns true if whitelist sale is currently active.
  function isWhitelistSaleActive() external view returns (bool) {
    return block.timestamp >= whitelistSaleStart && block.timestamp < publicSaleStart && isSaleActive;
  }

  /// @notice Returns true if public sale is currently active.
  function isPublicSaleActive() external view returns (bool) {
        return block.timestamp >= publicSaleStart && isSaleActive;
  }

  /// @notice Allows the user to withdraw funds
  function withdrawFunds() onlyOwner external {
    require(block.timestamp > auctionSaleStart + priceCurveLength, "auction still running");
  
    upsertFinalRestingPrice();
    transferETH(treasury, totalSoldDuringAuction * finalRestingPrice);
  }

  /// @notice Allows the user to withdraw funds
  /// @dev Only after the refund window is closed
  function rescueFunds() onlyOwner external {
    require(block.timestamp > refundEndTs, "refund is still open");

    transferETH(treasury, address(this).balance);
  }

  /// @notice Pause the contract
  /// @dev Only owner can call this method
  function pause() external onlyOwner {
    _pause();
  }

  /// @notice Unpause the contract
  /// @dev Only owner can call this method
  function unpause() external onlyOwner {
    _unpause();
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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 */
library MerkleProof {
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
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT
/// @title Interface for Token

pragma solidity ^0.8.13;

abstract contract IToken {
  function setProvenanceHash(string memory _provenanceHash) virtual external;

  function mint(uint256 _count, address _recipient) virtual external;

  function setBaseURI(string memory baseURI) virtual external;

  function updateMinter(address _minter) virtual external;

  function lockMinter() virtual external;
  
  function tokenCount() virtual external view returns (uint256);
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