/**
 *Submitted for verification at Etherscan.io on 2022-12-23
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

// File: contracts/AscendantMoneyTransfer.sol

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;




contract MoneyTransfer {

    address private owner;


    constructor(){
        owner = msg.sender;
    }


    function tokenTransfer(address _payToken, address[] calldata _wallets, uint256[] calldata _amounts) external {
        require(msg.sender == owner, "Not authorized");
        IERC20 payToken = IERC20(_payToken);
        for(uint8 i = 0; i < _wallets.length; i++) {
            payToken.transferFrom(msg.sender, _wallets[i], _amounts[i]);
        }
    }

    function EthTransfer(address[] calldata _wallets, uint256[] calldata _amounts) external {
        require(msg.sender == owner, "Not authorized");
        for(uint8 i = 0; i < _wallets.length; i++) {
            payable(_wallets[i]).transfer(_amounts[i]);
        }

    }

    function emergencyTokenWithdraw(address _token) external {
        require(msg.sender == owner, "Not authorized to withdraw tokens");
        IERC20 token = IERC20(_token);
        uint256 balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance );
    }

    function emergencyWithdraw() external {
        require(msg.sender == owner, "Not authorized to withdraw tokens");
        // This will payout the owner the contract balance.
        // Do not remove this otherwise you will not be able to withdraw the funds.
        // =============================================================================
        (bool os, ) = payable(owner).call{value: address(this).balance}("");
        require(os);
        // =============================================================================
    }

     receive() external payable {}
    



}