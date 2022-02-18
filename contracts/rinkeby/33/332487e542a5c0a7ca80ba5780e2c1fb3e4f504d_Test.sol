/**
 *Submitted for verification at Etherscan.io on 2022-02-18
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

error ApprovalCallerNotOwnerNorApproved();
error ApprovalQueryForNonexistentToken();
error ApproveToCaller();
error ApprovalToCurrentOwner();
error BalanceQueryForZeroAddress();
error MintedQueryForZeroAddress();
error BurnedQueryForZeroAddress();
error ClaimedQueryForZeroAddress();
error MintToZeroAddress();
error MintZeroQuantity();
error OwnerIndexOutOfBounds();
error OwnerQueryForNonexistentToken();
error TokenIndexOutOfBounds();
error TransferCallerNotOwnerNorApproved();
error TransferFromIncorrectOwner();
error TransferToNonERC721ReceiverImplementer();
error TransferToZeroAddress();
error URIQueryForNonexistentToken();
error NonexistentToken();
error BurnableCallerNotOwnerNorApproved();
error QueryForNonexistentToken();

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

library Strings {
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

abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(msg.sender);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        // extcodesize returns 0 for contracts in construction.
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance"); // Check contract balance.
        (bool success, ) = recipient.call{value: amount}(""); // Send to recipient.
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

interface IERC721Enumerable is IERC721 {
    function totalSupply() external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
    function tokenByIndex(uint256 index) external view returns (uint256);
}

interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

contract Test is IERC721Enumerable, Ownable, ReentrancyGuard {

    ///  __   __        __  ___  __        __  ___  __   __  
    /// /  ` /  \ |\ | /__`  |  |__) |  | /  `  |  /  \ |__) 
    /// \__, \__/ | \| .__/  |  |  \ \__/ \__,  |  \__/ |  \ 

    constructor() {
        marketplacePaused = true;
        withdrawThreshold = 1 ether;
    }
    
    ///            __          __        ___  __  
    /// \  /  /\  |__) |  /\  |__) |    |__  /__` 
    ///  \/  /~~\ |  \ | /~~\ |__) |___ |___ .__/ 

    using Address for address;
    using Strings for uint256;
    string internal tokenName = "Test"; // Use name()
    string internal tokenSymbol = "TEST"; // Use symbol()
    string public contentHash; // IPFS hash.
    string internal baseURI; // IPFS base.
    uint256 internal _tokensMinted;
    uint256 internal _tokensBurned;
    uint64 internal _multiplierValue;
    uint64 internal _multiplierTimestamp;
    uint256 internal constant maxSupply = 25000; // maxSupply.
    uint256 internal constant purchaseLimit = 50; // Max tokens that can be minted per transaction.
    uint256 internal constant maxFree = 20000; // Up to 20,000 can be claimed from the giveaway.
    uint256 internal constant redeemLimitStart = 6; // Number each account starts at.
    uint256 internal constant basePriceIncrement = 0.00001 ether; // Base price increment.
    uint256 internal constant declineDuration = 100 hours; // Price and multiplier declines by 1% per hour.
    uint256 public withdrawThreshold;

    // Token data. Ordered by mint number, not token ID number.
    mapping(uint256 => TokenData) internal _tokenData;
    struct TokenData {
        address account; // Address that owns the token.
        address approval; // 20 bytes. Use approved()
        uint32 level;
        bool burned; // 1 byte
    }

    // Account data.
    mapping(address => AccountData) private _accountData;
    struct AccountData {
        uint32 balance;
        uint32 minted;
        uint32 burned; // Account level
        uint32 claimed;
        mapping(address => bool) approvals; // Use isApprovedForAll().
    }
    
    event MintFree(address indexed account, uint256 amount);
    event MintPurchase(address indexed account, uint256 amount, uint256 bonus, uint256 base, uint256 multiplier, uint256 decline, uint256 price, uint256 timestamp);
    event MintSpecial(address indexed account, uint256 amount);
    event TokenMetadata(address indexed account, uint256 indexed tokenId, uint256 indexed category, string data, bool isOwner);

    function mintFree(uint256 _amount) external nonReentrant {
        
        // Initialize
        require(_tokensMinted < maxFree, "Giveaway limit reached");
        require(_amount > 0, "Amount out of range");
        require(tx.origin == msg.sender, "Can't be contract");

        // Get redemptions remaining.
        uint256 redemptionsRemaining = ownerToRedemptionsRemaining(msg.sender);

        // Prevent revert if claiming too many.
        if (_amount > redemptionsRemaining && redemptionsRemaining > 0) {
            _amount = redemptionsRemaining;
        }

        require(_amount <= redemptionsRemaining, "Account limit reached");

        //ownerToClaimed[msg.sender] += _amount; // Add to total claimed.
        _accountData[msg.sender].claimed += uint32(_amount); // Add to total claimed.

        _safeMint(msg.sender, _amount); // Mint token(s).

        emit MintFree(msg.sender, _amount);
    }

    /// @dev Each account can mint up to 20 for free.
    function redeemLimit() public view returns (uint256 _amount) {
        if (_tokensMinted < maxFree) {
            _amount = (_tokensMinted / 1000) + redeemLimitStart;
        }
        return _amount;
    }

    function ownerToRedemptionsRemaining(address _owner) public view returns (uint256 _amount) {
        if (_tokensMinted < maxFree) { // If giveaway still available.
            _amount = redeemLimit() - _accountData[_owner].claimed; // Calculate remaining.
        }
        return _amount;
    }

    function mintPurchase(uint256 _amount) external payable nonReentrant {
        
        // Initialize
        require(_amount >= 1 && _amount <= purchaseLimit, "Amount out of range");

        // Get price and total.
        (uint256 tokenPrice, uint256 base, uint256 multiplier, uint256 decline, uint256 bogo) = getPrice();
        uint256 salePrice = tokenPrice * _amount;
        require(msg.value >= salePrice, "Insufficient funds sent, price may have increased");

        uint256 bonus = _amount / bogo;

        // Update multiplier.
        _multiplierValue = uint64(multiplier + (20 * (_amount + bonus))); // 20 = 0.02%.
        _multiplierTimestamp = uint64(block.timestamp);

        // Issue refund.
        if (msg.value > salePrice) {
            uint256 _refund = msg.value - salePrice;
            payable(msg.sender).transfer(_refund);
        }

        // Payout to contract owner when threshold is reached.
        if (address(this).balance > withdrawThreshold) {
            withdraw();
        }

        _safeMint(msg.sender, _amount + bonus); // Mint token(s).

        emit MintPurchase(msg.sender, _amount, bonus, base, multiplier, decline, tokenPrice, block.timestamp);
    }

    function getPrice() public view returns (uint256 _price, uint256 _base, uint256 _multiplier, uint256 _decline, uint256 _bogo) {
        
        // Base
        _base = (_tokensMinted + 1) * basePriceIncrement;

        // Multiplier
        uint256 elapsed = block.timestamp - _multiplierTimestamp;
        if (elapsed < declineDuration) { // If time remaining.
            _multiplier = ((declineDuration - elapsed) * _multiplierValue) / declineDuration;
        }

        // Decline
        _decline = ((block.timestamp - _multiplierTimestamp) * 100000) / declineDuration;
        if (_decline > 100000) {
            _decline = 100000;
        }

        // Price
        _price = ((((_base * (_multiplier + 100000)) / 100000) * (100000 - _decline)) / 100000);

        // Calc BOGO.
        uint256 half;
        if (_multiplier > 100000) { // If over 100%.
            half = 1;
        } else {
            half = 2;
        }

        if (elapsed < 15 minutes) {
             _bogo = 10 / half;
        } else if (elapsed < 30 minutes) {
            _bogo = 8 / half;
        } else if (elapsed < 45 minutes) {
            _bogo = 6 / half;
        } else if (elapsed < 60 minutes) {
            _bogo = 4 / half;
        } else {
            _bogo = 2 / half;
        }

        return (_price, _base, _multiplier, _decline, _bogo);
    }

    ///  __  ___       ___  __  
    /// /  \  |  |__| |__  |__) 
    /// \__/  |  |  | |___ |  \
    
    /// @dev Withdraw contract balance to owner.
    function withdraw() public {
        Address.sendValue(payable(owner()), address(this).balance);
    }

    /// @dev Array of token owners.
    function tokenOwners() external view returns (address[maxSupply] memory owners) {
        for (uint256 i = 0; i < maxSupply; i++) {
            uint256 tokenId = i + 1;
            uint256 tokenIdIndex = getTokenIdIndex(tokenId);

            unchecked {
                if (tokenIdIndex < _tokensMinted) {
                    TokenData memory tokenData = _tokenData[tokenId];
                    if (!tokenData.burned) {
                        if (tokenData.account != address(0)) {
                            owners[i] = tokenData.account;
                        }
                        while (owners[i] == address(0)) {
                            tokenIdIndex--;
                            tokenId = getTokenId(tokenIdIndex);
                            tokenData = _tokenData[tokenId];
                            if (tokenData.account != address(0)) {
                                owners[i] = tokenData.account;
                            }
                        }
                    }
                }
            }
        }
    }

    // Get array of token levels.
    function tokenLevels() external view returns (uint256[maxSupply] memory levels) {
        for (uint256 i = 0; i < maxSupply; i++) {
            uint256 tokenId = i + 1;
            uint256 tokenIdIndex = getTokenIdIndex(tokenId);

            unchecked {
                if (tokenIdIndex < _tokensMinted) {
                    TokenData memory tokenData = _tokenData[tokenId];
                    levels[i] = uint256(tokenData.level);
                }
            }
        }
    }
    
    /// @dev Emit token metadata.
    function tokenMetadata(uint256 _tokenId, uint256 _category, string memory _data) external {
        bool owner;
        if (ownerOf(_tokenId) == msg.sender) {
            owner = true;
        }
        emit TokenMetadata(msg.sender, _tokenId, _category, _data, owner);
    }

    function contractBalance() public view returns (uint256 _balance) {
        return address(this).balance;
    }

    function deposit() public payable {} // Deposit to contract.
    
    /// @dev Owner can mint tokens for free without a limit directly to an address.
    function mintSpecial(uint256 _amount, address _recipient) external onlyOwner {
        require(_amount >= 1 && _amount <= 100);
        _safeMint(_recipient, _amount); // Mint token(s).
    }

    /// @dev Owner can set base URI.
    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    /// @dev Owner can set IPFS hash.
    function setContentHash(string memory _contentHash) external onlyOwner {
        contentHash = _contentHash;
    }

    /// @dev Owner can set the automatic paid out amount. 
    function setWithdrawThreshold(uint256 _amount) external onlyOwner {
        withdrawThreshold = _amount;
    }

    /// @dev Enables the marketplace.
    function pauseMarketplace(bool _status) external onlyOwner {
        marketplacePaused = _status;
    }

    function name() public view returns (string memory) {
        return tokenName;
    }

    function symbol() public view returns (string memory) {
        return tokenSymbol;
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        //require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        if (!_exists(tokenId)) revert QueryForNonexistentToken();
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == type(IERC165).interfaceId || // Interface ID: 0x01ffc9a7
            interfaceId == type(IERC721).interfaceId || // Interface ID: 0x80ac58cd
            interfaceId == type(IERC721Metadata).interfaceId || // Interface ID: 0x5b5e139f
            interfaceId == type(IERC721Enumerable).interfaceId; // Interface ID: 0x780e9d63
    }

    bool public marketplacePaused; // If market paused.

    // If a trade has been approved.
    mapping(address => // Maker's address
    mapping(address => // Taker's address
    mapping(bytes32 => // Maker IDs
    mapping(bytes32 => // Taker IDs
    mapping(uint256 => // Price (in wei)
    mapping(uint256 => // Tip (x1000)
    mapping(uint256 => // Expiry (unix)
    bool))))))) internal approvedTrades;

    event MakeOffer(
        address indexed maker, 
        address indexed taker, 
        uint256[] makerIds, 
        uint256[] takerIds, 
        uint256 price
    );
    event ApproveTrade(
        address indexed maker, 
        address indexed taker, 
        uint256[] makerIds, 
        uint256[] takerIds, 
        uint256 price, 
        uint256 tip, 
        uint256 expiry
    );
    event CancelTrade(
        address indexed maker, 
        address indexed taker, 
        uint256[] makerIds, 
        uint256[] takerIds, 
        uint256 price, 
        uint256 tip, 
        uint256 expiry
    );
    event Trade(
        address indexed maker, 
        address indexed taker, 
        uint256[] makerIds, 
        uint256[] takerIds, 
        uint256 price, 
        uint256 tip, 
        uint256 expiry
    );

    /// @dev Sends a request to the maker to purchase their token(s) with ETH, otherwise use approveOffer().
    /// @dev _taker is retrieved from msg.sender.
    function makeOffer(
        address _maker, 
        uint256[] memory _makerIds, 
        uint256[] memory _takerIds, 
        uint256 _price
    ) 
        external 
    {
        emit MakeOffer(_maker, msg.sender, _makerIds, _takerIds, _price);
    }

    /// @dev Only the owner of an account can approve a trade.
    /// @dev _maker is retrieved from msg.sender.
    function approveTrade(
        address _taker, 
        uint256[] memory _makerIds, 
        uint256[] memory _takerIds, 
        uint256 _price, 
        uint256 _tip, 
        uint256 _expiry
    ) 
        external 
    {
        approvedTrades[msg.sender][_taker][keccak256(abi.encodePacked(_makerIds))][keccak256(abi.encodePacked(_takerIds))][_price][_tip][_expiry] = true;
        emit ApproveTrade(msg.sender, _taker, _makerIds, _takerIds, _price, _tip, _expiry);
    }

    /// @dev Only the owner of an account can cancel a trade or when the taker completes the trade in trade().
    /// @dev _maker is retrieved from msg.sender.
    function cancelTrade(
        address _taker, 
        uint256[] memory _makerIds, 
        uint256[] memory _takerIds, 
        uint256 _price, 
        uint256 _tip, 
        uint256 _expiry
    )
        external 
    {
        approvedTrades[msg.sender][_taker][keccak256(abi.encodePacked(_makerIds))][keccak256(abi.encodePacked(_takerIds))][_price][_tip][_expiry] = false;
        emit CancelTrade(msg.sender, _taker, _makerIds, _takerIds, _price, _tip, _expiry);
    }

    /// @dev Checks if a trade has been approved by the maker.
    function isOfferApproved(
        address _maker, 
        address _taker, 
        uint256[] memory _makerIds, 
        uint256[] memory _takerIds, 
        uint256 _price, 
        uint256 _tip, 
        uint256 _expiry
    )
        public view returns (bool) 
    {
        return approvedTrades[_maker][_taker][keccak256(abi.encodePacked(_makerIds))][keccak256(abi.encodePacked(_takerIds))][_price][_tip][_expiry];
    }

    /// @dev Check if a trade is valid.
    /// @dev A few more things are checked in trade().
    function isOfferValid(
        address _maker, 
        address _taker, 
        uint256[] memory _makerIds, 
        uint256[] memory _takerIds,
        uint256 _price, 
        uint256 _tip, 
        uint256 _expiry
    ) 
        public view returns (bool) 
    {

        // Can't be the same addresses.
        require(_maker != _taker, "Addresses must be different");

        // Maker can't be a contract to prevent issues.
        require(!_maker.isContract(), "Maker can't be contract");
        
        // Can't be expired.
        require(_expiry == 0 || block.timestamp < _expiry, "Offer expired");
        
        // Maker must offer something.
        require(_makerIds.length > 0, "Maker must offer something");
        
        // Check if the maker owns the maker IDs.
        for (uint i = 0; i < _makerIds.length; i++) {
            //require(idToOwner[_makerIds[i]] == _maker, "Maker doesn't own a token offered");
            //TokenData memory ownership = _tokenData[getTokenIdIndex(_makerIds[i])];
            require(ownerOf(_makerIds[i]) == _maker, "Maker doesn't own a token offered");
        }

        // Taker must offer something.
        require(_takerIds.length > 0 || _price > 0, "Taker must offer something");

        // Check if the taker owns the taker IDs.
        if (_takerIds.length > 0) {
            if (_taker != address(0)) {
                for (uint i = 0; i < _takerIds.length; i++) {
                    //require(idToOwner[_takerIds[i]] == _taker, "Taker doesn't own a token offered");
                    require(ownerOf(_takerIds[i]) == _taker, "Taker doesn't own a token offered");
                }
            } else { // If offer for anyone, can't specify tokens.
                require(_takerIds.length == 0, "Public offers can't specify taker IDs");
            }
        }
        
        if (_tip > 0) {
            require(_price > 0, "Can't tip if no price set");
        }

        // Limit tip to 100%. 100000 = 100%. 12345 = 12.345%
        require(_tip <= 100000, "Can't tip over 100%");

        return true;
    }
    
    /// @dev Check if a maker approved an offer and if the offer meets all requirements.
    function isOfferApprovedAndValid(
        address _maker, 
        address _taker, 
        uint256[] memory _makerIds, 
        uint256[] memory _takerIds,
        uint256 _price, 
        uint256 _tip, 
        uint256 _expiry
    ) 
        public view returns (bool) 
    {

        // Check if approved by the maker.
        require(isOfferApproved(_maker, _taker, _makerIds, _takerIds, _price, _tip, _expiry), "Not approved by maker");

        // Check if valid offer.
        require(isOfferValid(_maker, _taker, _makerIds, _takerIds, _price, _tip, _expiry), "Invalid trade");

        return true;
    }

    /// @dev Accept a trade.
    function trade(
        address _maker, 
        address _taker, 
        uint256[] memory _makerIds, 
        uint256[] memory _takerIds,
        uint256 _price,
        uint256 _tip, 
        uint256 _expiry
    ) 
        external payable nonReentrant 
    {

        // Check market.
        require(!marketplacePaused, "Market paused");
        
        // Check sender/taker.
        require(msg.sender != _maker, "Can't accept own offer");
        require(_taker == address(0) || _taker == msg.sender, "Offer not for you");

        // Check value sent.
        require(_price == msg.value, "Incorrect funds sent");

        // Check offer.
        // Every variable must match what the maker approved, or else the transaction reverts.
        require(isOfferApprovedAndValid(_maker, _taker, _makerIds, _takerIds, _price, _tip, _expiry), "Invalid trade");

        // After this, msg.sender is used instead of taker because taker can be zero address (meaning available to anyone).

        // Handle ETH.
        if (_price > 0) {
            uint256 tipAmount;
            if (_tip > 0) { // If maker is tipping.
                tipAmount = _price - ((_price * (100000 - _tip)) / 100000); // Calculate tip.
            }
            payable(_maker).transfer(_price - tipAmount); // Transfer ETH to maker.
        }
        
        // Transfer maker IDs to taker.
        for (uint i = 0; i < _makerIds.length; i++) {
            //_transfer(idToOwner[_makerIds[i]], msg.sender, _makerIds[i]);
            _transfer(ownerOf(_makerIds[i]), msg.sender, _makerIds[i]);
        }
        
        // Transfer taker IDs to maker.
        for (uint i = 0; i < _takerIds.length; i++) {
            //_transfer(idToOwner[_takerIds[i]], _maker, _takerIds[i]);
            _transfer(ownerOf(_takerIds[i]), _maker, _takerIds[i]);
        }
        
        // Cancel trade.
        approvedTrades[_maker][_taker][keccak256(abi.encodePacked(_makerIds))][keccak256(abi.encodePacked(_takerIds))][_price][_tip][_expiry] = false;
        
        emit Trade(_maker, msg.sender, _makerIds, _takerIds, _price, _tip, _expiry);
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        // Counter underflow is impossible as _tokensBurned cannot be incremented
        // more than _tokensMinted times
        unchecked {
            return _tokensMinted - _tokensBurned;    
        }
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     * This read function is O(totalSupply). If calling from a separate contract, be sure to test gas first.
     * It may also degrade with extremely large collection sizes (e.g >> 10000), test for your use case.
     */
    function tokenByIndex(uint256 index) public view override returns (uint256) {
        // uint256 numMintedSoFar = _tokensMinted;
        // uint256 tokenIdsIdx;

        // // Counter overflow is impossible as the loop breaks when
        // // uint256 i is equal to another uint256 numMintedSoFar.
        // unchecked {
        //     for (uint256 i; i < numMintedSoFar; i++) {
        //         TokenData memory ownership = _tokenData[i];
        //         if (!ownership.burned) {
        //             if (tokenIdsIdx == index) {
        //                 return i;
        //             }
        //             tokenIdsIdx++;
        //         }
        //     }
        // }
        // revert TokenIndexOutOfBounds();

        //require(index < _tokensMinted, "ERC721Enumerable: global index out of bounds");
        if (index >= _tokensMinted) revert TokenIndexOutOfBounds();
        return getTokenId(index);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     * This read function is O(totalSupply). If calling from a separate contract, be sure to test gas first.
     * It may also degrade with extremely large collection sizes (e.g >> 10000), test for your use case.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view override returns (uint256) {
        if (index >= balanceOf(owner)) revert OwnerIndexOutOfBounds();
        uint256 tokensMinted = _tokensMinted;
        uint256 tokenIdsIndex;
        address tokenOwner;

        // Counter overflow is impossible as the loop breaks when
        // uint256 i is equal to another uint256 numMintedSoFar.
        unchecked {
            for (uint256 i; i < tokensMinted; i++) {
                uint256 tokenId = getTokenId(i);
                TokenData memory tokenData = _tokenData[tokenId];
                if (!tokenData.burned) {
                    //continue;
                    if (tokenData.account != address(0)) {
                        tokenOwner = tokenData.account;
                    }
                    if (tokenOwner == owner) {
                        if (tokenIdsIndex == index) {
                            return tokenId; // Return token ID.
                        }
                        tokenIdsIndex++;
                    }
                }
            }
        }

        // Execution should never reach this point.
        revert();
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view override returns (uint256) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        return uint256(_accountData[owner].balance);
    }

    function _minted(address owner) internal view returns (uint256) {
        if (owner == address(0)) revert MintedQueryForZeroAddress();
        return uint256(_accountData[owner].minted);
    }

    function _burned(address owner) internal view returns (uint256) {
        if (owner == address(0)) revert BurnedQueryForZeroAddress();
        return uint256(_accountData[owner].burned);
    }

    function ownerToClaimed(address owner) public view returns (uint256) {
        if (owner == address(0)) revert ClaimedQueryForZeroAddress();
        return uint256(_accountData[owner].claimed);
    }

    /**
     * Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around in the collection over time.
     */
    function ownershipOf(uint256 tokenId) internal view returns (TokenData memory) {
        //tokenIdIndex = getTokenIdIndex(tokenId);
        uint256 tokenIdIndex = getTokenIdIndex(tokenId);

        unchecked {
            if (tokenIdIndex < _tokensMinted) {
                TokenData memory tokenData = _tokenData[tokenId];
                if (!tokenData.burned) {
                    if (tokenData.account != address(0)) {
                        return tokenData;
                    }
                    // Invariant: 
                    // There will always be an ownership that has an address and is not burned 
                    // before an ownership that does not have an address and is not burned.
                    // Hence, curr will not underflow.
                    while (true) {
                        tokenIdIndex--;
                        tokenId = getTokenId(tokenIdIndex);
                        tokenData = _tokenData[tokenId];
                        if (tokenData.account != address(0)) {
                            return tokenData;
                        }
                    }
                }
            }
        }
        revert OwnerQueryForNonexistentToken();
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        return ownershipOf(tokenId).account;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual returns (string memory) {
        //uint256 tokenIdIndex = getTokenIdIndex(tokenId);
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        //string memory baseURI = _baseURI;
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : '';
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public override {
        address owner = ownerOf(tokenId);
        if (to == owner) revert ApprovalToCurrentOwner();

        if (msg.sender != owner && !isApprovedForAll(owner, msg.sender)) {
            revert ApprovalCallerNotOwnerNorApproved();
        }

        _approve(to, tokenId, owner);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view override returns (address) {
        //uint256 tokenIdIndex = getTokenIdIndex(tokenId);
        if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();
        return _tokenData[tokenId].approval; // _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public override {
        if (operator == msg.sender) revert ApproveToCaller();

        //_operatorApprovals[msg.sender][operator] = approved;
        _accountData[msg.sender].approvals[operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        //return _operatorApprovals[owner][operator];
        return _accountData[owner].approvals[operator];
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
    ) public virtual override {
        _transfer(from, to, tokenId);
        if (!_checkOnERC721Received(from, to, tokenId, _data)) {
            revert TransferToNonERC721ReceiverImplementer();
        }
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        uint256 tokenIdIndex = getTokenIdIndex(tokenId);
        return tokenIdIndex < _tokensMinted && !_tokenData[tokenIdIndex].burned;
    }

    function _safeMint(address to, uint256 quantity) internal {
        _safeMint(to, quantity, '');
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
        uint256 quantity,
        bytes memory _data
    ) internal {
        _mint(to, quantity, _data, true);
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
        uint256 quantity,
        bytes memory _data,
        bool safe
    ) internal {
        uint256 startTokenIdIndex = _tokensMinted;
        uint256 startTokenId = getTokenId(startTokenIdIndex);
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();

        // _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // balance or minted overflow if current value of either + quantity > 3.4e38 (2**128) - 1
        // updatedIndex overflows if _tokensMinted + quantity > 3.4e38 (2**128) - 1
        unchecked {
            _accountData[to].balance += uint32(quantity);
            _accountData[to].minted += uint32(quantity);

            _tokenData[startTokenId].account = to;
            //_tokenData[startTokenId].timestamp = uint64(block.timestamp);

            uint256 updatedIndex = startTokenIdIndex;

            for (uint256 i; i < quantity; i++) {
                uint256 tokenId = getTokenId(updatedIndex); // Calculate token IDs.
                emit Transfer(address(0), to, tokenId);
                if (safe && !_checkOnERC721Received(address(0), to, tokenId, _data)) {
                    revert TransferToNonERC721ReceiverImplementer();
                }
                updatedIndex++;
            }

            _tokensMinted = updatedIndex;
        }
        // _afterTokenTransfers(address(0), to, startTokenId, quantity);
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
    ) private {
        uint256 tokenIdIndex = getTokenIdIndex(tokenId);
        TokenData memory prevOwnership = ownershipOf(tokenId);

        bool isApprovedOrOwner = (msg.sender == prevOwnership.account ||
            isApprovedForAll(prevOwnership.account, msg.sender) ||
            getApproved(tokenId) == msg.sender);

        if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
        if (prevOwnership.account != from) revert TransferFromIncorrectOwner();
        if (to == address(0)) revert TransferToZeroAddress();

        //_beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, prevOwnership.account);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**128.
        unchecked {
            _accountData[from].balance -= 1;
            _accountData[to].balance += 1;

            _tokenData[tokenId].account = to;
            //_tokenData[tokenId].timestamp = uint32(block.timestamp);

            // If the ownership slot of tokenId+1 is not explicitly set, that means the transfer initiator owns it.
            // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
            uint256 nextTokenIdIndex = tokenIdIndex + 1;
            uint256 nextTokenId = getTokenId(nextTokenIdIndex);
            if (_tokenData[nextTokenId].account == address(0)) {
                // This will suffice for checking _exists(nextTokenId),
                // as a burned slot cannot contain the zero address.
                if (nextTokenIdIndex < _tokensMinted) {
                    _tokenData[nextTokenId].account = prevOwnership.account;
                    //_tokenData[nextTokenIdIndex].timestamp = prevOwnership.timestamp;
                }
            }
        }

        emit Transfer(from, to, tokenId);
        //_afterTokenTransfers(from, to, tokenId, 1);
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
    function _burn(uint256 tokenId) internal virtual {
        if (!_isApprovedOrOwner(msg.sender, tokenId)) revert BurnableCallerNotOwnerNorApproved(); // Check ownership.
        
        uint256 tokenIdIndex = getTokenIdIndex(tokenId);
        TokenData memory prevOwnership = ownershipOf(tokenId);

        //_beforeTokenTransfers(prevOwnership.account, address(0), tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, prevOwnership.account);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**128.
        unchecked {
            _accountData[prevOwnership.account].balance--;
            _accountData[prevOwnership.account].burned++;

            // Keep track of who burned the token, and the timestamp of burning.
            _tokenData[tokenId].account = prevOwnership.account;
            //_tokenData[tokenId].timestamp = uint64(block.timestamp);
            _tokenData[tokenId].burned = true;

            uint256 nextTokenIdIndex = tokenIdIndex + 1;
            uint256 nextTokenId = getTokenId(nextTokenIdIndex);
            if (_tokenData[nextTokenId].account == address(0)) {
                // This will suffice for checking _exists(nextTokenId),
                // as a burned slot cannot contain the zero address.
                if (nextTokenIdIndex < _tokensMinted) {
                    _tokenData[nextTokenId].account = prevOwnership.account;
                    //_tokenData[nextTokenIdIndex].timestamp = prevOwnership.timestamp;
                }
            }
        }

        emit Transfer(prevOwnership.account, address(0), tokenId);
        //_afterTokenTransfers(prevOwnership.account, address(0), tokenId, 1);

        // Overflow not possible, as _tokensBurned cannot be exceed _tokensMinted times.
        unchecked { 
            _tokensBurned++;
        }
    }

    // Burn/sacrifice a CryptoBlob and transfer levels/souls.
    function sacrifice(uint256 tokenIdBurning, uint256 tokenIdLeveling) external returns (uint256 level) {
        //if (msg.sender != ownerOf(tokenIdBurning)) revert CallerNotOwner(); // Check ownership.
        if (_tokenData[tokenIdLeveling].burned) revert NonexistentToken(); // Check if burned.

        // Burn token.
        _burn(tokenIdBurning);

        // Get levels.
        uint32 levels = _tokenData[tokenIdBurning].level;

        // Remove levels.
        _tokenData[tokenIdBurning].level = 0;

        // Add levels.
        _tokenData[tokenIdLeveling].level += levels + 1;

        return uint256(_tokenData[tokenIdLeveling].level);
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
        _tokenData[tokenId].approval = to;
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
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert TransferToNonERC721ReceiverImplementer();
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

    // Calculate token ID from index. 
    // This is a reversible PRNG algorithm, an alternative to minting token IDs by +1 to keep things interesting.
    // It's more gas efficient than generating random token IDs per transaction, as it doesn't require saving data.
    // And also an alternative to a standard LCG that allows for reversibility, since we need to know mint order.
    function getTokenId(uint256 _index) public pure returns (uint256 _tokenId) {
        if (_index >= maxSupply) revert TokenIndexOutOfBounds(); // Must be 0-24999.
        unchecked { // Saves gas.
            // Get mod of number.
            uint256 numberMod = _index % 5;
            if (numberMod == 0) {
                numberMod = 5;
            }

            // Calculate token ID.
            return ((_index * 100) % 25000) + ((((_index * 100) / 25000) + (20 * numberMod)) % 100) + 1;
        }
    }

    // Calculate index from token ID.
    function getTokenIdIndex(uint256 _tokenId) public pure returns (uint256 _index) {
        if (_tokenId > maxSupply || _tokenId < 1) revert TokenIndexOutOfBounds(); // Must be 1-25000.
        
        unchecked { // Saves gas.
            // Get mod of number.
            uint256 mod = (_tokenId / 100) % 5;
            if (mod == 0) {
                mod = 5;
            }
            
            // Correct offset.
            if (_tokenId % 100 > (20 * mod)) {
                _index = _tokenId - (20 * mod);
            } else {
                _index = _tokenId + (20 * (5 - mod));
            }

            // Calculate index.
            if (_index % 100 != 0) {
                _index = ((((_index % 100) - 1) * 250) + (_index / 100));
                if (mod != 5) {
                    if (_index >= 4751 + (5000 * (4 - mod)) && _index < 5000 * (5 - mod)) {
                    _index = _index + 4999;
                    }
                }
            } else {
                _index = (24749 + (_index / 100));
                if (_tokenId % 500 == 0) {
                    _index = _index - 20000;
                }
            }
            return _index;
        }
    }

    // Get a list of tokens owned by an address. 
    // This is for front-end. Cross-contract transactions may be costly.
    function tokensOfOwner(address owner) external view returns (uint256[] memory) {
        uint256 tokensMinted = _tokensMinted; // Saves gas.
        uint256 tokenIdsIndex;
        address tokenOwner;
        uint256 balance = balanceOf(owner);
        uint256[] memory tokenIds = new uint256[](balance);

        unchecked {
            for (uint256 i; i < tokensMinted; i++) {
                uint256 tokenId = getTokenId(i);
                TokenData memory tokenData = _tokenData[tokenId];
                if (!tokenData.burned) {
                    //continue;
                    if (tokenData.account != address(0)) {
                        tokenOwner = tokenData.account; // Save owner.
                    }
                    if (tokenOwner == owner) { // If owner matches.
                        tokenIds[tokenIdsIndex++] = tokenId; // Add token ID to list and interate array.
                    }
                }
            }
            return tokenIds;
        }
    }
}