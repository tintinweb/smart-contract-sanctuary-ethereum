/**
 *Submitted for verification at Etherscan.io on 2022-03-27
*/

// Dependency file: @openzeppelin/contracts/security/ReentrancyGuard.sol

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

// pragma solidity ^0.8.0;

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


// Dependency file: @openzeppelin/contracts/utils/Context.sol

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

// pragma solidity ^0.8.0;

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


// Dependency file: @openzeppelin/contracts/security/Pausable.sol

// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

// pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}


// Dependency file: @openzeppelin/contracts/access/Ownable.sol

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

// pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/utils/Context.sol";

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


// Dependency file: @openzeppelin/contracts/token/ERC20/IERC20.sol

// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

// pragma solidity ^0.8.0;

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


// Dependency file: @openzeppelin/contracts/utils/Address.sol

// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

// pragma solidity ^0.8.1;

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


// Dependency file: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol

// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

// pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/utils/Address.sol";

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


// Dependency file: contracts/traits/WithdrawalElement.sol


// pragma solidity ^0.8.9;

// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

abstract contract WithdrawalElement {
    using SafeERC20 for IERC20;
    using Address for address;

    event WithdrawToken(address token, address recipient, uint256 amount);
    event Withdraw(address recipient, uint256 amount);

    function _deliverFunds(
        address _recipient,
        uint256 _value,
        string memory _message
    ) internal {
        (bool sent, ) = payable(_recipient).call{value: _value}("");

        require(sent, _message);
    }

    function _deliverTokens(
        address _token,
        address _recipient,
        uint256 _value
    ) internal {
        IERC20(_token).safeTransfer(_recipient, _value);
    }

    function _withdraw(address _recipient, uint256 _amount) internal virtual {
        require(_recipient != address(0x0), "CryptoDrop Loto: address is zero");
        require(
            _amount <= address(this).balance,
            "CryptoDrop Loto: not enought BNB balance"
        );

        _afterWithdraw(_recipient, _amount);

        _deliverFunds(_recipient, _amount, "CryptoDrop Loto: Can't send BNB");
        emit Withdraw(_recipient, _amount);
    }

    function _afterWithdraw(address _recipient, uint256 _amount)
        internal
        virtual
    {}

    function _withdrawToken(
        address _token,
        address _recipient,
        uint256 _amount
    ) internal virtual {
        require(_recipient != address(0x0), "CryptoDrop Loto: address is zero");
        require(
            _amount <= IERC20(_token).balanceOf(address(this)),
            "CryptoDrop Loto: not enought token balance"
        );

        IERC20(_token).safeTransfer(_recipient, _amount);

        _afterWithdrawToken(_token, _recipient, _amount);

        emit WithdrawToken(_token, _recipient, _amount);
    }

    function _afterWithdrawToken(
        address _token,
        address _recipient,
        uint256 _amount
    ) internal virtual {}
}


// Dependency file: contracts/interfaces/ISNC.sol


// pragma solidity ^0.8.9;

interface ISNC {
    function mint(address _to, uint256 _tokenId) external;
}


// Root file: contracts/NFTSaleMultipleMint.sol


pragma solidity ^0.8.9;

// import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
// import "@openzeppelin/contracts/security/Pausable.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";
// import "contracts/traits/WithdrawalElement.sol";
// import "contracts/interfaces/ISNC.sol";

contract NFTSale is
    Ownable,
    Pausable,
    ReentrancyGuard,
    WithdrawalElement
{
    using SafeERC20 for IERC20;
    using Address for address;

    enum STATUS {
        QUED,
        ACTIVE,
        FINISHED,
        FAILED
    }

    struct Round {
        uint256 startTime;
        uint256 endTime;
        uint256 mintFee;
        uint256 supply;
        uint256 collected;
        uint256 maxTokensPerWallet;
        bool whitelistOnly;
    }

    Round[] public rounds;


    uint256 public lastRoundIndex;

    uint256 public tokenMinted;

    uint256 public requestsReceived;
      
    mapping(address => bool) public whitelistAddresses;

    mapping(uint256 => mapping(address => uint256)) public tokensPerWallet;

    //request => token ids

    mapping(uint256 => uint256[]) public requests;

    //address => request ids
    mapping(address => uint256[]) public userRequests;

    address public sncAddress;
    address public teamAddress;

    event UpdateSncAddress(address sncAddress);
    event UpdateTeamAddress(address teamAddress);
   
    event AddRound(
        uint256 startTime,
        uint256 endTime,
        uint256 mintFee,
        uint256 supply,
        uint256 maxTokensPerWallet,
        bool whitelistOnly
    );

    event ChangeRound(
        uint256 startTime,
        uint256 endTime,
        uint256 mintFee,
        uint256 supply,
        uint256 maxTokensPerWallet,
        bool whitelistOnly
    );

    event MintToken(
        uint256 roundId,
        address account,
        uint256 requestId,
        uint256 tokenId
    );

    event RequestReceived(
        address user, 
        uint256 requestId
    );
    
    receive() external payable {
        mint();
    }

    constructor(address _sncAddress, address _teamAddress) {

        sncAddress = _sncAddress;
        teamAddress = _teamAddress;
    }


    function addRound(
        uint256 _startTime,
        uint256 _endTime,
        uint256 _mintFee,
        uint256 _supply,
        uint256 _maxTokensPerWallet,
        bool _whitelistOnly
    ) external onlyOwner {
        Round memory round = Round(
            _startTime,
            _endTime,
            _mintFee,
            _supply,
            0,
            _maxTokensPerWallet,
            _whitelistOnly
        );

        rounds.push(round);

        emit AddRound(
            _startTime,
            _endTime,
            _mintFee,
            _supply,
            _maxTokensPerWallet,
            _whitelistOnly
        );
    }

    function changeRound(
        uint256 _roundId,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _mintFee,
        uint256 _supply,
        uint256 _maxTokensPerWallet,
        bool _whitelistOnly
    ) external onlyOwner {
        require(_roundId < rounds.length, "NFT Sale: round id invalid");

        Round storage round = rounds[_roundId];

        round.startTime = _startTime;
        round.endTime = _endTime;
        round.mintFee = _mintFee;
        round.supply = _supply;
        round.maxTokensPerWallet = _maxTokensPerWallet;
        round.whitelistOnly = _whitelistOnly;

        emit ChangeRound(
            _startTime,
            _endTime,
            _mintFee,
            _supply,
            _maxTokensPerWallet,
            _whitelistOnly
        );
    }

    function changeTimeForRound(
        uint256 _roundId,
        uint256 _startTime,
        uint256 _endTime
    ) external onlyOwner {
        require(_roundId < rounds.length, "NFT Sale: round id invalid");

        Round storage round = rounds[_roundId];

        round.startTime = _startTime;
        round.endTime = _endTime;

        emit ChangeRound(
            round.startTime,
            round.endTime,
            round.mintFee,
            round.supply,
            round.maxTokensPerWallet,
            round.whitelistOnly
        );
    }

    function changeMintFeeForRound(uint256 _roundId, uint256 _mintFee)
        external
        onlyOwner
    {
        require(_roundId < rounds.length, "NFT Sale: round id invalid");

        Round storage round = rounds[_roundId];

        round.mintFee = _mintFee;

        emit ChangeRound(
            round.startTime,
            round.endTime,
            round.mintFee,
            round.supply,
            round.maxTokensPerWallet,
            round.whitelistOnly
        );
    }

    function changeSupplyForRound(uint256 _roundId, uint256 _supply)
        external
        onlyOwner
    {
        require(_roundId < rounds.length, "NFT Sale: round id invalid");

        Round storage round = rounds[_roundId];

        round.supply = _supply;

        emit ChangeRound(
            round.startTime,
            round.endTime,
            round.mintFee,
            round.supply,
            round.maxTokensPerWallet,
            round.whitelistOnly
        );
    }

    function changeMaxTokensPerWalletForRound(
        uint256 _roundId,
        uint256 _maxTokensPerWallet
    ) external onlyOwner {
        require(_roundId < rounds.length, "NFT Sale: round id invalid");

        Round storage round = rounds[_roundId];

        round.maxTokensPerWallet = _maxTokensPerWallet;

        emit ChangeRound(
            round.startTime,
            round.endTime,
            round.mintFee,
            round.supply,
            round.maxTokensPerWallet,
            round.whitelistOnly
        );
    }

    function changeWhiteListStatusForRound(
        uint256 _roundId,
        bool _whitelistOnly
    ) external onlyOwner {
        require(_roundId < rounds.length, "NFT Sale: round id invalid");

        Round storage round = rounds[_roundId];

        round.whitelistOnly = _whitelistOnly;

        emit ChangeRound(
            round.startTime,
            round.endTime,
            round.mintFee,
            round.supply,
            round.maxTokensPerWallet,
            round.whitelistOnly
        );
    }

    function mint() public payable whenNotPaused nonReentrant {
        _calculateRound();

        require(
            _status(lastRoundIndex) == STATUS.ACTIVE,
            "NFTSale: sale is not started yet or ended"
        );

        Round storage round = rounds[lastRoundIndex];

        require(
            tokensPerWallet[lastRoundIndex][_msgSender()] <
                round.maxTokensPerWallet,
            "NFT Sale: max tokens per wallet reached"
        );

        
        uint256 requestId = requestsReceived;

        _mint(msg.sender, requestId, msg.value,  round);
        
        userRequests[_msgSender()].push(requestId);

        emit RequestReceived(_msgSender(), requestId);

        requestsReceived += 1;

        tokensPerWallet[lastRoundIndex][_msgSender()] += 1;
    }

    function _mint(address _user, uint256 _requestId, uint256 _amount,Round storage _round) internal {
        uint256 maxTokens = _round.maxTokensPerWallet;
        uint256 mintFee = _round.mintFee;
        uint256 rest = _amount;

        require(
            _amount >= _round.mintFee,
            "NFTSale: cannot enough ETH for mint"
        );

        for (uint8 i = 0; i < maxTokens; i++) {

            if (rest >= mintFee) {
                ISNC(sncAddress).mint(_user, tokenMinted);
                requests[_requestId].push(tokenMinted);
                rest = rest - mintFee;
                tokenMinted += 1;
                _round.collected += 1;
            }
        }

        if (rest > 0) {
             _deliverFunds(
                _user,
                rest,
                "NFTSale: failed transfer ETH to address"
            );
        }

        if (address(this).balance > 0) {
            _deliverFunds(
                teamAddress,
                address(this).balance,
                "NFTSale: failed transfer ETH to address"
            );
        }
    }

    function getUserRequestsLength(address _account)
        external
        view
        returns (uint256 length)
    {
        length = userRequests[_account].length;
    }
    
    function getTokenIds(address _account, uint256 _requestIndex) external view returns (uint256[] memory ids) {
        uint256 requestId = userRequests[_account][_requestIndex];

        ids = requests[requestId];
    }

    function _calculateRound() internal {
        Round memory round = rounds[lastRoundIndex];

        if (
            (block.timestamp > round.endTime) &&
            (lastRoundIndex + 1 < rounds.length)
        ) {
            lastRoundIndex += 1;
        }
    }

    function getLastRoundIndex()
        external
        view
        returns (uint256 _lastRoundIndex)
    {
        Round memory round = rounds[lastRoundIndex];

        _lastRoundIndex = lastRoundIndex;
        if (
            (block.timestamp > round.endTime) &&
            (lastRoundIndex + 1 < rounds.length)
        ) {
            _lastRoundIndex += 1;
        }
    }

    function getRoundSupply(uint256 _roundIndex)
        public
        view
        returns (uint256 supply)
    {
        if (_roundIndex == 0) {

            Round memory round = rounds[0];

            supply = round.supply;

        } else {

            Round memory round = rounds[_roundIndex];

            supply = round.supply;

            for (uint256 j = _roundIndex - 1; j > 0; j--) {
                Round memory prevRound = rounds[j];
                supply += prevRound.supply - prevRound.collected;
            }

            Round memory firstRound = rounds[0];

            supply += firstRound.supply - firstRound.collected;
        }
    }

   
    /// sale status
    function status(uint256 _roundId) external view returns (STATUS) {
        return _status(_roundId);
    }

    function _status(uint256 _roundIndex) internal view returns (STATUS) {
        Round memory round = rounds[_roundIndex];

        if (
            (block.timestamp >= round.startTime) &&
            (block.timestamp <= round.endTime)
        ) {
            if (round.collected == getRoundSupply(_roundIndex)) {
                return STATUS.FINISHED;
            }

            if (!round.whitelistOnly) {
                return STATUS.ACTIVE; // ACTIVE - mint enabled
            } else {
                //whitelisted
                if (whitelistAddresses[_msgSender()]) {
                    return STATUS.ACTIVE;
                } else {
                    return STATUS.FAILED;
                }
            }
        }

        if (block.timestamp > round.endTime) {
            return STATUS.FINISHED;
        }

        return STATUS.QUED; // QUED - awaiting start time
    }

    /// @notice management function. Withdraw all tokens in emergency mode only when contract paused
    function withdrawToken(address _token, address _recipient)
        external
        virtual
        whenPaused
        onlyOwner
    {
        uint256 amount = IERC20(_token).balanceOf(address(this));

        _withdrawToken(_token, _recipient, amount);
        _afterWithdrawToken(_token, _recipient, amount);
    }

    /// @notice management function. Withdraw  some tokens in emergency mode only when contract paused
    function withdrawSomeToken(
        address _token,
        address _recipient,
        uint256 _amount
    ) public virtual whenPaused onlyOwner {
        _withdrawToken(_token, _recipient, _amount);
        _afterWithdrawToken(_token, _recipient, _amount);
    }

    ///@notice withdraw all ETH. Withdraw in emergency mode only when contract paused
    function withdraw() external virtual whenPaused onlyOwner {
        _withdraw(_msgSender(), address(this).balance);
    }

    ///@notice withdraw some ETH. Withdraw in emergency mode only when contract paused
    function withdrawSome(address _recipient, uint256 _amount)
        external
        virtual
        onlyOwner
    {
        _withdraw(_recipient, _amount);
    }

    /// @notice pause contract
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice unpause contract
    function unpause() external onlyOwner {
        _unpause();
    }

    // whitelist
    function addToWhitelist(address[] memory _accounts) external onlyOwner {
        for (uint256 i = 0; i < _accounts.length; i++) {
            whitelistAddresses[_accounts[i]] = true;
        }
    }

    function removeFromWhitelist(address[] memory _accounts)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < _accounts.length; i++) {
            whitelistAddresses[_accounts[i]] = false;
        }
    }

    function updateSncAddress(address _sncAddress) external onlyOwner {
        sncAddress = _sncAddress;
        emit UpdateSncAddress(_sncAddress);
    }

    function updateTeamAddress(address _teamAddress) external onlyOwner {
        teamAddress = _teamAddress;
        emit UpdateTeamAddress(_teamAddress);
    }
}