/**
 *Submitted for verification at Etherscan.io on 2022-11-07
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

//import "./Ownable.sol";

contract Notarization {
    mapping (string => DocInfo) collection;
    // Owner address
    address public owner;
    struct DocInfo {
        string filehash;
        uint dateAdded; //in epoch
        bool exist; 
        string filename;
    }

     modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    event HashAdded(string filehash, uint dateAdded, string filename);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        owner = msg.sender;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0),"Invalid new address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == owner ;
    }    

    function add(string memory _filehash, uint _dateAdded, string memory _filename) public onlyOwner {
        require(collection[_filehash].exist == false, "this hash already exists in contract");
        DocInfo memory docInfo = DocInfo(_filehash, _dateAdded, true, _filename);
        collection[_filehash] = docInfo;
        
        emit HashAdded(_filehash, _dateAdded, _filename);
    }

    function get(string memory _hash) public view returns (string memory, uint, bool, string memory) {
        return (
            _hash, 
            collection[_hash].dateAdded,
            collection[_hash].exist,
            collection[_hash].filename
        );
    }    
}