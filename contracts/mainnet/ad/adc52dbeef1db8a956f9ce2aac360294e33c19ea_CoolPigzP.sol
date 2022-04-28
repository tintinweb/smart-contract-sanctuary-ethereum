// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "./Ownable.sol";
import "./Strings.sol";
import "./MerkleProof.sol";
import "./ERC721AP.sol";

contract CoolPigzP is ERC721AP, Ownable {
    using Strings for uint256;

    string baseURI;
    uint256 public constant _maxSupply = 5555;
    uint256 public constant _maxMint = 5355;
    uint256 public constant _maxMintAmountPerAddressPublic = 4;
    uint256 public constant _maxMintAmountPerAddressWL = 2;
    uint256 public constant _maxMintAmountPerAddressOG = 2;
    uint256 public constant _OGCost = 0.05 ether;
    uint256 public constant _WLCost = 0.06 ether;
    uint256 public constant _PublicCost = 0.08 ether;
    bool public _mintOpened;
    uint256 public publicSaleAfter;
    bytes32 public immutable _OGroot;
    bytes32 public immutable _WLroot;

    constructor(
        string memory initialBaseURI,
        bytes32 OGroot,
        bytes32 WLroot
    ) ERC721AP("CoolPigzT", "CPT",_maxSupply) {
        baseURI = initialBaseURI;
        _OGroot = OGroot;
        _WLroot = WLroot;
        
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function publicMint(uint256 mintAmount) public payable{
        require(_mintOpened, "Minting now allowed yet");
        require(mintAmount > 0,"The quantity cannot be a negative number");
        uint256 price = 0;

        if(block.timestamp >= publicSaleAfter){
            require(_numberMinted(msg.sender) + mintAmount <= _maxMintAmountPerAddressPublic,"Maximum mint amount exceeded");
                
            price = _PublicCost * mintAmount;
        }
        else revert("Minting now allowed yet");
        require(msg.value >= price,"Not Enough ETH");
        
        require((_maxMint - totalSupply()) - mintAmount >= 0,"Not Enough Mintable Token");

        _safeMint(msg.sender,mintAmount);

    }

    function presaleMint(uint256 mintAmount,bytes32[] memory proof) public payable{
        require(_mintOpened, "Minting now allowed yet");
        require(mintAmount > 0,"The quantity cannot be a negative number");
        uint256 mintedToken = _numberMinted(msg.sender);
        bool presale = true;
        uint256 price = 0;

        if(block.timestamp > publicSaleAfter) presale = false;

        if(presale && _verify(msg.sender,proof,_OGroot)){
            price = getPresaleCost(mintAmount,_OGCost,msg.sender);
        }
        else if(presale && _verify(msg.sender,proof,_WLroot)){
            price = getPresaleCost(mintAmount,_WLCost,msg.sender);
        }
        else revert("Pre-Sale is over");

        require(mintedToken + mintAmount <= (_maxMintAmountPerAddressPublic),"Maximum mint amount exceeded");
        

        require(msg.value >= price,"Not Enough ETH");
        
        require((_maxMint - totalSupply()) - mintAmount >= 0,"Not Enough Mintable Token");

        _safeMint(msg.sender,mintAmount);


    }

    function getPresaleCost(uint256 mintAmount,uint256 roleCost,address sender) public view returns(uint256 price) {
        uint256 mintedToken = _numberMinted(sender);

        require(mintAmount>0,"Mint amount cannot be zero");
        require((_maxMintAmountPerAddressPublic - mintedToken) >= mintAmount ,"Maximum mint amount exceeded");

        if ((_maxMintAmountPerAddressWL - mintedToken) < 1 ) 
        { 
            price = mintAmount*_PublicCost;

        } else {

            uint256 remainingPresaleCount = _maxMintAmountPerAddressWL - mintedToken;
            
            if (mintAmount>remainingPresaleCount) {
                price = remainingPresaleCount*roleCost + (mintAmount-remainingPresaleCount)*_PublicCost;
            } else {
                price = mintAmount*roleCost;
            }
        }

            
    }




    function _verify(address _address,bytes32[] memory proof,bytes32 listroot) internal pure returns(bool){
        
        return MerkleProof.verify(proof,listroot,keccak256(abi.encodePacked(_address)));
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        

        string memory currentBaseURI = _baseURI();
        return
            
                string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        ".json"
                    )
                );
                
        
    }
    
    

    //only owner

    function setBaseURI(string memory newBaseURI) external onlyOwner{
        baseURI = newBaseURI;
    }

    function startMint() external onlyOwner{
        _mintOpened = true;
        publicSaleAfter = block.timestamp + 4 hours;
    }

    function ownerMint(uint256 quantity,address _address) external onlyOwner{
        uint256 mod = quantity%5;
        for(uint256 i = 0;i<quantity/5;i++){
            _safeMint(_address,5);
        }
        if(mod != 0) _safeMint(_address,mod);
    }



    function withdraw() public payable onlyOwner {
        uint256 balance = address(this).balance;

        withdrawInternal(0x2C48744e9023f731f5c58Ce7b78dcc99Dc6A7A3b,(balance*2725)/10000);
        withdrawInternal(0xD34Fe4C535c24B91686D5481ec24971225fD9B90,(balance*1250)/10000);
        withdrawInternal(0x3460784Eb3C12F6e0811bbfAeCaF237c8B58FD73,(balance*1000)/10000);
        withdrawInternal(0x8353e20B0E920966a2C251Fac4918FD72356dA4E,(balance*250)/10000);
        withdrawInternal(0x62289aD97CEa85360a2fcD9cdADfECe9c082C423,(balance*150)/10000);
        withdrawInternal(0x29b7aAA30A47F779bFF900551A1AeA76b983ad75,(balance*150)/10000);
        withdrawInternal(0xbA4AA796ee6e3F1c38d1D00144689F71CD520976,(balance*500)/10000);
        withdrawInternal(0xc18658AEd32E150b18C4faAe73FcE4F23a0d75B3,(balance*50)/10000);
        withdrawInternal(0xC5ef721e41558203e46658D36204C7bfD5276b8C,(balance*750)/10000);
        withdrawInternal(0x7bDA20a949581C4b59B351D63e2Ff31c271E5C5c,(balance*1000)/10000);
        withdrawInternal(0xb83ce0cf4F53F82d22C98C6378E7fe337d01B1b9,(balance*150)/10000);
        withdrawInternal(0xf822e6f78CF07cac93dA749E9131dE76936FC72e,(balance*2000)/10000);
        withdrawInternal(0xfB1b6058E73E8eE71a5e2cf5d7a370b16e11D13F,(balance*25)/10000);



        
    }

    function withdrawInternal(address to,uint256 amount) internal onlyOwner{
        (bool success, ) = to.call{
            value: amount
        }("");
        require(success);
    }
}