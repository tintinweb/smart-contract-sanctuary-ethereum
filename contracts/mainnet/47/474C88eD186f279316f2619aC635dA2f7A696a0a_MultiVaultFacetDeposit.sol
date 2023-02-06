// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;


interface IWETH {

    function deposit() external payable;

    function withdraw(uint wad) external;

    function totalSupply() external view returns (uint);

    function approve(address guy, uint wad) external returns (bool);

    function transfer(address dst, uint wad) external returns (bool);

    function transferFrom(address src, address dst, uint wad) external returns (bool);

    function name() external view  returns (string memory);

    function balanceOf(address account) external view returns (uint256);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)
pragma solidity 0.8.0;


import "./interfaces/IERC20.sol";
import "./interfaces/IERC20Metadata.sol";
import "./interfaces/IMultiVaultToken.sol";

import "./libraries/Address.sol";

import "./utils/Ownable.sol";


contract MultiVaultToken is IMultiVaultToken, Context, IERC20, IERC20Metadata, Ownable {
    uint activation;

    constructor() Ownable(_msgSender()) {}

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name}, {symbol} and {decimals}.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function initialize(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) external override {
        require(activation == 0);

        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;

        activation = block.number;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function mint(
        address account,
        uint amount
    ) external override onlyOwner {
        _mint(account, amount);
    }

    function burn(
        address account,
        uint amount
    ) external override onlyOwner {
        _burn(account, amount);
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
    unchecked {
        _approve(owner, spender, currentAllowance - subtractedValue);
    }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
    unchecked {
        _balances[from] = fromBalance - amount;
    }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
    unchecked {
        _balances[account] = accountBalance - amount;
    }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
        unchecked {
            _approve(owner, spender, currentAllowance - amount);
        }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity 0.8.0;

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity 0.8.0;

import "./IERC20.sol";

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

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.0;


interface IEverscale {
    struct EverscaleAddress {
        int8 wid;
        uint256 addr;
    }

    struct EverscaleEvent {
        uint64 eventTransactionLt;
        uint32 eventTimestamp;
        bytes eventData;
        int8 configurationWid;
        uint256 configurationAddress;
        int8 eventContractWid;
        uint256 eventContractAddress;
        address proxy;
        uint32 round;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.0;


interface IMultiVaultToken {
    function initialize(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) external;

    function burn(address account, uint256 amount) external;
    function mint(address account, uint256 amount) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.0;


import "../IEverscale.sol";
import "./IMultiVaultFacetPendingWithdrawals.sol";


interface IMultiVaultFacetDeposit {
    struct DepositParams {
        IEverscale.EverscaleAddress recipient;
        address token;
        uint amount;
        uint expected_evers;
        bytes payload;
    }

    struct DepositNativeTokenParams {
        IEverscale.EverscaleAddress recipient;
        uint amount;
        uint expected_evers;
        bytes payload;
    }

    function depositByNativeToken(
        DepositNativeTokenParams memory d
    ) external payable;

    function depositByNativeToken(
        DepositNativeTokenParams memory d,
        uint256 expectedMinBounty,
        IMultiVaultFacetPendingWithdrawals.PendingWithdrawalId[] memory pendingWithdrawalIds
    ) external payable;

    function deposit(
        DepositParams memory d
    ) external payable;

    function deposit(
        DepositParams memory d,
        uint256 expectedMinBounty,
        IMultiVaultFacetPendingWithdrawals.PendingWithdrawalId[] memory pendingWithdrawalIds
    ) external payable;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.0;


import "./IMultiVaultFacetTokens.sol";

interface IMultiVaultFacetDepositEvents {
    event NativeTransfer(
        int8 native_wid,
        uint256 native_addr,
        uint128 amount,
        int8 recipient_wid,
        uint256 recipient_addr,
        uint value,
        uint expected_evers,
        bytes payload
    );

    event AlienTransfer(
        uint256 base_chainId,
        uint160 base_token,
        string name,
        string symbol,
        uint8 decimals,
        uint128 amount,
        int8 recipient_wid,
        uint256 recipient_addr,
        uint value,
        uint expected_evers,
        bytes payload
    );

    event Deposit(
        IMultiVaultFacetTokens.TokenType _type,
        address sender,
        address token,
        int8 recipient_wid,
        uint256 recipient_addr,
        uint256 amount,
        uint256 fee
    );
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.0;


interface IMultiVaultFacetFees {
    enum Fee { Deposit, Withdraw }

    function defaultNativeDepositFee() external view returns (uint);
    function defaultNativeWithdrawFee() external view returns (uint);
    function defaultAlienDepositFee() external view returns (uint);
    function defaultAlienWithdrawFee() external view returns (uint);

    function fees(address token) external view returns (uint);

    function skim(
        address token
    ) external payable;

    function setDefaultAlienWithdrawFee(uint fee) external;
    function setDefaultAlienDepositFee(uint fee) external;
    function setDefaultNativeWithdrawFee(uint fee) external;
    function setDefaultNativeDepositFee(uint fee) external;

    function setTokenWithdrawFee(
        address token,
        uint _withdrawFee
    ) external;
    function setTokenDepositFee(
        address token,
        uint _depositFee
    ) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.0;


interface IMultiVaultFacetFeesEvents {
    event UpdateDefaultNativeDepositFee(uint fee);
    event UpdateDefaultNativeWithdrawFee(uint fee);
    event UpdateDefaultAlienDepositFee(uint fee);
    event UpdateDefaultAlienWithdrawFee(uint fee);

    event UpdateTokenDepositFee(address token, uint256 fee);
    event UpdateTokenWithdrawFee(address token, uint256 fee);

    event EarnTokenFee(address token, uint amount);

    event SkimFee(
        address token,
        bool skim_to_everscale,
        uint256 amount
    );
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.0;


interface IMultiVaultFacetLiquidity {
    struct Liquidity {
        uint activation;
        uint supply;
        uint cash;
        uint interest;
    }

    function mint(
        address token,
        uint amount,
        address receiver
    ) external;

    function redeem(
        address token,
        uint amount,
        address receiver
    ) external;

    function exchangeRateCurrent(
        address token
    ) external view returns(uint);

    function getCash(
        address token
    ) external view returns(uint);

    function getLPToken(
        address token
    ) external view returns (address);

    function setTokenInterest(
        address token,
        uint interest
    ) external;

    function setDefaultInterest(
        uint interest
    ) external;

    function liquidity(
        address token
    ) external view returns (Liquidity memory);

    function convertLPToUnderlying(
        address token,
        uint amount
    ) external view returns (uint);

    function convertUnderlyingToLP(
        address token,
        uint amount
    ) external view returns (uint);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.0;


interface IMultiVaultFacetLiquidityEvents {
    event UpdateTokenLiquidityInterest(address token, uint interest);
    event UpdateDefaultLiquidityInterest(uint inetrest);

    event MintLiquidity(address sender, address token, uint amount, uint lp_amount);
    event RedeemLiquidity(address sender, address token, uint amount, uint underlying_amount);

    event EarnTokenCash(address token, uint amount);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.0;


import "../IEverscale.sol";
import "./IMultiVaultFacetWithdraw.sol";


interface IMultiVaultFacetPendingWithdrawals {
    enum ApproveStatus { NotRequired, Required, Approved, Rejected }

    struct WithdrawalLimits {
        uint undeclared;
        uint daily;
        bool enabled;
    }

    struct PendingWithdrawalParams {
        address token;
        uint256 amount;
        uint256 bounty;
        uint256 timestamp;
        ApproveStatus approveStatus;

        uint256 chainId;
        IMultiVaultFacetWithdraw.Callback callback;
    }

    struct PendingWithdrawalId {
        address recipient;
        uint256 id;
    }

    struct WithdrawalPeriodParams {
        uint256 total;
        uint256 considered;
    }

    function pendingWithdrawalsPerUser(address user) external view returns (uint);
    function pendingWithdrawalsTotal(address token) external view returns (uint);

    function pendingWithdrawals(
        address user,
        uint256 id
    ) external view returns (PendingWithdrawalParams memory);

    function setPendingWithdrawalBounty(
        uint256 id,
        uint256 bounty
    ) external;

    function cancelPendingWithdrawal(
        uint256 id,
        uint256 amount,
        IEverscale.EverscaleAddress memory recipient,
        uint expected_evers,
        bytes memory payload,
        uint bounty
    ) external payable;

    function setPendingWithdrawalApprove(
        PendingWithdrawalId memory pendingWithdrawalId,
        ApproveStatus approveStatus
    ) external;

    function setPendingWithdrawalApprove(
        PendingWithdrawalId[] memory pendingWithdrawalId,
        ApproveStatus[] memory approveStatus
    ) external;

    function forceWithdraw(
        PendingWithdrawalId[] memory pendingWithdrawalIds
    ) external;

    function withdrawalLimits(
        address token
    ) external view returns(WithdrawalLimits memory);

    function withdrawalPeriods(
        address token,
        uint256 withdrawalPeriodId
    ) external view returns (WithdrawalPeriodParams memory);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.0;


import "./IMultiVaultFacetPendingWithdrawals.sol";


interface IMultiVaultFacetPendingWithdrawalsEvents {
    event PendingWithdrawalCancel(
        address recipient,
        uint256 id,
        uint256 amount
    );

    event PendingWithdrawalUpdateBounty(
        address recipient,
        uint256 id,
        uint256 bounty
    );

    event PendingWithdrawalCreated(
        address recipient,
        uint256 id,
        address token,
        uint256 amount,
        bytes32 payloadId
    );

    event PendingWithdrawalWithdraw(
        address recipient,
        uint256 id,
        uint256 amount
    );

    event PendingWithdrawalFill(
        address recipient,
        uint256 id
    );

    event PendingWithdrawalForce(
        address recipient,
        uint256 id
    );

    event PendingWithdrawalUpdateApproveStatus(
        address recipient,
        uint256 id,
        IMultiVaultFacetPendingWithdrawals.ApproveStatus approveStatus
    );
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.0;


import "./../IEverscale.sol";


interface IMultiVaultFacetTokens {
    enum TokenType { Native, Alien }

    struct TokenPrefix {
        uint activation;
        string name;
        string symbol;
    }

    struct TokenMeta {
        string name;
        string symbol;
        uint8 decimals;
    }

    struct Token {
        uint activation;
        bool blacklisted;
        uint depositFee;
        uint withdrawFee;
        bool isNative;
        address custom;
    }

    function prefixes(address _token) external view returns (TokenPrefix memory);
    function tokens(address _token) external view returns (Token memory);
    function natives(address _token) external view returns (IEverscale.EverscaleAddress memory);

    function setPrefix(
        address token,
        string memory name_prefix,
        string memory symbol_prefix
    ) external;

    function setTokenBlacklist(
        address token,
        bool blacklisted
    ) external;

    function getNativeToken(
        IEverscale.EverscaleAddress memory native
    ) external view returns (address);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.0;


interface IMultiVaultFacetTokensEvents {
    event BlacklistTokenAdded(address token);
    event BlacklistTokenRemoved(address token);

    event TokenActivated(
        address token,
        uint activation,
        bool isNative,
        uint depositFee,
        uint withdrawFee
    );

    event TokenCreated(
        address token,
        int8 native_wid,
        uint256 native_addr,
        string name_prefix,
        string symbol_prefix,
        string name,
        string symbol,
        uint8 decimals
    );
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.0;


import "./IMultiVaultFacetTokens.sol";
import "../IEverscale.sol";


interface IMultiVaultFacetWithdraw {
    struct Callback {
        address recipient;
        bytes payload;
        bool strict;
    }

    struct NativeWithdrawalParams {
        IEverscale.EverscaleAddress native;
        IMultiVaultFacetTokens.TokenMeta meta;
        uint256 amount;
        address recipient;
        uint256 chainId;
        Callback callback;
    }

    struct AlienWithdrawalParams {
        address token;
        uint256 amount;
        address recipient;
        uint256 chainId;
        Callback callback;
    }

    function withdrawalIds(bytes32) external view returns (bool);

    function saveWithdrawNative(
        bytes memory payload,
        bytes[] memory signatures
    ) external;

    function saveWithdrawAlien(
        bytes memory payload,
        bytes[] memory signatures
    ) external;

    function saveWithdrawAlien(
        bytes memory payload,
        bytes[] memory signatures,
        uint bounty
    ) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.0;

import "./IMultiVaultFacetWithdraw.sol";


interface IOctusCallback {
    function onNativeWithdrawal(
        IMultiVaultFacetWithdraw.NativeWithdrawalParams memory payload
    ) external;
    function onAlienWithdrawal(
        IMultiVaultFacetWithdraw.AlienWithdrawalParams memory payload,
        uint256 withdrawAmount
    ) external;
    function onAlienWithdrawalPendingCreated(
        IMultiVaultFacetWithdraw.AlienWithdrawalParams memory _payload,
        uint pendingWithdrawalId
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity 0.8.0;

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity 0.8.0;

import "./../interfaces/IERC20.sol";
import "./../libraries/Address.sol";

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

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.0;


import "../../interfaces/multivault/IMultiVaultFacetDeposit.sol";
import "../../interfaces/multivault/IMultiVaultFacetFees.sol";
import "../../interfaces/multivault/IMultiVaultFacetTokens.sol";
import "../../interfaces/multivault/IMultiVaultFacetPendingWithdrawals.sol";
import "../../interfaces/multivault/IMultiVaultFacetPendingWithdrawalsEvents.sol";
import "../../interfaces/multivault/IMultiVaultFacetWithdraw.sol";
import "../../interfaces/IMultiVaultToken.sol";
import "../../interfaces/IEverscale.sol";
import "../../interfaces/IERC20.sol";
import "../../../interfaces/IWETH.sol";

import "../../libraries/SafeERC20.sol";

import "../storage/MultiVaultStorage.sol";

import "../helpers/MultiVaultHelperEverscale.sol";
import "../helpers/MultiVaultHelperReentrancyGuard.sol";
import "../helpers/MultiVaultHelperTokens.sol";
import "../helpers/MultiVaultHelperFee.sol";
import "../helpers/MultiVaultHelperPendingWithdrawal.sol";
import "../helpers/MultiVaultHelperCallback.sol";


contract MultiVaultFacetDeposit is
    MultiVaultHelperFee,
    MultiVaultHelperEverscale,
    MultiVaultHelperReentrancyGuard,
    MultiVaultHelperTokens,
    MultiVaultHelperPendingWithdrawal,
    IMultiVaultFacetDeposit,
    MultiVaultHelperCallback
{
    using SafeERC20 for IERC20;

    function depositByNativeToken(
        DepositNativeTokenParams memory d
    )
        external
        payable
        override
        nonReentrant
        wethNotBlacklisted
        initializeWethToken
        onlyEmergencyDisabled
    {
        require(msg.value >= d.amount, "Msg value to low");
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        IWETH(s.weth).deposit{value: d.amount}();
        _deposit(
            DepositParams({
            recipient: d.recipient,
            token: s.weth,
            amount: d.amount,
            expected_evers: d.expected_evers,
            payload: d.payload
            }),
            msg.value - d.amount,
            address(this)
        );
    }

    function deposit(
        DepositParams memory d
    )
        external
        payable
        override
        nonReentrant
        tokenNotBlacklisted(d.token)
        initializeToken(d.token)
        onlyEmergencyDisabled
    {
        _deposit(d, msg.value, msg.sender);
    }
    /// @notice Transfer tokens to the Everscale. Works both for native and alien tokens.
    /// Approve is required only for alien tokens deposit.
    /// @param d Deposit parameters
    function _deposit(
        DepositParams memory d,
        uint256 _value,
        address tokens_owner
    ) internal {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        uint fee = _calculateMovementFee(
            d.amount,
            d.token,
            IMultiVaultFacetFees.Fee.Deposit
        );

        bool isNative = s.tokens_[d.token].isNative;

        // Replace token address with custom token, if specified
        address token = s.tokens_[d.token].custom == address(0) ? d.token : s.tokens_[d.token].custom;

        if (isNative) {
            IMultiVaultToken(token).burn(
                msg.sender,
                d.amount
            );

            d.amount -= fee;

            _transferToEverscaleNative(d, fee, msg.value);
        } else {
            IERC20(token).safeTransferFrom(
                tokens_owner,
                address(this),
                d.amount
            );

            d.amount -= fee;

            _transferToEverscaleAlien(d, fee, _value);
        }

        _increaseTokenFee(d.token, fee);
        _drainGas();
    }

    function depositByNativeToken(
        DepositNativeTokenParams memory d,
        uint256 expectedMinBounty,
        IMultiVaultFacetPendingWithdrawals.PendingWithdrawalId[] memory pendingWithdrawalIds
    ) external payable override wethNotBlacklisted nonReentrant {
        require(msg.value >= d.amount, "Msg value to low");
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        IWETH(s.weth).deposit{value: d.amount}();
        _deposit(
            DepositParams({
                recipient:d.recipient,
                token: s.weth,
                amount: d.amount,
                expected_evers: d.expected_evers,
                payload: d.payload
            }),
            expectedMinBounty,
            pendingWithdrawalIds,
            msg.value - d.amount
        );
    }
    function deposit(
        DepositParams memory d,
        uint256 expectedMinBounty,
        IMultiVaultFacetPendingWithdrawals.PendingWithdrawalId[] memory pendingWithdrawalIds
    ) external payable override tokenNotBlacklisted(d.token) nonReentrant {
        IERC20(d.token).safeTransferFrom(msg.sender, address(this), d.amount);
        _deposit(d, expectedMinBounty, pendingWithdrawalIds, msg.value);
    }
    function _deposit(
        DepositParams memory d,
        uint256 expectedMinBounty,
        IMultiVaultFacetPendingWithdrawals.PendingWithdrawalId[] memory pendingWithdrawalIds,
        uint256 _value
    ) internal {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        uint amountLeft = d.amount;
        uint amountPlusBounty = d.amount;


        for (uint i = 0; i < pendingWithdrawalIds.length; i++) {
            IMultiVaultFacetPendingWithdrawals.PendingWithdrawalId memory pendingWithdrawalId = pendingWithdrawalIds[i];
            IMultiVaultFacetPendingWithdrawals.PendingWithdrawalParams memory pendingWithdrawal = _pendingWithdrawal(pendingWithdrawalId);

            require(pendingWithdrawal.amount > 0);
            require(pendingWithdrawal.token == d.token);

            amountLeft -= pendingWithdrawal.amount;
            amountPlusBounty += pendingWithdrawal.bounty;

            s.pendingWithdrawals_[pendingWithdrawalId.recipient][pendingWithdrawalId.id].amount = 0;

            emit PendingWithdrawalFill(
                pendingWithdrawalId.recipient,
                pendingWithdrawalId.id
            );

            IERC20(pendingWithdrawal.token).safeTransfer(
                pendingWithdrawalId.recipient,
                pendingWithdrawal.amount - pendingWithdrawal.bounty
            );

            _callbackAlienWithdrawal(
                IMultiVaultFacetWithdraw.AlienWithdrawalParams({
                    token: pendingWithdrawal.token,
                    amount: pendingWithdrawal.amount,
                    recipient: pendingWithdrawalId.recipient,
                    chainId: pendingWithdrawal.chainId,
                    callback: pendingWithdrawal.callback
                }),
                pendingWithdrawal.amount
            );

        }

        require(amountPlusBounty - d.amount >= expectedMinBounty);

        uint fee = _calculateMovementFee(d.amount, d.token, IMultiVaultFacetFees.Fee.Deposit);

        d.amount = amountPlusBounty - fee;

        _transferToEverscaleAlien(
            d,
            fee,
            _value
        );

        _increaseTokenFee(d.token, fee);

        _drainGas();
    }

    function _drainGas() internal {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        address payable gasDonor = payable(s.gasDonor);

        if (gasDonor != address(0)) {
            gasDonor.transfer(address(this).balance);
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.0;


import "../../interfaces/multivault/IMultiVaultFacetWithdraw.sol";
import "../../interfaces/multivault/IOctusCallback.sol";

abstract contract MultiVaultHelperCallback {
    modifier checkCallbackRecipient(address recipient) {
        require(recipient != address(this));

        if (recipient != address(0)) {
            _;
        }
    }

    function _callbackNativeWithdrawal(
        IMultiVaultFacetWithdraw.NativeWithdrawalParams memory withdrawal
    ) internal checkCallbackRecipient(withdrawal.callback.recipient) {
        bytes memory data = abi.encodeWithSelector(
            IOctusCallback.onNativeWithdrawal.selector,
            withdrawal
        );

        _execute(
            withdrawal.callback.recipient,
            data,
            withdrawal.callback.strict
        );
    }

    function _callbackAlienWithdrawal(
        IMultiVaultFacetWithdraw.AlienWithdrawalParams memory _withdrawal,
        uint256 _withdrawAmount
    ) internal checkCallbackRecipient(_withdrawal.callback.recipient) {
        bytes memory data = abi.encodeWithSelector(
            IOctusCallback.onAlienWithdrawal.selector,
            _withdrawal,
            _withdrawAmount
        );

        _execute(
            _withdrawal.callback.recipient,
            data,
            _withdrawal.callback.strict
        );
    }

    function _callbackAlienWithdrawalPendingCreated(
        IMultiVaultFacetWithdraw.AlienWithdrawalParams memory _withdrawal,
        uint _pendingWithdrawalId
    ) checkCallbackRecipient(_withdrawal.callback.recipient) internal {
        bytes memory data = abi.encodeWithSelector(
            IOctusCallback.onAlienWithdrawalPendingCreated.selector,
            _withdrawal,
            _pendingWithdrawalId
        );

        _execute(
            _withdrawal.callback.recipient,
            data,
            _withdrawal.callback.strict
        );
    }

    function _execute(
        address recipient,
        bytes memory data,
        bool strict
    ) internal {
        (bool success, ) = recipient.call(data);

        if (strict) require(success);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.0;

import "../storage/MultiVaultStorage.sol";


abstract contract MultiVaultHelperEmergency {
    modifier onlyEmergencyDisabled() {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        require(!s.emergencyShutdown);

        _;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.0;


import "../../interfaces/IEverscale.sol";
import "../../interfaces/IERC20Metadata.sol";
import "../../interfaces/multivault/IMultiVaultFacetDepositEvents.sol";
import "../../interfaces/multivault/IMultiVaultFacetDeposit.sol";

import "../storage/MultiVaultStorage.sol";


abstract contract MultiVaultHelperEverscale is IMultiVaultFacetDepositEvents {
    function _transferToEverscaleNative(
        IMultiVaultFacetDeposit.DepositParams memory deposit,
        uint fee,
        uint value
    ) internal {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        IEverscale.EverscaleAddress memory native = s.natives_[deposit.token];

        emit NativeTransfer(
            native.wid,
            native.addr,

            uint128(deposit.amount),
            deposit.recipient.wid,
            deposit.recipient.addr,
            value,
            deposit.expected_evers,
            deposit.payload
        );

        _emitDeposit(deposit, fee, true);
    }

    function _transferToEverscaleAlien(
        IMultiVaultFacetDeposit.DepositParams memory deposit,
        uint fee,
        uint value
    ) internal {
        emit AlienTransfer(
            block.chainid,
            uint160(deposit.token),
            IERC20Metadata(deposit.token).name(),
            IERC20Metadata(deposit.token).symbol(),
            IERC20Metadata(deposit.token).decimals(),

            uint128(deposit.amount),
            deposit.recipient.wid,
            deposit.recipient.addr,
            value,
            deposit.expected_evers,
            deposit.payload
        );

        _emitDeposit(deposit, fee, false);
    }

    function _emitDeposit(
        IMultiVaultFacetDeposit.DepositParams memory deposit,
        uint fee,
        bool isNative
    ) internal {
        emit Deposit(
            isNative ? IMultiVaultFacetTokens.TokenType.Native : IMultiVaultFacetTokens.TokenType.Alien,
            msg.sender,
            deposit.token,
            deposit.recipient.wid,
            deposit.recipient.addr,
            deposit.amount + fee,
            fee
        );
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.0;


import "../../interfaces/multivault/IMultiVaultFacetFees.sol";
import "../../interfaces/multivault/IMultiVaultFacetTokens.sol";
import "../../interfaces/multivault/IMultiVaultFacetLiquidity.sol";
import "../../interfaces/multivault/IMultiVaultFacetFeesEvents.sol";

import "../storage/MultiVaultStorage.sol";
import "./MultiVaultHelperLiquidity.sol";


abstract contract MultiVaultHelperFee is MultiVaultHelperLiquidity, IMultiVaultFacetFeesEvents {
    modifier respectFeeLimit(uint fee) {
        require(fee <= MultiVaultStorage.FEE_LIMIT);

        _;
    }

    /// @notice Calculates fee for deposit or withdrawal.
    /// @param amount Amount of tokens.
    /// @param _token Token address.
    /// @param fee Fee type (Deposit = 0, Withdraw = 1).
    function _calculateMovementFee(
        uint256 amount,
        address _token,
        IMultiVaultFacetFees.Fee fee
    ) internal view returns (uint256) {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        IMultiVaultFacetTokens.Token memory token = s.tokens_[_token];

        uint tokenFee = fee == IMultiVaultFacetFees.Fee.Deposit ? token.depositFee : token.withdrawFee;

        return tokenFee * amount / MultiVaultStorage.MAX_BPS;
    }

    function _increaseTokenFee(
        address token,
        uint _amount
    ) internal {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        if (_amount == 0) return;

        IMultiVaultFacetLiquidity.Liquidity memory liquidity = s.liquidity[token];

        uint amount;

        if (s.liquidity[token].activation == 0) {
            amount = _amount;
        } else {
            uint liquidity_fee = _amount * liquidity.interest / MultiVaultStorage.MAX_BPS;

            amount = _amount - liquidity_fee;

            _increaseTokenCash(token, liquidity_fee);
        }

        if (amount == 0) return;

        s.fees[token] += amount;
        emit EarnTokenFee(token, amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.0;


import "../../interfaces/multivault/IMultiVaultFacetLiquidityEvents.sol";
import "../../interfaces/multivault/IMultiVaultFacetLiquidity.sol";
import "../../interfaces/IMultiVaultToken.sol";
import "../storage/MultiVaultStorage.sol";

import "../../MultiVaultToken.sol";


abstract contract MultiVaultHelperLiquidity is IMultiVaultFacetLiquidityEvents {
    modifier onlyActivatedLP(address token) {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        require(s.liquidity[token].activation != 0);

        _;
    }

    function _getLPToken(
        address token
    ) internal view returns (address lp) {
        lp = address(uint160(uint(keccak256(abi.encodePacked(
            hex'ff',
            address(this),
            keccak256(abi.encodePacked(token)), // TODO: prevent collision
            hex'192c19818bebb5c6c95f5dcb3c3257379fc46fb654780cb06f3211ee77e1a360' // MultiVaultToken init code hash
        )))));
    }

    function _exchangeRateCurrent(
        address token
    ) internal view returns(uint) {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        IMultiVaultFacetLiquidity.Liquidity memory liquidity = s.liquidity[token];

        if (liquidity.supply == 0 || liquidity.activation == 0) return MultiVaultStorage.LP_EXCHANGE_RATE_BPS;

        return MultiVaultStorage.LP_EXCHANGE_RATE_BPS * liquidity.cash / liquidity.supply; // TODO: precision
    }

    function _getCash(
        address token
    ) internal view returns(uint) {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        IMultiVaultFacetLiquidity.Liquidity memory liquidity = s.liquidity[token];

        return liquidity.cash;
    }

    function _convertLPToUnderlying(
        address token,
        uint amount
    ) internal view returns (uint) {
        return _exchangeRateCurrent(token) * amount / MultiVaultStorage.LP_EXCHANGE_RATE_BPS;
    }

    function _convertUnderlyingToLP(
        address token,
        uint amount
    ) internal view returns (uint) {
        return MultiVaultStorage.LP_EXCHANGE_RATE_BPS / _exchangeRateCurrent(token) * amount;
    }

    function _deployLPToken(
        address token
    ) internal returns (address lp) {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        require(s.liquidity[token].activation == 0);

        s.liquidity[token].activation = block.number;
        s.liquidity[token].interest = s.defaultInterest;

        bytes memory bytecode = type(MultiVaultToken).creationCode;

        bytes32 salt = keccak256(abi.encodePacked(token));

        assembly {
            lp := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        string memory name = IERC20Metadata(token).name();
        string memory symbol = IERC20Metadata(token).symbol();
        uint8 decimals = IERC20Metadata(token).decimals(); // TODO: think again?

        IMultiVaultToken(lp).initialize(
            string(abi.encodePacked(MultiVaultStorage.DEFAULT_NAME_LP_PREFIX, name)),
            string(abi.encodePacked(MultiVaultStorage.DEFAULT_SYMBOL_LP_PREFIX, symbol)),
            decimals
        );
    }

    function _increaseTokenCash(
        address token,
        uint amount
    ) internal {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        if (amount == 0) return;

        s.liquidity[token].cash += amount;

        emit EarnTokenCash(token, amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.0;


import "../../interfaces/multivault/IMultiVaultFacetPendingWithdrawals.sol";
import "../../interfaces/multivault/IMultiVaultFacetPendingWithdrawalsEvents.sol";

import "../storage/MultiVaultStorage.sol";


abstract contract MultiVaultHelperPendingWithdrawal is IMultiVaultFacetPendingWithdrawalsEvents {
    modifier pendingWithdrawalOpened(
        IMultiVaultFacetPendingWithdrawals.PendingWithdrawalId memory pendingWithdrawalId
    ) {
        IMultiVaultFacetPendingWithdrawals.PendingWithdrawalParams memory pendingWithdrawal = _pendingWithdrawal(pendingWithdrawalId);

        require(pendingWithdrawal.amount > 0);

        _;
    }

    function _pendingWithdrawal(
        IMultiVaultFacetPendingWithdrawals.PendingWithdrawalId memory pendingWithdrawalId
    ) internal view returns (IMultiVaultFacetPendingWithdrawals.PendingWithdrawalParams memory) {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        return s.pendingWithdrawals_[pendingWithdrawalId.recipient][pendingWithdrawalId.id];
    }

    function _pendingWithdrawal(
        address recipient,
        uint256 id
    ) internal view returns (IMultiVaultFacetPendingWithdrawals.PendingWithdrawalParams memory) {
        return _pendingWithdrawal(IMultiVaultFacetPendingWithdrawals.PendingWithdrawalId(recipient, id));
    }

    function _pendingWithdrawalApproveStatusUpdate(
        IMultiVaultFacetPendingWithdrawals.PendingWithdrawalId memory pendingWithdrawalId,
        IMultiVaultFacetPendingWithdrawals.ApproveStatus approveStatus
    ) internal {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        s.pendingWithdrawals_[pendingWithdrawalId.recipient][pendingWithdrawalId.id].approveStatus = approveStatus;

        emit PendingWithdrawalUpdateApproveStatus(
            pendingWithdrawalId.recipient,
            pendingWithdrawalId.id,
            approveStatus
        );
    }

    function _pendingWithdrawalAmountReduce(
        address token,
        IMultiVaultFacetPendingWithdrawals.PendingWithdrawalId memory pendingWithdrawalId,
        uint amount
    ) internal {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        s.pendingWithdrawals_[pendingWithdrawalId.recipient][pendingWithdrawalId.id].amount -= amount;
        s.pendingWithdrawalsTotal[token] -= amount;
    }

    function _withdrawalPeriod(
        address token,
        uint256 timestamp
    ) internal view returns (IMultiVaultFacetPendingWithdrawals.WithdrawalPeriodParams memory) {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        return s.withdrawalPeriods_[token][_withdrawalPeriodDeriveId(timestamp)];
    }

    function _withdrawalPeriodDeriveId(
        uint256 timestamp
    ) internal pure returns (uint256) {
        return timestamp / MultiVaultStorage.WITHDRAW_PERIOD_DURATION_IN_SECONDS;
    }

    function _withdrawalPeriodIncreaseTotalByTimestamp(
        address token,
        uint256 timestamp,
        uint256 amount
    ) internal {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        uint withdrawalPeriodId = _withdrawalPeriodDeriveId(timestamp);

        s.withdrawalPeriods_[token][withdrawalPeriodId].total += amount;
    }

    function _withdrawalPeriodCheckLimitsPassed(
        address token,
        uint amount,
        IMultiVaultFacetPendingWithdrawals.WithdrawalPeriodParams memory withdrawalPeriod
    ) internal view returns (bool) {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        IMultiVaultFacetPendingWithdrawals.WithdrawalLimits memory withdrawalLimit = s.withdrawalLimits_[token];

        if (!withdrawalLimit.enabled) return true;

        return (amount < withdrawalLimit.undeclared) &&
        (amount + withdrawalPeriod.total - withdrawalPeriod.considered < withdrawalLimit.daily);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.0;


import "./../storage/MultiVaultStorageReentrancyGuard.sol";


abstract contract MultiVaultHelperReentrancyGuard {
    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        MultiVaultStorageReentrancyGuard.ReentrancyGuardStorage storage s = MultiVaultStorageReentrancyGuard._storage();

        // On the first call to nonReentrant, _notEntered will be true
        require(s._status != MultiVaultStorageReentrancyGuard._ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        s._status = MultiVaultStorageReentrancyGuard._ENTERED;
    }

    function _nonReentrantAfter() private {
        MultiVaultStorageReentrancyGuard.ReentrancyGuardStorage storage s = MultiVaultStorageReentrancyGuard._storage();

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        s._status = MultiVaultStorageReentrancyGuard._NOT_ENTERED;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.0;


import "../../interfaces/multivault/IMultiVaultFacetTokens.sol";
import "../../interfaces/multivault/IMultiVaultFacetWithdraw.sol";
import "../../interfaces/multivault/IMultiVaultFacetTokensEvents.sol";
import "../../interfaces/IEverscale.sol";

import "../../MultiVaultToken.sol";
import "../storage/MultiVaultStorage.sol";
import "./MultiVaultHelperEmergency.sol";


abstract contract MultiVaultHelperTokens is
    MultiVaultHelperEmergency,
    IMultiVaultFacetTokensEvents
{
    modifier initializeToken(address _token) {
        _initializeToken(_token);
        _;
    }
    modifier initializeWethToken() {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        _initializeToken(s.weth);
        _;
    }

    function _initializeToken(address _token) internal {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();
        if (s.tokens_[_token].activation == 0) {
            // Non-activated tokens are always aliens, native tokens are activate on the first `saveWithdrawNative`

            require(
                IERC20Metadata(_token).decimals() <= MultiVaultStorage.DECIMALS_LIMIT &&
                bytes(IERC20Metadata(_token).symbol()).length <= MultiVaultStorage.SYMBOL_LENGTH_LIMIT &&
                bytes(IERC20Metadata(_token).name()).length <= MultiVaultStorage.NAME_LENGTH_LIMIT
            );

            _activateToken(_token, false);
        }
    }

    modifier tokenNotBlacklisted(address _token) {
        bool isBlackListed = isTokenNoBlackListed(_token);
        require(!isBlackListed);

        _;
    }
    modifier wethNotBlacklisted() {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();
        bool isBlackListed = isTokenNoBlackListed(s.weth);
        require(!isBlackListed);

        _;
    }
    function isTokenNoBlackListed(address _token) internal view returns (bool) {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();
        return s.tokens_[_token].blacklisted;
    }

    function _activateToken(
        address token,
        bool isNative
    ) internal {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        uint depositFee = isNative ? s.defaultNativeDepositFee : s.defaultAlienDepositFee;
        uint withdrawFee = isNative ? s.defaultNativeWithdrawFee : s.defaultAlienWithdrawFee;

        s.tokens_[token] = IMultiVaultFacetTokens.Token({
            activation: block.number,
            blacklisted: false,
            isNative: isNative,
            depositFee: depositFee,
            withdrawFee: withdrawFee,
            custom: address(0)
        });

        emit TokenActivated(
            token,
            block.number,
            isNative,
            depositFee,
            withdrawFee
        );
    }

    function _getNativeWithdrawalToken(
        IMultiVaultFacetWithdraw.NativeWithdrawalParams memory withdrawal
    ) internal returns (address) {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        // Derive native token address from the Everscale (token wid, token addr)
        address token = _getNativeToken(withdrawal.native);

        // Token is being withdrawn first time - activate it (set default parameters)
        // And deploy ERC20 representation
        if (s.tokens_[token].activation == 0) {
            _deployTokenForNative(withdrawal.native, withdrawal.meta);
            _activateToken(token, true);

            s.natives_[token] = withdrawal.native;
        }

        // Check if there is a custom ERC20 representing this withdrawal.native
        address custom = s.tokens_[token].custom;

        if (custom != address(0)) return custom;

        return token;
    }

    function _increaseCash(
        address token,
        uint amount
    ) internal {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        s.liquidity[token].cash += amount;
    }

    /// @notice Gets the address
    /// @param native Everscale token address
    /// @return token Token address
    function _getNativeToken(
        IEverscale.EverscaleAddress memory native
    ) internal view returns (address token) {
        token = address(uint160(uint(keccak256(abi.encodePacked(
            hex'ff',
            address(this),
            keccak256(abi.encodePacked(native.wid, native.addr)),
            hex'192c19818bebb5c6c95f5dcb3c3257379fc46fb654780cb06f3211ee77e1a360' // MultiVaultToken init code hash
        )))));
    }

    function _deployTokenForNative(
        IEverscale.EverscaleAddress memory native,
        IMultiVaultFacetTokens.TokenMeta memory meta
    ) internal returns (address token) {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        bytes memory bytecode = type(MultiVaultToken).creationCode;

        bytes32 salt = keccak256(abi.encodePacked(native.wid, native.addr));

        assembly {
            token := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        // Check custom prefix available
        IMultiVaultFacetTokens.TokenPrefix memory prefix = s.prefixes_[token];

        string memory name_prefix = prefix.activation == 0 ? MultiVaultStorage.DEFAULT_NAME_PREFIX : prefix.name;
        string memory symbol_prefix = prefix.activation == 0 ? MultiVaultStorage.DEFAULT_SYMBOL_PREFIX : prefix.symbol;

        IMultiVaultToken(token).initialize(
            string(abi.encodePacked(name_prefix, meta.name)),
            string(abi.encodePacked(symbol_prefix, meta.symbol)),
            meta.decimals
        );

        emit TokenCreated(
            token,
            native.wid,
            native.addr,
            name_prefix,
            symbol_prefix,
            meta.name,
            meta.symbol,
            meta.decimals
        );
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.0;


import "../../interfaces/IEverscale.sol";
import "../../interfaces/multivault/IMultiVaultFacetTokens.sol";
import "../../interfaces/multivault/IMultiVaultFacetPendingWithdrawals.sol";
import "../../interfaces/multivault/IMultiVaultFacetLiquidity.sol";


library MultiVaultStorage {
    uint constant MAX_BPS = 10_000;
    uint constant FEE_LIMIT = MAX_BPS / 2;

    uint8 constant DECIMALS_LIMIT = 18;
    uint256 constant SYMBOL_LENGTH_LIMIT = 32;
    uint256 constant NAME_LENGTH_LIMIT = 32;

    string constant DEFAULT_NAME_PREFIX = '';
    string constant DEFAULT_SYMBOL_PREFIX = '';

    string constant DEFAULT_NAME_LP_PREFIX = 'Octus LP ';
    string constant DEFAULT_SYMBOL_LP_PREFIX = 'octLP';

    uint256 constant WITHDRAW_PERIOD_DURATION_IN_SECONDS = 60 * 60 * 24; // 24 hours

    // Previous version of the Vault contract was built with Upgradable Proxy Pattern, without using Diamond storage
    bytes32 constant MULTIVAULT_LEGACY_STORAGE_POSITION = 0x0000000000000000000000000000000000000000000000000000000000000002;

    uint constant LP_EXCHANGE_RATE_BPS = 10_000_000_000;

    struct Storage {
        mapping (address => IMultiVaultFacetTokens.Token) tokens_;
        mapping (address => IEverscale.EverscaleAddress) natives_;

        uint defaultNativeDepositFee;
        uint defaultNativeWithdrawFee;
        uint defaultAlienDepositFee;
        uint defaultAlienWithdrawFee;

        bool emergencyShutdown;

        address bridge;
        mapping(bytes32 => bool) withdrawalIds;
        IEverscale.EverscaleAddress rewards_;
        IEverscale.EverscaleAddress configurationNative_;
        IEverscale.EverscaleAddress configurationAlien_;

        address governance;
        address pendingGovernance;
        address guardian;
        address management;

        mapping (address => IMultiVaultFacetTokens.TokenPrefix) prefixes_;
        mapping (address => uint) fees;

        // STORAGE UPDATE 1
        // Pending withdrawals
        // - Counter pending withdrawals per user
        mapping(address => uint) pendingWithdrawalsPerUser;
        // - Pending withdrawal details
        mapping(address => mapping(uint256 => IMultiVaultFacetPendingWithdrawals.PendingWithdrawalParams)) pendingWithdrawals_;

        // - Total amount of pending withdrawals per token
        mapping(address => uint) pendingWithdrawalsTotal;

        // STORAGE UPDATE 2
        // Withdrawal limits per token
        mapping(address => IMultiVaultFacetPendingWithdrawals.WithdrawalLimits) withdrawalLimits_;

        // - Withdrawal periods. Each period is `WITHDRAW_PERIOD_DURATION_IN_SECONDS` seconds long.
        // If some period has reached the `withdrawalLimitPerPeriod` - all the future
        // withdrawals in this period require manual approve, see note on `setPendingWithdrawalsApprove`
        mapping(address => mapping(uint256 => IMultiVaultFacetPendingWithdrawals.WithdrawalPeriodParams)) withdrawalPeriods_;

        address withdrawGuardian;

        // STORAGE UPDATE 3
        mapping (address => IMultiVaultFacetLiquidity.Liquidity) liquidity;
        uint defaultInterest;

        // STORAGE UPDATE 4
        // - Receives native value, attached to the deposit
        address gasDonor;
        address weth;
    }

    function _storage() internal pure returns (Storage storage s) {
        assembly {
            s.slot := MULTIVAULT_LEGACY_STORAGE_POSITION
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.0;


//import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


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
library MultiVaultStorageReentrancyGuard {
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
    uint256 constant _NOT_ENTERED = 1;
    uint256 constant _ENTERED = 2;

    bytes32 constant REENTRANCY_GUARD_LEGACY_STORAGE_POSITION = 0x0000000000000000000000000000000000000000000000000000000000000001;

    struct ReentrancyGuardStorage {
        uint256 _status;
    }

    function _storage() internal pure returns (ReentrancyGuardStorage storage s) {
        assembly {
            s.slot := REENTRANCY_GUARD_LEGACY_STORAGE_POSITION
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity 0.8.0;

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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity 0.8.0;

import "./Context.sol";

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
    constructor (address initialOwner) {
        _transferOwnership(initialOwner);
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