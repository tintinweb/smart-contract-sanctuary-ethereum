/**
 *Submitted for verification at Etherscan.io on 2022-08-19
*/

// SPDX-License-Identifier: MIT
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

// File: contracts/MonsterBattle.sol


pragma solidity ^0.8.0;


interface ICheck {

    function checkEth(address _address, uint256 _amount, string memory signedMessage) external view returns (bool);
}

contract MonsterBattleETH is Ownable{
    ICheck private Check;

    bool public _isActiveWithdrawalETH = true;
    

    uint256 maxWithdrawETH = 0.2 ether;
    uint256 withdrawTimes = 3600;
   
    address public receiver = 0xDAC226421Fe37a1B00A469Cf03Ba5629ef5a3db6;
   
    mapping(address => uint256) private SignatureETH;
   
    event withdrawETHEvent(address indexed to,uint256 indexed _amount,uint256 indexed _timestamp); 
   

    constructor(address _check) {  
        Check = ICheck(_check);
    }

    function withdrawETH(uint256 _amount, string memory _signature) public {
        require(
            _isActiveWithdrawalETH,
            "Withdraw must be active"
        );

         require(
            _amount > 0,
            "Withdraw torch must be greater than 0"
        );

        require(
            _amount <= maxWithdrawETH,
            "Withdraw ETH must be less than max withdraw ETH at 1 time"
        );

        require(
            SignatureETH[msg.sender] + withdrawTimes <= block.timestamp,
            "Can only withdraw 1 times at 1 hour"
        );

        require(
            Check.checkEth(msg.sender, _amount, _signature) == true,
            "Audit error"
        );

        require(
            address(this).balance >= _amount,
            "ETH credit is running low"
        );

        SignatureETH[msg.sender] = block.timestamp;

        payable(msg.sender).transfer(_amount);

        emit withdrawETHEvent(msg.sender, _amount, block.timestamp);
    }
    
    function setReceiver(address _addr) public onlyOwner{
        receiver = _addr;
    }

    function setCheckContract(address _addr) public onlyOwner{
        Check = ICheck(_addr);
    }

    function setMaxWithdrawETH(uint256 _amount) public onlyOwner{
        maxWithdrawETH = _amount;
    }

    function setWithdrawTimes(uint256 _timestamp) public onlyOwner{
        withdrawTimes = _timestamp;
    }

    function rechageEth() public payable {
        require(
            0 <= msg.value,
            "Not enough ether sent"
        );
    }

    function withdrawEth() public payable onlyOwner{
        uint256 amount = address(this).balance;
        payable(receiver).transfer(amount);
    }

}