/**
 *Submitted for verification at Etherscan.io on 2022-09-05
*/

//SPDX-License-Identifier:MIT
pragma solidity >=0.7.0 < 0.9.0;

contract StudentScores{
    //儲存名字去對應成績
    mapping (string => uint)scores;
    string[] names;

    //輸入成績
    function addScore(string memory name, uint score) public {
        scores[name] = score;
        names.push(name);
    }

    //利用學生名字回傳成績
    function getScore(string memory name) public view returns (uint) {
        return scores[name];
    }
    //清除成績
    function clear() public {
        //當名字還沒刪除
        while (names.length > 0){
            //就將最後一個刪除
            delete scores[names[names.length-1]];
            names.pop();
        } 
    }
}