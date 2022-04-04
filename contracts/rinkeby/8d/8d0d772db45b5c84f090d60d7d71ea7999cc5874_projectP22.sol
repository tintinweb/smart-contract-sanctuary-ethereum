// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./ERC1155.sol";
import "./Strings.sol";
import "./Ownable.sol";

interface TokenContract {
    function Mint(uint numberOfTokens, address toAddress, uint tokenStartIndex) external;
}

interface Erc721Contract {
    function transferFrom(address from, address to, uint256 tokenId) external;
}

interface IERC721Receiver {
    function onERC721Received (address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

contract projectP22 is ERC1155, Ownable, IERC721Receiver {
    using Strings for uint256;

    string public name = "projectP22";
    string public symbol = "PP22";

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

    // Golden tickets
    bool public isGoldenTicketOpeningActive;
    mapping(uint32 => bool) public activeGoldenTickets;
    mapping(uint32 => string) public goldenTicketName;
    mapping(uint32 => string) public goldenTicketDescription;
    mapping(uint32 => uint32) public goldenTicketTotalSupply;
    mapping(uint32 => uint32) public suppliedGoldenTickets;

    mapping(uint32 => address) public tokenContractOfGoldenTicket;
    mapping(address => uint32) public goldenTicketOfTokenContract;
    mapping(uint32 => address) public goldenTokenAddressOfGoldenTicket;
    mapping(address => uint32) public goldenTicketOfGoldenTokenAddress;

    mapping(address => uint32) public goldenTicketTokenCount;
    mapping(uint32 => uint32) public goldenTicketTokenMinAvailableIndex;
    mapping(uint32 => uint32) public goldenTicketTokenMaxAvailableIndex;
    mapping(uint32 => mapping(uint32 => uint256)) public goldenTicketTokens;
    mapping(uint32 => mapping(uint256 => uint32)) public goldenTicketTokenIndex;
    mapping(uint32 => mapping(uint32 => bool)) public isGoldenTicketTokenIndexPicked;

    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) public virtual override returns (bytes4) {
        uint32 gt = goldenTicketOfGoldenTokenAddress[msg.sender];
        goldenTicketTokens[gt][goldenTicketTokenCount[msg.sender]] = tokenId;
        goldenTicketTokenIndex[gt][tokenId] = goldenTicketTokenCount[msg.sender];
        goldenTicketTokenCount[msg.sender] += 1;
        return this.onERC721Received.selector;
    }

    string private baseURI = "https://gateway.pinata.cloud/ipfs/QmUQmTFJJVcpDCQPUQJ9N7hcCQBeXbsGYm2WV53pg32nXH/"; // TODO: remove static value

    uint32 public saleStart = 1646510400; // TODO: update value before deploy

    constructor() ERC1155("") {}

    // ***************************** internal : Start *****************************

    function getRandomNumber(uint _modulus) internal view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % _modulus;
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
        require(activeGoldenTickets[newPackId] == false, "Pack id already used in golden ticket");
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

        // Golden tickets
    function addGoldenTicket(uint32 newGoldenTicketId, string memory _goldenTicketName, string memory _goldenTicketDescription, uint32 _goldenTicketTotalSupply,
            address _tokenContractAddress, address goldenTokenContractAddress) external onlyOwner {
        require(activePacks[newGoldenTicketId] == false, "Pack already active");
        require(goldenTicketOfTokenContract[_tokenContractAddress] == 0 , "One golden ticket already added for same token contract address");
        require(activeGoldenTickets[newGoldenTicketId] == false, "Pack id already used in golden ticket");
        require(newGoldenTicketId > 0, "Golden pack id must be greater than 0");
        activeGoldenTickets[newGoldenTicketId] = true;
        goldenTicketName[newGoldenTicketId] = _goldenTicketName;
        goldenTicketDescription[newGoldenTicketId] = _goldenTicketDescription;
        goldenTicketTotalSupply[newGoldenTicketId] = _goldenTicketTotalSupply;

        tokenContractOfGoldenTicket[newGoldenTicketId] = _tokenContractAddress;
        goldenTicketOfTokenContract[_tokenContractAddress] = newGoldenTicketId;
        goldenTokenAddressOfGoldenTicket[newGoldenTicketId] = goldenTokenContractAddress;
        goldenTicketOfGoldenTokenAddress[goldenTokenContractAddress] = newGoldenTicketId;
    }

    function setGoldenTicketName(uint32 _goldenTicketId, string memory _goldenTicketName) external onlyOwner {
        goldenTicketName[_goldenTicketId] = _goldenTicketName;
    }

    function setGoldenTicketDescription(uint32 _goldenTicketId, string memory _goldenTicketDescription) external onlyOwner {
        goldenTicketDescription[_goldenTicketId] = _goldenTicketDescription;
    }

    function setGoldenTicketTotalSupply(uint32 _goldenTicketId, uint32 _goldenTicketTotalSupply) external onlyOwner {
        goldenTicketTotalSupply[_goldenTicketId] = _goldenTicketTotalSupply;
    }

    function setGoldenTicketOpeningActive() external onlyOwner {
        isGoldenTicketOpeningActive = true;
    }

    function setGoldenTicketOpeningClose() external onlyOwner {
        isGoldenTicketOpeningActive = false;
    }

    function claimGoldenTicket(address luckyUserAddress) external {
        uint32 gtId = goldenTicketOfTokenContract[msg.sender];
        require(gtId > 0, "invalid claimer, you can't claim golden ticket");
        require(
            suppliedGoldenTickets[gtId] + 1 <= goldenTicketTotalSupply[gtId],
            "Count exceeds the maximum allowed supply."
        );
        suppliedGoldenTickets[gtId] += 1;
        _mint(luckyUserAddress, gtId, 1, "");
    }

    // function redeemGoldenTicket() external onlyOwner {
    //    	// - Get random number
    //     // - Pick token from pool
    //     // - Transfer NFT to user
    //     // - Burn golden ticket
    //     uint256 randomNumber = getRandomNumber(100);
    // }

    function setSaleStart(uint32 timestamp) external onlyOwner {
        saleStart = timestamp;
    }

    function setBaseUri(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
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
    }

    function uri(uint256 id) public view override returns (string memory) {
        require(activePacks[uint32(id)] || activeGoldenTickets[uint32(id)] , "URI requested for invalid pack");
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, id.toString())) : baseURI;
    }

    // ***************************** public external : End *****************************
}