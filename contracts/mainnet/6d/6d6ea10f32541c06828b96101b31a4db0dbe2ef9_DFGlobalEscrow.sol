pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DFGlobalEscrow is Ownable {

    enum Sign {
        NULL,
        REVERT,
        RELEASE
    }

    enum TokenType {
        ETH,
        ERC20
    }

    struct EscrowRecord {
        string referenceId;
        address payable delegator;
        address payable owner;
        address payable recipient;
        address payable agent;
        TokenType tokenType;
        address tokenAddress;
        uint256 fund;
        mapping(address => bool) signer;
        mapping(address => Sign) signed;
        uint256 releaseCount;
        uint256 revertCount;
        bool funded;
        bool disputed;
        bool finalized;
        uint256 withdrawnAmount;
        bool shouldInvest;
    }

    mapping(string => EscrowRecord) _escrow;

    function isSigner(string memory _referenceId, address _signer)
        public
        view
        returns (bool)
    {
        return _escrow[_referenceId].signer[_signer];
    }

    function getSignedAction(string memory _referenceId, address _signer)
        public
        view
        returns (Sign)
    {
        return _escrow[_referenceId].signed[_signer];
    }

    event EscrowInitiated(
        string referenceId,
        address payer,
        uint256 amount,
        TokenType tokenType,
        address payee,
        address trustedParty
    );

    event Signature(
        string referenceId,
        address signer,
        Sign action
    );
    event Finalized(string referenceId, address winner);
    event Disputed(string referenceId, address disputer);
    event Withdrawn(
        string referenceId,
        address payee,
        uint256 amount
    );
    event Funded(
        string indexed referenceId,
        address indexed owner,
        uint256 amount
    );

    modifier multisigcheck(string memory _referenceId, address _party) {
        EscrowRecord storage e = _escrow[_referenceId];
        require(!e.finalized, "Escrow should not be finalized");
        require(e.funded, "Escrow is not funded");
        require(e.signer[_party], "Party is not eligible to sign");
        require(
            e.signed[_party] == Sign.NULL,
            "Party has already signed"
        );

        _;

        if (e.releaseCount == 2) {
            transferOwnership(e);
        } else if (e.revertCount == 2) {
            finalize(e);
        } else if (e.releaseCount == 1 && e.revertCount == 1) {
            dispute(e, _party);
        }
    }

    modifier onlyEscrowOwner(string memory _referenceId) {
        require(
            _escrow[_referenceId].owner == msg.sender,
            "Sender must be Escrow's owner"
        );
        _;
    }

    modifier onlyEscrowOwnerOrDelegator(string memory _referenceId) {
        require(
            _escrow[_referenceId].owner == msg.sender ||
            _escrow[_referenceId].delegator == msg.sender,
            "Sender must be Escrow's owner or delegator"
        );
        _;
    }

    modifier onlyEscrowPartyOrDelegator(string memory _referenceId) {
        require(
            _escrow[_referenceId].owner == msg.sender ||
            _escrow[_referenceId].recipient == msg.sender ||
            _escrow[_referenceId].agent == msg.sender ||
            _escrow[_referenceId].delegator == msg.sender,
            "Sender must be Escrow's Owner or Recipient or agent or delegator"
        );
        _;
    }

    modifier onlyEscrowOwnerOrRecipientOrDelegator(string memory _referenceId) {
        require(
            _escrow[_referenceId].owner == msg.sender ||
            _escrow[_referenceId].recipient == msg.sender ||
            _escrow[_referenceId].delegator == msg.sender,
            "Sender must be Escrow's Owner or Recipient or delegator"
        );
        _;
    }

    modifier onlyEscrowAgent(string memory _referenceId) {
        require(_escrow[_referenceId].agent == msg.sender, "Only Escrow Agent can perform action");
        _;
    }

    modifier isFunded(string memory _referenceId) {
        require(
            _escrow[_referenceId].funded == true,
            "Escrow should be funded"
        );
        _;
    }

    function createEscrow(
        string memory _referenceId,
        address payable _owner,
        address payable _recipient,
        address payable _agent,
        TokenType tokenType,
        address erc20TokenAddress,
        uint256 tokenAmount
    ) public payable onlyOwner {
        require(msg.sender != address(0), "Sender should not be null");
        require(_owner != address(0), "Recipient should not be null");
        require(_recipient != address(0), "Recipient should not be null");
        require(_agent != address(0), "Trusted Agent should not be null");
        require(_escrow[_referenceId].owner == address(0), "Duplicate Escrow");

        EscrowRecord storage e = _escrow[_referenceId];
        e.referenceId = _referenceId;
        e.owner = _owner;

        if (e.owner != msg.sender) {
            e.delegator = payable(msg.sender);
        }

        e.recipient = _recipient;
        e.agent = _agent;
        e.tokenType = tokenType;
        e.funded = false;

        if (e.tokenType == TokenType.ETH) {
            e.fund = tokenAmount;
            emit EscrowInitiated(
            _referenceId,
            _owner,
            e.fund,
            TokenType.ETH,
            _recipient,
            _agent
        );
        } else {
            e.tokenAddress = erc20TokenAddress;
            e.fund = tokenAmount;
            emit EscrowInitiated(
            _referenceId,
            _owner,
            e.fund,
            TokenType.ERC20,
            _recipient,
            _agent
        );
        }

        e.disputed = false;
        e.finalized = false;

        e.releaseCount = 0;
        e.revertCount = 0;

        e.signer[_owner] = true;
        e.signer[_recipient] = true;
        e.signer[_agent] = true;
    }

    function fund(string memory _referenceId, uint256 fundAmount)
        public
        payable
        onlyEscrowOwnerOrDelegator(_referenceId)
    {
        require(
            _escrow[_referenceId].owner != address(0),
            "Sender should not be null"
        );
        uint256 escrowFund = _escrow[_referenceId].fund;
        EscrowRecord storage e = _escrow[_referenceId];
        require(!e.funded, "Escrow is already funded");
        if (e.tokenType == TokenType.ETH) {
            require(
                msg.value == escrowFund,
                "Must fund for exact ETH-amount in Escrow"
            );
        } else {
            require(msg.value == 0, "cannot accept ethers for erc20 token escrow");
            require(
                fundAmount == escrowFund,
                "Must fund for exact ERC20-amount in Escrow"
            );
            IERC20 erc20Instance = IERC20(e.tokenAddress);
            erc20Instance.transferFrom(msg.sender, address(this), escrowFund);
        }

        e.funded = true;
        emit Funded(_referenceId, msg.sender, escrowFund);
    }

    function release(string memory _referenceId, address _party)
        public
        multisigcheck(_referenceId, _party)
        onlyEscrowPartyOrDelegator(_referenceId)
    {
        EscrowRecord storage e = _escrow[_referenceId];

        require(
          _party == e.owner || _party == e.recipient || _party == e.agent,
          "Only owner or recipient or agent can release an escrow"
        );

        if(_party == e.owner || _party == e.recipient) require(msg.sender == _party, "Party must be same as msg.sender");

        emit Signature(_referenceId, _party, Sign.RELEASE);

        e.signed[_party] = Sign.RELEASE;
        e.releaseCount++;
    }

    function reverse(string memory _referenceId, address _party)
        public
        onlyEscrowPartyOrDelegator(_referenceId)
        multisigcheck(_referenceId, _party)
    {
        EscrowRecord storage e = _escrow[_referenceId];
        
        require(
          _party == e.owner || _party == e.recipient || _party == e.agent,
          "Only owner or recipient or agent can reverse an escrow"
        );

        if(_party == e.owner || _party == e.recipient) require(msg.sender == _party, "Party must be same as msg.sender");

        emit Signature(_referenceId, _party, Sign.REVERT);

        e.signed[_party] = Sign.REVERT;
        e.revertCount++;
    }

    function dispute(string memory _referenceId, address _party) public 
    onlyEscrowOwnerOrRecipientOrDelegator(_referenceId)
    {
        EscrowRecord storage e = _escrow[_referenceId];
        require(!e.finalized, "Cannot dispute on a finalised Escrow");
        require(e.funded, "Escrow is not funded");
        require(
            _party == e.owner || _party == e.recipient,
            "Only owner or recipient can dispute on escrow"
        );

        if(_party == e.owner || _party == e.recipient) require(msg.sender == _party, "Party must be same as msg.sender");

        dispute(e, _party);
    }

    function finalize(string memory _referenceId) public onlyEscrowAgent(_referenceId) {
        finalize(_escrow[_referenceId]);
    }

    function transferOwnership(EscrowRecord storage e) internal {
        e.owner = e.recipient;
        finalize(e);
    }

    function dispute(EscrowRecord storage e, address _party) internal
    {
        emit Disputed(e.referenceId, _party);
        e.disputed = true;
    }

    function finalize(EscrowRecord storage e) internal {
        require(!e.finalized, "Escrow should not be finalized");

        emit Finalized(e.referenceId, e.owner);

        e.finalized = true;
    }

    function withdraw(string memory _referenceId, uint256 _amount)
        public
        onlyEscrowOwner(_referenceId)
        isFunded(_referenceId)
    {
        EscrowRecord storage e = _escrow[_referenceId];
        require(e.finalized, "Escrow should be finalized before withdrawal");
        require(e.withdrawnAmount + _amount <= e.fund, "Cannot withdraw more than the deposit");

        address escrowOwner = e.owner;

        emit Withdrawn(_referenceId, escrowOwner, _amount);

        e.withdrawnAmount = e.withdrawnAmount + _amount;

        if (e.tokenType == TokenType.ETH) {
            require((e.owner).send(_amount));
        } else {
            IERC20 erc20Instance = IERC20(e.tokenAddress);
            require(erc20Instance.transfer(escrowOwner, _amount));
        }
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