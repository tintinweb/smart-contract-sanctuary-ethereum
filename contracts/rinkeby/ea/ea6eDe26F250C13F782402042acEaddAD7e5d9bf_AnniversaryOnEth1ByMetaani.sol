// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./OpenzeppelinERC1155.sol"; 

contract AnniversaryOnEth1ByMetaani is ERC1155{
    string public name = "Anniversary by Metaani";
    address public owner;
    uint private tokenId = 1;
    mapping(address => bool) private mintedAddressMap;
    uint public limited = 1000;
    uint public minted = 0;
    uint public endSaleDate = 1662994800;
    bool public isStartingSale = false;
    event freeMinted(address minter);

    modifier isOwner(){
        require( _msgSender() == owner, "Must be owner.");
        _;
    }

    function isOnSale() internal view returns(bool){
        return block.timestamp < endSaleDate ? true : false;
    }

    constructor(string memory _ipfsURL) ERC1155(_ipfsURL){
        owner = _msgSender();
        _setURI(_ipfsURL);
    }

    function freeMint() public {
        require(isStartingSale == true, "Coming soon.");
        require(isOnSale() == true, "Not Available.");
        require(mintedAddressMap[_msgSender()] == false, "Already minted.");
        require(minted < limited, "Reached limited.");
        _mint(_msgSender(), tokenId, 1, "");
        minted++;
        mintedAddressMap[_msgSender()] = true;
        emit freeMinted(_msgSender());
    }

    function toggleIsStartingSale() isOwner() public  {
        isStartingSale = !isStartingSale;
    }

    function afterThat(string memory _newuri) isOwner() public{
        _setURI(_newuri);
    }

}