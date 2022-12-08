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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Token is IERC20 {
    mapping(address => uint) private _balances;
    mapping(address => mapping(address => uint)) private _allowances;

    address payable private _owner;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;

    constructor(uint256 initialSupply) {
        _owner = payable(msg.sender);
        _balances[msg.sender] = initialSupply;
        _totalSupply = initialSupply;
        _name = "BuyCoin";
        _symbol = "BUY";
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function allowance(address owner_, address spender) public view returns (uint256) {
        return _allowances[owner_][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        emit Approval(msg.sender, spender, amount);
        _allowances[msg.sender][spender] = amount;
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        require(_allowances[from][msg.sender] >= amount, "Insufficient allowance");
        _transfer(from, to, amount);
        _allowances[from][msg.sender] -= amount;
        return true;
    }

    function buy() public payable {
        require(msg.value == 1 ether, "Must send exactly 1 ether");
        uint256 tokensToMint = msg.value * 1000;
        uint256 nextTotalSupply = _totalSupply + tokensToMint;
        require(nextTotalSupply <= 1000000 ether, "Total token supply cannot exceed 1 million");
        _totalSupply = nextTotalSupply;
        _mint(msg.sender, tokensToMint);
    }

    function withdraw() public {
        require(msg.sender == _owner, "Only owner can withdraw ether");
        uint256 amount = address(this).balance;
        _owner.transfer(amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(_balances[from] >= amount, "Insufficient funds");
        emit Transfer(from, to, amount);
        _balances[from] -= amount;
        _balances[to] += amount;
    }

    function _mint(address to, uint256 amount) private {
        emit Transfer(0x0000000000000000000000000000000000000000, to, amount);
        _balances[to] += amount;
    }
}