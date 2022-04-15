// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./ERC1155.sol";
import "./Strings.sol";
import "./Ownable.sol";

interface TokenContract {
    function Mint(uint numberOfTokens, address toAddress, uint tokenStartIndex) external;
}

interface Erc721Contract {
  function totalSupply() external view returns (uint256);
  function ownerOf(uint256 tokenId) external view returns (address);
  function balanceOf(address owner) external view returns (uint256);
  function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
}

contract projectP22 is ERC1155, Ownable {
    using Strings for uint256;

    string public name = "projectP22";
    string public symbol = "PP22";

    uint randNonce = 0;

    uint256 totalEarning = 0;
    mapping(uint256 => uint256) perTokenClaimedAmount;
    uint256 ownerClaimedAmount = 0;
    uint256 creatorClaimedAmount = 0;
    uint256 public tokenRevenueSharingMembers = 0;

    address public revenueSharingContractAddress = 0xf1183A89c576aa07f5DBE5a13ca4B42855fb6545;
    address public revenueSharingCreatorAddress = 0x911B7B284B7AAd6919c81f75A0DAC93F5bB2dBc9;

    // Packs 
    mapping(uint32 => bool) public activePacks;
    mapping(uint32 => string) public packName;
    mapping(uint32 => string) public packType;
    mapping(uint32 => string) public packDescription;
    mapping(uint32 => uint32) public numOfTokensInPerPack;
    mapping(uint32 => uint32) public maxPackSupply;
    mapping(uint32 => uint32) public suppliedPacks;
    mapping(uint32 => uint32) public startTokenIdOfPack;
    mapping(uint32 => uint32) public endTokenIdOfPack;
    mapping(uint32 => uint128) public packPrice;
    mapping(uint32 => string) public packProvenance;
    mapping(uint32 => uint32) public lastSelectedIndex;
    mapping(uint32 => uint32) public maxAvailableIndex;
    mapping(uint32 => address) public tokenContractAddress;
    mapping(address => uint32) public maxTokenSupply;
    mapping(uint32 => mapping(uint32 => bool)) public isTokenPicked;

    string private baseURI = "https://gateway.pinata.cloud/ipfs/QmUQmTFJJVcpDCQPUQJ9N7hcCQBeXbsGYm2WV53pg32nXH/"; // TODO: remove static value

    uint32 public saleStart = 1646510400; // TODO: update value before deploy

    Erc721Contract private revenueSharingContract;

    constructor() ERC1155("") {
        revenueSharingContract = Erc721Contract(revenueSharingContractAddress);
        tokenRevenueSharingMembers = revenueSharingContract.totalSupply();
    }

    // ***************************** internal : Start *****************************

    function getRandomNumber(uint _modulus) internal returns (uint) {
        randNonce++;
        return uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, randNonce))) % _modulus;
    }

    function checkIndexIsAvailbale(uint randomNumber, uint32 packId) internal returns (uint) {
        uint j=0;
        bool matchFound = false;
        uint newImageIndex = 0;
        for (j = randomNumber; j <= maxAvailableIndex[packId] && matchFound == false; j = j + 1) {
            if(isTokenPicked[packId][uint32(j)] != true) {
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

    // ***************************** internal : End *****************************

    // ***************************** onlyOwner : Start *****************************

        // Packs
    function addNewPack(uint32 newPackId, string memory _packName, string memory _packType, string memory _packDescription, uint32 _numOfTokensInPerPack, uint32 _maxPackSupply, uint128 _packPrice, address _tokenContractAddress) external onlyOwner {
        require(activePacks[newPackId] == false, "Pack already active");
        activePacks[newPackId] = true;
        packName[newPackId] = _packName;
        packType[newPackId] = _packType;
        packDescription[newPackId] = _packDescription;
        numOfTokensInPerPack[newPackId] = _numOfTokensInPerPack;
        maxPackSupply[newPackId] = _maxPackSupply;
        packPrice[newPackId] = _packPrice;
        maxAvailableIndex[newPackId] = _maxPackSupply - 1;
        startTokenIdOfPack[newPackId] = maxTokenSupply[_tokenContractAddress];
        endTokenIdOfPack[newPackId] = maxTokenSupply[_tokenContractAddress] + (_numOfTokensInPerPack*_maxPackSupply) - 1;
        maxTokenSupply[_tokenContractAddress] = endTokenIdOfPack[newPackId] + 1;
        tokenContractAddress[newPackId] = _tokenContractAddress;
    }

    function setPackName(uint32 packId, string memory newPackName) external onlyOwner {
        packName[packId] = newPackName;
    }

    function setPackType(uint32 packId, string memory newPackType) external onlyOwner {
        packType[packId] = newPackType;
    }

    function setPackDescription(uint32 packId, string memory description) external onlyOwner {
        packDescription[packId] = description;
    }

    function setPackPrice(uint32 packId, uint128 price) external onlyOwner {
        packPrice[packId] = price;
    }

    function setPackProvenance(uint32 packId, string memory _provenance) external onlyOwner {
        packProvenance[packId] = _provenance;
    }

    function setSaleStart(uint32 timestamp) external onlyOwner {
        saleStart = timestamp;
    }

    function setBaseUri(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function setRevenueSharingCreatorAddress(address newAddress) external onlyOwner {
        revenueSharingCreatorAddress = newAddress;
    }

    function claimOwnerShare() external onlyOwner {
        uint256 claimValue = ((totalEarning * 3) / 10) - ownerClaimedAmount;
        (bool success, ) = msg.sender.call{value: claimValue }("");
        ownerClaimedAmount += claimValue;
        require(success, "Transfer failed.");
    }

    // ***************************** onlyOwner : End *****************************

    // ***************************** public external : Start *****************************

    function saleIsActive() public view returns (bool) {
        return saleStart <= block.timestamp;
    }

    function OpenPack(uint32 packId) external {
        require(activePacks[packId], "Pack not active");
        require(balanceOf(msg.sender, packId) > 0, "You don't have any pack in your account");
        uint newImageIndex = checkIndexIsAvailbale(lastSelectedIndex[packId] + getRandomNumber(maxAvailableIndex[packId] - lastSelectedIndex[packId] + 1), packId);
        isTokenPicked[packId][uint32(newImageIndex)] = true;

        TokenContract tokenContract = TokenContract(tokenContractAddress[packId]);
        uint tokenStartIndex = startTokenIdOfPack[packId] + (newImageIndex * numOfTokensInPerPack[packId]);
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
        suppliedPacks[packId] += count;
        _mint(msg.sender, packId, count, "");
        totalEarning += msg.value;
    }

    function uri(uint256 id) public view override returns (string memory) {
        require(activePacks[uint32(id)], "URI requested for invalid pack");
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, id.toString())) : baseURI;
    }
    
    function unclaimedTokenShare(uint256 tokenId) external view returns(uint256) {
        return ((totalEarning * 6) / (10 * tokenRevenueSharingMembers))  - perTokenClaimedAmount[tokenId];
    }

    function unclaimedAllOwnsTokensShare(address ownerAddress) external view returns(uint256) {
        uint256 tokenCount = revenueSharingContract.balanceOf(ownerAddress);
        require(tokenCount > 0, "you don't own any token");
        uint256 index;
        uint256 alreadyClaimedAmount = 0;
        uint256 perTokenClaimableAmount = ((totalEarning * 6) / (10 * tokenRevenueSharingMembers));
        for (index = 0; index < tokenCount; index++) {
            alreadyClaimedAmount += perTokenClaimedAmount[revenueSharingContract.tokenOfOwnerByIndex(ownerAddress, index)];
        }
        return (perTokenClaimableAmount*tokenCount) - alreadyClaimedAmount;
    }

    function unclaimedOwnerShare() external view returns(uint256) {
        return ((totalEarning * 3) / 10)  - ownerClaimedAmount;
    }

    function unclaimedCreatorShare() external view returns(uint256) {
        return (totalEarning / 10)  - creatorClaimedAmount;
    }

    function claimTokenShareByToken(uint256 tokenId) external {
        require(revenueSharingContract.ownerOf(tokenId) == msg.sender, "Your wallet does not own this token!");
        uint256 claimValue = ((totalEarning * 6) / (10 * tokenRevenueSharingMembers)) - perTokenClaimedAmount[tokenId];
        (bool success, ) = msg.sender.call{value: claimValue }("");
        perTokenClaimedAmount[tokenId] += claimValue;
        require(success, "Transfer failed.");
    }

    function claimCreatorShare() external {
        require(revenueSharingCreatorAddress == msg.sender, "you can't claim creator share");
        uint256 claimValue = (totalEarning / 10) - creatorClaimedAmount;
        (bool success, ) = msg.sender.call{value: claimValue }("");
        creatorClaimedAmount += claimValue;
        require(success, "Transfer failed.");
    }

    /**
    @notice Add an address to the set of accepted signers.
     */
    function claimTokenShare() external {
        uint256 tokenCount = revenueSharingContract.balanceOf(msg.sender);
        require(tokenCount > 0, "you don't own any token");
        uint256 index;
        uint256 alreadyClaimedAmount = 0;
        uint256 perTokenClaimableAmount = ((totalEarning * 6) / (10 * tokenRevenueSharingMembers));
        for (index = 0; index < tokenCount; index++) {
            uint256 tokenId = revenueSharingContract.tokenOfOwnerByIndex(msg.sender, index);
            alreadyClaimedAmount += perTokenClaimedAmount[tokenId];
            perTokenClaimedAmount[tokenId] = perTokenClaimableAmount;
        }
        uint256 claimValue = (perTokenClaimableAmount*tokenCount) - alreadyClaimedAmount;
        (bool success, ) = msg.sender.call{value: claimValue }("");
        require(success, "Transfer failed.");
    }
    // ***************************** public external : End *****************************
}