pragma solidity ^0.8.0;

import {IERC721Metadata} from "./../openzeppelin/token/ERC721/IERC721Metadata.sol";
import {IStaking} from "../../interfaces/IStaking.sol";
import {ITreasury} from "../../interfaces/ITreasury.sol";
import {IVault} from "../../interfaces/IVault.sol";
import {TokenVaultStakingProxy} from "./../proxy/TokenVaultStakingProxy.sol";
import {Constants} from "../../protocol/Constants.sol";
import {IERC20} from "../openzeppelin/token/ERC20/IERC20.sol";
import {DataTypes} from "../types/DataTypes.sol";
import {Errors} from "../helpers/Errors.sol";

library TokenVaultStakingLogic {
    //
    function newStakingInstance(
        address settings,
        address token,
        uint256 id,
        string memory name,
        string memory symbol,
        uint256 totalSupply
    ) external returns (address) {
        bytes memory _initializationCalldata = abi.encodeWithSignature(
            "initialize(string,string,uint256,address,uint256,uint256)",
            name,
            symbol,
            totalSupply,
            address(this),
            Constants.STAKING_TERM1_DURATION,
            Constants.STAKING_TERM2_DURATION
        );
        address staking = address(
            new TokenVaultStakingProxy(settings, _initializationCalldata)
        );
        return staking;
    }

    function addRewardToken(address staking, address token) external {
        IStaking(staking).addRewardToken(token);
    }

    /**
     * for estimate withdraw amount
     */
    function estimateWithdrawAmount(
        DataTypes.EstimateWithdrawAmountParams memory params
    ) external pure returns (uint256) {
        require(params.withdrawAmount > 0, "zero amount");
        uint256 tokenAmt = params.withdrawAmount;
        require(params.stakingAmount >= tokenAmt, "invalid amount balance");

        if (params.infoSharedPerToken == 0) {
            params.infoSharedPerToken = Constants.REWARD_PER_SHARE_PRECISION;
        }
        uint256 rewardAmt;
        if (params.poolId == 1) {
            rewardAmt =
                (
                    (tokenAmt *
                        (params.sharedPerToken1 - params.infoSharedPerToken))
                ) /
                Constants.REWARD_PER_SHARE_PRECISION;
        } else if (params.poolId == 2) {
            rewardAmt =
                (
                    (tokenAmt *
                        (params.sharedPerToken2 - params.infoSharedPerToken))
                ) /
                Constants.REWARD_PER_SHARE_PRECISION;
        }
        uint256 withdrawAmt = rewardAmt;
        if (address(params.withdrawToken) == address(params.stakingToken)) {
            withdrawAmt += tokenAmt;
        }
        return withdrawAmt;
    }

    function estimateNewSharedRewardAmount(
        DataTypes.EstimateNewSharedRewardAmount memory params
    )
        public
        pure
        returns (uint256 newSharedPerTokenPool1, uint256 newSharedPerTokenPool2)
    {
        if (params.poolBalance1 > 0 || params.poolBalance2 > 0) {
            if (params.newRewardAmt > 0) {
                uint256 sharedAmt = (params.newRewardAmt *
                    Constants.REWARD_PER_SHARE_PRECISION *
                    10000) /
                    (params.poolBalance1 *
                        params.ratio1 +
                        params.poolBalance2 *
                        params.ratio2);
                if (params.poolBalance1 > 0) {
                    uint256 sharedTotal1 = (params.poolBalance1 *
                        sharedAmt *
                        params.ratio1) / 10000;
                    newSharedPerTokenPool1 = (sharedTotal1 /
                        params.poolBalance1);
                }
                if (params.poolBalance2 > 0) {
                    uint256 sharedTotal2 = (params.poolBalance2 *
                        sharedAmt *
                        params.ratio2) / 10000;
                    newSharedPerTokenPool2 = (sharedTotal2 /
                        params.poolBalance2);
                }
            }
        }
        return (newSharedPerTokenPool1, newSharedPerTokenPool2);
    }

    function getSharedPerToken(DataTypes.GetSharedPerTokenParams memory params)
        external
        view
        returns (uint256 sharedPerToken1, uint256 sharedPerToken2)
    {
        sharedPerToken1 = params.sharedPerToken1;
        sharedPerToken2 = params.sharedPerToken2;
        uint256 principalBalance = params.poolBalance1 + params.poolBalance2;
        if (principalBalance > 0) {
            uint256 newBalance = params.token.balanceOf(address(this));
            // check staking token
            if (address(params.token) == address(params.stakingToken)) {
                require(
                    newBalance >= params.totalUserFToken,
                    Errors.VAULT_STAKING_INVALID_BALANCE
                );
                newBalance = newBalance - params.totalUserFToken;
                require(
                    newBalance >= principalBalance,
                    Errors.VAULT_STAKING_INVALID_BALANCE
                );
                newBalance -= principalBalance;
            }
            require(
                newBalance >= params.currentRewardBalance,
                Errors.VAULT_STAKING_INVALID_BALANCE
            );
            uint256 rewardAmt = newBalance - params.currentRewardBalance;
            uint256 poolSharedAmt;
            uint256 incomeSharedAmt;
            (poolSharedAmt, incomeSharedAmt, ) = ITreasury(
                IVault(params.stakingToken).treasury()
            ).getNewSharedToken(params.token);
            rewardAmt += (poolSharedAmt + incomeSharedAmt);
            if (rewardAmt > 0) {
                uint256 newSharedPerTokenPool1;
                uint256 newSharedPerTokenPool2;
                (
                    newSharedPerTokenPool1,
                    newSharedPerTokenPool2
                ) = estimateNewSharedRewardAmount(
                    DataTypes.EstimateNewSharedRewardAmount({
                        newRewardAmt: rewardAmt,
                        poolBalance1: params.poolBalance1,
                        ratio1: params.ratio1,
                        poolBalance2: params.poolBalance2,
                        ratio2: params.ratio2
                    })
                );
                if (newSharedPerTokenPool1 > 0) {
                    sharedPerToken1 += newSharedPerTokenPool1;
                }
                if (newSharedPerTokenPool2 > 0) {
                    sharedPerToken2 += newSharedPerTokenPool2;
                }
            }
        }
        return (sharedPerToken1, sharedPerToken2);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Constants {
    // uint256 constant DEPOSIT_BLOCK_AMOUNT = 10**18;
    uint256 constant REWARD_PER_SHARE_PRECISION = 10**24;

    // address constant WETH = 0xc778417E063141139Fce010982780140Aa0cD5Ab;  //ropsten
    // address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;  //mainet

    // MAINNET
    // uint256 constant STAKING_EPOCH_DURATION = 1 days;
    // uint256 constant STAKING_TERM1_DURATION = 26 * 7 * STAKING_EPOCH_DURATION;
    // uint256 constant STAKING_TERM2_DURATION = 52 * 7 * STAKING_EPOCH_DURATION;
    // uint256 constant VAULT_AUCTION_LENGTH = 7 days;
    // uint256 constant VAULT_AUCTION_EXTEND_LENGTH = 30 minutes;
    // uint256 constant VOTING_DEPLAY_BLOCK = 13090; //2 days
    // uint256 constant VOTING_PERIOD_BLOCK = 32727; //5 days

    // ROPSTEN
    uint256 constant STAKING_EPOCH_DURATION = 5 * 60 seconds;
    uint256 constant STAKING_TERM1_DURATION = 2 * STAKING_EPOCH_DURATION;
    uint256 constant STAKING_TERM2_DURATION = 4 * STAKING_EPOCH_DURATION;
    uint256 constant VAULT_AUCTION_LENGTH = 30 * 60;
    uint256 constant VAULT_AUCTION_EXTEND_LENGTH = 10 * 60;
    uint256 constant VOTING_DEPLAY_BLOCK = 10;
    uint256 constant VOTING_PERIOD_BLOCK = 23;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import {IERC20} from "../openzeppelin/token/ERC20/IERC20.sol";

library DataTypes {
    struct TokenVaultInitializeParams {
        address curator;
        address token;
        uint256 id;
        uint256 listPrice;
        uint256 exitLength;
        string name;
        string symbol;
        uint256 supply;
        uint256 treasuryBalance;
    }

    struct StakingInfo {
        address staker;
        uint256 poolId;
        uint256 amount;
        uint256 createdTime;
        //sharedPerTokens by rewardToken
        mapping(IERC20 => uint256) sharedPerTokens;
    }

    struct PoolInfo {
        uint256 ratio;
        uint256 duration;
    }

    struct RewardInfo {
        uint256 currentBalance;
        //sharedPerTokens by pool
        mapping(uint256 => uint256) sharedPerTokensByPool;
    }

    struct EstimateWithdrawAmountParams {
        uint256 withdrawAmount;
        address withdrawToken;
        uint256 stakingAmount;
        address stakingToken;
        uint256 poolId;
        uint256 infoSharedPerToken;
        uint256 sharedPerToken1;
        uint256 sharedPerToken2;
    }

    struct EstimateNewSharedRewardAmount {
        uint256 newRewardAmt;
        uint256 poolBalance1;
        uint256 ratio1;
        uint256 poolBalance2;
        uint256 ratio2;
    }

    struct GetSharedPerTokenParams {
        IERC20 token;
        uint256 currentRewardBalance;
        address stakingToken;
        uint256 sharedPerToken1;
        uint256 sharedPerToken2;
        uint256 poolBalance1;
        uint256 ratio1;
        uint256 poolBalance2;
        uint256 ratio2;
        uint256 totalUserFToken;
    }

    // vault param

    struct VaultGetBeforeTokenTransferUserPriceParams {
        uint256 votingTokens;
        uint256 exitTotal;
        uint256 fromPrice;
        uint256 toPrice;
        uint256 amount;
    }

    struct VaultGetUpdateUserPrice {
        address settings;
        uint256 votingTokens;
        uint256 exitTotal;
        uint256 exitPrice;
        uint256 newPrice;
        uint256 oldPrice;
        uint256 weight;
    }

    struct VaultProposalETHTransferParams {
        address msgSender;
        address government;
        address recipient;
        uint256 amount;
    }

    struct VaultProposalTargetCallParams {
        bool isAdmin;
        address msgSender;
        address vaultToken;
        address government;
        address treasury;
        address staking;
        address exchange;
        address target;
        uint256 value;
        bytes data;
        uint256 nonce;
    }

    struct VaultProposalTargetCallValidParams {
        address msgSender;
        address vaultToken;
        address government;
        address treasury;
        address staking;
        address exchange;
        address target;
        bytes data;
    }
}

pragma solidity ^0.8.0;

import {InitializedProxy} from "./InitializedProxy.sol";
import {IImpls} from "../../interfaces/IImpls.sol";

/**
 * @title InitializedProxy
 * @author 0xkongamoto
 */
contract TokenVaultStakingProxy is InitializedProxy {
    constructor(address _settings, bytes memory _initializationCalldata)
        InitializedProxy(_settings, _initializationCalldata)
    {}

    function getImpl() public view override returns (address) {
        return IImpls(settings).stakingImpl();
    }
}

pragma solidity ^0.8.0;

/**
 * @title SettingStorage
 * @author 0xkongamoto
 */
contract SettingStorage {
    // address of logic contract
    address public immutable settings;

    // ======== Constructor =========

    constructor(address _settings) {
        require(_settings != address(0), "no zero address");
        settings = _settings;
    }
}

pragma solidity ^0.8.0;

import {SettingStorage} from "./SettingStorage.sol";

/**
 * @title InitializedProxy
 * @author 0xkongamoto
 */
contract InitializedProxy is SettingStorage {
    // ======== Constructor =========
    constructor(address _settings, bytes memory _initializationCalldata)
        SettingStorage(_settings)
    {
        // Delegatecall into the logic contract, supplying initialization calldata
        (bool _ok, bytes memory returnData) = getImpl().delegatecall(
            _initializationCalldata
        );
        // Revert if delegatecall to implementation reverts
        require(_ok, string(returnData));
    }

    function getImpl() public view virtual returns (address) {
        return settings;
    }

    // ======== Fallback =========

    fallback() external payable {
        address _impl = getImpl();
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(gas(), _impl, ptr, calldatasize(), 0, 0)
            let size := returndatasize()
            returndatacopy(ptr, 0, size)

            switch result
            case 0 {
                revert(ptr, size)
            }
            default {
                return(ptr, size)
            }
        }
    }

    // ======== Receive =========

    receive() external payable {} // solhint-disable-line no-empty-blocks
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

pragma solidity ^0.8.0;

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../introspection/IERC165.sol";

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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Burnable is IERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) external;
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity ^0.8.0;

/**
 * @title Errors library
 * @author Bend
 * @notice Defines the error messages emitted by the different contracts of the Bend protocol
 */
library Errors {
    //common errors
    // string public constant CALLER_NOT_OWNER = "100"; // 'The caller must be owner'
    string public constant ZERO_ADDRESS = "101"; // 'zero address'

    //vault errors
    string public constant VAULT_ = "200";
    string public constant VAULT_TREASURY_INVALID = "201";
    string public constant VAULT_SUPPLY_INVALID = "202";
    string public constant VAULT_STATE_INVALID = "203";
    string public constant VAULT_BID_PRICE_TOO_LOW = "204";
    string public constant VAULT_BALANCE_INVALID = "205";
    string public constant VAULT_REQ_VALUE_INVALID = "206";
    string public constant VAULT_AUCTION_END = "207";
    string public constant VAULT_AUCTION_LIVE = "208";
    string public constant VAULT_NOT_GOVERNOR = "209";
    string public constant VAULT_STAKING_INVALID = "210";
    string public constant VAULT_STAKING_LENGTH_INVALID = "211";
    string public constant VAULT_TOKEN_INVALID = "212";
    string public constant VAULT_PRICE_TOO_HIGHT = "213";
    string public constant VAULT_PRICE_TOO_LOW = "214";
    string public constant VAULT_PRICE_INVALID = "215";
    string public constant VAULT_STAKING_NEED_MORE_THAN_ZERO = "216";
    string public constant VAULT_STAKING_TRANSFER_FAILED = "217";
    string public constant VAULT_STAKING_INVALID_BALANCE = "218";
    string public constant VAULT_STAKING_INVALID_POOL_ID = "219";
    string public constant VAULT_WITHDRAW_TRANSFER_FAILED = "220";
    string public constant VAULT_TREASURY_TRANSFER_FAILED = "221";
    string public constant VAULT_TREASURY_EPOCH_INVALID = "222";
    string public constant VAULT_REWARD_TOKEN_INVALID = "223";
    string public constant VAULT_REWARD_TOKEN_MAX = "224";
    string public constant VAULT_BID_PRICE_ZERO = "225";
    string public constant VAULT_ZERO_AMOUNT = "226";
    string public constant VAULT_TRANSFER_ETH_FAILED = "227";
    string public constant VAULT_INVALID_PARAMS = "228";
    string public constant VAULT_TREASURY_STAKING_ENABLED = "229";
    string public constant VAULT_NOT_TARGET_CALL = "230";
    string public constant VAULT_PROPOSAL_NOT_AGAINST = "231";
    string public constant VAULT_AFTER_TARGET_CALL_FAILED = "232";
    string public constant VAULT_NOT_VOTERS = "233";
    string public constant VAULT_INVALID_SIGNER = "234";
    string public constant VAULT_INVALID_TIMESTAMP = "235";
    string public constant VAULT_TREASURY_BALANCE_INVALID = "236";

    //treasury errors
    // string public constant TREASURY_ = "300";

    //staking errors
    // string public constant STAKING_ = "400";

    //exchange errors
    // string public constant EXCHANGE_ = "500";

    //exchange errors
    // string public constant GOVERNOR_ = "600";
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IERC20Burnable} from "../libraries/openzeppelin/token/ERC20/IERC20Burnable.sol";

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IVault is IERC20Burnable {
    //
    function token() external view returns (address);

    function nftGovernor() external view returns (address);

    function curator() external view returns (address);

    function treasury() external view returns (address);

    function staking() external view returns (address);

    function government() external view returns (address);

    function exchange() external view returns (address);

    function decimals() external view returns (uint256);

    function initializeGovernorToken() external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../libraries/openzeppelin/token/ERC20/IERC20.sol";

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface ITreasury {
    function isEnded() external view returns (bool);

    function shareTreasuryRewardToken() external;

    function getPoolBalanceToken(IERC20 _token) external view returns (uint256);

    function getBalanceVeToken() external view returns (uint256);

    function getNewSharedToken(IERC20 _token)
        external
        view
        returns (
            uint256 poolSharedAmt,
            uint256 incomeSharedAmt,
            uint256 incomePoolAmt
        );

    function stakingInitialize(uint256 _epochTotal) external;

    function addRewardToken(address _rewardToken) external;

    function end() external;

    function initializeGovernorToken() external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IERC20Upgradeable} from "../libraries/openzeppelin/upgradeable/token/ERC20/IERC20Upgradeable.sol";

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IStaking is IERC20Upgradeable {
    //
    function delegate(address delegatee) external;

    function getStakingTotal() external view returns (uint256);

    function addRewardToken(address _addr) external;

    function deposit(uint256 amount, uint256 poolId) external;

    function withdraw(uint256 sId, uint256 amount) external;

    function convertFTokenToVeToken(uint256 amount) external;

    function redeemFToken(uint256 amount) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IImpls {
    function vaultImpl() external view returns (address);

    function stakingImpl() external view returns (address);

    function treasuryImpl() external view returns (address);

    function governmentImpl() external view returns (address);

    function exchangeImpl() external view returns (address);
}