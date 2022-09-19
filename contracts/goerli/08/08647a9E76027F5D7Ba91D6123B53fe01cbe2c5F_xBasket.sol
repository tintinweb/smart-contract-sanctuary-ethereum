// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

interface IxTokenRouter {
    function getCToken(string memory _name) external view returns(address);
    function getXToken(string memory _name) external view returns(address);
}

interface IOraclePrices  {
    function getXTokenPrice(address xToken) external view returns(uint256);
    function prices(string memory) external view returns(uint256);
    function usdc() external view returns(address);
}



interface IXToken is IERC20 {
    function stake(uint256 amount) external;
    function unstake(uint256 amount) external;
    function xBasketTransfer(address _from, uint256 amount) external;
    function Staked(address) external view returns(uint256 amount, uint256 startTime); // Not
    function availableToClaim(address account) external view returns(uint256);
    function claim() external;
}

contract xBasket is ERC20, Ownable {
    IxTokenRouter public xTokenRouter;
    IOraclePrices public oraclePrices;
    address public xWheat;
    address public xSoy;
    address public xCorn;
    address public xRice;
    address public cWheat;
    address public cSoy;
    address public cCorn;
    address public cRice;
    address public usdc;

    ISwapRouter public constant uniswapRouter = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    
    constructor(address _xTokenRouter, address _oraclePrices) ERC20("xBasket LandX Index Fund", "xBASKET") {
        xTokenRouter = IxTokenRouter(_xTokenRouter);
        oraclePrices = IOraclePrices(_oraclePrices);
        xWheat = xTokenRouter.getXToken("WHEAT");
        xSoy = xTokenRouter.getXToken("SOY");
        xRice = xTokenRouter.getXToken("RICE");
        xCorn = xTokenRouter.getXToken("CORN");
        cWheat = xTokenRouter.getCToken("WHEAT");
        cSoy = xTokenRouter.getCToken("SOY");
        cRice = xTokenRouter.getCToken("RICE");
        cCorn = xTokenRouter.getCToken("CORN");
        usdc = oraclePrices.usdc();
    }

    // Deposit xTokens to mint xBasket
    function mint(uint256 _amount) external {
        IXToken(xWheat).xBasketTransfer(msg.sender,_amount);
        IXToken(xSoy).xBasketTransfer(msg.sender,_amount);
        IXToken(xRice).xBasketTransfer(msg.sender,_amount);
        IXToken(xCorn).xBasketTransfer(msg.sender,_amount);
        IXToken(xWheat).stake(_amount);
        IXToken(xSoy).stake(_amount);
        IXToken(xRice).stake(_amount);
        IXToken(xCorn).stake(_amount);
        uint256 usdVaultValuation = calculateTVL();
        uint256 circulatingSupply = totalSupply();
        // This maths needs testing. From https://solidity-by-example.org/defi/vault/
        uint256 shares;
        if (circulatingSupply == 0) {
            shares = _amount; // initially 1 xBasket = 0.25 of all 4 xTokens
        } else {
            shares = _amount * circulatingSupply / usdVaultValuation;
        }
        _mint(msg.sender, shares);
    }

    function mintPreview(uint256 _amount) public view returns (uint256) {
        uint256 usdVaultValuation = calculateTVL();
        uint256 circulatingSupply = totalSupply();
        uint256 shares;
        if (circulatingSupply == 0) {
            shares = _amount; // initially 1 xBasket = 0.25 of all 4 xTokens
        } else {
            shares = _amount * circulatingSupply / usdVaultValuation;
        }
        return shares;
    }

    // Burn xBasket to redeem xTokens
    function redeem(uint256 _amount) external {
        require(balanceOf(msg.sender) >= _amount, "Your xBasket balance is too low");
        uint256 usdVaultValuation = calculateTVL();
        _burn(msg.sender, _amount);
        autoCompoundRewards(); // make sure we just have xTokens in the vault on redemption.
        uint256 circulatingSupply = totalSupply();
        // This maths needs testing. From https://solidity-by-example.org/defi/vault/
        uint256 redeemAmount;
        if (circulatingSupply == 0) { 
            redeemAmount = _amount;
        } else {
            redeemAmount = (_amount * usdVaultValuation) / circulatingSupply;
        }
        IXToken(xWheat).unstake(redeemAmount);
        IXToken(xSoy).unstake(redeemAmount);
        IXToken(xRice).unstake(redeemAmount);
        IXToken(xCorn).unstake(redeemAmount);
        IXToken(xWheat).transfer(msg.sender,redeemAmount);
        IXToken(xSoy).transfer(msg.sender,redeemAmount);
        IXToken(xRice).transfer(msg.sender,redeemAmount);
        IXToken(xCorn).transfer(msg.sender,redeemAmount);
    }

    function redeemPreview(uint256 _amount) public view returns (uint256) {
        uint256 usdVaultValuation = calculateTVL();
        uint256 circulatingSupply = totalSupply();
        if (circulatingSupply == 0) {
            return _amount;
        }
        uint256 redeemAmount = (_amount * usdVaultValuation) / circulatingSupply;
        return redeemAmount;
    }

    // calculate the value of the contracts xToken holdings in USDC
    function calculateCollateral() public view returns(uint256) {
        // xTokens Balances
        uint256 xWheatBalance = IXToken(xWheat).balanceOf(address(this));
        uint256 xSoyBalance = IXToken(xSoy).balanceOf(address(this));
        uint256 xRiceBalance = IXToken(xRice).balanceOf(address(this));
        uint256 xCornBalance = IXToken(xCorn).balanceOf(address(this));

        (uint256 xWheatStaked,) = IXToken(xWheat).Staked(address(this));
        (uint256 xSoyStaked,) = IXToken(xSoy).Staked(address(this));
        (uint256 xRiceStaked,) = IXToken(xRice).Staked(address(this));
        (uint256 xCornStaked,) = IXToken(xCorn).Staked(address(this));

        // USDC Prices - Note this assumes prices are stored in USDC with 6 decimals
        uint256 xWheatPrice = oraclePrices.getXTokenPrice(xWheat);
        uint256 xSoyPrice = oraclePrices.getXTokenPrice(xSoy);
        uint256 xRicePrice = oraclePrices.getXTokenPrice(xRice);
        uint256 xCornPrice = oraclePrices.getXTokenPrice(xCorn);
        
        // Valutations
        uint256 collateral;
        collateral += (xWheatBalance + xWheatStaked) * xWheatPrice / 1e6;
        collateral += (xSoyBalance + xSoyStaked) * xSoyPrice / 1e6;
        collateral += (xRiceBalance + xRiceStaked) * xRicePrice / 1e6;
        collateral += (xCornBalance + xCornStaked) * xCornPrice / 1e6;
        return collateral;        
    }

    // calculate the value of the contracts cToken holdings in USDC
    function calculateYield() public view returns(uint256) {
        // Rewards Pending & USDC balance
        uint256 cWheatPending = IXToken(xWheat).availableToClaim(address(this));
        uint256 cSoyPending = IXToken(xSoy).availableToClaim(address(this));
        uint256 cRicePending = IXToken(xRice).availableToClaim(address(this));
        uint256 cCornPending = IXToken(xCorn).availableToClaim(address(this));      
        uint256 usdcBalance = IERC20(usdc).balanceOf(address(this));

        // USDC Prices - Note this assumes prices are stored in USDC with 6 decimals
        uint256 cWheatPrice = oraclePrices.prices("WHEAT");
        uint256 cSoyPrice = oraclePrices.prices("SOY");
        uint256 cRicePrice = oraclePrices.prices("RICE");
        uint256 cCornPrice = oraclePrices.prices("CORN");

        // Valutations
        uint256 totalYield = usdcBalance;
        totalYield += (IERC20(cWheat).balanceOf(address(this)) + cWheatPending) * cWheatPrice / 1e9;
        totalYield += (IERC20(cSoy).balanceOf(address(this)) + cSoyPending) * cSoyPrice / 1e9;
        totalYield += (IERC20(cRice).balanceOf(address(this)) + cRicePending) * cRicePrice / 1e9;
        totalYield += (IERC20(cCorn).balanceOf(address(this)) + cCornPending) * cCornPrice / 1e9;
        return totalYield;    
    }

    // calculate the value of the contracts holdings in USDC
    function calculateTVL() public view returns(uint256) {
        uint256 totalCollateral = calculateCollateral();
        uint256 totalYield = calculateYield();
        uint256 tvl = totalCollateral + totalYield;
        return tvl;        
    }

    // calculate price per token
    function pricePerToken() public view returns(uint256) {
        uint256 tvl = calculateTVL();
        uint256 circulatingSupply = totalSupply();
        uint256 xBasketPrice = tvl * 1e6 / circulatingSupply; // price is usdc (6 decimals) for 1 xBasket
        return xBasketPrice;
    }

    // claim rewards, sell cTokens, buy xTokens, stake new xTokens
    function autoCompoundRewards() public {
        IXToken(xWheat).claim();
        IXToken(xSoy).claim();
        IXToken(xRice).claim();
        IXToken(xCorn).claim();
        uint256 cWheatBalance = IERC20(cWheat).balanceOf(address(this));
        uint256 cSoyBalance = IERC20(cSoy).balanceOf(address(this));
        uint256 cRiceBalance = IERC20(cRice).balanceOf(address(this));
        uint256 cCornBalance = IERC20(cCorn).balanceOf(address(this));
       
        ERC20Burnable(cWheat).burn(cWheatBalance);  //Sell cWheat
        convertToXToken(xWheat); //Buy xWheat
       
        ERC20Burnable(cSoy).burn(cSoyBalance);  //Sell cSoy
        convertToXToken(xSoy); //Buy xSoy
       
        ERC20Burnable(cRice).burn(cRiceBalance);  //Sell cRice
        convertToXToken(xRice); //Buy xRice
        
        ERC20Burnable(cCorn).burn(cCornBalance); //Sell cCorn
        convertToXToken(xCorn); //Buy xCorn

        uint256 xWheatBalance = IXToken(xWheat).balanceOf(address(this));
        uint256 xSoyBalance = IXToken(xSoy).balanceOf(address(this));
        uint256 xRiceBalance = IXToken(xRice).balanceOf(address(this));
        uint256 xCornBalance = IXToken(xCorn).balanceOf(address(this));
        IXToken(xWheat).stake(xWheatBalance);
        IXToken(xSoy).stake(xSoyBalance);
        IXToken(xRice).stake(xRiceBalance);
        IXToken(xCorn).stake(xCornBalance);
    }

     function convertToXToken(address xToken) internal returns(uint256) {
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams(
            usdc,
            xToken,
            3000,
            address(this),
            block.timestamp + 15,
            IERC20(usdc).balanceOf(address(this)),
            1,
            0
        );
        return uniswapRouter.exactInputSingle(params);
    }

    function decimals() public pure override returns (uint8) {
        return 6;
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}