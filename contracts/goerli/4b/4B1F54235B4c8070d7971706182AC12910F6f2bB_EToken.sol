// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "IERC20.sol";

contract EToken is IERC20 {
    // event Transfer(address indexed from, address indexed to, uint256 value);
    // event Approval(
    //     address indexed owner,
    //     address indexed spender,
    //     uint256 value
    // );
    uint256 public _totalSupply;
    uint256 public constant MAX_SUPPLY = 878000;
    bool public allow;
    string public name_;
    string public symbol_;
    error MaxSupplyMet();

    mapping(address => mapping(address => uint256)) private _allowance;
    mapping(address => mapping(address => bool)) internal _setApprovalForAll;
    mapping(address => uint256) public _balanceOf;

    constructor(string memory _name, string memory _symbol) {
        name_ = _name;
        symbol_ = _symbol;
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function getName() external view returns (string memory) {
        return name_;
    }

    function getSymbol() external view returns (string memory) {
        return symbol_;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balanceOf[account];
    }

    function allowance(address owner, address spender)
        external
        view
        returns (uint256)
    {
        return _allowance[owner][spender];
    }

    function _increaseAllowance(address spender, uint256 _amount)
        internal
        returns (bool)
    {
        require(_balanceOf[msg.sender] >= _amount, "allowance > balance");
        _allowance[msg.sender][spender] += _amount;
        allow = true;
        return allow;
    }

    function _decreaseAllowance(address spender, uint256 _amount) internal {
        uint256 allowance_ = _allowance[msg.sender][spender];
        require(allow, "no allowance");
        require(allowance_ >= _amount, "amount too high");
        if (allowance_ == _amount) {
            allow = false;
        }
        _allowance[msg.sender][spender] -= _amount;
    }

    function resetAllowance(address spender) external {
        require(allow, "no allwance");
        _allowance[msg.sender][spender] = 0;
    }

    function setApprovalForAll(address operator, bool setting) external {
        // setting represents true (if you want to set approval) or
        // false (if you want to remove existing approval)
        if (setting == true) {
            allow = true;
        } else {
            allow = false;
        }
        _setApprovalForAll[msg.sender][operator] = setting;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        _increaseAllowance(spender, amount);
    }

    function decreaseApprovalAmount(address spender, uint256 amount)
        external
        returns (bool)
    {
        _decreaseAllowance(spender, amount);
        return true;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        _balanceOf[msg.sender] -= amount;
        _balanceOf[to] += amount;
        // emit Transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool) {
        require(
            _allowance[msg.sender][to] >= amount ||
                _setApprovalForAll[from][msg.sender],
            "allowance < amount"
        );
        _allowance[msg.sender][to] -= amount;
        _balanceOf[from] -= amount;
        _balanceOf[to] += amount;
        // emit Transfer(from, to, amount);
        return true;
    }

    function mint(address receiver, uint256 amount) external {
        require(receiver != address(0), "0 address error");
        uint256 x = _totalSupply + amount;
        if (x >= MAX_SUPPLY) {
            amount = x - MAX_SUPPLY;
            if (amount == MAX_SUPPLY) {
                revert MaxSupplyMet();
            }
        }
        _totalSupply += amount;
        _balanceOf[receiver] += amount;
    }

    function burn(uint256 amount) external {
        _totalSupply -= amount;
        _balanceOf[msg.sender] -= amount;
    }
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