/**
 *Submitted for verification at Etherscan.io on 2022-06-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface KeeperCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

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

interface IVault {
    function earn() external;
    function token() external view returns (IERC20 _token);
}

contract BaseVaultUpKeep is KeeperCompatibleInterface {
    /// @notice Threshold for the vaults for earn to be called
    mapping(IVault => uint256) public threshold;

    uint256 public gasThreshold;
    address public governance;
    event VaultUpkeepPerformed(address indexed vault);
    event GasThresholdSet(uint256 threshold);
    event GovernanceChanged(address indexed newGovernor);

    constructor() {
        governance = msg.sender;
    }

    modifier onlyGovernance() {
        require(msg.sender == governance, "!gov");
        _;
    }

    modifier checkGasThreshold() {
        require(block.basefee <= gasThreshold, "Gas price above threshold!");
        _;
    }

    /// @notice Sets threshold for a vault
    /// @param vault_ vault for which threshold is to be set
    /// @param threshold_ threshold for the vault
    function setThreshold(IVault vault_, uint256 threshold_)
        external
        onlyGovernance
    {
        threshold[vault_] = threshold_;
    }

    /// @notice Set thresholds for vaults
    /// @param vaults_ vaults for which threshold is to be set
    /// @param thresholds_ thresholds for the related vaults
    function setThresholds(IVault[] memory vaults_, uint256[] memory thresholds_)
        external
        onlyGovernance
    {
        require(vaults_.length == thresholds_.length, "different length");
        for (uint256 i; i < vaults_.length;) {
            threshold[vaults_[i]] = thresholds_[i];
            ++i;
        }
        
    }

    /// @notice Set gas threshold
    /// @param threshold_ gas price
    function setGasThreshold(uint256 threshold_) external onlyGovernance {
        gasThreshold = threshold_;
        emit GasThresholdSet(threshold_);
    }

    function checkUpkeep(
        bytes calldata /* checkData */
    )
        external
        view
        virtual
        override
        returns (
            bool upkeepNeeded,
            bytes memory /* performData */
        )
    {}

    function performUpkeep(
        bytes calldata /* performData */
    ) external virtual override checkGasThreshold {}

    function setGovernance(address newGovernor) external onlyGovernance {
        require(newGovernor != address(0), "!0");
        require(newGovernor != governance, "Same governor!");
        governance = newGovernor;
        emit GovernanceChanged(newGovernor);
    }
}

/// @title A chainlink upkeep contract to call earn on ethereum vaults
/// @author StakeDAO
contract EthereumVaultUpkeep is BaseVaultUpKeep {
    /// @notice Function which returns whether upKeep needs to be done or not
    /// @dev The checkdata will contain the address of the vault to be called
    /// @return upkeepNeeded Returns whether the upkeep needs to be executed
    function checkUpkeep(bytes calldata checkData)
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        // Decoding the received data to an address
        IVault vault = IVault(abi.decode(checkData, (address)));

        // Check if the balance of the vault is greater than the required threshold
        if (
            IERC20(vault.token()).balanceOf(address(vault)) > threshold[vault]
        ) {
            upkeepNeeded = true;
            performData = checkData;
        }
    }

    /// @notice Called by chainlink keeper to perform upkeep & updates the data
    /// @dev The performData will contain the address of the vault
    function performUpkeep(bytes calldata performData)
        external
        override
        checkGasThreshold
    {
        IVault vault = IVault(abi.decode(performData, (address)));

        // Check if the balance of the vault is greater than the required threshold
        if (
            IERC20(vault.token()).balanceOf(address(vault)) > threshold[vault]
        ) {
            vault.earn();
            emit VaultUpkeepPerformed(address(vault));
        }
    }
}