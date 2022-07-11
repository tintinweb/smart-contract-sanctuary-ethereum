// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";


// .S_SsS_S.     sSSs  sdSS_SSSSSSbs   .S_SSSs            sSSs_sSSs     .S_sSSs     .S_SSSs      sSSs  
//.SS~S*S~SS.   d%%SP  YSSS~S%SSSSSP  .SS~SSSSS          d%%SP~YS%%b   .SS~YS%%b   .SS~SSSSS    d%%SP  
//S%S `Y' S%S  d%S'         S%S       S%S   SSSS        d%S'     `S%b  S%S   `S%b  S%S   SSSS  d%S'    
//S%S     S%S  S%S          S%S       S%S    S%S        S%S       S%S  S%S    S%S  S%S    S%S  S%|     
//S%S     S%S  S&S          S&S       S%S SSSS%S        S&S       S&S  S%S    d*S  S%S SSSS%P  S&S     
//S&S     S&S  S&S_Ss       S&S       S&S  SSS%S        S&S       S&S  S&S   .S*S  S&S  SSSY   Y&Ss    
//S&S     S&S  S&S~SP       S&S       S&S    S&S        S&S       S&S  S&S_sdSSS   S&S    S&S  `S&&S   
//S&S     S&S  S&S          S&S       S&S    S&S        S&S       S&S  S&S~YSY%b   S&S    S&S    `S*S  
//S*S     S*S  S*b          S*S       S*S    S&S        S*b       d*S  S*S   `S%b  S*S    S&S     l*S  
//S*S     S*S  S*S.         S*S       S*S    S*S        S*S.     .S*S  S*S    S%S  S*S    S*S    .S*P  
//S*S     S*S   SSSbs       S*S       S*S    S*S         SSSbs_sdSSS   S*S    S&S  S*S SSSSP   sSS*S   
//SSS     S*S    YSSP       S*S       SSS    S*S          YSSP~YSSY    S*S    SSS  S*S  SSY    YSS'    
//        SP                SP               SP                        SP          SP                  
//        Y                 Y                Y                         Y           Y                  

contract METAORBSWTF is ERC721A, Ownable {
    uint256 public maxSupply = 5555;
    uint256 public maxPerWallet = 6;
    uint256 public maxPerTx = 2;
    uint256 public _price = 0 ether;

    bool public activated;
    string public unrevealedTokenURI =
        "https://gateway.pinata.cloud/ipfs/QmPYyPrbCUcN3UioMcVXx3f3a6Z6bk4sH8g9fQyC2hxRPm";
    string public baseURI = "";

    mapping(uint256 => string) private _tokenURIs;

    address private _ownerWallet = 0x4893f3b932B9ff4281B3a22d964ea5cCC71060aA;

    constructor( ) ERC721A("metaorbswtf", "METAORB") {
    }

    ////  OVERIDES
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return
            bytes(baseURI).length != 0
                ? string(abi.encodePacked(baseURI, _toString(tokenId), ".json"))
                : unrevealedTokenURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    ////  MINT
    function mint(uint256 numberOfTokens) external payable {
        require(activated, "Inactive");
        require(totalSupply() + numberOfTokens <= maxSupply, "All minted");
        require(numberOfTokens <= maxPerTx, "Too many for Tx");
        require(
            _numberMinted(msg.sender) + numberOfTokens <= maxPerWallet,
            "Too many for address"
        );
        _safeMint(msg.sender, numberOfTokens);
    }

    ////  SETTERS
    function setTokenURI(string calldata newURI) external onlyOwner {
        baseURI = newURI;
    }

    function setMaxPerTx(uint256 _maxPerTx) external onlyOwner {
        maxPerTx = _maxPerTx;
    }

    function setMaxPerWallet(uint256 _maxPerWallet) external onlyOwner {
        maxPerWallet = _maxPerWallet;
    }

    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    function setIsActive(bool _isActive) external onlyOwner {
        activated = _isActive;
    }
}