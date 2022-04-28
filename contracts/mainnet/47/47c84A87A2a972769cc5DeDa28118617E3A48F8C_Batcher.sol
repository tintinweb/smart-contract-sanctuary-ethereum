/// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IBatcher.sol";
import "../../interfaces/IVault.sol";
import "../../interfaces/IWETH9.sol";
import "./EIP712.sol";

/// @title Batcher
/// @author 0xAd1, Bapireddy
/// @notice Used to batch user deposits and withdrawals until the next rebalance
contract Batcher is IBatcher, EIP712, ReentrancyGuard {
    using SafeERC20 for IERC20;

    /// @notice WETH token address on mainnet
    IWETH9 public immutable WETH;

    /// @notice Vault parameters for the batcher
    VaultInfo public vaultInfo;

    /// @notice Enforces signature checking on deposits
    bool public checkValidDepositSignature;

    /// @notice Creates a new Batcher strictly linked to a vault
    /// @param _verificationAuthority Address of the verification authority which allows users to deposit
    /// @param vaultAddress Address of the vault which will be used to deposit and withdraw want tokens
    /// @param maxAmount Maximum amount of tokens that can be deposited in the vault
    constructor(
        address _verificationAuthority,
        address vaultAddress,
        uint256 maxAmount
    ) {
        verificationAuthority = _verificationAuthority;
        checkValidDepositSignature = true;

        require(vaultAddress != address(0), "NULL_ADDRESS");
        vaultInfo = VaultInfo({
            vaultAddress: vaultAddress,
            tokenAddress: IVault(vaultAddress).wantToken(),
            maxAmount: maxAmount
        });

        WETH = IWETH9(vaultInfo.tokenAddress);

        IERC20(vaultInfo.tokenAddress).approve(vaultAddress, type(uint256).max);
    }

    /*///////////////////////////////////////////////////////////////
                       USER DEPOSIT/WITHDRAWAL LOGIC
  //////////////////////////////////////////////////////////////*/

    /// @notice Ledger to maintain addresses and their amounts to be deposited into vault
    mapping(address => uint256) public depositLedger;

    /// @notice Ledger to maintain addresses and their amounts to be withdrawn from vault
    mapping(address => uint256) public withdrawLedger;

    /// @notice Address which authorises users to deposit into Batcher
    address public verificationAuthority;

    /// @notice Amount of want tokens pending to be deposited
    uint256 public pendingDeposit;

    /// @notice Amount of LP tokens pending to be exchanged back to want token
    uint256 public pendingWithdrawal;

    /**
     * @notice Stores the deposits for future batching via periphery
     * @param amountIn Value of token to be deposited. It will be ignored if txn is sent with native ETH
     * @param signature signature verifying that recipient has enough karma and is authorized to deposit by brahma
     * @param recipient address receiving the shares issued by vault
     */
    function depositFunds(
        uint256 amountIn,
        bytes memory signature,
        address recipient
    ) external payable override nonReentrant {
        validDeposit(recipient, signature);

        uint256 wethBalanceBeforeTransfer = WETH.balanceOf(address(this));

        /// Checks wei sent with txn
        uint256 ethSent = msg.value;

        /// Convert wei if sent
        if (ethSent > 0) {
            amountIn = ethSent;
            WETH.deposit{value: ethSent}();
        }
        /// If no wei sent, use amountIn and transfer WETH from txn sender
        else {
            IERC20(vaultInfo.tokenAddress).safeTransferFrom(
                msg.sender,
                address(this),
                amountIn
            );
        }

        uint256 wethBalanceAfterTransfer = WETH.balanceOf(address(this));

        /// Check in both cases for WETH balance increase to be correct
        assert(
            wethBalanceAfterTransfer - wethBalanceBeforeTransfer == amountIn
        );

        require(
            IERC20(vaultInfo.vaultAddress).totalSupply() +
                pendingDeposit -
                pendingWithdrawal +
                amountIn <=
                vaultInfo.maxAmount,
            "MAX_LIMIT_EXCEEDED"
        );

        depositLedger[recipient] = depositLedger[recipient] + (amountIn);
        pendingDeposit = pendingDeposit + amountIn;

        emit DepositRequest(recipient, vaultInfo.vaultAddress, amountIn);
    }

    /**
     * @notice User deposits vault LP tokens to be withdrawn. Stores the deposits for future batching via periphery
     * @param amountIn Value of token to be deposited
     */
    function initiateWithdrawal(uint256 amountIn)
        external
        override
        nonReentrant
    {
        require(depositLedger[msg.sender] == 0, "DEPOSIT_PENDING");

        require(amountIn > 0, "AMOUNT_IN_ZERO");

        if (amountIn > userLPTokens[msg.sender]) {
            IERC20(vaultInfo.vaultAddress).safeTransferFrom(
                msg.sender,
                address(this),
                amountIn - userLPTokens[msg.sender]
            );
            userLPTokens[msg.sender] = 0;
        } else {
            userLPTokens[msg.sender] = userLPTokens[msg.sender] - amountIn;
        }

        withdrawLedger[msg.sender] = withdrawLedger[msg.sender] + (amountIn);

        pendingWithdrawal = pendingWithdrawal + amountIn;

        emit WithdrawRequest(msg.sender, vaultInfo.vaultAddress, amountIn);
    }

    /**
     * @notice Allows user to collect want token back after successfull batch withdrawal
     * @param amountOut Amount of token to be withdrawn
     */
    function completeWithdrawal(uint256 amountOut, address recipient)
        external
        override
        nonReentrant
    {
        require(amountOut != 0, "INVALID_AMOUNTOUT");

        // Will revert if not enough balance
        userWantTokens[recipient] = userWantTokens[recipient] - amountOut;
        IERC20(vaultInfo.tokenAddress).safeTransfer(recipient, amountOut);

        emit WithdrawComplete(recipient, vaultInfo.vaultAddress, amountOut);
    }

    /**
     * @notice Can be used to send LP tokens owed to the recipient
     * @param amount Amount of LP tokens to withdraw
     * @param recipient Address to receive the LP tokens
     */
    function claimTokens(uint256 amount, address recipient)
        public
        override
        nonReentrant
    {
        require(userLPTokens[recipient] >= amount, "NO_FUNDS");
        userLPTokens[recipient] = userLPTokens[recipient] - amount;
        IERC20(vaultInfo.vaultAddress).safeTransfer(recipient, amount);
    }

    /*///////////////////////////////////////////////////////////////
                    VAULT DEPOSIT/WITHDRAWAL LOGIC
  //////////////////////////////////////////////////////////////*/

    /// @notice Ledger to maintain addresses and vault LP tokens which batcher owes them
    mapping(address => uint256) public userLPTokens;

    /// @notice Ledger to maintain addresses and vault want tokens which batcher owes them
    mapping(address => uint256) public userWantTokens;

    /**
     * @notice Performs deposits on the periphery for the supplied users in batch
     * @param users array of users whose deposits must be resolved
     */
    function batchDeposit(address[] memory users)
        external
        override
        nonReentrant
    {
        onlyKeeper();
        IVault vault = IVault(vaultInfo.vaultAddress);

        uint256 amountToDeposit = 0;
        uint256 oldLPBalance = IERC20(address(vault)).balanceOf(address(this));

        // Temprorary array to hold user deposit info and check for duplicate addresses
        uint256[] memory depositValues = new uint256[](users.length);

        for (uint256 i = 0; i < users.length; i++) {
            // Copies deposit value from ledger to temporary array
            uint256 userDeposit = depositLedger[users[i]];
            amountToDeposit = amountToDeposit + userDeposit;
            depositValues[i] = userDeposit;

            // deposit ledger for that address is set to zero
            // Incase of duplicate address sent, new deposit amount used for same user will be 0
            depositLedger[users[i]] = 0;
        }

        require(amountToDeposit > 0, "NO_DEPOSITS");

        uint256 lpTokensReportedByVault = vault.deposit(
            amountToDeposit,
            address(this)
        );

        uint256 lpTokensReceived = IERC20(address(vault)).balanceOf(
            address(this)
        ) - (oldLPBalance);

        require(
            lpTokensReceived == lpTokensReportedByVault,
            "LP_TOKENS_MISMATCH"
        );

        uint256 totalUsersProcessed = 0;

        for (uint256 i = 0; i < users.length; i++) {
            uint256 userAmount = depositValues[i];

            // Checks if userAmount is not 0, only then proceed to allocate LP tokens
            if (userAmount > 0) {
                uint256 userShare = (userAmount * (lpTokensReceived)) /
                    (amountToDeposit);

                // Allocating LP tokens to user, can be calimed by the user later by calling claimTokens
                userLPTokens[users[i]] = userLPTokens[users[i]] + userShare;
                ++totalUsersProcessed;
            }
        }

        pendingDeposit = pendingDeposit - amountToDeposit;

        emit BatchDepositSuccessful(lpTokensReceived, totalUsersProcessed);
    }

    /**
     * @notice Performs withdraws on the periphery for the supplied users in batch
     * @param users array of users whose deposits must be resolved
     */
    function batchWithdraw(address[] memory users)
        external
        override
        nonReentrant
    {
        onlyKeeper();
        IVault vault = IVault(vaultInfo.vaultAddress);

        IERC20 token = IERC20(vaultInfo.tokenAddress);

        uint256 amountToWithdraw = 0;
        uint256 oldWantBalance = token.balanceOf(address(this));

        // Temprorary array to hold user withdrawal info and check for duplicate addresses
        uint256[] memory withdrawValues = new uint256[](users.length);

        for (uint256 i = 0; i < users.length; i++) {
            uint256 userWithdraw = withdrawLedger[users[i]];
            amountToWithdraw = amountToWithdraw + userWithdraw;
            withdrawValues[i] = userWithdraw;

            // Withdrawal ledger for that address is set to zero
            // Incase of duplicate address sent, new withdrawal amount used for same user will be 0
            withdrawLedger[users[i]] = 0;
        }

        require(amountToWithdraw > 0, "NO_WITHDRAWS");

        uint256 wantTokensReportedByVault = vault.withdraw(
            amountToWithdraw,
            address(this)
        );

        uint256 wantTokensReceived = token.balanceOf(address(this)) -
            (oldWantBalance);

        require(
            wantTokensReceived == wantTokensReportedByVault,
            "WANT_TOKENS_MISMATCH"
        );

        uint256 totalUsersProcessed = 0;

        for (uint256 i = 0; i < users.length; i++) {
            uint256 userAmount = withdrawValues[i];

            // Checks if userAmount is not 0, only then proceed to allocate want tokens
            if (userAmount > 0) {
                uint256 userShare = (userAmount * wantTokensReceived) /
                    amountToWithdraw;

                // Allocating want tokens to user. Can be claimed by the user by calling completeWithdrawal
                userWantTokens[users[i]] = userWantTokens[users[i]] + userShare;
                ++totalUsersProcessed;
            }
        }

        pendingWithdrawal = pendingWithdrawal - amountToWithdraw;

        emit BatchWithdrawSuccessful(wantTokensReceived, totalUsersProcessed);
    }

    /*///////////////////////////////////////////////////////////////
                    INTERNAL HELPERS
  //////////////////////////////////////////////////////////////*/

    /// @notice Helper to verify signature against verification authority
    /// @param signature Should be generated by verificationAuthority. Should contain msg.sender
    function validDeposit(address recipient, bytes memory signature)
        internal
        view
    {
        if (checkValidDepositSignature) {
            require(
                verifySignatureAgainstAuthority(
                    recipient,
                    signature,
                    verificationAuthority
                ),
                "INVALID_SIGNATURE"
            );
        }

        require(withdrawLedger[msg.sender] == 0, "WITHDRAW_PENDING");
    }

    /*///////////////////////////////////////////////////////////////
                    MAINTAINANCE ACTIONS
  //////////////////////////////////////////////////////////////*/

    /// @notice Function to set authority address
    /// @param authority New authority address
    function setAuthority(address authority) public {
        onlyGovernance();

        // Logging old and new verification authority
        emit VerificationAuthorityUpdated(verificationAuthority, authority);
        verificationAuthority = authority;
    }

    /// @inheritdoc IBatcher
    function setVaultLimit(uint256 maxAmount) external override {
        onlyGovernance();
        vaultInfo.maxAmount = maxAmount;
    }

    /// @notice Function to enable/disable deposit signature check
    function setDepositSignatureCheck(bool enabled) public {
        onlyGovernance();
        checkValidDepositSignature = enabled;
    }

    /// @notice Function to sweep funds out in case of emergency, can only be called by governance
    /// @param _token Address of token to sweep
    function sweep(address _token) public nonReentrant {
        onlyGovernance();
        IERC20(_token).transfer(
            msg.sender,
            IERC20(_token).balanceOf(address(this))
        );
    }

    /*///////////////////////////////////////////////////////////////
                    ACCESS MODIFERS
  //////////////////////////////////////////////////////////////*/

    /// @notice Helper to get Governance address from Vault contract
    /// @return Governance address
    function governance() public view returns (address) {
        return IVault(vaultInfo.vaultAddress).governance();
    }

    /// @notice Helper to get Keeper address from Vault contract
    /// @return Keeper address
    function keeper() public view returns (address) {
        return IVault(vaultInfo.vaultAddress).keeper();
    }

    /// @notice Helper to assert msg.sender as keeper address
    function onlyKeeper() internal view {
        require(msg.sender == keeper(), "ONLY_KEEPER");
    }

    /// @notice Helper to asset msg.sender as governance address
    function onlyGovernance() internal view {
        require(governance() == msg.sender, "ONLY_GOV");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/**
 * @title IBatcher
 * @notice A batcher to resolve vault deposits/withdrawals in batches
 * @dev Provides an interface for Batcher
 */
interface IBatcher {
    /// @notice Data structure to store vault info
    /// @param vaultAddress Address of the vault
    /// @param tokenAddress Address vault's want token
    /// @param maxAmount Max amount of tokens to deposit in vault
    /// @param currentAmount Current amount of wantTokens deposited in the vault
    struct VaultInfo {
        address vaultAddress;
        address tokenAddress;
        uint256 maxAmount;
    }

    /// @notice Deposit event
    /// @param sender Address of the depositor
    /// @param vault Address of the vault
    /// @param amountIn Tokens deposited
    event DepositRequest(
        address indexed sender,
        address indexed vault,
        uint256 amountIn
    );

    /// @notice Withdraw initiate event
    /// @param sender Address of the withdawer
    /// @param vault Address of the vault
    /// @param amountOut Tokens deposited
    event WithdrawRequest(
        address indexed sender,
        address indexed vault,
        uint256 amountOut
    );

    /// @notice Batch Deposit event
    /// @param amountIn Tokens deposited
    /// @param totalUsers Total number of users in the batch
    event BatchDepositSuccessful(uint256 amountIn, uint256 totalUsers);

    /// @notice Batch Withdraw event
    /// @param amountOut Tokens withdrawn
    /// @param totalUsers Total number of users in the batch
    event BatchWithdrawSuccessful(uint256 amountOut, uint256 totalUsers);

    /// @notice Withdraw complete event
    /// @param sender Address of the withdawer
    /// @param vault Address of the vault
    /// @param amountOut Tokens deposited
    event WithdrawComplete(
        address indexed sender,
        address indexed vault,
        uint256 amountOut
    );

    /// @notice Verification authority update event
    /// @param oldVerificationAuthority address of old verification authority
    /// @param newVerificationAuthority address of new verification authority
    event VerificationAuthorityUpdated(
        address indexed oldVerificationAuthority,
        address indexed newVerificationAuthority
    );

    function depositFunds(
        uint256 amountIn,
        bytes memory signature,
        address recipient
    ) external payable;

    function claimTokens(uint256 amount, address recipient) external;

    function initiateWithdrawal(uint256 amountIn) external;

    function completeWithdrawal(uint256 amountOut, address recipient) external;

    function batchDeposit(address[] memory users) external;

    function batchWithdraw(address[] memory users) external;

    function setVaultLimit(uint256 maxLimit) external;
}

/// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface IVault {
    function keeper() external view returns (address);

    function governance() external view returns (address);

    function wantToken() external view returns (address);

    function deposit(uint256 amountIn, address receiver)
        external
        returns (uint256 shares);

    function withdraw(uint256 sharesIn, address receiver)
        external
        returns (uint256 amountOut);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IWETH9 is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/// @title EIP712
/// @author 0xAd1
/// @notice Used to verify signatures
contract EIP712 {
    /// @notice Verifies a signature against alleged signer of the signature
    /// @param signature Signature to verify
    /// @param authority Signer of the signature
    /// @return True if the signature is signed by authority
    function verifySignatureAgainstAuthority(
        address recipient,
        bytes memory signature,
        address authority
    ) internal view returns (bool) {
        bytes32 eip712DomainHash = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes("Batcher")),
                keccak256(bytes("1")),
                1,
                address(this)
            )
        );

        bytes32 hashStruct = keccak256(
            abi.encode(keccak256("deposit(address owner)"), recipient)
        );

        bytes32 hash = keccak256(
            abi.encodePacked("\x19\x01", eip712DomainHash, hashStruct)
        );

        address signer = ECDSA.recover(hash, signature);
        require(signer == authority, "ECDSA: Invalid authority");
        require(signer != address(0), "ECDSA: invalid signature");
        return true;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

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
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
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