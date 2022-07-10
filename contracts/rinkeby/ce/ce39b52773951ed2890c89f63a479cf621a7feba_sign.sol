/**
 *Submitted for verification at Etherscan.io on 2022-07-10
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
contract sign{



                                    ///元操作标识符///
    //bytes32("SWAP")
    bytes32 constant private SWAP_OPERATION = 0x5357415000000000000000000000000000000000000000000000000000000000;
    //bytes32("BORROW")
    bytes32 constant private BORROW_OPERATION = 0x424f52524f570000000000000000000000000000000000000000000000000000;
                                    
                                    ///接口地址///
    //DEX接口
    address constant private UNISWAPV2_ROUTER = 0x8edA82BCC2CCb5B82FA8adcAf9d843247b3C1dA6;
    address constant private SUSHISWAPV2_ROUTER = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;

    

    event test(bytes32 opType,bytes32 SWAP_OPERATION,address impl,address router);

    struct Task{
        address signer;
        address tokenIn;
        address tokenOut;
        bytes32 opType;
        uint amountIn;
        uint amountOut;
        //以tokenIn计价的执行者奖励
        uint amountReward;
        //防止签名重放
        uint expiredTime;
    }
    struct EIP712Domain {
        string  name;
        string  version;
        uint256 chainId;
        address verifyingContract;
    }
    event test2 (bool,bytes);

                                        ///EIP-712相关///
    bytes32 public immutable DOMAIN_SEPARATOR;
    bytes32 public constant EIP712DOMAIN_TYPEHASH = keccak256(
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    );
    bytes32 internal constant TYPE_HASH = keccak256("Task(address signer,address tokenIn,address tokenOut,bytes32 opType,uint amountIn,uint amountOut,uint amountReward,uint expiredTime)");
    constructor() {
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                EIP712DOMAIN_TYPEHASH,
                keccak256("sign"),
                keccak256("1"),
                block.chainid,
                address(this)
            )
        );
    }
    event test(bool, bytes);
    function verify(Task memory task,uint8 v, bytes32 r, bytes32 s) internal view returns (bool) {

        bytes32 digest = keccak256(abi.encodePacked(
        "\x19\x01",
        DOMAIN_SEPARATOR,
        hashStruct(task)
        ));

        return ecrecover(digest, v, r, s) == task.signer;

    }
    function hashStruct(Task memory task) internal pure returns (bytes32) {
        return keccak256(
            abi.encode(
                TYPE_HASH,
                task.signer,
                task.tokenIn,
                task.tokenOut,
                task.opType,
                task.amountIn,
                task.amountOut,
                task.amountReward,
                task.expiredTime
            )
        );
    }

               
    function execute(bytes32[] memory userData,bytes32[] calldata extraData,uint8 v, bytes32 r, bytes32 s) external {

        Task memory task;
        uint balanceBeforeCall;
        uint reward;
        //拆分userData
        task = splitUserData(userData);
        //验证签名是否由用户发出
        require(verify(task,v,r,s)==true,"Error singer!");
        //验证是否是最新的签名
        require(block.timestamp<=task.expiredTime,"Expired sign!");

        balanceBeforeCall = IUniswapV2ERC20(task.tokenIn).balanceOf(address(this));
        //调用对应函数
        require(_execute(extraData,task)==true,"Error Call!");
        //分配奖励
        reward = IUniswapV2ERC20(task.tokenIn).balanceOf(address(this)) - balanceBeforeCall;
        distributeReward(reward,task.tokenIn,msg.sender);      
    }

    function _execute(bytes32[] calldata extraData,Task memory task) internal returns(bool){
        address impl;
        bool succeed;
        bytes32 temp = extraData[0];
        //提取调用者要实现的接口地址
        assembly{
            temp := shl(96,temp)
        }
        impl = address(bytes20(temp));

        if(task.opType == SWAP_OPERATION){
            if(impl == UNISWAPV2_ROUTER || impl == SUSHISWAPV2_ROUTER){

                require(true == IUniswapV2ERC20(task.tokenIn).transferFrom(task.signer,address(this),task.amountIn),"error when transferFrom signer to signContract!");
                require(true == IUniswapV2ERC20(task.tokenIn).approve(impl,task.amountIn-task.amountReward),"error when signContract approve to router!");
                //调用swapExactTokensForTokens(）
                require(true == callswapExactTokensForTokens(impl,task.amountIn-task.amountReward,task.amountOut,task.signer,extraData),"error when call function!");
                succeed = true;
            }
        }   
        return succeed;
    }


    function callswapExactTokensForTokens(address impl,uint amountIn,uint amountOut,address signer,bytes32[] calldata extraData) internal returns (bool){
        //bytes4(keccak("swapExactTokensForTokens(uint256,uint256,address[],address,uint256)")) = 0x38ed1739
        bytes4 func = 0x38ed1739;
        //extraData = impl + path[] + deadtime
        bytes32[] memory path = splitBytes32(extraData,1,extraData.length-1);
        bytes memory callData = 
        abi.encodePacked(
            func,
            abi.encode(
                amountIn,
                amountOut,
                path,
                signer,
                extraData[extraData.length-1]));
        (bool success,bytes memory data) = impl.call(callData);
        return success;
    }

    function splitBytes32(bytes32[] calldata input,uint start,uint end) internal returns(bytes32[] memory){
        return input[start:end];
    }
    
    function distributeReward(uint reward,address token,address to) internal{
        IUniswapV2ERC20(token).transfer(to,reward);
    }

    function splitUserData(bytes32[] memory userData) internal pure returns(Task memory task){

        bytes32 tempSinger = userData[0];
        bytes32 temptokenIn = userData[1];
        bytes32 temptokenOut = userData[2];
        assembly{
            tempSinger := shl(96,tempSinger)
            temptokenIn := shl(96,temptokenIn)
            temptokenOut := shl(96,temptokenOut)
        }
        task.signer = address(bytes20(tempSinger));
        task.tokenIn = address(bytes20(temptokenIn));
        task.tokenOut = address(bytes20(temptokenOut));
        task.opType = userData[3];
        task.amountIn = uint(userData[4]);
        task.amountOut = uint(userData[5]);
        task.amountReward = uint(userData[6]);
        task.expiredTime = uint(userData[7]);
        return task;          
    }

}