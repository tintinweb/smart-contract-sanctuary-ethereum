/**
 *Submitted for verification at Etherscan.io on 2022-06-15
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
    IERC20 public rewardToken;
    IERC20 public stakingToken;

    
    uint public _ticketAPrice1;
    uint public _ticketAPrice2;
    uint public _ticketAPrice3;
    uint public _ticketBPrice;
    uint public _stakeAmount;
    address private _asixPlusAddress;
    address private _asixPointAddress;
    uint private _asixPlusAmount;
    uint private _asixPointAmount;




    


    mapping(address => uint) private _validateTime;
    
    mapping(address => uint) private _lastClaimedTime;
    
    
    address private _ownerAddr;

    mapping(address => uint) private ticketA;
    mapping(address => bool) private ticketB;
    
    event ClaimReward(address account, uint amount);
 
    constructor(address _stakingToken, address _rewardsToken) {
        stakingToken = IERC20(_stakingToken);
        rewardToken = IERC20(_rewardsToken);
        _ownerAddr = msg.sender;
        _ticketAPrice1 = 3000 * 1e18;
        _ticketAPrice2 = 15000 * 1e18;
        _ticketAPrice3 = 25000 * 1e18;
        _ticketBPrice = 3000 * 1e18;
        _stakeAmount = 40000 * 1e18;
        _asixPlusAddress = 0x35a7951EaEDf436FD2e2899C1F27Cef35431D61b;
        _asixPointAddress = 0xc56643b2404E69c544008cB904c70c212d7FFdb3;
        
    }

   
  
    modifier checkUserValidate(address account) {
        require(block.timestamp < ticketA[account] && ticketB[account], "Expired, Please stake token!");
        _;
    }


    modifier checkArtistValidate(address account) {
        require(block.timestamp < _validateTime[account], "Expired, Please stake token!");
        _;
    }
    

    function stake() external returns (uint) {
        
        uint _usrAmount = stakingToken.balanceOf(msg.sender);
        require(_usrAmount >= _stakeAmount, "Please check token amount in your wallet.");
       
        bool res = stakingToken.transferFrom(msg.sender, address(this), _stakeAmount); 
        require(res, "Please try again");

        _asixPlusAmount += _stakeAmount;
        _asixPointAmount += _stakeAmount;
        
        if( _validateTime[msg.sender] > block.timestamp){
            _validateTime[msg.sender] = _validateTime[msg.sender] + 365 days;    
        }
        else{
            _validateTime[msg.sender] = block.timestamp + 365 days;
        }
        
        return _validateTime[msg.sender]; 
    }


    function buyTicketA(uint _type) external returns (uint) {

        uint _buyAmount;
        uint _expireDate;
        
        if(_type == 1){
            _buyAmount = _ticketAPrice1;
            _expireDate = 30 days;
        }

        if(_type == 2){
            _buyAmount = _ticketAPrice2;
            _expireDate = 180 days;
        }

        if(_type == 3){
            _buyAmount = _ticketAPrice3;
            _expireDate = 365 days;
        }

        uint _usrAmount = stakingToken.balanceOf(msg.sender);
        require(_usrAmount >= _buyAmount, "Please check token amount in your wallet.");

        bool res = stakingToken.transferFrom(msg.sender, address(this), _buyAmount); 
        require(res, "Please try again.");


        _asixPlusAmount += _buyAmount;
        _asixPointAmount += _buyAmount;

        if(ticketA[msg.sender] > block.timestamp){
            ticketA[msg.sender] = ticketA[msg.sender] + _expireDate;
        }
        else {
            ticketA[msg.sender] = block.timestamp + _expireDate;
        }
        
        
        return ticketA[msg.sender]; 
    }


    function buyTicketB() external returns (bool) {

        uint _usrAmount = stakingToken.balanceOf(msg.sender);
        require(_usrAmount >= _ticketBPrice, "Please check token amount in your wallet.");

        
        bool res = stakingToken.transferFrom(msg.sender, address(this), _ticketBPrice);
        require(res, "Please try again.");

        _asixPlusAmount += _ticketBPrice;
        _asixPointAmount += _ticketBPrice;
        ticketB[msg.sender] = true;
        
        return res; 
    }

    function withdraw(uint _amount) external checkArtistValidate(msg.sender) {
        
        uint restTime = _validateTime[msg.sender] - block.timestamp;
        require((_amount * 365 days) / _stakeAmount  < restTime, "This transaction is not available, You can't withdraw the amount");
        
        bool sent = stakingToken.transfer(msg.sender, _amount);
        require(sent, "Stakingtoken transfer failed");

        _asixPlusAmount -= _amount;
        _asixPointAmount -= _amount;
        _validateTime[msg.sender] = restTime - (_amount * 365 days) / _stakeAmount;
        
        
    }



    function setTicketAPrice1(uint _amount) external {
        require(msg.sender == _ownerAddr, "Can't set Amount");
        require(_amount > 0, "Can't set that Amount");
        _ticketAPrice1 = _amount;
    }

    function setTicketAPrice2(uint _amount) external {
        require(msg.sender == _ownerAddr, "Can't set Amount");
        require(_amount > 0, "Can't set that Amount");
        _ticketAPrice2 = _amount;
    }

    function setTicketAPrice3(uint _amount) external {
        require(msg.sender == _ownerAddr, "Can't set Amount");
        require(_amount > 0, "Can't set that Amount");
        _ticketAPrice3 = _amount;
    }

    function setTicketBPrice(uint _amount) external {
        require(msg.sender == _ownerAddr, "Can't set Amount");
        require(_amount > 0, "Can't set that Amount");
        _ticketBPrice = _amount;
    }

    function setStakeAmount(uint _amount) external {
        require(msg.sender == _ownerAddr, "Can't set Amount");
        require(_amount > 0, "Can't set that Amount");
        _stakeAmount = _amount;
    }

    function setAsixPlusAddress(address _addr) external {
        require(msg.sender == _ownerAddr, "Can't set Address");
        require(_addr != address(0), "Can't set 0 Address");
        _asixPlusAddress = _addr;
    }

    function setAsixPointAddress(address _addr) external {
        require(msg.sender == _ownerAddr, "Can't set Address");
        require(_addr != address(0), "Can't set 0 Address");
        _asixPointAddress = _addr;
    }

    

    function claimReward(uint _hour) external checkUserValidate(msg.sender) {
        
        

        require((block.timestamp - _lastClaimedTime[msg.sender] > _hour * 3600), "this is not verified activity");

       
        uint reward = _hour * 100 * 1e18;
        IAsixPoint( address(rewardToken) ).mint(msg.sender, reward);

        if(_asixPointAmount > reward) _asixPointAmount -= reward;
        else _asixPointAmount = 0;

        _lastClaimedTime[msg.sender] = block.timestamp;

        emit ClaimReward(msg.sender, reward);
    }

    function getValidateTime(address account) public view returns(uint){
        return _validateTime[account];   
    }

    function withdrawAsixPlus(uint _amount) external{
        require(msg.sender == _ownerAddr, "Can't withdraw.");
        
        require(_asixPlusAmount >= _amount, "can't withdraw specify amount.");
        stakingToken.transfer(_asixPlusAddress, _amount);
    }


    function withdrawAsixPoint(uint _amount) external{
        require(msg.sender == _ownerAddr, "Can't withdraw.");
        require(_asixPointAmount >= _amount, "Can't withdraw specify amount.");
        IAsixPoint( address(rewardToken) ).mint(_asixPointAddress, _amount);
        
    }

    function getTicketAStatus(address account) public view returns(uint){
        return ticketA[account];   
    }
    
    function getTicketBStatus(address account) public view returns(bool){
        return ticketB[account];   
    }

    function getAsixPlusTotalAmount() public view returns(uint){
        return _asixPlusAmount;
    }

    function getAsixPointTotalAmount() public view returns(uint){
        return _asixPointAmount;
    }

}