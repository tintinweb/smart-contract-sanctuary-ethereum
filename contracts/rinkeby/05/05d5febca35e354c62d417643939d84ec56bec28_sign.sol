/**
 *Submitted for verification at Etherscan.io on 2022-07-08
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
contract sign{



    //接口地址
    address constant public UNISWAPV2_ROUTER = 0x8edA82BCC2CCb5B82FA8adcAf9d843247b3C1dA6;
    address constant public SUSHISWAPV2_ROUTER = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;
    //
    //bytes4(keccak("swapExactTokensForTokens(uint256,uint256,address[],address,uint256)")) = 0x38ed1739





    
    struct Task{
        address signer;
        address tokenIn;
        address tokenOut;
        address implement;
        uint amountIn;
        uint amountOut;
        uint amountReward;
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
                _task.implement,
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
    function execute(bytes calldata _userData,bytes calldata _executerData,uint8 _v, bytes32 _r, bytes32 _s) external {

        Task memory task;
        bytes4 sig;
        //解析_userData   
        {
            sig = bytes4(_userData[0:3]);
            task.signer = address(bytes20(_userData[4:35]));
            task.implement = address(bytes20(_userData[36:67]));
            task.tokenIn = address(bytes20(_userData[68:99]));
            task.tokenOut = address(bytes20(_userData[100:131]));
            task.amountIn = uint(bytes32(_userData[132:163]));
            task.amountOut = uint(bytes32(_userData[164:195]));
            task.amountReward = uint(bytes32(_userData[196:227]));
            task.expiredTime = uint(bytes32(_userData[228:259]));          
        }
        //验证签名是否由用户发出
        require(verify(task,_v,_r,_s)==true,"error singer!");

        //验证是否是最新的签名
        require(block.timestamp<=task.expiredTime,"expired sign!");

        //对不同的调用函数参数拼接
        bytes memory callData = beforeCall(sig,_userData,_executerData,task);
        
        //如果没有对应接口则报错
        require(callData.length!=0,"no support interface!");

        //调用对应的接口
        (bool success,) = address(task.implement).call(callData);
        
        require(success==true,"call failed!");
    }


    function beforeCall(bytes4 _sig,bytes calldata _userData,bytes calldata _executerData,Task memory _task) internal returns(bytes memory callData){       
        if(_task.implement==SUSHISWAPV2_ROUTER)
            return setUniCallData(_sig,_task.amountIn,_task.amountOut,_task.signer,_executerData);
        else return callData;  
    }

    /*UNISWAP接口传入参数
        function swapExactTokensForTokens(
            uint amountIn,
            uint amountOutMin,
            address[] calldata path,
            address to,
            uint deadline)*/

    function setUniCallData(bytes4 _sig,uint _amountIn,uint _amountOut,address _signer,bytes calldata _executerData) public returns(bytes memory callData){
        return abi.encodePacked(_sig,abi.encode(_amountIn,_amountOut,_signer,_executerData[_executerData.length-31:_executerData.length]));
    }
    function setUniCallData1(bytes4 _sig,uint _amountIn,uint _amountOut,address _signer,bytes memory _executerData) public returns(bytes memory callData){
        return abi.encodePacked(_sig,abi.encode(_amountIn,_amountOut,_signer,_executerData));
    }

}