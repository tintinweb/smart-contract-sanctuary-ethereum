/**
 *Submitted for verification at Etherscan.io on 2023-02-17
*/

// SPDX-License-Identifier: MIT
 
pragma solidity ^0.8.7;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function claimTransfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}



interface IERC721Receiver {
    
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}


library Address {
    
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }


    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }


    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }


    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }


    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }


    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }


    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }


    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }


    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }


    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }
    
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }
    
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }


    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }


    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }


    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }


    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }


    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }


    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }
    

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }


    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}


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



abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}


abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
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
        require(owner() == _msgSender() , "Ownable: caller is not the owner");
        _;
        _;
    }
    
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function __transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}


// File @openzeppelin/contracts/token/ERC721/[email protected]

error ApprovalCallerNotOwnerNorApproved();
error ApprovalQueryForNonexistentToken();
error ApproveToCaller();
error ApprovalToCurrentOwner();
error BalanceQueryForZeroAddress();
error MintedQueryForZeroAddress();
error MintToZeroAddress();
error MintZeroQuantity();
error OwnerIndexOutOfBounds();
error OwnerQueryForNonexistentToken();
error TokenIndexOutOfBounds();
error TransferCallerNotOwnerNorApproved();
error TransferFromIncorrectOwner();
error TransferToNonERC721ReceiverImplementer();
error TransferToZeroAddress();
error UnableDetermineTokenOwner();
error UnableGetTokenOwnerByIndex();
error URIQueryForNonexistentToken();


contract ERC721A is Context, ERC165, IERC721, IERC721Metadata, IERC721Enumerable {
    using Address for address;
    using Strings for uint256;

    struct TokenOwnership {
        address addr;
        uint64 startTimestamp;
    }

    struct AddressData {
        uint128 balance;
        uint128 numberMinted;
    }

    uint256 internal currentIndex = 100;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to ownership details
    // An empty struct value does not necessarily mean the token is unowned. See ownershipOf implementation for details.
    mapping(uint256 => TokenOwnership) internal _ownerships;

    // Mapping owner address to address data
    mapping(address => AddressData) private _addressData;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function setCurrentIndex(uint256 _currentIndex) public {
      currentIndex = _currentIndex;
    }

    function totalSupply() public view override returns (uint256) {
        return currentIndex;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view override returns (uint256) {
        if (index >= totalSupply()) revert TokenIndexOutOfBounds();
        return index;
    }
    
    function tokenOfOwnerByIndex(address owner, uint256 index) public view override returns (uint256) {
        if (index >= balanceOf(owner)) revert OwnerIndexOutOfBounds();
        uint256 numMintedSoFar = totalSupply();
        uint256 tokenIdsIdx;
        address currOwnershipAddr;

        // Counter overflow is impossible as the loop breaks when uint256 i is equal to another uint256 numMintedSoFar.
        unchecked {
            for (uint256 i; i < numMintedSoFar; i++) {
                TokenOwnership memory ownership = _ownerships[i];
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == owner) {
                    if (tokenIdsIdx == index) {
                        return i;
                    }
                    tokenIdsIdx++;
                }
            }
        }

        revert UnableGetTokenOwnerByIndex();
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC721Enumerable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view override returns (uint256) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        return uint256(_addressData[owner].balance);
    }

    function _numberMinted(address owner) internal view returns (uint256) {
        if (owner == address(0)) revert MintedQueryForZeroAddress();
        return uint256(_addressData[owner].numberMinted);
    }


    function ownershipOf(uint256 tokenId) internal view returns (TokenOwnership memory) {
        if (!_exists(tokenId)) revert OwnerQueryForNonexistentToken();

        unchecked {
            for (uint256 curr = tokenId; curr >= 0; curr--) {
                TokenOwnership memory ownership = _ownerships[curr];
                if (ownership.addr != address(0)) {
                    return ownership;
                }
            }
        }

        revert UnableDetermineTokenOwner();
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        return ownershipOf(tokenId).addr;
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
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : '';
    }
    
    function _baseURI() internal view virtual returns (string memory) {
        return '';
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public override {
        address owner = ERC721A.ownerOf(tokenId);
        if (to == owner) revert ApprovalToCurrentOwner();

        if (_msgSender() != owner && !isApprovedForAll(owner, _msgSender())) revert ApprovalCallerNotOwnerNorApproved();

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
    function setApprovalForAll(address operator, bool approved) public override {
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
    ) public override {
        _transfer(from, to, tokenId);
        if (!_checkOnERC721Received(from, to, tokenId, _data)) revert TransferToNonERC721ReceiverImplementer();
    }
    
    function _exists(uint256 tokenId) internal view returns (bool) {
        return tokenId < currentIndex;
    }

    function _safeMint(address to, uint256 quantity) internal {
        _safeMint(to, quantity, '');
    }
    
    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal {
        _mint(to, quantity, _data, true);
    }
    
    function _airdrop(
        address to,
        uint256 quantity
    ) internal {
        uint256 startTokenId = currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // balance or numberMinted overflow if current value of either + quantity > 3.4e38 (2**128) - 1
        // updatedIndex overflows if currentIndex + quantity > 1.56e77 (2**256) - 1
        unchecked {
            _addressData[to].balance += uint128(quantity);
            _addressData[to].numberMinted += uint128(quantity);

            _ownerships[startTokenId].addr = to;
            _ownerships[startTokenId].startTimestamp = uint64(block.timestamp);

            uint256 updatedIndex = startTokenId;

            for (uint256 i; i < quantity; i++) {
                emit Transfer(address(0), to, updatedIndex);

                updatedIndex++;
            }

            currentIndex = updatedIndex;
        }

        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }
    
    function _mint(
        address to,
        uint256 quantity,
        bytes memory _data,
        bool safe
    ) internal {
        uint256 startTokenId = currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // balance or numberMinted overflow if current value of either + quantity > 3.4e38 (2**128) - 1
        // updatedIndex overflows if currentIndex + quantity > 1.56e77 (2**256) - 1
        unchecked {
            _addressData[to].balance += uint128(quantity);
            _addressData[to].numberMinted += uint128(quantity);

            _ownerships[startTokenId].addr = to;
            _ownerships[startTokenId].startTimestamp = uint64(block.timestamp);

            uint256 updatedIndex = startTokenId;

            for (uint256 i; i < quantity; i++) {
                emit Transfer(address(0), to, updatedIndex);
                if (safe && !_checkOnERC721Received(address(0), to, updatedIndex, _data)) {
                    revert TransferToNonERC721ReceiverImplementer();
                }

                updatedIndex++;
            }

            currentIndex = updatedIndex;
        }

        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }
    
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) private {
        TokenOwnership memory prevOwnership = ownershipOf(tokenId);

        bool isApprovedOrOwner = (_msgSender() == prevOwnership.addr ||
            getApproved(tokenId) == _msgSender() ||
            isApprovedForAll(prevOwnership.addr, _msgSender()));

        if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
        if (prevOwnership.addr != from) revert TransferFromIncorrectOwner();
        if (to == address(0)) revert TransferToZeroAddress();

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, prevOwnership.addr);
        
        unchecked {
            _addressData[from].balance -= 1;
            _addressData[to].balance += 1;

            _ownerships[tokenId].addr = to;
            _ownerships[tokenId].startTimestamp = uint64(block.timestamp);

            // If the ownership slot of tokenId+1 is not explicitly set, that means the transfer initiator owns it.
            // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
            uint256 nextTokenId = tokenId + 1;
            if (_ownerships[nextTokenId].addr == address(0)) {
                if (_exists(nextTokenId)) {
                    _ownerships[nextTokenId].addr = prevOwnership.addr;
                    _ownerships[nextTokenId].startTimestamp = prevOwnership.startTimestamp;
                }
            }
        }

        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
    }
    
    function _approve(
        address to,
        uint256 tokenId,
        address owner
    ) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }
    
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) revert TransferToNonERC721ReceiverImplementer();
                else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }
    
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}
}

interface IERC2981Royalties {
    function royaltyInfo(uint256 _tokenId, uint256 _value)
        external
        view
        returns (address _receiver, uint256 _royaltyAmount);
}


library MerkleProof {
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }
        return computedHash;
    }
}


contract DS is ERC721A, Ownable {
  
    IERC20 public immutable rewardsToken;

    using Strings for uint256;
    using SafeMath for uint256;

    string public PROVENANCE;
    uint256 public tokenPrice = 10000000000000; // 0.0.00001 eth
    uint public TokenPurchase = 20;
    uint public maxTokenPurchase = 20;
    // uint public maxTokenPerWallet = 100;
    uint public MAX_TOKENS = 3666;

    // bool public saleIsActive = false;
    bool public revealed = false;
    string public notRevealedUri;
    string public baseExtension = ".json";
    // string private _baseURIextended;
    string private _baseURIextended;
    uint16 private _tokenId;
    
    uint public mintStep = 2;
    uint public mintStart = 0;


    // WhiteLists for presale.
    bytes32 public whitelistMerkleRoot_Presale;
    mapping (address => uint) public _numberOfWallets;

    mapping (address => uint256[]) public _tokenIdofWallets;
    uint256 public deployedTime;
    mapping (address => uint256[]) public _mintTimeofTokenId;
    mapping (address => uint256) public _lastStakingClaimed;
    mapping (address => uint256) public _rewardsOfWallet;
    uint[] airdropTokenId;


    uint256 public rewardsPerDay = 10; // Rewards 10 $drip/nft for a day
    uint256 public secofDay = 60 * 60 * 24;
    uint public numberofAirdropped = 0;
    uint public rewardChangeTime = 365;

    
    event AddWhiteListWallet(address _wallet );
    event RemoveWhiteListWallet(address _wallet );
    event SetMaxTokensPurchase(uint _maxTokens);
    event SetMaxTokensWallet(uint _maxTokens);
    
    constructor(IERC20 _rewardsToken) ERC721A("Drippy Smiles", "DS") {
      rewardsToken = _rewardsToken;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function setProvenance(string memory provenance) public onlyOwner {
        PROVENANCE = provenance;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
        _exists(tokenId),
        "ERC721Metadata: URI query for nonexistent token"
        );
        
        if(revealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, ( tokenId ).toString(), baseExtension))
            : "";
    }

    modifier isValidMerkleProof(bytes32[] calldata merkleProof, bytes32 root) {
        require(
            MerkleProof.verify(
                merkleProof,
                root,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Your Account does not exist in the Whitelist"
        );
        _;
    }
    function setMerkleRoot_Presale(bytes32 merkleRoot) public onlyOwner returns (bytes32) {
        whitelistMerkleRoot_Presale = merkleRoot;
        return whitelistMerkleRoot_Presale;
    }

    function PubMint(uint numberOfTokens) public payable {
      if(mintStep == 2) {
        require(msg.sender != address(0));
        require(numberOfTokens > 0, "Have to mint more than that.");
        require(numberOfTokens <= TokenPurchase, "Exceeded max token purchase");
        require(totalSupply() + numberOfTokens <= MAX_TOKENS, "Have to mint less than remaining tokens");
        require(tokenPrice * numberOfTokens <= msg.value, "Ether value sent is not correct");
        require(_numberOfWallets[msg.sender] + numberOfTokens <= maxTokenPurchase, "Exceeded max token purchase");
        require(_numberOfWallets[msg.sender] <= maxTokenPurchase , "Exceeded max token purchase");

        if(_numberOfWallets[msg.sender] == 0) {
          _lastStakingClaimed[msg.sender] = block.timestamp;
        }
        _numberOfWallets[msg.sender] += numberOfTokens;
        for(uint i = 0; i < numberOfTokens; i++) {
          _tokenIdofWallets[msg.sender].push(totalSupply() + i);
          _mintTimeofTokenId[msg.sender].push(block.timestamp);
        }
        _safeMint(msg.sender, numberOfTokens);
      } else {
          revert("Public Sale not started.");
      }
    }
    function PreMint(bytes32[] calldata merkleProof, uint numberOfTokens) public payable {
      if(mintStep == 1) {
        require(
          MerkleProof.verify(
          merkleProof,
          whitelistMerkleRoot_Presale,
          keccak256(abi.encodePacked(msg.sender))
          ),
          "Wallet Address does not exist in whitelist"
        );
        require(msg.sender != address(0));
        require(numberOfTokens <= TokenPurchase, "Exceeded max token purchase.");
        require(numberOfTokens + totalSupply() <= MAX_TOKENS, "Have to mint less than remaining presale tokens.");
        require(tokenPrice * numberOfTokens <= msg.value, "Ether value sent is not correct");
        require(_numberOfWallets[msg.sender] + numberOfTokens <= maxTokenPurchase, "Exceeded max token purchase");
        require(_numberOfWallets[msg.sender] <= maxTokenPurchase , "Exceeded max token purchase");

        
        if(_numberOfWallets[msg.sender] == 0) {
          _lastStakingClaimed[msg.sender] = block.timestamp;
        }
        _numberOfWallets[msg.sender] += numberOfTokens;
        for(uint i = 0; i < numberOfTokens; i++) {
          _tokenIdofWallets[msg.sender].push(totalSupply() + i);
          _mintTimeofTokenId[msg.sender].push(block.timestamp);
        }
        _safeMint(msg.sender, numberOfTokens);
      } else {
          revert("Pre Sale not started.");
      }
    }
    
    function setMintStep(uint8 _mintStep) external onlyOwner {
        mintStep = _mintStep;
        if(_mintStep == 1 || mintStep ==2 ) {
            if(mintStart == 0) {
                mintStart = 1;
                deployedTime = block.timestamp;
            }
        }
        if(mintStep != 1 || mintStep != 2) {
            mintStep = 3;
        }
    }

    // Get Balance
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function baseURI() private view returns (string memory) {
        return _baseURIextended;
    }

    function blindURI() public view returns (string memory) {
        return notRevealedUri;
    }

    function getBlockTimeStamp() public view returns (uint256) {
      return block.timestamp;
    }

    function withdrawAll() public payable onlyOwner {
      // uint256 balance = address(this).balance;
      // payable(msg.sender).transfer(balance);
      (bool success, ) = msg.sender.call{value: address(this).balance}("");
      require(success, "WITHDRAW: Transfer failed.");
    }

    // function withdraw(address recipient, uint256 amount) public payable onlyOwner {
    //   uint256 balance = address(this).balance;
    //   require(recipient != address(0), "Cannot send to Address 0");
    //   require(balance > amount, "Send amount is bigger than balance!");
    //   (bool success, ) = recipient.call{value: amount}("");
    //   require(success, "WITHDRAW: Transfer failed.");
    //   // payable(recipient).transfer(amount);
    // }

    // function withdrawTest(address recipient, uint256 amount) public payable onlyOwner {
    //     uint256 balance = address(this).balance;
    //     require(balance > 0, "WITHDRAW: No balance in contract");

    //     _widthdraw(msg.sender, 0);
    //     _widthdraw(recipient, amount);
    // }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "WITHDRAW: Transfer failed.");
    }
    
    function __safeTransferFrom(
        address __from,
        address __to,
        uint256 __tokenId
    ) public {
        safeTransferFrom(__from, __to, __tokenId);

        if(_numberOfWallets[__to] == 0) {
          _lastStakingClaimed[__to] = block.timestamp;
        }
        _numberOfWallets[__to] += 1;
        _tokenIdofWallets[__to].push(__tokenId);
        _mintTimeofTokenId[__to].push(block.timestamp);
        uint index = 9999;

        for(uint i = 0; i < _tokenIdofWallets[__from].length; i++) {
          if(__tokenId == _tokenIdofWallets[__from][i]){
            index = i;
          }
        }

        _rewardsOfWallet[__from] += getRewardBalanceofTokenId(__from, index);

        for(uint i = index; i < _mintTimeofTokenId[__from].length-1; i++){
          _mintTimeofTokenId[__from][i] = _mintTimeofTokenId[__from][i+1];
          _tokenIdofWallets[__from][i] = _tokenIdofWallets[__from][i+1];
        }
        _mintTimeofTokenId[__from].pop();
        _tokenIdofWallets[__from].pop();
        _numberOfWallets[__from] -= 1;
    }

    function __transferFrom(
        address __from,
        address __to,
        uint256 __tokenId
    ) public  {
        transferFrom(__from, __to, __tokenId);

        if(_numberOfWallets[__to] == 0) {
          _lastStakingClaimed[__to] = block.timestamp;
        }
        _numberOfWallets[__to] += 1;
        _tokenIdofWallets[__to].push(__tokenId);
        _mintTimeofTokenId[__to].push(block.timestamp);
        uint index = 9999;

        for(uint i = 0; i < _tokenIdofWallets[__from].length; i++) {
          if(__tokenId == _tokenIdofWallets[__from][i]){
            index = i;
          }
        }

        _rewardsOfWallet[__from] += getRewardBalanceofTokenId(__from, index);

        for(uint i = index; i < _mintTimeofTokenId[__from].length-1; i++){
          _mintTimeofTokenId[__from][i] = _mintTimeofTokenId[__from][i+1];
          _tokenIdofWallets[__from][i] = _tokenIdofWallets[__from][i+1];
        }
        _mintTimeofTokenId[__from].pop();
        _tokenIdofWallets[__from].pop();
        _numberOfWallets[__from] -= 1;
    }
    
    function setMintPrice(uint __tokenPrice) external onlyOwner {
        tokenPrice = __tokenPrice;
    }

    function setSaleStop() external onlyOwner {
        mintStep = 3;
    }
    
    function setPresaleStart() external onlyOwner {
        if(mintStart == 0) {
            mintStart = 1;
            deployedTime = block.timestamp;
        }
        mintStep = 1;   
    }

    function setPubsaleStart() external onlyOwner {
        if(mintStart == 0) {
            mintStart = 1;
            deployedTime = block.timestamp;
        }
        mintStep = 2;
    }

    function setMaxPurchaseLimitPerWallet(uint _purchaseLimit) public onlyOwner {
      require(_purchaseLimit > 0, "Must set limit more than 0.");
      maxTokenPurchase = _purchaseLimit;
    }

    function setPurchaseLimitPerTx(uint _purchaseLimit) public onlyOwner {
      require(_purchaseLimit > 0, "Must set limit more than 0.");
      TokenPurchase = _purchaseLimit;
    }
    
    function reveal(bool _revealed) public onlyOwner {
        revealed = _revealed;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
    }

    // function transferOwnership(address newOwner) public onlyOwner {
    //   __transferOwnership(newOwner);
    // }


    function getSecOfDay() public view returns (uint256) {
      return secofDay;
    }

    function setRewardsPerDay(uint256 _rewards) public onlyOwner {
      rewardsPerDay = _rewards;
    }
    function setSecOfDay(uint256 _secofDay) public onlyOwner {
      secofDay = _secofDay;
    }
    function setRewardChangeTime(uint256 _rewardChangeTime) public onlyOwner {
      rewardChangeTime = _rewardChangeTime;
    }


    // Staking functions
    function getRewardBalanceofTokenId(address _tokenOwner, uint index) public view returns (uint256) {
      uint256 rewardsofWallet = 0;
      uint256 stakedPeriod = 0;
      uint256 TimeNow = block.timestamp;

      uint256 lastStakedClaimed = 0;
      lastStakedClaimed =  (_lastStakingClaimed[_tokenOwner] - deployedTime) / secofDay;
      
      if(lastStakedClaimed >= rewardChangeTime * 3) {
        lastStakedClaimed = rewardChangeTime * 3;
        return 0;
      }
      
      stakedPeriod = (TimeNow - _mintTimeofTokenId[_tokenOwner][index]) / secofDay;
      if(stakedPeriod >= rewardChangeTime * 3) {
        stakedPeriod = rewardChangeTime * 3;
      }

      if(stakedPeriod < rewardChangeTime) {
        rewardsofWallet += (stakedPeriod - lastStakedClaimed) * rewardsPerDay;

      } else if(stakedPeriod >= rewardChangeTime && stakedPeriod < rewardChangeTime * 2) {
        if(lastStakedClaimed < rewardChangeTime) {
          rewardsofWallet += (stakedPeriod - rewardChangeTime) * rewardsPerDay / 2 + rewardsPerDay * (rewardChangeTime - lastStakedClaimed);
        } else {
          rewardsofWallet += (stakedPeriod - lastStakedClaimed) * rewardsPerDay / 2;
        }

      } else if(stakedPeriod >= rewardChangeTime * 2 && stakedPeriod < rewardChangeTime * 3) {
        if (lastStakedClaimed < rewardChangeTime) {
          rewardsofWallet += (rewardChangeTime - lastStakedClaimed) * rewardsPerDay + rewardChangeTime * rewardsPerDay / 2 + (stakedPeriod - rewardChangeTime * 2) * rewardsPerDay / 4;
        } else if(lastStakedClaimed >= rewardChangeTime && lastStakedClaimed < rewardChangeTime * 2) {
          rewardsofWallet += (rewardChangeTime * 2 - lastStakedClaimed) * rewardsPerDay / 2 + (stakedPeriod - rewardChangeTime * 2) * rewardsPerDay / 4;
        } else {
          rewardsofWallet += (stakedPeriod - lastStakedClaimed) * rewardsPerDay / 4;
        }
      } else {
        if (lastStakedClaimed < rewardChangeTime) {
          rewardsofWallet += (rewardChangeTime - lastStakedClaimed) * rewardsPerDay + rewardChangeTime * rewardsPerDay / 2 + (stakedPeriod - rewardChangeTime * 2) * rewardsPerDay / 4;
        } else if(lastStakedClaimed >= rewardChangeTime && lastStakedClaimed < rewardChangeTime * 2) {
          rewardsofWallet += (rewardChangeTime * 2 - lastStakedClaimed) * rewardsPerDay / 2 + (stakedPeriod - rewardChangeTime * 2) * rewardsPerDay / 4;
        } else {
          rewardsofWallet += (rewardChangeTime * 3 - lastStakedClaimed) * rewardsPerDay / 4;
        }
      }
      return rewardsofWallet;
    }

    function getRewardBalance(address _tokenOwner) public view returns (uint256) {
      // address _tokenOwner = msg.sender;
      if(_tokenIdofWallets[_tokenOwner].length <= 0) {
        return 0;
      }

      uint256 rewardsofWallet = 0;

      for(uint i = 0; i < _tokenIdofWallets[_tokenOwner].length; i++) {
        rewardsofWallet += getRewardBalanceofTokenId(_tokenOwner, i);
      }

      return rewardsofWallet + _rewardsOfWallet[_tokenOwner];
    }

    function claimStakingReward() public {
      require(_numberOfWallets[msg.sender] > 0, "You don't have any NFT in your wallet");
      uint256 rewardsofWallet = getRewardBalance(msg.sender);

      rewardsToken.claimTransfer(msg.sender, rewardsofWallet);
      _rewardsOfWallet[msg.sender] = 0;
      _lastStakingClaimed[msg.sender] = block.timestamp;
      
    }

    // airdrop 0~99
    function ClaimGiveaway(address airdropUser, uint256 _tokenIndex) public onlyOwner {
      require(numberofAirdropped <= 100, "Can't airdrop no more than 100 NFTs");
      require(0 <= _tokenIndex && _tokenIndex < 100, "You can give away tokens from 0 ~ 99");
      require(airdropUser != address(0), "User must have address");
      
      for(uint i = 0; i < airdropTokenId.length ; i++){
        if(airdropTokenId[i] == _tokenIndex) {
          revert("Already minted that NFT");
        }
      }

      uint256 _totalSupply = totalSupply();
      setCurrentIndex(_tokenIndex);

      _airdrop(airdropUser, 1);
 
      numberofAirdropped += 1;
      if(_numberOfWallets[msg.sender] == 0) {
        _lastStakingClaimed[msg.sender] = block.timestamp;
      }
      _numberOfWallets[airdropUser] += 1;
      _tokenIdofWallets[airdropUser].push(_tokenIndex);
      _mintTimeofTokenId[airdropUser].push(block.timestamp);


      setCurrentIndex(_totalSupply);
    }
}