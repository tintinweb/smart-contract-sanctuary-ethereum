// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "./DS.sol";
import "./Modifiers.sol";

contract UpdateParms is Modifiers{

    // Change Defaults parms
    function _changeDefaultFee(uint256 _newDefaultFee) onlyOwner external{
        // use Points Basis 1% = 100
        require(DS.getVar().owner == msg.sender, "Only Owner");
        require((_newDefaultFee >= 10),"Fee in PB MIN 0.1% = 10" );
        require((_newDefaultFee <= 1000),"Fee in PB MAX 10% = 1000");
        DS.getVar().defaultFee = _newDefaultFee;
    }

    function _changeDefaultPenalty(uint256 _newDefaultPenalty) onlyOwner external{
        require(DS.getVar().owner == msg.sender, "Only Owner");
        DS.getVar().defaultPenalty = _newDefaultPenalty; // 1 USD = 1 unit
    }

    function _changeDefaultLifeTime(uint256 _newDefaultLifeTime) onlyOwner external{
        require(DS.getVar().owner == msg.sender, "Only Owner");
        DS.getVar().defaultLifeTime = _newDefaultLifeTime; // in secs
    }

    function _changeTribunalAdress(address _newAddress) onlyOwner external{
        require(DS.getVar().owner == msg.sender, "Only Owner");
        DS.getVar().tribunal = _newAddress;
    }

    function _changeOracleAddress(address _newAddress) onlyOwner external{
        require(DS.getVar().owner == msg.sender, "Only Owner");
        DS.getVar().oracle = _newAddress;
    }

    function _addNewToken(string memory _tokenName, address _tokenAddress, uint256 _tokenDecimal) onlyOwner external {
        require(DS.getVar().owner == msg.sender, "Only Owner");
        require(DS.getVar().tokens[_tokenName] == address(0), "token already exists");    
        DS.getVar().tokens[_tokenName] = _tokenAddress;
        DS.getVar().tokenDecimal[_tokenName] = _tokenDecimal;
    }
}

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
    function fill()external{

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