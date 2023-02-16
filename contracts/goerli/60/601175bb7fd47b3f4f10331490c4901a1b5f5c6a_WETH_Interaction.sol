/**
 *Submitted for verification at Etherscan.io on 2023-02-16
*/

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

contract WETH_Interaction {


    address wethAddress; //WETH address
    IERC20_WETH wethInterface; //WETH interface

    address operator; //The vault's operator
    address newOperator; //A variable used for safer transitioning between vault operators


    constructor() {

        operator = msg.sender;

        wethAddress = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6;//set this to be the vault's asset address
        wethInterface = IERC20_WETH(wethAddress); //this initializes an interface with the asset 
    }

    /*////// Operator functions and modifiers ///// */

    modifier onlyOperator() {
        require(msg.sender == operator, "You aren't the operator.");
        _;
    }

    /*////// Operator functions ///// */

    function displayBalance() public view returns(uint256){
        return wethInterface.balanceOf(address(this));
    }


    function deposit() public payable onlyOperator {
        //Pay 0 into this?
        wethInterface.deposit{value: address(this).balance};
    }

    function withdraw(uint256 amt) public onlyOperator {

        wethInterface.approve(wethAddress, amt);//Approve the WETH contract to approve this balance

        wethInterface.withdraw(amt); //Unwrap assets - WETH into ETH - 
        //The asset from the vault is WETH...so we call withdraw on the asset Interface to get raw ETH
    }


    /*/////////// END Vault Executions  //////////////*/

   //Need for a fallback function regarding ETH deposits??

}


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20_WETH {
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

    //I am so sorry Transmissions11 but I need this interface specifically for WETH...forgive me father
    
    //WETH Deposit function
    //Had this as external and not public - fixed?
    function deposit() external payable ;

    //WETH Withdraw function
    //I had this as uint256 instead of uint
    //I also had it as external and not public - fixed?
    function withdraw(uint amt) external ; 

}