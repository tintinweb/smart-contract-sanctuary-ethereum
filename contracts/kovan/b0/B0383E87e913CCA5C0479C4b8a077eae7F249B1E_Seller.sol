// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "IController.sol";
import "IBox.sol";
import "IERC721.sol";
import "IERC20.sol";
import "AggregatorV3Interface.sol";

//TODO: change getChainlinkAggregator() it doesn't work correctly (read-function in write part)
contract Seller {
    
    AggregatorV3Interface internal priceFeed;    
    IController internal controller;
    IBox internal box;

    uint256 public basePrice; // price of Box in USD (Box/USD)
    //decimals of basePrice. It's better to use decimals not too small, 
    //it can be the reason of the zero price in ETH or other expensive token
    uint8 public baseDecimals; 
    //mapping: Address of token => the address of Chainlink aggregator of price (token/USD Ethereum Mainnet)
    mapping (address => address) private allowedTokenToChainlinkAddress; 

    event Received(address _from, uint _amount);   

    //Receive Ether Function
    receive() external payable {                
        emit Received(msg.sender, msg.value);
    }
   
    /**
     * Network: Kovan Testnet
     * Aggregator: ETH/USD
     * Address: 0x9326BFA02ADD2366b30bacB125260Af641031331
     * Decimals: 8
     */
    constructor(
        address _addressOfController, 
        address _addressOfBox, 
        uint256 _basePrice, 
        uint8 _baseDecimals) {

            controller = IController(_addressOfController);   
            box = IBox(_addressOfBox);    
            priceFeed = AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331);
            basePrice = _basePrice;
            baseDecimals = _baseDecimals;
    }
   
    /**
     * @notice Set the price of Box in USD. 
     * Function can be called only by SuperAdmin
     * @param _boxPrice The price of Box in USD wich will be set.
     * @param _priceDecimals The decimals of Box price.
    */  
    function setThePriceOfBox(uint256 _boxPrice, uint8 _priceDecimals) external returns (bool){         
        require (controller.isSuperAdmin(msg.sender), "Seller: Only SuperAdmin can set the Price of Box");         
        basePrice = _boxPrice; 
        baseDecimals = _priceDecimals;
        return true;
    } 

    /**
     * @notice Set the address of the chainlink Aggregator for the proper token (token/USD)
     * This function can call only Super Administrator
     * Token to set address has to be allowed to recieve
     * @param _token Token to set address of the chainlink Addregator    
     * @param _chainlinkContract Address of the chainlink Addregator to set for the token
    */
    function setChainlinkAggregator(address _token, address _chainlinkContract) external returns (bool) {
        require (controller.isSuperAdmin(msg.sender), "Seller: Only Super Admin can set chainlink address");
        require (controller.isRecieveTokenAllowed(_token), "Seller: Only allowed tokens can be used");
        allowedTokenToChainlinkAddress[_token] = _chainlinkContract;

    }

    // Public functions   

    /**
     * @notice Get the price of Box in proper token.  
     * @param _token Token in wich you want to know the price of Box.
     * @param _decimals The decimals of Box price.
    */  
    function getTokenPrice(address _token, uint8 _decimals)
        public
        view
        returns (uint256)
    {
        require(_decimals > uint8(0) && _decimals <= uint8(18), "Invalid _decimals");
        uint256 decimals = 10 ** uint256(_decimals);        
        uint256 boxUSDPrice = _scalePrice(basePrice, baseDecimals, _decimals);

        address quoteAddress = allowedTokenToChainlinkAddress[_token];
        ( , int256 quotePrice, , , ) = AggregatorV3Interface(quoteAddress).latestRoundData();        
        uint8 quoteDecimals = AggregatorV3Interface(quoteAddress).decimals();
        uint256 tokenUSDPrice = _scalePrice(uint256(quotePrice), quoteDecimals, _decimals);

        return boxUSDPrice * decimals / tokenUSDPrice;
    }    

    /**
     * @notice Get the price of box in ETH.       
    */  
    function getETHPrice() public view returns (uint256) {

        uint256 decimals = 10 ** baseDecimals;               
        ( , int256 quotePrice, , , ) = priceFeed.latestRoundData();        
        uint8 quoteDecimals = priceFeed.decimals();
        uint256 ethUSDPrice = _scalePrice(uint256(quotePrice), quoteDecimals, baseDecimals);

        return basePrice * decimals / ethUSDPrice;

    }

    /**
     * @notice Get the address of the chainlink Aggregator for the proper token (token/USD)
     * @param _token Token to know address of the chainlink Addregator      
    */  
    function getChainlinkAggregator(address _token) public view returns (address) {
        address agreggator = allowedTokenToChainlinkAddress[_token];
        return agreggator;
    }

    /**
     * @notice Function to buy Box for ETH. 
     * It mints Box to the address of msg.sender and send ETH to the Treasure. 
     * Function can be called only by Whitelisted address (SC Controller, _whitelist)    
     * @param _BoxID ID of Box to buy  
    */
    function buyForETH(uint256 _BoxID) public returns (bool) {
        address buyer = payable(msg.sender);
        require (controller.isAddressWhitelisted(buyer), "Seller: You are not whitelisted, you can't buy Box");
        uint256 amountOfToken = getETHPrice();
        _sendETHToTreasure(amountOfToken);        
        _mintBox(buyer, _BoxID);
        return true;
    }
    
    /**
     * @notice Function to buy Box for ERC20-token. 
     * It mints Box to the address of msg.sender and send ERC20-tokens to the Treasure. 
     * Function can be called only by Whitelisted address (SC Controller, _whitelist)     
     * @param _tokenToPay Address of the token in which Box is bought. 
     * @param _decimals The decimals you want to use in price  
     * @param _BoxID ID of Box to buy  
    */
    function buyForToken(address _tokenToPay, uint8 _decimals, uint256 _BoxID) public returns (bool) {
        address buyer = payable(msg.sender);
        require (controller.isAddressWhitelisted(buyer), "Seller: You are not whitelisted, you can't buy Box");
        uint256 amountOfToken = getTokenPrice(_tokenToPay, _decimals);
        _sendTokenToTreasure(_tokenToPay, buyer, amountOfToken);
        _mintBox(buyer, _BoxID);
        return true;
    }

    // Internal functions

    /**
     * @notice Scale price to the proper decimals  
     * @param _price Price 
     * @param _priceDecimals Decimals of price
     * @param _decimals The decimals to wich price will be scaled
    */  
    function _scalePrice(uint256 _price, uint8 _priceDecimals, uint8 _decimals)
        internal
        pure
        returns (uint256)
    {
        if (_priceDecimals < _decimals) {
            return _price * (10 ** uint256(_decimals - _priceDecimals));
        } else if (_priceDecimals > _decimals) {
            return _price / (10 ** uint256(_priceDecimals - _decimals));
        }
        return _price;
    }    

    //Function will be created after SC Box
    function _mintBox(address _mintBoxTo, uint256 _BoxID) internal returns (bool){
        box.mint(_mintBoxTo, _BoxID);
        return true;
    }

    /**
     * @notice Internal function to send ERC20-tokens to Treasure.       
     * @param _tokenToPay Address of the ERC20-token in which Box will be bought.
     * @param _buyer The address which pays for Box.
     * @param _amountOfToken The amount of ERC20-token which will be payed for Box.
     */ 
    function _sendTokenToTreasure(address _tokenToPay, address _buyer, uint256 _amountOfToken) 
      internal      
      returns (bool) {

        address treasury = payable(controller.getTreasureContract());
        require(_buyer != address(0), "Address of the buyer can't be zero!");
        require(_amountOfToken != 0, "Amount of token can't be zero!");
        IERC20(_tokenToPay).transferFrom(_buyer, treasury, _amountOfToken);
        return true;
    }

    /**
     * @notice Internal function to send ETH to Treasure.            
     * @param _amountOfToken The amount of ETH which will be payed for Box.
     */ 
    function _sendETHToTreasure(uint256 _amountOfToken) 
      internal      
      returns (bool) {

        address payable treasury = payable(controller.getTreasureContract());        
        require(_amountOfToken != 0, "Amount of token can't be zero!");
        treasury.transfer(_amountOfToken);        
        return true;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IController {  
       
    /// @notice Get address of the Seller smart contract.
    function getSellerContract() external view returns (address);

    /// @notice Get address of the BoxNFT smart contract.
    function getBoxContract() external view returns (address);
    
    ///@notice Get address of the Treasure smart contract.
    function getTreasureContract() external view returns (address); 

    ///@notice Get the information if whitelist is active or not.  
    function isWhitelistActive() external returns (bool);

    ///@notice Get the information if address is whitelisted or not. 
    function isAddressWhitelisted(address _address) external view returns (bool);

    ///@notice Get the information if address of token is allowed to recieve.
    function isRecieveTokenAllowed(address _tokenToCheck) external view returns (bool);

    /**
     * @notice Checks if the address is assigned the Super_Admin role.
     * @param _address Address for checking.
     */
    function isSuperAdmin(address _address) external view returns (bool);    

    /**
     * @notice Checks if the address is assigned the TokenManager role.
     * @param _address Address for checking.
     */
    function isTokenManager(address _address) external view returns (bool);

    /**
     * @notice Checks if the address is assigned the NFTManager role.
     * @param _address Address for checking.
     */
    function isNFTManager(address _address) external view returns (bool);       
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IBox {

    // Rarity of tokens
    enum RarityTypes{Gold, Silver, Bronze}

    /** 
    * struct that save token metadata
    */ 
    struct TokenMeta{
        string Name;
        string Description;
        uint256 ID;
        string URL;
        RarityTypes Rarity;
        bool isPanno;
    }

    /**
     * @dev Returns the name of the contract.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the contract.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns true, if contract supports interface.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    /** 
    * Set the token metadata
    * _name - name of the token
    * _description - desxription of the token.
    * _Id - id of the token.
    * _URL - URL of the token.
    * _rarity - rarity of the token.
    * _isPanno - is a token Panno.
    * Requirements:
    * sender must be the metadataManager address.
    */
    function setMetadata(string memory _name, string memory _description, uint256 _Id, string memory _URL, RarityTypes _rarity, bool _isPanno) external;

    /**
     * @dev Returns the URI of the token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);

    //Set the 'isPanno' of the 'tokenId'
    // Requirements: sender must be metadataManager address.
    function setIsPanno(uint256 tokenId, bool _isPanno) external;

    // Returns the name of the token. 
    function getName(uint256 tokenId) external view returns(string memory);

    // Returns the description of the token. 
    function getDescription(uint256 tokenId) external view returns(string memory);

    // Returns the rarity of the token. 
    function getRarity(uint256 tokenId) external view returns(RarityTypes);

    // Returns the isPanno of the token. 
    function getIsPanno(uint256 tokenId) external view returns(bool);

    /**
     * Mints `tokenId` and transfers it to `to`.
     * Requirements:
     * - sender must be the minter address.
     * 'to' can have only 15 tokens.
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     * Emits a {Transfer} event.
     */
    function mint(address to, uint tokenId) external;

    /**
     * Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     * Requirements:
     * - sender must be burner address.
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function burn(uint256 tokenId) external;

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
     * Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     * Requirements:
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "IERC165.sol";

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
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}