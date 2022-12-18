/**
 *Submitted for verification at Etherscan.io on 2022-12-17
*/

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: contracts/Tombstone.sol



pragma solidity ^0.8.17;


contract Tombstone is ReentrancyGuard {

event deposit(address depositer, address beneficiary, uint amount, uint timenow, uint timeremaining);
event adddeposit (address depositer, uint amount);
event withdraw (address depositer, uint amount);
event alive (uint timenow, uint timeremaining);
event death (address recipient, uint amount, bool status);



//this line will assign a beneficiary to each depositer 
mapping (address => address) public beneficiary;

//this line will check to see if depositer is alive 
mapping (address => bool) public dead;




//this line will create a mapping for the accounts
mapping(address=> uint) public accounts;

//this line will keep track of how time is left 
mapping (address => uint) public timeleft;



//this line will deposit ETH and update the account
function Deposit (address recipient) public payable {
    require (dead[msg.sender] == false, "You are dead");
    require (beneficiary[msg.sender] == address(0), "You already have a beneficiary, please choose the continue deposit option");
    accounts[msg.sender] += msg.value;
    beneficiary[msg.sender] = recipient;
    timeleft[msg.sender] = block.timestamp + 1 minutes;

    emit deposit(msg.sender, recipient , msg.value, block.timestamp, timeleft[msg.sender]);
}

//this function is to be called if the depositer has already called the first deposit function
function AddDeposit () public payable {
   require (dead[msg.sender] == false, "You are dead");
   require (beneficiary[msg.sender] != address(0), "Must have a beneficiary");
   accounts[msg.sender] += msg.value;

   emit adddeposit(msg.sender, msg.value);

}


//an email will be sent to the deposit to call this contract or less the funds will be sent to beneficiary
function CheckifAlive () external   {
    require(dead[msg.sender] == false, "You are dead");
    require (accounts[msg.sender] > 0, "Only depositers are authorized");
    require (beneficiary[msg.sender] != address(0), "Must have a beneficiary");
    require (block.timestamp >= timeleft[msg.sender], "There is still time left for the next approval" );
    timeleft[msg.sender] = block.timestamp + 1 minutes;

   emit alive(block.timestamp, timeleft[msg.sender]);
}


//this function will be automated by Chainlink
function IfDead () external {

  require (accounts[msg.sender] > 0, "Only depositers are authorized");
  require (beneficiary[msg.sender] != address(0), "Must have a beneficiary");
  require (block.timestamp >= timeleft[msg.sender], "There is still time left for the next approval" );


    payable(beneficiary[msg.sender]).transfer(accounts[msg.sender]);

    dead[msg.sender] = true;

    emit death(msg.sender, accounts[msg.sender], true);

}





//this line will allow the user to withdraw his/her money. It also prevent Re-Entrancy attacks 
//by implenting OpenZepplin extension  
function Withdraw(uint amount)public payable nonReentrant {
    require (accounts[msg.sender] >= amount, "You do not have enough money in your account");
    accounts[msg.sender] -= amount;
    //this line allows the user to withdraw their money 
    payable(msg.sender).transfer(amount);

    emit withdraw(msg.sender, amount);


}


//this line will show the overall balance 
function Getbalance() public view returns (uint){
    return address(this).balance;
}


//this line will show the balance of the msg.sender's account 
function GetUserBalance() public view returns (uint){
    return accounts[msg.sender];

}





}