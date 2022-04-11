/*
SPDX-License-Identifier: GPL-3.0
*/

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";
import "./LinkTokenInterface.sol";
import "./VRFCoordinatorV2Interface.sol";
import "./VRFConsumerBaseV2.sol";
import "./IERC721Receiver.sol";

interface Erc721Contract {
  function transferFrom(address from, address to, uint256 tokenId) external;
}

contract projectP22Token is Ownable, ERC721A, ReentrancyGuard, IERC721Receiver, VRFConsumerBaseV2 {
    string public provenance = "";

    bool public saleIsActive = false;

    uint256 public maxProjectP22 = 8888;

    address packContractAddress;

    string private _baseTokenURI;

    mapping(uint32 => bool) isGoldenTicket;

    struct LinkRequest {
      uint32 tokenId;
      address userAddress;
    }
    struct GoldenTicketRedeemRequest {
      address userAddress;
      bool isBurned;
      bool isNftTransferred;
    }
    mapping(uint256 => LinkRequest) public LinkRequestMapping;
    mapping(uint256 => GoldenTicketRedeemRequest) public GoldenTicketRedeemRequestMapping;

    // CHAIN LINK
    VRFCoordinatorV2Interface COORDINATOR;
    LinkTokenInterface LINKTOKEN;
    // TODO: SET DEFAULT BEFORE DEPLOY
    uint64 chainLinkSubscriptionId = 2411;
    address chainLinkVrfCoordinator = 0x6168499c0cFfCaCD319c818142124B7A15E857ab;
    address chainLinkLinkAddress = 0x01BE23585060835E02B77ef475b0Cc51aA1e0709;
    bytes32 chainLinkKeyHash = 0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc;
    uint32 chainLinkCallbackGasLimit = 400000;
    uint16 chainLinkRequestConfirmations = 3;
    uint32 numWords = 1;

    uint32 public goldenTicketTokenCount = 0;
    uint32 public goldenTicketTokenMinAvailableIndex = 0;
    uint32 public goldenTicketTokenMaxAvailableIndex = 2;
    mapping(uint32 => uint256) public goldenTicketTokens;
    mapping(uint256 => uint32) public goldenTicketTokenIndex;
    mapping(uint32 => bool) public isGoldenTicketTokenIndexPicked;
    address public goldenTicketTokenAddress = 0xf1183A89c576aa07f5DBE5a13ca4B42855fb6545;

    // ############################# constructor #############################
    constructor() ERC721A("projectP22Token", "projectP22Token", 200, 8888) VRFConsumerBaseV2(chainLinkVrfCoordinator) {
      COORDINATOR = VRFCoordinatorV2Interface(chainLinkVrfCoordinator);
      LINKTOKEN = LinkTokenInterface(chainLinkLinkAddress);
    }

    // ############################# function section #############################

    // ***************************** internal : Start *****************************

    function _baseURI() internal view virtual override returns (string memory) {
      return _baseTokenURI;
    }

    function checkGoldenIndexIsAvailbale(uint randomNumber) internal returns (uint) {
      uint j=0;
      bool matchFound = false;
      uint newIndex = 0;
      for (j = randomNumber; j <= goldenTicketTokenMaxAvailableIndex && matchFound == false; j = j + 1) {
          if(isGoldenTicketTokenIndexPicked[uint32(j)] != true) {
              matchFound = true;
              newIndex = j;
              break;
          }
      }
      if(matchFound == false) {
          goldenTicketTokenMaxAvailableIndex = uint32(randomNumber - 1);
          return checkGoldenIndexIsAvailbale(0);
      }
      else {
          return newIndex;
      }
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
      GoldenTicketRedeemRequest memory goldenTicketRedeemRequestInstance = GoldenTicketRedeemRequestMapping[LinkRequestMapping[requestId].tokenId];
      require(goldenTicketRedeemRequestInstance.isBurned == true
              && goldenTicketRedeemRequestInstance.isNftTransferred == false,
        "Nft already transferred or token not burned"
      );

      uint256 rNumber = randomWords[0] % (goldenTicketTokenMaxAvailableIndex - goldenTicketTokenMinAvailableIndex + 1);
      uint newIndex = checkGoldenIndexIsAvailbale(rNumber);
      isGoldenTicketTokenIndexPicked[uint32(newIndex)] = true;

      Erc721Contract erc721ContractInstance = Erc721Contract(goldenTicketTokenAddress);
      erc721ContractInstance.transferFrom(address(this), LinkRequestMapping[requestId].userAddress, goldenTicketTokens[uint32(newIndex)]);

      GoldenTicketRedeemRequestMapping[LinkRequestMapping[requestId].tokenId] = GoldenTicketRedeemRequest(msg.sender, true, true);
    }

    // ***************************** internal : End *****************************

    // ***************************** onlyOwner : Start *****************************

    function withdraw() public onlyOwner {
      (bool success, ) = msg.sender.call{value: address(this).balance}("");
      require(success, "Transfer failed.");
    }

    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
      provenance = provenanceHash;
    }

    function startSale() external onlyOwner {
      require(!saleIsActive, "Public sale has already begun");
      saleIsActive = true;
    }

    function pauseSale() external onlyOwner {
      saleIsActive = false;
    }

    function setPackContractAddress(address _packContractAddress) external onlyOwner {
      packContractAddress = _packContractAddress;
    }

    function setCollectionSize(uint256 collectionSize_) external onlyOwner {
      maxProjectP22 = collectionSize_;
      collectionSize = collectionSize_;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
      _baseTokenURI = baseURI;
    }

    function setOwnersExplicit(uint256 quantity) external onlyOwner nonReentrant {
      _setOwnersExplicit(quantity);
    }

    function setIsGoldenTicket(uint32 tokenId, bool isGT) external onlyOwner {
      require(isGoldenTicket[tokenId] != isGT, "Same value already set");
      isGoldenTicket[tokenId] = isGT;
    }

    function setChainLinkSubscriptionId(uint64 newSubscriptionId) external onlyOwner {
      chainLinkSubscriptionId = newSubscriptionId;
    }

    function setGoldenTicketConfigration(uint32 _goldenTicketTokenMinAvailableIndex, uint32 _goldenTicketTokenMaxAvailableIndex, address _goldenTicketTokenAddress) external onlyOwner {
      goldenTicketTokenMinAvailableIndex = _goldenTicketTokenMinAvailableIndex;
      goldenTicketTokenMaxAvailableIndex = _goldenTicketTokenMaxAvailableIndex;
      goldenTicketTokenAddress = _goldenTicketTokenAddress;
    }

    function setChainLinkConfigration(address newVrfCoordinator, address newLinkAddress, bytes32 newKeyHash, uint32 newCallbackGasLimit, uint16 newRequestConfirmations) external onlyOwner {
      chainLinkVrfCoordinator = newVrfCoordinator;
      chainLinkLinkAddress = newLinkAddress;
      chainLinkKeyHash = newKeyHash;
      chainLinkCallbackGasLimit = newCallbackGasLimit;
      chainLinkRequestConfirmations = newRequestConfirmations;
    }

    function setChainLinkCallbackGasLimit(uint32 newCallbackGasLimit) external onlyOwner {
      chainLinkCallbackGasLimit = newCallbackGasLimit;
    }

    // ***************************** onlyOwner : End *****************************

    // ***************************** public view : Start *************************

    function tokensOfOwner(address _owner) public view returns(uint256[] memory ) {
      uint256 tokenCount = balanceOf(_owner);
      if (tokenCount == 0) {
          return new uint256[](0);
      } else {
          uint256[] memory result = new uint256[](tokenCount);
          uint256 index;
          for (index = 0; index < tokenCount; index++) {
              result[index] = tokenOfOwnerByIndex(_owner, index);
          }
          return result;
      }
    }
    
    function onERC721Received(address, address, uint256 tokenId, bytes calldata) public virtual override returns (bytes4) {
      require(msg.sender == goldenTicketTokenAddress, "Only golden ticket contract can send nft on this address");
      goldenTicketTokens[goldenTicketTokenCount] = tokenId;
      goldenTicketTokenIndex[tokenId] = goldenTicketTokenCount;
      goldenTicketTokenCount += 1;
      return this.onERC721Received.selector;
    }

    function Mint(uint numberOfTokens, address toAddress, uint tokenStartIndex) external {
      uint256 currentTotalSupply = totalSupply();
      require(packContractAddress == msg.sender, "Invalid pack address");
      require(saleIsActive, "Sale must be active to mint ProjectP22");
      require(numberOfTokens < 21, "Can only mint 20 tokens at a time");
      require(currentTotalSupply + numberOfTokens < 8889, "Purchase would exceed max supply of ProjectP22s");
      _safeMint(toAddress, numberOfTokens, tokenStartIndex);
    }

    function numberMinted(address owner) external view returns (uint256) {
      return _numberMinted(owner);
    }

    function getOwnershipData(uint256 tokenId) external view returns (TokenOwnership memory) {
      return ownershipOf(tokenId);
    }

    function RedeemGoldenTicket(uint32 tokenId) external {
      address owner = ERC721A.ownerOf(tokenId);
      GoldenTicketRedeemRequest memory goldenTicketRedeemRequestInstance = GoldenTicketRedeemRequestMapping[tokenId]; 
      require(
        msg.sender == owner 
          || (goldenTicketRedeemRequestInstance.userAddress == msg.sender 
              && goldenTicketRedeemRequestInstance.isBurned == true 
              && goldenTicketRedeemRequestInstance.isNftTransferred == false),
        "You are not the owner of the entered token"
        );
      require(isGoldenTicket[tokenId] == true, "Selected token is not a golden ticket");
      if (goldenTicketRedeemRequestInstance.isBurned == false) {
        // burn token
        transferFrom(msg.sender, 0x000000000000000000000000000000000000dEaD, tokenId);
        GoldenTicketRedeemRequestMapping[tokenId] = GoldenTicketRedeemRequest(msg.sender, true, false);
      }
      uint256 requestId = COORDINATOR.requestRandomWords(chainLinkKeyHash, chainLinkSubscriptionId, chainLinkRequestConfirmations, chainLinkCallbackGasLimit, 1);
      LinkRequestMapping[requestId] = LinkRequest(tokenId, msg.sender);
    }
}