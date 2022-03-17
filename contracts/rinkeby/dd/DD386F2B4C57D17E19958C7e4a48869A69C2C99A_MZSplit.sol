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

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
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

import "@openzeppelin/contracts/utils/Context.sol";

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
abstract contract Admin is Context {
    address private _owner;
    address private _moderator;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    event ModerationTransferred(address indexed previousModerator, address indexed newModerator);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
        _setModerator(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Returns the address of the current moderator.
     */
    function moderator() public view virtual returns (address) {
        return _moderator;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Admin: caller is not the owner");
        _;
    }

    /**
     * @dev Throws if called by any account other than the owner or moderator.
     */
    modifier onlyAdmins() {
        require(owner() == _msgSender() || moderator() == _msgSender(), "Admin: caller is not an admin");
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
        require(newOwner != address(0), "Admin: new owner is the zero address");
        _setOwner(newOwner);
    }

    /**
     * @dev Transfers moderation control of the contract to a new account
     * (`newModerator`). Can only be called by the current owner.
     */
    function transferModeration(address newModerator) public virtual onlyOwner {
        require(newModerator != address(0), "Admin: new moderator is the zero address");
        _setModerator(newModerator);
    }

    function _setOwner(address newOwner) internal {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function _setModerator(address newModerator) internal {
        address oldModerator = _moderator;
        _moderator = newModerator;
        emit ModerationTransferred(oldModerator, newModerator);
    }
}

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

import "./Admin.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract MZSplit is Admin {

    using SafeMath for uint256;

    /**
     * @dev Structure to hold ERC20 Tokens core info.
     *
     * @param symbol      String token symbol Example: ETH
     * @param deployed    Contract address
     */
    struct ERC20Token {
        string symbol;
        address deployed;
    }

    // List of supported tokens
    mapping(string => ERC20Token) public _supportedTokens;

    /**
     * @dev Structure to hold a split portion.
     *
     * @param cut           Number percent from 0 to 100
     * @param markToken     MetaMark token_id receiver of portion of funds
     * @param balance       Remaining funds per supported ERC20 token
     */
    struct Split {
        uint8 cut;
        uint256 markToken;
        mapping(string => uint256) balance;
    }

    // Array of split percentages
    mapping (uint8 => Split) public _splits;
    // How many split percentages
    uint8 public _splitCount = 0;
    // Split cuts added up
    uint8 public _sumCuts = 0;

    // Affiliate maximum cut
    uint8 public _affiliateCutMax = 10;

    // Logging variable for last amount transacted
    uint256 public _lastAmount = 0;

    // MetaMark contract address
    address private _metaMarkDeployed;

    // Event for balance increased
    event Purchase(address indexed from, string tokenSymbol, uint256 value, string sku);
    // Event for balance increased
    event Deposit(address indexed from, string tokenSymbol, uint256 value);
    // Event for withdraw made
    event Withdraw(address indexed to, string tokenSymbol, uint256 value);

    /**
     * @dev Initializes the amount of recipients involved, each recipient percentage, and the recipient addresses.
     *
     * @param metaMarkDeployed_     Address of MetaMark contract
     * @param count                Amount of recipients
     * @param cuts                 List of percentages for each recipient
     * @param markTokens           Recipient MetaMark token id
     */
    constructor(
        address moderator,
        address metaMarkDeployed_,
        uint8 count,
        uint8[] memory cuts,
        uint256[] memory markTokens
    )
    payable {
        // Count must be size of cuts and recipients
        require(count == cuts.length && count == markTokens.length, "Lengths do not match");

        // Sender is the owner
        _setOwner(tx.origin);
        // Allow creator to specify a moderator
        _setModerator(moderator);

        // Save MetaMark contract address
        _metaMarkDeployed = metaMarkDeployed_;

        // Save splits
        _splitCount = count;
        for(uint8 i=0; i<_splitCount; i++) {
            // Add new split
            Split storage s = _splits[i];
            s.cut = cuts[i];
            s.markToken = markTokens[i];

            // Sum of all cuts
            _sumCuts += cuts[i];

            // Add default eth token and zero balance
            _splits[i].balance["ETH"] = 0;
        }

        require(_sumCuts == 100, "Sum of cuts do not equal 100%");

        // Divide up initial payable amount
        if(msg.value > 0) {
            _splitAmount("ETH", msg.value);
        }
    }


    function getMetaMark() public view returns (address) {
        return _metaMarkDeployed;
    }
    function setMetaMark(address metaMarkDeployed_) public onlyAdmins {
        require(metaMarkDeployed_ != address(0), "Must provide MZMark address");
        _metaMarkDeployed = metaMarkDeployed_;
    }


    function getTokenAddress(string memory tokenSymbol) public view returns (address) {
      return _supportedTokens[tokenSymbol].deployed;
    }
    function supportToken(string memory tokenSymbol, address tokenDeployed) public onlyAdmins {
        require(keccak256(bytes(tokenSymbol)) != keccak256(bytes("ETH")), "ETH Token already supported");

        // Add new supported token with contract address
        _supportedTokens[tokenSymbol] = ERC20Token({
            symbol: tokenSymbol,
            deployed: tokenDeployed
        });
        // Initialize each recipient balance to zero
        for(uint8 i=0; i<_splitCount; i++) {
            // Add default erc20 token balance
            _splits[i].balance[tokenSymbol] = 0;
        }
    }


    receive () external payable {
        _splitAmount("ETH", msg.value);
    }
    fallback () external payable {
        _splitAmount("ETH", msg.value);
    }
    function deposit() public payable {
        _splitAmount("ETH", msg.value);
    }

    function depositERC20(string memory tokenSymbol, uint256 value, string memory sku) public {
        require(_supportedTokens[tokenSymbol].deployed != address(0), "Token not supported");
        require(value > 0, "No amount provided");

        // Retrieve token contract
        IERC20 erc20 = IERC20(_supportedTokens[tokenSymbol].deployed);

        require(erc20.allowance(msg.sender, address(this)) >= value, "Not enough spending power");

        // Send ERC20 payout to contract
        erc20.transferFrom(msg.sender, address(this), value);

        // Fire purchase event
        emit Purchase(tx.origin, tokenSymbol, value, sku);

        // Split the ERC20 payout
        _splitAmount(tokenSymbol, value);
    }

    function splitAmount(string memory tokenSymbol, uint256 value) public onlyAdmins {
      // Split the ERC20 payout
      _splitAmount(tokenSymbol, value);
    }
    function _splitAmount(string memory tokenSymbol, uint256 value) internal {
        require(keccak256(bytes(tokenSymbol)) == keccak256(bytes("ETH")) || _supportedTokens[tokenSymbol].deployed != address(0), "Token not supported");
        require(value > 0, "Must provide value amount");

        // Log for debugging
        _lastAmount = value;

        // Track used up value of cuts
        uint256 valueUsed = 0;
        // Loop through all cuts
        for(uint8 i=0; i<_splitCount; i++) {
            // Calculate recipient portion: value * (cut / 100)
            uint256 valueCut = value.mul(_splits[i].cut).div(_sumCuts);
            // Increment recipient balance
            _splits[i].balance[tokenSymbol] += valueCut;
            // Track used up value
            valueUsed += valueCut;
        }

        // Add any remaining unused value to first balance
        _splits[0].balance[tokenSymbol] += value - valueUsed;

        // Fire deposit event
        emit Deposit(tx.origin, tokenSymbol, value);

        // Send balances payouts
        withdrawBalances(tokenSymbol);
    }

    function withdrawBalances(string memory tokenSymbol) public {
        // Check is ETH
        bool isETH = keccak256(bytes(tokenSymbol)) == keccak256(bytes("ETH"));
        require(isETH || _supportedTokens[tokenSymbol].deployed != address(0), "Token not supported");

        // Retrieve MetaMark contract
        IERC721 erc721 = IERC721(_metaMarkDeployed);

        // Retrieve token contract
        IERC20 erc20;
        if(!isETH) {
            erc20 = IERC20(_supportedTokens[tokenSymbol].deployed);
        }

        // Loop through all recipients
        for(uint8 i=0; i<_splitCount; i++) {
            // Make sure has a balance
            if(_splits[i].balance[tokenSymbol] > 0) {
                // Retrieve recipient address
                address payable recipient = payable(erc721.ownerOf(_splits[i].markToken));

                // ETH
                if(isETH) {
                    // Send payout recipient
                    recipient.transfer(_splits[i].balance[tokenSymbol]);
                }
                // ERC20Token
                else {
                    // Send erc20 payout to recipient
                    erc20.transfer(recipient, _splits[i].balance[tokenSymbol]);
                }

                // Fire withdraw event
                emit Withdraw(recipient, tokenSymbol, _splits[i].balance[tokenSymbol]);
                // Clear balance
                _splits[i].balance[tokenSymbol] = 0;
            }
        }
    }

    function depositWithAffiliate(string memory tokenSymbol, address payable affiliate, uint256 affilateCut) public payable {
        require(affiliate != address(0), "Affilate address not provided");
        // Check is ETH
        bool isETH = keccak256(bytes(tokenSymbol)) == keccak256(bytes("ETH"));
        require(isETH || _supportedTokens[tokenSymbol].deployed != address(0), "Token not supported");
        require(msg.value > 0, "No amount provided");
        require(affilateCut <= _affiliateCutMax, "Invalid affiliate cut");

        // Log for debugging
        _lastAmount = msg.value;

        // Track used up value of cuts
        uint256 valueUsed = 0;
        // Loop through all cuts
        for(uint8 i=0; i<_splitCount; i++) {
            // Calculate recipient portion minus affiliate portion: value * ((cut - affiliateCut / splitCount) / 100)
            uint256 valueCut = msg.value.mul(uint256(_splits[i].cut).sub(affilateCut.div(_splitCount)).div(_sumCuts));
            // Increment recipient balance
            _splits[i].balance[tokenSymbol] += valueCut;
            // Track used up value
            valueUsed += valueCut;
        }

        // Add any remaining unused value to affiliate balance
        uint256 affiliateBalance = msg.value - valueUsed;

        // Retrieve MetaMark contract
        IERC721 erc721 = IERC721(_metaMarkDeployed);

        // Retrieve token contract
        IERC20 erc20 = IERC20(_supportedTokens[tokenSymbol].deployed);

        // Loop through all cuts
        for(uint8 i=0; i<_splitCount; i++) {
            // Check has any balance
            if(_splits[i].balance[tokenSymbol] > 0) {
                // Retrieve recipient address
                address payable recipient = payable(erc721.ownerOf(_splits[i].markToken));

                // ETH
                if(isETH) {
                    // Send eth payout to recipient
                    (recipient).transfer(_splits[i].balance[tokenSymbol]);
                }
                // ERC20Token
                else {
                    // Send erc20 payout to recipient
                    erc20.transfer(recipient, _splits[i].balance[tokenSymbol]);
                }

                // Clear balance
                _splits[i].balance[tokenSymbol] = 0;
            }
        }

        // ETH
        if(isETH) {
            // Payout affiliate
            (affiliate).transfer(affiliateBalance);
        }
        // ERC20Token
        else {
            // Send erc20 payout to affiliate
            IERC20(_supportedTokens[tokenSymbol].deployed).transfer(affiliate, affiliateBalance);
        }
    }

    function drainFunds(string memory tokenSymbol, address payable target) public onlyAdmins {
        bool isETH = keccak256(bytes(tokenSymbol)) == keccak256(bytes("ETH"));
        require(isETH || _supportedTokens[tokenSymbol].deployed != address(0), "Token not supported");

        // ETH
        if(isETH) {
            // Drain ETH funds to target address
            (target).transfer(address(this).balance);
        }
        // ERC20Token
        else {
            // Retrieve token contract
            IERC20 erc20 = IERC20(_supportedTokens[tokenSymbol].deployed);
            // Drain erc20 funds to target address
            erc20.transfer(target, erc20.balanceOf(address(this)));
        }

        // Loop through all recipients
        for(uint8 i=0; i<_splitCount; i++) {
            // Clear balance
            _splits[i].balance[tokenSymbol] = 0;
        }
    }

    function setCut(uint8 index, uint8 newCut) public onlyAdmins {
        require(index < _splitCount, "Invalid index");
        require(newCut >= 0, "New cut must be positive");

        // Adjust cut
        _splits[index].cut = newCut;
    }
    function setRecipient(uint8 index, uint256 newMarkToken) public onlyAdmins {
        require(index < _splitCount, "Invalid index");
        require(newMarkToken >= 0, "New token id must be positive");

        // Update MetaMark token id to the new token id
        _splits[index].markToken = newMarkToken;
    }
    /**
     * @dev In case of any errors admins can adjust the balance amounts.
     *
     * @param index            Recipient that will be modified
     * @param tokenSymbol      String token symbol Example: ETH
     * @param newBalance       Amount to replace the balance
     */
    function setBalance(uint8 index, string memory tokenSymbol, uint256 newBalance) public onlyAdmins {
        require(index < _splitCount, "Invalid index");
        bool isETH = keccak256(bytes(tokenSymbol)) == keccak256(bytes("ETH"));
        require(isETH || _supportedTokens[tokenSymbol].deployed != address(0), "Token not supported");
        require(newBalance >= 0, "Invalid amount");

        // Update MetaMark token id to the new id
        _splits[index].balance[tokenSymbol] = newBalance;
    }

    function getCut(uint8 index) public view returns(uint256) {
        return _splits[index].cut;
    }
    function getRecipient(uint8 index) public view returns(address) {
        return address(IERC721(_metaMarkDeployed).ownerOf(_splits[index].markToken));
    }
    function getBalance(uint8 index, string memory tokenSymbol) public view returns(uint256) {
        return _splits[index].balance[tokenSymbol];
    }
    function getContractBalance() public view returns(uint256) {
        return address(this).balance;
    }
}