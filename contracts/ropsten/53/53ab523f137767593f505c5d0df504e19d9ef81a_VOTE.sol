/**
 *Submitted for verification at Etherscan.io on 2022-06-22
*/

pragma solidity >=0.4.22 <0.7.0;

contract VOTE {

    int public dog1;
    int public dog2;
    int public dog3;

    constructor() public{
        dog1 = 0;
        dog2 = 0;
        dog3 = 0;
    }

    function vote(int choose) public{
        if(choose == 1){
            dog1++;
        }
        if(choose == 2){
            dog2++;
        }

        if(choose == 3){
            dog3++;
        }
    }

    function result(int sum)public view returns(int count){
        if(sum == 1){
            return dog1;
        }
        else if(sum == 2){
            return dog2;
        }
        else if(sum == 3){
            return dog3;
        }
    }
}