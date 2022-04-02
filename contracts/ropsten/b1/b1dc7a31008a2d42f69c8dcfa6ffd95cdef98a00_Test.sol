/**
 *Submitted for verification at Etherscan.io on 2022-04-02
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

contract Test{
    
    struct donateLog{
        string donateType;
        string moneyAmount;
        string itemDetail;
        string detail;
        string date;
    }
    
    mapping(string=>donateLog[]) userLog;
    

    function getData(string memory username) public view returns(string[5][] memory){
        
        string[5][] memory result = new string[5][](userLog[username].length);
        
        //给返回用的字符串数组赋值
        //solidity 6.0以上的版本不能直接修改数组长度（length），只能用push（）和pop（）方法修改长度
        for(uint j = 0;j<result.length;j++){
            for(uint i = 0;i<5;i++){
                if(i == 0)
                    result[j][i] = userLog[username][j].donateType;
                if(i == 1)
                     result[j][i] = userLog[username][j].moneyAmount;
                if(i == 2)
                     result[j][i] = userLog[username][j].itemDetail;
                if(i == 3)
                     result[j][i] = userLog[username][j].detail;
                if(i == 4)
                     result[j][i] = userLog[username][j].date;
            }
        }
        
        return result;
    }
    
    function setData(string memory username, uint donateType, string memory moneyAmount, string memory itemDetail, 
    string memory detail, string memory date) public returns(string memory){
        
        //记录数据
        uint logIndex = userLog[username].length;
        userLog[username].push();
        
        if(donateType == 1){
            userLog[username][logIndex].donateType = "money";
            userLog[username][logIndex].moneyAmount = moneyAmount;
        } else if(donateType == 2){
            userLog[username][logIndex].donateType = "item";
            userLog[username][logIndex].itemDetail = itemDetail;
        }
        
        userLog[username][logIndex].detail = detail;
        userLog[username][logIndex].date = date;
        
        return userLog[username][logIndex].date;
    }
}