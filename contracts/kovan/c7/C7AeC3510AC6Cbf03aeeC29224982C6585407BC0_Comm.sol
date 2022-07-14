// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

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

interface IRefferal {
    function userInfos(address _user) external view returns(address user,
        address refferBy,
        uint dateTime,
        uint totalRefer,
        uint totalRefer7,
        bool top10Refer);
}
    struct Spin {
        uint pid;
        uint number;
        uint amountToken;
        bool result;
        uint resultNumber;
        uint timestamp;
    }
interface IMGCLottery {

    function getUserSpins(address _user, uint _limit, uint _skip) external view returns(Spin[] memory list, uint totalitem);
}
contract Comm is Ownable {
    IRefferal public refer;
    IMGCLottery public lottery;
    IMGCLottery public lotteryDaily;
    IERC20 public MGC;


    constructor(IRefferal _refer, IMGCLottery _lottery, IMGCLottery _lotteryDaily, IERC20 _MGC) {
        refer = _refer;
        lottery = _lottery;
        lotteryDaily = _lotteryDaily;
        MGC = _MGC;
    }
    function getRefer(address _user) external view returns (address user,
        address refferBy,
        uint dateTime,
        uint totalRefer,
        uint totalRefer7,
        bool top10Refer) {
        return refer.userInfos(_user);
    }
    function getUserSpins(address _from) external view returns(Spin[] memory _list) {
        (_list,) = lottery.getUserSpins(_from, 1, 0);
    }
    function getUserSpinsDaily(address _from) external view returns(Spin[] memory _list) {
        (_list,) = lotteryDaily.getUserSpins(_from, 1, 0);
    }
    function handleComm(address _fromUser, uint _amount) external {
        address from = _fromUser;
        require(MGC.transferFrom(_msgSender(), address(this), _amount));
        uint skipAmount;
        for(uint i = 0; i < 7; i++) {
            address _user;
            address _refferBy;
            (_user, _refferBy,,,,) = refer.userInfos(from);
            from = _refferBy;
            if(_user == _refferBy) {
                MGC.transfer(_refferBy, _amount * (7-i) / 7 + skipAmount);
                break;
            } else {
                Spin[] memory _list;
                (_list,) = lottery.getUserSpins(from, 1, 0);
                if(_list.length > 0 && block.timestamp - _list[0].timestamp < 30 days) MGC.transfer(_refferBy, _amount / 7);
                else skipAmount += _amount / 7;
            }

        }
    }
    function handleCommDaily(address _fromUser, uint _amount) external {
        address from = _fromUser;
        require(MGC.transferFrom(_msgSender(), address(this), _amount));
        uint skipAmount;
        for(uint i = 0; i < 7; i++) {
            address _user;
            address _refferBy;
            (_user, _refferBy,,,,) = refer.userInfos(from);
            from = _refferBy;
            if(_user == _refferBy) {
                MGC.transfer(_refferBy, _amount * (7-i) / 7 + skipAmount);
                break;
            } else {
                Spin[] memory _list;
                (_list,) = lotteryDaily.getUserSpins(from, 1, 0);
                if(_list.length > 0 && block.timestamp - _list[0].timestamp < 30 days) MGC.transfer(_refferBy, _amount / 7);
                else skipAmount += _amount / 7;
            }

        }
    }
    function setLottery(IMGCLottery _lottery) external onlyOwner {
        lottery = _lottery;
    }
    function setLotteryDaily(IMGCLottery _lotteryDaily) external onlyOwner {
        lotteryDaily = _lotteryDaily;
    }
    function setRefer(IRefferal _refer) external onlyOwner {
        refer = _refer;
    }
    function inCaseTokensGetStuck(IERC20 _token) external onlyOwner {

        uint amount = _token.balanceOf(address(this));
        _token.transfer(msg.sender, amount);
    }
}