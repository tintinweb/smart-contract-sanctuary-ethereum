/**
 *Submitted for verification at Etherscan.io on 2022-10-23
*/

// File: contracts/libraries/TransferHelper.sol


pragma solidity ^0.8.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeApprove: approve failed"
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeTransfer: transfer failed"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::transferFrom: transferFrom failed"
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "TransferHelper::safeTransferETH: ETH transfer failed");
    }
}

// File: contracts/libraries/MerkleProof.sol


pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle trees (hash trees),
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: contracts/WorldCupDistributor.sol


pragma solidity ^0.8.0;




/// @notice use for claim reward
contract WorldCupDistributor {
    using TransferHelper for address;

    address public immutable token;
    bytes32 public merkleRoot;
    mapping(uint256 => mapping(address => bool)) claimedState;

    event DistributeReward(
        bytes32 indexed merkleRoot,
        uint256 indexed index,
        uint256 amount,
        uint256 settleBlockNumber
    );

    event Claimed(
        address indexed pool,
        address indexed user,
        uint256 indexed amount
    );

    struct MerkleDistributor {
        bytes32 merkleRoot;
        uint256 index;
        uint256 amount;
        uint256 settleBlockNumber;
    }
    MerkleDistributor[] public merkleDistributors;

    // This is a packed array of booleans.
    mapping(uint256 => uint256) private claimedBitMap;
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "not authorized!");
        _;
    }

    constructor(address token_) {
        token = token_;
        owner = msg.sender;
    }

    /// @param _index  the token will be distributed to users;
    /// @param _amount  the token will be distributed to users;
    /// @param _settleBlockNumber  the token will be distributed to users;
    /// @param _merkleRoot the merkle root generated by all user reward info
    function distributeReward(
        uint256 _index,
        uint256 _amount,
        uint256 _settleBlockNumber,
        bytes32 _merkleRoot
    ) external onlyOwner {
        merkleRoot = _merkleRoot;
        require(_index == merkleDistributors.length, "index already exists");

        uint256 currAmount = IERC20(token).balanceOf(address(this));
        require(currAmount >= _amount, "Insufficient reward funds");

        require(block.number >= _settleBlockNumber, "!blockNumber");

        if (merkleDistributors.length > 0) {
            MerkleDistributor memory md = merkleDistributors[
                merkleDistributors.length - 1
            ];
            require(
                md.settleBlockNumber < _settleBlockNumber,
                "!settleBlockNumber"
            );
        }

        merkleDistributors.push(
            MerkleDistributor(_merkleRoot, _index, _amount, _settleBlockNumber)
        );

        emit DistributeReward(_merkleRoot, _index, _amount, _settleBlockNumber);
    }

    /// @notice  user  claimed  reward with proof
    /// @param index user index in reward list
    /// @param amount  user reward amount
    /// @param proof  user merkelProof ,generate by merkel.js
    function claim(
        uint256 index,
        uint256 amount,
        bytes32[] calldata proof
    ) external {
        address user = msg.sender;
        require(merkleDistributors.length > index, "Invalid index");
        require(!isClaimed(index, user), "Drop already claimed.");

        MerkleDistributor storage merkleDistributor = merkleDistributors[index];
        require(merkleDistributor.amount >= amount, "Not sufficient");
        bytes32 leaf = keccak256(abi.encodePacked(index, user, amount));

        require(
            MerkleProof.verify(proof, merkleDistributor.merkleRoot, leaf),
            "Invalid proof."
        );

        merkleDistributor.amount = merkleDistributor.amount - amount;
        claimedState[index][user] = true;
        address(token).safeTransfer(msg.sender, amount);

        emit Claimed(address(this), user, amount);
    }

    function isClaimed(uint256 index, address user) public view returns (bool) {
        return claimedState[index][user];
    }

    /// @notice  owner withdraw the rest token
    function claimRestTokens(address to) public returns (bool) {
        // only owner
        require(msg.sender == owner);
        require(IERC20(token).balanceOf(address(this)) >= 0);
        require(
            IERC20(token).transfer(to, IERC20(token).balanceOf(address(this)))
        );
        return true;
    }
}