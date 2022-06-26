/**
 *Submitted for verification at Etherscan.io on 2022-06-26
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8;

interface IERC20PermitEverywhere {
    struct PermitTransferFrom {
        IERC20 token;
        address spender;
        uint256 maxAmount;
        uint256 deadline;
    }

    struct Signature {
        bytes32 r;
        bytes32 s;
        uint8 v;
    }

    function executePermitTransferFrom(
        address owner,
        address to,
        uint256 amount,
        PermitTransferFrom memory permit,
        Signature memory sig
    )
        external;
}

interface IERC20 {
    function balanceOf(address owner) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address owner, address to, uint256 amount) external returns (bool);
}

interface IUniswapV2Router {
    function swapExactTokensForETH(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline)
        external
        returns (uint256[] memory amounts);
}

contract TestUni2Router {
    IUniswapV2Router public immutable ROUTER;
    IERC20PermitEverywhere public immutable PERMIT_EVERYWHERE;

    constructor(IUniswapV2Router router, IERC20PermitEverywhere pe) {
        ROUTER = router;
        PERMIT_EVERYWHERE = pe;
    }

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address payable to,
        uint256 deadline,
        IERC20PermitEverywhere.PermitTransferFrom memory permit,
        IERC20PermitEverywhere.Signature memory permitSig
    )
        external
        returns (uint256[] memory amounts)
    {
        require(path[0] == address(permit.token), 'WRONG_PERMIT_TOKEN');
        PERMIT_EVERYWHERE.executePermitTransferFrom(
            msg.sender,
            address(this),
            amountIn,
            permit,
            permitSig
        );
        permit.token.approve(address(ROUTER), type(uint256).max);
        amounts = ROUTER.swapExactTokensForETH(
            amountIn,
            amountOutMin,
            path,
            to,
            deadline
        );
    }
}