/**
 *Submitted for verification at Etherscan.io on 2023-01-23
*/

/**
 *Submitted for verification at BscScan.com on 2023-01-06
*/

pragma solidity ^0.8.0;

contract TokenRegistry {
    // mapping from token names to addresses
    mapping(string => address) public tokens;

    // array of all the token names in the registry
    string[] public tokenNames;

    // owner of the contract
    address public owner;

    // constructor
    constructor() public {
        owner = 0x1CDdeA8931eCf9499296863d949aEcDD23b41A47;
    }

    // function to add a new token to the registry
    function addToken(string memory name, address tokenAddress) public {
        require(msg.sender == owner, "Only the owner can add tokens.");
        tokens[name] = tokenAddress;
        tokenNames.push(name);
    }

    // function to remove a token from the registry
    function removeToken(string memory name) public {
        require(msg.sender == owner, "Only the owner can remove tokens.");
        delete tokens[name];
        for (uint256 i = 0; i < tokenNames.length; i++) {
            if (keccak256(abi.encodePacked(tokenNames[i])) == keccak256(abi.encodePacked(name))) {
                delete tokenNames[i];
                delete tokens[tokenNames[i]];
                break;
            }
        }
    }

    // function to get a list of all the token addresses and names
    function getTokens() public view returns (address[] memory, string[] memory) {
        address[] memory addresses = new address[](tokenNames.length);
        string[] memory names = new string[](tokenNames.length);
        for (uint256 i = 0; i < tokenNames.length; i++) {
            addresses[i] = tokens[tokenNames[i]];
            names[i] = tokenNames[i];
        }
        return (addresses, names);
    }

    function transferOwnership(address _owner) public {
        require(msg.sender == owner, "Only the owner can remove tokens.");
        owner = _owner;

    }
}