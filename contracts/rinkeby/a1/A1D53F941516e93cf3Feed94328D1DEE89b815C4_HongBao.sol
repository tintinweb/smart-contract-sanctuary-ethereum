// SPDX-License-Identifier: MIT
// Creator: Xing @nelsonie

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract HongBao is Ownable {
    uint64 private constant EXPIRE_DAY = 1 days;

    struct RedEnvelopInfo {
        // Red Envelop information
        address creator;
        address tokenAddr;
        bytes32 merkelRoot;
        uint256 remainMoney;
        uint16 remainCount;
        uint64 expireTime;
        mapping (address => bool) isOpened;
    }
    mapping(uint64 => RedEnvelopInfo) public redEnvelopInfos;

    // Protocal Fee
    uint16 public protocalRatio = 824;
    mapping(address => uint256) public teamProfit;

    constructor() {
    }

    event Create(uint64 indexed envelopId, address indexed creator, uint256 indexed protocalFee, uint256 money);
    event Open(uint64 indexed envelopId, address indexed opener, uint256 money);
    event Drawback(uint64 indexed envelopId, address indexed creator, uint256 money);

    function create(uint64 envelopId, address tokenAddr, uint256 money, uint16 count, bytes32 merkelRoot) external payable {
        require(msg.sender == tx.origin, "Contract not allowed");
        require(redEnvelopInfos[envelopId].creator == address(0), "Duplicate ID");
        require(count > 0, "Invalid count");
        uint256 protocalFee = money / 100000 * protocalRatio;
        require(money - protocalFee >= count, "Invalid money");
        if (tokenAddr != address(0)) {
            require(IERC20(tokenAddr).allowance(msg.sender, address(this)) >= money, "Check Token allowance");
            require(IERC20(tokenAddr).transferFrom(msg.sender, address(this), money), "Transfer Token failed");
        } else {
            require(money == msg.value, "Insufficient ETH");
        }

        teamProfit[tokenAddr] += protocalFee;

        RedEnvelopInfo storage p = redEnvelopInfos[envelopId];
        p.creator = msg.sender;
        p.tokenAddr = tokenAddr;
        p.merkelRoot = merkelRoot;
        p.remainMoney = money - protocalFee;
        p.remainCount = count;
        p.expireTime = uint64(block.timestamp) + EXPIRE_DAY;
        emit Create(envelopId, msg.sender, protocalFee, money);
    }

    function open(uint64 envelopId, bytes32[] calldata proof) external {
        require(msg.sender == tx.origin, "Contract not allowed");
        require(checkOpenAvailability(envelopId, msg.sender, proof) == 0, "You are not allowed");

        uint256 amount = _calculateRandomAmount(redEnvelopInfos[envelopId].remainMoney, redEnvelopInfos[envelopId].remainCount, msg.sender);

        redEnvelopInfos[envelopId].remainMoney -= amount;
        redEnvelopInfos[envelopId].remainCount -= 1;
        redEnvelopInfos[envelopId].isOpened[msg.sender] = true;

        _send(redEnvelopInfos[envelopId].tokenAddr, payable(msg.sender), amount);
        emit Open(envelopId, msg.sender, amount);
    }

    function drawback(uint64 envelopId) external {
        require(msg.sender == tx.origin, "Contract not allowed");
        require(msg.sender == redEnvelopInfos[envelopId].creator, "Not creator");
        require(block.timestamp > redEnvelopInfos[envelopId].expireTime, "Not expired");
        require(redEnvelopInfos[envelopId].remainMoney > 0, "No money left");

        uint256 amount = redEnvelopInfos[envelopId].remainMoney;
        redEnvelopInfos[envelopId].remainMoney = 0;
        redEnvelopInfos[envelopId].remainCount = 0;

        _send(redEnvelopInfos[envelopId].tokenAddr, payable(msg.sender), amount);
        emit Drawback(envelopId, msg.sender, amount);
    }

    function info(uint64 envelopId) external view returns (address, address, bytes32, uint256, uint16, uint64) {
        RedEnvelopInfo storage redEnvelopInfo = redEnvelopInfos[envelopId];
        return (
        redEnvelopInfo.creator,
        redEnvelopInfo.tokenAddr,
        redEnvelopInfo.merkelRoot,
        redEnvelopInfo.remainMoney,
        redEnvelopInfo.remainCount,
        redEnvelopInfo.expireTime);
    }

    function checkOpenAvailability(uint64 envelopId, address sender, bytes32[] calldata proof) public view returns (uint) {
        if (redEnvelopInfos[envelopId].creator == address(0)) {
            return 1;
        }

        if (redEnvelopInfos[envelopId].remainCount == 0) {
            return 2;
        }

        if (redEnvelopInfos[envelopId].isOpened[sender]) {
            return 3;
        }

        if (redEnvelopInfos[envelopId].merkelRoot != "") {
            if (!MerkleProof.verify(proof, redEnvelopInfos[envelopId].merkelRoot, keccak256(abi.encodePacked(sender)))) {
                return 4;
            }
        }

        return 0;
    }

    function _random(uint256 remainMoney, uint remainCount, address sender) private view returns (uint256) {
       return uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, block.number, sender))) % (remainMoney / remainCount * 2) + 1;
    }

    function _calculateRandomAmount(uint256 remainMoney, uint remainCount, address sender) private view returns (uint256) {
        uint256 amount = 0;
        if (remainCount == 1) {
            amount = remainMoney;
        } else if (remainCount == remainMoney) {
            amount = 1;
        } else if (remainCount < remainMoney) {
            amount = _random(remainMoney, remainCount, sender);
        }
        return amount;
    }

    function _send(address tokenAddr, address payable to, uint256 amount) private {
        if (tokenAddr == address(0)) {
            require(to.send(amount), "Transfer ETH failed");
        } else {
            require(IERC20(tokenAddr).transfer(to, amount), "Transfer Token failed");
        }
    }

    // WIN TOGETHER
    /**
        Withdraw protocal fee to a Crepto Team public wallet address
        Crepto Team will convert all profit token to ETH, then transfer ETH to Crepass contract 0x759e689ec7dd42097e40d1f5df558b130a7544a9

        Support set the withdraw address to Crepass contract directly and renounce the ownership in future
     */
    address public creptoPassAddress = 0xdACFF5227793a31e98845DC5a9910D383e59f85D;

    function withdraw(address tokenAddr) external {
        require(creptoPassAddress != address(0), "Set address");
        uint256 profit = teamProfit[tokenAddr];
        require(profit > 0, "Make more profit");

        teamProfit[tokenAddr] = 0;

        _send(tokenAddr, payable(creptoPassAddress), profit);
    }

    function setCreptoPassAddress(address _creptoPassAddress) external onlyOwner {
        creptoPassAddress = _creptoPassAddress;
    }

    /**
        Protocal Fee can be lower in future and can't exceed 0.824%
     */
    function setProtocalRatio(uint16 _protocalRatio) external onlyOwner {
        require(_protocalRatio <= 824, "Exceed 824");
        protocalRatio = _protocalRatio;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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

// SPDX-License-Identifier: MIT
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