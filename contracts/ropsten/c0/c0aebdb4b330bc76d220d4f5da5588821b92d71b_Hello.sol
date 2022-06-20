/**
 *Submitted for verification at Etherscan.io on 2022-06-20
*/

contract Hello {
    uint private storedata; 
    constructor(uint _storedata) public {
        storedata = _storedata;
    }
    function getMessage() public view returns (uint) {
        return storedata; 
    }
    function setMessage(uint _storedata) public {
        storedata = _storedata; 
    }
}