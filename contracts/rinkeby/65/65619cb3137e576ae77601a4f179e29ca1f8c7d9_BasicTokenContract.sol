/**
 *Submitted for verification at Etherscan.io on 2022-05-03
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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

// File: contracts/TokenHolder.sol




pragma solidity ^0.8.0;


contract BasicTokenContract {
    address public owner;
    string public description;
    
        constructor() {
            initialize(address(0x4A87783c5A90268fC86d1beBA7C0b29d599Db29b), "Test Holder");
        }
    
    function initialize(address _owner, string memory _description) public {
        require(owner == address(0), "initialized outside of proxy call");
        //require(msg.sender == owner, "not owner");
        owner = _owner;
        description = _description;
    }
    
    
        function sweepTo(IERC20 token, uint256 amount, address target) public
    {
        require(msg.sender == owner, "Not owner");
        //uint256 amount = token.balanceOf(address(this));
        require(amount > 0, "Nothing to sweep");
        require(token.balanceOf(address(this)) >= amount, "Not enough balance!");
        token.transfer(target, amount);
    }
    
        function withdrawTo(address target) public
    {
        require(msg.sender == owner, "Not owner");
        require(address(this).balance > 0, "Nothing to withdraw");
        payable(target).transfer(address(this).balance);
    }

    function transferOwnership(address newOwner) public
    {
        require(msg.sender == owner, "Not owner");
        owner = newOwner;
    }

    function updateDescription(string memory newDescription) public
    {
        require(msg.sender == owner, "Not owner");
        description = newDescription;
    }
    
    receive() external payable {}
    
}