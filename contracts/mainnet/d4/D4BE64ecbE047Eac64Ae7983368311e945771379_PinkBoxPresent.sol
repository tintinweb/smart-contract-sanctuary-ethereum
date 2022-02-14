// SPDX-License-Identifier: NONE

pragma solidity >=0.8.10 <=0.8.10;

import "./OpenzeppelinERC721.sol";

contract PinkBoxPresent is  ERC721URIStorage {

    address public owner;
    uint256 public nftid = 1;
    bool revealed = false;
    bool minton = true;
    string pinkBox = "ipfs://QmdWLdQZpwe51MEovVU9u8BuRdruVzomeTAXANqhpAkTef";
    string cap = "ipfs://QmVZ5AuMWLVa91d7R3oBSUC2WiccwfVpkftu8ei83VYMkz";
    string sweatshirt = "ipfs://QmVMnaw1eYdPkn4HxremsmSSuDwdxpZ3tXrvcJgKtwUsKd";

    function mintOff() public{
        require( _msgSender() == owner );
        minton = false;
    }

    function reveal() public{
        require( _msgSender() == owner );
        revealed = true;
    }

    function multiMint(uint qty) public {
        require( minton );
        require( _msgSender() == owner );
        uint target = nftid - 1 + qty;
        for (uint i = nftid; i <= target; i++ ){
            _safeMint( owner , nftid);
            nftid++;
        }
    }


    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }


    function _burn(uint256 tokenId) internal override(ERC721URIStorage) {
        super._burn(tokenId);
    }

    function burn(uint256 _id) public {
        require( _msgSender() == ownerOf(_id));
        _burn(_id);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721URIStorage)
        returns (string memory)
    {
        if(revealed){
            if( tokenId%2 == 0 ){
                return cap;
            } else {
                return sweatshirt;
            }
        } else {
            return pinkBox;
        }
    }


    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }



    constructor() ERC721("Pink Box Present" , "imma" ) {
        owner = _msgSender();
    } 
}