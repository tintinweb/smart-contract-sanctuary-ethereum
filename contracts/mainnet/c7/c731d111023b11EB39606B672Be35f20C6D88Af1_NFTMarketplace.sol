// SPDX-License-Identifier: MIT
pragma solidity >=0.8.15 <0.9.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

import "./IERC721Autentica.sol";

contract NFTMarketplace is
    AccessControl,
    ReentrancyGuard,
    Pausable
{
    // Number of decimals used for fees.
    uint8 public constant DECIMALS = 2;

    // Create a new role identifier for the operator role.
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    // Autentica wallet address.
    address private _autentica;

    // Allowed token addresses to be used with `tradeForTokens`.
    address[] private _allowedTokens;

    // NFT details.
    struct NFT {
        address owner;
        address creator;
        address investor;
    }

    // Percentages for each party that needs to be payed.
    struct Percentages {
        uint256 creator;
        uint256 investor;
    }

    // Proceeds for each party that needs to be payed amounts expressed in coins or tokens, not in percentages
    struct Proceeds {
        uint256 creator;
        uint256 investor;
        uint256 marketplace;
    }

    // ECDSA signature.
    struct Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    /**
     * @dev Emitted when the Autentica wallet address has been updated.
     */
    event ChangedAutentica(
        address indexed oldAddress,
        address indexed newAddress
    );
    /**
     * @dev Emitted when a trade occured between the `seller` (the owner of the ERC-721 token
     * represented by `tokenId` within the `collection` smart contract) and `buyer` which
     * payed the specified `price` in coins (the native cryptocurrency of the platform, i.e.: ETH).
     */
    event TradedForCoins(
        address indexed collection,
        uint256 indexed tokenId,
        address indexed seller,
        address buyer,
        uint256 price,
        uint256 ownerProceeds,
        uint256 creatorProceeds,
        uint256 investorProceeds
    );
    /**
     * @dev Emitted when a trade occured between the `seller` (the owner of the ERC-721 token
     * represented by `tokenId` within the `collection` smart contract) and `buyer` which
     * payed the specified `price` in tokens that are represented by the `token`
     * ERC-20 smart contract address.
     */
    event TradedForTokens(
        address indexed collection,
        uint256 indexed tokenId,
        address indexed seller,
        address buyer,
        address token,
        uint256 price,
        uint256 ownerProceeds,
        uint256 creatorProceeds,
        uint256 investorProceeds
    );

    /**
     * @dev Emitted when a new token is allowed to be used for trading.
     */
    event AllowedTokenAdded(address indexed tokenAddress);
    /**
     * @dev Emitted when a token is not longer allowed to be used for trading.
     */
    event AllowedTokenRemoved(address indexed tokenAddress);

    /**
     * The constructor sets the creator of the contract as the admin
     * and operator of this smart contract, sets the wallet address for Autentica and sets the allowed tokens.
     */
    constructor(address wallet, address[] memory allowedTokens) {
        // Grant the admin role to the owner
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        // Grant the operator role to the owner
        _setupRole(OPERATOR_ROLE, _msgSender());

        // Set the wallet address for Autentica
        _autentica = wallet;

        // Set the allowed tokens
        for (uint256 i = 0; i < allowedTokens.length; i++) {
            addAllowedToken(allowedTokens[i]);
        }
    }

    /**
     * Returns the Autentica wallet address.
     */
    function autentica() external view returns (address) {
        return _autentica;
    }

    /**
     * @dev Sets the Autentica wallet address.
     *
     * Requirements:
     *
     * - the caller must be admin.
     */
    function setAutentica(address wallet) external returns (address) {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "NFTMarketplace: Only admins can change this"
        );

        // Keep a reference to the old address
        address oldAutentica = _autentica;

        // Change the address
        _autentica = wallet;

        // Emit the event
        emit ChangedAutentica(oldAutentica, _autentica);

        return _autentica;
    }

    /**
     * @dev Returns the number of decimals used for fees.
     */
    function decimals() external pure returns (uint8) {
        return DECIMALS;
    }

    /**
     * @dev Returns the number of allowed tokens.
     */
    function numberOfAllowedTokens() public view returns (uint256) {
        return _allowedTokens.length;
    }

    /**
     * @dev Returns the address of the allowed token at the specified index.
     * @param index The index of the allowed token.
     */
    function allowedTokenAtIndex(uint256 index) public view returns (address) {
        require(
            index < numberOfAllowedTokens(),
            "NFTMarketplace: Index out of bounds"
        );
        return _allowedTokens[index];
    }

    /**
     * @dev Verifies if a token address has been allowed already.
     */
    function isTokenAllowed(address tokenAddress) public view returns (bool) {
        for (uint256 i = 0; i < numberOfAllowedTokens(); i++) {
            if (_allowedTokens[i] == tokenAddress) {
                return true;
            }
        }

        return false;
    }

    /**
     * @dev Add a new allowed token to the contract.
     * @param tokenAddress The address of the allowed token to add.
     *
     * Requirements:
     *
     * - the caller must be admin.
     */
    function addAllowedToken(address tokenAddress) public {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "NFTMarketplace: Only admins can add allowed tokens"
        );

        // Check if the token address is valid
        require(
            tokenAddress != address(0),
            "NFTMarketplace: Token address is the zero address"
        );

        // Check if the token address is already allowed
        require(
            !isTokenAllowed(tokenAddress),
            "NFTMarketplace: Token address is already allowed"
        );

        // Add the token address
        _allowedTokens.push(tokenAddress);

        // Emit the event
        emit AllowedTokenAdded(tokenAddress);
    }

    /**
     * @dev Remove the allowed token at the specified index.
     * @param index The index of the allowed token.
     *
     * Requirements:
     *
     * - the caller must be admin.
     */
    function removeAllowedTokenAtIndex(uint256 index) public {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "NFTMarketplace: Only admins can remove allowed tokens"
        );

        // Check if the index is valid
        require(
            index < numberOfAllowedTokens(),
            "NFTMarketplace: Index out of bounds"
        );

        // Keep a reference to the old address
        address tokenAddress = _allowedTokens[index];

        // Deleting an element from the array does not affect the array length, so we need to use the `pop()` method
        if (numberOfAllowedTokens() == 1) {
            _allowedTokens.pop();
        } else {
            // Instead of shifting all the elements from the right, we will just move the last element in place of the
            // element that will be removed
            _allowedTokens[index] = _allowedTokens[numberOfAllowedTokens() - 1];
            // Remove the last element
            _allowedTokens.pop();
        }

        // Emit the event
        emit AllowedTokenRemoved(tokenAddress);
    }

    /**
     * @notice Trades an NFT for a given amount of coins (the native cryptocurrency of the platform, i.e.: ETH).
     *
     * @param collection The ERC-721 smart contract.
     * @param tokenId The unique identifier of the ERC-721 token within the `collection` smart contract.
     * @param price The price of the NFT in coins.
     * @param buyer Buyer address.
     * @param marketplaceFee Marketplace fee.
     * @param signature ECDSA signature.
     *
     * @dev Requirements
     *
     * - The `collection` smart contract must be an ERC-721 smart contract.
     * - The owner of the NFT identified by `tokenId` within the `collection` smart contract must have approved
     *   this smart contract to manage its NFTs.
     * - The `price` and `msg.value` must be equal.
     * - The sum of all the fees cannot be greater than 100%.
     * - The ECDSA signature must be signed by someone with the admin or operator role.
     */
    function tradeForCoins(
        address collection,
        uint256 tokenId,
        uint256 price,
        address buyer,
        uint256 marketplaceFee,
        Signature calldata signature
    ) external payable nonReentrant {
        // Check if the user sent enough coins
        require(msg.value == price, "NFTMarketplace: Not enough coins sent");

        // Validate the trade
        canPerformTrade(
            collection,
            tokenId,
            price,
            address(0x0),
            buyer,
            marketplaceFee,
            signature
        );

        NFT memory nft = _nftDetails(collection, tokenId);

        // Assemble the percentages
        Percentages memory percentages = _percentagesDetails(
            nft,
            getRoyaltyFee(collection, tokenId),
            getInvestorFee(collection, tokenId),
            marketplaceFee
        );

        // Assemble the fees
        Proceeds memory proceeds = Proceeds({
            creator: _calculateProceedsForFee(percentages.creator, price),
            investor: _calculateProceedsForFee(percentages.investor, price),
            marketplace: _calculateProceedsForFee(marketplaceFee, price)
        });

        // Calculate the base owner proceeds
        uint256 ownerProceeds = _calculateOwnerProceeds(
            price,
            proceeds
        );

        // Payments
        _sendViaCall(payable(nft.owner), ownerProceeds);
        if (proceeds.investor > 0) {
            _sendViaCall(payable(nft.investor), proceeds.investor);
        }
        if (proceeds.creator > 0) {
            _sendViaCall(payable(nft.creator), proceeds.creator);
        }
        if (proceeds.marketplace > 0) {
            _sendViaCall(payable(_autentica), proceeds.marketplace);
        }

        // Finally transfer the NFT
        IERC721(collection).safeTransferFrom(nft.owner, _msgSender(), tokenId);

        // Emit the event
        emit TradedForCoins(
            collection,
            tokenId,
            nft.owner,
            _msgSender(),
            price,
            ownerProceeds,
            proceeds.creator,
            proceeds.investor
        );
    }

    /**
     * @notice Trades an NFT for a given amount of ERC-20 tokens (i.e.: AUT/USDT/USDC).
     *
     * @param collection The ERC-721 smart contract.
     * @param tokenId The unique identifier of the ERC-721 token within the `collection` smart contract.
     * @param price The price of the NFT in `token` tokens.
     * @param token The ERC-20 smart contract.
     * @param buyer Buyer address.
     * @param marketplaceFee Marketplace fee.
     * @param signature ECDSA signature.
     *
     * Requirements:
     *
     * - The `collection` smart contract must be an ERC-721 smart contract.
     * - The owner of the NFT identified by `tokenId` within the `collection` smart contract must have approved
     *   this smart contract to manage its NFTs.
     * - The sum of all the fees cannot be greater than 100%.
     * - The ECDSA signature must be signed by someone with the admin or operator role.
     */
    function tradeForTokens(
        address collection,
        uint256 tokenId,
        uint256 price,
        address token,
        address buyer,
        uint256 marketplaceFee,
        Signature calldata signature
    ) external nonReentrant {
        // Check if the token is allowed
        require(isTokenAllowed(token), "NFTMarketplace: Token not allowed");

        // Validate the trade
        canPerformTrade(
            collection,
            tokenId,
            price,
            token,
            buyer,
            marketplaceFee,
            signature
        );

        // Assemble the NFT details
        NFT memory nft = _nftDetails(collection, tokenId);

        // Assemble the percentages
        Percentages memory percentages = _percentagesDetails(
            nft,
            getRoyaltyFee(collection, tokenId),
            getInvestorFee(collection, tokenId),
            marketplaceFee
        );

        // Assemble the fees
        Proceeds memory proceeds = Proceeds({
            creator: _calculateProceedsForFee(percentages.creator, price),
            investor: _calculateProceedsForFee(percentages.investor, price),
            marketplace: _calculateProceedsForFee(marketplaceFee, price)
        });

        // Calculate the base owner proceeds
        uint256 ownerProceeds = _calculateOwnerProceeds(
            price,
            proceeds
        );

        // Payments
        IERC20(token).transferFrom(buyer, nft.owner, ownerProceeds);
        if (proceeds.investor > 0) {
            IERC20(token).transferFrom(
                buyer,
                nft.investor,
                proceeds.investor
            );
        }
        if (proceeds.creator > 0) {
            IERC20(token).transferFrom(buyer, nft.creator, proceeds.creator);
        }
        if (proceeds.marketplace > 0) {
            IERC20(token).transferFrom(
                buyer,
                _autentica,
                proceeds.marketplace
            );
        }
        // Finally transfer the NFT
        IERC721(collection).safeTransferFrom(nft.owner, _msgSender(), tokenId);

        // Emit the event
        emit TradedForTokens(
            collection,
            tokenId,
            nft.owner,
            _msgSender(),
            token,
            price,
            ownerProceeds,
            proceeds.creator,
            proceeds.investor
        );
    }

    /**
     * @notice Validate the trade.
     *
     * @param collection The ERC-721 smart contract.
     * @param tokenId The unique identifier of the ERC-721 token within the `collection` smart contract.
     * @param price The price of the NFT in `token` tokens.
     * @param currency The type of currency (erc20 or native currency)
     * @param buyer Buyer address.
     * @param marketplaceFee Marketplace fee.
     * @param signature ECDSA signature.
     *
     */
    function canPerformTrade(
        address collection,
        uint256 tokenId,
        uint256 price,
        address currency,
        address buyer,
        uint256 marketplaceFee,
        Signature calldata signature
    ) public view returns (bool) {
        // Check if the contract is paused
        require(!paused(), "NFTMarketplace: Contract is paused");

        // Check if the collection is an ERC-721 smart contract
        _validateERC721(collection);

        // Assemble the NFT details
        NFT memory nft = _nftDetails(collection, tokenId);

        // Validate the approval
        _validateNFTApproval(collection, tokenId, nft);

        // Fees
        uint256 royaltyFee = getRoyaltyFee(collection, tokenId);
        uint256 investorFee = getInvestorFee(collection, tokenId);

        // Make sure that all the fees sumed up do not exceed 100%
        // 
        // Note: The investor fee is ignored from the validation
        // because that fee represents a percetange of the
        // royalty fee.
        _validateFees(royaltyFee, marketplaceFee);

        // Make sure the parameters are valid
        require(
            _validateTrade(
                collection,
                tokenId,
                nft.owner,
                buyer,
                price,
                currency,
                royaltyFee,
                investorFee,
                marketplaceFee,
                signature
            ),
            "NFTMarketplace: Invalid signature"
        );
        return true;
    }

    /**
     * @notice If the collection smart contract implements `IERC721Autentica` or `IERC2981` then 
     * the function returns the royalty fee from that smart contract, otherwise it will return 0.
     *
     * @param collection The ERC-721 smart contract.
     * @param tokenId The unique identifier of the ERC-721 token within the `collection` smart contract.
     *
     */
    function getRoyaltyFee(address collection, uint256 tokenId)
        public
        view
        returns (uint256)
    {
        uint256 royaltyFee = 0;

        if (ERC165Checker.supportsInterface(collection, type(IERC721Autentica).interfaceId)) {
            // This is a smart contract implementing `IERC721Autentica`
            royaltyFee = _normalizedFee(
                IERC721Autentica(collection),
                IERC721Autentica(collection).getRoyaltyFee(tokenId)
            );
        } else if (ERC165Checker.supportsInterface(collection, type(IERC2981).interfaceId)) {
            // This is a smart contract implementing `IERC2981`
            (, royaltyFee) = IERC2981(collection).royaltyInfo(tokenId, 100 * (10 ** DECIMALS));
            // The reason for why we use `100 * (10 ** DECIMALS)` as the sale price is because other
            // we don't want to lose precision when calculating the fee.
        }
        return royaltyFee;
    }

    /**
     * @notice If the collection smart contract implements `IERC721Autentica` then the function 
     * returns the investor fee from that smart contract, otherwise it will return 0.
     *
     * @param collection The ERC-721 smart contract.
     * @param tokenId The unique identifier of the ERC-721 token within the `collection` smart contract.
     *
     */
    function getInvestorFee(address collection, uint256 tokenId)
        public
        view
        returns (uint256)
    {
        uint256 investorFee = 0;
        if (ERC165Checker.supportsInterface(collection, type(IERC721Autentica).interfaceId)) {
            // This is a smart contract implementing `IERC721Autentica`
            investorFee = _normalizedFee(
                IERC721Autentica(collection),
                IERC721Autentica(collection).getInvestorFee(tokenId)
            );
        }
        return investorFee;
    }

    /**
     * @dev Verifies if the token owner has approved this smart contract to manage its 
     * NFTs from the specified collection.
     * @return Returns `true` if this smart contract is approved by the `tokenOwner` in 
     * the `collection` smart contract or only if that specific NFT is approved for this smart contract.
     */
    function isMarketplaceApproved(
        IERC721 collection,
        uint256 tokenId,
        address tokenOwner
    ) public view returns (bool) {
        return
            collection.getApproved(tokenId) == address(this) ||
            collection.isApprovedForAll(tokenOwner, address(this));
    }

    /**
     * @notice Pause the contract.
     *
     * Requirements:
     *
     * - the caller must be admin.
     */
    function pause() public {
        // Make sure that only admins can pause the contract
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "NFTMarketplace: Only admins can pause"
        );

        // Do it
        _pause();
    }

    /**
     * @notice Unpause the contract.
     *
     * Requirements:
     *
     * - the caller must be admin.
     */
    function unpause() public {
        // Make sure that only admins can unpause the contract
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "NFTMarketplace: Only admins can unpause"
        );

        // Do it
        _unpause();
    }

    /**
     * @dev Function to transfer coins (the native cryptocurrency of the 
     * platform, i.e.: ETH) from this contract to the specified address.
     *
     * @param to - Address where to transfer the coins
     * @param amount - Amount (in wei)
     *
     */
    function _sendViaCall(address payable to, uint256 amount) private {
        (bool sent, ) = to.call{value: amount}("");
        require(sent, "NFTMarketplace: Failed to send coins");
    }

    /**
     * Returns `true` if the signer has the admin or the operator role.
     *
     * @param collection The ERC-721 smart contract.
     * @param tokenId The unique identifier of the ERC-721 token within the `collection` smart contract.
     * @param buyer Seller address.
     * @param buyer Buyer address.
     * @param price Price of the NFT expressed in coins or tokens.
     * @param token The ERC-20 smart contract address.
     * @param royaltyFee Royalty fee.
     * @param investorFee Investor fee.
     * @param marketplaceFee Marketplace fee.
     * @param signature ECDSA signature.
     */
    function _validateTrade(
        address collection,
        uint256 tokenId,
        address seller,
        address buyer,
        uint256 price,
        address token,
        uint256 royaltyFee,
        uint256 investorFee,
        uint256 marketplaceFee,
        Signature calldata signature
    ) private view returns (bool) {
        bytes32 hash = keccak256(
            abi.encode(
                address(this),
                collection,
                tokenId,
                seller,
                buyer,
                price,
                token,
                royaltyFee,
                investorFee,
                marketplaceFee
            )
        );

        address signer = ecrecover(
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            ),
            signature.v,
            signature.r,
            signature.s
        );

        return
            hasRole(DEFAULT_ADMIN_ROLE, signer) ||
            hasRole(OPERATOR_ROLE, signer);
    }

    /**
     * @dev Returns the fee normalized to the number of decimals used in this smart contract.
     *
     * @param collection The Autentica ERC-721 smart contract.
     * @param fee Value represented using the number of decimals used by the `collection` smart contract.
     */
    function _normalizedFee(IERC721Autentica collection, uint256 fee)
        private
        view
        returns (uint256)
    {
        return (fee * (10**DECIMALS)) / (10**collection.decimals());
    }

    /**
     * @dev Returns the number of coins/tokens for a given fee percentage.
     */
    function _calculateProceedsForFee(uint256 fee, uint256 price)
        private
        pure
        returns (uint256)
    {
        if (fee == 0) {
            return 0;
        }

        // Price * Fee (which is already multiplied by 10**DECIMALS) / 100% multiplied by 10**DECIMALS
        return (price * fee) / (100 * 10**DECIMALS);
    }

    /**
     * Returns the owner proceeds.
     */
    function _calculateOwnerProceeds(
        uint256 price,
        Proceeds memory proceeds
    ) private pure returns (uint256) {
        return
            price -
            proceeds.marketplace -
            proceeds.creator -
            proceeds.investor;
    }

    /**
     * @dev Makes sure that the `collection` is a valid ERC-721 smart contract.
     */
    function _validateERC721(address collection) private view {
        require(
            ERC165Checker.supportsInterface(
                collection,
                type(IERC721).interfaceId
            ),
            "NFTMarketplace: Collection does not support the ERC-721 interface"
        );
    }

    /**
     * @dev Makes sure that the owner approved this smart contract for the token.
     */
    function _validateNFTApproval(
        address collection,
        uint256 tokenId,
        NFT memory nft
    ) private view {
        require(
            isMarketplaceApproved(IERC721(collection), tokenId, nft.owner),
            "NFTMarketplace: Owner has not approved us for managing its NFTs"
        );
    }

    /**
     * @dev Make sure that all the fees sumed up do not exceed 100%.
     */
    function _validateFees(
        uint256 royaltyFee,
        uint256 marketplaceFee
    ) private pure {
        require(
            royaltyFee + marketplaceFee <= 100 * 10**DECIMALS,
            "NFTMarketplace: Total fees cannot be greater than 100%"
        );
    }

    /**
     * @dev Returns the NFT details.
     *
     * @param collection The ERC-721 smart contract.
     * @param tokenId The unique identifier of the ERC-721 token within the `collection` smart contract.
     */
    function _nftDetails(address collection, uint256 tokenId)
        private
        view
        returns (NFT memory)
    {
        // Assemble the NFT details
        NFT memory nft = NFT({
            owner: IERC721(collection).ownerOf(tokenId),
            creator: address(0x0), // Will get overriden below if this is a Autentica ERC-721 collection
            investor: address(0x0) // Will get overriden below if this is a Autentica ERC-721 collection
        });

        // Update the information about the creator and investor
        if (ERC165Checker.supportsInterface(collection, type(IERC721Autentica).interfaceId)) {
            // This is a smart contract implementing `IERC721Autentica`
            nft.creator = IERC721Autentica(collection).getCreator(tokenId);
            nft.investor = IERC721Autentica(collection).getInvestor(tokenId);
        } else if (ERC165Checker.supportsInterface(collection, type(IERC2981).interfaceId)) {
            // This is a smart contract implementing `IERC2981`
            (nft.creator, ) = IERC2981(collection).royaltyInfo(tokenId, 100 * (10 ** DECIMALS));
            // The reason for why we use `100 * (10 ** DECIMALS)` as the sale price is because other
            // implementations of `ERC-2981` may return `address(0x0)` for the 
            // `receiver` if the values are too low or zero.
        }

        return nft;
    }

    /**
     * @dev Returns the Percentages details.
     *
     * @param nft NFT details.
     * @param royaltyFee Royalty fee.
     * @param investorFee Investor fee.
     * @param marketplaceFee Marketplace fee.
     */
    function _percentagesDetails(
        NFT memory nft,
        uint256 royaltyFee,
        uint256 investorFee,
        uint256 marketplaceFee
    ) private pure returns (Percentages memory) {
        Percentages memory percentages = Percentages({creator: 0, investor: 0});

        if (nft.owner == nft.creator) {
            // CASE 1: The NFT is owned by the creator

            if (nft.investor != address(0x0) && investorFee > 0) {
                // CASE 1.1: The investor will receive X% from the creator/owner's end
                percentages.investor = (investorFee * ((100 * 10**DECIMALS) - marketplaceFee)) / (100 * 10**DECIMALS);
            }
        } else {
            // CASE 2: The NFT is owned by someone else

            if (nft.creator != address(0x0) && royaltyFee > 0) {
                // CASE 2.1: The creator will get payed too
                percentages.creator = royaltyFee;

                if (nft.investor != address(0x0) && investorFee > 0) {
                    // CASE 1.1: The investor will receive X% from the creator's end
                    
                    // Calculate the investor fee
                    percentages.investor = (investorFee * percentages.creator) / (100 * 10**DECIMALS);
                    // Shrink the creator fee
                    percentages.creator = percentages.creator - percentages.investor;
                }
            }
        }

        return percentages;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.15 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IERC721Autentica is IERC721 {
    /**
     * @dev Number of decimals used for fees.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the Royalty fee of the `tokenId` token.
     * @param tokenId NFT ID.
     */
    function getRoyaltyFee(uint256 tokenId) external view returns (uint256);

    /**
     * @dev Returns the Investor fee of the `tokenId` token.
     * @param tokenId NFT ID.
     */
    function getInvestorFee(uint256 tokenId) external view returns (uint256);

    /**
     * @dev Returns the creator of the `tokenId` token.
     * @param tokenId NFT ID.
     *
     * NOTE: The Autentica Marketplace smart contract supports royalties, so in order for the
     * creator to be paid, we need to know who created the token and that information must
     * stay the same even if the person who owns the token changes.
     */
    function getCreator(uint256 tokenId) external view returns (address);

    /**
     * @dev Returns the investor of the `tokenId` token.
     * @param tokenId NFT ID.
     *
     * NOTE: Autentica lets other people to pay for the gas fees of the token minting so
     * in that case the minter is not the creator and owner of the token.
     */
    function getInvestor(uint256 tokenId) external view returns (address);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            _supportsERC165Interface(account, type(IERC165).interfaceId) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);
        (bool success, bytes memory result) = account.staticcall{gas: 30000}(encodedParams);
        if (result.length < 32) return false;
        return success && abi.decode(result, (bool));
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}