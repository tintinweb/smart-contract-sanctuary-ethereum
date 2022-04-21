//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.12;

// Imports
import "./EIP712Whitelisting.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";

/// NFT Interface
interface INFT {
  function mint(address recipient, uint256 quantity) external;
  function balanceOf(address owner) external view returns (uint256);
}

/// @title MOD - The Minting Router contract.
contract MintingRouter is Ownable, EIP712Whitelisting, ReentrancyGuard {
  /// @dev The sale types
  enum SaleRoundType {
    WHITELIST,
    PUBLIC
  }

  /// @dev The sale round details
  struct SaleRound {
    SaleRoundType saleType;
    uint256 price;
    uint256 totalAmount;
    uint256 limitAmountPerWallet;
    bool enabled;
  }

  uint256 public constant UNLIMITED = 0; // Indicates that tokens are unlimited.
  uint256 public defaultReferralPercent = 25;  // The percentage of funds transferred to a referral.
  mapping(address => uint256) public referralPercentByAddress; // The percentage of funds transferred to a specific referral.
  mapping(address => uint256) public discountPercentByAffiliatedNftAddress; // The percentage of discount given to holders of a specific NFT.
  SaleRound public saleRound;  // The current sale round details.
  uint256 private _currentSaleIndex;  // The current sale round index.
  INFT private _nftContract;  // The NFT contract.
  mapping(uint256 => uint256) private _mintedAmountPerRound;  // The number of NFTs minted during a sale round.
  // The number of NFTs minted during a sale round per wallet.
  mapping(uint256 => mapping(address => uint256)) private _mintedAmountPerAddress;


  /**
   * @param nftContract The NFT contract
   * @param tokenName The token name of the project
   * @param version The version
   * @dev The contract constructor
   */
  constructor(
    INFT nftContract,
    string memory tokenName,
    string memory version
  ) EIP712Whitelisting(tokenName, version) {
    _nftContract = nftContract;
    _currentSaleIndex = type(uint256).max;
  }

  /**
   * @dev Method for setting the parameters for a sale
   * @param saleType The type of the sale round (WHITELIST - 0, PUBLIC SALE - 1)
   * @param price The price of an NFT for the current sale round
   * @param totalAmount The total amount of NFTs available for the current sale round
   * @param limitAmountPerWallet The max amount of NFTs that can be minted by a single wallet
   */
  function createSaleRound(
    SaleRoundType saleType,
    uint256 price,
    uint256 totalAmount,
    uint256 limitAmountPerWallet
  ) external onlyOwner {
    require(saleRound.enabled == false, "Starting a sale round is only possible when sales are disabled.");
    saleRound.price = price;
    saleRound.totalAmount = totalAmount;
    saleRound.limitAmountPerWallet = limitAmountPerWallet;
    saleRound.saleType = saleType;

    if (_currentSaleIndex == type(uint256).max) {
      _currentSaleIndex = 0;
    } else {
      _currentSaleIndex += 1;
    }
  }

  /**
   * @param price The price of an NFT for the current sale round
   * @param totalAmount The total amount of NFTs available for the current sale round
   * @param limitAmountPerWallet The max amount of NFTs that can be minted by a single wallet
   * @dev Changes the current sale details
   */
  function changeSaleRoundParams(
    uint256 price,
    uint256 totalAmount,
    uint256 limitAmountPerWallet
  ) external onlyOwner {
    saleRound.price = price;
    saleRound.totalAmount = totalAmount;
    saleRound.limitAmountPerWallet = limitAmountPerWallet;
  }

  /// @dev Starts the sale round
  function enableSaleRound() external onlyOwner {
    require(saleRound.enabled == false, "Sale round is already enabled.");
    saleRound.enabled = true;
  }

  /// @dev Pauses the sale round
  function disableSaleRound() external onlyOwner {
    require(saleRound.enabled == true, "Sale round is already disabled.");
    saleRound.enabled = false;
  }

  /**
   * @dev Sets the percentage of funds transferred to a referral.
   * @param percent The percentage value.
   */
  function setDefaultReferralPercent(uint256 percent) external onlyOwner {
    require(percent <= 100, "Invalid percent");
    defaultReferralPercent = percent;
  }

  /**
   * @dev Sets the percentage of funds transferred to a specific referral by their address.
   * @param referralAddress The address of a user to set a custom referral percentage for.
   * @param percent The percentage value.
   */
  function setReferralPercentOfAddress(address referralAddress, uint256 percent) external onlyOwner {
    require(percent <= 100, "Invalid percent");
    referralPercentByAddress[referralAddress] = percent;
  }

  /**
   * @dev Sets the percentage of discount given to the owner of an NFT.
   * @param affiliatedNFTAddress The address of the affiliated NFT.
   * @param percent The percentage value.
   */
  function setDiscountPercentOfAffiliatedNftAddress(address affiliatedNFTAddress, uint256 percent) external onlyOwner {
    require(percent <= 100, "Invalid percent");
    discountPercentByAffiliatedNftAddress[affiliatedNFTAddress] = percent;
  }

  /**
   * @param recipient The address of an NFT receiver
   * @param quantity The number of NFTs to mint
   * @param signature The signature of a whitelisted minter
   * @param affiliatedAddress The address of an affiliate
   * @dev Mints an NFT during a whitelist sale round
   */
  function whitelistMint(
    address recipient,
    uint256 quantity,
    bytes calldata signature,
    address payable affiliatedAddress
  ) external payable requiresWhitelist(signature) nonReentrant {
    require(saleRound.saleType == SaleRoundType.WHITELIST, "Active sale round is not a whitelist round.");
    _mint(msg.value, recipient, quantity, affiliatedAddress, address(0));
  }

  /**
   * @param recipient The address of an NFT receiver
   * @param quantity The number of NFTs to mint
   * @param affiliatedAddress The address of an affiliate
   * @dev Mints an NFT during a public sale round
   */
  function publicMint(
    address recipient,
    uint256 quantity,
    address payable affiliatedAddress,
    address affiliatedNFTAddress
  ) external payable nonReentrant {
    require(saleRound.saleType == SaleRoundType.PUBLIC, "Active sale round is not a public round.");
    _mint(msg.value, recipient, quantity, affiliatedAddress, affiliatedNFTAddress);
  }

  /**
   * @param signer The address used during whitelist generation
   * @dev Sets the address that is used during whitelist generation
   */
  function setWhitelistSigningAddress(address signer) public onlyOwner {
    _setWhitelistSigningAddress(signer);
  }

  /**
   * @param minter The address of the minter
   * @dev Returns the max number of NFTs a minter can mint
   */
  function allowedTokenCount(address minter) public view returns (uint256) {
    if (saleRound.enabled == false) {
      return 0;
    }

    // Calculate the allowed number of tokens to mint by a wallet.
    uint256 allowedWalletCount = saleRound.limitAmountPerWallet != UNLIMITED
    ? (saleRound.limitAmountPerWallet > _mintedAmountPerAddress[_currentSaleIndex][minter]
    ? saleRound.limitAmountPerWallet - _mintedAmountPerAddress[_currentSaleIndex][minter] : 0)
    : type(uint256).max;
    // Calculate the total number of tokens left.
    uint256 availableTokenCount = saleRound.totalAmount != UNLIMITED
    ? (saleRound.totalAmount > _mintedAmountPerRound[_currentSaleIndex]
    ? saleRound.totalAmount - _mintedAmountPerRound[_currentSaleIndex] : 0)
    : type(uint256).max;
    // Get the minimum of all values.
    return allowedWalletCount < availableTokenCount ? allowedWalletCount : availableTokenCount;
  }

  /// @dev Returns the number of NFTs left for the current sale round
  function tokensLeft() public view returns (uint256) {
    if (saleRound.enabled == false) {
      return 0;
    }

    return saleRound.totalAmount != UNLIMITED
    ? (saleRound.totalAmount > _mintedAmountPerRound[_currentSaleIndex]
    ? saleRound.totalAmount - _mintedAmountPerRound[_currentSaleIndex] : 0)
    : type(uint256).max;
  }

  /**
   * @dev Calculates the discounted price of an NFT
   * @param affiliatedNFTAddress The address of an NFT contract
   * @param buyer The address of a buyer
   * @return The price of the NFT
   */
  function discountedPrice(address affiliatedNFTAddress, address buyer) public view returns (uint256) {
    uint256 price = saleRound.price;
    if (affiliatedNFTAddress != address(0)) {
      if (INFT(affiliatedNFTAddress).balanceOf(buyer) > 0) {
        uint256 discount = price * discountPercentByAffiliatedNftAddress[affiliatedNFTAddress] / 100;
        price -= discount;
      }
    }
    return price;
  }

  /// @dev Withdraws the funds
  function withdraw() public onlyOwner returns (bool) {
    uint256 balance = address(this).balance;
    payable(msg.sender).transfer(balance);
    return true;
  }

  /**
   * @param value The total cost for minting
   * @param recipient The user's address
   * @param quantity The number of NFTs to mint
   * @param affiliatedAddress The address of the affiliate
   * @dev Method for minting, this will trigger the mint method inside the NFT contract
   */
  function _mint(
    uint256 value,
    address recipient,
    uint256 quantity,
    address payable affiliatedAddress,
    address affiliatedNFTAddress
  ) private {
    require(quantity > 0, "Quantity should be greater than 0.");
    require(saleRound.enabled == true, "Sale round was disabled or closed.");

    if (saleRound.totalAmount != UNLIMITED) {
      // We have limited amount of tokens for this sale round.
      require(
        _mintedAmountPerRound[_currentSaleIndex] + quantity <= saleRound.totalAmount,
          "Cannot go above the limit of tokens for the current sale round.."
      );
    }

    if (saleRound.limitAmountPerWallet != UNLIMITED) {
      // We have limited amount of tokens per wallet for this sale round.
      uint256 mintedAmountSoFar = _mintedAmountPerAddress[_currentSaleIndex][recipient];
      require(mintedAmountSoFar + quantity <= saleRound.limitAmountPerWallet, "Cannot go above the limit of tokens per wallet.");
    }

    // Make the discount if the msg.sender holds a specific NFT.
    uint256 price = discountedPrice(affiliatedNFTAddress, msg.sender);

    require(value >= price * quantity, "An insufficient amount of funds was provided to process the transaction.");
    _nftContract.mint(recipient, quantity);

    // update total minted amount of this address
    _mintedAmountPerAddress[_currentSaleIndex][recipient] += quantity;
    _mintedAmountPerRound[_currentSaleIndex] += quantity;

    // If there is an affiliate address, not null. And there is no affiliate NFT address specified.
    if (affiliatedAddress != address(0) && affiliatedNFTAddress == address(0)) {
      uint256 referralPercent = defaultReferralPercent;
      if (referralPercentByAddress[affiliatedAddress] != 0) {
        referralPercent = referralPercentByAddress[affiliatedAddress];
      }
      uint256 affiliateShare = (msg.value * referralPercent) / 100;
      // Send affiliate's share
      affiliatedAddress.transfer(affiliateShare);
    }
  }
}