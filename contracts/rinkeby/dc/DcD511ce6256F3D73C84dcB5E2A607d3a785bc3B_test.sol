// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract test is Ownable {
    
    // IEstateContract public immutable estate;
    bytes32 public immutable merkleRoot;
    // uint256 public immutable estateId;

    // This is a packed array of booleans.
    mapping(uint256 => uint256) private claimedBitMap;
    mapping(address => bool) internal claimableAccounts;

    // time lock
    uint256 public startTime;
    uint256 public duration;

    // pause
    bool public paused;

    constructor (
        // address estateContract_, 
        bytes32 merkleRoot_, 
        // uint256 estateId_,
        address[] memory allowedAccounts_,
        uint256 startTime_
    ) {
        // estate = IEstateContract(estateContract_);
        merkleRoot = merkleRoot_;
        // estateId = estateId_;

        startTime = startTime_;
        addClaimableAccounts(allowedAccounts_);
        paused = false;
    }

    /** ========== public view functions ========== */

    function isClaimed(uint256 index) public view returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimedBitMap[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    /** ========== external functions ========== */

    function claim(uint256 index, address account, uint256[] calldata landIds, bytes32[] calldata merkleProof) external {


        if(paused == true) {
            revert claimPaused();
        }
        if(isClaimed(index)) {
            revert alreadyClaimed({index: index});
        }
        if(!_claimableAccount(account)) {
            revert notAllowedAccount();
        }
        if(block.timestamp < startTime) {
            revert notStartClaim();
        }
        if(duration != uint256(0)) {
            if(block.timestamp - startTime > duration) {
                revert exceedDuration();
            }
        }

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, account, landIds));
        if(!MerkleProof.verify(merkleProof, merkleRoot, node)) {
            revert invalidProof();
        }

        // Mark it claimed and send the token.
        _setClaimed(index);
        // estate.transferManyLands(estateId, landIds, account);

        // emit landDistributed(account, estateId, landIds);
    }

    /** ========== admin function ========== */
    function pause() external onlyOwner {
        paused = !paused;
    }

    function addClaimableAccount(address newAccount) public onlyOwner {
        _setClaimableAccount(newAccount);
    }

    function addClaimableAccounts(address[] memory newAccounts) public onlyOwner {
        if(newAccounts.length == 0) {
            revert invalidArray();
        }

        for(uint256 i = 0; i < newAccounts.length; i++ ) {
            _setClaimableAccount(newAccounts[i]);
        }
    }

    function setDuration(uint256 duration_) external onlyOwner {
        if(duration_ == uint256(0)) {
            revert invalidDuration();
        }

        duration = duration_;

        emit newDurationSet(duration_);
    }

    /** ========== internal & private functions ========== */

    function _setClaimed(uint256 index) private {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claimedBitMap[claimedWordIndex] = claimedBitMap[claimedWordIndex] | (1 << claimedBitIndex);
    }

    function _setClaimableAccount(address newAccount) internal {
        if(newAccount == address(0)) {
            revert nullAddress();
        }

        claimableAccounts[newAccount] = true;

        emit newClaimableAccount(newAccount);
    } 

    function _claimableAccount(address account) internal view returns (bool) {
        if(account == address(0)) {
            revert nullAddress();
        }
        
        return claimableAccounts[account];
    }


    /** ========== event ========== */
    event landDistributed(address indexed receiver, uint256 estateId, uint256[] landIds);
    event newClaimableAccount(address indexed account);
    event newDurationSet(uint256 indexed duration);

    /** ========== errors =========== */
    error notStartClaim();
    error exceedDuration();
    error invalidDuration();
    error notApprove();
    error alreadyClaimed(uint256 index);
    error invalidProof();
    error claimPaused();
    error nullAddress();
    error notAllowedAccount();
    error invalidArray();

    /** ========== modifier ========== */
    // modifier checkApproved() {
    //     if(estate.getApproved(estateId) != address(this)) {
    //         revert notApprove();
    //     }
    //     _;
    // }
}


interface IEstateContract {
  function transferManyLands(
    uint256 estateId,
    uint256[] calldata landIds,
    address destinatary
  ) external;

  function transferLand( 
    uint256 estateId,
    uint256 landId,
    address destinatary
  ) external;

  function getApproved(uint256 _tokenId) external view returns (address);
}

// SPDX-License-Identifier: MIT

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