/**
 *Submitted for verification at Etherscan.io on 2022-08-07
*/

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

pragma solidity ^0.8.7;

/*
Basic Loan allows user to borrow token for a fixed period of time using native asset
    *fee is constant and predefined. If not repaid lender keeps whole collateral
    * will be liquidated & transferred to lender
*/

contract BasicLoan {
    //variables
    address payable public lender;
    address payable public borrower;
    address public tokensAddress;

    //The struct contains the terms of our loan
    struct Terms {
        //Amount of token to be loaned
        uint256 loanedTokenAmount;
        //Amount of token to be repaid (loan amount + fee)
        uint256 feeTokenAmount;
        //The amount of collateral in the native asset
        //should be greater than the loanTokenAmount + feeToken at any time during loan
        //otherwise - borrower has an incentive to default for less
        uint256 nativeCollateralAmount;
        //Blocktime stap for when the loan should be repayed, after which lender can liquidate the collateral
        uint256 repaymentTime;
    }

    Terms public terms;

    //The loan can be in 5 states. Created, Fnded, Taken, Repayed, Liquidated
    //We only define three below because in the latter two states the contract will be destroyed
    enum StateOfLoan {Created, Funded, Taken}
    StateOfLoan public loanState;

   //Our modifier prevents some functions from being called in any other state than the provided one
   modifier onlyInState(StateOfLoan expectedState){
       require(loanState == expectedState, "Not allowed in this state");
       _;
   } 

   constructor(Terms memory _terms, address _tokensAddress){
       terms = _terms;
       tokensAddress = _tokensAddress;
       lender = payable(msg.sender);
       loanState = StateOfLoan.Created;
   }

    function fundLoan() public onlyInState(StateOfLoan.Created){
        //Transfer tokens from lender to contract, for use to borrowers
        //lender must allow contract beforehand otherwise will fail

        loanState = StateOfLoan.Funded;
        IERC20(tokensAddress).transferFrom(
            msg.sender,
            address(this),
            terms.loanedTokenAmount
        );

    }

    function takeOutLoan() public payable onlyInState(StateOfLoan.Funded){
        //check that exact amont of collateral is transferred. It will be kept in the contract until repayment or liquidation
        require(msg.value == terms.nativeCollateralAmount, "Invalid amount of collateral");

        //record borrower address so its only entitled to repayment and therfor unlock collateral
        borrower = payable(msg.sender);
        loanState = StateOfLoan.Taken;

        //Transfer the actual tokens that are being loaned
        IERC20(tokensAddress).transfer(borrower, terms.loanedTokenAmount);
    }

    //loan repayment it can be repayed early no fees. borrower should allow contract to pull the tokens before calling this
    function repayLoan() public onlyInState(StateOfLoan.Taken){
        //check that onyl borrower can repay preventing any one from paying and unlocking collateral
        require(msg.sender == borrower, "Only borrower can repay the loan");
        //Pull token both initial amount and the fee, if not enough sent it will fail
        IERC20(tokensAddress).transferFrom(borrower, lender, terms.loanedTokenAmount + terms.feeTokenAmount);

        //send the collateral back to the borrower and destroy the contract
        selfdestruct(borrower);

    }

    //This function is called be the lender in case of default payment
    //will transfer the whole colateral to the lender the collateral is expected to be more valuable that the loan
    //ensuring the lender doesnt loose any money in this case

    function liquidate()public onlyInState(StateOfLoan.Taken){
        require(msg.sender == lender, "Only the lender can liquidate the loan");
        require(block.timestamp >= terms.repaymentTime, "Cant liquidate before loan is due");

        //send the collateral to lender and destroy contract
        selfdestruct(lender);
    }








}