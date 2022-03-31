// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./ERC1155.sol";
import "./Strings.sol";
import "./Ownable.sol";

interface TokenContract {
    function Mint(uint numberOfTokens, address toAddress, uint tokenStartIndex) external;
}


interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

contract projectP22 is ERC1155, Ownable {
    using Strings for uint256;

    string public name = "projectP22";
    string public symbol = "PP22";

    mapping(uint32 => bool) public activeReleases;

    mapping(uint32 => string) public packName;
    mapping(uint32 => string) public packType;
    mapping(uint32 => string) public packDescription;
    mapping(uint32 => uint32) public numOfTokensInPerPack;
    mapping(uint32 => uint32) public maxPackSupply;
    mapping(uint32 => uint32) public suppliedPacks;
    mapping(uint32 => uint32) public startTokenIdOfRelease;
    mapping(uint32 => uint32) public endTokenIdOfRelease;
    mapping(uint32 => uint128) public packPrice;
    mapping(uint32 => string) public packProvenance;
    mapping(uint32 => uint32) public lastSelectedIndex;
    mapping(uint32 => uint32) public maxAvailableIndex;
    mapping(uint32 => address) public tokenContractAddress;
    mapping(address => uint32) public maxTokenSupply;

    // function onERC721Received(
    //     address operator,
    //     address from,
    //     uint256 tokenId,
    //     bytes calldata data
    // ) external override returns (bytes4) {
    //     return 0x150b7a02;
    // }

    mapping(uint32 => mapping(uint32 => bool)) public isImagePicked;

    string private baseURI = "https://gateway.pinata.cloud/ipfs/QmRmNVJWRxG6F5UpBZtSC1QbNMg229VPNurzjLKgKf633N/";

    uint32 public saleStart = 1646510400;

    constructor() ERC1155("") {}

    function addNewRelease(uint32 newPackId, string memory newPackName, string memory newPackType, string memory description, uint32 numOfTokensInPack, uint32 maxPackSupplyInPack, uint128 price, address _tokenContractAddress) external onlyOwner {
        require(activeReleases[newPackId] == false, "Release already active");
        activeReleases[newPackId] = true;
        packName[newPackId] = newPackName;
        packType[newPackId] = newPackType;
        packDescription[newPackId] = description;
        numOfTokensInPerPack[newPackId] = numOfTokensInPack;
        maxPackSupply[newPackId] = maxPackSupplyInPack;
        packPrice[newPackId] = price;
        maxAvailableIndex[newPackId] = maxPackSupplyInPack - 1;
        startTokenIdOfRelease[newPackId] = maxTokenSupply[_tokenContractAddress];
        endTokenIdOfRelease[newPackId] = maxTokenSupply[_tokenContractAddress] + (numOfTokensInPack*maxPackSupplyInPack) - 1;
        maxTokenSupply[_tokenContractAddress] = endTokenIdOfRelease[newPackId] + 1;
        tokenContractAddress[newPackId] = _tokenContractAddress;
    }

    function updatePackName(uint32 packId, string memory newPackName) external onlyOwner {
        packName[packId] = newPackName;
    }

    function updatePackType(uint32 packId, string memory newPackType) external onlyOwner {
        packType[packId] = newPackType;
    }

    function updatePackDescription(uint32 packId, string memory description) external onlyOwner {
        packDescription[packId] = description;
    }

    function updatePackPrice(uint32 packId, uint128 price) external onlyOwner {
        packPrice[packId] = price;
    }

    function setPackProvenance(uint32 packId, string memory _provenance) external onlyOwner {
        packProvenance[packId] = _provenance;
    }

    function setSaleStart(uint32 timestamp) external onlyOwner {
        saleStart = timestamp;
    }

    function saleIsActive() public view returns (bool) {
        return saleStart <= block.timestamp;
    }

    function getRandomNumber(uint _modulus) public view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % _modulus;
    }

    function checkIndexIsAvailbale(uint randomNumber, uint32 packId) internal returns (uint) {
        uint j=0;
        bool matchFound = false;
        uint newImageIndex = 0;
        for (j = randomNumber; j <= maxAvailableIndex[packId] && matchFound == false; j = j + 1) {
            if(isImagePicked[packId][uint32(j)] != true) {
                matchFound = true;
                newImageIndex = j;
                break;
            }
        }
        if(matchFound == false) {
            maxAvailableIndex[packId] = uint32(randomNumber - 1);
            lastSelectedIndex[packId] = 0;
            return checkIndexIsAvailbale(getRandomNumber(maxAvailableIndex[packId] - lastSelectedIndex[packId] + 1), packId);
        }
        else {
            return newImageIndex;
        }
    }

    function OpenPack(uint32 packId) external {
        require(activeReleases[packId], "Release not active");
        require(balanceOf(msg.sender, packId) > 0, "You don't have any pack in your account");
        uint newImageIndex = checkIndexIsAvailbale(lastSelectedIndex[packId] + getRandomNumber(maxAvailableIndex[packId] - lastSelectedIndex[packId] + 1), packId);
        isImagePicked[packId][uint32(newImageIndex)] = true;

        TokenContract tokenContract = TokenContract(tokenContractAddress[packId]);
        uint tokenStartIndex = startTokenIdOfRelease[packId] + (newImageIndex * numOfTokensInPerPack[packId]);
        tokenContract.Mint(numOfTokensInPerPack[packId], msg.sender, tokenStartIndex);

        if (newImageIndex == maxAvailableIndex[packId]) {
            maxAvailableIndex[packId] -= 1;
            lastSelectedIndex[packId] = 0;
        } else {
            lastSelectedIndex[packId] = uint32(newImageIndex);
        }
        _burn(msg.sender, packId, 1);
    }

    function Mint(uint32 count, uint32 packId) external payable {
        require(saleIsActive(), "Public sale is not active.");
        require(
            suppliedPacks[packId] + count <= maxPackSupply[packId],
            "Count exceeds the maximum allowed supply."
        );
        require(msg.value >= packPrice[packId] * count, "Not enough ether.");
        suppliedPacks[packId] += suppliedPacks[packId];
        _mint(msg.sender, packId, count, "");
    }

    function updateBaseUri(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function uri(uint256 id)
        public
        view
        override 
        returns (string memory)
    {
        require(
            activeReleases[uint32(id)],
            "URI requested for invalid pack"
        );
        return bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, id.toString()))
                : baseURI;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
}