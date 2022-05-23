/**
 *Submitted for verification at Etherscan.io on 2022-05-23
*/

// File: contracts/IFLBountyEscrow.sol



pragma solidity ^0.8.13;

interface IFLBountyEscrow {
    // enum BountyType {
    //     ApplicationBased,
    //     PermissionBased,
    //     ContestBased
    // }
    enum BountyState {
        Bidding,
        Approved,
        HalfStage,
        Completed,
        Cancelled
    }

    struct Bounty {
        BountyState state;
        address issuer;
        address fundTokenAddr; // funding token address
        uint256 fundTokenBalance; // funding amount
        
        address applicant;
        bytes32 next_auth_secret_hash; // used to authorize bounty state update actions

        uint256 startBlockNum; // for offchain event collector
        uint256 stopBlockNum; // for offchain event collector
    }

    // struct ApplicantInfo {
    //     uint256[] appliedBountyIds;
    //     mapping(uint256 => ApplyHistoryState) huntingStates;
    // }

    // struct NFTInfo {
    //     address tokenAddress; // the NFT smart contract address
    //     uint256 tokenId; // the NFT integer ID in the collection
    //     address refTokenAddress; // the reference NFT smart contract address
    //     uint256 refTokenId; // the reference NFT integer ID in the collection
    // }

    event BountyIssued(
        uint256 indexed bountyId,
        address indexed issuer,
        address fundTokenAddr,
        uint256 fundTokenBalance
    );

    event BountyPaymentUpdated(
        uint256 indexed bountyId,
        address indexed fundTokenAddr,
        uint256 indexed fundTokenBalance
    );

    event Approved(
        uint256 indexed bountyId,
        address indexed applicant,
        bytes32 indexed next_auth_secret_hash
    );

    event HalfStage(
        uint256 indexed bountyId,
        bytes32 indexed next_auth_secret_hash
    );

    event Completed(
        uint256 indexed bountyId
    );

    event Rejected(uint256 indexed bountyId, address indexed applicant);

    event Cancelled(uint256 indexed bountyId);

    function issueBounty(
        // uint8 _bountyType, // enumeration of "type" of bounty, application based, permission based, contest based
        address _fundTokenAddr,
        uint256 _fundTokenBalance
    ) external payable returns (uint256 bountyId);

    function updateBountyPayment(
        uint256 _bountyId,
        address _fundTokenAddr,
        uint256 _fundTokenBalance
    ) external payable;

    function approve(
        uint256 _bountyId,
        address _applicant,
        bytes32 _next_auth_secret_hash
    ) external;

    function halfStage(
        uint256 _bountyId,
        bytes32 _auth_secret,
        bytes32 _next_auth_secret_hash
    ) external;

    function complete(
        uint256 _bountyId,
        bytes32 _auth_secret
        // bytes32 _next_auth_secret_hash
    ) external;

    function reject(
        uint256 _bountyId,
        bytes32 _auth_secret
    ) external;

    function cancelAndRefund(uint256 _bountyId) external;

    // UX, just be nice to issuer
    function rejectThenCancelAndRefund(
        uint256 _bountyId,
        bytes32 _auth_secret
    ) external;

    // function getBountyApplicant(uint256 _bountyId)
    //     external
    //     view
    //     returns (address);

    // function getApplicantBountyIndexes(address _applicant)
    //     external
    //     view
    //     returns (uint256[] memory);

    // function getApplicantWorkState(address _applicant, uint256 _bountyId)
    //     external
    //     view
    //     returns (uint256);
}

// File: @openzeppelin/contracts/utils/Address.sol


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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;



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

// File: contracts/FroopylandEscrow.sol



pragma solidity ^0.8.13;

// import "@openzeppelin/contracts/token/ERC721/IERC721.sol";



contract FroopylandEscrow is IFLBountyEscrow {
    using SafeERC20 for IERC20;

    address public owner;
    uint256 constant DECIMALBASE = 10000; // the base for percentage calculation
    uint256 public serviceRate; // the commission rate with DECIMALBASE. e.x. 100 = 100 / DECIMALBASE = 1%
    uint256 constant halfStagePercentage = 50;

    uint256 public numBounties;
    mapping(uint256 => Bounty) bounties; // mapping{bountyId: Bounty}
    mapping(address => uint256[]) funder2bountyId; // bounty issuer => bounty IDs

    modifier isValidPaymentChange(
        uint256 bountyId,
        address newPaymentToken,
        uint256 newBalance
    ) {
        require(
            bounties[bountyId].fundTokenAddr != newPaymentToken ||
                bounties[bountyId].fundTokenBalance != newBalance,
            "FPLE004: the payment does need to be changed."
        );
        _;
    }

    modifier onState(uint256 _bountyId, BountyState _state) {
        require(bounties[_bountyId].state == _state);
        _;
    }

    modifier onlyIssuer(uint256 _bountyId) {
        require(
            msg.sender == bounties[_bountyId].issuer,
            "FPLE021: the action can only be performed by the bounty issuer."
        );
        _;
    }

    modifier onlyIssuerOrApplicant(uint256 _bountyId) {
        require(
            msg.sender == bounties[_bountyId].issuer || msg.sender == bounties[_bountyId].applicant,
            "FPLE022: the action can only be performed by the bounty issuer or applicant."
        );
        _;
    }

    modifier onlyAuth(uint256 _bountyId, bytes32 _auth_secret){
        require(
            keccak256(abi.encodePacked(_auth_secret)) == bounties[_bountyId].next_auth_secret_hash,
            "FPLE040: auth secret failed."
        );
        _;
    }

    constructor(uint256 _serviceRate) {
        owner = msg.sender;
        serviceRate = _serviceRate;
    }

    /// @dev issueBounty(): creates a new bounty
    /// @dev need to "approve" this contract to transferFrom in token contract
    /// @param _fundTokenAddr the address of the token which will be used for the bounty
    /// @param _fundTokenBalance the balance of bounty
    function issueBounty(
        address _fundTokenAddr,
        uint256 _fundTokenBalance
    )
        external
        payable
        override
        returns (uint256 bountyId)
    {
        bountyId = numBounties++;
        Bounty storage newBounty = bounties[bountyId];
        newBounty.issuer = msg.sender;
        newBounty.fundTokenAddr = _fundTokenAddr;
        newBounty.fundTokenBalance = _fundTokenBalance;

        if (_fundTokenAddr != address(0)) {
            IERC20(_fundTokenAddr).transferFrom(
                msg.sender,
                address(this),
                _fundTokenBalance
            );
            // require(,"FPLE023: not enough Token.")
        } else {
            require(msg.value == _fundTokenBalance, "FPLE024: not enough ETH.");
            // payable(address(this)).transfer(fundTokenBalance);
        }

        newBounty.startBlockNum = block.number;
        newBounty.state = BountyState.Bidding;
        funder2bountyId[msg.sender].push(bountyId);

        emit BountyIssued(
            bountyId,
            newBounty.issuer,
            newBounty.fundTokenAddr,
            newBounty.fundTokenBalance
        );
    }

    /// @dev update funding, only on Bidding state, maybe add Approved/Submitted later, if necessary
    function updateBountyPayment(
        uint256 _bountyId,
        address _fundTokenAddr,
        uint256 _fundTokenBalance
    )
        external
        payable
        override
        onState(_bountyId, BountyState.Bidding)
        isValidPaymentChange(_bountyId, _fundTokenAddr, _fundTokenBalance)
    {
        Bounty storage newBounty = bounties[_bountyId];

        if (newBounty.fundTokenAddr != _fundTokenAddr) {
            // Get new fund and then release old fund
            if (_fundTokenAddr != address(0)) {
                IERC20(_fundTokenAddr).transfer(
                    address(this),
                    _fundTokenBalance
                );
            } else {
                payable(address(this)).transfer(_fundTokenBalance);
            }

            if (newBounty.fundTokenAddr != address(0)) {
                IERC20(newBounty.fundTokenAddr).transferFrom(
                    address(this),
                    newBounty.issuer,
                    newBounty.fundTokenBalance
                );
            } else {
                payable(newBounty.issuer).transfer(newBounty.fundTokenBalance);
            }
        } else {
            // refund/withdraw fund diff
            if (_fundTokenAddr != address(0)) {
                if (_fundTokenBalance > newBounty.fundTokenBalance) {
                    IERC20(newBounty.fundTokenAddr).transfer(
                        address(this),
                        _fundTokenBalance - newBounty.fundTokenBalance
                    );
                } else {
                    IERC20(newBounty.fundTokenAddr).transferFrom(
                        address(this),
                        msg.sender,
                        newBounty.fundTokenBalance - _fundTokenBalance
                    );
                }
            } else {
                if (_fundTokenBalance > newBounty.fundTokenBalance) {
                    payable(address(this)).transfer(
                        _fundTokenBalance - newBounty.fundTokenBalance
                    );
                } else {
                    payable(newBounty.issuer).transfer(
                        newBounty.fundTokenBalance - _fundTokenBalance
                    );
                }
            }
        }

        newBounty.fundTokenAddr = _fundTokenAddr;
        newBounty.fundTokenBalance = _fundTokenBalance;

        emit BountyPaymentUpdated(_bountyId, _fundTokenAddr, _fundTokenBalance);
    }

    function approve(
        uint256 _bountyId,
        address _applicant,
        bytes32 _next_auth_secret_hash
    )
        external
        override
        onlyIssuer(_bountyId)
        // isApplicantExist(_bountyId, _applicant)
        onState(_bountyId, BountyState.Bidding)
    {
        Bounty storage bounty = bounties[_bountyId];
        bounty.applicant = _applicant;
        bounty.next_auth_secret_hash = _next_auth_secret_hash;

        // applicants[_applicant].huntingStates[_bountyId] = ApplyHistoryState.Working;

        bounty.state = BountyState.Approved;

        emit Approved(_bountyId, _applicant, _next_auth_secret_hash);
    }

    function halfStage(
        uint256 _bountyId,
        bytes32 _auth_secret,
        bytes32 _next_auth_secret_hash
    )
        external
        override
        onlyIssuerOrApplicant(_bountyId)
        onState(_bountyId, BountyState.Approved)
        onlyAuth(_bountyId, _auth_secret)
    {
        Bounty storage bounty = bounties[_bountyId];
        bounty.next_auth_secret_hash = _next_auth_secret_hash;
        bounty.state = BountyState.HalfStage;

        emit HalfStage(_bountyId, _next_auth_secret_hash);
    }


    function complete(
        uint256 _bountyId,
        bytes32 _auth_secret
    )
        external
        override
        onlyIssuerOrApplicant(_bountyId)
        onState(_bountyId, BountyState.HalfStage)
        onlyAuth(_bountyId, _auth_secret)
    {
        Bounty storage bounty = bounties[_bountyId];
        bounty.next_auth_secret_hash = bytes32(0);//_next_auth_secret_hash;
        bounty.state = BountyState.Completed;
        bounty.stopBlockNum = block.number;

        // applicants[bounty.applicant].huntingStates[_bountyId] = ApplyHistoryState
        //     .Accept;

        _transferFund(
            _bountyId,
            bounty.fundTokenBalance,
            payable(bounty.applicant)
        );

        emit Completed(_bountyId);
    }

    function _transferFund(
        uint256 _bountyId,
        uint256 _amt,
        address payable _to
    ) internal {
        Bounty storage bounty = bounties[_bountyId];
        require(_amt <= bounty.fundTokenBalance);

        address tokenAddr = bounty.fundTokenAddr;
        uint256 tokenAmt = _amt;

        if (tokenAddr == address(0)) {
            _to.transfer(tokenAmt);
            //require success
        } else {
            //TODO
        }
    }
    
    function _reject(uint256 _bountyId) internal {
        Bounty storage bounty = bounties[_bountyId];
        bounty.state = BountyState.Bidding;
        // applicants[bounty.applicant].huntingStates[_bountyId] = ApplyHistoryState
        //     .Reject;
        
        //TODO: transfer partial funds to applicants, according to Stage State.
        
        emit Rejected(_bountyId, bounty.applicant);
    }

    function reject(
        uint256 _bountyId,
        bytes32 _auth_secret
    )
        external
        override
        onlyIssuer(_bountyId)
        // onState(_bountyId, BountyState.HalfStage)
        onlyAuth(_bountyId, _auth_secret)
    {
        _reject(_bountyId);
    }

    /// @dev cancel, refund all funding
    /// @notice since only allowed on Bidding, no compensation is involved
    function cancelAndRefund(uint256 _bountyId)
        public
        override
        onlyIssuer(_bountyId)
        onState(_bountyId, BountyState.Bidding)
    {
        Bounty storage bounty = bounties[_bountyId];

        bounty.state = BountyState.Cancelled;

        _transferFund(
            _bountyId,
            bounty.fundTokenBalance,
            payable(bounty.issuer)
        ); // refund

        bounty.stopBlockNum = block.number;

        emit Cancelled(_bountyId);
    }

    /// @dev UX, just be nice to issuer
    /// @dev reject and quit and cancel without updating _submissionExpiration & _approveExpiration
    function rejectThenCancelAndRefund(
        uint256 _bountyId,
        bytes32 _auth_secret
    )
        external
        override
        onlyIssuer(_bountyId)
        onlyAuth(_bountyId, _auth_secret)
        // onState(_bountyId, BountyState.Submitted)
    {
        _reject(_bountyId);
        cancelAndRefund(_bountyId);
    }

}