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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address sender,
        address recipient,
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract MerkleProof {
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf,
        uint256 index
    ) public pure returns (bool) {
        bytes32 hash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (index % 2 == 0) {
                hash = keccak256(abi.encodePacked(hash, proofElement));
            } else {
                hash = keccak256(abi.encodePacked(proofElement, hash));
            }
            index = index / 2;
        }
        return hash == root;
    }
}

contract MerkleBridge is Ownable, MerkleProof {
    IERC20 public token;
    address public oracle;
    uint256 public immutable CHAIN_ID;

    uint256 public startTimestamp;
    uint256 public epochSize = 5 minutes;

    mapping(uint256 => bytes32[]) public transactionHashes;
    mapping(uint256 => mapping(uint256 => bytes32)) public roots;
    mapping(address => mapping(uint256 => Transaction[])) public transactions;

    mapping(address => uint256) public nonces;

    mapping(bytes32 => bool) public isWithdrawProceed;
    mapping(uint256 => mapping(uint256 => bool)) public isRootFilled;

    mapping(uint256 => bool) public allowedChainIds;

    event Deposit(
        uint256 indexed timestamp,
        address indexed user,
        address to,
        uint256 amount,
        uint256 chainId
    );
    event Withdraw(
        uint256 indexed timestamp,
        address indexed user,
        address from,
        address to,
        uint256 amount,
        uint256 chainId,
        bytes32 transactionHash
    );

    event AddRoot(
        uint256 indexed timestamp,
        address indexed user,
        uint256 chainId,
        uint256 epoch,
        bytes32 value
    );

    event SetChainIdAllow(
        uint256 indexed timestamp,
        address indexed user,
        uint256 chainId,
        bool allow
    );
    event ChangedOracle(
        uint256 indexed timestamp,
        address indexed user,
        address newOracle
    );
    event ChangedToken(uint256 indexed timestamp, address indexed user, IERC20 newToken);
    event WithdrawERC20(
        uint256 indexed timestamp,
        address indexed user,
        IERC20 token,
        uint256 amount
    );

    struct Root {
        bytes32 value;
        uint256 chainId;
        uint256 epoch;
    }
    struct Transaction {
        address from;
        address to;
        uint256 amount;
        uint256 nonce;
        uint256 chainId;
        uint256 index;
        uint256 epoch;
        uint256 timestamp;
    }

    modifier onlyOracle() {
        require(msg.sender == oracle, 'Only oracle can call this function');
        _;
    }

    constructor(IERC20 token_, address oracle_) {
        token = token_;
        oracle = oracle_;

        CHAIN_ID = block.chainid;
        startTimestamp = block.timestamp;
    }

    /// @dev deposits provided amount to chainId and adds to txs
    /// @param to address of target user
    /// @param amount of tokens
    /// @param chainId target chainId
    function deposit(
        address to,
        uint256 amount,
        uint256 chainId
    ) external {
        require(allowedChainIds[chainId], 'chainId is not allowed');

        token.transferFrom(msg.sender, address(this), amount);

        bytes32 transactionHash_ = transactionHash(
            msg.sender,
            to,
            amount,
            nonces[msg.sender],
            chainId
        );
        nonces[msg.sender] += 1;
        uint256 epoch = getEpoch();
        transactionHashes[epoch].push(transactionHash_);

        transactions[msg.sender][epoch].push(
            Transaction({
                from: msg.sender,
                to: to,
                amount: amount,
                nonce: nonces[msg.sender] - 1,
                index: transactionHashes[epoch].length - 1,
                chainId: CHAIN_ID,
                epoch: getEpoch(),
                timestamp: block.timestamp
            })
        );

        emit Deposit(block.timestamp, msg.sender, to, amount, chainId);
    }

    /// @dev withdraws tokens
    /// @param from address of origin user
    /// @param to address of target user
    /// @param amount amount of deposited tokens
    /// @param nonce number of deposit from this user
    /// @param chainId chain id of target chain
    /// @param epoch epoch of root
    /// @param proof array of hashes which proves that you can withdraw
    function withdraw(
        address from,
        address to,
        uint256 amount,
        uint256 nonce,
        uint256 index,
        uint256 chainId,
        uint256 epoch,
        bytes32[] memory proof
    ) external {
        bytes32 transactionHash_ = transactionHash(from, to, amount, nonce, chainId);
        bytes32 root = roots[chainId][epoch];

        require(!isWithdrawProceed[transactionHash_], 'Already withdrawed');
        require(root != 0, 'Root is empty');
        require(verify(proof, root, transactionHash_, index), 'Invalid inputs');

        isWithdrawProceed[transactionHash_] = true;
        token.transfer(to, amount);

        emit Withdraw(
            block.timestamp,
            msg.sender,
            from,
            to,
            amount,
            chainId,
            transactionHash_
        );
    }

    /// @dev returns transactions hashes from epoch
    /// @param epoch epoch
    function getTransactionHashes(uint256 epoch) public view returns (bytes32[] memory) {
        return transactionHashes[epoch];
    }

    /// @dev returns transactions hashes from last epoch
    function getLastTransactionHashes() public view returns (bytes32[] memory) {
        return transactionHashes[getEpoch() - 1];
    }

    /// @dev returns roots
    /// @param last amount of last epochs (if last == 0 returns all epochs)
    function getRootsForLast(uint256 chainId, uint256 last)
        public
        view
        returns (bytes32[] memory)
    {
        uint256 length = getEpoch();
        last = last == 0 ? length : last;

        bytes32[] memory roots_ = new bytes32[](last);
        for (uint256 i = 0; i < last; i++) roots_[i] = roots[chainId][i];

        return roots_;
    }

    struct Info {
        bytes32[] transactionHashes;
        Transaction[] transactions;
        uint256 epoch;
    }

    /// @dev returns info
    /// @param epoch period
    /// @return info_ info about user at epoch
    function getInfo(uint256 epoch) public view returns (Info memory info_) {
        require(epoch != getEpoch(), 'same epoch');
        info_.transactionHashes = transactionHashes[epoch];
        info_.epoch = epoch;
    }

    /// @dev returns info for last epochs
    /// @param last amount of last epochs (if last == 0 returns all epochs)
    function getInfoForLast(uint256 last) public view returns (Info[] memory) {
        uint256 length = getEpoch();
        last = last == 0 ? length : last;

        Info[] memory infos = new Info[](last);
        for (uint256 i = 0; i < last; i++) infos[i] = getInfo(length - (last - i));

        return infos;
    }

    /// @dev returns info about user
    /// @param user address of user
    /// @param epoch period
    /// @return info_ info about user at epoch
    function getUserInfo(address user, uint256 epoch)
        public
        view
        returns (Info memory info_)
    {
        require(epoch != getEpoch(), 'same epoch');
        info_.transactionHashes = transactionHashes[epoch];
        info_.transactions = transactions[user][epoch];
        info_.epoch = epoch;
    }

    /// @dev returns info about user for last epochs
    /// @param user address of user
    /// @param last amount of last epochs (if last == 0 returns all epochs)
    function getUserInfoForLast(address user, uint256 last)
        public
        view
        returns (Info[] memory)
    {
        uint256 length = getEpoch();
        last = last == 0 ? length : last;

        Info[] memory infos = new Info[](last);
        for (uint256 i = 0; i < last; i++)
            infos[i] = getUserInfo(user, length - (last - i));

        return infos;
    }

    function getEpoch() public view returns (uint256) {
        return (block.timestamp - startTimestamp) / epochSize;
    }

    /// @dev packs inforamtion about transaction
    /// @param from address of origin user
    /// @param to address of target user
    /// @param amount amount of deposited tokens
    /// @param nonce number of deposit from this user
    /// @param chainId chain id of target chain
    /// @return hash of packed deposit
    function transactionHash(
        address from,
        address to,
        uint256 amount,
        uint256 nonce,
        uint256 chainId
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(from, to, amount, nonce, chainId));
    }

    /// ORACLE FUNCTIONS

    /// @dev commits roots from another chains
    /// @param roots_ array of roots from another chain
    function commitRoots(Root[] memory roots_) external onlyOracle {
        uint256 length = roots_.length;
        for (uint256 i = 0; i < length; i++) {
            Root memory root = roots_[i];

            if (isRootFilled[root.chainId][root.epoch]) continue;

            isRootFilled[root.chainId][root.epoch] = true;
            roots[root.chainId][root.epoch] = root.value;

            emit AddRoot(
                block.timestamp,
                msg.sender,
                root.chainId,
                root.epoch,
                root.value
            );
        }
    }

    /// @dev commits root from another chain
    /// @param root adding root
    function commitRoot(Root memory root) external onlyOracle {
        require(!isRootFilled[root.chainId][root.epoch], 'Root have been already filled');
        isRootFilled[root.chainId][root.epoch] = true;
        roots[root.chainId][root.epoch] = root.value;
        emit AddRoot(block.timestamp, msg.sender, root.chainId, root.epoch, root.value);
    }

    /// ADMIN FUNCTIONS

    /// @dev sets allowance for other chains
    /// @param chainId of other chain
    /// @param allow boolean flag
    function setChainIdAllowance(uint256 chainId, bool allow) external onlyOwner {
        require(allowedChainIds[chainId] != allow, 'You cant set same allow');
        allowedChainIds[chainId] = allow;
        emit SetChainIdAllow(block.timestamp, msg.sender, chainId, allow);
    }

    /// @dev sets oracle address
    /// @param newOracle address of new oracle
    function setOracle(address newOracle) external onlyOwner {
        require(newOracle != address(0), 'Oracle cant be zero address');
        oracle = newOracle;
        emit ChangedOracle(block.timestamp, msg.sender, newOracle);
    }

    /// @dev sets token address
    /// @param newToken address of new token
    function setToken(IERC20 newToken) external onlyOwner {
        require(address(newToken) != address(0), 'Oracle cant be zero address');
        token = newToken;
        emit ChangedToken(block.timestamp, msg.sender, newToken);
    }

    /// @dev withdraws erc20 from contract
    /// @param token_ address of token
    /// @param amount amount of tokens to withdraw
    function withdrawERC20(IERC20 token_, uint256 amount) external onlyOwner {
        uint256 balance = token_.balanceOf(address(this));
        amount = amount > balance ? balance : amount;
        token_.transfer(msg.sender, amount);
        emit WithdrawERC20(block.timestamp, msg.sender, token_, amount);
    }
}