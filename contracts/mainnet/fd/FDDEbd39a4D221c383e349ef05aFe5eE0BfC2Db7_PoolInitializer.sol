// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import 'src/Interfaces/IPool.sol';
import 'src/Interfaces/IERC20.sol';

contract PoolInitializer {
    address admin;

    // Pool has been paused/unpaused
    event InitializePool(uint256 basePerFyToken);

    // User is not authorized
    error Unauthorized();

    constructor() {
        admin = msg.sender;
    }

    /// Allows only the authorized contract to execute the method
    modifier authorized(address a) {
        if (msg.sender != a) revert Unauthorized();
        _;
    }

    // @notice Initializes a Euler based shares token YieldSpace Pool and adjusts the current fyToken price
    // @param pool The pool that will get initialized
    // @param base The underlying token address traded against fyTokens
    // @param fyToken The principal token address being traded against
    // @param baseLP The amount of base tokens to commit as liquidity
    // @param fyTokenSold The amount of fyTokens to sell to the pool in order to adjust the fyToken price
    function initializePool(
        address pool,
        address base,
        address fyToken,
        uint256 baseLP,
        uint256 fyTokenSold
    ) public authorized(admin) returns (address) {
        // Transfer Base amount to pool
        IERC20(base).transferFrom(msg.sender, address(pool), baseLP);
        // Initialize the pool's liquidity, granting LP tokens and creating "virtual" fyToken liquidity
        IPool(pool).init(msg.sender);
        // Transfer fyTokens to sell to the pool
        IERC20(fyToken).transferFrom(msg.sender, address(pool), fyTokenSold);
        // Sell fyTokens to the pool, adjusting the fyToken price
        uint256 baseOut = IPool(pool).sellFYToken(msg.sender, 0);
        // Retake admin control
        setPoolAdmin(pool, msg.sender);
        // emit an event for simulation testing
        emit InitializePool(baseOut);

        return pool;
    }

    /// Allows the admin to transfer ownership of the contract
    function setAdmin(address a) external authorized(admin) {
        admin = a;
    }

    // Allows the pool contract to reset the admin to another address
    function setPoolAdmin(address p, address a) internal {
        IPool(p).setAdmin(a);
    }
}

// SPDX-License-Identifier: MIT
// Inspired on token.sol from DappHub. Natspec adpated from OpenZeppelin.

pragma solidity ^0.8.0;
import "../Interfaces/IERC20Metadata.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 * 
 * Calls to {transferFrom} do not check for allowance if the caller is the owner
 * of the funds. This allows to reduce the number of approvals that are necessary.
 *
 * Finally, {transferFrom} does not decrease the allowance if it is set to
 * type(uint256).max. This reduces the gas costs without any likely impact.
 */
contract ERC20 is IERC20Metadata {
    uint256                                           internal  _totalSupply;
    mapping (address => uint256)                      internal  _balanceOf;
    mapping (address => mapping (address => uint256)) internal  _allowance;
    string                                            public override name = "???";
    string                                            public override symbol = "???";
    uint8                                             public override decimals = 18;

    /**
     *  @dev Sets the values for {name}, {symbol} and {decimals}.
     */
    constructor(string memory name_, string memory symbol_, uint8 decimals_) {
        name = name_;
        symbol = symbol_;
        decimals = decimals_;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() external view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address guy) external view virtual override returns (uint256) {
        return _balanceOf[guy];
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) external view virtual override returns (uint256) {
        return _allowance[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     */
    function approve(address spender, uint wad) external virtual override returns (bool) {
        return _setAllowance(msg.sender, spender, wad);
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - the caller must have a balance of at least `wad`.
     */
    function transfer(address dst, uint wad) external virtual override returns (bool) {
        return _transfer(msg.sender, dst, wad);
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `src` must have a balance of at least `wad`.
     * - the caller is not `src`, it must have allowance for ``src``'s tokens of at least
     * `wad`.
     */
    /// if_succeeds {:msg "TransferFrom - decrease allowance"} msg.sender != src ==> old(_allowance[src][msg.sender]) >= wad;
    function transferFrom(address src, address dst, uint wad) external virtual override returns (bool) {
        _decreaseAllowance(src, wad);

        return _transfer(src, dst, wad);
    }

    /**
     * @dev Moves tokens `wad` from `src` to `dst`.
     * 
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `src` must have a balance of at least `amount`.
     */
    /// if_succeeds {:msg "Transfer - src decrease"} old(_balanceOf[src]) >= _balanceOf[src];
    /// if_succeeds {:msg "Transfer - dst increase"} _balanceOf[dst] >= old(_balanceOf[dst]);
    /// if_succeeds {:msg "Transfer - supply"} old(_balanceOf[src]) + old(_balanceOf[dst]) == _balanceOf[src] + _balanceOf[dst];
    function _transfer(address src, address dst, uint wad) internal virtual returns (bool) {
        require(_balanceOf[src] >= wad, "ERC20: Insufficient balance");
        unchecked { _balanceOf[src] = _balanceOf[src] - wad; }
        _balanceOf[dst] = _balanceOf[dst] + wad;

        emit Transfer(src, dst, wad);

        return true;
    }

    /**
     * @dev Sets the allowance granted to `spender` by `owner`.
     *
     * Emits an {Approval} event indicating the updated allowance.
     */
    function _setAllowance(address owner, address spender, uint wad) internal virtual returns (bool) {
        _allowance[owner][spender] = wad;
        emit Approval(owner, spender, wad);

        return true;
    }

    /**
     * @dev Decreases the allowance granted to the caller by `src`, unless src == msg.sender or _allowance[src][msg.sender] == MAX
     *
     * Emits an {Approval} event indicating the updated allowance, if the allowance is updated.
     *
     * Requirements:
     *
     * - `spender` must have allowance for the caller of at least
     * `wad`, unless src == msg.sender
     */
    /// if_succeeds {:msg "Decrease allowance - underflow"} old(_allowance[src][msg.sender]) <= _allowance[src][msg.sender];
    function _decreaseAllowance(address src, uint wad) internal virtual returns (bool) {
        if (src != msg.sender) {
            uint256 allowed = _allowance[src][msg.sender];
            if (allowed != type(uint).max) {
                require(allowed >= wad, "ERC20: Insufficient approval");
                unchecked { _setAllowance(src, msg.sender, allowed - wad); }
            }
        }

        return true;
    }

    /** @dev Creates `wad` tokens and assigns them to `dst`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     */
    /// if_succeeds {:msg "Mint - balance overflow"} old(_balanceOf[dst]) >= _balanceOf[dst];
    /// if_succeeds {:msg "Mint - supply overflow"} old(_totalSupply) >= _totalSupply;
    function _mint(address dst, uint wad) internal virtual returns (bool) {
        _balanceOf[dst] = _balanceOf[dst] + wad;
        _totalSupply = _totalSupply + wad;
        emit Transfer(address(0), dst, wad);

        return true;
    }

    /**
     * @dev Destroys `wad` tokens from `src`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `src` must have at least `wad` tokens.
     */
    /// if_succeeds {:msg "Burn - balance underflow"} old(_balanceOf[src]) <= _balanceOf[src];
    /// if_succeeds {:msg "Burn - supply underflow"} old(_totalSupply) <= _totalSupply;
    function _burn(address src, uint wad) internal virtual returns (bool) {
        unchecked {
            require(_balanceOf[src] >= wad, "ERC20: Insufficient balance");
            _balanceOf[src] = _balanceOf[src] - wad;
            _totalSupply = _totalSupply - wad;
            emit Transfer(src, address(0), wad);
        }

        return true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the number of decimals the token uses
     */
    function decimals() external view returns (uint8);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.15;
import './IERC20Metadata.sol';
import './IERC20.sol';

interface IERC20Like is IERC20, IERC20Metadata {
    function mint(address receiver, uint256 shares) external;
}

// SPDX-License-Identifier: MIT
// Taken from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/extensions/IERC20Metadata.sol

pragma solidity ^0.8.0;

import "./IERC20.sol";

/**
 * @dev Interface for the oFYTokenional metadata functions from the ERC20 standard.
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
// Code adaFYTokened from https://github.com/OpenZeppelin/openzeppelin-contracts/pull/2237/
pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC2612 standard as defined in the EIP.
 *
 * Adds the {permit} method, which can be used to change one's
 * {IERC20-allowance} without having to send a transaction, by signing a
 * message. This allows users to spend tokens without having to hold Ether.
 *
 * See https://eips.ethereum.org/EIPS/eip-2612.
 */
interface IERC2612 {
    /**
     * @dev Sets `amount` as the allowance of `spender` over `owner`'s tokens,
     * given `owner`'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
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
    function permit(address owner, address spender, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;

    /**
     * @dev Returns the current ERC2612 nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./IERC20.sol";
import "./IJoin.sol";

interface IFYToken is IERC20 {
    /// @dev Asset that is returned on redemption.
    function base() external view returns (address);

    /// @dev Source of redemption funds.
    function join() external view returns (IJoin);

    /// @dev Unix time at which redemption of FYToken for base are possible
    function maturity() external view returns (uint256);

    /// @dev Record price data at maturity
    function mature() external;

    /// @dev Mint FYToken providing an equal amount of base to the protocol
    function mintWithbase(address to, uint256 amount) external;

    /// @dev Burn FYToken after maturity for an amount of base.
    function redeem(address to, uint256 amount) external returns (uint256);

    /// @dev Mint FYToken.
    /// This function can only be called by other Yield contracts, not users directly.
    /// @param to Wallet to mint the FYToken in.
    /// @param FYTokenAmount Amount of FYToken to mint.
    function mint(address to, uint256 FYTokenAmount) external;

    /// @dev Burn FYToken.
    /// This function can only be called by other Yield contracts, not users directly.
    /// @param from Wallet to burn the FYToken from.
    /// @param FYTokenAmount Amount of FYToken to burn.
    function burn(address from, uint256 FYTokenAmount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./IERC20.sol";

interface IJoin {
    /// @dev asset managed by this contract
    function asset() external view returns (address);

    /// @dev Add tokens to this contract.
    function join(address user, uint128 wad) external returns (uint128);

    /// @dev Remove tokens to this contract.
    function exit(address user, uint128 wad) external returns (uint128);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.15;
import './IERC20.sol';

interface IMaturingToken is IERC20 {
    function maturity() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
import './IERC20.sol';
import './IERC2612.sol';
import './IFYToken.sol';
import {IMaturingToken} from './IMaturingToken.sol';
import {IERC20Metadata} from '../ERC/ERC20.sol';
import {IERC20Like} from './IERC20Like.sol';

interface IPool is IERC20, IERC2612 {
    function baseToken() external view returns (IERC20Like);

    function base() external view returns (IERC20);

    function burn(
        address baseTo,
        address fyTokenTo,
        uint256 minRatio,
        uint256 maxRatio
    )
        external
        returns (
            uint256,
            uint256,
            uint256
        );

    function burnForBase(
        address to,
        uint256 minRatio,
        uint256 maxRatio
    ) external returns (uint256, uint256);

    function buyBase(
        address to,
        uint128 baseOut,
        uint128 max
    ) external returns (uint128);

    function buyBasePreview(uint128 baseOut) external view returns (uint128);

    function buyFYToken(
        address to,
        uint128 fyTokenOut,
        uint128 max
    ) external returns (uint128);

    function buyFYTokenPreview(uint128 fyTokenOut)
        external
        view
        returns (uint128);

    function currentCumulativeRatio()
        external
        view
        returns (
            uint256 currentCumulativeRatio_,
            uint256 blockTimestampCurrent
        );

    function cumulativeRatioLast() external view returns (uint256);

    function fyToken() external view returns (IMaturingToken);

    function g1() external view returns (int128);

    function g2() external view returns (int128);

    function getC() external view returns (int128);

    function getCurrentSharePrice() external view returns (uint256);

    function getCache()
        external
        view
        returns (
            uint104 baseCached,
            uint104 fyTokenCached,
            uint32 blockTimestampLast,
            uint16 g1Fee_
        );

    function getBaseBalance() external view returns (uint128);

    function getFYTokenBalance() external view returns (uint128);

    function getSharesBalance() external view returns (uint128);

    function init(address to)
        external
        returns (
            uint256,
            uint256,
            uint256
        );

    function maturity() external view returns (uint32);

    function mint(
        address to,
        address remainder,
        uint256 minRatio,
        uint256 maxRatio
    )
        external
        returns (
            uint256,
            uint256,
            uint256
        );

    function mu() external view returns (int128);

    function mintWithBase(
        address to,
        address remainder,
        uint256 fyTokenToBuy,
        uint256 minRatio,
        uint256 maxRatio
    )
        external
        returns (
            uint256,
            uint256,
            uint256
        );

    function retrieveBase(address to) external returns (uint128 retrieved);

    function retrieveFYToken(address to) external returns (uint128 retrieved);

    function retrieveShares(address to) external returns (uint128 retrieved);

    function scaleFactor() external view returns (uint96);

    function sellBase(address to, uint128 min) external returns (uint128);

    function sellBasePreview(uint128 baseIn) external view returns (uint128);

    function sellFYToken(address to, uint128 min) external returns (uint128);

    function sellFYTokenPreview(uint128 fyTokenIn)
        external
        view
        returns (uint128);

    function setFees(uint16 g1Fee_) external;

    function sharesToken() external view returns (IERC20Like);

    function ts() external view returns (int128);

    function wrap(address receiver) external returns (uint256 shares);

    function wrapPreview(uint256 assets) external view returns (uint256 shares);

    function unwrap(address receiver) external returns (uint256 assets);

    function unwrapPreview(uint256 shares)
        external
        view
        returns (uint256 assets);

    /// Returns the max amount of FYTokens that can be sold to the pool
    function maxFYTokenIn() external view returns (uint128);

    /// Returns the max amount of FYTokens that can be bought from the pool
    function maxFYTokenOut() external view returns (uint128);

    /// Returns the max amount of Base that can be sold to the pool
    function maxBaseIn() external view returns (uint128);

    /// Returns the max amount of Base that can be bought from the pool
    function maxBaseOut() external view returns (uint128);

    /// Returns the result of the total supply invariant function
    function invariant() external view returns (uint128);

    /// Sets the pool's admin
    function setAdmin(address) external;
}