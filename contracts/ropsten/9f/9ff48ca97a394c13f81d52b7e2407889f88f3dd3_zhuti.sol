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
        string yinhangzhanghao;  
        
    }

    mapping(uint=>mapping(uint=>_Jiaoyi)) Jiaoyi;
    mapping(int=>int[][]) Mulu;       
    mapping(address=>int[1]) Guojiama; 

    int[] xxx;
    int[][] ccc;
    int[] sss; 
    int ooo;

    function guojiamashuru (int[1] memory guojiama) external  { //格式 [-86]

        Guojiama[msg.sender] = guojiama;
    } 

    function duqu_guojiama_mulu (address dizhi) public view returns(string memory,int[1]memory ,int[][] memory ){
        int[1] memory linshi = Guojiama[dizhi];
        int linshi1 = linshi[0];
        return (jiaoyitishi,Guojiama[dizhi],Mulu[linshi1]);

    }
    
   
}