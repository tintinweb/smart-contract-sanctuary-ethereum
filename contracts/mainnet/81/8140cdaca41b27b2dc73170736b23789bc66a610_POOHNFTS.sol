//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "ERC721Enumerable.sol";
import "Ownable.sol";

contract POOHNFTS is
    ERC721Enumerable,
    Ownable    
{
    using Strings for uint256;
    string public baseURI;
    string public baseExtension = ".json";

    bool public paused = false;

    bool public public_mint_status = true;

    string public notRevealedUri;

    bool public revealed = true;

    uint256 MAX_SUPPLY = 1000;
    uint256 public publicSaleCost = 0.62 ether;
    uint256 public specialPrice = 1.26 ether;
    uint256 public max_per_wallet = 10;
    string public contractURI;

    uint256[] public specialList;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        string memory _contractURI
    ) ERC721(_name, _symbol) {
        setBaseURI(_initBaseURI);
        contractURI = _contractURI;
        mint(1);
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // public
    function mint(uint256 _mintAmount) public payable {
        require(!paused, "Contract is paused");
        require(public_mint_status, "Public mint not available");
        require(
            totalSupply() + _mintAmount <= MAX_SUPPLY,
            "Maximum supply exceeds"
        );
        require(
            _mintAmount + balanceOf(msg.sender) <= max_per_wallet,
            "Max per wallet exceeds"
        );

        for (uint256 i = 1; i <= _mintAmount; i++) {
            if (msg.sender != owner()) {
                require(msg.value >= publicSaleCost * _mintAmount);
            }

            for (uint256 x = 0; x < specialList.length; x++) {
                if (totalSupply() + i == specialList[x]) {
                    i++;
                    x = 0;
                }
            }

            if (!_exists(totalSupply() + i)) {
                _safeMint(msg.sender, totalSupply() + i);
            }
        }
    }

    function mintSpecial(uint256 _mintAmount) public payable {
        require(!paused, "Contract is paused");
        require(
            totalSupply() + _mintAmount <= MAX_SUPPLY,
            "Maximum supply exceeds"
        );
        require(
            _mintAmount + balanceOf(msg.sender) <= max_per_wallet,
            "Max per wallet exceeds"
        );

        if (msg.sender != owner()) {
            require(msg.value >= specialPrice * _mintAmount);
        }

        uint256 z = 0;
        for (uint256 x = 0; x < specialList.length; x++) {
            if (_mintAmount > z) {
                if (!_exists(specialList[x])) {
                    _safeMint(msg.sender, specialList[x]);
                    z++;
                }
            }
        }
    }

    function dataInput(uint256[] calldata _ukranianTokenIDS) public onlyOwner {
        for (uint256 x = 0; x < _ukranianTokenIDS.length; x++) {
            specialList.push(_ukranianTokenIDS[x]);
        }
    }

    function deleteData() public onlyOwner {
        delete specialList;
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
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
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    //only owner

    function toggleReveal() public onlyOwner {
        if (revealed == false) {
            revealed = true;
        } else {
            revealed = false;
        }
    }

    function setPublicSaleCost(uint256 _publicSaleCost) public onlyOwner {
        publicSaleCost = _publicSaleCost;
    }

    function setMAX_SUPPLY(uint256 _MAX_SUPPLY) public onlyOwner {
        MAX_SUPPLY = _MAX_SUPPLY;
    }

    function setMax_per_wallet(uint256 _max_per_wallet) public onlyOwner {
        max_per_wallet = _max_per_wallet;
    }

    function setSpecialPrice(uint256 _specialPrice) public onlyOwner {
        specialPrice = _specialPrice;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function setPublic_mint_status(bool _public_mint_status) public onlyOwner {
        public_mint_status = _public_mint_status;
    }

    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}(
            ""
        );
        require(success);
    }

    function setContractURI(string calldata _contractURI) public onlyOwner {
        contractURI = _contractURI;
    }
}

/*

                                   _        _  __   ____     __    __   _          _           _ 
     /\                           | |      | |/ /  / __ \   / _|  / _| (_)        (_)         | |
    /  \     _ __    _ __    ___  | |      | ' /  | |  | | | |_  | |_   _    ___   _    __ _  | |
   / /\ \   | '_ \  | '_ \  / __| | |      |  <   | |  | | |  _| |  _| | |  / __| | |  / _` | | |
  / ____ \  | |_) | | |_) | \__ \ | |____  | . \  | |__| | | |   | |   | | | (__  | | | (_| | | |
 /_/    \_\ | .__/  | .__/  |___/ |______| |_|\_\  \____/  |_|   |_|   |_|  \___| |_|  \__,_| |_|
            | |     | |                                                                          
            |_|     |_|                                                                          

https://www.fiverr.com/appslkofficial */