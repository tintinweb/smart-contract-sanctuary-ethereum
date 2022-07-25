/**
 *Submitted for verification at Etherscan.io on 2022-07-25
*/

contract Child{
    uint public data;
    
    // use this function instead of the constructor
    // since creation will be done using createClone() function
    function init(uint _data) external {
        data = _data;
    }
}