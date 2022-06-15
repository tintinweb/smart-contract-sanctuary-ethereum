/**
 *Submitted for verification at Etherscan.io on 2022-06-14
*/

/*
 __          __    _      __  __                               _         
 \ \        / /   | |    |  \/  |                             (_)        
  \ \  /\  / /___ | |__  | \  / |  __ _  ___   ___   _ __      _   ___   
   \ \/  \/ // _ \| '_ \ | |\/| | / _` |/ __| / _ \ | '_ \    | | / _ \  
    \  /\  /|  __/| |_) || |  | || (_| |\__ \| (_) || | | | _ | || (_) | 
     \/  \/  \___||_.__/ |_|  |_| \__,_||___/ \___/ |_| |_|(_)|_| \___/  
                                                                         
                             www.WebMason.io                             
                                                                         
*/

// Dependency file: @openzeppelin/contracts/utils/cryptography/MerkleProof.sol

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/cryptography/MerkleProof.sol)

// pragma solidity ^0.8.0;

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


// Dependency file: @openzeppelin/contracts/utils/Context.sol

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

// pragma solidity ^0.8.0;

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


// Dependency file: @openzeppelin/contracts/access/Ownable.sol

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

// pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/utils/Context.sol";

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


// Dependency file: @openzeppelin/contracts/token/ERC20/IERC20.sol

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

// pragma solidity ^0.8.0;

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


// Dependency file: contracts/interfaces/IRecoverable.sol

// pragma solidity ^0.8.0;

interface IRecoverable {
    event RecoveredFunds(
        address indexed token,
        uint256 amount,
        address indexed recipient
    );

    function recoverFunds(
        address token,
        uint256 amount,
        address recipient
    ) external returns (bool);
}


// Dependency file: contracts/utils/Recoverable.sol

// pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";
// import "contracts/interfaces/IRecoverable.sol";

/**
 @dev The contract is intendent to help recovering arbitrary ERC20 tokens and ETH accidentally transferred to the contract address
 */
abstract contract Recoverable is Ownable, IRecoverable {
    function _getRecoverableAmount(address token)
        internal
        view
        virtual
        returns (uint256)
    {
        if (token == address(0)) return address(this).balance;
        else return IERC20(token).balanceOf(address(this));
    }

    /**
     @param token ERC20 token's address to recover or address(0) to recover ETH
     @param amount to recover from contract's address
     @param recipient address to receive tokens from the contract
     */
    function recoverFunds(
        address token,
        uint256 amount,
        address recipient
    ) external override onlyOwner returns (bool) {
        uint256 recoverableAmount = _getRecoverableAmount(token);
        require(
            amount <= recoverableAmount,
            "Recoverable: RECOVERABLE_AMOUNT_NOT_ENOUGH"
        );
        if (token == address(0)) _transferEth(amount, recipient);
        else _transferErc20(token, amount, recipient);
        emit RecoveredFunds(token, amount, recipient);
        return true;
    }

    function _transferEth(uint256 amount, address recipient) private {
        address payable toPayable = payable(recipient);
        toPayable.transfer(amount);
    }

    function _transferErc20(
        address token,
        uint256 amount,
        address recipient
    ) private {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, recipient, amount)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "Recoverable: TRANSFER_FAILED"
        );
    }
}


// Dependency file: contracts/interfaces/IVesting.sol

// pragma solidity ^0.8.0;

interface IVesting {
    struct VestingEntry {
        uint96 amount;
        uint64 start;
        uint32 lockup;
        uint32 cliff;
        uint32 vesting;
    }

    event AirdropperUpdated(address indexed account, bool status);
    event Airdrop(address indexed account, uint96 amount);
    event VestingEntryUpdated(
        address indexed account,
        uint96 amount,
        uint64 start,
        uint32 lockup,
        uint32 cliff,
        uint32 vesting
    );

    function vestingOf(address account)
        external
        view
        returns (
            uint64 start,
            uint32 lockup,
            uint32 cliff,
            uint32 vesting,
            uint96 balance,
            uint96 vested,
            uint96 locked,
            uint96 unlocked
        );

    function airdrop(
        uint32 lockup,
        uint32 cliff,
        uint32 vesting,
        address account,
        uint96 amount
    ) external returns (bool);

    function airdropBatch(
        uint32 lockup,
        uint32 cliff,
        uint32 vesting,
        address[] memory accounts,
        uint96[] memory amounts
    ) external returns (bool);
}


// Root file: contracts/WebMasonCoinOpenSeaAirdrop.sol

pragma solidity 0.8.14;

// import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "contracts/utils/Recoverable.sol";
// import "contracts/interfaces/IVesting.sol";

/// @custom:security-contact [email protected]
contract WebMasonCoinOpenSeaAirdrop is Ownable, Recoverable {
    address public immutable WMC;

    // WMC vesting parameters
    uint256 private _initTime;
    uint256 public vestingStart = 1669852800; // 2022-12-01T00:00:00.000Z
    uint32 private constant _vesting = 5 * 12 * 30 * 24 * 60 * 60; // 60mo = 5y

    // Airdrop
    bytes32 public merkleRoot;
    uint256 public airdropEndTime;

    mapping(address => bool) public claimed;
    event AirdropClaimed(address indexed account, uint256 amount);

    constructor(address token_) {
        _initTime = block.timestamp;
        WMC = token_;
    }

    // Airdrop
    function claim(
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external {
        require(!claimed[account], "Already claimed");
        require(
            _verify(_leaf(account, amount), merkleProof),
            "MerkleDistributor: Invalid  merkle proof"
        );

        claimed[account] = true;
        emit AirdropClaimed(account, amount);

        (uint64 tStart, , , uint32 tVesting, , , , ) = IVesting(WMC).vestingOf(
            account
        );
        uint256 endTime = vestingStart + _vesting;

        if (block.timestamp >= endTime) {
            // If the vesting has already ended, then we do an airdrop without vesting.
            IVesting(WMC).airdrop(0, 0, 0, account, uint96(amount));
            return;
        }

        if (tStart == 0) {
            // If vesting is not set.
            if (vestingStart >= block.timestamp) {
                // If time is less than vestingStart. Then we set up a new vesting.
                IVesting(WMC).airdrop(
                    uint32(vestingStart - block.timestamp),
                    0,
                    _vesting,
                    account,
                    uint96(amount)
                );
                return;
            }
            if (vestingStart < block.timestamp) {
                // If time is greater than vestingStart.
                // We increase the vested amount or set vesting.
                uint256 remainingTime = 0;
                uint256 locked = 0;

                // Recalculate and set the vesting.
                remainingTime = endTime - block.timestamp;
                locked = (amount * remainingTime) / _vesting;
                // Set vesting
                IVesting(WMC).airdrop(
                    0,
                    0,
                    uint32(remainingTime),
                    account,
                    uint96(locked)
                );

                // Airdrop of unlocked amount
                IVesting(WMC).airdrop(
                    0,
                    0,
                    0,
                    account,
                    uint96(amount - locked)
                );
                return;
            }
        } else {
            /**
             * If vesting is set.
             * Option 1. tVesting is 5 years. The vesting was set before the tokens were unlocked.
             * Then we add the quantity to the old quantity. Tokens will be unlocked automatically.
             * Option 2. tVesting less than 5 years. The vesting was set after the tokens were unlocked.
             * Then we airdrop the unlocked amount and add the remaining amount.
             */
            uint256 locked = amount;
            if (tVesting < _vesting) {
                uint256 unlocked = (amount * (_vesting - tVesting)) / _vesting;
                locked = amount - unlocked;
                // Airdrop of unlocked amount.
                IVesting(WMC).airdrop(0, 0, 0, account, uint96(unlocked));
            }
            // Add the remaining amount.
            IVesting(WMC).airdrop(0, 0, 1, account, uint96(locked));
            return;
        }
    }

    function _leaf(address account, uint256 amount)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(account, amount));
    }

    function _verify(bytes32 leaf, bytes32[] memory merkleProof)
        internal
        view
        returns (bool)
    {
        return MerkleProof.verify(merkleProof, merkleRoot, leaf);
    }

    function setRoot(bytes32 merkleRoot_, uint256 duration) external onlyOwner {
        merkleRoot = merkleRoot_;
        airdropEndTime = block.timestamp + duration;
    }

    function claim_rest_of_tokens_and_selfdestruct() external onlyOwner {
        require(block.timestamp >= airdropEndTime, "Too early");
        require(
            IERC20(WMC).transfer(owner(), IERC20(WMC).balanceOf(address(this)))
        );
        selfdestruct(payable(owner()));
    }

    // Vesting
    function setVestingStart(uint256 newTime) external onlyOwner {
        require(
            newTime < vestingStart && newTime >= _initTime,
            "The new time must be less than the old vesting start time"
        );
        vestingStart = newTime;
    }

    // Extra
    function _getRecoverableAmount(address token)
        internal
        view
        override
        returns (uint256)
    {
        if (token == WMC) return 0;
        else if (token == address(0)) return address(this).balance;
        else return IERC20(token).balanceOf(address(this));
    }
}