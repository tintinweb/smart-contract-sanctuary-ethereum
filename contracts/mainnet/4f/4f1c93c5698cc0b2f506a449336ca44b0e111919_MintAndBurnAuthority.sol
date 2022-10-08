/**
 *Submitted for verification at Etherscan.io on 2022-10-08
*/

// KTON auth
pragma solidity ^0.4.24;

contract MintAndBurnAuthority {

    mapping (address => bool) public allowMintList;
    mapping (address => bool) public allowBurnList;

    constructor(address[] _mintlists, address[] _burnlists) public {
        for (uint i = 0; i < _mintlists.length; i ++) {
            allowMintList[_mintlists[i]] = true;
        }
        
        for (uint j = 0; j < _burnlists.length; j ++) {
            allowBurnList[_burnlists[j]] = true;
        }
    }

    function canCall(
        address _src, address _dst, bytes4 _sig
    ) public view returns (bool) {
        return ( allowMintList[_src] && _sig == bytes4(keccak256("mint(address,uint256)")) ) ||
        ( allowBurnList[_src] && _sig == bytes4(keccak256("burn(address,uint256)")) );
    }
}