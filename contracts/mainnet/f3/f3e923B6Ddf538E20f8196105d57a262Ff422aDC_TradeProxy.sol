/* This contract is used to hold and transfer ERC20 token for transferring asset using fiat payments*/

pragma solidity 0.8.13;

interface IERC20 {

    /**
     * @dev Returns the amount of tokens in existence.
    */

    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
    */

    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
    */

    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
    */ 

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
} 

struct Sign {
    uint8 v;
    bytes32 r;
    bytes32 s;
    uint256 nonce;
}

struct Order {
    address seller;
    address buyer;
    address erc20Address;
    address nftAddress;
    BuyingAssetType nftType;
    uint unitPrice;
    uint amount;
    uint tokenId;
    uint256 supply;
    string tokenURI;
    uint256 fee;
    uint qty;
    bool isDeprecatedProxy;
    bool isErc20Payment;
}

enum BuyingAssetType {ERC1155, ERC721 , LazyMintERC1155, LazyMintERC721}

interface ITrade {

    function buyAndTransferAsset(Order memory order, bool _import, Sign memory sign) external returns(bool);
    function mintAndTransferAsset(Order memory order, Sign memory ownerSign, Sign memory sign, bool isShared) external returns(bool);
    function buyAndTransferAssetWithEth(Order memory order, bool _import, Sign memory sign) external payable returns (bool);
    function mintAndTransferAssetWithEth(Order memory order, Sign memory ownerSign, Sign memory sign, bool isShared) external payable returns(bool);

}


contract TradeProxy {

    address public owner;
    address public trade;
    address public transferProxy;
    address public depreciatedTransferProxy;

    constructor(address _trade, address _transferProxy, address _depreciatedTransferProxy) {
        owner = msg.sender;
        trade = _trade;
        transferProxy = _transferProxy;
        depreciatedTransferProxy = _depreciatedTransferProxy;
    }

      /**
     * @dev Throws if called by any account other than the owner.
    */    

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }


    function transferOwnership(address newOwner) public onlyOwner returns(bool){
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        owner = newOwner;
        return true;
    }

    function updateOperators(address _trade, address _transferProxy, address _depreciatedTransferProxy) public onlyOwner returns(bool){
        trade = _trade;
        transferProxy = _transferProxy;
        depreciatedTransferProxy = _depreciatedTransferProxy;
        return true;
    }

    function depositErc20(uint amount, address tokenAddress) public{   
        IERC20 token = IERC20(tokenAddress);
        token.transferFrom(msg.sender, address(this), amount);
    }
    
    function withdrawErc20(uint amount, address tokenAddress) public onlyOwner{
        IERC20 token = IERC20(tokenAddress);
        token.transfer(msg.sender, amount);
    }
    
    receive() external payable {}
    
    function withdrawEth(uint amount) public onlyOwner{
        payable(msg.sender).transfer(amount);
    }


    function _buyAndTransferAsset(Order memory order, bool _import, Sign memory sign) public returns(bool) {
        ITrade tradeContract = ITrade(trade);
        if (order.isErc20Payment){
            require((checkBalance(order.erc20Address) >= order.amount), 'Not enough balance');
            if (order.isDeprecatedProxy){
                require(approveSpending(order.erc20Address, depreciatedTransferProxy, order.amount), 'Approval for spending failed');
            }else{
                require(approveSpending(order.erc20Address, transferProxy, order.amount), 'Approval for spending failed');
            }
            return tradeContract.buyAndTransferAsset(order, _import, sign);
        }else{
            require(address(this).balance >= order.amount, "Not Enough Balance");   
            return tradeContract.buyAndTransferAssetWithEth{value: order.amount}(order, _import, sign);
        }
        
    }

    function _mintAndTransferAsset(Order memory order, Sign memory ownerSign, Sign memory sign, bool isShared) public returns(bool) {
        ITrade tradeContract = ITrade(trade);
        if (order.isErc20Payment){
            require((checkBalance(order.erc20Address) >= order.amount), 'Not enough balance');
            if (order.isDeprecatedProxy){
                require(approveSpending(order.erc20Address, depreciatedTransferProxy, order.amount), 'Approval for spending failed');
            }else{
                require(approveSpending(order.erc20Address, transferProxy, order.amount), 'Approval for spending failed');
            }
            return tradeContract.mintAndTransferAsset(order, ownerSign, sign, isShared);
        }else{
            require(address(this).balance >= order.amount, "Not Enough Balance");   
            return tradeContract.mintAndTransferAssetWithEth{value: order.amount}(order, ownerSign, sign, isShared);
        }
    }

    function approveSpending(address erc20, address receipient, uint amount) internal returns(bool){
        IERC20 token = IERC20(erc20);
        token.approve(receipient, amount);
        return true;
    }

    function checkBalance(address erc20) public view returns(uint){
        IERC20 token = IERC20(erc20);
        return token.balanceOf(address(this));
    }

}