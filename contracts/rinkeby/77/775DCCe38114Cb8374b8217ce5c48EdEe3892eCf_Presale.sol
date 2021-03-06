/**
 *Submitted for verification at Etherscan.io on 2022-04-26
*/

// SPDX-License-Identifier: GPL-3.0
// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


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

// File: @openzeppelin/contracts/utils/cryptography/MerkleProof.sol


// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/MerkleProof.sol)

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
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
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


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// File: contracts/presale.sol


pragma solidity ^0.8.13;

/*
    @title Presale
    @dev MerkleTree Whitelisting
*/

contract Presale is Ownable, ReentrancyGuard {
    constructor() {}
    
    enum Step {
        CLOSED,
        PREMIUM,
        BASIC,
        OPEN
    }

    Step public step = Step.CLOSED;
    uint public premiumMaxLimit = 8;
    uint public basicMaxLimit = 4;
    uint public openMaxLimit = 1;
    bytes32 private merkleRootPremium;
    bytes32 private merkleRootBasic;
    uint public price;
    uint public saledCount;
    uint public saledCountLimit = 8877;
    mapping(address => uint) public contribution;

    function setMaxLimit(uint _premiumMaxLimit, uint _basicMaxLimit, uint _openMaxLimit) external onlyOwner {
        premiumMaxLimit = _premiumMaxLimit;
        basicMaxLimit = _basicMaxLimit;
        openMaxLimit = _openMaxLimit;
    }

    function setMerkleTree(bytes32 _merkleRootPremium, bytes32 _merkleRootBasic) external onlyOwner {
        merkleRootPremium = _merkleRootPremium;
        merkleRootBasic = _merkleRootBasic;
    }

    function setPrice(uint _price) external onlyOwner {
        price = _price;
    }

    function setSaledCountLimit(uint _saledCountLimit) external onlyOwner {
        saledCountLimit = _saledCountLimit;
    }

    function goToNextStep() external onlyOwner {
        if(step == Step.CLOSED){
            step = Step.PREMIUM;
        } else if(step == Step.PREMIUM){
            step = Step.BASIC;
        } else if(step == Step.BASIC){
            step = Step.OPEN;
        } else{
            step = Step.CLOSED;
        }
    }

    function deposit(bytes32[] calldata _merkleProof) external payable nonReentrant {
        require(step != Step.CLOSED, "Presale is unavailable for now.");

        uint newContribution = msg.value / price;
        uint maxLimit;

        if(isPremiumUser(_merkleProof)) {
            maxLimit = premiumMaxLimit;
        } else if(isBasicUser(_merkleProof)) {
            require(step != Step.PREMIUM, "You are basic user, but current step is for only premium user.");
            maxLimit = basicMaxLimit;
        } else {
            require((step != Step.PREMIUM) && (step != Step.BASIC), "You are open user, but current step isn't for open user.");
            maxLimit = openMaxLimit;
        }

        require(saledCount + newContribution <= saledCountLimit, "SaledCount has limit");
        require(contribution[msg.sender] + newContribution <= maxLimit, "You can contribute only in your tier's limit." );
        saledCount += newContribution;
        contribution[msg.sender] += newContribution;
    }

    function withdraw() external onlyOwner returns (bool success) {
        (success,) = payable(msg.sender).call{value: address(this).balance}("");
    }

    function isPremiumUser(bytes32[] calldata _merkleProof) public view returns (bool) {
        return MerkleProof.verify(_merkleProof, merkleRootPremium, keccak256(abi.encodePacked(tx.origin)));
    }

    function isBasicUser(bytes32[] calldata _merkleProof) public view returns (bool isbasic) {
        return MerkleProof.verify(_merkleProof, merkleRootBasic, keccak256(abi.encodePacked(tx.origin)));
    }
}