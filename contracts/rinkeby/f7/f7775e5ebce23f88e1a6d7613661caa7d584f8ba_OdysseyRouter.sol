/**
 *Submitted for verification at Etherscan.io on 2022-04-09
*/

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.12;

/// @notice Read and write to persistent storage at a fraction of the cost.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SSTORE2.sol)
/// @author Modified from 0xSequence (https://github.com/0xSequence/sstore2/blob/master/contracts/SSTORE2.sol)
library SSTORE2 {
    uint256 internal constant DATA_OFFSET = 1; // We skip the first byte as it's a STOP opcode to ensure the contract can't be called.

    /*///////////////////////////////////////////////////////////////
                               WRITE LOGIC
    //////////////////////////////////////////////////////////////*/

    function write(bytes memory data) internal returns (address pointer) {
        // Prefix the bytecode with a STOP opcode to ensure it cannot be called.
        bytes memory runtimeCode = abi.encodePacked(hex"00", data);

        bytes memory creationCode = abi.encodePacked(
            //---------------------------------------------------------------------------------------------------------------//
            // Opcode  | Opcode + Arguments  | Description  | Stack View                                                     //
            //---------------------------------------------------------------------------------------------------------------//
            // 0x60    |  0x600B             | PUSH1 11     | codeOffset                                                     //
            // 0x59    |  0x59               | MSIZE        | 0 codeOffset                                                   //
            // 0x81    |  0x81               | DUP2         | codeOffset 0 codeOffset                                        //
            // 0x38    |  0x38               | CODESIZE     | codeSize codeOffset 0 codeOffset                               //
            // 0x03    |  0x03               | SUB          | (codeSize - codeOffset) 0 codeOffset                           //
            // 0x80    |  0x80               | DUP          | (codeSize - codeOffset) (codeSize - codeOffset) 0 codeOffset   //
            // 0x92    |  0x92               | SWAP3        | codeOffset (codeSize - codeOffset) 0 (codeSize - codeOffset)   //
            // 0x59    |  0x59               | MSIZE        | 0 codeOffset (codeSize - codeOffset) 0 (codeSize - codeOffset) //
            // 0x39    |  0x39               | CODECOPY     | 0 (codeSize - codeOffset)                                      //
            // 0xf3    |  0xf3               | RETURN       |                                                                //
            //---------------------------------------------------------------------------------------------------------------//
            hex"60_0B_59_81_38_03_80_92_59_39_F3", // Returns all code in the contract except for the first 11 (0B in hex) bytes.
            runtimeCode // The bytecode we want the contract to have after deployment. Capped at 1 byte less than the code size limit.
        );

        assembly {
            // Deploy a new contract with the generated creation code.
            // We start 32 bytes into the code to avoid copying the byte length.
            pointer := create(0, add(creationCode, 32), mload(creationCode))
        }

        require(pointer != address(0), "DEPLOYMENT_FAILED");
    }

    /*///////////////////////////////////////////////////////////////
                               READ LOGIC
    //////////////////////////////////////////////////////////////*/

    function read(address pointer) internal view returns (bytes memory) {
        return
            readBytecode(
                pointer,
                DATA_OFFSET,
                pointer.code.length - DATA_OFFSET
            );
    }

    function read(address pointer, uint256 start)
        internal
        view
        returns (bytes memory)
    {
        start += DATA_OFFSET;

        return readBytecode(pointer, start, pointer.code.length - start);
    }

    function read(
        address pointer,
        uint256 start,
        uint256 end
    ) internal view returns (bytes memory) {
        start += DATA_OFFSET;
        end += DATA_OFFSET;

        require(pointer.code.length >= end, "OUT_OF_BOUNDS");

        return readBytecode(pointer, start, end - start);
    }

    /*///////////////////////////////////////////////////////////////
                         INTERNAL HELPER LOGIC
    //////////////////////////////////////////////////////////////*/

    function readBytecode(
        address pointer,
        uint256 start,
        uint256 size
    ) private view returns (bytes memory data) {
        assembly {
            // Get a pointer to some free memory.
            data := mload(0x40)

            // Update the free memory pointer to prevent overriding our data.
            // We use and(x, not(31)) as a cheaper equivalent to sub(x, mod(x, 32)).
            // Adding 31 to size and running the result through the logic above ensures
            // the memory pointer remains word-aligned, following the Solidity convention.
            mstore(0x40, add(data, and(add(add(size, 32), 31), not(31))))

            // Store the size of the data in the first 32 byte chunk of free memory.
            mstore(data, size)

            // Copy the code into memory right after the 32 bytes we used to store the size.
            extcodecopy(pointer, add(data, 32), start, size)
        }
    }
}

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private locked = 1;

    modifier nonReentrant() {
        require(locked == 1, "REENTRANCY");

        locked = 2;

        _;

        locked = 1;
    }
}

//todo remove OZ string
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

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
    function toHexString(uint256 value, uint256 length)
        internal
        pure
        returns (string memory)
    {
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

/// @title Interface for verifying contract-based account signatures
/// @notice Interface that verifies provided signature for the data
/// @dev Interface defined by EIP-1271
interface IERC1271 {
    /// @notice Returns whether the provided signature is valid for the provided data
    /// @dev MUST return the bytes4 magic value 0x1626ba7e when function passes.
    /// MUST NOT modify state (using STATICCALL for solc < 0.5, view modifier for solc > 0.5).
    /// MUST allow external calls.
    /// @param hash Hash of the data to be signed
    /// @param signature Signature byte array associated with _data
    /// @return magicValue The bytes4 magic value 0x1626ba7e
    function isValidSignature(bytes32 hash, bytes memory signature)
        external
        view
        returns (bytes4 magicValue);
}

// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

/**
 * @dev Collection of functions related to the address type
 */
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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

library Signature {
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(
            uint256(s) <=
                0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
            "ODYSSEY: INVALID_SIGNATURE_S_VALUE"
        );
        require(v == 27 || v == 28, "ODYSSEY: INVALID_SIGNATURE_V_VALUE");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ODYSSEY: INVALID_SIGNATURE");

        return signer;
    }

    function verify(
        bytes32 hash,
        address signer,
        uint8 v,
        bytes32 r,
        bytes32 s,
        bytes32 domainSeparator
    ) internal view {
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, hash)
        );
        if (Address.isContract(signer)) {
            require(
                IERC1271(signer).isValidSignature(
                    digest,
                    abi.encodePacked(r, s, v)
                ) == 0x1626ba7e,
                "ODYSSEY: UNAUTHORIZED"
            );
        } else {
            require(
                recover(digest, v, r, s) == signer,
                "ODYSSEY: UNAUTHORIZED"
            );
        }
    }
}

// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/MerkleProof.sol)

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
    function processProof(bytes32[] memory proof, bytes32 leaf)
        internal
        pure
        returns (bytes32)
    {
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

    function _efficientHash(bytes32 a, bytes32 b)
        private
        pure
        returns (bytes32 value)
    {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

library MerkleWhiteList {
    function verify(
        address sender,
        bytes32[] calldata merkleProof,
        bytes32 merkleRoot
    ) internal pure {
        // Verify whitelist
        require(address(0) != sender);
        bytes32 leaf = keccak256(abi.encodePacked(sender));
        require(
            MerkleProof.verify(merkleProof, merkleRoot, leaf),
            "Not whitelisted"
        );
    }
}

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );

    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*///////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*///////////////////////////////////////////////////////////////
                             EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    bytes32 public constant PERMIT_TYPEHASH =
        keccak256(
            "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
        );

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*///////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*///////////////////////////////////////////////////////////////
                              ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount)
        public
        virtual
        returns (bool)
    {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount)
        public
        virtual
        returns (bool)
    {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max)
            allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*///////////////////////////////////////////////////////////////
                              EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            bytes32 digest = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    keccak256(
                        abi.encode(
                            PERMIT_TYPEHASH,
                            owner,
                            spender,
                            value,
                            nonces[owner]++,
                            deadline
                        )
                    )
                )
            );

            address recoveredAddress = ecrecover(digest, v, r, s);

            require(
                recoveredAddress != address(0) && recoveredAddress == owner,
                "INVALID_SIGNER"
            );

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return
            block.chainid == INITIAL_CHAIN_ID
                ? INITIAL_DOMAIN_SEPARATOR
                : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256(
                        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                    ),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
/// @dev Note that balanceOf does not revert if passed the zero address, in defiance of the ERC.
abstract contract ERC721 {
    /*///////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed id
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 indexed id
    );

    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    /*///////////////////////////////////////////////////////////////
                          METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*///////////////////////////////////////////////////////////////
                            ERC721 STORAGE                        
    //////////////////////////////////////////////////////////////*/

    mapping(address => uint256) public balanceOf;

    mapping(uint256 => address) public ownerOf;

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*///////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*///////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = ownerOf[id];

        require(
            msg.sender == owner || isApprovedForAll[owner][msg.sender],
            "NOT_AUTHORIZED"
        );

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        require(from == ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from ||
                msg.sender == getApproved[id] ||
                isApprovedForAll[from][msg.sender],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            balanceOf[from]--;

            balanceOf[to]++;
        }

        ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(
                    msg.sender,
                    from,
                    id,
                    ""
                ) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes memory data
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(
                    msg.sender,
                    from,
                    id,
                    data
                ) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*///////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId)
        public
        pure
        virtual
        returns (bool)
    {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            balanceOf[to]++;
        }

        ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = ownerOf[id];

        require(ownerOf[id] != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            balanceOf[owner]--;
        }

        delete ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(
                    msg.sender,
                    address(0),
                    id,
                    ""
                ) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(
                    msg.sender,
                    address(0),
                    id,
                    data
                ) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
interface ERC721TokenReceiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 id,
        bytes calldata data
    ) external returns (bytes4);
}

library UInt2Str {
    function uint2str(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}

contract OdysseyERC721 is ERC721("", "") {
    using UInt2Str for uint256;

    /*///////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/
    address launcher;
    bool initialized;
    string public baseURI;

    /*///////////////////////////////////////////////////////////////
                              METADATA LOGIC
    //////////////////////////////////////////////////////////////*/

    function tokenURI(uint256 id)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return string(abi.encodePacked(baseURI, id.uint2str()));
    }

    /*///////////////////////////////////////////////////////////////
                              FACTORY LOGIC
    //////////////////////////////////////////////////////////////*/

    function initialize(
        address _launcher,
        string calldata _name,
        string calldata _symbol,
        string calldata _baseURI
    ) external {
        require(!initialized, "");
        initialized = true;
        launcher = _launcher;
        name = _name;
        symbol = _symbol;
        baseURI = _baseURI;
    }

    /*///////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function mint(address user, uint256 id) external {
        require(msg.sender == launcher, "OdysseyERC721: Auth"); //todo allow owner to mint
        _mint(user, id);
    }
}

/// @notice Minimalist and gas efficient standard ERC1155 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155 {
    /*///////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 amount
    );

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] amounts
    );

    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    event URI(string value, uint256 indexed id);

    /*///////////////////////////////////////////////////////////////
                            ERC1155 STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(address => mapping(uint256 => uint256)) public balanceOf;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*///////////////////////////////////////////////////////////////
                             METADATA LOGIC
    //////////////////////////////////////////////////////////////*/

    function uri(uint256 id) public view virtual returns (string memory);

    /*///////////////////////////////////////////////////////////////
                             ERC1155 LOGIC
    //////////////////////////////////////////////////////////////*/

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual {
        require(
            msg.sender == from || isApprovedForAll[from][msg.sender],
            "NOT_AUTHORIZED"
        );

        balanceOf[from][id] -= amount;
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, from, to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(
                    msg.sender,
                    from,
                    id,
                    amount,
                    data
                ) == ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        require(
            msg.sender == from || isApprovedForAll[from][msg.sender],
            "NOT_AUTHORIZED"
        );

        for (uint256 i = 0; i < idsLength; ) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            balanceOf[from][id] -= amount;
            balanceOf[to][id] += amount;

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                i++;
            }
        }

        emit TransferBatch(msg.sender, from, to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(
                    msg.sender,
                    from,
                    ids,
                    amounts,
                    data
                ) == ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function balanceOfBatch(address[] memory owners, uint256[] memory ids)
        public
        view
        virtual
        returns (uint256[] memory balances)
    {
        uint256 ownersLength = owners.length; // Saves MLOADs.

        require(ownersLength == ids.length, "LENGTH_MISMATCH");

        balances = new uint256[](owners.length);

        // Unchecked because the only math done is incrementing
        // the array index counter which cannot possibly overflow.
        unchecked {
            for (uint256 i = 0; i < ownersLength; i++) {
                balances[i] = balanceOf[owners[i]][ids[i]];
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId)
        public
        pure
        virtual
        returns (bool)
    {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0xd9b67a26 || // ERC165 Interface ID for ERC1155
            interfaceId == 0x0e89341c; // ERC165 Interface ID for ERC1155MetadataURI
    }

    /*///////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal {
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, address(0), to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(
                    msg.sender,
                    address(0),
                    id,
                    amount,
                    data
                ) == ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchMint(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[to][ids[i]] += amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                i++;
            }
        }

        emit TransferBatch(msg.sender, address(0), to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(
                    msg.sender,
                    address(0),
                    ids,
                    amounts,
                    data
                ) == ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchBurn(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[from][ids[i]] -= amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                i++;
            }
        }

        emit TransferBatch(msg.sender, from, address(0), ids, amounts);
    }

    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal {
        balanceOf[from][id] -= amount;

        emit TransferSingle(msg.sender, from, address(0), id, amount);
    }
}

/// @notice A generic interface for a contract which properly accepts ERC1155 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC1155.sol)
interface ERC1155TokenReceiver {
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external returns (bytes4);

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external returns (bytes4);
}

contract OdysseyERC1155 is ERC1155 {
    using UInt2Str for uint256;

    /*///////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/
    address launcher;
    string public name;
    string public symbol;
    string public baseURI;
    bool initialized;

    /*///////////////////////////////////////////////////////////////
                             METADATA LOGIC
    //////////////////////////////////////////////////////////////*/

    function uri(uint256 id)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return string(abi.encodePacked(baseURI, id.uint2str()));
    }

    /*///////////////////////////////////////////////////////////////
                              FACTORY LOGIC
    //////////////////////////////////////////////////////////////*/

    function initialize(
        address _launcher,
        string calldata _name,
        string calldata _symbol,
        string calldata _baseURI
    ) external onlyOnce {
        initialized = true;
        launcher = _launcher;
        name = _name;
        symbol = _symbol;
        baseURI = _baseURI;
    }

    modifier onlyOnce() {
        require(!initialized, "OdysseyERC1155: Already Initialized");
        _;
    }

    /*///////////////////////////////////////////////////////////////
                              ERC1155 LOGIC
    //////////////////////////////////////////////////////////////*/

    function mint(address user, uint256 id) external {
        require(msg.sender == launcher, "OdysseyERC1155: Auth");
        _mint(user, id, 1, "");
    }

    function mintBatch(
        address user,
        uint256 id,
        uint256 amount
    ) external {
        require(msg.sender == launcher, "OdysseyERC1155: Auth");
        _mint(user, id, amount, "");
    }
}

//todo remove OZ string

contract OdysseyTokenFactory {
    /*///////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event TokenCreated(
        string indexed name,
        string indexed symbol,
        address addr,
        bool isERC721,
        uint256 length
    );

    /*///////////////////////////////////////////////////////////////
                            FACTORY STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(string => mapping(string => address)) public getToken;
    mapping(address => uint256) public tokenExists;
    address[] public allTokens;

    /*///////////////////////////////////////////////////////////////
                            FACTORY LOGIC
    //////////////////////////////////////////////////////////////*/

    function allTokensLength() external view returns (uint256) {
        return allTokens.length;
    }

    function create1155(
        string calldata name,
        string calldata symbol,
        string calldata baseURI
    ) external returns (address token) {
        require(
            getToken[name][symbol] == address(0),
            "OdysseyTokenFactory: TOKEN_EXISTS"
        );
        bytes memory bytecode = type(OdysseyERC1155).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(name, symbol));
        assembly {
            token := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        getToken[name][symbol] = token;
        tokenExists[token] = 1;
        // Run the proper initialize function
        OdysseyERC1155(token).initialize(
            msg.sender,
            name,
            symbol,
            string(
                abi.encodePacked(
                    baseURI,
                    Strings.toString(block.chainid),
                    "/",
                    Strings.toHexString(uint160(token)),
                    "/"
                )
            )
        );
        emit TokenCreated(name, symbol, token, false, allTokens.length);
        return token;
    }

    function create721(
        string calldata name,
        string calldata symbol,
        string calldata baseURI
    ) external returns (address token) {
        require(
            getToken[name][symbol] == address(0),
            "OdysseyTokenFactory: TOKEN_EXISTS"
        );
        bytes memory bytecode = type(OdysseyERC721).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(name, symbol));
        assembly {
            token := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        getToken[name][symbol] = token;
        tokenExists[token] = 1;
        // Run the proper initialize function
        OdysseyERC721(token).initialize(
            msg.sender,
            name,
            symbol,
            string(
                abi.encodePacked(
                    baseURI,
                    Strings.toString(block.chainid),
                    "/",
                    Strings.toHexString(uint160(token)),
                    "/"
                )
            )
        );
        emit TokenCreated(name, symbol, token, true, allTokens.length);
    }
}

abstract contract OdysseyDatabase {
    // Constants
    // keccak256("whitelistMint721(bytes32 merkleRoot,uint256 minPrice,address tokenAddress,address currency)").toString('hex')
    bytes32 public constant MERKLE_TREE_ROOT_ERC721_TYPEHASH =
        0x39b705530d4e5e0832221e2b2f1eb479e5ce7a7c53f9ddb8cdf523a3f511fff1;
    // keccak256("mint721(bytes32 merkleRoot,uint256 minPrice,address tokenAddress,address currency)").toString('hex')
    bytes32 public constant MIN_PRICE_ERC721_TYPEHASH =
        0x374016efc5db2688404aa73bfbdf0547040aed3400697281aaa0f8f3fde5050e;
    // keccak256("whitelistMint1155(bytes32 merkleRoot,uint256 minPrice,uint256 tokenId,address tokenAddress,address currency)").toString('hex')
    bytes32 public constant MERKLE_TREE_ROOT_ERC1155_TYPEHASH =
        0xc3b84f8653cb95f59a9d2637ec1a199bea006a12945eefc56fd75299a20203f9;
    // keccak256("mint1155(bytes32 merkleRoot,uint256 minPrice,uint256 tokenId,address tokenAddress,address currency)").toString('hex')
    bytes32 public constant MIN_PRICE_ERC1155_TYPEHASH =
        0xc81689ff3c6089d3f11f121b6b0d23d0a3fb648eaeef7ecdcf2bcf2638fb60c1;

    // Def understand this before writing code:
    // https://docs.soliditylang.org/en/v0.8.12/internals/layout_in_storage.html
    //--------------------------------------------------------------------------------//
    // Slot       |  Type                  | Description                              //
    //--------------------------------------------------------------------------------//
    // 0x00       |  address               | OdysseyLaunchPlatform.sol                //
    // 0x01       |  address               | OdysseyExchange.sol                      //
    // 0x02       |  address               | OdysseyTokenFactory.sol                  //
    //--------------------------------------------------------------------------------//
    // Slot storage
    address launchPlatform; // slot 0
    address baseExchange; // slot1
    address factory; // slot2

    // Common Storage
    mapping(address => bytes32) public domainSeparator;
    mapping(address => uint256) public whitelistActive;
    mapping(address => address) public ownerOf;
    // ERC721 Storage
    mapping(address => mapping(address => uint256)) public whitelistClaimed721;
    mapping(address => mapping(address => uint256)) public isReserved721;
    mapping(address => uint256) public cumulativeSupply721;
    mapping(address => uint256) public mintedSupply721;
    mapping(address => uint256) public maxSupply721;
    // ERC1155 Storage
    mapping(address => mapping(address => mapping(uint256 => uint256)))
        public whitelistClaimed1155;
    mapping(address => mapping(address => mapping(uint256 => uint256)))
        public isReserved1155;
    mapping(address => mapping(uint256 => uint256)) public cumulativeSupply1155;
    mapping(address => mapping(uint256 => uint256)) public maxSupply1155;

    function writeAddress(uint256 slot, address value) public {
        assembly {
            sstore(slot, value)
        }
    }

    function writeUint256(uint256 slot, uint256 value) public {
        assembly {
            sstore(slot, value)
        }
    }

    function readSlotAsAddress(uint256 slot)
        public
        view
        returns (address data)
    {
        assembly {
            data := sload(slot)
        }
    }
}

contract OdysseyLaunchPlatform is OdysseyDatabase, ReentrancyGuard {
    //todo take payment properly
    function mintERC721(
        bytes32[] calldata merkleProof,
        bytes32 merkleRoot,
        uint256 minPrice,
        address tokenAddress,
        address currency,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable nonReentrant {
        require(
            OdysseyTokenFactory(factory).tokenExists(tokenAddress) == 1,
            "OdysseyLaunchPlatform: Token does not exist"
        );
        require(
            whitelistClaimed721[tokenAddress][msg.sender] == 0,
            "OdysseyLaunchPlatform: Already claimed"
        );
        // Check if user is already reserved + paid
        if (isReserved721[tokenAddress][msg.sender] == 0) {
            require(
                cumulativeSupply721[tokenAddress] < maxSupply721[tokenAddress],
                "OdysseyLaunchPlatform: Max Supply Cap"
            );
            /*require( // todo add this back if currency address is 0 to pay with eth
                msg.value >= minPrice,
                "OdysseyLaunchPlatform: Insufficient funds"
            );*/
            if (whitelistActive[tokenAddress] == 1) {
                // Verify merkle root and minPrice signed by owner (all id's have same min price)
                bytes32 hash = keccak256(
                    abi.encode(
                        MERKLE_TREE_ROOT_ERC721_TYPEHASH,
                        merkleRoot,
                        minPrice,
                        tokenAddress,
                        currency
                    )
                );
                //todo include name + symbol in sig verify
                Signature.verify(
                    hash,
                    ownerOf[tokenAddress],
                    v,
                    r,
                    s,
                    domainSeparator[tokenAddress]
                );
                // Verify user whitelisted
                MerkleWhiteList.verify(msg.sender, merkleProof, merkleRoot);
            } else {
                // verify min price
                bytes32 hash = keccak256(
                    abi.encode(
                        MIN_PRICE_ERC721_TYPEHASH,
                        minPrice,
                        tokenAddress,
                        currency
                    )
                );
                Signature.verify(
                    hash,
                    ownerOf[tokenAddress],
                    v,
                    r,
                    s,
                    domainSeparator[tokenAddress]
                );
            }
            cumulativeSupply721[tokenAddress]++;
            ERC20(currency).transferFrom(
                msg.sender,
                ownerOf[tokenAddress],
                minPrice
            ); //todo prevent repeated reads from storage, copy to memory maybe
        }
        // Update State
        whitelistClaimed721[tokenAddress][msg.sender] = 1;
        OdysseyERC721(tokenAddress).mint(
            msg.sender,
            mintedSupply721[tokenAddress]++
        );
    }

    function reserveERC721(
        bytes32[] calldata merkleProof,
        bytes32 merkleRoot,
        uint256 minPrice,
        address tokenAddress,
        address currency,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable nonReentrant {
        require(
            OdysseyTokenFactory(factory).tokenExists(tokenAddress) == 1,
            "OdysseyLaunchPlatform: Token does not exist"
        );
        require(
            cumulativeSupply721[tokenAddress] < maxSupply721[tokenAddress],
            "OdysseyLaunchPlatform: Max Supply"
        );
        require(
            isReserved721[tokenAddress][msg.sender] == 0,
            "OdysseyLaunchPlatform: Already reserved"
        );
        require(
            whitelistClaimed721[tokenAddress][msg.sender] == 0,
            "OdysseyLaunchPlatform: Already claimed"
        );
        /*equire(
            msg.value >= minPrice,
            "OdysseyLaunchPlatform: Insufficient funds"
        );*/
        if (whitelistActive[tokenAddress] == 1) {
            // Verify merkle root and minPrice signed by owner (all id's have same min price)
            bytes32 hash = keccak256(
                abi.encode(
                    MERKLE_TREE_ROOT_ERC721_TYPEHASH,
                    merkleRoot,
                    minPrice,
                    tokenAddress,
                    currency
                )
            );
            Signature.verify(
                hash,
                ownerOf[tokenAddress],
                v,
                r,
                s,
                domainSeparator[tokenAddress]
            );
            // Verify user whitelisted
            MerkleWhiteList.verify(msg.sender, merkleProof, merkleRoot);
        } else {
            // verify min price
            bytes32 hash = keccak256(
                abi.encode(
                    MIN_PRICE_ERC721_TYPEHASH,
                    minPrice,
                    tokenAddress,
                    currency
                )
            );
            Signature.verify(
                hash,
                ownerOf[tokenAddress],
                v,
                r,
                s,
                domainSeparator[tokenAddress]
            );
        }
        ERC20(currency).transferFrom(
            msg.sender,
            ownerOf[tokenAddress],
            minPrice
        );
        // Set user is reserved
        isReserved721[tokenAddress][msg.sender] = 1;
        // Increate Reserved + minted supply
        cumulativeSupply721[tokenAddress]++;
        //todo do erc20 token transfer
    }

    function mintERC1155(
        bytes32[] calldata merkleProof,
        bytes32 merkleRoot,
        uint256 minPrice,
        uint256 tokenId,
        address tokenAddress,
        address currency,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable nonReentrant {
        require(
            OdysseyTokenFactory(factory).tokenExists(tokenAddress) == 1,
            "OdysseyLaunchPlatform: Token does not exist"
        );
        require(
            whitelistClaimed1155[tokenAddress][msg.sender][tokenId] == 0,
            "OdysseyLaunchPlatform: Already claimed"
        );
        // Check if user is already reserved + paid
        if (isReserved1155[tokenAddress][msg.sender][tokenId] == 0) {
            require(
                cumulativeSupply1155[tokenAddress][tokenId] <
                    maxSupply1155[tokenAddress][tokenId],
                "OdysseyLaunchPlatform: Max Supply Cap"
            );
            /*require(
                msg.value >= minPrice,
                "OdysseyLaunchPlatform: Insufficient funds"
            );*/
            if (whitelistActive[tokenAddress] == 1) {
                // Verify merkle root and minPrice signed by owner (all id's have same min price)
                bytes32 hash = keccak256(
                    abi.encode(
                        MERKLE_TREE_ROOT_ERC1155_TYPEHASH,
                        merkleRoot,
                        minPrice,
                        tokenId,
                        tokenAddress,
                        currency
                    )
                );
                Signature.verify(
                    hash,
                    ownerOf[tokenAddress],
                    v,
                    r,
                    s,
                    domainSeparator[tokenAddress]
                );
                // Verify user whitelisted
                MerkleWhiteList.verify(msg.sender, merkleProof, merkleRoot);
            } else {
                // verify min price
                bytes32 hash = keccak256(
                    abi.encode(
                        MIN_PRICE_ERC1155_TYPEHASH,
                        minPrice,
                        tokenId,
                        tokenAddress,
                        currency
                    )
                );
                Signature.verify(
                    hash,
                    ownerOf[tokenAddress],
                    v,
                    r,
                    s,
                    domainSeparator[tokenAddress]
                );
            }
            cumulativeSupply1155[tokenAddress][tokenId]++;
            ERC20(currency).transferFrom(
                msg.sender,
                ownerOf[tokenAddress],
                minPrice
            );
        }
        // Update State
        whitelistClaimed1155[tokenAddress][msg.sender][tokenId] = 1;
        OdysseyERC1155(tokenAddress).mint(msg.sender, tokenId);
    }

    function reserveERC1155(
        bytes32[] calldata merkleProof,
        bytes32 merkleRoot,
        uint256 minPrice,
        uint256 tokenId,
        address tokenAddress,
        address currency,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable nonReentrant {
        require(
            OdysseyTokenFactory(factory).tokenExists(tokenAddress) == 1,
            "OdysseyLaunchPlatform: Token does not exist"
        );
        require(
            cumulativeSupply1155[tokenAddress][tokenId] <
                maxSupply1155[tokenAddress][tokenId],
            "OdysseyLaunchPlatform: Max Supply"
        );
        require(
            isReserved1155[tokenAddress][msg.sender][tokenId] == 0,
            "OdysseyLaunchPlatform: Already reserved"
        );
        require(
            whitelistClaimed1155[tokenAddress][msg.sender][tokenId] == 0,
            "OdysseyLaunchPlatform: Already claimed"
        );
        /*require(
            msg.value >= minPrice,
            "OdysseyLaunchPlatform: Insufficient funds"
        );*/
        if (whitelistActive[tokenAddress] == 1) {
            bytes32 hash = keccak256(
                abi.encode(
                    MERKLE_TREE_ROOT_ERC1155_TYPEHASH,
                    merkleRoot,
                    minPrice,
                    tokenId,
                    tokenAddress,
                    currency
                )
            );
            Signature.verify(
                hash,
                ownerOf[tokenAddress],
                v,
                r,
                s,
                domainSeparator[tokenAddress]
            );
            // Verify user whitelisted
            MerkleWhiteList.verify(msg.sender, merkleProof, merkleRoot);
        } else {
            // verify min price
            bytes32 hash = keccak256(
                abi.encode(
                    MIN_PRICE_ERC1155_TYPEHASH,
                    minPrice,
                    tokenId,
                    tokenAddress,
                    currency
                )
            );
            Signature.verify(
                hash,
                ownerOf[tokenAddress],
                v,
                r,
                s,
                domainSeparator[tokenAddress]
            );
        }
        ERC20(currency).transferFrom(
            msg.sender,
            ownerOf[tokenAddress],
            minPrice
        );
        // Set user is reserved
        isReserved1155[tokenAddress][msg.sender][tokenId] = 1;
        // Increate Reserved + minted supply
        cumulativeSupply1155[tokenAddress][tokenId]++;
    }

    function setWhitelistStatus(address addr, bool active)
        external
        nonReentrant
    {
        require(
            OdysseyTokenFactory(factory).tokenExists(addr) == 1,
            "OdysseyRouter: Delegate Call Failure"
        );
        require(msg.sender == ownerOf[addr]);
        whitelistActive[addr] = active ? 1 : 0;
    }

    function mint721OnCreate(uint256 amount, address token)
        external
        nonReentrant
    {
        uint256 i;
        for (; i < amount; ++i) {
            OdysseyERC721(token).mint(msg.sender, i);
        }
        cumulativeSupply721[token] = amount;
        mintedSupply721[token] = amount;
    }

    function mint1155OnCreate(
        uint256[] calldata tokenIds,
        uint256[] calldata amounts,
        address token
    ) external nonReentrant {
        uint256 i;
        for (; i < tokenIds.length; ++i) {
            OdysseyERC1155(token).mintBatch(
                msg.sender,
                tokenIds[i],
                amounts[i]
            );
            cumulativeSupply1155[token][tokenIds[i]] = amounts[i];
        }
    }
}

contract OdysseyExchange {}

library OdysseyLib {
    struct Odyssey1155Info {
        uint256[] maxSupply;
        uint256[] tokenIds;
        uint256[] reserveAmounts;
    }
}

contract OdysseyRouter is OdysseyDatabase, ReentrancyGuard {
    constructor() {
        launchPlatform = address(new OdysseyLaunchPlatform());
        baseExchange = address(new OdysseyExchange());
        factory = address(new OdysseyTokenFactory());
    }

    function LaunchPlatform() public view returns (OdysseyLaunchPlatform) {
        return OdysseyLaunchPlatform(readSlotAsAddress(0));
    }

    function Exchange() public view returns (OdysseyExchange) {
        return OdysseyExchange(readSlotAsAddress(1));
    }

    function Factory() public view returns (OdysseyTokenFactory) {
        return OdysseyTokenFactory(readSlotAsAddress(2));
    }

    function create1155(
        string calldata name,
        string calldata symbol,
        string calldata baseURI,
        OdysseyLib.Odyssey1155Info calldata info,
        bool whitelist
    ) external returns (address token) {
        require(
            info.maxSupply.length == info.tokenIds.length,
            "OdysseyRouter: Supply and token id mismatch"
        );
        token = Factory().create1155(name, symbol, baseURI);
        ownerOf[token] = msg.sender;
        whitelistActive[token] = whitelist ? 1 : 0;
        uint256 i;
        for (; i < info.tokenIds.length; ++i) {
            maxSupply1155[token][info.tokenIds[i]] = (info.maxSupply[i] == 0)
                ? type(uint256).max
                : info.maxSupply[i];
        }

        domainSeparator[token] = keccak256(
            abi.encode(
                // keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)')
                0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f,
                keccak256(bytes(Strings.toHexString(uint160(token)))),
                0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6, // keccak256(bytes("1"))
                block.chainid,
                token
            )
        );

        if (info.reserveAmounts.length > 0) {
            (bool success, bytes memory data) = launchPlatform.delegatecall(
                abi.encodeWithSignature(
                    "mint1155OnCreate(uint256[],uint256[],address)",
                    info.tokenIds,
                    info.reserveAmounts,
                    token
                )
            );
            require(success, string(data));
        }
        return token;
    }

    function create721(
        string calldata name,
        string calldata symbol,
        string calldata baseURI,
        uint256 maxSupply,
        uint256 reserveAmount,
        bool whitelist
    ) external returns (address token) {
        token = Factory().create721(name, symbol, baseURI);
        ownerOf[token] = msg.sender;
        maxSupply721[token] = (maxSupply == 0) ? type(uint256).max : maxSupply;
        whitelistActive[token] = whitelist ? 1 : 0;
        domainSeparator[token] = keccak256(
            abi.encode(
                // keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)')
                0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f,
                keccak256(bytes(Strings.toHexString(uint160(token)))),
                0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6, // keccak256(bytes("1"))
                block.chainid,
                token
            )
        );

        if (reserveAmount > 0) {
            (bool success, bytes memory data) = launchPlatform.delegatecall(
                abi.encodeWithSignature(
                    "mint721OnCreate(uint256,address)",
                    reserveAmount,
                    token
                )
            );
            require(success, string(data));
        }

        return token;
    }

    function mintERC721(
        bytes32[] calldata merkleProof,
        bytes32 merkleRoot,
        uint256 minPrice,
        address tokenAddress,
        address currency,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public payable {
        (bool success, bytes memory data) = launchPlatform.delegatecall(
            abi.encodeWithSignature(
                "mintERC721(bytes32[],bytes32,uint256,address,address,uint8,bytes32,bytes32)",
                merkleProof,
                merkleRoot,
                minPrice,
                tokenAddress,
                currency,
                v,
                r,
                s
            )
        );
        require(success, string(data));
    }

    function reserveERC721(
        bytes32[] calldata merkleProof,
        bytes32 merkleRoot,
        uint256 minPrice,
        address tokenAddress,
        address currency,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public payable {
        (bool success, bytes memory data) = launchPlatform.delegatecall(
            abi.encodeWithSignature(
                "reserveERC721(bytes32[],bytes32,uint256,address,address,uint8,bytes32,bytes32)",
                merkleProof,
                merkleRoot,
                minPrice,
                tokenAddress,
                currency,
                v,
                r,
                s
            )
        );
        require(success, string(data));
    }

    function mintERC1155(
        bytes32[] calldata merkleProof,
        bytes32 merkleRoot,
        uint256 minPrice,
        uint256 tokenId,
        address tokenAddress,
        address currency,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public payable {
        (bool success, bytes memory data) = launchPlatform.delegatecall(
            abi.encodeWithSignature(
                "mintERC1155(bytes32[],bytes32,uint256,uint256,address,address,uint8,bytes32,bytes32)",
                merkleProof,
                merkleRoot,
                minPrice,
                tokenId,
                tokenAddress,
                currency,
                v,
                r,
                s
            )
        );
        require(success, string(data));
    }

    function reserveERC1155(
        bytes32[] calldata merkleProof,
        bytes32 merkleRoot,
        uint256 minPrice,
        uint256 tokenId,
        address tokenAddress,
        address currency,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public payable {
        (bool success, bytes memory data) = launchPlatform.delegatecall(
            abi.encodeWithSignature(
                "reserveERC1155(bytes32[],bytes32,uint256,uint256,address,address,uint8,bytes32,bytes32)",
                merkleProof,
                merkleRoot,
                minPrice,
                tokenId,
                tokenAddress,
                currency,
                v,
                r,
                s
            )
        );
        require(success, string(data));
    }

    function setWhitelistStatus(address addr, bool active) public {
        (bool success, ) = launchPlatform.delegatecall(
            abi.encodeWithSignature(
                "setWhitelistStatus(address,bool)",
                addr,
                active
            )
        );
        require(success, "OdysseyRouter: Whitelist Call Failure");
    }

    // tdoo add change ownership
}