/**
 *Submitted for verification at Etherscan.io on 2022-07-09
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

                                        ///EIP-712相关///
    bytes32 public immutable DOMAIN_SEPARATOR;
    bytes32 public constant EIP712DOMAIN_TYPEHASH = keccak256(
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    );
    bytes32 internal constant TYPE_HASH = keccak256("Task(address signer,address implement,address tokenIn,address tokenOut,uint amountIn,uint amountOut,uint amountReward,uint expiredTime)");
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

    function verify(Task memory _task,uint8 _v, bytes32 _r, bytes32 _s) public view returns (bool) {

        bytes32 digest = keccak256(abi.encodePacked(
        "\x19\x01",
        DOMAIN_SEPARATOR,
        hashStruct(_task)
        ));

        return ecrecover(digest, _v, _r, _s) == _task.signer;

    }
    function hashStruct(Task memory _task) public pure returns (bytes32) {
        return keccak256(
            abi.encode(
                TYPE_HASH,
                _task.signer,
                _task.opType,
                _task.tokenIn,
                _task.tokenOut,
                _task.amountIn,
                _task.amountOut,
                _task.amountReward,
                _task.expiredTime
            )
        );
    }


    /*_userData格式：
        struct Task{
            address signer;
            address implement;
            address tokenIn;
            address tokenOut;
            uint amountIn;
            uint amountOut;
            uint amountReward;
            uint expiredTime;
    }
    */
                                        ///功能函数///   
    function execute(bytes calldata _userData,bytes32[] memory _extraData,uint8 _v, bytes32 _r, bytes32 _s) external {

        Task memory task;
        bytes4 func;
        uint balanceBeforeCall;
        uint reward;
        //拆分_userData  
        {
            task.signer = address(bytes20(_userData[0:]));
            task.opType = bytes32(_userData[36:67]);
            task.tokenIn = address(bytes20(_userData[68:99]));
            task.tokenOut = address(bytes20(_userData[100:131]));
            task.amountIn = uint(bytes32(_userData[132:163]));
            task.amountOut = uint(bytes32(_userData[164:195]));
            task.amountReward = uint(bytes32(_userData[196:227]));
            task.expiredTime = uint(bytes32(_userData[228:259]));          
        }
        //验证签名是否由用户发出
        require(verify(task,_v,_r,_s)==true,"Error singer!");
        //验证是否是最新的签名
        require(block.timestamp<=task.expiredTime,"Expired sign!");

        balanceBeforeCall = IUniswapV2ERC20(task.tokenIn).balanceOf(address(this));
        //构建参数并执行
        require(_execute(func,_userData,_extraData,task)==true,"Error Call!");
        //分配奖励
        reward = IUniswapV2ERC20(task.tokenIn).balanceOf(address(this)) - balanceBeforeCall;
        distributeReward(reward,task.tokenIn,msg.sender);      
    }

    function _execute(bytes4 _func,bytes calldata _userData,bytes32[] memory _extraData,Task memory _task) internal returns(bool){
        address _impl;
        bool _succeed;
        //提取调用者要实现的接口地址
        assembly{
            _impl := mload(add(_extraData,0x20))
        }

        //根据opType选择操作类型，根据接口地址构建调用参数并调用
        if(_task.opType == SWAP_OPERATION){
            if(_impl == UNISWAPV2_ROUTER || _impl == SUSHISWAPV2_ROUTER){
                (bytes memory _callData) = putUniV2ParmTogether(_func,_task.amountIn,_task.amountOut,_extraData,_task.signer);
                //因为调用路由协议的swapExactTokesForToken时，token转移时需要验证allowance[signContract][router].sub(value)>=0
                //所以需要先把用户的币转到当前合约中，合约再授权给路由协议
                require(true == IUniswapV2ERC20(_task.tokenIn).transferFrom(_task.signer,address(this),_task.amountIn),"error when transferFrom signer to signContract!");
                require(true == IUniswapV2ERC20(_task.tokenIn).approve(msg.sender,_task.amountIn),"error when signContract approve to router!");
                //调用swapExactTokensForTokens(）
                (_succeed,) = _impl.call(_callData);

            }
        }   
        return _succeed;
    }


    /*
        function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    */
    function putUniV2ParmTogether(bytes4 _func,uint _amountIn,uint amountOut,bytes32[] memory _extraData,address _signer)public pure returns (bytes memory _callData){
        _callData = abi.encodePacked(
            _func,
            abi.encode(
                _amountIn,
                amountOut,
                _extraData[1],
                _signer,
                _extraData[2],
                _extraData[3],
                _extraData[4],
                _extraData[5]));
       return _callData;
    }
    function distributeReward(uint _reward,address _token,address _to) internal{
        IUniswapV2ERC20(_token).transfer(_to,_reward);
    }

    function testTask(bytes calldata userData) public returns(Task memory task){

            task.signer = address(bytes20(userData[0:19]));
            task.opType = bytes32(userData[20:51]);
            task.tokenIn = address(bytes20(userData[52:71]));
            task.tokenOut = address(bytes20(userData[72:91]));
            task.amountIn = uint(bytes32(userData[92:123]));
            task.amountOut = uint(bytes32(userData[124:155]));
            task.amountReward = uint(bytes32(userData[156:187]));
            task.expiredTime = uint(bytes32(userData[188:219]));
            return task;          
        }

}