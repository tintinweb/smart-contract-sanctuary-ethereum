//SPDX-License-Identifier:MIT


// Specifies the version of Solidity, using semantic versioning.
// Learn more: https://solidity.readthedocs.io/en/v0.5.10/layout-of-source-files.html#pragma


pragma solidity >= 0.7.3;
//HellowWorld 컨트렉트 이름의 계약 정의
//계약은 함수와 데이터의 모음입니다. 일단 배포되면 계약은 이더리움 블록체인의 특정주소에 있습니다.
contract HelloWorld {

    //업데이트 함수 호출 시 발생하는 이벤트

    //스마트 계약 이벤트는 특정 이벤트를 '수신' 하고 이벤트가 발생하면 조치를 취할 수 있는 
    //프론트엔드에 블록체인에서 어떤 일이 발생했음을 계약이 전달하는 방법

    //이벤트로는 업데이트 메세지 선언
    event UpdatedMessages(string oldStr, string newStr);

    //상태 변수는 값이 계약 저장소에 영구적으로 저장되는 변수
    //public 키워드로 인한 계약 외부에서 변수에 엑세스할 수 있게 한다.
    //다른 계약이나 클라이언트가 값에 엑세스하기 위해 호출 할 수 있는 함수를 만듭니다.
    string public message;
    
    //생성자는 계약 생성 시에만 실행되는 특수함수 / 계약의 데이터를 초기화 하는데 사용
    constructor (string memory initMessage){
        //문자열 인수 initMessage를 수락하고 값을 계약의 message 저장변수로 설정
        message = initMessage;
    }
    // 문자열 인수를 받아들이고 message 저장 변수를 업데이트하는 공개함수
    function update(string memory newMessage) public{
        string memory oldMsg = message;
        message = newMessage;
        emit UpdatedMessages(oldMsg, newMessage);
    }
}