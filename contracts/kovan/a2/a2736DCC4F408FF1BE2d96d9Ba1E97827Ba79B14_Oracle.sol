/**
 *Submitted for verification at Etherscan.io on 2022-06-16
*/

pragma solidity 0.8.12;
pragma abicoder v2;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
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
}

interface IOracle {
    /// A structure returned whenever someone requests for a price data.
    struct PriceData {
        uint256 price; // base/quote exchange rate, multiplied by 1e18.
        uint256 lastUpdatedBase; // UNIX epoch of the last time when base price gets updated.
        uint256 lastUpdatedQuote; // UNIX epoch of the last time when quote price gets updated.
    }

    /// Returns the price data for the given base/quote pair. Revert if not available.
    function getPriceData(string memory baseSymbol, string memory quoteSymbol)
        external
        view
        returns (PriceData memory);

    /// Similar to getPriceData, but with multiple base/quote pairs at once.
    function getPriceDataBulk(string[] memory baseSymbols, string[] memory quoteSymbols)
        external
        view
        returns (PriceData[] memory);
        
    /// Relay a price data to the contract.
    /// Can only be call by the owner of this contract.
    function relaySingle(string calldata symbol, uint256 price) external;
    
    /// Relay prices data to the contract.
    /// Can only be call by the owner of this contract.
    function relayMultiple(string[] memory symbols, uint256[] memory prices) external;
}

contract Oracle is IOracle, Ownable {

    mapping(string => uint256) public pricesMapping;
    mapping(string => uint256) public timesMapping;

    function getRawPriceAndTime(string memory symbol) public view returns(uint256, uint256) {
        uint256 price = 1e9;
        uint256 time = block.timestamp;
        if (keccak256(abi.encodePacked(symbol)) != keccak256(abi.encodePacked("USD"))) {
            price = pricesMapping[symbol];
            time = timesMapping[symbol];
            require(time > 0, "SYMBOL_NOT_FOUND");
        }
        return (price, time);
    }

    function getPriceData(string memory baseSymbol, string memory quoteSymbol) public view returns (PriceData memory) {
        (uint256 basePrice, uint256 baseTime) = getRawPriceAndTime(baseSymbol);
        (uint256 quotePrice, uint256 quoteTime) = getRawPriceAndTime(quoteSymbol);
        return PriceData({
            price: (basePrice * 1e18) / quotePrice,
            lastUpdatedBase: baseTime,
            lastUpdatedQuote: quoteTime
        });
    }

    function getPriceDataBulk(string[] calldata baseSymbols, string[] calldata quoteSymbols) external view returns (PriceData[] memory) {
        require(baseSymbols.length == quoteSymbols.length, "BAD_INPUT_LENGTH");
        uint256 len = baseSymbols.length;
        PriceData[] memory results = new PriceData[](len);
        for (uint256 i = 0; i < len; i++) {
            results[i] = getPriceData(baseSymbols[i], quoteSymbols[i]);
        }
        return results;
    }

    function relaySingle(string memory symbol, uint256 price) public onlyOwner {
        pricesMapping[symbol] = price;
        timesMapping[symbol] = block.timestamp;
    }

    function relayMultiple(string[] memory symbols, uint256[] memory prices) public onlyOwner {
        require(symbols.length == prices.length, "BAD_INPUT_LENGTH");
        uint256 len = symbols.length;
        for (uint256 i = 0; i < len; i++) {
            relaySingle(symbols[i], prices[i]);
        }
    }
}