/**
 *Submitted for verification at Etherscan.io on 2022-10-20
*/

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

// File: source/openzeppelin-contracts/contracts/access/Ownable.sol

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

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

// File: source/openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// File: source/ABCVault.sol

// File: contracts/ABCVault.sol

/*
 * @title: Asteroid Belt Club Vault Smart Contract
 * @author: Gustavo Hernandez Baratta  (The Pan de Azucar Bay Company LLC)
 * @dev: The vault is the smart contract in which the CLUB's digital assets are stored.
 * Funds stored in the vault can only be transferred to third parties through a three-step 
 * mechanism implemented in the addPayment, approvePayment and pay functions. 
 * addPayment allows scheduling a future payment, which must be approved by invoking the 
 * approvePayment function. Finally the payment is released and the beneficiary can execute the pay function and receive the funds.
 * Between steps there is a constraint of approximately 10 days (63000 blocks). 
 * The vault and individual payments can be paused in case of emergency by invoking the functions pause and pausePayment.
 *
 * The vault management rules are designed to prevent now or in the future practices known as "rug pulling". 
 * Initially the owner of the vault is the ABC contract itself, and no function is programmed to initiate the payment process. 
 * Once the DAO is designed, a smart contract will receive ownership and with it the ability to add new payments and pause 
 * the vault and individual contracts. But the process of approving a new payment will require a second contract 
 * to approve it (this function should be fulfilled by the voting contract from which the community approves and 
 * authorizes it), and there will be a restriction period long enough to alert on any improper payments.
 *
 *@email: [email protected]
 */

pragma solidity ^0.8.14;


contract ABCVault is IERC721Receiver, Ownable {

  //payment structure
  struct payment {
    string description; //a breaf description
    address to; //beneficiary address
    uint256 amount; //amount to be transfered after approval
    bool approved; //true if payment was approved
    address activator; //address from which the approvePayment function can be invoked to approve this payment.
    uint256 validblock; //block from which the payment can be approved // block from which the payment can be done.
    bool paused; //if paused, cannot be approved or paid
    bool paid;  //true if already paid   
  }  
  mapping(uint256=>payment) public paymentlist; //payments are stored in a list 
  uint256 public _paymentCounter; //payment index counter
  uint256 public constant blocksDelay=72000; //delay restriction
  bool public paused = true; //Vault can be paused

  /* Events fired by contract */
  event PaymentReceived(address indexed from, uint256 amount);
  event PaymentAdded(uint256 id);
  event PaymentApproved(uint256 id);
  event Paid(uint256 id);
  event StateChanged(bool state);
  event PaymentStateChanged(uint256 id, bool state);

  receive() external payable {
    emit PaymentReceived(_msgSender(), msg.value);
  }
  
  function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
    return this.onERC721Received.selector;
  }

  /* @dev: Pause and resume addPayment, aprovePayments and pay function 
   * Change paused variable with bool _state params
   * Emit StateChanged event
   */
  function pause(bool _state) public onlyOwner {
    paused = _state;
    emit StateChanged(_state);
  }

  /* @dev: Pause and resume individual payment 
   * Change payment state. if it paused can neither be approved nor paid
   * Execution is stopped if payment don't exist of if already paid
   * Emit PaymentStateChanged event
   */
  function pausePayment(uint256 _id, bool _state) public onlyOwner {
    require(paymentlist[_id].to != address(0),"Payment don't exist");
    require(!paymentlist[_id].paid, "Payment already paid");
    paymentlist[_id].paused=_state;
    emit PaymentStateChanged(_id,_state);
  }

  /* @dev: Add a new Payment. Only Owner can add a new payment to the list
   * @params:
   * _description: a breaf description
   * _to: beneficiary address
   * _amount: amount to be paid to beneficiary if approved
   * _activator: address from approvePayment could be called after _payment.validblock restriction
   * Execution is stopped if Vault is in pause state (paused==true), if description or amount or beneficiary or activator are no valud
   * or if called by other than de owner.
   * Emit PaymentAdded event
   */
  function addPayment(string memory _description, address _to, uint256 _amount, address _activator) public onlyOwner returns(uint256) {
    require(!paused,"Vault Paused");
    require(bytes(_description).length >0, "Please add a description");
    require(_amount >0,"Amount must be greather than 0");
    require(_to != address(0), "Please specify a destination address");
    require(_activator != address(0), "Please specify an activator address");
    payment memory __payment;
    _paymentCounter++;
    __payment.description=_description;
    __payment.to=_to;
    __payment.amount=_amount;
    __payment.activator=_activator;
    __payment.validblock=block.number + blocksDelay;
    paymentlist[_paymentCounter]=__payment;
    emit PaymentAdded(_paymentCounter);
    return _paymentCounter;
  }

  /* @dev: Approve previously added payment. After approval (and payment.validblock restriction) beneficiary can be paid
   * Execution is stopped if Vault or payment are in paused state, if payment does not exist, if already aproved, if function
   * was called by otther than activator or if current block number is less than valid block restriction.
   * Emit PaymentApproved event.
   */
  function approvePayment(uint256 _id) public {
    require(!paused,"Vault Paused");
    require(paymentlist[_id].to != address(0),"Payment don't exist");
    require(!paymentlist[_id].paused, "Payment paused");
    require(paymentlist[_id].approved==false,"Payment already aproved");    
    require(paymentlist[_id].activator==_msgSender(),"Yo cannot aprove this payment");
    require(paymentlist[_id].validblock < block.number,"Wait for a valid block to aprove payment");
    paymentlist[_id].validblock=block.number+blocksDelay;
    paymentlist[_id].approved=true;
    paymentlist[_id].paused=true;
    emit PaymentApproved(_id);

  }

  /* @dev: Release pre-approved payment after validblock restriction
   * Anyone can call this function, but payment.amount funds are only transfered to payment.to.
   * Execution was stopped if Vault or payment are in paused state, payment does not exist, not yet approved, already paid 
   * or validblock is greather than current block or current balance is less than payment amount
   * Emit Paid event
   */
  function pay(uint256 _id) public {
    require(!paused,"Vault Paused");
    require(paymentlist[_id].to != address(0),"Payment don't exist");
    require(!paymentlist[_id].paused, "Payment paused");
    require(paymentlist[_id].approved==true,"Payment not yet aproved");
    require(paymentlist[_id].paid==false,"Payment already paid");    
    require(paymentlist[_id].validblock < block.number,"Wait for a valid block to send payment");
    require(paymentlist[_id].amount <= address(this).balance,"Not enough balance to process this payment");
    paymentlist[_id].paid=true;
    address payable __to=payable(paymentlist[_id].to);
    __to.transfer(paymentlist[_id].amount);
    emit Paid(_id);
  }
}