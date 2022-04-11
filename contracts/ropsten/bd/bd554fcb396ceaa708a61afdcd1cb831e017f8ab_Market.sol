// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.10;

import "../SafeMath.sol";
import "../Strings.sol";
import "../DateTime.sol";
import "../IERC20.sol";
import "../AuthorityControlled.sol";

contract Market is AuthorityControlled {
    using SafeMath  for uint256;
    using Strings   for string;

    struct NftRule {
        uint256 direct;                                 // 直接解锁到账，分母是10000
        uint256 lock;                                   // 锁定期
        uint256 cycle;                                  // 解锁期
    }

    struct NftRecord {
        uint256 time;                                   // 奖励创建时间
        uint256 lock;                                   // 奖励锁定时间
        uint256 day;                                    // 开始计息的天份
        uint256 start;                                  // 开始计息的位置(月)
        uint256 total;                                  // 总数量
        uint256 done;                                   // 已发放数量
        uint256 await;                                  // 未发放数量
        uint256 stage;                                  // 每期发放数量
        uint256 cycle;                                  // 总周期
        uint256 past;                                   // 发放周期
        uint256 future;                                 // 未发放周期
        uint256 end;                                    // 截止计息的位置(月)
    }

    struct NftDetail {
        address addr;                                   // 奖励创建时间
        uint256 stage;                                  // 奖励锁定时间
        uint256 amount;                                 // 开始计息的天份
        uint256 time;                                   // 总数量
    }

    struct OpenRecord {
        address addr;                                   // 奖励创建时间
        uint256 amount;                                 // 奖励锁定时间
        uint256 price;                                  // 开始计息的天份
        uint256 volume;                                 // 开始计息的位置(月)
        uint256 time;                                   // 总数量
    }

    DateTime dateTime = new DateTime();                 // 时间处理工具
    NftRule public nftRule;                             // NFT拍卖规则

    uint256 public nft_index = 0;
    uint256 public open_index = 0;

    uint256 public startTime;                           // 公售开始时间
    uint256 public endTime;                             // 公售结束时间

    uint256 public min;                                 // 公开销售最小买入量
    uint256 public max;                                 // 公开销售最大买入量
    uint256 public price;                                // ETH兑换平台币比例
    uint256 public total;                               // 公开销售最大数量
    uint256 public sold;                                // 已卖出数量
    uint256 public usable;                              // 未卖出数量

    uint256 public asset;                               // 累计收到的ETH数量

    IERC20  public token;                               // 平台币合约
    address public auction;                             // 拍卖合约地址
    address public output;                              // 平台币拥有者地址

    mapping(address => NftRecord)   public nftRecords;  // 领奖列表
    mapping(uint256 => NftDetail)   public nftDetails;  // 领奖记录
    mapping(uint256 => OpenRecord)  public openRecords; // 领奖记录

    constructor(address authority_) AuthorityControlled(authority_) {
        startTime   = block.timestamp;                  //当前区块时间戳
        endTime     = block.timestamp.add(8_640_000);   // 当前区块后100天
        min         = 10;
        max         = 10000;
        price       = 20000000000000000;
        total       = 21000000000000;
        usable      = 21000000000000;
        nftRule 	= NftRule({
            direct  : 1200, 
            lock    : 3, 
            cycle   : 6
        });
    }

    // 初始化 公开售卖 开始和结束时间
    function range(uint8 _type, uint256 _time) public returns (bool) {
        require(1 == _type || 2 == _type, "Incorrect time type");
        if (1 == _type) {
            startTime = _time;
        } else if (2 == _type) {
            endTime = _time;
        } else {
            require(false, "Incorrect time type");
        }
        return true;
    }

    // 初始化 公开售卖 规则
    function plan(uint256 _min, uint256 _max, uint256 _price, uint256 _total) public returns (bool) {
        min     = _min;     // 公开售卖专用，最少购买量
        max     = _max;     // 公开售卖专用，最多购买量
        price   = _price;   // 折合ETH价格
        total   = _total;   // 总卖出数量限制
        usable  = _total;   // 剩余售卖数量
        return true;
    }

    // 设置 NFT 拍卖 奖励平台币规则
    function setNftRule(uint256 _direct, uint256 _lock, uint256 _cycle) public returns (bool) {
        require(1 <= _direct && _direct <= 10000, "Earnings time not yet reached");
        nftRule = NftRule({
            direct  : _direct,  // 直接解锁百分比，1000是10%, 10000是100%
            lock    : _lock,    // 锁仓时长(月)
            cycle   : _cycle    // 释放时长(月)
        });
        return true;
    }

    // 修改 外部 合约地址
    function modify(uint8 _type, address _addr) public returns (bool) {
        if (1 == _type) {
            token = IERC20(_addr);  // 平台币合约
        } else if (2 == _type) {
            auction = _addr;        // 拍卖地址
        } else if (3 == _type) {
            output = _addr;         // 提现地址
        }
        return true;
    }

    // NFT拍卖数量进入
    function add(address _receive, uint256 _amount) public returns (bool) {
        require(auction != msg.sender, "The initiator is illegal"); // 检查是否是由拍卖合约调用
        require(
            total   >   sold                &&                      // 总数量 > 已发放数量
            total   ==  sold.add(usable)    &&                      // 总数量 = 已发放数量 + 未发放数量
            0       <   usable              &&                      // 0 < 未发放数量
            0       <=  usable.sub(_amount) &&                      // 可用数量减去购买数量必须大于或等于0
            total   >=  sold.add(_amount),                          // 已发放数量 + 领取数量 <= 总数量
            "Illegal sales"                                         // 返回检查信息
        );

        uint256 done    = _amount.mul(nftRule.direct).div(10000);   // 直接解锁数量
        uint256 await   = _amount.sub(done);                        // 剩余解锁数量
        uint256 stage   = await.div(nftRule.cycle);                 // 每期解锁数量

        bool flag = token.transferFrom(output, _receive, done);     // 我 秦始皇 打钱
        require(flag, "Acquisition Token failed");

        uint256 year    = dateTime.getYear();
        uint256 month   = dateTime.getMonth();
        uint256 start   = year.mul(12);                             // 根据年份换算成月份
        start = start.add(month);                                   // 加上当前月
        start = start.add(nftRule.lock);                            // 加上锁定时长(月)

        uint256 end = start.add(nftRule.cycle);
        nftRecords[_receive] = NftRecord({
            time    : block.timestamp,
            lock    : nftRule.lock,
            day     : dateTime.getDay(),
            start   : start,
            total   : _amount,
            done    : done,
            await   : await,
            stage   : stage,
            cycle   : nftRule.cycle,
            past    : 0,
            future  : nftRule.cycle,
            end     : end
        });
        sold    = sold.add(_amount);                                // 增加已卖出数量
        usable  = usable.sub(_amount);                              // 减少未卖出数量
        return true;
    }

    // 领奖
    function draw() public returns (bool) {
        address addr = msg.sender;

        NftRecord memory nftRecord = nftRecords[addr];
        require(nftRecord.day != 0, "Do you have any rewards to receive");  // 你没有奖励可领取

        uint256 year    = dateTime.getYear();
        uint256 month   = dateTime.getMonth();
        uint256 day     = dateTime.getDay();

        uint256 share   = year.mul(12);                                     // 年份转为月份
        share = share.add(month);                                           // 加上当前月

        if (day < nftRecord.day) share = share.sub(1);                      // 如果今天小于领奖的天，则月份减1
        require(
            0 < share && share > nftRecord.start,                           // 月份要大于0并且月份要大于上次领取的月份
            "You have no new rewards to claim"
        );                                                                  // 您还没有产生新的奖励可领取

        uint256 actual = share.sub(nftRecord.start);                        // 计算实际可领取奖励的月份
        uint256 amount = actual.mul(nftRecord.stage);                       // 计算可领取的奖励数量

        bool flag = token.transferFrom(output, addr, amount);               // 我 秦始皇 打钱
        require(flag, "Failed to make money");                              // 检查打钱是否成功

        nftDetails[nft_index++] = NftDetail({
            addr    : addr,
            stage   : actual,
            amount  : amount,
            time    : block.timestamp
        });

        nftRecords[addr] = NftRecord({
            time    : nftRecord.time,
            lock    : nftRecord.lock,
            day     : nftRecord.day,
            start   : nftRecord.start.add(share),
            total   : nftRecord.total,
            done    : nftRecord.done.add(amount),
            await   : nftRecord.await.sub(amount),
            stage   : nftRecord.stage,
            cycle   : nftRecord.cycle,
            past    : nftRecord.past.add(share),
            future  : nftRecord.future.sub(share),
            end     : nftRecord.end
        });
        return true;
    }

    // 公开售卖
    function open() public payable returns (bool) {
        require(0 < msg.value, "Your eth quantity is insufficient");                    // 你的ETH不足
        require(startTime < block.timestamp, "Public sale has not started");            // 你的ETH不足
        require(endTime > block.timestamp, "Public sale has ended");                    // 你的ETH不足

        uint256 value = msg.value;                                                      // 获取用户的 ETH 数量
        uint256 volume = value.div(price);                                              // 计算能买到多少数量的代币

        require(min <= volume, "Purchase quantity below minimum limit");                // 检查购买数量是否大于最小购买数量
        require(max >= volume, "Purchase quantity is higher than the maximum limit");   // 检查购买数量是否小于最大购买数量

        require(
            total   >   sold                &&                                          // 总数量 > 已发放数量
            total   ==  sold.add(usable)    &&                                          // 总数量 = 已发放数量 + 未发放数量
            0       <   usable              &&                                          // 0 < 未发放数量
            0       <=  usable.sub(volume)  &&                                          // 可用数量减去购买数量必须大于或等于0
            total   >=  sold.add(volume),                                               // 已发放数量 + 领取数量 <= 总数量
            "Illegal sales"                                                             // 返回检查信息
        );

        bool flag = token.transferFrom(output, msg.sender, volume);                     // 4:向用户发送代币
        require(flag, "Failed to make money");                                          // 检查代币是否发送成功

        asset   = asset.add(value);                                                     // 累加收到的ETH
        sold    = sold.add(volume);                                                     // 增加已卖出数量
        usable  = usable.sub(volume);                                                   // 减少未卖出数量

        openRecords[open_index++] = OpenRecord({
            addr    : msg.sender,
            amount  : value,
            price   : price,
            volume  : volume,
            time    : block.timestamp
        });

        return true;                                                                    // 5:返回购买成功
    }

    // 提现
    function withdraw(address _to) external payable returns (bool) {
        require(_to != address(0), "XCC: invalid status for withdrawn.");               // 检查接收地址是否合法
        require(0 < asset, "XCC: invalid status for withdrawn.");                       // 检查 未提取的 ETH 数量是否大于 0

        payable(address(_to)).transfer(asset);                                          // 提取 ETH 到指定地址

        return true;                                                                    // 返回执行状态
    }
}