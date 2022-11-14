/**
 *Submitted for verification at Etherscan.io on 2022-11-13
*/

// File: diamond_plans/DS.sol


pragma solidity ^0.8.8;

library DS{

    bytes32 internal constant NAMESPACE = keccak256("deploy.storage.123");


    struct Appstorage{
        // user to timestamp
        mapping(address => uint) userExpiration;
        //user to key
        mapping(address => string) userKey;
        address payable vault;
        address owner;
        bool emergencyStop;
    }

    function getVar() internal pure returns (Appstorage storage s){
        bytes32 position = NAMESPACE;
        assembly{
            s.slot := position
        }
    }


}

// File: diamond_plans/init.sol


pragma solidity ^0.8.8;


contract init{

    function init_vars() external{
        DS.getVar().owner = msg.sender;
        DS.getVar().vault = payable(0xd92A8d5BCa7076204c607293235fE78200f392A7);
        DS.getVar().emergencyStop = false;

    }
}