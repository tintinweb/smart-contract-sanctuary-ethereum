// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// imports
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Arrays.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

// Openluck interfaces
import {ILucksExecutor, TaskItem, TaskExt, TaskStatus, Ticket, TaskInfo, UserState } from "./interfaces/ILucksExecutor.sol";
import {IProxyNFTStation, DepositNFT} from "./interfaces/IProxyNFTStation.sol";
import {IProxyTokenStation} from "./interfaces/IProxyTokenStation.sol";
import {ILucksHelper} from "./interfaces/ILucksHelper.sol";
import {ILucksBridge, lzTxObj} from "./interfaces/ILucksBridge.sol";


/** @title Openluck LucksTrade.
 * @notice It is the core contract for crowd funds to buy NFTs result to one lucky winner
 * randomness provided externally.
 */
contract LucksExecutor is ILucksExecutor, ReentrancyGuardUpgradeable, OwnableUpgradeable {    
    using SafeMath for uint256;
    using Arrays for uint256[];
    using Counters for Counters.Counter;

    Counters.Counter private ids;

    // ============ Openluck interfaces ============
    ILucksHelper public HELPER;    
    IProxyNFTStation public NFT;
    IProxyTokenStation public TOKEN;
    ILucksBridge public BRIDGE;
    
    uint16 public lzChainId;
    bool public isAllowTask; // this network allow running task or not (ethereum & Rinkeby not allow)

    // ============ Public Mutable Storage ============

    // VARIABLES    
    mapping(uint256 => TaskItem) public tasks; // store tasks info by taskId    
    mapping(uint256 => TaskInfo) public infos; // store task updated info (taskId=>TaskInfo)
    mapping(uint256 => mapping(uint256 => Ticket)) public tickets; // store tickets (taskId => ticketId => ticket)    
    mapping(uint256 => uint256[]) public ticketIds; // store ticket ids (taskId => lastTicketIds)             
    mapping(address => mapping(uint256 => UserState)) public userState; // Keep track of user ticket ids for a given taskId (user => taskId => userstate)        
    
    // ======== Constructor =========

    /**
     * @notice Constructor / initialize
     * @param _chainId layerZero chainId
     * @param _allowTask allow running task
     */
    function initialize(uint16 _chainId, bool _allowTask) external initializer { 
        __ReentrancyGuard_init();
        __Ownable_init();
        lzChainId = _chainId;
        isAllowTask = _allowTask;
    }

    //  ============ Modifiers  ============

    // MODIFIERS
    modifier isExists(uint256 taskId) {
        require(exists(taskId), "Task not exists");
        _;
    }

    // ============ Public functions ============

    function count() public view override returns (uint256) {
        return ids.current();
    }

    function exists(uint256 taskId) public view override returns (bool) {
        return taskId > 0 && taskId <= ids.current();
    }

    function getTask(uint256 taskId) public view override returns (TaskItem memory) {
        return tasks[taskId];
    }

    function getInfo(uint256 taskId) public view override returns (TaskInfo memory) {
        return infos[taskId];
    }
    
    function isFail(uint256 taskId) public view override returns(bool) {
        return tasks[taskId].status == TaskStatus.Fail ||
            (tasks[taskId].amountCollected < tasks[taskId].targetAmount && block.timestamp > tasks[taskId].endTime);
    }

    function getChainId() external view override returns (uint16) {
        return lzChainId;
    }
    
    function createTask(TaskItem memory item, TaskExt memory ext, lzTxObj memory _param) external payable override nonReentrant {
        
        require(lzChainId == item.nftChainId, "Invalid chainId"); // action must start from NFTChain   
        require(address(NFT) != address(0), "ProxyNFT unset");

        // inputs validation
        HELPER.checkNewTask(msg.sender, item);
        HELPER.checkNewTaskExt(ext);        

        // adapt to CryptoPunks
        if (HELPER.isPunks(item.nftContract)) {

            item.depositId = HELPER.getProxyPunks().deposit(msg.sender, item.nftContract, item.tokenIds, item.tokenAmounts, item.endTime);
        }
        else {

            // Transfer nfts to proxy station (NFTChain) 
            // in case of dst chain transection fail, enable user redeem nft back, after endTime            
            item.depositId = NFT.deposit(msg.sender, item.nftContract, item.tokenIds, item.tokenAmounts, item.endTime);
        }
             
        // Create Task Item           
        if (ext.chainId == item.nftChainId) { // same chain creation    
            _createTask(item, ext);
        }
        else {
            // cross chain creation
            require(address(BRIDGE) != address(0), "Bridge unset");
            BRIDGE.sendCreateTask{value: msg.value}(ext.chainId, payable(msg.sender), item, ext, _param);
        }
    }

    function updateTaskNote(uint256 taskId, string memory note) external override isExists(taskId) {

        require(tasks[taskId].seller == msg.sender, "onlySeller");
        require(bytes(note).length >=0 && bytes(note).length <= 256, "Invalid note len");

        emit UpdateTaskNote(taskId, note);
    }

    /**
    @notice buyer join a task
    num: how many ticket
    */
    function joinTask(uint256 taskId, uint32 num, string memory note) external payable override isExists(taskId) nonReentrant 
    {
        // check inputs and task
        HELPER.checkJoinTask(msg.sender, taskId, num, note);

        // Calculate number of TOKEN to this contract
        uint256 amount = tasks[taskId].price.mul(num);

        // deposit payment to token station.        
        TOKEN.deposit{value: msg.value}(msg.sender, tasks[taskId].acceptToken, amount);

        // create tickets
        uint256 lastTID = _createTickets(taskId, num, msg.sender);

        // update task item info
        if (tasks[taskId].status == TaskStatus.Pending) {
            tasks[taskId].status = TaskStatus.Open; 
        }
        tasks[taskId].amountCollected = tasks[taskId].amountCollected.add(amount);

        //if reach target amount, trigger to close task
        if (tasks[taskId].amountCollected >= tasks[taskId].targetAmount) {
            if (address(HELPER.getAutoClose()) != address(0)) {
                HELPER.getAutoClose().addTask(taskId, tasks[taskId].endTime);
            }
        }

        emit JoinTask(taskId, msg.sender, amount, num, lastTID, note);
    }

    /**
    @notice seller cancel the task, only when task status equal to 'Pending' or no funds amount
    */
    function cancelTask(uint256 taskId, lzTxObj memory _param) external payable override isExists(taskId) nonReentrant 
    {                                
        require((tasks[taskId].status == TaskStatus.Pending || tasks[taskId].status == TaskStatus.Open) && infos[taskId].lastTID <= 0, "Opening or canceled");        
        require(tasks[taskId].seller == msg.sender, "Invalid auth"); // only seller can cancel
        
        // update status
        tasks[taskId].status = TaskStatus.Close;
        
        _withdrawNFTs(taskId, payable(tasks[taskId].seller), true, _param);

        emit CancelTask(taskId, msg.sender);
    }


    /**
    @notice finish a Task, 
    case 1: reach target crowd amount, status success, and start to pick a winner
    case 2: time out and not reach the target amount, status close, and returns funds to claimable pool
    */
    function closeTask(uint256 taskId, lzTxObj memory _param) external payable override isExists(taskId) nonReentrant 
    {        
        require(tasks[taskId].status == TaskStatus.Open, "Not Open");
        require(tasks[taskId].amountCollected >= tasks[taskId].targetAmount || block.timestamp > tasks[taskId].endTime, "Not reach target or not expired");

        // mark operation time
        infos[taskId].closeTime = block.timestamp;

        if (tasks[taskId].amountCollected >= tasks[taskId].targetAmount) {    
            // Reached task target        
            // update task, Task Close & start to draw
            tasks[taskId].status = TaskStatus.Close; 

            // Request a random number from the generator based on a seed(max ticket number)
            HELPER.getVRF().reqRandomNumber(taskId, infos[taskId].lastTID);

            // add to auto draw Queue
            if (address(HELPER.getAutoDraw()) != address(0)) {
                HELPER.getAutoDraw().addTask(taskId, block.timestamp + HELPER.getDrawDelay());
            }

            // cancel the auto close queue if seller open directly
             if (msg.sender == tasks[taskId].seller && address(HELPER.getAutoClose()) != address(0)) {
                HELPER.getAutoClose().removeTask(taskId);
            }

        } else {
            // Task Fail & Expired
            // update task
            tasks[taskId].status = TaskStatus.Fail; 

            // NFTs back to seller            
            _withdrawNFTs(taskId, payable(tasks[taskId].seller), false, _param);                            
        }

        emit CloseTask(taskId, msg.sender, tasks[taskId].status);
    }

    /**
    @notice start to picker a winner via chainlink VRF
    */
    function pickWinner(uint256 taskId, lzTxObj memory _param) external payable override isExists(taskId) nonReentrant
    {                
        require(tasks[taskId].status == TaskStatus.Close, "Not Close");
        // require(block.timestamp >= infos[taskId].closeTime + HELPER.getDrawDelay(), "Delay limit");
         
        // get drawn number from Chainlink VRF
        uint32 finalNo = HELPER.getVRF().viewRandomResult(taskId);
        require(finalNo > 0, "Not Drawn");
        require(finalNo <= infos[taskId].lastTID, "Invalid finalNo");

        // find winner by drawn number
        Ticket memory ticket = _findWinnerTicket(taskId, finalNo);    
        require(ticket.number > 0, "Lost winner");
        
        // update store item
        tasks[taskId].status = TaskStatus.Success;    
        infos[taskId].finalNo = ticket.number;          
        
        // withdraw NFTs to winner (maybe cross chain)         
        _withdrawNFTs(taskId, payable(ticket.owner), true, _param);

        // dispatch Payment
        _transferPayment(taskId, ticket.owner);    
        
        emit PickWinner(taskId, ticket.owner, finalNo);
    }


    /**
    @notice when taskItem Fail, user can claim tokens back 
    */
    function claimTokens(uint256[] memory taskIds) override external nonReentrant
    {
        for (uint256 i = 0; i < taskIds.length; i++) {
            _claimToken(taskIds[i]);
        }
    }

    /**
    @notice when taskItem Fail, user can claim NFTs back (cross-chain case)
    */
    function claimNFTs(uint256[] memory taskIds, lzTxObj memory _param) override external payable nonReentrant
    {  
        for (uint256 i = 0; i < taskIds.length; i++) {
            _claimNFTs(taskIds[i], _param);
        }
    }

    // ============ Remote(destination) functions ============
    
    function onLzReceive(uint8 functionType, bytes memory _payload) override external {
        require(msg.sender == address(BRIDGE), "Executor: onlyBridge");
        if (functionType == 1) { //TYPE_CREATE_TASK
            (, TaskItem memory item, TaskExt memory ext) = abi.decode(_payload, (uint256, TaskItem, TaskExt));
             _createTask(item, ext);
                    
        } else if (functionType == 2) { //TYPE_WITHDRAW_NFT
            (, address user, address nftContract, uint256 depositId) = abi.decode(_payload, (uint8, address, address, uint256));                        
            _doWithdrawNFTs(depositId, nftContract, user);
        }
    }    

    // ============ Internal functions ============

    /**
    @notice seller create a crowdluck task
    returns: new taskId
     */
    function _createTask(TaskItem memory item, TaskExt memory ext) internal 
    {        
        require(isAllowTask, "Not allow task");
        HELPER.checkNewTaskRemote(item);

        //create TaskId
        ids.increment();
        uint256 taskId = ids.current();

        // start now
        if (item.status == TaskStatus.Open) {
            item.startTime = item.startTime < block.timestamp ? item.startTime : block.timestamp;
        } else {
            require(block.timestamp <= item.startTime && item.startTime < item.endTime, "Invalid time range");
            // start in future
            item.status = TaskStatus.Pending;
        }

        //store taskItem
        tasks[taskId] = item;

        emit CreateTask(taskId, item, ext);
    }

    /**
     * @notice join task succes. create tickets for buyer
     * @param taskId task id
     * @param num how many ticket
     * @param buyer buery
     */
    function _createTickets(uint256 taskId, uint32 num, address buyer) internal returns (uint256) 
    {
        uint256 start = infos[taskId].lastTID.add(1);
        uint256 lastTID = start.add(num).sub(1);

        tickets[taskId][lastTID] = Ticket(lastTID, num, buyer);
        ticketIds[taskId].push(lastTID);

        userState[buyer][taskId].num += num;
        infos[taskId].lastTID = lastTID;

        emit CreateTickets(taskId, buyer, num, start, lastTID);
        return lastTID;
    }

    /**
     * @notice search a winner ticket by number
     * @param taskId task id
     * @param number final number
     */
    function _findWinnerTicket(uint256 taskId, uint32 number) internal view returns (Ticket memory)
    {
        // find by ticketId
        Ticket memory ticket = tickets[taskId][number];

        if (ticket.number == 0) {

            uint256 idx = ticketIds[taskId].findUpperBound(number);
            uint256 lastTID = ticketIds[taskId][idx];
            ticket = tickets[taskId][lastTID];
        }

        return ticket;
    }

    /**
    @notice when taskItem Fail, user can claim token back  
    */
    function _claimToken(uint256 taskId) internal isExists(taskId)
    {
        TaskItem memory item = tasks[taskId];
        require(isFail(taskId), "Not Fail");
        require(userState[msg.sender][taskId].claimed == false, "Claimed");

        // Calculate the funds buyer payed
        uint256 amount = item.price.mul(userState[msg.sender][taskId].num);
        
        // update claim info
        userState[msg.sender][taskId].claimed = true;
        
        // Transfer
        _transferOut(item.acceptToken, msg.sender, amount);

        emit ClaimToken(taskId, msg.sender, amount, item.acceptToken);
    }

    function _claimNFTs(uint256 taskId, lzTxObj memory _param) internal isExists(taskId)
    {
        address seller = tasks[taskId].seller;
        require(isFail(taskId), "Not Fail");
        require(userState[seller][taskId].claimed == false, "Claimed");
        
        // update claim info
        userState[seller][taskId].claimed = true;
        
        // withdraw NFTs to winner (maybe cross chain)     
        _withdrawNFTs(taskId, payable(seller), true, _param);

        emit ClaimNFT(taskId, seller, tasks[taskId].nftContract, tasks[taskId].tokenIds);
    }

    function _withdrawNFTs(uint256 taskId, address payable user, bool enableCrossChain, lzTxObj memory _param) internal
    {
        if (lzChainId == tasks[taskId].nftChainId) { // same chain    

           _doWithdrawNFTs(tasks[taskId].depositId, tasks[taskId].nftContract, user);
            
        }
        else if (enableCrossChain){ // cross chain            
            BRIDGE.sendWithdrawNFTs{value: msg.value}(tasks[taskId].nftChainId, payable(msg.sender), user,tasks[taskId].nftContract, tasks[taskId].depositId, _param);
        }
    }

    function _doWithdrawNFTs(uint256 depositId, address nftContract, address user) internal {
       
        // adapt to CryptoPunks
        if (HELPER.isPunks(nftContract)) {
             HELPER.getProxyPunks().withdraw(depositId, user);
        }
        else {
            NFT.withdraw(depositId, user);
        }
    }

    /**
     * @notice transfer protocol fee and funds
     * @param taskId taskId
     * @param winner winner address
     * paymentStrategy for winner share is up to 50% (500 = 5%, 5,000 = 50%)
     */
    function _transferPayment(uint256 taskId, address winner) internal
    {
        // inner variables
        address acceptToken = tasks[taskId].acceptToken;

        // Calculate amount to seller
        uint256 collected = tasks[taskId].amountCollected;
        uint256 sellerAmount = collected;

        // 1. Calculate protocol fee
        uint256 fee = (collected.mul(HELPER.getProtocolFee())).div(10000);
        address feeRecipient = HELPER.getProtocolFeeRecipient();
        require(fee >= 0, "Invalid fee");
        sellerAmount = sellerAmount.sub(fee);

        // 2. Calculate winner share amount with payment stragey (up to 50%)
        uint256 winnerAmount = 0;
        uint256 winnerShare = 0;
        uint256[] memory splitShare;
        address[] memory splitAddr;
        if (tasks[taskId].paymentStrategy > 0) {
            (winnerShare, splitShare, splitAddr) = HELPER.getSTRATEGY().viewPaymentShares(tasks[taskId].paymentStrategy, winner, taskId);
            require(winnerShare >= 0 && winnerShare <= 5000, "Invalid strategy");
            require(splitShare.length <= 10, "Invalid splitShare"); // up to 10 splitter
            if (winnerShare > 0) {
                winnerAmount = (collected.mul(winnerShare)).div(10000);
                sellerAmount = sellerAmount.sub(winnerAmount);
            }
        }
        
        // 3. transfer funds

        // transfer protocol fee
        _transferOut(acceptToken, feeRecipient, fee);
        emit TransferFee(taskId, feeRecipient, acceptToken, fee);     

        // transfer winner share
        if (winnerAmount > 0) {
            if (splitShare.length > 0 && splitShare.length == splitAddr.length) {  
                // split winner share for strategy case
                uint256 splited = 10000;                
                for (uint i=0; i < splitShare.length; i++) {   
                    // make sure spliter cannot overflow
                    if ((splited.sub(splitShare[i])) >=0 && splitShare[i] > 0) { 
                        uint256 splitAmount = (winnerAmount.mul(splitShare[i]).div(10000));
                        _transferOut(acceptToken, splitAddr[i], splitAmount);
                        splited = splited.sub(splitShare[i]);

                        emit TransferShareAmount(taskId, splitAddr[i], acceptToken, splitAmount); 
                    }
                }

                if (splited > 0) {
                    // if there's a remainder of splitShare, give it to the seller
                    sellerAmount = sellerAmount.add((winnerAmount.mul(splited).div(10000)));
                }
            }
            else {                
                _transferOut(acceptToken, winner, winnerAmount);

                emit TransferShareAmount(taskId, winner, acceptToken, winnerAmount); 
            }
        }    

        // transfer funds to seller
        _transferOut(acceptToken, tasks[taskId].seller, sellerAmount);  

        emit TransferPayment(taskId, tasks[taskId].seller, acceptToken, sellerAmount);                    
    }

    function _transferOut(address token, address to, uint256 amount) internal {        
        TOKEN.withdraw(to, token, amount);
    }    

    //  ============ onlyOwner  functions  ============

    function setAllowTask(bool enable) external onlyOwner {
        isAllowTask = enable;
    }

    function setLucksHelper(ILucksHelper addr) external onlyOwner {
        HELPER = addr;
    }

    function setBridgeAndProxy(ILucksBridge _bridge, IProxyTokenStation _token, IProxyNFTStation _nft) external onlyOwner {

        require(address(_bridge) != address(0x0), "Invalid BRIDGE");
        if (isAllowTask) {
            require(address(_token) != address(0x0), "Invalid TOKEN");
        }
        require(address(_nft) != address(0x0), "Invalid NFT");

        BRIDGE = _bridge;
        TOKEN = _token;
        NFT = _nft;
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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
// OpenZeppelin Contracts v4.4.1 (utils/Arrays.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev Collection of functions related to array types.
 */
library Arrays {
    /**
     * @dev Searches a sorted `array` and returns the first index that contains
     * a value greater or equal to `element`. If no such index exists (i.e. all
     * values in the array are strictly less than `element`), the array length is
     * returned. Time complexity O(log n).
     *
     * `array` is expected to be sorted in ascending order, and to contain no
     * repeated elements.
     */
    function findUpperBound(uint256[] storage array, uint256 element) internal view returns (uint256) {
        if (array.length == 0) {
            return 0;
        }

        uint256 low = 0;
        uint256 high = array.length;

        while (low < high) {
            uint256 mid = Math.average(low, high);

            // Note that mid will always be strictly less than high (i.e. it will be a valid array index)
            // because Math.average rounds down (it does integer division with truncation).
            if (array[mid] > element) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        // At this point `low` is the exclusive upper bound. We will return the inclusive upper bound.
        if (low > 0 && array[low - 1] == element) {
            return low - 1;
        } else {
            return low;
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
pragma solidity ^0.8.0;

import { lzTxObj } from "./ILucksBridge.sol";

/** 
    TaskStatus
    0) Pending: task created but not reach starttime
    1) Open: task opening
    2) Close: task close, waiting for draw
    3) Success: task reach target, drawed winner
    4) Fail: task Fail and expired
    5) Cancel: task user cancel
 */
enum TaskStatus {
    Pending,
    Open,
    Close,
    Success,
    Fail,
    Cancel
}

struct ExclusiveToken {
    address token; // exclusive token contract address    
    uint256 amount; // exclusive token holding amount required
}

struct TaskItem {

    address seller; // Owner of the NFTs
    uint16 nftChainId; // NFT source ChainId    
    address nftContract; // NFT registry address    
    uint256[] tokenIds; // Allow mulit nfts for sell    
    uint256[] tokenAmounts; // support ERC1155
    
    address acceptToken; // acceptToken    
    TaskStatus status; // Task status    

    uint256 startTime; // Task start time    
    uint256 endTime; // Task end time
    
    uint256 targetAmount; // Task target crowd amount (in wei) for the published item    
    uint256 price; // Per ticket price  (in wei)    
    
    uint16 paymentStrategy; // payment strategy;
    ExclusiveToken exclusiveToken; // exclusive token contract address    
    
    // editable fields
    uint256 amountCollected; // The amount (in wei) collected of this task
    uint256 depositId; // NFTs depositId (system set)
}

struct TaskExt {
    uint16 chainId; // Task Running ChainId   
    string title; // title (for searching keywords)  
    string note;   // memo
}

struct Ticket {
    uint256 number;  // the ticket's id, equal to the end number (last ticket id)
    uint32 count;   // how many QTY the ticket joins, (number-count+1) equal to the start number of this ticket.
    address owner;  // ticket owner
}

struct TaskInfo {
    uint256 lastTID;
    uint256 closeTime;
    uint256 finalNo;
}
 
struct UserState {
    uint256 num; // user buyed tickets count
    bool claimed;  // user claimed
}
interface ILucksExecutor {

    // ============= events ====================

    event CreateTask(uint256 taskId, TaskItem item, TaskExt ext);
    event CancelTask(uint256 taskId, address seller);
    event CloseTask(uint256 taskId, address caller, TaskStatus status);
    event JoinTask(uint256 taskId, address buyer, uint256 amount, uint256 count, uint256 number,string note);
    event PickWinner(uint256 taskId, address winner, uint256 number);
    event ClaimToken(uint256 taskId, address caller, uint256 amount, address acceptToken);
    event ClaimNFT(uint256 taskId, address seller, address nftContract, uint256[] tokenIds);    
    event CreateTickets(uint256 taskId, address buyer, uint256 num, uint256 start, uint256 end);
    event UpdateTaskNote(uint256 taskId, string note);

    event TransferFee(uint256 taskId, address to, address token, uint256 amount); // for protocol
    event TransferShareAmount(uint256 taskId, address to, address token, uint256 amount); // for winners
    event TransferPayment(uint256 taskId, address to, address token, uint256 amount); // for seller

    // ============= functions ====================

    function count() external view returns (uint256);
    function exists(uint256 taskId) external view returns (bool);
    function getTask(uint256 taskId) external view returns (TaskItem memory);
    function getInfo(uint256 taskId) external view returns (TaskInfo memory);
    function isFail(uint256 taskId) external view returns(bool);
    function getChainId() external view returns (uint16);

    function createTask(TaskItem memory item, TaskExt memory ext, lzTxObj memory _param) external payable;
    function updateTaskNote(uint256, string memory note) external;
    function joinTask(uint256 taskId, uint32 num, string memory note) external payable;
    function cancelTask(uint256 taskId, lzTxObj memory _param) external payable;
    function closeTask(uint256 taskId, lzTxObj memory _param) external payable;
    function pickWinner(uint256 taskId, lzTxObj memory _param) external payable;

    function claimTokens(uint256[] memory taskIds) external;
    function claimNFTs(uint256[] memory taskIds, lzTxObj memory _param) external payable;

    function onLzReceive(uint8 functionType, bytes memory _payload) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct DepositNFT {
    address user; // deposit user
    address nftContract; // NFT registry address    
    uint256[] tokenIds; // Allow mulit nfts for sell    
    uint256[] amounts; // support ERC1155
    uint256 endTime; // Task end time
}

interface IProxyNFTStation {

    event Deposit(address indexed executor, uint256 depositId, address indexed user, address nft, uint256[] tokenIds, uint256[] amounts, uint256 endTime);
    event Withdraw(address indexed executor, uint256 depositId, address indexed to, address nft, uint256[] tokenIds, uint256[] amounts);
    event Redeem(address indexed executor, uint256 depositId, address indexed to, address nft, uint256[] tokenIds, uint256[] amounts);

    function getNFT(address executor, uint256 depositId) external view returns(DepositNFT memory);
    function deposit(address user, address nft, uint256[] memory tokenIds, uint256[] memory amounts, uint256 endTime) external payable returns (uint256 depositId);    
    function withdraw(uint256 depositId, address to) external;    
    function redeem(address executor, uint256 depositId, address to) external;    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IProxyTokenStation {

    event Deposit(address indexed executor, address indexed user, address token, uint256 amount);
    event Withdraw(address indexed executor, address indexed user, address token, uint256 amount);

    function deposit(address user, address token, uint256 amount) external payable;
    function withdraw(address user, address token, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// OpenZeppelin contracts
import "@openzeppelin/contracts/access/Ownable.sol";

// Openluck interfaces
import {TaskItem, TaskExt} from "./ILucksExecutor.sol";
import {ILucksVRF} from "./ILucksVRF.sol";
import {ILucksGroup} from "./ILucksGroup.sol";
import {ILucksPaymentStrategy} from "./ILucksPaymentStrategy.sol";
import {ILucksAuto} from "./ILucksAuto.sol";
import {IPunks} from "./IPunks.sol";
import {IProxyNFTStation} from "./IProxyNFTStation.sol";

interface ILucksHelper {

    function checkPerJoinLimit(uint32 num) external view returns (bool);
    function checkAcceptToken(address acceptToken) external view returns (bool);
    function checkNFTContract(address addr) external view returns (bool);
    function checkNewTask(address user, TaskItem memory item) external view returns (bool);
    function checkNewTaskExt(TaskExt memory ext) external pure returns (bool);
    function checkNewTaskRemote(TaskItem memory item) external view returns (bool);
    function checkJoinTask(address user, uint256 taskId, uint32 num, string memory note) external view returns (bool);
    function checkTokenListing(address addr, address seller, uint256[] memory tokenIds, uint256[] memory amounts) external view returns (bool,string memory);    
    function checkExclusive(address account, address token, uint256 amount) external view returns (bool);
    function isPunks(address nftContract) external view returns(bool);

    function getProtocolFeeRecipient() external view returns (address);
    function getProtocolFee() external view returns (uint256);
    function getMinTargetLimit(address token) external view returns (uint256);
    function getDrawDelay() external view returns (uint32);

    function getVRF() external view returns (ILucksVRF);
    function getGROUPS() external view returns (ILucksGroup);
    function getSTRATEGY() external view returns (ILucksPaymentStrategy);
    function getAutoClose() external view returns (ILucksAuto);
    function getAutoDraw() external view returns (ILucksAuto);

    function getPunks() external view returns (IPunks);
    function getProxyPunks() external view returns (IProxyNFTStation);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// OpenLuck
import {TaskItem, TaskExt} from "./ILucksExecutor.sol";

struct lzTxObj {
    uint256 dstGasForCall;
    uint256 dstNativeAmount;
    bytes dstNativeAddr;
    bytes zroPaymentAddr; //  the address of the ZRO token holder who would pay for the transaction
}

interface ILucksBridge {
    // ============= events ====================
    event SendMsg(uint8 msgType, uint64 nonce);

    // ============= Task functions ====================

    function sendCreateTask(
        uint16 _dstChainId,
        address payable _refundAddress,
        TaskItem memory item,
        TaskExt memory ext,
        lzTxObj memory _lzTxParams
    ) external payable;

    function sendWithdrawNFTs(
        uint16 _dstChainId,
        address payable _refundAddress,
        address payable _user,
        address nftContract,
        uint256 depositId,
        lzTxObj memory _lzTxParams
    ) external payable;

    // ============= Assets functions ====================

    function quoteLayerZeroFee(
        uint16 _dstChainId,
        uint8 _functionType,
        string memory _note,
        lzTxObj memory _lzTxParams
    ) external view returns (uint256 nativeFee, uint256 zroFee);

    function estimateCreateTaskFee(
        uint16 _dstChainId,
        TaskItem memory item,
        TaskExt memory ext,
        lzTxObj memory _lzTxParams
    ) external view returns (uint256 nativeFee, uint256 zroFee);

    function estimateWithdrawNFTsFee(
        uint16 _dstChainId,
        address payable _user,
        address nftContract,
        uint256 depositId,
        lzTxObj memory _lzTxParams
    ) external view returns (uint256 nativeFee, uint256 zroFee);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
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
pragma solidity ^0.8.0;

interface ILucksVRF {

    event ReqRandomNumber(uint256 taskId, uint256 max, uint256 requestId);
    event RspRandomNumber(uint256 taskId, uint256 requestId, uint256 randomness, uint32 number);    

    /**
     * Requests randomness from a user-provided max
     */
    function reqRandomNumber(uint256 taskId, uint256 max) external;

    /**
     * Views random result
     */
    function viewRandomResult(uint256 taskId) external view returns (uint32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Openluck interfaces
import {ILucksExecutor, TaskItem, TaskStatus, Ticket} from "./ILucksExecutor.sol";
import {ILucksHelper} from "./ILucksHelper.sol";

interface ILucksGroup {    

    event JoinGroup(address user, uint256 taskId, uint256 groupId);
    event CreateGroup(address user, uint256 taskId, uint256 groupId, uint16 seat);     

    function getGroupUsers(uint256 taskId, address winner) view external returns (address[] memory);
   
    function joinGroup(uint256 taskId, uint256 groupId, uint16 seat) external;
    function createGroup(uint256 taskId, uint16 seat) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface ILucksPaymentStrategy {
    
    function getShareRate(uint16 strategyId) external pure returns (uint32);
    function viewPaymentShares(uint16 strategyId, address winner,uint256 taskId) external view returns (uint256, uint256[] memory, address[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct Task {
    uint256 endTime;
    uint256 lastTimestamp;
}

interface ILucksAuto {

    event FundsAdded(uint256 amountAdded, uint256 newBalance, address sender);
    event FundsWithdrawn(uint256 amountWithdrawn, address payee);

    event KeeperRegistryAddressUpdated(address oldAddress, address newAddress);    
    
    event RevertInvoke(uint256 taskId, string reason);

    function addTask(uint256 taskId, uint endTime) external;
    function removeTask(uint256 taskId) external;
    function getQueueTasks() external view returns (uint256[] memory);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Interface for a permittable ERC721 contract
 * See https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC72 allowance (see {IERC721-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC721-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IPunks {
  
  function balanceOf(address account) external view returns (uint256);

  function punkIndexToAddress(uint256 punkIndex) external view returns (address owner);

  function buyPunk(uint256 punkIndex) external;

  function transferPunk(address to, uint256 punkIndex) external;
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