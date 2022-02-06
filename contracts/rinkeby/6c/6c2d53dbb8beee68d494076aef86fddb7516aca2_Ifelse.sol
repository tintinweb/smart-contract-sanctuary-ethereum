/**
 *Submitted for verification at Etherscan.io on 2022-02-06
*/

pragma solidity ^0.8.0;

contract Ifelse{
    
    bytes32  Ravi=keccak256(abi.encodePacked("Ravi"));
    bytes32  Tanvi=keccak256(abi.encodePacked("Tanvi"));
    bytes32  Jenika=keccak256(abi.encodePacked("Jenika"));

    function print(string memory _name) public view returns(string memory){
    bytes32 input = keccak256(abi.encodePacked(_name));
    
       if(input == Ravi)
        {
            return 'Rajkot';
        }
        else if(input == Tanvi)
        {
            return 'Ankaleshwar';
        }
        else if(input == Jenika)
        {
            return 'Ahmedabad';
        }
        else{
            return 'Data Not Found';
        }
}
}