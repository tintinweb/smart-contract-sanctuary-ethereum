// SPDX-License-Identifier: UNLICENSE
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ITokenSale.sol";
import "./interfaces/ITokenVesting.sol";
import "../blooprint-nft/interfaces/IBlooprintNft.sol";
import "../fee-storage/interfaces/IFeeStorage.sol";
import "../interfaces/IWETH.sol";

/*
    TS00: Address 0x00
    TS01: Invalid input
    TS01.1: Invalid amount
    TS01.2: Invalid price
    TS01.3: Invalid timestamp
    TS01.4: Invalid period duration
    TS01.5: Invalid number of periods
    TS02: Invalid payable value
    TS03: Amount purchased in this period exceeds
    TS04: It is not yet time 
    TS05: You have not bought tokens
    TS06: You do not have tokens to claim
    TS07: Sale has withdraw
    TS08: Sale sold out
    TS09: Vesting is not over yet
    TS10: Sale does not existed
*/

contract TokenSale is ITokenSale, Ownable {
    using SafeERC20 for IERC20;

    uint public constant PRECISION_DECIMALS = 1e4;
    uint public constant PRICE_DECIMALS = 1e10;

    mapping(uint => mapping(address => mapping(uint => uint))) public purchaseAmountPeriod; // [saleId][address][period]
    mapping(uint => mapping(address => mapping(uint => uint))) public depositAmountPeriod; // [saleId][address][period]
    mapping(uint => mapping(uint => uint)) public totalDepositPeriod; // [saleId][period]
    mapping(uint => mapping(uint => uint)) public saleAmountPeriod; // [saleId][period]
    mapping(uint => mapping(address => BuyerInfo)) public buyerInfo; // [saleId][address]
    mapping(uint => bool) public checkWithdraw;
    mapping(uint => Vesting) public vestingInfo; // [saleId]
    mapping(uint => mapping(uint => uint[])) public nftLevels; // [saleId][period]

    Sale[] public sales;
    uint public fee;
    uint public minPayable;

    address public immutable usd;
    address public immutable weth;
    ITokenVesting public immutable tokenVesting;
    IBlooprintNft public blooprintNft;
    IFeeStorage public feeStorage;

    constructor(
        uint _fee,
        uint _minPayable,
        address _tokenVesting,
        address _usd,
        address _weth,
        address _blooprintNft
    ) {
        fee = _fee;
        minPayable = _minPayable;
        usd = _usd;
        weth = _weth;
        tokenVesting = ITokenVesting(_tokenVesting);
        blooprintNft = IBlooprintNft(_blooprintNft);
    }

    modifier onlyExistedSale(uint saleId) {
        require(saleId < sales.length, "TS10");
        _;
    }

    // Admin functions
    function setFee(uint _fee) external onlyOwner {
        fee = _fee;
    }

    function setFeeStorage(address _feeStorage) public onlyOwner {
        feeStorage = IFeeStorage(_feeStorage);
    }

    function setMinPayable(uint _minPayable) external onlyOwner {
        minPayable = _minPayable;
    }

    function saleToken(Sale memory sale, uint[][] memory _nftLevels, uint cliff) external onlyOwner {
        _validateSale(sale);

        uint256 saleId = sales.length;
        if (sale.options.hasPeriodAccess) {
            require(_nftLevels.length == sale.numberOfPeriods, "TS01");
            for (uint i = 0; i < _nftLevels.length; i++) {
                nftLevels[saleId][i] = _nftLevels[i];
            }
        }

        _createVestingSchedule(
            sale.startTime + sale.periodDuration * sale.numberOfPeriods,
            sale.claimDuration * sale.numberOfClaims,
            sale.claimDuration,
            cliff,
            sale.saleAmount,
            sale.token
        );
        sales.push(sale);

        emit SaleToken(sales.length - 1, sale);
    }

    function _createVestingSchedule(
        uint start,
        uint duration,
        uint slicePeriodSeconds,
        uint cliff,
        uint amount,
        address token
    ) private {
        vestingInfo[sales.length].cliff = start + cliff;
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        // IERC20(token).safeTransferFrom(msg.sender, address(tokenVesting), amount);
        tokenVesting.createVestingSchedule(
            address(this),
            start,
            cliff,
            duration,
            slicePeriodSeconds,
            amount,
            token
        );
    }

    function buyToken(
        uint saleId,
        uint payingAmount,
        uint[] calldata nfts
    ) external payable onlyExistedSale(saleId) {
        Sale memory sale = sales[saleId];
        uint currentPeriod = timePeriod(saleId);
        uint value = msg.value;
        require(block.timestamp >= sale.startTime && currentPeriod <= sale.numberOfPeriods, "TS01.3");
        address user = msg.sender;

        if (sale.options.hasPeriodAccess) {
            _verifyNFTs(user, nftLevels[saleId][currentPeriod - 1], nfts);
        }

        if (sale.options.feeInPayingAsset) {
            require(value >= minPayable, "TS02"); //UPDATE FOR USDT
            value = sale.options.acceptsETH ? chargeFee(value) : chargeFee(payingAmount);
            if (sale.options.fixedPrice) {
                _buyTokenWithFixedPrice(saleId, sale, user, value, currentPeriod);
            } else {
                _buyTokenWithFlexiblePrice(saleId, sale, user, value, currentPeriod);
            }
        } else {}

        emit BuyToken(saleId, currentPeriod, user, value);
    }

    function _buyTokenWithFixedPrice(
        uint saleId,
        Sale memory sale,
        address user,
        uint payingAmount,
        uint currentPeriod
    ) private {
        uint totalAmount = (payingAmount * PRICE_DECIMALS) / sale.price;
        totalAmount = convertDecimal(totalAmount, IERC20Metadata(sale.token).decimals());

        uint chargedAmount = chargeFee(totalAmount);

        uint periodSold = saleAmountPeriod[saleId][currentPeriod] + totalAmount;
        require(periodSold <= sale.saleAmount / sale.numberOfPeriods, "TS03");

        sales[saleId].soldAmount += totalAmount;
        sales[saleId].totalPaying += payingAmount;
        totalDepositPeriod[saleId][currentPeriod] += payingAmount;
        saleAmountPeriod[saleId][currentPeriod] = periodSold;
        purchaseAmountPeriod[saleId][user][currentPeriod] += chargedAmount;
        buyerInfo[saleId][user].purchaseAmount += chargedAmount;
        buyerInfo[saleId][user].lastPurchasePeriod = currentPeriod;
        if (buyerInfo[saleId][user].firstPurchasePeriod == 0) {
            buyerInfo[saleId][user].firstPurchasePeriod = currentPeriod;
        }
    }

    function _buyTokenWithFlexiblePrice(
        uint saleId,
        Sale memory sale,
        address user,
        uint payingAmount,
        uint currentPeriod
    ) private {
        depositAmountPeriod[saleId][user][currentPeriod] += payingAmount;
        sales[saleId].totalPaying += payingAmount;
        totalDepositPeriod[saleId][currentPeriod] += payingAmount;
        buyerInfo[saleId][user].lastPurchasePeriod = currentPeriod;
        if (buyerInfo[saleId][user].firstPurchasePeriod == 0) {
            buyerInfo[saleId][user].firstPurchasePeriod = currentPeriod;
        }

        if (saleAmountPeriod[saleId][currentPeriod] == 0) {
            uint amountPerPeriod = (sale.saleAmount - sale.soldAmount) /
                (sale.numberOfPeriods - currentPeriod + 1);
            saleAmountPeriod[saleId][currentPeriod] = amountPerPeriod;
            sales[saleId].soldAmount += amountPerPeriod;
        }
    }

    function claim(uint saleId) external onlyExistedSale(saleId) {
        address user = msg.sender;
        BuyerInfo memory _buyerInfo = buyerInfo[saleId][user];
        Sale memory sale = sales[saleId];
        uint cliff = vestingInfo[saleId].cliff;
        require(block.timestamp > cliff, "TS04");

        _releaseVesting(saleId);

        uint purchaseAmount = _buyerInfo.purchaseAmount;
        if (!sale.options.fixedPrice && purchaseAmount == 0) {
            require(_buyerInfo.firstPurchasePeriod > 0, "TS05");
            purchaseAmount = computeTokenPurchased(saleId, user, _buyerInfo);
            buyerInfo[saleId][user].purchaseAmount = purchaseAmount;
        }

        uint claimable = ((vestingInfo[saleId].released * purchaseAmount) / sale.saleAmount) -
            _buyerInfo.claimedAmount;
        require(claimable > 0, "TS06");

        buyerInfo[saleId][user].claimedAmount += claimable;
        IERC20(sale.token).safeTransfer(user, claimable);
        emit Claim(user, saleId, claimable);
    }

    function _releaseVesting(uint saleId) private {
        uint claimPeriod = currentClaimPeriod(saleId);
        if (claimPeriod > vestingInfo[saleId].lastReleasePeriod) {
            bytes32 vestingScheduleId = tokenVesting.getVestingIdAtIndex(saleId);
            uint releasable = tokenVesting.computeReleasableAmount(vestingScheduleId);
            tokenVesting.release(vestingScheduleId, releasable);
            vestingInfo[saleId].released += releasable;
            vestingInfo[saleId].lastReleasePeriod = claimPeriod;
        }
    }

    function withdrawETH(address payable receiver, uint value) external onlyOwner {
        require(value > 0, "TS01");
        receiver.transfer(value);
    }

    function withdrawTokenById(uint saleId) external onlyOwner onlyExistedSale(saleId) {
        Sale memory sale = sales[saleId];
        require(!checkWithdraw[saleId], "TS07");
        require(sale.saleAmount > sale.soldAmount, "TS08");
        require(block.timestamp > endSaleTime(sale) + (sale.claimDuration * sale.numberOfClaims), "TS09");
        _releaseVesting(saleId);
        IERC20(sale.token).safeTransfer(owner(), sale.saleAmount - sale.soldAmount);
        checkWithdraw[saleId] = true;
    }

    // View function
    function convertDecimal(uint value, uint decimal) private pure returns (uint) {
        return decimal <= 18 ? value / 10 ** (18 - decimal) : value * 10 ** (decimal - 18);
    }

    function chargeFee(uint payingAmount) private view returns (uint) {
        return payingAmount - (payingAmount * fee) / PRECISION_DECIMALS;
    }

    function getEthAmount(uint amount, uint saleId) external view returns (uint) {
        return
            (amount * sales[saleId].price * PRECISION_DECIMALS) /
            (PRICE_DECIMALS * (PRECISION_DECIMALS - fee));
    }

    function getEthTotal(uint amount) external view returns (uint) {
        return (amount * PRECISION_DECIMALS) / (PRECISION_DECIMALS - fee);
    }

    function computeTokenPurchased(
        uint saleId,
        address user,
        BuyerInfo memory _buyerInfo
    ) public view returns (uint) {
        uint totalAmount;
        for (uint i = _buyerInfo.firstPurchasePeriod; i <= _buyerInfo.lastPurchasePeriod; i++) {
            uint depositAmount = depositAmountPeriod[saleId][user][i];
            if (depositAmount > 0) {
                uint periodAmount = (saleAmountPeriod[saleId][i] * depositAmount) /
                    totalDepositPeriod[saleId][i];
                totalAmount += periodAmount;
            } else continue;
        }
        return chargeFee(totalAmount);
    }

    function timePeriod(uint saleId) public view returns (uint) {
        Sale memory sale = sales[saleId];
        return
            sale.startTime > block.timestamp
                ? 0
                : (block.timestamp - sale.startTime) / sale.periodDuration + 1;
    }

    function numSales() public view returns (uint) {
        return sales.length;
    }

    function getSalesList(uint from, uint to) external view returns (Sale[] memory) {
        require(from <= to && to < numSales(), "TS01");
        Sale[] memory listSales = new Sale[](to - from + 1);
        uint countIndex = 0;
        for (uint i = from; i <= to; i++) {
            listSales[countIndex] = sales[i];
            countIndex++;
        }
        return listSales;
    }

    function getUserPurchasePeriod(address user, uint saleId, uint period) external view returns (uint) {
        uint depositAmount = depositAmountPeriod[saleId][user][period];
        return
            depositAmount > 0
                ? (saleAmountPeriod[saleId][period] * depositAmount) / totalDepositPeriod[saleId][period]
                : 0;
    }

    function claimableAmount(uint saleId, address user) external view returns (uint) {
        BuyerInfo memory _buyerInfo = buyerInfo[saleId][user];
        Sale memory sale = sales[saleId];
        Vesting memory vesting = vestingInfo[saleId];

        uint purchaseAmount;
        if (!sale.options.fixedPrice && _buyerInfo.purchaseAmount == 0) {
            purchaseAmount = computeTokenPurchased(saleId, user, _buyerInfo);
        } else {
            purchaseAmount = _buyerInfo.purchaseAmount;
        }

        if (currentClaimPeriod(saleId) > vesting.lastReleasePeriod) {
            uint totalRelease = tokenVesting.computeReleasableAmount(
                tokenVesting.getVestingIdAtIndex(saleId)
            ) + vesting.released;
            return ((totalRelease * purchaseAmount) / sale.saleAmount) - _buyerInfo.claimedAmount;
        } else {
            return ((vesting.released * purchaseAmount) / sale.saleAmount) - _buyerInfo.claimedAmount;
        }
    }

    function currentClaimPeriod(uint saleId) public view returns (uint) {
        Sale memory sale = sales[saleId];
        uint endSale = endSaleTime(sale);
        uint period = endSale > block.timestamp ? 0 : (block.timestamp - endSale) / sale.claimDuration;
        return period > sale.numberOfClaims ? sale.numberOfClaims : period;
    }

    function timeToNextClaim(uint saleId) external view returns (uint) {
        Sale memory sale = sales[saleId];
        uint endSale = endSaleTime(sale);
        uint cliff = vestingInfo[saleId].cliff;

        if (block.timestamp >= endSale + (sale.claimDuration * sale.numberOfClaims)) {
            return 0;
        } else if (block.timestamp < cliff) {
            return cliff > endSale + sale.claimDuration ? cliff : endSale + sale.claimDuration;
        } else {
            return endSale + sale.claimDuration * (currentClaimPeriod(saleId) + 1);
        }
    }

    function endSaleTime(Sale memory sale) public pure returns (uint) {
        return sale.startTime + (sale.periodDuration * sale.numberOfPeriods);
    }

    function isFinish(uint saleId) external view returns (bool) {
        return block.timestamp > endSaleTime(sales[saleId]);
    }

    //Verify functions
    function _validateSale(Sale memory sale) internal view {
        require(sale.soldAmount == 0 && sale.totalPaying == 0, "TS01");
        require(sale.saleAmount > 0, "TS01.1");
        require(sale.price > 0, "TS01.2");
        require(sale.startTime >= block.timestamp, "TS01.3");
        require(sale.periodDuration > 0, "TS01.4");
        require(sale.numberOfPeriods > 0, "TS01.5");
    }

    function _validateEndSale(Sale memory sale) internal view {
        require(block.timestamp > endSaleTime(sale), "TS04");
    }

    function _verifyNFTs(
        address owner,
        uint256[] memory requiredLevels,
        uint256[] calldata nfts
    ) internal view returns (bool) {
        _verifyNFTOwnership(owner, nfts);

        for (uint256 i = 0; i < requiredLevels.length; i++) {
            bool found = false;
            for (uint256 j = 0; j < nfts.length; j++) {
                if (blooprintNft.getLevel(nfts[j]) == requiredLevels[i]) {
                    found = true;
                    break;
                }
            }
            if (!found) {
                return false;
            }
        }
        return true;
    }

    function _verifyNFTOwnership(address owner, uint256[] calldata nfts) internal view {
        for (uint256 i = 0; i < nfts.length; i++) {
            require(blooprintNft.ownerOf(nfts[i]) == owner, "TS01");
        }
    }

    function addFeeStorage(uint256 saleId) external {
        Sale memory sale = sales[saleId];
        _validateEndSale(sale);

        address tokenAddress;
        uint tokenAmount;
        uint256 distributionPeriod;
        if (sale.options.feeInPayingAsset) {
            tokenAddress = sale.options.acceptsETH ? weth : usd;
            tokenAmount = sale.totalPaying / (PRECISION_DECIMALS - (sale.fee / PRECISION_DECIMALS));
            if (sale.options.acceptsETH) {
                require(address(this).balance > tokenAmount, "TS");
                IWETH(tokenAddress).deposit{value: tokenAmount}();
            } else {
                require(IERC20(tokenAddress).balanceOf(address(this)) >= tokenAmount, "TS");
            }
            distributionPeriod = 6;
        } else {
            tokenAddress = sale.token;
            tokenAmount = sale.soldAmount / (PRECISION_DECIMALS - (sale.fee / PRECISION_DECIMALS));
            require(IERC20(tokenAddress).balanceOf(address(this)) >= tokenAmount, "TS");

            distributionPeriod = sale.fee < 200 ? 6 : (sale.fee <= 350 ? 12 : 18);
        }

        if (IERC20(tokenAddress).allowance(address(this), address(feeStorage)) < tokenAmount) {
            IERC20(tokenAddress).safeApprove(address(feeStorage), tokenAmount);
        }
        feeStorage.addNewFeeToken(saleId, tokenAddress, tokenAmount, distributionPeriod);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @dev Interface of the Token Vesting.
 */
interface ITokenVesting {
    function createVestingSchedule(
        address beneficiary,
        uint256 start,
        uint256 cliff,
        uint256 duration,
        uint256 slicePeriodSeconds,
        uint256 amount,
        address token
    ) external;

    function release(bytes32 vestingScheduleId, uint256 amount) external;

    function computeReleasableAmount(bytes32 vestingScheduleId) external view returns (uint256);

    function getVestingIdAtIndex(uint256 index) external view returns (bytes32);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface ITokenSale {
    struct Sale {
        address token;
        uint saleAmount;
        uint soldAmount;
        uint totalPaying;
        uint64 price;
        uint16 fee;
        uint32 startTime;
        uint32 periodDuration;
        uint32 numberOfPeriods;
        uint32 claimDuration;
        uint32 numberOfClaims;
        SaleOption options;
    }

    struct SaleOption {
        bool fixedPrice;
        bool acceptsETH;
        bool feeInPayingAsset;
        bool hasPeriodAccess;
    }

    struct PeriodAccessOption {
        bool isAnyone;
        uint[] nftLevels;
    }

    struct BuyerInfo {
        uint purchaseAmount;
        uint firstPurchasePeriod;
        uint lastPurchasePeriod;
        uint claimedAmount;
    }

    struct Vesting {
        uint released;
        uint lastReleasePeriod;
        uint cliff;
    }

    event SaleToken(uint indexed saleId, Sale sale);
    event BuyToken(uint indexed saleId, uint timePeriod, address indexed buyer, uint value);
    event Claim(address indexed buyer, uint256 indexed saleId, uint amount);
}

// contracts/TokenVesting.sol
// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.17;

interface IWETH {
    function deposit() external payable;

    function withdraw(uint wad) external;

    function totalSupply() external view returns (uint);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address guy, uint wad) external returns (bool);

    function transfer(address dst, uint wad) external returns (bool);

    function transferFrom(
        address src,
        address dst,
        uint wad
    ) external returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface IFeeStorage {
    function addNewFeeToken(
        uint256 _tokenSaleId,
        address _tokenAddress,
        uint256 _tokenAmount,
        uint256 _distributionPeriod
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface IBlooprintNft {
    function ownerOf(uint256 tokenId) external view returns (address);

    function getLevel(uint256 tokenId) external view returns (uint256);

    function getMinLevel() external view returns (uint256);

    function getMaxLevel() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

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
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}