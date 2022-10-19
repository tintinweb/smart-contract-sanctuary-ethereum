pragma solidity ^0.8.0;

import {ISettings} from "../../interfaces/ISettings.sol";
import {IVault} from "../../interfaces/IVault.sol";
import {TokenVaultGovernorProxy} from "./../proxy/TokenVaultGovernorProxy.sol";
import {Constants} from "../../protocol/Constants.sol";

library TokenVaultGovernorLogic {
    //
    bytes4 public constant VOTE_TARGET_CALL_FUNCTION = 0xcc043ed6; //bytes4(keccak256(bytes('proposalTargetCall(address,uint256,bytes)'))) =>0xcc043ed6
    bytes4 public constant CAST_VOTE_CALL_FUNCTION = 0x56781388; //bytes4(keccak256(bytes('castVote(uint256,uint8)'))) ==> 0x56781388

    function newGovernorInstance(
        address settings,
        address token,
        address vaultToken,
        uint256 supply
    ) external returns (address) {
        ISettings _settings = ISettings(settings);
        (, uint256 delayBlock, uint256 periodBlock) = _settings
            .getGovernorSetting(token);
        require(delayBlock > 0, "bad delay block");
        require(periodBlock > 0, "bad period block");
        bytes memory _initializationCalldata = abi.encodeWithSignature(
            "initialize(address,uint256,uint256,uint256,uint256)",
            vaultToken,
            _settings.votingQuorumPercent(),
            delayBlock,
            periodBlock,
            ((supply * _settings.votingMinTokenPercent()) / 10000)
        );
        address government = address(
            new TokenVaultGovernorProxy(settings, _initializationCalldata)
        );
        return government;
    }

    function validTargetCallFunction(bytes calldata _data)
        internal
        pure
        returns (bool)
    {
        if (VOTE_TARGET_CALL_FUNCTION == bytes4(bytes(_data[:4]))) {
            return true;
        }
        return false;
    }

    function decodeTargetCallParams(bytes calldata _data)
        internal
        pure
        returns (
            address target,
            uint256 value,
            bytes memory data
        )
    {
        (target, value, data) = abi.decode(
            _data[4:],
            (address, uint256, bytes)
        );
        return (target, value, data);
    }

    function decodeCastVoteData(bytes calldata _data)
        public
        pure
        returns (uint256, uint8)
    {
        bytes4 funcName = bytes4(bytes(_data[:4]));
        if (CAST_VOTE_CALL_FUNCTION == funcName) {
            (uint256 proposalId, uint8 value) = abi.decode(
                _data[4:],
                (uint256, uint8)
            );
            return (proposalId, value);
        }
        return (0, 0);
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

pragma solidity ^0.8.0;

import {InitializedProxy} from "./InitializedProxy.sol";
import {IImpls} from "../../interfaces/IImpls.sol";

/**
 * @title InitializedProxy
 */
contract TokenVaultGovernorProxy is InitializedProxy {
    constructor(address _settings, bytes memory _initializationCalldata)
        InitializedProxy(_settings, _initializationCalldata)
    {}

    function getImpl() public view override returns (address) {
        return IImpls(settings).governmentImpl();
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISettings {
    // interface
    function weth() external view returns (address);

    function minBidIncrease() external view returns (uint256);

    function minVotePercentage() external view returns (uint256);

    function maxExitFactor() external view returns (uint256);

    function minExitFactor() external view returns (uint256);

    function feeReceiver() external view returns (address payable);

    function feePercentage() external view returns (uint256);

    function exitFeeForCuratorPercentage() external view returns (uint256);

    function exitFeeForPlatformPercentage() external view returns (uint256);

    function presaleFeePercentage() external view returns (uint256);

    function reduceStep() external view returns (uint256);

    function auctionLength() external view returns (uint256);

    function auctionExtendLength() external view returns (uint256);

    function votingQuorumPercent() external view returns (uint256);

    function votingMinTokenPercent() external view returns (uint256);

    function nftOracle() external view returns (address);

    function flashLoanAdmin() external view returns (address);

    function getGovernorSetting(address nftAddr)
        external
        view
        returns (
            address,
            uint256,
            uint256
        );
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