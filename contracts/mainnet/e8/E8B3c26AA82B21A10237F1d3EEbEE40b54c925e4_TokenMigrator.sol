/**
 *Submitted for verification at Etherscan.io on 2022-08-08
*/

/**
 *Submitted for verification at Etherscan.io on 2022-07-26
*/

// Sources flattened with hardhat v2.9.2 https://hardhat.org

// File @rari-capital/solmate/src/tokens/[email protected]



/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

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
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

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
                    keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
                )
            );

            address recoveredAddress = ecrecover(digest, v, r, s);

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


// File @rari-capital/solmate/src/utils/[email protected]



/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
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
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(from, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "from" argument.
            mstore(add(freeMemoryPointer, 36), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 100 because the calldata length is 4 + 32 * 3.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 100, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "TRANSFER_FROM_FAILED");
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
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 68 because the calldata length is 4 + 32 * 2.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 68, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "TRANSFER_FAILED");
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
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
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

    function didLastOptionalReturnCallSucceed(bool callStatus) private pure returns (bool success) {
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
}


// File @openzeppelin/contracts/token/ERC20/[email protected]

// 
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)



/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
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


// File @openzeppelin/contracts/utils/[email protected]

// 
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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


// File @openzeppelin/contracts/token/ERC20/utils/[email protected]

// 
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)




/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


// File contracts/interfaces/IStaking.sol

// 


interface IStaking {
    function stake(uint256 _amount, address _recipient) external returns (bool);

    function claim(address recipient) external;

    function unstake(uint256 _amount, bool _trigger) external;

    function index() external view returns (uint256);
}


// File contracts/interfaces/IWXBTRFLY.sol

// 


interface IWXBTRFLY is IERC20 {
    function wrapFromBTRFLY(uint256 _amount) external returns (uint256);

    function unwrapToBTRFLY(uint256 _amount) external returns (uint256);

    function wrapFromxBTRFLY(uint256 _amount) external returns (uint256);

    function unwrapToxBTRFLY(uint256 _amount) external returns (uint256);

    function xBTRFLYValue(uint256 _amount) external view returns (uint256);

    function wBTRFLYValue(uint256 _amount) external view returns (uint256);

    function realIndex() external view returns (uint256);
}


// File contracts/interfaces/IBTRFLY.sol

// 


interface IBTRFLY is IERC20 {
    function mint(address account_, uint256 amount_) external;

    function burn(uint256 amount) external;

    function burnFrom(address account_, uint256 amount_) external;
}


// File contracts/interfaces/IMariposa.sol

// 


interface IMariposa {
    function mintFor(address _recipient, uint256 amount) external;
}


// File @rari-capital/solmate/src/utils/[email protected]



/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private reentrancyStatus = 1;

    modifier nonReentrant() {
        require(reentrancyStatus == 1, "REENTRANCY");

        reentrancyStatus = 2;

        _;

        reentrancyStatus = 1;
    }
}


// File @openzeppelin/contracts/utils/[email protected]

// 
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)



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


// File @openzeppelin/contracts/access/[email protected]

// 
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)



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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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


// File contracts/core/RLBTRFLY.sol

// 





/// @title RLBTRFLY
/// @author ████

/**
    @notice
    Partially adapted from Convex's CvxLockerV2 contract with some modifications and optimizations for the BTRFLY V2 requirements
*/

contract RLBTRFLY is ReentrancyGuard, Ownable {
    using SafeTransferLib for ERC20;

    /**
        @notice Lock balance details
        @param  amount      uint224  Locked amount in the lock
        @param  unlockTime  uint32   Unlock time of the lock
     */
    struct LockedBalance {
        uint224 amount;
        uint32 unlockTime;
    }

    /**
        @notice Balance details
        @param  locked           uint224          Overall locked amount
        @param  nextUnlockIndex  uint32           Index of earliest next unlock
        @param  lockedBalances   LockedBalance[]  List of locked balances data
     */
    struct Balance {
        uint224 locked;
        uint32 nextUnlockIndex;
        LockedBalance[] lockedBalances;
    }

    // 1 epoch = 1 week
    uint32 public constant EPOCH_DURATION = 1 weeks;
    // Full lock duration = 16 epochs
    uint256 public constant LOCK_DURATION = 16 * EPOCH_DURATION;

    ERC20 public immutable btrflyV2;

    uint256 public lockedSupply;

    mapping(address => Balance) public balances;

    bool public isShutdown;

    string public constant name = "Revenue-Locked BTRFLY";
    string public constant symbol = "rlBTRFLY";
    uint8 public constant decimals = 18;

    event Shutdown();
    event Locked(
        address indexed account,
        uint256 indexed epoch,
        uint256 amount
    );
    event Withdrawn(address indexed account, uint256 amount, bool relock);

    error ZeroAddress();
    error ZeroAmount();
    error IsShutdown();
    error InvalidNumber(uint256 value);

    /**
        @param  _btrflyV2  address  BTRFLYV2 token address
     */
    constructor(address _btrflyV2) {
        if (_btrflyV2 == address(0)) revert ZeroAddress();
        btrflyV2 = ERC20(_btrflyV2);
    }

    /**
        @notice Emergency method to shutdown the current locker contract which also force-unlock all locked tokens
     */
    function shutdown() external onlyOwner {
        if (isShutdown) revert IsShutdown();

        isShutdown = true;

        emit Shutdown();
    }

    /**
        @notice Locked balance of the specified account including those with expired locks
        @param  account  address  Account
        @return amount   uint256  Amount
     */
    function lockedBalanceOf(address account)
        external
        view
        returns (uint256 amount)
    {
        return balances[account].locked;
    }

    /**
        @notice Balance of the specified account by only including tokens in active locks
        @param  account  address  Account
        @return amount   uint256  Amount
     */
    function balanceOf(address account) external view returns (uint256 amount) {
        // Using storage as it's actually cheaper than allocating a new memory based variable
        Balance storage userBalance = balances[account];
        LockedBalance[] storage locks = userBalance.lockedBalances;
        uint256 nextUnlockIndex = userBalance.nextUnlockIndex;

        amount = balances[account].locked;

        uint256 locksLength = locks.length;

        // Skip all old records
        for (uint256 i = nextUnlockIndex; i < locksLength; ++i) {
            if (locks[i].unlockTime <= block.timestamp) {
                amount -= locks[i].amount;
            } else {
                break;
            }
        }

        // Remove amount locked in the next epoch
        if (
            locksLength > 0 &&
            uint256(locks[locksLength - 1].unlockTime) - LOCK_DURATION >
            getCurrentEpoch()
        ) {
            amount -= locks[locksLength - 1].amount;
        }

        return amount;
    }

    /**
        @notice Pending locked amount at the specified account
        @param  account  address  Account
        @return amount   uint256  Amount
     */
    function pendingLockOf(address account)
        external
        view
        returns (uint256 amount)
    {
        LockedBalance[] storage locks = balances[account].lockedBalances;

        uint256 locksLength = locks.length;

        if (
            locksLength > 0 &&
            uint256(locks[locksLength - 1].unlockTime) - LOCK_DURATION >
            getCurrentEpoch()
        ) {
            return locks[locksLength - 1].amount;
        }

        return 0;
    }

    /**
        @notice Locked balances details for the specifed account
        @param  account     address          Account
        @return total       uint256          Total amount
        @return unlockable  uint256          Unlockable amount
        @return locked      uint256          Locked amount
        @return lockData    LockedBalance[]  List of active locks
     */
    function lockedBalances(address account)
        external
        view
        returns (
            uint256 total,
            uint256 unlockable,
            uint256 locked,
            LockedBalance[] memory lockData
        )
    {
        Balance storage userBalance = balances[account];
        LockedBalance[] storage locks = userBalance.lockedBalances;
        uint256 nextUnlockIndex = userBalance.nextUnlockIndex;
        uint256 idx;

        for (uint256 i = nextUnlockIndex; i < locks.length; ++i) {
            if (locks[i].unlockTime > block.timestamp) {
                if (idx == 0) {
                    lockData = new LockedBalance[](locks.length - i);
                }

                lockData[idx] = locks[i];
                locked += lockData[idx].amount;
                ++idx;
            } else {
                unlockable += locks[i].amount;
            }
        }

        return (userBalance.locked, unlockable, locked, lockData);
    }

    /**
        @notice Get current epoch
        @return uint256  Current epoch
     */
    function getCurrentEpoch() public view returns (uint256) {
        return (block.timestamp / EPOCH_DURATION) * EPOCH_DURATION;
    }

    /**
        @notice Locked tokens cannot be withdrawn for the entire lock duration and are eligible to receive rewards
        @param  account  address  Account
        @param  amount   uint256  Amount
     */
    function lock(address account, uint256 amount) external nonReentrant {
        if (account == address(0)) revert ZeroAddress();
        if (amount == 0) revert ZeroAmount();

        btrflyV2.safeTransferFrom(msg.sender, address(this), amount);

        _lock(account, amount);
    }

    /**
        @notice Perform the actual lock
        @param  account  address  Account
        @param  amount   uint256  Amount
     */
    function _lock(address account, uint256 amount) internal {
        if (isShutdown) revert IsShutdown();

        Balance storage balance = balances[account];

        uint224 lockAmount = _toUint224(amount);

        balance.locked += lockAmount;
        lockedSupply += lockAmount;

        uint256 lockEpoch = getCurrentEpoch() + EPOCH_DURATION;
        uint256 unlockTime = lockEpoch + LOCK_DURATION;
        LockedBalance[] storage locks = balance.lockedBalances;
        uint256 idx = locks.length;

        // If the latest user lock is smaller than this lock, add a new entry to the end of the list
        // else, append it to the latest user lock
        if (idx == 0 || locks[idx - 1].unlockTime < unlockTime) {
            locks.push(
                LockedBalance({
                    amount: lockAmount,
                    unlockTime: _toUint32(unlockTime)
                })
            );
        } else {
            locks[idx - 1].amount += lockAmount;
        }

        emit Locked(account, lockEpoch, amount);
    }

    /**
        @notice Withdraw all currently locked tokens where the unlock time has passed
        @param  account     address  Account
        @param  relock      bool     Whether should relock
        @param  withdrawTo  address  Target receiver
     */
    function _processExpiredLocks(
        address account,
        bool relock,
        address withdrawTo
    ) internal {
        // Using storage as it's actually cheaper than allocating a new memory based variable
        Balance storage userBalance = balances[account];
        LockedBalance[] storage locks = userBalance.lockedBalances;
        uint224 locked;
        uint256 length = locks.length;

        if (isShutdown || locks[length - 1].unlockTime <= block.timestamp) {
            locked = userBalance.locked;
            userBalance.nextUnlockIndex = _toUint32(length);
        } else {
            // Using nextUnlockIndex to reduce the number of loops
            uint32 nextUnlockIndex = userBalance.nextUnlockIndex;

            for (uint256 i = nextUnlockIndex; i < length; ++i) {
                // Unlock time must be less or equal to time
                if (locks[i].unlockTime > block.timestamp) break;

                // Add to cumulative amounts
                locked += locks[i].amount;
                ++nextUnlockIndex;
            }

            // Update the account's next unlock index
            userBalance.nextUnlockIndex = nextUnlockIndex;
        }

        if (locked == 0) revert ZeroAmount();

        // Update user balances and total supplies
        userBalance.locked -= locked;
        lockedSupply -= locked;

        emit Withdrawn(account, locked, relock);

        // Relock or return to user
        if (relock) {
            _lock(withdrawTo, locked);
        } else {
            btrflyV2.safeTransfer(withdrawTo, locked);
        }
    }

    /**
        @notice Withdraw expired locks to a different address
        @param  to  address  Target receiver
     */
    function withdrawExpiredLocksTo(address to) external nonReentrant {
        if (to == address(0)) revert ZeroAddress();

        _processExpiredLocks(msg.sender, false, to);
    }

    /**
        @notice Withdraw/relock all currently locked tokens where the unlock time has passed
        @param  relock  bool  Whether should relock
     */
    function processExpiredLocks(bool relock) external nonReentrant {
        _processExpiredLocks(msg.sender, relock, msg.sender);
    }

    /**
        @notice Validate and cast a uint256 integer to uint224
        @param  value  uint256  Value
        @return        uint224  Casted value
     */
    function _toUint224(uint256 value) internal pure returns (uint224) {
        if (value > type(uint224).max) revert InvalidNumber(value);

        return uint224(value);
    }

    /**
        @notice Validate and cast a uint256 integer to uint32
        @param  value  uint256  Value
        @return        uint32   Casted value
     */
    function _toUint32(uint256 value) internal pure returns (uint32) {
        if (value > type(uint32).max) revert InvalidNumber(value);

        return uint32(value);
    }
}


// File contracts/core/TokenMigrator.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;








/// @title BTRFLY V1 => V2 Token Migrator
/// @author Realkinando

/**
    @notice
    Enables users to convert BTRFLY, xBTRFLY & wxBTRFLY to BTRFLYV2, at a rate based on the wxStaking Index.
    Dependent on the contract having a sufficient allowance from Mariposa.

    receives btrfly/xBtrfly/wxBtrfly --> requests wx value for recipient --> unwraps btrfly and burns
*/

contract TokenMigrator {
    using SafeERC20 for IBTRFLY;
    using SafeERC20 for IWXBTRFLY;
    using SafeTransferLib for ERC20;

    IWXBTRFLY public immutable wxBtrfly;
    ERC20 public immutable xBtrfly;
    ERC20 public immutable btrflyV2;
    IBTRFLY public immutable btrfly;
    IMariposa public immutable mariposa;
    IStaking public immutable staking;
    RLBTRFLY public immutable rlBtrfly;

    error ZeroAddress();

    event Migrate(
        uint256 wxAmount,
        uint256 xAmount,
        uint256 v1Amount,
        address indexed recipient,
        bool indexed lock,
        address indexed caller
    );

    /**
        @param wxBtrfly_  address  wxBTRFLY token address
        @param xBtrfly_   address  xBTRFLY token address
        @param btrflyV2_  address  BTRFLYV2 token address
        @param btrfly_    address  BTRFLY token address
        @param mariposa_  address  Mariposa contract address
        @param staking_   address  Staking contract address
        @param rlBtrfly_  address  rlBTRFLY token address
     */
    constructor(
        address wxBtrfly_,
        address xBtrfly_,
        address btrflyV2_,
        address btrfly_,
        address mariposa_,
        address staking_,
        address rlBtrfly_
    ) {
        if (wxBtrfly_ == address(0)) revert ZeroAddress();
        if (xBtrfly_ == address(0)) revert ZeroAddress();
        if (btrflyV2_ == address(0)) revert ZeroAddress();
        if (btrfly_ == address(0)) revert ZeroAddress();
        if (mariposa_ == address(0)) revert ZeroAddress();
        if (staking_ == address(0)) revert ZeroAddress();
        if (rlBtrfly_ == address(0)) revert ZeroAddress();

        wxBtrfly = IWXBTRFLY(wxBtrfly_);
        xBtrfly = ERC20(xBtrfly_);
        btrflyV2 = ERC20(btrflyV2_);
        btrfly = IBTRFLY(btrfly_);
        mariposa = IMariposa(mariposa_);
        staking = IStaking(staking_);
        rlBtrfly = RLBTRFLY(rlBtrfly_);

        xBtrfly.safeApprove(staking_, type(uint256).max);
        btrflyV2.safeApprove(rlBtrfly_, type(uint256).max);
    }

    /**
        @notice Migrate wxBTRFLY to BTRFLYV2
        @param  amount  uint256  Amount of wxBTRFLY to convert to BTRFLYV2
        @return         uint256  Amount of BTRFLY to burn
     */
    function _migrateWxBtrfly(uint256 amount) internal returns (uint256) {
        // Take custody of wxBTRFLY and unwrap to BTRFLY
        wxBtrfly.safeTransferFrom(msg.sender, address(this), amount);

        return wxBtrfly.unwrapToBTRFLY(amount);
    }

    /**
        @notice Migrate xBTRFLY to BTRFLYV2
        @param  amount      uint256  Amount of xBTRFLY to convert to BTRFLYV2
        @return mintAmount  uint256  Amount of BTRFLYV2 to mint
     */
    function _migrateXBtrfly(uint256 amount)
        internal
        returns (uint256 mintAmount)
    {
        // Unstake xBTRFLY
        xBtrfly.safeTransferFrom(msg.sender, address(this), amount);
        staking.unstake(amount, false);

        return wxBtrfly.wBTRFLYValue(amount);
    }

    /**
        @notice Migrate BTRFLY to BTRFLYV2
        @param  amount      uint256  Amount of BTRFLY to convert to BTRFLYV2
        @return mintAmount  uint256  Amount of BTRFLYV2 to mint
     */
    function _migrateBtrfly(uint256 amount)
        internal
        returns (uint256 mintAmount)
    {
        btrfly.safeTransferFrom(msg.sender, address(this), amount);

        return wxBtrfly.wBTRFLYValue(amount);
    }

    /**
        @notice Migrates multiple different BTRFLY token types to V2
        @param  wxAmount   uint256  Amount of wxBTRFLY
        @param  xAmount    uint256  Amount of xBTRFLY
        @param  v1Amount   uint256  Amount of BTRFLY
        @param  recipient  address  Address receiving V2 BTRFLY
        @param  lock       bool     Whether or not to lock
     */
    function migrate(
        uint256 wxAmount,
        uint256 xAmount,
        uint256 v1Amount,
        address recipient,
        bool lock
    ) external {
        if (recipient == address(0)) revert ZeroAddress();

        emit Migrate(wxAmount, xAmount, v1Amount, recipient, lock, msg.sender);

        uint256 burnAmount;
        uint256 mintAmount;

        if (wxAmount != 0) {
            burnAmount = _migrateWxBtrfly(wxAmount);
            mintAmount = wxAmount;
        }

        if (xAmount != 0) {
            burnAmount += xAmount;
            mintAmount += _migrateXBtrfly(xAmount);
        }

        if (v1Amount != 0) {
            burnAmount += v1Amount;
            mintAmount += _migrateBtrfly(v1Amount);
        }

        btrfly.burn(burnAmount);
        _mintBtrflyV2(mintAmount, recipient, lock);
    }

    /**
        @notice Mint BTRFLYV2 and (optionally) lock
        @param  amount     uint256  Amount of BTRFLYV2 to mint
        @param  recipient  address  Address to receive V2 BTRFLY
        @param  lock       bool     Whether or not to lock
     */
    function _mintBtrflyV2(
        uint256 amount,
        address recipient,
        bool lock
    ) internal {
        // If locking, mint BTRFLYV2 for TokenMigrator, who will lock on behalf of recipient
        mariposa.mintFor(lock ? address(this) : recipient, amount);

        if (lock) rlBtrfly.lock(recipient, amount);
    }
}