/**
 *Submitted for verification at Etherscan.io on 2022-05-27
*/

/*
     ___       _______   _______     _______       ___       ______   
    /   \     |   ____| /  _____|   |       \     /   \     /  __  \  
   /  ^  \    |  |__   |  |  __     |  .--.  |   /  ^  \   |  |  |  | 
  /  /_\  \   |   __|  |  | |_ |    |  |  |  |  /  /_\  \  |  |  |  | 
 /  _____  \  |  |____ |  |__| |    |  '--'  | /  _____  \ |  `--'  | 
/__/     \__\ |_______| \______|    |_______/ /__/     \__\ \______/  
                                                                     
*/
// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

interface IGoEGenesis {
	function policyMint(address,uint256) external;
	function balanceOf(address) external view returns(uint256);
}

interface IGoEAttributes {
	/* GoEGenesis , sender =>  query walletOfOwner */
	function getNFTLevels(address,address) external view returns(uint256,uint256,uint256);
}

interface IMembershipOffice {

	function checkMembership(address) external view returns(bool);
	function changeAttributesAddress( address _addr ) external;
}

contract MinMembership is IMembershipOffice {
	
	address attributes;
	uint256 startEvo;
	uint256 midEvo;
	uint256 finalEvo;
	uint256 cmpMin;
	address public immutable AEGDao;
	address public immutable GENESIS;

	constructor( address GoEGenesis ) {
		GENESIS = GoEGenesis;
		AEGDao = msg.sender;
		startEvo = 3;
		midEvo = 1;
		finalEvo = 1;
		cmpMin = startEvo;
	}

	modifier onlyAEGDAO() {
		require( msg.sender == AEGDao , "OnlyDAO can call" );
		_;
	}

	function changeAttributesAddress( address _addr ) external override onlyAEGDAO {
		attributes = _addr;
	}

	function checkMembership( address _addr ) public override view returns( bool daoMember ) {
		uint256 s;
		uint256 m;
		uint256 f;
		if ( attributes != address( 0 ) ) {
			( s , m , f ) = IGoEAttributes( attributes ).getNFTLevels( GENESIS , _addr );
		}else {
			s = IGoEGenesis( GENESIS ).balanceOf( _addr );
		}
		if ( ( s + m + f  ) >= cmpMin ){
			daoMember = true;
		}
		else if ( s > startEvo ){
			daoMember = true;
		}
		else if ( m > midEvo && s >= 2 ){
			daoMember = true;
		}
		else if ( f > finalEvo && s >= 1 ){
			daoMember = true;
		}else{
			daoMember = false;
		}
		
	}
}

interface IGenesisDAOMembers {

	function changeClerk(address) external returns(bool);
}

contract AEGDAO is IGenesisDAOMembers {

	address public immutable GENESIS; 
	address internal immutable DEPLOYER;
	address public MembershipClerk;
	uint256 private _proposalIndex;

	mapping( uint256 => Proposal ) _proposals;
	mapping( uint256 => mapping( address => uint256 ) ) _ballotVote;

	event ProposalSubmitted( string ProposalURL , uint256 ProposalChoices , bytes32 ProposalReference , uint256 ProposalLength );
	event ProposalConcluded( string ProposalURL , bytes32 ProposalReference , uint256 ProposalPreference );

	modifier isMember() {
		if( msg.sender == DEPLOYER ){
			_;
		}else{
			require( IMembershipOffice( MembershipClerk ).checkMembership( msg.sender ) , "GoEGenesisDAO : Not A DAO member." );
			_;
		}
	}

	modifier onlyDeployer() {
		require( msg.sender == DEPLOYER , "Only DEPLOYER" );
		_;
	}

	struct Proposal {
		string _link;
		uint256 _ballot;
		uint256[] _choices;
		bytes32 _reference;
		uint256 _preferred;
		uint256 _deadline;
	}

	function daoMembership( address member ) public view returns( bool ){
		return IMembershipOffice( MembershipClerk ).checkMembership( member );
	}


	function getLastProposal() public view returns( uint256 ){

		return _proposalIndex;
	}

	constructor( address GoEGenesis , string memory proposalURL ) {
		GENESIS = GoEGenesis;
		DEPLOYER = msg.sender;
		MinMembership Clerk = new MinMembership( GoEGenesis );
		MembershipClerk = address( Clerk );
		uint256[] memory optionArray = new uint256[]( 4 );
		_proposalIndex = 1;
		_proposals[_proposalIndex] = Proposal( proposalURL , _proposalIndex , optionArray , 0x2e5a0bcd28fe2ff8c9d261793d6d234322012363add4d135d24acb07a452225b , 0 , ( block.timestamp + 604800 ) );
	}

	function changeClerk( address _newClerk ) public override onlyDeployer returns( bool ) {
		require( _newClerk != address( 0 ) , "The Clerk cannot be 0 addresses" );
		MembershipClerk = _newClerk;
		return true;
	}

	function changeAttributes( address _newAttributes ) public onlyDeployer {
		require( _newAttributes != address( 0 ) );
		IMembershipOffice( MembershipClerk ).changeAttributesAddress( _newAttributes );
	} 
	/**
	 * `_hash` is the keccak256(`GetData(_proposal)`) ; where GetData returns IPFS document
	 * `_options` is the amount of different choices
	 * `_proposal` here needs to be linked to ipfs.
	 */
	function submitProposal( string memory _proposal , uint256 _options , bytes32 _hash , uint256 _length ) public isMember {
		require( _length <= 604800 , "Max vote time is 1 week" );
		require( _proposals[ _proposalIndex ]._deadline < block.timestamp , "Previous proposal did not conclude" );
		_proposalIndex += 1;
		uint256[] memory optionArray = new uint256[]( _options + 1 );
		_proposals[_proposalIndex] = Proposal( _proposal , _proposalIndex , optionArray , _hash , 0 , ( block.timestamp + _length ) );
		emit ProposalSubmitted( _proposal , _options , _hash , _length );
	}

	function getProposal( uint256 proposal_reference ) public view returns( string memory _url ) {

		_url = _proposals[ proposal_reference ]._link;
		require( _proposals[ proposal_reference ]._deadline != 0 , "No such proposal reference" );
	}

	function getVotes( address voter , uint256 proposal_reference ) public view returns( uint256 choice_ ){
		require( _proposalIndex >= proposal_reference );
		return _ballotVote[ proposal_reference ] [ voter ];
	}

	function getProposalVotes( uint256 proposal_reference ) public view returns( uint256[] memory votes ){
		Proposal memory _proposal = _proposals[ proposal_reference ];
		require( _proposal._deadline != 0 , "Unkown proposal reference" );
		votes = new uint256[]( _proposal._choices.length - 1 );
		for(uint256 i=0; i<votes.length;i++){
			votes[i] = _proposal._choices[i+1];
		} 
	}

	function voteOnProposal( uint256 proposal_reference , uint256 choice ) external isMember returns( bool ) {
		require( choice != 0 );
		Proposal storage _proposal = _proposals[ proposal_reference ];
		require( _ballotVote[ _proposal._ballot][ msg.sender ] == 0 , "Voted Already" );
		require( _proposal._preferred == 0 , "Vote Concluded" );
		require( _proposal._deadline > block.timestamp );
		_proposal._choices[ choice ] += 1;
		_ballotVote[ _proposal._ballot ][ msg.sender ] = choice;
		return true;
	}

	function concludeVote( uint256 proposal_reference ) external isMember returns( uint256 winningVote ) {
		Proposal storage _proposal = _proposals[ proposal_reference ];
		require( _proposal._preferred == 0 , "Proposal Concluded" );
		require( block.timestamp >= _proposal._deadline , "Proposal cannot be concluded" );
		uint256 _idx_;
		uint256 _max_;
		for( uint256 i=1; i < _proposal._choices.length; i++ ){
			if( _proposal._choices[ i ] > _max_ ){
				_max_ = _proposal._choices[ i ];
				_idx_ = i;
			}
		}
		require( _max_ != 0 , "No Votes Registered" );
		_proposal._preferred = _idx_;
		winningVote = _max_;
		emit ProposalConcluded( _proposal._link , _proposal._reference , winningVote );
	}
}

interface IAEG20 {
	function transfer(address,uint256) external returns (bool);
    function balanceOf(address) external view returns (uint256); 
}

contract MembersDrop is AEGDAO {
	
	address public constant owner = 0x0C77526A828825D35Db9BFD06A23d91fbc3a5E8e;
	uint256 public constant MEMBERS_MINT = 0.1 ether;
	uint256 public constant PUBLIC_MINT = 0.15 ether;

	constructor( address GoEGenesis ) AEGDAO( GoEGenesis , "https://api.goe.gg/get/proposals/1" ){}

	
	modifier onlyOwner() {
		require( msg.sender == owner , "Only Owner is allowed" );
		_;
	}

	function genesisMint( address to , uint256 amount ) external payable returns( bool ) {
		uint256 _val = _mintPrice( amount );
		require( msg.value >= _val , "Need to pay for mints" );
		IGoEGenesis( GENESIS ).policyMint( to , amount );
		return true;
	}

	function _mintPrice( uint256 _amount ) internal view returns( uint256 reqValue ){
		require( _amount > 0 );
		bool isMember = IGoEGenesis( GENESIS ).balanceOf( msg.sender ) > 0 ? true : false;
		reqValue = isMember ? ( MEMBERS_MINT * _amount ) : ( ( PUBLIC_MINT + ( MEMBERS_MINT * ( _amount - 1 ) ) ) );
	}

	function mintPrice( uint256 amount ) public view returns( uint256 ) {
		return _mintPrice( amount );
	}


	function withdraw( uint256 amount , address to ) external onlyOwner {
		require( payable( to ).send( amount ) , "Not enough ether to support the withdraw" );
	}

	function withdraw20Token( address token_addr ) external onlyOwner {
		IAEG20( token_addr ).transfer( msg.sender , IAEG20( token_addr ).balanceOf( address( this ) ) );
	}
}