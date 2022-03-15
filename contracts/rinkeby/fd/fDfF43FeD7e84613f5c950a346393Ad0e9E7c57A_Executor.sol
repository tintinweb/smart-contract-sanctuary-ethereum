// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./Registry.sol";

/**
 * @notice We're hiring Solidity engineers! Let's get nifty!
 *         https://www.gemini.com/careers/nifty-gateway
 */
interface ICurrency {
    function symbol() external view returns (string memory);
}

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
}

interface IERC1155 {
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external;
}

/// TODO: Note - we're doing the transfer _with_ data, should we do it without???
interface IERC721 {
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) external payable;
}

/**
 *
 */
contract Executor is Registry {

    event NiftySale721(address indexed tokenContract, uint256 tokenId, uint256 price, address priceCurrency, string priceSymbol);

    string constant public _usd = "USD";
    address public _priceCurrencyUSD;

    string constant public _eth = "ETH";
    address immutable public _priceCurrencyETH = address(0);

    bool public _locked = false;

    /**
     *
     */
    constructor(address priceCurrencyUSD_, address[] memory owners_, address[] memory signingKeys_) Registry(owners_, signingKeys_) {
        
        _priceCurrencyUSD = priceCurrencyUSD_;
    }

    modifier onlyValidSender() {
        require(isValidNiftySender(msg.sender), "NiftyExchangeExecutor: Invalid sender");
        _;
    }

    modifier onlyValidOwner() {
        require(isOwner[msg.sender], "NiftyExchangeExecutor: Invalid owner");
        _;
    }

    modifier notLocked() {
        require(!_locked, "NiftyExchangeExecutor: Lock engaged");
        _;
    }

    function unlock() external onlyValidOwner returns (bool locked) {
        _locked = false;
        return _locked;
    }

    function lock() external onlyValidSender notLocked returns (bool locked) {
        _locked = true;
        return _locked;
    }

    /**
     * #1
     * 
     * @dev 7, 0/1/N, $
     *
     *
     * low key, this one doesn't need to be payable...
     *
     * uint256 price, for the event only
     *
     * uint256 tokenId
     * address tokenContract
     * address seller
     * address buyer
     * bytes data
     *
     */
    function executeSale(
        uint256 price, 
        uint256 tokenId, 
        address tokenContract, 
        address seller, 
        address buyer, 
        bytes calldata data) external onlyValidSender notLocked {
        
        emit NiftySale721(tokenContract, tokenId, price, _priceCurrencyUSD, _usd);
        IERC721(tokenContract).safeTransferFrom(seller, buyer, tokenId, data);
    }

    /**
     * #2
     * 
     * @dev 7, 0, ETH
     *
     * low key, this one _DOES_ need to be payable...
     *
     * uint256 price
     * uint256 sellerProceeds
     *
     * uint256 tokenId
     * address tokenContract
     * address seller
     * address buyer
     * bytes data
     *
     */
    function executeSale(
        uint256 price, 
        uint256 sellerProceeds, 
        uint256 tokenId, 
        address tokenContract, 
        address seller, 
        address buyer, 
        bytes calldata data) external payable onlyValidSender notLocked {

        emit NiftySale721(tokenContract, tokenId, price, _priceCurrencyETH, _eth);
        IERC721(tokenContract).safeTransferFrom(seller, buyer, tokenId, data);
        (bool success,) = payable(seller).call{value: sellerProceeds}("");
        require(success, "NiftyExchangeExecutor: Value transfer unsuccessful");
    }

    /**
     * #3
     * 
     * @dev 7, 0, 20
     *
     * low key, this one doesn't need to be payable...
     *
     * uint256 price
     * uint256 sellerProceeds
     * address priceCurrency
     *
     * uint256 tokenId
     * address tokenContract
     * address seller
     * address buyer
     * bytes data
     *
     */
    function executeSale(
        uint256 price, 
        uint256 sellerProceeds, 
        address priceCurrency, 
        uint256 tokenId, 
        address tokenContract, 
        address seller, 
        address buyer, 
        bytes calldata data) external onlyValidSender notLocked {

        emit NiftySale721(tokenContract, tokenId, price, priceCurrency, _getSymbol(priceCurrency));
        IERC721(tokenContract).safeTransferFrom(seller, buyer, tokenId, data);
        IERC20(priceCurrency).transferFrom(buyer, seller, sellerProceeds);
    }

    /* * */
    /* * */
    /* * */

    /**
     * #4
     * 
     * @dev 7, 1, ETH
     *
     * low key, this one _DOES_ need to be payable...
     *
     * address receiverCreator
     * uint256 receiverAmount
     * uint256 price
     * uint256 sellerProceeds
     *
     * uint256 tokenId
     * address tokenContract
     * address seller
     * address buyer
     * bytes data
     *
     */
    function executeSale(
        address receiverCreator, 
        uint256 receiverAmount, 
        uint256 price, 
        uint256 sellerProceeds, 
        uint256 tokenId, 
        address tokenContract, 
        address seller, 
        address buyer, 
        bytes calldata data) external payable onlyValidSender notLocked {

        emit NiftySale721(tokenContract, tokenId, price, _priceCurrencyETH, _eth);
        IERC721(tokenContract).safeTransferFrom(seller, buyer, tokenId, data);

        (bool successSeller,) = payable(seller).call{value: sellerProceeds}("");
        require(successSeller, "NiftyExchangeExecutor: Value transfer unsuccessful");

        (bool successCreator,) = payable(receiverCreator).call{value: receiverAmount}("");
        require(successCreator, "NiftyExchangeExecutor: Value transfer unsuccessful");
    }

    /**
     * #5
     *
     * low key, this one doesn't need to be payable...
     * 
     * @dev 7, 1, 20
     *
     * address receiverCreator
     * uint256 receiverAmount
     * uint256 price
     * uint256 sellerProceeds
     * address priceCurrency
     *
     * uint256 tokenId
     * address tokenContract
     * address seller
     * address buyer
     * bytes data
     *
     */
    function executeSale(
        address receiverCreator, 
        uint256 receiverAmount, 
        uint256 price, 
        uint256 sellerProceeds, 
        address priceCurrency, 
        uint256 tokenId, 
        address tokenContract, 
        address seller, 
        address buyer, 
        bytes calldata data) external onlyValidSender notLocked {

        emit NiftySale721(tokenContract, tokenId, price, priceCurrency, _getSymbol(priceCurrency));
        IERC721(tokenContract).safeTransferFrom(seller, buyer, tokenId, data);

        IERC20(priceCurrency).transferFrom(buyer, seller, sellerProceeds);

        IERC20(priceCurrency).transferFrom(buyer, receiverCreator, receiverAmount);
    }

    /* * */
    /* * */
    /* * */

    /**
     * #6
     * 
     * @dev 7, N, ETH
     *
     * low key, this one _DOES_ need to be payable...
     *
     * address[] receiverCreators
     * uint256[] receiverAmounts
     * uint256 price
     * uint256 sellerProceeds
     *
     * uint256 tokenId
     * address tokenContract
     * address seller
     * address buyer
     * bytes data
     *
     */
    function executeSale(
        address[] calldata receiverCreators, 
        uint256[] calldata receiverAmounts, 
        uint256 price, 
        uint256 sellerProceeds, 
        uint256 tokenId, 
        address tokenContract, 
        address seller, 
        address buyer, 
        bytes calldata data) external payable onlyValidSender notLocked {

        emit NiftySale721(tokenContract, tokenId, price, _priceCurrencyETH, _eth);
        IERC721(tokenContract).safeTransferFrom(seller, buyer, tokenId, data);

        (bool successSeller,) = payable(seller).call{value: sellerProceeds}("");
        require(successSeller, "NiftyExchangeExecutor: Value transfer unsuccessful");

        for(uint256 i = 0; i < receiverCreators.length; i++){
            (bool successCreator,) = payable(receiverCreators[i]).call{value: receiverAmounts[i]}("");
            require(successCreator, "NiftyExchangeExecutor: Value transfer unsuccessful");
        }
    }

    /**
     * #7
     * 
     * @dev 7, N, 20
     *
     * low key, this one doesn't need to be payable...
     *
     * address[] receiverCreators
     * uint256[] receiverAmounts
     * uint256 price
     * uint256 sellerProceeds
     * address priceCurrency
     *
     * uint256 tokenId
     * address tokenContract
     * address seller
     * address buyer
     * bytes data
     *
     */

    struct NiftyEvent {
        address[] receiverCreators;
        uint256[] receiverAmounts;
        uint256 price;
        uint256 sellerProceeds;
        address priceCurrency;
        uint256 tokenId;
        address tokenContract;
        address seller;
        address buyer;
        bytes data;  
    }

    function executeSale(NiftyEvent calldata ne) external {

        IERC721(ne.tokenContract).safeTransferFrom(ne.seller, ne.buyer, ne.tokenId, ne.data);

        /* * */

        emit NiftySale721(ne.tokenContract, ne.tokenId, ne.price, ne.priceCurrency, _getSymbol(ne.priceCurrency));

        /* * */

        IERC20(ne.priceCurrency).transferFrom(ne.buyer, ne.seller, ne.sellerProceeds);

        /* * */

        for(uint256 i = 0; i < ne.receiverCreators.length; i++){
            IERC20(ne.priceCurrency).transferFrom(ne.buyer, ne.receiverCreators[i], ne.receiverAmounts[i]);
        }

    }

    /**
     * @dev soLala
     */
    function _getSymbol(address priceCurrency) private view returns (string memory symbol) {
        return ICurrency(priceCurrency).symbol();
    }


}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

contract Registry {
    
    
    event OwnerAddition(address indexed owner);
    event OwnerRemoval(address indexed owner);
    
    /**
     * Constants
     */ 
     
    uint constant public MAX_OWNER_COUNT = 50;
    

  /**
   * @dev Modifiers, mostly from the Gnosis Multisig
   */
    modifier onlyOwner() {
        require(isOwner[msg.sender] == true);
        _;
    }
  
   
   /** 
    * @dev A mapping of all sender keys
    */ 
    
   mapping(address => bool) validNiftyKeys;
   mapping (address => bool) public isOwner;
   
   /**
    * @dev Static view functions to retrieve information 
    */
     
    /**
    * @dev function to see if sending key is valid
    */
    
    function isValidNiftySender(address sending_key) public view returns (bool) {
      return(validNiftyKeys[sending_key]);
    }
    
      
      /**
       * @dev Functions to alter master contract information, such as HSM signing wallet keys, static contract
       * @dev All can only be changed by a multi sig transaciton so they have the onlyWallet modifier
       */ 
    
      /**
       * @dev Functions to add and remove nifty keys
       */
       
       function addNiftyKey(address new_sending_key) external onlyOwner {
           validNiftyKeys[new_sending_key] = true;
       }
       
       function removeNiftyKey(address sending_key) external onlyOwner {
           validNiftyKeys[sending_key] = false;
       }
  
  
  /**
   * Multisig transactions from https://github.com/gnosis/MultiSigWallet/blob/master/contracts/MultiSigWallet.sol
   * Used to call transactions that will modify the master contract
   * Plus maintain owners, etc
   */
   
   /// @dev Contract constructor sets initial owners and required number of confirmations.
    /// @param _owners List of initial owners.
    constructor(address[] memory _owners, address[] memory signing_keys)
        public
    {
        for (uint i=0; i<_owners.length; i++) {
            require(!isOwner[_owners[i]] && _owners[i] != address(0));
            isOwner[_owners[i]] = true;
        }
        for (uint i=0; i<signing_keys.length; i++) {
            require(signing_keys[i] != address(0));
            validNiftyKeys[signing_keys[i]] = true;
        }
    }

    /// @dev Allows to add a new owner. Transaction has to be sent by wallet.
    /// @param owner Address of new owner.
    function addOwner(address owner)
        public
        onlyOwner
    {
        isOwner[owner] = true;
        emit OwnerAddition(owner);
    }

    /// @dev Allows to remove an owner. Transaction has to be sent by wallet.
    /// @param owner Address of owner.
    function removeOwner(address owner)
        public
        onlyOwner
    {
        isOwner[owner] = false;
        emit OwnerRemoval(owner);
    }

 

}