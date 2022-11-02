// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721AQueryable.sol";
import "./IERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Strings.sol";

contract Creator is ERC721AQueryable, Ownable {
    using Strings for uint256;
    using SafeMath for uint256;

    // Events
    event TokenMinted(address owner, uint256 qtyTokens);
    event RewardClaimed(address owner, uint256 qtyTokens);

    IERC721Enumerable public FRANKIE_CONTRACT = IERC721Enumerable(0xa9e739bA9e691FAcC90900D16629f4814805c6ea);

    // Provenance number
    string public provenance = "";

    // Max amount of token to purchase per account each time
    uint public maxPurchase = 20;

    // Max supply
    uint256 public maxTokens = 8888;

    // Mint price.
    uint256 public mintPrice = 0;

    // Max supply
    uint256 public claimRewardDueDate = 1673654399; // Friday 13, January 2023 23:59:59 GTM 0

    // Max qty tokens to claim per request.
    uint256 public maxQtyClaimPerRequest = 100;

    // Rewards Claimed
    mapping(uint256 => bool) private claimedRewards;

    // Define if claim is active
    bool public claimRewardIsActive = true;

    // Define if sale is active
    bool public saleIsActive = false;

    // Base URI
    string private baseURI;

    string public baseExtension = ".json";

    /**
     * Contract constructor
     */
    constructor(string memory _name, string memory _symbol, string memory _uri) ERC721A(_name, _symbol) {
        setBaseURI(_uri);
    }

    /*
     * Set Frankie contract address
     */
    function setFrankieContract(address _contractAddress) public onlyOwner {
        FRANKIE_CONTRACT = IERC721Enumerable(_contractAddress);
    }

    /*
     * Set provenance once it's calculated
     */
    function setProvenanceHash(string memory _provenanceHash) public onlyOwner {
        provenance = _provenanceHash;
    }

    /*
     * Claim reward is enabled
     */
    function setClaimRewardState(bool _newState) public onlyOwner {
        claimRewardIsActive = _newState;
    }

    /*
     * Pause sale if active, make active if paused
     */
    function setSaleState(bool _newState) public onlyOwner {
        saleIsActive = _newState;
    }

    /*
     * Set max purchase
     */
    function setMaxPurchase(uint256 _qty) public onlyOwner {
        maxPurchase = _qty;
    }

    /**
     * Set Max Tokens to mint
     */
    function setMaxTokens(uint256 _qty) public onlyOwner {
        maxTokens = _qty;
    }

    /**
     * Set Max qty tokens to claim per request
     */
    function setMaxQtyClaimPerRequest(uint256 _qty) public onlyOwner {
        maxQtyClaimPerRequest = _qty;
    }

    /**
     * Set the mint price
     */
    function setMintPrice(uint256 _newPrice) public onlyOwner {
        mintPrice = _newPrice;
    }

    /*
     * Set Claim Reward Due Date
     */
    function setClaimRewardDueDate(uint256 _newDate) public onlyOwner {
        claimRewardDueDate = _newDate;
    }

    /*
     * Set Base extension
     */
    function setBaseExtension(string memory _baseExtension) public onlyOwner {
        baseExtension = _baseExtension;
    }

    /**
     * @dev Changes the base URI if we want to move things in the future (Callable by owner only)
     */
    function setBaseURI(string memory BaseURI) onlyOwner public {
        baseURI = BaseURI;
    }

    /**
     * @dev Base URI for computing {tokenURI}. Empty by default, can be overriden
     * in child contracts.
     */
    function _baseURI() internal view virtual override returns(string memory) {
        return baseURI;
    }

    /**
     * Get the token URI with the metadata extension
     */
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), baseExtension))
            : "";
    }

    /**
     * Withdraw
     */
    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /**
     * Reserve tokens
     */
    function reserveTokens(uint _qtyTokens) public onlyOwner {
        require(totalSupply().add(_qtyTokens) <= maxTokens, "Reserve tokens would exceed max supply");

        _safeMint(msg.sender, _qtyTokens);
    }

    /**
     * Mint token for owners
     */
    function mintToWallets(address[] memory _owners, uint256 _qty) public onlyOwner {
        require(totalSupply().add(_owners.length.mul(_qty)) <= maxTokens, "Purchase would exceed max supply");
        
        for (uint i = 0; i < _owners.length; i++) {
            _safeMint(_owners[i], _qty);
            emit TokenMinted(_owners[i], _qty);
        }
    }

    /**
    * Mint tokens
    */
    function mint(uint _qty) public payable {
        require(saleIsActive, "Mint is not available right now");
        require(_qty <= maxPurchase, "Can only mint 20 tokens at a time");
        require(totalSupply().add(_qty) <= maxTokens, "Purchase would exceed max supply");
        require(mintPrice.mul(_qty) <= msg.value, "Value sent is not correct");
        
        _safeMint(msg.sender, _qty);
        emit TokenMinted(msg.sender, _qty);
    }

    /**
     * Claim all Rewards
     */
    function claimAllRewards(uint256[] memory _tokensId) external {
        require(claimRewardIsActive, "Claim reward is not available right now");
        require(claimRewardDueDate >= block.timestamp, "Time to claim rewards is over");
        require(_tokensId.length <= maxQtyClaimPerRequest, "The number of tokens to claim rewards exceeds the maximum allowed");

        uint256 ownerBalance = _tokensId.length;
        uint256 qtyToClaim = 0;

        for(uint i = 0; i < ownerBalance; i++) {
            if (FRANKIE_CONTRACT.ownerOf(_tokensId[i]) == msg.sender && !claimedRewards[_tokensId[i]]) {
                claimedRewards[_tokensId[i]] = true;
                qtyToClaim = qtyToClaim.add(1);
            }
        }

        require(qtyToClaim > 0, "You don't have rewards to claim");
        require(totalSupply().add(qtyToClaim) <= maxTokens, "Claim reward would exceed max supply");

        _safeMint(msg.sender, qtyToClaim);

        emit RewardClaimed(msg.sender, qtyToClaim);
    }

    /**
    * Claim Reward by Token Id
    */
    function claimReward(uint256 _frankieTokenId) external {
        require(claimRewardIsActive, "Claim reward must be active");
        require(claimRewardDueDate >= block.timestamp, "Time to claim reward is over");

        require(!claimedRewards[_frankieTokenId], "Token Reward was claimed");
        require(FRANKIE_CONTRACT.ownerOf(_frankieTokenId) == msg.sender, "You are not the token owner");
        require(totalSupply().add(1) <= maxTokens, "Claim reward would exceed max supply");

        claimedRewards[_frankieTokenId] = true;
        _safeMint(msg.sender, 1);

        emit RewardClaimed(msg.sender, 1);
    }

    /**
    * get Frankie tokens pending to claim for an owner
    */
    function getPendingRewards(address _owner) public view returns(uint256[] memory) {
        require(claimRewardIsActive, "Claim reward is not available right now");
        require(claimRewardDueDate >= block.timestamp, "Time to claim rewards is over");

        uint256 frankieTokenId;
        uint ownerBalance = FRANKIE_CONTRACT.balanceOf(_owner);
        uint256[] memory tokensId = new uint256[](ownerBalance);
        
        for(uint i = 0; i < ownerBalance; i++){
            frankieTokenId = FRANKIE_CONTRACT.tokenOfOwnerByIndex(_owner, i);
            if (!claimedRewards[frankieTokenId]) {
                tokensId[i] = frankieTokenId;
            }else{
                tokensId[i] = 0;
            }
        }

        return tokensId;
    }

    /**
     * Get total rewards available for an owner
     */
    function getTotalRewardsToClaim(address _owner) public view returns(uint256) {
        require(claimRewardIsActive, "Claim reward is not available right now");

        uint256 qtyToClaim = 0;
        uint256 frankieTokenId;
        uint256 ownerBalance = FRANKIE_CONTRACT.balanceOf(_owner);

        for(uint i = 0; i < ownerBalance; i++) {
            frankieTokenId = FRANKIE_CONTRACT.tokenOfOwnerByIndex(_owner, i);
            if (!claimedRewards[frankieTokenId]) {
                qtyToClaim = qtyToClaim.add(1);
            }
        }
        return qtyToClaim;
    }

    /**
     * Frankie has reward pending to claim
     */
    function frankieHasReward(uint256 _frankieTokenId) public view returns(bool) {
        require(_frankieTokenId > 0 && _frankieTokenId <= maxTokens, "Invalid Token Id");

        return !claimedRewards[_frankieTokenId];
    }

    /**
     * Get owners list
     */
    function getOwners(uint256 _offset, uint256 _limit) public view returns(address[] memory) {
        uint tokenCount = totalSupply();

        if (_offset.add(_limit) < tokenCount) {
            tokenCount = _offset.add(_limit);
        }

        address[] memory owners = new address[](tokenCount);
        for (uint i = _offset; i < tokenCount; i++) {
            owners[i] = ownerOf(i + 1);
        }

        return owners;
    }
}