/**
 *Submitted for verification at Etherscan.io on 2022-06-04
*/

// SPDX-License-Identifier: BUSL-1.1 
pragma solidity ^0.8.10;
contract mulu_du_xie{

    mapping(int=>int[][])Mulu;// 目录    国家码=>目录  
    int[2][10000] fanhuikan;
    
 //写入数组           参与计算的数组要加 [1] 否则无法计算。好像数组都要加方括号里的定长[1]
    function xieru(int[1] memory Guojiama,int[1] memory jiaoyihao,int[1] memory token_wei ) public {  
        int[1] memory  _token;

        if (token_wei[0] > 0){  //负变正，正变负 可用     正数则变负数
              _token[0] = token_wei[0] + token_wei[0];
              _token[0] = token_wei[0] - _token[0]; 
            }
        else{_token[0] = token_wei[0];}     //    否则   负数与0则直接写入
        Mulu[Guojiama[0]].push([jiaoyihao[0],_token[0]]);  //push
    }

 //读取 国家码对应 的 数组目录 网页上可以获取msg.sender 直接用地址读取国家码读取目录
    function duqu(int[1] memory guojiama)public view returns(int[][] memory mulu,int[2][10000] memory fanhuik ){
        

        return (Mulu[guojiama[0]],fanhuikan);
    }



 //计算交易号
    function qu_jiaoyihao() public {
        //交易目录 直接 push 交易完成后 pop掉
    }


}