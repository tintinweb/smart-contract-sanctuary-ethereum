// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.3;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "contracts/OndoRegistryClient.sol";
import "contracts/Multicall.sol";
import "contracts/interfaces/IPairVault.sol";
import "contracts/interfaces/IRollover.sol";
import "contracts/interfaces/ISingleAssetVault.sol";
import "contracts/interfaces/ISAStrategy.sol";
import "contracts/libraries/OndoLibrary.sol";

contract SingleAssetVault is Multicall, ISingleAssetVault {
  using SafeERC20 for IERC20;

  uint256 public constant MULTIPLIER_DENOMINATOR = 2**100;

  IERC20 public immutable override asset;

  mapping(address => bool) public isStrategy;

  uint256 public totalFundAmount;
  uint256 public totalActivePoolAmount;
  uint256 public totalPassivePoolAmount;

  PoolData[] public pools;
  Action[] public actions; // calculate token balance based on this action order

  mapping(address => UserDeposit[]) internal userDeposits;
  mapping(address => uint256) internal fromDepositIndex; // calculate token balance from this deposit index

  bool public withdrawEnabled;

  /**
   * @dev Setup contract dependencies here
   * @param _asset single asset
   * @param _registry Pointer to Registry
   */
  constructor(address _asset, address _registry) OndoRegistryClient(_registry) {
    require(_asset != address(0), "Invalid asset");
    asset = IERC20(_asset);
  }

  function setStrategy(address _strategy, bool _flag)
    external
    isAuthorized(OLib.GUARDIAN_ROLE)
    nonReentrant
  {
    isStrategy[_strategy] = _flag;
  }

  function setWithdrawEnabled(bool _withdrawEnabled)
    external
    isAuthorized(OLib.GUARDIAN_ROLE)
  {
    withdrawEnabled = _withdrawEnabled;
  }

  function deposit(uint256 _amount) external nonReentrant {
    require(_amount > 0, "zero amount");
    asset.safeTransferFrom(msg.sender, address(this), _amount);

    totalFundAmount += _amount;
    userDeposits[msg.sender].push(
      UserDeposit({amount: _amount, firstActionId: actions.length})
    );

    emit Deposit(msg.sender, _amount, pools.length);
  }

  function withdraw(uint256 _amount, address _to)
    external
    whenNotPaused
    nonReentrant
  {
    require(_amount > 0, "zero amount");
    require(withdrawEnabled, "withdraw disabled");
    (
      uint256 activeInvestAmount,
      uint256 passiveInvestAmount,
      uint256 remainAmount
    ) = tokenBalances(msg.sender);
    require(activeInvestAmount + passiveInvestAmount == 0, "invested!");
    require(remainAmount >= _amount, "insufficient balance");

    fromDepositIndex[msg.sender] = userDeposits[msg.sender].length;
    if (remainAmount > _amount) {
      userDeposits[msg.sender].push(
        UserDeposit({
          amount: remainAmount - _amount,
          firstActionId: actions.length
        })
      );
    }

    totalFundAmount -= _amount;
    asset.safeTransfer(_to, _amount);

    emit Withdraw(msg.sender, _amount, _to);
  }

  function massUpdateUserBalance(address _user) external {
    (
      uint256 activeInvestAmount,
      uint256 passiveInvestAmount,
      uint256 remainAmount
    ) = tokenBalances(msg.sender);
    require(activeInvestAmount + passiveInvestAmount == 0, "invested!");

    fromDepositIndex[msg.sender] = userDeposits[msg.sender].length;
    if (remainAmount > 0) {
      userDeposits[msg.sender].push(
        UserDeposit({amount: remainAmount, firstActionId: actions.length})
      );
    }

    emit MassUpdateUserBalance(_user);
  }

  function invest(
    address _strategy,
    uint256 _amount,
    bool _isPassive,
    bytes memory _data
  ) external whenNotPaused isAuthorized(OLib.STRATEGIST_ROLE) nonReentrant {
    require(isStrategy[_strategy], "invalid strategy");

    if (_isPassive) {
      pools.push(
        PoolData({
          isPassive: true,
          investAmount: _amount,
          strategy: _strategy,
          strategist: msg.sender,
          depositMultiplier: 0,
          redemptionMultiplier: 0,
          redeemed: false
        })
      );
      totalPassivePoolAmount += _amount;
    } else {
      pools.push(
        PoolData({
          isPassive: false,
          investAmount: _amount,
          strategy: _strategy,
          strategist: msg.sender,
          depositMultiplier: OLib.safeMulDiv(
            _amount,
            MULTIPLIER_DENOMINATOR,
            (totalFundAmount + totalPassivePoolAmount)
          ),
          redemptionMultiplier: MULTIPLIER_DENOMINATOR,
          redeemed: false
        })
      );
      actions.push(
        Action({actionType: ActionType.Invest, poolId: pools.length - 1})
      );
      totalActivePoolAmount += _amount;
    }

    totalFundAmount -= _amount;

    uint256 poolId = pools.length - 1;
    asset.safeApprove(_strategy, _amount);
    ISAStrategy(_strategy).invest(poolId, _amount, _data);

    emit Invest(poolId, msg.sender, _strategy, _amount, _data);
  }

  function redeem(uint256 _poolId, bytes memory _data)
    external
    whenNotPaused
    nonReentrant
  {
    PoolData storage pool = pools[_poolId];
    require(
      msg.sender == pool.strategist ||
        registry.authorized(OLib.GUARDIAN_ROLE, msg.sender),
      "Unauthorized"
    );
    require(!pool.redeemed, "Already redeemed");

    (bool pendingAdditionalWithdraw, uint256 redeemAmount) =
      ISAStrategy(pool.strategy).redeem(_poolId, _data);

    if (pendingAdditionalWithdraw) {
      return;
    }

    pool.redeemed = true;
    pool.redemptionMultiplier = OLib.safeMulDiv(
      redeemAmount,
      MULTIPLIER_DENOMINATOR,
      pool.investAmount
    );

    if (pool.isPassive) {
      pool.depositMultiplier = OLib.safeMulDiv(
        pool.investAmount,
        MULTIPLIER_DENOMINATOR,
        (totalFundAmount + totalPassivePoolAmount)
      );

      actions.push(Action({actionType: ActionType.Invest, poolId: _poolId}));
      totalPassivePoolAmount -= pool.investAmount;
    } else {
      totalActivePoolAmount -= pool.investAmount;
    }

    actions.push(Action({actionType: ActionType.Redeem, poolId: _poolId}));
    totalFundAmount += redeemAmount;

    emit Redeem(_poolId, msg.sender, redeemAmount, _data);
  }

  function tokenBalance(address _user) external view returns (uint256 amount) {
    (
      uint256 activeInvestAmount,
      uint256 passiveInvestAmount,
      uint256 remainAmount
    ) = tokenBalances(_user);

    return activeInvestAmount + passiveInvestAmount + remainAmount;
  }

  function tokenBalances(address _user)
    public
    view
    returns (
      uint256 activeInvestAmount,
      uint256 passiveInvestAmount,
      uint256 remainAmount
    )
  {
    uint256 depositLength = userDeposits[_user].length;
    uint256 depositIndex = fromDepositIndex[_user];
    if (depositLength == depositIndex) {
      return (0, 0, 0);
    }

    UserDeposit[] storage deposits = userDeposits[_user];

    uint256 currentActionId = deposits[depositIndex].firstActionId;
    uint256[] memory userPoolDeposits = new uint256[](pools.length); // this is to reduce the memory size
    while (depositIndex < depositLength || currentActionId < actions.length) {
      if (
        depositIndex < depositLength &&
        currentActionId == deposits[depositIndex].firstActionId
      ) {
        remainAmount += deposits[depositIndex].amount;
        depositIndex++;
        continue;
      }

      // always: currentActionId < deposits[depositIndex].actionId
      Action memory action = actions[currentActionId];
      PoolData memory pool = pools[action.poolId];
      if (action.actionType == ActionType.Invest) {
        userPoolDeposits[action.poolId] = OLib.safeMulDiv(
          remainAmount,
          pool.depositMultiplier,
          MULTIPLIER_DENOMINATOR
        );
        remainAmount -= userPoolDeposits[action.poolId];
        activeInvestAmount += userPoolDeposits[action.poolId];
      } else if (userPoolDeposits[action.poolId] > 0) {
        uint256 redeemAmount =
          OLib.safeMulDiv(
            userPoolDeposits[action.poolId],
            pool.redemptionMultiplier,
            MULTIPLIER_DENOMINATOR
          );
        remainAmount += redeemAmount;
        activeInvestAmount -= userPoolDeposits[action.poolId];
      }
      currentActionId++;
    }

    if (totalPassivePoolAmount != 0) {
      passiveInvestAmount = OLib.safeMulDiv(
        remainAmount,
        totalPassivePoolAmount,
        (totalFundAmount + totalPassivePoolAmount)
      );
      remainAmount -= passiveInvestAmount;
    }
  }
}

// SPDX-License-Identifier: MIT

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.3;

import "contracts/OndoRegistryClientInitializable.sol";

abstract contract OndoRegistryClient is OndoRegistryClientInitializable {
  constructor(address _registry) {
    __OndoRegistryClient__initialize(_registry);
  }
}

/**SPDX-License-Identifier: AGPL-3.0

          ▄▄█████████▄                                                                  
       ╓██▀└ ,╓▄▄▄, '▀██▄                                                               
      ██▀ ▄██▀▀╙╙▀▀██▄ └██µ           ,,       ,,      ,     ,,,            ,,,         
     ██ ,██¬ ▄████▄  ▀█▄ ╙█▄      ▄███▀▀███▄   ███▄    ██  ███▀▀▀███▄    ▄███▀▀███,     
    ██  ██ ╒█▀'   ╙█▌ ╙█▌ ██     ▐██      ███  █████,  ██  ██▌    └██▌  ██▌     └██▌    
    ██ ▐█▌ ██      ╟█  █▌ ╟█     ██▌      ▐██  ██ └███ ██  ██▌     ╟██ j██       ╟██    
    ╟█  ██ ╙██    ▄█▀ ▐█▌ ██     ╙██      ██▌  ██   ╙████  ██▌    ▄██▀  ██▌     ,██▀    
     ██ "██, ╙▀▀███████████⌐      ╙████████▀   ██     ╙██  ███████▀▀     ╙███████▀`     
      ██▄ ╙▀██▄▄▄▄▄,,,                ¬─                                    '─¬         
       ╙▀██▄ '╙╙╙▀▀▀▀▀▀▀▀                                                               
          ╙▀▀██████R⌐                                                                   

 */
pragma solidity 0.8.3;

import "@openzeppelin/contracts/utils/Address.sol";
import "./interfaces/IMulticall.sol";
import "./OndoRegistryClient.sol";

/// @title Multicall
/// @notice Enables calling multiple methods in a single call to the contract
abstract contract Multicall is IMulticall, OndoRegistryClient {
  using Address for address;

  /// @inheritdoc IMulticall
  function multiexcall(ExCallData[] calldata exCallData)
    external
    payable
    override
    isAuthorized(OLib.GUARDIAN_ROLE)
    returns (bytes[] memory results)
  {
    results = new bytes[](exCallData.length);
    for (uint256 i = 0; i < exCallData.length; i++) {
      results[i] = exCallData[i].target.functionCallWithValue(
        exCallData[i].data,
        exCallData[i].value,
        "Multicall: multiexcall failed"
      );
    }
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.3;

import "contracts/libraries/OndoLibrary.sol";
import "contracts/interfaces/ITrancheToken.sol";
import "contracts/interfaces/IStrategy.sol";

interface IPairVault {
  // Container to return Vault info to caller
  struct VaultView {
    uint256 id;
    Asset[] assets;
    IStrategy strategy; // Shared contract that interacts with AMMs
    address creator; // Account that calls createVault
    address strategist; // Has the right to call invest() and redeem(), and harvest() if strategy supports it
    address rollover;
    uint256 hurdleRate; // Return offered to senior tranche
    OLib.State state; // Current state of Vault
    uint256 startAt; // Time when the Vault is unpaused to begin accepting deposits
    uint256 investAt; // Time when investors can't move funds, strategist can invest
    uint256 redeemAt; // Time when strategist can redeem LP tokens, investors can withdraw
  }

  // Track the asset type and amount in different stages
  struct Asset {
    IERC20 token;
    ITrancheToken trancheToken;
    uint256 trancheCap;
    uint256 userCap;
    uint256 deposited;
    uint256 originalInvested;
    uint256 totalInvested; // not literal 1:1, originalInvested + proportional lp from mid-term
    uint256 received;
    uint256 rolloverDeposited;
  }

  function getState(uint256 _vaultId) external view returns (OLib.State);

  function createVault(OLib.VaultParams calldata _params)
    external
    returns (uint256 vaultId);

  function deposit(
    uint256 _vaultId,
    OLib.Tranche _tranche,
    uint256 _amount
  ) external;

  function depositETH(uint256 _vaultId, OLib.Tranche _tranche) external payable;

  function depositLp(uint256 _vaultId, uint256 _amount)
    external
    returns (uint256 seniorTokensOwed, uint256 juniorTokensOwed);

  function invest(
    uint256 _vaultId,
    uint256 _seniorMinOut,
    uint256 _juniorMinOut
  ) external returns (uint256, uint256);

  function redeem(
    uint256 _vaultId,
    uint256 _seniorMinOut,
    uint256 _juniorMinOut
  ) external returns (uint256, uint256);

  function withdraw(uint256 _vaultId, OLib.Tranche _tranche)
    external
    returns (uint256);

  function withdrawETH(uint256 _vaultId, OLib.Tranche _tranche)
    external
    returns (uint256);

  function withdrawLp(uint256 _vaultId, uint256 _amount)
    external
    returns (uint256, uint256);

  function claim(uint256 _vaultId, OLib.Tranche _tranche)
    external
    returns (uint256, uint256);

  function claimETH(uint256 _vaultId, OLib.Tranche _tranche)
    external
    returns (uint256, uint256);

  function depositFromRollover(
    uint256 _vaultId,
    uint256 _rolloverId,
    uint256 _seniorAmount,
    uint256 _juniorAmount
  ) external;

  function rolloverClaim(uint256 _vaultId, uint256 _rolloverId)
    external
    returns (uint256, uint256);

  function setRollover(
    uint256 _vaultId,
    address _rollover,
    uint256 _rolloverId
  ) external;

  function canDeposit(uint256 _vaultId) external view returns (bool);

  function getVaultById(uint256 _vaultId)
    external
    view
    returns (VaultView memory);

  function vaultInvestor(uint256 _vaultId, OLib.Tranche _tranche)
    external
    view
    returns (
      uint256 position,
      uint256 claimableBalance,
      uint256 withdrawableExcess,
      uint256 withdrawableBalance
    );

  function seniorExpected(uint256 _vaultId) external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.3;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "contracts/interfaces/ITrancheToken.sol";
import "contracts/libraries/OndoLibrary.sol";

interface IRollover {
  // ========== EVENTS ==========

  event CreatedRollover(
    uint256 indexed rolloverId,
    address indexed creator,
    address indexed strategist,
    address seniorAsset,
    address juniorAsset,
    address seniorToken,
    address juniorToken
  );

  event AddedVault(uint256 indexed rolloverId, uint256 indexed vaultId);

  event MigratedRollover(
    uint256 indexed rolloverId,
    uint256 indexed newVault,
    uint256 seniorDeposited,
    uint256 juniorDeposited
  );

  event Withdrew(
    address indexed user,
    uint256 indexed rolloverId,
    uint256 indexed trancheId,
    uint256 equivalentInvested,
    uint256 withdrawnShares,
    uint256 totalShares,
    uint256 excess
  );

  event Deposited(
    address indexed user,
    uint256 indexed rolloverId,
    uint256 indexed trancheId,
    uint256 depositAmount,
    uint256 excess,
    uint256 sharesMinted
  );

  event Claimed(
    address indexed user,
    uint256 indexed rolloverId,
    uint256 indexed trancheId,
    uint256 tokens,
    uint256 excess
  );
  event DepositedLP(
    address indexed depositor,
    uint256 indexed vaultId,
    uint256 amount,
    uint256 seniorTrancheMintedAmount,
    uint256 juniorTrancheMintedAmount
  );

  event WithdrewLP(
    address indexed depositor,
    uint256 indexed vaultId,
    uint256 amount,
    uint256 seniorTrancheBurnedAmount,
    uint256 juniorTrancheBurnedAmount
  );
  // ========== STRUCTS ==========

  struct TrancheRoundView {
    uint256 deposited;
    uint256 invested; // Total, if any, actually invested
    uint256 redeemed; // After Vault is done, total tokens redeemed for LP
    uint256 shares;
    uint256 newDeposited;
    uint256 newInvested;
  }

  struct RoundView {
    uint256 vaultId;
    TrancheRoundView[] tranches;
  }

  struct RolloverView {
    address creator;
    address strategist;
    IERC20[] assets;
    ITrancheToken[] rolloverTokens;
    uint256 thisRound;
  }

  struct TrancheRound {
    uint256 deposited;
    uint256 invested; // Total, if any, actually invested
    uint256 redeemed; // After Vault is done, total tokens redeemed for LP
    uint256 shares;
    uint256 newDeposited;
    uint256 newInvested;
    mapping(address => OLib.Investor) investors;
  }

  struct Round {
    uint256 vaultId;
    mapping(OLib.Tranche => TrancheRound) tranches;
  }

  struct Rollover {
    address creator;
    address strategist;
    mapping(uint256 => Round) rounds;
    mapping(OLib.Tranche => IERC20) assets;
    mapping(OLib.Tranche => ITrancheToken) rolloverTokens;
    mapping(OLib.Tranche => mapping(address => uint256)) investorLastUpdates;
    uint256 thisRound;
    bool dead;
  }

  struct SlippageSettings {
    uint256 seniorMinInvest;
    uint256 seniorMinRedeem;
    uint256 juniorMinInvest;
    uint256 juniorMinRedeem;
  }

  // ========== FUNCTIONS ==========

  function getRollover(uint256 rolloverId)
    external
    view
    returns (RolloverView memory);

  function getRound(uint256 _rolloverId, uint256 _roundIndex)
    external
    view
    returns (RoundView memory);

  function getNextVault(uint256 rolloverId) external view returns (uint256);

  function deposit(
    uint256 _rolloverId,
    OLib.Tranche _tranche,
    uint256 _amount
  ) external;

  function withdraw(
    uint256 _rolloverId,
    OLib.Tranche _tranche,
    uint256 shares
  ) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.3;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../libraries/OndoLibrary.sol";
import "./ITrancheToken.sol";

interface ISingleAssetVault {
  // Events
  event Deposit(address indexed user, uint256 amount, uint256 investFromIndex);
  event Withdraw(
    address indexed user,
    uint256 amount,
    address indexed recipient
  );
  event MassUpdateUserBalance(address indexed user);
  event Invest(
    uint256 indexed poolId,
    address indexed strategist,
    address indexed strategy,
    uint256 amount,
    bytes data
  );
  event Redeem(
    uint256 indexed poolId,
    address indexed redeemer,
    uint256 amount,
    bytes data
  );

  // Enums / Structs
  enum ActionType {Invest, Redeem}

  /**
   * redeem rollover will have two steps
   * 1. redeem from rollover -> will update vaultId field with withdrawn vault id
   * 2. redeem from vault once redeem state
   */
  struct PoolData {
    bool isPassive;
    uint256 investAmount;
    address strategy;
    address strategist;
    uint256 depositMultiplier;
    uint256 redemptionMultiplier;
    bool redeemed;
  }
  struct Action {
    ActionType actionType;
    uint256 poolId;
  }
  struct UserDeposit {
    uint256 amount;
    uint256 firstActionId;
  }

  // Functions

  function asset() external view returns (IERC20);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.3;

interface ISAStrategy {
  function invest(
    uint256 poolId,
    uint256 amount,
    bytes memory data
  ) external;

  function redeem(uint256 poolId, bytes memory data)
    external
    returns (bool pendingAdditionalWithdraw, uint256 amount);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.3;

import "@openzeppelin/contracts/utils/Arrays.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title Helper functions
 */
library OLib {
  using Arrays for uint256[];

  // State transition per Vault. Just linear transitions.
  enum State {Inactive, Deposit, Live, Withdraw}

  // Only supports 2 tranches for now
  enum Tranche {Senior, Junior}

  struct VaultParams {
    address seniorAsset;
    address juniorAsset;
    address strategist;
    address strategy;
    uint256 hurdleRate;
    uint256 startTime;
    uint256 enrollment;
    uint256 duration;
    string seniorName;
    string seniorSym;
    string juniorName;
    string juniorSym;
    uint256 seniorTrancheCap;
    uint256 seniorUserCap;
    uint256 juniorTrancheCap;
    uint256 juniorUserCap;
  }

  struct RolloverParams {
    address strategist;
    string seniorName;
    string seniorSym;
    string juniorName;
    string juniorSym;
  }

  bytes32 public constant GOVERNANCE_ROLE = keccak256("GOVERNANCE_ROLE");
  bytes32 public constant PANIC_ROLE = keccak256("PANIC_ROLE");
  bytes32 public constant GUARDIAN_ROLE = keccak256("GUARDIAN_ROLE");
  bytes32 public constant DEPLOYER_ROLE = keccak256("DEPLOYER_ROLE");
  bytes32 public constant CREATOR_ROLE = keccak256("CREATOR_ROLE");
  bytes32 public constant STRATEGIST_ROLE = keccak256("STRATEGIST_ROLE");
  bytes32 public constant VAULT_ROLE = keccak256("VAULT_ROLE");
  bytes32 public constant ROLLOVER_ROLE = keccak256("ROLLOVER_ROLE");
  bytes32 public constant STRATEGY_ROLE = keccak256("STRATEGY_ROLE");

  // Both sums are running sums. If a user deposits [$1, $5, $3], then
  // userSums would be [$1, $6, $9]. You can figure out the deposit
  // amount be subtracting userSums[i]-userSum[i-1].

  // prefixSums is the total deposited for all investors + this
  // investors deposit at the time this deposit is made. So at
  // prefixSum[0], it would be $1 + totalDeposits, where totalDeposits
  // could be $1000 because other investors have put in money.
  struct Investor {
    uint256[] userSums;
    uint256[] prefixSums;
    bool claimed;
    bool withdrawn;
  }

  /**
   * @dev Given the total amount invested by the Vault, we want to find
   *   out how many of this investor's deposits were actually
   *   used. Use findUpperBound on the prefixSum to find the point
   *   where total deposits were accepted. For example, if $2000 was
   *   deposited by all investors and $1000 was invested, then some
   *   position in the prefixSum splits the array into deposits that
   *   got in, and deposits that didn't get in. That same position
   *   maps to userSums. This is the user's deposits that got
   *   in. Since we are keeping track of the sums, we know at that
   *   position the total deposits for a user was $15, even if it was
   *   15 $1 deposits. And we know the amount that didn't get in is
   *   the last value in userSum - the amount that got it.

   * @param investor A specific investor
   * @param invested The total amount invested by this Vault
   */
  function getInvestedAndExcess(Investor storage investor, uint256 invested)
    internal
    view
    returns (uint256 userInvested, uint256 excess)
  {
    uint256[] storage prefixSums_ = investor.prefixSums;
    uint256 length = prefixSums_.length;
    if (length == 0) {
      // There were no deposits. Return 0, 0.
      return (userInvested, excess);
    }
    uint256 leastUpperBound = prefixSums_.findUpperBound(invested);
    if (length == leastUpperBound) {
      // All deposits got in, no excess. Return total deposits, 0
      userInvested = investor.userSums[length - 1];
      return (userInvested, excess);
    }
    uint256 prefixSum = prefixSums_[leastUpperBound];
    if (prefixSum == invested) {
      // Not all deposits got in, but there are no partial deposits
      userInvested = investor.userSums[leastUpperBound];
      excess = investor.userSums[length - 1] - userInvested;
    } else {
      // Let's say some of my deposits got in. The last deposit,
      // however, was $100 and only $30 got in. Need to split that
      // deposit so $30 got in, $70 is excess.
      userInvested = leastUpperBound > 0
        ? investor.userSums[leastUpperBound - 1]
        : 0;
      uint256 depositAmount = investor.userSums[leastUpperBound] - userInvested;
      if (prefixSum - depositAmount < invested) {
        userInvested += (depositAmount + invested - prefixSum);
        excess = investor.userSums[length - 1] - userInvested;
      } else {
        excess = investor.userSums[length - 1] - userInvested;
      }
    }
  }

  /*
   Used to avoid phantom overflow issues that can arise during this calculation:
   @notice Calculates floor(x*y÷denominator) with full precision.
   @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv.
   @dec Credit to prb-math for refactoring for solidity ^0.8 https://github.com/paulrberg/prb-math/blob/main/contracts/PRBMath.sol
  */
  function safeMulDiv(
    uint256 x,
    uint256 y,
    uint256 denominator
  ) internal pure returns (uint256 result) {
    // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
    // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
    // variables such that product = prod1 * 2^256 + prod0.
    uint256 prod0; // Least significant 256 bits of the product
    uint256 prod1; // Most significant 256 bits of the product
    assembly {
      let mm := mulmod(x, y, not(0))
      prod0 := mul(x, y)
      prod1 := sub(sub(mm, prod0), lt(mm, prod0))
    }
    // Handle non-overflow cases, 256 by 256 division.
    if (prod1 == 0) {
      unchecked {
        result = prod0 / denominator;
      }
      return result;
    }
    // Make sure the result is less than 2^256. Also prevents denominator == 0.
    if (prod1 >= denominator) {
      revert("OLib__MulDivOverflow(prod1, denominator)");
    }
    ///////////////////////////////////////////////
    // 512 by 256 division.
    ///////////////////////////////////////////////
    // Make division exact by subtracting the remainder from [prod1 prod0].
    uint256 remainder;
    assembly {
      // Compute remainder using mulmod.
      remainder := mulmod(x, y, denominator)
      // Subtract 256 bit number from 512 bit number.
      prod1 := sub(prod1, gt(remainder, prod0))
      prod0 := sub(prod0, remainder)
    }
    // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
    // See https://cs.stackexchange.com/q/138556/92363.
    unchecked {
      // Does not overflow because the denominator cannot be zero at this stage in the function.
      uint256 lpotdod = denominator & (~denominator + 1);
      assembly {
        // Divide denominator by lpotdod.
        denominator := div(denominator, lpotdod)
        // Divide [prod1 prod0] by lpotdod.
        prod0 := div(prod0, lpotdod)
        // Flip lpotdod such that it is 2^256 / lpotdod. If lpotdod is zero, then it becomes one.
        lpotdod := add(div(sub(0, lpotdod), lpotdod), 1)
      }
      // Shift in bits from prod1 into prod0.
      prod0 |= prod1 * lpotdod;
      // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
      // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
      // four bits. That is, denominator * inv = 1 mod 2^4.
      uint256 inverse = (3 * denominator) ^ 2;
      // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel’s lifting lemma, this also works
      // in modular arithmetic, doubling the correct bits in each step.
      inverse *= 2 - denominator * inverse; // inverse mod 2^8
      inverse *= 2 - denominator * inverse; // inverse mod 2^16
      inverse *= 2 - denominator * inverse; // inverse mod 2^32
      inverse *= 2 - denominator * inverse; // inverse mod 2^64
      inverse *= 2 - denominator * inverse; // inverse mod 2^128
      inverse *= 2 - denominator * inverse; // inverse mod 2^256
      // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
      // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
      // less than 2^256, this is the final result. We don’t need to compute the high bits of the result and prod1
      // is no longer required.
      result = prod0 * inverse;
      return result;
    }
  }
}

/**
 * @title Subset of SafeERC20 from openZeppelin
 *
 * @dev Some non-standard ERC20 contracts (e.g. Tether) break
 * `approve` by forcing it to behave like `safeApprove`. This means
 * `safeIncreaseAllowance` will fail when it tries to adjust the
 * allowance. The code below simply adds an extra call to
 * `approve(spender, 0)`.
 */
library OndoSaferERC20 {
  using SafeERC20 for IERC20;

  function ondoSafeIncreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    uint256 newAllowance = token.allowance(address(this), spender) + value;
    token.safeApprove(spender, 0);
    token.safeApprove(spender, newAllowance);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.3;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "contracts/interfaces/IRegistry.sol";
import "contracts/libraries/OndoLibrary.sol";

abstract contract OndoRegistryClientInitializable is
  Initializable,
  ReentrancyGuard,
  Pausable
{
  using SafeERC20 for IERC20;

  IRegistry public registry;
  uint256 public denominator;

  function __OndoRegistryClient__initialize(address _registry)
    internal
    initializer
  {
    require(_registry != address(0), "Invalid registry address");
    registry = IRegistry(_registry);
    denominator = registry.denominator();
  }

  /**
   * @notice General ACL checker
   * @param _role Role as defined in OndoLibrary
   */
  modifier isAuthorized(bytes32 _role) {
    require(registry.authorized(_role, msg.sender), "Unauthorized");
    _;
  }

  /*
   * @notice Helper to expose a Pausable interface to tools
   */
  function paused() public view virtual override returns (bool) {
    return registry.paused() || super.paused();
  }

  function pause() external virtual isAuthorized(OLib.PANIC_ROLE) {
    super._pause();
  }

  function unpause() external virtual isAuthorized(OLib.GUARDIAN_ROLE) {
    super._unpause();
  }

  /**
   * @notice Grab tokens and send to caller
   * @dev If the _amount[i] is 0, then transfer all the tokens
   * @param _tokens List of tokens
   * @param _amounts Amount of each token to send
   */
  function _rescueTokens(address[] calldata _tokens, uint256[] memory _amounts)
    internal
    virtual
  {
    for (uint256 i = 0; i < _tokens.length; i++) {
      uint256 amount = _amounts[i];
      if (amount == 0) {
        amount = IERC20(_tokens[i]).balanceOf(address(this));
      }
      IERC20(_tokens[i]).safeTransfer(msg.sender, amount);
    }
  }

  function rescueTokens(address[] calldata _tokens, uint256[] memory _amounts)
    public
    whenPaused
    isAuthorized(OLib.GUARDIAN_ROLE)
  {
    require(_tokens.length == _amounts.length, "Invalid array sizes");
    _rescueTokens(_tokens, _amounts);
  }
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
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
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
    constructor () {
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

// SPDX-License-Identifier: MIT

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

    constructor () {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.3;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "contracts/interfaces/IWETH.sol";

/**
 * @title Global values used by many contracts
 * @notice This is mostly used for access control
 */
interface IRegistry is IAccessControl {
  function paused() external view returns (bool);

  function pause() external;

  function unpause() external;

  function enableFeatureFlag(bytes32 _featureFlag) external;

  function disableFeatureFlag(bytes32 _featureFlag) external;

  function getFeatureFlag(bytes32 _featureFlag) external view returns (bool);

  function denominator() external view returns (uint256);

  function weth() external view returns (IWETH);

  function authorized(bytes32 _role, address _account)
    external
    view
    returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    function hasRole(bytes32 role, address account) external view returns (bool);
    function getRoleAdmin(bytes32 role) external view returns (bytes32);
    function grantRole(bytes32 role, address account) external;
    function revokeRole(bytes32 role, address account) external;
    function renounceRole(bytes32 role, address account) external;
}

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping (address => bool) members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override {
        require(hasRole(getRoleAdmin(role), _msgSender()), "AccessControl: sender must be an admin to grant");

        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override {
        require(hasRole(getRoleAdmin(role), _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.3;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWETH is IERC20 {
  function deposit() external payable;

  function withdraw(uint256 wad) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev Collection of functions related to array types.
 */
library Arrays {
   /**
     * @dev Searches a sorted `array` and returns the first index that contains
     * a value greater or equal to `element`. If no such index exists (i.e. all
     * values in the array are strictly less than `element`), the array length is
     * returned. Time complexity O(log n).
     *
     * `array` is expected to be sorted in ascending order, and to contain no
     * repeated elements.
     */
    function findUpperBound(uint256[] storage array, uint256 element) internal view returns (uint256) {
        if (array.length == 0) {
            return 0;
        }

        uint256 low = 0;
        uint256 high = array.length;

        while (low < high) {
            uint256 mid = Math.average(low, high);

            // Note that mid will always be strictly less than high (i.e. it will be a valid array index)
            // because Math.average rounds down (it does integer division with truncation).
            if (array[mid] > element) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        // At this point `low` is the exclusive upper bound. We will return the inclusive upper bound.
        if (low > 0 && array[low - 1] == element) {
            return low - 1;
        } else {
            return low;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

/**SPDX-License-Identifier: AGPL-3.0

          ▄▄█████████▄                                                                  
       ╓██▀└ ,╓▄▄▄, '▀██▄                                                               
      ██▀ ▄██▀▀╙╙▀▀██▄ └██µ           ,,       ,,      ,     ,,,            ,,,         
     ██ ,██¬ ▄████▄  ▀█▄ ╙█▄      ▄███▀▀███▄   ███▄    ██  ███▀▀▀███▄    ▄███▀▀███,     
    ██  ██ ╒█▀'   ╙█▌ ╙█▌ ██     ▐██      ███  █████,  ██  ██▌    └██▌  ██▌     └██▌    
    ██ ▐█▌ ██      ╟█  █▌ ╟█     ██▌      ▐██  ██ └███ ██  ██▌     ╟██ j██       ╟██    
    ╟█  ██ ╙██    ▄█▀ ▐█▌ ██     ╙██      ██▌  ██   ╙████  ██▌    ▄██▀  ██▌     ,██▀    
     ██ "██, ╙▀▀███████████⌐      ╙████████▀   ██     ╙██  ███████▀▀     ╙███████▀`     
      ██▄ ╙▀██▄▄▄▄▄,,,                ¬─                                    '─¬         
       ╙▀██▄ '╙╙╙▀▀▀▀▀▀▀▀                                                               
          ╙▀▀██████R⌐                                                                   

 */
pragma solidity 0.8.3;

/// @title Multicall interface
/// @notice Enables calling multiple methods in a single call to the contract
interface IMulticall {
  /// @notice External call data structure
  struct ExCallData {
    address target; // The target contract called from the current contract
    bytes data; // The encoded function data
    uint256 value; // The ether to be transfered to the target contract
  }

  /// @notice Call multiple functions in the target contract and return the data from all of them if they all succeed
  /// @dev The `msg.sender` is always the current contract in any method callable from multicall.
  /// @param exdata The external call data for each of the calls to make to this contract
  /// @return results The results from each of the calls passed in via data
  function multiexcall(ExCallData[] calldata exdata)
    external
    payable
    returns (bytes[] memory results);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.3;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface ITrancheToken is IERC20Upgradeable {
  function mint(address _account, uint256 _amount) external;

  function burn(address _account, uint256 _amount) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.3;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "contracts/libraries/OndoLibrary.sol";
import "contracts/interfaces/IPairVault.sol";

interface IStrategy {
  // Additional info stored for each Vault
  struct Vault {
    IPairVault origin; // who created this Vault
    IERC20 pool; // the DEX pool
    IERC20 senior; // senior asset in pool
    IERC20 junior; // junior asset in pool
    uint256 shares; // number of shares for ETF-style mid-duration entry/exit
    uint256 seniorExcess; // unused senior deposits
    uint256 juniorExcess; // unused junior deposits
  }

  function vaults(uint256 vaultId)
    external
    view
    returns (
      IPairVault origin,
      IERC20 pool,
      IERC20 senior,
      IERC20 junior,
      uint256 shares,
      uint256 seniorExcess,
      uint256 juniorExcess
    );

  function addVault(
    uint256 _vaultId,
    IERC20 _senior,
    IERC20 _junior
  ) external;

  function addLp(uint256 _vaultId, uint256 _lpTokens) external;

  function removeLp(
    uint256 _vaultId,
    uint256 _shares,
    address to
  ) external;

  function getVaultInfo(uint256 _vaultId)
    external
    view
    returns (IERC20, uint256);

  function invest(
    uint256 _vaultId,
    uint256 _totalSenior,
    uint256 _totalJunior,
    uint256 _extraSenior,
    uint256 _extraJunior,
    uint256 _seniorMinOut,
    uint256 _juniorMinOut
  ) external returns (uint256 seniorInvested, uint256 juniorInvested);

  function sharesFromLp(uint256 vaultId, uint256 lpTokens)
    external
    view
    returns (
      uint256 shares,
      uint256 vaultShares,
      IERC20 pool
    );

  function lpFromShares(uint256 vaultId, uint256 shares)
    external
    view
    returns (uint256 lpTokens, uint256 vaultShares);

  function redeem(
    uint256 _vaultId,
    uint256 _seniorExpected,
    uint256 _seniorMinOut,
    uint256 _juniorMinOut
  ) external returns (uint256, uint256);

  function withdrawExcess(
    uint256 _vaultId,
    OLib.Tranche tranche,
    address to,
    uint256 amount
  ) external;
}

// SPDX-License-Identifier: MIT

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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