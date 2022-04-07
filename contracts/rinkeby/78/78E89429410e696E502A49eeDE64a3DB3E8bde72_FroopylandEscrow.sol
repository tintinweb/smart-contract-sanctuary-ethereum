// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./interfaces/IFroopylandEscrow.sol";

contract FroopylandEscrow is IFroopylandEscrow {
    using SafeERC20 for IERC20;

    struct Bounty {
        address issuer; // The poster who have complete control over the bounty, and can edit any of its parameters
        address tokenAddress; // the NFT smart contract address
        uint256 tokenId; // the NFT integer ID in the collection
        uint8 bountyType; // enumeration of "type" of bounty, application based, permission based, contest based
        uint8 bountyStatus; // enumeration of "status" of bounty,0 - null, 1 - active, 2 - complete, 3 - cancelled
        uint256 expirationTime; // (optional) block timestamp for a bounty expiration time
        address paymentToken; // The address of the token associated with the bounty (use address(0) to represent ether)
        uint256 balance; // The number of tokens which the bounty is able to pay out or refund
        ApplicantsInfo applicants;
    }

    struct ApplicantsInfo {
        address[] waitingForApprovals; // An array of individuals who applied for the bounty
        address[] participants; // An array of individuals who are allowed to work on a particular bounty
        address[] rejected; // rejected participants
        mapping(address => uint256) isWaitingForApprovals; // a quick lookup for checking applicant status (start index 1)
                                                           // either return the index in the corresponding array
                                                           // or 0 if not in the array
        mapping(address => uint256) isAccepted; // a quick lookup for checking applicant status, same as above
        mapping(address => uint256) isRejected; // a quick lookup for checking applicant status, same as above
        address winner; // the final bounty receiver
    }

    uint public numBounties; // An integer storing the total number of bounties in the contract
    mapping(address => uint[]) findBountiesByIssuer; // bounty issuer => bounty IDs
    mapping(uint => Bounty) bounties; // A mapping of bountyIDs to bounties
    address public owner; // The owner address
    uint256 public DECIMALBASE = 10000; // the base for percentage calculation
    uint256 public serviceRate; // the commission rate with DECIMALBASE. e.x. 100 = 100 / DECIMALBASE = 1%

    modifier isValidERC721Owner(
        address _erc721,
        uint256 _id)
    {
        require(msg.sender == IERC721(_erc721).ownerOf(_id), "FPLE001: NFT Owner validation failed.");
        _;
    }

    modifier isActiveBounty(uint256 _bountyId)
    {
        require(bounties[_bountyId].bountyStatus == 1, "FPLE002: inactive bounty.");
        _;
    }

    modifier isIssuer(uint256 _bountyId)
    {
        require(bounties[_bountyId].issuer == msg.sender, "FPLE003: issuer validation failed.");
        _;
    }

    modifier isValidPaymentChange(uint256 _bountyId, address newPaymentToken, uint256 newBalance)
    {
        require(
            bounties[_bountyId].paymentToken != newPaymentToken
            || bounties[_bountyId].balance != newBalance , "FPLE004: the payment does need to be changed.");
        _;
    }

    modifier isNotIssuer(uint256 _bountyId)
    {
        require(bounties[_bountyId].issuer != msg.sender, "FPLE005: the action can not be performed by the issuer.");
        _;
    }

    modifier isNotRejected(uint256 _bountyId, address _address)
    {
        require(bounties[_bountyId].applicants.isRejected[_address] == 0, "FPLE006: the applicant is already rejected.");
        _;
    }

    modifier isNotAccepted(uint256 _bountyId, address _address)
    {
        require(bounties[_bountyId].applicants.isRejected[_address] == 0, "FPLE006: the applicant is already accepted.");
        _;
    }

    modifier isNewApplicant(uint256 _bountyId)
    {
        require(bounties[_bountyId].applicants.isWaitingForApprovals[msg.sender] == 0, "FPLE007: the applicant is already added.");
        _;
    }

    modifier isNotNewApplicant(uint256 _bountyId, address _address)
    {
        require(bounties[_bountyId].applicants.isWaitingForApprovals[_address] != 0, "FPLE008: Can not find the applicant.");
        _;
    }

    modifier isParticipant(uint256 _bountyId, address _address)
    {
        require(bounties[_bountyId].applicants.isRejected[_address] == 0, "FPLE009: the address is not a participant.");
        _;
    }

    modifier isValidAddress(address _address)
    {
        require(_address != address(0), "FPLE011: invalid address, zero address is not accepted.");
        _;
    }

    constructor(
        uint _serviceRate
    ) public {
        owner = msg.sender;
        serviceRate = _serviceRate;
    }


    /// @dev issueBounty(): creates a new bounty
    /// @dev need to "approve" this contract to transferFrom in token contract
    /// @param _tokenAddress the related NFT smart contract address
    /// @param _tokenId the nft Id in the collection
    /// @param _bountyType bounty type
    /// @param _expirationTime the timestamp which will become the expiration time of the bounty
    /// @param _paymentTokenAddress the address of the token which will be used for the bounty
    /// @param _bountyBalance the balance of bounty
    function issueBounty(
        address _tokenAddress,
        uint256 _tokenId,
        uint8 _bountyType,
        uint256 _expirationTime,
        address _paymentTokenAddress,
        uint256 _bountyBalance)
    external
    override
    payable
    isValidERC721Owner(_tokenAddress, _tokenId)
    returns (uint256)
    {
        uint bountyId = numBounties; // The next bounty's index will always equal the number of existing bounties

        Bounty storage newBounty = bounties[numBounties];
        newBounty.issuer = msg.sender;
        newBounty.tokenAddress = _tokenAddress;
        newBounty.tokenId = _tokenId;
        newBounty.expirationTime = _expirationTime;
        newBounty.paymentToken = _paymentTokenAddress;

        if (_paymentTokenAddress != address(0)) {
            IERC20(_paymentTokenAddress).transfer(address(this), _bountyBalance);
        } else {
            payable(address(this)).transfer(_bountyBalance);
        }

        newBounty.bountyStatus = 1; // active

        // initiate applicant info arrays
        newBounty.applicants.waitingForApprovals.push(address(0));
        newBounty.applicants.participants.push(address(0));
        newBounty.applicants.rejected.push(address(0));

        findBountiesByIssuer[msg.sender].push(numBounties);

        numBounties = numBounties + 1; // Increments the number of bounties, since a new one has just been added

        emit BountyIssued(bountyId,
            msg.sender,
            _tokenAddress,
            _tokenId,
            _bountyType,
            newBounty.bountyStatus,
            _expirationTime,
            _paymentTokenAddress,
            _bountyBalance
        );

        return (bountyId);
    }

    /// @dev updateBounty(): update general info in a bounty
    /// @param _bountyId the existing bounty Id
    /// @param _tokenAddress the related NFT smart contract address
    /// @param _tokenId the nft Id in the collection
    /// @param _bountyType bounty type
    /// @param _expirationTime the timestamp which will become the expiration time of the bounty
    function updateBounty(
        uint256 _bountyId,
        address _tokenAddress,
        uint256 _tokenId,
        uint8 _bountyType,
        uint256 _expirationTime)
    external
    override
    isActiveBounty(_bountyId)
    isIssuer(_bountyId)
    isValidERC721Owner(_tokenAddress, _tokenId)
    returns (uint256)
    {
        Bounty storage newBounty = bounties[_bountyId];
        newBounty.tokenAddress = _tokenAddress;
        newBounty.tokenId = _tokenId;
        newBounty.expirationTime = _expirationTime;

        emit BountyUpdated(_bountyId,
            msg.sender,
            _tokenAddress,
            _tokenId,
            _bountyType,
            newBounty.bountyStatus,
            _expirationTime
        );

        return (_bountyId);
    }

    /// @dev updateBountyPayment(): update payment info in a bounty
    /// @dev need to "approve" this contract to transferFrom in token contract
    /// @param _bountyId the existing bounty Id
    /// @param _paymentTokenAddress the address of the token which will be used for the bounty
    /// @param _bountyBalance the balance of bounty
    function updateBountyPayment(
        uint256 _bountyId,
        address _paymentTokenAddress,
        uint256 _bountyBalance)
    external
    override
    payable
    isActiveBounty(_bountyId)
    isIssuer(_bountyId)
    isValidPaymentChange(_bountyId, _paymentTokenAddress, _bountyBalance)
    returns (uint256)
    {
        Bounty storage newBounty = bounties[_bountyId];

        if(newBounty.paymentToken != _paymentTokenAddress) {
            // Get new fund and then release old fund
            if (_paymentTokenAddress != address(0)) {
                IERC20(_paymentTokenAddress).transfer(address(this), _bountyBalance);
            } else {
                payable(address(this)).transfer(_bountyBalance);
            }

            if (newBounty.paymentToken != address(0)) {
                IERC20(newBounty.paymentToken).transferFrom(address(this), newBounty.issuer, newBounty.balance);
            } else {
                payable(newBounty.issuer).transfer(newBounty.balance);
            }
        } else {
            // refund/withdraw fund diff
            if (_paymentTokenAddress != address(0)) {
                if(_bountyBalance > newBounty.balance) {
                    IERC20(newBounty.paymentToken).transfer(address(this), _bountyBalance - newBounty.balance);
                } else {
                    IERC20(newBounty.paymentToken).transferFrom(address(this), msg.sender, newBounty.balance - _bountyBalance);
                }
            } else {
                if (_paymentTokenAddress != address(0)) {
                    if(_bountyBalance > newBounty.balance) {
                        payable(address(this)).transfer(_bountyBalance - newBounty.balance);
                    } else {
                        payable(newBounty.issuer).transfer(newBounty.balance - _bountyBalance);
                    }
                }
            }
        }

        newBounty.paymentToken = _paymentTokenAddress;
        newBounty.balance = _bountyBalance;

        emit BountyPaymentUpdated(_bountyId,
            msg.sender,
            _paymentTokenAddress,
            _bountyBalance
        );

        return (_bountyId);
    }

    /// @dev cancelBounty(): cancel a bounty
    /// @dev need to "approve" this contract to transferFrom in token contract
    /// @param _bountyId the existing bounty Id
    function cancelBounty(
        uint256 _bountyId)
    external
    override
    payable
    isActiveBounty(_bountyId)
    isIssuer(_bountyId)
    returns(uint256)
    {
        Bounty storage newBounty = bounties[_bountyId];

        newBounty.bountyStatus = 3; // cancelled

        if (newBounty.paymentToken != address(0)) {
            IERC20(newBounty.paymentToken).transferFrom(address(this), newBounty.issuer, newBounty.balance);
        } else {
            payable(newBounty.issuer).transfer(newBounty.balance);
        }

        emit BountyCancelled(_bountyId);

        return (_bountyId);
    }

    function applyForBounty(
        uint256 _bountyId
    )
    external
    override
    isActiveBounty(_bountyId)
    isNotIssuer(_bountyId)
    isNewApplicant(_bountyId)
    isNotRejected(_bountyId, msg.sender)
    isNotAccepted(_bountyId, msg.sender) {
        Bounty storage newBounty = bounties[_bountyId];
        newBounty.applicants.waitingForApprovals.push(msg.sender);
        uint256 indexOfApplicant = newBounty.applicants.waitingForApprovals.length - 1;
        newBounty.applicants.isWaitingForApprovals[msg.sender] = indexOfApplicant;

        emit BountyApplied(_bountyId, msg.sender);
    }

    function acceptApplicant(
        uint256 _bountyId,
        address _newApplicant
    )
    external
    override
    isActiveBounty(_bountyId)
    isIssuer(_bountyId)
    isValidAddress(_newApplicant)
    isNotNewApplicant(_bountyId, _newApplicant)
    isNotRejected(_bountyId, _newApplicant)
    isNotAccepted(_bountyId, _newApplicant)
    {
        Bounty storage newBounty = bounties[_bountyId];
        uint256 indexOfApplicant = newBounty.applicants.isWaitingForApprovals[_newApplicant];
        // reset the index and the mapping of array - waitingForApprovals
        newBounty.applicants.waitingForApprovals[indexOfApplicant] = address(0);
        newBounty.applicants.isWaitingForApprovals[_newApplicant] = 0;
        newBounty.applicants.participants.push(_newApplicant);
        uint256 indexOfParticipant = newBounty.applicants.participants.length - 1;
        newBounty.applicants.isAccepted[_newApplicant] = indexOfParticipant;

        emit ApplicantAccepted(_bountyId, _newApplicant);
    }

    function rejectApplicant(
        uint256 _bountyId,
        address _newApplicant
    )
    external
    override
    isActiveBounty(_bountyId)
    isIssuer(_bountyId)
    isValidAddress(_newApplicant)
    isNotNewApplicant(_bountyId, _newApplicant)
    isNotRejected(_bountyId, _newApplicant)
    isNotAccepted(_bountyId, _newApplicant)
    {
        Bounty storage newBounty = bounties[_bountyId];
        uint256 indexOfApplicant = newBounty.applicants.isWaitingForApprovals[_newApplicant];

        newBounty.applicants.rejected.push(_newApplicant);
        uint256 indexOfRej = newBounty.applicants.rejected.length - 1;
        newBounty.applicants.isRejected[_newApplicant] = indexOfRej;
        // reset the index and the mapping of array - waitingForApprovals
        newBounty.applicants.waitingForApprovals[indexOfApplicant] = address(0);
        newBounty.applicants.isWaitingForApprovals[_newApplicant] = 0;

        emit ApplicantRejected(_bountyId, _newApplicant);
    }

    // complete the bounty by selecting the winner
    function releaseBounty(
        uint256 _bountyId,
        address _winner
    )
    external
    override
    payable
    isActiveBounty(_bountyId)
    isIssuer(_bountyId)
    isValidAddress(_winner)
    isParticipant(_bountyId, _winner)
    {
        Bounty storage newBounty = bounties[_bountyId];
        newBounty.bountyStatus = 2;

        newBounty.applicants.winner = _winner;

        if (newBounty.paymentToken != address(0)) {
            IERC20(newBounty.paymentToken).transferFrom(address(this), _winner, newBounty.balance);
        } else {
            payable(_winner).transfer(newBounty.balance);
        }

    emit BountyCompleted(_bountyId, _winner);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
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

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.13;

interface IFroopylandEscrow {
    event BountyIssued(
        uint256 indexed bountyId,
        address indexed issuer,
        address tokenAddress,
        uint256 tokenId,
        uint8 bountyType,
        uint8 bountyStatus,
        uint256 expirationTime,
        address paymentToken,
        uint256 indexed balance);

    event BountyUpdated(
        uint256 indexed bountyId,
        address indexed issuer,
        address tokenAddress,
        uint256 tokenId,
        uint8 bountyType,
        uint8 bountyStatus,
        uint256 expirationTime);

    event BountyPaymentUpdated(
        uint256 indexed bountyId,
        address indexed issuer,
        address paymentToken,
        uint256 indexed balance);

    event BountyCancelled(uint256 indexed bountyId);

    event BountyApplied(
        uint256 indexed bountyId,
        address indexed applicant);

    event ApplicantAccepted(
        uint256 indexed bountyId,
        address indexed applicant);

    event ApplicantRejected(
        uint256 indexed bountyId,
        address indexed applicant);

    event BountyCompleted(
        uint256 indexed bountyId,
        address indexed winner);

    function issueBounty(
        address _nftAddress,
        uint256 _nftId,
        uint8 _bountyType,
        uint256 _expirationTime,
        address _tokenAddress,
        uint256 _bountyBalance) external payable returns(uint256);

    function updateBounty(
        uint256 _bountyId,
        address _tokenAddress,
        uint256 _tokenId,
        uint8 _bountyType,
        uint256 _expirationTime) external returns(uint256);

    function updateBountyPayment(
        uint256 _bountyId,
        address _tokenAddress,
        uint256 _bountyBalance) external payable returns(uint256);

    function cancelBounty(uint256 _bountyId) external payable returns(uint256);

    function applyForBounty(uint256 _bountyId) external;

    function acceptApplicant(uint256 _bountyId, address _newApplicant) external;

    function rejectApplicant(uint256 _bountyId, address _newApplicant) external;

    function releaseBounty(uint256 _bountyId, address _winner) external payable;
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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