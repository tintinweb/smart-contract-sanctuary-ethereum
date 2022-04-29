/**
 *Submitted for verification at Etherscan.io on 2022-04-29
*/

pragma solidity ^0.8.0;  //SPDX-License-Identifier: UNLICENSED

library Counters {
    struct Counter {
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }    
    }

    function reset (Counter storage counter) internal {
        counter._value = 0;
    }
}

pragma solidity ^0.8.0;

library Strings {

    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";


    function toString(uint256 value) internal pure returns (string memory) {
        if(value == 0){
            return '0';
        }
        uint256 temp = value;
        uint256 digits;
        while(temp != 0){
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);

        while(value != 0){
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string (buffer);
    }

    function toHexString(uint256 value) internal pure returns (string memory) {
        if(value == 0){
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while(temp != 0){
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for(uint256 i = 2 * length + 1; i > 1; --i){
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "String hex length insufficient");
        return string(buffer);
    }
}

// CONTEXT 

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


// Address 
// returns TRUE if account is contract.
/* Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
*/

library Address {
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }
}


// Interface Receiver
pragma solidity ^0.8.0;


interface IERC721Receiver {
    /**
     * Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
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


// interface IERC165

pragma solidity ^0.8.0;

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}


pragma solidity ^0.8.0;

/**
 * Implementation of the {IERC165} interface.
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
    // IERC165-supportsInterface
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// interface IERC721

interface IERC721 is IERC165 {
    
    // Emitted when `tokenId` token is transferred from 'from' to 'to'.
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    //Emitted when 'owner' eables approved to manage the 'tokenId' toekn.
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    // Emitted when 'owner' enables or disables ('approved') 'operator' to manage all of its assets.
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    // Returns the number of tokens in 'owner's ' qaccount.
    function balanceOf(address owner) external view returns(uint256 balance);

    //returns owner of tokenid
    function ownerOf(uint256 tokennId) external view returns (address owner);

    /*Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
    * are aware of the ERC721 protocol to prevent tokens from being forever locked.
    *  
    * Requirements :
    *  - `from` cannot be the zero address.
    * - `to` cannot be the zero address.
    * - `tokenId` token must exist and be owned by `from`.
    * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
    * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
    *
    *  Emits a Transfer Event.
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
         uint256 tokenOId
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

pragma solidity ^0.8.0;

// Interface of MetaData ERC721

interface IERC721Metadata is IERC721 {
    // returns th etoken collection name.
    function name() external view returns (string memory);

    // returns the token collection symbol.
    function symbol() external view returns (string memory);

    // returns the unifirm resource indentifier (URI) for tokenID token.
    function tokenURI(uint256 tokenId) external view returns (string memory);
}


pragma solidity ^0.8.0;

contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {

    using Address for address;
    using Strings for uint256;
    //using Base64 for string;

    // Token name;
    string private _name;

    // Token symbol
    string private _symbol;

    string private _baseUri = "";

    // mapppings

    // mapping from tokenID to owner address.
    mapping(uint256 => address) private _owners;

    // mapping owner address to toekn  count.
    mapping(address => uint256) private _balances;

    // mapping from owner to operator approval.
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // mapping from tokenID to approved address.
    mapping(uint256 => address) private _tokenApprovals;

    // names of token to 
    mapping(string => bool) private tokenNames;

    // Initializes the contract by setting a name and symbol to the token collection.

    constructor(string memory name_, string memory symbol_){
        _name = name_;
        _symbol = symbol_;
    }

    // IERC165-supportInterface
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return 
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    // IERC721-balanceof
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    // IERC721-ownerOf
    function ownerOf(uint256 tokenId) public view virtual override returns(address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexisting token");
        return owner;
    }

    // IERC721Metadata-name
    function name() public view virtual override returns(string memory) {
        return _name;
    }

    // IERC721Metadata-symbol
    function symbol() public view virtual override returns(string memory) {
        return _symbol;
    }

    // IERC721Metadat-tokenURI
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return _baseUri;
    } 


    // IERC721-approve
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()), "ERC721: approve caller is not owner nor approved for all");

        _approve(to, tokenId);
    }

    // IERC721-getApproved
    function getApproved(uint256 tokenId) public view virtual override returns(address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    // IERC721-setApproveForAll
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    // IERC721-isApprovedForAll
    function isApprovedForAll(address owner, address operator) public view virtual override returns(bool) {
        return _operatorApprovals[owner][operator];
    }

    // IERC721-transferFrom
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    // IERC721-safeTransferFrom
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */

     function _safeTransfer(
         address from,
         address to,
         uint256 tokenId,
         bytes memory _data
     ) internal virtual {
         _transfer(from, to, tokenId);
         require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721:  transfer to non ERC721 Recevier implementer");
     }

    // returns wheather tokenID exiists .
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    // returns wheather the spender is approved ot manage tokenId
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");

        address owner = ERC721.ownerOf(tokenId);
        return(spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }


    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
     function _safeMint(address to, uint256 tokenId, string memory tokenName) internal virtual {
         _safeMint(to, tokenId, tokenName, "");
     }


     /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        string memory tokenName,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId, tokenName);
        require(_checkOnERC721Received(address(0), to, tokenId, _data),"ERC721: Transfer for non ERC721Receiver implementor");
    }


    //Mints 'tokenId' and transfer it to 'to.
    // try to use safeMint if possible.
    function _mint(
        address to, 
        uint256 tokenId, 
        string memory tokenName
        ) internal virtual {
        require(to != address(0), "ERC721 : Mint ot the zero address");
        require(!_exists(tokenId), "ERC721 : Token already exists");
        require(tokenNames[tokenName] == false, "Token name already exist !!!");

        _beforeTokenTransfer( address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to; 
        tokenNames[tokenName] = true;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    // Destory tokenId
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // clear approvans
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    // Transfers 'tokenId' from 'from' to 'to'.
    // as opposed to {transferFrom}, this imposes no restrictions on msg.sender.
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721 transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        //Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    // Approve 'To' to operate on 'TokenId'
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    // Approve 'operator' to operate on al  of 'owner' tokens
    // emits a {ApprovalForAll} event.
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
    */
    function _checkOnERC721Received (
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if(to.isContract()){
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if(reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
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

    function _beforeTokenTransfer(
        address from, 
        address to,
        uint256 tokenId
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

pragma solidity ^0.8.0;

abstract contract ERC721URIStorage is ERC721 {
    using Strings for uint256;

    mapping(uint256 => string) private _tokenURIs;

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory){
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        if(bytes(base).length == 0){
            return _tokenURI;
        }
        if(bytes(_tokenURI).length > 0) {
            return string (abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */

     function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
         require(_exists(tokenId), "ERC721URIStorage : URI set of nonexistent token");

         _tokenURIs[tokenId] = _tokenURI;
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
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}

pragma solidity ^0.8.0;

contract GameItems is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    constructor() ERC721("GameItem", "GITM"){}
    
    function awardItem(address player, string memory tokenURI, string memory tName)
        public
        returns (uint256)
    {
        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();
        _mint(player, newItemId, tName);
        _setTokenURI(newItemId, tokenURI);

        return newItemId;
    }
}