/**
 *Submitted for verification at Etherscan.io on 2022-12-03
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

pragma solidity 0.8.10;

interface IExchangeFactory {
    function getFees() external view returns(uint taker_fee_numerator_, uint taker_fee_denominator_, uint maker_fee_numerator_, uint maker_fee_denominator_);
    function feeTo() external view returns (address);
}

pragma solidity 0.8.10;
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
pragma solidity 0.8.10;


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
        address sellToken; 
        address buyToken; 
        uint256 sellAmount;
        uint256 pSellAmt;
        uint256 buyAmount;
        uint256 pBuyAmt;
        uint256 makerFee; 
        uint256 takerFee; 
        uint256 expirationTimeSeconds;
        Status status;
    }

    struct OrderInfo {
        bytes32[] orderQueqe; 
        uint256 lastIndex; 
    }
    

    function getOrderHash(address user, address sellToken ,address buyToken,uint256 sellAmount,uint256 buyAmount, uint256 expirationTimeSeconds) internal pure returns (bytes32 orderHash) {
        orderHash = keccak256(
        abi.encode(_EIP712_ORDER_SCHEMA_HASH, user, sellToken, buyToken, sellAmount, buyAmount, expirationTimeSeconds)
        );   
    }

}
pragma solidity 0.8.10;
//S
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

contract ExchangeFactory  is Ownable {

    address public feeTo;

    uint256 maker_fee_numerator = 3;
    uint256 maker_fee_denominator = 1000;
    uint256 taker_fee_numerator = 3;
    uint256 taker_fee_denominator = 1000;

    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;
    event PairCreated(address indexed token0, address indexed token1, address pair, uint );

    constructor(address _feeTo) {
        feeTo = _feeTo;
    }
    function allPairsLength() external view returns (uint) {
        return allPairs.length;
    }

    function createPair(address baseToken, address qouteToken) external returns (address) {
        require(baseToken != qouteToken, 'Exchange: IDENTICAL_ADDRESSES');
        require(baseToken != address(0) && qouteToken != address(0), 'Exchange: ZERO_ADDRESS');
        require(getPair[baseToken][qouteToken] == address(0), 'Exchange: PAIR_EXISTS');
        bytes32 salt = keccak256(abi.encodePacked(baseToken, qouteToken));

        ExchangePair pair = new ExchangePair{salt:salt}(address(this));
        pair.initialize(baseToken, qouteToken);
        getPair[baseToken][qouteToken] = address(pair);
        getPair[qouteToken][baseToken] = address(pair); 
        allPairs.push(address(pair));
        emit PairCreated(baseToken, qouteToken, address(pair), allPairs.length);
        return address(pair);
    }

    function setFees(
        uint256 _taker_fee_numerator,
        uint256 _taker_fee_denominator,
        uint256 _maker_fee_numerator,
        uint256 _maker_fee_denominator
    ) public  onlyOwner{
  
        taker_fee_numerator = _taker_fee_numerator;
        taker_fee_denominator = _taker_fee_denominator;
        maker_fee_numerator = _maker_fee_numerator;
        maker_fee_denominator = _maker_fee_denominator;
    }

    function getFees() public view returns(uint taker_fee_numerator_, uint taker_fee_denominator_, uint maker_fee_numerator_, uint maker_fee_denominator_){
            taker_fee_numerator_ = taker_fee_numerator;
            taker_fee_denominator_ = taker_fee_denominator;
            maker_fee_numerator_ = maker_fee_numerator;
            maker_fee_denominator_ = maker_fee_denominator;
    }

    function setFeeTo(address _feeTo) external onlyOwner{
        feeTo = _feeTo;
    }


}

pragma solidity 0.8.10;

contract ExchangePair {
    using LibOrder for LibOrder.Order;

    address public factory;
    address public baseToken;
    address public fiatToken;
    
    uint public lastPrice;
    mapping(bytes32 => bool) public cancelled;
    mapping(bytes32 => bool) public compleated;
    mapping(bytes32 => LibOrder.Order) public orderByHash;
    mapping(uint => LibOrder.OrderInfo) private orders;

    uint private unlocked = 1;

    event CreateOrder(bytes32 hash, address buyToken, address sellToken, uint buyAmount, uint sellAmount, uint256 price);
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
        uint256 makerVolumeFee,
        uint256 takerVolumeFee
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
        uint256 makerVolumeFee,
        uint256 takerVolumeFee
    );
 
    modifier lock() {
        require(unlocked == 1, 'Exchange: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    constructor(address _factory) {
        factory = _factory;
    }

    function initialize(address _baseToken, address _fiatToken) external {
        require(msg.sender == factory, 'Exchange: FORBIDDEN');
        baseToken = _baseToken;
        fiatToken = _fiatToken;
    }

    function createOrder(address _user, address _buyToken, address _sellToken, uint _buyAmount, uint _sellAmount) public lock returns (uint _tBuyAmount , uint _tSellAmount)  {
        require(_buyToken==fiatToken || _buyToken==baseToken && _sellToken==fiatToken||_sellToken==baseToken,"ExchangePair: Invalid Token Address!");
        IERC20 sellToken = IERC20(_sellToken);
        IERC20 buyToken = IERC20(_buyToken);
        require(sellToken.allowance(_user,address(this))>=_sellAmount,"ExchagnePair: Allownace Exceed!");
        _tBuyAmount = _buyAmount;
        _tSellAmount = _sellAmount;
        uint takerFee;
        uint makerFee;
        sellToken.transferFrom(_user,address(this),_sellAmount);
        uint price = _buyToken==fiatToken ? (_buyAmount*1e18)/_sellAmount : (_sellAmount*1e18)/_buyAmount;

        bytes32 hash_ = LibOrder.getOrderHash(_user, _sellToken,  _buyToken , _sellAmount, _buyAmount, block.timestamp);
        orderByHash[hash_] =  LibOrder.Order(_user, new bytes32[](0), _sellToken,  _buyToken , _sellAmount,0, _buyAmount,0, 0, 0, block.timestamp,LibOrder.Status.PENDING);
        emit CreateOrder(hash_, _buyToken, _sellToken, _buyAmount, _sellAmount, price);

        for(uint i = orders[price].lastIndex; i<orders[price].orderQueqe.length; i++) {

            bytes32 __hash = orders[price].orderQueqe[i];
            ( uint _takerFee, uint _makerFee) = _settleMatchedOrders(
                (orderByHash[__hash].sellAmount-orderByHash[__hash].pSellAmt),
                (orderByHash[hash_].sellAmount-orderByHash[hash_].pSellAmt)
            );

            takerFee +=_takerFee;
            makerFee +=_makerFee;
            lastPrice = price;

            if(!cancelled[__hash] &&! compleated[__hash] && orderByHash[hash_].sellToken == orderByHash[__hash].buyToken) {
                
                    orderByHash[hash_].takerFee += _takerFee; 
                    orderByHash[__hash].makerFee += _makerFee;

                    orderByHash[hash_].takerOrderHashs.push(__hash);
                    orderByHash[__hash].takerOrderHashs.push(hash_);

                if ((orderByHash[__hash].sellAmount - orderByHash[__hash].pSellAmt) > (orderByHash[hash_].buyAmount-orderByHash[hash_].pBuyAmt)) { 

                    buyToken.transfer(orderByHash[hash_].maker, (orderByHash[hash_].buyAmount-orderByHash[hash_].pBuyAmt)-_takerFee);
                    sellToken.transfer(orderByHash[__hash].maker, (orderByHash[hash_].sellAmount - orderByHash[hash_].pSellAmt)-_makerFee);

                    emit PartialExecutedOrder(
                        __hash,
                        hash_, 
                        orderByHash[__hash].maker,
                        orderByHash[hash_].maker,
                        orderByHash[__hash].sellToken,
                        orderByHash[hash_].sellToken,
                        (orderByHash[__hash].sellAmount-orderByHash[__hash].pSellAmt),
                        (orderByHash[hash_].sellAmount-orderByHash[hash_].pSellAmt),
                        _makerFee,
                        0
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
                        0,
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
                        buyToken.transfer(orderByHash[hash_].maker, (orderByHash[hash_].buyAmount-orderByHash[hash_].pBuyAmt)-_takerFee);
                        sellToken.transfer(orderByHash[__hash].maker, (orderByHash[hash_].sellAmount - orderByHash[hash_].pSellAmt)-_makerFee);

                        emit PartialExecutedOrder(
                            hash_,
                            __hash,
                            orderByHash[hash_].maker,
                            orderByHash[__hash].maker,
                            orderByHash[hash_].sellToken,
                            orderByHash[__hash].sellToken,
                            (orderByHash[hash_].sellAmount-orderByHash[hash_].pSellAmt),
                            (orderByHash[__hash].sellAmount-orderByHash[__hash].pSellAmt),
                            0,
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
                            _makerFee,
                            0
                        );

                        orderByHash[hash_].status = LibOrder.Status.PARTIALCOMPLETED;
                        orderByHash[hash_].pBuyAmt += (orderByHash[__hash].sellAmount - orderByHash[__hash].pSellAmt); 
                        orderByHash[hash_].pSellAmt += (orderByHash[__hash].buyAmount - orderByHash[__hash].pBuyAmt); 
                        orderByHash[__hash].pSellAmt = orderByHash[__hash].sellAmount; 
                        orderByHash[__hash].pBuyAmt = orderByHash[__hash].buyAmount;



                    } else {

                        buyToken.transfer(orderByHash[hash_].maker, (orderByHash[hash_].buyAmount-orderByHash[hash_].pBuyAmt)-_takerFee);
                        sellToken.transfer(orderByHash[__hash].maker, (orderByHash[hash_].sellAmount - orderByHash[hash_].pSellAmt)-_makerFee);

                        emit ExecutedOrder(
                            hash_,
                            __hash,
                            orderByHash[hash_].maker,
                            orderByHash[__hash].maker,
                            orderByHash[hash_].sellToken,
                            orderByHash[__hash].sellToken,
                            (orderByHash[hash_].sellAmount-orderByHash[hash_].pSellAmt),
                            (orderByHash[__hash].sellAmount-orderByHash[__hash].pSellAmt),
                            0,
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
                            _makerFee,
                            0
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

        if(takerFee!=0){
            buyToken.transfer(IExchangeFactory(factory).feeTo(),takerFee);
        } 
        if(makerFee!=0) {
            sellToken.transfer(IExchangeFactory(factory).feeTo(),makerFee);
        }
        if(_tBuyAmount!=0)
            orders[price].orderQueqe.push(hash_);
    }

    function getTakersByOrderHash(bytes32 _hash) external view returns(bytes32[] memory) {
            return orderByHash[_hash].takerOrderHashs;
    } 

    function _settleMatchedOrders(
      uint makerSellAmount,
      uint takerSellAmount
    ) internal view returns(uint,uint) {
        (uint taker_fee_numerator, uint taker_fee_denominator, uint maker_fee_numerator, uint maker_fee_denominator) = IExchangeFactory(factory).getFees();
        uint takerFee = makerSellAmount * taker_fee_numerator / taker_fee_denominator;
        uint makerFee = takerSellAmount * maker_fee_numerator / maker_fee_denominator;
        return (takerFee,makerFee);
    }

    function cancleOrder(bytes32 _hash) external {
        require(orderByHash[_hash].maker == msg.sender,"Exchange: Forbidden");
        require(!cancelled[_hash],"Exchange: Order Already Cancled!");
        require(!compleated[_hash],"Exchange: Order Already Completed!");
        orderByHash[_hash].status = LibOrder.Status.CANCLED;
        cancelled[_hash] = true;
        IERC20(orderByHash[_hash].sellToken).transfer(orderByHash[_hash].maker,(orderByHash[_hash].sellAmount-orderByHash[_hash].pSellAmt));
        emit CancleOrder(_hash);
    }

    function getOrdersByPrice(uint256 price) external  view returns  (uint lastIndex,bytes32[] memory queqe) {
        return (orders[price].lastIndex,orders[price].orderQueqe);
    }
    

}