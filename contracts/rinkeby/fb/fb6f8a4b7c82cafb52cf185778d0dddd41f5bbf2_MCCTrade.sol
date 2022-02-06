/**
 *Submitted for verification at Etherscan.io on 2022-02-06
*/

/**
 *Submitted for verification at BscScan.com on 2022-01-06
 */

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;
    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;
    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(
            _initializing || !_initialized,
            "Initializable: contract is already initialized"
        );

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {}

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    uint256[50] private __gap;
}

library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    uint256[49] private __gap;
}
interface IERC20Upgradeable {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}


interface OpenSale721 {
    function setServiceValue(uint256 _serviceValue, uint256 sellerfee) external;

    function addTokenType(string[] memory _type, address[] memory tokenAddress)
        external;
}

interface OpenSale1155 {
    function setServiceValue(uint256 _serviceValue, uint256 sellerfee) external;

    function addTokenType(string[] memory _type, address[] memory tokenAddress)
        external;
}

contract MCCTrade is Initializable, OwnableUpgradeable {
    event SetPack(string indexed packName, uint256 indexed pPrice);
    using SafeMathUpgradeable for uint256;

    function initialize() public initializer {
        __Ownable_init();
        serviceValue = 2500000000000000000;
        sellervalue = 0;
        tokenhold = 50000000000000000000;
        mccTokenAddress = 0x626fECC2B41297a24ad3bcCA79ABbBb3795aE155;
    }

    struct packInfo {
        string packName;
        uint256 packPrice; 
        uint256 multiples;
    }
    mapping(string => address) private tokentype;
    mapping(address => uint256) public aPack;
    uint256 private serviceValue;
    uint256 private sellervalue;
    packInfo[] public _pName;
    premiumpackInfo[] public _premiumpName;
    mapping(address => uint256) public aPremiumPack;
    uint256 private tokenhold;
    struct premiumpackInfo {
        string packName;
        uint256 packPrice;
        uint256 multiples;
    }
    address public mccTokenAddress;

    function getServiceFee() public view returns (uint256, uint256) {
        return (serviceValue, sellervalue);
    }

    function setServiceValue(
        uint256 _serviceValue,
        uint256 sellerfee,
        address[] memory _conAddress
    ) public onlyOwner {
        serviceValue = _serviceValue;
        sellervalue = sellerfee;
        OpenSale721(_conAddress[0]).setServiceValue(_serviceValue, sellerfee);
        OpenSale1155(_conAddress[1]).setServiceValue(_serviceValue, sellerfee);
    }

    function getTokenAddress(string memory _type)
        public
        view
        returns (address)
    {
        return tokentype[_type];
    }

    function addTokenType(
        string[] memory _type,
        address[] memory tokenAddress,
        address[] memory _conAddress
    ) public onlyOwner {
        require(
            _type.length == tokenAddress.length,
            "Not equal for type and tokenAddress"
        );
        for (uint256 i = 0; i < _type.length; i++) {
            tokentype[_type[i]] = tokenAddress[i];
        }
        OpenSale721(_conAddress[0]).addTokenType(_type, tokenAddress);
        OpenSale1155(_conAddress[0]).addTokenType(_type, tokenAddress);
    }

    function addNewPreminumPack(string memory _pname, uint256 _pfee, uint _multiples)
        public
        onlyOwner
    {
        premiumpackInfo memory _premiumpackInfo;
        _premiumpackInfo.packName = _pname;
        _premiumpackInfo.packPrice = _pfee;
        _premiumpackInfo.multiples = _multiples;
        _premiumpName.push(_premiumpackInfo);
        emit SetPack(
            _premiumpName[_premiumpName.length - 1].packName,
            _premiumpName[_premiumpName.length - 1].packPrice
        );
    }

    function addNewPack(string memory _pname, uint256 _pfee, uint _multiples) public onlyOwner {
        packInfo memory _packInfo;
        _packInfo.packName = _pname;
        _packInfo.packPrice = _pfee;
        _packInfo.multiples = _multiples;
        _pName.push(_packInfo);
        emit SetPack(
            _pName[_pName.length - 1].packName,
            _pName[_pName.length - 1].packPrice
        );
    }

    function getPacks()
        public
        view
        returns (packInfo[] memory, premiumpackInfo[] memory)
    {
        return (_pName, _premiumpName);
    }

    function editPremiumPackFee(
        string memory _pname,
        uint256 _pfee,
        uint256 _pid,
        uint _multiples
        
    ) public onlyOwner {
        _premiumpName[_pid].packName = _pname;
        _premiumpName[_pid].packPrice = _pfee;
        _premiumpName[_pid].multiples = _multiples;
        emit SetPack(_premiumpName[_pid].packName, _premiumpName[_pid].packPrice);
    }

    function editPackFee(
        string memory _pname,
        uint256 _pfee,
        uint256 _pid,
        uint _multiples
    ) public onlyOwner {
        _pName[_pid].packName = _pname;
        _pName[_pid].packPrice = _pfee;
        _pName[_pid].multiples = _multiples;
        emit SetPack(_pName[_pid].packName, _pName[_pid].packPrice);
    }

    function buyPack(
        uint256 _pid,
        uint256 _nPack,
        string memory _type
    ) public payable {
        if (
            keccak256(abi.encodePacked((_type))) ==
            keccak256(abi.encodePacked(("Premium")))
        ) {
            require(IERC20Upgradeable(mccTokenAddress).balanceOf(msg.sender) >= tokenhold, "Not Eligible to Mint Premium Pack");
            require(
                _premiumpName[_pid].packPrice.mul(_nPack) == msg.value,
                "Invalid Pack Price"
            );
            aPremiumPack[msg.sender] = aPremiumPack[msg.sender].add(_nPack.mul(_premiumpName[_pid].multiples));
            payable(owner()).transfer(msg.value);
        } else {
            require(
                _pName[_pid].packPrice.mul(_nPack) == msg.value,
                "Invalid Pack Price"
            );
            aPack[msg.sender] = aPack[msg.sender].add(_nPack.mul(_pName[_pid].multiples));
            payable(owner()).transfer(msg.value);
        }
    }

    function availablePack(address from) public view returns (uint256, uint256) {
        return (aPack[from],aPremiumPack[from]);
    }
    function getHoldTokenValue() public view returns (uint256) {
        return tokenhold;
    }
    function editHoldTokenValue(uint256 value) public onlyOwner {
        tokenhold = value;   
    }

    function decreasePack(address from,string memory _type) external {
         if (
            keccak256(abi.encodePacked((_type))) ==
            keccak256(abi.encodePacked(("Premium")))
        ){
            aPremiumPack[from] = aPremiumPack[from].sub(1);
        }
        else{
            aPack[from] = aPack[from].sub(1);
        }
    }
}