// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/ISTOCKSDATA.sol";
import "../interfaces/IDIVIDENDSSTOCKS.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DividendsStocks is IDIVIDENDSSTOCKS, Pausable, Ownable {
    //////////////////////////////////////////////////////////////////////////////////////////////////
    // State
    ////////////////////////////////////////////////////////////////////////////////////////////////// 

    // Stocks Contract
    ISTOCKSDATA private STOCKSDATA_CONTRACT;

    // Dividends
    address public s_contractNFTs;
    mapping(address => uint256) private s_claimedDividends;
    mapping(address => uint256) private s_claimedRealDividends;
    uint256 private s_amountStock;

    //////////////////////////////////////////////////////////////////////////////////////////////////
    // Constructor
    ////////////////////////////////////////////////////////////////////////////////////////////////// 

    constructor(address p_stocksData) {
        STOCKSDATA_CONTRACT = ISTOCKSDATA(p_stocksData);
    }

    //////////////////////////////////////////////////////////////////////////////////////////////////
    // Modifiers
    //////////////////////////////////////////////////////////////////////////////////////////////////

    modifier onlyContract {
        if (msg.sender != s_contractNFTs || s_contractNFTs == address(0)) {
            revert();
        }

        _;
    }

    //////////////////////////////////////////////////////////////////////////////////////////////////
    // Public functions
    //////////////////////////////////////////////////////////////////////////////////////////////////

    // => View functions

    function amountStock() public view override returns(uint256) { 
        return s_amountStock;
    }

    function infoClaimDividends(address p_to) public view override returns(uint256) {
        return _infoClaimDividends(p_to);
    }

    function claimedDividends(address p_to) public view override returns(uint256) { 
        return s_claimedDividends[p_to]; 
    } 

    function infoClaimedDividends(address p_to) public view override returns(uint256) {
        return s_claimedRealDividends[p_to];
    }

    // => Set functions

    function setAddressNFTs(address p_addressNFTs) public onlyOwner override {
        s_contractNFTs = p_addressNFTs;
    }

    function setStocksData(address p_stocksData) public onlyOwner override { 
        STOCKSDATA_CONTRACT = ISTOCKSDATA(p_stocksData); 
    }

    function setPause(bool p_pause) public onlyOwner override {
        if (p_pause) {
            _pause();
        } else {
            _unpause();
        }
    } 

    function addDividends(uint256 p_amount) public payable onlyOwner override {
        require(msg.value == p_amount, "Values do not match");
        require(p_amount >= STOCKSDATA_CONTRACT.totalSupplyStocks(), "Error values");

        uint256 increment = p_amount / STOCKSDATA_CONTRACT.totalSupplyStocks();
        s_amountStock += increment;
        uint256 toReturn = p_amount - (increment * STOCKSDATA_CONTRACT.totalSupplyStocks());
        payable(msg.sender).transfer(toReturn);

        emit AddDividends(
            increment * STOCKSDATA_CONTRACT.totalSupplyStocks(), 
            increment
        ); 
    }

    function claimDividends() public whenNotPaused override {
        _claimDividends(msg.sender); 
    }

    function claimDividendsTo(address p_to) public override onlyContract  { 
        _claimDividends(p_to); 
    }

    function subClaimedDividends(address p_to, uint256 p_amount) public onlyContract override { 
        require(s_claimedDividends[p_to] >= p_amount, "Error amount");

        s_claimedDividends[p_to] -= p_amount;
    }

    function addClaimedDividends(address p_to, uint256 p_amount) public onlyContract override { 
        s_claimedDividends[p_to] += p_amount;
    }

    function deleteClaimedDividends(address p_to) public onlyContract override { 
        delete s_claimedDividends[p_to];
    } 

    //////////////////////////////////////////////////////////////////////////////////////////////////
    // Internal functions
    //////////////////////////////////////////////////////////////////////////////////////////////////

    function _claimDividends(address p_to) internal {
        uint256 claimAmount = _infoClaimDividends(p_to);
        require(claimAmount > 0, "No dividends");

        s_claimedDividends[p_to] += claimAmount;
        s_claimedRealDividends[p_to] += claimAmount;
        
        payable(p_to).transfer(claimAmount);

        emit ClaimDividends(p_to, claimAmount);
    }

    function _infoClaimDividends(address p_to) internal view returns(uint256) {
        if (s_amountStock == 0 || STOCKSDATA_CONTRACT.numberStocks(p_to) == 0) { 
            return 0;
        }

        uint256 claimTotal = STOCKSDATA_CONTRACT.numberStocks(p_to) * s_amountStock;

        uint256 claimAmount;
        if (claimTotal > s_claimedDividends[p_to]) {
            claimAmount = claimTotal - s_claimedDividends[p_to];
        }

        return claimAmount;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISTOCKSDATA {
    // STRUCT METADATA NFT

    struct Metadata {
        uint256 min;
        uint256 max;
    }
    
    // PUBLIC FUNCTIONS

        // View functions

        function totalSupplyStocks() external view returns(uint256);
        function numberStocks(address p_address) external view returns(uint256);
        function metadata(uint256 p_tokenId) external view returns(uint256, uint256);

        // Set functions

        function setPause(bool p_pause) external;
        function setAddressNFTs(address p_addressNFTs) external;
        function mint(uint256 p_total, uint256 p_tokenId) external;
        function mintWithPartition( uint256 p_tokenId, uint256 p_min, uint256 p_max) external;
        function reduceMax(uint256 p_tokenId, uint256 p_max) external;
        function addNumberStocks(address p_address, uint256 p_amount) external;
        function subNumberStocks(address p_address, uint256 p_amount) external;
        function addTotalSupplyStocks(uint256 p_amount) external;
        function subTotalSupplyStocks(uint256 p_amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDIVIDENDSSTOCKS {
    // EVENTS
    event AddDividends(uint256 e_amount, uint256 e_amountStock);
    event ClaimDividends(address indexed e_to, uint256 e_amount);
    
    // PUBLIC FUNCTIONS

        // View functions 

        function amountStock() external view returns(uint256);
        function infoClaimDividends(address p_to) external view returns(uint256);
        function claimedDividends(address p_to) external view returns(uint256);
        function infoClaimedDividends(address p_to) external view returns(uint256);

        // Set functions

        function setAddressNFTs(address p_addressNFTs) external;
        function setStocksData(address p_stocksData) external;
        function setPause(bool p_pause) external;
        function addDividends(uint256 p_amount) external payable;
        function claimDividends() external;
        function claimDividendsTo(address p_to) external;
        function subClaimedDividends(address p_to, uint256 p_amount) external;
        function addClaimedDividends(address p_to, uint256 p_amount) external;
        function deleteClaimedDividends(address p_to) external;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

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