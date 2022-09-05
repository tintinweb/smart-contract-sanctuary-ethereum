/**
 *Submitted for verification at Etherscan.io on 2022-09-05
*/

contract cryptoKitties{
    uint Age;
    
    function set(uint _age) public{
        Age = _age;
    }

    function get() public view returns(uint AGE){
        AGE = Age;
    }
}