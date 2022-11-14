// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "./vestingClaims.sol";

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function latestAnswer() external view returns (int256);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

contract Presale is Ownable {
    using SafeMath for uint256;
    // event WalletCreated(address vestingAddress,address userAddress,uint256 amount);
    bool public isPresaleOpen = true;
    address public admin;

    AggregatorV3Interface internal priceFeed;

    address public tokenAddress;
    uint256 public tokenDecimals;

    //2 means if you want 100 tokens per eth then set the rate as 100 + number of rateDecimals i.e => 10000
    uint256 public rateDecimals = 2;
    uint256 public tokenSold = 0;
    
    uint256 public totalEthAmount = 0;
    uint256 public totalUSDAmount = 0;
    uint256 public buyTokenPercentage = 500;
    uint256[] public rLockinPeriod = [0,180,360,720,720];

    uint256[] public priceBrackets = [5000,50000,150000,250000];
    uint256[] public pricePerToken = [8,7,6,5];
    
    uint256 public sliceDays;

    uint256 public hardcap = 10000*1e18;  // Total Eth Value
    address private dev;

    vestingContract vestingAddress;

    mapping(address => uint256) public usersInvestments;

    address public recipient;

    modifier onlyOwnerAndAdmin()   {
        require(
            owner() == _msgSender() || _msgSender() == admin,
            "Ownable: caller is not the owner or admin"
        );
        _;
    }

    constructor(
        address _token,
        address _recipient
    ) {
        tokenAddress = _token;
        tokenDecimals = IToken(_token).decimals();
        recipient = _recipient;
        priceFeed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
        sliceDays = 30;
        admin = _msgSender();
    }

    function getEthPriceInUsd() public view returns(int256) {
        return (priceFeed.latestAnswer()/1e8);
    }

    function getLaunchedAt() public view returns(uint256 ) {
        return(vestingAddress.listedAt());
    }

    function setAdmin(address account) external  onlyOwnerAndAdmin{
        require(account != address(0),"Invalid Address, Address should not be zero");
        admin = account;
    }

    function setVestingAddress(address _vestingAddress) external onlyOwnerAndAdmin {
        vestingAddress = vestingContract(_vestingAddress);
    }

    function setRecipient(address _recipient) external onlyOwnerAndAdmin {
        recipient = _recipient;
    }

    function setBuyTokenPercentage(uint _percentage) public  onlyOwnerAndAdmin{
        buyTokenPercentage = _percentage;  
    }

    function setPriceBrackets(uint256[] memory _priceBrackets)
        external
        onlyOwnerAndAdmin
    {
        priceBrackets = _priceBrackets;
    }

    function setPricePerToken(uint256[] memory _pricePerToken)
        external
        onlyOwnerAndAdmin
    {
        pricePerToken = _pricePerToken;
    }

    function setRLockinPeriods(uint256[] memory _rLockinPeriod) external onlyOwnerAndAdmin {
        rLockinPeriod = _rLockinPeriod;
    }

    function setHardcap(uint256 _hardcap) external onlyOwnerAndAdmin {
        hardcap = _hardcap;
    }

    function startPresale() external onlyOwnerAndAdmin {
        require(!isPresaleOpen, "Presale is open");

        isPresaleOpen = true;
    }

    function closePresale() external onlyOwnerAndAdmin {
        require(isPresaleOpen, "Presale is not open yet.");

        isPresaleOpen = false;
    }

    function setTokenAddress(address token) external onlyOwnerAndAdmin {
        require(token != address(0), "Token address zero not allowed.");
        tokenAddress = token;
        tokenDecimals = IToken(token).decimals();
    }

    function setTokenDecimals(uint256 decimals) external onlyOwnerAndAdmin {
        tokenDecimals = decimals;
    }

    function setRateDecimals(uint256 decimals) external onlyOwnerAndAdmin {
        rateDecimals = decimals;
    }

    receive() external payable {

    }

    function buyToken(uint256 _amountInUSD) public payable  {
        require(isPresaleOpen, "Presale is not open.");
        require(getLaunchedAt() == 0,"Already Listed!");
        
        uint256 priceInUSD = uint256(getEthPriceInUsd());

        uint256 priceUSDInEth = (((1*1e18)/priceInUSD)*_amountInUSD);

        require(priceUSDInEth <= msg.value,"Insufficient amount.");

        (,uint256 tokenAmount) = getTokens(_amountInUSD);  // token amount with decimals
        
        (uint256 range,uint256 _slicePeriod) = getDuration(_amountInUSD);


        if (range == 0) {
            require(
                IToken(tokenAddress).transfer(msg.sender, tokenAmount),
                "Insufficient balance of presale contract!"
            );
        } else {
            createVestingWallets(
            tokenAmount,
            _msgSender(),
            range,
            _slicePeriod
            );
        }
        tokenSold += tokenAmount;

        usersInvestments[msg.sender] = usersInvestments[msg.sender].add(
            msg.value
        );

        totalEthAmount = totalEthAmount + msg.value;
        totalUSDAmount = totalUSDAmount + _amountInUSD;


        payable(recipient).transfer(msg.value);

        if (totalEthAmount > hardcap) {
            isPresaleOpen = false;
        }
       
    }


    function createVestingWallets(
        uint256 tokenAmount,
        address _userAddress,
        uint256 _totalDays,
        uint256 _slicePeriod
    ) private {

        uint _tokenAmount = (tokenAmount * buyTokenPercentage)/(10**(2+rateDecimals));
        tokenAmount =  tokenAmount - _tokenAmount;

        vestingContract(vestingAddress).createVesting(
            _userAddress,
            _totalDays,
            _slicePeriod,
            tokenAmount
        );

        require(IToken(tokenAddress).transfer(_userAddress, _tokenAmount),
            "Insufficient balance of presale contract!"
        );
        
        require(IToken(tokenAddress).transfer(address(vestingAddress), tokenAmount),
            "Insufficient balance of presale contract!"
        );

    }

    function vestingCreate(uint256 tokenAmount,address _userAddress,uint256 _totalDays,uint256 _slicePeriod) public {

        vestingContract(vestingAddress).createVesting(_userAddress,_totalDays,_slicePeriod,tokenAmount);
        
        IToken(tokenAddress).transferFrom(msg.sender,address(vestingAddress), tokenAmount);

    }

    function getTokens(uint256 _amountInUSD) public view returns(uint256 _pricePerToken, uint256 tokenAmount) {

        uint256 per=0;
        require(_amountInUSD >= pricePerToken[0],"Amount should not be less then minimum amount");

        if(_amountInUSD >= priceBrackets[0] && _amountInUSD <= priceBrackets[1] ){
            per = pricePerToken[0];
        }
        else if(_amountInUSD > priceBrackets[1] && _amountInUSD <= priceBrackets[2] ){
            per = pricePerToken[1];
        }
        else if(_amountInUSD > priceBrackets[2] && _amountInUSD <= priceBrackets[3] ) {
            per = pricePerToken[2];
        }
        else if(_amountInUSD > priceBrackets[3] ){
            per = pricePerToken[3];
        }
        
        return (per, _amountInUSD*10**(tokenDecimals+rateDecimals)/per);

    } 

    function burnUnsoldTokens() external onlyOwnerAndAdmin {
        require(
            !isPresaleOpen,
            "You cannot burn tokens untitl the presale is closed."
        );

        IToken(tokenAddress).burn(
            IToken(tokenAddress).balanceOf(address(this))
        );
    }

    function getUnsoldTokens(address to) external onlyOwnerAndAdmin {
        require(
            !isPresaleOpen,
            "You cannot get tokens until the presale is closed."
        );

        IToken(tokenAddress).transfer(to,IToken(tokenAddress).balanceOf(address(this)));
    
    }

    function getDuration(uint256 amount)
        public
        view
        returns (uint256 range,uint256 _slicePeriod)
    {
      uint256 retrunDuration=0;
      _slicePeriod=0;
    
        if(amount < priceBrackets[0]){
            retrunDuration = 0;
            _slicePeriod=0;
        }
        else if(amount <= priceBrackets[1]){
            retrunDuration = rLockinPeriod[1] ;
            _slicePeriod=retrunDuration/sliceDays;

        }
        else if(amount <= priceBrackets[2]){
            retrunDuration = rLockinPeriod[2] ;
            _slicePeriod=retrunDuration/sliceDays;

        }
        else if(amount <= priceBrackets[3]){
            retrunDuration = rLockinPeriod[3] ;
            _slicePeriod=retrunDuration/sliceDays;

        }
        else if(amount > priceBrackets[3]){
            retrunDuration = rLockinPeriod[4] ;
            _slicePeriod=retrunDuration/sliceDays;

        }
        
        return  (retrunDuration,_slicePeriod);
    }

    function getVestingAddress() external view returns (address){
        return address(vestingAddress);
    }
    
    function setTimeUnit(uint _unit,uint _sliceDays) public onlyOwnerAndAdmin{
        vestingContract(vestingAddress).setTimeUnit(_unit);
        sliceDays = _sliceDays;
    }

    function getTimeUnit() public view returns(uint _timeUnit){
        return vestingContract(vestingAddress).timeUnit();
    }

    function launch() public onlyOwnerAndAdmin {
         vestingContract(vestingAddress).launch();
    }

    function setAdminForpreSale(address _address) public onlyOwnerAndAdmin{
        vestingContract(vestingAddress).setAdmin(_address);
    }

    function getVestingId(address _address) public view returns(uint[] memory){
        return vestingContract(vestingAddress).getVestingIds(_address);
    }

    function getClaimAmount(address _walletAddress,uint256 _vestingId) public view returns(uint _claimAmount) {
        return vestingContract(vestingAddress).getClaimableAmount(_walletAddress,_vestingId);
    }

    function getUserVestingData(address _address,uint256 _vestingId) public view returns(address _owner,
        uint _totalEligible,
		uint _totalClaimed,
		uint _remainingBalTokens,
		uint _lastClaimedAt,
        uint _startTime,
        uint _totalVestingDays,
        uint _slicePeriod ){
        (,_owner,_totalEligible,_totalClaimed,_remainingBalTokens,_lastClaimedAt,_startTime,_totalVestingDays,_slicePeriod) = vestingContract(vestingAddress).userClaimData(_address,_vestingId);
        
    }

}

//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import '@openzeppelin/contracts/utils/Context.sol';
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";


interface IToken {
    function transfer(address to, uint256 tokens)
        external
        returns (bool success);
    
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function burn(uint256 _amount) external;

    function balanceOf(address tokenOwner)
        external
        view
        returns (uint256 balance);

    function decimals() external
        view
        returns (uint256);
}


contract vestingContract {


    using Counters for Counters.Counter;
    using SafeMath for uint256;
    address public token;

    uint256 public timeUnit;
    address public admin;

    mapping(address => uint256[]) vestingIds;
    
    uint256 public listedAt;
    Counters.Counter private _id;

    constructor (address _token,address _admin) {
        admin = _admin;
        timeUnit = 60;
        token = _token;
    }


    struct claimInfo {
        bool initialized;
        address owner;
        uint totalEligible;
		uint totalClaimed;
		uint remainingBalTokens;
		uint lastClaimedAt;
        uint startTime;
        uint totalVestingDays;
        uint slicePeriod;

    }


    modifier onlyAdmin()   {
        require(
            msg.sender == admin,
            "Ownable: caller is not the owner or admin"
        );
        _;
    }

    mapping(address => mapping(uint256 => claimInfo)) public userClaimData; 

    function launch() external  {
        require(admin == msg.sender,"caller is not the admin ");
        require(listedAt == 0, "Already Listed!");
        listedAt = block.timestamp;
    }

    function createVesting (address _creator,uint _totalDays, uint _slicePeriod,uint tokenAmount) public onlyAdmin {
                
        uint256 launchedAt = listedAt;
        uint256 currentTime = getCurrentTime();
        _id.increment();
        
        vestingIds[_creator].push(_id.current());
        
        userClaimData[_creator][_id.current()] = claimInfo({
            initialized:true,
            owner:_creator,
            totalEligible:tokenAmount,
            totalClaimed:0,
            remainingBalTokens:tokenAmount,
            lastClaimedAt:launchedAt,
            startTime:currentTime,
            totalVestingDays:_totalDays,
            slicePeriod:_slicePeriod
        });
        
    }


    function getCurrentTime()internal virtual view
    returns(uint256){
        return block.timestamp;
    }

    function getLaunchedAt() public view returns(uint256 ) {
        return(listedAt);
    }


    function getClaimableAmount(address _walletAddress,uint256 _vestingId) public view returns(uint _claimAmount) {

        if(getLaunchedAt()==0) {
            return 0;
        }

        claimInfo storage userData = userClaimData[_walletAddress][_vestingId];        
        uint256 timeLeft = 0;
        uint slicePeriodSeconds = userData.slicePeriod * timeUnit;
        uint256 claimAmount =0;
        uint256 _amount =0;

        uint256 currentTime = getCurrentTime();
        uint totalEligible = userData.totalEligible;
        uint lastClaimedAt = userData.lastClaimedAt;
        if(getLaunchedAt() !=0 && lastClaimedAt==0){
            if(currentTime>getLaunchedAt()){
            timeLeft = currentTime.sub(getLaunchedAt());
      
            }else{
            timeLeft =  getLaunchedAt().sub(currentTime);
            }

        }else{
            
            if(currentTime>lastClaimedAt){
            timeLeft = currentTime.sub(lastClaimedAt);
      
            }else{
            timeLeft =  lastClaimedAt.sub(currentTime);
            }

        }
        _amount = totalEligible;

        if(timeLeft/slicePeriodSeconds > 0){
            claimAmount = ((_amount*userData.slicePeriod)/userData.totalVestingDays)*(timeLeft/slicePeriodSeconds) ;
        }

        uint _lastReleaseAmount = userData.totalClaimed;

        uint256 temp = _lastReleaseAmount.add(claimAmount);

        if(temp > totalEligible){
            _amount = totalEligible.sub(_lastReleaseAmount);
            return (_amount);
        }
        return (claimAmount);
      
    }

    function claim(address _walletAddress,uint256 _vestingId) public {
        require(getLaunchedAt() != 0,"Not yet launched");
        require(getClaimableAmount(_walletAddress,_vestingId)>0,'Insufficient funds to claims.');
        require( msg.sender==userClaimData[_walletAddress][_vestingId].owner,"You are not the owner");
        uint256 _amount = getClaimableAmount(_walletAddress,_vestingId);
        userClaimData[_walletAddress][_vestingId].totalClaimed += _amount;
        userClaimData[_walletAddress][_vestingId].remainingBalTokens = userClaimData[_walletAddress][_vestingId].totalEligible-userClaimData[_walletAddress][_vestingId].totalClaimed;
        userClaimData[_walletAddress][_vestingId].lastClaimedAt = getCurrentTime();
        IToken(token).transfer(_walletAddress, _amount);
    }


    function setAdmin(address account) external  {
        require(admin == msg.sender,"caller is not the admin ");
        require(account != address(0),"Invalid Address, Address should not be zero");
        admin = account;
    }

    function getVestingIds(address _walletAddress)  
    external view
    returns (uint[] memory)
    {
        return vestingIds[_walletAddress];
    }

    // remove token for admin

    function balance() public view returns(uint256){
        return IToken(token).balanceOf(address(this));
    }

    function removeERC20() public {
        require(admin == msg.sender,"caller is not the admin ");
        IToken(token).transfer(admin,IToken(token).balanceOf(address(this)));
    }


    function setTimeUnit(uint _unit) public onlyAdmin{
        timeUnit = _unit;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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