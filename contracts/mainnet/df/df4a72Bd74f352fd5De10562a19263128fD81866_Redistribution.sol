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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

interface IAliceNetFactory {
    function lookup(bytes32 salt_) external view returns (address);
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

interface IERC20Transferable {
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

interface IMagicEthTransfer {
    function depositEth(uint8 magic_) external payable;
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

interface IStakingNFT {
    function skimExcessEth(address to_) external returns (uint256 excess);

    function skimExcessToken(address to_) external returns (uint256 excess);

    function depositToken(uint8 magic_, uint256 amount_) external;

    function depositEth(uint8 magic_) external payable;

    function lockPosition(
        address caller_,
        uint256 tokenID_,
        uint256 lockDuration_
    ) external returns (uint256);

    function lockOwnPosition(uint256 tokenID_, uint256 lockDuration_) external returns (uint256);

    function lockWithdraw(uint256 tokenID_, uint256 lockDuration_) external returns (uint256);

    function mint(uint256 amount_) external returns (uint256 tokenID);

    function mintTo(
        address to_,
        uint256 amount_,
        uint256 lockDuration_
    ) external returns (uint256 tokenID);

    function burn(uint256 tokenID_) external returns (uint256 payoutEth, uint256 payoutALCA);

    function burnTo(
        address to_,
        uint256 tokenID_
    ) external returns (uint256 payoutEth, uint256 payoutALCA);

    function collectEth(uint256 tokenID_) external returns (uint256 payout);

    function collectToken(uint256 tokenID_) external returns (uint256 payout);

    function collectAllProfits(
        uint256 tokenID_
    ) external returns (uint256 payoutToken, uint256 payoutEth);

    function collectEthTo(address to_, uint256 tokenID_) external returns (uint256 payout);

    function collectTokenTo(address to_, uint256 tokenID_) external returns (uint256 payout);

    function collectAllProfitsTo(
        address to_,
        uint256 tokenID_
    ) external returns (uint256 payoutToken, uint256 payoutEth);

    function getPosition(
        uint256 tokenID_
    )
        external
        view
        returns (
            uint256 shares,
            uint256 freeAfter,
            uint256 withdrawFreeAfter,
            uint256 accumulatorEth,
            uint256 accumulatorToken
        );

    function getTotalShares() external view returns (uint256);

    function getTotalReserveEth() external view returns (uint256);

    function getTotalReserveALCA() external view returns (uint256);

    function estimateEthCollection(uint256 tokenID_) external view returns (uint256 payout);

    function estimateTokenCollection(uint256 tokenID_) external view returns (uint256 payout);

    function estimateAllProfits(
        uint256 tokenID_
    ) external view returns (uint256 payoutEth, uint256 payoutToken);

    function estimateExcessToken() external view returns (uint256 excess);

    function estimateExcessEth() external view returns (uint256 excess);

    function getEthAccumulator() external view returns (uint256 accumulator, uint256 slush);

    function getTokenAccumulator() external view returns (uint256 accumulator, uint256 slush);

    function getLatestMintedPositionID() external view returns (uint256);

    function getAccumulatorScaleFactor() external pure returns (uint256);

    function getMaxMintLock() external pure returns (uint256);

    function getMaxGovernanceLock() external pure returns (uint256);
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

library ERC20SafeTransferErrors {
    error CannotCallContractMethodsOnZeroAddress();
    error Erc20TransferFailed(address erc20Address, address from, address to, uint256 amount);
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

library MagicValueErrors {
    error BadMagic(uint256 magic);
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "contracts/utils/auth/ImmutableALCA.sol";
import "contracts/utils/auth/ImmutablePublicStaking.sol";
import "contracts/utils/auth/ImmutableFoundation.sol";
import "contracts/interfaces/IStakingNFT.sol";
import "contracts/utils/ERC20SafeTransfer.sol";
import "contracts/utils/MagicEthTransfer.sol";

contract Redistribution is
    ImmutableALCA,
    ImmutablePublicStaking,
    ImmutableFoundation,
    ERC20SafeTransfer,
    MagicEthTransfer
{
    struct accountInfo {
        uint248 balance;
        bool isPositionTaken;
    }

    event Withdrawn(address indexed user, uint256 amount);
    event TokenAlreadyTransferred();

    error NotOperator();
    error WithdrawalWindowExpired();
    error WithdrawalWindowNotExpiredYet();
    error IncorrectLength();
    error ZeroAmountNotAllowed();
    error InvalidAllowanceSum(uint256 totalAllowance, uint256 maxRedistributionAmount);
    error DistributionTokenAlreadyCreated();
    error PositionAlreadyRegisteredOrTaken();
    error InvalidDistributionAmount(uint256 amount, uint256 maxAllowed);
    error NotEnoughFundsToRedistribute(uint256 withdrawAmount, uint256 currentAmount);
    error PositionAlreadyTakenOrInexistent();

    /// The amount of blocks that the withdraw position will be locked against burning.
    uint256 public constant MAX_MINT_LOCK = 1051200;
    /// The total amount of ALCA that can be redistributed to accounts via this contract.
    uint256 public immutable maxRedistributionAmount;
    /// The block number that the withdrawal window will expire.
    uint256 public immutable expireBlock;
    /// The address of the operator of the contract. The operator will be able to register new
    /// accounts that will have rights to withdraw funds.
    address public operator;
    /// The amount from the `maxRedistributionAmount` already reserved for distribution.
    uint256 public totalAllowances;
    /// The current tokenID of the public staking position that holds the ALCA to be distributed.
    uint256 public tokenID;
    mapping(address => accountInfo) internal _accounts;

    modifier onlyOperator() {
        if (msg.sender != operator) {
            revert NotOperator();
        }
        _;
    }

    modifier notExpired() {
        if (block.number > expireBlock) {
            revert WithdrawalWindowExpired();
        }
        _;
    }

    /**
     * @notice This function is used to receive ETH from the public staking contract.
     */
    receive() external payable onlyPublicStaking {}

    constructor(
        uint256 withdrawalBlockWindow,
        uint256 maxRedistributionAmount_,
        address[] memory allowedAddresses,
        uint248[] memory allowedAmounts
    ) ImmutableFactory(msg.sender) ImmutableALCA() ImmutablePublicStaking() ImmutableFoundation() {
        if (allowedAddresses.length != allowedAmounts.length || allowedAddresses.length == 0) {
            revert IncorrectLength();
        }
        uint256 totalAllowance = 0;
        for (uint256 i = 0; i < allowedAddresses.length; i++) {
            if (allowedAddresses[i] == address(0) || _accounts[allowedAddresses[i]].balance > 0) {
                revert PositionAlreadyRegisteredOrTaken();
            }
            if (allowedAmounts[i] == 0) {
                revert ZeroAmountNotAllowed();
            }
            _accounts[allowedAddresses[i]] = accountInfo(allowedAmounts[i], false);
            totalAllowance += allowedAmounts[i];
        }
        if (totalAllowance > maxRedistributionAmount_) {
            revert InvalidAllowanceSum(totalAllowance, maxRedistributionAmount_);
        }
        maxRedistributionAmount = maxRedistributionAmount_;
        totalAllowances = totalAllowance;
        expireBlock = block.number + withdrawalBlockWindow;
    }

    /**
     * @notice Set a new operator for the contract. This function can only be called by the factory.
     * @param operator_ The new operator address.
     */
    function setOperator(address operator_) public onlyFactory {
        operator = operator_;
    }

    /**
     * @notice Creates the total staked position for the redistribution. This function can only be
     * called by the factory. This function can only be called if the withdrawal window has not expired
     * yet.
     * @dev the maxRedistributionAmount should be approved to this contract before calling this
     * function.
     */
    function createRedistributionStakedPosition() public onlyFactory notExpired {
        if (tokenID != 0) {
            revert DistributionTokenAlreadyCreated();
        }
        _safeTransferFromERC20(
            IERC20Transferable(_alcaAddress()),
            msg.sender,
            maxRedistributionAmount
        );
        // approve the staking contract to transfer the ALCA
        IERC20(_alcaAddress()).approve(_publicStakingAddress(), maxRedistributionAmount);
        tokenID = IStakingNFT(_publicStakingAddress()).mint(maxRedistributionAmount);
    }

    /**
     * @notice register an new address for a distribution amount. This function can only be called
     * by the operator. The distribution amount can not be greater that the total amount left for
     * distribution. Only one amount can be registered per address. Amount for already registered
     * addresses cannot be changed.
     * @dev This function can only be called if the withdrawal window has not expired yet.
     * @param user The address to register for distribution.
     * @param distributionAmount The amount to register for distribution.
     */
    function registerAddressForDistribution(
        address user,
        uint248 distributionAmount
    ) public onlyOperator notExpired {
        if (distributionAmount == 0) {
            revert ZeroAmountNotAllowed();
        }
        accountInfo memory account = _accounts[user];
        if (account.balance > 0 || account.isPositionTaken) {
            revert PositionAlreadyRegisteredOrTaken();
        }
        uint256 distributionLeft = _getDistributionLeft();
        if (distributionAmount > distributionLeft) {
            revert InvalidDistributionAmount(distributionAmount, distributionLeft);
        }
        _accounts[user] = accountInfo(distributionAmount, false);
        totalAllowances += distributionAmount;
    }

    /**
     *  @notice Withdraw the staked position to the user's address. It will burn the Public
     *  Staking position held by this contract and mint a new one to the user's address with the
     *  owned amount and in case there is a remainder, it will mint a new position to this contract.
     *  THE CALLER OF THIS FUNCTION MUST BE AN EOA (EXTERNAL OWNED ACCOUNT) OR PROXY WALLET THAT
     *  ACCEPTS AND HANDLE ERC721 POSITIONS. BEWARE IF THIS REQUIREMENTS ARE NOT FOLLOWED, THE
     *  POSITION CAN BE FOREVER LOST.
     *  @dev This function can only be called by the user that has the right to withdraw a staked
     *  position. This function can only be called if the withdrawal window has not expired yet.
     *  @param to The address to send the staked position to.
     */
    function withdrawStakedPosition(address to) public notExpired {
        accountInfo memory account = _accounts[msg.sender];
        if (account.balance == 0 || account.isPositionTaken) {
            revert PositionAlreadyTakenOrInexistent();
        }
        _accounts[msg.sender] = accountInfo(0, true);
        IStakingNFT staking = IStakingNFT(_publicStakingAddress());
        IERC20 alca = IERC20(_alcaAddress());
        staking.burn(tokenID);
        uint256 alcaBalance = alca.balanceOf(address(this));
        if (alcaBalance < account.balance) {
            revert NotEnoughFundsToRedistribute(alcaBalance, account.balance);
        }
        alca.approve(_publicStakingAddress(), alcaBalance);
        staking.mintTo(to, account.balance, MAX_MINT_LOCK);
        uint256 remainder = alcaBalance - account.balance;
        if (remainder > 0) {
            tokenID = staking.mint(remainder);
        }
        // send any eth balance collected to the foundation
        uint256 ethBalance = address(this).balance;
        if (ethBalance > 0) {
            _safeTransferEthWithMagic(IMagicEthTransfer(_foundationAddress()), ethBalance);
        }
        emit Withdrawn(msg.sender, account.balance);
    }

    /**
     *  @notice Send any remaining funds that were not claimed during the valid time back to the
     *  factory. It will transfer the Public Staking position (in case it exists) and any ALCA back
     *  to the Factory. Ether will be send to the foundation.
     *  @dev This function can only be called by the AliceNet factory. This function never fails and
     *  can act as a skim of ether and ALCA.
     *  function never fails.
     */
    function sendExpiredFundsToFactory() public onlyFactory {
        if (block.number <= expireBlock) {
            revert WithdrawalWindowNotExpiredYet();
        }
        try
            IERC721(_publicStakingAddress()).transferFrom(address(this), _factoryAddress(), tokenID)
        {} catch {
            emit TokenAlreadyTransferred();
        }
        uint256 alcaBalance = IERC20(_alcaAddress()).balanceOf(address(this));
        if (alcaBalance > 0) {
            _safeTransferERC20(IERC20Transferable(_alcaAddress()), _factoryAddress(), alcaBalance);
        }
        uint256 ethBalance = address(this).balance;
        if (ethBalance > 0) {
            _safeTransferEthWithMagic(IMagicEthTransfer(_foundationAddress()), ethBalance);
        }
    }

    /**
     * @notice Returns the account info for a given user
     * @param user The address of the user
     */
    function getRedistributionInfo(address user) public view returns (accountInfo memory account) {
        account = _accounts[user];
    }

    /**
     * @notice Returns the amount of ALCA left to distribute
     */
    function getDistributionLeft() public view returns (uint256) {
        return _getDistributionLeft();
    }

    // internal function to get the amount of ALCA left to distribute
    function _getDistributionLeft() internal view returns (uint256) {
        return maxRedistributionAmount - totalAllowances;
    }
}

// This file is auto-generated by hardhat generate-immutable-auth-contract task. DO NOT EDIT.
// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/utils/DeterministicAddress.sol";
import "contracts/utils/auth/ImmutableFactory.sol";
import "contracts/interfaces/IAliceNetFactory.sol";

abstract contract ImmutableALCA is ImmutableFactory {
    address private immutable _alca;
    error OnlyALCA(address sender, address expected);

    modifier onlyALCA() {
        if (msg.sender != _alca) {
            revert OnlyALCA(msg.sender, _alca);
        }
        _;
    }

    constructor() {
        _alca = IAliceNetFactory(_factoryAddress()).lookup(_saltForALCA());
    }

    function _alcaAddress() internal view returns (address) {
        return _alca;
    }

    function _saltForALCA() internal pure returns (bytes32) {
        return 0x414c434100000000000000000000000000000000000000000000000000000000;
    }
}

// This file is auto-generated by hardhat generate-immutable-auth-contract task. DO NOT EDIT.
// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/utils/DeterministicAddress.sol";

abstract contract ImmutableFactory is DeterministicAddress {
    address private immutable _factory;
    error OnlyFactory(address sender, address expected);

    modifier onlyFactory() {
        if (msg.sender != _factory) {
            revert OnlyFactory(msg.sender, _factory);
        }
        _;
    }

    constructor(address factory_) {
        _factory = factory_;
    }

    function _factoryAddress() internal view returns (address) {
        return _factory;
    }
}

// This file is auto-generated by hardhat generate-immutable-auth-contract task. DO NOT EDIT.
// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/utils/DeterministicAddress.sol";
import "contracts/utils/auth/ImmutableFactory.sol";

abstract contract ImmutableFoundation is ImmutableFactory {
    address private immutable _foundation;
    error OnlyFoundation(address sender, address expected);

    modifier onlyFoundation() {
        if (msg.sender != _foundation) {
            revert OnlyFoundation(msg.sender, _foundation);
        }
        _;
    }

    constructor() {
        _foundation = getMetamorphicContractAddress(
            0x466f756e646174696f6e00000000000000000000000000000000000000000000,
            _factoryAddress()
        );
    }

    function _foundationAddress() internal view returns (address) {
        return _foundation;
    }

    function _saltForFoundation() internal pure returns (bytes32) {
        return 0x466f756e646174696f6e00000000000000000000000000000000000000000000;
    }
}

// This file is auto-generated by hardhat generate-immutable-auth-contract task. DO NOT EDIT.
// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/utils/DeterministicAddress.sol";
import "contracts/utils/auth/ImmutableFactory.sol";

abstract contract ImmutablePublicStaking is ImmutableFactory {
    address private immutable _publicStaking;
    error OnlyPublicStaking(address sender, address expected);

    modifier onlyPublicStaking() {
        if (msg.sender != _publicStaking) {
            revert OnlyPublicStaking(msg.sender, _publicStaking);
        }
        _;
    }

    constructor() {
        _publicStaking = getMetamorphicContractAddress(
            0x5075626c69635374616b696e6700000000000000000000000000000000000000,
            _factoryAddress()
        );
    }

    function _publicStakingAddress() internal view returns (address) {
        return _publicStaking;
    }

    function _saltForPublicStaking() internal pure returns (bytes32) {
        return 0x5075626c69635374616b696e6700000000000000000000000000000000000000;
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

abstract contract DeterministicAddress {
    function getMetamorphicContractAddress(
        bytes32 _salt,
        address _factory
    ) public pure returns (address) {
        // byte code for metamorphic contract
        // 6020363636335afa1536363636515af43d36363e3d36f3
        bytes32 metamorphicContractBytecodeHash_ = 0x1c0bf703a3415cada9785e89e9d70314c3111ae7d8e04f33bb42eb1d264088be;
        return
            address(
                uint160(
                    uint256(
                        keccak256(
                            abi.encodePacked(
                                hex"ff",
                                _factory,
                                _salt,
                                metamorphicContractBytecodeHash_
                            )
                        )
                    )
                )
            );
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/interfaces/IERC20Transferable.sol";
import "contracts/libraries/errors/ERC20SafeTransferErrors.sol";

abstract contract ERC20SafeTransfer {
    // _safeTransferFromERC20 performs a transferFrom call against an erc20 contract in a safe manner
    // by reverting on failure
    // this function will return without performing a call or reverting
    // if amount_ is zero
    function _safeTransferFromERC20(
        IERC20Transferable contract_,
        address sender_,
        uint256 amount_
    ) internal {
        if (amount_ == 0) {
            return;
        }
        if (address(contract_) == address(0x0)) {
            revert ERC20SafeTransferErrors.CannotCallContractMethodsOnZeroAddress();
        }

        bool success = contract_.transferFrom(sender_, address(this), amount_);
        if (!success) {
            revert ERC20SafeTransferErrors.Erc20TransferFailed(
                address(contract_),
                sender_,
                address(this),
                amount_
            );
        }
    }

    // _safeTransferERC20 performs a transfer call against an erc20 contract in a safe manner
    // by reverting on failure
    // this function will return without performing a call or reverting
    // if amount_ is zero
    function _safeTransferERC20(
        IERC20Transferable contract_,
        address to_,
        uint256 amount_
    ) internal {
        if (amount_ == 0) {
            return;
        }
        if (address(contract_) == address(0x0)) {
            revert ERC20SafeTransferErrors.CannotCallContractMethodsOnZeroAddress();
        }
        bool success = contract_.transfer(to_, amount_);
        if (!success) {
            revert ERC20SafeTransferErrors.Erc20TransferFailed(
                address(contract_),
                address(this),
                to_,
                amount_
            );
        }
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/utils/MagicValue.sol";
import "contracts/interfaces/IMagicEthTransfer.sol";

abstract contract MagicEthTransfer is MagicValue {
    function _safeTransferEthWithMagic(IMagicEthTransfer to_, uint256 amount_) internal {
        to_.depositEth{value: amount_}(_getMagic());
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;
import "contracts/libraries/errors/MagicValueErrors.sol";

abstract contract MagicValue {
    // _MAGIC_VALUE is a constant that may be used to prevent
    // a user from calling a dangerous method without significant
    // effort or ( hopefully ) reading the code to understand the risk
    uint8 internal constant _MAGIC_VALUE = 42;

    modifier checkMagic(uint8 magic_) {
        if (magic_ != _getMagic()) {
            revert MagicValueErrors.BadMagic(magic_);
        }
        _;
    }

    // _getMagic returns the magic constant
    function _getMagic() internal pure returns (uint8) {
        return _MAGIC_VALUE;
    }
}