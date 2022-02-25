/**
 *Submitted for verification at Etherscan.io on 2022-02-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface FFFReward is ERC20 {
    function newOrder(address user, uint num1) external returns(bool);

    function burn(address account, uint amount) external returns(bool);
}

library SafeMath {
    /* 加 : a + b */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    /* 减 : a - b */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    /* 减 : a - b */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }
    /* 乘 : a * b */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    /* 除 : a / b */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    /* 除 : a / b */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
    /* 除 : a / b */
    function divFloat(uint256 a, uint256 b,uint decimals) internal pure returns (uint256){
        require(b > 0, "SafeMath: division by zero");
        uint256 aPlus = a * (10 ** uint256(decimals));
        uint256 c = aPlus/b;
        return c;
    }
    /* 末 : a % b */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    /* 末 : a % b */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    /*
     * @dev 转换位
     * @param amout 金额
     * @param decimals 代币的精度
     */
    function toWei(uint256 amout, uint decimals) internal pure returns (uint256){
        return mul(amout,10 ** uint256(decimals));
    }

    /*
     * @dev 回退位
     * @param amout 金额
     * @param decimals 代币的精度
     */
    function backWei(uint256 amout, uint decimals) internal pure returns (uint256){
        return div(amout,(10 ** uint256(decimals)));
    }
}

contract Common {
    address internal owner;                                 //合约创建者
    address internal approveAddress;                        //授权地址
    bool internal running = true;                           //true:开启(默认); false:关闭;

    modifier onlyOwner(){
        require(msg.sender == owner,"Modifier: The caller is not the creator");
        _;
    }
    modifier onlyApprove(){
        require(msg.sender == approveAddress || msg.sender == owner,"Modifier: The caller is not the approveAddress or creator");
        _;
    }
    modifier isRunning {
        require(running,"Modifier: System maintenance in progress");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /*
     * @dev 设置授权的地址
     * @param externalAddress 外部地址
     */
    function setApproveAddress(address externalAddress) public onlyOwner returns (bool) {
        approveAddress = externalAddress;
        return true;
    }
    /*
     * @dev 设置合约运行状态
     * @param state true:开启; false:关闭;
     */
    function setRunning (bool state) public onlyApprove returns (bool) {
        running = state;
        return true;
    }

    /* 获取授权的地址 */
    function getApproveAddress() internal view returns(address) {
        return approveAddress;
    }

    /* 获取合约运行的状态 */
    function getRunning() internal view returns(bool) {
        return running;
    }
}

contract FFFExchange is Common {
    using SafeMath for uint256;
    
    constructor() {
        owner = msg.sender;
        usdt = ERC20(0x70E80beC8087DD6931f15E5F3F2e2d3cfd9ad31e);
        fff = ERC20(0xa300ac099775Bb545c3e284E6A5AB3017650cB36);
        ffft = ERC20(0xfc9fb1dBF7E8B01F1889cc3f5CDd5960768F20B5);
        fffr = FFFReward(0x795EbfEbebc9147C6d9c6C2127e79451088BC2e8);
    }

    mapping(address => uint256) public exchangePerAddressAmount;                    // 单个地址使用u兑换fff的数量

    uint256 public ffftTotalExchangedFromfff;                                       // 通过fff兑换到3ft的总数量
    mapping(address => uint256) public ffftExchangedFromfff;                        // 单个地址通过fff兑换到3ft的数量
    uint256 public fffrTotalExchangedFromfffr;                                      // 通过fffr兑换到3ft的总数量
    mapping(address => uint256) public ffftExchangedFromfffr;                       // 单个地址通过fffr兑换到3ft的数量

    event ExchangeUTo3ft(address toAddress, uint256 usdtAmount, uint256 fffAmount, uint256 ffftAmount, address caller);             // 事件 u兑换fff fff兑换ffft
    event Exchange3fTo3ft(address toAddress, uint256 fffAmount, uint256 ffftAmount, address caller);                                // 事件 fff兑换ffft
    event Exchange3frTo3ft(address toAddress, uint256 fffrAmount, uint256 ffftAmount, address caller);                              // 事件 fffr兑换ffft

    /*  
    * u兑换fff，fff兑换ffft
    */
    function exchangeU2ffftTo(address toAddress, uint256 usdtAmount) public isRunning returns(bool) {
        require(isFirstStage, "Is not first stage");                                                                                        // 判断当前是否为第一阶段
        require(toAddress != address(0), "Out address must not be null");                                                                   // 接收地址不能为0
        require(usdtAmount <= exchangeableAmount(toAddress), "Out address out of max exchange u amount");                                   // 兑换最多使用1000u 
        require(usdtAmount.mod(exchangeu2fffLimit) == 0, "Must be multiple");                                                               // 发送u的数量必须是1的倍数
        require(usdt.balanceOf(msg.sender) >= usdtAmount, "Insufficient usdt balance in msg.sender");                                       // 判断用户u的余额
        uint256 fffAmount = usdtAmount.mul(exchangeConfigU2fff);
        require(fff.balanceOf(address(this)) >= fffAmount, "Insufficient fff balance in contract");                                         // 判断合约内fff余额
        uint256 ffftAmount = fffAmount.mul(exchangeConfigfff2ffft);
        require(ffft.balanceOf(address(this)) >= ffftAmount, "Insufficient ffft balance in contract");                                      // 判断合约内ffft余额
        
        exchangePerAddressAmount[toAddress] =  exchangePerAddressAmount[toAddress].add(usdtAmount);                                         // 记录兑换的u的数量
        ffftExchangedFromfff[toAddress] = ffftExchangedFromfff[toAddress].add(ffftAmount);                                                  // 记录fff兑换的3ft数量
        ffftTotalExchangedFromfff = ffftTotalExchangedFromfff.add(ffftAmount);                                                              // 记录fff兑换3ft总兑换数量
        usdt.transferFrom(msg.sender, address(this), usdtAmount);                                                                           // 发送用户的u到合约
        fff.transfer(blackHole, fffAmount);                                                                                                 // 发送fff到黑洞地址
        ffft.transfer(toAddress, ffftAmount);                                                                                               // 发送ffft到用户指定地址
        emit ExchangeUTo3ft(toAddress, usdtAmount, fffAmount, ffftAmount, msg.sender);
        fffr.newOrder(toAddress, ffftAmount);                                                                                               // 调用外部合约发送奖励
        return true;
    }

    /*  
    * u兑换fff，fff兑换ffft
    */
    function exchangeU2ffft(uint256 usdtAmount) public returns(bool) {
        return exchangeU2ffftTo(msg.sender, usdtAmount);
    }

    /*  
    * 查询第一阶段可兑换的数量 单位：U
    */
    function exchangeableAmount(address target) public view returns(uint256) {
        return exchangePerAddressLimit - exchangePerAddressAmount[target];
    }

    /*  
    * fff兑换ffft
    */
    function exchangefff2ffftTo(address toAddress, uint256 fffAmount) public isRunning returns(bool) {
        require(!isFirstStage, "Is first stage");                                                                                           // 判断当前是否为第一阶段
        require(toAddress != address(0), "Out address must not be null");                                                                   // 接收地址不能为0

        require(fff.balanceOf(msg.sender) >= fffAmount, "Insufficient fff balance in msg.sender");                                          // 判断用户fff的余额
        uint256 ffftAmount = fffAmount.mul(fff2ffftRatio());                                                                                  // 计算最终兑换多少ffft
        require(ffft.balanceOf(address(this)) >= ffftAmount, "Insufficient ffft balance in contract");                                      // 判断合约内ffft余额
        
        ffftExchangedFromfff[toAddress] = ffftExchangedFromfff[toAddress].add(ffftAmount);                                                  // 记录fff兑换的3ft数量
        ffftTotalExchangedFromfff = ffftTotalExchangedFromfff.add(ffftAmount);                                                              // 记录fff兑换3ft总兑换数量
        fff.transferFrom(msg.sender, blackHole, fffAmount);                                                                                 // 发送fff到黑洞地址
        ffft.transfer(toAddress, ffftAmount);                                                                                               // 发送ffft到用户指定地址
        emit Exchange3fTo3ft(toAddress, fffAmount, ffftAmount, msg.sender);
        fffr.newOrder(toAddress, ffftAmount);                                                                                               // 调用外部合约发送奖励
        return true;
    }

    /*
    * 查询当前fff兑换ffft的比例：1 fff：x ffft
    */
    function fff2ffftRatio() public view returns(uint256) {
        return ffft.balanceOf(address(this)).div(poolOutputPerDay).div(expectedMiningDay);
    }

    /*
    * fff兑换ffft
    */
    function exchangefff2ffft(uint256 fffAmount) public returns(bool) {
        return exchangefff2ffftTo(msg.sender, fffAmount);
    }

    /*
    * fffr兑换ffft
    */
    function exchangefffr2ffft(uint256 fffrAmount) public isRunning returns(bool) {                                                        
        require(fffrAmount <= exchangeablefffrAmount(msg.sender), "Out of max exchange limit");                                             // 判断兑换是否超过最高限制
        require(fffr.balanceOf(msg.sender) >= fffrAmount, "Insufficient fffrAmount balance in msg.sender");                                 // 判断用户fffr的余额
        uint256 ffftAmount = fffrAmount.mul(exchangeConfigfffr2ffft);                                                                       // 计算最终兑换多少ffft
        require(ffft.balanceOf(address(this)) >= ffftAmount, "Insufficient ffft balance in contract");                                      // 判断合约内ffft余额
        
        ffftExchangedFromfffr[msg.sender] = ffftExchangedFromfffr[msg.sender].add(ffftAmount);                                              // 记录fffr兑换3ft兑换数量
        fffrTotalExchangedFromfffr = fffrTotalExchangedFromfffr.add(ffftAmount);                                                            // 记录fffr兑换3ft总兑换数量
        fffr.burn(msg.sender, fffrAmount);                                                                                                  // 发送fffr到黑洞地址
        ffft.transfer(msg.sender, ffftAmount);                                                                                              // 发送ffft到调用者地址
        emit Exchange3frTo3ft(msg.sender, fffrAmount, ffftAmount, msg.sender);
        return true;
    }

    /*
    * 查询当前可以兑换的最大fffr数量：单位fffr
    */
    function exchangeablefffrAmount(address target) public view returns(uint256) {
        return ffftExchangedFromfff[target].mul(exchangeConfigfffr2ffftLimitRatio)
            .sub(ffftExchangedFromfffr[target].div(exchangeConfigfffr2ffft));
    }

    /*
    * 查询已经兑换到的ffft的数量
    */
    function exchangedAmount(address target) public view returns(uint256) {
        return ffftExchangedFromfff[target].add(ffftExchangedFromfffr[target]);
    }

    /*---------------------------------------------------管理运营-----------------------------------------------------------*/

    bool private isFirstStage = true;                                       //[设置] 是否是第一阶段 默认为第一阶段：true
    uint256 private exchangeu2fffLimit = 1 * (10 ** 18);                    //[设置] 限制u兑换fff下限 默认：最小1，且为1的倍数 单位u
    uint256 private exchangefffLimit = 0.01 * (10 ** 18);                   //[设置] 限制fff兑换下限 默认：0.01 单位fff   
    address private blackHole = address(0);                                 //[设置] 销毁黑洞地址 默认：address(0)

    /*-------第一阶段--------*/
    uint256 private exchangePerAddressLimit = 1000 * (10 ** 18);            //[设置] 限制每个地址兑换上限 默认：1000 单位U
    uint private exchangeConfigU2fff = 4;                                   //[设置] 1 u兑换fff的数量 默认：4
    uint private exchangeConfigfff2ffft = 1;                                //[设置] 1 fff兑换ffft的数量 默认：1

    /*-------第二阶段--------*/
    uint256 private poolOutputPerDay = 24000 * (10 ** 18);                  //[设置] 权益池每日产出 默认：24000
    uint private expectedMiningDay = 120;                                   //[设置] 预计挖完时间 默认：120

    uint private exchangeConfigfffr2ffft = 1;                               //[设置] 1 fffr兑换ffft的数量 默认：1
    uint private exchangeConfigfffr2ffftLimitRatio = 3;                     //[设置] 1 fffr兑换ffft的数量限制 是fff兑换ffft数量的3倍 默认：3

    ERC20 usdt;                                     //[设置]  配置USDT代币
    ERC20 fff;                                      //[设置]  配置项目代币
    ERC20 ffft;                                     //[设置]  配置算力凭证代币
    FFFReward fffr;                                     //[设置]  配置推广权益奖励代币 配置调用奖励合约 FFF兑换FFFT的时候调用

    function setExchangeContract(address usdtContract,address fffContract,address ffftContract,address fffrContract) public onlyApprove {
        usdt = ERC20(usdtContract);
        fff = ERC20(fffContract);
        ffft = ERC20(ffftContract);
        fffr = FFFReward(fffrContract);
    }

    function exchangeContract() public view onlyApprove returns (ERC20, ERC20, ERC20, FFFReward){
        return (usdt, fff, ffft, fffr);
    }

    function setExchangeConfigs(bool firstStage, uint256 u2fffLimit, uint256 fffLimit, address blakHole, uint256 perAddressLimit, 
        uint u2fff, uint fff2ffft, uint256 outputPerDay, uint miningDay, uint fffr2ffft, uint fffr2ffftLimitRatio) public onlyApprove {
        isFirstStage = firstStage;
        exchangeu2fffLimit = u2fffLimit;
        exchangefffLimit = fffLimit;
        blackHole = blakHole;
        exchangePerAddressLimit = perAddressLimit;
        exchangeConfigU2fff = u2fff;
        exchangeConfigfff2ffft = fff2ffft;
        poolOutputPerDay = outputPerDay;
        expectedMiningDay = miningDay;
        exchangeConfigfffr2ffft = fffr2ffft;
        exchangeConfigfffr2ffftLimitRatio = fffr2ffftLimitRatio;
    }

    function setExchangeConfigs(uint256 u2fffLimit, uint256 fffLimit, uint256 perAddressLimit, uint256 outputPerDay) public onlyApprove {
        exchangeu2fffLimit = u2fffLimit;
        exchangefffLimit = fffLimit;
        exchangePerAddressLimit = perAddressLimit;
        poolOutputPerDay = outputPerDay;
    }

    function setFirstStage(bool firstStage) public onlyApprove {
        isFirstStage = firstStage;
    }

    function exchangeConfigs() public view onlyApprove returns (bool, uint256, uint256, address, uint256, uint, uint, uint256, uint, uint, uint){
        return (isFirstStage, exchangeu2fffLimit, exchangefffLimit, blackHole, exchangePerAddressLimit, exchangeConfigU2fff,
        exchangeConfigfff2ffft, poolOutputPerDay, expectedMiningDay, exchangeConfigfffr2ffft, exchangeConfigfffr2ffftLimitRatio);
    }

    /*
     * @dev  修改 | 授权者调用 | 提取平台的Token
     * @param contractAddress 合约地址
     * @param outAddress 取出地址
     * @param amountToWei 交易金额
     */
    function poolOutTokens(address contractAddress,address outAddress, uint amountToWei) public onlyApprove {
        ERC20(contractAddress).transfer(outAddress,amountToWei);
    }

}