//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "./SpaceLP.sol";
import "./SpaceCoin.sol";
contract SpaceRouter {
    SpaceLP public spaceLP;
    SpaceCoin public spaceCoin;
    constructor(SpaceLP _spaceLP, SpaceCoin _spaceCoin) {
        spaceLP = _spaceLP;
        spaceCoin = _spaceCoin;

    }

    /// @notice Provides ETH-SPC liquidity to LP contract
    /// @param spc The amount of SPC to be deposited
    function addLiquidity(uint256 spc) external payable { 
        require(msg.value > 0,"SpaceRouter:addLiquidity:didnt send eth");
        require(spc > 0,"SpaceRouter:addLiquidity:spc amount is 0");
        if (spaceLP.totalSupply() != 0) {
            require((msg.value * 100000)/ (spc) == spaceLP.getReserveRatio() ,"SpaceRouter:addLiquidity:wrong balance of deposits");
        }

        sweepSpaceLP();
        //will revert or return true only
        spaceCoin.transferFrom(msg.sender,address(spaceLP),spc);
        (bool ethSuccess, ) = address(spaceLP).call{value: msg.value}("");
        assert(ethSuccess); // we control spaceLP 
        spaceLP.deposit(msg.sender);       
        
    }

    // /// @notice Removes ETH-SPC liquidity from LP contract
    // /// @param lpToken The amount of LP tokens being returned
    function removeLiquidity(uint256 lpToken) external {
        require(lpToken > 0,"SpaceRouter:removeLiquidity:lpToken amount is 0");
        spaceLP.transferFrom(msg.sender,address(spaceLP),lpToken);
        spaceLP.withdraw(msg.sender);
     }

    /// @notice Swaps ETH for SPC in LP contract
    /// @param spcOutMin The minimum acceptable amout of SPC to be received
    function swapETHForSPC(uint256 spcOutMin) external payable { 
        require(msg.value > 0,"SpaceRouter:swapETHForSPC:no eth sent");
        require(spcOutMin < spaceLP.getSPCforETHPrice(msg.value),"SpaceRouter:swapETHForSPC:spcOutMin too high");
        sweepSpaceLP();
        address(spaceLP).call{value: msg.value}(""); // we control spaceLP
        spaceLP.swap(msg.sender);
    }

    /// @notice Swaps SPC for ETH in LP contract
    /// @param spcIn The amount of inbound SPC to be swapped
    /// @param ethOutMin The minimum acceptable amount of ETH to be received
    function swapSPCForETH(uint256 spcIn, uint256 ethOutMin) external { 
        require(spcIn > 0,"SpaceRouter:swapSPCForETH:no spcIn");
        require(ethOutMin < spaceLP.getETHForSPCPrice(spcIn),"SpaceRouter:swapSPCForETH:ethOutMin too high");
        sweepSpaceLP();
        spaceCoin.transferFrom(msg.sender,address(spaceLP),spcIn);
        spaceLP.swap(msg.sender);


    }

    /// @notice helper function to sweep spaceLP if needed
    function sweepSpaceLP() private {
        if (spaceLP.shouldPublicSweep()) {
            spaceLP.publicSweep();
        }
    }
    function inCaseForAccidentlySentInSpc() public {
        uint256 spcBal = spaceCoin.balanceOf(address(this));
        require(spcBal > 0,"SpaceRouter:inCaseForAccidentlySentInSpc:spc bal is 0");
        spaceCoin.transfer(address(spaceLP),spcBal); 
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./SpaceCoin.sol";
contract SpaceLP is ERC20 {
    uint256 public reserve0;           
    uint256 public reserve1;          
    SpaceCoin public spaceCoin;


    event Deposit(address indexed trader,uint256 deposit0,uint256 deposit1,uint256 lpTokens);
    event Withdraw(address indexed trader,uint256 eth,uint256 spc,uint256 lpTokens);
    event SwapETHforSPC(address indexed trader,uint256 ethAmt,uint256 spcAmt);
    event SwapSPCforETH(address indexed trader,uint256 spcAmt,uint256 ethAmt);
    constructor(SpaceCoin _spaceCoin) ERC20("SpaceLP", "SPLP") { 
        spaceCoin = _spaceCoin;

    }
    bool private locked;
    modifier lock() {
        require(locked == false, 'SpaceLP:lock:LOCKED');
        locked = true;
        _;
        locked = false;
    }


    /// @notice Adds ETH-SPC liquidity to LP contract
    /// @param to The address that will receive the LP tokens
    function deposit(address to) lock public payable {

        // we calculate all the new tokens we received and assume its for the latest caller of deposit
        uint256 deposit0 = address(this).balance - reserve0;
        uint256 deposit1 = spaceCoin.balanceOf(address(this)) - reserve1;
        uint256 lpTokens;
        if (totalSupply() == 0) {
            lpTokens = deposit0 + deposit1;

            if (deposit0 > 0 && deposit1 > 0 && (deposit0 * 100000)/deposit1 > 0) {
                
                _mint(to,lpTokens);
                emit Deposit(to,deposit0,deposit1,lpTokens);
            } 
            
        } else {
            // we are going to be total dicks and expect exact right ratio or we fail silently
            if ((deposit0 * 100000)/(deposit1) == getReserveRatio()) {
                lpTokens = (deposit0 * totalSupply()) / reserve0;
                _mint(to,lpTokens);
                emit Deposit(to,deposit0,deposit1,lpTokens);
            } 
        }
        //absorb faulty deposits into reserves anyway
        sweep();
        
     }

    /// @notice Returns ETH-SPC liquidity to liquidity provider
    /// @param to The address that will receive the outbound token pair
    function withdraw(address to) lock external { 
            // amt = (lpTokensReceived / totalSupply) * reserve 
            uint256 lpTokensReceived = balanceOf(address(this));
            uint256 withdrawETH = (lpTokensReceived * reserve0)/ totalSupply();
            require(withdrawETH > 0,"SpaceLP:withdraw:no LP tokens received");
            uint256 withdrawSPC = (lpTokensReceived * reserve1)/ totalSupply();
            _burn(address(this),lpTokensReceived);
            // transfer always returns true or reverts
            spaceCoin.transfer(to,withdrawSPC);
            (bool ethSuccess, ) = to.call{value: withdrawETH}("");
            require(ethSuccess,"SpaceLP:withdraw:ETH withdraw failure");
            emit Withdraw(to,withdrawETH,withdrawSPC,lpTokensReceived);
            sweep();
            
        
    }
    /// @notice Swaps ETH for SPC, or SPC for ETH
    /// @param to The address that will receive the outbound SPC or ETH
    function swap(address to) lock external {
        uint256 deposit0 = address(this).balance - reserve0;
        uint256 deposit1 = spaceCoin.balanceOf(address(this)) - reserve1;
        require(deposit0 > 0 || deposit1 > 0,"SpaceLP:swap:no deposits received");
        require((deposit0 > 0 && deposit1 > 0) == false,"SpaceLP:swap:balances out of sync, call publicSweep()");
        if (deposit0 > 0) {
            uint256 spcAmt = getSPCforETHPrice(deposit0);
            spaceCoin.transfer(to,spcAmt);
            emit SwapETHforSPC(to,deposit0,spcAmt);
        } 
        else {
            uint256 ethAmt = getETHForSPCPrice(deposit1);
            require(((reserve0 - ethAmt) * 100000 )/ reserve1 > 0,"SpaceLP:swap:max difference of 100000x");
            (bool successEth, ) = to.call{value: ethAmt}("");
            require(successEth,"SpaceLP:swap:eth transfer failed");
            emit SwapSPCforETH(to,deposit1,ethAmt);
        }
        sweep();

    }
    // /// @notice helper function to allow offchain systems to poll this function
    function shouldPublicSweep() public view returns (bool) {
        uint256 deposit0 = address(this).balance - reserve0;
        uint256 deposit1 = spaceCoin.balanceOf(address(this)) - reserve1;
        if (deposit0 > 0 || deposit1 > 0) {
            return true;
        } else {
            return false;
        }
        
    }
    /// @notice public sweep balances 
    function publicSweep() lock public {
        // not gona check for shouldPublicSweep, trust in our lock
        sweep();
    }
    /// @notice sweep balances into reserves
    function sweep() private {
        reserve0 = address(this).balance;
        reserve1 = spaceCoin.balanceOf(address(this));
    }
    /// @notice reserve ratio
    /// @return reserveRatio amt of spc you are going to get at current state of pool
    function getReserveRatio() public view returns (uint256 reserveRatio) {
        reserveRatio = (reserve0 * 100000) / (reserve1);
    }
    /// @notice function helper to get price
    /// @param ethAmt amount of eth you are going to swap
    /// @return spcAmt amt of spc you are going to get at current state of pool
    function getSPCforETHPrice(uint256 ethAmt) public view returns (uint256 spcAmt) {
        require((reserve0 > 0) && (reserve1 > 0),"SpaceLP:getSPCforETHPrice:not enough reserves");
        // no fees if tiny amount, gas fees prob make it not worth it, and we are ok as small trades are better for price discovery
        uint256 ethAmtAfterTax = ethAmt - (ethAmt/100);
        // (ethBal + ethAmt) * (spcBal - spcAmt) = ethBal * spcBal
        // (spcBal - spcAmt) = (ethBal * spcBal / (ethBal + ethAmt) )
        spcAmt = reserve1 -  ((reserve0 * reserve1) / (reserve0 + ethAmtAfterTax));
        assert(spcAmt < reserve1); //this should prob maths wise never happen, just to get peace of mind
    }

    /// @notice function helper to get price
    /// @param spcAmt amount of eth you are going to swap
    /// @return ethAmt amt of spc you are going to get at current state of pool
    function getETHForSPCPrice(uint256 spcAmt) public view returns (uint256 ethAmt) {
        require((reserve0 > 0) && (reserve1 > 0),"SpaceLP:getETHForSPCPrice:not enough reserves");
        // no fees if tiny amount, gas fees prob make it not worth it, and we are ok as small trades are better for price discovery
        uint256 spcAmtAfterTax = spcAmt - (spcAmt/100);
        // (ethBal - ethAmt) * (spcBal + spcAmt) = ethBal * spcBal
        // (ethBal - ethAmt)  = (ethBal * spcBal ) / (spcBal + spcAmt)
        // ethBal = ((ethBal * spcBal ) / (spcBal + spcAmt)) + ethAmt
        // ethAmt = ethBal - ((ethBal * spcBal ) / (spcBal + spcAmt)) 
        ethAmt = reserve0 - ((reserve0 * reserve1 ) / (reserve1 + spcAmtAfterTax));
        assert(ethAmt < reserve0); //this should prob maths wise never happen, just to get peace of mind
    }

    /// @notice allow contract to receive ether
    receive() external payable {
        // do nothing, dont need to lock by right. by the time reentrancy can happen, we've setup our amount vars.
    }


}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
contract SpaceCoin is ERC20 {
    address public immutable treasuryAccount;
    address public immutable ownerAccount;
    bool public taxOn = false;
    constructor(
        uint256 icoSupply,
        uint256 treasurySupply,
        address treasuryAccount_
    ) 
     
    ERC20("SpaceCoin", "SPC") 
    {
        // use default 18 decimals
        treasuryAccount = treasuryAccount_;
        ownerAccount = address(msg.sender);
        _mint(treasuryAccount, treasurySupply);
        _mint(msg.sender, icoSupply);
    }

    function toggleTax() external {
        require(msg.sender == ownerAccount,"SPC:toggleTax:not ownerAccount");
        taxOn = !taxOn;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        if (taxOn) {
            uint256 treasuryFee =  amount / 50;
            uint256 receiverAmount = amount - treasuryFee;
            super._transfer(from,treasuryAccount,treasuryFee);
            super._transfer(from, to, receiverAmount);
        }
        else {
            super._transfer(from, to, amount);
        }
        
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