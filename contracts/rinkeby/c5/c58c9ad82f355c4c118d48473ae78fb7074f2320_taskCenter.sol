/**
 *Submitted for verification at Etherscan.io on 2022-07-07
*/

pragma solidity >=0.7.0 <0.9.0;

interface IUniswapV2ERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}
interface IUniswapV2Router01 {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}
contract taskCenter{

    uint256 public totalTask;
    mapping(uint=>Task) public taskId;

    struct Task{
        //任务发布者
        address sender;
        address tokenIn;
        address tokenOut;
        //路由协议的地址
        address router;
        //卖出代币A的数量
        uint amountIn;
        uint amountOut;
        //赏金
        uint executeRewardRatio;
        //任务是否被完成
        bool finished;
    }

    event newTask(address _tokenIn,address _tokenOut,address _router,uint _amountIn,uint _amountOut,uint _executeReward);
    event finishTask(uint _taskId,address _executer,uint _executeReward);
    event deleteTask(uint _taskId);

    //任务发布者创建任务并将代币（交换数量+赏金）打入合约
    function createTask(address _tokenIn,address _tokenOut,address _router,uint _amountIn,uint _amountOut,uint _executeReward) public{

        //处理transfer时会燃烧的情况，得到真正存入的token数量
        uint _beforeTokenIn;
        uint _amountInReal;
        _beforeTokenIn = IUniswapV2ERC20(_tokenIn).balanceOf(address(this));
        IUniswapV2ERC20(_tokenIn).transferFrom(msg.sender,address(this),_amountIn);
        _amountInReal = IUniswapV2ERC20(_tokenIn).balanceOf(address(this)) - _beforeTokenIn;

        //初始化任务
        {
            Task memory task;
            task.sender = msg.sender;
            task.tokenIn = _tokenIn;
            task.tokenOut = _tokenOut;
            task.router = _router;
            task.amountIn = _amountInReal;
            task.amountOut = _amountOut;
            task.executeRewardRatio = _executeReward;
            taskId[++totalTask] = task;
        }

        emit newTask(_tokenIn,_tokenOut,_router,_amountIn,_amountOut,_executeReward);
    }
    //任务发布者取消任务，退回发布者存入的代币
    function cancelTask(uint _taskId) public {
        Task memory task = taskId[_taskId];
        require(task.sender == msg.sender,"not task owner!");
        IUniswapV2ERC20(task.tokenIn).transfer(msg.sender,task.amountIn);
        task.finished = true;
        emit deleteTask(_taskId);
    }
    //赏金猎人trigger合约发起调用完成任务
    function executeTask(uint _taskId,address[] calldata _path,uint _deadline) public {

        Task memory task = taskId[_taskId];
        require(task.finished == false,"task have been finished");

        //计算卖出tokenA数量和赏金
        uint _beforCal = IUniswapV2ERC20(task.tokenIn).balanceOf(address(this));
        uint _rewardAmount = task.amountIn * task.executeRewardRatio / 10000;
        uint _realSellAmount = _beforCal - _rewardAmount;

        IUniswapV2ERC20(task.tokenIn).approve(task.router,2**256-1);

        //uniswap前端计算tokenA和tokenB交换的最佳路由方法：https://github.com/Uniswap/interface/blob/3aa045303a4aeefe4067688e3916ecf36b2f7f75/src/hooks/useBestV3Trade.ts#L17-L96
        //此处需要赏金猎人手动输入最佳路由
        IUniswapV2Router01(task.router).swapExactTokensForTokens(
            _realSellAmount,
            task.amountOut,
            _path,
            task.sender,
            _deadline);

        IUniswapV2ERC20(task.tokenIn).transfer(msg.sender,_rewardAmount);  
        task.finished == true;

        emit finishTask(_taskId,msg.sender,_rewardAmount);
    }


}