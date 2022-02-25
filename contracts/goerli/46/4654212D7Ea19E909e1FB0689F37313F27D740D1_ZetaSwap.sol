/**
 *Submitted for verification at Etherscan.io on 2022-02-25
*/

// File: contracts/swap.sol

pragma solidity ^0.8.4;

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);
}

interface IUniswapV2Router {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

interface ZetaMPI {
    function zetaMessageSend(uint16 destChainID, bytes calldata  destContract, uint zetaAmount, uint gasLimit, bytes calldata message, bytes calldata zetaParams) external;
}

interface ZetaMPIReceiver {
	function uponZetaMessage(bytes calldata sender, uint16 srcChainID, address destContract, uint zetaAmount, bytes calldata message) external; 
}


contract ZetaSwap  {
    address public ZETA_MPI_ADDRESS; 
    address public ZETA_TOKEN; 
    address public UNISWAP_V2_ROUTER; 
    constructor(address _zeta_mpi_address, address _zeta_token, address _uniswap_v2_router) {
        ZETA_MPI_ADDRESS = _zeta_mpi_address; 
        ZETA_TOKEN = _zeta_token; 
        UNISWAP_V2_ROUTER = _uniswap_v2_router; 
    }

    function xcSwap(address _tokenIn, address _tokenOut, uint _amountIn, uint _amountOutMin, address _toAddress, uint16 _toChain, bytes calldata _destContract, uint _gasLimit) external {
        IERC20(_tokenIn).transferFrom(msg.sender, address(this), _amountIn); 
        IERC20(_tokenIn).approve(UNISWAP_V2_ROUTER, _amountIn); 

        address[] memory path; 
        path = new address[](2);
        path[0] = _tokenIn;
        path[1] = ZETA_TOKEN; 

        uint[] memory amounts = IUniswapV2Router(UNISWAP_V2_ROUTER).swapExactTokensForTokens(_amountIn, _amountOutMin, path, address(this), block.timestamp);
        bytes memory message = abi.encode(_tokenOut, _toAddress, _amountOutMin);
        require(amounts[1] > 0, "zero output swap");

        IERC20(ZETA_TOKEN).approve(ZETA_MPI_ADDRESS, amounts[1]);
        uint bal = IERC20(ZETA_TOKEN).balanceOf(ZETA_MPI_ADDRESS);
        //function zetaMessageSend(uint16 destChainID, bytes calldata  destContract, uint zetaAmount, uint gasLimit, bytes calldata message, bytes calldata zetaParams) external {
        uint8 conf = 12; 
        bytes memory zetaParams =  abi.encode(conf);
        ZetaMPI(ZETA_MPI_ADDRESS).zetaMessageSend(_toChain,  _destContract, amounts[1], _gasLimit, message, zetaParams);
    }
	function uponZetaMessage(bytes calldata sender, uint16 srcChainID, address destContract, uint zetaAmount, bytes calldata message) external { 
        (address tokenOut, address toAddress, uint256 amountOutMin) = abi.decode(message, (address, address, uint256));
        
        address[] memory path; 
        path = new address[](2);

        path[0] = ZETA_TOKEN;
        path[1] = tokenOut; 
        IERC20(ZETA_TOKEN).approve(UNISWAP_V2_ROUTER, zetaAmount); 
        uint[] memory amounts = IUniswapV2Router(UNISWAP_V2_ROUTER).swapExactTokensForTokens(zetaAmount, amountOutMin, path, toAddress, block.timestamp);
    }
}