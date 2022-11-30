// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./BaseBondDepository.sol";

import "./interfaces/ITreasuryBondDepository.sol";
import "./interfaces/IBondGovernor.sol";
import "./interfaces/ITreasury.sol";

/// @title TreasuryBondDepository
/// @author Bluejay Core Team
/// @notice TreasuryBondDepository allows the protocol to raise funds into the Treasury by selling bonds.
/// These bonds allow users to claim governance token vested over a period of time.
/// The bonds are priced based on outstanding debt ratio and a bond control variable.
/// @dev This contract is only suitable for assets with 18 decimals.
contract TreasuryBondDepository is
  Ownable,
  BaseBondDepository,
  ITreasuryBondDepository
{
  using SafeERC20 for IERC20;

  uint256 private constant WAD = 10**18;
  uint256 private constant RAY = 10**27;
  uint256 private constant RAD = 10**45;

  /// @notice Contract address of the BLU Token
  IERC20 public immutable BLU;

  /// @notice Contract address of the asset used to pay for the bonds
  IERC20 public immutable override reserve;

  /// @notice Contract address of the Treasury where the reserve assets are sent and BLU minted
  ITreasury public immutable treasury;

  /// @notice Vesting period of bonds, in seconds
  uint256 public immutable vestingPeriod;

  /// @notice Contract address of the BondGovernor where bond parameters are defined
  IBondGovernor public bondGovernor;

  /// @notice Address where fees collected from bond sales are sent
  address public feeCollector;

  /// @notice Flag to pause purchase of bonds
  bool public isPurchasePaused;

  /// @notice Flag to pause redemption of bonds
  bool public isRedeemPaused;

  /// @notice Governance token debt outstanding, decaying over the vesting period, in WAD
  uint256 public totalDebt;

  /// @notice Timestamp of last debt decay, in unix timestamp
  uint256 public lastDecay;

  /// @notice Constructor to initialize the contract
  /// @dev Bond parameters should be initialized in the bond governor.
  /// @param _bondGovernor Address of bond governor which defines bond parameters
  /// @param _reserve Address of the asset accepted for payment of the bonds
  /// @param _BLU Address of the BLU token
  /// @param _treasury Address of the Treasury for minting BLU tokens and storing proceeds
  /// @param _feeCollector Address to send fees collected from bond sales
  /// @param _vestingPeriod Vesting period of bonds, in seconds
  constructor(
    address _bondGovernor,
    address _reserve,
    address _BLU,
    address _treasury,
    address _feeCollector,
    uint256 _vestingPeriod
  ) {
    bondGovernor = IBondGovernor(_bondGovernor);
    reserve = IERC20(_reserve);
    BLU = IERC20(_BLU);
    treasury = ITreasury(_treasury);
    feeCollector = _feeCollector;
    vestingPeriod = _vestingPeriod;
    isPurchasePaused = true;
  }

  // =============================== INTERNAL FUNCTIONS =================================

  /// @notice Decrease total debt by removing amount of debt decayed during the period elapsed
  function _decayDebt() internal {
    totalDebt = totalDebt - debtDecay();
    lastDecay = block.timestamp;
  }

  // =============================== PUBLIC FUNCTIONS =================================

  /// @notice Purchase treasury bond paid with reserve assets
  /// @dev Approval of reserve asset to this address is required
  /// @param amount Amount of reserve asset to spend, in WAD
  /// @param maxPrice Maximum price to pay for the bond to prevent slippages, in WAD
  /// @param recipient Address to issue the bond to
  /// @return bondId ID of bond that was issued
  function purchase(
    uint256 amount,
    uint256 maxPrice,
    address recipient
  ) public override returns (uint256 bondId) {
    require(!isPurchasePaused, "Purchase paused");
    (
      uint256 controlVariable,
      uint256 minimumPrice,
      uint256 minimumSize,
      uint256 maximumSize,
      uint256 fees
    ) = bondGovernor.getPolicy(address(reserve));
    require(recipient != address(0), "Invalid address");

    _decayDebt();

    uint256 price = calculateBondPrice(
      controlVariable,
      minimumPrice,
      debtRatio()
    );
    require(price <= maxPrice, "Price too high");

    uint256 payout = (amount * WAD) / price;
    require(payout >= minimumSize, "Bond size too small");
    require(payout <= maximumSize, "Bond size too big");

    uint256 feeCollected = (amount * fees) / price;
    reserve.safeTransferFrom(msg.sender, address(treasury), amount);
    treasury.mint(address(this), payout + feeCollected);

    if (feeCollected > 0) {
      BLU.safeTransfer(feeCollector, feeCollected);
    }

    bondId = _mint(recipient, payout, vestingPeriod);
    totalDebt += payout;

    emit BondPurchased(bondId, recipient, amount, payout, price);
  }

  /// @notice Redeem BLU tokens from previously purchased bond.
  /// BLU is linearly vested over the vesting period and user can redeem vested tokens at any time.
  /// @dev Bond will be deleted after the bond is fully vested and redeemed
  /// @param bondId ID of bond to redeem, caller must the bond owner
  /// @param recipient Address to send vested BLU tokens to
  /// @return payout Amount of BLU tokens sent to recipient, in WAD
  /// @return principal Amount of BLU tokens left to be vested on the bond, in WAD
  function redeem(uint256 bondId, address recipient)
    public
    override
    returns (uint256 payout, uint256 principal)
  {
    require(!isRedeemPaused, "Redeem paused");
    require(bondOwners[bondId] == msg.sender, "Not bond owner");
    Bond memory bond = bonds[bondId];
    if (bond.lastRedeemed + bond.vestingPeriod <= block.timestamp) {
      _burn(bondId);
      payout = bond.principal;
      BLU.safeTransfer(recipient, bond.principal);
      emit BondRedeemed(bondId, recipient, true, payout, 0);
    } else {
      payout =
        (bond.principal * (block.timestamp - bond.lastRedeemed)) /
        bond.vestingPeriod;
      principal = bond.principal - payout;
      bonds[bondId] = Bond({
        principal: principal,
        vestingPeriod: bond.vestingPeriod -
          (block.timestamp - bond.lastRedeemed),
        purchased: bond.purchased,
        lastRedeemed: block.timestamp
      });
      BLU.safeTransfer(recipient, payout);
      emit BondRedeemed(bondId, recipient, false, payout, principal);
    }
  }

  // =============================== ADMIN FUNCTIONS =================================

  /// @notice Set the address where fees are sent to
  /// @param _feeCollector Address of fee collector
  function setFeeCollector(address _feeCollector) public override onlyOwner {
    feeCollector = _feeCollector;
    emit UpdatedFeeCollector(_feeCollector);
  }

  /// @notice Pause or unpause redemption of bonds
  /// @param pause True to pause redemption, false to unpause redemption
  function setIsRedeemPaused(bool pause) public override onlyOwner {
    isRedeemPaused = pause;
    emit RedeemPaused(pause);
  }

  /// @notice Pause or unpause purchase of bonds
  /// @param pause True to pause purchase, false to unpause purchase
  function setIsPurchasePaused(bool pause) public override onlyOwner {
    isPurchasePaused = pause;
    emit PurchasePaused(pause);
  }

  // =============================== VIEW FUNCTIONS =================================

  /// @notice Calculate current debt after debt decay
  /// @return debt Amount of current debt, in WAD
  function currentDebt() public view override returns (uint256 debt) {
    debt = totalDebt - debtDecay();
  }

  /// @notice Calculate amount of debt decayed during the period elapsed
  /// @return decay Amount of debt to decay by, in WAD
  function debtDecay() public view override returns (uint256 decay) {
    uint256 timeSinceLast = block.timestamp - lastDecay;
    decay = (totalDebt * timeSinceLast) / vestingPeriod;
    if (decay > totalDebt) {
      decay = totalDebt;
    }
  }

  /// @notice Calculate ratio of debt against the total supply of BLU tokens
  /// @return ratio Debt ratio, in WAD
  function debtRatio() public view override returns (uint256 ratio) {
    ratio = (currentDebt() * WAD) / BLU.totalSupply();
  }

  /// @notice Calculate current price of bond
  /// @return price Price of bond, in WAD
  function bondPrice() public view override returns (uint256 price) {
    (uint256 controlVariable, uint256 minimumPrice, , , ) = bondGovernor
      .getPolicy(address(reserve));
    return calculateBondPrice(controlVariable, minimumPrice, debtRatio());
  }

  /// @notice Calculate price of bond using the control variable, debt ratio and min price
  /// @param controlVariable Control variable of bond, in RAY
  /// @param minimumPrice Minimum price of bond, in WAD
  /// @param ratio Debt ratio, in WAD
  /// @return price Price of bond, in WAD
  function calculateBondPrice(
    uint256 controlVariable,
    uint256 minimumPrice,
    uint256 ratio
  ) public pure override returns (uint256 price) {
    price = (controlVariable * ratio + RAD) / RAY;
    if (price < minimumPrice) {
      price = minimumPrice;
    }
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

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
pragma solidity ^0.8.4;

import "./interfaces/IBaseBondDepository.sol";

/// @title BaseBondDepository
/// @author Bluejay Core Team
/// @notice BaseBondDepository provides logic for minting, burning and storing bond info.
/// The contract is to be inherited by treasury bond depository and stabilizing bond depository.
abstract contract BaseBondDepository is IBaseBondDepository {
  /// @notice Number of bonds minted, monotonic increasing from 0
  uint256 public bondsCount;

  /// @notice Map of bond ID to the bond information
  mapping(uint256 => Bond) public override bonds;

  /// @notice Map of bond ID to the address of the bond owner
  mapping(uint256 => address) public bondOwners;

  /// @notice Map of bond owner address to array of bonds owned
  mapping(address => uint256[]) public ownedBonds;

  /// @notice Map of bond owner and bond ID to the index location of `ownedBonds`
  mapping(address => mapping(uint256 => uint256)) public ownedBondsIndex;

  // =============================== INTERNAL FUNCTIONS =================================

  /// @notice Internal function for child contract to mint a bond with fixed vesting period to an address
  /// @param to Address to mint the bond to
  /// @param payout Amount of assets to payout across the entire vesting period
  /// @param vestingPeriod Vesting period of the bond
  function _mint(
    address to,
    uint256 payout,
    uint256 vestingPeriod
  ) internal returns (uint256 bondId) {
    bondId = ++bondsCount;
    bonds[bondId] = Bond({
      principal: payout,
      vestingPeriod: vestingPeriod,
      purchased: block.timestamp,
      lastRedeemed: block.timestamp
    });
    bondOwners[bondId] = to;
    uint256[] storage userBonds = ownedBonds[to];
    ownedBondsIndex[to][bondId] = userBonds.length;
    userBonds.push(bondId);
  }

  /// @notice Internal function for child contract to burn a bond, usually after it fully vest
  /// This recover gas as well as delete the bond from the view functions
  /// @param bondId Bond ID of the bond to burn
  /// @dev Perform required sanity check on the bond before burning it
  function _burn(uint256 bondId) internal {
    address bondOwner = bondOwners[bondId];
    require(bondOwner != address(0), "Invalid bond");
    uint256[] storage userBonds = ownedBonds[bondOwner];
    mapping(uint256 => uint256) storage userBondIndices = ownedBondsIndex[
      bondOwner
    ];
    uint256 lastBondIndex = userBonds.length - 1;
    uint256 bondIndex = userBondIndices[bondId];
    if (bondIndex != lastBondIndex) {
      uint256 lastBondId = userBonds[lastBondIndex];
      userBonds[bondIndex] = lastBondId;
      userBondIndices[lastBondId] = bondIndex;
    }
    userBonds.pop();
    delete userBondIndices[bondId];
    delete bonds[bondId];
    delete bondOwners[bondId];
  }

  // =============================== INTERNAL FUNCTIONS =================================

  /// @notice List all bond IDs owned by an address
  /// @param owner Address of the owner of the bonds
  /// @return bondIds List of bond IDs owned by the address
  function listBondIds(address owner)
    public
    view
    override
    returns (uint256[] memory bondIds)
  {
    bondIds = ownedBonds[owner];
  }

  /// @notice List all bond info owned by an address
  /// @param owner Address of the owner of the bonds
  /// @return Bond List of bond info owned by the address
  function listBonds(address owner)
    public
    view
    override
    returns (Bond[] memory)
  {
    uint256[] memory bondIds = ownedBonds[owner];
    Bond[] memory bondsOwned = new Bond[](bondIds.length);
    for (uint256 i = 0; i < bondIds.length; i++) {
      bondsOwned[i] = bonds[bondIds[i]];
    }
    return bondsOwned;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IBondDepositoryCommon.sol";

interface ITreasuryBondDepository is IBondDepositoryCommon {
  function purchase(
    uint256 amount,
    uint256 maxPrice,
    address recipient
  ) external returns (uint256 bondId);

  function currentDebt() external view returns (uint256 debt);

  function debtDecay() external view returns (uint256 decay);

  function debtRatio() external view returns (uint256 ratio);

  function setFeeCollector(address dao) external;

  function calculateBondPrice(
    uint256 controlVariable,
    uint256 minimumPrice,
    uint256 ratio
  ) external view returns (uint256 price);

  event UpdatedFeeCollector(address dao);
  event RedeemPaused(bool indexed isPaused);
  event PurchasePaused(bool indexed isPaused);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IBondGovernor {
  struct Policy {
    uint256 controlVariable; // [ray]
    uint256 lastControlVariableUpdate; // [unix timestamp]
    uint256 targetControlVariable; // [ray]
    uint256 timeToTargetControlVariable; // [seconds]
    uint256 minimumPrice; // [wad]
  }

  function initializePolicy(
    address asset,
    uint256 controlVariable,
    uint256 minimumPrice
  ) external;

  function adjustPolicy(
    address asset,
    uint256 targetControlVariable,
    uint256 timeToTargetControlVariable,
    uint256 minimumPrice
  ) external;

  function updateControlVariable(address asset) external;

  function setFees(uint256 _fees) external;

  function setMinimumSize(uint256 _minimumSize) external;

  function setMaximumRatio(uint256 _maximumRatio) external;

  function getControlVariable(address asset)
    external
    view
    returns (uint256 controlVariable);

  function maximumBondSize() external view returns (uint256 maxBondSize);

  function getPolicy(address asset)
    external
    view
    returns (
      uint256 currentControlVariable,
      uint256 minPrice,
      uint256 minSize,
      uint256 maxBondSize,
      uint256 fees
    );

  event UpdatedFees(uint256 fees);
  event UpdatedMinimumSize(uint256 fees);
  event UpdatedMaximumRatio(uint256 fees);
  event CreatedPolicy(
    address indexed asset,
    uint256 controlVariable,
    uint256 minPrice
  );
  event UpdatedPolicy(
    address indexed asset,
    uint256 targetControlVariable,
    uint256 minPrice,
    uint256 timeToTargetControlVariable
  );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ITreasury {
  function mint(address to, uint256 amount) external;

  function withdraw(
    address token,
    address to,
    uint256 amount
  ) external;

  function increaseMintLimit(address minter, uint256 amount) external;

  function decreaseMintLimit(address minter, uint256 amount) external;

  function increaseWithdrawalLimit(
    address asset,
    address spender,
    uint256 amount
  ) external;

  function decreaseWithdrawalLimit(
    address asset,
    address spender,
    uint256 amount
  ) external;

  event Mint(address indexed to, uint256 amount);
  event Withdraw(address indexed token, address indexed to, uint256 amount);
  event MintLimitUpdate(address indexed minter, uint256 amount);
  event WithdrawLimitUpdate(
    address indexed token,
    address indexed minter,
    uint256 amount
  );
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address sender,
        address recipient,
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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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
        assembly {
            size := extcodesize(account)
        }
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
pragma solidity ^0.8.4;

interface IBaseBondDepository {
  struct Bond {
    uint256 principal; // [wad]
    uint256 vestingPeriod; // [seconds]
    uint256 purchased; // [unix timestamp]
    uint256 lastRedeemed; // [unix timestamp]
  }

  function bonds(uint256 _id)
    external
    view
    returns (
      uint256 principal,
      uint256 vestingPeriod,
      uint256 purchased,
      uint256 lastRedeemed
    );

  function listBondIds(address owner)
    external
    view
    returns (uint256[] memory bondIds);

  function listBonds(address owner) external view returns (Bond[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "./IBaseBondDepository.sol";

interface IBondDepositoryCommon is IBaseBondDepository {
  function reserve() external view returns (IERC20);

  function bondPrice() external view returns (uint256 price);

  function redeem(uint256 bondId, address recipient)
    external
    returns (uint256 payout, uint256 principal);

  function setIsRedeemPaused(bool pause) external;

  function setIsPurchasePaused(bool pause) external;

  event BondPurchased(
    uint256 indexed bondId,
    address indexed recipient,
    uint256 amount,
    uint256 principal,
    uint256 price
  );
  event BondRedeemed(
    uint256 indexed bondId,
    address indexed recipient,
    bool indexed fullyRedeemed,
    uint256 payout,
    uint256 principal
  );
}