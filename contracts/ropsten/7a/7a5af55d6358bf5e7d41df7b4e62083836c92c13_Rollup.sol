/**
 *Submitted for verification at Etherscan.io on 2022-08-23
*/

// File: @openzeppelin/contracts/GSN/Context.sol

pragma solidity ^0.6.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }

    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/ownership/Ownable.sol

pragma solidity ^0.6.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal virtual {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.6.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// File: contracts/lib/Memory.sol

// solium-disable security/no-inline-assembly
pragma solidity ^0.6.1;

/**
* @title a library to sequentially read memory
* @dev inspired from Andreas Olofsson's RLP
*/
library Memory {
    struct Cursor {
       uint256 begin;
       uint256 end;
    }

    /**
    * @dev returns a new cursor from a memory
    * @return Cursor cursor to read from
    */
    function read(bytes memory self) internal pure returns (Cursor memory) {
       uint ptr;
       assembly {
         ptr := add(self, 0x20)
       }
       return Cursor(ptr,ptr+self.length);
    }

    /**
    * @dev reads 32 bytes from cursor, no eof checks
    * @return b the value
    */
    function readBytes32(Cursor memory c) internal pure returns (bytes32) {
        uint ptr = c.begin;
        bytes32 b;
        assembly {
          b := mload(ptr)
        }
        c.begin += 32;
        return b;
    }

    /**
    * @dev reads 30 bytes from cursor, no eof checks
    * @return b the value
    */
    function readBytes30(Cursor memory c) internal pure returns (bytes30) {
        uint ptr = c.begin;
        bytes32 b;
        assembly {
          b := mload(ptr)
        }
        c.begin += 30;
        return bytes30(b);
    }

    /**
    * @dev reads 28 bytes from cursor, no eof checks
    * @return b the value
    */
    function readBytes28(Cursor memory c) internal pure returns (bytes28) {
        uint ptr = c.begin;
        bytes32 b;
        assembly {
          b := mload(ptr)
        }
        c.begin += 28;
        return bytes28(b);
    }

    /**
    * @dev reads 10 bytes from cursor, no eof checks
    * @return b the value
    */
    function readBytes10(Cursor memory c) internal pure returns (bytes10) {
        uint ptr = c.begin;
        bytes32 b;
        assembly {
          b := mload(ptr)
        }
        c.begin += 10;
        return bytes10(b);
    }

    /**
    * @dev reads 3 bytes from cursor, no eof checks
    * @return b the value
    */
    function readBytes3(Cursor memory c) internal pure returns (bytes3) {
        uint ptr = c.begin;
        bytes32 b;
        assembly {
          b := mload(ptr)
        }
        c.begin += 3;
        return bytes3(b);
    }

    /**
    * @dev reads 2 bytes from cursor, no eof checks
    * @return b the value
    */
    function readBytes2(Cursor memory c) internal pure returns (bytes2) {
        uint ptr = c.begin;
        bytes32 b;
        assembly {
          b := mload(ptr)
        }
        c.begin += 2;
        return bytes2(b);
    }

    /**
    * @dev reads 1 bytes from cursor, no eof checks
    * @return b the value
    */
    function readBytes1(Cursor memory c) internal pure returns (bytes1) {
        uint ptr = c.begin;
        bytes32 b;
        assembly {
          b := mload(ptr)
        }
        c.begin += 1;
        return bytes1(b);
    }

    /**
    * @dev reads a bool from cursor (8 bits), no eof checks
    * @return b the value
    */
    function readBool(Cursor memory c) internal pure returns (bool) {
        uint ptr = c.begin;
        uint256 b;
        assembly {
          b := mload(ptr)
        }
        c.begin += 1;
        return (b >> (256-8)) != 0;
    }

    /**
    * @dev reads a uint8 from cursor, no eof checks
    * @return b the value
    */
    function readUint8(Cursor memory c) internal pure returns (uint8) {
        uint ptr = c.begin;
        uint256 b;
        assembly {
          b := mload(ptr)
        }
        c.begin += 1;
        return uint8(b >> (256-8));
    }

    /**
    * @dev reads a uint16 from cursor, no eof checks
    * @return b the value
    */
    function readUint16(Cursor memory c) internal pure returns (uint16) {
        uint ptr = c.begin;
        uint256 b;
        assembly {
          b := mload(ptr)
        }
        c.begin += 2;
        return uint16(b >> (256-16));
    }

    /**
    * @dev reads a uint32 from cursor, no eof checks
    * @return b the value
    */
    function readUint32(Cursor memory c) internal pure returns (uint32) {
        uint ptr = c.begin;
        uint256 b;
        assembly {
          b := mload(ptr)
        }
        c.begin += 4;
        return uint32(b >> (256-32));
    }

    /**
    * @dev reads a uint64 from cursor, no eof checks
    * @return b the value
    */
    function readUint64(Cursor memory c) internal pure returns (uint64) {
        uint ptr = c.begin;
        uint256 b;
        assembly {
          b := mload(ptr)
        }
        c.begin += 8;
        return uint64(b>>(256-64));
    }

    /**
    * @dev reads a uint240 from cursor, no eof checks
    * @return b the value
    */
    function readUint240(Cursor memory c) internal pure returns (uint240) {
        uint ptr = c.begin;
        uint256 b;
        assembly {
          b := mload(ptr)
        }
        c.begin += 30;
        return uint240(b>>(256-240));
    }

    /**
    * @dev reads an address from cursor, no eof checks
    * @return b the value
    */
    function readAddress(Cursor memory c) internal pure returns (address) {
        uint ptr = c.begin;
        uint256 b;
        assembly {
          b := mload(ptr)
        }
        c.begin += 20;
        return address(b >> (256-160));
    }

    /**
    * @dev reads a variable sized bytes, max 2^16 len, no eof check
    * @return bts the value
    */
    function readBytes(Cursor memory c) internal pure returns (bytes memory bts) {
        uint16 len = readUint16(c);
        bts = new bytes(len);
        uint256 btsmem;
        assembly {
            btsmem := add(bts,0x20)
        }
        memcpy(btsmem,c.begin,len);
        c.begin += len;
    }

    /**
    * @dev checks if the cursor is *exactly* at the end of the stream
    * @return c true if is *exactly* at the end
    */
    function eof(Cursor memory c) internal pure returns (bool) {
        return c.begin == c.end;
    }

    /**
    * @dev copies _len bytes from _src to _dest
    */
    // solium-disable security/no-assign-params
    function memcpy(uint _dest, uint _src, uint _len) internal pure {
        // Copy word-length chunks while possible
        for ( ;_len >= 32; _len -= 32) {
            assembly {
                mstore(_dest, mload(_src))
            }
            _dest += 32;
            _src += 32;
        }

        // Copy remaining bytes
        uint mask = 256 ** (32 - _len) - 1;
        assembly {
            let srcpart := and(mload(_src), not(mask))
            let destpart := and(mload(_dest), mask)
            mstore(_dest, or(destpart, srcpart))
        }
    }

}

// File: contracts/lib/RollupHelpers.sol

pragma solidity ^0.6.1;

/**
 * @dev Interface poseidon hash function
 */
contract PoseidonUnit {
  function poseidon(uint256[] memory) public pure returns(uint256) {}
}

/**
 * @dev Rollup helper functions
 */
contract RollupHelpers {

  using Memory for *;

  PoseidonUnit insPoseidonUnit;

  struct Entry {
    bytes32 e1;
    bytes32 e2;
    bytes32 e3;
    bytes32 e4;
    bytes32 e5;
    bytes32 e6;
  }

  uint constant bytesOffChainTx = 3*2 + 2;
  uint constant rField = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
  uint64 constant IDEN3_ROLLUP_TX = 4839017969649077913;

  /**
   * @dev Load poseidon smart contract
   * @param _poseidonContractAddr poseidon contract address
   */
  constructor (address _poseidonContractAddr) public {
    insPoseidonUnit = PoseidonUnit(_poseidonContractAddr);
  }

  /**
   * @dev hash poseidon multi-input elements
   * @param inputs input element array
   * @return poseidon hash
   */
  function hashGeneric(uint256[] memory inputs) internal view returns (uint256){
    return insPoseidonUnit.poseidon(inputs);
  }

  /**
   * @dev hash poseidon for sparse merkle tree nodes
   * @param left input element array
   * @param right input element array
   * @return poseidon hash
   */
  function hashNode(uint256 left, uint256 right) internal view returns (uint256){
    uint256[] memory inputs = new uint256[](2);
    inputs[0] = left;
    inputs[1] = right;
    return hashGeneric(inputs);
  }

  /**
   * @dev hash poseidon for sparse merkle tree final nodes
   * @param key input element array
   * @param value input element array
   * @return poseidon hash1
   */
  function hashFinalNode(uint256 key, uint256 value) internal view returns (uint256){
    uint256[] memory inputs = new uint256[](3);
    inputs[0] = key;
    inputs[1] = value;
    inputs[2] = 1;
    return hashGeneric(inputs);
  }

  /**
   * @dev poseidon hash for entry generic structure
   * @param entry entry structure
   * @return poseidon hash
   */
  function hashEntry(Entry memory entry) internal view returns (uint256){
    uint256[] memory inputs = new uint256[](6);
    inputs[0] = uint256(entry.e1);
    inputs[1] = uint256(entry.e2);
    inputs[2] = uint256(entry.e3);
    inputs[3] = uint256(entry.e4);
    inputs[4] = uint256(entry.e5);
    inputs[5] = uint256(entry.e6);
    return hashGeneric(inputs);
  }

  /**
   * @dev Verify sparse merkle tree proof
   * @param root root to verify
   * @param siblings all siblings
   * @param key key to verify
   * @param value value to verify
   * @param isNonExistence existence or non-existence verification
   * @param isOld indicates non-existence non-empty verification
   * @param oldKey needed in case of non-existence proof with non-empty node
   * @param oldValue needed in case of non-existence proof with non-empty node
   * @return true if verification is correct, false otherwise
   */
  function smtVerifier(uint256 root, uint256[] memory siblings,
    uint256 key, uint256 value, uint256 oldKey, uint256 oldValue,
    bool isNonExistence, bool isOld, uint256 maxLevels) internal view returns (bool){

    // Step 1: check if proof is non-existence non-empty
    uint256 newHash;
    if (isNonExistence && isOld) {
      // Check old key is final node
      uint exist = 0;
      uint levCounter = 0;
      while ((exist == 0) && (levCounter < maxLevels)) {
        exist = (uint8(oldKey >> levCounter) & 0x01) ^ (uint8(key >> levCounter) & 0x01);
        levCounter += 1;
      }

      if (exist == 0) {
        return false;
      }
      newHash = hashFinalNode(oldKey, oldValue);
    }

    // Step 2: Calcuate root
    uint256 nextHash = isNonExistence ? newHash : hashFinalNode(key, value);
    uint256 siblingTmp;
    for (int256 i = int256(siblings.length) - 1; i >= 0; i--) {
     siblingTmp = siblings[uint256(i)];
      bool leftRight = (uint8(key >> i) & 0x01) == 1;
      nextHash = leftRight ? hashNode(siblingTmp, nextHash)
                           : hashNode(nextHash, siblingTmp);
    }

    // Step 3: Check root
    return root == nextHash;
  }

  /**
   * @dev build entry for fee plan
   * @param feePlan contains all fee plan data
   * @return entry structure
   */
  function buildEntryFeePlan(bytes32[2] memory feePlan)
    internal pure returns (Entry memory entry) {
    // build element 1
    entry.e1 = bytes32(feePlan[0] << 128) >> (256 - 128);
    // build element 2
    entry.e2 = bytes32(feePlan[0]) >> (256 - 128);
    // build element 3
    entry.e3 = bytes32(feePlan[1] << 128)>>(256 - 128);
    // build element 4
    entry.e4 = bytes32(feePlan[1]) >> (256 - 128);
  }

  /**
   * @dev Calculate total fee amount for the beneficiary
   * @param tokenIds contains all token id (feePlanCoinsInput)
   * @param totalFees contains total fee for every token Id (feeTotal)
   * @param nToken token position on fee plan
   * @return total fee amount
   */
  function calcTokenTotalFee(bytes32 tokenIds, bytes32 totalFees, uint nToken)
    internal pure returns (uint32, uint256) {
    uint256 ptr = 256 - ((nToken+1)*16);
    // get fee depending on token
    uint256 fee = float2Fix(uint16(bytes2(totalFees << ptr)));
    // get token id
    uint32 tokenId = uint16(bytes2(tokenIds << ptr));

    return (tokenId, fee);
  }

  /**
   * @dev build entry for the exit tree leaf
   * @param amount amount
   * @param token token type
   * @param Ax x coordinate public key babyJub
   * @param Ay y coordinate public key babyJub
   * @param ethAddress ethereum address
   * @param nonce nonce parameter
   * @return entry structure
   */
  function buildTreeState(uint256 amount, uint32 token, uint256 Ax, uint Ay,
    address ethAddress, uint48 nonce) internal pure returns (Entry memory entry) {
     // build element 1
    entry.e1 = bytes32(bytes4(token)) >> (256 - 32);
    entry.e1 |= bytes32(bytes6(nonce)) >> (256 - 48 - 32);
    // build element 2
    entry.e2 = bytes32(amount);
    // build element 3
    entry.e3 = bytes32(Ax);
    // build element 4
    entry.e4 = bytes32(Ay);
    // build element 5
    entry.e5 = bytes32(bytes20(ethAddress)) >> (256 - 160);
  }

  /**
   * @dev build transaction data
   * @param amountF amount to send encoded as half precision float
   * @param token token identifier
   * @param nonce nonce parameter
   * @param fee fee sent by the user, it represents some % of the amount
   * @param rqOffset atomic swap paramater
   * @param onChain flag to indicate that transaction is an onChain one
   * @param newAccount flag to indicate if transaction is of deposit type
   * @return element
   */
  function buildTxData(
    uint16 amountF,
    uint32 token,
    uint48 nonce,
    uint8 fee,
    uint8 rqOffset,
    bool onChain,
    bool newAccount
    ) internal pure returns (bytes32 element) {
    // build element
    element = bytes32(bytes8(IDEN3_ROLLUP_TX)) >> (256 - 64);
    element |= bytes32(bytes2(amountF)) >> (256 - 16 - 64);
    element |= bytes32(bytes4(token)) >> (256 - 32 - 16 - 64);
    element |= bytes32(bytes6(nonce)) >> (256 - 48 - 32 - 16 - 64);

    bytes1 nextByte = bytes1(fee) & 0x0f;
    nextByte = nextByte | (bytes1(rqOffset << 4) & 0x70);
    nextByte = onChain ? (nextByte | 0x80): nextByte;
    element |= bytes32(nextByte) >> (256 - 8 - 48 - 32 - 16 - 64);

    bytes1 last = newAccount ? bytes1(0x01) : bytes1(0x00);

    element |= bytes32(last) >> (256 - 8 - 8 - 48 - 32 - 16 - 64);
  }

  /**
   * @dev build on-chain Hash
   * @param oldOnChainHash previous on chain hash
   * @param txData transaction data coded into a bytes32
   * @param loadAmount input amount
   * @param dataOnChain poseidon hash of the onChain data
   * @param fromEthAddr ethereum addres sender
   * @return entry structure
   */
  function buildOnChainHash(
    uint256 oldOnChainHash,
    uint256 txData,
    uint128 loadAmount,
    uint256 dataOnChain,
    address fromEthAddr
    ) internal pure returns (Entry memory entry) {
    // build element 1
    entry.e1 = bytes32(oldOnChainHash);
    // build element 2
    entry.e2 = bytes32(txData);
    // build element 3
    entry.e3 = bytes32(bytes16(loadAmount)) >> (256 - 128);
    // build element 4
    entry.e4 = bytes32(dataOnChain);
    // build element 5
    entry.e5 = bytes32(bytes20(fromEthAddr)) >> (256 - 160);
  }

  /**
   * @dev build hash of the on-chain data
   * @param fromAx x coordinate public key BabyJubJub sender
   * @param fromAy y coordinate public key BabyJubJub sender
   * @param toEthAddr ethereum addres receiver
   * @param toAx x coordinate public key BabyJubJub receiver
   * @param toAy y coordinate public key BabyJubJub receiver
   * @return entry structure
   */
  function buildOnChainData(
    uint256 fromAx,
    uint256 fromAy,
    address toEthAddr,
    uint256 toAx,
    uint256 toAy
    ) internal pure returns (Entry memory entry) {
    // build element 1
    entry.e1 = bytes32(fromAx);
    // build element 2
    entry.e2 = bytes32(fromAy);
    // build element 3
    entry.e3 = bytes32(bytes20(toEthAddr)) >> (256 - 160);
    // build element 4
    entry.e4 = bytes32(toAx);
    // build element 5
    entry.e5 = bytes32(toAy);
  }

  /**
   * @dev Decode half floating precision
   * @param float Float half precision encode number
   * @return Decoded floating half precision
   */
  function float2Fix(uint16 float) public pure returns (uint256) {
    uint256 m = float & 0x3FF;
    uint256 e = float >> 11;
    uint256 e5 = (float >> 10) & 1;

    uint256 exp = 10 ** e;
    uint256 fix = m * exp;

    if ((e5 == 1) && (e != 0)){
      fix = fix + (exp / 2);
    }
    return fix;
  }

  /**
   * @dev Retrieve ethereum address from a msg plus signature
   * @param msgHash message hash
   * @param rsv signature
   * @return Ethereum address recovered from the signature
   */
  function checkSig(bytes32 msgHash, bytes memory rsv) public pure returns (address) {
    bytes32 r;
    bytes32 s;
    uint8   v;

    // solium-disable security/no-inline-assembly
    assembly {
        r := mload(add(rsv, 32))
        s := mload(add(rsv, 64))
        v := byte(0, mload(add(rsv, 96)))
    }
    return ecrecover(msgHash, v, r, s);
  }

  /**
   * @dev update on-chain fees
   * it updates every batch if it is full or build
   * @param onChainTxCount number of on-chain transactions in the same batch
   * @param currentFee current on-chain fee
   * @return newFee
   */
  function updateOnchainFee(uint256 onChainTxCount, uint256 currentFee) internal pure returns (uint256 newFee) {
      if (10 < onChainTxCount)
          newFee = (currentFee*100722)/100000;
      else if (10 > onChainTxCount)
          newFee = (currentFee*100000)/100722;
      else
          newFee = currentFee;
      if (newFee > 1 ether)
          newFee = 1 ether;
      else if (newFee < (1 szabo / 1000) ) // 1 Gwei
          newFee = 1 szabo / 1000;
  }

  /**
   * @dev update deposit fee
   * It updates every batch
   * @param depositCount number of deposits in the same batch
   * @param oldFee current deposit fee
   * @return newFee
   */
  function updateDepositFee(uint32 depositCount, uint256 oldFee) internal pure returns (uint256 newFee) {
      newFee = oldFee;
      for (uint32 i = 0; i < depositCount; i++) {
          newFee = newFee * 10000008235 / 10000000000;
      }
  }
}

// File: contracts/RollupInterface.sol

pragma solidity ^0.6.1;

/**
 * @dev Define interface Rollup smart contract
 */
interface RollupInterface {
  function forgeBatch(
    uint[2] calldata proofA,
    uint[2][2] calldata proofB,
    uint[2] calldata proofC,
    uint[10] calldata input,
    bytes calldata compressedOnChainTx
  ) external payable;
}

// File: contracts/VerifierInterface.sol

pragma solidity ^0.6.1;

/**
 * @dev Define interface verifier
 */
interface VerifierInterface {
  function verifyProof(
    uint[2] calldata proofA,
    uint[2][2] calldata proofB,
    uint[2] calldata proofC,
    uint[10] calldata input
  ) external view returns (bool);
}

// File: contracts/Rollup.sol

pragma solidity ^0.6.1;





contract Rollup is Ownable, RollupHelpers, RollupInterface {
    // External contracts used
    VerifierInterface verifier;

    // Forge batch mechanism owner
    address ownerForgeBatch;

    // Each batch forged will have the root state of the 'balance tree'
    bytes32[] stateRoots;

    // Each batch forged will have a correlated 'exit tree' represented by the exit root
    bytes32[] exitRoots;
    mapping(uint256 => bool) public exitNullifier;

    // Define struct to store data of each leaf
    // lastLeafIndex + relativeIndex = index of the leaf
    struct leafInfo{
        uint64 forgedBatch;
        uint32 relativeIndex;
        address ethAddress;
    }

    // Store accounts information, treeInfo[hash(Ax, Ay, tokenId)] = leafInfo
    mapping(uint256 => leafInfo) treeInfo;

    // Define struct to store batch information regarding number of deposits and keep track of index accounts
    struct batchInfo{
        uint64 lastLeafIndex;
        uint32 depositOnChainCount;
    }

    // Batch number to batch information
    mapping(uint256 => batchInfo) public batchToInfo;

    // Maxim Deposit allowed
    uint constant MAX_AMOUNT_DEPOSIT = (1 << 128);

    // List of valid ERC20 tokens that can be deposit in 'balance tree'
    address[] public tokens;
    mapping(uint => address) public tokenList;
    uint constant MAX_TOKENS = 0xFFFFFFFF;
    uint public feeAddToken = 0.01 ether;

    // Address to receive token fees
    address payable feeTokenAddress;

    // Hash of all on chain transactions ( will be forged in the next batch )
    // Forces 'operator' to add all on chain transactions
    uint256 public miningOnChainTxsHash;

    /**
     * @dev Struct that contains all the information to forge future OnchainTx
     * @param fillingOnChainTxsHash  hash of all on chain transactions ( will be forged in two batches )
     * @param totalFillingOnChainFee poseidon hash function address
     * @param currentOnChainTx fees of all on-chain transactions that will be on minninf the next batch
     */
    struct fillingInfo {
        uint256 fillingOnChainTxsHash;
        uint256 totalFillingOnChainFee;
        uint256 currentOnChainTx;
    }

    // batchNum --> filling information
    mapping(uint256 => fillingInfo) public fillingMap;

    uint256 public currentFillingBatch;

    // Fees of all on-chain transactions which goes to the operator that will forge the batch
    uint256 public totalMinningOnChainFee;

    // Fees recollected for every on-chain transaction
    uint256 public feeOnchainTx = 0.01 ether;
    uint256 public depositFee = 0.001 ether; 

    // maximum on-chain transactions
    uint public MAX_ONCHAIN_TX;

    // maximum rollup transactions: either off-chain or on-chain transactions
    uint public MAX_TX;

    // Flag to determine if the mechanism to forge batch has been initialized
    bool initialized = false;

    // Bytes of a encoded offchain deposit
    uint32 constant DEPOSIT_BYTES = 88;
    // Number of levels in Snark circuit
    uint256 public NLevels = 24;

    // Input snark definition
    uint256 constant finalIdxInput = 0;
    uint256 constant newStateRootInput = 1;
    uint256 constant newExitRootInput = 2;
    uint256 constant onChainHashInput = 3;
    uint256 constant offChainHashInput = 4;
    uint256 constant initialIdxInput = 5;
    uint256 constant oldStateRootInput = 6;
    uint256 constant feePlanCoinsInput = 7;
    uint256 constant feeTotalsInput = 8;
    uint256 constant beneficiaryAddressInput = 9;

    /**
     * @dev Event called when any on-chain transaction has benn done
     * contains all data required for the operator to update balance tree
     */
    event OnChainTx(uint batchNumber, bytes32 txData, uint128 loadAmount,
        address fromEthAddress, uint256 fromAx, uint256 fromAy,  address toEthAddress, uint256 toAx, uint256 toAy);

    /**
     * @dev Event called when a batch is forged
     * Contains which batch has been forged and on which block number
     */
    event ForgeBatch(uint batchNumber, uint blockNumber);

    /**
     * @dev Event called when a token is added to token list
     * Contains token address and its index inside rollup token list
     */
    event AddToken(address tokenAddress, uint tokenId);

    /**
     * @dev modifier to check if forge batch mechanism has been initialized
     */
    modifier isForgeBatch {
        require(initialized == true, 'forge batch mechanism has not been loaded');
        require(ownerForgeBatch == msg.sender, 'message sender is not forge batch mechanism owner');
        _;
    }

    /**
     * @dev Rollup constructor
     * Loads 'RollupHelpers' constructor with poseidon
     * Loads verifier zk-snark proof
     * @param _verifier verifier zk-snark proof address
     * @param _poseidon poseidon hash function address
     * @param _maxTx maximum rollup transactions, either on-chain or off-chain
     * @param _maxOnChainTx maximum rollup on-chain transactions
     */
    constructor(address _verifier, address _poseidon, uint _maxTx,
        uint _maxOnChainTx, address payable _feeTokenAddress) RollupHelpers(_poseidon) public {
        feeTokenAddress = _feeTokenAddress;
        verifier = VerifierInterface(_verifier);
        MAX_ONCHAIN_TX = _maxOnChainTx;
        MAX_TX = _maxTx;
        stateRoots.push(bytes32(0));
        exitRoots.push(bytes32(0));
        batchToInfo[getStateDepth()].lastLeafIndex = 100; // Start at 100
    }

    /**
     * @dev Load forge batch mechanism smart contract
     * @param forgeBatchMechanismAddress rollupPoS contract address
     */
    function loadForgeBatchMechanism(address forgeBatchMechanismAddress) public onlyOwner{
        ownerForgeBatch = forgeBatchMechanismAddress;
        initialized = true;
    }

    /**
     * @dev Inclusion of a new token that will be able to deposit on 'balance tree'
     * Fees to include token are increased as tokens are added into rollup
     * @param tokenAddress smart contract token address
     */
    function addToken(address tokenAddress) public payable {
        // Allow MAX_TOKENS different types of tokens
        require(tokens.length <= MAX_TOKENS, 'token list is full');
        require(msg.value >= feeAddToken, 'Amount is not enough to cover token fees');
        tokens.push(tokenAddress);
        uint tokenId = tokens.length - 1;
        tokenList[tokenId] = tokenAddress;
        feeTokenAddress.transfer(msg.value);
        // increase fees for next token deposit
        feeAddToken = (feeAddToken / 4) + feeAddToken;
        emit AddToken(tokenAddress, tokenId);
    }

    /**
     * @dev update on-chain hash
     * @param txData transaction rollup data
     * @param loadAmount amount to add to balance tree
     * @param fromEthAddress ethereum Address
     * @param fromBabyPubKey public key babyjubjub represented as point (Ax, Ay)
     * @param toEthAddress ethereum Address
     * @param toBabyPubKey public key babyjubjub represented as point (Ax, Ay)
     */
    function _updateOnChainHash(
        uint256 txData,
        uint128 loadAmount,
        address fromEthAddress,
        uint256[2] memory fromBabyPubKey,
        address toEthAddress,
        uint256[2] memory toBabyPubKey
    ) private {

        // Retrieve current fillingOnchainHash
        fillingInfo storage currentFilling = fillingMap[currentFillingBatch];

        // Calculate onChain Hash
        Entry memory onChainData = buildOnChainData(fromBabyPubKey[0], fromBabyPubKey[1],
        toEthAddress, toBabyPubKey[0], toBabyPubKey[1]);
        uint256 hashOnChainData = hashEntry(onChainData);
        Entry memory onChainHash = buildOnChainHash(currentFilling.fillingOnChainTxsHash, txData, loadAmount,
            hashOnChainData, fromEthAddress);
        currentFilling.fillingOnChainTxsHash = hashEntry(onChainHash);

        // Update number of on-chain transactions
        currentFilling.currentOnChainTx++;

        // The burned fee depends on how many on-chain transactions have been taken place the last batch
        // It grows linearly to a maximum of 33% of the feeOnchainTx
        uint256 burnedFee = (feeOnchainTx * currentFilling.currentOnChainTx) / (MAX_ONCHAIN_TX * 3);
        address(0).transfer(burnedFee);
        // Update total on-chain fees
        currentFilling.totalFillingOnChainFee += feeOnchainTx - burnedFee;
        
        // trigger on chain tx event event
        emit OnChainTx(currentFillingBatch, bytes32(txData), loadAmount, fromEthAddress, fromBabyPubKey[0], fromBabyPubKey[1],
        toEthAddress, toBabyPubKey[0], toBabyPubKey[1]);

         // if the currentFilling slot have all the OnChainTx possible, add a new element to the array
        if (currentFilling.currentOnChainTx >= MAX_ONCHAIN_TX) {
            feeOnchainTx = updateOnchainFee(currentFilling.currentOnChainTx, feeOnchainTx);
            currentFillingBatch++;
        }
    }

    /**
     * @dev Deposit on-chain transaction
     * add new leaf to balance tree and initializes it with a load amount
     * @param loadAmount initial balance on balance tree
     * @param tokenId token type identifier
     * @param ethAddress allowed address to control new balance tree leaf
     * @param babyPubKey public key babyjubjub represented as point (Ax, Ay)
    */
    function deposit(
        uint128 loadAmount,
        uint32 tokenId,
        address ethAddress,
        uint256[2] memory babyPubKey
    ) public payable {
        // Onchain fee + deposit fee
        uint256 totalFee = feeOnchainTx + depositFee;
        require(msg.value >= totalFee, 'Amount deposited less than fee required');
        require(loadAmount > 0, 'Deposit amount must be greater than 0');
        require(loadAmount < MAX_AMOUNT_DEPOSIT, 'deposit amount larger than the maximum allowed');
        require(ethAddress != address(0), 'Must specify withdraw address');
        require(tokenList[tokenId] != address(0), 'token has not been registered');

        leafInfo storage leaf = treeInfo[uint256(keccak256(abi.encodePacked(babyPubKey,tokenId)))];
        require(leaf.ethAddress == address(0), 'leaf already exist');
        
        // Get token deposit on rollup smart contract
        require(depositToken(tokenId, loadAmount), 'Fail deposit ERC20 transaction');

        // Build txData for deposit
        bytes32 txDataDeposit = buildTxData(0, tokenId, 0, 0, 0, true, true);

        // Increment deposit count in the batch that will be forged
        batchToInfo[currentFillingBatch+2].depositOnChainCount++;

        // Insert leaf informations
        leaf.forgedBatch = uint64(currentFillingBatch+2);
        leaf.relativeIndex = batchToInfo[currentFillingBatch+2].depositOnChainCount;
        leaf.ethAddress = ethAddress;

        // Burn deposit fee
        address(0).transfer(depositFee);
        
        _updateOnChainHash(uint256(txDataDeposit), loadAmount, ethAddress, babyPubKey, address(0), [uint256(0),uint256(0)]);

        // Return remaining ether to the msg.sender    
        msg.sender.transfer(msg.value - totalFee);
    }

    /**
     * @dev Deposit off-chain transaction
     * add new leaf to balance tree and initializes it with a load amount
     * @param tokenId token id
     * @param ethAddress allowed address to control new balance tree leaf
     * @param babyPubKey public key babyjubjub represented as point (Ax, Ay)
     * @param relativeIndex relative index of this leaf
     */
    function depositOffChain(
        uint32 tokenId,
        address ethAddress,
        uint256[2] memory babyPubKey,
        uint32 relativeIndex
    ) internal {
        require(ethAddress != address(0), 'Must specify withdraw address');
        require(tokenList[tokenId] != address(0), 'token has not been registered');

        leafInfo storage leaf = treeInfo[uint256(keccak256(abi.encodePacked(babyPubKey,tokenId)))];
        require(leaf.ethAddress == address(0), 'leaf already exist');

        // Build txData for deposit off-chain
        bytes32 txDataDeposit = buildTxData(0, tokenId, 0, 0, 0, true, true);

        // Calculate onChain Hash
        Entry memory onChainData = buildOnChainData(babyPubKey[0], babyPubKey[1],
        address(0), 0, 0);
        uint256 hashOnChainData = hashEntry(onChainData);
        Entry memory onChainHash = buildOnChainHash(miningOnChainTxsHash, uint256(txDataDeposit), 0,
         hashOnChainData, ethAddress);
        miningOnChainTxsHash = hashEntry(onChainHash);

        // Insert tree information
        leaf.forgedBatch = uint64(getStateDepth()+1);
        leaf.relativeIndex = relativeIndex;
        leaf.ethAddress = ethAddress;
    }

    /**
     * @dev Deposit on an existing balance tree leaf
     * @param babyPubKey public key babyjubjub represented as point (Ax, Ay)
     * @param loadAmount amount to be added into leaf specified by idBalanceTree
     * @param tokenId token identifier
     */
    function depositOnTop(
        uint256[2] memory babyPubKey,
        uint128 loadAmount,
        uint32 tokenId
    ) public payable{
        uint256 totalFee = feeOnchainTx;
        require(msg.value >= totalFee, 'Amount deposited less than fee required');
        require(loadAmount > 0, 'Deposit amount must be greater than 0');
        require(loadAmount < MAX_AMOUNT_DEPOSIT, 'deposit amount larger than the maximum allowed');

        leafInfo storage leaf = treeInfo[uint256(keccak256(abi.encodePacked(babyPubKey,tokenId)))];
        require(leaf.ethAddress != address(0), 'leaf does no exist');

        // Get token deposit on rollup smart contract
        require(depositToken(tokenId, loadAmount), 'Fail deposit ERC20 transaction');

        // Build txData for deposit on top
        bytes32 txDataDepositOnTop = buildTxData(0, tokenId, 0, 0, 0, true, false);
        _updateOnChainHash(uint256(txDataDepositOnTop), loadAmount, leaf.ethAddress, babyPubKey, address(0), [uint256(0),uint256(0)]);

        // Return remaining ether to the msg.sender    
        msg.sender.transfer(msg.value - totalFee);
    }

    /**
     * @dev Transfer between two accounts already defined in balance tree
     * @param fromBabyPubKey account sender
     * @param toBabyPubKey account receiver
     * @param amountF amount to send encoded as half precision float
     * @param tokenId token identifier
     */
    function transfer(
        uint256[2] memory fromBabyPubKey,
        uint256[2] memory toBabyPubKey,
        uint16 amountF,
        uint32 tokenId
    ) public payable{
        uint256 totalFee = feeOnchainTx;
        require(msg.value >= totalFee, 'Amount deposited less than fee required');

        leafInfo storage fromLeaf = treeInfo[uint256(keccak256(abi.encodePacked(fromBabyPubKey,tokenId)))];
        require(fromLeaf.ethAddress == msg.sender, 'Sender does not match identifier balance tree');

        leafInfo storage toLeaf = treeInfo[uint256(keccak256(abi.encodePacked(toBabyPubKey,tokenId)))];
        require(toLeaf.ethAddress != address(0), 'Receiver leaf does not exist');

        // Build txData for transfer
        bytes32 txDataTransfer = buildTxData(amountF, tokenId, 0, 0, 0, true, false);
        _updateOnChainHash(uint256(txDataTransfer), 0, fromLeaf.ethAddress, fromBabyPubKey,
         toLeaf.ethAddress, toBabyPubKey);

        // Return remaining ether to the msg.sender    
        msg.sender.transfer(msg.value - totalFee);
    }


    /**
     * @dev add new leaf to balance tree and initializes it with a load amount
     * then transfer some amount to an account already defined in the balance tree
     * @param loadAmount initial balance on balance tree
     * @param tokenId token identifier
     * @param fromEthAddress allowed address to control new balance tree leaf
     * @param fromBabyPubKey public key babyjubjub of the sender represented as point (Ax, Ay)
     * @param toBabyPubKey account receiver
     * @param amountF amount to send encoded as half precision float
     */
    function depositAndTransfer(
        uint128 loadAmount,
        uint32 tokenId,
        address fromEthAddress,
        uint256[2] memory fromBabyPubKey,
        uint256[2] memory toBabyPubKey,
        uint16 amountF
    ) public payable{
        // Onchain fe + deposit Fee
        uint256 totalFee = feeOnchainTx + depositFee;        
        require(msg.value >= totalFee, 'Amount deposited less than fee required');
        require(loadAmount > 0, 'Deposit amount must be greater than 0');
        require(loadAmount < MAX_AMOUNT_DEPOSIT, 'deposit amount larger than the maximum allowed');
        require(fromEthAddress != address(0), 'Must specify withdraw address');
        require(tokenList[tokenId] != address(0), 'token has not been registered');

        leafInfo storage fromLeaf = treeInfo[uint256(keccak256(abi.encodePacked(fromBabyPubKey,tokenId)))];
        require(fromLeaf.ethAddress == address(0), 'leaf already exist');

        leafInfo memory toLeaf;
        if (!(toBabyPubKey[0] == 0 && toBabyPubKey[1] == 0)){
            toLeaf = treeInfo[uint256(keccak256(abi.encodePacked(toBabyPubKey,tokenId)))];
            require(toLeaf.ethAddress != address(0), 'leaf does not exist');
        }

        // Get token deposit on rollup smart contract
        require(depositToken(tokenId, loadAmount), 'Fail deposit ERC20 transaction');

        // Build txData for DepositAndtransfer
        bytes32 txDataDepositAndTransfer = buildTxData(amountF, tokenId, 0, 0, 0, true, true);

        // Increment index leaf balance tree
        batchToInfo[currentFillingBatch + 2].depositOnChainCount++;

        // Insert tree informations
        fromLeaf.forgedBatch = uint64(currentFillingBatch + 2); // batch wich will be forged
        fromLeaf.relativeIndex = batchToInfo[currentFillingBatch + 2].depositOnChainCount;
        fromLeaf.ethAddress = fromEthAddress;
        
        // Burn deposit fee
        address(0).transfer(depositFee);

        _updateOnChainHash(uint256(txDataDepositAndTransfer), loadAmount, fromEthAddress, fromBabyPubKey,
        toLeaf.ethAddress, toBabyPubKey);

        // Return remaining ether to the msg.sender    
        msg.sender.transfer(msg.value - totalFee);
    }


    /**
     * @dev Withdraw balance from identifier balance tree
     * user has to prove ownership of ethAddress of idBalanceTree
     * @param fromBabyPubKey public key babyjubjub of the sender represented as point (Ax, Ay)
     * @param tokenId token identifier
     * @param amountF total amount coded as float 16 bits
     */
    function forceWithdraw(
        uint256[2] memory fromBabyPubKey,
        uint32 tokenId,
        uint16 amountF
    ) public payable{
        uint256 totalFee = feeOnchainTx;
        require(msg.value >= totalFee, 'Amount deposited less than fee required');

        leafInfo memory fromLeaf = treeInfo[uint256(keccak256(abi.encodePacked(fromBabyPubKey,tokenId)))];
        require(fromLeaf.ethAddress == msg.sender, 'Sender does not match identifier balance tree');

        // Build txData for withdraw
        bytes32 txDataWithdraw = buildTxData(amountF, tokenId, 0, 0, 0, true, false);
        _updateOnChainHash(uint256(txDataWithdraw), 0, msg.sender, fromBabyPubKey, address(0), [uint256(0),uint256(0)]);

        // Return remaining ether to the msg.sender    
        msg.sender.transfer(msg.value - totalFee);
    }

    /**
     * @dev withdraw on-chain transaction to get balance from balance tree
     * Before this call an off-chain withdraw transaction must be done
     * Off-chain withdraw transaction will build a leaf on exit tree
     * Each batch forged will publish its exit tree root
     * All leaves created on the exit are allowed to call on-chain transaction to finish the withdraw
     * @param amount amount to retrieve
     * @param numExitRoot exit root depth. Number of batch where the withdraw transaction has been done
     * @param siblings siblings to demonstrate merkle tree proofç
     * @param fromBabyPubKey public key babyjubjub of the sender represented as point (Ax, Ay)
     * @param tokenId token identifier
     */
    function withdraw(
        uint256 amount,
        uint256 numExitRoot,
        uint256[] memory siblings,
        uint256[2] memory fromBabyPubKey,
        uint32 tokenId
    ) public {
        // Build 'key' and 'value' for exit tree
        uint256 keyExitTree = getLeafId(fromBabyPubKey, tokenId);
        Entry memory exitEntry = buildTreeState(amount, tokenId, fromBabyPubKey[0],
        fromBabyPubKey[1], msg.sender, 0);
        uint256 valueExitTree = hashEntry(exitEntry);

        // Get exit root given its index depth
        uint256 exitRoot = uint256(getExitRoot(numExitRoot));

        // Check exit tree nullifier
        uint256[] memory inputs = new uint256[](3);
        inputs[0] = valueExitTree;
        inputs[1] = numExitRoot;
        inputs[2] = exitRoot;
        uint256 nullifier = hashGeneric(inputs);
        require(exitNullifier[nullifier] == false, 'withdraw has been already done');

        // Check sparse merkle tree proof
        bool result = smtVerifier(exitRoot, siblings, keyExitTree, valueExitTree, 0, 0, false, false, 24);
        require(result == true, 'invalid proof');

        // Withdraw token from rollup smart contract to ethereum address
        require(withdrawToken(tokenId, msg.sender, amount), 'Fail ERC20 withdraw');

        // Set nullifier
        exitNullifier[nullifier] = true;
    }

    /**
     * @dev Checks proof given by the operator
     * forge a batch if succesfull and pay fees to beneficiary address
     * @param proofA zk-snark input
     * @param proofB zk-snark input
     * @param proofC zk-snark input
     * @param input public zk-snark inputs
     * @param compressedOnChainTx compresssed deposit offchain
     */
    function forgeBatch(
        uint[2] calldata proofA,
        uint[2][2] calldata proofB,
        uint[2] calldata proofC,
        uint[10] calldata input,
        bytes calldata compressedOnChainTx
    ) external payable override virtual isForgeBatch {

        // Verify old state roots
        require(bytes32(input[oldStateRootInput]) == stateRoots[getStateDepth()],
            'old state root does not match current state root');

        // Initial index must be the final index of the last batch
        require(batchToInfo[getStateDepth()].lastLeafIndex == input[initialIdxInput], 'Initial index does not match');

        // Deposits that will be added in this batch
        uint64 depositOffChainLength = uint64(compressedOnChainTx.length/DEPOSIT_BYTES);
        uint32 depositCount = batchToInfo[getStateDepth()+1].depositOnChainCount;

        // Deposit off-chain fee * depositOffchainLength
        uint256 totalFee = depositFee * depositOffChainLength;
        // Operator must pay for every off-chain deposit
        require(msg.value >= totalFee, 'Amount deposited less than fee required');

        // Burn deposit off-chain fee
        address(0).transfer(totalFee);

        // Add deposits off-chain
        for (uint32 i = 0; i < depositOffChainLength; i++) {  
            uint32 initialByte = DEPOSIT_BYTES*i;
            uint256 Ax = abi.decode(compressedOnChainTx[initialByte:initialByte+32], (uint256));
            uint256 Ay = abi.decode(compressedOnChainTx[initialByte+32:initialByte+64], (uint256));
            address ethAddress = address(abi.decode(compressedOnChainTx[initialByte+52:initialByte+84], (uint256)));
            uint32 token = uint32(abi.decode(compressedOnChainTx[initialByte+56:initialByte+88], (uint256)));
            depositCount++;
            depositOffChain(token, ethAddress, [Ax, Ay], depositCount);
        }

        // Update and verify lastLeafIndex
        batchToInfo[getStateDepth()+1].lastLeafIndex = batchToInfo[getStateDepth()].lastLeafIndex + depositCount;
        require(batchToInfo[getStateDepth()+1].lastLeafIndex == input[finalIdxInput], 'Final index does not match');

        // Verify on-chain hash
        require(input[onChainHashInput] == miningOnChainTxsHash,
            'on-chain hash does not match current mining on-chain hash');

        // Verify zk-snark circuit
        require(verifier.verifyProof(proofA, proofB, proofC, input) == true,
            'zk-snark proof is not valid');

        // current batch filling Info
        fillingInfo storage currentFilling = fillingMap[getStateDepth()];

        // Get beneficiary address from zk-inputs 
        address payable beneficiaryAddress = address(input[beneficiaryAddressInput]);

        // Clean fillingOnChainTxsHash an its fees
        uint payOnChainFees = totalMinningOnChainFee;

        miningOnChainTxsHash = currentFilling.fillingOnChainTxsHash;
        totalMinningOnChainFee = currentFilling.totalFillingOnChainFee;

        // If the current state does not match currentFillingBatch means that
        // currentFillingBatch > getStateDepth(), and that batch fees were already updated
        if (getStateDepth() == currentFillingBatch) { 
            feeOnchainTx = updateOnchainFee(currentFilling.currentOnChainTx, feeOnchainTx);
            currentFillingBatch++;
        }
        delete fillingMap[getStateDepth()];

        // Update deposit fee
        depositFee = updateDepositFee(depositCount, depositFee);

        // Update state roots
        stateRoots.push(bytes32(input[newStateRootInput]));

        // Update exit roots
        exitRoots.push(bytes32(input[newExitRootInput]));

        // Calculate fees and pay them
        withdrawTokens(bytes32(input[feePlanCoinsInput]), bytes32(input[feeTotalsInput]),
        beneficiaryAddress);

        // Pay onChain transactions fees and  remaining ether to the msg.sender    
        beneficiaryAddress.transfer(payOnChainFees + msg.value - totalFee);

        // Event with all compressed transactions given its batch number
        emit ForgeBatch(getStateDepth(), block.number);
    }

    /**
     * @dev withdraw all token fees to the beneficiary Address
     * @param coins encoded all the coins that are used in the batch
     * @param totalFees total fee wasted of every coin
     * @param beneficiaryAddress address wich will receive the tokens
     */
    function withdrawTokens(bytes32 coins, bytes32 totalFees, address payable beneficiaryAddress) internal {
        for (uint i = 0; i < 16; i++) {
            (uint32 tokenId, uint256 totalTokenFee) = calcTokenTotalFee(coins, totalFees, i);

            if (totalTokenFee != 0) {
                require(withdrawToken(tokenId, beneficiaryAddress, totalTokenFee),
                    'Fail ERC20 withdraw');
            }
        }
    }

    //////////////
    // Viewers
    /////////////

    /**
     * @dev Retrieve state root given its batch depth
     * @param numBatch batch depth
     * @return root
     */
    function getStateRoot(uint numBatch) public view returns (bytes32) {
        require(numBatch <= stateRoots.length - 1, 'Batch number does not exist');
        return stateRoots[numBatch];
    }

    /**
     * @dev Retrieve total number of batches forged
     * @return Total number of batches forged
     */
    function getStateDepth() public view returns (uint) {
        return stateRoots.length - 1;
    }

    /**
     * @dev Retrieve exit root given its batch depth
     * @param numBatch batch depth
     * @return exit root
     */
    function getExitRoot(uint numBatch) public view returns (bytes32) {
        require(numBatch <= exitRoots.length - 1, 'Batch number does not exist');
        return exitRoots[numBatch];
    }

    /**
     * @dev Retrieve token address from its index
     * @param tokenId token id for rollup smart contract
     * @return token address
     */
    function getTokenAddress(uint tokenId) public view returns (address) {
        require(tokens.length > 0, 'There are no tokens listed');
        require(tokenId <= (tokens.length - 1), 'Token id does not exist');
        return tokenList[tokenId];
    }

    /**
     * @dev Retrieve leafInfo from Babyjub address and tokenID
     * @param fromBabyPubKey public key babyjubjub
     * @param tokenId token ID
     * @return forgedBatch relativeIndex and ethAddress
     */
    function getLeafInfo(uint256[2] memory fromBabyPubKey, uint32 tokenId)
     public view returns(uint64 forgedBatch, uint32 relativeIndex, address ethAddress) {
        leafInfo memory leaf = treeInfo[uint256(keccak256(abi.encodePacked(fromBabyPubKey,tokenId)))];
        return (leaf.forgedBatch, leaf.relativeIndex, leaf.ethAddress);
    }

    /**
     * @dev Retrieve leaf index from Babyjub address and tokenID
     * @param fromBabyPubKey public key babyjubjub
     * @param tokenId token ID
     * @return leaf index
     */
    function getLeafId( uint256[2] memory fromBabyPubKey, uint32 tokenId)
     public view returns (uint64) {
        leafInfo memory leaf = treeInfo[uint256(keccak256(abi.encodePacked(fromBabyPubKey,tokenId)))];
        require(leaf.ethAddress != address(0), 'leaf does not exist');
        if (leaf.forgedBatch == 0)
            return leaf.relativeIndex;
        else {
        require(leaf.forgedBatch-1 <= getStateDepth(), 'batch must be forged');
        return (batchToInfo[leaf.forgedBatch-1].lastLeafIndex + leaf.relativeIndex);
        }
    }

    ///////////
    // helpers ERC20 functions
    ///////////

    /**
     * @dev deposit token to rollup smart contract
     * Previously, it requires an approve erc20 transaction to allow this contract
     * make the transaction for the msg.sender
     * @param tokenId token id
     * @param amount quantity of token to send
     * @return true if succesfull
     */
    function depositToken(uint32 tokenId, uint128 amount) private returns(bool){
        return IERC20(tokenList[tokenId]).transferFrom(msg.sender, address(this), amount);
    }

    /**
     * @dev withdraw token from rollup smart contract
     * Tokens on rollup smart contract are withdrawn
     * @param tokenId token id
     * @param receiver address to receive amount
     * @param amount quantity to withdraw
     * @return true if succesfull
     */
    function withdrawToken(uint32 tokenId, address receiver, uint256 amount) private returns(bool){
        return IERC20(tokenList[tokenId]).transfer(receiver, amount);
    }
}