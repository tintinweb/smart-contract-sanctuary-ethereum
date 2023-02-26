// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IDIVADevelopmentFund} from "./interfaces/IDIVADevelopmentFund.sol";
import {IDIVAOwnershipShared} from "./interfaces/IDIVAOwnershipShared.sol";

contract DIVADevelopmentFund is IDIVADevelopmentFund, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // DIVA ownership contract
    IDIVAOwnershipShared private immutable _divaOwnership;

    // Deposit related storage variables
    Deposit[] private _deposits;
    mapping(address => uint256[]) private _tokenToDepositIndices;

    // Mapping introduced to allow differentiating between deposits that came in via
    // the implemented `deposit` functions and direct deposits, made by sending native
    // assets or ERC20 tokens directly to the contract address. The difference between
    // the contract balance and `_tokenToUnclaimedDepositAmount` represents the amount
    // of direct deposits that can be withdrawn via `withdrawDirectDeposit` without
    // vesting.
    mapping(address => uint256) private _tokenToUnclaimedDepositAmount;

    modifier onlyDIVAOwner() {
        address _currentOwner = _divaOwnership.getCurrentOwner();
        if (_currentOwner != msg.sender) {
            revert NotDIVAOwner(msg.sender, _currentOwner);
        }
        _;
    }

    constructor(IDIVAOwnershipShared divaOwnership_) payable {
        _divaOwnership = divaOwnership_;
    }

    // Function to receive native asset. msg.data must be empty, otherwise it will fail.
    receive() external payable {}

    function deposit(uint256 _releasePeriodInSeconds)
        external
        payable
        override
        nonReentrant
    {
        uint256 _depositIndex = _addNewDeposit(
            address(0),
            msg.value,
            _releasePeriodInSeconds
        );

        emit Deposited(msg.sender, _depositIndex);
    }

    function deposit(
        address _token,
        uint256 _amount,
        uint256 _releasePeriodInSeconds
    ) external override nonReentrant {
        uint256 _depositIndex = _addNewDeposit(
            _token,
            _amount,
            _releasePeriodInSeconds
        );

        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);

        emit Deposited(msg.sender, _depositIndex);
    }

    function withdraw(address _token, uint256[] calldata _indices)
        external
        payable
        override
        nonReentrant
        onlyDIVAOwner
    {
        uint256 _claimableAmount;
        uint256 _len = _indices.length;
        for (uint256 _i = 0; _i < _len; ) {
            Deposit storage _deposit = _deposits[_indices[_i]];
            if (_deposit.token != _token) {
                revert DifferentTokens();
            }
            if (_deposit.lastClaimedAt < _deposit.endTime) {
                _claimableAmount += _claimableAmountForDeposit(_deposit);
                _deposit.lastClaimedAt = block.timestamp;
            }

            unchecked {
                ++_i;
            }
        }

        _tokenToUnclaimedDepositAmount[_token] -= _claimableAmount;

        if (_token == address(0)) {
            (bool success, ) = msg.sender.call{value: _claimableAmount}("");
            require(success, "Failed to send native asset");
        } else {
            IERC20(_token).safeTransfer(msg.sender, _claimableAmount);
        }

        emit Withdrawn(msg.sender, _token, _claimableAmount);
    }

    function withdrawDirectDeposit(address _token)
        external
        payable
        override
        nonReentrant
        onlyDIVAOwner
    {
        uint256 _claimableAmount;
        if (_token == address(0)) {
            _claimableAmount =
                address(this).balance -
                _tokenToUnclaimedDepositAmount[_token];
            (bool success, ) = msg.sender.call{value: _claimableAmount}("");
            require(success, "Failed to send native asset");
        } else {
            IERC20 _depositTokenInstance = IERC20(_token);
            _claimableAmount =
                _depositTokenInstance.balanceOf(address(this)) -
                _tokenToUnclaimedDepositAmount[_token];
            IERC20(_token).safeTransfer(msg.sender, _claimableAmount);
        }

        emit Withdrawn(msg.sender, _token, _claimableAmount);
    }

    function getDepositsLength()
        external
        view
        override
        returns (uint256 length)
    {
        length = _deposits.length;
    }

    function getDivaOwnership()
        external
        view
        override
        returns (IDIVAOwnershipShared divaOwnership)
    {
        divaOwnership = _divaOwnership;
    }

    function getDepositInfo(uint256 _index)
        external
        view
        override
        returns (Deposit memory depositInfo)
    {
        depositInfo = _deposits[_index];
    }

    function getDepositIndices(
        address _token,
        uint256 _startIndex,
        uint256 _endIndex
    ) external view override returns (uint256[] memory indices) {
        if (_endIndex > _startIndex) {
            uint256 _len = _tokenToDepositIndices[_token].length;
            indices = new uint256[](_endIndex - _startIndex);
            for (uint256 i = _startIndex; i < _endIndex; ) {
                if (i >= _len) {
                    indices[i - _startIndex] = 0;
                } else {
                    indices[i - _startIndex] = _tokenToDepositIndices[_token][
                        i
                    ];
                }

                unchecked {
                    ++i;
                }
            }
        } else {
            indices = new uint256[](0);
        }
    }

    function getDepositIndicesLengthForToken(address _token)
        external
        view
        override
        returns (uint256 depositIndicesLength)
    {
        depositIndicesLength = _tokenToDepositIndices[_token].length;
    }

    function getUnclaimedDepositAmount(address _token)
        external
        view
        override
        returns (uint256 amount)
    {
        amount = _tokenToUnclaimedDepositAmount[_token];
    }

    function _addNewDeposit(
        address _token,
        uint256 _amount,
        uint256 _releasePeriodInSeconds
    ) internal returns (uint256 depositIndex) {
        _deposits.push(
            Deposit(
                _token,
                _amount,
                block.timestamp,
                block.timestamp + _releasePeriodInSeconds,
                block.timestamp
            )
        );
        depositIndex = _deposits.length - 1;
        _tokenToDepositIndices[_token].push(depositIndex);

        _tokenToUnclaimedDepositAmount[_token] += _amount;
    }

    function _claimableAmountForDeposit(Deposit memory _deposit)
        internal
        view
        returns (uint256 amount)
    {
        if (block.timestamp >= _deposit.endTime) {
            amount =
                _deposit.amount -
                (_deposit.amount *
                    (_deposit.lastClaimedAt - _deposit.startTime)) /
                (_deposit.endTime - _deposit.startTime);
        } else {
            amount =
                (_deposit.amount * (block.timestamp - _deposit.lastClaimedAt)) /
                (_deposit.endTime - _deposit.startTime);
        }
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.19;

import {IDIVAOwnershipShared} from "./IDIVAOwnershipShared.sol";

interface IDIVADevelopmentFund {
    // Thrown in `withdraw` if `msg.sender` is not the owner of DIVA protocol
    error NotDIVAOwner(address _user, address _divaOwner);

    // Thrown in `withdraw` if token addresses for indices passed are
    // different
    error DifferentTokens();

    // Struct for deposits
    struct Deposit {
        address token; // Address of deposited token (zero address for native asset)
        uint256 amount; // Deposit amount
        uint256 startTime; // Timestamp in seconds since epoch when user can start claiming the deposit
        uint256 endTime; // Timestamp in seconds since epoch when release period ends at
        uint256 lastClaimedAt; // Timestamp in seconds since epoch when user last claimed deposit at
    }

    /**
     * @notice Emitted when a user deposits a token or a native asset via
     * one of the two `deposit` functions.
     * @param sender Address of user who deposits token (`msg.sender`).
     * @param depositIndex Index of deposit in deposits array variable.
     */
    event Deposited(address indexed sender, uint256 indexed depositIndex);

    /**
     * @notice Emitted when a user withdraws a token via `withdraw`
     * or `withdrawDirectDeposit`.
     * @param withdrawnBy Address of user who withdraws token (same as
     * current DIVA owner).
     * @param token Address of withdrawn token.
     * @param amount Token amount withdrawn.
     */
    event Withdrawn(
        address indexed withdrawnBy,
        address indexed token,
        uint256 amount
    );

    /**
     * @notice Function to deposit the native asset, such as ETH on
     * Ethereum.
     * @dev Creates a new entry in the `Deposit` struct array with the
     * `token` parameter set to `address(0)` and the `amount` parameter to
     * `msg.value`. Emits a `Deposited` event on success.
     * @param _releasePeriodInSeconds Release period of deposit in seconds.
     */
    function deposit(uint256 _releasePeriodInSeconds) external payable;

    /**
     * @notice Function to deposit ERC20 token.
     * @dev Creates a new entry in the `Deposit` struct array with the
     * `token` and `amount` parameters set equal to the ones provided by the user.
     * Emits a `Deposited` event on success.
     * @param _token Address of token to deposit.
     * @param _amount ERC20 token amount to deposit.
     * @param _releasePeriodInSeconds Release period of deposit in seconds.
     */
    function deposit(
        address _token,
        uint256 _amount,
        uint256 _releasePeriodInSeconds
    ) external;

    /**
     * @notice Function to withdraw a deposited `_token`.
     * @dev Use the zero address for the native asset (e.g., ETH on Ethereum).
     * @param _token Address of token to withdraw.
     * @param _indices Array of deposit indices to withdraw (indices can be
     * obtained via `getDepositIndices`).
     */
    function withdraw(address _token, uint256[] calldata _indices)
        external
        payable;

    /**
     * @notice Function to withdraw a given `_token` that has been sent
     * to the contract directly without calling the deposit function.
     * @dev Use the zero address for the native asset (e.g., ETH on Ethereum).
     * @param _token Address of token to withdraw.
     */
    function withdrawDirectDeposit(address _token) external payable;

    /**
     * @notice Function to return the number of deposits.
     */
    function getDepositsLength() external view returns (uint256);

    /**
     * @notice Function to return the DIVAOwnership contract address on
     * the corresponding chain.
     */
    function getDivaOwnership() external view returns (IDIVAOwnershipShared);

    /**
     * @notice Function to get the deposit info for a given `_index`.
     * @param _index Deposit index.
     */
    function getDepositInfo(uint256 _index)
        external
        view
        returns (Deposit memory);

    /**
     * @notice Function to get the deposit indices for a given `_token`.
     * @dev Use the zero address for the native asset (e.g., ETH on Ethereum).
     * `_startIndex` and `_endIndex` allow the caller to control the array
     * range to return to avoid exceeding the gas limit. Returns an empty
     * array if `_endIndex <= _startIndex`.
     * @param _token Token address.
     * @param _startIndex Start index of deposit indices list to get.
     * @param _endIndex End index of deposit indices list to get.
     */
    function getDepositIndices(
        address _token,
        uint256 _startIndex,
        uint256 _endIndex
    ) external view returns (uint256[] memory);

    /**
     * @notice Function to get the length of deposit indices for a given `_token`.
     * @dev Use the zero address for the native asset (e.g., ETH on Ethereum).
     * @param _token Token address.
     */
    function getDepositIndicesLengthForToken(address _token)
        external
        view
        returns (uint256);

    /**
     * @notice Function to get the unclaimed deposit amount for a given `_token`.
     * @dev Use the zero address for the native asset (e.g., ETH on Ethereum).
     * @param _token Token address.
     */
    function getUnclaimedDepositAmount(address _token)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.19;

interface IDIVAOwnershipShared {
    /**
     * @notice Function to return the current DIVA Protocol owner address.
     * @return Current owner address. On main chain, equal to the existing owner
     * during an on-going election cycle and equal to the new owner afterwards. On secondary
     * chain, equal to the address reported via Tellor oracle.
     */
    function getCurrentOwner() external view returns (address);
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
}