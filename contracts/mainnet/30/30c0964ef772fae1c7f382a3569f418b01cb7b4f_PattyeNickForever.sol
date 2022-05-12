pragma solidity ^0.4.25;
contract Ownable {
	address private owner;
	constructor() public {
		owner = msg.sender;
	}
	modifier onlyOwner() {
		require( 
			msg.sender == owner, 
			'solo Dio puo cambiarlo'
		);
		_;
	}
}
contract PattyeNickForever is Ownable {
    string public amore1;
    string public amore2;
	string public data;
	string public dichiarazione;
	bool public attivo;
	constructor() public {
		amore1 = 'Patty';
		amore2 = 'Nick';
		data = '11 ottobre 2008';
		dichiarazione = 'La mia promessa per amarti ed onorarti fin che morte non ci separi. Ti amo con tutto me stesso. Sei la mia vita. Sei tutto. Per sempre tuo Nick.';
		attivo = true;
	}
	function updateStatus(bool _status) public onlyOwner {
		attivo   = _status;
		emit StatusChanged(attivo);
	}
		event StatusChanged(bool NewStatus);
}