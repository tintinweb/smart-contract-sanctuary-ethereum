/**
 *Submitted for verification at Etherscan.io on 2022-04-17
*/

pragma solidity 0.6.0;


 contract firstone {


 string public name;

 function givename(string memory _name ) public {


  name = _name;

}

function getname()public view returns (string memory){


return name;


}





}