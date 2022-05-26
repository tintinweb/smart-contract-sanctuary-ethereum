//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./IERC20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IERC721.sol";

//import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
//import "@openzeppelin/contracts/access/Ownable.sol";
//import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
//import "@openzeppelin/contracts/token/ERC721/IERC721.sol";


// to self: remember to call SetApprovalForAll(address, true) on the token contract
contract WhiteListMarketPlace is Ownable, ReentrancyGuard{

    IERC20 public tokenUsed;
    address public tokenUsedAddress; // NEEDS TO BE SET MANUALLY

    mapping(string => whitelistProject) public whitelistProjectsForSale; // key is project name
    mapping(string => nftForSale) public NFTsForSale; // key is project name
    string[] public projectNames;
    

    struct whitelistProject{
        uint amountOfSpots;
        string twitterIdentifier; // https://twitter.com/ProjectName
        string discordIdentifier; // https://discord.gg/ProjectName
        string imageIdentifier; // https://gateway.pinata.cloud/S0fj2Ks29Mns02
        string websiteIdentifier;
        string projectName; 
        string description;
        uint tokenCost;

        uint spotsLeft;
        address[] wlAddresses;
    }

    struct nftForSale{
        uint amountOfSpots;
        string twitterIdentifier; // https://twitter.com/ProjectName
        string discordIdentifier; // https://discord.gg/ProjectName
        string imageIdentifier; // https://gateway.pinata.cloud/S0fj2Ks29Mns02
        string websiteIdentifier;
        string projectName; 
        string description;
        uint tokenCost;
        address nftContractAddress;

        uint spotsLeft;
        uint tokenId;
    }

    constructor(){
        tokenUsed = IERC20(tokenUsedAddress);
    }

    function addWLProject (
        uint _amountOfSpots,
        string memory _twitterLink,
        string memory _discordLink,
        string memory _websiteLink,
        string memory _imageLink,
        string memory _projectName,
        string memory _description,
        uint _cost
    )   onlyOwner external {
        whitelistProjectsForSale[_projectName] = whitelistProject(
            _amountOfSpots,
            _twitterLink,
            _discordLink,
            _websiteLink,
            _imageLink,
            _projectName,
            _description,
            _cost,
            _amountOfSpots,
            new address[](0)
        );

        projectNames.push(_projectName);
    }

    // DONT use this unless you are no longer giving spots away OR addresses have been collected
    function removeWLProject(string memory projectName) external onlyOwner{
        delete whitelistProjectsForSale[projectName];

        for(uint i = 0; i < projectNames.length; i++){
            if(keccak256(abi.encodePacked(projectNames[i])) == keccak256(abi.encodePacked(projectName))){

                for(uint x = i; x <= (projectNames.length - 1); x++){
                    projectNames[x] = projectNames[x + 1];
                }
                projectNames.pop(); // delete projectNames[projectNames.length - 1]
                break;
            }
        }
    }

    function holderBuysWL(string memory projectName) external nonReentrant{
        whitelistProject memory _WLProject = whitelistProjectsForSale[projectName];

        require(_WLProject.spotsLeft > 0);
        require(tokenUsed.balanceOf(_msgSender()) >= _WLProject.tokenCost);

        // transfers the tokens across
        require(tokenUsed.transferFrom(_msgSender(), address(this), _WLProject.tokenCost));

        // account for the changes
        whitelistProjectsForSale[projectName].spotsLeft -= 1;
        whitelistProjectsForSale[projectName].wlAddresses.push(_msgSender());
    }

    function addNFTProject(
        uint _amountOfSpots,
        string memory twitterLink, // https://twitter.com/ProjectName
        string memory discordLink, // https://discord.gg/ProjectName
        string memory imageLink, // https://gateway.pinata.cloud/S0fj2Ks29Mns02
        string memory websiteLink,
        string memory _projectName, 
        string memory _description,
        uint _tokenCost,
        address _nftContractAddress,
        uint _tokenId
    ) external onlyOwner{
        nftForSale memory NFT = nftForSale(
            _amountOfSpots,
            twitterLink,
            discordLink,
            websiteLink,
            imageLink,
            _projectName,
            _description,
            _tokenCost,
            _nftContractAddress,
            _amountOfSpots,
            _tokenId
        );

        IERC721 realNFTContract = IERC721(NFT.nftContractAddress);
        realNFTContract.setApprovalForAll(address(this), true);
        realNFTContract.safeTransferFrom(_msgSender(), address(this), _tokenId);


        NFTsForSale[_projectName] = NFT;
        projectNames.push(_projectName);
    }

    function removeNFTProject(string memory _projectName) external onlyOwner{
        nftForSale memory NFT = NFTsForSale[_projectName];

        IERC721 realNFTContract = IERC721(NFT.nftContractAddress);
        realNFTContract.safeTransferFrom(address(this), _msgSender(), NFT.tokenId);

        delete NFTsForSale[_projectName];

        for(uint i = 0; i < projectNames.length; i++){
            if(keccak256(abi.encodePacked(projectNames[i])) == keccak256(abi.encodePacked(_projectName))){

                for(uint x = i; x <= (projectNames.length - 1); x++){
                    projectNames[x] = projectNames[x + 1];
                }
                projectNames.pop(); // delete projectNames[projectNames.length - 1]
                break;
            }
        }
    }

    function holderBuysNFT(string memory projectName) external nonReentrant{
        nftForSale memory NFT = NFTsForSale[projectName];

        // validation
        require(NFT.spotsLeft > 0);
        require(tokenUsed.balanceOf(_msgSender()) >= NFT.tokenCost);

        IERC721 realNFTContract = IERC721(NFT.nftContractAddress);
        require(realNFTContract.ownerOf(NFT.tokenId) == address(this));


        //transfers the token across
        require(tokenUsed.transferFrom(_msgSender(), address(this), NFT.tokenCost));

        realNFTContract.setApprovalForAll(address(this), true);
        realNFTContract.safeTransferFrom(address(this), _msgSender(), NFT.tokenId);

        delete NFTsForSale[projectName];

        for(uint i = 0; i < projectNames.length; i++){
            if(keccak256(abi.encodePacked(projectNames[i])) == keccak256(abi.encodePacked(projectName))){

                for(uint x = i; x <= (projectNames.length - 1); x++){
                    projectNames[x] = projectNames[x + 1];
                }
                projectNames.pop(); // delete projectNames[projectNames.length - 1]
                break;
            }
        }
    }

    function withdrawTokens() external onlyOwner{
        tokenUsed.transferFrom(address(this), _msgSender(), tokenUsed.balanceOf(address(this)));
    }

    function changeTokenAddress(address newAddy) external onlyOwner{
        tokenUsedAddress = newAddy;
        tokenUsed.transferFrom(address(this), _msgSender(), tokenUsed.balanceOf(address(this)));
        tokenUsed = IERC20(tokenUsedAddress);
    }
}