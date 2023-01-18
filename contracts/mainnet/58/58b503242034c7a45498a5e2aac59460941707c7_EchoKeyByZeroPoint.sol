// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ERC721AQueryable.sol";
import "./AccessControl.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";
import "./ECDSA.sol";

/**
 * @title ERC721A token for Echo Keys
 * 
 * @dev Master Echo Keys are redeemable through burning Echo Keys, a minimum of 7 total are needed, 6 will be burned 1 will be upgraded.
 * 
 * @author Author: KeyesCode 🧙
 */

contract EchoKeyByZeroPoint is ERC721AQueryable, AccessControl, ReentrancyGuard {
    
    bytes32 constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    uint256 public keys = 350;
    uint256 constant min_key_amount = 6;
    uint256 public tokensBurned = 0;
    mapping(address => bool) public walletMinted;

    string uri;
    string masterURI;
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
    error TokenIsAlreadyMaster();
    error TokenIsAlreadyMasterCantBurnMasterTokens();
    error PrimaryTokenIsAlreadyMaster();

    event UriUpdated(string uri);
    event MintStatusUpdated(bool mintStatus);
    event UpgradeStatusUpdated(bool upgradeStatus);
    event MasterUriUpdated(string uri);
    event KeyUpgraded(
        uint256 indexed tokenId, 
        string indexed masterTier,
        uint256[] tokenIdsBurned
    );

    address publicKey = 0x5973f9BAFb090e25570d82e2a252Fc6Be2E0bea5;

    constructor(
        string memory _name, 
        string memory _symbol,
        string memory _uri,
        string memory _masterURI,
        bool _mintStatus,
        bool _upgradeStatus,
        address adminWallet
    ) 
        ERC721A(_name, _symbol)
    {

        uri = _uri;
        masterURI = _masterURI;
        mintStatus = _mintStatus;
        upgradeStatus = _upgradeStatus;

        _setupRole(DEFAULT_ADMIN_ROLE, adminWallet);
        _setupRole(ADMIN_ROLE, address(0xa0E9B24b5c1563873859fD8c1327271a6D8bd084));
    }

     
    /// @notice verify voucher
    function _verifySignature(address _signer, bytes32 _hash, bytes memory _signature) private pure returns(bool) {
        return _signer == ECDSA.recover(ECDSA.toEthSignedMessageHash(_hash), _signature);
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
     * @notice Called by contract admin to set a new master base URI for KEYS
     */
    function setMasterURI(string memory _uri) external onlyRole(ADMIN_ROLE) {
        masterURI = _uri;
        emit MasterUriUpdated(_uri);
    }

    /**
     * @notice Function to mint
     * @dev Mint a NFT here
     */
    function mint(bytes calldata _voucher) external payable nonReentrant {
        require(mintStatus == true, "Minting is offline right now.");
        uint256 totalKeys = totalSupply() + tokensBurned;
        require(msg.value == 0, "Mint is Free! Do Not Send ETH.");
        require(totalKeys + 1 <= keys, "No more keys available.");
        require(msg.sender == tx.origin);
    	require(!walletMinted[msg.sender], "Wallet already minted");

        bytes32 hash = keccak256(
           abi.encodePacked(msg.sender)
        );
        require(_verifySignature(publicKey, hash, _voucher), "Invalid voucher");
        
        _mint(msg.sender, 1);
        walletMinted[msg.sender] = true;
    }
    
    /**
     * @notice Admin function to mint keys to a specific address
     */
    function mintTo(
        address _to, uint256 quantity
    ) external nonReentrant onlyRole(ADMIN_ROLE) {
        uint256 totalKeys = totalSupply() + tokensBurned;
        require(totalKeys + quantity <= keys);
        _mint(_to, quantity);
    }

    /**
     * @notice For upgrading a ECHO KEY to master tier
     * @dev User must own at least 7 Echo Keys to call this
     * @dev 7 Echo keys 6 will be burned 1 primary key will be upgraded
     * @param _primaryTokenId Token ID of KEY to upgrade
     * @param _tokenIds Array of ECHO KEYS token IDs to burn as part of the upgrade
     */
    function upgrade(
        uint256 _primaryTokenId,  
        uint256[] calldata _tokenIds
    ) external nonReentrant {
        require(upgradeStatus == true, "Upgrading is offline right now.");
        string memory _masterTier = "Master";
        if (ownerOf(_primaryTokenId) != msg.sender) revert NotOwnedBySender();
        if (_tokenIds.length < min_key_amount) revert NotEnoughTokens();
        if (_tokenIds.length > min_key_amount) revert TryingToBurnTooManyTokens();

        _burnKeys(_primaryTokenId, _tokenIds);
        
        tokensBurned += 6;
        currentEchoKeys[_masterTier][_primaryTokenId] = true;

        emit KeyUpgraded(_primaryTokenId, _masterTier, _tokenIds);
    }

    function burn(uint256 _tokenId) private {
        _burn(_tokenId, true);
    }

    function withdraw() public payable onlyRole(ADMIN_ROLE) {
	   (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
	   require(success);
	}

    function tokenURI(uint256 _id) public view override(ERC721A, IERC721A) returns (string memory) {
        require(
            _exists(_id),
            "ERC721Metadata: URI query for nonexistent token"
        );

        return
            readFromCurrentEchoKeys("Master", _id)
                ? string(abi.encodePacked(masterURI, Strings.toString(_id)))
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
        if (readFromCurrentEchoKeys("Master", _primaryTokenId)) revert PrimaryTokenIsAlreadyMaster();
        for (uint i=0; i < _tokenIdsToBurn.length; ) {
            uint256 _tokenId = _tokenIdsToBurn[i];
            if (readFromCurrentEchoKeys("Master", _tokenId)) revert TokenIsAlreadyMasterCantBurnMasterTokens();
            if (_tokenId == _primaryTokenId) revert CannotBurnPrimaryToken();
            unchecked { 
                i++;
            }
        }
        for(uint i=0; i<_tokenIdsToBurn.length;){
            burn(_tokenIdsToBurn[i]);
            unchecked {
                i++;
            }
        }
    }

    /// @notice set signer for signature
    function setPublicKey(address _key) external onlyRole(ADMIN_ROLE) {
       publicKey = _key;
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