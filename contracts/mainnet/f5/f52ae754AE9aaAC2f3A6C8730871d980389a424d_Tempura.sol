///@author WOK
///@dev This contract controls dripping and minting of TEMPURA.
///@dev Dripping occurs via Yakuza Elite - Gen Yakuza must mint tokens due to lack of transfer hooks or staking.
///@dev S/O to OxBeans for GIGADRIP

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./GIGADRIP.sol";

contract Tempura is Ownable, GIGADRIP20, ReentrancyGuard {
    uint256 public constant BASE_RATE = 2 ether;

    address public yakuzaElite;

    bool public claimAllowed;

    uint256 public startTime;
    uint256 public endTime;

    mapping(uint256 => uint256) public lastClaim;
    mapping(address => uint256) private userIndex;

    address[] public accruers;

    IERC721 public constant YAKUZA_GEN = IERC721(0x0EE1448F200e6e65E9bad7A335E3FFb674c0f68C);

    constructor() GIGADRIP20("Tempura", "TEMPURA", 18, 167000000000000) {
        startTime = block.timestamp + 100 days;
    }

    /*==============================================================
    ==                    Dripping Functions                      ==
    ==============================================================*/

    function startDripping(address addr, uint128 multiplier) external {
        require(
            msg.sender == yakuzaElite || msg.sender == owner(),
            "Dripping can only be modified by Yakuza Elite contract or owner"
        );
        if (_accruers[addr].multiplier == 0) {
            userIndex[addr] = accruers.length;
            accruers.push(addr);
        }
        if (block.timestamp < endTime) _startDripping(addr, multiplier);
    }

    function stopDripping(address addr, uint128 multiplier) external {
        require(
            msg.sender == yakuzaElite || msg.sender == owner(),
            "Dripping can only be modified by Yakuza Elite contract or owner"
        );
        if (block.timestamp < endTime) _stopDripping(addr, multiplier);
        if (_accruers[addr].multiplier == 0) {
            accruers[userIndex[addr]] = accruers[accruers.length - 1];
            accruers.pop();
        }
    }

    function burn(address from, uint256 value) external {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.
        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - value;

        _burn(from, value);
    }

    /*==============================================================
    ==                    Gen Yield Functions                     ==
    ==============================================================*/

    function claimReward(uint256 _tokenId) external nonReentrant {
        require(claimAllowed, "Claiming is not live.");
        require(
            YAKUZA_GEN.ownerOf(_tokenId) == msg.sender,
            "Caller does not own the token being claimed for."
        );
        uint256 unclaimedReward = computeUnclaimedReward(_tokenId);
        lastClaim[_tokenId] = block.timestamp;
        _mint(msg.sender, unclaimedReward);
    }

    function claimRewards(uint256[] calldata _tokenIds) external nonReentrant {
        require(claimAllowed, "Claiming is not live.");
        uint256 totalUnclaimedRewards = 0;
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 _tokenId = _tokenIds[i];
            require(
                YAKUZA_GEN.ownerOf(_tokenId) == msg.sender,
                "Caller does not own the token being claimed for."
            );
            uint256 unclaimedReward = computeUnclaimedReward(_tokenId);
            totalUnclaimedRewards = totalUnclaimedRewards + unclaimedReward;
            lastClaim[_tokenId] = block.timestamp;
        }
        _mint(msg.sender, totalUnclaimedRewards);
    }

    function getUnclaimedRewardAmount(uint256 _tokenId) public view returns (uint256) {
        uint256 unclaimedReward = computeUnclaimedReward(_tokenId);
        return unclaimedReward;
    }

    function getUnclaimedRewardsAmount(uint256[] calldata _tokenIds)
        public
        view
        returns (uint256)
    {
        uint256 totalUnclaimedRewards = 0;

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            totalUnclaimedRewards += computeUnclaimedReward(_tokenIds[i]);
        }
        return totalUnclaimedRewards;
    }

    function getLastClaimedTime(uint256 _tokenId) public view returns (uint256) {
        return lastClaim[_tokenId];
    }

    function computeAccumulatedReward(
        uint256 _lastClaimDate,
        uint256 _baseRate,
        uint256 currentTime
    ) internal pure returns (uint256) {
        require(
            currentTime > _lastClaimDate,
            "Last claim date must be smaller than block timestamp"
        );

        uint256 secondsElapsed = currentTime - _lastClaimDate;
        uint256 accumulatedReward = (secondsElapsed * _baseRate) / 1 days;

        return accumulatedReward;
    }

    function computeUnclaimedReward(uint256 _tokenId) internal view returns (uint256) {
        YAKUZA_GEN.ownerOf(_tokenId);

        uint256 lastClaimDate = lastClaim[_tokenId];

        if (lastClaimDate != uint256(0)) {
            return computeAccumulatedReward(lastClaimDate, BASE_RATE, block.timestamp);
        } else if (block.timestamp < endTime) {
            uint256 totalReward = computeAccumulatedReward(startTime, BASE_RATE, block.timestamp);
            return totalReward;
        } else {
            uint256 totalReward = computeAccumulatedReward(lastClaimDate, BASE_RATE, endTime);
            return totalReward;
        }
    }

    /*==============================================================
    ==                    Only Owner Functions                    ==
    ==============================================================*/

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function setYakuzaElite(address yakuzaEliteAddress) external onlyOwner {
        yakuzaElite = yakuzaEliteAddress;
    }

    function startYield() external onlyOwner {
        startTime = block.timestamp;
        endTime = block.timestamp + 730 days;
    }

    function stopAllDrips() external onlyOwner {
        require(block.timestamp > endTime, "Cannot stop the drip yet.");
        for (uint256 i; i < accruers.length; i++) {
            address _addr = accruers[i];
            _stopDripping(_addr, _accruers[_addr].multiplier);
        }
    }

    function toggleClaim() external onlyOwner {
        claimAllowed = !claimAllowed;
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
pragma solidity ^0.8.0;

///@author 0xBeans
///@notice This is a beefed up ERC20 implementation of DRIP20 that supports emission multipliers.
///@notice Multipliers are useful when certain users should accrue larger emissions. For example,
///@notice if an NFT drips 10 tokens per block to a user, and the user has 3 NFTs, then the user
///@notice should accrue 3 times as many tokens per block. This user would have a multiplier of 3.
///@notice shout out to solmate (@t11s) for the slim and efficient ERC20 implementation!
///@notice shout out to superfluid and UBI for the dripping inspiration!
abstract contract GIGADRIP20 {
    /*==============================================================
    ==                            ERRORS                          ==
    ==============================================================*/

    error UserNotAccruing();
    error ERC20_TransferToZeroAddress();

    /*==============================================================
    ==                            EVENTS                          ==
    ==============================================================*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );

    /*==============================================================
    ==                      METADATA STORAGE                      ==
    ==============================================================*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*==============================================================
    ==                       ERC20 STORAGE                        ==
    ==============================================================*/

    mapping(address => mapping(address => uint256)) public allowance;

    /*==============================================================
    ==                        DRIP STORAGE                        ==
    ==============================================================*/

    struct Accruer {
        uint256 balance;
        uint128 accrualStartBlock;
        uint128 multiplier;
    }

    // immutable token emission rate per block
    uint256 public immutable emissionRatePerBlock;

    // wallets currently getting dripped tokens
    mapping(address => Accruer) public _accruers;

    // these are all for calculating totalSupply()
    uint256 private _currAccrued;
    uint128 private _currEmissionBlockNum;
    uint128 private _currEmissionMultiple;

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _emissionRatePerBlock
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        emissionRatePerBlock = _emissionRatePerBlock;
    }

    /*==============================================================
    ==                        ERC20 IMPL                          ==
    ==============================================================*/

    function approve(address spender, uint256 amount)
        public
        virtual
        returns (bool)
    {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount)
        public
        virtual
        returns (bool)
    {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender];

        if (allowed != type(uint256).max)
            allowance[from][msg.sender] = allowed - amount;

        _transfer(from, to, amount);

        return true;
    }

    function balanceOf(address addr) public view returns (uint256) {
        Accruer memory accruer = _accruers[addr];

        if (accruer.accrualStartBlock == 0) {
            return accruer.balance;
        }

        return
            ((block.number - accruer.accrualStartBlock) *
                emissionRatePerBlock) *
            accruer.multiplier +
            accruer.balance;
    }

    function totalSupply() public view returns (uint256) {
        return
            _currAccrued +
            (block.number - _currEmissionBlockNum) *
            emissionRatePerBlock *
            _currEmissionMultiple;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        if (to == address(0)) revert ERC20_TransferToZeroAddress();

        Accruer storage fromAccruer = _accruers[from];
        Accruer storage toAccruer = _accruers[to];

        fromAccruer.balance = balanceOf(from) - amount;

        unchecked {
            toAccruer.balance += amount;
        }

        if (fromAccruer.accrualStartBlock != 0) {
            fromAccruer.accrualStartBlock = uint128(block.number);
        }

        emit Transfer(from, to, amount);
    }

    /*==============================================================
    ==                        DRIP LOGIC                          ==
    ==============================================================*/

    /**
     * @dev Add an address to start dripping tokens to.
     * @dev We need to update _currAccrued whenever we add a new dripper or INCREASE a dripper multiplier to properly update totalSupply()
     * @dev IMPORTANT: Everytime you call this with an addr already getting dripped to, it will INCREASE the multiplier
     * @param addr address to drip to
     * @param multiplier used to increase token drip. ie if 1 NFT drips 10 tokens per block and this address has 3 NFTs,
     * the user would need to get dripped 30 tokens per block - multipler would multiply emissions by 3
     */
    function _startDripping(address addr, uint128 multiplier) internal virtual {
        Accruer storage accruer = _accruers[addr];

        // need to update the balance if wallet was already accruing
        if (accruer.accrualStartBlock != 0) {
            accruer.balance = balanceOf(addr);
        } else {
            // emit Transfer event when new address starts dripping
            emit Transfer(address(0), addr, 0);
        }

        _currAccrued = totalSupply();
        _currEmissionBlockNum = uint128(block.number);
        accruer.accrualStartBlock = uint128(block.number);

        // should not overflow unless you have >2**256-1 items...
        unchecked {
            _currEmissionMultiple += multiplier;
            accruer.multiplier += multiplier;
        }
    }

    /**
     * @dev Add an address to stop dripping tokens to.
     * @dev We need to update _currAccrued whenever we remove a dripper or DECREASE a dripper multiplier to properly update totalSupply()
     * @dev IMPORTANT: Everytime you call this with an addr already getting dripped to, it will DECREASE the multiplier
     * @dev IMPORTANT: Decrease the multiplier to 0 to completely stop the address from getting dripped to
     * @param addr address to stop dripping to
     * @param multiplier used to decrease token drip. ie if addr has a multiplier of 3 already, passing in a value of 1 would decrease
     * the multiplier to 2
     */
    function _stopDripping(address addr, uint128 multiplier) internal virtual {
        Accruer storage accruer = _accruers[addr];

        // should I check for 0 multiplier too
        if (accruer.accrualStartBlock == 0) revert UserNotAccruing();

        accruer.balance = balanceOf(addr);
        _currAccrued = totalSupply();
        _currEmissionBlockNum = uint128(block.number);

        // will revert if underflow occurs
        _currEmissionMultiple -= multiplier;
        accruer.multiplier -= multiplier;

        if (accruer.multiplier == 0) {
            accruer.accrualStartBlock = 0;
        } else {
            accruer.accrualStartBlock = uint128(block.number);
        }
    }

    /*==============================================================
    ==                         MINT/BURN                          ==
    ==============================================================*/

    function _mint(address to, uint256 amount) internal virtual {
        Accruer storage accruer = _accruers[to];

        unchecked {
            _currAccrued += amount;
            accruer.balance += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        Accruer storage accruer = _accruers[from];

        // have to update supply before burning
        _currAccrued = totalSupply();
        _currEmissionBlockNum = uint128(block.number);

        accruer.balance = balanceOf(from) - amount;

        // Cannot underflow because amount can
        // never be greater than the totalSupply()
        unchecked {
            _currAccrued -= amount;
        }

        // update accruers block number if user was accruing
        if (accruer.accrualStartBlock != 0) {
            accruer.accrualStartBlock = uint128(block.number);
        }

        emit Transfer(from, address(0), amount);
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