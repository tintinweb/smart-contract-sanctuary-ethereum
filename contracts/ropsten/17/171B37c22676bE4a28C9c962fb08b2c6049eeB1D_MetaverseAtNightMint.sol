/**
 *Submitted for verification at Etherscan.io on 2022-05-18
*/

// SPDX-License-Identifier: MIT

// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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

// File: @openzeppelin/contracts/utils/Context.sol

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

// File: @openzeppelin/contracts/access/Ownable.sol

pragma solidity ^0.8.0;

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

pragma solidity ^0.8.0;

interface IGame {
    function gameMint(address _to, uint256 _mintAmount) external;
    function isGame(address _to) external view returns (bool);
    function setGame(address _to, bool _state) external;
}

interface IGames {
    function gameMint(address _to, uint256 _mintAmount) external;
    function gamesOf(address _to) external view returns (uint256);
    function addGames(address _to, uint256 _newGames) external;
    function removeGames(address _to, uint256 _newGames) external;
}

contract MetaverseAtNightMint is Ownable {

    address public constant HA2 = 0xa50797F0Cb879f3B4D1002EeAe932c203e2f52dF;
    address public constant MANCamels = 0xf5eadd59709837BB5406b59757c9dfa23C1073d5;
    address public constant SP = 0x750858236Bcb2e27e238e16BDC22d1Dd99BF44DE;

    uint256 public lastPrice = 2.0 ether;
    uint256 public lastMint;
    uint256 public dutchStart = 2.0 ether;
    uint256 public dutchBase = 0.03 ether;
    uint256 public dutchMinutes = 2;
    uint256 public mintPrice = 4.0 ether;

    bool public mintPaused;
    bool public isDutch;

    mapping(address => uint256) private _holderCount;

    constructor() {}

    // public payable
    function mint(uint256 mintAmount) public payable {
        mint(msg.sender, mintAmount);
    }

    function mint(address user, uint256 mintAmount) public payable {
        require(user != address(0), "user is the zero address");
        require(!mintPaused, "the contract mint is paused");
        require(mintAmount > 0, "need to mint at least 1 NFT");

        lastPrice = getMintPrice();
        lastMint = block.timestamp;
        if (user != owner()) {
            require(msg.value >= lastPrice * mintAmount, "insufficient funds");

            (bool success, ) = payable(owner()).call{value: msg.value}("");
            require(success, "failed to send payment");
        }

        IGames(HA2).gameMint(user, mintAmount);
        IGame(MANCamels).gameMint(user, mintAmount);
        IGame(SP).gameMint(user, mintAmount);
    }

    // public view
    function getMintPrice() public view returns (uint256) {
        if (!isDutch) {
            return mintPrice;
        }

        uint256 minutesPast = (block.timestamp - lastMint) / 60;
        uint256 drops = minutesPast / dutchMinutes;

        uint256 currentPrice = lastPrice;
        uint256 loop;
        for (loop = 1; loop <= drops; loop++) {
            if (currentPrice <= 0.1 ether && currentPrice > 0.01 ether) {
                currentPrice = currentPrice - 0.01 ether;
            } else if (currentPrice > 0.1 ether) {
                currentPrice = currentPrice - 0.1 ether;
            }
        }

        if (currentPrice < dutchBase) {
            return dutchBase;
        }

        return currentPrice;
    }

    // onlyOwner
    function startDutch() public onlyOwner {
        isDutch = true;
        lastMint = block.timestamp;
        lastPrice = dutchStart;
    }

    function stopDutch() public onlyOwner {
        isDutch = false;
    }

    function setDutchStart(uint256 _dutchStart) public onlyOwner {
        dutchStart = _dutchStart;
    }

    function setDutchBase(uint256 _dutchBase) public onlyOwner {
        dutchBase = _dutchBase;
    }

    function setDutchMinutes(uint256 _dutchMinutes) public onlyOwner {
        dutchMinutes = _dutchMinutes;
    }

    function setMintPrice(uint256 _mintPrice) public onlyOwner {
        mintPrice = _mintPrice;
    }

    function setMintPaused(bool _state) public onlyOwner {
        mintPaused = _state;
    }

    function tokenWithdraw(IERC20 token) public onlyOwner {
        uint256 amount = token.balanceOf(address(this));
        bool success = token.transfer(owner(), amount);
        require(success, "failed to withdraw token");
    }

    function withdraw() public onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success, "failed to withdraw");
    }
}