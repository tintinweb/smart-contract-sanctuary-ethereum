// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract FlashBat is Ownable {
    bool public subscribingActive;
    bool public whitelistActive;
    uint256 public subscriptionPrice;
    uint256 public subscriptionLength;
    uint256 public whitelistDiscount;
    uint256 public whitelistPeriods;

    // Merkle Proof hash
    bytes32 public rootHash;

    // Mapping from address to subscription end time in seconds
    mapping(address => uint256) public subscriptionEnd;

    // Mapping from number of periods to discount in percent
    mapping(uint256 => uint256) public discounts;

    // Mapping to see if an address has subscribed at a discount before
    mapping(address => bool) private whitelistedSubscriberHasPurchased;

    constructor(
        uint256 _subscriptionPrice,
        uint256 _subscriptionLength,
        uint256 _whitelistDiscount,
        uint256 _whitelistPeriods,
        bool _subscribingActive,
        bool _whitelistActive
    ) {
        subscriptionPrice = _subscriptionPrice;
        subscriptionLength = _subscriptionLength;
        whitelistDiscount = _whitelistDiscount;
        whitelistPeriods = _whitelistPeriods;
        subscribingActive = _subscribingActive;
        whitelistActive = _whitelistActive;
    }

    // @notice Set the Merkle Tree root
    // @param _rootHash New root hash
    function setMerkleHash(bytes32 _rootHash) external onlyOwner {
        rootHash = _rootHash;
    }

    // @notice Set the subscription time length (in seconds)
    // @param _subscriptionLength Length of a subscription period (in seconds)
    function setSubscriptionLength(uint256 _subscriptionLength) external onlyOwner {
        subscriptionLength = _subscriptionLength;
    }

    // @notice Set the subscription price (in Wei)
    // @param _subscriptionPrice Amount to be paid for a subscription period (in Wei)
    function setSubscriptionPrice(uint256 _subscriptionPrice) external onlyOwner {
        subscriptionPrice = _subscriptionPrice;
    }

    // @notice Set a discount depending on number of periods bought
    // @param _periods Number of periods for which the discount will apply for
    // @param _discounts Discount values (in percent)
    function setDiscounts(uint256[] memory _periods, uint256[] memory _discounts) external onlyOwner {
        for (uint256 i = 0; i < _periods.length; i++) {
            discounts[_periods[i]] = _discounts[i];
        }
    }

    // @notice Set the whitelist discount value (in percent)
    // @param _whitelistDiscount New whitelist discount value (in percent)
    function setWhitelistDiscount(uint256 _whitelistDiscount) external onlyOwner {
        whitelistDiscount = _whitelistDiscount;
    }

    // @notice Set the number of periods for whitelisted members
    // @param _whitelistPeriods New number of periods for whitelisted members
    function setWhitelistPeriods(uint256 _whitelistPeriods) external onlyOwner {
        whitelistPeriods = _whitelistPeriods;
    }

    // @notice Enable or disable purchase of new subscriptions
    function setSubscribingActive() external onlyOwner {
        subscribingActive = !subscribingActive;
    }

    // @notice Enable or disable purchase of new whitelisted subscriptions
    function setWhitelistActive() external onlyOwner {
        whitelistActive = !whitelistActive;
    }

    // @notice Check if an address is currently subscribed
    // @param _address Address to check if currently subscribed
    function isSubscribed(address _address) public view returns (bool) {
        return block.timestamp <= subscriptionEnd[_address];
    }

    // @notice Get remaining time left regarding a subscription (in seconds)
    // @param _address Address to check remaining time for
    function getRemainingTime(address _address) external view returns (uint256) {

        // If not currently subscribed return zero
        uint256 remainingTime = 0;
        if (isSubscribed(_address)) {
            remainingTime = subscriptionEnd[_address] - block.timestamp;
        }

        return remainingTime;
    }

    // @notice Renew a subscription for 1 subscription period with no discount
    // @dev Acts as a function call with default value 1 for parameter periods
    function renewSubscription() external payable {
        renewSubscription(1);
    }

    // @notice Renew a subscription with no discount
    // @param periods Amount of time periods for which to renew the subscription for
    function renewSubscription(uint256 periods) public payable {
        renewSubscription(periods, discounts[periods]);
    }

    // @notice Owner can grant subscriptions to users
    // @param _address Addresses to grant a subscription for
    // @param _timestamps Timestamp until which subscription should be active for the given address
    function grantSubscription(address[] memory _addresses, uint256[] memory _timestamps) external onlyOwner {
        for (uint8 i = 0; i < _addresses.length; i++) {
            subscriptionEnd[_addresses[i]] = _timestamps[i];
        }
    }

    // @notice Get a discounted whitelist subscription
    // @param proof Merkle Tree proof
    function getWhitelistSubscription(bytes32[] memory proof) external payable {
        require(whitelistActive, "Whitelist purchasing is disabled");
        require(whitelistedSubscriberHasPurchased[msg.sender] == false, "You've already purchased");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(proof, rootHash, leaf), "Invalid proof");

        whitelistedSubscriberHasPurchased[msg.sender] = true;

        renewSubscription(whitelistPeriods, whitelistDiscount);
    }

    // @notice Renew a subscription
    // @param periods Amount of time periods for which to renew the subscription for
    // @param _discount Discount amount (in percent)
    function renewSubscription(uint256 periods, uint256 _discount) internal {
        require(subscribingActive, "Purchase of new subscriptions is disabled");

        uint256 cost = (subscriptionPrice * periods * (100 - _discount)) / 100;
        require(msg.value == cost, "Incorrect payment amount");

        // Get maximum of current time and current subscription end time
        uint256 subscriptionStart = subscriptionEnd[msg.sender] >= block.timestamp ? subscriptionEnd[msg.sender] : block.timestamp;

        subscriptionEnd[msg.sender] = subscriptionStart + (subscriptionLength * periods);
    }
    
    // @notice Transfer remaining subscription time to a different address
    // @param to Address to which the remaining subscription time will be given
    function transferRemainingSubscription(address to) external {
        require(msg.sender == tx.origin, "No contracts allowed");
        require(isSubscribed(msg.sender), "Cannot transfer inactive subscription");

        uint256 remainingTime = subscriptionEnd[msg.sender] - block.timestamp;
        if(isSubscribed(to)) {
            subscriptionEnd[to] += remainingTime;
        }
        else {
            subscriptionEnd[to] = block.timestamp + remainingTime;
        }
        subscriptionEnd[msg.sender] = block.timestamp;
    }

    // @notice Withdraw Ether
    function withdrawEther() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
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