// SPDX-License-Identifier: NONE

pragma solidity >=0.8.10 <=0.8.10;

import "./OpenzeppelinERC721.sol";
import "./OpenZeppelinMerkleProof.sol";

contract METAANIxKPP is ERC721Enumerable {

    address public owner;

    string ipfs_base = "ipfs://QmSgK4i9oEE8vtS7JvCGXsepeDYx6s7q4qse254iUU8Ds8/";

    bool private_mint_started = false;
    bool public_mint_started = false;

    mapping(uint => bool) public minted;
    mapping( address => uint ) public addressMintedMap;
    mapping( address => bool ) public privatesale1done;

    uint public privatesaleprice = 0.075 ether;
    uint public publicsaleprice = 0.3 ether;
    uint public magnification = 0;

    address metawallet = 0x60a89BB4C35A62DE53e4E1852E2d4037a008aC5b;
    address metaani = 0xeecE4544101f7C7198157c74A1cBfE12aa86718B;

    bytes32 allowListRoot = 0x493c228601905ea40eec37ae8423c901976d08e0ea1f9fa6fdc0924ea7633f58;
    function setRoot(bytes32 _merkleroot) public {
        require( _msgSender() == owner );
        allowListRoot = _merkleroot;
    }

    function setPrivateSalePrice(uint _price) public {
        require(_msgSender() == owner);
        privatesaleprice = _price;
    }

    function setPublicSalePrice(uint _price) public {
        require(_msgSender() == owner);
        publicsaleprice = _price;
    }

    function setMagnification(uint _magnification) public {
        require(_msgSender() == owner);
        magnification = _magnification;
    }

    function checkredeem(address account, uint256 amount, bytes32[] calldata proof) public view returns ( uint ) {
        if (_verify(_leaf(account, amount), proof)){
            return amount;
        } else {
            return 0;
        }
    }

    function _leaf(address account, uint256 amount)
    internal pure returns (bytes32)
    {
        return keccak256(abi.encodePacked(account , amount));
    }

    function _verify(bytes32 leaf, bytes32[] memory proof)
    internal view returns (bool)
    {
        return MerkleProof.verify(proof, allowListRoot, leaf);
    }

    function privateSaleMint1(address account, uint256 amount, bytes32[] calldata proof , uint _nftid) public payable {
        require( private_mint_started , "private sale not started");
        require(checkredeem( account , amount , proof ) > 0 , "account is not in allowlist");
        require(addressMintedMap[account] < 1 , "mint amount over" );
        require( msg.value == privatesaleprice , "invalid transaction eth price");
        require( 0 < _nftid  && _nftid <= 500 , "invalid nft id" );
        _safeMint( _msgSender() , _nftid);
        addressMintedMap[account]++;
        minted[_nftid] = true;
        privatesale1done[account] = true;
    }

    function privateSaleMint2(address account, uint256 amount, bytes32[] calldata proof , uint _nftid) public payable {
        require( private_mint_started , "private sale not started");
        require(checkredeem( account , amount , proof ) > 0 , "account is not in allowlist");
        require(addressMintedMap[account] < amount * magnification , "magnification amount over" );
        require( msg.value == privatesaleprice , "invalid transaction eth price");
        require( 0 < _nftid  && _nftid <= 500 , "invalid nft id" );
        _safeMint( _msgSender() , _nftid);
        addressMintedMap[account]++;
        minted[_nftid] = true;
    }

    function publicSaleMint(uint256 _nftid) public payable {
        require(msg.value == publicsaleprice );
        require( public_mint_started );
        require( 0 < _nftid  && _nftid <= 500);
        _safeMint( msg.sender , _nftid);
        addressMintedMap[msg.sender]++;
        minted[_nftid] = true;
    }

    function teamMint(uint256 _nftid) public {
        require(_msgSender() == owner );
        require( 0 < _nftid  && _nftid <= 500);
        _safeMint( msg.sender , _nftid);
        minted[_nftid] = true;
    }

    function privatemintStart() public {
        require(msg.sender == owner);
        private_mint_started = true;
    }


    function privatemintStop() public {
        require(msg.sender == owner);
        private_mint_started = false;
    }

    function publicmintStart() public {
        require(msg.sender == owner);
        public_mint_started = true;
    }

    function publicmintStop() public {
        require(msg.sender == owner);
        public_mint_started = false;
    }


    function withdraw() public {
        require(msg.sender == metawallet);
        uint balance = address(this).balance;
        payable(metawallet).transfer(balance);
    }

    function withdrawSpare() public {
        require(msg.sender == 0xE35B827177398D8d2FBA304d9cF53bc8fC1573B7);
        uint balance = address(this).balance;
        payable(metaani).transfer(balance);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }


    function _burn(uint256 tokenId) internal override(ERC721) {
        super._burn(tokenId);
    }

    function burn(uint256 _id) public {
        require( msg.sender == ownerOf(_id));
        _burn(_id);
    }

    function _baseURI() internal view override returns (string memory) {
        return ipfs_base;
    }

    function setbaseURI(string memory _ipfs_base) public {
        require(msg.sender == metawallet );
        ipfs_base = _ipfs_base;
    }


    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Enumerable)
        returns (bool)
    {        
        return super.supportsInterface(interfaceId);
    }



    constructor() ERC721("Metaani x Kyary Pamyu Pamyu" , "METKPP" ) {
        owner = msg.sender;

        //MetaaniKPP
        _safeMint( msg.sender , 1);
        minted[1] = true;
        _safeMint( msg.sender , 2);
        minted[2] = true;
        _safeMint( msg.sender , 3);
        minted[3] = true;

    } 

}