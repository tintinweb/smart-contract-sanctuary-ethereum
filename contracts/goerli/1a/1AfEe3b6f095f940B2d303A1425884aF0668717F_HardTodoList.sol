/**
 *Submitted for verification at Etherscan.io on 2022-08-14
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.4;

contract HardTodoList {
    enum Status{
        TODO,
        PENDING,
        COMPLETED
    }

    struct Todo{
        string title;
        Status status;
        uint256 expired;
        
    }
    
    //滯留時間
    uint256 private expirdedPeriod = 5;
    //不給外部直接呼叫，只能內部使用
    Todo[] private todos;
    //準備清空的數量
    uint256 private needRemoveCount = 0;


    //新增todo
    function addTodo(string memory _title) external{
        todos.push(
            Todo({
                title: _title,
                status: Status.TODO,
                expired: 0
            })
        );
    }

    //取得全部 todos
    function getAllTodos() external view returns(Todo[] memory ){
        return todos;
    }
    
    //將 todo 設定為 completed
    function setTodoCompleted(uint256 _index) external onlyTodo(_index){
        Todo storage todo = todos[_index];
        todo.status = Status.COMPLETED;
    }

    //將 todo 設定為 pending
    function setTodoPending(uint256 _index) external onlyTodo(_index){
        Todo storage todo = todos[_index];
        todo.status = Status.PENDING;
        todo.expired = block.timestamp + expirdedPeriod;
    }

    //將 pending 設定為 todo
    function setPendingTodo(uint256 _index) external {
        require(_index < todos.length , "This index is not exist");
        require(todos[_index].status == Status.PENDING, "This todo's status is not 'PENDING' ");
        require(todos[_index].expired >= block.timestamp, "pending expired");

        Todo storage todo = todos[_index];
        todo.status = Status.TODO;
        todo.expired = 0;            
    }

    
    modifier onlyTodo(uint256 _index) {
        require(_index < todos.length , "This index is not exist");
        require(todos[_index].status == Status.TODO, "This todo's status is not 'TODO' ");
        _;
    }

    //清空 Completed
    function removeAllCompletedTodos() external{
        if(todos.length > 0){
        for(uint256 _i = 0; _i < todos.length - 1; _i++)
            {
                if(todos[_i].status == Status.COMPLETED){
                    todos[_i] = todos[_i + 1];
                    needRemoveCount++;
                }
            }

            if(needRemoveCount > 0){
            for(uint256 _i = 0; _i < needRemoveCount; _i++)
                {
                    todos.pop();
                }
            }
        }
       
    }
}