// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";

contract HazyHares is ERC721 {
    event Mint(address indexed from, uint256 indexed tokenId);

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    modifier onlyCollaborator() {
        bool isCollaborator = false;
        for (uint256 i; i < collaborators.length; i++) {
            if (collaborators[i].addr == msg.sender) {
                isCollaborator = true;

                break;
            }
        }

        require(
            owner() == _msgSender() || isCollaborator,
            "Ownable: caller is not the owner nor a collaborator"
        );

        _;
    }

    modifier claimStarted() {
        require(
            startClaimDate != 0 && startClaimDate <= block.timestamp,
            "You are too early"
        );

        _;
    }

    modifier presaleStarted() {
        require(
            startPresaleDate != 0 && startPresaleDate <= block.timestamp,
            "Presale not started yet"
        );

        _;
    }

    struct Collaborators {
        address addr;
        uint256 cut;
    }

    uint256 private startClaimDate = 1644699600;
    uint256 private startPresaleDate = 1644688800;
    uint256 private mintPrice = 69000000000000000;
    uint256 private presaleMintPrice = 69000000000000000;

    uint256 private totalTokens = 10000;
    uint256 private totalMintedTokens = 0;

    uint256 private maxHarePerTransactionDuringPresale = 20;
    uint256 private maxHarePerTransaction = 20;

    uint128 private basisPoints = 10000;
    string private baseURI =
        "https://hazyhares.s3.amazonaws.com/";
    
    uint256 public giveawayCount = 50;
    
    mapping(address => uint256) public claimedHarePerWallet;

    uint16[] availableHares;
    Collaborators[] private collaborators;

    mapping (address => bool) whitelistedAddresses;

    uint256 private firstFreeProbabilityGenerator = 10;
    uint256 private secondFreeProbabilityGenerator = 13;
    uint256 private thirdFreeProbabilityGenerator = 20;
    uint256 private fourthFreeProbabilityGenerator = 40;

    uint256 private firstProbabilitySwitch = 2000;
    uint256 private secondProbabilitySwitch = 4000;
    uint256 private thirdProbabilitySwitch = 6000;
    uint256 private fourthProbabilitySwitch = 8000;

    uint256 private targetValue = 7;

    constructor() ERC721("HazyHaresNFT", "HZH") {}

    // ONLY OWNER

    /**
     * Sets the collaborators of the project with their cuts
     */
    function addCollaborators(Collaborators[] memory _collaborators)
        external
        onlyOwner
    {
        require(collaborators.length == 0, "Collaborators were already set");

        uint128 totalCut;
        for (uint256 i; i < _collaborators.length; i++) {
            collaborators.push(_collaborators[i]);
            totalCut += uint128(_collaborators[i].cut);
        }

        require(totalCut == basisPoints, "Total cut does not add to 100%");
    }

    // ONLY COLLABORATORS

    /**
     * @dev Allows to withdraw the Ether in the contract and split it among the collaborators
     */
    function withdraw() external onlyCollaborator {
        uint256 totalBalance = address(this).balance;

        for (uint256 i; i < collaborators.length; i++) {
            payable(collaborators[i].addr).transfer(
                mulScale(totalBalance, collaborators[i].cut, basisPoints)
            );
        }
    }

    /**
     * @dev Sets the base URI for the API that provides the NFT data.
     */
    function setBaseTokenURI(string memory _uri) external onlyCollaborator {
        baseURI = _uri;
    }

    /**
     * @dev Sets the claim price for each hare in public sale
     */
    function setMintPrice(uint256 _mintPrice) external onlyCollaborator {
        mintPrice = _mintPrice;
    }

    /**
     * @dev Sets the claim price for each hare in presale
     */
    function setPresaleMintPrice(uint256 _presaleMintPrice) external onlyCollaborator {
        presaleMintPrice = _presaleMintPrice;
    }

    /**
     * @dev Sets the giveaway count
     */
    function setGiveawayCount(uint256 _giveawayCount) external onlyCollaborator {
        giveawayCount = _giveawayCount;
    }

    /**
     * @dev Sets the firstFreeProbabilityGenerator
     */
    function setFirstFreeProbabilityGenerator(uint256 _firstFreeProbabilityGenerator) external onlyCollaborator {
        firstFreeProbabilityGenerator = _firstFreeProbabilityGenerator;
    }

    /**
     * @dev Sets the secondFreeProbabilityGenerator
     */
    function setSecondFreeProbabilityGenerator(uint256 _secondFreeProbabilityGenerator) external onlyCollaborator {
        secondFreeProbabilityGenerator = _secondFreeProbabilityGenerator;
    }

     /**
     * @dev Sets the thirdFreeProbabilityGenerator
     */
    function setThirdFreeProbabilityGenerator(uint256 _thirdFreeProbabilityGenerator) external onlyCollaborator {
        thirdFreeProbabilityGenerator = _thirdFreeProbabilityGenerator;
    }

    /**
     * @dev Sets the fourthFreeProbabilityGenerator
     */
    function setFourthFreeProbabilityGenerator(uint256 _fourthFreeProbabilityGenerator) external onlyCollaborator {
        fourthFreeProbabilityGenerator = _fourthFreeProbabilityGenerator;
    }

    /**
     * @dev Populates the available hares
     */
    function addAvailableHares(uint16 from, uint16 to)
        external
        onlyCollaborator
    {
        for (uint16 i = from; i <= to; i++) {
            availableHares.push(i);
        }
    }

    /**
     * @dev Removes a chosen hare from the available list, only a utility function
     */
    function removeHareFromAvailableHares(uint16 tokenId)
        external
        onlyCollaborator
    {
        for (uint16 i; i <= availableHares.length; i++) {
            if (availableHares[i] != tokenId) {
                continue;
            }

            availableHares[i] = availableHares[availableHares.length - 1];
            availableHares.pop();

            break;
        }
    }

    /**
     * @dev Sets the date that users can start claiming hares
     */
    function setStartClaimDate(uint256 _startClaimDate)
        external
        onlyCollaborator
    {
        startClaimDate = _startClaimDate;
    }

    /**
     * @dev Sets the date that users can start claiming hares for presale
     */
    function setStartPresaleDate(uint256 _startPresaleDate)
        external
        onlyCollaborator
    {
        startPresaleDate = _startPresaleDate;
    }

    /**
     * @dev Checks if a hare is in the available list
     */
    function isHareAvailable(uint16 tokenId)
        external
        view
        onlyCollaborator
        returns (bool)
    {
        for (uint16 i; i < availableHares.length; i++) {
            if (availableHares[i] == tokenId) {
                return true;
            }
        }

        return false;
    }


    /**
     * @dev Give random hares to the provided address
     */
    function reserveGiveawayHares(address _address)
        external
        onlyCollaborator
    {
        require(availableHares.length >= giveawayCount, "No hares left to be claimed");
        
        totalMintedTokens += giveawayCount;

        uint256[] memory tokenIds = new uint256[](giveawayCount);

        for (uint256 i; i < giveawayCount; i++) {
            tokenIds[i] = getHareToBeClaimed();
        }

        _batchMint(_address, tokenIds);
        giveawayCount = 0;
    }

    /**
    * @dev Whitelist addresses
     */
    function whitelistAddress (address[] memory users) external onlyCollaborator {
        for (uint i = 0; i < users.length; i++) {
            whitelistedAddresses[users[i]] = true;
        }
    }

    /**
     * @dev Claim up to 20 hares at once
     */
    function claimHares(uint256 quantity)
        external
        payable
        callerIsUser
        claimStarted
        returns (uint256[] memory)
    {
        require(
            msg.value >= mintPrice * quantity,
            "Not enough Ether to claim the Hares"
        );
        
        require(quantity <= maxHarePerTransaction, "You can only claim 20 Hares per transaction");
        
        require(availableHares.length >= quantity, "Not enough hares left");

        require(availableHares.length - giveawayCount >= quantity, "No Hares left to be claimed");

        // means that available hares is between 10k and 8k
        if (availableHares.length <= 10000 && availableHares.length > 10000 - firstProbabilitySwitch) {
            uint256 randomNumber = _random(firstFreeProbabilityGenerator);
            if (randomNumber == targetValue) {
                quantity = quantity + 1;
            }
        } 
        // means that available hares is between 8k and 6k
        else if (availableHares.length <= 10000 - firstProbabilitySwitch && availableHares.length > 10000 - secondProbabilitySwitch) {
            uint256 randomNumber = _random(secondFreeProbabilityGenerator);
            if (randomNumber == targetValue) {
                quantity = quantity + 1;
            }
        } 
        // means that available hares is between 6k and 4k
        else if (availableHares.length <= 10000 - secondProbabilitySwitch && availableHares.length > 10000 - thirdProbabilitySwitch) {
            uint256 randomNumber = _random(thirdFreeProbabilityGenerator);
            if (randomNumber == targetValue) {
                quantity = quantity + 1;
            }
        } 
        // means that available hares is between 4k and 2k
        else if (availableHares.length <= 10000 - thirdProbabilitySwitch && availableHares.length > 10000 - fourthProbabilitySwitch) {
            uint256 randomNumber = _random(fourthFreeProbabilityGenerator);
            if (randomNumber == targetValue) {
                quantity = quantity + 1;
            }
        }

        uint256[] memory tokenIds = new uint256[](quantity);

        claimedHarePerWallet[msg.sender] += quantity;
        totalMintedTokens += quantity;

        for (uint256 i; i < quantity; i++) {
            tokenIds[i] = getHareToBeClaimed();
        }

        _batchMint(msg.sender, tokenIds);
        return tokenIds;
    }

    /**
     * @dev Claim up to 20 hares at once in presale
     */
    function presaleMintHares(uint256 quantity)
        external
        payable
        callerIsUser
        presaleStarted
        returns (uint256[] memory)
    {
        require(
            msg.value >= presaleMintPrice * quantity,
            "Not enough Ether to claim the Hares"
        );
        
        require(quantity <= maxHarePerTransactionDuringPresale, "You can only claim 20 hares per transaction");

        require(availableHares.length >= quantity, "Not enough hares left");

        require(availableHares.length - giveawayCount >= quantity, "No Hares left to be claimed");

        // means that available hares is between 10k and 8k
        if (availableHares.length <= 10000 && availableHares.length > 10000 - firstProbabilitySwitch) {
            uint256 randomNumber = _random(firstFreeProbabilityGenerator);
            if (randomNumber == targetValue) {
                quantity = quantity + 1;
            }
        } 
        // means that available hares is between 8k and 6k
        else if (availableHares.length <= 10000 - firstProbabilitySwitch && availableHares.length > 10000 - secondProbabilitySwitch) {
            uint256 randomNumber = _random(secondFreeProbabilityGenerator);
            if (randomNumber == targetValue) {
                quantity = quantity + 1;
            }
        } 
        // means that available hares is between 6k and 4k
        else if (availableHares.length <= 10000 - secondProbabilitySwitch && availableHares.length > 10000 - thirdProbabilitySwitch) {
            uint256 randomNumber = _random(thirdFreeProbabilityGenerator);
            if (randomNumber == targetValue) {
                quantity = quantity + 1;
            }
        } 
        // means that available hares is between 4k and 2k
        else if (availableHares.length <= 10000 - thirdProbabilitySwitch && availableHares.length > 10000 - fourthProbabilitySwitch) {
            uint256 randomNumber = _random(fourthFreeProbabilityGenerator);
            if (randomNumber == targetValue) {
                quantity = quantity + 1;
            }
        }

        uint256[] memory tokenIds = new uint256[](quantity);

        claimedHarePerWallet[msg.sender] += quantity;
        totalMintedTokens += quantity;

        for (uint256 i; i < quantity; i++) {
            tokenIds[i] = getHareToBeClaimed();
        }

        _batchMint(msg.sender, tokenIds);
        return tokenIds;
    }

    /**
     * @dev Returns the tokenId by index
     */
    function tokenByIndex(uint256 tokenId) external view returns (uint256) {
        require(
            _exists(tokenId),
            "ERC721: operator query for nonexistent token"
        );

        return tokenId;
    }

    /**
     * @dev Returns the base URI for the tokens API.
     */
    function baseTokenURI() external view returns (string memory) {
        return baseURI;
    }

    /**
     * @dev Returns how many Hares are still available to be claimed
     */
    function getAvailableHares() external view returns (uint256) {
        return availableHares.length;
    }

    /**
     * @dev Returns the claim price
     */
    function getmintPrice() external view returns (uint256) {
        return mintPrice;
    }

    /**
     * @dev Returns the total supply
     */
    function totalSupply() external view virtual returns (uint256) {
        return totalMintedTokens;
    }

    // Private and Internal functions

    /**
     * @dev Returns a random available Hare to be claimed
     */
    function getHareToBeClaimed() private returns (uint256) {
        uint256 random = _getRandomNumber(availableHares.length);
        uint256 tokenId = uint256(availableHares[random]);

        availableHares[random] = availableHares[availableHares.length - 1];
        availableHares.pop();

        return tokenId;
    }

    /**
     * @dev Generates a pseudo-random number.
     */
    function _getRandomNumber(uint256 _upper) private view returns (uint256) {
        uint256 random = uint256(
            keccak256(
                abi.encodePacked(
                    availableHares.length,
                    blockhash(block.number - 1),
                    block.coinbase,
                    block.difficulty,
                    msg.sender
                )
            )
        );

        return random % _upper;
    }

    /**
     * @dev Generates a pseudo-random number given a range
     */
    function _random(uint256 _upper) private view returns (uint256) {
        uint256 randomHash = uint256(keccak256(abi.encodePacked(block.timestamp, blockhash(block.number - 1), block.difficulty, msg.sender)));
        return randomHash % _upper;
    } 

    /**
     * @dev See {ERC721}.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function mulScale(
        uint256 x,
        uint256 y,
        uint128 scale
    ) internal pure returns (uint256) {
        uint256 a = x / scale;
        uint256 b = x % scale;
        uint256 c = y / scale;
        uint256 d = y % scale;

        return a * c * scale + a * d + b * c + (b * d) / scale;
    }
}