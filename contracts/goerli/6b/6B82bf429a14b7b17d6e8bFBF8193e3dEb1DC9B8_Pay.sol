// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

contract Pay {
    mapping(address => uint256) public balances;
    address[] public users;

    address owner;

    event PayTransfer(address addr, uint256 value, bool inOrOut);

    constructor(address o) {
        owner = o;
    }

    function count() public view returns (uint256) {
        return users.length;
    }

    // address.transfer(value)
    receive() external payable {
        _pay();
    }

    // 不能使用pay(value)， 因为其他函数中的transfer是从这个合约的内置balance中扣除的
    // 只有通过msg.value才能增加内置balance
    function pay() public payable {
        _pay();
    }

    function _pay() private {
        require(msg.value > 0, "pay value must >0");
        balances[msg.sender] += msg.value;
        if (!exists(msg.sender)) {
            users.push(msg.sender);
        }

        emit PayTransfer(msg.sender, msg.value, true);
    }

    // 用户退款
    function refund() public {
        require(balances[msg.sender] > 0, "your balance must >0");

        uint256 balance = balances[msg.sender];
        payable(msg.sender).transfer(balance);

        // update state
        delete balances[msg.sender];
        remove(msg.sender);

        emit PayTransfer(msg.sender, balance, false);
    }

    // 管理员提现
    function withdraw() public onlyOwner {
        uint256 totalBalance = address(this).balance;
        require(totalBalance > 0, "total balance must >0");
        payable(owner).transfer(totalBalance);
        clean();

        emit PayTransfer(msg.sender, totalBalance, false);
    }

    // 管理员退款, 不好，会花费很多gas
    function rollback() public onlyOwner {
        for (uint256 i = 0; i < users.length; ++i) {
            payable(users[i]).transfer(balances[users[i]]);
            emit PayTransfer(users[i], balances[users[i]], false);
        }
        clean();
    }

    function clean() private {
        for (uint256 i = 0; i < users.length; ++i) {
            delete balances[users[i]];
        }
        delete users;
    }

    function exists(address addr) private view returns (bool) {
        for (uint256 i = 0; i < users.length; i++) {
            if (users[i] == addr) {
                return true;
            }
        }
        return false;
    }

    function remove(address addr) private {
        bool start = false;
        for (uint256 i = 0; i < users.length - 1; i++) {
            if (users[i] == addr) {
                start = true;
            }
            if (start) {
                users[i] = users[i + 1];
            }
        }
        users.pop();
    }

    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }
}