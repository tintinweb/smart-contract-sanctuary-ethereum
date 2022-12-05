/**
 *Submitted for verification at Etherscan.io on 2022-12-05
*/

contract A {
    struct Board {
        uint numb;
        string title;
        string question;
        string questioner;
        string respond;
        string respondent;
        Status status;
    }
    enum Status {question, cancel, answering, complete}

//    struct Status {}
    
    mapping (address => Board) BoardList;

    function setQuestion() public {}

    function cancel() public {}
}