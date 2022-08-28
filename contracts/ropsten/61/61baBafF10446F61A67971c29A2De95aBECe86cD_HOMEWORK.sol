/**
 *Submitted for verification at Etherscan.io on 2022-08-28
*/

pragma solidity >=0.7.0 <0.8.0;

contract HOMEWORK {

    mapping(address => string) public submitters;

    function store(string memory student_id) public{
        submitters[msg.sender] = student_id;
    }
    // uint256 number;

    /**
     * @dev Store value in variable
     * @param num value to store
     
    function store(uint256 num) public {
        number = num;
    }
    

    
     * @dev Return value 
     * @return value of 'number'
     
    function retrieve() public view returns (uint256){
        return number;
    }
    */

}