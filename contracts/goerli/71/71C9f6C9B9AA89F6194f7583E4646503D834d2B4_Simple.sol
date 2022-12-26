//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Simple {
    uint[] array;
    
    function getArraylength() public view returns(uint) {
        return array.length;
    }

    function pushArray(uint _a) public {
        array.push(_a);
    }

    function getValue(uint a, uint b) public view returns (uint) {
            if (a > b) {
            return a;
            } else {
            return b;
            }
}
}


// 상태변수 1개 -> uint가 들어가는 array
// 상태변수를 호출하는 함수 1개 -> array의 length;
// 상태변수를 변경하는 함수 1개 -> array에 값 넣기
// 2개의 input 값을 받아 더 큰 함수를 반환시키는 함수(크기 비교 함수)

// 1. Compile 후, 한쪽에는 ABI가 보이는 json // 한쪽에는 sol 코드가 보이게 하고 밑의 terminal에는 compile 명령어
// 2. Localhost에 배포 후, 한쪽에는 deploy.js // 한쪽에는 hardhat.config.js // 밑의 terminal에서는 한쪽에는 같은 컨트랙트를 4번 실행(2번은 그냥, 2번은 localhost에) // 한쪽에는 hardhat. node 실행 -> 주소 변화 강조하면 더 좋음
// 3. goerli에 배포 후, etherscan에서 배포 확인(code 등록 안된 것 확인) hardhat.config.js // terminal 배포 명령어 
// 4. Verify 후, etherscan에서 코드 등록 화면 // terminal verify 명령어 확인 // hardhat.config.js
// 5. Terminal로 컨트랙트와 상호작용 (명령어 전체와 getA() 1번, setA() 1번[1,2,3 넣기], 다시 getA() 1번 결과들 + setA()에 대한 캡쳐 - 거래내역)
// 6.  .env와 상호작용 후, interact.js 파일(크기 비교 함수 1번, setA() 1번[4,5,6 넣기], getA()1번 결과물 - 터미널), env 파일  + setA()에 대한 캡쳐 - 거래내역
// 7. 터미널에서 2번 지갑으로 돈 보내기 후, 터미널과 etherscan 결과 캡쳐
// 8. 파일 만들어서(transfer.js)[tx 결과는 터미널에서 보여주기] 2번 지갑으로 돈 보내기 후, transfer.js 코드와 터미널과 etherscan 결과 캡쳐