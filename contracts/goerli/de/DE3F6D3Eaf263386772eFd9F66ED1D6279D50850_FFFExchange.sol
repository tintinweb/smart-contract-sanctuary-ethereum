// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./OwnableUpgradeable.sol";

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
    /* add : a + b */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    /* sub : a - b */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    /* sub : a - b */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }
    /* mul : a * b */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    /* div : a / b */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    /* div : a / b */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
    /* divFloat : a / b */
    function divFloat(uint256 a, uint256 b,uint decimals) internal pure returns (uint256){
        require(b > 0, "SafeMath: division by zero");
        uint256 aPlus = a * (10 ** uint256(decimals));
        uint256 c = aPlus/b;
        return c;
    }
    /* mod : a % b */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    /* mod : a % b */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    /*
     * @dev to Wei
     * @param amout amount
     * @param decimals decimals
     */
    function toWei(uint256 amout, uint decimals) internal pure returns (uint256){
        return mul(amout,10 ** uint256(decimals));
    }

    /*
     * @dev back Wei 
     * @param amout amout
     * @param decimals decimals
     */
    function backWei(uint256 amout, uint decimals) internal pure returns (uint256){
        return div(amout,(10 ** uint256(decimals)));
    }
}

contract Common {
    address internal commonOwner;                           // creator 
    address internal approveAddress;                        // approve address
    bool internal running = true;                           // true:open(default); false:close;

    modifier onlyCommonOwner(){
        require(msg.sender == commonOwner,"Modifier: The caller is not the creator");
        _;
    }
    modifier onlyApprove(){
        require(msg.sender == approveAddress || msg.sender == commonOwner,"Modifier: The caller is not the approveAddress or creator");
        _;
    }
    modifier isRunning {
        require(running,"Modifier: System maintenance in progress");
        _;
    }

    constructor() {
        commonOwner = msg.sender;
    }

    /*
     * @dev set approve address
     * @param externalAddress external address
     */
    function setApproveAddress(address externalAddress) public onlyCommonOwner returns (bool) {
        approveAddress = externalAddress;
        return true;
    }
    /*
     * @dev set contract is running
     * @param state true: able; false:disable;
     */
    function setRunning (bool state) public onlyApprove returns (bool) {
        running = state;
        return true;
    }

    /* get approve address */
    function getApproveAddress() public view returns(address) {
        return approveAddress;
    }

    /* get contract is running */
    function getRunning() public view returns(bool) {
        return running;
    }
}

contract FFFExchange is Common,Initializable,OwnableUpgradeable {
    using SafeMath for uint256;

    /* Contract config */
    ERC20 usdt;                                         //[设置]  配置USDT代币
    ERC20 fff;                                          //[设置]  配置项目代币
    ERC20 ffft;                                         //[设置]  配置算力凭证代币
    FFFReward fffr;                                     //[设置]  配置推广权益奖励代币 配置调用奖励合约 FFF兑换FFFT的时候调用

    /* Admin config */
    bool private isFirstStage;                                      //[设置] 是否是第一阶段 默认为第一阶段：true
    uint256 private configU2FFFLimit;                               //[设置] 限制u兑换fff下限 默认：最小1，且为1的倍数 单位u
    uint256 private configFFFMinLimit;                              //[设置] 限制fff兑换下限 默认：0.01 单位fff
    address private blackHole = address(0);                         //[设置] 销毁黑洞地址 默认：address(0)

    /*------- First Stage --------*/
    uint256 private exchangeableULimit;                             //[设置] 限制每个地址兑换上限 默认：1000 单位U
    uint private configU2FFF;                                       //[设置] 1 u兑换fff的数量 默认：4
    uint private configFFF2FFFT;                                    //[设置] 1 fff兑换ffft的数量 默认：1

    /*-------第二阶段--------*/
    uint256 private poolOutputPerDay;                               //[设置] 权益池每日产出 默认：24000
    uint private expectedMiningDay;                                 //[设置] 预计挖完时间 默认：120

    uint private configFFFR2FFFT;                                   //[设置] 1 fffr兑换ffft的数量 默认：1
    uint private configFFFTLimitRatio;                              //[设置] 1 fffr兑换ffft的数量限制 是fff兑换ffft数量的3倍 默认：3

    /* V */
    mapping(address => uint256) private exchangedU;                 // 单个地址使用u兑换fff的数量

    uint256 private ffftTotalExchangedFromfff;                                       // 通过fff兑换到3ft的总数量
    mapping(address => uint256) private ffftExchangedFromfff;                        // 单个地址通过fff兑换到3ft的数量
    uint256 private ffftTotalExchangedFromfffr;                                      // 通过fffr兑换到3ft的总数量
    mapping(address => uint256) private ffftExchangedFromfffr;                       // 单个地址通过fffr兑换到3ft的数量
    uint256 private fffrTotalExchanged;                                              // 通过fffr兑换总数量
    mapping(address => uint256) private fffrExchanged;                               // 单个地址fffr兑换数量

    function initialize() public initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        commonOwner = msg.sender;
        usdt = ERC20(0x70E80beC8087DD6931f15E5F3F2e2d3cfd9ad31e);
        fff = ERC20(0xa300ac099775Bb545c3e284E6A5AB3017650cB36);
        ffft = ERC20(0xfc9fb1dBF7E8B01F1889cc3f5CDd5960768F20B5);
        fffr = FFFReward(0xb16CE40a222aDEc8b29e78962A83D9c9D5290264);
        isFirstStage = true;                                        //[设置] 是否是第一阶段 默认为第一阶段：true
        configU2FFFLimit = 1 * (10 ** 18);                          //[设置] 限制u兑换fff下限 默认：最小1，且为1的倍数 单位u
        configFFFMinLimit = 0.01 * (10 ** 18);                      //[设置] 限制fff兑换下限 默认：0.01 单位fff
        blackHole = address(0);                                     //[设置] 销毁黑洞地址 默认：address(0)

        /*-------第一阶段--------*/
        exchangeableULimit = 1000 * (10 ** 18);                     //[设置] 限制每个地址兑换上限 默认：1000 单位U
        configU2FFF = 4;                                            //[设置] 1 u兑换fff的数量 默认：4
        configFFF2FFFT = 1;                                         //[设置] 1 fff兑换ffft的数量 默认：1

        /*-------第二阶段--------*/
        poolOutputPerDay = 24000;                                   //[设置] 权益池每日产出 默认：24000
        expectedMiningDay = 120;                                    //[设置] 预计挖完时间 默认：120

        configFFFR2FFFT = 1;                                        //[设置] 1 fffr兑换ffft的数量 默认：1
        configFFFTLimitRatio = 3;                                   //[设置] 1 fffr兑换ffft的数量限制 是fff兑换ffft数量的3倍 默认：3

    }

    event Exchange(address indexed contractAddress, address indexed toAddress, uint256 inAmount,uint256 outAmount, address caller);             // event exchange



    /*---------------------------------------------------主动接口-----------------------------------------------------------*/

    /*
     * @dev  exchange | public | exchange
     * @param contractAddress contract
     * @param outAddress out address
     * @param amountToWei amount to wei
     */
    function exchange(address contractAddress, address toAddress, uint256 amountToWei) public isRunning returns(bool) {
        if (contractAddress == address(usdt)) {
            exchangeU2ffftTo(toAddress, amountToWei);
        } else if (contractAddress == address(fff)) {
            exchangefff2ffftTo(toAddress, amountToWei);
        } else if (contractAddress == address(fffr)) {
            exchangefffr2ffft(amountToWei);
        } else {
            require(false, "Contract address error");
        }
        return true;
    }

    /*
    * u兑换fff，fff兑换ffft
    */
    function exchangeU2ffftTo(address toAddress, uint256 usdtAmount) internal returns(bool) {
        require(isFirstStage, "Is not first stage");                                                                                        // 判断当前是否为第一阶段
        require(toAddress != address(0), "Out address must not be null");                                                                   // 接收地址不能为0
        require(usdtAmount <= exchangeableU(toAddress), "Out address out of max exchange u amount");                                        // 兑换最多使用1000u
        require(usdtAmount.mod(configU2FFFLimit) == 0, "Must be a multiple of 1");                                                          // 发送u的数量必须是1的倍数
        require(usdt.balanceOf(msg.sender) >= usdtAmount, "Insufficient usdt balance in msg.sender");                                       // 判断用户u的余额
        uint256 fffAmount = usdtAmount.mul(configU2FFF);
        require(fffAmount >= configFFFMinLimit, "Exchanged fff amount so small");                                                           // 兑换的数额太小
        require(fff.balanceOf(address(this)) >= fffAmount, "Insufficient fff balance in contract");                                         // 判断合约内fff余额
        uint256 ffftAmount = fffAmount.mul(configFFF2FFFT);
        require(ffft.balanceOf(address(this)) >= ffftAmount, "Insufficient ffft balance in contract");                                      // 判断合约内ffft余额

        exchangedU[toAddress] =  exchangedU[toAddress].add(usdtAmount);                                                                     // 记录兑换的u的数量
        ffftExchangedFromfff[toAddress] = ffftExchangedFromfff[toAddress].add(ffftAmount);                                                  // 记录fff兑换的3ft数量
        ffftTotalExchangedFromfff = ffftTotalExchangedFromfff.add(ffftAmount);                                                              // 记录fff兑换3ft总兑换数量
        usdt.transferFrom(msg.sender, address(this), usdtAmount);                                                                           // 发送用户的u到合约
        fff.transfer(blackHole, fffAmount);                                                                                                 // 发送fff到黑洞地址
        ffft.transfer(toAddress, ffftAmount);                                                                                               // 发送ffft到用户指定地址
        emit Exchange(address(usdt), toAddress, usdtAmount, ffftAmount, msg.sender);
        //fffr.newOrder(toAddress, ffftAmount);                                                                                             // 调用外部合约发送奖励
        return true;
    }

    /*
    * fff兑换ffft
    */
    function exchangefff2ffftTo(address toAddress, uint256 fffAmount) internal returns(bool) {
        require(!isFirstStage, "Is first stage");                                                                                           // 判断当前是否为第一阶段
        require(toAddress != address(0), "Out address must not be null");                                                                   // 接收地址不能为0

        require(fffAmount >= configFFFMinLimit, "Exchanged fff amount so small");                                                           // 兑换的数额太小
        require(fff.balanceOf(msg.sender) >= fffAmount, "Insufficient fff balance in msg.sender");                                          // 判断用户fff的余额

        uint256 ffftAmount = fffAmount.mul(fff2ffftRatio()).div(10 ** 18);                                                                  // 计算最终兑换多少ffft
        require(ffft.balanceOf(address(this)) >= ffftAmount, "Insufficient ffft balance in contract");                                      // 判断合约内ffft余额

        ffftExchangedFromfff[toAddress] = ffftExchangedFromfff[toAddress].add(ffftAmount);                                                  // 记录fff兑换的3ft数量
        ffftTotalExchangedFromfff = ffftTotalExchangedFromfff.add(ffftAmount);                                                              // 记录fff兑换3ft总兑换数量
        fff.transferFrom(msg.sender, blackHole, fffAmount);                                                                                 // 发送fff到黑洞地址
        ffft.transfer(toAddress, ffftAmount);                                                                                               // 发送ffft到用户指定地址
        emit Exchange(address(fff), toAddress, fffAmount, ffftAmount, msg.sender);
        //fffr.newOrder(toAddress, ffftAmount);                                                                                             // 调用外部合约发送奖励
        return true;
    }

    /*
    * fffr兑换ffft
    */
    function exchangefffr2ffft(uint256 fffrAmount) internal returns(bool) {
        require(fffrAmount <= exchangeableFFFR(msg.sender), "Out of max exchange limit");                                             // 判断兑换是否超过最高限制
        require(fffr.balanceOf(msg.sender) >= fffrAmount, "Insufficient fffr balance in msg.sender");                                       // 判断用户fffr的余额
        uint256 ffftAmount = fffrAmount.mul(configFFFR2FFFT);                                                                               // 计算最终兑换多少ffft
        require(ffft.balanceOf(address(this)) >= ffftAmount, "Insufficient ffft balance in contract");                                      // 判断合约内ffft余额

        fffrTotalExchanged = fffrTotalExchanged.add(fffrAmount);                                                                            // 记录已经消耗的3fr数量
        fffrExchanged[msg.sender] = fffrExchanged[msg.sender].add(fffrAmount);                                                              // 记录单个地址消耗的3fr数量
        ffftExchangedFromfffr[msg.sender] = ffftExchangedFromfffr[msg.sender].add(ffftAmount);                                              // 记录fffr兑换3ft兑换数量
        ffftTotalExchangedFromfffr = ffftTotalExchangedFromfffr.add(ffftAmount);                                                            // 记录fffr兑换3ft总兑换数量
        fffr.burn(msg.sender, fffrAmount);                                                                                                  // 发送fffr到黑洞地址
        ffft.transfer(msg.sender, ffftAmount);                                                                                              // 发送ffft到调用者地址
        emit Exchange(address(fff), msg.sender, fffrAmount, ffftAmount, msg.sender);
        return true;
    }

    /*---------------------------------------------------查询接口-----------------------------------------------------------*/

    /*
    * 查询第一阶段可兑换的数量 单位：U
    */
    function exchangeableU(address target) public view returns(uint256) {
        return exchangeableULimit.sub(exchangedU[target]);
    }

    /*
    * 查询当前fff兑换ffft的比例：1 个单位 fff：x 个单位ffft
    */
    function fff2ffftRatio() public view returns(uint256) {
        return exchangedFFFTTotal().div(poolOutputPerDay).div(expectedMiningDay);
    }

    /*
    * 查询当前fff兑换ffft的数量
    */
    function fff2ffftAmount(uint256 fffAmount) public view returns(uint256) {
        return fffAmount.mul(fff2ffftRatio()).div(10 ** 18);
    }

    /*
    * 查询当前可以兑换的最大fffr数量：单位fffr
    */
    function exchangeableFFFR(address target) public view returns(uint256) {
        return ffftExchangedFromfff[target].mul(configFFFTLimitRatio)
        .sub(ffftExchangedFromfffr[target].div(configFFFR2FFFT));
    }

    /*
    * 查询已经兑换到的ffft的数量
    */
    function exchangedFFFT(address target) public view returns(uint256) {
        return ffftExchangedFromfff[target].add(ffftExchangedFromfffr[target]);
    }

    /*
    * 查询所有人兑换到的ffft的数量
    */
    function exchangedFFFTTotal() public view returns(uint256) {
        return ffftTotalExchangedFromfff.add(ffftTotalExchangedFromfffr);
    }

    /*
    * 查询兑换到的FFFR的数量
    */
    function exchangedFFFR(address target) public view returns(uint256) {
        return fffrExchanged[target];
    }

    /*
    * 查询兑换到总的FFFR的数量
    */
    function exchangedFFFRTotal() public view returns(uint256) {
        return fffrTotalExchanged;
    }

    /*
    * 查询FFFR兑换到总的FFFT的数量
    */
    function exchangedFromFFFR(address target) public view returns(uint256) {
        return ffftExchangedFromfffr[target];
    }

    /*
    * 查询FFFR兑换到总的FFFT的数量
    */
    function exchangedFromFFFRTotal() public view returns(uint256) {
        return ffftTotalExchangedFromfffr;
    }

    /*
    * 查询FFFR兑换到总的FFFT的数量
    */
    function exchangedFromFFF(address target) public view returns(uint256) {
        return ffftExchangedFromfff[target];
    }

    /*
    * 查询FFFR兑换到总的FFFT的数量
    */
    function exchangedFromFFFTotal() public view returns(uint256) {
        return ffftTotalExchangedFromfff;
    }

    /*---------------------------------------------------管理运营-----------------------------------------------------------*/

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
        configU2FFFLimit = u2fffLimit;
        configFFFMinLimit = fffLimit;
        blackHole = blakHole;
        exchangeableULimit = perAddressLimit;
        configU2FFF = u2fff;
        configFFF2FFFT = fff2ffft;
        poolOutputPerDay = outputPerDay;
        expectedMiningDay = miningDay;
        configFFFR2FFFT = fffr2ffft;
        configFFFTLimitRatio = fffr2ffftLimitRatio;
    }

    function setExchangeConfigs(uint256 u2fffLimit, uint256 fffLimit, uint256 perAddressLimit, uint256 outputPerDay) public onlyApprove {
        configU2FFFLimit = u2fffLimit;
        configFFFMinLimit = fffLimit;
        exchangeableULimit = perAddressLimit;
        poolOutputPerDay = outputPerDay;
    }

    function setFirstStage(bool firstStage) public onlyApprove {
        isFirstStage = firstStage;
    }

    function exchangeConfigs() public view onlyApprove returns (bool, uint256, uint256, address, uint256, uint, uint, uint256, uint, uint, uint){
        return (isFirstStage, configU2FFFLimit, configFFFMinLimit, blackHole, exchangeableULimit, configU2FFF,
        configFFF2FFFT, poolOutputPerDay, expectedMiningDay, configFFFR2FFFT, configFFFTLimitRatio);
    }

    /*
     * @dev  修改 | 授权者调用 | 提取平台的Token
     * @param contractAddress 合约地址
     * @param outAddress 取出地址
     * @param amountToWei 交易金额
     */
    function extractTokens(address contractAddress,address outAddress, uint amountToWei) public onlyApprove {
        ERC20(contractAddress).transfer(outAddress,amountToWei);
    }

}