pragma solidity 0.8.12;

/**
 * @author InsureDAO
 * @title Vault contract
 * @notice All underwritten fund is deposited in this contract
 * SPDX-License-Identifier: GPL-3.0
 */

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IOwnership.sol";
import "./interfaces/IVault.sol";
import "./interfaces/IController.sol";
import "./interfaces/IRegistry.sol";

contract Vault is IVault {
    using SafeERC20 for IERC20;

    /**
     * Storage
     */

    address public token;
    IController public controller;
    IRegistry public registry;
    IOwnership public immutable ownership;

    mapping(address => uint256) public debts;
    mapping(address => uint256) public attributions;
    uint256 public totalAttributions;

    uint256 public balance; //balance of underlying token
    uint256 public totalDebt; //total debt balance. 1debt:1token

    uint256 private constant MAGIC_SCALE_1E6 = 1e6; //internal multiplication scale 1e6 to reduce decimal truncation

    event ControllerSet(address controller);

    modifier onlyOwner() {
        require(ownership.owner() == msg.sender, "Caller is not allowed to operate");
        _;
    }

    modifier onlyMarket() {
        require(IRegistry(registry).isListed(msg.sender), "ERROR_ONLY_MARKET");
        _;
    }

    modifier onlyController() {
        require(address(controller) == msg.sender, "Caller is not allowed to operate");
        _;
    }

    constructor(address _token, address _registry, address _controller, address _ownership) {
        require(_token != address(0), "ERROR_ZERO_ADDRESS");
        require(_registry != address(0), "ERROR_ZERO_ADDRESS");
        require(_ownership != address(0), "ERROR_ZERO_ADDRESS");
        //controller can be zero

        token = _token;
        registry = IRegistry(_registry);
        controller = IController(_controller);
        ownership = IOwnership(_ownership);
    }

    /**
     * Vault Functions
     */

    /**
     * @notice A market contract can deposit collateral and get attribution point in return
     * @param  _amount amount of tokens to deposit
     * @param _from sender's address
     * @param _beneficiaries beneficiary's address array
     * @param _shares funds share within beneficiaries (100% = 1e6)
     * @return _allocations attribution amount generated from the transaction
     */
    function addValueBatch(
        uint256 _amount,
        address _from,
        address[2] calldata _beneficiaries,
        uint256[2] calldata _shares
    ) external onlyMarket returns (uint256[2] memory _allocations) {
        require(_shares[0] + _shares[1] == 1000000, "ERROR_INCORRECT_SHARE");

        uint256 _attributions;
        uint256 _pool = valueAll();
        if (totalAttributions == 0) {
            _attributions = _amount;
        } else {
            require(_pool != 0, "ERROR_VALUE_ALL_IS_ZERO"); //should never triggered
            _attributions = (_amount * totalAttributions) / _pool;
        }
        IERC20(token).safeTransferFrom(_from, address(this), _amount);

        balance += _amount;
        totalAttributions += _attributions;

        uint256 _allocation = (_shares[0] * _attributions) / MAGIC_SCALE_1E6;
        attributions[_beneficiaries[0]] += _allocation;
        _allocations[0] = _allocation;

        _allocation = (_shares[1] * _attributions) / MAGIC_SCALE_1E6;
        attributions[_beneficiaries[1]] += _allocation;
        _allocations[1] = _allocation;
    }

    /**
     * @notice A market contract can deposit collateral and get attribution point in return
     * @param  _amount amount of tokens to deposit
     * @param _from sender's address
     * @param _beneficiary beneficiary's address
     * @return _attributions attribution amount generated from the transaction
     */

    function addValue(uint256 _amount, address _from, address _beneficiary)
        external
        onlyMarket
        returns (uint256 _attributions)
    {
        if (totalAttributions == 0) {
            _attributions = _amount;
        } else {
            uint256 _pool = valueAll();
            _attributions = (_amount * totalAttributions) / _pool;
        }
        IERC20(token).safeTransferFrom(_from, address(this), _amount);
        balance += _amount;
        totalAttributions += _attributions;
        attributions[_beneficiary] += _attributions;
    }

    /**
     * @notice an address that has balance in the vault can withdraw underlying value
     * @param _amount amount of tokens to withdraw
     * @param _to address to get underlying tokens
     * @return _attributions amount of attributions burnet
     */
    function withdrawValue(uint256 _amount, address _to) external returns (uint256 _attributions) {
        require(_to != address(0), "ERROR_ZERO_ADDRESS");

        uint256 _valueAll = valueAll();
        require(
            attributions[msg.sender] != 0 && underlyingValue(msg.sender, _valueAll) >= _amount,
            "WITHDRAW-VALUE_BADCONDITIONS"
        );

        _attributions = _divRoundUp(totalAttributions * _amount, valueAll());
        uint256 _available = available();

        require(attributions[msg.sender] >= _attributions, "WITHDRAW-VALUE_BADCONDITIONS");
        attributions[msg.sender] -= _attributions;

        totalAttributions -= _attributions;

        if (_available < _amount) {
            //when USDC in this contract isn't enough
            uint256 _shortage;
            unchecked {
                _shortage = _amount - _available;
            }
            _unutilize(_shortage);

            require(available() >= _amount, "Withdraw amount > Available");
        }

        balance -= _amount;
        IERC20(token).safeTransfer(_to, _amount);
    }

    /**
     * @notice an address that has balance in the vault can transfer underlying value
     * @param _amount sender of value
     * @param _destination reciepient of value
     */

    function transferValue(uint256 _amount, address _destination) external returns (uint256 _attributions) {
        require(_destination != address(0), "ERROR_ZERO_ADDRESS");

        uint256 _valueAll = valueAll();

        require(
            attributions[msg.sender] != 0 && underlyingValue(msg.sender, _valueAll) >= _amount,
            "TRANSFER-VALUE_BADCONDITIONS"
        );
        _attributions = _divRoundUp(totalAttributions * _amount, valueAll());
        attributions[msg.sender] -= _attributions;
        attributions[_destination] += _attributions;
    }

    /**
     * @notice a registered contract can borrow balance from the vault
     * @param _amount borrow amount
     * @param _to borrower's address
     */
    function borrowValue(uint256 _amount, address _to) external onlyMarket {
        if (_amount != 0) {
            uint256 _available = available();

            if (_available < _amount) {
                //when USDC in this contract isn't enough
                uint256 _shortage;
                unchecked {
                    _shortage = _amount - _available;
                }
                _unutilize(_shortage);

                require(available() >= _amount, "Withdraw amount > Available");
            }

            debts[msg.sender] += _amount;
            totalDebt += _amount;

            IERC20(token).safeTransfer(_to, _amount);
        }
    }

    /**
     * @notice simply, add underlying asset without granting attribution to the sender.
     * @param _amount adding amount
     * @dev This performs like investment feature. Good to use for distributing revenue for all underwriters.
     * This function results increasing of attributionValue().
     */
    function addBalance(uint256 _amount) external onlyMarket {
        IERC20(token).safeTransferFrom(msg.sender, address(this), _amount);
        balance += _amount;
    }

    /**
     * @notice an address that has balance in the vault can offset an address's debt
     * @param _amount debt amount to offset
     * @param _target borrower's address
     */

    function offsetDebt(uint256 _amount, address _target) external returns (uint256 _attributions) {
        uint256 _valueAll = valueAll();
        require(
            attributions[msg.sender] != 0 && underlyingValue(msg.sender, _valueAll) >= _amount,
            "ERROR_REPAY_DEBT_BADCONDITIONS"
        );
        _attributions = _divRoundUp(totalAttributions * _amount, valueAll());
        attributions[msg.sender] -= _attributions;
        totalAttributions -= _attributions;
        balance -= _amount;
        debts[_target] -= _amount;
        totalDebt -= _amount;
    }

    /**
     * @notice a registerd market can transfer their debt to system debt
     * @param _amount debt amount to transfer
     * @dev will be called when Reserve could not afford when resume the market.
     */
    function transferDebt(uint256 _amount) external onlyMarket {
        if (_amount != 0) {
            debts[msg.sender] -= _amount;
            debts[address(0)] += _amount;
        }
    }

    /**
     * @notice anyone can repay the system debt by sending tokens to this contract
     * @param _amount debt amount to repay
     * @param _target borrower's address
     */
    function repayDebt(uint256 _amount, address _target) external {
        uint256 _debt = debts[_target];

        if (_debt > _amount) {
            unchecked {
                debts[_target] = _debt - _amount;
            }
        } else {
            debts[_target] = 0;
            _amount = _debt;
        }
        totalDebt -= _amount;
        IERC20(token).safeTransferFrom(msg.sender, address(this), _amount);
    }

    /**
     * @notice an address that has balance in the vault can withdraw value denominated in attribution
     * @param _attribution amount of attribution to burn
     * @param _to beneficiary's address
     * @return _retVal number of tokens withdrawn from the transaction
     */
    function withdrawAttribution(uint256 _attribution, address _to) external returns (uint256 _retVal) {
        require(_to != address(0), "ERROR_ZERO_ADDRESS");

        _retVal = _withdrawAttribution(_attribution, _to);
    }

    /**
     * @notice an address that has balance in the vault can withdraw all value
     * @param _to beneficiary's address
     * @return _retVal number of tokens withdrawn from the transaction
     */
    function withdrawAllAttribution(address _to) external returns (uint256 _retVal) {
        require(_to != address(0), "ERROR_ZERO_ADDRESS");

        _retVal = _withdrawAttribution(attributions[msg.sender], _to);
    }

    /**
     * @notice See _renounceAttribution() below.
     */
    function renounceAttribution(uint256 _attribution) external returns (uint256) {
        return _renounceAttribution(_attribution);
    }

    /**
     * @notice Burn sender's all attribution. See _renounceAttribution() below.
     */
    function renounceAllAttribution() external {
        _renounceAttribution(attributions[msg.sender]);
    }

    /**
     * @notice Burn sender's attribution.
     * @param _attribution amount to be burnt
     * @return . remaining attribution
     * @dev This function results increasing of attributionValue().
     */
    function _renounceAttribution(uint256 _attribution) internal returns (uint256) {
        uint256 _userAttribution = attributions[msg.sender];
        require(_userAttribution >= _attribution, "_attribution exceed your holding");

        unchecked {
            attributions[msg.sender] -= _attribution;
        }
        totalAttributions -= _attribution;

        return attributions[msg.sender];
    }

    /**
     * @notice an address that has balance in the vault can withdraw all value
     * @param _attribution amount of attribution to burn
     * @param _to beneficiary's address
     * @return _retVal number of tokens withdrawn from the transaction
     */
    function _withdrawAttribution(uint256 _attribution, address _to) internal returns (uint256 _retVal) {
        require(attributions[msg.sender] >= _attribution, "WITHDRAW-ATTRIBUTION_BADCONS");
        uint256 _available = available();
        _retVal = (_attribution * valueAll()) / totalAttributions;

        unchecked {
            attributions[msg.sender] -= _attribution;
        }
        totalAttributions -= _attribution;

        if (_available < _retVal) {
            uint256 _shortage;
            unchecked {
                _shortage = _retVal - _available;
            }
            _unutilize(_shortage);
        }

        balance -= _retVal;
        IERC20(token).safeTransfer(_to, _retVal);
    }

    /**
     * @notice an address that has balance in the vault can transfer value denominated in attribution
     * @param _amount amount of attribution to transfer
     * @param _destination reciepient of attribution
     */
    function transferAttribution(uint256 _amount, address _destination) external {
        require(_destination != address(0), "ERROR_ZERO_ADDRESS");

        require(_amount != 0 && attributions[msg.sender] >= _amount, "TRANSFER-ATTRIBUTION_BADCONS");

        unchecked {
            attributions[msg.sender] -= _amount;
        }
        attributions[_destination] += _amount;
    }

    /**
     * @notice get attribution number for the specified address
     * @param _target target address
     * @return amount of attritbution
     */

    function attributionOf(address _target) external view returns (uint256) {
        return attributions[_target];
    }

    /**
     * @notice get all attribution number for this contract
     * @return amount of all attribution
     */
    function attributionAll() external view returns (uint256) {
        return totalAttributions;
    }

    /**
     * @notice Convert attribution number into underlying assset value
     * @param _attribution amount of attribution
     * @return token value of input attribution
     */
    function attributionValue(uint256 _attribution) external view returns (uint256) {
        uint256 _totalAttributions = totalAttributions;

        if (_totalAttributions != 0 && _attribution != 0) {
            return (_attribution * valueAll()) / _totalAttributions;
        }
    }

    /**
     * @notice return underlying value of the specified address
     * @param _target target address
     * @return token value of target address
     */
    function underlyingValue(address _target) public view returns (uint256) {
        uint256 _valueAll = valueAll();
        uint256 attribution = attributions[_target];

        if (_valueAll != 0 && attribution != 0) {
            return (_valueAll * attribution) / totalAttributions;
        }
    }

    function underlyingValue(address _target, uint256 _valueAll) public view returns (uint256) {
        uint256 attribution = attributions[_target];
        if (_valueAll != 0 && attribution != 0) {
            return (_valueAll * attribution) / totalAttributions;
        }
    }

    /**
     * @notice return underlying value of this contract
     * @return all token value of the vault
     */
    function valueAll() public view returns (uint256) {
        if (address(controller) != address(0)) {
            return balance + controller.managingFund();
        } else {
            return balance;
        }
    }

    /**
     * @notice return how much funds in this contract is available to be utilized
     * @return available balance to utilize
     */
    function available() public view returns (uint256) {
        return balance - totalDebt;
    }

    /**
     * @notice return how much price for each attribution
     * @return value of one share of attribution
     */
    function getPricePerFullShare() external view returns (uint256) {
        return (valueAll() * MAGIC_SCALE_1E6) / totalAttributions;
    }

    /**
     * Interaction with Controller
     */

    /**
     * @notice utilize all available underwritten funds into the set controller.
     * @return _amount amount of tokens utilized
     */
    function utilize(uint256 _amount) external onlyController returns (uint256) {
        require(_amount <= available(), "EXCEED_AVAILABLE");

        if (_amount != 0) {
            IERC20(token).safeTransfer(address(controller), _amount);
            balance -= _amount;
        }

        return _amount;
    }

    /**
     * @notice internal function to unutilize the funds and keep utilization rate
     * @param _amount amount to withdraw from controller
     */
    function _unutilize(uint256 _amount) internal returns (uint256) {
        require(address(controller) != address(0), "ERROR_CONTROLLER_NOT_SET");

        if (_amount != 0) {
            uint256 beforeBalance = IERC20(token).balanceOf(address(this));
            controller.returnFund(_amount);
            uint256 received = IERC20(token).balanceOf(address(this)) - beforeBalance;
            require(received >= _amount, "ERROR_INSUFFICIENT_RETURN_VALUE");
            balance += received;

            return received;
        }
    }

    /**
     * onlyOwner
     */

    /**
     * @notice withdraw redundant token stored in this contract
     * @param _token token address
     * @param _to beneficiary's address
     */
    function withdrawRedundant(address _token, address _to) external onlyOwner {
        uint256 _balance = balance;
        uint256 _tokenBalance = IERC20(_token).balanceOf(address(this));
        if (_token == token && _balance < _tokenBalance) {
            uint256 _utilized = controller.managingFund();
            uint256 _actualValue = IERC20(token).balanceOf(address(this)) + _utilized;
            uint256 _virtualValue = balance + _utilized;
            if (_actualValue > _virtualValue) {
                uint256 _redundant;
                unchecked {
                    _redundant = _tokenBalance - _balance;
                }
                IERC20(token).safeTransfer(_to, _redundant);
            }
        } else if (_token != address(token) && _tokenBalance != 0) {
            IERC20(_token).safeTransfer(_to, _tokenBalance);
        }
    }

    /**
     * @notice admin function to set controller address
     * @param _controller address of the controller
     */
    function setController(address _controller) external onlyOwner {
        require(_controller != address(0), "ERROR_ZERO_ADDRESS");

        if (address(controller) != address(0)) {
            uint256 beforeUnderlying = controller.managingFund();
            controller.emigrate(address(_controller));
            require(IController(_controller).managingFund() >= beforeUnderlying, "ERROR_VALUE_ALL_DECREASED");
        }
        controller = IController(_controller);

        emit ControllerSet(_controller);
    }

    /**
     * @notice internal division function to prevent underflow
     * @param _a number to get divided by _b
     * @param _b number to divide _a
     */
    function _divRoundUp(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_a >= _b, "ERROR_NUMERATOR_TOO_SMALL");
        uint256 _c = _a / _b;
        if (_c * _b != _a) {
            _c += 1;
        }
        return _c;
    }
}

pragma solidity 0.8.12;

//SPDX-License-Identifier: MIT

interface IOwnership {
    function owner() external view returns (address);

    function futureOwner() external view returns (address);

    function commitTransferOwnership(address newOwner) external;

    function acceptTransferOwnership() external;
}

pragma solidity 0.8.12;

interface IVault {
    function addValueBatch(
        uint256 _amount,
        address _from,
        address[2] memory _beneficiaries,
        uint256[2] memory _shares
    ) external returns (uint256[2] memory _allocations);

    function addValue(
        uint256 _amount,
        address _from,
        address _attribution
    ) external returns (uint256 _attributions);

    function withdrawValue(uint256 _amount, address _to) external returns (uint256 _attributions);

    function transferValue(uint256 _amount, address _destination) external returns (uint256 _attributions);

    function withdrawAttribution(uint256 _attribution, address _to) external returns (uint256 _retVal);

    function withdrawAllAttribution(address _to) external returns (uint256 _retVal);

    function transferAttribution(uint256 _amount, address _destination) external;

    function attributionOf(address _target) external view returns (uint256);

    function underlyingValue(address _target) external view returns (uint256);

    function attributionValue(uint256 _attribution) external view returns (uint256);

    function utilize(uint256 _amount) external returns (uint256);

    function valueAll() external view returns (uint256);

    function token() external returns (address);

    function balance() external view returns (uint256);

    function available() external view returns (uint256);

    function borrowValue(uint256 _amount, address _to) external;

    /*
    function borrowAndTransfer(uint256 _amount, address _to)
        external
        returns (uint256 _attributions);
    */

    function offsetDebt(uint256 _amount, address _target) external returns (uint256 _attributions);

    function repayDebt(uint256 _amount, address _target) external;

    function debts(address _debtor) external view returns (uint256);

    function transferDebt(uint256 _amount) external;

    //onlyOwner
    function withdrawRedundant(address _token, address _to) external;

    function setController(address _controller) external;
}

pragma solidity 0.8.12;

interface IRegistry {
    function isListed(address _market) external view returns (bool);

    function getReserve(address _address) external view returns (address);

    function confirmExistence(address _template, address _target) external view returns (bool);

    //onlyOwner
    function setFactory(address _factory) external;

    function addPool(address _market) external;

    function setExistence(address _template, address _target) external;

    function setReserve(address _address, address _reserve) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

/**
 * @title IController
 * @author @InsureDAO
 * @dev Defines the basic interface for an InsureDAO Controller.
 * @notice Controller invests market deposited tokens on behalf of Vault contract.
 *         This contract gets utilized a vault assets then invests these assets via
 *         Strategy contract. To Avoid unnecessary complexity, sometimes the controller
 *         includes the functionality of a strategy.
 */
interface IController {
    /**
     * @notice Utilizes a vault fund to strategies, which invest fund to
     *         various protocols. Vault fund is utilized up to maxManagingRatio
     *         determined by the owner.
     * @dev You **should move all pulled fund to strategies** in this function
     *      to avoid unnecessary complexity of asset management.
     *      Controller exists to route vault fund to strategies safely.
     */
    function adjustFund() external;

    /**
     * @notice Returns utilized fund to a vault. If the amount exceeds all
     *         assets the controller manages, transaction should be reverted.
     * @param _amount the amount to be returned to a vault
     */
    function returnFund(uint256 _amount) external;

    /**
     * @notice Returns all assets this controller manages. Value is denominated
     *         in USDC token amount. (e.g. If the controller utilizes 100 USDC
     *         for strategies, valueAll() returns 100,000,000(100 * 1e6)) .
     */
    function managingFund() external view returns (uint256);

    /**
     * @notice The proportion of a vault fund to be utilized. 1e6 regarded as 100%.
     */
    function maxManagingRatio() external view returns (uint256);

    /**
     * @notice Changes maxManagingRatio which
     * @param _ratio maxManagingRatio to be set. See maxManagingRatio() for more detail
     */
    function setMaxManagingRatio(uint256 _ratio) external;

    /**
     * @notice Returns the proportion of a vault fund managed by the controller.
     */
    function currentManagingRatio() external view returns (uint256);

    /**
     * @notice Moves managing asset to new controller. Only vault should call
     *         this method for safety.
     * @param _to the destination of migration. this address should be a
     *            controller address as this method expected call immigrate() internally.
     */
    function emigrate(address _to) external;

    /**
     * @notice Receives the asset from old controller. New controller should call this method.
     * @param _from The address that fund received from. the address should be a controller address.
     */
    function immigrate(address _from) external;

    /**
     * @notice Sends managing fund to any address. This method should be called in case that
     *         managing fund cannot be moved by the controller (e.g. A protocol contract is
     *         temporary unavailable so the controller cannot withdraw managing fund directly,
     *         where emergencyExit() should move to the right to take reward like aUSDC on Aave).
     * @param _to The address that fund will be sent.
     */
    function emergencyExit(address _to) external;
}

error RatioOutOfRange();
error ExceedManagingRatio();
error AlreadyInUse();
error AaveSupplyCapExceeded();
error InsufficientManagingFund();
error InsufficientRewardToWithdraw();
error NoRewardClaimable();
error MigrateToSelf();
error SameAddressUsed();

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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
                /// @solidity memory-safe-assembly
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