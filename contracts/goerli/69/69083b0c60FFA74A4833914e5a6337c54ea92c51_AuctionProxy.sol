// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "../interfaces/ClipperLike.sol";
import "../interfaces/GemJoinLike.sol";
import "../interfaces/DavosJoinLike.sol";
import "../interfaces/DogLike.sol";
import "../interfaces/VatLike.sol";
import "../ceros/interfaces/IDavosProvider.sol";
import "../oracle/libraries/FullMath.sol";

import { CollateralType } from  "../ceros/interfaces/IDao.sol";

uint256 constant RAY = 10**27;

library AuctionProxy {
  using SafeERC20Upgradeable for IERC20Upgradeable;
  using SafeERC20Upgradeable for GemLike;

  function startAuction(
    address user,
    address keeper,
    IERC20Upgradeable davos,
    DavosJoinLike davosJoin,
    VatLike vat,
    DogLike dog,
    IDavosProvider davosProvider,
    CollateralType calldata collateral
  ) public returns (uint256 id) {
    ClipperLike _clip = ClipperLike(collateral.clip);
    _clip.upchost();
    uint256 davosBal = davos.balanceOf(address(this));
    id = dog.bark(collateral.ilk, user, address(this));

    davosJoin.exit(address(this), vat.davos(address(this)) / RAY);
    davosBal = davos.balanceOf(address(this)) - davosBal;
    davos.transfer(keeper, davosBal);

    // Burn any derivative token (dMATIC incase of ceaMATICc collateral)
    if (address(davosProvider) != address(0)) {
      davosProvider.daoBurn(user, _clip.sales(id).lot);
    }
  }

  function resetAuction(
    uint auctionId,
    address keeper,
    IERC20Upgradeable davos,
    DavosJoinLike davosJoin,
    VatLike vat,
    CollateralType calldata collateral
  ) public {
    ClipperLike _clip = ClipperLike(collateral.clip);
    uint256 davosBal = davos.balanceOf(address(this));
    _clip.redo(auctionId, keeper);


    davosJoin.exit(address(this), vat.davos(address(this)) / RAY);
    davosBal = davos.balanceOf(address(this)) - davosBal;
    davos.transfer(keeper, davosBal);
  }

  // Returns lefover from auction
  function buyFromAuction(
    uint256 auctionId,
    uint256 collateralAmount,
    uint256 maxPrice,
    address receiverAddress,
    IERC20Upgradeable davos,
    DavosJoinLike davosJoin,
    VatLike vat,
    IDavosProvider davosProvider,
    CollateralType calldata collateral
  ) public returns (uint256 leftover) {
    // Balances before
    uint256 davosBal = davos.balanceOf(address(this));
    uint256 gemBal = collateral.gem.gem().balanceOf(address(this));

    uint256 davosMaxAmount = FullMath.mulDiv(maxPrice, collateralAmount, RAY);

    davos.transferFrom(msg.sender, address(this), davosMaxAmount);
    davosJoin.join(address(this), davosMaxAmount);

    vat.hope(address(collateral.clip));
    address urn = ClipperLike(collateral.clip).sales(auctionId).usr; // Liquidated address

    leftover = vat.gem(collateral.ilk, urn); // userGemBalanceBefore
    ClipperLike(collateral.clip).take(auctionId, collateralAmount, maxPrice, address(this), "");
    leftover = vat.gem(collateral.ilk, urn) - leftover; // leftover

    collateral.gem.exit(address(this), vat.gem(collateral.ilk, address(this)));
    davosJoin.exit(address(this), vat.davos(address(this)) / RAY);

    // Balances rest
    davosBal = davos.balanceOf(address(this)) - davosBal;
    gemBal = collateral.gem.gem().balanceOf(address(this)) - gemBal;
    davos.transfer(receiverAddress, davosBal);

    vat.nope(address(collateral.clip));

    if (address(davosProvider) != address(0)) {
      IERC20Upgradeable(collateral.gem.gem()).safeTransfer(address(davosProvider), gemBal);
      davosProvider.liquidation(receiverAddress, gemBal); // Burn router ceToken and mint amaticc to receiver

      if (leftover != 0) {
        // Auction ended with leftover
        vat.flux(collateral.ilk, urn, address(this), leftover);
        collateral.gem.exit(address(davosProvider), leftover); // Router (disc) gets the remaining ceamaticc
        davosProvider.liquidation(urn, leftover); // Router burns them and gives amaticc remaining
      }
    } else {
      IERC20Upgradeable(collateral.gem.gem()).safeTransfer(receiverAddress, gemBal);
    }
  }

  function getAllActiveAuctionsForClip(ClipperLike clip)
    external
    view
    returns (Sale[] memory sales)
  {
    uint256[] memory auctionIds = clip.list();
    uint256 auctionsCount = auctionIds.length;
    sales = new Sale[](auctionsCount);
    for (uint256 i = 0; i < auctionsCount; i++) {
      sales[i] = clip.sales(auctionIds[i]);
    }
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
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

    function safePermit(
        IERC20PermitUpgradeable token,
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
pragma solidity ^0.8.10;

struct Sale {
    uint256 pos; // Index in active array
    uint256 tab; // Davos to raise       [rad]
    uint256 lot; // collateral to sell [wad]
    address usr; // Liquidated CDP
    uint96 tic; // Auction start time
    uint256 top; // Starting price     [ray]
}

interface ClipperLike {
    function ilk() external view returns (bytes32);

    function kick(
        uint256 tab,
        uint256 lot,
        address usr,
        address kpr
    ) external returns (uint256);

    function take(
        uint256 id,
        uint256 amt,
        uint256 max,
        address who,
        bytes calldata data
    ) external;

    function redo(uint256 id, address kpr) external;

    function upchost() external;

    function getStatus(uint256 id) external view returns (bool, uint256, uint256, uint256);

    function kicks() external view returns (uint256);

    function count() external view returns (uint256);

    function list() external view returns (uint256[] memory);

    function sales(uint256 auctionId) external view returns (Sale memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./GemLike.sol";

interface GemJoinLike {
    function join(address usr, uint256 wad) external;

    function exit(address usr, uint256 wad) external;

    function gem() external view returns (GemLike);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface DavosJoinLike {
    function join(address usr, uint256 wad) external;

    function exit(address usr, uint256 wad) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface DogLike {

       // --- Administration ---
    function file(bytes32 what, address data) external;
    function file(bytes32 what, uint256 data) external;
    function file(bytes32 ilk, bytes32 what, uint256 data) external;
    function file(bytes32 ilk, bytes32 what, address clip) external;

    function chop(bytes32 ilk) external view returns (uint256);

    // --- CDP Liquidation: all bark and no bite ---
    //
    // Liquidate a Vault and start a Dutch auction to sell its collateral for DAVOS.
    //
    // The third argument is the address that will receive the liquidation reward, if any.
    //
    // The entire Vault will be liquidated except when the target amount of DAVOS to be raised in
    // the resulting auction (debt of Vault + liquidation penalty) causes either Dirt to exceed
    // Hole or ilk.dirt to exceed ilk.hole by an economically significant amount. In that
    // case, a partial liquidation is performed to respect the global and per-ilk limits on
    // outstanding DAVOS target. The one exception is if the resulting auction would likely
    // have too little collateral to be interesting to Keepers (debt taken from Vault < ilk.dust),
    // in which case the function reverts. Please refer to the code and comments within if
    // more detail is desired.
    function bark(bytes32 ilk, address urn, address kpr) external returns (uint256 id);

    function digs(bytes32 ilk, uint256 rad) external;

    function cage() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface VatLike {
    function init(bytes32 ilk) external;

    function hope(address usr) external;

    function nope(address usr) external;

    function rely(address usr) external;

    function deny(address usr) external;

    function move(address src, address dst, uint256 rad) external;

    function behalf(address bit, address usr) external;

    function frob(bytes32 i, address u, address v, address w, int dink, int dart) external;

    function flux(bytes32 ilk, address src, address dst, uint256 wad) external;

    function ilks(bytes32) external view returns (uint256, uint256, uint256, uint256, uint256);

    function fold(bytes32 i, address u, int rate) external;

    function gem(bytes32, address) external view returns (uint256);

    function davos(address) external view returns (uint256);

    function urns(bytes32, address) external view returns (uint256, uint256);

    function file(bytes32, bytes32, uint) external;

    function sin(address) external view returns (uint256);

    function heal(uint rad) external;

    function suck(address u, address v, uint rad) external;

    function grab(bytes32,address,address,address,int256,int256) external;

    function slip(bytes32,address,int) external;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

interface IDavosProvider {

    // --- Events ---
    event Deposit(address indexed _account, uint256 _amount);
    event Withdrawal(address indexed _owner, address indexed _recipient, uint256 _amount);
    event File(bytes32 _what, address _data);

    // --- Functions ---
    function provide(uint256 _amount) external returns (uint256);
    function release(address _recipient, uint256 _amount) external returns (uint256);
    function liquidation(address _recipient, uint256 _amount) external;
    function daoBurn(address _account, uint256 _value) external;
    function daoMint(address _account, uint256 _value) external;
}

// SPDX-License-Identifier: CC-BY-4.0
pragma solidity ^0.8.10;

// taken from https://medium.com/coinmonks/math-in-solidity-part-3-percents-and-proportions-4db014e080b1
// license is CC-BY-4.0
library FullMath {
  function fullMul(uint256 x, uint256 y) internal pure returns (uint256 l, uint256 h) {
  unchecked{
    uint256 mm = mulmod(x, y, type(uint256).max);
    l = x * y;
    h = mm - l;
    if (mm < l) h -= 1;
  }
  }

  function fullDiv(
    uint256 l,
    uint256 h,
    uint256 d
  ) private pure returns (uint256) {
  unchecked {
    uint256 pow2 = d & (~d + 1);
    d /= pow2;
    l /= pow2;
    l += h * ((~pow2 + 1) / pow2 + 1);
    uint256 r = 1;
    r *= 2 - d * r;
    r *= 2 - d * r;
    r *= 2 - d * r;
    r *= 2 - d * r;
    r *= 2 - d * r;
    r *= 2 - d * r;
    r *= 2 - d * r;
    r *= 2 - d * r;
    return l * r;
  }
  }

  function mulDiv(
    uint256 x,
    uint256 y,
    uint256 d
  ) internal pure returns (uint256) {
    (uint256 l, uint256 h) = fullMul(x, y);

  unchecked {
    uint256 mm = mulmod(x, y, d);
    if (mm > l) h -= 1;
    l -= mm;

    if (h == 0) return l / d;

    require(h < d, "FullMath: FULLDIV_OVERFLOW");
    return fullDiv(l, h, d);
  }
  }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "../../interfaces/GemJoinLike.sol";

struct CollateralType {
    GemJoinLike gem;
    bytes32 ilk;
    uint32 live; //0 - inactive, 1 - started, 2 - stopped
    address clip;
}

interface IDao {

    event Deposit(address indexed user, address collateral, uint256 amount, uint256 totalAmount);
    event Borrow(address indexed user, address collateral, uint256 collateralAmount, uint256 amount, uint256 liquidationPrice);
    event Payback(address indexed user, address collateral, uint256 amount, uint256 debt, uint256 liquidationPrice);
    event Withdraw(address indexed user, uint256 amount);
    event CollateralEnabled(address token, bytes32 ilk);
    event CollateralDisabled(address token, bytes32 ilk);
    event AuctionStarted(address indexed token, address user, uint256 amount, uint256 price);
    event AuctionFinished(address indexed token, address keeper,  uint256 amount);
    event Liquidation(address indexed user, address indexed collateral, uint256 amount, uint256 leftover);
    event AddedToWhitelist(address indexed user);
    event RemovedFromWhitelist(address indexed user);
    event ChangeRewards(address rewards);
    event ChangeDavosProvider(address davosProvider);

      function deposit(
        address participant,
        address token,
        uint256 dink
    ) external returns (uint256);

    function withdraw(
        address participant,
        address token,
        uint256 dink
    ) external returns (uint256);

    function dropRewards(address token, address usr) external;
    function buyFromAuction(address token, uint256 auctionId, uint256 collateralAmount, uint256 maxPrice, address receiverAddress) external;
    function collaterals(address) external view returns(GemJoinLike gem, bytes32 ilk, uint32 live, address clip);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
interface IERC20PermitUpgradeable {
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
pragma solidity ^0.8.10;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

interface GemLike is IERC20Upgradeable {
    function decimals() external view returns (uint);
}