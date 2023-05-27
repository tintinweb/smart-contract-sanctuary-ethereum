/**
 *Submitted for verification at Etherscan.io on 2023-05-26
*/

// project:学生成绩管理系统
// author：z// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.1;

//  创建合约
contract StudentGradeSystem {

    uint total;//定义总分

    struct Student {
        string name;        //姓名
        uint studentId;     // 学号
        uint256 mathScore;   //数学成绩
        uint256 scienceScore;  // 科学成绩
        uint256 englishScore;   //英语成绩
        uint256 total;      //总成绩
    }

    // 根据结构体创建student数组
    Student []  students;
    // 计算统计的学生人数
    uint256 studentCount;

    // 学号映射为学生信息
    mapping (uint => Student) private  student_s;  
    // 存放学生学号
    uint[] private  studentIds; 
    
    // 后续限制合约部署着才可管理成绩
    address owner;
    modifier onlyowner() {
            require(
                owner == msg.sender,
                "Only owner."
            );
            _;
    }
    
   //判断数组里是否存在某个元素
    function logic(uint[] memory _studentIds,uint256 _studentId)  private pure  returns (bool) {
        for (uint i = 0; i < _studentIds.length; i++) {
            if (_studentIds[i] == _studentId) {
                return true;
            } 
        }
        return false;
    }

    // 增加/插入 学生成绩信息
    function addStudent(string memory _name, uint _studentId, uint256 _mathScore,uint256 _scienceScore, uint256 _englishScore) public returns (Student[] memory,uint256) {
        //  判断原有库中是否有该生信息
        require(logic(studentIds,_studentId) == false,"please input again");
        //数组：添加新同学结构体（成绩信息）
        Student memory newStudent = Student({
            name: _name,
            studentId:  _studentId,
            mathScore: _mathScore,
            scienceScore: _scienceScore,
            englishScore: _englishScore,
            total:_mathScore+_scienceScore+_englishScore
        });
        students.push(newStudent);
        // 映射记录
        student_s[_studentId] = Student(_name, _studentId,_mathScore,_scienceScore,_englishScore,_mathScore+_scienceScore+_englishScore);
        studentIds.push(_studentId);
        // 学生人数加一
        studentCount++;
        return (students,studentCount);
    }

    //删除某个学生成绩信息
    function deleteStudent(uint _studentId) public {
        //  判断原有库中是否有该生信息
        require(logic(studentIds,_studentId) == true,"please input again");
        delete student_s[_studentId];
        for (uint i = 0; i < studentIds.length; i++) {
            if (studentIds[i] == _studentId) {
                studentIds[i] = studentIds[studentIds.length - 1];
                studentIds.pop();
                break;
            }
        }
        for (uint i=0;i<students.length;i++){
             if (students[i].studentId == _studentId){
                delete students[i];
             }
        }
    }
    
    //更新成绩
    function updateGrade(uint  _studentId,  uint256 _mathScore,uint256 _scienceScore, uint256 _englishScore) public returns (string memory){
        // 检查库中是否有该生
        require(logic(studentIds,_studentId) == true,"please input again");
        student_s[_studentId].mathScore = _mathScore;
        student_s[_studentId].scienceScore = _scienceScore;
        student_s[_studentId].englishScore = _englishScore;
        student_s[_studentId].total = _mathScore+ _scienceScore+_englishScore;
        for(uint i=0;i<studentCount;i++){
            if (students[i].studentId == _studentId){
                students[i].mathScore =_mathScore;
                students[i].scienceScore= _scienceScore;
                students[i].englishScore= _englishScore;
                students[i].total=_mathScore+_scienceScore+_englishScore;
            }
        }

        return "success updata";
    }

    //通过学生学号查找学生的姓名，各科成绩情况   关键词搜索
    function getkey(uint _studentId) public view returns (string memory,uint256,uint256,uint256,uint256) {
        // 检查库中是否有该生
        require(logic(studentIds,_studentId) == true,"please input again");
        return (student_s[_studentId].name,student_s[_studentId].mathScore,student_s[_studentId].scienceScore,student_s[_studentId].englishScore,student_s[_studentId].total);
    }

    // 将学生按平均成绩/最高成绩排序
    function sortStudentsByAverageScore() public  returns (Student [] memory) {
        for (uint256 i = 0; i < studentCount - 1; i++) {
            for (uint256 j = 0; j < studentCount - i - 1; j++) {
            if (students[j].total < students[j+1].total) {
                Student memory temp = students[j];
                students[j] = students[j+1];
                students[j+1] = temp;
            }
            }
        }
        //  返回按照总成绩，平均成绩排序表的学生信息
        return (students);
    }
    
    // 单科最高最低学生成绩查询
    //数学成绩排序
    function mathscore() public returns (Student [] memory,string memory,uint256,uint256,string memory,uint256,uint256){
        for (uint256 i = 0; i < studentCount - 1; i++) {
            for (uint256 j = 0; j < studentCount - i - 1; j++) {
            if (students[j].mathScore < students[j+1].mathScore) {
                Student memory temp1 = students[j];
                students[j] = students[j+1];
                students[j+1] = temp1;
            }
            }
        }
        //  返回按照数学最高成绩、最低成绩的学生信息
        return (students,students[0].name,students[0].studentId,students[0].mathScore,students[studentIds.length-1].name,students[studentIds.length-1].studentId,students[studentIds.length-1].mathScore);
    }

    //英语成绩排序
    function englishscore() public returns (Student [] memory,string memory,uint256,uint256,string memory,uint256,uint256){
        for (uint256 i = 0; i < studentCount - 1; i++) {
            for (uint256 j = 0; j < studentCount - i - 1; j++) {
            if (students[j].englishScore < students[j+1].englishScore) {
                Student memory temp1 = students[j];
                students[j] = students[j+1];
                students[j+1] = temp1;
            }
            }
        }
        //  返回按照数学最高成绩、最低成绩的学生信息
        return (students,students[0].name,students[0].studentId,students[0].englishScore,students[studentIds.length-2].name,students[studentIds.length-1].studentId,students[studentIds.length-1].englishScore);
    }
    
    //科学成绩排序
    function sciencescore() public returns (Student [] memory,string memory,uint256,uint256,string memory,uint256,uint256){
        for (uint256 i = 0; i < studentCount - 1; i++) {
            for (uint256 j = 0; j < studentCount - i - 1; j++) {
            if (students[j].scienceScore < students[j+1].scienceScore) {
                Student memory temp1 = students[j];
                students[j] = students[j+1];
                students[j+1] = temp1;
            }
            }
        }
        //  返回按照数学最高成绩、最低成绩的学生信息
        return (students,students[0].name,students[0].studentId,students[0].scienceScore,students[studentIds.length-1].name,students[studentIds.length-1].studentId,students[studentIds.length-1].scienceScore);
    }
    

    //  按照学号排序  从小到大
    function sortIDs() public returns (Student [] memory){
        for (uint256 i = 0; i < studentCount - 1; i++) {
            for (uint256 j = 0; j < studentCount - i - 1; j++) {
            if (students[j].studentId > students[j+1].studentId) {
                Student memory temp1 = students[j];
                students[j] = students[j+1];
                students[j+1] = temp1;
            }
            }
        }
        return students;
     }
}