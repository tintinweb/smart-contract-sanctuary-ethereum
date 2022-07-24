/**
 *Submitted for verification at Etherscan.io on 2022-07-22
*/

// SPDX-License-Identifier: GPL-3.0-or-later
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


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// File: contracts/AllowanceContract.sol



pragma solidity 0.8.15;


contract WalletChallenge is Ownable {
    uint internal _totalBalance;
    uint internal _redeemedMoneyEventIndex;

    struct User {
        uint myBalance;
        uint allMyAllowanceBalances;
        mapping (address => uint) balances;
        mapping (address => Allowances) allowances;
    }
    struct Allowances {
        uint index;
        uint timestamp;
        uint duration;
        uint value;
    }

    mapping (address => User) internal _user;

    /////////////////////Events
    event AllowanceSucceed(
        uint indexed _index,
        uint indexed _timestamp,
        uint _duration,
        uint _value,
        address _from,
        address indexed _to
    );
    event AllowanceRevoked(
        uint indexed _index,
        uint indexed _timestamp,
        address _from,
        address indexed _to,
        uint _redeemedValue
    );
    event MoneyRedeemed(
        uint indexed _index,
        uint indexed _timestamp,
        address _from,
        address indexed _to,
        uint _redeemedValue
    );
    //////////////////////////

    /////////////////////Modifiers
    modifier IsThereAnAllowance(address _from, address _to){
        require(_user[_to].allowances[_from].index > 0, "There is no allowance from this wallet.");
        _;
    }
    modifier AllowanceFunction (address _to) {
        _;

        _user[_to].allowances[msg.sender].index ++;

        emit AllowanceSucceed(
            _user[_to].allowances[msg.sender].index,
            _user[_to].allowances[msg.sender].timestamp,
            _user[_to].allowances[msg.sender].duration,
            _user[_to].allowances[msg.sender].value,
            msg.sender,
            _to
        );
    }
    modifier verifyRemainingTime (address _allowned, address _allowner) {
        require(verifiesRemainingTime(_allowned, _allowner), "Your allowed time has ended.");
        _;
    }
    modifier NotYourself (address _to){
        require(_to != msg.sender, "You can't do this with your own wallet.");
        _;
    }
    //////////////////////////////

    /////////////////////View Functions
    function getTotalBalance() public view returns(uint totalBalance){
        return _totalBalance;
    }
    function getMyBalance() public view returns(uint myBalance) {
        return _user[msg.sender].myBalance;
    }
    function getAllMyAllowanceBalances() public view returns(uint allMyAllowanceBalances){
        return _user[msg.sender].allMyAllowanceBalances;
    }
    function getMyReservedBalanceFrom(address _allowner) public view IsThereAnAllowance(_allowner, msg.sender) returns(uint getMyAllowanceBalance){
        return _user[msg.sender].balances[_allowner];
    }
    function getMyAllowanceFrom(address _allowner) public view IsThereAnAllowance(_allowner, msg.sender) returns(uint index, uint timestamp, uint duration, uint remainingTime, uint blockTimestamp, uint value){
        return (
            _user[msg.sender].allowances[_allowner].index,
            _user[msg.sender].allowances[_allowner].timestamp,
            _user[msg.sender].allowances[_allowner].duration,
            getMyAllowanceRemainingTime(_allowner),
            block.timestamp,
            _user[msg.sender].allowances[_allowner].value
        );
    }
    ///////////////////////////////////

    /////////////////////Allowance Functions
    function giveAllowance(address _to, uint _duration, uint _amount) public NotYourself(_to) AllowanceFunction(_to) {
        require(_user[_to].balances[msg.sender] >= _amount, "Insufficient funds.");

        setAllowanceTime(_to, _duration);

        _user[_to].allMyAllowanceBalances -= _user[_to].allowances[msg.sender].value;
        _user[_to].allMyAllowanceBalances += (_user[_to].allowances[msg.sender].value = _amount);
    }

    function depositAndGiveAllowance(address _to, uint _duration) public payable NotYourself(_to) AllowanceFunction(_to){
        _totalBalance += msg.value;
        setAllowanceTime(_to, _duration);
        _user[_to].allMyAllowanceBalances += msg.value;
        _user[_to].balances[msg.sender] += (_user[_to].allowances[msg.sender].value = msg.value);
    }

    function transferAndGiveAllowance(address _to, uint _duration, uint _amount) public NotYourself(_to) AllowanceFunction(_to){
        decreaseMoneyFromMyBalance(msg.sender, _amount);
        setAllowanceTime(_to, _duration);
        _user[_to].allMyAllowanceBalances += _amount;
        _user[_to].balances[msg.sender] += (_user[_to].allowances[msg.sender].value = _amount);
    }
    
    function revokeAllowanceOf(address _wallet) public NotYourself(_wallet) IsThereAnAllowance(msg.sender, _wallet){
        uint _redeemedValue = _user[_wallet].allowances[msg.sender].value;
        redeemValueFromAllowance(_wallet, msg.sender, _redeemedValue);
        setAllowanceTime(_wallet, 0);

        _user[_wallet].allowances[msg.sender].index++;

        emit AllowanceRevoked(
            _user[_wallet].allowances[msg.sender].index,
            _user[_wallet].allowances[msg.sender].timestamp,
            msg.sender,
            _wallet,
            _redeemedValue
        );
    }
    
    function redeemFreeValueFromTheBalanceOf(address _wallet) public NotYourself(_wallet) {
        uint _redeemedValue = _user[_wallet].balances[msg.sender] - _user[_wallet].allowances[msg.sender].value;
        redeemValueFromBalance(_wallet, msg.sender, _redeemedValue);

        _redeemedMoneyEventIndex++;

        emit MoneyRedeemed(
            _redeemedMoneyEventIndex,
            block.timestamp,
            msg.sender,
            _wallet,
            _redeemedValue
        );
    }
    /////////////////////////////////////////

    /////////////////////Internal Functions
    function getMyAllowanceRemainingTime(address _allowner) internal view returns(uint remainingTime){
        if (verifiesRemainingTime(msg.sender, _allowner)) {
            return (_user[msg.sender].allowances[_allowner].timestamp + _user[msg.sender].allowances[_allowner].duration) - block.timestamp;
        } else {
            return 0;
        }
    }
    function setAllowanceTime(address _to, uint _duration) internal {
        _user[_to].allowances[msg.sender].timestamp = block.timestamp;
        _user[_to].allowances[msg.sender].duration = _duration;
    }
    function receiveMoney(address _to) internal {
        _totalBalance += msg.value;
        _user[_to].myBalance += msg.value;
    }
    function decreaseMoneyFromMyBalance(address _address, uint _amount) internal {
        require(_user[_address].myBalance >= _amount, "Insufficient funds.");

        _user[_address].myBalance -= _amount;
    }
    function redeemValueFromAllowance(address _from, address _to, uint _amount) internal {
        require(_user[_from].allowances[_to].value >= _amount, "Insufficient funds.");

        _user[_from].allowances[_to].value -= _amount;
        _user[_from].allMyAllowanceBalances -= _amount;
        _user[_from].balances[_to] -= _amount;
        _user[_to].myBalance += _amount;
    }
    function redeemValueFromBalance(address _from, address _to, uint _amount) internal {
        require(_user[_from].balances[_to] > _user[_from].allowances[_to].value, "There is no free balance to redeem. Check your Allowances for this user.");
        require((_user[_from].balances[_to] - _user[_from].allowances[_to].value) >= _amount, "Insufficient free funds.");

        _user[_from].balances[_to] -= _amount;
        _user[_to].myBalance += _amount;
    }
    function verifiesRemainingTime(address _allowed, address _allowner) internal view returns(bool){
        return block.timestamp < _user[_allowed].allowances[_allowner].timestamp + _user[_allowed].allowances[_allowner].duration;
    }
    ////////////////////////////////////////

    function depositMoney() public payable {
        receiveMoney(msg.sender);
    }

    function withdrawFromMyBalance (uint _amount) public {
        decreaseMoneyFromMyBalance(msg.sender, _amount);
        _totalBalance -= _amount;

        payable(msg.sender).transfer(_amount);
    }

    function withdrawFromAllowance (address _allowner, uint _amount) public IsThereAnAllowance(_allowner, msg.sender) verifyRemainingTime(msg.sender,_allowner) {
        require(_user[msg.sender].allowances[_allowner].value >= _amount, "Insufficient allowed funds.");

        _user[msg.sender].allowances[_allowner].value -= _amount;
        _user[msg.sender].balances[_allowner] -= _amount;
        _user[msg.sender].allMyAllowanceBalances -= _amount;
        _totalBalance = _totalBalance - _amount;

        payable(msg.sender).transfer(_amount);
    }


    receive() external payable {
        receiveMoney(msg.sender);
    }
}