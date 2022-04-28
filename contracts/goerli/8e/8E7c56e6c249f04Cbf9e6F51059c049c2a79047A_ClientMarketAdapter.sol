// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.2;

import {IERC20PermitUpgradeable as IERC20Permit} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-IERC20PermitUpgradeable.sol";
import {IERC20Upgradeable as IERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeERC20Upgradeable as SafeERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {IERC20MetadataUpgradeable as IERC20Metadata} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

import "../interfaces/IMarket.sol";
import "../interfaces/IBST.sol";
import "../interfaces/IClientMarketAdapter.sol";
import "../interfaces/IWETH9.sol";

/// @notice Stable adapter for market
contract ClientMarketAdapter is IClientMarketAdapter {

    using SafeERC20 for IERC20;

    IERC20 public immutable token; 
    function ASSET_ADDRESS() public view override returns (address) { return address(token); }

    IERC20 public immutable stable;
    function STABLE_ADDRESS() public view override returns (address) { return address(stable); }    
    uint public immutable DIVIDER_STABLE;

    IERC20 public immutable bump;
    IMarket public immutable market;
    IBST public immutable bst;
    IBond public immutable bond;
    constructor (address _stable, address _market, address _bst, address _bond, address _bump) {
        require(_stable != address(0), "CMA-zero-stable" );
        require(_market != address(0), "CMA-zero-market" );
        require(_bst != address(0), "CMA-zero-bst" );
        require(_bond != address(0), "CMA-zero-bond" );
        require(_bump != address(0), "CMA-zero-bump" );

        stable = IERC20(_stable);
        market = IMarket( _market);
        token = IMarket(_market).ASSET();
        bst = IBST(_bst);
        bond = IBond(_bond);
        bump = IERC20(_bump);

        DIVIDER_STABLE = (10**IERC20Metadata(_stable).decimals());
    }

    /// @notice deposit with permit for bonding only
    function depositWithPermitWithAutoBondingPermit(
        uint amount,
        uint16 risk,
        uint16 term,
        bool autorenew,
        uint bumpAmount,
        bytes memory permitStable,
        bytes memory permitBump
    ) external override returns (uint id) {
        _bumpBondPermit(bumpAmount, permitBump);

        (uint deadline, uint8 v, bytes32 r, bytes32 s) = _decodePermit(
            permitStable
        );

        return
            depositWithPermit(amount, risk, term, autorenew, deadline, v, r, s);
    }

    /// @notice deposit with permit for bonding only
    function protectWithPermitWithAutoBondingPermit(
        uint amount,
        uint16 risk,
        uint16 term,
        bool autorenew,
        uint bumpAmount,
        bytes memory permitToken,
        bytes memory permitBump
    ) external override returns (uint id) {
        _bumpBondPermit(bumpAmount, permitBump);

        (uint deadline, uint8 v, bytes32 r, bytes32 s) = _decodePermit(
            permitToken
        );

        return
            protectWithPermit(amount, risk, term, autorenew, deadline, v, r, s);
    }

    /// @notice deposit with permit for bonding only
    function protectWithAutoBondingPermit(
        uint amount,
        uint16 risk,
        uint16 term,
        bool autorenew,
        uint bumpAmount,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override returns (uint id) {
        _bumpBondPermit(bumpAmount, deadline, v, r, s);

        return protect(amount, risk, term, autorenew);
    }

    /// @notice deposit with permit for bonding only
    function depositWithAutoBondingPermit(
        uint amount,
        uint16 risk,
        uint16 term,
        bool autorenew,
        uint bumpAmount,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override returns (uint id) {
        _bumpBondPermit(bumpAmount, deadline, v, r, s);
        return deposit(amount, risk, term, autorenew);
    }

    /// @notice deposit with permit
    function depositWithPermit(
        uint amount,
        uint16 risk,
        uint16 term,
        bool autorenew,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public override returns (uint id) {
        IERC20Permit(address(stable)).permit(
            msg.sender,
            address(this),
            amount,
            deadline,
            v,
            r,
            s
        );
        return deposit(amount, risk, term, autorenew);
    }

    function protectWithPermit(
        uint amount,
        uint16 risk,
        uint16 term,
        bool autorenew,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public override returns (uint id) {
        IERC20Permit(address(token)).permit(
            msg.sender,
            address(this),
            amount,
            deadline,
            v,
            r,
            s
        );
        return protect(amount, risk, term, autorenew);
    }

    /// @notice create new taker position (override with NFT mint)
    function protect(
        uint amount,
        uint16 risk,
        uint16 term,
        bool autorenew
    ) public virtual override returns (uint id) {
        // lock BUMP tokens using Bond contract
        (uint bumpAmount, , uint reduceAmount) = bond.autoLockBondTakerPosition(
            msg.sender,
            amount,
            risk,
            term
        );
        amount -= reduceAmount;
        // transfer token to market contract
        token.safeTransferFrom(msg.sender, address(market), amount );
        // open position and transfer tokens
        return market.protect(msg.sender, amount, risk, term, autorenew, bumpAmount);
    }

    /// @notice create new taker position using native token (override with NFT mint)
    function protectNative(
        uint16 risk,
        uint16 term,
        bool autorenew
    ) public payable virtual override returns (uint id) {
        // lock BUMP tokens using Bond contract
        (uint bumpAmount, , uint reduceAmount) = bond.autoLockBondTakerPosition(
            msg.sender,
            msg.value,
            risk,
            term
        );

        // open position and transfer tokens
        _wrapNativeASSET();
        // transfer token to market contract
        uint amount = msg.value - reduceAmount;
        token.safeTransfer( address(market), amount );      
        // create taker position  
        return market.protect(
            msg.sender,
            amount,
            risk,
            term,
            autorenew,
            bumpAmount
        );
    }

    /// @notice close position (override with NFT burn)
    /// TODO: add unwrap flag and the frontend/user should decide how to withdraw
    function close(uint id, bool unwrap) public virtual override {
        // get locked BUMP token amount for this position
        uint bumpAmount = market.getTakerPosition(id).bumpAmount;
        // unlock BUMP tokens
        if (bumpAmount > 0) {
            bond.unlock(msg.sender, bumpAmount);
        }
        // close position
        market.close(msg.sender, id, unwrap);
    }


    /// @notice close position (override with NFT burn)
    function claim(uint id) public virtual override {
        // get locked BUMP token amount for this position
        uint bumpAmount = market.getTakerPosition(id).bumpAmount;
        // unlock BUMP tokens
        if (bumpAmount > 0) {
            bond.unlock(msg.sender, bumpAmount);
        }
        // claim position
        uint claimAmountInStable = market.claim(msg.sender, id);
        bst.withdraw(address(stable), claimAmountInStable, address(market), msg.sender );
    }

    /// @notice cancel position (override with NFT burn)
    function cancel(uint id, bool unwrap) public virtual override {
        // get locked BUMP token amount for this position
        uint bumpAmount = market.getTakerPosition(id).bumpAmount;
        // unlock BUMP tokens
        if (bumpAmount > 0) {
            bond.unlock(msg.sender, bumpAmount);
        }
        // close position
        market.cancel(msg.sender, id, unwrap);
    }

    /// @notice create new maker position (override with NFT mint)
    function deposit(
        uint amount,
        uint16 risk,
        uint16 term,
        bool autorenew
    ) public virtual override returns (uint id) {
        // convert stable to BST and mint it to market address
        stable.safeTransferFrom(msg.sender, address(bst), amount );
        uint bstAmount = amount * (10**18) / DIVIDER_STABLE;
        bst.mint( bstAmount, address(market) );

        // lock BUMP tokens using Bond contract
        (uint bumpAmount, , uint reduceAmount) = bond.autoLockBondMakerPosition(
            msg.sender,
            bstAmount,
            risk,
            term
        );        
        // deposit tokens and open position
        return market.deposit(msg.sender, bstAmount - reduceAmount, risk, term, autorenew, bumpAmount);
    }

    /// @notice close maker position (override with NFT burn)
    function withdraw(uint id) public virtual override {
        // get locked BUMP tokens for this position
        uint bumpAmount = market.getMakerPosition(id).bumpAmount;
        // unlock BUMP tokens using Bond contract
        if (bumpAmount > 0) {
            bond.unlock(msg.sender, bumpAmount);
        }
        uint amount = market.withdraw(msg.sender, id);
        bst.withdraw(address(stable), amount, address(market), msg.sender );
    }

    /// @notice cancel position (override with NFT burn)
    function abandon(uint id) public virtual override {
        // get locked BUMP tokens for this position
        uint bumpAmount = market.getMakerPosition(id).bumpAmount;
        // unlock BUMP tokens using Bond contract
        if (bumpAmount > 0) {
            bond.unlock(msg.sender, bumpAmount);
        }
        market.abandon(msg.sender, id);
    }

    function getTakerPosition(uint id) public view override returns (TakerPosition memory) {
        return market.getTakerPosition(id);
    }

    function getMakerPosition(uint id) public view override returns (MakerPosition memory) {
        return market.getMakerPosition(id);
    }

    /// @notice internal function for bonding
    function _bumpBondPermit(
        uint amount,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) private {
        IERC20Permit(address(bump)).permit(
            msg.sender,
            address(bond),
            amount,
            deadline,
            v,
            r,
            s
        );
    }

    function _bumpBondPermit(uint amount, bytes memory permitBump) internal {
        (uint deadline, uint8 v, bytes32 r, bytes32 s) = _decodePermit(
            permitBump
        );
        _bumpBondPermit(amount, deadline, v, r, s);
    }

    function _decodePermit(bytes memory permitEncoded)
        private
        pure
        returns (
            uint deadline,
            uint8 v,
            bytes32 r,
            bytes32 s
        )
    {
        (deadline, v, r, s) = abi.decode(
            permitEncoded,
            (uint, uint8, bytes32, bytes32)
        );
    }

    /// @notice Wrap native token
    function _wrapNativeASSET() internal  {
        IWETH9(address(token)).deposit{value: msg.value}();
    }

    function _unwrapToNativeToken(uint amount) internal  {
        IWETH9(address(token)).withdraw(amount);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IERC20Upgradeable as IERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import "../struct/TakerPosition.sol";
import "../struct/MakerPosition.sol";
import "./IMarketStorage.sol";
import "./IMakerPosition.sol";
import "./ITakerPosition.sol";
import "./IRebalanceable.sol";
import "./IBond.sol";

interface IMarket is IMarketStorage, IRebalanceable {
    function ASSET() external pure returns(IERC20);
    function STABLE() external pure returns(IERC20);

    function price() external view returns (int _price, uint _updatedAt, uint80 _roundId);

    function priceAt(uint80 roundId) external view returns (int _price, uint _updatedAt);

    function getState()
        external
        view
        returns (
            uint AP,
            uint AR,
            uint CP,
            uint CR,
            uint B,
            uint L,
            uint D
        );

    function getRiskCalc() external view returns (address);

     function getTakerPosition(uint id)
        external
        view
        returns (TakerPosition memory);

     function getMakerPosition(uint id)
        external
        view
        returns (MakerPosition memory);

    function protect(
        address account,
        uint amount,
        uint16 risk,
        uint16 term,
        bool autorenew,
        uint bumpAmount
    ) external returns (uint id);

    function close(address account, uint id, bool unwrap) external;

    function claim(address account, uint id) external returns (uint claimAmountInStable);

    function cancel(address account, uint id, bool unwrap) external;    

    function deposit(
        address account,
        uint amount,
        uint16 risk,
        uint16 term,
        bool autorenew,
        uint bumpAmount
    ) external returns (uint id);    

    function withdraw(address account, uint id) external  returns (uint amount);

    function abandon(address account, uint id) external returns (uint amount);    

    // Events
    event Protect(
        address indexed market,
        address indexed account,
        uint id,
        uint amount,
        uint floor,
        uint16 risk,
        uint16 term,
        bool autorenew
    );
    event Claim(
        address indexed market,
        address indexed account,
        uint id,
        uint amount,
        uint floor
    );
    event Close(
        address indexed market,
        address indexed account,
        uint id,
        uint amount,
        uint premium
    );
    event Cancel(
        address indexed market,
        address indexed account,
        uint id,
        uint amount,
        uint premium
    );
   event Deposit(
        address indexed market,
        address indexed account,
        uint id,
        uint amount,
        uint16 risk,
        uint16 term
    );
    event Withdraw(
        address indexed market,
        address indexed account,
        uint id,
        uint amount,
        int reward
    );
    event Abandon(
        address indexed market,
        address indexed account,
        uint id,
        uint amount,
        int reward
    );

    event MarketStateChange(
        address indexed market,
        uint AP, 
        uint AR, 
        uint CP, 
        uint CR, 
        uint B, 
        uint D, 
        uint L
    );
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/// @title IBST
interface IBST {
    function mint(uint amount, address mintTo) external;
    function withdraw(address stable, uint amount, address burnFrom, address to) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "../interfaces/ITakerPosition.sol";
import "../interfaces/IMakerPosition.sol";
import "../interfaces/IBond.sol";

interface IClientMarketAdapter is ITakerPosition, IMakerPosition {
   function ASSET_ADDRESS() external view returns (address);
   function STABLE_ADDRESS() external view returns (address);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

interface IWETH9 {
    function deposit() external payable;

    function withdraw(uint256 _amount) external;
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

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/// @notice Taker position representation structure
struct TakerPosition {
    address owner; // owner of the position
    uint assetAmount; // amount of tokens
    uint start; // timestamp when position was opened
    uint floor; // floor price of the protected tokens
    uint16 risk; // risk in percentage with 100 multiplier (9000 means 90%)
    uint16 term; // term (in days) of protection
    bool autorenew; // autorenew flag
    uint bumpAmount; // locked bump amount for this position
    uint ci; // start position cummulative index
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/// @notice Maker position representaion structure
struct MakerPosition {
    address owner; // owner of the position
    uint stableAmount; // amount of stable tokens
    uint start; // CI when position was opened
    uint16 term; // term (in days) of protection
    uint16 risk; // risk number (1-5)
    bool autorenew; // autorenew flag for the position
    uint bumpAmount; // locked bump amount for this position 
    uint ci; // start position cummulative index    
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "../interfaces/IProtocolConfig.sol";
import "../interfaces/IMarketStates.sol";

import "../struct/TakerPosition.sol";
import "../struct/MakerPosition.sol";
import "./IMakerPosition.sol";
import "./ITakerPosition.sol";

interface IMarketStorage  {
    function minTakerPositionSize() external view returns (uint);
    function minMakerPositionSize() external view returns (uint);

    function AP() external view returns (uint);
    function AR() external view returns (uint);
    function B() external view returns (uint);
    function L() external view returns (uint);

    function CP() external view returns (uint);
    function CR() external view returns (uint);
    function D() external view returns (uint);

    function RWAP() external view returns (uint);

    function config() external view returns(IProtocolConfig);
    // function state() external view returns(IMarketStates);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "../struct/MakerPosition.sol";

interface IMakerPosition {
    function getMakerPosition(uint id)
        external
        view
        returns (MakerPosition memory);

    function deposit(
        uint amount,
        uint16 risk,
        uint16 term,
        bool autorenew
    ) external returns (uint id);

    function depositWithAutoBondingPermit(
        uint amount,
        uint16 risk,
        uint16 term,
        bool autorenew,
        uint bumpAmount,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint id);

    function depositWithPermitWithAutoBondingPermit(
        uint amount,
        uint16 risk,
        uint16 term,
        bool autorenew,
        uint bumpAmount,
        bytes memory permitStable,
        bytes memory permitBump
    ) external returns (uint id);

    function depositWithPermit(
        uint amount,
        uint16 risk,
        uint16 term,
        bool autorenew,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint id);

    function withdraw(uint id) external;

    function abandon(uint id) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "../struct/TakerPosition.sol";

interface ITakerPosition {
     function getTakerPosition(uint id)
        external
        view
        returns (TakerPosition memory);

    function protect(
        uint amount,
        uint16 risk,
        uint16 term,
        bool autorenew
    ) external returns (uint id);

    function protectNative(
        uint16 risk,
        uint16 term,
        bool autorenew
    ) external payable returns (uint id);

    function protectWithAutoBondingPermit(
        uint amount,
        uint16 risk,
        uint16 term,
        bool autorenew,
        uint bumpAmount,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint id);

    function protectWithPermitWithAutoBondingPermit(
        uint amount,
        uint16 risk,
        uint16 term,
        bool autorenew,
        uint bumpAmount,
        bytes memory permitToken,
        bytes memory permitBump
    ) external returns (uint id);

    function protectWithPermit(
        uint amount,
        uint16 risk,
        uint16 term,
        bool autorenew,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint id);

    function close(uint id, bool unwrap) external;

    function claim(uint id) external;

    function cancel(uint id, bool unwrap) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

interface IRebalanceable {
    
    /// @notice rebalance callback
    function onAfterRebalance(
        int deltaAP,
        int deltaAR,
        int deltaCP,
        int deltaCR) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "../struct/BondConfig.sol";

/// @title IBond
interface IBond {
    /// @return address of token which contract stores
    function BOND_TOKEN_ADDRESS() external view returns (address);

    /// @notice transfers amount from your address to contract
    /// @param depositTo - address on which tokens will be deposited
    /// @param amount - amount of token to store in contract
    function deposit(address depositTo, uint amount) external;

    /// @notice permit version of {deposit} method
    function depositWithPermit(
        address depositTo,
        uint amount,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /// @notice transfers amount from your address to contract
    /// @param amount - amount of token to withdraw from contract
    function withdraw(uint amount) external;

    /// @notice locks amount of token in contract
    /// @param _owner - owner of the position
    /// @param amount - amount of token to lock
    /// @param risk - risk in percentage with 100 multiplier (9000 means 90%)
    /// @param term - term (in days) of protection
    /// @return bondAmount to lock based on taker position
    function lockForTaker(
        address _owner,
        uint amount,
        uint16 risk,
        uint16 term
    ) external returns (uint bondAmount);

    /// @notice locks amount of token in contract
    /// @param _owner - owner of the position
    /// @param amount - amount of stable token to lock
    /// @param risk - risk number (1-5)
    /// @param term - term (in days) of protection
    /// @return bondAmount to lock based on maker position
    function lockForMaker(
        address _owner,
        uint amount,
        uint16 risk,
        uint16 term
    ) external returns (uint bondAmount);

    /// @notice unlocks amount of token in contract
    /// @param _owner - owner of the position
    /// @param bondAmount - amount of bond token to unlock
    function unlock(
        address _owner,
        uint bondAmount
    ) external;

    /// @notice calculates taker's bond to lock in contract
    /// @param token - token address
    /// @param amount - amount of asset token
    /// @param risk - risk in percentage with 100 multiplier (9000 means 90%)
    /// @param term - term (in days) of protection
    /// @return bondAmount to lock based on taker position
    function takerBond(
        address token,
        uint amount,
        uint16 risk,
        uint16 term
    ) external view returns (uint bondAmount);

    /// @notice calculates maker's bond to lock in contract
    /// @param token - token address
    /// @param amount - amount of stable token to lock
    /// @param risk - risk number (1-5)
    /// @param term - term (in days) of protection
    /// @return bondAmount to lock based on maker position
    function makerBond(
        address token,
        uint amount,
        uint16 risk,
        uint16 term
    ) external view returns (uint bondAmount);

    /// @notice how much of bond amount will be reduced for taker position
    function takerToSwap(address token, uint bondAmount)
        external
        view
        returns (uint amount);

    /// @notice how much of bond amount will be reduced for maker position
    function makerToSwap(address token, uint bondAmount)
        external
        view
        returns (uint amount);

    function autoLockBondTakerPosition(
        address recipient,
        uint amount,
        uint16 risk,
        uint16 term
    )
        external
        returns (
            uint bondAmount,
            uint toTransfer,
            uint toReduce
        );

    function autoLockBondMakerPosition(
        address recipient,
        uint amount,
        uint16 risk,
        uint16 term
    )
        external
        returns (
            uint bondAmount,
            uint toTransfer,
            uint toReduce
        );

    /// @notice calculates amount of bond position for taker
    function calcBondSizeForTakerPosition(
        address recipient,
        address token,
        uint amount,
        uint16 risk,
        uint16 term
    )
        external
        view
        returns (
            uint toLock,
            uint toTransfer,
            uint toReduce
        );

    /// @notice calculates amount of bond position for maker
    function calcBondSizeForMakerPosition(
        address recipient,
        address token,
        uint amount,
        uint16 risk,
        uint16 term
    )
        external
        view
        returns (
            uint toLock,
            uint toTransfer,
            uint toReduce
        );

    /// @notice locks amount of deposited bond
    function lock(
        address addr,
        uint amount
    ) external;

    /// @param addr - address of user
    /// @return amount - locked amount of particular user
    function lockedOf(address addr) external view returns (uint amount);

    /// @param addr - address of user
    /// @return amount - deposited amount of particular user
    function balanceOf(address addr) external view returns (uint amount);

    /// @notice transfer locked bond between accounts
    function transferLocked(
        address from,
        address to,
        uint amount
    ) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

import "../configuration/MarketConfig.sol";

/// @notice Interface for accessing protocol configuration parameters
interface IProtocolConfig {
    /// @notice get Global access controller
    function getGAC() external view returns (address);

    /// @notice Version of the protocol
    function getVersion() external view returns (uint16);

    /// @notice Stable coin address
    function getStable() external view returns (address);

    /// @notice Configuration params of the given token market
    function getConfig(address token)
        external
        view
        returns (MarketConfig memory config);

    /// @notice Get address of NFT maker for given market
    function getNFTMaker(address token) external view returns (address);
    
    /// @notice Get address of NFT taker for given market
    function getNFTTaker(address token) external view returns (address);

    /// @notice Get address of B-token for given market
    function getBToken(address token) external view returns (address);

    /// @notice Get market contract address by token address
    function getMarket(address token) external view returns (address);

    /// @notice Get wrapped native market address
    function getWrappedNativeMarket() external view returns (address);

    /// @notice Get wrapped native token address
    function getWrappedNativeASSET() external view returns (address);

    /// @notice Get IMarketStates contract implementation address
    function getState() external view returns (address);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

import "../struct/MarketState.sol";

/// @notice Interface for accessing and managing markets states/prices
interface IMarketStates {
    /// @notice get calculated average price in 64.64 format
    function getWeightedAvgPrice(address token) external view returns (int);

    /// @notice get current market state parameters
    function getCurrentState(address token)
        external
        view
        returns (MarketState memory data);

    /// @notice update market state for given tokens
    function updateStates(address[] memory tokens) external;

    /// @notice update prices, average and price components
    function updatePrices(address[] memory tokens) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

/// @notice Market configuration settings
struct MarketConfig {
    // price risk factor calculation
    int128 Vel_Max; // max historical velocity
    int128 Acc_Max; // max historical acceleration
    int128 Min_Price_Change; //  min price change (in percent)
    int128 Min_Price_Period; // min update period
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

struct MarketState {
    int128 shock;
    int128 surge;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/// @title BondConfig
struct BondConfig {
    uint bumpPerAsset;
    uint bumpPerStable;
    uint assetPerBump;
    uint stablePerBump;
}