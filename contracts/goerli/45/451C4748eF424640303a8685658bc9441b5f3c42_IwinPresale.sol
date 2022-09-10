// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract IwinPresale is Ownable {
    using SafeMath for uint256;
    using SafeMath for uint;

    address public rewardWallet;
    IERC20 public sellToken;
    mapping(address => bool) private _whitelist; //

    //pool info
    struct PoolInfo {
        uint id;
        string name;        //Sale name
        uint256 price;      //per 1 ETH value
        uint256 hardCap;    //
        uint256 softCap;    //

        uint256 locked;     // total token locked
        uint256 raised;     // ETH raised
        bool reached;

        uint256 minVal;     //Buy min
        uint256 maxVal;     //Buy max
        uint256 openingTime;
        uint256 closingTime;
    }
    mapping(uint256 => PoolInfo) private _pools;
    uint public poolsLength = 0;

    //User
    struct UserBuy {
        uint pid; //lock buy pool
        uint256 locked; //lock buy pool
        uint256 claimed; //has claim
        uint lastClaim; //lock buy pool
        uint256 raised; //earn calculate earch buy
        uint256 refRaised; //total ref raised
        uint luckyNumber; //total token wined
        bool isWhitelist; //token withdraw
    }
    mapping(address => mapping(uint => UserBuy)) private _buyed;   //user -> poolid -> UserBuyed
    mapping(uint => address[]) public Buyers;   //pool - addr[]

    //Referral:
    struct RefInfo {
        uint pid;
        mapping(address => uint256) raised;
        address[] lookup;
        uint256 total; //total ETH
    }
    
    mapping(address => RefInfo) private _refLogs;                   //user -> referral of user
    address[] public Referrals; //addr has refinfor
    //Reward sale:
    mapping(address => uint256) private _refRewards;                  //amout of ref reward
    address[] public ReferralRewards;
    mapping(address => uint256) private _giveawayRewards;                 //amout of giveaway reward  
    address[] public Giveaways;
    uint256 public releaseReferal = 0;
    uint256 public releaseGiveAway = 0;

    //Setup Vesting:
    struct VestingInfo {
        uint index;
        uint256 openingTime;
        uint256 percent;
    }
    mapping(uint => mapping(uint => VestingInfo)) private _vesting; //pid - index - VestingInfo
    mapping(uint => uint) public vestingLength;

    //percent
    uint256 public apr = 15000;
    uint256 private denominator = 10000;

    //Events:
    event TokensPurchased(
        address indexed beneficiary,
        uint256 value,
        uint256 token,  //buyed
        uint256 poolid,
        uint256 locked, //total locked
        uint256 price,  //
        uint256 hardcap
    );
    event ClaimToken(address indexed beneficiary, uint256 amount);
    event Withdrawtoken(address indexed to, uint256 amount);
    event SetDone(address indexed from, bool result, uint256 value);

    modifier onlySaleOpen(uint256 pid) {
        require(isPoolOpen(pid), "pool not open");
        _;
    }

    function isPoolOpen(uint256 pid) public view returns (bool) {
        return block.timestamp >= _pools[pid].openingTime && block.timestamp <= _pools[pid].closingTime && _pools[pid].hardCap > _pools[pid].raised;
    }

    function getPoolOpen() public view returns (uint) {
        for (uint256 index = 0; index < poolsLength; index++) {
            if (isPoolOpen(index)) { return index + 1; }
        }
        return 0;
    }

    function setToken(address addr) external onlyOwner {
        require(addr != address(0), "token is 0");
        sellToken = IERC20(addr);
    }

    function setRewardWallet(address _rewardWallet) external onlyOwner{
        require(_rewardWallet != address(0), "Zero address");
        rewardWallet = _rewardWallet;
    }

    //
    function importPresale(uint pid, address[] calldata addrs, uint256[] calldata amounts) external onlyOwner{
        for(uint i=0; i< addrs.length; i++){
            if (_buyed[addrs[i]][pid].locked == 0) {
                Buyers[pid].push(addrs[i]);
            }
            _buyed[addrs[i]][pid].locked = _buyed[addrs[i]][pid].locked.add(amounts[i]);
            _buyed[addrs[i]][pid].claimed = 0;
            _buyed[addrs[i]][pid].lastClaim = 0;
        }
    }
    function importRefReward(address[] calldata addrs, uint256[] calldata amounts) external onlyOwner{
        for(uint i=0; i< addrs.length; i++){
            _refRewards[addrs[i]] = _refRewards[addrs[i]].add(amounts[i]);
        }
    }
    function importLuckReward(address[] calldata addrs, uint256[] calldata amounts) external onlyOwner{
        for(uint i=0; i< addrs.length; i++){
            _giveawayRewards[addrs[i]] = _giveawayRewards[addrs[i]].add(amounts[i]);
        }
    }

    function setReferalTime(uint256 _time) external onlyOwner {
        releaseReferal = _time;
    } 
    function setGiveawayTime(uint256 _time) external onlyOwner {
        releaseGiveAway = _time;
    } 

    function setPool(uint256 pid, string memory name, uint256 price, uint256 hardCap, uint256 softCap, uint256 minUserCap, uint256 maxUserCap, uint256 openingTime, uint256 closingTime) external onlyOwner {
        require(price > 0, "token price is 0");
        require(closingTime > openingTime, "opening is not before closing");
        if (_pools[pid].price == 0) {
            poolsLength++;
        }
        _pools[pid].id = pid;
        _pools[pid].name = name;
        _pools[pid].hardCap = hardCap;
        _pools[pid].softCap = softCap;
        _pools[pid].price = price;
        _pools[pid].minVal = minUserCap;
        _pools[pid].maxVal = maxUserCap;
        _pools[pid].openingTime = openingTime;
        _pools[pid].closingTime = closingTime;
    }

    function setPoolsLength(uint _max) external onlyOwner {
        poolsLength = _max;
    }

    function setPoolReached(uint pid, bool _reached) external onlyOwner {
        _pools[pid].reached = _reached;
    }

    function getPool(uint pid) public view returns (PoolInfo memory) {
        return _pools[pid];
    }

    function isWhitelist(address addr) public view returns (bool) {
        return _whitelist[addr];
    }

    function setWhitelist(address addr, bool val) external onlyOwner {
        require(addr != address(0), "addr is 0");
        _whitelist[addr] = val;
    }

    function addWhitelist(address addr) external {
        _whitelist[addr] = true;
    }

    receive() external payable{
        uint poolid = getPoolOpen();
        require(poolid > 0, "all pool has closed");
        if(msg.value > 0){
            buyToken(poolid - 1, address(0), block.timestamp % 1000);
        }
    }   
     
    function withdrawToken(address _to, uint256 _amount) external onlyOwner {
        require(sellToken.balanceOf(address(this)) >= _amount, "Not enough token");
        require(_to != address(0), "Destination is 0");
        sellToken.transfer(_to, _amount);
        emit SetDone(_to, true, _amount);(_to, _amount);
    }

    function withdrawReward(uint256 _amount) external onlyOwner {
        require(sellToken.balanceOf(address(this)) >= _amount, "Not enough token");
        sellToken.transfer(msg.sender, _amount);
        emit SetDone(msg.sender, true, _amount);
    }

    function withdrawRewardTo(address _to, uint256 _amount) external onlyOwner {
        require(sellToken.balanceOf(address(this)) >= _amount, "Not enough token");
        require(_to != address(0), "Destination is 0");
        sellToken.transferFrom(rewardWallet, msg.sender, _amount);
        emit SetDone(_to, true, _amount);
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    struct RefView {
        address addr;
        uint256 raised; //total ETH
    }
    function getRefUser(address addr) public view returns (RefView[] memory) {
        uint count = _refLogs[addr].lookup.length;
        RefView[] memory ret = new RefView[](count);
        for (uint256 i = 0; i < count; i++) {
            ret[i].addr = _refLogs[addr].lookup[i];
            ret[i].raised = _refLogs[addr].raised[_refLogs[addr].lookup[i]];
        }
        return ret;
    }

    function getReferralReward(address account) public view returns (uint256) {
        return _refRewards[account];
    }

    function getGiveawayReward(address account) public view returns (uint256) {
        return _giveawayRewards[account];
    }

    function giveawayRewards() public view returns (address[] memory) {
        return Giveaways;
    }

    function referralRewards() public view returns (address[] memory) {
        return ReferralRewards;
    }

    function _preValidatePurchase(uint256 pid, address beneficiary, uint256 weiAmount) internal virtual onlySaleOpen(pid) {
        require(beneficiary != address(0), "beneficiary is the zero address");
        require(weiAmount > 0, "weiAmount is 0");
        require(_pools[pid].reached == false, "Hardcap reached");
        require(weiAmount >= _pools[pid].minVal, "cap minimal required");
    }

    function buyToken(uint256 pid, address refaddr, uint ln) public payable {
        address beneficiary = _msgSender();
        uint256 weiAmount = msg.value;
        _preValidatePurchase(pid, beneficiary, weiAmount);
        //POOL
        uint256 tokenAmount = weiAmount.mul(_pools[pid].price).div(10**18);
        _pools[pid].raised = _pools[pid].raised.add(weiAmount);
        _pools[pid].locked = _pools[pid].locked.add(tokenAmount);
        if (_pools[pid].raised.add(weiAmount) >= _pools[pid].hardCap) {
            _pools[pid].reached == true;
        }
        //LOOKUP 
        if (_buyed[beneficiary][pid].raised == 0) {
            Buyers[pid].push(beneficiary);
        }
        //USER
        _buyed[beneficiary][pid].pid = pid;
        _buyed[beneficiary][pid].luckyNumber = ln;
        _buyed[beneficiary][pid].isWhitelist = _whitelist[beneficiary];
        _buyed[beneficiary][pid].raised = _buyed[beneficiary][pid].raised.add(weiAmount);
        _buyed[beneficiary][pid].locked = _buyed[beneficiary][pid].locked.add(tokenAmount);
        //REF USER:
        if (refaddr != address(0)) {
            if (_refLogs[refaddr].total > 0) {
                Referrals.push(refaddr);
            }
            //total ref:
            _buyed[refaddr][pid].refRaised = _buyed[refaddr][pid].refRaised.add(weiAmount);
            //log ref
            _refLogs[refaddr].pid = pid;
            if (_refLogs[refaddr].raised[beneficiary] == 0) {
                _refLogs[refaddr].lookup.push(beneficiary); 
            }
            _refLogs[refaddr].raised[beneficiary] = _refLogs[refaddr].raised[beneficiary].add(weiAmount); 
            _refLogs[refaddr].total = _refLogs[refaddr].total.add(weiAmount);
            //earn ref
            
        }
        emit TokensPurchased(beneficiary, weiAmount, tokenAmount, pid, _pools[pid].locked, _pools[pid].price, _pools[pid].hardCap);
    }

    function getBuyInfo(uint pid, address account) public view returns (UserBuy memory) {
        return _buyed[account][pid];
    }

    //amount per pool can claim locked token (msg, until, amount, reward)
    function checkClaim(uint pid, address holder) public view returns(string memory mss, uint time, uint256 amount, uint256 reward){
        //not buyer
        if(_buyed[holder][pid].locked == 0) {
            return ("Locked is zero", 0, 0, 0);
        }
        //stake time
        ( ,uint256 _reward) = rewardAmount(pid, holder);
        //before release time
        if(block.timestamp < _vesting[pid][0].openingTime){
            return ("Claim on ", _vesting[pid][0].openingTime, _buyed[holder][pid].locked.mul(_vesting[pid][0].percent).div(denominator), _reward);
        }
        // release all
        if (block.timestamp >= _vesting[pid][vestingLength[pid] - 1].openingTime){
            return ("Released", 0,  _buyed[holder][pid].locked.sub( _buyed[holder][pid].claimed), _reward);
        }
        //in
        uint _time = 0;
        uint256 percent = 0;
        uint256 toclaim = 0;
        for (uint256 i = 0; i < vestingLength[pid]; i++) {
            if(block.timestamp < _vesting[pid][i].openingTime){
                _time = _vesting[pid][i].openingTime;
                break;
            }
            percent = percent + _vesting[pid][i].percent;
            toclaim = _buyed[holder][pid].locked;
            toclaim = toclaim.mul(percent).div(denominator);
        }
        if (toclaim.sub(_buyed[holder][pid].claimed) > 0) {
            return ("Claim amount ", 0, toclaim.sub(_buyed[holder][pid].claimed), _reward);
        }
        return ("Claim on ", _time, 0, _reward);
    }

    //reward staking 
    function rewardAmount(uint pid, address holder) public view returns(uint, uint256){
        uint256 amount = _buyed[holder][pid].locked.sub(_buyed[holder][pid].claimed);
        if(amount == 0){
            return (0, 0);
        }
        uint timeElapsed;
        if(_buyed[holder][pid].lastClaim != 0){
            timeElapsed = block.timestamp - _buyed[holder][pid].lastClaim;
        }else{
            if (_vesting[pid][0].openingTime >= block.timestamp) {
                timeElapsed = 0;
            } else {
                timeElapsed = block.timestamp - _vesting[pid][0].openingTime;
            }
        }
        uint256 reward = amount.mul(timeElapsed).div(365 days).mul(apr).div(denominator);
        return (timeElapsed, reward);
    }

    function claim(uint pid) external{
        ( , ,uint256 _amount, uint256 reward) = checkClaim(pid, msg.sender);
        require(_amount > 0, "Nothing to claim");
        require(sellToken.balanceOf(address(this)) >= _amount, "Pre-Sale not enough token");
        if(_amount > 0){
            // reward stake
            //(,uint256 reward) = rewardAmount(pid, msg.sender);
            if(reward > 0){
                require(sellToken.balanceOf(rewardWallet) >= _amount, "rewardWallet not enough token");
                sellToken.transferFrom(rewardWallet, msg.sender, reward);
            }
        }
        _buyed[msg.sender][pid].lastClaim = block.timestamp;
        _buyed[msg.sender][pid].claimed = _buyed[msg.sender][pid].claimed.add(_amount);
        sellToken.transfer(msg.sender, _amount);
        emit ClaimToken(msg.sender, _amount);
    }

    function luckyNumber(uint pid, address _wallet) public view returns(uint) {
        return _buyed[_wallet][pid].luckyNumber;
    }

    function setAPR(uint _apr) external onlyOwner{
        apr = _apr;
    }
    function getAPR() public view returns(uint256){
        return apr;
    }

    function getLookupLength(uint256 pid) public view returns(uint256){
        return Buyers[pid].length;
    }

    function getBuyerByIndex(uint256 pid, uint256 idx) public view returns(address){
        return Buyers[pid][idx];
    }

    function getReleaseTime(uint pid) public view returns(uint256) {
        return _vesting[pid][0].openingTime;
    }

    //
    function setVesting(uint pid, uint _index, uint256 _time, uint256 _vestpercent) external onlyOwner{
        if (_vesting[pid][_index].percent == 0) {
            vestingLength[pid]++;
        }
        _vesting[pid][_index].index = _index;
        _vesting[pid][_index].openingTime = _time;
        _vesting[pid][_index].percent = _vestpercent;
    }

    function setVestings(uint _index, uint256 _time, uint256 _vestpercent) external onlyOwner{
        for (uint256 i = 0; i < poolsLength; i++) {
            if (_vesting[i][_index].percent == 0) {
                vestingLength[i]++;
            }
            _vesting[i][_index].index = _index;
            _vesting[i][_index].openingTime = _time;
            _vesting[i][_index].percent = _vestpercent;
        }
    }

    function getVesting(uint pid, uint _index) public view returns(VestingInfo memory) {
        return _vesting[pid][_index];
    }

    function setVestingLength(uint pid, uint _length) external onlyOwner{
        vestingLength[pid] = _length;
    }

    function getVestingLength(uint pid) public view returns(uint) {
        return vestingLength[pid];
    }

    function governanceRecoverUnsupported(IERC20 _token, uint256 _amount, address _to) external onlyOwner {
        _token.transfer(_to, _amount);
    }
}

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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