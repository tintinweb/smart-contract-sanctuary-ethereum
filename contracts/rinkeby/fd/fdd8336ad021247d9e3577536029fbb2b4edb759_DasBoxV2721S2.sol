/**
 *Submitted for verification at Etherscan.io on 2022-08-05
*/

//SPDX-License-Identifier: MIT

pragma solidity =0.8.15;

// import {Owned} from "solmate/auth/Owned.sol";
// https://eips.ethereum.org/EIPS/eip-721, http://erc721.org/

/// @title ERC-721 Non-Fungible Token Standard
/// @dev See https://eips.ethereum.org/EIPS/eip-721
///  Note: the ERC-165 identifier for this interface is 0x80ac58cd.
/* is ERC165 */
interface IERC721 {
	/// @dev This emits when ownership of any NFT changes by any mechanism.
	///  This event emits when NFTs are created (`from` == 0) and destroyed
	///  (`to` == 0). Exception: during contract creation, any number of NFTs
	///  may be created and assigned without emitting Transfer. At the time of
	///  any transfer, the approved address for that NFT (if any) is reset to none.
	event Transfer(
		address indexed _from,
		address indexed _to,
		uint256 indexed _tokenId
	);

	/// @dev This emits when the approved address for an NFT is changed or
	///  reaffirmed. The zero address indicates there is no approved address.
	///  When a Transfer event emits, this also indicates that the approved
	///  address for that NFT (if any) is reset to none.
	event Approval(
		address indexed _owner,
		address indexed _approved,
		uint256 indexed _tokenId
	);

	/// @dev This emits when an operator is enabled or disabled for an owner.
	///  The operator can manage all NFTs of the owner.
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
	function safeTransferFrom(
		address _from,
		address _to,
		uint256 _tokenId,
		bytes memory data
	) external payable;

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
	) external payable;

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
	) external payable;

	/// @notice Change or reaffirm the approved address for an NFT
	/// @dev The zero address indicates there is no approved address.
	///  Throws unless `msg.sender` is the current NFT owner, or an authorized
	///  operator of the current owner.
	/// @param _approved The new approved NFT controller
	/// @param _tokenId The NFT to approve
	function approve(address _approved, uint256 _tokenId) external payable;

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
	function isApprovedForAll(address _owner, address _operator)
		external
		view
		returns (bool);
}

interface IERC165 {
	/// @notice Query if a contract implements an interface
	/// @param interfaceID The interface identifier, as specified in ERC-165
	/// @dev Interface identification is specified in ERC-165. This function
	///  uses less than 30,000 gas.
	/// @return `true` if the contract implements `interfaceID` and
	///  `interfaceID` is not 0xffffffff, `false` otherwise
	function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) internal _ownerOf;

    mapping(address => uint256) internal _balanceOf;

    function ownerOf(uint256 id) public view virtual returns (address owner) {
        require((owner = _ownerOf[id]) != address(0), "NOT_MINTED");
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "ZERO_ADDRESS");

        return _balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = _ownerOf[id];

        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        require(from == _ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[id],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[from]--;

            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(_ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = _ownerOf[id];

        require(owner != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            _balanceOf[owner]--;
        }

        delete _ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

/// @notice Read and write to persistent storage at a fraction of the cost.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SSTORE2.sol)
/// @author Modified from 0xSequence (https://github.com/0xSequence/sstore2/blob/master/contracts/SSTORE2.sol)
library SSTORE2 {
    uint256 internal constant DATA_OFFSET = 1; // We skip the first byte as it's a STOP opcode to ensure the contract can't be called.

    /*//////////////////////////////////////////////////////////////
                               WRITE LOGIC
    //////////////////////////////////////////////////////////////*/

    function write(bytes memory data) internal returns (address pointer) {
        // Prefix the bytecode with a STOP opcode to ensure it cannot be called.
        bytes memory runtimeCode = abi.encodePacked(hex"00", data);

        bytes memory creationCode = abi.encodePacked(
            //---------------------------------------------------------------------------------------------------------------//
            // Opcode  | Opcode + Arguments  | Description  | Stack View                                                     //
            //---------------------------------------------------------------------------------------------------------------//
            // 0x60    |  0x600B             | PUSH1 11     | codeOffset                                                     //
            // 0x59    |  0x59               | MSIZE        | 0 codeOffset                                                   //
            // 0x81    |  0x81               | DUP2         | codeOffset 0 codeOffset                                        //
            // 0x38    |  0x38               | CODESIZE     | codeSize codeOffset 0 codeOffset                               //
            // 0x03    |  0x03               | SUB          | (codeSize - codeOffset) 0 codeOffset                           //
            // 0x80    |  0x80               | DUP          | (codeSize - codeOffset) (codeSize - codeOffset) 0 codeOffset   //
            // 0x92    |  0x92               | SWAP3        | codeOffset (codeSize - codeOffset) 0 (codeSize - codeOffset)   //
            // 0x59    |  0x59               | MSIZE        | 0 codeOffset (codeSize - codeOffset) 0 (codeSize - codeOffset) //
            // 0x39    |  0x39               | CODECOPY     | 0 (codeSize - codeOffset)                                      //
            // 0xf3    |  0xf3               | RETURN       |                                                                //
            //---------------------------------------------------------------------------------------------------------------//
            hex"60_0B_59_81_38_03_80_92_59_39_F3", // Returns all code in the contract except for the first 11 (0B in hex) bytes.
            runtimeCode // The bytecode we want the contract to have after deployment. Capped at 1 byte less than the code size limit.
        );

        assembly {
            // Deploy a new contract with the generated creation code.
            // We start 32 bytes into the code to avoid copying the byte length.
            pointer := create(0, add(creationCode, 32), mload(creationCode))
        }

        require(pointer != address(0), "DEPLOYMENT_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                               READ LOGIC
    //////////////////////////////////////////////////////////////*/

    function read(address pointer) internal view returns (bytes memory) {
        return readBytecode(pointer, DATA_OFFSET, pointer.code.length - DATA_OFFSET);
    }

    function read(address pointer, uint256 start) internal view returns (bytes memory) {
        start += DATA_OFFSET;

        return readBytecode(pointer, start, pointer.code.length - start);
    }

    function read(
        address pointer,
        uint256 start,
        uint256 end
    ) internal view returns (bytes memory) {
        start += DATA_OFFSET;
        end += DATA_OFFSET;

        require(pointer.code.length >= end, "OUT_OF_BOUNDS");

        return readBytecode(pointer, start, end - start);
    }

    /*//////////////////////////////////////////////////////////////
                          INTERNAL HELPER LOGIC
    //////////////////////////////////////////////////////////////*/

    function readBytecode(
        address pointer,
        uint256 start,
        uint256 size
    ) private view returns (bytes memory data) {
        assembly {
            // Get a pointer to some free memory.
            data := mload(0x40)

            // Update the free memory pointer to prevent overriding our data.
            // We use and(x, not(31)) as a cheaper equivalent to sub(x, mod(x, 32)).
            // Adding 31 to size and running the result through the logic above ensures
            // the memory pointer remains word-aligned, following the Solidity convention.
            mstore(0x40, add(data, and(add(add(size, 32), 31), not(31))))

            // Store the size of the data in the first 32 byte chunk of free memory.
            mstore(data, size)

            // Copy the code into memory right after the 32 bytes we used to store the size.
            extcodecopy(pointer, add(data, 32), start, size)
        }
    }
}

/// @title BoxAuthBasic
/// @author computerdata
/// @notice basic auth module
abstract contract BoxAuthBasic {
	error NotOwner();
	/*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
	event OwnerSet(address indexed _prev, address indexed _new);
	/*//////////////////////////////////////////////////////////////
                                  STATE
    //////////////////////////////////////////////////////////////*/
	address private _owner;

	/*//////////////////////////////////////////////////////////////
                                  WRITE
    //////////////////////////////////////////////////////////////*/

	modifier onlyOwner() {
		if (msg.sender != owner()) revert NotOwner();
		_;
	}

	constructor() {
		_setOwner(msg.sender);
	}

	function owner() public view virtual returns (address) {
		return _owner;
	}

	function setOwner(address _newOwner) public virtual onlyOwner {
		_setOwner(_newOwner);
	}

	function _setOwner(address _new) internal virtual {
		address prev = _owner;
		_owner = _new;
		emit OwnerSet(prev, _new);
	}
}

/**
 * @title DasBoxV2721S
 * @dev Box Prototype V2.7.21S2
 * @author COMPUTER DATA
 */
contract DasBoxV2721S2 is BoxAuthBasic {
	/*//////////////////////////////////////////////////////////////
                              STATE/STORAGE
    //////////////////////////////////////////////////////////////*/
	/**
	 * @dev Structure for holding a source
	 * @param address tokenContract The address of the token contract
	 * @param uint256 id The id of the token
	 */
	struct Source {
		address tokenContract;
		uint256 id;
	}

	uint256 public boxSize;
	bool public initialized;
	mapping(uint256 => address) private _box;
	mapping(address => uint256) private _boxOrder;
	mapping(bytes32 => bool) private _boxHashes;

	/*//////////////////////////////////////////////////////////////
								  EVENTS
	//////////////////////////////////////////////////////////////*/
	event SourceAdded(address indexed data1, uint256 indexed data2);
	event SourceRemoved(address indexed data1, uint256 indexed data2);
	event SourceReplaced(
		address indexed data1,
		uint256 indexed data2,
		uint256 indexed index
	);

	/*//////////////////////////////////////////////////////////////
                        CONSTRUCTOR / INITIALIZER
    //////////////////////////////////////////////////////////////*/
	constructor(address _owner) {
		// setOwner(_owner);
	}

	function initialize(address _owner) external {
		require(!initialized, "no");
		initialized = true;
		_setOwner(_owner);
	}

	/*//////////////////////////////////////////////////////////////
                             WRITES EXTERNAL
    //////////////////////////////////////////////////////////////*/

	/**
	 * @dev Adds a source to the box
	 * @param data1 address The address of the token contract
	 * @param data2 uint256 The id of the token
	 */
	function addSource(address data1, uint256 data2) external {
		require(
			_boxHashes[keccak256(abi.encodePacked(data1, data2))] == false,
			"exists"
		);
		_addSource(data1, data2);
		emit SourceAdded(data1, data2);
	}

	// should be made into flag
	function addSourceValidated(address data1, uint256 data2) external {
		require(
			_boxHashes[keccak256(abi.encodePacked(data1, data2))] == false,
			"exists"
		);
		require(validateContract(data1) == true, "!valid");
		_addSource(data1, data2);
		emit SourceAdded(data1, data2);
	}

	/**
	 * @dev Replaces a source in the box with a new source
	 * @param data1 address The address of the token contract
	 * @param data2 uint256 The id of the token
	 */
	function replaceSource(
		address data1,
		uint256 data2,
		uint256 index
	) external {
		require(
			_boxHashes[keccak256(abi.encodePacked(data1, data2))] == false,
			"exists"
		);
		_replaceSource(data1, data2, index);
		emit SourceAdded(data1, data2);
	}

	/**
	 * @dev Adds an array of sources to the box
	 * @param _inputSources Source[] The array of sources to add
	 * @notice this function bad
	 */
	function addMultiSource(Source[] calldata _inputSources) external {
		uint256 length = _inputSources.length;
		for (uint16 i; i < length; ++i) {
			_addSource(_inputSources[i]);
		}
	}

	/**
	 * @dev Removes a source from the box
	 * @param data1 address The address of the token contract
	 * @param data2 uint256 The id of the token
	 * @return bool Whether the source was removed
	 */
	function removeSource(address data1, uint256 data2)
		external
		returns (bool)
	{
		require(
			_boxHashes[keccak256(abi.encodePacked(data1, data2))] == true,
			"!exists"
		);
		return _removeSource(data1, data2);
	}

	/**
	 * @dev Removes an array of sources from the box
	 * @param _inputSources Source[] The array of sources to remove
	 * @return bool[] Whether the sources were removed
	 */
	function removeMultiSource(Source[] calldata _inputSources)
		external
		returns (bool[] memory)
	{
		uint256 length = _inputSources.length;
		bool[] memory success = new bool[](length);

		for (uint16 i = 0; i < length; i++) {
			require(
				_boxHashes[
					keccak256(
						abi.encodePacked(
							_inputSources[i].tokenContract,
							_inputSources[i].id
						)
					)
				] == true,
				"!exists"
			);
			success[i] = _removeSource(
				_inputSources[i].tokenContract,
				_inputSources[i].id
			);
		}
		return success;
	}

	function removeSourceAtIndex(uint256 index) external returns (bool) {
		return _removeSourceAtIndex(index);
	}

	/*//////////////////////////////////////////////////////////////
                             WRITES INTERNAL
    //////////////////////////////////////////////////////////////*/

	function _removeSourceAtIndex(uint256 _index) internal returns (bool) {
		(address data1, uint256 data2) = abi.decode(
			SSTORE2.read(_box[_index]),
			(address, uint256)
		);
		require(
			_boxHashes[keccak256(abi.encodePacked(data1, data2))] == true,
			"!exists"
		);
		delete _box[_index];
		unchecked {
			boxSize--;
		}
		delete _boxHashes[keccak256(abi.encodePacked(data1, data2))];
		emit SourceRemoved(data1, data2);
		return true;
	}

	/**
	 * @dev internal function to add a source to the box
	 * @param data1 address The address of the token contract
	 * @param data2 uint256 The id of the token
	 * @notice function increases box size. Data is stored as pointer address
	 */
	function _addSource(address data1, uint256 data2) internal {
		bytes32 tempBytes = keccak256(abi.encodePacked(data1, data2));
		_boxHashes[tempBytes] = true;

		address temp = SSTORE2.write(abi.encode(data1, data2));
		_box[boxSize] = temp;
		_boxOrder[temp] = boxSize;
		// locationAddresses[tempBytes] = temp;
		unchecked {
			boxSize++;
		}
	}

	function _addSource(Source calldata _source) internal {
		address tempSource = _source.tokenContract;
		uint256 tempId = _source.id;
		bytes32 tempBytes = keccak256(abi.encodePacked(tempSource, tempId));
		_boxHashes[tempBytes] = true;
		address location = SSTORE2.write(abi.encode(tempSource, tempId));
		_box[boxSize] = location;
		_boxOrder[location] = boxSize;
		unchecked {
			boxSize++;
		}
	}

	/**
	 * @dev internal function to replace a source in the box with a new source
	 * @param data1 address The address of the token contract
	 * @param data2 uint256 The id of the token
	 * @param index uint256 The index of the source to replace
	 */
	function _replaceSource(
		address data1,
		uint256 data2,
		uint256 index
	) internal {
		bytes32 tempBytes = keccak256(abi.encodePacked(data1, data2));
		_boxHashes[tempBytes] = true;

		address temp = SSTORE2.write(abi.encode(data1, data2));
		_box[index] = temp;
		_boxOrder[temp] = index; // locationAddresses[tempBytes] = temp;
	}

	/**
	 * @dev internal function to remove a source from the box
	 * @param data1 address The address of the token contract
	 * @param data2 uint256 The id of the token
	 * @return bool Whether the source was removed
	 */
	function _removeSource(address data1, uint256 data2)
		internal
		returns (bool)
	{
		unchecked {
			boxSize--;
		}
		_boxHashes[keccak256(abi.encodePacked(data1, data2))] = false;
		// think this works
		// address location = SSTORE2.read(abi.decode(data1, data2));
		address location = _encode(data1, data2);
		delete _box[_boxOrder[location]];
		return true;
	}

	/**
	 * @dev internal function to get the location of a source in the box
	 * @param data1 address The address of the token contract
	 * @param data2 uint256 The id of the token
	 * @return address The location of the source
	 */
	function _encode(address data1, uint256 data2) internal returns (address) {
		return SSTORE2.write(abi.encode(data1, data2));
	}

	/*//////////////////////////////////////////////////////////////
                              READ EXTERNAL
    //////////////////////////////////////////////////////////////*/

	function getSource(uint256 id) public view returns (Source memory) {
		(address data1, uint256 data2) = abi.decode(
			SSTORE2.read(_box[id]),
			(address, uint256)
		);
		return Source(data1, data2);
	}

	function getSourceURI(uint256 id) public view returns (string memory) {
		Source memory input = getSource(id);
		return _getSourceURI(input);
	}

	function getDirectory() external view returns (Source[] memory) {
		uint256 length = boxSize;
		Source[] memory temp = new Source[](length);
		for (uint256 i = 0; i < length; i++) {
			temp[i] = getSource(i);
		}
		return temp;
	}

	function getDirectoryURIs() external view returns (string[] memory) {
		uint256 length = boxSize;
		string[] memory temp = new string[](length);
		for (uint256 i = 0; i < length; i++) {
			temp[i] = getSourceURI(i);
		}
		return temp;
	}

	/*//////////////////////////////////////////////////////////////
                              READ INTERNAL
    //////////////////////////////////////////////////////////////*/
	// can be modularized for different token types
	function _getSourceURI(Source memory inputSource)
		internal
		view
		returns (string memory uri)
	{
		string memory temp = ERC721(inputSource.tokenContract).tokenURI(
			inputSource.id
		);
		return temp;
	}

	function validateContract(address _contract) internal view returns (bool) {
		// check interface
		ERC721 test = ERC721(_contract);
		// check on 721 and 2981 interfaces
		return
			test.supportsInterface(0x80ac58cd) &&
			test.supportsInterface(0x2a55205a);
	}

	function validateSource(Source calldata _source)
		internal
		view
		returns (bool)
	{
		return validateContract(_source.tokenContract);
	}

	function _decode(address pointer) internal view returns (address, uint256) {
		(address data1, uint256 data2) = abi.decode(
			SSTORE2.read(pointer),
			(address, uint256)
		);
		return (data1, data2);
	}

	function _decodeForURI(address pointer)
		internal
		view
		returns (string memory)
	{
		(address data1, uint256 data2) = abi.decode(
			SSTORE2.read(pointer),
			(address, uint256)
		);
		return ERC721(data1).tokenURI(data2);
	}

	function reset() external returns (bool) {
		uint256 length = boxSize;
		for (uint256 i = 0; i < length; i++) {
			delete _box[i];
		}
		boxSize = 0;
		return true;
	}
}