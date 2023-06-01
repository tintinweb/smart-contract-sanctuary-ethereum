// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

contract LogContract {
    // 合约拥有者
    address private owner;

    constructor() {
        owner = msg.sender; // 初始化合约拥有者
    }

    // 节点流转记录结构体
    struct Log {
        uint256 id; // 主键
        uint256 productId; // 构件id
        uint256 nodeId; // 节点id
        uint256 tokenAttrId; // token属性id
        string nodeValue; // 节点流转详情，一个JSON字符传
        string createTime; // 创建时间
    }

    // 已同步的最大节点流转记录Id
    uint256 public logId = 0;
    // 节点流转记录Mapping
    mapping(uint256 => Log[]) public logs;

    /**
     * 上传节点流转记录上链
     * _logs：流转记录记录
     */
    function sendLogs(Log[] memory _logs) public {
        require(
            msg.sender == owner,
            "Only contract publishers can push node flow records up the chain" // 只能是合约发布者才能推送节点流转记录上链
        );
        for (uint256 i = 0; i < _logs.length; i++) {
            Log memory log = _logs[i];
            Log[] storage logArr = logs[log.productId];
            logArr.push(log);
        }
        logId = _logs[0].id;
    }

    /**
     * 根据构件id获取对应的节点流转记录
     * _productId：构件id
     */
    function getLogByKey(uint256 _productId)
        public
        view
        returns (Log[] memory)
    {
        return logs[_productId];
    }
}