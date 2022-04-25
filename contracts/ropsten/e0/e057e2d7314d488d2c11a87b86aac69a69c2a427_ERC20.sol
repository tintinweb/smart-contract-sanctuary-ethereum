/**
 *Submitted for verification at Etherscan.io on 2022-04-24
*/

// SPDX-License-Identifier: SimPL-2.0
pragma solidity 0.8.13; //編譯器版本

contract ERC20{
    
    // 宣告 mapping & 變數
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    uint8 private _decimals = 18;
    uint256 private _amount;
    string private _name;
    string private _symbol;
    address private _owner;

    // 宣告事件
    event Transfer(address indexed from, address indexed to, uint256 value); 
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // 宣告建構式
    constructor(string memory name_, string memory symbol_, address owner_, uint256 amount_) {
        _name = name_; // 初始化 name
        _symbol = symbol_; // 初始化 symbol
        _owner = owner_; // 合約 owner
        _amount = amount_; // 初始 mint amount
        _mint(_owner, _amount); // 將資料傳入 _mint()
    }

    modifier onlyOwner(){
        require(_msgSender() == _owner, "not owner"); //檢查執行者是不是合約owner
        _; //執行後續程式
    }

    function _msgSender() internal view virtual returns (address) {
        return msg.sender; // 回傳呼叫合約的地址
    }

    // basic return of token data (name, symbol, decimals, total supply, balance)

    function name() public view returns (string memory) {
        return _name; // 回傳 token name
    }

    function symbol() public view returns (string memory) {
        return _symbol; // 回傳 token symbol
    }

    function decimals() public view returns (uint8) {
        return _decimals; // 回傳 token 的 decimals
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply; // 回傳 token 的 total supply
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account]; // 回傳地址的 balances
    }


    // token main method (transfer, mint, burn, approve, change allowance)

    function transfer(address to, uint256 amount) public returns (bool) {
        address owner = _msgSender(); // 將 owner 設為呼叫 function 的地址
        _transfer(owner, to, amount); // 將資料傳入 _transfer()
        return true; // 執行完後回傳 true
    }

    function mint(address account, uint256 amount) public onlyOwner returns (bool) {
        _mint(account, amount); // 將資料傳入 _mint()
        return true; // 執行完後回傳 true
    }

    function burn(uint256 amount) public returns (bool) {
        address account = _msgSender(); // 將 account 設為呼叫 function 的地址
        _burn(account, amount); // 將資料傳入 _burn()
        return true; // 執行完後回傳 true
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender]; // 回傳 owner 地址允許 spender 提取的 value
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        address owner = _msgSender(); // 將 owner 設為呼叫 function 的地址
        _approve(owner, spender, amount); // 將資料傳入 _approve()
        return true; // 執行完後回傳 true
    }

    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        address spender = _msgSender(); // 將 spender 設為呼叫 function 的地址
        _spendAllowance(from, spender, amount); // 將資料傳入 _spendAllowance()
        _transfer(from, to, amount); // 將資料傳入 _transfer()
        return true; // 執行完後回傳 true
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender(); // 將 owner 設為呼叫 function 的地址
        _approve(owner, spender, allowance(owner, spender) + addedValue); // 將資料傳入 _approve()
        return true; // 執行完後回傳 true
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender(); // 將 owner 設為呼叫 function 的地址
        uint256 currentAllowance = allowance(owner, spender); // 使用 allowance() 取得 value 並設為 currentAllowance
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero"); // 判斷條件，若滿足則繼續執行程式，否則回傳錯誤訊息
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue); // 將資料傳入 _approve()
        }

        return true;
    }


    // internal function (_transfer, _mint, _burn, _approve, _spendAllowance)

    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address"); // 若地址為 0 回傳錯誤訊息
        require(to != address(0), "ERC20: transfer to the zero address"); // 若地址為 0 回傳錯誤訊息

        uint256 fromBalance = _balances[from]; // 取得地址 from 的 balance
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance"); // 若 balance 小於 amount 回傳錯誤訊息
        unchecked {
            _balances[from] = fromBalance - amount; // 更新 from 地址傳送後的 balance 資料
        }
        _balances[to] += amount; // 更新 to 地址傳送後的 balance 資料

        emit Transfer(from, to, amount); // 用 Transfer 事件將傳送的資料寫到鏈上
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address"); // 若地址為 0 回傳錯誤訊息

        _totalSupply += amount; // 更新 totalSupply
        _balances[account] += amount; // 更新 account 地址 mint 後的 balance 資料
        emit Transfer(address(0), account, amount); // 用 Transfer 事件將 mint 的資料寫到鏈上
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address"); // 若地址為 0 回傳錯誤訊息

        uint256 accountBalance = _balances[account]; // 取得地址 account 的 balance 並設為 accountBalance
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance"); // 若 accountBalance 小於 amount 回傳錯誤訊息
        unchecked {
            _balances[account] = accountBalance - amount; // 更新 account 地址 burn 後的 balance 資料
        }
        _totalSupply -= amount; // 更新 totalSupply

        emit Transfer(account, address(0), amount); // 用 Transfer 事件將 burn 的資料寫到鏈上
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address"); // 若地址為 0 回傳錯誤訊息
        require(spender != address(0), "ERC20: approve to the zero address"); // 若地址為 0 回傳錯誤訊息

        _allowances[owner][spender] = amount; // 更新 owner 地址允許 spender 提取的 value
        emit Approval(owner, spender, amount); // 用 Approval 事件將 approve 的資料寫到鏈上
    }

    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender); // 使用 allowance() 取得 value 並設為 currentAllowance
        if (currentAllowance != type(uint256).max) { // 若 currentAllowance 不為 uint256 的最大值，執行 if 內的程式
            require(currentAllowance >= amount, "ERC20: insufficient allowance"); // 若 currentAllowance 小於 amount 回傳錯誤訊息
            unchecked {
                _approve(owner, spender, currentAllowance - amount); // 將資料傳入 _approve()
            }
        }
    }
}