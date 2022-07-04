/**
 *Submitted for verification at Etherscan.io on 2022-07-04
*/

/**
 *Submitted for verification at BscScan.com on 2022-05-28
*/

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.6.0/contracts/security/ReentrancyGuard.sol

// SPDX-License-Identifier: MIT

// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity 0.8.10;

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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.6.0/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)



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

// File: contracts/AsixPlusStaking.sol

interface IAsixPoint {
    function mint(address account_, uint256 amount_) external;
    function burnFrom(address account_, uint256 amount_) external;
    function transfer(address sender_, address recipient, uint256 amount_) external;
}





contract MusicReward {
    IERC20 public rewardToken;  // reward token
    IERC20 public stakingToken; // stake token

    
    uint public _silverPrice1; // Silver ticket Price (One month)
    uint public _silverPrice2; // Silver ticket Price (6 months)
    uint public _silverPrice3; // Silver ticket Price (12 months)
    uint public _goldPrice; // Gold ticket Price
    uint public _platinumPrice;  // Platinum ticket Price
    uint public _stakeAmount; // Stake Token amount for Artist(AsixPlus)
    uint public _rewardUnitFromListen; // Reward Token amount(AsixPoint)
    uint public _rewardUnitFromPromote; // Reward Token amount(AsixPoint)
    uint public _seatRate;

    address private _asixPlusAddress; // AsixPlus token address
    address private _asixPointAddress; // AsixPoint token address
    uint private _asixPlusAmount; // Pool AsixPlus token total amount
    uint private _asixPointAmount; // Pool AsixPoint tokenn total amount
    uint private _totalUser;    // Total User number buy Silver ticket
    
    uint private _curSlotNumber; // Current Gold Slot Number (always same 10% of total User)

    mapping(address => uint) private _validateTime; // available Time for upload - artist.
    mapping(address => uint) private _lastClaimedTime; // time when claim.
    address private _ownerAddr; // contract owner address

    mapping(address => uint) private silver; // Silver ticket array
    mapping(address => bool) private gold; // Silver ticket array
    mapping(address => bool) private platinum; // Platinum ticket array
    mapping(uint => address) private totalAccount; // Platinum ticket array
    
    event ClaimReward(address account, uint amount);
 
    constructor(address _stakingToken, address _rewardsToken) { // staking, reward...
        stakingToken = IERC20(_stakingToken);
        rewardToken = IERC20(_rewardsToken);
        _ownerAddr = msg.sender;
        _silverPrice1 = 3000 * 1e18; // set silver ticket price(one month)
        _silverPrice2 = 15000 * 1e18; // set silver ticket price(6 months)
        _silverPrice3 = 25000 * 1e18; // set silver ticket price(12 months)
        _platinumPrice = 3000 * 1e18; // set Platinum ticket price. 
        _goldPrice = 3000 * 1e18; // set Gold ticket price. 
        _seatRate = 10; // set Seat number.
        _stakeAmount = 40000 * 1e18; //  set staking amount for artist.
        _rewardUnitFromListen = 100 * 1e18;
        _rewardUnitFromPromote = 100 * 1e18;
        _asixPlusAddress = 0x35a7951EaEDf436FD2e2899C1F27Cef35431D61b;
        _asixPointAddress = 0xc56643b2404E69c544008cB904c70c212d7FFdb3;
        
    }

   
  
    modifier checkUserValidate(address account) {
        require(block.timestamp < silver[account] && platinum[account], "Expired, Please stake token!"); // check if silver ticket is available 
        _;
    }


    modifier checkArtistValidate(address account) {
        require(block.timestamp < _validateTime[account], "Expired, Please stake token!"); // check if artist status is available
        _;
    }
    
    function shareRoyalty() external returns(uint){
        if( _validateTime[msg.sender] > block.timestamp){ // Check if current available member.
            _validateTime[msg.sender] = _validateTime[msg.sender] + 365 days; // add time more. 
        }
        else{
            _validateTime[msg.sender] = block.timestamp + 365 days; // Add newly.
        }
        return _validateTime[msg.sender];
    }
    function stake() external returns (uint) { // artist staking.
        
        uint _usrAmount = stakingToken.balanceOf(msg.sender); // check if staking amount is enough.
        require(_usrAmount >= _stakeAmount, "Please check token amount in your wallet.");
       
        bool res = stakingToken.transferFrom(msg.sender, address(this), _stakeAmount); // transfer staking token to POOL.
        require(res, "Please try again");

        _asixPlusAmount += _stakeAmount; // increase POOL's AsixPlus amount.
        _asixPointAmount += _stakeAmount; // increase POOL's AsixPoint amount.
        
        if( _validateTime[msg.sender] > block.timestamp){ // Check if current available member.
            _validateTime[msg.sender] = _validateTime[msg.sender] + 365 days; // add time more. 
        }
        else{
            _validateTime[msg.sender] = block.timestamp + 365 days; // Add newly.
        }
        
        return _validateTime[msg.sender]; 
    }


    function buySilver(uint _type) external returns (uint) { //Buy Silver ticket

        uint _buyAmount;
        uint _expireDate;
        
        if(_type == 1){ // Check if type is one month.
            _buyAmount = _silverPrice1;
            _expireDate = 30 days;
        }

        if(_type == 2){ // Check if type is 6 months.
            _buyAmount = _silverPrice2;
            _expireDate = 180 days;
        }

        if(_type == 3){ // Check if type is 12 months.
            _buyAmount = _silverPrice3;
            _expireDate = 365 days;
        }

        uint _usrAmount = stakingToken.balanceOf(msg.sender); // Check if staking amount is available.
        require(_usrAmount >= _buyAmount, "Please check token amount in your wallet.");

        bool res = stakingToken.transferFrom(msg.sender, address(this), _buyAmount); // Staking token transfer to POOL.
        require(res, "Please try again.");


        _asixPlusAmount += _buyAmount; // Increase AsixPlus Amount on POOL.
        _asixPointAmount += _buyAmount; // Increase AsixPoint Amount on POOL.

        if(silver[msg.sender] > block.timestamp){ // Check if silver expire Date left.
            silver[msg.sender] = silver[msg.sender] + _expireDate;
            
        }
        else { // make new silver ticket.
            silver[msg.sender] = block.timestamp + _expireDate;
            totalAccount[_totalUser] = msg.sender;
            _totalUser += 1;
            

        }
        
        
        return silver[msg.sender]; 
    }

    function buyGold() external returns (bool) { // Buy Platinum ticket.


        require(silver[msg.sender] > block.timestamp, "Your account is not available to buy Gold.");
        
        
        uint _usrAmount = stakingToken.balanceOf(msg.sender); // check if staking token amount is available.
        require(_usrAmount >= _goldPrice, "Please check token amount in your wallet.");

        bool res = stakingToken.transferFrom(msg.sender, address(this), _goldPrice); // staking token transfer POOL.
        require(res, "Please try again.");

        _asixPlusAmount += _goldPrice; // Increase AsixPlus Amount on POOL.
        _asixPointAmount += _goldPrice; // Increase AsixPoint Amount on POOL.
        gold[msg.sender] = true;
        
        
        return res; 
    }



    function buyPlatinum() external returns (bool) { // Buy Platinum ticket.
    
        require(gold[msg.sender], "You're not available to buy Platinum ticket.");

        uint tmpNum = 0;
        
        for (uint i = 0; i < _totalUser; i++){
            if( silver[totalAccount[i]] > block.timestamp ){
                totalAccount[tmpNum] = totalAccount[i];
                tmpNum += 1; 
            }
        }

        _totalUser = tmpNum;
        
        tmpNum = 0;
        
        for(uint i = 0; i < _totalUser; i++){
            if(gold[totalAccount[i]] == true) tmpNum += 1;
        }
        _curSlotNumber = tmpNum;
        require( (_totalUser * _seatRate) / 100 > _curSlotNumber, "There is not seat.");
        _curSlotNumber += 1;

        uint _usrAmount = stakingToken.balanceOf(msg.sender); // check if staking token amount is available.
        require(_usrAmount >= _platinumPrice, "Please check token amount in your wallet.");

        bool res = stakingToken.transferFrom(msg.sender, address(this), _platinumPrice); // staking token transfer POOL.
        require(res, "Please try again.");

        _asixPlusAmount += _platinumPrice; // Increase AsixPlus Amount on POOL.
        _asixPointAmount += _platinumPrice; // Increase AsixPoint Amount on POOL.
        platinum[msg.sender] = true;
        
        return res; 
    }

    function withdraw(uint _amount) external checkArtistValidate(msg.sender) { // Withdraw from POOL in artist side.
        
        uint restTime = _validateTime[msg.sender] - block.timestamp; // Check if rest time exists.
        require((_amount * 365 days) / _stakeAmount  < restTime, "This transaction is not available, You can't withdraw the amount");
        
        bool sent = stakingToken.transfer(msg.sender, _amount); // transfer Staking token to artist.
        require(sent, "Stakingtoken transfer failed");

        _asixPlusAmount -= _amount;
        _asixPointAmount -= _amount;
        _validateTime[msg.sender] = restTime - (_amount * 365 days) / _stakeAmount;
    }



    function setSilverPrice1(uint _amount) external { // Set silver ticket price(one month).
        require(msg.sender == _ownerAddr, "Can't set Amount");
        require(_amount > 0, "Can't set that Amount");
        _silverPrice1 = _amount;
    }

    function setSilverPrice2(uint _amount) external { // Set silver ticket price(6 months).
        require(msg.sender == _ownerAddr, "Can't set Amount");
        require(_amount > 0, "Can't set that Amount");
        _silverPrice2 = _amount;
    }

    function setSilverPrice3(uint _amount) external { // Set silver ticket price(12 months)
        require(msg.sender == _ownerAddr, "Can't set Amount");
        require(_amount > 0, "Can't set that Amount");
        _silverPrice3 = _amount;
    }

    function setPlatinumPrice(uint _amount) external { // Set platinum ticket price
        require(msg.sender == _ownerAddr, "Can't set Amount");
        require(_amount > 0, "Can't set that Amount");
        _platinumPrice = _amount;
    }

    function setGoldPrice(uint _amount) external { // Set platinum ticket price
        require(msg.sender == _ownerAddr, "Can't set Amount");
        require(_amount > 0, "Can't set that Amount");
        _goldPrice = _amount;
    }

    function setRewardUnitFromListen(uint _amount) external { // Set RewardAmount for listening per hour.
        require(msg.sender == _ownerAddr, "Can't set Amount");
        require(_amount > 0, "Can't set that Amount");
        _rewardUnitFromListen = _amount;
    }

    function setRewardUnitFromPromote(uint _amount) external { // Set RewardAmount for listening per hour.
        require(msg.sender == _ownerAddr, "Can't set Amount");
        require(_amount > 0, "Can't set that Amount");
        _rewardUnitFromPromote = _amount;
    }

    function setStakeAmount(uint _amount) external { // Set staking amount for artist.
        require(msg.sender == _ownerAddr, "Can't set Amount");
        require(_amount > 0, "Can't set that Amount");
        _stakeAmount = _amount;
    }
    

    function setSeatRate(uint _amount) external { // Set staking amount for artist.
        require(msg.sender == _ownerAddr, "Can't set Amount");
        require(_amount > 0, "Can't set that Amount");
        _seatRate = _amount;
    }


    function setAsixPlusAddress(address _addr) external { // Set AsixPlus address
        require(msg.sender == _ownerAddr, "Can't set Address");
        require(_addr != address(0), "Can't set 0 Address");
        _asixPlusAddress = _addr;
    }

    function setAsixPointAddress(address _addr) external { // Set AsixPoint address
        require(msg.sender == _ownerAddr, "Can't set Address");
        require(_addr != address(0), "Can't set 0 Address");
        _asixPointAddress = _addr;
    }


    function claimRewardFromListening(uint _hour) external checkUserValidate(msg.sender) { // claim tokens base on listening time.

        require((block.timestamp - _lastClaimedTime[msg.sender] > _hour * 3600), "this is not verified activity"); // check if available transaction.
        uint reward = _hour * _rewardUnitFromListen; // Calculation Reward Amount.
        IAsixPoint( address(rewardToken) ).mint(msg.sender, reward);

        if(_asixPointAmount > reward) _asixPointAmount -= reward; 
        else _asixPointAmount = 0;

        _lastClaimedTime[msg.sender] = block.timestamp;
        
    }

    function claimRewardFromPromotion(uint _userAmount) external { // claim tokens base on listening time.

        
        uint reward = _userAmount * _rewardUnitFromPromote; // Calculation Reward Amount.
        IAsixPoint( address(rewardToken) ).mint(msg.sender, reward);

        if(_asixPointAmount > reward) _asixPointAmount -= reward; 
        else _asixPointAmount = 0;


    }

    function getValidateTime(address account) public view returns(uint){ // get validate time from account info.
        return _validateTime[account];   
    }

    function withdrawAsixPlus(uint _amount) external{ // withdraw AsixPlus token.
        require(msg.sender == _ownerAddr, "Can't withdraw.");    
        require(_asixPlusAmount >= _amount, "can't withdraw specify amount.");
        stakingToken.transfer(_asixPlusAddress, _amount);
    }

    function withdrawAsixPoint(uint _amount) external{ // withdraw AsixPoint token.
        require(msg.sender == _ownerAddr, "Can't withdraw.");
        require(_asixPointAmount >= _amount, "Can't withdraw specify amount.");
        IAsixPoint( address(rewardToken) ).mint(_asixPointAddress, _amount);
    }

    function getSilverStatus(address account) public view returns(uint){
        return silver[account];   
    }

    function getGoldStatus(address account) public view returns(bool){
        return gold[account];   
    }
    
    function getPlatinumStatus(address account) public view returns(bool){
        return platinum[account];   
    }

    function getAsixPlusTotalAmount() public view returns(uint){
        return _asixPlusAmount;
    }

    function getAsixPointTotalAmount() public view returns(uint){
        return _asixPointAmount;
    }

    function getSilverPrice1() public view returns(uint){
        return _silverPrice1;
    }
    function getSilverPrice2() public view returns(uint){
        return _silverPrice2;
    }
    function getSilverPrice3() public view returns(uint){
        return _silverPrice3;
    }
    
    function getGoldPrice() public view returns(uint){
        return _goldPrice;
    }
    function getPlatinumPrice() public view returns(uint){
        return _platinumPrice;
    }

     function getSeatRate() public view returns(uint){
        return _seatRate;
    }

    function getTotalUser() public view returns(uint){
        return _totalUser;
    }
    function getSlotNumber() public view returns(uint){
        return _curSlotNumber;
    }
    function getRewardUnitForListen() public view returns(uint){
        return _rewardUnitFromListen;
    }
    function getRewardUnitForPromote() public view returns(uint){
        return _rewardUnitFromPromote;
    }

}