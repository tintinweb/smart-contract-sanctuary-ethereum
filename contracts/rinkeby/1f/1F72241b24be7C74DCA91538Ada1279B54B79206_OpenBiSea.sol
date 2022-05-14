// SPDX-License-Identifier: UNLICENSED
// (c) Oleksii Vynogradov 2021, All rights reserved, contact [email protected] if you like to use code
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IOracle.sol";
import "./IOpenBiSeaAuction.sol";

interface IOpenBiSeaInt {
    function bid(
        address contractNFT,
        uint256 tokenId,
        address referral,
        address sender
    ) external payable;
}


contract OpenBiSea is Ownable  {
    using SafeMath for uint256;

    address public auction;
    address public usdContract;
    address public tokenOBS;
    uint256 public rate;
    uint256 public auctionCreationFeeMultiplier = 1;
    uint256 public auctionContractFeeMultiplier;
    uint256 public totalIncome;
    uint256 public tokensaleTotalSold;
    uint256 public platformFeePercent = 5;
    uint256 public referralPercent = 1;
    IOracle _oracleContract;

    mapping(address => address) private _referrals;

    mapping(address => bool) public restrictedTokens;

    uint256 public initialBalance;

    uint256 public initialPrice = 0.0888 ether;
    uint256 public mainCoinToUSD = 472 ether;
    // 88800000000000000 - 0.0888 BNB one token, 607578947368421000 - MATIC one token, 14697931034482762 - METIS,
    // 14145132743363000 - Aurora(ETH), 55956229793583686000 - Cronos(CRO), KAVA - 7668711656441718000 (KAVA). 428689655172413952 - Avalanche(AVAX)

    constructor (
        uint256 _initialBalance,
        address _usdContract,
        address _tokenOBS,
        uint256 _initialPrice,
        uint256 _mainCoinToUSD,
        uint256 _networkId
    ) {
        tokenOBS = _tokenOBS;
        initialBalance = _initialBalance;
        usdContract = _usdContract;
        initialPrice = _initialPrice;
        mainCoinToUSD = _mainCoinToUSD;

        if (_networkId == 56) {
            tokensaleTotalSold = 429.2125438496257 ether;
        }
        if (_networkId == 97) {
            tokensaleTotalSold = 429.2125438496257 ether;
        }
    }

    function setOracleContract(IOracle _oracle) public onlyOwner {
        _oracleContract = _oracle;
    }

    function getReferral(address buyer) public view returns (address) {
        return _referrals[buyer];
    }

    function getMainCoinToUSD() public view returns (uint256) {
        return mainCoinToUSD;
    }

    function getTokenOBS() public view returns (address) {
        return tokenOBS;
    }

    function getInitialBalance() public view returns (uint256) {
        return initialBalance;
    }

    function getTokensaleTotalSold() public view returns (uint256) {
        return tokensaleTotalSold;
    }

    function getOracleContract() public view returns (IOracle) {
        return _oracleContract;
    }

    function _setRestrictedToken(address token, bool isRestricted) public onlyOwner {
        restrictedTokens[token] = isRestricted;
    }

    function _setReferral(address buyer, address referral) public onlyOwner {
        _referrals[buyer] = referral;
    }

    function _setPremiumFee(uint256 _premiumFee) public onlyOwner {
        platformFeePercent = _premiumFee;
    }

    function _setReferralPercent(uint256 _referralPercent) public onlyOwner {
        referralPercent = _referralPercent;
    }

    function _withdrawSuperAdmin(address payable sender,address token, uint256 amount) public onlyOwner returns (bool) {
        if (amount > 0) {
            if (token == address(0)) {
                Address.sendValue(sender, amount);
                return true;
            } else {
                IERC20(token).transfer(sender, amount);
                return true;
            }
        }
        return false;
    }

    function _setRate(uint256 _rate) public onlyOwner {
        rate = _rate;
    }

    function _setAuction(address _auction) public onlyOwner {
        auction = _auction;
    }

    function getInitialPriceInt() public view returns (uint256)  {
        return initialPrice;
    }

    function setInitialPriceInt(uint256 _initialPriceInt) public onlyOwner {
        initialPrice = _initialPriceInt;
    }

    function setUsdContract(address _usdContract) public onlyOwner {
        usdContract = _usdContract;
    }

    function getUsdContract() public view returns (address)  {
        return usdContract;
    }

    function purchaseTokensQuantityFor(uint256 amount) public view returns (uint256,uint256) {
        uint256 delta = initialBalance.sub(tokensaleTotalSold);
        uint256 newPrice = initialPrice.mul(initialBalance).div(delta);
        return (amount.mul(10 ** uint256(18)).div(newPrice),initialBalance.sub(tokensaleTotalSold));
    }

    function purchaseTokens(address referral) public payable returns (uint256) {
        require(msg.value > initialPrice.mul(2), "OpenBiSea: minimal purchase must be more then two times initial price");
        uint256 amountTokens;
        uint256 balance;
        (amountTokens,balance) = purchaseTokensQuantityFor(msg.value);
        require(amountTokens > 0, "OpenBiSea: we can't sell 0 tokens.");
        require(amountTokens < balance.div(3), "OpenBiSea: we can't sell more than 33.3% from one transaction. Please decrease investment amount.");
        if (referral != address (0x0) || _referrals[msg.sender] != address (0x0)) {
            if (_referrals[msg.sender] == address (0x0)) {
                require(!Address.isContract(referral),"OpenBiSea: Invalid address");
                _referrals[msg.sender] = referral;
            } else referral = _referrals[msg.sender];

            uint256 referralFee = msg.value.mul(referralPercent).div(100);
            Address.sendValue(payable(referral), referralFee);
            Address.sendValue(payable(owner()), msg.value.sub(referralFee));
        } else {
            Address.sendValue(payable(owner()), msg.value);
        }

        IERC20(tokenOBS).transfer(msg.sender, amountTokens);
        tokensaleTotalSold = tokensaleTotalSold.add(amountTokens);

        return amountTokens;
    }

    function contractsNFTWhitelisted() public view returns (address[] memory) {
        return IOpenBiSeaAuction(auction).contractsNFTWhitelisted();
    }

    function whitelistContractCreator(address _contractNFT) public payable {
        require(msg.value >= initialPrice.mul(auctionCreationFeeMultiplier), "OpenBiSea: you must send minimal amount or more");
        Address.sendValue(payable(owner()), msg.value);
        IOpenBiSeaAuction(auction).whitelistContractCreator(_contractNFT);
        totalIncome = totalIncome.add(msg.value);
    }

    function whitelistContractCreatorTokens(address _contractNFT) public {
        uint256 amount = (10 ** uint256(18)).mul(auctionCreationFeeMultiplier);
        IERC20(tokenOBS).transferFrom(msg.sender,address(this),amount);
        totalIncome = totalIncome.add(initialPrice.mul(amount).div(10 ** uint256(18)));
        IOpenBiSeaAuction(auction).whitelistContractCreator(_contractNFT);
    }


    function createAuction(
        address _contractNFT,
        uint256 _tokenId,
        uint256 _price,
        uint256 _deadline,
        bool _isERC1155,
        address token,
        address sender
    ) public {
        require(restrictedTokens[token] != true, "OpenBiSea: token is restricted for auctions");
        address finalSender = msg.sender;
        if (msg.sender == address(this)) finalSender = sender;
        IOpenBiSeaAuction(auction).createAuction(_contractNFT,_tokenId, _price, _deadline,_isERC1155, finalSender, token);
    }

    function createAuctionBatch(
        address[] memory contractsNFT,
        uint256[] memory tokenIds,
        uint256[] memory prices,
        uint256[] memory deadlines,
        bool [] memory isERC1155s,
        address[] memory tokens) public{
        for (uint i=0; i< contractsNFT.length; i++) {
            createAuction(contractsNFT[i],tokenIds[i],prices[i],deadlines[i],isERC1155s[i],tokens[i], msg.sender);
        }
    }

    struct AuctionResult {
        bool isWin;
        uint256 amountTransferBack;
        address auctionLatestBidder;
        address tokenSaved;
    }

    function _updateTotalIncomeFor(uint256 bidAmount, address token) private {
        uint256 priceMainToUSD = mainCoinToUSD;
        uint8 decimals = 18;
        uint256 valueFinal;
        if (_oracleContract.getIsOracle()) (priceMainToUSD,decimals) = _oracleContract.getLatestPrice();
        if (token == usdContract) {
            valueFinal = bidAmount.mul(10 ** 18).div(priceMainToUSD);
        } else if (IOpenBiSeaAuction(auction).getTokenPriceToMainCoin(token) > 0) {
            valueFinal = bidAmount.mul(10 ** 18).div(IOpenBiSeaAuction(auction).getTokenPriceToMainCoin(token)).mul(10 ** 18).div(priceMainToUSD);
        }
        totalIncome = totalIncome.add(valueFinal);
    }

    function winToken(
        uint256 bidAmount,
        address finalSender,
        address referral,
        uint256 amountTransferBack,
        address auctionLatestBidder,
        address token,
        address seller
    ) private {
        uint256 depositFee = bidAmount.mul(platformFeePercent).div(100);
        uint256 depositFeeReferrer = bidAmount.mul(referralPercent).div(100);
        uint256 totalSellerAmount = bidAmount.sub(depositFee);
        if (_referrals[finalSender] != address(0) || referral != address(0)) {
            if (_referrals[finalSender] == address(0)) {
                require(!Address.isContract(referral),"OpenBiSea: Invalid address");
                _referrals[finalSender] = referral;
            } else referral = _referrals[finalSender];
            totalSellerAmount = totalSellerAmount.sub(depositFeeReferrer);
            IERC20(token).transfer(referral,depositFeeReferrer);
        }
        IERC20(token).transfer(owner(),depositFee);
        IERC20(token).transfer(seller,totalSellerAmount);
        if (auctionLatestBidder != address (0x0)) IERC20(token).transfer(auctionLatestBidder,amountTransferBack);
        _updateTotalIncomeFor(bidAmount, token);
    }

    function bidToken(
        address contractNFT,
        uint256 tokenId,
        uint256 bidAmount,
        address referral,
        address token,
        address sender
    ) public {
        require(restrictedTokens[token] != true, "OpenBiSea: token is restricted for auctions");
        address finalSender = msg.sender;
        if (msg.sender == address(this)) finalSender = sender;

        IERC20(token).transferFrom(finalSender,address(this), bidAmount);
        bool isWin;
        uint256 amountTransferBack;
        address auctionLatestBidder;
        address tokenSaved;
        address seller;

        (isWin, amountTransferBack, auctionLatestBidder, tokenSaved, seller) = IOpenBiSeaAuction(auction).bid(contractNFT, tokenId, bidAmount, finalSender, token);
        require(token == tokenSaved, "OpenBiSea: auction use another token");

        if (isWin) {
            winToken(bidAmount, finalSender, referral, amountTransferBack, auctionLatestBidder, token, seller);
        } else {
            if (amountTransferBack > 0) {
                IERC20(token).transfer(auctionLatestBidder,amountTransferBack);
            }
        }
    }

    function bidTokenBatch(
        address[] memory contractsNFT,
        uint256[] memory tokenIds,
        uint256[] memory bidAmounts,
        address[] memory referrals,
        address[] memory tokens) public{
        for (uint i=0; i< contractsNFT.length; i++) {
            bidToken(contractsNFT[i], tokenIds[i], bidAmounts[i], referrals[i], tokens[i], msg.sender);
        }
    }

    function win(
        uint256 value,
        address finalSender,
        address referral,
        uint256 amountTransferBack,
        address auctionLatestBidder,
        address seller
    ) private {
        uint256 depositFee = value.mul(platformFeePercent).div(100);
        uint256 depositFeeReferrer = value.mul(referralPercent).div(100);
        uint256 totalSellerAmount = value.sub(depositFee);

        if (_referrals[finalSender] != address(0) || referral != address(0)) {
            if (_referrals[finalSender] == address(0)) {
                require(!Address.isContract(referral),"OpenBiSea: Invalid address");
                _referrals[finalSender] = referral;
            } else referral = _referrals[finalSender];
            totalSellerAmount = totalSellerAmount.sub(depositFeeReferrer);
            Address.sendValue(payable(referral), depositFeeReferrer);
            Address.sendValue(payable(owner()), depositFee);
        } else Address.sendValue(payable(owner()), depositFee);

        Address.sendValue(payable(seller), totalSellerAmount);
        if (amountTransferBack > 0 && auctionLatestBidder != address (0x0)) Address.sendValue(payable(auctionLatestBidder), amountTransferBack);
        totalIncome = totalIncome.add(value);
    }

    function bid(
        address contractNFT,
        uint256 tokenId,
        address referral,
        address sender
    ) public payable {
        address finalSender = msg.sender;
        if (msg.sender == address(this)) finalSender = sender;
        bool isWin;
        uint256 amountTransferBack;
        address auctionLatestBidder;
        address token;
        address seller;
        (isWin, amountTransferBack, auctionLatestBidder, token, seller) = IOpenBiSeaAuction(auction).bid(contractNFT, tokenId, msg.value, finalSender, address (0x0) );
        require(token == address (0x0), "OpenBiSea: auction must use main coin");

        if (isWin) {
            win(msg.value, finalSender, referral, amountTransferBack, auctionLatestBidder, seller);
        } else {
            if (amountTransferBack > 0) {
                Address.sendValue(payable(auctionLatestBidder), amountTransferBack);
            }
        }
    }

    function bidBatch(
        address[] memory contractsNFT,
        uint256[] memory tokenIds,
        uint256[] memory bidAmounts,
        address[] memory referrals
    ) public payable {
        for (uint i=0; i< contractsNFT.length; i++) {
            IOpenBiSeaInt(address(this)).bid{value:bidAmounts[i]}(contractsNFT[i], tokenIds[i], referrals[i], msg.sender);
        }
    }

    function finalizeAuction(address _contractNFT, uint256 _tokenId, address referral, address sender) public {
        bool isWin;
        uint256 amountTransferBack;
        address auctionLatestBidder;
        address seller;
        address token;
        (isWin, amountTransferBack, auctionLatestBidder, token , seller) = IOpenBiSeaAuction(auction).finalize(_contractNFT, _tokenId);
        if (isWin) {
            if (token == address (0x0)) win(amountTransferBack, auctionLatestBidder, referral, 0, auctionLatestBidder, seller);
            else winToken(amountTransferBack, auctionLatestBidder, referral, 0, auctionLatestBidder, token, seller);
        }
    }

    function cancelAuction(address _contractNFT, uint256 _tokenId, address sender) public {
        address finalSender = msg.sender;
        if (msg.sender == address(this)) finalSender = sender;

        address latestBidder;
        uint256 price;
        address token;
        (latestBidder, price, token) = IOpenBiSeaAuction(auction).cancelAuction(_contractNFT, _tokenId, finalSender);
        if (latestBidder != address (0)) {
            if (token == address(0)) {
                Address.sendValue(payable(latestBidder), price);
            } else {
                IERC20(token).transfer(latestBidder,price);
            }
        }
    }

    function cancelAuctionBatch(
        address[] memory contractsNFT,
        uint256[] memory tokenIds
    ) public {
        for (uint i=0; i< contractsNFT.length; i++) {
            cancelAuction(contractsNFT[i], tokenIds[i], msg.sender);
        }
    }

    event ClaimFreeTokens(uint256 amount, address investor);//, uint256 amountTotalUSDwei, uint256 incomeInOBSfromUser, uint256 percentOfSales, uint256 newPriceOBS, uint256 priceMainToUSD);
    /* if total sales > $10k and < $500k, (5% from revenue in OBS )  if total sales >  $500k and total sales < $5M (3% from revenue in OBS) if total sales >  $5M, ( 0.1% from revenue in OBS) */
    mapping(address => uint256) private _consumersReceivedMainTokenLatestDate;

    function claimFreeTokens() public {
        //Example, 10BNB(TI) ether * 427 ether / 1 ether leaved 4270 ether (in usd) which is true to compare!
        uint256 totalIncomeUSD = totalIncome * mainCoinToUSD / 1 ether;

        require(totalIncomeUSD >= 100 ether, "OpenBiSea: distribution starts from 100 USD total income");
        uint256 percentWithDecimalsToDistribute = 500; // max 500 (5%)
        if (totalIncomeUSD > 10000 ether && totalIncomeUSD < 500000 ether)  percentWithDecimalsToDistribute = 300;
        if (totalIncomeUSD > 500000 ether && totalIncomeUSD < 5000000 ether)  percentWithDecimalsToDistribute = 100;
        if (totalIncomeUSD > 5000000 ether) percentWithDecimalsToDistribute = 10;

        uint256 delta = initialBalance.sub(tokensaleTotalSold);
        uint256 newPriceOBS = initialPrice.mul(initialBalance).div(delta);
        uint256 tokensToPay = IOpenBiSeaAuction(auction).revenueFor(msg.sender).mul(10 ** 18).mul(percentWithDecimalsToDistribute).div(newPriceOBS).div(10000); // can't reward more than percentToDistribute% of customer income
        require(tokensToPay > 0, "OpenBiSea: nothing to claim");
        require(_consumersReceivedMainTokenLatestDate[msg.sender] < block.timestamp.sub(4 weeks), "OpenBiSea: only once per months you can claim");
        IERC20(tokenOBS).transfer(msg.sender, tokensToPay);
        _consumersReceivedMainTokenLatestDate[msg.sender] = block.timestamp;
        IOpenBiSeaAuction(auction).zeroingRevenueFor(msg.sender);
        emit ClaimFreeTokens(tokensToPay, msg.sender);
    }

}

// SPDX-License-Identifier: UNLICENSED
// (c) Oleksii Vynogradov 2021, All rights reserved, contact [email protected] if you like to use code
pragma solidity ^0.8.0;
interface IOracle {
    function getLatestPrice() external view returns (uint256, uint8);
    function getIsOracle() external view returns (bool);
    function getCustomPrice(address aggregator) external view returns (uint256, uint8);
}

// SPDX-License-Identifier: UNLICENSED
// (c) Oleksii Vynogradov 2021, All rights reserved, contact [email protected] if you like to use code
pragma solidity ^0.8.0;
interface IOpenBiSeaAuction {
    function contractsNFTWhitelisted() external view returns (address[] memory);
    function getTokenPriceToMainCoin(address token) external view returns (uint256);
    function whitelistContractCreator(address _contractNFT) external payable;
    function createAuction(
        address _contractNFT,
        uint256 _tokenId,
        uint256 _price,
        uint256 _deadline,
        bool _isERC1155,
        address _sender,
        address token
    ) external;

    function bid(
        address _contractNFT,
        uint256 _tokenId,
        uint256 _price,
        address _sender,
        address token
    ) external returns (bool, uint256, address, address, address);

    function finalize(
        address contractNFT,
        uint256 tokenId
    ) external returns (bool, uint256, address, address, address);

    function cancelAuction(address _contractNFT, uint256 _tokenId, address _sender) external returns (address, uint256, address);
    function revenueFor(address consumer) external view returns (uint256);
    function zeroingRevenueFor(address consumer) external;

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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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