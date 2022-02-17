/**
 *Submitted for verification at Etherscan.io on 2022-02-17
*/

pragma solidity ^0.8.0;

contract Authorizers {

    mapping(address => bool) private _authorizers;

    function addAuthorizer(address signer) public {
        _authorizers[signer] = true;
    } 

    function checkAuthorizer(address signer) public view returns (bool) {
        return _authorizers[signer];
    } 

    function removeAuthorizer(address signer) public {
        _authorizers[signer] = false;
    } 
}