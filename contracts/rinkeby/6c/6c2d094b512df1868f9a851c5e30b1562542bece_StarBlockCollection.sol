// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./StarBlockBaseCollection.sol";

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract StarBlockCollection is StarBlockBaseCollection {

   mapping(uint256 => uint256) public collectionSizeMap;
   mapping(uint256 => mapping(address => uint256)) public collectionNumberMinted;
   mapping(uint256 => mapping(address => uint256)) public collectionWhiteListNumberMinted; 

  /* ERC20 Token address */
  IERC20 public tokenAddress;
  uint public mintTokenAmount;
  
   constructor(
        string memory name_,
        string memory symbol_,
        address proxyRegistryAddress_,
        uint256 maxBatchSize_,
        uint256 collectionSize_,
        string memory baseURI_
    ) StarBlockBaseCollection(name_, symbol_, proxyRegistryAddress_, maxBatchSize_, collectionSize_, baseURI_) {

    }

   function _mintAssets(
        address from_,
        address to_,
        uint256 collectionId_,
        uint256 numberMinted_,
        uint256 collectionSize_,
        uint256 maxPerAddressDuringMint_,
        uint256 quantity_
    ) internal {
        require(quantity_ > 0, "StarBlockCollection#mintAssets quantity must greater than zero");
        require(
            _isProxyForUser(from_, _msgSender()),
            "StarBlockCollection#mintAssets: caller is not approved"
        );

        if (collectionSize_ > 0) {
            require((collectionSizeMap[collectionId_] + quantity_) <= collectionSize_, "StarBlockCollection#mintAssets reached max supply");
        }

        if (maxPerAddressDuringMint_ > 0) {
            require(
           (numberMinted_ + quantity_) <= maxPerAddressDuringMint_,
           "StarBlockCollection#mintAssets reached per address max supply"
         );
        }

        _safeMint(from_, to_, quantity_);
        collectionSizeMap[collectionId_] = collectionSizeMap[collectionId_] + quantity_;
        safeTransferToken(to_, mintTokenAmount * quantity_);
   }

    function publicMint(
        address from_,
        address to_,
        uint256 collectionId_,
        uint256 collectionSize_,
        uint256 maxPerAddressDuringMint_,
        uint256 quantity_
    ) public whenNotPaused {

        _mintAssets(from_, to_,  collectionId_, collectionNumberMinted[collectionId_][to_],
        collectionSize_, maxPerAddressDuringMint_, quantity_);
        collectionNumberMinted[collectionId_][to_] = collectionNumberMinted[collectionId_][to_] + quantity_;
    }

   function whiteListMint(
        address from_,
        address to_,
        uint256 collectionId_,
        uint256 collectionSize_,
        uint256 maxPerAddressDuringMint_,
        uint256 quantity_
    )  public whenNotPaused {

        _mintAssets(from_, to_, collectionId_, collectionWhiteListNumberMinted[collectionId_][to_],
        collectionSize_, maxPerAddressDuringMint_, quantity_);
        collectionWhiteListNumberMinted[collectionId_][to_] = collectionWhiteListNumberMinted[collectionId_][to_] + quantity_;
   }

   function setTokenAddressAndMintTokenAmount(IERC20 tokenAddress_, uint256 mintTokenAmount_) external onlyOwner {
        tokenAddress = tokenAddress_;
        mintTokenAmount = mintTokenAmount_;
   }

   function safeTransferToken(address to_, uint256 amount_) internal {
      if(address(tokenAddress) != address(0) && amount_ > 0){
        uint256 bal = tokenAddress.balanceOf(address(this));
        if(bal > 0) {
            if (amount_ > bal) {
                tokenAddress.transfer(to_, bal);
            } else {
                tokenAddress.transfer(to_, amount_);
            }
        }
      }
    }

    function withdrawToken() external onlyOwner {
        uint256 bal = tokenAddress.balanceOf(address(this));
        if(bal > 0) {
            tokenAddress.transfer(msg.sender, bal);
        }
    }
}