/**
 *Submitted for verification at Etherscan.io on 2022-05-29
*/

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;
contract zhuti {

    string jiaoyitishi = "Number format";//提示最大支持wei数量int最大值是多少到时候获取一下看看。
    struct _Jiaoyi{
        bool jiaoyizhuangtai;
        int[] jiaoyihao;
        int[] touken_wei;
        int[] guojiama;
        string yinhanghuming;
        string yinhangzhanghao;  //银行账号用string 因为int位数不够；
        
    }

    mapping(uint=>mapping(uint=>_Jiaoyi)) Jiaoyi;
    mapping(int=>int[][]) Mulu;       //xinxi[Guojiama[0]]= 100 或 [100][-100];   可用
    mapping(address=>int[1]) Guojiama; //所有用户，只要填写一次就好。始终记录每个用户的国家码。

    int[] xxx;
    int[][] ccc;
    int[] sss;  //    sss = [100] 数组型，赋值加括号。sss[0]= 100 ；int型 不用加括号。 可以显示转换，很重要。
    int ooo;

    function guojiamashuru (int[1] memory guojiama) external  { //格式 [-86]

        Guojiama[msg.sender] = guojiama;
    }

    function duqu_guojiama_mulu () public view returns(string memory,int[1]memory ,int[][] memory ){
        int[1] memory linshi = Guojiama[msg.sender];
        int linshi1 = linshi[0];
        return (jiaoyitishi,Guojiama[msg.sender],Mulu[linshi1]);

    }
    
   
}