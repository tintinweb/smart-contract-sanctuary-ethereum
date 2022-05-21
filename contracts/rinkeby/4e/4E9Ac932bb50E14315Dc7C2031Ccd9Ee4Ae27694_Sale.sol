// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "Ownable.sol";
import "INFT.sol";

contract Sale is Ownable {
    uint public NFT_PRICE;
    uint public TOTAL_TOKENS_ON_SALE;
    uint public STAGE1_START;
    uint public STAGE1_DURATION;
    address public signerAddress;
    INFT public nftContract;

    event Purchase(address indexed account, uint count);

    constructor(
        INFT _nftContract,
        uint stage1startTime,
        uint stage1durationSeconds,
        uint price,
        uint totalTokensOnSale)
    {
        nftContract = _nftContract;
        STAGE1_START = stage1startTime;
        STAGE1_DURATION = stage1durationSeconds;
        NFT_PRICE = price;
        TOTAL_TOKENS_ON_SALE = totalTokensOnSale;
        signerAddress = msg.sender;
    }

    /// @notice Returns current sale status
    /// @param account Selected buyer address
    /// @return stage One of number 0..3. 0 - presale not started. 1 - Presale. 2 - Genesis sale. 3 - sale is over.
    /// @return leftToMint Left roaches to mint
    /// @return nextStageTimestamp UTC timestamp of current stage finish and next stage start. Always 0 for for stages 2 and 3.
    /// @return price One roach price in ETH.
    /// @return allowedToMint For stage 2 - max count for one tx.
    function getSaleStatus(address account, uint limitForAccount) external view returns (
        uint stage,
        int leftToMint,
        uint nextStageTimestamp,
        uint price,
        uint allowedToMint)
    {
        stage = getSaleStage();

        price = NFT_PRICE;
        nextStageTimestamp =
            stage == 0 ? STAGE1_START :
            stage == 1 ? STAGE1_START + STAGE1_DURATION :
            0;
        leftToMint = int(TOTAL_TOKENS_ON_SALE) - int(totalSupply());
        allowedToMint =
            stage == 1 ? getAllowedToBuyForAccountOnPresale(account, limitForAccount) :
            stage == 2 ? uint(leftToMint) :
            (uint)(0);
    }

    function isPresaleActive() public view returns (bool) {
        return STAGE1_START <= block.timestamp
            && block.timestamp < STAGE1_START + STAGE1_DURATION
            && totalSupply() < TOTAL_TOKENS_ON_SALE;
    }

    function isSaleStage2Active() public view returns (bool) {
        return STAGE1_START + STAGE1_DURATION <= block.timestamp
            && totalSupply() < TOTAL_TOKENS_ON_SALE;
    }

    function getSaleStage() public view returns (uint) {
        return isPresaleActive() ? 1 :
            isSaleStage2Active() ? 2 :
            block.timestamp < STAGE1_START ? 0 :
            3;
    }

    /// @notice Takes payment and mints new roaches on Genesis Sale
    /// @dev function works on both Presale and Genesis sale stages
    /// @param desiredCount The number of roach to mint
    // decimals 2, 12 mean 12% bonus
    function mintStage1(
        uint desiredCount,
        uint limitForAccount,
        uint8 sigV,
        bytes32 sigR,
        bytes32 sigS
    )
        external payable
    {
        require(isValidSignature(msg.sender, limitForAccount, sigV, sigR, sigS), "Wrong signature");
        _mintStage1(msg.sender, desiredCount, limitForAccount);
    }

    function getAllowedToBuyForAccountOnPresale(address account, uint limitForAccount) public view returns (uint) {
        uint256 numberMinted = nftContract.getNumberMinted(account);
        return limitForAccount > numberMinted
            ? limitForAccount - numberMinted
            : 0;
    }

    function _mintStage1(address account, uint desiredCount, uint limitForAccount) internal {
        uint stage = getSaleStage();
        require(stage == 1, "Presale not active");
        uint leftToMint = getAllowedToBuyForAccountOnPresale(account, limitForAccount);
        require(desiredCount <= leftToMint, 'Account limit reached');

        _buy(account, desiredCount);
    }

    /// @notice Takes payment and mints new roaches on Genesis Sale
    /// @dev function works on both Presale and Genesis sale stages
    /// @param desiredCount The number of roach to mint
    function mintStage2(uint desiredCount) external payable {
        uint stage = getSaleStage();
        require(stage == 2, "Public sale not active");
        _buy(msg.sender, desiredCount);
    }

    function _buy(address account, uint count) internal {
        require(count > 0, 'Min count is 1');
        uint soldCount = totalSupply();
        if (soldCount + count > TOTAL_TOKENS_ON_SALE) {
            count = TOTAL_TOKENS_ON_SALE - soldCount; // allow to buy left tokens
        }
        uint needMoney = NFT_PRICE * count;
        emit Purchase(account, count);
        _mintRaw(account, count);
        acceptMoney(needMoney);
    }

    function acceptMoney(uint needMoney) internal {
        require(msg.value >= needMoney, "Insufficient money");
        if (msg.value > needMoney) {
            payable(msg.sender).transfer(msg.value - needMoney);
        }
    }

    function _mintRaw(address to, uint count) internal {
        nftContract.mintRoom(to, count);
    }

    function totalSupply() public view returns (uint256) {
        return nftContract.lastTokenId();
    }

    /// Signatures

    function hashArguments(address account, uint limitForAccount)
        public pure returns (bytes32 msgHash)
    {
        msgHash = keccak256(abi.encode(account, limitForAccount));
    }

    function getSigner(
        address account, uint limitForAccount,
        uint8 sigV, bytes32 sigR, bytes32 sigS
    )
        public pure returns (address)
    {
        bytes32 msgHash = hashArguments(account, limitForAccount);
        return ecrecover(msgHash, sigV, sigR, sigS);
    }

    function isValidSignature(
        address account, uint limitForAccount,
        uint8 sigV, bytes32 sigR, bytes32 sigS
    )
        public
        view
        returns (bool)
    {
        return getSigner(account, limitForAccount, sigV, sigR, sigS) == signerAddress;
    }

    /// Admin functions
    function mintOperator(address to, uint count) external onlyOwner {
        _mintRaw(to, count);
    }

    function setSigner(address newSigner) external onlyOwner {
        signerAddress = newSigner;
    }

    function withdrawEther() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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
// Roach Racing Club: Collectible NFT game (https://roachracingclub.com/)
pragma solidity ^0.8.10;

interface INFT {

    function mintRoom(address to, uint count) external;
    function mintWithType(address to, uint8 _type) external;
    function lastTokenId() external view returns (uint);
    function getNumberMinted(address account) external view returns (uint64);
    function burn(uint tokenId) external;
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function getTokenInfo(uint tokenId) external view returns (uint8 estateType);
    function transferFrom(address from, address to, uint256 tokenId) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}