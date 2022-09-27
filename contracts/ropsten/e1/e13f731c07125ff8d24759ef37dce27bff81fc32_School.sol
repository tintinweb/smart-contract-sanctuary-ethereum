/**
 *Submitted for verification at Etherscan.io on 2022-09-27
*/

//SPDX-License-Identifier:MIT
pragma solidity >=0.7.0 < 0.9.0;
 
contract School{
    //宣告變數名稱
    struct Class{
        string teacher;
        mapping (string => uint) scores;
    }
    //班級名稱對應到班級struct
    mapping (string => Class) classes;
    //新增班級，節省gas使用calldata而不是memory
    function addClass(string calldata className,string calldata teacher)public{
        //宣告Class的一個storage，refrence到classes的班級名稱
        Class storage class = classes[className];
        class.teacher = teacher;
    }
    //新增學生資料
    function addStudentScore(string calldata className,string calldata studentName, uint score) public {
        /*方法1.對classes的mapping 從所有班級中挑出一個班級，她的成員score中的學生名稱等於score
        (classes[className]).scores[studentName] = score;
        */
        //方法2.建立storage refrence到classes的班級名稱
        Class storage class = classes[className];
        //設定其中學生的成績
        class.scores[studentName] = score;
    }
    //取得學生成績(查看storage)
    function getStudentScore(string calldata className,string calldata studentName) public view returns(uint){
        /*方法1.在班級storage中把班級名稱拿出來再將成績中的storage學生名字拿出來
        return (class[className]).score[studentName];
        */
        //方法2.建立storage refrence 把班級名稱拿出來再去拿學生成績
        Class storage class = classes[className];
        return class.scores[studentName];
    }
}