/**
 *Submitted for verification at Etherscan.io on 2022-04-07
*/

// File: @openzeppelin/contracts/math/SafeMath.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// File: contracts/interfaces/IGenIDOFactory.sol

pragma solidity >=0.5.0;

interface IGenIDOFactory {
    event IDOCreated(address indexed caller, address indexed genIDO);

    // function feeTo() external view returns (address);
    // function feeToSetter() external view returns (address);

    function getGenIDO(address) external view returns (uint);
    function genIDO(uint) external view returns (address);
    function genIDOLength() external view returns (uint);

    function createGenIDO(
        address _underlyingToken,//18
        uint256 _totalTokenAllocation,//50k//decimal will depend on _underlyingToken decimals
        address _usdt,//6
        uint256[] memory _maxAllocPerUserPerTier,//18//in wei[975.6,731.7,487.8,243.9]//usd//6
        uint256[] memory _numApplicantsPerTier,//will get from frontend[25,40,55,80]
        uint[] memory _trancheWeightage,//in wei//18 always
        uint[] memory _trancheLength,//in seconds always
        uint256 _maxClaimPercentage,//eg 5% in wei 5000000000000000000//18
        uint256 _tokenPerUsd//wei always
    ) external returns (address);

    // function setFeeTo(address) external;
    // function setFeeToSetter(address) external;
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

 
pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
}

// File: contracts/GenIDO.sol

pragma solidity 0.6.12;



//import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

pragma experimental ABIEncoderV2;

abstract contract IERC20Extented is IERC20 {
    function decimals() public virtual view returns (uint8);
}

contract GenIDO {
    using SafeMath for uint;

    IERC20Extented public underlyingToken;
    IERC20Extented public usdt;

    uint256[] private trancheLength;
    uint256[] private trancheWeightage;
    uint256[] private numApplicantsPerTier;
    uint256[] public maxAllocPerUserPerTier;
    IGenIDOFactory public factory;
    address public issuer;
    // for IDO to be active for sale
    bool public active = false;
    bool public enableFcfsSale = false;
    // Expected TGE timestamp, start at max uint256
    uint public TGE = type(uint).max;

    mapping(address => bool) public blacklist;

    uint256 public totalTokenAllocation;
    uint256 public totalUsdtAllocation;

    uint256 public minAllocationPermitted;
    uint256 public maxAllocationPermitted;

    uint256 private tokensPurchased;

    uint256 public tokenPerUsd;

    struct WhitelistDetails{
        bool isWhitelisted;
        uint256 id;
    }

    mapping(address => uint256) private  guaranteedTier;

    uint public startTime = type(uint).max;

    struct Purchases{
        uint256 paymentDone;//usd
        uint256 allocationBought;//tokens respective to payment
        uint256 allocationRemaining;//tokens remaining after each tranch claim 
        uint256 position;
    }

    struct GuranteedInfo{
        address addr;
        uint256 pay;
        uint256 id;
    }
    GuranteedInfo[] private guranteedInfo;

    struct ParticipantsInfo{
        address addr;
        uint256 pay;
    }
    ParticipantsInfo[] private participantsInfo;

    mapping(address => Purchases) public purchases;

    bytes private constant VALIDATOR = bytes('AS');

    address[] private participants;
    address[] private guranteedParticipants;
    address[] private blacklistedAddresses;

    uint256 private tokenDec;
    uint256 private usdDec;

    constructor (
        address _underlyingToken,//18
        uint256 _totalTokenAllocation,//50k//decimal will depend on _underlyingToken decimals
        address _usdt,//6
        uint256[] memory _maxAllocPerUserPerTier,//18//in wei[975.6,731.7,487.8,243.9]//usd//6
        uint256[] memory _numApplicantsPerTier,//will get from frontend[25,40,55,80]
        uint[] memory _trancheWeightage,//in wei//18 always
        uint[] memory _trancheLength,//in seconds always
        uint256 _maxClaimPercentage,//eg 5% in wei 5000000000000000000//18
        uint256 _tokenPerUsd,//wei always
        IGenIDOFactory _factory,
        address _issuer
    ) 
        public 
    {
        underlyingToken = IERC20Extented(_underlyingToken);//decimal format of underlying token
        totalTokenAllocation = _totalTokenAllocation;//same as above
        usdt = IERC20Extented(_usdt);//decimal format of usd token
        maxAllocPerUserPerTier = _maxAllocPerUserPerTier;//decimal format of usd token
        numApplicantsPerTier = _numApplicantsPerTier;
        trancheWeightage = _trancheWeightage;//wei
        trancheLength = _trancheLength;//seconds
        tokenPerUsd = _tokenPerUsd;//wei
        factory = _factory;
        issuer = _issuer;

        tokenDec = underlyingToken.decimals();
        usdDec = usdt.decimals();

         for (uint i = 0; i < 50; i++){
            if (maxAllocPerUserPerTier.length == i){
                break;
            }
            
            totalUsdtAllocation += _numApplicantsPerTier[i].mul(_maxAllocPerUserPerTier[i]);
        }

        minAllocationPermitted = maxAllocPerUserPerTier[maxAllocPerUserPerTier.length -1]/2;
        maxAllocationPermitted = totalUsdtAllocation.mul(_maxClaimPercentage).div(10**18).div(100);

        require(maxAllocationPermitted >= minAllocationPermitted, "GenIDO: Max allocation allowed should be greater or equal to min allocation");

    }

    function returnTrancheLength() public view returns (uint256[] memory) {
        return (trancheLength);
    }
    function returnTrancheWeightage() public view returns (uint256[] memory) {
        return (trancheWeightage);
    }

    function updateTGE(uint timestamp) external {
        require(msg.sender == issuer, "GenIDO: Only issuer can update TGE");
        require(getBlockTimestamp() < TGE, "GenIDO: TGE already occurred");
        require(getBlockTimestamp() < timestamp, "GenIDO: New TGE must be in the future");
        // Determine whether we want to restrict this or not
        //require(!active, "Tokens are already active");

        TGE = timestamp;
    }

    // first deposit underlying tokens to contract
    function depositTokens() external {
        require(msg.sender == issuer, "GenIDO: Only issuer can deposit tokens to the contract");
        require(!active, "GenIDO: Token is already active");
        require(IERC20(underlyingToken).balanceOf(msg.sender) >= totalTokenAllocation, "GenFactory: The underlying tokens attempted to lock is more than the balance");//18

        IERC20(underlyingToken).transferFrom(msg.sender, address(this), totalTokenAllocation);//18

        active = true;
    }

    // This methods allows issuer to deposit tokens anytime - even after TGE
    function submitTokens(uint256 _amount) external {
        require(msg.sender == issuer, "GenIDO: Only issuer can deposit tokens to the contract");
        require(IERC20(underlyingToken).balanceOf(msg.sender) >= _amount, "GenFactory: The underlying tokens attempted to lock is more than the balance");

        IERC20(underlyingToken).transferFrom(msg.sender, address(this), _amount);
    }

    function updateStartTime(uint timestamp) external {
        require(msg.sender == issuer, "GenIDO: Only creator can update start time");
        require(getBlockTimestamp() < startTime, "GenIDO: Start time already occurred");
        require(getBlockTimestamp() < timestamp, "GenIDO: New start time must be in the future");

        startTime = timestamp;
    }

    function flipFCFSStatus() external {
        require(msg.sender == issuer, "GenIDO: Only the issuer can enable the fcfs sale");
        enableFcfsSale = !enableFcfsSale;
    }

    function flipIDOStatus() external {
        require(msg.sender == issuer, "GenIDO: Only the issuer can flip the ido active status");
        active = !active;
    }

    // Buying from contract directly might lead to the loss of busd submitted//what if usdt or busd? 6 decimal?18 dec?
    function buyAnAllocation(uint256 _pay, uint256 _staked) external {
        require(_pay > 0, "GenIDO: Payment cannot be zero");
        require(active, "GenIDO: Market is not active");
        require(getBlockTimestamp() >= startTime, "GenTks: Start time must pass");
        require(tokensPurchased.add(((_pay.mul(tokenPerUsd)).div(10**18)).mul(10**tokenDec).div(10**usdDec)) <= totalTokenAllocation, "GenIDO: Sold Out");//18

        uint256 id;//id needed for guranteed participants
        if (_staked >= 30000 * 10**18){
            id =0;
        } else if (_staked >= 15000 * 10**18 && _staked < 30000 * 10**18){
            id =1;
        } else if(_staked >= 7500 * 10**18 && _staked < 15000 * 10**18){
            id =2;
        } else if(_staked >= 2000 * 10**18 && _staked < 7500 * 10**18){
            id =3;
        } else{
            require(true, "GenIDO: Invalid User");
        }

        require((purchases[msg.sender].paymentDone).add(_pay) >= minAllocationPermitted , "Genztk: User min purchase violation");//6
        // only for guranteed sale
        if (!enableFcfsSale){//false
            require((purchases[msg.sender].paymentDone).add(_pay) <= maxAllocPerUserPerTier[id], "Genztk: User max purchase violation");//6
            if ((purchases[msg.sender].paymentDone) < minAllocationPermitted){//to check if at least bought some allocation as guranteed user
                guranteedParticipants.push(msg.sender);
                 guaranteedTier[msg.sender] = id;
            }
            GuranteedInfo memory newInfo = GuranteedInfo({
                    addr: msg.sender,
                    pay: _pay,
                    id: id
                });
            guranteedInfo.push(newInfo);
        }
        require(purchases[msg.sender].paymentDone.add(_pay) <= maxAllocationPermitted, "GenIDO: Max Purchase Limit Reached");//6

        if ((purchases[msg.sender].paymentDone) < minAllocationPermitted){
            participants.push(msg.sender);
        }
        ParticipantsInfo memory newInfo = ParticipantsInfo({
            addr: msg.sender,
            pay: _pay
        });
        participantsInfo.push(newInfo);   
        
        purchases[msg.sender].paymentDone += _pay;//this will keep track of who purchased how much in usd?
        purchases[msg.sender].allocationBought += (_pay.mul(tokenPerUsd).div(10**18)).mul(10**tokenDec).div(10**usdDec);//to keep track of token holdings per user//?
        purchases[msg.sender].allocationRemaining = purchases[msg.sender].allocationBought;//6//tokensBought/??

        tokensPurchased += (_pay.mul(tokenPerUsd).div(10**18)).mul(10**tokenDec).div(10**usdDec);

        // payment made by User
        usdt.transferFrom(msg.sender, address(this), _pay);
    }

    // returns total balance of the contract
    function getContractBalance() public view returns (uint256 usdBalance, uint256 tokenBalance){
        usdBalance = usdt.balanceOf(address(this));
        tokenBalance = underlyingToken.balanceOf(address(this));
    }

    function getTokensSold() public view returns (uint256 tokensSold) {
         tokensSold = tokensPurchased;
    }

    function getAmountRaised() public view returns (uint256 amountRaised) {
        amountRaised = ((tokensPurchased.mul(10**18)).div(tokenPerUsd)).mul(10**usdDec).div(10**tokenDec);
    }

    function getWinnerCounts() public view returns(uint256[] memory _numApplicantsPerTier){
        return numApplicantsPerTier;
    }

    function getGuranteedParticipants() public view returns(address[] memory allGuranteedParticipants){
        return (guranteedParticipants);
    }

    function getGuranteedDetails() public view returns (GuranteedInfo[] memory){
        return guranteedInfo;
    }

    function getParticipantsDetails() public view returns (ParticipantsInfo[] memory){
        return participantsInfo;
    }

    function getAllParticipants() public view returns(address[] memory allParticipants){
        return (participants);
    }

    function getAllBlacklistedAddresses() public view returns(address[] memory allBlacklistedAddresses){
        return blacklistedAddresses;
    }

    //issuer's responsibility to decide on claim amount - in case of blacklisted user or any emergency case
    function claimTokens(uint256 _amount) external {
        require (_amount <= underlyingToken.balanceOf(address(this)), "Invalid claim amount");
        underlyingToken.transfer(issuer, _amount);
    }

    //for users who bought from contract rather than web app
    function setBlackList(address[] memory addresses, bool blackListOn) external {
        require(msg.sender == issuer, "GenIDO: Only issuer can update blacklist");
        require(addresses.length < 200, "GenIDO: Blacklist less than 200 at a time");

        for (uint8 i=0; i<200; i++) {
            if (i == addresses.length) {
                break;
            }

            blacklist[addresses[i]] = blackListOn;
            blacklistedAddresses.push(addresses[i]);
        }
    }

    function redeem(address _to) public {
        require(!blacklist[msg.sender], "GenIDO: User in blacklist");
        require(purchases[msg.sender].paymentDone > maxAllocPerUserPerTier[maxAllocPerUserPerTier.length - 1]/2, "GenIDO: Invalid Claim");
        require(getBlockTimestamp() > TGE, "GenIDO: Project TGE not occured");

        uint256 redeemablePercentage;
        uint256 redeemedPercentage;
        uint256 redeemableCounter;
        uint256 redeemedCounter;

        uint tranche = purchases[msg.sender].position;
        
        require(purchases[msg.sender].allocationRemaining > 0, "GenIDO: Ticket has redeemed all tokens");
        require(purchases[msg.sender].position < trancheLength.length, "GenIDO: All tranches fully claimed");        

        for (uint i=0; i< trancheLength.length ; i++){
            
            if (i < tranche ){
                redeemedPercentage += (trancheWeightage[i].div(10**14));
                redeemedCounter += 1;
            }

            if (TGE.add(trancheLength[i]) <= getBlockTimestamp()){
                redeemablePercentage += (trancheWeightage[i].div(10**14));
                redeemableCounter += 1;
            } else{
                break;
            }
        }
        require(redeemablePercentage > 0, "GenIDO: zero amount cannot be claimed");
        require(redeemableCounter > redeemedCounter, "GenIDO: Tokens for this ticket are being vested");

        uint256 tokens = (purchases[msg.sender].allocationBought).mul(redeemablePercentage - redeemedPercentage).div(1000000);

        // Transfer underlying tokens with corresponding size or allocation bought
        IERC20(underlyingToken).transfer(_to, tokens);
        purchases[msg.sender].allocationRemaining -= tokens;
        purchases[msg.sender].position += redeemableCounter;
    }

    //usd claim proceeds
    function claimProceeds() external {
        require(msg.sender == issuer, "GenIDO: Only the creator can claim");
        require (usdt.balanceOf(address(this)) > 0, "No balance to transfer");

        usdt.transfer(msg.sender, usdt.balanceOf(address(this)));
    }

    function getBlockTimestamp() internal view returns (uint) {
        // solium-disable-next-line security/no-block-members
        return block.timestamp;
    }

}

// File: contracts/GenIDOFactory.sol

pragma solidity 0.6.12;





contract GenIDOFactory is IGenIDOFactory {
    using SafeMath for uint;

    address[] public override genIDO;
    
    mapping(address => uint) public override getGenIDO;
    
    event IDOCreated(address indexed caller, address indexed genIDO);
    
    function genIDOLength() external override view returns (uint) {
        return genIDO.length;
    }

    function createGenIDO(
        address _underlyingToken,//18
        uint256 _totalTokenAllocation,//50k//decimal will depend on _underlyingToken decimals
        address _usdt,//6
        uint256[] memory _maxAllocPerUserPerTier,//18//in wei[975.6,731.7,487.8,243.9]//usd//6
        uint256[] memory _numApplicantsPerTier,//will get from frontend[25,40,55,80]
        uint[] memory _trancheWeightage,//in wei//18 always
        uint[] memory _trancheLength,//in seconds always
        uint256 _maxClaimPercentage,//eg 5% in wei 5000000000000000000//18
        uint256 _tokenPerUsd//wei always

    )  external override returns (address) {
        require(_numApplicantsPerTier.length < 10, 'GenFactory: MAX NUMBER OF TIERS');
        require(_numApplicantsPerTier.length == _maxAllocPerUserPerTier.length && _trancheWeightage.length == _trancheLength.length, 'GenFactory: ARRAY SIZE MISMATCH');

        // A check for underlying tokens in the issuer's wallet be greater or equal to the amount supplied
        require(IERC20(_underlyingToken).balanceOf(msg.sender) >= _totalTokenAllocation, "GenFactory: The underlying tokens attempted to lock is more than the balance");

        //address issuer = msg.sender;
        GenIDO gd = new GenIDO(_underlyingToken, _totalTokenAllocation, _usdt, _maxAllocPerUserPerTier, _numApplicantsPerTier, _trancheWeightage, _trancheLength, _maxClaimPercentage, _tokenPerUsd, this, msg.sender);
        // Populate mapping
        getGenIDO[address(gd)] = genIDO.length;
        // Add to list
        genIDO.push(address(gd));
        emit IDOCreated(msg.sender, address(gd));
        
        return address(gd);
    }
    
}