/**
 *Submitted for verification at Etherscan.io on 2022-10-11
*/

// SPDX-License-Identifier: GPL-3.0
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

// File: casino.sol


pragma solidity ^0.8.16;

contract Casino is Ownable{
    struct playersData{
        string name;
        uint mobileNo;
        address Address;
    }
    address casinoOwner;
    mapping (uint=>playersData) userData;
    enum gameStatus {Start,End}
    gameStatus public GameStatus = gameStatus.End;
     constructor(){
         casinoOwner=msg.sender;
     }
     function casinoStatus()public onlyOwner{
         if(address(this).balance>5000000000000000000)  //game is only on when conract address have minimum balance(5 eth).
            {
                GameStatus=gameStatus.Start;
            }
            else{
                GameStatus=gameStatus.End;
            }
     }
 
     function casinoOn()public onlyOwner{
        if(address(this).balance>5000000000000000000)  //game is only on when conract address have minimum balance(5 eth).
            {
                GameStatus=gameStatus.Start;
            }
     }
    receive() external payable {
        require(msg.value>=1 ether);
        payable(msg.sender);
        //if balance of conract is >50 eth so extra amount will be gone to owner.
         if(address(this).balance>50000000000000000000){
            payable (casinoOwner).transfer(address(this).balance-50000000000000000000);
        }
    }
     function userDataEntry(string memory _name, uint _no) public {
         require(GameStatus==gameStatus.Start,"Request owner to start the game");
         userData[_no]=playersData(_name,_no,msg.sender);
         payable (casinoOwner).transfer(100000000000000000);//transfer 10% to owner as their share 
     }
 
    function prizeMoney(uint _range) public view returns(uint256,uint256){
        uint256 prizePercent=0;
        uint256 amount;
        uint256 serviceFee;
        if(_range>=10 && _range<=20){
            prizePercent=10;
        }
        else if(_range>=25 && _range<=35){
            prizePercent=25;
        }else if(_range>=45 && _range<=50){
            prizePercent=50;
        }else{
            prizePercent=5;
        }
        //require(prizePercent!=0,"Wrong range");
        (amount,serviceFee)=prizeAmountCalculation(prizePercent);
        return (amount,serviceFee);
    } 
    function prizeAmountCalculation(uint256 _prizePercent) internal view returns(uint256,uint256){
        uint256 amount=address(this).balance;
        amount=amount*_prizePercent/100;
        uint256 serviceFee=amount/10;
        amount=amount-serviceFee;
        return (amount,serviceFee);
    }
    function bumperOfferOn( uint256 _prizePercent ) public view onlyOwner returns(uint256,uint256){
        uint256 offerAmount;
        uint256 offerFee;
        (offerAmount,offerFee)=prizeAmountCalculation(_prizePercent);
        return (offerAmount,offerFee);
    }
    function payPrize(uint _no,uint256 _amount,uint256 _serviceFee) public {
        require(address(this).balance>_amount+_serviceFee,"insuficient balance");
        address payable winner=payable(userData[_no].Address); 
        payable(casinoOwner).transfer(_serviceFee); //transfer 10% from prize money to owner
        winner.transfer(_amount);
    }
 
}