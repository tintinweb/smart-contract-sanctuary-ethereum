/**
 *Submitted for verification at Etherscan.io on 2022-09-19
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: contracts/myToken.sol




pragma solidity ^0.8.9;

contract MyToken is IERC20 {
    uint256 public totalSupply;
    address public owner;

    mapping(address => uint256) balances_;
    mapping(address => mapping (address => uint256)) allowances_;


    constructor(uint256 totalSupply_) {
        totalSupply = totalSupply_;
        owner = msg.sender;
        balances_[owner] = totalSupply;
    }

    function changeOwner(address newOwner) public {
        if (msg.sender == owner) {
            owner = newOwner;
        }
    }

    function changeOwnerWithError(address newOwner) public {
        require(msg.sender == owner, "Not the owner");
        owner = newOwner;
    }

    function balanceOf(address account)
        external
        view
        override
        returns (uint256)
    {
        return balances_[account];
    }

    function transfer(address to, uint256 amount)
        external
        override
        returns (bool)
    {
        require(balances_[msg.sender] >= amount, "No money");
        balances_[msg.sender] -= amount;
        balances_[to] += amount;

        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function allowance(address owner, address spender)
        external
        view
        override
        returns (uint256)
    {
        return allowances_[owner][spender];   
    }

    function approve(address spender, uint256 amount)
        external
        override
        returns (bool)
    {
        allowances_[msg.sender][spender] = amount;
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external override returns (bool) {
        require(balances_[from] >= amount, "No money");
        require(allowances_[from][msg.sender] >= amount, "No approve");
        balances_[from] -= amount;
        balances_[to] += amount;
        allowances_[from][msg.sender] -= amount;
        return true;
    }
}