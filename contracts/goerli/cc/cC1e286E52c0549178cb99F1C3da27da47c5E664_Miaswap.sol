// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./MiaLiquidityProviderToken.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

error Miaswap__AllFeesMustBeLessThan10Percent();
error Miaswap__PoolExists(address lpToken);
error Miaswap__MustSendEth();
error Miaswap__NotTokenOwner();
error Miaswap__FailedToSendEth();
error Miaswap__SendExactEth(uint256 exactEthAmount);
error Miaswap__TokenIdsLengthMustDifferentTokenScoresLength(); // CHECK
error Miaswap__InsufficientLiquidityBalance(uint64 maximumScoreWithdrawal);
error Miaswap__NotCreator();
error Miaswap__InsufficientBalance(uint256 creatorBalance);
error Miaswap__NotServiceFeeRecipient(address serviceFeeRecipient);
error Miaswap__MustBeDifferentZeroAddress();

contract Miaswap is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    /**********************
     * Style declarations *
     **********************/
    struct PoolInfo {
        address payable lpToken;
        address creator;
        uint16 creatorFee;
        uint16 liquidityProviderFee;
        uint64 totalScore;
        uint256 totalEth;
    }

    /*******************
     * State variables *
     *******************/
    uint16 private constant FEE_DENOMINATOR = 10000; // minimum fee is 0.01%
    uint16 private s_serviceFee;
    address private s_serviceFeeRecipient;

    // collection address => Pool Info
    mapping(address => PoolInfo) private s_poolInfos;

    // collection address => (token ID => score)
    mapping(address => mapping(uint256 => uint64)) private s_tokenScores;

    /**********
     * Events *
     **********/
    event PoolCreated(
        address indexed collection,
        address payable indexed lpToken,
        address indexed creator,
        uint256 creatorFee,
        uint256 liquidityProviderFee,
        uint64 totalScore,
        uint256 totalEth
    );

    event PoolDeposited(
        address indexed collection,
        address liquidityProvider,
        uint256 ethSent,
        uint256[] tokenIds
    );

    event NftsSwappedByEth(address indexed collection, uint256 ethSent, uint256[] tokenIds);

    event EthSwappedByNfts(address indexed collection, uint256 ethReceived, uint256[] tokenIds);

    event PoolWithdrawn(
        address indexed collection,
        address liquidityProvider,
        uint256 ethReceived,
        uint256[] tokenIds
    );

    /*************
     * Modifiers *
     *************/
    modifier onlyServiceFeeRecipient() {
        if (msg.sender != s_serviceFeeRecipient) {
            revert Miaswap__NotServiceFeeRecipient(s_serviceFeeRecipient);
        }
        _;
    }

    /******************
     * Main functions *
     ******************/
    constructor(uint16 serviceFee, address serviceFeeRecipient) {
        if (serviceFee >= FEE_DENOMINATOR / 10) {
            revert Miaswap__AllFeesMustBeLessThan10Percent();
        }
        if (serviceFeeRecipient == address(0)) {
            revert Miaswap__MustBeDifferentZeroAddress();
        }
        s_serviceFee = serviceFee;
        s_serviceFeeRecipient = serviceFeeRecipient;
    }

    /**
     * @notice Only owner can set new service fee
     * @param serviceFee new service fee
     */

    function setServiceFee(uint16 serviceFee) external onlyOwner {
        if (serviceFee >= FEE_DENOMINATOR / 10) {
            revert Miaswap__AllFeesMustBeLessThan10Percent();
        }
        s_serviceFee = serviceFee;
    }

    /**
     * @notice Only an existing service fee account can set up a new service fee account
     * @param serviceFeeRecipient The new service fee account
     */
    function setServiceFeeRecipient(address serviceFeeRecipient) external onlyServiceFeeRecipient {
        if (serviceFeeRecipient == address(0)) {
            revert Miaswap__MustBeDifferentZeroAddress();
        }
        s_serviceFeeRecipient = serviceFeeRecipient;
    }

    /**
     * @notice Creates NFT pool and LP token
     * @param collection Address of the NFT collection
     * @param tokenId The id of the NFT token
     * @param creatorFee Creator royalties per transaction
     * @param liquidityProviderFee Liquidity provider bonus per transaction
     */
    function createPool(
        address collection,
        uint256 tokenId,
        uint16 creatorFee,
        uint16 liquidityProviderFee
    ) external payable nonReentrant {
        if (creatorFee >= FEE_DENOMINATOR / 10 || liquidityProviderFee >= FEE_DENOMINATOR / 10) {
            revert Miaswap__AllFeesMustBeLessThan10Percent();
        }
        address payable lpToken = s_poolInfos[collection].lpToken;
        if (lpToken != address(0)) {
            revert Miaswap__PoolExists(lpToken);
        }
        uint256 value = msg.value;
        if (value == 0) {
            revert Miaswap__MustSendEth();
        }
        address tokenOwner = IERC721(collection).ownerOf(tokenId);
        address sender = msg.sender;
        if (tokenOwner != sender) {
            revert Miaswap__NotTokenOwner();
        }
        lpToken = payable(address(new MiaLiquidityProviderToken(collection)));
        IERC721(collection).transferFrom(sender, lpToken, tokenId);
        uint64 tokenScore = generateScore(tokenId); // CHECK
        s_tokenScores[collection][tokenId] = tokenScore; // CHECK
        MiaLiquidityProviderToken(lpToken).mint(sender, tokenScore);
        (bool sent, ) = lpToken.call{value: value}("");
        if (!sent) {
            revert Miaswap__FailedToSendEth();
        }
        s_tokenScores[collection][tokenId] = tokenScore;
        s_poolInfos[collection] = PoolInfo(
            lpToken,
            sender,
            creatorFee,
            liquidityProviderFee,
            tokenScore,
            value
        );
        emit PoolCreated(
            collection,
            lpToken,
            sender,
            creatorFee,
            liquidityProviderFee,
            tokenScore,
            value
        );
    }

    /**
     * @notice Deposits ETH and NFTs, then get LP tokens
     * @param collection Address of the NFT collection
     * @param tokenIds List of NFT token Ids
     */
    function deposit(address collection, uint256[] memory tokenIds) external payable nonReentrant {
        uint64 scoresToDeposit = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (s_tokenScores[collection][tokenIds[i]] != 0) {
                scoresToDeposit += s_tokenScores[collection][tokenIds[i]];
            } else {
                uint64 tokenScore = generateScore(tokenIds[i]);
                s_tokenScores[collection][tokenIds[i]] = tokenScore;
                scoresToDeposit += tokenScore;
            }
        }
        PoolInfo memory poolInfo = s_poolInfos[collection];
        uint256 equivalentEthAmount = poolInfo.totalEth.mul(uint256(scoresToDeposit)).div(
            uint256(poolInfo.totalScore)
        );
        uint256 value = msg.value;
        if (value != equivalentEthAmount) {
            revert Miaswap__SendExactEth(equivalentEthAmount);
        }
        (bool sent, ) = poolInfo.lpToken.call{value: value}("");
        if (!sent) {
            revert Miaswap__FailedToSendEth();
        }
        address sender = msg.sender;
        IERC721 collectionContract = IERC721(collection);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            collectionContract.transferFrom(sender, poolInfo.lpToken, tokenIds[i]);
        }
        MiaLiquidityProviderToken(poolInfo.lpToken).mint(sender, scoresToDeposit);
        poolInfo.totalEth += value;
        poolInfo.totalScore += scoresToDeposit;
        s_poolInfos[collection].totalEth = poolInfo.totalEth;
        s_poolInfos[collection].totalScore = poolInfo.totalScore;
        emit PoolDeposited(collection, sender, value, tokenIds);
    }

    /**
     * @notice Swaps ETH to gets NFTs
     * @param collection Address of the NFT collection
     * @param tokenIds List of NFT token Ids
     */
    function swapEthToNfts(address collection, uint256[] memory tokenIds)
        external
        payable
        nonReentrant
    {
        uint64 scoresToSwap = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            scoresToSwap += s_tokenScores[collection][tokenIds[i]];
        }
        PoolInfo memory poolInfo = s_poolInfos[collection];
        uint256 equivalentEthAmount = poolInfo.totalEth.mul(uint256(scoresToSwap)).div(
            uint256(poolInfo.totalScore)
        );
        uint256 serviceFee = equivalentEthAmount.mul(s_serviceFee).div(FEE_DENOMINATOR);
        uint256 creatorFee = equivalentEthAmount.mul(poolInfo.creatorFee).div(FEE_DENOMINATOR);
        uint256 liquidityProviderFee = equivalentEthAmount.mul(poolInfo.liquidityProviderFee).div(
            FEE_DENOMINATOR
        );
        uint256 actualEthAmount = equivalentEthAmount +
            serviceFee +
            creatorFee +
            liquidityProviderFee;
        uint256 value = msg.value;
        if (value != actualEthAmount) {
            revert Miaswap__SendExactEth(actualEthAmount);
        }
        (bool sent, ) = poolInfo.lpToken.call{
            value: equivalentEthAmount + creatorFee + liquidityProviderFee
        }("");
        if (!sent) {
            revert Miaswap__FailedToSendEth();
        }
        address sender = msg.sender;
        MiaLiquidityProviderToken(poolInfo.lpToken).transferNfts(sender, tokenIds);
        poolInfo.totalEth += equivalentEthAmount + liquidityProviderFee;
        poolInfo.totalScore -= scoresToSwap;
        s_poolInfos[collection].totalEth = poolInfo.totalEth;
        s_poolInfos[collection].totalScore = poolInfo.totalScore;
        emit NftsSwappedByEth(collection, value, tokenIds);
    }

    /**
     * @notice Swaps NFTs to gets ETH
     * @param collection Address of the NFT collection
     * @param tokenIds List of NFT token Ids
     */
    function swapNftsToEth(address collection, uint256[] memory tokenIds) external nonReentrant {
        uint64 scoresToSwap = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (s_tokenScores[collection][tokenIds[i]] != 0) {
                scoresToSwap += s_tokenScores[collection][tokenIds[i]];
            } else {
                uint64 tokenScore = generateScore(tokenIds[i]);
                s_tokenScores[collection][tokenIds[i]] = tokenScore;
                scoresToSwap += tokenScore;
            }
        }
        PoolInfo memory poolInfo = s_poolInfos[collection];
        uint256 equivalentEthAmount = poolInfo.totalEth.mul(uint256(scoresToSwap)).div(
            uint256(poolInfo.totalScore)
        );
        uint256 serviceFee = equivalentEthAmount.mul(s_serviceFee).div(FEE_DENOMINATOR);
        uint256 creatorFee = equivalentEthAmount.mul(poolInfo.creatorFee).div(FEE_DENOMINATOR);
        uint256 liquidityProviderFee = equivalentEthAmount.mul(poolInfo.liquidityProviderFee).div(
            FEE_DENOMINATOR
        );
        uint256 actualEthAmount = equivalentEthAmount -
            serviceFee -
            creatorFee -
            liquidityProviderFee;
        address sender = msg.sender;
        IERC721 collectionContract = IERC721(collection);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            collectionContract.transferFrom(sender, poolInfo.lpToken, tokenIds[i]);
        }
        MiaLiquidityProviderToken miaLiquidityProviderToken = MiaLiquidityProviderToken(
            poolInfo.lpToken
        );
        miaLiquidityProviderToken.transferEth(address(this), serviceFee);
        miaLiquidityProviderToken.transferEth(sender, actualEthAmount);
        poolInfo.totalEth -= actualEthAmount + serviceFee + creatorFee;
        poolInfo.totalScore -= scoresToSwap;
        s_poolInfos[collection].totalEth = poolInfo.totalEth;
        s_poolInfos[collection].totalScore = poolInfo.totalScore;
        emit EthSwappedByNfts(collection, actualEthAmount, tokenIds);
    }

    /**
     * @notice The Liquidity Provider withdraws eth and nfts from the pool
     * @param collection Address of the NFT collection
     * @param tokenIds List of NFT token Ids
     */
    function withdraw(address collection, uint256[] memory tokenIds) external nonReentrant {
        PoolInfo memory poolInfo = s_poolInfos[collection];
        uint64 scoresToWithdraw = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            scoresToWithdraw += s_tokenScores[collection][tokenIds[i]];
        }
        MiaLiquidityProviderToken miaLiquidityProviderToken = MiaLiquidityProviderToken(
            poolInfo.lpToken
        );
        address sender = msg.sender;
        uint64 maximumScoreWithdrawal = uint64(miaLiquidityProviderToken.balanceOf(sender));
        if (scoresToWithdraw > maximumScoreWithdrawal) {
            revert Miaswap__InsufficientLiquidityBalance(maximumScoreWithdrawal);
        }
        uint256 equivalentEthAmount = poolInfo.totalEth.mul(uint256(scoresToWithdraw)).div(
            uint256(poolInfo.totalScore)
        );
        miaLiquidityProviderToken.transferEth(sender, equivalentEthAmount);
        miaLiquidityProviderToken.transferNfts(sender, tokenIds);
        miaLiquidityProviderToken.burnFrom(sender, uint256(scoresToWithdraw));
        poolInfo.totalEth -= equivalentEthAmount;
        poolInfo.totalScore -= scoresToWithdraw;
        s_poolInfos[collection].totalEth = poolInfo.totalEth;
        s_poolInfos[collection].totalScore = poolInfo.totalScore;
        emit PoolWithdrawn(collection, sender, equivalentEthAmount, tokenIds);
    }

    /**
     * @notice Only the pool creator can withdraw the creator fee
     * @param collection Address of the NFT collection
     * @param amount Amount of ETH to withdraw
     */
    function withdrawCreatorBalance(address collection, uint256 amount) external nonReentrant {
        address sender = msg.sender;
        PoolInfo memory poolInfo = s_poolInfos[collection];
        if (sender != poolInfo.creator) {
            revert Miaswap__NotCreator();
        }
        uint256 creatorBalance = poolInfo.lpToken.balance - poolInfo.totalEth;
        if (amount > creatorBalance) {
            revert Miaswap__InsufficientBalance(creatorBalance);
        }
        MiaLiquidityProviderToken(poolInfo.lpToken).transferEth(sender, amount);
    }

    /**
     * @notice Only miaswap owner can withdraw the service fee
     * @param amount The amount of ETH to withdraw
     */
    function withdrawServiceFee(uint256 amount) external onlyServiceFeeRecipient {
        uint256 balance = address(this).balance;
        if (amount > balance) {
            revert Miaswap__InsufficientBalance(balance);
        }
        (bool sent, ) = msg.sender.call{value: amount}("");
        if (!sent) {
            revert Miaswap__FailedToSendEth();
        }
    }

    /********************
     * Getter functions *
     ********************/
    /**
     * @notice Gets the fee denominator of the contract
     */
    function getFeeDenominator() external pure returns (uint16) {
        return FEE_DENOMINATOR;
    }

    /**
     * @notice Gets the service fee of the contract
     */
    function getServiceFee() external view returns (uint16) {
        return s_serviceFee;
    }

    /**
     * @notice Gets the address of the service fee receipient
     */
    function getServiceFeeRecipient() external view returns (address) {
        return s_serviceFeeRecipient;
    }

    /**
     * @notice Gets the info of the pool includes nfts of the collection
     * @param collection Address of the NFT collection
     */
    function getPoolInfo(address collection) external view returns (PoolInfo memory) {
        return s_poolInfos[collection];
    }

    /**
     * @notice Gets the score of the NFT
     * @param collection Address of the NFT collection
     * @param tokenId The id of the NFT
     */
    function getTokenScore(address collection, uint256 tokenId) external view returns (uint64) {
        return s_tokenScores[collection][tokenId];
    }

    // CHECK
    /**
     * @notice Generates random score by the token Id
     * @notice Uses if oracle is not available
     * @param tokenId The id of the NFT
     */
    function generateScore(uint256 tokenId) internal pure returns (uint64) {
        if (tokenId == 0) {
            return 1;
        }
        uint256 number = uint256(keccak256("Random Score By Le Quan")) / tokenId / tokenId;
        uint256 module = number % 10;
        if (module == 0) {
            return 1;
        } else if (module == 1) {
            return uint64(number % 100);
        } else if (module == 2) {
            return uint64(number % 1000);
        } else if (module == 3) {
            return uint64(number % 10000);
        } else if (module == 4) {
            return uint64(number % 20000);
        } else if (module == 5) {
            return uint64(number % 30000);
        } else if (module == 6) {
            return uint64(number % 40000);
        } else if (module == 7) {
            return uint64(number % 60000);
        } else if (module == 8) {
            return uint64(number % 80000);
        } else {
            return uint64(number % 100000);
        }
    }

    /**
     * @notice Calculates the amount of ETH to deposits or received after withdrawing
     * @param collection Address of the NFT collection
     * @param tokenIds List of token Ids
     */
    function calculateEthDepositOrWithdraw(address collection, uint256[] memory tokenIds)
        external
        view
        returns (uint256)
    {
        PoolInfo memory poolInfo = s_poolInfos[collection];
        uint64 scoresToDeposit = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            scoresToDeposit += generateScore(tokenIds[i]); // CHECK
        }
        return poolInfo.totalEth.mul(uint256(scoresToDeposit)).div(uint256(poolInfo.totalScore));
    }

    /**
     * @notice Calculates the amount of ETH to swaps to NFTs
     * @param collection Address of the NFT collection
     * @param tokenIds List of token Ids
     */
    function calculateEthToSwap(address collection, uint256[] memory tokenIds)
        external
        view
        returns (uint256)
    {
        PoolInfo memory poolInfo = s_poolInfos[collection];
        uint64 scoresToSwap = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            scoresToSwap += generateScore(tokenIds[i]); // CHECK
        }
        uint256 equivalentEthAmount = poolInfo.totalEth.mul(uint256(scoresToSwap)).div(
            uint256(poolInfo.totalScore)
        );
        uint256 serviceFee = equivalentEthAmount.mul(s_serviceFee).div(FEE_DENOMINATOR);
        uint256 creatorFee = equivalentEthAmount.mul(poolInfo.creatorFee).div(FEE_DENOMINATOR);
        uint256 liquidityProviderFee = equivalentEthAmount.mul(poolInfo.liquidityProviderFee).div(
            FEE_DENOMINATOR
        );
        return equivalentEthAmount + serviceFee + creatorFee + liquidityProviderFee;
    }

    /**
     * @notice Calculates the amount of ETH received after swapping NFTs
     * @param collection Address of the NFT collection
     * @param tokenIds List of token Ids
     */
    function calculateEthReceivedAfterSwap(address collection, uint256[] memory tokenIds)
        external
        view
        returns (uint256)
    {
        PoolInfo memory poolInfo = s_poolInfos[collection];
        uint64 scoresToSwap = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            scoresToSwap += generateScore(tokenIds[i]); // CHECK
        }
        uint256 equivalentEthAmount = poolInfo.totalEth.mul(uint256(scoresToSwap)).div(
            uint256(poolInfo.totalScore)
        );
        uint256 serviceFee = equivalentEthAmount.mul(s_serviceFee).div(FEE_DENOMINATOR);
        uint256 creatorFee = equivalentEthAmount.mul(poolInfo.creatorFee).div(FEE_DENOMINATOR);
        uint256 liquidityProviderFee = equivalentEthAmount.mul(poolInfo.liquidityProviderFee).div(
            FEE_DENOMINATOR
        );
        return equivalentEthAmount - serviceFee - creatorFee - liquidityProviderFee;
    }

    /**
     * @notice Gets the collection creator fee balance
     * @param collection Address of the NFT collection
     */
    function getCreatorBalance(address collection) public view returns (uint256) {
        PoolInfo memory poolInfo = s_poolInfos[collection];
        return poolInfo.lpToken.balance - poolInfo.totalEth;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

error MiaLiquidityProviderToken__NotMiaswap();
error MiaLiquidityProviderToken__FailedToSendEth();

contract MiaLiquidityProviderToken is ERC20Burnable {
    /*******************
     * State variables *
     *******************/
    address private immutable i_miaswap;
    address private immutable i_collection;

    /** Modifiers */
    modifier onlyMiaswap() {
        if (msg.sender != i_miaswap) {
            revert MiaLiquidityProviderToken__NotMiaswap();
        }
        _;
    }

    /******************
     * Main functions *
     ******************/
    constructor(address collection) ERC20("MiaLiquidityProviderToken", "MiaLP") {
        i_miaswap = msg.sender;
        i_collection = collection;
    }

    receive() external payable onlyMiaswap {}

    fallback() external payable onlyMiaswap {}

    /**
     * @notice Only Miaswap contract can call this method to mint tokens to user
     * @param to The address of user
     * @param amount Amount of tokens to mint
     */
    function mint(address to, uint256 amount) external onlyMiaswap {
        _mint(to, amount);
    }

    /**
     * @notice Only Miaswap contract can call this method to transfer an NFT to user
     * @param to The address of user
     * @param tokenIds List of NFT token Ids
     */
    function transferNfts(address to, uint256[] memory tokenIds) external onlyMiaswap {
        IERC721 collectionContract = IERC721(i_collection);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            collectionContract.transferFrom(address(this), to, tokenIds[i]);
        }
    }

    /**
     * @notice Only Miaswap can call this method to transfer ETH to user
     * @param to The address of user
     * @param amount The amount of ETH to transfer
     */
    function transferEth(address to, uint256 amount) external onlyMiaswap {
        (bool sent, ) = to.call{value: amount}("");
        if (!sent) {
            revert MiaLiquidityProviderToken__FailedToSendEth();
        }
    }

    /**
     * @notice To protect Liquidity Providers, we have adjusted only Miaswap contract can execute burn
     * @notice This method will never work
     */
    function burn(uint256 amount) public virtual override onlyMiaswap {
        _burn(_msgSender(), amount);
    }

    /**
     * @notice To protect Liquidity Providers, we have adjusted only Miaswap contract can execute burn
     * @param account The account that owns the tokens is burned
     * @param amount The amount of tokens to burn
     */
    function burnFrom(address account, uint256 amount) public virtual override onlyMiaswap {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }

    /********************
     * Getter functions *
     ********************/
    /**
     * @notice The number of lp tokens is always a positive integer
     */
    function decimals() public view virtual override returns (uint8) {
        return 0;
    }

    /**
     * @notice Gets the address of the Miaswap contract
     */
    function getMiaswap() public view returns (address) {
        return i_miaswap;
    }

    /**
     * @notice Gets the address of the collection corresponding to this LP token
     */
    function getCollection() public view returns (address) {
        return i_collection;
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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

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
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
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