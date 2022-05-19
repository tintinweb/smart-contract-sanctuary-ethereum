// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Redeem is Ownable {

    struct RedeemInfo {
        string name;
        string email;
        string add;
        string country;
        string provinces;
        string phone;
        string itemsRedeemed;
        string comments;
        uint256 redeemTime;
    }
    mapping(address => RedeemInfo) public redeemInfo;

    address public prtAddress;

    event Redeem100(    string _name, string _email, string _add, string _country, 
                        string _provinces, string _phone, string _itemsRedeemed, 
                        string _comments);
    event Redeem200(    string _name, string _email, string _add, string _country, 
                        string _provinces, string _phone, string _itemsRedeemed, 
                        string _comments);
    event Redeem400(    string _name, string _email, string _add, string _country, 
                        string _provinces, string _phone, string _itemsRedeemed, 
                        string _comments);
    event Redeem500(    string _name, string _email, string _add, string _country, 
                        string _provinces, string _phone, string _itemsRedeemed, 
                        string _comments);

    constructor(address _prtAddress)  {
        prtAddress = _prtAddress;
    }

    function changePrtAddress(address _prtAddress) public {
        prtAddress = _prtAddress;
    }

    function checkRedeemForUser(address _add) public view returns(RedeemInfo memory) {
        return redeemInfo[_add];
    }

    function redeem100( string memory _name, string memory _email, string memory _add, string memory _country, 
                        string memory _provinces, string memory _phone, string memory _itemsRedeemed, 
                        string memory _comments) public {
        require(msg.sender != address(0), "Zero Address");
        IERC20(prtAddress).transferFrom(msg.sender, address(this), 100 * 10 ** 18);
        redeemInfo[msg.sender].redeemTime = block.timestamp;
        redeemInfo[msg.sender].name = _name;
        redeemInfo[msg.sender].email = _email;
        redeemInfo[msg.sender].add = _add;
        redeemInfo[msg.sender].country = _country;
        redeemInfo[msg.sender].provinces = _provinces;
        redeemInfo[msg.sender].phone = _phone;
        redeemInfo[msg.sender].itemsRedeemed = _itemsRedeemed;
        redeemInfo[msg.sender].comments = _comments;

        emit Redeem100( _name, _email, _add, _country, 
                        _provinces, _phone, _itemsRedeemed, _comments);
    }

    function redeem200( string memory _name, string memory _email, string memory _add, string memory _country, 
                        string memory _provinces, string memory _phone, string memory _itemsRedeemed, 
                        string memory _comments) public {
        require(msg.sender != address(0), "Zero Address");
        IERC20(prtAddress).transferFrom(msg.sender, address(this), 200 * 10 ** 18);
        redeemInfo[msg.sender].redeemTime = block.timestamp;
        redeemInfo[msg.sender].name = _name;
        redeemInfo[msg.sender].email = _email;
        redeemInfo[msg.sender].add = _add;
        redeemInfo[msg.sender].country = _country;
        redeemInfo[msg.sender].provinces = _provinces;
        redeemInfo[msg.sender].phone = _phone;
        redeemInfo[msg.sender].itemsRedeemed = _itemsRedeemed;
        redeemInfo[msg.sender].comments = _comments;

        emit Redeem100( _name, _email, _add, _country, 
                        _provinces, _phone, _itemsRedeemed, _comments);
    }

    function redeem400( string memory _name, string memory _email, string memory _add, string memory _country, 
                        string memory _provinces, string memory _phone, string memory _itemsRedeemed, 
                        string memory _comments) public {
        require(msg.sender != address(0), "Zero Address");
        IERC20(prtAddress).transferFrom(msg.sender, address(this), 400 * 10 ** 18);
        redeemInfo[msg.sender].redeemTime = block.timestamp;
        redeemInfo[msg.sender].name = _name;
        redeemInfo[msg.sender].email = _email;
        redeemInfo[msg.sender].add = _add;
        redeemInfo[msg.sender].country = _country;
        redeemInfo[msg.sender].provinces = _provinces;
        redeemInfo[msg.sender].phone = _phone;
        redeemInfo[msg.sender].itemsRedeemed = _itemsRedeemed;
        redeemInfo[msg.sender].comments = _comments;

        emit Redeem100( _name, _email, _add, _country, 
                        _provinces, _phone, _itemsRedeemed, _comments);
    }

    function redeem500( string memory _name, string memory _email, string memory _add, string memory _country, 
                        string memory _provinces, string memory _phone, string memory _itemsRedeemed, 
                        string memory _comments) public {
        require(msg.sender != address(0), "Zero Address");
        IERC20(prtAddress).transferFrom(msg.sender, address(this), 500 * 10 ** 18);
        redeemInfo[msg.sender].redeemTime = block.timestamp;
        redeemInfo[msg.sender].name = _name;
        redeemInfo[msg.sender].email = _email;
        redeemInfo[msg.sender].add = _add;
        redeemInfo[msg.sender].country = _country;
        redeemInfo[msg.sender].provinces = _provinces;
        redeemInfo[msg.sender].phone = _phone;
        redeemInfo[msg.sender].itemsRedeemed = _itemsRedeemed;
        redeemInfo[msg.sender].comments = _comments;

        emit Redeem100( _name, _email, _add, _country, 
                        _provinces, _phone, _itemsRedeemed, _comments);
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