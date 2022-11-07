// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "./MerkleChild.sol";

contract MerkleFactory is Ownable {
    mapping(address => address[]) private tokenAirdrops;
    mapping(address => address[]) private creatorAirdrops;
    mapping(address => string) public airdropUserList;
    address[] private allAirdrops;

    IERC20 public immutable weth;
    uint256 public creatorFee = 0.01 ether;
    uint256 public claimFee = 0.003 ether;
    address payable public feeAddress;

    uint256 public minClaimPeriod = 2 hours;
    uint256 public maxClaimPeriod = 90 days;

    constructor(address _weth) {
        weth = IERC20(_weth);
        feeAddress = payable(msg.sender);
    }

    function createNewAirdrop(
        bool _isPayingInToken,
        address _token,
        uint256 _amount,
        uint256 _startDate,
        uint256 _endDate,
        string memory _url,
        bytes32 _merkleRoot
    ) external payable {
        uint256 duration = _endDate - _startDate;
        require(duration >= minClaimPeriod && duration <= maxClaimPeriod, "Invalid duration to claim airdrop");
        require(_amount > 0, "Zero amount");

        MerkleChild newAirdrop = new MerkleChild(
            _token,
            payable(msg.sender),
            feeAddress,
            _startDate,
            _endDate,
            _merkleRoot
        );
        airdropUserList[address(newAirdrop)] = _url;

        if (_isPayingInToken) {
            weth.transferFrom(msg.sender, feeAddress, creatorFee);
        } else {
            require(msg.value >= creatorFee, "Fees not paid");
            feeAddress.transfer(creatorFee);
        }

        allAirdrops.push(address(newAirdrop));
        tokenAirdrops[_token].push(address(newAirdrop));
        creatorAirdrops[msg.sender].push(address(newAirdrop));

        if (_token == address(0)) {
            /* solhint-disable-next-line */
            (bool success, ) = address(newAirdrop).call{ value: _amount }("");
            require(success, "");
        } else {
            IERC20(_token).transferFrom(msg.sender, address(newAirdrop), _amount);
        }
    }

    function setFees(
        address payable _newAddress,
        uint256 _creatorFee,
        uint256 _claimFee
    ) external onlyOwner {
        feeAddress = _newAddress;
        creatorFee = _creatorFee;
        claimFee = _claimFee;
    }

    function setClaimPeriod(uint256 min, uint256 max) external onlyOwner {
        minClaimPeriod = min;
        maxClaimPeriod = max;
    }

    function getAllTokenAirdrops(address _token) public view returns (address[] memory) {
        return tokenAirdrops[_token];
    }

    function getAllCreatorAirdrops(address _creator) public view returns (address[] memory) {
        return creatorAirdrops[_creator];
    }

    function getAllAirdrops() public view returns (address[] memory) {
        return allAirdrops;
    }

    function getAllAirdropsByIndex(uint256 startIdx, uint256 endIdx) public view returns (address[] memory) {
        if (endIdx > allAirdrops.length - 1) {
            endIdx = allAirdrops.length - 1;
        }
        address[] memory list = new address[](endIdx - startIdx + 1);
        uint256 counter = 0;

        for (uint256 i = startIdx; i <= endIdx; i++) {
            list[counter] = allAirdrops[i];
            counter++;
        }
        return list;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

interface IFactory {
    function claimFee() external view returns (uint256);
}

contract MerkleChild {
    bytes32 public immutable merkleRoot;
    IERC20 public immutable token;
    IFactory private immutable factory;

    uint32 internal constant CLAIM_GAP = 1 hours;
    uint32 internal constant CLAIM_PERIOD = 1 hours;
    uint8 internal constant CLAIM_FREQ = 4; //Total 4 times claim

    mapping(address => bool) public userClaimed;
    mapping(uint8 => bool) public creatorClaimed;
    bool public ownerClaimed;

    uint256 public nonClaimedFunds;
    uint256 public startDate;
    uint256 public endDate;

    address payable internal creator;
    address payable internal owner;

    event Claim(address indexed to, uint256 amount);

    receive() external payable {
        this;
    }

    constructor(
        address _token,
        address payable _creator,
        address payable _owner,
        uint256 _startDate,
        uint256 _endDate,
        bytes32 _merkleRoot
    ) {
        merkleRoot = _merkleRoot;
        token = IERC20(_token);
        startDate = _startDate;
        endDate = _endDate;
        creator = _creator;
        owner = _owner;
        factory = IFactory(msg.sender);
    }

    function claim(uint256 amount, bytes32[] calldata proof) external payable {
        require(msg.value >= factory.claimFee(), "Claim fee not sent");
        require(block.timestamp >= startDate && block.timestamp <= endDate, "Not Started/Expired");
        require(canUserClaim(msg.sender, amount, proof), "Invalid proof");
        require(!userClaimed[msg.sender], "Already claimed");

        userClaimed[msg.sender] = true;
        emit Claim(msg.sender, amount);

        payable(owner).transfer(msg.value);

        if (address(token) == address(0)) {
            payable(msg.sender).transfer(amount);
        } else {
            token.transfer(msg.sender, amount);
        }
    }

    function creatorClaim(uint8 roundId) external {
        require(msg.sender == creator, "Not creator");
        require(canCreatorClaim(roundId), "Not in creator claim period");
        require(!creatorClaimed[roundId], "Already claimed");
        require(roundId < CLAIM_FREQ, "Invalid claim round");

        creatorClaimed[roundId] = true;

        if (nonClaimedFunds == 0) {
            if (address(token) == address(0)) {
                nonClaimedFunds = address(this).balance;
            } else {
                nonClaimedFunds = token.balanceOf(address(this));
            }
        }

        if (address(token) == address(0)) {
            creator.transfer(nonClaimedFunds / CLAIM_FREQ);
        } else {
            token.transfer(creator, nonClaimedFunds / CLAIM_FREQ);
        }
    }

    function ownerClaim() external {
        require(msg.sender == owner, "Not owner");
        require(ownerClaimStatus(), "Not in owner claim period");

        ownerClaimed = true;

        if (address(token) == address(0)) {
            owner.transfer(address(this).balance);
        } else {
            token.transfer(owner, token.balanceOf(address(this)));
        }
    }

    function canCreatorClaim(uint8 roundId) public view returns (bool) {
        uint256 start = endDate + (((2 * roundId) + 1) * CLAIM_GAP);
        uint256 end = start + CLAIM_PERIOD;
        bool status = block.timestamp >= start && block.timestamp <= end;

        if (roundId > 0) {
            status = status && creatorClaimed[roundId - 1];
        }

        return status;
    }

    function canOwnerClaim(uint8 roundId) public view returns (bool) {
        uint256 end = endDate + (((2 * roundId) + 1) * CLAIM_GAP) + CLAIM_PERIOD;

        return (block.timestamp >= end && !creatorClaimed[roundId]);
    }

    function canUserClaim(
        address user,
        uint256 amount,
        bytes32[] calldata proof
    ) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(user, amount));
        bool isValidLeaf = MerkleProof.verify(proof, merkleRoot, leaf);
        return isValidLeaf;
    }

    function creatorClaimStatus() public view returns (bool[] memory status) {
        status = new bool[](CLAIM_FREQ);

        for (uint8 i = 0; i < CLAIM_FREQ; i++) {
            status[i] = (canCreatorClaim(i) && !creatorClaimed[i]);
        }
    }

    function ownerClaimStatus() public view returns (bool status) {
        for (uint8 i = 0; i < CLAIM_FREQ; i++) {
            if (canOwnerClaim(i)) {
                status = true;
                break;
            }
        }

        status = status && !ownerClaimed;
    }

    function userClaimStatus(address user) public view returns (bool) {
        return block.timestamp >= startDate && block.timestamp <= endDate && !userClaimed[user];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
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
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
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
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be proved to be a part of a Merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and the sibling nodes in `proof`,
     * consuming from one or the other at each step according to the instructions given by
     * `proofFlags`.
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
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