// SPDX-License-Identifier: MIT

pragma solidity 0.4.24;

import "../role/RoleManager.sol";
import "../interfaces/IKiKiStakingHelper.sol";
import "../interfaces/IKiKiStaking.sol";
import "../interfaces/IKiKiStakingToken.sol";
import "@aragon/os/contracts/lib/math/SafeMath.sol";

contract KiKiStakingHelper is IKiKiStakingHelper, RoleManager {
    using SafeMath for uint256;
    
    bytes32 constant public LIQUIDITY_POOL_ROLE = keccak256("LIQUIDITY_POOL_ROLE");

    bytes32 internal constant KIKISTAKING_POSITION = keccak256("KKS.KKSH.kikiStaking");
    
    /// @dev liquidity pool percent, based on 10000 point
    bytes32 internal constant SWAP_BUFFER_PERCENT_POSITION = keccak256("KKS.KKSH.bufferPercent");
    /// @dev Swap min fee, based on 10000 point
    bytes32 internal constant SWAP_MIN_FEE_POSITION = keccak256("KKS.KKSH.swapMinFee");
    /// @dev Swap max fee, based on 10000 point
    bytes32 internal constant SWAP_MAX_FEE_POSITION = keccak256("KKS.KKSH.swapMaxFee");
    /// @dev APR points, based on 10000 point
    bytes32 internal constant APR_POSITION = keccak256("KKS.KKSH.APR");
    /// @dev Last update APR total pooled ether
    bytes32 internal constant TOTAL_POOLED_ETHER_POSITION = keccak256("KKS.KKSH.totalPooledEther");
    /// @dev Last update APR block time
    bytes32 internal constant LAST_APR_TIME_POSITION = keccak256("KKS.KKSH.lastAPRTime");

    modifier onlyKiKiStaking() {
        require(msg.sender == KIKISTAKING_POSITION.getStorageAddress(), "APP_AUTH_FAILED");
        _;
    }

    function initialize(address _kikiStaking)
        external
        onlyInit
        onlyMainManager
    {
        _setKiKiStaking(_kikiStaking);

        initialized();
    }
    
    /**
      * @notice Set liquidity pool percent to `points`, need manager role
      * @param points Percent points, base on 10000
      */
    function setLiquidityPoolPercent(uint16 points) external auth(LIQUIDITY_POOL_ROLE) {
        if (_readBPValue(SWAP_BUFFER_PERCENT_POSITION) != points) {
            _setBPValue(SWAP_BUFFER_PERCENT_POSITION, points);
            IKiKiStaking kikiStaking = IKiKiStaking(KIKISTAKING_POSITION.getStorageAddress());
            uint256 liquidity = kikiStaking.getLiquidity();
            uint256 liquidityPoolSize = kikiStaking.getLiquidityPoolSize();
            if (liquidity > liquidityPoolSize)
            {
                kikiStaking.updateSwapPool(liquidity.sub(liquidityPoolSize));
            }
        }
    }

    /**
      * @notice Set swap fee percent to min `minPoints`, max `maxPoints`, need manager role
      * @param minPoints Min percent points, base on 10000
      * @param maxPoints Max percent points, base on 10000
      */
    function setSwapFeePercent(uint16 minPoints, uint16 maxPoints) external auth(LIQUIDITY_POOL_ROLE) {
        require(minPoints <= maxPoints, "KKSH::setSwapFeePercent: need min points <= max points");
        _setBPValue(SWAP_MIN_FEE_POSITION, minPoints);
        _setBPValue(SWAP_MAX_FEE_POSITION, maxPoints);
    }
    
    /**
      * @notice Get current APR based on 10000 points
      */
    function getAPR() external view returns (uint256) {
        return _getAPR();
    }

    /**
      * @notice Set current APR based on 10000 points
      */
    function setAPR(uint16 _APR) external onlyKiKiStaking {
        _setLastBlockTime(getTimestamp());
        _setAPR(uint256(_APR));
    }

    function updateAPR() public onlyKiKiStaking {
        address kikiStaking = KIKISTAKING_POSITION.getStorageAddress();
        uint256 currentTotalPooledEther = IKiKiStaking(kikiStaking).getTotalPooledEther();
        uint256 timeElapsed = getTimestamp().sub(_getLastBlockTime());
        uint256 _APR = getNewAPR(currentTotalPooledEther, timeElapsed);
        // APR can over 100 percent
        // require(_APR <= 10000, "KKSH::updateAPR: abnormal APR");
        _setAPR(_APR);
        _setLastTotalPooledEther(currentTotalPooledEther);
        _setLastBlockTime(getTimestamp());
    }

    /**
    * @notice Returns the liquidity pool percent point, based on 10000
    */
    function getLiquidityPoolPercent() public view returns (uint16) {
        return _readBPValue(SWAP_BUFFER_PERCENT_POSITION);
    }

    /**
    * @notice Returns the min and max swap fee percent point, based on 10000
    */
    function getSwapFeePercent() public view returns (uint16, uint16) {
        return (_readBPValue(SWAP_MIN_FEE_POSITION), _readBPValue(SWAP_MAX_FEE_POSITION));
    }

    /**
    * @notice Returns the swap fee by ether amount `etherAmount`
    */
    function getSwapFeeByETH(uint256 etherAmount) public view returns (uint256) {
        return etherAmount.mul(getSwapFeePointsByETH(etherAmount)).div(10000);
    }

    /**
    * @notice Returns the swap fee percent points by ether amount `etherAmount`, based on 10000
    */
    function getSwapFeePointsByETH(uint256 etherAmount) public view returns (uint16) {
        IKiKiStaking kikiStaking = IKiKiStaking(KIKISTAKING_POSITION.getStorageAddress());
        uint256 bufferPoolLiquidity = kikiStaking.getLiquidity();
        uint256 outEth = bufferPoolLiquidity > etherAmount ? etherAmount : bufferPoolLiquidity;
        (uint16 minFee, uint16 maxFee) = getSwapFeePercent();
        if (maxFee == minFee) {
            return minFee;
        } else {
            uint256 swapPoolSize = kikiStaking.getLiquidityPoolSize();
            if (0 == swapPoolSize)
                return 0;
            uint256 swapPoolLiquidity = kikiStaking.getLiquidity();
            // k = (maxFee - minFee) / swapPoolSize;
            // feePoints = (swapPoolSize - swapPoolLiquidity + outEth) * k + minFee;
            uint256 feePoints = swapPoolSize.sub(swapPoolLiquidity).add(outEth).mul(uint256(maxFee).sub(minFee)).div(swapPoolSize).add(minFee);
            require(feePoints <= 10000);
            return uint16(feePoints);
        }
    }

    function getNewAPR(uint256 newTotalPooledEther, uint256 timeElapsed) public view returns (uint256) {
        address kikiStaking = KIKISTAKING_POSITION.getStorageAddress();
        uint256 lastTotalPooledEther = _getLastTotalPooledEther();
        if (0 == lastTotalPooledEther)
        {
            lastTotalPooledEther = IKiKiStakingToken(kikiStaking).getTotalStaking();
        }
        require(lastTotalPooledEther > 0, "KKSH::getNewAPR: zero lastTotalPooledEther");
        uint16 feePoints = IKiKiStaking(kikiStaking).getFee();
        return newTotalPooledEther.sub(lastTotalPooledEther).mul(365 days).mul(10000-feePoints).div(lastTotalPooledEther).div(timeElapsed);
    }

    function getLastAPRBlockTime() public view returns (uint256) {
        return _getLastBlockTime();
    }

    function getLiquidityPoolNewStatus(uint256 _value) public view returns (uint256 swapPoolLiquidity, uint256 bufferedEther) {
        IKiKiStaking kikiStaking = IKiKiStaking(KIKISTAKING_POSITION.getStorageAddress());
        uint256 oldSwapPoolSize = kikiStaking.getLiquidityPoolSize();
        uint256 liquidity = kikiStaking.getLiquidity();
        // if decreased liquidity pool size, must move the superfluous ether to buffered pool
        if (_value <= oldSwapPoolSize.sub(liquidity)) {
            swapPoolLiquidity = liquidity.add(_value);
            bufferedEther = kikiStaking.getBufferedEther();
        } else {
            uint16 swapPoolPercentPoints = _readBPValue(SWAP_BUFFER_PERCENT_POSITION);
            uint256 depositedAndBufferedEthers = kikiStaking.getDepositedAndBufferedEthers();
            uint256 total = depositedAndBufferedEthers.add(liquidity).add(_value);
            // liquidity == liquidity pool size
            swapPoolLiquidity = total.mul(swapPoolPercentPoints).div(10000);
            uint256 etherToBuffered = total.sub(swapPoolLiquidity).sub(depositedAndBufferedEthers);
            bufferedEther = etherToBuffered.add(kikiStaking.getBufferedEther());
        }
    }

    /**added code without aragonApp */
    function getRecoveryVault() public view returns (address) {
        return address(0);
    }
    /**added code without aragonApp */

    function _setKiKiStaking(address kikiStaking) internal {
        require(address(0) != kikiStaking, "KiKiFeeManager::_setKiKiStaking: zero address");
        KIKISTAKING_POSITION.setStorageAddress(kikiStaking);
    }

    /**
      * @dev Write a value nominated in basis points
      */
    function _setBPValue(bytes32 _slot, uint16 _value) internal {
        require(_value <= 10000, "VALUE_OVER_100_PERCENT");
        _slot.setStorageUint256(uint256(_value));
    }

    /**
      * @dev Read a value nominated in basis points
      */
    function _readBPValue(bytes32 _slot) internal view returns (uint16) {
        uint256 v = _slot.getStorageUint256();
        assert(v <= 10000);
        return uint16(v);
    }

    function _setAPR(uint256 _APR) internal {
        APR_POSITION.setStorageUint256(_APR);
    }

    function _setLastTotalPooledEther(uint256 etherAmount) internal {
        TOTAL_POOLED_ETHER_POSITION.setStorageUint256(etherAmount);
    }

    function _setLastBlockTime(uint256 timestamp) internal {
        LAST_APR_TIME_POSITION.setStorageUint256(timestamp);
    }

    function _getAPR() internal view returns (uint256) {
        return APR_POSITION.getStorageUint256();
    }

    function _getLastBlockTime() internal view returns (uint256) {
        return LAST_APR_TIME_POSITION.getStorageUint256();
    }

    function _getLastTotalPooledEther() internal view returns (uint256) {
        return TOTAL_POOLED_ETHER_POSITION.getStorageUint256();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.4.24;

import "@aragon/os/contracts/common/Initializable.sol";
import "@aragon/os/contracts/acl/ACLSyntaxSugar.sol";
import "@aragon/os/contracts/common/VaultRecoverable.sol";

contract RoleManager is Initializable
, ACLSyntaxSugar
, VaultRecoverable {
    mapping(bytes32 => address) managers;
    bytes32 constant public MANAGE_MAIN = keccak256("MANAGE_MAIN");
    address internal constant ROLE_ANYONE = 0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF;
    string private constant ERROR_AUTH_FAILED = "APP_AUTH_FAILED";
    string private constant ERROR_AUTH_MANAGER_FAILED = "ERROR_AUTH_MANAGER_FAILED";

    event TranseferRole(bytes32 role, address from, address to);
    event TranseferManager(bytes32 role, address from, address to);

    modifier authManager(bytes32 _role) {
        require(managers[_role] == msg.sender, ERROR_AUTH_MANAGER_FAILED);
        _;
    }

    modifier onlyMainManager() {
        require(MANAGE_MAIN.getStorageAddress() == msg.sender, ERROR_AUTH_FAILED);
        _;
    }

    modifier auth(bytes32 _role) {
        require(canPerform(msg.sender, _role), ERROR_AUTH_FAILED);
        _;
    }

    modifier authP(bytes32 _role, uint256[] _params) {
        require(canPerform(msg.sender, _role), ERROR_AUTH_FAILED);
        _;
    }

    constructor() public {
        managers[MANAGE_MAIN] = msg.sender;
        MANAGE_MAIN.setStorageAddress(msg.sender);
        emit TranseferManager(MANAGE_MAIN, address(0), msg.sender);
        emit TranseferRole(MANAGE_MAIN, address(0), msg.sender);
    }

    function getManager(bytes32 _role) public view returns (address) {
        require(managers[_role] != address(0), "RoleManager::getManager: invalid role");
        return managers[_role];
    }

    function canPerform(address _sender, bytes32 _role) public view returns (bool) {
        if (!hasInitialized()) {
            return false;
        }
        address entity = _role.getStorageAddress();
        if (entity == ROLE_ANYONE) {
            return true;
        }
        else {
            return _sender == entity;
        }
    }

    function registerRole(bytes32 role, address manager, address entity) public auth(MANAGE_MAIN) {
        require(managers[role] == address(0), "RoleManager::registerRole: role aready have");
        managers[role] = manager;
        role.setStorageAddress(entity);
        emit TranseferManager(role, address(0), manager);
        emit TranseferRole(role, address(0), entity);
    }

    function registerRoleGrantAnyone(bytes32 role, address manager) public {
        registerRole(role, manager, ROLE_ANYONE);
    }

    function transferRole(bytes32 role, address newEntity) internal authManager(role) {
        address oldEntity = role.getStorageAddress();
        role.setStorageAddress(newEntity);
        emit TranseferRole(role, oldEntity, newEntity);
    }

    function transferManagerRole(bytes32 role, address newManager) internal authManager(role) {
        managers[role] = newManager;
        emit TranseferManager(role, msg.sender, newManager);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.4.24;

interface IKiKiStakingHelper {
    function setLiquidityPoolPercent(uint16 points) external;
    function setSwapFeePercent(uint16 minPoints, uint16 maxPoints) external;
    function setAPR(uint16 _APR) external;
    function updateAPR() external;
    function getLiquidityPoolPercent() external view returns (uint16);
    function getSwapFeePercent() external view returns (uint16, uint16);
    function getSwapFeeByETH(uint256 etherAmount) external view returns (uint256);
    function getSwapFeePointsByETH(uint256 etherAmount) external view returns (uint16);
    function getLiquidityPoolNewStatus(uint256 _value) external view returns (uint256 swapPoolLiquidity, uint256 bufferedEther);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.4.24;

/**
  * @title Liquid staking pool
  *
  * For the high-level description of the pool operation please refer to the paper.
  * Pool manages withdrawal keys and fees. It receives ether submitted by users on the ETH 1 side
  * and stakes it via the deposit_contract.sol contract. It doesn't hold ether on it's balance,
  * only a small portion (buffer) of it.
  * It also mints new tokens for rewards generated at the ETH 2.0 side.
  */
interface IKiKiStaking {
    /**
     * @dev From IKiKiStaking interface, because "Interfaces cannot inherit".
     */
    function totalSupply() external view returns (uint256);
    function getTotalShares() external view returns (uint256);

    /**
      * @notice Stop pool routine operations
      */
    function stop() external;

    /**
      * @notice Resume pool routine operations
      */
    function resume() external;

    event Stopped();
    event Resumed();


    /**
      * @notice Set fee rate to `_feeBasisPoints` basis points. The fees are accrued when oracles report staking results
      * @param _feeBasisPoints Fee rate, in basis points
      */
    function setFee(uint16 _feeBasisPoints) external;

    /**
      * @notice Returns staking rewards fee rate
      */
    function getFee() external view returns (uint16 feeBasisPoints);

    event FeeSet(uint16 feeBasisPoints);

    /**
      * @notice Set credentials to withdraw ETH on ETH 2.0 side after the phase 2 is launched to `_withdrawalCredentials`
      * @dev Note that setWithdrawalCredentials discards all unused signing keys as the signatures are invalidated.
      * @param _withdrawalCredentials hash of withdrawal multisignature key as accepted by
      *        the deposit_contract.deposit function
      */
    function setWithdrawalCredentials(bytes32 _withdrawalCredentials) external;

    /**
      * @notice Returns current credentials to withdraw ETH on ETH 2.0 side after the phase 2 is launched
      */
    function getWithdrawalCredentials() external view returns (bytes);


    event WithdrawalCredentialsSet(bytes32 withdrawalCredentials);


    /**
      * @notice Ether on the ETH 2.0 side reported by the oracle
      * @param _epoch Epoch id
      * @param _eth2balance Balance in wei on the ETH 2.0 side
      */
    function pushBeacon(uint256 _epoch, uint256 _eth2balance) external;


    // User functions

    /**
      * @notice Adds eth to the pool
      * @return kETH Amount of kETH generated
      */
    function submit(address _referral) external payable returns (uint256 kETH);

    // Records a deposit made by a user
    event Submitted(address indexed sender, uint256 amount, address referral);

    // The `_amount` of ether was sent to the deposit_contract.deposit function.
    event Unbuffered(uint256 amount);

    /**
      * @notice Issues withdrawal request. Large withdrawals will be processed only after the phase 2 launch.
      * @param _amount Amount of kETH to burn
      * @param _pubkeyHash Receiving address
      */
    function withdraw(uint256 _amount, bytes32 _pubkeyHash) external;

    // Requested withdrawal of `etherAmount` to `pubkeyHash` on the ETH 2.0 side, `tokenAmount` burned by `sender`,
    // `sentFromBuffer` was sent on the current Ethereum side.
    event Withdrawal(address indexed sender, uint256 tokenAmount, uint256 sentFromBuffer,
                     bytes32 indexed pubkeyHash, uint256 etherAmount);

    /**
      * @notice Issues swap `_amount` kETH to ETH from liquidity pool, transfer to `to`.
      * @param _amount Amount of kETH to burn
      * @param to Recipient
      * @return ETH swaped
      */
    function swap(uint256 _amount, address to) external returns (uint256);

    // Requested swap of `ethAmount`, `kETHAmount` burned by `sender`
    event Swap(address sender, address recipient, uint256 ethAmount, uint256 kETHAmount);

    // Info functions

    /**
      * @notice Gets the amount of Ether controlled by the system
      */
    function getTotalPooledEther() external view returns (uint256);

    /**
      * @notice Gets the amount of Ether temporary buffered on this contract balance
      */
    function getBufferedEther() external view returns (uint256);

    /**
      * @notice Gets the amount of swap pool liquidity
      */
    function getLiquidity() external view returns (uint256);

    /**
      * @notice Gets the swap pool size
      */
    function getLiquidityPoolSize() external view returns (uint256);

    /**
      * @notice Gets the deposited and buffered ethers
      */
    function getDepositedAndBufferedEthers() external view returns (uint256);

    /**
      * @notice Gets total swap fee
      */
    function getTotalSwapFee() external view returns (uint256);

    /**
      * @notice Update liquidity pool status, when decrease liquidity pool size, may call this function.
      */
    function updateSwapPool(uint256 _value) external;

    /**
      * @notice Returns the key values related to Beacon-side
      * @return depositedValidators - number of deposited validators
      * @return beaconValidators - number of KiKiStaking's validators visible in the Beacon state, reported by oracles
      * @return beaconBalance - total amount of Beacon-side Ether (sum of all the balances of KiKiStaking validators)
      */
    function getBeaconStat() external view returns (uint256 depositedValidators, uint256 beaconValidators, uint256 beaconBalance);

    // /**
    //   * @notice Get current APR based on 10000 points
    //   */
    // function getAPR() external view returns (uint16);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.4.24;

/**
  * @title A liquid version of ETH 2.0 native token
  *
  * ERC20 token which supports stop/resume mechanics. The token is operated by `IKiKiStaking`.
  *
  * Since balances of all token holders change when the amount of total controlled Ether
  * changes, this token cannot fully implement ERC20 standard: it only emits `Transfer`
  * events upon explicit transfer between holders. In contrast, when KiKiStaking oracle reports
  * rewards, no Transfer events are generated: doing so would require emitting an event
  * for each token holder and thus running an unbounded loop.
  */
interface IKiKiStakingToken /* is IERC20 */ {
    function totalSupply() external view returns (uint256);

    /**
      * @notice Stop transfers
      */
    function stop() external;

    /**
      * @notice Resume transfers
      */
    function resume() external;

    /**
      * @notice Returns true if the token is stopped
      */
    function isStopped() external view returns (bool);

    event Stopped();
    event Resumed();

    /**
    * @notice Increases shares of a given address by the specified amount. Called by KiKiStaking
    *         contract in two cases: 1) when a user submits an ETH1.0 deposit; 2) when
    *         ETH2.0 rewards are reported by the oracle. Upon user deposit, KiKiStaking contract
    *         mints the amount of shares that corresponds to the submitted Ether, so
    *         token balances of other token holders don't change. Upon rewards report,
    *         KiKiStaking contract mints new shares to distribute fee, effectively diluting the
    *         amount of Ether that would otherwise correspond to each share.
    *
    * @param _to Receiver of new shares
    * @param _sharesAmount Amount of shares to mint
    * @return The total amount of all holders' shares after new shares are minted
    */
    function mintShares(address _to, uint256 _sharesAmount) external returns (uint256);

    /**
      * @notice Burn is called by KiKiStaking contract when a user withdraws their Ether.
      * @param _account Account which tokens are to be burnt
      * @param _sharesAmount Amount of shares to burn
      * @return The total amount of all holders' shares after the shares are burned
      */
    function burnShares(address _account, uint256 _sharesAmount) external returns (uint256);


    function balanceOf(address owner) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function getTotalShares() external view returns (uint256);

    /**
      * @dev Gets total staking Ether on this side
      */
    function getTotalStaking() external view returns (uint256);

    function getPooledEthByShares(uint256 _sharesAmount) external view returns (uint256);
    function getSharesByPooledEth(uint256 _pooledEthAmount) external view returns (uint256);
}

// See https://github.com/OpenZeppelin/openzeppelin-solidity/blob/d51e38758e1d985661534534d5c61e27bece5042/contracts/math/SafeMath.sol
// Adapted to use pragma ^0.4.24 and satisfy our linter rules

pragma solidity ^0.4.24;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {
    string private constant ERROR_ADD_OVERFLOW = "MATH_ADD_OVERFLOW";
    string private constant ERROR_SUB_UNDERFLOW = "MATH_SUB_UNDERFLOW";
    string private constant ERROR_MUL_OVERFLOW = "MATH_MUL_OVERFLOW";
    string private constant ERROR_DIV_ZERO = "MATH_DIV_ZERO";

    /**
    * @dev Multiplies two numbers, reverts on overflow.
    */
    function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (_a == 0) {
            return 0;
        }

        uint256 c = _a * _b;
        require(c / _a == _b, ERROR_MUL_OVERFLOW);

        return c;
    }

    /**
    * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b > 0, ERROR_DIV_ZERO); // Solidity only automatically asserts when dividing by 0
        uint256 c = _a / _b;
        // assert(_a == _b * c + _a % _b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b <= _a, ERROR_SUB_UNDERFLOW);
        uint256 c = _a - _b;

        return c;
    }

    /**
    * @dev Adds two numbers, reverts on overflow.
    */
    function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
        uint256 c = _a + _b;
        require(c >= _a, ERROR_ADD_OVERFLOW);

        return c;
    }

    /**
    * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, ERROR_DIV_ZERO);
        return a % b;
    }
}

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;

import "./TimeHelpers.sol";
import "./UnstructuredStorage.sol";


contract Initializable is TimeHelpers {
    using UnstructuredStorage for bytes32;

    // keccak256("aragonOS.initializable.initializationBlock")
    bytes32 internal constant INITIALIZATION_BLOCK_POSITION = 0xebb05b386a8d34882b8711d156f463690983dc47815980fb82aeeff1aa43579e;

    string private constant ERROR_ALREADY_INITIALIZED = "INIT_ALREADY_INITIALIZED";
    string private constant ERROR_NOT_INITIALIZED = "INIT_NOT_INITIALIZED";

    modifier onlyInit {
        require(getInitializationBlock() == 0, ERROR_ALREADY_INITIALIZED);
        _;
    }

    modifier isInitialized {
        require(hasInitialized(), ERROR_NOT_INITIALIZED);
        _;
    }

    /**
    * @return Block number in which the contract was initialized
    */
    function getInitializationBlock() public view returns (uint256) {
        return INITIALIZATION_BLOCK_POSITION.getStorageUint256();
    }

    /**
    * @return Whether the contract has been initialized by the time of the current block
    */
    function hasInitialized() public view returns (bool) {
        uint256 initializationBlock = getInitializationBlock();
        return initializationBlock != 0 && getBlockNumber() >= initializationBlock;
    }

    /**
    * @dev Function to be called by top level contract after initialization has finished.
    */
    function initialized() internal onlyInit {
        INITIALIZATION_BLOCK_POSITION.setStorageUint256(getBlockNumber());
    }

    /**
    * @dev Function to be called by top level contract after initialization to enable the contract
    *      at a future block number rather than immediately.
    */
    function initializedAt(uint256 _blockNumber) internal onlyInit {
        INITIALIZATION_BLOCK_POSITION.setStorageUint256(_blockNumber);
    }
}

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;


contract ACLSyntaxSugar {
    function arr() internal pure returns (uint256[]) {
        return new uint256[](0);
    }

    function arr(bytes32 _a) internal pure returns (uint256[] r) {
        return arr(uint256(_a));
    }

    function arr(bytes32 _a, bytes32 _b) internal pure returns (uint256[] r) {
        return arr(uint256(_a), uint256(_b));
    }

    function arr(address _a) internal pure returns (uint256[] r) {
        return arr(uint256(_a));
    }

    function arr(address _a, address _b) internal pure returns (uint256[] r) {
        return arr(uint256(_a), uint256(_b));
    }

    function arr(address _a, uint256 _b, uint256 _c) internal pure returns (uint256[] r) {
        return arr(uint256(_a), _b, _c);
    }

    function arr(address _a, uint256 _b, uint256 _c, uint256 _d) internal pure returns (uint256[] r) {
        return arr(uint256(_a), _b, _c, _d);
    }

    function arr(address _a, uint256 _b) internal pure returns (uint256[] r) {
        return arr(uint256(_a), uint256(_b));
    }

    function arr(address _a, address _b, uint256 _c, uint256 _d, uint256 _e) internal pure returns (uint256[] r) {
        return arr(uint256(_a), uint256(_b), _c, _d, _e);
    }

    function arr(address _a, address _b, address _c) internal pure returns (uint256[] r) {
        return arr(uint256(_a), uint256(_b), uint256(_c));
    }

    function arr(address _a, address _b, uint256 _c) internal pure returns (uint256[] r) {
        return arr(uint256(_a), uint256(_b), uint256(_c));
    }

    function arr(uint256 _a) internal pure returns (uint256[] r) {
        r = new uint256[](1);
        r[0] = _a;
    }

    function arr(uint256 _a, uint256 _b) internal pure returns (uint256[] r) {
        r = new uint256[](2);
        r[0] = _a;
        r[1] = _b;
    }

    function arr(uint256 _a, uint256 _b, uint256 _c) internal pure returns (uint256[] r) {
        r = new uint256[](3);
        r[0] = _a;
        r[1] = _b;
        r[2] = _c;
    }

    function arr(uint256 _a, uint256 _b, uint256 _c, uint256 _d) internal pure returns (uint256[] r) {
        r = new uint256[](4);
        r[0] = _a;
        r[1] = _b;
        r[2] = _c;
        r[3] = _d;
    }

    function arr(uint256 _a, uint256 _b, uint256 _c, uint256 _d, uint256 _e) internal pure returns (uint256[] r) {
        r = new uint256[](5);
        r[0] = _a;
        r[1] = _b;
        r[2] = _c;
        r[3] = _d;
        r[4] = _e;
    }
}


contract ACLHelpers {
    function decodeParamOp(uint256 _x) internal pure returns (uint8 b) {
        return uint8(_x >> (8 * 30));
    }

    function decodeParamId(uint256 _x) internal pure returns (uint8 b) {
        return uint8(_x >> (8 * 31));
    }

    function decodeParamsList(uint256 _x) internal pure returns (uint32 a, uint32 b, uint32 c) {
        a = uint32(_x);
        b = uint32(_x >> (8 * 4));
        c = uint32(_x >> (8 * 8));
    }
}

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;

import "../lib/token/ERC20.sol";
import "./EtherTokenConstant.sol";
import "./IsContract.sol";
import "./IVaultRecoverable.sol";
import "./SafeERC20.sol";


contract VaultRecoverable is IVaultRecoverable, EtherTokenConstant, IsContract {
    using SafeERC20 for ERC20;

    string private constant ERROR_DISALLOWED = "RECOVER_DISALLOWED";
    string private constant ERROR_VAULT_NOT_CONTRACT = "RECOVER_VAULT_NOT_CONTRACT";
    string private constant ERROR_TOKEN_TRANSFER_FAILED = "RECOVER_TOKEN_TRANSFER_FAILED";

    /**
     * @notice Send funds to recovery Vault. This contract should never receive funds,
     *         but in case it does, this function allows one to recover them.
     * @param _token Token balance to be sent to recovery vault.
     */
    function transferToVault(address _token) external {
        require(allowRecoverability(_token), ERROR_DISALLOWED);
        address vault = getRecoveryVault();
        require(isContract(vault), ERROR_VAULT_NOT_CONTRACT);

        uint256 balance;
        if (_token == ETH) {
            balance = address(this).balance;
            vault.transfer(balance);
        } else {
            ERC20 token = ERC20(_token);
            balance = token.staticBalanceOf(this);
            require(token.safeTransfer(vault, balance), ERROR_TOKEN_TRANSFER_FAILED);
        }

        emit RecoverToVault(vault, _token, balance);
    }

    /**
    * @dev By default deriving from AragonApp makes it recoverable
    * @param token Token address that would be recovered
    * @return bool whether the app allows the recovery
    */
    function allowRecoverability(address token) public view returns (bool) {
        return true;
    }

    // Cast non-implemented interface to be public so we can use it internally
    function getRecoveryVault() public view returns (address);
}

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;

import "./Uint256Helpers.sol";


contract TimeHelpers {
    using Uint256Helpers for uint256;

    /**
    * @dev Returns the current block number.
    *      Using a function rather than `block.number` allows us to easily mock the block number in
    *      tests.
    */
    function getBlockNumber() internal view returns (uint256) {
        return block.number;
    }

    /**
    * @dev Returns the current block number, converted to uint64.
    *      Using a function rather than `block.number` allows us to easily mock the block number in
    *      tests.
    */
    function getBlockNumber64() internal view returns (uint64) {
        return getBlockNumber().toUint64();
    }

    /**
    * @dev Returns the current timestamp.
    *      Using a function rather than `block.timestamp` allows us to easily mock it in
    *      tests.
    */
    function getTimestamp() internal view returns (uint256) {
        return block.timestamp; // solium-disable-line security/no-block-members
    }

    /**
    * @dev Returns the current timestamp, converted to uint64.
    *      Using a function rather than `block.timestamp` allows us to easily mock it in
    *      tests.
    */
    function getTimestamp64() internal view returns (uint64) {
        return getTimestamp().toUint64();
    }
}

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;


library UnstructuredStorage {
    function getStorageBool(bytes32 position) internal view returns (bool data) {
        assembly { data := sload(position) }
    }

    function getStorageAddress(bytes32 position) internal view returns (address data) {
        assembly { data := sload(position) }
    }

    function getStorageBytes32(bytes32 position) internal view returns (bytes32 data) {
        assembly { data := sload(position) }
    }

    function getStorageUint256(bytes32 position) internal view returns (uint256 data) {
        assembly { data := sload(position) }
    }

    function setStorageBool(bytes32 position, bool data) internal {
        assembly { sstore(position, data) }
    }

    function setStorageAddress(bytes32 position, address data) internal {
        assembly { sstore(position, data) }
    }

    function setStorageBytes32(bytes32 position, bytes32 data) internal {
        assembly { sstore(position, data) }
    }

    function setStorageUint256(bytes32 position, uint256 data) internal {
        assembly { sstore(position, data) }
    }
}

pragma solidity ^0.4.24;


library Uint256Helpers {
    uint256 private constant MAX_UINT64 = uint64(-1);

    string private constant ERROR_NUMBER_TOO_BIG = "UINT64_NUMBER_TOO_BIG";

    function toUint64(uint256 a) internal pure returns (uint64) {
        require(a <= MAX_UINT64, ERROR_NUMBER_TOO_BIG);
        return uint64(a);
    }
}

// See https://github.com/OpenZeppelin/openzeppelin-solidity/blob/a9f910d34f0ab33a1ae5e714f69f9596a02b4d91/contracts/token/ERC20/ERC20.sol

pragma solidity ^0.4.24;


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 {
    function totalSupply() public view returns (uint256);

    function balanceOf(address _who) public view returns (uint256);

    function allowance(address _owner, address _spender)
        public view returns (uint256);

    function transfer(address _to, uint256 _value) public returns (bool);

    function approve(address _spender, uint256 _value)
        public returns (bool);

    function transferFrom(address _from, address _to, uint256 _value)
        public returns (bool);

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;


// aragonOS and aragon-apps rely on address(0) to denote native ETH, in
// contracts where both tokens and ETH are accepted
contract EtherTokenConstant {
    address internal constant ETH = address(0);
}

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;


contract IsContract {
    /*
    * NOTE: this should NEVER be used for authentication
    * (see pitfalls: https://github.com/fergarrui/ethereum-security/tree/master/contracts/extcodesize).
    *
    * This is only intended to be used as a sanity check that an address is actually a contract,
    * RATHER THAN an address not being a contract.
    */
    function isContract(address _target) internal view returns (bool) {
        if (_target == address(0)) {
            return false;
        }

        uint256 size;
        assembly { size := extcodesize(_target) }
        return size > 0;
    }
}

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;


interface IVaultRecoverable {
    event RecoverToVault(address indexed vault, address indexed token, uint256 amount);

    function transferToVault(address token) external;

    function allowRecoverability(address token) external view returns (bool);
    function getRecoveryVault() external view returns (address);
}

// Inspired by AdEx (https://github.com/AdExNetwork/adex-protocol-eth/blob/b9df617829661a7518ee10f4cb6c4108659dd6d5/contracts/libs/SafeERC20.sol)
// and 0x (https://github.com/0xProject/0x-monorepo/blob/737d1dc54d72872e24abce5a1dbe1b66d35fa21a/contracts/protocol/contracts/protocol/AssetProxy/ERC20Proxy.sol#L143)

pragma solidity ^0.4.24;

import "../lib/token/ERC20.sol";


library SafeERC20 {
    // Before 0.5, solidity has a mismatch between `address.transfer()` and `token.transfer()`:
    // https://github.com/ethereum/solidity/issues/3544
    bytes4 private constant TRANSFER_SELECTOR = 0xa9059cbb;

    string private constant ERROR_TOKEN_BALANCE_REVERTED = "SAFE_ERC_20_BALANCE_REVERTED";
    string private constant ERROR_TOKEN_ALLOWANCE_REVERTED = "SAFE_ERC_20_ALLOWANCE_REVERTED";

    function invokeAndCheckSuccess(address _addr, bytes memory _calldata)
        private
        returns (bool)
    {
        bool ret;
        assembly {
            let ptr := mload(0x40)    // free memory pointer

            let success := call(
                gas,                  // forward all gas
                _addr,                // address
                0,                    // no value
                add(_calldata, 0x20), // calldata start
                mload(_calldata),     // calldata length
                ptr,                  // write output over free memory
                0x20                  // uint256 return
            )

            if gt(success, 0) {
                // Check number of bytes returned from last function call
                switch returndatasize

                // No bytes returned: assume success
                case 0 {
                    ret := 1
                }

                // 32 bytes returned: check if non-zero
                case 0x20 {
                    // Only return success if returned data was true
                    // Already have output in ptr
                    ret := eq(mload(ptr), 1)
                }

                // Not sure what was returned: don't mark as success
                default { }
            }
        }
        return ret;
    }

    function staticInvoke(address _addr, bytes memory _calldata)
        private
        view
        returns (bool, uint256)
    {
        bool success;
        uint256 ret;
        assembly {
            let ptr := mload(0x40)    // free memory pointer

            success := staticcall(
                gas,                  // forward all gas
                _addr,                // address
                add(_calldata, 0x20), // calldata start
                mload(_calldata),     // calldata length
                ptr,                  // write output over free memory
                0x20                  // uint256 return
            )

            if gt(success, 0) {
                ret := mload(ptr)
            }
        }
        return (success, ret);
    }

    /**
    * @dev Same as a standards-compliant ERC20.transfer() that never reverts (returns false).
    *      Note that this makes an external call to the token.
    */
    function safeTransfer(ERC20 _token, address _to, uint256 _amount) internal returns (bool) {
        bytes memory transferCallData = abi.encodeWithSelector(
            TRANSFER_SELECTOR,
            _to,
            _amount
        );
        return invokeAndCheckSuccess(_token, transferCallData);
    }

    /**
    * @dev Same as a standards-compliant ERC20.transferFrom() that never reverts (returns false).
    *      Note that this makes an external call to the token.
    */
    function safeTransferFrom(ERC20 _token, address _from, address _to, uint256 _amount) internal returns (bool) {
        bytes memory transferFromCallData = abi.encodeWithSelector(
            _token.transferFrom.selector,
            _from,
            _to,
            _amount
        );
        return invokeAndCheckSuccess(_token, transferFromCallData);
    }

    /**
    * @dev Same as a standards-compliant ERC20.approve() that never reverts (returns false).
    *      Note that this makes an external call to the token.
    */
    function safeApprove(ERC20 _token, address _spender, uint256 _amount) internal returns (bool) {
        bytes memory approveCallData = abi.encodeWithSelector(
            _token.approve.selector,
            _spender,
            _amount
        );
        return invokeAndCheckSuccess(_token, approveCallData);
    }

    /**
    * @dev Static call into ERC20.balanceOf().
    * Reverts if the call fails for some reason (should never fail).
    */
    function staticBalanceOf(ERC20 _token, address _owner) internal view returns (uint256) {
        bytes memory balanceOfCallData = abi.encodeWithSelector(
            _token.balanceOf.selector,
            _owner
        );

        (bool success, uint256 tokenBalance) = staticInvoke(_token, balanceOfCallData);
        require(success, ERROR_TOKEN_BALANCE_REVERTED);

        return tokenBalance;
    }

    /**
    * @dev Static call into ERC20.allowance().
    * Reverts if the call fails for some reason (should never fail).
    */
    function staticAllowance(ERC20 _token, address _owner, address _spender) internal view returns (uint256) {
        bytes memory allowanceCallData = abi.encodeWithSelector(
            _token.allowance.selector,
            _owner,
            _spender
        );

        (bool success, uint256 allowance) = staticInvoke(_token, allowanceCallData);
        require(success, ERROR_TOKEN_ALLOWANCE_REVERTED);

        return allowance;
    }

    /**
    * @dev Static call into ERC20.totalSupply().
    * Reverts if the call fails for some reason (should never fail).
    */
    function staticTotalSupply(ERC20 _token) internal view returns (uint256) {
        bytes memory totalSupplyCallData = abi.encodeWithSelector(_token.totalSupply.selector);

        (bool success, uint256 totalSupply) = staticInvoke(_token, totalSupplyCallData);
        require(success, ERROR_TOKEN_ALLOWANCE_REVERTED);

        return totalSupply;
    }
}