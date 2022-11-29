/**
 *Submitted for verification at Etherscan.io on 2022-11-29
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

contract ShigotoTouroku {
    // 仕事の内容

    // string[] public shigoto;
    // uint256[] public housyuu;
    // string[] public syuryou;

    struct Work {
        string naiyou;
        uint256 tokensuu;
        string zyoutai;
    }

    Work[] public works;

    function workPush(string calldata naiyou_, uint256 tokensuu_) external {
        Work memory mem = Work({
            naiyou: naiyou_,
            tokensuu: tokensuu_,
            zyoutai: "1"
        });

        works.push(mem);
    }

    function getWork(uint idx) external view returns (Work memory) {
        return works[idx];
    }

    function changeWork(uint idx, string calldata newnaiyou, uint256 newtokensuu) external {
        works[idx].naiyou = newnaiyou;
        works[idx].tokensuu = newtokensuu;
    }

    // function getArray() public view returns (string[] memory, uint256[] memory, string[] memory){
    //     return (shigoto, housyuu, syuryou);
    // }

    // function length() public view returns (uint, uint, uint){
    //     return (shigoto.length, housyuu.length, syuryou.length);
    // }

    // function push(string memory shigotoa, uint housyuua) public {
    //     shigoto.push(shigotoa);
    //     housyuu.push(housyuua);
    //     syuryou.push("1");
    // }


}