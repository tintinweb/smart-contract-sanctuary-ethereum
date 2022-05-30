//SPDX-License-Identifier: Unlicense
// Specifies the version of Solidity, using semantic versioning.
// Learn more: https://solidity.readthedocs.io/en/v0.5.10/layout-of-source-files.html#pragma
pragma solidity >=0.7.3;
import './ArtItem.sol';

contract ArtValidator {

    address public owner;
    mapping(address => ArtItem) public arts;


    constructor() {
        // Set the transaction sender as the owner of the contract.
        owner = msg.sender;
    }

     // Modifier to check that the caller is the owner of
    // the contract.
    modifier onlyOwner() {
        require(owner == msg.sender, "Not Owner");
        _;
    }

    modifier validateAddress(address _addr) {
        require(_addr != address(0), "Not Validate Address");
        _;
    }

    function getArt(address _addr) public view returns (string memory, string memory, uint8) {
        return (arts[_addr].name, arts[_addr].url, arts[_addr].flag);
        // ArtItem memory art = arts[_addr];
        // if(arts[_addr].flag != 1) {
        //     return (arts[_addr].name, arts[_addr].url);
        // } else {
            
        // }
    }

    // Only owner address can set art
    function setNewArt(address _addr, string memory _name, string memory _url) public onlyOwner {
        setArt(_addr, ArtItem( {name: _name, url: _url, flag: 1} ));
    }

    
    function setArt(address _addr, ArtItem memory _art) private {
        arts[_addr] = _art;
    }

    
}

//SPDX-License-Identifier: Unlicense
// Specifies the version of Solidity, using semantic versioning.
// Learn more: https://solidity.readthedocs.io/en/v0.5.10/layout-of-source-files.html#pragma
pragma solidity >=0.7.3;
struct ArtItem {
    string name;
    string url;
    uint8 flag;
}