// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


import "./ReentrancyGuard.sol";
import "./FullMath.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./IUniswapV2Router.sol";
import "./SafeERC20.sol";

contract MoonLabsVesting is ReentrancyGuard, Ownable{    

    using SafeERC20 for IERC20;

    constructor(address _tokenToBurn, uint _burnPercent) {
        require(_burnPercent <= 100, "Burn percent cannot be over 100");
        tokenToBurn = _tokenToBurn;
        burnPercent = _burnPercent;
        lockPrice = 25000000000000000;
        uniswapV2Router = IUniswapV2Router(0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45);
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}


    /*|| === STATE VARIABLES === ||*/
    address public tokenToBurn;
    uint public burnPercent;
    uint public index;
    uint public lockPrice;
    IUniswapV2Router public immutable uniswapV2Router;


    /*|| === STRUCTS VARIABLES === ||*/
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

    modifier onlyToken() {
        require(msg.sender == address(this)); 
        _;
    }


    /*|| === CORE FUNCTIONS === ||*/
    //Create lock or vesting instance
    function createVest(address _tokenAddress, address[] calldata _withdrawAddress, uint[] calldata _depositAmount, uint[] calldata _endDate,  uint[] calldata _startDate) external payable nonReentrant returns(bool){
        // Check if all arrays are same the size
        require(_withdrawAddress.length == _depositAmount.length && _depositAmount.length == _endDate.length && _endDate.length == _startDate.length, "Unequal array sizes");
        require(msg.value == lockPrice * _withdrawAddress.length, "Incorrect Price");

        uint _depAmount = 0;

        for(uint i; i < _withdrawAddress.length; i++){
            createVestingInstance(_tokenAddress, _withdrawAddress[i], _depositAmount[i], _endDate[i], _startDate[i]);
            _depAmount += _depositAmount[i];
        }

        IERC20(_tokenAddress).safeTransferFrom( msg.sender, address(this), _depAmount);

        // Buy tokenToBurn via uniswap router 
        address[] memory path = new address[](2);
        path[0] = tokenToBurn;
        path[1] = uniswapV2Router.WETH();

        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: (msg.value * (burnPercent/100))}(
            0,
            path,
            address(this),
            block.timestamp + 10
        );

        return true;
    }

    // Create vesting instance
    function createVestingInstance(address _tokenAddress, address _withdrawAddress, uint _depositAmount, uint _endDate, uint _startDate) private nonReentrant{
        require(_depositAmount > 0, "Deposit amount must be greater than 0");
        require(_startDate < _endDate, "Start date must come before end date");
        require(_endDate >= block.timestamp - 100 && _endDate < 10000000000, "Invalid end date");

        vestingInstance[index].tokenAddress = _tokenAddress;
        vestingInstance[index].creatorAddress = msg.sender;
        vestingInstance[index].withdrawAddress = _withdrawAddress;
        vestingInstance[index].depositAmount = _depositAmount;
        vestingInstance[index].totalAmount = _depositAmount;
        vestingInstance[index].endDate = _endDate;
        vestingInstance[index].startDate = _startDate;


        // Send tokenToBurn to dead address
        IERC20(tokenToBurn).transfer(0x000000000000000000000000000000000000dEaD, IERC20(tokenToBurn).balanceOf(address(this)));

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
    function getVestingIndexFromTokenAddress(address _tokenAddress) external view returns(uint[] memory){
        return tokenAddressToLock[_tokenAddress];
    }
    
    // Return vesting instance from index
    function getVestingInstanceDetails(uint _index) external view returns(VestingInstance memory){
        return vestingInstance[_index];
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
    function transferVestingOwnership(uint _index, address _newOwner) public withdrawOwner(_index){
        vestingInstance[_index].withdrawAddress = _newOwner;
    }

    // Claim unlocked tokens
    function withdrawUnlockedTokens(uint _index, uint _amount) external nonReentrant withdrawOwner(_index){
        require(_amount <= getClaimableTokens(_index) , "Exceedes withdraw balance");
        require(_amount > 0, "Cannot withdraw 0 tokens");
        // Add claim amount to total withdraw amount
        vestingInstance[_index].totalAmount -= _amount;
        // Transfer tokens from contract to recipient
        IERC20(vestingInstance[_index].tokenAddress).safeTransfer(msg.sender,  _amount);
    }


    /*|| === OWNER FUNCTIONS === ||*/
    // Claim bnb in contract
    function claimETH() external onlyOwner{
        address payable to = payable(msg.sender);
        to.transfer(address(this).balance);
    }
    
    // Change lock price in wei
    function setLockPrice(uint _lockPrice) external onlyOwner{
        lockPrice = _lockPrice;
    }

    // Change token to auto burn
    function setTokenToBurn(address _tokenToBurn) external onlyOwner{
        tokenToBurn = _tokenToBurn;
    }

    // Change amount of tokens to autoburn
    function setBurnPercent(uint _burnPercent) external onlyOwner{
        require( _burnPercent <= 100, "Burn percent cannot exceed 100");
        burnPercent = _burnPercent;
    }

    // THIS IS A SAFEGUARD FUNCTION ONLY TO BE USED WHEN TOKENS ARE STUCK!!!
    function forceUnlock(uint _index) external onlyOwner{
        vestingInstance[_index].endDate = block.timestamp;
        vestingInstance[_index].startDate = 0;
    }

}