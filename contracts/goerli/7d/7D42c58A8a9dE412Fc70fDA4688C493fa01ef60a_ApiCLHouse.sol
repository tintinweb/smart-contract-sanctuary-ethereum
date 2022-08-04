// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "ICLHouse.sol";

/// @title Some funtions to interact with a CLHouse
/// @author Leonardo Urrego
/// @notice This contract is only for test 
contract ApiCLHouse {

    /// @notice A funtion to verify the signer of a menssage
    /// @param _msgh Signed message
    /// @param _v V
    /// @param _r R
    /// @param _s S
    /// @return sender The address of the signer
    function RecoverSignerFromSignature(
        bytes32  _msgh,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    )
        public
        pure
        returns(
            address sender
        )
    {
        return ecrecover( _msgh, _v, _r, _s);
    }

    /// @notice Get the info of an user in one especific CLH
    /// @param _houseAddr Address of the CLH
    /// @param _walletAddr Address of the user
    /// @return name Nickname ot other user identificaction
    /// @return balance How much money have deposited
    /// @return isMember true if is member
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
            bool isMember,
            bool isManager
        )
    {
        ICLHouse daoCLH = ICLHouse( _houseAddr );

        uint256 uid = daoCLH.mapIdMember( _walletAddr );

        require( 0 != uid , "Address not exist!!" );

        strMember memory houseMember;

        (   houseMember.walletAddr,
            houseMember.name,
            houseMember.balance,
            houseMember.isMember,
            houseMember.isManager ) = daoCLH.arrMembers( uid );

        require( true == houseMember.isMember  , "User is not a Member" );

        return (
            houseMember.name,
            houseMember.balance,
            houseMember.isMember,
            houseMember.isManager
        );
    }

    /// @notice The list of all members address
    /// @param _houseAddr address of the CLH
    /// @return arrMembers array with list of members
    function GetHouseUserList(
        address payable _houseAddr
    )
        external
        view
        returns(
            strMember[] memory arrMembers
        )
    {
        ICLHouse daoCLH = ICLHouse( _houseAddr );

        uint8 numActiveMembers = daoCLH.numActiveMembers( );
        uint256 arrMembersLength = daoCLH.GetArrMembersLength();
        strMember[] memory _arrMembers = new strMember[] ( numActiveMembers );

        uint8 index = 0 ;

        for( uint256 uid = 1 ; uid < arrMembersLength ; uid++ ) {
            strMember memory houseMember;

            (   houseMember.walletAddr,
                houseMember.name,
                houseMember.balance,
                houseMember.isMember,
                houseMember.isManager ) = daoCLH.arrMembers( uid );

            if( true == houseMember.isMember ){
                _arrMembers[ index ] = houseMember;
                index++;
            }
        }
        return _arrMembers;
    }

    /// @notice All properties of a House
    /// @param _houseAddr CLH address
    /// @return HOUSE_NAME name of the CLH
    /// @return HOUSE_GOVERNANCE_MODEL Hash of governance model
    /// @return housePrivate True if is private
    /// @return numActiveMembers Current members of a CLH
    /// @return numManagerMembers Current managers of a CLH
    /// @return govRuleApprovPercentage Percentage for approval o reject proposal based on `numManagerMembers`
    /// @return govRuleMaxActiveMembers Max of all members (including managers)
    /// @return govRuleMaxManagerMembers Max of manager member that CLH can accept (only for COMMITTEE )
    function GetHouseProperties(
        address _houseAddr
    )
        external
        view
        returns(
            string memory HOUSE_NAME,
            bytes32 HOUSE_GOVERNANCE_MODEL,
            bool housePrivate,
            uint8 numActiveMembers,
            uint8 numManagerMembers,
            uint8 govRuleApprovPercentage,
            uint8 govRuleMaxActiveMembers,
            uint8 govRuleMaxManagerMembers
        )
    {
        ICLHouse daoCLH = ICLHouse( _houseAddr );

        return(
            daoCLH.HOUSE_NAME(),
            daoCLH.HOUSE_GOVERNANCE_MODEL(),
            daoCLH.housePrivate(),
            daoCLH.numActiveMembers(),
            daoCLH.numManagerMembers(),
            daoCLH.govRuleApprovPercentage(),
            daoCLH.govRuleMaxActiveMembers(),
            daoCLH.govRuleMaxManagerMembers()
        );
    }

    function ValidateSingOffChainVote(
        address _houseAddr,
        address _voter,
        uint _propId,
        bool _support,
        string memory _justification,
        bytes memory _signature
    ) 
      external view
      returns( bool )
    {
      uint256 chainId = block.chainid;

      bytes32 eip712DomainHash = keccak256(
          abi.encode(
              keccak256(abi.encodePacked(
                  "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
              )),
              keccak256("CLHouse"),
              keccak256("0.0.10"),
              chainId,
              _houseAddr
          )
      );

      bytes32 hashStruct = keccak256(
        abi.encode(
              keccak256(abi.encodePacked(
                "strOffChainVote(address voter,uint256 propId,bool support,string justification)"
              )),
              _voter,
              _propId,
              _support,
              keccak256(abi.encodePacked(_justification))
          )
      );

      bytes32 hash = keccak256(abi.encodePacked("\x19\x01", eip712DomainHash, hashStruct));
      
      require( _signature.length == 65, "Bad signature length" );

      bytes32 r;
      bytes32 s;
      uint8 v;

      assembly {
        // first 32 bytes, after the length prefix
        r := mload( add( _signature, 32 ))
        // second 32 bytes
        s := mload( add( _signature, 64 ))
        // final byte (first byte of the next 32 bytes)
        v := byte( 0, mload( add( _signature, 96 )))
      }

      return _voter == ecrecover( hash, v, r, s );
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
    sellERC20,
    buyERC20
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
    swapERC20,
    sellERC20,
    buyERC20
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

struct strOffChainVote {
    address voter;
    uint256 propId;
    bool support;
    string  justification;
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