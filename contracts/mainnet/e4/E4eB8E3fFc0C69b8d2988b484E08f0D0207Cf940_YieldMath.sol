// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.15;

// AdaFYTokened from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/53516bc555a454862470e7860a9b5254db4d00f5/contracts/token/ERC20/ERC20Permit.sol

// Inspired on token.sol from DappHub. Natspec adpated from OpenZeppelin.

// Taken from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/extensions/IERC20Metadata.sol

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

// Code adaFYTokened from https://github.com/OpenZeppelin/openzeppelin-contracts/pull/2237/

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

/**
 * @dev Extension of {ERC20} that allows token holders to use their tokens
 * without sending any transactions by setting {IERC20-allowance} with a
 * signature using the {permit} method, and then spend them via
 * {IERC20-transferFrom}.
 *
 * The {permit} signature mechanism conforms to the {IERC2612} interface.
 */
abstract contract ERC20Permit is ERC20, IERC2612 {
    mapping (address => uint256) public override nonces;

    bytes32 public immutable PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 private immutable _DOMAIN_SEPARATOR;
    uint256 public immutable deploymentChainId;

    constructor(string memory name_, string memory symbol_, uint8 decimals_) ERC20(name_, symbol_, decimals_) {
        deploymentChainId = block.chainid;
        _DOMAIN_SEPARATOR = _calculateDomainSeparator(block.chainid);
    }

    /// @dev Calculate the DOMAIN_SEPARATOR.
    function _calculateDomainSeparator(uint256 chainId) private view returns (bytes32) {
        return keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256(bytes(version())),
                chainId,
                address(this)
            )
        );
    }

    /// @dev Return the DOMAIN_SEPARATOR.
    function DOMAIN_SEPARATOR() external view returns (bytes32) {
        return block.chainid == deploymentChainId ? _DOMAIN_SEPARATOR : _calculateDomainSeparator(block.chainid);
    }

    /// @dev Setting the version as a function so that it can be overriden
    function version() public pure virtual returns(string memory) { return "1"; }

    /**
     * @dev See {IERC2612-permit}.
     *
     * In cases where the free oFYTokenion is not a concern, deadline can simply be
     * set to uint(-1), so it should be seen as an oFYTokenional parameter
     */
    function permit(address owner, address spender, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external virtual override {
        require(deadline >= block.timestamp, "ERC20Permit: expired deadline");

        bytes32 hashStruct = keccak256(
            abi.encode(
                PERMIT_TYPEHASH,
                owner,
                spender,
                amount,
                nonces[owner]++,
                deadline
            )
        );

        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19\x01",
                block.chainid == deploymentChainId ? _DOMAIN_SEPARATOR : _calculateDomainSeparator(block.chainid),
                hashStruct
            )
        );

        address signer = ecrecover(hash, v, r, s);
        require(
            signer != address(0) && signer == owner,
            "ERC20Permit: invalid signature"
        );

        _setAllowance(owner, spender, amount);
    }
}

interface IJoin {
    /// @dev asset managed by this contract
    function asset() external view returns (address);

    /// @dev Add tokens to this contract.
    function join(address user, uint128 wad) external returns (uint128);

    /// @dev Remove tokens to this contract.
    function exit(address user, uint128 wad) external returns (uint128);
}

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

interface IMaturingToken is IERC20 {
    function maturity() external view returns (uint256);
}

interface IERC20Like is IERC20, IERC20Metadata {
    function mint(address receiver, uint256 shares) external;
}

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

interface IERC4626 is IERC20, IERC20Metadata {
    function asset() external returns (IERC20);

    function convertToAssets(uint256 shares) external view returns (uint256);

    function convertToShares(uint256 assets) external view returns (uint256);

    function deposit(uint256 assets, address receiver)
        external
        returns (uint256 shares);

    function mint(address receiver, uint256 shares)
        external
        returns (uint256 assets);

    function previewDeposit(uint256 assets)
        external
        view
        returns (uint256 shares);

    function previewRedeem(uint256 shares)
        external
        view
        returns (uint256 assets);

    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) external returns (uint256 assets);
}

// Taken from https://github.com/Uniswap/uniswap-lib/blob/master/contracts/libraries/TransferHelper.sol

// Taken from https://github.com/sushiswap/BoringSolidity/blob/441e51c0544cf2451e6116fe00515e71d7c42e2c/contracts/BoringBatchable.sol

library RevertMsgExtractor {
    /// @dev Helper function to extract a useful revert message from a failed call.
    /// If the returned data is malformed or not correctly abi encoded then this call can fail itself.
    function getRevertMsg(bytes memory returnData)
        internal pure
        returns (string memory)
    {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (returnData.length < 68) return "Transaction reverted silently";

        assembly {
            // Slice the sighash.
            returnData := add(returnData, 0x04)
        }
        return abi.decode(returnData, (string)); // All that remains is the revert string
    }
}

// helper methods for transferring ERC20 tokens that do not consistently return true/false
library MinimalTransferHelper {
    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with the base revert message if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        if (!(success && (data.length == 0 || abi.decode(data, (bool))))) revert(RevertMsgExtractor.getRevertMsg(data));
    }
}

library CastU256U128 {
    /// @dev Safely cast an uint256 to an uint128
    function u128(uint256 x) internal pure returns (uint128 y) {
        require (x <= type(uint128).max, "Cast overflow");
        y = uint128(x);
    }
}

library CastU256U112 {
    /// @dev Safely cast an uint256 to an uint112
    function u112(uint256 x) internal pure returns (uint112 y) {
        require (x <= type(uint112).max, "Cast overflow");
        y = uint112(x);
    }
}

library CastU256I256 {
    /// @dev Safely cast an uint256 to an int256
    function i256(uint256 x) internal pure returns (int256 y) {
        require (x <= uint256(type(int256).max), "Cast overflow");
        y = int256(x);
    }
}

library CastU256U104 {
    /// @dev Safely cast an uint256 to an uint104
    function u104(uint256 x) internal pure returns (uint104 y) {
        require(x <= type(uint104).max, 'Cast overflow');
        y = uint104(x);
    }
}

library CastU128U112 {
    /// @dev Safely cast an uint128 to an uint112
    function u112(uint128 x) internal pure returns (uint112 y) {
        require (x <= type(uint112).max, "Cast overflow");
        y = uint112(x);
    }
}

library CastU128I128 {
    /// @dev Safely cast an uint128 to an int128
    function i128(uint128 x) internal pure returns (int128 y) {
        require (x <= uint128(type(int128).max), "Cast overflow");
        y = int128(x);
    }
}

library CastU128U104 {
    /// @dev Safely cast an uint128 to an uint104
    function u104(uint128 x) internal pure returns (uint104 y) {
        require(x <= type(uint104).max, 'Cast overflow');
        y = uint104(x);
    }
}

library RDiv {
    // Fixed point arithmetic for ray (27 decimal units)
    /// @dev Divide an amount by a fixed point factor with 27 decimals
    function rdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = (x * 1e27) / y;
    }
}

library WDiv {
    // Fixed point arithmetic in 18 decimal units
    // Taken from https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol
    /// @dev Divide an amount by a fixed point factor with 18 decimals
    function wdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = (x * 1e18) / y;
    }
}

/*
   __     ___      _     _
   \ \   / (_)    | |   | | ██╗   ██╗██╗███████╗██╗     ██████╗ ███╗   ███╗ █████╗ ████████╗██╗  ██╗
    \ \_/ / _  ___| | __| | ╚██╗ ██╔╝██║██╔════╝██║     ██╔══██╗████╗ ████║██╔══██╗╚══██╔══╝██║  ██║
     \   / | |/ _ \ |/ _` |  ╚████╔╝ ██║█████╗  ██║     ██║  ██║██╔████╔██║███████║   ██║   ███████║
      | |  | |  __/ | (_| |   ╚██╔╝  ██║██╔══╝  ██║     ██║  ██║██║╚██╔╝██║██╔══██║   ██║   ██╔══██║
      |_|  |_|\___|_|\__,_|    ██║   ██║███████╗███████╗██████╔╝██║ ╚═╝ ██║██║  ██║   ██║   ██║  ██║
       yieldprotocol.com       ╚═╝   ╚═╝╚══════╝╚══════╝╚═════╝ ╚═╝     ╚═╝╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝
*/

 /*
   __     ___      _     _
   \ \   / (_)    | |   | | ███████╗██╗  ██╗██████╗  ██████╗ ██╗  ██╗██╗  ██╗ ██████╗ ██╗  ██╗
    \ \_/ / _  ___| | __| | ██╔════╝╚██╗██╔╝██╔══██╗██╔════╝ ██║  ██║╚██╗██╔╝██╔════╝ ██║  ██║
     \   / | |/ _ \ |/ _` | █████╗   ╚███╔╝ ██████╔╝███████╗ ███████║ ╚███╔╝ ███████╗ ███████║
      | |  | |  __/ | (_| | ██╔══╝   ██╔██╗ ██╔═══╝ ██╔═══██╗╚════██║ ██╔██╗ ██╔═══██╗╚════██║
      |_|  |_|\___|_|\__,_| ███████╗██╔╝ ██╗██║     ╚██████╔╝     ██║██╔╝ ██╗╚██████╔╝     ██║
       yieldprotocol.com    ╚══════╝╚═╝  ╚═╝╚═╝      ╚═════╝      ╚═╝╚═╝  ╚═╝ ╚═════╝      ╚═╝
                            Gas optimized math library custom-built by ABDK -- Copyright © 2019 */

 /*
  __     ___      _     _
  \ \   / (_)    | |   | |  ███╗   ███╗ █████╗ ████████╗██╗  ██╗ ██████╗ ██╗  ██╗██╗  ██╗ ██████╗ ██╗  ██╗
   \ \_/ / _  ___| | __| |  ████╗ ████║██╔══██╗╚══██╔══╝██║  ██║██╔════╝ ██║  ██║╚██╗██╔╝██╔════╝ ██║  ██║
    \   / | |/ _ \ |/ _` |  ██╔████╔██║███████║   ██║   ███████║███████╗ ███████║ ╚███╔╝ ███████╗ ███████║
     | |  | |  __/ | (_| |  ██║╚██╔╝██║██╔══██║   ██║   ██╔══██║██╔═══██╗╚════██║ ██╔██╗ ██╔═══██╗╚════██║
     |_|  |_|\___|_|\__,_|  ██║ ╚═╝ ██║██║  ██║   ██║   ██║  ██║╚██████╔╝     ██║██╔╝ ██╗╚██████╔╝     ██║
       yieldprotocol.com    ╚═╝     ╚═╝╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝ ╚═════╝      ╚═╝╚═╝  ╚═╝ ╚═════╝      ╚═╝
*/

/// Smart contract library of mathematical functions operating with signed
/// 64.64-bit fixed point numbers.  Signed 64.64-bit fixed point number is
/// basically a simple fraction whose numerator is signed 128-bit integer and
/// denominator is 2^64.  As long as denominator is always the same, there is no
/// need to store it, thus in Solidity signed 64.64-bit fixed point numbers are
/// represented by int128 type holding only the numerator.
/// @title  Math64x64.sol
/// @author Mikhail Vladimirov - ABDK Consulting
/// https://github.com/abdk-consulting/abdk-libraries-solidity/blob/master/ABDKMath64x64.sol
library Math64x64 {
    /* CONVERTERS
     ******************************************************************************************************************/
    /*
     * Minimum value signed 64.64-bit fixed point number may have.
     */
    int128 private constant MIN_64x64 = -0x80000000000000000000000000000000;

    /*
     * Maximum value signed 64.64-bit fixed point number may have.
     */
    int128 private constant MAX_64x64 = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    /// @dev Convert signed 256-bit integer number into signed 64.64-bit fixed point
    /// number.  Revert on overflow.
    /// @param x signed 256-bit integer number
    /// @return signed 64.64-bit fixed point number
    function fromInt(int256 x) internal pure returns (int128) {
        unchecked {
            require(x >= -0x8000000000000000 && x <= 0x7FFFFFFFFFFFFFFF);
            return int128(x << 64);
        }
    }

    /// @dev Convert signed 64.64 fixed point number into signed 64-bit integer number rounding down.
    /// @param x signed 64.64-bit fixed point number
    /// @return signed 64-bit integer number
    function toInt(int128 x) internal pure returns (int64) {
        unchecked {
            return int64(x >> 64);
        }
    }

    /// @dev Convert unsigned 256-bit integer number into signed 64.64-bit fixed point number.  Revert on overflow.
    /// @param x unsigned 256-bit integer number
    /// @return signed 64.64-bit fixed point number
    function fromUInt(uint256 x) internal pure returns (int128) {
        unchecked {
            require(x <= 0x7FFFFFFFFFFFFFFF);
            return int128(int256(x << 64));
        }
    }

    /// @dev Convert signed 64.64 fixed point number into unsigned 64-bit integer number rounding down.
    /// Reverts on underflow.
    /// @param x signed 64.64-bit fixed point number
    /// @return unsigned 64-bit integer number
    function toUInt(int128 x) internal pure returns (uint64) {
        unchecked {
            require(x >= 0);
            return uint64(uint128(x >> 64));
        }
    }

    /// @dev Convert signed 128.128 fixed point number into signed 64.64-bit fixed point number rounding down.
    /// Reverts on overflow.
    /// @param x signed 128.128-bin fixed point number
    /// @return signed 64.64-bit fixed point number
    function from128x128(int256 x) internal pure returns (int128) {
        unchecked {
            int256 result = x >> 64;
            require(result >= MIN_64x64 && result <= MAX_64x64);
            return int128(result);
        }
    }

    /// @dev Convert signed 64.64 fixed point number into signed 128.128 fixed point number.
    /// @param x signed 64.64-bit fixed point number
    /// @return signed 128.128 fixed point number
    function to128x128(int128 x) internal pure returns (int256) {
        unchecked {
            return int256(x) << 64;
        }
    }

    /* OPERATIONS
     ******************************************************************************************************************/

    /// @dev Calculate x + y.  Revert on overflow.
    /// @param x signed 64.64-bit fixed point number
    /// @param y signed 64.64-bit fixed point number
    /// @return signed 64.64-bit fixed point number
    function add(int128 x, int128 y) internal pure returns (int128) {
        unchecked {
            int256 result = int256(x) + y;
            require(result >= MIN_64x64 && result <= MAX_64x64);
            return int128(result);
        }
    }

    /// @dev Calculate x - y.  Revert on overflow.
    /// @param x signed 64.64-bit fixed point number
    /// @param y signed 64.64-bit fixed point number
    /// @return signed 64.64-bit fixed point number
    function sub(int128 x, int128 y) internal pure returns (int128) {
        unchecked {
            int256 result = int256(x) - y;
            require(result >= MIN_64x64 && result <= MAX_64x64);
            return int128(result);
        }
    }

    /// @dev Calculate x///y rounding down.  Revert on overflow.
    /// @param x signed 64.64-bit fixed point number
    /// @param y signed 64.64-bit fixed point number
    /// @return signed 64.64-bit fixed point number
    function mul(int128 x, int128 y) internal pure returns (int128) {
        unchecked {
            int256 result = (int256(x) * y) >> 64;
            require(result >= MIN_64x64 && result <= MAX_64x64);
            return int128(result);
        }
    }

    /// @dev Calculate x * y rounding towards zero, where x is signed 64.64 fixed point
    /// number and y is signed 256-bit integer number.  Revert on overflow.
    /// @param x signed 64.64 fixed point number
    /// @param y signed 256-bit integer number
    /// @return signed 256-bit integer number
    function muli(int128 x, int256 y) internal pure returns (int256) {
        //NOTE: This reverts if y == type(int128).min
        unchecked {
            if (x == MIN_64x64) {
                require(
                    y >= -0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF &&
                        y <= 0x1000000000000000000000000000000000000000000000000
                );
                return -y << 63;
            } else {
                bool negativeResult = false;
                if (x < 0) {
                    x = -x;
                    negativeResult = true;
                }
                if (y < 0) {
                    y = -y; // We rely on overflow behavior here
                    negativeResult = !negativeResult;
                }
                uint256 absoluteResult = mulu(x, uint256(y));
                if (negativeResult) {
                    require(
                        absoluteResult <=
                            0x8000000000000000000000000000000000000000000000000000000000000000
                    );
                    return -int256(absoluteResult); // We rely on overflow behavior here
                } else {
                    require(
                        absoluteResult <=
                            0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
                    );
                    return int256(absoluteResult);
                }
            }
        }
    }

    /// @dev Calculate x * y rounding down, where x is signed 64.64 fixed point number
    /// and y is unsigned 256-bit integer number.  Revert on overflow.
    /// @param x signed 64.64 fixed point number
    /// @param y unsigned 256-bit integer number
    /// @return unsigned 256-bit integer number
    function mulu(int128 x, uint256 y) internal pure returns (uint256) {
        unchecked {
            if (y == 0) return 0;

            require(x >= 0);

            uint256 lo = (uint256(int256(x)) *
                (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)) >> 64;
            uint256 hi = uint256(int256(x)) * (y >> 128);

            require(hi <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
            hi <<= 64;

            require(
                hi <=
                    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF -
                        lo
            );
            return hi + lo;
        }
    }

    /// @dev Calculate x / y rounding towards zero.  Revert on overflow or when y is zero.
    /// @param x signed 64.64-bit fixed point number
    /// @param y signed 64.64-bit fixed point number
    /// @return signed 64.64-bit fixed point number
    function div(int128 x, int128 y) internal pure returns (int128) {
        unchecked {
            require(y != 0);
            int256 result = (int256(x) << 64) / y;
            require(result >= MIN_64x64 && result <= MAX_64x64);
            return int128(result);
        }
    }

    /// @dev Calculate x / y rounding towards zero, where x and y are signed 256-bit
    /// integer numbers.  Revert on overflow or when y is zero.
    /// @param x signed 256-bit integer number
    /// @param y signed 256-bit integer number
    /// @return signed 64.64-bit fixed point number
    function divi(int256 x, int256 y) internal pure returns (int128) {
        unchecked {
            require(y != 0);

            bool negativeResult = false;
            if (x < 0) {
                x = -x; // We rely on overflow behavior here
                negativeResult = true;
            }
            if (y < 0) {
                y = -y; // We rely on overflow behavior here
                negativeResult = !negativeResult;
            }
            uint128 absoluteResult = divuu(uint256(x), uint256(y));
            if (negativeResult) {
                require(absoluteResult <= 0x80000000000000000000000000000000);
                return -int128(absoluteResult); // We rely on overflow behavior here
            } else {
                require(absoluteResult <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
                return int128(absoluteResult); // We rely on overflow behavior here
            }
        }
    }

    /// @dev Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
    /// integer numbers.  Revert on overflow or when y is zero.
    /// @param x unsigned 256-bit integer number
    /// @param y unsigned 256-bit integer number
    /// @return signed 64.64-bit fixed point number
    function divu(uint256 x, uint256 y) internal pure returns (int128) {
        unchecked {
            require(y != 0);
            uint128 result = divuu(x, y);
            require(result <= uint128(MAX_64x64));
            return int128(result);
        }
    }

    /// @dev Calculate -x.  Revert on overflow.
    /// @param x signed 64.64-bit fixed point number
    /// @return signed 64.64-bit fixed point number
    function neg(int128 x) internal pure returns (int128) {
        unchecked {
            require(x != MIN_64x64);
            return -x;
        }
    }

    /// @dev Calculate |x|.  Revert on overflow.
    /// @param x signed 64.64-bit fixed point number
    /// @return signed 64.64-bit fixed point number
    function abs(int128 x) internal pure returns (int128) {
        unchecked {
            require(x != MIN_64x64);
            return x < 0 ? -x : x;
        }
    }

    /// @dev Calculate 1 / x rounding towards zero.  Revert on overflow or when x is
    ///zero.
    /// @param x signed 64.64-bit fixed point number
    /// @return signed 64.64-bit fixed point number
    function inv(int128 x) internal pure returns (int128) {
        unchecked {
            require(x != 0);
            int256 result = int256(0x100000000000000000000000000000000) / x;
            require(result >= MIN_64x64 && result <= MAX_64x64);
            return int128(result);
        }
    }

    /// @dev Calculate arithmetics average of x and y, i.e. (x + y) / 2 rounding down.
    /// @param x signed 64.64-bit fixed point number
    /// @param y signed 64.64-bit fixed point number
    /// @return signed 64.64-bit fixed point number
    function avg(int128 x, int128 y) internal pure returns (int128) {
        unchecked {
            return int128((int256(x) + int256(y)) >> 1);
        }
    }

    /// @dev Calculate geometric average of x and y, i.e. sqrt (x * y) rounding down.
    /// Revert on overflow or in case x * y is negative.
    /// @param x signed 64.64-bit fixed point number
    /// @param y signed 64.64-bit fixed point number
    /// @return signed 64.64-bit fixed point number
    function gavg(int128 x, int128 y) internal pure returns (int128) {
        unchecked {
            int256 m = int256(x) * int256(y);
            require(m >= 0);
            require(
                m <
                    0x4000000000000000000000000000000000000000000000000000000000000000
            );
            return int128(sqrtu(uint256(m)));
        }
    }

    /// @dev Calculate x^y assuming 0^0 is 1, where x is signed 64.64 fixed point number
    /// and y is unsigned 256-bit integer number.  Revert on overflow.
    /// also see:https://hackmd.io/gbnqA3gCTR6z-F0HHTxF-A#33-Normalized-Fractional-Exponentiation
    /// @param x signed 64.64-bit fixed point number
    /// @param y uint256 value
    /// @return signed 64.64-bit fixed point number
    function pow(int128 x, uint256 y) internal pure returns (int128) {
        unchecked {
            bool negative = x < 0 && y & 1 == 1;

            uint256 absX = uint128(x < 0 ? -x : x);
            uint256 absResult;
            absResult = 0x100000000000000000000000000000000;

            if (absX <= 0x10000000000000000) {
                absX <<= 63;
                while (y != 0) {
                    if (y & 0x1 != 0) {
                        absResult = (absResult * absX) >> 127;
                    }
                    absX = (absX * absX) >> 127;

                    if (y & 0x2 != 0) {
                        absResult = (absResult * absX) >> 127;
                    }
                    absX = (absX * absX) >> 127;

                    if (y & 0x4 != 0) {
                        absResult = (absResult * absX) >> 127;
                    }
                    absX = (absX * absX) >> 127;

                    if (y & 0x8 != 0) {
                        absResult = (absResult * absX) >> 127;
                    }
                    absX = (absX * absX) >> 127;

                    y >>= 4;
                }

                absResult >>= 64;
            } else {
                uint256 absXShift = 63;
                if (absX < 0x1000000000000000000000000) {
                    absX <<= 32;
                    absXShift -= 32;
                }
                if (absX < 0x10000000000000000000000000000) {
                    absX <<= 16;
                    absXShift -= 16;
                }
                if (absX < 0x1000000000000000000000000000000) {
                    absX <<= 8;
                    absXShift -= 8;
                }
                if (absX < 0x10000000000000000000000000000000) {
                    absX <<= 4;
                    absXShift -= 4;
                }
                if (absX < 0x40000000000000000000000000000000) {
                    absX <<= 2;
                    absXShift -= 2;
                }
                if (absX < 0x80000000000000000000000000000000) {
                    absX <<= 1;
                    absXShift -= 1;
                }

                uint256 resultShift = 0;
                while (y != 0) {
                    require(absXShift < 64);

                    if (y & 0x1 != 0) {
                        absResult = (absResult * absX) >> 127;
                        resultShift += absXShift;
                        if (absResult > 0x100000000000000000000000000000000) {
                            absResult >>= 1;
                            resultShift += 1;
                        }
                    }
                    absX = (absX * absX) >> 127;
                    absXShift <<= 1;
                    if (absX >= 0x100000000000000000000000000000000) {
                        absX >>= 1;
                        absXShift += 1;
                    }

                    y >>= 1;
                }

                require(resultShift < 64);
                absResult >>= 64 - resultShift;
            }
            int256 result = negative ? -int256(absResult) : int256(absResult);
            require(result >= MIN_64x64 && result <= MAX_64x64);
            return int128(result);
        }
    }

    /// @dev Calculate sqrt (x) rounding down.  Revert if x < 0.
    /// @param x signed 64.64-bit fixed point number
    /// @return signed 64.64-bit fixed point number
    function sqrt(int128 x) internal pure returns (int128) {
        unchecked {
            require(x >= 0);
            return int128(sqrtu(uint256(int256(x)) << 64));
        }
    }

    /// @dev Calculate binary logarithm of x.  Revert if x <= 0.
    /// @param x signed 64.64-bit fixed point number
    /// @return signed 64.64-bit fixed point number
    function log_2(int128 x) internal pure returns (int128) {
        unchecked {
            require(x > 0);

            int256 msb = 0;
            int256 xc = x;
            if (xc >= 0x10000000000000000) {
                xc >>= 64;
                msb += 64;
            }
            if (xc >= 0x100000000) {
                xc >>= 32;
                msb += 32;
            }
            if (xc >= 0x10000) {
                xc >>= 16;
                msb += 16;
            }
            if (xc >= 0x100) {
                xc >>= 8;
                msb += 8;
            }
            if (xc >= 0x10) {
                xc >>= 4;
                msb += 4;
            }
            if (xc >= 0x4) {
                xc >>= 2;
                msb += 2;
            }
            if (xc >= 0x2) msb += 1; // No need to shift xc anymore

            int256 result = (msb - 64) << 64;
            uint256 ux = uint256(int256(x)) << uint256(127 - msb);
            for (int256 bit = 0x8000000000000000; bit > 0; bit >>= 1) {
                ux *= ux;
                uint256 b = ux >> 255;
                ux >>= 127 + b;
                result += bit * int256(b);
            }

            return int128(result);
        }
    }

    /// @dev Calculate natural logarithm of x.  Revert if x <= 0.
    /// @param x signed 64.64-bit fixed point number
    /// @return signed 64.64-bit fixed point number
    function ln(int128 x) internal pure returns (int128) {
        unchecked {
            require(x > 0);

            return
                int128(
                    int256(
                        (uint256(int256(log_2(x))) *
                            0xB17217F7D1CF79ABC9E3B39803F2F6AF) >> 128
                    )
                );
        }
    }

    /// @dev Calculate binary exponent of x.  Revert on overflow.
    /// @param x signed 64.64-bit fixed point number
    /// @return signed 64.64-bit fixed point number
    function exp_2(int128 x) internal pure returns (int128) {
        unchecked {
            require(x < 0x400000000000000000); // Overflow

            if (x < -0x400000000000000000) return 0; // Underflow

            uint256 result = 0x80000000000000000000000000000000;

            if (x & 0x8000000000000000 > 0)
                result = (result * 0x16A09E667F3BCC908B2FB1366EA957D3E) >> 128;
            if (x & 0x4000000000000000 > 0)
                result = (result * 0x1306FE0A31B7152DE8D5A46305C85EDEC) >> 128;
            if (x & 0x2000000000000000 > 0)
                result = (result * 0x1172B83C7D517ADCDF7C8C50EB14A791F) >> 128;
            if (x & 0x1000000000000000 > 0)
                result = (result * 0x10B5586CF9890F6298B92B71842A98363) >> 128;
            if (x & 0x800000000000000 > 0)
                result = (result * 0x1059B0D31585743AE7C548EB68CA417FD) >> 128;
            if (x & 0x400000000000000 > 0)
                result = (result * 0x102C9A3E778060EE6F7CACA4F7A29BDE8) >> 128;
            if (x & 0x200000000000000 > 0)
                result = (result * 0x10163DA9FB33356D84A66AE336DCDFA3F) >> 128;
            if (x & 0x100000000000000 > 0)
                result = (result * 0x100B1AFA5ABCBED6129AB13EC11DC9543) >> 128;
            if (x & 0x80000000000000 > 0)
                result = (result * 0x10058C86DA1C09EA1FF19D294CF2F679B) >> 128;
            if (x & 0x40000000000000 > 0)
                result = (result * 0x1002C605E2E8CEC506D21BFC89A23A00F) >> 128;
            if (x & 0x20000000000000 > 0)
                result = (result * 0x100162F3904051FA128BCA9C55C31E5DF) >> 128;
            if (x & 0x10000000000000 > 0)
                result = (result * 0x1000B175EFFDC76BA38E31671CA939725) >> 128;
            if (x & 0x8000000000000 > 0)
                result = (result * 0x100058BA01FB9F96D6CACD4B180917C3D) >> 128;
            if (x & 0x4000000000000 > 0)
                result = (result * 0x10002C5CC37DA9491D0985C348C68E7B3) >> 128;
            if (x & 0x2000000000000 > 0)
                result = (result * 0x1000162E525EE054754457D5995292026) >> 128;
            if (x & 0x1000000000000 > 0)
                result = (result * 0x10000B17255775C040618BF4A4ADE83FC) >> 128;
            if (x & 0x800000000000 > 0)
                result = (result * 0x1000058B91B5BC9AE2EED81E9B7D4CFAB) >> 128;
            if (x & 0x400000000000 > 0)
                result = (result * 0x100002C5C89D5EC6CA4D7C8ACC017B7C9) >> 128;
            if (x & 0x200000000000 > 0)
                result = (result * 0x10000162E43F4F831060E02D839A9D16D) >> 128;
            if (x & 0x100000000000 > 0)
                result = (result * 0x100000B1721BCFC99D9F890EA06911763) >> 128;
            if (x & 0x80000000000 > 0)
                result = (result * 0x10000058B90CF1E6D97F9CA14DBCC1628) >> 128;
            if (x & 0x40000000000 > 0)
                result = (result * 0x1000002C5C863B73F016468F6BAC5CA2B) >> 128;
            if (x & 0x20000000000 > 0)
                result = (result * 0x100000162E430E5A18F6119E3C02282A5) >> 128;
            if (x & 0x10000000000 > 0)
                result = (result * 0x1000000B1721835514B86E6D96EFD1BFE) >> 128;
            if (x & 0x8000000000 > 0)
                result = (result * 0x100000058B90C0B48C6BE5DF846C5B2EF) >> 128;
            if (x & 0x4000000000 > 0)
                result = (result * 0x10000002C5C8601CC6B9E94213C72737A) >> 128;
            if (x & 0x2000000000 > 0)
                result = (result * 0x1000000162E42FFF037DF38AA2B219F06) >> 128;
            if (x & 0x1000000000 > 0)
                result = (result * 0x10000000B17217FBA9C739AA5819F44F9) >> 128;
            if (x & 0x800000000 > 0)
                result = (result * 0x1000000058B90BFCDEE5ACD3C1CEDC823) >> 128;
            if (x & 0x400000000 > 0)
                result = (result * 0x100000002C5C85FE31F35A6A30DA1BE50) >> 128;
            if (x & 0x200000000 > 0)
                result = (result * 0x10000000162E42FF0999CE3541B9FFFCF) >> 128;
            if (x & 0x100000000 > 0)
                result = (result * 0x100000000B17217F80F4EF5AADDA45554) >> 128;
            if (x & 0x80000000 > 0)
                result = (result * 0x10000000058B90BFBF8479BD5A81B51AD) >> 128;
            if (x & 0x40000000 > 0)
                result = (result * 0x1000000002C5C85FDF84BD62AE30A74CC) >> 128;
            if (x & 0x20000000 > 0)
                result = (result * 0x100000000162E42FEFB2FED257559BDAA) >> 128;
            if (x & 0x10000000 > 0)
                result = (result * 0x1000000000B17217F7D5A7716BBA4A9AE) >> 128;
            if (x & 0x8000000 > 0)
                result = (result * 0x100000000058B90BFBE9DDBAC5E109CCE) >> 128;
            if (x & 0x4000000 > 0)
                result = (result * 0x10000000002C5C85FDF4B15DE6F17EB0D) >> 128;
            if (x & 0x2000000 > 0)
                result = (result * 0x1000000000162E42FEFA494F1478FDE05) >> 128;
            if (x & 0x1000000 > 0)
                result = (result * 0x10000000000B17217F7D20CF927C8E94C) >> 128;
            if (x & 0x800000 > 0)
                result = (result * 0x1000000000058B90BFBE8F71CB4E4B33D) >> 128;
            if (x & 0x400000 > 0)
                result = (result * 0x100000000002C5C85FDF477B662B26945) >> 128;
            if (x & 0x200000 > 0)
                result = (result * 0x10000000000162E42FEFA3AE53369388C) >> 128;
            if (x & 0x100000 > 0)
                result = (result * 0x100000000000B17217F7D1D351A389D40) >> 128;
            if (x & 0x80000 > 0)
                result = (result * 0x10000000000058B90BFBE8E8B2D3D4EDE) >> 128;
            if (x & 0x40000 > 0)
                result = (result * 0x1000000000002C5C85FDF4741BEA6E77E) >> 128;
            if (x & 0x20000 > 0)
                result = (result * 0x100000000000162E42FEFA39FE95583C2) >> 128;
            if (x & 0x10000 > 0)
                result = (result * 0x1000000000000B17217F7D1CFB72B45E1) >> 128;
            if (x & 0x8000 > 0)
                result = (result * 0x100000000000058B90BFBE8E7CC35C3F0) >> 128;
            if (x & 0x4000 > 0)
                result = (result * 0x10000000000002C5C85FDF473E242EA38) >> 128;
            if (x & 0x2000 > 0)
                result = (result * 0x1000000000000162E42FEFA39F02B772C) >> 128;
            if (x & 0x1000 > 0)
                result = (result * 0x10000000000000B17217F7D1CF7D83C1A) >> 128;
            if (x & 0x800 > 0)
                result = (result * 0x1000000000000058B90BFBE8E7BDCBE2E) >> 128;
            if (x & 0x400 > 0)
                result = (result * 0x100000000000002C5C85FDF473DEA871F) >> 128;
            if (x & 0x200 > 0)
                result = (result * 0x10000000000000162E42FEFA39EF44D91) >> 128;
            if (x & 0x100 > 0)
                result = (result * 0x100000000000000B17217F7D1CF79E949) >> 128;
            if (x & 0x80 > 0)
                result = (result * 0x10000000000000058B90BFBE8E7BCE544) >> 128;
            if (x & 0x40 > 0)
                result = (result * 0x1000000000000002C5C85FDF473DE6ECA) >> 128;
            if (x & 0x20 > 0)
                result = (result * 0x100000000000000162E42FEFA39EF366F) >> 128;
            if (x & 0x10 > 0)
                result = (result * 0x1000000000000000B17217F7D1CF79AFA) >> 128;
            if (x & 0x8 > 0)
                result = (result * 0x100000000000000058B90BFBE8E7BCD6D) >> 128;
            if (x & 0x4 > 0)
                result = (result * 0x10000000000000002C5C85FDF473DE6B2) >> 128;
            if (x & 0x2 > 0)
                result = (result * 0x1000000000000000162E42FEFA39EF358) >> 128;
            if (x & 0x1 > 0)
                result = (result * 0x10000000000000000B17217F7D1CF79AB) >> 128;

            result >>= uint256(int256(63 - (x >> 64)));
            require(result <= uint256(int256(MAX_64x64)));

            return int128(int256(result));
        }
    }

    /// @dev Calculate natural exponent of x.  Revert on overflow.
    /// @param x signed 64.64-bit fixed point number
    /// @return signed 64.64-bit fixed point number
    function exp(int128 x) internal pure returns (int128) {
        unchecked {
            require(x < 0x400000000000000000); // Overflow

            if (x < -0x400000000000000000) return 0; // Underflow

            return
                exp_2(
                    int128(
                        (int256(x) * 0x171547652B82FE1777D0FFDA0D23A7D12) >> 128
                    )
                );
        }
    }

    /// @dev Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
    /// integer numbers.  Revert on overflow or when y is zero.
    /// @param x unsigned 256-bit integer number
    /// @param y unsigned 256-bit integer number
    /// @return unsigned 64.64-bit fixed point number
    function divuu(uint256 x, uint256 y) internal pure returns (uint128) {
        // ^^ changed visibility from private to internal for testing
        unchecked {
            require(y != 0);

            uint256 result;

            if (x <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
                result = (x << 64) / y;
            else {
                uint256 msb = 192;
                uint256 xc = x >> 192;
                if (xc >= 0x100000000) {
                    xc >>= 32;
                    msb += 32;
                }
                if (xc >= 0x10000) {
                    xc >>= 16;
                    msb += 16;
                }
                if (xc >= 0x100) {
                    xc >>= 8;
                    msb += 8;
                }
                if (xc >= 0x10) {
                    xc >>= 4;
                    msb += 4;
                }
                if (xc >= 0x4) {
                    xc >>= 2;
                    msb += 2;
                }
                if (xc >= 0x2) msb += 1; // No need to shift xc anymore

                result = (x << (255 - msb)) / (((y - 1) >> (msb - 191)) + 1);
                require(result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

                uint256 hi = result * (y >> 128);
                uint256 lo = result * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

                uint256 xh = x >> 192;
                uint256 xl = x << 64;

                if (xl < lo) xh -= 1;
                xl -= lo; // We rely on overflow behavior here
                lo = hi << 128;
                if (xl < lo) xh -= 1;
                xl -= lo; // We rely on overflow behavior here

                assert(xh == hi >> 128);

                result += xl / y;
            }

            require(result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
            return uint128(result);
        }
    }

    /// @dev Calculate sqrt (x) rounding down, where x is unsigned 256-bit integer number.
    /// @param x unsigned 256-bit integer number
    /// @return unsigned 128-bit integer number
    function sqrtu(uint256 x) internal pure returns (uint128) {
        // ^^ changed visibility from private to internal for testing

        unchecked {
            if (x == 0) return 0;
            else {
                uint256 xx = x;
                uint256 r = 1;
                if (xx >= 0x100000000000000000000000000000000) {
                    xx >>= 128;
                    r <<= 64;
                }
                if (xx >= 0x10000000000000000) {
                    xx >>= 64;
                    r <<= 32;
                }
                if (xx >= 0x100000000) {
                    xx >>= 32;
                    r <<= 16;
                }
                if (xx >= 0x10000) {
                    xx >>= 16;
                    r <<= 8;
                }
                if (xx >= 0x100) {
                    xx >>= 8;
                    r <<= 4;
                }
                if (xx >= 0x10) {
                    xx >>= 4;
                    r <<= 2;
                }
                if (xx >= 0x8) {
                    r <<= 1;
                }
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1; // Seven iterations should be enough
                uint256 r1 = x / r;
                return uint128(r < r1 ? r : r1);
            }
        }
    }
}

library Exp64x64 {
    using Math64x64 for int128;

    /// @dev Raises a 64.64 number to the power of another 64.64 number
    /// x^y = 2^(y*log_2(x))
    /// https://ethereum.stackexchange.com/questions/79903/exponential-function-with-fractional-numbers
    function pow(int128 x, int128 y) internal pure returns (int128) {
        return y.mul(x.log_2()).exp_2();
    }

    /* Mikhail Vladimirov, [Jul 6, 2022 at 12:26:12 PM (Jul 6, 2022 at 12:28:29 PM)]:
        In simple words, when have an n-bits wide number x and raise it to a power α, then the result would be α*n bits wide.  This, if α<1, the result will loose precision, and if α>1, the result could exceed range.

        So, the pow function multiplies the result by 2^(n * (1 - α)).  We have:

        x ∈ [0; 2^n)
        x^α ∈ [0; 2^(α*n))
        x^α * 2^(n * (1 - α)) ∈ [0; 2^(α*n) * 2^(n * (1 - α))) = [0; 2^(α*n + n * (1 - α))) = [0; 2^(n * (α +  (1 - α)))) =  [0; 2^n)

        So the normalization returns the result back into the proper range.

        Now note, that:

        pow (pow (x, α), 1/α) =
        pow (x^α * 2^(n * (1 -α)) , 1/α) =
        (x^α * 2^(n * (1 -α)))^(1/α) * 2^(n * (1 -1/α)) =
        x^(α * (1/α)) * 2^(n * (1 -α) * (1/α)) * 2^(n * (1 -1/α)) =
        x * 2^(n * (1/α -1)) * 2^(n * (1 -1/α)) =
        x * 2^(n * (1/α -1) + n * (1 -1/α)) =
        x

        So, for formulas that look like:

        (a x^α + b y^α + ...)^(1/α)

        The pow function could be used instead of normal power. */
    /// @dev Raise given number x into power specified as a simple fraction y/z and then
    /// multiply the result by the normalization factor 2^(128 /// (1 - y/z)).
    /// Revert if z is zero, or if both x and y are zeros.
    /// @param x number to raise into given power y/z -- integer
    /// @param y numerator of the power to raise x into  -- 64.64
    /// @param z denominator of the power to raise x into  -- 64.64
    /// @return x raised into power y/z and then multiplied by 2^(128 * (1 - y/z)) -- integer
    function pow(
        uint128 x,
        uint128 y,
        uint128 z
    ) internal pure returns (uint128) {
        unchecked {
            require(z != 0);

            if (x == 0) {
                require(y != 0);
                return 0;
            } else {
                uint256 l = (uint256(
                    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF - log_2(x)
                ) * y) / z;
                if (l > 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF) return 0;
                else
                    return
                        pow_2(uint128(0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF - l));
            }
        }
    }

    /// @dev Calculate base 2 logarithm of an unsigned 128-bit integer number.  Revert
    /// in case x is zero.
    /// @param x number to calculate base 2 logarithm of
    /// @return base 2 logarithm of x, multiplied by 2^121
    function log_2(uint128 x) internal pure returns (uint128) {
        unchecked {
            require(x != 0);

            uint256 b = x;

            uint256 l = 0xFE000000000000000000000000000000;

            if (b < 0x10000000000000000) {
                l -= 0x80000000000000000000000000000000;
                b <<= 64;
            }
            if (b < 0x1000000000000000000000000) {
                l -= 0x40000000000000000000000000000000;
                b <<= 32;
            }
            if (b < 0x10000000000000000000000000000) {
                l -= 0x20000000000000000000000000000000;
                b <<= 16;
            }
            if (b < 0x1000000000000000000000000000000) {
                l -= 0x10000000000000000000000000000000;
                b <<= 8;
            }
            if (b < 0x10000000000000000000000000000000) {
                l -= 0x8000000000000000000000000000000;
                b <<= 4;
            }
            if (b < 0x40000000000000000000000000000000) {
                l -= 0x4000000000000000000000000000000;
                b <<= 2;
            }
            if (b < 0x80000000000000000000000000000000) {
                l -= 0x2000000000000000000000000000000;
                b <<= 1;
            }

            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x1000000000000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x800000000000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x400000000000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x200000000000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x100000000000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x80000000000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x40000000000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x20000000000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x10000000000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x8000000000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x4000000000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x2000000000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x1000000000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x800000000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x400000000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x200000000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x100000000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x80000000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x40000000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x20000000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x10000000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x8000000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x4000000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x2000000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x1000000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x800000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x400000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x200000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x100000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x80000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x40000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x20000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x10000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x8000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x4000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x2000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x1000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x800000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x400000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x200000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x100000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x80000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x40000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x20000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x10000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x8000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x4000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x2000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x1000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x800000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x400000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x200000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x100000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x80000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x40000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x20000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x10000000000000000;
            } /*
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x8000000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x4000000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x2000000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x1000000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x800000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x400000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x200000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x100000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x80000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x40000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x20000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x10000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x8000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x4000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x2000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x1000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x800000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x400000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x200000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x100000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x80000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x40000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x20000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x10000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x8000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x4000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x2000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x1000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x800000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x400000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x200000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x100000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x80000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x40000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x20000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x10000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x8000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x4000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x2000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x1000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x800000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x400000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x200000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x100000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x80000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x40000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x20000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x10000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x8000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x4000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x2000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x1000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x800;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x400;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x200;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x100;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x80;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x40;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x20;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x10;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x8;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x4;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x2;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) l |= 0x1; */

            return uint128(l);
        }
    }

    /// @dev Calculate 2 raised into given power.
    /// @param x power to raise 2 into, multiplied by 2^121
    /// @return 2 raised into given power
    function pow_2(uint128 x) internal pure returns (uint128) {
        unchecked {
            uint256 r = 0x80000000000000000000000000000000;
            if (x & 0x1000000000000000000000000000000 > 0)
                r = (r * 0xb504f333f9de6484597d89b3754abe9f) >> 127;
            if (x & 0x800000000000000000000000000000 > 0)
                r = (r * 0x9837f0518db8a96f46ad23182e42f6f6) >> 127;
            if (x & 0x400000000000000000000000000000 > 0)
                r = (r * 0x8b95c1e3ea8bd6e6fbe4628758a53c90) >> 127;
            if (x & 0x200000000000000000000000000000 > 0)
                r = (r * 0x85aac367cc487b14c5c95b8c2154c1b2) >> 127;
            if (x & 0x100000000000000000000000000000 > 0)
                r = (r * 0x82cd8698ac2ba1d73e2a475b46520bff) >> 127;
            if (x & 0x80000000000000000000000000000 > 0)
                r = (r * 0x8164d1f3bc0307737be56527bd14def4) >> 127;
            if (x & 0x40000000000000000000000000000 > 0)
                r = (r * 0x80b1ed4fd999ab6c25335719b6e6fd20) >> 127;
            if (x & 0x20000000000000000000000000000 > 0)
                r = (r * 0x8058d7d2d5e5f6b094d589f608ee4aa2) >> 127;
            if (x & 0x10000000000000000000000000000 > 0)
                r = (r * 0x802c6436d0e04f50ff8ce94a6797b3ce) >> 127;
            if (x & 0x8000000000000000000000000000 > 0)
                r = (r * 0x8016302f174676283690dfe44d11d008) >> 127;
            if (x & 0x4000000000000000000000000000 > 0)
                r = (r * 0x800b179c82028fd0945e54e2ae18f2f0) >> 127;
            if (x & 0x2000000000000000000000000000 > 0)
                r = (r * 0x80058baf7fee3b5d1c718b38e549cb93) >> 127;
            if (x & 0x1000000000000000000000000000 > 0)
                r = (r * 0x8002c5d00fdcfcb6b6566a58c048be1f) >> 127;
            if (x & 0x800000000000000000000000000 > 0)
                r = (r * 0x800162e61bed4a48e84c2e1a463473d9) >> 127;
            if (x & 0x400000000000000000000000000 > 0)
                r = (r * 0x8000b17292f702a3aa22beacca949013) >> 127;
            if (x & 0x200000000000000000000000000 > 0)
                r = (r * 0x800058b92abbae02030c5fa5256f41fe) >> 127;
            if (x & 0x100000000000000000000000000 > 0)
                r = (r * 0x80002c5c8dade4d71776c0f4dbea67d6) >> 127;
            if (x & 0x80000000000000000000000000 > 0)
                r = (r * 0x8000162e44eaf636526be456600bdbe4) >> 127;
            if (x & 0x40000000000000000000000000 > 0)
                r = (r * 0x80000b1721fa7c188307016c1cd4e8b6) >> 127;
            if (x & 0x20000000000000000000000000 > 0)
                r = (r * 0x8000058b90de7e4cecfc487503488bb1) >> 127;
            if (x & 0x10000000000000000000000000 > 0)
                r = (r * 0x800002c5c8678f36cbfce50a6de60b14) >> 127;
            if (x & 0x8000000000000000000000000 > 0)
                r = (r * 0x80000162e431db9f80b2347b5d62e516) >> 127;
            if (x & 0x4000000000000000000000000 > 0)
                r = (r * 0x800000b1721872d0c7b08cf1e0114152) >> 127;
            if (x & 0x2000000000000000000000000 > 0)
                r = (r * 0x80000058b90c1aa8a5c3736cb77e8dff) >> 127;
            if (x & 0x1000000000000000000000000 > 0)
                r = (r * 0x8000002c5c8605a4635f2efc2362d978) >> 127;
            if (x & 0x800000000000000000000000 > 0)
                r = (r * 0x800000162e4300e635cf4a109e3939bd) >> 127;
            if (x & 0x400000000000000000000000 > 0)
                r = (r * 0x8000000b17217ff81bef9c551590cf83) >> 127;
            if (x & 0x200000000000000000000000 > 0)
                r = (r * 0x800000058b90bfdd4e39cd52c0cfa27c) >> 127;
            if (x & 0x100000000000000000000000 > 0)
                r = (r * 0x80000002c5c85fe6f72d669e0e76e411) >> 127;
            if (x & 0x80000000000000000000000 > 0)
                r = (r * 0x8000000162e42ff18f9ad35186d0df28) >> 127;
            if (x & 0x40000000000000000000000 > 0)
                r = (r * 0x80000000b17217f84cce71aa0dcfffe7) >> 127;
            if (x & 0x20000000000000000000000 > 0)
                r = (r * 0x8000000058b90bfc07a77ad56ed22aaa) >> 127;
            if (x & 0x10000000000000000000000 > 0)
                r = (r * 0x800000002c5c85fdfc23cdead40da8d6) >> 127;
            if (x & 0x8000000000000000000000 > 0)
                r = (r * 0x80000000162e42fefc25eb1571853a66) >> 127;
            if (x & 0x4000000000000000000000 > 0)
                r = (r * 0x800000000b17217f7d97f692baacded5) >> 127;
            if (x & 0x2000000000000000000000 > 0)
                r = (r * 0x80000000058b90bfbead3b8b5dd254d7) >> 127;
            if (x & 0x1000000000000000000000 > 0)
                r = (r * 0x8000000002c5c85fdf4eedd62f084e67) >> 127;
            if (x & 0x800000000000000000000 > 0)
                r = (r * 0x800000000162e42fefa58aef378bf586) >> 127;
            if (x & 0x400000000000000000000 > 0)
                r = (r * 0x8000000000b17217f7d24a78a3c7ef02) >> 127;
            if (x & 0x200000000000000000000 > 0)
                r = (r * 0x800000000058b90bfbe9067c93e474a6) >> 127;
            if (x & 0x100000000000000000000 > 0)
                r = (r * 0x80000000002c5c85fdf47b8e5a72599f) >> 127;
            if (x & 0x80000000000000000000 > 0)
                r = (r * 0x8000000000162e42fefa3bdb315934a2) >> 127;
            if (x & 0x40000000000000000000 > 0)
                r = (r * 0x80000000000b17217f7d1d7299b49c46) >> 127;
            if (x & 0x20000000000000000000 > 0)
                r = (r * 0x8000000000058b90bfbe8e9a8d1c4ea0) >> 127;
            if (x & 0x10000000000000000000 > 0)
                r = (r * 0x800000000002c5c85fdf4745969ea76f) >> 127;
            if (x & 0x8000000000000000000 > 0)
                r = (r * 0x80000000000162e42fefa3a0df5373bf) >> 127;
            if (x & 0x4000000000000000000 > 0)
                r = (r * 0x800000000000b17217f7d1cff4aac1e1) >> 127;
            if (x & 0x2000000000000000000 > 0)
                r = (r * 0x80000000000058b90bfbe8e7db95a2f1) >> 127;
            if (x & 0x1000000000000000000 > 0)
                r = (r * 0x8000000000002c5c85fdf473e61ae1f8) >> 127;
            if (x & 0x800000000000000000 > 0)
                r = (r * 0x800000000000162e42fefa39f121751c) >> 127;
            if (x & 0x400000000000000000 > 0)
                r = (r * 0x8000000000000b17217f7d1cf815bb96) >> 127;
            if (x & 0x200000000000000000 > 0)
                r = (r * 0x800000000000058b90bfbe8e7bec1e0d) >> 127;
            if (x & 0x100000000000000000 > 0)
                r = (r * 0x80000000000002c5c85fdf473dee5f17) >> 127;
            if (x & 0x80000000000000000 > 0)
                r = (r * 0x8000000000000162e42fefa39ef5438f) >> 127;
            if (x & 0x40000000000000000 > 0)
                r = (r * 0x80000000000000b17217f7d1cf7a26c8) >> 127;
            if (x & 0x20000000000000000 > 0)
                r = (r * 0x8000000000000058b90bfbe8e7bcf4a4) >> 127;
            if (x & 0x10000000000000000 > 0)
                r = (r * 0x800000000000002c5c85fdf473de72a2) >> 127; /*
      if(x & 0x8000000000000000 > 0) r = r * 0x80000000000000162e42fefa39ef3765 >> 127;
      if(x & 0x4000000000000000 > 0) r = r * 0x800000000000000b17217f7d1cf79b37 >> 127;
      if(x & 0x2000000000000000 > 0) r = r * 0x80000000000000058b90bfbe8e7bcd7d >> 127;
      if(x & 0x1000000000000000 > 0) r = r * 0x8000000000000002c5c85fdf473de6b6 >> 127;
      if(x & 0x800000000000000 > 0) r = r * 0x800000000000000162e42fefa39ef359 >> 127;
      if(x & 0x400000000000000 > 0) r = r * 0x8000000000000000b17217f7d1cf79ac >> 127;
      if(x & 0x200000000000000 > 0) r = r * 0x800000000000000058b90bfbe8e7bcd6 >> 127;
      if(x & 0x100000000000000 > 0) r = r * 0x80000000000000002c5c85fdf473de6a >> 127;
      if(x & 0x80000000000000 > 0) r = r * 0x8000000000000000162e42fefa39ef35 >> 127;
      if(x & 0x40000000000000 > 0) r = r * 0x80000000000000000b17217f7d1cf79a >> 127;
      if(x & 0x20000000000000 > 0) r = r * 0x8000000000000000058b90bfbe8e7bcd >> 127;
      if(x & 0x10000000000000 > 0) r = r * 0x800000000000000002c5c85fdf473de6 >> 127;
      if(x & 0x8000000000000 > 0) r = r * 0x80000000000000000162e42fefa39ef3 >> 127;
      if(x & 0x4000000000000 > 0) r = r * 0x800000000000000000b17217f7d1cf79 >> 127;
      if(x & 0x2000000000000 > 0) r = r * 0x80000000000000000058b90bfbe8e7bc >> 127;
      if(x & 0x1000000000000 > 0) r = r * 0x8000000000000000002c5c85fdf473de >> 127;
      if(x & 0x800000000000 > 0) r = r * 0x800000000000000000162e42fefa39ef >> 127;
      if(x & 0x400000000000 > 0) r = r * 0x8000000000000000000b17217f7d1cf7 >> 127;
      if(x & 0x200000000000 > 0) r = r * 0x800000000000000000058b90bfbe8e7b >> 127;
      if(x & 0x100000000000 > 0) r = r * 0x80000000000000000002c5c85fdf473d >> 127;
      if(x & 0x80000000000 > 0) r = r * 0x8000000000000000000162e42fefa39e >> 127;
      if(x & 0x40000000000 > 0) r = r * 0x80000000000000000000b17217f7d1cf >> 127;
      if(x & 0x20000000000 > 0) r = r * 0x8000000000000000000058b90bfbe8e7 >> 127;
      if(x & 0x10000000000 > 0) r = r * 0x800000000000000000002c5c85fdf473 >> 127;
      if(x & 0x8000000000 > 0) r = r * 0x80000000000000000000162e42fefa39 >> 127;
      if(x & 0x4000000000 > 0) r = r * 0x800000000000000000000b17217f7d1c >> 127;
      if(x & 0x2000000000 > 0) r = r * 0x80000000000000000000058b90bfbe8e >> 127;
      if(x & 0x1000000000 > 0) r = r * 0x8000000000000000000002c5c85fdf47 >> 127;
      if(x & 0x800000000 > 0) r = r * 0x800000000000000000000162e42fefa3 >> 127;
      if(x & 0x400000000 > 0) r = r * 0x8000000000000000000000b17217f7d1 >> 127;
      if(x & 0x200000000 > 0) r = r * 0x800000000000000000000058b90bfbe8 >> 127;
      if(x & 0x100000000 > 0) r = r * 0x80000000000000000000002c5c85fdf4 >> 127;
      if(x & 0x80000000 > 0) r = r * 0x8000000000000000000000162e42fefa >> 127;
      if(x & 0x40000000 > 0) r = r * 0x80000000000000000000000b17217f7d >> 127;
      if(x & 0x20000000 > 0) r = r * 0x8000000000000000000000058b90bfbe >> 127;
      if(x & 0x10000000 > 0) r = r * 0x800000000000000000000002c5c85fdf >> 127;
      if(x & 0x8000000 > 0) r = r * 0x80000000000000000000000162e42fef >> 127;
      if(x & 0x4000000 > 0) r = r * 0x800000000000000000000000b17217f7 >> 127;
      if(x & 0x2000000 > 0) r = r * 0x80000000000000000000000058b90bfb >> 127;
      if(x & 0x1000000 > 0) r = r * 0x8000000000000000000000002c5c85fd >> 127;
      if(x & 0x800000 > 0) r = r * 0x800000000000000000000000162e42fe >> 127;
      if(x & 0x400000 > 0) r = r * 0x8000000000000000000000000b17217f >> 127;
      if(x & 0x200000 > 0) r = r * 0x800000000000000000000000058b90bf >> 127;
      if(x & 0x100000 > 0) r = r * 0x80000000000000000000000002c5c85f >> 127;
      if(x & 0x80000 > 0) r = r * 0x8000000000000000000000000162e42f >> 127;
      if(x & 0x40000 > 0) r = r * 0x80000000000000000000000000b17217 >> 127;
      if(x & 0x20000 > 0) r = r * 0x8000000000000000000000000058b90b >> 127;
      if(x & 0x10000 > 0) r = r * 0x800000000000000000000000002c5c85 >> 127;
      if(x & 0x8000 > 0) r = r * 0x80000000000000000000000000162e42 >> 127;
      if(x & 0x4000 > 0) r = r * 0x800000000000000000000000000b1721 >> 127;
      if(x & 0x2000 > 0) r = r * 0x80000000000000000000000000058b90 >> 127;
      if(x & 0x1000 > 0) r = r * 0x8000000000000000000000000002c5c8 >> 127;
      if(x & 0x800 > 0) r = r * 0x800000000000000000000000000162e4 >> 127;
      if(x & 0x400 > 0) r = r * 0x8000000000000000000000000000b172 >> 127;
      if(x & 0x200 > 0) r = r * 0x800000000000000000000000000058b9 >> 127;
      if(x & 0x100 > 0) r = r * 0x80000000000000000000000000002c5c >> 127;
      if(x & 0x80 > 0) r = r * 0x8000000000000000000000000000162e >> 127;
      if(x & 0x40 > 0) r = r * 0x80000000000000000000000000000b17 >> 127;
      if(x & 0x20 > 0) r = r * 0x8000000000000000000000000000058b >> 127;
      if(x & 0x10 > 0) r = r * 0x800000000000000000000000000002c5 >> 127;
      if(x & 0x8 > 0) r = r * 0x80000000000000000000000000000162 >> 127;
      if(x & 0x4 > 0) r = r * 0x800000000000000000000000000000b1 >> 127;
      if(x & 0x2 > 0) r = r * 0x80000000000000000000000000000058 >> 127;
      if(x & 0x1 > 0) r = r * 0x8000000000000000000000000000002c >> 127; */

            r >>= 127 - (x >> 121);

            return uint128(r);
        }
    }
}

/// Ethereum smart contract library implementing Yield Math model with yield bearing tokens.
/// @dev see Mikhail Vladimirov (ABDK) explanations of the math: https://hackmd.io/gbnqA3gCTR6z-F0HHTxF-A#Yield-Math
library YieldMath {
    using Math64x64 for int128;
    using Math64x64 for uint128;
    using Math64x64 for int256;
    using Math64x64 for uint256;
    using Exp64x64 for uint128;
    using Exp64x64 for int128;
    using CastU256U128 for uint256;
    using CastU128I128 for uint128;

    uint128 public constant WAD = 1e18;
    uint128 public constant ONE = 0x10000000000000000; //   In 64.64
    uint256 public constant MAX = type(uint128).max; //     Used for overflow checks

    /* CORE FUNCTIONS
     ******************************************************************************************************************/

    /* ----------------------------------------------------------------------------------------------------------------
                                              ┌───────────────────────────────┐                    .-:::::::::::-.
      ┌──────────────┐                        │                               │                  .:::::::::::::::::.
      │$            $│                       \│                               │/                :  _______  __   __ :
      │ ┌────────────┴─┐                     \│                               │/               :: |       ||  | |  |::
      │ │$            $│                      │    fyTokenOutForSharesIn      │               ::: |    ___||  |_|  |:::
      │$│ ┌────────────┴─┐     ────────▶      │                               │  ────────▶    ::: |   |___ |       |:::
      └─┤ │$            $│                    │                               │               ::: |    ___||_     _|:::
        │$│  `sharesIn`  │                   /│                               │\              ::: |   |      |   |  :::
        └─┤              │                   /│                               │\               :: |___|      |___|  ::
          │$            $│                    │                      \(^o^)/  │                 :       ????        :
          └──────────────┘                    │                     YieldMath │                  `:::::::::::::::::'
                                              └───────────────────────────────┘                    `-:::::::::::-'
    */
    /// Calculates the amount of fyToken a user would get for given amount of shares.
    /// https://docs.google.com/spreadsheets/d/14K_McZhlgSXQfi6nFGwDvDh4BmOu6_Hczi_sFreFfOE/
    /// @param sharesReserves yield bearing vault shares reserve amount
    /// @param fyTokenReserves fyToken reserves amount
    /// @param sharesIn shares amount to be traded
    /// @param timeTillMaturity time till maturity in seconds e.g. 90 days in seconds
    /// @param k time till maturity coefficient, multiplied by 2^64.  e.g. 25 years in seconds
    /// @param g fee coefficient, multiplied by 2^64 -- sb under 1.0 for selling shares to pool
    /// @param c price of shares in terms of their base, multiplied by 2^64
    /// @param mu (μ) Normalization factor -- starts as c at initialization
    /// @return fyTokenOut the amount of fyToken a user would get for given amount of shares
    function fyTokenOutForSharesIn(
        uint128 sharesReserves, // z
        uint128 fyTokenReserves, // x
        uint128 sharesIn, // x == Δz
        uint128 timeTillMaturity,
        int128 k,
        int128 g,
        int128 c,
        int128 mu
    ) public pure returns (uint128) {
        unchecked {
            require(c > 0 && mu > 0, 'YieldMath: c and mu must be positive');

            uint128 a = _computeA(timeTillMaturity, k, g);

            uint256 sum;
            {
                /* https://docs.google.com/spreadsheets/d/14K_McZhlgSXQfi6nFGwDvDh4BmOu6_Hczi_sFreFfOE/

                y = fyToken reserves
                z = shares reserves
                x = Δz (sharesIn)

                     y - (                         sum                           )^(   invA   )
                     y - ((    Za         ) + (  Ya  ) - (       Zxa           ) )^(   invA   )
                Δy = y - ( c/μ * (μz)^(1-t) +  y^(1-t) -  c/μ * (μz + μx)^(1-t)  )^(1 / (1 - t))

                */
                uint256 normalizedSharesReserves;
                require(
                    (normalizedSharesReserves = mu.mulu(sharesReserves)) <= MAX,
                    'YieldMath: Rate overflow (nsr)'
                );

                // za = c/μ * (normalizedSharesReserves ** a)
                // The “pow(x, y, z)” function not only calculates x^(y/z) but also normalizes the result to
                // fit into 64.64 fixed point number, i.e. it actually calculates: x^(y/z) * (2^63)^(1 - y/z)
                uint256 za;
                require(
                    (za = c.div(mu).mulu(
                        uint128(normalizedSharesReserves).pow(a, ONE)
                    )) <= MAX,
                    'YieldMath: Rate overflow (za)'
                );

                // ya = fyTokenReserves ** a
                // The “pow(x, y, z)” function not only calculates x^(y/z) but also normalizes the result to
                // fit into 64.64 fixed point number, i.e. it actually calculates: x^(y/z) * (2^63)^(1 - y/z)
                uint256 ya = fyTokenReserves.pow(a, ONE);

                // normalizedSharesIn = μ * sharesIn
                uint256 normalizedSharesIn;
                require(
                    (normalizedSharesIn = mu.mulu(sharesIn)) <= MAX,
                    'YieldMath: Rate overflow (nsi)'
                );

                // zx = normalizedSharesReserves + sharesIn * μ
                uint256 zx;
                require(
                    (zx = normalizedSharesReserves + normalizedSharesIn) <= MAX,
                    'YieldMath: Too many shares in'
                );

                // zxa = c/μ * zx ** a
                // The “pow(x, y, z)” function not only calculates x^(y/z) but also normalizes the result to
                // fit into 64.64 fixed point number, i.e. it actually calculates: x^(y/z) * (2^63)^(1 - y/z)
                uint256 zxa;
                require(
                    (zxa = c.div(mu).mulu(uint128(zx).pow(a, ONE))) <= MAX,
                    'YieldMath: Rate overflow (zxa)'
                );

                sum = za + ya - zxa;

                require(sum <= (za + ya), 'YieldMath: Sum underflow');
            }

            // result = fyTokenReserves - (sum ** (1/a))
            // The “pow(x, y, z)” function not only calculates x^(y/z) but also normalizes the result to
            // fit into 64.64 fixed point number, i.e. it actually calculates: x^(y/z) * (2^63)^(1 - y/z)
            uint256 fyTokenOut;
            require(
                (fyTokenOut =
                    uint256(fyTokenReserves) -
                    sum.u128().pow(ONE, a)) <= MAX,
                'YieldMath: Rounding error'
            );

            require(
                fyTokenOut <= fyTokenReserves,
                'YieldMath: > fyToken reserves'
            );

            return uint128(fyTokenOut);
        }
    }

    /* ----------------------------------------------------------------------------------------------------------------
          .-:::::::::::-.                       ┌───────────────────────────────┐
        .:::::::::::::::::.                     │                               │
       :  _______  __   __ :                   \│                               │/              ┌──────────────┐
      :: |       ||  | |  |::                  \│                               │/              │$            $│
     ::: |    ___||  |_|  |:::                  │    sharesOutForFYTokenIn      │               │ ┌────────────┴─┐
     ::: |   |___ |       |:::   ────────▶      │                               │  ────────▶    │ │$            $│
     ::: |    ___||_     _|:::                  │                               │               │$│ ┌────────────┴─┐
     ::: |   |      |   |  :::                 /│                               │\              └─┤ │$            $│
      :: |___|      |___|  ::                  /│                               │\                │$│    SHARES    │
       :     `fyTokenIn`   :                    │                      \(^o^)/  │                 └─┤     ????     │
        `:::::::::::::::::'                     │                     YieldMath │                   │$            $│
          `-:::::::::::-'                       └───────────────────────────────┘                   └──────────────┘
    */
    /// Calculates the amount of shares a user would get for certain amount of fyToken.
    /// @param sharesReserves shares reserves amount
    /// @param fyTokenReserves fyToken reserves amount
    /// @param fyTokenIn fyToken amount to be traded
    /// @param timeTillMaturity time till maturity in seconds
    /// @param k time till maturity coefficient, multiplied by 2^64
    /// @param g fee coefficient, multiplied by 2^64
    /// @param c price of shares in terms of Dai, multiplied by 2^64
    /// @param mu (μ) Normalization factor -- starts as c at initialization
    /// @return amount of Shares a user would get for given amount of fyToken
    function sharesOutForFYTokenIn(
        uint128 sharesReserves,
        uint128 fyTokenReserves,
        uint128 fyTokenIn,
        uint128 timeTillMaturity,
        int128 k,
        int128 g,
        int128 c,
        int128 mu
    ) public pure returns (uint128) {
        unchecked {
            require(c > 0 && mu > 0, 'YieldMath: c and mu must be positive');
            return
                _sharesOutForFYTokenIn(
                    sharesReserves,
                    fyTokenReserves,
                    fyTokenIn,
                    _computeA(timeTillMaturity, k, g),
                    c,
                    mu
                );
        }
    }

    /// @dev Splitting sharesOutForFYTokenIn in two functions to avoid stack depth limits.
    function _sharesOutForFYTokenIn(
        uint128 sharesReserves,
        uint128 fyTokenReserves,
        uint128 fyTokenIn,
        uint128 a,
        int128 c,
        int128 mu
    ) private pure returns (uint128) {
        /* https://docs.google.com/spreadsheets/d/14K_McZhlgSXQfi6nFGwDvDh4BmOu6_Hczi_sFreFfOE/

            y = fyToken reserves
            z = shares reserves
            x = Δy (fyTokenIn)

                 z - (                                rightTerm                                              )
                 z - (invMu) * (      Za              ) + ( Ya   ) - (    Yxa      ) / (c / μ) )^(   invA    )
            Δz = z -   1/μ   * ( ( (c / μ) * (μz)^(1-t) +  y^(1-t) - (y + x)^(1-t) ) / (c / μ) )^(1 / (1 - t))

        */
        unchecked {
            // normalizedSharesReserves = μ * sharesReserves
            uint256 normalizedSharesReserves;
            require(
                (normalizedSharesReserves = mu.mulu(sharesReserves)) <= MAX,
                'YieldMath: Rate overflow (nsr)'
            );

            uint128 rightTerm;
            {
                uint256 zaYaYxa;
                {
                    // za = c/μ * (normalizedSharesReserves ** a)
                    // The “pow(x, y, z)” function not only calculates x^(y/z) but also normalizes the result to
                    // fit into 64.64 fixed point number, i.e. it actually calculates: x^(y/z) * (2^63)^(1 - y/z)
                    uint256 za;
                    require(
                        (za = c.div(mu).mulu(
                            uint128(normalizedSharesReserves).pow(a, ONE)
                        )) <= MAX,
                        'YieldMath: Rate overflow (za)'
                    );

                    // ya = fyTokenReserves ** a
                    // The “pow(x, y, z)” function not only calculates x^(y/z) but also normalizes the result to
                    // fit into 64.64 fixed point number, i.e. it actually calculates: x^(y/z) * (2^63)^(1 - y/z)
                    uint256 ya = fyTokenReserves.pow(a, ONE);

                    // yxa = (fyTokenReserves + x) ** a   # x is aka Δy
                    // The “pow(x, y, z)” function not only calculates x^(y/z) but also normalizes the result to
                    // fit into 64.64 fixed point number, i.e. it actually calculates: x^(y/z) * (2^63)^(1 - y/z)
                    uint256 yxa = (fyTokenReserves + fyTokenIn).pow(a, ONE);

                    require(
                        (zaYaYxa = (za + ya - yxa)) <= MAX,
                        'YieldMath: Rate overflow (yxa)'
                    );
                }

                rightTerm = uint128( // Cast zaYaYxa/(c/μ).pow(1/a).div(μ) from int128 to uint128 - always positive
                    int128( // Cast zaYaYxa/(c/μ).pow(1/a) from uint128 to int128 - always < zaYaYxa/(c/μ)
                        uint128( // Cast zaYaYxa/(c/μ) from int128 to uint128 - always positive
                            zaYaYxa.divu(uint128(c.div(mu))) // Cast c/μ from int128 to uint128 - always positive
                        ).pow(uint128(ONE), a) // Cast 2^64 from int128 to uint128 - always positive
                    ).div(mu)
                );
            }
            require(rightTerm <= sharesReserves, 'YieldMath: Rate underflow');

            return sharesReserves - rightTerm;
        }
    }

    /* ----------------------------------------------------------------------------------------------------------------
          .-:::::::::::-.                       ┌───────────────────────────────┐
        .:::::::::::::::::.                     │                               │              ┌──────────────┐
       :  _______  __   __ :                   \│                               │/             │$            $│
      :: |       ||  | |  |::                  \│                               │/             │ ┌────────────┴─┐
     ::: |    ___||  |_|  |:::                  │    fyTokenInForSharesOut      │              │ │$            $│
     ::: |   |___ |       |:::   ────────▶      │                               │  ────────▶   │$│ ┌────────────┴─┐
     ::: |    ___||_     _|:::                  │                               │              └─┤ │$            $│
     ::: |   |      |   |  :::                 /│                               │\               │$│              │
      :: |___|      |___|  ::                  /│                               │\               └─┤  `sharesOut` │
       :        ????       :                    │                      \(^o^)/  │                  │$            $│
        `:::::::::::::::::'                     │                     YieldMath │                  └──────────────┘
          `-:::::::::::-'                       └───────────────────────────────┘
    */
    /// Calculates the amount of fyToken a user could sell for given amount of Shares.
    /// @param sharesReserves shares reserves amount
    /// @param fyTokenReserves fyToken reserves amount
    /// @param sharesOut Shares amount to be traded
    /// @param timeTillMaturity time till maturity in seconds
    /// @param k time till maturity coefficient, multiplied by 2^64
    /// @param g fee coefficient, multiplied by 2^64
    /// @param c price of shares in terms of Dai, multiplied by 2^64
    /// @param mu (μ) Normalization factor -- starts as c at initialization
    /// @return fyTokenIn the amount of fyToken a user could sell for given amount of Shares
    function fyTokenInForSharesOut(
        uint128 sharesReserves,
        uint128 fyTokenReserves,
        uint128 sharesOut,
        uint128 timeTillMaturity,
        int128 k,
        int128 g,
        int128 c,
        int128 mu
    ) public pure returns (uint128) {
        /* https://docs.google.com/spreadsheets/d/14K_McZhlgSXQfi6nFGwDvDh4BmOu6_Hczi_sFreFfOE/

                y = fyToken reserves
                z = shares reserves
                x = Δz (sharesOut)

                     (                  sum                                )^(   invA    ) - y
                     (    Za          ) + (  Ya  ) - (       Zxa           )^(   invA    ) - y
                Δy = ( c/μ * (μz)^(1-t) +  y^(1-t) - c/μ * (μz - μx)^(1-t) )^(1 / (1 - t)) - y

            */

        unchecked {
            require(c > 0 && mu > 0, 'YieldMath: c and mu must be positive');

            uint128 a = _computeA(timeTillMaturity, k, g);
            uint256 sum;
            {
                // normalizedSharesReserves = μ * sharesReserves
                uint256 normalizedSharesReserves;
                require(
                    (normalizedSharesReserves = mu.mulu(sharesReserves)) <= MAX,
                    'YieldMath: Rate overflow (nsr)'
                );

                // za = c/μ * (normalizedSharesReserves ** a)
                // The “pow(x, y, z)” function not only calculates x^(y/z) but also normalizes the result to
                // fit into 64.64 fixed point number, i.e. it actually calculates: x^(y/z) * (2^63)^(1 - y/z)
                uint256 za;
                require(
                    (za = c.div(mu).mulu(
                        uint128(normalizedSharesReserves).pow(a, ONE)
                    )) <= MAX,
                    'YieldMath: Rate overflow (za)'
                );

                // ya = fyTokenReserves ** a
                // The “pow(x, y, z)” function not only calculates x^(y/z) but also normalizes the result to
                // fit into 64.64 fixed point number, i.e. it actually calculates: x^(y/z) * (2^63)^(1 - y/z)
                uint256 ya = fyTokenReserves.pow(a, ONE);

                // normalizedSharesOut = μ * sharesOut
                uint256 normalizedSharesOut;
                require(
                    (normalizedSharesOut = mu.mulu(sharesOut)) <= MAX,
                    'YieldMath: Rate overflow (nso)'
                );

                // zx = normalizedSharesReserves + sharesOut * μ
                require(
                    normalizedSharesReserves >= normalizedSharesOut,
                    'YieldMath: Too many shares in'
                );
                uint256 zx = normalizedSharesReserves - normalizedSharesOut;

                // zxa = c/μ * zx ** a
                // The “pow(x, y, z)” function not only calculates x^(y/z) but also normalizes the result to
                // fit into 64.64 fixed point number, i.e. it actually calculates: x^(y/z) * (2^63)^(1 - y/z)
                uint256 zxa = c.div(mu).mulu(uint128(zx).pow(a, ONE));

                // sum = za + ya - zxa
                // z < MAX, y < MAX, a < 1. It can only underflow, not overflow.
                require(
                    (sum = za + ya - zxa) <= MAX,
                    'YieldMath: > fyToken reserves'
                );
            }

            // result = fyTokenReserves - (sum ** (1/a))
            // The “pow(x, y, z)” function not only calculates x^(y/z) but also normalizes the result to
            // fit into 64.64 fixed point number, i.e. it actually calculates: x^(y/z) * (2^63)^(1 - y/z)
            uint256 result;
            require(
                (result =
                    uint256(uint128(sum).pow(ONE, a)) -
                    uint256(fyTokenReserves)) <= MAX,
                'YieldMath: Rounding error'
            );

            return uint128(result);
        }
    }

    /* ----------------------------------------------------------------------------------------------------------------
                                              ┌───────────────────────────────┐                    .-:::::::::::-.
      ┌──────────────┐                        │                               │                  .:::::::::::::::::.
      │$            $│                       \│                               │/                :  _______  __   __ :
      │ ┌────────────┴─┐                     \│                               │/               :: |       ||  | |  |::
      │ │$            $│                      │    sharesInForFYTokenOut      │               ::: |    ___||  |_|  |:::
      │$│ ┌────────────┴─┐     ────────▶      │                               │  ────────▶    ::: |   |___ |       |:::
      └─┤ │$            $│                    │                               │               ::: |    ___||_     _|:::
        │$│    SHARES    │                   /│                               │\              ::: |   |      |   |  :::
        └─┤     ????     │                   /│                               │\               :: |___|      |___|  ::
          │$            $│                    │                      \(^o^)/  │                 :   `fyTokenOut`    :
          └──────────────┘                    │                     YieldMath │                  `:::::::::::::::::'
                                              └───────────────────────────────┘                    `-:::::::::::-'
    */
    /// @param sharesReserves yield bearing vault shares reserve amount
    /// @param fyTokenReserves fyToken reserves amount
    /// @param fyTokenOut fyToken amount to be traded
    /// @param timeTillMaturity time till maturity in seconds e.g. 90 days in seconds
    /// @param k time till maturity coefficient, multiplied by 2^64.  e.g. 25 years in seconds
    /// @param g fee coefficient, multiplied by 2^64 -- sb under 1.0 for selling shares to pool
    /// @param c price of shares in terms of their base, multiplied by 2^64
    /// @param mu (μ) Normalization factor -- starts as c at initialization
    /// @return result the amount of shares a user would have to pay for given amount of fyToken
    function sharesInForFYTokenOut(
        uint128 sharesReserves,
        uint128 fyTokenReserves,
        uint128 fyTokenOut,
        uint128 timeTillMaturity,
        int128 k,
        int128 g,
        int128 c,
        int128 mu
    ) public pure returns (uint128) {
        unchecked {
            require(c > 0 && mu > 0, 'YieldMath: c and mu must be positive');
            return
                _sharesInForFYTokenOut(
                    sharesReserves,
                    fyTokenReserves,
                    fyTokenOut,
                    _computeA(timeTillMaturity, k, g),
                    c,
                    mu
                );
        }
    }

    /// @dev Splitting sharesInForFYTokenOut in two functions to avoid stack depth limits
    function _sharesInForFYTokenOut(
        uint128 sharesReserves,
        uint128 fyTokenReserves,
        uint128 fyTokenOut,
        uint128 a,
        int128 c,
        int128 mu
    ) private pure returns (uint128) {
        /* https://docs.google.com/spreadsheets/d/14K_McZhlgSXQfi6nFGwDvDh4BmOu6_Hczi_sFreFfOE/

        y = fyToken reserves
        z = shares reserves
        x = Δy (fyTokenOut)

             1/μ * (                 subtotal                            )^(   invA    ) - z
             1/μ * ((     Za       ) + (  Ya  ) - (    Yxa    )) / (c/μ) )^(   invA    ) - z
        Δz = 1/μ * (( c/μ * μz^(1-t) +  y^(1-t) - (y - x)^(1-t)) / (c/μ) )^(1 / (1 - t)) - z

        */
        unchecked {
            // normalizedSharesReserves = μ * sharesReserves
            require(
                mu.mulu(sharesReserves) <= MAX,
                'YieldMath: Rate overflow (nsr)'
            );

            // za = c/μ * (normalizedSharesReserves ** a)
            // The “pow(x, y, z)” function not only calculates x^(y/z) but also normalizes the result to
            // fit into 64.64 fixed point number, i.e. it actually calculates: x^(y/z) * (2^63)^(1 - y/z)
            uint256 za = c.div(mu).mulu(
                uint128(mu.mulu(sharesReserves)).pow(a, ONE)
            );
            require(za <= MAX, 'YieldMath: Rate overflow (za)');

            // ya = fyTokenReserves ** a
            // The “pow(x, y, z)” function not only calculates x^(y/z) but also normalizes the result to
            // fit into 64.64 fixed point number, i.e. it actually calculates: x^(y/z) * (2^63)^(1 - y/z)
            uint256 ya = fyTokenReserves.pow(a, ONE);

            // yxa = (fyTokenReserves - x) ** aß
            // The “pow(x, y, z)” function not only calculates x^(y/z) but also normalizes the result to
            // fit into 64.64 fixed point number, i.e. it actually calculates: x^(y/z) * (2^63)^(1 - y/z)
            uint256 yxa = (fyTokenReserves - fyTokenOut).pow(a, ONE);
            require(
                fyTokenOut <= fyTokenReserves,
                'YieldMath: Underflow (yxa)'
            );

            uint256 zaYaYxa;
            require(
                (zaYaYxa = (za + ya - yxa)) <= MAX,
                'YieldMath: Rate overflow (zyy)'
            );

            int128 subtotal = int128(ONE).div(mu).mul(
                (
                    uint128(zaYaYxa.divu(uint128(c.div(mu)))).pow(
                        uint128(ONE),
                        uint128(a)
                    )
                ).i128()
            );

            // subtotal is calculated as a positive fraction multiplied by a uint so it cannot underflow when casting to uint and its ok to use a raw casting
            uint128 sharesOut = uint128(subtotal) - sharesReserves;
            require(
                sharesOut <= uint128(subtotal),
                'YieldMath: Underflow error'
            );
            return sharesOut;
        }
    }

    /// Calculates the max amount of fyToken a user could sell.
    /// @param sharesReserves yield bearing vault shares reserve amount
    /// @param fyTokenReserves fyToken reserves amount
    /// @param timeTillMaturity time till maturity in seconds e.g. 90 days in seconds
    /// @param k time till maturity coefficient, multiplied by 2^64.  e.g. 25 years in seconds
    /// @param g fee coefficient, multiplied by 2^64 -- sb over 1.0 for buying shares from the pool
    /// @param c price of shares in terms of their base, multiplied by 2^64
    /// @return fyTokenIn the max amount of fyToken a user could sell
    function maxFYTokenIn(
        uint128 sharesReserves,
        uint128 fyTokenReserves,
        uint128 timeTillMaturity,
        int128 k,
        int128 g,
        int128 c,
        int128 mu
    ) public pure returns (uint128 fyTokenIn) {
        /* https://docs.google.com/spreadsheets/d/14K_McZhlgSXQfi6nFGwDvDh4BmOu6_Hczi_sFreFfOE/

                Y = fyToken reserves
                Z = shares reserves
                y = maxFYTokenIn

                     (                  sum        )^(   invA    ) - Y
                     (    Za          ) + (  Ya  ) )^(   invA    ) - Y
                Δy = ( c/μ * (μz)^(1-t) +  Y^(1-t) )^(1 / (1 - t)) - Y

            */

        unchecked {
            require(c > 0 && mu > 0, 'YieldMath: c and mu must be positive');

            uint128 a = _computeA(timeTillMaturity, k, g);
            uint256 sum;
            {
                // normalizedSharesReserves = μ * sharesReserves
                uint256 normalizedSharesReserves;
                require(
                    (normalizedSharesReserves = mu.mulu(sharesReserves)) <= MAX,
                    'YieldMath: Rate overflow (nsr)'
                );

                // za = c/μ * (normalizedSharesReserves ** a)
                // The “pow(x, y, z)” function not only calculates x^(y/z) but also normalizes the result to
                // fit into 64.64 fixed point number, i.e. it actually calculates: x^(y/z) * (2^63)^(1 - y/z)
                uint256 za;
                require(
                    (za = c.div(mu).mulu(
                        uint128(normalizedSharesReserves).pow(a, ONE)
                    )) <= MAX,
                    'YieldMath: Rate overflow (za)'
                );

                // ya = fyTokenReserves ** a
                // The “pow(x, y, z)” function not only calculates x^(y/z) but also normalizes the result to
                // fit into 64.64 fixed point number, i.e. it actually calculates: x^(y/z) * (2^63)^(1 - y/z)
                uint256 ya = fyTokenReserves.pow(a, ONE);

                // sum = za + ya
                // z < MAX, y < MAX, a < 1. It can only underflow, not overflow.
                require(
                    (sum = za + ya) <= MAX,
                    'YieldMath: > fyToken reserves'
                );
            }

            // result = (sum ** (1/a)) - fyTokenReserves
            // The “pow(x, y, z)” function not only calculates x^(y/z) but also normalizes the result to
            // fit into 64.64 fixed point number, i.e. it actually calculates: x^(y/z) * (2^63)^(1 - y/z)
            uint256 result;
            require(
                (result =
                    uint256(uint128(sum).pow(ONE, a)) -
                    uint256(fyTokenReserves)) <= MAX,
                'YieldMath: Rounding error'
            );

            fyTokenIn = uint128(result);
        }
    }

    /// Calculates the max amount of fyToken a user could get.
    /// https://docs.google.com/spreadsheets/d/14K_McZhlgSXQfi6nFGwDvDh4BmOu6_Hczi_sFreFfOE/
    /// @param sharesReserves yield bearing vault shares reserve amount
    /// @param fyTokenReserves fyToken reserves amount
    /// @param timeTillMaturity time till maturity in seconds e.g. 90 days in seconds
    /// @param k time till maturity coefficient, multiplied by 2^64.  e.g. 25 years in seconds
    /// @param g fee coefficient, multiplied by 2^64 -- sb under 1.0 for selling shares to pool
    /// @param c price of shares in terms of their base, multiplied by 2^64
    /// @param mu (μ) Normalization factor -- c at initialization
    /// @return fyTokenOut the max amount of fyToken a user could get
    function maxFYTokenOut(
        uint128 sharesReserves,
        uint128 fyTokenReserves,
        uint128 timeTillMaturity,
        int128 k,
        int128 g,
        int128 c,
        int128 mu
    ) public pure returns (uint128 fyTokenOut) {
        unchecked {
            require(c > 0 && mu > 0, 'YieldMath: c and mu must be positive');

            int128 a = int128(_computeA(timeTillMaturity, k, g));

            /*
                y = maxFyTokenOut
                Y = fyTokenReserves (virtual)
                Z = sharesReserves

                    Y - ( (       numerator           ) / (  denominator  ) )^invA
                    Y - ( ( (    Za      ) + (  Ya  ) ) / (  denominator  ) )^invA
                y = Y - ( (   c/μ * (μZ)^a +    Y^a   ) / (    c/μ + 1    ) )^(1/a)
            */

            // za = c/μ * ((μ * (sharesReserves / 1e18)) ** a)
            int128 za = c.div(mu).mul(mu.mul(sharesReserves.divu(WAD)).pow(a));

            // ya = (fyTokenReserves / 1e18) ** a
            int128 ya = fyTokenReserves.divu(WAD).pow(a);

            // numerator = za + ya
            int128 numerator = za.add(ya);

            // denominator = c/u + 1
            int128 denominator = c.div(mu).add(int128(ONE));

            // rightTerm = (numerator / denominator) ** (1/a)
            int128 rightTerm = numerator.div(denominator).pow(
                int128(ONE).div(a)
            );

            // maxFYTokenOut_ = fyTokenReserves - (rightTerm * 1e18)
            require(
                (fyTokenOut = fyTokenReserves - uint128(rightTerm.mulu(WAD))) <=
                    MAX,
                'YieldMath: Underflow error'
            );
            require(
                fyTokenOut <= fyTokenReserves,
                'YieldMath: Underflow error'
            );
        }
    }

    /// Calculates the max amount of base a user could sell.
    /// https://docs.google.com/spreadsheets/d/14K_McZhlgSXQfi6nFGwDvDh4BmOu6_Hczi_sFreFfOE/
    /// @param sharesReserves yield bearing vault shares reserve amount
    /// @param fyTokenReserves fyToken reserves amount
    /// @param timeTillMaturity time till maturity in seconds e.g. 90 days in seconds
    /// @param k time till maturity coefficient, multiplied by 2^64.  e.g. 25 years in seconds
    /// @param g fee coefficient, multiplied by 2^64 -- sb under 1.0 for selling shares to pool
    /// @param c price of shares in terms of their base, multiplied by 2^64
    /// @param mu (μ) Normalization factor -- c at initialization
    /// @return sharesIn Calculates the max amount of base a user could sell.
    function maxSharesIn(
        uint128 sharesReserves, // z
        uint128 fyTokenReserves, // x
        uint128 timeTillMaturity,
        int128 k,
        int128 g,
        int128 c,
        int128 mu
    ) public pure returns (uint128 sharesIn) {
        unchecked {
            require(c > 0 && mu > 0, 'YieldMath: c and mu must be positive');

            int128 a = int128(_computeA(timeTillMaturity, k, g));

            /*
                y = maxSharesIn_
                Y = fyTokenReserves (virtual)
                Z = sharesReserves

                    1/μ ( (       numerator           ) / (  denominator  ) )^invA  - Z
                    1/μ ( ( (    Za      ) + (  Ya  ) ) / (  denominator  ) )^invA  - Z
                y = 1/μ ( ( c/μ * (μZ)^a   +    Y^a   ) / (     c/u + 1   ) )^(1/a) - Z
            */

            // za = c/μ * ((μ * (sharesReserves / 1e18)) ** a)
            int128 za = c.div(mu).mul(mu.mul(sharesReserves.divu(WAD)).pow(a));

            // ya = (fyTokenReserves / 1e18) ** a
            int128 ya = fyTokenReserves.divu(WAD).pow(a);

            // numerator = za + ya
            int128 numerator = za.add(ya);

            // denominator = c/u + 1
            int128 denominator = c.div(mu).add(int128(ONE));

            // leftTerm = 1/μ * (numerator / denominator) ** (1/a)
            int128 leftTerm = int128(ONE).div(mu).mul(
                numerator.div(denominator).pow(int128(ONE).div(a))
            );

            // maxSharesIn_ = (leftTerm * 1e18) - sharesReserves
            require(
                (sharesIn = uint128(leftTerm.mulu(WAD)) - sharesReserves) <=
                    MAX,
                'YieldMath: Underflow error'
            );
            require(
                sharesIn <= uint128(leftTerm.mulu(WAD)),
                'YieldMath: Underflow error'
            );
        }
    }

    /*
    This function is not needed as it's return value is driven directly by the shares liquidity of the pool

    https://hackmd.io/lRZ4mgdrRgOpxZQXqKYlFw?view#MaxSharesOut

    function maxSharesOut(
        uint128 sharesReserves, // z
        uint128 fyTokenReserves, // x
        uint128 timeTillMaturity,
        int128 k,
        int128 g,
        int128 c,
        int128 mu
    ) public pure returns (uint128 maxSharesOut_) {} */

    /// Calculates the total supply invariant.
    /// https://docs.google.com/spreadsheets/d/14K_McZhlgSXQfi6nFGwDvDh4BmOu6_Hczi_sFreFfOE/
    /// @param sharesReserves yield bearing vault shares reserve amount
    /// @param fyTokenReserves fyToken reserves amount
    /// @param totalSupply total supply
    /// @param timeTillMaturity time till maturity in seconds e.g. 90 days in seconds
    /// @param k time till maturity coefficient, multiplied by 2^64.  e.g. 25 years in seconds
    /// @param g fee coefficient, multiplied by 2^64 -- use under 1.0 (g2)
    /// @param c price of shares in terms of their base, multiplied by 2^64
    /// @param mu (μ) Normalization factor -- c at initialization
    /// @return result Calculates the total supply invariant.
    function invariant(
        uint128 sharesReserves, // z
        uint128 fyTokenReserves, // x
        uint256 totalSupply, // s
        uint128 timeTillMaturity,
        int128 k,
        int128 g,
        int128 c,
        int128 mu
    ) public pure returns (uint128 result) {
        if (totalSupply == 0) return 0;
        int128 a = int128(_computeA(timeTillMaturity, k, g));

        result = _invariant(
            sharesReserves,
            fyTokenReserves,
            totalSupply,
            a,
            c,
            mu
        );
    }

    /// @param sharesReserves yield bearing vault shares reserve amount
    /// @param fyTokenReserves fyToken reserves amount
    /// @param totalSupply total supply
    /// @param a 1 - g * t computed
    /// @param c price of shares in terms of their base, multiplied by 2^64
    /// @param mu (μ) Normalization factor -- c at initialization
    /// @return result Calculates the total supply invariant.
    function _invariant(
        uint128 sharesReserves, // z
        uint128 fyTokenReserves, // x
        uint256 totalSupply, // s
        int128 a,
        int128 c,
        int128 mu
    ) internal pure returns (uint128 result) {
        unchecked {
            require(c > 0 && mu > 0, 'YieldMath: c and mu must be positive');

            /*
                y = invariant
                Y = fyTokenReserves (virtual)
                Z = sharesReserves
                s = total supply

                    c/μ ( (       numerator           ) / (  denominator  ) )^invA  / s 
                    c/μ ( ( (    Za      ) + (  Ya  ) ) / (  denominator  ) )^invA  / s 
                y = c/μ ( ( c/μ * (μZ)^a   +    Y^a   ) / (     c/u + 1   ) )^(1/a) / s
            */

            // za = c/μ * ((μ * (sharesReserves / 1e18)) ** a)
            int128 za = c.div(mu).mul(mu.mul(sharesReserves.divu(WAD)).pow(a));

            // ya = (fyTokenReserves / 1e18) ** a
            int128 ya = fyTokenReserves.divu(WAD).pow(a);

            // numerator = za + ya
            int128 numerator = za.add(ya);

            // denominator = c/u + 1
            int128 denominator = c.div(mu).add(int128(ONE));

            // topTerm = c/μ * (numerator / denominator) ** (1/a)
            int128 topTerm = c.div(mu).mul(
                (numerator.div(denominator)).pow(int128(ONE).div(a))
            );

            result = uint128((topTerm.mulu(WAD) * WAD) / totalSupply);
        }
    }

    /* UTILITY FUNCTIONS
     ******************************************************************************************************************/

    function _computeA(
        uint128 timeTillMaturity,
        int128 k,
        int128 g
    ) private pure returns (uint128) {
        // t = k * timeTillMaturity
        int128 t = k.mul(timeTillMaturity.fromUInt());
        require(t >= 0, 'YieldMath: t must be positive'); // Meaning neither T or k can be negative

        // a = (1 - gt)
        int128 a = int128(ONE).sub(g.mul(t));
        require(a > 0, 'YieldMath: Too far from maturity');
        require(a <= int128(ONE), 'YieldMath: g must be positive');

        return uint128(a);
    }
}

// Taken from https://github.com/Uniswap/uniswap-lib/blob/master/contracts/libraries/TransferHelper.sol

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
// USDT is a well known token that returns nothing for its transfer, transferFrom, and approve functions
// and part of the reason this library exists
library TransferHelper {
    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with the underlying revert message if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.transfer.selector, to, value)
        );
        if (!(success && _returnTrueOrNothing(data)))
            revert(RevertMsgExtractor.getRevertMsg(data));
    }

    /// @notice Approves a spender to transfer tokens from msg.sender
    /// @dev Errors with the underlying revert message if transfer fails
    /// @param token The contract address of the token which will be approved
    /// @param spender The approved spender
    /// @param value The value of the allowance
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.approve.selector, spender, value)
        );
        if (!(success && _returnTrueOrNothing(data)))
            revert(RevertMsgExtractor.getRevertMsg(data));
    }

    /// @notice Transfers tokens from the targeted address to the given destination
    /// @dev Errors with the underlying revert message if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(
                IERC20.transferFrom.selector,
                from,
                to,
                value
            )
        );
        if (!(success && _returnTrueOrNothing(data)))
            revert(RevertMsgExtractor.getRevertMsg(data));
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Errors with the underlying revert message if transfer fails
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address payable to, uint256 value) internal {
        (bool success, bytes memory data) = to.call{value: value}(new bytes(0));
        if (!success) revert(RevertMsgExtractor.getRevertMsg(data));
    }

    function _returnTrueOrNothing(bytes memory data)
        internal
        pure
        returns (bool)
    {
        return (data.length == 0 || abi.decode(data, (bool)));
    }
}

/* POOL EVENTS
 ******************************************************************************************************************/

abstract contract PoolEvents {
    /// Fees have been updated.
    event FeesSet(uint16 g1Fee);

    // Pool has been paused/unpaused
    event PausePool(bool state);

    /// Pool is matured and all LP tokens burned. gg.
    event gg();

    /// gm.  Pool is initialized.
    event gm();

    /// A liquidity event has occured (burn / mint).
    event Liquidity(
        uint32 maturity,
        address indexed from,
        address indexed to,
        address indexed fyTokenTo,
        int256 base,
        int256 fyTokens,
        int256 poolTokens
    );

    /// The _update fn has run and cached balances updated.
    event Sync(
        uint112 baseCached,
        uint112 fyTokenCached,
        uint256 cumulativeBalancesRatio
    );

    /// One of the four trading functions has been called:
    /// - buyBase
    /// - sellBase
    /// - buyFYToken
    /// - sellFYToken
    event Trade(
        uint32 maturity,
        address indexed from,
        address indexed to,
        int256 base,
        int256 fyTokens
    );
}

/* POOL ERRORS
 ******************************************************************************************************************/

/// The pool is currently paused.
error Paused();

/// The pool has matured and maybe you should too.
error AfterMaturity();

/// The approval of the sharesToken failed miserably.
error ApproveFailed();

/// The update would cause the FYToken cached to be less than the total supply. This should never happen but may
/// occur due to unexpected rounding errors.  We cannot allow this to happen as it could have many unexpected and
/// side effects which may pierce the fabric of the space-time continuum.
error FYTokenCachedBadState();

/// The pool has already been initialized. What are you thinking?
/// @dev To save gas, total supply == 0 is checked instead of a state variable.
error Initialized();

/// Trade results in negative interest rates because fyToken balance < (newSharesBalance * mu). Don't neg me.
error NegativeInterestRatesNotAllowed(
    uint128 newFYTokenBalance,
    uint128 newSharesBalanceTimesMu
);

/// Represents the fee in bps, and it cannot be larger than 10,000.
/// @dev https://en.wikipedia.org/wiki/10,000 per wikipedia:
/// 10,000 (ten thousand) is the natural number following 9,999 and preceding 10,001.
/// @param proposedFee The fee that was proposed.
error InvalidFee(uint16 proposedFee);

/// The year is 2106 and an invalid maturity date was passed into the constructor.
/// Maturity date must be less than type(uint32).max
error MaturityOverflow();

/// Mu cannot be zero. And you're not a hero.
error MuCannotBeZero();

/// Not enough base was found in the pool contract to complete the requested action. You just wasted gas.
/// @param baseAvailable The amount of unaccounted for base tokens.
/// @param baseNeeded The amount of base tokens required for the mint.
error NotEnoughBaseIn(uint256 baseAvailable, uint256 baseNeeded);

/// Not enough fYTokens were found in the pool contract to complete the requested action :( smh.
/// @param fYTokensAvailable The amount of unaccounted for fYTokens.
/// @param fYTokensNeeded The amount of fYToken tokens required for the mint.
error NotEnoughFYTokenIn(uint256 fYTokensAvailable, uint256 fYTokensNeeded);

/// The pool has not been initialized yet. INTRUDER ALERT!
/// @dev To save gas, total supply == 0 is checked instead of a state variable
error NotInitialized();

/// The reserves have changed compared with the last cache which causes the burn to fall outside the bounds of min/max
/// slippage ratios selected. This is likely the result of a peanut butter sandwich attack.
/// @param newRatio The ratio that would have resulted from the mint.
/// @param minRatio The minimum ratio allowed as specified by the caller.
/// @param maxRatio The maximum ratio allowed as specified by the caller
error SlippageDuringBurn(uint256 newRatio, uint256 minRatio, uint256 maxRatio);

/// The reserves have changed compared with the last cache which causes the mint to fall outside the bounds of min/max
/// slippage ratios selected. This is likely the result of a bologna sandwich attack.
/// @param newRatio The ratio that would have resulted from the mint.
/// @param minRatio The minimum ratio allowed as specified by the caller.
/// @param maxRatio The maximum ratio allowed as specified by the caller
error SlippageDuringMint(uint256 newRatio, uint256 minRatio, uint256 maxRatio);

/// Minimum amount of fyToken (per the min arg) would not be met for the trade. Try again.
/// @param fyTokenOut fyTokens that would be obtained through the trade.
/// @param min The minimum amount of fyTokens as specified by the caller.
error SlippageDuringSellBase(uint128 fyTokenOut, uint128 min);

/// Minimum amount of base (per the min arg) would not be met for the trade. Maybe you'll get lucky next time.
/// @param baseOut bases that would be obtained through the trade.
/// @param min The minimum amount of bases as specified by the caller.
error SlippageDuringSellFYToken(uint128 baseOut, uint128 min);

/// Unauthorized user attempted to call a method
error Unauthorized();

/*
   __     ___      _     _
   \ \   / (_)    | |   | |  ██████╗  ██████╗  ██████╗ ██╗        ███████╗ ██████╗ ██╗
    \ \_/ / _  ___| | __| |  ██╔══██╗██╔═══██╗██╔═══██╗██║        ██╔════╝██╔═══██╗██║
     \   / | |/ _ \ |/ _` |  ██████╔╝██║   ██║██║   ██║██║        ███████╗██║   ██║██║
      | |  | |  __/ | (_| |  ██╔═══╝ ██║   ██║██║   ██║██║        ╚════██║██║   ██║██║
      |_|  |_|\___|_|\__,_|  ██║     ╚██████╔╝╚██████╔╝███████╗██╗███████║╚██████╔╝███████╗
       yieldprotocol.com     ╚═╝      ╚═════╝  ╚═════╝ ╚══════╝╚═╝╚══════╝ ╚═════╝ ╚══════╝

                                                ┌─────────┐
                                                │no       │
                                                │lifeguard│
                                                └─┬─────┬─┘       ==+
                    be cool, stay in pool         │     │    =======+
                                             _____│_____│______    |+
                                      \  .-'"___________________`-.|+
                                        ( .'"                   '-.)+
                                        |`-..__________________..-'|+
                                        |                          |+
             .-:::::::::::-.            |                          |+      ┌──────────────┐
           .:::::::::::::::::.          |         ---  ---         |+      │$            $│
          :  _______  __   __ :        .|         (o)  (o)         |+.     │ ┌────────────┴─┐
         :: |       ||  | |  |::      /`|                          |+'\    │ │$            $│
        ::: |    ___||  |_|  |:::    / /|            [             |+\ \   │$│ ┌────────────┴─┐
        ::: |   |___ |       |:::   / / |        ----------        |+ \ \  └─┤ │$  ERC4626   $│
        ::: |    ___||_     _|:::.-" ;  \        \________/        /+  \ "--/│$│  Tokenized   │
        ::: |   |      |   |  ::),.-'    `-..__________________..-' +=  `---=└─┤ Vault Shares │
         :: |___|      |___|  ::=/              |    | |    |                  │$            $│
          :       TOKEN       :                 |    | |    |                  └──────────────┘
           `:::::::::::::::::'                  |    | |    |
             `-:::::::::::-'                    +----+ +----+
                `'''''''`                  _..._|____| |____| _..._
                                         .` "-. `%   | |    %` .-" `.
                                        /      \    .: :.     /      \
                                        '-..___|_..=:` `-:=.._|___..-'
*/

/// A Yieldspace AMM implementation for pools which provide liquidity and trading of fyTokens vs base tokens.
/// **The base tokens in this implementation are converted to ERC4626 compliant tokenized vault shares.**
/// See whitepaper and derived formulas: https://hackmd.io/lRZ4mgdrRgOpxZQXqKYlFw
//
//  Useful terminology:
//    base - Example: DAI. The underlying token of the fyToken. Sometimes referred to as "asset" or "base".
//    shares - Example: yvDAI. Upon receipt, base is deposited (wrapped) in a tokenized vault.
//    c - Current price of shares in terms of base (in 64.64 bit)
//    mu - also called c0 is the initial c of shares at contract deployment
//    Reserves are tracked in shares * mu for consistency.
//
/// @title  Pool.sol
/// @dev    Uses ABDK 64.64 mathlib for precision and reduced gas.
/// @author Adapted by @devtooligan from original work by @alcueca and UniswapV2. Maths and whitepaper by @aniemerg.
contract Pool is PoolEvents, IPool, ERC20Permit {
    /* LIBRARIES
     *****************************************************************************************************************/

    using WDiv for uint256;
    using RDiv for uint256;
    using Math64x64 for int128;
    using Math64x64 for uint256;
    using CastU128I128 for uint128;
    using CastU128U104 for uint128;
    using CastU256U104 for uint256;
    using CastU256U128 for uint256;
    using CastU256I256 for uint256;
    using TransferHelper for IMaturingToken;
    using TransferHelper for IERC20Like;

    /* MODIFIERS
     *****************************************************************************************************************/

    /// Trading can only be done before maturity.
    modifier beforeMaturity() {
        if (block.timestamp >= maturity) revert AfterMaturity();
        _;
    }

    /// Allows only the authorized contract to execute the method
    modifier authorized(address a) {
        if (msg.sender != a) revert Unauthorized();
        _;
    }

    /// Ensures pool is not paused before execution
    modifier unpaused() {
        if (paused == true) revert Paused();
        _;
    }

    /* IMMUTABLES
     *****************************************************************************************************************/

    /// The fyToken for the corresponding base token. Ex. yvDAI's fyToken will be fyDAI. Even though we convert base
    /// in this contract to a wrapped tokenized vault (e.g. Yearn Vault Dai), the fyToken is still payable in
    /// the base token upon maturity.
    IMaturingToken public immutable fyToken;

    /// This pool accepts a pair of base and fyToken tokens.
    /// When these are deposited into a tokenized vault they become shares.
    /// It is an ERC20 token.
    IERC20Like public immutable baseToken;

    /// Decimals of base tokens (fyToken, lp token, and usually the sharesToken).
    uint256 public immutable baseDecimals;

    /// When base comes into this contract it is deposited into a 3rd party tokenized vault in return for shares.
    /// @dev For most of this contract, only the ERC20 functionality of the shares token is required. As such, shares
    /// are cast as "IERC20Like" and when that 4626 functionality is needed, they are recast as IERC4626.
    /// This wei, modules for non-4626 compliant base tokens can import this contract and override 4626 specific fn's.
    IERC20Like public immutable sharesToken;

    /// Time stretch == 1 / seconds in x years where x varies per contract (64.64)
    int128 public ts;

    /// The normalization coefficient, the initial c value or price per 1 share of base (64.64)
    int128 public mu;

    /// Pool's maturity date (not 64.64)
    uint32 public immutable maturity;

    /// Used to scale up to 18 decimals (not 64.64)
    uint96 public immutable scaleFactor;

    /* STRUCTS
     *****************************************************************************************************************/

    struct Cache {
        uint16 g1Fee;
        uint104 sharesCached;
        uint104 fyTokenCached;
        uint32 blockTimestampLast;
    }

    /* STORAGE
     *****************************************************************************************************************/

    // The following 4 vars use one storage slot and can be retrieved in a Cache struct with getCache()

    /// This number is used to calculate the fees for buying/selling fyTokens.
    /// @dev This is a fp4 that represents a ratio out 1, where 1 is represented by 10000.
    uint16 public g1Fee;

    /// Shares reserves, cached.
    uint104 internal sharesCached;

    /// fyToken reserves, cached.
    uint104 internal fyTokenCached;

    /// block.timestamp of last time reserve caches were updated.
    uint32 internal blockTimestampLast;

    /// This is a LAGGING, time weighted sum of the fyToken:shares reserves ratio measured in ratio seconds.
    /// @dev Footgun 🔫 alert!  Be careful, this number is probably not what you need and it should normally be
    /// considered with blockTimestampLast. For consumption as a TWAR observation, use currentCumulativeRatio().
    /// In future pools, this function's visibility may be changed to internal.
    /// @return a fixed point factor with 27 decimals (ray).
    uint256 public cumulativeRatioLast;

    /// Admin has access to certain setter methods
    address public admin;

    /// Paused flag
    bool public paused;

    /* CONSTRUCTOR FUNCTIONS
     *****************************************************************************************************************/
    constructor(
        address sharesToken_, //    address of shares token
        address fyToken_, //  address of fyToken
        int128 ts_, //        time stretch(64.64)
        uint16 g1Fee_ //      fees (in bps) when buying fyToken
    )
        ERC20Permit(
            string(abi.encodePacked(IERC20Like(fyToken_).name(), ' LP')),
            string(abi.encodePacked(IERC20Like(fyToken_).symbol(), 'LP')),
            IERC20Like(fyToken_).decimals()
        )
    {
        /*  __   __        __  ___  __        __  ___  __   __
           /  ` /  \ |\ | /__`  |  |__) |  | /  `  |  /  \ |__)
           \__, \__/ | \| .__/  |  |  \ \__/ \__,  |  \__/ |  \ */

        // Set the admin as the sender of the contract
        admin = msg.sender;

        // Set maturity with check to make sure its not 2107 yet.
        uint256 maturity_ = IMaturingToken(fyToken_).maturity();
        if (maturity_ > uint256(type(uint32).max)) revert MaturityOverflow();
        maturity = uint32(maturity_);

        // Set sharesToken.
        sharesToken = IERC20Like(sharesToken_);

        // Cache baseToken to save loads of SLOADs.
        IERC20Like baseToken_ = _getBaseAsset(sharesToken_);

        // Call approve hook for sharesToken.
        _approveSharesToken(baseToken_, sharesToken_);

        // NOTE: LP tokens, baseToken and fyToken should have the same decimals.  Within this core contract, it is
        // presumed that sharesToken also has the same decimals. If this is not the case, a separate module must be
        // used to overwrite _getSharesBalance() and other affected functions (see PoolEuler.sol for example).
        baseDecimals = baseToken_.decimals();

        // Set other immutables.
        baseToken = baseToken_;
        fyToken = IMaturingToken(fyToken_);
        ts = ts_;
        scaleFactor = uint96(10**(18 - uint96(baseDecimals))); // No more than 18 decimals allowed, reverts on underflow.

        // Set mu with check for 0.
        if ((mu = _getC()) == 0) {
            revert MuCannotBeZero();
        }

        // Set g1Fee state variable with out of bounds check.
        if ((g1Fee = g1Fee_) > 10000) revert InvalidFee(g1Fee_);
        emit FeesSet(g1Fee_);
    }

    /// This is used by the constructor to give max approval to sharesToken.
    /// @dev This should be overridden by modules if needed.
    /// @dev safeAprove will revert approve is unsuccessful
    function _approveSharesToken(IERC20Like baseToken_, address sharesToken_)
        internal
        virtual
    {
        baseToken_.safeApprove(sharesToken_, type(uint256).max);
    }

    /// This is used by the constructor to set the base token as immutable.
    /// @dev This should be overridden by modules.
    /// We use the IERC20Like interface, but this should be an ERC20 asset per EIP4626.
    function _getBaseAsset(address sharesToken_)
        internal
        virtual
        returns (IERC20Like)
    {
        return IERC20Like(address(IERC4626(sharesToken_).asset()));
    }

    /* LIQUIDITY FUNCTIONS

        ┌─────────────────────────────────────────────────┐
        │  mint, new life. gm!                            │
        │  buy, sell, mint more, trade, trade -- stop     │
        │  mature, burn. gg~                              │
        │                                                 │
        │ "Watashinojinsei (My Life)" - haiku by Poolie   │
        └─────────────────────────────────────────────────┘

     *****************************************************************************************************************/

    /*mint
                                                                                              v
         ___                                                                           \            /
         |_ \_/                   ┌───────────────────────────────┐
         |   |                    │                               │                 `    _......._     '   gm!
                                 \│                               │/                  .-:::::::::::-.
           │                     \│                               │/             `   :    __    ____ :   /
           └───────────────►      │            mint               │                 ::   / /   / __ \::
                                  │                               │  ──────▶    _   ::  / /   / /_/ /::   _
           ┌───────────────►      │                               │                 :: / /___/ ____/ ::
           │                     /│                               │\                ::/_____/_/      ::
                                 /│                               │\             '   :               :   `
         B A S E                  │                      \(^o^)/  │                   `-:::::::::::-'
                                  │                     Pool.sol  │                 ,    `'''''''`     .
                                  └───────────────────────────────┘
                                                                                       /            \
                                                                                              ^
    */
    /// Mint liquidity tokens in exchange for adding base and fyToken
    /// The amount of liquidity tokens to mint is calculated from the amount of unaccounted for fyToken in this contract.
    /// A proportional amount of asset tokens need to be present in this contract, also unaccounted for.
    /// @dev _totalSupply > 0 check important here to prevent unauthorized initialization.
    /// @param to Wallet receiving the minted liquidity tokens.
    /// @param remainder Wallet receiving any surplus base.
    /// @param minRatio Minimum ratio of shares to fyToken in the pool (fp18).
    /// @param maxRatio Maximum ratio of shares to fyToken in the pool (fp18).
    /// @return baseIn The amount of base found in the contract that was used for the mint.
    /// @return fyTokenIn The amount of fyToken found that was used for the mint
    /// @return lpTokensMinted The amount of LP tokens minted.
    function mint(
        address to,
        address remainder,
        uint256 minRatio,
        uint256 maxRatio
    )
        external
        virtual
        override
        unpaused
        returns (
            uint256 baseIn,
            uint256 fyTokenIn,
            uint256 lpTokensMinted
        )
    {
        if (_totalSupply == 0) revert NotInitialized();

        (baseIn, fyTokenIn, lpTokensMinted) = _mint(
            to,
            remainder,
            0,
            minRatio,
            maxRatio
        );
    }

    //  ╦┌┐┌┬┌┬┐┬┌─┐┬  ┬┌─┐┌─┐  ╔═╗┌─┐┌─┐┬
    //  ║││││ │ │├─┤│  │┌─┘├┤   ╠═╝│ ││ ││
    //  ╩┘└┘┴ ┴ ┴┴ ┴┴─┘┴└─┘└─┘  ╩  └─┘└─┘┴─┘
    /// @dev This is the exact same as mint() but with auth added and skip the supply > 0 check
    /// and checks instead that supply == 0.
    /// This intialize mechanism is different than UniV2.  Tokens addresses are added at contract creation.
    /// This pool is considered initialized after the first LP token is minted.
    /// @param to Wallet receiving the minted liquidity tokens.
    /// @return baseIn The amount of base found that was used for the mint.
    /// @return fyTokenIn The amount of fyToken found that was used for the mint
    /// @return lpTokensMinted The amount of LP tokens minted.
    function init(address to)
        external
        virtual
        authorized(admin)
        returns (
            uint256 baseIn,
            uint256 fyTokenIn,
            uint256 lpTokensMinted
        )
    {
        if (_totalSupply != 0) revert Initialized();

        // address(this) used for the remainder, but actually this parameter is not used at all in this case because
        // there will never be any left over base in this case
        (baseIn, fyTokenIn, lpTokensMinted) = _mint(
            to,
            address(this),
            0,
            0,
            type(uint256).max
        );

        emit gm();
    }

    /* mintWithBase
                                                                                             V
                                  ┌───────────────────────────────┐                   \            /
                                  │                               │                 `    _......._     '   gm!
                                 \│                               │/                  .-:::::::::::-.
                                 \│                               │/             `   :    __    ____ :   /
                                  │         mintWithBase          │                 ::   / /   / __ \::
         B A S E     ──────►      │                               │  ──────▶    _   ::  / /   / /_/ /::   _
                                  │                               │                 :: / /___/ ____/ ::
                                 /│                               │\                ::/_____/_/      ::
                                 /│                               │\             '   :               :   `
                                  │                      \(^o^)/  │                   `-:::::::::::-'
                                  │                     Pool.sol  │                 ,    `'''''''`     .
                                  └───────────────────────────────┘                    /           \
                                                                                            ^
    */
    /// Mint liquidity tokens in exchange for adding only base.
    /// The amount of liquidity tokens is calculated from the amount of fyToken to buy from the pool.
    /// The base tokens need to be previously transferred and present in this contract.
    /// @dev _totalSupply > 0 check important here to prevent minting before initialization.
    /// @param to Wallet receiving the minted liquidity tokens.
    /// @param remainder Wallet receiving any leftover base at the end.
    /// @param fyTokenToBuy Amount of `fyToken` being bought in the Pool, from this we calculate how much base it will be taken in.
    /// @param minRatio Minimum ratio of shares to fyToken in the pool (fp18).
    /// @param maxRatio Maximum ratio of shares to fyToken in the pool (fp18).
    /// @return baseIn The amount of base found that was used for the mint.
    /// @return fyTokenIn The amount of fyToken found that was used for the mint
    /// @return lpTokensMinted The amount of LP tokens minted.
    function mintWithBase(
        address to,
        address remainder,
        uint256 fyTokenToBuy,
        uint256 minRatio,
        uint256 maxRatio
    )
        external
        virtual
        override
        unpaused
        returns (
            uint256 baseIn,
            uint256 fyTokenIn,
            uint256 lpTokensMinted
        )
    {
        if (_totalSupply == 0) revert NotInitialized();
        (baseIn, fyTokenIn, lpTokensMinted) = _mint(
            to,
            remainder,
            fyTokenToBuy,
            minRatio,
            maxRatio
        );
    }

    /// This is the internal function called by the external mint functions.
    /// Mint liquidity tokens, with an optional internal trade to buy fyToken beforehand.
    /// The amount of liquidity tokens is calculated from the amount of fyTokenToBuy from the pool,
    /// plus the amount of extra, unaccounted for fyToken in this contract.
    /// The base tokens also need to be previously transferred and present in this contract.
    /// Only usable before maturity.
    /// @dev Warning: This fn does not check if supply > 0 like the external functions do.
    /// This function overloads the ERC20._mint(address, uint) function.
    /// @param to Wallet receiving the minted liquidity tokens.
    /// @param remainder Wallet receiving any surplus base.
    /// @param fyTokenToBuy Amount of `fyToken` being bought in the Pool.
    /// @param minRatio Minimum ratio of shares to fyToken in the pool (fp18).
    /// @param maxRatio Maximum ratio of shares to fyToken in the pool (fp18).
    /// @return baseIn The amount of base found that was used for the mint.
    /// @return fyTokenIn The amount of fyToken found that was used for the mint
    /// @return lpTokensMinted The amount of LP tokens minted.
    function _mint(
        address to,
        address remainder,
        uint256 fyTokenToBuy,
        uint256 minRatio,
        uint256 maxRatio
    )
        internal
        beforeMaturity
        returns (
            uint256 baseIn,
            uint256 fyTokenIn,
            uint256 lpTokensMinted
        )
    {
        // Wrap all base found in this contract.
        baseIn = baseToken.balanceOf(address(this));

        _wrap(address(this));

        // Gather data
        uint256 supply = _totalSupply;
        Cache memory cache = _getCache();
        uint256 realFYTokenCached_ = cache.fyTokenCached - supply; // The fyToken cache includes the virtual fyToken, equal to the supply
        uint256 sharesBalance = _getSharesBalance();

        // Check the burn wasn't sandwiched
        if (realFYTokenCached_ != 0) {
            if (
                uint256(cache.sharesCached).wdiv(realFYTokenCached_) <
                minRatio ||
                uint256(cache.sharesCached).wdiv(realFYTokenCached_) > maxRatio
            )
                revert SlippageDuringMint(
                    uint256(cache.sharesCached).wdiv(realFYTokenCached_),
                    minRatio,
                    maxRatio
                );
        } else if (maxRatio < type(uint256).max) {
            revert SlippageDuringMint(type(uint256).max, minRatio, maxRatio);
        }

        // Calculate token amounts
        uint256 sharesIn;
        if (supply == 0) {
            // **First mint**
            // Initialize at 1 pool token
            sharesIn = sharesBalance;
            lpTokensMinted = _mulMu(sharesIn);
        } else if (realFYTokenCached_ == 0) {
            // Edge case, no fyToken in the Pool after initialization
            sharesIn = sharesBalance - cache.sharesCached;
            lpTokensMinted = (supply * sharesIn) / cache.sharesCached;
        } else {
            // There is an optional virtual trade before the mint
            uint256 sharesToSell;
            if (fyTokenToBuy != 0) {
                sharesToSell = _buyFYTokenPreview(
                    fyTokenToBuy.u128(),
                    cache.sharesCached,
                    cache.fyTokenCached,
                    _computeG1(cache.g1Fee)
                );
            }

            // We use all the available fyTokens, plus optional virtual trade. Surplus is in base tokens.
            fyTokenIn = fyToken.balanceOf(address(this)) - realFYTokenCached_;
            lpTokensMinted =
                (supply * (fyTokenToBuy + fyTokenIn)) /
                (realFYTokenCached_ - fyTokenToBuy);

            sharesIn =
                sharesToSell +
                ((cache.sharesCached + sharesToSell) * lpTokensMinted) /
                supply;

            if ((sharesBalance - cache.sharesCached) < sharesIn) {
                revert NotEnoughBaseIn(
                    _unwrapPreview(sharesBalance - cache.sharesCached),
                    _unwrapPreview(sharesIn)
                );
            }
        }

        // Update TWAR
        _update(
            (cache.sharesCached + sharesIn).u128(),
            (cache.fyTokenCached + fyTokenIn + lpTokensMinted).u128(), // Include "virtual" fyToken from new minted LP tokens
            cache.sharesCached,
            cache.fyTokenCached
        );

        // Execute mint
        _mint(to, lpTokensMinted);

        // Return any unused base tokens
        if (sharesBalance > cache.sharesCached + sharesIn) _unwrap(remainder);

        // confirm new virtual fyToken balance is not less than new supply
        if (
            (cache.fyTokenCached + fyTokenIn + lpTokensMinted) <
            supply + lpTokensMinted
        ) {
            revert FYTokenCachedBadState();
        }

        emit Liquidity(
            maturity,
            msg.sender,
            to,
            address(0),
            -(baseIn.i256()),
            -(fyTokenIn.i256()),
            lpTokensMinted.i256()
        );
    }

    /* burn
                        (   (
                        )    (
                   (  (|   (|  )
                )   )\/ ( \/(( (    gg            ___
                ((  /     ))\))))\      ┌~~~~~~►  |_ \_/
                 )\(          |  )      │         |   |
                /:  | __    ____/:      │
                ::   / /   / __ \::  ───┤
                ::  / /   / /_/ /::     │
                :: / /___/ ____/ ::     └~~~~~~►  B A S E
                ::/_____/_/      ::
                 :               :
                  `-:::::::::::-'
                     `'''''''`
    */
    /// Burn liquidity tokens in exchange for base and fyToken.
    /// The liquidity tokens need to be previously tranfsferred to this contract.
    /// @param baseTo Wallet receiving the base tokens.
    /// @param fyTokenTo Wallet receiving the fyTokens.
    /// @param minRatio Minimum ratio of shares to fyToken in the pool (fp18).
    /// @param maxRatio Maximum ratio of shares to fyToken in the pool (fp18).
    /// @return lpTokensBurned The amount of LP tokens burned.
    /// @return baseOut The amount of base tokens received.
    /// @return fyTokenOut The amount of fyTokens received.
    function burn(
        address baseTo,
        address fyTokenTo,
        uint256 minRatio,
        uint256 maxRatio
    )
        external
        virtual
        override
        unpaused
        returns (
            uint256 lpTokensBurned,
            uint256 baseOut,
            uint256 fyTokenOut
        )
    {
        (lpTokensBurned, baseOut, fyTokenOut) = _burn(
            baseTo,
            fyTokenTo,
            false,
            minRatio,
            maxRatio
        );
    }

    /* burnForBase

                        (   (
                        )    (
                    (  (|   (|  )
                 )   )\/ ( \/(( (    gg
                 ((  /     ))\))))\
                  )\(          |  )
                /:  | __    ____/:
                ::   / /   / __ \::   ~~~~~~~►   B A S E
                ::  / /   / /_/ /::
                :: / /___/ ____/ ::
                ::/_____/_/      ::
                 :               :
                  `-:::::::::::-'
                     `'''''''`
    */
    /// Burn liquidity tokens in exchange for base.
    /// The liquidity provider needs to have called `pool.approve`.
    /// Only usable before maturity.
    /// @param to Wallet receiving the base and fyToken.
    /// @param minRatio Minimum ratio of shares to fyToken in the pool (fp18).
    /// @param maxRatio Maximum ratio of shares to fyToken in the pool (fp18).
    /// @return lpTokensBurned The amount of lp tokens burned.
    /// @return baseOut The amount of base tokens returned.
    function burnForBase(
        address to,
        uint256 minRatio,
        uint256 maxRatio
    )
        external
        virtual
        override
        unpaused
        beforeMaturity
        returns (uint256 lpTokensBurned, uint256 baseOut)
    {
        (lpTokensBurned, baseOut, ) = _burn(
            to,
            address(0),
            true,
            minRatio,
            maxRatio
        );
    }

    /// Burn liquidity tokens in exchange for base.
    /// The liquidity provider needs to have called `pool.approve`.
    /// @dev This function overloads the ERC20._burn(address, uint) function.
    /// @param baseTo Wallet receiving the base.
    /// @param fyTokenTo Wallet receiving the fyToken.
    /// @param tradeToBase Whether the resulting fyToken should be traded for base tokens.
    /// @param minRatio Minimum ratio of shares to fyToken in the pool (fp18).
    /// @param maxRatio Maximum ratio of shares to fyToken in the pool (fp18).
    /// @return lpTokensBurned The amount of pool tokens burned.
    /// @return baseOut The amount of base tokens returned.
    /// @return fyTokenOut The amount of fyTokens returned.
    function _burn(
        address baseTo,
        address fyTokenTo,
        bool tradeToBase,
        uint256 minRatio,
        uint256 maxRatio
    )
        internal
        returns (
            uint256 lpTokensBurned,
            uint256 baseOut,
            uint256 fyTokenOut
        )
    {
        // Gather data
        lpTokensBurned = _balanceOf[address(this)];
        uint256 supply = _totalSupply;

        Cache memory cache = _getCache();
        uint96 scaleFactor_ = scaleFactor;

        // The fyToken cache includes the virtual fyToken, equal to the supply.
        uint256 realFYTokenCached_ = cache.fyTokenCached - supply;

        // Check the burn wasn't sandwiched
        if (realFYTokenCached_ != 0) {
            if (
                (uint256(cache.sharesCached).wdiv(realFYTokenCached_) <
                    minRatio) ||
                (uint256(cache.sharesCached).wdiv(realFYTokenCached_) >
                    maxRatio)
            ) {
                revert SlippageDuringBurn(
                    uint256(cache.sharesCached).wdiv(realFYTokenCached_),
                    minRatio,
                    maxRatio
                );
            }
        }

        // Calculate trade
        uint256 sharesOut = (lpTokensBurned * cache.sharesCached) / supply;
        fyTokenOut = (lpTokensBurned * realFYTokenCached_) / supply;

        if (tradeToBase) {
            sharesOut +=
                YieldMath.sharesOutForFYTokenIn( //                                 This is a virtual sell
                    (cache.sharesCached - sharesOut.u128()) * scaleFactor_, //     Cache, minus virtual burn
                    (cache.fyTokenCached - fyTokenOut.u128()) * scaleFactor_, //  Cache, minus virtual burn
                    fyTokenOut.u128() * scaleFactor_, //                          Sell the virtual fyToken obtained
                    maturity - uint32(block.timestamp), //                         This can't be called after maturity
                    ts,
                    _computeG2(cache.g1Fee),
                    _getC(),
                    mu
                ) /
                scaleFactor_;
            fyTokenOut = 0;
        }

        // Update TWAR
        _update(
            (cache.sharesCached - sharesOut).u128(),
            (cache.fyTokenCached - fyTokenOut - lpTokensBurned).u128(), // Exclude "virtual" fyToken from new minted LP tokens
            cache.sharesCached,
            cache.fyTokenCached
        );

        // Burn and transfer
        _burn(address(this), lpTokensBurned); // This is calling the actual ERC20 _burn.
        baseOut = _unwrap(baseTo);

        if (fyTokenOut != 0) fyToken.safeTransfer(fyTokenTo, fyTokenOut);

        // confirm new virtual fyToken balance is not less than new supply
        if (
            (cache.fyTokenCached - fyTokenOut - lpTokensBurned) <
            supply - lpTokensBurned
        ) {
            revert FYTokenCachedBadState();
        }

        emit Liquidity(
            maturity,
            msg.sender,
            baseTo,
            fyTokenTo,
            baseOut.i256(),
            fyTokenOut.i256(),
            -(lpTokensBurned.i256())
        );

        if (supply == lpTokensBurned && block.timestamp >= maturity) {
            emit gg();
        }
    }

    /* TRADING FUNCTIONS
     ****************************************************************************************************************/

    /* buyBase

                         I want to buy `uint128 baseOut` worth of base tokens.
             _______     I've transferred you some fyTokens -- that should be enough.
            /   GUY \         .:::::::::::::::::.
     (^^^|   \===========    :  _______  __   __ :                 ┌─────────┐
      \(\/    | _  _ |      :: |       ||  | |  |::                │no       │
       \ \   (. o  o |     ::: |    ___||  |_|  |:::               │lifeguard│
        \ \   |   ~  |     ::: |   |___ |       |:::               └─┬─────┬─┘       ==+
        \  \   \ == /      ::: |    ___||_     _|::      ok guy      │     │    =======+
         \  \___|  |___    ::: |   |      |   |  :::            _____│_____│______    |+
          \ /   \__/   \    :: |___|      |___|  ::         .-'"___________________`-.|+
           \            \    :                   :         ( .'"                   '-.)+
            --|  GUY |\_/\  / `:::::::::::::::::'          |`-..__________________..-'|+
              |      | \  \/ /  `-:::::::::::-'            |                          |+
              |      |  \   /      `'''''''`               |                          |+
              |      |   \_/                               |       ---     ---        |+
              |______|                                     |       (o )    (o )       |+
              |__GG__|             ┌──────────────┐      /`|                          |+
              |      |             │$            $│     / /|            [             |+
              |  |   |             │   B A S E    │    / / |        ----------        |+
              |  |  _|             │   baseOut    │\.-" ;  \        \________/        /+
              |  |  |              │$            $│),.-'    `-..__________________..-' +=
              |  |  |              └──────────────┘                |    | |    |
              (  (  |                                              |    | |    |
              |  |  |                                              |    | |    |
              |  |  |                                              T----T T----T
             _|  |  |                                         _..._L____J L____J _..._
            (_____[__)                                      .` "-. `%   | |    %` .-" `.
                                                           /      \    .: :.     /      \
                                                           '-..___|_..=:` `-:=.._|___..-'
    */
    /// Buy base with fyToken.
    /// The trader needs to have transferred in the necessary amount of fyTokens in advance.
    /// @param to Wallet receiving the base being bought.
    /// @param baseOut Amount of base being bought that will be deposited in `to` wallet.
    /// @param max This has been deprecated and was left in for backwards compatibility.
    /// @return fyTokenIn Amount of fyToken that will be taken from caller.
    function buyBase(
        address to,
        uint128 baseOut,
        uint128 max
    ) external virtual override unpaused returns (uint128 fyTokenIn) {
        // Calculate trade and cache values
        uint128 fyTokenBalance = _getFYTokenBalance();
        Cache memory cache = _getCache();

        uint128 sharesOut = _wrapPreview(baseOut).u128();
        fyTokenIn = _buyBasePreview(
            sharesOut,
            cache.sharesCached,
            cache.fyTokenCached,
            _computeG2(cache.g1Fee)
        );

        // Checks
        if (fyTokenBalance - cache.fyTokenCached < fyTokenIn) {
            revert NotEnoughFYTokenIn(
                fyTokenBalance - cache.fyTokenCached,
                fyTokenIn
            );
        }

        // Update TWAR
        _update(
            cache.sharesCached - sharesOut,
            cache.fyTokenCached + fyTokenIn,
            cache.sharesCached,
            cache.fyTokenCached
        );

        // Transfer
        _unwrap(to);

        emit Trade(
            maturity,
            msg.sender,
            to,
            baseOut.i128(),
            -(fyTokenIn.i128())
        );
    }

    /// Returns how much fyToken would be required to buy `baseOut` base.
    /// @dev Note: This fn takes baseOut as a param while the internal fn takes sharesOut.
    /// @param baseOut Amount of base hypothetically desired.
    /// @return fyTokenIn Amount of fyToken hypothetically required.
    function buyBasePreview(uint128 baseOut)
        external
        view
        virtual
        override
        returns (uint128 fyTokenIn)
    {
        Cache memory cache = _getCache();
        fyTokenIn = _buyBasePreview(
            _wrapPreview(baseOut).u128(),
            cache.sharesCached,
            cache.fyTokenCached,
            _computeG2(cache.g1Fee)
        );
    }

    /// Returns how much fyToken would be required to buy `sharesOut`.
    /// @dev Note: This fn takes sharesOut as a param while the external fn takes baseOut.
    function _buyBasePreview(
        uint128 sharesOut,
        uint104 sharesBalance,
        uint104 fyTokenBalance,
        int128 g2_
    ) internal view beforeMaturity returns (uint128 fyTokenIn) {
        uint96 scaleFactor_ = scaleFactor;
        fyTokenIn =
            YieldMath.fyTokenInForSharesOut(
                sharesBalance * scaleFactor_,
                fyTokenBalance * scaleFactor_,
                sharesOut * scaleFactor_,
                maturity - uint32(block.timestamp), // This can't be called after maturity
                ts,
                g2_,
                _getC(),
                mu
            ) /
            scaleFactor_;
    }

    /*buyFYToken

                         I want to buy `uint128 fyTokenOut` worth of fyTokens.
             _______     I've transferred you some base tokens -- that should be enough.
            /   GUY \                                                 ┌─────────┐
     (^^^|   \===========  ┌──────────────┐                           │no       │
      \(\/    | _  _ |     │$            $│                           │lifeguard│
       \ \   (. o  o |     │ ┌────────────┴─┐                         └─┬─────┬─┘       ==+
        \ \   |   ~  |     │ │$            $│   hmm, let's see here     │     │    =======+
        \  \   \ == /      │ │   B A S E    │                      _____│_____│______    |+
         \  \___|  |___    │$│              │                  .-'"___________________`-.|+
          \ /   \__/   \   └─┤$            $│                 ( .'"                   '-.)+
           \            \    └──────────────┘                 |`-..__________________..-'|+
            --|  GUY |\_/\  / /                               |                          |+
              |      | \  \/ /                                |                          |+
              |      |  \   /         _......._             /`|       ---     ---        |+
              |      |   \_/       .-:::::::::::-.         / /|       (o )    (o )       |+
              |______|           .:::::::::::::::::.      / / |                          |+
              |__GG__|          :  _______  __   __ : _.-" ;  |            [             |+
              |      |         :: |       ||  | |  |::),.-'   |        ----------        |+
              |  |   |        ::: |    ___||  |_|  |:::/      \        \________/        /+
              |  |  _|        ::: |   |___ |       |:::        `-..__________________..-' +=
              |  |  |         ::: |    ___||_     _|:::               |    | |    |
              |  |  |         ::: |   |      |   |  :::               |    | |    |
              (  (  |          :: |___|      |___|  ::                |    | |    |
              |  |  |           :     fyTokenOut    :                 T----T T----T
              |  |  |            `:::::::::::::::::'             _..._L____J L____J _..._
             _|  |  |              `-:::::::::::-'             .` "-. `%   | |    %` .-" `.
            (_____[__)                `'''''''`               /      \    .: :.     /      \
                                                              '-..___|_..=:` `-:=.._|___..-'
    */
    /// Buy fyToken with base.
    /// The trader needs to have transferred in the correct amount of base tokens in advance.
    /// @param to Wallet receiving the fyToken being bought.
    /// @param fyTokenOut Amount of fyToken being bought that will be deposited in `to` wallet.
    /// @param max  This has been deprecated and was left in for backwards compatibility.
    /// @return baseIn Amount of base that will be used.
    function buyFYToken(
        address to,
        uint128 fyTokenOut,
        uint128 max
    ) external virtual override unpaused returns (uint128 baseIn) {
        // Wrap any base assets found in contract.
        _wrap(address(this));

        // Calculate trade
        uint128 sharesBalance = _getSharesBalance();
        Cache memory cache = _getCache();
        uint128 sharesIn = _buyFYTokenPreview(
            fyTokenOut,
            cache.sharesCached,
            cache.fyTokenCached,
            _computeG1(cache.g1Fee)
        );
        baseIn = _unwrapPreview(sharesIn).u128();

        // Checks
        if (sharesBalance - cache.sharesCached < sharesIn)
            revert NotEnoughBaseIn(
                _unwrapPreview(sharesBalance - cache.sharesCached),
                baseIn
            );

        // Update TWAR
        _update(
            cache.sharesCached + sharesIn,
            cache.fyTokenCached - fyTokenOut,
            cache.sharesCached,
            cache.fyTokenCached
        );

        // Transfer
        fyToken.safeTransfer(to, fyTokenOut);

        // confirm new virtual fyToken balance is not less than new supply
        if ((cache.fyTokenCached - fyTokenOut) < _totalSupply) {
            revert FYTokenCachedBadState();
        }

        emit Trade(
            maturity,
            msg.sender,
            to,
            -(baseIn.i128()),
            fyTokenOut.i128()
        );
    }

    /// Returns how much base would be required to buy `fyTokenOut`.
    /// @param fyTokenOut Amount of fyToken hypothetically desired.
    /// @dev Note: This returns an amount in base.  The internal fn returns amount of shares.
    /// @return baseIn Amount of base hypothetically required.
    function buyFYTokenPreview(uint128 fyTokenOut)
        external
        view
        virtual
        override
        returns (uint128 baseIn)
    {
        Cache memory cache = _getCache();
        uint128 sharesIn = _buyFYTokenPreview(
            fyTokenOut,
            cache.sharesCached,
            cache.fyTokenCached,
            _computeG1(cache.g1Fee)
        );

        baseIn = _unwrapPreview(sharesIn).u128();
    }

    /// Returns how many shares are required to buy `fyTokenOut` fyTokens.
    /// @dev Note: This returns an amount in shares.  The external fn returns amount of base.
    function _buyFYTokenPreview(
        uint128 fyTokenOut,
        uint128 sharesBalance,
        uint128 fyTokenBalance,
        int128 g1_
    ) internal view beforeMaturity returns (uint128 sharesIn) {
        uint96 scaleFactor_ = scaleFactor;

        sharesIn =
            YieldMath.sharesInForFYTokenOut(
                sharesBalance * scaleFactor_,
                fyTokenBalance * scaleFactor_,
                fyTokenOut * scaleFactor_,
                maturity - uint32(block.timestamp), // This can't be called after maturity
                ts,
                g1_,
                _getC(),
                mu
            ) /
            scaleFactor_;

        uint128 newSharesMulMu = _mulMu(sharesBalance + sharesIn).u128();
        if ((fyTokenBalance - fyTokenOut) < newSharesMulMu) {
            revert NegativeInterestRatesNotAllowed(
                fyTokenBalance - fyTokenOut,
                newSharesMulMu
            );
        }
    }

    /* sellBase

                         I've transfered you some base tokens.
             _______     Can you swap them for fyTokens?
            /   GUY \                                                 ┌─────────┐
     (^^^|   \===========  ┌──────────────┐                           │no       │
      \(\/    | _  _ |     │$            $│                           │lifeguard│
       \ \   (. o  o |     │ ┌────────────┴─┐                         └─┬─────┬─┘       ==+
        \ \   |   ~  |     │ │$            $│             can           │     │    =======+
        \  \   \ == /      │ │              │                      _____│_____│______    |+
         \  \___|  |___    │$│    baseIn    │                  .-'"___________________`-.|+
          \ /   \__/   \   └─┤$            $│                 ( .'"                   '-.)+
           \            \   ( └──────────────┘                 |`-..__________________..-'|+
            --|  GUY |\_/\  / /                               |                          |+
              |      | \  \/ /                                |                          |+
              |      |  \   /         _......._             /`|       ---     ---        |+
              |      |   \_/       .-:::::::::::-.         / /|       (o )    (o )       |+
              |______|           .:::::::::::::::::.      / / |                          |+
              |__GG__|          :  _______  __   __ : _.-" ;  |            [             |+
              |      |         :: |       ||  | |  |::),.-'   |        ----------        |+
              |  |   |        ::: |    ___||  |_|  |:::/      \        \________/        /+
              |  |  _|        ::: |   |___ |       |:::        `-..__________________..-' +=
              |  |  |         ::: |    ___||_     _|:::               |    | |    |
              |  |  |         ::: |   |      |   |  :::               |    | |    |
              (  (  |          :: |___|      |___|  ::                |    | |    |
              |  |  |           :      ????         :                 T----T T----T
              |  |  |            `:::::::::::::::::'             _..._L____J L____J _..._
             _|  |  |              `-:::::::::::-'             .` "-. `%   | |    %` .-" `.
            (_____[__)                `'''''''`               /      \    .: :.     /      \
                                                              '-..___|_..=:` `-:=.._|___..-'
    */
    /// Sell base for fyToken.
    /// The trader needs to have transferred the amount of base to sell to the pool before calling this fn.
    /// @param to Wallet receiving the fyToken being bought.
    /// @param min Minimum accepted amount of fyToken.
    /// @return fyTokenOut Amount of fyToken that will be deposited on `to` wallet.
    function sellBase(address to, uint128 min)
        external
        virtual
        override
        unpaused
        returns (uint128 fyTokenOut)
    {
        // Wrap any base assets found in contract.
        _wrap(address(this));

        // Calculate trade
        Cache memory cache = _getCache();
        uint104 sharesBalance = _getSharesBalance();
        uint128 sharesIn = sharesBalance - cache.sharesCached;
        fyTokenOut = _sellBasePreview(
            sharesIn,
            cache.sharesCached,
            cache.fyTokenCached,
            _computeG1(cache.g1Fee)
        );

        // Check slippage
        if (fyTokenOut < min) revert SlippageDuringSellBase(fyTokenOut, min);

        // Update TWAR
        _update(
            sharesBalance,
            cache.fyTokenCached - fyTokenOut,
            cache.sharesCached,
            cache.fyTokenCached
        );

        // Transfer
        fyToken.safeTransfer(to, fyTokenOut);

        // confirm new virtual fyToken balance is not less than new supply
        if ((cache.fyTokenCached - fyTokenOut) < _totalSupply) {
            revert FYTokenCachedBadState();
        }

        emit Trade(
            maturity,
            msg.sender,
            to,
            -(_unwrapPreview(sharesIn).u128().i128()),
            fyTokenOut.i128()
        );
    }

    /// Returns how much fyToken would be obtained by selling `baseIn`.
    /// @dev Note: This external fn takes baseIn while the internal fn takes sharesIn.
    /// @param baseIn Amount of base hypothetically sold.
    /// @return fyTokenOut Amount of fyToken hypothetically bought.
    function sellBasePreview(uint128 baseIn)
        external
        view
        virtual
        override
        returns (uint128 fyTokenOut)
    {
        Cache memory cache = _getCache();
        fyTokenOut = _sellBasePreview(
            _wrapPreview(baseIn).u128(),
            cache.sharesCached,
            cache.fyTokenCached,
            _computeG1(cache.g1Fee)
        );
    }

    /// Returns how much fyToken would be obtained by selling `sharesIn`.
    /// @dev Note: This internal fn takes sharesIn while the external fn takes baseIn.
    function _sellBasePreview(
        uint128 sharesIn,
        uint104 sharesBalance,
        uint104 fyTokenBalance,
        int128 g1_
    ) internal view beforeMaturity returns (uint128 fyTokenOut) {
        uint96 scaleFactor_ = scaleFactor;
        fyTokenOut =
            YieldMath.fyTokenOutForSharesIn(
                sharesBalance * scaleFactor_,
                fyTokenBalance * scaleFactor_,
                sharesIn * scaleFactor_,
                maturity - uint32(block.timestamp), // This can't be called after maturity
                ts,
                g1_,
                _getC(),
                mu
            ) /
            scaleFactor_;

        uint128 newSharesMulMu = _mulMu(sharesBalance + sharesIn).u128();
        if ((fyTokenBalance - fyTokenOut) < newSharesMulMu) {
            revert NegativeInterestRatesNotAllowed(
                fyTokenBalance - fyTokenOut,
                newSharesMulMu
            );
        }
    }

    /*sellFYToken
                         I've transferred you some fyTokens.
             _______     Can you swap them for base?
            /   GUY \         .:::::::::::::::::.
     (^^^|   \===========    :  _______  __   __ :                 ┌─────────┐
      \(\/    | _  _ |      :: |       ||  | |  |::                │no       │
       \ \   (. o  o |     ::: |    ___||  |_|  |:::               │lifeguard│
        \ \   |   ~  |     ::: |   |___ |       |:::               └─┬─────┬─┘       ==+
        \  \   \ == /      ::: |    ___||_     _|:::     lfg         │     │    =======+
         \  \___|  |___    ::: |   |      |   |  :::            _____│_____│______    |+
          \ /   \__/   \    :: |___|      |___|  ::         .-'"___________________`-.|+
           \            \    :      fyTokenIn    :         ( .'"                   '-.)+
            --|  GUY |\_/\  / `:::::::::::::::::'          |`-..__________________..-'|+
              |      | \  \/ /  `-:::::::::::-'            |                          |+
              |      |  \   /      `'''''''`               |                          |+
              |      |   \_/                               |       ---     ---        |+
              |______|                                     |       (o )    (o )       |+
              |__GG__|             ┌──────────────┐      /`|                          |+
              |      |             │$            $│     / /|            [             |+
              |  |   |             │   B A S E    │    / / |        ----------        |+
              |  |  _|             │    ????      │\.-" ;  \        \________/        /+
              |  |  |              │$            $│),.-'    `-..__________________..-' +=
              |  |  |              └──────────────┘                |    | |    |
              (  (  |                                              |    | |    |
              |  |  |                                              |    | |    |
              |  |  |                                              T----T T----T
             _|  |  |                                         _..._L____J L____J _..._
            (_____[__)                                      .` "-. `%   | |    %` .-" `.
                                                           /      \    .: :.     /      \
                                                           '-..___|_..=:` `-:=.._|___..-'
    */
    /// Sell fyToken for base.
    /// The trader needs to have transferred the amount of fyToken to sell to the pool before in the same transaction.
    /// @param to Wallet receiving the base being bought.
    /// @param min Minimum accepted amount of base.
    /// @return baseOut Amount of base that will be deposited on `to` wallet.
    function sellFYToken(address to, uint128 min)
        external
        virtual
        override
        unpaused
        returns (uint128 baseOut)
    {
        // Calculate trade
        Cache memory cache = _getCache();
        uint104 fyTokenBalance = _getFYTokenBalance();
        uint128 fyTokenIn = fyTokenBalance - cache.fyTokenCached;
        uint128 sharesOut = _sellFYTokenPreview(
            fyTokenIn,
            cache.sharesCached,
            cache.fyTokenCached,
            _computeG2(cache.g1Fee)
        );

        // Update TWAR
        _update(
            cache.sharesCached - sharesOut,
            fyTokenBalance,
            cache.sharesCached,
            cache.fyTokenCached
        );

        // Transfer
        baseOut = _unwrap(to).u128();

        // Check slippage
        if (baseOut < min) revert SlippageDuringSellFYToken(baseOut, min);

        emit Trade(
            maturity,
            msg.sender,
            to,
            baseOut.i128(),
            -(fyTokenIn.i128())
        );
    }

    /// Returns how much base would be obtained by selling `fyTokenIn` fyToken.
    /// @dev Note: This external fn returns baseOut while the internal fn returns sharesOut.
    /// @param fyTokenIn Amount of fyToken hypothetically sold.
    /// @return baseOut Amount of base hypothetically bought.
    function sellFYTokenPreview(uint128 fyTokenIn)
        public
        view
        virtual
        returns (uint128 baseOut)
    {
        Cache memory cache = _getCache();
        uint128 sharesOut = _sellFYTokenPreview(
            fyTokenIn,
            cache.sharesCached,
            cache.fyTokenCached,
            _computeG2(cache.g1Fee)
        );
        baseOut = _unwrapPreview(sharesOut).u128();
    }

    /// Returns how much base would be obtained by selling `fyTokenIn` fyToken.
    /// An alternate version of the preview method which allows manual shares and fyToken input
    /// @dev Note: This external fn returns baseOut while the internal fn returns sharesOut.
    /// @param fyTokenIn Amount of fyToken hypothetically sold.
    /// @param shares The amount of shares held by the pool
    /// @param fyTokens The amount of fyTokens (including virtual) held by the pool
    /// @return baseOut Amount of base hypothetically bought.
    function sellFYTokenPreview(
        uint128 fyTokenIn,
        uint128 shares,
        uint128 fyTokens
    ) public view virtual returns (uint128 baseOut) {
        uint128 sharesOut = _sellFYTokenPreview(
            fyTokenIn,
            uint104(shares),
            uint104(fyTokens),
            _computeG2(g1Fee)
        );
        baseOut = _unwrapPreview(sharesOut).u128();
    }

    /// Returns how much shares would be obtained by selling `fyTokenIn` fyToken.
    /// @dev Note: This internal fn returns sharesOut while the external fn returns baseOut.
    function _sellFYTokenPreview(
        uint128 fyTokenIn,
        uint104 sharesBalance,
        uint104 fyTokenBalance,
        int128 g2_
    ) internal view beforeMaturity returns (uint128 sharesOut) {
        uint96 scaleFactor_ = scaleFactor;

        sharesOut =
            YieldMath.sharesOutForFYTokenIn(
                sharesBalance * scaleFactor_,
                fyTokenBalance * scaleFactor_,
                fyTokenIn * scaleFactor_,
                maturity - uint32(block.timestamp), // This can't be called after maturity
                ts,
                g2_,
                _getC(),
                mu
            ) /
            scaleFactor_;
    }

    /* LIQUIDITY FUNCTIONS
     ****************************************************************************************************************/

    /// @inheritdoc IPool
    function maxFYTokenIn() public view override returns (uint128 fyTokenIn) {
        uint96 scaleFactor_ = scaleFactor;
        Cache memory cache = _getCache();
        fyTokenIn =
            YieldMath.maxFYTokenIn(
                cache.sharesCached * scaleFactor_,
                cache.fyTokenCached * scaleFactor_,
                maturity - uint32(block.timestamp), // This can't be called after maturity
                ts,
                _computeG2(cache.g1Fee),
                _getC(),
                mu
            ) /
            scaleFactor_;
    }

    /// @inheritdoc IPool
    function maxFYTokenOut() public view override returns (uint128 fyTokenOut) {
        uint96 scaleFactor_ = scaleFactor;
        Cache memory cache = _getCache();
        fyTokenOut =
            YieldMath.maxFYTokenOut(
                cache.sharesCached * scaleFactor_,
                cache.fyTokenCached * scaleFactor_,
                maturity - uint32(block.timestamp), // This can't be called after maturity
                ts,
                _computeG1(cache.g1Fee),
                _getC(),
                mu
            ) /
            scaleFactor_;
    }

    /// @inheritdoc IPool
    function maxBaseIn() public view override returns (uint128 baseIn) {
        uint96 scaleFactor_ = scaleFactor;
        Cache memory cache = _getCache();
        uint128 sharesIn = ((YieldMath.maxSharesIn(
            cache.sharesCached * scaleFactor_,
            cache.fyTokenCached * scaleFactor_,
            maturity - uint32(block.timestamp), // This can't be called after maturity
            ts,
            _computeG1(cache.g1Fee),
            _getC(),
            mu
        ) / 1e8) * 1e8) / scaleFactor_; // Shave 8 wei/decimals to deal with precision issues on the decimal functions

        baseIn = _unwrapPreview(sharesIn).u128();
    }

    /// @inheritdoc IPool
    function maxBaseOut() public view override returns (uint128 baseOut) {
        uint128 sharesOut = _getCache().sharesCached;
        baseOut = _unwrapPreview(sharesOut).u128();
    }

    /// @inheritdoc IPool
    function invariant() public view override returns (uint128 result) {
        uint96 scaleFactor_ = scaleFactor;
        Cache memory cache = _getCache();
        result =
            YieldMath.invariant(
                cache.sharesCached * scaleFactor_,
                cache.fyTokenCached * scaleFactor_,
                _totalSupply * scaleFactor_,
                maturity - uint32(block.timestamp),
                ts,
                _computeG2(cache.g1Fee),
                _getC(),
                mu
            ) /
            scaleFactor_;
    }

    /* WRAPPING FUNCTIONS
     ****************************************************************************************************************/

    /// Wraps any base asset tokens found in the contract, converting them to base tokenized vault shares.
    /// @dev This is provided as a convenience and uses the 4626 deposit method.
    /// @param receiver The address to which the wrapped tokens will be sent.
    /// @return shares The amount of wrapped tokens sent to the receiver.
    function wrap(address receiver) external returns (uint256 shares) {
        shares = _wrap(receiver);
    }

    /// Internal function for wrapping base tokens whichwraps the entire balance of base found in this contract.
    /// @dev This should be overridden by modules.
    /// @param receiver The address the wrapped tokens should be sent.
    /// @return shares The amount of wrapped tokens that are sent to the receiver.
    function _wrap(address receiver) internal virtual returns (uint256 shares) {
        uint256 assets = baseToken.balanceOf(address(this));
        if (assets == 0) {
            shares = 0;
        } else {
            shares = IERC4626(address(sharesToken)).deposit(assets, receiver);
        }
    }

    /// Preview how many shares will be received when depositing a given amount of base.
    /// @dev This should be overridden by modules.
    /// @param assets The amount of base tokens to preview the deposit.
    /// @return shares The amount of shares that would be returned from depositing.
    function wrapPreview(uint256 assets)
        external
        view
        returns (uint256 shares)
    {
        shares = _wrapPreview(assets);
    }

    /// Internal function to preview how many shares will be received when depositing a given amount of assets.
    /// @param assets The amount of base tokens to preview the deposit.
    /// @return shares The amount of shares that would be returned from depositing.
    function _wrapPreview(uint256 assets)
        internal
        view
        virtual
        returns (uint256 shares)
    {
        if (assets == 0) {
            shares = 0;
        } else {
            shares = IERC4626(address(sharesToken)).previewDeposit(assets);
        }
    }

    /// Unwraps base shares found unaccounted for in this contract, converting them to the base assets.
    /// @dev This is provided as a convenience and uses the 4626 redeem method.
    /// @param receiver The address to which the assets will be sent.
    /// @return assets The amount of asset tokens sent to the receiver.
    function unwrap(address receiver) external returns (uint256 assets) {
        assets = _unwrap(receiver);
    }

    /// Internal function for unwrapping unaccounted for base in this contract.
    /// @dev This should be overridden by modules.
    /// @param receiver The address the wrapped tokens should be sent.
    /// @return assets The amount of base assets sent to the receiver.
    function _unwrap(address receiver)
        internal
        virtual
        returns (uint256 assets)
    {
        uint256 surplus = _getSharesBalance() - sharesCached;
        if (surplus == 0) {
            assets = 0;
        } else {
            // The third param of the 4626 redeem fn, `owner`, is always this contract address.
            assets = IERC4626(address(sharesToken)).redeem(
                surplus,
                receiver,
                address(this)
            );
        }
    }

    /// Preview how many asset tokens will be received when unwrapping a given amount of shares.
    /// @param shares The amount of shares to preview a redemption.
    /// @return assets The amount of base tokens that would be returned from redeeming.
    function unwrapPreview(uint256 shares)
        external
        view
        returns (uint256 assets)
    {
        assets = _unwrapPreview(shares);
    }

    /// Internal function to preview how base asset tokens will be received when unwrapping a given amount of shares.
    /// @dev This should be overridden by modules.
    /// @param shares The amount of shares to preview a redemption.
    /// @return assets The amount of base tokens that would be returned from redeeming.
    function _unwrapPreview(uint256 shares)
        internal
        view
        virtual
        returns (uint256 assets)
    {
        if (shares == 0) {
            assets = 0;
        } else {
            assets = IERC4626(address(sharesToken)).previewRedeem(shares);
        }
    }

    /* BALANCES MANAGEMENT AND ADMINISTRATIVE FUNCTIONS
       Note: The sync() function has been discontinued and removed.
     *****************************************************************************************************************/
    /*
                  _____________________________________
                   |o o o o o o o o o o o o o o o o o|
                   |o o o o o o o o o o o o o o o o o|
                   ||_|_|_|_|_|_|_|_|_|_|_|_|_|_|_|_||
                   || | | | | | | | | | | | | | | | ||
                   |o o o o o o o o o o o o o o o o o|
                   |o o o o o o o o o o o o o o o o o|
                   |o o o o o o o o o o o o o o o o o|
                   |o o o o o o o o o o o o o o o o o|
                  _|o_o_o_o_o_o_o_o_o_o_o_o_o_o_o_o_o|_
                          "Poolie's Abacus" - ejm */

    /// Calculates cumulative ratio as of current timestamp.  Can be consumed for TWAR observations.
    /// @dev See UniV2 implmentation: https://tinyurl.com/UniV2currentCumulativePrice
    /// @return currentCumulativeRatio_ is the cumulative ratio up to the current timestamp as ray.
    /// @return blockTimestampCurrent is the current block timestamp that the currentCumulativeRatio was computed with.
    function currentCumulativeRatio()
        external
        view
        virtual
        returns (uint256 currentCumulativeRatio_, uint256 blockTimestampCurrent)
    {
        blockTimestampCurrent = block.timestamp;
        uint256 timeElapsed;
        unchecked {
            timeElapsed = blockTimestampCurrent - blockTimestampLast;
        }

        // Multiply by 1e27 here so that r = t * y/x is a fixed point factor with 27 decimals
        currentCumulativeRatio_ =
            cumulativeRatioLast +
            (fyTokenCached * timeElapsed).rdiv(_mulMu(sharesCached));
    }

    /// Update cached values and, on the first call per block, update cumulativeRatioLast.
    /// cumulativeRatioLast is a LAGGING, time weighted sum of the reserves ratio which is updated as follows:
    ///
    ///   cumulativeRatioLast += old fyTokenReserves / old baseReserves * seconds elapsed since blockTimestampLast
    ///
    /// NOTE: baseReserves is calculated as mu * sharesReserves
    ///
    /// Example:
    ///   First mint creates a ratio of 1:1.
    ///   300 seconds later a trade occurs:
    ///     - cumulativeRatioLast is updated: 0 + 1/1 * 300 == 300
    ///     - sharesCached and fyTokenCached are updated with the new reserves amounts.
    ///     - This causes the ratio to skew to 1.1 / 1.
    ///   200 seconds later another trade occurs:
    ///     - NOTE: During this 200 seconds, cumulativeRatioLast == 300, which represents the "last" updated amount.
    ///     - cumulativeRatioLast is updated: 300 + 1.1 / 1 * 200 == 520
    ///     - sharesCached and fyTokenCached updated accordingly...etc.
    ///
    /// @dev See UniV2 implmentation: https://tinyurl.com/UniV2UpdateCumulativePrice
    function _update(
        uint128 sharesBalance,
        uint128 fyBalance,
        uint104 sharesCached_,
        uint104 fyTokenCached_
    ) internal {
        // No need to update and spend gas on SSTORE if reserves haven't changed.
        if (sharesBalance == sharesCached_ && fyBalance == fyTokenCached_)
            return;

        uint32 blockTimestamp = uint32(block.timestamp);
        uint256 timeElapsed = blockTimestamp - blockTimestampLast; // reverts on underflow

        uint256 oldCumulativeRatioLast = cumulativeRatioLast;
        uint256 newCumulativeRatioLast = oldCumulativeRatioLast;
        if (timeElapsed > 0 && fyTokenCached_ > 0 && sharesCached_ > 0) {
            // Multiply by 1e27 here so that r = t * y/x is a fixed point factor with 27 decimals
            newCumulativeRatioLast += (fyTokenCached_ * timeElapsed).rdiv(
                _mulMu(sharesCached_)
            );
        }

        blockTimestampLast = blockTimestamp;
        cumulativeRatioLast = newCumulativeRatioLast;

        // Update the reserves caches
        uint104 newSharesCached = sharesBalance.u104();
        uint104 newFYTokenCached = fyBalance.u104();

        sharesCached = newSharesCached;
        fyTokenCached = newFYTokenCached;

        emit Sync(newSharesCached, newFYTokenCached, newCumulativeRatioLast);
    }

    /// Exposes the 64.64 factor used for determining fees.
    /// A value of 1 (in 64.64) means no fees.  g1 < 1 because it is used when selling base shares to the pool.
    /// @dev Converts state var cache.g1Fee(fp4) to a 64bit divided by 10,000
    /// Useful for external contracts that need to perform calculations related to pool.
    /// @return a 64bit factor used for applying fees when buying fyToken/selling base.
    function g1() external view returns (int128) {
        Cache memory cache = _getCache();
        return _computeG1(cache.g1Fee);
    }

    /// Returns the ratio of net proceeds after fees, for buying fyToken
    function _computeG1(uint16 g1Fee_) internal pure returns (int128) {
        return uint256(g1Fee_).divu(10000);
    }

    /// Exposes the 64.64 factor used for determining fees.
    /// A value of 1 means no fees.  g2 > 1 because it is used when selling fyToken to the pool.
    /// @dev Calculated by dividing 10,000 by state var cache.g1Fee(fp4) and converting to 64bit.
    /// Useful for external contracts that need to perform calculations related to pool.
    /// @return a 64bit factor used for applying fees when selling fyToken/buying base.
    function g2() external view returns (int128) {
        Cache memory cache = _getCache();
        return _computeG2(cache.g1Fee);
    }

    /// Returns the ratio of net proceeds after fees, for selling fyToken
    function _computeG2(uint16 g1Fee_) internal pure returns (int128) {
        // Divide 1 (64.64) by g1
        return uint256(10000).divu(g1Fee_);
    }

    /// Returns the shares balance with the same decimals as the underlying base asset.
    /// @dev NOTE: If the decimals of the share token does not match the base token, then the amount of shares returned
    /// will be adjusted to match the decimals of the base token.
    /// @return The current balance of the pool's shares tokens as uint128 for consistency with other functions.
    function getSharesBalance() external view returns (uint128) {
        return _getSharesBalance();
    }

    /// Returns the shares balance
    /// @dev NOTE: The decimals returned here must match the decimals of the base token.  If not, then this fn should
    // be overriden by modules.
    function _getSharesBalance() internal view virtual returns (uint104) {
        return sharesToken.balanceOf(address(this)).u104();
    }

    /// Returns the base balance.
    /// @dev Returns uint128 for backwards compatibility
    /// @return The current balance of the pool's base tokens.
    function getBaseBalance() external view returns (uint128) {
        return _getBaseBalance().u128();
    }

    /// Returns the base balance
    function _getBaseBalance() internal view virtual returns (uint256) {
        return
            (_getSharesBalance() * _getCurrentSharePrice()) / 10**baseDecimals;
    }

    /// Returns the base token current price.
    /// @return The price of 1 share of a tokenized vault token in terms of its base cast as uint256.
    function getCurrentSharePrice() external view returns (uint256) {
        return _getCurrentSharePrice();
    }

    /// Returns the base token current price.
    /// @dev This assumes the shares, base, and lp tokens all use the same decimals.
    /// This function should be overriden by modules.
    /// @return The price of 1 share of a tokenized vault token in terms of its base asset cast as uint256.
    function _getCurrentSharePrice() internal view virtual returns (uint256) {
        uint256 scalar = 10**baseDecimals;
        return IERC4626(address(sharesToken)).convertToAssets(scalar);
    }

    /// Returns current price of 1 share in 64bit.
    /// Useful for external contracts that need to perform calculations related to pool.
    /// @return The current price (as determined by the token) scalled to 18 digits and converted to 64.64.
    function getC() external view returns (int128) {
        return _getC();
    }

    /// Returns the c based on the current price
    function _getC() internal view returns (int128) {
        return (_getCurrentSharePrice() * scaleFactor).divu(1e18);
    }

    /// Returns the all storage vars except for cumulativeRatioLast
    /// @return Cached shares token balance.
    /// @return Cached virtual FY token balance which is the actual balance plus the pool token supply.
    /// @return Timestamp that balances were last cached.
    /// @return g1Fee  This is a fp4 number where 10_000 is 1.
    function getCache()
        public
        view
        virtual
        returns (
            uint104,
            uint104,
            uint32,
            uint16
        )
    {
        return (sharesCached, fyTokenCached, blockTimestampLast, g1Fee);
    }

    /// Returns the all storage vars except for cumulativeRatioLast
    /// @dev This returns the same info as external getCache but uses a struct to help with stack too deep.
    /// @return cache A struct containing:
    /// g1Fee a fp4 number where 10_000 is 1.
    /// Cached base token balance.
    /// Cached virtual FY token balance which is the actual balance plus the pool token supply.
    /// Timestamp that balances were last cached.

    function _getCache() internal view virtual returns (Cache memory cache) {
        cache = Cache(g1Fee, sharesCached, fyTokenCached, blockTimestampLast);
    }

    /// The "virtual" fyToken balance, which is the actual balance plus the pool token supply.
    /// @dev For more explanation about using the LP tokens as part of the virtual reserves see:
    /// https://hackmd.io/lRZ4mgdrRgOpxZQXqKYlFw
    /// Returns uint128 for backwards compatibility
    /// @return The current balance of the pool's fyTokens plus the current balance of the pool's
    /// total supply of LP tokens as a uint104
    function getFYTokenBalance()
        public
        view
        virtual
        override
        returns (uint128)
    {
        return _getFYTokenBalance();
    }

    /// Returns the "virtual" fyToken balance, which is the real balance plus the pool token supply.
    function _getFYTokenBalance() internal view returns (uint104) {
        return (fyToken.balanceOf(address(this)) + _totalSupply).u104();
    }

    /// Returns mu multipled by given amount.
    /// @param amount Amount as standard fp number.
    /// @return product Return standard fp number retaining decimals of provided amount.
    function _mulMu(uint256 amount) internal view returns (uint256 product) {
        product = mu.mulu(amount);
    }

    /// Retrieve any shares tokens not accounted for in the cache.
    /// @param to Address of the recipient of the shares tokens.
    /// @return retrieved The amount of shares tokens sent.
    function retrieveShares(address to)
        external
        virtual
        override
        returns (uint128 retrieved)
    {
        retrieved = _getSharesBalance() - sharesCached; // Cache can never be above balances
        sharesToken.safeTransfer(to, retrieved);
    }

    /// Retrieve all base tokens found in this contract.
    /// @param to Address of the recipient of the base tokens.
    /// @return retrieved The amount of base tokens sent.
    function retrieveBase(address to)
        external
        virtual
        override
        returns (uint128 retrieved)
    {
        // This and most other pools do not keep any baseTokens, so retrieve everything.
        // Note: For PoolNonTv, baseToken == sharesToken so must override this fn.
        retrieved = baseToken.balanceOf(address(this)).u128();
        baseToken.safeTransfer(to, retrieved);
    }

    /// Retrieve any fyTokens not accounted for in the cache.
    /// @param to Address of the recipient of the fyTokens.
    /// @return retrieved The amount of fyTokens sent.
    function retrieveFYToken(address to)
        external
        virtual
        override
        returns (uint128 retrieved)
    {
        // related: https://twitter.com/transmissions11/status/1505994136389754880?s=20&t=1H6gvzl7DJLBxXqnhTuOVw
        retrieved = _getFYTokenBalance() - fyTokenCached; // Cache can never be above balances
        fyToken.safeTransfer(to, retrieved);
        // Now the balances match the cache, so no need to update the TWAR
    }

    /// Sets g1 as an fp4, g1 <= 1.0
    /// @dev These numbers are converted to 64.64 and used to calculate g1 by dividing them, or g2 from 1/g1
    function setFees(uint16 g1Fee_) external authorized(admin) {
        if (g1Fee_ > 10000) {
            revert InvalidFee(g1Fee_);
        }
        g1Fee = g1Fee_;
        emit FeesSet(g1Fee_);
    }

    /// Allows the admin to transfer ownership of the contract
    function setAdmin(address a) external authorized(admin) {
        admin = a;
    }

    /// Allows the admin to pause or unpause the pool
    /// @param b True if paused, False if unpaused
    function pause(bool b) external authorized(admin) {
        paused = b;
        emit PausePool(b);
    }

    /// Returns baseToken.
    /// @dev This has been deprecated and may be removed in future pools.
    /// @return baseToken The base token for this pool.  The base of the shares and the fyToken.
    function base() external view returns (IERC20) {
        // Returns IERC20 instead of IERC20Like (IERC20Metadata) for backwards compatability.
        return IERC20(address(baseToken));
    }
}

interface IEToken is IERC20, IERC20Metadata {
    /// @notice Convert an eToken balance to an underlying amount, taking into account current exchange rate
    /// @param balance eToken balance, in internal book-keeping units (18 decimals)
    /// @return Amount in underlying units, (same decimals as underlying token)
    function convertBalanceToUnderlying(uint256 balance)
        external
        view
        returns (uint256);

    /// @notice Convert an underlying amount to an eToken balance, taking into account current exchange rate
    /// @param underlyingAmount Amount in underlying units (same decimals as underlying token)
    /// @return eToken balance, in internal book-keeping units (18 decimals)
    function convertUnderlyingToBalance(uint256 underlyingAmount)
        external
        view
        returns (uint256);

    /// @notice Transfer underlying tokens from sender to the Euler pool, and increase account's eTokens.
    /// @param subAccountId 0 for primary, 1-255 for a sub-account.
    /// @param amount In underlying units (use max uint256 for full underlying token balance).
    /// subAccountId is the id of optional subaccounts that can be used by the depositor.
    function deposit(uint256 subAccountId, uint256 amount) external;

    function underlyingAsset() external view returns (address);

    /// @notice Transfer underlying tokens from Euler pool to sender, and decrease account's eTokens
    /// @param subAccountId 0 for primary, 1-255 for a sub-account
    /// @param amount In underlying units (use max uint256 for full pool balance)
    function withdraw(uint256 subAccountId, uint256 amount) external;
}

/*

  __     ___      _     _
  \ \   / (_)    | |   | |
   \ \_/ / _  ___| | __| |
    \   / | |/ _ \ |/ _` |
     | |  | |  __/ | (_| |
     |_|  |_|\___|_|\__,_|
       yieldprotocol.com

  ██████╗  ██████╗  ██████╗ ██╗     ███████╗██╗   ██╗██╗     ███████╗██████╗
  ██╔══██╗██╔═══██╗██╔═══██╗██║     ██╔════╝██║   ██║██║     ██╔════╝██╔══██╗
  ██████╔╝██║   ██║██║   ██║██║     █████╗  ██║   ██║██║     █████╗  ██████╔╝
  ██╔═══╝ ██║   ██║██║   ██║██║     ██╔══╝  ██║   ██║██║     ██╔══╝  ██╔══██╗
  ██║     ╚██████╔╝╚██████╔╝███████╗███████╗╚██████╔╝███████╗███████╗██║  ██║
  ╚═╝      ╚═════╝  ╚═════╝ ╚══════╝╚══════╝ ╚═════╝ ╚══════╝╚══════╝╚═╝  ╚═╝

*/

/// Module for using non-4626 compliant Euler etokens as base for the Yield Protocol Pool.sol AMM contract.
/// Adapted from: https://docs.euler.finance/developers/integration-guide
/// @dev Since Euler "eTokens" are not currently ERC4626 compliant, this contract inherits the Yield Pool
/// contract and overwrites the functions that are unique to Euler.
/// @title  PoolEuler.sol
/// @dev Deploy pool with Euler Pool contract and associated fyToken.
/// @author @devtooligan
contract PoolEuler is Pool {
    using TransferHelper for IERC20Like;
    using CastU256U104 for uint256;
    using CastU256U128 for uint256;

    constructor(
        address euler_, // The main Euler contract address
        address eToken_,
        address fyToken_,
        int128 ts_,
        uint16 g1Fee_
    ) Pool(eToken_, fyToken_, ts_, g1Fee_) {
        // Approve the main Euler contract to take base from the Pool, used on `deposit`.
        _getBaseAsset(eToken_).safeApprove(euler_, type(uint256).max);
        _getBaseAsset(eToken_).safeApprove(eToken_, type(uint256).max);
    }

    /// **This function is intentionally empty to overwrite the Pool._approveSharesToken fn.**
    /// This is normally used by Pool.constructor give max approval to sharesToken, but Euler tokens require approval
    /// of the main Euler contract -- not of the individual sharesToken contracts. The required approval is given above
    /// in the constructor.
    function _approveSharesToken(IERC20Like baseToken_, address sharesToken_)
        internal
        virtual
        override
    {}

    /// This is used by the constructor to set the base asset token as immutable.
    function _getBaseAsset(address sharesToken_)
        internal
        virtual
        override
        returns (IERC20Like)
    {
        return IERC20Like(address(IEToken(sharesToken_).underlyingAsset()));
    }

    /// Returns the base token current price.
    /// This function should be overriden by modules.
    /// @dev Euler tokens are all 18 decimals.
    /// @return The price of 1 share of a Euler token in terms of its underlying base asset with base asset decimals.
    function _getCurrentSharePrice()
        internal
        view
        virtual
        override
        returns (uint256)
    {
        // The return is in the decimals of the underlying.
        return IEToken(address(sharesToken)).convertBalanceToUnderlying(1e18);
    }

    /// Returns the shares balance TODO: lots of notes
    /// The decimals of the shares amount returned is adjusted to match the decimals of the baseToken
    function _getSharesBalance()
        internal
        view
        virtual
        override
        returns (uint104)
    {
        return (sharesToken.balanceOf(address(this)) / scaleFactor).u104();
    }

    /// Internal function for wrapping base asset tokens.
    /// @param receiver The address the wrapped tokens should be sent.
    /// @return shares The amount of wrapped tokens that are sent to the receiver.
    function _wrap(address receiver)
        internal
        virtual
        override
        returns (uint256 shares)
    {
        uint256 baseOut = baseToken.balanceOf(address(this));
        if (baseOut == 0) return 0;

        IEToken(address(sharesToken)).deposit(0, baseOut); // first param is subaccount, 0 for primary
        shares = _getSharesBalance() - sharesCached; // this includes any shares in pool previously
        if (receiver != address(this)) {
            sharesToken.safeTransfer(receiver, shares);
        }
    }

    /// Internal function to preview how many shares will be received when depositing a given amount of assets.
    /// @param assets The amount of base asset tokens to preview the deposit in native decimals.
    /// @return shares The amount of shares that would be returned from depositing (converted to base decimals).
    function _wrapPreview(uint256 assets)
        internal
        view
        virtual
        override
        returns (uint256 shares)
    {
        shares =
            IEToken(address(sharesToken)).convertUnderlyingToBalance(assets) /
            scaleFactor;
    }

    /// Internal function for unwrapping unaccounted for base in this contract.
    /// @param receiver The address the wrapped tokens should be sent.
    /// @return assets The amount of assets sent to the receiver in native decimals.
    function _unwrap(address receiver)
        internal
        virtual
        override
        returns (uint256 assets)
    {
        uint256 surplus = _getSharesBalance() - sharesCached;
        if (surplus == 0) return 0;
        // convert to base
        assets = _unwrapPreview(surplus);
        IEToken(address(sharesToken)).withdraw(0, assets); // first param is subaccount, 0 for primary

        if (receiver != address(this)) {
            baseToken.safeTransfer(
                receiver,
                baseToken.balanceOf(address(this))
            );
        }
    }

    /// Internal function to preview how many base tokens will be received when unwrapping a given amount of shares.
    /// @dev NOTE: eToken contracts are all 18 decimals. Because Pool.sol expects share tokens to use the same decimals
    /// as the base taken, when shares balance is needed, we convert the result of shares.balanceOf() to the base
    /// decimals via the overridden _getSharesBalance(). Therefore, this _unwrapPreview() expects to receive share
    /// amounts which have already been converted to base decimals. However, the eToken convertBalanceToUnderlying()
    /// used in this fn requires share amounts in 18 decimals so we scale the shareAmount back up to fp18 and pass
    /// as a parameter.  Fortunately, the return value from the convertBalanceToUnderlying() is in base decimals so
    /// we don't have to do any further conversions, yay.
    /// @param sharesInBaseDecimals The amount of shares to preview a redemption (converted to base decimals).
    /// @return assets The amount of base asset tokens that would be returned from redeeming (in base decimals).
    function _unwrapPreview(uint256 sharesInBaseDecimals)
        internal
        view
        virtual
        override
        returns (uint256 assets)
    {
        assets = IEToken(address(sharesToken)).convertBalanceToUnderlying(
            sharesInBaseDecimals * scaleFactor
        );
    }

    /// Retrieve any shares tokens not accounted for in the cache.
    /// @param to Address of the recipient of the shares tokens.
    /// @return retrieved The amount of shares tokens sent (in eToken decimals -- 18).
    function retrieveShares(address to)
        external
        virtual
        override
        returns (uint128 retrieved)
    {
        // sharesCached is stored by Yield with the same decimals as the underlying base, but actually the Euler
        // eTokens are always fp18.  So we scale up the sharesCached and subtract from real eToken balance.
        retrieved = (sharesToken.balanceOf(address(this)) -
            (sharesCached * scaleFactor)).u128();
        sharesToken.safeTransfer(to, retrieved);
        // Now the current balances match the cache, so no need to update the TWAR
    }
}