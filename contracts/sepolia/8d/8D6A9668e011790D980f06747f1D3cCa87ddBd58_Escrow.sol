/**
 *Submitted for verification at Etherscan.io on 2023-06-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
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


interface IShieldpay {
   function transfer(address receipent) external payable;
    function transferBusd(address recipient, uint256 amount) external;

}

contract Escrow is Ownable {
     string public name = "escrow contract";
     enum ItemState { PLACE,OFFERED, AWAITING_DELIVERY, COMPLETE , CANCEL }
    IShieldpay public shieldPay;  //Reference to BossoinCoin contract   

struct Item{
        address  seller;
        uint8 quantity;
        uint128 price;
        bytes32  key; //unique string identifier          
    }

     struct EscrowItem{
        address  seller;
        address  buyer;   
        uint8 paymentType; 
        ItemState state;
        uint128 price;
        bytes32  key; //unique string identifier    
              
    } //item published for sale in escrow arragement
    
    mapping (bytes32 => Item) public stocks; //balances from each buyer/seller and escrow account
    mapping (bytes32 => EscrowItem) public escrowItems; 

    error InvalidType();
    error ItemNotInList();
    error AmountIsNotValid();
    error CanNotBeSame();
    error CanNotPlaceOffer();
    error SellerCanNotZero();
    error  ItemAlreadyCompleted( );

    //@dev: constructor for BossonEscrow
    //@params: takes in the address of the ShieldPay contract 
    constructor (address _shieldPay) {
         shieldPay = IShieldpay(_shieldPay);         
    }

    // onlyOwner , onlyseller , onlybuyer

    modifier onlySeller(bytes32 _key){
     EscrowItem memory item = escrowItems[_key];
     if(item.seller != _msgSender()) revert();
     _;
    }

      modifier onlyBuyer(bytes32 _key){
     EscrowItem memory item = escrowItems[_key];
     if(item.buyer != _msgSender()) revert();
     _;
    }
     
     //@dev:  add item to the list
    function addItem(address _seller , bytes32 _key , uint128 _price , uint8 _quantity) public{
        if(_seller == address(0)) revert SellerCanNotZero();
        Item memory itemList;
        itemList.seller = _seller;
        itemList.price = _price;
        itemList.quantity = _quantity;
        stocks[_key] = itemList;
    }

     //@dev:  buyer funds are transfered to escrow account

     function buyerPlaceOrder( uint8 _paymentType, uint128 amount , bytes32 _key , bytes32 itemKey)  public payable {
        if( !(_paymentType == 0 || _paymentType ==1)) revert InvalidType();
        Item memory itemList = stocks[itemKey];
        if(itemList.seller == address(0)) revert ItemNotInList();
        if(!(itemList.price + calculatePercentage(itemList.price) == uint128(msg.value))) revert AmountIsNotValid();
        EscrowItem memory item;
        item.seller = itemList.seller;
        item.buyer = msg.sender;
        item.state = ItemState.PLACE;
        if(_paymentType == 0){ // for native currency
         item.price = uint128(msg.value);
        } else if(_paymentType == 1){
            item.price= amount;
        }
        escrowItems[_key] = item;

     }

         //@dev:  buyer funds are transfered to escrow account
     function sellerOfferItem( bytes32 _key) onlySeller(_key) public payable {
               EscrowItem memory item = escrowItems[_key];
               if(item.seller != _msgSender()) revert CanNotPlaceOffer();
               item.state = ItemState.OFFERED;
     }


          //@dev:  buyer funds are transfered to escrow account
     function sellerDispatchItem( bytes32 _key) onlySeller(_key)public payable {
               EscrowItem memory item = escrowItems[_key];
               item.state = ItemState.AWAITING_DELIVERY;
     }

             //@dev:  buyer funds are transfered to seller and admin account 
     function buyerCompleteOrder( bytes32 _key , bytes32 _itemKey)  onlyBuyer(_key) public  {
              Item memory itemList = stocks[_itemKey];
        if(itemList.seller == address(0)) revert ItemNotInList();

               EscrowItem memory item = escrowItems[_key];
                if(item.state == ItemState.COMPLETE) revert ItemAlreadyCompleted();
               item.state = ItemState.COMPLETE;
               itemList.quantity -=1;
               // total of 5% = 2.5 from buyer and seller
               uint128 buyerCut = calculatePercentage(item.price);
                uint128 sellerCut = calculatePercentage(item.price - buyerCut);
                  (bool success, ) = payable(owner()).call{
            value: (sellerCut + buyerCut)
        }("");
        if(!success) revert();
      
        shieldPay.transfer{value:item.price - (buyerCut + sellerCut)}(item.seller);
            
     }
     function calculatePercentage(uint128 price) private pure returns(uint128){
        return ((price) * 25) / 1000;
        
     }


      receive() external payable {
        }
 }