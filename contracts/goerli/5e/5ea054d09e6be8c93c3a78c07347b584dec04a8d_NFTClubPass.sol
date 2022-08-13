pragma solidity ^0.8.4;

// SPDX-License-Identifier: MIT

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract NFTClubPass is ERC721A, Ownable {
    
    using Strings for uint256;

    uint256 public VIP_LIST_PRICE = 0.1 ether;
    uint256 public MINT_PRICE = 0.15 ether;
    uint256 public constant MAX_SUPPLY = 250;
    uint256 public constant MAX_PER_WALLET = 1;

    mapping(address => bool) public whitelist;
    mapping(address => bool) public viplist;

    enum Status {
        NOT_LIVE,
        VIP,
        LIVE,
        ENDED
    }

    // minting variables
    string public baseURI;
    Status public state = Status.NOT_LIVE;
    uint256 public mintCount = 0;

    constructor() ERC721A("NFT Club Pass", "NFTClub") {
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function mint() external payable {
        require(state == Status.LIVE || state == Status.VIP, "NFT Club Pass: Mint Not Active");
        if(state == Status.VIP){
            require(viplist[msg.sender], "Not in viplist");
        }
        if(state == Status.LIVE){
            require(whitelist[msg.sender], "Not in whitelist");
        }
        require(mintCount < MAX_SUPPLY, "NFT Club Pass: Mint Supply Exceeded");
        require(msg.value >= (state == Status.LIVE ? MINT_PRICE : VIP_LIST_PRICE), "NFT Club Pass: Insufficient ETH");
        require(_numberMinted(msg.sender) < MAX_PER_WALLET, "NFT Club Pass: Exceeds Max Per Wallet");
        mintCount += 1;
        _safeMint(msg.sender, 1);
    }

    function setAllowList(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            whitelist[addresses[i]] = true;
        }
    }

    function resetAllowList(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            whitelist[addresses[i]] = false;
        }
    }
    
    function addWhitelist(address _newEntry) external onlyOwner {
        require(!whitelist[_newEntry], "Already in whitelist");
        whitelist[_newEntry] = true;
    }
  
    function removeWhitelist(address _newEntry) external onlyOwner {
        require(whitelist[_newEntry], "Previous not in whitelist");
        whitelist[_newEntry] = false;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function setState(Status _state) external onlyOwner {
        state = _state;
    }

    function mintForAddress(address _receiver) external onlyOwner {
        require(mintCount < MAX_SUPPLY, "NFT Club Pass: Mint Supply Exceeded");
        mintCount += 1;
        _safeMint(_receiver, 1);
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory base = _baseURI();

        return string(abi.encodePacked(base, "twisted", ".json"));
    }

    function setMintCost(uint256 _newCost) external onlyOwner {
        MINT_PRICE = _newCost;
    }

    function setVipListCost(uint256 _newCost) external onlyOwner {
        VIP_LIST_PRICE = _newCost;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Withdraw failed.");
    }
}