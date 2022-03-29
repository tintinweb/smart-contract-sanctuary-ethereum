/**
 *Submitted for verification at Etherscan.io on 2022-03-29
*/

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;
// pragma solidity >=0.4.22 <0.9.0;

// import "./utils/introspection/IERC165.sol";
// import "./ERC721/IERC721Receiver.sol";
// import "./ERC721/IERC721Metadata.sol";
// import "./utils/access/Ownable.sol";
// import "./utils/Address.sol";
// import "./utils/Strings.sol";
// import "./utils/introspection/ERC165.sol";
// import "./utils/Base58.sol";





interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}



abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
      
       if(interfaceId == type(IERC165).interfaceId){}
       return true;
       		// return interfaceId == type(IERC721).interfaceId || interfaceId == type(IERC721Metadata).interfaceId;
      //  return true;
    }
}


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
    
    function createrOf(uint256 tokenId) external view returns (address);

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;



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
    function transferFrom(address from, address to, uint256 tokenId) external;

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

    // function baseTokenURI() external  ;
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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

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
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}
interface IERC721Metadata is IERC721 {

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

}

library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";

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
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

}

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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


library Base58 {
  bytes constant prefix1 = hex"0a";
  bytes constant prefix2 = hex"080212";
  bytes constant postfix = hex"18";
  bytes constant sha256MultiHash = hex"1220";
  bytes constant ALPHABET = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';

  /* /// @dev generates the corresponding IPFS hash (in base 58) to the given string
  /// @param contentString The content of the IPFS object
  /// @return The IPFS hash in base 58
  function generateHash(string memory contentString) internal pure returns (bytes memory) {
    bytes memory content = bytes(contentString);
    bytes memory len = lengthEncode(content.length);
    bytes memory len2 = lengthEncode(content.length + 4 + 2*len.length);
    return toBase58(concat(sha256MultiHash, toBytes(sha256(abi.encodePacked(prefix1, len2, prefix2, len, content, postfix, len)))));
  }

  /// @dev Compares an IPFS hash with content
  function verifyHash(string memory contentString, string memory hash) internal pure returns (bool) {
    return equal(generateHash(contentString), bytes(hash));
  } */
  
  /// @dev Converts hex string to base 58
  function toBase58(bytes memory source) internal pure returns (bytes memory) {
    //   function toBytes(uint256 x) returns (bytes b) {
    

    if (source.length == 0) return new bytes(0);
    uint8[] memory digits = new uint8[](64); //TODO: figure out exactly how much is needed
    digits[0] = 0;
    uint8 digitlength = 1;
    for (uint256 i = 0; i<source.length; ++i) {
      uint carry = uint8(source[i]);
      for (uint256 j = 0; j<digitlength; ++j) {
        carry += uint(digits[j]) * 256;
        digits[j] = uint8(carry % 58);
        carry = carry / 58;
      }
      
      while (carry > 0) {
        digits[digitlength] = uint8(carry % 58);
        digitlength++;
        carry = carry / 58;
      }
    }
    //return digits;
    return toAlphabet(reverse(truncate(digits, digitlength)));
  }

  /* function lengthEncode(uint256 length) internal pure returns (bytes memory) {
    if (length < 128) {
      return to_binary(length);
    }
    else {
      return concat(to_binary(length % 128 + 128), to_binary(length / 128));
    }
  } */

  /* function toBytes(bytes32 input) internal pure returns (bytes memory) {
    bytes memory output = new bytes(32);
    for (uint8 i = 0; i<32; i++) {
      output[i] = input[i];
    }
    return output;
  } */
    
  /* function equal(bytes memory one, bytes memory two) internal pure returns (bool) {
    if (!(one.length == two.length)) {
      return false;
    }
    for (uint256 i = 0; i<one.length; i++) {
      if (!(one[i] == two[i])) {
	return false;
      }
    }
    return true;
  } */

  function truncate(uint8[] memory array, uint8 length) internal pure returns (uint8[] memory) {
    uint8[] memory output = new uint8[](length);
    for (uint256 i = 0; i<length; i++) {
        output[i] = array[i];
    }
    return output;
  }
  
  function reverse(uint8[] memory input) internal pure returns (uint8[] memory) {
    uint8[] memory output = new uint8[](input.length);
    for (uint256 i = 0; i<input.length; i++) {
        output[i] = input[input.length-1-i];
    }
    return output;
  }
  
  function toAlphabet(uint8[] memory indices) internal pure returns (bytes memory) {
    bytes memory output = new bytes(indices.length);
    for (uint256 i = 0; i<indices.length; i++) {
        output[i] = ALPHABET[indices[i]];
    }
    return output;
  }

  /* function concat(bytes memory byteArray, bytes memory byteArray2) internal pure returns (bytes memory) {
    bytes memory returnArray = new bytes(byteArray.length + byteArray2.length);
    uint i = 0;
    for (i; i < byteArray.length; i++) {
      returnArray[i] = byteArray[i];
    }
    for (i; i < (byteArray.length + byteArray2.length); i++) {
      returnArray[i] = byteArray2[i - byteArray.length];
    }
    return returnArray;
  }
    
  function to_binary(uint256 x) internal pure returns (bytes memory) {
    if (x == 0) {
      return new bytes(0);
    }
    else {
      bytes1 s = bytes1(uint8(x % 256));
      bytes memory r = new bytes(1);
      r[0] = s;
      return concat(to_binary(x / 256), r);
    }
  } */
}

contract StoreFront is Ownable, ERC165, IERC721, IERC721Metadata{
	event Buy( address _owner, uint[] _tokens, uint _price );

	using Address for address;
	using Strings for uint;
	using Base58 for bytes;

	string public  _name;
	string public  _symbol;
	mapping(uint => address) private _owners;
	mapping(uint => address) public  creaters;
	mapping(address => uint) private _balances;
	mapping(uint => address) private _tokenApprovals;
	mapping(address => mapping(address => bool)) private _operatorApprovals;

	

	address public immutable signerAddress;
	uint public immutable totalSupply;
	uint public  maxPerWallet;
	uint public totalSales = 0;
	string private baseUri;
	

	constructor() Ownable() {
		signerAddress = 0xaFa52348CeD7B0dA15016096240f6Cd6AE51203c;
		baseUri = "https://ipfs.io/ipfs"; //"https://ipfs.io/ipfs";
		totalSupply = 1e3;
		maxPerWallet = 1;
		_name = "myNFT";
		_symbol = "TNFT";
    
    uint _tokenId = 0x9c2582bf7648dc75825a26758206b6610d7c989c6ac940285503d77e5ad27bdc;
    _owners[_tokenId] = msg.sender;
    creaters[_tokenId] = msg.sender;
		_balances[msg.sender] += 1;
    emit Transfer(address(0), msg.sender, _tokenId);
    
    // emit Transfer(address(0), msg.sender, _tokenId);
    
    // emit Transfer(address(0), msg.sender, _tokenId);
	}

	function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
  	// return interfaceId == type(IERC721).interfaceId || interfaceId == type(IERC721Metadata).interfaceId || super.supportsInterface(interfaceId);
       if(interfaceId == type(IERC165).interfaceId){}
       return true;
	}
    // function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
    //     return
    //         interfaceId == type(IERC721).interfaceId ||
    //         interfaceId == type(IERC721Metadata).interfaceId ||
    //         super.supportsInterface(interfaceId);
    // }  

	
	function balanceOf(address _owner) public view override returns (uint) {
		require( _owner != address(0), "ERC721: balance query for the zero address" );
		// if (_owner==owner()) return totalSupply - totalSales;
		return _balances[_owner];
	}

	function ownerOf(uint tokenId) public view override returns (address) {
		address _owner = _owners[tokenId];
		// if (_owner != address(0)) return _owner;
		require( _owner != address(0), "ERC721: creater query for nonexistent token" );
		return _owners[tokenId];
	}

	function createrOf(uint tokenId) public view override returns (address) {
		address creater = creaters[tokenId];
		require( creater != address(0), "ERC721: owner query for nonexistent token" );
		return creater;
	}

	function name() public view virtual override returns (string memory) {
		return _name;
	}

	function symbol() public view virtual override returns (string memory) {
		return _symbol;
	} 

	function approve(address to, uint tokenId) public override {
		address _owner = ownerOf(tokenId);
		require(to != _owner, "ERC721: approval to current owner");
		require( _msgSender() == _owner || isApprovedForAll(_owner, _msgSender()), "ERC721: approve caller is not owner nor approved for all" );
		_approve(to, tokenId);
	}

	function getApproved(uint tokenId) public view virtual override returns (address) {
		require( _exists(tokenId), "ERC721: approved query for nonexistent token" );
		return _tokenApprovals[tokenId];
	}

	function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
		return _operatorApprovals[owner][operator];
	}

	function setApprovalForAll(address operator, bool approved) public virtual override {
		require(operator != _msgSender(), "ERC721: approve to caller");
		_operatorApprovals[_msgSender()][operator] = approved;
		emit ApprovalForAll(_msgSender(), operator, approved);
	}

	function transferFrom( address from, address to, uint tokenId ) public virtual override {
		//solhint-disable-next-line max-line-length
		require( _isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved" );
		_transfer(from, to, tokenId);
	}
	
	function safeTransferFrom( address from, address to, uint tokenId ) public virtual override {
		safeTransferFrom(from, to, tokenId, "");
	}

	function safeTransferFrom( address from, address to, uint tokenId, bytes memory _data ) public virtual override {
		require( _isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved" );
		_safeTransfer(from, to, tokenId, _data);
	}


	function _safeTransfer( address from, address to, uint tokenId, bytes memory _data ) internal virtual {
		_transfer(from, to, tokenId);
		require( _checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer" );
	}

	function _exists(uint tokenId) internal view virtual returns (bool) {
		return _owners[tokenId] != address(0);
	}
   function mintTo(address _to) public onlyOwner {
        //  uint256 currentTokenId = _nextTokenId.current();
        // _nextTokenId.increment();
        // _safeMint(_to, currentTokenId);
  }

	function _isApprovedOrOwner(address spender, uint tokenId) internal view virtual returns (bool) {
		require( _exists(tokenId), "ERC721: operator query for nonexistent token" );
		address owner = ownerOf(tokenId);
		return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
	}
  function mint(address to) public virtual {
      // require(hasRole(MINTER_ROLE, _msgSender()), "ERC721PresetMinterPauserAutoId: must have minter role to mint");
      // We cannot just use balanceOf to create the new tokenId because tokens
      // can be burned (destroyed), so we need a separate counter.
      // _mint(to, owner());
      // _tokenIdTracker.increment();
      //  safeTransferFrom(owner(), to);
  }
	function pause() public virtual {
      // require(hasRole(PAUSER_ROLE, _msgSender()), "ERC721PresetMinterPauserAutoId: must have pauser role to pause");
      // _pause();
  }
   function reveal() public onlyOwner {
  //    revealed = true;
  }
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
    // baseURI = _newBaseURI;
  }


    function withdraw() public payable onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }
	function _pause() internal virtual {}
  function _unpause() internal virtual {}

    function _incrementTokenId() private {
        // _currentTokenId++;
    }
    
    function _getNextTokenId() private view returns (uint256) {
        // return _currentTokenId.add(1);
    }
    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC721Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() public virtual {
        // require(hasRole(PAUSER_ROLE, _msgSender()), "ERC721PresetMinterPauserAutoId: must have pauser role to unpause");
        // _unpause();
    }
    


  function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }


	function _mint(address to, uint tokenId) internal virtual {
		require(to != address(0), "ERC721: mint to the zero address");
		require(!_exists(tokenId), "ERC721: token already minted");

		_beforeTokenTransfer(address(0), to, tokenId);

		_balances[to] += 1;
		_owners[tokenId] = to;
		creaters[tokenId] = to;

		emit Transfer(address(0), to, tokenId);
	} 

 function _burn(uint tokenId) internal virtual {
		address owner = ownerOf(tokenId);

		_beforeTokenTransfer(owner, address(0), tokenId);
		_approve(address(0), tokenId);

		_balances[owner] -= 1;
		delete _owners[tokenId];

		emit Transfer(owner, address(0), tokenId);
	} 


	function _transfer( address from, address to, uint tokenId ) internal virtual {
		require( ownerOf(tokenId) == from, "ERC721: transfer of token that is not own" );
		require(to != address(0), "ERC721: transfer to the zero address");

		_beforeTokenTransfer(from, to, tokenId);

		// Clear approvals from the previous owner
		_approve(address(0), tokenId);

		_balances[from] -= 1;
		_balances[to] += 1;
		_owners[tokenId] = to;

		emit Transfer(from, to, tokenId);
	}

	function _approve(address to, uint tokenId) internal virtual {
		_tokenApprovals[tokenId] = to;
		emit Approval(ownerOf(tokenId), to, tokenId);
	}


	function _checkOnERC721Received( address from, address to, uint tokenId, bytes memory _data ) private returns (bool) {
		if (to.isContract()) {
			try
				IERC721Receiver(to).onERC721Received( _msgSender(), from, tokenId, _data ) returns (bytes4 retval) {
					return retval == IERC721Receiver(to).onERC721Received.selector;
				} catch (bytes memory reason) {
					if (reason.length == 0) {
						revert ("ERC721: transfer to non ERC721Receiver implementer");
					} else {
						assembly {
							revert(add(32, reason), mload(reason))
						}
					}
				}
		} else {
			return true;
		}
	}

	function _beforeTokenTransfer( address from, address to, uint tokenId ) internal virtual {}    




	function buy( uint[] memory _tokens, uint _price, bytes memory _signature) public payable {
		uint count = 0;
		require(msg.sender != address(0), "ERC721: mint to the zero address");
		require(verify(_tokens, _price, _signature), "invalid params");
		for (uint k=0; k<_tokens.length; k++) {
			uint _tokenId = _tokens[k];
			if (_owners[_tokenId] == address(0)) {
				_owners[_tokenId] = msg.sender;
				creaters[_tokenId] = msg.sender;
        safeTransferFrom( address(0), msg.sender,  _tokenId ) ;
				emit Transfer(address(0), msg.sender, _tokenId);
				count++;
			}
		}
		require(count + _balances[msg.sender] <= maxPerWallet, "your wallet reach out limit.");

		uint _amount = count * _price;
		require(msg.value>=_amount, "value is less than total amount");
		uint _remain = msg.value - _amount;
		if (_remain>0) {
			bool sent;
			bytes memory data;
			(sent, data) = msg.sender.call{value: _remain}("");
		}

		for(uint i = 0; i<count ; i++)
		    emit Transfer(address(0), msg.sender, i+totalSales);
		totalSales += count;
		_balances[msg.sender] += count;
		if(totalSales >= 888){
			maxPerWallet = 20;
		}
		emit Buy( msg.sender, _tokens, _price );
	}

	/* ------------- view ---------------*/

	function tokenURI(uint tokenId) external view returns (string memory) {
		bytes memory src = new bytes(32);
    	assembly { mstore(add(src, 32), tokenId) }
		bytes memory dst = new bytes(34);
		dst[0] = 0x12;
		dst[1] = 0x20;
		for(uint i=0; i<32; i++) {
			dst[i + 2] = src[i];
		} 
		return string(abi.encodePacked(baseUri, "/",  dst.toBase58()));
	}
  
  function baseTokenURI()  public pure returns (string memory) {
        return "https://creatures-api.opensea.io/api/creature/";
    }

    function contractURI() public pure returns (string memory) {
        return "https://creatures-api.opensea.io/contract/opensea-creatures";
    }
  function _baseURI() internal view   returns (string memory) {
    return baseUri;
  }
	function getMessageHash(uint[] memory _tokens, uint _price) public pure returns (bytes32) {
		 return keccak256(abi.encodePacked(_tokens, _price));
	}

	function verify(uint[] memory _tokens, uint _price, bytes memory _signature) public view returns (bool) {
		bytes32 messageHash = getMessageHash(_tokens, _price);
		bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
		return recoverSigner(ethSignedMessageHash, _signature) == signerAddress;
	}
	
	function getEthSignedMessageHash(bytes32 _messageHash) internal pure returns (bytes32) {
		return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
	}

	function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature) internal pure returns (address) {
		(bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
		return ecrecover(_ethSignedMessageHash, v, r, s);
	}
	
	function splitSignature(bytes memory sig) internal pure returns (bytes32 r,bytes32 s,uint8 v) {
		require(sig.length == 65, "invalid signature length");
				assembly {
			r := mload(add(sig, 32))
			s := mload(add(sig, 64))
			v := byte(0, mload(add(sig, 96)))
		}
	}
}