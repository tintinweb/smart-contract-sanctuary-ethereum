/**
 *Submitted for verification at Etherscan.io on 2022-07-08
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.7.0;

contract Mycontract {
    
    uint number;
    uint fac=1;
    uint i;

    function fact(uint x) public  returns(uint) {
        number=x;
        for(i=1;i<=x;i++){
            fac= fac*(i);
        }
        return fac;
    }
     function Sum(uint firstNo,uint secondNo) pure public returns (uint){
        uint outPut =firstNo+secondNo;
        return outPut;
    } 
     function Sub(uint firstNo,uint secondNo) pure public returns (uint){
        uint outPut =firstNo-secondNo;
        return outPut;
    } 
     function Mul(uint firstNo,uint secondNo) pure public returns (uint){
        uint outPut =firstNo*secondNo;
        return outPut;
    } 

    function Div(uint firstNo,uint secondNo) pure public returns (uint){
        uint outPut =firstNo/secondNo;
        return outPut;
    } 

    function palindrom (uint num) pure public returns (string memory){
         uint m=num;
         uint rev=0;
         while(num>0){
             uint temp=num%10;
             rev=(rev*10)+temp;
             num=num/10;
         }
         if(rev==m){
             return"palindrom no";
         }
         else{
             return"not palindrom no";
         }
    }

    function armstrong(uint num) pure public returns (string memory)
    {
         uint m=num;
         uint sum=0;
         while(num>0){
             uint temp=num%10;
             sum =sum+(temp+temp+temp);
             num=num/10;
             }
             if (sum==m){
                 return"armstong no";
             }
             else{
                 return "not armstrong no";
             }
    }
         
    function reverse (uint num) pure public returns (string memory){
         uint m=num;
         uint sum=0;
             uint temp=num%10;
             sum =sum+(temp+temp+temp);
             num=num/10;
             
             if (sum==m)
             {
                 return"reverse no";
             }
             else
             {
                 return "not reverse no";
             }
         }
         function getResult(
         ) public pure returns(
         uint product, uint sum){
         uint num1 =8 ; 
         uint num2 = 4;
            product = num1 * num2;
         sum = num1 + num2; 
    }

    function prime (uint num) pure public returns (string memory){
        uint flgData=2;
         if(num<2){
             return "not prime no";
         }
         else if(num==2){
             return"prime no";
         }
         else{
                 while(num%flgData==0){
                     return "not prime no";
                 }
             
             return "prime no";
         }
    }

   function digitSum(int256 n) public pure returns (int256) {
        int256 a;
        int256 sum = 0;
        while (n > 0) {
            a = n % 10;
            sum = sum + a;
            n = n / 10;
        }
        return sum;
    }

    function fib(uint n) public view returns(uint) { 
      if (n <= 1) 
      {
         return n;
      } 
      else 
      {
         return this.fib(n - 1) + this.fib(n - 2);
       }
    } 
 }