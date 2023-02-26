// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

import "./VAT.sol";
import "./eInvoice.sol";
import "./TaxAuthority.sol";
import "./SellerInterface.sol";

contract Sale {
    //Initialize eInvoice and TaxAuthority
    VAT vat;
    SellerInterface sellerContract;
    address sellerAddress;
    address owner;
    uint256 taxRate;
    address VATTokenContract;
    TaxAuthority taxAuthority;
    mapping(string => Item) items;
    struct Item {
        uint256 pricePerUnit;
        uint256 quantity;
    }

    struct Invoice {
        address seller;
        address buyer;
        string item;
        uint256 qty;
        uint256 totalPrice;
        VAT.State state;
        uint256 netVatAmount;
        uint256 vatToken;
        bool paid;
    }
    Invoice invoicesNew;
    address[] invoiceArray;
    eInvoice.Invoice invoice;
    address public eInvoiceAddress;
    mapping(address => Invoice[]) public invoiceDetails;
    mapping(address => Invoice[]) buyerToInvoices;

    constructor(
        address _Seller,
        address _TaxAuthority,
        address _VATTokenContract
    ) {
        //Initialize values for TaxAuthority and eInvoice
        //Initialize Store Items
        taxRate = 0;
        owner = msg.sender;
        VATTokenContract = _VATTokenContract;
        vat = VAT(_VATTokenContract);

        sellerAddress = _Seller;
        sellerContract = SellerInterface(_Seller);

        taxAuthority = TaxAuthority(_TaxAuthority);

        items["Book"] = Item(100 wei, 100);
        items["Magazine"] = Item(500 wei, 50);
        items["Newspaper"] = Item(200 wei, 200);
    }

    /*
     *Registration in Tax Authority
     */

    function register(string memory _organisationCategory) public payable {
        require(
            sellerContract.isBoardMember(msg.sender),
            "Unauthorised Access"
        );
        taxRate = taxAuthority.register{value: msg.value}(
            _organisationCategory,
            sellerAddress
        );
    }

    function getTotalPrice(string memory _item, uint256 qty)
        public
        view
        returns (uint256)
    {
        return (items[_item].pricePerUnit * qty * (100 + taxRate)) / 100;
    }

    function purchase(
        string memory _item,
        uint256 _qty,
        uint256 _totalPrice,
        VAT.State _state,
        uint256 _vatToken
    ) public payable {
        require(
            taxAuthority.isAddressRegistered(sellerAddress),
            "Organisation not Registered with Tax Authority"
        );
        require(msg.value == _totalPrice - _vatToken, "Total Amount Mismatch");
        require(items[_item].quantity > _qty, "Out of Stock");
        require(
            vat.balanceOf(msg.sender) >= _vatToken,
            "Insufficient Token Balance"
        );
        uint256 vatAmount = (items[_item].pricePerUnit * _qty * taxRate) / 100;
        eInvoice eInvoiceContract = new eInvoice(
            sellerAddress,
            VATTokenContract
        );
        eInvoiceAddress = address(eInvoiceContract);
        vat.transferFrom(msg.sender, eInvoiceAddress, _vatToken);
        invoice = eInvoiceContract.purchase(
            msg.sender,
            _item,
            _qty,
            _totalPrice,
            _state,
            vatAmount,
            _vatToken
        );
        uint256 additionalAmount = vatAmount - _vatToken;
        eInvoiceContract.getAmount{value: additionalAmount}();
        Invoice memory inv = convert(invoice);
        buyerToInvoices[msg.sender].push(inv);
        invoiceDetails[eInvoiceAddress].push(inv);
        invoiceArray.push(eInvoiceAddress);
        items[_item].quantity -= _qty;
        sellerContract.deposit{value: _totalPrice - vatAmount}();
    }

    function convert(eInvoice.Invoice memory _invoice)
        private
        pure
        returns (Invoice memory)
    {
        Invoice memory newInvoice;
        newInvoice.seller = _invoice.seller;
        newInvoice.buyer = _invoice.buyer;
        newInvoice.item = _invoice.item;
        newInvoice.qty = _invoice.qty;
        newInvoice.totalPrice = _invoice.totalPrice;
        newInvoice.state = _invoice.state;
        newInvoice.netVatAmount = _invoice.netVatAmount;
        newInvoice.vatToken = _invoice.vatToken;
        newInvoice.paid = _invoice.paid;
        return newInvoice;
    }

    function getInvoiceDetails(address _invoice)
        public
        view
        returns (Invoice[] memory)
    {
        return invoiceDetails[_invoice];
    }

    function getDeployedInvoices() public view returns (address[] memory) {
        return invoiceArray;
    }

    function getBuyerInvoices(address _buyer)
        public
        view
        returns (Invoice[] memory)
    {
        return buyerToInvoices[_buyer];
    }

    function restoreItem(string memory _item, uint256 _rstrVal) public {
        require(msg.sender == owner, "Unauthorized Access");
        items[_item].quantity += _rstrVal;
    }

    function getVatTokenBalance(address _address)
        external
        view
        returns (uint256)
    {
        return vat.balanceOf(_address);
    }

    function getItemInfo(string memory itemName)
        public
        view
        returns (
            string memory,
            uint256,
            uint256
        )
    {
        Item memory item = items[itemName];
        return (itemName, item.pricePerUnit, item.quantity);
    }

    function getItemInfoAll()
        public
        view
        returns (
            string[] memory,
            uint256[] memory,
            uint256[] memory
        )
    {
        uint256 itemCount = 3;
        string[] memory itemNames = new string[](itemCount);
        uint256[] memory itemPrices = new uint256[](itemCount);
        uint256[] memory itemQuantities = new uint256[](itemCount);

        itemNames[0] = "Book";
        itemPrices[0] = items["Book"].pricePerUnit;
        itemQuantities[0] = items["Book"].quantity;

        itemNames[1] = "Magazine";
        itemPrices[1] = items["Magazine"].pricePerUnit;
        itemQuantities[1] = items["Magazine"].quantity;

        itemNames[2] = "Newspaper";
        itemPrices[2] = items["Newspaper"].pricePerUnit;
        itemQuantities[2] = items["Newspaper"].quantity;

        return (itemNames, itemPrices, itemQuantities);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

interface SellerInterface {
    function isBoardMember(address _address) external view returns (bool);

    function deposit() external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

contract TaxAuthority {
    // Mapping from address to Tax Category and Tax Rate
    struct taxInfo {
        string taxCategory;
        uint256 taxRate;
    }
    taxInfo txinf;
    mapping(address => taxInfo) registeredOrganisations;
    address[] public registeredAddresses;
    string[] availableTaxCategories;
    mapping(string => uint256) public taxClass;

    uint256 public registerFee;

    constructor(uint256 _registerFee) {
        registerFee = _registerFee;
        availableTaxCategories = [
            "Trade",
            "Manufacturing",
            "Construction",
            "AgricultureFishing",
            "Forestry",
            "Mining",
            "Services",
            "SmallBusinesses",
            "CharitableOrganisations",
            "GoodsServices"
        ];
        taxClass["Trade"] = 19;
        taxClass["Manufacturing"] = 19;
        taxClass["Construction"] = 19;
        taxClass["AgricultureFishing"] = 19;
        taxClass["Forestry"] = 19;
        taxClass["Mining"] = 19;
        taxClass["Services"] = 19;
        taxClass["SmallBusinesses"] = 16;
        taxClass["CharitableOrganisations"] = 0;
        taxClass["GoodsServices"] = 7;
    }

    // Function to register a contract
    function register(string memory _category, address _address)
        public
        payable
        returns (uint256)
    {
        require(msg.value == registerFee, "Incorrect fee");
        txinf = taxInfo(_category, taxClass[_category]);
        registeredOrganisations[_address] = txinf;
        registeredAddresses.push(_address);
        return taxClass[_category];
    }

    function getTaxCategories() public view returns (string[] memory) {
        return availableTaxCategories;
    }

    function getTaxRates(string memory _category)
        public
        view
        returns (uint256)
    {
        return taxClass[_category];
    }

    function getRegisteredAddresses() public view returns (address[] memory) {
        return registeredAddresses;
    }

    function getOrganisationTaxDetails(address _address)
        public
        view
        returns (taxInfo memory)
    {
        return registeredOrganisations[_address];
    }

    function isAddressRegistered(address _address) public view returns (bool) {
        for (uint256 i = 0; i < registeredAddresses.length; i++) {
            if (registeredAddresses[i] == _address) {
                return true;
            }
        }
        return false;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

import "./VAT.sol";

contract eInvoice {
    struct Invoice {
        address seller;
        address buyer;
        string item;
        uint256 qty;
        uint256 totalPrice;
        VAT.State state;
        uint256 netVatAmount;
        uint256 vatToken;
        bool paid;
    }

    VAT vat;
    Invoice public invoice;
    address public association;
    uint256 balance;

    event InvoiceCreated(
        address indexed user,
        uint256 invoiceId,
        uint256 totalPrice,
        VAT.State state,
        uint256 vatPrice
    );

    constructor(address _association, address _vatTokenAddress) {
        association = _association;
        vat = VAT(_vatTokenAddress);
    }

    function purchase(
        address _buyer,
        string memory _item,
        uint256 _qty,
        uint256 _totalPrice,
        VAT.State _state,
        uint256 _vatAmount,
        uint256 _vatToken
    ) external payable returns (Invoice memory) {
        uint256 invoiceId = uint256(
            keccak256(abi.encodePacked(block.timestamp, msg.sender))
        );
        uint256 netVatAmount = _vatAmount - _vatToken;
        invoice.seller = msg.sender;
        invoice.buyer = _buyer;
        invoice.item = _item;
        invoice.qty = _qty;
        invoice.totalPrice = _totalPrice;
        invoice.state = _state;
        invoice.netVatAmount = netVatAmount;
        invoice.vatToken = _vatToken;
        invoice.paid = true;
        if (netVatAmount != 0) {
            vat.mint(msg.sender, invoice.netVatAmount);
        }
        emit InvoiceCreated(
            msg.sender,
            invoiceId,
            _totalPrice,
            _state,
            invoice.netVatAmount
        );
        return invoice;
    }

    function getAmount() public payable {
        balance += msg.value;
    }

    function getInvoiceDetails() public view returns (Invoice memory) {
        return invoice;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract VAT is ERC20 {
    constructor() ERC20("VAT Token", "VAT") {}

    enum State {
        EndCustomer,
        Retailer
    }

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

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
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
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
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
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
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
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
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
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
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
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
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
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
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

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
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

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