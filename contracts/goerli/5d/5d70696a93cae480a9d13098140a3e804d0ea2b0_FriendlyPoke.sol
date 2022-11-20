/**
 *Submitted for verification at Etherscan.io on 2022-11-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;



interface IFlashLoanReceiver {
    function executeOperation(address _reserve, uint256 _amount, uint256 _fee, bytes calldata _params) external;
}

interface IUnilendV2Core {
    function getFlashLoanFeesInBips() external view returns (uint256, uint256);    
    
    function getOraclePrice(address _token0, address _token1, uint _amount) external view returns(uint);
    

    function getPoolLTV(address _pool) external view returns (uint _ltv);

    function getPoolTokens(address _pool) external view returns (address, address);

    function getPoolByTokens(address _token0, address _token1) external view returns (address);
    
    
    function balanceOfUserToken0(address _pool, address _address) external view returns (uint _lendBalance0, uint _borrowBalance0);
    

    function balanceOfUserToken1(address _pool, address _address) external view returns (uint _lendBalance1, uint _borrowBalance1);
    
    function balanceOfUserTokens(address _pool, address _address) external view returns (uint _lendBalance0, uint _borrowBalance0, uint _lendBalance1, uint _borrowBalance1);
    
    
    function shareOfUserToken0(address _pool, address _address) external view returns (uint _lendShare0, uint _borrowShare0);

    function shareOfUserToken1(address _pool, address _address) external view returns (uint _lendShare1, uint _borrowShare1);
    

    function shareOfUserTokens(address _pool, address _address) external view returns (uint _lendShare0, uint _borrowShare0, uint _lendShare1, uint _borrowShare1);
    

    function getUserHealthFactor(address _pool, address _address) external view returns (uint _healthFactor0, uint _healthFactor1);


    function getPoolAvailableLiquidity(address _pool) external view returns (uint _token0Liquidity, uint _token1Liquidity);
    
 
    function flashLoan(address _receiver, address _pool, int _amount, bytes calldata _params) external;
    function lend(address _pool, int _amount) external  returns(uint mintedTokens);
    function redeem(address _pool, int _token_amount, address _receiver) external returns(int redeemTokens);
    function redeemUnderlying(address _pool, int _amount, address _receiver) external returns(int _token_amount);
    function borrow(address _pool, int _amount, uint _collateral_amount, address payable _recipient) external;  
    function repay(address _pool, int _amount, address _for) external returns (int _retAmount);      
}

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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


contract FriendlyPoke is IFlashLoanReceiver{
    address payable public core; 
    address payable public pool; 
    address public constant token1Contract = 0xC783F19c3ac1De293321725d0f92f15a411Da0a4;

    event log(bytes);

    constructor(address coreaddress, address pooladdr)
    {
        core = payable(coreaddress);
        pool = payable(pooladdr);

    }

   function executeOperation(address _reserve, uint256 _amount, uint256 _fee, bytes calldata _params) override external 
    {
        // flash loan 200,000
        

        //return the loan + f(ee
        bool result = IERC20(_reserve).transfer(pool, _amount+_fee); 
        require(result, "Fail to return the loan.");
        emit log(_params);
        
     

    }

    function MyFirstPoke() public {
        bytes memory _params = "nothing much";
    
        IUnilendV2Core(core).flashLoan(address(this), pool, 200000, _params);
        // IERC20(token1Contract).transfer(msg.sender, IERC20(token1Contract).balanceOf(address(this)));
    }

    function withdraw() public {
        IERC20(token1Contract).transfer(msg.sender,IERC20(token1Contract).balanceOf(address(this))); 
    }

}