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
        address payable _houseAddr,
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
        address payable _houseAddr
    )
        external
        view
        returns(
            strUser[] memory arrUsers
        )
    {
        ICLHouse daoCLH = ICLHouse( _houseAddr );

        uint8 numUsers = daoCLH.numUsers( );
        uint256 arrUsersLength = daoCLH.GetArrUsersLength();
        strUser[] memory _arrUsers = new strUser[] ( numUsers );

        uint8 index = 0 ;

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
            uint8 numUsers,
            uint8 numManagers,
            uint8 govRuleApprovPercentage,
            uint8 govRuleMaxUsers,
            uint8 govRuleMaxManagers
        )
    {
        ICLHouse daoCLH = ICLHouse( _houseAddr );

        return(
            daoCLH.HOUSE_NAME(),
            daoCLH.HOUSE_GOVERNANCE_MODEL(),
            daoCLH.housePrivate(),
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
        bytes32 _govModel,
        uint8 _govRuleMaxUsers,
        uint8 _govRuleMaxManagers,
        uint8 _govRuleApprovPercentage,
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "IERC20.sol";

bytes32 constant __GOV_DICTATORSHIP__ = keccak256("__GOV_DICTATORSHIP__");
bytes32 constant __GOV_COMMITTEE__ = keccak256("__GOV_COMMITTEE__");
bytes32 constant __GOV_SIMPLE_MAJORITY__ = keccak256("__GOV_SIMPLE_MAJORITY__");
bytes32 constant __CONTRACT_NAME_HASH__ = keccak256("CLHouse");
bytes32 constant __CONTRACT_VERSION_HASH__ = keccak256("0.0.10");
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
        "strOCNewCLH(string houseName,bool housePrivate,bytes32 govModel,uint8 govRuleMaxUsers,uint8 govRuleMaxManagers,uint8 govRuleApprovPercentage,address whiteListWallets)"
    )
);


error InvalidGovernanceType ( bytes32 ) ;
error DebugDLGTCLL( bool successDLGTCLL , bytes dataDLGTCLL );

/**
 * ### CLH Types ###
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

/// @param CLLUserManagement Address Contract Logic for user management
/// @param CLLGovernance Address Contract Logic for governance
/// @param CLLConstructorCLH Address Contract with the CLH Constructor logic
enum eCLC {
    CLLUserManagement,
    CLLGovernance,
    CLLConstructorCLH,
    CLHAPI
}

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

struct strDataAddUser {
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
    function numUsers() external view returns( uint8 );
    function numManagers() external view returns( uint8 );
    function govRuleApprovPercentage() external view returns( uint8 );
    function govRuleMaxUsers() external view returns( uint8 );
    function govRuleMaxManagers() external view returns( uint8 );
    function arrUsers( uint256 ) external view returns( address , string memory , uint256 , bool , bool );
    function arrProposals( uint256 ) external view returns( address , proposalType , string memory , uint16 , uint8 , uint8 , bool , bool , uint256 );
    function arrDataPropAddUser( uint256 ) external view returns( address , string memory , bool );
    function arrDataPropTxWei( uint256 ) external view returns( address , uint256 );
    function arrDataPropGovRules( uint256 ) external view returns( uint8 );
    function mapIdUser( address ) external view returns( uint256 );
    function mapInvitationUser( address ) external view returns( uint256 );
    function mapVotes( uint256 ,  address ) external view returns( bool , bool , string memory);
    function GetArrUsersLength() external view returns( uint256 );

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