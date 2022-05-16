/**
 *Submitted for verification at Etherscan.io on 2022-05-16
*/

pragma solidity ^0.8.0;



/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
}

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

/**
  Ref: https://github.com/Uniswap/merkle-distributor
 */
contract MerkleDistributor {
    bytes32 public  merkleRoot;
    bytes32 public  merkleRoot2;
    bytes32 public  merkleRoot3;
    bytes32 public  merkleRoot4;

    IERC20 public  token;
    IERC20 public  oldtoken;

    address public owner = 0xD319b2F19205BdC15f3b143da937Bdd12C66aaFA;
    bool public depositsAllowed = true;
    uint256 public claim_2_open_block = 2000;
    uint256 public claim_3_open_block = 3000;
    uint256 public claim_4_open_block = 4000;

    mapping(address => bool) public claimed;
    mapping(address => bool) public claimed2;
    mapping(address => bool) public claimed3;
    mapping(address => bool) public claimed4;

    event Claimed(address account, uint256 amount);
    event Claimed2(address account, uint256 amount);
    event Claimed3(address account, uint256 amount);
    event Claimed4(address account, uint256 amount);

    constructor(IERC20 _oldtoken) {
        oldtoken = _oldtoken;
    }

    function depositAirdrop(uint256 _amount) public {
        require(depositsAllowed == true, 'deposits closed my friend');
        oldtoken.transferFrom(msg.sender, address(this), _amount);
    }

    function addMekrleTree1(bytes32 _merkleRoot) public {
        require(msg.sender == owner, 'not owner');
        merkleRoot = _merkleRoot;
    }

    function addMerkleTree2(bytes32 _merkleRoot) public {
        require(msg.sender == owner, 'not owner');
        merkleRoot2 = _merkleRoot;
    }
    function addMerkleTree3(bytes32 _merkleRoot) public {
        require(msg.sender == owner, 'not owner');
        merkleRoot3 = _merkleRoot;
    }

    function addMerkleTree4(bytes32 _merkleRoot) public {
        require(msg.sender == owner, 'not owner');
        merkleRoot4 = _merkleRoot;
    }

    function stopAirdrop(bool _status) public {
        require(msg.sender == owner, 'not owner');
        depositsAllowed = _status;
    }

    function addAllMerkleTreesAndToken(bytes32 _merkleroot1, bytes32 _merkleroot2, bytes32 _merkleroot3, bytes32 _merkleroot4, IERC20 _token) public {
        require(msg.sender == owner, 'not owner');
        merkleRoot = _merkleroot1;
        merkleRoot2 = _merkleroot2;
        merkleRoot3 = _merkleroot3; 
        merkleRoot4 = _merkleroot4;
        token = _token;
    }

    function claim(
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) public {
        require(depositsAllowed == false, 'cannot withdraw yet');
        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(account, amount));
        require(claimed[account] == false, 'account already claimed');
        require(
            MerkleProof.verify(merkleProof, merkleRoot, node),
            "MerkleDistributor: Invalid proof."
        );

        claimed[account] = true;
        require(IERC20(token).transfer(account, amount), 'MerkleDistributor: Transfer failed.');

        emit Claimed(account, amount);
    }


    function claim2(
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) public {
        require(block.number > claim_2_open_block, 'invalid block');
        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(account, amount));
        require(claimed2[account] == false, 'account already claimed');
        require(
            MerkleProof.verify(merkleProof, merkleRoot2, node),
            "MerkleDistributor: Invalid proof."
        );

        claimed2[account] = true;
        require(IERC20(token).transfer(account, amount), 'MerkleDistributor: Transfer failed.');

        emit Claimed2(account, amount);
    }

    function claim3(
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) public {
        require(block.number > claim_3_open_block, 'invalid block');
        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(account, amount));
        require(claimed3[account] == false, 'account already claimed');
        require(
            MerkleProof.verify(merkleProof, merkleRoot3, node),
            "MerkleDistributor: Invalid proof."
        );

        claimed3[account] = true;
        require(IERC20(token).transfer(account, amount), 'MerkleDistributor: Transfer failed.');

        emit Claimed3(account, amount);
    }

    function claim4(
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) public {
        require(block.number > claim_4_open_block, 'invalid block');
        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(account, amount));
        require(claimed4[account] == false, 'account already claimed');
        require(
            MerkleProof.verify(merkleProof, merkleRoot4, node),
            "MerkleDistributor: Invalid proof."
        );

        claimed4[account] = true;
        require(IERC20(token).transfer(account, amount), 'MerkleDistributor: Transfer failed.');

        emit Claimed4(account, amount);
    }

    function emergencyWithdraw(uint256 amount) public {
        require(msg.sender == owner, 'not owner');
        IERC20(token).transfer(owner, amount);
    }


    function emergencyWithdrawOldToken(uint256 amount) public {
        require(msg.sender == owner, 'not owner');
        IERC20(oldtoken).transfer(owner, amount);
    }
}