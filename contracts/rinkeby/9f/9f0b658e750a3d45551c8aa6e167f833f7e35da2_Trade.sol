/**
 *Submitted for verification at Etherscan.io on 2022-04-06
*/

pragma solidity ^0.8.4;

interface IERC165 {

  

    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC1155 is IERC165 {

    function mint(address from, string memory uri, uint256 supply, uint96 fee)  external returns(uint256, bool);

    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view returns (address receiver, uint256 royaltyAmount);

    /**
        @notice Transfers `_value` amount of an `_id` from the `_from` address to the `_to` address specified (with safety call).
        @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
        MUST revert if `_to` is the zero address.
        MUST revert if balance of holder for token `_id` is lower than the `_value` sent.
        MUST revert on any other error.
        MUST emit the `TransferSingle` event to reflect the balance change (see "Safe Transfer Rules" section of the standard).
        After the above conditions are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call `onERC1155Received` on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).
        @param _from    Source address
        @param _to      Target address
        @param _id      ID of the token type
        @param _value   Transfer amount
        @param _data    Additional data with no specified format, MUST be sent unaltered in call to `onERC1155Received` on `_to`
    */

    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external;

}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
*/

interface IERC20 {

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
    */ 

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

}

contract Trade {

    enum BuyingAssetType {ERC1155, ERC721}

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event SellerFee(uint8 sellerFee);
    event BuyerFee(uint8 buyerFee);
    event Transferred(address indexed from, address indexed to, uint indexed tokenId, uint qty);
    event Minted(address from, address indexed to, uint256 tokenId, uint256 supply);

    uint8 public buyerFee;
    uint8 public sellerFee;
    address public owner;
    address public signer;
    mapping(uint256 => bool) private usedNonce;
    IERC20 public token;

    enum orderType {
        buy,
        sell
    }

    struct Fee {
        uint platformFee;
        uint assetFee;
        uint royaltyFee;
        uint price;
        address tokenCreator;
    }

    /* An ECDSA signature. */
    struct Sign {
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 nonce;
    }

    struct Order {
        address seller;
        address buyer;
        bool isETH; 
        address nftAddress;
        orderType _orderType; 
        uint amount;
        uint tokenId;
        uint qty;
    }
   

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    constructor (uint8 _buyerFee, uint8 _sellerFee) {
        buyerFee = _buyerFee;
        sellerFee = _sellerFee;
        owner = msg.sender;
        signer = msg.sender;
    }

    function setBuyerServiceFee(uint8 _buyerFee) external onlyOwner returns(bool) {
        buyerFee = _buyerFee;
        emit BuyerFee(buyerFee);
        return true;
    }

    function setSellerServiceFee(uint8 _sellerFee) external onlyOwner returns(bool) {
        sellerFee = _sellerFee;
        emit SellerFee(sellerFee);
        return true;
    }

    function transferOwnership(address newOwner) external onlyOwner returns(bool){
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        return true;
    }

    function verifySigner(bytes32 hash, Sign memory sign) internal pure returns(address) {
        return ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)), sign.v, sign.r, sign.s); 
    }

    function isVerifiedOrder(Order memory order, Sign calldata sign) internal view {
        bytes32 hash = keccak256(abi.encodePacked(this, order.seller, order.buyer,order.isETH, order.nftAddress,order.amount, order.tokenId, order.qty, sign.nonce));
        require(signer == verifySigner(hash, sign), " sign verification failed");
    }

    function isVerifiedMinting(address nftAddress, string memory uri, address caller, Sign calldata sign) internal view {
            bytes32 hash = keccak256(abi.encodePacked(this, nftAddress, uri, caller, sign.nonce));
        require(signer == verifySigner(hash, sign), " sign verification failed");
    }

    function calculateFees(uint paymentAmt, address nftAddress, uint tokenId) internal view returns(Fee memory){
        address tokenCreator;
        uint platformFee;
        uint royaltyFee;
        uint assetFee;
        uint price = paymentAmt * 1000 / (1000 + buyerFee);
        uint _buyerFee = paymentAmt - price;
        uint _sellerFee = price * sellerFee/ 1000;
        platformFee = _buyerFee + _sellerFee;
        (tokenCreator, royaltyFee) = IERC1155(nftAddress).royaltyInfo(tokenId, price);
        assetFee = price - royaltyFee - sellerFee;
        return Fee(platformFee, assetFee, royaltyFee, price, tokenCreator);
    }

    function transferAsset(Order memory order, Fee memory fee) internal virtual {
        IERC1155(order.nftAddress).safeTransferFrom(order.seller, order.buyer, order.tokenId, 1,"");
       if(!order.isETH){
        if(fee.platformFee > 0) {
            token.transferFrom(order.buyer, owner, fee.platformFee);
        }
        if(fee.royaltyFee > 0) {
            token.transferFrom( order.buyer, fee.tokenCreator, fee.royaltyFee);
        }
       token.transferFrom( order.buyer, order.seller, fee.assetFee);}
       else{
             if(fee.platformFee > 0) {
            payable(owner).transfer(fee.platformFee);
        }
           if(fee.royaltyFee > 0) {
              payable(fee.tokenCreator).transfer(fee.platformFee);
        }
           payable(order.seller).transfer(fee.platformFee);} 
    }

   
    /**  
        excuteOrder excutes the  selling and buying HiveNFTs orders.
        @param order struct contains set of parameters like seller,buyer,tokenId..., etc.
        function returns the bool value always true;

    */
    function excuteOrder(Order memory order, Sign calldata sign) external returns(bool) {
        require(!usedNonce[sign.nonce],"Nonce : Invalid Nonce");
        usedNonce[sign.nonce] = true;
        isVerifiedOrder(order, sign);
        Fee memory fee = calculateFees(order.amount, order.nftAddress, order.tokenId);
        if(order._orderType == orderType.sell) order.seller = msg.sender;
        if(order._orderType == orderType.buy) order.buyer = msg.sender;
        transferAsset(order,fee);
        emit Transferred(order.seller, order.buyer, order.tokenId, order.amount);
        return true;
    }

    function createNFT(address nftAddress, string memory uri, uint256 supply, uint96 fee, Sign calldata sign) external payable {
        require(!usedNonce[sign.nonce],"Nonce : Invalid Nonce");
        usedNonce[sign.nonce] = true;
        isVerifiedMinting(nftAddress, uri, msg.sender, sign);
        bool paid = getFee();
        require(paid, "Minting: ETH transfer failed");
        (uint256 tokenId, bool mint) = IERC1155(nftAddress).mint(msg.sender, uri, supply, fee);
        require(mint, "Minting: NFT Minting Failed");
        emit Minted(address(0), msg.sender, tokenId, supply);
    }

function getFee() internal returns(bool) {
        require(msg.value >= 0.01 * 10 ** 18, "Mint: value must be greater tha 0.01 eth");
        if(msg.value >= 0.01 * 10 ** 18){
            if((payable(owner).send(0.01 * 10 ** 18))) return true;
        }
        return false;
    }
    function setERC20(address _addr) external onlyOwner{
        token=IERC20(_addr);

    }


}