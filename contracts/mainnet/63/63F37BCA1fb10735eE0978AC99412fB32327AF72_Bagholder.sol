/**
 *Submitted for verification at Etherscan.io on 2022-09-19
*/

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.14;

// Source: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol + Claimable.sol
// Simplified by BoringCrypto

contract BoringOwnableData {
    address public owner;
    address public pendingOwner;
}

contract BoringOwnable is BoringOwnableData {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice `owner` defaults to msg.sender on construction.
    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    /// @notice Transfers ownership to `newOwner`. Either directly or claimable by the new pending owner.
    /// Can only be invoked by the current `owner`.
    /// @param newOwner Address of the new owner.
    /// @param direct True if `newOwner` should be set immediately. False if `newOwner` needs to use `claimOwnership`.
    /// @param renounce Allows the `newOwner` to be `address(0)` if `direct` and `renounce` is True. Has no effect otherwise.
    function transferOwnership(
        address newOwner,
        bool direct,
        bool renounce
    ) public onlyOwner {
        if (direct) {
            // Checks
            require(newOwner != address(0) || renounce, "Ownable: zero address");

            // Effects
            emit OwnershipTransferred(owner, newOwner);
            owner = newOwner;
            pendingOwner = address(0);
        } else {
            // Effects
            pendingOwner = newOwner;
        }
    }

    /// @notice Needs to be called by `pendingOwner` to claim ownership.
    function claimOwnership() public {
        address _pendingOwner = pendingOwner;

        // Checks
        require(msg.sender == _pendingOwner, "Ownable: caller != pending owner");

        // Effects
        emit OwnershipTransferred(owner, _pendingOwner);
        owner = _pendingOwner;
        pendingOwner = address(0);
    }

    /// @notice Only allows the `owner` to execute the function.
    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }
}

// OpenZeppelin Contracts (last updated v4.5.0) (utils/Multicall.sol)

// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
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
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
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
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

/**
 * @dev Provides a function to batch together multiple calls in a single external call.
 *
 * _Available since v4.1._
 */
abstract contract Multicall {
    /**
     * @dev Receives and executes a batch of function calls on this contract.
     */
    function multicall(bytes[] calldata data) external virtual returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            results[i] = Address.functionDelegateCall(address(this), data[i]);
        }
        return results;
    }
}

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
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

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
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

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
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
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
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
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) internal _ownerOf;

    mapping(address => uint256) internal _balanceOf;

    function ownerOf(uint256 id) public view virtual returns (address owner) {
        require((owner = _ownerOf[id]) != address(0), "NOT_MINTED");
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "ZERO_ADDRESS");

        return _balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = _ownerOf[id];

        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

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
        require(from == _ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[id],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[from]--;

            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

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
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(_ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = _ownerOf[id];

        require(owner != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            _balanceOf[owner]--;
        }

        delete _ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") ==
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
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

/// @notice Safe unsigned integer casting library that reverts on overflow.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeCastLib.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeCast.sol)
library SafeCastLib {
    function safeCastTo248(uint256 x) internal pure returns (uint248 y) {
        require(x < 1 << 248);

        y = uint248(x);
    }

    function safeCastTo224(uint256 x) internal pure returns (uint224 y) {
        require(x < 1 << 224);

        y = uint224(x);
    }

    function safeCastTo192(uint256 x) internal pure returns (uint192 y) {
        require(x < 1 << 192);

        y = uint192(x);
    }

    function safeCastTo160(uint256 x) internal pure returns (uint160 y) {
        require(x < 1 << 160);

        y = uint160(x);
    }

    function safeCastTo128(uint256 x) internal pure returns (uint128 y) {
        require(x < 1 << 128);

        y = uint128(x);
    }

    function safeCastTo96(uint256 x) internal pure returns (uint96 y) {
        require(x < 1 << 96);

        y = uint96(x);
    }

    function safeCastTo64(uint256 x) internal pure returns (uint64 y) {
        require(x < 1 << 64);

        y = uint64(x);
    }

    function safeCastTo32(uint256 x) internal pure returns (uint32 y) {
        require(x < 1 << 32);

        y = uint32(x);
    }

    function safeCastTo24(uint256 x) internal pure returns (uint24 y) {
        require(x < 1 << 24);

        y = uint24(x);
    }

    function safeCastTo8(uint256 x) internal pure returns (uint8 y) {
        require(x < 1 << 8);

        y = uint8(x);
    }
}

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
}

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = a * b
            // Compute the product mod 2**256 and mod 2**256 - 1
            // then use the Chinese Remainder Theorem to reconstruct
            // the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2**256 + prod0
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(a, b, not(0))
                prod0 := mul(a, b)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division
            if (prod1 == 0) {
                require(denominator > 0);
                assembly {
                    result := div(prod0, denominator)
                }
                return result;
            }

            // Make sure the result is less than 2**256.
            // Also prevents denominator == 0
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0]
            // Compute remainder using mulmod
            uint256 remainder;
            assembly {
                remainder := mulmod(a, b, denominator)
            }
            // Subtract 256 bit number from 512 bit number
            assembly {
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator
            // Compute largest power of two divisor of denominator.
            // Always >= 1.
            uint256 twos = (0 - denominator) & denominator;
            // Divide denominator by power of two
            assembly {
                denominator := div(denominator, twos)
            }

            // Divide [prod1 prod0] by the factors of two
            assembly {
                prod0 := div(prod0, twos)
            }
            // Shift in bits from prod1 into prod0. For this we need
            // to flip `twos` such that it is 2**256 / twos.
            // If twos is zero, then it becomes one
            assembly {
                twos := add(div(sub(0, twos), twos), 1)
            }
            prod0 |= prod1 * twos;

            // Invert denominator mod 2**256
            // Now that denominator is an odd number, it has an inverse
            // modulo 2**256 such that denominator * inv = 1 mod 2**256.
            // Compute the inverse by starting with a seed that is correct
            // correct for four bits. That is, denominator * inv = 1 mod 2**4
            uint256 inv = (3 * denominator) ^ 2;
            // Now use Newton-Raphson iteration to improve the precision.
            // Thanks to Hensel's lifting lemma, this also works in modular
            // arithmetic, doubling the correct bits in each step.
            inv *= 2 - denominator * inv; // inverse mod 2**8
            inv *= 2 - denominator * inv; // inverse mod 2**16
            inv *= 2 - denominator * inv; // inverse mod 2**32
            inv *= 2 - denominator * inv; // inverse mod 2**64
            inv *= 2 - denominator * inv; // inverse mod 2**128
            inv *= 2 - denominator * inv; // inverse mod 2**256

            // Because the division is now exact we can divide by multiplying
            // with the modular inverse of denominator. This will give us the
            // correct result modulo 2**256. Since the precoditions guarantee
            // that the outcome is less than 2**256, this is the final result.
            // We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inv;
            return result;
        }
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            result = mulDiv(a, b, denominator);
            if (mulmod(a, b, denominator) > 0) {
                require(result < type(uint256).max);
                result++;
            }
        }
    }
}

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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

// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

/// @title Self Permit
/// @notice Functionality to call permit on any EIP-2612-compliant token for use in the route
interface ISelfPermit {
    /// @notice Permits this contract to spend a given token from `msg.sender`
    /// @dev The `owner` is always msg.sender and the `spender` is always address(this).
    /// @param token The address of the token spent
    /// @param value The amount that can be spent of token
    /// @param deadline A timestamp, the current blocktime must be less than or equal to this timestamp
    /// @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`
    /// @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`
    /// @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`
    function selfPermit(
        address token,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;

    /// @notice Permits this contract to spend a given token from `msg.sender`
    /// @dev The `owner` is always msg.sender and the `spender` is always address(this).
    /// Can be used instead of #selfPermit to prevent calls from failing due to a frontrun of a call to #selfPermit
    /// @param token The address of the token spent
    /// @param value The amount that can be spent of token
    /// @param deadline A timestamp, the current blocktime must be less than or equal to this timestamp
    /// @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`
    /// @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`
    /// @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`
    function selfPermitIfNecessary(
        address token,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;

    /// @notice Permits this contract to spend the sender's tokens for permit signatures that have the `allowed` parameter
    /// @dev The `owner` is always msg.sender and the `spender` is always address(this)
    /// @param token The address of the token spent
    /// @param nonce The current nonce of the owner
    /// @param expiry The timestamp at which the permit is no longer valid
    /// @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`
    /// @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`
    /// @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`
    function selfPermitAllowed(
        address token,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;

    /// @notice Permits this contract to spend the sender's tokens for permit signatures that have the `allowed` parameter
    /// @dev The `owner` is always msg.sender and the `spender` is always address(this)
    /// Can be used instead of #selfPermitAllowed to prevent calls from failing due to a frontrun of a call to #selfPermitAllowed.
    /// @param token The address of the token spent
    /// @param nonce The current nonce of the owner
    /// @param expiry The timestamp at which the permit is no longer valid
    /// @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`
    /// @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`
    /// @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`
    function selfPermitAllowedIfNecessary(
        address token,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;
}

/// @title Interface for permit
/// @notice Interface used by DAI/CHAI for permit
interface IERC20PermitAllowed {
    /// @notice Approve the spender to spend some tokens via the holder signature
    /// @dev This is the permit interface used by DAI and CHAI
    /// @param holder The address of the token holder, the token owner
    /// @param spender The address of the token spender
    /// @param nonce The holder's nonce, increases at each call to permit
    /// @param expiry The timestamp at which the permit is no longer valid
    /// @param allowed Boolean that sets approval amount, true for type(uint256).max and false for 0
    /// @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`
    /// @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`
    /// @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`
    function permit(
        address holder,
        address spender,
        uint256 nonce,
        uint256 expiry,
        bool allowed,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

/// @title Self Permit
/// @notice Functionality to call permit on any EIP-2612-compliant token for use in the route
/// @dev These functions are expected to be embedded in multicalls to allow EOAs to approve a contract and call a function
/// that requires an approval in a single transaction.
abstract contract SelfPermit is ISelfPermit {
    /// @inheritdoc ISelfPermit
    function selfPermit(
        address token,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public payable override {
        IERC20Permit(token).permit(msg.sender, address(this), value, deadline, v, r, s);
    }

    /// @inheritdoc ISelfPermit
    function selfPermitIfNecessary(
        address token,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable override {
        if (IERC20(token).allowance(msg.sender, address(this)) < value) selfPermit(token, value, deadline, v, r, s);
    }

    /// @inheritdoc ISelfPermit
    function selfPermitAllowed(
        address token,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public payable override {
        IERC20PermitAllowed(token).permit(msg.sender, address(this), nonce, expiry, true, v, r, s);
    }

    /// @inheritdoc ISelfPermit
    function selfPermitAllowedIfNecessary(
        address token,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable override {
        if (IERC20(token).allowance(msg.sender, address(this)) < type(uint256).max)
            selfPermitAllowed(token, nonce, expiry, v, r, s);
    }
}

function min(uint256 a, uint256 b) pure returns (uint256) {
    return a < b ? a : b;
}

/// @param nft the NFT to incentivize
/// @param rewardToken the token used to reward stakers
/// @param refundRecipient the recipient of the refunded reward tokens
/// @param startTime the Unix timestamp (in seconds) when the incentive begins
/// @param endTime the Unix timestamp (in seconds) when the incentive ends
/// @param bondAmount the amount of ETH a staker needs to put up as bond, should be
/// enough to cover the gas cost of calling slashPaperHand() and then some
struct IncentiveKey {
    ERC721 nft;
    ERC20 rewardToken;
    address refundRecipient;
    uint256 startTime;
    uint256 endTime;
    uint256 bondAmount;
}

/// @param totalRewardUnclaimed the amount of unclaimed reward tokens accrued to the staker
/// @param rewardPerTokenStored the rewardPerToken value when the staker info was last updated
/// @param numberOfStakedTokens the number of NFTs staked by the staker in the specified incentive
struct StakerInfo {
    uint256 rewardPerTokenStored;
    uint192 totalRewardUnclaimed;
    uint64 numberOfStakedTokens;
}

/// @param rewardRatePerSecond the amount of reward tokens (in wei) given to stakers per second
/// @param rewardPerTokenStored the rewardPerToken value when the incentive info was last updated
/// @param numberOfStakedTokens the number of NFTs staked in the specified incentive
/// @param lastUpdateTime the Unix timestamp (in seconds) when the incentive info was last updated,
/// or the incentive's endTime if the time of the last update was after endTime
/// @param accruedRefund the amount of reward tokens to refund to the incentive creator from periods
/// where there are no staked NFTs in the incentive
struct IncentiveInfo {
    uint256 rewardPerTokenStored;
    uint128 rewardRatePerSecond;
    uint64 numberOfStakedTokens;
    uint64 lastUpdateTime;
    uint256 accruedRefund;
}

/// @param key the incentive to stake into
/// @param nftId the ID of the NFT to stake
struct StakeMultipleInput {
    IncentiveKey key;
    uint256 nftId;
}

/// @param fee The fee value. Each increment represents 0.1%, so max is 25.5% (8 bits)
/// @param recipient The address that will receive the protocol fees
struct ProtocolFeeInfo {
    uint8 fee;
    address recipient;
}

library IncentiveId {
    /// @notice Calculate the key for a staking incentive
    /// @param key The components used to compute the incentive identifier
    /// @return incentiveId The identifier for the incentive
    function compute(IncentiveKey memory key)
        internal
        pure
        returns (bytes32 incentiveId)
    {
        return keccak256(abi.encode(key));
    }
}

/// @title Bagholder
/// @author zefram.eth
/// @notice Incentivize NFT holders to keep holding their bags without letting their
/// precious NFTs leave their wallets.
/// @dev Uses an optimistic staking model where if someone staked and then transferred
/// their NFT elsewhere, someone else can slash them and receive the staker's bond.
contract Bagholder is Multicall, SelfPermit, BoringOwnable {
    /// -----------------------------------------------------------------------
    /// Library usage
    /// -----------------------------------------------------------------------

    using SafeCastLib for uint256;
    using SafeTransferLib for ERC20;
    using SafeTransferLib for address;
    using IncentiveId for IncentiveKey;

    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    /// @notice Thrown when unstaking an NFT that hasn't been staked
    error Bagholder__NotStaked();

    /// @notice Thrown when an unauthorized account tries to perform an action available
    /// only to the NFT's owner
    error Bagholder__NotNftOwner();

    /// @notice Thrown when trying to slash someone who shouldn't be slashed
    error Bagholder__NotPaperHand();

    /// @notice Thrown when staking an NFT that's already staked
    error Bagholder__AlreadyStaked();

    /// @notice Thrown when the bond provided by the staker differs from the specified amount
    error Bagholder__BondIncorrect();

    /// @notice Thrown when creating an incentive using invalid parameters (e.g. start time is after end time)
    error Bagholder__InvalidIncentiveKey();

    /// @notice Thrown when staking into an incentive that doesn't exist
    error Bagholder__IncentiveNonexistent();

    /// @notice Thrown when creating an incentive with a zero reward rate
    error Bagholder__RewardAmountTooSmall();

    /// @notice Thrown when creating an incentive that already exists
    error Bagholder__IncentiveAlreadyExists();

    /// @notice Thrown when setting the protocol fee recipient to the zero address
    /// while having a non-zero protocol fee
    error Bagholder_ProtocolFeeRecipientIsZero();

    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    event Stake(
        address indexed staker,
        bytes32 indexed incentiveId,
        uint256 indexed nftId
    );
    event Unstake(
        address indexed staker,
        bytes32 indexed incentiveId,
        uint256 indexed nftId,
        address bondRecipient
    );
    event SlashPaperHand(
        address indexed sender,
        bytes32 indexed incentiveId,
        uint256 indexed nftId,
        address bondRecipient
    );
    event CreateIncentive(
        address indexed sender,
        bytes32 indexed incentiveId,
        IncentiveKey key,
        uint256 rewardAmount,
        uint256 protocolFeeAmount
    );
    event ClaimRewards(
        address indexed staker,
        bytes32 indexed incentiveId,
        address recipient
    );
    event ClaimRefund(
        address indexed sender,
        bytes32 indexed incentiveId,
        uint256 refundAmount
    );
    event SetProtocolFee(ProtocolFeeInfo protocolFeeInfo_);

    /// -----------------------------------------------------------------------
    /// Constants
    /// -----------------------------------------------------------------------

    /// @notice The precision used by rewardPerToken
    uint256 internal constant PRECISION = 1e27;

    /// -----------------------------------------------------------------------
    /// Storage variables
    /// -----------------------------------------------------------------------

    /// @notice Records the address that staked an NFT into an incentive.
    /// Zero address if the NFT hasn't been staked into the incentive.
    /// @dev incentive ID => NFT ID => staker address
    mapping(bytes32 => mapping(uint256 => address)) public stakers;

    /// @notice Records accounting info about each staker.
    /// @dev incentive ID => staker address => info
    mapping(bytes32 => mapping(address => StakerInfo)) public stakerInfos;

    /// @notice Records accounting info about each incentive.
    /// @dev incentive ID => info
    mapping(bytes32 => IncentiveInfo) public incentiveInfos;

    /// @notice Stores the amount and recipient of the protocol fee
    ProtocolFeeInfo public protocolFeeInfo;

    /// -----------------------------------------------------------------------
    /// Constructor
    /// -----------------------------------------------------------------------

    constructor(ProtocolFeeInfo memory protocolFeeInfo_) {
        if (
            protocolFeeInfo_.fee != 0 &&
            protocolFeeInfo_.recipient == address(0)
        ) {
            revert Bagholder_ProtocolFeeRecipientIsZero();
        }
        protocolFeeInfo = protocolFeeInfo_;
        emit SetProtocolFee(protocolFeeInfo_);
    }

    /// -----------------------------------------------------------------------
    /// Public actions
    /// -----------------------------------------------------------------------

    /// @notice Stakes an NFT into an incentive. The NFT stays in the user's wallet.
    /// The caller must provide the ETH bond (specified in the incentive key) as part of
    /// the call. Anyone can stake on behalf of anyone else, provided they provide the bond.
    /// @param key the incentive's key
    /// @param nftId the ID of the NFT
    function stake(IncentiveKey calldata key, uint256 nftId)
        external
        payable
        virtual
    {
        /// -----------------------------------------------------------------------
        /// Storage loads
        /// -----------------------------------------------------------------------

        bytes32 incentiveId = key.compute();
        address staker = key.nft.ownerOf(nftId);
        StakerInfo memory stakerInfo = stakerInfos[incentiveId][staker];
        IncentiveInfo memory incentiveInfo = incentiveInfos[incentiveId];

        /// -----------------------------------------------------------------------
        /// Validation
        /// -----------------------------------------------------------------------

        // check bond is correct
        if (msg.value != key.bondAmount) {
            revert Bagholder__BondIncorrect();
        }

        // check the NFT is not currently being staked in this incentive
        if (stakers[incentiveId][nftId] != address(0)) {
            revert Bagholder__AlreadyStaked();
        }

        // ensure the incentive exists
        if (incentiveInfo.lastUpdateTime == 0) {
            revert Bagholder__IncentiveNonexistent();
        }

        /// -----------------------------------------------------------------------
        /// State updates
        /// -----------------------------------------------------------------------

        // accrue rewards
        (stakerInfo, incentiveInfo) = _accrueRewards(
            key,
            stakerInfo,
            incentiveInfo
        );

        // update stake state
        stakers[incentiveId][nftId] = staker;

        // update staker state
        stakerInfo.numberOfStakedTokens += 1;
        stakerInfos[incentiveId][staker] = stakerInfo;

        // update incentive state
        incentiveInfo.numberOfStakedTokens += 1;
        incentiveInfos[incentiveId] = incentiveInfo;

        emit Stake(staker, incentiveId, nftId);
    }

    /// @notice Stakes multiple NFTs into incentives. The NFTs stay in the user's wallet.
    /// The caller must provide the ETH bond (specified in the incentive keys) as part of
    /// the call. Anyone can stake on behalf of anyone else, provided they provide the bond.
    /// @param inputs The array of inputs, with each input consisting of an incentive key
    /// and an NFT ID.
    function stakeMultiple(StakeMultipleInput[] calldata inputs)
        external
        payable
        virtual
    {
        uint256 numInputs = inputs.length;
        uint256 totalBondRequired;
        for (uint256 i; i < numInputs; ) {
            /// -----------------------------------------------------------------------
            /// Storage loads
            /// -----------------------------------------------------------------------

            bytes32 incentiveId = inputs[i].key.compute();
            uint256 nftId = inputs[i].nftId;
            address staker = inputs[i].key.nft.ownerOf(nftId);
            StakerInfo memory stakerInfo = stakerInfos[incentiveId][staker];
            IncentiveInfo memory incentiveInfo = incentiveInfos[incentiveId];

            /// -----------------------------------------------------------------------
            /// Validation
            /// -----------------------------------------------------------------------

            // check the NFT is not currently being staked in this incentive
            if (stakers[incentiveId][nftId] != address(0)) {
                revert Bagholder__AlreadyStaked();
            }

            // ensure the incentive exists
            if (incentiveInfo.lastUpdateTime == 0) {
                revert Bagholder__IncentiveNonexistent();
            }

            /// -----------------------------------------------------------------------
            /// State updates
            /// -----------------------------------------------------------------------

            // accrue rewards
            (stakerInfo, incentiveInfo) = _accrueRewards(
                inputs[i].key,
                stakerInfo,
                incentiveInfo
            );

            // update stake state
            stakers[incentiveId][nftId] = staker;

            // update staker state
            stakerInfo.numberOfStakedTokens += 1;
            stakerInfos[incentiveId][staker] = stakerInfo;

            // update incentive state
            incentiveInfo.numberOfStakedTokens += 1;
            incentiveInfos[incentiveId] = incentiveInfo;

            emit Stake(staker, incentiveId, nftId);

            totalBondRequired += inputs[i].key.bondAmount;
            unchecked {
                ++i;
            }
        }

        // check bond is correct
        if (msg.value != totalBondRequired) {
            revert Bagholder__BondIncorrect();
        }
    }

    /// @notice Unstakes an NFT from an incentive and returns the ETH bond.
    /// The caller must be the owner of the NFT AND the current staker.
    /// @param key the incentive's key
    /// @param nftId the ID of the NFT
    /// @param bondRecipient the recipient of the ETH bond
    function unstake(
        IncentiveKey calldata key,
        uint256 nftId,
        address bondRecipient
    ) external virtual {
        /// -----------------------------------------------------------------------
        /// Validation
        /// -----------------------------------------------------------------------

        bytes32 incentiveId = key.compute();

        // check the NFT is currently being staked in the incentive
        if (stakers[incentiveId][nftId] != msg.sender) {
            revert Bagholder__NotStaked();
        }

        // check msg.sender owns the NFT
        if (key.nft.ownerOf(nftId) != msg.sender) {
            revert Bagholder__NotNftOwner();
        }

        /// -----------------------------------------------------------------------
        /// Storage loads
        /// -----------------------------------------------------------------------

        StakerInfo memory stakerInfo = stakerInfos[incentiveId][msg.sender];
        IncentiveInfo memory incentiveInfo = incentiveInfos[incentiveId];

        /// -----------------------------------------------------------------------
        /// State updates
        /// -----------------------------------------------------------------------

        // accrue rewards
        (stakerInfo, incentiveInfo) = _accrueRewards(
            key,
            stakerInfo,
            incentiveInfo
        );

        // update NFT state
        delete stakers[incentiveId][nftId];

        // update staker state
        stakerInfo.numberOfStakedTokens -= 1;
        stakerInfos[incentiveId][msg.sender] = stakerInfo;

        // update incentive state
        incentiveInfo.numberOfStakedTokens -= 1;
        incentiveInfos[incentiveId] = incentiveInfo;

        /// -----------------------------------------------------------------------
        /// External calls
        /// -----------------------------------------------------------------------

        // return bond to user
        bondRecipient.safeTransferETH(key.bondAmount);

        emit Unstake(msg.sender, incentiveId, nftId, bondRecipient);
    }

    /// @notice Unstaked an NFT from an incentive, then use the bond to stake an NFT into another incentive.
    /// Must be called by the owner of the unstaked NFT. The bond amount of the incentive to unstake from must be at least
    /// that of the incentive to stake in, with any extra bond sent to the specified recipient.
    /// @param unstakeKey the key of the incentive to unstake from
    /// @param unstakeNftId the ID of the NFT to unstake
    /// @param stakeKey the key of the incentive to stake into
    /// @param stakeNftId the ID of the NFT to stake
    /// @param bondRecipient the recipient of any extra bond
    function restake(
        IncentiveKey calldata unstakeKey,
        uint256 unstakeNftId,
        IncentiveKey calldata stakeKey,
        uint256 stakeNftId,
        address bondRecipient
    ) external virtual {
        /// -----------------------------------------------------------------------
        /// Validation
        /// -----------------------------------------------------------------------

        bytes32 unstakeIncentiveId = unstakeKey.compute();
        bytes32 stakeIncentiveId = stakeKey.compute();

        // check the NFT is currently being staked in the unstake incentive
        if (stakers[unstakeIncentiveId][unstakeNftId] != msg.sender) {
            revert Bagholder__NotStaked();
        }

        // check msg.sender owns the unstaked NFT
        if (unstakeKey.nft.ownerOf(unstakeNftId) != msg.sender) {
            revert Bagholder__NotNftOwner();
        }

        // check there's enough bond
        if (unstakeKey.bondAmount < stakeKey.bondAmount) {
            revert Bagholder__BondIncorrect();
        }

        // check the staked NFT is not currently being staked in the stake incentive
        if (stakers[stakeIncentiveId][stakeNftId] != address(0)) {
            revert Bagholder__AlreadyStaked();
        }

        /// -----------------------------------------------------------------------
        /// Storage loads (Unstake)
        /// -----------------------------------------------------------------------

        StakerInfo memory stakerInfo = stakerInfos[unstakeIncentiveId][
            msg.sender
        ];
        IncentiveInfo memory incentiveInfo = incentiveInfos[unstakeIncentiveId];

        /// -----------------------------------------------------------------------
        /// State updates (Unstake)
        /// -----------------------------------------------------------------------

        // accrue rewards
        (stakerInfo, incentiveInfo) = _accrueRewards(
            unstakeKey,
            stakerInfo,
            incentiveInfo
        );

        // update NFT state
        delete stakers[unstakeIncentiveId][unstakeNftId];

        // update staker state
        stakerInfo.numberOfStakedTokens -= 1;
        stakerInfos[unstakeIncentiveId][msg.sender] = stakerInfo;

        // update incentive state
        incentiveInfo.numberOfStakedTokens -= 1;
        incentiveInfos[unstakeIncentiveId] = incentiveInfo;

        emit Unstake(
            msg.sender,
            unstakeIncentiveId,
            unstakeNftId,
            bondRecipient
        );

        /// -----------------------------------------------------------------------
        /// Storage loads (Stake)
        /// -----------------------------------------------------------------------

        address staker = stakeKey.nft.ownerOf(stakeNftId);
        stakerInfo = stakerInfos[stakeIncentiveId][staker];
        incentiveInfo = incentiveInfos[stakeIncentiveId];

        // ensure the incentive exists
        if (incentiveInfo.lastUpdateTime == 0) {
            revert Bagholder__IncentiveNonexistent();
        }

        /// -----------------------------------------------------------------------
        /// State updates (Stake)
        /// -----------------------------------------------------------------------

        // accrue rewards
        (stakerInfo, incentiveInfo) = _accrueRewards(
            stakeKey,
            stakerInfo,
            incentiveInfo
        );

        // update stake state
        stakers[stakeIncentiveId][stakeNftId] = staker;

        // update staker state
        stakerInfo.numberOfStakedTokens += 1;
        stakerInfos[stakeIncentiveId][staker] = stakerInfo;

        // update incentive state
        incentiveInfo.numberOfStakedTokens += 1;
        incentiveInfos[stakeIncentiveId] = incentiveInfo;

        emit Stake(staker, stakeIncentiveId, stakeNftId);

        /// -----------------------------------------------------------------------
        /// External calls
        /// -----------------------------------------------------------------------

        if (unstakeKey.bondAmount != stakeKey.bondAmount) {
            unchecked {
                // return extra bond to user
                // already checked unstakeKey.bondAmount > stakeKey.bondAmount
                bondRecipient.safeTransferETH(
                    unstakeKey.bondAmount - stakeKey.bondAmount
                );
            }
        }
    }

    /// @notice Slashes a staker who has transferred the staked NFT to another address.
    /// The bond is given to the slasher as reward.
    /// @param key the incentive's key
    /// @param nftId the ID of the NFT
    /// @param bondRecipient the recipient of the ETH bond
    function slashPaperHand(
        IncentiveKey calldata key,
        uint256 nftId,
        address bondRecipient
    ) external virtual {
        /// -----------------------------------------------------------------------
        /// Validation
        /// -----------------------------------------------------------------------

        bytes32 incentiveId = key.compute();

        // check the NFT is currently being staked in this incentive by someone other than the NFT owner
        address staker = stakers[incentiveId][nftId];
        if (staker == address(0) || staker == key.nft.ownerOf(nftId)) {
            revert Bagholder__NotPaperHand();
        }

        /// -----------------------------------------------------------------------
        /// Storage loads
        /// -----------------------------------------------------------------------

        StakerInfo memory stakerInfo = stakerInfos[incentiveId][staker];
        IncentiveInfo memory incentiveInfo = incentiveInfos[incentiveId];

        /// -----------------------------------------------------------------------
        /// State updates
        /// -----------------------------------------------------------------------

        // accrue rewards
        (stakerInfo, incentiveInfo) = _accrueRewards(
            key,
            stakerInfo,
            incentiveInfo
        );

        // update NFT state
        delete stakers[incentiveId][nftId];

        // update staker state
        stakerInfo.numberOfStakedTokens -= 1;
        stakerInfos[incentiveId][staker] = stakerInfo;

        // update incentive state
        incentiveInfo.numberOfStakedTokens -= 1;
        incentiveInfos[incentiveId] = incentiveInfo;

        /// -----------------------------------------------------------------------
        /// External calls
        /// -----------------------------------------------------------------------

        // send bond to recipient as reward
        bondRecipient.safeTransferETH(key.bondAmount);

        emit SlashPaperHand(msg.sender, incentiveId, nftId, bondRecipient);
    }

    /// @notice Creates an incentive and transfers the reward tokens from the caller.
    /// @dev Will revert if the incentive key is invalid (e.g. startTime >= endTime)
    /// @param key the incentive's key
    /// @param rewardAmount the amount of reward tokens to add to the incentive
    function createIncentive(IncentiveKey calldata key, uint256 rewardAmount)
        external
        virtual
    {
        /// -----------------------------------------------------------------------
        /// Validation
        /// -----------------------------------------------------------------------

        bytes32 incentiveId = key.compute();
        ProtocolFeeInfo memory protocolFeeInfo_ = protocolFeeInfo;

        // ensure incentive doesn't already exist
        if (incentiveInfos[incentiveId].lastUpdateTime != 0) {
            revert Bagholder__IncentiveAlreadyExists();
        }

        // ensure incentive key is valid
        if (
            address(key.nft) == address(0) ||
            address(key.rewardToken) == address(0) ||
            key.startTime >= key.endTime ||
            key.endTime < block.timestamp
        ) {
            revert Bagholder__InvalidIncentiveKey();
        }

        // apply protocol fee
        uint256 protocolFeeAmount;
        if (protocolFeeInfo_.fee != 0) {
            protocolFeeAmount = FullMath.mulDiv(
                rewardAmount,
                protocolFeeInfo_.fee,
                1000
            );
            rewardAmount -= protocolFeeAmount;
        }

        // ensure incentive amount makes sense
        uint128 rewardRatePerSecond = (rewardAmount /
            (key.endTime - key.startTime)).safeCastTo128();
        if (rewardRatePerSecond == 0) {
            revert Bagholder__RewardAmountTooSmall();
        }

        /// -----------------------------------------------------------------------
        /// State updates
        /// -----------------------------------------------------------------------

        // create incentive info
        incentiveInfos[incentiveId] = IncentiveInfo({
            rewardRatePerSecond: rewardRatePerSecond,
            rewardPerTokenStored: 0,
            numberOfStakedTokens: 0,
            lastUpdateTime: block.timestamp.safeCastTo64(),
            accruedRefund: 0
        });

        /// -----------------------------------------------------------------------
        /// External calls
        /// -----------------------------------------------------------------------

        // transfer reward tokens from sender
        key.rewardToken.safeTransferFrom(
            msg.sender,
            address(this),
            rewardAmount
        );

        // transfer protocol fee
        if (protocolFeeAmount != 0) {
            key.rewardToken.safeTransferFrom(
                msg.sender,
                protocolFeeInfo_.recipient,
                protocolFeeAmount
            );
        }

        emit CreateIncentive(
            msg.sender,
            incentiveId,
            key,
            rewardAmount,
            protocolFeeAmount
        );
    }

    /// @notice Claims the reward tokens the caller has earned from a particular incentive.
    /// @param key the incentive's key
    /// @param recipient the recipient of the reward tokens
    /// @return rewardAmount the amount of reward tokens claimed
    function claimRewards(IncentiveKey calldata key, address recipient)
        external
        virtual
        returns (uint256 rewardAmount)
    {
        bytes32 incentiveId = key.compute();

        /// -----------------------------------------------------------------------
        /// Storage loads
        /// -----------------------------------------------------------------------

        StakerInfo memory stakerInfo = stakerInfos[incentiveId][msg.sender];
        IncentiveInfo memory incentiveInfo = incentiveInfos[incentiveId];

        // ensure the incentive exists
        if (incentiveInfo.lastUpdateTime == 0) {
            revert Bagholder__IncentiveNonexistent();
        }

        /// -----------------------------------------------------------------------
        /// State updates
        /// -----------------------------------------------------------------------

        // accrue rewards
        (stakerInfo, incentiveInfo) = _accrueRewards(
            key,
            stakerInfo,
            incentiveInfo
        );

        // update staker state
        rewardAmount = stakerInfo.totalRewardUnclaimed;
        stakerInfo.totalRewardUnclaimed = 0;
        stakerInfos[incentiveId][msg.sender] = stakerInfo;

        // update incentive state
        incentiveInfos[incentiveId] = incentiveInfo;

        /// -----------------------------------------------------------------------
        /// External calls
        /// -----------------------------------------------------------------------

        // transfer reward to user
        key.rewardToken.safeTransfer(recipient, rewardAmount);

        emit ClaimRewards(msg.sender, incentiveId, recipient);
    }

    function claimRefund(IncentiveKey calldata key)
        external
        virtual
        returns (uint256 refundAmount)
    {
        bytes32 incentiveId = key.compute();

        /// -----------------------------------------------------------------------
        /// Storage loads
        /// -----------------------------------------------------------------------

        IncentiveInfo memory incentiveInfo = incentiveInfos[incentiveId];
        refundAmount = incentiveInfo.accruedRefund;

        // ensure the incentive exists
        if (incentiveInfo.lastUpdateTime == 0) {
            revert Bagholder__IncentiveNonexistent();
        }

        /// -----------------------------------------------------------------------
        /// State updates
        /// -----------------------------------------------------------------------

        // accrue rewards
        uint256 lastTimeRewardApplicable = min(block.timestamp, key.endTime);
        uint256 rewardPerToken_ = _rewardPerToken(
            incentiveInfo,
            lastTimeRewardApplicable
        );

        if (incentiveInfo.numberOfStakedTokens == 0) {
            // [lastUpdateTime, lastTimeRewardApplicable] was a period without any staked NFTs
            // accrue refund
            refundAmount +=
                incentiveInfo.rewardRatePerSecond *
                (lastTimeRewardApplicable - incentiveInfo.lastUpdateTime);
        }
        incentiveInfo.rewardPerTokenStored = rewardPerToken_;
        incentiveInfo.lastUpdateTime = lastTimeRewardApplicable.safeCastTo64();
        incentiveInfo.accruedRefund = 0;

        // update incentive state
        incentiveInfos[incentiveId] = incentiveInfo;

        /// -----------------------------------------------------------------------
        /// External calls
        /// -----------------------------------------------------------------------

        // transfer refund to recipient
        key.rewardToken.safeTransfer(key.refundRecipient, refundAmount);

        emit ClaimRefund(msg.sender, incentiveId, refundAmount);
    }

    /// -----------------------------------------------------------------------
    /// View functions
    /// -----------------------------------------------------------------------

    /// @notice Computes the current rewardPerToken value of an incentive.
    /// @param key the incentive's key
    /// @return the rewardPerToken value
    function rewardPerToken(IncentiveKey calldata key)
        external
        view
        returns (uint256)
    {
        uint256 lastTimeRewardApplicable = min(block.timestamp, key.endTime);
        return
            _rewardPerToken(
                incentiveInfos[key.compute()],
                lastTimeRewardApplicable
            );
    }

    /// @notice Computes the amount of reward tokens a staker has accrued
    /// from an incentive.
    /// @param key the incentive's key
    /// @param staker the staker's address
    /// @return the amount of reward tokens accrued
    function earned(IncentiveKey calldata key, address staker)
        external
        view
        returns (uint256)
    {
        bytes32 incentiveId = key.compute();
        uint256 lastTimeRewardApplicable = min(block.timestamp, key.endTime);
        StakerInfo memory info = stakerInfos[incentiveId][staker];
        return
            _earned(
                info,
                _rewardPerToken(
                    incentiveInfos[key.compute()],
                    lastTimeRewardApplicable
                )
            );
    }

    /// -----------------------------------------------------------------------
    /// Owner functions
    /// -----------------------------------------------------------------------

    /// @notice Updates the protocol fee and/or the protocol fee recipient.
    /// Only callable by the owner.
    /// @param protocolFeeInfo_ The new protocol fee info
    function ownerSetProtocolFee(ProtocolFeeInfo calldata protocolFeeInfo_)
        external
        virtual
        onlyOwner
    {
        if (
            protocolFeeInfo_.fee != 0 &&
            protocolFeeInfo_.recipient == address(0)
        ) {
            revert Bagholder_ProtocolFeeRecipientIsZero();
        }
        protocolFeeInfo = protocolFeeInfo_;

        emit SetProtocolFee(protocolFeeInfo_);
    }

    /// -----------------------------------------------------------------------
    /// Internal utilities
    /// -----------------------------------------------------------------------

    function _rewardPerToken(
        IncentiveInfo memory info,
        uint256 lastTimeRewardApplicable
    ) internal pure returns (uint256) {
        if (info.numberOfStakedTokens == 0) {
            return info.rewardPerTokenStored;
        }
        return
            info.rewardPerTokenStored +
            FullMath.mulDiv(
                (lastTimeRewardApplicable - info.lastUpdateTime) * PRECISION,
                info.rewardRatePerSecond,
                info.numberOfStakedTokens
            );
    }

    function _earned(StakerInfo memory info, uint256 rewardPerToken_)
        internal
        pure
        returns (uint256)
    {
        return
            FullMath.mulDiv(
                info.numberOfStakedTokens,
                rewardPerToken_ - info.rewardPerTokenStored,
                PRECISION
            ) + info.totalRewardUnclaimed;
    }

    function _accrueRewards(
        IncentiveKey calldata key,
        StakerInfo memory stakerInfo,
        IncentiveInfo memory incentiveInfo
    ) internal view returns (StakerInfo memory, IncentiveInfo memory) {
        uint256 lastTimeRewardApplicable = min(block.timestamp, key.endTime);
        uint256 rewardPerToken_ = _rewardPerToken(
            incentiveInfo,
            lastTimeRewardApplicable
        );

        if (incentiveInfo.numberOfStakedTokens == 0) {
            // [lastUpdateTime, lastTimeRewardApplicable] was a period without any staked NFTs
            // accrue refund
            incentiveInfo.accruedRefund +=
                incentiveInfo.rewardRatePerSecond *
                (lastTimeRewardApplicable - incentiveInfo.lastUpdateTime);
        }
        incentiveInfo.rewardPerTokenStored = rewardPerToken_;
        incentiveInfo.lastUpdateTime = lastTimeRewardApplicable.safeCastTo64();

        stakerInfo.totalRewardUnclaimed = _earned(stakerInfo, rewardPerToken_)
            .safeCastTo192();
        stakerInfo.rewardPerTokenStored = rewardPerToken_;

        return (stakerInfo, incentiveInfo);
    }
}