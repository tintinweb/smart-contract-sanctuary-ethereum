// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import './interfaces/ICallFactory.sol';
import './interfaces/pool/ICallPoolImmutables.sol';
import './CallPoolDeployer.sol';
import './NoDelegateCall.sol';
import './CallPool.sol';


contract CallFactory is ICallFactory, CallPoolDeployer, NoDelegateCall, Ownable {

    mapping(address => address) public override getPool;

    constructor(address nTokenFactory, address callTokenFactory) Ownable() CallPoolDeployer(nTokenFactory, callTokenFactory) {
    }

    function createPool(
        address erc721token,
        address oracle,
        address premium
    ) external override noDelegateCall onlyOwner returns (address pool) {
        require(erc721token != address(0));
        require(oracle != address(0));
        require(premium != address(0));
        require(getPool[erc721token] == address(0));
        pool = deploy(address(this), erc721token, oracle, premium);
        // populate mapping in the reverse direction, deliberate choice to avoid the cost of comparing addresses
        getPool[erc721token] = pool;
        ICallPoolImmutables poolImmutables = ICallPoolImmutables(pool);
        emit PoolCreated(erc721token, oracle, pool, premium, poolImmutables.nToken(), poolImmutables.callToken());
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.9;

interface ICallFactory {
    event PoolCreated(
        address indexed erc721token,
        address oracle,
        address pool,
        address premium,
        address ntoken,
        address calltoken);
    
    function getPool(address erc721token) external view returns (address pool);
    function createPool(address erc721token, address oracle, address premium) external returns (address pool);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title Pool state that never changes
/// @notice These parameters are fixed for a pool forever, i.e., the methods will always return the same values
interface ICallPoolImmutables {
    /// @notice The contract that deployed the pool, which must adhere to the IUniswapV3Factory interface
    /// @return The contract address
    function factory() external view returns (address);

    function nft() external view returns (address);

    function nToken() external view returns (address);

    function callToken() external view returns (address);

    function oracle() external view returns (address);

    function premium() external view returns (address);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.9;
pragma abicoder v2;

import './interfaces/ICallPoolDeployer.sol';
import './CallPool.sol';
import './NToken.sol';
import './CallToken.sol';

abstract contract CallPoolDeployer is ICallPoolDeployer {
        struct Parameters {
        address factory;
        address erc721token;
        address ntoken;
        address calltoken;
        address oracle;
        address premium;
    }

    Parameters public override parameters;

    address immutable nTokenFactory;
    address immutable callTokenFactory;

    constructor (address _nTokenFactory, address _callTokenFactory) {
        nTokenFactory = _nTokenFactory;
        callTokenFactory = _callTokenFactory;
    }

    function deploy(address factory, address erc721token, address oracle, address premium) internal returns (address pool) {
        parameters.factory = factory;
        parameters.erc721token = erc721token;
        parameters.oracle = oracle;
        parameters.premium = premium;
        (bool success1, bytes memory result1) = nTokenFactory.delegatecall(
            abi.encodeWithSignature('deployNToken(bytes32)', keccak256(abi.encode('ntoken', erc721token)))
        );
        require(success1);
        (address ntoken) = abi.decode(result1, (address));
        parameters.ntoken = ntoken;
        (bool success2, bytes memory result2) = callTokenFactory.delegatecall(
            abi.encodeWithSignature('deployCallToken(bytes32)', keccak256(abi.encode('calltoken', erc721token)))
        );
        require(success2);
        (address calltoken) = abi.decode(result2, (address));
        parameters.calltoken = calltoken;
        pool = address(new CallPool{salt: keccak256(abi.encode('callpool', erc721token, ntoken, calltoken, oracle, premium))}());
        NToken(ntoken).transferOwnership(pool);
        CallToken(calltoken).transferOwnership(pool);

        delete parameters;
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

abstract contract NoDelegateCall {
    address private immutable selfAddress;

    constructor() {
        selfAddress = address(this);
    }

    modifier noDelegateCall() {
        require(address(this) == selfAddress);
        _;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.9;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {ICallPoolDeployer} from "./interfaces/ICallPoolDeployer.sol";
import {ICallPool} from "./interfaces/ICallPool.sol";
import {IPriceOracle} from "./interfaces/IPriceOracle.sol";
import {IPremium} from "./interfaces/IPremium.sol";
import {ICallToken} from "./interfaces/ICallToken.sol";
import {CallToken} from "./CallToken.sol";
import {NToken} from "./NToken.sol";
import {Errors, ErrorCodes} from "./Errors.sol";
import {DataTypes, MAXIMUM_VALID_DURATION_IDX, MAXIMUM_VALID_STRIKE_PRICE_GAP_IDX, STRIKE_PRICE_DECIMALS, MAXIMUM_STRIKE_PRICE} from "./DataTypes.sol";
import {NFTStatus} from "./NFTStatus.sol";

contract CallPool is ICallPool, Pausable, ReentrancyGuard {
    using NFTStatus for DataTypes.NFTStatusMap; 
    address public immutable override factory;
    address public immutable override nft;
    address public immutable override oracle;
    address public immutable override nToken;
    address public immutable override callToken;
    address public immutable override premium;

    uint16 public constant  exercisePeriodProportion = 5000;  // 5000 means the buyers can exercise at any time in the late 50% of option period
    uint256 public constant minimumPremiumToOwner = 1e18 / 1000;      // 0.001 ether
    uint256 public constant INVALID_PRICE = type(uint256).max;
    uint256 public constant DECIMALS = 18;

    // Assume that the price decimals is greater than the strike price decimals.
    // When the price decimals is less than the strike price decimals, 
    // please use: (DataTypes.STRIKE_PRICE_MAX / (10 ** (DataTypes.STRIKE_PRICE_DECIMALS - DECIMALS)));
    uint256 internal constant STRIKE_PRICE_SCALE = 10 ** (DECIMALS - STRIKE_PRICE_DECIMALS);
    uint256 public constant MAXIMUM_STRIKE_PRICE_IN_CONTRACT_DECIMALS = uint256(type(uint64).max) * STRIKE_PRICE_SCALE;

    uint256 private constant PRECISION = 1e5;
    uint256 private constant RESERVE = 1e4; // 10%

    function STRIKE_PRICE_GAP(uint8 strikePriceGapIdx) public pure returns(uint256) {
        uint24[MAXIMUM_VALID_STRIKE_PRICE_GAP_IDX + 1] memory strikePriceGaps = [0, 1e4, 2*1e4, 3*1e4, 5*1e4, 1e5]; // [0% 10% 20% 30% 50% 100%]
        return uint256(strikePriceGaps[strikePriceGapIdx]);
    }

    function DURATION(uint8 durationIdx) public pure returns(uint40) {
        uint40[MAXIMUM_VALID_DURATION_IDX + 1] memory durations = [uint40(3 days), uint40(7 days), uint40(14 days), uint40(28 days)];
        return uint40(durations[durationIdx]);
    }

    function convertToStrikePrice(uint256 price) private pure returns(uint64) {
        return uint64(price / STRIKE_PRICE_SCALE);
    }

    function convertFromStrikePrice(uint64 strikePrice) private pure returns(uint256) {
        return uint256(strikePrice) * STRIKE_PRICE_SCALE;
    }
    
    bool internal _deactivated;


    mapping(uint256 => DataTypes.NFTStatusMap) private nftStatus;


    mapping(address => uint256) private _balanceOf;

    constructor() {
        (factory, nft, nToken, callToken, oracle, premium) = ICallPoolDeployer(_msgSender()).parameters();
    }

    modifier onlyFactoryOwner() {
        require(_msgSender() == Ownable(factory).owner(), Errors.CP_CALLER_IS_NOT_FACTORY_OWNER);
        _;
    }

    modifier whenActivated() {
        require(!_deactivated, Errors.CP_DEACTIVATED);
        _;
    }

    function pause() external onlyFactoryOwner {
        _pause();
    }

    function unpause() external onlyFactoryOwner {
        _unpause();
    }

    function activate() external onlyFactoryOwner {
        require(_deactivated, Errors.CP_ACTIVATED);
        _deactivated = false;
        emit Activate(_msgSender());
    }

    function deactivate() external onlyFactoryOwner {
        require(!_deactivated, Errors.CP_DEACTIVATED);
        _deactivated = true;
        emit Deactivate(_msgSender());
    }

    function balanceOf(address user) public view override returns (uint256) {
        return _balanceOf[user];
    }

    function checkAvailable(uint256 tokenId) public view returns (bool) {
        if(nftStatus[tokenId].data == 0){
            return false;
        }
        uint256 endTime = uint256(nftStatus[tokenId].getEndTime());
        if (endTime < block.timestamp) {
            return true;
        } else {
            return false;
        }
    }

    // Deposit NFT
    function deposit(address onBehalfOf, uint256 tokenId) external override whenNotPaused whenActivated nonReentrant {
        uint256 errorCode = _deposit(onBehalfOf, tokenId, 1, 3, 0);
        require(errorCode == 0, Strings.toString(errorCode));
    }

    function depositBatch(address onBehalfOf, uint256[] calldata tokenIds) external override  whenNotPaused whenActivated nonReentrant returns(uint256[] memory) {
        require(tokenIds.length != 0, Errors.CP_ZERO_SIZED_ARRAY);
        uint256[] memory errorCodes = new uint256[](tokenIds.length);
        for(uint256 i = 0; i < tokenIds.length; ++i) {
            errorCodes[i] = _deposit(onBehalfOf, tokenIds[i], 1, 3, 0);
        }
        return errorCodes;
    }

    function depositWithPreference(
        address onBehalfOf,
        uint256 tokenId,
        uint8 lowerStrikePriceGapIdx,
        uint8 upperDurationIdx,
        uint256 minimumStrikePrice
    ) external override whenNotPaused whenActivated nonReentrant{
        uint256 errorCode = _deposit(onBehalfOf, tokenId, lowerStrikePriceGapIdx, upperDurationIdx, minimumStrikePrice);
        require(errorCode == 0, Strings.toString(errorCode));
    }

    function depositWithPreferenceBatch(
        address onBehalfOf,
        uint256[] calldata tokenIds,
        uint8[] calldata lowerStrikePriceGapIdxList,
        uint8[] calldata upperDurationIdxList,
        uint256[] calldata minimumStrikePriceList
    ) external override whenNotPaused whenActivated nonReentrant returns(uint256[] memory){
        require(tokenIds.length != 0, Errors.CP_ZERO_SIZED_ARRAY);
        require(tokenIds.length == lowerStrikePriceGapIdxList.length 
                && tokenIds.length == upperDurationIdxList.length 
                && tokenIds.length == minimumStrikePriceList.length
                , Errors.CP_ARRAY_LENGTH_UNMATCHED);
        uint256[] memory errorCodes = new uint256[](tokenIds.length);
        for(uint256 i=0; i < tokenIds.length; ++i){
            errorCodes[i] = _deposit(onBehalfOf, tokenIds[i], lowerStrikePriceGapIdxList[i], upperDurationIdxList[i], minimumStrikePriceList[i]);
        }
        return errorCodes;
    }

    function _deposit(
        address onBehalfOf,
        uint256 tokenId,
        uint8 minimumStrikePriceGapIdx,
        uint8 maximumDurationIdx,
        uint256 minimumStrikePrice
    ) internal returns(uint256){
        if(minimumStrikePrice > MAXIMUM_STRIKE_PRICE_IN_CONTRACT_DECIMALS){
            return ErrorCodes.CP_PRICE_TOO_HIGH;
        }
        DataTypes.NFTStatusMap memory status = DataTypes.NFTStatusMap(DataTypes.NFT_STATUS_MAP_INIT_VALUE);
        status.setIfOnMarket(true);
        status.setMinimumStrikePriceGapIdx(minimumStrikePriceGapIdx);
        status.setMaximumDurationIdx(maximumDurationIdx);
        status.setMinimumStrikePrice(convertToStrikePrice(minimumStrikePrice));
        nftStatus[tokenId].data = status.data;

        CallToken(callToken).mint(nToken, tokenId);
        emit Deposit(nft, _msgSender(), onBehalfOf, tokenId);
        emit PreferenceUpdated(nft, tokenId, minimumStrikePriceGapIdx, maximumDurationIdx, minimumStrikePrice);
        NToken(nToken).mint(onBehalfOf, tokenId);
        IERC721(nft).transferFrom(_msgSender(), nToken, tokenId);

        
        return 0;
    }

    // Withdraw NFT
    function withdraw(address to, uint256 tokenId) external override whenNotPaused nonReentrant{
        uint256 errorCode = _withdraw(_msgSender(), to, tokenId, block.timestamp);
        require(errorCode == 0, Strings.toString(errorCode));
    }

    // Withdraw NFT
    function withdrawBatch(address to, uint256[] calldata tokenIds) external override whenNotPaused nonReentrant returns(uint256[] memory){
        require(tokenIds.length != 0, Errors.CP_ZERO_SIZED_ARRAY);
        uint256[] memory errorCodes = new uint256[](tokenIds.length);
        address user = _msgSender();
        uint256 currentTime = block.timestamp;
        for(uint256 i = 0; i < tokenIds.length; ++i){
            errorCodes[i] = _withdraw(user, to, tokenIds[i], currentTime);
        }
        return errorCodes;
    }

    // Withdraw NFT
    function _withdraw(address user, address to, uint256 tokenId, uint256 currentTime) internal returns(uint256) {
        
        if(NToken(nToken).ownerOf(tokenId) != user){
            return ErrorCodes.CP_NOT_THE_OWNER;
        }
        // Check requirements: not commited to a call, etc.
        if(uint256(nftStatus[tokenId].getEndTime()) >= currentTime){
            return ErrorCodes.CP_NFT_ON_MARKET_OR_UNAVAILABLE;
        }
        delete nftStatus[tokenId];
        CallToken(callToken).burn(tokenId);

        emit Withdraw(nft, user, to, tokenId);
        // Burn NToken
        NToken(nToken).burn(user, to, tokenId);
        return 0;
    }

    /**
   * @dev transfer ETH to an address, revert if it fails.
   * @param to recipient of the transfer
   * @param value the amount to send
   */
    function _safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, Errors.CP_UNABLE_TO_TRANSFER_ETH);
    }

    function withdrawETH(
        address to,
        uint256 amount
    ) external override whenNotPaused nonReentrant returns(uint256) {
        require(amount != 0, Errors.CP_INVALID_AMOUNT);
        require(to != address(0), Errors.CP_INVALID_RECEIVER);
        uint256 userBalance = _balanceOf[_msgSender()];
        if(amount == type(uint256).max){
            amount = userBalance;
        }
        require(amount <= userBalance, Errors.CP_NOT_ENOUGH_BALANCE);
        address user = _msgSender();
        _balanceOf[user] = userBalance - amount;
        emit WithdrawETH(_msgSender(), to, amount);
        emit BalanceChangedETH(user, _balanceOf[user]);
        _safeTransferETH(to, amount);
        
        return amount;
    }

    function takeNFTOffMarket(uint256 tokenId) external override whenNotPaused {
        uint256 errorCode = _takeNFTOffMarket(_msgSender(), tokenId);
        require(errorCode == 0, Strings.toString(errorCode));
    }

    function takeNFTOffMarketBatch(uint256[] calldata tokenIds) external override whenNotPaused returns(uint256[] memory){
        require(tokenIds.length != 0, Errors.CP_ZERO_SIZED_ARRAY);
        address user = _msgSender();
        uint256[] memory errorCodes = new uint256[](tokenIds.length);
        for(uint256 i = 0; i < tokenIds.length; ++i){
            errorCodes[i] = _takeNFTOffMarket(user, tokenIds[i]);
        }
        return errorCodes;
    }

    function _takeNFTOffMarket(address user, uint256 tokenId) internal returns(uint256) {
        if(NToken(nToken).ownerOf(tokenId) != user){
            return ErrorCodes.CP_NOT_THE_OWNER;
        }
        DataTypes.NFTStatusMap memory status = nftStatus[tokenId];
        status.setIfOnMarket(false);
        nftStatus[tokenId].data = status.data;
        emit OffMarket(nft, user, tokenId);
        return 0;
    }

    function relistNFT(uint256 tokenId) external override whenNotPaused whenActivated{
        uint256 errorCode = _relistNFT(_msgSender(), tokenId);
        require(errorCode == 0, Strings.toString(errorCode));
    }

    function relistNFTBatch(uint256[] calldata tokenIds) external override whenNotPaused whenActivated returns(uint256[] memory){
        require(tokenIds.length != 0, Errors.CP_ZERO_SIZED_ARRAY);
        address user = _msgSender();
        uint256[] memory errorCodes = new uint256[](tokenIds.length);
        for(uint256 i = 0; i < tokenIds.length; ++i){
            errorCodes[i] = _relistNFT(user, tokenIds[i]);
        }
        return errorCodes;
    }

    function _relistNFT(address user, uint256 tokenId) internal returns(uint256) {
        if(NToken(nToken).ownerOf(tokenId) != user){
            return ErrorCodes.CP_NOT_THE_OWNER;
        }
        DataTypes.NFTStatusMap memory status = nftStatus[tokenId];
        status.setIfOnMarket(true);
        nftStatus[tokenId].data = status.data;
        emit OnMarket(nft, user, tokenId);
        return 0;
    }

    struct OpenCallLocalVars {
        uint256 strikePrice;
        uint256 premiumToOwner;
        uint256 premiumToReserve;
        uint256 errorCode;
    }

    // Open a call position
    function openCall(
        uint256 tokenId,
        uint8 strikePriceGapIdx,
        uint8 durationIdx
    ) external payable override whenNotPaused whenActivated{
        OpenCallLocalVars memory vars;
        (
            vars.strikePrice,
            vars.premiumToOwner,
            vars.premiumToReserve,
            vars.errorCode
        ) = previewOpenCall(tokenId, strikePriceGapIdx, durationIdx);
        require(vars.errorCode == 0, Strings.toString(vars.errorCode));
        address user = _msgSender();
        uint256 totalPremium = vars.premiumToOwner + vars.premiumToReserve;
        if(msg.value != totalPremium){
            require(totalPremium < msg.value, Errors.CP_DID_NOT_SEND_ENOUGH_ETH);
            _balanceOf[user] += msg.value - totalPremium;
            emit BalanceChangedETH(user, _balanceOf[user]);
        }
        address owner = IERC721(nToken).ownerOf(tokenId);
        _balanceOf[owner] += vars.premiumToOwner;
        emit BalanceChangedETH(owner, _balanceOf[owner]);
        address pool = address(this);
        _balanceOf[pool] += vars.premiumToReserve;
        emit BalanceChangedETH(pool, _balanceOf[pool]);
        uint40 currentTime = uint40(block.timestamp);
        _openCallInteractions(user, tokenId, currentTime, strikePriceGapIdx, durationIdx, vars.strikePrice);
        emit PremiumReceived(nft, owner, tokenId, vars.premiumToOwner, vars.premiumToReserve);


    }

    // Batch open position
    function openCallBatch(
        uint256[] calldata tokenIds,
        uint8[] calldata strikePriceGaps,
        uint8[] calldata durations
    ) external payable override whenNotPaused whenActivated{
        require(tokenIds.length != 0, Errors.CP_ZERO_SIZED_ARRAY);
        require(tokenIds.length == strikePriceGaps.length && tokenIds.length == durations.length, Errors.CP_ARRAY_LENGTH_UNMATCHED);
        uint256 totalPremium = 0;
        uint256 totalReservePremium = 0;
        address user = _msgSender();
        uint40 currentTime = uint40(block.timestamp);
        OpenCallLocalVars memory vars;
        for(uint256 i = 0; i < tokenIds.length; ++i){
            (
                vars.strikePrice,
                vars.premiumToOwner,
                vars.premiumToReserve,
                vars.errorCode
            ) = previewOpenCall(tokenIds[i], strikePriceGaps[i], durations[i]);
            if(vars.errorCode == 0){
                totalReservePremium += vars.premiumToReserve;
                totalPremium += vars.premiumToOwner;
                address owner = IERC721(nToken).ownerOf(tokenIds[i]);
                _balanceOf[owner] += vars.premiumToOwner;
                emit BalanceChangedETH(owner, _balanceOf[owner]);
                _openCallInteractions(user, tokenIds[i], currentTime, strikePriceGaps[i], durations[i], vars.strikePrice);
                emit PremiumReceived(nft, owner, tokenIds[i], vars.premiumToOwner, vars.premiumToReserve);
            }
        }
        totalPremium += totalReservePremium;
        address pool = address(this);
        _balanceOf[pool] += totalReservePremium;
        emit BalanceChangedETH(pool, _balanceOf[pool]);
        if(msg.value != totalPremium){
            require(msg.value > totalPremium, Errors.CP_DID_NOT_SEND_ENOUGH_ETH);
            _balanceOf[user] += msg.value - totalPremium;
            emit BalanceChangedETH(user, _balanceOf[user]);
        }
    }

    function previewOpenCall(
        uint256 tokenId,
        uint8 strikePriceGapIdx,
        uint8 durationIdx
    ) public override view returns(
        uint256 strikePrice,
        uint256 premiumToOwner,
        uint256 premiumToReserve,
        uint256 errorCode
    ) {
        return _previewOpenCall(tokenId, strikePriceGapIdx, durationIdx);
    }

    function previewOpenCallBatch( uint256[] calldata tokenIds, uint8[] calldata strikePriceGaps, uint8[] calldata durations) public override view
        returns( uint256[] memory strikePrices, uint256[] memory premiumsToOwner, uint256[] memory premiumsToReserve, uint256[] memory errorCodes) {
        require(tokenIds.length != 0, Errors.CP_ZERO_SIZED_ARRAY);
        require(tokenIds.length == strikePriceGaps.length && tokenIds.length == durations.length, Errors.CP_ARRAY_LENGTH_UNMATCHED);
        strikePrices = new uint256[](tokenIds.length);
        premiumsToOwner = new uint256[](tokenIds.length);
        premiumsToReserve = new uint256[](tokenIds.length);
        errorCodes = new uint256[](tokenIds.length);
        for(uint256 i = 0; i < tokenIds.length; ++i){
            (strikePrices[i], premiumsToOwner[i], premiumsToReserve[i], errorCodes[i]) = _previewOpenCall(tokenIds[i], strikePriceGaps[i], durations[i]);
        }
    }

    function _previewOpenCall(
        uint256 tokenId,
        uint8 strikePriceGapIdx,
        uint8 durationIdx
    ) internal view returns(
        uint256 strikePrice,
        uint256 premiumToOwner,
        uint256 premiumToReserve,
        uint256 errorCode
    ) {
        DataTypes.NFTStatusMap storage status = nftStatus[tokenId];
        strikePrice = INVALID_PRICE;
        premiumToOwner = INVALID_PRICE;
        premiumToReserve = INVALID_PRICE;
        if(_msgSender() == IERC721(nToken).ownerOf(tokenId)){
            errorCode = ErrorCodes.CP_CAN_NOT_OPEN_A_POSITION_ON_SELF_OWNED_NFT;
        }
        else if(!status.getIfOnMarket() || (block.timestamp <= uint256(status.getEndTime()))){
            errorCode = ErrorCodes.CP_NFT_ON_MARKET_OR_UNAVAILABLE;
        }
        else if(strikePriceGapIdx < status.getMinimumStrikePriceGapIdx()){
            errorCode = ErrorCodes.CP_STRIKE_GAP_TOO_LOW;
        } 
        else if(durationIdx > status.getMaximumDurationIdx()) {
            errorCode = ErrorCodes.CP_DURATION_TOO_LONG;
        }
        else {
            uint256 openPrice;
            (openPrice, premiumToReserve, premiumToOwner) = _calculatePremium(strikePriceGapIdx, durationIdx);
            if(premiumToOwner < minimumPremiumToOwner){
                errorCode = ErrorCodes.CP_TOO_LITTLE_PREMIUM_TO_OWNER;
            }
            else{
                strikePrice =  openPrice + openPrice * STRIKE_PRICE_GAP(strikePriceGapIdx) / PRECISION;
                if(strikePrice < convertFromStrikePrice(status.getMinimumStrikePrice())){
                    errorCode = ErrorCodes.CP_STRIKE_PRICE_TOO_LOW;
                }
                else if(strikePrice > MAXIMUM_STRIKE_PRICE_IN_CONTRACT_DECIMALS){
                    errorCode = ErrorCodes.CP_PRICE_TOO_HIGH;
                }
                else{
                    errorCode = 0;
                }
            }
        }
    }

    function _openCallInteractions(address user, uint256 tokenId, uint40 currentTime, uint8 strikePriceGapIdx, uint8 durationIdx, uint256 strikePrice) internal {
        uint40 duration = DURATION(durationIdx);
        uint40 exercisePeriodEnd = currentTime + duration;
        uint40 exercisePeriodBegin = exercisePeriodEnd - duration * exercisePeriodProportion / 10000;
        DataTypes.NFTStatusMap memory status = nftStatus[tokenId];
        status.setExerciseTime(exercisePeriodBegin);
        status.setEndTime(exercisePeriodEnd);
        status.setStrikePrice(convertToStrikePrice(strikePrice));
        nftStatus[tokenId].data = status.data;
        ICallToken(callToken).open(user, tokenId);
        emit CallOpened(nft, user, tokenId, strikePriceGapIdx, durationIdx, strikePrice, exercisePeriodBegin, exercisePeriodEnd);
        
    }

    // Exercise a call position
    function exerciseCall(uint256 tokenId) external payable override whenNotPaused whenActivated nonReentrant{
        (uint256 errorCode, uint256 remainValue) = _exerciseCall(_msgSender(), tokenId, msg.value, block.timestamp);
        require(errorCode == 0, Strings.toString(errorCode));
        require(remainValue == 0, Errors.CP_NOT_ENOUGH_OR_TOO_MUCH_ETH);
    }

    // Exercise a call position
    // To avoid reentrancy attack, we can not use the amount in the _balanceOf[user] to pay the strike price.
    function exerciseCallBatch(uint256[] calldata tokenIds) external payable override whenNotPaused whenActivated nonReentrant returns(uint256[] memory){
        require(tokenIds.length != 0, Errors.CP_ZERO_SIZED_ARRAY);
        address user = _msgSender();
        uint256 remainValue = msg.value;
        uint256 currentTime = block.timestamp;
        uint256[] memory errorCodes = new uint256[](tokenIds.length);
        for(uint256 i = 0; i < tokenIds.length; ++ i){
            (errorCodes[i], remainValue) = _exerciseCall(_msgSender(), tokenIds[i], remainValue, currentTime);
        }
        if(remainValue > 0){
            _balanceOf[user] += remainValue;
            emit BalanceChangedETH(user, _balanceOf[user]);
        }
        return errorCodes;
    }

    // Exercise a call position
    function _exerciseCall(address user, uint256 tokenId, uint256 value, uint256 currentTime) internal returns(uint256 errorCode, uint256 remainValue){
        DataTypes.NFTStatusMap storage status = nftStatus[tokenId];
        uint256 strikePrice = convertFromStrikePrice(status.getStrikePrice());
        if(uint256(status.getEndTime()) < currentTime || uint256(status.getExerciseTime()) > currentTime){
            return (ErrorCodes.CP_NOT_IN_THE_EXERCISE_PERIOD, value);
        }
        if(CallToken(callToken).ownerOf(tokenId) != user){
            return (ErrorCodes.CP_NOT_THE_OWNER, value);
        }
        if(strikePrice > value){
            return (ErrorCodes.CP_DID_NOT_SEND_ENOUGH_ETH, value);
        }
        // Burn CallToken
        CallToken(callToken).burn(tokenId);
        delete nftStatus[tokenId];
        address originalOwner = NToken(nToken).ownerOf(tokenId);

        // Pay strike price to NToken owner
        _balanceOf[originalOwner] += strikePrice;

        emit BalanceChangedETH(originalOwner, _balanceOf[originalOwner]);
        emit CallClosed(nft, user, originalOwner, tokenId, strikePrice);
        // Burn NToken and transfer underlying NFT
        NToken(nToken).burn(originalOwner, user, tokenId);
        
        return (0, value - strikePrice);
    }

    function collectProtocol(
        address recipient,
        uint256 amountRequested
    ) external override onlyFactoryOwner returns (uint256 amountSent) {
        require(recipient != address(0), Errors.CP_INVALID_RECEIVER);
        require(amountRequested != 0, Errors.CP_INVALID_AMOUNT);
        uint256 balance = _balanceOf[address(this)];
        amountSent = amountRequested > balance ? balance : amountRequested;
        if (amountSent > 0) {
            address pool = address(this);
            _balanceOf[pool] -= amountSent;
            emit BalanceChangedETH(pool, _balanceOf[pool]);
            emit CollectProtocol(_msgSender(), recipient, amountSent);
            _safeTransferETH(recipient, amountSent);
        }
    }

    function _calculatePremium(
        uint8 strikePriceGapIdx,
        uint8 durationIdx
    ) internal view returns(
        uint256 openPrice,
        uint256 premiumToReserve,
        uint256 premiumToOwner
    ){
        require(uint256(strikePriceGapIdx) <= MAXIMUM_VALID_STRIKE_PRICE_GAP_IDX && uint256(durationIdx) <= MAXIMUM_VALID_DURATION_IDX, Errors.CP_GAP_OR_DURATION_OUT_OF_INDEX);

        IPriceOracle _oracle = IPriceOracle(oracle);
        uint256 vol = _oracle.getAssetVol(nft);
        openPrice = _oracle.getAssetPrice(nft);

        IPremium _premium = IPremium(premium);
        uint256 currentPremium = _premium.getPremium(uint256(strikePriceGapIdx) * 4 + uint256(durationIdx), vol);
        uint256 precision = _premium.precision();

        uint256 premiumTotal = openPrice * currentPremium / precision;
        premiumToReserve = premiumTotal * RESERVE / PRECISION;
        premiumToOwner = premiumTotal - premiumToReserve;
    }

    function getNFTStatus(uint256 tokenId) external view override returns (DataTypes.NFTStatusOutput memory) {
        return _getNFTStatus(tokenId);
    }

    function getNFTStatusBatch(uint256[] calldata tokenIds) external view override returns (DataTypes.NFTStatusOutput[] memory) {
        require(tokenIds.length != 0, Errors.CP_ZERO_SIZED_ARRAY);
        DataTypes.NFTStatusOutput[] memory statuses = new DataTypes.NFTStatusOutput[](tokenIds.length);
        for(uint256 i = 0; i < tokenIds.length; ++i){
            statuses[i] = _getNFTStatus(tokenIds[i]);
        }
        return statuses;
    }

    function _getNFTStatus(uint256 tokenId) internal view returns (DataTypes.NFTStatusOutput memory) {
        require(IERC721(nToken).ownerOf(tokenId) != address(0), Errors.CP_NFT_ON_MARKET_OR_UNAVAILABLE);
        DataTypes.NFTStatusMap storage _status = nftStatus[tokenId];
        DataTypes.NFTStatusOutput memory status = DataTypes.NFTStatusOutput(
            _status.getIfOnMarket(),
            _status.getMinimumStrikePriceGapIdx(),
            _status.getMaximumDurationIdx(),
            uint256(_status.getExerciseTime()),
            uint256(_status.getEndTime()),
            convertFromStrikePrice(_status.getMinimumStrikePrice()),
            convertFromStrikePrice(_status.getStrikePrice())
        );
        return status;
    }

    function changePreference(
        uint256 tokenId,
        uint8 lowerStrikePriceGapIdx,
        uint8 upperDurationIdx,
        uint256 minimumStrikePrice
    ) external override whenNotPaused whenActivated{
        address user = _msgSender();
        uint256 currentTime = block.timestamp;
        uint256 errorCode = _changePreference(user, tokenId, lowerStrikePriceGapIdx, upperDurationIdx, minimumStrikePrice, currentTime);
        require(errorCode == 0, Strings.toString(errorCode));
    }

    function changePreferenceBatch(
        uint256[] calldata tokenIds,
        uint8[] calldata lowerStrikePriceGapIdxList,
        uint8[] calldata upperDurationIdxList,
        uint256[] calldata minimumStrikePriceList
    ) external override whenNotPaused whenActivated returns(uint256[] memory){
        require(tokenIds.length != 0, Errors.CP_ZERO_SIZED_ARRAY);
        require(tokenIds.length == lowerStrikePriceGapIdxList.length 
                && tokenIds.length == upperDurationIdxList.length 
                && tokenIds.length == minimumStrikePriceList.length
                , Errors.CP_ARRAY_LENGTH_UNMATCHED);
        uint256[] memory errorCodes = new uint256[](tokenIds.length);
        address user = _msgSender();
        uint256 currentTime = block.timestamp;
        for(uint256 i=0; i < tokenIds.length; ++i){
            errorCodes[i] = _changePreference(user, tokenIds[i], lowerStrikePriceGapIdxList[i], upperDurationIdxList[i], minimumStrikePriceList[i], currentTime);
        }
        return errorCodes;
    }

    function _changePreference(
        address user,
        uint256 tokenId,
        uint8 lowerStrikePriceGapIdx,
        uint8 upperDurationIdx,
        uint256 minimumStrikePrice,
        uint256 currentTime
    ) internal returns(uint256) {
        if(NToken(nToken).ownerOf(tokenId) != user){
            return ErrorCodes.CP_NOT_THE_OWNER;
        }
        if(currentTime <= uint256(nftStatus[tokenId].getEndTime())){
            return ErrorCodes.CP_NFT_ON_MARKET_OR_UNAVAILABLE;
        }
        if(minimumStrikePrice > MAXIMUM_STRIKE_PRICE){
            return ErrorCodes.CP_PRICE_TOO_HIGH;
        }
        DataTypes.NFTStatusMap memory status = nftStatus[tokenId];
        status.setMinimumStrikePriceGapIdx(lowerStrikePriceGapIdx);
        status.setMaximumDurationIdx(upperDurationIdx);
        status.setMinimumStrikePrice(convertToStrikePrice(minimumStrikePrice));
        nftStatus[tokenId].data = status.data;
        emit PreferenceUpdated(nft, tokenId, lowerStrikePriceGapIdx, upperDurationIdx, minimumStrikePrice);
        return 0;
    }

    function totalOpenInterest() external view override returns(uint256) {
        return IERC721Enumerable(callToken).totalSupply();
    }

    function getEndTime(uint256 tokenId) external view override returns(uint256) {
        return uint256(nftStatus[tokenId].getEndTime());
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.9;

interface ICallPoolDeployer {
    function parameters() external view returns (
        address factory,
        address erc721token,
        address ntoken,
        address calltoken,
        address oracle,
        address premium
    );
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./interfaces/ICallPoolDeployer.sol";
import "./interfaces/INToken.sol";
import "./Errors.sol";

contract NToken is ERC721, INToken, Ownable, IERC721Receiver {
    address public immutable override factory;
    address public immutable override nft;
    
    modifier onlyFactoryOwner() {
        require(_msgSender() == Ownable(factory).owner(), Errors.CP_CALLER_IS_NOT_FACTORY_OWNER);
        _;
    }

    constructor() ERC721("NFTCall Wrapped ", "n") Ownable() {
        (factory, nft, , , ,) = ICallPoolDeployer(msg.sender).parameters();
    }

    function name() public view override returns (string memory) {
        return string(abi.encodePacked(ERC721.name(), IERC721Metadata(nft).name()));

    }

    function symbol() public view override returns (string memory) {
        return string(abi.encodePacked(ERC721.symbol(), IERC721Metadata(nft).symbol()));
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory){
        return IERC721Metadata(nft).tokenURI(tokenId);
    }

    function mint(address user, uint256 tokenId) public override onlyOwner{
        _safeMint(user, tokenId);
        emit Mint(user, tokenId);
    }

    function burn(address user, address receiverOfUnderlying, uint256 tokenId) public override onlyOwner{
        _burn(tokenId);
        emit Burn(user, receiverOfUnderlying, tokenId);
        IERC721(nft).safeTransferFrom(address(this), receiverOfUnderlying, tokenId);
    }

    function transferERC721(address collection, address recipient, uint256 tokenId) public override onlyFactoryOwner{
        require(collection != nft || !_exists(tokenId), "Can only transfer NFT that have been accidentally sent.");
        require(recipient != address(0), "Cannot use zero address as recipient.");
        IERC721(collection).safeTransferFrom(address(this), recipient, tokenId);
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4){
        return this.onERC721Received.selector;
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC721, IERC165, IERC721, IERC721Metadata} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {IERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import {ICallToken} from "./interfaces/ICallToken.sol";
import {ICallPoolDeployer} from "./interfaces/ICallPoolDeployer.sol";
import {ICallPoolState} from "./interfaces/pool/ICallPoolState.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Errors} from "./Errors.sol";

contract CallToken is ERC721, IERC721Enumerable, ICallToken, Ownable {
    using Strings for uint256;

    address public immutable override factory;
    address public immutable override nft;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    string private _baseTokenURI;

    constructor() ERC721("NFTCall ", "call") Ownable() {
        (factory, nft, , , ,) = ICallPoolDeployer(msg.sender).parameters();
    }

    modifier onlyFactoryOwner() {
        require(_msgSender() == Ownable(factory).owner(), Errors.CP_CALLER_IS_NOT_FACTORY_OWNER);
        _;
    }

    function name() public view override returns (string memory) {
        return string(abi.encodePacked(ERC721.name(), IERC721Metadata(nft).name(), " Call"));

    }

    function symbol() public view override returns (string memory) {
        return string(abi.encodePacked(ERC721.symbol(), IERC721Metadata(nft).symbol()));
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(block.timestamp <= ICallPoolState(Ownable.owner()).getEndTime(tokenId), "token is expired");
        string memory baseURI = _baseTokenURI;
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    function ownerOf(uint256 tokenId) public view virtual override(IERC721, ERC721) returns(address) {
        require(block.timestamp <= ICallPoolState(Ownable.owner()).getEndTime(tokenId), "token is expired");
        return ERC721.ownerOf(tokenId);
    }

    function balanceOf(address owner) public view virtual override(IERC721, ERC721) returns(uint256) {
        uint256 balance = 0;
        uint256 currentTime = block.timestamp;
        for(uint256 i = 0; i < _allTokens.length; ++i){
            uint256 tokenId = _allTokens[i];
            if(ERC721.ownerOf(tokenId) == owner && currentTime <= ICallPoolState(Ownable.owner()).getEndTime(tokenId)){
                balance += 1;
            }
        }
        return balance;
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override(IERC721, ERC721) {
        uint256 endTime = ICallPoolState(Ownable.owner()).getEndTime(tokenId);
        require(block.timestamp <= endTime, "token is expired");
        ERC721.transferFrom(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override(IERC721, ERC721) {
        uint256 endTime = ICallPoolState(Ownable.owner()).getEndTime(tokenId);
        require(block.timestamp <= endTime, "token is expired");
        ERC721.safeTransferFrom(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override(IERC721, ERC721) {
        uint256 endTime = ICallPoolState(Ownable.owner()).getEndTime(tokenId);
        require(block.timestamp <= endTime, "token is expired");
        ERC721.safeTransferFrom(from, to, tokenId, data);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < _allTokens.length, "owner index out of bounds");
        uint256 currentTime = block.timestamp;
        uint256 userIndex = 0;
        for(uint256 i = 0; i < _allTokens.length; ++i) {
            uint256 tokenId = _allTokens[i];
            if(ERC721.ownerOf(tokenId) == owner && currentTime <= ICallPoolState(Ownable.owner()).getEndTime(tokenId)){
                if(userIndex == index){
                    return tokenId;
                }
                else{
                    userIndex += 1;
                }
            }
        }
        revert("owner index out of bounds");
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        uint256 supply = 0;
        uint256 currentTime = block.timestamp;
        for(uint256 i = 0; i < _allTokens.length; ++i){
            uint256 tokenId = _allTokens[i];
            if(currentTime <= ICallPoolState(Ownable.owner()).getEndTime(tokenId)){
                supply += 1;
            }
        }
        return supply;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        uint256 currentIndex = 0;
        uint256 currentTime = block.timestamp;
        for(uint256 i = 0; i < _allTokens.length; ++i){
            uint256 tokenId = _allTokens[i];
            if(currentTime <= ICallPoolState(Ownable.owner()).getEndTime(tokenId)){
                if(currentIndex == index){
                    return tokenId;
                }
                else{
                    currentIndex += 1;
                }
            }
        }
        revert("ERC721Enumerable: global index out of bounds");
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721) {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } 
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    function mint(address user, uint256 tokenId) external override onlyOwner {
        _safeMint(user, tokenId);
        emit Mint(user, tokenId);
    }

    function burn(uint256 tokenId) external override onlyOwner {
        address owner = ERC721.ownerOf(tokenId);
        _burn(tokenId);
        emit Burn(owner, tokenId);
    }

    function open( address user, uint256 tokenId) external override onlyOwner {
        emit MetadataUpdate(tokenId);
        _transfer(ERC721.ownerOf(tokenId), user, tokenId);
    }

    function updateBaseURI(string calldata baseURI) external override onlyFactoryOwner {
        _baseTokenURI = baseURI;
        emit BaseURIUpdated(baseURI);
        emit BatchMetadataUpdate(0, type(uint256).max);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.9;

import "./pool/ICallPoolActions.sol";
import "./pool/ICallPoolDerivedState.sol";
import "./pool/ICallPoolEvents.sol";
import "./pool/ICallPoolImmutables.sol";
import "./pool/ICallPoolOwnerActions.sol";
import "./pool/ICallPoolState.sol";

interface ICallPool is ICallPoolImmutables, ICallPoolActions, ICallPoolDerivedState, ICallPoolEvents, ICallPoolOwnerActions, ICallPoolState{
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

/************
@title IPriceOracle interface
@notice Interface for the Aave price oracle.*/
interface IPriceOracle {
  /***********
    @dev returns the asset price in wei
     */
  function getAssetPrice(address asset) external view returns (uint256);

  /***********
    @dev sets the asset price, in wei
     */
  function setAssetPrice(address asset, uint256 price) external;

  function getAssetVol(address asset) external view returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;


interface IPremium {
  function getPremium(uint256 curveIdx, uint256 vol) external view returns (uint256);
  function precision() external pure returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.9;

interface ICallToken {
    function factory() external returns(address);
    function nft() external returns(address);

    event Mint(address indexed user, uint256 indexed tokenId);

    function mint(address user, uint256 tokenId) external;

    event Burn(address indexed user, uint256 indexed tokenId);

    function burn(uint256 tokenId) external;

    function open(address user, uint256 tokenId) external;

    event BaseURIUpdated(string newBaseURI);

    function updateBaseURI(string memory baseURI) external;

    /// @dev This event emits when the metadata of a token is changed.
    /// So that the third-party platforms such as NFT market could
    /// timely update the images and related attributes of the NFT.
    event MetadataUpdate(uint256 _tokenId);

    /// @dev This event emits when the metadata of a range of tokens is changed.
    /// So that the third-party platforms such as NFT market could
    /// timely update the images and related attributes of the NFTs.    
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

library Errors {
    string public constant CP_CALLER_IS_NOT_FACTORY_OWNER = "1";
    string public constant CP_GAP_OR_DURATION_OUT_OF_INDEX = "2";
    string public constant CP_NFT_ON_MARKET_OR_UNAVAILABLE = "3";
    string public constant CP_NOT_THE_OWNER = "4";

    string public constant CP_INVALID_AMOUNT = "5";
    string public constant CP_INVALID_RECEIVER = "6";
    string public constant CP_NOT_ENOUGH_BALANCE = "7";

    string public constant CP_CAN_NOT_OPEN_CALL = "8";
    string public constant CP_DID_NOT_SEND_ENOUGH_ETH = "9";

    string public constant CP_ARRAY_LENGTH_UNMATCHED = "10";

    string public constant CP_NOT_IN_THE_EXERCISE_PERIOD = "11";

    string public constant CP_STRIKE_GAP_TOO_LOW = "12";
    string public constant CP_DURATION_TOO_LONG = "13";
    string public constant CP_STRIKE_PRICE_TOO_LOW = "14";

    string public constant CP_TOO_LITTLE_PREMIUM_TO_OWNER = "15";
    string public constant CP_PREMIUM_AND_ETH_UNEQUAL = "16";
    string public constant CP_CAN_NOT_OPEN_A_POSITION_ON_SELF_OWNED_NFT = "17";

    string public constant CP_DEACTIVATED = "18";
    string public constant CP_ACTIVATED = "19";

    string public constant CP_PRICE_TOO_HIGH = "20";

    string public constant CP_ZERO_SIZED_ARRAY = "21";

    string public constant CP_UNABLE_TO_TRANSFER_ETH = "22";

    string public constant CP_NOT_ENOUGH_OR_TOO_MUCH_ETH = "23";
}

library ErrorCodes {
    uint256 public constant CP_CALLER_IS_NOT_FACTORY_OWNER = 1;
    uint256 public constant CP_GAP_OR_DURATION_OUT_OF_INDEX = 2;
    uint256 public constant CP_NFT_ON_MARKET_OR_UNAVAILABLE = 3;
    uint256 public constant CP_NOT_THE_OWNER = 4;

    uint256 public constant CP_INVALID_AMOUNT = 5;
    uint256 public constant CP_INVALID_RECEIVER = 6;
    uint256 public constant CP_NOT_ENOUGH_BALANCE = 7;

    uint256 public constant CP_CAN_NOT_OPEN_CALL = 8;
    uint256 public constant CP_DID_NOT_SEND_ENOUGH_ETH = 9;

    uint256 public constant CP_ARRAY_LENGTH_UNMATCHED = 10;

    uint256 public constant CP_NOT_IN_THE_EXERCISE_PERIOD = 11;

    uint256 public constant CP_STRIKE_GAP_TOO_LOW = 12;
    uint256 public constant CP_DURATION_TOO_LONG = 13;
    uint256 public constant CP_STRIKE_PRICE_TOO_LOW = 14;

    uint256 public constant CP_TOO_LITTLE_PREMIUM_TO_OWNER = 15;
    uint256 public constant CP_PREMIUM_AND_ETH_UNEQUAL = 16;
    uint256 public constant CP_CAN_NOT_OPEN_A_POSITION_ON_SELF_OWNED_NFT = 17;

    uint256 public constant CP_DEACTIVATED = 18;
    uint256 public constant CP_ACTIVATED = 19;

    uint256 public constant CP_PRICE_TOO_HIGH = 20;

    uint256 public constant CP_ZERO_SIZED_ARRAY = 21;

    uint256 public constant CP_UNABLE_TO_TRANSFER_ETH = 22;
    
    uint256 public constant CP_NOT_ENOUGH_OR_TOO_MUCH_ETH = 23;
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.9;

uint256 constant MAXIMUM_VALID_DURATION_IDX = 3;
uint256 constant MAXIMUM_VALID_STRIKE_PRICE_GAP_IDX = 5;

uint256 constant STRIKE_PRICE_DECIMALS = 9;
uint256 constant MAXIMUM_STRIKE_PRICE = type(uint64).max;

library DataTypes {

    // Used to store nft availability and related call NFT. Here needs to consider data compression
    struct NFTStatusMap {
        // bit 0-1: maximumDurationIdx: value 0-3. 3 means the duration should be <= 28d. Default value is 3.
        // bit 2-4: minimumStrikeGapIdx: value 0-5. 1 means the strike price gap must be >= 10%. Default value is 1.
        // bit 5: NFT is on market
        // bit 6: reserved
        // bit 7: always be 1
        // bit 8-47: reserved
        // bit 48-87: exerciseTime
        // bit 88-127: endTime
        // bit 128-191: minimumStrikePrice
        // bit 192-255: strikePrice
        uint256 data;
        /* uint8 nftPreferenceMap;
        uint40 reserved;
        uint40 exerciseTime;
        uint40 endTime;
        uint64 minimumStrikePrice;
        uint64 strikePrice;*/
    }

    uint256 public constant NFT_STATUS_MAP_INIT_VALUE = 1 << 7;

    struct NFTStatusOutput {
        bool ifOnMarket;
        uint8 minimumStrikeGapIdx;
        uint8 maximumDurationIdx;
        uint256 exerciseTime;       // When can exercise
        uint256 endTime;            // When this call expire
        uint256 minimumStrikePrice;
        uint256 strikePrice;
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.9;

import {Errors} from './Errors.sol';
import {DataTypes, MAXIMUM_VALID_DURATION_IDX, MAXIMUM_VALID_STRIKE_PRICE_GAP_IDX} from './DataTypes.sol';

/**
 * @title ReserveConfiguration library
 * @author Aave
 * @notice Implements the bitmap logic to handle the reserve configuration
 */
library NFTStatus {
  uint256 constant MAXIMUM_DURATION_IDX_MASK =             0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC; // prettier-ignore
  uint256 constant MINIMUM_STRIKE_PRICE_GAP_IDX_MASK =     0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE3; // prettier-ignore
  uint256 constant IF_ON_MARKET_MASK =             0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFDF; // prettier-ignore
  uint256 constant EXERCISE_TIME_MASK =            0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000000000FFFFFFFFFFFF; // prettier-ignore
  uint256 constant END_TIME_MASK =                 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000000000FFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore
  uint256 constant MINIMUM_STRIKE_PRICE_MASK =       0xFFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore
  uint256 constant STRIKE_PRICE_MASK =             0x0000000000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore

  /// @dev For the Duration index, the start bit is 0 (up to 1), hence no bitshifting is needed
  uint256 constant MINIMUM_STRIKE_PRICE_GAP_IDX_START_BIT_POSITION = 2;
  uint256 constant IF_ON_MARKET_START_BIT_POSITION = 5;
  uint256 constant EXERCISE_TIME_START_BIT_POSITION = 48;
  uint256 constant END_TIME_START_BIT_POSITION = 88;
  uint256 constant MINIMUM_STRIKE_PRICE_START_BIT_POSITION = 128;
  uint256 constant STRIKE_PRICE_START_BIT_POSITION = 192;
  

  
  function setMaximumDurationIdx(DataTypes.NFTStatusMap memory self, uint8 durationIdx) internal pure {
    require(durationIdx <= uint8(MAXIMUM_VALID_DURATION_IDX), Errors.CP_GAP_OR_DURATION_OUT_OF_INDEX);
    self.data = (self.data & MAXIMUM_DURATION_IDX_MASK) | uint256(durationIdx);
  }

  function getMaximumDurationIdx(DataTypes.NFTStatusMap storage self) internal view returns (uint8) {
    return uint8(self.data & ~MAXIMUM_DURATION_IDX_MASK);
  }

  function setMinimumStrikePriceGapIdx(DataTypes.NFTStatusMap memory self, uint8 strikePriceGapIdx) internal pure
  {
    require(strikePriceGapIdx <= uint8(MAXIMUM_VALID_STRIKE_PRICE_GAP_IDX), Errors.CP_GAP_OR_DURATION_OUT_OF_INDEX);

    self.data =
      (self.data & MINIMUM_STRIKE_PRICE_GAP_IDX_MASK) |
      (uint256(strikePriceGapIdx) << MINIMUM_STRIKE_PRICE_GAP_IDX_START_BIT_POSITION);
  }

  function getMinimumStrikePriceGapIdx(DataTypes.NFTStatusMap storage self) internal view returns (uint8)
  {
    return uint8((self.data & ~MINIMUM_STRIKE_PRICE_GAP_IDX_MASK) >> MINIMUM_STRIKE_PRICE_GAP_IDX_START_BIT_POSITION);
  }

  function setIfOnMarket(DataTypes.NFTStatusMap memory self, bool ifOnMarket) internal pure
  {
    self.data = 
        (self.data & IF_ON_MARKET_MASK) |
        (uint256(ifOnMarket?1:0) << IF_ON_MARKET_START_BIT_POSITION);
  }

  function getIfOnMarket(DataTypes.NFTStatusMap storage self) internal view returns (bool)
  {
    return (self.data & ~IF_ON_MARKET_MASK) != 0;
  }

  function setExerciseTime(DataTypes.NFTStatusMap memory self, uint40 exerciseTime) internal pure
  {
    self.data = 
        (self.data & EXERCISE_TIME_MASK) |
        (uint256(exerciseTime) << EXERCISE_TIME_START_BIT_POSITION);
  }

  function getExerciseTime(DataTypes.NFTStatusMap storage self) internal view returns (uint40)
  {
    return uint40((self.data & ~EXERCISE_TIME_MASK) >> EXERCISE_TIME_START_BIT_POSITION);
  }

  function setEndTime(DataTypes.NFTStatusMap memory self, uint40 endTime) internal pure
  {
    self.data = 
        (self.data & END_TIME_MASK) |
        (uint256(endTime) << END_TIME_START_BIT_POSITION);
  }

  function getEndTime(DataTypes.NFTStatusMap storage self) internal view returns (uint40)
  {
    return uint40((self.data & ~END_TIME_MASK) >> END_TIME_START_BIT_POSITION);
  }

  function setMinimumStrikePrice(DataTypes.NFTStatusMap memory self, uint64 strikePriceLimit) internal pure
  {
    self.data = 
        (self.data & MINIMUM_STRIKE_PRICE_MASK) |
        (uint256(strikePriceLimit) << MINIMUM_STRIKE_PRICE_START_BIT_POSITION);
  }

  function getMinimumStrikePrice(DataTypes.NFTStatusMap storage self) internal view returns (uint64)
  {
    return uint64((self.data & ~MINIMUM_STRIKE_PRICE_MASK) >> MINIMUM_STRIKE_PRICE_START_BIT_POSITION);
  }

  function setStrikePrice(DataTypes.NFTStatusMap memory self, uint64 strikePrice) internal pure
  {
    self.data = 
        (self.data & STRIKE_PRICE_MASK) |
        (uint256(strikePrice) << STRIKE_PRICE_START_BIT_POSITION);
  }

  function getStrikePrice(DataTypes.NFTStatusMap storage self) internal view returns (uint64)
  {
    return uint64((self.data & ~STRIKE_PRICE_MASK) >> STRIKE_PRICE_START_BIT_POSITION);
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title Permissionless pool actions
/// @notice Contains pool methods that can be called by anyone
interface ICallPoolActions {
    // Deposit NFT
    function deposit(address onBehalfOf, uint256 tokenId) external;

    function depositBatch(address onBehalfOf, uint256[] memory tokenIds) external returns (uint256[] memory errorCodes);

    function depositWithPreference(address onBehalfOf, uint256 tokenId, uint8 lowerStrikePriceGapIdx, uint8 upperDurationIdx, uint256 minimumStrikePrice) external;

    function depositWithPreferenceBatch(address onBehalfOf, uint256[] memory tokenIds, uint8[] memory lowerStrikePriceGapIdxList, uint8[] memory upperDurationIdxList, uint256[] memory minimumStrikePriceList) external returns(uint256[] memory errorCodes);

    // Withdraw NFT
    function withdraw(address to, uint256 tokenId) external;

    function withdrawBatch(address to, uint256[] memory tokenIds) external returns (uint256[] memory errorCodes);

    function withdrawETH(address to, uint256 amount) external returns(uint256);

    // Open option
    function openCall(uint256 tokenId, uint8 strikePriceIdx, uint8 durationIdx) external payable;

    function openCallBatch(uint256[] memory tokenIds, uint8[] memory strikePrices, uint8[] memory durations) external payable;

    // Close option
    function exerciseCall(uint256 tokenId) external payable;

    function exerciseCallBatch(uint256[] memory tokenIds) external payable returns (uint256[] memory errorCodes);

    function takeNFTOffMarket(uint256 tokenId) external;

    function takeNFTOffMarketBatch(uint256[] memory tokenIds) external returns (uint256[] memory errorCodes);

    function relistNFT(uint256 tokenId) external;

    function relistNFTBatch(uint256[] memory tokenIds) external returns (uint256[] memory errorCodes);


    function changePreference(
        uint256 tokenId,
        uint8 lowerStrikePriceGapIdx,
        uint8 upperDurationIdx,
        uint256 minimumStrikePrice
    ) external;

    function changePreferenceBatch(
        uint256[] memory tokenId,
        uint8[] memory lowerStrikePriceGapIdxList,
        uint8[] memory upperDurationIdxList,
        uint256[] memory minimumStrikePriceList
    ) external returns (uint256[] memory errorCodes);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title Pool state that is not stored
/// @notice Contains view functions to provide information about the pool that is computed rather than stored on the
/// blockchain. The functions here may have variable gas costs.
interface ICallPoolDerivedState {
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title Events emitted by a pool
/// @notice Contains all events emitted by the pool
interface ICallPoolEvents {
    event Activate(address account);
    event Deactivate(address account);

    event Deposit(address indexed nft, address user, address indexed onBehalfOf, uint256 indexed tokenId);
    event PreferenceUpdated(address indexed nft, uint256 indexed tokenId, uint8 lowerStrikePriceGapIdx, uint8 upperDurationIdx, uint256 minimumStrikePrice);
    event Withdraw(address indexed nft, address indexed user, address to, uint256 indexed tokenId);
    event CallOpened(address indexed nft, address indexed user, uint256 indexed tokenId, uint8 strikePriceGapIdx, uint8 durationIdx, uint256 exercisePrice, uint40 exercisePeriodBegin, uint40 exercisePeriodEnd);
    event PremiumReceived(address indexed nft, address indexed owner, uint256 indexed tokenId, uint256 premiumToOwner, uint256 premiumToReserve);
    event CallClosed(address indexed nft, address indexed user, address owner, uint256 indexed tokenId, uint256 price);
    event OffMarket(address indexed nft, address indexed owner, uint256 indexed tokenId);
    event OnMarket(address indexed nft, address indexed owner, uint256 indexed tokenId);
    event WithdrawETH(address indexed user, address indexed to, uint256 amount);
    event BalanceChangedETH(address indexed user, uint256 newBalance);

    /// @notice Emitted when the collected protocol fees are withdrawn by the factory owner
    /// @param sender The address that collects the protocol fees
    /// @param recipient The address that receives the collected protocol fees
    /// @param amount The amount of token0 protocol fees that is withdrawn
    event CollectProtocol(address indexed sender, address indexed recipient, uint256 amount);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title Permissioned pool actions
/// @notice Contains pool methods that may only be called by the factory owner
interface ICallPoolOwnerActions {
    function collectProtocol(
        address recipient,
        uint256 amountRequested
    ) external returns (uint256 amountSent);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {DataTypes} from '../../DataTypes.sol';

/// @title Pool state that can change
/// @notice These methods compose the pool's state, and can change with any frequency including multiple times
/// per transaction
interface ICallPoolState {

    function balanceOf(address user) external view returns(uint256);

    // Get NFTStatus
    function getNFTStatus(uint256 tokenId) external view returns (DataTypes.NFTStatusOutput memory);

    function getNFTStatusBatch(uint256[] memory tokenIds) external view returns (DataTypes.NFTStatusOutput[] memory);

    function previewOpenCall( uint256 tokenId, uint8 strikePriceGapIdx, uint8 durationIdx) external view 
        returns( uint256 strikePrice, uint256 premiumToOwner, uint256 premiumToReserve, uint256 errorCode );

    function previewOpenCallBatch( uint256[] memory tokenIds, uint8[] memory strikePriceGaps, uint8[] memory durations) external view
        returns( uint256[] memory strikePrices, uint256[] memory premiumsToOwner, uint256[] memory premiumsToReserve, uint256[] memory errorCodes);

    function totalOpenInterest() external view returns(uint256);

    function getEndTime(uint256 tokenId) external view returns(uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.9;

interface INToken {
    function factory() external view returns(address);
    
    function nft() external view returns(address);

    event Mint(address indexed from, uint256 tokenId);

    function mint(address user, uint256 tokenId) external;

    event Burn(address indexed from, address indexed target, uint256 tokenId);

    function burn(address user, address receiverOfUnderlying, uint256 tokenId) external;

    event NFTTransfered(address indexed collection, address indexed recipient, uint256 indexed tokenId);

    function transferERC721(address collection, address recipient, uint256 tokenId) external;
}