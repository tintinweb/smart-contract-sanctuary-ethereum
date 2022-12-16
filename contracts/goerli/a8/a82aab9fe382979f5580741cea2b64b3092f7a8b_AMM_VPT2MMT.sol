/**
 *Submitted for verification at Etherscan.io on 2022-12-16
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

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




contract AMM_VPT2MMT {
    //storage variables - defined on top
    address token1;
    address token2;


    uint public reserve1;
    uint public reserve2;

    constructor(){
        token1 = 0x77B829a682Ed71EF6D99F2Eec0B373770A64b519;//vptAddress on Goerli
        token2 = 0xc80E2d87C1Be040bf66557195d4CE8E194eEb14A;//mmtAddress on Goerli


    }

    function swap(address from, address to, uint amount) external {
        uint x = IERC20(token1).balanceOf(address(this));
        uint y = IERC20(token2).balanceOf(address(this));
        uint dy;

        dy = y*amount / ( x + amount);

        IERC20(from).transferFrom(msg.sender, address(this), amount);
        IERC20(to).transfer(msg.sender, dy);        
    }

    function swapVPT2MMT(uint amount) external {
        uint x = IERC20(token1).balanceOf(address(this));
        uint y = IERC20(token2).balanceOf(address(this));
        uint dy;

        dy = y*amount / ( x + amount);

        IERC20(token1).transferFrom(msg.sender, address(this), amount);
        IERC20(token2).transfer(msg.sender, dy);        
    }

 
        function swapMMT2VPT(uint amount) external {
        uint x = IERC20(token1).balanceOf(address(this));
        uint y = IERC20(token2).balanceOf(address(this));
        uint dx;

        dx = x*amount / ( y + amount);

        IERC20(token2).transferFrom(msg.sender, address(this), amount);
        IERC20(token1).transfer(msg.sender, dx);        
    }




    function addLiquidity(uint amount1, uint amount2) external {
        
        uint x = IERC20(token1).balanceOf(address(this));
        uint y = IERC20(token2).balanceOf(address(this));

        if (x > 0 && y > 0 ){
            //in oreder price to stay the same
            require(x*amount2 == y*amount1, "Invalid amounts");
        }

        //transfer token A inside
        IERC20(token1).transferFrom(msg.sender, address(this), amount1);
        //transfer token B insade
        IERC20(token2).transferFrom(msg.sender, address(this), amount2);
        //minting - not implemented since only owner can add liquiduty
    }

    function removeLiquidity(uint amount1, uint amount2) external {
        //burning of LP tokens - LP tokens not implemented for simplicity
        
        uint x = IERC20(token1).balanceOf(address(this));
        uint y = IERC20(token2).balanceOf(address(this));

        if (((x - amount1) > 0) && ((y - amount2) > 0 )){
            //in order price to stay the same after removal of liquidity
            require((x-amount1)*amount2 == (y-amount2)*amount1, "Invalid amounts");

            //transfer token A inside
            IERC20(token1).transfer(msg.sender, amount1);        
            //transfer token B insade
            IERC20(token2).transfer(msg.sender, amount2);        
            //minting - not implemented for simpicity
        }

    }

}