// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%@@@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@       @@@@@@@@@@@@@@@@@@@@@@@@@@@        (@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@          @@@@@@@@              #@@@   *@.   @@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@            @@@#                         @    @@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@     @@@@@@@@,                             @  @@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@     @@                                     @ *@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@      @                                      @@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@    @                 @@&                     @@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@ ,@             &@@@@@@@[email protected]@        @@@@@@@@@   @@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@            @@@@@@@@@@@@&@@     @@@@@@@@@@@*    *@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@              @@@@@@@@@@@@@ @    @@@@@@@@@@@@(   @  @@@@@@@@@@@@
        @@@@@@@@@@@@                    @@@@@@@@@@@.      @@@@@@@@@@@     @@@@@@@@@@@@@@
        @@@@@@@@@@@@  @@                    @@@@@               @@@       @@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@                    @@@@@@   #@@@@@@@   @@@@*       @@@@@@@@@@@@@
        @@@@@@@@@@@@@@                    @@@,      %@@@@@ @   @@@@@         @@@@@@@@@@@
        @@@@@@@@@@@@@                     @@@@                  &%@(       % @@@@@@@@@@@
        @@@@@@@@@@@.   ,                    (                              @@@@@@@@@@@@@
        @@@@@@@@@@@@  @@                                                   @@@@@@@@@@@@@
        @@@@@@@@@@@@  @@@                                                 @@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@        @@                                    @@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@&   @@@                                  @@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@    @@@@     @@@                @  @@   @@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@(   @@@@@#   @@@@@  %@@ @@      @@@@@   @@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@     @@@@@@@@@@@@    /@@@@@@@@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
*/

/// @creator:         Mutant Hamsters
/// @author:          BGOuk

import "./Ownable.sol";
import "./Strings.sol";
import "./MerkleProof.sol";
import "ERC721A.sol";
import "./MutantHamstersYield.sol";


contract MutantHamsters is MutantHamstersYield {
    using Strings for uint256;

    string baseURI;
    uint256 public constant _maxSupply = 3333;
    uint256 public constant _maxMint = 3323;
    uint256 public constant _maxMintAmountPerAddressPublic = 5;
    uint256 public constant _maxMintAmountPerAddressWL = 3;
    uint256 public constant _WLCost = 0.04 ether;
    uint256 public constant _PublicCost = 0.06 ether;
    bool public _mintOpened;
    uint256 public publicSaleAfter;
    bytes32 public immutable _WLroot;

    constructor(
        string memory initialBaseURI,
        bytes32 WLroot
    ) ERC721A("Mutant Hamsters", "MH",_maxMintAmountPerAddressPublic,_maxSupply) {
        baseURI = initialBaseURI;
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

        
            require(_numberMinted(msg.sender) + mintAmount <= _maxMintAmountPerAddressPublic,"Maximum mint amount exceeded");
                
            price = _PublicCost * mintAmount;
        
        require(msg.value >= price,"Not Enough ETH");
        
        require((_maxMint - totalSupply()) - mintAmount >= 0,"Not Enough Mintable Token");

        _safeMint(msg.sender,mintAmount);
        yieldToken.updateRewardOnMint(msg.sender);

    }

    function presaleMint(uint256 mintAmount,bytes32[] memory proof) public payable{
        require(_mintOpened, "Minting now allowed yet");
        require(mintAmount > 0,"The quantity cannot be a negative number");
        uint256 mintedToken = _numberMinted(msg.sender);
        bool presale = true;
        uint256 price = 0;

        if(block.timestamp > publicSaleAfter) presale = false;

        
        if(presale && _verify(msg.sender,proof,_WLroot)){
            price = getPresaleCost(mintAmount,_WLCost,msg.sender);
        }
        else revert("Pre-Sale is over");

        require(mintedToken + mintAmount <= (_maxMintAmountPerAddressPublic),"Maximum mint amount exceeded");
        

        require(msg.value >= price,"Not Enough ETH");
        
        require((_maxMint - totalSupply()) - mintAmount >= 0,"Not Enough Mintable Token");

        _safeMint(msg.sender,mintAmount);
        yieldToken.updateRewardOnMint(msg.sender);



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

    function toggleMint() external onlyOwner{
        _mintOpened = !_mintOpened;
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
        withdrawInternal(0x321011E9BcDF93F57174f9Afd28083701ee27634,(balance*200)/1000);
        withdrawInternal(0xfB1b6058E73E8eE71a5e2cf5d7a370b16e11D13F,(balance*200)/1000);
        withdrawInternal(0xF9080Ac7188724d898665fD61A25caD56C62F9d3,(balance*100)/1000);
        withdrawInternal(0x7f69789732d31AF98b2766dBdf23a69612D2B5C5,(balance*100)/1000);
        withdrawInternal(0x1b207D0A58892BDCE713bd90D0aF63eF8C2435AA,(balance*100)/1000);
        withdrawInternal(0x2D3cca8356aD7Bb654499B1ba8BA4e26346d3Edf,(balance*100)/1000);
        withdrawInternal(0xb83ce0cf4F53F82d22C98C6378E7fe337d01B1b9,(balance*35)/1000);
        withdrawInternal(0x29b7aAA30A47F779bFF900551A1AeA76b983ad75,(balance*35)/1000);
        withdrawInternal(0x433AA2913eFc08042899aB9b6fCFC7B7E901Fa8a,(balance*50)/1000);
        withdrawInternal(0xCF06446c0372Bf1BB771d0E9AD9c16fD0d3cdD7B,(balance*30)/1000);
        withdrawInternal(0x55C1D22188A6b195b30E354E59D16fe35e853F33,(balance*20)/1000);
        withdrawInternal(0xf37ed805aA7bCf1C98d91B75d0c4DAA89773C560,(balance*20)/1000);
        withdrawInternal(0xFC5127d20e8775eEEF3db7F34340d01B635A0525,(balance*10)/1000);
        
    }

    function withdrawInternal(address to,uint256 amount) internal onlyOwner{
        (bool success, ) = to.call{
            value: amount
        }("");
        require(success);
    }
}