// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**
                                      ..                                                            
                                    #@@@@=                                                          
                               +%@%#@@[email protected]@:                                                         
                              *@@=+%@@* @@@%%%@@@@@%%%##*+=-:                                       
                              [email protected]@@#-.:  -**+=========++*#%@@@@%*=.                                  
                             .+%@@#-                        .-+%@@%=                                
                            [email protected]@%=                               .=%@@+                              
                          .%@@-                                    [email protected]@%:                            
                         [email protected]@%.                                      .#@@:                           
                         %@%                                         .%@@                           
                        [email protected]@:                             :-           :@@+                          
                        @@%                             [email protected]@%.          #@@                          
                       :@@=      .                      [email protected]@@@:         [email protected]@:                         
                       [email protected]@-    -%@@+                    [email protected]@@@@=        [email protected]@-                         
                       [email protected]@@@@@@@@*%@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@=                         
                        --*@@+--   ---=++---------------=+=  :----==*@@*--                          
                          [email protected]@-      .#@@@%-           .#@@@%:       [email protected]@=                            
                          [email protected]@-      %@@@@@@:          %@@@@@@.      [email protected]@=                            
                          [email protected]@-     :@@@@@@@*         [email protected]@@@@@@+      [email protected]@=                            
                         -*@@-     :@@@@@@@*         [email protected]@@@@@@+      [email protected]@*-                           
                       [email protected]@@@@=      @@@@@@@-          @@@@@@@:      [email protected]@@@@+                         
                      [email protected]@[email protected]@+     #@*=--+%@.        %@*=--+%@.     [email protected]@[email protected]@+                        
                      *@@  @@#             .                 .      #@@  @@*                        
  =*#%%%%%#+:         .::. :::                                     .=-: :=-.     @@@@@%#=           
  :*@@@%-*@@@.  [email protected]@@@@=   =******+:  :+******=       #@@@@@:  :#%@@@@# :@@@@%#+  @@@%*%@@% :-=+++=  
   [email protected]@@%.:%@@.  =%@@@@=  [email protected]@@@%@@@%  @@@@%@@@@-      [email protected]@@@@:  #@@*[email protected]@@ [email protected]@@[email protected]@@- @@@+ [email protected]@@[email protected]@@=%@@. 
    @@@@@@@@-    *@@@@-  #@@@= @@@@[email protected]@@% *@@@+       #@@@@:  @@@[email protected]@@.*@@% %@@+ @@@%%@@@% %@@**+=: 
    #@@@@@@@@%+. [email protected]@@@-  %@@@- %@@@:[email protected]@@# [email protected]@@*       #@@@@. [email protected]@@[email protected]@@:*@@@.%@@* %@@@@@@+  :#%%@@@# 
    *@@@*.-*@@@@[email protected]@@@-  *@@@[email protected]@@@ :@@@%-#@@@=       *@@@@. [email protected]@@@@@@@:*@@@@@@@* %@@%+-    -*+=:@@# 
    [email protected]@@% [email protected]@@@[email protected]@@@=:.:@@@@@@@@*  #@@@@@@@%.       [email protected]@@@--.=+*####*.=#####*+: %@@*      [email protected]@@%%#= 
    [email protected]@@@@@@@@*: :+++***:   ...        ....           -+++***.                   +**=       .       
    .====--:.                                                                                                                              
                                                                                                                                                   
*/

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./BlooLoopsInterface.sol";

contract BlooLoopsRevival is Ownable, ReentrancyGuard {
  using Strings for uint256;

  address public blooLoopsAddress;
  uint256 public maxSupply = 2900;
  uint256 public currentSupply = 2801;
  bool public sleepMachine = false;
  bool public revivalMachine = false;
  bool public publicRevival = false;
  uint256 public publicRevivalPrice = 0.02 ether;

  address public vault;
  address public beneficiary;

  mapping(address => uint256) public sleepDonuts;
  mapping(address => uint256) public revivalDonuts;

  constructor (address _blooLoopsAddress, address _beneficiary, address _vault) {
    blooLoopsAddress = _blooLoopsAddress;
    beneficiary =_beneficiary;
    vault = _vault;
  }

  function setBlooLoopsAddress(address _blooLoopsAddress) public onlyOwner {
    blooLoopsAddress = _blooLoopsAddress;
  }

  function setbeneficiary(address _beneficiary) public onlyOwner {
    beneficiary = _beneficiary;
  }

  function setVault(address _vault) public onlyOwner {
    vault = _vault;
  }

  function setMaxSupply(uint256 _maxSupply) public onlyOwner {
    maxSupply = _maxSupply;
  }

  function setCurrentSupply(uint256 _currentSupply) public onlyOwner {
    currentSupply = _currentSupply;
  }

  function setPublicRevivalPrice(uint256 _price) public onlyOwner {
    publicRevivalPrice = _price;
  }

  function setSleepMachine(bool _sleepMachine) public onlyOwner {
    sleepMachine = _sleepMachine;
  }

  function setRevivalMachine(bool _revivalMachine) public onlyOwner {
    revivalMachine = _revivalMachine;
  }

  function setPublicRevival(bool _publicRevival) public onlyOwner {
    publicRevival = _publicRevival;
  }

  function getSleepDounts(address _address) public view returns (uint256) {
      return sleepDonuts[_address];
  }

  function addSleepDonuts(address[] memory addresses, uint256 _donuts) public onlyOwner {
    for (uint256 i; i < addresses.length; i++) {
      sleepDonuts[addresses[i]] = _donuts;
    }
  }

  function getRevivalDounts(address _address) public view returns (uint256) {
      return revivalDonuts[_address];
  }

  function addRevivalDonuts(address[] memory addresses, uint256 _donuts) public onlyOwner {
    for (uint256 i; i < addresses.length; i++) {
      revivalDonuts[addresses[i]] = _donuts;
    }
  }

  function sleepBloo(uint256 tokenId) public {
    uint256 donuts = sleepDonuts[msg.sender];

    require(sleepMachine == true, "Sleeping Machine is off");
    require(donuts > 0, "Not enough Sleep Donuts");
    require(currentSupply < maxSupply, "All bloos have been revived");
    sleepDonuts[msg.sender]--;
    BlooLoopsInterface(blooLoopsAddress).transferFrom(msg.sender, vault, tokenId);
    revivalDonuts[msg.sender]++;
  }

  function reviveBloo() public {
    uint256 donuts = revivalDonuts[msg.sender];

    require(revivalMachine == true, "Revival Machine is off");
    require(donuts > 0, "Not enough Revival Donuts");
    require(currentSupply < maxSupply, "All bloos have been revived");

    revivalDonuts[msg.sender]--;
    BlooLoopsInterface(blooLoopsAddress).transferFrom(vault, msg.sender, currentSupply);
    currentSupply++;
  }

  function revivePublicBloo(uint256 count) public payable {
    require(publicRevival == true, "Revival is finished/paused");
    require(currentSupply + count <= maxSupply, "All bloos have been revived");
    require(msg.value == publicRevivalPrice * count, "Insufficient amount");

    for (uint256 i = 1; i <= count; i++) {
      BlooLoopsInterface(blooLoopsAddress).transferFrom(vault, msg.sender, currentSupply);
      currentSupply++;
    }
  }

  function withdraw() public onlyOwner {
    payable(beneficiary).transfer(address(this).balance);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface BlooLoopsInterface {
  function transferFrom(address from, address to, uint256 tokenId) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
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