// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
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
pragma solidity ^0.8.16;

interface IERC721A {
    function totalSupply() external view returns (uint256);
    function tokenByIndex(uint256 index) external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
    function balanceOf(address owner) external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address);
    function setApprovalForAll(address operator, bool approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function transferFrom(address from, address to, uint256 tokenId) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IERC721A.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

// https://twitter.com/TwoPawsDefi
// https://twopaws.io/

//TOKENOMIC TOKEN 2PAW.
//Total supply 100M
//Add uniswap 75% supply token / 4 ETH, 25% team .
//LP token Burn (0) address.
//Tax: buy and sales of 2PAW over 80k are taxed at 20%; transfers over 80k are taxed at 1%.
//No tax on buy and sales and transfer of < 80k 2PAW.
//Auto-added Liquidity: 1.25% of tokens are auto-added to the pair if it has an overabundance of tokens. Liquidity not added from (number of sales NFTDAO * 30000) + 2.5m is used to buy back NFT.
//All tax proceeds are allocated to the protocol for incentives.

//TOKENOMIC PROTOCOL
//The protocol collects 0.3% of the loan amount if it is taken.
//The protocol distributes the 2PAW token from buy and sales of the token and NFT buy/sell itself, stimulating orders.
//NFT Buy 40000 2PAW / Sell 30000 2PAW
//Only NFT holders can place reward orders!
//1 NFT = 1 Reward order !
//NFTDAO holders are entitled to all the proceeds of the protocol after the sale of 1650 NFTDAO.
//The owner will change to the DAO contract address!
//Reward Formula: Repayment date must be 21 days from now (repayment date + loan amount/ denominator)*(repayment date + loan amount/ denominator).
//Only the DAO can add new denominator & tokens or change them.

// WT - Wrong Timestamp
// WR - Wrong Role
// NC - No Contracts
// WA - Wrong Amount
// WS - Wrong Status
// WLF - Wrong Lender Fee
// WTP - Wrong Tokens Pair
// TF - Transfer Filed
// LCB - The Lender cannot be the Borrower
// BCL - The Borrower cannot be the Lender
// CF - Cancel Filed
// BR - Only Borrower Can Repay
// LL - Only Lender Can Liquidate Order
// IB - Insufficient Tokens Balance
// EA - Empty Array
// ETF - Ether Transfer Filed
// LI - Locked NFTId
// 0A - Zero Address

library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value : value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint) external;
}

interface IPawToken is IERC20 {
    function devLocked() external view returns (bool);
}

contract TwoPaws is Ownable, ERC721Holder {
    enum Status {
        OPEN,
        WORKING,
        CLOSED,
        CANCELED
    }
    enum Role {
        SUPPLY,
        BORROW
    }
    struct SupportedTokenSettings {
        bool isRewarded;
        uint256 denominator;
    }

    struct Order {
        uint256 id;
        address lender;
        address borrower;
        address loanToken;
        uint256 loanAmount;
        address collateralToken;
        uint256 collateralAmount;
        uint256 lenderFeeAmount;
        uint256[] timestamps;
        uint256 rewardAmount;
        uint256 NFTId;
        Status status;
        Role role;
    }

    address public governanceContract;
    IPawToken public protocolToken;
    IERC721A public protocolNFT;
    uint256 public protocolTokenDecimals = 18;
    mapping(uint256 => bool) public lockedProtocolNFTs;
    // Orders
    uint256 public ordersCount;
    mapping(uint256 => Order) public orders;
    // DAO
    address[] public supportedTokens;
    mapping(address => SupportedTokenSettings) public supportedTokensSettings;
    uint256 public protocolNFTBuyPrice = 40000 * 10 ** protocolTokenDecimals;
    uint256 public protocolNFTSellPrice = 30000 * 10 ** protocolTokenDecimals;
    uint256 public exchangeFeePercent = 20;
    uint256 public DAOFeePercent = 30; // 0,3%

    event NewOrder(uint256 indexed orderId, Order order);
    event OrderStatusChange(uint256 indexed orderId, Status status);

    modifier noContracts() {
        require(msg.sender == tx.origin, "NC");
        _;
    }

    function init(address _protocolToken, address _protocolNFT, address _governanceContract) public onlyOwner {
        require (address(protocolToken) == address(0));
        protocolToken = IPawToken(_protocolToken);
        protocolNFT = IERC721A(_protocolNFT);
        governanceContract = _governanceContract;
    }

    function newOrder(
        address _loanToken,
        uint256 _loanAmount,
        address _collateralToken,
        uint256 _collateralAmount,
        uint256 _lenderFeeAmount,
        uint256[] memory _timestamps,
        Role _role,
        uint256 NFTId
    ) public noContracts returns (uint256 orderId) {
        require(msg.sender != address(0), "0A");
        require(
            _timestamps[0] > block.timestamp &&
            _timestamps[1] > block.timestamp &&
            _timestamps[1] > _timestamps[0],
            "WTS"
        );
        require(_role == Role.SUPPLY || _role == Role.BORROW, "WR");
        require(_loanAmount > 0 && _collateralAmount > 0, "WA");
        require(
            (_loanToken != address(0)) &&
            (_collateralToken != address(0)) &&
            (_loanToken != _collateralToken)
        , "WTP");
        uint256 rewardAmount = 0;
        if (NFTId < protocolNFT.totalSupply()) {
            address NFTOwner = protocolNFT.ownerOf(NFTId);
            if (
                NFTOwner == msg.sender &&
                supportedTokensSettings[_loanToken].isRewarded &&
                supportedTokensSettings[_collateralToken].isRewarded &&
                !lockedProtocolNFTs[NFTId]
            ) {
                rewardAmount = _calcRewardAmount(_timestamps[0], _loanToken, _loanAmount);
                lockedProtocolNFTs[NFTId] = rewardAmount == 0 ? false : true;
            } else {
                NFTId = type(uint256).max;
            }
        }
        uint256 amount;
        uint256 DAOFeeAmount;
        if (_role == Role.SUPPLY) {
            amount = _transferToProtocol(_loanToken, msg.sender, _loanAmount);
            DAOFeeAmount = amount * DAOFeePercent / 10000;
            require(_lenderFeeAmount + DAOFeeAmount < amount, "WA");
        } else if (_role == Role.BORROW) {
            amount = _transferToProtocol(_collateralToken, msg.sender, _collateralAmount);
            DAOFeeAmount = _loanAmount * DAOFeePercent / 10000;
            require(_lenderFeeAmount + DAOFeeAmount < _loanAmount, "WA");
        }
        orderId = ordersCount;
        Order memory order;
        order = Order(
            orderId,
            _role == Role.SUPPLY ? msg.sender : address(0),
            _role == Role.BORROW ? msg.sender : address(0),
            _loanToken,
            _role == Role.SUPPLY ? amount : _loanAmount,
            _collateralToken,
            _role == Role.BORROW ? amount : _collateralAmount,
            _lenderFeeAmount,
            _timestamps,
            rewardAmount,
            NFTId,
            Status.OPEN,
            _role
        );
        orders[orderId] = order;
        ordersCount++;
        emit NewOrder(orderId, order);
        return orderId;
    }

    function _transferToProtocol(address _token, address _sender, uint256 _amount) public returns (uint256 amount) {
        uint256 balanceBefore = IERC20(_token).balanceOf(address(this));
        TransferHelper.safeTransferFrom(_token, _sender, address(this), _amount);
        uint256 balanceAfter = IERC20(_token).balanceOf(address(this));
        require((balanceAfter - balanceBefore) > 0, "TF");
        return balanceAfter - balanceBefore;
    }


    function _calcRewardAmount(uint256 repayTimestamp, address _loanToken, uint256 _loanAmount) internal view returns (uint256 rewardAmount){
        uint256 daysAmount = (repayTimestamp - block.timestamp) / 1 days;
        uint256 addDays;
        if (supportedTokensSettings[_loanToken].denominator != 0) {
            addDays = _loanAmount / supportedTokensSettings[_loanToken].denominator;
            addDays = addDays > 100 ? 100 : addDays;
        }
        if ((daysAmount != 0) && (daysAmount >= 20)) {
            rewardAmount = ((daysAmount + addDays) ** 2) * 10 ** protocolTokenDecimals;
        } else {
            rewardAmount = 0;
        }

    }

    function getOrder(uint256 _orderId) public noContracts {
        if (orders[_orderId].role == Role.SUPPLY) {
            _getSupplyOrder(_orderId);
        } else if (orders[_orderId].role == Role.BORROW) {
            _getBorrowOrder(_orderId);
        }
        emit OrderStatusChange(_orderId, orders[_orderId].status);
    }

    function _getSupplyOrder(uint256 _orderId) private {
        require(
            block.timestamp < orders[_orderId].timestamps[1],
            "WT"
        );
        require(msg.sender != address(0), "0A");
        require(orders[_orderId].status == Status.OPEN, "WS");
        orders[_orderId].status = Status.WORKING;
        require(
            msg.sender != orders[_orderId].lender,
            "LCB"
        );
        uint256 amount = _transferToProtocol(
            orders[_orderId].collateralToken,
            msg.sender,
            orders[_orderId].collateralAmount
        );
        orders[_orderId].collateralAmount = amount;
        uint256 DAOFeeAmount = orders[_orderId].loanAmount * DAOFeePercent / 10000;
        TransferHelper.safeTransfer(
            orders[_orderId].loanToken,
            msg.sender,
            orders[_orderId].loanAmount - (DAOFeeAmount + orders[_orderId].lenderFeeAmount)
        );
        TransferHelper.safeTransfer(
            orders[_orderId].loanToken,
            owner(),
            DAOFeeAmount
        );
        if (orders[_orderId].lenderFeeAmount > 0) {
            TransferHelper.safeTransfer(
                orders[_orderId].loanToken,
                orders[_orderId].lender,
                orders[_orderId].lenderFeeAmount
            );
        }
        orders[_orderId].borrower = msg.sender;
    }

    function _getBorrowOrder(uint256 _orderId) private {
        require(
            block.timestamp < orders[_orderId].timestamps[1],
            "WT"
        );
        require(msg.sender != address(0), "0A");
        require(orders[_orderId].status == Status.OPEN, "WS");
        orders[_orderId].status = Status.WORKING;
        require(
            msg.sender != orders[_orderId].borrower,
            "BCL"
        );
        uint256 amount = _transferToProtocol(
            orders[_orderId].loanToken,
            msg.sender,
            orders[_orderId].loanAmount
        );
        orders[_orderId].loanAmount = amount;
        uint256 DAOFeeAmount = amount * DAOFeePercent / 10000;
        require(orders[_orderId].lenderFeeAmount + DAOFeeAmount < amount, "WA");
        TransferHelper.safeTransfer(
            orders[_orderId].loanToken,
            orders[_orderId].borrower,
            amount - (orders[_orderId].lenderFeeAmount + DAOFeeAmount)
        );
        TransferHelper.safeTransfer(
            orders[_orderId].loanToken,
            owner(),
            DAOFeeAmount
        );
        if (orders[_orderId].lenderFeeAmount > 0) {
            TransferHelper.safeTransfer(
                orders[_orderId].loanToken,
                msg.sender,
                orders[_orderId].lenderFeeAmount
            );
        }
        orders[_orderId].lender = msg.sender;
    }

    function cancelOrder(uint256 _orderId) public noContracts {
        require(orders[_orderId].status == Status.OPEN, "WS");
        orders[_orderId].status = Status.CANCELED;
        require(
            (orders[_orderId].role == Role.SUPPLY && orders[_orderId].lender == msg.sender) ||
            (orders[_orderId].role == Role.BORROW && orders[_orderId].borrower == msg.sender),
            "CF"
        );
        uint256 amount = orders[_orderId].role == Role.SUPPLY
        ? orders[_orderId].loanAmount
        : orders[_orderId].collateralAmount;

        orders[_orderId].role == Role.SUPPLY
        ? TransferHelper.safeTransfer(orders[_orderId].loanToken, msg.sender, amount)
        : TransferHelper.safeTransfer(orders[_orderId].collateralToken, msg.sender, amount);

        lockedProtocolNFTs[orders[_orderId].NFTId] = false;
        emit OrderStatusChange(_orderId, orders[_orderId].status);
    }

    function repayOrder(uint256 _orderId) public noContracts {
        require(orders[_orderId].status == Status.WORKING, "WS");
        orders[_orderId].status = Status.CLOSED;
        require(
            orders[_orderId].timestamps[0] < block.timestamp &&
            block.timestamp < orders[_orderId].timestamps[1],
            "WT"
        );
        require(orders[_orderId].borrower == msg.sender, "BR");
        uint256 amount = _transferToProtocol(
            orders[_orderId].loanToken,
            msg.sender,
            orders[_orderId].loanAmount
        );
        TransferHelper.safeTransfer(
            orders[_orderId].loanToken,
            orders[_orderId].lender,
            amount
        );
        TransferHelper.safeTransfer(
            orders[_orderId].collateralToken,
            orders[_orderId].borrower,
            orders[_orderId].collateralAmount
        );
        _reward(orders[_orderId].borrower, orders[_orderId].rewardAmount);
        lockedProtocolNFTs[orders[_orderId].NFTId] = false;
        emit OrderStatusChange(_orderId, orders[_orderId].status);
    }

    function liquidateOrder(uint256 _orderId) public noContracts {
        require(orders[_orderId].status == Status.WORKING, "WS");
        orders[_orderId].status = Status.CLOSED;
        require(block.timestamp > orders[_orderId].timestamps[1], "WT");
        require(orders[_orderId].lender == msg.sender, "LL");
        TransferHelper.safeTransfer(
            orders[_orderId].collateralToken,
            orders[_orderId].lender,
            orders[_orderId].collateralAmount
        );
        _reward(orders[_orderId].lender, orders[_orderId].rewardAmount);

        lockedProtocolNFTs[orders[_orderId].NFTId] = false;
        emit OrderStatusChange(_orderId, orders[_orderId].status);
    }

    function _reward(address _to, uint256 _amount) private {
        if (_amount > 0) return;
        uint256 contractBalance = protocolToken.balanceOf(address(this));
        uint256 lockedNFT = protocolNFT.totalSupply() - protocolNFT.balanceOf(address(this));
        uint256 lockedTokens = (protocolNFTSellPrice * lockedNFT);
        if (contractBalance > lockedTokens + _amount) {
            require(protocolToken.transfer(_to, _amount), "TF");
        }

    }

    function buyNFTForTokens(uint256[] memory _tokensIds) public {
        require(_tokensIds.length > 0, "EA");
        uint256 NFTCount = _tokensIds.length;
        uint256 protocolTokensAmount = NFTCount * protocolNFTBuyPrice;
        require(protocolToken.transferFrom(msg.sender, address(this), protocolTokensAmount), "TF");
        for (uint256 i = 0; i < NFTCount; i++) {
            protocolNFT.transferFrom(address(this), msg.sender, _tokensIds[i]);
        }
    }

    function sellNFT(uint256[] memory _tokensIds) public {
        require(_tokensIds.length > 0, "EA");
        uint256 NFTCount = _tokensIds.length;
        for (uint256 i = 0; i < NFTCount; i++) {
            require(!lockedProtocolNFTs[_tokensIds[i]], "LI");
            protocolNFT.transferFrom(msg.sender, address(this), _tokensIds[i]);
        }
        uint256 protocolTokensAmount = NFTCount * protocolNFTSellPrice;
        require(protocolToken.transfer(msg.sender, protocolTokensAmount), "TF");
    }

    function getAllOrders() public view returns (Order[] memory allOrders) {
        allOrders = new Order[](ordersCount);
        for (uint256 i = 0; i < ordersCount; i++) {
            Order storage order = orders[i];
            allOrders[i] = order;
        }
        return allOrders;
    }

    function getSupportedTokens() public view returns (address[] memory allTokens){
        allTokens = new address[](supportedTokens.length);
        for (uint256 i = 0; i < supportedTokens.length; i++) {
            address token = supportedTokens[i];
            allTokens[i] = token;
        }
        return allTokens;
    }

    //DAO
    function transferOwnershipToDAO() public {
        require(!protocolToken.devLocked());
        require(protocolNFT.balanceOf(address(this)) < 900);
        _transferOwnership(governanceContract);
    }

    function addSupportedToken(address _tokenAddress, uint256 _denominator) public onlyOwner {
        for (uint256 i = 0; i < supportedTokens.length; i++) {
            require(supportedTokens[i] != _tokenAddress);
        }
        supportedTokens.push(_tokenAddress);
        supportedTokensSettings[_tokenAddress].isRewarded = true;
        supportedTokensSettings[_tokenAddress].denominator = _denominator;
    }

    function setTokenReward(address _tokenAddress, bool _flag, uint256 _denominator) public onlyOwner {
        supportedTokensSettings[_tokenAddress].isRewarded = _flag;
        supportedTokensSettings[_tokenAddress].denominator = _denominator;
    }

    function changeProtocolNFTSellPrice(uint256 _protocolNFTSellPrice) public onlyOwner {
        require(
            _protocolNFTSellPrice < 30000 * 10 ** protocolTokenDecimals
            && _protocolNFTSellPrice >= 20000 * 10 ** protocolTokenDecimals
        );
        protocolNFTSellPrice = _protocolNFTSellPrice;
    }

    function changeDAOFeePercent(uint256 _DAOFeePercent) public onlyOwner {
        require(_DAOFeePercent >= 10 && _DAOFeePercent <= 150);
        DAOFeePercent = _DAOFeePercent;
    }

    function changeFeePercent(uint256 _exchangeFeePercent) public onlyOwner {
        require(_exchangeFeePercent <= 20 && _exchangeFeePercent > 0);
        exchangeFeePercent = _exchangeFeePercent;
    }

    function withdraw() public onlyOwner returns (bytes memory){
        (, bytes memory resp) = owner().call{value : address(this).balance}("");
        return resp;
    }

    receive() external payable {
    }
}