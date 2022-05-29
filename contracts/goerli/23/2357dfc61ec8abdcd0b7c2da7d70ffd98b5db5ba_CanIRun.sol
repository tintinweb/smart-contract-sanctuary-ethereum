/**
 *Submitted for verification at Etherscan.io on 2022-05-28
*/

contract CanIRun{
    address public owner;
    bool state = true;
    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }

    constructor(){
        owner=msg.sender;
    }

    function flipState() public onlyOwner{
        state=!state;
    }


    function canIrun() public onlyOwner view returns(bool) {
        return state;
    }
}