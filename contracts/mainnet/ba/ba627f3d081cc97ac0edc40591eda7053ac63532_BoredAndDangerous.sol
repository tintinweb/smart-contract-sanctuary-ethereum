// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import {ERC721} from "solmate/tokens/ERC721.sol";
import {ERC2981} from "openzeppelin-contracts/contracts/token/common/ERC2981.sol";
import {MerkleProof} from "openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";
import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";


interface IERC721 {
    function ownerOf(uint tokenId) external view returns (address);
}


contract BoredAndDangerous is ERC721, ERC2981 {
    /// @notice The original writer's room contract
    address public constant WRITERS_ROOM = 0x880644ddF208E471C6f2230d31f9027578FA6FcC;

    /// @notice The grace period for refund claiming
    uint public constant DUTCH_AUCTION_GRACE_PERIOD = 12 hours;
    /// @notice The mint cap in the dutch auction
    uint public constant DUTCH_AUCTION_MINT_CAP = 2;
    /// @notice The first token id that dutch auction minters will receive, inclusive
    uint public immutable DUTCH_AUCTION_START_ID;
    /// @notice The last token id that dutch auction minters will receive, inclusive
    uint public immutable DUTCH_AUCTION_END_ID;

    /// @notice The price for writelist mints
    uint public writelistPrice;

    /// @notice The address which can admin mint for free, set merkle roots, and set auction params
    address public mintingOwner;
    /// @notice The address which can update the metadata uri
    address public metadataOwner;
    /// @notice The address which will be returned for the ERC721 owner() standard for setting royalties
    address public royaltyOwner;

    /// @notice Records the price and time when the final dutch auction token sells out
    struct DutchAuctionFinalization {
        uint128 price;
        uint128 time;
    }
    /// @notice The instantiation of the dutch auction finalization struct
    DutchAuctionFinalization public dutchEnd;

    /// @notice The token id which will be minted next in the dutch auction
    uint public dutchAuctionNextId;
    /// @notice The token id which will be minted next in the writelist mint
    uint public writelistMintNextId;

    /// @notice Records whether a whitelist allocation has been started, and how many are remaining to claim
    struct Writelist {
        uint128 remaining;
        bool used;
    }

    /// @notice Whether free mints for writers' room holders are open
    bool public writelistMintWritersRoomFreeOpen;

    /// @notice Whether paid mints for writers' room holders are open
    bool public writelistMintWritersRoomOpen;

    /// @notice Construct this from (address, amount) tuple elements
    bytes32 public giveawayMerkleRoot;
    /// @notice Caches writelist allocations once they've been used
    mapping(address => Writelist) public giveawayWritelist;

    /// @notice Construct this from (address, tokenId) tuple elements
    bytes32 public apeMerkleRoot;
    /// @notice Maps (address, tokenId) hash to bool, true if token has minted
    mapping(bytes32 => bool) public apeWritelistUsed;

    /// @notice Maps tokenId to bool, true if token has minted
    mapping(uint => bool) public writersroomWritelistUsed;

    /// @notice Total number of tokens which have minted
    uint public totalSupply = 0;

    /// @notice The prefix to attach to the tokenId to get the metadata uri
    string public baseTokenURI;

    /// @notice Struct is packed to fit within a single 256-bit slot
    struct DutchAuctionMintHistory {
        uint128 amount;
        uint128 price;
    }
    /// @notice Store the mint history for an individual address. Used to issue refunds
    mapping(address => DutchAuctionMintHistory) public mintHistory;

    /// @notice Struct is packed to fit within a single 256-bit slot
    /// @dev uint64 has max value 1.8e19, or 18 ether
    /// @dev uint32 has max value 4.2e9, which corresponds to max timestamp of year 2106
    struct DutchAuctionParams {
        uint64 startPrice;
        uint64 endPrice;
        uint64 priceIncrement;
        uint32 startTime;
        uint32 timeIncrement;
    }
    /// @notice The instantiation of dutch auction parameters
    DutchAuctionParams public params;

    /// @notice Emitted when a token is minted
    event Mint(address indexed owner, uint indexed tokenId);
    /// @notice Emitted when an accounts receives its dutch auction refund
    event DutchAuctionRefund(address indexed account);

    /// @notice Raised when an unauthorized user calls a gated function
    error AccessControl();
    /// @notice Raised when a non-EOA account calls a gated function
    error OnlyEOA(address msgSender);
    /// @notice Raised when a user exceeds their mint cap
    error ExceededUserMintCap();
    /// @notice Raised when the mint has not reached the required timestamp
    error MintNotOpen();
    /// @notice Raised when the user attempts to writelist mint on behalf of a token they do not own
    error DoesNotOwnToken(uint tokenId);
    /// @notice Raised when the user attempts to mint after the dutch auction finishes
    error DutchAuctionOver();
    /// @notice Raised when the admin attempts to withdraw funds before the dutch auction grace period has ended
    error DutchAuctionGracePeriod(uint endPrice, uint endTime);
    /// @notice Raised when a user attempts to claim their dutch auction refund before the dutch auction ends
    error DutchAuctionNotOver();
    /// @notice Raised when the admin attempts to mint within the dutch auction range while the auction is still ongoing
    error DutchAuctionNotOverAdmin();
    /// @notice Raised when the admin attempts to set dutch auction parameters that don't make sense
    error DutchAuctionBadParamsAdmin();
    /// @notice Raised when `sender` does not pass the proper ether amount to `recipient`
    error FailedToSendEther(address sender, address recipient);
    /// @notice Raised when a user tries to writelist mint twice
    error WritelistUsed();
    /// @notice Raised when two calldata arrays do not have the same length
    error MismatchedArrays();
    /// @notice Raised when the user attempts to mint zero items
    error MintZero();

    constructor(uint _DUTCH_AUCTION_START_ID, uint _DUTCH_AUCTION_END_ID) ERC721("Bored & Dangerous", "BOOK") {
        DUTCH_AUCTION_START_ID = _DUTCH_AUCTION_START_ID;
        DUTCH_AUCTION_END_ID = _DUTCH_AUCTION_END_ID;
        dutchAuctionNextId = _DUTCH_AUCTION_START_ID;
        writelistMintNextId = _DUTCH_AUCTION_END_ID + 1;
        mintingOwner = msg.sender;
        metadataOwner = msg.sender;
        royaltyOwner = msg.sender;
    }

    /// @notice Admin mint a token
    function ownerMint(address recipient, uint tokenId) external {
        if (msg.sender != mintingOwner) {
            revert AccessControl();
        }

        if (DUTCH_AUCTION_START_ID <= tokenId && tokenId <= DUTCH_AUCTION_END_ID) {
            revert DutchAuctionNotOverAdmin();
        }

        unchecked {
            ++totalSupply;
        }
        _mint(recipient, tokenId);
    }

    /// @notice Admin mint a batch of tokens
    function ownerMintBatch(address[] calldata recipients, uint[] calldata tokenIds) external {
        if (msg.sender != mintingOwner) {
            revert AccessControl();
        }
        
        if (recipients.length != tokenIds.length) {
            revert MismatchedArrays();
        }

        unchecked {
            totalSupply += tokenIds.length;
            for (uint i = 0; i < tokenIds.length; ++i) {
                if (DUTCH_AUCTION_START_ID <= tokenIds[i] && tokenIds[i] <= DUTCH_AUCTION_END_ID) {
                    revert DutchAuctionNotOverAdmin();
                }
                _mint(recipients[i], tokenIds[i]);
            }
        }
    }
    
    ///////////////////
    // DUTCH AUCTION //
    ///////////////////

    /// @notice The current dutch auction price
    /// @dev Reverts if dutch auction has not started yet
    /// @dev Returns the end price even if the dutch auction has sold out
    function dutchAuctionPrice() public view returns (uint) {
        DutchAuctionParams memory _params = params;
        uint numIncrements = (block.timestamp - _params.startTime) / _params.timeIncrement;
        uint price = _params.startPrice - numIncrements * _params.priceIncrement;
        if (price < _params.endPrice) {
            price = _params.endPrice;
        }
        return price;
    }

    /// @notice Dutch auction with refunds
    /// @param amount The number of NFTs to mint, either 1 or 2
    function dutchAuctionMint(uint amount) external payable {
        // Enforce EOA mints
        _onlyEOA(msg.sender);

        if (amount == 0) {
            revert MintZero();
        }

        DutchAuctionMintHistory memory userMintHistory = mintHistory[msg.sender];

        // Enforce per-account mint cap
        if (userMintHistory.amount + amount > DUTCH_AUCTION_MINT_CAP) {
            revert ExceededUserMintCap();
        }

	    uint256 _dutchAuctionNextId = dutchAuctionNextId;
        // Enforce global mint cap
        if (_dutchAuctionNextId + amount > DUTCH_AUCTION_END_ID + 1) {
            revert DutchAuctionOver();
        }

        DutchAuctionParams memory _params = params;

        // Enforce timing
        if (block.timestamp < _params.startTime || _params.startPrice == 0) {
            revert MintNotOpen();
        }
        
        // Calculate dutch auction price
        uint numIncrements = (block.timestamp - _params.startTime) / _params.timeIncrement;
        uint price = _params.startPrice - numIncrements * _params.priceIncrement;
        if (price < _params.endPrice) {
            price = _params.endPrice;
        }

        // Check mint price
        if (msg.value != amount * price) {
            revert FailedToSendEther(msg.sender, address(this));
        }
        unchecked {
            uint128 newPrice = (userMintHistory.amount * userMintHistory.price + uint128(amount * price)) / uint128(userMintHistory.amount + amount);
            mintHistory[msg.sender] = DutchAuctionMintHistory({
                amount: userMintHistory.amount + uint128(amount),
                price: newPrice
            });
            for (uint i = 0; i < amount; ++i) {
                _mint(msg.sender, _dutchAuctionNextId++);
            }
            totalSupply += amount;
            if (_dutchAuctionNextId > DUTCH_AUCTION_END_ID) {
                dutchEnd = DutchAuctionFinalization({
                    price: uint128(price),
                    time: uint128(block.timestamp)
                });
            }
	        dutchAuctionNextId = _dutchAuctionNextId;
        }
    }

    /// @notice Provide dutch auction refunds to people who minted early
    /// @dev Deliberately left unguarded so users can either claim their own, or batch refund others
    function claimDutchAuctionRefund(address[] calldata accounts) external {
        // Check if dutch auction over
        if (dutchEnd.price == 0) {
            revert DutchAuctionNotOver();
        }
        for (uint i = 0; i < accounts.length; ++i) {
            address account = accounts[i];
            DutchAuctionMintHistory memory mint = mintHistory[account];
            // If an account has already been refunded, skip instead of reverting
            // This prevents griefing attacks when performing batch refunds
            if (mint.price > 0) {
                uint refundAmount = mint.amount * (mint.price - dutchEnd.price);
                delete mintHistory[account];
                (bool sent,) = account.call{value: refundAmount}("");
                // Revert if the address has a malicious receive function
                // This is not a griefing vector because the function can be retried
                // without the failing recipient
                if (!sent) {
                    revert FailedToSendEther(address(this), account);
                }
            }
        }
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////
    // WRITELIST MINTS (free writer's room, paid writer's room, paid bored/mutant ape, paid giveaway) //
    ////////////////////////////////////////////////////////////////////////////////////////////////////

    /// @notice Free mint from writelist ticket allocation
    function writelistMintWritersRoomFree(uint[] calldata tokenIds) external {
        if (!writelistMintWritersRoomFreeOpen) {
            revert MintNotOpen();
        }
        for (uint i = 0; i < tokenIds.length; ++i) {
            address tokenOwner = IERC721(WRITERS_ROOM).ownerOf(tokenIds[i]);
            // This will revert is specific tokenId already minted
            _mint(tokenOwner, tokenIds[i]);
        }
        totalSupply += tokenIds.length;
    }

    /// @notice Paid mint for a writer's room NFT
    function writelistMintWritersRoom(uint[] calldata tokenIds) external payable {
        if (!writelistMintWritersRoomOpen) {
            revert MintNotOpen();
        }
        // Check payment
        if (msg.value != tokenIds.length * writelistPrice) {
            revert FailedToSendEther(msg.sender, address(this));
        }

        for (uint i = 0; i < tokenIds.length; ++i) {
            if (writersroomWritelistUsed[tokenIds[i]]) {
                revert WritelistUsed();
            }
            writersroomWritelistUsed[tokenIds[i]] = true;
            address tokenOwner = IERC721(WRITERS_ROOM).ownerOf(tokenIds[i]);
            _mint(tokenOwner, writelistMintNextId++);
        }
        totalSupply += tokenIds.length;
    }

    /// @notice Mint for a licensed bored ape or mutant ape
    function writelistMintApes(address tokenContract, uint tokenId, bytes32 leaf, bytes32[] calldata proof) external payable {
        // Check payment
        if (msg.value != writelistPrice) {
            revert FailedToSendEther(msg.sender, address(this));
        }
        
        bytes32 tokenHash = keccak256(abi.encodePacked(tokenContract, tokenId));
        
        // Create storage element tracking user mints if this is the first mint for them
        if (apeWritelistUsed[tokenHash]) {
            revert WritelistUsed();
        }
        // Verify that (tokenContract, tokenId) correspond to Merkle leaf
        require(tokenHash == leaf, "Token contract and id don't match Merkle leaf");

        // Verify that (leaf, proof) matches the Merkle root
        require(verify(apeMerkleRoot, leaf, proof), "Not a valid leaf in the Merkle tree");

        // Get the current tokenOwner and mint to them
        address tokenOwner = IERC721(tokenContract).ownerOf(tokenId);

        apeWritelistUsed[tokenHash] = true;
        ++totalSupply;

        _mint(tokenOwner, writelistMintNextId++);
    }

    /// @notice Mint from writelist allocation
    function writelistMintGiveaway(address tokenOwner, uint8 amount, uint8 totalAllocation, bytes32 leaf, bytes32[] memory proof) external payable {
        // Check payment
        if (msg.value != amount * writelistPrice) {
            revert FailedToSendEther(msg.sender, address(this));
        }

        Writelist memory writelist = giveawayWritelist[tokenOwner];
        
        // Create storage element tracking user mints if this is the first mint for them
        if (!writelist.used) {    
            // Verify that (tokenOwner, amount) correspond to Merkle leaf
            require(keccak256(abi.encodePacked(tokenOwner, totalAllocation)) == leaf, "Sender and amount don't match Merkle leaf");

            // Verify that (leaf, proof) matches the Merkle root
            require(verify(giveawayMerkleRoot, leaf, proof), "Not a valid leaf in the Merkle tree");

            writelist.used = true;
            // Save some gas by never writing to this slot if it will be reset to zero at method end
            if (amount != totalAllocation) {
                writelist.remaining = totalAllocation - amount;
            }
        }
        else {
            writelist.remaining -= amount;
        }

        giveawayWritelist[tokenOwner] = writelist;
        totalSupply += amount;
        for (uint i = 0; i < amount; ++i) {
            _mint(tokenOwner, writelistMintNextId++);
        }
    }

    /// @notice Ensure the proof and leaf match the merkle root
    function verify(bytes32 root, bytes32 leaf, bytes32[] memory proof) public pure returns (bool) {
        return MerkleProof.verify(proof, root, leaf);
    }

    /////////////////////////
    // ADMIN FUNCTIONALITY //
    /////////////////////////

    /// @notice Set metadata
    function setBaseTokenURI(string memory _baseTokenURI) external {
        if (msg.sender != metadataOwner) {
            revert AccessControl();
        }
        baseTokenURI = _baseTokenURI;
    }

    /// @notice Set merkle root
    function setGiveawayMerkleRoot(bytes32 _giveawayMerkleRoot) external {
        if (msg.sender != mintingOwner) {
            revert AccessControl();
        }
        giveawayMerkleRoot = _giveawayMerkleRoot;
    }

    /// @notice Set merkle root
    function setApeMerkleRoot(bytes32 _apeMerkleRoot) external {
        if (msg.sender != mintingOwner) {
            revert AccessControl();
        }
        apeMerkleRoot = _apeMerkleRoot;
    }

    /// @notice Set parameters
    function setDutchAuctionStruct(DutchAuctionParams calldata _params) external {
        if (msg.sender != mintingOwner) {
            revert AccessControl();
        }
        if (!(_params.startPrice >= _params.endPrice && _params.endPrice > 0 && _params.startTime > 0 && _params.timeIncrement > 0)) {
            revert DutchAuctionBadParamsAdmin();
        }
        params = DutchAuctionParams({
            startPrice: _params.startPrice,
            endPrice: _params.endPrice,
            priceIncrement: _params.priceIncrement,
            startTime: _params.startTime,
            timeIncrement: _params.timeIncrement
        });
    }

    /// @notice Set writelistMintNextId
    /// @dev Should not be used, but failsafe in case the admin accidentally mints a token id in the writelist range too early
    function setWritelistMintNextId(uint _writelistMintNextId) external {
        if (msg.sender != mintingOwner) {
            revert AccessControl();
        }
        writelistMintNextId = _writelistMintNextId;
    }

    /// @notice Set writelistMintWritersRoomFreeOpen
    function setWritelistMintWritersRoomFreeOpen(bool _value) external {
        if (msg.sender != mintingOwner) {
            revert AccessControl();
        }
        writelistMintWritersRoomFreeOpen = _value;
    }

    /// @notice Set writelistMintWritersRoomOpen
    function setWritelistMintWritersRoomOpen(bool _value) external {
        if (msg.sender != mintingOwner) {
            revert AccessControl();
        }
        writelistMintWritersRoomOpen = _value;
    }

    /// @notice Set writelistPrice
    function setWritelistPrice(uint _price) external {
        if (msg.sender != mintingOwner) {
            revert AccessControl();
        }
        writelistPrice = _price;
    }

    /// @notice Claim funds
    function claimFunds(address payable recipient) external {
        if (!(msg.sender == mintingOwner || msg.sender == metadataOwner || msg.sender == royaltyOwner)) {
            revert AccessControl();
        }

        // Wait for the grace period after scheduled end to allow claiming of dutch auction refunds
        if (!(dutchEnd.price > 0 && block.timestamp >= dutchEnd.time + DUTCH_AUCTION_GRACE_PERIOD)) {
            revert DutchAuctionGracePeriod(dutchEnd.price, dutchEnd.time);
        }

        (bool sent,) = recipient.call{value: address(this).balance}("");
        if (!sent) {
            revert FailedToSendEther(address(this), recipient);
        }
    }

    ////////////////////////////////////
    // ACCESS CONTROL ADDRESS UPDATES //
    ////////////////////////////////////

    /// @notice Update the mintingOwner
    /// @dev Can also be used to revoke this power by setting to 0x0
    function setMintingOwner(address _mintingOwner) external {
        if (msg.sender != mintingOwner) {
            revert AccessControl();
        }
        mintingOwner = _mintingOwner;
    }

    /// @notice Update the metadataOwner
    /// @dev Can also be used to revoke this power by setting to 0x0
    /// @dev Should only be revoked after setting an IPFS url so others can pin
    function setMetadataOwner(address _metadataOwner) external {
        if (msg.sender != metadataOwner) {
            revert AccessControl();
        }
        metadataOwner = _metadataOwner;
    }

    /// @notice Update the royaltyOwner
    /// @dev Can also be used to revoke this power by setting to 0x0
    function setRoyaltyOwner(address _royaltyOwner) external {
        if (msg.sender != royaltyOwner) {
            revert AccessControl();
        }
        royaltyOwner = _royaltyOwner;
    }

    /// @notice The address which can set royalties
    function owner() external view returns (address) {
        return royaltyOwner;
    }

    // ROYALTY FUNCTIONALITY

    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC2981) returns (bool) {
        return
            interfaceId == 0x2a55205a || // ERC165 Interface ID for ERC2981
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /// @dev See {ERC2981-_setDefaultRoyalty}.
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external {
        if (msg.sender != royaltyOwner) {
            revert AccessControl();
        }
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    /// @dev See {ERC2981-_deleteDefaultRoyalty}.
    function deleteDefaultRoyalty() external {
        if (msg.sender != royaltyOwner) {
            revert AccessControl();
        }
        _deleteDefaultRoyalty();
    }

    /// @dev See {ERC2981-_setTokenRoyalty}.
    function setTokenRoyalty(uint256 tokenId, address receiver, uint96 feeNumerator) external {
        if (msg.sender != royaltyOwner) {
            revert AccessControl();
        }
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    /// @dev See {ERC2981-_resetTokenRoyalty}.
    function resetTokenRoyalty(uint256 tokenId) external {
        if (msg.sender != royaltyOwner) {
            revert AccessControl();
        }
        _resetTokenRoyalty(tokenId);
    }

    // METADATA FUNCTIONALITY

    /// @notice Returns the metadata URI for a given token
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(baseTokenURI, Strings.toString(tokenId)));
    }

    // INTERNAL FUNCTIONS

    /// @dev Revert if the account is a smart contract. Does not protect against calls from the constructor.
    /// @param account The account to check
    function _onlyEOA(address account) internal view {
        if (msg.sender != tx.origin || account.code.length > 0) {
            revert OnlyEOA(account);
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
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
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/common/ERC2981.sol)

pragma solidity ^0.8.0;

import "../../interfaces/IERC2981.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the NFT Royalty Standard, a standardized way to retrieve royalty payment information.
 *
 * Royalty information can be specified globally for all token ids via {_setDefaultRoyalty}, and/or individually for
 * specific token ids via {_setTokenRoyalty}. The latter takes precedence over the first.
 *
 * Royalty is specified as a fraction of sale price. {_feeDenominator} is overridable but defaults to 10000, meaning the
 * fee is specified in basis points by default.
 *
 * IMPORTANT: ERC-2981 only specifies a way to signal royalty information and does not enforce its payment. See
 * https://eips.ethereum.org/EIPS/eip-2981#optional-royalty-payments[Rationale] in the EIP. Marketplaces are expected to
 * voluntarily pay royalties together with sales, but note that this standard is not yet widely supported.
 *
 * _Available since v4.5._
 */
abstract contract ERC2981 is IERC2981, ERC165 {
    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    RoyaltyInfo private _defaultRoyaltyInfo;
    mapping(uint256 => RoyaltyInfo) private _tokenRoyaltyInfo;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc IERC2981
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) public view virtual override returns (address, uint256) {
        RoyaltyInfo memory royalty = _tokenRoyaltyInfo[_tokenId];

        if (royalty.receiver == address(0)) {
            royalty = _defaultRoyaltyInfo;
        }

        uint256 royaltyAmount = (_salePrice * royalty.royaltyFraction) / _feeDenominator();

        return (royalty.receiver, royaltyAmount);
    }

    /**
     * @dev The denominator with which to interpret the fee set in {_setTokenRoyalty} and {_setDefaultRoyalty} as a
     * fraction of the sale price. Defaults to 10000 so fees are expressed in basis points, but may be customized by an
     * override.
     */
    function _feeDenominator() internal pure virtual returns (uint96) {
        return 10000;
    }

    /**
     * @dev Sets the royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setDefaultRoyalty(address receiver, uint96 feeNumerator) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: invalid receiver");

        _defaultRoyaltyInfo = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Removes default royalty information.
     */
    function _deleteDefaultRoyalty() internal virtual {
        delete _defaultRoyaltyInfo;
    }

    /**
     * @dev Sets the royalty information for a specific token id, overriding the global default.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: Invalid parameters");

        _tokenRoyaltyInfo[tokenId] = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Resets royalty information for the token id back to the global default.
     */
    function _resetTokenRoyalty(uint256 tokenId) internal virtual {
        delete _tokenRoyaltyInfo[tokenId];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
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
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be proved to be a part of a Merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and the sibling nodes in `proof`,
     * consuming from one or the other at each step according to the instructions given by
     * `proofFlags`.
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
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