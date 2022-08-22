/**
 *Submitted for verification at Etherscan.io on 2022-08-22
*/

pragma solidity ^0.8.10;

// SPDX-License-Identifier: MIT


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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



interface IHasher {
    function hash(uint256[2] memory inputs) external view returns (uint256);
}


interface IVerifier {
    function verifyProof(uint256[2] memory a, uint256[2][2] memory b, uint256[2] memory c, uint256[4] memory input) external view returns (bool);
}

contract Riemann is ReentrancyGuard {
    struct TreeData {
        uint256 depth;
        uint256 root;
        uint256 count;
        mapping(uint256 => uint256) zeroes;
        mapping(uint256 => uint256[2]) lastSubtrees;
    }

    TreeData private _treeData;
    IVerifier private _verifier;
    IHasher private _hasher;

    uint256 public constant MIN_DENOMINATION = 1e16;
    uint8 public constant MAX_DEPTH = 32;
    uint256 public constant MAX_VALUE = 21888242871839275222246405745257275088548364400416034343698204186575808495617;

    mapping(uint256 => bool) public commitments;
    mapping(uint256 => bool) public nullifierHashes;

    event Deposit(uint256 commitment, address sender);
    event Withdraw(uint256 nullifierHash, address recipient, address relayer, uint256 fee);
    event Split(uint256 nullifierHash, uint256 commitment);

    constructor(IHasher hasher, IVerifier verifier, uint256 depth, uint256 zero) {
        _hasher = hasher;
        _verifier = verifier;

        _initTree(depth, zero);
    }

    function deposit(uint256 commitment) external payable nonReentrant {
        require(!commitments[commitment], "commitment invalid!");
        require(msg.value >= MIN_DENOMINATION, "denomination invalid!");

        _insertLeaf(commitment);
        commitments[commitment] = true;

        emit Deposit(commitment, msg.sender);
    }

    function withdraw(
        uint256[8] calldata proof,
        uint256 root,
        uint256 nullifierHash,
        uint256 message,
        uint256 signalHash,
        address payable recipient,
        uint256 amount,
        address payable relayer,
        uint256 fee
    ) external nonReentrant {
        require(amount > fee, "amount invalid!");
        require(!nullifierHashes[nullifierHash], "nullifierHash invalid!");
        require(uint256(keccak256(abi.encode(recipient, amount, relayer, fee))) >> 8 == message, "message invalid");
        require(_verifyProof(proof, root, nullifierHash, message, signalHash), "proof invalid");

        nullifierHashes[nullifierHash] = true;

        _sendNative(recipient, amount - fee);
        if (fee > 0) {
            _sendNative(relayer, fee);
        }

        emit Withdraw(nullifierHash, recipient, relayer, fee);
    }

    function split(
        uint256[8] calldata proof,
        uint256 root,
        uint256 nullifierHash,
        uint256 message,
        uint256 signalHash,
        uint256[] calldata _commitments
    ) external nonReentrant {
        require(!nullifierHashes[nullifierHash], "nullifierHash invalid!");

        uint256 length = _commitments.length;
        require(length >= 2 && length <= 20, "commitments invalid");

        require(uint256(keccak256(abi.encode(_commitments))) >> 8 == message, "message invalid");
        require(_verifyProof(proof, root, nullifierHash, message, signalHash), "proof invalid");

        nullifierHashes[nullifierHash] = true;

        for(uint256 i = 0; i < length; i++) {
            uint256 commitment = _commitments[i];
            require(!commitments[commitment], "commitment invalid!");
            _insertLeaf(commitment);
            commitments[commitment] = true;

            emit Split(nullifierHash, commitment);
        }
    }

    function _initTree(uint256 depth, uint256 zero) private {
        require(zero < MAX_VALUE, "leaf must be < MAX_VALUE");
        require(depth > 0 && depth <= MAX_DEPTH, "tree depth must be between 1 and 32");

        _treeData.depth = depth;

        for (uint8 i = 0; i < depth; ) {
            _treeData.zeroes[i] = zero;
            zero = _hasher.hash([zero, zero]);

            unchecked {
                ++i;
            }
        }

        _treeData.root = zero;
    }

    function _insertLeaf(uint256 leaf) private {
        uint256 depth = _treeData.depth;

        require(leaf < MAX_VALUE, "leaf must be < MAX_VALUE");
        require(_treeData.count < 2**depth, "tree is full");

        uint256 index = _treeData.count;
        uint256 hash = leaf;

        for (uint8 i = 0; i < depth; ) {
            if (index & 1 == 0) {
                _treeData.lastSubtrees[i] = [hash, _treeData.zeroes[i]];
            } else {
                _treeData.lastSubtrees[i][1] = hash;
            }

            hash = _hasher.hash(_treeData.lastSubtrees[i]);
            index >>= 1;

            unchecked {
                ++i;
            }
        }

        _treeData.root = hash;
        _treeData.count += 1;
    }

    function _verifyProof(uint256[8] calldata proof, uint256 root, uint256 nullifierHash, uint256 message, uint256 signalHash) private view returns (bool) {
        return _verifier.verifyProof(
            [proof[0], proof[1]],
            [[proof[2], proof[3]], [proof[4], proof[5]]],
            [proof[6], proof[7]],
            [root, nullifierHash, message, signalHash]
        );
    }

    function _sendNative(address payable to, uint256 value) private {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = to.call{value: value}("");
        require(success, "payment fail");
    }

    function getVerifier() external view returns (IVerifier) {
        return _verifier;
    }

    function getHasher() external view returns (IHasher) {
        return _hasher;
    }

    function getRoot() external view returns (uint256) {
        return _treeData.root;
    }

    function getDepth() external view returns (uint256) {
        return _treeData.depth;
    }

    function getCount() external view returns (uint256) {
        return _treeData.count;
    }
}