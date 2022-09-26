/**
 *Submitted for verification at Etherscan.io on 2022-09-26
*/

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

contract Fomo3d is Ownable{
    address payable public  pot; //contract address    
    address public lastBid; //winner
    uint256 public winnerAmount = 0;
    uint256 public potMoney = 0; //contract balance
    uint256 public keySold = 0; 
    uint256 public potEndTime = 0;
    uint256 holderMintPrice = 0;
    uint256 holderPotPrice = 0;
    uint256 public startPrice = 1 * 10 ** 18;
    uint256 public increasePrice = 1 * 10 ** 17;
    address payable public admin; // admin address
    uint256 public adminBalance = 0;
    uint256 nextRound = 0;
    mapping (address => uint256) public keyHolder;
    mapping (address => uint256) public claimedAmount;
    mapping (address => uint256) public referral;


    constructor(){
        potEndTime = block.timestamp + 8 hours;
    }

    modifier isTimerRunning() {
        require(potEndTime >= block.timestamp, "Pot Closed");
        _;
    }

    modifier isTimerEnd() {
        require(potEndTime < block.timestamp, "Pot is runing");
        require(potMoney > 0, "Don't have money");
        _;
    }

   

    function potTimer( uint256 time) public onlyOwner returns(bool){
        require(time > block.timestamp, "Pot time should be greater then current time stamp");
        potEndTime = time;
        return true;
    }
    
    function addAdminAccount( address payable adminAddress) public onlyOwner returns(bool){
        require( admin == 0x0000000000000000000000000000000000000000 , "Admin account already created by owner");
        admin = adminAddress;
        return true;
    }

  
    function mintKey(uint mintAmount, address referralAddress) public payable isTimerRunning returns (bool) {
        require(mintAmount >= (startPrice + (keySold * increasePrice)), "Amount is less then price !");
        keySold++;
        lastBid = msg.sender;
        startPrice += increasePrice;
        keyHolder[msg.sender]++;
        potEndTime += 1 minutes;
        if(potEndTime > block.timestamp + 8 hours){
            potEndTime = block.timestamp + 8 hours;
        }          
        holderMintPrice += ( mintAmount * 30) / 100;           
        potMoney += ( mintAmount * 50 ) / 100;
        adminBalance += (( mintAmount * 5 ) / 100 );
        referral[referralAddress] += ( mintAmount * 15 ) / 100;
        return true;
    }
  
    //-------------------------------pot price distribution-after-end-timer------------------------------

    function potDistribution() public isTimerEnd returns (bool){    
        winnerAmount = ( potMoney * 25 ) / 100;
        payable (lastBid).transfer( winnerAmount);         
        holderPotPrice = keySold /(( potMoney * 175 ) / 10**3);
        adminBalance += (( potMoney * 25 ) /10**3 );   
        nextRound += (( potMoney * 75 ) / 10**3);  
        potMoney = potMoney - (winnerAmount + holderPotPrice + adminBalance + nextRound);
        return true;
    }    

    //------------------------------end-pot price distribution-------------------------------

    // ----------------------------claim-mint-amount-by-Holder---------------------------------

    function claimHoldAmount() public returns (bool){
        uint256 holderMintPricePer =  holderMintPrice / keySold;
        uint256 holderPotPricePer =  holderPotPrice / keySold;
        uint256 claimableMintAmount = (( holderMintPricePer * 50 ) / 100) * keyHolder[msg.sender];
        require(keyHolder[msg.sender] > 0, "You had not sold any key yet!");
            if(potEndTime >= block.timestamp){
                require(claimableMintAmount >= claimedAmount[msg.sender], "You have already claimed !" );
                payable(msg.sender).transfer(claimableMintAmount - claimedAmount[msg.sender]);
                claimedAmount[msg.sender] += (claimableMintAmount - claimedAmount[msg.sender]);
                holderMintPrice = holderMintPrice - claimableMintAmount;
                potMoney -= holderMintPrice;
                return true;
            }else{
                payable(msg.sender).transfer((holderMintPricePer * keyHolder[msg.sender]) +  holderPotPricePer);
                claimedAmount[msg.sender]++;
                holderMintPrice = (holderPotPricePer + (holderMintPricePer * keyHolder[msg.sender])) - claimedAmount[msg.sender];
                holderPotPrice -= holderPotPricePer;
                potMoney -= holderPotPricePer;
                return true;
            }             
    }
    
    // ---------------------------End-claim-mint-amount-by-Holder---------------------------------

    // ----------------------------claim-mint-amount-by-admin---------------------------------

    function claimAdmin(address payable adminAddress) public returns (bool){
        require( adminAddress == admin, "You are not authorized to claim this amount !");
        require( adminBalance != 0, "You don't have any amount to claim !");
        adminAddress.transfer(adminBalance);
        potMoney = potMoney - adminBalance;
        adminBalance = 0 ;        
        return true;
    }
    
    // ---------------------------End-claim-mint-amount-by-admin---------------------------------

    // ----------------------------Referral-mint-amount---------------------------------------

    function referralClaim() public returns (bool){
        require(referral[msg.sender] > 0, "You don't have any referral amount");
        uint256 referralAmount = referral[msg.sender];       
        payable(msg.sender).transfer(referralAmount);
        delete referral[msg.sender];
        return true;
    }

    // ---------------------------End-Referral-mint-amount---------------------------------------

    
     
}