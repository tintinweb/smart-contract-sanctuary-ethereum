// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

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

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

/**
 * SPDX-License-Identifier: MIT
 */

pragma solidity ^0.8.0;

import "./MultiSigWallet.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

contract MultiSigCloneFactory {

  address immutable public multiSigImplementation;

  event ContractCreated(address indexed contractAddress, string indexed typeName);

  constructor(address _multiSigImplementation) {
    multiSigImplementation = _multiSigImplementation;
  }
  
  function predict(bytes32 salt) external view returns (address) {
    return Clones.predictDeterministicAddress(multiSigImplementation, salt);
  }

  function create(address owner, bytes32 salt) external returns (MultiSigWallet) {
    address payable instance = payable(Clones.cloneDeterministic(multiSigImplementation, salt));
    MultiSigWallet(instance).initialize(owner);
    emit ContractCreated(instance, "MultiSigWallet");
    return MultiSigWallet(instance);
  }
}

/**
 * SPDX-License-Identifier: MIT
 */

pragma solidity ^0.8.0;

import "../utils/Address.sol";
import "../utils/Initializable.sol";
import "./RLPEncode.sol";
import "./Nonce.sol";

/**
 *  Not in use anymore!
 * Documented in ../../doc/multisig.md
 */
contract MultiSigWallet is Nonce, Initializable {

  mapping (address => uint8) public signers; // The addresses that can co-sign transactions and the number of signatures needed

  uint16 public signerCount;
  bytes public contractId; // most likely unique id of this contract

  event SignerChange(
    address indexed signer,
    uint8 signaturesNeeded
  );

  event Transacted(
    address indexed toAddress,  // The address the transaction was sent to
    bytes4 selector, // selected operation
    address[] signers // Addresses of the signers used to initiate the transaction
  );

  event Received(address indexed sender, uint amount);

  function initialize(address owner) external initializer {
    // We use the gas price field to get a unique id into our transactions.
    // Note that 32 bits do not guarantee that no one can generate a contract with the
    // same id, but it practically rules out that someone accidentally creates two
    // two multisig contracts with the same id, and that's all we need to prevent
    // replay-attacks.
    contractId = toBytes(uint32(uint160(address(this))));
    signerCount = 0;
    _setSigner(owner, 1); // set initial owner
  }

  /**
   * It should be possible to store ether on this address.
   */
  receive() external payable {
    emit Received(msg.sender, msg.value);
  }

  /**
   * Checks if the provided signatures suffice to sign the transaction and if the nonce is correct.
   */
  function checkSignatures(uint128 nonce, address to, uint value, bytes calldata data,
    uint8[] calldata v, bytes32[] calldata r, bytes32[] calldata s) external view returns (address[] memory) {
    bytes32 transactionHash = calculateTransactionHash(nonce, contractId, to, value, data);
    return verifySignatures(transactionHash, v, r, s);
  }

  /**
   * Checks if the execution of a transaction would succeed if it was properly signed.
   */
  function checkExecution(address to, uint value, bytes calldata data) external {
    Address.functionCallWithValue(to, data, value);
    revert("Test passed. Reverting.");
  }

  function execute(uint128 nonce, address to, uint value, bytes calldata data, uint8[] calldata v, bytes32[] calldata r, bytes32[] calldata s) external returns (bytes memory) {
    bytes32 transactionHash = calculateTransactionHash(nonce, contractId, to, value, data);
    address[] memory found = verifySignatures(transactionHash, v, r, s);
    bytes memory returndata = Address.functionCallWithValue(to, data, value);
    flagUsed(nonce);
    emit Transacted(to, extractSelector(data), found);
    return returndata;
  }

  function extractSelector(bytes calldata data) private pure returns (bytes4){
    if (data.length < 4){
      return bytes4(0);
    } else {
      return bytes4(data[0]) | (bytes4(data[1]) >> 8) | (bytes4(data[2]) >> 16) | (bytes4(data[3]) >> 24);
    }
  }

  function toBytes(uint number) internal pure returns (bytes memory){
    uint len = 0;
    uint temp = 1;
    while (number >= temp){
      temp = temp << 8;
      len++;
    }
    temp = number;
    bytes memory data = new bytes(len);
    for (uint i = len; i>0; i--) {
      data[i-1] = bytes1(uint8(temp));
      temp = temp >> 8;
    }
    return data;
  }

  // Note: does not work with contract creation
  function calculateTransactionHash(uint128 sequence, bytes memory id, address to, uint value, bytes calldata data)
    internal view returns (bytes32){
    bytes[] memory all = new bytes[](9);
    all[0] = toBytes(sequence); // sequence number instead of nonce
    all[1] = id; // contract id instead of gas price
    all[2] = toBytes(21000); // gas limit
    all[3] = abi.encodePacked(to);
    all[4] = toBytes(value);
    all[5] = data;
    all[6] = toBytes(block.chainid);
    all[7] = toBytes(0);
    for (uint i = 0; i<8; i++){
      all[i] = RLPEncode.encodeBytes(all[i]);
    }
    all[8] = all[7];
    return keccak256(RLPEncode.encodeList(all));
  }

  function verifySignatures(bytes32 transactionHash, uint8[] calldata v, bytes32[] calldata r, bytes32[] calldata s)
    public view returns (address[] memory) {
    address[] memory found = new address[](r.length);
    require(r.length > 0, "sig missing");
    for (uint i = 0; i < r.length; i++) {
      address signer = ecrecover(transactionHash, v[i], r[i], s[i]);
      uint8 signaturesNeeded = signers[signer];
      require(signaturesNeeded > 0 && signaturesNeeded <= r.length, "cosigner error");
      found[i] = signer;
    }
    requireNoDuplicates(found);
    return found;
  }

  function requireNoDuplicates(address[] memory found) private pure {
    for (uint i = 0; i < found.length; i++) {
      for (uint j = i+1; j < found.length; j++) {
        require(found[i] != found[j], "duplicate signature");
      }
    }
  }

  /**
   * Call this method through execute
   */
  function setSigner(address signer, uint8 signaturesNeeded) external authorized {
    _setSigner(signer, signaturesNeeded);
    require(signerCount > 0, "signer count 0");
  }

  function migrate(address destination) external {
    _migrate(msg.sender, destination);
  }

  function migrate(address source, address destination) external authorized {
    _migrate(source, destination);
  }

  function _migrate(address source, address destination) private {
    require(signers[destination] == 0, "destination not new"); // do not overwrite existing signer!
    _setSigner(destination, signers[source]);
    _setSigner(source, 0);
  }

  function _setSigner(address signer, uint8 signaturesNeeded) private {
    require(!Address.isContract(signer), "signer cannot be a contract");
    require(signer != address(0x0), "0x0 signer");
    uint8 prevValue = signers[signer];
    signers[signer] = signaturesNeeded;
    if (prevValue > 0 && signaturesNeeded == 0){
      signerCount--;
    } else if (prevValue == 0 && signaturesNeeded > 0){
      signerCount++;
    }
    emit SignerChange(signer, signaturesNeeded);
  }

  modifier authorized() {
    require(address(this) == msg.sender || signers[msg.sender] == 1, "not authorized");
    _;
  }

}

/**
* SPDX-License-Identifier: LicenseRef-Aktionariat
*
* MIT License with Automated License Fee Payments
*
* Copyright (c) 2020 Aktionariat AG (aktionariat.com)
*
* Permission is hereby granted to any person obtaining a copy of this software
* and associated documentation files (the "Software"), to deal in the Software
* without restriction, including without limitation the rights to use, copy,
* modify, merge, publish, distribute, sublicense, and/or sell copies of the
* Software, and to permit persons to whom the Software is furnished to do so,
* subject to the following conditions:
*
* - The above copyright notice and this permission notice shall be included in
*   all copies or substantial portions of the Software.
* - All automated license fee payments integrated into this and related Software
*   are preserved.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/
pragma solidity ^0.8.0;

contract Nonce {

    uint256 public constant MAX_INCREASE = 100;
    
    uint256 private compound;
    
    constructor(){
        setBoth(128, 0);
    }
    
    /**
     * The next recommended nonce, which is the highest nonce ever used plus one.
     * The initial nonce is 129.
     */
    function nextNonce() external view returns (uint128){
        return getMax() + 1;
    }

    /**
     * Returns whether the provided nonce can be used.
     * For the 100 nonces in the interval [nextNonce(), nextNonce + 99], this is always true.
     * For the nonces in the interval [nextNonce() - 129, nextNonce() - 1], this is true for the nonces that have not been used yet.
     */ 
    function isFree(uint128 nonce) external view returns (bool){
        uint128 max = getMax();
        return isValidHighNonce(max, nonce) || isValidLowNonce(max, getRegister(), nonce);
    }

    /**
     * Flags the given nonce as used.
     * Reverts if the provided nonce is not free.
     */
    function flagUsed(uint128 nonce) internal {
        uint256 comp = compound;
        uint128 max = uint128(comp);
        uint128 reg = uint128(comp >> 128);
        if (isValidHighNonce(max, nonce)){
            setBoth(nonce, ((reg << 1) | 0x1) << (nonce - max - 1));
        } else if (isValidLowNonce(max, reg, nonce)){
            setBoth(max, uint128(reg | 0x1 << (max - nonce - 1)));
        } else {
            revert("used");
        }
    }
    
    function getMax() private view returns (uint128) {
        return uint128(compound);
    }
    
    function getRegister() private view returns (uint128) {
        return uint128(compound >> 128);
    }
    
    function setBoth(uint128 max, uint128 reg) private {
        compound = uint256(reg) << 128 | max;
    }

    function isValidHighNonce(uint128 max, uint128 nonce) private pure returns (bool){
        return nonce > max && nonce <= max + MAX_INCREASE;
    }

    function isValidLowNonce(uint128 max, uint128 reg, uint128 nonce) private pure returns (bool){
        uint256 diff = max - nonce;
        return diff > 0 && diff <= 128 && ((0x1 << (diff - 1)) & reg == 0);
    }
    
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
/**
 * @title RLPEncode
 * @dev A simple RLP encoding library.
 * @author Bakaoh
 */
library RLPEncode {
    /*
     * Internal functions
     */

    /**
     * @dev RLP encodes a byte string.
     * @param self The byte string to encode.
     * @return The RLP encoded string in bytes.
     */
    function encodeBytes(bytes memory self) internal pure returns (bytes memory) {
        bytes memory encoded;
        if (self.length == 1 && uint8(self[0]) < 128) {
            encoded = self;
        } else {
            encoded = abi.encodePacked(encodeLength(self.length, 128), self);
        }
        return encoded;
    }

    /**
     * @dev RLP encodes a list of RLP encoded byte byte strings.
     * @param self The list of RLP encoded byte strings.
     * @return The RLP encoded list of items in bytes.
     */
    function encodeList(bytes[] memory self) internal pure returns (bytes memory) {
        bytes memory list = flatten(self);
        return abi.encodePacked(encodeLength(list.length, 192), list);
    }

    /*
     * Private functions
     */

    /**
     * @dev Encode the first byte, followed by the `len` in binary form if `length` is more than 55.
     * @param len The length of the string or the payload.
     * @param offset 128 if item is string, 192 if item is list.
     * @return RLP encoded bytes.
     */
    function encodeLength(uint len, uint offset) private pure returns (bytes memory) {
        bytes memory encoded;
        if (len < 56) {
            encoded = new bytes(1);
            encoded[0] = bytes32(len + offset)[31];
        } else {
            uint lenLen;
            uint i = 1;
            while (len >= i) {
                lenLen++;
                i <<= 8;
            }

            encoded = new bytes(lenLen + 1);
            encoded[0] = bytes32(lenLen + offset + 55)[31];
            for(i = 1; i <= lenLen; i++) {
                encoded[i] = bytes32((len / (256**(lenLen-i))) % 256)[31];
            }
        }
        return encoded;
    }

    /**
     * @dev Copies a piece of memory to another location.
     * @notice From: https://github.com/Arachnid/solidity-stringutils/blob/master/src/strings.sol.
     * @param _dest Destination location.
     * @param _src Source location.
     * @param _len Length of memory to copy.
     */
    function memcpy(uint _dest, uint _src, uint _len) private pure {
        uint dest = _dest;
        uint src = _src;
        uint len = _len;

        for(; len >= 32; len -= 32) {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        uint mask = type(uint).max >> (len << 3);
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }

    /**
     * @dev Flattens a list of byte strings into one byte string.
     * @notice From: https://github.com/sammayo/solidity-rlp-encoder/blob/master/RLPEncode.sol.
     * @param _list List of byte strings to flatten.
     * @return The flattened byte string.
     */
    function flatten(bytes[] memory _list) private pure returns (bytes memory) {
        if (_list.length == 0) {
            return new bytes(0);
        }

        uint len;
        uint i;
        for (i = 0; i < _list.length; i++) {
            len += _list[i].length;
        }

        bytes memory flattened = new bytes(len);
        uint flattenedPtr;
        // solhint-disable-next-line no-inline-assembly
        assembly { flattenedPtr := add(flattened, 0x20) }

        for(i = 0; i < _list.length; i++) {
            bytes memory item = _list[i];
            
            uint listPtr;
            // solhint-disable-next-line no-inline-assembly
            assembly { listPtr := add(item, 0x20)}

            memcpy(flattenedPtr, listPtr, item.length);
            flattenedPtr += item.length;
        }

        return flattened;
    }

}

// SPDX-License-Identifier: MIT
// Copied from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol
// and modified it.

pragma solidity ^0.8.0;

library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.
        return account.code.length > 0;
    }

    function functionCallWithValue(address target, bytes memory data, uint256 weiValue) internal returns (bytes memory) {
        require(data.length == 0 || isContract(target), "transfer or contract");
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else if (returndata.length > 0) {
            assembly{
                revert (add (returndata, 0x20), mload (returndata))
            }
        } else {
           revert("failed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Modifier to protect the initializer function from being invoked twice.
     */
    modifier initializer() {
        require(!_initialized, "already initialized");
        _;
        _initialized = true;
    }

}