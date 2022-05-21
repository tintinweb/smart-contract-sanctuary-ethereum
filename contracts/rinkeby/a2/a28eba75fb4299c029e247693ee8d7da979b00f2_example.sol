/**
 *Submitted for verification at Etherscan.io on 2022-05-21
*/

// File: user.sol

pragma solidity ^0.8.0;
contract example {
   

        uint public nu;
        mapping (uint => bool) public see;

        function setSee(uint num) public {
            see[num] = true;
        }

        function suffer (uint numb) public {
                    bool status;

                while (status == false){
                    uint numb = increaseNumber(numb);
                    if (see[numb] == false){
                        status = true;
                    }
                }
                see[numb] = true;
        }


        function increaseNumber (uint number) public pure returns(uint) {
                    return number++;
        } 

}