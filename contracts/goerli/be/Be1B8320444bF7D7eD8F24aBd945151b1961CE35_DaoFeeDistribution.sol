/**
 *Submitted for verification at Etherscan.io on 2023-02-14
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool); 
} 



// This contract can recieve ETH (directy)
// and any erc20 token (should have been approved by user)  
// and send 30% of the amount to two wallets (15% to each)

contract DaoFeeDistribution {

    address public owner;
    address payable public managementWallet; 
    address payable public  treasuryWallet;
       
    // the contract deployer will be the owner
    // and he can define the two wallets
    // and only he can change these wallets
    constructor (address payable _wallet1, address payable _wallet2) {

        owner = msg.sender;             
        managementWallet = _wallet1;
        treasuryWallet = _wallet2;

    }

    // only the owner can change the wallets later
    function setDaoWallets (address payable _managementWallet, address payable _treasuryWallet) public {
        
        require (msg.sender==owner, "only the contract owner can do this!");
        managementWallet = _managementWallet;
        treasuryWallet = _treasuryWallet;        
    }

    // receiving ETH and sending it to two wallets
    receive() payable external {

        uint256 _15percent = (msg.value)*15/100;               

        (bool succuss1, )= managementWallet.call{value: _15percent}("");
        (bool succuss2, )= treasuryWallet.call{value: _15percent}("");
        require(succuss1 && succuss2, "ETH Transfer failed!");
              
    }     

    // receiving an erc20 token from a user
    // the SC should be approved by the user on token address   
    function depositERC20token (address _sender, IERC20 _token, uint256 _amount) public {
             
        require (
                        
            _token.allowance(_sender, address(this)) >= _amount &&
            _token.balanceOf(_sender) >= _amount,
             "this amount hasn't been approved by you or you don't have enough funds"
        );

        _token.transferFrom(_sender, address(this), _amount*70/100);
        _token.transferFrom(_sender, managementWallet, _amount*15/100);
        _token.transferFrom(_sender, treasuryWallet, _amount*15/100);      
              
    } 
    
}