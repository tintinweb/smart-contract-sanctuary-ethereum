// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./interfaces/IBatcher.sol";
import "../../interfaces/IMetaRouter.sol";
import "../ConvexExecutor/interfaces/ICurvePool.sol";
import "../ConvexExecutor/interfaces/ICurveDepositZapper.sol";

import "./EIP712.sol";

/// @title Batcher
/// @author 0xAd1
/// @notice Used to batch user deposits and withdrawals until the next rebalance
contract Batcher is Ownable, IBatcher, EIP712 {
  using SafeERC20 for IERC20;

  uint256 DUST_LIMIT = 10000;

  struct Vault {
    address tokenAddress;
    uint256 maxAmount;
    uint256 currentAmount;
  }

  mapping(address => Vault) public vaults;

  mapping(address => mapping(address => uint256)) public depositLedger;
  mapping(address => mapping(address => uint256)) public withdrawLedger;

  event DepositRequest(
    address indexed sender,
    address indexed router,
    uint256 amountIn
  );
  event WithdrawRequest(
    address indexed sender,
    address indexed router,
    uint256 amountOut
  );

  address public verificationAuthority;
  address public governance;
  address public pendingGovernance;
  uint256 public slippageForCurveLp = 30;
  constructor(address _verificationAuthority, address _governance) {
    verificationAuthority = _verificationAuthority;
    governance = _governance;
  }

  function setAuthority(address authority) public onlyGovernance {
    verificationAuthority = authority;
  }

  /// @inheritdoc IBatcher
  function depositFunds(
    uint256 amountIn,
    address routerAddress,
    bytes memory signature
  ) external override validDeposit(routerAddress, signature) {
    require(
      IERC20(vaults[routerAddress].tokenAddress).allowance(
        msg.sender,
        address(this)
      ) >= amountIn,
      "No allowance"
    );

    IERC20(vaults[routerAddress].tokenAddress).safeTransferFrom(
      msg.sender,
      address(this),
      amountIn
    );

    vaults[routerAddress].currentAmount += amountIn;
    require(vaults[routerAddress].currentAmount <= vaults[routerAddress].maxAmount, "Exceeded deposit limit");

    _completeDeposit(routerAddress, amountIn);
  }

  /// @inheritdoc IBatcher
  function depositFundsInCurveLpToken(
    uint256 amountIn,
    address routerAddress,
    bytes memory signature
  ) external override validDeposit(routerAddress, signature) {
    /// Curve Lp Token - UST_Wormhole
    IERC20 lpToken = IERC20(0xCEAF7747579696A2F0bb206a14210e3c9e6fB269);

    require(
      lpToken.allowance(msg.sender, address(this)) >= amountIn,
      "No allowance"
    );

    lpToken.safeTransferFrom(msg.sender, address(this), amountIn);

    uint256 usdcReceived = _convertLpTokenIntoUSDC(lpToken);

    _completeDeposit(routerAddress, usdcReceived);
  }

  function _completeDeposit(address routerAddress, uint256 amountIn) internal {
    depositLedger[routerAddress][msg.sender] =
      depositLedger[routerAddress][msg.sender] +
      (amountIn);

    emit DepositRequest(msg.sender, routerAddress, amountIn);
  }

  /// @inheritdoc IBatcher
  function withdrawFunds(uint256 amountIn, address routerAddress)
    external
    override
  {
    require(
      vaults[routerAddress].tokenAddress != address(0),
      "Invalid router address"
    );

    require(
      depositLedger[routerAddress][msg.sender] == 0,
      "Cannot withdraw funds from router while waiting to deposit"
    );

    // require(depositLedger[routerAddress][msg.sender] >= amountOut, "No funds available");

    IERC20(routerAddress).safeTransferFrom(msg.sender, address(this), amountIn);

    withdrawLedger[routerAddress][msg.sender] =
      withdrawLedger[routerAddress][msg.sender] +
      (amountIn);

    vaults[routerAddress].currentAmount -= amountIn;

    emit WithdrawRequest(msg.sender, routerAddress, amountIn);
  }

  /// @inheritdoc IBatcher
  function batchDeposit(address routerAddress, address[] memory users)
    external
    override
    onlyOwner
  {
    IMetaRouter router = IMetaRouter(routerAddress);

    uint256 amountToDeposit = 0;
    uint256 oldLPBalance = IERC20(address(router)).balanceOf(address(this));

    for (uint256 i = 0; i < users.length; i++) {
      amountToDeposit =
        amountToDeposit +
        (depositLedger[routerAddress][users[i]]);
    }

    require(amountToDeposit > 0, "no deposits to make");

    uint256 lpTokensReportedByRouter = router.deposit(
      amountToDeposit,
      address(this)
    );

    uint256 lpTokensReceived = IERC20(address(router)).balanceOf(
      address(this)
    ) - (oldLPBalance);

    require(
      lpTokensReceived == lpTokensReportedByRouter,
      "LP tokens received by router does not match"
    );

    for (uint256 i = 0; i < users.length; i++) {
      uint256 userAmount = depositLedger[routerAddress][users[i]];
      if (userAmount > 0) {
        uint256 userShare = (userAmount * (lpTokensReceived)) /
          (amountToDeposit);
        IERC20(address(router)).safeTransfer(users[i], userShare);
        depositLedger[routerAddress][users[i]] = 0;
      }
    }
  }

  /// @inheritdoc IBatcher
  function batchWithdraw(address routerAddress, address[] memory users)
    external
    override
    onlyOwner
  {
    IMetaRouter router = IMetaRouter(routerAddress);

    IERC20 token = IERC20(vaults[routerAddress].tokenAddress);

    uint256 amountToWithdraw = 0;
    uint256 oldWantBalance = token.balanceOf(address(this));

    for (uint256 i = 0; i < users.length; i++) {
      amountToWithdraw =
        amountToWithdraw +
        (withdrawLedger[routerAddress][users[i]]);
    }

    require(amountToWithdraw > 0, "no deposits to make");

    uint256 wantTokensReportedByRouter = router.withdraw(
      amountToWithdraw,
      address(this)
    );

    uint256 wantTokensReceived = token.balanceOf(address(this)) -
      (oldWantBalance);

    require(
      wantTokensReceived == wantTokensReportedByRouter,
      "Want tokens received by router does not match"
    );

    for (uint256 i = 0; i < users.length; i++) {
      uint256 userAmount = withdrawLedger[routerAddress][users[i]];
      if (userAmount > 0) {
        uint256 userShare = (userAmount * wantTokensReceived) /
          amountToWithdraw;
        token.safeTransfer(users[i], userShare);

        withdrawLedger[routerAddress][users[i]] = 0;
      }
    }
  }

  /// @inheritdoc IBatcher
  function setRouterParams(address routerAddress, address token, uint256 maxLimit)
    external
    override
    onlyOwner
  {
    require(routerAddress != address(0), "Invalid router address");
    require(token != address(0), "Invalid token address");
    // (, , IERC20Metadata token0, IERC20Metadata token1) = _getVault(routerAddress);
    // require(address(token0) == token || address(token1) == token, 'wrong token address');
    vaults[routerAddress] = Vault({
      tokenAddress: token, 
      maxAmount: maxLimit,
      currentAmount: 0
    });

    IERC20(token).approve(routerAddress, type(uint256).max);
  }

  /**
   * @notice Get the balance of a token in contract
   * @param token token whose balance needs to be returned
   * @return balance of a token in contract
   */
  function _tokenBalance(IERC20Metadata token) internal view returns (uint256) {
    return token.balanceOf(address(this));
  }

  function sweep(address _token) public onlyGovernance {
    IERC20(_token).transfer(
      msg.sender,
      IERC20(_token).balanceOf(address(this))
    );
  }

  function setGovernance(address _governance) external onlyGovernance {
    pendingGovernance = _governance;
  }

  function acceptGovernance() external {
    require(
      msg.sender == pendingGovernance,
      "Only pending governance can accept"
    );
    governance = pendingGovernance;
  }

  /// @notice Helper to convert Lp tokens into USDC
  /// @dev Burns LpTokens on UST3-Wormhole pool on curve to get USDC
  /// @param lpToken Curve Lp Token
  function _convertLpTokenIntoUSDC(IERC20 lpToken)
    internal
    returns (uint256 receivedWantTokens)
  {
    uint256 MAX_BPS = 10000;

    ICurvePool ust3Pool = ICurvePool(
      0xCEAF7747579696A2F0bb206a14210e3c9e6fB269
    );
    ICurveDepositZapper curve3PoolZap = ICurveDepositZapper(
      0xA79828DF1850E8a3A3064576f380D90aECDD3359
    );

    uint256 _amount = lpToken.balanceOf(address(this));

    lpToken.safeApprove(address(curve3PoolZap), _amount);

    int128 usdcIndexInPool = int128(int256(uint256(2)));

    // estimate amount of USDC received on burning Lp tokens
    uint256 expectedWantTokensOut = curve3PoolZap.calc_withdraw_one_coin(
      address(ust3Pool),
      _amount,
      usdcIndexInPool
    );
    // burn Lp tokens to receive USDC with a slippage of 0.3%
    receivedWantTokens = curve3PoolZap.remove_liquidity_one_coin(
      address(ust3Pool),
      _amount,
      usdcIndexInPool,
      (expectedWantTokensOut * (MAX_BPS - slippageForCurveLp)) / (MAX_BPS)
    );
  }


  function setSlippage(uint256 _slippage) external override onlyOwner {
    require(
      _slippage >= 0 && _slippage <= 10000,
      "Slippage must be between 0 and 10000"
    );
    slippageForCurveLp = _slippage;
  }

  modifier onlyGovernance() {
    require(governance == msg.sender, "Only governance can call this");
    _;
  }

  modifier validDeposit(address routerAddress, bytes memory signature) {
    require(
      verifySignatureAgainstAuthority(signature, verificationAuthority),
      "Signature is not valid"
    );

    require(
      vaults[routerAddress].tokenAddress != address(0),
      "Invalid router address"
    );

    require(
      withdrawLedger[routerAddress][msg.sender] == 0,
      "Cannot deposit funds to router while waiting to withdraw"
    );

    _;
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/**
 * @title IPeripheryBatcher
 * @notice A batcher to resolve router deposits/withdrawals in batches
 * @dev Provides an interface for Batcher
 */
interface IBatcher {
  /**
   * @notice Stores the deposits for future batching via periphery
   * @param amountIn Value of token to be deposited
   * @param routerAddress address of router to deposit into
   * @param signature signature verifying that depositor has enough karma and is authorized to deposit by brahma
   */
  function depositFunds(
    uint256 amountIn,
    address routerAddress,
    bytes memory signature
  ) external;

  /**
   * @notice Stores the deposits for future batching via periphery
   * @param amountIn Value of Lp token to be deposited
   * @param routerAddress address of router to deposit into
   * @param signature signature verifying that depositor has enough karma and is authorized to deposit by brahma
   */
  function depositFundsInCurveLpToken(
    uint256 amountIn,
    address routerAddress,
    bytes memory signature
  ) external;

  /**
   * @notice Stores the deposits for future batching via periphery
   * @param amountOut Value of token to be deposited
   * @param routerAddress address of router to deposit into
   */
  function withdrawFunds(uint256 amountOut, address routerAddress) external;

  /**
   * @notice Performs deposits on the periphery for the supplied users in batch
   * @param routerAddress address of router to deposit inton
   * @param users array of users whose deposits must be resolved
   */
  function batchDeposit(address routerAddress, address[] memory users) external;

  /**
   * @notice Performs withdraws on the periphery for the supplied users in batch
   * @param routerAddress address of router to deposit inton
   * @param users array of users whose deposits must be resolved
   */
  function batchWithdraw(address routerAddress, address[] memory users)
    external;

  /**
   * @notice To set a token address as the deposit token for a router
   * @param routerAddress address of router to deposit inton
   * @param token address of token which is to be deposited into router
   */
  function setRouterParams(address routerAddress, address token, uint256 maxLimit) external;


  /**
   * @notice To set slippage param for curve lp token conversion
   * @param slippage for curve lp token to usdc conversion
   */
  function setSlippage(uint256 slippage) external;
}

/// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface IMetaRouter {
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

/// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface ICurvePool {
  function exchange(
    int128 i,
    int128 j,
    uint256 _dx,
    uint256 _min_dy,
    address _receiver
  ) external returns (uint256);

  function remove_liquidity_one_coin(
    uint256 _token_amount,
    int128 i,
    uint256 min_amount
  ) external returns (uint256);

  function add_liquidity(uint256[3] memory amounts, uint256 min_mint_amount)
    external
    returns (uint256);

  function get_dy(
    int128 i,
    int128 j,
    uint256 _dx
  ) external view returns (uint256);

  function get_virtual_price() external view returns (uint256);

  function balanceOf(address) external view returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

}

/// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface ICurveDepositZapper {
  function calc_withdraw_one_coin(
    address _pool,
    uint256 _token_amount,
    int128 i
  ) external returns (uint256);

  function calc_token_amount(
    address _pool,
    uint256[4] memory _amounts,
    bool _is_deposit
  ) external returns (uint256);

  function remove_liquidity_one_coin(
    address _pool,
    uint256 _burn_amount,
    int128 i,
    uint256 _min_amount
  ) external returns (uint256);

  function add_liquidity(
    address _pool,
    uint256[4] memory _deposit_amounts,
    uint256 _min_mint_amount
  ) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title EIP712
/// @author 0xAd1
/// @notice Used to verify signatures
contract EIP712 {

    /// @notice Verifies a signature against alleged signer of the signature
    /// @param signature Signature to verify
    /// @param authority Signer of the signature
    /// @return True if the signature is signed by authority
    function verifySignatureAgainstAuthority(
        bytes memory signature,
        address authority
    ) internal returns (bool){
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
            abi.encode(
                keccak256("deposit(address owner)"),
                msg.sender
            )
        );

        (bytes32 r, bytes32 s, uint8 v) = splitSignature(signature);

        bytes32 hash = keccak256(abi.encodePacked("\x19\x01", eip712DomainHash, hashStruct));
        address signer = ecrecover(hash, v, r, s);
        require(signer == authority, "Invalid authority");
        require(signer != address(0), "ECDSA: invalid signature");
        return true;
    }

    function splitSignature(bytes memory sig)
        internal
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            /*
            First 32 bytes stores the length of the signature
            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature
            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
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