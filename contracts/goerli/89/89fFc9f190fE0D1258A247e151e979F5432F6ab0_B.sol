/**
 *Submitted for verification at Etherscan.io on 2022-12-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;



// abstract contract SayHello {
//     uint256 public age;
//     constructor(uint256 _age ){
//         age = _age;
//     }

//     function getAge() public virtual view returns (uint256){
//         return age;
//     }
//     function setAge(uint256 _age) public virtual {}
//     // function makeMeSayHello() public  pure returns (string memory) 
//     // {
//     //     return "Hello";
//     // }
// }

pragma solidity ^0.8.0;


contract A{
    function first()virtual public pure returns(string memory){
        return "from contract A Function first";
    }
    function secondA() public pure returns(string memory){
        return "From contract A Function Second";
    }

}

contract B is A{
    event forTest(uint amount);
    function first()override public pure returns(string memory){
        return "from contract B Function first";
    }    
    function second() public pure returns(string memory){
        return "From contract B Function Second";
    }
    function eventEmit(uint _amount) public {
        emit forTest(_amount);
    }
}