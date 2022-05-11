/**
 *Submitted for verification at Etherscan.io on 2022-05-11
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract ChainExBill {

    // 최대 15개까지 컴파일 에러가 발생하지 않음
    struct Bill {
        address writerAddress;          // 작성자 주소
        string departureCountry;        // 출발국가
        string arrivalCountry;          // 도착국가
        string agenct;                  // agent
        string departurePlace;          // 출발지
        string arrivalPlace;            // 도착지
        string estimatedDistance;       // 예상 거리
        string productName;             // 제품명
        string storageCondition;        // 보관조건
        uint256 amount;                 // 수량
        Bill2 Bill2;
    }

    struct Bill2 {
        string[] mkt;                   // MKT
        string[] temperature;           // 온도
        string[] humidity;              // 습도
        string deliverier;              // 배송기사
        string deliverierTel;           // 배송기사 연란처
        string shippingVehicleNumber;   // 배송 차량 번호
        string wroteTime;               // 작성시간
        string writer;                  // 작성자
        string memo;                    // 메모
        string specificMemo;            // 특이사항
    }

    uint256 private _billIndex = 0;
    mapping(uint256 => Bill) public _bills;
    
// 
// 함수의 매개변수 인자 수는 최대 11개 
    // function regist(string memory departureCountry, string memory arrivalCountry, string memory agenct,
    //                 string memory departurePlace, string memory arrivalPlace, string memory estimatedDistance,
    //                 string memory productName, string memory storageCondition, uint256 amount,
    //                 string[] memory mkt, string[] memory temperature, string[] memory humidity
    // ) public {

    //     uint256 index = ++_billIndex;

    //     _bills[index].writerAddress = msg.sender;
    //     _bills[index].departureCountry = departureCountry;
    //     _bills[index].arrivalCountry = arrivalCountry;
    //     _bills[index].agenct = agenct;
    //     _bills[index].departurePlace = departurePlace;
    //     _bills[index].arrivalPlace = arrivalPlace;
    //     _bills[index].estimatedDistance = estimatedDistance;
    //     _bills[index].productName = productName;
    //     _bills[index].storageCondition = storageCondition;
    //     _bills[index].amount = amount;
    //     _bills[index].mkt = mkt;
    //     _bills[index].temperature = temperature;
    //     _bills[index].humidity = humidity;

    // }
    

    function regist(Bill memory bill) public {
        uint256 index = ++_billIndex;
        _bills[index] = bill;
    }


}