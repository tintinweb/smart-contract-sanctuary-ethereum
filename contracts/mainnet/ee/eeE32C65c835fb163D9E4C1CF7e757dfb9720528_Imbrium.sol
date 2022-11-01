// SPDX-License-Identifier: MIT

/*
Total token supply: 1,000,000,000

10% Reserve
10% Advisors
20% Team
15% Foundation
10% Private 3 sale
5% Public sale
10% Seed round
15% Private sale 1
5% Private sale 2
*/

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract Imbrium is ERC20Capped, ERC20Burnable {
    uint256 public timeOfPublishing;

    uint256 private totalTokenSupply = 1000000000;

    uint256 public releasePeriod = 10000000;

    uint256 feeInPercentage = 5;

    uint public tokensPerSecond = totalTokenSupply / releasePeriod * (10 ** decimals());


    struct userShareObj {
        uint256 totalTokenShare;

        uint256 remainingTokenShare;

        uint256 timestampOfLastClaim;
    }

    mapping(address => userShareObj) public userShareMap;

    // Contributor addresses
    address private Reserve = 0x542795BDcbeD4Dc47b535Add84C3A446Fb370289;
    address private Advisors = 0x807518744D08e546aC68ba22974D6a397EB32F70;
    address private Team = 0x0c321556099B88bD46879E698c3d7985aa11C756;
    address private Foundation = 0xC55703263793355fB283ee69b4DF251466EBEC4D;
    address private PrivateSale3 = 0xd3Ab5294039254547Dc5f2FD7cbfdAb050A8c322;
    address private PublicSale = 0x89a4d7e563902045A175cda895B8D41a221332E4;
    address private SeedRound = 0xEE1617D25D90ed8251717b631bB041276B1A2B31;
    address private PrivateSale1 = 0xE683fAEb26c1ffB6feA5a65411f8CaB4cb284b0f;
    address private PrivateSale2 = 0x5798F06ec7797C57010d48C33b1D51E993690C03;

    constructor() ERC20("Imbrium", "IMB") ERC20Capped(totalTokenSupply * (10 ** decimals()))  {
        timeOfPublishing = block.timestamp;

        userShareMap[Reserve] = userShareObj(
            calculateTokenShareBasedOnPercentage(10, totalTokenSupply) * (10 ** decimals()),
            calculateTokenShareBasedOnPercentage(10, totalTokenSupply) * (10 ** decimals()),
            timeOfPublishing
        );

        userShareMap[Advisors] = userShareObj(
            calculateTokenShareBasedOnPercentage(10, totalTokenSupply) * (10 ** decimals()),
            calculateTokenShareBasedOnPercentage(10, totalTokenSupply) * (10 ** decimals()),
            timeOfPublishing
        );

        userShareMap[Team] = userShareObj(
            calculateTokenShareBasedOnPercentage(20, totalTokenSupply) * (10 ** decimals()),
            calculateTokenShareBasedOnPercentage(20, totalTokenSupply) * (10 ** decimals()),
            timeOfPublishing
        );

        userShareMap[Foundation] = userShareObj(
            calculateTokenShareBasedOnPercentage(15, totalTokenSupply) * (10 ** decimals()),
            calculateTokenShareBasedOnPercentage(15, totalTokenSupply) * (10 ** decimals()),
            timeOfPublishing
        );

        userShareMap[PrivateSale3] = userShareObj(
            calculateTokenShareBasedOnPercentage(10, totalTokenSupply) * (10 ** decimals()),
            calculateTokenShareBasedOnPercentage(10, totalTokenSupply) * (10 ** decimals()),
            timeOfPublishing
        );

        userShareMap[PublicSale] = userShareObj(
            calculateTokenShareBasedOnPercentage(5, totalTokenSupply) * (10 ** decimals()),
            calculateTokenShareBasedOnPercentage(5, totalTokenSupply) * (10 ** decimals()),
            timeOfPublishing
        );

        userShareMap[SeedRound] = userShareObj(
            calculateTokenShareBasedOnPercentage(10, totalTokenSupply) * (10 ** decimals()),
            calculateTokenShareBasedOnPercentage(10, totalTokenSupply) * (10 ** decimals()),
            timeOfPublishing
        );

        userShareMap[PrivateSale1] = userShareObj(
            calculateTokenShareBasedOnPercentage(15, totalTokenSupply) * (10 ** decimals()),
            calculateTokenShareBasedOnPercentage(15, totalTokenSupply) * (10 ** decimals()),
            timeOfPublishing
        );

        userShareMap[PrivateSale2] = userShareObj(
            calculateTokenShareBasedOnPercentage(5, totalTokenSupply) * (10 ** decimals()),
            calculateTokenShareBasedOnPercentage(5, totalTokenSupply) * (10 ** decimals()),
            timeOfPublishing
        );
    }

    function _mint(address _beneficiary, uint256 _amount) internal virtual override(ERC20, ERC20Capped) {
        require(ERC20.totalSupply() + _amount <= cap(), "ERC20Capped: cap exceeded");
        super._mint(_beneficiary, _amount);
    }

    function _transfer(address from, address to, uint256 amount) internal virtual override {
        uint256 amountToTransfer = amount;
        uint256 amountToBurn = calculateBurnableFee(amount);

        amountToTransfer = amount - amountToBurn;
        burn(amountToBurn);

        super._transfer(from, to, amountToTransfer);
    }

    function calculateBurnableFee(uint256 amount) private view returns (uint256) {
        return amount * feeInPercentage / 100;
    }

    function calculateTokenShareBasedOnPercentage(uint256 _percentageToBeAwarded, uint256 _tokens) private pure returns(uint256) {
        return _tokens * _percentageToBeAwarded / 100;
    }

    function claimTokens() public {
        uint256 currentTime = block.timestamp;
        uint256 tokensToBeMinted;

        // TODO use modifier instead of if/else
        if (msg.sender == Reserve && userShareMap[Reserve].remainingTokenShare > 0) {
            tokensToBeMinted = calculateTokensToBeReleased(userShareMap, Reserve, currentTime);
            mintTokensAndDecrementTokensToBeMinted(tokensToBeMinted, Reserve, userShareMap, currentTime);
        } else if(msg.sender == Advisors && userShareMap[Advisors].remainingTokenShare > 0) {
            tokensToBeMinted = calculateTokensToBeReleased(userShareMap, Advisors, currentTime);
            mintTokensAndDecrementTokensToBeMinted(tokensToBeMinted, Advisors, userShareMap, currentTime);
        } else if(msg.sender == Team && userShareMap[Team].remainingTokenShare > 0) {
            tokensToBeMinted = calculateTokensToBeReleased(userShareMap, Team, currentTime);
            mintTokensAndDecrementTokensToBeMinted(tokensToBeMinted, Team, userShareMap, currentTime);
        } else if(msg.sender == Foundation && userShareMap[Foundation].remainingTokenShare > 0) {
            tokensToBeMinted = calculateTokensToBeReleased(userShareMap, Foundation, currentTime);
            mintTokensAndDecrementTokensToBeMinted(tokensToBeMinted, Foundation, userShareMap, currentTime);
        } else if(msg.sender == PrivateSale3 && userShareMap[PrivateSale3].remainingTokenShare > 0) {
            tokensToBeMinted = calculateTokensToBeReleased(userShareMap, PrivateSale3, currentTime);
            mintTokensAndDecrementTokensToBeMinted(tokensToBeMinted, PrivateSale3, userShareMap, currentTime);
        } else if(msg.sender == PublicSale && userShareMap[PublicSale].remainingTokenShare > 0) {
            tokensToBeMinted = calculateTokensToBeReleased(userShareMap, PublicSale, currentTime);
            mintTokensAndDecrementTokensToBeMinted(tokensToBeMinted, PublicSale, userShareMap, currentTime);
        } else if(msg.sender == SeedRound && userShareMap[SeedRound].remainingTokenShare > 0) {
            tokensToBeMinted = calculateTokensToBeReleased(userShareMap, SeedRound, currentTime);
            mintTokensAndDecrementTokensToBeMinted(tokensToBeMinted, SeedRound, userShareMap, currentTime);
        } else if(msg.sender == PrivateSale1 && userShareMap[PrivateSale1].remainingTokenShare > 0) {
            tokensToBeMinted = calculateTokensToBeReleased(userShareMap, PrivateSale1, currentTime);
            mintTokensAndDecrementTokensToBeMinted(tokensToBeMinted, PrivateSale1, userShareMap, currentTime);
        } else if(msg.sender == PrivateSale2 && userShareMap[PrivateSale2].remainingTokenShare > 0) {
            tokensToBeMinted = calculateTokensToBeReleased(userShareMap, PrivateSale2, currentTime);
            mintTokensAndDecrementTokensToBeMinted(tokensToBeMinted, PrivateSale2, userShareMap, currentTime);
        } else {
            require(false, "You are not authorized to claim tokens!");
        }
    }

    function calculateTokensToBeReleased(mapping(address => userShareObj) storage _userShareMap, address _beneficiary, uint256 _currentTime) private view returns(uint256) {
        // if all tokens are unlocked, return all remaining tokens for minting
        if (_currentTime > timeOfPublishing + releasePeriod) {
            return _userShareMap[_beneficiary].remainingTokenShare;
        } else {
            uint256 elapsedTimeSinceLastRelease = _currentTime - _userShareMap[_beneficiary].timestampOfLastClaim;
            uint256 tokens = elapsedTimeSinceLastRelease * tokensPerSecond;

            if (tokens < _userShareMap[_beneficiary].remainingTokenShare) {
                return tokens;
            } else {
                return _userShareMap[_beneficiary].remainingTokenShare;
            }
        }
    }

    function mintTokensAndDecrementTokensToBeMinted(uint256 _tokens, address _beneficiary, mapping(address => userShareObj) storage _userShareMap, uint256 _currentTime) private {
        _mint(_beneficiary, _tokens);

        uint256 decrementedTokens = _userShareMap[_beneficiary].remainingTokenShare - _tokens;
        _userShareMap[_beneficiary].remainingTokenShare = decrementedTokens;
        _userShareMap[_beneficiary].timestampOfLastClaim = _currentTime;

    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/ERC20Capped.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";

/**
 * @dev Extension of {ERC20} that adds a cap to the supply of tokens.
 */
abstract contract ERC20Capped is ERC20 {
    uint256 private immutable _cap;

    /**
     * @dev Sets the value of the `cap`. This value is immutable, it can only be
     * set once during construction.
     */
    constructor(uint256 cap_) {
        require(cap_ > 0, "ERC20Capped: cap is 0");
        _cap = cap_;
    }

    /**
     * @dev Returns the cap on the token's total supply.
     */
    function cap() public view virtual returns (uint256) {
        return _cap;
    }

    /**
     * @dev See {ERC20-_mint}.
     */
    function _mint(address account, uint256 amount) internal virtual override {
        require(ERC20.totalSupply() + amount <= cap(), "ERC20Capped: cap exceeded");
        super._mint(account, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

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
     * @dev Moves `amount` of tokens from `from` to `to`.
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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