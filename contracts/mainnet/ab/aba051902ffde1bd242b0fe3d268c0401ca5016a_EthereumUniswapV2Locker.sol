/**
 *Submitted for verification at Etherscan.io on 2022-10-22
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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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

// File: ca.sol

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

interface IMigrator {
    function migrate(
        address lockowner,
        address lpaddress,
        uint256 unlockdate,
        uint256 lockamount,
        uint256 lockid
    ) external;
}

interface IUniFactory {
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address);
}

interface IUniswapV2Router02 {
    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );
}

contract EthereumUniswapV2Locker {
    constructor(IUniFactory factory, IUniswapV2Router02 uniswaprouter) {
        owner = msg.sender;
        uniswapFactory = factory;
        uniswapRouter = uniswaprouter;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    struct newLock {
        address lockowner;
        address lpaddress;
        uint256 unlockdate;
        uint256 lockamount;
        uint256 lockid;
    }

    struct fastLock {
        address tokenaddress1;
        address tokenaddress2;
        uint256 amount1Desired;
        uint256 amount2Desired;
        uint256 amount1Min;
        uint256 amount2Min;
    }

    struct fastLockETH {
        address tokenaddress;
        address owner;
        uint256 amountTokenDesired;
        uint256 amountTokenMin;
        uint256 amountETHMin;
    }

    address owner;
    address payable devaddr;
    IUniswapV2Router02 public uniswapRouter;
    address _uniswapRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    IUniFactory public uniswapFactory;
    uint256 public Eth = 91330000000000000;
    address public delugeToken;
    uint256 public tokensToHold = 1000000;
    bool public paused;
    newLock[] public locks;
    uint256 public totalLocks;
    address public newContract;
    mapping(address => uint256[]) public ownerLocks;
    mapping(address => uint256[]) public tokenLocks;
    mapping(address => uint256) public approvedTimeFastLock;
    mapping(address => bool) public approvedFastBurn;
    event lpLocked(
        address indexed tokenaddress,
        uint256 amount,
        uint256 unlocktime,
        address indexed owner,
        uint256 indexed locknumber
    );
    event lpWithdrawn(
        address indexed tokenaddress,
        uint256 amount,
        address indexed owner,
        uint256 indexed locknumber
    );
    event newLPadded(uint256 indexed newLPamount, uint256 indexed locknumber);
    event lockExtended(uint256 indexed newTime, uint256 indexed locknumber);
    event ownerUpdated(address indexed newOwner, uint256 indexed locknumber);
    event lpBurnt(uint256 indexed locknumber, uint256 indexed lockamount);
    event lpFastBurnt(address indexed lptoken, uint256 indexed liquidity);
    event newTimeApproved(
        address indexed _address,
        uint256 indexed approvedTime
    );
    event fastBurnApproved(address indexed _address);

    function change(uint256 newEth) external onlyOwner {
        require(500000000000000000 >= newEth);
        Eth = newEth;
    }

    function changeTokenAddress(address newaddress) external onlyOwner {
        delugeToken = newaddress;
    }

    function changeNewContract(address newcontract) external onlyOwner {
        newContract = newcontract;
    }

    function changeaddress(address payable newaddress) external onlyOwner {
        devaddr = newaddress;
    }

    function changeTokensToHold(uint256 newamount) external onlyOwner {
        tokensToHold = newamount;
    }

    function pause() external onlyOwner {
        paused = true;
    }

    function unpause() external onlyOwner {
        paused = false;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        owner = newOwner;
    }

    function lockTokens(
        address token,
        uint256 amount,
        uint256 locktime,
        address _owner
    ) external payable returns (uint256 _lockNumber) {
        require(amount > 0);
        require(locktime > 3599);
        if (IERC20(delugeToken).balanceOf(msg.sender) < tokensToHold) {
            require(msg.value == Eth);
            devaddr.transfer(Eth);
        } else {
            require(msg.value == 0);
        }
        require(!paused);
        require(IERC20(token).allowance(msg.sender, address(this)) >= amount);

        uint256 oldBalance = IERC20(token).balanceOf(address(this));
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        uint256 newBalance = IERC20(token).balanceOf(address(this));
        require(oldBalance == newBalance - amount);

        uint256 newLockNumber = totalLocks + 1;
        totalLocks++;
        ownerLocks[_owner].push(newLockNumber);
        tokenLocks[token].push(newLockNumber);
        uint256 unlocktime = block.timestamp + locktime;

        newLock memory newlock;
        newlock.lockowner = _owner;
        newlock.lpaddress = token;
        newlock.unlockdate = unlocktime;
        newlock.lockamount = amount;
        newlock.lockid = newLockNumber;

        locks.push(newlock);

        emit lpLocked(token, amount, unlocktime, _owner, newLockNumber);
        return newLockNumber;
    }

    function withdrawLP(uint256 lockNumber) external {
        require(msg.sender == locks[lockNumber].lockowner);
        require(block.timestamp >= locks[lockNumber].unlockdate);
        require(locks[lockNumber].lockamount > 0);
        IERC20(locks[lockNumber].lpaddress).transfer(
            msg.sender,
            locks[lockNumber].lockamount
        );
        emit lpWithdrawn(
            locks[lockNumber].lpaddress,
            locks[lockNumber].lockamount,
            locks[lockNumber].lockowner,
            locks[lockNumber].lockid
        );
    }

    function addNewLP(uint256 locknumber, uint256 amount) external {
        require(amount > 0);
        require(locks[locknumber].unlockdate > block.timestamp);
        require(msg.sender == locks[locknumber].lockowner);
        require(
            IERC20(locks[locknumber].lpaddress).allowance(
                msg.sender,
                address(this)
            ) >= amount
        );
        IERC20(locks[locknumber].lpaddress).transferFrom(
            msg.sender,
            address(this),
            amount
        );
        locks[locknumber].lockamount = locks[locknumber].lockamount + amount;
        emit newLPadded(amount, locknumber);
    }

    function extendLock(uint256 locknumber, uint256 newunlocktime) external {
        require(locks[locknumber].unlockdate > block.timestamp);
        require(msg.sender == locks[locknumber].lockowner);
        require(newunlocktime > locks[locknumber].unlockdate);
        locks[locknumber].unlockdate = newunlocktime;
        emit lockExtended(newunlocktime, locknumber);
    }

    function updateOwner(uint256 locknumber, address newowner) external {
        require(locks[locknumber].unlockdate > block.timestamp);
        require(msg.sender == locks[locknumber].lockowner);
        require(newowner != locks[locknumber].lockowner);
        locks[locknumber].lockowner = newowner;
        emit ownerUpdated(newowner, locknumber);
    }

    function burnLP(uint256 locknumber) external {
        require(msg.sender == locks[locknumber].lockowner);
        uint256 lockamount = locks[locknumber].lockamount;
        locks[locknumber].lockamount = 0;
        IERC20(locks[locknumber].lpaddress).transfer(address(0), lockamount);
        emit lpBurnt(locknumber, lockamount);
    }

    function approveCustomTime(uint256 approveTime) external {
        approvedTimeFastLock[msg.sender] = approveTime;
        emit newTimeApproved(msg.sender, approveTime);
    }

    function approve365DaysLock() external {
        approvedTimeFastLock[msg.sender] = 31536000;
        emit newTimeApproved(msg.sender, 31536000);
    }

    function approve180DaysLock() external {
        approvedTimeFastLock[msg.sender] = 15552000;
        emit newTimeApproved(msg.sender, 15552000);
    }

    function approve90DaysLock() external {
        approvedTimeFastLock[msg.sender] = 7776000;
        emit newTimeApproved(msg.sender, 7776000);
    }

    function approve30DaysLock() external {
        approvedTimeFastLock[msg.sender] = 2592000;
        emit newTimeApproved(msg.sender, 2592000);
    }

    function approve15DaysLock() external {
        approvedTimeFastLock[msg.sender] = 1296000;
        emit newTimeApproved(msg.sender, 1296000);
    }

    function approve7DaysLock() external {
        approvedTimeFastLock[msg.sender] = 604800;
        emit newTimeApproved(msg.sender, 604800);
    }

    function approve1DayLock() external {
        approvedTimeFastLock[msg.sender] = 86400;
        emit newTimeApproved(msg.sender, 86400);
    }

    function approveFastBurnLP() external {
        approvedFastBurn[msg.sender] = true;
        emit fastBurnApproved(msg.sender);
    }

    function fastLockLpWithTokens(
        address tokenaddress1,
        address tokenaddress2,
        uint256 amount1Desired,
        uint256 amount2Desired,
        uint256 amount1Min,
        uint256 amount2Min,
        address _owner
    ) public payable returns (uint256 _lockNumber) {
        require(!paused);
        require(amount1Desired > 0 && amount2Desired > 0);
        require(
            IERC20(tokenaddress1).allowance(msg.sender, address(this)) >=
                amount1Desired
        );
        require(
            IERC20(tokenaddress2).allowance(msg.sender, address(this)) >=
                amount2Desired
        );
        require(approvedTimeFastLock[msg.sender] > 3599);
        if (IERC20(delugeToken).balanceOf(msg.sender) < tokensToHold) {
            require(msg.value == Eth);
            devaddr.transfer(Eth);
        } else {
            require(msg.value == 0);
        }

        fastLock memory fastlock;
        fastlock.tokenaddress1 = tokenaddress1;
        fastlock.tokenaddress2 = tokenaddress2;
        fastlock.amount1Desired = amount1Desired;
        fastlock.amount2Desired = amount2Desired;
        fastlock.amount1Min = amount1Min;
        fastlock.amount2Min = amount2Min;

        uint256 oldBalance1 = IERC20(tokenaddress1).balanceOf(address(this));
        uint256 oldBalance2 = IERC20(tokenaddress2).balanceOf(address(this));
        IERC20(tokenaddress1).transferFrom(
            msg.sender,
            address(this),
            amount1Desired
        );
        IERC20(tokenaddress2).transferFrom(
            msg.sender,
            address(this),
            amount2Desired
        );
        uint256 newBalance1 = IERC20(tokenaddress1).balanceOf(address(this));
        uint256 newBalance2 = IERC20(tokenaddress2).balanceOf(address(this));
        require(
            oldBalance1 == newBalance1 - amount1Desired &&
                oldBalance2 == newBalance2 - amount2Desired
        );

        IERC20(fastlock.tokenaddress1).approve(_uniswapRouter, amount1Desired);
        IERC20(fastlock.tokenaddress2).approve(_uniswapRouter, amount2Desired);
        (, , uint256 liquidity) = uniswapRouter.addLiquidity(
            fastlock.tokenaddress1,
            fastlock.tokenaddress2,
            fastlock.amount1Desired,
            fastlock.amount2Desired,
            fastlock.amount1Min,
            fastlock.amount2Min,
            address(this),
            block.timestamp
        );

        if (IERC20(tokenaddress1).balanceOf(address(this)) > oldBalance1) {
            IERC20(tokenaddress1).transfer(
                msg.sender,
                IERC20(fastlock.tokenaddress1).balanceOf(address(this)) -
                    oldBalance1
            );
        }

        if (IERC20(tokenaddress2).balanceOf(address(this)) > oldBalance2) {
            IERC20(tokenaddress2).transfer(
                msg.sender,
                IERC20(fastlock.tokenaddress2).balanceOf(address(this)) -
                    oldBalance2
            );
        }

        address lptoken = uniswapFactory.getPair(
            fastlock.tokenaddress1,
            fastlock.tokenaddress2
        );

        uint256 locktime = approvedTimeFastLock[msg.sender];
        approvedTimeFastLock[msg.sender] = 0;
        uint256 unlocktime = block.timestamp + locktime;

        uint256 newLockNumber = totalLocks + 1;
        totalLocks++;
        ownerLocks[_owner].push(newLockNumber);
        tokenLocks[lptoken].push(newLockNumber);

        newLock memory newlock;
        newlock.lockowner = _owner;
        newlock.lpaddress = lptoken;
        newlock.unlockdate = unlocktime;
        newlock.lockamount = liquidity;
        newlock.lockid = newLockNumber;

        locks.push(newlock);

        emit lpLocked(lptoken, liquidity, unlocktime, _owner, newLockNumber);
        return newLockNumber;
    }

    function fastLockLPWithETH(
        address tokenaddress,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address _owner
    ) public payable returns (uint256 _lockNumber) {
        require(!paused);
        require(amountTokenDesired > 0);
        require(
            IERC20(tokenaddress).allowance(msg.sender, address(this)) >=
                amountTokenDesired
        );
        require(approvedTimeFastLock[msg.sender] > 3599);
        uint256 ETHForLP;
        if (IERC20(delugeToken).balanceOf(msg.sender) < tokensToHold) {
            require(msg.value > Eth);
            devaddr.transfer(Eth);
            ETHForLP = msg.value - Eth;
        } else {
            ETHForLP = msg.value;
        }

        fastLockETH memory fastlocketh;
        fastlocketh.tokenaddress = tokenaddress;
        fastlocketh.owner = _owner;
        fastlocketh.amountTokenDesired = amountTokenDesired;
        fastlocketh.amountTokenMin = amountTokenMin;
        fastlocketh.amountETHMin = amountETHMin;

        uint256 oldBalance = IERC20(tokenaddress).balanceOf(address(this));
        IERC20(tokenaddress).transferFrom(
            msg.sender,
            address(this),
            amountTokenDesired
        );
        uint256 newBalance = IERC20(tokenaddress).balanceOf(address(this));
        require(oldBalance == newBalance - amountTokenDesired);

        address payable msgsender = payable(msg.sender);

        uint256 oldBalanceETH = address(this).balance - ETHForLP;
        IERC20(tokenaddress).approve(_uniswapRouter, amountTokenDesired);
        (, , uint256 liquidity) = uniswapRouter.addLiquidityETH{
            value: ETHForLP
        }(
            fastlocketh.tokenaddress,
            fastlocketh.amountTokenDesired,
            fastlocketh.amountTokenMin,
            fastlocketh.amountETHMin,
            address(this),
            block.timestamp
        );
        uint256 newBalanceETH = address(this).balance;
        if (newBalanceETH > oldBalanceETH) {
            msgsender.transfer(newBalanceETH - oldBalanceETH);
        }

        if (IERC20(tokenaddress).balanceOf(address(this)) > oldBalance) {
            IERC20(tokenaddress).transfer(
                msg.sender,
                IERC20(fastlocketh.tokenaddress).balanceOf(address(this)) -
                    oldBalance
            );
        }

        address lptoken = uniswapFactory.getPair(
            fastlocketh.tokenaddress,
            0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
        );

        uint256 locktime = approvedTimeFastLock[msg.sender];
        approvedTimeFastLock[msg.sender] = 0;
        uint256 unlocktime = block.timestamp + locktime;

        uint256 newLockNumber = totalLocks + 1;
        totalLocks++;
        ownerLocks[fastlocketh.owner].push(newLockNumber);
        tokenLocks[lptoken].push(newLockNumber);

        newLock memory newlock;
        newlock.lockowner = _owner;
        newlock.lpaddress = lptoken;
        newlock.unlockdate = unlocktime;
        newlock.lockamount = liquidity;
        newlock.lockid = newLockNumber;

        locks.push(newlock);

        emit lpLocked(lptoken, liquidity, unlocktime, _owner, newLockNumber);
        return newLockNumber;
    }

    function fastBurnLPWithETH(
        address tokenaddress,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin
    ) public payable {
        require(!paused);
        require(amountTokenDesired > 0);
        require(
            IERC20(tokenaddress).allowance(msg.sender, address(this)) >=
                amountTokenDesired
        );
        uint256 ETHForLP;
        if (IERC20(delugeToken).balanceOf(msg.sender) < tokensToHold) {
            require(msg.value > Eth);
            devaddr.transfer(Eth);
            ETHForLP = msg.value - Eth;
        } else {
            ETHForLP = msg.value;
        }
        require(approvedFastBurn[msg.sender] == true);

        uint256 oldBalance = IERC20(tokenaddress).balanceOf(address(this));
        IERC20(tokenaddress).transferFrom(
            msg.sender,
            address(this),
            amountTokenDesired
        );
        uint256 newBalance = IERC20(tokenaddress).balanceOf(address(this));
        require(oldBalance == newBalance - amountTokenDesired);

        address payable msgsender = payable(msg.sender);

        uint256 oldBalanceETH = address(this).balance - ETHForLP;
        IERC20(tokenaddress).approve(_uniswapRouter, amountTokenDesired);
        (, , uint256 liquidity) = uniswapRouter.addLiquidityETH{
            value: ETHForLP
        }(
            tokenaddress,
            amountTokenDesired,
            amountTokenMin,
            amountETHMin,
            address(0),
            block.timestamp
        );
        uint256 newBalanceETH = address(this).balance;
        if (newBalanceETH > oldBalanceETH) {
            msgsender.transfer(newBalanceETH - oldBalanceETH);
        }

        if (IERC20(tokenaddress).balanceOf(address(this)) > oldBalance) {
            IERC20(tokenaddress).transfer(
                msg.sender,
                IERC20(tokenaddress).balanceOf(address(this)) - oldBalance
            );
        }

        address lptoken = uniswapFactory.getPair(
            tokenaddress,
            0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
        );
        approvedFastBurn[msg.sender] = false;

        emit lpFastBurnt(lptoken, liquidity);
    }

    function fastBurnLpWithTokens(
        address tokenaddress1,
        address tokenaddress2,
        uint256 amount1Desired,
        uint256 amount2Desired,
        uint256 amount1Min,
        uint256 amount2Min
    ) public payable {
        require(!paused);
        require(amount1Desired > 0 && amount2Desired > 0);
        require(
            IERC20(tokenaddress1).allowance(msg.sender, address(this)) >=
                amount1Desired
        );
        require(
            IERC20(tokenaddress2).allowance(msg.sender, address(this)) >=
                amount2Desired
        );
        require(approvedFastBurn[msg.sender] == true);
        if (IERC20(delugeToken).balanceOf(msg.sender) < tokensToHold) {
            require(msg.value == Eth);
            devaddr.transfer(Eth);
        } else {
            require(msg.value == 0);
        }

        uint256 oldBalance1 = IERC20(tokenaddress1).balanceOf(address(this));
        uint256 oldBalance2 = IERC20(tokenaddress2).balanceOf(address(this));
        IERC20(tokenaddress1).transferFrom(
            msg.sender,
            address(this),
            amount1Desired
        );
        IERC20(tokenaddress2).transferFrom(
            msg.sender,
            address(this),
            amount2Desired
        );
        uint256 newBalance1 = IERC20(tokenaddress1).balanceOf(address(this));
        uint256 newBalance2 = IERC20(tokenaddress2).balanceOf(address(this));
        require(
            oldBalance1 == newBalance1 - amount1Desired &&
                oldBalance2 == newBalance2 - amount2Desired
        );

        IERC20(tokenaddress1).approve(_uniswapRouter, amount1Desired);
        IERC20(tokenaddress2).approve(_uniswapRouter, amount2Desired);
        (, , uint256 liquidity) = uniswapRouter.addLiquidity(
            tokenaddress1,
            tokenaddress2,
            amount1Desired,
            amount2Desired,
            amount1Min,
            amount2Min,
            address(0),
            block.timestamp
        );

        if (IERC20(tokenaddress1).balanceOf(address(this)) > oldBalance1) {
            IERC20(tokenaddress1).transfer(
                msg.sender,
                IERC20(tokenaddress1).balanceOf(address(this)) - oldBalance1
            );
        }

        if (IERC20(tokenaddress2).balanceOf(address(this)) > oldBalance2) {
            IERC20(tokenaddress2).transfer(
                msg.sender,
                IERC20(tokenaddress2).balanceOf(address(this)) - oldBalance2
            );
        }

        address lptoken = uniswapFactory.getPair(tokenaddress1, tokenaddress2);

        approvedFastBurn[msg.sender] = false;
        emit lpFastBurnt(lptoken, liquidity);
    }

    function migrateLock(uint256 lockNumber) external {
        require(msg.sender == locks[lockNumber].lockowner);
        IERC20(locks[lockNumber].lpaddress).approve(
            newContract,
            locks[lockNumber].lockamount
        );
        IMigrator(newContract).migrate(
            locks[lockNumber].lockowner,
            locks[lockNumber].lpaddress,
            locks[lockNumber].unlockdate,
            locks[lockNumber].lockamount,
            lockNumber
        );
    }

    function getLocksByOwnerAddress(address addr)
        external
        view
        returns (uint256[] memory)
    {
        return ownerLocks[addr];
    }

    function getUserApprovedFastBurn(address addr)
        external
        view
        returns (bool)
    {
        return approvedFastBurn[addr];
    }

    function getUserApprovedFastLock(address addr)
        external
        view
        returns (uint256)
    {
        return approvedTimeFastLock[addr];
    }

    function getLocksByTokenAddress(address addr)
        external
        view
        returns (uint256[] memory)
    {
        return tokenLocks[addr];
    }

    function getLockInfo(uint256 lockNumber)
        external
        view
        returns (
            address lockowner,
            address lpaddress,
            uint256 unlockdate,
            uint256 lockamount
        )
    {
        (lockowner) = locks[lockNumber].lockowner;
        (lpaddress) = locks[lockNumber].lpaddress;
        (unlockdate) = locks[lockNumber].unlockdate;
        (lockamount) = locks[lockNumber].lockamount;
    }
}