/**
 *Submitted for verification at Etherscan.io on 2022-09-27
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

contract test {

    uint    public baseFees   = 0.003 ether;
    uint    public baseMerge  = 100000;
    uint  [] public feesModifier   = [100, 67, 50 ];            // -0%, -30%,  -50% 
    uint32[] public priceModifier  = [100, 200, 300];           // +0%, +100%, +200%  


    struct merge {

        bool   first;
        uint32 onBlock; 
        uint   mergedToken;
    }

    modifier checkMergeValue (uint8 mergeValue, uint amount) {

        //DETAILS ⋯ Make sure "msg.sender" has sent enough ether to cover for the fees
        require (msg.value >= (perCalc(baseFees, feesModifier[mergeValue]) * amount),
        "Sorry not enough ether has been sent to cover the fees");
        _;
    }

    function perCalc (uint input, uint per)
    internal
    pure
    returns (uint) {

        return input * per / 100;
    }

    mapping
    (uint => merge) 
    public
    mergedTo;

    function typeOf(uint tokenId) 
    public
    pure
    returns (uint8) {
        if (tokenId <= 10000) {
            return 0;
        } else if (tokenId <= 15000) {
            return 1;
        } else if (tokenId <= 17500) {
            return 2;
        } else {
            return 3;
        }
    }

    function prepareMultipleMerges (
        uint[] memory firstTokens,
        uint[] memory secondTokens
    ) external payable checkMergeValue (typeOf(firstTokens[0]), firstTokens.length) {

        for (uint i; i < firstTokens.length; i++) {

            uint token1 = firstTokens[i];
            uint token2 = secondTokens[i];


            // ⋯ CHANGES DONE ⋯ //
            //                  //
            mergedTo[token1].first        = true;
            mergedTo[token1].onBlock      = uint32(block.number);
            mergedTo[token1].mergedToken  = token2;

            mergedTo[token2].mergedToken = token1;
        }
    } 
}