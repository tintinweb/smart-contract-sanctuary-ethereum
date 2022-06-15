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

// File: contracts/veNEWO.sol


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

// Custom errors
error Unauthorized();
error InsufficientBalance(uint256 available, uint256 required);
error NotWhitelisted();
error FundsInGracePeriod();
error FundsNotUnlocked();
error InvalidSetting();
error LockTimeOutOfBounds(uint256 lockTime, uint256 lockMin, uint256 lockMax);
error LockTimeLessThanCurrent(uint256 currentUnlockDate, uint256 newUnlockDate);

/** 
 * @title Implements voting escrow tokens with time based locking system
 * @author gcontarini jocorrei
 * @dev This implementation tries to follow the ERC4626 standard
 * Implement a new constructor to deploy this contract 
 */
abstract contract VeVault is ReentrancyGuard, Pausable, IERC4626 {
    using SafeERC20 for IERC20;

    // Holds all params to implement the penalty/kick-off system
    struct Penalty {
        uint256 gracePeriod;
        uint256 maxPerc;
        uint256 minPerc;
        uint256 stepPerc;
    }
    
    // Hold all params to implement the locking system
    struct LockTimer {
        uint256 min;
        uint256 max;
        uint256 epoch;
        bool    enforce;
    }

    /* ========== STATE VARIABLES ========== */

    // Asset token
    address public _assetTokenAddress;
    uint256 public _totalManagedAssets;
    mapping(address => uint256) public _assetBalances;

    // Share (veToken)
    uint256 private _totalSupply;
    mapping(address => uint256) public _shareBalances;
    mapping(address => uint256) private _unlockDate;

    // ERC20 metadata
    string public _name;
    string public _symbol;

    LockTimer internal _lockTimer;
    Penalty internal _penalty;
    
    // Only allow recoverERC20 from this list
    mapping(address => bool) public whitelistRecoverERC20;

    // Constants
    uint256 private constant SEC_IN_DAY = 86400;
    uint256 private constant PRECISION = 1e2;
    // This value should be 1e17 but we are using 1e2 as precision
    uint256 private constant CONVERT_PRECISION  = 1e17 / PRECISION;
    // Polynomial coefficients used in veMult function
    uint256 private constant K_3 = 154143856;
    uint256 private constant K_2 = 74861590400;
    uint256 private constant K_1 = 116304927000000;
    uint256 private constant K = 90026564600000000;

    /* ========== CONSTRUCTOR ========== */

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }
    
    /* ========== VIEWS ========== */
    
    /**
     * @notice The address of the underlying token 
     * used for the Vault for accounting, depositing,
     * and withdrawing.
     */
    function asset() external view override returns (address assetTokenAddress) {
        return _assetTokenAddress;
    }

    /**
     * @notice Total amount of the underlying asset that is “managed” by Vault.
     */
    function totalAssets() external view override returns (uint256 totalManagedAssets) {
        return _totalManagedAssets;
    }

    /**
     * @notice Total of veTokens
     */
    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @notice Total of veTokens currently hold by an address
     */
    function balanceOf(address account) external view override returns (uint256) {
        return _shareBalances[account];
    }

    /** 
     * @dev Compliant to the ERC4626 interface.
     * @notice The amount of shares that the Vault would exchange 
     * for the amount of assets provided, in an ideal scenario where
     * all the conditions are met.
     */
    function convertToShares(uint256 assets, uint256 lockTime) public pure returns (uint256 shares) {
        return assets * veMult(lockTime) / PRECISION;
    }

    /**
     * @notice If no lock time is given, return the amount of veToken for the min amount of time locked.
     */
    function convertToShares(uint256 assets) override external view returns (uint256 shares) {
        return convertToShares(assets, _lockTimer.min);
    }
    
    /**
     * @notice The amount of assets that the Vault would exchange
     * for the amount of shares provided, in an ideal scenario where
     * all the conditions are met.
     * @dev Compliant to the ERC4626 interface.
     */
    function convertToAssets(uint256 shares, uint256 lockTime) public pure returns (uint256 assets) {
        return shares * PRECISION / veMult(lockTime);
    }

    /**
     * @notice If no lock time is given, return the amount of
     * veToken for the min amount of time locked.
     */
    function convertToAssets(uint256 shares) override external view returns (uint256 assets) {
        return convertToAssets(shares, _lockTimer.min);
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
     * @notice Allows an on-chain or off-chain user to simulate the
     * effects of their deposit at the current block, given current on-chain conditions.
     * @dev Compliant to the ERC4626 interface.
     */
    function previewDeposit(uint256 assets, uint256 lockTime) public pure returns (uint256 shares) {
        return convertToShares(assets, lockTime);
    }

    function previewDeposit(uint256 assets) override external view returns (uint256 shares) {
        return previewDeposit(assets, _lockTimer.min);
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
     * @notice Allows an on-chain or off-chain user to simulate the
     * effects of their mint at the current block, given current on-chain conditions.
     * @dev Compliant to the ERC4626 interface.
     */
    function previewMint(uint256 shares, uint256 lockTime) public pure returns (uint256 assets) {
        return convertToAssets(shares, lockTime);
    }

    /**
     * @notice If no lock time is given, return the amount of veToken for the min amount of time locked.
     */
    function previewMint(uint256 shares) override external view returns (uint256 assets) {
        return previewMint(shares, _lockTimer.min);
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
        return _assetBalances[owner];
    }

    /**
     * @notice Allows an on-chain or off-chain user to simulate the effects of their
     * withdrawal at the current block, given current on-chain conditions.
     * @dev Compliant to the ERC4626 interface.
     */
    function previewWithdraw(uint256 assets, uint256 lockTime) public pure returns (uint256 shares) {
        return convertToShares(assets, lockTime);
    }

    /**
     * @notice If no lock time is given, return the amount of veToken for the min amount of time locked.
     */
    function previewWithdraw(uint256 assets) override external view returns (uint256 shares) {
        return previewWithdraw(assets, _lockTimer.min);
    }
    
    /**
     * @notice Maximum amount of Vault shares that can be redeemed from the owner balance in the Vault, through a redeem call.
     * @dev Compliant to the ERC4626 interface.
     */
    function maxRedeem(address owner) override external view returns (uint256 maxShares) {
        if (paused) {
            return 0;
        }
        return _shareBalances[owner];
    }

    /**
     * @notice Allows an on-chain or off-chain user to simulate the effects of their
     * redeemption at the current block, given current on-chain conditions.
     * @dev Compliant to the ERC4626 interface.
     */
    function previewRedeem(uint256 shares, uint256 lockTime) public pure returns (uint256 assets) {
        return convertToAssets(shares, lockTime);
    }

    /**
     * @notice If no lock time is given, return the amount of veToken for the min amount of time locked.
     */
    function previewRedeem(uint256 shares) override external view returns (uint256 assets) {
        return previewRedeem(shares, _lockTimer.min);
    }
    
    /**
     * @notice Ve tokens are not transferable.
     * @dev Always returns zero.
     * ERC20 interface.
     */
    function allowance(address, address) override external pure returns (uint256) {
        return 0;
    }

    /**
     * @notice Total assets deposited by address
     * @dev Compliant to the ERC4626 interface.
     */
    function assetBalanceOf(address account) external view returns (uint256) {
        return _assetBalances[account];
    }

    /**
     * @notice Unlock date for an account
     */
    function unlockDate(address account) external view returns (uint256) {
        return _unlockDate[account];
    }

    /**
     * @notice How long is the grace period in seconds
     */
    function gracePeriod() external view returns (uint256) {
        return _penalty.gracePeriod;
    }

    /**
     * @notice Percentage paid per epoch after grace period plus the minimum percentage
     * This is paid to caller which withdraw veTokens in name of account in the underlying asset.
     */
    function penaltyPercentage() external view returns (uint256) {
        return _penalty.stepPerc;
    }

    /**
     * @notice Minimum lock time in seconds
     */
     function minLockTime() external view returns (uint256) {
         return _lockTimer.min;
     }
    
    /**
     * @notice Maximum lock time in seconds
     */
     function maxLockTime() external view returns (uint256) {
         return _lockTimer.max;
     }

     /**
     * @notice Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @notice Returns the symbol of the token, usually a shorter version of the name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
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

    /* ========== PURE FUNCTIONS ========== */

    /**
     * @notice Calculate the multipler applied to the amount of tokens staked.
     * @dev This functions implements the following polynomial: 
     * f(x) = x^3 * 1.54143856e-09 - x^2 * 7.48615904e-07 + x * 1.16304927e-03 + 9.00265646e-01
     * Which can be simplified to: f(x) = x^3 * K_3 - x^2 * K_2 + x * K_1 + K
     * Granularity is lost with lockTime between days
     * @param lockTime: time in seconds
     * @return multiplier with 2 digits of precision
     */
    function veMult(uint256 lockTime) internal pure returns (uint256) {
        return (
            (((lockTime / SEC_IN_DAY) ** 3) * K_3)
            + ((lockTime / SEC_IN_DAY) * K_1) + K
            - (((lockTime / SEC_IN_DAY) ** 2) * K_2)
            ) / CONVERT_PRECISION;
    }

    /**
     * @notice Returns the multiplier applied for an address
     * with 2 digits precision
     * @param owner: address of owner 
     * @return multiplier applied to an account, zero in case of no assets
     */
    function veMult(address owner) external view returns (uint256) {
        if (_assetBalances[owner] == 0) return 0;
        return _shareBalances[owner] * PRECISION / _assetBalances[owner];
    }
    
    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @notice Mints shares Vault shares to receiver by depositing exactly 
     * amount of underlying tokens.
     * Only allow deposits for caller equals receiver.
     * Relocks are only allowed if new unlock date is futherest
     * in the future. If user tries to reduce its lock period
     * the transaction will revert.
     * The multiplier applied is always the one from the last
     * deposit. And it's applied to the total amount deposited
     * so far. It's not possible to have 2 unclock dates for 
     * the same address.
     * @dev Compliant to the ERC4626 interface.
     * @param assets: amount of underlying tokens
     * @param receiver: address which the veTokens will be granted to
     * @param lockTime: how long the tokens will be locked
     * @return shares minted for receiver
     */
    function deposit(uint256 assets, address receiver, uint256 lockTime)
            external 
            nonReentrant
            notPaused 
            returns (uint256 shares) {
        return _deposit(assets, receiver, lockTime);
    }
    
    /**
     * @notice If no lock time is given, use the min lock time value.
     * @param assets: amount of underlying tokens
     * @param receiver: address which the veTokens will be granted to
     * @return shares minted for receiver
     */
    function deposit(uint256 assets, address receiver)
            override
            external
            nonReentrant
            notPaused 
            returns (uint256 shares) {
        return _deposit(assets, receiver, _lockTimer.min);
    }
    
    /**
     * @notice Mint shares for receiver by depositing
     * the necessary amount of underlying tokens.
     * Only allow deposits for caller equals receiver.
     * Relocks are only allowed if new unlock date is futherest
     * in the future. If user tries to reduce its lock period
     * the transaction will revert.
     * The multiplier applied is always the one from the last
     * deposit. And it's applied to the total amount deposited
     * so far. It's not possible to have 2 unclock dates for 
     * the same address.
     * @dev Not compliant to the ERC4626 interface
     * since it doesn't mint the exactly amount
     * of shares asked. The shares amount stays
     * within a 0.001% margin.
     * @param shares: amount of veTokens the receiver will get
     * @param receiver: address which the veTokens will be granted to
     * @param lockTime: how long the tokens will be locked
     * @return assets deposit in the vault
     */
    function mint(uint256 shares, address receiver, uint256 lockTime)
            external 
            nonReentrant
            notPaused
            returns (uint256 assets) {
        uint256 updatedShares = convertToShares(_assetBalances[receiver], lockTime);
        if (updatedShares > _shareBalances[receiver]) {
            uint256 diff = updatedShares - _shareBalances[receiver];
            if (shares <= diff)
                revert Unauthorized();
            assets = convertToAssets(shares - diff, lockTime);
        } else {
            uint256 diff = _shareBalances[receiver] - updatedShares;
            assets = convertToAssets(shares + diff, lockTime);
        }
        _deposit(assets, receiver, lockTime);
        return assets;
    }

    /**
     * @notice If no lock time is given, use the min lock time value.
     * @param shares: amount of veTokens the receiver will get
     * @param receiver: address which the veTokens will be granted to
     * @return assets deposit in the vault
     */
    function mint(uint256 shares, address receiver)
            override
            external
            nonReentrant
            notPaused
            returns (uint256 assets) {
        uint256 updatedShares = convertToShares(_assetBalances[receiver], _lockTimer.min);
        if (updatedShares > _shareBalances[receiver]) {
            uint256 diff = updatedShares - _shareBalances[receiver];
            assets = convertToAssets(shares - diff, _lockTimer.min);
        } else {
            uint256 diff = _shareBalances[receiver] - updatedShares;
            assets = convertToAssets(shares + diff, _lockTimer.min);
        }
        _deposit(assets, receiver, _lockTimer.min);
        return assets;
    }
    
    /**
     * @notice Burns shares from owner and sends exactly
     * assets of underlying tokens to receiver.
     * Allows owner to send their assets to another
     * address.
     * A caller can only withdraw assets from owner
     * to owner, receiving a reward for doing so.
     * This reward is paid from owner's asset balance.
     * Can only withdraw after unlockDate and withdraw
     * from another address after unlockDate plus grace
     * period.
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
            notPaused
            returns (uint256 shares) {
        return _withdraw(assets, receiver, owner);
    }

    /**
     * @notice Burns shares from owner and sends the correct
     * amount of underlying tokens to receiver.
     * Allows owner to send their assets to another
     * address.
     * A caller can only withdraw assets from owner
     * to owner, receiving a reward for doing so.
     * This reward is paid from owner asset balance.
     * Can only withdraw after unlockDate and withdraw
     * from another address after unlockDate plus grace
     * period.
     * @dev Not compliant to the ERC4626 interface
     * since it doesn't burn the exactly amount
     * of shares asked. The shares amount stays
     * within a 0.001% margin.
     * @param shares: amount of veTokens to burn 
     * @param receiver: address which tokens will be transfered to
     * @param owner: address which controls the veTokens 
     * @return assets transfered to receiver
     */
    function redeem(uint256 shares, address receiver, address owner)
            override
            external 
            nonReentrant 
            notPaused
            returns (uint256 assets) {
        uint256 diff = _shareBalances[owner] - _assetBalances[owner];
        if (shares < diff)
            revert Unauthorized();
        assets = shares - diff;
        _withdraw(assets, receiver, owner);
        return assets;
    }

    /**
     * @notice Withdraw all funds for the caller
     * @dev Best option to get all funds from an account
     * @return shares burned from caller 
     */
    function exit()
            external 
            nonReentrant 
            notPaused
            returns (uint256 shares) {
        return _withdraw(_assetBalances[msg.sender], msg.sender, msg.sender);
    }

    /**
    * @notice Owner can change the unlock rule to allow
    * withdraws before unlock date.
    * Ignores the rule if set to false.
    */
    function changeUnlockRule(bool flag) external onlyOwner {
        _lockTimer.enforce = flag;
    }

    /**
     * @notice Owner can change state variabes which controls the penalty system
     */
    function changeGracePeriod(uint256 newGracePeriod) external onlyOwner {
        _penalty.gracePeriod = newGracePeriod;
    }
    
    /**
     * @notice Owner can change state variabes which controls the penalty system
     */
    function changeEpoch(uint256 newEpoch) external onlyOwner {
        if (newEpoch == 0)
            revert InvalidSetting();
        _lockTimer.epoch = newEpoch;
    }
    
    /**
     * @notice Owner can change state variabes which controls the penalty system
     */
    function changeMinPenalty(uint256 newMinPenalty) external onlyOwner {
        if (newMinPenalty >= _penalty.maxPerc)
            revert InvalidSetting();
        _penalty.minPerc = newMinPenalty;
    }
    
    /**
     * @notice Owner can change state variabes which controls the penalty system
     */
    function changeMaxPenalty(uint256 newMaxPenalty) external onlyOwner {
        if (newMaxPenalty <= _penalty.minPerc)
            revert InvalidSetting();
        _penalty.maxPerc = newMaxPenalty;
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
        if (balance < tokenAmount) revert InsufficientBalance({
                available: balance,
                required: tokenAmount
        });
        
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

    /* ========== INTERNAL FUNCTIONS ========== */
    
    /**
     * @dev Handles deposit in which
     * new veTokens are minted.
     * Transfer asset tokens to
     * vault and lock it for a period.
     * @param assets: amount of underlying tokens
     * @param receiver: address which the veTokens will be granted to
     * @param lockTime: how long the tokens will be locked
     * @return shares minted for receiver 
     */
    function _deposit(
        uint256 assets,
        address receiver,
        uint256 lockTime
        ) internal 
        updateShares(receiver, lockTime)
        returns (uint256 shares) {
        if (msg.sender != receiver)
            revert Unauthorized();
        if (lockTime < _lockTimer.min || lockTime > _lockTimer.max)
            revert LockTimeOutOfBounds(lockTime, _lockTimer.min, _lockTimer.max);

        // Cannot lock more funds less than the current
        uint256 unlockTime = block.timestamp + lockTime;
        if (unlockTime < _unlockDate[receiver])
            revert LockTimeLessThanCurrent(_unlockDate[receiver], unlockTime);
        _unlockDate[receiver] = unlockTime;

        // The end balance of shares can be
        // lower than the amount returned by
        // this function
        shares = convertToShares(assets, lockTime);
        if (assets == 0) {
            emit Relock(msg.sender, receiver, assets, _unlockDate[receiver]);
        } else {
            // Update assets
            _totalManagedAssets += assets;
            _assetBalances[receiver] += assets;
            IERC20(_assetTokenAddress).safeTransferFrom(receiver, address(this), assets);
            emit Deposit(msg.sender, receiver, assets, shares);
        }
        return shares;
    }
    
    /**
     * @dev Handles withdraw in which veTokens are burned.
     * Transfer asset tokens from vault to receiver.
     * Only allows withdraw after correct unlock date.
     * The end balance of shares can be lower than 
     * the amount returned by this function
     * @param assets: amount of underlying tokens
     * @param receiver: address which the veTokens will be granted to
     * @param owner: address which holds the veTokens 
     * @return shares burned from owner
     */
    function _withdraw(
        uint256 assets,
        address receiver,
        address owner
        ) internal
        updateShares(receiver, _lockTimer.min)
        returns (uint256 shares) {
        if (owner == address(0)) revert Unauthorized();
        if (_assetBalances[owner] < assets)
            revert InsufficientBalance({
                available: _assetBalances[owner],
                required: assets
            });

        // To kickout someone
        if (msg.sender != owner) {
            // Must send the funds to owner
            if (receiver != owner)
                revert Unauthorized();
            // Only kickout after gracePeriod
            if (_lockTimer.enforce && (block.timestamp < _unlockDate[owner] + _penalty.gracePeriod))
                revert FundsNotUnlocked();
            // Pay reward to caller
            assets -= _payPenalty(owner, assets);
        }
        // Self withdraw
        else if (_lockTimer.enforce && block.timestamp < _unlockDate[owner])
            revert FundsNotUnlocked();

        // Withdraw assets
        _totalManagedAssets -= assets;
        _assetBalances[owner] -= assets;
        IERC20(_assetTokenAddress).safeTransfer(receiver, assets);
        shares = assets;
        emit Withdraw(msg.sender, receiver, owner, assets, shares);
        return shares;
    }

    /**
     * @dev Pay penalty to withdraw caller.
     * The reward is paid from owner account
     * with their underlying asset.
     * Only after the grace period it's paid.
     * It starts at the minimum penalty and
     * after each epoch it's increased. It's
     * capped at the max penalty.
     * @param owner: address which controls the veTokens
     * @param assets: amount of assets from owner being withdraw
     * @return amountPenalty amount of assets paid to caller
     */
    function _payPenalty(address owner, uint256 assets) internal returns (uint256 amountPenalty) {
        uint256 penaltyAmount = _penalty.minPerc 
                        + (((block.timestamp - (_unlockDate[owner] + _penalty.gracePeriod))
                            / _lockTimer.epoch)
                        * _penalty.stepPerc);

        if (penaltyAmount > _penalty.maxPerc) {
            penaltyAmount = _penalty.maxPerc;
        }
        amountPenalty = (assets * penaltyAmount) / 100;

        // Safety check 
        if (_assetBalances[owner] < amountPenalty)
            revert InsufficientBalance({
                available: _assetBalances[owner],
                required: amountPenalty
            });

        _totalManagedAssets -= amountPenalty;
        _assetBalances[owner] -= amountPenalty;

        IERC20(_assetTokenAddress).safeTransfer(msg.sender, amountPenalty);
        emit PayPenalty(msg.sender, owner, amountPenalty);
        return amountPenalty;
    }
    
    /**
     * @dev Update the correct amount of shares
     * In case of a deposit, always consider
     * the last lockTime for the multiplier.
     * But the unlockDate will always be the
     * one futherest in the future.
     * In a case of a withdraw, the min multiplier
     * is applied for the leftover assets in vault. 
     */
    modifier updateShares(address receiver, uint256 lockTime) {
        _;
        uint256 shares = convertToShares(_assetBalances[receiver], lockTime);
        uint256 oldShares = _shareBalances[receiver];
        if (oldShares < shares) {
            uint256 diff = shares - oldShares;
            _totalSupply += diff;
            emit Mint(receiver, diff);
        } else if (oldShares > shares) {
            uint256 diff = oldShares - shares;
            _totalSupply -= diff;
            emit Burn(receiver, diff);
        }
        _shareBalances[receiver] = shares;
    }
    
    /* ========== EVENTS ========== */

    event Relock(address indexed caller, address indexed receiver, uint256 assets, uint256 newUnlockDate);
    event PayPenalty(address indexed caller, address indexed owner, uint256 assets);
    event Burn(address indexed user, uint256 shares);
    event Mint(address indexed user, uint256 shares);
    event Recovered(address token, uint256 amount);
    event RecoveredNFT(address tokenAddress, uint256 tokenId);
    event ChangeWhitelistERC20(address indexed tokenAddress, bool whitelistState);
}

contract VeNewO is VeVault("veNewO", "veNWO") {
    constructor(
        address owner_,
        address stakingToken_,
        uint256 gracePeriod_,
        uint256 minLockTime_,
        uint256 maxLockTime_,
        uint256 penaltyPerc_,
        uint256 maxPenalty_,
        uint256 minPenalty_,
        uint256 epoch_
    ) Owned(owner_) {
        // assetToken = IERC20(stakingToken_);
        _assetTokenAddress = stakingToken_;

        _lockTimer.min = minLockTime_;
        _lockTimer.max = maxLockTime_;
        _lockTimer.epoch = epoch_;
        _lockTimer.enforce = true;
        
        _penalty.gracePeriod = gracePeriod_;
        _penalty.maxPerc = maxPenalty_;
        _penalty.minPerc = minPenalty_;
        _penalty.stepPerc = penaltyPerc_;

        paused = false;
    }
}