// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../lib/Ownable.sol";
import "../lib/SafeMath.sol";
import "../lib/ERC20.sol";

interface IEthStaking {
    function accountLpInfos(address, address)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );
}

interface IEthExternalStaking {
    function balanceOf(address) external view returns (uint256);
}

contract Info is Ownable {
    using SafeMath for uint256;

    uint256[] private devFeePercentage = [5, 2, 2];
    uint256[] private minDevFeeInWei = [0, 0, 0];
    address[] private presaleAddresses; // track all presales created

    mapping(address => uint256) private minInvestorBalance; // min amount to investors HODL BSCS balance
    mapping(address => uint256) private minInvestorGuaranteedBalance;

    uint256 private minStakeTime = 1 minutes;
    uint256 private minUnstakeTime = 3 days;
    uint256 private creatorUnsoldClaimTime = 3 days;

    address[] private swapRouters = [
        address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D)
    ]; // Array of Routers
    address[] private swapFactorys = [
        address(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f)
    ]; // Array of Factorys

    mapping(address => bytes32) private initCodeHash; // Mapping of INIT_CODE_HASH

    mapping(address => address) private lpAddresses; // TOKEN + START Pair Addresses

    address private weth = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    address private factoryAddress;

    mapping(address => uint256) private investmentLimit;
    mapping(address => bool) private devs;

    address private lockingAddress =
        address(0x0000000000000000000000000000000000000000);

    mapping(address => uint256) private minYesVotesThreshold; // minimum number of yes votes needed to pass

    mapping(address => uint256) private minCreatorStakedBalance;

    mapping(address => bool) private blacklistedAddresses;

    mapping(address => bool) public auditorWhitelistedAddresses; // addresses eligible to perform audits

    IEthStaking public stakingPool;
    IEthExternalStaking public externalStaking;

    uint256 private devPresaleTokenFee = 2;
    address private devPresaleAllocationAddress =
        address(0x0000000000000000000000000000000000000000);
    uint256 private presaleCreationFee = 1 ether;

    constructor(address _stakingPool, address _externalStaking) public {
        stakingPool = IEthStaking(_stakingPool);
        externalStaking = IEthExternalStaking(_externalStaking);

        initCodeHash[
            address(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f)
        ] = 0x96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f; // Uniswap V2 INIT_CODE_HASH

        lpAddresses[weth] = address(0xa0558Bec506FC36F84e93883CaA57B96d598C153); // WETH -> LP Addresses

        minYesVotesThreshold[weth] = 1000 * 1e18;

        minInvestorBalance[weth] = 3.5 * 1e18;

        minInvestorGuaranteedBalance[weth] = 35 * 1e18;

        investmentLimit[weth] = 1000 * 1e18;

        minCreatorStakedBalance[weth] = 3.5 * 1e18;
    }

    modifier onlyFactory() {
        require(
            factoryAddress == msg.sender ||
                owner == msg.sender ||
                devs[msg.sender],
            "onlyFactoryOrDev"
        );
        _;
    }

    modifier onlyDev() {
        require(owner == msg.sender || devs[msg.sender], "onlyDev");
        _;
    }

    function getCakeV2LPAddress(
        address tokenA,
        address tokenB,
        uint256 swapIndex
    ) public view returns (address pair) {
        (address token0, address token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        pair = address(
            uint256(
                keccak256(
                    abi.encodePacked(
                        hex"ff",
                        swapFactorys[swapIndex],
                        keccak256(abi.encodePacked(token0, token1)),
                        initCodeHash[swapFactorys[swapIndex]] // init code hash
                    )
                )
            )
        );
    }

    function getDev(address _dev) external view returns (bool) {
        return devs[_dev];
    }

    function setDevAddress(address _newDev) external onlyOwner {
        devs[_newDev] = true;
    }

    function removeDevAddress(address _oldDev) external onlyOwner {
        devs[_oldDev] = false;
    }

    function getFactoryAddress() external view returns (address) {
        return factoryAddress;
    }

    function setFactoryAddress(address _newFactoryAddress) external onlyDev {
        factoryAddress = _newFactoryAddress;
    }

    function getStakingPool() external view returns (address) {
        return address(stakingPool);
    }

    function setStakingPool(address _stakingPool) external onlyDev {
        stakingPool = IEthStaking(_stakingPool);
    }

    function setExternalStaking(address _externalStaking) external onlyDev {
        externalStaking = IEthExternalStaking(_externalStaking);
    }

    function addPresaleAddress(address _presale)
        external
        onlyFactory
        returns (uint256)
    {
        presaleAddresses.push(_presale);
        return presaleAddresses.length - 1;
    }

    function getPresalesCount() external view returns (uint256) {
        return presaleAddresses.length;
    }

    function getPresaleAddress(uint256 bscsId) external view returns (address) {
        return presaleAddresses[bscsId];
    }

    function setPresaleAddress(uint256 bscsId, address _newAddress)
        external
        onlyDev
    {
        presaleAddresses[bscsId] = _newAddress;
    }

    function getPresaleFee() external view returns (uint256) {
        return presaleCreationFee;
    }

    function setPresaleFee(uint256 _newFee) external onlyDev {
        presaleCreationFee = _newFee;
    }

    function getDevFeePercentage(uint256 presaleType)
        external
        view
        returns (uint256)
    {
        return devFeePercentage[presaleType];
    }

    function setDevFeePercentage(uint256 presaleType, uint256 _devFeePercentage)
        external
        onlyDev
    {
        devFeePercentage[presaleType] = _devFeePercentage;
    }

    function getMinDevFeeInWei(uint256 presaleType)
        external
        view
        returns (uint256)
    {
        return minDevFeeInWei[presaleType];
    }

    function setMinDevFeeInWei(uint256 presaleType, uint256 _fee)
        external
        onlyDev
    {
        minDevFeeInWei[presaleType] = _fee;
    }

    function getMinInvestorBalance(address tokenAddress)
        external
        view
        returns (uint256)
    {
        return minInvestorBalance[tokenAddress];
    }

    function setMinInvestorBalance(
        address tokenAddress,
        uint256 _minInvestorBalance
    ) external onlyDev {
        minInvestorBalance[tokenAddress] = _minInvestorBalance;
    }

    function getMinYesVotesThreshold(address tokenAddress)
        external
        view
        returns (uint256)
    {
        return minYesVotesThreshold[tokenAddress];
    }

    function setMinYesVotesThreshold(
        address tokenAddress,
        uint256 _minYesVotesThreshold
    ) external onlyDev {
        minYesVotesThreshold[tokenAddress] = _minYesVotesThreshold;
    }

    function getMinCreatorStakedBalance(address fundingTokenAddress)
        external
        view
        returns (uint256)
    {
        return minCreatorStakedBalance[fundingTokenAddress];
    }

    function setMinCreatorStakedBalance(
        address fundingTokenAddress,
        uint256 _minCreatorStakedBalance
    ) external onlyDev {
        minCreatorStakedBalance[fundingTokenAddress] = _minCreatorStakedBalance;
    }

    function getMinInvestorGuaranteedBalance(address tokenAddress)
        external
        view
        returns (uint256)
    {
        return minInvestorGuaranteedBalance[tokenAddress];
    }

    function setMinInvestorGuaranteedBalance(
        address tokenAddress,
        uint256 _minInvestorGuaranteedBalance
    ) external onlyDev {
        minInvestorGuaranteedBalance[
            tokenAddress
        ] = _minInvestorGuaranteedBalance;
    }

    function getMinStakeTime() external view returns (uint256) {
        return minStakeTime;
    }

    function setMinStakeTime(uint256 _minStakeTime) external onlyDev {
        minStakeTime = _minStakeTime;
    }

    function getMinUnstakeTime() external view returns (uint256) {
        return minUnstakeTime;
    }

    function setMinUnstakeTime(uint256 _minUnstakeTime) external onlyDev {
        minUnstakeTime = _minUnstakeTime;
    }

    function getCreatorUnsoldClaimTime() external view returns (uint256) {
        return creatorUnsoldClaimTime;
    }

    function setCreatorUnsoldClaimTime(uint256 _creatorUnsoldClaimTime)
        external
        onlyDev
    {
        creatorUnsoldClaimTime = _creatorUnsoldClaimTime;
    }

    function getSwapRouter(uint256 index) external view returns (address) {
        return swapRouters[index];
    }

    function setSwapRouter(uint256 index, address _swapRouter)
        external
        onlyDev
    {
        swapRouters[index] = _swapRouter;
    }

    function addSwapRouter(address _swapRouter) external onlyDev {
        swapRouters.push(_swapRouter);
    }

    function getSwapFactory(uint256 index) external view returns (address) {
        return swapFactorys[index];
    }

    function setSwapFactory(uint256 index, address _swapFactory)
        external
        onlyDev
    {
        swapFactorys[index] = _swapFactory;
    }

    function addSwapFactory(address _swapFactory) external onlyDev {
        swapFactorys.push(_swapFactory);
    }

    function getInitCodeHash(address _swapFactory)
        external
        view
        returns (bytes32)
    {
        return initCodeHash[_swapFactory];
    }

    function setInitCodeHash(address _swapFactory, bytes32 _initCodeHash)
        external
        onlyDev
    {
        initCodeHash[_swapFactory] = _initCodeHash;
    }

    function getWETH() external view returns (address) {
        return weth;
    }

    function setWETH(address _weth) external onlyDev {
        weth = _weth;
    }

    function getLockingAddress() external view returns (address) {
        return lockingAddress;
    }

    function setLockingAddress(address _newLocking) external onlyDev {
        lockingAddress = _newLocking;
    }

    function getInvestmentLimit(address tokenAddress)
        external
        view
        returns (uint256)
    {
        return investmentLimit[tokenAddress];
    }

    function setInvestmentLimit(address tokenAddress, uint256 _limit)
        external
        onlyDev
    {
        investmentLimit[tokenAddress] = _limit;
    }

    function getLpAddress(address tokenAddress) public view returns (address) {
        return lpAddresses[tokenAddress];
    }

    function setLpAddress(address tokenAddress, address lpAddress)
        external
        onlyDev
    {
        lpAddresses[tokenAddress] = lpAddress;
    }

    function getStakedByLp(address lpAddress, address payable sender)
        public
        view
        returns (uint256)
    {
        uint256 balance;
        uint256 lastStakedTimestamp;
        (balance, lastStakedTimestamp, ) = stakingPool.accountLpInfos(
            lpAddress,
            address(sender)
        );
        uint256 totalHodlerBalance = 0;
        if (lastStakedTimestamp + minStakeTime <= block.timestamp) {
            totalHodlerBalance = totalHodlerBalance.add(balance);
        }

        uint256 externalBalance = externalStaking.balanceOf(address(sender));

        return totalHodlerBalance + externalBalance;
    }

    function getTotalStakedByLp(address lpAddress)
        public
        view
        returns (uint256)
    {
        return ERC20(lpAddress).balanceOf(address(stakingPool));
    }

    function getStaked(address fundingTokenAddress, address payable sender)
        public
        view
        returns (uint256)
    {
        return getStakedByLp(getLpAddress(fundingTokenAddress), sender);
    }

    function getTotalStaked(address fundingTokenAddress)
        public
        view
        returns (uint256)
    {
        return getTotalStakedByLp(getLpAddress(fundingTokenAddress));
    }

    function getDevPresaleTokenFee() public view returns (uint256) {
        return devPresaleTokenFee;
    }

    function setDevPresaleTokenFee(uint256 _devPresaleTokenFee)
        external
        onlyDev
    {
        devPresaleTokenFee = _devPresaleTokenFee;
    }

    function getDevPresaleAllocationAddress() public view returns (address) {
        return devPresaleAllocationAddress;
    }

    function setDevPresaleAllocationAddress(
        address _devPresaleAllocationAddress
    ) external onlyDev {
        devPresaleAllocationAddress = _devPresaleAllocationAddress;
    }

    function isBlacklistedAddress(address _sender) public view returns (bool) {
        return blacklistedAddresses[_sender];
    }

    function addBlacklistedAddresses(address[] calldata _blacklistedAddresses)
        external
        onlyDev
    {
        for (uint256 i = 0; i < _blacklistedAddresses.length; i++) {
            blacklistedAddresses[_blacklistedAddresses[i]] = true;
        }
    }

    function removeBlacklistedAddresses(
        address[] calldata _blacklistedAddresses
    ) external onlyDev {
        for (uint256 i = 0; i < _blacklistedAddresses.length; i++) {
            blacklistedAddresses[_blacklistedAddresses[i]] = false;
        }
    }

    function isAuditorWhitelistedAddress(address _sender)
        public
        view
        returns (bool)
    {
        return auditorWhitelistedAddresses[_sender];
    }

    function addAuditorWhitelistedAddresses(
        address[] calldata _whitelistedAddresses
    ) external onlyDev {
        for (uint256 i = 0; i < _whitelistedAddresses.length; i++) {
            auditorWhitelistedAddresses[_whitelistedAddresses[i]] = true;
        }
    }

    function removeAuditorWhitelistedAddresses(
        address[] calldata _whitelistedAddresses
    ) external onlyDev {
        for (uint256 i = 0; i < _whitelistedAddresses.length; i++) {
            auditorWhitelistedAddresses[_whitelistedAddresses[i]] = false;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "../interfaces/IERC20.sol";
import "../lib/SafeMath.sol";
import "../lib/Ownable.sol";
import "./Info.sol";

contract Locking is Ownable {
    using SafeMath for uint256;

    Info public infoContract;
    /*
     * deposit vars
     */
    struct Items {
        address tokenAddress;
        address withdrawalAddress;
        uint256 tokenAmount;
        uint256 unlockTime;
        bool withdrawn;
    }

    uint256 public depositId;
    uint256[] public allDepositIds;
    mapping(address => uint256[]) public depositsByWithdrawalAddress;
    mapping(uint256 => Items) public lockedToken;
    mapping(address => mapping(address => uint256)) public walletTokenBalance;

    event LogLock(
        address tokenAddress,
        address fromAddress,
        uint256 amount,
        uint256 unlockTime,
        uint256 depositId
    );
    event LogWithdrawal(address SentToAddress, uint256 AmountTransferred);

    modifier onlyDev() {
        require(msg.sender == owner || infoContract.getDev(msg.sender));
        _;
    }

    /**
     * Constrctor function
     */
    constructor(address _infoContract) public {
        infoContract = Info(_infoContract);
    }

    /**
     * lock tokens
     */
    function lockTokens(
        address _tokenAddress,
        address _withdrawalAddress,
        uint256 _lockAmount,
        uint256 _unlockTime
    ) public returns (uint256 _id) {
        require(_lockAmount > 0, "token amount is Zero");
        require(
            _unlockTime < 10000000000,
            "Enter an unix timestamp in seconds, not miliseconds"
        );
        require(
            _unlockTime >= block.timestamp,
            "Enter an unix timestamp in the future"
        );
        require(
            IERC20(_tokenAddress).transferFrom(
                msg.sender,
                address(this),
                _lockAmount
            ),
            "Transfer of tokens failed"
        );

        // update balance in address
        walletTokenBalance[_tokenAddress][
            _withdrawalAddress
        ] = walletTokenBalance[_tokenAddress][_withdrawalAddress].add(
            _lockAmount
        );

        _id = ++depositId;
        lockedToken[_id].tokenAddress = _tokenAddress;
        lockedToken[_id].withdrawalAddress = _withdrawalAddress;
        lockedToken[_id].tokenAmount = _lockAmount;
        lockedToken[_id].unlockTime = _unlockTime;
        lockedToken[_id].withdrawn = false;

        allDepositIds.push(_id);
        depositsByWithdrawalAddress[_withdrawalAddress].push(_id);
        emit LogLock(
            _tokenAddress,
            _withdrawalAddress,
            _lockAmount,
            _unlockTime,
            _id
        );
    }

    /**
     * withdraw tokens
     */
    function withdrawTokens(uint256 _id) public {
        require(
            block.timestamp >= lockedToken[_id].unlockTime,
            "Tokens are locked"
        );
        require(
            msg.sender == lockedToken[_id].withdrawalAddress,
            "Can withdraw by withdrawal Address only"
        );
        require(!lockedToken[_id].withdrawn, "Tokens already withdrawn");
        require(
            IERC20(lockedToken[_id].tokenAddress).transfer(
                msg.sender,
                lockedToken[_id].tokenAmount
            ),
            "Transfer of tokens failed"
        );

        lockedToken[_id].withdrawn = true;

        //update balance in address
        walletTokenBalance[lockedToken[_id].tokenAddress][
            msg.sender
        ] = walletTokenBalance[lockedToken[_id].tokenAddress][msg.sender].sub(
            lockedToken[_id].tokenAmount
        );

        //remove this id from this address
        uint256 i;
        uint256 j;
        for (
            j = 0;
            j <
            depositsByWithdrawalAddress[lockedToken[_id].withdrawalAddress]
                .length;
            j++
        ) {
            if (
                depositsByWithdrawalAddress[lockedToken[_id].withdrawalAddress][
                    j
                ] == _id
            ) {
                for (
                    i = j;
                    i <
                    depositsByWithdrawalAddress[
                        lockedToken[_id].withdrawalAddress
                    ].length -
                        1;
                    i++
                ) {
                    depositsByWithdrawalAddress[
                        lockedToken[_id].withdrawalAddress
                    ][i] = depositsByWithdrawalAddress[
                        lockedToken[_id].withdrawalAddress
                    ][i + 1];
                }
                depositsByWithdrawalAddress[lockedToken[_id].withdrawalAddress]
                    .pop();
                break;
            }
        }
        emit LogWithdrawal(msg.sender, lockedToken[_id].tokenAmount);
    }

    /* get total token balance in contract */
    function getTotalTokenBalance(address _tokenAddress)
        public
        view
        returns (uint256)
    {
        return IERC20(_tokenAddress).balanceOf(address(this));
    }

    /*get total token balance by address*/
    function getTokenBalanceByAddress(
        address _tokenAddress,
        address _walletAddress
    ) public view returns (uint256) {
        return walletTokenBalance[_tokenAddress][_walletAddress];
    }

    /* get allDepositIds */
    function getAllDepositIds() public view returns (uint256[] memory) {
        return allDepositIds;
    }

    /* get getDepositDetails */
    function getDepositDetails(uint256 _id)
        public
        view
        returns (
            address,
            address,
            uint256,
            uint256,
            bool
        )
    {
        return (
            lockedToken[_id].tokenAddress,
            lockedToken[_id].withdrawalAddress,
            lockedToken[_id].tokenAmount,
            lockedToken[_id].unlockTime,
            lockedToken[_id].withdrawn
        );
    }

    /* get DepositsByWithdrawalAddress */
    function getDepositsByWithdrawalAddress(address _withdrawalAddress)
        public
        view
        returns (uint256[] memory)
    {
        return depositsByWithdrawalAddress[_withdrawalAddress];
    }

    function emergencyWithdraw(address _token, address _receiver)
        public
        onlyDev
    {
        IERC20(_token).transfer(
            _receiver,
            IERC20(_token).balanceOf(address(this))
        );
    }
}

pragma solidity ^0.6.12;

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

pragma solidity ^0.6.12;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(
            data
        );
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity ^0.6.12;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity ^0.6.12;

import "./Address.sol";
import "./Context.sol";
import "./SafeMath.sol";
import "../interfaces/IERC20.sol";

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
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) _balances;

    mapping(address => mapping(address => uint256)) _allowances;

    uint256 _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
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
    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
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
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(
            amount,
            "ERC20: transfer amount exceeds balance"
        );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(
            amount,
            "ERC20: burn amount exceeds balance"
        );
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
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
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
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
}

pragma solidity ^0.6.12;

/**
 * @title Owned
 * @dev Basic contract for authorization control.
 * @author dicether
 */
contract Ownable {
    address public owner;
    address public pendingOwner;

    event LogOwnerShipTransferred(address indexed previousOwner, address indexed newOwner);
    event LogOwnerShipTransferInitiated(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Modifier, which throws if called by other account than owner.
     */
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Modifier throws if called by any account other than the pendingOwner.
     */
    modifier onlyPendingOwner() {
        require(msg.sender == pendingOwner);
        _;
    }

    /**
     * @dev Set contract creator as initial owner
     */
    constructor() public {
        owner = msg.sender;
        pendingOwner = address(0);
    }

    /**
     * @dev Allows the current owner to set the pendingOwner address.
     * @param _newOwner The address to transfer ownership to.
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        pendingOwner = _newOwner;
        emit LogOwnerShipTransferInitiated(owner, _newOwner);
    }

    /**
     * @dev PendingOwner can accept ownership.
     */
    function claimOwnership() public onlyPendingOwner {
        owner = pendingOwner;
        pendingOwner = address(0);
        emit LogOwnerShipTransferred(owner, pendingOwner);
    }
}

pragma solidity ^0.6.12;

// File: @openzeppelin/contracts/math/SafeMath.sol

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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
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
     *
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}