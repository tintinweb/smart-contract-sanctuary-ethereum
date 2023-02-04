pragma solidity ^0.8.9;
//SPDX-License-Identifier: MIT

// -------------------------------------------------------------------------------------------------------
// kys.systems                                                                              Payment module
//
//
//
//
// UI:
// - [Admin] Create new bill      =====>  createBill([address] user, [uint] amount, [string] billId)
// - [Admin] Change billed amount =====>  changeBilledAmount([address] user, [string] billId, [uint] amount)
// - Read billed amount           =====>  readBilledAmount([address] user, [string] billId)
// - Charge for "no interview"    =====>  generalPayments([uint8] 0)
// - Charge for "with interview"  =====>  generalPayments([uint8] 2)
// - Charge for custom offer      =====>  customPayments([uint] billId)
//
// -------------------------------------------------------------------------------------------------------
//
// For custom offer user has to give us his address beforehand
// Flow:
//  1. Create bill for address with amount, bill id
//  2. User calls function from known address, provides bill id
//  3. Pays
//
// How to charge users:
//  1. Approve user spending allowance on USDT contract
//      - Call "approve" on USDT contract 
//      - spender => this contract
//      - amount => price/amount from bill
//  2. Call either generalPayments or customPayments
//
// -------------------------------------------------------------------------------------------------------

import "@openzeppelin/contracts/access/Ownable.sol"; 
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
//import "./interfaces/IERC20.sol";

contract KYCPayments is Ownable {

    // -------------------------------------------------------------------------------------------------------
    // ------------------------------- DECLARATIONS
    // -------------------------------------------------------------------------------------------------------

    // @notice                  bill keeps track of custom prices
    struct                      Bill {
      mapping(string => uint)   amountBilled;
      mapping(string => bool)   idUsed;
    }

    // @dev                     nested mapping address => (string => int)
    mapping(address => Bill)    dbBills;

    // @notice                  USDT token address via interface
    IERC20 public               USDT;

    // @notice                  an array of prices for services
    //                          0 — Owner no interview
    //                          1 - Owner with interview 
    uint256[] public            prices;




    // -------------------------------------------------------------------------------------------------------
    // ------------------------------- EVENTS
    // -------------------------------------------------------------------------------------------------------

    // @param                   [address] user => user completed a payment
    // @param                   [uint256] amount => payment amount
    // @param                   [uint8] _type => service option
    //                                          0 — Owner no interview
    //                                          1 - Owner with interview 
    //                                          3 - Custom offer
    // @param                   [string] billId => bill id
    // @dev                     billId returns "none" for predefined payments (first 2 types)
    event                       PaymentCompleted(address indexed user, uint256 amount, uint8 _type, string billId);





    // -------------------------------------------------------------------------------------------------------
    // ------------------------------- CONSTRUCTOR
    // -------------------------------------------------------------------------------------------------------

    // @param                   [address] _usdt => usdt contract address
    // @param                   [uint256] _price1 => price for 1st offer
    // @param                   [uint256] _price2 => price for 2nd offer
    constructor(address _usdt, uint256 _price1, uint256 _price2) {
        USDT = IERC20(_usdt);
        prices.push(_price1);
        prices.push(_price2);
        _transferOwnership(msg.sender);
    }




    // -------------------------------------------------------------------------------------------------------
    // ------------------------------- FIN CONTROL
    // -------------------------------------------------------------------------------------------------------

    // @notice                  allows to modify the price
    // @param                   [uint8] _priceToChange => offer index in the prices array:
    //                                                     0 — Owner no interview
    //                                                     1 - Owner with interview 
    // @param                   [uint256] _newPrice => new price
    function                    changePrice(uint8 _priceToChange, uint256 _newPrice) external onlyOwner {
        require(_priceToChange == 0 || _priceToChange == 1, "Incorrect option!");
        require(_newPrice > 0, "New price can't be zero!");
        prices[_priceToChange] = _newPrice;
    }

    // @notice                  function to return contract's USDT balance
    function                    readBalance() view external onlyOwner returns(uint256) {
        return(USDT.balanceOf(address(this)));
    }

    // @notice                  withdraws contract balance to specified address
    // @param                   [uint256] _newPrice => new price
    function                    withdrawBalance(address _to) external onlyOwner {
        require(_to != address(0), "Address can't be zero!");
        require(USDT.transfer(_to, USDT.balanceOf(address(this))) == true, "Failed to transfer USDT!");
    }




    // -------------------------------------------------------------------------------------------------------
    // ------------------------------- CUSTOM OFFERS
    // -------------------------------------------------------------------------------------------------------

    // @notice                  restricts reading billed info only to address owner & owner
    modifier                    onlyAuthorized(address _addr) {
        require(msg.sender == _addr || msg.sender == owner(), "Not authorized!");
        _;
    }

    // @notice                  creates a new bill for user
    // @param                   [address] _addr => user billed
    // @param                   [uint256] _amount => billed amount
    // @param                   [string] _billId => bill id
    function                    createBill(address _addr, uint256 _amount, string memory _billId) external onlyOwner {
        require(!dbBills[_addr].idUsed[_billId], "Bill id is not available!");
        dbBills[_addr].amountBilled[_billId] = _amount;
        dbBills[_addr].idUsed[_billId] = true;
    }

    // @notice                  billed amount getter
    // @param                   [address] _addr => user billed
    // @param                   [string] _billId => bill id
    function                    readBilledAmount(address _addr, string memory _billId) external view onlyAuthorized(_addr) returns(uint256) {
      return(dbBills[_addr].amountBilled[_billId]);
    }

    // @notice                  billed amount setter
    // @param                   [address] _addr => user billed
    // @param                   [string] _billId => bill id
    // @param                   [uint256] _new_amount => new bill amount
    function                    changeBilledAmount(address _addr, string memory _billId, uint256 _new_amount) external onlyOwner {
        dbBills[_addr].amountBilled[_billId] = _new_amount;
    }





    // -------------------------------------------------------------------------------------------------------
    // ------------------------------- PAYMENTS
    // -------------------------------------------------------------------------------------------------------

    // @notice                  predefined payment
    // @param                   [uint8] _offerChoice => offer index in the prices array:
    //                                                  0 — Owner no interview
    //                                                  1 - Owner with interview 
    function                    generalPayments(uint8 _offerChoice) external {
        require(_offerChoice == 0 || _offerChoice == 1, "Incorrect option!");
        require(USDT.allowance(msg.sender, address(this)) >= prices[_offerChoice],
                      "Not enough allowance, approve your USDT first!");
        require(USDT.balanceOf(msg.sender) >= prices[_offerChoice], 
                      "Not enough USDT!");
        require(USDT.transferFrom(msg.sender, 
                                  address(this), 
                                  prices[_offerChoice]) == true, 
                                  "Failed to transfer USDT!");
        emit PaymentCompleted(msg.sender, prices[_offerChoice], _offerChoice, "none");
    }

    // @notice                  payment via bill
    // @param                   [string] _billId => bill id
    function                    customPayments(string memory _billId) external {
      uint256                   amount;

      amount = dbBills[msg.sender].amountBilled[_billId];
      require(amount > 0, "Invalid bill!");
      require(USDT.allowance(msg.sender, address(this)) >= amount,
                      "Not enough allowance, approve your USDT first!");
      require(USDT.balanceOf(msg.sender) >= amount, 
                      "Not enough USDT!");
      require(USDT.transferFrom(msg.sender, 
                                address(this), 
                                amount) == true, 
                                "Failed to transfer USDT!");
      emit PaymentCompleted(msg.sender, amount, 2, _billId);
    }





    // -------------------------------------------------------------------------------------------------------
    // ------------------------------- MISC
    // -------------------------------------------------------------------------------------------------------

    // @notice                  disable renounceOwnership
    function                    renounceOwnership() public pure override {
        require(false, "This function is disabled");
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