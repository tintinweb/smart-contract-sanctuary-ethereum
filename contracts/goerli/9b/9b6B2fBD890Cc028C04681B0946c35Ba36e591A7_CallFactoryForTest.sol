// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import '../interfaces/ICallPoolDeployer.sol';
import '../interfaces/ICallFactory.sol';
import '../NoDelegateCall.sol';
import '../NToken.sol';
import '../CallToken.sol';
import './CallPoolForTest.sol';

abstract contract CallPoolDeployerForTest is ICallPoolDeployer {
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
        pool = address(new CallPoolForTest{salt: keccak256(abi.encode('callpool', erc721token, ntoken, calltoken, oracle, premium))}());
        NToken(ntoken).transferOwnership(pool);
        CallToken(calltoken).transferOwnership(pool);

        delete parameters;
    }
}

contract CallFactoryForTest is ICallFactory, CallPoolDeployerForTest, NoDelegateCall, Ownable {

    mapping(address => address) public override getPool;

    constructor(address nTokenFactory, address callTokenFactory) Ownable() CallPoolDeployerForTest(nTokenFactory, callTokenFactory) {
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
        address pool = deploy(address(this), erc721token, oracle, premium);
        // populate mapping in the reverse direction, deliberate choice to avoid the cost of comparing addresses
        getPool[erc721token] = pool;
        emit PoolCreated(erc721token, oracle, pool, premium);
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.9;

interface ICallFactory {
    event PoolCreated(
        address indexed erc721token,
        address oracle,
        address pool,
        address premium);
    
    function getPool(address erc721token) external view returns (address pool);
    function createPool(address erc721token, address oracle, address premium) external returns (address pool);
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

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./interfaces/ICallPoolDeployer.sol";
import "./interfaces/INToken.sol";

contract NToken is ERC721, INToken, Ownable, IERC721Receiver {
    address public immutable override nft;

    constructor() ERC721("NToken", "N") Ownable() {
        (, nft, , , ,) = ICallPoolDeployer(msg.sender).parameters();
    }

    function name() public view override returns (string memory) {
        return string(abi.encodePacked(ERC721.name(), " ", IERC721Metadata(nft).name()));

    }

    function symbol() public view override returns (string memory) {
        return string(abi.encodePacked(ERC721.symbol(), IERC721Metadata(nft).symbol()));
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory){
        return IERC721Metadata(nft).tokenURI(tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function mint(address user, uint256 tokenId) public override onlyOwner{
        _safeMint(user, tokenId);
        emit Mint(user, tokenId);
    }

    function burn(address user, address receiverOfUnderlying, uint256 tokenId) public override onlyOwner{
        _burn(tokenId);
        IERC721(nft).safeTransferFrom(address(this), receiverOfUnderlying, tokenId);
        emit Burn(user, receiverOfUnderlying, tokenId);
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

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "./interfaces/ICallToken.sol";
import "./interfaces/ICallPoolDeployer.sol";

struct CallInfo {
    uint256 exerciseTime;       // When can exercise
    uint256 endTime;            // When this call expire
    uint256 strikePrice;
}

contract CallToken is ERC721, IERC721Enumerable, ICallToken, Ownable {
    address public immutable override nft;

    mapping(uint256 => CallInfo) private callInfos;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    constructor() ERC721("CallToken", "CT") Ownable() {
        (, nft, , , ,) = ICallPoolDeployer(msg.sender).parameters();
    }

    function name() public view override returns (string memory) {
        return string(abi.encodePacked(ERC721.name(), " ", IERC721Metadata(nft).name()));

    }

    function symbol() public view override returns (string memory) {
        return string(abi.encodePacked(ERC721.symbol(), IERC721Metadata(nft).symbol()));
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory){
        return IERC721Metadata(nft).tokenURI(tokenId);
    }

    function ownerOf(uint256 tokenId) public view virtual override(IERC721, ERC721) returns(address){
        uint256 endTime = callInfos[tokenId].endTime;
        require(endTime > 0 && block.timestamp <= endTime, "token is expired");
        return ERC721.ownerOf(tokenId);
    }

    function balanceOf(address owner) public view virtual override(IERC721, ERC721) returns(uint256) {
        uint256 balance = 0;
        uint256 currentTime = block.timestamp;
        for(uint256 i = 0; i < _allTokens.length; ++i){
            uint256 tokenId = _allTokens[i];
            if(ERC721.ownerOf(tokenId) == owner && currentTime <= callInfos[tokenId].endTime){
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
        uint256 endTime = callInfos[tokenId].endTime;
        require(endTime > 0 && block.timestamp <= endTime, "token is expired");
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
        uint256 endTime = callInfos[tokenId].endTime;
        require(endTime > 0 && block.timestamp <= endTime, "token is expired");
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
        uint256 endTime = callInfos[tokenId].endTime;
        require(endTime > 0 && block.timestamp <= endTime, "token is expired");
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
            if(ERC721.ownerOf(tokenId) == owner && currentTime <= callInfos[tokenId].endTime){
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
            if(currentTime <= callInfos[tokenId].endTime){
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
            if(currentTime <= callInfos[tokenId].endTime){
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

    function mint(
        address user,
        uint256 tokenId
    ) external override onlyOwner {
        callInfos[tokenId] = CallInfo(0, 0, 0);
        _safeMint(user, tokenId);
        emit Mint(user, tokenId);
    }

    function burn(uint256 tokenId) external override onlyOwner {
        address owner = ERC721.ownerOf(tokenId);
        delete callInfos[tokenId];
        _burn(tokenId);
        emit Burn(owner, tokenId);
    }

    function open(
        address user,
        uint256 tokenId,
        uint256 strikePrice,
        uint256 duration,
        uint256 exercisePeriodProportion
    ) external override onlyOwner {
        require(callInfos[tokenId].endTime < block.timestamp);
        uint256 exercisePeriodEnd = block.timestamp + duration;
        uint256 exercisePeriodBegin = exercisePeriodEnd - duration * exercisePeriodProportion / 10000;
        callInfos[tokenId] = CallInfo(exercisePeriodBegin, exercisePeriodEnd, strikePrice);
        _transfer(ERC721.ownerOf(tokenId), user, tokenId);
        emit Open(user, tokenId, strikePrice, exercisePeriodBegin, exercisePeriodEnd);
    }

    function getCallInfo(uint256 tokenId) external view returns (CallInfo memory) {
        return callInfos[tokenId];
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.9;

// Import this file to use console.log
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "../interfaces/ICallPoolDeployer.sol";
import "../interfaces/ICallPool.sol";
import "../interfaces/IPriceOracle.sol";
import "../interfaces/IPremium.sol";
import "../CallToken.sol";
import "../NToken.sol";
import "../Errors.sol";

contract CallPoolForTest is ICallPool, Pausable {
    address public immutable override factory;
    address public immutable override nft;
    address public immutable override oracle;
    address public immutable override nToken;
    address public immutable override callToken;
    address public immutable override premium;

    uint16 public constant  exercisePeriodProportion = 5000;  // 5000 means the buyers can exercise at any time in the late 50% of option period
    uint256 public constant minimumPremiumToOwner = 1e18 / 1000;      // 0.001 ether
    uint256 public constant INVALID_PRICE = type(uint256).max;

    uint256 private constant PRECISION = 1e5;
    uint256 private constant RESERVE = 1e4; // 10%
    uint256[6] private STRIKE_PRICE_GAP = [0, 1e4, 2*1e4, 3*1e4, 5*1e4, 1e5]; // [0% 10% 20% 30% 50% 100%]
    uint256[4] private DURATION = [uint256(3 days) / 168, uint256(7 days) / 168, uint256(14 days) / 168, uint256(28 days) / 168];
    uint256 private constant MAX_PRICE_GAP_INDEX = 5;
    uint256 private constant MAX_DURATION_INDEX = 3;


    // Used to store nft availability and related call NFT. Here needs to consider data compression
    struct NFTStatus {
        bool ifOnMarket;            // If it can be listed on market, default TRUE. Only can be set up by NFT holder
        bool available;             // If it is available for opening a position. Only when callId=0 or the option with callId has expired
        uint8 lowerStrikePriceGapIdx;   // value 0-5. If 1, means the strike price gap must be >= 10%. Default 1.
        uint8 upperDurationIdx;         // value 0-3. If 3, means the duration preference is <= 28d. Default is 3.
        uint256 lowerLimitOfStrikePrice;
    }

    mapping(uint256 => NFTStatus) private nftStatus;

    uint256 private _reserveBalance;

    mapping(address => uint256) private _balanceOf;

    constructor() {
        (factory, nft, nToken, callToken, oracle, premium) = ICallPoolDeployer(_msgSender()).parameters();
    }

    modifier onlyFactoryOwner() {
        require(_msgSender() == Ownable(factory).owner(), Errors.CP_CALLER_IS_NOT_FACTORY_OWNER);
        _;
    }

    function balanceOf(address user) public view override returns (uint256){
        return _balanceOf[user];
    }

    function pause() external onlyFactoryOwner {
        _pause();
    }

    function unpause() external onlyFactoryOwner {
        _unpause();
    }

    function checkAvailable(uint256 tokenId) public view returns (bool) {
        if (nftStatus[tokenId].available) {
            return true;
        } else {
            uint256 endTime = CallToken(callToken).getCallInfo(tokenId).endTime;
            if (endTime > 0 && endTime < block.timestamp) {
                return true;
            } else {
                return false;
            }
        }
    }

    // Deposit NFT
    function deposit(address onBehalfOf, uint256 tokenId) external override whenNotPaused {
        _deposit(onBehalfOf, tokenId, 1, 3, 0);
    }

    function depositWithPreference(
        address onBehalfOf,
        uint256 tokenId,
        uint8 lowerStrikePriceGapIdx,
        uint8 upperDurationIdx,
        uint256 lowerLimitOfStrikePrice
    ) external override whenNotPaused {
        _deposit(onBehalfOf, tokenId, lowerStrikePriceGapIdx, upperDurationIdx, lowerLimitOfStrikePrice);
    }

    function _deposit(
        address onBehalfOf,
        uint256 tokenId,
        uint8 lowerStrikePriceGapIdx,
        uint8 upperDurationIdx,
        uint256 lowerLimitOfStrikePrice
    ) internal {
        require(lowerStrikePriceGapIdx <= MAX_PRICE_GAP_INDEX && upperDurationIdx <= MAX_DURATION_INDEX, Errors.CP_GAP_OR_DURATION_OUT_OF_INDEX);
        CallToken(callToken).mint(nToken, tokenId);
        nftStatus[tokenId] = NFTStatus(true, true, lowerStrikePriceGapIdx, upperDurationIdx, lowerLimitOfStrikePrice);
        NToken(nToken).mint(onBehalfOf, tokenId);
        ERC721(nft).transferFrom(_msgSender(), nToken, tokenId);

        emit Deposit(nft, _msgSender(), onBehalfOf, tokenId);
    }

    // Withdraw NFT
    function withdraw(address to, uint256 tokenId) external override whenNotPaused {
        // Check requirements: not commited to a call, etc.
        require(!nftStatus[tokenId].ifOnMarket || checkAvailable(tokenId), Errors.CP_NFT_ON_MARKET_OR_UNABAILABLE);
        // Burn NToken
        require(NToken(nToken).ownerOf(tokenId) == _msgSender(), Errors.CP_NOT_THE_OWNER);
        CallToken(callToken).burn(tokenId);
        delete nftStatus[tokenId];
        NToken(nToken).burn(_msgSender(), to, tokenId);

        emit Withdraw(nft, _msgSender(), to, tokenId);
    }

    /**
   * @dev transfer ETH to an address, revert if it fails.
   * @param to recipient of the transfer
   * @param value the amount to send
   */
    function _safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success);
    }

    function withdrawETH(
        address to,
        uint256 amount
    ) external override whenNotPaused returns(uint256) {
        require(amount != 0, Errors.CP_INVALID_AMOUNT);
        require(to != address(0), Errors.CP_INVALID_RECEIVER);
        uint256 userBalance = _balanceOf[_msgSender()];
        if(amount == type(uint256).max){
            amount = userBalance;
        }
        require(amount <= userBalance, Errors.CP_NOT_ENOUGH_BALANCE);
        address user = _msgSender();
        _balanceOf[user] = userBalance - amount;
        _safeTransferETH(to, amount);
        emit WithdrawETH(_msgSender(), to, amount);
        emit BalanceChangedETH(user, _balanceOf[user]);
        return amount;
    }

    function takeNFTOffMarket(uint256 tokenId) external override {
        require(NToken(nToken).ownerOf(tokenId) == _msgSender(), Errors.CP_NOT_THE_OWNER);
        nftStatus[tokenId].ifOnMarket = false;
        emit OffMarket(nft, _msgSender(), tokenId);
    }

    function relistNFT(uint256 tokenId) external override {
        require(NToken(nToken).ownerOf(tokenId) == _msgSender(), Errors.CP_NOT_THE_OWNER);
        nftStatus[tokenId].ifOnMarket = true;
        emit OnMarket(nft, _msgSender(), tokenId);
    }

    // Open a call position
    function openCall(
        uint256 tokenId,
        uint256 strikePriceGapIdx,
        uint256 durationIdx
    ) external payable override whenNotPaused {
        (
            uint256 strikePrice,
            uint256 premiumToOwner,
            uint256 premiumToReserve,
            uint256 errorCode
        ) = previewOpenCall(tokenId, strikePriceGapIdx, durationIdx);
        require(errorCode == 0, Errors.CP_CAN_NOT_OPEN_CALL);
        
        _openCallInteractions(tokenId, strikePrice, durationIdx);
        address owner = ERC721(nToken).ownerOf(tokenId);
        _balanceOf[owner] += premiumToOwner;
        emit BalanceChangedETH(owner, _balanceOf[owner]);
        address pool = address(this);
        _balanceOf[pool] += premiumToReserve;
        emit BalanceChangedETH(pool, _balanceOf[pool]);
        address user = _msgSender();
        uint256 totalPremium = premiumToOwner + premiumToReserve;
        if(msg.value != totalPremium){
            require(totalPremium <= _balanceOf[user] + msg.value, Errors.CP_DID_NOT_SEND_ENOUGHT_ETH);
            _balanceOf[user] = _balanceOf[user] + msg.value - totalPremium;
            emit BalanceChangedETH(user, _balanceOf[user]);
        }
        emit CallOpened(nft, _msgSender(), tokenId, strikePriceGapIdx, durationIdx);
        emit PremiumReceived(nft, owner, tokenId, premiumToOwner, premiumToReserve);
    }

    // Batch open position
    function openCallBatch(
        uint256[] calldata tokenIds,
        uint256[] calldata strikePriceGaps,
        uint256[] calldata durations
    ) external payable override whenNotPaused {
        require(tokenIds.length == strikePriceGaps.length && tokenIds.length == durations.length, Errors.CP_ARRAY_LENGTH_UNMATCHED);
        uint256 totalPremium = 0;
        uint256 totalReservePremium = 0;
        for(uint256 i = 0; i < tokenIds.length; ++i){
            (
                uint256 strikePrice,
                uint256 premiumToOwner,
                uint256 premiumToReserve,
                uint256 errorCode
            ) = previewOpenCall(tokenIds[i], strikePriceGaps[i], durations[i]);
            if(errorCode == 0){
                _openCallInteractions(tokenIds[i], strikePrice, durations[i]);
                totalReservePremium += premiumToReserve;
                totalPremium += premiumToOwner;
                address owner = ERC721(nToken).ownerOf(tokenIds[i]);
                emit CallOpened(nft, owner, tokenIds[i], strikePriceGaps[i], durations[i]);
                emit PremiumReceived(nft, owner, tokenIds[i], premiumToOwner, premiumToReserve);
                _balanceOf[owner] += premiumToOwner;
                emit BalanceChangedETH(owner, _balanceOf[owner]);
            }
        }
        totalPremium += totalReservePremium;
        address pool = address(this);
        _balanceOf[pool] += totalReservePremium;
        emit BalanceChangedETH(pool, _balanceOf[pool]);
        address user = _msgSender();
        if(msg.value != totalPremium){
            require(_balanceOf[user] + msg.value >= totalPremium, Errors.CP_DID_NOT_SEND_ENOUGHT_ETH);
            _balanceOf[user] = _balanceOf[user] + msg.value - totalPremium;
            emit BalanceChangedETH(user, _balanceOf[user]);
        }
    }

    function previewOpenCall(
        uint256 tokenId,
        uint256 strikePriceGapIdx,
        uint256 durationIdx
    ) public override view returns(
        uint256 strikePrice,
        uint256 premiumToOwner,
        uint256 premiumToReserve,
        uint256 errorCode
    ) {
        NFTStatus memory status = nftStatus[tokenId];
        strikePrice = INVALID_PRICE;
        premiumToOwner = INVALID_PRICE;
        premiumToReserve = INVALID_PRICE;
        if(_msgSender() == ERC721(nToken).ownerOf(tokenId)){
            errorCode = ErrorCodes.CP_CAN_NOT_OPEN_A_POSITION_ON_SELF_OWNED_NFT;
        }
        else if(!(status.ifOnMarket) || !(checkAvailable(tokenId))){
            errorCode = ErrorCodes.CP_NFT_ON_MARKET_OR_UNABAILABLE;
        }
        else if(strikePriceGapIdx < status.lowerStrikePriceGapIdx){
            errorCode = ErrorCodes.CP_STRIKE_GAP_TOO_LOW;
        } 
        else if(durationIdx > status.upperDurationIdx) {
            errorCode = ErrorCodes.CP_DURATION_TOO_LONG;
        }
        else {
            uint256 openPrice;
            (openPrice, premiumToReserve, premiumToOwner) = _calculatePremium(strikePriceGapIdx, durationIdx);
            if(premiumToOwner <= minimumPremiumToOwner){
                return(INVALID_PRICE, INVALID_PRICE, INVALID_PRICE, ErrorCodes.CP_TOO_LITTLE_PREMIUM_TO_OWNER);
            }
            strikePrice =  openPrice + openPrice * STRIKE_PRICE_GAP[strikePriceGapIdx] / PRECISION;
            if(strikePrice < status.lowerLimitOfStrikePrice){
                return (INVALID_PRICE, INVALID_PRICE, INVALID_PRICE, ErrorCodes.CP_STRIKE_PRICE_TOO_LOW);
            }
            errorCode = 0;
        }
    }

    function _openCallInteractions(uint256 tokenId, uint256 strikePrice, uint256 durationIdx) internal {
        NFTStatus memory status = nftStatus[tokenId];
        // Update underlying nft status
        nftStatus[tokenId] = NFTStatus(status.ifOnMarket, false, status.lowerStrikePriceGapIdx, status.upperDurationIdx, status.lowerLimitOfStrikePrice);
        CallToken(callToken).open(_msgSender(), tokenId, strikePrice, DURATION[durationIdx], exercisePeriodProportion);
    }

    // Exercise a call position
    function exerciseCall(uint256 tokenId) external payable override whenNotPaused {
        CallInfo memory ci = CallToken(callToken).getCallInfo(tokenId);
        require(ci.endTime >= block.timestamp && ci.exerciseTime <= block.timestamp, Errors.CP_NOT_IN_THE_EXERCISE_PERIOD);
        require(CallToken(callToken).ownerOf(tokenId) == _msgSender(), Errors.CP_NOT_THE_OWNER);
        require(ci.strikePrice == msg.value, Errors.CP_DID_NOT_SEND_ENOUGHT_ETH);
        // Burn CallToken
        CallToken(callToken).burn(tokenId);
        delete nftStatus[tokenId];
        // Burn NToken and transfer underlying NFT
        address originalOwner = NToken(nToken).ownerOf(tokenId);

        // Pay strike price to NToken owner
        _balanceOf[originalOwner] += ci.strikePrice;

        emit BalanceChangedETH(originalOwner, _balanceOf[originalOwner]);
        NToken(nToken).burn(originalOwner, _msgSender(), tokenId);
        
        emit CallClosed(nft, _msgSender(), originalOwner, tokenId, ci.strikePrice);
    }

    function collectProtocol(
        address recipient,
        uint256 amountRequested
    ) external override onlyFactoryOwner returns (uint256 amountSent){
        uint256 balance = _balanceOf[address(this)];
        amountSent = amountRequested > balance ? balance : amountRequested;
        if (amountSent > 0) {
            address pool = address(this);
            _balanceOf[pool] -= amountSent;
            emit BalanceChangedETH(pool, _balanceOf[pool]);
            _safeTransferETH(recipient, amountSent);
            emit CollectProtocol(_msgSender(), recipient, amountSent);
        }
    }

    function _calculatePremium(
        uint256 strikePriceGapIdx,
        uint256 durationIdx
    ) internal view returns(
        uint256 openPrice,
        uint256 premiumToReserve,
        uint256 premiumToOwner
    ){
        require(strikePriceGapIdx <= MAX_PRICE_GAP_INDEX && durationIdx <= MAX_DURATION_INDEX, Errors.CP_GAP_OR_DURATION_OUT_OF_INDEX);

        IPriceOracle _oracle = IPriceOracle(oracle);
        uint256 vol = _oracle.getAssetVol(nft);
        openPrice = _oracle.getAssetPrice(nft);

        IPremium _premium = IPremium(premium);
        uint256 currentPremium = _premium.getPremium(strikePriceGapIdx * 4 + durationIdx, vol);

        uint256 premiumTotal = openPrice * currentPremium / PRECISION;
        premiumToReserve = premiumTotal * RESERVE / PRECISION;
        premiumToOwner = premiumTotal - premiumToReserve;
    }

    function getNFTStatus(uint256 tokenId) external view override returns (bool, bool, uint8, uint8, uint256) {
        NFTStatus memory status = nftStatus[tokenId];
        return (
            status.ifOnMarket,
            status.available,
            status.lowerStrikePriceGapIdx,
            status.upperDurationIdx,
            status.lowerLimitOfStrikePrice
        );
    }

    function changePreference(
        uint256 tokenId,
        uint8 lowerStrikePriceGapIdx,
        uint8 upperDurationIdx,
        uint256 lowerLimitOfStrikePrice
    ) external override {
        require(lowerStrikePriceGapIdx <= MAX_PRICE_GAP_INDEX && upperDurationIdx <= MAX_DURATION_INDEX, Errors.CP_GAP_OR_DURATION_OUT_OF_INDEX);
        require(checkAvailable(tokenId), Errors.CP_NFT_ON_MARKET_OR_UNABAILABLE);
        require(NToken(nToken).ownerOf(tokenId) == _msgSender(), Errors.CP_NOT_THE_OWNER);
        nftStatus[tokenId] = NFTStatus(
            nftStatus[tokenId].ifOnMarket,
            nftStatus[tokenId].available,
            lowerStrikePriceGapIdx,
            upperDurationIdx,
            lowerLimitOfStrikePrice
        );
    }

    function totalOpenInterest() external view override returns(uint256) {
        return IERC721Enumerable(callToken).totalSupply();
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.9;

interface INToken {
    function nft() external view returns(address);

    event Mint(address indexed from, uint256 tokenId);

    function mint(address user, uint256 tokenId) external;

    event Burn(address indexed from, address indexed target, uint256 tokenId);

    function burn(address user, address receiverOfUnderlying, uint256 tokenId) external;
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.9;

interface ICallToken {
    function nft() external returns(address);

    event Mint(address indexed user, uint256 indexed tokenId);

    function mint(address user, uint256 tokenId) external;

    event Burn(address indexed user, uint256 indexed tokenId);

    function burn(uint256 tokenId) external;

    event Open(address indexed user, uint256 indexed tokenId, uint256 exercisePrice, uint256 exercisePeriodBegin, uint256 exercisePeriodEnd);

    function open(address user, uint256 tokenId, uint256 strikePrice, uint256 duration, uint256 exercisePeriodProportion) external;
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
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

library Errors {
    string public constant CP_CALLER_IS_NOT_FACTORY_OWNER = '1';
    string public constant CP_GAP_OR_DURATION_OUT_OF_INDEX = '2';
    string public constant CP_NFT_ON_MARKET_OR_UNABAILABLE = '3';
    string public constant CP_NOT_THE_OWNER = '4';

    string public constant CP_INVALID_AMOUNT = '5';
    string public constant CP_INVALID_RECEIVER = '6';
    string public constant CP_NOT_ENOUGH_BALANCE = '7';

    string public constant CP_CAN_NOT_OPEN_CALL = '8';
    string public constant CP_DID_NOT_SEND_ENOUGHT_ETH = '9';

    string public constant CP_ARRAY_LENGTH_UNMATCHED = '10';

    string public constant CP_NOT_IN_THE_EXERCISE_PERIOD = '11';

    string public constant CP_STRIKE_GAP_TOO_LOW = '12';
    string public constant CP_DURATION_TOO_LONG = '13';
    string public constant CP_STRIKE_PRICE_TOO_LOW = '14';

    string public constant CP_TOO_LITTLE_PREMIUM_TO_OWNER = '15';
    string public constant CP_PREMIUM_AND_ETH_UNEQUAL = '16';
    string public constant CP_CAN_NOT_OPEN_A_POSITION_ON_SELF_OWNED_NFT = '17';

}

library ErrorCodes {
    uint256 public constant CP_CALLER_IS_NOT_FACTORY_OWNER = 1;
    uint256 public constant CP_GAP_OR_DURATION_OUT_OF_INDEX = 2;
    uint256 public constant CP_NFT_ON_MARKET_OR_UNABAILABLE = 3;
    uint256 public constant CP_NOT_THE_OWNER = 4;

    uint256 public constant CP_INVALID_AMOUNT = 5;
    uint256 public constant CP_INVALID_RECEIVER = 6;
    uint256 public constant CP_NOT_ENOUGH_BALANCE = 7;

    uint256 public constant CP_CAN_NOT_OPEN_CALL = 8;
    uint256 public constant CP_DID_NOT_SEND_ENOUGHT_ETH = 9;

    uint256 public constant CP_ARRAY_LENGTH_UNMATCHED = 10;

    uint256 public constant CP_NOT_IN_THE_EXERCISE_PERIOD = 11;

    uint256 public constant CP_STRIKE_GAP_TOO_LOW = 12;
    uint256 public constant CP_DURATION_TOO_LONG = 13;
    uint256 public constant CP_STRIKE_PRICE_TOO_LOW = 14;

    uint256 public constant CP_TOO_LITTLE_PREMIUM_TO_OWNER = 15;
    uint256 public constant CP_PREMIUM_AND_ETH_UNEQUAL = 16;
    uint256 public constant CP_CAN_NOT_OPEN_A_POSITION_ON_SELF_OWNED_NFT = 17;

}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title Permissionless pool actions
/// @notice Contains pool methods that can be called by anyone
interface ICallPoolActions {
    // Deposit NFT
    function deposit(address onBehalfOf, uint256 tokenId) external;

    function depositWithPreference(address onBehalfOf, uint256 tokenId, uint8 lowerStrikePriceGapIdx, uint8 upperDurationIdx, uint256 lowerLimitOfStrikePrice) external;

    // Withdraw NFT
    function withdraw(address to, uint256 tokenId) external;

    function withdrawETH(address to, uint256 amount) external returns(uint256);

    // Open option
    function openCall(uint256 tokenId, uint256 strikePrice, uint256 duration) external payable;

    function openCallBatch(uint256[] memory tokenIds, uint256[] memory strikePrices, uint256[] memory durations) external payable;

    // Close option
    function exerciseCall(uint256 tokenId) external payable;

    function takeNFTOffMarket(uint256 tokenId) external;

    function relistNFT(uint256 tokenId) external;

    function changePreference(
        uint256 tokenId,
        uint8 lowerStrikePriceGapIdx,
        uint8 upperDurationIdx,
        uint256 lowerLimitOfStrikePrice
    ) external;
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
    event Deposit(address indexed nft, address user, address indexed onBehalfOf, uint256 indexed tokenId);
    event Withdraw(address indexed nft, address indexed user, address to, uint256 indexed tokenId);
    event CallOpened(address indexed nft, address indexed user, uint256 indexed tokenId, uint256 strikePriceGap, uint256 duration);
    event PremiumReceived(address indexed nft, address indexed owner, uint256 indexed tokenId, uint256 premiumToOwner, uint256 premiumToReserve);
    event CallClosed(address indexed nft, address indexed user, address owner, uint256 indexed tokenId, uint256 price);
    event OffMarket(address indexed nft, address indexed owner, uint256 indexed tokenId);
    event OnMarket(address indexed nft, address indexed owner, uint256 indexed tokenId);
    event DepositETH(address indexed user, address indexed receiver, uint256 amount);
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

/// @title Pool state that can change
/// @notice These methods compose the pool's state, and can change with any frequency including multiple times
/// per transaction
interface ICallPoolState {

    function balanceOf(address user) external view returns(uint256);

    // Get NFTStatus
    function getNFTStatus(uint256 tokenId) external view  returns (bool, bool, uint8, uint8, uint256);

    function previewOpenCall( uint256 tokenId, uint256 strikePriceGapIdx, uint256 durationIdx) external view 
        returns( uint256 strikePrice, uint256 premiumToOwner, uint256 premiumToReserve, uint256 errorCode );

    function totalOpenInterest() external view returns(uint256);
}