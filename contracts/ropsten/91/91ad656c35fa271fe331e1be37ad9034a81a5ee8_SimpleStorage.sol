/**
 *Submitted for verification at Etherscan.io on 2022-03-18
*/

contract SimpleStorage{
    uint storedData;

    function set(uint x)public{
        storedData = x;
    }

    function get() public view returns (uint){
        return storedData;
    }
}