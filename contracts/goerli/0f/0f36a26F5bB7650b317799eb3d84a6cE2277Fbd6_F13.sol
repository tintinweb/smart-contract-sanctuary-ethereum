// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.8;

import "./SoliditySprint2022.sol";

contract F13 {
    SoliditySprint2022 Sprint =
        SoliditySprint2022(0xc8612f5E2C8dd4bb4a4EbC4A58A045348f2BE9F8);
    uint256 private x = 0;

    function callSprint() public {
        Sprint.f14(msg.sender);
    }

    fallback() external payable {
        x = 1;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./Clones.sol";
import "./Cryptography.sol";
import "./MerkleTree.sol";
import "./Create2Contract.sol";

interface ISupportsInterface {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

contract SoliditySprint2022 is Ownable {
    bool public live;
    bool public timeExtended = false;

    mapping(address => uint256) public scores;
    mapping(address => mapping(uint256 => bool)) public progress;

    mapping(address => uint256) public entryCount;
    mapping(address => bool) public signers;
    mapping(uint256 => uint256) public solves;
    mapping(bytes32 => bool) public usedLeaves;

    mapping(address => uint256) public totallyLegitMapping;

    Create2Contract public template;
    uint256 salt = 0;

    address public immutable weth;
    bytes32 public immutable merkleRoot;

    uint256 public startTime;

    event registration(address indexed teamAddr, string name);

    constructor(address _weth) {
        template = new Create2Contract();
        weth = _weth;

        bytes32[] memory numbers = new bytes32[](20);
        for (uint256 x = 0; x < 20; x++) {
            numbers[x] = bytes32(keccak256(abi.encodePacked(x)));
        }

        merkleRoot = MerkleTree.getRoot(numbers);
    }

    function start() public onlyOwner {
        startTime = block.timestamp;
        live = true;
    }

    function stop() public onlyOwner {
        live = false;
    }

    function extendTime() public onlyOwner {
        timeExtended = true;
    }

    modifier isLive() {
        require(live);

        if (timeExtended) {
            require(block.timestamp < startTime + 3 hours);
        } else {
            require(block.timestamp < startTime + 2 hours);
        }
        _;
    }

    function registerTeam(string memory team) public isLive {
        emit registration(msg.sender, team);
    }

    function givePoints(
        uint256 challengeNum,
        address team,
        uint256 points
    ) internal {
        progress[team][challengeNum] = true;

        if (challengeNum != 23) {
            scores[team] += (points - solves[challengeNum]);
        }
        solves[challengeNum]++;
    }

    function f0(bool val) public isLive {
        uint256 fNum = 0;
        require(!progress[msg.sender][fNum]);

        require(!val);

        givePoints(fNum, msg.sender, 200);
    }

    function f1() public payable isLive {
        uint256 fNum = 1;

        require(!progress[msg.sender][fNum]);

        require(msg.value == 10 wei);
        givePoints(fNum, msg.sender, 400);
    }

    function f2(uint256 val) public isLive {
        uint256 fNum = 2;
        require(!progress[msg.sender][fNum]);

        uint256 guess = uint256(keccak256(abi.encodePacked(val, msg.sender)));

        require(guess % 5 == 0);

        givePoints(fNum, msg.sender, 600);
    }

    function f3(uint256 data) public isLive {
        uint256 fNum = 3;
        uint256 xorData = data ^ 0x987654321;

        require(!progress[msg.sender][fNum]);

        require(xorData == 0xbeefdead);
        givePoints(fNum, msg.sender, 800);
    }

    function f4(address destAddr) public isLive {
        uint256 fNum = 4;
        require(!progress[msg.sender][fNum]);

        require(destAddr == address(this));
        givePoints(fNum, msg.sender, 1000);
    }

    function f5(address destAddr) public isLive {
        uint256 fNum = 5;
        require(!progress[msg.sender][fNum]);

        require(destAddr == msg.sender);

        givePoints(fNum, msg.sender, 1200);
    }

    function f6(address destAddr) public isLive {
        uint256 fNum = 6;
        require(!progress[msg.sender][fNum]);

        require(destAddr == owner());

        givePoints(fNum, msg.sender, 1400);
    }

    function f7() public isLive {
        uint256 fNum = 7;
        require(!progress[msg.sender][fNum]);

        require(gasleft() > 6_969_420);

        givePoints(fNum, msg.sender, 1600);
    }

    function f8(bytes calldata data) public isLive {
        uint256 fNum = 8;
        require(!progress[msg.sender][fNum]);

        require(data.length == 32);

        givePoints(fNum, msg.sender, 1800);
    }

    function f9(bytes memory data) public isLive {
        uint256 fNum = 9;

        require(!progress[msg.sender][fNum]);

        data = abi.encodePacked(msg.sig, data);
        require(data.length == 32);

        givePoints(fNum, msg.sender, 2000);
    }

    function f10(int256 num1, int256 num2) public isLive {
        uint256 fNum = 10;
        require(!progress[msg.sender][fNum]);

        require(num1 < 0 && num2 > 0);
        unchecked {
            int256 num3 = num1 - num2;
            require(num3 > 10);
        }

        givePoints(fNum, msg.sender, 2200);
    }

    function f11(int256 num1, int256 num2) public isLive {
        uint256 fNum = 11;
        require(!progress[msg.sender][fNum]);

        require(num1 > 0 && num2 > 0, "Numbers must be greater than zero");
        unchecked {
            int256 num3 = num1 + num2;
            require(num3 < -10);
        }

        givePoints(fNum, msg.sender, 2400);
    }

    function f12(bytes memory data) public isLive {
        uint256 fNum = 12;

        require(!progress[msg.sender][fNum]);

        (bool success, bytes memory returnData) = address(this).call(data);
        require(success);

        require(keccak256(returnData) == keccak256(abi.encode(0xdeadbeef)));

        givePoints(fNum, msg.sender, 2600);
    }

    function f13(address team) public isLive {
        uint256 fNum = 13;

        require(!progress[team][fNum]);

        // require(msg.sender.code.length == 0, "No contracts this time!");
        require(msg.sender != tx.origin);

        if (entryCount[team] == 0) {
            entryCount[team]++;
            (bool sent, ) = msg.sender.call("");
            require(sent);
        }

        givePoints(fNum, team, 2800);
    }

    function f14(address team) public isLive {
        uint256 fNum = 14;

        require(!progress[team][fNum]);

        require(msg.sender.code.length == 0);
        require(msg.sender != tx.origin);

        if (entryCount[team] == 0) {
            entryCount[team]++;
            (bool sent, ) = msg.sender.call("");
            require(sent);
        }

        givePoints(fNum, team, 3000);
    }

    function f15(
        address team,
        address expectedSigner,
        bytes memory signature
    ) external isLive {
        uint256 fNum = 15;

        require(!progress[team][fNum]);

        bytes32 digest = keccak256(
            "I don't like sand. It's course and rough and it gets everywhere"
        );

        address signer = Cryptography.recover(digest, signature);

        require(signer != address(0));

        require(signer == expectedSigner);
        require(!signers[signer]);

        signers[signer] = true;
        givePoints(fNum, team, 3200);
    }

    function f16(address team) public isLive {
        uint256 fNum = 16;
        require(!progress[team][fNum]);

        require(
            ISupportsInterface(msg.sender).supportsInterface(
                type(IERC20).interfaceId
            ),
            "msg sender does not support interface"
        );

        givePoints(fNum, team, 3400);
    }

    function f17(address newContract, address team) public isLive {
        uint256 fNum = 17;
        require(!progress[team][fNum]);

        address clone = Clones.cloneDeterministic(
            address(template),
            keccak256(abi.encode(msg.sender))
        );
        require(newContract == clone);

        givePoints(fNum, team, 3600);
    }

    function f18(address team) public isLive {
        uint256 fNum = 18;
        require(!progress[team][fNum]);

        require(IERC20(weth).balanceOf(msg.sender) > 1e9 wei);

        givePoints(fNum, team, 3800);
    }

    function f19(address team) public isLive {
        uint256 fNum = 19;
        require(!progress[team][fNum]);

        IERC20(weth).transferFrom(msg.sender, address(this), 1e9 wei);

        givePoints(fNum, team, 4000);
    }

    function f20(
        address team,
        bytes32[] calldata proof,
        bytes32 leaf
    ) public isLive {
        uint256 fNum = 20;
        require(!progress[team][fNum]);
        require(!usedLeaves[leaf]);

        require(MerkleProof.verify(proof, merkleRoot, leaf));

        usedLeaves[leaf] = true;

        givePoints(fNum, team, 4200);
    }

    function f21(address team, uint256 value) public isLive {
        uint256 fNum = 21;

        require(!progress[team][fNum]);

        uint256 result;

        assembly {
            mstore(0, team)
            mstore(32, 1)
            let hash := keccak256(0, 64)
            result := sload(hash)
        }

        require(result == value);

        givePoints(fNum, team, 4400);
    }

    function f22(
        address team,
        bytes calldata data,
        bytes32 hashSlingingSlasher
    ) public isLive {
        uint256 fNum = 22;
        require(!progress[team][fNum]);

        bytes32 hashData = keccak256(data);
        address sender = msg.sender;

        assembly {
            let size := extcodesize(sender)
            if eq(size, 0) {
                revert(0, 0)
            }

            if eq(sender, origin()) {
                revert(0, 0)
            }

            if gt(xor(hashData, hashSlingingSlasher), 0) {
                revert(0, 0)
            }

            extcodecopy(sender, 0, 0, size)
            let exthash := keccak256(0, size)

            if gt(xor(exthash, hashData), 0) {
                revert(0, 0)
            }
        }

        givePoints(fNum, team, 4600);
    }

    function f23(address team, uint256 value) public isLive {
        uint256 fNum = 23;
        require(!progress[team][fNum]);

        assembly {
            mstore(0, team)
            mstore(32, 1)
            let hash := keccak256(0, 64)
            let result := sload(hash)

            mstore(0, team)
            mstore(32, 1)
            hash := keccak256(0, 64)
            sstore(hash, value)

            mstore(0, team)
            mstore(32, 1)
            hash := keccak256(0, 64)
            let result3 := sload(hash)

            if gt(xor(result3, add(result, add(mul(23, 200), 200))), 0) {
                revert(0, 0)
            }
        }

        givePoints(fNum, team, 4800);
    }

    function internalChallengeHook() public view isLive returns (uint256) {
        require(msg.sender == address(this));
        return 0xdeadbeef;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

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

pragma solidity ^0.8.9;

library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }
}

pragma solidity ^0.8.9;

library Cryptography {
    function recover(bytes32 hash, bytes memory sig) internal pure returns (address) {
            bytes32 r;
            bytes32 s;
            uint8 v;

            //Check the signature length
            if (sig.length != 65) {
            return (address(0));
            }

            // Divide the signature in r, s and v variables
            assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
            }

            // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
            if (v < 27) {
            v += 27;
            }

            // If the version is correct return the signer address
            if (v != 27 && v != 28) {
                return (address(0));
            } else {
                return ecrecover(hash, v, r, s);
            }
        }
}

pragma solidity ^0.8.9;

library MerkleTree {

    function hashLeafPairs(bytes32 left, bytes32 right) internal pure returns (bytes32 _hash) {
       assembly {
           switch lt(left, right)
           case 0 {
               mstore(0x0, right)
               mstore(0x20, left)
           }
           default {
               mstore(0x0, left)
               mstore(0x20, right)
           }
           _hash := keccak256(0x0, 0x40)
       }
    }

    function getRoot(bytes32[] memory data) public pure returns (bytes32) {
        require(data.length > 1, "won't generate root for single leaf");
        while(data.length > 1) {
            data = hashLevel(data);
        }
        return data[0];
    }

     ///@dev function is private to prevent unsafe data from being passed
    function hashLevel(bytes32[] memory data) private pure returns (bytes32[] memory) {
        bytes32[] memory result;

        // Function is private, and all internal callers check that data.length >=2.
        // Underflow is not possible as lowest possible value for data/result index is 1
        // overflow should be safe as length is / 2 always. 
        unchecked {
            uint256 length = data.length;
            if (length & 0x1 == 1){
                result = new bytes32[](length / 2 + 1);
                result[result.length - 1] = hashLeafPairs(data[length - 1], bytes32(0));
            } else {
                result = new bytes32[](length / 2);
        }
        // pos is upper bounded by data.length / 2, so safe even if array is at max size
            uint256 pos = 0;
            for (uint256 i = 0; i < length-1; i+=2){
                result[pos] = hashLeafPairs(data[i], data[i+1]);
                ++pos;
            }
        }
        return result;
    }

}

pragma solidity ^0.8.9;

contract Create2Contract {
    bytes public constant getRekt = "bet you can't guess my address before im even deployed";
    constructor() {

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