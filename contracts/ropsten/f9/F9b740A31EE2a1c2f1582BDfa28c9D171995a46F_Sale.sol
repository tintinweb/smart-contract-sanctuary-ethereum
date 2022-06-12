// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./lib/ISarugami.sol";

contract Sale is Ownable, ReentrancyGuard {
    bytes32 public merkleRootAlphaTeam = "0x";
    uint256 public maxAlphaTeam = 4;

    bytes32 public merkleRootHeadMods = "0x";
    uint256 public maxHeadMods = 3;

    bytes32 public merkleRootMods = "0x";
    uint256 public maxMods = 2;

    bytes32 public merkleRootHonoraryOg = "0x";
    uint256 public maxHonoraryOg = 2;
    uint256 priceHonoraryOg = 31000000000000000;

    bytes32 public merkleRootOg = "0x";
    uint256 public maxOg = 2;
    uint256 priceOg = 62000000000000000;

    bytes32 public merkleRootWhitelist = "0x";
    uint256 public maxWhitelist = 1;
    uint256 priceWhitelist = 62000000000000000;

    bytes32 public merkleRootRaffle = "0x";
    uint256 public maxRaffle = 1;
    uint256 priceRaffle = 88000000000000000;

    uint256 public startFirstDay = 99999999999;
    uint256 public finishFirstDay = 99999999999;
    uint256 public startSecondDay = 99999999999;
    uint256 public finishSecondDay = 99999999999;
    ISarugami public sarugami;
    mapping(address => uint256) public walletMintCount;
    mapping(address => uint256) public walletMintCountRaffle;

    constructor(
        address sarugamiAddress
    ) {
        sarugami = ISarugami(sarugamiAddress);
    }

    function buy(bytes32[] calldata merkleProof, uint256 group, uint256 amount) public payable nonReentrant {
        require(block.timestamp > startFirstDay , "Sale not open");
        require(block.timestamp < finishSecondDay , "Sale ended");
        require(group > 0 && group <= 7 , "Invalid group");
        require(amount > 0 , "Invalid amount");
        require(isWalletListed(merkleProof, msg.sender, group) == true, "Invalid proof, your wallet isn't listed in any group");

        uint256 price = getPriceForGroup(group, amount);
        require(msg.value == price, "ETH sent does not match Sarugamis value");

        //FIRST DAY ELSE SECOND DAY
        if (block.timestamp > startFirstDay && block.timestamp < finishFirstDay) {
            require(group <= 6, "Today is just for groups: Team, Honorary OGs, OGs and Whitelist");
            require(walletMintCount[msg.sender] + amount <= getMaxAmountForGroup(group), "Max amount reached for this wallet");

            //IF IS THE FIRST HOUR JUST ALPA AND HEAD MOD CAN MINT FOR TESTS
            if(block.timestamp < (startFirstDay + 3600)){
                require(group <= 2, "Alpha team + Head mod is minting now for tests porpouses");
            }

            walletMintCount[msg.sender] += amount;
            sarugami.mint(msg.sender, amount);
        } else {
            require(group > 6 , "You miss the minting date sorry.");
            require(block.timestamp > startSecondDay, "Public sale not open");
            require(walletMintCountRaffle[msg.sender] + amount <= getMaxAmountForGroup(group), "Max 1 per wallet");

            walletMintCountRaffle[msg.sender] += amount;
            sarugami.mint(msg.sender, amount);
        }
    }

    function getMaxAmountForGroup(uint256 group) public view returns (uint256 amount) {
        if (group == 1) {
            return maxAlphaTeam;
        }

        if (group == 2) {
            return maxHeadMods;
        }

        if (group == 3) {
            return maxMods;
        }

        if (group == 4) {
            return maxHonoraryOg;
        }

        if (group == 5) {
            return maxOg;
        }

        if (group == 6) {
            return maxWhitelist;
        }

        if (group == 7) {
            return maxRaffle;
        }

        return 0;
    }

    function getPriceForGroup(uint256 group, uint256 amount) public view returns (uint256 price) {
        if (group == 1) {
            return 0;
        }

        if (group == 2) {
            return 0;
        }

        if (group == 3) {
            return 0;
        }

        if (group == 4) {
            return priceHonoraryOg * amount;
        }

        if (group == 5) {
            return priceOg * amount;
        }

        if (group == 6) {
            return priceWhitelist * amount;
        }

        if (group == 7) {
            return priceRaffle * amount;
        }

        return 1000000000000000000;
    }

    function isWalletListed(
        bytes32[] calldata merkleProof,
        address wallet,
        uint256 group
    ) private view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(wallet));

        if (group == 1) {
            return MerkleProof.verify(merkleProof, merkleRootAlphaTeam, leaf);
        }

        if (group == 2) {
            return MerkleProof.verify(merkleProof, merkleRootHeadMods, leaf);
        }

        if (group == 3) {
            return MerkleProof.verify(merkleProof, merkleRootMods, leaf);
        }

        if (group == 4) {
            return MerkleProof.verify(merkleProof, merkleRootHonoraryOg, leaf);
        }

        if (group == 5) {
            return MerkleProof.verify(merkleProof, merkleRootOg, leaf);
        }

        if (group == 6) {
            return MerkleProof.verify(merkleProof, merkleRootWhitelist, leaf);
        }

        if (group == 7) {
            return MerkleProof.verify(merkleProof, merkleRootRaffle, leaf);
        }

        return false;
    }

    function setStartFirstDay(uint256 timestamp) external onlyOwner {
        startFirstDay = timestamp;
    }

    function setFinishFirstDay(uint256 timestamp) external onlyOwner {
        finishFirstDay = timestamp;
    }

    function setStartSecondDay(uint256 timestamp) external onlyOwner {
        startSecondDay = timestamp;
    }

    function setFinishSecondDay(uint256 timestamp) external onlyOwner {
        finishSecondDay = timestamp;
    }

    function withdrawStuckToken(address recipient, address token) external onlyOwner() {
        IERC20(token).transfer(recipient, IERC20(token).balanceOf(address(this)));
    }

    function removeDustFunds(address treasury) public onlyOwner {
        (bool success,) = treasury.call{value : address(this).balance}("");
        require(success, "funds were not sent properly to treasury");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ISarugami {
    function mint(address, uint256) external returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

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