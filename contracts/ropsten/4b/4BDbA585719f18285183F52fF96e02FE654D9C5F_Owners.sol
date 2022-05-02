/**
 *Submitted for verification at Etherscan.io on 2022-05-02
*/

pragma solidity ^0.6.4;


contract Owners {
    //owner address for ownership validation
    address owner;

    constructor() public {
        owner = msg.sender;
//        log("owner=",owner);
    }
    //owner check modifier
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

//    //contract distruction by owner only
//    function close()  public  onlyOwner {
////        log("##contract closed by owner=",owner);
//        selfdestruct(owner);
//    }

    //constractor to verify real owner assignment
    function getOwner()    public view returns (address){
        return owner ;
    }
    //log event for debug purposes
//    event log(string loga, address logb);
}