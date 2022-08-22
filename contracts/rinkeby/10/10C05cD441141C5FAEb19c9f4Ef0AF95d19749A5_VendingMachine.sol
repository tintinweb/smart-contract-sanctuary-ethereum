// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../Interfaces/IProptoCore.sol";
import "../Interfaces/IPTokenShared.sol";
import "../Structs/structs.sol";

contract VendingMachine is Ownable {
    address public ProptoCoreContract;

    address public paymentTokenContract;

    mapping(address => Goods) private shelves;

    constructor(address _paymentTokenContract) {
        paymentTokenContract = _paymentTokenContract;
    }

    function setProptoCoreContract(address contractAddress) public onlyOwner {
        ProptoCoreContract = contractAddress;
    }

    function getSellInfo(address tokenContract)
        public
        view
        returns (uint256[3] memory info)
    {
        address PTokenContract = CheckPTokenContract(tokenContract);
        info = [
            shelves[PTokenContract].price,
            shelves[PTokenContract].initialAmount,
            IERC20(PTokenContract).balanceOf(address(this))
        ];
    }

    function CheckPTokenContract(address tokenContract)
        public
        view
        returns (address PTokenContract)
    {
        uint256 VaultId = IPTokenShared(tokenContract).getVaultId();
        PTokenContract = IProptoCore(ProptoCoreContract).getPTokenContract(
            VaultId
        );
        require(tokenContract == PTokenContract, "not accepted tokenContract");
    }

    function sellOpen(
        address tokenContract,
        uint256 amount,
        uint256 price
    ) public {
        _preSellOpen(tokenContract, msg.sender);
        IERC20(tokenContract).transferFrom(msg.sender, address(this), amount);
        shelves[tokenContract] = Goods(msg.sender, price, amount);
    }

    function sellOpen(
        address owner,
        address tokenContract,
        uint256 price
    ) public onlyOwner {
        _preSellOpen(tokenContract, owner);
        uint256 amount = IERC20(tokenContract).balanceOf(address(this));
        require(amount > 0, "nothing to sell");
        shelves[tokenContract] = Goods(owner, price, amount);
    }

    function _preSellOpen(address tokenContract, address owner) public view {
        CheckPTokenContract(tokenContract);
        require(
            IPTokenShared(tokenContract).owner() == owner,
            "you are not token owner"
        );
        require(shelves[tokenContract].initialAmount == 0, "already initialed");
    }

    function sellClose(address tokenContract) public {
        address PTokenContract = CheckPTokenContract(tokenContract);

        require(shelves[PTokenContract].owner == msg.sender, "not your shelf");
        uint256 amountleft = IERC20(PTokenContract).balanceOf(address(this));
        require(amountleft > 0, "nothing left");
        IERC20(PTokenContract).transferFrom(
            address(this),
            shelves[PTokenContract].owner,
            amountleft
        );
    }

    function coinIntoSlot(address tokenContract, uint256 amount) public {
        address PTokenContract = CheckPTokenContract(tokenContract);

        uint256 price;

        require(
            IERC20(PTokenContract).balanceOf(address(this)) >= amount,
            "shelf quantity not enough to sell"
        );
        price = shelves[tokenContract].price * amount;

        IERC20(paymentTokenContract).transferFrom(
            msg.sender,
            address(this),
            price
        );
        IERC20(paymentTokenContract).transfer(
            shelves[tokenContract].owner,
            price
        );
        IERC20(PTokenContract).transferFrom(address(this), msg.sender, amount);
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

pragma solidity ^0.8.0;

interface IProptoCore {
    function easyCreatePToken(
        address[] memory tokens,
        uint256[] memory tokenIDs,
        uint256 vendingMachineAmount,
        uint256 initialPrice
    ) external;

    function createPToken(uint256 VaultId) external;

    function mintProptoEvent(
        uint256 VaultId,
        uint256 VRFMachineIndex,
        uint256 amount,
        uint256 startRange
    ) external;

    function calcMintProptoEventPayment(
        uint256 VaultId,
        uint256 VRFMachineIndex,
        uint256 amount
    ) external view returns (uint256);

    function verifiProptoEvent(uint256 tokenId) external;

    function ProptoEventVerificationStatusByVaultId(uint256 VaultId)
        external
        view
        returns (uint8 VStatus, uint256 VerifiedTokenId);

    function getPTokenContract(uint256 VaultId) external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IPTokenShared {
    function totalSupply() external view returns (uint256);

    function getVaultId() external view returns (uint256);

    function owner() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

struct PTokenInfo {
    uint256 VaultId;
    uint8 inVaultNum;
    address creator;
    address verifiedOwner;
    address PTokenContract;
}

struct proptoEventCustomIdGroup {
    address proptoEventContract;
    uint256 customId;
    uint256[] tokenIds;
    uint256[] insuranceAmounts;
    address[] beneficiaries;
    uint256[] reverseTokenIds;
    uint256[] reverseInsuranceAmounts;
    address[] reverseBeneficiaries;
}

struct incomingReservesDetail {
    uint256 amount;
    bool collected;
}

struct outgoingIPTokenDetail {
    uint256 amount;
    bool collected;
}

struct insurancePay {
    address proptoEventContract;
    uint256 tokenId;
    uint256 customId;
    uint256 insuranceAmount;
    address beneficiary;
    bool direction;
    uint8 collected;
}

struct RoundLockRangeUnit {
    uint256 rangeStart;
    uint256 rangeAmount;
}

struct RoundLockReservesBatchInfo {
    uint256 batchRangeTotal;
    uint256 batchLockedAmount;
    uint256 batchLockedMaximum;
    uint256 batchRangesUnitNum;
    uint256 dataIndex;
}

struct RoundLockReservesBatchData {
    mapping(uint256 => RoundLockRangeUnit) RoundLockRangeUnits;
}

struct RoundLockReserves {
    uint256 totalLockedAmount;
    mapping(uint256 => RoundLockReservesBatchInfo) batchInfos;
    mapping(uint256 => RoundLockReservesBatchData) batchDatas;
    uint256 batchesNum;
}

struct keyVerifications {
    uint256 pendingVerificationKeyNumbers;
    uint256 startRange;
    uint256[] tokenIds;
    uint256[] keys;
}

struct customIdVerification {
    uint256 VRFMachineIndex;
    uint256 VRFIndex;
}

struct inVaultNFTInfo {
    uint256 VaultId;
    uint8 nftIndex;
    address contractAddress;
    uint256 tokenId;
    bool redeemed;
}

struct VaultInfo {
    uint256 VaultId;
    uint8 inVaultNum;
    address owner;
    address creator;
    bool locked;
    mapping(uint8 => inVaultNFTInfo) inVaultNFTs;
}

struct Goods {
    address owner;
    uint256 price;
    uint256 initialAmount;
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