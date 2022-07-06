/**
 *Submitted for verification at Etherscan.io on 2022-07-06
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: contracts/IDO/IDOSale.sol

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;



interface IDOToken is IERC20 {
    function mint(address dest, uint256 amount) external returns (bool);
}

contract IDOPool is Ownable {
    IERC20 public usdc = IERC20(0x5e31357F45DC69Ba971c4706dfC99798bb6E298b);
    IDOToken public idoToken;

    uint256 public rate;
    uint256 public hardCap; // 6M
    uint256 public softCap; // 2.5M
    uint256 public minPerWallet;
    uint256 public maxPerWallet;

    mapping(address => bool) public whitelisted;
    mapping(address => uint256) public purchased;

    uint256 public startTime;
    uint256 public endTime;

    address public admin;
    uint256 totalPurchased;

    constructor(
        uint256 _startTime,
        uint256 _endTime,
        address _idoToken,
        uint256 _rate,
        uint256 _softCap,
        uint256 _hardCap,
        uint256 _maxPerWallet,
        uint256 _minPerWallet,
        address _admin
    ) {
        require(
            _endTime > _startTime && _endTime > block.timestamp,
            "Wrong endtime"
        );
        require(_rate > 0, "Rate is 0");
        require(_idoToken != address(0), "Token is the zero address");
        require(_softCap < _hardCap, "Softcap must be lower than Hardcap");
        require(_minPerWallet < _maxPerWallet, "Incorrect limits per wallet");
        startTime = _startTime;
        endTime = _endTime;
        idoToken = IDOToken(_idoToken);
        rate = _rate;
        softCap = _softCap;
        hardCap = _hardCap;
        admin = _admin;
        maxPerWallet = _maxPerWallet;
        minPerWallet = _minPerWallet;
        _transferOwnership(_admin);
    }

    function addWhitelists(address[] memory _whitelist) external onlyOwner {
        for (uint256 i = 0; i < _whitelist.length; i++) {
            whitelisted[_whitelist[i]] = true;
        }
    }

    function removeWhitelists(address[] memory _whitelist) external onlyOwner {
        for (uint256 i = 0; i < _whitelist.length; i++) {
            whitelisted[_whitelist[i]] = false;
        }
    }

    function _balanceOf() public view returns (uint256) {
        return usdc.balanceOf(address(this));
    }

    function purchase(uint256 _amount) external idoActive {
        require(whitelisted[msg.sender] == true, "not whitelisted");
        require(_amount != 0, "Presale: weiAmount is 0");
        if (purchased[msg.sender] == 0) {
            require(_amount >= minPerWallet, "Smaller than minimum amount");
        }
        require(
            purchased[msg.sender] + _amount <= maxPerWallet,
            "Exceeds max per wallet"
        );
        require(totalPurchased + _amount <= hardCap, "Exceeds Hard Cap");
        require(
            usdc.balanceOf(msg.sender) >= _amount / rate,
            "Insufficinet Fund"
        );
        usdc.transferFrom(msg.sender, address(this), _amount / rate);
        idoToken.mint(msg.sender, _amount);
        purchased[msg.sender] += _amount;
        totalPurchased += _amount;
    }

    function withdraw() external onlyOwner idoNotActive {
        require(_balanceOf() > 0, "No usdc to withdraw");
        usdc.transfer(msg.sender, _balanceOf());
    }

    function setRate(uint256 newRate) external onlyOwner {
        rate = newRate;
    }

    function setHardCap(uint256 value) external onlyOwner {
        hardCap = value;
    }

    function setSoftCap(uint256 value) external onlyOwner {
        softCap = value;
    }

    function setStartTime(uint256 value) external onlyOwner {
        startTime = value;
    }

    function setEndime(uint256 value) external onlyOwner {
        endTime = value;
    }

    function setMaxPerWallet(uint256 value) external onlyOwner {
        maxPerWallet = value;
    }

    function setMinPerWallet(uint256 value) external onlyOwner {
        minPerWallet = value;
    }

    modifier idoActive() {
        require(
            block.timestamp >= startTime && block.timestamp <= endTime,
            "Presale must be active"
        );
        _;
    }

    modifier idoNotActive() {
        require(block.timestamp >= endTime, "Presale should not be active");
        _;
    }
}