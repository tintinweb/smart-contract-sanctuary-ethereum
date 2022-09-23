// SPDX-License-Identifier: UNLICENCED
pragma solidity 0.8.11;

import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';

import './JoyToken.sol';
import './xJoyToken.sol';
import './interfaces/IUSDT.sol';

import './interfaces/IUniswapV2Pair.sol';
import './libraries/UniswapV2Library.sol';

error SALE_NOT_LIVE();
error STILL_VESTING();
error WRONG_VESTING_TYPE();
error NOTHING_TO_WITHDRAW();
error COINS_NOT_SET();
error ONLY_OWNER();
error WRONG_ADDRESS();
error PAIR_NOT_SET();
error MIN_ONE_CENT();

contract Presale is AccessControl {
    /**
     * VESTING TYPES
     * Initialy there will be 5 vesting levels defined by the constructor
     * 0 - SEED
     * 1 - PRESALE
     * 2 - TEAM
     * 3 - PARTNERS
     * 4 - STAR
     *
     * It's not becoming an enum to allow users to set different vesting  level after the release
     */

    struct VestingInfo {
        uint256 releasePercentBasisPoints; // Release percent basis points (1% = 100, 100% = 10000)
        uint256 cliff; // Cliff for release start time
        uint256 releaseStep; // How often percent step is applied
        uint256 vestingCloseTimeline; // How much time has to pass to finish vesting
    }

    struct DepositInfo {
        uint256 vestingType; // Tier of the type of vesting
        uint256 depositedAmount; // How many Coins amount the user has deposited.
        uint256 purchasedAmount; // How many JOY tokens the user has purchased.
        uint256 depositTime; // Deposited time
    }

    struct PurchaserInfo {
        uint256 firstDepositTime; // When user made his first deposit
        uint256 firstUnlockTime; // Timestamp when unlock will start
        uint256 vestingTimeFinish; // Timestamp when vesting for the purchaser will be closed
        uint256 withdrawnAmount; // Amount of JOY tokens already withdrawn by the purchaser
        DepositInfo[] deposits; // List of all deposits of the purchaser
    }

    JoyToken public joyToken;
    XJoyToken public xJoyToken;

    VestingInfo[] public vestingList;
    uint256 public currentVestingType;
    uint256 public totalPurchasers;
    address public treasuryAddress;
    address public USDC_Address = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public USDT_Address = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public owner;
    bool public sale;

    mapping(uint256 => address) public purchaserAddress;
    mapping(address => PurchaserInfo) public purchaserList;

    event TokensPurchased(
        address indexed purchaser,
        uint256 coinAmount,
        uint256 tokenAmount
    );
    event TokensWithdrawn(address indexed purchaser, uint256 tokenAmount);
    event VestingTypeAdded(uint256 indexed level);
    event VestingTypeChanged(uint256 indexed level);

    modifier onSale() {
        if (!sale) revert SALE_NOT_LIVE();
        _;
    }

    modifier notVested(address userAddr) {
        if (!checkVestingPeriod(userAddr)) revert STILL_VESTING();
        _;
    }

    modifier onlyAdmin() {
        _checkRole(DEFAULT_ADMIN_ROLE);
        _;
    }

    modifier onlyOwner() {
        if (owner != _msgSender()) revert ONLY_OWNER();
        _;
    }

    constructor(
        JoyToken _joyToken,
        XJoyToken _xJoyToken,
        VestingInfo[] memory _vestingInfo,
        uint256 _initialVestingType,
        address _treasuryAddress
    ) {
        joyToken = _joyToken;
        xJoyToken = _xJoyToken;
        treasuryAddress = _treasuryAddress;
        owner = msg.sender;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        for (uint256 i; i < _vestingInfo.length; ) {
            vestingList.push(_vestingInfo[i]);
            unchecked {
                i++;
            }
        }

        currentVestingType = _initialVestingType;
        startSale(false);
    }

    /**
     * Adding new admin to the contract
     * @param _admin - New admin to be added to administrator list
     */
    function addAdmin(address _admin) external onlyAdmin {
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
    }

    /**
     * Removing admin from token administrators list
     * @param _admin - Admin to be removed from admin list
     */
    function removeAdmin(address _admin) external onlyAdmin {
        if (_admin == owner) revert ONLY_OWNER();
        _revokeRole(DEFAULT_ADMIN_ROLE, _admin);
    }

    /**
     * Team Multisig Safe Vault
     * @param _newOwner - Contract owner address
     */
    function changeOwnership(address _newOwner) public onlyOwner {
        if (owner == _newOwner || _newOwner == address(0)) revert WRONG_ADDRESS();
        _revokeRole(DEFAULT_ADMIN_ROLE, owner);
        owner = _newOwner;
        _grantRole(DEFAULT_ADMIN_ROLE, _newOwner);
    }

    /**
     * Update Treasury
     * @param _treasuryAddress - New treasury multisig
     */
    function updateTreasury(address _treasuryAddress) public onlyOwner {
        treasuryAddress = _treasuryAddress;
    }

    /**
     * Start (or stop) the sale from happening
     * @param _start - Flag if sale should be started.
     */
    function startSale(bool _start) public onlyAdmin {
        sale = _start;
    }

    /**
     * Checks if given address has finished vesting.
     * @param _address - Address of the account being checked
     * @return True if given address is still locked. False otherwise.
     */
    function isLocked(address _address) public view returns (bool) {
        return block.timestamp < purchaserList[_address].vestingTimeFinish;
    }

    /**
     * Checks if given address is still being vested.
     * @param _address - Address of the account being checked.
     * @return True if given account is being vested anymore. False otherwise.
     */
    function checkVestingPeriod(address _address) public view returns (bool) {
        return block.timestamp > purchaserList[_address].firstUnlockTime;
    }

    /**
     * Adding new vesting type for vesting list.
     *
     * @param _vestingType - Struct defining new vesting level
     */

    function addVestingType(VestingInfo memory _vestingType)
        external
        onlyAdmin
    {
        uint256 index = vestingList.length;

        vestingList.push(_vestingType);

        emit VestingTypeAdded(index);
    }

    /**
     * Change vesting type.
     *
     * Switching vesting type to new level.
     * ATTENTION!: Vesting type can be only moved FORWARD so no going back to previous vestings
     *
     * @param _vestingType - Index of vesting to be switched to
     */
    function switchVesting(uint256 _vestingType) external onlyAdmin {
        if (
            _vestingType >= vestingList.length ||
            _vestingType <= currentVestingType
        ) {
            revert WRONG_VESTING_TYPE();
        }

        currentVestingType = _vestingType;
        emit VestingTypeChanged(_vestingType);
    }

    /**
     * Sets purchase and vesting information of given purchaser.
     *
     * Addresses added to this list will be blacklisted from moving XJoy tokens.
     * This is done to block trading these and use them only as a vesting token to retrieve Joy tokens after vesting period.
     * This contract will be listed as whitelisted contract to move tokens back at the end of the vesting season.
     * @param _addr - Address matched to information being set
     * @param _vestingIndex - Index of a vested address
     * @param _depositedTime - Timestamp of the deposit
     * @param _purchasedAmount - Amount of tokens purchased
     * @param _withdrawnAmount - Amount of tokens already withdrawn by the user
     */
    function addPurchase(
        address _addr,
        uint256 _vestingIndex,
        uint256 _depositedTime,
        uint256 _depositedAmount,
        uint256 _purchasedAmount,
        uint256 _withdrawnAmount
    ) external onlyAdmin {
        internalAddPurchase(
            _addr,
            _vestingIndex,
            _depositedTime,
            _depositedAmount,
            _purchasedAmount,
            _withdrawnAmount
        );
    }

    /**
     * Deliver vested tokens to list of users
     * @param _purchaserAddress - Addresses that should be vested
     * @param _purchaserList  - List of purchasers
     * @param _transferToken - Should addresses receive tokens on top of being marked as vested
     */
    function addPurchasers(
        address[] memory _purchaserAddress,
        DepositInfo[] memory _purchaserList,
        bool _transferToken
    ) public onlyAdmin {
        for (uint256 i; i < _purchaserAddress.length; ) {
            addPurchaser(
                _purchaserAddress[i],
                _purchaserList[i].vestingType,
                _purchaserList[i].depositTime,
                _purchaserList[i].depositedAmount,
                _purchaserList[i].purchasedAmount,
                _transferToken
            );
            unchecked {
                i++;
            }
        }
    }

    /**
     * Add purchaser vesting schedule
     * @param _purchaserAddr - Address of the user to be vested
     * @param _vestingIndex - Index of the vested user
     * @param _depositedTime - Time of the deposit
     * @param _depositedAmount - Amount of the deposit
     * @param _purchasedAmount - Amount of tokens purchased
     * @param _transferToken - Should tokens be transfered
     */
    function addPurchaser(
        address _purchaserAddr,
        uint256 _vestingIndex,
        uint256 _depositedTime,
        uint256 _depositedAmount,
        uint256 _purchasedAmount,
        bool _transferToken
    ) public onlyAdmin {
        internalAddPurchase(
            _purchaserAddr,
            _vestingIndex,
            _depositedTime,
            _depositedAmount,
            _purchasedAmount,
            0
        );
        if (_transferToken) {
            xJoyToken.transfer(_purchaserAddr, _purchasedAmount);
        }
    }

    /**
     * Lists all deposit history for given user
     * @param _address - purchaser to get deposit history of
     * @return An array of all deposit structures for given purchaser
     */
    function depositHistory(address _address)
        external
        view
        returns (DepositInfo[] memory)
    {
        return purchaserList[_address].deposits;
    }

    /**
     * Depositing a coin for xJoy token.
     * @param _coinAmount - Amount of tokens being deposited
     * @param _coinIndex  - Index of the coin in contracts list
     */
    function deposit(uint256 _coinAmount, uint256 _coinIndex) external onSale {
        internalDeposit(
            _msgSender(),
            _coinAmount,
            _coinIndex,
            currentVestingType,
            block.timestamp
        );
    }

    /**
     * Withdrawing Joy tokens after vesting.
     * Amounts are automatically calculated based on current vesting plan and time.
     */
    function withdraw() external notVested(_msgSender()) {
        uint256 withdrawalAmount = calcWithdrawalAmount(_msgSender());
        uint256 xJoyTokenAmount = xJoyToken.balanceOf(address(_msgSender()));
        uint256 withdrawAmount = withdrawalAmount;

        if (withdrawAmount > xJoyTokenAmount) {
            withdrawAmount = xJoyTokenAmount;
        }

        if (withdrawAmount <= 0) revert NOTHING_TO_WITHDRAW();

        xJoyToken.transferFrom(_msgSender(), address(this), withdrawAmount);
        joyToken.transfer(_msgSender(), withdrawAmount);

        purchaserList[_msgSender()].withdrawnAmount += withdrawAmount;

        emit TokensWithdrawn(_msgSender(), withdrawAmount);
    }

    /**
     * Checks withdrawal limit for the address
     * @param _userAddr - Address that is checked for current limit
     * @return The amount of tokens address can currently withdraw
     */
    function calcWithdrawalAmount(address _userAddr)
        public
        view
        returns (uint256)
    {
        PurchaserInfo storage purchaserInfo = purchaserList[_userAddr];

        uint256 allowedAmount = 0;
        for (uint256 i = 0; i < purchaserInfo.deposits.length; ) {
            DepositInfo storage theDeposit = purchaserInfo.deposits[i];
            VestingInfo storage vesting = vestingList[theDeposit.vestingType];
            uint256 cliff = theDeposit.depositTime + vesting.cliff;
            if (block.timestamp > cliff) {
                if (
                    block.timestamp >
                    theDeposit.depositTime + vesting.vestingCloseTimeline
                ) {
                    allowedAmount += theDeposit.purchasedAmount;
                } else {
                    uint256 stepSize = (theDeposit.purchasedAmount * vesting.releasePercentBasisPoints) / 10000;
                    uint256 stepsElapsed = (block.timestamp - cliff) / vesting.releaseStep;
                    uint value = stepsElapsed * stepSize;
                    if(value > theDeposit.purchasedAmount) {
                        value = theDeposit.purchasedAmount;
                    }
                    allowedAmount += value;
                }
            }
            unchecked {
                i++;
            }
        }

        return allowedAmount - purchaserInfo.withdrawnAmount;
    }

    /**
     * Withdraws all coins transfered as deposits to owner.
     * @param _treasury - Treasury address to move all coins to.
     */
    function withdrawAllCoins(address _treasury) public onlyOwner {
        IERC20Metadata USDC = IERC20Metadata(USDC_Address);
        IUSDT USDT = IUSDT(USDT_Address);
        uint256 usdcAmount = USDC.balanceOf(address(this));
        uint256 usdtAmount = USDT.balanceOf(address(this));
        if (usdcAmount > 0) USDC.transfer(_treasury, usdcAmount);
        if (usdtAmount > 0) USDT.transfer(_treasury, usdtAmount);
    }

    /**
     * Withdraws all XJoy tokens to owner.
     * @param _treasury - Treasury address that should receive all xJoy tokens.
     */
    function withdrawAllxJoyTokens(address _treasury) public onlyOwner {
        uint256 tokenAmount = xJoyToken.balanceOf(address(this));
        xJoyToken.transfer(_treasury, tokenAmount);
    }

    /**
     * Performs real deposit in the contract.
     * @param _address - An address of the depositor
     * @param _coinAmount - Amount of coins being deposited
     * @param _coinIndex - Index of the coin being deposited
     * @param _vestingIndex - Index of the vesting
     * @param _depositTime - Time when deposit took place
     */
    function internalDeposit(
        address _address,
        uint256 _coinAmount,
        uint256 _coinIndex,
        uint256 _vestingIndex,
        uint256 _depositTime
    ) internal {
        if (_vestingIndex >= vestingList.length) {
            revert WRONG_VESTING_TYPE();
        }
        if (_coinIndex > 1) revert COINS_NOT_SET();

        if (_coinIndex == 0) {
            IERC20Metadata USDC = IERC20Metadata(USDC_Address);
            USDC.transferFrom(_address, treasuryAddress, _coinAmount);
        } else if (_coinIndex == 1) {
            IUSDT USDT = IUSDT(USDT_Address);
            USDT.transferFrom(_address, treasuryAddress, _coinAmount);
        }

        uint256 joyAmountStar = pairInfo(_coinAmount);
        xJoyToken.transfer(_address, joyAmountStar);

        internalAddPurchase(
            _address,
            _vestingIndex,
            _depositTime,
            _coinAmount,
            joyAmountStar,
            0
        );
        emit TokensPurchased(_address, _coinAmount, joyAmountStar);
    }

    function internalAddPurchase(
        address _addr,
        uint256 _vestingIndex,
        uint256 _depositedTime,
        uint256 _depositedAmount,
        uint256 _purchasedAmount,
        uint256 _withdrawnAmount
    ) internal {
        if (_vestingIndex >= vestingList.length) {
            revert WRONG_VESTING_TYPE();
        }
        PurchaserInfo storage purchaserInfo = purchaserList[_addr];
        if (purchaserInfo.firstDepositTime == 0) {
            purchaserInfo.firstDepositTime = _depositedTime;
            purchaserAddress[totalPurchasers] = _addr;
            totalPurchasers += 1;
            xJoyToken.addToBlacklist(_addr);
        }

        // Get information about this vesting type
        VestingInfo storage vInfo = vestingList[uint256(_vestingIndex)];

        // calculate when vesting will finish
        uint256 vestingFinish = _depositedTime +
            vInfo.vestingCloseTimeline +
            vInfo.cliff;
        if (purchaserInfo.vestingTimeFinish < vestingFinish) {
            purchaserInfo.vestingTimeFinish = vestingFinish;
        }

        // Calculate new vestings cliff date
        uint256 unlockTime = _depositedTime + vInfo.cliff;
        if (
            purchaserInfo.firstUnlockTime > unlockTime ||
            purchaserInfo.firstUnlockTime == 0
        ) {
            purchaserInfo.firstUnlockTime = unlockTime;
        }

        // Update global amount of withdrawn amount by purchaser
        purchaserInfo.withdrawnAmount += _withdrawnAmount;

        // Last but not least - we need to add history of purchase
        purchaserInfo.deposits.push(
            DepositInfo(
                _vestingIndex,
                _depositedAmount,
                _purchasedAmount,
                _depositedTime
            )
        );
    }

    function pairInfo(uint256 _joyAmount)
        public
        view
        returns (uint256 joyAmountStar)
    {
        if (_joyAmount < 1e4) revert MIN_ONE_CENT();
        address FACTORY_ADDRESS = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
        IUniswapV2Pair pair = IUniswapV2Pair(
            UniswapV2Library.pairFor(
                FACTORY_ADDRESS,
                address(joyToken),
                USDC_Address
            )
        );
        if (address(pair) == address(0)) revert PAIR_NOT_SET();
        (uint256 reserves0, uint256 reserves1, ) = pair.getReserves();
        (uint256 reserveA, uint256 reserveB) = USDC_Address == pair.token0()
            ? (reserves1, reserves0)
            : (reserves0, reserves1);
        uint256 numerator = 1e6 * reserveA; // Joy Reserve
        uint256 denominator = reserveB; // USDC Reserve
        uint256 amountOutCents = (numerator / denominator) / 1e2; // 1 cent of USDC
        uint256 joyAmountInJoy = _joyAmount / 1e4; // 1 cent of JOY
        uint256 joyAmountInCalcInCents = joyAmountInJoy * amountOutCents; // Total Joy in cents
        joyAmountStar =
            joyAmountInCalcInCents +
            ((joyAmountInCalcInCents / 100) * 55); // 55% Discount
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import "./extensions/SecureToken.sol";

error DISABLED();
error ALLOWED_WHITELISTED_FROM();
error ALLOWED_WHITELISTED_TO(); 
error SWAP_IS_COOLING_DOWN();

contract JoyToken is SecureToken {

    enum TransferMode {
        DISABLED,
        ALLOWED_ALL,
        ALLOWED_WHITELISTED_FROM,
        ALLOWED_WHITELISTED_TO,
        ALLOWED_WHITELISTED_FROM_TO
    }

    TransferMode public transferMode;
    
    mapping (address => uint256) private swapBlock;

    bool public swapGuarded;

    /**
      * Joy Token constructor
      * @param _whitelist - Initial list of whitelisted receivers
      * @param _blacklist - Initial list of blacklisted addresses
      * @param _admins - Initial list of all administrators of the token
      */
    constructor(
        address[] memory _whitelist, 
        address[] memory _blacklist, 
        address[] memory _admins
    )
        SecureToken(_whitelist, _blacklist, _admins, "Joystick", "JOY") 
    {
            transferMode = TransferMode.ALLOWED_ALL;
    }

    /**
      * Setting new transfer mode for the token
      * @param _mode - New transfer mode to be set
      */
    function setTransferMode(TransferMode _mode) public onlyAdmin {
        transferMode = _mode;
    }

    /**
      * Checking transfer status
      * @param from - Transfer sender
      * @param to - Transfer recipient
      */
    function _checkTransferStatus(address from, address to) private view {
        if(transferMode == TransferMode.DISABLED) revert DISABLED();
        
        if(transferMode == TransferMode.ALLOWED_WHITELISTED_FROM_TO) {
            if(blacklisted[from] || !whitelisted[from]) revert ALLOWED_WHITELISTED_FROM(); 
            if(blacklisted[to] || !whitelisted[to]) revert ALLOWED_WHITELISTED_TO();
            return;
        }

        if(transferMode == TransferMode.ALLOWED_WHITELISTED_FROM) {
            if(blacklisted[from] || !whitelisted[from]) revert ALLOWED_WHITELISTED_FROM(); 
            return;
        }

        if (transferMode == TransferMode.ALLOWED_WHITELISTED_TO) {
            if(blacklisted[to] || !whitelisted[to]) revert ALLOWED_WHITELISTED_TO();
            return;
        }
    }

    /**
      * Prevent MEV Bots from doing Sandwich Attacks and Arbitrage
      * Enforces a single JOY Transfer per transaction
      * @param _swapGuardStatus - True or false
      */
    function setProtectedSwaps(bool _swapGuardStatus) external onlyOwner {
        swapGuarded = _swapGuardStatus;
    }

    /**
      * Enforces atleast 1 block gap for swaps and transfers
      * This prevents MEV Bots (Maximal Extractable Value)
      * @param from - Address of sender
      * @param to - Address of recipient
      */
    function _checkSwapCooldown(address from, address to) private {
        if(swapGuarded) {
            if(swapBlock[from] == block.number) revert SWAP_IS_COOLING_DOWN();
            swapBlock[to] = block.number;
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256) override internal virtual {
        _checkTransferStatus(from, to);
        _checkSwapCooldown(from, to);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import "./extensions/SecureToken.sol";

contract XJoyToken is SecureToken {
    /**
     * Flag indicating if contract is guarding transfers from blacklisted sources and sniper attacks
     */
    bool public guarding;

    event Guarding(bool _status);

    /**
     * Tokens constructor
     *
     * @param _whitelist - Initial list of whitelisted receivers
     * @param _blacklist - Initial list of blacklisted addresses
     * @param _admins - Initial list of all administrators of the token
     * @param _guarding - If SecureToken is guarding the transfers from the constructor moment
     */
    constructor(
        address[] memory _whitelist,
        address[] memory _blacklist,
        address[] memory _admins,
        bool _guarding,
        uint256 _initialSupply
    )
        SecureToken(
            _whitelist,
            _blacklist,
            _admins,
            "xJOY Token",
            "xJOY"
        )
    {
        guarding = _guarding;
        mint(_msgSender(), _initialSupply);
    }

    /**
     * Turning on or off guarding mechanism of the contract
     *
     * @param _guard - Flag if guarding mechanism should be turned on or off
     */
    function setGuard(bool _guard) external onlyAdmin {
        if (guarding != _guard) {
            guarding = _guard;
            emit Guarding(_guard);
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256
    ) internal virtual override {
        if (guarding) {
            require(!blacklisted[from] || whitelisted[to], "SecureToken: This address is forbidden from making any transfers");
        }
    }
    
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IUSDT {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external;
    function approve(address spender, uint value) external;
    function transferFrom(address from, address to, uint value) external;
    function allowance(address owner, address spender) external view returns (uint);
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
}

// SPDX-License-Identifier: UNLICENCED
pragma solidity =0.8.11;

import '../interfaces/IUniswapV2Pair.sol';

library UniswapV2Library {
    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        bytes32 tmp = keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
            ));
        pair = address(uint160(uint256(tmp)));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'UniswapV2Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        amountB = (amountA * reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn * 997;
        uint numerator = amountInWithFee * reserveOut;
        uint denominator = (reserveIn * 1000) + amountInWithFee;
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint numerator = (reserveIn * amountOut) * 1000;
        uint denominator = (reserveOut -amountOut) * 997;
        amountIn = (numerator / denominator) + 1;
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

error NOT_AUTHORIZED();
error MAX_TOTAL_SUPPLY();

contract SecureToken is AccessControl, ERC20, Ownable {
    /**
     * Maximum totalSupply 
     */
    uint256 public maxTotalSupply;

    /**
     * A map of all blacklisted addresses
     */
    mapping(address => bool) public blacklisted;

    /**
     * A map of whitelisted receivers.
     */
    mapping(address => bool) public whitelisted;

    event WhitelistedMany(address[] _users);
    event Whitelisted(address _user);
    event RemovedFromWhitelist(address _user);

    event BlacklistedMany(address[] _users);
    event Blacklisted(address _user);
    event RemovedFromBlacklist(address _user);

    modifier onlyAdmin() {
        _checkRole(DEFAULT_ADMIN_ROLE);
        _;
    }

    /**
     * Constructor of SecureToken contract
     * @param _whitelist - List of addresses to be whitelisted as always allowed token transfering
     * @param _blacklist  - Initial blacklisted addresses to forbid any token transfers
     * @param _admins    - List of administrators that can change this contract settings
     */
    constructor(
        address[] memory _whitelist,
        address[] memory _blacklist,
        address[] memory _admins,
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        maxTotalSupply = 5000000000 * 1e18; // 5B Joy & xJoy

        if (_admins.length > 0) {
            for (uint i; i < _admins.length; ) {
                _grantRole(DEFAULT_ADMIN_ROLE, _admins[i]);
                unchecked { i++; }
            }
        }

        if (_whitelist.length > 0) {
            addManyToWhitelist(_whitelist);
        }
        if (_blacklist.length > 0) {
            addManyToBlacklist(_blacklist);
        }
    }

    /**
     * Adding new admin to the contract
     * @param _admin - New admin to be added to administrator list
     */
    function addAdmin(address _admin) external onlyAdmin {
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
    }

    /**
     * Removing admin from token administrators list
     * @param _admin - Admin to be removed from admin list
     */
    function removeAdmin(address _admin) external onlyAdmin {
        if (_admin == owner()) revert NOT_AUTHORIZED();
        _revokeRole(DEFAULT_ADMIN_ROLE, _admin);
    }
    
    /**
     * Minting tokens for many addressess
     * @param _addrs - Address to mint new tokens to
     * @param _amounts - Amount new tokens to be minted
     */
    function mintMany(address[] memory _addrs, uint256[] memory _amounts) external onlyOwner {
        uint256 totalMinted;
        for (uint i=0; i<_addrs.length; i++) {
            _mint(_addrs[i], _amounts[i]);
            totalMinted += _amounts[i];
        }
        if(totalSupply() > maxTotalSupply) revert MAX_TOTAL_SUPPLY();
    }

    /**
     * Minting new tokens
     * @param _to - Address to mint new tokens to
     * @param _amount - Amount new tokens to be minted
     */
    function mint(address _to, uint256 _amount) public onlyOwner {
        if(totalSupply() + _amount > maxTotalSupply) revert MAX_TOTAL_SUPPLY();
        _mint(_to, _amount);
    }

    /**
     * Burning existing tokens
     * @param _from - Address to burn tokens from
     * @param _amount - Amount of tokens to be burned
     */
    function burn(address _from, uint256 _amount) public onlyOwner {
        _burn(_from, _amount);
    }

    /**
     * Adding new address to the blacklist
     * @param _blacklisted - New address to be added to the blacklist
     */
    function addToBlacklist(address _blacklisted) public onlyAdmin {
        blacklisted[_blacklisted] = true;
        emit Blacklisted(_blacklisted);
    }

    /**
     * Adding many addresses to the blacklist
     * @param _blacklisted - An array of addresses to be added to the blacklist
     */
    function addManyToBlacklist(address[] memory _blacklisted) public onlyAdmin {
        for (uint i; i < _blacklisted.length; ) {
            blacklisted[_blacklisted[i]] = true;
            unchecked { i++; }
        }
        emit BlacklistedMany(_blacklisted);
    }

    /**
     * Removing address from the blacklist
     * @param _address - Address to be removed from the blacklist
     */
    function removeFromBlacklist(address _address) public onlyAdmin {
        blacklisted[_address] = false;
        emit RemovedFromBlacklist(_address);
    }

    /**
     * Adding an address to contracts whitelist
     * @param _whitelisted - Address to be added to the whitelist
     */
    function addToWhitelist(address _whitelisted) public onlyAdmin {
        whitelisted[_whitelisted] = true;
        emit Whitelisted(_whitelisted);
    }

    /**
     * Adding many addresses to the whitelist
     * @param _whitelisted - An array of addresses to be added to the whitelist
     */
    function addManyToWhitelist(address[] memory _whitelisted) public onlyAdmin {
        for (uint i; i < _whitelisted.length; ) {
            whitelisted[_whitelisted[i]] = true;
            unchecked { i++; }
        }
        emit WhitelistedMany(_whitelisted);
    }

    /**
     * Removing an address from the whitelist
     * @param _address - Address to be removed from the whitelist
     */
    function removeFromWhitelist(address _address) public onlyAdmin {
        whitelisted[_address] = false;
        emit RemovedFromWhitelist(_address);
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

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
     * @dev Moves `amount` of tokens from `from` to `to`.
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}