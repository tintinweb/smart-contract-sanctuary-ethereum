//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20/ERC20.sol";

contract XXXToken is ERC20 {
    constructor() ERC20("XXX Coin", "XXX", 18){}   
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./InterfaceERC20.sol";

contract ERC20 is InterfaceERC20 {
    address private owner;
    mapping(address => uint256) private _balances;
    mapping(address => bool) private isAdmin;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint8 private _decimals; // 1 token = 1 wei
    string private _name;
    string private _symbol;
    uint256 private _totalTokens;

    modifier enoughTokens(address from, uint256 value){
        require(balanceOf(from) >= value, "not enough tokens");
        _;
    }

    modifier onlyOwner(){
        require(msg.sender == owner, "not an owner");
        _;
    }

    modifier onlyAdmin() {
        require(isAdmin[msg.sender], "not an admin");
        _;
    }
    

    constructor(string memory name_, string memory symbol_, uint8 decimals_){
        require(decimals_ >= 1 && decimals_ <= 18, "wrong decomals");
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        owner = msg.sender;
        isAdmin[msg.sender] = true;
    }

    function giveAdminRole(address newAdmin) override external onlyOwner{
        isAdmin[newAdmin] = true;
    }

    function name() override public view returns(string memory){
        return _name;
    }
    function symbol() override public view returns(string memory){
        return _symbol;
    }
    function decimals() override public view returns(uint8){
        return _decimals;
    }
    function totalSupply() override public view returns(uint256){
        return _totalTokens;
    }

    function balanceOf(address ownerTokens) override public view returns(uint256){
        return _balances[ownerTokens];
    }
    function allowance(address ownerTokens, address spender) override public view returns(uint256){
        return _allowances[ownerTokens][spender];
    }

    function transfer(address to, uint256 value) override public enoughTokens(msg.sender, value) returns(bool){
        _balances[msg.sender] -= value;
        _balances[to] += value;
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) override public enoughTokens(from, value)  returns(bool){
        require(allowance(from, to) >= value, "not allowed");
        _balances[from] -= value;
        _balances[to] += value;
        emit Transfer(from, to, value);
        return true;
    }

    function approve(address spender, uint256 value) override public returns(bool){
        _allowances[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function burn(address account, uint256 amount) override public onlyAdmin{
        _balances[account] -= amount;
        _totalTokens -= amount;
    }

    function mint(address account, uint256 amount) override public onlyAdmin{
        _balances[account] += amount;
        _totalTokens += amount;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface InterfaceERC20 is IERC20 {
    function giveAdminRole(address newAdmin) external;
    function name() external view returns(string memory);
    function symbol() external view returns(string memory);
    function decimals() external view returns(uint8);

    function burn(address account, uint256 amount) external;
    function mint(address account, uint256 amount) external;
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