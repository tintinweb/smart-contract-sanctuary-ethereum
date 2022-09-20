// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "./DS.sol";

contract readers{

    function initVars() 
    external view returns
    ( address owner,
      address oracle,
      address tribunal,
      uint256 defaultfee,
      uint256 defaultPenalty,
      uint256 defaultLifeTime
      
    ){

      address _owner = DS.getVar().owner;
      address _oracle = DS.getVar().oracle;
      address _tribunal = DS.getVar().tribunal;
      uint256 _defaultFee = DS.getVar().defaultFee; 
      uint256 _defaultPenalty = DS.getVar().defaultPenalty;
      uint256 _defaultLifeTime = DS.getVar().defaultLifeTime;
      
      return ( _owner,_oracle,_tribunal,_defaultFee, _defaultPenalty, _defaultLifeTime);

    }

    function searchTokenERC20(string memory _tokenName) external view returns(address ERC20tokenaddress, uint256 decimals){
       address _tokenAddress = DS.getVar().tokens[_tokenName];
       uint256 _tokenDecimal = DS.getVar().tokenDecimal[_tokenName];
       return(_tokenAddress, _tokenDecimal);
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