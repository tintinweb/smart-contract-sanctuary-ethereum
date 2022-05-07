// SPDX-License-Identifier: MIT
// Roach Racing Club: Collectible NFT game (https://roachracingclub.com/)
pragma solidity ^0.8.10;

import "GenesisSale.sol";

contract GenesisSaleDebug is GenesisSale {

    constructor(
        IRoachNFT _roachContract,
        uint stage1startTime,
        uint stage1durationSeconds,
        uint price,
        uint totalTokensOnSale)
        GenesisSale(_roachContract, stage1startTime, stage1durationSeconds, price, totalTokensOnSale)
    {
    }

    function mintStage1noSig(
        uint wantCount,
        uint limitForAccount,
        uint8 traitBonus,
        string calldata syndicate
    )
        external payable
    {
        _mintStage1(msg.sender, wantCount, limitForAccount, traitBonus, syndicate);
    }

    function setStage0(uint duration) external onlyOperator {
        STAGE1_START = block.timestamp + duration;
    }

    function setStage1(uint duration) external onlyOperator {
        STAGE1_START = block.timestamp;
        STAGE1_DURATION = duration;
    }

    function setStage2() external onlyOperator {
        STAGE1_START = block.timestamp - STAGE1_DURATION;
    }

    function setStage3() external onlyOperator {
        STAGE1_START = block.timestamp - STAGE1_DURATION;
    }

}

// SPDX-License-Identifier: MIT
// Roach Racing Club: Collectible NFT game (https://roachracingclub.com/)
pragma solidity ^0.8.10;

import "Operators.sol";
import "IRoachNFT.sol";

contract GenesisSale is Operators {

    uint public ROACH_PRICE = 0.0001 ether;
    uint public TOTAL_TOKENS_ON_SALE = 10_000;
    uint constant public STAGE2_LIMIT_PER_TX = 30;
    uint public STAGE1_START;
    uint public STAGE1_DURATION;
    address public signerAddress;
    IRoachNFT public roachContract;

    mapping(address => uint) public soldCountPerAddress;
    mapping(string => uint) public syndicateScore;

    event Purchase(address indexed account, uint count, uint traitBonus, string syndicate);

    constructor(
        IRoachNFT _roachContract,
        uint stage1startTime,
        uint stage1durationSeconds,
        uint price,
        uint totalTokensOnSale)
    {
        roachContract = _roachContract;
        STAGE1_START = stage1startTime;
        STAGE1_DURATION = stage1durationSeconds;
        ROACH_PRICE = price;
        TOTAL_TOKENS_ON_SALE = totalTokensOnSale;
        // TODO: setSigner
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

        price = ROACH_PRICE;
        nextStageTimestamp =
            stage == 0 ? STAGE1_START :
            stage == 1 ? STAGE1_START + STAGE1_DURATION :
            0;
        leftToMint = int(TOTAL_TOKENS_ON_SALE) - int(totalSupply());
        allowedToMint =
            stage == 1 ? getAllowedToBuyForAccountOnPresale(account, limitForAccount) :
            stage == 2 ? getAllowedToBuyOnStage2() :
            (uint)(0);
    }

    function totalSupply() public view returns (uint256) {
        return roachContract.lastRoachId();
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

    function getAllowedToBuyOnStage2() public pure returns (uint) {
        return STAGE2_LIMIT_PER_TX;
    }

    /// @notice Takes payment and mints new roaches on Genesis Sale
    /// @dev function works on both Presale and Genesis sale stages
    /// @param wantCount The number of roach to mint
    /// @param syndicate (Optional) Syndicate name, that player wants join to. Selected syndicate will receive a bonus.
    // decimals 2, 12 mean 12% bonus
    function mintStage1(
        uint wantCount,
        uint limitForAccount,
        uint8 traitBonus,
        string calldata syndicate,
        uint8 sigV,
        bytes32 sigR,
        bytes32 sigS
    )
        external payable
    {
        require(isValidSignature(msg.sender, limitForAccount, traitBonus, sigV, sigR, sigS), "Wrong signature");
        _mintStage1(msg.sender, wantCount, limitForAccount, traitBonus, syndicate);
    }

    function getAllowedToBuyForAccountOnPresale(address account, uint limitForAccount) public view returns (uint) {
        return limitForAccount > soldCountPerAddress[account]
            ? limitForAccount - soldCountPerAddress[account]
            : 0;
    }

    function _mintStage1(address account, uint wantCount, uint limitForAccount, uint8 traitBonus, string calldata syndicate) internal {
        uint stage = getSaleStage();
        require(stage == 1, "Presale not active");
        uint leftToMint = getAllowedToBuyForAccountOnPresale(account, limitForAccount);
        require(wantCount <= leftToMint, 'Account limit reached');

        _buy(account, wantCount, syndicate, traitBonus);
    }

    /// @notice Takes payment and mints new roaches on Genesis Sale
    /// @dev function works on both Presale and Genesis sale stages
    /// @param count The number of roach to mint
    /// @param syndicate (Optional) Syndicate name, that player wants join to. Selected syndicate will receive a bonus.
    function mintStage2(uint count, string calldata syndicate) external payable {
        uint stage = getSaleStage();
        require(stage == 2, "Public sale not active");
        require(count <= STAGE2_LIMIT_PER_TX, 'Limit per tx');
        _buy(msg.sender, count, syndicate, 0);
    }

    function _buy(address account, uint count, string calldata syndicate, uint8 traitBonus) internal {
        require(count > 0, 'Min count is 1');
        uint soldCount = totalSupply();
        if (soldCount + count > TOTAL_TOKENS_ON_SALE) {
            count = TOTAL_TOKENS_ON_SALE - soldCount; // allow to buy left tokens
        }
        uint needMoney = ROACH_PRICE * count;
        syndicateScore[syndicate] += count;
        soldCountPerAddress[account] += count;
        emit Purchase(account, count, traitBonus, syndicate);
        _mintRaw(account, count, traitBonus, syndicate);
        acceptMoney(needMoney);
    }

    function acceptMoney(uint needMoney) internal {
        require(msg.value >= needMoney, "Insufficient money");
        if (msg.value > needMoney) {
            payable(msg.sender).transfer(msg.value - needMoney);
        }
    }

    function _mintRaw(address to, uint count, uint8 traitBonus, string calldata syndicate) internal {
        for (uint i = 0; i < count; i++) {
            roachContract.mintGen0(to, traitBonus, syndicate);
        }
    }

    /// Signatures

    function hashArguments(address account, uint limitForAccount, uint8 traitBonus)
        public pure returns (bytes32 msgHash)
    {
        msgHash = keccak256(abi.encode(account, limitForAccount, traitBonus));
    }

    function getSigner(
        address account, uint limitForAccount, uint8 traitBonus,
        uint8 sigV, bytes32 sigR, bytes32 sigS
    )
    public pure returns (address)
    {
        bytes32 msgHash = hashArguments(account, limitForAccount, traitBonus);
        return ecrecover(msgHash, sigV, sigR, sigS);
    }

    function isValidSignature(
        address account, uint limitForAccount, uint8 traitBonus,
        uint8 sigV, bytes32 sigR, bytes32 sigS
    )
        public
        view
        returns (bool)
    {
        return getSigner(account, limitForAccount, traitBonus, sigV, sigR, sigS) == signerAddress;
    }

    /// Admin functions
    function mintOperator(address to, uint count, uint8 traitBonus, string calldata syndicate) external onlyOperator {
        _mintRaw(to, count, traitBonus, syndicate);
    }

}

// SPDX-License-Identifier: MIT
// Degen'$ Farm: Collectible NFT game (https://degens.farm)
pragma solidity ^0.8.10;

import "IERC20.sol";
import "Ownable.sol";

contract Operators is Ownable {
    mapping (address=>bool) operatorAddress;

    modifier onlyOperator() {
        require(isOperator(msg.sender), "Access denied");
        _;
    }

    function isOwner(address _addr) public view returns (bool) {
        return owner() == _addr;
    }

    function isOperator(address _addr) public view returns (bool) {
        return operatorAddress[_addr] || isOwner(_addr);
    }

    function _addOperator(address _newOperator) internal {
        operatorAddress[_newOperator] = true;
    }

    function addOperator(address _newOperator) external onlyOwner {
        require(_newOperator != address(0), "New operator is empty");
        _addOperator(_newOperator);
    }

    function removeOperator(address _oldOperator) external onlyOwner {
        delete(operatorAddress[_oldOperator]);
    }

    /**
     * @dev Owner can claim any tokens that transferred
     * to this contract address
     */
    function withdrawERC20(IERC20 _tokenContract, address _admin) external onlyOwner {
        uint256 balance = _tokenContract.balanceOf(address(this));
        _tokenContract.transfer(_admin, balance);
    }

    function withdrawEther() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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

interface IRoachNFT {

    function mint(
        address to,
        bytes calldata genome,
        uint40[2] calldata parents,
        uint40 generation,
        uint16 resistance) external;

    function mintGen0(address to, uint8 traitBonus, string calldata syndicate) external;

    function setGenome(uint tokenId, bytes calldata genome) external;

    function lastRoachId() external view returns (uint);

}