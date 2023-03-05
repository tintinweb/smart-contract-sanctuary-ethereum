/**
 *Submitted for verification at Etherscan.io on 2023-03-05
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

contract TodoList {
    TodoStruct[] private todos; //代辦事項草稿區
    TodoStruct[] private pendings; // 代辦事項待送區
    TodoStruct[] private completeds; // 代辦事項已完成區
    uint256 private limitSec = 30; // Pending超過多少秒不給回ToDo

    //建構式
    constructor() {}

    //ToDo Object
    struct TodoStruct {
        string todoText; //代辦事項
        uint256 timestamp; //時間戳記
    }

    //Result Object
    struct ResultStruct {
        string code; //回傳代碼
        string desc; //回傳說明
    }

    // 永久儲存是storage，短暫使用就用memory，calldata傳入後只能參考不能改變的data type

    // =========== 代辦事項草稿區 =========== //
    // 新增代辦事項草稿文件
    function setTodo(string memory todo)
        external
        returns (ResultStruct memory)
    {
        todos.push(TodoStruct(todo, this.getTime()));
        return ResultStruct("0000", "Success");
    }

    // 取得所有代辦事項草稿文件
    function getTodos() external view returns (TodoStruct[] memory) {
        return todos;
    }

    // 取得代辦事項草稿文件 By index
    function getTodo(uint256 todosIndex)
        external
        view
        returns (TodoStruct memory)
    {
        return todos[todosIndex];
    }

    // 刪除代辦事項草稿文件
    function deleteTodos(uint256 todosIndex)
        external
        returns (ResultStruct memory)
    {
        if (!checkTodoStructIsNull(todos[todosIndex])) {
            deleteAndSortAndPop(todosIndex, "todos");
            return ResultStruct("0000", "Success");
        } else {
            return ResultStruct("0009", "TodoStruct Is Null");
        }
    }

    // =========== 代辦事項待送區 =========== //
    // 新增代辦事項待送文件
    function setPending(uint256 todosIndex)
        external
        returns (ResultStruct memory)
    {
        TodoStruct memory todo = this.getTodo(todosIndex); //取得代辦事項草稿區文件

        // 判斷該物件是否存在
        if (!checkTodoStructIsNull(todo)) {
            deleteAndSortAndPop(todosIndex, "todos");
            todo.timestamp = this.getTime();
            pendings.push(todo);
            return ResultStruct("0000", "Success");
        } else {
            return ResultStruct("0009", "TodoStruct Is Null");
        }
    }

    // 取得所有代辦事項待送文件
    function getAllPending() external view returns (TodoStruct[] memory) {
        return pendings;
    }

    // 取得代辦事項待送文件 By index
    function getPending(uint256 pendingsIndex)
        external
        view
        returns (TodoStruct memory)
    {
        return pendings[pendingsIndex];
    }

    // 代辦事項待送區文件 返回 代辦事項草稿區
    function pending2Todos(uint256 pendingsIndex)
        external
        returns (ResultStruct memory)
    {
        TodoStruct memory todo = this.getPending(pendingsIndex); //取得代辦事項草稿區文件

        // 判斷該物件是否存在
        if (!checkTodoStructIsNull(todo)) {
            //如果現在時間 - 物件儲存時間 <= 限制秒數，則可以退回todos
            if (this.getTime() - todo.timestamp <= limitSec) {
                deleteAndSortAndPop(pendingsIndex, "pendings");
                todo.timestamp = this.getTime();
                todos.push(todo);
                return ResultStruct("0000", "Success");
            } else {
                return ResultStruct("0001", "time expired");
            }
        }

        return ResultStruct("0009", "TodoStruct Is Null");
    }

    // 刪除代辦事項待送區文件
    function deletePending(uint256 pendingsIndex)
        external
        returns (ResultStruct memory)
    {
        TodoStruct memory todo = this.getPending(pendingsIndex); //取得代辦事項待送區文件

        // 判斷該物件是否存在
        if (!checkTodoStructIsNull(todo)) {
            deleteAndSortAndPop(pendingsIndex, "pendings");
            return ResultStruct("0000", "Success");
        } else {
            return ResultStruct("0009", "TodoStruct Is Null");
        }
    }

    // =========== 代辦事項完成區 =========== //

    // 新增代辦事項完成區文件
    function setCompleted(uint256 pendingsIndex)
        external
        returns (ResultStruct memory)
    {
        TodoStruct memory todo = this.getPending(pendingsIndex); //取得代辦事項待送區文件

        // 判斷該物件是否存在
        if (!checkTodoStructIsNull(todo)) {
            deleteAndSortAndPop(pendingsIndex, "pendings");
            todo.timestamp = this.getTime();
            completeds.push(todo);
            return ResultStruct("0000", "Success");
        } else {
            return ResultStruct("0009", "TodoStruct Is Null");
        }
    }

    // 取得代辦事項完成區文件 By index
    function getCompleted(uint256 completedIndex)
        external
        view
        returns (TodoStruct memory)
    {
        return completeds[completedIndex];
    }

    // 取得所有代辦事項完成區文件
    function getAllCompleted() external view returns (TodoStruct[] memory) {
        return completeds;
    }

    function deleteAllCompleteds() external returns (ResultStruct memory) {
        delete completeds;
        return ResultStruct("0000", "Success");
    }

    // =========== 其他 =========== //
    // 判斷 Struct 是否為 null
    function checkTodoStructIsNull(TodoStruct memory todo)
        private
        pure
        returns (bool)
    {
        if (bytes(todo.todoText).length == 0 && todo.timestamp == 0) {
            return true;
        } else {
            return false;
        }
    }

    // Array delete Todo And Sort And pop
    function deleteAndSortAndPop(uint256 index, string memory arrStr) private {
        TodoStruct[] storage arr = todos;

        if (
            bytes(arrStr).length == bytes("pendings").length &&
            keccak256(abi.encode(arrStr)) == keccak256(abi.encode("pendings"))
        ) {
            arr = pendings;
        } else if (
            bytes(arrStr).length == bytes("completeds").length &&
            keccak256(abi.encode(arrStr)) == keccak256(abi.encode("completeds"))
        ) {
            arr = completeds;
        }

        if (arr.length > 0) {
            // 把index後面的全部替代前一格
            for (uint256 i = index; i < arr.length - 1; i++) {
                arr[i] = arr[i + 1];
            }

            delete arr[arr.length - 1]; //刪除最後一格的資料
            arr.pop(); //移除陣列最後一格的空間，這樣可以減少gas
        }
    }

    //設定 Pending超過多少秒不給回ToDo 的限制秒數
    function setLimitSec(uint256 sec) external {
        limitSec = sec;
    }

    //取得現在時間
    function getTime() external view returns (uint256) {
        return block.timestamp;
    }
}