// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

enum SaleStage {
    None,
    whitelist,
    publicSale
}

interface NFT {
    function mint(address to) external;
}

contract GabiNFTSale is Ownable, ReentrancyGuard {
    using Strings for uint256;
    using MerkleProof for bytes32[];

    uint256 public whitelistSaleStartTime = 1653111000; // 5/21 1:30pm
    uint256 public whitelistSaleEndTime = whitelistSaleStartTime + 1 days;
    uint256 public whitelistSaleAllocatedQuantity = 120;
    uint256 public publicSaleStartTime = whitelistSaleEndTime + 30 minutes;
    uint256 public publicSaleEndTime = publicSaleStartTime + 1 days;
    uint256 public publicSaleMaxPurchaseAmount = 3;
    uint256 public publicSaleAllocatedQuantity = 0;
    uint256 public maxTotalSoldQuantity =
        publicSaleAllocatedQuantity + whitelistSaleAllocatedQuantity;
    uint256 public mintedQuantity = 0;
    uint256 public whitelistMintPrice = 0.2 ether;
    uint256 public publicSaleMintPrice = 0.24 ether;

    bytes32 private _whitelistMerkleRoot;

    address public GabiNFTAddress;
    mapping(address => bool) public whitelistPurchased;

    constructor(address _GabiNFTAddress) {
        GabiNFTAddress = _GabiNFTAddress;
    }

    /* ************** */
    /* USER FUNCTIONS */
    /* ************** */

    function remainingCount() public view returns (uint256) {
        SaleStage currentStage = getCurrentActiveSaleStage();
        if (currentStage == SaleStage.whitelist) {
            return whitelistSaleAllocatedQuantity - mintedQuantity;
        } else if (currentStage == SaleStage.publicSale) {
            return maxTotalSoldQuantity - mintedQuantity;
        } else {
            return 0;
        }
    }

    // @notice This function returns the current active sale stage
    // @notice 0: NONE, 1: First Whitelist Sale, 2: Public Sale
    function getCurrentActiveSaleStage() public view returns (SaleStage) {
        bool whitelistSaleIsActive = (block.timestamp >
            whitelistSaleStartTime) && (block.timestamp < whitelistSaleEndTime);
        if (whitelistSaleIsActive) {
            return SaleStage.whitelist;
        }
        bool publicSaleIsActive = (block.timestamp > publicSaleStartTime) &&
            (block.timestamp < publicSaleEndTime);
        if (publicSaleIsActive) {
            return SaleStage.publicSale;
        }
        return SaleStage.None;
    }

    function mint(bytes32[] calldata proof, uint256 numberOfTokens)
        external
        payable
        nonReentrant
    {
        require(tx.origin == msg.sender, "contracts not allowed to mint");
        SaleStage currentActiveSaleStage = getCurrentActiveSaleStage();
        require(
            currentActiveSaleStage != SaleStage.None,
            "no active sale right now"
        );
        require(numberOfTokens > 0, "numberOfTokens cannot be 0");
        if (currentActiveSaleStage == SaleStage.whitelist) {
            _mintwhitelist(proof, numberOfTokens);
        } else if (currentActiveSaleStage == SaleStage.publicSale) {
            _mintpublicSale(numberOfTokens);
        }
    }

    function _mintwhitelist(bytes32[] calldata proof, uint256 numberOfTokens)
        internal
    {
        require(
            msg.value == whitelistMintPrice * numberOfTokens,
            "sent ether value incorrect"
        );
        require(!whitelistPurchased[msg.sender], "whitelistPurchased already");
        require(
            proof.verify(
                _whitelistMerkleRoot,
                keccak256(abi.encodePacked(msg.sender, numberOfTokens))
            ),
            "failed to verify first WL merkle root"
        );
        require(numberOfTokens <= remainingCount(), "whitelist sold out");
        whitelistPurchased[msg.sender] = true;
        mintedQuantity += numberOfTokens;
        for (uint256 i = 0; i < numberOfTokens; i++) {
            NFT(GabiNFTAddress).mint(msg.sender);
        }
    }

    function _mintpublicSale(uint256 numberOfTokens) internal {
        require(
            msg.value == publicSaleMintPrice * numberOfTokens,
            "sent ether value incorrect"
        );
        require(numberOfTokens <= remainingCount(), "public sale sold out");
        require(
            numberOfTokens <= publicSaleMaxPurchaseAmount,
            "numberOfTokens exceeds publicSaleMaxPurchaseAmount"
        );

        mintedQuantity += numberOfTokens;
        for (uint256 i = 0; i < numberOfTokens; i++) {
            NFT(GabiNFTAddress).mint(msg.sender);
        }
    }

    /* *************** */
    /* ADMIN FUNCTIONS */
    /* *************** */

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        _whitelistMerkleRoot = _merkleRoot;
    }

    function setSaleData(
        uint256 _whitelistSaleStartTime,
        uint256 _whitelistSaleEndTime,
        uint256 _whitelistSaleAllocatedQuantity,
        uint256 _publicSaleStartTime,
        uint256 _publicSaleEndTime,
        uint256 _publicSaleMaxPurchaseAmount,
        uint256 _publicSaleAllocatedQuantity,
        uint256 _maxTotalSoldQuantity,
        uint256 _whitelistMintPrice,
        uint256 _publicSaleMintPrice
    ) external onlyOwner {
        whitelistSaleStartTime = _whitelistSaleStartTime;
        whitelistSaleEndTime = _whitelistSaleEndTime;
        whitelistSaleAllocatedQuantity = _whitelistSaleAllocatedQuantity;
        publicSaleStartTime = _publicSaleStartTime;
        publicSaleEndTime = _publicSaleEndTime;
        publicSaleMaxPurchaseAmount = _publicSaleMaxPurchaseAmount;
        publicSaleAllocatedQuantity = _publicSaleAllocatedQuantity;
        maxTotalSoldQuantity = _maxTotalSoldQuantity;
        whitelistMintPrice = _whitelistMintPrice;
        publicSaleMintPrice = _publicSaleMintPrice;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

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
     * by making the `nonReentrant` function external, and make it call a
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

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

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