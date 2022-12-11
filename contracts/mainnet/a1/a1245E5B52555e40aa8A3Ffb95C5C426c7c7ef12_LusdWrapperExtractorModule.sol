/**
 *Submitted for verification at Etherscan.io on 2022-12-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface Enum {
    enum Operation {
        Call,
        DelegateCall
    }
}


interface GnosisSafe {
    /// @dev Allows a Module to execute a Safe transaction without any further confirmations.
    /// @param to Destination address of module transaction.
    /// @param value Ether value of module transaction.
    /// @param data Data payload of module transaction.
    /// @param operation Operation type of module transaction.
    function execTransactionFromModule(address to, uint256 value, bytes calldata data, Enum.Operation operation)
        external
        returns (bool success);
}

interface IMinimalSystemSettings {
      function wrapperBurnFeeRate(address wrapper) external view returns (int);
}


interface IAddressResolver {
    function getAddress(bytes32 name) external view returns (address);

    function getSynth(bytes32 key) external view returns (address);

    function requireAndGetAddress(bytes32 name, string calldata reason) external view returns (address);
}


interface IWrapper {
    function mint(uint amount) external;

    function burn(uint amount) external;

    function capacity() external view returns (uint);

    function totalIssuedSynths() external view returns (uint);

    function calculateMintFee(uint amount) external view returns (uint, bool);

    function calculateBurnFee(uint amount) external view returns (uint, bool);

    function maxTokenAmount() external view returns (uint256);

    function mintFeeRate() external view returns (int256);

    function burnFeeRate() external view returns (int256);
}


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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}


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



contract LusdWrapperExtractorModule is ReentrancyGuard {
    string public constant NAME = "LUSD Wrapper Extractor Module";
    string public constant VERSION = "0.1.0";

    uint256 public constant RETRIEVE_ALL = 0;
    uint256 public constant RETRIEVE_SUSD = 1;
    uint256 public constant RETRIEVE_LUSD = 2;
    uint256 public constant RETRIEVE_ETH = 3;
    
    // Contract/Accounts
    address DEPLOYER_ADDRESS = 0x302d2451d9f47620374B54c521423Bf0403916A2;
    address PDAO_MULTISIG_ADDRESS = 0xEb3107117FEAd7de89Cd14D463D340A2E6917769;
    address LUSD_WRAPPER_ADDRESS = 0x7C22547779c8aa41bAE79E03E8383a0BefBCecf0;    
    address SYSTEM_SETTINGS_ADDRESS = 0x202ae40Bed1640b09e2AF7aC5719D129A498B7C8;
    address ADDRESS_RESOLVER = 0x823bE81bbF96BEc0e25CA13170F5AaCb5B79ba83;

    // Tokens
    address LUSD_ADDRESS = 0x5f98805A4E8be255a32880FDeC7F6728C6568bA0;


    error InvalidSender(address sender);
    error InvalidAmount();
    error ExecutionFailed(uint256 atStep);
    error InvalidAmounts(uint256 sUSDAmount, uint256 lusdAmountBefore, uint256 lusdAmountAfter);
    event Burnt(address sender, address from, address to, uint256 sUSDAmount, uint256 lusdAmountBefore, uint256 lusdAmountAfter);

    function burnFromWrapper(uint256 susdToBurn) nonReentrant external {
        bool success;
        
        // 0- Initial Checks
        // 0.1 sender
        if (msg.sender != DEPLOYER_ADDRESS) {
            revert InvalidSender(msg.sender);
        }

        // 0.2- Check amount is positive
        if (susdToBurn == 0) {
            revert InvalidAmount();
        }

        // 0.3- Check address(this) has the sUSD amount to burn
        uint sUSDBalance = _getSUSDContract().balanceOf(address(this));
        if (sUSDBalance < susdToBurn) {
            revert InvalidAmount();
        }
            
        // 1- Read current burn fee rate
        int256 previousBurnFeeRate = IMinimalSystemSettings(SYSTEM_SETTINGS_ADDRESS).wrapperBurnFeeRate(LUSD_WRAPPER_ADDRESS);

        // 2- Decrease wrapper burn fee rate to zero
        success = _executeSafeTransactionSetBurnFeeRate(0);
        if (!success) {
            revert ExecutionFailed(2);
        }

        // 3.0- pre-check get before LUSD balance of pDAO
        uint beforeLUSDBalance = IERC20(LUSD_ADDRESS).balanceOf(PDAO_MULTISIG_ADDRESS);

        // 3- Burn synth
        IWrapper(LUSD_WRAPPER_ADDRESS).burn(susdToBurn);

        // 4- Reset wrapper burn fee rate to previous value
        success = _executeSafeTransactionSetBurnFeeRate(previousBurnFeeRate);
        if (!success) {
            revert ExecutionFailed(4);
        }

        // 5- Transfer LUSD to pDAO (or destination address)
        IERC20(LUSD_ADDRESS).transfer(PDAO_MULTISIG_ADDRESS, susdToBurn);

        // 6- Check delta LUSD on pDAO == sUSD (amount)
        uint afterLUSDBalance = IERC20(LUSD_ADDRESS).balanceOf(PDAO_MULTISIG_ADDRESS);
        if (afterLUSDBalance != (susdToBurn + beforeLUSDBalance)) {
            revert InvalidAmounts(susdToBurn, beforeLUSDBalance, afterLUSDBalance);
        }

        // 7- Emit event with results
        emit Burnt(msg.sender, address(this), PDAO_MULTISIG_ADDRESS, susdToBurn, beforeLUSDBalance, afterLUSDBalance);
    }

    function retrievePendingBalance(uint kind) nonReentrant external {
        // fallback to send any outstanding balance to pDAO
        if (kind == RETRIEVE_ALL || kind == RETRIEVE_SUSD) {
            // Transfer any outstanding sUSD, 
            uint sUSDBalance = _getSUSDContract().balanceOf(address(this));
            _getSUSDContract().transfer(PDAO_MULTISIG_ADDRESS, sUSDBalance);
        }

        if (kind == RETRIEVE_ALL || kind == RETRIEVE_LUSD) {
            // Transfer any outstanding LUSD,
            uint lUSDBalance = IERC20(LUSD_ADDRESS).balanceOf(address(this));
            IERC20(LUSD_ADDRESS).transfer(PDAO_MULTISIG_ADDRESS, lUSDBalance);
        }

        if (kind == RETRIEVE_ALL || kind == RETRIEVE_ETH) {
            // Transfer any outstanding ETH
            payable(PDAO_MULTISIG_ADDRESS).transfer(address(this).balance);
        }
    }

    function _getSUSDContract() internal view returns (IERC20) {
        return IERC20(IAddressResolver(ADDRESS_RESOLVER).getAddress('ProxysUSD'));
    }

    function _executeSafeTransactionSetBurnFeeRate(int256 burnFeeRate) internal returns (bool success) {
        GnosisSafe safe = GnosisSafe(PDAO_MULTISIG_ADDRESS);

        bytes memory payload = abi.encodeWithSignature("setWrapperBurnFeeRate(address,int256)", LUSD_WRAPPER_ADDRESS, burnFeeRate);

        success = safe.execTransactionFromModule(SYSTEM_SETTINGS_ADDRESS, 0, payload, Enum.Operation.Call);
    }
}