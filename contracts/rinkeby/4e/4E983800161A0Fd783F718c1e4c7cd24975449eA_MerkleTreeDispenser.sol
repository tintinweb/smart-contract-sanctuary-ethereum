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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/MerkleProof.sol)

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
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }
        return computedHash;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IMint.sol";
import "../interfaces/IAutoStakeFor.sol";
import "../interfaces/IVeXBF.sol";
import "../interfaces/IBonusCampaign.sol";

contract MerkleTreeDispenser is Pausable, Ownable {

    mapping(uint256 => PoolInfo) public pools;
    mapping(address => mapping(uint256 => UserInfo)) public users;

    uint256 public poolCount;
    address public tokenAddress;
    address public bonusCampaign;
    address public vsr;
    address public vexbf;

    uint256 private pauseDuration;
    uint256 private lastPauseBlock;

    uint256 public constant WEEK = 7 * 86400; 


    struct PoolInfo {
        uint256 totalNumberOfBlocks;
        uint256 startBlock;
        bytes32 merkleRoot;
    }

    struct UserInfo {
        uint256 assigned;
        uint256 payed;
        uint256 lastBlock;
        uint256 lastPaused;
        bool lockVested;
    }

    event NewPool(uint256 totalAmount);
    event NewUser(address account, uint256 poolId, uint256 totalUserAmount);

    constructor(
        address _tokenAddress,
        address _bonusCampaign,
        address _vsr,
        address _vexbf
    ) {
        require(_tokenAddress != address(0), "token address is zero");
        tokenAddress = _tokenAddress;
        bonusCampaign = _bonusCampaign;
        vsr = _vsr;
        vexbf = _vexbf;
    }

    function addPool(
        uint256 _totalNumberOfBlocks,
        bytes32 _merkleRoot
    )
        external
        onlyOwner
        whenNotPaused
    {
        require(_totalNumberOfBlocks > 0, "incorrect duration");
        pools[poolCount++] = PoolInfo(
            _totalNumberOfBlocks,
            block.number,
            _merkleRoot
        );
        emit NewPool(_totalNumberOfBlocks);
    }

    function pause() external onlyOwner {
        lastPauseBlock = block.number;
        _pause();
    }

    function unpause() external onlyOwner {
        pauseDuration += block.number - lastPauseBlock;
        _unpause();
    }

    /**
    * @notice Claims available XBF for the user proportional to time passed from 
    * the beginning for the first time, if valid Merkle proof was provided
    */
    function claim(
        uint256 _poolId,
        uint256 _totalUserAmount,
        bytes32[] memory _proof,
        bool _lock
    ) external whenNotPaused {
        require(users[_msgSender()][_poolId].lastBlock == 0, "already registered");
        PoolInfo memory pool = pools[_poolId];
        require(MerkleProof.verify(
            _proof,
            pool.merkleRoot,
            keccak256(abi.encodePacked(_msgSender(), _totalUserAmount))
        ), "incorrect proof");
        uint256 currentPauseDuration = pauseDuration;
        (uint256 toPay, ) = _calculateReward(currentPauseDuration, UserInfo(_totalUserAmount, 0, pool.startBlock, 1, _lock), pool);
        users[_msgSender()][_poolId] = UserInfo(_totalUserAmount, toPay, block.number, currentPauseDuration, _lock);
        uint256 maxtime = IVeXBF(vexbf).MAXTIME();
        address bonusCampaign_ = bonusCampaign;

        uint256 startTime = IBonusCampaign(bonusCampaign_).startMintTime();
        uint256 endCampaignTime = startTime + maxtime;
        if (_lock && block.timestamp < endCampaignTime) {
            IMint(tokenAddress).mint(address(this), toPay);
            _lockForUser(_msgSender(), toPay);
            if(!IBonusCampaign(bonusCampaign_).registered(_msgSender())) {
              IBonusCampaign(bonusCampaign_).registerFor(_msgSender());
            }
        } else {
            IMint(tokenAddress).mint(_msgSender(), toPay);
        }
        emit NewUser(_msgSender(), _poolId, _totalUserAmount);
    }

    function claim(uint256 _poolId) external whenNotPaused {
        UserInfo memory user = users[_msgSender()][_poolId];
        require(user.lastBlock != 0, "not registered");
        PoolInfo memory pool = pools[_poolId];
        require(user.payed < user.assigned, "already payed");
        uint256 currentPauseDuration = pauseDuration;
        (uint256 toPay, uint256 finishBlock) = _calculateReward(currentPauseDuration, user, pool);
        if (block.number < finishBlock) users[_msgSender()][_poolId].lastPaused = currentPauseDuration;
        users[_msgSender()][_poolId].payed += toPay;
        users[_msgSender()][_poolId].lastBlock = block.number;
        address bonusCampaign_ = bonusCampaign;

        uint256 maxtime = IVeXBF(vexbf).MAXTIME();
        uint256 startTime = IBonusCampaign(bonusCampaign_).startMintTime();
        uint256 endCampaignTime = startTime + maxtime;
        if(user.lockVested && block.timestamp < endCampaignTime) {
            IMint(tokenAddress).mint(address(this), toPay);
            _lockForUser(_msgSender(), toPay);
        } else {
            IMint(tokenAddress).mint(_msgSender(), toPay);
        }
    }

    function pendingReward(uint256 _poolId, address _account) external view returns(uint256) {
        UserInfo memory user = users[_account][_poolId];
        PoolInfo memory pool = pools[_poolId];
        uint256 currentPauseDuration = pauseDuration;
        (uint256 reward, ) = _calculateReward(currentPauseDuration, user, pool);
        return reward;
    }

    function pendingReward(uint256 _poolId, uint256 _totalUserAmount) external view returns(uint256) {
        PoolInfo memory pool = pools[_poolId];
        uint256 currentPauseDuration = pauseDuration;
        (uint256 reward, ) = _calculateReward(currentPauseDuration, UserInfo(_totalUserAmount, 0, pool.startBlock, 1, false), pool);
        return reward;
    }

    function _calculateReward(
        uint256 _currentPauseDuration,
        UserInfo memory _user,
        PoolInfo memory _pool
    )
        internal
        view
        returns(
            uint256 toPay,
            uint256 finishBlock
        )
    {
        finishBlock = _pool.startBlock + _pool.totalNumberOfBlocks + _currentPauseDuration;
        if (block.number >= finishBlock) {
            toPay = _user.assigned - _user.payed;
        } else {
            toPay = _user.assigned * (block.number - _user.lastBlock - _currentPauseDuration + _user.lastPaused) / _pool.totalNumberOfBlocks;
        }

    }

    function _lockForUser(
        address _user,
        uint256 _amount
    )
        internal
    {
        address vsr_ = vsr;
        address vexbf_ = vexbf;
        address tokenAddress_ = tokenAddress;
        address sender = _msgSender();
        IERC20(tokenAddress_).approve(vsr_, 0);
        IERC20(tokenAddress_).approve(vsr_, _amount);
        IAutoStakeFor(vsr_).stakeFor(sender, _amount);
        IVeXBF vexbf__ = IVeXBF(vexbf_);
        // if user has no lock yet, a lock will be created (createLockFor)
        // if user already has a lock, a lock will updated (increaseAmountFor and increaseUnlockTimeFor)
        // if user has an expired lock, he/she will have to withdraw first (VeXBF.withdraw)
        uint256 maxtime = vexbf__.MAXTIME();
        uint256 startTime = IBonusCampaign(bonusCampaign).startMintTime();
        uint256 endCampaignTime = startTime + maxtime;
        if (vexbf__.lockedAmount(sender) == 0) {
            vexbf__.createLockFor(sender, _amount, block.timestamp + maxtime);
        } else {
            vexbf__.increaseAmountFor(sender, _amount);
            if (vexbf__.lockedEnd(sender) < endCampaignTime / WEEK * WEEK) vexbf__.increaseUnlockTimeFor(sender, endCampaignTime);
        }
        
        
    }




}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IAutoStakeFor {
    function stakeFor(address _for, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IBonusCampaign {
    function bonusEmission() external view returns(uint256);
    function startMintTime() external view returns(uint256);
    function rewardsDuration() external view returns(uint256);
    function stopRegisterTime() external view returns(uint256);
    function registered(address) external view returns(bool);
    function registerFor(address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IMint {
    function mint(address account, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IVeXBF {
    function createLockFor(address addr, uint256 amount, uint256 lockEnd) external;

    function depositFor(address _addr, uint256 _value) external;

    function increaseAmountFor(address _account, uint256 _value) external;

    function increaseUnlockTimeFor(address _account, uint256 _unlockTime) external;

    function getLastUserSlope(address addr) external view returns (int128);

    function lockedEnd(address addr) external view returns (uint256);

    function lockedAmount(address addr) external view returns (uint256);

    function userPointEpoch(address addr) external view returns (uint256);

    function userPointHistoryTs(address addr, uint256 epoch)
        external
        view
        returns (uint256);

    function balanceOfAt(address addr, uint256 _block)
        external
        view
        returns (uint256);

    function balanceOf(address addr) external view returns (uint256);

    function balanceOf(address addr, uint256 timestamp)
        external
        view
        returns (uint256);

    function totalSupply() external view returns (uint256);

    function lockedSupply() external view returns (uint256);

    function lockStarts(address addr) external view returns (uint256);

    function totalSupplyAt(uint256 _block) external view returns (uint256);

    function MAXTIME() external view returns (uint256);
}