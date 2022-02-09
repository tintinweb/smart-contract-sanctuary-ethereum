/**
 *Submitted for verification at Etherscan.io on 2022-02-08
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapETHForExactTokens(
        uint amountOut,
        address[] calldata path,
        address to,
        uint deadline
    )external payable returns (uint[] memory amounts);

    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );
}

 contract alfaBuyer {

     IUniswapV2Router02 private uniswapV2Router;

     bool private payByContract = true;
     address private _owner;

     modifier onlyOwner {
         require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
     }

     constructor() {
         uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
         _owner = msg.sender;
     }

    function togglePayType() public {
        if(payByContract){
            payByContract = false;
        }else{
            payByContract = true;
        }
    }

    function getPaymentMethod() public view returns (bool) {
        return payByContract;
    }

    function withdrawBalance(address payable _wallet) public onlyOwner {
        uint256 balance = address(this).balance;

        if(balance > 0){
            _wallet.transfer(balance);
        }
    }

    function buyToken(address _tokAddress, address[] memory wallets, uint256 _tokenAmount) payable public onlyOwner returns(bool) {
        address[] memory path = new address[](2);
        
        path[0] = uniswapV2Router.WETH();
        path[1] = _tokAddress;

        uint256 balance;

        if(payByContract){
            balance = address(this).balance;
        }else{
            balance = msg.value;
        }

        for(uint8 _counter; _counter < wallets.length; _counter++){

            uniswapV2Router.swapETHForExactTokens{value: balance}(
                _tokenAmount,
                path,
                wallets[_counter],
                block.timestamp
            );
            

        }

        return true;
    }

    receive() external payable {}
    

 }