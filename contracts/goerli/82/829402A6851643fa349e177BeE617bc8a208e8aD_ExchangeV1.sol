// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../libs/@openzeppelin/contracts/access/Ownable.sol";
import "../libs/@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../libs/@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../metatx/EIP2771Recipient.sol";

abstract contract IxBaseV1 is Ownable, ReentrancyGuard, EIP2771Recipient {
    using SafeERC20 for IERC20;

    event ContractClosed(address indexed owner);
    event Rescued(address indexed token, address indexed to, uint256 amount);

    constructor(address admin, address forwarder) EIP2771Recipient(forwarder) {
        _transferOwnership(admin);
    }

    /**
     * @dev set new trusted forwarder of EIP2771Recipient
     * nonEIP2771 modifier is needed because of direct access from administrator account
     * @param forwarder new address of trusted forwarder
     */
    function setTrustedForwarder(address forwarder) external virtual override nonEIP2771 onlyOwner {
        _setTrustedForwarder(forwarder);
    }

    /**
     * @dev in case of stucked erc20 token or ether, rescue them
     * nonEIP2771 modifier is needed because of direct access from administrator account
     */
    function rescue(address token, address to) external virtual nonReentrant nonEIP2771 onlyOwner {
        require(to != address(0), "to address can not be zero");

        uint256 amount;

        if (token == address(0)) {
            amount = address(this).balance;
        } else {
            amount = IERC20(token).balanceOf(address(this));
        }

        if (amount > 0) {
            if (token == address(0)) {
                // solhint-disable-next-line avoid-low-level-calls
                (bool success, ) = to.call{value: amount}("");
                require(success, "failed to transfer");
            } else {
                IERC20(token).safeTransfer(to, amount);
            }

            emit Rescued(token, to, amount);
        }
    }

    /**
     * @dev close this contract
     * expected to be used when this contract is no longer needed,
     * due to contract upgrade and re-deployment
     * nonEIP2771 modifier is needed because of direct access from administrator account
     */
    function finalize() external virtual nonEIP2771 onlyOwner {
        address payable owner = payable(owner());

        emit ContractClosed(owner);

        selfdestruct(owner);
    }

    /**
     * @dev override for EIP-2771
     * @return sender the address of sender, one of msg.sender or meta transaction signer
     */
    function _msgSender() internal view virtual override(Context, EIP2771Recipient) returns (address) {
        return EIP2771Recipient._msgSender();
    }

    /**
     * @dev override for EIP-2771
     * @return calldata the calldata of called function
     */
    function _msgData() internal view virtual override(Context, EIP2771Recipient) returns (bytes calldata) {
        return EIP2771Recipient._msgData();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./libs/@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./libs/@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./interfaces/IExchange.sol";
import "./interfaces/IWETH.sol";
import "./base/IxBaseV1.sol";
import "./FeeWorkerV1.sol";

contract ExchangeV1 is IExchange, IxBaseV1, FeeWorkerV1 {
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeERC20 for IERC20;
    using SafeERC20 for IERC20Permit;

    EnumerableSet.AddressSet private _allowedWithdrawers;

    modifier nonInternalCall() {
        // solhint-disable-next-line avoid-tx-origin
        require(tx.origin == msg.sender, "IxBaseV1: internal call not allowed");
        _;
    }

    constructor(address admin, address forwarder, address manager) IxBaseV1(admin, forwarder) {
        _setFeeManager(manager, admin);
    }

    /**
     * @notice setFeeManager set fee manager
     * @param manager addres of new feemanager
     */
    function setFeeManager(address manager) external override nonEIP2771 onlyOwner {
        // if manager is address(0) then fee recharge will be skipped
        _setFeeManager(manager, _msgSender());
    }

    /**
     * @notice registerWithdrawer register withdrawer to whitelist
     * @param withdrawer address of withdrawer to register
     */
    function registerWithdrawer(address withdrawer) external nonEIP2771 onlyOwner {
        require(withdrawer != address(0), "withdrawer can not be zero address");
        require(_allowedWithdrawers.add(withdrawer), "withdrawer already registered");

        emit WithdrawerRegistered(withdrawer, _msgSender());
    }

    /**
     * @notice unregisterWithdrawer unregister withdrawer from whitelist
     * @param withdrawer address of withdrawer to unregister
     */
    function unregisterWithdrawer(address withdrawer) external nonEIP2771 onlyOwner {
        require(_allowedWithdrawers.remove(withdrawer), "withdrawer is not registered");

        emit WithdrawerUnregistered(withdrawer, _msgSender());
    }

    /**
     * @notice getRegisteredWithdrawerCount get number of registered withdrawer
     */
    function getRegisteredWithdrawerCount() external view returns (uint256) {
        return _allowedWithdrawers.length();
    }

    /**
     * @notice getRegisteredWithdrawerAt returns registered withdrawer at index
     * @param index index of registered withdrawer
     */
    function getRegisteredWithdrawerAt(uint256 index) external view returns (address) {
        return _allowedWithdrawers.at(index);
    }

    /**
     * @notice getRegisteredWithdrawers returns all addresses of registerd withdrawer
     */
    function getRegisteredWithdrawers() external view returns (address[] memory) {
        return _allowedWithdrawers.values();
    }

    /**
     * @notice isRegisteredWithdrawer returns whether address is registered
     * @param withdrawer address to check
     */
    function isRegisteredWithdrawer(address withdrawer) public view returns (bool) {
        return _allowedWithdrawers.contains(withdrawer);
    }

    /**
     * @notice depositToken deposits token from user's wallet to service's token pool
     * the contract must be approved before the call
     * @param token token address to deposit
     * @param poolGame pool address to deposit token
     * @param amountGame amount of token to deposit
     * @param poolPlatform pool address to share deposit token
     * @param amountPlatform amount of token to share
     * @param memo memo
     */
    function depositToken(
        address token,
        address poolGame,
        uint256 amountGame,
        address poolPlatform,
        uint256 amountPlatform,
        string calldata memo
    ) external nonReentrant {
        require(token != address(0), "token address can not be zero");
        require(poolGame != address(0), "pool address can not be zero");
        require(amountGame > 0, "amount must be greater than zero");

        address user = _msgSender();

        IERC20(token).safeTransferFrom(user, poolGame, amountGame);
        if (amountPlatform > 0) {
            require(poolPlatform != address(0), "platform pool address can not be zero");
            IERC20(token).safeTransferFrom(user, poolPlatform, amountPlatform);
        }

        emit Deposited(token, user, poolGame, amountGame, poolPlatform, amountPlatform, memo);
    }

    /**
     * @notice depositTokenWithPermit deposits token from user's wallet to service's token pool
     * @param token token address to deposit
     * @param poolGame pool address to deposit token
     * @param amountGame amount of token to deposit
     * @param poolPlatform pool address to share deposit token
     * @param amountPlatform amount of token to share
     * @param memo memo
     * @param permission data for permit method
     */
    function depositTokenWithPermit(
        address token,
        address poolGame,
        uint256 amountGame,
        address poolPlatform,
        uint256 amountPlatform,
        string calldata memo,
        IxTypes.PermitData calldata permission
    ) external nonReentrant {
        require(token != address(0), "token address can not be zero");
        require(poolGame != address(0), "pool address can not be zero");
        require(amountGame > 0, "amount must be greater than zero");

        IERC20Permit(token).safePermit(
            permission.owner,
            permission.spender,
            permission.value,
            permission.deadline,
            permission.v,
            permission.r,
            permission.s
        );

        address user = _msgSender();

        IERC20(token).safeTransferFrom(user, poolGame, amountGame);
        if (amountPlatform > 0) {
            require(poolPlatform != address(0), "platform pool address can not be zero");
            IERC20(token).safeTransferFrom(user, poolPlatform, amountPlatform);
        }

        emit Deposited(token, user, poolGame, amountGame, poolPlatform, amountPlatform, memo);
    }

    /**
     * @notice withdrawToken withdraws tokens from service's token pool.
     * this function is supposed to be used by service platform,
     * can be called by specific addresses with registered withdrawer only.
     * @param token token address to withdraw
     * @param pool pool address to withdraw token
     * @param user address to withdraw token from pool
     * @param amount amount of token to withdraw
     * @param collector collector address to send fee
     * @param feeAmount amount of fee to send
     * @param memo memo
     */
    function withdrawToken(
        address token,
        address pool,
        address user,
        uint256 amount,
        address collector,
        uint256 feeAmount,
        string calldata memo
    ) external nonReentrant nonEIP2771 nonInternalCall {
        require(isRegisteredWithdrawer(_msgSender()), "only registered withdrawer can withdraw token");

        try this.innerWithdrawToken(token, pool, user, amount, collector, feeAmount) {
            // success
            _log(token, pool, user, amount, collector, feeAmount, memo, WithdrawStatus.OK, "");
        } catch (bytes memory reason) {
            // any other errors
            _log(token, pool, user, amount, collector, feeAmount, memo, WithdrawStatus.ERROR, reason);
        }

        _tryRechargeGasFee(msg.sender);
    }

    function _log(
        address token,
        address pool,
        address user,
        uint256 amount,
        address collector,
        uint256 feeAmount,
        string memory memo,
        WithdrawStatus status,
        bytes memory reason
    ) internal {
        emit Withdrawn(token, pool, user, amount, collector, feeAmount, memo, status, reason);
    }

    function innerWithdrawToken(
        address token,
        address pool,
        address user,
        uint256 amount,
        address collector,
        uint256 feeAmount
    ) external {
        // this external function can only be called by Exchange itself,
        // creating an internal transaction.
        require(msg.sender == address(this), "only can be called by Exchange itself");

        require(token != address(0), "token address can not be zero");
        // pool is EOA used by service platform, holding a lot of token amount
        // this contract must be approved by pool address
        require(pool != address(0), "pool address can not be zero");
        require(user != address(0), "user address can not be zero");
        require(amount > 0, "amount must be greater than zero");

        IERC20(token).safeTransferFrom(pool, user, amount);
        if (feeAmount > 0) {
            require(collector != address(0), "fee collector address can not be zero");
            IERC20(token).safeTransferFrom(pool, collector, feeAmount);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./interfaces/IFeeManager.sol";

abstract contract FeeWorkerV1 {
    address public feeManager;

    event FeeManagerChanged(address oldManager, address newManager, address changer);

    /**
     * @notice _setFeeManager set feemanager
     * @param manager addres of new feemanager
     * @param changer address changing feemanger
     */
    function _setFeeManager(address manager, address changer) internal virtual {
        emit FeeManagerChanged(feeManager, manager, changer);
        feeManager = manager;
    }

    function setFeeManager(address manager) external virtual;

    function _tryRechargeGasFee(address target) internal virtual {
        if (feeManager == address(0)) {
            return;
        }

        if (feeManager.code.length <= 0) {
            revert("trying to call non contract address as fee manager");
        }

        try IFeeManager(feeManager).rechargeGasFee(target) {
            // solhint-disable-previous-line no-empty-blocks
            // do nothing
        } catch (bytes memory reason) {
            // failed due to configuration (address, gas fee, etd)
            if (reason.length > 0) {
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            } else {
                revert("revert with no reason");
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./IxTypes.sol";

interface IExchange {
    event WithdrawerRegistered(address indexed withdrawer, address indexed owner);
    event WithdrawerUnregistered(address indexed withdrawer, address indexed owner);

    event Deposited(
        address indexed token,
        address indexed user,
        address indexed poolGame,
        uint256 amountGame,
        address poolPlatform,
        uint256 amountPlatform,
        string memo
    );
    event Withdrawn(
        address indexed token,
        address indexed pool,
        address indexed user,
        uint256 amount,
        address collector,
        uint256 fee,
        string memo,
        WithdrawStatus status,
        bytes reason
    );

    /**
     * OK for success
     * ERR for require or revert
     * LOW_ERR for other low level errors like Panic (assert), OOG, etc.
     */
    enum WithdrawStatus {
        OK,
        ERROR
    }

    /**
     * a user deposits token from user's wallet to service's token pool
     * the contract must be approved before the call
     */
    function depositToken(
        address token,
        address poolGame,
        uint256 amountGame,
        address poolPlatform,
        uint256 amountPlatform,
        string calldata memo
    ) external;

    /**
     * a user deposits token from user's wallet to service's token pool
     */
    function depositTokenWithPermit(
        address token,
        address poolGame,
        uint256 amountGame,
        address poolPlatform,
        uint256 amountPlatform,
        string calldata memo,
        IxTypes.PermitData calldata permission
    ) external;

    /**
     * a user withdraws tokens from service's token pool.
     * this function is supposed to be used by service platform,
     * can be called by specific addresses with WITHDRAWER_ROLE only.
     */
    function withdrawToken(
        address token,
        address pool,
        address user,
        uint256 amount,
        address collector,
        uint256 feeAmount,
        string calldata memo
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IFeeManager {
    event ConfigChanged(
        address weth,
        address nweWeth,
        address payer,
        address newPayer,
        uint256 threshold,
        uint256 newThreshold,
        uint256 amount,
        uint256 newAmount,
        address owner
    );
    event RechargerRegistered(address indexed recharger, address owner);
    event RechargerUnregistered(address indexed recharger, address owner);

    event GasFeeRecharged(address indexed target, uint256 amount, RechargeStatus indexed status, bytes reason);

    /**
     * OK for success
     * ERR for require or revert
     * LOW_ERR for other low level errors like Panic (assert), OOG, etc.
     */
    enum RechargeStatus {
        OK,
        ERROR
    }

    /**
     * give ETH target address to refill gas fee
     */
    function rechargeGasFee(address target) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IxTypes {
    struct PermitData {
        address owner;
        address spender;
        uint256 value;
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @dev recipient contract for "EIP-2771: Secure Protocol for Native Meta Transactions"
 */
abstract contract EIP2771Recipient {
    address private _trustedForwarder;

    event TrustedForwarderChanged(address previousForwarder, address newForwarder, address changer);

    /**
     * @dev revert if called by trusted forwarder. this means meta transaction is not allowed
     */
    modifier nonEIP2771() {
        require(!isTrustedForwarder(msg.sender), "EIP2771Recipient: meta transaction is not allowed");
        _;
    }

    constructor(address forwarder) {
        _setTrustedForwarder(forwarder);
    }

    /**
     * @dev get trusted forwarder address
     * @return forwarder the address of trusted forwarder
     */
    function getTrustedForwarder() external view returns (address forwarder) {
        return _trustedForwarder;
    }

    /**
     * @dev check whether the address is trusted forwarder or not
     * @return true if the address to check is trusted forwarder
     */
    function isTrustedForwarder(address forwarder) public view returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function setTrustedForwarder(address forwarder) external virtual;

    /**
     * @dev changes trusted forwarder address and emits the event
     */
    function _setTrustedForwarder(address forwarder) internal {
        emit TrustedForwarderChanged(_trustedForwarder, forwarder, _msgSender());
        _trustedForwarder = forwarder;
    }

    function _msgSender() internal view virtual returns (address ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                ret := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            ret = msg.sender;
        }
    }

    function _msgData() internal view virtual returns (bytes calldata ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            return msg.data[0:msg.data.length - 20];
        } else {
            return msg.data;
        }
    }
}