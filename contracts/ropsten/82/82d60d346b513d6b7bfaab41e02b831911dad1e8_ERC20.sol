/**
 *Submitted for verification at Etherscan.io on 2022-04-24
*/

// File: contracts/IERC20.sol



pragma solidity ^0.8.0;

/**
 * @dev EIP 中定義的 ERC20 標準接口
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
// File: contracts/ERC20.sol


pragma solidity ^0.8.0;


/** 
 * 此 ERC20 合約結合 "上課實作" 與 "OpenZeppelin" 以學習業界實作方式
 * 查看每個 function 的標準作用請參考 IERC20
 * 查看 OpenZeppelin ERC20 合約請參考 https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol
 * 
 * 此合約定義: 
 * token 發行量無上限，totalSupply 代表已經發出去(鑄造)多少 token
 * deploy 時將 mint 10000 token 給 deploy 的人管理(_owner)
 * 總 supply 數量在 deploy 時固定(Fixed Supply = 10000)，未來 _owner 可透過 mint function 再增加
 * 
 * @dev this contract implement {IERC20} interface (define in EIT)
 */
contract ERC20 is IERC20 {
    // Balances for each account
    mapping(address => uint256) private _balances;

    /**
     * @dev Owner of account approves the transfer of an amount to another account.
     * 
     * ex: B => C => 1000 代表 B 錢包地址允許 C 合約地址動用屬於 B 錢包地址的 1000 Token 
     * 壞處: 持有者只能指定一個操作員，但現實可以有多個操作員，指定新操作員時，就得就會失效
     * 
     * <法二> 一個持有者可有多個操作員，但就要有可刪除操作員的function
     * struct operator {
     *     address operator; // 操作員 EOA
     *     uint256 tokens;   // 授權量
     * }
     * mapping(address => operator[]) allowed;
     * 
     */
    mapping(address => mapping(address => uint256)) private _allowances; // 授權者 => (操作員EOA => 授權量)

    // 此合約定義 token 發行量無上限，totalSupply 代表已經發出去多少 token
    uint256 private _totalSupply; // amount of tokens in existence

    address _owner;
    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     * Both _name and _symbal are immutable: they can only be set once during construction.
     * 此合約在 deploy 時將mint 10000 token 給 deploy 的人管理(_owner)
     */
    constructor(string memory name_, string memory symbol_) {
        _owner = msg.sender;
        _name = name_;  // deploy 時才給值可發行不同名稱的 token
        _symbol = symbol_;
        _mint(msg.sender, 1000);
    }

    modifier onlyOwner() {
        if(msg.sender != _owner) {
            revert();
        }
        _;
    }

    function mint(uint256 amount) public onlyOwner {
        _mint(_owner, amount);
    }

    /**
     * @dev Returns the name of the token.
     * Token 的名字
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the name.
     * Token 代稱，也會出現在 Etherscan 上
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is overridden;
     * Token 位數，通常會設定成 18，這樣的設定跟 Ether 是一樣的
     * (Solidity 中沒有浮點數的存在，所有的運算都是整數，因此 1 Ether 在 Solidity 程式中是以 10¹⁸ 來撰寫)
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}. 已發出多少 token
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}. 此 address EOA 帳戶的 token 數量
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
        address owner = msg.sender;
        _transfer(owner, to, amount); // 檢查會在 _transfer 中進行
        return true;
    }

    /**
     * @dev See {IERC20-allowance}. 代理人帳戶還剩多少token額度可動用
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}. 執行的人(授權人)設定代理人(操作員)，以及可動用(授權)多少錢
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, amount); // 檢查會在 _approve 中進行
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}. 指定轉帳雙方
     *
     * Emits an {Approval} event indicating the updated allowance.
     * This is not required by the EIP.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = msg.sender;
        // Might emit an {Approval} event.
        // This allows applications to reconstruct the allowance for all accounts just
        // by listening to said events. Other implementations of the EIP may not emit
        // these events, as it isn't required by the specification.
        _spendAllowance(from, spender, amount); // 檢查足夠的 allowance
        _transfer(from, to, amount); // 檢查其他轉帳條件
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
        address owner = msg.sender;
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
        address owner = msg.sender;
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
        // 檢查 `from`,  `to` 帳戶合法性
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount); // 若在transfer前有其他固定操作，可加在此 function

        uint256 fromBalance = _balances[from];  // 轉錢的人餘額夠
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        
        require(_balances[to] + amount > _balances[to], "ERC20: transfer overflow"); // overflow 檢查

        // 在 Solidity 0.8.0 之前，算術運算會在發生溢出的情況下進行“截斷”，須引入額外檢查庫來解決
        // Solidity 0.8.0 開始，所有的算術運算默認就會進行溢出檢查，額外引入庫將不再必要。
        unchecked {     // 溢出會返回"截斷"的结果，若不使用unchecked 則會拋出異常
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount); // 若在transfer後有其他固定操作，可加在此 function
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

        _totalSupply += amount; // 發出的token數量增加
        _balances[account] += amount;
        emit Transfer(address(0), account, amount); // 製造token也是一種 transfer，從 0(代表contract) 轉到 account

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
            _balances[account] = accountBalance - amount; // 銷毀token也是一種 transfer，從 account 轉到 0(代表contract) 
        }
        _totalSupply -= amount; // 發出的token數量減少

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
        // 檢查 `owner`,  `spender` 帳戶合法性
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
     * Might emit an {Approval} event. 這並不規範在 EIT
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance"); // 檢查有足夠的 allowance
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