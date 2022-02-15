// SPDX-License-Identifier: MIT
/*  
+ + + - - - - - - - - - - - - - - - - - - - - - - - - - - - ++ - - - - - - - - - - - - - - - - - - - - - - - - - - + + +      
+                                                                                                                      +
+                                                                                                                      +
.                                              @@@     @@@@@@@@@@@/    @@@                                             .
.                                        #@@@@@@@@     @@@@@@@@@@@/    @@@@@@@@#                                       .
.                                   @@@@@@@@@@@@@@     @@@@@@@@@@@/    @@@@@@@@@@@@@@                                  .    
.                             &@@@@@@@@@@@@@@@@@@@     @@@@@@@@@@@/    @@@@@@@@@@@@@@@@@@@&                            .
.                       /@@@@@@@@@@@@@@@@@@@@@@@@@     @@@@@@@@@@@/    @@@@@@@@@@@@@@@@@@@@@@@@@/                      .
.                     @@@@@@@@@@@@@@@@@@@@@@@@@@@@     @@@@@@@@@@@/    @@@@@@@@@@@@@@@@@@@@@@@@@@@@                    .
.                     @@@@@@@@@@@      @@@@@@@@@@@     @@@@@@@@@@@/    @@@@@@@@@@@      @@@@@@@@@@@                    .                   
.                     @@@@@@@@@@@      @@@@@@@@@@@     @@@@@@@@@@@/    @@@@@@@@@@@@    @@@@@@@@@@@@                    . 
.                     @@@@@@                @@@@@@     @@@@@@@@@@@/    @@@@@@     @@@@@@     @@@@@@                    . 
.                     @@@@@#                @@@@@@     @@@@@@@@@@@/    @@@@@@     @@@@@@     %@@@@@                    . 
.                     @@@@@@@@@@@      @@@@@@@@@@@     @@@@@@@@@@@/    @@@@@@@@@@@@    @@@@@@@@@@@@                    . 
.                     @@@@@@@@@@@      @@@@@@@@@@@     @@@@@@@@@@@/    @@@@@@@@@@@      @@@@@@@@@@@                    . 
.                     @@@@@@@@@@@@@@@@@@@@@@@@@@@@     @@@@@@@@@@@/    @@@@@@@@@@@@@@@@@@@@@@@@@@@@                    . 
.                     @@@@@@@@@@@@@@@@@@@@@@@@@@@@     @@@@@@@@@@@/    @@@@@@@@@@@@@@@@@@@@@@@@@@@@                    . 
.                     @@@@@@@@@@@@@@@@@@@@@@@@@@@@     @@@@@@@@@@@/    @@@@@@@@@@@@@@@@@@@@@@@@@@@@                    . 
.                     @@@@@@@@@@@@                     @@@@@@@@@@@/                    @@@@@@@@@@@@                    . 
.                     @@@@@@@@@@@@                     @@@@@@@@@@@/                    @@@@@@@@@@@@                    . 
.                     @@@@@@@@@@@@                     @@@@@@@@@@@@@@@@@@@@@@@@@@@     @@@@@@@@@@@@                    . 
.                     @@@@@@@@@@@@                     @@@@@@@@@@@@@@@@@@@@@@@@@@@     @@@@@@@@@@@@                    . 
.                     @@@@@@@@@@@@                     @@@@@@@@@@@@@@@@@@@@@@@@@@@     @@@@@@@@@@@@                    . 
.                                                                                                                      .
.                                                                                                                      .
.                     @@@@@@@@@@@@        #@@@        ,@@@@@@@@@@@(    @@@@@@@@@@@@    @@@@@@@@@@@@                    . 
.                     @@@                /@@/@@       ,@@  &@@  @@(    @@              @@                              .
.                     @@@    %@@@@      ,@@. %@@      ,@@  &@@  @@(    @@@@@@@@@       @@@@@@@@@@@@                    . 
.                     @@@       @@     [email protected]@,   @@@     ,@@  &@@  @@(    @@                       (@@                    . 
.                     @@@@@@@@@@@@     @@(  %@@@@@    ,@@  &@@  @@(    @@@@@@@@@@@@    @@@@@@@@@@@@                    .
+                                                                                                                      +
+                                                                                                                      +
+ + + - - - - - - - - - - - - - - - - - - - - - - - - - - - ++ - - - - - - - - - - - - - - - - - - - - - - - - - - + + +
*/
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./ERC721Enumerable.sol";

contract TestNFT is ERC721, Pausable, Ownable, ERC721Enumerable {
    using Counters for Counters.Counter;

    Counters.Counter public _tokenIdCounter;
    uint256 public constant MAX_SUPPLY = 4;
    uint256 public constant PRICE_PER_TOKEN = 50000000000000000; // 0.05 ETH
    uint256 public constant MAX_PUBLIC_MINT = 5;

    constructor() ERC721("Beryl Test NFTs", "tBRL") {
    }

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://QmboUuStzRhthiw1HGr5uS7DWQ8zVgRUfCdAJyDHmqDGUs/";
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function safeMint(uint numberOfTokens) public whenNotPaused payable {
        uint256 ts = totalSupply();
        require(ts + numberOfTokens <= MAX_SUPPLY, "Purchase would exceed max tokens");
        require(numberOfTokens <= MAX_PUBLIC_MINT, "Exceeded max token purchase");
        require(PRICE_PER_TOKEN * numberOfTokens <= msg.value, "Ether value sent is not correct");

        for (uint256 i = 0; i < numberOfTokens; i++) {              
            _safeMint(msg.sender, _tokenIdCounter.current() );      
            _tokenIdCounter.increment();
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

}