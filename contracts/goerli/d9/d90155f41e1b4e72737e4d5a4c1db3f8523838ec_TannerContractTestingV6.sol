// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ERC721AQueryable.sol";
import "./AccessControl.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";

/**
 * @title ...
 * 
 * @dev ...
 * 
 * @author Author: 
 */

contract TannerContractTestingV6 is ERC721AQueryable, AccessControl, ReentrancyGuard {
    
    bytes32 constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    uint256 public keys = 350;
    uint256 constant max_key = 1;
    uint256 constant min_key_amount = 6;
    uint256 public tokensBurned = 0;
    mapping(address => uint256) public amountOfKeys;

    string uri;
    string goldURI;
    bool mintStatus = false;
    bool upgradeStatus = false;

    mapping(string => mapping(uint256 => bool)) public currentEchoKeys; // tier => tokenIds => bool

    error TryingToBurnTooManyTokens();
    error NotOwnedBySender();
    error CannotBurnPrimaryToken();
    error MustIncludeAmount();
    error NotEnoughTokens();
    error MustIncludeKeysToUpgrade();
    error TokenDoesNotExist();
    error InsufficientBaseAmount();
    error EchoDoesNotExist();
    error TokenIsAlreadyGolden();
    error TokenIsAlreadyGoldenCantBurnGoldenTokens();
    error PrimaryTokenIsAlreadyGold();

    event UriUpdated(string uri);
    event MintStatusUpdated(bool mintStatus);
    event UpgradeStatusUpdated(bool upgradeStatus);
    event GoldUriUpdated(string uri);
    event KeyUpgraded(
        uint256 indexed tokenId, 
        string indexed goldTier,
        uint256[] tokenIdsBurned
    );

    constructor(
        string memory _name, 
        string memory _symbol,
        string memory _uri,
        string memory _goldURI,
        bool _mintStatus,
        bool _upgradeStatus,
        address adminWallet
    ) 
        ERC721A(_name, _symbol)
    {

        uri = _uri;
        goldURI = _goldURI;
        mintStatus = _mintStatus;
        upgradeStatus = _upgradeStatus;

        _setupRole(DEFAULT_ADMIN_ROLE, adminWallet);
        _setupRole(ADMIN_ROLE, address(0xd2447231bD541aEBa3Da3a1F6584cD40932adfa4));
    }

    /**
     * @notice Called by contract admin to set a new base URI for KEYS
     */
    function setURI(string memory _uri) external onlyRole(ADMIN_ROLE) {
        uri = _uri;
        emit UriUpdated(_uri);
    }

    /**
     * @notice Called by contract admin to set a mint status
     */
    function setMintStatus(bool _mintStatus) external onlyRole(ADMIN_ROLE) {
        mintStatus = _mintStatus;
        emit MintStatusUpdated(_mintStatus);
    }

    /**
     * @notice Called by contract admin to set a upgrade status
     */
    function setUpgradeStatus(bool _upgradeStatus) external onlyRole(ADMIN_ROLE) {
        upgradeStatus = _upgradeStatus;
        emit UpgradeStatusUpdated(_upgradeStatus);
    }

    /**
     * @notice Called by contract admin to set a new gold base URI for KEYS
     */
    function setGoldURI(string memory _uri) external onlyRole(ADMIN_ROLE) {
        goldURI = _uri;
        emit GoldUriUpdated(_uri);
    }

    /**
     * @notice Function to mint
     * @dev Mint a NFT here
     */
    function mint() external payable nonReentrant {
        require(mintStatus == true, "Minting is offline right now.");
        uint256 totalKeys = totalSupply() + tokensBurned;
        require(msg.value == 0, "Mint is Free! Do Not Send ETH.");
        require(totalKeys + max_key <= keys, "No more keys available.");
        require(msg.sender == tx.origin);
    	require(amountOfKeys[msg.sender] < max_key, "Max Minted for wallet.");
        
        _mint(msg.sender, max_key);
        amountOfKeys[msg.sender] += max_key;
    }
    
    /**
     * @notice Admin function to mint keys to a specified address
     */
    function mintTo(
        address _to, uint256 quantity
    ) external nonReentrant onlyRole(ADMIN_ROLE) {
        uint256 totalKeys = totalSupply() + tokensBurned;
        require(totalKeys + quantity <= keys);
        _mint(_to, quantity);
    }

    /**
     * @notice For upgrading a 
     * @dev User must own 
     * @dev 
     * @param _primaryTokenId Token ID of
     * @param _tokenIds Array of 
     */
    function upgrade(
        uint256 _primaryTokenId,  
        uint256[] calldata _tokenIds
    ) external nonReentrant {
        require(upgradeStatus == true, "Upgrading is offline right now.");
        string memory _goldTier = "Gold";
        if (ownerOf(_primaryTokenId) != msg.sender) revert NotOwnedBySender();
        if (_tokenIds.length < min_key_amount) revert NotEnoughTokens();
        if (_tokenIds.length > min_key_amount) revert TryingToBurnTooManyTokens();

        _burnKeys(_primaryTokenId, _tokenIds);
        
        tokensBurned += 6;
        currentEchoKeys[_goldTier][_primaryTokenId] = true;

        emit KeyUpgraded(_primaryTokenId, _goldTier, _tokenIds);
    }

    function withdraw() public payable onlyRole(ADMIN_ROLE) {
	   (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
	   require(success);
	}

    function burn(uint256 _tokenId) private {
        _burn(_tokenId, true);
    }

    function tokenURI(uint256 _id) public view override(ERC721A, IERC721A) returns (string memory) {
        require(
            _exists(_id),
            "ERC721Metadata: URI query for nonexistent token"
        );

        return
            readFromCurrentEchoKeys("Gold", _id)
                ? string(abi.encodePacked(goldURI, Strings.toString(_id)))
                : string(abi.encodePacked(uri, Strings.toString(_id)));
    }

    function supportsInterface(bytes4 interfaceId) public pure override(ERC721A, IERC721A, AccessControl) returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || 
               interfaceId == type(IERC165).interfaceId ||
               interfaceId == type(IERC721AQueryable).interfaceId ||
               interfaceId == type(IERC721A).interfaceId ||
               interfaceId == 0x80ac58cd ||
               interfaceId == 0x5b5e139f;     
    }

    function _startTokenId() internal override view virtual returns (uint256) {
        return 1;
    }

    function _burnKeys(
        uint256 _primaryTokenId, 
        uint256[] calldata _tokenIdsToBurn
    ) private {
        if (readFromCurrentEchoKeys("Gold", _primaryTokenId)) revert PrimaryTokenIsAlreadyGold();
        for (uint i=0; i < _tokenIdsToBurn.length; ) {
            uint256 _tokenId = _tokenIdsToBurn[i];
            if (readFromCurrentEchoKeys("Gold", _tokenId)) revert TokenIsAlreadyGoldenCantBurnGoldenTokens();
            if (_tokenId == _primaryTokenId) revert CannotBurnPrimaryToken();
            unchecked { 
                ++i;
            }
        }
        for(uint i=0; i<_tokenIdsToBurn.length;){
            burn(_tokenIdsToBurn[i]);
            unchecked {
                ++i;
            }
        }
    }

    //Reading Functions
    function readFromCurrentEchoKeys(string memory _tier, uint _tokenId) public view returns(bool) {
        return currentEchoKeys[_tier][_tokenId];
    }

    function readTokensBurned() public view returns(uint) {
        return tokensBurned;
    }

    function readMintStatus() public view returns(bool) {
        return mintStatus;
    }

    function readUpgradeStatus() public view returns(bool) {
        return upgradeStatus;
    }
}