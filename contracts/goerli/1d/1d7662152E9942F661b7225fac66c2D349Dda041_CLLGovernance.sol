// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "CLStorage.sol";

/// @title Contract to implement basic fuctions for governancce functions of CLHouses to will called with delegatecall
/// @author Leonardo Urrego
/// @notice This contract for test only the most basic interactions
contract CLLGovernance is CLStorage {
    
    /**
     * ### Function modifiers ###
     */
    
    modifier modIsUser( address _walletAddr ) {
        require( true == arrUsers[ mapIdUser[ _walletAddr ] ].isUser , "User don't exist!!" );
        _;
    }

    modifier modCheckMaxUsers( ) {
        require( numUsers < govRuleMaxUsers, "No avaliable spots for new users");
        _;
    }

    modifier modCheckMaxManager( bool _isManager ) {
        if( _isManager )
            require( numManagers < govRuleMaxManagers, "No avaliable spots for managers" );
        _;
    }

    modifier modValidApprovPercentage( uint256 _newApprovPercentage ) {
        require(
            _newApprovPercentage >= 0 &&
            _newApprovPercentage <= 100,
            "invalid number for percentage of Approval"
        );
        _;
    }

    function CheckPropExists( uint256 _propId ) internal view {
        require( _propId < arrProposals.length , "Proposal does not exist" );
    }

    function CheckPropNotExecuted( uint256 _propId ) internal view {
        require( false == arrProposals[ _propId ].executed , "Proposal already executed" );
    }

    function CheckPropNotRejected( uint256 _propId ) internal view {
        require( false == arrProposals[ _propId ].rejected , "Proposal was rejected" );
    }

    function CheckDeadline( uint256 _propId ) internal view {
        require( block.timestamp < arrProposals[ _propId ].deadline , "Proposal deadline" );
    }

    function CheckIsManager( address _walletAddr ) internal view {
        require( true == arrUsers[ mapIdUser[ _walletAddr ] ].isManager , "Not manager rights" );
    }

    function CheckNotUser( address _walletAddr ) internal view {
        require( 0 == mapIdUser[ _walletAddr ] , "User exist!!" );
    }

    function CheckNotPendingInvitation( address _walletAddr ) internal view {
        uint256 propId = mapInvitationUser[ _walletAddr ];
        if( propId > 0 && nftInvitation.balanceOf( _walletAddr ) > 0 )
            require( block.timestamp > arrProposals[ propId ].deadline , "User have a pending Invitation" );
    }

    function CheckNotPendingReq2Join( address _walletAddr ) internal view {
        uint256 propId = mapReq2Join[ _walletAddr ];
        if(
            propId > 0 &&
            false == arrProposals[ propId ].executed &&
            false == arrProposals[ propId ].rejected &&
            block.timestamp < arrProposals[ propId ].deadline
        )
            revert( "User have a pending request to Join" );
    }


    function ChangeGovRules(
        uint256 _govRuleApprovPercentage
    )
        internal
    {
        govRuleApprovPercentage = _govRuleApprovPercentage;

        emit evtChangeGovRules( _govRuleApprovPercentage );
    }

    /// @notice Internal Core function that validate governance and exec/reject a proposal
    /// @param _propId ID of the proposal, based on `arrProposals`
    /// @dev Is called internally after each vote and external ExecProp, validations will be done before call
    function __ValidateGovAndExec__(
        uint256 _propId
    )
        internal
        returns(
            bool status,
            string memory message
        )
    {
        uint256 percent = arrProposals[ _propId ].againstVotes * 100 / numManagers;

        if( percent >= govRuleApprovPercentage ) {
            arrProposals[ _propId ].rejected = true;
            emit evtProposal( proposalEvent.rejectProposal, _propId, arrProposals[ _propId ].typeProposal, arrProposals[ _propId ].description );
            return ( false , "Proposal has been rejected" );
        }

        percent = arrProposals[ _propId ].numVotes - arrProposals[ _propId ].againstVotes;
        percent = percent * 100 / numManagers;

        if(  percent < govRuleApprovPercentage )
            return ( false , "No approval percentage reached" );

        __Exec__( _propId );
    }

    /// @notice Internal Core function that exec proposal without validations
    /// @param _propId ID of the proposal, based on `arrProposals`
    /// @dev Is called internally to exec a Prop, validations will be done before call
    function __Exec__(
        uint256 _propId
    )
        internal
        returns(
            bool status,
            string memory message
        )
    {
        proposalType typeProposal = arrProposals[ _propId ].typeProposal;
        uint256 propDataId = arrProposals[ _propId ].propDataId;

        if( proposalType.newUser == typeProposal ) {
            address CLLUserManagement = CCLFACTORY.CLLUserManagement();
            (bool successDGTCLL, bytes memory dataDLGTCLL) = CLLUserManagement.delegatecall(
                abi.encodeWithSignature(
                    "InviteUser(uint256)",
                    _propId
                )
            );

            if( !successDGTCLL )
                revert DebugDLGTCLL( successDGTCLL , dataDLGTCLL );

        } else if( proposalType.removeUser == typeProposal ) {
            address CLLUserManagement = CCLFACTORY.CLLUserManagement();
            (bool successDGTCLL, bytes memory dataDLGTCLL) = CLLUserManagement.delegatecall(
                abi.encodeWithSignature(
                    "DelUser(address)",
                    arrDataPropUser[ propDataId ].walletAddr
                )
            );

            if( !successDGTCLL )
                revert DebugDLGTCLL( successDGTCLL , dataDLGTCLL );
        } else if( proposalType.transferEth == typeProposal ) {
            vaultCLH.TxWei(arrDataPropTxAssets[ propDataId ].to, arrDataPropTxAssets[ propDataId ].amountOutCLV );
        } else if( proposalType.transferERC20 == typeProposal ) {
            vaultCLH.TxERC20(
                arrDataPropTxAssets[ propDataId ].to,
                arrDataPropTxAssets[ propDataId ].amountOutCLV,
                arrDataPropTxAssets[ propDataId ].tokenOutCLV
            );
        } else if( proposalType.swapERC20 == typeProposal ) {
            vaultCLH.swapERC20(
                arrDataPropTxAssets[ propDataId ].tokenOutCLV,
                arrDataPropTxAssets[ propDataId ].tokenInCLV,
                arrDataPropTxAssets[ propDataId ].amountOutCLV
            );
        } else if( proposalType.sellERC20 == typeProposal ) {
            vaultCLH.swapTokens2Eth(
                arrDataPropTxAssets[ propDataId ].tokenOutCLV,
                arrDataPropTxAssets[ propDataId ].amountOutCLV
            );
        } else if( proposalType.buyERC20 == typeProposal ) {
            vaultCLH.swapEth2Tokens(
                arrDataPropTxAssets[ propDataId ].tokenInCLV,
                arrDataPropTxAssets[ propDataId ].amountOutCLV
            );
        } else if( proposalType.changeGovRules == typeProposal ) {
            ChangeGovRules( arrDataPropGovRules[ propDataId ].newApprovPercentage );
        } else if( proposalType.requestJoin == typeProposal ) {
            address CLLUserManagement = CCLFACTORY.CLLUserManagement();
            (bool successDGTCLL, bytes memory dataDLGTCLL) = CLLUserManagement.delegatecall(
                abi.encodeWithSignature(
                    "AddUser(address,string,bool)",
                    arrDataPropUser[ propDataId ].walletAddr,
                    arrDataPropUser[ propDataId ].name,
                    arrDataPropUser[ propDataId ].isManager
                )
            );

            if( !successDGTCLL )
                revert DebugDLGTCLL( successDGTCLL , dataDLGTCLL );
            
            delete mapReq2Join[ arrDataPropUser[ propDataId ].walletAddr ];
        } else {
            revert("Proposal error");
        }

        arrProposals[ _propId ].executed = true;

        emit evtProposal( proposalEvent.execProposal, _propId, arrProposals[ _propId ].typeProposal, arrProposals[ _propId ].description );

        return ( true , "Success executed proposal" );
    }

    /// @notice Execute (or reject) a proposal computing the votes and the governance model
    /// @param _propId ID of the proposal, based on `arrProposals`
    /// @return status True if the proposal can be execute, false in other cases
    /// @return message result of the transaction
    //@dev Is designed to be called externally
    function ExecProp(
        uint256 _propId
    )
        external
        returns(
            bool status,
            string memory message
        )
    {
        CheckPropExists( _propId );
        CheckPropNotExecuted( _propId );
        CheckPropNotRejected ( _propId );
        CheckDeadline( _propId );
        CheckIsManager( msg.sender );
        
        ( status, message ) = __ValidateGovAndExec__( _propId );
    }

    /// @dev Doesn't validate manager rights, prior validations is required, to be used internally
    function __Vote__(
        address _voterWallet,
        uint256 _propId,
        bool _support,
        string memory _justification
    ) 
        internal
    {
        mapVotes[ _propId ][ _voterWallet ].inSupport = _support;
        mapVotes[ _propId ][ _voterWallet ].justification = _justification;
        mapVotes[ _propId ][ _voterWallet ].voted = true;

        arrProposals[ _propId ].numVotes++;
        
        if( !_support )
        arrProposals[ _propId ].againstVotes++;
        
        emit evtVoted( _propId,  _support, _voterWallet, _justification );
        
        // auto exec
        __ValidateGovAndExec__( _propId );
    }
        
    function VoteProposal(
        uint256 _propId,
        bool _support,
        string memory _justification,
        bytes memory _signature
    )
        external
    {
        CheckPropExists( _propId );
        CheckPropNotExecuted( _propId );
        CheckPropNotRejected ( _propId );
        CheckDeadline( _propId );

        address realSender = msg.sender;

        if( _signature.length == 65 ) {
            
            realSender = CLHouseApi( CLHAPI ).SignerOCVote(
                _propId,
                _support,
                _justification,
                address(this),
                _signature
            );

            require( address(0) != realSender, "VoteProposal: ECDSA - invalid signature" );     // TODO: to function
        }

        CheckIsManager( realSender );

        require( !mapVotes[ _propId ][ realSender ].voted , "User have a vote registred for this proposal" );
        
        __Vote__(
            realSender,
            _propId,
            _support,
            _justification
        );
    }

    /// @notice Generate a new proposal for change some governance parameters
    /// @dev When execute this proposal the new values will be set
    /// @param _newApprovPercentage The new percentaje for accept or reject a proposal
    /// @param _description About the new proposal 
    /// @return propId ID of the new proposal, based on `arrProposals`
    function PropGovRules(
        uint256 _newApprovPercentage,
        string memory _description,
        uint256 _delayTime
    )
        modValidApprovPercentage( _newApprovPercentage )
        external
        returns( uint256 )
    {
        CheckIsManager( msg.sender );

        uint256 idDataNewPropGovRules = arrDataPropGovRules.length;
        arrDataPropGovRules.push(
            strDataGovRules({
                newApprovPercentage: _newApprovPercentage
            } )
        );

        uint256 propId = arrProposals.length;
        arrProposals.push( 
            strProposal( { 
                proponent: msg.sender,
                typeProposal: proposalType.changeGovRules,
                description: _description,
                propDataId: idDataNewPropGovRules,
                numVotes: 0,
                againstVotes: 0,
                executed: false,
                rejected: false,
                deadline: block.timestamp + _delayTime
            } )
        );

        emit evtProposal( proposalEvent.addProposal, propId, proposalType.changeGovRules, _description );
        
        // Auto vote
        __Vote__( msg.sender, propId , true , _description );

        return propId;
    }

    /// @notice Generate a proposal from a user that want to join to the CLH
    /// @dev Only avaiable in public CLH
    /// @param _name Nickname or other user identification
    /// @param _description About the request
    /// @return propId ID of the new proposal, based on `arrProposals`
    function PropRequestToJoin(
        string memory _name,
        string memory _description,
        bytes memory _signature
    )
        modCheckMaxUsers()
        external
        returns( uint256 )
    {
        address realSender = msg.sender;

        if( _signature.length == 65 ) {
            
            realSender = CLHouseApi( CLHAPI ).SignerOCRequest(
                _name,
                _description,
                address(this),
                _signature
            );

            require( address(0) != realSender, "PropRequestToJoin: ECDSA - invalid signature" );
        }

        CheckNotUser( realSender );
        CheckNotPendingInvitation( realSender );
        CheckNotPendingReq2Join( realSender );

        require(
            false == housePrivate,
            "Private House"
        );

        uint256 idDataNewUser = arrDataPropUser.length;
        arrDataPropUser.push(
            strDataUser( {
                walletAddr:realSender,
                name: _name,
                isManager: false
            } )
        );

        uint256 propId = arrProposals.length;
        arrProposals.push(
            strProposal( {
                proponent: realSender,
                typeProposal: proposalType.requestJoin,
                description: _description,
                propDataId: idDataNewUser,
                numVotes: 0,
                againstVotes: 0,
                executed: false,
                rejected: false,
                deadline: block.timestamp + 1 weeks
            } )
        );

        mapReq2Join[ realSender ] = propId;

        emit evtProposal( proposalEvent.addProposal, propId, proposalType.requestJoin, _description );

        if( true == houseOpen )
            __Exec__( propId );

        return propId;
    }

    /// @notice Generate a new proposal to invite a new user
    /// @dev the execution of this proposal only create an invitation 
    /// @param _walletAddr  Address of the new user
    /// @param _name Can be the nickname or other reference to the User
    /// @param _description A text for the proposal
    /// @param _isManager True if is for a manager user
    /// @return propId ID of the new proposal, based on `arrProposals`
    function PropInviteUser(
        address _walletAddr,
        string memory _name,
        string memory _description,
        bool _isManager,
        uint256 _delayTime,
        bytes memory _signature
    )
        modCheckMaxUsers()
        modCheckMaxManager( _isManager ) // TODO: to function
        external
        returns( uint256 )
    {
        CheckNotUser( _walletAddr );
        CheckNotPendingInvitation( _walletAddr );
        
        address realSender = msg.sender;

        if( _signature.length == 65 ) {
            
            realSender = CLHouseApi( CLHAPI ).SignerOCNewUser(
                _walletAddr,
                _name,
                _description,
                _isManager,
                _delayTime,
                address(this),
                _signature
            );

            require( address(0) != realSender, "PropInviteUser: ECDSA - invalid signature" );
        }

        CheckIsManager( realSender );

        if( !_isManager && __GOV_SIMPLE_MAJORITY__ == HOUSE_GOVERNANCE_MODEL )
            _isManager = true;

        uint256 idDataNewUser = arrDataPropUser.length;
        arrDataPropUser.push(
            strDataUser( {
                walletAddr:_walletAddr,
                name: string(_name),
                isManager: _isManager
            } )
        );

        uint256 propId = arrProposals.length;
        arrProposals.push(
            strProposal( {
                proponent: realSender,
                typeProposal: proposalType.newUser,
                description: string(_description),
                propDataId: idDataNewUser,
                numVotes: 0,
                againstVotes: 0,
                executed: false,
                rejected: false,
                deadline: block.timestamp + _delayTime
            } )
        );

        emit evtProposal( proposalEvent.addProposal, propId, proposalType.newUser, _description );

        // Auto vote
        __Vote__( realSender, propId , true , _description );

        return propId;
    }

    /// @notice Generate a new proposal for remove an user
    /// @dev The user can be a manager
    /// @param _walletAddr user Address to be removed
    /// @param _description About the proposal
    /// @return propId ID of the new proposal, based on `arrProposals`
    function PropRemoveUser(
        address _walletAddr,
        string memory _description,
        uint256 _delayTime,
        bytes memory _signature
    )
        modIsUser( _walletAddr )
        external
        returns( uint256 )
    {
        address realSender = msg.sender;

        if( _signature.length == 65 ) {
            realSender = CLHouseApi( CLHAPI ).SignerOCDelUser(
                _walletAddr,
                _description,
                _delayTime,
                address(this),
                _signature
            );

            require( address(0) != realSender, "PropRemoveUser: ECDSA - invalid signature" );
        }
        
        CheckIsManager( realSender );

        uint256 idDataNewUser = arrDataPropUser.length;
        arrDataPropUser.push(
            strDataUser( {
                walletAddr:_walletAddr,
                name: "",
                isManager: false
            } )
        );

        uint256 propId = arrProposals.length;
        arrProposals.push( 
            strProposal( { 
                proponent: realSender,
                typeProposal: proposalType.removeUser,
                description: _description,
                propDataId: idDataNewUser,
                numVotes: 0,
                againstVotes: 0,
                executed: false,
                rejected: false,
                deadline: block.timestamp + _delayTime
            } )
        );
        
        emit evtProposal( proposalEvent.addProposal, propId, proposalType.removeUser, _description );

        // Auto vote
        __Vote__( realSender, propId , true , _description );

        return propId;
    }

    function PropTxWei(
        address _to,
        uint256 _amountOutCLV,
        string memory _description,
        uint256 _delayTime
    )
        external
        returns( uint256 )
    {
        CheckIsManager( msg.sender );

        uint256 idDataNewPropTxWei = arrDataPropTxAssets.length;
        arrDataPropTxAssets.push(
            strDataTxAssets({
                to: _to,
                amountOutCLV: _amountOutCLV,
                tokenOutCLV: address(0),
                tokenInCLV: address(0)
            } )
        );

        uint256 propId = arrProposals.length;
        arrProposals.push( 
            strProposal( { 
                proponent: msg.sender,
                typeProposal: proposalType.transferEth,
                description: _description,
                propDataId: idDataNewPropTxWei,
                numVotes: 0,
                againstVotes: 0,
                executed: false,
                rejected: false,
                deadline: block.timestamp + _delayTime
            } )
        );

        emit evtProposal( proposalEvent.addProposal, propId, proposalType.transferEth, _description );

        // Auto vote
        __Vote__( msg.sender, propId , true , _description );

        return propId;
    }

    function PropTxERC20(
        address _to,
        uint256 _amountOutCLV,
        address _tokenAdd,
        string memory _description,
        uint256 _delayTime
    )
        external
        returns( uint256 )
    {
        CheckIsManager( msg.sender );

        uint256 idDataNewPropTxWei = arrDataPropTxAssets.length;
        arrDataPropTxAssets.push(
            strDataTxAssets({
                to: _to,
                amountOutCLV: _amountOutCLV,
                tokenOutCLV: _tokenAdd,
                tokenInCLV: address(0)
            } )
        );

        uint256 propId = arrProposals.length;
        arrProposals.push( 
            strProposal( { 
                proponent: msg.sender,
                typeProposal: proposalType.transferERC20,
                description: _description,
                propDataId: idDataNewPropTxWei,
                numVotes: 0,
                againstVotes: 0,
                executed: false,
                rejected: false,
                deadline: block.timestamp + _delayTime
            } )
        );
        emit evtProposal( proposalEvent.addProposal, propId, proposalType.transferERC20, _description );

        // Auto vote
        __Vote__( msg.sender, propId , true , _description );

        return propId;
    }

    function PropSwapERC20(
        address _tokenOutCLV,
        address _tokenInCLV,
        uint256 _amountOutCLV,
        string memory _description,
        uint256 _delayTime
    )
        external
        returns( uint256 propId )
    {
        CheckIsManager( msg.sender );

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
        __Vote__( msg.sender, propId , true , _description );
    }


    function PropSellERC20(
        address _tokenOutCLV,
        uint256 _amountOutCLV,
        string memory _description,
        uint256 _delayTime
    )
        external
        returns( uint256 propId )
    {
        CheckIsManager( msg.sender );

        require( IERC20( _tokenOutCLV ).balanceOf( address( vaultCLH ) ) >= _amountOutCLV , "Insufficient Tokens!!" );
        
        uint256 idDataNewPropTxWei = arrDataPropTxAssets.length;
        arrDataPropTxAssets.push(
            strDataTxAssets({
                to: address(0),
                amountOutCLV: _amountOutCLV,
                tokenOutCLV: _tokenOutCLV,
                tokenInCLV: address(0)
            } )
        );

        propId = arrProposals.length;
        arrProposals.push( 
            strProposal( { 
                proponent: msg.sender,
                typeProposal: proposalType.sellERC20,
                description: _description,
                propDataId: idDataNewPropTxWei,
                numVotes: 0,
                againstVotes: 0,
                executed: false,
                rejected: false,
                deadline: block.timestamp + _delayTime
            } )
        );

        emit evtProposal( proposalEvent.addProposal, propId, proposalType.sellERC20, _description );

        // Auto vote
        __Vote__( msg.sender, propId , true , _description );
    }


    function PropBuyERC20(
        address _tokenInCLV,
        uint256 _amountOutCLV,
        string memory _description,
        uint256 _delayTime
    )
        external
        returns( uint256 propId )
    {
        CheckIsManager( msg.sender );

        require( address( this ).balance >= _amountOutCLV , "Insufficient funds!!"  );
        
        uint256 idDataNewPropTxWei = arrDataPropTxAssets.length;
        arrDataPropTxAssets.push(
            strDataTxAssets({
                to: address(0),
                amountOutCLV: _amountOutCLV,
                tokenOutCLV: address(0),
                tokenInCLV: _tokenInCLV
            } )
        );

        propId = arrProposals.length;
        arrProposals.push( 
            strProposal( { 
                proponent: msg.sender,
                typeProposal: proposalType.buyERC20,
                description: _description,
                propDataId: idDataNewPropTxWei,
                numVotes: 0,
                againstVotes: 0,
                executed: false,
                rejected: false,
                deadline: block.timestamp + _delayTime
            } )
        );

        emit evtProposal( proposalEvent.addProposal, propId, proposalType.buyERC20, _description );

        // Auto vote
        __Vote__( msg.sender, propId , true , _description );
    }

    function bulkVote(
        uint256[] memory _propId,
        bool _support,
        string memory _justification
    )
        external
    {
        address realSender = msg.sender;

        // ToDo: off chain verification

        CheckIsManager( realSender );

        for( uint256 idx = 0 ;  idx < _propId.length ; idx++ ) {
            CheckPropExists( _propId[ idx ] );
            CheckPropNotExecuted( _propId[ idx ] );
            CheckPropNotRejected ( _propId[ idx ] );
            CheckDeadline( _propId[ idx ] );

            require( !mapVotes[ _propId[ idx ] ][ realSender ].voted , "User have a vote registred for this proposal" );

            __Vote__(
                realSender,
                _propId[ idx ],
                _support,
                _justification
            );
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "CLHNFT.sol";
import "ICLFactory.sol";
import "CLVault.sol";

/// @title Contract to store data of CLHouse (var stack)
/// @author Leonardo Urrego
/// @notice This contract is part of CLH
abstract contract CLStorage {

	/**
     * ### CLH Public Variables ###
     */

    bool public housePrivate;
    bool public houseOpen;
    bool[30] __gapBool;

    uint256 public numUsers;
    uint256 public numManagers;
    uint256 public govRuleApprovPercentage;
    uint256 public govRuleMaxUsers;
    uint256 public govRuleMaxManagers;
    uint256[27] __gapUint256;

    address public CLHAPI;
    address public CLHSAFE;
    address[30] __gapAddress;

    string public HOUSE_NAME;
    uint256[31] __gapString;

    bytes32 public HOUSE_GOVERNANCE_MODEL;
    bytes32[31] __gapBytes32;

    strUser[] public arrUsers;
    strProposal[] public arrProposals;
    strDataUser[] public arrDataPropUser;
    strDataTxAssets[] public arrDataPropTxAssets;
    strDataGovRules[] public arrDataPropGovRules;
    uint256[27] __gapArrays;

    mapping( address => uint256 ) public mapIdUser;
    mapping( address => uint256 ) public mapInvitationUser; // wallet => propId
    mapping( address => uint256 ) public mapReq2Join; // wallet => propId
    mapping( uint256 => mapping( address => strVote ) ) public mapVotes; // mapVotes[propId][wallet].strVote
    uint256[27] __gapMappings;

    ICLFactory public CCLFACTORY;
    CLVault public vaultCLH;
    CLHNFT public nftAdmin;
    CLHNFT public nftMember;
    CLHNFT public nftInvitation;

    /**
     * ### Contract events ###
     */

    event evtUser( userEvent eventUser, address walletAddr, string name );
    event evtVoted( uint256 propId, bool position, address voter, string justification );
    event evtProposal( proposalEvent eventProposal, uint256 propId, proposalType typeProposal, string description );
    event evtChangeGovRules( uint256 newApprovPercentage );
    event evtTxEth( assetsEvent typeEvent, address walletAddr, uint256 value, uint256 balance );
    event evtTxERC20( address walletAddr, uint256 value, address tokenAdd );
    event evtSwapERC20( address tokenOutCLV, uint256 amountOutCLV, address tokenInCLV, uint256 amountReceived );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "ERC721.sol";
import "ERC721URIStorage.sol";
import "ERC721Burnable.sol";
import "Ownable.sol";
import "Counters.sol";

contract CLHNFT is ERC721, ERC721URIStorage, ERC721Burnable, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    constructor( string memory _name , string memory _symbol ) ERC721( _name, _symbol ) {}

    function safeMint(address to, string memory uri) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        revert("operation not allowed");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "IERC721.sol";
import "IERC721Receiver.sol";
import "IERC721Metadata.sol";
import "Address.sol";
import "Context.sol";
import "Strings.sol";
import "ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "IERC165.sol";

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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
                /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/extensions/ERC721URIStorage.sol)

pragma solidity ^0.8.0;

import "ERC721.sol";

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorage is ERC721 {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev See {ERC721-_burn}. This override additionally checks to see if a
     * token-specific URI was set for the token, and if so, it deletes the token URI from
     * the storage mapping.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/extensions/ERC721Burnable.sol)

pragma solidity ^0.8.0;

import "ERC721.sol";
import "Context.sol";

/**
 * @title ERC721 Burnable Token
 * @dev ERC721 Token that can be burned (destroyed).
 */
abstract contract ERC721Burnable is Context, ERC721 {
    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _burn(tokenId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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
pragma solidity ^0.8.11;

import "CLTypes.sol";
import "CLBeacon.sol";
import "ICLHouse.sol";


interface ICLFactory {
    // View fuctions
    function CLHAPI() external view returns( address );
    function CLLConstructorCLH() external view returns( address );
    function CLLUserManagement() external view returns( address );
    function CLLGovernance() external view returns( address );
    function beaconCLH() external view returns( CLBeacon );
    function mapCLH( uint256 ) external view returns( ICLHouse );
    function numCLH() external view returns( uint256 );
    function getCLHImplementation() external view returns (address);

    // Write Functions
    function Init(
        address _CLLUserManagement,
        address _CLLGovernance,
        address _CLLConstructorCLH,
        address _CLHAPI,
        address _beacon
    ) external;

    function CreateCLH(
        string memory _houseName,
        bool _housePrivate,
        bool _houseOpen,
        bytes32 _govModel,
        uint256[3] memory _govRules,
        address[] memory _ManagerWallets,
        address _gnosisSafe,
        address _signerWallet,
        bytes memory _signature
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

error InvalidGovernanceType ( bytes32 ) ;
error DebugDLGTCLL( bool successDLGTCLL , bytes dataDLGTCLL );

/*
 * ### CLH constant Types ###
 */

uint8 constant __UPGRADEABLE_CLH_VERSION__ = 1;
uint8 constant __UPGRADEABLE_CLF_VERSION__ = 1;

bytes32 constant __GOV_DICTATORSHIP__ = keccak256("__GOV_DICTATORSHIP__");
bytes32 constant __GOV_COMMITTEE__ = keccak256("__GOV_COMMITTEE__");
bytes32 constant __GOV_SIMPLE_MAJORITY__ = keccak256("__GOV_SIMPLE_MAJORITY__");
bytes32 constant __CONTRACT_NAME_HASH__ = keccak256("CLHouse");
bytes32 constant __CONTRACT_VERSION_HASH__ = keccak256("0.1.0");
bytes32 constant __STR_EIP712DOMAIN_HASH__ = keccak256(
    abi.encodePacked(
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    )
);
bytes32 constant __STR_OCINVIT_HASH__ = keccak256(
    abi.encodePacked(
        "strOCInvit(bool acceptance)"
    )
);
bytes32 constant __STR_OCVOTE_HASH__ = keccak256(
    abi.encodePacked(
        "strOCVote(uint256 propId,bool support,string justification)"
    )
);
bytes32 constant __STR_OCNEWUSER_HASH__ = keccak256(
    abi.encodePacked(
        "strOCNewUser(address walletAddr,string name,string description,bool isManager,uint256 delayTime)"
    )
);
bytes32 constant __STR_OCDELUSER_HASH__ = keccak256(
    abi.encodePacked(
        "strOCDelUser(address walletAddr,string description,uint256 delayTime)"
    )
);
bytes32 constant __STR_OCREQUEST_HASH__ = keccak256(
    abi.encodePacked(
        "strOCRequest(string name,string description)"
    )
);
bytes32 constant __STR_OCNEWCLH_HASH__ = keccak256(
    abi.encodePacked(
        "strOCNewCLH(string houseName,bool housePrivate,bool houseOpen,bytes32 govModel,uint256 govRuleMaxUsers,uint256 govRuleMaxManagers,uint256 govRuleApprovPercentage,address whiteListWallets)"
    )
);


/*
 * ### CLH enum Types ###
 */

enum userEvent{
    addUser,
    delUser,
    inviteUser,
    acceptInvitation,
    rejectInvitation,
    requestJoin
}

enum assetsEvent {
    receivedEth,
    transferEth,
    transferERC20,
    swapERC20,
    sellERC20,
    buyERC20
}

enum proposalEvent {
    addProposal,
    execProposal,
    rejectProposal
}

enum proposalType {
    newUser,
    removeUser,
    requestJoin,
    changeGovRules,
    transferEth,
    transferERC20,
    swapERC20,
    sellERC20,
    buyERC20
}

/// @param maxUsers Max of all users (including managers)
/// @param maxManagers Max of managers that CLH can accept (only for COMMITTEE )
/// @param approvPercentage Percentage for approval o reject proposal based on `numManagers`
enum gRule {
    maxUsers,
    maxManagers,
    approvPercentage
}

// / @param CLLUserManagement Address Contract Logic for user management
// / @param CLLGovernance Address Contract Logic for governance
/// @param CLFACTORY Address Proxy Contract for CLF
/// @param CLHAPI Address Contract for API
/// @param CLHSAFE Address Contract Proxy for Gnosis Safe
/// @param CLLConstructorCLH Address Contract with the CLH Constructor logic
enum eCLC {
    CLFACTORY,
    CLHAPI,
    CLHSAFE,
    CLLConstructorCLH
}


/*
 * ### CLH struct Types ###
 */

struct strUser {
    address walletAddr;
    string name;
    uint256 balance;
    bool isUser;
    bool isManager;
}

struct strProposal {
    address proponent;
    proposalType typeProposal;
    string description;
    uint256 propDataId;
    uint256 numVotes;
    uint256 againstVotes;
    bool executed;
    bool rejected;
    uint256 deadline;
}

struct strVote {
    bool voted;
    bool inSupport;
    string justification;
}

struct strDataUser {
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
    uint256 newApprovPercentage;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "UpgradeableBeacon.sol";

contract CLBeacon is UpgradeableBeacon {
    constructor(
        address _CLLogicContract
    )
        UpgradeableBeacon(
            _CLLogicContract
        )
    {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/UpgradeableBeacon.sol)

pragma solidity ^0.8.0;

import "IBeacon.sol";
import "Ownable.sol";
import "Address.sol";

/**
 * @dev This contract is used in conjunction with one or more instances of {BeaconProxy} to determine their
 * implementation contract, which is where they will delegate all function calls.
 *
 * An owner is able to change the implementation the beacon points to, thus upgrading the proxies that use this beacon.
 */
contract UpgradeableBeacon is IBeacon, Ownable {
    address private _implementation;

    /**
     * @dev Emitted when the implementation returned by the beacon is changed.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Sets the address of the initial implementation, and the deployer account as the owner who can upgrade the
     * beacon.
     */
    constructor(address implementation_) {
        _setImplementation(implementation_);
    }

    /**
     * @dev Returns the current implementation address.
     */
    function implementation() public view virtual override returns (address) {
        return _implementation;
    }

    /**
     * @dev Upgrades the beacon to a new implementation.
     *
     * Emits an {Upgraded} event.
     *
     * Requirements:
     *
     * - msg.sender must be the owner of the contract.
     * - `newImplementation` must be a contract.
     */
    function upgradeTo(address newImplementation) public virtual onlyOwner {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Sets the implementation contract address for this beacon
     *
     * Requirements:
     *
     * - `newImplementation` must be a contract.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "UpgradeableBeacon: implementation is not a contract");
        _implementation = newImplementation;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "CLTypes.sol";


interface ICLHouse {

    // View fuctions
    function housePrivate() external view returns( bool );
    function houseOpen() external view returns( bool );
    function HOUSE_NAME() external view returns( string memory );
    function HOUSE_GOVERNANCE_MODEL() external view returns( bytes32 );
    function numUsers() external view returns( uint256 );
    function numManagers() external view returns( uint256 );
    function govRuleApprovPercentage() external view returns( uint256 );
    function govRuleMaxUsers() external view returns( uint256 );
    function govRuleMaxManagers() external view returns( uint256 );
    function arrUsers( uint256 ) external view returns( address , string memory , uint256 , bool , bool );
    function arrProposals( uint256 ) external view returns( address , proposalType , string memory , uint16 , uint8 , uint8 , bool , bool , uint256 );
    function arrDataPropUser( uint256 ) external view returns( address , string memory , bool );
    function arrDataPropTxWei( uint256 ) external view returns( address , uint256 );
    function arrDataPropGovRules( uint256 ) external view returns( uint256 );
    function mapIdUser( address ) external view returns( uint256 );
    function mapInvitationUser( address ) external view returns( uint256 );
    function mapVotes( uint256 ,  address ) external view returns( bool , bool , string memory);
    function GetArrUsersLength() external view returns( uint256 );
    function CLHSAFE() external view returns( address );


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

    function PropInviteUser(
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

    function PropRemoveUser(
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
        uint256 _newApprovPercentage,
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
pragma solidity ^0.8.11;

import "CLHouseApi.sol";
import "ISwapRouter.sol";
import "TransferHelper.sol";

/// @title Vault contract for CLH
/// @notice Contract to store the assets and the functions that have any interaction with these
/// @author Leonardo Urrego
contract CLVault {

    /**
     * ### CLV Private Variables ###
     */

    /// @notice Contract of the offcial uniswap router
    ISwapRouter internal constant swapRouterV3 = ISwapRouter( 0xE592427A0AEce92De3Edee1F18E0157C05861564 );

    /// @notice Contract of the ERC20 WETH token
    address internal constant WETH = 0xc778417E063141139Fce010982780140Aa0cD5Ab; // rinkeby

    /// @notice CLH that deployed this contract
	ICLHouse ownerCLH;

	/**
     * ### Contract events ###
     */

    /// @notice Event when deposit or transfer ETH
    /// @param typeEvent received/Transfer
    /// @param walletAddr Origin or destination address
    /// @param value amount in wei
    /// @param balance new balance after transacction in wei
    event evtTxEth( assetsEvent typeEvent, address walletAddr, uint256 value, uint256 balance );

    /// @notice Event when transfer any ERC20
    /// @param walletAddr destination address
    /// @param value amount
    /// @param tokenAdd Contract address of the ERC20
    /// @dev The recieve transfer event can't be generated here
    event evtTxERC20( address walletAddr, uint256 value, address tokenAdd );

    /// @notice Event for any swap of ERC20 token
    /// @param tokenOutCLV ERC20 contract token OUT
    /// @param amountOutCLV Amount that OUT from CLVault
    /// @param tokenInCLV ERC20 contract token IN
    /// @param amountReceived Amount that IN from CLVault
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


    /// @notice Create the vault and asign the owner house
    /// @param _CLH Address of the vault owner
    constructor( address _CLH ) payable {
        ownerCLH = ICLHouse( _CLH );
    }


    /// @notice Transfer ETH from this vault
    /// @param _walletAddr Address of the receiver
    /// @param _amountOutCLV Amount to transfer from this vault
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

        // arrUsers[ mapIdUser[ msg.sender ] ].balance -= msg.value;  // TODO: safeMath?

        emit evtTxEth( assetsEvent.transferEth, _walletAddr, _amountOutCLV, address( this ).balance );
    }


    /// @notice Transfer any ERC20 that this vault has
    /// @param _walletAddr Address of the receiver
    /// @param _amountOutCLV Amount to transfer from this vault
    /// @param _tokenOutCLV Contract Address of the token to transfer
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


    /// @notice Swap any ERC20 that this vault has using Uniswap
    /// @param _tokenOutCLV Contract Address of the token to swap
    /// @param _tokenInCLV Contract Address of the token to receive
    /// @param _amountOutCLV Amount to swap from this vault
    /// @return amountReceived Token amount "received in the vault"
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


    /// @notice Buy any ERC20 with Ether using Uniswap
    /// @param _tokenInCLV Contract Address of the token to receive
    /// @param _amountOutCLV Amount in ether out from this vault
    /// @return amountReceived Token amount received in the vault
    /// @dev The Ether is converted to WETH before buy
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

        emit evtTxEth( assetsEvent.transferEth, WETH, _amountOutCLV, address( this ).balance );

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


    /// @notice Sell any ERC20 using Uniswap
    /// @param _tokenOutCLV Contract Address of the token to sell
    /// @param _amountOutCLV Token amount out from this vault
    /// @return amountReceived Ether amount received in the vault
    /// @dev The WETH is converted to Ether at the end
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

        emit evtSwapERC20( _tokenOutCLV, _amountOutCLV, address( 0 ), amountReceived );

        ( bool result , ) = WETH.call{value: 0}( abi.encodeWithSignature( "withdraw(uint256)" , amountReceived ) );
        require( result , "Withdraw ETH fail" );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "ICLHouse.sol";

/// @title Some funtions to interact with a CLHouse
/// @author Leonardo Urrego
/// @notice This contract is only for test 
contract CLHouseApi {

    /// @notice A funtion to verify the signer of a menssage
    /// @param _msghash Hash of the message
    /// @param _signature Signature of the message
    /// @return Signer address of the message
    function SignerOfMsg(
        bytes32  _msghash,
        bytes memory _signature
    )
        public
        pure
        returns( address )
    {
        require( _signature.length == 65, "Bad signature length" );

        bytes32 signR;
        bytes32 signS;
        uint8 signV;

        assembly {
            // first 32 bytes, after the length prefix
            signR := mload( add( _signature, 32 ) )
            // second 32 bytes
            signS := mload( add( _signature, 64 ) )
            // final byte (first byte of the next 32 bytes)
            signV := byte( 0, mload( add( _signature, 96 ) ) )
        }

        return ecrecover( _msghash, signV, signR, signS );
    }

    /// @notice Get the info of an user in one especific CLH
    /// @param _houseAddr Address of the CLH
    /// @param _walletAddr Address of the user
    /// @return name Nickname ot other user identificaction
    /// @return balance How much money have deposited
    /// @return isUser true if is User
    /// @return isManager true if is manager
    function GetUserInfoByAddress(
        address _houseAddr,
        address _walletAddr
    )
        external
        view
        returns(
            string memory name,
            uint balance,
            bool isUser,
            bool isManager
        )
    {
        ICLHouse daoCLH = ICLHouse( _houseAddr );

        uint256 uid = daoCLH.mapIdUser( _walletAddr );

        require( 0 != uid , "Address not exist!!" );

        strUser memory houseUser;

        (   houseUser.walletAddr,
            houseUser.name,
            houseUser.balance,
            houseUser.isUser,
            houseUser.isManager ) = daoCLH.arrUsers( uid );

        require( true == houseUser.isUser  , "Is not a user" );

        return (
            houseUser.name,
            houseUser.balance,
            houseUser.isUser,
            houseUser.isManager
        );
    }

    /// @notice The list of all users address
    /// @param _houseAddr address of the CLH
    /// @return arrUsers array with list of users
    function GetHouseUserList(
        address _houseAddr
    )
        external
        view
        returns(
            strUser[] memory arrUsers
        )
    {
        ICLHouse daoCLH = ICLHouse( _houseAddr );

        uint256 numUsers = daoCLH.numUsers( );
        uint256 arrUsersLength = daoCLH.GetArrUsersLength();
        strUser[] memory _arrUsers = new strUser[] ( numUsers );

        uint256 index = 0 ;

        for( uint256 uid = 1 ; uid < arrUsersLength ; uid++ ) {
            strUser memory houseUser;

            (   houseUser.walletAddr,
                houseUser.name,
                houseUser.balance,
                houseUser.isUser,
                houseUser.isManager ) = daoCLH.arrUsers( uid );

            if( true == houseUser.isUser ){
                _arrUsers[ index ] = houseUser;
                index++;
            }
        }
        return _arrUsers;
    }

    /// @notice All properties of a House
    /// @param _houseAddr CLH address
    /// @return HOUSE_NAME name of the CLH
    /// @return HOUSE_GOVERNANCE_MODEL Hash of governance model
    /// @return housePrivate True if is private
    /// @return houseOpen True if is Open
    /// @return numUsers Current users of a CLH
    /// @return numManagers Current managers of a CLH
    /// @return govRuleApprovPercentage Percentage for approval o reject proposal based on `numManagers`
    /// @return govRuleMaxUsers Max of all users (including managers)
    /// @return govRuleMaxManagers Max of managers that CLH can accept (only for COMMITTEE )
    function GetHouseProperties(
        address _houseAddr
    )
        external
        view
        returns(
            string memory HOUSE_NAME,
            bytes32 HOUSE_GOVERNANCE_MODEL,
            bool housePrivate,
            bool houseOpen,
            uint256 numUsers,
            uint256 numManagers,
            uint256 govRuleApprovPercentage,
            uint256 govRuleMaxUsers,
            uint256 govRuleMaxManagers
        )
    {
        ICLHouse daoCLH = ICLHouse( _houseAddr );

        return(
            daoCLH.HOUSE_NAME(),
            daoCLH.HOUSE_GOVERNANCE_MODEL(),
            daoCLH.housePrivate(),
            daoCLH.houseOpen(),
            daoCLH.numUsers(),
            daoCLH.numManagers(),
            daoCLH.govRuleApprovPercentage(),
            daoCLH.govRuleMaxUsers(),
            daoCLH.govRuleMaxManagers()
        );
    }


    function SignerOCInvit(
        bool _acceptance,
        address _houseAddr,
        bytes memory _signature
    ) 
        external view
        returns( address )
    {
        bytes32 hashEIP712Domain = keccak256(
            abi.encode(
                __STR_EIP712DOMAIN_HASH__,
                __CONTRACT_NAME_HASH__,
                __CONTRACT_VERSION_HASH__,
                block.chainid,
                _houseAddr
            )
        );

        bytes32 hashMsg = keccak256(
            abi.encode(
                __STR_OCINVIT_HASH__,
                _acceptance
            )
        );

        bytes32 singhash = keccak256( abi.encodePacked( "\x19\x01", hashEIP712Domain, hashMsg ) );

        return SignerOfMsg( singhash, _signature );
    }


    function SignerOCVote(
        uint _propId,
        bool _support,
        string memory _justification,
        address _houseAddr,
        bytes memory _signature
    ) 
        external view
        returns( address )
    {
        bytes32 hashEIP712Domain = keccak256(
            abi.encode(
                __STR_EIP712DOMAIN_HASH__,
                __CONTRACT_NAME_HASH__,
                __CONTRACT_VERSION_HASH__,
                block.chainid,
                _houseAddr
            )
        );

        bytes32 hashMsg = keccak256(
            abi.encode(
                __STR_OCVOTE_HASH__,
                _propId,
                _support,
                keccak256( abi.encodePacked( _justification ) )
            )
        );

        bytes32 singhash = keccak256( abi.encodePacked( "\x19\x01", hashEIP712Domain, hashMsg ) );

        return SignerOfMsg( singhash, _signature );
    }


    function SignerOCNewUser(
        address _walletAddr,
        string memory _name,
        string memory _description,
        bool _isManager,
        uint256 _delayTime,
        address _houseAddr,
        bytes memory _signature
    ) 
        external view
        returns( address )
    {
        bytes32 hashEIP712Domain = keccak256(
            abi.encode(
                __STR_EIP712DOMAIN_HASH__,
                __CONTRACT_NAME_HASH__,
                __CONTRACT_VERSION_HASH__,
                block.chainid,
                _houseAddr
            )
        );

        bytes32 hashMsg = keccak256(
            abi.encode(
                __STR_OCNEWUSER_HASH__,
                _walletAddr,
                keccak256( abi.encodePacked( _name ) ),
                keccak256( abi.encodePacked( _description ) ),
                _isManager,
                _delayTime
            )
        );

        bytes32 singhash = keccak256( abi.encodePacked( "\x19\x01", hashEIP712Domain, hashMsg ) );

        return SignerOfMsg( singhash, _signature );
    }


    function SignerOCDelUser(
        address _walletAddr,
        string memory _description,
        uint256 _delayTime,
        address _houseAddr,
        bytes memory _signature
    ) 
        external view
        returns( address )
    {
        bytes32 hashEIP712Domain = keccak256(
            abi.encode(
                __STR_EIP712DOMAIN_HASH__,
                __CONTRACT_NAME_HASH__,
                __CONTRACT_VERSION_HASH__,
                block.chainid,
                _houseAddr
            )
        );

        bytes32 hashMsg = keccak256(
            abi.encode(
                __STR_OCDELUSER_HASH__,
                _walletAddr,
                keccak256( abi.encodePacked( _description ) ),
                _delayTime
            )
        );

        bytes32 singhash = keccak256( abi.encodePacked( "\x19\x01", hashEIP712Domain, hashMsg ) );

        return SignerOfMsg( singhash, _signature );
    }


    function SignerOCRequest(
        string memory _name,
        string memory _description,
        address _houseAddr,
        bytes memory _signature
    ) 
        external view
        returns( address )
    {
        bytes32 hashEIP712Domain = keccak256(
            abi.encode(
                __STR_EIP712DOMAIN_HASH__,
                __CONTRACT_NAME_HASH__,
                __CONTRACT_VERSION_HASH__,
                block.chainid,
                _houseAddr
            )
        );

        bytes32 hashMsg = keccak256(
            abi.encode(
                __STR_OCREQUEST_HASH__,
                keccak256( abi.encodePacked( _name ) ),
                keccak256( abi.encodePacked( _description ) )
            )
        );

        bytes32 singhash = keccak256( abi.encodePacked( "\x19\x01", hashEIP712Domain, hashMsg ) );

        return SignerOfMsg( singhash, _signature );
    }


    function SignerOCNewCLH(
        string memory _houseName,
        bool _housePrivate,
        bool _houseOpen,
        bytes32 _govModel,
        uint256 _govRuleMaxUsers,
        uint256 _govRuleMaxManagers,
        uint256 _govRuleApprovPercentage,
        address _whiteListWallets,
        address _addrCLF,
        bytes memory _signature
    ) 
        external view
        returns( address )
    {
        bytes32 hashEIP712Domain = keccak256(
            abi.encode(
                __STR_EIP712DOMAIN_HASH__,
                __CONTRACT_NAME_HASH__,
                __CONTRACT_VERSION_HASH__,
                block.chainid,
                _addrCLF
            )
        );

        bytes32 hashMsg = keccak256(
            abi.encode(
                __STR_OCNEWCLH_HASH__,
                keccak256( abi.encodePacked( _houseName ) ),
                _housePrivate,
                _houseOpen,
                _govModel,
                _govRuleMaxUsers,
                _govRuleMaxManagers,
                _govRuleApprovPercentage,
                _whiteListWallets
                // keccak256( abi.encodePacked( _whiteListWallets ) )
            )
        );

        bytes32 singhash = keccak256( abi.encodePacked( "\x19\x01", hashEIP712Domain, hashMsg ) );

        return SignerOfMsg( singhash, _signature );
    }
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