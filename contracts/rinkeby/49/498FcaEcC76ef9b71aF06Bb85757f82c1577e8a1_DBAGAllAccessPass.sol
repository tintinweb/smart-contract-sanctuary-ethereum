// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
import "ERC721Enumerable.sol";
import "Ownable.sol";

contract DBAGAllAccessPass is ERC721Enumerable, Ownable {
    using Strings for uint256;
    address public DBAGNFTAddress = 0x0000000000000000000000000000000000000000;
    string public baseURI;
    uint256 public cost = 0.001 ether;
    uint256 public maxSupply = 20000;
    bool public pausedMint = true;
    bool public pausedRedeem = true;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _ipfsURI
    ) ERC721(_name, _symbol) {
        setBaseURI(_ipfsURI);
    }

    //=================================INTERNAL FUNCTIONS================================//
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    //=================================PUBLIC FUNCTIONS================================//
    function redeem(
        address _address /*, uint256 _amountToBurn*/
    ) public {
        require(!pausedRedeem, "The contract is paused for redeeming");
        uint256[] memory tokensFromAddress = walletOfOwner(_address);
        require(tokensFromAddress.length > 0, "No pass to redeem");
        address[] memory addressArray = new address[](1);
        addressArray[0] = _address;
        //for(uint256 i = 0; i < _amountToBurn; i++) {
        safeTransferFrom(
            _address,
            0x000000000000000000000000000000000000dEaD,
            tokensFromAddress[0]
        );
        bytes memory payload = abi.encodeWithSignature(
            "redeemNFT(address[],uint256)",
            addressArray,
            tokensFromAddress[0]
        );
        (bool success, ) = address(DBAGNFTAddress).call(payload);
        require(success, "redeemNFT FAIL");
        //}
    }

    function mint(uint256 _mintAmount) public payable {
        require(!pausedMint, "The contract is paused for minting");
        uint256 supply = totalSupply();
        require(
            _mintAmount > 0 && _mintAmount <= 20,
            "Need to mint between 1 and 20 NFTs"
        );
        require(supply + _mintAmount <= maxSupply, "Max NFT limit exceeded");
        require(msg.value >= cost * _mintAmount, "Insufficient funds");
        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(msg.sender, supply + i);
        }
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
        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        ".json"
                    )
                )
                : "";
    }

    //=================================ONLY OWNER FUNCTIONS================================//
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function pauseMint(bool _state) public onlyOwner {
        pausedMint = _state;
    }

    function pauseRedeem(bool _state) public onlyOwner {
        pausedRedeem = _state;
    }

    function setDBAGNFTAddress(address _DBAGNFTAddress) public onlyOwner {
        DBAGNFTAddress = _DBAGNFTAddress;
    }

    function withdraw() public payable onlyOwner {
        (bool os, ) = payable(msg.sender).call{value: address(this).balance}(
            ""
        );
        require(os);
    }
}