/**
 *Submitted for verification at Etherscan.io on 2022-02-02
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;



/**
 * @title PixelCons interface
 * @dev Interface for the core PixelCons contract
 */
interface IPixelCons {
	function getAdmin() external view returns(address);

	//PixelCon Tokens
	function create(address to, uint256 tokenId, bytes8 name) external payable returns(uint64);
	function rename(uint256 tokenId, bytes8 name) external returns(uint64);
	function exists(uint256 tokenId) external view returns(bool);
	function creatorOf(uint256 tokenId) external view returns(address);
	function creatorTotal(address creator) external view returns(uint256);
	function tokenOfCreatorByIndex(address creator, uint256 index) external view returns(uint256);
	function getTokenIndex(uint256 tokenId) external view returns(uint64);

	//Collections
	function createCollection(uint64[] memory tokenIndexes, bytes8 name) external returns(uint64);
	function renameCollection(uint64 collectionIndex, bytes8 name) external returns(uint64);
	function clearCollection(uint64 collectionIndex) external returns(uint64);
	function collectionExists(uint64 collectionIndex) external view returns(bool);
	function collectionCleared(uint64 collectionIndex) external view returns(bool);
	function totalCollections() external view returns(uint256);
	function collectionOf(uint256 tokenId) external view returns(uint256);
	function collectionTotal(uint64 collectionIndex) external view returns(uint256);
	function getCollectionName(uint64 collectionIndex) external view returns(bytes8);
	function tokenOfCollectionByIndex(uint64 collectionIndex, uint256 index) external view returns(uint256);

	//ERC-721 Implementation
	function balanceOf(address owner) external view returns(uint256);
	function ownerOf(uint256 tokenId) external view returns(address);
	function approve(address to, uint256 tokenId) external;
	function getApproved(uint256 tokenId) external view returns(address);
	function setApprovalForAll(address to, bool approved) external;
	function isApprovedForAll(address owner, address operator) external view returns(bool);
	function transferFrom(address from, address to, uint256 tokenId) external;
	function safeTransferFrom(address from, address to, uint256 tokenId) external;
	function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) external;

	//ERC-721 Enumeration Implementation
	function totalSupply() external view returns(uint256);
	function tokenByIndex(uint256 tokenIndex) external view returns(uint256);
	function tokenOfOwnerByIndex(address owner, uint256 index) external view returns(uint256);

	//ERC-721 Metadata Implementation
	function name() external view returns(string memory);
	function symbol() external view returns(string memory);
	function tokenURI(uint256 tokenId) external view returns(string memory);
}



/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}



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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        require(owner() == _msgSender(), "Caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}



/**
 * @title ICrossDomainMessenger
 */
interface ICrossDomainMessenger {
    /**********
     * Events *
     **********/

    event SentMessage(
        address indexed target,
        address sender,
        bytes message,
        uint256 messageNonce,
        uint256 gasLimit
    );
    event RelayedMessage(bytes32 indexed msgHash);
    event FailedRelayedMessage(bytes32 indexed msgHash);

    /*************
     * Variables *
     *************/

    function xDomainMessageSender() external view returns (address);

    /********************
     * Public Functions *
     ********************/

    /**
     * Sends a cross domain message to the target messenger.
     * @param _target Target contract address.
     * @param _message Message to send to the target.
     * @param _gasLimit Gas limit for the provided message.
     */
    function sendMessage(
        address _target,
        bytes calldata _message,
        uint32 _gasLimit
    ) external;
}



/**
 * @title CrossDomainEnabled
 * @dev Helper contract for contracts performing cross-domain communications
 *
 * Compiler used: defined by inheriting contract
 */
contract CrossDomainEnabled {
    /*************
     * Variables *
     *************/

    // Messenger contract used to send and recieve messages from the other domain.
    address public messenger;

    /***************
     * Constructor *
     ***************/

    /**
     * @param _messenger Address of the CrossDomainMessenger on the current layer.
     */
    constructor(address _messenger) {
        messenger = _messenger;
    }

    /**********************
     * Function Modifiers *
     **********************/

    /**
     * Enforces that the modified function is only callable by a specific cross-domain account.
     * @param _sourceDomainAccount The only account on the originating domain which is
     *  authenticated to call this function.
     */
    modifier onlyFromCrossDomainAccount(address _sourceDomainAccount) {
        require(
            msg.sender == address(getCrossDomainMessenger()),
            "OVM_XCHAIN: messenger contract unauthenticated"
        );

        require(
            getCrossDomainMessenger().xDomainMessageSender() == _sourceDomainAccount,
            "OVM_XCHAIN: wrong sender of cross-domain message"
        );

        _;
    }

    /**********************
     * Internal Functions *
     **********************/

    /**
     * Gets the messenger, usually from storage. This function is exposed in case a child contract
     * needs to override.
     * @return The address of the cross-domain messenger contract which should be used.
     */
    function getCrossDomainMessenger() internal virtual returns (ICrossDomainMessenger) {
        return ICrossDomainMessenger(messenger);
    }

    /**q
     * Sends a message to an account on another domain
     * @param _crossDomainTarget The intended recipient on the destination domain
     * @param _message The data to send to the target (usually calldata to a function with
     *  `onlyFromCrossDomainAccount()`)
     * @param _gasLimit The gasLimit for the receipt of the message on the target domain.
     */
    function sendCrossDomainMessage(
        address _crossDomainTarget,
        uint32 _gasLimit,
        bytes memory _message
    ) internal {
        // slither-disable-next-line reentrancy-events, reentrancy-benign
        getCrossDomainMessenger().sendMessage(_crossDomainTarget, _message, _gasLimit);
    }
}



/**
 * @title PixelConInvadersBridge
 * @notice The purpose of this contract is to generate, custody and bridge Invader PixelCons. All users are treated equally with the exception 
 * of an admin user who only controls the ability to reseed generation. No fees are required to interact with this contract beyond base gas fees. 
 * For more information about PixelConInvaders, please visit (https://invaders.pixelcons.io)
 * @dev This contract follows the standard Optimism L2 bridging contracts
 * See (https://github.com/ethereum-optimism/optimism)
 * @author PixelCons
 */
contract PixelConInvadersBridge is Ownable, CrossDomainEnabled {

	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	///////////////////////////////////////////////////////// Structs/Constants /////////////////////////////////////////////////////////////////
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	// Constants
	uint64 constant MAX_TOKENS = 1000;
	uint64 constant MINT1_PIXELCON_INDEX = 1217;//before 2022
	uint64 constant MINT2_PIXELCON_INDEX = 792; //before 2021
	uint64 constant MINT3_PIXELCON_INDEX = 714; //before 2020
	uint64 constant MINT4_PIXELCON_INDEX = 651;
	uint64 constant MINT5_PIXELCON_INDEX = 651; //genesis
	uint64 constant MINT6_PIXELCON_INDEX = 100; //first 100
	
	
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	///////////////////////////////////////////////////////////// Storage ///////////////////////////////////////////////////////////////////////
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	// Address of the original PixelCons contract
	address internal _pixelconsContract;
	
	// Address of the PixelCon Invaders contract (L2)
	address internal _pixelconInvadersContract;

	// The base seed used for invader generation
	uint256 internal _generationSeed;


	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	///////////////////////////////////////////////////////////// Events ////////////////////////////////////////////////////////////////////////
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	// Invader token events
	event Mint(uint256 indexed invaderId, uint256 generationSeed, uint256 generationId, uint256 generationIndex, address minter);
	event Bridge(uint256 indexed invaderId, address to);
	event Unbridge(uint256 indexed invaderId, address to);


	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	/////////////////////////////////////////////////////// PixelConInvadersBridge //////////////////////////////////////////////////////////////
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	/**
	 * @dev Contract constructor
	 */
	constructor(address pixelconsContract, address l1CrossDomainMessenger) CrossDomainEnabled(l1CrossDomainMessenger) Ownable() {
		//require(pixelconsContract != address(0), "Invalid address"); //unlikely
		//require(l1CrossDomainMessenger != address(0), "Invalid address"); //unlikely
		_pixelconsContract = pixelconsContract;
		_pixelconInvadersContract = address(0);
		_generationSeed = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), block.difficulty)));
	}

	/**
     * @dev Sets the Invader contract address on L2
	 * @param pixelconInvadersContract -Invader contract address
	 */
	function linkInvadersContract(address pixelconInvadersContract) public onlyOwner {
		//require(pixelconInvadersContract != address(0), "Invalid address"); //unlikely
		require(_pixelconInvadersContract == address(0), "Already set");
		_pixelconInvadersContract = pixelconInvadersContract;
	}

	/**
	 * @dev Updates the generation seed
	 */
	function cycleGenerationSeed() public onlyOwner {
		_generationSeed = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), block.difficulty)));
	}
	
	////////////////// PixelCon Invader Tokens //////////////////
	
	/**
	 * @dev Mint an Invader
	 * @param pixelconId -ID of the PixelCon to generate from
	 * @param generationIndex -Index number to generate from
	 * @param gasLimit -Amount of gas for messenger (advise to keep <=1900000)
	 * @return ID of the new invader
	 */
	function mintInvader(uint256 pixelconId, uint32 generationIndex, uint32 gasLimit) public returns (uint256) {
		//require(pixelconId != uint256(0), "Invalid ID"); //duplicate require in 'ownerOf' function
		require(generationIndex < 6, "Invalid index");
		address minter = _msgSender();
		
		//check that minter owns the pixelcon
		address pixelconOwner = IPixelCons(_pixelconsContract).ownerOf(pixelconId);
		require(pixelconOwner == minter, "Not PixelCon owner");
		
		//check that invaders can still be minted
		uint256 numInvadersCreated = IPixelCons(_pixelconsContract).creatorTotal(address(this));
		require(numInvadersCreated < (MAX_TOKENS-1), "Max Invaders have been minted");
		
		//check that the given generation index is valid for the pixelcon
		uint64 pixelconIndex = IPixelCons(_pixelconsContract).getTokenIndex(pixelconId);
		if(generationIndex == 5) require(pixelconIndex < MINT6_PIXELCON_INDEX, "Index out of bounds");
		if(generationIndex == 4) require(pixelconIndex < MINT5_PIXELCON_INDEX, "Index out of bounds");
		if(generationIndex == 3) require(pixelconIndex < MINT4_PIXELCON_INDEX, "Index out of bounds");
		if(generationIndex == 2) require(pixelconIndex < MINT3_PIXELCON_INDEX, "Index out of bounds");
		if(generationIndex == 1) require(pixelconIndex < MINT2_PIXELCON_INDEX, "Index out of bounds");
		if(generationIndex == 0) require(pixelconIndex < MINT1_PIXELCON_INDEX, "Index out of bounds");
		
		//generate the invader
		uint256 invaderId = _generate(pixelconId, generationIndex);
		
		//create the pixelcon
		IPixelCons(_pixelconsContract).create(address(this), invaderId, bytes8(0));

		//bridge pixelcon to the invader contract on L2
		_bridgeToL2(invaderId, minter, gasLimit);

		//emit events
		emit Mint(invaderId, _generationSeed, pixelconId, generationIndex, minter);
		return invaderId;
	}
	
	/**
	 * @dev Bridge an Invader to L2
	 * @param tokenId -ID of the Invader to bridge
	 * @param from -Address of current Invader PixelCon owner
	 * @param to -Address of desired Invader owner
	 * @param gasLimit -Amount of gas for messenger (advise to keep <=1900000)
	 */
	function bridgeToL2(uint256 tokenId, address from, address to, uint32 gasLimit) public {
		//require(tokenId != uint256(0), "Invalid ID"); //duplicate require in 'ownerOf' function
		//require(from != address(0), "Invalid address"); //duplicate require in 'transferFrom' function
		require(to != address(0), "Invalid address");
		
		//check that caller owns the pixelcon
		address pixelconOwner = IPixelCons(_pixelconsContract).ownerOf(tokenId);
		require(pixelconOwner == _msgSender(), "Not owner");
		
		//check that the pixelcon was created by this contract
		address pixelconCreator = IPixelCons(_pixelconsContract).creatorOf(tokenId);
		require(pixelconCreator == address(this), "Not Invader");
		
		//transfer pixelcon to this contract
		IPixelCons(_pixelconsContract).transferFrom(from, address(this), tokenId);
	
		//bridge pixelcon to the invader contract on L2
		_bridgeToL2(tokenId, to, gasLimit);
	}
	
    /**
     * @dev Unbridge the Invader PixelCon from L2 (callable only by the L1 messenger)
	 * @param tokenId -ID of token
	 * @param to -New owner address
	 */
	function unbridgeFromL2(uint256 tokenId, address to) external onlyFromCrossDomainAccount(_pixelconInvadersContract) {
		//require(tokenId != uint256(0), "Invalid ID"); //duplicate require in 'transferFrom' function
		//require(to != address(0), "Invalid address"); //duplicate require in 'transferFrom' function
		
		//transfer
		IPixelCons(_pixelconsContract).transferFrom(address(this), to, tokenId);
		emit Unbridge(tokenId, to);
	}
	
    /**
     * @dev Returns the current seed used in generation
	 * @return Current generation seed
     */
    function getGenerationSeed() public view returns (uint256) {
        return _generationSeed;
    }
	
    /**
     * @dev Returns linked Pixelcons contract
	 * @return Pixelcons contract
     */
    function getPixelconsContract() public view returns (address) {
        return _pixelconsContract;
    }
	
    /**
     * @dev Returns linked PixelconInvaders contract
	 * @return PixelconInvaders contract
     */
    function getPixelconInvadersContract() public view returns (address) {
        return _pixelconInvadersContract;
    }
	

	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	////////////////////////////////////////////////////////////// Utils ////////////////////////////////////////////////////////////////////////
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	/**
     * @dev Bridges the Invader to L2
	 * @param tokenId -ID of the Invader
	 * @param to -The address to receive the Invader
	 * @param gasLimit -Amount of gas for messenger
	 */
	function _bridgeToL2(uint256 tokenId, address to, uint32 gasLimit) private {
		//construct calldata for L2 bridge function
		bytes memory message = abi.encodeWithSignature("bridgeFromL1(uint256,address)", tokenId, to);

		//send message to L2
		sendCrossDomainMessage(_pixelconInvadersContract, gasLimit, message);
		emit Bridge(tokenId, to);
	}
	
	
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	/////////////////////////////////////////////////////// Invader Generation //////////////////////////////////////////////////////////////////
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	/**
	 * @dev Generates an Invader from a PixelCon ID and generation index
	 * @param pixelconId -The PixelCon ID to use in generation
	 * @param generationIndex -The index to use in generation
	 * @return Invader ID
	 */
	function _generate(uint256 pixelconId, uint32 generationIndex) private view returns (uint256) {
		uint256 seed = uint256(keccak256(abi.encodePacked(_generationSeed, pixelconId, generationIndex)));
		/*                      [mask 3         ] [mask 2] [mask 1] [colors] [flags]
		seed: 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000 */

		//flags
		uint8 horizontalExpand1 = uint8(seed & 0x00000001);
		uint8 verticalExpand1 = uint8(seed & 0x00000002);
		uint8 horizontalExpand2 = uint8(seed & 0x00000004);
		uint8 verticalExpand2 = uint8(seed & 0x00000008);
		seed = seed >> 32;

		//colors
		(uint256 color1, uint256 color2, uint256 color3) = _getColors(seed);
		seed = seed >> 32;

		//masks
		uint256 mask1 = _generateMask_5x5(seed, verticalExpand1, horizontalExpand1);
		seed = seed >> 32;
		uint256 mask2 = _generateMask_5x5(seed, verticalExpand2, horizontalExpand2);
		seed = seed >> 32;
		uint256 mask3 = _generateMask_8x8(seed);
		seed = seed >> 64;
		uint256 combinedMask = mask1 & mask2;
		uint256 highlightMask = mask1 & mask3;

		uint256 invaderId = ((mask1 & ~combinedMask & ~highlightMask) & color1) | ((combinedMask & ~highlightMask) & color2) | (highlightMask & color3);
		return invaderId;
	}
	
	/**
	 * @dev Generates an 8x8 mask
	 * @param seed -Randomness for generation
	 * @return 256bit mask
	 */
	function _generateMask_8x8(uint256 seed) private pure returns (uint256){
		uint256 mask = _generateLine_8x8(seed);
		mask = (mask << 32) + _generateLine_8x8(seed >> 8);
		mask = (mask << 32) + _generateLine_8x8(seed >> 16);
		mask = (mask << 32) + _generateLine_8x8(seed >> 24);
		mask = (mask << 32) + _generateLine_8x8(seed >> 32);
		mask = (mask << 32) + _generateLine_8x8(seed >> 40);
		mask = (mask << 32) + _generateLine_8x8(seed >> 48);
		mask = (mask << 32) + _generateLine_8x8(seed >> 56);
		return mask;
	}
	
	/**
	 * @dev Generates a single line for 8x8 mask
	 * @param seed -Randomness for generation
	 * @return 256bit mask line
	 */
	function _generateLine_8x8(uint256 seed) private pure returns (uint256){
		uint256 line = 0x00000000;
		if((seed & 0x00000003) == 0x00000001) line |= 0x000ff000;
		if((seed & 0x0000000c) == 0x00000004) line |= 0x00f00f00;
		if((seed & 0x00000030) == 0x00000010) line |= 0x0f0000f0;
		if((seed & 0x000000c0) == 0x00000040) line |= 0xf000000f;
		return line;
	}
	
	/**
	 * @dev Generates an 5x5 mask
	 * @param seed -Randomness for generation
	 * @param verticalExpand -Flag for vertical expand mode
	 * @param horizontalExpand -Flag for horizontal expand mode
	 * @return 256bit mask
	 */
	function _generateMask_5x5(uint256 seed, uint8 verticalExpand, uint8 horizontalExpand) private pure returns (uint256){
		uint256 mask = 0x0000000000000000000000000000000000000000000000000000000000000000;
		uint256 line1 = _generateLine_5x5(seed, horizontalExpand);
		uint256 line2 = _generateLine_5x5(seed >> 3, horizontalExpand);
		uint256 line3 = _generateLine_5x5(seed >> 6, horizontalExpand);
		uint256 line4 = _generateLine_5x5(seed >> 9, horizontalExpand);
		uint256 line5 = _generateLine_5x5(seed >> 12, horizontalExpand);
		if(verticalExpand > 0) {
			mask = (line1 << 224) + (line2 << 192) + (line2 << 160) + (line3 << 128) + (line4 << 96) + (line4 << 64) + (line5 << 32) + (line5);
		} else {
			mask = (line1 << 224) + (line1 << 192) + (line2 << 160) + (line2 << 128) + (line3 << 96) + (line4 << 64) + (line4 << 32) + (line5);
		}
		return mask;
	}
	
	/**
	 * @dev Generates a single line for 5x5 mask
	 * @param seed -Randomness for generation
	 * @param horizontalExpand -Flag for horizontal expand mode
	 * @return 256bit mask line
	 */
	function _generateLine_5x5(uint256 seed, uint8 horizontalExpand) private pure returns (uint256){
		uint256 line = 0x00000000;
		if((seed & 0x00000001) == 0x00000001) line |= 0x000ff000;
		if(horizontalExpand > 0) {
			if((seed & 0x00000002) == 0x00000002) line |= 0x0ff00ff0;
			if((seed & 0x00000004) == 0x00000004) line |= 0xf000000f;
		} else {
			if((seed & 0x00000002) == 0x00000002) line |= 0x00f00f00;
			if((seed & 0x00000004) == 0x00000004) line |= 0xff0000ff;
		}
		return line;
	}

	/**
	 * @dev Gets colors for generation
	 * @param seed -Randomness for generation
	 * @return 256bit color templates
	 */
	function _getColors(uint256 seed) private pure returns (uint256, uint256, uint256){
		uint256 color1 = 0x0000000000000000000000000000000000000000000000000000000000000000;
		uint256 color2 = 0x0000000000000000000000000000000000000000000000000000000000000000;
		uint256 color3 = 0x0000000000000000000000000000000000000000000000000000000000000000;

		uint256 colorNum = seed & 0x000000ff;
		if(colorNum < 0x00000080) {
			if(colorNum < 0x00000055) {
				if(colorNum < 0x0000002B) color3 = 0x7777777777777777777777777777777777777777777777777777777777777777;
				else color3 = 0x8888888888888888888888888888888888888888888888888888888888888888;
			} else {
				color3 = 0x9999999999999999999999999999999999999999999999999999999999999999;
			}
		} else {
			if(colorNum < 0x000000D5) {
				if(colorNum < 0x000000AB) color3 = 0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
				else color3 = 0xbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb;
			} else {
				color3 = 0xcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc;
			}
		}

		if((seed & 0x00000100) == 0x00000100) color1 = 0x1111111111111111111111111111111111111111111111111111111111111111;
		else color1 = 0x5555555555555555555555555555555555555555555555555555555555555555;

		if((seed & 0x00000200) == 0x00000200) color2 = 0x6666666666666666666666666666666666666666666666666666666666666666;
		else color2 = 0xdddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;

		return (color1, color2, color3);
	}
}