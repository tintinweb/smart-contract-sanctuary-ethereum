// SPDX-License-Identifier: MIT
// Roach Racing Club: Collectible NFT game (https://roachracingclub.com/)
pragma solidity ^0.8.10;

import "Operators.sol";
import "IRoachNFT.sol";

contract GenesisSale is Operators {

    struct Whitelist {
        uint16 maxCount;
        uint32 traitBonus; // decimals 2, 12 mean 12% bonus
    }

    uint public ROACH_PRICE = 0.001 ether;
    uint constant public SALE_LIMIT = 10_000;
    uint constant public STAGE2_LIMIT_PER_TX = 100;
    uint public STAGE1_START;
    uint public STAGE1_DURATION;

    IERC20 public moneyTokenContract;
    IRoachNFT public roachContract;
    uint public soldCount = 0;
    mapping(address => uint) public soldCountPerAddress;
    mapping(address => Whitelist) public whitelist;
    mapping(string => uint) public syndicateScore;

    constructor(
        IERC20 _moneyToken,
        IRoachNFT _roachContract,
        uint stage1startTime,
        uint stage1durationSeconds,
        uint price)
    {
        moneyTokenContract = _moneyToken;
        roachContract = _roachContract;
        STAGE1_START = stage1startTime;
        STAGE1_DURATION = stage1durationSeconds;
        ROACH_PRICE = price;
    }

    function isPresaleActive() public view returns (bool) {
        return STAGE1_START <= block.timestamp
            && block.timestamp < STAGE1_START + STAGE1_DURATION;
    }

    function isSaleStage2Active() public view returns (bool) {
        return STAGE1_START + STAGE1_DURATION <= block.timestamp
            && soldCount < SALE_LIMIT;
    }

    function getSaleStatus(address account) external view returns (
        bool presaleActive,
        bool stage2active,
        uint leftToMint,
        uint secondsToNextStage,
        uint price,
        uint allowedToMintForAccount,
        uint accountBonus)
    {
        presaleActive = isPresaleActive();
        stage2active = isSaleStage2Active();
        price = ROACH_PRICE;
        secondsToNextStage =
            presaleActive ? STAGE1_START + STAGE1_DURATION - block.timestamp :
            block.timestamp < STAGE1_START ? STAGE1_START - block.timestamp :
            0;
        leftToMint = SALE_LIMIT - soldCount;
        allowedToMintForAccount =
            presaleActive ? getAllowedToBuyForAccountOnPresale(account) :
            stage2active ? getAllowedToBuyOnStage2() :
            (uint)(0);
        accountBonus = presaleActive ? getAccountBonusOnPresale(account) : (uint)(0);
    }

    function getAccountBonusOnPresale(address account) public view returns (uint) {
        return whitelist[account].traitBonus;
    }

    function getAllowedToBuyForAccountOnPresale(address account) public view returns (uint) {
        return whitelist[account].maxCount - soldCountPerAddress[account];
    }

    function getAllowedToBuyOnStage2() public view returns (uint) {
        return STAGE2_LIMIT_PER_TX;
    }

    function mint(uint count, string calldata syndicate) external {
        if (isPresaleActive()) {
            _mintStage1(msg.sender, count, syndicate);
        } else if (isSaleStage2Active()) {
            _mintStage2(msg.sender, count, syndicate);
        } else {
            revert("Genesis sale not started yet");
        }
    }

    function _mintStage1(address account, uint count, string calldata syndicate) internal {
        require(STAGE1_START <= block.timestamp, 'Sale stage1 not started');
        require(block.timestamp < STAGE1_START + STAGE1_DURATION, 'Sale stage1 is over');

        uint leftToMint = getAllowedToBuyForAccountOnPresale(account);
        require(count <= leftToMint, 'Account limit reached');

        soldCountPerAddress[account] += count;
        _buy(account, count, syndicate, whitelist[account].traitBonus);
    }

    function _mintStage2(address account, uint count, string calldata syndicate) internal {
        require(count <= STAGE2_LIMIT_PER_TX, 'Limit per tx');
        require(STAGE1_START + STAGE1_DURATION <= block.timestamp, 'Sale stage2 not started');
        _buy(account, count, syndicate, 0);
    }

    function _buy(address account, uint count, string calldata syndicate, uint32 traitBonus) internal {
        uint needMoney = ROACH_PRICE * count;

        require(count > 0, 'Min count is 1');
        if (soldCount >= SALE_LIMIT) {
            require(false, 'Sale is over');
        }
        if (soldCount + count > SALE_LIMIT) {
            count = SALE_LIMIT - soldCount; // allow to buy left tokens
        }
        require(moneyTokenContract.balanceOf(account) >= needMoney, "Insufficient money");

        moneyTokenContract.transferFrom(
            account,
            address(this),
            needMoney
        );
        syndicateScore[syndicate] += count;
        _mintRaw(account, count, traitBonus);
    }

    function _mintRaw(address to, uint count, uint32 traitBonus) internal {
        soldCount += count;
        for (uint i = 0; i < count; i++) {
            roachContract.mintGen0(to, traitBonus);
        }
    }

    /// Admin functions

    function mintOperator(address to, uint count, uint32 traitBonus) external onlyOperator {
        _mintRaw(to, count, traitBonus);
    }

    function setWhitelistAddress(address account, uint16 maxCount, uint32 traitBonus) external onlyOperator {
        whitelist[account] = Whitelist(maxCount, traitBonus);
    }

    function setWhitelistAddressBatch(address[] calldata accounts, uint16 maxCount, uint32 traitBonus) external onlyOperator {
        for (uint i = 0; i < accounts.length; i++) {
            whitelist[accounts[i]] = Whitelist(maxCount, traitBonus);
        }
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
    function mintGen0(address to, uint32 traitBonus) external;
    function setGenome(uint tokenId, bytes calldata genome) external;

}