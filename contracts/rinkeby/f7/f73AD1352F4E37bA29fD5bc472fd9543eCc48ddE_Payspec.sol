// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

pragma solidity ^0.8.0;

/*
PAYSPEC: Atomic and deterministic invoicing system

Generate offchain invoices based on sell-order data and allow users to fulfill those order invoices onchain.

*/
 

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";



  
contract Payspec is Ownable, ReentrancyGuard {

  uint256 public immutable contractVersion  = 100;
  address immutable ETHER_ADDRESS = address(0x0000000000000000000000000000000000000010);
  
  mapping(bytes32 => Invoice) public invoices; 

  bool lockedByOwner = false; 

  event CreatedInvoice(bytes32 uuid); 
  event PaidInvoice(bytes32 uuid, address from);


  struct Invoice {
    bytes32 uuid;
    string description;
    uint256 nonce;
    bool created;


    address token;
    uint256 amountDue;
    address payTo;

    address[] feeAddresses;
    uint[] feePercents;

    address paidBy;
    uint256 amountPaid;
    uint256 ethBlockPaidAt;


    uint256 ethBlockExpiresAt;

  }



  constructor(   ) public {

  } 
 

  function lockContract() public onlyOwner {
    lockedByOwner = true;
  }


   


  function createAndPayInvoice(  string memory description, uint256 nonce, address token, uint256 amountDue, address payTo, address[] memory feeAddresses, uint[] memory feePercents, uint256 ethBlockExpiresAt, bytes32 expecteduuid  ) 
    public 
    payable 
    nonReentrant
    returns (bool) {
     
     if(token == ETHER_ADDRESS){
       require(msg.value == amountDue, "Transaction sent incorrect ETH amount.");
     }else{
       require(msg.value == 0, "Transaction sent ETH for an ERC20 invoice.");
     }
     
     bytes32 newuuid = _createInvoice(description,nonce,token,amountDue,payTo,feeAddresses, feePercents,ethBlockExpiresAt,expecteduuid);
     require(newuuid == expecteduuid);
     return _payInvoice(newuuid);
  }

   function _createInvoice(  string memory description, uint256 nonce, address token, uint256 amountDue, address payTo, address[] memory feeAddresses, uint[] memory feePercents, uint256 ethBlockExpiresAt, bytes32 expecteduuid ) 
    private 
    returns (bytes32 uuid) { 


      bytes32 newuuid = getInvoiceUUID(description, nonce, token, amountDue, payTo, feeAddresses, feePercents,  ethBlockExpiresAt ) ;

      require(!lockedByOwner);
      require( newuuid == expecteduuid );
      require( invoices[newuuid].uuid == 0 );  //make sure you do not overwrite invoices
      require(feeAddresses.length == feePercents.length);

      require(ethBlockExpiresAt == 0 || block.number < ethBlockExpiresAt);

      invoices[newuuid] = Invoice({
       uuid:newuuid,
       description:description,
       nonce: nonce,
       token: token,
       amountDue: amountDue,
       payTo: payTo,
       paidBy: address(0),
       feeAddresses: feeAddresses,
       feePercents: feePercents,
       amountPaid: 0,
       ethBlockPaidAt: 0,
       ethBlockExpiresAt: ethBlockExpiresAt,
       created:true
      });


       emit CreatedInvoice(newuuid);

       return newuuid;
   }

   function _payInvoice( bytes32 invoiceUUID ) private returns (bool) {

       address from = msg.sender;

       require(!lockedByOwner);
       require( invoices[invoiceUUID].uuid == invoiceUUID ); //make sure invoice exists
       require( invoiceWasPaid(invoiceUUID) == false ); 

       uint totalAmountDueInFees = 0; // invoices[invoiceUUID].amountDue.mul( fee_pct ).div(100);



       for(uint i=0;i<invoices[invoiceUUID].feeAddresses.length;i++){
              uint amtDueInFees =  invoices[invoiceUUID].amountDue * ( invoices[invoiceUUID].feePercents[i] / 100);

              //transfer each fee to fee recipient
              require(  _payTokenAmount(invoices[invoiceUUID].token , from , invoices[invoiceUUID].feeAddresses[i], amtDueInFees ) , "Unable to pay fees amount due." );

              totalAmountDueInFees = totalAmountDueInFees + amtDueInFees ;
       }
 

      uint amountDueLessFees =  invoices[invoiceUUID].amountDue - totalAmountDueInFees ; 

      //transfer the tokens to the seller
      require( _payTokenAmount(  invoices[invoiceUUID].token ,  from,  invoices[invoiceUUID].payTo, amountDueLessFees  ),"Unable to pay amount due.");

      //mark the invoice as paid 
       invoices[invoiceUUID].amountPaid = invoices[invoiceUUID].amountDue;

       invoices[invoiceUUID].paidBy = from;

       invoices[invoiceUUID].ethBlockPaidAt = block.number;



       emit PaidInvoice(invoiceUUID, from);

       return true;


   }


   function _payTokenAmount(address tokenAddress, address from, address to, uint256 tokenAmount) 
      internal 
      returns (bool) {
      
      if(tokenAddress == ETHER_ADDRESS){
        payable(to).transfer( tokenAmount ); 
      }else{ 
        IERC20( tokenAddress  ).transferFrom( from ,  to, tokenAmount  );
      }
      return true;
   }



   function getInvoiceUUID(  string memory description, uint256 nonce, address token, uint256 amountDue, address payTo, address[] memory feeAddresses, uint[] memory feePercents, uint expiresAt  ) public view returns (bytes32 uuid) {

         address payspecContractAddress = address(this); //prevent from paying through the wrong contract

         bytes32 newuuid = keccak256( abi.encodePacked(payspecContractAddress, description, nonce, token, amountDue, payTo, feeAddresses, feePercents, expiresAt ) );

         return newuuid;
    }

   function invoiceWasPaid( bytes32 invoiceUUID ) public view returns (bool){

       return invoices[invoiceUUID].amountPaid >= invoices[invoiceUUID].amountDue;
   }

   function invoiceWasCreated( bytes32 invoiceUUID ) public view returns (bool){

       return invoices[invoiceUUID].created ;
   }



    function getInvoiceDescription( bytes32 invoiceUUID ) public view returns (string memory){

       return invoices[invoiceUUID].description;
   }

   function getInvoiceTokenCurrency( bytes32 invoiceUUID ) public view returns (address){

       return invoices[invoiceUUID].token;
   }


   function getInvoiceAmountPaid( bytes32 invoiceUUID ) public view returns (uint){

       return invoices[invoiceUUID].amountPaid;
   }

   function getInvoicePayer( bytes32 invoiceUUID ) public view returns (address){

       return invoices[invoiceUUID].paidBy;
   }

   function getInvoiceEthBlockPaidAt( bytes32 invoiceUUID ) public view returns (uint){

       return invoices[invoiceUUID].ethBlockPaidAt;
   }

 


}