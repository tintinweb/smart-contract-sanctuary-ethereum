pragma solidity ^0.8.10;

import "IERC20.sol";

interface IUniswapV2Pair {    
    function token0() external view returns(address);
    function token1() external view returns(address);
    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;
}

interface IUniswapV2Callee {    
    function uniswapV2Call(address sender, uint256 amount0, uint256 amount1, bytes calldata data) external;  
}

contract ArbContract is IUniswapV2Callee {
    address immutable OWNER;
    address borrow_pool_address;
    uint256[2] borrow_amounts;
    address swap_pool_address;
    uint256[2] swap_out_amounts;
    uint256 repay_amount;

    constructor() {         
        OWNER = msg.sender;        
    }

    function _cleanup() internal {
        borrow_pool_address = address(0);
        borrow_amounts = [0,0];
        swap_pool_address = address(0);
        swap_out_amounts = [0,0];
        repay_amount = 0;
    }
    
    function flash_borrow_to_swap (
        address _borrow_pool_address,
        uint256[2] memory _borrow_amounts,
        address _swap_pool_address,
        uint256[2] memory _swap_out_amounts,
        uint256 _repay_amount
    ) external {
        require(msg.sender == OWNER, "msg.sender is !OWNER");

        borrow_pool_address = _borrow_pool_address;
        borrow_amounts = _borrow_amounts;
        swap_pool_address = _swap_pool_address;
        swap_out_amounts = _swap_out_amounts;
        repay_amount = _repay_amount;
        
        //this swap will trigger uniswapV2Call
        IUniswapV2Pair(borrow_pool_address).swap(borrow_amounts[0],borrow_amounts[1], address(this), bytes("x"));
    }

    function uniswapV2Call (address ,uint256 _amount0, uint256 _amount1, bytes calldata) external {
        //this is where we execute flash loan + swap

        // ensure msg.sender is borrow_pool as part of flash loan and swap, as intended 
        require(msg.sender == borrow_pool_address, "!LP");
        
        address _token0_address = IUniswapV2Pair(msg.sender).token0();
        address _token1_address = IUniswapV2Pair(msg.sender).token1();

        //transfer the borrow amounts to swap pool
        if (_amount0 == 0) {
            IERC20(_token1_address).transfer(swap_pool_address,_amount1);
        }
        
        else if (_amount1 == 0) {
            IERC20(_token0_address).transfer(swap_pool_address,_amount0);
        }
            
        IUniswapV2Pair(swap_pool_address).swap(swap_out_amounts[0],swap_out_amounts[1], address(this), bytes(""));

        //if borrowed token1, repay in token0 (and vice versa)
        if (_amount0 == 0) {
            IERC20(_token0_address).transfer(msg.sender, repay_amount);
        }    
        else if (_amount1 == 0) {
            IERC20(_token1_address).transfer(msg.sender, repay_amount);
        }        
        _cleanup();
    }
    
    function withdrawTokenToOwner(address withdraw_token, uint256 amt) external {
        require(msg.sender == OWNER, "address must be OWNER");
        IERC20(withdraw_token).transfer(OWNER, amt);
    }

}

// SPDX-License-Identifier: MIT
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