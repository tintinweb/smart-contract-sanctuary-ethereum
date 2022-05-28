/**
 *Submitted for verification at Etherscan.io on 2022-05-28
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

library SafeTransfer {
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool s, ) = address(token).call(
            abi.encodeWithSelector(
                IERC20.transferFrom.selector,
                from,
                to,
                value
            )
        );
        require(s, "safeTransferFrom failed");
    }

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        (bool s, ) = address(token).call(
            abi.encodeWithSelector(IERC20.transfer.selector, to, value)
        );
        require(s, "safeTransfer failed");
    }

    function safeApprove(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        (bool s, ) = address(token).call(
            abi.encodeWithSelector(IERC20.approve.selector, to, value)
        );
        require(s, "safeApprove failed");
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool s, ) = to.call{value: value}(new bytes(0));
        require(s, "safeTransferETH failed");
    }
}



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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}




contract Sandwich {
    using SafeTransfer for IERC20;

    // Authorized
    address internal immutable user;

    // transfer(address,uint256)
    bytes4 internal constant ERC20_TRANSFER_ID = 0xa9059cbb;

    // swap(uint256,uint256,address,bytes)
    bytes4 internal constant PAIR_SWAP_ID = 0x022c0d9f;

    // Contructor sets the only user
    receive() external payable {}

    constructor(address _owner) {
        user = _owner;
    }

    // *** Receive profits from contract *** //
    function recoverERC20(address token) public {
        require(msg.sender == user, "shoo");
        IERC20(token).safeTransfer(
            msg.sender,
            IERC20(token).balanceOf(address(this))
        );
    }

    /*
        Fallback function where you do your frontslice and backslice

        NO UNCLE BLOCK PROTECTION IN PLACE, USE AT YOUR OWN RISK

        Payload structure (abi encodePacked)

        - token: address        - Address of the token you're swapping
        - pair: address         - Univ2 pair you're sandwiching on
        - amountIn: uint128     - Amount you're giving via swap
        - amountOut: uint128    - Amount you're receiving via swap
        - tokenOutNo: uint8     - Is the token you're giving token0 or token1? (On univ2 pair)

        Note: This fallback function generates some dangling bits
    */
    fallback() external payable {
        // Assembly cannot read immutable variables
        address memUser = user;

        assembly {
            // You can only access teh fallback function if you're authorized
            if iszero(eq(caller(), memUser)) {
                // Ohm (3, 3) makes your code more efficient
                // WGMI
                revert(3, 3)
            }

            // Extract out teh variables
            // We don't have function signatures sweet saving EVEN MORE GAS

            // bytes20
            let token := shr(96, calldataload(0x00))
            // bytes20
            let pair := shr(96, calldataload(0x14))
            // uint128
            let amountIn := shr(128, calldataload(0x28))
            // uint128
            let amountOut := shr(128, calldataload(0x38))
            // uint8
            let tokenOutNo := shr(248, calldataload(0x48))

            // **** calls token.transfer(pair, amountIn) ****

            // transfer function signature
            mstore(0x7c, ERC20_TRANSFER_ID)
            // destination
            mstore(0x80, pair)
            // amount
            mstore(0xa0, amountIn)

            let s1 := call(sub(gas(), 5000), token, 0, 0x7c, 0x44, 0, 0)
            if iszero(s1) {
                // WGMI
                revert(3, 3)
            }

            // ************
            /* 
                calls pair.swap(
                    tokenOutNo == 0 ? amountOut : 0,
                    tokenOutNo == 1 ? amountOut : 0,
                    address(this),
                    new bytes(0)
                )
            */

            // swap function signature
            mstore(0x7c, PAIR_SWAP_ID)
            // tokenOutNo == 0 ? ....
            switch tokenOutNo
            case 0 {
                mstore(0x80, amountOut)
                mstore(0xa0, 0)
            }
            case 1 {
                mstore(0x80, 0)
                mstore(0xa0, amountOut)
            }
            // address(this)
            mstore(0xc0, address())
            // empty bytes
            mstore(0xe0, 0x80)

            let s2 := call(sub(gas(), 5000), pair, 0, 0x7c, 0xa4, 0, 0)
            if iszero(s2) {
                revert(3, 3)
            }
        }
    }
}