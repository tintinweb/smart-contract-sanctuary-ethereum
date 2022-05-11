/**
 *Submitted for verification at Etherscan.io on 2022-05-11
*/

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

// File: @openzeppelin/contracts/utils/Context.sol

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

// File: @openzeppelin/contracts/access/Ownable.sol

pragma solidity ^0.8.0;

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

pragma solidity ^0.8.0;

interface IGame {
    function gameMint(address _to, uint256 _mintAmount) external;
    function isGame(address _to) external view returns (bool);
    function setGame(address _to, bool _state) external;
}

interface IGiveaway {
    function giveawayMint(uint256 _total, bytes32[] calldata _merkleProof, uint256 _mintAmount) external;
    function giveawayMint(address _to, uint256 _total, bytes32[] calldata _merkleProof, uint256 _mintAmount) external;
    function giveawaysOf(address _to, uint256 _total, bytes32[] calldata _merkleProof) external view returns (uint256);
    function setGiveawayRoot(bytes32 _newGiveawayRoot) external;
}

contract MetaverseAtNightHolder is Ownable {

    address public constant HA2 = 0xa50797F0Cb879f3B4D1002EeAe932c203e2f52dF;
    address public constant MANCamels = 0xf5eadd59709837BB5406b59757c9dfa23C1073d5;
    address public constant SP = 0x750858236Bcb2e27e238e16BDC22d1Dd99BF44DE;

    bytes32 public holderRoot = 0xb2b5302e9412d21bcff8524bd7ea95571bcf9e59c2744d5dbbb773b9099cf97c;

    mapping(address => uint256) private _holderCount;

    constructor() {}

    // public
    function giveawayMint(uint256 _total, bytes32[] calldata _merkleProof, uint256 _mintAmount) public {
        giveawayMint(msg.sender, _total, _merkleProof, _mintAmount);
    }

    function giveawayMint(address _to, uint256 _total, bytes32[] calldata _merkleProof, uint256 _mintAmount) public {
        IGiveaway(HA2).giveawayMint(_to, _total, _merkleProof, _mintAmount);

        IGame(MANCamels).gameMint(_to, _mintAmount);
        IGame(SP).gameMint(_to, _mintAmount);
    }

    function holderMint(uint256 _total, bytes32[] calldata _merkleProof, uint256 _mintAmount) public {
        holderMint(msg.sender, _total, _merkleProof, _mintAmount);
    }

    function holderMint(address _to, uint256 _total, bytes32[] calldata _merkleProof, uint256 _mintAmount) public {
        require(_mintAmount > 0, "need to mint at least 1 NFT");
        require(holderCountOf(_to, _total, _merkleProof) >= _mintAmount, "insufficient count remaining");

        _holderCount[_to] += _mintAmount;

        IGame(MANCamels).gameMint(_to, _mintAmount);
        IGame(SP).gameMint(_to, _mintAmount);
    }

    // public view
    function holderCountOf(address _to, uint256 _total, bytes32[] calldata _merkleProof) public view returns (uint256) {
        require(
            _to != address(0),
            "query for the zero address"
        );

        bytes32 leaf = keccak256(abi.encodePacked(_to, _total));
        require(MerkleProof.verify(_merkleProof, holderRoot, leaf), "invalid proof");

        uint256 taken = _holderCount[_to];
        if (taken >= _total) {
            return 0;
        }

        return _total - taken;
    }

    // onlyOwner
    function setHolderRoot(bytes32 _newHolderRoot) public onlyOwner {
        holderRoot = _newHolderRoot;
    }

    function tokenWithdraw(IERC20 token) public onlyOwner {
        uint256 amount = token.balanceOf(address(this));
        bool success = token.transfer(owner(), amount);
        require(success, "failed to withdraw token");
    }

    function withdraw() public onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success, "failed to withdraw");
    }
}