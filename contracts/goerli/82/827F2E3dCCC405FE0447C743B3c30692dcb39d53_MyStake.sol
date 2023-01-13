// SPDX-License-Identifier: SimPL-2.0
pragma solidity ^0.8.0 ;

import "./ReentrancyGuard.sol";
import "./Address.sol";
import "./MinerFactory.sol";


contract MyStake is Ownable, Pausable, ReentrancyGuard {

    struct Stake {
        uint deposit_amount;        //质押金额，记账
        uint stake_creation_time;   //首次质押时间
        uint last_upload_time;       //上次上传信息时间
        bool returned;              //是否可以赎回，默认可以，（保留字段）
        uint alreadyWithdrawedAmount;   //已近赎回金额,记账
        uint AllUploadCount; //总上传心跳次数
        uint AllRewardAmount; //总分红金额
        uint rewardAmount; //当前分红金额（总分红金额-总提币金额）
        uint rewardUpload; //这个周期上传心跳次数（每12次归零）
        uint AllReturnAmount; //总提币金额
        address walletAddr;
        bool isUsed; //是否被使用，用于判断地址是否存在
    }

    struct ClientInfo {
        //心跳上传时间戳
        uint ts;
        //心跳上传内容
        uint256 _ip;
        uint256 _bandwidth;
        uint256 _gpu;
        uint256 _storage;
        uint256 _cpu;
        uint256 _mem;
    }

    //心跳上传内容
    struct StandardInfo {
        uint _ip;
        uint _bandwidth;
        uint _gpu;
        uint _storage;
        uint _cpu;
        uint _mem;
        bool isUsed;
    }

    struct RewardInfo {
        uint rewardType;
        uint256 rewardTime;
        uint256 amount;
    }

    //--------------------------------------------------------------------
    //-------------------------- GLOBALS -----------------------------------
    //--------------------------------------------------------------------


    string secret = "ohcloud";

    mapping(address => RewardInfo[]) private rewardLog;
    //存用户地址（用户挖矿合约地址）和对应详情，用户查询
    mapping(address => Stake) private stake;
    //正在使用中的用户地址（用户挖矿合约地址）
    address[] private activeAddresses;
    //存放swarm支票本地址和挖矿合约地址的对应关系
    mapping(address => address) private cashHni;
    //存放swarm支票本地址和swarm钱包地址的对应关系（未使用）
    mapping(address => address) private cashWallet;
    //挖矿合约地址和硬件上传信息的对应关系
    mapping(address => ClientInfo[]) private clientInfos;
    //节点的配置标准
    //mapping (address => StandardInfo) private standardInfo;
    //总质押金额
    uint256 private totalDepositAmount;
    //总权重
    uint256 private allPowerWight;
    //资金池内资金代币合约地址
    address private tokenAddress;
    //分红比例（分母10000,分子默认为0,分红1%即此值为100）
    uint private rewardPercent = 100;
    //提币比例（分母10000,分子默认为0,提币收取1%代币费用即此值为9900）
    //原用于手续费收取，现未使用，默认为10000,100%提币
    uint private returnPercent = 10000;
    //资金代币合约对象
    Token private ERC20Interface;
    //资金池提币服务费(单位wei)
    uint private gasAmount = 10000000000000000;
    //分红周期(上传多少次硬件信息分红，默认12次)
    uint private uploadcount = 12;
    //每次硬件上传间隔时间（默认3600s 1个小时）
    uint private uploadtime = 3550;

    mapping(address => uint256) private verifyNode;

    MinerFactory public factoryInterface;

    //构造函数（未设置任何初始值,由管理员调用set方法设置，提高灵活性）
    constructor(){
        tokenAddress = address(0);
    }

    //设置资金池代币地址(管理员权限)
    function setTokenAddress(address _tokenAddress) public onlyOwner {
        //判断是否为地址是否为合法合约地址
        require(Address.isContract(_tokenAddress), "The address does not point to a contract");

        tokenAddress = _tokenAddress;
        //初始化代币接口对象
        ERC20Interface = Token(address(tokenAddress));
    }

    //设置资金池代币地址(管理员权限)
    function setFactoryAddress(address _factoryAddress) public onlyOwner {
        //判断是否为地址是否为合法合约地址
        require(Address.isContract(_factoryAddress), "The address does not point to a contract");

        factoryInterface = MinerFactory(_factoryAddress);
    }

    //回收合约内服务费到管理员账号(管理员权限)
    function getGas() payable public onlyOwner {
        payable(address(msg.sender)).transfer(address(this).balance);
    }

    //设置分红周期(管理员权限)
    function setUploadCount(uint _uploadCount) public onlyOwner {
        uploadcount = _uploadCount;
    }

    //设置每次硬件上传周期间隔时间(管理员权限)
    function setUploadTime(uint _uploadTime) public onlyOwner {
        uploadtime = _uploadTime;
    }

    //设置分红比例(管理员权限)
    function setRewardPercent(uint rp) public onlyOwner {
        rewardPercent = rp;
    }

    //设置手续费大小
    function setGasAmount(uint ga) public onlyOwner {
        gasAmount = ga;
    }

    //设置提币时的提币比例(启用，默认100%提币)
    function setReturnPercent(uint rt) public onlyOwner {
        returnPercent = rt;
    }

    //判断资金池合约有没有设置代币地址
    function isTokenSet() public view returns (bool) {
        if (tokenAddress == address(0))
            return false;
        return true;
    }

    //获取资金池合约的代币地址
    function getTokenAddress() public view returns (address){
        return tokenAddress;
    }

    //根据用户挖矿合约地址 获取stake mapping中的所有信息
    function getAllInfo(address _addr) public view returns (Stake memory){
        return stake[_addr];
    }

    //判断用户的挖矿地址是否进行过质押
    function isExistEntry(address _addr) public view returns (bool){
        return stake[_addr].isUsed;
    }

    //质押代币
    // /**
    // @Param _amount 质押金额
    // @Param walletAddr 用钱包地址
    // */
    function stakeToken(uint _amount, address walletAddr) public nonReentrant {

        address staker = msg.sender;

        //质押金额必须大于0
        require(_amount > 0, "UBQ is not enough!!");

        //该方法必须由合约调用，否则判定为非法
        require(Address.isContract(staker), "Illegal upload errCode:004!");

        Stake memory newStake;

        //修改信息
        if (isExistEntry(staker)) {
            newStake = stake[staker];
            newStake.deposit_amount += _amount;
            newStake.stake_creation_time = block.timestamp;
            newStake.isUsed = true;
            RewardInfo memory rewardInfo;
            rewardInfo.rewardType = 3;
            rewardInfo.rewardTime = block.timestamp;
            rewardInfo.amount = _amount;
            rewardLog[staker].push(rewardInfo);
        } else {
            newStake.deposit_amount = _amount;
            newStake.returned = false;
            newStake.stake_creation_time = block.timestamp;
            newStake.alreadyWithdrawedAmount = 0;
            newStake.isUsed = true;
            newStake.AllRewardAmount = 0;
            newStake.AllUploadCount = 0;
            newStake.rewardUpload = 0;
            newStake.AllReturnAmount = 0;
            newStake.rewardAmount = 0;
            newStake.walletAddr = walletAddr;
            activeAddresses.push(staker);
            RewardInfo memory rewardInfo;
            rewardInfo.rewardType = 4;
            rewardInfo.rewardTime = block.timestamp;
            rewardInfo.amount = _amount;
            rewardLog[staker].push(rewardInfo);
        }
        stake[staker] = newStake;
    }

    //加密
    function calcSha256(string memory time) private view returns (bytes32){
        bytes32 id = sha256(joinBytes(bytes(secret), bytes(time)));
        return id;
    }

    //bytes拼接
    function joinBytes(bytes memory st1, bytes memory st2) private pure returns (bytes memory){
        string memory ret = new string(st1.length + st2.length);
        bytes memory retTobytes = bytes(ret);
        uint index = 0;
        for (uint i = 0; i < st1.length; i++) {
            retTobytes[index++] = st1[i];
        }
        for (uint i = 0; i < st2.length; i++) {
            retTobytes[index++] = st2[i];
        }
        return retTobytes;
    }

    function uploadAllInfo(uint256 ts,
        string memory tsStr,
        bytes32 sign,
        address[] memory nodeAddress,
        uint256[][][] memory TokenIds,
        uint256[][][] memory TokenPrice) public {
        bytes32 id = calcSha256(tsStr);
        require(id == sign, "Illegal upload errCode:001!");
        require(block.timestamp - ts <= 300, "Illegal upload errCode:002!");
        verifyNode[msg.sender] = block.timestamp;
        for (uint i = 0; i < nodeAddress.length; i++) {
            uploadInfo(ts, nodeAddress[i], TokenIds[i], TokenPrice[i]);
        }
    }

    event uploadError(address indexed contractAddress, uint256 realSto,uint256 realCpu,uint256 realMem,uint256 realGpu,uint256 realIp,uint256 realBan);

    //上传信息
    // /*
    // @Param ts 时间戳
    // @Param tsStr 时间戳字符串
    // @Param sign 加密签名
    // @Param result 上传内容
    // **/
    function uploadInfo(uint256 ts,
        address nodeAddress,
        uint256[][] memory TokenIds,
        uint256[][] memory TokenPrice
    ) private {
        // bytes32 id = calcSha256(tsStr,nodeAddress);
        // //校验加密串
        // require(id == sign,"Illegal upload errCode:001!");
        //判断时效性(300s内合法)
        //require(block.timestamp - ts <= 300,"Illegal upload errCode:002!");
        address contractAddr = nodeAddress;
        //判断上传间隔时间合法性(避免短时间内重复上传)
        if (ts - stake[contractAddr].last_upload_time >= uploadtime) {
            uint256 _ip = TokenIds[0].length;
            uint256 _bandwidth = TokenIds[1].length;
            uint256 _gpu = TokenIds[2].length;
            uint256 _storage = TokenIds[3].length;
            uint256 _cpu = TokenIds[4].length;
            uint256 _mem = TokenIds[5].length;
            for (uint i = 0; i < _ip; i++) {
                factoryInterface.setTokenPrice(factoryInterface.ipAddress(), TokenIds[0][i], TokenPrice[0][i]);
            }
            for (uint i = 0; i < _bandwidth; i++) {
                factoryInterface.setTokenPrice(factoryInterface.bandwidthAddress(), TokenIds[1][i], TokenPrice[1][i]);
            }
            for (uint i = 0; i < _gpu; i++) {
                factoryInterface.setTokenPrice(factoryInterface.gpuAddress(), TokenIds[2][i], TokenPrice[2][i]);
            }
            for (uint i = 0; i < _storage; i++) {
                factoryInterface.setTokenPrice(factoryInterface.storageAddress(), TokenIds[3][i], TokenPrice[3][i]);
            }
            for (uint i = 0; i < _cpu; i++) {
                factoryInterface.setTokenPrice(factoryInterface.cpuAddress(), TokenIds[4][i], TokenPrice[4][i]);
            }
            for (uint i = 0; i < _mem; i++) {
                factoryInterface.setTokenPrice(factoryInterface.memAddress(), TokenIds[5][i], TokenPrice[5][i]);
            }
            if (factoryInterface.storageInterface().balanceOf(contractAddr) >= _storage && factoryInterface.cpuInterface().balanceOf(contractAddr) >= _cpu && factoryInterface.memInterface().balanceOf(contractAddr) >= _mem && factoryInterface.gpuInterface().balanceOf(contractAddr) >= _gpu && factoryInterface.ipInterface().balanceOf(contractAddr) >= _ip && factoryInterface.bandWidthInterface().balanceOf(contractAddr) >= _bandwidth) {
                ClientInfo memory clientInfo;
                clientInfo.ts = ts;
                clientInfo._storage = _storage;
                clientInfo._cpu = _cpu;
                clientInfo._mem = _mem;
                clientInfo._gpu = _gpu;
                clientInfo._ip = _ip;
                clientInfo._bandwidth = _bandwidth;
                // clientInfos.push(clientInfo);
                clientInfos[contractAddr].push(clientInfo);
                stake[contractAddr].AllUploadCount += 1;
                stake[contractAddr].rewardUpload += 1;
                stake[contractAddr].last_upload_time = ts;
                //如果周期上传数到达分红周期次数，开始分红
                if (stake[contractAddr].rewardUpload >= uploadcount) {
                    stake[contractAddr].rewardUpload = 0;
                    uint256 rewardAmount = (stake[contractAddr].deposit_amount * rewardPercent / 10000);
                    stake[contractAddr].AllRewardAmount += rewardAmount;
                    stake[contractAddr].rewardAmount += rewardAmount;
                    RewardInfo memory rewardInfo;
                    rewardInfo.rewardType = 1;
                    rewardInfo.rewardTime = block.timestamp;
                    rewardInfo.amount = rewardAmount;
                    rewardLog[contractAddr].push(rewardInfo);
                }
            }else{
                emit uploadError(contractAddr,factoryInterface.storageInterface().balanceOf(contractAddr),factoryInterface.cpuInterface().balanceOf(contractAddr),factoryInterface.memInterface().balanceOf(contractAddr),factoryInterface.gpuInterface().balanceOf(contractAddr),factoryInterface.ipInterface().balanceOf(contractAddr),factoryInterface.bandWidthInterface().balanceOf(contractAddr));
            }
        }
    }

    function getRewardLog(address nodeAddress) view public returns (RewardInfo[] memory){
        return rewardLog[nodeAddress];
    }

    //提币
    function returnToken(uint _amount) payable public nonReentrant {
        address staker = msg.sender;
        //判断地址是否质押过
        require(isExistEntry(staker), "The Address is not Exist");
        //判断分红金额是否大于提币金额
        require(stake[staker].rewardAmount >= _amount, "deposit amount is not enough");
        //铸造对应数量的代币至对应的挖矿合约（returnPercent默认为10000，即100%提币）
        //ERC20Interface.mint(staker, _amount*returnPercent/10000);
        require(ERC20Interface.mint(staker, _amount * returnPercent / 10000) == true, "mint error");
        //记账变更
        stake[staker].rewardAmount -= _amount;
        stake[staker].AllReturnAmount += _amount;
    }

    //取出质押
    function undeposit() public virtual returns (bool){
        address staker = msg.sender;

        require(isExistEntry(staker), "The Address is not Exist");

        stake[staker].deposit_amount = 0;
        stake[staker].rewardUpload = 0;
        return true;
    }

    //手动分红(只能管理员使用，主要用于测试)
    function reward() public onlyOwner {
        for (uint i = 0; i < activeAddresses.length; i++) {
            stake[activeAddresses[i]].rewardAmount += stake[activeAddresses[i]].deposit_amount * rewardPercent / 10000;
        }
    }

    //获取上传周期
    function getUploadCount() public view returns (uint){
        return uploadcount;
    }

    //获取上传间隔时间
    function getUploadTime() public view returns (uint){
        return uploadtime;
    }

    //获取手续费
    function getGasAmount() public view returns (uint){
        return gasAmount;
    }

    //获取分红比例（管理员权限）
    function getRewardPercent() public view onlyOwner returns (uint){
        return rewardPercent;
    }

    //停用
    function getReturnPercent() public view onlyOwner returns (uint){
        return returnPercent;
    }

    //查询质押金额
    //@Param _addr 挖矿合约地址
    function getDepositAmount(address _addr) public view returns (uint){
        return stake[_addr].deposit_amount;
    }

    //查询分红金额
    //@Param _addr 挖矿合约地址
    function getRewardAmount(address _addr) public view returns (uint){
        return stake[_addr].rewardAmount;
    }


    //查询所有用户
    function getAllUser() public view returns (address [] memory){
        return activeAddresses;
    }

    //获取用户的信息
    //@Param _addr 挖矿合约地址
    function getClientInfos(address _addr) public view returns (ClientInfo[] memory){
        return clientInfos[_addr];
    }

    //获取用户总上传次数的信息
    //@Param _addr 挖矿合约地址
    function getAllUploadCount(address _addr) public view returns (uint){
        return stake[_addr].AllUploadCount;
    }

    //获取用户总提币金额的信息
    //@Param _addr 挖矿合约地址
    function getAllReturnAmount(address _addr) public view returns (uint){
        return stake[_addr].AllReturnAmount;
    }

    //获取用户历史总分红金额
    //@Param _addr 挖矿合约地址
    function getAllRewardAmount(address _addr) public view returns (uint){
        return stake[_addr].AllRewardAmount;
    }

    function getVerifyTimestamp(address verifyAddress) view public returns (uint256){
        return verifyNode[verifyAddress];
    }
}