pragma solidity 0.8.19;

import "../interface/INFT.sol";
import "../interface/ISTBL.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Preseed is Ownable {
    struct DepositInfo {
        uint256 minimalValue;
        uint256 lockPeriod;
        uint256 apr;
    }

    struct UserInfo {
        INFT.Rarity rarity;
        uint256 value;
        uint256 claimDate;
        bool claimed;
    }

    mapping(INFT.Rarity => DepositInfo) public availableDeposits;
    mapping(address => UserInfo[]) public userInfos;

    ISTBL public stbl;
    INFT public nft_slag;

    uint256 public startDate;
    uint256 public endDate;
    bool public startCheck;

    uint256 constant public HUNDRED_PERCENT = 10 ** 30;

    modifier onlyWhenActive() {
        require(block.timestamp >= startDate && block.timestamp <= endDate, "not active");
        _;
    }

    constructor(address _stbl, address _nft_slag, DepositInfo[] memory _depositInfo) {
        require(_stbl != address(0), "invalid stbl address");
        require(_nft_slag != address(0), "invalid nft_slag address");
        require(_depositInfo.length == 4, "deposit info doesn't match with numbers of rarity");

        stbl = ISTBL(_stbl);
        nft_slag = INFT(_nft_slag);
        
        availableDeposits[INFT.Rarity.Common] = _depositInfo[0];
        availableDeposits[INFT.Rarity.Rare] = _depositInfo[1];
        availableDeposits[INFT.Rarity.Legendary] = _depositInfo[2];
        availableDeposits[INFT.Rarity.Epic] = _depositInfo[3];
    }

    function start() public onlyOwner {
        require(!startCheck, "already was started");
        startDate = block.timestamp;
        endDate = block.timestamp + 30 days;
        startCheck = true;
    }

    function deposit(uint256 _value, INFT.Rarity _rarity) public onlyWhenActive {
        DepositInfo memory _depositInfo = availableDeposits[_rarity];
        require(_value >= _depositInfo.minimalValue, "value too small");

        stbl.transferFrom(msg.sender, address(this), _value);
        stbl.burn(_value);
        userInfos[msg.sender].push(UserInfo(_rarity, _value, block.timestamp + _depositInfo.lockPeriod, false));
    }

    function claim(uint256 _index) public {
        UserInfo memory _userInfo = userInfos[msg.sender][_index];
        require(!_userInfo.claimed, "already claimed");
        require(block.timestamp >= _userInfo.claimDate, "not available for claim");

        nft_slag.claim(msg.sender, _userInfo.rarity, _userInfo.value);
        uint256 reward = _userInfo.value * availableDeposits[_userInfo.rarity].apr / HUNDRED_PERCENT;
        stbl.mint(msg.sender, reward + _userInfo.value);

        userInfos[msg.sender][_index] = UserInfo(_userInfo.rarity, _userInfo.value, _userInfo.claimDate, true);
    }

    function getUserInfoLength(address _user) public view returns(uint256) {
        return userInfos[_user].length;
    }

    function getUserInfoIndexed(address _user, uint256 _from, uint256 _to) public view returns(UserInfo[] memory) {
        UserInfo[] memory _info = new UserInfo[](_to - _from);

        for(uint256 _index = 0; _from < _to; ++_index) {
            _info[_index] = userInfos[_user][_from];
            _from++;
        }

        return _info;
    }
}

pragma solidity 0.8.19;

interface ISTBL {
    function mint(address _receiver, uint256 _value) external;
    function burn(uint256 _value) external;
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

pragma solidity 0.8.19;

interface INFT {
    enum Rarity { Common, Rare, Legendary, Epic }
    function claim(address _receiver, Rarity _rarity, uint256 _value) external;
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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