/**
 *Submitted for verification at Etherscan.io on 2022-05-21
*/

pragma solidity >=0.4.22 <0.8.0;

contract AccessRestriction {
    address public owner = msg.sender;
    uint public creationTime = block.timestamp;

    // 检查调用是否来自特定的账户
    modifier onlyBy(address _account) {
        require(msg.sender == _account, "Sender not authorized.");
        _;
    }

    // 修改合约拥有者
    function changeOwner(address _newOwner) public onlyBy(owner) {
        owner = _newOwner;
    }

    // 检查是否经过了一段特定的时间
    modifier onlyAfter(uint _time) {
        require(block.timestamp >= _time, "Function called too early.");
        _;
    }

    // 只有合约所有者创建6周后才能调用本方法
    function disown() public onlyBy(owner) onlyAfter(creationTime + 6 weeks) {
        delete owner;
    }

    // 检查函数调用是否有足够的费用
    modifier costs(uint _amount) {
        require(msg.value >= _amount, "Not enough Ether provided.");
        _;
        if (msg.value > _amount)
            msg.sender.transfer(msg.value-_amount);
    }

    function forceOwnerChange(address _newOwner) public payable costs(200 ether) {
        owner = _newOwner;
        // 下面的条件仅用于举例
        if (uint(owner) & 0 == 1)
            return;
        // 返还多余的费用
    }
}