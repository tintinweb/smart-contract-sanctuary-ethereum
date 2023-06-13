/**
 *Submitted for verification at Etherscan.io on 2023-06-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BlockchainSplitwise {
    mapping(address => mapping(address => uint32)) public balances;
    address[] public users;
    mapping(address => uint32) public unique_users;

    // For development
    uint32[] public parents;
    bool[] public visited;

    event visitedNode(address _address);
    event logMessage(string message);
    event logCycleEnd(int32 cycle_end);
    event logMin(uint32 min);

    function lookup(
        address debtor,
        address creditor
    ) public view returns (uint32) {
        return balances[debtor][creditor];
    }

    function getNeighbors(
        address user
    ) public view returns (address[10] memory) {
        address[10] memory neighbors;
        uint32 length = 0;
        for (uint32 i = 0; i < users.length; i++) {
            if (balances[user][users[i]] != 0) {
                neighbors[length] = users[i];
                length++;
            }
        }
        return neighbors;
    }

    function dfs(address creditor) internal returns (int32) {
        visited[unique_users[creditor] - 1] = true;
        address[10] memory listOfNeighbors = getNeighbors(creditor);
        uint32 index = 0;
        while (listOfNeighbors[index] != address(0)) {
            if (visited[unique_users[listOfNeighbors[index]] - 1]) {
                return (int32(unique_users[creditor] - 1));
            }
            parents[unique_users[listOfNeighbors[index]] - 1] =
                unique_users[creditor] -
                1;
            int32 cycle_end = dfs(listOfNeighbors[index]);
            if (cycle_end >= 0) return cycle_end;
            index++;
        }
        visited[unique_users[creditor] - 1] = false;
        return -1;
    }

    function find_cycle(address creditor) internal returns (int32) {
        for (uint32 index = 0; index < users.length; index++) {
            visited[index] = false;
        }
        visited[unique_users[msg.sender] - 1] = true;
        parents[unique_users[creditor] - 1] = unique_users[msg.sender] - 1;
        int32 cycle_end = dfs(creditor);
        if (cycle_end > 0) {
            return cycle_end;
        }
        return -1;
    }

    function add_IOU(address creditor, uint32 amount) public {
        require(msg.sender != creditor, "You can not owe yourself money");
        // Đầu tiên phải phân tích xem nó có thể tạo vòng hay không

        // Add debtor into list users
        if (unique_users[msg.sender] == 0) {
            unique_users[msg.sender] = uint32(users.length) + 1;
            users.push(msg.sender);
            parents.push(0);
            visited.push(false);
        }
        // Add creditor into list users
        if (unique_users[creditor] == 0) {
            unique_users[creditor] = uint32(users.length) + 1;
            users.push(creditor);
            parents.push(0);
            visited.push(false);
        }

        // Nếu đang nợ mà nợ thêm thì không tạo ra vòng
        if (balances[msg.sender][creditor] != 0) {
            balances[msg.sender][creditor] += amount;
            return;
        }
        // Nếu muốn xóa nợ -> có thể xóa hoặc chưa xóa hết
        if (balances[creditor][msg.sender] >= amount) {
            balances[creditor][msg.sender] -= amount;
            return;
        }
        // Chắc chắn sẽ tạo cạnh mới
        balances[msg.sender][creditor] +=
            amount -
            balances[creditor][msg.sender];
        balances[creditor][msg.sender] = 0;
        // Bắt đầu tìm kiếm vòng
        int32 cycle_end = -1;
        cycle_end = find_cycle(creditor);
        emit logCycleEnd(cycle_end);
        if (cycle_end != -1) {
            emit logMessage("Found the cycle!!!!!");
            // Find min balance
            uint32 positionSender = unique_users[msg.sender] - 1;
            uint32 _cycle_end = uint32(cycle_end);
            uint32 minBalance = balances[users[_cycle_end]][msg.sender];
            while (_cycle_end != positionSender) {
                uint32 indexBalance = uint32(
                    balances[users[parents[_cycle_end]]][users[_cycle_end]]
                );
                if (indexBalance < minBalance) {
                    minBalance = indexBalance;
                }
                _cycle_end = parents[_cycle_end];
            }
            emit logMin(minBalance);
            _cycle_end = uint32(cycle_end);
            while (_cycle_end != positionSender) {
                balances[users[parents[_cycle_end]]][
                    users[_cycle_end]
                ] -= minBalance;
                _cycle_end = parents[_cycle_end];
            }
            _cycle_end = uint32(cycle_end);
            balances[users[_cycle_end]][msg.sender] -= minBalance;
        } else emit logMessage("Not Found any cycle!!!!");
    }
}