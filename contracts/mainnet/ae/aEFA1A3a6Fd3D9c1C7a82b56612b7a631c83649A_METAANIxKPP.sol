// SPDX-License-Identifier: NONE

pragma solidity >=0.8.10 <=0.8.10;

import "./OpenzeppelinERC721.sol";

contract METAANIxKPP is  ERC721  {

    address public owner;
    address commander;
    string[4] premintmetadata;
    string ipfs_base;

    uint256 public nftid = 4;

    function commandermint( address _target ) external {
        require( _msgSender() == commander );
        _safeMint( _target , nftid);
        nftid++;
    }

    function setcommander(address _commander) public {
        require( owner == _msgSender());
        commander = _commander;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function burn(uint256 _id) public {
        require( _msgSender() == ownerOf(_id));
        super._burn(_id);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        if(tokenId < 4){
            return premintmetadata[tokenId];
        }
        return super.tokenURI(tokenId);
    }

    function setbaseURI(string memory _ipfs_base) public {
        require(msg.sender == owner );
        ipfs_base = _ipfs_base;
    }

    function _baseURI() internal view override returns (string memory) {
        return ipfs_base;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }


    //
    constructor() ERC721("Metaani x Kyary Pamyu Pamyu" , "METKPP" ) {
        owner = _msgSender();
        _safeMint( owner , 1);
        premintmetadata[1] = "ipfs://Qmd5XbWXkej7hd2Gj3JCs2Khg7QBHqQ27krNaRz8umHSS7";
        _safeMint( owner , 2);
        premintmetadata[2] = "ipfs://QmYQDG9tMYf2kdBEMJiNZsPtN96G4taKxDSYAXoWx7eExR";
        _safeMint( owner , 3);
        premintmetadata[3] = "ipfs://QmWg7ETXhuVNZEcYAEDeWFUHP5gZW7hzvpSanNdTPaxwQg";
    } 
}