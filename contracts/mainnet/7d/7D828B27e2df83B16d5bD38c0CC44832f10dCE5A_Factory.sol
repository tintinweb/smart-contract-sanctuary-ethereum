pragma solidity =0.8.7;

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Clones } from "@openzeppelin/contracts/proxy/Clones.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IAuction.sol";
import "./interfaces/IBasket.sol";
import "./interfaces/IFactory.sol";

contract Factory is IFactory, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    uint256 private constant BASE = 1e18;
    uint256 public constant TIMELOCK_DURATION = 5 days;


    constructor (IAuction _auctionImpl, IBasket _basketImpl) {
        auctionImpl = _auctionImpl;
        basketImpl = _basketImpl;
    }

    Proposal[] private _proposals;

    IAuction public override auctionImpl;
    IBasket public override basketImpl;

    uint256 public override minLicenseFee = 1e15; // 1e15 0.1%
    uint256 public override auctionDecrement = 10000;
    uint256 public override auctionMultiplier = 2;
    uint256 public override bondPercentDiv = 400;
    
    PendingChange public pendingMinLicenseFee;
    PendingChange public pendingAuctionDecrement;
    PendingChange public pendingAuctionMultiplier;
    PendingChange public pendingBondPercentDiv;

    uint256 public override ownerSplit;
    PendingChange public pendingOwnerSplit;

    function proposal(uint256 proposalId) external override view returns (Proposal memory) {
        return _proposals[proposalId];
    }

    function proposals(uint256[] memory _ids) external override view returns (Proposal[] memory) {
        uint256 numIds = _ids.length;
        Proposal[] memory returnProps = new Proposal[](numIds);

        for (uint256 i = 0; i < numIds; i++) {
            returnProps[i] = _proposals[_ids[i]];
        }

        return returnProps;
    }

    function proposalsLength() external override view returns(uint256) {
        return _proposals.length;
    }

    function setMinLicenseFee(uint256 newMinLicenseFee) public override onlyOwner {
        if (pendingMinLicenseFee.change != 0 && pendingMinLicenseFee.change == newMinLicenseFee) {
            require(block.timestamp >= pendingMinLicenseFee.timestamp + TIMELOCK_DURATION);
            minLicenseFee = newMinLicenseFee;

            pendingMinLicenseFee.change = 0;

            emit ChangedMinLicenseFee(newMinLicenseFee);
        } else {
            pendingMinLicenseFee.change = newMinLicenseFee;
            pendingMinLicenseFee.timestamp = block.timestamp;

            emit NewMinLicenseFeeSubmitted(newMinLicenseFee);
        }
    }

    function setAuctionDecrement(uint256 newAuctionDecrement) public override onlyOwner {
        if (pendingAuctionDecrement.change != 0 && pendingAuctionDecrement.change == newAuctionDecrement) {
            require(block.timestamp >= pendingAuctionDecrement.timestamp + TIMELOCK_DURATION);
            auctionDecrement = newAuctionDecrement;

            pendingAuctionDecrement.change = 0;

            emit ChangedAuctionDecrement(newAuctionDecrement);
        } else {
            pendingAuctionDecrement.change = newAuctionDecrement;
            pendingAuctionDecrement.timestamp = block.timestamp;

            emit NewAuctionDecrementSubmitted(newAuctionDecrement);
        }
    }

    function setAuctionMultiplier(uint256 newAuctionMultiplier) public override onlyOwner {
        if (pendingAuctionMultiplier.change != 0 && pendingAuctionMultiplier.change == newAuctionMultiplier) {
            require(block.timestamp >= pendingAuctionMultiplier.timestamp + TIMELOCK_DURATION);
            auctionMultiplier = newAuctionMultiplier;

            pendingAuctionMultiplier.change = 0;

            emit ChangedAuctionMultipler(newAuctionMultiplier);
        } else {
            pendingAuctionMultiplier.change = newAuctionMultiplier;
            pendingAuctionMultiplier.timestamp = block.timestamp;

            emit NewAuctionMultiplierSubmitted(newAuctionMultiplier);
        }
    }

    function setBondPercentDiv(uint256 newBondPercentDiv) public override onlyOwner {
        if (pendingBondPercentDiv.change != 0 && pendingBondPercentDiv.change == newBondPercentDiv) {
            require(block.timestamp >= pendingBondPercentDiv.timestamp + TIMELOCK_DURATION);
            bondPercentDiv = newBondPercentDiv;

            pendingBondPercentDiv.change = 0;

            emit ChangedBondPercentDiv(newBondPercentDiv);
        } else {
            pendingBondPercentDiv.change = newBondPercentDiv;
            pendingBondPercentDiv.timestamp = block.timestamp;

            emit NewBondPercentDivSubmitted(newBondPercentDiv);
        }
    }

    function setOwnerSplit(uint256 newOwnerSplit) public override onlyOwner {
        require(newOwnerSplit <= 2e17);
        if (pendingOwnerSplit.change != 0 && pendingOwnerSplit.change == newOwnerSplit) {
            require(block.timestamp >= pendingOwnerSplit.timestamp + TIMELOCK_DURATION);
            ownerSplit = newOwnerSplit;

            pendingOwnerSplit.change = 0;

            emit ChangedOwnerSplit(newOwnerSplit);
        } else {
            pendingOwnerSplit.change = newOwnerSplit;
            pendingOwnerSplit.timestamp = block.timestamp;

            emit NewOwnerSplitSubmitted(newOwnerSplit);
        }
    }

    function getProposalWeights(uint256 id) external override view returns (address[] memory, uint256[] memory) {
        return (_proposals[id].tokens, _proposals[id].weights);
    }

    function proposeBasketLicense(
        uint256 licenseFee, 
        string memory tokenName, 
        string memory tokenSymbol, 
        address[] memory tokens,
        uint256[] memory weights,
        uint256 maxSupply
    ) public override returns (uint256 id) {
        basketImpl.validateWeights(tokens, weights);

        require(licenseFee >= minLicenseFee);

        // create proposal object
        Proposal memory newProposal = Proposal({
            licenseFee: licenseFee,
            tokenName: tokenName,
            tokenSymbol: tokenSymbol,
            proposer: address(msg.sender),
            tokens: tokens,
            weights: weights,
            basket: address(0),
            maxSupply: maxSupply
        });

        _proposals.push(newProposal);
        emit BasketLicenseProposed(msg.sender, tokenName, _proposals.length - 1);

        return _proposals.length - 1;
    }

    function createBasket(uint256 idNumber) external override nonReentrant returns (IBasket) {
        Proposal memory bProposal = _proposals[idNumber];
        require(bProposal.basket == address(0));

        IAuction newAuction = IAuction(Clones.clone(address(auctionImpl)));
        IBasket newBasket = IBasket(Clones.clone(address(basketImpl)));

        _proposals[idNumber].basket = address(newBasket);

        newAuction.initialize(address(newBasket), address(this));
        newBasket.initialize(bProposal, newAuction);

        for (uint256 i = 0; i < bProposal.weights.length; i++) {
            IERC20 token = IERC20(bProposal.tokens[i]);
            token.safeTransferFrom(msg.sender, address(this), bProposal.weights[i]);
            token.safeApprove(address(newBasket), 0);
            token.safeApprove(address(newBasket), bProposal.weights[i]);
        }

        newBasket.mintTo(BASE, msg.sender);

        emit BasketCreated(address(newBasket), idNumber);

        return newBasket;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT

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
     * by making the `nonReentrant` function external, and make it call a
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

pragma solidity =0.8.7;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IBasket.sol";
import "./IFactory.sol";

interface IAuction {
    struct Bounty {
        address token;
        uint256 amount;
        bool active;
    }

    function startAuction() external;
    function bondForRebalance() external;
    function settleAuctionWithBond(
        uint256[] calldata,
        address[] calldata,
        uint256[] calldata,
        address[] calldata,
        uint256[] calldata
    ) external;
    function settleAuctionWithoutBond(
        uint256[] calldata,
        address[] calldata,
        uint256[] calldata,
        address[] calldata,
        uint256[] calldata
    ) external;
    function bondBurn() external;
    function killAuction() external;
    function endAuction() external;
    function addBounty(IERC20, uint256) external returns (uint256);
    function initialize(address, address) external;
    function initialized() external view returns (bool);
    function calcIbRatio(uint256 blockNum) external view returns (uint256);
    function getCurrentNewIbRatio() external view returns(uint256);

    function auctionOngoing() external view returns (bool);
    function auctionStart() external view returns (uint256);
    function hasBonded() external view returns (bool);
    function bondAmount() external view returns (uint256);
    function bondTimestamp() external view returns (uint256);
    function bondBlock() external view returns (uint256);

    function basket() external view returns (IBasket);
    function factory() external view returns (IFactory);
    function auctionBonder() external view returns (address);

    event AuctionStarted();
    event Bonded(address _bonder, uint256 _amount);
    event AuctionSettled(address _settler);
    event BondBurned(address _burned, address _burnee, uint256 _amount);
    event BountyAdded(IERC20 _token, uint256 _amount, uint256 _id);
    event BountyClaimed(address _claimer, address _token, uint256 _amount, uint256 _id);
}

pragma solidity =0.8.7;

import "./IAuction.sol";
import "./IFactory.sol";

interface IBasket {
    struct PendingPublisher {
        address publisher;
        uint256 timestamp;
    }

    struct PendingLicenseFee {
        uint256 licenseFee;
        uint256 timestamp;
    }

    struct PendingMaxSupply {
        uint256 maxSupply;
        uint256 timestamp;
    }

    struct PendingWeights {
        address[] tokens;
        uint256[] weights;
        uint256 timestamp;
        bool pending;
        uint256 minIbRatio;
    }

    function initialize(IFactory.Proposal memory, IAuction) external;
    function mint(uint256) external;
    function mintTo(uint256, address) external;
    function burn(uint256) external;
    function changePublisher(address) external;
    function changeLicenseFee(uint256) external;
    function setNewMaxSupply(uint256) external;
    function publishNewIndex(address[] calldata, uint256[] calldata, uint256) external;
    function deleteNewIndex() external;
    function auctionBurn(uint256) external;
    function updateIBRatio(uint256) external returns (uint256);
    function setNewWeights() external;
    function validateWeights(address[] memory, uint256[] memory) external pure;
    function initialized() external view returns (bool);

    function ibRatio() external view returns (uint256);
    function getPendingWeights() external view returns (address[] memory, uint256[] memory, uint256);
    function factory() external view returns (IFactory);
    function auction() external view returns (IAuction);
    function lastFee() external view returns (uint256);
    function publisher() external view returns (address);

    event Minted(address indexed _to, uint256 _amount);
    event Burned(address indexed _from, uint256 _amount);
    event ChangedPublisher(address indexed _newPublisher);
    event ChangedLicenseFee(uint256 _newLicenseFee);
    event NewPublisherSubmitted(address indexed _newPublisher);
    event NewLicenseFeeSubmitted(uint256 _newLicenseFee);
    event NewIndexSubmitted();
    event PublishedNewIndex(address _publisher);
    event DeletedNewIndex(address _sender);
    event WeightsSet();
    event NewIBRatio(uint256);
    event NewMaxSupplySubmitted(uint256 _newMaxSupply);
    event ChangedMaxSupply(uint256 _newMaxSupply);

}

pragma solidity =0.8.7;

import "./IBasket.sol";
import "./IAuction.sol";

interface IFactory {
    struct Proposal {
        uint256 licenseFee;
        string tokenName;
        string tokenSymbol;
        address proposer;
        address[] tokens;
        uint256[] weights;
        address basket;
        uint256 maxSupply;
    }

    struct PendingChange{
        uint256 change;
        uint256 timestamp;
    }


    function proposal(uint256) external view returns (Proposal memory);
    function proposals(uint256[] memory _ids) external view returns (Proposal[] memory); 
    function proposalsLength() external view returns (uint256);
    function minLicenseFee() external view returns (uint256);
    function auctionDecrement() external view returns (uint256);
    function auctionMultiplier() external view returns (uint256);
    function bondPercentDiv() external view returns (uint256);
    function ownerSplit() external view returns (uint256);
    function auctionImpl() external view returns (IAuction);
    function basketImpl() external view returns (IBasket);
    function getProposalWeights(uint256 id) external view returns (address[] memory, uint256[] memory);

    function createBasket(uint256) external returns (IBasket);
    function proposeBasketLicense(uint256, string calldata, string calldata, address[] memory tokens, uint256[] memory weights, uint256) external returns (uint256);
    function setMinLicenseFee(uint256) external;
    function setAuctionDecrement(uint256) external;
    function setAuctionMultiplier(uint256) external;
    function setBondPercentDiv(uint256) external;
    function setOwnerSplit(uint256) external;

    event BasketCreated(address indexed basket, uint256 id);
    event BasketLicenseProposed(address indexed proposer, string tokenName, uint256 indexed id);

    event NewMinLicenseFeeSubmitted(uint256);
    event ChangedMinLicenseFee(uint256);
    event NewAuctionDecrementSubmitted(uint256);
    event ChangedAuctionDecrement(uint256);
    event NewAuctionMultiplierSubmitted(uint256);
    event ChangedAuctionMultipler(uint256);
    event NewBondPercentDivSubmitted(uint256);
    event ChangedBondPercentDiv(uint256);
    event NewOwnerSplitSubmitted(uint256);
    event ChangedOwnerSplit(uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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