// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interface/ICircuitVerifier.sol";
import "./interface/ILayerZeroUltraLightNodeV1.sol";
import "./Merkle.sol";
// this a test
contract LayerZeroOracle is Ownable,Merkle {
    event MerkleRootRecorded(
        bytes32 parentMerkleRoot,
        bytes32 currentMerkleRoot,
        uint256 blockNumber
    );

    event ModCircuitVerifier(
        address oldCircuitVerifier,
        uint256 oldBatchSize,
        address newCircuitVerifier,
        uint256 newBatchSize
    );

    event ModBatchAffirm(
        uint256 oldBatchAffirm,
        uint256 newBatchAffirm
    );

    event ModIrreversibleSize(
        uint256 oldIrreversibleSize,
        uint256 newIrreversibleSize
    );

    struct MerkleRootInfo {
        uint256 index;
        uint256 blockNumber;
        uint256 totalDifficulty;
    }

    struct ParsedInput {
        bytes32 parentMerkleRoot;
        bytes32 currentMerkleRoot;
        uint256 validatorSetHash;
        uint256 totalDifficulty;
        uint256 lastBlockNumber;
    }

    uint256 public  batchSize = 16;

    uint256 public  batchAffirm = 6;

    uint256 public irreversibleSize = 1;

    uint256 public genesisBlockNumber;

    bytes32[] public canonical;

    ICircuitVerifier public circuitVerifier;
    ILayerZeroUltraLightNodeV1 public layerZeroUltraLightNode;

    mapping(bytes32 => MerkleRootInfo) public merkleRoots;

    constructor(address circuitVerifierAddress, address layerZeroUltraLightNodeAddress) {
        layerZeroUltraLightNode = ILayerZeroUltraLightNodeV1(layerZeroUltraLightNodeAddress);
        //circuitVerifier = ICircuitVerifier(circuitVerifierAddress);
    }

    function updateBlock(
        uint256[2] calldata a,
        uint256[2][2] calldata b,
        uint256[2] calldata c,
        uint256[8] calldata inputs,
        bytes32[32] calldata hashList
    ) external {
        //        require(
        //            circuitVerifier.verifyProof(a, b, c, inputs),
        //            "verifyProof failed"
        //        );

        // Toy Data
        bytes32[] memory data = new bytes32[](batchSize);
        for (uint256 i = 0; i < batchSize; i++) {
            data[i] = keccak256(abi.encodePacked(hashList[i], hashList[i + batchSize], uint16(i)));
        }
        // Get Root, Proof, and Verify
        bytes32 root = getRoot(data);

        ParsedInput memory parsedInput = _parseInput(inputs);
        bytes32 parentMerkleRoot = parsedInput.parentMerkleRoot;
        bytes32 currentMerkleRoot = parsedInput.currentMerkleRoot;
        uint256 totalDifficulty = parsedInput.totalDifficulty;
        uint256 blockNumber = parsedInput.lastBlockNumber;
        require(root == currentMerkleRoot, "data error");
        if (canonical.length == 0) {
            // init
            _setGenesisBlock(currentMerkleRoot, blockNumber, totalDifficulty);
        } else {
            // make sure the known block
            MerkleRootInfo storage parentInfo = merkleRoots[parentMerkleRoot];
            require(
                parentMerkleRoot == canonical[0] || parentInfo.index != 0,
                "Cannot find parent"
            );
            uint256 currentIndex = parentInfo.index + 1;
            require(
                parentInfo.totalDifficulty < totalDifficulty,
                "Check totalDifficulty"
            );
            if (currentIndex >= canonical.length) {
                canonical.push(currentMerkleRoot);
            } else {
                //reorg
                require(
                    canonical[currentIndex] != currentMerkleRoot,
                    "Block header already exist"
                );
                require(
                    canonical.length - currentIndex <= irreversibleSize,
                    "Block header irreversible"
                );

                canonical[currentIndex] = currentMerkleRoot;
                for (uint256 i = canonical.length - 1; i > currentIndex; i--) {
                    delete merkleRoots[canonical[i]];
                    canonical.pop();
                }
            }
            MerkleRootInfo memory tempInfo = MerkleRootInfo(
                currentIndex,
                blockNumber,
                totalDifficulty
            );
            merkleRoots[currentMerkleRoot] = tempInfo;
        }

        for (uint256 i = 0;
            i < 16;
            i++) {
            layerZeroUltraLightNode.updateHash(2, hashList[i], 10, hashList[i + 16]);
        }
        emit MerkleRootRecorded(
            parentMerkleRoot,
            currentMerkleRoot,
            blockNumber
        );
    }

    function getHighestBlockInfo()
    external
    view
    returns (MerkleRootInfo memory)
    {
        uint256 index = canonical.length - 1;
        bytes32 merkleRoot = canonical[index];
        return merkleRoots[merkleRoot];
    }

    function _setGenesisBlock(
        bytes32 merkleRoot,
        uint256 blockNumber,
        uint256 totalDifficulty
    ) internal {
        require(canonical.length == 0);
        MerkleRootInfo memory tempInfo = MerkleRootInfo(
            0,
            blockNumber,
            totalDifficulty
        );
        merkleRoots[merkleRoot] = tempInfo;
        canonical.push(merkleRoot);
        genesisBlockNumber = blockNumber - batchSize + 1;
    }

    function _parseInput(uint256[8] memory inputs)
    internal
    pure
    returns (ParsedInput memory)
    {
        ParsedInput memory result;
        uint256 parentMTRoot = (inputs[1] << 128) | inputs[0];
        result.parentMerkleRoot = bytes32(parentMTRoot);

        uint256 currentMTRoot = (inputs[3] << 128) | inputs[2];
        result.currentMerkleRoot = bytes32(currentMTRoot);
        result.totalDifficulty = inputs[4];
        uint256 valSetHash = (inputs[6] << 128) | inputs[5];
        result.validatorSetHash = uint256(valSetHash);
        result.lastBlockNumber = inputs[7];
        return result;
    }

    function setCircuitVerifier(address circuitVerifierAddress, uint256 _batchSize) external onlyOwner {
        require(address(circuitVerifier) != circuitVerifierAddress, "Incorrect circuitVerifierAddress");
        require(_batchSize > 0, "Incorrect batchSize");
        emit ModCircuitVerifier(address(circuitVerifier), batchSize, circuitVerifierAddress, _batchSize);
        circuitVerifier = ICircuitVerifier(circuitVerifierAddress);
        batchSize = _batchSize;

    }

    function setBatchAffirm(uint256 _batchAffirm) external onlyOwner {
        require(_batchAffirm > 0, "Incorrect batchAffirm");
        emit ModBatchAffirm(batchAffirm, _batchAffirm);
        batchAffirm = _batchAffirm;

    }

    function setIrreversibleSize(uint256 _irreversibleSize) external onlyOwner {
        require(_irreversibleSize >= 1, "Incorrect irreversibleSize");
        emit ModIrreversibleSize(irreversibleSize, _irreversibleSize);
        irreversibleSize = _irreversibleSize;
    }
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

pragma solidity ^0.8.0;

interface ICircuitVerifier {
    function verifyProof(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[8] memory input
    ) external view returns (bool);
}

// SPDX-License-Identifier: MIT



pragma solidity ^0.8.14;

interface ILayerZeroUltraLightNodeV1 {

    function updateHash(uint16 _remoteChainId, bytes32 _lookupHash, uint _confirmations, bytes32 _data) external;

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


/// @notice Nascent, simple, kinda efficient (and improving!) Merkle proof generator and verifier
/// @author dmfxyz
/// @dev Note Generic Merkle Tree
contract  Merkle {

    /**********************
    * PROOF VERIFICATION *
    **********************/
    function verifyProof(bytes32 root, bytes32[] memory proof, bytes32 valueToProve) external pure returns (bool) {
        // proof length must be less than max array size
        bytes32 rollingHash = valueToProve;
        uint256 length = proof.length;
    unchecked {
        for(uint i = 0; i < length; ++i){
            rollingHash = hashLeafPairs(rollingHash, proof[i]);
        }
    }
        return root == rollingHash;
    }

    /********************
    * PROOF GENERATION *
    ********************/

    function getRoot(bytes32[] memory data) public pure returns (bytes32) {
        require(data.length > 1, "won't generate root for single leaf");
        while(data.length > 1) {
            data = hashLevel(data);
        }
        return data[0];
    }

    function getProof(bytes32[] memory data, uint256 node) public pure returns (bytes32[] memory) {
        require(data.length > 1, "won't generate proof for single leaf");
        // The size of the proof is equal to the ceiling of log2(numLeaves)
        bytes32[] memory result = new bytes32[](log2ceilBitMagic(data.length));
        uint256 pos = 0;

        // Two overflow risks: node, pos
        // node: max array size is 2**256-1. Largest index in the array will be 1 less than that. Also,
        // for dynamic arrays, size is limited to 2**64-1
        // pos: pos is bounded by log2(data.length), which should be less than type(uint256).max
        while(data.length > 1) {
        unchecked {
            if(node & 0x1 == 1) {
                result[pos] = data[node - 1];
            }
            else if (node + 1 == data.length) {
                result[pos] = bytes32(0);
            }
            else {
                result[pos] = data[node + 1];
            }
            ++pos;
            node /= 2;
        }
            data = hashLevel(data);
        }
        return result;
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

    /******************
    * MATH "LIBRARY" *
    ******************/

    /// @dev  Note that x is assumed > 0
    function log2ceil(uint256 x) public pure returns (uint256) {
        uint256 ceil = 0;
        uint pOf2;
        // If x is a power of 2, then this function will return a ceiling
        // that is 1 greater than the actual ceiling. So we need to check if
        // x is a power of 2, and subtract one from ceil if so.
        assembly {
        // we check by seeing if x == (~x + 1) & x. This applies a mask
        // to find the lowest set bit of x and then checks it for equality
        // with x. If they are equal, then x is a power of 2.

        /* Example
            x has single bit set
            x := 0000_1000
            (~x + 1) = (1111_0111) + 1 = 1111_1000
            (1111_1000 & 0000_1000) = 0000_1000 == x
            x has multiple bits set
            x := 1001_0010
            (~x + 1) = (0110_1101 + 1) = 0110_1110
            (0110_1110 & x) = 0000_0010 != x
        */

        // we do some assembly magic to treat the bool as an integer later on
            pOf2 := eq(and(add(not(x), 1), x), x)
        }

        // if x == type(uint256).max, than ceil is capped at 256
        // if x == 0, then pO2 == 0, so ceil won't underflow
    unchecked {
        while( x > 0) {
            x >>= 1;
            ceil++;
        }
        ceil -= pOf2; // see above
    }
        return ceil;
    }

    /// Original bitmagic adapted from https://github.com/paulrberg/prb-math/blob/main/contracts/PRBMath.sol
    /// @dev Note that x assumed > 1
    function log2ceilBitMagic(uint256 x) public pure returns (uint256){
        if (x <= 1) {
            return 0;
        }
        uint256 msb = 0;
        uint256 _x = x;
        if (x >= 2**128) {
            x >>= 128;
            msb += 128;
        }
        if (x >= 2**64) {
            x >>= 64;
            msb += 64;
        }
        if (x >= 2**32) {
            x >>= 32;
            msb += 32;
        }
        if (x >= 2**16) {
            x >>= 16;
            msb += 16;
        }
        if (x >= 2**8) {
            x >>= 8;
            msb += 8;
        }
        if (x >= 2**4) {
            x >>= 4;
            msb += 4;
        }
        if (x >= 2**2) {
            x >>= 2;
            msb += 2;
        }
        if (x >= 2**1) {
            msb += 1;
        }

        uint256 lsb = (~_x + 1) & _x;
        if ((lsb == _x) && (msb > 0)) {
            return msb;
        } else {
            return msb + 1;
        }
    }

    /// ascending sort and concat prior to hashing
    function hashLeafPairs(bytes32 left, bytes32 right) public pure returns (bytes32 _hash) {
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