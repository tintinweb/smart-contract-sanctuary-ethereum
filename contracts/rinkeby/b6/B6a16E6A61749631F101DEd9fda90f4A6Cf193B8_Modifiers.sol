// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "./DS.sol";

contract Modifiers{

    function setDSowner()external  returns(address){
        DS.getVar().owner = payable(0xd20fD73BFD6B0fCC3222E5b881AB03A24449E608);
        return DS.getVar().owner;
    }

    modifier onlyOwner(){
        require(DS.getVar().owner == msg.sender, "Only Owner");
        _;
    }

    function test() external onlyOwner returns(address, uint256){
        DS.getVar().defaultFee +=  1;
        return (DS.getVar().owner,DS.getVar().defaultFee);
    }
    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

library DS{

    //bytes32 internal constant NAMESPACE = keccak256("deploy.1.var.diamondstorage");
    bytes32 internal constant NAMESPACE = keccak256("test.1.var.diamondstorage");

    struct Appstorage{
        uint256 defaultLifeTime;
        uint256 defaultFee;
        uint256 defaultPenalty;
        address payable owner;
        address oracle;
        address tribunal;

        // map tokens contract
        mapping(string => address)  tokens;     
        // map tokens contract > decimals
        mapping(string => uint)  tokenDecimal;
    }

    function getVar() internal pure returns (Appstorage storage s){
        bytes32 position = NAMESPACE;
        assembly{
            s.slot := position
        }
    }


}