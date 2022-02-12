/**
 *Submitted for verification at Etherscan.io on 2022-02-12
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Owner
 * @dev Set & change owner
 */

contract Assignment {
    //grace period
    //8th/9th day = 86400/172800 second
    //10th day = 259200 second
    uint constant dueDate = 1644508800;    //2022-02-16 00:00:00
    uint constant initialMark = 100;
    string public GetDueDate = "2022-02-16 00:00:00";
    uint public uploadtime;
    uint public FinalMark; 
    uint private gracePeriod;


    function getDate() internal returns(uint){
        uploadtime = block.timestamp;
        return uploadtime;
    }
    
    function getFinalMark() public returns(uint){
        uint curtime = getDate();
        if (curtime > dueDate){
            gracePeriod = curtime - dueDate;
            if (gracePeriod <= 86400){
                FinalMark = 80;
                return FinalMark;
            } else if (gracePeriod <= 172800) {
                FinalMark = 64;
                return FinalMark;
            } else if (gracePeriod <= 259200) {
                FinalMark = 64;
                return FinalMark;
            } else {
                FinalMark = 0;
                return FinalMark;
            }
        }
        if (curtime <= dueDate){
            FinalMark = 100;
            return FinalMark; 
        }

    }

  
}