/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

contract exerice10 {
    string [] nameList;

// 이름을 넣는 함수
// 상태변수에 변화를 주기때문에 view 사용 불가

    function pushName(string memory _name) public {
        nameList.push(_name);
    }
    
// 리스트의 길이를 알려주는 함수
    function lastLength() public view returns(uint) {
        return nameList.length;
    }

// 몇번쨰 리스트에 뭐가 들어갔는지 알려주는 함수
    function getName(uint _name) public view returns(string memory) {
        return nameList[_name-1];
    }
}