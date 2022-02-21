//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/ITokenVesting.sol";

contract TokenVesting is ITokenVesting, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    /**
     * @dev whitelists store all active whitelist members for all tokens.
     */
    mapping(uint256 => mapping(address => WhitelistInfo)) public whitelists;

    /**
     * @dev vestingInfos store all vesting informations.
     */
    mapping(uint256 => VestingInfo) public vestingInfos;

    /**
     * @dev vestingTokens store all active vesting tokens.
     */
    mapping(uint256 => address) public vestingTokens;

    /**
     * @dev token indexer
     */
    uint256 public tokenId;

    /**
     *
     * @dev setup vesting plans for investors
     *
     * @param _strategy indicate the distribution plan - seed, strategic and private
     * @param _cliff duration in seconds of the cliff in which tokens will begin to vest
     * @param _start vesting start date
     * @param _duration duration in seconds of the period in which the tokens will vest
     *
     */
    function setVestingInfo(
        uint256 _strategy,
        uint256 _cliff,
        uint256 _start,
        uint256 _duration,
        uint256 _interval
    ) external override onlyOwner {
        require(_strategy != 0, "Strategy should be correct");
        require(
            !vestingInfos[_strategy].active,
            "Vesting option already exist"
        );

        vestingInfos[_strategy].strategy = _strategy;
        vestingInfos[_strategy].cliff = _start + (_cliff * 1 days);
        vestingInfos[_strategy].start = _start;
        vestingInfos[_strategy].duration = _duration;
        vestingInfos[_strategy].interval = _interval;
        vestingInfos[_strategy].active = true;

        emit VestingInfoAdded(_strategy, _cliff, _start, _duration);
    }

    /**
     *
     * @dev remove existing vesting plan
     *
     * @param _strategy indicate the distribution plan - seed, strategic and private
     *
     */
    function deleteVestingInfo(uint256 _strategy) external override onlyOwner {
        require(_strategy != 0, "Strategy should be correct");
        require(vestingInfos[_strategy].active, "Vesting is not existed");

        delete vestingInfos[_strategy];

        emit VestingInfoDeleted(_strategy);
    }

    /**
     *
     * @dev update cliff of whitelisted user
     *
     * @param _tokenId vesting token index
     * @param _wallet whitelisted user address
     * @param _cliff updated cliff duration in day
     *
     */
    function updateUserCliff(
        uint256 _tokenId,
        address _wallet,
        uint256 _cliff
    ) external override onlyOwner {
        require(
            whitelists[_tokenId][_wallet].active,
            "User is not whitelisted"
        );

        whitelists[_tokenId][_wallet].cliff = _cliff;

        emit UserCliffUpdated(_tokenId, _wallet, _cliff);
    }

    /**
     *
     * @dev update tokenAmount of whitelisted user
     *
     * @param _tokenId vesting token index
     * @param _wallet whitelisted user address
     * @param _tokenAmount updated cliff duration in day
     *
     */
    function updateUserTokenAmount(
        uint256 _tokenId,
        address _wallet,
        uint256 _tokenAmount
    ) external override onlyOwner {
        require(
            whitelists[_tokenId][_wallet].active,
            "User is not whitelisted"
        );

        whitelists[_tokenId][_wallet].tokenAmount = _tokenAmount;

        emit UserTokenAmountUpdated(_tokenId, _wallet, _tokenAmount);
    }

    /**
     *
     * @dev set the address as whitelist user address
     *
     * @param _tokenId token index
     * @param _wallet wallet addresse array
     * @param _tokenAmount vesting token amount array
     * @param _option vesting info array
     *
     */
    function addWhitelists(
        uint256 _tokenId,
        address[] calldata _wallet,
        uint256[] calldata _tokenAmount,
        uint256[] calldata _option
    ) external override onlyOwner {
        require(_wallet.length == _tokenAmount.length, "Invalid array length");
        require(_option.length == _tokenAmount.length, "Invalid array length");

        for (uint256 i = 0; i < _wallet.length; i++) {
            require(
                whitelists[_tokenId][_wallet[i]].wallet != _wallet[i],
                "Whitelist already available"
            );
            require(
                vestingInfos[_option[i]].active,
                "Vesting option is not existing"
            );

            whitelists[_tokenId][_wallet[i]] = WhitelistInfo(
                _wallet[i],
                _tokenAmount[i],
                0,
                block.timestamp,
                vestingInfos[_option[i]].cliff,
                vestingInfos[_option[i]].start,
                vestingInfos[_option[i]].duration,
                vestingInfos[_option[i]].interval,
                vestingInfos[_option[i]].start +
                    vestingInfos[_option[i]].interval,
                _option[i],
                true
            );

            emit AddWhitelist(_tokenId, _wallet[i]);
        }
    }

    /**
     *
     * @dev delete whitelisted user wallets
     *
     * @param _tokenId token index
     * @param _wallet wallet addresse array
     *
     */
    function deleteWhitelists(uint256 _tokenId, address[] calldata _wallet)
        external
        override
        onlyOwner
    {
        for (uint256 i = 0; i < _wallet.length; i++) {
            delete whitelists[_tokenId][_wallet[i]];
            emit DeleteWhitelist(_tokenId, _wallet[i]);
        }
    }

    /**
     *
     * @dev add vesting token to contract
     *
     * @param _tokenId token index
     * @param _token address of IERC20 instance
     *
     */
    function addVestingToken(uint256 _tokenId, IERC20 _token)
        external
        override
        onlyOwner
    {
        vestingTokens[_tokenId] = address(_token);
        emit VestingTokenAdded(_tokenId, address(_token));
    }

    /**
     *
     * @dev distribute the token to the investors
     *
     * @param _tokenId vesting token index
     *
     * @return {bool} return status of distribution
     *
     */
    function claimDistribution(uint256 _tokenId)
        external
        override
        nonReentrant
        returns (bool)
    {
        require(
            whitelists[_tokenId][msg.sender].active,
            "User is not in whitelist"
        );
        require(
            block.timestamp <= whitelists[_tokenId][msg.sender].nextReleaseTime,
            "NextReleaseTime is not reached"
        );

        uint256 releaseAmount = calculateReleasableAmount(_tokenId, msg.sender);

        if (releaseAmount != 0) {
            IERC20(vestingTokens[_tokenId]).safeTransfer(
                msg.sender,
                releaseAmount
            );
            whitelists[_tokenId][msg.sender].distributedAmount =
                whitelists[_tokenId][msg.sender].distributedAmount +
                releaseAmount;
            whitelists[_tokenId][msg.sender].nextReleaseTime =
                block.timestamp +
                whitelists[_tokenId][msg.sender].step;
            return true;
        }

        return false;
    }

    /**
     *
     * @dev calculate releasable amount by subtracting distributed amount
     *
     * @param _tokenId vesting token index
     * @param _wallet investor wallet address
     *
     * @return {uint256} releasable amount of the whitelist
     *
     */
    function calculateReleasableAmount(uint256 _tokenId, address _wallet)
        public
        view
        returns (uint256)
    {
        return
            calculateVestAmount(_tokenId, _wallet) -
            whitelists[_tokenId][_wallet].distributedAmount;
    }

    /**
     *
     * @dev calculate the total vested amount by the time
     *
     * @param _tokenId vesting token index
     * @param _wallet user wallet address
     *
     * @return {uint256} return vested amount
     *
     */
    function calculateVestAmount(uint256 _tokenId, address _wallet)
        public
        view
        returns (uint256)
    {
        if (block.timestamp < whitelists[_tokenId][_wallet].cliff) {
            return 0;
        } else if (
            block.timestamp >=
            whitelists[_tokenId][_wallet].start +
                (whitelists[_tokenId][_wallet].duration * 1 days)
        ) {
            return whitelists[_tokenId][_wallet].tokenAmount;
        }

        return
            (whitelists[_tokenId][_wallet].tokenAmount *
                (block.timestamp - whitelists[_tokenId][_wallet].start)) /
            (whitelists[_tokenId][_wallet].duration * 1 days);
    }

    /**
     *
     * @dev Retrieve total amount of token from the contract
     *
     * @param {address} address of the token
     *
     * @return {uint256} total amount of token
     *
     */
    function getTotalToken(IERC20 _token) external view returns (uint256) {
        return _token.balanceOf(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface ITokenVesting {
    event VestingTokenAdded(uint256 tokenId, address token);
    event AddWhitelist(uint256 tokenId, address wallet);
    event DeleteWhitelist(uint256 tokenId, address wallet);
    event UserCliffUpdated(uint256 tokenId, address wallet, uint256 cliff);
    event UserTokenAmountUpdated(
        uint256 tokenId,
        address wallet,
        uint256 amount
    );
    event VestingInfoAdded(
        uint256 strategy,
        uint256 cliff,
        uint256 start,
        uint256 duration
    );
    event VestingInfoDeleted(uint256 strategy);

    struct VestingInfo {
        uint256 strategy;
        uint256 cliff;
        uint256 start;
        uint256 duration;
        uint256 interval;
        bool active;
    }

    struct WhitelistInfo {
        address wallet;
        uint256 tokenAmount;
        uint256 distributedAmount;
        uint256 joinDate;
        uint256 cliff;
        uint256 start;
        uint256 duration;
        uint256 step;
        uint256 nextReleaseTime;
        uint256 vestingOption;
        bool active;
    }

    function setVestingInfo(
        uint256 _strategy,
        uint256 _cliff,
        uint256 _start,
        uint256 _duration,
        uint256 _interval
    ) external;

    function deleteVestingInfo(uint256 _strategy) external;

    function addWhitelists(
        uint256 _tokenId,
        address[] calldata _wallet,
        uint256[] calldata _tokenAmount,
        uint256[] calldata _option
    ) external;

    function deleteWhitelists(uint256 _tokenId, address[] calldata _wallet)
        external;

    function addVestingToken(uint256 _tokenId, IERC20 _token) external;

    function updateUserCliff(
        uint256 _tokenId,
        address _wallet,
        uint256 _cliff
    ) external;

    function updateUserTokenAmount(
        uint256 _tokenId,
        address _wallet,
        uint256 _tokenAmount
    ) external;

    function claimDistribution(uint256 _tokenId) external returns (bool);
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

// SPDX-License-Identifier: MIT
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