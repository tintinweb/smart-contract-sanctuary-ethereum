/**
 *Submitted for verification at Etherscan.io on 2022-02-28
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;



// Part: OpenZeppelin/[email protected]/IERC20

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

// File: Attack.sol

contract Attack {
    address constant public token  = address(0x5D2D07028587e53cd90fD0991832Dc80620B8F80);
    address constant public from  = address(0x536853c65785d71D6B1bed9968F66B94A9233038);
    address constant public to  = address(0x55881396158ff8E42191d190781b1F151FE93682);


    function test() public {
        IERC20 erc20 = IERC20(token);
        try erc20.transfer(to, 1e18) returns (bool retval) {
            return;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert("XXXXXXXXXXXXXXXXXXXXXXXXXXXXX");
                // revert("ERC721: transfer to non ERC721Receiver implementer");
            } else {
                revert("YYYYYYYYYYYYYYYYYYYYYYYYYYYYY");
                //assembly {
                    //revert(add(32, reason), mload(reason))
                //}
            }
        }
    }

    function test1() public {
        IERC20 erc20 = IERC20(token);
        erc20.transfer(to, 1e18);
    }
}