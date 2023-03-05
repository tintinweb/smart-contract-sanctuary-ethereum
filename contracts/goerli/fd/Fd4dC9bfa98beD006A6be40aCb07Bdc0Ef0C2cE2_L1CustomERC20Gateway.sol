// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { SafeERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import { IL2ERC20Gateway } from "../../L2/gateways/IL2ERC20Gateway.sol";
import { IL1ScrollMessenger } from "../IL1ScrollMessenger.sol";
import { IL1ERC20Gateway } from "./IL1ERC20Gateway.sol";

import { ScrollGatewayBase } from "../../libraries/gateway/ScrollGatewayBase.sol";
import { L1ERC20Gateway } from "./L1ERC20Gateway.sol";

/// @title L1CustomERC20Gateway
/// @notice The `L1CustomERC20Gateway` is used to deposit custom ERC20 compatible tokens in layer 1 and
/// finalize withdraw the tokens from layer 2.
/// @dev The deposited tokens are held in this gateway. On finalizing withdraw, the corresponding
/// tokens will be transfer to the recipient directly.
contract L1CustomERC20Gateway is OwnableUpgradeable, ScrollGatewayBase, L1ERC20Gateway {
  using SafeERC20Upgradeable for IERC20Upgradeable;

  /**********
   * Events *
   **********/

  /// @notice Emitted when token mapping for ERC20 token is updated.
  /// @param _l1Token The address of ERC20 token in layer 1.
  /// @param _l2Token The address of corresponding ERC20 token in layer 2.
  event UpdateTokenMapping(address _l1Token, address _l2Token);

  /*************
   * Variables *
   *************/

  /// @notice Mapping from l1 token address to l2 token address for ERC20 token.
  mapping(address => address) public tokenMapping;

  /***************
   * Constructor *
   ***************/

  /// @notice Initialize the storage of L1CustomERC20Gateway.
  /// @param _counterpart The address of L2CustomERC20Gateway in L2.
  /// @param _router The address of L1GatewayRouter.
  /// @param _messenger The address of L1ScrollMessenger.
  function initialize(
    address _counterpart,
    address _router,
    address _messenger
  ) external initializer {
    require(_router != address(0), "zero router address");

    OwnableUpgradeable.__Ownable_init();
    ScrollGatewayBase._initialize(_counterpart, _router, _messenger);
  }

  /*************************
   * Public View Functions *
   *************************/

  /// @inheritdoc IL1ERC20Gateway
  function getL2ERC20Address(address _l1Token) public view override returns (address) {
    return tokenMapping[_l1Token];
  }

  /****************************
   * Public Mutated Functions *
   ****************************/

  /// @inheritdoc IL1ERC20Gateway
  function finalizeWithdrawERC20(
    address _l1Token,
    address _l2Token,
    address _from,
    address _to,
    uint256 _amount,
    bytes calldata _data
  ) external payable override onlyCallByCounterpart {
    require(msg.value == 0, "nonzero msg.value");
    require(_l2Token == tokenMapping[_l1Token], "l2 token mismatch");

    // @note can possible trigger reentrant call to this contract or messenger,
    // but it seems not a big problem.
    IERC20Upgradeable(_l1Token).safeTransfer(_to, _amount);

    // @todo forward `_data` to `_to` in the near future

    emit FinalizeWithdrawERC20(_l1Token, _l2Token, _from, _to, _amount, _data);
  }

  /************************
   * Restricted Functions *
   ************************/

  /// @notice Update layer 1 to layer 2 token mapping.
  /// @param _l1Token The address of ERC20 token in layer 1.
  /// @param _l2Token The address of corresponding ERC20 token in layer 2.
  function updateTokenMapping(address _l1Token, address _l2Token) external onlyOwner {
    require(_l2Token != address(0), "map to zero address");

    tokenMapping[_l1Token] = _l2Token;

    emit UpdateTokenMapping(_l1Token, _l2Token);
  }

  /**********************
   * Internal Functions *
   **********************/

  /// @inheritdoc L1ERC20Gateway
  function _deposit(
    address _token,
    address _to,
    uint256 _amount,
    bytes memory _data,
    uint256 _gasLimit
  ) internal virtual override nonReentrant {
    address _l2Token = tokenMapping[_token];
    require(_l2Token != address(0), "no corresponding l2 token");

    // 1. Extract real sender if this call is from L1GatewayRouter.
    address _from = msg.sender;
    if (router == msg.sender) {
      (_from, _data) = abi.decode(_data, (address, bytes));
    }

    // 2. Transfer token into this contract.
    {
      // common practice to handle fee on transfer token.
      uint256 _before = IERC20Upgradeable(_token).balanceOf(address(this));
      IERC20Upgradeable(_token).safeTransferFrom(_from, address(this), _amount);
      uint256 _after = IERC20Upgradeable(_token).balanceOf(address(this));
      // no unchecked here, since some weird token may return arbitrary balance.
      _amount = _after - _before;
      // ignore weird fee on transfer token
      require(_amount > 0, "deposit zero amount");
    }

    // 3. Generate message passed to L2StandardERC20Gateway.
    bytes memory _message = abi.encodeWithSelector(
      IL2ERC20Gateway.finalizeDepositERC20.selector,
      _token,
      _l2Token,
      _from,
      _to,
      _amount,
      _data
    );

    // 4. Send message to L1ScrollMessenger.
    IL1ScrollMessenger(messenger).sendMessage{ value: msg.value }(counterpart, 0, _message, _gasLimit);

    emit DepositERC20(_token, _l2Token, _from, _to, _amount, _data);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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

pragma solidity ^0.8.0;

interface IL2ERC20Gateway {
  /**********
   * Events *
   **********/

  /// @notice Emitted when ERC20 token is deposited from L1 to L2 and transfer to recipient.
  /// @param l1Token The address of the token in L1.
  /// @param l2Token The address of the token in L2.
  /// @param from The address of sender in L1.
  /// @param to The address of recipient in L2.
  /// @param amount The amount of token withdrawn from L1 to L2.
  /// @param data The optional calldata passed to recipient in L2.
  event FinalizeDepositERC20(
    address indexed l1Token,
    address indexed l2Token,
    address indexed from,
    address to,
    uint256 amount,
    bytes data
  );

  /// @notice Emitted when someone withdraw ERC20 token from L2 to L1.
  /// @param l1Token The address of the token in L1.
  /// @param l2Token The address of the token in L2.
  /// @param from The address of sender in L2.
  /// @param to The address of recipient in L1.
  /// @param amount The amount of token will be deposited from L2 to L1.
  /// @param data The optional calldata passed to recipient in L1.
  event WithdrawERC20(
    address indexed l1Token,
    address indexed l2Token,
    address indexed from,
    address to,
    uint256 amount,
    bytes data
  );

  /*************************
   * Public View Functions *
   *************************/

  /// @notice Return the corresponding l1 token address given l2 token address.
  /// @param l2Token The address of l2 token.
  function getL1ERC20Address(address l2Token) external view returns (address);

  /// @notice Return the corresponding l2 token address given l1 token address.
  /// @param l1Token The address of l1 token.
  function getL2ERC20Address(address l1Token) external view returns (address);

  /****************************
   * Public Mutated Functions *
   ****************************/

  /// @notice Withdraw of some token to a caller's account on L1.
  /// @dev Make this function payable to send relayer fee in Ether.
  /// @param token The address of token in L2.
  /// @param amount The amount of token to transfer.
  /// @param gasLimit Unused, but included for potential forward compatibility considerations.
  function withdrawERC20(
    address token,
    uint256 amount,
    uint256 gasLimit
  ) external payable;

  /// @notice Withdraw of some token to a recipient's account on L1.
  /// @dev Make this function payable to send relayer fee in Ether.
  /// @param token The address of token in L2.
  /// @param to The address of recipient's account on L1.
  /// @param amount The amount of token to transfer.
  /// @param gasLimit Unused, but included for potential forward compatibility considerations.
  function withdrawERC20(
    address token,
    address to,
    uint256 amount,
    uint256 gasLimit
  ) external payable;

  /// @notice Withdraw of some token to a recipient's account on L1 and call.
  /// @dev Make this function payable to send relayer fee in Ether.
  /// @param token The address of token in L2.
  /// @param to The address of recipient's account on L1.
  /// @param amount The amount of token to transfer.
  /// @param data Optional data to forward to recipient's account.
  /// @param gasLimit Unused, but included for potential forward compatibility considerations.
  function withdrawERC20AndCall(
    address token,
    address to,
    uint256 amount,
    bytes calldata data,
    uint256 gasLimit
  ) external payable;

  /// @notice Complete a deposit from L1 to L2 and send fund to recipient's account in L2.
  /// @dev Make this function payable to handle WETH deposit/withdraw.
  ///      The function should only be called by L2ScrollMessenger.
  ///      The function should also only be called by L1ERC20Gateway in L1.
  /// @param l1Token The address of corresponding L1 token.
  /// @param l2Token The address of corresponding L2 token.
  /// @param from The address of account who deposits the token in L1.
  /// @param to The address of recipient in L2 to receive the token.
  /// @param amount The amount of the token to deposit.
  /// @param data Optional data to forward to recipient's account.
  function finalizeDepositERC20(
    address l1Token,
    address l2Token,
    address from,
    address to,
    uint256 amount,
    bytes calldata data
  ) external payable;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IScrollMessenger } from "../libraries/IScrollMessenger.sol";

interface IL1ScrollMessenger is IScrollMessenger {
  /***********
   * Structs *
   ***********/

  struct L2MessageProof {
    // The hash of the batch where the message belongs to.
    bytes32 batchHash;
    // Concatenation of merkle proof for withdraw merkle trie.
    bytes merkleProof;
  }

  /****************************
   * Public Mutated Functions *
   ****************************/

  /// @notice Relay a L2 => L1 message with message proof.
  /// @param from The address of the sender of the message.
  /// @param to The address of the recipient of the message.
  /// @param value The msg.value passed to the message call.
  /// @param nonce The nonce of the message to avoid replay attack.
  /// @param message The content of the message.
  /// @param proof The proof used to verify the correctness of the transaction.
  function relayMessageWithProof(
    address from,
    address to,
    uint256 value,
    uint256 nonce,
    bytes memory message,
    L2MessageProof memory proof
  ) external;

  /// @notice Replay an exsisting message.
  /// @param from The address of the sender of the message.
  /// @param to The address of the recipient of the message.
  /// @param value The msg.value passed to the message call.
  /// @param queueIndex The queue index for the message to replay.
  /// @param message The content of the message.
  /// @param oldGasLimit Original gas limit used to send the message.
  /// @param newGasLimit New gas limit to be used for this message.
  function replayMessage(
    address from,
    address to,
    uint256 value,
    uint256 queueIndex,
    bytes memory message,
    uint32 oldGasLimit,
    uint32 newGasLimit
  ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IL1ERC20Gateway {
  /**********
   * Events *
   **********/

  /// @notice Emitted when ERC20 token is withdrawn from L2 to L1 and transfer to recipient.
  /// @param l1Token The address of the token in L1.
  /// @param l2Token The address of the token in L2.
  /// @param from The address of sender in L2.
  /// @param to The address of recipient in L1.
  /// @param amount The amount of token withdrawn from L2 to L1.
  /// @param data The optional calldata passed to recipient in L1.
  event FinalizeWithdrawERC20(
    address indexed l1Token,
    address indexed l2Token,
    address indexed from,
    address to,
    uint256 amount,
    bytes data
  );

  /// @notice Emitted when someone deposit ERC20 token from L1 to L2.
  /// @param l1Token The address of the token in L1.
  /// @param l2Token The address of the token in L2.
  /// @param from The address of sender in L1.
  /// @param to The address of recipient in L2.
  /// @param amount The amount of token will be deposited from L1 to L2.
  /// @param data The optional calldata passed to recipient in L2.
  event DepositERC20(
    address indexed l1Token,
    address indexed l2Token,
    address indexed from,
    address to,
    uint256 amount,
    bytes data
  );

  /*************************
   * Public View Functions *
   *************************/

  /// @notice Return the corresponding l2 token address given l1 token address.
  /// @param _l1Token The address of l1 token.
  function getL2ERC20Address(address _l1Token) external view returns (address);

  /****************************
   * Public Mutated Functions *
   ****************************/

  /// @notice Deposit some token to a caller's account on L2.
  /// @dev Make this function payable to send relayer fee in Ether.
  /// @param _token The address of token in L1.
  /// @param _amount The amount of token to transfer.
  /// @param _gasLimit Gas limit required to complete the deposit on L2.
  function depositERC20(
    address _token,
    uint256 _amount,
    uint256 _gasLimit
  ) external payable;

  /// @notice Deposit some token to a recipient's account on L2.
  /// @dev Make this function payable to send relayer fee in Ether.
  /// @param _token The address of token in L1.
  /// @param _to The address of recipient's account on L2.
  /// @param _amount The amount of token to transfer.
  /// @param _gasLimit Gas limit required to complete the deposit on L2.
  function depositERC20(
    address _token,
    address _to,
    uint256 _amount,
    uint256 _gasLimit
  ) external payable;

  /// @notice Deposit some token to a recipient's account on L2 and call.
  /// @dev Make this function payable to send relayer fee in Ether.
  /// @param _token The address of token in L1.
  /// @param _to The address of recipient's account on L2.
  /// @param _amount The amount of token to transfer.
  /// @param _data Optional data to forward to recipient's account.
  /// @param _gasLimit Gas limit required to complete the deposit on L2.
  function depositERC20AndCall(
    address _token,
    address _to,
    uint256 _amount,
    bytes memory _data,
    uint256 _gasLimit
  ) external payable;

  /// @notice Complete ERC20 withdraw from L2 to L1 and send fund to recipient's account in L1.
  /// @dev Make this function payable to handle WETH deposit/withdraw.
  ///      The function should only be called by L1ScrollMessenger.
  ///      The function should also only be called by L2ERC20Gateway in L2.
  /// @param _l1Token The address of corresponding L1 token.
  /// @param _l2Token The address of corresponding L2 token.
  /// @param _from The address of account who withdraw the token in L2.
  /// @param _to The address of recipient in L1 to receive the token.
  /// @param _amount The amount of the token to withdraw.
  /// @param _data Optional data to forward to recipient's account.
  function finalizeWithdrawERC20(
    address _l1Token,
    address _l2Token,
    address _from,
    address _to,
    uint256 _amount,
    bytes calldata _data
  ) external payable;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IScrollGateway } from "./IScrollGateway.sol";
import { IScrollMessenger } from "../IScrollMessenger.sol";

abstract contract ScrollGatewayBase is IScrollGateway {
  /*************
   * Constants *
   *************/

  // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.5.0/contracts/security/ReentrancyGuard.sol
  uint256 private constant _NOT_ENTERED = 1;
  uint256 private constant _ENTERED = 2;

  /*************
   * Variables *
   *************/

  /// @inheritdoc IScrollGateway
  address public override counterpart;

  /// @inheritdoc IScrollGateway
  address public override router;

  /// @inheritdoc IScrollGateway
  address public override messenger;

  /// @dev The status of for non-reentrant check.
  uint256 private _status;

  /**********************
   * Function Modifiers *
   **********************/

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

  modifier onlyMessenger() {
    require(msg.sender == messenger, "only messenger can call");
    _;
  }

  modifier onlyCallByCounterpart() {
    address _messenger = messenger; // gas saving
    require(msg.sender == _messenger, "only messenger can call");
    require(counterpart == IScrollMessenger(_messenger).xDomainMessageSender(), "only call by conterpart");
    _;
  }

  /***************
   * Constructor *
   ***************/

  function _initialize(
    address _counterpart,
    address _router,
    address _messenger
  ) internal {
    require(_counterpart != address(0), "zero counterpart address");
    require(_messenger != address(0), "zero messenger address");

    counterpart = _counterpart;
    messenger = _messenger;

    // @note: the address of router could be zero, if this contract is GatewayRouter.
    if (_router != address(0)) {
      router = _router;
    }

    // for reentrancy guard
    _status = _NOT_ENTERED;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IL1ERC20Gateway } from "./IL1ERC20Gateway.sol";

// solhint-disable no-empty-blocks

abstract contract L1ERC20Gateway is IL1ERC20Gateway {
  /****************************
   * Public Mutated Functions *
   ****************************/

  /// @inheritdoc IL1ERC20Gateway
  function depositERC20(
    address _token,
    uint256 _amount,
    uint256 _gasLimit
  ) external payable override {
    _deposit(_token, msg.sender, _amount, new bytes(0), _gasLimit);
  }

  /// @inheritdoc IL1ERC20Gateway
  function depositERC20(
    address _token,
    address _to,
    uint256 _amount,
    uint256 _gasLimit
  ) external payable override {
    _deposit(_token, _to, _amount, new bytes(0), _gasLimit);
  }

  /// @inheritdoc IL1ERC20Gateway
  function depositERC20AndCall(
    address _token,
    address _to,
    uint256 _amount,
    bytes memory _data,
    uint256 _gasLimit
  ) external payable override {
    _deposit(_token, _to, _amount, _data, _gasLimit);
  }

  /**********************
   * Internal Functions *
   **********************/

  /// @dev Internal function to do all the deposit operations.
  ///
  /// @param _token The token to deposit.
  /// @param _to The recipient address to recieve the token in L2.
  /// @param _amount The amount of token to deposit.
  /// @param _data Optional data to forward to recipient's account.
  /// @param _gasLimit Gas limit required to complete the deposit on L2.
  function _deposit(
    address _token,
    address _to,
    uint256 _amount,
    bytes memory _data,
    uint256 _gasLimit
  ) internal virtual;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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

pragma solidity ^0.8.0;

interface IScrollMessenger {
  /**********
   * Events *
   **********/

  /// @notice Emitted when a cross domain message is sent.
  /// @param sender The address of the sender who initiates the message.
  /// @param target The address of target contract to call.
  /// @param value The amount of value passed to the target contract.
  /// @param messageNonce The nonce of the message.
  /// @param gasLimit The optional gas limit passed to L1 or L2.
  /// @param message The calldata passed to the target contract.
  event SentMessage(
    address indexed sender,
    address indexed target,
    uint256 value,
    uint256 messageNonce,
    uint256 gasLimit,
    bytes message
  );

  /// @notice Emitted when a cross domain message is relayed successfully.
  /// @param messageHash The hash of the message.
  event RelayedMessage(bytes32 indexed messageHash);

  /// @notice Emitted when a cross domain message is failed to relay.
  /// @param messageHash The hash of the message.
  event FailedRelayedMessage(bytes32 indexed messageHash);

  /*************************
   * Public View Functions *
   *************************/

  /// @notice Return the sender of a cross domain message.
  function xDomainMessageSender() external view returns (address);

  /****************************
   * Public Mutated Functions *
   ****************************/

  /// @notice Send cross chain message from L1 to L2 or L2 to L1.
  /// @param target The address of account who recieve the message.
  /// @param value The amount of ether passed when call target contract.
  /// @param message The content of the message.
  /// @param gasLimit Gas limit required to complete the message relay on corresponding chain.
  function sendMessage(
    address target,
    uint256 value,
    bytes calldata message,
    uint256 gasLimit
  ) external payable;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IScrollGateway {
  /// @notice The address of corresponding L1/L2 Gateway contract.
  function counterpart() external view returns (address);

  /// @notice The address of L1GatewayRouter/L2GatewayRouter contract.
  function router() external view returns (address);

  /// @notice The address of corresponding L1ScrollMessenger/L2ScrollMessenger contract.
  function messenger() external view returns (address);
}