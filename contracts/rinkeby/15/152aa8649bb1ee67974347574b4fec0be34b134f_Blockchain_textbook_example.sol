/**
 *Submitted for verification at Etherscan.io on 2022-02-10
*/

pragma solidity ^0.4.16;

contract Blockchain_textbook_example {
    address private owner;
    string private messagefromauthors;
    mapping (uint256 => string) private textbookmessage;
    uint256 private bookcounter;

    function Blockchain_textbook_example () public {
        owner = msg.sender;
        bookcounter = 0;
    }

    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }

    function setmessagefromreader (string _messagefromreader) public {
        textbookmessage[bookcounter] = _messagefromreader;
        bookcounter ++;
    }

    function getmessagefromreader(uint256 _bookentrynumber) public view returns (string _messagefromreader) {
        return textbookmessage[_bookentrynumber];
    }

    function getnumberofmessagesfromreaders() public view returns (uint256 _numberofmessages) {
        return bookcounter;
    }

    function setmessagefromauthors (string _messagefromauthors) onlyOwner() public {
        messagefromauthors = _messagefromauthors;
    }

    function getmessagefromauthors () public view returns (string _messagefromauthors){
        return messagefromauthors;
    }

}