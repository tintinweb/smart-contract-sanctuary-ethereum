/**
 *Submitted for verification at Etherscan.io on 2022-12-06
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol";

contract BC{

//1
function input(string memory _str)public pure returns(string memory){
    if(keccak256(bytes(_str))==keccak256("1")){
        return "1111";
    }

    if(keccak256(bytes(_str))==keccak256("a")){
        return "aaaa";
    }

    return "";
}

//2
uint[] public temp;

function sort()public {
    
    temp.push(1);
    temp.push(2);
    temp.push(3);
    temp.push(5);

    uint box;

    for(uint i=0;i<temp.length;i++){
        for(uint j=i;j<temp.length;j++){
            if(temp[j]>temp[i]){
                box= temp[i];
                temp[i]=temp[j];
                temp[j]=box;
            }
        }
    }

}

//3

function show(uint num)public pure returns(uint){
    uint _num = (num-100)/100;
    return _num;
}

//4
uint[] public sequence;
function arithmeticSequence(uint _start,uint _end,uint total)public {

    uint next=_start;
    uint plusNum;
    for(uint i=_start;i<_end;i++){
        uint recycle=1;
        while(next>_end){
            
            next+=i;
            recycle++;
        }

        if(recycle==total){
            break;
        }
    }


    next=_start;

    for(uint i=0;i<total;i+=plusNum){
        sequence.push(next);
        next+=plusNum;
    }


}

//5

    // uint[] tempForFive;
    // function numberFive(uint _num) public{
    //     for(uint i=2;i<=_num;i++){
    //         while(_num%i==0){
    //             _num/=i;

    //             if(_num>i)
    //         }
    //     }
    // }


//7

function textLimit(string memory _str)public{
    require(bytes(_str).length<=100);
}

//9
function SafeMathTryAdd(uint a,uint b)public returns(bool,uint){
    //tryadd, add, sub
    // return SafeMath.tryAdd(a,b);
}

function SafeMathAdd(uint a,uint b)public returns(uint){
    // return SafeMath.add(a,b);
}

function SafeMathSub(uint a,uint b)public returns(uint){
    // return SafeMath.sub(a,b);
}


}

//10
/*
contract A{
    uint a;

    function plus()public{
        a+=10;
    }
}
contract B{

    A ca;

    constructor(address _ad){
        ca=A(_ad);
    }

    function plusB(uint _a)public{
        ca.plus();
    }

}
*/