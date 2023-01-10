pragma solidity ^0.8.0;
//设计一种叫做减肥的合约
contract Diet {
    //定义一个变量，用来记录目前的体重
    uint256 weight;
    //定义一个变量，用来记录减肥的目标
    uint256 public target;
    //定义一个变量，用来记录减肥的截至时间戳(完成目标)
    uint256 public deadline;
    //一种结构体，用来存储每个人的自律状态，参数包括：地址、目前体重、减肥目标、截至时间戳、质押金额
    struct DietRecord {
        address addr;
        uint256 weight;
        uint256 target;
        uint256 deadline;
        uint256 pledge;
    }
    // 定义一个mapping，用来存储每个人的自律状态
    mapping(address => DietRecord) public dietRecords;

    // 定义一个函数，用来设定自己的减肥目标，设定目标的同时需要发送一定的DIET代币作为保证金
    function setTarget(uint256 _target, uint256 _deadline, uint256 _weight) public payable {
        // 设定目标的同时需要发送一定的DIET代币作为保证金
        require(msg.value >= 0.001 ether, "not enough ether");
        // 设定减肥目标
        require(_target > 0, "target must be greater than 0");
        // 设定截至时间戳
        require(_deadline > block.timestamp, "deadline must be greater than now");

        // 设定自己的减肥目标
        target = _target;
        // 设定自己的截至时间戳
        deadline = _deadline;
        // 设定自己的目前体重
        weight = _weight;
        // 设定自己的减肥状态
        dietRecords[msg.sender] = DietRecord(msg.sender, weight, target, deadline, msg.value);
    }
    //定义一个函数，用来更新自己的减肥状态
    function updateWeight(uint256 _weight) public {
        // 更新自己的减肥状态
        dietRecords[msg.sender].weight = _weight;
    }

    // 定义一个函数，只能在设定目标的时间戳以后一天内开启，用来领取保证金
    function withdraw() public {
        // 只能在设定目标的时间戳以后一天内开启
        require(block.timestamp > deadline + 1 days, "too early");
        // 只能在设定目标的时间戳三天内开启
        require(block.timestamp < deadline + 3 days, "too late");
        // 只能在减肥成功的情况下开启
        require(dietRecords[msg.sender].weight <= dietRecords[msg.sender].target, "not success");
        // 领取保证金
        payable(msg.sender).transfer(dietRecords[msg.sender].pledge);
        // 领取ZILV代币作为激励
        payable(msg.sender).transfer(0.001 ether);
    }
}