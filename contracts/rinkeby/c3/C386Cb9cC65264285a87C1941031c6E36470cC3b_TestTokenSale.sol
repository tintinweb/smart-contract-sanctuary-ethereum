// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import { ERC721Sale } from "../core/ERC721Sale.sol";

// NOTE: testnet での動作確認を目的とする contract
contract TestTokenSale is ERC721Sale {
    /* solhint-disable no-empty-blocks */
    constructor(address newMintAddress)
        ERC721Sale(newMintAddress, address(0))
    {}
    /* solhint-enable no-empty-blocks */
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import { OwnerChanger } from "./OwnerChanger.sol";
import { IERC721CoreMint } from "./interfaces/IERC721CoreMint.sol";

contract ERC721Sale is OwnerChanger {
    using SafeMath for uint256;

    struct WhiteListMintData {
        mapping(address => uint256) issuedAmountPerAddress;
        bytes32 merkleRoot;
        uint256 totalSupply;
        uint256 maxSupply;
        uint256 maxAmountPerAddress;
        bool isSale;
    }

    WhiteListMintData private _freeMintData;
    WhiteListMintData private _preMintData;
    address private _mintAddress;
    uint256 private _preMintPrice;
    uint256 private _publicMintPrice;
    bool private _publicMintIsSale;

    event FreeMintData(
        bytes32 merkleRoot,
        uint256 maxSupply,
        uint256 maxAmountPerAddress,
        bool isSale
    );

    event PreMintData(
        bytes32 merkleRoot,
        uint256 maxSupply,
        uint256 maxAmountPerAddress,
        uint256 price,
        bool isSale
    );

    event PublicMintData(uint256 price, bool isSale);

    event MintAddress(
        address indexed previousAddress,
        address indexed newAddress
    );

    event Withdraw(address indexed recipient, uint256 sendValue);

    constructor(address newMintAddress, address newOwnerChanger)
        OwnerChanger(
            newOwnerChanger != address(0) ? newOwnerChanger : _msgSender()
        )
    {
        _setMintAddress(newMintAddress);
    }

    /*------------------------------------------------
     * Free Mint
     *----------------------------------------------*/

    function freeMint(bytes32[] calldata proof, uint256 amount) external {
        require(_freeMintData.isSale == true, "not sale.");
        require(
            (_freeMintData.issuedAmountPerAddress[msg.sender] + amount) <=
                _freeMintData.maxAmountPerAddress,
            "over amount by address."
        );
        require(
            (_freeMintData.totalSupply + amount) <= _freeMintData.maxSupply,
            "over amount by total."
        );
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(proof, _freeMintData.merkleRoot, leaf),
            "Invalid proof"
        );

        _freeMintData.issuedAmountPerAddress[msg.sender] += amount;
        _freeMintData.totalSupply += amount;

        IERC721CoreMint erc721CoreMint = IERC721CoreMint(_mintAddress);
        erc721CoreMint.mint(msg.sender, amount);
    }

    function setFreeMintData(
        bytes32 newMerkleRoot,
        uint256 newMaxSupply,
        uint256 newMaxAmountPerAddress,
        bool newSale
    ) external onlyOwner {
        _freeMintData.merkleRoot = newMerkleRoot;
        _freeMintData.maxSupply = newMaxSupply;
        _freeMintData.maxAmountPerAddress = newMaxAmountPerAddress;
        _freeMintData.isSale = newSale;
        emitFreeMintData();
    }

    function setFreeMintMerkleRoot(bytes32 newMerkleRoot) external onlyOwner {
        _freeMintData.merkleRoot = newMerkleRoot;
        emitFreeMintData();
    }

    function setFreeMintMaxSupply(uint256 newMaxSupply) external onlyOwner {
        _freeMintData.maxSupply = newMaxSupply;
        emitFreeMintData();
    }

    function setFreeMintMaxAmountPerAddress(uint256 newMaxAmountPerAddress)
        external
        onlyOwner
    {
        _freeMintData.maxAmountPerAddress = newMaxAmountPerAddress;
        emitFreeMintData();
    }

    function setFreeMintSale(bool newSale) external onlyOwner {
        _freeMintData.isSale = newSale;
        emitFreeMintData();
    }

    function freeMintData()
        external
        view
        returns (
            bytes32,
            uint256,
            uint256,
            uint256,
            bool
        )
    {
        return (
            _freeMintData.merkleRoot,
            _freeMintData.totalSupply,
            _freeMintData.maxSupply,
            _freeMintData.maxAmountPerAddress,
            _freeMintData.isSale
        );
    }

    function emitFreeMintData() internal {
        emit FreeMintData(
            _freeMintData.merkleRoot,
            _freeMintData.maxSupply,
            _freeMintData.maxAmountPerAddress,
            _freeMintData.isSale
        );
    }

    /*------------------------------------------------
     * Pre Mint
     *----------------------------------------------*/

    function preMint(bytes32[] calldata proof, uint256 amount)
        external
        payable
    {
        require(_preMintData.isSale == true, "not sale.");
        require(
            (_preMintData.issuedAmountPerAddress[msg.sender] + amount) <=
                _preMintData.maxAmountPerAddress,
            "over amount by address."
        );
        require(
            (_preMintData.totalSupply + amount) <= _preMintData.maxSupply,
            "over amount by total."
        );
        require((_preMintPrice * amount) <= msg.value, "not enough value.");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(proof, _preMintData.merkleRoot, leaf),
            "Invalid proof"
        );

        _preMintData.issuedAmountPerAddress[msg.sender] += amount;
        _preMintData.totalSupply += amount;

        IERC721CoreMint erc721CoreMint = IERC721CoreMint(_mintAddress);
        erc721CoreMint.mint(msg.sender, amount);
    }

    function setPreMintData(
        bytes32 newMerkleRoot,
        uint256 newMaxSupply,
        uint256 newMaxAmountPerAddress,
        uint256 newPrice,
        bool newSale
    ) external onlyOwner {
        _preMintData.merkleRoot = newMerkleRoot;
        _preMintData.maxSupply = newMaxSupply;
        _preMintData.maxAmountPerAddress = newMaxAmountPerAddress;
        _preMintPrice = newPrice;
        _preMintData.isSale = newSale;
        emitPreMintData();
    }

    function setPreMintMerkleRoot(bytes32 newMerkleRoot) external onlyOwner {
        _preMintData.merkleRoot = newMerkleRoot;
        emitPreMintData();
    }

    function setPreMintMaxSupply(uint256 newMaxSupply) external onlyOwner {
        _preMintData.maxSupply = newMaxSupply;
        emitPreMintData();
    }

    function setPreMintMaxAmountPerAddress(uint256 newMaxAmountPerAddress)
        external
        onlyOwner
    {
        _preMintData.maxAmountPerAddress = newMaxAmountPerAddress;
        emitPreMintData();
    }

    function setPreMintPrice(uint256 newPrice) external onlyOwner {
        _preMintPrice = newPrice;
        emitPreMintData();
    }

    function setPreMintSale(bool newSale) external onlyOwner {
        _preMintData.isSale = newSale;
        emitPreMintData();
    }

    function preMintData()
        external
        view
        returns (
            bytes32,
            uint256,
            uint256,
            uint256,
            uint256,
            bool
        )
    {
        return (
            _preMintData.merkleRoot,
            _preMintData.totalSupply,
            _preMintData.maxSupply,
            _preMintData.maxAmountPerAddress,
            _preMintPrice,
            _preMintData.isSale
        );
    }

    function emitPreMintData() internal {
        emit PreMintData(
            _preMintData.merkleRoot,
            _preMintData.maxSupply,
            _preMintData.maxAmountPerAddress,
            _preMintPrice,
            _preMintData.isSale
        );
    }

    /*------------------------------------------------
     * Public Mint
     *----------------------------------------------*/

    function publicMint(uint256 amount) external payable {
        require(_publicMintIsSale == true, "not sale.");
        require((_publicMintPrice * amount) <= msg.value, "not enough value.");

        IERC721CoreMint erc721CoreMint = IERC721CoreMint(_mintAddress);
        erc721CoreMint.mint(msg.sender, amount);
    }

    function setPublicMintData(uint256 newPrice, bool newSale)
        external
        onlyOwner
    {
        _publicMintPrice = newPrice;
        _publicMintIsSale = newSale;
        emitPublicMintData();
    }

    function setPublicMintPrice(uint256 newPrice) external onlyOwner {
        _publicMintPrice = newPrice;
        emitPublicMintData();
    }

    function setPublicMintSale(bool newSale) external onlyOwner {
        _publicMintIsSale = newSale;
        emitPublicMintData();
    }

    function publicMintData() external view returns (uint256, bool) {
        return (_publicMintPrice, _publicMintIsSale);
    }

    function emitPublicMintData() internal {
        emit PublicMintData(_publicMintPrice, _publicMintIsSale);
    }

    /*------------------------------------------------
     * Other external
     *----------------------------------------------*/

    function mintAddress() external view returns (address) {
        return _mintAddress;
    }

    function setMintAddress(address newMintAddress) external onlyOwner {
        _setMintAddress(newMintAddress);
    }

    function withdraw(address recipient) external onlyOwner {
        require(recipient != address(0), "invalid recipient");
        uint256 sendValue = address(this).balance;
        (bool success, ) = recipient.call{ value: sendValue }(""); // solhint-disable-line avoid-low-level-calls
        require(success, "failed to withdraw");
        emit Withdraw(recipient, sendValue);
    }

    /*------------------------------------------------
     * Other internal
     *----------------------------------------------*/

    function _setMintAddress(address newMintAddress) internal {
        address previousMintAddress = _mintAddress;
        _mintAddress = newMintAddress;
        emit MintAddress(previousMintAddress, newMintAddress);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
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
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
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
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be proved to be a part of a Merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and the sibling nodes in `proof`,
     * consuming from one or the other at each step according to the instructions given by
     * `proofFlags`.
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract OwnerChanger is Ownable {
    address private _ownerChanger;

    event OwnerChangerTransferred(
        address indexed previousOwnerChanger,
        address indexed newOwnerChanger
    );

    constructor(address newOwnerChanger) {
        _transferOwnerChanger(newOwnerChanger);
    }

    modifier onlyOwnerChanger() {
        require(
            ownerChanger() == _msgSender(),
            "caller is not the owner changer"
        );
        _;
    }

    modifier onlyOwnerOrChanger() {
        address caller = _msgSender();
        require(
            owner() == caller || ownerChanger() == caller,
            "invalid caller"
        );
        _;
    }

    function ownerChanger() public view virtual returns (address) {
        return _ownerChanger;
    }

    function transferOwnership(address newOwner)
        public
        virtual
        override
        onlyOwnerOrChanger
    {
        require(newOwner != address(0), "invalid address");
        _transferOwnership(newOwner);
    }

    function transferOwnerChanger(address newOwnerChanger)
        external
        virtual
        onlyOwnerChanger
    {
        _transferOwnerChanger(newOwnerChanger);
    }

    function _transferOwnerChanger(address newOwnerChanger) internal virtual {
        require(newOwnerChanger != address(0), "invalid address");
        require(newOwnerChanger != _ownerChanger, "not change ownerChanger");
        address oldOwnerChanger = _ownerChanger;
        _ownerChanger = newOwnerChanger;
        emit OwnerChangerTransferred(oldOwnerChanger, newOwnerChanger);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface IERC721CoreMint {
    function mint(address to, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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