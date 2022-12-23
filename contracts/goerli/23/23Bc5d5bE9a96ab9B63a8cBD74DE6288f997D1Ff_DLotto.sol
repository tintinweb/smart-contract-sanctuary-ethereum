// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract DLotto is Ownable,Pausable{
    struct lotto{
        uint256 number;
        uint256 amount;
        uint256 typeoflotto;
    }
    
    mapping(address => lotto) public buyer;
    mapping(address => uint256) public balances;
    address[] public all_Buyer;
    uint256[] public announceReward;
    uint256 reward=1 ether;
    uint256 public systemDept;
    address payable public Owner;
    string public theCheck;
    uint256 public balance;
    address payable public recipient;
    uint256[] public rate=[950000000000000000,475000000000000000,475000000000000000,237500000000000000,237500000000000000,190000000000000000]; //[0.95,0.475,0.475,0.2375,0.2375,0.19]
    //uint256 public amount;

/*
    receive() external payable {
        balances[msg.sender] += amt;
    }
    //rate == [0.95,0.475,0.2375,0.2375,0.2375,0.19,0.19];
    //address payable public receiver;
*/
    constructor () { 
        Owner = payable(msg.sender); 
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event PayDividend(uint256 totalAmount);

    function totalBalance() public view returns (uint256){
        return address(this).balance;
    }

    function buyDlotto(uint256 no,uint256 amt,uint256 tp) public payable {

        lotto storage lt = buyer[msg.sender];
        lt.number = no;
        lt.amount = amt;
        lt.typeoflotto = tp;
        /*
        if (balances[msg.sender] == 0) {
            all_Buyer.push(msg.sender);
        }
        */

        all_Buyer.push(msg.sender);
        balances[msg.sender] += amt;
        emit Deposit(msg.sender, amt);

    }

    function getAllBuyer() view public returns (address[] memory) {
        return all_Buyer;
    }

    function lotteryAnnouncement(uint256[] memory rewards) public{ 
        announceReward = rewards;
    }

    function cell() public payable returns (uint256){
        return balance = address(this).balance; 
        //address(this).balance; //smart contract no.
    }
 
    function payReward() public payable onlyOwner{

        address(this).balance;
        //require(reward >= cell(), "Incorrect interest amount");
        for (uint256 i=0;i<all_Buyer.length;i++){
            address payable receiver = payable(all_Buyer[i]);
            for (uint256 j=0;j<announceReward.length;j++)               
                if (buyer[receiver].number == announceReward[j]){                
                    //require(address(this).balance == cell(), "no money on contract");
                    //uint256 amt = buyer[receiver].amount*rate[j];
                    receiver.transfer(buyer[receiver].amount*rate[j]);          
                    //send(receiver);
            }     
        }
        //clear state 
        clearRound();
    }
    function clearRound() public {
        delete all_Buyer;
        delete announceReward;
    }

    function pause() public onlyOwner{
        _pause();
    }


    function unpause() public onlyOwner{
        _unpause();
    }
        function systemWithdraw(uint256 amount)
        public
        onlyOwner
    {
        require(amount <= address(this).balance, "withdraw amount exceed");
        systemDept += amount;
        payable(msg.sender).transfer(amount);
    }

    function systemDeposit()
        public payable
        onlyOwner
    {
        systemDept -= msg.value;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

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
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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