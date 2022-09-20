// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "./DS.sol";

contract Modifiers{

    modifier onlyOwner(){
        require(DS.getVar().owner == msg.sender, "Only OWNER");
        _;
    }
    modifier onlyOracle(){
        require(DS.getVar().oracle == msg.sender, "Only ORACLE");
        _;
    }
    modifier onlyTribunal(){
        require(DS.getVar().tribunal == msg.sender, "Only TRIBUNAL");
        _;
    }
    modifier tokenValid(string memory _tokenName){
        require(DS.getVar().tokens[_tokenName] != address(0),"token NOT supported");
        _;
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