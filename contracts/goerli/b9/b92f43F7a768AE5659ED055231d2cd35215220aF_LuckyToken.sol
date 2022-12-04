/**
 *Submitted for verification at Etherscan.io on 2022-12-04
*/

// SPDX-License-Identifier: MIT
// Credits to OpenZeppelin
pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract ERC20 is Context {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    event Transfer(address indexed from, address indexed to, uint256 value);
    //value是被更改的代币的数目
    event Approval(address indexed owner, address indexed spender, uint256 value );
    // value = new allowance

    uint256 private _totalSupply;
    //uint256 private decimals = 18;

    string private _name;
    string private _symbol;
    //A function that allows an inheriting contract to override its behavior will be marked at virtual.
    
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint256) {
        //return decimals;
        return 18;
        /**
        * @dev Returns the number of decimals used to get its user representation.
        * For example, if `decimals` equals `2`, a balance of `505` tokens should
        * be displayed to a user as `5.05` (`505 / 10 ** 2`).
        */
    }

    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        require(to != address(0));
        require(_balances[_msgSender()]>=amount);

        _transfer(_msgSender(), to , amount);
        return true;
        /** TODO
        * @dev Moves `amount` tokens from the caller's account to `to`.
        *
        * Returns a boolean value indicating whether the operation succeeded.
        * Requirements:
        *
        * - `to` cannot be the zero address.
        * - the caller must have a balance of at least `amount`.
        */
    }

    function allowance(address owner, address spender) public view virtual returns (uint256){
        return _allowances[owner][spender];
        /** TODO 
        * @dev Returns the remaining number of tokens that `spender` will be
        * allowed to spend on behalf of `owner` through {transferFrom}. This is
        * zero by default.
        */
    }

    function approve(address spender, uint256 amount)public virtual returns (bool){
        require(spender != address(0));
        // TODO: use `_approve` defined later in the contract
        _approve(_msgSender(), spender, amount);
        //_allowances[_msgSender()][spender] = amount;
        return true;
            /** TODO enable to use allowance of owner.
            * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
            *
            * Returns a boolean value indicating whether the operation succeeded.
            *
            * Requirements:
            *
            * - `spender` cannot be the zero address.
            */
    }

    function transferFrom( address from, address to, uint256 amount) public virtual {
        
        require(from != address(0));
        require(to != address(0));
        require(_balances[from] >= amount);
        require(_allowances[from][_msgSender()]>=amount);


        _spendAllowance(from,_msgSender(), amount);
        _transfer(from, to, amount);

        emit Transfer(from, to , amount);
        emit Approval(from, _msgSender(), amount);

        // TODO: use `_spendAllowance` and `_transfer` defined later in the contract
            /** TODO
            * @dev Moves `amount` tokens from `from` to `to` using the
            * allowance mechanism. `amount` is then deducted from the caller's
            * allowance.
            *
            * Emits an {Approval} event indicating the updated allowance. This is not
            * required by the EIP. See the note at the beginning of {ERC20}.
            *
            * NOTE: Does not update the allowance if the current allowance
            * is the maximum `uint256`.
            */
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual {
        // TODO: use `_approve` defined later in the contract
        require(spender != address(0));

        _allowances[_msgSender()][spender]+= addedValue;
        _approve(_msgSender(),spender, _allowances[_msgSender()][spender]);//这不是脱裤子放屁吗 我能直接改_allowance还要用函数？
        emit Approval(_msgSender(),spender, addedValue );
            /** TODO
            * @dev Atomically increases the allowance granted to `spender` by the caller.
            */
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)public virtual {
        // TODO: use `_approve` defined later in the contract
        require(spender != address(0));
        require(_allowances[_msgSender()][spender] >= subtractedValue);

        _allowances[_msgSender()][spender]-= subtractedValue;
        _approve( _msgSender(),spender, _allowances[_msgSender()][spender]);
        emit Approval(_msgSender(),spender,  subtractedValue);
            /** TODO
            * @dev Atomically decreases the allowance granted to `spender` by the caller.
            */
    }
    // 如果_allowances没法在这里直接修改呢？

    function _transfer(address from, address to, uint256 amount) internal virtual {
        require( from != address(0));
        require( to != address(0));
        require(_balances[from] >= amount);

        _balances[from] -= amount;
        _balances[to] += amount;
        emit Transfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        //TODO
        require(account != address(0));

        _balances[account]+= amount;
        _totalSupply += amount;

        emit Transfer(address(0), account, amount);
            /** TODO
            @dev Creates `amount` tokens and assigns them to `account`, increasing
            * the total supply.
            */
    }

    function _burn(address account, uint256 amount) internal virtual {
        // TODO
        require(account != address(0));
        require(_balances[account] >= amount);

        _balances[account] -= amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
            /** TODO
            * @dev Destroys `amount` tokens from `account`, reducing the
            * total supply.
            */
    }

    function _approve( address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0));
        require(spender != address(0));

        //allowance(owner, spender);
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, _allowances[owner][spender] );
        /** TODO done:set _allowances[owner][spender] = amount
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     */
    }

    function _spendAllowance( address owner, address spender, uint256 amount) internal virtual {//前面第三方transfer的时候 我写了from为spender
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount);
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
            emit Approval(owner, spender,amount);
        }
            /** TODO amount is the unpaid allowance which should be minused
            * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
            *.
            * Revert if not enough allowance is available.
            *
            * Might emit an {Approval} event.
            */
    }
}

abstract contract ERC20Burnable is Context, ERC20 {

    function burn(uint256 amount) public virtual {//从调用者那扣除amount单位的allowance
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {//需要补充 判断allowance 是否足够的代码
        _spendAllowance(account, _msgSender(), amount); //花掉 第二个参数 也就是调用者的allowance ，数值为amount
        _burn(account, amount);  //内部函数  销毁代币
    }
    /**
    * @dev Extension of {ERC20} that allows token holders to destroy both their own
    * tokens and those that they have an allowance for, in a way that can be
    * recognized off-chain (via event analysis).
    */
}

contract LuckyToken is Context, ERC20Burnable {
    mapping(address => bool) _minters;

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _minters[_msgSender()] = true;
    }

    function hasMinterRole(address account) public view virtual returns (bool) {
        return _minters[account];
    }

    function mint(address to, uint256 amount) public virtual {//给to地址 发送amount单位的代币
        require(
            hasMinterRole(_msgSender()),
            "requester must have minter role to mint"
        );
        _mint(to, amount);
    }
    /**
    * @dev {ERC20} token, including:
    *
    *  - ability for holders to burn (destroy) their tokens
    *  - a minter role that allows for token minting (creation)
    *  - a pauser role that allows to stop all token transfers
    */
}

contract LC809 is LuckyToken {
    constructor() LuckyToken("LuckyToken809", "LC809") {}
}