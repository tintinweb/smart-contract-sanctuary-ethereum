pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Context.sol";

interface Bearlab {
    function proxyMint(address _address, uint256 _tokenId) external;
}

contract BearLabsProxyMint is Context, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private m_TokenIdCounter;

    event MintByStaked(
        address indexed receiver,
        uint256 indexed numberOfTokens,
        bytes signature
    );

    event MintByWallet(
        address indexed receiver,
        uint256 indexed numberOfTokens
    );

    address private m_MSK = 0x72D7b17bF63322A943d4A2873310a83DcdBc3c8D;
    address private m_BearLab = 0xfC6DfeA7E513Dd4cB554032418B3b9f01cD24274;

    bool private m_IsMintable = false; // false
    uint256 private m_MaxMintPerAddress = 4;
    uint256 private m_MintPrice = 100000 ether; // 100K MSK

    uint256 private m_MintSupply = 101;
    uint256 private m_BaseCounter = 3333;

    address private m_Verify1 = 0x27798F382f4eE811B12f79e5E3035fb5134b3Dbf;
    address private m_Verify2 = 0x7f5467Fd11F4C7C7F143b03883Cda5432545dC13;
    uint256 private m_SignatureLifeTime = 1 minutes * 5;

    mapping(address => uint256) private m_MintCountList;

    constructor() {}

    function _mintDrop(address _address) private {
        m_TokenIdCounter.increment();
        uint256 tokenId = m_BaseCounter.add(m_TokenIdCounter.current());

        require(tokenId <= m_BaseCounter.add(m_MintSupply));

        Bearlab(m_BearLab).proxyMint(_address, tokenId);
        m_MintCountList[_address] = m_MintCountList[_address].add(1);
    }

    function _safeMintMultiple(address _address, uint256 _numberOfTokens)
        private
    {
        while (_numberOfTokens > 0) {
            _mintDrop(_address);
            _numberOfTokens = _numberOfTokens.sub(1);
        }
    }

    function mintByWallet(uint256 _numberOfTokens) public {
        require(m_IsMintable, "must be active");

        require(_numberOfTokens > 0);

        uint256 afterMintBalace = m_MintCountList[_msgSender()].add(
            _numberOfTokens
        );

        require(
            afterMintBalace <= m_MaxMintPerAddress,
            "Over Max Mint per Address"
        );

        IERC20 msk = IERC20(m_MSK);
        uint256 requireAmount = m_MintPrice.mul(_numberOfTokens);

        require(
            msk.balanceOf(_msgSender()) >= requireAmount,
            "Msk balance is not enough"
        );

        msk.transferFrom(_msgSender(), address(this), requireAmount);

        _safeMintMultiple(_msgSender(), _numberOfTokens);

        emit MintByWallet(_msgSender(), _numberOfTokens);
    }

    function mintByStaked(
        uint256 _numberOfTokens,
        uint256 _time,
        bytes memory signature1,
        bytes memory signature2
    ) external {
        require(m_IsMintable, "must be active");

        require(_numberOfTokens > 0);

        uint256 afterMintBalace = m_MintCountList[_msgSender()].add(
            _numberOfTokens
        );

        require(
            afterMintBalace <= m_MaxMintPerAddress,
            "Over Max Mint per Address"
        );

        bytes32 messageHash = getMessageHash(
            _msgSender(),
            _numberOfTokens,
            _time,
            m_MintCountList[_msgSender()]
        );

        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        require(
            recoverSigner(ethSignedMessageHash, signature1) == m_Verify1,
            "Different signer1"
        );

        require(
            recoverSigner(ethSignedMessageHash, signature2) == m_Verify2,
            "Different signer2"
        );

        require(block.timestamp - _time < m_SignatureLifeTime);

        _safeMintMultiple(_msgSender(), _numberOfTokens);

        emit MintByStaked(_msgSender(), _numberOfTokens, signature1);
    }

    function getMintCount(address _address) external view returns (uint256) {
        return m_MintCountList[_address];
    }

    ///////////////////////////////////////////////////////////////////

    function resetTokenIdCounter() external onlyOwner {
        m_TokenIdCounter.reset();
    }

    function getCurrentSupply() external view returns (uint256) {
        return m_BaseCounter.add(m_TokenIdCounter.current());
    }

    function setMintEnabled(bool _enabled) external onlyOwner {
        m_IsMintable = _enabled;
    }

    function getMintEnabled() external view returns (bool) {
        return m_IsMintable;
    }

    function setMaxMintPerAddress(uint256 _maxMintPerAddress)
        external
        onlyOwner
    {
        m_MaxMintPerAddress = _maxMintPerAddress;
    }

    function getMaxMintPerAddress() external view returns (uint256) {
        return m_MaxMintPerAddress;
    }

    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        m_MintPrice = _mintPrice * (10**18);
    }

    function getMintPrice() external view returns (uint256) {
        return m_MintPrice.div(10**18);
    }

    function setBaseCounter(uint256 _baseCounter) external onlyOwner {
        m_BaseCounter = _baseCounter;
    }

    function getBaseCounter() external view returns (uint256) {
        return m_BaseCounter;
    }

    function setMintSupply(uint256 _mintSupply) external onlyOwner {
        m_MintSupply = _mintSupply;
    }

    function getMintSupply() external view returns (uint256) {
        return m_MintSupply;
    }

    function getDropSupply() external view returns (uint256) {
        return m_MintSupply.add(m_BaseCounter);
    }

    function setSignatureLifeTime(uint256 _signatureLifeTime)
        external
        onlyOwner
    {
        m_SignatureLifeTime = _signatureLifeTime;
    }

    function getSignatureLifeTime() external view returns (uint256) {
        return m_SignatureLifeTime;
    }

    // ######## SIGN #########

    function getMessageHash(
        address _address,
        uint256 _amount,
        uint256 _time,
        uint256 _counter
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_address, _amount, _time, _counter));
    }

    function splitSignature(bytes memory sig)
        public
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }

    function getEthSignedMessageHash(bytes32 _messageHash)
        public
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    _messageHash
                )
            );
    }

    function recoverSigner(
        bytes32 _ethSignedMessageHash,
        bytes memory _signature
    ) public pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    // ######## MSK & BANK & VERIFY #########

    function setMskContract(address _address) external onlyOwner {
        m_MSK = _address;
    }

    function getMskContract() external view returns (address) {
        return m_MSK;
    }

    function setBearlabContract(address _address) external onlyOwner {
        m_BearLab = _address;
    }

    function getBearlabContract() external view returns (address) {
        return m_BearLab;
    }

    function setVerifyAddress1(address _address) external onlyOwner {
        m_Verify1 = _address;
    }

    function getVerfiyAddress1() external view returns (address) {
        return m_Verify1;
    }

    function setVerifyAddress2(address _address) external onlyOwner {
        m_Verify2 = _address;
    }

    function getVerfiyAddress2() external view returns (address) {
        return m_Verify2;
    }

    ////////////////////////////////////////////////////////////////
    function withdrawMsk() external onlyOwner {
        IERC20(m_MSK).transfer(owner(), IERC20(m_MSK).balanceOf(address(this)));
    }
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

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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