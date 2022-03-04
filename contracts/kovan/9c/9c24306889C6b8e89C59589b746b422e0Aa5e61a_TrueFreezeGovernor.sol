//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "Ownable.sol";
import "IERC20.sol";
import "ReentrancyGuard.sol";
import "IfrToken.sol";
import "IwAsset.sol";
import "IMultiRewards.sol";
import "INonFungiblePositionManager.sol";

/// @title TrueFreezeGovernor contract
/// @author chalex.eth - CharlieDAO
/// @notice Main TrueFreeze contract

contract TrueFreezeGovernor is Ownable, ReentrancyGuard {
    uint256 internal constant N_DAYS = 365;
    uint256 internal constant MIN_LOCK_DAYS = 7;
    uint256 internal constant MAX_LOCK_DAYS = 1100;
    uint256 internal constant MAX_UINT = 2**256 - 1;

    /// @dev The token ID position data
    mapping(uint256 => Position) private _positions;

    /// @dev The ID of the next token that will be minted. Skips 0
    uint256 private _nextId = 1;

    ///@dev pack the parameters of the position in a struct
    struct Position {
        uint256 amountLocked;
        uint256 tokenMinted;
        uint256 lockingDate;
        uint256 maturityDate;
        bool active;
    }

    /* ----------- events --------------*/

    event lockedWAsset(
        address indexed minter,
        uint256 indexed tokenId,
        uint256 amountLocked,
        uint256 lockingDate,
        uint256 maturityDate
    );

    event withdrawedWAsset(
        address indexed withdrawer,
        uint256 indexed tokenId,
        uint256 amountWithdrawed,
        uint256 WAssetPenalty,
        uint256 frPenalty
    );

    /* ----------- Interfaces --------------*/

    IfrToken private immutable frToken;
    IwAsset private immutable wAsset;
    INonFungiblePositionManager private immutable nftPosition;
    IMultiRewards private immutable stakingContract;

    /* ----------- Constructor --------------*/

    constructor(
        address _wAssetaddress,
        address _frToken,
        address _NFTPosition,
        address _stakingAddress
    ) {
        wAsset = IwAsset(_wAssetaddress);
        frToken = IfrToken(_frToken);
        nftPosition = INonFungiblePositionManager(_NFTPosition);
        stakingContract = IMultiRewards(_stakingAddress);
        wAsset.approve(_stakingAddress, MAX_UINT);
        frToken.approve(_stakingAddress, MAX_UINT);
    }

    /* ----------- External functions --------------*/

    /// @notice lock wAsset (WETH,WAVAX,WMATIC...) and create a position represented by a NFT
    /// @dev locking create a position, reward by minting frToken and NFT associated to the position
    /// @param _amount wAsset amount to lock
    /// @param _lockDuration number of days to lock the wAsset
    function lockWAsset(uint256 _amount, uint256 _lockDuration)
        external
        nonReentrant
    {
        require(_amount > 0, "Amount must be more than 0");
        require(
            _lockDuration >= MIN_LOCK_DAYS && _lockDuration <= MAX_LOCK_DAYS,
            "Bad days input"
        );
        bool sent = wAsset.transferFrom(msg.sender, address(this), _amount);
        require(sent, "Error in sending WAsset");
        uint256 lockingDate = block.timestamp;
        uint256 maturityDate = lockingDate + (_lockDuration * 1 days);
        uint256 tokenToMint = _calculate_frToken(
            _amount,
            (_lockDuration * 1 days)
        );
        _createPosition(
            _amount,
            tokenToMint,
            lockingDate,
            maturityDate,
            _nextId
        );
        _mintToken(tokenToMint);
        nftPosition.mint(msg.sender, _nextId);

        emit lockedWAsset(
            msg.sender,
            _nextId,
            _amount,
            lockingDate,
            maturityDate
        );

        _nextId += 1;
    }

    /// @notice withdraw wAsset (WETH,WAVAX,WMATIC...) associated to the NFT position
    /// @dev withdraw the position associated to the NFT position
    /// @param _tokenId ID of the NFT token
    function withdrawWAsset(uint256 _tokenId) external nonReentrant {
        require(
            msg.sender == nftPosition.ownerOf(_tokenId),
            "Not the owner of tokenId"
        );
        require(
            _positions[_tokenId].active = true,
            "Position already withdrawed"
        );

        (
            uint256 amountLocked,
            uint256 tokenMinted,
            uint256 lockingDate,
            uint256 maturityDate,
            bool active
        ) = getPositions(_tokenId);
        uint256 feesToPay = getWAssetFees(_tokenId);
        _positions[_tokenId].active = false;
        _positions[_tokenId].amountLocked = 0;

        nftPosition.burn(_tokenId);
        uint256 progress = getProgress(_tokenId);
        if (progress >= 100) {
            // if progress > 100 sending back asset
            wAsset.approve(msg.sender, amountLocked);
            wAsset.transfer(msg.sender, amountLocked);
            emit withdrawedWAsset(msg.sender, _tokenId, amountLocked, 0, 0);
        } else if (progress < 100) {
            // if progress < 100 user need to pay a wAsset fee
            uint256 sendToUser = amountLocked - feesToPay;
            wAsset.approve(msg.sender, sendToUser);
            wAsset.transfer(msg.sender, sendToUser);
            stakingContract.notifyRewardAmount(address(wAsset), feesToPay);

            uint256 frPenalty = getUnlockCost(_tokenId);
            frToken.transferFrom(msg.sender, address(this), frPenalty);

            if (progress <= 67) {
                // if progress < 67 user need to pay a wAsset fee and frToken fee
                (uint256 toSend, uint256 toBurn) = _calculateBurnAndSend(
                    tokenMinted,
                    frPenalty
                );
                frToken.burn(address(this), toBurn);
                stakingContract.notifyRewardAmount(address(frToken), toSend);
            } else {
                frToken.burn(address(this), frPenalty);
            }
            emit withdrawedWAsset(
                msg.sender,
                _tokenId,
                amountLocked,
                feesToPay,
                frPenalty
            );
        }
    }

    /* ----------- Internal functions --------------*/

    ///@dev create a mapping of position struct
    function _createPosition(
        uint256 _amount,
        uint256 _tokenMinted,
        uint256 _lockingDate,
        uint256 _maturityDate,
        uint256 tokenId
    ) private {
        _positions[tokenId] = Position({
            amountLocked: _amount,
            tokenMinted: _tokenMinted,
            lockingDate: _lockingDate,
            maturityDate: _maturityDate,
            active: true
        });
    }

    function _mintToken(uint256 _tokenToMint) private {
        frToken.mint(msg.sender, _tokenToMint);
    }

    /* ----------- View functions --------------*/

    ///@dev returns data for a given position
    function getPositions(uint256 tokenId)
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            bool
        )
    {
        return (
            _positions[tokenId].amountLocked,
            _positions[tokenId].tokenMinted,
            _positions[tokenId].lockingDate,
            _positions[tokenId].maturityDate,
            _positions[tokenId].active
        );
    }

    ///@dev get the progress for a given position
    function getProgress(uint256 tokenId) public view returns (uint256) {
        (, , uint256 _lockingDate, uint256 _maturityDate, ) = getPositions(
            tokenId
        );
        return _calculateProgress(block.timestamp, _lockingDate, _maturityDate);
    }

    ///@dev get the frToken fee to pay for unlocking a position
    function getUnlockCost(uint256 _tokenId) public view returns (uint256) {
        uint256 _progress = getProgress(_tokenId);
        (, uint256 _TokenMinted, , , ) = getPositions(_tokenId);
        return _calculateWithdrawCost(_progress, _TokenMinted);
    }

    ///@dev get the wAsset fee to pay if position is unlock
    function getWAssetFees(uint256 _tokenId) public view returns (uint256) {
        (uint256 amountLocked, , , , ) = getPositions(_tokenId);
        uint256 progress = getProgress(_tokenId);
        if (progress >= 100) {
            return 0;
        } else {
            return _calculateWAssetFees(amountLocked);
        }
    }

    /* ----------- Pure functions --------------*/

    /// @notice Get the amount of frAsset that will be minted
    /// @return Return the amount of frAsset that will be minted
    function _calculate_frToken(uint256 _lockedAmount, uint256 _timeToLock)
        internal
        pure
        returns (uint256)
    {
        uint256 token = (_timeToLock * _lockedAmount) / (N_DAYS * 1 days);
        return token;
    }

    function _calculateProgress(
        uint256 _nBlock,
        uint256 _lockingDate,
        uint256 _maturityDate
    ) internal pure returns (uint256) {
        return
            (100 * (_nBlock - _lockingDate)) / (_maturityDate - _lockingDate);
    }

    function _calculateWithdrawCost(uint256 _progress, uint256 _frToken)
        internal
        pure
        returns (uint256)
    {
        uint256 unlockCost;
        if (_progress >= 100) {
            unlockCost = 0;
        } else if (_progress < 67) {
            unlockCost =
                _frToken +
                ((((20 * _frToken) / 100) * (100 - ((_progress * 3) / 2))) /
                    100);
        } else {
            unlockCost = (_frToken * (100 - ((_progress - 67) * 3))) / 100;
        }
        return unlockCost;
    }

    function _calculateWAssetFees(uint256 _lockedAmount)
        internal
        pure
        returns (uint256)
    {
        return (_lockedAmount * 25) / 10000;
    }

    ///@dev calculate how much token is burnt and sent to staking contract
    function _calculateBurnAndSend(uint256 _tokenMinted, uint256 _penaltyPaid)
        internal
        pure
        returns (uint256, uint256)
    {
        uint256 toSend = (_penaltyPaid - _tokenMinted) / 2;
        uint256 toBurn = _tokenMinted + (_penaltyPaid - _tokenMinted) / 2;
        return (toSend, toBurn);
    }
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
// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)

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

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "IERC20.sol";

interface IfrToken is IERC20 {
    function mint(address, uint256) external;

    function burn(address, uint256) external;
}

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "IERC20.sol";

interface IwAsset is IERC20 {}

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IMultiRewards {
    function notifyRewardAmount(address, uint256) external;
}

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface INonFungiblePositionManager {
    function mint(address, uint256) external;

    function burn(uint256) external;

    function ownerOf(uint256) external view returns (address);
}