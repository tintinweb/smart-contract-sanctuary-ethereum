/**
 *Submitted for verification at Etherscan.io on 2022-06-30
*/

// SPDX-License-Identifier: MIT
// Made with love by Mai use 721Degen for whatever you want

pragma solidity ^0.8.12;

abstract contract ERC721TokenReceiver {
    function onERC721Received(address, address, uint256, bytes calldata) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

/**
 * Built to optimize for lower gas during mints and transfers to allow for the ultimate Degen lifestyle. 
 * Assumes tokens are sequentially minted starting at 0 (0, 1, 2, 3..., etc).
 *
 */
abstract contract ERC721Degen {

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    string private _name;
    string private _symbol;
    uint256 private _index;
    uint256 private b;

    mapping(uint256 => address) internal _ownerships;
    mapping(uint256 => address) internal _tokenApprovals;
    mapping(address => mapping(address => bool)) private  _operatorApprovals;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint` or `_safeMint`),
     */
    function _exists(uint256 tokenId) public view virtual returns (bool) {
        return tokenId < _index;
    }

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) public view virtual returns (address) {
        unchecked {
            if (tokenId < _index) {
                address ownership = _ownerships[tokenId];
                if (ownership != address(0)) {
                    return ownership;
                }
                    while (true) {
                        ownership = _ownerships[--tokenId];

                        if (ownership != address(0)) {
                            return ownership;
                        }
                         
                    }
                }
            }

        revert ();
    }

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 quantity) internal {
        require(to != address(0), "Address 0");
        require(quantity > 0, "Quantity 0");

        unchecked {
            uint256 updatedIndex = _index;
            uint256 endIndex = updatedIndex + quantity;
            _ownerships[updatedIndex] = to;

            do {
                emit Transfer(address(0), to, updatedIndex++);
            } while (updatedIndex < endIndex);

            _index = endIndex;
        }
    }

    /**
     * @dev See Below {ERC721Degen-_safeMint}.
     */
    function _safeMint(address to, uint256 quantity) internal {
        _safeMint(to, quantity, '');
    }

    /**
     * @dev Safely mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {onERC721Received}, which is called for each safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 quantity, bytes memory _data) internal {
        _mint(to, quantity);

        unchecked {
            if (to.code.length != 0) {
                uint256 endIndex = _index;
                uint256 updatedIndex = endIndex - quantity;
                do {
                    require(ERC721TokenReceiver(to).onERC721Received(_msgSender(), address(0), updatedIndex++, _data) ==
                            ERC721TokenReceiver.onERC721Received.selector, "Unsafe Destination");
                } while (updatedIndex < endIndex);
                if (_index != endIndex) revert();
            }
        }
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - `from` must not have tokens locked.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual {
        address currentOwner = ownerOf(tokenId);
        require((_msgSender() == currentOwner ||
            getApproved(tokenId) == _msgSender() ||
            isApprovedForAll(currentOwner,_msgSender())), "Not Approved");
        require(currentOwner == from, "Not Owner");
        require(to != address(0), "Address 0");

        delete _tokenApprovals[tokenId]; 
        unchecked {
            _ownerships[tokenId] = to;
            uint256 nextTokenId = tokenId + 1;
            if (_ownerships[nextTokenId] == address(0) && nextTokenId < _index) {
                _ownerships[nextTokenId] = currentOwner;
            }
        }

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev See Below {ERC721Degen-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual {
        safeTransferFrom(from, to, tokenId, '');
    }

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
     * - If `to` refers to a smart contract, it must implement {ERC721TokenReceiver}, which is called upon a safe transfer.
     * - `from` must not have tokens locked.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual {
        transferFrom(from, to, tokenId);
        require(to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(_msgSender(), address(0), tokenId, _data) ==
                ERC721TokenReceiver.onERC721Received.selector, "Unsafe Destination");
    }
    
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() public view returns (uint256) {
        unchecked {
            return _index;
        }
    }

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     * - Owner must not have tokens locked.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) public {
        require(operator != _msgSender(), "Address is Owner");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `_owner` and tokens are unlocked for `_owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address _owner, address operator) public view returns (bool) {
        return _operatorApprovals[_owner][operator];
    }

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
    function approve(address to, uint256 tokenId) public {
        address tokenOwner = ownerOf(tokenId);
        require(_msgSender() == tokenOwner || isApprovedForAll(tokenOwner, _msgSender()), "ERC721Degen: Not Approved");
        _tokenApprovals[tokenId] = to;
        emit Approval(tokenOwner, to, tokenId);
    }

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId), "ERC721Degen: Null ID");
        return _tokenApprovals[tokenId];
    }

    /**
     * @dev Returns the token collection name.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) public view virtual returns (string memory) {
        require(_exists(tokenId), "Non Existent");

        string memory _baseURI = baseURI();
        return bytes(_baseURI).length != 0 ? string(abi.encodePacked(_baseURI, _toString(tokenId))) : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function baseURI() public view virtual returns (string memory) {
        return '';
    }

    /**
     * @dev Returns token balance owned by `_owner`.
     */
    function balanceOf(address _owner) public view returns (uint256) {
        require(_owner != address(0), "Address 0");
        uint256 supply = _index;
        address currentOwner;
        address tokenOwner;
        
        uint256 totalOwned;

        unchecked {
            for (uint256 i; i < supply; ) {
                tokenOwner = _ownerships[i++];
                if (tokenOwner != address(0)) {
                    currentOwner = tokenOwner;
                }
                if (currentOwner == _owner) {
                    ++totalOwned;
                }
            }
        }

        return totalOwned;
    }

    /**
     * @dev Returns token balance owned by `_owner`.
     */
    function balanceOf2(address _owner) public view returns (uint256) {
        require(_owner != address(0), "Address 0");
        uint256 supply = _index;
        address currentOwner;
        address tokenOwner;

        uint256 totalOwned;
        uint256 currentIndex;

        unchecked {
            while (currentIndex < supply) {
                tokenOwner = _ownerships[currentIndex++];
                if (tokenOwner != address(0)) {
                    currentOwner = tokenOwner;
                }
                if (currentOwner == _owner) {
                    ++totalOwned;
                }
            }
        }

        return totalOwned;
    }

     /**
     * @dev Returns token balance owned by `_owner`.
     */
    function balanceOfCheck(address _owner) public  {
        require(_owner != address(0), "Address 0");
        uint256 supply = _index;
        address currentOwner;
        address tokenOwner;

        uint256 totalOwned;

        unchecked {
            for (uint256 i; i < supply; ) {
                tokenOwner = _ownerships[i++];
                if (tokenOwner != address(0)) {
                    currentOwner = tokenOwner;
                }
                if (currentOwner == _owner) {
                    ++totalOwned;
                }
            }
        }

        b =  totalOwned;
    }

     /**
     * @dev Returns token balance owned by `_owner`.
     */
    function balanceOfCheck2(address _owner) public  {
        require(_owner != address(0), "Address 0");
        uint256 supply = _index;
        address currentOwner;
        address tokenOwner;

        uint256 totalOwned;
        uint256 currentIndex;

        unchecked {
            while (currentIndex < supply) {
                tokenOwner = _ownerships[currentIndex++];
                if (tokenOwner != address(0)) {
                    currentOwner = tokenOwner;
                }
                if (currentOwner == _owner) {
                    ++totalOwned;
                }
            }
        }

        b =  totalOwned;
    }

    function supportsInterface(bytes4 interfaceId) public pure virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     * Credit to whatever crazy person rewrote toString into exclusively assembly for a view function
     */
    function _toString(uint256 value) internal pure returns (string memory ptr) {
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit),
            // but we allocate 128 bytes to keep the free memory pointer 32-byte word aliged.
            // We will need 1 32-byte word to store the length,
            // and 3 32-byte words to store a maximum of 78 digits. Total: 32 + 3 * 32 = 128.
            ptr := add(mload(0x40), 128)
            // Update the free memory pointer to allocate.
            mstore(0x40, ptr)

            // Cache the end of the memory to calculate the length later.
            let end := ptr

            // We write the string from the rightmost digit to the leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // Costs a bit more than early returning for the zero case,
            // but cheaper in terms of deployment and overall runtime costs.
            for {
                // Initialize and perform the first pass without check.
                let temp := value
                // Move the pointer 1 byte leftwards to point to an empty character slot.
                ptr := sub(ptr, 1)
                // Write the character to the pointer. 48 is the ASCII index of '0'.
                mstore8(ptr, add(48, mod(temp, 10)))
                temp := div(temp, 10)
            } temp {
                // Keep dividing `temp` until zero.
                temp := div(temp, 10)
            } {
                // Body of the for loop.
                ptr := sub(ptr, 1)
                mstore8(ptr, add(48, mod(temp, 10)))
            }

            let length := sub(end, ptr)
            // Move the pointer 32 bytes leftwards to make room for the length.
            ptr := sub(ptr, 32)
            // Store the length.
            mstore(ptr, length)
        }
    }

}

interface IRocketPass {
    function balanceOf(address _address, uint256 id) external view returns (uint256);
}


contract HASHDroid is ERC721Degen {

    string private _baseURI = "ipfs://QmUDPXkjLXNGhxfoS4ZcyXe7b9in6tccaf2982VjbU5SsV/";

    uint256 public publicMaxMint = 7;
    uint256 public priceDroid = .069 ether;
    uint256 public publicMinted;

    bool public depreciatedMint;
    bool public mintStatus;
    IRocketPass public rocketPass;

    mapping(address => uint256) public mintedRP;

  constructor() ERC721Degen("HASHDroid", "HD") {
  }

  modifier callerIsUser() {
    require(tx.origin == _msgSender(), "Contract Caller");
    _;
  }

  function rpMint(uint256 _quantity) public callerIsUser() {
    _mint(_msgSender(), _quantity);
  }

  function baseURI() public view override returns (string memory) {
    return _baseURI;
  }

  function verifyRP(address _address) external view returns (bool){
    return (rocketPass.balanceOf(_address, 1) - mintedRP[_address]) > 0;
  }

}