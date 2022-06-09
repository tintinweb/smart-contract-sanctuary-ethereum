// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
//import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
// import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./IFLBountyEscrow.sol";

contract FLBountyEscrow is IFLBountyEscrow {
//    using SafeERC20 for IERC20;

    address public owner;
    uint256 constant DECIMALBASE = 10000; // the base for percentage calculation
    uint256 public serviceRate; // the commission rate with DECIMALBASE. e.x. 100 = 100 / DECIMALBASE = 1%
    uint256 constant halfStagePercentage = 5000;

    uint256 public numBounties;
    mapping(uint256 => Bounty) public bounties; // mapping{bountyId: Bounty}
    mapping(address => uint256[]) public issuer2bountyId; // bounty issuer => bounty IDs

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

    modifier onlySameTokenIfAny(uint256 _bountyId, address _tokenAddr){
        require(
            bounties[_bountyId].fundTokenBalance == 0 || _tokenAddr == bounties[_bountyId].fundTokenAddr,
            "FPLE030: token addr should be the same with current one."
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
//        require(_fundTokenBalance > 0, "FPLE034: fund balance should > 0.");

        bountyId = numBounties++;
        Bounty storage newBounty = bounties[bountyId];
        newBounty.issuer = msg.sender;

        newBounty.startBlockNum = block.number;
        newBounty.state = BountyState.Bidding;
        issuer2bountyId[msg.sender].push(bountyId);

        newBounty.fundTokenAddr = _fundTokenAddr;
        newBounty.fundTokenBalance = 0;
        newBounty.currentFundPercentage = 0;
        fundDeposit(bountyId, _fundTokenAddr, _fundTokenBalance); // CEI

        emit BountyIssued(
            bountyId,
            newBounty.issuer,
            newBounty.fundTokenAddr,
            newBounty.fundTokenBalance
        );
    }

    function fundDeposit(
        uint256 _bountyId,
        address _fundTokenAddr,
        uint256 _fundTokenAmt
    )
    public
    payable
    override
    onlyIssuer(_bountyId) // just in case someone deposits to the wrong bounty
//    onlySameTokenIfAny(_bountyId, _fundTokenAddr) // redundant
    onState(_bountyId, BountyState.Bidding)
    {
        _transferFundIn(
            _bountyId,
            _fundTokenAddr,
            _fundTokenAmt,
            msg.sender
        );

//        emit Deposit(_bountyId, _fundTokenAddr, _fundTokenAmt);
    }

    function fundWithdraw(
        uint256 _bountyId,
        address _fundTokenAddr,
        uint256 _fundTokenAmt
    )
    public
    override
    onlyIssuer(_bountyId)
//    onlySameTokenIfAny(_bountyId, _fundTokenAddr)// redundant
    onState(_bountyId, BountyState.Bidding)
    {
        Bounty storage bounty = bounties[_bountyId];
        _transferFundOut(
            _bountyId,
            _fundTokenAddr,
            _fundTokenAmt,
            payable(bounty.issuer)
        );

//        emit Withdraw(_bountyId, _fundTokenAddr, _fundTokenAmt);
    }

    //@@dev a UX wrapper for withdraw all fund and deposit another kind of token
    function fundUpdate(
        uint256 _bountyId,
        address _fundTokenNewAddr,
        uint256 _fundTokenNewBalance
    )
    external
    payable
    override
//    onState(_bountyId, BountyState.Bidding) // redundant
    {
        Bounty storage bounty = bounties[_bountyId];
        if (bounty.fundTokenAddr != _fundTokenNewAddr && bounty.fundTokenBalance > 0){
            fundWithdraw(_bountyId, bounty.fundTokenAddr, bounty.fundTokenBalance);
            bounty.fundTokenAddr = _fundTokenNewAddr;
            fundDeposit(_bountyId, _fundTokenNewAddr, _fundTokenNewBalance);
        } else {
            require(_fundTokenNewBalance != bounty.fundTokenBalance, "Fund No Need To Change");
            if (_fundTokenNewBalance > bounty.fundTokenBalance) {
//                console.log(">");
//                console.log(_fundTokenNewBalance - bounty.fundTokenBalance);
                fundDeposit(_bountyId, _fundTokenNewAddr, _fundTokenNewBalance - bounty.fundTokenBalance);
            } else {
//                console.log("<");
//                console.log(_fundTokenNewBalance - bounty.fundTokenBalance);
                fundWithdraw(_bountyId, _fundTokenNewAddr, bounty.fundTokenBalance - _fundTokenNewBalance);
            }
        }
    }

    function approve(
        uint256 _bountyId,
        address _applicant,
        bytes32 _next_auth_secret_hash // add zk proof | exp in the future to prevent lock
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
        bounty.currentFundPercentage = halfStagePercentage;

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
        bounty.currentFundPercentage = DECIMALBASE;

        _transferFundOut(
            _bountyId,
            bounty.fundTokenAddr,
            bounty.fundTokenBalance,
            payable(bounty.applicant)
        );

        emit Completed(_bountyId);
    }

    function _transferFundIn(
        uint256 _bountyId,
        address _tokenAddr,
        uint256 _tokenAmt,
        address _from
    ) internal onlySameTokenIfAny(_bountyId, _tokenAddr) {
        bounties[_bountyId].fundTokenBalance += _tokenAmt;
        if (_tokenAddr == address(0)) {
            require(msg.value == _tokenAmt, "FPLE032: deposit value != declared amount.");
        } else {
            bool succ = IERC20(_tokenAddr).transferFrom(_from, address(this), _tokenAmt);
            require(succ, "FPLE033: token transfer in failed.");
        }

        emit FundTransferIn(_bountyId, _tokenAddr, _tokenAmt, _from);
    }

    function _transferFundOut(
        uint256 _bountyId,
        address _tokenAddr,
        uint256 _tokenAmt,
        address payable _to
    ) internal onlySameTokenIfAny(_bountyId, _tokenAddr) {
        require(_to != address(0), "FPLE035: don't transfer to address(0)");
        bounties[_bountyId].fundTokenBalance -= _tokenAmt;
        if (_tokenAddr == address(0)) {
            _to.transfer(_tokenAmt);
        } else {
            bool succ = IERC20(_tokenAddr).transfer(_to, _tokenAmt);
            require(succ, "FPLE031: token transfer out failed.");
        }

        emit FundTransferOut(_bountyId, _tokenAddr, _tokenAmt, _to);
    }

    function _reject(uint256 _bountyId) internal {
        Bounty storage bounty = bounties[_bountyId];
        bounty.state = BountyState.Bidding;
        // applicants[bounty.applicant].huntingStates[_bountyId] = ApplyHistoryState
        //     .Reject;

        _transferFundOut(
            _bountyId,
            bounty.fundTokenAddr,
            bounty.fundTokenBalance * bounty.currentFundPercentage / DECIMALBASE,
            payable(bounty.applicant)
        );

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

        bounty.stopBlockNum = block.number;

        fundWithdraw(_bountyId, bounty.fundTokenAddr, bounty.fundTokenBalance); // check CEI later

        bounty.state = BountyState.Cancelled;

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

    function getBountyFundByID(uint256 _bountyId) external view returns(address, uint256){
        Bounty storage bounty = bounties[_bountyId];
        return (bounty.fundTokenAddr, bounty.fundTokenBalance);
    }
    function getBountyIDByIssuer(address _issuer) external view returns(uint256[] memory){
        return issuer2bountyId[_issuer];
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

// SPDX-License-Identifier: UNLICENSED

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
        uint256 currentFundPercentage;

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

    event FundTransferIn(
        uint256 indexed bountyId,
        address indexed fundTokenAddr,
        uint256 indexed fundTokenAmt,
        address from
    );

    event FundTransferOut(
        uint256 indexed bountyId,
        address indexed fundTokenAddr,
        uint256 indexed fundTokenAmt,
        address to
    );

    function issueBounty(
    // uint8 _bountyType, // enumeration of "type" of bounty, application based, permission based, contest based
        address _fundTokenAddr,
        uint256 _fundTokenBalance
    ) external payable returns (uint256 bountyId);

    function fundDeposit(
        uint256 _bountyId,
        address _fundTokenAddr,
        uint256 _fundTokenAmt
    ) external payable;

    function fundWithdraw(
        uint256 _bountyId,
        address _fundTokenAddr,
        uint256 _fundTokenAmt
    ) external;

    function fundUpdate(
        uint256 _bountyId,
        address _fundTokenNewAddr,
        uint256 _fundTokenNewBalance
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