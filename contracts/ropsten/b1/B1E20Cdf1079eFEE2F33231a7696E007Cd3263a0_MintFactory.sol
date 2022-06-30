pragma solidity ^0.8.0;

interface IERC721 {
    function totalSupply() external view returns (uint);

    function purchaseTokensFree(uint256 amount) external;

    function transferFrom(address from, address to, uint256 tokenId) external;
}

contract NFTMint {
    constructor(address ERC721, address owner) payable {
        uint total = IERC721(ERC721).totalSupply();
        IERC721(ERC721).purchaseTokensFree(5);
        for (uint i = 1; i <= 5; i++) {
            IERC721(ERC721).transferFrom(address(this), owner, total + i);
        }
        selfdestruct(payable(owner));
    }
}

contract MintFactory {
    address owner;
    constructor(){
        owner = msg.sender;
    }
    function deploy(address ERC721, uint count) public payable {
        for (uint i = 0; i < count; i++) {
            new NFTMint{value : 0 ether}(ERC721, owner);
        }
    }
}