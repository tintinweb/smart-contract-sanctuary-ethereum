// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "ICLHouse.sol";
import "CLStorage.sol";

/// @title Contract to implement and test the basic fuctions of CLHouses
/// @author Leonardo Urrego
/// @notice This contract for test only the most basic interactions
contract CLHouse is CLStorage {

    /**
     * ### Contract events ###
     */

    event evtMember( eventType typeEvent, address walletAddr, string name );
    event evtTxEth( eventType typeEvent, address walletAddr, uint value, uint balance );
    event evtTxERC20( eventType typeEvent, address walletAddr, uint value, address tokenAdd );
    event evtChangeGovRules( uint newApprovPercentage );
    event evtProposal( eventType typeEvent, uint propId, eventType typeProposal, string description );
    event evtVoted( uint propId, bool position, address voter, string justification );

    /**
     * ### Function modifiers ###
     */

    modifier modNotMember( address _walletAddr ) {
        require( 0 == mapIdMember[ _walletAddr ] , "Member exist!!" );
        _;
    }

    modifier modIsMember( address _walletAddr ) {
        require( true == arrMembers[ mapIdMember[ _walletAddr ] ].isMember , "Member don't exist!!" );
        _;
    }

    modifier modIsManager( address _walletAddr ) {
        require( true == arrMembers[ mapIdMember[ _walletAddr ] ].isManager , "Not manager rights" );
        _;
    }

    modifier modCheckMaxMembers( ) {
        require( numActiveMembers < govRuleMaxActiveMembers, "No avaliable spots for new members");
        _;
    }

    modifier modCheckMaxManager( bool _isManager ) {
        if( _isManager )
            require( numManagerMembers < govRuleMaxManagerMembers, "No avaliable spots for manager members" );
        _;
    }

    modifier modCheckPendingInvitation( address _walletAddr ) {
        require( 0 == mapInvitationMember[ _walletAddr ], "User have a pending Invitation" );
        _;
    }

    modifier modValidApprovPercentage( uint _newApprovPercentage ) {
        require(
            _newApprovPercentage >= 0 &&
            _newApprovPercentage <= 100,
            "invalid number for percentage of Approval"
        );
        _;
    }

    modifier modPropExists( uint _propId ) {
        require( _propId < arrProposals.length , "Proposal does not exist" );
        _;
    }

    modifier modPropNotExecuted( uint _propId ) {
        require( false == arrProposals[ _propId ].executed , "Proposal already executed" );
        _;
    }

    modifier modPropNotRejected( uint _propId ) {
        require( false == arrProposals[ _propId ].rejected , "Proposal was rejected" );
        _;
    }

    modifier modUserHasNotVoted( uint _propId ) {
        require( !mapVotes[ _propId ][ msg.sender ].voted , "User have a vote registred for this proposal" );
        _;
    }

    modifier modCheckDeadline( uint _propId ) {
        require( block.timestamp < arrProposals[ _propId ].deadline , "Proposal deadline" );
        _;
    }

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
        address[] memory _ManagerWallets
    )
        payable
    {

        if( __GOV_DICTATORSHIP__ == _gov ){
            govRuleApprovPercentage = 100;
            govRuleMaxActiveMembers = _govRuleMaxActiveMembers;
            govRuleMaxManagerMembers = 1;
        }
        else if( __GOV_COMMITTEE__ == _gov ){
            govRuleApprovPercentage = _govRuleApprovPercentage;
            govRuleMaxActiveMembers = _govRuleMaxActiveMembers;
            govRuleMaxManagerMembers = _govRuleMaxManagerMembers;
        }
        else if( __GOV_SIMPLE_MAJORITY__ == _gov ){
            govRuleApprovPercentage = _govRuleApprovPercentage;
            govRuleMaxActiveMembers = _govRuleMaxActiveMembers;
            govRuleMaxManagerMembers = _govRuleMaxActiveMembers;
        }
        else
            revert InvalidGovernanceType( _gov );

        HOUSE_NAME = _houseName;
        HOUSE_GOVERNANCE_MODEL = _gov;
        housePrivate = _housePrivate;
        CLCMemberManagement = _CLCMemberManagement;
        CLCGovernance = _CLCGovernance;

        arrMembers.push( 
            strMember( {
                walletAddr: address(0),
                name: "",
                balance: 0,
                isMember: false,
                isManager: false
            } ) 
        );

        arrMembers.push( 
            strMember( {
                walletAddr: _owner,
                name: "Founder",
                balance: msg.value,
                isMember: true,
                isManager: true
            } ) 
        );
        
        mapIdMember[ _owner ] = 1;
        numActiveMembers = 1;
        numManagerMembers = 1;

        arrProposals.push( strProposal( {
                            proponent: _owner,
                            typeProposal: eventType.addMember,
                            description: "Founder",
                            propDataId: 0,
                            numVotes: 1,
                            againstVotes: 0,
                            executed: true,
                            rejected: false,
                            deadline: block.timestamp
                        } ) );

        mapVotes[ 0 ][ _owner ].inSupport = true;
        mapVotes[ 0 ][ _owner ].justification = "Founder";
        mapVotes[ 0 ][ _owner ].voted = true;

        if( 
            _ManagerWallets.length > 0
            &&
            ( __GOV_COMMITTEE__ == _gov || __GOV_SIMPLE_MAJORITY__ == _gov )
        ) {
            for( uint8 wid = 0 ; wid < _ManagerWallets.length ; wid++ ){
                if( address( 0 ) != _ManagerWallets[ wid ] ) {

                    (bool successDGTCLL, bytes memory dataDLGTCLL) = CLCMemberManagement.delegatecall(
                        abi.encodeWithSignature( 
                            "WhitelistAdd(address,address)",
                            _ManagerWallets[ wid ],
                            _owner
                        )
                    );

                    if( !successDGTCLL )
                        revert DebugDLGTCLL( successDGTCLL , dataDLGTCLL );
                }
            }
        }
    }

    receive() external payable {
        if( arrMembers[ mapIdMember[ msg.sender ] ].isMember )
            arrMembers[ mapIdMember[ msg.sender ] ].balance += msg.value;

        emit evtTxEth( eventType.depositEth, msg.sender, msg.value, address(this).balance );
    }

    function TxWei(
        address _walletAddr,
        uint _value
    )
        private
    {
        require( address( this ).balance >= _value , "Insufficient funds!!"  );
        ( bool success, ) = _walletAddr.call{ value: _value }( "" );
        require( success, "txWei failed" );

        arrMembers[ mapIdMember[ msg.sender ] ].balance -= msg.value;  // TODO: safeMath?

        emit evtTxEth( eventType.tranferEth, _walletAddr, _value, address( this ).balance );
    }

    function TxERC20(
        address _walletAddr,
        uint _value,
        address _tokenAdd
    )
        private
    {
        IERC20 token = IERC20( _tokenAdd );

        require( token.balanceOf( address( this ) ) >= _value , "Insufficient Tokens!!"  );
        ( bool success ) = token.transfer({ to: _walletAddr, amount: _value });
        require( success, "TxERC20 failed" );

        emit evtTxERC20( eventType.tranferERC20, _walletAddr, _value, _tokenAdd );
    }

    /// @notice Execute (or reject) a proposal computing the votes and the governance model
    /// @dev Normally is called internally after each vote
    /// @param _propId ID of the proposal, based on `arrProposals`
    /// @return status True if the proposal can be execute, false in other cases
    /// @return message result of the transaction
    function ExecProp(
        uint _propId
    )
        modPropExists( _propId )
        modPropNotExecuted( _propId )
        modPropNotRejected ( _propId )
        modCheckDeadline( _propId )
        modIsManager( msg.sender )
        public
        returns(
            bool status,
            string memory message
        )
    {
        uint16 percent = arrProposals[ _propId ].againstVotes * 100 / numManagerMembers;

        if( percent > govRuleApprovPercentage ) {
            arrProposals[ _propId ].rejected = true;
            // TODO: generate a rejected event
            return ( false , "Proposal has been rejected" );
        }

        percent = arrProposals[ _propId ].numVotes - arrProposals[ _propId ].againstVotes;
        percent = percent * 100 / numManagerMembers;

        if(  percent < govRuleApprovPercentage )
            return ( false , "No approval percentage reached" );

        eventType typeProposal = arrProposals[ _propId ].typeProposal;
        uint16 propDataId = arrProposals[ _propId ].propDataId;

        if( eventType.addMember == typeProposal ) {
            mapInvitationMember[ arrDataPropAddMember[ propDataId ].walletAddr ] = _propId;
            arrProposals[ _propId ].deadline = block.timestamp + 1 weeks;
        } else if( eventType.delMember == typeProposal ) {
            (bool successDGTCLL, bytes memory dataDLGTCLL) = CLCMemberManagement.delegatecall(
                abi.encodeWithSignature( 
                    "DelMember(address)", 
                    arrDataPropAddMember[ propDataId ].walletAddr
                )
            );

            if( !successDGTCLL )
                revert DebugDLGTCLL( successDGTCLL , dataDLGTCLL );
        } else if( eventType.tranferEth == typeProposal ) {
            TxWei(arrDataPropTxAssets[ propDataId ].to, arrDataPropTxAssets[ propDataId ].value );
        } else if( eventType.tranferERC20 == typeProposal ) {
            TxERC20(
                arrDataPropTxAssets[ propDataId ].to,
                arrDataPropTxAssets[ propDataId ].value,
                arrDataPropTxAssets[ propDataId ].tokenAdd
            );
        } else if( eventType.changeGovRules == typeProposal ) {
            (bool successDGTCLL, bytes memory dataDLGTCLL) = CLCGovernance.delegatecall(
                abi.encodeWithSignature( 
                    "ChangeGovRules(uint8)", 
                    arrDataPropGovRules[ propDataId ].newApprovPercentage
                )
            );

            if( !successDGTCLL )
                revert DebugDLGTCLL( successDGTCLL , dataDLGTCLL );
        } else if( eventType.requestJoin == typeProposal ) {
            (bool successDGTCLL, bytes memory dataDLGTCLL) = CLCMemberManagement.delegatecall(
                abi.encodeWithSignature( 
                    "AddMember(address,string,bool)", 
                    arrDataPropAddMember[ propDataId ].walletAddr,
                    arrDataPropAddMember[ propDataId ].name,
                    arrDataPropAddMember[ propDataId ].isManager
                )
            );

            if( !successDGTCLL )
                revert DebugDLGTCLL( successDGTCLL , dataDLGTCLL );
        } else {
            revert("Proposal error");
        }

        arrProposals[ _propId ].executed = true;

        emit evtProposal( eventType.execProposal, _propId, arrProposals[ _propId ].typeProposal, arrProposals[ _propId ].description );

        return ( true , "Success executed proposal" );
    }

    /// @notice Used to vote a proposal
    /// @dev After vote the proposal automatically try to be executed
    /// @param _propId ID of the proposal, based on `arrProposals`
    /// @param _support True for accept, false to reject
    /// @param _justification About your vote
    /// @return true is the vote can be stored
    function VoteProposal(
        uint _propId,
        bool _support,
        string memory _justification
    )
        modIsManager( msg.sender )
        modPropExists( _propId )
        modPropNotExecuted( _propId )
        modPropNotRejected ( _propId )
        modUserHasNotVoted( _propId )
        modCheckDeadline( _propId )
        public
        returns( bool )
    {
        mapVotes[ _propId ][ msg.sender ].inSupport = _support;
        mapVotes[ _propId ][ msg.sender ].justification = _justification;
        mapVotes[ _propId ][ msg.sender ].voted = true;

        arrProposals[ _propId ].numVotes++;

        if( !_support )
            arrProposals[ _propId ].againstVotes++;

        emit evtVoted( _propId,  _support, msg.sender, _justification );

        // auto exec
        ExecProp( _propId );

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
        modIsManager( msg.sender )
        modNotMember( _walletAddr )
        modCheckMaxMembers()
        modCheckMaxManager( _isManager )
        modCheckPendingInvitation( _walletAddr )
        external
        returns( uint )
    {
        uint propId = arrProposals.length;

        (bool successDGTCLL, bytes memory dataDLGTCLL) = CLCMemberManagement.delegatecall(
            abi.encodeWithSignature( 
                "PropInviteMember(address,string,string,bool,uint256)", 
                _walletAddr,
                _name,
                _description,
                _isManager,
                _delayTime
            )
        );

        if( !successDGTCLL )
            revert DebugDLGTCLL( successDGTCLL , dataDLGTCLL );

        // Auto vote
        VoteProposal( propId , true , _description );
        
        return propId;
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
        modIsManager( msg.sender )
        modIsMember( _walletAddr )
        external
        returns( uint )
    {
        uint propId = arrProposals.length;

        (bool successDGTCLL, bytes memory dataDLGTCLL) = CLCMemberManagement.delegatecall(
            abi.encodeWithSignature( 
                "PropRemoveMember(address,string,uint256)", 
                _walletAddr,
                _description,
                _delayTime
            )
        );

        if( !successDGTCLL )
            revert DebugDLGTCLL( successDGTCLL , dataDLGTCLL );

        // Auto vote
        VoteProposal( propId , true , _description );

        return propId;
    }

    /// @notice generate a new proposal to transfer ETH in weis
    /// @dev When execute this proposal, the transfer is made
    /// @param _to Recipient address
    /// @param _value Amount to transfer (in wei)
    /// @param _description About this proposal
    /// @return propId ID of the new proposal, based on `arrProposals`
    function PropTxWei(
        address _to,
        uint _value,
        string memory _description,
        uint256 _delayTime
    )
        modIsManager( msg.sender )
        external
        returns( uint )
    {
        uint16 idDataNewPropTxWei = uint16( arrDataPropTxAssets.length );
        arrDataPropTxAssets.push(
            strDataTxAssets({
                to: _to,
                value: _value,
                tokenAdd: address(0)
            } )
        );

        uint propId = arrProposals.length;
        arrProposals.push( 
            strProposal( { 
                proponent: msg.sender,
                typeProposal: eventType.tranferEth,
                description: _description,
                propDataId: idDataNewPropTxWei,
                numVotes: 0,
                againstVotes: 0,
                executed: false,
                rejected: false,
                deadline: block.timestamp + _delayTime
            } )
        );

        // Auto vote
        VoteProposal( propId , true , _description );

        emit evtProposal( eventType.addProposal, propId, eventType.tranferEth, _description );
        return propId;
    }

    /// @notice generate a new proposal to transfer ETH in weis
    /// @dev When execute this proposal, the transfer is made
    /// @param _to Recipient address
    /// @param _value Amount to transfer (in wei)
    /// @param _description About this proposal
    /// @return propId ID of the new proposal, based on `arrProposals`
    function PropTxERC20(
        address _to,
        uint _value,
        address _tokenAdd,
        string memory _description,
        uint256 _delayTime
    )
        modIsManager( msg.sender )
        external
        returns( uint )
    {
        uint16 idDataNewPropTxWei = uint16( arrDataPropTxAssets.length );
        arrDataPropTxAssets.push(
            strDataTxAssets({
                to: _to,
                value: _value,
                tokenAdd: _tokenAdd
            } )
        );

        uint propId = arrProposals.length;
        arrProposals.push( 
            strProposal( { 
                proponent: msg.sender,
                typeProposal: eventType.tranferERC20,
                description: _description,
                propDataId: idDataNewPropTxWei,
                numVotes: 0,
                againstVotes: 0,
                executed: false,
                rejected: false,
                deadline: block.timestamp + _delayTime
            } )
        );

        // Auto vote
        VoteProposal( propId , true , _description );

        emit evtProposal( eventType.addProposal, propId, eventType.tranferERC20, _description );
        return propId;
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
        modIsManager( msg.sender )
        modValidApprovPercentage( _newApprovPercentage )
        external
        returns( uint )
    {
        uint propId = arrProposals.length;

        (bool successDGTCLL, bytes memory dataDLGTCLL) = CLCGovernance.delegatecall(
            abi.encodeWithSignature( 
                "PropGovRules(uint8,string,uint256)", 
                _newApprovPercentage,
                _description,
                _delayTime
            )
        );

        if( !successDGTCLL )
            revert DebugDLGTCLL( successDGTCLL , dataDLGTCLL );
        
        // Auto vote
        VoteProposal( propId , true , _description );

        return propId;
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
        modNotMember( msg.sender )
        modCheckMaxMembers()
        modCheckPendingInvitation( msg.sender )
        external
        returns( uint )
    {
        require( false == housePrivate, "Request to Join isn't available" );

        uint16 idDataNewMember = uint16( arrDataPropAddMember.length );
        arrDataPropAddMember.push(
            strDataAddMember( {
                walletAddr:msg.sender,
                name: _name,
                isManager: false
            } )
        );

        uint propId = arrProposals.length;
        arrProposals.push(
            strProposal( {
                proponent: msg.sender,
                typeProposal: eventType.requestJoin,
                description: _description,
                propDataId: idDataNewMember,
                numVotes: 0,
                againstVotes: 0,
                executed: false,
                rejected: false,
                deadline: block.timestamp + 1 weeks
            } )
        );

        emit evtProposal( eventType.addProposal, propId, eventType.requestJoin, _description );

        return propId;
    }

    /// @notice For an user that have an invitation pending
    /// @dev 
    /// @param _acceptance True for accept the invitation
    function AcceptRejectInvitation(
        bool _acceptance
    )
        external
    {
        uint propId = mapInvitationMember[ msg.sender ];
        require( 0 != propId, "You Don't have a pending invitation" );
        require( block.timestamp < arrProposals[ propId ].deadline , "Invitation deadline" );

        uint16 propDataId = arrProposals[ propId ].propDataId;
        // require( msg.sender == arrDataPropAddMember[ propDataId ].walletAddr, "Only the invitee can accept/reject" );

        if ( _acceptance ) {
            (bool successDGTCLL, bytes memory dataDLGTCLL) = CLCMemberManagement.delegatecall(
                abi.encodeWithSignature( 
                    "AddMember(address,string,bool)", 
                    arrDataPropAddMember[ propDataId ].walletAddr,
                    arrDataPropAddMember[ propDataId ].name,
                    arrDataPropAddMember[ propDataId ].isManager
                )
            );

            if( successDGTCLL )
                emit evtProposal( eventType.acceptInvitation, propId, arrProposals[ propId ].typeProposal, arrProposals[ propId ].description );
            else
                revert DebugDLGTCLL( successDGTCLL , dataDLGTCLL );
        } else {
            emit evtProposal( eventType.rejectInvitation, propId, arrProposals[ propId ].typeProposal, arrProposals[ propId ].description );
        }

        delete mapInvitationMember[ arrDataPropAddMember[ propDataId ].walletAddr ];
    }

    function GetArrMembersLength() external view returns( uint256 ){
        return arrMembers.length;
    }


    function swapERC20(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn
    )
        modIsManager( msg.sender )
        external
        returns (
            uint256 amountOut
        )
    {
        require( IERC20( _tokenIn ).balanceOf( address( this ) ) >= _amountIn , "Insufficient Tokens!!" );

        TransferHelper.safeApprove( _tokenIn , address( swapRouterV3 ) , _amountIn );        

        return swapRouterV3.exactInputSingle(
            ISwapRouter.ExactInputSingleParams( {
                tokenIn: _tokenIn,
                tokenOut: _tokenOut,
                fee: 3000,
                recipient: address( this ),
                deadline: block.timestamp,
                amountIn: _amountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            } )
        );
    }


    function swapEth2Tokens(
        address _tokenOut,
        uint256 _amountIn
    )
        modIsManager( msg.sender )
        external
        returns (
            uint256 amountOut
        )
    {
        require( address( this ).balance >= _amountIn , "Insufficient funds!!"  );

        TransferHelper.safeTransferETH( WETH , _amountIn );

        TransferHelper.safeApprove( WETH , address( swapRouterV3 ) , _amountIn );        

        return swapRouterV3.exactInputSingle(
            ISwapRouter.ExactInputSingleParams( {
                tokenIn: WETH,
                tokenOut: _tokenOut,
                fee: 3000,
                recipient: address( this ),
                deadline: block.timestamp,
                amountIn: _amountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            } )
        );
    }

    function swapTokens2Eth(
        address _tokenIn,
        uint256 _amountIn
    )
        modIsManager( msg.sender )
        external
        returns (
            uint256 amountOut
        )
    {
        require( IERC20( _tokenIn ).balanceOf( address( this ) ) >= _amountIn , "Insufficient Tokens!!" );

        TransferHelper.safeApprove( _tokenIn , address( swapRouterV3 ) , _amountIn );        

        amountOut = swapRouterV3.exactInputSingle(
            ISwapRouter.ExactInputSingleParams( {
                tokenIn: _tokenIn,
                tokenOut: WETH,
                fee: 3000,
                recipient: address( this ),
                deadline: block.timestamp,
                amountIn: _amountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            } )
        );

        // ( bool result , ) = WETH.call{value: 0}( abi.encodeWithSignature( "withdraw(uint256)" , amountOut) );
        // require( result , "Withdraw ETH fail" );
        return amountOut;
    }
    
    function withdrawWETH(
        uint256 _amountIn
    )
        public
        returns (
            uint256 amountOut
        )
    {
        require( IERC20( WETH ).balanceOf( address( this ) ) >= _amountIn , "Insufficient WETH Tokens!!" );

        ( bool result , ) = WETH.call{value: 0}( abi.encodeWithSignature( "withdraw(uint256)" , _amountIn) );
        require( result , "Withdraw ETH fail" );
        return amountOut;
    }   
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

// import "IERC20.sol";
import "ISwapRouter.sol";
import "TransferHelper.sol";


bytes32 constant __GOV_DICTATORSHIP__ = keccak256("__GOV_DICTATORSHIP__");
bytes32 constant __GOV_COMMITTEE__ = keccak256("__GOV_COMMITTEE__");
bytes32 constant __GOV_SIMPLE_MAJORITY__ = keccak256("__GOV_SIMPLE_MAJORITY__");

error InvalidGovernanceType ( bytes32 ) ;
error DebugDLGTCLL( bool successDLGTCLL , bytes dataDLGTCLL );

/**
 * ### CLH Types ###
 */

enum eventType {
    houseCreation,
    addMember,
    delMember,
    inviteMember,
    requestJoin,
    acceptInvitation,
    rejectInvitation,
    addProposal,
    execProposal,
    changeGovRules,
    depositEth,
    tranferEth,
    tranferERC20
    // buyERC20
    // sellERC20
    // buyNFT
    // sellNFT
}

struct strMember {
    address walletAddr;
    string name;
    uint balance;
    bool isMember;
    bool isManager;
}

struct strProposal {
    address proponent;
    eventType typeProposal;
    string description;
    uint16 propDataId;
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
    uint value;
    address tokenAdd;
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
    function arrProposals( uint256 ) external view returns( address , eventType , string memory , uint16 , uint8 , uint8 , bool , bool , uint256 );
    function arrDataPropAddMember( uint256 ) external view returns( address , string memory , bool );
    function arrDataPropTxWei( uint256 ) external view returns( address , uint );
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "ICLHouse.sol";

contract CLStorage {

	/**
     * ### CLH Public Variables ###
     */

    string public HOUSE_NAME; // TODO: immutable? https://gist.github.com/frangio/61497715c43b79e3e2d7bfab907b01c2#file-testshortstring-sol
    bytes32 public HOUSE_GOVERNANCE_MODEL; // immutable
    bool public housePrivate;
    uint8 public numActiveMembers;
    uint8 public numManagerMembers;
    uint8 public govRuleApprovPercentage;
    uint8 public govRuleMaxActiveMembers;
    uint8 public  govRuleMaxManagerMembers; // immutable
    strProposal[] public arrProposals;
    strDataAddMember[] public arrDataPropAddMember;
    strDataTxAssets[] public arrDataPropTxAssets;
    strDataGovRules[] public arrDataPropGovRules;
    mapping( address => uint ) public mapInvitationMember; // wallet => propId
    mapping( address => uint ) public mapIdMember;
    strMember[] public arrMembers;
    mapping( uint => mapping( address => strVote ) ) public mapVotes; // mapVotes[propId][wallet].strVote
    address CLCMemberManagement;
    address CLCGovernance;


    /**
     * ### CLH Private Variables ###
     */

    ISwapRouter internal constant swapRouterV3 = ISwapRouter( 0xE592427A0AEce92De3Edee1F18E0157C05861564 );
    address internal constant WETH = 0xc778417E063141139Fce010982780140Aa0cD5Ab; // rinkeby

}