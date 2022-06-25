// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract UncleLeroyRaffle is Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    Counters.Counter private _raffleIds;
    Counters.Counter private _gameIds;
    Counters.Counter private _subRaffleIds;

    IERC20 UNCC;
    IERC1155 UncleLeroyNFT;
    uint256 public constant PRICE_PER_TICKET = 1500000 * 10**18;
    uint256 private _memberAmt = 10;
    uint256 private _unccLpAmt = 5;
    uint256 private _nftLpAmt = 5;
    uint256 private _celebAmt = 10;
    uint256 private _investorAmt = 10;
    uint256 private _owner1Amt = 30;
    uint256 private _owner2Amt = 30;

    uint256 private constantNumberOfWinners = 25;

    uint256 private numberOfIndependentPlayers;

    uint256 private ticketRestriction = 5;

    address public _memberWallet;
    address public _nftLp;
    address public _unccLp;
    address public _celebWallet;
    address public _investorWallet;
    address public _owner1;
    address public _owner2;

    address[] private lastWinners;
    
    mapping(uint256 => mapping(address => uint256)) private _balances;
    mapping(address => uint256) private _userToLastClaimed;
    
    mapping(uint256 => mapping(uint256 => RaffleItem)) private raffleItems;
    mapping(uint256 => mapping(address => bool)) private isInArray;
    mapping(uint256 => mapping(address => bool)) private AlreadyHas;
    
    struct RaffleItem {
        uint256 raffleId;
        address owner;
    }

    constructor(address _uncc, address _uncleLeroyNFT) {
        UNCC = IERC20(_uncc);
        UncleLeroyNFT = IERC1155(_uncleLeroyNFT);
        _gameIds.increment();
    }

    // get a free raffle once a month if you own commonNFT
    function claimRaffle() external returns(uint256) {
        require(
            UncleLeroyNFT.balanceOf(msg.sender, 3) > 0,
            "Must own common NFT to participate"
        );
        require(
            block.timestamp - _userToLastClaimed[msg.sender] > 30 days,
            "Already claimed this month"
        );
        _raffleIds.increment();
        _subRaffleIds.increment();

        raffleItems[_gameIds.current()][_subRaffleIds.current()] = RaffleItem(
            _raffleIds.current(),
            msg.sender
        );

        _balances[_gameIds.current()][msg.sender] += 1;

        _userToLastClaimed[msg.sender] = block.timestamp;

        if (!AlreadyHas[_gameIds.current()][msg.sender]) {
            numberOfIndependentPlayers++;
            AlreadyHas[_gameIds.current()][msg.sender] = true;
        }

        return _raffleIds.current();
    }

    // returns your owned tickets
    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = _balances[_gameIds.current()][_owner];
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 0;
        uint256 ownedTokenIndex = 0;

        while (
            ownedTokenIndex < ownerTokenCount &&
            currentTokenId <= _raffleIds.current()
        ) {
            address currentTokenOwner = raffleItems[_gameIds.current()][currentTokenId].owner;

            if (currentTokenOwner == _owner) {
                ownedTokenIds[ownedTokenIndex] = raffleItems[_gameIds.current()][currentTokenId].raffleId;

                ownedTokenIndex++;
            }
            currentTokenId++;
        }
        return ownedTokenIds;
    }

    // get the raffle holder knowing raffleId
    function getRaffleOwner(uint256 raffleId) external view onlyOwner returns(address) {
        return raffleItems[_gameIds.current()][raffleId].owner;
    }

    // set a limit on the number of ticket purchases at one tx
    function setPurchaseRestriction(uint ticketAmount) public onlyOwner {
        ticketRestriction = ticketAmount;
    }

    // buy new raffles via uncc if you own commonNFT
    function purchase(uint256 ticketAmount) external {
        require(ticketAmount > 0);
        require(ticketAmount <= ticketRestriction, "You can buy only 5 raffles per transaction");

        require(
            UncleLeroyNFT.balanceOf(msg.sender, 3) > 0,
            "Must own common NFT to participate"
        );
        
        uint256 oldBalance = UNCC.balanceOf(address(this));

        // before transferFrom, you have to increase allowance for this contract address in the uncc
        UNCC.transferFrom(
            msg.sender,
            address(this),
            ticketAmount.mul(PRICE_PER_TICKET)
        );

        uint256 newBalance = UNCC.balanceOf(address(this));

        for (uint256 i = 0; i < ticketAmount; i++) {
            _raffleIds.increment();
            _subRaffleIds.increment();

            raffleItems[_gameIds.current()][_subRaffleIds.current()] = RaffleItem(
                _raffleIds.current(),
                msg.sender
            );
        }

        if (!AlreadyHas[_gameIds.current()][msg.sender]) {
            numberOfIndependentPlayers++;
            AlreadyHas[_gameIds.current()][msg.sender] = true;
        }

        _balances[_gameIds.current()][msg.sender] = _balances[_gameIds.current()][msg.sender].add(ticketAmount);

        _transferShares(newBalance.sub(oldBalance));
    }

    // helper function to generate pseudorandom number
    function random() private view returns(uint){
        return  uint(keccak256(abi.encode(block.timestamp,  _subRaffleIds.current())));
    }

    // get a list of winners
    function pickRaffleWinners() public onlyOwner returns(address[] memory winners){
        
        require(numberOfIndependentPlayers >= constantNumberOfWinners, "Not enough participants to draw");

        winners = getRandomWinners(random(), constantNumberOfWinners, _subRaffleIds.current());
        lastWinners = winners;

        _subRaffleIds.reset();
        _raffleIds.reset();
        _gameIds.increment();
        numberOfIndependentPlayers = 0;

        return winners;
    }

    // helper function to generate list of random numbers
    function getRandomWinners(uint256 randomValue, uint256 n, uint256 range) private returns (address[] memory expandedValues) {
        expandedValues = new address[](n);

        uint256 currentIndex = 1;
        uint256 currentWinners = 0;

        while (
            currentWinners < n
        ) {
            address randomWinnerAddress = raffleItems[_gameIds.current()][
                uint256(keccak256(abi.encode(randomValue, currentIndex))) % range + 1
            ].owner;

            if (!isInArray[_gameIds.current()][randomWinnerAddress]) {
                expandedValues[currentWinners] = randomWinnerAddress;
                currentWinners++;
                isInArray[_gameIds.current()][randomWinnerAddress] = true;
            }
            currentIndex++;
        }
        return expandedValues;
    }

    // get last winners' list
    function getLastWinners() public view returns(address[] memory) {
        return lastWinners;
    }

    // get the unique amount of playing addresses
    function getNumberOfIndependentPlayers() public view onlyOwner returns(uint256) {
        return numberOfIndependentPlayers;
    }

    // transfer uncc to different wallets
    function _transferShares(uint256 amount) private {
        UNCC.transfer(_unccLp, (amount.mul(_unccLpAmt)).div(100));
        UNCC.transfer(_owner1, (amount.mul(_owner1Amt)).div(100));
        UNCC.transfer(_owner2, (amount.mul(_owner2Amt)).div(100));
        UNCC.transfer(_celebWallet, (amount.mul(_celebAmt)).div(100));
        UNCC.transfer(_investorWallet, (amount.mul(_investorAmt)).div(100));
        UNCC.transfer(_memberWallet, (amount.mul(_memberAmt)).div(100));
        UNCC.transfer(_nftLp, (amount.mul(_nftLpAmt)).div(100));
    }

    // getter of the numberOfWinners;
    function getNumberOfWinners() public view onlyOwner returns(uint256) {
        return constantNumberOfWinners;
    }

    // setter of the numberOfWinners
    function setNumberOfWinners(uint256 _numberOfWinners) public onlyOwner {
        constantNumberOfWinners = _numberOfWinners;
    }

    function setMemberWallet(address memberWallet) public onlyOwner {
        _memberWallet = memberWallet;
    }

    function setNftLpWallet(address nftLp) public onlyOwner {
        _nftLp = nftLp;
    }

    function setUnccLpWallet(address unccLp) public onlyOwner {
        _unccLp = unccLp;
    }

    function setCelebrityWallet(address celebWallet) public onlyOwner {
        _celebWallet = celebWallet;
    }

    function setInvestorWallet(address investorWallet) public onlyOwner {
        _investorWallet = investorWallet;
    }

    function setOwner1Wallet(address owner1) public onlyOwner {
        _owner1 = owner1;
    }

    function setOwner2Wallet(address owner2) public onlyOwner {
        _owner2 = owner2;
    }

    function setAllWallets(
        address memberWallet,
        address nftLp,
        address unccLp,
        address celebWallet,
        address investorWallet,
        address owner1,
        address owner2
    ) public onlyOwner {
            _memberWallet = memberWallet;
            _nftLp = nftLp;
            _unccLp = unccLp;
            _celebWallet = celebWallet;
            _investorWallet = investorWallet;
            _owner1 = owner1;
            _owner2 = owner2;
    }

    function setUNCCaddress(address newUNCCaddress) public onlyOwner {
        UNCC = IERC20(newUNCCaddress);
    }

    function setNFTaddress(address newNFTaddress) public onlyOwner {
        UncleLeroyNFT = IERC1155(newNFTaddress);
    }


}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
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
}