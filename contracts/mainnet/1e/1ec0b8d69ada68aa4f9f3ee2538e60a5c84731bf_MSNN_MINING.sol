/**
 *Submitted for verification at Etherscan.io on 2022-03-26
*/

// SPDX-License-Identifier: GPL v3

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


contract MSNN_MINING {
    uint256 public payable_amount;

    address private MSNNAddr;
    address private MiningOwner;

    mapping(address => string) private keepers; //keeper account can add add_merkle_root
    mapping(bytes32 => uint256) private merkleRoots; // merkleRoot=>balance
    mapping(bytes32 => mapping(uint256 => bool)) private claimed; //bytes32 merkleRoot => (index => true|false)

    mapping(address => uint256) private acc_staking;

    constructor(address _MSNNcontractAddr) {
        MiningOwner = msg.sender;
        MSNNAddr = _MSNNcontractAddr;
        keepers[msg.sender] = "MiningOwner";
    }

    modifier onlyMiningOwner() {
        require(msg.sender == MiningOwner, "only MiningOwner");
        _;
    }

    event set_MiningOwner_EVENT(
        address trigger_user_addr,
        address oldOwner,
        address newOwner,
        uint256 blocktime
    );

    function set_MiningOwner(address _newOwner) external onlyMiningOwner {
        require(
            _newOwner != MiningOwner,
            "The new owner must be different from the old"
        );
        address oldMiningOwner = MiningOwner;
        delete keepers[oldMiningOwner];
        MiningOwner = _newOwner;
        keepers[_newOwner] = "MiningOwner";
        emit set_MiningOwner_EVENT(
            msg.sender,
            oldMiningOwner,
            _newOwner,
            block.timestamp
        );
    }

    function get_MiningOwner() external view returns (address) {
        return MiningOwner;
    }

    function get_msn_addr() public view returns (address) {
        return MSNNAddr;
    }

    function get_contract_balance() public view returns (uint256) {
        return IERC20(MSNNAddr).balanceOf(address(this));
    }

    function get_keeper(address keeper_addr)
        public
        view
        returns (string memory)
    {
        require(bytes(keepers[keeper_addr]).length != 0, "No such a keeper");
        return keepers[keeper_addr];
    }

    event add_keeper_EVENT(
        address trigger_user_addr,
        address keeper_addr,
        string keeper_name,
        uint256 blocktime
    );

    function add_keeper(address keeper_addr, string calldata keeper_name)
        external
        onlyMiningOwner
    {
        require(bytes(keeper_name).length != 0, "No name");
        keepers[keeper_addr] = keeper_name;
        emit add_keeper_EVENT(
            msg.sender,
            keeper_addr,
            keeper_name,
            block.timestamp
        );
    }

    event remove_keeper_EVENT(
        address trigger_user_addr,
        address keeper_addr,
        string keeper_name,
        uint256 blocktime
    );

    function remove_keeper(address keeper_addr) external onlyMiningOwner {
        require(bytes(keepers[keeper_addr]).length != 0, "No such a keeper");
        require(keeper_addr != MiningOwner, "Can not delete MiningOwner");
        string memory keeper_name = keepers[keeper_addr];
        delete keepers[keeper_addr];
        emit remove_keeper_EVENT(
            msg.sender,
            keeper_addr,
            keeper_name,
            block.timestamp
        );
    }

    modifier onlyKeeper() {
        require(bytes(keepers[msg.sender]).length != 0, "No such a keeper");
        _;
    }

    event add_merkle_root_EVENT(
        address trigger_user_addr,
        bytes32 merkleRoot,
        uint256 amount,
        uint256 blocktime
    );

    function set_merkle_root(bytes32 merkleRoot, uint256 amount)
        external
        onlyKeeper
    {
        merkleRoots[merkleRoot] = amount + 1; // +1 for never to 0 again
        emit add_merkle_root_EVENT(
            msg.sender,
            merkleRoot,
            amount,
            block.timestamp
        );
    }

    event remove_merkle_root_EVENT(
        address trigger_user_addr,
        bytes32 merkleRoot,
        uint256 blocktime
    );

    function remove_merkle_root(bytes32 merkleRoot) external onlyMiningOwner {
        delete merkleRoots[merkleRoot];
        emit remove_merkle_root_EVENT(msg.sender, merkleRoot, block.timestamp);
    }

    function get_merkle_balance(bytes32 merkleRoot)
        public
        view
        returns (uint256)
    {
        return merkleRoots[merkleRoot];
    }

    event claim_erc20_EVENT(
        address trigger_user_addr,
        bytes32 merkleRoot,
        uint256 amount,
        uint256 time
    );

    function claim_erc20(
        bytes32 merkleRoot,
        uint256 index,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external {
        require(merkleRoots[merkleRoot] != 0, "The merkleRoot doesn't exist");
        require(claimed[merkleRoot][index] == false, "Already claimed");

        bytes32 leaf = keccak256(abi.encodePacked(index, msg.sender, amount));
        bool verify = MerkleProof.verify(merkleProof, merkleRoot, leaf);
        require(verify == true, "Not verified");

        require(merkleRoots[merkleRoot] > amount, "Not enough balance");
        merkleRoots[merkleRoot] -= amount;

        claimed[merkleRoot][index] = true;
        bool result = IERC20(MSNNAddr).transfer(msg.sender, amount);
        require(result == true, "transfer error");
        emit claim_erc20_EVENT(msg.sender, merkleRoot, amount, block.timestamp);
    }

    function erc20_claimed(bytes32 merkleRoot, uint256 index)
        external
        view
        returns (bool)
    {
        return  claimed[merkleRoot][index];
    }

    event stake_token_EVENT(
        address trigger_user_addr,
        uint256 amount,
        string userid,
        uint256 blocktime
    );

    function stake_token(uint256 amount, string calldata userid) external {
        uint256 allowance = IERC20(MSNNAddr).allowance(
            msg.sender,
            address(this)
        );
        require(allowance > 0, "Not allowed");
        bool t_result = IERC20(MSNNAddr).transferFrom(
            msg.sender,
            address(this),
            amount
        );
        require(t_result == true, "transfer error");
        acc_staking[msg.sender] += amount;
        emit stake_token_EVENT(msg.sender, amount, userid, block.timestamp);
    }

    function get_acc_staking(address addr) public view returns (uint256) {
        return acc_staking[addr];
    }

    receive() external payable {
        payable_amount += msg.value;
    }

    fallback() external payable {
        payable_amount += msg.value;
    }

    event withdraw_eth_EVENT(
        address trigger_user_addr,
        uint256 _amount,
        uint256 blocktime
    );

    function withdraw_eth() external onlyMiningOwner {
        uint256 amout_to_t = address(this).balance;
        payable(msg.sender).transfer(amout_to_t);
        payable_amount = 0;
        emit withdraw_eth_EVENT(msg.sender, amout_to_t, block.timestamp);
    }

    event withdraw_contract_EVENT(
        address trigger_user_addr,
        address _from,
        uint256 amount,
        uint256 blocktime
    );

    function withdraw_contract() public onlyMiningOwner {
        uint256 left = IERC20(MSNNAddr).balanceOf(address(this));
        require(left > 0, "No balance");
        IERC20(MSNNAddr).transfer(msg.sender, left);
        emit withdraw_contract_EVENT(
            msg.sender,
            address(this),
            left,
            block.timestamp
        );
    }
}