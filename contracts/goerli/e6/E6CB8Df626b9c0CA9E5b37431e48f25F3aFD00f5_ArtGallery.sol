// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";
import "../node_modules/@openzeppelin/contracts/utils/Address.sol";




/*
************************
ArtGallery SmartContract
************************
- We simulate an art gallery that sells its works of art
- Customers can put the purchased works of art on sale and in case of sale the art gallery retains the fees
*/
contract ArtGallery is Ownable{    
              
    enum en_Operation{
        Enter,
        ForSale, 
        Purchase
    }

    /*
    *   
    */
    struct Artwork {        
        /*
        *   The fees that the contract retains for each sale
        */
        uint percFee;

        /*
        *   Need to understand if an Artwork exixts in the Mapping
        */
        bool exists;      
    }

    /*
    *   Defines the list of purchase or sale transactions
    *   The smart Contract create a new Business element every time 
    *   the owner changes the state of the artwork and evry time it is sold
    */
    struct Business {
        
        /*
        *   The new Owner of the Artwork
        */
        address owner;

        /*
        *   The price of the operation
        */
        uint price;

        /*
        *   The operation type
        *   Created every time the Owner change the Art work status 
        *   and/or price and every time an Artwork is sold
        *   Define the current status of the Artwork, Purchased or ForSale
        */
        en_Operation operation;
    }



    /* Contract Data */ 
    mapping(string => Artwork) artworks;
    mapping(string => Business[]) business;
    uint totalSold;
    uint totalDirectSold;
    uint totalFeeSold;

    

    /* Contract Events */
    event AddArtworkEvent(string code, uint price);
    event RemoveArtworkEvent(string code);
    event PutArtworkForSaleEvent(string code, uint price);
    event RemoveArtworkForSaleEvent(string code);
    event BuyEvent(string code, uint price, address from);
    event SendPaymentEvent(string code, uint price, address to);
    event ChangeArtworkPriceEvent(string code, uint price);

    
    /*
    *    The Contract owner insert the Artwork
    *
    *    Requirements:
    * 
    *    - `_code`      : the unique code of the Artwork
    *    - `_price`     : the price of the Artwork
    *    - `_percFee`   : the fee applied when a client resells the Artwork
    * 
    *   Emits a {AddArtworkEvent} event.
    */
    function addArtwork(string memory _code, uint _price, uint _percFee) 
                        public 
                        onlyOwner
                        stringNotVoid(_code)
                        artworkNotExists(_code) 
                        valueNotZero(_price, "The price is required") {
                
        Artwork memory product;
        product.percFee = _percFee;        
        product.exists = true;
        
        Business memory newBusiness;                    
        newBusiness.owner = msg.sender;
        newBusiness.price = _price;
        newBusiness.operation = en_Operation.Enter;

        artworks[_code] = product;        
        business[_code].push(newBusiness);
        
        emit AddArtworkEvent(_code, _price);
    }

    /*
    *    The Contract owner remove the Artworks, only if the Contract owner is the artwork owner
    *
    *   Requirements:
    * 
    *   - `_code`   : the unique code of the Artwork  
    * 
    *   Emits a {RemoveArtworkEvent} event.              
    */
    function removeArtwork(string memory _code) 
                            public 
                            onlyOwner 
                            stringNotVoid(_code)
                            artworkExists(_code) 
                            senderIsArtworkOwner(_code )                             
                            returns(bool){

        delete artworks[_code];                
        delete business[_code];  

        emit RemoveArtworkEvent(_code);
        
        return artworks[_code].exists && business[_code].length > 0;
    }

    /*
    *   Buy a product, the product must be for sale
    *
    *   Requirements:
    * 
    *   - `_code` : the product code you want buy
    * 
    *   Emits a {SendPaymentEvent} event - Only when ArtWork Owner is a Customer
    *   Emits a {BuyEvent} event.   
    */
    function buyArtwork(string memory _code) 
                    public 
                    payable 
                    stringNotVoid(_code) 
                    artworkExists(_code)
                    senderIsNotArtworkOwner(_code)
                    artworkIsForSale(_code)
                    returns(bool){

        //The amouint to send to the current Artwork Owner 
        //in case is not the constract Owner
        uint amountToPay;

        Business memory lastBusiness = getLastBusiness(_code);
                
        /* Check the send amount is equals to the Artwork price */
        require(lastBusiness.price == msg.value, "#valid-price# - The price is not valid");

        //I am doing a resale for which i have to send
        //payment to the owner minus the fees
        if(lastBusiness.owner != owner()){
            Artwork memory product = artworks[_code];
            if(product.percFee > 0){
                amountToPay = msg.value - (msg.value / 100 * product.percFee);
                Address.sendValue(payable(lastBusiness.owner), amountToPay);            
            }
        }

        /* Create a new Purchase operation - Change the Artwork Owner */
        Business memory newbusiness;        
        newbusiness.owner = msg.sender;
        newbusiness.price = msg.value;
        newbusiness.operation = en_Operation.Purchase;
        business[_code].push(newbusiness);

        emit BuyEvent(_code, msg.value, msg.sender);

        if(lastBusiness.owner != owner()){
            emit SendPaymentEvent(_code, amountToPay, lastBusiness.owner);
        }
        
        unchecked {
            totalSold += msg.value;
            if(lastBusiness.owner != owner()){
                totalFeeSold += (msg.value - amountToPay);            
            }else{
                totalDirectSold += msg.value;
            }
        }

        return true;
    }

    /*
    *   The buyer can put the product for sale
    *
    *   Requirements:
    * 
    *   - `_code` : the product code, the sender must be the current owner
    *   - `_price`:    the sale price
    * 
    *   Emits a {PutArtworkForSaleEvent} event.  
    */
    function putForSale(string memory _code, uint _price) 
                        public 
                        stringNotVoid(_code)
                        artworkExists(_code)
                        valueNotZero(_price, "The price is required")
                        senderIsArtworkOwner(_code)
                        artworkIsNotForSale(_code) 
                        returns(bool){
        
        Business memory newBusiness;        
        newBusiness.owner = msg.sender;
        newBusiness.price = _price;
        newBusiness.operation = en_Operation.ForSale;
        business[_code].push(newBusiness);

        emit PutArtworkForSaleEvent(_code, _price);

        return true;
    }

    /*
    *   The buyer can remove the artwork for sale
    *
    *   Requirements:
    * 
    *   - `_code` : the artwork code, the sender must be the current owner        
    * 
    *   Emits a {RemoveArtworkForSaleEvent} event.  
    */
    function removeFromSale(string memory _code) 
                            public 
                            stringNotVoid(_code)
                            artworkExists(_code) 
                            senderIsArtworkOwner(_code)
                            artworkIsForSale(_code)
                            returns(bool){
                       
        Business memory lastBusiness = getLastBusiness(_code);
        require(lastBusiness.owner != owner(), "#cannot-remove# - The contract owner cannot remove artwork from sale, remove the Artwork instead");

        /* Remove the last element in the business array */
        business[_code].pop();

        emit RemoveArtworkForSaleEvent(_code);

        return true;
    }

    /*
    *   The buyer can change the price
    *
    *   Requirements:
    * 
    *   - `_code` : the artwork code
    *   - `_price` : the new price
    * 
    *   Emits a {ChangeArtworkPriceEvent} event. 
    */
    function changeSalePrice(string memory _code, uint _price) 
                                public 
                                stringNotVoid(_code)
                                valueNotZero(_price, "The price cannot be zero")
                                artworkExists(_code) 
                                senderIsArtworkOwner(_code)
                                artworkIsForSale(_code)
                                returns(bool){

        uint last_index = business[_code].length -1 ;                
        /* Change the price in the business array */
        business[_code][last_index].price = _price;

        emit ChangeArtworkPriceEvent(_code, _price);

        return true;
    }

    /*
    *   The current Owner of the Artwork by code
    *
    *   Requirements
    *   - `_code` : the Artwork code    
    *   
    */
    function getCurrentOwner(string memory _code) 
                                public  
                                view            
                                stringNotVoid(_code)                    
                                artworkExists(_code) 
                                returns(address){

        return getLastBusiness(_code).owner;
    }

    /*
    *   Return the operation for the Artwork
    *
    *   Requirements
    * 
    *   - `_code` : the Artwork code
    */
    function getBusinessList(string memory _code) 
                            public 
                            view 
                            onlyOwner
                            stringNotVoid(_code)
                            artworkExists(_code) 
                            returns(Business[] memory){
        Business[] memory businessList = new Business[](business[_code].length);
        
        for(uint x=0; x<business[_code].length; x++){            
            businessList[x] = business[_code][x];            
        }
        return businessList;                
    }

    /* 
    *   Return the current contract balance 
    *
    *    Returns:
    *    1) Total amount of sold Artwork
    *    2) Total amount of direct sold Artwork
    *    3) Total amount of fee
    *    4) Current contract balance
    */
    function getBalance() 
                public 
                view
                onlyOwner 
                returns(uint, uint, uint, uint){

        return (totalSold, totalDirectSold, totalFeeSold, address(this).balance);
    }
    
    /*
    function getAddress() public view returns(address){
        return address(this);
    }
    */

    /* 
    *   Owner can withdraw Contract balance
    *
    *   Requirements:
    *     
    *   - `_amount` : amount to withdraw
    */
    function withdraw(uint _amount) 
                        public 
                        payable 
                        onlyOwner 
                        valueNotZero(_amount, "The amount of the withdraw is required") {        
                
        uint balance = address(this).balance;
        require(balance > 0, "#balance-zero# The balance is zero");
        require(_amount <= balance, "#amount-exceed-balance# - The amount cannot exceed the balance");
        
        Address.sendValue(payable(owner()), _amount);        
    }

    /********************
        Private functions
    *********************/
    /*
    *   Return the last operation on the specified Artwork
    *
    *   Requirements:
    * 
    *   - `_code` :    the code of the artwork
    * 
    */
    function getLastBusiness(string memory _code) 
                                public 
                                view                                                                
                                returns(Business memory){
        uint lastIndex = business[_code].length - 1;
        return business[_code][lastIndex];
    }

    function enumOperationToString(en_Operation operation) private pure returns(string memory){                
        if(operation == en_Operation.ForSale) return "ForSale";
        if(operation == en_Operation.Enter) return "Enter";
        if(operation == en_Operation.Purchase) return "Purchase";
        return "";
    }




    /**********************
        Functions modifiers 
    ***********************/ 
    modifier artworkNotExists(string memory _code) {                
        require(artworks[_code].exists == false, string.concat("#artwork-not-exist# - The Artwork ", _code, " exists"));
        _;
    }

    modifier artworkExists(string memory _code) {                
        require(artworks[_code].exists, string.concat("#artwork-exist# - The Artwork ", _code, " does not exists"));
        _;
    }

    modifier senderIsArtworkOwner(string memory _code) {                
        Business memory lastBusiness = getLastBusiness(_code);        
        require(lastBusiness.owner == msg.sender, string.concat("#current-owner# - You are not the current artwork ", _code, " owner"));
        _;
    }

    modifier senderIsNotArtworkOwner(string memory _code) {                
        Business memory lastBusiness = getLastBusiness(_code);   
        require(lastBusiness.owner != msg.sender, string.concat("#not-current-owner# - You are the current artwork ", _code, " owner"));
        _;
    }

    modifier artworkIsForSale(string memory _code) {                
        Business memory lastBusiness = getLastBusiness(_code);        
        require(lastBusiness.operation == en_Operation.Enter || 
                lastBusiness.operation == en_Operation.ForSale, 
                string.concat("#for-sale# - The artwork ", _code, " is not for sale"));
        _;
    }

    modifier artworkIsNotForSale(string memory _code) {                
        Business memory lastBusiness = getLastBusiness(_code);        
        require(lastBusiness.operation == en_Operation.Purchase, string.concat("#not-for-sale# - The artwork ", _code, " is for sale"));
        _;
    }

    modifier stringNotVoid(string memory _code) {
        require(bytes(_code).length != 0, "#code-empty# - The code is required");
        _;
    }

    modifier valueNotZero(uint _value, string memory _message) {        
        require(_value > 0, string.concat("#value-zero# - ", _message));
        _;
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}