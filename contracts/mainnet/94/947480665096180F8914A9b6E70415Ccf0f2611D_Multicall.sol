//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./IPancakeFactory.sol";
import "./IPancakePair.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IIDOExtra {
    function extras(address) external view returns(address factory);
}

interface IIDO {
    enum PoolStatus {
        Inprogress,
        Listed,
        Cancelled,
        Unlocked
    }
    enum PoolTier {
        Nothing,
        Gold,
        Platinum,
        Diamond,
        Alpha
    }
    struct PoolModel {
        uint256 hardCap; // how much project wants to raise
        uint256 softCap; // how much of the raise will be accepted as successful IDO
        uint256 presaleRate;
        uint256 dexCapPercent;
        uint256 dexRate;
        address projectTokenAddress; //the address of the token that project is offering in return
        PoolStatus status; //: by default “Upcoming”,
        PoolTier tier;
        bool kyc;
    }
    function isHiddenPool(address) external view returns (bool);
    function fundRaiseToken(address) external view returns (address);
    function fairLaunch(address) external view returns (bool);
    function fairPresaleAmount(address) external view returns (uint256);
    function _weiRaised(address) external view returns (uint256);
    function isStealth(address) external view returns (bool);
    function totalSupply(address) external view returns (uint256);

    function poolInformation(address) external view returns (PoolModel memory);
    function poolDetails(address) external view returns (
        uint256 startDateTime,
        uint256 endDateTime,
        uint256 listDateTime,
        uint256 minAllocationPerUser,
        uint256 maxAllocationPerUser,
        uint256 dexLockup,
        string memory extraData,
        bool whitelistable,
        bool audit,
        string memory auditLink);
    function poolAddresses(uint256) external view returns (address);
    function poolOwners(address) external view returns (address);
    function getPoolAddresses() external view returns (address[] memory);
}

interface ILock {
    struct TokenList {
        uint256 amount;
        uint256 startDateTime;
        uint256 endDateTime;
        address owner;
        address creator;
    }

    function liquidities(uint256) external view returns (address);

    function tokens(uint256) external view returns (address);

    function getTokenDetails(address) external view returns (TokenList[] memory);

    function getLiquidityDetails(address) external view returns (TokenList[] memory);
}

contract Multicall is Initializable, OwnableUpgradeable {
    // enum PoolStatus {
    //     Inprogress,
    //     Listed,
    //     Cancelled,
    //     Unlocked
    // }
    // struct PoolModel {
    //     uint256 hardCap; // how much project wants to raise
    //     uint256 softCap; // how much of the raise will be accepted as successful IDO
    //     uint256 presaleRate;
    //     uint256 dexCapPercent;
    //     uint256 dexRate;
    //     address projectTokenAddress; //the address of the token that project is offering in return
    //     PoolStatus status; //: by default “Upcoming”,
    //     PoolTier tier;
    //     bool kyc;
    // }
    // struct TokenList {
    //     uint256 amount;
    //     uint256 startDateTime;
    //     uint256 endDateTime;
    //     address owner;
    //     address creator;
    // }
    struct CardView {
        string name;
        bool isStealth;
        uint256 softCap;
        uint256 hardCap;
        uint8 tier;
        bool kyc;
        bool audit;
        uint256 startDateTime;
        uint256 endDateTime;
        uint8 poolStatus;
        uint256 weiRaised;
        string extraData;
        bool fairLaunch;
        uint256 fairPresaleAmount;
        string fundRaiseToken;
        uint256 marketCap;
    }
    struct Call {
        address target;
        bytes callData;
    }
    struct LiquidityLockList {
        address liquidity;
        uint256 amount;
        string token0Name;
        string token1Name;
        string token0Symbol;
        string token1Symbol;
        address owner;
    }
    struct TokenLockList {
        address token;
        uint256 amount;
        string name;
        uint8 decimals;
        string symbol;
        address owner;
    }
    struct PresaleLockList {
        address pool;
        address liquidity;
        uint256 amount;
        string token0Name;
        string token1Name;
        string token0Symbol;
        string token1Symbol;
        address owner;
    }
    struct PresaleLockDetail{
        string poolName;
        uint256 value;
        uint256 listedTime;
        uint256 dexLockup;
        address owner;
    }
    address public constant WETH = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    address[] tokensForPrice;
    address public baseToken;
    IPancakeFactory public factory;
    IIDOExtra public constant iIDOExtra=IIDOExtra(0x56EA04f16Bf43f1989c41FaA2532AeC2868Fe045);
    address public constant IDOAddress =
        address(0x6126E7Af6989cfabD2be277C46fB507aa5836CFd);
    address public constant LockAddress =
        address(0x98cBfc7763c8c0a9525154D4C376014A4d00eE83);
    address[] public factoryList;

    function initialize() public initializer {
        __Ownable_init();
    }

    function tokensForPriceList() external view returns (address[] memory) {
        return tokensForPrice;
    }

    function updateTokensForPriceList(
        address[] memory _tokens,
        address _baseToken
    ) external onlyOwner {
        tokensForPrice = _tokens;
        baseToken = _baseToken;
    }

    function updateFactoryList(address[] memory _factoryList) external onlyOwner {
        factoryList=_factoryList;
    }

    function getFactoryList() external view returns (address[] memory) {
        return factoryList;
    }
    function updateFactory(address _factory) external onlyOwner {
        factory = IPancakeFactory(_factory);
    }

    function _getRatio(address target, address base, address _factory)
        internal
        view
        returns (uint256)
    {
        address pair = IPancakeFactory(_factory).getPair(target, base);
        uint8 decimals = IERC20Metadata(target).decimals();
        if (pair != address(0x0) && IERC20Metadata(base).balanceOf(pair)>0) {
            IPancakePair pairContract = IPancakePair(pair);
            bool isToken0 = pairContract.token0() == target;
            (uint256 reserve0, uint256 reserve1, ) = pairContract.getReserves();
            if (isToken0) {
                
                return (reserve1 * (10**decimals)) / reserve0;
            } else {
                return (reserve0 * (10**decimals)) / reserve1;
            }
        } else return 0;
    }

    function getPrice(address token, address _factory) public view returns (uint256) {
        uint256 ratio = _getRatio(token, baseToken, _factory);
        if (ratio > 0) {
            return ratio;
        } else {
            for (uint8 i = 0; i < tokensForPrice.length; i++) {
                ratio = _getRatio(token, tokensForPrice[i], _factory);
                if (ratio > 0) {
                    uint256 ratio1 = _getRatio(tokensForPrice[i], baseToken, address(factory));
                    return
                        (ratio * ratio1) /
                        (10**IERC20Metadata(tokensForPrice[i]).decimals());
                }
            }
            return 0;
        }
    }  

    function getTokenLockList(
        address[] memory tokenAddresses,
        address search
    ) public view returns (TokenLockList[] memory) {
        ILock lock = ILock(LockAddress);
        uint256 n = 0;
        if (search == address(0x0)) {
            TokenLockList[] memory tokens = new TokenLockList[](
                tokenAddresses.length
            );
            
            for (uint256 i = tokenAddresses.length; i > 0; i--) {
                ILock.TokenList[] memory tokenList = lock.getTokenDetails(tokenAddresses[i-1]);             
                tokens[n] = _getTokenLock(tokenAddresses[i-1], tokenList[0].owner);
                n++;                
            }
            return tokens;
        } else {
            TokenLockList[] memory token=new TokenLockList[](1);
            ILock.TokenList[] memory tokenList = lock.getTokenDetails(search);
            
            token[0]=_getTokenLock(search, tokenList[0].owner);
            return token;
        }
    }

    function _getTokenLock(address token, address owner)
        internal
        view
        returns (TokenLockList memory)
    {
        TokenLockList memory tokenLock;
        tokenLock.token = token;
        tokenLock.name = IERC20Metadata(token).name();
        tokenLock.symbol = IERC20Metadata(token).symbol();
        tokenLock.decimals = IERC20Metadata(token).decimals();
        tokenLock.amount = IERC20Metadata(token).balanceOf(LockAddress);
        tokenLock.owner=owner;
        return tokenLock;
    }


    function getOtherLiqList(
        address[] memory liqAddresses,
        address search
    ) public view returns (LiquidityLockList[] memory) {
        ILock lock = ILock(LockAddress);
        uint256 n = 0;
        if (search == address(0x0)) {
            LiquidityLockList[] memory liqs = new LiquidityLockList[](
                liqAddresses.length
            );
            for (uint256 i = liqAddresses.length; i > 0; i--) {
                ILock.TokenList[] memory liqList = lock.getLiquidityDetails(liqAddresses[i-1]);
                liqs[n] = _getLiqLock(liqAddresses[i-1], liqList[0].owner);
                n++;
            }
            return liqs;
        } else {
            LiquidityLockList[] memory liq = new LiquidityLockList[](1);
            ILock.TokenList[] memory liqList = lock.getLiquidityDetails(search);
            liq[0] = _getLiqLock(search, liqList[0].owner);
            return liq;
        }
    }
    function _getLiqLock(address liquidity, address owner)
        internal
        view
        returns (LiquidityLockList memory)
    {
        LiquidityLockList memory liq;
        liq.owner=owner;
        liq.liquidity = liquidity;
        address token0 = IPancakePair(liquidity).token0();
        liq.token0Name = IERC20Metadata(token0).name();
        liq.token0Symbol = IERC20Metadata(token0).symbol();
        address token1 = IPancakePair(liquidity).token1();
        liq.token1Name = IERC20Metadata(token1).name();
        liq.token1Symbol = IERC20Metadata(token1).symbol();
        liq.amount = IPancakePair(liquidity).balanceOf(LockAddress);
        return liq;
    }

    function _getPresaleLock(address pool, IIDO ido)
        internal
        view
        returns (PresaleLockList memory)
    {
        IPancakeFactory _factory= iIDOExtra.extras(pool)==address(0) ? factory : IPancakeFactory(iIDOExtra.extras(pool));
        PresaleLockList memory liq;
        liq.pool = pool;
        address token0 = ido.fundRaiseToken(pool) == address(0x0)
            ? WETH
            : ido.fundRaiseToken(pool);
        address token1 = ido.poolInformation(pool).projectTokenAddress;
        address pair = _factory.getPair(token0, token1);
        liq.owner=ido.poolOwners(pool);
        liq.amount = IPancakePair(pair).balanceOf(pool);
        liq.liquidity = pair;
        liq.token0Name = IERC20Metadata(token0).name();
        liq.token1Name = IERC20Metadata(token1).name();
        liq.token0Symbol = IERC20Metadata(token0).symbol();
        liq.token1Symbol = IERC20Metadata(token1).symbol();
        return liq;
    }

    function getPresaleLiqList(
        address[] memory pools,
        address search
    ) public view returns (PresaleLockList[] memory) {
        IIDO ido = IIDO(IDOAddress);        
        if(search==address(0x0)){
            uint256 n = 0;
            PresaleLockList[] memory liqs = new PresaleLockList[](
                pools.length
            );
            for (uint256 i = pools.length; i > 0; i--) {
                if(ido.isHiddenPool(pools[i-1])) continue;
                if (ido.poolInformation(pools[i-1]).status != IIDO.PoolStatus.Listed) continue;
                liqs[n] = _getPresaleLock(pools[i-1], ido);
                n++;           
            }
            return liqs;
        }else{
            PresaleLockList[] memory liqs = new PresaleLockList[](1);
            for (uint256 i = pools.length; i > 0; i--) {
                if(ido.isHiddenPool(pools[i-1])) continue;
                if (ido.poolInformation(pools[i-1]).status != IIDO.PoolStatus.Listed) continue;
                PresaleLockList memory liq = _getPresaleLock(pools[i-1], ido);
                if(liq.liquidity==search){
                    liqs[0]=liq;
                    break;
                }
            }
            return liqs;
        }  
    }

    function getPresaleLockDetail(address pool, address liquidity) external view returns(PresaleLockDetail memory){
        PresaleLockDetail memory lockDetail;
        IIDO ido = IIDO(IDOAddress);      
        lockDetail.poolName=IERC20Metadata(ido.poolInformation(pool).projectTokenAddress).name();
        address token0=ido.fundRaiseToken(pool);
        token0= token0==address(0x0) ? WETH : token0;
        lockDetail.value=(IPancakePair(liquidity).balanceOf(pool)*getPrice(token0, address(factory))/IPancakePair(liquidity).totalSupply())*
            IERC20Metadata(token0).balanceOf(liquidity)/(10**IERC20Metadata(token0).decimals());
        (,,lockDetail.listedTime,,,lockDetail.dexLockup,,,,)=ido.poolDetails(pool);
        lockDetail.owner=ido.poolOwners(pool);
        return lockDetail;
    }

    function getOtherLockDetail(address liquidity) external view returns(uint256 value, address owner, ILock.TokenList[] memory liqList){
        ILock lock = ILock(LockAddress);
        address token0=IPancakePair(liquidity).token0();
        uint256 price=getPrice(token0, address(factory));
        if(price==0){
            for(uint256 i=0;i<factoryList.length;i++){
                price=getPrice(token0, factoryList[i]);
                if(price>0)
                    break;
            }
        }
        value=(IPancakePair(liquidity).balanceOf(LockAddress)*price/IPancakePair(liquidity).totalSupply())*
            IERC20Metadata(token0).balanceOf(liquidity)/(10**IERC20Metadata(token0).decimals());
        liqList= lock.getLiquidityDetails(liquidity);
        owner=liqList[0].owner;
    }

    // function getUpcomingAndLiveIDOPools() external view returns(address[] memory){
    //     IIDO ido = IIDO(IDOAddress);
    //     address[] memory pools=ido.getPoolAddresses();
    //     address[] memory poolsUL=new address[](pools.length);
    //     uint256 n=0;
    //     for(uint256 i=0;i<pools.length;i++){
    //         if(ido.isHiddenPool(pools[i]))
    //             continue;
    //         if(uint(ido.poolInformation(pools[i]).status) != 0)
    //             continue;
    //         poolsUL[n]=pools[i];
    //         n++;            
    //     }
    //     return poolsUL;
    // }
    // function getIDOCardViewDirect() external view returns(CardView[] memory){        
    //     IIDO ido = IIDO(IDOAddress);
    //     address[] memory pools=ido.getPoolAddresses();
    //     CardView[] memory cardviews=new CardView[](pools.length);
    //     uint256 n=0;
    //     for(uint256 i=0;i<50;i++){
    //         if(!ido.isHiddenPool(pools[i]) && IIDO.PoolStatus.Inprogress==ido.poolInformation(pools[i]).status){
    //             if(!ido.isStealth(pools[i])){                    
    //                 cardviews[n].name=IERC20Metadata(ido.poolInformation(pools[i]).projectTokenAddress).name();
    //                 cardviews[n].isStealth=false;
    //             }else
    //                 cardviews[n].isStealth=true;
    //             cardviews[n].softCap=ido.poolInformation(pools[i]).softCap;
    //             cardviews[n].hardCap=ido.poolInformation(pools[i]).hardCap;
    //             cardviews[n].tier=uint8(ido.poolInformation(pools[i]).tier);
    //             cardviews[n].kyc=ido.poolInformation(pools[i]).kyc;
    //             (cardviews[n].startDateTime,
    //             cardviews[n].endDateTime,
    //             ,
    //             ,
    //             ,
    //             ,
    //             cardviews[n].extraData,
    //             ,
    //             cardviews[n].audit,)=ido.poolDetails(pools[i]);
 
    //             cardviews[n].fairLaunch=ido.fairLaunch(pools[i]);
    //             cardviews[n].fairPresaleAmount=ido.fairPresaleAmount(pools[i]);
    //             uint256 price;
    //             if(ido.fundRaiseToken(pools[i])!=address(0x0)){
    //                 cardviews[n].fundRaiseToken=IERC20Metadata(ido.fundRaiseToken(pools[i])).name();
    //                 price=getPrice(ido.fundRaiseToken(pools[i]), address(factory));
    //             }else{
    //                 cardviews[n].fundRaiseToken=IERC20Metadata(ido.fundRaiseToken(pools[i])).name();
    //                 price=getPrice(WETH, address(factory));
    //             }
                
    //             uint256 totalSupply;
    //             if(!ido.isStealth(pools[i])){
    //                 totalSupply=IERC20Metadata(ido.poolInformation(pools[i]).projectTokenAddress).totalSupply();
    //             }else{
    //                 totalSupply=ido.totalSupply(pools[i]);
    //             }
    //             if(!cardviews[n].fairLaunch)
    //                 cardviews[n].marketCap=totalSupply/ido.poolInformation(pools[i]).dexRate*price;
    //             else
    //                 cardviews[n].marketCap=totalSupply/cardviews[n].fairPresaleAmount*cardviews[n].softCap*price;
    //             n++;     
    //         }
    //     }
    //     return cardviews;
    // }

    function getIDOCardView(address[] memory pools) external view returns(CardView[] memory){        
        CardView[] memory cardviews=new CardView[](pools.length);
        IIDO ido = IIDO(IDOAddress);
        uint256 n=0;
        for(uint256 i=0;i<pools.length;i++){
            if(!ido.isStealth(pools[i])){                    
                cardviews[n].name=IERC20Metadata(ido.poolInformation(pools[i]).projectTokenAddress).name();
                cardviews[n].isStealth=false;
            }else
                cardviews[n].isStealth=true;
            cardviews[n].softCap=ido.poolInformation(pools[i]).softCap;
            cardviews[n].hardCap=ido.poolInformation(pools[i]).hardCap;
            cardviews[n].tier=uint8(ido.poolInformation(pools[i]).tier);
            cardviews[n].poolStatus=uint8(ido.poolInformation(pools[i]).status);
            cardviews[n].weiRaised=ido._weiRaised(pools[i]);
            cardviews[n].kyc=ido.poolInformation(pools[i]).kyc;
            (cardviews[n].startDateTime,
                cardviews[n].endDateTime,
                ,
                ,
                ,
                ,
                cardviews[n].extraData,
                ,
                cardviews[n].audit,)=ido.poolDetails(pools[i]);
            cardviews[n].fairLaunch=ido.fairLaunch(pools[i]);
            cardviews[n].fairPresaleAmount=ido.fairPresaleAmount(pools[i]);
            uint256 price;
            if(ido.fundRaiseToken(pools[i])!=address(0x0)){
                cardviews[n].fundRaiseToken=IERC20Metadata(ido.fundRaiseToken(pools[i])).name();
                price=getPrice(ido.fundRaiseToken(pools[i]), address(factory));
            }else{
                cardviews[n].fundRaiseToken=IERC20Metadata(WETH).name();
                price=getPrice(WETH, address(factory));
            }
            
            uint256 totalSupply;
            if(!ido.isStealth(pools[i])){
                totalSupply=IERC20Metadata(ido.poolInformation(pools[i]).projectTokenAddress).totalSupply();
            }else{
                totalSupply=ido.totalSupply(pools[i]);
            }
            if(!cardviews[n].fairLaunch)
                cardviews[n].marketCap=totalSupply/ido.poolInformation(pools[i]).dexRate*price;
            else
                cardviews[n].marketCap=totalSupply/cardviews[n].fairPresaleAmount*cardviews[n].softCap*price;
            n++;     
        }
        return cardviews;
    }


    function aggregate(Call[] memory calls)
        public
        returns (uint256 blockNumber, bytes[] memory returnData)
    {
        blockNumber = block.number;
        returnData = new bytes[](calls.length);
        for (uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory ret) = calls[i].target.call(
                calls[i].callData
            );
            require(success);
            returnData[i] = ret;
        }
    }

    function multiCall(Call[] memory calls)
        external
        view
        returns (uint256 blockNumber, bytes[] memory results)
    {
        blockNumber = block.number;
        results = new bytes[](calls.length);

        for (uint256 i; i < calls.length; i++) {
            (bool success, bytes memory result) = calls[i].target.staticcall(
                calls[i].callData
            );
            require(success, "call failed");
            results[i] = result;
        }
    }

    // function getIDO(uint256 number, address IDOAddress)
    //     external
    //     view
    //     returns (uint256 blockNumber, bytes[] memory results)
    // {
    //     blockNumber = block.number;
    //     results = new bytes[](number>20 ? 20 : number);
    //     uint256 end=number-(number>20 ? 20 : number);
    //     IDO ido=new IDO(IDOAddress);
    //     for (uint i=number-1; i >=end; i--) {
    //         (bool success, bytes memory result) = calls[i].target.staticcall(calls[i].callData);
    //         require(success, "call failed");
    //         results[i] = result;
    //     }
    // }

    function getDate(Call[] memory calls)
        public
        returns (uint256 blockNumber, bytes[] memory returnData)
    {
        blockNumber = block.number;
        returnData = new bytes[](calls.length);
        for (uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory ret) = calls[i].target.call(
                calls[i].callData
            );
            require(success);
            returnData[i] = ret;
        }
    }

    // Helper functions
    function getEthBalance(address addr) public view returns (uint256 balance) {
        balance = addr.balance;
    }

    function getBlockHash(uint256 blockNumber)
        public
        view
        returns (bytes32 blockHash)
    {
        blockHash = blockhash(blockNumber);
    }

    function getLastBlockHash() public view returns (bytes32 blockHash) {
        blockHash = blockhash(block.number - 1);
    }

    function getCurrentBlockTimestamp()
        public
        view
        returns (uint256 timestamp)
    {
        timestamp = block.timestamp;
    }

    function getCurrentBlockDifficulty()
        public
        view
        returns (uint256 difficulty)
    {
        difficulty = block.difficulty;
    }

    function getCurrentBlockGasLimit() public view returns (uint256 gaslimit) {
        gaslimit = block.gaslimit;
    }

    function getCurrentBlockCoinbase() public view returns (address coinbase) {
        coinbase = block.coinbase;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IPancakeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;

    function INIT_CODE_PAIR_HASH() external view returns (bytes32);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IPancakePair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;
    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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
}