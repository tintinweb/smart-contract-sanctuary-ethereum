/**
 *Submitted for verification at Etherscan.io on 2022-09-21
*/

contract input_read{
    uint num = 15; 

    function read() public view returns (uint){
        return 123;
    }

    function read2() public view returns (uint){
        return num;
    }

    function change(uint input) public{
        num =input;
    }
}