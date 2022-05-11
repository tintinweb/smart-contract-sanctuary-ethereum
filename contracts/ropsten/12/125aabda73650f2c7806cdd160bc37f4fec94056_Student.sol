/**
 *Submitted for verification at Etherscan.io on 2022-05-11
*/

//SPDX-License-Identifier:MIT
pragma solidity^0.8.0;
contract Student{
    event s_roll(uint ROLL);
    mapping(uint=>string) public S_roll;  
    function enroll(uint _Roll,string memory _name)public  {
    S_roll[_Roll]=_name;
        emit s_roll(_Roll);
                }
                        }