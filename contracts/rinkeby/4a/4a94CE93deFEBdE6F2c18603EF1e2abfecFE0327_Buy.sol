// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IUTILITYTOKENERC20.sol"; 
import "../interfaces/IBUY.sol"; 

contract Buy is IBUY, Ownable { 

    //////////////////////////////////////////////////////////////////////////////////////////////////
    // State
    //////////////////////////////////////////////////////////////////////////////////////////////////

    address public s_utilityTokenAddress;
    address public s_cardsNFTsAddress;

    mapping(address => bool) private s_sellers;
    mapping(string => address) private s_receipts;
    mapping(address => uint256) private s_points;

    //////////////////////////////////////////////////////////////////////////////////////////////////
    // Constructor
    //////////////////////////////////////////////////////////////////////////////////////////////////

    constructor(address p_utilityTokenAddress) {
        s_utilityTokenAddress = p_utilityTokenAddress;
    }

    //////////////////////////////////////////////////////////////////////////////////////////////////
    // Public functions
    ////////////////////////////////////////////////////////////////////////////////////////////////// 

    // => View functions

    function points(address p_address) public view override returns(uint256) { 
        return s_points[p_address]; 
    }

    function receipt(string memory p_receipt) public view override returns(address) { 
        return s_receipts[p_receipt]; 
    }

    function seller(address p_seller) public view override returns(bool) { 
        return s_sellers[p_seller]; 
    }

    // => Set functions

    function setAddressCardsNFTs(address p_cardsNFTsAddress) public onlyOwner override {  
        s_cardsNFTsAddress = p_cardsNFTsAddress;
    }

    function setAddressUtilityToken(address p_utilityTokenAddress) public onlyOwner override {  
        s_utilityTokenAddress = p_utilityTokenAddress;
    }

    function setSeller(address p_seller, bool p_active) public onlyOwner override {
        if (p_active) {
            s_sellers[p_seller] = true;
        } else {
            delete s_sellers[p_seller];
        }
    }

    function payBusiness(
        address p_contract, 
        address p_seller, 
        string memory p_receipt, 
        uint256 p_amount, 
        address p_from, 
        bytes memory sig
    ) public override {
        require(p_contract == address(this), "Different contract");
        require(s_sellers[p_seller], "Error seller");
        require(p_from == msg.sender, "Error origin");
        require(s_receipts[p_receipt] == address(0), "Error receipt");
        require(IUTILITYTOKENERC20(s_utilityTokenAddress).freeBalanceOf(p_from) >= p_amount, "Insufficient balance");
        require(p_amount >= 2, "Error amount (min: 2)");

        bytes32 message = keccak256(abi.encodePacked(p_contract, p_seller, p_receipt, p_amount, p_from));
        require(_recoverSigner(message, sig) == p_seller, "Error signature");

        s_points[msg.sender] += 1;

        s_receipts[p_receipt] = p_seller;

        uint256 _num99;
        if (p_amount >= 100) { _num99 = (p_amount / 100) * 99; }
        if (p_amount < 100) { _num99 = p_amount - 1; }
        IERC20(s_utilityTokenAddress).transferFrom(p_from, owner(), _num99);
        IUTILITYTOKENERC20(s_utilityTokenAddress).burn(p_from, p_amount - _num99);

        emit Sale(msg.sender, p_amount, p_seller, p_receipt); 
    }

    function deletePoints(address p_address) public override {  
        require(msg.sender == s_cardsNFTsAddress, "Error origin");

        delete s_points[p_address];
    }

    //////////////////////////////////////////////////////////////////////////////////////////////////
    // Internal functions
    //////////////////////////////////////////////////////////////////////////////////////////////////

    function _recoverSigner(bytes32 message, bytes memory sig) internal pure returns (address) {
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = _splitSignature(sig);

        return ecrecover(message, v, r, s);
    }

    function _splitSignature(bytes memory sig) internal pure returns (uint8, bytes32, bytes32) {
        require(sig.length == 65);

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    
        return (v, r, s);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUTILITYTOKENERC20 {
    // EVENTS

    event FreeMint(address indexed e_owner, uint256 e_amount);
    
    // PUBLIC FUNCTIONS

        // View functions

        function costMint(uint128 p_amount) external view returns(uint256);
        function ethToTokens(uint256 p_amount) external view returns(uint256);
        function maxMint() external view returns(uint256);
        function freeBalanceOf(address p_from) external view returns(uint256);
        function monthlyUnlock(address p_owner) external view returns(uint256);
        function poolUniswapV3() external view returns(address);

        // Set functions

        function setAddressStocksNFTs(address p_addressStocksNFTs) external;
        function setAddressCardsNFTs(address p_addressCardsNFTs) external;
        function setAddressBuy(address p_buyAddress) external;
        function setPause(bool p_pause) external;
        function freeMint(address p_owner, uint256 p_amount) external;
        function mint() external payable;
        function burn(address p_address, uint256 p_amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBUY {
    // EVENTS

    event Sale(address e_client, uint256 e_amount, address indexed e_seller, string indexed e_receipt);
    
    // PUBLIC FUNCTIONS

        // View functions

        function points(address p_address) external view returns(uint256);
        function receipt(string memory p_receipt) external view returns(address);
        function seller(address p_seller) external view returns(bool);

        // Set functions

        function setAddressCardsNFTs(address p_addressCardsNFTs) external;
        function setAddressUtilityToken(address p_utilityTokenAddress) external;
        function setSeller(address p_seller, bool p_active) external;
        function payBusiness(address p_contract, address p_seller, string memory p_receipt, uint256 p_amount, address p_from, bytes memory sig) external;
        function deletePoints(address p_address) external;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address sender,
        address recipient,
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