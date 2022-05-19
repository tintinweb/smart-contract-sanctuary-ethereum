//SPDX-License-Identifier: LGPLv3
pragma solidity ^0.8.9;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {XDToken} from "./XDToken.sol";
import {IERC20} from "./IERC20.sol";
import {IDEXRouter} from "./IDEXRouter.sol";
import {IDEXInteractor} from "../exchanges/IDEXInteractor.sol";
import {DecimalLib} from "../lib/DecimalLib.sol";
import {FixedPointMathLib} from "../lib/FixedPointMath.sol";
import {LongPositionParams, ShortPositionParams} from "./PositionParams.sol";

/// @title Controller
/// @notice Entry point to the program. Controls minting of XDToken and the redemption of
/// collateral token through burning XDTkoken
contract Controller is Ownable, ReentrancyGuard {
    using DecimalLib for uint256;
    using FixedPointMathLib for uint256;

    /// @notice Returns stats about make up of
    /// @dev Explain to a developer any extra details
    /// @param token the return variables of a contract’s function state variable
    /// @param redeemable the amount of collateral redeemable.
    /// @param minted the amount of XDT minted with `token` as collateral in XDT.
    struct CollateralInfo {
        address token;
        uint256 redeemable;
        uint256 minted;
    }

    /// Events
    event RouterUpdated(address indexed by, address indexed newRouter);
    event WhitelistUpdated(address indexed by, address indexed token, bool isWhitelisted, bool isBaseToken);
    event Minted(address indexed account, uint256 base, uint256 quote, uint256 minted);
    event Redeemed(address indexed account, uint256 base, uint256 quote, uint256 burned);

    /// @notice The token to be minted and burned
    XDToken public token;

    /// @notice Router to various perpetual futures dexes.
    /// @dev Explain to a developer any extra details
    IDEXRouter public router;

    /// @notice Mapping for tokens that are whitelisted to be used as collateral.
    /// @dev Mapping token address => is whitelisted
    mapping(address => bool) public collateralTokens;

    address[] public collateralList;

    /// @notice mapping keeping track of if the collateral is the base token in a market.
    /// @dev Mapping token address => is base token
    mapping(address => bool) private _isBaseToken;

    /// @notice Amount deposited per collateral token.
    /// @dev mapping token address => amount deposited
    mapping(address => uint256) public collateralDeposited;

    /// @notice Amount minted per collateral token.
    /// @dev mapping token address => amount minted - amount burned.
    mapping(address => uint256) public mintedPerCollateral;

    /// @notice Amount of collateral that should be redeemable.
    /// @dev mapping token address => amount deposited
    mapping(address => uint256) public redeemable;

    constructor(address _token) {
        token = XDToken(_token);
    }

    function updateRouter(address newRouter) public onlyOwner {
        router = IDEXRouter(newRouter);
        emit RouterUpdated(msg.sender, newRouter);
    }

    /// @notice Updates the list of tokens that can be used as collateral.
    /// @param tokenAddress the token address
    /// @param isWhitelisted true if token is being added to the whitelist, false otherwise.
    function whitelistCollateral(
        address tokenAddress,
        bool isWhitelisted,
        bool isBaseToken
    ) external onlyOwner {
        collateralTokens[tokenAddress] = isWhitelisted;
        _isBaseToken[tokenAddress] = isBaseToken;
        if (isWhitelisted) {
            _addCollateral(tokenAddress);
        } else {
            _removeCollateral(tokenAddress);
        }
        emit WhitelistUpdated(msg.sender, tokenAddress, isWhitelisted, isBaseToken);
    }

    /// @notice Internal function to add collateral to collateralList
    /// @dev Used for traversing through collateral list
    function _addCollateral(address tokenAddress) private {
        for (uint256 i = 0; i < collateralList.length; i++) {
            if (tokenAddress == collateralList[i]) {
                return;
            }
        }
        collateralList.push(tokenAddress);
    }

    /// @notice Internal function to remove collateral to collateralList
    function _removeCollateral(address tokenAddress) private {
        uint256 foundIndex = type(uint256).max;
        for (uint256 i = 0; i < collateralList.length; i++) {
            if (tokenAddress == collateralList[i]) {
                foundIndex = i;
                break;
            }
        }
        if (foundIndex != type(uint256).max) {
            collateralList[foundIndex] = collateralList[collateralList.length];
            collateralList.pop();
        }
    }

    /// @notice Mints token in base
    /// @param market the market to open the futures position in.
    /// @param collateralToken the token being used as collateral
    /// @param amount The amount of `collateralToken` used to mint.
    function mint(
        address market,
        address collateralToken,
        uint256 amount
    ) external {
        // 1. check that token is approved
        // 2. get clearing house from router
        // 3. transfer tokens from msg.sender to clearing house
        // 4. execute perp tx
        // 6. mint
        require(collateralTokens[collateralToken], "CT: !Whitelisted");
        ERC20 collateral = ERC20(collateralToken);
        address account = msg.sender;
        require(collateral.allowance(account, address(this)) >= amount, "CT: !Approved");
        IDEXInteractor interactor = router.interactorFor(market);
        collateral.transferFrom(account, address(interactor), amount);
        uint256 baseAmount = _positionSizeForCollateral(amount.fromDecimalToDecimal(collateral.decimals(), 18));
        uint256 collateralAmount = amount;
        bool isExactInput = _isBaseToken[collateralToken];
        ShortPositionParams memory params = ShortPositionParams({
            market: market,
            amount: baseAmount,
            amountIsBase: isExactInput,
            collateralToken: collateralToken,
            collateralAmount: collateralAmount
        });
        (uint256 base, uint256 quote) = router.depositAndOpen(params);
        uint256 amountToMint = quote;

        collateralDeposited[collateralToken] += amount;
        redeemable[collateralToken] += amount;
        mintedPerCollateral[collateralToken] += amountToMint;

        token.mint(account, amountToMint);
        emit Minted(account, base, quote, amountToMint);
    }

    /// @notice Redeems a given amount of collateral tokens.
    /// @param market the market to open the futures position in.
    /// @param collateralToken the token being used as collateral
    /// @param amount The amount of `collateralToken` to redeem.
    function redeem(
        address market,
        address collateralToken,
        uint256 amount
    ) external {
        require(collateralTokens[collateralToken], "CT: !Whitelisted");
        ERC20 collateral = ERC20(collateralToken);
        address account = msg.sender;
        uint256 baseAmount = _positionSizeForCollateral(amount.fromDecimalToDecimal(collateral.decimals(), 18));
        uint256 collateralAmount = amount;
        bool isExactInput = _isBaseToken[collateralToken];
        LongPositionParams memory params = LongPositionParams({
            market: market,
            amount: baseAmount,
            amountIsBase: isExactInput,
            collateralToken: collateralToken,
            collateralAmount: collateralAmount,
            user: account
        });
        (uint256 base, uint256 quote) = router.reduceAndWithdrawTo(params);
        uint256 toBurn = quote;
        collateralDeposited[collateralToken] -= amount;
        redeemable[collateralToken] -= amount;
        mintedPerCollateral[collateralToken] -= toBurn;

        token.burn(account, toBurn);
        emit Redeemed(account, base, quote, toBurn);
    }

    /// @notice Desposit collateral without opening a position.
    /// @dev Not sure if this is needed in prod but is used on testnet for testing.
    /// @param market The address of market to deposit collateral into
    /// @param collateralToken The address of collateral to deposit
    /// @param amount The amount of collateralToken to deposit
    function depositOnly(
        address market,
        address collateralToken,
        uint256 amount
    ) external {
        require(collateralTokens[collateralToken], "CT: !Whitelisted");
        ERC20 collateral = ERC20(collateralToken);
        address account = msg.sender;
        require(collateral.allowance(account, address(this)) >= amount, "CT: !Approved");
        IDEXInteractor interactor = router.interactorFor(market);
        collateralDeposited[collateralToken] += amount;
        collateral.transferFrom(account, address(interactor), amount);
        router.depositCollateralOnly(market, collateralToken, amount);
    }

    /// @notice Returns information of the composition of XDT deposits
    /// @return info the amount minted and redeemable per collateral token.
    function getCollateralInfo() external view returns (CollateralInfo[] memory info) {
        info = new CollateralInfo[](collateralList.length);
        for (uint256 i = 0; i < collateralList.length; i++) {
            address collateral = collateralList[i];
            info[i] = CollateralInfo({
                token: collateral,
                redeemable: redeemable[collateral],
                minted: mintedPerCollateral[collateral]
            });
        }
    }

    function amountToDecimal(
        uint256 amount,
        uint8 inDecimals,
        uint8 outDecimals
    ) external pure returns (uint256) {
        return amount.fromDecimalToDecimal(inDecimals, outDecimals);
    }

    function _amountToMint(
        uint256 baseAmount,
        uint8 inDecimals,
        uint8 outDecimals
    ) private pure returns (uint256) {
        return baseAmount.fromDecimalToDecimal(inDecimals, outDecimals);
    }

    function _amountToBurn(
        uint256 baseAmount,
        uint8 inDecimals,
        uint8 outDecimals
    ) private pure returns (uint256) {
        return (baseAmount * 10**outDecimals) / 10**inDecimals;
    }

    function _positionSizeForCollateral(uint256 amount) private pure returns (uint256) {
        return amount;
        // return amount.mulWadDown(996 * 1e15);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
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
        return 18;
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
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[owner][spender];
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
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
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

//SPDX-License-Identifier: LGPLv3
pragma solidity ^0.8.9;

import { ERC20, IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

interface IXDToken {
    function mint(address account, uint256 amount) external;

    function burn(address account, uint256 amount) external;
}

contract XDToken is Ownable, ERC20, IXDToken {

    /// Events
    event Minted(address indexed account, uint256 amount);
    event Burned(address indexed account, uint256 amount);
    event ControllerUpdated(address indexed by, address indexed controller);

    /// @notice Controller
    /// @dev Only controller is allowed to mint and burn tokens.
    address public controller;

    modifier onlyController() {
        require(msg.sender == controller, "Not Controller");
        _;
    }

    constructor(
        string memory name,
        string memory symbol,
        uint256 _totalSupply
    ) ERC20(name, symbol) {
        _mint(msg.sender, _totalSupply);
    }

    /// @notice Updates the controller address
    /// @param newController The address of the new controller
    /// @dev Explain to a developer any extra details
    function updateController(address newController) external onlyOwner {
        require(newController != address(0), "XDT: Zero");
        controller = newController;
        emit ControllerUpdated(msg.sender, controller);
    }

    /// @notice Mint tokens to a given account.
    /// @dev Can only be called by the controller.
    /// @param account The account to mint tokens to.
    /// @param amount The amount of tokens to mint
    function mint(address account, uint256 amount) external onlyController {
        _mint(account, amount);
        emit Minted(account, amount);
    }

    /// @notice Burn tokens from a given account.
    /// @dev Can only be called by the controller.
    /// @param account The account to burn tokens from.
    /// @param amount The amount of tokens to burn.
    function burn(address account, uint256 amount) external override onlyController {
        _burn(account, amount);
        emit Burned(account, amount);
    }

    function decimals() public pure override returns (uint8) {
        return 18;
    }

}

//SPDX-License-Identifier: LGPLv3 
pragma solidity ^0.8.9;

interface IERC20 {
    function totalSupply() external returns (uint256);
    function balanceOf(address account) external returns (uint256);
    function transfer(address to, uint256 amount) external;
    function transferFrom(address from, address to, uint256 amount) external;
    function approve(address account, uint256 amount) external;
    function allowance(address account, address spender) external returns (uint256);
    function decimals() external returns (int8);
}

//SPDX-License-Identifier: LGPLv3
pragma solidity ^0.8.9;

import { IDEXInteractor } from "../exchanges/IDEXInteractor.sol";
import { LongPositionParams, ShortPositionParams } from "./PositionParams.sol";

interface IDEXRouter {
    function interactorFor(address baseToken)
        external
        view
        returns (IDEXInteractor);

    function depositAndOpen(
        ShortPositionParams memory params
    ) external returns (uint256, uint256);

    function reduceAndWithdrawTo(
        LongPositionParams memory params
    ) external returns (uint256, uint256);

    function depositCollateralOnly(
        address baseToken,
        address collateralToken,
        uint256 collateralAmount
    ) external;

    function removeCollateralOnly(
        address baseToken,
        address collateralToken,
        uint256 collateralAmount
    ) external;
}

//SPDX-License-Identifier: LGPLv3
pragma solidity ^0.8.9;

interface IDEXInteractor {
    function depositCollateral(address token, uint256 amount) external;

    function removeCollateral(address token, uint256 amount) external;

    function withdrawCollateralTo(
        address token,
        uint256 amount,
        address account
    ) external;

    function openShort(
        address baseToken,
        uint256 amount,
        bool isBaseAmount
    ) external returns (uint256 base, uint256 quote);

    function openLong(
        address baseToken,
        uint256 amount,
        bool isBaseAmount
    ) external returns (uint256 base, uint256 quote);

    function closePosition(address baseToken, uint256 limit) external returns (uint256 base, uint256 quote);
}

//SPDX-License-Identifier: LGPLv3
pragma solidity ^0.8.9;

library DecimalLib {
    function fromDecimalToDecimal(uint256 amount, uint8 inDecimals, uint8 outDecimals) public pure returns (uint256) {
        return amount * 10 ** outDecimals / 10 ** inDecimals;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
library FixedPointMathLib {
    /*///////////////////////////////////////////////////////////////
                    SIMPLIFIED FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.

    function mulWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
    }

    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, y, WAD); // Equivalent to (x * y) / WAD rounded up.
    }

    function divWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, WAD, y); // Equivalent to (x * WAD) / y rounded down.
    }

    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, WAD, y); // Equivalent to (x * WAD) / y rounded up.
    }

    /*///////////////////////////////////////////////////////////////
                    LOW LEVEL FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // Divide z by the denominator.
            z := div(z, denominator)
        }
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // First, divide z - 1 by the denominator and add 1.
            // We allow z - 1 to underflow if z is 0, because we multiply the
            // end result by 0 if z is zero, ensuring we return 0 if z is zero.
            z := mul(iszero(iszero(z)), add(div(sub(z, 1), denominator), 1))
        }
    }

    function rpow(
        uint256 x,
        uint256 n,
        uint256 scalar
    ) internal pure returns (uint256 z) {
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    // 0 ** 0 = 1
                    z := scalar
                }
                default {
                    // 0 ** n = 0
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    // If n is even, store scalar in z for now.
                    z := scalar
                }
                default {
                    // If n is odd, store x in z for now.
                    z := x
                }

                // Shifting right by 1 is like dividing by 2.
                let half := shr(1, scalar)

                for {
                    // Shift n right by 1 before looping to halve it.
                    n := shr(1, n)
                } n {
                    // Shift n right by 1 each iteration to halve it.
                    n := shr(1, n)
                } {
                    // Revert immediately if x ** 2 would overflow.
                    // Equivalent to iszero(eq(div(xx, x), x)) here.
                    if shr(128, x) {
                        revert(0, 0)
                    }

                    // Store x squared.
                    let xx := mul(x, x)

                    // Round to the nearest number.
                    let xxRound := add(xx, half)

                    // Revert if xx + half overflowed.
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }

                    // Set x to scaled xxRound.
                    x := div(xxRound, scalar)

                    // If n is even:
                    if mod(n, 2) {
                        // Compute z * x.
                        let zx := mul(z, x)

                        // If z * x overflowed:
                        if iszero(eq(div(zx, x), z)) {
                            // Revert if x is non-zero.
                            if iszero(iszero(x)) {
                                revert(0, 0)
                            }
                        }

                        // Round to the nearest number.
                        let zxRound := add(zx, half)

                        // Revert if zx + half overflowed.
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }

                        // Return properly scaled zxRound.
                        z := div(zxRound, scalar)
                    }
                }
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

    function sqrt(uint256 x) internal pure returns (uint256 z) {
        assembly {
            // Start off with z at 1.
            z := 1

            // Used below to help find a nearby power of 2.
            let y := x

            // Find the lowest power of 2 that is at least sqrt(x).
            if iszero(lt(y, 0x100000000000000000000000000000000)) {
                y := shr(128, y) // Like dividing by 2 ** 128.
                z := shl(64, z)
            }
            if iszero(lt(y, 0x10000000000000000)) {
                y := shr(64, y) // Like dividing by 2 ** 64.
                z := shl(32, z)
            }
            if iszero(lt(y, 0x100000000)) {
                y := shr(32, y) // Like dividing by 2 ** 32.
                z := shl(16, z)
            }
            if iszero(lt(y, 0x10000)) {
                y := shr(16, y) // Like dividing by 2 ** 16.
                z := shl(8, z)
            }
            if iszero(lt(y, 0x100)) {
                y := shr(8, y) // Like dividing by 2 ** 8.
                z := shl(4, z)
            }
            if iszero(lt(y, 0x10)) {
                y := shr(4, y) // Like dividing by 2 ** 4.
                z := shl(2, z)
            }
            if iszero(lt(y, 0x8)) {
                // Equivalent to 2 ** z.
                z := shl(1, z)
            }

            // Shifting right by 1 is like dividing by 2.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // Compute a rounded down version of z.
            let zRoundDown := div(x, z)

            // If zRoundDown is smaller, use it.
            if lt(zRoundDown, z) {
                z := zRoundDown
            }
        }
    }
}

//SPDX-License-Identifier: LGPLv3
pragma solidity ^0.8.9;

struct LongPositionParams {
    address market;
    uint256 amount;
    bool amountIsBase;
    address collateralToken;
    uint256 collateralAmount;
    address user;
}

struct ShortPositionParams {
    address market;
    uint256 amount;
    bool amountIsBase;
    address collateralToken;
    uint256 collateralAmount; 
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