/**
 *Submitted for verification at Etherscan.io on 2022-12-17
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

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

interface iPool {
    function addLiquidity(uint256[] calldata, uint256, uint256) external returns (uint256);
}

contract Broken {

    error INVALID_ADDRESS(address addr);
    error NOT_AUTHORIZED(address _addr);
    error INVALID_SIZES();
    error FAIL_WITHDRAW(address ercAddr, uint256 amount);

    event BalanceWithdraw(address ercAddr, uint256 amount);
    event DONE(address addr);

    address public owner;

    constructor(address _owner) payable{
        owner = _owner;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert NOT_AUTHORIZED(msg.sender);
        _;
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    function execute(
        uint256[] memory _amounts,
        address _pool_address,
        address[] memory _tokens) external onlyOwner
    {
        // Check if pool and lp_token is valid
        if (_pool_address == address(0)) revert INVALID_ADDRESS(_pool_address);
        if (_tokens.length != _amounts.length) revert INVALID_SIZES();


        // Approve tokens to pool
        for (uint i = 0; i < _tokens.length; i++) {
            IERC20 token = IERC20(_tokens[i]);
            if (_amounts[i] > 0) {
                token.approve(_pool_address, _amounts[i]);
            }
        }

        iPool poolContract = iPool(_pool_address);

        poolContract.addLiquidity(_amounts, 0, 0);

        emit DONE(_pool_address);
    }

    function self_destroy() external onlyOwner
    {
        selfdestruct(payable(owner));
    }

    function withdrawToken(address _token_address) external onlyOwner
    {
        IERC20 token = IERC20(_token_address);
        uint256 balance = token.balanceOf(address(this));
        bool success = token.transfer(owner, balance);
        if (!success) revert FAIL_WITHDRAW(_token_address, balance);
        emit BalanceWithdraw(_token_address, balance);
    }

    receive() external payable {}

    fallback() external payable {}
}