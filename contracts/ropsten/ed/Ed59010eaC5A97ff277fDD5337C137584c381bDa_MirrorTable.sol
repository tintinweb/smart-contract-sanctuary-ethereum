// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/access/Ownable.sol";

contract MirrorTable is Ownable {
    enum RoundType {
        ORDINARY,
        SEED,
        SERIES_A,
        SERIES_B,
        CONVERTIBLE_NOTE_A,
        WARRANT_B
    }

    struct Investment {
        address shareHolder;
        RoundType round;
        uint256 investmentEpoch;
        uint256 numberOfShares;
        uint256 pricePerShareUSD;
    }

    struct Portfolio {
        string name;
        uint256 equityAwardsAllocated;
        uint256 equityAwardsUnallocated;
        // mapping(RoundType => uint256) conversionRatio;
        // mapping(RoundType => uint256) liquidationPreference;
        // mapping(RoundType => uint256) liquidationMultiplier;
        // mapping(RoundType => bool) participating;
    }

    struct Shareholder {
        string name;
    }

    mapping(address => Investment[]) public investments;
    mapping(address => Portfolio) public portfolios;
    mapping(address => Shareholder) public shareholders;

    function decimals() public pure returns (uint256) {
        return 8;
    }

    function registerPortfolio(
        address _address,
        string memory _name,
        uint256 _equityAwardsAllocated,
        uint256 _equityAwardsUnallocated
    ) external onlyOwner {
        Portfolio storage portfolio = portfolios[_address];
        portfolio.name = _name;
        portfolio.equityAwardsAllocated = _equityAwardsAllocated;
        portfolio.equityAwardsUnallocated = _equityAwardsUnallocated;

        // TODO: input for conversionRatio, liquidationPreference, liquidationMultiplier, participating
    }

    function registerShareholder(address _address, string memory _name)
        external
        onlyOwner
    {
        Shareholder storage shareholder = shareholders[_address];
        shareholder.name = _name;
    }

    function registerInvestment(
        address _portfolio,
        address _shareholder,
        RoundType _round,
        uint256 _investmentEpoch,
        uint256 _numberOfShares,
        uint256 _pricePerShareUSD
    ) external onlyOwner {
        Investment memory investment = Investment(
            _shareholder,
            _round,
            _investmentEpoch,
            _numberOfShares,
            _pricePerShareUSD
        );
        investments[_portfolio].push(investment);
    }

    function getInvestments(address _portfolio)
        public
        view
        returns (Investment[] memory)
    {
        return investments[_portfolio];
    }

    function getPortfolio(address _portfolio)
        public
        view
        returns (Portfolio memory)
    {
        return portfolios[_portfolio];
    }

    function getShareHolder(address _shareholder)
        public
        view
        returns (Shareholder memory)
    {
        return shareholders[_shareholder];
    }
}