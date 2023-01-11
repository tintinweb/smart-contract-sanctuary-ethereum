// SPDX-License-Identifier: SimPL-2.0
pragma solidity ^0.8.0 ;

import "./ERC20.sol";
import "./ERC4907DEMO.sol";
import "./ReentrancyGuard.sol";
import "./MinerFactory.sol";
import "./MyApp.sol";

contract Trade is Ownable,Pausable,ReentrancyGuard{
    using Counters for Counters.Counter;

    Counters.Counter private _nextOrderId;

    //资金池内资金代币合约地址
    address private tokenAddress;
    //资金代币合约对象
    Token private ERC20Interface;

    address private appFactory;


    struct NodeInfo{
        uint startTime;
        uint createTime;
        uint64 duration;
        uint256 totalFee;
        address appAddress;
        uint256 expiresTime;
        bool isBurned;
    }

    mapping(address=>uint256[]) private orderList;

    mapping(uint256=>NodeInfo) private orderInfo;

    MinerFactory private factoryInterface;
    ERC4907Demo private ipInterface;
    ERC4907Demo private bandwidthInterface;
    ERC4907Demo private gpuInterface;
    ERC4907Demo private storageInterface;
    ERC4907Demo private cpuInterface;
    ERC4907Demo private memInterface;

    address private ipAddress;
    address private bandwidthAddress;
    address private gpuAddress;
    address private storageAddress;
    address private cpuAddress;
    address private memAddress;

    constructor(){
        _nextOrderId.increment();
    }

    function setTokenAddress(address _tokenAddress) public onlyOwner {
        //判断是否为地址是否为合法合约地址
        require(Address.isContract(_tokenAddress), "The address does not point to a contract");

        tokenAddress = _tokenAddress;
        //初始化代币接口对象
        ERC20Interface = Token(address(tokenAddress));
    }

    function setERC721Address(address _fac,address cpu,address mem, address ip, address bandwidth, address gpu, address _storage,address _appFactory) public onlyOwner {
        factoryInterface = MinerFactory(address(_fac));
        cpuInterface = ERC4907Demo(address(cpu));
        memInterface = ERC4907Demo(address(mem));
        ipInterface = ERC4907Demo(address(ip));
        bandwidthInterface = ERC4907Demo(address(bandwidth));
        gpuInterface = ERC4907Demo(address(gpu));
        storageInterface = ERC4907Demo(address(_storage));
        cpuAddress = cpu;
        memAddress = mem;
        bandwidthAddress = bandwidth;
        ipAddress = ip;
        gpuAddress = gpu;
        storageAddress = _storage;
        appFactory = _appFactory;
    }

    function getOrderList(address _addr) public view returns (uint256[] memory){
        return orderList[_addr];
    }

    function getOrderInfo(uint256 orderId) public view returns (NodeInfo memory){
        return orderInfo[orderId];
    }

    function getLatestOrderId() public view returns(uint256){
        return _nextOrderId.current();
    }

    function getOrderBalance(uint256 orderId) public view returns(uint256){
        uint startTime = orderInfo[orderId].startTime;
        uint256 totalFee = orderInfo[orderId].totalFee;
        uint256 expiresTime = orderInfo[orderId].expiresTime;
        return totalFee * ((expiresTime - block.timestamp + startTime)*100/(expiresTime - startTime));
    }

    function burnExpireToken() public onlyOwner{
        uint256 burnAmount = 0;
        for(uint256 i = 0;i<_nextOrderId.current();i++){
            if(orderInfo[i].expiresTime<block.timestamp && orderInfo[i].isBurned == false){
                burnAmount += orderInfo[i].totalFee;
                orderInfo[i].isBurned = true;
            }
        }
        ERC20Interface.burn(burnAmount);
    }

    function getExpireToken() view public returns(uint256){
        uint256 burnAmount = 0;
        for(uint256 i = 0;i<_nextOrderId.current();i++){
            if(orderInfo[i].expiresTime<block.timestamp && orderInfo[i].isBurned == false){
                burnAmount += orderInfo[i].totalFee;
            }
        }
        return burnAmount;
    }


    function stopApp(address appAddress,uint256 orderId) public{
        MyApp myApp = MyApp(appAddress);
        require(myApp.getMyOwner() == msg.sender,"you are not owner");
        for(uint i=0;i<myApp.getCpuTokenIds().length;i++){
            cpuInterface.setUser(myApp.getCpuTokenIds()[i],msg.sender,uint64(block.timestamp));
        }
        for(uint i=0;i<myApp.getMemTokenIds().length;i++){
            memInterface.setUser(myApp.getMemTokenIds()[i],msg.sender,uint64(block.timestamp));
        }
        for(uint i=0;i<myApp.getIpTokenIds().length;i++){
            ipInterface.setUser(myApp.getIpTokenIds()[i],msg.sender,uint64(block.timestamp));
        }
        for(uint i=0;i<myApp.getBandwidthTokenIds().length;i++){
            bandwidthInterface.setUser(myApp.getBandwidthTokenIds()[i],msg.sender,uint64(block.timestamp));
        }
        for(uint i=0;i<myApp.getGpuTokenIds().length;i++){
            gpuInterface.setUser(myApp.getGpuTokenIds()[i],msg.sender,uint64(block.timestamp));
        }
        for(uint i=0;i<myApp.getStorageTokenIds().length;i++){
            storageInterface.setUser(myApp.getStorageTokenIds()[i],msg.sender,uint64(block.timestamp));
        }
        uint256 balance = orderInfo[orderId].totalFee * (orderInfo[orderId].expiresTime - block.timestamp) / (orderInfo[orderId].expiresTime - orderInfo[orderId].startTime);
        ERC20Interface.transfer(msg.sender,balance);
        orderInfo[orderId].totalFee = orderInfo[orderId].totalFee * (block.timestamp-orderInfo[orderId].startTime) / (orderInfo[orderId].expiresTime - orderInfo[orderId].startTime);
        orderInfo[orderId].expiresTime = block.timestamp;
    }

    function addOrder(uint64 duration,uint256 totalPrice,address appAddress,address buyAddress) public{
        require(msg.sender == appFactory,"only used by appFactory");
        // uint64 expiresTime = uint64(block.timestamp)+duration;
        uint256 currentOrderId = _nextOrderId.current();
        _nextOrderId.increment();
        NodeInfo memory nodeInfo;
        nodeInfo.duration = duration;
        nodeInfo.createTime = block.timestamp;
        nodeInfo.totalFee = totalPrice;
        nodeInfo.appAddress = appAddress;
        orderInfo[currentOrderId] = nodeInfo;
        orderList[buyAddress].push(currentOrderId);
    }

    function setTokenIds(address appAddress,address[] memory _nodeAddress,uint256[][][] memory _tokenIds,uint256 orderId,address minerAddress) public{
        MyApp app = MyApp(appAddress);
        MinerContract mc = MinerContract(minerAddress);
        require(mc.getIssuer()==msg.sender,"you are not this verifyNode's Owner");
        require(block.timestamp - mc.myStake().getVerifyTimestamp(address(minerAddress)) <= 7200,"you are not available VerifyNode");
        uint256 totalPrice = 0;
        uint256 duration = orderInfo[orderId].duration;
        for(uint j=0;j<_tokenIds.length;j++){
            uint256[] memory _ipTokenIds = _tokenIds[j][0];
            uint256[] memory _bandwidthTokenIds = _tokenIds[j][1];
            uint256[] memory _gpuTokenIds = _tokenIds[j][2];
            uint256[] memory _storageTokenIds = _tokenIds[j][3];
            uint256[] memory _cpuTokenIds = _tokenIds[j][4];
            uint256[] memory _memTokenIds = _tokenIds[j][5];
            require(_ipTokenIds.length==app.getTokenNeed()[j][0]&& _bandwidthTokenIds.length==app.getTokenNeed()[j][1]&& _gpuTokenIds.length==app.getTokenNeed()[j][2]&& _storageTokenIds.length==app.getTokenNeed()[j][3]&& _cpuTokenIds.length ==app.getTokenNeed()[j][4] && _memTokenIds.length==app.getTokenNeed()[j][5]  ,"Insufficient resources");
            for(uint i = 0;i<_cpuTokenIds.length;i++){
                require(cpuInterface.getApproved(_cpuTokenIds[i]) == address(this),"cpu approve error");
                require(cpuInterface.userExpires(_cpuTokenIds[i])<block.timestamp,"cpu is used");
                cpuInterface.setUser(_cpuTokenIds[i],app.getMyOwner(),uint64(block.timestamp + duration));
                totalPrice += factoryInterface.getTokenPrice(cpuAddress,_cpuTokenIds[i]);
            }
            for(uint i = 0;i<_memTokenIds.length;i++){
                require(memInterface.getApproved(_memTokenIds[i]) == address(this),"mem approve error");
                require(memInterface.userExpires(_memTokenIds[i])<block.timestamp,"mem is used");
                memInterface.setUser(_memTokenIds[i],app.getMyOwner(),uint64(block.timestamp + duration));
                totalPrice += factoryInterface.getTokenPrice(memAddress,_memTokenIds[i]);
            }
            for(uint i = 0;i<_ipTokenIds.length;i++){
                require(ipInterface.getApproved(_ipTokenIds[i]) == address(this),"ip approve error");
                require(ipInterface.userExpires(_ipTokenIds[i])<block.timestamp,"ip is used");
                ipInterface.setUser(_ipTokenIds[i],app.getMyOwner(),uint64(block.timestamp + duration));
                totalPrice += factoryInterface.getTokenPrice(ipAddress,_ipTokenIds[i]);
            }
            for(uint i = 0;i<_bandwidthTokenIds.length;i++){
                require(bandwidthInterface.getApproved(_bandwidthTokenIds[i]) == address(this),"bandwidth approve error");
                require(bandwidthInterface.userExpires(_bandwidthTokenIds[i])<block.timestamp,"bandwidth is used");
                bandwidthInterface.setUser(_bandwidthTokenIds[i],app.getMyOwner(),uint64(block.timestamp + duration));
                totalPrice += factoryInterface.getTokenPrice(bandwidthAddress,_bandwidthTokenIds[i]);
            }
            for(uint i = 0;i<_gpuTokenIds.length;i++){
                require(gpuInterface.getApproved(_gpuTokenIds[i]) == address(this),"gpu approve error");
                require(gpuInterface.userExpires(_gpuTokenIds[i])<block.timestamp,"gpu is used");
                gpuInterface.setUser(_gpuTokenIds[i],app.getMyOwner(),uint64(block.timestamp + duration));
                totalPrice += factoryInterface.getTokenPrice(gpuAddress,_gpuTokenIds[i]);
            }
            for(uint i = 0;i<_storageTokenIds.length;i++){
                require(storageInterface.getApproved(_storageTokenIds[i]) == address(this),"storage approve error");
                require(storageInterface.userExpires(_storageTokenIds[i])<block.timestamp,"storage is used");
                storageInterface.setUser(_storageTokenIds[i],app.getMyOwner(),uint64(block.timestamp + duration));
                totalPrice += factoryInterface.getTokenPrice(storageAddress,_storageTokenIds[i]);
            }
        }
        totalPrice = totalPrice*duration/60/60/24/30;
        if(app.getIsExpanded()){
            totalPrice = totalPrice*6/5;
        }
        require(ERC20Interface.allowance(app.getMyOwner(),address(this))>=totalPrice,"allowance error");
        ERC20Interface.transferFrom(app.getMyOwner(),address(this),totalPrice);
        app.setNodeAddressAndTokenInfo(_nodeAddress,_tokenIds);
        orderInfo[orderId].startTime = block.timestamp;
        orderInfo[orderId].totalFee = totalPrice;
        orderInfo[orderId].expiresTime = block.timestamp + duration;
    }
}