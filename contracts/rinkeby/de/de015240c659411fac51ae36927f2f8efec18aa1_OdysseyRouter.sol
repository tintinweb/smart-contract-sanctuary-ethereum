/**
 *Submitted for verification at Etherscan.io on 2022-04-29
*/

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.12;

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
} /// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.

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
} // OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

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
} /// @title Interface for verifying contract-based account signatures

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
} // OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/MerkleProof.sol)

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
} /// @notice Modern, minimalist, and gas efficient ERC-721 implementation.

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
                            CUSTOM ERRORS
    //////////////////////////////////////////////////////////////*/
    error OdysseyERC721_AlreadyInit();
    error OdysseyERC721_Unauthorized();
    error OdysseyERC721_BadAddress();

    /*///////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/
    address launcher;
    address public owner;
    bool initialized;
    string public baseURI;
    uint256 public royaltyFeeInBips; // 1% = 100
    address public royaltyReceiver;
    string public contractURI;

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
        address _owner,
        string calldata _name,
        string calldata _symbol,
        string calldata _baseURI
    ) external {
        if (initialized) {
            revert OdysseyERC721_AlreadyInit();
        }
        initialized = true;
        launcher = _launcher;
        owner = _owner;
        name = _name;
        symbol = _symbol;
        baseURI = _baseURI;
    }

    /*///////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function transferOwnership(address newOwner) public virtual {
        if (newOwner == address(0)) {
            revert OdysseyERC721_BadAddress();
        }
        if (msg.sender != owner) {
            revert OdysseyERC721_Unauthorized();
        }
        owner = newOwner;
    }

    function mint(address user, uint256 id) external {
        if (msg.sender != launcher) {
            revert OdysseyERC721_Unauthorized();
        }
        _mint(user, id);
    }

    /*///////////////////////////////////////////////////////////////
                              EIP2981 LOGIC
    //////////////////////////////////////////////////////////////*/

    function royaltyInfo(uint256, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        return (royaltyReceiver, (_salePrice / 10000) * royaltyFeeInBips);
    }

    function setRoyaltyInfo(address _royaltyReceiver, uint256 _royaltyFeeInBips)
        external
    {
        if (_royaltyReceiver == address(0)) {
            revert OdysseyERC721_BadAddress();
        }
        if (msg.sender != owner) {
            revert OdysseyERC721_Unauthorized();
        }
        royaltyReceiver = _royaltyReceiver;
        royaltyFeeInBips = _royaltyFeeInBips;
    }

    function setContractURI(string memory _uri) public {
        if (msg.sender != owner) {
            revert OdysseyERC721_Unauthorized();
        }
        contractURI = _uri;
    }

    /*///////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceID)
        public
        pure
        override(ERC721)
        returns (bool)
    {
        return
            bytes4(keccak256("royaltyInfo(uint256,uint256)")) == interfaceID ||
            super.supportsInterface(interfaceID);
    }
} /// @notice Minimalist and gas efficient standard ERC1155 implementation.

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
                            CUSTOM ERRORS
    //////////////////////////////////////////////////////////////*/
    error OdysseyERC1155_AlreadyInit();
    error OdysseyERC1155_Unauthorized();
    error OdysseyERC1155_BadAddress();

    /*///////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/
    address launcher;
    address public owner;
    string public name;
    string public symbol;
    string public baseURI;
    bool initialized;
    uint256 public royaltyFeeInBips; // 1% = 100
    address public royaltyReceiver;
    string public contractURI;

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
        address _owner,
        string calldata _name,
        string calldata _symbol,
        string calldata _baseURI
    ) external {
        if (isInit()) {
            revert OdysseyERC1155_AlreadyInit();
        }
        initialized = true;
        launcher = _launcher;
        owner = _owner;
        name = _name;
        symbol = _symbol;
        baseURI = _baseURI;
    }

    function isInit() internal view returns (bool) {
        return initialized;
    }

    /*///////////////////////////////////////////////////////////////
                              ERC1155 LOGIC
    //////////////////////////////////////////////////////////////*/

    function transferOwnership(address newOwner) public virtual {
        if (newOwner == address(0)) {
            revert OdysseyERC1155_BadAddress();
        }
        if (msg.sender != owner) {
            revert OdysseyERC1155_Unauthorized();
        }
        owner = newOwner;
    }

    function mint(address user, uint256 id) external {
        if (msg.sender != launcher) {
            revert OdysseyERC1155_Unauthorized();
        }
        _mint(user, id, 1, "");
    }

    function mintBatch(
        address user,
        uint256 id,
        uint256 amount
    ) external {
        if (msg.sender != launcher) {
            revert OdysseyERC1155_Unauthorized();
        }
        _mint(user, id, amount, "");
    }

    /*///////////////////////////////////////////////////////////////
                              EIP2981 LOGIC
    //////////////////////////////////////////////////////////////*/

    function royaltyInfo(uint256, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        return (royaltyReceiver, (_salePrice / 10000) * royaltyFeeInBips);
    }

    function setRoyaltyInfo(address _royaltyReceiver, uint256 _royaltyFeeInBips)
        external
    {
        if (_royaltyReceiver == address(0)) {
            revert OdysseyERC1155_BadAddress();
        }
        if (msg.sender != owner) {
            revert OdysseyERC1155_Unauthorized();
        }
        royaltyReceiver = _royaltyReceiver;
        royaltyFeeInBips = _royaltyFeeInBips;
    }

    function setContractURI(string memory _uri) public {
        if (msg.sender != owner) {
            revert OdysseyERC1155_Unauthorized();
        }
        contractURI = _uri;
    }

    /*///////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceID)
        public
        pure
        override(ERC1155)
        returns (bool)
    {
        return
            bytes4(keccak256("royaltyInfo(uint256,uint256)")) == interfaceID ||
            super.supportsInterface(interfaceID);
    }
}

contract OdysseyTokenFactory {
    /*///////////////////////////////////////////////////////////////
                            CUSTOM ERRORS
    //////////////////////////////////////////////////////////////*/
    error OdysseyTokenFactory_TokenAlreadyExists();
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
        address owner,
        string calldata name,
        string calldata symbol,
        string calldata baseURI
    ) external returns (address token) {
        if (getToken[name][symbol] != address(0)) {
            revert OdysseyTokenFactory_TokenAlreadyExists();
        }
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
            owner,
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
        address owner,
        string calldata name,
        string calldata symbol,
        string calldata baseURI
    ) external returns (address token) {
        if (getToken[name][symbol] != address(0)) {
            revert OdysseyTokenFactory_TokenAlreadyExists();
        }
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
            owner,
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

library OdysseyLib {
    struct Odyssey1155Info {
        uint256[] maxSupply;
        uint256[] tokenIds;
        uint256[] reserveAmounts;
    }

    struct BatchMint {
        bytes32[][] merkleProof;
        bytes32[] merkleRoot;
        uint256[] minPrice;
        uint256[] mintsPerUser;
        uint256[] tokenId;
        address[] tokenAddress;
        address[] currency;
        uint8[] v;
        bytes32[] r;
        bytes32[] s;
    }

    struct Percentage {
        uint256 numerator;
        uint256 denominator;
    }

    function compareDefaultPercentage(OdysseyLib.Percentage calldata percent)
        internal
        pure
        returns (bool result)
    {
        if (percent.numerator > percent.denominator) {
            // Can't have a percent greater than 100
            return false;
        }

        if (percent.numerator == 0 || percent.denominator == 0) {
            // Can't use 0 in percentage
            return false;
        }

        //Check cross multiplication of 3/100
        uint256 crossMultiple1 = percent.numerator * 100;
        uint256 crossMultiple2 = percent.denominator * 3;
        if (crossMultiple1 < crossMultiple2) {
            return false;
        }
        return true;
    }
}

abstract contract OdysseyDatabase {
    // Custom Errors
    error OdysseyLaunchPlatform_TokenDoesNotExist();
    error OdysseyLaunchPlatform_AlreadyClaimed();
    error OdysseyLaunchPlatform_MaxSupplyCap();
    error OdysseyLaunchPlatform_InsufficientFunds();
    error OdysseyLaunchPlatform_TreasuryPayFailure();
    error OdysseyLaunchPlatform_FailedToPayEther();
    error OdysseyLaunchPlatform_FailedToPayERC20();
    error OdysseyLaunchPlatform_ReservedOrClaimedMax();

    // Constants
    // keccak256("whitelistMint721(bytes32 merkleRoot,uint256 minPrice,uint256 mintsPerUser,address tokenAddress,address currency)").toString('hex')
    bytes32 public constant MERKLE_TREE_ROOT_ERC721_TYPEHASH =
        0xf0f6f256599682b9387f45fc268ed696625f835d98d64b8967134239e103fc6c;
    // keccak256("whitelistMint1155(bytes32 merkleRoot,uint256 minPrice,uint256 mintsPerUser,uint256 tokenId,address tokenAddress,address currency)").toString('hex')
    bytes32 public constant MERKLE_TREE_ROOT_ERC1155_TYPEHASH =
        0x0a52f6e0133eadd055cc5703844e676242c3b461d85fb7ce7f74becd7e40edd1;

    // Def understand this before writing code:
    // https://docs.soliditylang.org/en/v0.8.12/internals/layout_in_storage.html
    //--------------------------------------------------------------------------------//
    // Slot       |  Type                  | Description                              //
    //--------------------------------------------------------------------------------//
    // 0x00       |  address               | OdysseyLaunchPlatform.sol                //
    // 0x01       |  address               | OdysseyFactory.sol                       //
    // 0x02       |  address               | Treasury Multisig                        //
    // 0x03       |  address               | Admin Address                            //
    // 0x04       |  address               | OdysseyXp.sol                            //
    //--------------------------------------------------------------------------------//
    // Slot storage
    address launchPlatform; // slot 0
    address factory; // slot 1
    address treasury; // slot 2
    address admin; //slot 3
    address xp; //slot 4

    // Common Storage
    mapping(address => bytes32) public domainSeparator;
    mapping(address => uint256) public whitelistActive;
    mapping(address => address) public ownerOf;
    mapping(address => address) public royaltyRecipient;
    mapping(address => OdysseyLib.Percentage) public treasuryCommission;
    mapping(address => uint256) public ohmFamilyCurrencies;
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

    function readSlotAsAddress(uint256 slot)
        public
        view
        returns (address data)
    {
        assembly {
            data := sload(slot)
        }
    }
} /// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.

/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @author Modified from Gnosis (https://github.com/gnosis/gp-v2-contracts/blob/main/src/contracts/libraries/GPv2SafeERC20.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
library SafeTransferLib {
    /*///////////////////////////////////////////////////////////////
                            ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool callStatus;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            callStatus := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(callStatus, "ETH_TRANSFER_FAILED");
    }

    /*///////////////////////////////////////////////////////////////
                           ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(
                freeMemoryPointer,
                0x23b872dd00000000000000000000000000000000000000000000000000000000
            ) // Begin with the function selector.
            mstore(
                add(freeMemoryPointer, 4),
                and(from, 0xffffffffffffffffffffffffffffffffffffffff)
            ) // Mask and append the "from" argument.
            mstore(
                add(freeMemoryPointer, 36),
                and(to, 0xffffffffffffffffffffffffffffffffffffffff)
            ) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 100 because the calldata length is 4 + 32 * 3.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 100, 0, 0)
        }

        require(
            didLastOptionalReturnCallSucceed(callStatus),
            "TRANSFER_FROM_FAILED"
        );
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(
                freeMemoryPointer,
                0xa9059cbb00000000000000000000000000000000000000000000000000000000
            ) // Begin with the function selector.
            mstore(
                add(freeMemoryPointer, 4),
                and(to, 0xffffffffffffffffffffffffffffffffffffffff)
            ) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 68 because the calldata length is 4 + 32 * 2.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 68, 0, 0)
        }

        require(
            didLastOptionalReturnCallSucceed(callStatus),
            "TRANSFER_FAILED"
        );
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(
                freeMemoryPointer,
                0x095ea7b300000000000000000000000000000000000000000000000000000000
            ) // Begin with the function selector.
            mstore(
                add(freeMemoryPointer, 4),
                and(to, 0xffffffffffffffffffffffffffffffffffffffff)
            ) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 68 because the calldata length is 4 + 32 * 2.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 68, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "APPROVE_FAILED");
    }

    /*///////////////////////////////////////////////////////////////
                         INTERNAL HELPER LOGIC
    //////////////////////////////////////////////////////////////*/

    function didLastOptionalReturnCallSucceed(bool callStatus)
        private
        pure
        returns (bool success)
    {
        assembly {
            // Get how many bytes the call returned.
            let returnDataSize := returndatasize()

            // If the call reverted:
            if iszero(callStatus) {
                // Copy the revert message into memory.
                returndatacopy(0, 0, returnDataSize)

                // Revert with the same message.
                revert(0, returnDataSize)
            }

            switch returnDataSize
            case 32 {
                // Copy the return data into memory.
                returndatacopy(0, 0, returnDataSize)

                // Set success to whether it returned true.
                success := iszero(iszero(mload(0)))
            }
            case 0 {
                // There was no return data.
                success := 1
            }
            default {
                // It returned some malformed input.
                success := 0
            }
        }
    }
} /// @notice Arithmetic library with operations for fixed-point numbers.

/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
library FixedPointMathLib {
    /*//////////////////////////////////////////////////////////////
                    SIMPLIFIED FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.

    function mulWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
    }

    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, y, WAD); // Equivalent to (x * y) / WAD rounded up.
    }

    function divWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, WAD, y); // Equivalent to (x * WAD) / y rounded down.
    }

    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, WAD, y); // Equivalent to (x * WAD) / y rounded up.
    }

    /*//////////////////////////////////////////////////////////////
                    LOW LEVEL FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(
                and(
                    iszero(iszero(denominator)),
                    or(iszero(x), eq(div(z, x), y))
                )
            ) {
                revert(0, 0)
            }

            // Divide z by the denominator.
            z := div(z, denominator)
        }
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(
                and(
                    iszero(iszero(denominator)),
                    or(iszero(x), eq(div(z, x), y))
                )
            ) {
                revert(0, 0)
            }

            // First, divide z - 1 by the denominator and add 1.
            // We allow z - 1 to underflow if z is 0, because we multiply the
            // end result by 0 if z is zero, ensuring we return 0 if z is zero.
            z := mul(iszero(iszero(z)), add(div(sub(z, 1), denominator), 1))
        }
    }

    function rpow(
        uint256 x,
        uint256 n,
        uint256 scalar
    ) internal pure returns (uint256 z) {
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    // 0 ** 0 = 1
                    z := scalar
                }
                default {
                    // 0 ** n = 0
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    // If n is even, store scalar in z for now.
                    z := scalar
                }
                default {
                    // If n is odd, store x in z for now.
                    z := x
                }

                // Shifting right by 1 is like dividing by 2.
                let half := shr(1, scalar)

                for {
                    // Shift n right by 1 before looping to halve it.
                    n := shr(1, n)
                } n {
                    // Shift n right by 1 each iteration to halve it.
                    n := shr(1, n)
                } {
                    // Revert immediately if x ** 2 would overflow.
                    // Equivalent to iszero(eq(div(xx, x), x)) here.
                    if shr(128, x) {
                        revert(0, 0)
                    }

                    // Store x squared.
                    let xx := mul(x, x)

                    // Round to the nearest number.
                    let xxRound := add(xx, half)

                    // Revert if xx + half overflowed.
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }

                    // Set x to scaled xxRound.
                    x := div(xxRound, scalar)

                    // If n is even:
                    if mod(n, 2) {
                        // Compute z * x.
                        let zx := mul(z, x)

                        // If z * x overflowed:
                        if iszero(eq(div(zx, x), z)) {
                            // Revert if x is non-zero.
                            if iszero(iszero(x)) {
                                revert(0, 0)
                            }
                        }

                        // Round to the nearest number.
                        let zxRound := add(zx, half)

                        // Revert if zx + half overflowed.
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }

                        // Return properly scaled zxRound.
                        z := div(zxRound, scalar)
                    }
                }
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

    function sqrt(uint256 x) internal pure returns (uint256 z) {
        assembly {
            // Start off with z at 1.
            z := 1

            // Used below to help find a nearby power of 2.
            let y := x

            // Find the lowest power of 2 that is at least sqrt(x).
            if iszero(lt(y, 0x100000000000000000000000000000000)) {
                y := shr(128, y) // Like dividing by 2 ** 128.
                z := shl(64, z) // Like multiplying by 2 ** 64.
            }
            if iszero(lt(y, 0x10000000000000000)) {
                y := shr(64, y) // Like dividing by 2 ** 64.
                z := shl(32, z) // Like multiplying by 2 ** 32.
            }
            if iszero(lt(y, 0x100000000)) {
                y := shr(32, y) // Like dividing by 2 ** 32.
                z := shl(16, z) // Like multiplying by 2 ** 16.
            }
            if iszero(lt(y, 0x10000)) {
                y := shr(16, y) // Like dividing by 2 ** 16.
                z := shl(8, z) // Like multiplying by 2 ** 8.
            }
            if iszero(lt(y, 0x100)) {
                y := shr(8, y) // Like dividing by 2 ** 8.
                z := shl(4, z) // Like multiplying by 2 ** 4.
            }
            if iszero(lt(y, 0x10)) {
                y := shr(4, y) // Like dividing by 2 ** 4.
                z := shl(2, z) // Like multiplying by 2 ** 2.
            }
            if iszero(lt(y, 0x8)) {
                // Equivalent to 2 ** z.
                z := shl(1, z)
            }

            // Shifting right by 1 is like dividing by 2.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // Compute a rounded down version of z.
            let zRoundDown := div(x, z)

            // If zRoundDown is smaller, use it.
            if lt(zRoundDown, z) {
                z := zRoundDown
            }
        }
    }
} // OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165Checker.sol)

// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            _supportsERC165Interface(account, type(IERC165).interfaceId) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId)
        internal
        view
        returns (bool)
    {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return
            supportsERC165(account) &&
            _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(
        address account,
        bytes4[] memory interfaceIds
    ) internal view returns (bool[] memory) {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = _supportsERC165Interface(
                    account,
                    interfaceIds[i]
                );
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(
        address account,
        bytes4[] memory interfaceIds
    ) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId)
        private
        view
        returns (bool)
    {
        bytes memory encodedParams = abi.encodeWithSelector(
            IERC165.supportsInterface.selector,
            interfaceId
        );
        (bool success, bytes memory result) = account.staticcall{gas: 30000}(
            encodedParams
        );
        if (result.length < 32) return false;
        return success && abi.decode(result, (bool));
    }
}
struct Rewards {
    uint256 sale;
    uint256 purchase;
    uint256 mint;
    uint256 ohmPurchase;
    uint256 ohmMint;
    uint256 multiplier;
}

struct NFT {
    address contractAddress;
    uint256 id;
}

enum NftType {
    ERC721,
    ERC1155
}

error OdysseyXpDirectory_Unauthorized();

contract OdysseyXpDirectory {
    using ERC165Checker for address;

    Rewards public defaultRewards;
    mapping(address => Rewards) public erc721rewards;
    mapping(address => mapping(uint256 => Rewards)) public erc1155rewards;
    NFT[] public customRewardTokens;
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    // modifier substitute
    function notOwner() internal view returns (bool) {
        return msg.sender != owner;
    }

    function transferOwnership(address newOwner) external {
        if (notOwner()) revert OdysseyXpDirectory_Unauthorized();
        owner = newOwner;
    }

    /*///////////////////////////////////////////////////////////////
                            Reward Setters
    //////////////////////////////////////////////////////////////*/

    /// @notice Set default rewards for contracts without a custom reward set
    /// @param sale XP reward for selling an NFT
    /// @param purchase XP reward for purchasing an NFT
    /// @param mint XP reward for minting an NFT
    /// @param ohmPurchase XP reward for purchasing an NFT with OHM
    /// @param ohmMint XP reward for minting an NFT with OHM
    /// @param multiplier XP reward multiplier for wallets holding an NFT
    function setDefaultRewards(
        uint256 sale,
        uint256 purchase,
        uint256 mint,
        uint256 ohmPurchase,
        uint256 ohmMint,
        uint256 multiplier
    ) public {
        if (notOwner()) revert OdysseyXpDirectory_Unauthorized();
        defaultRewards = Rewards(
            sale,
            purchase,
            mint,
            ohmPurchase,
            ohmMint,
            multiplier
        );
    }

    /// @notice Set custom rewards for an ERC721 contract
    /// @param sale XP reward for selling this NFT
    /// @param purchase XP reward for purchasing this NFT
    /// @param mint XP reward for minting this NFT
    /// @param ohmPurchase XP reward for purchasing this NFT with OHM
    /// @param ohmMint XP reward for minting this NFT with OHM
    /// @param multiplier XP reward multiplier for wallets holding this NFT
    function setErc721CustomRewards(
        address tokenAddress,
        uint256 sale,
        uint256 purchase,
        uint256 mint,
        uint256 ohmPurchase,
        uint256 ohmMint,
        uint256 multiplier
    ) public {
        if (notOwner()) revert OdysseyXpDirectory_Unauthorized();
        customRewardTokens.push(NFT(tokenAddress, 0));
        erc721rewards[tokenAddress] = Rewards(
            sale,
            purchase,
            mint,
            ohmPurchase,
            ohmMint,
            multiplier
        );
    }

    /// @notice Set custom rewards for an ERC1155 contract and token ID
    /// @param sale XP reward for selling this NFT
    /// @param purchase XP reward for purchasing this NFT
    /// @param mint XP reward for minting this NFT
    /// @param ohmPurchase XP reward for purchasing this NFT with OHM
    /// @param ohmMint XP reward for minting this NFT with OHM
    /// @param multiplier XP reward multiplier for wallets holding this NFT
    function setErc1155CustomRewards(
        address tokenAddress,
        uint256 tokenId,
        uint256 sale,
        uint256 purchase,
        uint256 mint,
        uint256 ohmPurchase,
        uint256 ohmMint,
        uint256 multiplier
    ) public {
        if (notOwner()) revert OdysseyXpDirectory_Unauthorized();
        customRewardTokens.push(NFT(tokenAddress, tokenId));
        erc1155rewards[tokenAddress][tokenId] = Rewards(
            sale,
            purchase,
            mint,
            ohmPurchase,
            ohmMint,
            multiplier
        );
    }

    /*///////////////////////////////////////////////////////////////
                            Reward Getters
    //////////////////////////////////////////////////////////////*/

    /// @notice Get the XP reward for selling an NFT
    /// @param seller Seller of the NFT
    /// @param contractAddress Address of the NFT being sold
    /// @param tokenId ID of the NFT being sold
    function getSaleReward(
        address seller,
        address contractAddress,
        uint256 tokenId
    ) public view returns (uint256) {
        (
            bool isCustomErc721,
            bool isCustomErc1155,
            uint256 multiplier
        ) = _getRewardDetails(seller, contractAddress, tokenId);
        if (isCustomErc721) {
            return erc721rewards[contractAddress].sale * multiplier;
        } else if (isCustomErc1155) {
            return erc1155rewards[contractAddress][tokenId].sale * multiplier;
        } else {
            return defaultRewards.sale * multiplier;
        }
    }

    /// @notice Get the XP reward for buying an NFT
    /// @param buyer Buyer of the NFT
    /// @param contractAddress Address of the NFT being sold
    /// @param tokenId ID of the NFT being sold
    function getPurchaseReward(
        address buyer,
        address contractAddress,
        uint256 tokenId
    ) public view returns (uint256) {
        (
            bool isCustomErc721,
            bool isCustomErc1155,
            uint256 multiplier
        ) = _getRewardDetails(buyer, contractAddress, tokenId);
        if (isCustomErc721) {
            return erc721rewards[contractAddress].purchase * multiplier;
        } else if (isCustomErc1155) {
            return
                erc1155rewards[contractAddress][tokenId].purchase * multiplier;
        } else {
            return defaultRewards.purchase * multiplier;
        }
    }

    /// @notice Get the XP reward for minting an NFT
    /// @param buyer Buyer of the NFT
    /// @param contractAddress Address of the NFT being sold
    /// @param tokenId ID of the NFT being sold
    function getMintReward(
        address buyer,
        address contractAddress,
        uint256 tokenId
    ) public view returns (uint256) {
        (
            bool isCustomErc721,
            bool isCustomErc1155,
            uint256 multiplier
        ) = _getRewardDetails(buyer, contractAddress, tokenId);
        if (isCustomErc721) {
            return erc721rewards[contractAddress].mint * multiplier;
        } else if (isCustomErc1155) {
            return erc1155rewards[contractAddress][tokenId].mint * multiplier;
        } else {
            return defaultRewards.mint * multiplier;
        }
    }

    /// @notice Get the XP reward for buying an NFT with OHM
    /// @param buyer Buyer of the NFT
    /// @param contractAddress Address of the NFT being sold
    /// @param tokenId ID of the NFT being sold
    function getOhmPurchaseReward(
        address buyer,
        address contractAddress,
        uint256 tokenId
    ) public view returns (uint256) {
        (
            bool isCustomErc721,
            bool isCustomErc1155,
            uint256 multiplier
        ) = _getRewardDetails(buyer, contractAddress, tokenId);
        if (isCustomErc721) {
            return erc721rewards[contractAddress].ohmPurchase * multiplier;
        } else if (isCustomErc1155) {
            return
                erc1155rewards[contractAddress][tokenId].ohmPurchase *
                multiplier;
        } else {
            return defaultRewards.ohmPurchase * multiplier;
        }
    }

    /// @notice Get the XP reward for minting an NFT with OHM
    /// @param buyer Buyer of the NFT
    /// @param contractAddress Address of the NFT being sold
    /// @param tokenId ID of the NFT being sold
    function getOhmMintReward(
        address buyer,
        address contractAddress,
        uint256 tokenId
    ) public view returns (uint256) {
        (
            bool isCustomErc721,
            bool isCustomErc1155,
            uint256 multiplier
        ) = _getRewardDetails(buyer, contractAddress, tokenId);
        if (isCustomErc721) {
            return erc721rewards[contractAddress].ohmMint * multiplier;
        } else if (isCustomErc1155) {
            return
                erc1155rewards[contractAddress][tokenId].ohmMint * multiplier;
        } else {
            return defaultRewards.ohmMint * multiplier;
        }
    }

    /// @notice Determine if an NFT has custom rewards and any multiplier based on the user's held NFTs
    /// @dev The multiplier and custom rewards are determined simultaneously to save on gas costs of iteration
    /// @param user Wallet address with potential multiplier NFTs
    /// @param contractAddress Address of the NFT being sold
    /// @param tokenId ID of the NFT being sold
    function _getRewardDetails(
        address user,
        address contractAddress,
        uint256 tokenId
    )
        internal
        view
        returns (
            bool isCustomErc721,
            bool isCustomErc1155,
            uint256 multiplier
        )
    {
        NFT[] memory _customRewardTokens = customRewardTokens; // save an SLOAD from length reading
        for (uint256 i = 0; i < _customRewardTokens.length; i++) {
            NFT memory token = _customRewardTokens[i];
            if (token.contractAddress.supportsInterface(0x80ac58cd)) {
                // is ERC721
                if (OdysseyERC721(token.contractAddress).balanceOf(user) > 0) {
                    uint256 reward = erc721rewards[token.contractAddress]
                        .multiplier;
                    multiplier = reward > 1 ? multiplier + reward : multiplier; // only increment if multiplier is non-one
                }
                if (contractAddress == token.contractAddress) {
                    isCustomErc721 = true;
                }
            } else if (token.contractAddress.supportsInterface(0xd9b67a26)) {
                // is isERC1155
                if (
                    OdysseyERC1155(token.contractAddress).balanceOf(
                        user,
                        token.id
                    ) > 0
                ) {
                    uint256 reward = erc1155rewards[token.contractAddress][
                        token.id
                    ].multiplier;
                    multiplier = reward > 1 ? multiplier + reward : multiplier; // only increment if multiplier is non-one
                    if (
                        contractAddress == token.contractAddress &&
                        tokenId == token.id
                    ) {
                        isCustomErc1155 = true;
                    }
                }
            }
        }
        multiplier = multiplier == 0 ? defaultRewards.multiplier : multiplier; // if no custom multiplier, use default
        multiplier = multiplier > 4 ? 4 : multiplier; // multiplier caps at 4
    }
}
error OdysseyXp_Unauthorized();
error OdysseyXp_NonTransferable();
error OdysseyXp_ZeroAssets();

contract OdysseyXp is ERC20 {
    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;

    struct UserHistory {
        uint256 balanceAtLastRedeem;
        uint256 globallyWithdrawnAtLastRedeem;
    }

    /*///////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Mint(address indexed owner, uint256 assets, uint256 xp);

    event Redeem(address indexed owner, uint256 assets, uint256 xp);

    /*///////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    address public router;
    address public exchange;
    address public owner;
    uint256 public globallyWithdrawn;
    ERC20 public immutable asset;
    OdysseyXpDirectory public directory;
    mapping(address => UserHistory) public userHistories;

    constructor(
        ERC20 _asset,
        OdysseyXpDirectory _directory,
        address _router,
        address _exchange,
        address _owner
    ) ERC20("Odyssey XP", "XP", 0) {
        asset = _asset;
        directory = _directory;
        router = _router;
        exchange = _exchange;
        owner = _owner;
    }

    /*///////////////////////////////////////////////////////////////
                            MODIFIERS
    //////////////////////////////////////////////////////////////*/

    function notOwner() internal view returns (bool) {
        return msg.sender != owner;
    }

    function notRouter() internal view returns (bool) {
        return msg.sender != router;
    }

    function notExchange() internal view returns (bool) {
        return msg.sender != exchange;
    }

    /*///////////////////////////////////////////////////////////////
                        RESTRICTED SETTERS
    //////////////////////////////////////////////////////////////*/

    function setExchange(address _exchange) external {
        if (notOwner()) revert OdysseyXp_Unauthorized();
        exchange = _exchange;
    }

    function setRouter(address _router) external {
        if (notOwner()) revert OdysseyXp_Unauthorized();
        router = _router;
    }

    function setDirectory(address _directory) external {
        if (notOwner()) revert OdysseyXp_Unauthorized();
        directory = OdysseyXpDirectory(_directory);
    }

    function transferOwnership(address _newOwner) external {
        if (notOwner()) revert OdysseyXp_Unauthorized();
        owner = _newOwner;
    }

    /*///////////////////////////////////////////////////////////////
                        XP Granting Methods
    //////////////////////////////////////////////////////////////*/

    function saleReward(
        address seller,
        address contractAddress,
        uint256 tokenId
    ) external {
        if (notExchange()) revert OdysseyXp_Unauthorized();
        _grantXP(
            seller,
            directory.getSaleReward(seller, contractAddress, tokenId)
        );
    }

    function purchaseReward(
        address buyer,
        address contractAddress,
        uint256 tokenId
    ) external {
        if (notExchange()) revert OdysseyXp_Unauthorized();
        _grantXP(
            buyer,
            directory.getPurchaseReward(buyer, contractAddress, tokenId)
        );
    }

    function mintReward(
        address buyer,
        address contractAddress,
        uint256 tokenId
    ) external {
        if (notRouter()) revert OdysseyXp_Unauthorized();
        _grantXP(
            buyer,
            directory.getMintReward(buyer, contractAddress, tokenId)
        );
    }

    function ohmPurchaseReward(
        address buyer,
        address contractAddress,
        uint256 tokenId
    ) external {
        if (notExchange()) revert OdysseyXp_Unauthorized();
        _grantXP(
            buyer,
            directory.getOhmPurchaseReward(buyer, contractAddress, tokenId)
        );
    }

    function ohmMintReward(
        address buyer,
        address contractAddress,
        uint256 tokenId
    ) external {
        if (notRouter()) revert OdysseyXp_Unauthorized();
        _grantXP(
            buyer,
            directory.getOhmMintReward(buyer, contractAddress, tokenId)
        );
    }

    /*///////////////////////////////////////////////////////////////
                            MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Grants the receiver the given amount of XP
    /// @dev Forces the receiver to redeem if they have rewards available
    /// @param receiver The address to grant XP to
    /// @param xp The amount of XP to grant
    function _grantXP(address receiver, uint256 xp)
        internal
        returns (uint256 assets)
    {
        uint256 currentXp = balanceOf[receiver];
        if ((assets = previewRedeem(receiver, currentXp)) > 0)
            _redeem(receiver, assets, currentXp); // force redeeming to keep portions in line
        else if (currentXp == 0)
            userHistories[receiver]
                .globallyWithdrawnAtLastRedeem = globallyWithdrawn; // if a new user, adjust their history to calculate withdrawn at their first redeem
        _mint(receiver, xp);

        emit Mint(msg.sender, assets, xp);

        afterMint(assets, xp);
    }

    /*///////////////////////////////////////////////////////////////
                        REDEEM LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice external redeem method
    /// @dev will revert if there is nothing to redeem
    function redeem() public returns (uint256 assets) {
        uint256 xp = balanceOf[msg.sender];
        if ((assets = previewRedeem(msg.sender, xp)) == 0)
            revert OdysseyXp_ZeroAssets();
        _redeem(msg.sender, assets, xp);
    }

    /// @notice Internal logic for redeeming rewards
    /// @param receiver The receiver of rewards
    /// @param assets The amount of assets to grant
    /// @param xp The amount of XP the user is redeeming with
    function _redeem(
        address receiver,
        uint256 assets,
        uint256 xp
    ) internal virtual {
        beforeRedeem(assets, xp);

        userHistories[receiver].balanceAtLastRedeem =
            asset.balanceOf(address(this)) -
            assets;
        userHistories[receiver].globallyWithdrawnAtLastRedeem =
            globallyWithdrawn +
            assets;
        globallyWithdrawn += assets;

        asset.safeTransfer(receiver, assets);

        emit Redeem(receiver, assets, xp);
    }

    /*///////////////////////////////////////////////////////////////
                           ACCOUNTING LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Preview the result of a redeem for the given user with the given XP amount
    /// @param recipient The user to check potential rewards for
    /// @param xp The amount of XP the user is previewing a redeem for
    function previewRedeem(address recipient, uint256 xp)
        public
        view
        virtual
        returns (uint256)
    {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return
            supply == 0 || xp == 0
                ? 0
                : xp.mulDivDown(totalAssets(recipient), supply);
    }

    /// @notice The total amount of available assets for the user, adjusted based on their history
    /// @param user The user to check assets for
    function totalAssets(address user) internal view returns (uint256) {
        uint256 balance = asset.balanceOf(address(this)); // Saves an extra SLOAD if balance is non-zero.
        return
            balance +
            (globallyWithdrawn -
                userHistories[user].globallyWithdrawnAtLastRedeem) -
            userHistories[user].balanceAtLastRedeem;
    }

    /*///////////////////////////////////////////////////////////////
                       OVERRIDE TRANSFERABILITY
    //////////////////////////////////////////////////////////////*/

    function transfer(address to, uint256 amount)
        public
        override
        returns (bool)
    {
        revert OdysseyXp_NonTransferable();
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override returns (bool) {
        revert OdysseyXp_NonTransferable();
    }

    /*///////////////////////////////////////////////////////////////
                         INTERNAL HOOKS LOGIC
    //////////////////////////////////////////////////////////////*/

    function beforeRedeem(uint256 assets, uint256 xp) internal virtual {}

    function afterMint(uint256 assets, uint256 xp) internal virtual {}
}

contract OdysseyLaunchPlatform is OdysseyDatabase, ReentrancyGuard {
    /*///////////////////////////////////////////////////////////////
                                ACTIONS
    //////////////////////////////////////////////////////////////*/
    function mintERC721(
        bytes32[] calldata merkleProof,
        bytes32 merkleRoot,
        uint256 minPrice,
        uint256 mintsPerUser,
        address tokenAddress,
        address currency,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable nonReentrant {
        if (OdysseyTokenFactory(factory).tokenExists(tokenAddress) == 0) {
            revert OdysseyLaunchPlatform_TokenDoesNotExist();
        }
        if (whitelistClaimed721[tokenAddress][msg.sender] >= mintsPerUser) {
            revert OdysseyLaunchPlatform_AlreadyClaimed();
        }
        // Check if user is already reserved + paid
        if (isReserved721[tokenAddress][msg.sender] == 0) {
            if (
                cumulativeSupply721[tokenAddress] >= maxSupply721[tokenAddress]
            ) {
                revert OdysseyLaunchPlatform_MaxSupplyCap();
            }
            {
                // Verify merkle root and minPrice signed by owner (all id's have same min price)
                bytes32 hash = keccak256(
                    abi.encode(
                        MERKLE_TREE_ROOT_ERC721_TYPEHASH,
                        merkleRoot,
                        minPrice,
                        mintsPerUser,
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
            if (whitelistActive[tokenAddress] == 1) {
                // Verify user whitelisted
                MerkleWhiteList.verify(msg.sender, merkleProof, merkleRoot);
            }
            cumulativeSupply721[tokenAddress]++;

            OdysseyLib.Percentage storage percent = treasuryCommission[
                tokenAddress
            ];
            uint256 commission = (minPrice * percent.numerator) /
                percent.denominator;

            if (currency == address(0)) {
                if (msg.value < minPrice) {
                    revert OdysseyLaunchPlatform_InsufficientFunds();
                }
                (bool treasurySuccess, ) = treasury.call{value: commission}("");
                if (!treasurySuccess) {
                    revert OdysseyLaunchPlatform_TreasuryPayFailure();
                }
                (bool success, ) = royaltyRecipient[tokenAddress].call{
                    value: minPrice - commission
                }("");
                if (!success) {
                    revert OdysseyLaunchPlatform_FailedToPayEther();
                }
            } else {
                if (
                    ERC20(currency).allowance(msg.sender, address(this)) <
                    minPrice
                ) {
                    revert OdysseyLaunchPlatform_InsufficientFunds();
                }
                bool result = ERC20(currency).transferFrom(
                    msg.sender,
                    treasury,
                    commission
                );
                if (!result) {
                    revert OdysseyLaunchPlatform_TreasuryPayFailure();
                }
                result = ERC20(currency).transferFrom(
                    msg.sender,
                    royaltyRecipient[tokenAddress],
                    minPrice - commission
                );
                if (!result) {
                    revert OdysseyLaunchPlatform_FailedToPayERC20();
                }
                if (ohmFamilyCurrencies[currency] == 1) {
                    OdysseyXp(xp).ohmMintReward(msg.sender, tokenAddress, 0);
                }
            }
        } else {
            isReserved721[tokenAddress][msg.sender]--;
        }
        // Update State
        whitelistClaimed721[tokenAddress][msg.sender]++;
        OdysseyERC721(tokenAddress).mint(
            msg.sender,
            mintedSupply721[tokenAddress]++
        );
    }

    function reserveERC721(
        bytes32[] calldata merkleProof,
        bytes32 merkleRoot,
        uint256 minPrice,
        uint256 mintsPerUser,
        address tokenAddress,
        address currency,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable nonReentrant {
        if (OdysseyTokenFactory(factory).tokenExists(tokenAddress) == 0) {
            revert OdysseyLaunchPlatform_TokenDoesNotExist();
        }
        if (cumulativeSupply721[tokenAddress] >= maxSupply721[tokenAddress]) {
            revert OdysseyLaunchPlatform_MaxSupplyCap();
        }
        if (
            isReserved721[tokenAddress][msg.sender] +
                whitelistClaimed721[tokenAddress][msg.sender] >=
            mintsPerUser
        ) {
            revert OdysseyLaunchPlatform_ReservedOrClaimedMax();
        }
        {
            // Verify merkle root and minPrice signed by owner (all id's have same min price)
            bytes32 hash = keccak256(
                abi.encode(
                    MERKLE_TREE_ROOT_ERC721_TYPEHASH,
                    merkleRoot,
                    minPrice,
                    mintsPerUser,
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
        if (whitelistActive[tokenAddress] == 1) {
            // Verify user whitelisted
            MerkleWhiteList.verify(msg.sender, merkleProof, merkleRoot);
        }

        // Set user is reserved
        isReserved721[tokenAddress][msg.sender]++;
        // Increate Reserved + minted supply
        cumulativeSupply721[tokenAddress]++;

        OdysseyLib.Percentage storage percent = treasuryCommission[
            tokenAddress
        ];
        uint256 commission = (minPrice * percent.numerator) /
            percent.denominator;

        if (currency == address(0)) {
            if (msg.value < minPrice) {
                revert OdysseyLaunchPlatform_InsufficientFunds();
            }
            (bool treasurySuccess, ) = treasury.call{value: commission}("");
            if (!treasurySuccess) {
                revert OdysseyLaunchPlatform_TreasuryPayFailure();
            }
            (bool success, ) = royaltyRecipient[tokenAddress].call{
                value: minPrice - commission
            }("");
            if (!success) {
                revert OdysseyLaunchPlatform_FailedToPayEther();
            }
        } else {
            if (
                ERC20(currency).allowance(msg.sender, address(this)) < minPrice
            ) {
                revert OdysseyLaunchPlatform_InsufficientFunds();
            }
            bool result = ERC20(currency).transferFrom(
                msg.sender,
                treasury,
                commission
            );
            if (!result) {
                revert OdysseyLaunchPlatform_TreasuryPayFailure();
            }
            result = ERC20(currency).transferFrom(
                msg.sender,
                royaltyRecipient[tokenAddress],
                minPrice - commission
            );
            if (!result) {
                revert OdysseyLaunchPlatform_FailedToPayERC20();
            }
            if (ohmFamilyCurrencies[currency] == 1) {
                OdysseyXp(xp).ohmMintReward(msg.sender, tokenAddress, 0);
            }
        }
    }

    function mintERC1155(
        bytes32[] calldata merkleProof,
        bytes32 merkleRoot,
        uint256 minPrice,
        uint256 mintsPerUser,
        uint256 tokenId,
        address tokenAddress,
        address currency,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable nonReentrant {
        if (OdysseyTokenFactory(factory).tokenExists(tokenAddress) == 0) {
            revert OdysseyLaunchPlatform_TokenDoesNotExist();
        }
        if (
            whitelistClaimed1155[tokenAddress][msg.sender][tokenId] >=
            mintsPerUser
        ) {
            revert OdysseyLaunchPlatform_AlreadyClaimed();
        }
        // Check if user is already reserved + paid
        if (isReserved1155[tokenAddress][msg.sender][tokenId] == 0) {
            if (
                cumulativeSupply1155[tokenAddress][tokenId] >=
                maxSupply1155[tokenAddress][tokenId]
            ) {
                revert OdysseyLaunchPlatform_MaxSupplyCap();
            }
            {
                // Verify merkle root and minPrice signed by owner (all id's have same min price)
                bytes32 hash = keccak256(
                    abi.encode(
                        MERKLE_TREE_ROOT_ERC1155_TYPEHASH,
                        merkleRoot,
                        minPrice,
                        mintsPerUser,
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

            if (whitelistActive[tokenAddress] == 1) {
                // Verify user whitelisted
                MerkleWhiteList.verify(msg.sender, merkleProof, merkleRoot);
            }
            cumulativeSupply1155[tokenAddress][tokenId]++;

            OdysseyLib.Percentage storage percent = treasuryCommission[
                tokenAddress
            ];
            uint256 commission = (minPrice * percent.numerator) /
                percent.denominator;

            if (currency == address(0)) {
                if (msg.value < minPrice) {
                    revert OdysseyLaunchPlatform_InsufficientFunds();
                }
                (bool treasurySuccess, ) = treasury.call{value: commission}("");
                if (!treasurySuccess) {
                    revert OdysseyLaunchPlatform_TreasuryPayFailure();
                }
                (bool success, ) = royaltyRecipient[tokenAddress].call{
                    value: minPrice - commission
                }("");
                if (!success) {
                    revert OdysseyLaunchPlatform_FailedToPayEther();
                }
            } else {
                if (
                    ERC20(currency).allowance(msg.sender, address(this)) <
                    minPrice
                ) {
                    revert OdysseyLaunchPlatform_InsufficientFunds();
                }
                bool result = ERC20(currency).transferFrom(
                    msg.sender,
                    treasury,
                    commission
                );
                if (!result) {
                    revert OdysseyLaunchPlatform_TreasuryPayFailure();
                }
                result = ERC20(currency).transferFrom(
                    msg.sender,
                    royaltyRecipient[tokenAddress],
                    minPrice - commission
                );
                if (!result) {
                    revert OdysseyLaunchPlatform_FailedToPayERC20();
                }
                if (ohmFamilyCurrencies[currency] == 1) {
                    OdysseyXp(xp).ohmMintReward(
                        msg.sender,
                        tokenAddress,
                        tokenId
                    );
                }
            }
        } else {
            isReserved1155[tokenAddress][msg.sender][tokenId]--;
        }
        // Update State
        whitelistClaimed1155[tokenAddress][msg.sender][tokenId]++;

        OdysseyERC1155(tokenAddress).mint(msg.sender, tokenId);
    }

    function reserveERC1155(
        bytes32[] calldata merkleProof,
        bytes32 merkleRoot,
        uint256 minPrice,
        uint256 mintsPerUser,
        uint256 tokenId,
        address tokenAddress,
        address currency,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable nonReentrant {
        if (OdysseyTokenFactory(factory).tokenExists(tokenAddress) == 0) {
            revert OdysseyLaunchPlatform_TokenDoesNotExist();
        }
        if (
            cumulativeSupply1155[tokenAddress][tokenId] >=
            maxSupply1155[tokenAddress][tokenId]
        ) {
            revert OdysseyLaunchPlatform_MaxSupplyCap();
        }
        if (
            isReserved1155[tokenAddress][msg.sender][tokenId] +
                whitelistClaimed1155[tokenAddress][msg.sender][tokenId] >=
            mintsPerUser
        ) {
            revert OdysseyLaunchPlatform_ReservedOrClaimedMax();
        }
        {
            // Verify merkle root and minPrice signed by owner (all id's have same min price)
            bytes32 hash = keccak256(
                abi.encode(
                    MERKLE_TREE_ROOT_ERC1155_TYPEHASH,
                    merkleRoot,
                    minPrice,
                    mintsPerUser,
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

        if (whitelistActive[tokenAddress] == 1) {
            // Verify user whitelisted
            MerkleWhiteList.verify(msg.sender, merkleProof, merkleRoot);
        }

        // Set user is reserved
        isReserved1155[tokenAddress][msg.sender][tokenId]++;
        // Increase Reserved + minted supply
        cumulativeSupply1155[tokenAddress][tokenId]++;

        OdysseyLib.Percentage storage percent = treasuryCommission[
            tokenAddress
        ];
        uint256 commission = (minPrice * percent.numerator) /
            percent.denominator;

        if (currency == address(0)) {
            if (msg.value < minPrice) {
                revert OdysseyLaunchPlatform_InsufficientFunds();
            }
            (bool treasurySuccess, ) = treasury.call{value: commission}("");
            if (!treasurySuccess) {
                revert OdysseyLaunchPlatform_TreasuryPayFailure();
            }
            (bool success, ) = royaltyRecipient[tokenAddress].call{
                value: minPrice - commission
            }("");
            if (!success) {
                revert OdysseyLaunchPlatform_FailedToPayEther();
            }
        } else {
            if (
                ERC20(currency).allowance(msg.sender, address(this)) < minPrice
            ) {
                revert OdysseyLaunchPlatform_InsufficientFunds();
            }
            bool result = ERC20(currency).transferFrom(
                msg.sender,
                treasury,
                commission
            );
            if (!result) {
                revert OdysseyLaunchPlatform_TreasuryPayFailure();
            }
            result = ERC20(currency).transferFrom(
                msg.sender,
                royaltyRecipient[tokenAddress],
                minPrice - commission
            );
            if (!result) {
                revert OdysseyLaunchPlatform_FailedToPayERC20();
            }
            if (ohmFamilyCurrencies[currency] == 1) {
                OdysseyXp(xp).ohmMintReward(msg.sender, tokenAddress, tokenId);
            }
        }
    }

    function setWhitelistStatus(address addr, bool active)
        external
        nonReentrant
    {
        if (OdysseyTokenFactory(factory).tokenExists(addr) == 0) {
            revert OdysseyLaunchPlatform_TokenDoesNotExist();
        }
        whitelistActive[addr] = active ? 1 : 0;
    }

    function mint721OnCreate(uint256 amount, address token)
        external
        nonReentrant
    {
        cumulativeSupply721[token] = amount;
        mintedSupply721[token] = amount;
        uint256 i;
        for (; i < amount; ++i) {
            OdysseyERC721(token).mint(msg.sender, i);
        }
    }

    function mint1155OnCreate(
        uint256[] calldata tokenIds,
        uint256[] calldata amounts,
        address token
    ) external nonReentrant {
        uint256 i;
        for (; i < tokenIds.length; ++i) {
            cumulativeSupply1155[token][tokenIds[i]] = amounts[i];
            OdysseyERC1155(token).mintBatch(
                msg.sender,
                tokenIds[i],
                amounts[i]
            );
        }
    }

    function ownerMint721(address token, address to) external nonReentrant {
        if (cumulativeSupply721[token] >= maxSupply721[token]) {
            revert OdysseyLaunchPlatform_MaxSupplyCap();
        }
        cumulativeSupply721[token]++;
        OdysseyERC721(token).mint(to, mintedSupply721[token]++);
    }

    function ownerMint1155(
        uint256 id,
        uint256 amount,
        address token,
        address to
    ) external nonReentrant {
        if (
            cumulativeSupply1155[token][id] + amount > maxSupply1155[token][id]
        ) {
            revert OdysseyLaunchPlatform_MaxSupplyCap();
        }
        cumulativeSupply1155[token][id] += amount;
        OdysseyERC1155(token).mintBatch(to, id, amount);
    }
}

contract OdysseyRouter is OdysseyDatabase, ReentrancyGuard {
    error OdysseyRouter_TokenIDSupplyMismatch();
    error OdysseyRouter_WhitelistUpdateFail();
    error OdysseyRouter_Unauthorized();
    error OdysseyRouter_OwnerMintFailure();
    error OdysseyRouter_BadTokenAddress();
    error OdysseyRouter_BadOwnerAddress();
    error OdysseyRouter_BadSenderAddress();
    error OdysseyRouter_BadRecipientAddress();
    error OdysseyRouter_BadTreasuryAddress();
    error OdysseyRouter_BadAdminAddress();

    constructor(
        address treasury_,
        address xpDirectory_,
        address xp_,
        address[] memory ohmCurrencies_
    ) {
        launchPlatform = address(new OdysseyLaunchPlatform());
        factory = address(new OdysseyTokenFactory());
        treasury = treasury_;
        admin = msg.sender;
        uint256 i;
        for (; i < ohmCurrencies_.length; i++) {
            ohmFamilyCurrencies[ohmCurrencies_[i]] = 1;
        }
        if (xp_ == address(0)) {
            if (xpDirectory_ == address(0)) {
                xpDirectory_ = address(new OdysseyXpDirectory());
                OdysseyXpDirectory(xpDirectory_).setDefaultRewards(
                    1,
                    1,
                    1,
                    3,
                    3,
                    1
                );
                OdysseyXpDirectory(xpDirectory_).transferOwnership(admin);
            }
            xp_ = address(
                new OdysseyXp(
                    ERC20(ohmCurrencies_[0]),
                    OdysseyXpDirectory(xpDirectory_),
                    address(this),
                    address(this),
                    admin
                )
            );
        }
        xp = xp_;
    }

    function Factory() public view returns (OdysseyTokenFactory) {
        return OdysseyTokenFactory(readSlotAsAddress(1));
    }

    function create1155(
        string calldata name,
        string calldata symbol,
        string calldata baseURI,
        OdysseyLib.Odyssey1155Info calldata info,
        OdysseyLib.Percentage calldata treasuryPercentage,
        address royaltyReceiver,
        bool whitelist
    ) external returns (address token) {
        if (info.maxSupply.length != info.tokenIds.length) {
            revert OdysseyRouter_TokenIDSupplyMismatch();
        }
        token = Factory().create1155(msg.sender, name, symbol, baseURI);
        ownerOf[token] = msg.sender;
        whitelistActive[token] = whitelist ? 1 : 0;
        royaltyRecipient[token] = royaltyReceiver;
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

        if (OdysseyLib.compareDefaultPercentage(treasuryPercentage)) {
            // Treasury % was greater than 3/100
            treasuryCommission[token] = treasuryPercentage;
        } else {
            // Treasury % was less than 3/100, using 3/100 as default
            treasuryCommission[token] = OdysseyLib.Percentage(3, 100);
        }

        if (info.reserveAmounts.length > 0) {
            (bool success, bytes memory data) = launchPlatform.delegatecall(
                abi.encodeWithSignature(
                    "mint1155OnCreate(uint256[],uint256[],address)",
                    info.tokenIds,
                    info.reserveAmounts,
                    token
                )
            );
            if (!success) {
                if (data.length == 0) revert();
                assembly {
                    revert(add(32, data), mload(data))
                }
            }
        }
        return token;
    }

    function create721(
        string calldata name,
        string calldata symbol,
        string calldata baseURI,
        uint256 maxSupply,
        uint256 reserveAmount,
        OdysseyLib.Percentage calldata treasuryPercentage,
        address royaltyReceiver,
        bool whitelist
    ) external returns (address token) {
        token = Factory().create721(msg.sender, name, symbol, baseURI);
        ownerOf[token] = msg.sender;
        maxSupply721[token] = (maxSupply == 0) ? type(uint256).max : maxSupply;
        whitelistActive[token] = whitelist ? 1 : 0;
        royaltyRecipient[token] = royaltyReceiver;
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

        if (OdysseyLib.compareDefaultPercentage(treasuryPercentage)) {
            // Treasury % was greater than 3/100
            treasuryCommission[token] = treasuryPercentage;
        } else {
            // Treasury % was less than 3/100, using 3/100 as default
            treasuryCommission[token] = OdysseyLib.Percentage(3, 100);
        }

        if (reserveAmount > 0) {
            (bool success, bytes memory data) = launchPlatform.delegatecall(
                abi.encodeWithSignature(
                    "mint721OnCreate(uint256,address)",
                    reserveAmount,
                    token
                )
            );
            if (!success) {
                if (data.length == 0) revert();
                assembly {
                    revert(add(32, data), mload(data))
                }
            }
        }

        return token;
    }

    function mintERC721(
        bytes32[] calldata merkleProof,
        bytes32 merkleRoot,
        uint256 minPrice,
        uint256 mintsPerUser,
        address tokenAddress,
        address currency,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public payable {
        (bool success, bytes memory data) = launchPlatform.delegatecall(
            abi.encodeWithSignature(
                "mintERC721(bytes32[],bytes32,uint256,uint256,address,address,uint8,bytes32,bytes32)",
                merkleProof,
                merkleRoot,
                minPrice,
                mintsPerUser,
                tokenAddress,
                currency,
                v,
                r,
                s
            )
        );
        if (!success) {
            if (data.length == 0) revert();
            assembly {
                revert(add(32, data), mload(data))
            }
        }
    }

    function batchMintERC721(OdysseyLib.BatchMint calldata batch)
        public
        payable
    {
        for (uint256 i = 0; i < batch.tokenAddress.length; i++) {
            (bool success, bytes memory data) = launchPlatform.delegatecall(
                abi.encodeWithSignature(
                    "mintERC721(bytes32[],bytes32,uint256,uint256,address,address,uint8,bytes32,bytes32)",
                    batch.merkleProof[i],
                    batch.merkleRoot[i],
                    batch.minPrice[i],
                    batch.mintsPerUser[i],
                    batch.tokenAddress[i],
                    batch.currency[i],
                    batch.v[i],
                    batch.r[i],
                    batch.s[i]
                )
            );
            if (!success) {
                if (data.length == 0) revert();
                assembly {
                    revert(add(32, data), mload(data))
                }
            }
        }
    }

    function reserveERC721(
        bytes32[] calldata merkleProof,
        bytes32 merkleRoot,
        uint256 minPrice,
        uint256 mintsPerUser,
        address tokenAddress,
        address currency,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public payable {
        (bool success, bytes memory data) = launchPlatform.delegatecall(
            abi.encodeWithSignature(
                "reserveERC721(bytes32[],bytes32,uint256,uint256,address,address,uint8,bytes32,bytes32)",
                merkleProof,
                merkleRoot,
                minPrice,
                mintsPerUser,
                tokenAddress,
                currency,
                v,
                r,
                s
            )
        );
        if (!success) {
            if (data.length == 0) revert();
            assembly {
                revert(add(32, data), mload(data))
            }
        }
    }

    function batchReserveERC721(OdysseyLib.BatchMint calldata batch)
        public
        payable
    {
        for (uint256 i = 0; i < batch.tokenAddress.length; i++) {
            (bool success, bytes memory data) = launchPlatform.delegatecall(
                abi.encodeWithSignature(
                    "reserveERC721(bytes32[],bytes32,uint256,uint256,address,address,uint8,bytes32,bytes32)",
                    batch.merkleProof[i],
                    batch.merkleRoot[i],
                    batch.minPrice[i],
                    batch.mintsPerUser[i],
                    batch.tokenAddress[i],
                    batch.currency[i],
                    batch.v[i],
                    batch.r[i],
                    batch.s[i]
                )
            );
            if (!success) {
                if (data.length == 0) revert();
                assembly {
                    revert(add(32, data), mload(data))
                }
            }
        }
    }

    function mintERC1155(
        bytes32[] calldata merkleProof,
        bytes32 merkleRoot,
        uint256 minPrice,
        uint256 mintsPerUser,
        uint256 tokenId,
        address tokenAddress,
        address currency,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public payable {
        (bool success, bytes memory data) = launchPlatform.delegatecall(
            abi.encodeWithSignature(
                "mintERC1155(bytes32[],bytes32,uint256,uint256,uint256,address,address,uint8,bytes32,bytes32)",
                merkleProof,
                merkleRoot,
                minPrice,
                mintsPerUser,
                tokenId,
                tokenAddress,
                currency,
                v,
                r,
                s
            )
        );
        if (!success) {
            if (data.length == 0) revert();
            assembly {
                revert(add(32, data), mload(data))
            }
        }
    }

    function batchMintERC1155(OdysseyLib.BatchMint calldata batch)
        public
        payable
    {
        for (uint256 i = 0; i < batch.tokenAddress.length; i++) {
            (bool success, bytes memory data) = launchPlatform.delegatecall(
                abi.encodeWithSignature(
                    "mintERC1155(bytes32[],bytes32,uint256,uint256,uint256,address,address,uint8,bytes32,bytes32)",
                    batch.merkleProof[i],
                    batch.merkleRoot[i],
                    batch.minPrice[i],
                    batch.mintsPerUser[i],
                    batch.tokenId[i],
                    batch.tokenAddress[i],
                    batch.currency[i],
                    batch.v[i],
                    batch.r[i],
                    batch.s[i]
                )
            );
            if (!success) {
                if (data.length == 0) revert();
                assembly {
                    revert(add(32, data), mload(data))
                }
            }
        }
    }

    function reserveERC1155(
        bytes32[] calldata merkleProof,
        bytes32 merkleRoot,
        uint256 minPrice,
        uint256 mintsPerUser,
        uint256 tokenId,
        address tokenAddress,
        address currency,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public payable {
        (bool success, bytes memory data) = launchPlatform.delegatecall(
            abi.encodeWithSignature(
                "reserveERC1155(bytes32[],bytes32,uint256,uint256,uint256,address,address,uint8,bytes32,bytes32)",
                merkleProof,
                merkleRoot,
                minPrice,
                mintsPerUser,
                tokenId,
                tokenAddress,
                currency,
                v,
                r,
                s
            )
        );
        if (!success) {
            if (data.length == 0) revert();
            assembly {
                revert(add(32, data), mload(data))
            }
        }
    }

    function batchReserveERC1155(OdysseyLib.BatchMint calldata batch)
        public
        payable
    {
        for (uint256 i = 0; i < batch.tokenAddress.length; i++) {
            (bool success, bytes memory data) = launchPlatform.delegatecall(
                abi.encodeWithSignature(
                    "reserveERC1155(bytes32[],bytes32,uint256,uint256,uint256,address,address,uint8,bytes32,bytes32)",
                    batch.merkleProof[i],
                    batch.merkleRoot[i],
                    batch.minPrice[i],
                    batch.mintsPerUser[i],
                    batch.tokenId[i],
                    batch.tokenAddress[i],
                    batch.currency[i],
                    batch.v[i],
                    batch.r[i],
                    batch.s[i]
                )
            );
            if (!success) {
                if (data.length == 0) revert();
                assembly {
                    revert(add(32, data), mload(data))
                }
            }
        }
    }

    function setWhitelistStatus(address addr, bool active) public {
        if (msg.sender != ownerOf[addr]) {
            revert OdysseyRouter_Unauthorized();
        }
        (bool success, ) = launchPlatform.delegatecall(
            abi.encodeWithSignature(
                "setWhitelistStatus(address,bool)",
                addr,
                active
            )
        );
        if (!success) {
            revert OdysseyRouter_WhitelistUpdateFail();
        }
    }

    function ownerMint721(address token, address to) public {
        if (ownerOf[token] != msg.sender) {
            revert OdysseyRouter_Unauthorized();
        }
        (bool success, ) = launchPlatform.delegatecall(
            abi.encodeWithSignature("ownerMint721(address,address)", token, to)
        );
        if (!success) {
            revert OdysseyRouter_OwnerMintFailure();
        }
    }

    function ownerMint1155(
        uint256 id,
        uint256 amount,
        address token,
        address to
    ) public {
        if (ownerOf[token] != msg.sender) {
            revert OdysseyRouter_Unauthorized();
        }
        (bool success, ) = launchPlatform.delegatecall(
            abi.encodeWithSignature(
                "ownerMint1155(uint256,uint256,address,address)",
                id,
                amount,
                token,
                to
            )
        );
        if (!success) {
            revert OdysseyRouter_OwnerMintFailure();
        }
    }

    function setOwnerShip(address token, address newOwner) public {
        if (token == address(0)) {
            revert OdysseyRouter_BadTokenAddress();
        }
        if (newOwner == address(0)) {
            revert OdysseyRouter_BadOwnerAddress();
        }
        if (msg.sender == address(0)) {
            revert OdysseyRouter_BadSenderAddress();
        }
        if (ownerOf[token] != msg.sender) {
            revert OdysseyRouter_Unauthorized();
        }
        ownerOf[token] = newOwner;
    }

    function setRoyaltyRecipient(address token, address recipient) public {
        if (token == address(0)) {
            revert OdysseyRouter_BadTokenAddress();
        }
        if (recipient == address(0)) {
            revert OdysseyRouter_BadRecipientAddress();
        }
        if (msg.sender == address(0)) {
            revert OdysseyRouter_BadSenderAddress();
        }
        if (ownerOf[token] != msg.sender) {
            revert OdysseyRouter_Unauthorized();
        }
        royaltyRecipient[token] = recipient;
    }

    function setTreasury(address newTreasury) public {
        if (msg.sender != admin) {
            revert OdysseyRouter_Unauthorized();
        }
        if (msg.sender == address(0)) {
            revert OdysseyRouter_BadSenderAddress();
        }
        if (newTreasury == address(0)) {
            revert OdysseyRouter_BadTreasuryAddress();
        }
        treasury = newTreasury;
    }

    function setXP(address newXp) public {
        if (msg.sender != admin) {
            revert OdysseyRouter_Unauthorized();
        }
        if (msg.sender == address(0)) {
            revert OdysseyRouter_BadSenderAddress();
        }
        if (newXp == address(0)) {
            revert OdysseyRouter_BadTokenAddress();
        }
        xp = newXp;
    }

    function setAdmin(address newAdmin) public {
        if (msg.sender != admin) {
            revert OdysseyRouter_Unauthorized();
        }
        if (msg.sender == address(0)) {
            revert OdysseyRouter_BadSenderAddress();
        }
        if (newAdmin == address(0)) {
            revert OdysseyRouter_BadAdminAddress();
        }
        admin = newAdmin;
    }

    function setMaxSupply721(address token, uint256 amount) public {
        if (ownerOf[token] != msg.sender) {
            revert OdysseyRouter_Unauthorized();
        }
        maxSupply721[token] = amount;
    }

    function setMaxSupply1155(
        address token,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) public {
        if (ownerOf[token] != msg.sender) {
            revert OdysseyRouter_Unauthorized();
        }
        uint256 i;
        for (; i < tokenIds.length; ++i) {
            maxSupply1155[token][tokenIds[i]] = amounts[i];
        }
    }
}