// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "./Base/ERC20/ERC20BaseToken.sol";
import "./Base/ERC20/extensions/ERC20BasicApproveExtension.sol";

contract CosmBaseToken is ERC20BaseToken, ERC20BasicApproveExtension {
  constructor(
    address CosmAdmin,
    address executionAdmin,
    address beneficiary,
    uint256 amount //need to remove unused var
  ) ERC20BaseToken("COSMITE TEST TOKEN", "tCSMT", CosmAdmin, executionAdmin) {
    //choose name and symbol name
    _admin = CosmAdmin;
    if (beneficiary != address(0)) {
      uint256 initialSupply = amount * 10**18; //need to change this
      _mint(beneficiary, initialSupply);
    }
  }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./WithAdmin.sol";

contract WithSuperOperators is WithAdmin {
  mapping(address => bool) internal _superOperators;

  event SuperOperator(address superOperator, bool enabled);

  /// @notice Enable or disable the ability of `superOperator` to transfer tokens of all (superOperator rights).
  /// @param superOperator address that will be given/removed superOperator right.
  /// @param enabled set whether the superOperator is enabled or disabled.
  function setSuperOperator(address superOperator, bool enabled) external {
    require(
      msg.sender == _admin,
      "only admin is allowed to add super operators"
    );
    _superOperators[superOperator] = enabled;
    emit SuperOperator(superOperator, enabled);
  }

  /// @notice check whether address `who` is given superOperator rights.
  /// @param who The address to query.
  /// @return whether the address has superOperator rights.
  function isSuperOperator(address who) public view returns (bool) {
    return _superOperators[who];
  }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract WithAdmin {
  address internal _admin;

  /// @dev Emits when the contract administrator is changed.
  /// @param oldAdmin The address of the previous administrator.
  /// @param newAdmin The address of the new administrator.
  event AdminChanged(address oldAdmin, address newAdmin);

  modifier onlyAdmin() {
    require(msg.sender == _admin, "ADMIN_ONLY");
    _;
  }

  /// @dev Get the current administrator of this contract.
  /// @return The current administrator of this contract.
  function getAdmin() external view returns (address) {
    return _admin;
  }

  /// @dev Change the administrator to be `newAdmin`.
  /// @param newAdmin The address of the new administrator.
  function changeAdmin(address newAdmin) external {
    require(msg.sender == _admin, "ADMIN_ACCESS_DENIED");
    emit AdminChanged(_admin, newAdmin);
    _admin = newAdmin;
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

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library BytesUtil {
  uint256 private constant DATA_MIN_LENGTH = 68;

  /// @dev Check if the data == _address.
  /// @param data The bytes passed to the function.
  /// @param _address The address to compare to.
  /// @return Whether the first param == _address.
  function doFirstParamEqualsAddress(bytes memory data, address _address)
    internal
    pure
    returns (bool)
  {
    if (data.length < DATA_MIN_LENGTH) {
      return false;
    }
    uint256 value;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      value := mload(add(data, 36))
    }
    return value == uint256(uint160(_address));
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./IERC20.sol";

interface IERC20Extended is IERC20 {
    function burnFor(address from, uint256 amount) external;

    function burn(uint256 amount) external;

    function approveFor(
        address owner,
        address spender,
        uint256 amount
    ) external returns (bool success);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @dev see https://eips.ethereum.org/EIPS/eip-20
interface IERC20 {
    /// @notice emitted when tokens are transfered from one address to another.
    /// @param from address from which the token are transfered from (zero means tokens are minted).
    /// @param to destination address which the token are transfered to (zero means tokens are burnt).
    /// @param value amount of tokens transferred.
    event Transfer(address indexed from, address indexed to, uint256 value);

    /// @notice emitted when owner grant transfer rights to another address
    /// @param owner address allowing its token to be transferred.
    /// @param spender address allowed to spend on behalf of `owner`
    /// @param value amount of tokens allowed.
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice return the current total amount of tokens owned by all holders.
    /// @return supply total number of tokens held.
    function totalSupply() external view returns (uint256 supply);

    /// @notice return the number of tokens held by a particular address.
    /// @param who address being queried.
    /// @return balance number of token held by that address.
    function balanceOf(address who) external view returns (uint256 balance);

    /// @notice transfer tokens to a specific address.
    /// @param to destination address receiving the tokens.
    /// @param value number of tokens to transfer.
    /// @return success whether the transfer succeeded.
    function transfer(address to, uint256 value) external returns (bool success);

    /// @notice transfer tokens from one address to another.
    /// @param from address tokens will be sent from.
    /// @param to destination address receiving the tokens.
    /// @param value number of tokens to transfer.
    /// @return success whether the transfer succeeded.
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool success);

    /// @notice approve an address to spend on your behalf.
    /// @param spender address entitled to transfer on your behalf.
    /// @param value amount allowed to be transfered.
    /// @param success whether the approval succeeded.
    function approve(address spender, uint256 value) external returns (bool success);

    /// @notice return the current allowance for a particular owner/spender pair.
    /// @param owner address allowing spender.
    /// @param spender address allowed to spend.
    /// @return amount number of tokens `spender` can spend on behalf of `owner`.
    function allowance(address owner, address spender) external view returns (uint256 amount);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract ERC20Internal {
    function _approveFor(
        address owner,
        address target,
        uint256 amount
    ) internal virtual;

    function _addAllowanceIfNeeded(
        address owner,
        address spender,
        uint256 amountNeeded
    ) internal virtual;

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual;
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../../utils/Context.sol";
import "./ERC20Internal.sol";
import "../../../utils/BytesUtil.sol";

abstract contract ERC20BasicApproveExtension is ERC20Internal, Context {
    /// @notice Approve `target` to spend `amount` and call it with data.
    /// @param target The address to be given rights to transfer and destination of the call.
    /// @param amount The number of tokens allowed.
    /// @param data The bytes for the call.
    /// @return The data of the call.
    function approveAndCall(
        address target,
        uint256 amount,
        bytes calldata data
    ) external payable returns (bytes memory) {
        require(BytesUtil.doFirstParamEqualsAddress(data, _msgSender()), "FIRST_PARAM_NOT_SENDER");

        _approveFor(_msgSender(), target, amount);

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returnData) = target.call{value: msg.value}(data);
        require(success, string(returnData));
        return returnData;
    }

    /// @notice Temporarily approve `target` to spend `amount` and call it with data.
    /// Previous approvals remains unchanged.
    /// @param target The destination of the call, allowed to spend the amount specified
    /// @param amount The number of tokens allowed to spend.
    /// @param data The bytes for the call.
    /// @return The data of the call.
    function paidCall(
        address target,
        uint256 amount,
        bytes calldata data
    ) external payable returns (bytes memory) {
        require(BytesUtil.doFirstParamEqualsAddress(data, _msgSender()), "FIRST_PARAM_NOT_SENDER");

        if (amount > 0) {
            _addAllowanceIfNeeded(_msgSender(), target, amount);
        }

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returnData) = target.call{value: msg.value}(data);
        require(success, string(returnData));

        return returnData;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../utils/Context.sol";
import "./extensions/ERC20Internal.sol";
import "../../interfaces/IERC20Extended.sol";
import "../../utils/WithSuperOperators.sol";

abstract contract ERC20BaseToken is WithSuperOperators, IERC20, IERC20Extended, ERC20Internal, Context {
    string internal _name;
    string internal _symbol;
    address internal immutable _operator;
    uint256 internal _totalSupply;
    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) internal _allowances;

    constructor(
        string memory tokenName,
        string memory tokenSymbol,
        address admin,
        address operator
    ) {
        _name = tokenName;
        _symbol = tokenSymbol;
        _admin = admin;
        _operator = operator;
    }

    /// @notice Transfer `amount` tokens to `to`.
    /// @param to The recipient address of the tokens being transfered.
    /// @param amount The number of tokens being transfered.
    /// @return success Whether or not the transfer succeeded.
    function transfer(address to, uint256 amount) external override returns (bool success) {
        _transfer(_msgSender(), to, amount);
        return true;
    }

    /// @notice Transfer `amount` tokens from `from` to `to`.
    /// @param from The origin address  of the tokens being transferred.
    /// @param to The recipient address of the tokensbeing  transfered.
    /// @param amount The number of tokens transfered.
    /// @return success Whether or not the transfer succeeded.
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external override returns (bool success) {
        if (_msgSender() != from && !_superOperators[_msgSender()] && _msgSender() != _operator) {
            uint256 currentAllowance = _allowances[from][_msgSender()];
            if (currentAllowance != ~uint256(0)) {
                // save gas when allowance is maximal by not reducing it (see https://github.com/ethereum/EIPs/issues/717)
                require(currentAllowance >= amount, "NOT_AUTHORIZED_ALLOWANCE");
                _allowances[from][_msgSender()] = currentAllowance - amount;
            }
        }
        _transfer(from, to, amount);
        return true;
    }

    /// @notice Burn `amount` tokens.
    /// @param amount The number of tokens to burn.
    function burn(uint256 amount) external override {
        _burn(_msgSender(), amount);
    }

    /// @notice Burn `amount` tokens from `owner`.
    /// @param from The address whose token to burn.
    /// @param amount The number of tokens to burn.
    function burnFor(address from, uint256 amount) external override {
        _burn(from, amount);
    }

    /// @notice Approve `spender` to transfer `amount` tokens.
    /// @param spender The address to be given rights to transfer.
    /// @param amount The number of tokens allowed.
    /// @return success Whether or not the call succeeded.
    function approve(address spender, uint256 amount) external override returns (bool success) {
        _approveFor(_msgSender(), spender, amount);
        return true;
    }

    /// @notice Get the name of the token collection.
    /// @return The name of the token collection.
    function name() external view virtual returns (string memory) {
        //added virtual
        return _name;
    }

    /// @notice Get the symbol for the token collection.
    /// @return The symbol of the token collection.
    function symbol() external view virtual returns (string memory) {
        //added virtual
        return _symbol;
    }

    /// @notice Get the total number of tokens in existence.
    /// @return The total number of tokens in existence.
    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    /// @notice Get the balance of `owner`.
    /// @param owner The address to query the balance of.
    /// @return The amount owned by `owner`.
    function balanceOf(address owner) external view override returns (uint256) {
        return _balances[owner];
    }

    /// @notice Get the allowance of `spender` for `owner`'s tokens.
    /// @param owner The address whose token is allowed.
    /// @param spender The address allowed to transfer.
    /// @return remaining The amount of token `spender` is allowed to transfer on behalf of `owner`.
    function allowance(address owner, address spender) external view override returns (uint256 remaining) {
        return _allowances[owner][spender];
    }

    /// @notice Get the number of decimals for the token collection.
    /// @return The number of decimals.
    function decimals() external pure virtual returns (uint8) {
        return uint8(18);
    }

    /// @notice Approve `spender` to transfer `amount` tokens from `owner`.
    /// @param owner The address whose token is allowed.
    /// @param spender The address to be given rights to transfer.
    /// @param amount The number of tokens allowed.
    /// @return success Whether or not the call succeeded.
    function approveFor(
        address owner,
        address spender,
        uint256 amount
    ) public override returns (bool success) {
        require(_msgSender() == owner || _superOperators[_msgSender()] || _msgSender() == _operator, "NOT_AUTHORIZED");
        _approveFor(owner, spender, amount);
        return true;
    }

    /// @notice Increase the allowance for the spender if needed
    /// @param owner The address of the owner of the tokens
    /// @param spender The address wanting to spend tokens
    /// @param amountNeeded The amount requested to spend
    /// @return success Whether or not the call succeeded.
    function addAllowanceIfNeeded(
        address owner,
        address spender,
        uint256 amountNeeded
    ) public returns (bool success) {
        require(_msgSender() == owner || _superOperators[_msgSender()] || _msgSender() == _operator, "INVALID_SENDER");
        _addAllowanceIfNeeded(owner, spender, amountNeeded);
        return true;
    }

    /// @dev See addAllowanceIfNeeded.
    function _addAllowanceIfNeeded(
        address owner,
        address spender,
        uint256 amountNeeded /*(ERC20Internal, ERC20ExecuteExtension, ERC20BasicApproveExtension)*/
    ) internal virtual override {
        if (amountNeeded > 0 && !isSuperOperator(spender) && spender != _operator) {
            uint256 currentAllowance = _allowances[owner][spender];
            if (currentAllowance < amountNeeded) {
                _approveFor(owner, spender, amountNeeded);
            }
        }
    }

    /// @dev See approveFor.
    function _approveFor(
        address owner,
        address spender,
        uint256 amount /*(ERC20BasicApproveExtension, ERC20Internal)*/
    ) internal virtual override {
        require(owner != address(0) && spender != address(0), "INVALID_OWNER_||_SPENDER");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /// @dev See transfer.
    function _transfer(
        address from,
        address to,
        uint256 amount /*(ERC20Internal, ERC20ExecuteExtension)*/
    ) internal virtual override {
        require(to != address(0), "NOT_TO_ZEROADDRESS");
        require(to != address(this), "NOT_TO_THIS");
        uint256 currentBalance = _balances[from];
        require(currentBalance >= amount, "INSUFFICIENT_FUNDS");
        _balances[from] = currentBalance - amount;
        _balances[to] += amount;
        emit Transfer(from, to, amount);
    }

    /// @dev Mint tokens for a recipient.
    /// @param to The recipient address.
    /// @param amount The number of token to mint.
    function _mint(address to, uint256 amount) internal {
        require(to != address(0), "NOT_TO_ZEROADDRESS");
        require(amount > 0, "MINT_O_TOKENS");
        uint256 currentTotalSupply = _totalSupply;
        uint256 newTotalSupply = currentTotalSupply + amount;
        require(newTotalSupply > currentTotalSupply, "OVERFLOW");
        _totalSupply = newTotalSupply;
        _balances[to] += amount;
        emit Transfer(address(0), to, amount);
    }

    /// @dev Burn tokens from an address.
    /// @param from The address whose tokens to burn.
    /// @param amount The number of token to burn.
    function _burn(address from, uint256 amount) internal {
        require(amount > 0, "BURN_O_TOKENS");
        if (_msgSender() != from && !_superOperators[_msgSender()] && _msgSender() != _operator) {
            uint256 currentAllowance = _allowances[from][_msgSender()];
            if (currentAllowance != ~uint256(0)) {
                // save gas when allowance is maximal by not reducing it (see https://github.com/ethereum/EIPs/issues/717)
                require(currentAllowance >= amount, "INSUFFICIENT_ALLOWANCE");
                _allowances[from][_msgSender()] = currentAllowance - amount;
            }
        }

        uint256 currentBalance = _balances[from];
        require(currentBalance >= amount, "INSUFFICIENT_FUNDS");
        _balances[from] = currentBalance - amount;
        _totalSupply -= amount;
        emit Transfer(from, address(0), amount);
    }
}