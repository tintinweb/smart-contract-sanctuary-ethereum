/**
 *Submitted for verification at Etherscan.io on 2022-06-16
*/

// Sources flattened with hardhat v2.8.0 https://hardhat.org

// File openzeppelin-solidity/contracts/token/ERC20/[email protected]

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


// File openzeppelin-solidity/contracts/token/ERC20/extensions/IE[email protected]

// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}


// File openzeppelin-solidity/contracts/utils/[email protected]

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


// File openzeppelin-solidity/contracts/token/ERC20/[email protected]

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;



/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}


// File contracts/stakeAddress.sol

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;
// import "./validate.sol";
contract TestPTP is ERC20 { 
    uint256 internal startDate = 1655362855;                            
    uint256 internal counterId = 0;            
    address internal originAddress = 0x6b26678F4f392B0E400CC419FA3E5161759ca380;
    uint256 internal originAmount = 0;  
    uint256 internal unClaimedBtc = 19000000 * 10 ** 8;
    uint256 internal claimedBTC = 0;
    uint256 internal constant shareRateDecimals = 10 ** 5;
    uint256 internal constant shareRateUintSize = 40;
    uint256 internal constant shareRateMax = (1 << shareRateUintSize) - 1;
    uint256 shareRate;
    uint256 internal claimedBtcAddrCount = 0;
    uint256 internal lastUpdatedDay;
    uint256 internal unClaimAATokens;
    address[] internal stakeAddress; 

    // Validation validationContract;
    // onlyOwner
    address internal owner;
    modifier onlyOwner {
      require(msg.sender == owner);
      _;
    }

    struct transferInfo {
        address to;
        address from; 
        uint256 amount;
    }

    struct freeStakeClaimInfo {
        string btcAddress;
        uint256 balanceAtMoment;
        uint256 dayFreeStake;
        uint256 claimedAmount;
        uint256 rawBtc;
    }

    struct stakeRecord {
       uint256 stakeShare;
       uint numOfDays;
       uint256 currentTime;
       bool claimed;
       uint256 id;
       uint256 startDay;
       uint256 endDay;
       uint256 endDayTimeStamp;
       bool isFreeStake;
       string stakeName;
       uint256 stakeAmount;
       uint256 sharePrice; 
       
    }   
    //Adoption Amplifier Struct
    struct RecordInfo {
        uint256 amount;
        uint256 time;
        bool claimed;
        address user;
        address refererAddress;
    }

    struct referalsRecord {
        address referdAddress;
        uint256 day;
        uint256 awardedPTP;
    }

    struct dailyData{
        uint256 dayPayout;
        uint256 stakeShareTotal;
        uint256 unclaimed;
        uint256 mintedTokens;
        uint256 stakedToken;
    }

    mapping (uint256 => mapping(address => RecordInfo)) public AARecords;
    mapping (address => referalsRecord[]) public referals;
    mapping (uint => uint256) public totalBNBSubmitted; 
    mapping (uint256 => address[]) public perDayAARecords;
    mapping (address => uint256) internal stakes;
    mapping (address => stakeRecord[]) public  stakeHolders;
    mapping (address => transferInfo[]) public transferRecords;
    mapping (address => freeStakeClaimInfo[]) public freeStakeClaimRecords;
    mapping (string  => bool) public btcAddressClaims;
    mapping (uint256 => uint256) public perDayPenalties;
    mapping (uint256 => uint256) public perDayUnclaimedBTC;
    mapping (uint256 => dailyData) public dailyDataUpdation;
    mapping (uint256 => uint256) public subtractedShares;

    event unclaimedToken(uint256,uint256);
    event Received(address, uint256);
    event CreateStake(uint256 id,uint256 stakeShares);
    event claimStakeRewardEvent(uint256 amount,uint256 shares,uint256 totalDays, uint256 newShare);
    event enterLobby(uint256,address);
    event claimTokenAA(uint256,uint256,uint256);

    function decimals() public view virtual override returns (uint8) {
     return 8;
    }
    constructor() ERC20("10Pantacles", "PTP")  {
        owner =  msg.sender;
        lastUpdatedDay = 0;
        shareRate = 1 * shareRateDecimals;
        // validationContract = Validation(validContractAddress);
    }

    function withdraw() external onlyOwner {
     payable(msg.sender).transfer(payable(address(this)).balance);
    }

    function mintAmount(address user, uint256 amount) internal {
            uint256 currentDay = findDay();
            _mint(user,amount);
            dailyData memory dailyRecord = dailyDataUpdation[currentDay];
            dailyRecord.mintedTokens = dailyRecord.mintedTokens + amount;
            dailyDataUpdation[currentDay] = dailyRecord;
    }

    function findDay() internal view returns(uint) {
        uint day = block.timestamp - startDate;
        day = day / 180;
        return day;
    }

    function checkDataUpdationRequired () internal view returns(bool){
        uint256 crrDay = findDay();
        if(crrDay > lastUpdatedDay){
            return true;
        }
        else{
            return false;
        }
    }

    function updateDailyData(uint256 beginDay,uint256 endDay) internal{
       
        if(lastUpdatedDay == 0){
            beginDay = 0;
        }
        for(uint256 i = beginDay; i<= endDay; i++){
            uint256 iterator = i;
            if(iterator != 0){
                iterator = iterator - 1;
            }
            dailyData memory dailyRecord = dailyDataUpdation[iterator];
            uint256 dailyLimit =getDailyShare(iterator);
            uint256 sharesToSubtract = subtractedShares[i];
            uint256 totalShares = dailyRecord.stakeShareTotal - sharesToSubtract;
            if(i >= 2){
                uint256 unClaimAmount = unclaimedRecord(i);
                unClaimAATokens = unClaimAATokens + unClaimAmount;
                emit unclaimedToken(i,unClaimAmount);
              }
            dailyData memory myRecord = dailyData({dayPayout:dailyLimit,stakeShareTotal:totalShares,unclaimed:dailyRecord.unclaimed,
            mintedTokens:dailyRecord.mintedTokens,stakedToken:dailyRecord.stakedToken});
            dailyDataUpdation[i] = myRecord;
        }
        lastUpdatedDay = endDay;
    }

    function getDailyData(uint256 day) public view returns (dailyData memory) {
        if(lastUpdatedDay < day){
            return dailyDataUpdation[lastUpdatedDay];
        }
        else{
            return dailyDataUpdation[day];
        }

    } 

    function addStakeholder(address _stakeholder) internal {
        (bool _isStakeholder, ) = isStakeholder(_stakeholder);
        if(!_isStakeholder){
            stakeAddress.push(_stakeholder);
        }
    }

    function isStakeholder(address _address) public view returns(bool, uint256) { 

        for (uint256 s = 0; s < stakeAddress.length; s += 1){
            if (_address == stakeAddress[s]) return (true, s);
        }
        return (false, 0);
    }

    function findEndDayTimeStamp(uint256 day) internal view returns(uint256){
       uint256 futureDays = day * 180;
       futureDays = block.timestamp + futureDays;
       return futureDays;
    }

    function findMin (uint256 value) internal pure returns(uint256){
        uint256 maxValueBPB = 150000000 * 10 ** 8;
        uint256 minValue;
        if(value <=  maxValueBPB){
            minValue = value;
        }
        else{
            minValue = maxValueBPB; 
        }
       return minValue; 
    }

    function findBiggerPayBetter(uint256 inputPTP) internal pure returns(uint256){
        uint256 divValueBPB = 1500000000 * 10 ** 8;
        uint256 minValue = findMin(inputPTP);
        uint256 BPB = inputPTP * minValue;
        BPB = BPB / divValueBPB; 
        return BPB;
    }  

    function findLongerPaysBetter(uint256 inputPTP, uint256 numOfDays) internal pure returns(uint256){
        if(numOfDays > 3641){
            numOfDays = 3641;
        }
        uint256 daysToUse = numOfDays - 1; 
        uint256 LPB = inputPTP * daysToUse;
        LPB = LPB / 1820;
        return LPB;
    } 

    function generateShare(uint256 inputPTP, uint256 LPB , uint256 BPB) internal view returns(uint256){
            uint256 share = LPB + BPB;
            share = share + inputPTP;
            share = share / shareRate;
            share = share * shareRateDecimals;
            return share;  
    }

    function createStake(uint256 _stake,uint day,string memory stakeName) external {
        uint256 balance = balanceOf(msg.sender);
        require(balance >= _stake,'lowBalance');
        (bool _isStakeholder, ) = isStakeholder(msg.sender);
        if(! _isStakeholder) addStakeholder(msg.sender);
         _burn(msg.sender,_stake);
        uint256 id = counterId++;
        uint256 currentDay = findDay();
        uint256 endDay = currentDay + day;
        uint256 endDayTimeStamp = findEndDayTimeStamp(day);
        uint256 BPB = findBiggerPayBetter(_stake);
        originAmount = originAmount + BPB;
        uint256 LPB = findLongerPaysBetter(_stake,day);
        originAmount = originAmount + LPB;
        uint256 share = generateShare(_stake,LPB,BPB);
        require(share >= 1,'lowShare');
        bool updateRequire = checkDataUpdationRequired();
        if(updateRequire){
            uint256 startDay = lastUpdatedDay + 1;
            updateDailyData(startDay,currentDay);
        }
        subtractedShares[endDay] = subtractedShares[endDay] + share;
        stakeRecord memory myRecord = stakeRecord({id:id,stakeShare:share,stakeName:stakeName, numOfDays:day, currentTime:block.timestamp,claimed:false,startDay:currentDay,endDay:endDay,
        endDayTimeStamp:endDayTimeStamp,isFreeStake:false,stakeAmount:_stake,sharePrice:shareRate});
        stakeHolders[msg.sender].push(myRecord);
        dailyData memory dailyRecord = dailyDataUpdation[currentDay];
        dailyRecord.stakeShareTotal = dailyRecord.stakeShareTotal + share;
        dailyRecord.dayPayout = getDailyShare(currentDay);
        dailyRecord.unclaimed = unClaimedBtc;
        dailyRecord.mintedTokens = dailyRecord.mintedTokens - _stake;
        dailyRecord.stakedToken = dailyRecord.stakedToken + _stake;
        dailyDataUpdation[currentDay] = dailyRecord;
        emit CreateStake(id,share);
    }

    function transferStake(uint256 id,address transferTo) external {
        uint256 currentDay = findDay();
        bool updateRequire = checkDataUpdationRequired();
        if(updateRequire){
            uint256 startDay = lastUpdatedDay + 1;
            updateDailyData(startDay,currentDay);
        }
     stakeRecord[] memory myRecord = stakeHolders[msg.sender];
     for(uint i=0; i<myRecord.length; i++){
        if(myRecord[i].id == id){
        stakeHolders[transferTo].push(stakeHolders[msg.sender][i]); 
        delete(stakeHolders[msg.sender][i]);
        }
     }
    }

    function getDailyShare (uint256 day) internal view returns(uint256 dailyRewardOfDay){
        uint256 penalties = perDayPenalties[day];
        dailyData memory data = getDailyData(day);
        uint256 allocSupply = data.mintedTokens + data.stakedToken;
        dailyRewardOfDay = allocSupply * 10000;
        dailyRewardOfDay = dailyRewardOfDay / 100448995;
        dailyRewardOfDay = dailyRewardOfDay + penalties;
        return  dailyRewardOfDay;
    }

    function findBPDPercent (uint256 share,uint256 totalSharesOfBPD) internal pure returns (uint256){
        uint256 totalShares = totalSharesOfBPD;
        uint256 sharePercent = share * 10 ** 4;
        sharePercent = sharePercent / totalShares;
        sharePercent = sharePercent * 10 ** 2;
        return sharePercent;   
    }

    function findStakeSharePercent (uint256 share,uint256 day) internal view returns (uint256){
        dailyData memory data = dailyDataUpdation[day];
        uint256 sharePercent = share * 10 ** 4;
        sharePercent = sharePercent / data.stakeShareTotal;
        sharePercent = sharePercent * 10 ** 2;
        return sharePercent;   
    }

    function _calcAdoptionBonus(uint256 payout)internal view returns (uint256){
        uint256 claimableBtcAddrCount = 27997742;
        uint256 bonus = 0;
        uint256 viral = payout * claimedBtcAddrCount;
        viral = viral / claimableBtcAddrCount;
        uint256 crit = payout * claimedBTC;
        crit = crit / unClaimedBtc;
        bonus = viral + crit;
        return bonus; 
    }

    function getAllDayReward(uint256 beginDay,uint256 endDay,uint256 stakeShare) internal view returns (uint256 ){
         uint256 totalIntrestAmount = 0; 
        for (uint256 day = beginDay; day < endDay; day++) {
            dailyData memory data = dailyDataUpdation[day];
            uint256 dayShare = getDailyShare(day);
            uint256 currDayAmount = dayShare * stakeShare;
            currDayAmount = currDayAmount / data.stakeShareTotal;
            totalIntrestAmount = totalIntrestAmount + currDayAmount; 
            }
          if (beginDay <= 351 && endDay > 351) {
              dailyData memory data = dailyDataUpdation[350];  
              uint256 sharePercentOfBPD = findBPDPercent(stakeShare,data.stakeShareTotal);
              uint256 bigPayDayAmount = getBigPayDay();
              bigPayDayAmount = bigPayDayAmount + unClaimAATokens;
              uint256 bigPaySlice = bigPayDayAmount * sharePercentOfBPD;
              bigPaySlice = bigPaySlice/ 100 * 10 ** 4;
              totalIntrestAmount = bigPaySlice + _calcAdoptionBonus(bigPaySlice);
            }
        return totalIntrestAmount;
    }

    function findDayDiff(uint256 endDayTimeStamp) internal view returns(uint) {
        uint day = block.timestamp - endDayTimeStamp;
        day = day / 180;
        return day;
    }
    
    function findEstimatedIntrest (uint256 stakeShare,uint256 startDay) internal view returns (uint256) {
            uint256 day = findDay();
            uint256 sharePercent = findStakeSharePercent(stakeShare,startDay);
            uint256 dailyEstReward = getDailyShare(day);
            uint256 perDayProfit = dailyEstReward * sharePercent;
            perDayProfit = perDayProfit / 100 * 10 ** 4;
            return perDayProfit;

    }

    function getDayRewardForPenalty(uint256 beginDay,uint256 stakeShare, uint256 dayData) internal view returns (uint256){
         uint256 totalIntrestAmount = 0;
          for (uint256 day = beginDay; day < beginDay + dayData; day++) {
            uint256 dayShare = getDailyShare(day);
            totalIntrestAmount = dayShare * stakeShare;
            dailyData memory data = dailyDataUpdation[day];
            totalIntrestAmount = totalIntrestAmount / data.stakeShareTotal;
            }
        return totalIntrestAmount;
    }

    function earlyPenaltyForShort(uint256 totalIntrestAmount,uint256 currentTime,uint256 startDay,uint256 stakeShare) internal view returns(uint256){
            uint256 emergencyDayEnd = findDayDiff(currentTime);
            uint256 penalty;
            if(emergencyDayEnd == 0){
                uint256 estimatedAmount = findEstimatedIntrest(stakeShare,startDay);
                estimatedAmount = estimatedAmount * 90;
                penalty = estimatedAmount;
            }

            if(emergencyDayEnd < 90 && emergencyDayEnd !=0){
                penalty = totalIntrestAmount * 90;
                penalty = penalty / emergencyDayEnd;
               
            }

            if(emergencyDayEnd == 90){
                penalty = totalIntrestAmount;
                
            }

            if(emergencyDayEnd > 90){
                uint256 rewardTo90Days = getDayRewardForPenalty(startDay,stakeShare,89);
                 penalty = totalIntrestAmount - rewardTo90Days;
            }
            return penalty;
    }

    function earlyPenaltyForLong(uint256 totalIntrestAmount,uint256 currentTime,uint256 startDay,uint256 stakeShare,uint256 numOfDays) internal view returns(uint256){
            uint256 emergencyDayEnd = findDayDiff(currentTime);
            uint256 endDay = numOfDays;
            uint256 halfOfStakeDays = endDay / 2;
            uint256 penalty ;
            if(emergencyDayEnd == 0){
                uint256 estimatedAmount = findEstimatedIntrest(stakeShare,startDay);
                estimatedAmount = estimatedAmount * halfOfStakeDays;
                penalty = estimatedAmount;
            }

            if(emergencyDayEnd < halfOfStakeDays && emergencyDayEnd != 0){
                penalty = totalIntrestAmount * halfOfStakeDays;
                penalty = penalty / emergencyDayEnd;
            }

            if(emergencyDayEnd == halfOfStakeDays){
                penalty = totalIntrestAmount;
                
            }

            if(emergencyDayEnd > halfOfStakeDays){
                uint256 rewardToHalfDays = getDayRewardForPenalty(startDay,stakeShare,halfOfStakeDays);
                penalty = totalIntrestAmount - rewardToHalfDays;   
            }
            return penalty;
    }

    function latePenalties (uint256 totalAmountReturned,uint256 endDayTimeStamp) internal  returns(uint256){
            uint256 dayAfterEnd = findDayDiff(endDayTimeStamp);
            if(dayAfterEnd > 14){
            uint256 transferAmount = totalAmountReturned;
            uint256 perDayDeduction = 143 ;
            uint256 penalty = transferAmount * perDayDeduction;
            penalty = penalty / 1000; 
            penalty = penalty / 100;
            uint256 totalPenalty = dayAfterEnd * penalty;
            uint256 halfOfPenalty = totalPenalty / 2;
            uint256 actualAmount = 0;
            uint256 day = findDay();
             day = day + 1;
            if(totalPenalty < totalAmountReturned){

             perDayPenalties[day] = perDayPenalties[day] + halfOfPenalty;
             originAmount = originAmount + halfOfPenalty;
             actualAmount = totalAmountReturned - totalPenalty;
            }
            else{
             uint256 halfAmount = actualAmount / 2;
             perDayPenalties[day] = perDayPenalties[day] + halfAmount;
             originAmount = originAmount + halfAmount; 
            }
            return actualAmount;
            }
            else{
            return totalAmountReturned;
            }
    } 

    function settleStakes (address _sender,uint256 id) internal  {
        stakeRecord[] memory myRecord = stakeHolders[_sender];
        for(uint i=0; i<myRecord.length; i++){
            if(myRecord[i].id == id){
                myRecord[i].claimed = true;
                stakeHolders[_sender][i] = myRecord[i];
            }
        }
    }

    function calcNewShareRate (uint256 fullAmount,uint256 stakeShares,uint256 stakeDays) internal pure returns (uint256){
        uint256 BPB = findBiggerPayBetter(fullAmount);
        uint256 LPB = findLongerPaysBetter(fullAmount,stakeDays);
        uint256 newShareRate = fullAmount + BPB + LPB;
        newShareRate = newShareRate * shareRateDecimals;
        newShareRate = newShareRate / stakeShares;
        if (newShareRate > shareRateMax) {
                /*
                    Realistically this can't happen, but there are contrived theoretical
                    scenarios that can lead to extreme values of newShareRate, so it is
                    capped to prevent them anyway.
                */
                newShareRate = shareRateMax;
            }
        return newShareRate ;
    }

    function claimStakeReward (uint id) external  {
        (bool _isStakeholder, ) = isStakeholder(msg.sender);
        require(_isStakeholder,'Not SH');

        stakeRecord[] memory myRecord2 = stakeHolders[msg.sender];
        stakeRecord memory stakeData;
        uint256 currDay = findDay();
        uint256 penaltyDay = currDay + 1;
        uint256 dayToFindBonus;
        uint256 amountToNewShareRate;
        bool updateRequire = checkDataUpdationRequired();
        if(updateRequire){
            uint256 startDay = lastUpdatedDay + 1;
            updateDailyData(startDay,currDay);
        }
        for(uint i=0; i<myRecord2.length; i++){
            if(myRecord2[i].id == id){ 
                stakeData = myRecord2[i];
            }
        }
        if(stakeData.endDay > currDay){
            dayToFindBonus = currDay;
        }
        else{
            dayToFindBonus = stakeData.endDay;
        }
        uint256 totalIntrestAmount = getAllDayReward(stakeData.startDay,dayToFindBonus,stakeData.stakeShare);
        if(block.timestamp < stakeData.endDayTimeStamp){
           require(stakeData.isFreeStake != true,"notYet");
            uint256 penalty;
            if(stakeData.numOfDays < 180){
                 penalty = earlyPenaltyForShort(totalIntrestAmount,stakeData.currentTime,stakeData.startDay,stakeData.stakeShare); 
             }
            
            if(stakeData.numOfDays >= 180){
                 penalty = earlyPenaltyForLong(totalIntrestAmount,stakeData.currentTime,stakeData.startDay,stakeData.stakeShare,stakeData.numOfDays); 
            } 

                uint256 halfOfPenalty = penalty / 2;
                uint256 compeleteAmount = stakeData.stakeAmount + totalIntrestAmount;
                uint256 amountToMint = 0;
                if(penalty < compeleteAmount){ 
                    perDayPenalties[penaltyDay] = perDayPenalties[penaltyDay] + halfOfPenalty;
                    originAmount = originAmount + halfOfPenalty; 
                    amountToMint = compeleteAmount - penalty;
                }
                else{
                    uint256 halfAmount = compeleteAmount / 2;
                    perDayPenalties[penaltyDay] = perDayPenalties[penaltyDay] + halfAmount;
                    originAmount = originAmount + halfAmount; 
                }
                dailyData memory data = dailyDataUpdation[currDay];
                data.stakeShareTotal = data.stakeShareTotal - stakeData.stakeShare;
                dailyDataUpdation[currDay] = data;
                amountToNewShareRate = amountToMint;
                mintAmount(msg.sender,amountToMint);
        }

        if(block.timestamp >= stakeData.endDayTimeStamp){
         uint256 totalAmount = stakeData.stakeAmount + totalIntrestAmount;
         uint256 amounToMinted = latePenalties(totalAmount,stakeData.endDayTimeStamp);
         amountToNewShareRate = amounToMinted;
         mintAmount(msg.sender,amounToMinted);
        }
        settleStakes(msg.sender,id);
        uint256 newShare = calcNewShareRate(amountToNewShareRate, stakeData.stakeShare, stakeData.numOfDays);
        if(newShare > shareRate){
            shareRate = newShare;
        }
        dailyData memory dailyRecord = dailyDataUpdation[currDay];
        dailyRecord.stakedToken = dailyRecord.stakedToken - stakeData.stakeAmount;
        dailyDataUpdation[currDay] = dailyRecord;
       emit claimStakeRewardEvent(amountToNewShareRate,stakeData.stakeShare,stakeData.numOfDays, newShare);
    }

    function getStakeRecords() external view returns (stakeRecord[] memory stakeHolder) {
        
        return stakeHolders[msg.sender];
    }

    function getStakeSharePercent(address user, uint256 stakeId, uint256 dayToFind) external view returns(uint256){
        stakeRecord[] memory myRecord = stakeHolders[user];
        dailyData memory data = dailyDataUpdation[dayToFind];
        uint256 sharePercent;
        for(uint i=0; i<myRecord.length; i++){
            if(myRecord[i].id == stakeId){
            sharePercent = myRecord[i].stakeShare * 10 ** 4;
            sharePercent = sharePercent / data.stakeShareTotal;
            }
        }
        return  sharePercent;
    }
 
    // function createFreeStake(
    //     // address user,  
    //     string memory btcAddress2, 
    //     uint balance2,
    //     address refererAddress,
    //     bytes32[] calldata proof,
    //     bytes32 pubKeyX,
    //     bytes32 pubKeyY,
    //     uint8 claimFlags,
    //     uint8 v,
    //     bytes32 r,
    //     bytes32 s
    //     ) external {
    //     require(balance2 > 0, 'lowBalance');
    //     address ad = refererAddress;
    //     string memory btcAddress = btcAddress2;
    //     uint balance = balance2;
    //     // validationContract.pubKeyToBtcAddress(pubKeyX,pubKeyY,claimFlags);
    //     //  validationContract.btcAddressClaim(balance2, proof, msg.sender, pubKeyX, pubKeyY, claimFlags, v, r, s, 365,ad);
    //     bool isClaimable = btcAddressClaims[btcAddress];
    //     require(!isClaimable,"claimed");
    //     uint day = findDay();
    //     bool updateRequire = checkDataUpdationRequired();
    //     if(updateRequire){
    //         uint256 startDay = lastUpdatedDay / 1;
    //         updateDailyData(startDay,day);
    //     }
    //     distributeFreeStake(msg.sender,btcAddress,day,balance, ad); 
    //     unClaimedBtc = unClaimedBtc - balance;
    //     perDayUnclaimedBTC[day] = perDayUnclaimedBTC[day] + balance;
    //     claimedBTC = claimedBTC + balance;
    //     btcAddressClaims[btcAddress] = true;
    //     claimedBtcAddrCount ++ ;  
    //     dailyData memory dailyRecord = dailyDataUpdation[day];
    //     dailyRecord.unclaimed = unClaimedBtc;
       
    //     dailyRecord.dayPayout = getDailyShare(day);

    //     dailyDataUpdation[day] = dailyRecord;   
    // }

    function findSillyWhalePenalty(uint256 amount) internal pure returns (uint256){
        if(amount < 1000e8){
            return amount;
        }
        else if(amount >= 1000e8 && amount < 10000e8){  
            uint256 penaltyPercent = amount - 1000e8;
            penaltyPercent = penaltyPercent * 25 * 10 ** 2;
            penaltyPercent = penaltyPercent / 9000e8; 
            penaltyPercent = penaltyPercent + 50 * 10 ** 2; 
            uint256 deductedAmount = amount * penaltyPercent; 
            deductedAmount = deductedAmount / 10 ** 4;          
            uint256 adjustedBtc = amount - deductedAmount;  
            return adjustedBtc;   
        }
        else { 
            uint256 adjustedBtc = amount * 25;
            adjustedBtc = adjustedBtc / 10 ** 2;
            return adjustedBtc;  
        }
    }

    function findLatePenaltiy(uint256 dayPassed) internal pure returns (uint256){
        uint256 totalDays = 350;
        uint256 latePenalty = totalDays - dayPassed;
        latePenalty = latePenalty * 10 ** 4;
        latePenalty = latePenalty / 350;
        return latePenalty; 
    }

    function findSpeedBonus(uint256 day,uint256 share) internal pure returns (uint256){
      uint256 speedBonus = 0;
      uint256 initialAmount = share;
      uint256 percentValue = initialAmount * 20;
      uint256 perDayValue = percentValue / 350;  
      uint256 deductedAmount = perDayValue * day;      
      speedBonus = percentValue - deductedAmount;
      return speedBonus;

    }

    function findReferalBonus(address user,uint256 share,address referer) internal pure returns(uint256) { 
       uint256 fixedAmount = share;
       uint256 sumUpAmount = 0;
      if(referer != address(0)){
       if(referer != user){
         
        // if referer is not user it self
        uint256 referdBonus = fixedAmount * 10;
        referdBonus = referdBonus / 100;
        sumUpAmount = sumUpAmount + referdBonus;
       }
       else{
        // if a user referd it self  
        uint256 referdBonus = fixedAmount * 20;
        referdBonus = referdBonus / 100;
        sumUpAmount = sumUpAmount + referdBonus;
        }
       }
       return sumUpAmount;
    }

    function createReferalRecords(address refererAddress, address referdAddress,uint256 awardedPTP) internal {
        uint day = findDay();
        referalsRecord memory myRecord = referalsRecord({referdAddress:referdAddress,day:day,awardedPTP:awardedPTP});
        referals[refererAddress].push(myRecord);
    }

    function createFreeStakeClaimRecord(address userAddress,string memory btcAddress,uint256 day,uint256 balance,uint256 claimedAmount) internal {

     freeStakeClaimInfo memory myRecord = freeStakeClaimInfo({btcAddress:btcAddress,balanceAtMoment:balance,dayFreeStake:day,claimedAmount:claimedAmount,rawBtc:unClaimedBtc});
     freeStakeClaimRecords[userAddress].push(myRecord);
    }

    function freeStaking(uint256 stakeAmount,address userAddress) internal  {
        uint256 id = counterId++;
        uint256 startDay = findDay();
        uint256 endDay = startDay + 365;   
        uint256 endDayTimeStamp = findEndDayTimeStamp(endDay);
        uint256 share = generateShare(stakeAmount,0,0);
        subtractedShares[endDay] = subtractedShares[endDay] + share;
        stakeRecord memory myRecord = stakeRecord({id:id,stakeShare:share, stakeName:'', numOfDays:365,
         currentTime:block.timestamp,claimed:false,startDay:startDay,endDay:endDay,
        endDayTimeStamp:endDayTimeStamp,isFreeStake:true,stakeAmount:stakeAmount,sharePrice:shareRate});
        stakeHolders[userAddress].push(myRecord); 
        dailyData memory dailyRecord = dailyDataUpdation[startDay];
        dailyRecord.stakeShareTotal = dailyRecord.stakeShareTotal + share;
        dailyRecord.stakedToken = dailyRecord.stakedToken + stakeAmount;
        dailyDataUpdation[startDay] = dailyRecord;
        (bool _isStakeholder, ) = isStakeholder(userAddress);
        if(! _isStakeholder) addStakeholder(userAddress);
        
    }

    function distributeFreeStake(address userAddress,string memory btcAddress,uint256 balance,address refererAddress) external {
            uint256 day = findDay();
            uint256 sillyWhaleValue = findSillyWhalePenalty(balance);
            uint share = sillyWhaleValue * 10 ** 8;
            share = share / 10 ** 4;
            uint256 actualAmount = share;  
            uint256 latePenalty = findLatePenaltiy(day);
            actualAmount = actualAmount * latePenalty;
            //Late Penalty return amount in 4 decimal to avoid decimal issue,
            // we didvide with 10 ** 4 to find actual amount 
            actualAmount = actualAmount / 10 ** 4;
            //Speed Bonus
            
            uint256 userSpeedBonus = findSpeedBonus(day,actualAmount);
            userSpeedBonus = userSpeedBonus / 100;
            actualAmount = actualAmount + userSpeedBonus;
            originAmount = originAmount + actualAmount;

            uint256 refBonus = 0;
           //Referal Mints 
            if(refererAddress != userAddress && refererAddress != address(0)){
                uint256 amount = actualAmount;
                uint256 referingBonus = amount * 20;
                referingBonus = referingBonus / 100;
                originAmount = originAmount + referingBonus;
                mintAmount(refererAddress,referingBonus);
           }
        
         //Referal Bonus
            if(refererAddress != address(0)){
            refBonus = findReferalBonus(userAddress,actualAmount,refererAddress);
            actualAmount = actualAmount + refBonus;
            originAmount = originAmount + refBonus;
            createReferalRecords(refererAddress,userAddress,refBonus);
          }
         uint256 mintedValue = actualAmount * 10; 
         mintedValue = mintedValue / 100;
         mintAmount(userAddress,mintedValue); 
         createFreeStakeClaimRecord(userAddress,btcAddress,day,balance,mintedValue);

         uint256 stakeAmount = actualAmount * 90;
         stakeAmount = stakeAmount / 100; 
         freeStaking(stakeAmount,userAddress);
        unClaimedBtc = unClaimedBtc - balance;
        perDayUnclaimedBTC[day] = perDayUnclaimedBTC[day] + balance;
        claimedBTC = claimedBTC + balance;
        btcAddressClaims[btcAddress] = true;
        claimedBtcAddrCount ++ ;  
        dailyData memory dailyRecord = dailyDataUpdation[day];
        dailyRecord.unclaimed = unClaimedBtc;
       
        dailyRecord.dayPayout = getDailyShare(day);

        dailyDataUpdation[day] = dailyRecord; 

    }

    function getFreeStakeClaimRecord() external view returns (freeStakeClaimInfo[] memory claimRecords){
       return freeStakeClaimRecords[msg.sender];
    } 

    function extendStakeLength(uint256 totalDays, uint256 id) external { 
        uint256 currentDay = findDay();
        bool updateRequire = checkDataUpdationRequired();
        if(updateRequire){
            uint256 startDay = lastUpdatedDay + 1;
            updateDailyData(startDay,currentDay);
        }
        stakeRecord[] memory myRecord = stakeHolders[msg.sender];
        for(uint i=0; i<myRecord.length; i++){
            if(myRecord[i].id == id){
                if(myRecord[i].isFreeStake){
                    if(totalDays >= 365){
                        require(myRecord[i].startDay + totalDays > myRecord[i].numOfDays , 'falseDays');
                        myRecord[i].numOfDays = myRecord[i].numOfDays + totalDays;
                        myRecord[i].endDay = myRecord[i].startDay + totalDays;
                        myRecord[i].endDayTimeStamp = findEndDayTimeStamp(myRecord[i].endDay);
                    }
                }
             stakeHolders[msg.sender][i] = myRecord[i];
            }
        }
    }

    function findAddress(uint256 day, address sender) internal view returns(bool){
        address addressValue = AARecords[day][sender].user;
        if(addressValue == address(0)){
            return false;
        }
        else{
           return true;
        }
    }

    function enterAALobby (address refererAddress) external payable {
        require(msg.value > 0, '0 Balance');
        uint day = findDay();
        bool updateRequire = checkDataUpdationRequired();
        if(updateRequire){
            uint256 startDay = lastUpdatedDay + 1;
            updateDailyData(startDay,day);
        }
        RecordInfo memory myRecord = RecordInfo({amount: msg.value, time: block.timestamp, claimed: false, user:msg.sender,refererAddress:refererAddress});
        bool check = findAddress(day,msg.sender);
        if(check == false){
            AARecords[day][msg.sender] = myRecord;
            perDayAARecords[day].push(msg.sender);
        }  
        else{
            RecordInfo memory record = AARecords[day][msg.sender];
            record.amount = record.amount + msg.value;
            AARecords[day][msg.sender] = record;
        }
      
        totalBNBSubmitted[day] = totalBNBSubmitted[day] + msg.value;
        emit enterLobby(msg.value,msg.sender);
    }

    function getTotalBNB (uint day) public view returns (uint256){
        
       return totalBNBSubmitted[day];
    }

    function getAvailablePTP (uint day) public view returns (uint256 daySupply){
        uint256 hexAvailabel = 0;
       
        uint256 firstDayAvailabilty = 1000000000 * 10 ** 8; 
        if(day == 0){
            hexAvailabel = firstDayAvailabilty;
        }
        else{
            uint256 othersDayAvailability = 19000000 * 10 ** 8;
            uint256 totalUnclaimedToken = 0;
            for(uint256 i = 0; i < day; i++){
                totalUnclaimedToken= totalUnclaimedToken + perDayUnclaimedBTC[i];
            }
            
            othersDayAvailability = othersDayAvailability - totalUnclaimedToken;
            //as per rules we have to multiply it with 10^8 than divided with 10 ^ 4 but as we can make it multiply 
            //with 10 ^ 4
            othersDayAvailability = othersDayAvailability * 10 ** 4;
            hexAvailabel = othersDayAvailability / 350;
        }
        daySupply = hexAvailabel;
       return daySupply;
    }

    function getTransactionRecords(uint day,address user) public view returns (RecordInfo memory record) {   
            return AARecords[day][user];
    }

    function countShare (uint256 userSubmittedBNB, uint256 dayTotalBNB, uint256 availablePTP) internal pure returns  (uint256) {
        uint256 share = 0;
        //to avoid decimal issues we add 10 ** 5
        share = userSubmittedBNB * 10 ** 5 / dayTotalBNB;
        share = share * availablePTP;
        return share / 10 ** 5;
    }

    function settleSubmission (uint day, address user) internal  {
        RecordInfo memory myRecord = AARecords[day][user];
                 myRecord.claimed = true;
                 AARecords[day][user] = myRecord;
    }

    function claimAATokens () external {
        uint256 presentDay = findDay();
        require(presentDay > 0,'not now');
        bool updateRequire = checkDataUpdationRequired();
        if(updateRequire){
            uint256 startDay = lastUpdatedDay + 1;
            updateDailyData(startDay,presentDay);
        }
        uint256 prevDay = presentDay - 1;
        uint256 dayTotalBNB = getTotalBNB(prevDay);
        uint256 availablePTP = getAvailablePTP(prevDay);
        RecordInfo memory record = getTransactionRecords(prevDay,msg.sender);
        if(record.user != address(0) && record.claimed == false){
           uint256 userSubmittedBNB = record.amount;
           uint256 userShare = 0;
           uint256 referalBonus = 0;
           userShare = countShare(userSubmittedBNB,dayTotalBNB,availablePTP);
            address userReferer = record.refererAddress;
            if(userReferer != msg.sender && userReferer !=address(0)){
             uint256 amount = userShare;
             uint256 referingBonus = amount * 20;
             referingBonus = referingBonus / 100;
             originAmount = originAmount + referingBonus;
             mintAmount(userReferer,referingBonus);
             createReferalRecords(userReferer,msg.sender,referingBonus);
             }
            referalBonus =  findReferalBonus(msg.sender,userShare,userReferer);  
             userShare = userShare + referalBonus;
             originAmount = originAmount + referalBonus;
             mintAmount(msg.sender,userShare);
             settleSubmission(prevDay,msg.sender);
             if(userReferer != address(0)){
              createReferalRecords(userReferer,msg.sender,referalBonus);
             }
            emit claimTokenAA(userShare,dayTotalBNB,record.amount);
        }
    }

    function getReferalRecords(address refererAddress) external view returns (referalsRecord[] memory referal) {
        
        return referals[refererAddress];
    }

    function transferPTP(address recipientAddress, uint256 _amount) external{
        _transfer(msg.sender,recipientAddress,_amount);
        transferInfo memory myRecord = transferInfo({amount: _amount,to:recipientAddress, from: msg.sender});
        transferRecords[msg.sender].push(myRecord);
    }

    function getTransferRecords( address _address ) external view returns (transferInfo[] memory transferRecord) {
        return transferRecords[_address];
    }

    function getBigPayDay() internal view returns (uint256){
        uint256 totalAmount = 0;
        for(uint256 j = 0 ; j<=350; j++){
            dailyData memory data = dailyDataUpdation[j];
            uint256 btc = data.unclaimed / 10 ** 8;
            uint256 bigPayDayAmount = btc * 2857;
            //it should be divieded with 10 ** 6 but we have to convert it in hex so we div it 10 ** 2
            bigPayDayAmount = bigPayDayAmount / 10 ** 2;
            totalAmount = totalAmount + bigPayDayAmount;
        }
        return totalAmount ;
    }
    
    function getShareRate() external view returns (uint256){
        return shareRate;
    }

    function unclaimedRecord(uint256 presentDay) internal view returns (uint256 unclaimedAAToken) {
        uint256 prevDay = presentDay - 2;
        uint256 dayTotalBNB = getTotalBNB(prevDay);
        uint256 availablePTP = getAvailablePTP(prevDay);
        address[] memory allUserAddresses = perDayAARecords[0];
        if(allUserAddresses.length > 0){
            for(uint i = 0; i < allUserAddresses.length; i++){
                uint256 userSubmittedBNB = 0;
                uint256 userShare = 0;
                RecordInfo memory record = getTransactionRecords(prevDay,allUserAddresses[i]);
                if(record.claimed == false){
                    userSubmittedBNB = record.amount;
                    userShare = countShare(userSubmittedBNB,dayTotalBNB,availablePTP);
                    unclaimedAAToken = unclaimedAAToken + userShare;
                }
            
            } 
        }  
        else{
         unclaimedAAToken = unclaimedAAToken + availablePTP;
        }
        return unclaimedAAToken;
    }
}