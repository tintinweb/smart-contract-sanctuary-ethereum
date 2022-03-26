// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./ERC1155.sol";
import "./Strings.sol";
import "./Ownable.sol";

contract projectP22 is ERC1155, Ownable {
    using Strings for uint256;

    string public name = "projectP22";
    string public symbol = "PP22";
    uint32 public totalSupply = 0;
    uint32 public maxTokenSupply = 0;
    mapping(uint32 => bool) public activeReleases;

    uint256 typeId = 1;

    mapping(uint32 => string) public packName;
    mapping(uint32 => string) public packType;
    mapping(uint32 => string) public packDescription;
    mapping(uint32 => uint32) public numOfTokensInPerPack;
    mapping(uint32 => uint32) public maxPackSupply;
    mapping(uint32 => uint32) public suppliedPacks;
    mapping(uint32 => uint32) public startTokenIdOfRelease;
    mapping(uint32 => uint32) public endTokenIdOfRelease;
    mapping(uint32 => uint) public packPrice;
    mapping(uint32 => uint) public lastSelectedIndex;
    mapping(uint32 => uint) public maxAvailableIndex;

    mapping(uint32 => mapping(uint => bool)) public isImagePicked;
    
    string private baseURI = "https://gateway.pinata.cloud/ipfs/QmWxwUsJop9qPBzzUFqpqELTicSUvJwwvqXeRake5MJbDq";

    uint public saleStart = 1646510400;

    constructor() ERC1155("") {}

    function addNewRelease(uint32 newPackId, string memory newPackName, string memory newPackType, string memory description, uint32 numOfTokensInPack, uint32 maxPackSupplyInPack, uint price) external onlyOwner {
        require(activeReleases[newPackId] == false, "Release already active");
        activeReleases[newPackId] = true;
        packName[newPackId] = newPackName;
        packType[newPackId] = newPackType;
        packDescription[newPackId] = description;
        numOfTokensInPerPack[newPackId] = numOfTokensInPack;
        maxPackSupply[newPackId] = maxPackSupplyInPack;
        packPrice[newPackId] = price;

        startTokenIdOfRelease[newPackId] = maxTokenSupply;
        endTokenIdOfRelease[newPackId] = maxTokenSupply + (numOfTokensInPack*maxPackSupplyInPack) - 1;

        maxTokenSupply = maxTokenSupply + (numOfTokensInPack*maxPackSupplyInPack);
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
    function updatePackPrice(uint32 packId, uint price) external onlyOwner {
        packPrice[packId] = price;
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

    // function checkIndexIsAvailbale(uint randomNumber) internal returns (uint) {
    //     uint j=0;
    //     bool matchFound = false;
    //     uint newImageIndex = 0;
    //     for (j = randomNumber; j <= maxAvailableIndex && matchFound == false; j += 1) {
    //         if(isImagePicked[j] != true) {
    //             matchFound = true;
    //             newImageIndex = j;
    //             break;
    //         }
    //     }

    //     if(matchFound == false) {
    //         maxAvailableIndex = randomNumber - 1;
    //         lastSelectedIndex = 0;
    //         return checkIndexIsAvailbale(getRandomNumber(maxAvailableIndex - lastSelectedIndex));
    //     }
    //     else {
    //         return newImageIndex;
    //     }
    // }

    // function openPack() external {
    //     // require(balanceOf(msg.sender, typeId) > 0, "You don't have any pack in your account");
    //     uint newImageIndex = checkIndexIsAvailbale(lastSelectedIndex + getRandomNumber(maxAvailableIndex - lastSelectedIndex));
    //     isImagePicked[newImageIndex] = true;
    //     if (newImageIndex == maxAvailableIndex) {
    //         maxAvailableIndex -= 1;
    //         lastSelectedIndex = 0;
    //     } else {
    //         lastSelectedIndex = newImageIndex;
    //     }
    //     // _burn(msg.sender, typeId, 1);
    // }

    // function mint(uint32 count) external payable {
    //     // require(saleIsActive(), "Public sale is not active.");
    //     require(
    //         totalSupply + count <= maxSupply,
    //         "Count exceeds the maximum allowed supply."
    //     );
    //     require(msg.value >= price * count, "Not enough ether.");
    //     totalSupply += count;
    //     _mint(msg.sender, typeId, count, "");
    // }

    // function burnPack(address burnTokenAddress) external {
    //     require(msg.sender == mutationContract, "Invalid burner address");
    //     _burn(burnTokenAddress, typeId, 1);
    // }

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
            id == typeId,
            "URI requested for invalid serum type"
        );
        return baseURI;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
}