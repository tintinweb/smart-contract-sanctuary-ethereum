// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./Ownable.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./Pausable.sol";
import "./IERC20.sol";

contract IFOPool is Ownable, Pausable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    struct UserInfo {
        uint256 shares; // number of shares for a user
        uint256 lastDepositedTime; // keeps track of deposited time for potential penalty
        uint256 xTcsAtLastUserAction; // keeps track of xTcs deposited at the last user action
        uint256 lastUserActionTime; // keeps track of the last user action time
    }
    //IFO
    struct UserIFOInfo {
        // ifo valid period is current block between startblock and endblock
        uint256 lastActionBalance; // staked xTcs numbers (not include compoud xTcs) at last action
        uint256 lastValidActionBalance; // staked xTcs numbers in ifo valid period
        uint256 lastActionBlock; //  last action block number 
        uint256 lastValidActionBlock; // last action block number in ifo valid period
        uint256 lastAvgBalance; // average balance in ifo valid period
    }

    enum IFOActions {Deposit, Withdraw}

    IERC20 public immutable token; // XTcs token

    mapping(address => UserInfo) public userInfo;
    //IFO
    mapping(address =>  UserIFOInfo) public userIFOInfo;

    uint256 public startBlock;
    uint256 public endBlock;

    address public admin;

    event Pause();
    event Unpause();
    event Deposit(address indexed sender, uint256 amount, uint256 shares, uint256 lastDepositedTime);
    event Withdraw(address indexed sender, uint256 amount, uint256 shares);

    event UpdateEndBlock(uint256 endBlock);
    event UpdateStartAndEndBlocks(uint256 startBlock, uint256 endBlock);
    event UpdateUserIFO(address indexed sender, uint256 lastAvgBalance, uint256 lastActionBalance, uint256 lastValidActionBalance, uint256 lastActionBlock, uint256 lastValidActionBlock);
    event ZeroFreeIFO(address indexed sender, uint256 currentBlock);
    
    /**
     * @notice Constructor
     * @param _token: XTcs token contract
     * @param _admin: address of the admin
     * @param _startBlock: IFO start block height
     * @param _endBlock: IFO end block height
     */
    constructor(
        IERC20 _token,
        address _admin,
        uint256 _startBlock,
        uint256 _endBlock
    ) public {
        require(block.number < _startBlock, "start block can't behind current block");
        require(_startBlock < _endBlock, "end block can't behind start block");

        token = _token;
        admin = _admin;
        startBlock = _startBlock;
        endBlock = _endBlock;
    }

    /**
     * @notice Checks if the msg.sender is the admin address
     */
    modifier onlyAdmin() {
        require(msg.sender == admin, "admin: wut?");
        _;
    }

    /**
     * @notice Checks if the msg.sender is a contract or a proxy
     */
    modifier notContract() {
        require(!_isContract(msg.sender), "contract not allowed");
        require(msg.sender == tx.origin, "proxy contract not allowed");
        _;
    }

    /**
     * @notice Deposits funds into the XTcs Vault
     * @dev Only possible when contract not paused.
     * @param _amount: number of tokens to deposit (in XTCS)
     */
    function deposit(uint256 _amount) external whenNotPaused notContract {
        require(_amount > 0, "Nothing to deposit");

        token.safeTransferFrom(msg.sender, address(this), _amount);

        UserInfo storage user = userInfo[msg.sender];
        
        user.shares = user.shares.add(_amount);
        user.lastDepositedTime = block.timestamp;

        user.xTcsAtLastUserAction = user.shares;
        user.lastUserActionTime = block.timestamp;
        //IFO
        _updateUserIFO(_amount, IFOActions.Deposit);


        emit Deposit(msg.sender, _amount, user.shares, block.timestamp);
    }

    /**
     * @notice check IFO is avaliable
     * @dev This function will be called that need to calculate average balance
     */
    function _isIFOAvailable() internal view returns(bool) {
        // actually block.number = startBlock is ifo available status
        // but the avgbalance must be zero, so we don't add this boundary
        return block.number > startBlock;
    }

    /**
     * @notice This function only be called to judge whether to update last action block.
     * @dev only block number between start block and end block to update last action block.
     */
    function _isValidActionBlock() internal view returns(bool) {
        return block.number >= startBlock && block.number <= endBlock;
    }

     /**
     * @notice calculate user IFO latest avgBalance.
     * @dev only calculate average balance when IFO is available, other return 0.
     * @param _lastActionBlock: last action(deposit/withdraw) block number.
     * @param _lastValidActionBlock: last valid action(deposit/withdraw) block number.
     * @param _lastActionBalance: last valid action(deposit/withdraw) block number.
     * @param _lastValidActionBalance: staked xTcs number at last action.
     * @param _lastAvgBalance: last average balance.
     */
    function _calculateAvgBalance(
        uint256  _lastActionBlock,
        uint256  _lastValidActionBlock, 
        uint256 _lastActionBalance, 
        uint256  _lastValidActionBalance, 
        uint256 _lastAvgBalance
) internal view returns(uint256 avgBalance) {
        uint256 currentBlock = block.number; //reused

        // (_lastActionBlock > endBlock) means lastavgbalance have updated after endblock,
        // subsequent action should not update lastavgbalance again
        if (_lastActionBlock >= endBlock){
            return _lastAvgBalance;
        }
        
        // first time participate current ifo
        if (_lastValidActionBlock < startBlock){
            _lastValidActionBlock = startBlock;
            _lastAvgBalance = 0;
            _lastValidActionBalance = _lastActionBalance;
        }

        currentBlock = currentBlock < endBlock ?  currentBlock : endBlock;

        uint256 lastContribute  = _lastAvgBalance.mul(_lastValidActionBlock.sub(startBlock));
        uint256 currentContribute  = _lastValidActionBalance.mul(currentBlock.sub(_lastValidActionBlock));
        avgBalance = (lastContribute.add(currentContribute)).div(currentBlock.sub(startBlock));
    }

    /**
     * @notice update userIFOInfo
     * @param _amount:the xTcs amount that need be add or sub
     * @param _action:IFOActions enum element
     */
    function _updateUserIFO(uint256 _amount, IFOActions _action) internal {
        UserIFOInfo storage IFOInfo = userIFOInfo[msg.sender];
        
        uint256 avgBalance = !_isIFOAvailable() ? 0 : _calculateAvgBalance(IFOInfo.lastActionBlock, IFOInfo.lastValidActionBlock, IFOInfo.lastActionBalance, IFOInfo.lastValidActionBalance, IFOInfo.lastAvgBalance);
        
        if (_action == IFOActions.Withdraw){
            IFOInfo.lastActionBalance = _amount > IFOInfo.lastActionBalance ? 0 : IFOInfo.lastActionBalance.sub(_amount);
        }else{
            IFOInfo.lastActionBalance = IFOInfo.lastActionBalance.add(_amount);
        }

        if (_isValidActionBlock()) {
             IFOInfo.lastValidActionBalance = IFOInfo.lastActionBalance;
             IFOInfo.lastValidActionBlock =  block.number;
        }
        
        IFOInfo.lastAvgBalance = avgBalance;
        IFOInfo.lastActionBlock = block.number;
        emit UpdateUserIFO(msg.sender, IFOInfo.lastAvgBalance, IFOInfo.lastActionBalance, IFOInfo.lastValidActionBalance, IFOInfo.lastActionBlock, IFOInfo.lastValidActionBlock);
    }

    /**
     * @notice calculate IFO latest average balance for specific user
     * @param _user: user address
     */
    function getUserCredit(address _user) external view returns(uint256 avgBalance) {
        UserIFOInfo storage IFOInfo = userIFOInfo[_user];
        
        if (_isIFOAvailable()){
            avgBalance = _calculateAvgBalance(IFOInfo.lastActionBlock, IFOInfo.lastValidActionBlock, IFOInfo.lastActionBalance, IFOInfo.lastValidActionBalance, IFOInfo.lastAvgBalance);
        }else{
             avgBalance = 0;   
        }
    }

    /**
     * @notice Withdraws all funds for a user
     */
    function withdrawAll() external notContract {
        withdraw(userInfo[msg.sender].shares);
    }

    /**
     * @notice Withdraws user all funds in emergency,it's called by user not admin,the userifo status will be clear
     */
    function emergencyWithdrawAll() external notContract {
        _zeroFreeIFO();
        withdrawV1(userInfo[msg.sender].shares);
    }

    /**
     * @notice set userIFOInfo to initial state
     */
    function _zeroFreeIFO() internal {
        UserIFOInfo storage IFOInfo = userIFOInfo[msg.sender];

        IFOInfo.lastActionBalance = 0;
        IFOInfo.lastValidActionBalance = 0;
        IFOInfo.lastActionBlock = 0;
        IFOInfo.lastValidActionBlock = 0;
        IFOInfo.lastAvgBalance = 0;
        
        emit ZeroFreeIFO(msg.sender, block.number);
    }
    //********************//*********************************************************????
    /**
     * @notice Withdraws from funds from the IFOPool
     * @param _shares: Number of shares to withdraw
     */
    function withdraw(uint256 _shares) public notContract {
        UserInfo storage user = userInfo[msg.sender];
        require(_shares > 0, "Nothing to withdraw");
        require(_shares <= user.shares, "Withdraw amount exceeds balance");

        uint256 ifoDeductAmount = _shares;
        user.shares = user.shares.sub(_shares);

        uint256 bal = balanceOf();
        if (bal < _shares) {
            _shares = bal;
        }


        if (user.shares > 0) {
            user.xTcsAtLastUserAction = user.shares;
        } else {
            user.xTcsAtLastUserAction = 0;
        }

        user.lastUserActionTime = block.timestamp;
        
        //IFO
        _updateUserIFO(ifoDeductAmount, IFOActions.Withdraw);

        token.safeTransfer(msg.sender, _shares);

        emit Withdraw(msg.sender, user.shares, _shares);
    }

    /**
     * @notice original Withdraws implementation from funds, the logic same as XTcs Vault withdraw
     * @notice this function visibility change to internal, call only be called by 'emergencyWithdrawAll' function
     * @param _shares: Number of shares to withdraw
     */
    function withdrawV1(uint256 _shares) internal {
        UserInfo storage user = userInfo[msg.sender];
        require(_shares > 0, "Nothing to withdraw");
        require(_shares <= user.shares, "Withdraw amount exceeds balance");

        user.shares = user.shares.sub(_shares);

        uint256 bal = balanceOf();
        if (bal < _shares) {
            _shares = bal;
        }

        if (user.shares > 0) {
            user.xTcsAtLastUserAction = user.shares;
        } else {
            user.xTcsAtLastUserAction = 0;
        }

        user.lastUserActionTime = block.timestamp;

        token.safeTransfer(msg.sender, _shares);

        emit Withdraw(msg.sender, user.shares, _shares);
    }

    /**
     * @notice Sets admin address
     * @dev Only callable by the contract owner.
     */
    function setAdmin(address _admin) external onlyOwner {
        require(_admin != address(0), "Cannot be zero address");
        admin = _admin;
    }

    /**
     * @notice It allows the admin to update start and end blocks
     * @dev This function is only callable by owner.
     * @param _startBlock: the new start block
     * @param _endBlock: the new end block
     */
    function updateStartAndEndBlocks(uint256 _startBlock, uint256 _endBlock) external onlyAdmin {
        require(block.number < _startBlock, "Pool current block must be lower than new startBlock");
        require(_startBlock < _endBlock, "New startBlock must be lower than new endBlock");

        startBlock = _startBlock;
        endBlock = _endBlock;

        emit UpdateStartAndEndBlocks(_startBlock, _endBlock);
    }

    /**
     * @notice It allows the admin to update end block
     * @dev This function is only callable by owner.
     * @param _endBlock: the new end block
     */
    function updateEndBlock(uint256 _endBlock) external onlyAdmin {
        require(block.number < _endBlock, "new end block can't behind current block");
        require(block.number < endBlock,  "old end block can't behind current block");

        endBlock = _endBlock;

        emit UpdateEndBlock(_endBlock);
    }


    /**
     * @notice Withdraw unexpected tokens sent to the XTcs Vault
     */
    function inCaseTokensGetStuck(address _token) external onlyAdmin {
        require(_token != address(token), "Token cannot be same as deposit token");

        uint256 amount = IERC20(_token).balanceOf(address(this));
        IERC20(_token).safeTransfer(msg.sender, amount);
    }

    /**
     * @notice Triggers stopped state
     * @dev Only possible when contract not paused.
     */
    function pause() external onlyAdmin whenNotPaused {
        _pause();
        emit Pause();
    }

    /**
     * @notice Returns to normal state
     * @dev Only possible when contract is paused.
     */
    function unpause() external onlyAdmin whenPaused {
        _unpause();
        emit Unpause();
    }


    /**
     * @notice Calculates the total underlying tokens
     * @dev It includes tokens held by the contract and held in MasterChef
     */
    function balanceOf() public view returns (uint256) {
        return token.balanceOf(address(this));
    }



    /**
     * @notice Checks if address is a contract
     * @dev It prevents contract from being targetted
     */
    function _isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }
}