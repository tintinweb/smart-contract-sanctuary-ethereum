// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./ERC1155.sol";
import "./Strings.sol";
import "./Ownable.sol";

interface TokenContract {
    function Mint(uint numberOfTokens, address toAddress, uint tokenStartIndex, uint randomNumber) external;
}

interface IVestedRandomness {
    function receiveRandomness(uint requestId, uint randomNumber) external;
}

interface VestedRandomnessContract {
    function getRandomNumber(address senderAddress, uint _modulus) external returns (uint);
}

interface Erc721Contract {
  function totalSupply() external view returns (uint256);
  function ownerOf(uint256 tokenId) external view returns (address);
  function balanceOf(address owner) external view returns (uint256);
  function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
}

contract projectP22 is ERC1155, Ownable, IVestedRandomness {
    using Strings for uint256;

    string public name = "projectP22";
    string public symbol = "PP22";

    uint256 public totalRevenue = 0;
    mapping(uint256 => uint256) perTokenClaimedAmount;
    uint256 ownerClaimedAmount = 0;
    uint256 creatorClaimedAmount = 0;
    uint256 public tokenRevenueSharingMembers = 0;

    address public revenueSharingContractAddress = 0x6Bd1517cC975f7A09B954dd606873c1801570cF0;
    address public revenueSharingCreatorAddress = 0x911B7B284B7AAd6919c81f75A0DAC93F5bB2dBc9;

    address public randomnessProviderAddress = 0x2a6C5550B697Dcf5B29B575F2bcf009220bA317B;
    bool public asyncRandomnessProvider = false;
    struct AsyncRandomnessProviderRequest {
      uint32 packId;
      address userAddress;
    }
    mapping(uint256 => AsyncRandomnessProviderRequest) public asyncRandomnessProviderRequestMapping;

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

    mapping(uint32 => string) public packProvenance;
    mapping(uint32 => uint32) public lastSelectedIndex;
    mapping(uint32 => uint32) public maxAvailableIndex;
    mapping(uint32 => address) public tokenContractAddress;
    mapping(address => uint32) public maxTokenSupply;
    mapping(uint32 => mapping(uint32 => bool)) public isTokenPicked;
    mapping(uint32 => uint256) private numOfDropPointsInPack;

    mapping(uint32 => bool) private SaleIsActiveForPack;
    mapping(uint32 => uint256) public packSaleDuration;
    mapping(uint32 => uint256) public packSaleStartTime;
    mapping(uint32 => uint128) public packStartPrice;
    mapping(uint32 => uint128) public packMinPrice;

    mapping(uint32 => mapping(uint32 => bool)) private isToadzIdClaimedFreePack;
    mapping(uint32 => bool) public isToadzFreeClaimPack;
    uint32 private toadzFreeClaimRelease = 0;

    string private baseURI = "https://gateway.pinata.cloud/ipfs/QmUQmTFJJVcpDCQPUQJ9N7hcCQBeXbsGYm2WV53pg32nXH/"; // TODO: remove static value

    Erc721Contract private revenueSharingContract;

    constructor() ERC1155("") {
        revenueSharingContract = Erc721Contract(revenueSharingContractAddress);
        tokenRevenueSharingMembers = revenueSharingContract.totalSupply();
    }

    // ***************************** internal : Start *****************************

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
            return checkIndexIsAvailbale((randomNumber/2), packId);
        }
        else {
            return newImageIndex;
        }
    }

    function getElapsedSaleTime(uint32 packId) internal view returns (uint256) {
        return packSaleStartTime[packId] > 0 ? block.timestamp - packSaleStartTime[packId] : 0;
    }

    function getNumOfDropPoints(uint256 maxPrice) internal pure returns (uint256) {
        if(maxPrice > 1000000000000000000) return (32 + ((maxPrice - 1000000000000000000) / 250000000000000000)); 
        else if (maxPrice > 50000000000000000) return (13 + ((maxPrice - 50000000000000000) / 50000000000000000)); 
        else if (maxPrice > 10000000000000000) return (9 + ((maxPrice - 10000000000000000) / 10000000000000000)); 
        else if (maxPrice > 1000000000000000) return ((maxPrice - 1000000000000000) / 1000000000000000); 
        else return 0;
    }

    function getDroppedPrice(uint256 droppedPoint) internal pure returns (uint256)  {
        if(droppedPoint > 32) return ((droppedPoint - 32) * 250000000000000000 + 1000000000000000000);
        else if(droppedPoint > 13) return ((droppedPoint - 13) * 50000000000000000 + 50000000000000000);
        else if(droppedPoint > 9) return ((droppedPoint - 9) * 10000000000000000 + 10000000000000000);
        else if(droppedPoint > 0) return ((droppedPoint) * 1000000000000000 + 1000000000000000);
        else return 1000000000000000;
    }

    function getRemainingSaleTime(uint32 packId) public view returns (uint256) {
        require(packSaleStartTime[packId] > 0, "Public sale hasn't started yet");
        if (getElapsedSaleTime(packId) >= packSaleDuration[packId]) {
            return 0;
        }
        return (packSaleStartTime[packId] + packSaleDuration[packId]) - block.timestamp;
    }

    function nowOpenPack(address senderAddress, uint32 packId, uint randomNumber) internal {
        uint newImageIndex = checkIndexIsAvailbale(lastSelectedIndex[packId] + randomNumber, packId);
        isTokenPicked[packId][uint32(newImageIndex)] = true;

        TokenContract tokenContract = TokenContract(tokenContractAddress[packId]);
        uint tokenStartIndex = startTokenIdOfPack[packId] + (newImageIndex * numOfTokensInPerPack[packId]);
        tokenContract.Mint(numOfTokensInPerPack[packId], senderAddress, tokenStartIndex, randomNumber);

        if (newImageIndex == maxAvailableIndex[packId]) {
            maxAvailableIndex[packId] -= 1;
            lastSelectedIndex[packId] = 0;
        } else {
            lastSelectedIndex[packId] = uint32(newImageIndex);
        }
        _burn(senderAddress, packId, 1);
    }
    // ***************************** internal : End *****************************

    // ***************************** onlyOwner : Start *****************************

        // Packs
    function addNewPack(uint32 newPackId, string memory _packName, string memory _packType, string memory _packDescription,
            uint32 _numOfTokensInPerPack, uint32 _maxPackSupply, address _tokenContractAddress
            ) external onlyOwner {
        require(activePacks[newPackId] == false, "Pack already active");
        activePacks[newPackId] = true;
        packName[newPackId] = _packName;
        packType[newPackId] = _packType;
        packDescription[newPackId] = _packDescription;
        numOfTokensInPerPack[newPackId] = _numOfTokensInPerPack;
        maxPackSupply[newPackId] = _maxPackSupply;
        maxAvailableIndex[newPackId] = _maxPackSupply - 1;
        startTokenIdOfPack[newPackId] = maxTokenSupply[_tokenContractAddress];
        endTokenIdOfPack[newPackId] = maxTokenSupply[_tokenContractAddress] + (_numOfTokensInPerPack*_maxPackSupply) - 1;
        maxTokenSupply[_tokenContractAddress] = endTokenIdOfPack[newPackId] + 1;
        tokenContractAddress[newPackId] = _tokenContractAddress;
    }

    function startPackSale(uint32 packId, uint128 _packStartPrice, uint128 _packMinPrice, uint256 _saleDuration) external onlyOwner {
        require(activePacks[packId], "Pack not active");
        require(SaleIsActiveForPack[packId] == false, "Sale already begun");
        packStartPrice[packId] = _packStartPrice;
        packMinPrice[packId] = _packMinPrice;
        packSaleDuration[packId] = _saleDuration;
        packSaleStartTime[packId] = block.timestamp;
        numOfDropPointsInPack[packId] = getNumOfDropPoints(_packStartPrice);
        SaleIsActiveForPack[packId] = true;
    }

    function pausePackSale(uint32 packId) external onlyOwner {
        require(activePacks[packId], "Pack not active");
        require(SaleIsActiveForPack[packId] == true, "Sale already paused");
        SaleIsActiveForPack[packId] = false;
    }

    function setSaleMinPrice(uint32 packId, uint128 _packMinPrice) external onlyOwner {
        require(activePacks[packId], "Pack not active");
        packMinPrice[packId] = _packMinPrice;
    }

    function setPackName(uint32 packId, string memory newPackName) external onlyOwner {
        require(activePacks[packId], "Pack not active");
        packName[packId] = newPackName;
    }

    function setPackType(uint32 packId, string memory newPackType) external onlyOwner {
        require(activePacks[packId], "Pack not active");
        packType[packId] = newPackType;
    }

    function setPackDescription(uint32 packId, string memory description) external onlyOwner {
        require(activePacks[packId], "Pack not active");
        packDescription[packId] = description;
    }

    function setPackProvenance(uint32 packId, string memory _provenance) external onlyOwner {
        require(activePacks[packId], "Pack not active");
        packProvenance[packId] = _provenance;
    }

    function setBaseUri(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function setRevenueSharingCreatorAddress(address newAddress) external onlyOwner {
        revenueSharingCreatorAddress = newAddress;
    }

    /**
    @notice Claim owner's share
     */
    function claimOwnerShare() external onlyOwner {
        uint256 claimValue = ((totalRevenue * 3) / 10) - ownerClaimedAmount;
        (bool success, ) = msg.sender.call{value: claimValue }("");
        ownerClaimedAmount += claimValue;
        require(success, "Transfer failed.");
    }

    function setRandomness(address _randomnessProviderAddress, bool _asyncRandomnessProvider) external onlyOwner {
        randomnessProviderAddress = _randomnessProviderAddress;
        asyncRandomnessProvider = _asyncRandomnessProvider;
    }

    function setToadzFreeClaimPack(uint32 packId, bool _isToadzFreeClaimPack) external onlyOwner {
        require(activePacks[packId], "Pack not active");
        isToadzFreeClaimPack[packId] = _isToadzFreeClaimPack;
    }

    /**
    @notice Only the Owner can call it, it will allow already claimed Toadz owner to claim free pack again
     */
    function resetOGToadTokenFreePacks() external onlyOwner {
        toadzFreeClaimRelease += 1;
    }

    // ***************************** onlyOwner : End *****************************

    // ***************************** public external : Start *****************************

    function claimToadzFreePack(uint32 toadzTokenId, uint32 packId) external {
        require(activePacks[packId], "Pack not active");
        require(isToadzIdClaimedFreePack[toadzFreeClaimRelease][toadzTokenId] == false, "Free pack already claimed for this toadz token id");
        require(revenueSharingContract.ownerOf(toadzTokenId) == msg.sender, "Your wallet does not own this token!");
        require(isToadzFreeClaimPack[packId], "Pack is not toadz free claim pack");
        require(
            suppliedPacks[packId] + 1 <= maxPackSupply[packId],
            "Count exceeds the maximum allowed supply."
        );
        suppliedPacks[packId] += 1;
        _mint(msg.sender, packId, 1, "");
        isToadzIdClaimedFreePack[toadzFreeClaimRelease][toadzTokenId] = true;
    }

    function numOfUnclaimedFreePacksOfUser(address userAddress) external view returns(uint32) {
        uint256 tokenCount = revenueSharingContract.balanceOf(userAddress);
        require(tokenCount > 0, "user don't own any toadz");

        uint32 qty = 0;
        uint256 index = 0;
        for (index = 0; index < tokenCount; index++) {
            uint256 tokenId = revenueSharingContract.tokenOfOwnerByIndex(userAddress, index);
            if(isToadzIdClaimedFreePack[toadzFreeClaimRelease][uint32(tokenId)] == false) {
                qty += 1;
            }
        }
        return qty;
    }
    
    function claimToadzAllFreePacks(uint32 packId) external {
        uint256 tokenCount = revenueSharingContract.balanceOf(msg.sender);
        require(tokenCount > 0, "you don't own any toadz");
        require(activePacks[packId], "Pack not active");
        require(isToadzFreeClaimPack[packId], "Pack is not toadz free claim pack");
        require(
            suppliedPacks[packId] + tokenCount <= maxPackSupply[packId],
            "Count exceeds the maximum allowed supply of pack."
        );
        uint32 qty = 0;
        uint256 index = 0;
        for (index = 0; index < tokenCount; index++) {
            uint256 tokenId = revenueSharingContract.tokenOfOwnerByIndex(msg.sender, index);
            if(isToadzIdClaimedFreePack[toadzFreeClaimRelease][uint32(tokenId)] == false) {
                qty += 1;
                isToadzIdClaimedFreePack[toadzFreeClaimRelease][uint32(tokenId)] = true;
            }
        }
        suppliedPacks[packId] = suppliedPacks[packId] + qty;
        _mint(msg.sender, packId, qty, "");
    }

    function toadzIdAvailableForFreePackClaim(uint32 toadzTokenId) external view returns(bool) {
        return isToadzIdClaimedFreePack[toadzFreeClaimRelease][toadzTokenId];
    }

    function MintPrice(uint32 packId) public view returns (uint256) {
        require(activePacks[packId], "Pack not active");
        uint256 elapsed = getElapsedSaleTime(packId);
        if (elapsed >= packSaleDuration[packId]) {
            return packMinPrice[packId];
        } else {
            uint256 currentPrice = getDroppedPrice(((numOfDropPointsInPack[packId] * getRemainingSaleTime(packId)) / packSaleDuration[packId]) + 1);
            return currentPrice > packMinPrice[packId] ? currentPrice : packMinPrice[packId];
        }
    }

    /**
    @notice Open pack and get NFTs
     */
    function OpenPack(uint32 packId) external {
        require(activePacks[packId], "Pack not active");
        require(balanceOf(msg.sender, packId) > 0, "You don't have any pack in your account");

        uint randomNumberRes = VestedRandomnessContract(randomnessProviderAddress).getRandomNumber(msg.sender ,maxAvailableIndex[packId] - lastSelectedIndex[packId] + 1);
        if(asyncRandomnessProvider){
            asyncRandomnessProviderRequestMapping[randomNumberRes] = AsyncRandomnessProviderRequest(packId, msg.sender);
        } else{
            nowOpenPack(msg.sender, packId, randomNumberRes);
        }        
    }

    function receiveRandomness(uint requestId, uint randomNumber) external override {
        require(randomnessProviderAddress == msg.sender, "only randomness provider contract can call this function");
        require(activePacks[asyncRandomnessProviderRequestMapping[requestId].packId], "Pack not active");
        require(balanceOf(asyncRandomnessProviderRequestMapping[requestId].userAddress, 
            asyncRandomnessProviderRequestMapping[requestId].packId) > 0, "You don't have any pack in your account");
        nowOpenPack(asyncRandomnessProviderRequestMapping[requestId].userAddress, asyncRandomnessProviderRequestMapping[requestId].packId, randomNumber);
    }

    /**
    @notice Mint pack
     */
    function Mint(uint32 count, uint32 packId) external payable {
        require(activePacks[packId], "Pack not active");
        require(SaleIsActiveForPack[packId], "Public sale is not active.");
        require(
            suppliedPacks[packId] + count <= maxPackSupply[packId],
            "Count exceeds the maximum allowed supply."
        );
        require(msg.value >= MintPrice(packId) * count, "Not enough ether.");
        suppliedPacks[packId] += count;
        _mint(msg.sender, packId, count, "");
        totalRevenue += msg.value;
    }

    function uri(uint256 id) public view override returns (string memory) {
        require(activePacks[uint32(id)], "URI requested for invalid pack");
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, id.toString())) : baseURI;
    }
    
    /**
    @notice Enter OG Cryptoadz tokenID to view unclaimed amount
     */
    function unclaimedTokenShare(uint256 tokenId) external view returns(uint256) {
        return ((totalRevenue * 6) / (10 * tokenRevenueSharingMembers))  - perTokenClaimedAmount[tokenId];
    }

    /**
    @notice Enter wallet to view unclaimed amount of all of owner's OG Cryptoadz tokenIDs 
     */
    function unclaimedAllOwnsTokensShare(address ownerAddress) external view returns(uint256) {
        uint256 tokenCount = revenueSharingContract.balanceOf(ownerAddress);
        require(tokenCount > 0, "you don't own any token");
        uint256 index;
        uint256 alreadyClaimedAmount = 0;
        uint256 perTokenClaimableAmount = ((totalRevenue * 6) / (10 * tokenRevenueSharingMembers));
        for (index = 0; index < tokenCount; index++) {
            alreadyClaimedAmount += perTokenClaimedAmount[revenueSharingContract.tokenOfOwnerByIndex(ownerAddress, index)];
        }
        return (perTokenClaimableAmount*tokenCount) - alreadyClaimedAmount;
    }

    /**
    @notice View unclaimed amount of owner's share
     */
    function unclaimedOwnerShare() external view returns(uint256) {
        return ((totalRevenue * 3) / 10)  - ownerClaimedAmount;
    }

    /**
    @notice View unclaimed amount of OG Cryptoadz Creator's share
     */
    function unclaimedCreatorShare() external view returns(uint256) {
        return (totalRevenue / 10)  - creatorClaimedAmount;
    }

    /**
    @notice Claim individual token share by OG Cryptoadz tokenID
     */
    function claimTokenShareByToken(uint256 tokenId) external {
        require(revenueSharingContract.ownerOf(tokenId) == msg.sender, "Your wallet does not own this token!");
        uint256 claimValue = ((totalRevenue * 6) / (10 * tokenRevenueSharingMembers)) - perTokenClaimedAmount[tokenId];
        (bool success, ) = msg.sender.call{value: claimValue }("");
        perTokenClaimedAmount[tokenId] += claimValue;
        require(success, "Transfer failed.");
    }

    /**
    @notice Claim creator's share 
     */
    function claimCreatorShare() external {
        require(revenueSharingCreatorAddress == msg.sender, "you can't claim creator share");
        uint256 claimValue = (totalRevenue / 10) - creatorClaimedAmount;
        (bool success, ) = msg.sender.call{value: claimValue }("");
        creatorClaimedAmount += claimValue;
        require(success, "Transfer failed.");
    }

    /**
    @notice Claim all unclaimed amount for all of your OG Cryptoadz tokenIDs
     */
    function claimTokenShare() external {
        uint256 tokenCount = revenueSharingContract.balanceOf(msg.sender);
        require(tokenCount > 0, "you don't own any token");
        uint256 index;
        uint256 alreadyClaimedAmount = 0;
        uint256 perTokenClaimableAmount = ((totalRevenue * 6) / (10 * tokenRevenueSharingMembers));
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