// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import { MapPurchase, Utilities } from "./Libs.sol";
import { BaseControl } from "./BaseControl.sol";
import { ERC20Burnable, ERC20, IERC20 } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract MIFE is BaseControl, ERC20Burnable {
  using MapPurchase for MapPurchase.Purchase;
  using MapPurchase for MapPurchase.Record;

  struct Initial {
    address account;
    uint256 amount;
  }

  // constants
  // variables
  uint256 public quantityReleased;
  MapPurchase.Record purchases;


  constructor() ERC20("The Metalife", "MIFE") {
    uint256 maxSupply = 3000000000 * (10 ** decimals());

    uint256 list_a = 300000000 * (10 ** decimals());
    _mint(0x12E36b7D140f8083d2da50F977F5ca8C415193EF, list_a);
    _mint(0x99AD6259C66d32144bCc226b45472C6Def82397B, list_a);

    uint256 list_b = 60000000 * (10 ** decimals());
    _mint(0x3411118a35A1F20e5b45324a50bA24990c667928, list_b);
    _mint(0x9114DE606aAEba34E0AdEABcBdE7F6Aa212A7ee0, list_b);
    _mint(0xFed7EC360e5200F725109fA68917b33Face2B99e, list_b);
    _mint(0xdE906C27793eF5521A3c8F2732dE71Bfd2c14aA9, list_b);
    _mint(0x34abb70836476B9E93Aa516188b0667936b9e36F, list_b);

    // 2100000000
    _mint(0x5B7D2199d748f3fdfB744e7756290b29d4c83FD3, maxSupply - list_a * 2 - list_b * 5);
  }

  /** Public */
  function privateSale(bytes memory _signature) external payable {
    uint16 rate = 12000;
    require(tx.origin == msg.sender, "Not allowed");
    require(privateSaleActive, "Not active");
    require(!purchases.containsValue(msg.sender), "Already purchased");
    require(msg.value >= 2 ether && msg.value <= 20 ether, "Ether value incorrect");
    // check supply
    (uint256 tokenAmount, uint256 bonusAmount, ) = Utilities.computeReward(msg.value, rate, decimals(), Utilities.getPrivateBonus);
    require(quantityReleased + tokenAmount + bonusAmount <= 150000000 * (10 ** decimals()), "Exceed supply");
    // check whitelist
    require(eligibleByWhitelist(msg.sender, msg.value, _signature), "Not eligible");

    purchases.addValue(msg.sender, msg.value, rate, decimals(), Utilities.getPrivateBonus);
    quantityReleased += (tokenAmount + bonusAmount);
  }

  function publicSale() external payable {
    uint16 rate = 10000;
    require(tx.origin == msg.sender, "Not allowed");
    require(publicSaleActive, "Not active");
    require(!purchases.containsValue(msg.sender), "Already purchased");
    require(msg.value >= 0.5 ether && msg.value <= 8 ether, "Ether value incorrect");
    // check supply
    (uint256 tokenAmount, uint256 bonusAmount, ) = Utilities.computeReward(msg.value, rate, decimals(), Utilities.getPublicBonus);
    require(quantityReleased + tokenAmount + bonusAmount <= 450000000 * (10 ** decimals()), "Exceed supply");

    purchases.addValue(msg.sender, msg.value, rate, decimals(), Utilities.getPublicBonus);
    quantityReleased += (tokenAmount + bonusAmount);
  }

  /** Admin */
  function issueBonus(uint256 _start, uint256 _end) external onlyOwner {
    uint256 maxSize = getPurchasersSize();
    _end = _end > maxSize ? maxSize : _end;

    for (uint256 i = _start; i < _end; i++) {
      MapPurchase.Purchase storage record = purchases.values[i];
      if (record.tokenAmount == 0 && record.bonusAmount > 0) {
        IERC20(address(this)).transfer(record.account, record.bonusAmount);
        record.bonusAmount = 0;
      }
    }
  }

  function issueTokens(uint256 _start, uint256 _end, uint8 _issueTh) external onlyOwner {
    require(_issueTh >= 1, "Incorrect Input");

    uint256 maxSize = getPurchasersSize();
    _end = _end > maxSize ? maxSize : _end;

    for (uint256 i = _start; i < _end; i++) {
      MapPurchase.Purchase storage record = purchases.values[i];
      if (record.divisor + _issueTh > 12) {
        uint256 amount = record.tokenAmount / record.divisor;
        record.tokenAmount -= amount;

        if (record.divisor > 1) {
          record.divisor -= 1;
        }
        IERC20(address(this)).transfer(record.account, amount);
      }
    }
  }

  function withdraw() external onlyOwner {
    uint256 balance = address(this).balance;
    uint256 balanceA = balance * 85 / 100;

    uint256 balanceB = balance - balanceA;
    payable(0x95a881D2636a279B0F51a2849844b999E0E52fa8).transfer(balanceA);
    payable(0x0dF5121b523aaB2b238f5f03094f831348e6b5C3).transfer(balanceB);
  }

  function withdrawMIFE() external onlyOwner {
    uint256 balance = IERC20(address(this)).balanceOf(address(this));
    IERC20(address(this)).transfer(msg.sender, balance);
  }

  /** View */
  function eligibleByWhitelist(address _account, uint256 _stakeValue, bytes memory _signature) public view returns (bool) {
    bytes32 message = keccak256(abi.encodePacked(hashKey, 'normal', _account));
    if (_stakeValue >= 19 ether) {
      message = keccak256(abi.encodePacked(hashKey, 'special', _account));
    }
    return validSignature(message, _signature);
  }

  function getPurchasersSize() public view returns (uint256) {
    return purchases.values.length;
  }

  function getPurchaserAt(uint256 _index) public view returns (MapPurchase.Purchase memory) {
    return purchases.values[_index];
  }

  function getPurchasers(uint256 _start, uint256 _end) public view returns (MapPurchase.Purchase[] memory) {
    uint256 maxSize = getPurchasersSize();
    _end = _end > maxSize ? maxSize : _end;

    MapPurchase.Purchase[] memory records = new MapPurchase.Purchase[](_end - _start);
    for (uint256 i = _start; i < _end; i++) {
      records[i - _start] = purchases.values[i];
    }
    return records;
  }

  function getPersonaAllocated(address _account) public view returns (uint8) {
    MapPurchase.Purchase memory purchase = purchases.getValue(_account);
    return purchase.personaAmount;
  }

  function getPurchasedByAccount(address _account) public view returns (MapPurchase.Purchase memory) {
    return purchases.getValue(_account);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library MapPurchase {
  struct Purchase {
    uint8 divisor;
    uint8 personaAmount;
    uint256 tokenAmount;
    uint256 bonusAmount;
    address account;
    uint256 purchasedAmount;
  }

  struct Record {
    Purchase[] values;
    mapping(address => uint256) indexes; // value to index
  }

  function addValue(
    Record storage _record,
    address _purchaser,
    uint256 _purchased,
    uint16 _unit,
    uint8 _decimals,
    function(uint256, uint16) internal pure returns (uint16, uint8) getRate
  ) internal {
    if (containsValue(_record, _purchaser)) return; // exist
    (uint256 tokenAmount, uint256 bonusAmount, uint8 personaAmount) = Utilities.computeReward(_purchased, _unit, _decimals, getRate);
    Purchase memory _value = Purchase({ divisor: 12, personaAmount: personaAmount, tokenAmount: tokenAmount, bonusAmount: bonusAmount, account: _purchaser, purchasedAmount: _purchased });
    _record.values.push(_value);
    _record.indexes[_purchaser] = _record.values.length;
  }

  function removeValue(Record storage _record, Purchase memory _value) internal {
    uint256 valueIndex = _record.indexes[_value.account];
    if (valueIndex == 0) return;
    uint256 toDeleteIndex = valueIndex - 1;
    uint256 lastIndex = _record.values.length - 1;
    if (lastIndex != toDeleteIndex) {
      Purchase memory lastvalue = _record.values[lastIndex];
      _record.values[toDeleteIndex] = lastvalue;
      _record.indexes[lastvalue.account] = valueIndex;
    }
    _record.values.pop();
    _record.indexes[_value.account] = 0;
  }

  function containsValue(Record storage _record, address _account) internal view returns (bool) {
    return _record.indexes[_account] != 0;
  }

  function getValue(Record storage _record, address _account) internal view returns (Purchase memory) {
    if (!containsValue(_record, _account)) {
      return Purchase({ divisor: 12, personaAmount: 0, tokenAmount: 0, bonusAmount: 0, account: _account, purchasedAmount: 0 });
    }
    uint256 valueIndex = _record.indexes[_account];
    return _record.values[valueIndex - 1];
  }
}

library Utilities {
  function computeReward(
    uint256 purchased,
    uint16 unit,
    uint8 decimals,
    function(uint256, uint16) internal pure returns (uint16, uint8) getRate
  )
    internal
    pure
    returns (
      uint256,
      uint256,
      uint8
    )
  {
    uint256 tokenAmount = uint256((purchased * unit) / 1 ether) * (10 ** decimals);

    (uint16 rate, uint8 persona) = getRate(purchased, unit);
    uint256 bonusAmount = uint256((purchased * rate) / 1 ether) * (10 ** decimals);

    return (tokenAmount, bonusAmount, persona);
  }

  function getPrivateBonus(uint256 purchased, uint16 unit) internal pure returns (uint16, uint8) {
    if (purchased >= 2 ether && purchased < 4 ether) {
      return ((unit / 100) * 10, 10);
    }

    if (purchased >= 4 ether && purchased < 6 ether) {
      return ((unit / 100) * 15, 15);
    }

    if (purchased >= 6 ether && purchased < 9 ether) {
      return ((unit / 100) * 25, 25);
    }

    if (purchased >= 9 ether && purchased < 15 ether) {
      return ((unit / 100) * 30, 35);
    }

    if (purchased >= 15 ether && purchased < 19 ether) {
      return ((unit / 100) * 35, 45);
    }

    if (purchased >= 19 ether) {
      return ((unit / 100) * 50, 88);
    }

    return (0, 0);
  }

  function getPublicBonus(uint256 purchased, uint16 unit) internal pure returns (uint16, uint8) {
    if (purchased >= 0.5 ether && purchased < 1 ether) {
      return ((unit / 100) * 2, 2);
    }

    if (purchased >= 1 ether && purchased < 3 ether) {
      return ((unit / 100) * 5, 5);
    }

    if (purchased >= 3 ether && purchased < 6 ether) {
      return ((unit / 100) * 10, 10);
    }

    if (purchased >= 6 ether) {
      return ((unit / 100) * 15, 15);
    }

    return (0, 0);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

abstract contract BaseControl is Ownable {
  // variables
  bool public privateSaleActive;
  bool public publicSaleActive;
  address public signerAccount = 0x8F9Ab1589581250c9D0BA92d3c865E06C9CCfCe0;
  string public hashKey = "metalife-mife";

  function togglePrivateSale(bool _status) external onlyOwner {
    privateSaleActive = _status;
  }

  function togglePublicSale(bool _status) external onlyOwner {
    publicSaleActive = _status;
  }

  function setSignerInfo(address _signer) external onlyOwner {
    signerAccount = _signer;
  }

  function setHashKey(string calldata _hashKey) external onlyOwner {
    hashKey = _hashKey;
  }

  /** Internal */
  function splitSignature(bytes memory _sig)
    internal
    pure
    returns (
      uint8,
      bytes32,
      bytes32
    )
  {
    require(_sig.length == 65, "Invalid signature length");

    uint8 v;
    bytes32 r;
    bytes32 s;
    assembly {
      r := mload(add(_sig, 32))
      s := mload(add(_sig, 64))
      v := byte(0, mload(add(_sig, 96)))
    }
    return (v, r, s);
  }

  function validSignature(bytes32 _message, bytes memory _signature) internal view returns (bool) {
    bytes32 ethSignedMessageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _message));
    (uint8 v, bytes32 r, bytes32 s) = splitSignature(_signature);
    return ecrecover(ethSignedMessageHash, v, r, s) == signerAccount;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        unchecked {
            _approve(account, _msgSender(), currentAllowance - amount);
        }
        _burn(account, amount);
    }
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}