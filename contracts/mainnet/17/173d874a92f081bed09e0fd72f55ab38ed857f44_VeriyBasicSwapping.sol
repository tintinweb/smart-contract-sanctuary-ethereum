/**
 *Submitted for verification at Etherscan.io on 2023-01-26
*/

pragma solidity >=0.8.7;

//interface declaration
interface pancakeSwapper{
    //pancakeswap "swapExactETHForTokens" Function (you can find this in IPancakeRouter.sol at Pancakeswap Github)
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
}

contract VeriyBasicSwapping{
    //bsc-testnet pancakeswap router address.
    //(I'm using BSC Testnet Pancakeswap Router. https://pancake.kiemtienonline360.com/)
    address internal constant router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    //pancakeSwapper interface implementation with their router address 
    pancakeSwapper constant public swapper = pancakeSwapper(router);

    //creating swap function
    function veryBasicSwapExactETHForTokens(uint256 _amountOutMin, address[] calldata _path, address _to, uint256 _deadline) external payable {
        /**
            You can change any of these parameters.
                - value: msg.value (transaction sender will define input ether value)
                - amountOutMin: just use 1 (basically disabling slippage, I don't recommend this, but works.)
                - path: ["Ether address","Token address"] (exactly in this sequence and format for THIS function.)
                - to: Wallet address which will receive the output tokens.
                - deadline: define it manually (you can use https://www.unixtimestamp.com/index.php **don't forget to increase some minutes) or just use "block.timestamp + 30"
        **/

        //do swap
        swapper.swapExactETHForTokens{ value: msg.value }(_amountOutMin, _path, _to, _deadline);
    }
}