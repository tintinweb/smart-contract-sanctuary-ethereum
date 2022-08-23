/**
 *Submitted for verification at Etherscan.io on 2022-08-23
*/

/**
 *Submitted for verification at Etherscan.io on 2022-08-23
*/

pragma solidity ^0.8;
/*------------------------------------导入头------------------------------------*/
interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function deposit() external payable;

    function transfer(address to, uint value) external returns (bool);

    function withdraw(uint) external;

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint);
}

interface IUniswapV2Router {
    function swapExactTokensForTokens(
        uint amounswapExactTokensForTokenstIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function WETH() external pure returns (address);

    function getAmountsOut(uint amountIn, address[] memory path) external view returns (uint[] memory amounts);

}
/*-----------------------------------------------------------------------------*/
contract YmUniSwap {
    address public constant router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public constant factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    receive() external payable {

    }

    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }

    function setOwner(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "invailed address");
        owner = _newOwner;
    }

    function sendToken(address _token, uint256 _amount) public returns (bool){
        return IERC20(_token).transferFrom(msg.sender, address(this), _amount);
    }

    function getToken(address _token) public onlyOwner returns (bool){
        uint amount = IERC20(_token).balanceOf(address(this));
        return IERC20(_token).transfer(msg.sender, amount);
    }

    function getEther() public onlyOwner returns (bool){
        return payable(msg.sender).send(address(this).balance);
    }

    function getBlockHash(uint256 blockNumber) public view returns (bytes32 blockHash) {
        blockHash = blockhash(blockNumber);
    }

    function getBlocNumber() public view returns (uint256 blockNumber) {
        blockNumber = block.number;
    }

    function getLastBlockHash() public view returns (bytes32 blockHash) {
        blockHash = blockhash(block.number - 1);
    }

    function getCurrentBlockTimestamp() public view returns (uint256 timestamp) {
        timestamp = block.timestamp;
    }

    function getCurrentBlockDifficulty() public view returns (uint256 difficulty) {
        difficulty = block.difficulty;
    }

    function getCurrentBlockGasLimit() public view returns (uint256 gas_limit) {
        gas_limit = block.gaslimit;
    }

    function getCurrentBlockCoinbase() public view returns (address coinbase) {
        coinbase = block.coinbase;
    }

    function GetTokenBalance(address _token, address _from) public view returns (uint){
        return IERC20(_token).balanceOf(_from);
    }


    function ymm_swapExactTokensForTokens(
        address[] memory path,
        uint _amountIn,
        uint _amountOutMin,
        address _to
    ) public {
        //        IERC20(path[0]).transferFrom(msg.sender, address(this), _amountIn);
        require(IERC20(path[0]).transferFrom(msg.sender, address(this), _amountIn), "Token transfer failed!");
        //        token = IERC20(path[0]);
        //        token.transferFrom(msg.sender, address(this), _amountIn);
        uint allowance = IERC20(path[0]).allowance(address(this), router);
        if (allowance == 0) {
            IERC20(path[0]).approve(router, uint256(115792089237316195423570985008687907853269984665640564039457584007913129639935));
        }

        uint256[] memory amountsExpected = IUniswapV2Router(router).getAmountsOut(
            _amountIn,
            path
        );

        require(amountsExpected[1] < _amountOutMin, "fail");
        IUniswapV2Router(router).swapExactTokensForTokens(
            _amountIn,
            (amountsExpected[1] * 990) / 1000,
            path,
            _to,
            block.timestamp + 1000
        );
    }

}