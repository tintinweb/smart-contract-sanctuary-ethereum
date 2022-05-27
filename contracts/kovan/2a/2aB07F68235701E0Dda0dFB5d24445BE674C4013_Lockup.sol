// contracts/NFT.sol
// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.0;

library SafeMath {

    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }


    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }


    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }


    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

 
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) { 
        uint256 size; assembly { size := extcodesize(account) } return size > 0;
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");(bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
        
    }
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
        
    }
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
        
    }
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) { return returndata; } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {revert(errorMessage);}
        }
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {return msg.sender;}
    function _msgData() internal view virtual returns (bytes calldata) {this; return msg.data;}
}

abstract contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }   
    
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }


   function getTime() public view returns (uint256) {
        return block.timestamp;
    }

}

interface IPancakeV2Factory {
       event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IPancakeV2Router {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    
}


interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

interface IERC165 {
     function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IGuarantNFT is IERC165 {

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function setApprovalForAll(address operator, bool _approved) external;

    function getApproved(uint256 tokenId) external view returns (address operator);

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function createToken(address recipient) external returns (uint256);
}


contract Lockup is Ownable {
    using SafeMath for uint256;
    using Address for address;

    IERC20 public stakingToken;
    IGuarantNFT public NFToken;
    uint256 public totalSupply;

    uint256 public distributionPeriod = 10;

    uint256 public rewardPoolBalance = 10000000000;

    // balance of this contract should be bigger than thresholdMinimum
    uint256 public thresholdMinimum;

    // default divisor is 6
    uint8 public divisor = 6;

    uint8 public rewardClaimInterval = 12;

    uint256 public totalStaked;     // current total staked value

    uint8 public claimFee = 100; // the default claim fee is 10

    address treasureWallet;
    uint256 public claimFeeAmount;
    // when cliamFeeAmount arrives at claimFeeAmountLimit, the values of claimFeeAmount will be transfered (for saving gas fee)
    uint256 public claimFeeAmountLimit;   

    address deadAddress = 0x000000000000000000000000000000000000dEaD;
    address rewardWallet;

    // this is similar to `claimFeeAmountLimit` (for saving gas fee)
    uint256 public irreversibleAmountLimit;
    uint256 public irreversibleAmount;

    uint256 minInterval = 6 hours;

    struct StakeInfo {
        int128 duration;  // -1: irreversible, others: reversible (0, 30, 90, 180, 365 days which means lock periods)
        uint256 amount; // staked amount
        uint256 stakedTime; // initial staked time
        uint256 lastClaimed; // last claimed time
        uint256 blockListIndex; // blockList id which is used in calculating rewards
        bool available;     // if diposit, true: if withdraw, false
        string name;    // unique id of the stake
        uint256 NFTId;
    }

    // this will be updated whenever new stake or lock processes
    struct BlockInfo {
        uint256 blockNumber;      
        uint256 totalStaked;      // this is used for calculating reward.
    }

    mapping(bytes32 => StakeInfo) public stakedUserList;
    mapping (address => bytes32[]) public userInfoList; // container of user's id
    BlockInfo[] public blockList;

    IPancakeV2Router public router;
    address public pair;

    uint256 initialTime;        // it has the block time when first deposit in this contract (used for calculating rewards)

    event Deposit(address indexed user, string name, uint256 amount);
    event Withdraw(address indexed user, string name, uint256 amount);
    event Compound(address indexed user, string name, uint256 amount);
    event NewDeposit(address indexed user, string name, uint256 amount);
    event SendToken(address indexed token, address indexed sender, uint256 amount);
    event ClaimReward(address indexed user, uint256 amount);

    constructor (
        IERC20 _stakingToken,
        IGuarantNFT _NFTAddress
    ) {
        stakingToken = _stakingToken;
        NFToken = _NFTAddress;
        totalSupply = uint256(IERC20Metadata(address(stakingToken)).totalSupply());
        // IPancakeV2Router _newPancakeRouter = IPancakeV2Router(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        IPancakeV2Router _newPancakeRouter = IPancakeV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        router = _newPancakeRouter;

        // default is 10000 amount of tokens
        claimFeeAmountLimit = 10000 * 10 ** IERC20Metadata(address(stakingToken)).decimals();
        irreversibleAmountLimit = 10000 * 10 ** IERC20Metadata(address(stakingToken)).decimals();
        thresholdMinimum = 10 ** 11 * 10 ** IERC20Metadata(address(stakingToken)).decimals();

        // for test
        pair = IPancakeV2Factory(router.factory()).getPair(address(stakingToken), 0x9b6AFC6f69C556e2CBf79fbAc1cb19B75E6B51E2);
        if (pair == address(0)) {
            pair = IPancakeV2Factory(router.factory()).createPair(
                address(stakingToken), // Token
                0x9b6AFC6f69C556e2CBf79fbAc1cb19B75E6B51E2 // USDC
            );
        }

        IERC20Metadata(address(stakingToken)).approve(address(router), 999999999999999999999999);
        IERC20Metadata(0x9b6AFC6f69C556e2CBf79fbAc1cb19B75E6B51E2).approve(address(router), 999999999999999999999999); // USDC
        IERC20Metadata(address(_newPancakeRouter.WETH())).approve(address(router), 999999999999999999999999); // USDC
    }
    
    // pri#
    function string2byte32(string memory name) public pure returns(bytes32) {
        return keccak256(abi.encodePacked(name));
    }

    // check if the given name is unique id
    function isExistStakeId(string memory name) public view returns (bool) {
        return stakedUserList[string2byte32(name)].available;
    }

    // change Reward Poll Pool Balance but in case of only owner
    function setRewardPoolBalance(uint256 _balance) external onlyOwner {
        rewardPoolBalance = _balance;
    }

    function setTreasuryWallet(address walletAddr) external onlyOwner {
        treasureWallet = walletAddr;
    }

    function setClaimFeeAmountLimit(uint256 val) external onlyOwner {
        claimFeeAmountLimit = val * 10 ** IERC20Metadata(address(stakingToken)).decimals();
    }

    function setIrreversibleAmountLimit(uint256 val) external onlyOwner {
        irreversibleAmountLimit = val * 10 ** IERC20Metadata(address(stakingToken)).decimals();
    }

    function setDistributionPeriod(uint256 _period) external onlyOwner {
        distributionPeriod = _period;
    }

    function setDivisor (uint8 _divisor) external onlyOwner {
        divisor = _divisor;
    }

    //for test
    function setMinInterval (uint256 interval) public onlyOwner {
        minInterval = interval * 1 minutes;
    }

    function setRewardInterval (uint8 _interval) external onlyOwner {
        require(_interval >= 6, "_interval should be bigger than 6");
        require(_interval % 6 == 0, "_interval should be multipler of 6");
        rewardClaimInterval = _interval;
    }

    function setClaimFee(uint8 fee) external onlyOwner {
        claimFee = fee;
    }

    // send tokens out inside this contract into any address. 
    // when the specified token is stake token, the minmum value should be equal or bigger than thresholdMinimum amount.
    function sendToken (address token, address sender, uint256 amount) external onlyOwner {
        if(address(stakingToken) == token) {
            require(uint256(IERC20Metadata(token).balanceOf(address(this))) - amount >= thresholdMinimum, "Token balance should be bigger than thresholdMinimum");
        }
        IERC20Metadata(address(token)).transfer(sender, amount);
        emit SendToken(token, sender, amount);
    }

    // update the blockList table
    // when deposit, totalStaked increases; when withdraw, totalStaked decreases (if isPush is true this is deposit mode, or else withdraw)
    // pri#
    function updateBlockList(uint256 amount, bool isPush) public {
        uint256 len = blockList.length;
        if(isPush) totalStaked = totalStaked.add(amount);
        else       totalStaked = totalStaked.sub(amount);

        uint256 time = block.timestamp;

        time = time - (time - initialTime) % minInterval;

        if(len == 0) {
            blockList.push(BlockInfo({
                blockNumber : time,
                totalStaked : totalStaked
            }));
        } else {
            // when the reward is not accumulated yet
            if((time - blockList[len-1].blockNumber) / minInterval == 0) { 
                blockList[len-1].totalStaked = totalStaked;
            } else {
                blockList.push(BlockInfo({
                    blockNumber : time,
                    totalStaked : totalStaked
                }));
            }
        }
    }

    // when staked, new StakeInfo is added: when withdraw this stakeInfo is no available anymore (avaliable = false)
    // pri#
    function updateStakedList(string memory name, int128 duration, uint256 amount, bool available) public {
        bytes32 key = string2byte32(name); 
        StakeInfo storage info = stakedUserList[key];
        info.available = available;
        if(!available) return; // when withdraw mode

        uint256 time = block.timestamp;
        time = time - (time - initialTime) % minInterval;

        info.amount = info.amount.add(amount);
        info.blockListIndex = blockList.length - 1;
        info.stakedTime = block.timestamp;
        info.lastClaimed = time;
        info.duration = duration;
        info.name = name;
    }

    // update the user list table
    // pri#
    function updateUserList(string memory name, bool isPush) public {
        bytes32 key = string2byte32(name);
        if(isPush)
            userInfoList[_msgSender()].push(key);
        else {
            // remove user id from the userList
            for (uint256 i = 0; i < userInfoList[_msgSender()].length; i++) {
                if (userInfoList[_msgSender()][i] == key) {
                    userInfoList[_msgSender()][i] = userInfoList[_msgSender()][userInfoList[_msgSender()].length - 1];
                    userInfoList[_msgSender()].pop();
                    break;
                }
            }
        }
    }

    function deposit(string memory name, int128 duration, uint256 amount) public {
        require(amount > 0, "amount should be bigger than zero!");
        require(!isExistStakeId(name), "This id is already existed!");

        if(initialTime == 0) {
            initialTime = block.timestamp;
        }

        updateBlockList(amount, true);
        updateStakedList(name, duration, amount, true);
        updateUserList(name, true);

        if(duration == -1) {    //irreversible mode
            dealWithIrreversibleAmount(amount, name);
        } else {
            IERC20Metadata(address(stakingToken)).transferFrom(_msgSender(), address(this), amount);
        }
        emit Deposit(_msgSender(), name, amount);
    }

    function withdraw(string memory name) public {
        require(isExistStakeId(name), "This doesn't existed!");
        require(isWithDrawable(name), "Lock period is not expired!");

        // when user withdraws the amount, the accumulated reward should be refunded
        _claimReward(name, true);
        uint256 amount = stakedUserList[string2byte32(name)].amount;
        updateBlockList(amount, false);
        updateStakedList(name, 0, 0, false);
        updateUserList(name, false);
        IERC20Metadata(address(stakingToken)).transfer(_msgSender(), amount);
        emit Withdraw(_msgSender(), name, amount);
    }

    function getBoost(int128 duration) internal pure returns (uint8) {
        if (duration < 0) return 10;      // irreversable
        else if (duration < 30) return 1;   // no lock
        else if (duration < 60) return 2;   // more than 1 month
        else if (duration < 90) return 3;   // more than 3 month
        else if (duration < 360) return 4;  // more than 6 month
        else return 5;                      // more than 12 month
    }

    // *pri for test
    function dealWithIrreversibleAmount(uint256 amount, string memory name) public {
        // for saving gas fee
        if(irreversibleAmount + amount > irreversibleAmountLimit) {
            uint256 deadAmount = (irreversibleAmount + amount) / 5;
            IERC20Metadata(address(stakingToken)).transfer(deadAddress, deadAmount);
            uint256 usdcAmount = (irreversibleAmount + amount) / 5;
            uint256 nativeTokenAmount = (irreversibleAmount + amount) * 3 / 10;
            uint256 rewardAmount = (irreversibleAmount + amount) * 3 / 10;
            swapTokensForUSDC(usdcAmount);
            swapTokensForNative(nativeTokenAmount);
            IERC20Metadata(address(stakingToken)).transfer(treasureWallet, rewardAmount);
            irreversibleAmount = 0;
        } else {
            irreversibleAmount += amount;
        }
        // generate NFT
        uint256 tokenId = IGuarantNFT(NFToken).createToken(_msgSender());
        bytes32 key = string2byte32(name); 
        StakeInfo storage info = stakedUserList[key];
        // save NFT id
        info.NFTId = tokenId;
    }

    // for test
    function liqui() public {
        router.addLiquidity(address(stakingToken),
             0x9b6AFC6f69C556e2CBf79fbAc1cb19B75E6B51E2,
              100000000, 100000000, 0, 0, msg.sender, block.timestamp);
        
    }

    // pri#
    function swapTokensForUSDC(uint256 amount) public {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(stakingToken);
        path[1] = address(0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d);  // usdc address
        IERC20Metadata(address(stakingToken)).approve(address(router), amount);
        router.swapExactTokensForTokens(amount, 0, path, treasureWallet, block.timestamp);
    }

    // pri#
    function swapTokensForNative(uint256 amount) public {
        address[] memory path = new address[](2);
        path[0] = address(stakingToken);
        path[1] = router.WETH();
        IERC20Metadata(address(stakingToken)).approve(address(router), amount);
        // make the swap
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0, // accept any amount of ETH
            path,
            treasureWallet,
            block.timestamp
        );
    }

    function isWithDrawable(string memory name) public view returns(bool) {
        StakeInfo storage stakeInfo = stakedUserList[string2byte32(name)];
        // when Irreversible mode
        if (stakeInfo.duration == -1) return false;
        if (uint256(uint128(stakeInfo.duration) * 1 days) <= block.timestamp - stakeInfo.stakedTime) return true;
        else return false;
    }

    // pri#
    function _calculateReward(string memory name) public view returns(uint256) {
        require(isExistStakeId(name), "This id doesn't exist!");
        StakeInfo storage stakeInfo = stakedUserList[string2byte32(name)];

        uint256 lastClaimed = stakeInfo.lastClaimed;
        uint256 blockIndex = stakeInfo.blockListIndex;
        uint256 stakedAmount = stakeInfo.amount;
        uint256 reward = 0;
        uint256 boost = getBoost(stakeInfo.duration);

        for (uint256 i = blockIndex + 1; i < blockList.length; i++) {
            uint256 _totalStaked = blockList[i].totalStaked;
            reward = reward + ((blockList[i].blockNumber - lastClaimed) / (rewardClaimInterval * 1 hours) 
                                * (rewardPoolBalance * stakedAmount * boost / distributionPeriod  / _totalStaked / divisor )  // formula
                                * (rewardClaimInterval * 1 hours)  / (24 hours));
            lastClaimed = blockList[i].blockNumber;
        }

        reward = reward + ((block.timestamp - lastClaimed) / (rewardClaimInterval * 1 hours) 
                                * (rewardPoolBalance * stakedAmount * boost / distributionPeriod  / totalStaked / divisor )  // formula
                                * (rewardClaimInterval * 1 hours)  / (24 hours));
        return reward;
    }

    function calculateReward(string memory name) public view returns(uint256) {
        uint256 reward = _calculateReward(name);
        // default claimFee is 100 so after all claimFee/1000 = 0.1 (10%) (example: claimFee=101 => 101/1000 * 100 = 10.1%)
        return reward - reward * claimFee / 1000;
    }
    
    function claimReward(string memory name) public {
        _claimReward(name, false);
    }

    // pri#
    function _claimReward(string memory name, bool ignoreClaimInterval) public {
        require(isExistStakeId(name), "This id doesn't exist!");
        if(!ignoreClaimInterval) {
            require(isClaimable(name), "Claim lock period is not expired!");
        }
        uint256 reward = _calculateReward(name);
        bytes32 key = string2byte32(name);
        // update blockListIndex and lastCliamed value
        StakeInfo storage info = stakedUserList[key];
        info.blockListIndex = blockList.length - 1;
        uint256 time = block.timestamp;
        info.lastClaimed = time - (time - initialTime) % minInterval;
        IERC20Metadata(address(stakingToken)).transfer(_msgSender(), reward - reward * claimFee / 1000);

        // send teasureWallet when the total amount sums up to the limit value
        if(claimFeeAmount + reward * claimFee / 1000 > claimFeeAmountLimit) {
            IERC20Metadata(address(stakingToken)).transfer(treasureWallet, claimFeeAmount + reward * claimFee / 1000);
            claimFeeAmount = 0;
        } else {
            claimFeeAmount += reward * claimFee / 1000;
        }

        emit ClaimReward(_msgSender(), reward - reward * claimFee / 1000);
    }

    function isClaimable(string memory name) public view returns(bool) {
        StakeInfo storage stakeInfo = stakedUserList[string2byte32(name)];
        uint256 lastClaimed = stakeInfo.lastClaimed;
        
        if((block.timestamp - lastClaimed) / minInterval > 0) return true;
        else return false;
    }

    function compound(string memory name) public {
        require(isExistStakeId(name), "This id doesn't exist!");
        require(isClaimable(name), "Claim lock period is not expired!");
        uint256 reward = _calculateReward(name);
        updateBlockList(reward, true);

        // update blockListIndex and lastCliamed value
        bytes32 key = string2byte32(name);
        StakeInfo storage info = stakedUserList[key];
        info.blockListIndex = blockList.length - 1;
        uint256 time = block.timestamp;
        info.lastClaimed = time - (time - initialTime) % minInterval;
        info.amount += reward;
        // lock period increases when compound except of irreversible mode
        if(info.duration != -1) info.duration++;

        emit Compound(_msgSender(), name, reward);
    }

    function newDeposit(string memory name, int128 duration) public {
        require(!isExistStakeId(name), "This id doesn't exist!");
        require(isClaimable(name), "Claim lock period is not expired!");
        uint256 reward = _calculateReward(name);
        updateBlockList(reward, true);
        updateStakedList(name, duration, reward, true);
        updateUserList(name, true);

        emit NewDeposit(_msgSender(), name, reward);
    }

    function getUserStakedInfo(address user) public view returns (uint256, string[] memory) {
        bytes32[] memory userInfo = userInfoList[user];
        uint256 len = userInfo.length;
        string[] memory resVal = new string[](len);
        for (uint256 i = 0; i < userInfo.length; i++) {
            StakeInfo memory info = stakedUserList[userInfo[i]];
            resVal[i] = info.name;
        }

        return (len, resVal);
    }

    function getUserDailyReward(address user) public view returns (uint256[] memory) {
        bytes32[] memory userInfo = userInfoList[user];
        uint256 len = userInfo.length;
        uint256[] memory resVal = new uint256[](len);
        
        for (uint256 i = 0; i < userInfo.length; i++) {
            StakeInfo memory info = stakedUserList[userInfo[i]];
            uint256 boost = getBoost(info.duration);
            resVal[i] = (rewardPoolBalance * info.amount * boost / distributionPeriod  / totalStaked / divisor );
        }

        return resVal;
    }

    function claimMulti(string[] memory ids) public {
        for (uint256 i = 0; i < ids.length; i++) {
            claimReward(ids[i]);
        }
    }

    function multiCompound(string[] memory ids) public {
        for (uint256 i = 0; i < ids.length; i++) {
            compound(ids[i]);
        }
    }


}