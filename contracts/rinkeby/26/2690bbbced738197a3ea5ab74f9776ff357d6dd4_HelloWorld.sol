/**
 *Submitted for verification at Etherscan.io on 2022-05-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
contract HelloWorld {
string private _message;

// Constructur wird beim Deployment ausgeführt und soll die Variabel "_message" auf "Hello World" setzen
constructor() {
    _message = "Hello World";
}

// updateMessage() soll die Variable "_message" mit dem übergeben Wert überschreiben.
// Es soll eine Fehlermeldung zurückgeliefert werden, wenn die neue Nachricht, die gleich ist wie die alte.
function updateMessage(string memory newMessage) public{
    require(
        !compareStrings(_message,newMessage),
        "New message is old message"
    );
    _message = newMessage;
}
// readMessage() soll den aktuellen Wert von _message zurückgeben
function readMessage() public view returns(string memory){
    return _message;


}

// Ein String Vergleich in Solidity ist nicht trivial. Daher hier eine Hilfsfunktion
function compareStrings(string memory a, string memory b) public pure returns (bool) {
return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
}
}