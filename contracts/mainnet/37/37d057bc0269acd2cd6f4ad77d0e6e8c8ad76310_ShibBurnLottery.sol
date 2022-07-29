/**
 *Submitted for verification at Etherscan.io on 2022-07-29
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: contracts/ShibBurn.sol

//SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;



interface IShibBurn {
    function burnShib(uint256 amount) external;
}

interface ISwapper {
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}

/** 
    Purpose of ShibBurnLottery is to burn SHIB tokens through Shib Burn Portal, which in exchange
    returns burntSHIB. When tokens get burned, this contract randomly selects addresses that will
    receive the burntSHIB. Additionaly it can select some more addresses that will receive special
    rewards manualy from the Owner. This can be NFTs / project tokens or other.

    When participating in lottery, user specifies the amount of tokens that he wishes to participate
    with. The amount is directly corelated to chance of winning.
    If user does not have SHIB tokens, he can also execute "buyAndParticipate", which uses ShibaSwap
    to swap ETH to SHIB.

    Example reward distribution:

    n = number of winners = 3
    i = winner position (eg. 1 = 1st place, 2 = 2nd place)
    a = amount of reward in this lottery = 100
    ap = amount already paid out in this lottery
    Formula:
    (a - ap / (n + 2 - i)) * 2

    1st place:
    amount1 = (a / (n + 2 - i)) * 2;
    amount1 = (100 / (3 + 2 - 1) * 2)
    amount1 = 50

    2nd place:
    amount2 = ((a - amount1) / (n + 2 - i)) * 2
    amount2 = ((100 - 50) / (3 + 2 - 2)) * 2
    amount2 = 33

    3rd place:
    amount3 = ((a - amount1 - amount2) / (n + 2 - i)) * 2
    amount3 = ((100 - 50 - 33) / (3 + 2 - 3)) * 2
    amount3 = 16

 */


contract ShibBurnLottery is Ownable {
    ISwapper public router; // ShibaSwap

    address public verseAddress;
    address public shibAddress;
    address public burntShibAddress;
    address public wethAddress;
    address public shibBurnContract;

    struct Winner{
        address account;
        uint amount; // amount of burntSHIB won
    }

    struct Settings{
        uint rewardAmount;
        uint8 numOfWinners1; // winners that receive tokens
        uint8 numOfWinners2; // winners that receive rewards manually
        uint startedAt;
    }

    mapping(address => mapping(uint => uint)) accountLotteryParticipation; // map account to lottery id to amount participated 

    mapping(uint => address[]) public lotteryParticipants; // map lottery id to lottery participants addresses

    mapping(uint => Winner[]) public lotteryWinners; // map lottery id to lottery winners

    mapping(uint => uint) public lotteryTotalTickets; // map lottery id to amount of tickets sold

    mapping(uint => Settings) public lotterySettings;

    uint public currentLotteryId;
    uint public minParticipation;
    uint public maxParticipants;

    bool public active;
    bool locked;

    /* ========== MODIFIERS ========== */

    modifier noReentrancy() {
        require(!locked,"Reentrant call");
        locked = true;
        _;
        locked = false;
    }

    /* ========== EVENTS ========== */

    event Participated(
        uint lotteryId,
        address account,
        uint amount
    );

    event LotteryDrawn(
        uint lotteryId,
        Winner[] winners
    );

    event LotteryStarted(
        uint lotteryId,
        uint rewardAmount,
        uint numOfWinners1,
        uint numOfWinners2
    );

    /* ========== CONSTRUCTOR ========== */

    constructor (address _verseAddress, address _shibAddress, address _burntShibAddress, address _shibBurnContract, address _wethAddress, address _router, uint _minParticipation, uint _maxParticipants) {
        verseAddress = _verseAddress;
        shibAddress = _shibAddress;
        burntShibAddress = _burntShibAddress;
        shibBurnContract = _shibBurnContract;
        wethAddress = _wethAddress;
        minParticipation = _minParticipation;
        maxParticipants = _maxParticipants;
        router = ISwapper(_router);
    }
    
    /* ========== SET LIMITS ========== */

    function setMaxParticipants(uint _maxParticipants) external onlyOwner {
        maxParticipants = _maxParticipants;
    }

    function setMinParticipation(uint _minParticipation) external onlyOwner {
        minParticipation = _minParticipation;
    }

    /* ========== ACTIVATE LOTTERY ========== */

    function activateLottery(uint _rewardAmount, uint8 _numOfWinners1, uint8 _numOfWinners2) external onlyOwner {
        require(!active, "Lottery already started");
        require(_rewardAmount > 0 && _numOfWinners1 > 0, "Invalid settings");
        require(_rewardAmount <= IERC20(verseAddress).balanceOf(address(this)), "Balance too low");
        active = true;
        lotterySettings[currentLotteryId] = Settings(_rewardAmount, _numOfWinners1, _numOfWinners2, block.timestamp);
        emit LotteryStarted(currentLotteryId, _rewardAmount, _numOfWinners1, _numOfWinners2);
    }

    /* ========== PARTICIPATE ========== */

    function _participate(uint _amount) internal {
        uint participated = accountLotteryParticipation[msg.sender][currentLotteryId]; // get amount of tokens that user already participated with in current lottery

        accountLotteryParticipation[msg.sender][currentLotteryId] = participated + _amount;

        if(participated == 0) { // if user did not participate in current lottery before, add him to participants
            lotteryParticipants[currentLotteryId].push(msg.sender);
        }

        lotteryTotalTickets[currentLotteryId] += _amount;

        // burn SHIB through the shibBurn portal
        IERC20(shibAddress).approve(shibBurnContract, _amount);
        IShibBurn(shibBurnContract).burnShib(_amount); 
        IERC20(burntShibAddress).transfer(msg.sender, _amount);
        
        emit Participated(currentLotteryId, msg.sender, _amount);
    }

    function participate(uint _amount) external noReentrancy {
        require(active, "Not active");
        require(_amount >= minParticipation, "Too low");
        require(lotteryParticipants[currentLotteryId].length < maxParticipants, "Participants limit reached");
        IERC20(shibAddress).transferFrom(msg.sender, address(this), _amount);
        _participate(_amount);
    }

    function buyAndParticipate(uint _minOut) external payable noReentrancy { // Swap ETH to SHIB on ShibaSwap and participate
        require(active, "Not active");
        require(_minOut >= minParticipation, "Too low");
        require(lotteryParticipants[currentLotteryId].length < maxParticipants, "Participants limit reached");
        address[] memory ethPath = new address[](2);
        ethPath[0] = wethAddress; // WETH
        ethPath[1] = shibAddress;
        IERC20 token = IERC20(shibAddress);

        uint256 balanceWas = token.balanceOf(address(this));
        router.swapExactETHForTokens{ value: msg.value }(_minOut, ethPath, address(this), block.timestamp + 1000);
        uint256 amount = token.balanceOf(address(this)) - balanceWas;

        _participate(amount);
    }

    /* ========== DRAW LOTTERY ========== */

    function drawWinners() external onlyOwner {
        require(active, "Not active");

        uint lotteryId = currentLotteryId;

        // draw lottery winners and distribute verse
        _drawWinners(lotteryId);

        emit LotteryDrawn(
            lotteryId,
            lotteryWinners[lotteryId]
        );

        currentLotteryId = lotteryId + 1;
        active = false;
    }

    function _drawWinners(uint _lotteryId) internal {
        Settings memory settings = lotterySettings[_lotteryId];
        address[] memory participants = lotteryParticipants[_lotteryId];
        uint totalTickets = lotteryTotalTickets[_lotteryId];
        uint toPay = settings.rewardAmount;

        for(uint i = 0; i < settings.numOfWinners1 + settings.numOfWinners2; i++) {

            uint randomNumber = (uint(keccak256(abi.encodePacked(i, block.timestamp, block.difficulty))) % totalTickets ) + 1;

            uint currentNumber = 0;

            for(uint j = 0; j < participants.length; j++) {

                currentNumber += accountLotteryParticipation[participants[j]][_lotteryId];

                if(currentNumber >= randomNumber) {
                    uint pay;

                    if(i < settings.numOfWinners1) {
                        pay = (toPay / (settings.numOfWinners1 + 1 - i)) * 2;
                        toPay = toPay - pay;

                        IERC20(verseAddress).transfer(participants[j], pay);
                    }

                    totalTickets -= accountLotteryParticipation[participants[j]][_lotteryId];
                    lotteryWinners[_lotteryId].push(Winner(participants[j], pay));

                    delete participants[j];
                    break;
                }
            }
        }
    }

    /* ========== VIEWS ========== */

    function getWinners(uint _lotteryId) external view returns(Winner[] memory) { // get winners for lottery
        return lotteryWinners[_lotteryId];
    }

    function getTotalTickets() external view returns(uint) { // get total tickets sold / total SHIB burnt
        uint total = 0;

        for(uint i = 0; i <= currentLotteryId; i ++) {
            total += lotteryTotalTickets[i];
        }

        return total;
    }

    function getParticipants(uint _lotteryId) external view returns(uint) { // get number of participants for lottery
        return lotteryParticipants[_lotteryId].length;
    }

    function getParticipation(address _account, uint _lotteryId) external view returns(uint) { // get participation for acoount in lottery
        return accountLotteryParticipation[_account][_lotteryId];
    }

    function getTotalParticipation(address _account) external view returns(uint) { // get participation for account in all lotteries combined
        uint total = 0;

        for(uint i = 0; i <= currentLotteryId; i ++) {
            total += accountLotteryParticipation[_account][i];
        }

        return total;
    }
}