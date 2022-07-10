// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";


// .S_SsS_S.     sSSs  sdSS_SSSSSSbs   .S_SSSs              .S    sSSs_sSSs      sSSSSs    sSSSSs    sSSs   .S_sSSs      sSSs  
//.SS~S*S~SS.   d%%SP  YSSS~S%SSSSSP  .SS~SSSSS            .SS   d%%SP~YS%%b    d%%%%SP   d%%%%SP   d%%SP  .SS~YS%%b    d%%SP  
//S%S `Y' S%S  d%S'         S%S       S%S   SSSS           S%S  d%S'     `S%b  d%S'      d%S'      d%S'    S%S   `S%b  d%S'    
//S%S     S%S  S%S          S%S       S%S    S%S           S%S  S%S       S%S  S%S       S%S       S%S     S%S    S%S  S%|     
//S%S     S%S  S&S          S&S       S%S SSSS%S           S&S  S&S       S&S  S&S       S&S       S&S     S%S    d*S  S&S     
//S&S     S&S  S&S_Ss       S&S       S&S  SSS%S           S&S  S&S       S&S  S&S       S&S       S&S_Ss  S&S   .S*S  Y&Ss    
//S&S     S&S  S&S~SP       S&S       S&S    S&S           S&S  S&S       S&S  S&S       S&S       S&S~SP  S&S_sdSSS   `S&&S   
//S&S     S&S  S&S          S&S       S&S    S&S           S&S  S&S       S&S  S&S sSSs  S&S sSSs  S&S     S&S~YSY%b     `S*S  
//S*S     S*S  S*b          S*S       S*S    S&S           d*S  S*b       d*S  S*b `S%%  S*b `S%%  S*b     S*S   `S%b     l*S  
//S*S     S*S  S*S.         S*S       S*S    S*S          .S*S  S*S.     .S*S  S*S   S%  S*S   S%  S*S.    S*S    S%S    .S*P  
//S*S     S*S   SSSbs       S*S       S*S    S*S        sdSSS    SSSbs_sdSSS    SS_sSSS   SS_sSSS   SSSbs  S*S    S&S  sSS*S   
//SSS     S*S    YSSP       S*S       SSS    S*S        YSSY      YSSP~YSSY      Y~YSSY    Y~YSSY    YSSP  S*S    SSS  YSS'    
//        SP                SP               SP                                                            SP                  
//        Y                 Y                Y                                                             Y                   
                                                                                                                             

contract METAJOGGERS is ERC721A, Ownable {
    uint256 public maxSupply = 1333;
    uint256 public maxPerWallet = 3;
    uint256 public maxPerTx = 1;
    uint256 public _price = 0 ether;

    bool public activated;
    string public unrevealedTokenURI =
        "https://gateway.pinata.cloud/ipfs/QmYQH2oSRfw2FiugG84ETWtDXSSVfD9BwHPzhFbwnbgwGa";
    string public baseURI = "";

    mapping(uint256 => string) private _tokenURIs;

    address private _ownerWallet = 0xFc2F7BB19A515d13C5Fd8eE8571DFD55ec23110c;

    constructor( ) ERC721A("metajoggers", "METAJOGGER") {
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