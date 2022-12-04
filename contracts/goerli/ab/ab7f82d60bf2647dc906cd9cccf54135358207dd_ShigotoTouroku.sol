/**
 *Submitted for verification at Etherscan.io on 2022-12-04
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

contract ShigotoTouroku {

    uint8 lastShigotoId = 0;

    struct Work {
        // 仕事を登録する構造体
        string tourokubi;
        uint8 shigotoid;
        string naiyou;
        string tourokusya;
        uint256 tokensuu;
        string zyoutai;
    }

    Work[] private works;

    function workPush(string calldata tourokubi_, string calldata naiyou_, string calldata tourokusya_, uint256 tokensuu_) external {
        // 仕事を新規で登録する

        lastShigotoId = lastShigotoId + 1;

        Work memory mem = Work({
            tourokubi: tourokubi_,
            shigotoid: lastShigotoId,
            naiyou: naiyou_,
            tourokusya: tourokusya_,
            tokensuu: tokensuu_,
            zyoutai: "1"
        });

        works.push(mem);
    }

    function getWork(uint idx) external view returns (Work memory) {
        // インデックス番号の仕事内容を返す。
        return works[idx];
    }

    function getLength() external view returns (uint256) {
        // 登録されている仕事の総数を返す。
        return works.length;
    }

    function changeWork(uint idx, string calldata newnaiyou, uint256 newtokensuu) external {
        // 仕事内容を変更する。(仕事内容と報酬を変更できる。登録者は変えれない）
        works[idx].naiyou = newnaiyou;
        works[idx].tokensuu = newtokensuu;
    }

    function changeZyoutai(uint idx) external {
        // 状態を終了：９に変更する。
        works[idx].zyoutai = "9";
    }



}