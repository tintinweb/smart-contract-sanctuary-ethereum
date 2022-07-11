// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;


import '@openzeppelin/contracts/utils/Strings.sol';

// Import this file to use console.log
enum ResultBattle {
    SHIP_WIN,
    BOAT_WIN,
    PENDING
}

contract BattleShips {
    
    struct Match {
        address ship; 
        address boat; 
        uint8 healthShip;
        uint8 healthBoat;
        ResultBattle result; 
        uint16 roundNumber;
        bytes[] actionShip;
        bytes[] actionBoat;
        bool isStart;
        uint8 lastMoveBoat;
        uint8 lastMoveShip;
    }


    uint256 private roomId;

    mapping(uint256 => Match) public matches;

    function createRoom()public{
        Match storage session = matches[roomId];
        
        session.ship = msg.sender;
        session.healthShip = 3;
        session.healthBoat = 3;
        session.result = ResultBattle.PENDING;
        session.roundNumber = 0;
        session.isStart = false;
        session.lastMoveBoat = 4;
        session.lastMoveShip = 4;

        emit RoomCreated(roomId);

        roomId++;    

    }

    function joinRoom(uint256 _roomId) public {
        Match storage session = matches[_roomId];
        require(session.ship != address(0), "Incorrect room ID");
        require(!session.isStart, "Match already start");

        session.boat = msg.sender;
        session.isStart = true;
        session.roundNumber++;

        emit MatchWasStarted(_roomId, session.roundNumber);
    }


    function doMove(uint256 _roomId, bytes[] memory signatures)public {
        Match storage session = matches[_roomId];
        
        require(session.ship != address(0), "Incorrect room ID");
        require(msg.sender == session.boat || msg.sender == session.ship, "Incorrect room ID");
    
        if(msg.sender == session.boat && session.actionBoat.length == 0){
            session.actionBoat = signatures;
        }else if(session.actionShip.length == 0){
            session.actionShip = signatures;
        }else{
            revert("Move already set! Wait next round");
        }
    
        
    }

    function confirmMove(uint256 _roomId, string[] memory confirmParams )public{
        Match storage session = matches[_roomId];

        require(session.ship != address(0), "Incorrect room ID");
        require(msg.sender == session.boat || msg.sender == session.ship, "Incorrect room ID");
        require(confirmParams.length == 3, "Invalid confirm params");

    

        if(session.boat == msg.sender){

            for(uint8 i; i < confirmParams.length; i++){
                checkParamsVerification(session.actionBoat[i], concatParams(i, _roomId, confirmParams[i]), msg.sender );
             }

            for(uint8 i; i < session.actionBoat.length; i++){

                bytes memory conPar = bytes(confirmParams[i]);
                
                if(conPar[conPar.length-1] == 0x54 ){
                    
                    session.lastMoveBoat = i;
                    
                }
             }    
        }else{
            for(uint8 i; i < session.actionShip.length; i++){
                checkParamsVerification(session.actionShip[i], concatParams(i, _roomId, confirmParams[i]), msg.sender );
             }

            for(uint8 i; i < session.actionShip.length; i++){
                bytes memory conPar = bytes(confirmParams[i]);

                if(conPar[conPar.length-1] == 0x54 ){
                    
                    session.lastMoveShip = i;
                    
                }
            }
        }

    if(session.lastMoveBoat != 4 && session.lastMoveShip != 4){
            nextRound(_roomId, session.lastMoveBoat, session.lastMoveShip);
        }
       
    }

    function nextRound(uint256 _roomId, uint8 validActionNumberBoat, uint8 validActionNumberShip) private {
        Match storage session = matches[_roomId];

        if(validActionNumberBoat == validActionNumberShip){
            session.roundNumber++;
            
            emit RoundWasEnded(
                _roomId,
                validActionNumberShip,
                validActionNumberBoat,
                session.healthShip,
                session.healthBoat,
                session.roundNumber
            );

            return;
            
        }

        if (session.roundNumber % 2 == 0) { 
            session.healthShip--;
        } else {
            session.healthBoat--;
        }

        session.roundNumber++;

         if (session.healthBoat == 0 || session.healthShip == 0) {
            emit MatchWasEnded( _roomId, session.healthShip, session.healthBoat, session.roundNumber);
        } else {
            emit RoundWasEnded(
                _roomId,
                validActionNumberShip,
                validActionNumberBoat,
                session.healthShip,
                session.healthBoat,
                session.roundNumber
            );
        }
        
    }


    function checkParamsVerification(bytes memory _signature, string memory _concatenatedParams, address publicKey) public pure {
		(bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
		require(verifyMessage(_concatenatedParams, v, r, s) == publicKey, 'Your signature is not valid');
	}

	function splitSignature(bytes memory _signature)
		public
		pure
		returns (
			bytes32 r,
			bytes32 s,
			uint8 v
		)
	{
		require(_signature.length == 65, 'invalid signature length');
		assembly {
			r := mload(add(_signature, 32))
			s := mload(add(_signature, 64))
			v := byte(0, mload(add(_signature, 96)))
		}
	}

	function verifyMessage(
		string memory _concatenatedParams,
		uint8 _v,
		bytes32 _r,
		bytes32 _s
	) public pure returns (address) {
		return
			ecrecover(
				keccak256(
					abi.encodePacked(
						'\x19Ethereum Signed Message:\n',
						Strings.toString(bytes(_concatenatedParams).length),
						_concatenatedParams
					)
				),
				_v,
				_r,
				_s
			);
	}

	function concatParams(
		uint256 _action,
		uint256 _roomId,
		string memory _stateAction
	) private pure returns (string memory) {
		return
			string(
				abi.encodePacked(
					Strings.toString(_action),
					Strings.toString(_roomId),
					_stateAction
				)
			);
	}

    /*----------------------------------------EVENTS---------------------------------------------------------*/
    event RoomCreated(uint256 _roomId );
    event MatchWasStarted(uint256 _roomId, uint16 roundNumber);
    event MatchWasEnded(uint256 _roomId, uint8 healthShip, uint8 healthBoat, uint16 roundNumber);
    event RoundWasEnded(uint256 _roomId, uint8 shipAction, uint8 boatAction, uint8 healthShip, uint8 healthBoat, uint16 roundNumber);
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