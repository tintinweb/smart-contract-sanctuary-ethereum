// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./lib/SafeMath.sol";
import "./interfaces/IERC20.sol";

interface IOpenStarterNft {
    function mint(address _to) external returns (uint256);

    function setMinter(address _minter) external;
}

interface IOpenStarterStaking {
    function getUserInfo(address _staker)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );
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
}

contract OpenStarterSale {
    using SafeMath for uint256;

    struct ArtistInfo {
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
    IOpenStarterStaking public openStarterStakingPool;
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
        string calldata _utility,
        string calldata _projectStage,
        string calldata _copyright
    ) external onlySaleCreatorOrFactory {
        projectName = _projectName;
        artwork = _artwork;
        kycInformation = _kycInformation;
        description = _description;
        utility = _utility;
        projectStage = _projectStage;
        copyright = _copyright;
    }

    function setArtistInfo(
        string calldata _bio,
        bytes32 _twitter,
        bytes32 _opensea,
        bytes32 _instagram,
        bytes32 _discord
    ) external onlySaleCreatorOrFactory {
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

        uint256 userTier = 0;
        (userTier, , ) = openStarterStakingPool.getUserInfo(msg.sender);

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

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./lib/SafeMath.sol";
import "./lib/ERC20.sol";
import "./OpenStarterSale.sol";

contract OpenStarterSaleFactory {
    using SafeMath for uint256;

    IOpenStarterLibrary public openStarterLibrary;

    event SaleCreated(uint256 saleId, address _nft, address _creator);

    constructor(address _openStarterLibrary) public {
        openStarterLibrary = IOpenStarterLibrary(_openStarterLibrary);
    }

    function setLibraryAddress(address _newLibrary) public {
        require(openStarterLibrary.getStarterDev(msg.sender), "1");
        openStarterLibrary = IOpenStarterLibrary(_newLibrary);
    }

    struct NftInfo {
        string name;
        string symbol;
        uint256 maxQuantityMinted;
        string logo;
        string collection;
        string description;
        string utility;
        bytes32 website;
        bytes32 discord;
        bytes32 twitter;
        bytes32 medium;
        bytes32 telegram;
        string logoUrl;
        string unlockable;
        string baseUrl;
        bool isExplicit;
        bool isErc721; // true: ERC721 false: ERC1155
    }

    struct Attributes {
        string sName;
        uint256 uMin;
        uint256 uMax;
        uint256 uType;
    }

    struct SaleInfo {
        uint256 totalQuantity;
        uint256 openTime;
        uint256 closeTime;
        bytes32 projectName;
        string artwork;
        string kycInformation;
        string description;
        string utility;
        string projectStage;
        string copyright;
    }

    struct ArtistInfo {
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
        uint256 pricePerNft;
        uint256 maxPerWallet;
        bool isWhitelistedMode;
        bool isFreeMintingMode;
    }

    function createSale(
        address _nft, // ERC721 NFT Address
        address _owner, // Sale Owner Address for Collecting Funds
        address _fundingTokenAddress, // Funding Token Address
        uint8 _saleType, // 0: DAO Sale, 1: Certified
        SaleInfo calldata _saleInfo, // Sale Main Info
        ArtistInfo calldata _artistInfo, // Artist Info
        StageInfo[] calldata _stages // Stages Array
    ) external {
        if (_saleType == 1) {
            require(openStarterLibrary.getStarterDev(msg.sender), "1");
        }
        OpenStarterSale sale = new OpenStarterSale(
            address(this),
            address(openStarterLibrary),
            openStarterLibrary.owner()
        );
        sale.setAddressInfo(_owner, _nft, _fundingTokenAddress);
        sale.setGeneralInfo(
            _saleInfo.totalQuantity,
            _saleInfo.openTime,
            _saleInfo.closeTime,
            _saleType
        );
        sale.setArtistInfo(
            _artistInfo.bio,
            _artistInfo.twitter,
            _artistInfo.opensea,
            _artistInfo.instagram,
            _artistInfo.discord
        );
        for (uint256 i = 0; i < _stages.length; i++) {
            sale.addStageInfo(
                _stages[i].stageType,
                _stages[i].openTime,
                _stages[i].closeTime,
                _stages[i].quantity,
                _stages[i].pricePerNft,
                _stages[i].maxPerWallet,
                _stages[i].isWhitelistedMode,
                _stages[i].isFreeMintingMode
            );
        }
        uint256 saleId = openStarterLibrary.addSaleAddress(address(sale));

        try IOpenStarterNft(_nft).setMinter(address(sale)) {} catch Error(
            string memory reason
        ) {} catch (bytes memory reason) {}
        emit SaleCreated(saleId, _nft, msg.sender);
    }

    function setMinter(address _nft, address _sale) public {
        require(openStarterLibrary.getStarterDev(msg.sender), "1");
        IOpenStarterNft(_nft).setMinter(_sale);
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