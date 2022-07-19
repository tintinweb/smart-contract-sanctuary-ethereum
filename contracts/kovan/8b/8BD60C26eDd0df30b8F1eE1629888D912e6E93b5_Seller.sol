// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "IController.sol";
import "IBox.sol";
import "IERC721.sol";
import "SafeERC20.sol";
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";
import "draft-IERC20Permit.sol";
import "Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
                /// @solidity memory-safe-assembly
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