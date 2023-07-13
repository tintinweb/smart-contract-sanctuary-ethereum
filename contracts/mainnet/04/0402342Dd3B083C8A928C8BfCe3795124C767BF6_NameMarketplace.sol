// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./INFTRegistry.sol";
import "./IPunks.sol";
import "./IERC721.sol";
import "./IWETH.sol";
import "./IERC20.sol";
import "./OwnableUpgradeable.sol";

contract NameMarketplace is OwnableUpgradeable {

    /**
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
      EVENTS
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
    **/

    /// @dev Event log for when a name is transferred
    /// @param collectionFrom collection address of NFT releasing name
    /// @param tokenFrom token id of NFT releasing name
    /// @param collectionTo collection address of NFT receiving name
    /// @param tokenTo token id of NFT receiving name    
    /// @param name the name being transferred
    event NameTransfer(address collectionFrom, uint256 tokenFrom, address collectionTo, uint256 tokenTo, string name);

    /// @dev Event log for when a name is offerred
    /// @param collectionFrom collection address of NFT releasing name
    /// @param tokenFrom token id of NFT releasing name   
    /// @param name the name being offered    
    /// @param minSalePriceInWei minimum ask for the name
    /// @param onlyTo optionally specify address if the offer is specific to a buyer
    /// @param feePerc marketplace fee % the name owner is willing to pay
    event NameOffered(address collectionFrom, uint256 tokenFrom, string name, uint256 minSalePriceInWei, address onlyTo, uint256 feePerc);

    /// @dev Event log for when a bid for a name is made
    /// @param collectionFrom collection address of NFT that owns the name
    /// @param tokenFrom token id of NFT that owns the name
    /// @param collectionTo collection address of NFT receiving name
    /// @param tokenTo token id of NFT receiving name    
    /// @param name the name being bid on
    /// @param value value bid in ETH
    /// @param bidder bidder address
    event NameBidEntered(address collectionFrom, uint256 tokenFrom, address collectionTo, uint256 tokenTo, string name, uint256 value, address bidder);

    /// @dev Event log for when a bid is withdrawn
    /// @param collectionFrom collection address of NFT that owns the name
    /// @param tokenFrom token id of NFT that owns the name
    /// @param collectionTo collection address of NFT receiving name
    /// @param tokenTo token id of NFT receiving name    
    /// @param name the name that had been bid on
    /// @param value value bid in ETH
    /// @param bidder bidder address
    event NameBidWithdrawn(address collectionFrom, uint256 tokenFrom, address collectionTo, uint256 tokenTo, string name, uint256 value, address bidder);

    /// @dev Event log for when a name is bought
    /// @param collectionFrom collection address of NFT releasing name
    /// @param tokenFrom token id of NFT releasing name
    /// @param collectionTo collection address of NFT receiving name
    /// @param tokenTo token id of NFT receiving name    
    /// @param name the name that has been bought
    /// @param value value bid in ETH  
    /// @param seller address of the previous name owner
    /// @param buyer address of the new name owner
    event NameBought(address collectionFrom, uint256 tokenFrom, address collectionTo, uint256 tokenTo, string name, uint256 value, address seller, address buyer);

    /// @dev Event log for when a name offer is retired
    /// @param collectionFrom collection address of NFT releasing name
    /// @param tokenFrom token id of NFT releasing name
    /// @param name the name that is no longer offered for sale
    event NameNoLongerForSale(address collectionFrom, uint256 tokenFrom, string name);

    /// @dev Event log for a change in the protocol free recipient
    /// @param protocolFeeRecipient the new recipient of protocol fees
    event NewProtocolFeeRecipient(address indexed protocolFeeRecipient);

    /// @dev Event log for a change in the protocol fee %
    /// @param feePerc the new fee in % terms
    event NewFeePerc(uint256 indexed feePerc);

    /**
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
      STRUCTS, STORAGE VARIABLES
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
    **/    

    struct Offer {
        bool isForSale;
        string name;
        address seller;
        uint256 minValue;       // in ETH
        address onlySellTo;     
        uint256 agreedFee;
    }

    struct Bid {
        bool hasBid;
        string name;
        address collectionTo;
        uint256 tokenTo;
        address bidder;
        uint256 value;          // in ETH
        uint256 bidBlock;       // recorded to avoid griefing name sellers
    }

    // Contract addresses
    IPunks public punksAddress;
    INFTRegistry public nftr; // name registry   
    address public WETH;     

    // A record of names that are offered for sale at a specific minimum value, and perhaps to a specific address
    mapping (bytes32 => Offer) public namesOfferedForSale;
    // A record of the highest name bid
    mapping (bytes32 => Bid) public nameBids;
    // A record of ETH that can be withdrawn by bidders whose bid hasn't been fulfilled
    mapping (address => uint256) public pendingWithdrawals;

    uint256 public feePerc;
    address public protocolFeeRecipient;    

    /**
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
      ERRORS
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
    **/

    error NotNameOwner();
    error NotForSale();
    error NotForSaleToThisAddress();
    error NotEnoughETH();
    error SellerNoLongerOwner();
    error BidderNoLongerOwner();
    error BuyerNotOwner();
    error NFTIsNotNamed();
    error NoNFTWithThatName();
    error BidderIsOwner();
    error BidderIsNotOwner();
    error BidIsTooLow();
    error NotBidder();
    error FailedToSendETHER();
    error FeeMismatch();
    error CantOverwriteNFTName();
    error TooEarlyToWithdraw();
    error NFTNotAllowedForNameTransfer();

    /**
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
      INITIALIZER
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
    **/

    function initialize(address _nftr, address _punksAddress, address _protocolFeeRecipient, address _WETH) external initializer {
        require(address(nftr) == address(0), "NameMarketplace: Can only initialize once");
        require(_nftr != address(0), "NameMarketplace: In constructor, can't set nftr to zero");
        require(_punksAddress != address(0), "NameMarketplace: In constructor, can't set punksAddress to zero");
        require(_protocolFeeRecipient != address(0), "NameMarketplace: In constructor, can't set protocolFeeRecipient to zero");
        require(_WETH != address(0), "NameMarketplace: In constructor, can't set WETH address to zero");        
        nftr = INFTRegistry(_nftr);
        punksAddress = IPunks(_punksAddress);
        protocolFeeRecipient = _protocolFeeRecipient;
        WETH = _WETH;    
        feePerc = 5;    
        __Ownable_init();
    }

    /**
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
      INTERNAL FUNCTIONS
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
    **/

    /**
     * @notice Converts the string to lowercase
     * @param str string to convert
     */
    function toLower(string memory str) internal pure returns (string memory) {
        bytes memory bStr = bytes(str);
        uint256 bStrLength = bStr.length;
        bytes memory bLower = new bytes(bStrLength);
        for (uint256 i = 0; i < bStrLength;) {
            // Uppercase character
            if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
                bLower[i] = bytes1(uint8(bStr[i]) + 32);
            } else {
                bLower[i] = bStr[i];
            }

            unchecked { i++; }
        }
        return string(bLower);
    }

    /**
     * @notice Get NFT's owner
     * @param nftAddress address of the NFT collection
     * @param tokenId token id of the NFT
     */
    function getOwner(address nftAddress, uint256 tokenId)
        internal
        view
        returns (address)
    {
        if (nftAddress == address(punksAddress)) {
            return IPunks(punksAddress).punkIndexToAddress(tokenId);
        } else {
            return IERC721(nftAddress).ownerOf(tokenId);
        }
    }

    /**
     * @notice Check if the message sender owns the NFT
     * @param nftAddress address of the NFT collection
     * @param tokenId token id of the NFT
     */
    function checkOwnership(address nftAddress, uint256 tokenId) internal view {
        if (msg.sender != getOwner(nftAddress, tokenId)) revert NotNameOwner();
    }    

    /**
     * @notice Get collection address and token id from an NFT name
     * @param name name of the NFT
     */ 
    function getToken(string calldata name) internal view returns (address, uint256) {
        Token memory _token = nftr.tokenByName(toLower(name));
        address collectionAddress = _token.collectionAddress;
        uint256 tokenId = _token.tokenId;
        if (collectionAddress == address(0) && tokenId == 0) revert NoNFTWithThatName();        
        return (collectionAddress, tokenId); 
    }   

    /**
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
      EXTERNAL FUNCTIONS
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
    **/

    /**
     * @notice Update the protocol fee %
     * @param _feePerc new fee
     */
    function updateFeePerc(uint256 _feePerc) external onlyOwner {
        require(_feePerc <= 100, "NameMarketplace: transfer fee is too high");
        feePerc = _feePerc;
        emit NewFeePerc(feePerc);
    }

    /**
     * @notice Update the protocol fee recipient
     * @param _protocolFeeRecipient new recipient
     */
    function updateProtocolFeeRecipient(address _protocolFeeRecipient) external onlyOwner {
        require(_protocolFeeRecipient != address(0), "NameMarketplace: protocolFeeRecipient can't be 0x0");
        protocolFeeRecipient = _protocolFeeRecipient;
        emit NewProtocolFeeRecipient(protocolFeeRecipient);
    }    

    /**
     * @notice Transfer a name from an NFT to another. Both NFTs must have the same owner (msg.sender)
     * @param collectionFrom address of NFT collection releasing the name
     * @param tokenFrom token id of NFT releasing the name
     * @param collectionTo address of NFT collection receiving the name
     * @param tokenTo token id of NFT receiving the name
     */
    function transferName(address collectionFrom, uint256 tokenFrom, address collectionTo, uint256 tokenTo) external {
        checkOwnership(collectionFrom, tokenFrom);
        checkOwnership(collectionTo, tokenTo); // also check that sender owns recipient NFT to avoid writing to recipient NFT's name unwillingly
        if (bytes(nftr.tokenName(collectionFrom, tokenFrom)).length == 0) revert NFTIsNotNamed();  
        if (bytes(nftr.tokenName(collectionTo, tokenTo)).length > 0) revert CantOverwriteNFTName();              
        string memory name = toLower(nftr.tokenName(collectionFrom, tokenFrom)); 
        nftr.transferName(collectionFrom, tokenFrom, collectionTo, tokenTo);
        emit NameTransfer(collectionFrom, tokenFrom, collectionTo, tokenTo, name);
    }

    /**
     * @notice Offer a name for sale. Sending fee % as a parameter ensures contract owner can't front-run the offer
     * @param name the name being offered
     * @param minSalePriceInWei minimum sale price
     * @param _feePerc % fee willing to pay (must be equal to current feePerc)
     */
    function offerNameForSale(string calldata name, uint256 minSalePriceInWei, uint256 _feePerc) external {
        (address collectionAddress, uint256 tokenId) = getToken(name);   
        checkOwnership(collectionAddress, tokenId);
        if (_feePerc != feePerc) revert FeeMismatch();
        
        // Check if this NFT is allowed for name transfer by the current owner
        if (!nftr.allowances(msg.sender, collectionAddress, tokenId)) revert NFTNotAllowedForNameTransfer();

        namesOfferedForSale[keccak256(abi.encodePacked(toLower(name)))] = Offer(true, name, msg.sender, minSalePriceInWei, address(0), _feePerc);
        emit NameOffered(collectionAddress, tokenId, name, minSalePriceInWei, address(0), feePerc);
    }

    /**
     * @notice Offer a name for sale to a specific buyer. Sending fee % as a parameter ensures contract owner can't front-run the offer
     * @param name the name being offered
     * @param minSalePriceInWei minimum sale price
     * @param toAddress the buyer's address
     * @param _feePerc % fee willing to pay (must be equal to current feePerc)
     */
    function offerNameForSaleToAddress(string calldata name, uint256 minSalePriceInWei, address toAddress, uint256 _feePerc) external {
        (address collectionAddress, uint256 tokenId) = getToken(name);     
        checkOwnership(collectionAddress, tokenId);
        if (_feePerc != feePerc) revert FeeMismatch();
        namesOfferedForSale[keccak256(abi.encodePacked(toLower(name)))] = Offer(true, name, msg.sender, minSalePriceInWei, toAddress, _feePerc);
        emit NameOffered(collectionAddress, tokenId, name, minSalePriceInWei, toAddress, feePerc);
    }    

    /**
     * @notice Retire an offer to sell a name
     * @param name the name being taken off market
     */
    function nameNoLongerForSale(string calldata name) external {
        (address collectionAddress, uint256 tokenId) = getToken(name);     
        checkOwnership(collectionAddress, tokenId);
        namesOfferedForSale[keccak256(abi.encodePacked(toLower(name)))] = Offer(false, name, address(0), 0, address(0), 0);
        emit NameNoLongerForSale(collectionAddress, tokenId, name);
    }

    /**
     * @notice Buy a name that is currently offered
     * @param name the name being offered
     * @param collectionTo collection address of NFT receiving name
     * @param tokenTo token id of NFT receiving name
     */
    function buyName(string calldata name, address collectionTo, uint256 tokenTo) external payable {
        (address collectionFrom, uint256 tokenFrom) = getToken(name);
        bytes32 encodedName = keccak256(abi.encodePacked(toLower(name)));        
        Offer memory offer = namesOfferedForSale[encodedName];
        if (!offer.isForSale) revert NotForSale(); // name not actually for sale
        if (offer.onlySellTo != address(0) && offer.onlySellTo != msg.sender) revert NotForSaleToThisAddress();  // name not supposed to be sold to this user
        if (msg.value < offer.minValue) revert NotEnoughETH();      // Didn't send enough ETH
        if (bytes(nftr.tokenName(collectionTo, tokenTo)).length > 0) revert CantOverwriteNFTName();

        address seller = offer.seller;
        if (seller != getOwner(collectionFrom, tokenFrom)) revert SellerNoLongerOwner(); // Seller no longer owner of name
        if (getOwner(collectionTo, tokenTo) != msg.sender) revert BuyerNotOwner();

        namesOfferedForSale[encodedName] = Offer(false, name, address(0), 0, address(0), 0);
        emit NameNoLongerForSale(collectionFrom, tokenFrom, name);

        if (offer.agreedFee < feePerc) revert FeeMismatch();
        uint256 protocolFee = msg.value * feePerc/100;
        // Wrap fee portion of ETH sent to this contract 
        IWETH(WETH).deposit{value: protocolFee}();
        IERC20(WETH).transfer(
            protocolFeeRecipient,
            protocolFee
        );        
        pendingWithdrawals[seller] += (msg.value - protocolFee);
        emit NameBought(collectionFrom, tokenFrom, collectionTo, tokenTo, name, msg.value, seller, msg.sender);

        // Check for the case where there is a bid from the new owner and refund it.
        // Any other bid can stay in place.
        Bid memory bid = nameBids[encodedName];
        if (bid.bidder == msg.sender) {
            // Kill bid and refund value
            pendingWithdrawals[msg.sender] += bid.value;
            nameBids[encodedName] = Bid(false, name, address(0), 0, address(0), 0, 0);
        }

        nftr.transferName(collectionFrom, tokenFrom, collectionTo, tokenTo);
        emit NameTransfer(collectionFrom, tokenFrom, collectionTo, tokenTo, name);        
    }

    /**
     * @notice Withdraw any pending ETH available for the msg.sender
     */
    function withdraw() external {
        uint amount = pendingWithdrawals[msg.sender];
        pendingWithdrawals[msg.sender] = 0;
        (bool sent, ) = msg.sender.call{value: amount}("");
        if (!sent) revert FailedToSendETHER();
    }

    /**
     * @notice Enter a bid for a name
     * @param name The name being bid on
     * @param collectionTo address of NFT collection to receive the name
     * @param tokenTo token id of NFT to receive the name
     */
    function enterBidForName(string calldata name, address collectionTo, uint256 tokenTo) external payable {
        (address collectionFrom, uint256 tokenFrom) = getToken(name);
        if (getOwner(collectionFrom, tokenFrom) == msg.sender) revert BidderIsOwner();
        if (getOwner(collectionTo, tokenTo) != msg.sender) revert BidderIsNotOwner();
        if (bytes(nftr.tokenName(collectionTo, tokenTo)).length > 0) revert CantOverwriteNFTName();

        if (msg.value == 0) revert NotEnoughETH();
        bytes32 encodedName = keccak256(abi.encodePacked(toLower(name)));
        Bid memory existing = nameBids[encodedName];

        // Check for the case where the existing bid's name destination isn't owned by the bidder anymore and clean
        address existingCollection = existing.collectionTo;
        uint256 existingToken = existing.tokenTo;
        if (
            (existingCollection != address(0)) 
            && 
            (existing.bidder == getOwner(existingCollection, existingToken))) {
                if (msg.value <= existing.value) revert BidIsTooLow();
        }
        if (existing.value > 0) {
            // Refund the failing bid
            pendingWithdrawals[existing.bidder] += existing.value;
        }
        nameBids[encodedName] = Bid(true, name, collectionTo, tokenTo, msg.sender, msg.value, block.number);
        emit NameBidEntered(collectionFrom, tokenFrom, collectionTo, tokenTo, name, msg.value, msg.sender);
    }

    /**
     * @notice Accept a bid for a name. Sending fee % as a parameter ensures contract owner can't front-run the transaction
     * @param name the name being sold
     * @param minPrice minimum price in wei
     * @param _feePerc the fee percentage (must be equal to feePerc)
     */
    function acceptBidForName(string calldata name, uint256 minPrice, uint256 _feePerc) external {            
        (address collectionAddress, uint256 tokenId) = getToken(name);            
        checkOwnership(collectionAddress, tokenId);
        if (_feePerc != feePerc) revert FeeMismatch();
        address seller = msg.sender;
        bytes32 encodedName = keccak256(abi.encodePacked(toLower(name)));
        Bid memory bid = nameBids[encodedName];
        uint256 amount = bid.value;
        if (amount == 0) revert BidIsTooLow();
        if (amount < minPrice) revert BidIsTooLow();
        if (getOwner(bid.collectionTo, bid.tokenTo) != bid.bidder) revert BidderNoLongerOwner();
        if (bytes(nftr.tokenName(bid.collectionTo, bid.tokenTo)).length > 0) revert CantOverwriteNFTName();

        namesOfferedForSale[encodedName] = Offer(false, name, address(0), 0, address(0), 0);
        nameBids[encodedName] = Bid(false, name, address(0), 0, address(0), 0, 0);
        uint256 protocolFee = amount * feePerc/100;
        // Wrap fee portion of ETH sent to this contract 
        IWETH(WETH).deposit{value: protocolFee}();
        IERC20(WETH).transfer(
            protocolFeeRecipient,
            protocolFee
        );        
        pendingWithdrawals[seller] += (amount - protocolFee);        
        emit NameBought(collectionAddress, tokenId, bid.collectionTo, bid.tokenTo, name, amount, seller, bid.bidder);

        nftr.transferName(collectionAddress, tokenId, bid.collectionTo, bid.tokenTo);
        emit NameTransfer(collectionAddress, tokenId, bid.collectionTo, bid.tokenTo, name);        
    }

    /**
     * @notice Withdraw a bid for a name
     * @param name the name that had been bid on
     */
    function withdrawBidForName(string calldata name) external {
        (address collectionAddress, uint256 tokenId) = getToken(name);
        bytes32 encodedName = keccak256(abi.encodePacked(toLower(name)));        
        // Ensure some blocks have passed after bid before allowing withdraw to deincentivise "wipe bidding"
        Bid memory bid = nameBids[encodedName];
        if (bid.bidBlock + 9 > block.number) revert TooEarlyToWithdraw();        
        if (bid.bidder != msg.sender) revert NotBidder();
        emit NameBidWithdrawn(collectionAddress, tokenId, bid.collectionTo, bid.tokenTo, name, bid.value, msg.sender);
        uint amount = bid.value;
        nameBids[encodedName] = Bid(false, name, address(0), 0, address(0), 0, 0);
        // Refund the bid money
        (bool sent, ) = msg.sender.call{value: amount}("");
        if (!sent) revert FailedToSendETHER();
    }

}