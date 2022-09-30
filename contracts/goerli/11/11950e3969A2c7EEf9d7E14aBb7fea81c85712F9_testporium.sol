// SPDX-License-Identifier: MIT
//
//     _,       
//   <(o )_,      __.-''-._
//    (  __)     <_' ____ _>-.-
//     ''          ''   ''
//
//   ~Duck-Lizard Productions~
// 

pragma solidity ^0.8.10;

import "./ERC1155_merkle.sol";

contract testporium is ERC1155Supply, Ownable {

	struct TokenDetails {
		uint16 tokenID;
		bool openMint;
		uint128 maxSupply;
		string tokenURI;
	}
	
	TokenDetails[] public tokenDetails;
	
	mapping( address => mapping( uint256 => uint16 )) public walletMints;
	
	address public manager;
	bytes32 public MerkleRoot;
	string public contractUri;
	
	constructor() ERC1155("") {}

	modifier requireManager() {
		if( msg.sender == manager || msg.sender == owner() ) {
			_;
		} else {
			revert("not manager or owner");
		}
	}

	modifier validProof(bytes32[] calldata	_proof, bytes calldata _maxAmountKey) {
		if( MerkleProof.verify(_proof, MerkleRoot, keccak256(abi.encodePacked(msg.sender, _maxAmountKey))) ) {
			_;
		} else {
			revert("invalid proof-key");
		}
		
	}


	// TOKEN FUNCTIONS

	function mintMerkle( 
		uint256 id, 
		uint16 amount, 
		bytes32[] calldata _proof, 
		bytes calldata _maxAmountKey ) 
	public validProof(_proof, _maxAmountKey) {
		require( id < tokenDetails.length, "doesn't exist");
		require( tokenDetails[id].openMint, "id not minting" );
		require( totalSupply(id) + amount <= tokenDetails[id].maxSupply, "exceeds supply" );
		
		uint alloc_int = UString.toUint16( _maxAmountKey, id*2 );
		
		require( amount + walletMints[msg.sender][id] <= alloc_int, "exceeds allocation" );
		
		walletMints[msg.sender][id] += uint16(amount);
		
		_mint( msg.sender, id, amount, "0x" );
		
	}
	
	function mintBatchMerkle( 
		uint256[] memory ids, 
		uint16[] memory amounts, 
		bytes32[] calldata _proof, 
		bytes calldata _maxAmountKey ) 
	public validProof(_proof, _maxAmountKey) {
		require( ids.length == amounts.length, "ERC1155: ids and amounts length mismatch" );
		
		uint256[] memory _amounts;
		uint alloc_int;
		uint ids_i;
		
		for( uint256 i = 0; i < ids.length; i++ ) {
			ids_i = ids[i];
			if( ids_i < tokenDetails.length ) {
				revert( string.concat(UString.uint2str(ids_i), " doesn't exist") );
			}
			if( tokenDetails[ids_i].openMint == false ) {
				revert( string.concat(UString.uint2str(ids_i), " mint closed") );
			}
            if( amounts[i] + totalSupply(ids_i) > tokenDetails[ids_i].maxSupply ) {
				revert( string.concat(UString.uint2str(ids_i), " amount exeeds supply") );
			}
			
			alloc_int = UString.toUint16( _maxAmountKey, i*2 );
			if( amounts[i] + walletMints[msg.sender][ids_i] > alloc_int ) {
				revert( string.concat(UString.uint2str(ids_i), " exceeds allocation") );
			}
			
			_amounts[i] = uint256(amounts[i]);
			
			walletMints[msg.sender][ids_i] += uint16(amounts[i]);
			
        }
		
		_mintBatch( msg.sender, ids, _amounts, "0x" );
		
	}
	
	
	// ****************************************************
	// TEST FUNCTIONS - DELETE FOR PRODUCTION
	
    function mint( uint256 id, uint256 amount ) public {
		require( tokenDetails[id].openMint, "id not minting" );
		require( totalSupply(id) + amount <= tokenDetails[id].maxSupply, "exceeds supply" );
		
		walletMints[msg.sender][id] += uint16(amount);
		
		_mint( msg.sender, id, amount, "0x" );
	}
	
	function mintBatch( uint256[] calldata ids, uint256[] calldata amounts ) public {
		require( ids.length == amounts.length, "ERC1155: ids and amounts length mismatch" );
		uint ids_i;
		for( uint256 i = 0; i < ids.length; i++ ) {
			ids_i = ids[i];
			if( tokenDetails[ids_i].openMint == false ) {
				revert( string.concat(UString.uint2str(ids_i), " mint closed") );
			}
            if( amounts[i] + totalSupply(ids_i) > tokenDetails[ids_i].maxSupply ) {
				revert( string.concat(UString.uint2str(ids_i), " amount exeeds supply") );
			}
			
			walletMints[msg.sender][ids_i] += uint16(amounts[i]);
			
        }

		_mintBatch( msg.sender, ids, amounts, "0x" );
		
	}
	
	// END TEST FUNCTIONS
	// ********************************************************
	
	
    function burn( address account, uint256 id, uint16 amount ) public {
		require( account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );
		_burn( account, id, amount );
	}
	
	
	// VIEW FUNCTIONS
	
	function uri(uint256 _tokenId) public view virtual override returns (string memory) {
        return tokenDetails[_tokenId].tokenURI;
    }
	
    function readContractUri() public view returns (string memory) {
        return contractUri;
    }
	
	function getHistory(address _owner) public view returns (uint16[] memory) {
		uint16[] memory _amounts = new uint16[](tokenDetails.length);
		for( uint i=0; i<tokenDetails.length; i++ ) {
			_amounts[i] = walletMints[_owner][i];
		}
        return _amounts;
    }
	
	// FALLBACK
	fallback() external payable { }
	receive() external payable { }

	// MANAGEMENT FUNCTIONS

	function setManager( address _manager ) public onlyOwner {
		manager = _manager;
	}
	
	function setMerkleRoot( bytes32 _merkle ) public requireManager {
		MerkleRoot = _merkle;
	}

	function createToken( bool _open, uint128 _supply, string calldata _tokenURI ) public requireManager {
		tokenDetails.push();
		uint _id = tokenDetails.length - 1;
		if( tokenDetails[_id].maxSupply > 0 ) {
			require( _supply >= totalSupply(_id), "cannot delete supply" );
			require( _supply <= tokenDetails[_id].maxSupply, "cannot increase supply" );
		}
		tokenDetails[_id].openMint = _open;
		tokenDetails[_id].maxSupply = _supply;
		tokenDetails[_id].tokenURI = _tokenURI;
	}
	
	function setToken_sale( uint _id, bool _open ) public requireManager {
		require( _id < tokenDetails.length, "id doesn't exist" );
		tokenDetails[_id].openMint = _open;
	}
	function setToken_URI( uint _id, string calldata _tokenURI ) public requireManager {
		require( _id < tokenDetails.length, "id doesn't exist" );
		tokenDetails[_id].tokenURI = _tokenURI;
	}
	function setToken_supply( uint _id, uint128 _supply ) public requireManager {
		require( _id < tokenDetails.length, "id doesn't exist" );
		if( tokenDetails[_id].maxSupply > 0 ) {
			require( _supply >= totalSupply(_id), "cannot delete supply" );
			require( _supply <= tokenDetails[_id].maxSupply, "cannot increase supply" );
		}
		tokenDetails[_id].maxSupply = _supply;
	}
	
	function teamMint( address to, uint256 id, uint256 amount ) public requireManager {
		require( tokenDetails[id].openMint, "id not minting" );
		_mint( to, id, amount, "0x" );
	}
	
		
	function setContractUri( string calldata _contractUri ) public requireManager {
        contractUri = _contractUri;
    }
	
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
		( bool success, ) = msg.sender.call{ value: balance }("");
        require( success, "Transfer failed." );
    }
	
	
}