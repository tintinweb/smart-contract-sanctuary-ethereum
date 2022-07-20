// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";



contract ForjFree is ERC721Enumerable, Ownable {

    using SafeMath for uint256;
    using Strings for uint256;

    // Time of when the sale starts.
    uint256 public blockStart;
    uint256 public blockEnd;

    uint256 public MAX_SUPPLY;
    uint256 public maxMintAmount;
    uint256 public mintedAmount;
    string public baseURI;
    string public uri;
    string public metaDataExt = ".json";

    mapping(address => uint256) public mintedPerAddress;
    mapping(address => bool) public isAdmin;

    modifier onlyAdminOrOwner(address _address) {
        require(isAdmin[_address] || _address == owner(), 'This address is not allowed');
        _;
    }

    constructor(
        string memory name,
        string memory symbol,
        string memory URI,
        uint256 initialSupply,
        uint256 startDate,
        uint256 endDate,
        uint256 _limitPerAddress
    ) ERC721(name, symbol) {
        baseURI = URI;
        blockStart = startDate;
        blockEnd = endDate;
        maxMintAmount = _limitPerAddress;
        MAX_SUPPLY = initialSupply;
    }

    // owner settings
    function setContractOwnership(address newOwner) public onlyOwner {
        transferOwnership(newOwner);
    }

    // admin settings
    function setContractAdmin(address _address) public onlyOwner {
        isAdmin[_address] = true;
    }

    function deleteContractAdmin(address _address) public onlyOwner {
        isAdmin[_address] = false;
    }

    // minting period settings
    function setMintingTime(uint256 startDate, uint256 endDate) public onlyAdminOrOwner(msg.sender) {
        // require(block.timestamp <= blockStart, "Sale has already started.");
        blockStart = startDate;
        blockEnd = endDate;
    }

    // max supply settings
    function setMaxSupply(uint256 supply) public onlyOwner {
        MAX_SUPPLY = supply;
    }

    // mint allowance settings
    function setMintAllowance(uint256 _newmaxMintAmount) public onlyAdminOrOwner(msg.sender) {
        maxMintAmount = _newmaxMintAmount;
    }

    // set NFT baseUri and extension
    function setNftMetadata(string memory _newBaseURI, string memory _newExt) public onlyAdminOrOwner(msg.sender) {
        baseURI = _newBaseURI;
        metaDataExt = _newExt;
    }

    // mint
    function mint(address mintAddress) external onlyAdminOrOwner(msg.sender) {
        require(block.timestamp >= blockStart && block.timestamp <= blockEnd, "Exception: Mint isn't available");
        require(totalSupply() < MAX_SUPPLY, "Exception: All was minted.");
        require(mintedPerAddress[mintAddress] < maxMintAmount, "Exception: Reached the limit for each user. You can't mint no more");
        _safeMint(mintAddress, totalSupply());
        mintedPerAddress[mintAddress] = SafeMath.add(mintedPerAddress[mintAddress], 1);
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
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), metaDataExt))
            : "";
    }
}