// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
//  _ __   ___ _   _ _ __ ___  _ __   __| | __ _  ___
// | '_ \ / _ \ | | | '__/ _ \| '_ \ / _` |/ _` |/ _ \
// | | | |  __/ |_| | | | (_) | | | | (_| | (_| | (_) |
// |_| |_|\___|\__,_|_|  \___/|_| |_|\__,_|\__,_|\___/
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract NROSale is Ownable, ReentrancyGuard {
    uint256 public constant totalTokenAmount = 1E7 ether;
    uint256 public maxCommitTokenAmountPerWallet = 1E3 ether;
    uint256 public minCommitTokenAmount = 1E2 ether; //單次購買最小數量，待確認
    //whitelist
    uint256 public constant whitelistSalePrice = 0.05 ether;
    //public sale
    uint256 public constant publicSalePrice = 0.06 ether;
    // used to validate whitelists
    bytes32 public whitelistMerkleRoot;
    // set time
    uint64 public immutable whitelistStartTime = 1648274400;
    uint64 public immutable whitelistEndTime = 1748310400;

    uint64 public immutable publicStartTime = 1648360800;
    uint64 public immutable publicEndTime = 1748396800;

    mapping(address => uint256) public tokenCommitted;
    mapping(address => uint256) public tokenBought;
    mapping(address => uint256) public tokenUnclaim;
    mapping(address => uint256) public tokenClaimed;
    uint256 public tokenSoldAmount;
    IERC20 public paymentToken;

    address saleTokenAddress;
    address paymentTokenAddress;
    address withdrawAddress;

    constructor() {}

    modifier isValidMerkleProof(bytes32[] calldata merkleProof, bytes32 root) {
        require(
            MerkleProof.verify(
                merkleProof,
                root,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Address does not exist in list"
        );
        _;
    }
    modifier checkWhitelistTime() {
        require(
            block.timestamp >= uint256(whitelistStartTime) &&
                block.timestamp <= uint256(whitelistEndTime),
            "Outside whitelist sale round hours"
        );
        _;
    }
    modifier checkPublicTime() {
        require(
            block.timestamp >= uint256(publicStartTime) &&
                block.timestamp <= uint256(publicEndTime),
            "Outside public sale round hours"
        );
        _;
    }
    modifier checkSender() {
        require(msg.sender == tx.origin, "Sender must be EOA");
        _;
    }

    modifier checkMinCommitAmount(uint256 amount) {
        require(
            amount >= minCommitTokenAmount,
            "Commit amount must greater than minCommitTokenAmount"
        );
        _;
    }

    function commitWhitelist(uint256 amount, bytes32[] calldata merkleProof)
        public
        isValidMerkleProof(merkleProof, whitelistMerkleRoot)
        checkWhitelistTime
        checkSender
        checkMinCommitAmount(amount)
        nonReentrant
    {
        require(
            tokenCommitted[msg.sender] + amount <=
                maxCommitTokenAmountPerWallet,
            "already exceed max buy amount by this wallet"
        );
        uint256 numberOfTokens = (amount / whitelistSalePrice) * 1 ether;
        uint256 ts = tokenSoldAmount;
        require(
            ts + numberOfTokens <= totalTokenAmount,
            "Purchase would exceed max token amount"
        );
        paymentToken.transferFrom(address(msg.sender), address(this), amount);
        tokenCommitted[msg.sender] += amount;
        tokenBought[msg.sender] += numberOfTokens;
        tokenUnclaim[msg.sender] += numberOfTokens;
        tokenSoldAmount += numberOfTokens;
    }

    function commitPublic(uint256 amount)
        public
        checkPublicTime
        checkSender
        checkMinCommitAmount(amount)
        nonReentrant
    {
        require(
            tokenCommitted[msg.sender] + amount <=
                maxCommitTokenAmountPerWallet,
            "already exceed max buy amount by this wallet"
        );
        uint256 numberOfTokens = (amount / publicSalePrice) * 1 ether;
        uint256 ts = tokenSoldAmount;
        require(
            ts + numberOfTokens <= totalTokenAmount,
            "Purchase would exceed max token amount"
        );
        paymentToken.transferFrom(address(msg.sender), address(this), amount);
        tokenCommitted[msg.sender] += amount;
        tokenBought[msg.sender] += numberOfTokens;
        tokenUnclaim[msg.sender] += numberOfTokens;
        tokenSoldAmount += numberOfTokens;
    }

    function withdraw() public {
        uint256 claimableToken = getClaimableAmount(msg.sender);
        require(claimableToken > 0, "Nothing to claim");
        tokenClaimed[msg.sender] += claimableToken;
        tokenUnclaim[msg.sender] -= claimableToken;
        IERC20 _token = IERC20(saleTokenAddress);
        _token.transfer(msg.sender, claimableToken);
    }

    function getClaimableAmount(address sender)
        public
        view
        returns (uint256 claimableAmout)
    {
        uint256 base = (tokenBought[sender] * 30) / 100;
        uint256 ts = (block.timestamp - uint256(publicEndTime)) / (30 days);
        if (ts >= 10) {
            claimableAmout = tokenBought[sender] - tokenClaimed[sender];
        } else {
            claimableAmout =
                base +
                ((tokenBought[sender] * ts * 7) / 100) -
                tokenClaimed[sender];
        }
    }

    function adminWithdraw() public {
        require(msg.sender == withdrawAddress, "not withdrawAddress");
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function adminWithdrawTokens() public {
        require(msg.sender == withdrawAddress, "not withdrawAddress");
        uint256 balance = paymentToken.balanceOf(address(this));
        paymentToken.transfer(msg.sender, balance);
    }

    function setWhitelistMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        whitelistMerkleRoot = merkleRoot;
    }

    function setSaleTokenAddress(address newAddress) public onlyOwner {
        saleTokenAddress = newAddress;
    }

    function setPaymentTokenAddress(address newAddress) public onlyOwner {
        paymentTokenAddress = newAddress;
        paymentToken = IERC20(newAddress);
    }

    function setWithdrawAddress(address newAddress) public onlyOwner {
        withdrawAddress = newAddress;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

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