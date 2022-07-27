/**
 *Submitted for verification at Etherscan.io on 2022-07-26
*/

pragma solidity ^0.6.6;
// Stores cid and hash values

contract store {
    string cid = "";
    string hash = "";
    
    function cidhash(string memory _cid, string  memory _hash) public {
        cid = _cid;
        hash = _hash;
    }

}