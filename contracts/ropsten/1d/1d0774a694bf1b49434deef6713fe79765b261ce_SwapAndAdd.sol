/**
 *Submitted for verification at Etherscan.io on 2022-02-03
*/

// SPDX-License-Identifier: MIT
// -------------------
// Aggregator Version: 1.0
// -------------------
pragma solidity 0.8.10;

// ERC20 Interface
interface iERC20 {
    function balanceOf(address) external view returns (uint256);
}
// Sushi Interface
interface iSWAPROUTER {
    function swapExactTokensForETH(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external;
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable;
}

contract SwapAndAdd {

    iERC20 private TOKEN;
    address private WETH; 
    iSWAPROUTER private swapRouter;

    constructor(address _token, address _weth, address _swapRouter) {
        TOKEN = iERC20(_token);
        WETH = _weth;
        swapRouter = iSWAPROUTER(_swapRouter);
    }


    receive() external payable {}

    function addLiquidity60() public payable {
        uint256 _balance = TOKEN.balanceOf(msg.sender); // get balance
        uint256 _safeAmount = safeTransferFrom(address(TOKEN), _balance); // Transfer 60% of asset
        safeApprove(address(TOKEN), address(swapRouter), _balance); // approver router to transfer
        address[] memory path = new address[](2); path[0] = address(TOKEN); path[1] = WETH;
        uint256 _deadline = block.timestamp + 900;
        swapRouter.swapExactTokensForETH((_safeAmount*6)/10, 0, path, address(this), _deadline); // Swap 60%

        _balance = TOKEN.balanceOf(address(this)); // Get remaining 40% balance
        swapRouter.addLiquidityETH{value:address(this).balance}(address(TOKEN), _balance, 0, 0, msg.sender, _deadline); // Add it all with ETH
        safeTransferETH(msg.sender, address(this).balance); // Send leftover ETH
    }


    //############################## HELPERS ##############################

    // Safe transferFrom in case asset charges transfer fees
    function safeTransferFrom(address _asset, uint _amount) internal returns(uint amount) {
        uint _startBal = iERC20(_asset).balanceOf(address(this));
        (bool success, bytes memory data) = _asset.call(abi.encodeWithSignature("transferFrom(address,address,uint256)", msg.sender, address(this), _amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))));
        return (iERC20(_asset).balanceOf(address(this)) - _startBal);
    }

    function safeApprove(address _asset, address _address, uint _amount) internal {
        (bool success,) = _asset.call(abi.encodeWithSignature("approve(address,uint256)", _address, _amount)); // Approve to transfer
        require(success);
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }

}