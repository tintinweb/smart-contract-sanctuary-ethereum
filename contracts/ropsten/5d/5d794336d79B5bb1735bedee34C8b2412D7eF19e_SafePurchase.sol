// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.15;
contract SafePurchase {

    struct Purchase{
        uint  value;
        address payable  seller;
        address payable  buyer;
        State  state;
    }
    

    enum State { Created, Locked, Release, Inactive }
    // The state variable has a default value of the first member, `State.created`
    

    modifier condition(bool _condition) {
        require(_condition);
        _;
    }

    /// Only the buyer can call this function.
    error OnlyBuyer();
    /// Only the seller can call this function.
    error OnlySeller();
    /// The function cannot be called at the current state.
    error InvalidState();
    /// The provided value has to be even.
    error ValueNotEven();

    ///Purchase item already exists
    error ItemExists(); 

    modifier onlyBuyer(uint256 id) {
        if (msg.sender != purchases[id].buyer)
            revert OnlyBuyer();
        _;
    }

    modifier onlySeller(uint256 id) {
        if (msg.sender != purchases[id].seller)
            revert OnlySeller();
        _;
    }

    modifier inState(State _state,uint256 id) {
        if (purchases[id].state != _state)
            revert InvalidState();
        _;
    }

    modifier existPurchaseItem(uint256 id){
        if(purchases[id].seller != address(0))
            revert ItemExists();
        _;
    }

    event RegisteredPurchase(uint256 id,uint256 price,address seller);
    event Aborted(uint256 id);
    event PurchaseConfirmed(uint256 id);
    event ItemReceived(uint256 id);
    event SellerRefunded(uint256 id);

    mapping(uint256 =>Purchase) public purchases;
    uint256 public purchaseCounter = 1;

    function registerPurchase(uint256 id)public payable existPurchaseItem(id){
        Purchase storage newPurchase = purchases[id];
        newPurchase.seller =payable( msg.sender);
        newPurchase.value = msg.value/2;
        purchaseCounter++;
        if ((2 * newPurchase.value) != msg.value)
             revert ValueNotEven();
        emit RegisteredPurchase(id,newPurchase.value,msg.sender);
    }

    function getPurchase(uint256 id) public view returns (uint256 , address , address,uint){
        Purchase storage p = purchases[id];
        return (p.value,p.buyer,p.seller,uint (p.state));
    }

    function abort(uint256 id)
        public
        onlySeller(id)
        inState(State.Created,id)
    {
        emit Aborted(id);
        purchases[id].state = State.Inactive;
        // We use transfer here directly. It is
        // reentrancy-safe, because it is the
        // last call in this function and we
        // already changed the state.
        purchases[id].seller.transfer(purchases[id].value*2);
    }

    /// Confirm the purchase as buyer.
    /// Transaction has to include `2 * value` ether.
    /// The ether will be locked until confirmReceived
    /// is called.
    function confirmPurchase(uint256 id)
        public
        inState(State.Created,id)
        condition(msg.value == (2 * purchases[id].value))
        payable
    {
        emit PurchaseConfirmed(id);
        purchases[id].buyer = payable(msg.sender);
        purchases[id].state = State.Locked;
    }

    /// Confirm that you (the buyer) received the item.
    /// This will release the locked ether.
    function confirmReceived(uint256  id)
        public
        onlyBuyer(id)
        inState(State.Locked,id)
    {
        emit ItemReceived(id);
        // It is important to change the state first because
        // otherwise, the contracts called using `send` below
        // can call in again here.
        purchases[id].state = State.Release;

        purchases[id].buyer.transfer(purchases[id].value);
    }

    /// This function refunds the seller, i.e.
    /// pays back the locked funds of the seller.
    function refundSeller(uint256 id)
        public
        onlySeller(id)
        inState(State.Release,id)
    {
        emit SellerRefunded(id);
        // It is important to change the state first because
        // otherwise, the contracts called using `send` below
        // can call in again here.
        purchases[id].state = State.Inactive;

        purchases[id].seller.transfer(3 * purchases[id].value);
    }
}