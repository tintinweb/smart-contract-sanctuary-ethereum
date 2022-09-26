/**
 *Submitted for verification at Etherscan.io on 2022-09-26
*/

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: contracts/KidsCorpus.sol

////SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.8;

/**@imports*/


/** @title kidsCorpus */

contract kidsCorpus is ReentrancyGuard{

    address public owner;

    kid[] public kids;

    struct kid{
        address payable walletAddress;
        string name;
        uint amount;
        uint releaseTime;
    }

    event kidAdded( address indexed _kidWalletAddress, uint _releaseTime);
    event Deposit(address indexed _kidWalletAddress, address _sender);
    event Withdraw(address indexed _kidWalletAddress, uint _timeofwithdraw);

    constructor(){
        owner = msg.sender;
    }

    modifier onlyOwner{
        require(msg.sender == owner, "you are not allowed to add kid");
        _;
    }

    /** @notice add kids to the array */

    function addKids(address payable _walletAddress, string memory _name, uint _amount,uint _releaseTime) public onlyOwner{
        kids.push(kid(_walletAddress,_name, _amount, _releaseTime));
        emit kidAdded(_walletAddress, _releaseTime);
    }

    /** @notice function allows to deposit to kid wallet */

    function deposit(address _walletAddress) payable public{
       addToKidsBalance(_walletAddress);
       emit Deposit(_walletAddress, msg.sender);
    }

   function getIndex(address _walletAddress) view private returns(uint) {
       uint index;
        for(uint i = 0; i < kids.length; i++) {
            if (kids[i].walletAddress == _walletAddress) {
                index = i;
            }
        }
        return index;
    }

    function addToKidsBalance(address _walletAddress) private{
        uint i = getIndex(_walletAddress);
        if(kids[i].walletAddress == _walletAddress){
               kids[i].amount += msg.value;
           }
       }

    /** @notice to view kids can withdraw or not */
    ///@dev kids can only withdraw after releasetime
    
    function availableToWithdraw(address _walletAddress) public view returns(bool) {
        uint i = getIndex(_walletAddress);
        if(block.timestamp >= kids[i].releaseTime){
            return true;}
        else{
            return false;
        }
        
    }

    /** @notice allows kids to withdraw money */
    ///@dev kids can only withdraw after releasetime

    function withdraw(address _walletAddress) payable public nonReentrant(){
        uint i = getIndex(_walletAddress);
        require(msg.sender == kids[i].walletAddress, "You must be the kid to withdraw");
        require(kids[i].amount>0,"you dont have funds to withdraw");
        require(block.timestamp > kids[i].releaseTime, "You are not able to withdraw at this time");
        kids[i].walletAddress.transfer(kids[i].amount);
        kids[i].amount =0;
        emit Withdraw(_walletAddress, block.timestamp);
    }
}