// f0c581c562514ca526c5d2f24ac2f771073b8774
// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.17;

import "AclPriceFeedAggregatorBASE.sol";



contract AclPriceFeedAggregatorETH is AclPriceFeedAggregatorBASE {
    
    address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    constructor() {
        tokenMap[ETH] = WETH;   //nativeToken to wrappedToken
        tokenMap[address(0)] = WETH;
        priceFeedAggregator[address(0)] = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
        priceFeedAggregator[ETH] = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;// ETH
        priceFeedAggregator[WETH] = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;// WETH
        priceFeedAggregator[0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599] = 0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c;// WBTC & BTC / USD
        priceFeedAggregator[0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984] = 0x553303d460EE0afB37EdFf9bE42922D8FF63220e;// UNI
        priceFeedAggregator[0x514910771AF9Ca656af840dff83E8264EcF986CA] = 0x2c1d072e956AFFC0D435Cb7AC38EF18d24d9127c;// LINK
        priceFeedAggregator[0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48] = 0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6;// USDC
        priceFeedAggregator[0xdAC17F958D2ee523a2206206994597C13D831ec7] = 0x3E7d1eAB13ad0104d2750B8863b489D65364e32D;// USDT
        priceFeedAggregator[0x6B175474E89094C44Da98b954EedeAC495271d0F] = 0xAed0c38402a5d19df6E4c03F4E2DceD6e29c1ee9;// DAI
        priceFeedAggregator[0x853d955aCEf822Db058eb8505911ED77F175b99e] = 0xB9E1E3A9feFf48998E45Fa90847ed4D467E8BcfD;// FRAX
        priceFeedAggregator[0xAf5191B0De278C7286d6C7CC6ab6BB8A73bA2Cd6] = address(0);// STG
        priceFeedAggregator[0x5A98FcBEA516Cf06857215779Fd812CA3beF1B32] = address(0);// LDO
        priceFeedAggregator[0xD533a949740bb3306d119CC777fa900bA034cd52] = 0xCd627aA160A6fA45Eb793D19Ef54f5062F20f33f;// CRV
        priceFeedAggregator[0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B] = 0xd962fC30A72A84cE50161031391756Bf2876Af5D;// CVX
        priceFeedAggregator[0x4d224452801ACEd8B2F0aebE155379bb5D594381] = 0xD10aBbC76679a20055E167BB80A24ac851b37056;// ApeCoin
        priceFeedAggregator[0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84] = address(0);// stETH
        priceFeedAggregator[0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0] = address(0);// wstETH
    }
}

// f0c581c562514ca526c5d2f24ac2f771073b8774
// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.17;

import "Ownable.sol";

interface AggregatorV3Interface {
    function latestRoundData() external view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function decimals() external view returns (uint8);
}

interface IERC20 {
    function decimals() external view returns (uint8);
}


contract AclPriceFeedAggregatorBASE is TransferOwnable{
    
    uint256 public constant DECIMALS_BASE = 18;
    mapping(address => address) public priceFeedAggregator;
    mapping(address => address) public tokenMap;

    struct PriceFeedAggregator {
        address token; 
        address priceFeed; 
    }

    event PriceFeedUpdated(address indexed token, address indexed priceFeed);
    event TokenMap(address indexed nativeToken, address indexed wrappedToken);

    function getUSDPrice(address _token) public view returns (uint256,uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(priceFeedAggregator[_token]);
        require(address(priceFeed) != address(0), "priceFeed not found");
        (uint80 roundId, int256 price, , uint256 updatedAt, uint80 answeredInRound) = priceFeed.latestRoundData();
        require(price > 0, "Chainlink: price <= 0");
        require(answeredInRound >= roundId, "Chainlink: answeredInRound <= roundId");
        require(updatedAt > 0, "Chainlink: updatedAt <= 0");
        return (uint256(price) , uint256(priceFeed.decimals()));
    }

    function getUSDValue(address _token , uint256 _amount) public view returns (uint256) {
        if (tokenMap[_token] != address(0)) {
            _token = tokenMap[_token];
        } 
        (uint256 price, uint256 priceFeedDecimals) = getUSDPrice(_token);
        uint256 usdValue = (_amount * uint256(price) * (10 ** DECIMALS_BASE)) / ((10 ** IERC20(_token).decimals()) * (10 ** priceFeedDecimals));
        return usdValue;
    }

    function setPriceFeed(address _token, address _priceFeed) public onlyOwner {    
        require(_priceFeed != address(0), "_priceFeed not allowed");
        require(priceFeedAggregator[_token] != _priceFeed, "_token _priceFeed existed");
        priceFeedAggregator[_token] = _priceFeed;
        emit PriceFeedUpdated(_token,_priceFeed);
    }

    function setPriceFeeds(PriceFeedAggregator[] calldata _priceFeedAggregator) public onlyOwner {    
        for (uint i=0; i < _priceFeedAggregator.length; i++) { 
            priceFeedAggregator[_priceFeedAggregator[i].token] = _priceFeedAggregator[i].priceFeed;
        }
    }

    function setTokenMap(address _nativeToken, address _wrappedToken) public onlyOwner {    
        require(_wrappedToken != address(0), "_wrappedToken not allowed");
        require(tokenMap[_nativeToken] != _wrappedToken, "_nativeToken _wrappedToken existed");
        tokenMap[_nativeToken] = _wrappedToken;
        emit TokenMap(_nativeToken,_wrappedToken);
    }


    fallback() external {
        revert("Unauthorized access");
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "Context.sol";

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function _transferOwnership(address newOwner) internal virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

abstract contract TransferOwnable is Ownable {
    function transferOwnership(address newOwner) public virtual onlyOwner {
        _transferOwnership(newOwner);
    }
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