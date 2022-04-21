// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import { ERC721 } from "./ERC721.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

import { Base64 } from "./Base64.sol"; 
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";


/**
 *@title Glitter Bombs
 *@author @nftchance and @masonthechain
 *@dev Implementation of ERC-721 that utilizes EIP-2309 to explode Glitter 
 *     bombs into the wallets of the unsuspecting victims. Functional at the *     time of deployment on all major marketplaces. 
 */
contract Bomb is
      ERC721
    , Ownable
{
    using Strings for uint256;
    using Strings for int256;

    ///@notice is the mint open
    bool public mintOpen;

    ///@notice id of current token types being minted
    uint256 public shieldSupply;
    uint256 public bombSupply = MAX_SHIELDS;

    ///@notice the cost of each clean-up size increment
    uint256 public constant CLEAN_INCREMENTS_PRICE = 0.02 ether;

    ///@notice the size of clean-up steps
    uint256 public constant CLEAN_INCREMENTS = 100;

    ///@notice the cost of a shield -- what goes up, must come down
    uint256 public constant SHIELD_PRICE = 0.02 ether;

    ///@notice the colors that shrapnel can be
    string[] public COLORS;

    ///@notice the path of the bomb
    string[] outlinePaths;

    event ConsecutiveTransfer(
          uint256 indexed fromTokenId
        , uint256         toTokenId
        , address indexed fromAddress
        , address indexed toAddress
    );

    constructor(
          string memory _name
        , string memory _symbol
        , string[] memory _colors
        , string[] memory _outlinePaths
    ) ERC721(
          _name
        , _symbol
    ) { 
        COLORS = _colors;

        outlinePaths = _outlinePaths; 
    }

    ///@notice toggles the mint
    function toggleMint()
        public
        onlyOwner
    {
        mintOpen = !mintOpen;
    }

    ///@notice Generates the image for the token id
    function tokenImage(
        uint256 _tokenId
    )
        public
        view
        returns (
            string memory svgString
        )
    {
        require(_exists(_tokenId), "Bomb: image query for nonexistent token");

        ///@dev controls the pieces of confetti generated
        uint256 buffer;
        uint256 pieces = (uint256(
            keccak256(
                abi.encodePacked(
                      _tokenId
                    , block.timestamp
                )
            )
        ) % 45) + 35;
        if(bombToPieces[_tokenId] > 0) {
            buffer = 175;
            pieces = bombToPieces[_tokenId];
        }

        for(
            uint256 i;
            i < pieces;
            i++
        ) { 
            uint256 seed = uint256(
                keccak256(
                    abi.encodePacked(
                        _tokenId
                        , i
                    )
                )
            );

            ///@dev builds the piece of confetti
            svgString = string(
                abi.encodePacked(
                      svgString
                    , '<circle cx="'
                    , (buffer + (seed <<= 4) % (500 - buffer)).toString()
                    , '" cy="'
                    , (buffer + (seed <<= 5) % (500 - buffer)).toString()
                    , '" r="'
                    , (15 + (seed <<= 6) % 50).toString()
                    , '" fill="'
                    , COLORS[(seed <<= 1) % COLORS.length]
                    , '"/>'
                )
            );
        }

        ///@dev if the supplied token id is an unexploded bomb the glitter is contained
        if(
            _tokenId < MAX_BOMBS && 
            buffer == 0
        ) {
            svgString = string(
                abi.encodePacked(
                      svgString
                    , outlinePaths[_tokenId < MAX_SHIELDS ? 1 : 0]
                )
            );
        }

        svgString = string(
            abi.encodePacked(
                  '<svg id="glitter-bomb" xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 500 500" width="500" height="500">'
                  // adding the black background
                , '<rect x="0" y="0" width="500" height="500" fill="#000"/>'
                , svgString
                , '</svg>'
            )
        );
    }

    ///@dev See {IERC721Metadata-tokenURI}.
    function tokenURI(
        uint256 _tokenId
    )
        override
        public
        view
        returns (
            string memory metadataString
        )
    {
        require(
              _exists(_tokenId)
            , "ERC721Metadata: URI query for nonexistent token"
        );

        string memory descriptionString = "This Glitter shrapnel is part of a Glitter Bomb NFT that someone paid the gas to explode into your wallet. What'd you do to them??? Glitter is a pain to get cleaned up, but we can handle it.. For a price! No? Then consider buying a Glitter Shield 9000 next time.";

        if(_tokenId < ARMORY_CAPACITY)
            descriptionString = _tokenId < MAX_SHIELDS ? "Top of the line equipment. The Glitter Shield 9000 is the next gen in wallet protection and keeps out any of those pesky Glitter Bomb kids.. You know, the ones we gave to em. At least you won't have to worry about them anymore!"  : "Glitter Bombs are stuffed with our 'patented' Web3 glitter and payload delivery system, built for max annoyance upon being delivered into a wallet. Upon exploding into the wallet of your enemy (or friend), a varying amount of shrapnel glitter will fill their wallet and be a hassle for their NFT viewing experience on popular marketplaces. Got Glittered? We'll clean it up... for a price. In the future maybe look into buying a handy dandy Glitter Shield 9000 to protect your wallet from further glitter related explosions.";

        ///@dev add the metadata that shows the type of token it is
        metadataString = string(
            abi.encodePacked(
                  metadataString
                , '{"trait_type":"Type","value":"'
                , _tokenId < ARMORY_CAPACITY ? ["Shield", "Bomb"][
                    _tokenId < MAX_SHIELDS ? 0 : 1
                ] : "Shrapnel"
                , '"}'
            )
        );

        ///@dev show the amount of pieces that a bomb exploded into
        if(
            _tokenId < ARMORY_CAPACITY && 
            0 < bombToPieces[_tokenId]
        ) {
            metadataString = string(
                abi.encodePacked(
                      metadataString
                    , ',{"trait_type":"Pieces","value":"'
                    , bombToPieces[_tokenId]
                    , '"}'
                )
            );
        }

        metadataString = string(
            abi.encodePacked(
                  '['
                , metadataString
                , ']'
            )
        );

        ///@dev build the metadata string and return it as encoded data
        metadataString = string(
            abi.encodePacked(
                  "data:application/json;base64,"
                , Base64.encode(
                    bytes(
                        string(
                            abi.encodePacked(
                                  '{"name":"Glitter'
                                , _tokenId < ARMORY_CAPACITY ? 
                                    [" Shield 9000", " Bomb"][
                                        _tokenId < MAX_SHIELDS ? 0 : 1
                                    ] : " Shrapnel"
                                , ' #'
                                , _tokenId.toString()
                                , '","description":"'
                                , descriptionString
                                , '","image":"data:image/svg+xml;base64,'
                                , Base64.encode(
                                    bytes(tokenImage(_tokenId))
                                  )                                
                                , '","attributes":'
                                , metadataString
                                , '}'
                            )
                        )
                    )
                )
            )
        );
    }

    ///@notice the number of pieces that a bomb exploded into
    function tokenPieces(
        uint256 _tokenId
    )
        public
        view
        returns (
            uint256
        )
    {
        require(
            _tokenId >= MAX_SHIELDS && _tokenId < ARMORY_CAPACITY, 
            "Bomb: non-container capacity check"
        );

        return bombToPieces[_tokenId];
    }

    ///@notice allows for the minting of the initial supply of shields
    function mintShield(
        uint256 _count
    ) 
        public 
        payable
    {
        require(mintOpen, "Bomb: mint closed");
        require(
              shieldSupply + _count < MAX_SHIELDS
            , "Bomb: shield exceeds supply"
        );
        require(
              msg.value == SHIELD_PRICE * _count
            , "Bomb: supplied mint value"
        );

        addressToShielded[msg.sender] += _count;

        for (
            uint256 i;
            i < _count; 
            i++
        ) {
            _owners[shieldSupply] = msg.sender;

            emit Transfer(
                  address(0)
                , msg.sender
                , shieldSupply
            );

            shieldSupply++;
        }
    }

    ///@notice allows for the free minting of the initial supply of bombs
    function mintBomb(
        uint256 _count
    ) 
        public
    {
        require(mintOpen, "Bomb: mint closed");
        require(bombSupply + _count < ARMORY_CAPACITY, "Bomb: exceeds supply");

        for (
            uint256 i;
            i < _count; 
            i++
        ) {
            _mint(
                  msg.sender
                , bombSupply++
            );
        }
    }

    ///@notice used to explode a token id onto a recipient
    function explode(
          uint256 _tokenId
        , address _recipient 
    )  
        public
    { 
        require(
            ownerOf(_tokenId) == msg.sender, 
            "Bomb: invalid caller"
        );
        require(
              _tokenId < ARMORY_CAPACITY && _tokenId >= MAX_SHIELDS
            , "Bomb: non-container explosion"
        );
        require(bombToPieces[_tokenId] == 0, "Bomb: exploded");
        require(
              addressToShielded[_recipient] < 1
            , "Bomb: recipient has shield"
        );
        require(
              _recipient != address(0)
            , "ERC721: transfer to the zero address"
        );

        bombToPieces[_tokenId] = uint256(
            keccak256(
                    abi.encodePacked(
                    _recipient
                    , block.difficulty
                )
            )
        ) % MAX_PIECES;

        if(bombToPieces[_tokenId] == 0) {
            bombToPieces[_tokenId] = 15; 
        }
        
        _owners[_tokenId] = _recipient;
        emit Transfer(
              msg.sender
            , _recipient
            , _tokenId
        );

        uint256 buffer = (
            ARMORY_CAPACITY + 
            ((_tokenId - MAX_SHIELDS) * MAX_PIECES)
        );

        emit ConsecutiveTransfer(
              buffer
            , buffer + bombToPieces[_tokenId]
            , address(0)
            , _recipient ///@dev To spec this can also be address(this)
        );
    }

    ///@dev returns the wei cost to clean a given amount of shrapnel
    function cleanPrice(
        uint256 _pieces
    )
        public
        pure
        returns (
            uint256
        )
    { 
        return (1 + (_pieces / CLEAN_INCREMENTS)) * CLEAN_INCREMENTS_PRICE;
    }

    ///@notice allows the recipient of an exploded bomb to repack the bomb
    function clean(
        uint256 _tokenId
    )
        public
        payable
    { 
        require(
              _tokenId < ARMORY_CAPACITY && _tokenId >= MAX_SHIELDS
            , "Bomb: shrapnel items not cleaned individually"
        );
        require(
              ownerOf(_tokenId) == msg.sender
            , "Bomb: invalid caller"
        );
        require(bombToPieces[_tokenId] != 0, "Bomb: not exploded");
        require(
              msg.value == cleanPrice(bombToPieces[_tokenId])
            , "Bomb: supplied cleaning value"
        );

        bombToPieces[_tokenId] = 0;
    }


    ///@notice claim the funds earned from a good cleaning service 
    function withdraw() 
        public
        onlyOwner() 
    { 
        (bool success, ) = owner().call{value: address(this).balance}("");
        require(success, "Failed to withdraw.");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    ///@notice max size of armory
    uint256 public constant ARMORY_CAPACITY = 5000;

    ///@notice max amount of bombs that can ever be minted
    uint256 public constant MAX_BOMBS = 4000;

    ///@notice max amount of shields that can be minted
    uint256 public constant MAX_SHIELDS = ARMORY_CAPACITY - MAX_BOMBS;

    ///@notice max amount of shrapnel that a bomb can explode into
    uint256 public constant MAX_PIECES = 150;

    ///@notice max amount of tokens that will ever exist
    uint256 public constant MAX_SUPPLY = ARMORY_CAPACITY + (MAX_BOMBS * MAX_PIECES);

    // Mapping from token ID to owner address
    address[MAX_SUPPLY] internal _owners;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    ///@notice bomb id to shrapnel pieces dispersed
    mapping(uint256 => uint256) public bombToPieces;

    ///@notice address to shield ownership
    mapping(address => uint256) public addressToShielded;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` 
     *      to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) 
        public 
        view 
        virtual 
        override(ERC165, IERC165) 
        returns (
            bool
        ) 
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @notice Returns the number of bombs in ``owner``'s account plus the 
     *      amount of shrapnel that has been sent to ``owner``'s account.
     * @dev See {IERC721-balanceOf}.
     * @dev This function is O(n) meaning it should not be used on-chain.
     */
    function balanceOf(
        address _owner
    ) 
        public 
        view 
        virtual 
        override 
        returns (
            uint256
        ) 
    {
        require(
              _owner != address(0)
            , "ERC721: balance query for the zero address"
        );

        uint256 _count;

        for(
            uint i; 
            i < ARMORY_CAPACITY; 
            ++i 
        ) {
            if(_owner == _owners[i]) {
                ///@dev if token is shield add 1
                if(i < MAX_SHIELDS) { 
                    _count++;
                } else { 
                    ///@dev if token is bomb include shrapnel
                   _count += 1 + bombToPieces[i];
                }
            }
        }

        return _count;
    }

    ///@dev Determines the token id of the bomb a piece of shrapnel belongs to
    function _shrapnelBombId(uint256 shrapnelId)
        public
        pure
        returns (
            uint256
        )
    { 
        return MAX_SHIELDS + ((shrapnelId - ARMORY_CAPACITY) / MAX_PIECES);
    }

    /**
     * @notice Extends base ERC-721 functionality to used Phantom ownership
     *         of Shrapnel pieces to the owner of a bomb that has exploded.
     * @dev See {IERC721-ownerOf}.
     * @return The address an unexploded bomb or the bomb a piece of 
     *         shrapnel came from
     */
    function ownerOf(
        uint256 _tokenId
    ) 
        override
        public 
        view 
        returns (
            address
        )
    {
        if(_tokenId < ARMORY_CAPACITY) {
            require(
                  _owners[_tokenId] != address(0)
                , "ERC721: owner query for nonexistent token"
            );
            return _owners[_tokenId];
        }

        uint256 _bombId = _shrapnelBombId(_tokenId);

        if(
            bombToPieces[_bombId] != 0 && 
            _tokenId < (
                ARMORY_CAPACITY + ((_bombId - MAX_SHIELDS) * MAX_PIECES) + bombToPieces[_bombId]
            )
        ) 
            return _owners[_bombId];

        revert("ERC721: owner query for nonexistent token");
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() 
        public 
        view 
        virtual 
        override 
        returns (
            string memory
        ) 
    {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() 
        public 
        view 
        virtual 
        override 
        returns (
            string memory
        ) 
    {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) 
        public 
        view 
        virtual 
        override 
        returns (
            string memory
        ) 
    {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI 
     *      for each token will be the concatenation of the `baseURI` and the *      `tokenId`. Empty by default, can be overriden in child contracts.
     */
    function _baseURI() 
        internal 
        view 
        virtual 
        returns (
            string memory
        ) 
    {
        return "";
    }

    /**
     * @notice Even if a bomb is approved before exploding once it explodes 
     *         future approvals will have no impact and are wasted gas.
     * @dev See {IERC721-approve}.
     */
    function approve(
          address to
        , uint256 tokenId
    ) 
        public 
        virtual 
        override 
    {
        require(tokenId < ARMORY_CAPACITY, "Bomb: shrapnel approval");

        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) 
        public 
        view 
        virtual 
        override 
        returns (
            address
        ) 
    {
        if(
            tokenId >= ARMORY_CAPACITY || 
            bombToPieces[tokenId] != 0
        ) return address(0);

        require(
            _exists(tokenId), 
            "ERC721: approved query for nonexistent token"
        );

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) 
        public 
        virtual 
        override 
    {
        _setApprovalForAll(
              _msgSender()
            , operator
            , approved
        );
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(
          address owner
        , address operator
    ) 
        public 
        view 
        virtual 
        override 
        returns (
            bool
        ) 
    {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @notice Transfering of exploded bombs and shrapnel are prohibited.
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
          address from
        , address to
        , uint256 tokenId
    ) 
        public 
        virtual 
        override 
    {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(
              from
            , to
            , tokenId
        );
    }

    /**
     * @notice Transfering of exploded bombs and shrapnel are prohibited.
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) 
        public 
        virtual 
        override 
    {
        safeTransferFrom(
              from
            , to
            , tokenId
            , ""
        );
    }

    /**
     * @notice Transfering of exploded bombs and shrapnel are prohibited.
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) 
        public 
        virtual 
        override 
    {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(
              from
            , to
            , tokenId
            , _data
        );
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
    ) 
        internal 
        virtual 
    {
        _transfer(
              from
            , to
            , tokenId
        );

        require(_checkOnERC721Received(
              from
            , to
            , tokenId
            , _data
        ), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) 
        internal 
        view 
        virtual 
        returns (
            bool
        )
    {
        if(tokenId < ARMORY_CAPACITY) {
            return _owners[tokenId] != address(0);
        }

        ///@notice if the pieces doesn't equal zero and the piece is <= the number of pieces in the bomb
        uint256 _bombId = _shrapnelBombId(tokenId);
        return tokenId < (
            ARMORY_CAPACITY + ((_bombId - MAX_SHIELDS) * MAX_PIECES) + bombToPieces[_bombId]
        );
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(
          address spender
        , uint256 tokenId
    ) 
        internal 
        view 
        virtual 
        returns (
            bool
        ) 
    {
        if(tokenId >= ARMORY_CAPACITY) return false;

        require(
            _exists(tokenId), 
            "ERC721: operator query for nonexistent token"
        );
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) 
        internal 
        virtual 
    {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
          address to
        , uint256 tokenId
        , bytes memory _data
    ) 
        internal 
        virtual 
    {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(
          address to
        , uint256 tokenId
    ) 
        internal 
        virtual 
    {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
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
    function _burn(uint256 tokenId) 
        internal 
        virtual 
    {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _owners[tokenId] = address(0);

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
          address from
        , address to
        , uint256 tokenId
    ) 
        internal 
        virtual 
    {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(
          address to
        , uint256 tokenId
    ) 
        internal 
        virtual 
    {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
          address owner
        , address operator
        , bool approved
    ) 
        internal 
        virtual 
    {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
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
          address from
        , address to
        , uint256 tokenId
        , bytes memory _data
    ) 
        private 
        returns (
            bool
        ) 
    {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
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

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    /**
     * @notice Hook that is called before any token transfer. This includes
     *         minting and burning.
     */
    function _beforeTokenTransfer(
          address from
        , address to
        , uint256 tokenId
    ) 
        internal 
        virtual 
    {
        if(tokenId < MAX_SHIELDS) { 
            addressToShielded[from] -= 1;
            addressToShielded[to] += 1;
        } else if(bombToPieces[tokenId] != 0)  
            revert("Bomb: exploded");
        else if(tokenId > ARMORY_CAPACITY)
            revert("Bomb: shrapnel transfer");
    }

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
          address
        , address
        , uint256 tokenId
    ) 
        internal 
        virtual 
    { }
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

pragma solidity >=0.6.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
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