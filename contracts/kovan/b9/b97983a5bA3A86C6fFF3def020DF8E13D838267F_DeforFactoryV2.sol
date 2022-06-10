// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import "./common/IERC20.sol";
import "./common/IDeforFactory.sol";
import "./common/IUniswapV2Router02.sol";

contract DeforFactoryV2 is IDeforFactory {

    address public weth;
    address public dexRouter;
    address public gasTank;
    address public receivedFeeContractAddress;
    // 允许调用的方法
    mapping(uint256 => bool) public assetsFunction;
    mapping(address => uint256) public nonces;
    mapping(address => mapping(uint256 => bool)) public randomNonces;
    bytes32 public constant TRANSACTION_CHANNEL = keccak256('Transaction(address from,bytes to,bytes data,uint256 nonce,uint256 expireTime)');
    bytes32 public constant RECEIVEDFEE_CHANNEL = keccak256('ReceivedFee(address from,address token,uint256 fee)');
    enum TxType{RECEIVED_FEE,GASTANK}
    event Fail(address indexed user,uint256 indexed nonce,uint8 txType);
    event TransactionState(address indexed user,uint256 indexed nonce,bool state);

    constructor(address _dexRouter,address _weth) {
        assetsFunction[599290589] = true;   // transferFrom(address,address,uint256)
        assetsFunction[1115958798] = true;  // safeTransferFrom(address,address,uint256)
        assetsFunction[3096268766] = true;  // safeTransferFrom(address,address,uint256,bytes)
        assetsFunction[1381750552] = true;  // safeBatchTransferFrom(adddress,address,uint256[],uint256[],bytes)
        assetsFunction[4064428842] = true;  // safeTransferFrom(address,address,uint256,uint256,bytes)

        dexRouter = _dexRouter;
        weth = _weth;
    }
    /*** WRITE ***/
    /*
        发送交易入口(交易入口需要分为2种逻辑：a->datas[0]必须是处理fee，b->datas[0]可以为任意操作)
            1. 先处理fee逻辑，如果fee逻辑失败，那么打印将用户加入黑名单操作
            2. 处理业务逻辑，如果业务逻辑中有任何一笔交易失败，那么将回滚除了fee逻辑之外的所有操作
    */
    function transactionChannel(address _from,address[] memory _toAddrs,bytes[] memory _datas,bytes memory _signature,uint256 _nonce,uint256 _expireTime,bytes memory _gasTankData,address _solver) external lock whenNotPaused payable{
        // 检测该交易是否过期
        require(_expireTime >= block.timestamp,"The time has expired");
        // 必须检测nonce，防止签名重放攻击
        if(_nonce >= 2**128){
            require(!randomNonces[_from][_nonce],"Nonce is already exists");
            randomNonces[_from][_nonce] = true;
        }else{
            require(_nonce == nonces[_from] + 1,"Nonce is error"); 
            nonces[_from] = _nonce;
        }
        require(verifyTransaction(_from,_toAddrs,_datas,_signature,_nonce,_expireTime) == _from,"Verify signer is error");
        bool success;
        // 接收fee
        (uint256 value) = getValueByTransferFromBytes(_datas[0]);
        if(value > 0){
            require(getFromByTransferFromBytes(_datas[0])==_from,"from address is error");
            (success,) = _toAddrs[0].call(_datas[0]);
            // 处理fee逻辑时失败直接回滚，可以将该用户列入黑名单中
            if(!success){
                emit Fail(_from,_nonce,uint8(TxType.RECEIVED_FEE));
                return;
            }
            if(_solver == address(0)){
                _solver = tx.origin;
            }
            if(_toAddrs[0] == weth){
                IERC20 erc = IERC20(_toAddrs[0]);
                erc.transferFrom(address(this),_solver,value);
            }else{
                address[] memory path = new address[](2);
                path[0] = _toAddrs[0];
                path[1] = weth;
                // swap之前缺少一个授权动作
                IERC20 erc = IERC20(_toAddrs[0]);
                if(erc.allowance(address(this),dexRouter)<value){
                    erc.approve(dexRouter,0);
                    erc.approve(dexRouter,2**256-1);
                }
                IUniswapV2Router02(dexRouter).swapExactTokensForETH(value, 0, path, _solver, block.timestamp);
            }
            // 为了使合约更加灵活，此处使用delegatecall
            // (success,) = dexRouter.delegatecall(abi.encodeWithSignature("swap(uint256,uint256,address[],address)",value,0,path,_solver));
            // require(success,"swap exchange is error");
        }
        // 为了节约gas消耗，gasTank signer是对keccak256(_signature)进行签名
        if(keccak256(_signature) == getSigHash(_gasTankData)){
            // 使用gasTank
            (success,) = gasTank.call(_gasTankData);
            if(!success){
                emit Fail(_from,_nonce,uint8(TxType.GASTANK));
                return;
            }
        }
        // // 处理业务逻辑，为了业务交易失败后不影响到fee的接收，使用call方式
        // (success,) = address(this).call(abi.encodeWithSignature("sendTransaction(address,address[],bytes[],uint256)",_from,_toAddrs,_datas,1));
        // emit TransactionState(_from,_nonce,success);        
    }

    function sendTransaction(address _from,address[] memory _toAddrs,bytes[] memory _datas,uint256 _num) private{
        for(uint256 i=_num; i<_toAddrs.length; i++){
            // 需要区分是否是ERC20协议，如果不是，那么直接就需要是验证通过的
            if(assetsFunction[getUintByBytes4(_datas[i])]){
                require(getFromByBytes(_datas[i]) == _from,"From is error");
            }
            require(_toAddrs[i] != gasTank,"Call contract address is not gasTank");
            (bool success,) = _toAddrs[i].call(_datas[i]);
            require(success,"Call is fail");
        }
    }

    function receivedFee(address _user,address _token,uint256 _protocolFee, bytes memory _signature) external {
        (bytes32 _r, bytes32 _s, uint8 _v) = sliceToSignature(_signature);
        address from =  ecrecover(keccak256(abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(
                    RECEIVEDFEE_CHANNEL,
                    _user,
                    _token,
                    _protocolFee
                ))
            )), _v, _r, _s);
        require(from == _user,"signer is error");
        if(_token == weth){
            IERC20 erc = IERC20(_token);
            erc.transferFrom(address(this),msg.sender,_protocolFee);
        }else{
            address[] memory path = new address[](2);
            path[0] = _token;
            path[1] = weth;
            IERC20 erc = IERC20(_token);
            if(erc.allowance(address(this),dexRouter)<_protocolFee){
                erc.approve(dexRouter,0);
                erc.approve(dexRouter,2**256-1);
            }
            IUniswapV2Router02(dexRouter).swapExactTokensForETH(_protocolFee, 0, path, msg.sender, block.timestamp);
        }
        // (bool success,) = dexRouter.delegatecall(abi.encodeWithSignature("swapExactTokensForETH(uint256,uint256,address[],address)",_protocolFee,0,path,msg.sender));
        // require(success,"swap exchange is error");
    }

    /*
        用于估算交易
    */
    function transactionChannel(address _from,address[] memory _toAddrs,bytes[] memory _datas,uint256 _nonce,uint256 _expireTime,address _solver) external lock whenNotPaused payable{
        // 检测该交易是否过期
        require(_expireTime >= block.timestamp,"The time has expired");
        // 必须检测nonce，防止签名重放攻击
         if(_nonce >= 2**128){
            require(!randomNonces[_from][_nonce],"Nonce is already exists");
            randomNonces[_from][_nonce] = true;
        }else{
            require(_nonce == nonces[_from] + 1,"Nonce is error"); 
            nonces[_from] = _nonce;
        }
        bool success;
        // 接收fee
        (uint256 value) = getValueByTransferFromBytes(_datas[0]);
        if(value > 0){
            require(getFromByTransferFromBytes(_datas[0])==_from,"from address is error");
            (success,) = _toAddrs[0].call(_datas[0]);
            // 处理fee逻辑时失败直接回滚，可以将该用户列入黑名单中
            if(!success){
                emit Fail(_from,_nonce,uint8(TxType.RECEIVED_FEE));
                return;
            }
            if(_solver == address(0)){
                _solver = tx.origin;
            }
            if(_toAddrs[0] == weth){
                IERC20 erc = IERC20(_toAddrs[0]);
                erc.transferFrom(address(this),_solver,value);
            }else{
                address[] memory path = new address[](2);
                path[0] = _toAddrs[0];
                path[1] = weth;
                // swap之前缺少一个授权动作
                IERC20 erc = IERC20(_toAddrs[0]);
                if(erc.allowance(address(this),dexRouter)<value){
                    erc.approve(dexRouter,0);
                    erc.approve(dexRouter,2**256-1);
                }
                IUniswapV2Router02(dexRouter).swapExactTokensForETH(value, 0, path, _solver, block.timestamp);
            }
            // 为了使合约更加灵活，此处使用delegatecall
            // (success,) = dexRouter.delegatecall(abi.encodeWithSignature("swap(uint256,uint256,address[],address)",value,0,path,_solver));
            // require(success,"swap exchange is error");
        }    
    }
    function verifyReceivedFee(address _user,address _token,uint256 _protocolFee, bytes memory _signature) public view returns(address){
        (bytes32 _r, bytes32 _s, uint8 _v) = sliceToSignature(_signature);
        return ecrecover(keccak256(abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(
                    RECEIVEDFEE_CHANNEL,
                    _user,
                    _token,
                    _protocolFee
                ))
            )), _v, _r, _s);
    }

    function addAssetsFunction(uint256 _bytes4) public onlyOwner returns(bool){
        require(!assetsFunction[_bytes4],"Bytes4 is already exists");
        assetsFunction[_bytes4] = true;
        return true;
    }
    function deleteAssetsFunction(uint256 _bytes4) public onlyOwner returns(bool){
        require(assetsFunction[_bytes4],"Bytes4 is not already exists");
        assetsFunction[_bytes4] = false;
        return true;
    }
    function updateGasTank(address _gasTank) public onlyOwner{
        gasTank = _gasTank;
    }
    /*** READ ***/
    // 通过data查询任意方法
    function getData(address _addr,bytes calldata _data) public view returns(bytes memory){
        (bool success,bytes memory b) = _addr.staticcall(_data);
        if(success){
            return b;
        }
        // return data;
    }
    function getUintByBytes4(bytes memory _data) public pure returns(uint256){
        return sliceFirstBytes(_data)/(16**56);
    }
    function sliceToSignature(bytes memory _signature) public pure returns (bytes32 _r, bytes32 _s, uint8 _v){
        assembly {
            _r := mload(add(_signature, 32))
            _s := mload(add(_signature, 64))
            _v := and(mload(add(_signature, 65)), 255)
        }
    }
    function getFromByTransferFromBytes(bytes memory _data) public pure returns(address _from){
        assembly {
            _from := mload(add(_data, 36))
        }
    }
    function getValueByTransferFromBytes(bytes memory _data) public pure returns (uint256 _value){
        assembly {
            _value := mload(add(_data, 100))
        }
    }
    function sliceFirstBytes(bytes memory _data) public pure returns (uint256 _bytes32){
        assembly {
            _bytes32 := mload(add(_data, 32))
        }
    }
    function getFromByBytes(bytes memory _data) public pure returns(address from){
        assembly {
            from := mload(add(_data,36))
        }
    }
    function getSigHash(bytes memory _data) public pure returns(bytes32 _sigHash){
        assembly {
            _sigHash := mload(add(_data,36))
        }
    }
    /*
        Transaction交易验证
        @Params
            _from : 用户地址
            _toAddrs : 调用的合约地址
            _datas : 拼接的字符串
            _signature : r + s + v
        @Returns
            address : 数据签名者的地址
    */
    function verifyTransaction(address _from,address[] memory _toAddrs,bytes[] memory _datas,bytes memory _signature,uint256 _nonce,uint256 _expireTime) public view returns (address){
        (bytes32 _r, bytes32 _s, uint8 _v) = sliceToSignature(_signature);
        return ecrecover(keccak256(abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(
                    TRANSACTION_CHANNEL,
                    _from,
                    keccak256(abi.encode(_toAddrs)),
                    keccak256(abi.encode(_datas)),
                    _nonce,
                    _expireTime
                ))
            )), _v, _r, _s);
    }
    function getSelector(string memory _str)public pure returns(bytes4){
        return bytes4(keccak256(bytes(_str)));
    }
    function getAddressListToBytes(address[] memory _addrs) public pure returns(bytes memory){
        return abi.encode(_addrs);
    }
    function getBytesListToBytes(bytes[] memory _bs) public pure returns(bytes memory){
        return abi.encode(_bs);
    }
    /*** UPDATE PROPERTIES ***/
    /*
        接受ETH直接转账
    */
    receive() external payable {}
    // fallback() external {}

}
contract Verify{

    bytes32 public constant TRANSACTION_CHANNEL = keccak256('Transaction(address from,bytes to,bytes data,uint256 nonce,uint256 expireTime)');
    bytes32 public SS;

    constructor(){
        uint256 chainId = 42;
        SS = keccak256(abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes("Defor Protocol")),
                keccak256(bytes("1.0")),
                chainId,
                address(0x06ECd302E7C8B039Cc491fccf9B758F1889b6F56)
            ));
    }

    function verifyTransaction(address _from,address[] memory _toAddrs,bytes[] memory _datas,bytes memory _signature,uint256 _nonce,uint256 _expireTime) public view returns (address){
    
        (bytes32 _r, bytes32 _s, uint8 _v) = sliceToSignature(_signature);
        return ecrecover(keccak256(abi.encodePacked(
                '\x19\x01',
                SS,
                keccak256(abi.encode(
                    TRANSACTION_CHANNEL,
                    _from,
                    keccak256(abi.encode(_toAddrs)),
                    keccak256(abi.encode(_datas)),
                    _nonce,
                    _expireTime
                ))
            )), _v, _r, _s);
    }
    function getString(address[] memory _addrs) public pure returns(bytes32){
        return keccak256(abi.encode(_addrs));
    }
    function getString2(address[] memory _addrs) public pure returns(bytes32){
        return keccak256(abi.encodePacked(_addrs));
    }
    function getString3(address[] memory _addrs) public pure returns(bytes memory){
        return abi.encode(_addrs);
    }
    function getString4(bytes[] memory _addrs) public pure returns(bytes memory){
        return abi.encode(_addrs);
    }
    function sliceToSignature(bytes memory _signature) public pure returns (bytes32 _r, bytes32 _s, uint8 _v){
        assembly {
            _r := mload(add(_signature, 32))
            _s := mload(add(_signature, 64))
            _v := and(mload(add(_signature, 65)), 255)
        }
    }

}

contract Selector{
    event State(bool state);
    function getSelector(string memory _str)public pure returns(bytes32){
        return keccak256(bytes(_str));
    }
    function a(address _addr,bytes memory _data) public{
        (bool success,) = _addr.call(_data);
        emit State(success);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

interface IUniswapV2Router02 {
    function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);

    function swapTokensForExactTokens(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);

    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);

    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);

    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);

    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import "./IERC20.sol";

abstract contract IDeforFactory {
    address public owner;
    bytes32 public immutable DOMAIN_SEPARATOR;
    bool public paused = false;
    uint256 public unlocked = 1;
    address public pendingOwner;

    event Pause();
    event Unpause();

    constructor(){
        uint256 chainId;
        assembly{
            chainId := chainid()
        }
        owner = msg.sender;
        DOMAIN_SEPARATOR = keccak256(abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes("Defor Protocol")),
                keccak256(bytes("1.0")),
                chainId,
                address(this)
            ));
    }

    /*
        取回所有的ETH
    */
    function withdrawEth() external {
        payable(msg.sender).transfer(address(this).balance);
    }

    /*
        取回所有的ERC20
    */
    function withdrawErc(address _contractAddress) external {
        IERC20 erc = IERC20(_contractAddress);
        erc.transfer(msg.sender, erc.balanceOf(address(this)));
    }

      
    /*
        修改管理员
    */
    function updatePendingOwner(address _pendingOwner) external onlyOwner {
        require(_pendingOwner != address(0), "PendingOwner cannot be zero");
        pendingOwner = _pendingOwner;
    }
    /*
        确认修改管理员
    */
    function updateOwner() external onlyPendingOwner {
        owner = msg.sender;
        pendingOwner = address(0);
    }
    /*
        用于接收ERC721代币
    */
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes memory _data) external returns(bytes4){
    }


    /*** MODIFIERS ***/
    /*
       Modifier to make a function callable only when the contract is not paused.
    */
    modifier whenNotPaused() {
        require(!paused, 'Paused');
        _;
    }

    /*
        仅限管理员操作
    */
    modifier onlyOwner(){
        require(owner == msg.sender, 'Unauthorized');
        _;
    }

    /*
        仅限新设置的管理员操作
    */
    modifier onlyPendingOwner(){
        require(pendingOwner == msg.sender, 'Unauthorized');
        _;
    }

    modifier lock() {
        require(unlocked == 1, 'Locked');
        unlocked = 0;
        _;
        unlocked = 1;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

interface IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function balanceOf(address) external view returns (uint256);

    function transfer(address, uint256) external;

    function transferFrom(address, address, uint256) external;

    function approve(address, uint256) external;

    function allowance(address, address) external view returns (uint256);
}