/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: GPL-3.0
// 20220923 JeonghoPark

pragma solidity 0.8.0;

contract summary {

    uint Lovepizza;
    int Hatepizza;

    uint Lovehamberger;
    int Hatehamberger;

    function LikePizza() public returns(uint) {
        Lovepizza++;
        return Lovepizza;
    }
    function DislikePizza() public returns(int) {
        Hatepizza--;
        return Hatepizza;
    }
    function LikeHamberger() public returns(uint) {
        Lovehamberger++;
        return Lovehamberger;
    }
    function DisLikeHamberger() public returns(int) {
        Hatehamberger--;
        return Hatehamberger;
    }
}