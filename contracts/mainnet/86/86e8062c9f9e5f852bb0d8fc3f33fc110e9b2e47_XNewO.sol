/**
 *Submitted for verification at Etherscan.io on 2022-06-15
*/

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


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

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/interfaces/IERC20.sol


// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;


// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;



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

// File: contracts/veLPvault.sol


pragma solidity ^0.8.13;






// https://docs.synthetix.io/contracts/source/contracts/Owned
abstract contract Owned {
    address public owner;
    address public nominatedOwner;

    constructor(address _owner) {
        require(_owner != address(0), "Owner address cannot be 0");
        owner = _owner;
        emit OwnerChanged(address(0), _owner);
    }

    function nominateNewOwner(address _owner) external onlyOwner {
        nominatedOwner = _owner;
        emit OwnerNominated(_owner);
    }

    function acceptOwnership() external {
        require(msg.sender == nominatedOwner, "You must be nominated before you can accept ownership");
        emit OwnerChanged(owner, nominatedOwner);
        owner = nominatedOwner;
        nominatedOwner = address(0);
    }

    modifier onlyOwner {
        _onlyOwner();
        _;
    }

    function _onlyOwner() private view {
        require(msg.sender == owner, "Only the contract owner may perform this action");
    }

    event OwnerNominated(address newOwner);
    event OwnerChanged(address oldOwner, address newOwner);
}

// https://docs.synthetix.io/contracts/source/contracts/Pausable
abstract contract Pausable is Owned {
    uint public lastPauseTime;
    bool public paused;

    constructor() {
        // This contract is abstract, and thus cannot be instantiated directly
        require(owner != address(0), "Owner must be set");
        // Paused will be false, and lastPauseTime will be 0 upon initialisation
    }

    /**
     * @notice Change the paused state of the contract
     * @dev Only the contract owner may call this.
     */
    function setPaused(bool _paused) external onlyOwner {
        // Ensure we're actually changing the state before we do anything
        if (_paused == paused) {
            return;
        }

        // Set our paused state.
        paused = _paused;

        // If applicable, set the last pause time.
        if (paused) {
            lastPauseTime = block.timestamp;
        }

        // Let everyone know that our pause state has changed.
        emit PauseChanged(paused);
    }

    event PauseChanged(bool isPaused);

    modifier notPaused {
        require(!paused, "This action cannot be performed while the contract is paused");
        _;
    }
}


// https://docs.synthetix.io/contracts/source/contracts/RewardsDistributionRecipient
abstract contract RewardsDistributionRecipient is Owned {
    address public rewardsDistribution;

    function notifyRewardAmount(uint256 reward) virtual external;

    modifier onlyRewardsDistribution() {
        require(msg.sender == rewardsDistribution, "Caller is not RewardsDistribution contract");
        _;
    }

    function setRewardsDistribution(address _rewardsDistribution) external onlyOwner {
        rewardsDistribution = _rewardsDistribution;
    }
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}


interface IERC4626 is IERC20 {
    // The address of the underlying token used for the Vault for accounting, depositing, and withdrawing.
    function asset() external view returns(address assetTokenAddress);

    // Total amount of the underlying asset that is “managed” by Vault.
    function totalAssets() external view returns(uint256 totalManagedAssets);

    // The amount of shares that the Vault would exchange for the amount of assets provided, in an ideal scenario where all the conditions are met.
    function convertToShares(uint256 assets) external view returns(uint256 shares); 

    // The amount of assets that the Vault would exchange for the amount of shares provided, in an ideal scenario where all the conditions are met.
    function convertToAssets(uint256 shares) external view returns(uint256 assets);
 
    // Maximum amount of the underlying asset that can be deposited into the Vault for the receiver, through a deposit call.
    function maxDeposit(address receiver) external view returns(uint256 maxAssets);

    // Allows an on-chain or off-chain user to simulate the effects of their deposit at the current block, given current on-chain conditions.
    function previewDeposit(uint256 assets) external view returns(uint256 shares);

    // Mints shares Vault shares to receiver by depositing exactly amount of underlying tokens.
    function deposit(uint256 assets, address receiver) external returns(uint256 shares);

    // Maximum amount of shares that can be minted from the Vault for the receiver, through a mint call.
    function maxMint(address receiver) external view returns(uint256 maxShares); 

    // Allows an on-chain or off-chain user to simulate the effects of their mint at the current block, given current on-chain conditions.
    function previewMint(uint256 shares) external view returns(uint256 assets);

    // Mints exactly shares Vault shares to receiver by depositing amount of underlying tokens.
    function mint(uint256 shares, address receiver) external returns(uint256 assets);

    // Maximum amount of the underlying asset that can be withdrawn from the owner balance in the Vault, through a withdraw call.
    function maxWithdraw(address owner) external view returns(uint256 maxAssets);

    // Allows an on-chain or off-chain user to simulate the effects of their withdrawal at the current block, given current on-chain conditions.
    function previewWithdraw(uint256 assets) external view returns(uint256 shares);

    // Burns shares from owner and sends exactly assets of underlying tokens to receiver.
    function withdraw(uint256 assets, address receiver, address owner) external returns(uint256 shares);

    // Maximum amount of Vault shares that can be redeemed from the owner balance in the Vault, through a redeem call.
    function maxRedeem(address owner) external view returns(uint256 maxShares);

    // Allows an on-chain or off-chain user to simulate the effects of their redeemption at the current block, given current on-chain conditions.
    function previewRedeem(uint256 shares) external view returns(uint256 assets);

    // Burns exactly shares from owner and sends assets of underlying tokens to receiver.
    function redeem(uint256 shares, address receiver, address owner) external returns(uint256 assets);

    event Deposit(address indexed caller, address indexed owner, uint256 assets, uint256 shares);
    event Withdraw(address indexed caller, address indexed receiver, address indexed owner, uint256 assets, uint256 shares);
}
interface IVeVault is IERC4626 {
    function asset() external view  returns (address assetTokenAddress);
    function totalAssets() external view  returns (uint256 totalManagedAssets);
    function totalSupply() external view  returns (uint256);
    function balanceOf(address account) external view  returns (uint256);
    function convertToShares(uint256 assets, uint256 lockTime) external view returns (uint256 shares);
    function convertToShares(uint256 assets)  external view returns (uint256 shares);
    function convertToAssets(uint256 shares, uint256 lockTime) external view returns (uint256 assets);
    function convertToAssets(uint256 shares)  external view returns (uint256 assets);
    function maxDeposit(address)  external pure returns (uint256 maxAssets);
    function previewDeposit(uint256 assets, uint256 lockTime) external view returns (uint256 shares);
    function previewDeposit(uint256 assets)  external view returns (uint256 shares);
    function maxMint(address)  external pure returns (uint256 maxShares);
    function previewMint(uint256 shares, uint256 lockTime) external view returns (uint256 assets);
    function previewMint(uint256 shares)  external view returns (uint256 assets);
    function maxWithdraw(address owner)  external view returns (uint256 maxAssets);
    function previewWithdraw(uint256 assets, uint256 lockTime) external view returns (uint256 shares);
    function previewWithdraw(uint256 assets)  external view returns (uint256 shares);
    function maxRedeem(address owner)  external view returns (uint256 maxShares);
    function previewRedeem(uint256 shares, uint256 lockTime) external view returns (uint256 assets);
    function previewRedeem(uint256 shares)  external view returns (uint256 assets);
    function allowance(address, address)  external view returns (uint256);
    function assetBalanceOf(address account) external view returns (uint256);
    function unlockDate(address account) external view returns (uint256);
    function gracePeriod() external view returns (uint256);
    function penaltyPercentage() external view returns (uint256);
    function minLockTime() external view returns (uint256);
    function maxLockTime() external view returns (uint256);
    function transfer(address, uint256) external  returns (bool);
    function approve(address, uint256) external  returns (bool);
    function transferFrom(address, address, uint256) external  returns (bool);
    function veMult(address owner) external view returns (uint256);
    function deposit(uint256 assets, address receiver, uint256 lockTime) external returns (uint256 shares);
    function deposit(uint256 assets, address receiver)  external returns (uint256 shares);
    function mint(uint256 shares, address receiver, uint256 lockTime) external returns (uint256 assets);
    function mint(uint256 shares, address receiver)  external returns (uint256 assets);
    function withdraw(uint256 assets, address receiver, address owner)  external returns (uint256 shares);
    function redeem(uint256 shares, address receiver, address owner)  external returns (uint256 assets);
    function exit() external returns (uint256 shares);
    function changeUnlockRule(bool flag) external;
    function changeGracePeriod(uint256 newGracePeriod) external;
    function changeEpoch(uint256 newEpoch) external;
    function changeMinPenalty(uint256 newMinPenalty) external;
    function changeMaxPenalty(uint256 newMaxPenalty) external;
    function changeWhitelistRecoverERC20(address tokenAddress, bool flag) external;
    function recoverERC20(address tokenAddress, uint256 tokenAmount) external;
    function recoverERC721(address tokenAddress, uint256 tokenId) external;

    event PayPenalty(address indexed caller, address indexed owner, uint256 assets);
    event Burn(address indexed user, uint256 shares);
    event Mint(address indexed user, uint256 shares);
    event Recovered(address token, uint256 amount);
    event RecoveredNFT(address tokenAddress, uint256 tokenId);
    event ChangeWhitelistERC20(address indexed tokenAddress, bool whitelistState);
}


// Custom errors
error Unauthorized();
error UnauthorizedClaim();
error NotImplemented();
error RewardTooHigh(uint256 allowed, uint256 reward);
error NotWhitelisted();
error InsufficientBalance();

/** 
 * @title Implements a reward system which grants rewards based on LP
 * staked in this contract and grants boosts based on depositor veToken balance
 * @author gcontarini jocorrei
 * @dev This implementation tries to follow the ERC4626 standard
 * Implement a new constructor to deploy this contract 
 */
abstract contract LpRewards is ReentrancyGuard, Pausable, RewardsDistributionRecipient, IERC4626 {
    using SafeERC20 for IERC20;

    struct Account {
        uint256 rewards;
        uint256 assets;
        uint256 shares;
        uint256 sharesBoost;
        uint256 rewardPerTokenPaid;
    }

    struct Total {
        uint256 managedAssets;
        uint256 supply;
    }
    
    /* ========= STATE VARIABLES ========= */

    // veVault
    address public veVault;
    // Reward token
    address public rewardsToken;
    // Asset token (LP token)
    address public assetToken;

    // Contract totals
    Total public total;
    // User info
    mapping(address => Account) internal accounts;

    // Reward per token
    uint256 public rewardPerTokenStored;
    uint256 public rewardRate = 0;

    // Epochs
    uint256 public periodFinish = 0;
    uint256 public rewardsDuration = 7 days;
    uint256 public lastUpdateTime;

    // Math precision
    uint256 internal constant PRECISION = 1e18; 
    
    // ERC20 metadata (The share token)
    string public _name;
    string public _symbol;

    // Only allow recoverERC20 from this list
    mapping(address => bool) public whitelistRecoverERC20;

    /* ============ CONSTRUCTOR ============== */

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /* ============ VIEWS (IERC4626) =================== */
    
    /**
     * @notice Address of asset token
     */
    function asset() override external view returns (address assetTokenAddress) {
        return assetToken;
    }
    
    /**
     * @notice Total of LP tokens hold by the contract
     */
    function totalAssets() override external view returns (uint256 totalManagedAssets) {
        return total.managedAssets;
    }

    /**
     * @notice Total of shares minted by the contract
     * This value is important to calculate the percentage
     * of reward for each staker
     */
    function totalSupply() override external view returns (uint256) {
        return total.supply;
    }

    /**
     * @notice Amount of shares an address has
     */
    function balanceOf(address owner) override external view returns (uint256) {
        return accounts[owner].shares;
    }

    /**
     * @notice Amount of LP staked by an address
     */
    function assetBalanceOf(address owner) external view returns (uint256) {
        return accounts[owner].assets;
    }

    /** 
     * @notice Maximum amount of the underlying asset that can
     * be deposited into the Vault for the receiver, through a deposit call.
     * @dev Compliant to the ERC4626 interface.
     */
    function maxDeposit(address) override external pure returns (uint256 maxAssets) {
        return 2 ** 256 - 1;
    }

    /**
     * @notice Maximum amount of shares that can be minted from the
     * Vault for the receiver, through a mint call.
     * @dev Compliant to the ERC4626 interface.
     */
    function maxMint(address) override external pure returns (uint256 maxShares) {
        return 2 ** 256 - 1;
    }

    /**
     * @notice Maximum amount of the underlying asset that can be withdrawn from the
     * owner balance in the Vault, through a withdraw call.
     * @dev Compliant to the ERC4626 interface.
     */
    function maxWithdraw(address owner) override external view returns (uint256 maxAssets) {
        if (paused) {
            return 0;
        }
        return accounts[owner].assets;
    }

    /**
     * @notice Maximum amount of Vault shares that can be redeemed from the owner balance in the Vault, through a redeem call.
     * @dev Compliant to the ERC4626 interface.
     */
    function maxRedeem(address owner) override external view returns (uint256 maxShares) {
        if (paused) {
            return 0;
        }
        // Since assets and (shares - sharesBoost) have an 1:1 ratio
        return accounts[owner].assets;
    }

    /** 
     * @notice The amount of shares that the Vault would exchange 
     * for the amount of assets provided, in an ideal scenario where
     * all the conditions are met.
     * @dev Compliant to the ERC4626 interface.
     */
    function convertToShares(uint256 assets) override external view returns (uint256 shares) {
        return assets * getMultiplier(msg.sender) / PRECISION;
    }

    /**
     * @notice The amount of assets that the Vault would exchange
     * for the amount of shares provided, in an ideal scenario where
     * all the conditions are met.
     * @dev Compliant to the ERC4626 interface.
     */
    function convertToAssets(uint256 shares) override external view returns (uint256 assets) {
        return shares * PRECISION / getMultiplier(msg.sender);
    }

    /** 
     * @notice Allows an on-chain or off-chain user to simulate the
     * effects of their deposit at the current block, given current on-chain conditions.
     * @dev Compliant to the ERC4626 interface.
     */
    function previewDeposit(uint256 assets) override external view returns (uint256 shares) {
        return assets * getMultiplier(msg.sender) / PRECISION;
    }

    /**
     * @notice Allows an on-chain or off-chain user to simulate the
     * effects of their mint at the current block, given current on-chain conditions.
     * @dev Compliant to the ERC4626 interface.
     */
    function previewMint(uint256 shares) override external view returns (uint256 assets) {
         return shares * PRECISION / getMultiplier(msg.sender);
    }

    /**
     * @notice Allows an on-chain or off-chain user to simulate the effects of their
     * withdrawal at the current block, given current on-chain conditions.
     * @dev Compliant to the ERC4626 interface.
     */
    function previewWithdraw(uint256 assets) override external view returns (uint256 shares) {
        return assets * getMultiplier(msg.sender) / PRECISION;
    }

    /**
     * @notice Allows an on-chain or off-chain user to simulate the effects of their
     * redeemption at the current block, given current on-chain conditions.
     * @dev Compliant to the ERC4626 interface.
     */
    function previewRedeem(uint256 shares) override external view returns (uint256 assets) {
        return shares * PRECISION / getMultiplier(msg.sender);
    }

    /**
     * @notice xNEWO tokens are not transferable.
     * @dev Always returns zero.
     */
    function allowance(address, address) override external pure returns (uint256) {
        return 0;
    }

    /**
     * @dev Returns the name, symbol and decimals of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint8) {
        return 18;
    }

     /* ========== ERC20 NOT ALLOWED FUNCTIONS ========== */

    /**
     * @notice ERC20 transfer are not allowed
     */
    function transfer(address, uint256) external pure override returns (bool) {
        revert Unauthorized();
    }

    /**
     * @notice ERC20 approve are not allowed
     */
    function approve(address, uint256) external pure override returns (bool) {
        revert Unauthorized();
    }

    /**
     * @notice ERC20 transferFrom are not allowed
     */
    function transferFrom(address, address, uint256) external pure override returns (bool) {
        revert Unauthorized();
    }

    /* ============== REWARD FUNCTIONS ====================== */

    /**
     * @notice Notify the reward contract about a deposit in the
     * veVault contract. This is important to assure the
     * contract will account user's rewards.
     * @return account with full information
     */
    function notifyDeposit() public updateReward(msg.sender) updateBoost(msg.sender) returns(Account memory) {
        emit NotifyDeposit(msg.sender, accounts[owner].assets, accounts[owner].shares);
        return accounts[owner];
    }

    /**
     * @notice Pick the correct date for applying the reward
     * Apply until the end of periodFinish or now
     * @return date which rewards are applicable
     */
    function lastTimeRewardApplicable() public view returns (uint256) {
        return block.timestamp < periodFinish ? block.timestamp : periodFinish;
    }

    /**
     * @notice Calculate how much reward must be given for an user
     * per token staked. 
     * @return amount of reward per token updated
     */
    function rewardPerToken() public view returns (uint256) {
        if (total.supply == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored
            + ((lastTimeRewardApplicable() - lastUpdateTime)
                * rewardRate
                * PRECISION 
                / total.supply
            );
    }
    
    /**
     * @notice Calculates how much rewards a staker earned 
     * until this moment.
     * @return amount of rewards earned so far
     */
    function earned(address owner) public view returns (uint256) {
        return accounts[owner].rewards
                + (accounts[owner].shares
                    * (rewardPerToken() - accounts[owner].rewardPerTokenPaid)
                    / PRECISION);
    }

    /**
     * @notice Total rewards that will be paid during the distribution
     */
    function getRewardForDuration() external view returns (uint256) {
        return rewardRate * rewardsDuration;
    }

    /**
     * @notice Claim rewards for user.
     * @dev In case of no rewards claimable
     * just update the user status and do nothing.
     */
    function getReward() public updateReward(msg.sender) returns (uint256 reward) {
        reward = accounts[msg.sender].rewards;
        if(reward <= 0)
            revert UnauthorizedClaim();
        accounts[msg.sender].rewards = 0;
        IERC20(rewardsToken).safeTransfer(msg.sender, reward);
        emit RewardPaid(msg.sender, reward);
        return reward;
    }

    /**
     * @notice Set the contract to start distribuiting rewards
     * for stakers.
     * @param reward: amount of tokens to be distributed
     */
    function notifyRewardAmount(uint256 reward)
            override
            external
            onlyRewardsDistribution
            updateReward(address(0)) {
        if (block.timestamp >= periodFinish)
            rewardRate = reward / rewardsDuration;
        else {
            uint256 remaining = periodFinish - block.timestamp;
            uint256 leftover = remaining * rewardRate;
            rewardRate = (reward + leftover) / rewardsDuration;
        }

        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
        uint balance = IERC20(rewardsToken).balanceOf(address(this));
        if(rewardRate > balance / rewardsDuration)
            revert RewardTooHigh({
                allowed: balance,
                reward: reward
            });
        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp + rewardsDuration;
        emit RewardAdded(reward);
    }

    /**
     * @notice Allow owner to change reward duration
     * Only allow the change if period finish has already ended
     */
    function setRewardsDuration(uint256 _rewardsDuration) external onlyOwner {
        if (block.timestamp <= periodFinish)
            revert Unauthorized();
        rewardsDuration = _rewardsDuration;
        emit RewardsDurationUpdated(rewardsDuration);
    }

    /* =================  GET EXTERNAL INFO  =================== */

    /**
     * @notice Get how much token (not veToken) owner has in the provided LP
     */
    function getNewoShare(address owner) public view returns (uint256) {
        uint112 reserve0; uint112 reserve1; uint32 timestamp;

        (reserve0, reserve1, timestamp) = IUniswapV2Pair(assetToken).getReserves();
        return accounts[owner].assets * reserve0
                / IUniswapV2Pair(assetToken).totalSupply();
    }

    /**
     * @notice Get the multiplier applied for the address in the veVault contract 
     */
    function getMultiplier(address owner) public view returns (uint256) {
        IVeVault veToken = IVeVault(veVault);
        uint256 assetBalance = veToken.assetBalanceOf(owner);
        
        // to make sure that there is no division by zero
        if (assetBalance == 0)
            return 1;
        return veToken.balanceOf(owner) * PRECISION / assetBalance;   
    }

    /**
     * @notice Get how much newo an address has locked in veVault
     */
    function getNewoLocked(address owner) public view returns (uint256) {
        return IVeVault(veVault).assetBalanceOf(owner);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */
    
    /**
     * @notice Mints shares to receiver by depositing exactly amount of underlying tokens.
     * @dev Compliant to the ERC4626 interface.
     * @param assets: amount of underlying tokens
     * @param receiver: address which the veTokens will be granted to
     * @return shares minted for receiver
     */
    function deposit(uint256 assets, address receiver)
            override
            external
            nonReentrant
            notPaused
            updateReward(receiver)
            updateBoost(receiver)
            returns (uint256 shares) {
        shares = assets;
        _deposit(assets, shares, receiver);
        return shares;
    }

    /**
     * @dev Not compliant to the ERC4626 interface.
     * Due to rounding issues, would be very hard and
     * gas expensive to make it properly works.
     * To avoid a bad user experience this function
     * will always revert.
     */
    function mint(uint256, address)
            override
            external
            pure
            returns (uint256) {
        revert NotImplemented();
    }

    /**
     * @notice Burns shares from owner and sends exactly
     * assets of underlying tokens to receiver.
     * Allows owner to send their assets to another
     * address.
     * @dev Compliant to the ERC4626 interface
     * @param assets: amount of underlying tokens
     * @param receiver: address which tokens will be transfered to
     * @param owner: address which controls the veTokens 
     * @return shares burned from owner
     */
    function withdraw(uint256 assets, address receiver, address owner)
            override
            external
            nonReentrant
            updateReward(owner)
            updateBoost(owner)
            returns(uint256 shares) {
        shares = assets;
        _withdraw(assets, shares, receiver, owner);
        return shares; 
    }

    /**
     * @dev Not compliant to the ERC4626 interface.
     * Due to rounding issues, would be very hard and
     * gas expensive to make it properly works.
     * To avoid a bad user experience this function
     * will always revert.
     */
    function redeem(uint256, address, address)
            override
            external 
            pure
            returns (uint256) {
        revert NotImplemented();
    }

    /**
     * @notice Perform a full withdraw
     * for caller and get all remaining rewards
     * @return reward claimed by the caller
     */
    function exit() external
            nonReentrant 
            updateReward(msg.sender)
            updateBoost(msg.sender)
            returns (uint256 reward) {
        _withdraw(accounts[msg.sender].assets, accounts[msg.sender].shares - accounts[msg.sender].sharesBoost, msg.sender, msg.sender);
        reward = getReward();
        return reward;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */
    
    /**
     * @dev Handles internal withdraw logic
     * Burns the correct shares amount and
     * transfer assets to receiver.
     * Only allows receiver equal owner
     * @param assets: amount of tokens to withdraw
     * @param shares: amount of shares to burn
     * @param receiver: address which the tokens will transfered to
     * @param owner: address which controls the shares
     */
    function _withdraw(uint256 assets, uint256 shares, address receiver, address owner) internal {
        if(assets <= 0 || owner != msg.sender 
            || accounts[owner].assets < assets
            || (accounts[owner].shares - accounts[owner].sharesBoost) < shares)
            revert Unauthorized();
    
        // Remove LP Tokens (assets)
        total.managedAssets -= assets;
        accounts[owner].assets -= assets;
        
        // Remove shares
        total.supply -= shares;
        accounts[owner].shares -= shares;

        IERC20(assetToken).safeTransfer(receiver, assets);

        // ERC4626 compliance has to emit withdraw event
        emit Withdraw(msg.sender, receiver, owner, assets, shares);
    }
    
    /**
     * @dev Handles internal deposit logic
     * Mints the correct shares amount and
     * transfer assets from caller to vault.
     * @param assets: amount of tokens to deposit 
     * @param shares: amount of shares to mint
     * @param receiver: address which the shares will be minted to, must be the same as caller
     */
    function _deposit(uint256 assets, uint256 shares, address receiver) internal {
        if(assets <= 0 || receiver != msg.sender)
            revert Unauthorized();
        // Lp tokens
        total.managedAssets += assets;
        accounts[receiver].assets += assets;

        // Vault shares
        total.supply += shares;
        accounts[receiver].shares += shares;

        IERC20(assetToken).safeTransferFrom(msg.sender, address(this), assets);
        emit Deposit(msg.sender, address(this), assets, shares);
    }

    /**
     * @notice Owner can whitelist an ERC20 to recover it afterwards.
     * Emits and event to notify all users about it 
     * @dev It's possible to owner whitelist the underlying token
     * and do some kind of rugpull. To prevent that, it'recommended
     * that owner is a multisig address. Also, it emits an event
     * of changes in the ERC20 whitelist as a safety check.
     * @param flag: true to allow recover for the token
     */
    function changeWhitelistRecoverERC20(address tokenAddress, bool flag) external onlyOwner {
        whitelistRecoverERC20[tokenAddress] = flag;
        emit ChangeWhitelistERC20(tokenAddress, flag);
    }

    /**
     * @notice Added to support to recover ERC20 token within a whitelist 
     */
    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        if (whitelistRecoverERC20[tokenAddress] == false) revert NotWhitelisted();
        
        uint balance = IERC20(tokenAddress).balanceOf(address(this));
        if (balance < tokenAmount) revert InsufficientBalance(); 

        IERC20(tokenAddress).safeTransfer(owner, tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }

    /**
     * @notice Added to support to recover ERC721 
     */
    function recoverERC721(address tokenAddress, uint256 tokenId) external onlyOwner {
        IERC721(tokenAddress).safeTransferFrom(address(this), owner, tokenId);
        emit RecoveredNFT(tokenAddress, tokenId);
    }
    
    /* ========== MODIFIERS ========== */

    /**
     * @dev Always apply this to update the current state
     * of earned rewards for caller
     */
    modifier updateReward(address owner) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (owner != address(0)) {
            accounts[owner].rewards = earned(owner);
            accounts[owner].rewardPerTokenPaid = rewardPerTokenStored;
        }
        _;
    }

    /**
     * @dev Whenever the amount of assets is changed
     * this will check and update the boosts correctly
     * This action can burn or mint new shares if necessary
     */
    modifier updateBoost(address owner) {
        _;
        uint256 oldShares = accounts[owner].shares;
        uint256 newShares = oldShares;
        if (getNewoShare(owner) <= getNewoLocked(owner)){
            newShares = accounts[owner].assets * getMultiplier(owner) / PRECISION;
        }
        if (newShares > oldShares) {
            // Mint boost shares
            uint256 diff = newShares - oldShares;
            total.supply += diff;
            accounts[owner].sharesBoost = diff;
            accounts[owner].shares = newShares;
            emit BoostUpdated(owner, accounts[owner].shares, accounts[owner].sharesBoost);
        } else if (newShares < oldShares) {
            // Burn boost shares
            uint256 diff = oldShares - newShares;
            total.supply -= diff;
            accounts[owner].sharesBoost = diff;
            accounts[owner].shares = newShares;
            emit BoostUpdated(owner, accounts[owner].shares, accounts[owner].sharesBoost);
        }
    }

    /* ========== EVENTS ========== */

    event RewardAdded(uint256 reward);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardsDurationUpdated(uint256 newDuration);
    event Recovered(address token, uint256 amount);
    event RecoveredNFT(address tokenAddress, uint256 tokenId);
    event ChangeWhitelistERC20(address indexed tokenAddress, bool whitelistState);
    event NotifyDeposit(address indexed user, uint256 assetBalance, uint256 sharesBalance);
    event BoostUpdated(address indexed owner, uint256 totalShares, uint256 boostShares);
}


contract XNewO is LpRewards("staked NEWO LP", "stNEWOlp") {
    constructor(
        address _owner,
        address _lp,
        address _rewardsToken,
        address _veTokenVault,
        address _rewardsDistribution
    ) Owned (_owner) {
        assetToken = _lp;
        rewardsToken = _rewardsToken;
        veVault = _veTokenVault;
        rewardsDistribution = _rewardsDistribution;
    }
}