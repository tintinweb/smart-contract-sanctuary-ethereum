// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


import "./ReentrancyGuard.sol";
import "./FullMath.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

contract MoonLabsVesting is ReentrancyGuard, Ownable{    
    using SafeERC20 for IERC20;


    constructor(address _tokenToBurn, uint _burnPercent) {
        require(_burnPercent <= 100, "Burn percent cannot be over 100");
        tokenToBurn = _tokenToBurn;
        burnPercent = _burnPercent;
        lockPrice = 25000000000000000;
    }


    /*|| === STATE VARIABLES === ||*/

    address public tokenToBurn;
    uint public burnPercent;
    uint private index;
    uint public lockPrice;



    struct VestingInstance {
        address tokenAddress; // Address of locked token
        address creatorAddress; // Lock creator
        address withdrawAddress; // Withdraw address
        uint depositAmount; // Initial deposit amount
        uint totalAmount; // Current tokens in lock
        uint endDate; // Date when tokens are fully unlocked
        uint startDate;// Linear lock if !=0. Date when tokens start to unlock
    }


    /*|| === MAPPING === ||*/

    mapping (address => uint[]) private creatorAddressToLock;
    mapping (address => uint[]) private withdrawAddressToLock;
    mapping (address => uint[]) private tokenAddressToLock;
    mapping (uint => VestingInstance) private vestingInstance;


    /*|| === MODIFIERS === ||*/

    modifier withdrawOwner(uint _index){
        require(msg.sender == vestingInstance[_index].withdrawAddress, "You do not own this lock");
        _;
    }


    /*|| === CORE FUNCTIONS === ||*/

    //Create lock or vesting instance
    function createVest(address _tokenAddress, address[] calldata _withdrawAddress, uint[] calldata _depositAmount, uint[] calldata _endDate,  uint[] calldata _startDate) nonReentrant external payable{
        // Check if all arrays are same size
        require(_withdrawAddress.length == _depositAmount.length && _depositAmount.length == _endDate.length && _endDate.length == _startDate.length, "Unequal array sizes");
        require(msg.value == lockPrice * _withdrawAddress.length, "Incorrect Price");

        for(uint i; i < _withdrawAddress.length; i++){
            createVestingInstance(_tokenAddress, _withdrawAddress[i], _depositAmount[i], _endDate[i], _startDate[i]);
        }

    }

    // Create vesting instance
    function createVestingInstance(address _tokenAddress, address _withdrawAddress, uint _depositAmount, uint _endDate, uint _startDate) private {
        require(_depositAmount > 0, "Deposit amount must be greater than 0");
        require(_startDate == 0 || _startDate >= block.timestamp, "Invalid start date");
        require(_startDate < _endDate, "Start date must come before end date");
        require(_endDate > block.timestamp && _endDate < 10000000000, "Invalid end date");
        IERC20(_tokenAddress).safeTransferFrom(msg.sender, address(this), _depositAmount);
        // Request caller to send token to contract

        vestingInstance[index].tokenAddress = _tokenAddress;
        vestingInstance[index].creatorAddress = msg.sender;
        vestingInstance[index].withdrawAddress = _withdrawAddress;
        vestingInstance[index].depositAmount = _depositAmount;
        vestingInstance[index].totalAmount = _depositAmount;
        vestingInstance[index].endDate = _endDate;
        vestingInstance[index].startDate = _startDate;



        // Create map to withdraw address
        withdrawAddressToLock[_withdrawAddress].push(index);

        // Create map to token address
        tokenAddressToLock[_tokenAddress].push(index);

        // Create map to creator address
        creatorAddressToLock[msg.sender].push(index);

        // Increment index
        index++;
    }


    /*|| === VIEW FUNCTIONS === ||*/

    // Return vesting index from owner address
    function getVestingIndexFromCreatorAddress(address _creatorAddress) external view returns(uint[] memory){
        return creatorAddressToLock[_creatorAddress];
    }

    // Return vesting index from withdraw address
    function getVestingIndexFromWithdrawAddress(address _withdrawAddress) external view returns(uint[] memory){
        return withdrawAddressToLock[_withdrawAddress];
    }

    // Return vest index from token address
    function getVestingIndexFromWtoken(address _tokenAddress) external view returns(uint[] memory){
        return tokenAddressToLock[_tokenAddress];
    }
    
    // Return vesting instance from index
    function getVestingInstanceDetails(uint _index) external view returns(VestingInstance memory){
        return vestingInstance[_index];
    }

    // Return time left on token lock
    function getLockTime(uint _index) external view returns(uint[2] memory timeLeft){
        uint _endDate = vestingInstance[_index].endDate;
        uint _startDate = vestingInstance[_index].startDate;
        uint[2] memory _timeLeft;

        if(_startDate == 0){
            _timeLeft[0] = _endDate;
            _timeLeft[1] = _startDate;
        }else{
            _timeLeft[0] = _endDate;
            _timeLeft[1] = _startDate;
        }
        return _timeLeft;

    }
    // Return claimable tokens
    function getClaimableTokens(uint _index) public view returns(uint tokens){
        uint _tokensRemaining = vestingInstance[_index].totalAmount;
        uint _endDate = vestingInstance[_index].endDate;
        uint _startDate = vestingInstance[_index].startDate;

        // Check if token balance is 0
        if(_tokensRemaining == 0){
            return 0;
        }

        // Check if lock is not linear
        if(_startDate == 0){
            return _endDate <= block.timestamp ? _tokensRemaining : 0;
        }

        // If none of the above then token is a linear lock
        return calculateLinearWithdraw(_index, _tokensRemaining);
    }

    // Get current amount of unlocked tokens
    function calculateLinearWithdraw(uint _index, uint _tokensRemaining) private view returns(uint unlockedTokens){
        uint _endDate = vestingInstance[_index].endDate;
        uint _startDate = vestingInstance[_index].startDate;
        uint _timeBlock = _endDate - _startDate;
        uint _timeElapsed;

        if(_endDate <= block.timestamp){ 
            _timeElapsed = _timeBlock;
        }else if(_startDate >= block.timestamp){
            _timeElapsed = 0;
        }else{
            _timeElapsed  = block.timestamp - _startDate;
        }
        // Math to calcualte linear unlock
        return  FullMath.mulDiv(_tokensRemaining, _timeElapsed, _timeBlock);
    }


    /*|| === MUTATIVE FUNCTIONS === ||*/

    // Transfer withdraw address
    function transferVestingOwnership(uint _index, address _newOwner) public nonReentrant withdrawOwner(_index){
        vestingInstance[_index].withdrawAddress = _newOwner;
    }

    // Claim unlocked tokens
    function withdrawUnlockedTokens(uint _index, uint _amount) external nonReentrant withdrawOwner(_index){
        require(_amount <= getClaimableTokens(_index) , "Exceedes withdraw balance");
        require(_amount > 0, "Cannot withdraw 0 tokens");
        // Add claim amount to total withdraw amount
        vestingInstance[_index].totalAmount -= _amount;
        // Transfer tokens from contract to recipient
        IERC20(vestingInstance[index].tokenAddress).safeTransfer(msg.sender,  _amount);
    }

    /*|| === OWNER FUNCTIONS === ||*/

    // Change lock price in wei
    function changeLockPrice(uint _lockPrice) external onlyOwner{
        lockPrice = _lockPrice;
    }

    // Change token to auto burn
    function changeTokenToBurn(address _tokenToBurn) external onlyOwner{
        tokenToBurn = _tokenToBurn;
    }

    // Change amount of tokens to autoburn
    function changeBurnPercent(uint _burnPercent) external onlyOwner{
        require( _burnPercent <= 100, "Burn percent cannot exceed 100");
        burnPercent = _burnPercent;
    }

    // THIS IS A SAFEGUARD FUNCTION ONLY TO BE USED WHEN TOKENS ARE STUCK!!!
    function forceUnlock(uint _index) external onlyOwner{
        vestingInstance[_index].endDate = block.timestamp;
        vestingInstance[_index].startDate = 0;
    }

}