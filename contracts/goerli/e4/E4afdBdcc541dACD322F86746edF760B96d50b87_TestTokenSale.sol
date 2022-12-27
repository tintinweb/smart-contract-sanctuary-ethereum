// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import { ERC721Sale } from "../core/ERC721Sale.sol";

// NOTE: Testnet での動作確認を目的とするコントラクト
contract TestTokenSale is ERC721Sale {
    constructor(address newMintAddress) ERC721Sale(newMintAddress) {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import { IERC721Core } from "./interfaces/IERC721Core.sol";
import { SaleRoles } from "./SaleRoles.sol";

contract ERC721Sale is SaleRoles {
    struct SecretSaleData {
        bytes32 merkleRoot;
        uint256 totalSupply;
        uint256 maxSupply;
        mapping(address => uint256) issuedAmountPerAddress;
        bool isSale;
    }

    struct SaleData {
        mapping(address => uint256) issuedAmountPerAddress;
        uint256 maxAmountPerAddress;
        bool isSale;
    }

    SecretSaleData private _freeSecretSaleData;
    SecretSaleData private _preSecretSaleData;
    SaleData private _publicSaleData;
    address private _earningAddress;
    address private _mintAddress;
    uint256 private _prePrice;
    uint256 private _publicPrice;

    /*------------------------------------------------
     * ERC721Sale
     *----------------------------------------------*/

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "caller is another contract"); // solhint-disable-line avoid-tx-origin
        _;
    }

    event FreeMintData(bytes32 merkleRoot, uint256 maxSupply, bool isSale);

    event PreMintData(
        bytes32 merkleRoot,
        uint256 maxSupply,
        uint256 price,
        bool isSale
    );

    event PublicMintData(
        uint256 maxAmountPerAddress,
        uint256 price,
        bool isSale
    );

    event MintAddress(
        address indexed previousAddress,
        address indexed newAddress
    );

    event EarningAddress(
        address indexed previousAddress,
        address indexed newAddress
    );

    event Withdraw(address indexed recipient, uint256 sendValue);

    constructor(address newMintAddress) {
        _setMintAddress(newMintAddress);
    }

    /*------------------------------------------------
     * Free Mint
     *----------------------------------------------*/

    function freeMint(
        bytes32[] calldata proof,
        uint256 amount,
        uint256 maxAmountPerAddress
    ) external callerIsUser whenNotPaused {
        require(_freeSecretSaleData.isSale == true, "not sale");
        require(
            (_freeSecretSaleData.issuedAmountPerAddress[msg.sender] + amount) <=
                maxAmountPerAddress,
            "over amount by address"
        );
        require(
            (_freeSecretSaleData.totalSupply + amount) <=
                _freeSecretSaleData.maxSupply,
            "over amount by total"
        );
        bytes32 leaf = keccak256(
            abi.encodePacked(msg.sender, maxAmountPerAddress)
        );
        require(
            MerkleProof.verify(proof, _freeSecretSaleData.merkleRoot, leaf),
            "invalid proof"
        );

        _freeSecretSaleData.issuedAmountPerAddress[msg.sender] += amount;
        _freeSecretSaleData.totalSupply += amount;

        IERC721Core erc721CoreMint = IERC721Core(_mintAddress);
        erc721CoreMint.mint(msg.sender, amount);
    }

    function setFreeMintData(
        bytes32 newMerkleRoot,
        uint256 newMaxSupply,
        bool newSale
    ) external onlyOperator {
        _freeSecretSaleData.merkleRoot = newMerkleRoot;
        _freeSecretSaleData.maxSupply = newMaxSupply;
        _freeSecretSaleData.isSale = newSale;
        emitFreeMintData();
    }

    function setFreeMintMerkleRoot(bytes32 newMerkleRoot)
        external
        onlyOperator
    {
        _freeSecretSaleData.merkleRoot = newMerkleRoot;
        emitFreeMintData();
    }

    function setFreeMintMaxSupply(uint256 newMaxSupply) external onlyOperator {
        _freeSecretSaleData.maxSupply = newMaxSupply;
        emitFreeMintData();
    }

    function setFreeMintSale(bool newSale) external onlyOperator {
        _freeSecretSaleData.isSale = newSale;
        emitFreeMintData();
    }

    function freeMintData()
        external
        view
        returns (
            bytes32,
            uint256,
            uint256,
            bool
        )
    {
        return (
            _freeSecretSaleData.merkleRoot,
            _freeSecretSaleData.totalSupply,
            _freeSecretSaleData.maxSupply,
            _freeSecretSaleData.isSale
        );
    }

    function freeMintIssuedAmountOf(address minter)
        external
        view
        returns (uint256)
    {
        return _freeSecretSaleData.issuedAmountPerAddress[minter];
    }

    function freeMintRemainAmountOf(address minter, uint256 maxAmountPerAddress)
        external
        view
        returns (uint256)
    {
        require(_freeSecretSaleData.isSale == true, "not sale");
        require(
            _freeSecretSaleData.issuedAmountPerAddress[minter] <
                maxAmountPerAddress,
            "address reached the max"
        );
        require(
            _freeSecretSaleData.totalSupply < _freeSecretSaleData.maxSupply,
            "total reached the max"
        );

        IERC721Core erc721Core = IERC721Core(_mintAddress);
        uint256 remainSupply = erc721Core.remainSupply();
        require(0 < remainSupply, "core reached the max");

        uint256 remainByAddress = maxAmountPerAddress -
            _freeSecretSaleData.issuedAmountPerAddress[minter];
        uint256 remainByTotal = _freeSecretSaleData.maxSupply -
            _freeSecretSaleData.totalSupply;
        if (
            (remainSupply < remainByTotal) && (remainSupply < remainByAddress)
        ) {
            return remainSupply;
        }
        return
            remainByTotal < remainByAddress ? remainByTotal : remainByAddress;
    }

    function emitFreeMintData() internal {
        emit FreeMintData(
            _freeSecretSaleData.merkleRoot,
            _freeSecretSaleData.maxSupply,
            _freeSecretSaleData.isSale
        );
    }

    /*------------------------------------------------
     * Pre Mint
     *----------------------------------------------*/

    function preMint(
        bytes32[] calldata proof,
        uint256 amount,
        uint256 maxAmountPerAddress
    ) external payable callerIsUser whenNotPaused {
        require(_preSecretSaleData.isSale == true, "not sale");
        require(
            (_preSecretSaleData.issuedAmountPerAddress[msg.sender] + amount) <=
                maxAmountPerAddress,
            "over amount by address"
        );
        require(
            (_preSecretSaleData.totalSupply + amount) <=
                _preSecretSaleData.maxSupply,
            "over amount by total"
        );
        require((_prePrice * amount) <= msg.value, "not enough value");
        bytes32 leaf = keccak256(
            abi.encodePacked(msg.sender, maxAmountPerAddress)
        );
        require(
            MerkleProof.verify(proof, _preSecretSaleData.merkleRoot, leaf),
            "invalid proof"
        );

        if ((_earningAddress != address(0)) && (0 < msg.value)) {
            (bool success, ) = _earningAddress.call{ value: msg.value }(""); // solhint-disable-line avoid-low-level-calls
            require(success, "failed to withdraw");
        }

        _preSecretSaleData.issuedAmountPerAddress[msg.sender] += amount;
        _preSecretSaleData.totalSupply += amount;

        IERC721Core erc721Core = IERC721Core(_mintAddress);
        erc721Core.mint(msg.sender, amount);
    }

    function setPreMintData(
        bytes32 newMerkleRoot,
        uint256 newMaxSupply,
        uint256 newPrice,
        bool newSale
    ) external onlyOperator {
        _preSecretSaleData.merkleRoot = newMerkleRoot;
        _preSecretSaleData.maxSupply = newMaxSupply;
        _prePrice = newPrice;
        _preSecretSaleData.isSale = newSale;
        emitPreMintData();
    }

    function setPreMintMerkleRoot(bytes32 newMerkleRoot) external onlyOperator {
        _preSecretSaleData.merkleRoot = newMerkleRoot;
        emitPreMintData();
    }

    function setPreMintMaxSupply(uint256 newMaxSupply) external onlyOperator {
        _preSecretSaleData.maxSupply = newMaxSupply;
        emitPreMintData();
    }

    function setPreMintPrice(uint256 newPrice) external onlyOperator {
        _prePrice = newPrice;
        emitPreMintData();
    }

    function setPreMintSale(bool newSale) external onlyOperator {
        _preSecretSaleData.isSale = newSale;
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
            bool
        )
    {
        return (
            _preSecretSaleData.merkleRoot,
            _preSecretSaleData.totalSupply,
            _preSecretSaleData.maxSupply,
            _prePrice,
            _preSecretSaleData.isSale
        );
    }

    function preMintIssuedAmountOf(address minter)
        external
        view
        returns (uint256)
    {
        return _preSecretSaleData.issuedAmountPerAddress[minter];
    }

    function preMintRemainAmountOf(address minter, uint256 maxAmountPerAddress)
        external
        view
        returns (uint256)
    {
        require(_preSecretSaleData.isSale == true, "not sale");
        require(
            _preSecretSaleData.issuedAmountPerAddress[minter] <
                maxAmountPerAddress,
            "address reached the max"
        );
        require(
            _preSecretSaleData.totalSupply < _preSecretSaleData.maxSupply,
            "total reached the max"
        );

        IERC721Core erc721Core = IERC721Core(_mintAddress);
        uint256 remainSupply = erc721Core.remainSupply();
        require(0 < remainSupply, "core reached the max");

        uint256 remainByAddress = maxAmountPerAddress -
            _preSecretSaleData.issuedAmountPerAddress[minter];
        uint256 remainByTotal = _preSecretSaleData.maxSupply -
            _preSecretSaleData.totalSupply;
        if (
            (remainSupply < remainByTotal) && (remainSupply < remainByAddress)
        ) {
            return remainSupply;
        }
        return
            remainByTotal < remainByAddress ? remainByTotal : remainByAddress;
    }

    function emitPreMintData() internal {
        emit PreMintData(
            _preSecretSaleData.merkleRoot,
            _preSecretSaleData.maxSupply,
            _prePrice,
            _preSecretSaleData.isSale
        );
    }

    /*------------------------------------------------
     * Public Mint
     *----------------------------------------------*/

    function publicMint(uint256 amount)
        external
        payable
        callerIsUser
        whenNotPaused
    {
        require(_publicSaleData.isSale == true, "not sale");
        require(
            (_publicSaleData.issuedAmountPerAddress[msg.sender] + amount) <=
                _publicSaleData.maxAmountPerAddress,
            "over amount by address"
        );
        require((_publicPrice * amount) <= msg.value, "not enough value");

        if ((_earningAddress != address(0)) && (0 < msg.value)) {
            (bool success, ) = _earningAddress.call{ value: msg.value }(""); // solhint-disable-line avoid-low-level-calls
            require(success, "failed to withdraw");
        }

        _publicSaleData.issuedAmountPerAddress[msg.sender] += amount;

        IERC721Core erc721Core = IERC721Core(_mintAddress);
        erc721Core.mint(msg.sender, amount);
    }

    function setPublicMintData(
        uint256 newMaxAmountPerAddress,
        uint256 newPrice,
        bool newSale
    ) external onlyOperator {
        _publicSaleData.maxAmountPerAddress = newMaxAmountPerAddress;
        _publicPrice = newPrice;
        _publicSaleData.isSale = newSale;
        emitPublicMintData();
    }

    function setPublicMintMaxAmountPerAddress(uint256 newMaxAmountPerAddress)
        external
        onlyOperator
    {
        _publicSaleData.maxAmountPerAddress = newMaxAmountPerAddress;
        emitPublicMintData();
    }

    function setPublicMintPrice(uint256 newPrice) external onlyOperator {
        _publicPrice = newPrice;
        emitPublicMintData();
    }

    function setPublicMintSale(bool newSale) external onlyOperator {
        _publicSaleData.isSale = newSale;
        emitPublicMintData();
    }

    function publicMintData()
        external
        view
        returns (
            uint256,
            uint256,
            bool
        )
    {
        return (
            _publicSaleData.maxAmountPerAddress,
            _publicPrice,
            _publicSaleData.isSale
        );
    }

    function publicMintIssuedAmountOf(address minter)
        external
        view
        returns (uint256)
    {
        return _publicSaleData.issuedAmountPerAddress[minter];
    }

    function publicMintRemainAmountOf(address minter)
        external
        view
        returns (uint256)
    {
        require(_publicSaleData.isSale == true, "not sale");
        require(
            _publicSaleData.issuedAmountPerAddress[minter] <
                _publicSaleData.maxAmountPerAddress,
            "address reached the max"
        );

        IERC721Core erc721Core = IERC721Core(_mintAddress);
        uint256 remainSupply = erc721Core.remainSupply();
        require(0 < remainSupply, "core reached the max");

        uint256 remainByAddress = _publicSaleData.maxAmountPerAddress -
            _publicSaleData.issuedAmountPerAddress[minter];
        return remainSupply < remainByAddress ? remainSupply : remainByAddress;
    }

    function emitPublicMintData() internal {
        emit PublicMintData(
            _publicSaleData.maxAmountPerAddress,
            _publicPrice,
            _publicSaleData.isSale
        );
    }

    /*------------------------------------------------
     * Other external
     *----------------------------------------------*/

    function coreSupplies()
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        IERC721Core erc721Core = IERC721Core(_mintAddress);
        return erc721Core.supplies();
    }

    function mintAddress() external view returns (address) {
        return _mintAddress;
    }

    function setMintAddress(address newMintAddress) external onlyOperator {
        _setMintAddress(newMintAddress);
    }

    function earningAddress() external view returns (address) {
        return _earningAddress;
    }

    function setEarningAddress(address newEarningAddress)
        external
        onlyFinancial
    {
        _setEarningAddress(newEarningAddress);
    }

    function withdraw() external onlyFinancial {
        require(_earningAddress != address(0), "invalid earning address");
        uint256 sendValue = address(this).balance;
        require(0 < sendValue, "empty balance");

        (bool success, ) = _earningAddress.call{ value: sendValue }(""); // solhint-disable-line avoid-low-level-calls
        require(success, "failed to withdraw");
        emit Withdraw(_earningAddress, sendValue);
    }

    /*------------------------------------------------
     * Other internal
     *----------------------------------------------*/

    function _setMintAddress(address newMintAddress) internal {
        address previousMintAddress = _mintAddress;
        _mintAddress = newMintAddress;
        emit MintAddress(previousMintAddress, _mintAddress);
    }

    function _setEarningAddress(address newEarningAddress) internal {
        address previousEarningAddress = _earningAddress;
        _earningAddress = newEarningAddress;
        emit EarningAddress(previousEarningAddress, _earningAddress);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import { Pausable } from "@openzeppelin/contracts/security/Pausable.sol";
import { AdminRole } from "./roles/AdminRole.sol";
import { FinancialRole } from "./roles/FinancialRole.sol";
import { OperatorRole } from "./roles/OperatorRole.sol";

contract SaleRoles is Pausable, AdminRole, OperatorRole, FinancialRole {
    function transferAdmin(address newAdmin) external virtual onlyAdmin {
        _transferAdmin(newAdmin);
    }

    function transferOperator(address newOperator) external virtual onlyAdmin {
        _transferOperator(newOperator);
    }

    function transferFinancial(address newFinancial)
        external
        virtual
        onlyAdmin
    {
        _transferFinancial(newFinancial);
    }

    function pause() external onlyOperator {
        _pause();
    }

    function unpause() external onlyOperator {
        _unpause();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface IERC721Core {
    function mint(address to, uint256 amount) external;

    function totalSupply() external view returns (uint256);

    function maxSupply() external view returns (uint256);

    function remainSupply() external view returns (uint256);

    function supplies()
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );
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

contract AdminRole {
    address private _admin;

    event AdminTransferred(
        address indexed previousAdmin,
        address indexed newAdmin
    );

    constructor() {
        _transferAdmin(msg.sender);
    }

    modifier onlyAdmin() {
        require(admin() == msg.sender, "caller is not the admin");
        _;
    }

    function admin() public view virtual returns (address) {
        return _admin;
    }

    function _transferAdmin(address newAdmin) internal virtual {
        require(newAdmin != address(0), "invalid address");
        require(newAdmin != _admin, "not change admin");
        address oldAdmin = _admin;
        _admin = newAdmin;
        emit AdminTransferred(oldAdmin, _admin);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract FinancialRole {
    address private _financial;

    event FinancialTransferred(
        address indexed previousFinancial,
        address indexed newFinancial
    );

    constructor() {
        _transferFinancial(msg.sender);
    }

    modifier onlyFinancial() {
        require(financial() == msg.sender, "caller is not the financial");
        _;
    }

    function financial() public view virtual returns (address) {
        return _financial;
    }

    function _transferFinancial(address newFinancial) internal virtual {
        require(newFinancial != address(0), "invalid address");
        require(newFinancial != _financial, "not change financial");
        address oldFinancial = _financial;
        _financial = newFinancial;
        emit FinancialTransferred(oldFinancial, _financial);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract OperatorRole {
    address private _operator;

    event OperatorTransferred(
        address indexed previousOperator,
        address indexed newOperator
    );

    constructor() {
        _transferOperator(msg.sender);
    }

    modifier onlyOperator() {
        require(operator() == msg.sender, "caller is not the operator");
        _;
    }

    function operator() public view virtual returns (address) {
        return _operator;
    }

    function _transferOperator(address newOperator) internal virtual {
        require(newOperator != address(0), "invalid address");
        require(newOperator != _operator, "not change operator");
        address oldOperator = _operator;
        _operator = newOperator;
        emit OperatorTransferred(oldOperator, _operator);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

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
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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