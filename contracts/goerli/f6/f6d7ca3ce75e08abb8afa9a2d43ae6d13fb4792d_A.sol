/**
 *Submitted for verification at Etherscan.io on 2022-12-19
*/

//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 < 0.9.0;

contract A  {
    struct student  {
        uint number;
        string name;
    }

    student[] Students;

    function pushStudent(uint _n, string memory _name)  public  {
        Students.push(student(_n, _name));
    }

    function getLength()    public view returns(uint)   {
        return Students.length;
    }

    // a번째 학생의 이름을 알고 싶다.
    function getName(uint _n)   public view returns(string memory)  {
        return Students[_n-1].name;
    }
}