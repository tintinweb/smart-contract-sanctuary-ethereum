/**
 *Submitted for verification at Etherscan.io on 2022-12-05
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

// 질문하고 답변하는 질의응답 게시판을 만드세요.

// 모든 유저는 질문자도 답변자도 될 수 있다. 질의응답 과정은 평범하다.
// 질문자가 질문을 등록한 후에, 답변자가 답변을 다는 것이다. 단 질문자는 스스로의 질문에 답할 수 없다. 

// 질문자가 등록하면 질문 등록 상태가 된다.
// 복수의 답변자들이 한 질문에 답변을 등록할 수 있고
// 1개의 답변이라도 등록되면 그때부터 답변 등록중 상태가 된다.
// 그 중 질문자가 원하는 답변을 채택하면 완료 상태가 된다.

// 돈이 충분치 않으면 충전기능을 이용해야한다. 답변이 채택되면 0.125eth를 돌려받는다.


// 모든 유저들은 이 시스템에 있는 질의응답들의 각 현황을 검색하여 찾아볼 수 있어야 하고,
// 또 자신이 한 질문이나 답변 역시 볼 수 있어야 한다. 

// +) 1분동안 답변이 등록되지 않으면 자동으로 취소상태로 변경되게 하시오.
// +) 10eth 이상 한번에 충전하면 금액의 10%를 보너스로 충전할 수 있게 하는 기능을 구현하시오.
// +) 해당 시스템의 지속가능성을 위해 질문, 답변시 요구되는 금액을 수정하시오.

contract QNA {
// 상태는 질문 등록, 취소, 답변 등록중, 완료가 있다.
    enum STATUS{
        ASK,
        CANCEL,
        REPLYING,
        COMPLETE
    }
// 게시판은 번호, 제목, 질문 내용, 질의자, 현재 상태 그리고 답변 내용과 답변자로 이루어져 있습니다.
    struct Board {
        uint number;
        string title;
        string content;
        address writer;
        STATUS status;
        uint[] pickedCmtIdxArr;
    }
    uint boardIdx;

    // boardIdx => Comment
    mapping(uint => Comment[]) commentMapping;
    // boardTitle => Board
    mapping(string => Board) boardMapping;

    struct Comment {
        address commenter;
        string title;
        string content;
    }

    struct User {
        address userAddr;
        uint[] myWriteList;
        //boardIdx => commentIdx
        mapping(uint => uint) myCommentList; 
    }

    mapping(address => User) UserMapping;

    function writeQNA(string memory _title, string memory _content) public payable{
// 질문할 때는 0.2eth가 요구된다.
        require(msg.value == 2*10**17, "PAY 0.2 ETH");
        boardIdx++;
        uint[] memory picked;
        boardMapping[_title] = Board(boardIdx, _title, _content, msg.sender, STATUS.ASK, picked);
        UserMapping[msg.sender].myWriteList.push(boardIdx);
    }

    function writeComment(string memory _boardTitle, string memory _title, string memory _content) public payable {
// 답변할 때는 0.1eth가 요구된다.
        require(msg.value == 1*10**17, "PAY 0.1 ETH");
        require(msg.sender != boardMapping[_boardTitle].writer, "WRTIER CANNOT REPLY");
        require(boardMapping[_boardTitle].status != STATUS.COMPLETE, "IT'S DONE");
        require(boardMapping[_boardTitle].status != STATUS.CANCEL, "IT WAS CANCELED");
        uint _boardIdx = boardMapping[_boardTitle].number;
        // 답변자는 한 질문에 대해 답변은 1개만 등록할 수 있다.
        require(UserMapping[msg.sender].myCommentList[_boardIdx] == 0, "YOU ALREADY REPLIED");
        commentMapping[_boardIdx].push(Comment(msg.sender, _title, _content));
        boardMapping[_boardTitle].status = STATUS.REPLYING;
    }

// 답변 채택은 오직 질문자만 가능하고 여러개의 답변을 채택할 수 있다. 
    function pickComment(string memory _boardTitle, uint commentIdx) public {
        require(msg.sender == boardMapping[_boardTitle].writer, "WRITER ONLY");
        boardMapping[_boardTitle].pickedCmtIdxArr.push(commentIdx);
        boardMapping[_boardTitle].status = STATUS.COMPLETE;
        //0.125TH 돌려주기
    }

// 질문자가 스스로 질문에 대한 답변이 필요없다고 느껴지면 취소할 수 있다.
    function cancelQNA(string memory _title) public {
        require(msg.sender == boardMapping[_title].writer, "WRTER ONLY");
// 하지만, 본인의 질문에 답변이 이미 달려있는 상태라면 취소할 수 없다. 
        require(boardMapping[_title].status == STATUS.ASK, "CANNOT CANCEL");
        boardMapping[_title].status = STATUS.CANCEL;
    }
}