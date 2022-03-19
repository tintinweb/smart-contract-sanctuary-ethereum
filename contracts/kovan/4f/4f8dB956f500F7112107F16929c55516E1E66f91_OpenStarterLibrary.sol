// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./lib/Ownable.sol";
import "./lib/SafeMath.sol";
import "./lib/ERC20.sol";

interface IOpenStarterStaking {
    function accounts(address)
        external
        view
        returns (
            uint256[5] memory,
            uint256,
            uint256,
            uint256
        );

    function getUserBalances(address) external view returns (uint256[] memory);

    function getAccountTier(address) external view returns (uint256);
}

interface IExternalStaking {
    function balanceOf(address) external view returns (uint256);
}

contract OpenStarterLibrary is Ownable {
    using SafeMath for uint256;

    uint256[5][10] private tiers; // tiers[0][] is SOS; tiers[1][] is START;

    // Archeologist:    10B+ SOS OR 20K+ START for 14+ days
    // Conservator:     1B+ SOS OR 10K+ START for 10+ days
    // Researcher:      100M+ SOS OR 1K+ START for 7+ days
    // Navigator:       10M+ SOS OR 100+ START for 5+ days
    // Lottery:         <10M or no staking

    mapping(address => bool) private starterDevs;

    IOpenStarterStaking public openStarterStakingPool;
    IExternalStaking public externalStaking;

    address private nftFactoryAddress;
    address private saleFactoryAddress;

    address[] public nfts;
    address[] public sales;

    uint256 private devFeePercentage = 10; // 10% fee for INOs

    address private WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    uint256 private allocationCount = 4;
    uint256[] private allocationPercentage = [5, 10, 20, 30, 35];
    uint256[] private allocationTime = [30 * 60, 60 * 60, 90 * 60, 120 * 60];
    uint256 private voteTokenIndex = 0;
    uint256 private minVoterBalance = 100 * 1e06 * 1e18;
    uint256 private minYesVotesThreshold = 10000 * 1e27;
    uint256 private externalTokenIndex = 0;

    string public featured; // ipfs link for featured projects list
    string public upcomings; // ipfs link for upcoming projects list
    string public finished; // ipfs link for finished projects list

    constructor(address _openStarterStakingPool, address _externalStaking)
        public
    {
        openStarterStakingPool = IOpenStarterStaking(_openStarterStakingPool);
        externalStaking = IExternalStaking(_externalStaking);

        starterDevs[address(0xf7e925818a20E5573Ee0f3ba7aBC963e17f2c476)] = true;
        starterDevs[address(0x283B3b8f340E8FB94D55b17E906744a74074cD07)] = true;

        tiers[0][0] = 10 * 1e06 * 1e18; // tiers: 10M+ SOS, 100M+ SOS, 1B+ SOS, 10B+ SOS,
        tiers[0][1] = 100 * 1e06 * 1e18;
        tiers[0][2] = 1 * 1e27;
        tiers[0][3] = 10 * 1e27;

        tiers[1][0] = 100 * 1e18; // tiers: 100+ START, 1K+ START, 10K+ START, 20K+ START
        tiers[1][1] = 1000 * 1e18;
        tiers[1][2] = 10000 * 1e18;
        tiers[1][3] = 20000 * 1e18;
    }

    modifier onlyStarterDev() {
        require(
            owner == msg.sender || starterDevs[msg.sender],
            "onlyStarterDev"
        );
        _;
    }

    modifier onlyFactory() {
        require(
            owner == msg.sender ||
                starterDevs[msg.sender] ||
                nftFactoryAddress == msg.sender ||
                saleFactoryAddress == msg.sender,
            "onlyFactory"
        );
        _;
    }

    function getTier(uint256 tokenIndex, uint256 tierIndex)
        external
        view
        returns (uint256)
    {
        return tiers[tokenIndex][tierIndex];
    }

    function setTier(
        uint256 tokenIndex,
        uint256 tierIndex,
        uint256 _value
    ) external onlyStarterDev {
        tiers[tokenIndex][tierIndex] = _value;
    }

    function getUserTier(uint256 stakingTokenIndex, uint256 amount)
        external
        view
        returns (uint256)
    {
        uint256 i = 0;
        uint256 tier = 0;
        for (i = 0; i < tiers[stakingTokenIndex].length; i++) {
            if (
                amount >= tiers[stakingTokenIndex][i] &&
                tiers[stakingTokenIndex][i] > 0
            ) {
                tier = i + 1;
            } else {
                break;
            }
        }
        return tier;
    }

    function getStarterDev(address _dev) external view returns (bool) {
        return starterDevs[_dev];
    }

    function setStarterDevAddress(address _newDev) external onlyOwner {
        starterDevs[_newDev] = true;
    }

    function removeStarterDevAddress(address _oldDev) external onlyOwner {
        starterDevs[_oldDev] = false;
    }

    function getNftFactoryAddress() external view returns (address) {
        return nftFactoryAddress;
    }

    function setNftFactoryAddress(address _newFactoryAddress)
        external
        onlyStarterDev
    {
        nftFactoryAddress = _newFactoryAddress;
    }

    function getSaleFactoryAddress() external view returns (address) {
        return saleFactoryAddress;
    }

    function setSaleFactoryAddress(address _newFactoryAddress)
        external
        onlyStarterDev
    {
        saleFactoryAddress = _newFactoryAddress;
    }

    function addNfts(address _nftAddress)
        external
        onlyFactory
        returns (uint256)
    {
        nfts.push(_nftAddress);
        return nfts.length - 1;
    }

    function addSaleAddress(address _saleAddress)
        external
        onlyFactory
        returns (uint256)
    {
        sales.push(_saleAddress);
        return sales.length - 1;
    }

    function addSales(address[] calldata _saleAddresses) external onlyFactory {
        for (uint256 i = 0; i < _saleAddresses.length; i++) {
            sales.push(_saleAddresses[i]);
        }
    }

    function setNftAddress(uint256 _index, address _nftAddress)
        external
        onlyFactory
    {
        nfts[_index] = _nftAddress;
    }

    function setSaleAddress(uint256 _index, address _saleAddress)
        external
        onlyFactory
    {
        sales[_index] = _saleAddress;
    }

    function getStakingPool() external view returns (address) {
        return address(openStarterStakingPool);
    }

    function setStakingPool(address _openStarterStakingPool)
        external
        onlyStarterDev
    {
        openStarterStakingPool = IOpenStarterStaking(_openStarterStakingPool);
    }

    function getExternalStaking() external view returns (address) {
        return address(externalStaking);
    }

    function setExternalStaking(address _openStarterStakingPool)
        external
        onlyStarterDev
    {
        externalStaking = IExternalStaking(_openStarterStakingPool);
    }

    function getNftsCount() external view returns (uint256) {
        return nfts.length;
    }

    function getNftAddress(uint256 nftId) external view returns (address) {
        return nfts[nftId];
    }

    function getSalesCount() external view returns (uint256) {
        return sales.length;
    }

    function getSaleAddress(uint256 saleId) external view returns (address) {
        return sales[saleId];
    }

    function getDevFeePercentage() external view returns (uint256) {
        return devFeePercentage;
    }

    function setDevFeePercentage(uint256 _devFeePercentage)
        external
        onlyStarterDev
    {
        devFeePercentage = _devFeePercentage;
    }

    function getWETH() external view returns (address) {
        return WETH;
    }

    function setWETH(address _WETH) external onlyStarterDev {
        WETH = _WETH;
    }

    function getAllocationCount() external view returns (uint256) {
        return allocationCount;
    }

    function setAllocationCount(uint256 _count) external onlyStarterDev {
        allocationCount = _count;
    }

    function getAllocationPercentage(uint256 _index)
        external
        view
        returns (uint256)
    {
        return allocationPercentage[_index];
    }

    function setAllocationPercentage(uint256 _index, uint256 _value)
        external
        onlyStarterDev
    {
        allocationPercentage[_index] = _value;
    }

    function getAllocationTime(uint256 _index) external view returns (uint256) {
        return allocationTime[_index];
    }

    function setAllocationTime(uint256 _index, uint256 _value)
        external
        onlyStarterDev
    {
        allocationTime[_index] = _value;
    }

    function getStaked(address _sender) external view returns (uint256) {
        uint256[] memory balances = openStarterStakingPool.getUserBalances(
            _sender
        );
        uint256 externalBalance = 0;
        if (
            address(externalStaking) !=
            0x0000000000000000000000000000000000000000 &&
            voteTokenIndex == externalTokenIndex
        ) {
            externalBalance = externalStaking.balanceOf(_sender);
        }
        return balances[voteTokenIndex] + externalBalance;
    }

    function getStakerTier(address _staker) external view returns (uint256) {
        return openStarterStakingPool.getAccountTier(_staker);
    }

    function getVoteTokenIndex() external view returns (uint256) {
        return voteTokenIndex;
    }

    function setVoteTokenIndex(uint256 _index) external onlyStarterDev {
        voteTokenIndex = _index;
    }

    function getMinVoterBalance() external view returns (uint256) {
        return minVoterBalance;
    }

    function setMinVoterBalance(uint256 _balance) external onlyStarterDev {
        minVoterBalance = _balance;
    }

    function getMinYesVotesThreshold() external view returns (uint256) {
        return minYesVotesThreshold;
    }

    function setMinYesVotesThreshold(uint256 _balance) external onlyStarterDev {
        minYesVotesThreshold = _balance;
    }

    function getTierByTime(uint256 _openTime, uint256 _currentTimestamp)
        external
        view
        returns (uint256)
    {
        if (
            _currentTimestamp >= _openTime &&
            _currentTimestamp <= _openTime + allocationTime[0]
        ) {
            return 4;
        }
        for (uint256 i = 0; i < allocationCount - 1; i++) {
            if (
                _currentTimestamp > _openTime + allocationTime[i] &&
                _currentTimestamp < _openTime + allocationTime[i + 1]
            ) {
                return allocationCount - i - 1;
            }
        }
        return 0;
    }

    function setFeaturedProjects(string memory _url) external onlyStarterDev {
        featured = _url;
    }

    function setUpcomingProjects(string memory _url) external onlyStarterDev {
        upcomings = _url;
    }

    function setFinishedProjects(string memory _url) external onlyStarterDev {
        finished = _url;
    }

    function getExternalTokenIndex() external view returns (uint256) {
        return externalTokenIndex;
    }

    function setExternalTokenIndex(uint256 _index) external onlyStarterDev {
        externalTokenIndex = _index;
    }

    function getExternalStaked(uint256 tokenIndex, address _staker)
        external
        view
        returns (uint256)
    {
        if (tokenIndex != externalTokenIndex) return 0;
        if (
            address(externalStaking) ==
            0x0000000000000000000000000000000000000000
        ) return 0;
        return externalStaking.balanceOf(_staker);
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