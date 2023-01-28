// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract TokenPreSale is ReentrancyGuard, Ownable {
    uint256 public presaleId;
    uint256 public BASE_MULTIPLIER;
    uint256 public MONTH;
    address public ROUTER;

    struct PresaleTiming {
        uint256 startTimePhase1;
        uint256 endTimePhase1;
        uint256 startTimePhase2;
        uint256 endTimePhase2;
    }

    struct PresaleData {
        address saleToken;
        uint256 price;
        uint256 tokensToSell;
        uint256 maxAmountTokensForSalePerUser;
        uint256 amountTokensForLiquidity;
        uint256 baseDecimals;
        uint256 inSale;
    }

    struct PresaleVesting {
        uint256 vestingStartTime;
        uint256 vestingCliff;
        uint256 vestingPeriod;
    }
    

    struct PresaleBuyData {
        uint256 marketingPercentage;
        bool presaleFinalized;
        address[] whitelist;
    }

    struct Presale {
    PresaleTiming presaleTiming;
    PresaleData presaleData;
    PresaleVesting presaleVesting;
    PresaleBuyData presaleBuyData;
    }

    struct Vesting {
        uint256 totalAmount;
        uint256 claimedAmount;
        uint256 claimStart;
        uint256 claimEnd;
    }

    mapping(uint256 => bool) public paused;
    mapping(uint256 => Presale) public presale;
    mapping(address => mapping(uint256 => Vesting)) public userVesting;

    constructor(address _router) public {
        BASE_MULTIPLIER = (10**18);
        MONTH = (30 * 24 * 3600);
        ROUTER = _router;
    }


    /**
     * @dev Creates a new presale
     * @param _price Per token price multiplied by (10**18). how much ETH does 1 token cost
     * @param _tokensToSell No of tokens to sell without denomination. If 1 million tokens to be sold then - 1_000_000 has to be passed
     * @param _maxAmountTokensForSalePerUser Max no of tokens someone can buy
     * @param _amountTokensForLiquidity Amount of tokens for liquidity
     * @param _baseDecimals No of decimals for the token. (10**18), for 18 decimal token
     * @param _vestingCliff Cliff period for vesting in seconds
     * @param _vestingPeriod Total vesting period(after vesting cliff) in seconds
     * @param _marketingPercentage Percentage of raised funds that will go to the team
     * @param _presaleFinalized false by default, can only be true after liquidity has been added
     * @param _whitelist array of addresses that are allowed to buy in phase 1
     */
    function createPresale(
        uint256 _price,
        uint256 _tokensToSell,
        uint256 _maxAmountTokensForSalePerUser,
        uint256 _amountTokensForLiquidity,
        uint256 _baseDecimals,
        uint256 _inSale,
        uint256 _vestingCliff,
        uint256 _vestingPeriod,
        uint256 _marketingPercentage,
        bool _presaleFinalized,
        address[] memory _whitelist
    ) external onlyOwner {
        require(validatePrice(_price), "Zero price");
        require(validateMarketingPercentage(_marketingPercentage), "Can not be greater than 40 percent");
        require(validatePresaleFinalized(_presaleFinalized), "Presale can not be finalized");
        require(validateTokensToSell(_tokensToSell), "Zero tokens to sell");
        require(validateBaseDecimals(_baseDecimals), "Zero decimals for the token");
        
        PresaleTiming memory timing = PresaleTiming(0, 0, 0, 0);
        PresaleData memory data = PresaleData(address(0), _price, _tokensToSell, _maxAmountTokensForSalePerUser, _amountTokensForLiquidity, _baseDecimals, _inSale);
        PresaleVesting memory vesting = PresaleVesting(0, _vestingCliff, _vestingPeriod);
        PresaleBuyData memory buyData = PresaleBuyData(_marketingPercentage, _presaleFinalized, _whitelist);

        presaleId++;

        presale[presaleId] = Presale(timing, data, vesting, buyData);

    }

    /**
     * @dev To add the sale times
     * @param _id Presale id to update
     * @param _startTimePhase1 New start time
     * @param _endTimePhase1 New end time
     * @param _startTimePhase2 New start time
     * @param _endTimePhase2 New end time
     * @param _vestingStartTime new vesting start time
     */
    function addSaleTimes(
    uint256 _id,
    uint256 _startTimePhase1,
    uint256 _endTimePhase1,
    uint256 _startTimePhase2,
    uint256 _endTimePhase2,
    uint256 _vestingStartTime 
    ) external checkPresaleId(_id) onlyOwner {
        require(_startTimePhase1 > 0 || _endTimePhase1 > 0 || _startTimePhase2 > 0 || _endTimePhase2 > 0 || _vestingStartTime > 0, "Invalid parameters");

        if (_startTimePhase1 > 0) {
            require(block.timestamp < _startTimePhase1, "Sale time in past");
            presale[_id].presaleTiming.startTimePhase1 = _startTimePhase1;
        }

        if (_endTimePhase1 > 0) {
            require(block.timestamp < _endTimePhase1, "Sale end in past");
            require(_endTimePhase1 > _startTimePhase1, "Sale ends before sale start");
            presale[_id].presaleTiming.endTimePhase1 = _endTimePhase1;
        }

        if (_startTimePhase2 > 0) {
            require(block.timestamp < _startTimePhase2, "Sale time in past");
            presale[_id].presaleTiming.startTimePhase2 = _startTimePhase2;
        }

        if (_endTimePhase2 > 0) {
            require(block.timestamp < _endTimePhase2, "Sale end in past");
            require(_endTimePhase2 > _startTimePhase2, "Sale ends before sale start");
            presale[_id].presaleTiming.endTimePhase2 = _endTimePhase2;
        }

        if (_vestingStartTime > 0) {
            require(
            _vestingStartTime >= presale[_id].presaleTiming.endTimePhase2,
            "Vesting starts before Presale ends"
        );
            presale[_id].presaleVesting.vestingStartTime = _vestingStartTime;
        }
    }

    /**
     * @dev To update the sale times
     * @param _id Presale id to update
     * @param _startTimePhase1 New start time
     * @param _endTimePhase1 New end time
     * @param _startTimePhase2 New start time
     * @param _endTimePhase2 New end time
     */
    function changeSaleTimes(
    uint256 _id,
    uint256 _startTimePhase1,
    uint256 _endTimePhase1,
    uint256 _startTimePhase2,
    uint256 _endTimePhase2
    ) external checkPresaleId(_id) onlyOwner {
        require(_startTimePhase1 > 0 || _endTimePhase1 > 0 || _startTimePhase2 > 0 || _endTimePhase2 > 0, "Invalid parameters");

        if (_startTimePhase1 > 0) {
            require(
                block.timestamp < presale[_id].presaleTiming.startTimePhase1,
                "Sale already started"
            );
            require(block.timestamp < _startTimePhase1, "Sale time in past");
            presale[_id].presaleTiming.startTimePhase1 = _startTimePhase1;
        }

        if (_endTimePhase1 > 0) {
            require(
                block.timestamp < presale[_id].presaleTiming.endTimePhase1,
                "Sale already ended"
            );
            require(_endTimePhase1 > presale[_id].presaleTiming.startTimePhase1, "Invalid endTime");
            presale[_id].presaleTiming.endTimePhase1 = _endTimePhase1;
        }

        if (_startTimePhase2 > 0) {
            require(
                block.timestamp < presale[_id].presaleTiming.startTimePhase2,
                "Sale already started"
            );
            require(block.timestamp < _startTimePhase2, "Sale time in past");
            presale[_id].presaleTiming.startTimePhase2 = _startTimePhase2;
        }

        if (_endTimePhase2 > 0) {
            require(
                block.timestamp < presale[_id].presaleTiming.endTimePhase2,
                "Sale already ended"
            );
            require(_endTimePhase2 > presale[_id].presaleTiming.startTimePhase2, "Invalid endTime");
            presale[_id].presaleTiming.endTimePhase2 = _endTimePhase2;
        }
    }

    /**
     * @dev To whitelist addresses
     * @param _id Presale id to update
     * @param _wallets Array of wallet addresses
     */
    function addToWhitelist(uint256 _id, address[] memory _wallets)
        external
        checkPresaleId(_id)
        onlyOwner
    {
        for (uint256 i = 0; i < _wallets.length; i++) {
            presale[_id].presaleBuyData.whitelist.push(_wallets[i]);
        }
    }

    /**
     * @dev To remove addresses from the whitelist
     * @param _id Presale id to update
     * @param _wallets Array of wallet addresses
     */
    function removeFromWhitelist(uint256 _id, address[] memory _wallets)
        external
        checkPresaleId(_id)
        onlyOwner
    {
        for (uint256 i = 0; i < _wallets.length; i++) {
            for (uint256 j = 0; j < presale[_id].presaleBuyData.whitelist.length; j++) {
                if (presale[_id].presaleBuyData.whitelist[j] == _wallets[i]) {
                    delete presale[_id].presaleBuyData.whitelist[j];
                    break;
                }
            }
        }
    }

    /**
     * @dev To update the vesting start time
     * @param _id Presale id to update
     * @param _vestingStartTime New vesting start time
     */
    function changeVestingStartTime(uint256 _id, uint256 _vestingStartTime)
        external
        checkPresaleId(_id)
        onlyOwner
    {
        require(
            _vestingStartTime >= presale[_id].presaleTiming.endTimePhase2,
            "Vesting starts before Presale ends"
        );
        presale[_id].presaleVesting.vestingStartTime = _vestingStartTime;
    }

    /**
     * @dev To update the sale token address
     * @param _id Presale id to update
     * @param _newAddress Sale token address
     */
    function changeSaleTokenAddress(uint256 _id, address _newAddress)
        external
        checkPresaleId(_id)
        onlyOwner
    {
        require(_newAddress != address(0), "Zero token address");
        presale[_id].presaleData.saleToken = _newAddress;
    }

    /**
     * @dev To update the price
     * @param _id Presale id to update
     * @param _newPrice New sale price of the token
     */
    function changePrice(uint256 _id, uint256 _newPrice)
        external
        checkPresaleId(_id)
        onlyOwner
    {
        require(_newPrice > 0, "Zero price");
        require(
            presale[_id].presaleTiming.startTimePhase1 > block.timestamp,
            "Sale already started"
        );
        require(
            presale[_id].presaleTiming.startTimePhase2 > block.timestamp,
            "Sale already started"
        );
        presale[_id].presaleData.price = _newPrice;
    }

     /**
     * @dev To update the amount of tokens that will be added to liquidity
     * @param _id Presale id to update
     * @param _newAmountTokensForLiquidity new amount
     */
    function changeAmountTokensForLiquidity(uint256 _id, uint256 _newAmountTokensForLiquidity)
        external
        checkPresaleId(_id)
        onlyOwner
    {
        presale[_id].presaleData.maxAmountTokensForSalePerUser = _newAmountTokensForLiquidity;
    }

     /**
     * @dev To update the marketing percentage that will go to the team
     * @param _id Presale id to update
     * @param _newMarketingPercentage The new marketing percentage
     */
    function changeMarketingPercentage(uint256 _id, uint256 _newMarketingPercentage)
        external
        checkPresaleId(_id)
        onlyOwner
    {
        require(validateMarketingPercentage(_newMarketingPercentage), "Can not be greater than 40 percent");
        presale[_id].presaleBuyData.marketingPercentage = _newMarketingPercentage;
    }

     /**
     * @dev To update the max amount of tokens someone can buy
     * @param _id Presale id to update
     * @param _newMaxAmountTokensForSalePerUser New max amount 
     */
    function changeMaxAmountTokensForSalePerUser(uint256 _id, uint256 _newMaxAmountTokensForSalePerUser)
        external
        checkPresaleId(_id)
        onlyOwner
    {
        require(_newMaxAmountTokensForSalePerUser < presale[_id].presaleData.tokensToSell, "number too big");
        require(
            presale[_id].presaleTiming.startTimePhase1 > block.timestamp,
            "Sale already started"
        );
        require(
            presale[_id].presaleTiming.startTimePhase2 > block.timestamp,
            "Sale already started"
        );
        presale[_id].presaleData.maxAmountTokensForSalePerUser = _newMaxAmountTokensForSalePerUser;
    }


    /**
     * @dev To pause the presale
     * @param _id Presale id to update
     */
    function pausePresale(uint256 _id) external checkPresaleId(_id) onlyOwner {
        require(!paused[_id], "Already paused");
        paused[_id] = true;
    }

    /**
     * @dev To unpause the presale
     * @param _id Presale id to update
     */
    function unPausePresale(uint256 _id)
        external
        checkPresaleId(_id)
        onlyOwner
    {
        require(paused[_id], "Not paused");
        paused[_id] = false;
    }

    /**
     * @dev To finalize the sale by adding the tokens to liquidity and sending the marketing percentage to the team
     * @param _id Presale id to update
     */
    function finalizeAndAddLiquidity(uint256 _id)
        external
        checkPresaleId(_id)
        onlyOwner
    {
        require(presale[_id].presaleBuyData.presaleFinalized == false, "already finalized");
        transferMarketingFunds(_id);
        addLiquidity(_id);
    }

    function validateTiming(PresaleTiming memory _timing) internal view returns (bool) {
        if (_timing.startTimePhase1 <= block.timestamp || _timing.endTimePhase1 <= _timing.startTimePhase1) return false;
        if (_timing.startTimePhase2 <= block.timestamp || _timing.endTimePhase2 <= _timing.startTimePhase2) return false;
        return true;
    }

    function validatePrice(uint256 _price) internal pure returns (bool) {
        return _price > 0;
    }

    function validateMarketingPercentage(uint256 _marketingPercentage) internal pure returns (bool) {
        return _marketingPercentage <= 40;
    }

    function validatePresaleFinalized(bool _presaleFinalized) internal pure returns (bool) {
        return !_presaleFinalized;
    }

    function validateTokensToSell(uint256 _tokensToSell) internal pure returns (bool) {
        return _tokensToSell > 0;
    }

    function validateBaseDecimals(uint256 _baseDecimals) internal pure returns (bool) {
        return _baseDecimals > 0;
    }

    function validateVesting(uint256 _vestingStartTime, uint256 endTimePhase2) internal pure returns (bool) {
        return _vestingStartTime >= endTimePhase2;
    }

    function transferMarketingFunds(uint256 _id) internal {

        uint256 ETHBalance = address(this).balance;

        uint256 marketingAmountETH = ETHBalance * (presale[_id].presaleBuyData.marketingPercentage / 100);

        if (ETHBalance > 0) {
            address payable teamAddress = payable(owner());
            teamAddress.transfer(marketingAmountETH);
        }
    }


    function addLiquidity(uint256 _id) internal {
        address saleTokenAddress = presale[_id].presaleData.saleToken;
        uint256 ETHBalance = address(this).balance;

        // allowance
        (bool successAllowanceSaleToken, ) = address(saleTokenAddress).call(
            abi.encodeWithSignature(
                "approve(address,uint256)",
                ROUTER,
                presale[_id].presaleData.amountTokensForLiquidity
            )
        );

        // add liquidity
        (bool successAddLiq, ) = address(ROUTER).call{value: ETHBalance}(
            abi.encodeWithSignature(
                "addLiquidityETH(address,uint256,uint256,uint256,address,uint256)",
                presale[_id].presaleData.saleToken,
                presale[_id].presaleData.amountTokensForLiquidity,
                0,
                0,
                owner(),
                block.timestamp + 600
            )
        );
    }


    modifier checkPresaleId(uint256 _id) {
        require(_id > 0 && _id <= presaleId, "Invalid presale id");
        _;
    }

    modifier checkSaleState(uint256 _id, uint256 amount) {
        require(
            block.timestamp >= presale[_id].presaleTiming.startTimePhase1 &&
                block.timestamp <= presale[_id].presaleTiming.endTimePhase2,
            "Invalid time for buying"
        );
        require(
            amount > 0 && amount <= presale[_id].presaleData.inSale,
            "Invalid sale amount"
        );
        _;
    }

    function isWhitelisted(uint256 _id, address _address) internal view returns (bool) {
        for (uint256 i = 0; i < presale[_id].presaleBuyData.whitelist.length; i++) {
            if (presale[_id].presaleBuyData.whitelist[i] == _address) {
                return true;
            }
        }
        return false;
    }

    function isPhaseOne(uint256 _id) internal view returns (bool) {
        if (presale[_id].presaleTiming.startTimePhase1 > block.timestamp && presale[_id].presaleTiming.endTimePhase1 < block.timestamp) {
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev To buy into a presale using ETH
     * @param _id Presale id
     * @param amount No of tokens to buy. not in wei
     */
    function buyWithEth(uint256 _id, uint256 amount)
        external
        payable
        checkPresaleId(_id)
        checkSaleState(_id, amount)
        nonReentrant
        returns (bool)
    {
        require(amount <= presale[_id].presaleData.maxAmountTokensForSalePerUser, "You are trying to buy too many tokens");
        require(!paused[_id], "Presale paused");
        uint256 ethAmount = amount * presale[_id].presaleData.price;
        require(msg.value >= ethAmount, "Less payment");
        uint256 excess = msg.value - ethAmount;
        presale[_id].presaleData.inSale -= amount;
        Presale memory _presale = presale[_id];

        if (isPhaseOne(_id)) {
            require(isWhitelisted(_id, msg.sender), "Not whitelisted");
        }

        if (userVesting[_msgSender()][_id].totalAmount > 0) {
        userVesting[_msgSender()][_id].totalAmount += (amount *
            _presale.presaleData.baseDecimals);
        } else {
            userVesting[_msgSender()][_id] = Vesting(
                (amount * _presale.presaleData.baseDecimals),
                0,
                _presale.presaleVesting.vestingStartTime + _presale.presaleVesting.vestingCliff,
                _presale.presaleVesting.vestingStartTime +
                    _presale.presaleVesting.vestingCliff +
                    _presale.presaleVesting.vestingPeriod
            );
        }
        sendValue(payable(address(this)), ethAmount);
        if (excess > 0) sendValue(payable(_msgSender()), excess);
        return true;
    }


    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Low balance");
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "ETH Payment failed");
    }

    /**
     * @dev Helper funtion to get claimable tokens for a given presale.
     * @param user User address
     * @param _id Presale id
     */
    function claimableAmount(address user, uint256 _id)
        public
        view
        checkPresaleId(_id)
        returns (uint256)
    {
        Vesting memory _user = userVesting[user][_id];
        require(_user.totalAmount > 0, "Nothing to claim");
        uint256 amount = _user.totalAmount - _user.claimedAmount;
        require(amount > 0, "Already claimed");

        if (block.timestamp < _user.claimStart) return 0;
        if (block.timestamp >= _user.claimEnd) return amount;

        uint256 noOfMonthsPassed = (block.timestamp - _user.claimStart) / MONTH;

        uint256 perMonthClaim = (_user.totalAmount * BASE_MULTIPLIER * MONTH) /
            (_user.claimEnd - _user.claimStart);

        uint256 amountToClaim = ((noOfMonthsPassed * perMonthClaim) /
            BASE_MULTIPLIER) - _user.claimedAmount;

        return amountToClaim;
    }

    /**
     * @dev To claim tokens after vesting cliff from a presale
     * @param user User address
     * @param _id Presale id
     */
    function claim(address user, uint256 _id) public returns (bool) {
        uint256 amount = claimableAmount(user, _id);
        require(presale[_id].presaleBuyData.presaleFinalized == true, "Liquidity has not been added yet");
        require(amount > 0, "Zero claim amount");
        require(
            presale[_id].presaleData.saleToken != address(0),
            "Presale token address not set"
        );
        require(
            amount <=
                IERC20(presale[_id].presaleData.saleToken).balanceOf(
                    address(this)
                ),
            "Not enough tokens in the contract"
        );
        userVesting[user][_id].claimedAmount += amount;
        bool status = IERC20(presale[_id].presaleData.saleToken).transfer(
            user,
            amount
        );
        require(status, "Token transfer failed");
        return true;
    }

    /**
     * @dev To claim tokens after vesting cliff from a presale
     * @param users Array of user addresses
     * @param _id Presale id
     */
    function claimMultiple(address[] calldata users, uint256 _id)
        external
        returns (bool)
    {
        require(presale[_id].presaleBuyData.presaleFinalized == true, "Liquidity has not been added yet");
        require(users.length > 0, "Zero users length");
        for (uint256 i; i < users.length; i++) {
            require(claim(users[i], _id), "Claim failed");
        }
        return true;
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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
                /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
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