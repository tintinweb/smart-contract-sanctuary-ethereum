/**
 *Submitted for verification at Etherscan.io on 2022-07-26
*/

// File: contracts/Jam.sol
pragma solidity ^0.8.7;

contract JAM {

    uint256 public tokenId;
    string public firstName;
    string public lastName;
    address public from;
    address public to;
    bytes public data;
   
     function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        string memory _firstName, 
        string memory _lastName
    ) public virtual  {
        safeTransferFrom(_from, _to, _tokenId,_firstName,_lastName, "");
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        string memory _firstName, 
        string memory _lastName,
        bytes memory _data
    ) public  returns(bool) {
        from = _from;
        to = _to;
        tokenId =_tokenId;
        firstName =_firstName;
        lastName = _lastName;
        data = _data;
        return true;
    }
}