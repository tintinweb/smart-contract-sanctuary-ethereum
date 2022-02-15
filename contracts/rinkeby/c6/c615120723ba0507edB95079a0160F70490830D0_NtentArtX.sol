/**
 *Submitted for verification at Etherscan.io on 2022-02-15
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File contracts/libs/IERC165.sol

// File: openzeppelin-solidity/contracts/introspection/IERC165.sol
pragma solidity ^0.8.9;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * [EIP](https://eips.ethereum.org/EIPS/eip-165).
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others (`ERC165Checker`).
 *
 * For an implementation, see `ERC165`.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}


// File contracts/libs/ERC165.sol

// File: openzeppelin-solidity/contracts/introspection/ERC165.sol

pragma solidity ^0.8.9;


/**
 * @dev Implementation of the `IERC165` interface.
 *
 * Contracts may inherit from this and call `_registerInterface` to declare
 * their support of an interface.
 */
contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See `IERC165.supportsInterface`.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) override external virtual view returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See `IERC165.supportsInterface`.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}


// File contracts/libs/IERC721.sol

// File: openzeppelin-solidity/contracts/token/ERC721/IERC721.sol

pragma solidity ^0.8.9;


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
abstract contract IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of NFTs in `owner`'s account.
     */
    function balanceOf(address owner) public virtual view returns (uint256 balance);

    /**
     * @dev Returns the owner of the NFT specified by `tokenId`.
     */
    function ownerOf(uint256 tokenId) public virtual view returns (address owner);

    /**
     * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
     * another (`to`).
     *
     *
     *
     * Requirements:
     * - `from`, `to` cannot be zero.
     * - `tokenId` must be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this
     * NFT by either `approve` or `setApproveForAll`.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual;
    /**
     * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
     * another (`to`).
     *
     * Requirements:
     * - If the caller is not `from`, it must be approved to move this NFT by
     * either `approve` or `setApproveForAll`.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual;
    function approve(address to, uint256 tokenId) public virtual;
    function getApproved(uint256 tokenId) public virtual view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) public virtual;
    function isApprovedForAll(address owner, address operator) public virtual view returns (bool);


    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual;
}


// File contracts/libs/Address.sol

// File: openzeppelin-solidity/contracts/utils/Address.sol

pragma solidity ^0.8.9;

/**
 * @dev Collection of functions related to the address type,
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * > It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

pragma solidity ^0.8.9;
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    function concatenate(string memory a, string memory b) internal pure returns (string memory){
        return string(abi.encodePacked(a,b));
    } 

    /**
     * @dev converts string to integer
     */

    function str2int(string memory numString) internal pure returns(uint) {
        uint  val=0;
        bytes memory stringBytes = bytes(numString);
        for (uint  i =  0; i<stringBytes.length; i++) {
            uint exp = stringBytes.length - i;
            bytes1 ival = stringBytes[i];
            uint8 uval = uint8(ival);
            uint jval = uval - uint(0x30);
   
           val +=  (uint(jval) * (10**(exp-1))); 
        }
      return val;
    }

    /**
     * @dev get substring of string 
     */
    function substring(string memory str, uint startIndex, uint endIndex) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex-startIndex);
        for(uint i = startIndex; i < endIndex; i++) {
            result[i-startIndex] = strBytes[i];
        }
        return string(result);
    }

    /**
     * @dev gets string length
     */
    function stringLength(string memory str) pure internal returns (uint length)
    {
        uint i=0;
        bytes memory string_rep = bytes(str);

        while (i<string_rep.length)
        {
            if (string_rep[i]>>7==0)
                i+=1;
            else if (string_rep[i]>>5==bytes1(uint8(0x6)))
                i+=2;
            else if (string_rep[i]>>4==bytes1(uint8(0xE)))
                i+=3;
            else if (string_rep[i]>>3==bytes1(uint8(0x1E)))
                i+=4;
            else
                //For safety
                i+=1;

            length++;
        }
    }

    /**
     * @dev reverses string
     */
    function reverse(string memory _base) internal pure returns(string memory){
        bytes memory _baseBytes = bytes(_base);
        assert(_baseBytes.length > 0);

        string memory _tempValue = new string(_baseBytes.length);
        bytes memory _newValue = bytes(_tempValue);

        for(uint i=0;i<_baseBytes.length;i++){
            _newValue[ _baseBytes.length - i - 1] = _baseBytes[i];
        }

        return string(_newValue);
    }

}

pragma solidity ^0.8.9;
library Ints {
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
}


// File contracts/libs/Counters.sol

// File: openzeppelin-solidity/contracts/drafts/Counters.sol

pragma solidity ^0.8.9;



/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 * Since it is not possible to overflow a 256 bit integer with increments of one, `increment` can skip the SafeMath
 * overflow check, thereby saving gas. This does assume however correct usage, in that the underlying `_value` is never
 * directly accessed.
 */
library Counters {

    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value - 1;
    }
}


// File contracts/libs/IERC721Receiver.sol

// File: openzeppelin-solidity/contracts/token/ERC721/IERC721Receiver.sol

pragma solidity ^0.8.9;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
abstract contract IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data)
    public virtual returns (bytes4);
}

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata {
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


/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata and Enumerable extension. Built to optimize for lower gas during batch mints.
 *
 * Assumes serials are sequentially minted starting at 0 (e.g. 0, 1, 2, 3..).
 *
 * Does not support burning tokens to address(0).
 *
 * Assumes that an owner cannot have more than the 2**128 - 1 (max value of uint128) of supply
 */

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
error AttemptedTranserOfBurnedToken();
error StartTimeStampOfBurnedTokenNotFound();

pragma solidity ^0.8.9;

contract ERC721A is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Ints for uint256;

    struct TokenOwnership {
        address addr;
        uint64 startTimestamp;
    }

    struct AddressData {
        uint128 balance;
        uint128 numberMinted;
    }

    uint256 internal currentIndex;
    uint256[] internal burnedTokens;

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
    function totalSupply() public view returns (uint256) {
        return currentIndex - burnedTokens.length;
    }

    // /**
    //  * @dev See {IERC721Enumerable-tokenByIndex}.
    //  */
    // function tokenByIndex(uint256 index) public view override returns (uint256) {
    //     if (index >= (totalSupply() + burnedTokens.length)) revert TokenIndexOutOfBounds();
    //     return index;
    // }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     * This read function is O(totalSupply). If calling from a separate contract, be sure to test gas first.
     * It may also degrade with extremely large collection sizes (e.g >> 10000), test for your use case.
     */
    // function tokenOfOwnerByIndex(address owner, uint256 index) public view override returns (uint256) {
    //     if (index >= balanceOf(owner)) revert OwnerIndexOutOfBounds();
    //     uint256 numMintedSoFar = totalSupply();
    //     uint256 tokenIdsIdx;
    //     address currOwnershipAddr;

    //     // Counter overflow is impossible as the loop breaks when uint256 i is equal to another uint256 numMintedSoFar.
    //     unchecked {
    //         for (uint256 i; i < numMintedSoFar; i++) {
    //             TokenOwnership memory ownership = _ownerships[i];
    //             if (ownership.addr != address(0)) {
    //                 currOwnershipAddr = ownership.addr;
    //                 tokenIdsIdx = 0;
    //             }
    //             if (currOwnershipAddr == owner) {
    //                 if (tokenIdsIdx == index) {
    //                     return currOwnershipAddr.tokenId + tokenIdsIdx;
    //                 }
    //                 tokenIdsIdx++;
    //             }
    //         }
    //     }

    //     revert UnableGetTokenOwnerByIndex();
    // }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
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

    /**
     * Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around in the collection over time.
     */
    function ownershipOf(uint256 tokenId) internal view returns (TokenOwnership memory) {
        if (!_exists(tokenId)) revert OwnerQueryForNonexistentToken();

        if(isBurned(tokenId) == true)
            return TokenOwnership({addr : address(0), startTimestamp : 0});

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
     * @dev Added by @dotjiwa to track burned tokens.
     */
    function isBurned(uint256 tokenId) public view returns (bool) {
        for(uint256 i = 0; i < burnedTokens.length; i++){
            if(tokenId == burnedTokens[i])
                return true;
        }
        return false;
    }

    function getBurnedTokens() public view returns (uint256[] memory) {
        return burnedTokens;
    }

    /**
     * @dev Brought over from ERC721 by @dotjiwa.
     */

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
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

    function _burn(address owner, uint256 tokenId) internal {

        //update balance of owner
        _addressData[owner].balance--;

        //store burned token id which will update total supply
        burnedTokens.push(tokenId);

        unchecked {

            // If the ownership slot of tokenId+1 is not explicitly set, that means the transfer initiator owns it.
            // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
            uint256 nextTokenId = tokenId + 1;
            if (_ownerships[nextTokenId].addr == address(0)) {
                if (_exists(nextTokenId)) {
                    uint64 startTimestamp; 
                    for (uint256 curr = tokenId; curr >= 0; curr--) {
                        TokenOwnership memory ownership = _ownerships[curr];
                        if (ownership.addr != address(0)) {
                            startTimestamp = ownership.startTimestamp;
                            break;
                        }
                    }

                    if(startTimestamp == 0)
                        revert StartTimeStampOfBurnedTokenNotFound();

                    _ownerships[nextTokenId].addr = owner;
                    _ownerships[nextTokenId].startTimestamp = startTimestamp;
                }
            }
        }

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

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     */
    function _exists(uint256 tokenId) internal virtual view returns (bool) {
        return tokenId < currentIndex;
    }

    function _safeMint(address to, uint256 startTokenId, uint256 quantity) internal {
        _safeMint(to, startTokenId, quantity, '');
    }

    /**
     * @dev Safely mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(
        address to,
        uint256 startTokenId,
        uint256 quantity,
        bytes memory _data
    ) internal {
        _mint(to, startTokenId, quantity, _data, true);
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
    function _mint(
        address to,
        uint256 startTokenId,
        uint256 quantity,
        bytes memory _data,
        bool safe
    ) internal {
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

            currentIndex = currentIndex + quantity;
        }

        _afterTokenTransfers(address(0), to, startTokenId, quantity);
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
    ) internal {
        TokenOwnership memory prevOwnership = ownershipOf(tokenId);

        bool isApprovedOrOwner = (_msgSender() == prevOwnership.addr ||
            getApproved(tokenId) == _msgSender() ||
            isApprovedForAll(prevOwnership.addr, _msgSender()));

        if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
        if (prevOwnership.addr != from) revert TransferFromIncorrectOwner(); //also catches burned tokens
        if (to == address(0)) revert TransferToZeroAddress();

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, prevOwnership.addr);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
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
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
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

    /**
     * @dev Hook that is called before a set of serially-ordered token ids are about to be transferred. This includes minting.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
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
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     */
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}
}


pragma solidity ^0.8.9;

interface NtentTokenUri {
   function tokenUri(uint256 _tokenId) external view returns(string memory);
}

interface NtentTransfer {
   function transfer(address _from, address _to, uint256 _tokenId) external view returns(string memory);
}

contract NtentArtX is ERC721A {
    using Ints for uint256;
    using Strings for string;

    event Mint(
        uint256 indexed _startTokenId,
        uint256 indexed _endTokenId,
        uint256 indexed _projectId
    );

    event TokenBurned(
        address indexed _tokenOwner, 
        uint indexed _tokenId);

    struct Project {
        string name;
        string artist;
        string description;
        string website;
        string license;
        address purchaseContract;
        address dataContract;
        address tokenUriContract;
        address transferContract;
        bool acceptsMintPass;
        uint256 mintPassProjectId;
        bool dynamic;
        string projectBaseURI;
        string projectBaseIpfsURI;
        uint256 invocations;
        uint256 maxInvocations;
        string scriptJSON;
        mapping(uint256 => string) scripts;
        uint scriptCount;
        string ipfsHash;
        bool useHashString;
        bool useIpfs;
        bool active;
        bool locked;
        bool paused;
    }

    uint256 constant ONE_MILLION = 1_000_000;
    mapping(uint256 => Project) projects;

    //All financial functions are stripped from struct for visibility
    mapping(uint256 => address) public projectIdToArtistAddress;
    mapping(uint256 => uint256) public projectIdToPricePerTokenInWei;

    address public ntentAddress;
    uint256 public ntentPercentage = 10;

    mapping(uint256 => string) public staticIpfsImageLink;
    // mapping(uint256 => uint256) public tokenIdToProjectId;
    // mapping(uint256 => uint256[]) internal projectIdToTokenIds;

    address public admin;
    mapping(address => bool) public isRainbowlisted;
    mapping(address => bool) public isMintRainbowlisted;

    uint256 public nextProjectId = 1;

    uint256 private _royaltyBps;
    address payable private _royaltyRecipient;
    bytes4 private constant _INTERFACE_ID_ROYALTIES_CREATORCORE = 0xbb3bafd6;
    bytes4 private constant _INTERFACE_ID_ROYALTIES_EIP2981 = 0x2a55205a;
    bytes4 private constant _INTERFACE_ID_ROYALTIES_RARIBLE = 0xb7799584;


    modifier onlyValidTokenId(uint256 _tokenId) {
        require(_exists(_tokenId), "Token ID not exists");
        _;
    }

    modifier onlyUnlocked(uint256 _projectId) {
        require(!projects[_projectId].locked, "Only if unlocked");
        _;
    }

    modifier onlyArtist(uint256 _projectId) {
        require(msg.sender == projectIdToArtistAddress[_projectId], "Only artist");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin");
        _;
    }

    modifier onlyRainbowlisted() {
        require(isRainbowlisted[msg.sender], "Only Rainbowlisted");
        _;
    }

    modifier onlyArtistOrRainbowlisted(uint256 _projectId) {
        require(isRainbowlisted[msg.sender] || msg.sender == projectIdToArtistAddress[_projectId], "Only artist or Rainbowlisted");
        _;
    }
    constructor(string memory _tokenName, string memory _tokenSymbol) ERC721A(_tokenName, _tokenSymbol) {
        admin = msg.sender;
        isRainbowlisted[msg.sender] = true;
        ntentAddress = msg.sender;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A) returns (bool) {
        return interfaceId == type(IERC721).interfaceId || ERC721A.supportsInterface(interfaceId) ||
            interfaceId == type(IERC721Metadata).interfaceId || interfaceId == _INTERFACE_ID_ROYALTIES_CREATORCORE || 
            interfaceId == _INTERFACE_ID_ROYALTIES_EIP2981 || interfaceId == _INTERFACE_ID_ROYALTIES_RARIBLE;
    }

    function _exists(uint256 tokenId) internal override view returns (bool) {
        uint256 projectId = tokenIdToProjectId(tokenId);
        return 
        (tokenId < ((projectId * ONE_MILLION) + projects[projectId].invocations)) && 
        (tokenId >= (projectId * ONE_MILLION));
    }

    function mint(address _to, uint256 _projectId, uint256 quantity, address _by) external returns (uint256 _tokenId) {
        require(isMintRainbowlisted[msg.sender], "Must mint from Rainbowlisted minter");
        require(projects[_projectId].invocations + quantity <= projects[_projectId].maxInvocations, "Exceeds max invocations");
        require(projects[_projectId].active || _by == projectIdToArtistAddress[_projectId], "Proj must exist and be active");
        require(!projects[_projectId].paused || _by == projectIdToArtistAddress[_projectId], "Purchases are paused");

        uint256 tokenId = _mintTokens(_to, _projectId, quantity);

        return tokenId;
    }

    function _mintTokens(address _to, uint256 _projectId, uint256 quantity) internal returns (uint256 _tokenId) {

        uint256 nextStartTokenId = (_projectId * ONE_MILLION) + projects[_projectId].invocations;

        projects[_projectId].invocations = projects[_projectId].invocations + quantity;

        _safeMint(_to, nextStartTokenId, quantity);

        // tokenIdToProjectId(tokenIdToBe] = _projectId;
        // projectIdToTokenIds[_projectId].push(tokenIdToBe);

        emit Mint(nextStartTokenId, nextStartTokenId + quantity, _projectId);

        return nextStartTokenId;
    }
    
    function burn(address ownerAddress, uint256 tokenId) external returns(uint256 _tokenId) {
        require(isMintRainbowlisted[msg.sender], "Must burn from Rainbowlisted minter");
        _burn(ownerAddress, tokenId);
        emit TokenBurned(ownerAddress, tokenId);
        return tokenId;
    }
    
    function updateNtentAddress(address _ntentAddress) public onlyAdmin {
        ntentAddress = _ntentAddress;
    }

    function updateNtentPercentage(uint256 _ntentPercentage) public onlyAdmin {
        require(_ntentPercentage <= 50, "Max of 50%");
        ntentPercentage = _ntentPercentage;
    }

    function addRainbowlisted(address _address) public onlyAdmin {
        isRainbowlisted[_address] = true;
    }

    function removeRainbowlisted(address _address) public onlyAdmin {
        isRainbowlisted[_address] = false;
    }

    function addMintRainbowlisted(address _address) public onlyAdmin {
        isMintRainbowlisted[_address] = true;
    }

    function removeMintRainbowlisted(address _address) public onlyAdmin {
        isMintRainbowlisted[_address] = false;
    }
    
    function getPricePerTokenInWei(uint256 _projectId) public view returns (uint256 price) {
        return projectIdToPricePerTokenInWei[_projectId];
    }

    function toggleProjectIsLocked(uint256 _projectId) public onlyRainbowlisted onlyUnlocked(_projectId) {
        projects[_projectId].locked = true;
    }

    function toggleProjectIsActive(uint256 _projectId) public onlyRainbowlisted {
        projects[_projectId].active = !projects[_projectId].active;
    }

    function updateProjectArtistAddress(uint256 _projectId, address _artistAddress) public onlyArtistOrRainbowlisted(_projectId) {
        projectIdToArtistAddress[_projectId] = _artistAddress;
    }

    function toggleProjectIsPaused(uint256 _projectId) public onlyArtistOrRainbowlisted(_projectId) {
        projects[_projectId].paused = !projects[_projectId].paused;
    }

    function addProject(string memory _projectName, address _artistAddress, uint256 _pricePerTokenInWei, address _purchaseContract, bool _acceptsMintPass, uint256 _mintPassProjectId, bool _dynamic) public onlyRainbowlisted {

        uint256 projectId = nextProjectId;
        projectIdToArtistAddress[projectId] = _artistAddress;
        projects[projectId].name = _projectName;
        projects[projectId].purchaseContract = _purchaseContract;
        projects[projectId].acceptsMintPass = _acceptsMintPass;
        projects[projectId].mintPassProjectId = _mintPassProjectId;
        projectIdToPricePerTokenInWei[projectId] = _pricePerTokenInWei;
        projects[projectId].paused=true;
        projects[projectId].dynamic=_dynamic;
        projects[projectId].maxInvocations = ONE_MILLION;
        if (!_dynamic) {
            projects[projectId].useHashString = false;
        } else {
            projects[projectId].useHashString = true;
        }
        nextProjectId = nextProjectId + 1;
    }

    function updateProjectPricePerTokenInWei(uint256 _projectId, uint256 _pricePerTokenInWei) onlyArtist(_projectId) public {
        projectIdToPricePerTokenInWei[_projectId] = _pricePerTokenInWei;
    }

    function updateProjectName(uint256 _projectId, string memory _projectName) onlyUnlocked(_projectId) onlyArtistOrRainbowlisted(_projectId) public {
        projects[_projectId].name = _projectName;
    }

    function updateProjectArtistName(uint256 _projectId, string memory _projectArtistName) onlyUnlocked(_projectId) onlyArtistOrRainbowlisted(_projectId) public {
        projects[_projectId].artist = _projectArtistName;
    }
    
    function updateProjectPurchaseContractInfo(uint256 _projectId, address _projectPurchaseContract, bool _acceptsMintPass, uint256 _mintPassProjectId) onlyUnlocked(_projectId) onlyRainbowlisted public {
        projects[_projectId].purchaseContract = _projectPurchaseContract;
        projects[_projectId].acceptsMintPass = _acceptsMintPass;
        projects[_projectId].mintPassProjectId = _mintPassProjectId;
    }
    
    function updateProjectDataContractInfo(uint256 _projectId, address _projectDataContract) onlyUnlocked(_projectId) onlyRainbowlisted public {
        projects[_projectId].dataContract = _projectDataContract;
    }

    function updateTransferContractInfo(uint256 _projectId, address _projectTransferContract) onlyUnlocked(_projectId) onlyRainbowlisted public {
        projects[_projectId].transferContract = _projectTransferContract;
    }
    
    function updateProjectTokenUriContractInfo(uint256 _projectId, address _projectTokenUriContract) onlyUnlocked(_projectId) onlyRainbowlisted public {
        projects[_projectId].tokenUriContract = _projectTokenUriContract;
    }

    function updateProjectDescription(uint256 _projectId, string memory _projectDescription) onlyArtist(_projectId) public {
        projects[_projectId].description = _projectDescription;
    }

    function updateProjectWebsite(uint256 _projectId, string memory _projectWebsite) onlyArtist(_projectId) public {
        projects[_projectId].website = _projectWebsite;
    }

    function updateProjectLicense(uint256 _projectId, string memory _projectLicense) onlyUnlocked(_projectId) onlyArtistOrRainbowlisted(_projectId) public {
        projects[_projectId].license = _projectLicense;
    }

    function updateProjectMaxInvocations(uint256 _projectId, uint256 _maxInvocations) onlyArtist(_projectId) public {
        require((!projects[_projectId].locked || _maxInvocations<projects[_projectId].maxInvocations), "Only if unlocked");
        require(_maxInvocations > projects[_projectId].invocations, "Max invocations exceeds current");
        require(_maxInvocations <= ONE_MILLION, "Cannot exceed 1000000");
        projects[_projectId].maxInvocations = _maxInvocations;
    }

    function toggleProjectUseHashString(uint256 _projectId) onlyUnlocked(_projectId) onlyArtistOrRainbowlisted(_projectId) public {
      require(projects[_projectId].invocations == 0, "Cannot modify after token is minted.");
      projects[_projectId].useHashString = !projects[_projectId].useHashString;
    }

    function addProjectScript(uint256 _projectId, string memory _script) onlyUnlocked(_projectId) onlyArtistOrRainbowlisted(_projectId) public {
        projects[_projectId].scripts[projects[_projectId].scriptCount] = _script;
        projects[_projectId].scriptCount = projects[_projectId].scriptCount + 1;
    }

    function updateProjectScript(uint256 _projectId, uint256 _scriptId, string memory _script) onlyUnlocked(_projectId) onlyArtistOrRainbowlisted(_projectId) public {
        require(_scriptId < projects[_projectId].scriptCount, "scriptId out of range");
        projects[_projectId].scripts[_scriptId] = _script;
    }

    function removeProjectLastScript(uint256 _projectId) onlyUnlocked(_projectId) onlyArtistOrRainbowlisted(_projectId) public {
        require(projects[_projectId].scriptCount > 0, "there are no scripts to remove");
        delete projects[_projectId].scripts[projects[_projectId].scriptCount - 1];
        projects[_projectId].scriptCount = projects[_projectId].scriptCount + 1;
    }

    function updateProjectScriptJSON(uint256 _projectId, string memory _projectScriptJSON) onlyUnlocked(_projectId) onlyArtistOrRainbowlisted(_projectId) public {
        projects[_projectId].scriptJSON = _projectScriptJSON;
    }

    function updateProjectIpfsHash(uint256 _projectId, string memory _ipfsHash) onlyUnlocked(_projectId) onlyArtistOrRainbowlisted(_projectId) public {
        projects[_projectId].ipfsHash = _ipfsHash;
    }

    function updateProjectBaseURI(uint256 _projectId, string memory _newBaseURI) onlyArtist(_projectId) public {
        projects[_projectId].projectBaseURI = _newBaseURI;
    }

    function updateProjectBaseIpfsURI(uint256 _projectId, string memory _projectBaseIpfsURI) onlyArtist(_projectId) public {
        projects[_projectId].projectBaseIpfsURI = _projectBaseIpfsURI;
    }

    function toggleProjectUseIpfsForStatic(uint256 _projectId) onlyArtistOrRainbowlisted(_projectId) public {
        require(!projects[_projectId].dynamic, "can only set static IPFS hash for static projects");
        projects[_projectId].useIpfs = !projects[_projectId].useIpfs;
    }

    function toggleProjectIsDynamic(uint256 _projectId) onlyUnlocked(_projectId) onlyArtistOrRainbowlisted(_projectId) public {
      require(projects[_projectId].invocations == 0, "Can not switch after a token is minted.");
        if (projects[_projectId].dynamic) {
            projects[_projectId].useHashString = false;
        } else {
            projects[_projectId].useHashString = true;
        }
        projects[_projectId].dynamic = !projects[_projectId].dynamic;
    }

    function overrideTokenDynamicImageWithIpfsLink(uint256 _tokenId, string memory _ipfsHash) onlyArtistOrRainbowlisted(tokenIdToProjectId(_tokenId)) public {
        staticIpfsImageLink[_tokenId] = _ipfsHash;
    }

    function clearTokenIpfsImageUri(uint256 _tokenId) onlyArtistOrRainbowlisted(tokenIdToProjectId(_tokenId)) public {
        delete staticIpfsImageLink[tokenIdToProjectId(_tokenId)];
    }

    function projectDetails(uint256 _projectId) view public returns (string memory projectName, string memory artist, string memory description, string memory website, string memory license, bool dynamic) {
        projectName = projects[_projectId].name;
        artist = projects[_projectId].artist;
        description = projects[_projectId].description;
        website = projects[_projectId].website;
        license = projects[_projectId].license;
        dynamic = projects[_projectId].dynamic;
    }

    function projectTokenInfo(uint256 _projectId) view public returns (address artistAddress, uint256 pricePerTokenInWei, uint256 invocations, uint256 maxInvocations, bool active, address purchaseContract,  address dataContract, address tokenUriContract, address transferContract, uint256[] memory tokensBurned, bool acceptsMintPass, uint256 mintPassProjectId) {
        artistAddress = projectIdToArtistAddress[_projectId];
        pricePerTokenInWei = projectIdToPricePerTokenInWei[_projectId];
        invocations = projects[_projectId].invocations;
        maxInvocations = projects[_projectId].maxInvocations;
        active = projects[_projectId].active;
        purchaseContract = projects[_projectId].purchaseContract;
        dataContract = projects[_projectId].dataContract;
        tokenUriContract = projects[_projectId].tokenUriContract;
        transferContract = projects[_projectId].transferContract;
        tokensBurned = projectBurnedTokens(_projectId);
        acceptsMintPass = projects[_projectId].acceptsMintPass;
        mintPassProjectId = projects[_projectId].mintPassProjectId;
    }

    function projectBurnedTokens(uint256 _projectId) view public returns (uint256[] memory burnedTokenIds){
        uint256 burnedIndex = 0;
        for(uint256 i = 0; i < burnedTokens.length; i++){
            uint256 burnedTokenId = burnedTokens[i];
            if(tokenIdToProjectId(burnedTokenId) == _projectId){
                burnedTokenIds[burnedIndex] = burnedTokenId;
                burnedIndex++;
            }     
        }
    }

    function projectScriptInfo(uint256 _projectId) view public returns (string memory scriptJSON, uint256 scriptCount, bool useHashString, string memory ipfsHash, bool locked, bool paused) {
        scriptJSON = projects[_projectId].scriptJSON;
        scriptCount = projects[_projectId].scriptCount;
        useHashString = projects[_projectId].useHashString;
        ipfsHash = projects[_projectId].ipfsHash;
        locked = projects[_projectId].locked;
        paused = projects[_projectId].paused;
    }

    function projectScriptByIndex(uint256 _projectId, uint256 _index) view public returns (string memory){
        return projects[_projectId].scripts[_index];
    }

    function projectURIInfo(uint256 _projectId) view public returns (string memory projectBaseURI, string memory projectBaseIpfsURI, bool useIpfs) {
        projectBaseURI = projects[_projectId].projectBaseURI;
        projectBaseIpfsURI = projects[_projectId].projectBaseIpfsURI;
        useIpfs = projects[_projectId].useIpfs;
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) public override {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "ERC721: transfer caller is not owner nor approved");

        //check if custom transfer contract, if so, use that.
        if(projects[tokenIdToProjectId(_tokenId)].transferContract != address(0)){
            NtentTransfer ntentTransfer = NtentTransfer(projects[tokenIdToProjectId(_tokenId)].transferContract);
            ntentTransfer.transfer(_from, _to, _tokenId);
        }

        _transfer(_from, _to, _tokenId);
    }

    function bulkTransfer(address[] calldata _addressList, uint256[] calldata _tokenList) public onlyAdmin {
        uint addressLength = _addressList.length;
        uint tokenLength = _tokenList.length;
        require(addressLength > 0, "Address quantity must greater than zero");
        require(addressLength == tokenLength, "Token quantity must equal address quantity");

        for(uint256 i = 0; i < addressLength; i++){  
            address _toAddress = _addressList[i];
            uint256 _tokenId = _tokenList[i];
            safeTransferFrom(msg.sender, _toAddress, _tokenId);
        }
    }

    function projectShowAllTokens(uint256 _projectId) public view returns (uint256[] memory){
        return projectIdToTokenIds(_projectId);
    }

    function projectIdToTokenIds(uint256 _projectId) public view returns (uint256[] memory tokenIds){

        uint256 tId = 0;
        uint256 tokenId;
        uint256 projTokens = projects[_projectId].invocations;

        for(uint256 i = 0; i < projTokens; i++){  
            tokenId = (_projectId * ONE_MILLION) + i;
            if(isBurned(tokenId) == false){
                tokenIds[tId] = tokenId;
                tId++;
            }
        }
        return tokenIds;
    }

    //example input : 1000004
    function tokenIdToProjectId(uint256 _tokenId) public pure returns (uint256){

        //convert to string and reverse
        string memory reversed = _tokenId.toString().reverse();
        //chop off reversed project id from end, reverse back
        string memory strProjectId = reversed.substring(6, reversed.stringLength()).reverse();

        return strProjectId.str2int();
    }

    function tokensOfOwner(address owner) external view returns (uint256[] memory ownedTokenIds) {
        
        uint256 ownerBalance = balanceOf(owner);
        uint256 foundCount = 0;
        address currOwnershipAddr;

        // Counter overflow is impossible as the loop breaks when uint256 i is equal to another uint256 numMintedSoFar.
        unchecked {
            for (uint256 i = 1; i < nextProjectId; i++) {

                uint256[] memory projectTokens = projectIdToTokenIds(i);

                for (uint256 ii = 0; ii < projectTokens.length; ii++) {
                    uint256 tokenId = projectTokens[ii];

                    TokenOwnership memory ownership = _ownerships[tokenId];
                    if (ownership.addr != address(0)) {
                        currOwnershipAddr = ownership.addr;
                    }
                    if (currOwnershipAddr == owner) {
                        ownedTokenIds[foundCount] = tokenId;
                        foundCount++;
                    }
                    if(foundCount == ownerBalance){
                        return ownedTokenIds;
                    }   
                }
            }
        }

        revert UnableGetTokenOwnerByIndex();


    }

    function tokenURI(uint256 _tokenId) public override view onlyValidTokenId(_tokenId) returns (string memory) {

        //check if custom tokenUri contract, if so, use that.
        if(projects[tokenIdToProjectId(_tokenId)].tokenUriContract != address(0)){
            NtentTokenUri ntentTokenUri = NtentTokenUri(projects[tokenIdToProjectId(_tokenId)].tokenUriContract);
            return ntentTokenUri.tokenUri(_tokenId);
        }
        
        //check if tokenId has a specified image link
        if (bytes(staticIpfsImageLink[_tokenId]).length > 0) {
            return projects[tokenIdToProjectId(_tokenId)].projectBaseIpfsURI.concatenate(staticIpfsImageLink[_tokenId]);
        }

        //check if the project has a single overall token Uri (mintpass, etc)
        if (!projects[tokenIdToProjectId(_tokenId)].dynamic && projects[tokenIdToProjectId(_tokenId)].useIpfs) {
            return projects[tokenIdToProjectId(_tokenId)].projectBaseIpfsURI.concatenate(projects[tokenIdToProjectId(_tokenId)].ipfsHash);
        }

        return projects[tokenIdToProjectId(_tokenId)].projectBaseURI.concatenate(_tokenId.toString());
    }

    /**
     * ROYALTY FUNCTIONS
     */


    /**
     * @dev Update royalties
     */
    function updateRoyalties(address payable recipient, uint256 bps) external onlyRainbowlisted {
        _royaltyRecipient = recipient;
        _royaltyBps = bps;
    }

    function getRoyalties(uint256) external view returns (address payable[] memory recipients, uint256[] memory bps) {
        if (_royaltyRecipient != address(0x0)) {
            recipients = new address payable[](1);
            recipients[0] = _royaltyRecipient;
            bps = new uint256[](1);
            bps[0] = _royaltyBps;
        }
        return (recipients, bps);
    }

    function getFeeRecipients(uint256) external view returns (address payable[] memory recipients) {
        if (_royaltyRecipient != address(0x0)) {
            recipients = new address payable[](1);
            recipients[0] = _royaltyRecipient;
        }
        return recipients;
    }

    function getFeeBps(uint256) external view returns (uint[] memory bps) {
        if (_royaltyRecipient != address(0x0)) {
            bps = new uint256[](1);
            bps[0] = _royaltyBps;
        }
        return bps;
    }

    function royaltyInfo(uint256, uint256 value) external view returns (address, uint256) {
        return (_royaltyRecipient, value*_royaltyBps/10000);
    }
}