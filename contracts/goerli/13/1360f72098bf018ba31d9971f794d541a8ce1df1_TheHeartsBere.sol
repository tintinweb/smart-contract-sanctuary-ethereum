// SPDX-License-Identifier: MIT
//  YGGP#@@#PGGJ [email protected]@J     [email protected]@  [email protected]@GPGGGG5        YGP:    :PGY  :PPGGGGGGGB7     .5GGY      :PPGGGGGGPJ^  JGGGGPPGGGGY !GG   @[email protected]?        P&&######G?Y   !&&J  5&###&&###&PP
//      [email protected]@7     [email protected]@J     [email protected]@  [email protected]&:              [email protected]@^    ^@@G  ^@@#???????~     [email protected]@@@J     ^@@#????J#@@7 [email protected]@G??J7 ~G   [email protected]@[email protected] [email protected]@[email protected]@Y   [email protected]@Y  ##5##[email protected]@5##^^ 
//      [email protected]@?     [email protected]@#BBBBB&@@  [email protected]@BBBBBB~        [email protected]@~.::[email protected]@G  ^@@G.......     [email protected]@[email protected]@7    ^@@G     [email protected]@Y     [email protected]@J     ^!   [email protected]@J!               [email protected]@      @BY   [email protected]@Y      [email protected]@J     
//      [email protected]@?     [email protected]@P77777#@@  [email protected]@?77777:        [email protected]@&&&&&&@@G  ^@@@&&&&&&B.   [email protected]@Y  [email protected]@~   ^@@&BB#B#&BJ.     [email protected]@J     .      G&@@@&GJ:         [email protected]@#####@@PY   [email protected]@Y      [email protected]@J     
//      [email protected]@?     [email protected]@J     [email protected]@  [email protected]&:              [email protected]@!:^^:[email protected]@G  ^@@G:::::::   ^&@@[email protected]@&:  ^@@[email protected]@B!       [email protected]@J                 !J&@#:       [email protected]@      [email protected]@   [email protected]@Y      [email protected]@J
//      [email protected]@?     [email protected]@J     [email protected]@  [email protected]@#BBBBBB:       [email protected]@^    ^@@G  ^@@G.::::::: .#@&YYYYYY&@B. ^@@G   ^[email protected]@5.     [email protected]@J          [email protected]@B~   ^#@&:       [email protected]@[email protected]&   [email protected]@Y      [email protected]@Y
//      JPG5     ?PGP.    BPG  BGGGGGGGGB?       [email protected]&^    ^&@G  ^&@&&&&&&&&P [email protected]&!      [email protected]@P ^&@P     J&@B^    [email protected]@J           ~P&@&#&@&P~        5BBBBBBBBPJ:   ~BB?      !BB?  



pragma solidity 0.8.17;

import "./ERC721A.sol";
import "./Strings.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract TheHeartsBere is ERC721A, Ownable, ReentrancyGuard {

    using Strings for uint256;

    string public hiddenURL ;
    string public uriPrefix ;
    string private uriSuffix = ".json";
    
    uint256 public cost = 0.003 ether;

    uint256 public maxSupply = 6969;    
    
    uint256 public maxPerTx = 5;
    uint256 public maxPerWallet = 10;

    bool public mintOnline = false;

    bool public reveal = false;

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        string memory _hiddenMetadataUri
    ) ERC721A(_tokenName, _tokenSymbol) {}

    modifier mintCompliance(uint256 quantity) {

        require(quantity > 0,
         "Hey Crypto Virgins");

        require(totalSupply() + quantity <= maxSupply,
         "No E-Girls left");
        _;
    }

    function mintPublic(uint256 quantity)
     public
     payable
     mintCompliance(quantity) 
     nonReentrant 
    {
        require(mintOnline, "Offline");

        require(msg.value >= quantity * cost, "Unlock For 0.003 ETH");

        require(quantity <= maxPerTx, "Crypto Virgin it's 5 Per TX");

        require(_numberMinted(_msgSender()) + quantity <= maxPerWallet,
            "Let some for your Crypto Virgin friends!"
        );

        _safeMint(msg.sender, quantity);

    }

    function airdrop(uint256 quantity, address _to) 
    public 
    onlyOwner 
    mintCompliance(quantity) 
    {
        _safeMint(_to, quantity);
    }

    function setCost(uint256 _cost) public onlyOwner {
        cost = _cost;
    }

    function setOnline(bool _mintOnline) public onlyOwner {
        mintOnline = _mintOnline;
    }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        maxSupply = _maxSupply;
    }
    
    function tokenURI(uint256 _tokenId)
    public
    view
    virtual
    override
    returns (string memory)
    {
    require(
      _exists(_tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );
    if (reveal == false)
    {
       return hiddenURL;
    }
    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString() ,uriSuffix))
        : "";
    }

    function setUriPrefix(string memory _uriPrefix) external onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function setHiddenUri(string memory _uriPrefix) external onlyOwner {
        hiddenURL = _uriPrefix;
    }

    function setRevealed() external onlyOwner{
       reveal = !reveal;
    }

    function _baseURI() internal view  override returns (string memory) {
        return uriPrefix;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function withdraw() public onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success, "Bankruptcy :( ");
    }
}