// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.14;

import "./shared/CBWCBase.sol";
import "./interfaces/ICBWCStaking.sol";

/// @title Crypto Bear Watch Club Pieces
/// @author Kfish n Chips
/// @notice ERC721 Watch Pieces to be claimed by CBWC holders
/// @dev Claiming begins once WAVE_MANAGER starts a claim wave
/// @custom:security-contact [email protected]
contract CBWCPieces is CBWCBase {
    /// @notice Keeping track of active waves
    uint256[] public activeWaves;
    // @notice Mapping the status of wave to bear claim
    // @dev WaveID => ( CBWCID => true/false )
    mapping(uint256 => mapping(uint256 => bool)) private claimed;
    /// @notice Enable/Disable Claim Feature
    bool public claimingActive;
    /// @notice CryptoBear Watch Club Staking Contract
    ICBWCStaking public cbwcStaking;
    /// @notice CBWCWatch contract
    address public cbwcWatch;
    // @notice Role assigned by DEFAULT_ADMIN_ROLE with access to burn
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    // @notice Role assigned by DEFAULT_ADMIN_ROLE to manage claim waves
    bytes32 public constant WAVE_MANAGER = keccak256("WAVE_MANAGER");
    /// @notice Counter of waves to make sure new waves don't override previous ones
    uint256 public waveCounter;

    /// @notice Emitted when CBWC WATCH changed
    /// @dev only DEFAULT_ADMIN_ROLE can perform this action
    /// @param sender address with the role of DEFAULT_ADMIN_ROLE
    /// @param previousCBWCWatch previous CBWC WATCH contract address
    /// @param cbwcWatch new CBWC WATCH contract address
    event CBWCWatchChanged(
        address indexed sender,
        address previousCBWCWatch,
        address cbwcWatch
    );

    /// @notice Emitted when CBWC Staking contract changed
    /// @dev only DEFAULT_ADMIN_ROLE can perform this action
    /// @param sender address with the role of DEFAULT_ADMIN_ROLE
    /// @param previousCBWCStaking previous CBWC Staking contract address
    /// @param cbwcStaking new CBWC Staking contract address
    event CBWCStakingChanged(
        address indexed sender,
        address previousCBWCStaking,
        address cbwcStaking
    );

    /// @dev Emitted when the claiming status change.
    /// @param sender address with the role of DEFAULT_ADMIN_ROLE
    /// @param state the new claiming status
    event ToggleClaiming(
        address sender,
        bool state
    );

    /// @notice Modifier to Enable/Disable Claim Feature
    /// @dev false by default
    modifier isClaimingActive() {
        require(claimingActive, "CBWCP: claiming not active");
        _;
    }

    /// @notice Initializer function which replaces constructor for upgradeable contracts
    /// @dev This should be called at deploy time
    function initialize(
        address cbwcWatch_,
        address cbwcStaking_
    )
        external
        initializer
    {
        __CBWCBase_init(
            "CBWCPieces",
            "CBWCP",
            "https://cryptobearwatchclub.mypinata.cloud/ipfs/QmabYNu8sF9fZvury4pEwU9y95GQvHMbYyJeHXGEcvi4pc",
            "https://api.cbwc.io/pieces/metadata/"
        );
        require(cbwcWatch_ != address(0), "CBWCP: cannot set address zero");
        require(cbwcStaking_ != address(0), "CBWCP: cannot set address zero");
        cbwcWatch = cbwcWatch_;
        cbwcStaking = ICBWCStaking(cbwcStaking_);
        _grantRole(BURNER_ROLE, cbwcWatch);
        _grantRole(WAVE_MANAGER, msg.sender);
    }

    /// @notice Mint multiple NFTs to receivers
    /// @dev Restricted to {MINTER_ROLE}
    /// @param receivers_ The receiving addresses
    /// @param quantities_ The receiver's quantities
    function airdrop(
        address[] calldata receivers_,
        uint256[] calldata quantities_
    )
        external
        onlyRole(MINTER_ROLE)
    {
        require(receivers_.length > 0, "CBWCP: must airdrop at least one address");
        require(receivers_.length == quantities_.length, "CBWCP: receivers and quantities length does not match");
        for (uint256 i = 0; i < receivers_.length; i++) {
            _mint(receivers_[i], quantities_[i]);
        }
    }

    /// @notice Burn existing token
    /// @dev Forge contract will call this function
    /// @param tokenIds_ The tokenIds to burn
    /// @return bool success
    function burnPieces(
        uint256[] calldata tokenIds_,
        address owner_
    )
        external
        onlyRole(BURNER_ROLE)
        returns (bool)
    {
        require(tokenIds_.length > 0, "CBWCP: must burn at least one token");
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            _burn(tokenIds_[i], owner_);
        }

        return true;
    }

    /// @notice Mints multiple tokens to `msg.sender` based on claimable amount.
    /// @dev staked tokens can claim pieces: cbwcStaking
    /// @param cbwcTokenIds_ Array of CBWC token ids for claiming
    function claim(uint256[] calldata cbwcTokenIds_) external isClaimingActive {
        require(activeWaves.length > 0, "CBWCP: No active waves");
        uint256 unclaimedPieces = 0;
        for (uint256 i = 0; i < cbwcTokenIds_.length; i++) {
            require(
                cbwc.ownerOf(cbwcTokenIds_[i]) == msg.sender || cbwcStaking.tokenOwner(cbwcTokenIds_[i]) == msg.sender,
                "CBWCP: caller is not token owner"
            );
            for (uint256 j = 0; j < activeWaves.length; j++) {
                if (!claimed[activeWaves[j]][cbwcTokenIds_[i]]) {
                    claimed[activeWaves[j]][cbwcTokenIds_[i]] = true;
                    unclaimedPieces += 1;
                }
            }
        }
        require(unclaimedPieces > 0, "CBWCP: no claimable tokens");

        safeMint(msg.sender, unclaimedPieces);
    }

    /// @notice Set CBWCWatch address
    /// @dev revoke and grant the BURNER_ROLE
    /// @param cbwcWatch_ The new CBWC Watch address
    /// Emits a {CBWCWatchChanged} event
    function setCBWCWatch(address cbwcWatch_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(cbwcWatch_ != address(0), "CBWCP: cannot set address zero");

        address previousCBWCWatch = cbwcWatch;
        cbwcWatch = cbwcWatch_;
        _revokeRole(BURNER_ROLE, previousCBWCWatch);
        _grantRole(BURNER_ROLE, cbwcWatch);

        emit CBWCWatchChanged(msg.sender, previousCBWCWatch, cbwcWatch_);
    }

    /// @notice Set CBWCStaking address
    /// @param cbwcStaking_ The new Stating CBWC contract address
    /// Emits a {CBWCStakingChanged} event
    function setCBWCStaking(address cbwcStaking_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(cbwcStaking_ != address(0), "CBWCP: cannot set address zero");

        address previousCBWCStaking = address(cbwcStaking);
        cbwcStaking = ICBWCStaking(cbwcStaking_);

        emit CBWCStakingChanged(msg.sender, previousCBWCStaking, cbwcStaking_);
    }

    /// @notice Used to enable or disable a wave
    /// @dev Only callable by an address with DEFAULT_ADMIN_ROLE
    /// @param wave_ The wave ID
    /// @param active_ Whether the wave is active or not
    function setWave(
        uint256 wave_,
        bool active_
    )
        external
        isClaimingActive
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(wave_ > 0 && wave_ <= waveCounter, "CBWCP: invalid wave");
        if (active_) {
            for (uint256 i = 0; i < activeWaves.length; i++) {
                require(activeWaves[i] != wave_, "CBWCP: wave already active");
            }
            activeWaves.push(wave_);
        } else {
            uint256[] memory _activeWaves = new uint256[](activeWaves.length - 1);
            uint256 counter = 0;
            for (uint256 i = 0; i < activeWaves.length; i++) {
                if (activeWaves[i] == wave_) {
                    counter = 1;
                } else if (i == _activeWaves.length && counter == 0) {
                    require(activeWaves[i] == wave_, "CBWCP: wave is not active");
                } else {
                    _activeWaves[i - counter] = activeWaves[i];
                }
            }
            activeWaves = _activeWaves;
        }
    }

    /// @notice Start the next wave
    /// @param endCurrentWave_ Whether to end the current wave
    function startNextWave(bool endCurrentWave_) external isClaimingActive onlyRole(WAVE_MANAGER) {
        if (endCurrentWave_) endCurrentWave();
        activeWaves.push(waveCounter + 1);
        waveCounter += 1;
    }

    /// @notice change the status of current POAP
    /// Emits a {ToggleClaiming} event
    function toggleClaiming() external onlyRole(DEFAULT_ADMIN_ROLE) {
        claimingActive = !claimingActive;
        emit ToggleClaiming(msg.sender, claimingActive);
    }

    /// @notice Returns amount of claimable watch pieces
    /// @param cbwcTokenIds_ List of CBWC token ids
    /// @dev does NOT check that cbwcTokenIds_ exits
    /// @return The claimable amount
    function getPendingClaims(uint256[] calldata cbwcTokenIds_) external view isClaimingActive returns (uint256) {
        uint256 unclaimedPieces = 0;
        for (uint256 i = 0; i < activeWaves.length; i++) {
            for (uint256 j = 0; j < cbwcTokenIds_.length; j++) {
                if (cbwcTokenIds_[j] > 0 && !claimed[activeWaves[i]][cbwcTokenIds_[j]]) {
                    unclaimedPieces += 1;
                }
            }
        }
        return unclaimedPieces;
    }

    /// @notice End the current wave
    /// @dev must be a active wave
    function endCurrentWave() public isClaimingActive onlyRole(WAVE_MANAGER) {
        require(activeWaves.length > 0, "CBWCP: no active waves");
        activeWaves.pop();
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.14;

import "../ERC721KFNCUUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "../interfaces/IERC165KFNC.sol";
import "../interfaces/ICBWC.sol";

/// @title Crypto Bear Watch Club Base
/// @author Kfish n Chips
/// @notice Upgradeable contract base for Pieces and Watch NFTs
/// @dev Upgrades using UUPSUpgradeable Proxy pattern
abstract contract CBWCBase is
    Initializable,
    ERC721KFNCUUPSUpgradeable,
    ERC2981Upgradeable,
    AccessControlUpgradeable
{
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    /// @notice Role assigned to addresses that can perform minted actions
    /// @dev Role can be granted by the DEFAULT_ADMIN_ROLE
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    /// @notice Role assigned to an address that can perform upgrades to the contract
    /// @dev Role can be granted by the DEFAULT_ADMIN_ROLE
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    /// @notice Setting an owner in order to comply with ownable interfaces
    /// @dev This variable was only added for compatibility with contracts that request an owner
    address public owner;
    /// @notice Contract URI with metadata
    string internal _contractURI;
    /// @notice The CryptoBearWatchClub NFT Contract
    /// @dev used to check the ownership of tokens
    ICBWC internal cbwc;

    /// @notice Emitted when ownership transferred.
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /// @notice Initializer function which replaces constructor for upgradeable contracts
    /// @dev This should be called from inheriting contract
    /// @param name_ Contract name
    /// @param symbol_ Contract symbol
    /// @param contractURI_ URI containing contract metadata for marketplaces such as OpenSea
    /// @param baseURI_ Base URI used to fetch token metadata
    /* solhint-disable ordering */
    function __CBWCBase_init(
        string memory name_,
        string memory symbol_,
        string memory contractURI_,
        string memory baseURI_
    ) internal onlyInitializing {
        __AccessControl_init();
        __ERC2981_init();
        __ERC721KFNC_init(name_, symbol_, baseURI_);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);
        _contractURI = contractURI_;
        owner = msg.sender;
        _setDefaultRoyalty(0x99946d4eb4B05165be06caE6A7F7A81095AFFd9D, 1000);
    }
    /* solhint-disable ordering */

    /// @notice Transfers ownership of the contract to a new account (`newOwner`)
    /// @dev Can only be called by an address with DEFAULT_ADMIN_ROLE
    /// @param newOwner_ New Owner of the contract
    /// Emits a {OwnershipTransferred} event
    function transferOwnership(address newOwner_)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(newOwner_ != address(0), "CBWC: owner cannot be 0 address");
        address previousOwner = owner;
        owner = newOwner_;

        emit OwnershipTransferred(previousOwner, owner);
    }

    /// @notice Used to set the baseURI for metadata
    /// @dev Only callable by an address with DEFAULT_ADMIN_ROLE
    /// @param baseURI_ The base URI
    function setBaseURI(string memory baseURI_)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(bytes(baseURI_).length > 0, "CBWC: invalid URI");
        _setBaseURI(baseURI_);
    }

    /// @notice Used to set the contractURI
    /// @dev Only callable by an address with DEFAULT_ADMIN_ROLE
    /// @param newContractURI_ The base URI
    function setContractURI(string memory newContractURI_)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(bytes(newContractURI_).length > 0, "CBWC: invalid URI");
        _contractURI = newContractURI_;
    }

    /// @notice Set the default royalties using the ERC2981 NFT Royalty Standard
    /// @dev Callable only by an address with DEFAULT_ADMIN_ROLE
    /// The fee numerator considers a 10000 denominator
    /// meaning that 10% royalties would require a feeNumerator of 1000
    /// @param receiver_ Address that will receive royalty payments
    /// @param feeNumerator_ The number used to calculate the royalty percentage
    function setDefaultRoyalties(address receiver_, uint96 feeNumerator_)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _setDefaultRoyalty(receiver_, feeNumerator_);
    }

    /// @notice ContractURI containing metadata for marketplaces
    /// @return The _contractURI
    function contractURI()
        external
        view
        returns (string memory)
    {
        return _contractURI;
    }

    /// @notice Tokens minted
    /// @dev include tokens burned
    /// @return Returns the total amount of tokens minted in the contract.
    function totalMinted()
        external
        view
        returns (uint256)
    {
        return _nextTokenId - 1;
    }

    /// @notice Override of supportsInterface function
    /// @param interfaceId the interfaceId
    /// @return bool if interfaceId is supported or not
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(
            AccessControlUpgradeable,
            ERC2981Upgradeable)
        returns (bool)
    {

        return interfaceId == _INTERFACE_ID_ERC165
            || interfaceId == _INTERFACE_ID_ERC721
            || interfaceId == _INTERFACE_ID_ERC721_METADATA
            || interfaceId == _INTERFACE_ID_ERC2981;
    }

    /// @notice UUPS Upgradeable authorization function
    /// @dev Callable only an address with UPGRADER_ROLE
    /// @param newImplementation_ Address of the new implementation
    /* solhint-disable no-empty-blocks */
    function _authorizeUpgrade(address newImplementation_)
        internal
        virtual
        override
        onlyRole(UPGRADER_ROLE)
    {}
    /* solhint-disable no-empty-blocks */

    /// @notice Used to set the CryptoBearWatchClub contract address
    /// @dev Only callable by an address with DEFAULT_ADMIN_ROLE
    /// @param cbwc_ The CryptoBearWatchClub contract address
    function setCBWC(address cbwc_)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        cbwc = ICBWC(cbwc_);
    }

    /// @notice Override ERC2981 {royaltyInfo} to validate whether a token exists
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) public view virtual override returns (address, uint256) {
        if(!_exists(_tokenId)) revert QueryNonExistentToken();
        return super.royaltyInfo(_tokenId, _salePrice);
    }

    /// @notice Overriding in order to start the Token ID
    function startingTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.14;


/// @title Crypto Bear Watch Club Pieces Interface
/// @author Kfish n Chips
/// @notice Interface of CBWC Staking contract
/// @custom:security-contact [email protected]
interface ICBWCStaking {
    /// @notice Stores token id staker address
    /// @dev mapping(uint256 => address) public tokenOwner
    /// @param tokenId_ the token ID to get the owner
    /// @return the address of the owner
    function tokenOwner(uint256 tokenId_) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./interfaces/IERC721KFNCReceiver.sol";
import "./interfaces/IERC721KFNC.sol";
import "./interfaces/IERC165KFNC.sol";


/// @title ERC721KFNCUUPSUpgradeable
/// @author Kfish n Chips
/// @notice Implementation of Non-Fungible Token Standard
/// @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
/// the Metadata extension, but not including the Enumerable extension, which is available separately as
/// {ERC721Enumerable}.
/// @custom:security-contact [email protected]
abstract contract ERC721KFNCUUPSUpgradeable is IERC721KFNC, UUPSUpgradeable {
    bytes4 internal constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 internal constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;
    bytes4 internal constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

    /// @dev Mapping from token ID to owner address ordered
    mapping(uint256 => address) private _tokenOwnersOrdered;
    /// @dev Mapping from token ID to owner address unordered
    mapping(uint256 => bool) private _unorderedOwner;
    /// @dev Mapping from token ID to owner address
    mapping(uint256 => address) private _tokenOwners;
    /// @dev Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenOperators;
    /// @dev Mapping from token ID to whether it has been burned
    mapping(uint256 => bool) private _burnedTokens;
    /// @dev Mapping owner address to token count
    mapping(address => uint256) private _balances;
    /// @dev Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operators;

    /// @dev Token name
    string private _name;
    /// @dev Token symbol
    string private _symbol;

    /// @dev Base URI for computing {tokenURI}.
    string private _baseURI;

    /// @dev Count NFTs tracked
    uint256 internal _nextTokenId;
    /// @dev Firts NFTs
    uint256 private _startingTokenId;
    /// @dev Count NFTs burned
    uint256 private _burnCounter;

    /// @notice Change or reaffirm the approved address for an NFT
    /// @dev The zero address indicates there is no approved address.
    ///  Throws unless `msg.sender` is the current NFT owner, or an authorized
    ///  operator of the current owner.
    /// @param _approved The new approved NFT controller
    /// @param _tokenId The NFT to approve
    function approve(address _approved, uint256 _tokenId) external {
        address owner = ownerOf(_tokenId);
        if (owner != msg.sender && !_operators[owner][msg.sender] && _tokenOperators[_tokenId] != msg.sender)
            revert CallerNotOwnerOrApprovedOperator();

        if (!_unorderedOwner[_tokenId]) {
            _tokenOwners[_tokenId] = owner;
            _unorderedOwner[_tokenId] = true;
        }
        _tokenOperators[_tokenId] = _approved;

        emit Approval(msg.sender, _approved, _tokenId);
    }

    /// @notice Enable or disable approval for a third party ("operator") to manage
    ///  all of `msg.sender`'s assets
    /// @dev Emits the ApprovalForAll event. The contract MUST allow
    ///  multiple operators per owner.
    /// @param _operator Address to add to the set of authorized operators
    /// @param _approved True if the operator is approved, false to revoke approval
    function setApprovalForAll(address _operator, bool _approved) external {
        _operators[msg.sender][_operator] = _approved;

        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    /// @notice Name for NFTs in this contract
    function name() external view returns (string memory) {
        return _name;
    }

    /// @notice An abbreviated name for NFTs in this contract
    function symbol() external view returns (string memory) {
        return _symbol;
    }

    /// @notice Base URI for computing {tokenURI}
    function baseURI() external view returns (string memory) {
        return _baseURI;
    }

    /// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
    /// @dev Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC
    ///  3986. The URI may point to a JSON file that conforms to the "ERC721
    ///  Metadata JSON Schema".
    function tokenURI(uint256 _tokenId) external view virtual returns (string memory) {
        if (_tokenId < _startingTokenId || _tokenId > _nextTokenId - 1) revert QueryNonExistentToken();
        return bytes(_baseURI).length > 0 ? string.concat(_baseURI, toString(_tokenId)) : "";
    }


    /// @notice Count all NFTs assigned to an owner
    /// @dev NFTs assigned to the zero address are considered invalid, and this
    ///  function throws for queries about the zero address.
    /// @param _owner An address for whom to query the balance
    /// @return The number of NFTs owned by `_owner`, possibly zero
    function balanceOf(address _owner) external view returns (uint256) {
        if (_owner == address(0)) revert QueryBalanceOfZeroAddress();
        return _balances[_owner];
    }

    /// @notice Count NFTs tracked by this contract
    /// @return A count of valid NFTs tracked by this contract, where each one of
    ///  them has an assigned and queryable owner not equal to the zero address
    function totalSupply() external view returns (uint256) {
        return _nextTokenId - _startingTokenId - _burnCounter;
    }

    /// @notice Get the approved address for a single NFT
    /// @dev Throws if `_tokenId` is not a valid NFT.
    /// @param _tokenId The NFT to find the approved address for
    /// @return The approved address for this NFT, or the zero address if there is none
    function getApproved(uint256 _tokenId) external view returns (address) {
        if (_tokenId < _startingTokenId || _tokenId > _nextTokenId - 1) revert QueryNonExistentToken();
        return _tokenOperators[_tokenId];
    }

    /// @notice Query if an address is an authorized operator for another address
    /// @param _owner The address that owns the NFTs
    /// @param _operator The address that acts on behalf of the owner
    /// @return True if `_operator` is an approved operator for `_owner`, false otherwise
    function isApprovedForAll(address _owner, address _operator) external view returns (bool) {
        return _operators[_owner][_operator];
    }

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///  except this function just sets data to "".
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public {
        safeTransferFrom(_from, _to, _tokenId, "");
    }

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT. When transfer is complete, this function
    ///  checks if `_to` is a smart contract (code size > 0). If so, it calls
    ///  `onERC721Received` on `_to` and throws if the return value is not
    ///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    /// @param data Additional data with no specified format, sent in call to `_to`
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory data
    ) public {
        transferFrom(_from, _to, _tokenId);
        if (_to.code.length > 0) {
            _checkERC721Received(_from, _to, _tokenId, data);
        }
    }

    /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
    ///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
    ///  THEY MAY BE PERMANENTLY LOST
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public {
        if (_tokenId < _startingTokenId || _tokenId > _nextTokenId - 1) revert QueryNonExistentToken();
        address owner = ownerOf(_tokenId);
        if (owner != _from) revert TokenNotOwnedByFromAddress();
        if (owner != msg.sender && !_operators[_from][msg.sender] && _tokenOperators[_tokenId] != msg.sender)
            revert CallerNotOwnerOrApprovedOperator();
        if (_to == address(0)) revert InvalidTransferToZeroAddress();

        _beforeTokenTransfer(_from, _to, _tokenId);

        _balances[_from] -= 1;
        _balances[_to] += 1;

        _tokenOperators[_tokenId] = address(0);
        _tokenOwners[_tokenId] = _to;
        _unorderedOwner[_tokenId] = true;

        emit Transfer(_from, _to, _tokenId);

        _afterTokenTransfer(_from, _to, _tokenId);
    }

    /// @notice Find the owner of an NFT
    /// @dev NFTs assigned to zero address are considered invalid, and queries
    ///  about them do throw.
    /// @param _tokenId The identifier for an NFT
    /// @return The address of the owner of the NFT
    function ownerOf(uint256 _tokenId) public view returns (address) {
        if (_tokenId < _startingTokenId || _tokenId > _nextTokenId - 1) revert QueryNonExistentToken();
        if (_burnedTokens[_tokenId]) revert QueryBurnedToken();
        return _unorderedOwner[_tokenId] ? _tokenOwners[_tokenId] : _ownerOf(_tokenId);
    }

    /// @notice Find the owner of an NFT
    /// @dev Does not revert if token is burned, this is used to query via multi-call
    /// @param _tokenId The identifier for an NFT
    /// @return The address of the owner of the NFT
    function unsafeOwnerOf(uint256 _tokenId) public view returns (address) {
        if(_burnedTokens[_tokenId]) return address(0);
        return _unorderedOwner[_tokenId] ? _tokenOwners[_tokenId] : _ownerOf(_tokenId);
    }

    /// @notice Same as calling {safeMint} without data
    function safeMint(address _to, uint256 _quantity) internal {
        safeMint(_to, _quantity, "");
    }

    /// @notice Same as calling {_mint} and then checking for IERC721Receiver
    function safeMint(
        address _to,
        uint256 _quantity,
        bytes memory _data
    ) internal {
        _mint(_to, _quantity);
        uint256 currentTokenId = _nextTokenId - 1;
        unchecked {
            if (_to.code.length != 0) {
                uint256 tokenId = _nextTokenId - _quantity - 1;
                do {
                    if (!_checkERC721Received(address(0), _to, ++tokenId, _data)) {
                        revert TransferToNonERC721ReceiverImplementer();
                    }
                } while (tokenId < currentTokenId);
            }
        }
    }

    /// @notice Mint a quantity of NFTs to an address
    /// @dev Saves the first token id minted by the address to a map of
    ///      used to verify ownership initially.
    ///      {_tokenOwnersOrdered} will be used to find the owner unless the token
    ///      has been transfered. In that case, it will be available in {_tokenOwners} instead.
    ///      This is done to reduce gas requirements of minting while keeping on-chain lookups
    ///      cheaper as tokens are transfered around. It helps with the burning of tokens.
    /// @param _to Receiver address
    /// @param _quantity The quantity to be minted
    function _mint(address _to, uint256 _quantity) internal {
        if (_to == address(0)) revert InvalidTransferToZeroAddress();
        if (_quantity == 0) revert MintZeroTokenId();
        unchecked {
            _balances[_to] += _quantity;
            uint256 newTotal = _nextTokenId + _quantity;

            for (uint256 i = _nextTokenId; i < newTotal; i++) {
                emit Transfer(address(0), _to, i);
            }

            _tokenOwnersOrdered[_nextTokenId] = _to;
            _nextTokenId = newTotal;
        }
    }

    /// @notice Same as calling {_burn} without a from address or approval check
    function _burn(uint256 _tokenId) internal {
        _burn(_tokenId, msg.sender);
    }

    /// @notice Same as calling {_burn} without approval check
    function _burn(uint256 _tokenId, address _from) internal {
        _burn(_tokenId, _from, false);
    }

    /// @notice Burn an NFT
    /// @dev Checks ownership of the token
    /// @param _tokenId The token id
    /// @param _from The owner address
    /// @param _approvalCheck Check if the caller is owner or an approved operator
    function _burn(
        uint256 _tokenId,
        address _from,
        bool _approvalCheck
    ) internal {
        if (_tokenId < _startingTokenId || _tokenId > _nextTokenId - 1) revert QueryNonExistentToken();
        address owner = ownerOf(_tokenId);
        if (owner != _from) revert TokenNotOwnedByFromAddress();
        if (_approvalCheck) {
            if (owner != msg.sender && !_operators[_from][msg.sender] && _tokenOperators[_tokenId] != msg.sender)
                revert CallerNotOwnerOrApprovedOperator();
        }

        _balances[_from]--;
        _burnCounter++;
        _burnedTokens[_tokenId] = true;

        _tokenOperators[_tokenId] = address(0);

        emit Transfer(_from, address(0), _tokenId);
    }

    /// @notice Before Token Transfer Hook
    /// @param from Token owner
    /// @param to Receiver
    /// @param tokenId The token id
    /* solhint-disable no-empty-blocks */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
    /* solhint-disable no-empty-blocks */

    /// @notice After Token Transfer Hook
    /// @param from Token owner
    /// @param to Receiver
    /// @param tokenId The token id
    /* solhint-disable no-empty-blocks */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
    /* solhint-disable no-empty-blocks */

    /// @notice Initializer due to this being an upgradeable contract
    /// @dev calls the unchained initializer
    /// @param name_ Name of the contract
    /// @param symbol_ An abbreviated name for NFTs in this contract
    function __ERC721KFNC_init(
        string memory name_,
        string memory symbol_,
        string memory baseURI_
    ) internal onlyInitializing {
        __ERC721KFNC_init_unchained(name_, symbol_, baseURI_);
    }

    /// @notice Initializer due to this being an upgradeable contract
    /// @param name_ Name of the contract
    /// @param symbol_ An abbreviated name for NFTs in this contract
    function __ERC721KFNC_init_unchained(
        string memory name_,
        string memory symbol_,
        string memory baseURI_
    ) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
        _baseURI = baseURI_;
        _nextTokenId = _startingTokenId = startingTokenId();
    }

     /// @notice Used to set the baseURI for metadata
    /// @dev Only callable by an address with DEFAULT_ADMIN_ROLE
    /// @param baseURI_ The base URI
    function _setBaseURI(string memory baseURI_)
        internal
    {
        _baseURI = baseURI_;
    }

    /// @notice Verify whether a token exists and has not been burned
    /// @param _tokenId The token id
    /// @return bool
    function _exists(uint256 _tokenId) internal view returns (bool) {
        return _tokenId >= _startingTokenId && _tokenId < _nextTokenId && !_burnedTokens[_tokenId];
    }

    /// @notice Number to use as the first token id
    /// @dev Overridable by implementing contract
    function startingTokenId() internal view virtual returns (uint256) {
        return 0;
    }

    /// @notice Used to change a token id uint256 into string
    /// @param value The number to change
    /// @return string
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OpenZeppelin's implementation - MIT licence
        // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /// @notice Checking if the receiving contract implements IERC721Receiver
    /// @param from Token owner
    /// @param to Receiver
    /// @param tokenId The token id
    /// @param _data Extra data
    function _checkERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool)
    {
        try IERC721KFNCReceiver(to).onERC721Received(msg.sender, from, tokenId, _data) returns (bytes4 retval) {
            return retval == IERC721KFNCReceiver(to).onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert TransferToNonERC721ReceiverImplementer();
            } else {
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }

    /// @notice Find the owner of an NFT
    /// @dev This function should only be called from {ownerOf(_tokenId)}
    ///      This iterates through the original minters since they are ordered
    ///      If an owner is address(0), it keeps looking for the owner by checking the
    ///      previous tokens. If minter A minted 10, then the first token will have the address
    ///      and the rest will have address(0)
    /// @param _tokenId The identifier for an NFT
    /// @return The address of the owner of the NFT
    function _ownerOf(uint256 _tokenId) private view returns (address) {
        uint256 curr = _tokenId;
        unchecked {
            address owner = address(0);
            while (owner == address(0)) {
                if (!_unorderedOwner[curr]) {
                    owner = _tokenOwnersOrdered[curr];
                }
                curr--;
            }
            return owner;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/common/ERC2981.sol)

pragma solidity ^0.8.0;

import "../../interfaces/IERC2981Upgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the NFT Royalty Standard, a standardized way to retrieve royalty payment information.
 *
 * Royalty information can be specified globally for all token ids via {_setDefaultRoyalty}, and/or individually for
 * specific token ids via {_setTokenRoyalty}. The latter takes precedence over the first.
 *
 * Royalty is specified as a fraction of sale price. {_feeDenominator} is overridable but defaults to 10000, meaning the
 * fee is specified in basis points by default.
 *
 * IMPORTANT: ERC-2981 only specifies a way to signal royalty information and does not enforce its payment. See
 * https://eips.ethereum.org/EIPS/eip-2981#optional-royalty-payments[Rationale] in the EIP. Marketplaces are expected to
 * voluntarily pay royalties together with sales, but note that this standard is not yet widely supported.
 *
 * _Available since v4.5._
 */
abstract contract ERC2981Upgradeable is Initializable, IERC2981Upgradeable, ERC165Upgradeable {
    function __ERC2981_init() internal onlyInitializing {
    }

    function __ERC2981_init_unchained() internal onlyInitializing {
    }
    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    RoyaltyInfo private _defaultRoyaltyInfo;
    mapping(uint256 => RoyaltyInfo) private _tokenRoyaltyInfo;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165Upgradeable, ERC165Upgradeable) returns (bool) {
        return interfaceId == type(IERC2981Upgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc IERC2981Upgradeable
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) public view virtual override returns (address, uint256) {
        RoyaltyInfo memory royalty = _tokenRoyaltyInfo[_tokenId];

        if (royalty.receiver == address(0)) {
            royalty = _defaultRoyaltyInfo;
        }

        uint256 royaltyAmount = (_salePrice * royalty.royaltyFraction) / _feeDenominator();

        return (royalty.receiver, royaltyAmount);
    }

    /**
     * @dev The denominator with which to interpret the fee set in {_setTokenRoyalty} and {_setDefaultRoyalty} as a
     * fraction of the sale price. Defaults to 10000 so fees are expressed in basis points, but may be customized by an
     * override.
     */
    function _feeDenominator() internal pure virtual returns (uint96) {
        return 10000;
    }

    /**
     * @dev Sets the royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setDefaultRoyalty(address receiver, uint96 feeNumerator) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: invalid receiver");

        _defaultRoyaltyInfo = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Removes default royalty information.
     */
    function _deleteDefaultRoyalty() internal virtual {
        delete _defaultRoyaltyInfo;
    }

    /**
     * @dev Sets the royalty information for a specific token id, overriding the global default.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: Invalid parameters");

        _tokenRoyaltyInfo[tokenId] = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Resets royalty information for the token id back to the global default.
     */
    function _resetTokenRoyalty(uint256 tokenId) internal virtual {
        delete _tokenRoyaltyInfo[tokenId];
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[48] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;


/// @title Interface of the ERC165 standard, as defined in the
///     https://eips.ethereum.org/EIPS/eip-165[EIP].
/// @author Kfish n Chips
/// @dev Implementers can declare support of contract interfaces, which can then be
///     queried by others ({ERC165Checker}).
/// @custom:security-contact [email protected]
interface IERC165KFNC {
    /// @notice Query if a contract implements an interface
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.14;

/// @title Crypto Bear Watch Club Pieces Interface
/// @author Kfish n Chips
/// @notice Interface of CBWC contract
/// @custom:security-contact [email protected]
interface ICBWC {
     /// @notice returns the owner of the `tokenId_` token.
     /// @dev `tokenId_` must exist.
     /// @param tokenId_ the id token
     /// @return Returns the owner´s address of the `tokenId` token.
    function ownerOf(uint256 tokenId_) external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

/// @dev Note: the ERC-165 identifier for this interface is 0x150b7a02.
interface IERC721KFNCReceiver {
    /// @notice Handle the receipt of an NFT
    /// @dev The ERC721 smart contract calls this function on the recipient
    ///  after a `transfer`. This function MAY throw to revert and reject the
    ///  transfer. Return of other than the magic value MUST result in the
    ///  transaction being reverted.
    ///  Note: the contract address is always the message sender.
    /// @param _operator The address which called `safeTransferFrom` function
    /// @param _from The address which previously owned the token
    /// @param _tokenId The NFT identifier which is being transferred
    /// @param _data Additional data with no specified format
    /// @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    ///  unless throwing
    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes calldata _data
    ) 
        external 
        returns (bytes4);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "../IERC721KFNC.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981Upgradeable is IERC165Upgradeable {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.14;

/// @title Interface of ERC-721 Non-Fungible Token Standard, with metadata extension
/// @author Kfish n Chips
/// @dev Required interface of an ERC721 compliant contract.
/// @custom:security-contact [email protected]
interface IERC721KFNC  {
    error TransferToNonERC721ReceiverImplementer();
    error QueryBalanceOfZeroAddress();
    error ApprovedOfZeroAddress();
    error QueryNonExistentToken();
    error QueryBurnedToken();
    error CallerNotOwnerOrApprovedOperator();
    error InvalidApprovalZeroAddress();
    error TokenNotOwnedByFromAddress();
    error InvalidTransferToZeroAddress();
    error MintZeroTokenId();


    /// @notice Emitted when `tokenId` token is transferred from `from` to `to`.
    /// @dev This emits when ownership of any NFT changes by any mechanism.
    ///  This event emits when NFTs are created (`from` == 0) and destroyed
    ///  (`to` == 0). Exception: during contract creation, any number of NFTs
    ///  may be created and assigned without emitting Transfer. At the time of
    ///  any transfer, the approved address for that NFT (if any) is reset to none.
    /// @param _from transfer address
    /// @param _to receiver address
    /// @param _tokenId the NFT transfered
    event Transfer(
        address indexed _from, 
        address indexed _to, 
        uint256 indexed _tokenId
    );


    /// @notice Emitted when `owner` enables `approved` to manage the `tokenId` token.
    /// @dev This emits when the approved address for an NFT is changed or
    ///  reaffirmed. The zero address indicates there is no approved address.
    ///  When a Transfer event emits, this also indicates that the approved
    ///  address for that NFT (if any) is reset to none.
    /// @param _owner owner address
    /// @param _approved approved address
    /// @param _tokenId NFT that approve for
    event Approval(
        address indexed _owner, 
        address indexed _approved, 
        uint256 indexed _tokenId
    );

    
    /// @notice Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
    /// @dev This emits when an operator is enabled or disabled for an owner.
    ///  The operator can manage all NFTs of the owner.
    /// @param _owner owner address
    /// @param _operator operator address
    /// @param _approved enables or disables the operator
    event ApprovalForAll(
        address indexed _owner, 
        address indexed _operator, 
        bool _approved
    );


    /// @notice Count all NFTs assigned to an owner
    /// @dev NFTs assigned to the zero address are considered invalid, and this
    ///  function throws for queries about the zero address.
    /// @param _owner An address for whom to query the balance
    /// @return The number of NFTs owned by `_owner`, possibly zero
    function balanceOf(address _owner) external view returns (uint256);


    /// @notice Find the owner of an NFT
    /// @dev NFTs assigned to zero address are considered invalid, and queries
    ///  about them do throw.
    /// @param _tokenId The identifier for an NFT
    /// @return The address of the owner of the NFT
    function ownerOf(uint256 _tokenId) external view returns (address);


    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT. When transfer is complete, this function
    ///  checks if `_to` is a smart contract (code size > 0). If so, it calls
    ///  `onERC721Received` on `_to` and throws if the return value is not
    ///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    /// @param data Additional data with no specified format, sent in call to `_to`
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) external;


    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///  except this function just sets data to "".
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;


    /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
    ///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
    ///  THEY MAY BE PERMANENTLY LOST
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function transferFrom(address _from, address _to, uint256 _tokenId) external;


    /// @notice Change or reaffirm the approved address for an NFT
    /// @dev The zero address indicates there is no approved address.
    ///  Throws unless `msg.sender` is the current NFT owner, or an authorized
    ///  operator of the current owner.
    /// @param _approved The new approved NFT controller
    /// @param _tokenId The NFT to approve
    function approve(address _approved, uint256 _tokenId) external;


    /// @notice Enable or disable approval for a third party ("operator") to manage
    ///  all of `msg.sender`'s assets
    /// @dev Emits the ApprovalForAll event. The contract MUST allow
    ///  multiple operators per owner.
    /// @param _operator Address to add to the set of authorized operators
    /// @param _approved True if the operator is approved, false to revoke approval
    function setApprovalForAll(address _operator, bool _approved) external;


    /// @notice Get the approved address for a single NFT
    /// @dev Throws if `_tokenId` is not a valid NFT.
    /// @param _tokenId The NFT to find the approved address for
    /// @return The approved address for this NFT, or the zero address if there is none
    function getApproved(uint256 _tokenId) external view returns (address);


    /// @notice Query if an address is an authorized operator for another address
    /// @param _owner The address that owns the NFTs
    /// @param _operator The address that acts on behalf of the owner
    /// @return True if `_operator` is an approved operator for `_owner`, false otherwise
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);


    function totalSupply() external view returns (uint256);

    /// @notice A descriptive name for a collection of NFTs in this contract
    function name() external view returns (string memory);

    /// @notice An abbreviated name for NFTs in this contract
    function symbol() external view returns (string memory);

    /// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
    /// @dev Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC
    ///  3986. The URI may point to a JSON file that conforms to the "ERC721
    ///  Metadata JSON Schema".
    function tokenURI(uint256 _tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}