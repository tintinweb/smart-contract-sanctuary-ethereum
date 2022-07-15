// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "CLStorage.sol";

/// @title Contract to implement and test the basic fuctions of CLHouses
/// @author Leonardo Urrego
/// @notice This contract for test only the most basic interactions
contract CLHouse is CLStorage {

    /// @notice Create a new CLH
    /// @dev Some parameters can be ignored depending on the governance model
    /// @param _owner The address of the deployed wallet
    /// @param _houseName Name given by the owner
    /// @param _housePrivate If is set to 1, the CLH is set to private
    /// @param _gov keccak256 hash of the governance model, see the __GOV_* constans
    /// @param _govRuleMaxManagerMembers Max of manager member that CLH can accept (only for COMMITTEE )
    /// @param _govRuleMaxActiveMembers Max of all members (including managers)
    /// @param _govRuleApprovPercentage Percentage for approval o reject proposal based on `numManagerMembers`
    /// @param _ManagerWallets Whitelist of address for invitate as managers
    constructor(
        address _owner, 
        string memory _houseName,
        bool _housePrivate,
        bytes32 _gov,
        uint8 _govRuleMaxManagerMembers,
        uint8 _govRuleMaxActiveMembers,
        uint8 _govRuleApprovPercentage,
        address _CLCMemberManagement,
        address _CLCGovernance,
        address _CLLConstructor,
        address[] memory _ManagerWallets
    )
    {

        
        (bool successDGTCLL, bytes memory dataDLGTCLL) = _CLLConstructor.delegatecall(
            abi.encodeWithSignature(
                "CLLCLHConstructor(address,string,bool,bytes32,uint8,uint8,uint8,address,address,address[])",
                _owner, 
                _houseName,
                _housePrivate,
                _gov,
                _govRuleMaxManagerMembers,
                _govRuleMaxActiveMembers,
                _govRuleApprovPercentage,
                _CLCMemberManagement,
                _CLCGovernance,
                _ManagerWallets
            )
        );

        if( !successDGTCLL ) {
            assembly {
                let ptr := mload(0x40)
                let size := returndatasize()
                returndatacopy(ptr, 0, size)
                revert(ptr, size)
            }
        }
    }

    /// @notice Execute (or reject) a proposal computing the votes and the governance model
    /// @dev Normally is called internally after each vote
    /// @param _propId ID of the proposal, based on `arrProposals`
    /// @return status True if the proposal can be execute, false in other cases
    /// @return message result of the transaction
    function ExecProp(
        uint256 _propId
    )
        public
        returns(
            bool status,
            string memory message
        )
    {
        (bool successDGTCLL, bytes memory dataDLGTCLL) = CLCGovernance.delegatecall(
            abi.encodeWithSignature(
                "_ExecProp(uint256)",
                _propId
            )
        );

        if( !successDGTCLL ) {
            assembly {
                let ptr := mload(0x40)
                let size := returndatasize()
                returndatacopy(ptr, 0, size)
                revert(ptr, size)
            }
        }

        return ( true , "Success executed proposal" );
    }

    /// @notice Used to vote a proposal
    /// @dev After vote the proposal automatically try to be executed
    /// @param _propId ID of the proposal, based on `arrProposals`
    /// @param _support True for accept, false to reject
    /// @param _justification About your vote
    /// @return true is the vote can be stored
    function VoteProposal(
        uint256 _propId,
        bool _support,
        string memory _justification
    )
        public
        returns( bool )
    {
        (bool successDGTCLL, bytes memory dataDLGTCLL) = CLCGovernance.delegatecall(
            abi.encodeWithSignature( 
                "_VoteProposal(uint256,bool,string)", 
                _propId,
                _support,
                _justification
            )
        );

        if( !successDGTCLL ) {
            assembly {
                let ptr := mload(0x40)
                let size := returndatasize()
                returndatacopy(ptr, 0, size)
                revert(ptr, size)
            }
        }

        return true;
    }

    /// @notice Generate a new proposal to invite a new member
    /// @dev the execution of this proposal only create an invitation 
    /// @param _walletAddr  Address of the new user
    /// @param _name Can be the nickname or other reference to the User
    /// @param _description A text for the proposal
    /// @param _isManager True if is for a manager member
    /// @return propId ID of the new proposal, based on `arrProposals`
    function PropInviteMember(
        address _walletAddr,
        string memory _name,
        string memory _description,
        bool _isManager,
        uint256 _delayTime
    )
        external
        returns( uint256 propId )
    {
        (bool successDGTCLL, bytes memory dataDLGTCLL) = CLCGovernance.delegatecall(
            abi.encodeWithSignature( 
                "PropInviteMember(address,string,string,bool,uint256)", 
                _walletAddr,
                _name,
                _description,
                _isManager,
                _delayTime
            )
        );

        assembly {
            let ptr := mload(0x40)
            let size := returndatasize()
            returndatacopy(ptr, 0, size)
            if iszero( successDGTCLL ) {
                revert(ptr, size)
            }
            propId := mload(ptr)
        }
    }

    /// @notice Generate a new proposal for remove a member
    /// @dev The member can be a managaer
    /// @param _walletAddr member Address to be removed
    /// @param _description About the proposal
    /// @return propId ID of the new proposal, based on `arrProposals`
    function PropRemoveMember(
        address _walletAddr,
        string memory _description,
        uint256 _delayTime
    )
        external
        returns( uint256 propId )
    {
        (bool successDGTCLL, bytes memory dataDLGTCLL) = CLCGovernance.delegatecall(
            abi.encodeWithSignature( 
                "PropRemoveMember(address,string,uint256)", 
                _walletAddr,
                _description,
                _delayTime
            )
        );

        assembly {
            let ptr := mload(0x40)
            let size := returndatasize()
            returndatacopy(ptr, 0, size)
            if iszero( successDGTCLL ) {
                revert(ptr, size)
            }
            propId := mload(ptr)
        }
    }

    /// @notice generate a new proposal to transfer ETH in weis
    /// @dev When execute this proposal, the transfer is made
    /// @param _to Recipient address
    /// @param _amountOutCLV Amount to transfer (in wei)
    /// @param _description About this proposal
    /// @return propId ID of the new proposal, based on `arrProposals`
    function PropTxWei(
        address _to,
        uint256 _amountOutCLV,
        string memory _description,
        uint256 _delayTime
    )
        external
        returns( uint256 propId )
    {
        (bool successDGTCLL, bytes memory dataDLGTCLL) = CLCGovernance.delegatecall(
            abi.encodeWithSignature( 
                "PropTxWei(address,uint256,string,uint256)", 
                _to,
                _amountOutCLV,
                _description,
                _delayTime
            )
        );

        assembly {
            let ptr := mload(0x40)
            let size := returndatasize()
            returndatacopy(ptr, 0, size)
            if iszero( successDGTCLL ) {
                revert(ptr, size)
            }
            propId := mload(ptr)
        }
    }

    /// @notice generate a new proposal to transfer ETH in weis
    /// @dev When execute this proposal, the transfer is made
    /// @param _to Recipient address
    /// @param _amountOutCLV Amount to transfer (in wei)
    /// @param _description About this proposal
    /// @return propId ID of the new proposal, based on `arrProposals`
    function PropTxERC20(
        address _to,
        uint256 _amountOutCLV,
        address _tokenOutCLV,
        string memory _description,
        uint256 _delayTime
    )
        external
        returns( uint256 propId )
    {
        (bool successDGTCLL, bytes memory dataDLGTCLL) = CLCGovernance.delegatecall(
            abi.encodeWithSignature( 
                "PropTxERC20(address,uint256,address,string,uint256)", 
                _to,
                _amountOutCLV,
                _tokenOutCLV,
                _description,
                _delayTime
            )
        );

        assembly {
            let ptr := mload(0x40)
            let size := returndatasize()
            returndatacopy(ptr, 0, size)
            if iszero( successDGTCLL ) {
                revert(ptr, size)
            }
            propId := mload(ptr)
        }
    }

    /// @notice Generate a new proposal for change some governance parameters
    /// @dev When execute this proposal the new values will be set
    /// @param _newApprovPercentage The new percentaje for accept or reject a proposal
    /// @param _description About the new proposal 
    /// @return propId ID of the new proposal, based on `arrProposals`
    function PropGovRules(
        uint8 _newApprovPercentage,
        string memory _description,
        uint256 _delayTime
    )
        external
        returns( uint256 propId )
    {
        (bool successDGTCLL, bytes memory dataDLGTCLL) = CLCGovernance.delegatecall(
            abi.encodeWithSignature( 
                "PropGovRules(uint8,string,uint256)", 
                _newApprovPercentage,
                _description,
                _delayTime
            )
        );

        assembly {
            let ptr := mload(0x40)
            let size := returndatasize()
            returndatacopy(ptr, 0, size)
            if iszero( successDGTCLL ) {
                revert(ptr, size)
            }
            propId := mload(ptr)
        }
    }

    /// @notice Generate a proposal from a user that want to join to the CLH
    /// @dev Only avaiable in public CLH
    /// @param _name Nickname or other user identification
    /// @param _description About the request
    /// @return propId ID of the new proposal, based on `arrProposals`
    function PropRequestToJoin(
        string memory _name,
        string memory _description
    )
        external
        returns( uint256 )
    {
        (bool successDGTCLL, bytes memory dataDLGTCLL) = CLCGovernance.delegatecall(
            abi.encodeWithSignature( 
                "PropRequestToJoin(string,string)", 
                _name,
                _description
            )
        );

        assembly {
            let ptr := mload(0x40)
            let size := returndatasize()
            returndatacopy(ptr, 0, size)
            if iszero( successDGTCLL ) {
                revert(ptr, size)
            }
            return(ptr, size)
        }
    }

    /// @notice For an user that have an invitation pending
    /// @dev 
    /// @param _acceptance True for accept the invitation
    function AcceptRejectInvitation(
        bool _acceptance
    )
        external
    {
        (bool successDGTCLL, bytes memory dataDLGTCLL) = CLCMemberManagement.delegatecall(
            abi.encodeWithSignature( 
                "AcceptRejectInvitation(bool)", 
                _acceptance
            )
        );

        if( !successDGTCLL ) {
            assembly {
                let ptr := mload(0x40)
                let size := returndatasize()
                returndatacopy(ptr, 0, size)
                revert(ptr, size)
            }
        }
    }

    function GetArrMembersLength() external view returns( uint256 ){
        return arrMembers.length;
    }

    function PropSwapERC20(
        address _tokenOutCLV,
        address _tokenInCLV,
        uint256 _amountOutCLV,
        string memory _description,
        uint256 _delayTime
    )
        // modIsManager( msg.sender )
        external
        returns( uint256 propId )
    {
        require( IERC20( _tokenOutCLV ).balanceOf( address( vaultCLH ) ) >= _amountOutCLV , "Insufficient Tokens!!" );
        
        uint256 idDataNewPropTxWei = arrDataPropTxAssets.length;
        arrDataPropTxAssets.push(
            strDataTxAssets({
                to: address(0),
                amountOutCLV: _amountOutCLV,
                tokenOutCLV: _tokenOutCLV,
                tokenInCLV: _tokenInCLV
            } )
        );

        propId = arrProposals.length;
        arrProposals.push( 
            strProposal( { 
                proponent: msg.sender,
                typeProposal: proposalType.swapERC20,
                description: _description,
                propDataId: idDataNewPropTxWei,
                numVotes: 0,
                againstVotes: 0,
                executed: false,
                rejected: false,
                deadline: block.timestamp + _delayTime
            } )
        );

        emit evtProposal( proposalEvent.addProposal, propId, proposalType.swapERC20, _description );

        // Auto vote
        VoteProposal( propId , true , _description );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "CLVault.sol";

/// @title Contract to store data of CLHouse (var stack)
/// @author Leonardo Urrego
/// @notice This contract is part of CLH
contract CLStorage {

	/**
     * ### CLH Public Variables ###
     */

    string public HOUSE_NAME; // TODO: immutable? https://gist.github.com/frangio/61497715c43b79e3e2d7bfab907b01c2#file-testshortstring-sol
    uint8 public numActiveMembers;
    uint8 public numManagerMembers;
    uint8 public govRuleApprovPercentage;
    uint8 public govRuleMaxActiveMembers;
    uint8 public  govRuleMaxManagerMembers; // immutable
    bool public housePrivate;
    address CLCMemberManagement;
    address CLCGovernance;
    bytes32 public HOUSE_GOVERNANCE_MODEL; // immutable
    CLVault public vaultCLH;
    mapping( address => uint256 ) public mapInvitationMember; // wallet => propId
    mapping( address => uint256 ) public mapIdMember;
    mapping( uint256 => mapping( address => strVote ) ) public mapVotes; // mapVotes[propId][wallet].strVote
    strProposal[] public arrProposals;
    strDataAddMember[] public arrDataPropAddMember;
    strDataTxAssets[] public arrDataPropTxAssets;
    strDataGovRules[] public arrDataPropGovRules;
    strMember[] public arrMembers;

    /**
     * ### Contract events ###
     */

    event evtProposal( proposalEvent eventProposal, uint256 propId, proposalType typeProposal, string description );
    event evtVoted( uint256 propId, bool position, address voter, string justification );
    event evtMember( memberEvent eventMember, address walletAddr, string name );
    event evtChangeGovRules( uint256 newApprovPercentage );
    event evtTxEth( assetsEvent typeEvent, address walletAddr, uint256 value, uint256 balance );
    event evtTxERC20( address walletAddr, uint256 value, address tokenAdd );
    event evtSwapERC20( address tokenOutCLV, uint256 amountOutCLV, address tokenInCLV, uint256 amountReceived );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "ICLHouse.sol";
import "ISwapRouter.sol";
import "TransferHelper.sol";

/// @title Contract to store a exec trancsaccions of CLHouses
/// @author Leonardo Urrego
/// @notice This contract is for test only the most basic interactions
contract CLVault {

	/**
     * ### CLV Private Variables ###
     */

    ISwapRouter internal constant swapRouterV3 = ISwapRouter( 0xE592427A0AEce92De3Edee1F18E0157C05861564 );
    address internal constant WETH = 0xc778417E063141139Fce010982780140Aa0cD5Ab; // rinkeby

	ICLHouse ownerCLH;

	/**
     * ### Contract events ###
     */

    event evtTxEth( assetsEvent typeEvent, address walletAddr, uint256 value, uint256 balance );
    event evtTxERC20( address walletAddr, uint256 value, address tokenAdd );
    event evtSwapERC20( address tokenOutCLV, uint256 amountOutCLV, address tokenInCLV, uint256 amountReceived );

    modifier modOnlyOwnerCLH( ) {
        require( address( ownerCLH ) == msg.sender , "Not a ownerCLH" );
        _;
    }

    fallback() external payable {
        emit evtTxEth( assetsEvent.receivedEth, msg.sender, msg.value, address(this).balance );
    }

    receive() external payable {
        emit evtTxEth( assetsEvent.receivedEth, msg.sender, msg.value, address(this).balance );
    }

    constructor( address _CLH ) payable {
    	ownerCLH = ICLHouse( _CLH );
    }

    function TxWei(
        address _walletAddr,
        uint256 _amountOutCLV
    )
        modOnlyOwnerCLH()
        external
    {
        require( address( this ).balance >= _amountOutCLV , "Insufficient funds!!" );
        ( bool success, ) = _walletAddr.call{ value: _amountOutCLV }( "" );
        require( success, "txWei failed" );

        // arrMembers[ mapIdMember[ msg.sender ] ].balance -= msg.value;  // TODO: safeMath?

        emit evtTxEth( assetsEvent.transferEth, _walletAddr, _amountOutCLV, address( this ).balance );
    }

    function TxERC20(
        address _walletAddr,
        uint256 _amountOutCLV,
        address _tokenOutCLV
    )
        modOnlyOwnerCLH()
        external
    {
        IERC20 token = IERC20( _tokenOutCLV );

        require( token.balanceOf( address( this ) ) >= _amountOutCLV , "Insufficient Tokens!!" );
        ( bool success ) = token.transfer({ to: _walletAddr, amount: _amountOutCLV });
        require( success, "TxERC20 failed" );

        emit evtTxERC20( _walletAddr, _amountOutCLV, _tokenOutCLV );
    }

    function swapERC20(
        address _tokenOutCLV,
        address _tokenInCLV,
        uint256 _amountOutCLV
    )
        modOnlyOwnerCLH()
        external
        returns (
            uint256 amountReceived
        )
    {
        require( IERC20( _tokenOutCLV ).balanceOf( address( this ) ) >= _amountOutCLV , "Insufficient Tokens!!" );

        TransferHelper.safeApprove( _tokenOutCLV , address( swapRouterV3 ) , _amountOutCLV );        

        amountReceived = swapRouterV3.exactInputSingle(
            ISwapRouter.ExactInputSingleParams( {
                tokenIn: _tokenOutCLV,
                tokenOut: _tokenInCLV,
                fee: 3000,
                recipient: address( this ),
                deadline: block.timestamp,
                amountIn: _amountOutCLV,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            } )
        );

        emit evtSwapERC20( _tokenOutCLV, _amountOutCLV, _tokenInCLV, amountReceived );
    }


    function swapEth2Tokens(
        address _tokenInCLV,
        uint256 _amountOutCLV
    )
        modOnlyOwnerCLH()
        external
        returns (
            uint256 amountReceived
        )
    {
        require( address( this ).balance >= _amountOutCLV , "Insufficient funds!!"  );

        TransferHelper.safeTransferETH( WETH , _amountOutCLV );

        TransferHelper.safeApprove( WETH , address( swapRouterV3 ) , _amountOutCLV );        

        amountReceived = swapRouterV3.exactInputSingle(
            ISwapRouter.ExactInputSingleParams( {
                tokenIn: WETH,
                tokenOut: _tokenInCLV,
                fee: 3000,
                recipient: address( this ),
                deadline: block.timestamp,
                amountIn: _amountOutCLV,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            } )
        );

        emit evtSwapERC20( address( 0 ), _amountOutCLV, _tokenInCLV, amountReceived );
    }

    function swapTokens2Eth(
        address _tokenOutCLV,
        uint256 _amountOutCLV
    )
        modOnlyOwnerCLH()
        external
        returns (
            uint256 amountReceived
        )
    {
        require( IERC20( _tokenOutCLV ).balanceOf( address( this ) ) >= _amountOutCLV , "Insufficient Tokens!!" );

        TransferHelper.safeApprove( _tokenOutCLV , address( swapRouterV3 ) , _amountOutCLV );        

        amountReceived = swapRouterV3.exactInputSingle(
            ISwapRouter.ExactInputSingleParams( {
                tokenIn: _tokenOutCLV,
                tokenOut: WETH,
                fee: 3000,
                recipient: address( this ),
                deadline: block.timestamp,
                amountIn: _amountOutCLV,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            } )
        );

        ( bool result , ) = WETH.call{value: 0}( abi.encodeWithSignature( "withdraw(uint256)" , amountReceived ) );
        require( result , "Withdraw ETH fail" );

        emit evtSwapERC20( _tokenOutCLV, _amountOutCLV, address( 0 ), amountReceived );
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "IERC20.sol";

bytes32 constant __GOV_DICTATORSHIP__ = keccak256("__GOV_DICTATORSHIP__");
bytes32 constant __GOV_COMMITTEE__ = keccak256("__GOV_COMMITTEE__");
bytes32 constant __GOV_SIMPLE_MAJORITY__ = keccak256("__GOV_SIMPLE_MAJORITY__");

error InvalidGovernanceType ( bytes32 ) ;
error DebugDLGTCLL( bool successDLGTCLL , bytes dataDLGTCLL );

/**
 * ### CLH Types ###
 */

enum memberEvent{
    addMember,
    delMember,
    inviteMember,
    acceptInvitation,
    rejectInvitation,
    requestJoin
}

enum assetsEvent {
    receivedEth,
    transferEth,
    transferERC20,
    swapERC20,
    buyERC20,
    sellERC20
}

enum proposalEvent {
    addProposal,
    execProposal,
    rejectProposal
}

enum proposalType {
    newMember,
    removeMember,
    requestJoin,
    changeGovRules,
    transferEth,
    transferERC20,
    swapERC20
}

struct strMember {
    address walletAddr;
    string name;
    uint256 balance;
    bool isMember;
    bool isManager;
}

struct strProposal {
    address proponent;
    proposalType typeProposal;
    string description;
    uint256 propDataId;
    uint8 numVotes;
    uint8 againstVotes;
    bool executed;
    bool rejected;
    uint256 deadline;
}

struct strVote {
    bool voted;
    bool inSupport;
    string justification;
}

struct strDataAddMember {
    address walletAddr;
    string name;
    bool isManager;
}

struct strDataTxAssets {
    address to;
    uint256 amountOutCLV;
    address tokenOutCLV;
    address tokenInCLV;
}

struct strDataGovRules {
    uint8 newApprovPercentage;
}

interface ICLHouse {

    // View fuctions
    function housePrivate() external view returns( bool );
    function HOUSE_NAME() external view returns( string memory );
    function HOUSE_GOVERNANCE_MODEL() external view returns( bytes32 );
    function numActiveMembers() external view returns( uint8 );
    function numManagerMembers() external view returns( uint8 );
    function govRuleApprovPercentage() external view returns( uint8 );
    function govRuleMaxActiveMembers() external view returns( uint8 );
    function govRuleMaxManagerMembers() external view returns( uint8 );
    function arrMembers( uint256 ) external view returns( address , string memory , uint256 , bool , bool );
    function arrProposals( uint256 ) external view returns( address , proposalType , string memory , uint16 , uint8 , uint8 , bool , bool , uint256 );
    function arrDataPropAddMember( uint256 ) external view returns( address , string memory , bool );
    function arrDataPropTxWei( uint256 ) external view returns( address , uint256 );
    function arrDataPropGovRules( uint256 ) external view returns( uint8 );
    function mapIdMember( address ) external view returns( uint256 );
    function mapInvitationMember( address ) external view returns( uint256 );
    function mapVotes( uint256 ,  address ) external view returns( bool , bool , string memory);
    function GetArrMembersLength() external view returns( uint256 );

    // no-view functions
    function ExecProp(
        uint _propId 
    )
        external 
        returns(
            bool status, 
            string memory message
        );

    function VoteProposal(
        uint _propId,
        bool _support,
        string memory _justification
    )
        external
        returns(
            bool status
        );

    function PropInviteMember(
        address _walletAddr,
        string memory _name,
        string memory _description,
        bool _isManager,
        uint256 _delayTime
    )
        external
        returns(
            uint propId
        );

    function PropRemoveMember(
        address _walletAddr,
        string memory _description,
        uint256 _delayTime
    )
        external
        returns(
            uint propId
        );

    function PropTxWei(
        address _to,
        uint _value,
        string memory _description,
        uint256 _delayTime
    )
        external
        returns(
            uint propId
        );

    function PropGovRules(
        uint8 _newApprovPercentage,
        string memory _description,
        uint256 _delayTime
    )
        external
        returns(
            uint propId
        );

    function PropRequestToJoin(
        string memory _name,
        string memory _description
    )
        external
        returns(
            uint propId
        );

    function AcceptRejectInvitation( bool __acceptance ) external;
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import "IUniswapV3SwapCallback.sol";

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

import "IERC20.sol";

library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');
    }

    /// @notice Approves the stipulated contract to spend the given allowance in the given token
    /// @dev Errors with 'SA' if transfer fails
    /// @param token The contract address of the token to be approved
    /// @param to The target of the approval
    /// @param value The amount of the given token the target will be allowed to spend
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SA');
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
    }
}