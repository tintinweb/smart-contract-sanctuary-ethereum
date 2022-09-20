/**
 *Submitted for verification at Etherscan.io on 2022-09-20
*/

// File: diamond_tribunal/DS.sol

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

// File: diamond_tribunal/initDiamond.sol


pragma solidity ^0.8.8;


contract initDiamond{

    function init(address _tokenAddress, string memory _tokenName,  uint256 _tokenDecimal,uint256 _defaultPenalty) external{
        DS.getVar().tokens[_tokenName] = _tokenAddress;
        DS.getVar().tokenDecimal[_tokenName] = _tokenDecimal;
        DS.getVar().defaultFee = 150; 
        DS.getVar().defaultPenalty = _defaultPenalty;
        DS.getVar().defaultLifeTime =  604800;
    }
}