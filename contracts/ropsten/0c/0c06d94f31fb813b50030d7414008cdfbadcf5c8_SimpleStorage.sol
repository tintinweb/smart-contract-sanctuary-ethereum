/**
 *Submitted for verification at Etherscan.io on 2022-05-03
*/

pragma solidity ^0.5.16;

contract SimpleStorage {
    struct file {
        string signature;
        string ipfspath;
    }

    mapping(string => file) public info;
    string[] public fileName;

    function set(string memory filename, string memory signature, string memory ipfspath) public {
        info[filename].signature = signature;
        info[filename].ipfspath = ipfspath;
        fileName.push(filename);
    }

    function get(string memory filename) view public returns (string memory, string memory) {
        return (info[filename].signature, info[filename].ipfspath);
    }
}