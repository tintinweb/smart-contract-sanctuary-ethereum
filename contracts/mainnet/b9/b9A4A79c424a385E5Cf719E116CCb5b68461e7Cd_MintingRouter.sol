//SPDX-License-Identifier: UNLICENSED

// ███████╗███╗   ██╗███████╗ █████╗ ██╗  ██╗██╗   ██╗     ██████╗  ██████╗ ██████╗ ██╗     ██╗███╗   ██╗███████╗
// ██╔════╝████╗  ██║██╔════╝██╔══██╗██║ ██╔╝╚██╗ ██╔╝    ██╔════╝ ██╔═══██╗██╔══██╗██║     ██║████╗  ██║██╔════╝
// ███████╗██╔██╗ ██║█████╗  ███████║█████╔╝  ╚████╔╝     ██║  ███╗██║   ██║██████╔╝██║     ██║██╔██╗ ██║███████╗
// ╚════██║██║╚██╗██║██╔══╝  ██╔══██║██╔═██╗   ╚██╔╝      ██║   ██║██║   ██║██╔══██╗██║     ██║██║╚██╗██║╚════██║
// ███████║██║ ╚████║███████╗██║  ██║██║  ██╗   ██║       ╚██████╔╝╚██████╔╝██████╔╝███████╗██║██║ ╚████║███████║
// ╚══════╝╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝        ╚═════╝  ╚═════╝ ╚═════╝ ╚══════╝╚═╝╚═╝  ╚═══╝╚══════╝

pragma solidity 0.8.13;

// Imports
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./EIP712Whitelisting.sol";

/// NFT Interface
interface INFT {
    function mint(address recipient, uint256 quantity) external;
    function preminted() external view returns (bool);
    function MAX_SUPPLY() external view returns(uint256);
    function totalSupply() external view returns(uint256);
}

/**
 * @title The Minting Router contract.
 */
contract MintingRouter is EIP712Whitelisting, ReentrancyGuard, Ownable {
    // The available sale types.
    enum SaleRoundType {
        WHITELIST,
        PUBLIC
    }

    // The sale round details.
    struct SaleRound {
        // The type of the sale.
        SaleRoundType saleType;
        // The price of a token during the sale round.
        uint256 price;
        // The total number of tokens available for minting during the sale round.
        uint256 totalAmount;
        // The total number of tokens available for minting by a single wallet during the sale round.
        uint256 limitAmountPerWallet;
        // The maximum number of tokens available for minting per single transaction.
        uint256 maxAmountPerMint;
        // The flag that indicates if the sale round is enabled.
        bool enabled;
    }

    /// @notice Indicates that tokens are unlimited.
    uint256 private constant UNLIMITED_AMOUNT = 0;
    /// @notice The current sale round details.
    SaleRound public saleRound;
    /// @notice The current sale round index.
    uint256 public currentSaleIndex;
    /// @notice The number of NFTs minted during an ongoing sale round.
    uint256 public totalMintedAmountCurrentRound;
    /// @notice The number of NFTs minted during a sale round.
    mapping(uint256 => uint256) public mintedAmountPerRound;
    /// @notice The NFT contract.
    INFT private _nftContract;
    /// @notice The number of NFTs minted during a sale round per wallet.
    mapping(uint256 => mapping(address => uint256)) private _mintedAmountPerAddress;

    /**
     * @notice The smart contract constructor that initializes the minting router.
     * @param nftContract_ The NFT contract.
     * @param tokenName The name of the NFT token.
     * @param version The version of the project.
     */
    constructor(INFT nftContract_, string memory tokenName, string memory version) EIP712Whitelisting(tokenName, version)   {
        // Initialize the variables.
        _nftContract = nftContract_;
        // Set the initial dummy value for the current sale index.
        currentSaleIndex = type(uint256).max;
    }

    /**
     * @notice Changes the current sale details.
     * @param price The price of an NFT for the current sale round.
     * @param totalAmount The total amount of NFTs available for the current sale round.
     * @param limitAmountPerWallet The total number of NFTs that can be minted by a single wallet during the sale round.
     * @param maxAmountPerMint The maximum number of tokens available for minting per single transaction.
     */
    function changeSaleRoundParams(
        uint256 price,
        uint256 totalAmount,
        uint8 limitAmountPerWallet,
        uint256 maxAmountPerMint
    ) external onlyOwner {
        saleRound.price = price;
        saleRound.totalAmount = totalAmount;
        saleRound.limitAmountPerWallet = limitAmountPerWallet;
        saleRound.maxAmountPerMint = maxAmountPerMint;
    }

    /**
     * @notice Creates a new sale round.
     * @dev Requires sales to be disabled and reserves to be minted.
     * @param saleType The type of the sale round (WHITELIST - 0, PUBLIC SALE - 1).
     * @param price The price of an NFT for the current sale round.
     * @param totalAmount The total amount of NFTs available for the current sale round.
     * @param limitAmountPerWallet The total number of NFTs that can be minted by a single wallet during the sale round.
     * @param maxAmountPerMint The maximum number of tokens available for minting per single transaction.
     */
    function createSaleRound(
        SaleRoundType saleType,
        uint256 price,
        uint256 totalAmount,
        uint256 limitAmountPerWallet,
        uint256 maxAmountPerMint
    ) external onlyOwner {
        // Check if the reserves are minted.
        bool preminted = _nftContract.preminted();
        require(preminted == true, "Must mint reserved tokens");
        // Check if the sales are closed.
        require(saleRound.enabled == false, "Must disable the current round");
        // Increment the sale round index.
        if (currentSaleIndex == type(uint256).max) {
            currentSaleIndex = 0;
        } else {
            currentSaleIndex += 1;
        }
        // Set new sale parameters.
        saleRound.price = price;
        saleRound.totalAmount = totalAmount;
        saleRound.limitAmountPerWallet = limitAmountPerWallet;
        saleRound.maxAmountPerMint = maxAmountPerMint;
        saleRound.saleType = saleType;

        // Reset the number of tokens minted during the round.
        totalMintedAmountCurrentRound = 0;
    }

    /**
     * @notice Starts the sale round.
     */
    function enableSaleRound() external onlyOwner {
        require(saleRound.enabled == false, "Sale round was already enabled");
        saleRound.enabled = true;
    }

    /**
     * @notice Closes the sale round.
     */
    function disableSaleRound() external onlyOwner {
        require(saleRound.enabled == true, "Sale round was already disabled");
        saleRound.enabled = false;
    }

    /**
     * @notice Mints NFTs during whitelist sale rounds.
     * @dev Requires the current sale round to be a WHITELIST round.
     * @param recipient The address that will receive the minted NFT.
     * @param quantity The number of NFTs to mint.
     * @param signature The signature of a whitelisted minter.
     */
    function whitelistMint(address recipient, uint256 quantity, bytes calldata signature) external payable requiresWhitelist(signature) nonReentrant {
        require(saleRound.saleType == SaleRoundType.WHITELIST, "Not a whitelist round");
        _mint(msg.value, recipient, quantity);
    }

    /**
     * @notice Mints NFTs during public sale rounds.
     * @dev Requires the current sale round to be a PUBLIC round.
     * @param recipient The address that will receive the minted NFT.
     * @param quantity The number of NFTs to mint.
     */
    function publicMint(address recipient, uint256 quantity) external payable nonReentrant {
        require(saleRound.saleType == SaleRoundType.PUBLIC, "Not a public round");
        _mint(msg.value, recipient, quantity);
    }

    /**
     * @notice Sets the address that is used during whitelist generation.
     * @param signer The address used during whitelist generation.
     */
    function setWhitelistSigningAddress(address signer) public onlyOwner {
        _setWhitelistSigningAddress(signer);
    }

    /**
     * @notice Withdraws funds to the owner wallet.
     */
    function withdraw() public onlyOwner returns(bool) {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
        return true;
    }

    /**
     * @notice Calculates the number of tokens a minter is allowed to mint.
     * @param minter The minter address.
     * @return The number of tokens that a minter can mint.
     */
    function allowedTokenCount(address minter) public view returns (uint256) {
        if (saleRound.enabled == false) {
            return 0;
        }
        // Calculate the allowed number of tokens to mint by a wallet.
        uint256 allowedWalletCount = saleRound.limitAmountPerWallet != UNLIMITED_AMOUNT
        ? (saleRound.limitAmountPerWallet > _mintedAmountPerAddress[currentSaleIndex][minter]
        ? saleRound.limitAmountPerWallet - _mintedAmountPerAddress[currentSaleIndex][minter] : 0)
        : _nftContract.MAX_SUPPLY() - _nftContract.totalSupply();
        // Calculate the total number of tokens left.
        uint256 availableTokenCount = saleRound.totalAmount != UNLIMITED_AMOUNT
        ? (saleRound.totalAmount > mintedAmountPerRound[currentSaleIndex]
        ? saleRound.totalAmount - mintedAmountPerRound[currentSaleIndex] : 0)
        : _nftContract.MAX_SUPPLY() - _nftContract.totalSupply();
        // Calculate the limit of the number of tokens per single mint.
        uint256 allowedAmountPerMint = saleRound.maxAmountPerMint != UNLIMITED_AMOUNT
        ? saleRound.maxAmountPerMint : _nftContract.MAX_SUPPLY() - _nftContract.totalSupply();
        // Get the minimum of all values.
        uint256 allowedTokens = allowedWalletCount < availableTokenCount ? allowedWalletCount : availableTokenCount;
        allowedTokens = allowedAmountPerMint < allowedTokens ? allowedAmountPerMint : allowedTokens;
        return allowedTokens;
    }

    /**
     * @notice Returns the number of tokens left for the running sale round.
     */
    function tokensLeft() public view returns (uint256) {
        if (saleRound.enabled == false) {
            return 0;
        }

        return saleRound.totalAmount != UNLIMITED_AMOUNT
        ? (saleRound.totalAmount > mintedAmountPerRound[currentSaleIndex]
        ? saleRound.totalAmount - mintedAmountPerRound[currentSaleIndex] : 0)
        : _nftContract.MAX_SUPPLY() - _nftContract.totalSupply();
    }

    /**
     * @notice Mints NFTs.
     * @param value The purchase fee.
     * @param recipient The address that will receive the minted NFT.
     * @param quantity The number of NFTs to mint.
     */
    function _mint(uint256 value, address recipient, uint256 quantity) private {
        require(saleRound.enabled == true, "Sale round is disabled");
        require(quantity > 0, "Quantity must be > 0");

        if (saleRound.maxAmountPerMint != UNLIMITED_AMOUNT) {
            require(quantity <= saleRound.maxAmountPerMint, "Max mint amount exceeded");
        }

        if (saleRound.totalAmount != UNLIMITED_AMOUNT) {
            require(totalMintedAmountCurrentRound + quantity <= saleRound.totalAmount, "Max sale amount reached");
        }

        if (saleRound.limitAmountPerWallet != UNLIMITED_AMOUNT) {
            uint256 mintedAmountSoFar = _mintedAmountPerAddress[currentSaleIndex][recipient];
            require(mintedAmountSoFar + quantity <= saleRound.limitAmountPerWallet, "Max minted per address reached");
        }

        require(value >= saleRound.price * quantity, "Insufficient funds");
        _nftContract.mint(recipient, quantity);
        totalMintedAmountCurrentRound += quantity;
        // update total minted amount of this address
        _mintedAmountPerAddress[currentSaleIndex][recipient] += quantity;
        mintedAmountPerRound[currentSaleIndex] += quantity;
    }
}