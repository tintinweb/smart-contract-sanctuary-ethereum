/**
 *Submitted for verification at Etherscan.io on 2022-12-16
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

/**
 * A라는 컨트랙트에는 학생이라는 구조체를 만드세요.
 * 학생이라는 구조체안에는 이름과 번호 그리고 점수를 넣습니다. 
 * 점수와 정보들을 넣을 수 있는 함수를 만드세요.

 * B라는 컨트랙트에는 점수가 80점 이상되는 학생들을 모아놓은 array나 mapping을 만드세요.
 * 검색을 통하여 학생의 정보를 받아올 수 있게 해주는 함수도 필요합니다.

 * 1) 구현하고 ->  2) VS Code-truffle(goerli)로 배포하고 -> 3) publis and verify로 코드 등록하기 -> 4) terminal에서 A contract로 점수를 넣고 B contract에서 학생 받아오기

 * 1) 구현한 후 truffle compile 해서 compile 된 캡쳐본 업로드
 * 2) goerli testnet에 배포하는 명령어 입력 후 완료화면 캡쳐본 업로드
 * 3) 코드가 등록된 것을 확인할 수 있는 캡쳐본 업로드
 * 4) terminal 명령어 입력 후 캡쳐본 업로드 
 */

contract A {

    /* ---------------------------------------------------------------- */
    /* -------------------------- STUDENTS ---------------------------- */
    /* ---------------------------------------------------------------- */

    /* DB */
    StudentStruct[] studentsArr;
    struct StudentStruct {
        uint num;
        string name;
        uint score;
    }

    /* Create */
    function setStudent(string memory _name, uint _score) public {
        uint _num = studentsArr.length + 1;
        studentsArr.push(StudentStruct(_num, _name, _score));
    }
    /* Read */
    function getStudent(uint _num) public view returns(uint, string memory, uint) {
        return (studentsArr[_num - 1].num, studentsArr[_num - 1].name, studentsArr[_num - 1].score);
    }


    /* ---------------------------------------------------------------- */
    /* -------------------- HIGH SCORED STUDENTS ---------------------- */
    /* ---------------------------------------------------------------- */

    /* DB */
    StudentStruct[] highScoredStudentsArr;
    uint public highScoredStudentsArrLen;

    /* Update */
    function pushHighScoredStudents() public {
        getHighScoredStudentsLen();
        for (uint i; i < highScoredStudentsArrLen; i++) {
            highScoredStudentsArr.pop();
        }
        for (uint i; i < studentsArr.length; i++) {
            if (studentsArr[i].score >= 80) {
                highScoredStudentsArr.push(studentsArr[i]);
            }
        }
    }

    /* Read */
    function getHighScoredStudents() public view returns(StudentStruct[] memory) {
        return highScoredStudentsArr;
    }
    function getHighScoredStudentsLen() public returns(uint) {
        highScoredStudentsArrLen = highScoredStudentsArr.length;
        return highScoredStudentsArrLen;
    }

}