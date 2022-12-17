/**
 *Submitted for verification at Etherscan.io on 2022-12-17
*/

/**
 *Submitted for verification at Etherscan.io on 2022-12-13
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

interface IExchangeFactory {
    function getFees() external view returns(uint taker_fee_numerator_, uint taker_fee_denominator_, uint maker_fee_numerator_, uint maker_fee_denominator_);
    function feeTo() external view returns (address);
    function weth() external view returns (address);
}

interface IExchangePair {
    event CreateOrder(bytes32 hash,address maker, address buyToken, address sellToken, uint buyAmount, uint sellAmount);
    event CancleOrder(bytes32 hash);

    event ExecutedOrder(
        bytes32 makerHash,
        bytes32 takerHash,
        address maker,
        address taker,
        address makerSellToken,
        address takerSellToken,
        uint256 makerSellAmount,
        uint256 takerSellAmount,
        uint fee
    );
    
    event PartialExecutedOrder(
        bytes32 makerHash,
        bytes32 takerHash,
        address maker,
        address taker,
        address makerSellToken,
        address takerSellToken,
        uint256 makerSellAmount,
        uint256 takerSellAmount,
        uint fee
    );
    function getOrderByHash(bytes32 _hash) external view returns (
        address maker,
        bytes32[] memory takerOrderHashs, 
        address sellToken,
        address buyToken,
        uint256 sellAmount,
        uint256 pSellAmt,
        uint256 buyAmount,   
        uint256 pBuyAmt,
        uint256 fee, 
        uint256 createdAt,
        LibOrder.Status  status 
    ); 
    function getMakerByHash(bytes32 _hash) external view returns (address maker); 
    function createOrderTokensForTokens(address _user, address _buyToken, address _sellToken, uint _buyAmount, uint _sellAmount) external;
    function createOrderETHForTokens(address _user ,address _buyToken ,address _sellToken, uint _buyAmount,uint _sellAmount)external;
    function createOrderTokensForETH(address _user ,address _buyToken ,address _sellToken, uint _buyAmount,uint _sellAmount)external payable;
    function cancleOrder(bytes32 _hash) external returns (bool);
}

interface IWETH {
    function deposit() external payable ;
    function withdraw(uint wad) external payable;
    function approve(address guy, uint wad) external returns (bool);
    function transfer(address dst, uint wad) external returns (bool);
    function transferFrom(address src, address dst, uint wad) external returns (bool);
    function balanceOf(address _owner) external returns (uint);
    function allowance(address _owner, address _spender ) external returns(uint);
    event  Approval(address indexed src, address indexed guy, uint wad);
    event  Transfer(address indexed src, address indexed dst, uint wad);
    event  Deposit(address indexed dst, uint wad);
    event  Withdrawal(address indexed src, uint wad);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

library LibOrder {
    //keccak256("Order(address user,address sellToken,address buyToken,uint256 sellAmount,uint256 buyAmount,uint256 expirationTimeSeconds)")
    bytes32 internal constant _EIP712_ORDER_SCHEMA_HASH = 0x68d868c8698fc31da3a36bb7a184a4af099797794701bae97bea3de7ebe6e399;

    enum Status {
        PENDING,
        PARTIALCOMPLETED,
        COMPLETED,
        CANCLED
    }

    struct Order {
        address maker;
        bytes32[] takerOrderHashs; 
        address[] taker;
        uint[] amount;
        address sellToken; 
        address buyToken; 
        uint256 sellAmount;
        uint256 pSellAmt;
        uint256 buyAmount;
        uint256 pBuyAmt;
        uint256 fee; 
        uint256 createdAt;
        uint256 executedAt;
        Status status;
    }

    struct OrderInfo {
        bytes32[] orderQueqe; 
        uint256 lastIndex; 
    }
    

    function getOrderHash(address user, address sellToken ,address buyToken,uint256 sellAmount,uint256 buyAmount, uint256 createdAt) internal pure returns (bytes32 orderHash) {
        orderHash = keccak256(abi.encode(_EIP712_ORDER_SCHEMA_HASH, user, sellToken, buyToken, sellAmount, buyAmount, createdAt));   
    }

}

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

library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

contract ExchangePair {
    using LibOrder for LibOrder.Order;

    address public factory;
    address public baseToken;
    address public fiatToken;
    
    uint public lastPrice;
    mapping(bytes32 => bool) public cancelled;
    mapping(bytes32 => bool) public compleated;
    mapping(bytes32 => LibOrder.Order) private orderByHash;
    mapping(uint => LibOrder.OrderInfo) private orders;

    uint private unlocked = 1;

    event CreateOrder(bytes32 indexed  hash,address indexed maker, address buyToken, address sellToken, uint buyAmount, uint sellAmount);
    event CancleOrder(bytes32 indexed hash);

    event ExecutedOrder(
        bytes32 indexed makerHash,
        bytes32 indexed takerHash,
        address indexed maker,
        address  taker,
        address makerSellToken,
        address takerSellToken,
        uint256 makerSellAmount,
        uint256 takerSellAmount,
        uint fee
    );
    
    event PartialExecutedOrder(
        bytes32 indexed makerHash,
        bytes32 indexed takerHash,
        address indexed maker,
        address taker,
        address makerSellToken,
        address takerSellToken,
        uint256 makerSellAmount,
        uint256 takerSellAmount,
        uint fee
    );

    modifier lock() {
        require(unlocked == 1, 'Exchange: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    modifier onlyFactory {
        require(factory==msg.sender,"Exchagne:Forbidden");
        _;
    }

    constructor(address _factory) {
        factory = _factory;
    }

    function initialize(address _baseToken, address _fiatToken) external {
        require(msg.sender == factory, 'Exchange: FORBIDDEN');
        baseToken = _baseToken;
        fiatToken = _fiatToken;
    }

    function _createOrderGetHash(address _user, address _buyToken, address _sellToken, uint _buyAmount, uint _sellAmount) internal returns (bytes32 hash_) {
        hash_ = LibOrder.getOrderHash(_user, _sellToken,  _buyToken , _sellAmount, _buyAmount, block.timestamp);
        orderByHash[hash_] =  LibOrder.Order(
            _user,
            new bytes32[](0),
            new address[](0),
            new uint[](0),
            _sellToken,
            _buyToken,
            _sellAmount,
            0,
            _buyAmount,
            0,
            0,
            block.timestamp,
            0,
            LibOrder.Status.PENDING
        );
        emit CreateOrder(hash_, _user,_buyToken, _sellToken, _buyAmount, _sellAmount);
    }

    function checkPrice(address _buyToken, uint _buyAmount, uint _sellAmount) public view  returns(uint price) {
        price = _buyToken==fiatToken ? (_buyAmount*1e18)/_sellAmount : (_sellAmount*1e18)/_buyAmount;
    }

    function createOrderTokensForTokens(address _user, address _buyToken, address _sellToken, uint _buyAmount, uint _sellAmount) external {
        // TransferHelper.safeTransferFrom(_sellToken, _user, address(this), _sellAmount);
        createOrder(_user, _buyToken, _sellToken, _buyAmount, _sellAmount);
    }

    function createOrderETHForTokens(address _user ,address _buyToken ,address _sellToken, uint _buyAmount,uint _sellAmount)external {
        address _weth = IExchangeFactory(factory).weth();
        require(_buyToken == _weth, 'Exchange: INVALID_PATH');
        // TransferHelper.safeTransferFrom(_sellToken, _user, address(this), _sellAmount);
        createOrder(_user, _buyToken, _sellToken, _buyAmount, _sellAmount);
    }

    function createOrderTokensForETH(address _user ,address _buyToken ,address _sellToken, uint _buyAmount,uint _sellAmount)external payable {
        address _weth = IExchangeFactory(factory).weth();
        require(_sellToken == _weth, 'Exchange: INVALID_PATH');
        createOrder(_user, _buyToken, _sellToken, _buyAmount, _sellAmount);
    }


    function _range(uint _price) internal view virtual returns(uint) {
        if(orders[_price].orderQueqe.length!=0)
            return ((orders[_price].orderQueqe.length-orders[_price].lastIndex) > 5 ? (orders[_price].lastIndex+5): orders[_price].orderQueqe.length);
        else 
            return 0;
    }

    function createOrder(address _user, address _buyToken, address _sellToken, uint _buyAmount, uint _sellAmount) internal lock onlyFactory returns (bytes32)  {
        uint _tBuyAmount = _buyAmount;
        uint _tSellAmount = _sellAmount;
        uint takerFee;
        uint makerFee;

        uint price = checkPrice( _buyToken,  _buyAmount,  _sellAmount);
        bytes32 hash_ = _createOrderGetHash( _user,  _buyToken,  _sellToken,  _buyAmount,  _sellAmount);

        for(uint i = orders[price].lastIndex; i< _range(price); i++) {
            bytes32 __hash = orders[price].orderQueqe[i]; 
            if(!cancelled[__hash] &&! compleated[__hash] && orderByHash[hash_].sellToken == orderByHash[__hash].buyToken) {
                    (uint _takerFee, uint _makerFee) = _getFees(
                        _buyToken,
                        (orderByHash[hash_].buyAmount-orderByHash[hash_].pBuyAmt),
                        (orderByHash[hash_].sellAmount-orderByHash[hash_].pSellAmt)
                    );
                    takerFee +=_takerFee;
                    makerFee +=_makerFee;
                    lastPrice = price;

                    orderByHash[hash_].fee += _takerFee; 
                    orderByHash[hash_].executedAt=block.timestamp;
                    orderByHash[hash_].takerOrderHashs.push(__hash);

                    orderByHash[__hash].fee += _makerFee;
                    orderByHash[__hash].executedAt= block.timestamp;
                    orderByHash[__hash].takerOrderHashs.push(hash_);

                if ((orderByHash[__hash].sellAmount - orderByHash[__hash].pSellAmt) > (orderByHash[hash_].buyAmount-orderByHash[hash_].pBuyAmt)) { 

                    _transfer(_buyToken,orderByHash[hash_].maker,(orderByHash[hash_].buyAmount-orderByHash[hash_].pBuyAmt)-_takerFee);
                    _transfer(_sellToken,orderByHash[__hash].maker,(orderByHash[hash_].sellAmount - orderByHash[hash_].pSellAmt)-_makerFee);
                    emit PartialExecutedOrder(
                        __hash,
                        hash_, 
                        orderByHash[__hash].maker,
                        orderByHash[hash_].maker,
                        orderByHash[__hash].sellToken,
                        orderByHash[hash_].sellToken,
                        (orderByHash[__hash].sellAmount-orderByHash[__hash].pSellAmt),
                        (orderByHash[hash_].sellAmount-orderByHash[hash_].pSellAmt),
                        _makerFee
                    );

                    emit ExecutedOrder(
                        hash_,
                        __hash,
                        orderByHash[hash_].maker,
                        orderByHash[__hash].maker,
                        orderByHash[hash_].sellToken,
                        orderByHash[__hash].sellToken,
                        (orderByHash[hash_].sellAmount-orderByHash[hash_].pSellAmt),
                        (orderByHash[__hash].sellAmount-orderByHash[__hash].pSellAmt),
                        _takerFee
                    );

                    orderByHash[__hash].pSellAmt +=  (orderByHash[hash_].buyAmount-orderByHash[hash_].pBuyAmt);
                    orderByHash[__hash].pBuyAmt +=  (orderByHash[hash_].sellAmount-orderByHash[hash_].pSellAmt);
                    orderByHash[hash_].pSellAmt += _sellAmount;
                    orderByHash[hash_].pBuyAmt += _buyAmount;

                    compleated[hash_] = true;  
                  
                    orderByHash[hash_].status = LibOrder.Status.COMPLETED;
                    orderByHash[__hash].status = LibOrder.Status.PARTIALCOMPLETED;                   

                    _tBuyAmount = 0;
                    _tSellAmount = 0;  
                    break;

                } else {
                    _tBuyAmount = _tBuyAmount - (orderByHash[__hash].sellAmount - orderByHash[__hash].pSellAmt);
                    _tSellAmount = _tSellAmount - (orderByHash[__hash].buyAmount - orderByHash[__hash].pBuyAmt);
                    orderByHash[__hash].status = LibOrder.Status.COMPLETED;
                    
                    compleated[__hash] = true;
                    orders[price].lastIndex = i + 1;  

                    if(_tBuyAmount!=0) {
                        _transfer(_buyToken,orderByHash[hash_].maker,(orderByHash[__hash].sellAmount-orderByHash[__hash].pSellAmt)-_takerFee);
                        _transfer(_sellToken,orderByHash[__hash].maker,(orderByHash[__hash].buyAmount-orderByHash[__hash].pBuyAmt)-_makerFee);

                        emit PartialExecutedOrder(
                            hash_,
                            __hash,
                            orderByHash[hash_].maker,
                            orderByHash[__hash].maker,
                            orderByHash[hash_].sellToken,
                            orderByHash[__hash].sellToken,
                            (orderByHash[hash_].sellAmount-orderByHash[hash_].pSellAmt),
                            (orderByHash[__hash].sellAmount-orderByHash[__hash].pSellAmt),
                            _takerFee
                        );

                        emit ExecutedOrder(
                            __hash,
                            hash_,
                            orderByHash[__hash].maker,
                            orderByHash[hash_].maker,
                            orderByHash[__hash].sellToken,
                            orderByHash[hash_].sellToken,
                            (orderByHash[__hash].sellAmount-orderByHash[__hash].pSellAmt),
                            (orderByHash[hash_].sellAmount-orderByHash[hash_].pSellAmt),
                            _makerFee
                        );

                        orderByHash[hash_].status = LibOrder.Status.PARTIALCOMPLETED;
                        orderByHash[hash_].pBuyAmt += (orderByHash[__hash].sellAmount - orderByHash[__hash].pSellAmt); 
                        orderByHash[hash_].pSellAmt += (orderByHash[__hash].buyAmount - orderByHash[__hash].pBuyAmt); 
                        orderByHash[__hash].pSellAmt = orderByHash[__hash].sellAmount; 
                        orderByHash[__hash].pBuyAmt = orderByHash[__hash].buyAmount;
                    } else {

                        _transfer(_buyToken,orderByHash[hash_].maker,(orderByHash[hash_].buyAmount - orderByHash[hash_].pBuyAmt) - _takerFee);
                        _transfer(_sellToken,orderByHash[__hash].maker,(orderByHash[hash_].sellAmount - orderByHash[hash_].pSellAmt) - _makerFee);

                        emit ExecutedOrder(
                            hash_,
                            __hash,
                            orderByHash[hash_].maker,
                            orderByHash[__hash].maker,
                            orderByHash[hash_].sellToken,
                            orderByHash[__hash].sellToken,
                            (orderByHash[hash_].sellAmount-orderByHash[hash_].pSellAmt),
                            (orderByHash[__hash].sellAmount-orderByHash[__hash].pSellAmt),
                            _takerFee
                        );

                        emit ExecutedOrder(
                            __hash,
                            hash_,
                            orderByHash[__hash].maker,
                            orderByHash[hash_].maker,
                            orderByHash[__hash].sellToken,
                            orderByHash[hash_].sellToken,
                            (orderByHash[__hash].sellAmount-orderByHash[__hash].pSellAmt),
                            (orderByHash[hash_].sellAmount-orderByHash[hash_].pSellAmt),
                            _makerFee
                        );
                        
                        orderByHash[hash_].status = LibOrder.Status.COMPLETED;
                        compleated[hash_] = true;
                        orderByHash[hash_].pSellAmt = orderByHash[hash_].sellAmount; 
                        orderByHash[hash_].pBuyAmt = orderByHash[hash_].buyAmount; 
                        orderByHash[__hash].pSellAmt = orderByHash[__hash].sellAmount; 
                        orderByHash[__hash].pBuyAmt = orderByHash[__hash].buyAmount;
                        break;
                    }
                }
            }
        }

        _takeFee( _buyToken, _sellToken, takerFee, makerFee);
        if(_tBuyAmount!=0)
            orders[price].orderQueqe.push(hash_);
        return hash_;
    }

    function getTakersByOrderHash(bytes32 _hash) external view returns(bytes32[] memory) {
            return orderByHash[_hash].takerOrderHashs;
    } 

    function _transfer(address _token,address _to, uint _amount) internal {
        address _weth = IExchangeFactory(factory).weth();
        if(_token==_weth){
            // payable(_to).transfer(_amount);
            TransferHelper.safeTransferETH(_to, _amount);
        } else {
            // IERC20(_token).transfer(_to,_amount);
            TransferHelper.safeTransfer(_token, _to,_amount);
        }
    }

    function _takeFee(address _buyToken,address _sellToken,uint takerFee,uint makerFee) internal  {
        if(takerFee!=0){
            // IERC20(_buyToken).transfer(IExchangeFactory(factory).feeTo(),takerFee);
            _transfer(_buyToken,IExchangeFactory(factory).feeTo(), takerFee);
        } 
        if(makerFee!=0) {
            // IERC20(_sellToken).transfer(IExchangeFactory(factory).feeTo(),makerFee);
            _transfer(_sellToken,IExchangeFactory(factory).feeTo(), makerFee);
        }
    }

    function _getFees(
      address buyToken,
      uint makerBuyAmount,
      uint makerSellAmount
    ) internal view returns(uint,uint) {
        (uint taker_fee_numerator, uint taker_fee_denominator, uint maker_fee_numerator, uint maker_fee_denominator) = IExchangeFactory(factory).getFees();
        uint takerFee;
        uint makerFee;
        if(buyToken==baseToken) {
            makerFee = makerBuyAmount * maker_fee_numerator / maker_fee_denominator;
            takerFee = makerSellAmount * taker_fee_numerator / taker_fee_denominator;
        } else {
            takerFee = makerBuyAmount * maker_fee_numerator / maker_fee_denominator;
            makerFee = makerSellAmount * taker_fee_numerator / taker_fee_denominator;
        }

        return (takerFee,makerFee);
    }

    function cancleOrder(bytes32 _hash) external onlyFactory {
        require(!cancelled[_hash],"Exchange: Order Already Cancled!");
        require(!compleated[_hash],"Exchange: Order Already Completed!");
        orderByHash[_hash].status = LibOrder.Status.CANCLED;
        cancelled[_hash] = true;
        _transfer(orderByHash[_hash].sellToken,orderByHash[_hash].maker,(orderByHash[_hash].sellAmount-orderByHash[_hash].pSellAmt));
        // IERC20(orderByHash[_hash].sellToken).transfer(orderByHash[_hash].maker,(orderByHash[_hash].sellAmount-orderByHash[_hash].pSellAmt));
        emit CancleOrder(_hash);
    }

    function getOrdersByPrice(uint256 price) external  view returns  (uint lastIndex,bytes32[] memory queqe) {
        return (orders[price].lastIndex,orders[price].orderQueqe);
    }
    
    function getOrderByHash(bytes32 _hash) external view returns (
        address maker,
        bytes32[] memory takerOrderHashs, 
        address sellToken,
        address buyToken,
        uint256 sellAmount,
        uint256 pSellAmt,
        uint256 buyAmount,   
        uint256 pBuyAmt,
        uint256 fee, 
        uint256 createdAt,
        uint256 executedAt,
        LibOrder.Status  status 
    ) {
            maker= orderByHash[_hash].maker;
            takerOrderHashs= orderByHash[_hash].takerOrderHashs;
            sellToken= orderByHash[_hash].sellToken;
            buyToken= orderByHash[_hash].buyToken;
            sellAmount= orderByHash[_hash].sellAmount;
            pSellAmt= orderByHash[_hash].pSellAmt;
            buyAmount= orderByHash[_hash].buyAmount;
            pBuyAmt= orderByHash[_hash].pBuyAmt;
            fee= orderByHash[_hash].fee;
            createdAt = orderByHash[_hash].createdAt;
            executedAt = orderByHash[_hash].executedAt;
            status =  orderByHash[_hash].status;
    }

    function getMakerByHash(bytes32 _hash) external view returns (address maker) {
        maker= orderByHash[_hash].maker;
    }
}