/**
 *Submitted for verification at Etherscan.io on 2022-08-14
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

contract TodoList_plus {
    // 列舉
   enum Status {
        TODO,       //代表0
        PENDING,    //代表1
        COMPLETED   //代表2
    }   
    struct Todo {
        string title;
        Status state;
        uint256 expired;
    }
    uint256 public delaytime = 5; //宣告延遲幾秒
    //宣告todos陣列
    Todo[] public todos;

    function add_todo(string memory title) external{
        todos.push(
            Todo({
                title : title,
                state:  Status.TODO,
                expired: 0
            })
        );
    }

    //補充一個todo狀態,
    modifier only_todo(uint256 index){
    require(todos[index].state == Status.TODO ,"Status not TODO , Must be only TODO");
    _;
    }

    //todo -> completed
    //加入modifier的only_todo,會先檢查狀態必須是TODO才能繼續,否則回傳錯誤訊息 
    function set_todo_completed(uint256 index) external only_todo(index){
        Todo storage todo = todos[index];
        todo.state = Status.COMPLETED;
    }
    //todo -> pending
    //todo 搬移後要記錄時間
    function move_todo_to_pending(uint256 index) external only_todo(index){
        Todo storage todo = todos[index];
        todo.state = Status.PENDING;
        //紀錄時間
        todo.expired = block.timestamp + delaytime;  //當下時間 + 延長時間
    }

    //pending ->todo
    function move_pending_to_todo(uint256 index) external {
        Todo storage todo = todos[index];

        //檢查狀態必須是pending才能繼續,否則回傳錯誤訊息
        require(todo.state == Status.PENDING ,"Status not PENDING , Must be only PENDING"); 
       //檢查當時間超過N秒就不能再搬回todo內
        require(todo.expired >= block.timestamp,"pending expired");

        todo.state = Status.TODO;
        todo.expired = 0;
    }
    //清空completed
    function clearcompleted() external{
        for(uint256 j = 0 ; j < todos.length ; j++){
            //require(todo[j].state == Status.COMPLETED ,"Status not COMPLETED , Must be only COMPLETED"); 
            if(todos[j].state == Status.COMPLETED){
                for(uint256 i = j ; i < todos.length -1 ; i++){
                    todos[i] = todos[i+1];
                }
                todos.pop();
            }
        }
    }
}