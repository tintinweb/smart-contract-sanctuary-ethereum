// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
import "./ERC721.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./Address.sol";

contract DogeColaEcosystem is ERC721, Ownable {
    using Strings for uint256;

    string public baseURI;
    string public baseExtension = ".json";
    string public notRevealedUri;
    uint256 public cost = 0.06 ether;
    uint256 public costWL = 0.05 ether;
    uint256 public costOG = 0.04 ether;
    uint256 public maxSupply = 2000;
    uint256 public maxMintAmountOG = 6;
    uint256 public maxMintAmountWL = 3;
    uint256 public maxMintAmount = 2000;
    uint256 public nftPerAddressLimitOG = 6;
    uint256 public nftPerAddressLimitWL = 3;
    uint256 public nftPerAddressLimit = 2000;
    uint256 allTokens = 0;
    bool public revealed = false;
    mapping(address => uint256) public addressMintedBalance;

    uint256 public currentState = 0;
    address[] public whitelistedAddresses;
    address[] public ogAddresses;

    constructor() ERC721("DogeCola Ecosystem", "DCE") {
        setNotRevealedURI(
            "ipfs://QmZPYLRhtw66XC9TbmnFZayCAndZso9qTUNeiuggkAju6x"
        );
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function mint(uint256 _mintAmount) public payable {
        uint256 supply = totalSupply();
        require(_mintAmount > 0, "need to mint at least 1 NFT");
        require(supply + _mintAmount <= maxSupply, "max NFT limit exceeded");
        if (msg.sender != owner()) {
            require(currentState > 0, "the contract is paused");
            uint256 ownerMintedCount = addressMintedBalance[msg.sender];

            if (currentState == 1) {
                require(isOGed(msg.sender), "user is not whitelisted");
                require(
                    msg.value >= costOG * _mintAmount,
                    "insufficient funds"
                );
                require(
                    _mintAmount <= maxMintAmountOG,
                    "max mint amount per session exceeded"
                );
                require(
                    ownerMintedCount + _mintAmount <= nftPerAddressLimitOG,
                    "max NFT per address exceeded"
                );
            } else if (currentState == 2) {
                require(isWhitelisted(msg.sender), "user is not whitelisted");
                require(
                    msg.value >= costWL * _mintAmount,
                    "insufficient funds"
                );
                require(
                    _mintAmount <= maxMintAmountWL,
                    "max mint amount per session exceeded"
                );
                require(
                    ownerMintedCount + _mintAmount <= nftPerAddressLimitWL,
                    "max NFT per address exceeded"
                );
            } else {
                require(msg.value >= cost * _mintAmount, "insufficient funds");
            }
        }

        for (uint256 i = 1; i <= _mintAmount; i++) {
            addressMintedBalance[msg.sender]++;
            _safeMint(msg.sender, supply + i);
            allTokens++;
        }
    }

    function totalSupply() public view returns (uint256) {
        return allTokens;
    }

    function isWhitelisted(address _user) public view returns (bool) {
        for (uint256 i = 0; i < whitelistedAddresses.length; i++) {
            if (whitelistedAddresses[i] == _user) {
                return true;
            }
        }
        return false;
    }

    function isOGed(address _user) public view returns (bool) {
        for (uint256 i = 0; i < ogAddresses.length; i++) {
            if (ogAddresses[i] == _user) {
                return true;
            }
        }
        return false;
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

        if (revealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, tokenId.toString()))
                : "";
    }

    //only owner
    function reveal() public onlyOwner {
        revealed = true;
    }

    function setNftPerAddressLimit(uint256 _limit) public onlyOwner {
        nftPerAddressLimit = _limit;
    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
        maxMintAmount = _newmaxMintAmount;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function pause() public onlyOwner {
        currentState = 0;
    }

    function setOnlyOG() public onlyOwner {
        currentState = 1;
    }

    function setOnlyWhitelisted() public onlyOwner {
        currentState = 2;
    }

    function setPublic() public onlyOwner {
        currentState = 3;
    }

    function ogUsers(address[] calldata _users) public onlyOwner {
        delete ogAddresses;
        ogAddresses = _users;
    }

    function whitelistUsers(address[] calldata _users) public onlyOwner {
        delete whitelistedAddresses;
        whitelistedAddresses = _users;
    }

    function setPublicCost(uint256 _price) public onlyOwner {
        cost = _price;
    }

    function setOGCost(uint256 _price) public onlyOwner {
        costOG = _price;
    }

    function setWLCost(uint256 _price) public onlyOwner {
        costWL = _price;
    }

    function withdraw() public payable onlyOwner {
        // This will payout the owner the contract balance.
        // Do not remove this otherwise you will not be able to withdraw the funds.
        // =============================================================================
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
        // =============================================================================
    }
}