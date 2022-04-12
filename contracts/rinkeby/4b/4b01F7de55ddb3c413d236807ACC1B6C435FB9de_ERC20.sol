/**
 *Submitted for verification at Etherscan.io on 2022-04-12
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;



// Part: OpenZeppelin/[email protected]/IERC20

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

// File: ERC20.sol

contract ERC20 is IERC20 {
    uint256 public totalSupply;
    mapping(address=>uint256) public balanceOf; //account's erc20 token balance
    mapping(address=>mapping(address=>uint256)) public allowance; // owner -> spender -> allowance (ie how much the account owner allows spender to spend on his/her behalf)
    string public name;
    string public symbol;
    uint8 public decimals;
    address immutable owner;

    // addtional implementation
    constructor (
        string memory _name,
        string memory _symbol,
        uint256 _totalSupply,
        uint8 _decimal) {
            name = _name;
            symbol = _symbol;
            owner = msg.sender;
            totalSupply = _totalSupply;
            decimals = _decimal;
            balanceOf[msg.sender] += _totalSupply;
            emit Transfer(address(0), msg.sender, _totalSupply);
        }

    // _transfer is shared login for tranfer and transferFrom
    function _transfer(address _from, address _to, uint256 _amount) internal {
        require(balanceOf[_from] >= _amount, 'Not enough fund!');
        balanceOf[_from] -= _amount;
        balanceOf[_to] += _amount;
        emit Transfer(_from, _to, _amount);
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        require(balanceOf[msg.sender] >= amount, 'Not enough fund!');
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool) {
        require(allowance[from][msg.sender] >= amount, 'Not enough approved fund!');
        allowance[from][msg.sender] -= amount;
        _transfer(from, to, amount);
        return true;
    }
    
    // addtional implementation
    // only owner can mint contract
    function _mint(address account, uint256 amount) internal {
        require(msg.sender == owner, 'only owner can mint coins');
        require(account != address(0), 'cannot mint to zero address');
        balanceOf[account] += amount;
        totalSupply += amount;
        emit Transfer(address(0), msg.sender, amount);
    }

/*
The following events do not need to define in contract, as they are already defined in IERC20:

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

These functions are automatically implemented when we declare state variables public:

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
*/

}