/**
 *Submitted for verification at Etherscan.io on 2021-04-28
*/

//YunJun Lee
pragma solidity >=0.7.0 <0.9.0;

contract Likelion_2 {
    
    function Sum() public view returns(uint) {
        uint sum = 0 ;
        for ( uint i =1 ; i<=25;i++){
            if (i%2 !=0 && i%3 !=0 && i%5 !=0 && i%7 !=0)
                sum+=i;
        }
        return sum;
    }
    
    


}