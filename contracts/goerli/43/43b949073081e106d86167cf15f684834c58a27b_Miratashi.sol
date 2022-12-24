//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721M.sol";
import "./IERC165.sol";
import "./ERC2981.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";

////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//     ███╗   ███╗██╗██████╗  █████╗ ████████╗ █████╗ ███████╗██╗  ██╗██╗     //
//     ████╗ ████║██║██╔══██╗██╔══██╗╚══██╔══╝██╔══██╗██╔════╝██║  ██║██║     //
//     ██╔████╔██║██║██████╔╝███████║   ██║   ███████║███████╗███████║██║     //
//     ██║╚██╔╝██║██║██╔══██╗██╔══██║   ██║   ██╔══██║╚════██║██╔══██║██║     //
//     ██║ ╚═╝ ██║██║██║  ██║██║  ██║   ██║   ██║  ██║███████║██║  ██║██║     //
//     ╚═╝     ╚═╝╚═╝╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝     //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////

/* ==================================================================
 * 🔥 Miratashi.sol
 *
 * 👨🏽‍💻 Author: funcTh4natos
 *
 * 🎉 Special thanks goes to: VinzMIRATASHI
 * ==================================================================
 */

/**
 * Subset of the IOperatorFilterRegistry with only the methods that the main minting contract will call.
 * The owner of the collection is able to manage the registry subscription on the contract's behalf
 */
interface IOperatorFilterRegistry {
    function isOperatorAllowed(
        address registrant,
        address operator
    ) external returns (bool);
}

/// @custom:security-contact [email protected]
contract Miratashi is ERC721M, Ownable, ERC2981, ReentrancyGuard {
    // =============================================================
    //                            Structs
    // =============================================================

    // Struct for storing batch price data.
    struct TokenBatchPriceData {
        uint128 pricePaid;
        uint8 quantityMinted;
    }

    // =============================================================
    //                            Constants
    // =============================================================

    string public constant TOKEN_BASE_EXTENSION = ".json";

    // Founder address
    address public constant FOUNDER_ADDRESS =
        0x8c332d8183E00a0a996576f7998Aa0CA77349813;

    // Team treasury address
    address public constant TEAM_TREASURY_ADDRESS =
        0x8c332d8183E00a0a996576f7998Aa0CA77349813;

    // Owner will be minting this amount to the treasury which happens before
    // any whitelist or regular sale. Once totalSupply() is over this amount,
    // no more can get minted by {mintTeamTreasury}
    uint256 public constant TEAM_TREASURY_SUPPLY = 400;

    // The quantity for whitelist mint
    uint256 public constant WHITELIST_MINT_QUANTITY = 6100;

    // The quantity for dutch auction mint
    uint256 public constant DUTCH_AUCTION_MINT_QUANTITY = 3500;

    // Public mint is unlikely to be enabled as it will get botted, but if
    // is needed this will make it a tiny bit harder to bot the entire remaining.
    uint256 public constant MAX_MINT_TXN_SIZE = 2;

    // =============================================================
    //                            Storage
    // =============================================================

    string public tokenBaseURI;

    // Delay revealed active variable
    bool public isRevealed = false;

    // Address that houses the implemention to check if operators are allowed or not
    address public operatorFilterRegistryAddress;
    // Address this contract verifies with the registryAddress for allowed operators
    address public filterRegistrant;

    // Address used for mint which will be a majority of the transactions
    address public signer;
    // Used to quickly invalidate batches of signatures if needed
    uint256 public signatureVersion;

    // Token to token price data
    mapping(address => TokenBatchPriceData[]) public userToTokenBatchPriceData;

    modifier callerIsUser() {
        require(
            tx.origin == msg.sender,
            "Miratashi: The caller is another contract"
        );
        _;
    }

    // =============================================================
    //                            Whitelist Storage
    // =============================================================

    // Active variable
    bool public isWhitelistActive = false;

    // Whitelist price
    uint256 public whitelistPrice;

    // Starting whitelist time (seconds). Ending whitelist time in 2 hours (7200 seconds)
    uint256 public whitelistStartingTime;
    uint256 public whitelistDuration = 7200;

    // Whitelist
    mapping(address => bool) public walletWhitelist;

    // Whitelist wallet addresses
    mapping(address => uint8) public walletWhitelistMinted;

    // Whitelist minted count
    uint256 public whitelistMinted;

    // =============================================================
    //                            Dutch Auction Storage
    // =============================================================

    // Active variable
    bool public isAuctionActive = false;

    // Continue until Whitelist phase
    uint256 public auctionStartingTime =
        whitelistStartingTime + whitelistDuration;

    // Starting price
    uint256 public auctionStartingPrice;

    // Ending price
    uint256 public auctionEndingPrice = 0 ether;

    // Final auction price
    uint256 public auctionFinalPrice;

    // Decrement
    uint256 public auctionPriceDecrement;
    uint256 public auctionDecrementFrequency;

    // =============================================================
    //                          Constructor
    // =============================================================

    constructor() ERC721M("Miratashi", "MIRA") {}

    /**
     * @dev Returns the starting token ID.
     * To change the starting token ID, please override this function.
     */
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721M, ERC2981) returns (bool) {
        // The interface IDs are constants representing the first 4 bytes
        // of the XOR of all function selectors in the interface.
        // See: [ERC165](https://eips.ethereum.org/EIPS/eip-165)
        // (e.g. `bytes4(i.functionA.selector ^ i.functionB.selector ^ ...)`)
        return
            ERC721M.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    // =============================================================
    //                           IERC2981
    // =============================================================

    /**
     * @notice Allows the owner to set default royalties following EIP-2981 royalty standard.
     */
    function setDefaultRoyalty(
        address receiver,
        uint96 feeNumerator
    ) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    // =============================================================
    //                 Operator Filter Registry
    // =============================================================
    /**
     * @dev Stops operators from being added as an approved address to transfer.
     * @param operator the address a wallet is trying to grant approval to.
     */
    function _beforeApproval(address operator) internal virtual override {
        if (operatorFilterRegistryAddress.code.length > 0) {
            if (
                !IOperatorFilterRegistry(operatorFilterRegistryAddress)
                    .isOperatorAllowed(filterRegistrant, operator)
            ) {
                revert OperatorNotAllowed();
            }
        }
        super._beforeApproval(operator);
    }

    /**
     * @dev Stops operators that are not approved from doing transfers.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 tokenId,
        uint256 quantity
    ) internal virtual override {
        if (operatorFilterRegistryAddress.code.length > 0) {
            if (
                !IOperatorFilterRegistry(operatorFilterRegistryAddress)
                    .isOperatorAllowed(filterRegistrant, msg.sender)
            ) {
                revert OperatorNotAllowed();
            }
        }
        // Expiration time represented in hours. multiply by 60 * 60, or 3600.
        if (_getExtraDataAt(tokenId) * 3600 > block.timestamp)
            revert TokenTransferLocked();
        super._beforeTokenTransfers(from, to, tokenId, quantity);
    }

    /**
     * @notice Allows the owner to set a new registrant contract.
     */
    function setOperatorFilterRegistryAddress(
        address registryAddress
    ) external onlyOwner {
        operatorFilterRegistryAddress = registryAddress;
    }

    /**
     * @notice Allows the owner to set a new registrant address.
     */
    function setFilterRegistrant(address newRegistrant) external onlyOwner {
        filterRegistrant = newRegistrant;
    }

    // =============================================================
    //                   Whitelist Mint Method
    // =============================================================

    function mintWhitelist() external payable callerIsUser {
        // Check if whitelist phase is active
        if (!isWhitelistActive) revert WhitelistMintNotActive();

        // Check if wallet was in whitelist
        if (!walletWhitelist[msg.sender]) revert YouAreNotWhitelist();

        // Max supply
        if (whitelistMinted + 1 <= WHITELIST_MINT_QUANTITY)
            revert OverWhitelistMintSupplyLimit();

        // Mint only once during the first 30 minutes (1800 seconds)
        if (
            walletWhitelistMinted[msg.sender] > 0 &&
            block.timestamp <= whitelistStartingTime + 1800
        ) revert OverDuringFirstHalfHourLimit();

        // Mint only 2 times
        if (walletWhitelistMinted[msg.sender] >= 2)
            revert OverWhitelistMintLimit();

        // Require whitelist started
        if (block.timestamp <= whitelistStartingTime)
            revert WhitelistMintNotLive();

        if (block.timestamp >= (whitelistStartingTime + whitelistDuration))
            revert WhitelistMintHasFinished();

        // Require enough ETH
        if (msg.value <= whitelistPrice) revert MsgValueNotEnough();

        // Increase wallet addesss minted count
        walletWhitelistMinted[msg.sender]++;

        // Increase whitelist minted count
        whitelistMinted++;

        _safeMint(msg.sender, 1);
    }

    // =============================================================
    //                   Dutch Auction Method
    // =============================================================

    function mintDutchAuction(uint8 quantity) external payable callerIsUser {
        // Check is active
        if (!isAuctionActive) revert AuctionMintNotActive();

        // Max supply
        if (remainingSupply() < quantity) revert OverMintLimit();

        // Require dutch auction started
        if (block.timestamp <= auctionStartingTime) revert AuctionMintNotLive();

        // Require max 2 per tx
        if (quantity > 2) revert OverMaxPerTransaction();

        uint256 _currentPrice = currentPrice();
        /// Require enough ETH
        if (msg.value >= quantity * _currentPrice) revert MsgValueNotEnough();

        // This calculates the final price
        if (
            totalSupply() + quantity ==
            (WHITELIST_MINT_QUANTITY + DUTCH_AUCTION_MINT_QUANTITY)
        ) {
            auctionFinalPrice = _currentPrice;
        }

        // Saving wallet mint price data
        userToTokenBatchPriceData[msg.sender].push(
            TokenBatchPriceData(uint128(msg.value), quantity)
        );

        _safeMint(msg.sender, quantity);
    }

    // =============================================================
    //                   External Mint Methods
    // =============================================================

    /**
     * @notice Allows the owner to mint from treasury supply.
     */
    function mintTeamTreasury() external onlyOwner {
        _mint(TEAM_TREASURY_ADDRESS, TEAM_TREASURY_SUPPLY);
    }

    function remainingSupply() public view returns (uint256) {
        return
            (WHITELIST_MINT_QUANTITY + DUTCH_AUCTION_MINT_QUANTITY) -
            totalSupply();
    }

    function currentPrice() public view returns (uint256) {
        if (block.timestamp <= auctionStartingTime) revert AuctionMintNotLive();

        if (auctionFinalPrice > 0) return auctionFinalPrice;

        // Seconds since we started
        uint256 timeSinceStart = block.timestamp - auctionStartingTime;

        // How many decrements should've happened since that time
        uint256 decrementsSinceStart = timeSinceStart /
            auctionDecrementFrequency;

        // How much ETH to remove
        uint256 totalDecrement = decrementsSinceStart * auctionPriceDecrement;

        // If how much we want to reduce is greater or equal to the range, return the lowest value
        if (totalDecrement >= auctionStartingPrice - auctionEndingPrice) {
            return auctionEndingPrice;
        }

        // If not, return the starting price minus the decrement.
        return auctionStartingPrice - totalDecrement;
    }

    // =============================================================
    //                        Token Metadata
    // =============================================================

    /**
     * @notice Allows the owner to set the base token URI.
     */
    function setBaseURI(string memory _baseURI) external onlyOwner {
        tokenBaseURI = _baseURI;
    }

    function tokenURI(
        uint256 _tokenId
    ) public view override returns (string memory) {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (!isRevealed)
            return
                string(
                    abi.encodePacked(tokenBaseURI, "0", TOKEN_BASE_EXTENSION)
                );

        return
            string(
                abi.encodePacked(
                    tokenBaseURI,
                    Strings.toString(_tokenId),
                    TOKEN_BASE_EXTENSION
                )
            );
    }

    // =============================================================
    //                        Miscellaneous
    // =============================================================

    /**
     * @notice Allows the owner to withdraw a specified amount of ETH to a specified address.
     */
    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    /**
     * @notice Allows the owner to add specified wallet address of whitelisted to this smart contract.
     */
    function addToWhitelist(
        address[] calldata toAddAddresses
    ) external onlyOwner {
        for (uint256 i = 0; i < toAddAddresses.length; i++) {
            walletWhitelist[toAddAddresses[i]] = true;
        }
    }

    /**
     * @notice Allows the owner to remove specified wallet address of whitelisted from this smart contract.
     */
    function removeFromWhitelist(
        address[] calldata toRemoveAddresses
    ) external onlyOwner {
        for (uint256 i = 0; i < toRemoveAddresses.length; i++) {
            delete walletWhitelist[toRemoveAddresses[i]];
        }
    }

    /**
     * @notice Allows the owner to set a new price of whitelist phase.
     */
    function setWhitelistPrice(uint256 newPrice) external onlyOwner {
        whitelistPrice = newPrice;
    }

    /**
     * @notice Allows the owner to set active status of whitelist phase.
     */
    function setWhitelistActive(bool isActive) external onlyOwner {
        isWhitelistActive = isActive;
    }

    /**
     * @notice Allows the owner to set active status of dutch auction phase.
     */
    function setDutchAuctionActive(bool isActive) external onlyOwner {
        isAuctionActive = isActive;
    }

    /**
     * @notice Allows the owner to set specified time of whitelist phase.
     */
    function setWhitelistStartTime(uint256 startTime) external onlyOwner {
        whitelistStartingTime = startTime;
    }

    /**
     * @notice Allows the owner to set delay revealed.
     */
    function setRevealData(bool _isRevealed) external onlyOwner {
        isRevealed = _isRevealed;
    }

    function userToTokenBatch(
        address user
    ) public view returns (TokenBatchPriceData[] memory) {
        return userToTokenBatchPriceData[user];
    }

    // Whitelist errors
    error WhitelistMintNotActive();
    error YouAreNotWhitelist();
    error OverWhitelistMintSupplyLimit();
    error OverDuringFirstHalfHourLimit();
    error OverWhitelistMintLimit();
    error WhitelistMintNotLive();
    error WhitelistMintHasFinished();
    // Auction errors
    error AuctionMintNotActive();
    error AuctionMintNotLive();
    error AuctionMintHasFinished();
    // External mint errors
    error MsgValueNotEnough();
    error OverMaxPerTransaction();
    error OverTeamTreasurySupplyLimit();
    error OverMintLimit();
    // Operator filter registry errors
    error OperatorNotAllowed();
    error TokenTransferLocked();
}