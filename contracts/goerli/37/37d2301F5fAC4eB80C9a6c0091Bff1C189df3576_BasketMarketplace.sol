//SPDX-License-Identifier: MIT
/**
 * @dev @brougkr
 */
pragma solidity 0.8.17;
contract BasketMarketplace
{
    struct Order
    {
        address Seller;           // Seller Address
        address Reservee;         // Reserves Basket For Specific User 
        address[] OfferedNFTs;    // NFT Addresses
        address[] RequestedNFTs;  // NFT Addresses
        uint[] OfferedTokenIDs;   // NFT TokenIDs
        uint[] RequestedTokenIDs; // NFT TokenIDs
        address ERC20;            // Optional ERC20 Payment Address
        uint ETHPrice;            // Optional ETH Price For Basket
        uint ERC20Price;          // Optional ERC20 Price For Basket
        bool Fulfilled;           // If The Order Is Fulfilled
    }

    struct Params
    {
        address _Owner;
        address _Namespace;
    }
    
    Params public _Params;
    Order[] public Orders;                            // All Orders
    mapping(address=>bool) public Allowlist;          // Allowlist For ERC20 Payment Tokens
    mapping(address=>uint[]) public UserOrderIndexes; // User Order Indexes

    event OfferCreated(address Seller, uint OrderIndex);  // Offer Created Event
    event OrderFulfilled(address Buyer, uint OrderIndex); // Order Fulfilled Event

    constructor() 
    {
        _Params._Owner = msg.sender;
        Allowlist[address(0)] = true;
    }

    /**
     * @dev Offers A Basket Of OfferedNFTs For Sale
     * @param OfferedNFTs       | Array Of Offered NFT Addresses
     * @param RequestedNFTs     | Array Of Requested NFT Addresses
     * @param OfferedTokenIDs   | Array Of Offered NFT TokenIDs
     * @param RequestedTokenIDs | Array Of Requested NFT TokenIDs
     * @param Reservee          | Optional Reservee Address (Reserves Basket For Specific User)
     * @param ERC20             | Optional ERC20 Payment Address
     * @param ETHPrice          | Optional ETH Price For Basket
     * @param ERC20Price        | Optional ERC20 Price For Basket
     */
    function Offer (
        address[] calldata OfferedNFTs, 
        address[] calldata RequestedNFTs,
        uint[] calldata OfferedTokenIDs,
        uint[] calldata RequestedTokenIDs,
        address Reservee,
        address ERC20,
        uint ETHPrice,
        uint ERC20Price
    ) external onlyAccount {
        require(Allowlist[ERC20], "Basket: Input ERC20 Address Is Not Valid Payment Method");
        uint NextOrderIndex = Orders.length;
        for(uint x; x < OfferedNFTs.length; x++) { require(IERC721(OfferedNFTs[x]).ownerOf(OfferedTokenIDs[x]) == msg.sender, "Basket: You Do Not Own The Offered NFT"); }
        Orders.push(Order(msg.sender, Reservee, OfferedNFTs, RequestedNFTs, OfferedTokenIDs, RequestedTokenIDs, ERC20, ETHPrice, ERC20Price, false));
        UserOrderIndexes[msg.sender].push(NextOrderIndex);
        emit OfferCreated(msg.sender, NextOrderIndex);
    }

    /**
     * @dev Fulfills Order
     */
    function FulfillOffer ( uint OrderIndex ) external payable onlyAccount
    {
        Order memory _Order = Orders[OrderIndex];
        require(!_Order.Fulfilled, "Basket: Order Already Fulfilled");
        require(_Order.Seller != address(0), "Basket: Order Does Not Exist");
        require(msg.sender != _Order.Seller, "Basket: Cannot Fulfill Your Own Order");
        Orders[OrderIndex].Fulfilled = true;
        if(_Order.Reservee != address(0)) { require(msg.sender == _Order.Reservee, "Basket: Offer Reserved For Another User"); }
        if(_Order.ETHPrice > 0) 
        { 
            require(msg.sender.balance >= _Order.ETHPrice, "Basket: Insufficient ETH Balance");
            require(msg.value == _Order.ETHPrice, "Basket: Incorrect ETH Amount Sent");
            payable(_Order.Seller).transfer(_Order.ETHPrice); 
        }
        if(_Order.ERC20Price > 0) 
        { 
            require(IERC20(_Order.ERC20).balanceOf(msg.sender) >= _Order.ERC20Price, "Basket: Insufficient ERC20 Balance");
            IERC20(_Order.ERC20).transferFrom(msg.sender, _Order.Seller, _Order.ERC20Price); 
        }
        for(uint x; x < _Order.OfferedNFTs.length; x++) 
        { 
            IERC721(_Order.OfferedNFTs[x]).transferFrom(_Order.Seller, msg.sender, _Order.OfferedTokenIDs[x]); 
        }
        for(uint y; y < _Order.RequestedNFTs.length; y++) 
        { 
            IERC721(_Order.RequestedNFTs[y]).transferFrom(msg.sender, _Order.Seller, _Order.RequestedTokenIDs[y]); 
        }
        emit OrderFulfilled(msg.sender, OrderIndex);
    }

    /**
     * @dev Returns An Order At `OrderIndex`
     */
    function ViewOrder(uint OrderIndex) public view returns (Order memory) { return Orders[OrderIndex]; }

    /**
     * @dev Returns All Orders
     */
    function ViewOrders(uint StartingIndex, uint EndingIndex) public view returns (Order[] memory)
    {
        uint Range = EndingIndex - StartingIndex;
        Order[] memory _Orders = new Order[](Range);
        for(uint x; x < Range; x++) { _Orders[x] = Orders[StartingIndex + x]; }
        return _Orders;
    }

    /**
     * @dev Returns All Order Indexes For `User`
     */
    function ViewUserOrderIndexes(address User) public view returns (uint[] memory) { return UserOrderIndexes[User]; }

    /**
     * @dev Returns All Orders For `User`
     */
    function ViewUserOrders(address User) public view returns (Order[] memory)
    {
        uint[] memory _UserOrderIndexes = UserOrderIndexes[User];
        Order[] memory _UserOrders = new Order[](_UserOrderIndexes.length);
        for(uint x; x < _UserOrderIndexes.length; x++) { _UserOrders[x] = Orders[_UserOrderIndexes[x]]; }
        return _UserOrders;
    }

    /**
     * @dev Changes The Namespace NFT Address
     */
    function _ChangeNamespaceAddress(address NewAddress) external onlyOwner { _Params._Namespace = NewAddress; }

    /**
     * @dev Transfers Ownership Of The Contract
     */
    function _TransferOwnership(address NewAddress) external onlyOwner { _Params._Owner = NewAddress; }

    /**
     * @dev Withdraws All ETH Mistakenly Sent To The Contract
     */
    function _WithdrawETH() external onlyOwner { payable(msg.sender).transfer(address(this).balance); }

    /**
     * @dev Access Modifier For Blockspace Accounts
     */
    modifier onlyAccount
    {
        require(INamespace(_Params._Namespace).ViewAccountCreationStatus(msg.sender), "BasketMarketplace | onlyAccount | `msg.sender` Is Not A Blockspace Account");
        _;
    }

    /**
     * @dev Access Modifier For Owner
     */
    modifier onlyOwner
    {
        require(msg.sender == _Params._Owner, "BasketMarketplace | onlyOwner | `msg.sender` Is Not Owner");
        _;
    }
}

interface INamespace { function ViewAccountCreationStatus(address Wallet) external view returns (bool); }

interface IERC20 
{ 
    function balanceOf(address account) external view returns (uint256); 
    function transferFrom(address From, address To, uint256 Amount) external returns (bool);
}

interface IERC721 
{ 
    function transferFrom(address from, address to, uint256 tokenId) external; 
    function ownerOf(uint tokenId) external view returns (address);
}