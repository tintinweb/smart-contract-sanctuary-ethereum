// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./StartMining721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Staking is ERC721Holder, Ownable, ReentrancyGuard {
    StartMining721 private nft;

    uint256 public nextPoolId;

    uint256 public stakingUnlock = 60; // 60 seconds

    bool public notPaused;

    struct Pool {
        uint256 firstTokenAllowed;
        uint256 limitPool;
        uint256 costElectricity;
        uint256 lifeTime;
        string typeMachine;
        string area;
        mapping(uint256 => ItemInfo) tokensPool;
        uint256[] ownedTokensPool;
    }

    struct ItemInfo {
        address owner;
        uint256 poolId;
        uint256 timestamp;
        string addressBTC;
    }

    struct Staker {
        mapping(uint256 => ItemInfo) tokensStaker;
        uint256[] ownedTokensStaker;
    }

    /// @notice mapping of a pool to an id.
    mapping(uint256 => Pool) public poolInfos;

    /// @notice mapping of a staker to its wallet.
    mapping(address => Staker) private stakers;

    /// @notice event emitted when a user has staked a nft.
    event Staked721(address owner, uint256 itemId, uint256 poolId);

    /// @notice event emitted when a user has unstaked a nft.
    event Unstaked721(address owner, uint256 itemId, uint256 poolId);

    /// @notice event emitted when the unlock period is updated.
    event UnlockPeriodUpdated(uint256 period);

    /// @notice event emitted when the informations in a pool has been updated.
    event PoolInformationsUpdated(
        uint256 poolId,
        uint256 firstTokenAllowed,
        uint256 limitPool,
        uint256 costElectricity,
        string area
    );

    /// @notice event emitted when a pool has been created.
    event PoolCreated(
        uint256 nextPoolId,
        uint256 firstTokenAllowed,
        uint256 limitPool,
        uint256 costElectricity,
        uint256 lifeTime,
        string typeMachine,
        string area
    );

    /**
     * @notice Constructor of the contract Staking.
     * @param _nft Address of the mint contract.
     */
    constructor(StartMining721 _nft) {
        nft = _nft;
        nextPoolId++;
        poolInfos[nextPoolId].firstTokenAllowed = 1;
        poolInfos[nextPoolId].limitPool = 200;
        poolInfos[nextPoolId].costElectricity = 50;
        poolInfos[nextPoolId].lifeTime = 1722079628;
        poolInfos[nextPoolId].typeMachine = "Infra";
        poolInfos[nextPoolId].area = "Bordeaux";
    }

    /**
     * @notice Enables only externally owned accounts (= users) to mint.
     */
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Caller is a contract");
        _;
    }

    /**
     * @notice Safety checks common to each stake function.
     * @param _poolId Id of the pool where to stake.
     * @param _addressBTC BTC address that will receive the rewards.
     */
    modifier stakeModifier(uint256 _poolId, string calldata _addressBTC) {
        require(notPaused, "Staking unavailable for the moment");
        require(_poolId > 0 && _poolId <= nextPoolId, "Pool doesn't exist");
        require(
            bytes(_addressBTC).length > 25 && bytes(_addressBTC).length < 36,
            "Wrong length address"
        );
        require(
            poolInfos[_poolId].ownedTokensPool.length <
                poolInfos[_poolId].limitPool,
            "Pool limit exceeded"
        );
        _;
    }

    /**
     * @notice Changes the variable notPaused to allow or not the staking.
     */
    function setPause() external onlyOwner {
        notPaused = !notPaused;
    }

    /**
     * @notice Changes the minimum period before it's possible to unstake.
     * @param _period New minimum period before being able to unstake.
     */
    function setUnlockPeriod(uint256 _period) external onlyOwner {
        stakingUnlock = _period;
        emit UnlockPeriodUpdated(stakingUnlock);
    }

    /**
     * @notice Change the Pool informations of an NFT.
     * @param _poolId Id of the pool.
     * @param _firstTokenAllowed First NFT accepted, only ids greater than or equal to this value will be accepted.
     * @param _limitPool Maximum amount of NFT stakable in the pool.
     * @param _costElectricity The average cost of electricity.
     * @param _area The area where the machine is located.
     **/
    function setPoolInformation(
        uint256 _poolId,
        uint256 _firstTokenAllowed,
        uint256 _limitPool,
        uint256 _costElectricity,
        string calldata _area
    ) external onlyOwner {
        require(_poolId > 0 && _poolId <= nextPoolId, "Pool doesn't exist");
        poolInfos[_poolId].firstTokenAllowed = _firstTokenAllowed;
        poolInfos[_poolId].limitPool = _limitPool;
        poolInfos[_poolId].costElectricity = _costElectricity;
        poolInfos[_poolId].area = _area;
        emit PoolInformationsUpdated(
            _poolId,
            _firstTokenAllowed,
            _limitPool,
            _costElectricity,
            _area
        );
    }

    /**
     * @notice Allows to create a new pool.
     * @param _firstTokenAllowed First NFT accepted, only ids greater than or equal to this value will be accepted.
     * @param _limitPool Maximum amount of NFT stakable in the pool.
     * @param _costElectricity The average cost of electricity.
     * @param _lifeTime The life time of the machine.
     * @param _typeMachine The type of machine.
     * @param _area The area where the machine is located.
     */
    function createPool(
        uint256 _firstTokenAllowed,
        uint256 _limitPool,
        uint256 _costElectricity,
        uint256 _lifeTime,
        string calldata _typeMachine,
        string calldata _area
    ) external onlyOwner {
        nextPoolId++;
        poolInfos[nextPoolId].firstTokenAllowed = _firstTokenAllowed;
        poolInfos[nextPoolId].limitPool = _limitPool;
        poolInfos[nextPoolId].costElectricity = _costElectricity;
        poolInfos[nextPoolId].lifeTime = _lifeTime;
        poolInfos[nextPoolId].typeMachine = _typeMachine;
        poolInfos[nextPoolId].area = _area;
        emit PoolCreated(
            nextPoolId,
            _firstTokenAllowed,
            _limitPool,
            _costElectricity,
            _lifeTime,
            _typeMachine,
            _area
        );
    }

    /**
     * @notice Private function used in stakeERC721.
     * @param _poolId Id of the pool where to stake.
     * @param _tokenId Id of the token to stake.
     * @param _addressBTC BTC address that will receive the rewards.
     */
    function _stakeERC721(
        uint256 _poolId,
        uint256 _tokenId,
        string calldata _addressBTC
    ) private nonReentrant {
        require(
            _tokenId >= poolInfos[_poolId].firstTokenAllowed,
            "NFT can't be staked in this pool"
        );
        require(nft.ownerOf(_tokenId) == msg.sender, "Not owner");
        nft.safeTransferFrom(msg.sender, address(this), _tokenId);
        Staker storage staker = stakers[msg.sender];
        Pool storage pool = poolInfos[_poolId];
        ItemInfo memory info = ItemInfo(
            msg.sender,
            _poolId,
            block.timestamp,
            _addressBTC
        );
        staker.tokensStaker[_tokenId] = info;
        staker.ownedTokensStaker.push(_tokenId);
        pool.tokensPool[_tokenId] = info;
        pool.ownedTokensPool.push(_tokenId);
        emit Staked721(msg.sender, _tokenId, _poolId);
    }

    /**
     * @notice Allows to stake an NFT in the desired quantity.
     * @param _poolId Id of the pool where to stake.
     * @param _tokenId Id of the token to stake.
     * @param _addressBTC BTC address that will receive the rewards.
     */
    function stakeERC721(
        uint256 _poolId,
        uint256 _tokenId,
        string calldata _addressBTC
    ) external callerIsUser stakeModifier(_poolId, _addressBTC) {
        _stakeERC721(_poolId, _tokenId, _addressBTC);
    }

    /**
     * @notice Allows to stake several NFT in the desired quantity.
     * @param _poolId Id of the pool where to stake.
     * @param _tokenIds Ids of the tokens to stake.
     * @param _addressBTC BTC address that will receive the rewards.
     */
    function batchStakeERC721(
        uint8 _poolId,
        uint256[] memory _tokenIds,
        string calldata _addressBTC
    ) external callerIsUser stakeModifier(_poolId, _addressBTC) {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            _stakeERC721(_poolId, _tokenIds[i], _addressBTC);
        }
    }

    /**
     * @notice Private function used in unstakeERC721.
     * @param _tokenId Id of the token to unstake.
     */
    function _unstakeERC721(uint256 _tokenId) private nonReentrant {
        require(
            stakers[msg.sender].tokensStaker[_tokenId].timestamp != 0,
            "No NFT staked"
        );
        uint256 elapsedTime = block.timestamp -
            stakers[msg.sender].tokensStaker[_tokenId].timestamp;
        require(
            stakingUnlock < elapsedTime,
            "Unable to unstake before the minimum period"
        );
        Staker storage staker = stakers[msg.sender];
        uint256 poolId = staker.tokensStaker[_tokenId].poolId;
        Pool storage pool = poolInfos[poolId];

        delete staker.tokensStaker[_tokenId];
        delete pool.tokensPool[_tokenId];

        for (uint256 i = 0; i < staker.ownedTokensStaker.length; i++) {
            if (staker.ownedTokensStaker[i] == _tokenId) {
                staker.ownedTokensStaker[i] = staker.ownedTokensStaker[
                    staker.ownedTokensStaker.length - 1
                ];
                staker.ownedTokensStaker.pop();
                break;
            }
        }

        for (uint256 i = 0; i < pool.ownedTokensPool.length; i++) {
            if (pool.ownedTokensPool[i] == _tokenId) {
                pool.ownedTokensPool[i] = pool.ownedTokensPool[
                    pool.ownedTokensPool.length - 1
                ];
                pool.ownedTokensPool.pop();
                break;
            }
        }

        nft.safeTransferFrom(address(this), msg.sender, _tokenId);
        emit Unstaked721(msg.sender, _tokenId, poolId);
    }

    /**
     * @notice Allows you to unstake an NFT staked.
     * @param _tokenId Id of the token to unstake.
     */
    function unstakeERC721(uint256 _tokenId) external callerIsUser {
        _unstakeERC721(_tokenId);
    }

    /**
     * @notice Allows you to unstake several NFT staked.
     * @param _tokenIds Ids of the token to unstake.
     */
    function batchUnstakeERC721(uint256[] memory _tokenIds)
        external
        callerIsUser
    {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            _unstakeERC721(_tokenIds[i]);
        }
    }

    /**
     * @notice Returns the ItemInfo of a specific NFT staked by a user.
     * @param _user Address of the user.
     * @param _tokenId Id of the token.
     * @return ItemInfo Details of tokenId.
     */
    function getStakedERC721(address _user, uint256 _tokenId)
        external
        view
        returns (ItemInfo memory)
    {
        return stakers[_user].tokensStaker[_tokenId];
    }

    /**
     * @notice Returns the list of NFT staked by a user.
     * @param _user Address of the user.
     * @return uint256[] List of tokenIds.
     */
    function getAllStakedERC721(address _user)
        external
        view
        returns (uint256[] memory)
    {
        return stakers[_user].ownedTokensStaker;
    }

    /**
     * @notice Returns the ItemInfo of a specific NFT staked in a pool.
     * @param _poolId Id of the pool.
     * @param _tokenId Id of the token.
     * @return ItemInfo Details of tokenId.
     */
    function getStakedERC721Pool(uint256 _poolId, uint256 _tokenId)
        external
        view
        returns (ItemInfo memory)
    {
        return poolInfos[_poolId].tokensPool[_tokenId];
    }

    /**
     * @notice Returns the list of NFT staked in a pool.
     * @param _poolId Id of the pool.
     * @return uint256[] List of tokenIds.
     */
    function getAllStakedERC721Pool(uint256 _poolId)
        external
        view
        returns (uint256[] memory)
    {
        return poolInfos[_poolId].ownedTokensPool;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/// @title StartMining NFTs Collection
/// @author cd33
contract StartMining721 is ERC721, Ownable, ReentrancyGuard {
    using Strings for uint256;

    using SafeERC20 for IERC20;
    IERC20 private usdt;
    // IERC20 private usdt = IERC20(0x55d398326f99059fF775485246999027B3197955); // USDT sur la BSC
    address private constant recipient =
        // 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266; // TESTS: WALLET OWNER
        0xD9453F5E2696604703076835496F81c3753C3Bb3; // TESTS: MON SECOND WALLET
    AggregatorV3Interface internal priceFeed =
        AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e); // Chainlink Rinkeby ETH/USD
    // AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e); // Chainlink Goerli ETH/USD
    // AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419); // Chainlink Mainnet ETH/USD

    struct Referrer {
        uint256 referredCount;
        uint256 alreadyClaimed;
    }

    bool public notPaused;

    uint16 public salePrice = 1; // 1$ USD
    uint256 public nextNFT;
    uint256 public limitNFT = 500;

    string public baseURI;

    mapping(address => Referrer) public referrer;

    /// @notice event emitted when the sale price updated.
    event PriceUpdated(uint16 salePrice);

    /// @notice event emitted when a new mint season of NFT is ready to be minted.
    event InitializedMint(uint256 _tokenId, uint256 limit, uint16 salePrice);

    /**
     * @notice Constructor of the contract ERC721.
     * @param _baseURI Metadatas for the ERC721.
     */
    constructor(string memory _baseURI, IERC20 _usdt)
        ERC721("Start Mining", "SMI")
    {
        // TESTS: IERC20 usdt à supprimer
        baseURI = _baseURI;
        usdt = _usdt;
    }

    /**
     * @notice Enables only externally owned accounts (= users) to mint.
     */
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Caller is a contract");
        _;
    }

    /**
     * @notice Safety checks common to each mint function.
     * @param _amount Amount of tokens to mint.
     * @param _referral Adress of the referral.
     */
    modifier mintModifier(uint16 _amount, address _referral) {
        _mintCheck(_amount, _referral);
        _;
    }

    /**
     * @notice Private function of safety checks to save gas.
     * @param _amount Amount of tokens to mint.
     * @param _referral Adress of the referral.
     */
    function _mintCheck(uint16 _amount, address _referral) private view {
        require(_amount > 0, "Amount min 1");
        require(_referral != msg.sender, "Not allowed to self-referral");
    }

    /**
     * @notice Requires approve from msg.sender to this contract upstream.
     * @param _tokenamount Dollar amount sent from msg.sender to recipient.
     */
    function _acceptPayment(uint256 _tokenamount) private {
        usdt.safeTransferFrom(msg.sender, recipient, _tokenamount);
    }

    /**
     * @notice Allows access to off-chain metadatas.
     * @param _tokenId Id of the token.
     * @return string Token's metadatas URI.
     */
    function tokenURI(uint256 _tokenId)
        external
        view
        virtual
        override
        returns (string memory)
    {
        require(_tokenId > 0 && _tokenId <= limitNFT, "NFT doesn't exist");
        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(baseURI, _tokenId.toString(), ".json")
                )
                : "";
    }

    /**
     * @notice Get the current ETH/USD price.
     * @dev The function uses the chainlink aggregator.
     * @return int Price value.
     */
    function getLatestPrice() public view returns (int256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return price;
    }

    /**
     * @notice Changes the variable notPaused to allow or not the sale.
     */
    function setPause() external onlyOwner {
        notPaused = !notPaused;
    }

    /**
     * @notice Change the salePrice.
     * @param _newPrice New sale price.
     **/
    function setSalePrice(uint16 _newPrice) external onlyOwner {
        salePrice = _newPrice;
        emit PriceUpdated(salePrice);
    }

    /**
     * @notice Change the base URI.
     * @param _newBaseURI New base URI.
     **/
    function setBaseUri(string calldata _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    /**
     * @notice Initialize a new mint season of NFT ready to be minted.
     * @param _nextNFT Id of the first token minus 1.
     * @param _limit Maximum amount of units.
     * @param _salePrice Price value of NFT.
     **/
    function initMint(
        uint256 _nextNFT,
        uint256 _limit,
        uint16 _salePrice
    ) external onlyOwner {
        require(
            _nextNFT >= nextNFT,
            "New nextNFT must be higher than the old one"
        );
        require(_limit > _nextNFT, "Limit must be higher than the new nextNFT");
        require(_salePrice > 0, "Price can't be zero");
        nextNFT = _nextNFT;
        limitNFT = _limit;
        salePrice = _salePrice;
        emit InitializedMint(_nextNFT, _limit, _salePrice);
    }

    // MINTS
    /**
     * @notice Private function to mint during the sale.
     * @param _to Address that will receive the NFT.
     * @param _referral Adress of the referral.
     */
    function _mintSale(address _to, address _referral) private nonReentrant {
        require(notPaused, "Sale unavailable for the moment");
        require(nextNFT < limitNFT, "Sold out");
        if (_referral != address(0)) {
            referrer[_referral].referredCount++;
        }
        nextNFT++;
        _mint(_to, nextNFT);
    }

    /**
     * @notice Mint in ETH during the sale.
     * @param _amount Amount of tokens to mint.
     * @param _referral Adress of the referral.
     */
    function mintSale(uint16 _amount, address _referral)
        external
        payable
        callerIsUser
        mintModifier(_amount, _referral)
    {
        require(
            msg.value >=
                (uint256(_amount) * salePrice * 10**26) /
                    uint256(getLatestPrice()),
            "Not enough funds"
        );
        payable(recipient).transfer(address(this).balance);
        for (uint16 i = 0; i < _amount; i++) {
            _mintSale(msg.sender, _referral);
        }
    }

    /**
     * @notice Mint in USDT during the sale.
     * @param _amount Amount of tokens to mint.
     * @param _referral Adress of the referral.
     */
    function mintSaleUSDT(uint16 _amount, address _referral)
        external
        callerIsUser
        mintModifier(_amount, _referral)
    {
        _acceptPayment(uint256(_amount) * salePrice * 10**18);
        for (uint16 i = 0; i < _amount; i++) {
            _mintSale(msg.sender, _referral);
        }
    }

    /**
     * @notice Crossmint allows payment by credit card.
     * @param _to Address that will receive the NFT.
     * @param _amount Amount of tokens to mint.
     * @param _referral Adress of the referral.
     */
    function crossmintSale(
        address _to,
        uint16 _amount,
        address _referral
    ) external payable mintModifier(_amount, _referral) {
        require(
            msg.sender == 0xdAb1a1854214684acE522439684a145E62505233,
            "This function is for Crossmint only."
        );
        require(
            msg.value >=
                (uint256(_amount) * salePrice * 10**26) /
                    uint256(getLatestPrice()),
            "Not enough funds"
        );

        payable(recipient).transfer(address(this).balance);
        for (uint16 i = 0; i < _amount; i++) {
            _mintSale(_to, _referral);
        }
    }

    /**
     * @notice Allows to claim rewards.
     */
    function claimReward() external callerIsUser {
        uint256 countReferral = referrer[msg.sender].referredCount;
        require(countReferral >= 100, "Not enough referral yet");
        uint256 amountNFTClaimable;
        if (countReferral < 1000)
            amountNFTClaimable =
                (1 + (countReferral - 100) / 34) -
                referrer[msg.sender].alreadyClaimed;
        else
            amountNFTClaimable =
                (28 + (countReferral - 1000) / 20) -
                referrer[msg.sender].alreadyClaimed;
        require(amountNFTClaimable > 0, "No rewards available");
        referrer[msg.sender].alreadyClaimed += amountNFTClaimable;
        for (uint16 i = 0; i < amountNFTClaimable; i++) {
            _mintSale(msg.sender, address(0));
        }
    }

    /**
     * @notice Allows the owner to offer NFTs.
     * @param _to Receiving address.
     * @param _amount Amount of tokens to mint.
     */
    function gift(address _to, uint16 _amount) external onlyOwner {
        require(_amount > 0, "Amount min 1");
        for (uint16 i = 0; i < _amount; i++) {
            _mintSale(_to, address(0));
        }
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) external view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) internal _ownerOf;

    mapping(address => uint256) internal _balanceOf;

    function ownerOf(uint256 id) external view virtual returns (address owner) {
        require((owner = _ownerOf[id]) != address(0), "NOT_MINTED");
    }

    function balanceOf(address owner) external view virtual returns (uint256) {
        require(owner != address(0), "ZERO_ADDRESS");

        return _balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) external virtual {
        address owner = _ownerOf[id];

        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) external virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        require(from == _ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[id],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[from]--;

            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) external virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) external virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) external view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(_ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
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

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
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