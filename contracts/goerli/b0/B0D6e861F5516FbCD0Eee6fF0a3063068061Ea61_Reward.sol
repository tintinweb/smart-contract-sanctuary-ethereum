/**
 *Submitted for verification at Etherscan.io on 2023-06-13
*/

// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol


pragma solidity ^0.8.0;

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

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

// File: contracts/getprice.sol


pragma solidity ^0.8.0;


/*
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
        this;
        // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `+` operator.
   *
   * Requirements:
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
   * - Subtraction cannot overflow.
   */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
   * overflow (when the result is negative).
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   * - Subtraction cannot overflow.
   */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `*` operator.
   *
   * Requirements:
   * - Multiplication cannot overflow.
   */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
   * division by zero. The result is rounded towards zero.
   *
   * Counterpart to Solidity's `/` operator. Note: this function uses a
   * `revert` opcode (which leaves remaining gas untouched) while Solidity
   * uses an invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
   * division by zero. The result is rounded towards zero.
   *
   * Counterpart to Solidity's `/` operator. Note: this function uses a
   * `revert` opcode (which leaves remaining gas untouched) while Solidity
   * uses an invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
   * Reverts when dividing by zero.
   *
   * Counterpart to Solidity's `%` operator. This function uses a `revert`
   * opcode (which leaves remaining gas untouched) while Solidity uses an
   * invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
   * Reverts with custom message when dividing by zero.
   *
   * Counterpart to Solidity's `%` operator. This function uses a `revert`
   * opcode (which leaves remaining gas untouched) while Solidity uses an
   * invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

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

contract Reward is Context, Ownable {


    AggregatorV3Interface internal priceFeed;
    uint256 periodNumber; //
    address asset;
    address nftasset;
    uint256 fee;
    uint256 minBnb;
    uint256 feeClaim;
    uint256 times5;
    uint256 times3;
    uint256 times2;
    uint256 base5;
    uint256 baseFee;
    uint256 baseTimeOut;
    uint256 public limitAmount;
    uint256 public limitAmountU;
    uint256 public basePay;

    bool public isSale;
    bool public isSaleActive;
    bool public isSaleActiveFree;


    mapping(address => uint256) private newstId; //
    mapping(address => uint256[]) private personHistory;//
    mapping(uint256 => uint256) private rewardHistoryTime;//
    mapping(uint256 => mapping(address => uint256)) private maxPerson; //
    //
    mapping(uint256 => uint256[]) private rewardHistory;                     //
    //
    mapping(address => mapping(uint256 => mapping(uint256 => uint256[]))) private SeveralIssues; // addr qi index reward
    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor () {
        priceFeed = AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);
        asset = 0x3bFE12D0b3D67103e0e7e9841ba9D8A56Cb67847;
        nftasset = 0x7f356E5e1926B5FeBbdef529eDc9E77f331054c8;
        periodNumber = 1;
        fee = 99;
        feeClaim = 70;
        baseFee = 100;
        times5 = 9;
        times3 = 3;
        times2 = 2;
        base5 = 5;
        baseTimeOut = 10;
        limitAmount = 10;
        limitAmountU = 100000;
        basePay = 1 * 10 ** 15;
        minBnb = 1 * 10 ** 15;
    }

    receive() external payable {
        // 接收 ETH
    }

    function withdraw(uint256 amount) external onlyOwner {
        require(address(this).balance >= amount, "Insufficient BNB balance");
        payable(owner()).transfer(amount);
    }

    function getBalanceBnb() public view returns (uint256) {
        return address(this).balance;
    }
    //
    function flipSaleState() public onlyOwner {
        isSaleActive = !isSaleActive;
    }

    function flipSale() public onlyOwner {
        isSale = !isSale;
    }


    function flipSaleStateFree() public onlyOwner {
        isSaleActiveFree = !isSaleActiveFree;
    }

    function getFlipSaleState() public view returns (bool) {
        return isSaleActive;
    }

    function getFlipSaleStateFree() public view returns (bool) {
        return isSaleActiveFree;
    }

    function setBasePay(uint256 basePayOne) public onlyOwner() {
        basePay = basePayOne * 10 ** 14;
    }

    function setAsset(address assetOne) public onlyOwner() {
        asset = assetOne;
    }

    function setLimit(uint256 limitOne) public onlyOwner() {
        limitAmount = limitOne;
    }

    function setLimitU(uint256 limitOne) public onlyOwner() {
        limitAmountU = limitOne;
    }


    function setBase5(uint256 base5One) public onlyOwner() {
        base5 = base5One;
    }

    function setFee(uint256 feeOne) public onlyOwner() {
        fee = feeOne;
    }

    function setMinBnb(uint256 feeOne) public onlyOwner() {
        minBnb = feeOne;
    }

    function setFeeClaim(uint256 feeOne) public onlyOwner() {
        feeClaim = feeOne;
    }


    function setBaseTimeOut(uint256 baseTimeOutOne) public onlyOwner() {
        baseTimeOut = baseTimeOutOne;
    }


    function setTimes5(uint256 times5One) public onlyOwner() {
        times5 = times5One;
    }

    function setTimes3(uint256 times3One) public onlyOwner() {
        times3 = times3One;
    }

    function setTimes2(uint256 times2One) public onlyOwner() {
        times2 = times2One;
    }


    function getRewardHistoryTime(uint256 indexOne) public view returns (uint256){
        return rewardHistoryTime[indexOne];
    }

    function doNext() public onlyOwner() returns (uint256[] memory) {
        require(isSale, "Sale is not active");
        (
        /*uint80 roundID*/,
        int price,
        /*uint startedAt*/,
        /*uint timeStamp*/,
        /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();

        // :

        //uint256[] ls = new uint256[](5);
        for (uint i = periodNumber; i < periodNumber + 5; i++) {
            uint random = uint(keccak256(abi.encode(block.timestamp, msg.sender, i, price))) % 10;
            //ls.push(random);
            rewardHistory[periodNumber].push(random);
        }
        rewardHistoryTime[periodNumber] = block.timestamp;
        periodNumber += 1;
        return rewardHistory[periodNumber - 1];
    }

    function getRewardHistory(uint256 i) public view returns (uint256[] memory) {
        return rewardHistory[i];
    }

    function getSeveralIssues(address addr, uint256 i, uint256 index) public view returns (uint256[] memory) {
        return SeveralIssues[addr][i][index];
    }


    function getPersonHistoryAll(address addr) public view returns (uint256[] memory) {
        return personHistory[addr];
    }

    function getPersonHistoryAllLength(address addr) public view returns (uint256) {
        return personHistory[addr].length;
    }

    function getPersonHistoryIndex(address addr, uint256 begin, uint256 end) public view returns (uint256[] memory) {
        uint256 sizeA = end - begin + 1;
        uint256[] memory indexH = new uint256[](sizeA);
        uint256 i = 0;
        for (uint256 i = begin; i <= end; i++) {
            indexH[i] = personHistory[addr][i];
            i++;
        }
        return indexH;
    }


    function getPeriodNumber() public view returns (uint256) {
        return periodNumber;
    }

    //
    function balanceOfTotal() public view returns (uint256){
        IERC20 token = IERC20(asset);
        return token.balanceOf(address(this));
    }

    //
    function doPerPay(uint256 aType, uint256 a, uint256 b, uint256 c, uint256 d, uint256 e) payable public {
        //require(aAmount >= limitAmount, "aAmount less than limitAmount");
        //require(aAmount <= limitAmountU, "aAmount more than limitAmount");

        require(isSaleActive, "Sale is not active");

        if (periodNumber != 1) {
            require(block.timestamp >= rewardHistoryTime[periodNumber - 1] && block.timestamp <= rewardHistoryTime[periodNumber - 1] + baseTimeOut, "time out");
        }
        if (balanceOfOneAll(msg.sender) > 0) {
            doClaim();
        }
        //require(getIsPle(msg.sender), "already ple");
        require(msg.value >= minBnb, "BNB exceeds the limit");

        payable(owner()).transfer(msg.value);

        IERC20 nftToken = IERC20(nftasset);
        uint256 balanceNft = nftToken.balanceOf(msg.sender);
        require(balanceNft > 0, "expect nft not 0");
        require(SeveralIssues[msg.sender][periodNumber][balanceNft - 1].length == 0, "already list out");
        for (uint256 i; i < balanceNft; i++) {
            if (SeveralIssues[msg.sender][periodNumber][i].length == 0) {
                SeveralIssues[msg.sender][periodNumber][i] = [aType, a, b, c, d, e, 0];
            }
        }

        newstId[msg.sender] = periodNumber;
        personHistory[msg.sender].push(periodNumber);
    }


    //
    function getNewsId(address addr) public view returns (uint256){
        return newstId[addr];
    }


    // true  can buy ; false not can buy
    function getIsPle(address addr) public view returns (bool){
        return newstId[addr] != periodNumber;
    }

    function getBuyOrNot(address addr) public view returns (bool){
        IERC20 nftToken = IERC20(nftasset);
        uint256 balanceNft = nftToken.balanceOf(msg.sender);
        if (balanceNft <= 0) {
            return false;
        }
        for (uint256 i; i < balanceNft; i++) {
            if (SeveralIssues[msg.sender][periodNumber][i].length == 0) {
                return true;
            }
        }
        return false;
    }

    //
    function doClaim() public {
        IERC20 token = IERC20(nftasset);
        uint256 amount = token.balanceOf(msg.sender);
        require(amount >= 0, "zero nft");
        uint256 totalReward = 0;
        uint256 iss = newstId[msg.sender];
        for (uint256 i = 0; i < amount; i++) {
            if ((SeveralIssues[msg.sender][iss][i].length > 0) && (SeveralIssues[msg.sender][iss][i][6] == 0)) {
                SeveralIssues[msg.sender][iss][i][6] = 1;
                uint256 reward = balanceOfOne(msg.sender, i);
                totalReward += reward;
            }
        }

        require(totalReward != 0, "reward amount is 0");
        payable(msg.sender).transfer(totalReward);
        //
    }


    function balanceOfOneAll(address addr) public view returns (uint256){
        IERC20 token = IERC20(nftasset);
        uint256 amount = token.balanceOf(addr);
        if (amount == 0) {
            return 0;
        }
        uint256 totalReward = 0;
        uint256 iss = newstId[addr];
        for (uint256 i = 0; i < amount; i++) {
            if ((SeveralIssues[addr][iss][i].length > 0) && (SeveralIssues[addr][iss][i][6] == 0)) {
                uint256 reward = balanceOfOne(addr, i);
                totalReward += reward;
            }
        }
        return totalReward;
    }


    //
    function balanceOfOne(address addr, uint256 indexI) public view returns (uint256){
        uint256 iss = newstId[addr];
        if (iss == 0) {
            return 0;
        }
        uint256[] memory pushOne = SeveralIssues[addr][iss][indexI];
        uint256[] memory nums = rewardHistory[iss];
        if (newstId[addr] == periodNumber) {// already next
            return 0;
        }
        if (pushOne[6] == 1) {//
            return 0;
        } else {//
            uint256 toTalBalance = address(this).balance;
            if (pushOne[0] == 2) {//
                //uint256[] memory numsls = pushOne[2];
                if (pushOne[2] == rewardHistory[iss][0] && pushOne[3] == rewardHistory[iss][1] && pushOne[4] == rewardHistory[iss][2] && pushOne[5] == rewardHistory[iss][3] && pushOne[6] == rewardHistory[iss][4]) {
                    return toTalBalance * times5 * fee / baseFee / 10;
                } else if ((pushOne[2] == rewardHistory[iss][0] && pushOne[3] == rewardHistory[iss][1] && pushOne[4] == rewardHistory[iss][2]) || (pushOne[4] == rewardHistory[iss][2] && pushOne[5] == rewardHistory[iss][3] && pushOne[6] == rewardHistory[iss][4])) {
                    return toTalBalance * times3 * fee / baseFee / 10;
                } else if ((pushOne[2] == rewardHistory[iss][0] && pushOne[3] == rewardHistory[iss][1]) || (pushOne[5] == rewardHistory[iss][3] && pushOne[6] == rewardHistory[iss][4])) {
                    return toTalBalance * times2 * fee / baseFee / 10;
                } else {
                    return 0;
                }
            }
        }
        return 0;
    }
}