// SPDX-License-Identifier: MIT

// ██████╗ ███████╗████████╗██████╗  ██████╗                
// ██╔══██╗██╔════╝╚══██╔══╝██╔══██╗██╔═══██╗               
// ██████╔╝█████╗     ██║   ██████╔╝██║   ██║               
// ██╔══██╗██╔══╝     ██║   ██╔══██╗██║   ██║               
// ██║  ██║███████╗   ██║   ██║  ██║╚██████╔╝               
// ╚═╝  ╚═╝╚══════╝   ╚═╝   ╚═╝  ╚═╝ ╚═════╝                
                                                         
// ██████╗  ██████╗ ██╗     ██╗     ███████╗██████╗ ███████╗
// ██╔══██╗██╔═══██╗██║     ██║     ██╔════╝██╔══██╗██╔════╝
// ██████╔╝██║   ██║██║     ██║     █████╗  ██████╔╝███████╗
// ██╔══██╗██║   ██║██║     ██║     ██╔══╝  ██╔══██╗╚════██║
// ██║  ██║╚██████╔╝███████╗███████╗███████╗██║  ██║███████║
// ╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚══════╝╚══════╝╚═╝  ╚═╝╚══════╝

pragma solidity ^0.8.0;

//Mimetic Metadata
import { MimeticMetadata } from "./Mimetics/MimeticMetadata.sol";
import { INonDilutive } from "./Interfaces/INonDilutive.sol";

//Lock Registry
import "./Interfaces/ILock.sol";
import "./LockRegistry/LockRegistry.sol";

//ERC-Standards and OpenZeppelin
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./ERC721A.sol";
import "./DutchAuction/MDDA.sol";
import "./Scorekeeper.sol";

contract RetroRollers is 
    ERC721A,
    INonDilutive,
    MimeticMetadata,
    LockRegistry,
    AccessControl,
    ReentrancyGuard,
    MDDA,
    Scorekeeper
{
    using Strings for uint256;

    address public ROLLERS_PAYOUT_ADDRESS = 0x9cEE145eA8842E8C332BEC94Eb48337ff38cdadF;
    bytes32 public merkleRoot;

    uint256 public mintPrice = 0.08 ether;

    uint256 public maxPublicMintPerAddress = 2;
    uint256 public MAX_SUPPLY = 8888;
    uint256 public lockedSupply = 3333;
    uint256 public reservedSupply = 3000;
    uint256 public totalReserveMinted;
    uint256 public publicSupply;
    uint64 public startTime;

    bool public mintActive = false;

    mapping(uint => uint) private tokenMatrix;
    mapping(uint => uint) private mappedTokenIds;

    /** Contract Functionality Variables */
    bytes4 private constant _INTERFACE_ID_LOCKABLE = 0xc1c8d4d6;
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    constructor(string memory _baseTokenURI) ERC721A("Retro Rollers", "RR") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        startTime = 1651770000; // May 5th, 1:00 PM EST

        setPublicSupply();

        loadGeneration(
            0,              // layer
            true,           // enabled   (cannot be removed by project owner)
            true,           // locked    (cannot be removed by project owner)
            true,           // sticky    (cannot be removed by owner)
            _baseTokenURI
        );
    }

    modifier onlyOperator() {
        if(!(hasRole(OPERATOR_ROLE, msg.sender)||owner()==msg.sender)) revert CallerIsNotOperator();
        _;
    }

    modifier mintCompliance() {
        if(startTime > block.timestamp) revert SaleNotStarted();
        if(!mintActive) revert SaleNotStarted();
        _;
    }

    /** ensures the function caller is the user */

    modifier isContract() {
        uint32 size = 32;
        address _addr = msg.sender;
        assembly {
            size := extcodesize(_addr)
        }
        if(size > 0) revert CallerIsContract();
        _;
    }

    function mintDutchAuction(uint8 _quantity) public payable isContract nonReentrant {
        DAHook(_quantity, totalSupply());

        uint random = randomness();
        for(uint i = 0; i < _quantity; i++){
            _mintToken(msg.sender, mappedTokenFor((random+i)));
        }
    }

    /** Public Mint Function */
    function mint(uint64 quantity)
        external
        payable
        isContract
        nonReentrant
        mintCompliance
    {
        uint totalSupply = totalSupply();

        if(_addressData[msg.sender].mintTime < startTime) {
            _addressData[msg.sender].reserveMinted = 0;
            _addressData[msg.sender].numberMinted = 0;
        }

        if(totalSupply - totalReserveMinted + quantity > publicSupply) revert MaxMintAmountReached();
        if(quantity == 0) revert InvalidMintAmount();
        if(quantity + _addressData[msg.sender].numberMinted - _addressData[msg.sender].reserveMinted > maxPublicMintPerAddress) revert MaxMintAmountReached();

        delete totalSupply;

        uint random = randomness();

        for(uint i = 0; i < quantity; i++){
            _mintToken(msg.sender, mappedTokenFor((random+i)));
        }

        refundIfOver(quantity * mintPrice);
    }

    /** Presale Mint Function */
    function reservedMint(bytes32[] calldata _merkleProof)
        external
        payable
        isContract
        nonReentrant
        mintCompliance
    {
        if(totalSupply() == MAX_SUPPLY - lockedSupply) revert MaxSupplyReached();

        if(!verify(msg.sender, _merkleProof)) revert InvalidProof();

        if(_addressData[msg.sender].mintTime < startTime) {
            _addressData[msg.sender].reserveMinted = 0;
            _addressData[msg.sender].numberMinted = 0;
        } else { 
            if (_addressData[msg.sender].reserveMinted == 1) revert MaxMintAmountReached();
        }

        _mintToken(msg.sender, mappedTokenFor(randomness()));

        _addressData[msg.sender].reserveMinted = 1;
        refundIfOver(mintPrice);
    }

    function randomness() internal view returns (uint256) {
        return uint256(keccak256(
            abi.encodePacked(
                msg.sender,
                block.coinbase,
                block.difficulty,
                block.gaslimit,
                block.timestamp,
                totalSupply(),
                blockhash(block.number - 1)
            )
        ));
    }

    function mappedTokenFor(uint _randomSeed) internal returns (uint64) {

        uint maxIndex = MAX_SUPPLY - lockedSupply-_mintCounter;
        uint random = _randomSeed % (maxIndex);

        uint lastAvail = tokenMatrix[maxIndex];

        uint256 value = 0;
        if (tokenMatrix[random] == 0) {
            // If this matrix position is empty, set the value to the generated random number.
            value = random;
        } else {
            // Otherwise, use the previously stored number from the matrix.
            value = tokenMatrix[random];
        }

        // If the last available tokenID is still unused...
        if (lastAvail == 0) {
            // ...store that ID in the current matrix position.
            tokenMatrix[random] = maxIndex;
        } else {
            // ...otherwise copy over the stored number to the current matrix position.
            tokenMatrix[random] = lastAvail;
        }

        return uint64(value + _startTokenId());
    }

    /** Get the owner of a specific token from the tokenId */
    function getOwnershipData(uint256 tokenId) external view returns (TokenOwnership memory) {
        return _ownershipOf(tokenId);
    }

    function getTokensOfOwner(address owner) external view returns(uint[] memory) {
        uint[] memory tokens = new uint[](balanceOf(owner));
        uint ct = 0;

        for(uint i = 1; i <= MAX_SUPPLY - lockedSupply; i++) {
            if(_ownerships[i].addr == owner) {
                tokens[ct] = i;
                ct++;
            }
        }

        return tokens;
    }

    /**  Refund function which requires the minimum amount for the transaction and returns any extra payment to the sender */
    function refundIfOver(uint256 price) private {
        if(msg.value < price) revert NotEnoughETH();
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    function verify(address target, bytes32[] calldata _merkleProof) public view returns(bool) {
        bytes32 leaf = keccak256(abi.encodePacked(target));
        return MerkleProof.verify(_merkleProof, merkleRoot, leaf);
    }

    /**  Standard TokenURI ERC721A function. */
    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        // Make sure that the token has been minted
        if(!_exists(_tokenId)) revert InvalidTokenId();
        return _tokenURI(_tokenId);
    }

    /** Mint Function only usable by contract owner. Use reserved for giveaways and promotions. */
    function ownerMint(address to, uint256 quantity) public 
        isContract 
        nonReentrant 
        onlyOperator 
    {
        if(quantity + totalSupply() > MAX_SUPPLY) revert MaxSupplyReached();
            uint random = randomness();

        for(uint i = 0; i < quantity; i++){
            _mintToken(to, mappedTokenFor(random+i));
        }

    }

    function toggleMint() external onlyOperator {
        mintActive = !mintActive;
    }

    function setStartTime(uint64 _startTime) external onlyOperator {
        startTime = _startTime;
    }

    function setMintPrice(uint _mintPrice) external onlyOperator {
        mintPrice = _mintPrice;
    }

    function setReservedSupply(uint _reservedSupply) external onlyOperator {
        reservedSupply = _reservedSupply;
        setPublicSupply();
    }

    function setLockedSupply(uint _lockedSupply) external onlyOperator {
        lockedSupply = _lockedSupply;
        setPublicSupply();
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOperator {
        merkleRoot = _merkleRoot;
    }

    function setScoreSignerAddress(address _scoreSigner) external onlyOperator {
        scoreSigner = _scoreSigner;
    }

    function setRollScorePrice(uint64 _price) external onlyOperator {
        rollScorePrice = _price;
    }

    function setRollTokenAddress(address _rollAddress) external onlyOperator {
        rollToken = IROLL(_rollAddress);
    }

    function setPayoutAddress(address _payoutAddress) external onlyOperator {
        ROLLERS_PAYOUT_ADDRESS = _payoutAddress;
    }

    function setPublicSupply() internal {
        publicSupply = MAX_SUPPLY - reservedSupply - lockedSupply;
    } 

    /** MIMETIC METADATA FUNCTIONS **/

    /*
     * @notice Allows any user to see the layer that a token currently has enabled.
     */
    function getTokenGeneration(uint256 _tokenId) override public virtual view returns(uint256) {
        if(_exists(_tokenId) == false) revert InvalidTokenId();
        return _getTokenGeneration(_tokenId);
    }

    function focusGeneration(uint256 _layerId, uint256 _tokenId) override public virtual payable {
        if(!isUnlocked(_tokenId)) revert LockedToken();
        _focusGeneration(_layerId, _tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, AccessControl) returns (bool) {
        return interfaceId == _INTERFACE_ID_LOCKABLE || super.supportsInterface(interfaceId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override {
        if(!isUnlocked(tokenId)) revert LockedToken();
        ERC721A.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public override {
        if(!isUnlocked(tokenId)) revert LockedToken();
        ERC721A.safeTransferFrom(from, to, tokenId, _data);
    }

    function lockId(uint256 _id) external override {
        if(!_exists(_id)) revert InvalidTokenId();
        _lockId(_id);
    }

    function unlockId(uint256 _id) external override {
        if(!_exists(_id)) revert InvalidTokenId();
        _unlockId(_id);
    }

    function freeId(uint256 _id, address _contract) external override {
        if(!_exists(_id)) revert InvalidTokenId();
        _freeId(_id, _contract);
    }

    function recordHighScore(uint8 v, bytes32 r, bytes32 s, UserData memory record) public override(Scorekeeper) {
        require(ownerOf(record.rollerId) == msg.sender, "NotOwner");
        super.recordHighScore(v,r,s,record);
    }

    /** Standard withdraw function for the owner to pull the contract */
    function withdraw() external onlyOperator {
        uint256 mintAmount = address(this).balance;
        address rollers = payable(ROLLERS_PAYOUT_ADDRESS); // SET UP MULTI-SIG WALLET
        bool success;

        (success, ) = rollers.call{value: mintAmount }("");
        if(!success) revert TransactionUnsuccessful();
    }

    function withdrawInitialDAFunds() public onlyOperator {
        require(!INITIAL_FUNDS_WITHDRAWN, "Initial funds have already been withdrawn.");
        require(DA_FINAL_PRICE > 0, "DA has not finished!");

        //Only pull the amount of ether that is the final price times how many were bought. This leaves room for refunds until final withdraw.
        uint256 initialFunds = DA_QUANTITY * DA_FINAL_PRICE;

        INITIAL_FUNDS_WITHDRAWN = true;

        (bool succ, ) = payable(ROLLERS_PAYOUT_ADDRESS).call{value: initialFunds}("");

        require(succ, "transfer failed");
    }

    function withdrawFinalDAFunds() public onlyOperator {
        //Require this is 1 week after DA Start.
        require(block.timestamp >= DA_STARTING_TIMESTAMP + 604800);

        uint256 finalFunds = address(this).balance;

        (bool succ, ) = payable(ROLLERS_PAYOUT_ADDRESS).call{value: finalFunds}("");
        require(succ, "transfer failed");
    }
}

error CallerIsContract();
error CallerIsNotOperator();
error InvalidMintAmount();
error InvalidProof();
error InvalidTokenId();
error LockedToken();
error MaxMintAmountReached();
error MaxSupplyReached();
error NotEnoughETH();
error SaleNotStarted();
error TransactionUnsuccessful();

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import { IMimeticMetadata } from "./IMimeticMetadata.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

error MintExceedsMaxSupply();
error MintCostMismatch();
error MintNotEnabled();

error GenerationAlreadyLoaded();
error GenerationNotDifferent();
error GenerationNotEnabled();
error GenerationNotDowngradable();
error GenerationNotToggleable();
error GenerationCostMismatch();

error TokenNonExistent();
error TokenNotRevealed();
error TokenRevealed();
error TokenOwnerMismatch();

error WithdrawFailed();

/**
 * @title  Non-Dilutive 721
 * @author nftchance
 * @notice This token was created to serve as a proof for a conversational point. Non-dilutive 721 
 *         tokens can exist. Teams can easily build around this concept. Teams can additionally  
 *         still monetize the going ons and hard work of their team. However, that does not need to 
 *         come at the cost of their holders. As it stands every token drop following the 
 *         initial is a holder mining experience in which every single holders is impacted by the 
 *         lower market concentration of liquidty and attention.
 * @notice If you plan on yoinking this code. Please message me. Curiosity breeds progress. I am 
 *         here to help if you need or want it. I do not want a cut; I do not want paid. I want a 
 *         market of * honest and holder thoughtful devs. This is a very very weird 721 
 *         implementation and comes with many nuances. I'd love to discuss.
 * @notice Doodles drop of the Spaceships by wrapping into a new token is 100% dilutive.
 * @dev The extendable 'Generations' wrap the token metadata within the content to remove the need 
 *         of dropping another token into the collection. By doing this, that does not inherently
 *         mean the metadata is mutable beyond the extent that the token holder can change the
 *         active metadata. The underlying generations still much exist and can be configured in a 
 *         way that allows accessing them again if desired. However, there does also exist the 
 *         ability to have truly immutable layers that cannot be removed. (If following this
 *         implementation it is vitally noted that object permanence must be achieved from day one.
 *         A project CANNOT implement this on a mutable URL that is massive holder-trust betrayal.)
 */
contract MimeticMetadata is IMimeticMetadata, Ownable {
    using Strings for uint256;

    mapping(uint256 => Generation) public generations;
    mapping(uint256 => uint256) tokenToGeneration;


    /**
     * @notice Function that controls which metadata the token is currently utilizing.
     *         By default every token is using layer zero which is loaded during the time
     *         of contract deployment. Cannot be removed, is immutable, holders can always
     *         revert back. However, if at any time they choose to "wrap" their token then
     *         it is automatically reflected here.
     * @notice Errors out if the token has not yet been revealed within this collection.
     * @param _tokenId the token we are getting the URI for
     * @return _tokenURI The internet accessible URI of the token 
     */
    function _tokenURI(uint256 _tokenId) internal virtual view returns (string memory) {
        // Make sure that the token has been minted
        uint256 activeGenerationLayer = tokenToGeneration[_tokenId];
        Generation memory activeGeneration = generations[activeGenerationLayer];

        return string(abi.encodePacked(activeGeneration.baseURI, _tokenId.toString()));
    }

    /**
     * @notice Allows the project owner to establish a new generation. Generations are enabled by 
     *      default. With this we initialize the generation to be loaded.
     * @dev _name is passed as a param, if this is not needed; remove it. Don't be superfluous.
     * @dev only accessed by owner of contract
     * @param _layerId the z-depth of the metadata being loaded
     * @param _enabled a generation can be connected before a token can utilize it
     * @param _locked can this layer be disabled by the project owner
     * @param _sticky can this layer be removed by the holder
     * @param _baseURI the internet URI the metadata is stored on
     */
    function loadGeneration(uint256 _layerId, bool _enabled, bool _locked, bool _sticky, string memory _baseURI)
        override 
        public 
        virtual 
        onlyOwner 
    {
        Generation storage generation = generations[_layerId];

        // Make sure that we are not overwriting an existing layer.
        if(generation.loaded) revert GenerationAlreadyLoaded();

        generations[_layerId] = Generation({
            loaded: true,
            enabled: _enabled,
            locked: _locked,
            sticky: _sticky,
            baseURI: _baseURI
        });
    }

    /**
     * @notice Used to toggle the state of a generation. Disable generations cannot be focused by 
     *         token holders.
     */
    function toggleGeneration( uint256 _layerId) override public virtual onlyOwner {
        Generation memory generation = generations[_layerId];

        // Make sure that the token isn't locked (immutable but overlapping keywords is spicy)
        if(generation.enabled && generation.locked) revert GenerationNotToggleable();

        generations[_layerId].enabled = !generation.enabled;
    }

    /**
     * @notice Allows any user to see the layer that a token currently has enabled.
     */
    function _getTokenGeneration(uint256 _tokenId) internal virtual view returns(uint256) {
        return tokenToGeneration[_tokenId];
    }

    /**
     * @notice Function that allows token holders to focus a generation and wear their skin.
     *         This is not in control of the project maintainers once the layer has been 
     *         initialized.
     * @dev This function is utilized when building supporting functions around the concept of 
     *         extendable metadata. For example, if Doodles were to drop their spaceships, it would 
     *         be loaded and then enabled by the holder through this function on a front-end.
     * @param _layerId the layer that this generation belongs on. The bottom is zero.
     * @param _tokenId the token that we are updating the metadata for
     */
    function _focusGeneration(uint256 _layerId, uint256 _tokenId) internal virtual {
        uint256 activeGenerationLayer = tokenToGeneration[_tokenId]; 
        if(activeGenerationLayer == _layerId) revert GenerationNotDifferent();

        // Make sure that the generation has been enabled
        Generation memory generation = generations[_layerId];
        if(!generation.enabled) revert GenerationNotEnabled();

        // Make sure a user can't take off a sticky generation
        Generation memory activeGeneration = generations[activeGenerationLayer];
        if(activeGeneration.sticky && _layerId < activeGenerationLayer) revert GenerationNotDowngradable(); 

        // Finally evolve to the generation
        tokenToGeneration[_tokenId] = _layerId;

        emit GenerationChange( _layerId, _tokenId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface INonDilutive {
    function getTokenGeneration(
        uint256 _tokenId
    ) external returns (
        uint256
    );

    function focusGeneration(
         uint256 _layerId
        ,uint256 _tokenId
    ) external payable;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

interface IERC721x {

	/**
     * @dev Returns if the token is locked (non-transferrable) or not.
     */
	function isUnlocked(uint256 _id) external view returns(bool);

	/**
     * @dev Returns the amount of locks on the token.
     */
	function lockCount(uint256 _tokenId) external view returns(uint256);

	/**
     * @dev Returns if a contract is allowed to lock/unlock tokens.
     */
	function approvedContract(address _contract) external view returns(bool);

	/**
     * @dev Returns the contract that locked a token at a specific index in the mapping.
     */
	function lockMap(uint256 _tokenId, uint256 _index) external view returns(address);

	/**
     * @dev Returns the mapping index of a contract that locked a token.
     */
	function lockMapIndex(uint256 _tokenId, address _contract) external view returns(uint256);

	/**
     * @dev Locks a token, preventing it from being transferrable
     */
	function lockId(uint256 _id) external;

	/**
     * @dev Unlocks a token.
     */
	function unlockId(uint256 _id) external;

	/**
     * @dev Unlocks a token from a given contract if the contract is no longer approved.
     */
	function freeId(uint256 _id, address _contract) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

/*
 *     ,_,
 *    (',')
 *    {/"\}
 *    -"-"-
 */

import "@openzeppelin/contracts/access/Ownable.sol";
import "../Interfaces/ILock.sol";

abstract contract LockRegistry is Ownable, IERC721x {
	
	mapping(address => bool) public override approvedContract;
	mapping(uint256 => uint256) public override lockCount;
	mapping(uint256 => mapping(uint256 => address)) public override lockMap;
	mapping(uint256 => mapping(address => uint256)) public override lockMapIndex;

	event TokenLocked(uint256 indexed tokenId, address indexed approvedContract);
	event TokenUnlocked(uint256 indexed tokenId, address indexed approvedContract);

	function isUnlocked(uint256 _id) public view override returns(bool) {
		return lockCount[_id] == 0;
	}

	function updateApprovedContracts(address[] calldata _contracts, bool[] calldata _values) external onlyOwner {
		require(_contracts.length == _values.length, "!length");
		for(uint256 i = 0; i < _contracts.length; i++)
			approvedContract[_contracts[i]] = _values[i];
	}

	function _lockId(uint256 _id) internal {
		require(approvedContract[msg.sender], "Cannot update map");
		require(lockMapIndex[_id][msg.sender] == 0, "ID already locked by caller");

		uint256 count = lockCount[_id] + 1;
		lockMap[_id][count] = msg.sender;
		lockMapIndex[_id][msg.sender] = count;
		lockCount[_id]++;
		emit TokenLocked(_id, msg.sender);
	}

	function _unlockId(uint256 _id) internal {
		require(approvedContract[msg.sender], "Cannot update map");
		uint256 index = lockMapIndex[_id][msg.sender];
		require(index != 0, "ID not locked by caller");
		
		uint256 last = lockCount[_id];
		if (index != last) {
			address lastContract = lockMap[_id][last];
			lockMap[_id][index] = lastContract;
			lockMap[_id][last] = address(0);
			lockMapIndex[_id][lastContract] = index;
		}
		else
			lockMap[_id][index] = address(0);
		lockMapIndex[_id][msg.sender] = 0;
		lockCount[_id]--;
		emit TokenUnlocked(_id, msg.sender);
	}

	function _freeId(uint256 _id, address _contract) internal {
		require(!approvedContract[_contract], "Cannot update map");
		uint256 index = lockMapIndex[_id][_contract];
		require(index != 0, "ID not locked");

		uint256 last = lockCount[_id];
		if (index != last) {
			address lastContract = lockMap[_id][last];
			lockMap[_id][index] = lastContract;
			lockMap[_id][last] = address(0);
			lockMapIndex[_id][lastContract] = index;
		}
		else
			lockMap[_id][index] = address(0);
		lockMapIndex[_id][_contract] = 0;
		lockCount[_id]--;
		emit TokenUnlocked(_id, _contract);
	}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

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
abstract contract AccessControl is Context, IAccessControl, ERC165 {
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
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
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
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
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
}

// SPDX-License-Identifier: MIT
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import './IERC721A.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension. Built to optimize for lower gas during batch mints.
 *
 * Assumes serials are sequentially minted starting at _startTokenId() (defaults to 0, e.g. 0, 1, 2, 3..).
 *
 * Assumes that an owner cannot have more than 2**64 - 1 (max value of uint64) of supply.
 *
 * Assumes that the maximum token id cannot exceed 2**256 - 1 (max value of uint256).
 */
contract ERC721A is Context, ERC165, IERC721A {
    using Address for address;
    using Strings for uint256;

    // The number of tokens burned.
    uint256 internal _burnCounter;

    uint256 public _mintCounter;

    uint256 public _maxSupply = 8888;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to ownership details
    // An empty struct value does not necessarily mean the token is unowned. See _ownershipOf implementation for details.
    mapping(uint256 => TokenOwnership) internal _ownerships;

    // Mapping owner address to address data
    mapping(address => AddressData) internal _addressData;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * To change the starting tokenId, please override this function.
     */
    function _startTokenId() internal view virtual returns (uint256) {
        return 1;
    }

    /**
     * @dev Burned tokens are calculated here, use _totalMinted() if you want to count just minted tokens.
     */
    function totalSupply() public view override returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than _currentIndex - _startTokenId() times
        unchecked {
            return _mintCounter - _burnCounter;
        }
    }

    /**
     * Returns the total amount of tokens minted in the contract.
     */
    function _totalMinted() internal view returns (uint256) {
        // Counter underflow is impossible as _currentIndex does not decrement,
        // and it is initialized to _startTokenId()
        unchecked {
            return _mintCounter;
        }
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : '';
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view override returns (uint256) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        return uint256(_addressData[owner].balance);
    }

    /**
     * Returns the number of tokens minted by `owner`.
     */
    function _numberMinted(address owner) internal view returns (uint256) {
        return uint256(_addressData[owner].numberMinted);
    }

    /**
     * Returns the number of tokens burned by or on behalf of `owner`.
     */
    function _reserveMinted(address owner) internal view returns (uint256) {
        return uint256(_addressData[owner].reserveMinted);
    }

    /**
     * Returns the auxillary data for `owner`. (e.g. number of whitelist mint slots used).
     */
    function _getMintTime(address owner) internal view returns (uint64) {
        return _addressData[owner].mintTime;
    }

    /**
     * Sets the auxillary data for `owner`. (e.g. number of whitelist mint slots used).
     * If there are multiple variables, please pack them into a uint64.
     */
    function _setAux(address owner, uint64 mintTime) internal {
        _addressData[owner].mintTime = mintTime;
    }

    /**
     * Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around in the collection over time.
     */
    function _ownershipOf(uint256 tokenId) internal view returns (TokenOwnership memory) {
        // unchecked {
        //     if (_startTokenId() <= curr && curr < _maxSupply) {
        //         TokenOwnership memory ownership = _ownerships[curr];
        //         if (!ownership.burned) {
        //             if (ownership.addr != address(0)) {
        //                 return ownership;
        //             }
        //             // Invariant:
        //             // There will always be an ownership that has an address and is not burned
        //             // before an ownership that does not have an address and is not burned.
        //             // Hence, curr will not underflow.
        //             while (true) {
        //                 curr--;
        //                 ownership = _ownerships[curr];
        //                 if (ownership.addr != address(0)) {
        //                     return ownership;
        //                 }
        //             }
        //         }
        //     }
        // }
        // revert OwnerQueryForNonexistentToken();
        return _ownerships[tokenId];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        return _ownerships[tokenId].addr;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return '';
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public override {
        address owner = ERC721A.ownerOf(tokenId);
        if (to == owner) revert ApprovalToCurrentOwner();

        if (_msgSender() != owner && !isApprovedForAll(owner, _msgSender())) {
            revert ApprovalCallerNotOwnerNorApproved();
        }

        _approve(to, tokenId, owner);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view override returns (address) {
        if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        if (operator == _msgSender()) revert ApproveToCaller();

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, '');
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        _transfer(from, to, tokenId);
        if (to.isContract() && !_checkContractOnERC721Received(from, to, tokenId, _data)) {
            revert TransferToNonERC721ReceiverImplementer();
        }
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        // return _startTokenId() <= tokenId && tokenId < _maxSupply && !_ownerships[tokenId].burned;
        return _ownerships[tokenId].addr != address(0) && !_ownerships[tokenId].burned;
    }

        /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event.
     */

    
    function _mintToken(address to, uint64 tokenId) internal {
        if (to == address(0)) revert MintToZeroAddress();
        if (tokenId == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, tokenId, 1);

        // Overflows are incredibly unrealistic.
        // balance or numberMinted overflow if current value of either + quantity > 1.8e19 (2**64) - 1
        // updatedIndex overflows if _currentIndex + quantity > 1.2e77 (2**256) - 1
        unchecked {
            _addressData[to].balance++;
            _addressData[to].numberMinted++;
            _addressData[to].mintTime = uint64(block.timestamp);

            _ownerships[tokenId].addr = to;
            _ownerships[tokenId].startTimestamp = uint64(block.timestamp);

            emit Transfer(address(0), to, tokenId);

            _mintCounter++;
        }
        
        _afterTokenTransfers(address(0), to, tokenId, 1);
    }

    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal {

    }

    function _safeMint(address to, uint256 quantity) internal {
    }

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 quantity) internal {
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) private {
        TokenOwnership memory prevOwnership = _ownershipOf(tokenId);

        if (prevOwnership.addr != from) revert TransferFromIncorrectOwner();

        bool isApprovedOrOwner = (_msgSender() == from ||
            isApprovedForAll(from, _msgSender()) ||
            getApproved(tokenId) == _msgSender());

        if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
        if (to == address(0)) revert TransferToZeroAddress();

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, from);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            _addressData[from].balance -= 1;
            _addressData[to].balance += 1;

            TokenOwnership storage currSlot = _ownerships[tokenId];
            currSlot.addr = to;
            currSlot.startTimestamp = uint64(block.timestamp);

            // If the ownership slot of tokenId+1 is not explicitly set, that means the transfer initiator owns it.
            // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
            uint256 nextTokenId = tokenId + 1;
            TokenOwnership storage nextSlot = _ownerships[nextTokenId];
            if (nextSlot.addr == address(0)) {
                // This will suffice for checking _exists(nextTokenId),
                // as a burned slot cannot contain the zero address.
                if (_exists(tokenId)) {
                    nextSlot.addr = from;
                    nextSlot.startTimestamp = prevOwnership.startTimestamp;
                }
            }
        }

        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
    }

    /**
     * @dev Equivalent to `_burn(tokenId, false)`.
     */
    function _burn(uint256 tokenId) internal virtual {
        _burn(tokenId, false);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId, bool approvalCheck) internal virtual {
        TokenOwnership memory prevOwnership = _ownershipOf(tokenId);

        address from = prevOwnership.addr;

        if (approvalCheck) {
            bool isApprovedOrOwner = (_msgSender() == from ||
                isApprovedForAll(from, _msgSender()) ||
                getApproved(tokenId) == _msgSender());

            if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
        }

        _beforeTokenTransfers(from, address(0), tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, from);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            AddressData storage addressData = _addressData[from];
            addressData.balance -= 1;

            // Keep track of who burned the token, and the timestamp of burning.
            TokenOwnership storage currSlot = _ownerships[tokenId];
            currSlot.addr = from;
            currSlot.startTimestamp = uint64(block.timestamp);
            currSlot.burned = true;

            // If the ownership slot of tokenId+1 is not explicitly set, that means the burn initiator owns it.
            // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
            uint256 nextTokenId = tokenId + 1;
            TokenOwnership storage nextSlot = _ownerships[nextTokenId];
            if (nextSlot.addr == address(0)) {
                // This will suffice for checking _exists(nextTokenId),
                // as a burned slot cannot contain the zero address.
                if (_exists(tokenId)) {
                    nextSlot.addr = from;
                    nextSlot.startTimestamp = prevOwnership.startTimestamp;
                }
            }
        }

        emit Transfer(from, address(0), tokenId);
        _afterTokenTransfers(from, address(0), tokenId, 1);

        // Overflow not possible, as _burnCounter cannot be exceed _currentIndex times.
        unchecked {
            _burnCounter++;
        }
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(
        address to,
        uint256 tokenId,
        address owner
    ) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkContractOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
            return retval == IERC721Receiver(to).onERC721Received.selector;
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

    /**
     * @dev Hook that is called before a set of serially-ordered token ids are about to be transferred. This includes minting.
     * And also called before burning one token.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Hook that is called after a set of serially-ordered token ids have been transferred. This includes
     * minting.
     * And also called after one token has been burned.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` has been
     * transferred to `to`.
     * - When `from` is zero, `tokenId` has been minted for `to`.
     * - When `to` is zero, `tokenId` has been burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

/*
Open source Dutch Auction contract
Dutch Auction that exposes a function to minters that allows them to pull difference between payment price and settle price.
Initial version has no owner functions to not allow for owner foul play.
Written by: mousedev.eth
*/

contract MDDA is Ownable {
    uint256 public DA_STARTING_PRICE;
    uint256 public DA_ENDING_PRICE;
    uint256 public DA_DECREMENT;
    uint256 public DA_DECREMENT_FREQUENCY;
    uint256 public DA_STARTING_TIMESTAMP;
    uint256 public DA_MAX_QUANTITY;
    uint256 public DA_FINAL_PRICE;
    uint256 public DA_QUANTITY;
    bool public DATA_SET;
    bool public INITIAL_FUNDS_WITHDRAWN;

    //Struct for storing batch price data.
    struct TokenBatchPriceData {
        uint128 pricePaid;
        uint128 quantityMinted;
    }

    //Token to token price data
    mapping(address => TokenBatchPriceData[]) public userToTokenBatchPriceData;

    function initializeAuctionData(
        uint256 _DAStartingPrice,
        uint256 _DAEndingPrice,
        uint256 _DADecrement,
        uint256 _DADecrementFrequency,
        uint256 _DAStartingTimestamp,
        uint256 _DAMaxQuantity,
        uint256 _DAQuantity
    ) public onlyOwner {
        require(!DATA_SET, "DA data has already been set.");
        DA_STARTING_PRICE = _DAStartingPrice;
        DA_ENDING_PRICE = _DAEndingPrice;
        DA_DECREMENT = _DADecrement;
        DA_DECREMENT_FREQUENCY = _DADecrementFrequency;
        DA_STARTING_TIMESTAMP = _DAStartingTimestamp;
        DA_MAX_QUANTITY = _DAMaxQuantity;
        DA_QUANTITY = _DAQuantity;

        DATA_SET = true;
    }

    function userToTokenBatches(address user) public view returns (TokenBatchPriceData[] memory) {
        return userToTokenBatchPriceData[user];
    }

    function currentPrice() public view returns (uint256) {
        require( block.timestamp >= DA_STARTING_TIMESTAMP, "DA has not started!");

        if (DA_FINAL_PRICE > 0) return DA_FINAL_PRICE;

        //Seconds since we started
        uint256 timeSinceStart = block.timestamp - DA_STARTING_TIMESTAMP;

        //How many decrements should've happened since that time
        uint256 decrementsSinceStart = timeSinceStart / DA_DECREMENT_FREQUENCY;

        //How much eth to remove
        uint256 totalDecrement = decrementsSinceStart * DA_DECREMENT;

        //If how much we want to reduce is greater or equal to the range, return the lowest value
        if (totalDecrement >= DA_STARTING_PRICE - DA_ENDING_PRICE) {
            return DA_ENDING_PRICE;
        }

        //If not, return the starting price minus the decrement.
        return DA_STARTING_PRICE - totalDecrement;
    }

    function DAHook(uint128 _quantity, uint256 _totalSupply) internal {
        require(DATA_SET, "DA data not set yet");

        uint256 _currentPrice = currentPrice();

        //Require enough ETH
        require(msg.value >= _quantity * _currentPrice, "Did not send enough eth.");
        require(_quantity > 0 && _quantity <= DA_MAX_QUANTITY, "Incorrect quantity!");
        require(block.timestamp >= DA_STARTING_TIMESTAMP, "DA has not started!");
        require(_totalSupply + _quantity <= DA_QUANTITY, "Max supply for DA reached!");

        //Set the final price.
        if (_totalSupply + _quantity == DA_QUANTITY)
            DA_FINAL_PRICE = _currentPrice;

        //Add to user batch array.
        userToTokenBatchPriceData[msg.sender].push(TokenBatchPriceData(uint128(msg.value), _quantity));
    }

    function refundExtraETH() public {
        require(DA_FINAL_PRICE > 0, "Dutch action must be over!");

        uint256 totalRefund;

        for ( uint256 i = userToTokenBatchPriceData[msg.sender].length; i > 0; i--) {
            //This is what they should have paid if they bought at lowest price tier.
            uint256 expectedPrice = userToTokenBatchPriceData[msg.sender][i - 1]
                .quantityMinted * DA_FINAL_PRICE;

            //What they paid - what they should have paid = refund.
            uint256 refund = userToTokenBatchPriceData[msg.sender][i - 1]
                .pricePaid - expectedPrice;

            //Remove this tokenBatch
            userToTokenBatchPriceData[msg.sender].pop();

            //Send them their extra monies.
            totalRefund += refund;
        }
        payable(msg.sender).transfer(totalRefund);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/Strings.sol';
import "./IROLL.sol";

contract Scorekeeper
{
    using Strings for uint256;

    struct EIP712Domain {
        string  name;
        string  version;
        uint256 chainId;
        address verifyingContract;
    }

    struct UserData {
        uint64 rollerId;
        uint64 score;
        uint64 timestamp;
        address wallet;
    }

    IROLL public rollToken;
    address public scoreSigner;
    uint256 public rollScorePrice = 100 ether;

    bytes32 constant EIP712DOMAIN_TYPEHASH = keccak256(
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    );

    bytes32 constant USERDATA_TYPEHASH = keccak256(
        "UserData(uint64 rollerId,uint64 score,uint64 timestamp,address wallet)"
    );

    bytes32 DOMAIN_SEPARATOR;


    mapping(uint => UserData) public scores;

    constructor() {
        uint256 chainId;
        assembly {
          chainId := chainid()
        }

        DOMAIN_SEPARATOR = hash(EIP712Domain({
            name: "RetroRollers",
            version: '1',
            chainId: chainId,
            verifyingContract: address(this)
        }));
    }

/** Hashing functions used in verfiying Score messages */
    function hash(EIP712Domain memory eip712Domain) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            EIP712DOMAIN_TYPEHASH,
            keccak256(bytes(eip712Domain.name)),
            keccak256(bytes(eip712Domain.version)),
            eip712Domain.chainId,
            eip712Domain.verifyingContract
        ));
    }

    function hash(UserData memory score) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            USERDATA_TYPEHASH,
            score.rollerId,
            score.score,
            score.timestamp,
            score.wallet
        ));
    }

/** Score Functions */

    function recordHighScore(uint8 v, bytes32 r, bytes32 s, UserData memory record) public virtual {
        if(rollScorePrice > rollToken.balanceOf(msg.sender)) revert NotEnoughRollToken();
        if(rollScorePrice > rollToken.allowance(msg.sender, address(this))) revert NotEnoughRollToken();

        rollToken.transferFrom(msg.sender, address(this), rollScorePrice);

        bytes32 digest = keccak256(abi.encodePacked(
        "\x19\x01",
        DOMAIN_SEPARATOR,
        hash(record)
        ));

        address signer = ecrecover(digest, v, r, s);

        if(signer != scoreSigner) revert InvalidSignature();
        // require(signer == scoreSigner, "InvalidSignature");
        if(signer == address(0)) revert ECDSAInvalidSignature();
        // require(signer != address(0), "ECDSAInvalidSignature");
        //require(ownerOf(record.rollerId) == msg.sender, "NotOwner");
        if(record.wallet != msg.sender) revert NotScoreWallet();
        // require(record.wallet == msg.sender, "NotScorerWallet");

        if(scores[record.rollerId].score > record.score) revert NotHighScore();

        saveScore(record);
    }

    function saveScore(UserData memory record) internal virtual {
        scores[record.rollerId] = record;
    }

    function getScore(uint _tokenId) public virtual view returns (UserData memory) {
        return scores[_tokenId];
    }
}

error NotHighScore();
error NotEnoughRollToken();
error NotScoreWallet();
error InvalidSignature();
error ECDSAInvalidSignature();

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface IMimeticMetadata { 
    struct Generation {
        bool enabled;
        bool loaded;
        bool locked;
        bool sticky;
        string baseURI;
    }

    event GenerationChange(uint256 _layerId, uint256 _tokenId);

    function loadGeneration(uint256 _layerId, bool _enabled, bool _locked, bool _sticky, string memory _baseURI) external;

    function toggleGeneration(uint256 _layerId) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
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
interface IERC165 {
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
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol';

/**
 * @dev Interface of an ERC721A compliant contract.
 */
interface IERC721A is IERC721, IERC721Metadata {
    /**
     * The caller must own the token or be an approved operator.
     */
    error ApprovalCallerNotOwnerNorApproved();

    /**
     * The token does not exist.
     */
    error ApprovalQueryForNonexistentToken();

    /**
     * The caller cannot approve to their own address.
     */
    error ApproveToCaller();

    /**
     * The caller cannot approve to the current owner.
     */
    error ApprovalToCurrentOwner();

    /**
     * Cannot query the balance for the zero address.
     */
    error BalanceQueryForZeroAddress();

    /**
     * Cannot mint to the zero address.
     */
    error MintToZeroAddress();

    /**
     * The quantity of tokens minted must be more than zero.
     */
    error MintZeroQuantity();

    /**
     * The token does not exist.
     */
    error OwnerQueryForNonexistentToken();

    /**
     * The caller must own the token or be an approved operator.
     */
    error TransferCallerNotOwnerNorApproved();

    /**
     * The token must be owned by `from`.
     */
    error TransferFromIncorrectOwner();

    /**
     * Cannot safely transfer to a contract that does not implement the ERC721Receiver interface.
     */
    error TransferToNonERC721ReceiverImplementer();

    /**
     * Cannot transfer to the zero address.
     */
    error TransferToZeroAddress();

    /**
     * The token does not exist.
     */
    error URIQueryForNonexistentToken();

    // Compiler will pack this into a single 256bit word.
    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Keeps track of the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
    }

    // Compiler will pack this into a single 256bit word.
    struct AddressData {
        uint64 balance;
        uint64 numberMinted;
        uint64 mintTime;
        uint64 reserveMinted;
    }

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     * @dev Burned tokens are calculated here, use _totalMinted() if you want to count just minted tokens.
     */
    function totalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IROLL {
    function balanceOf(address owner) external view returns(uint256);
    function transferFrom(address, address, uint256) external;
    function allowance(address owner, address spender) external view returns(uint256);
    function approve(address spender, uint256 amount) external returns(bool);
}