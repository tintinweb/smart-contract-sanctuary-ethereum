// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./lib/SafeMath.sol";
import "./interfaces/IERC20.sol";

interface IOpenStarterNft {
    function mint(address _to) external returns (uint256);

    function setMinter(address _minter) external;
}

interface IOpenStarterLibrary {
    function getStarterDev(address) external view returns (bool);

    function getMinYesVotesThreshold() external view returns (uint256);

    function getTierByTime(uint256, uint256) external view returns (uint256);

    function getAllocationPercentage(uint256) external view returns (uint256);

    function getDevFeePercentage() external view returns (uint256);

    function getWETH() external view returns (address);

    function getStaked(address) external view returns (uint256);

    function getMinVoterBalance() external view returns (uint256);

    function owner() external view returns (address);

    function addSaleAddress(address _sale) external returns (uint256);

    function getStakerTier(address _staker) external view returns (uint256);
}

contract OpenStarterSale {
    using SafeMath for uint256;

    struct ArtistInfo {
        bytes32 name;
        string bio;
        bytes32 twitter;
        bytes32 opensea;
        bytes32 instagram;
        bytes32 discord;
    }

    struct StageInfo {
        uint8 stageType;
        uint256 openTime;
        uint256 closeTime;
        uint256 quantity;
        uint256 sold;
        uint256 pricePerNft;
        uint256 maxPerWallet;
        bool isWhitelistedMode;
        bool isFreeMintingMode;
        bool isLotteryMode;
        bool isPublicMode;
        mapping(address => bool) whitelists;
    }

    address payable internal factoryAddress; // address that creates the sale contracts
    address payable public devAddress; // address where dev fees will be transferred to
    IOpenStarterNft public nftToken; // address where NFT token created
    IOpenStarterLibrary public openStarterLibrary;

    IERC20 public fundingTokenAddress; // funding token like USDC, USDT or ETH(WETH)
    address payable public saleCreatorAddress; // address where percentage of invested wei will be transferred to

    mapping(address => uint256[]) public mintedNfts; // total NFT count for minters
    mapping(uint256 => uint256[5]) public mintedCount; // minted nfts per stage

    uint256 public saleId; // used for fetching sale without referencing its address

    uint256 public totalInvestorsCount; // total investors count
    uint256 public totalCollectedWei; // total wei collected
    uint256 public totalQuantity; // total quantity to be sold
    uint256 public tokensLeft; // available tokens to be sold
    uint256 public openTime; // time when sale starts, investing is allowed
    uint256 public closeTime; // time when presale closes, investing is not allowed
    uint8 public saleType = 0; // 0 : DAO Sale, 1 : Certified Sale

    mapping(address => uint256) public voters; // addresses voting on sale
    uint256 public noVotes; // total number of no votes
    uint256 public yesVotes; // total number of yes votes

    bytes32 public projectName; // project name
    string public artwork; // artwork
    string public kycInformation; // kyc information
    string public description; // description
    string public utility; // utility
    string public projectStage; // stage
    string public copyright; // copyright information
    string public cover; // cover image url

    ArtistInfo public artist; // artist information
    StageInfo[] public stages; // stage list

    constructor(
        address _factoryAddress,
        address _libraryAddress,
        address _devAddress
    ) public {
        openStarterLibrary = IOpenStarterLibrary(_libraryAddress);
        factoryAddress = payable(_factoryAddress);
        devAddress = payable(_devAddress);
    }

    modifier onlyStarterDev() {
        require(
            factoryAddress == msg.sender ||
                devAddress == msg.sender ||
                openStarterLibrary.getStarterDev(msg.sender)
        );
        _;
    }

    modifier onlySaleCreatorOrFactory() {
        require(
            saleCreatorAddress == msg.sender ||
                factoryAddress == msg.sender ||
                devAddress == msg.sender ||
                openStarterLibrary.getStarterDev(msg.sender)
        );
        _;
    }

    function setAddressInfo(
        address _saleCreator,
        address _tokenAddress,
        address _fundingTokenAddress
    ) external onlyStarterDev {
        saleCreatorAddress = payable(_saleCreator);
        nftToken = IOpenStarterNft(_tokenAddress);
        fundingTokenAddress = IERC20(_fundingTokenAddress);
    }

    function setGeneralInfo(
        uint256 _totalQuantity,
        uint256 _openTime,
        uint256 _closeTime,
        uint8 _saleType
    ) external onlyStarterDev {
        totalQuantity = _totalQuantity;
        tokensLeft = _totalQuantity;
        openTime = _openTime;
        closeTime = _closeTime;
        saleType = _saleType;
    }

    function setStringInfo(
        bytes32 _projectName,
        string calldata _artwork,
        string calldata _kycInformation,
        string calldata _description,
        string calldata _projectStage,
        string calldata _cover
    ) external onlySaleCreatorOrFactory {
        projectName = _projectName;
        artwork = _artwork;
        kycInformation = _kycInformation;
        description = _description;
        projectStage = _projectStage;
        cover = _cover;
    }

    function setCopyright(string calldata _copyright, string calldata _utility)
        external
        onlySaleCreatorOrFactory
    {
        utility = _utility;
        copyright = _copyright;
    }

    function setArtistInfo(
        bytes32 _name,
        string calldata _bio,
        bytes32 _twitter,
        bytes32 _opensea,
        bytes32 _instagram,
        bytes32 _discord
    ) external onlySaleCreatorOrFactory {
        artist.name = _name;
        artist.bio = _bio;
        artist.twitter = _twitter;
        artist.opensea = _opensea;
        artist.instagram = _instagram;
        artist.discord = _discord;
    }

    function addStageInfo(
        uint8 _stageType,
        uint256 _openTime,
        uint256 _closeTime,
        uint256 _quantity,
        uint256 _pricePerNft,
        uint256 _maxPerWallet,
        bool _isWhitelistedMode,
        bool _isFreeMintingMode
    ) external onlyStarterDev returns (uint256) {
        StageInfo memory _newInfo;
        _newInfo.stageType = _stageType;
        _newInfo.openTime = _openTime;
        _newInfo.closeTime = _closeTime;
        _newInfo.quantity = _quantity;
        _newInfo.pricePerNft = _pricePerNft;
        _newInfo.maxPerWallet = _maxPerWallet;
        _newInfo.isWhitelistedMode = _isWhitelistedMode;
        _newInfo.isFreeMintingMode = _isFreeMintingMode;
        stages.push(_newInfo);
        return stages.length - 1;
    }

    function addWhitelistedAddresses(
        uint256 _stageIndex,
        address[] calldata _whitelistedAddresses
    ) external onlySaleCreatorOrFactory {
        for (uint256 i = 0; i < _whitelistedAddresses.length; i++) {
            stages[_stageIndex].whitelists[_whitelistedAddresses[i]] = true;
        }
    }

    function removeWhitelistedAddresses(
        uint256 _stageIndex,
        address[] calldata _whitelistedAddresses
    ) external onlySaleCreatorOrFactory {
        for (uint256 i = 0; i < _whitelistedAddresses.length; i++) {
            stages[_stageIndex].whitelists[_whitelistedAddresses[i]] = false;
        }
    }

    function isVotePassed() public returns (bool) {
        return
            yesVotes >=
            noVotes.add(openStarterLibrary.getMinYesVotesThreshold());
    }

    function getCurrentStage() public view returns (uint256) {
        uint256 stageIndex = stages.length;
        for (uint256 i = 0; i < stages.length; i++) {
            if (
                block.timestamp >= stages[i].openTime &&
                block.timestamp <= stages[i].closeTime
            ) {
                stageIndex = i;
            }
        }
        return stageIndex;
    }

    function getStagesCount() public view returns (uint256) {
        return stages.length;
    }

    function getMintedNftsCount(address _sender) public view returns (uint256) {
        return mintedNfts[_sender].length;
    }

    function invest(uint256 _buyCount) public payable {
        require(saleType != 0 || isVotePassed(), "0");
        require(
            block.timestamp >= openTime && block.timestamp < closeTime,
            "1"
        );

        uint256 stageIndex = getCurrentStage();

        require(stageIndex < stages.length, "2");

        StageInfo storage stage = stages[stageIndex];

        uint256 tierIndex = openStarterLibrary.getTierByTime(
            stage.openTime,
            block.timestamp
        );
        uint256 tierPercentage = openStarterLibrary.getAllocationPercentage(
            tierIndex
        );

        if (stage.isWhitelistedMode && !stage.isPublicMode) {
            require(stage.whitelists[msg.sender], "5");
        }

        uint256 userTier = openStarterLibrary.getStakerTier(msg.sender);

        uint256 investAmount = stage.pricePerNft.mul(_buyCount);

        if (!stage.isFreeMintingMode) {
            require(userTier == tierIndex && investAmount > 0, "6");
            if (address(fundingTokenAddress) == openStarterLibrary.getWETH()) {
                require(investAmount == 0 || msg.value >= investAmount, "3");
            }
        }

        if (mintedNfts[msg.sender].length == 0) {
            totalInvestorsCount = totalInvestorsCount.add(1);
        }

        totalCollectedWei = totalCollectedWei.add(investAmount);
        tokensLeft = tokensLeft.sub(_buyCount);

        for (uint256 i = 0; i < _buyCount; i++) {
            uint256 tokenId = nftToken.mint(msg.sender);
            mintedNfts[msg.sender].push(tokenId);
        }

        mintedCount[stageIndex][tierIndex] = mintedCount[stageIndex][tierIndex]
            .add(_buyCount);
        stage.sold = stage.sold.add(_buyCount);
        require(mintedNfts[msg.sender].length <= stage.maxPerWallet, "8");

        if (tierIndex > 0) {
            require(
                mintedCount[stageIndex][tierIndex] <=
                    stage.quantity.mul(tierPercentage).div(100),
                "-"
            );
        } else {
            require(stage.sold <= stage.quantity, "=");
            if (stage.isWhitelistedMode) {
                require(stage.whitelists[msg.sender], "*");
            }
        }

        if (
            address(fundingTokenAddress) != openStarterLibrary.getWETH() &&
            investAmount > 0
        ) {
            require(
                fundingTokenAddress.balanceOf(msg.sender) >= investAmount,
                "b"
            );
            fundingTokenAddress.transferFrom(
                msg.sender,
                address(this),
                investAmount
            );
        }
    }

    receive() external payable {}

    function sendFeesToDevs() internal returns (uint256) {
        uint256 finalTotalCollectedWei = totalCollectedWei;
        uint256 devFeePercentage = openStarterLibrary.getDevFeePercentage();
        uint256 starterDevFeeInWei = finalTotalCollectedWei
            .mul(devFeePercentage)
            .div(100);
        if (starterDevFeeInWei > 0) {
            finalTotalCollectedWei = finalTotalCollectedWei.sub(
                starterDevFeeInWei
            );
            if (address(fundingTokenAddress) == openStarterLibrary.getWETH()) {
                devAddress.transfer(starterDevFeeInWei);
            } else {
                fundingTokenAddress.transfer(devAddress, starterDevFeeInWei);
            }
        }
        return finalTotalCollectedWei;
    }

    function vote(bool yes) external {
        uint256 voterBalance = openStarterLibrary.getStaked(msg.sender);
        uint256 minVoterBalance = openStarterLibrary.getMinVoterBalance();

        require(
            voterBalance >= minVoterBalance &&
                voters[msg.sender] == 0 &&
                saleType == 0
        );
        // public INO only need Vote

        voters[msg.sender] = voterBalance;
        if (yes) {
            yesVotes = yesVotes.add(voterBalance);
        } else {
            noVotes = noVotes.add(voterBalance);
        }
    }

    function collectFundsRaised() external onlySaleCreatorOrFactory {
        require(block.timestamp >= closeTime, "1");
        sendFeesToDevs();

        if (address(fundingTokenAddress) == openStarterLibrary.getWETH()) {
            saleCreatorAddress.transfer(address(this).balance);
        } else {
            fundingTokenAddress.transfer(
                saleCreatorAddress,
                fundingTokenAddress.balanceOf(address(this))
            );
        }
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