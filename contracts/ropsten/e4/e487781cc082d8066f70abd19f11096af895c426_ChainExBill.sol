/**
 *Submitted for verification at Etherscan.io on 2022-05-11
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

struct Bill {
    address writerAddress;          // 작성자 주소
    Country country;
    Place place;
    Distance distance;
    Product product;
    string[] mkt;                   // MKT
    string[] temperature;           // 온도
    string[] humidity;              // 습도
    Delivery delivery;
    Agenct agent;
    uint256 createdDate;            // 작성시간
}

struct Country {
    string departureCountry;        // 출발국가
    string arrivalCountry;          // 도착국가
}

struct Place {
    string departurePlace;          // 출발지
    string arrivalPlace;            // 도착지
}

struct Product {
    string storageCondition;        // 보관조건
    string productName;             // 제품명
    uint256 amount;                 // 수량
}

struct Distance {
    string estimatedDistance;       // 예상 거리
    string traveledDistance;        // 실제 거리
}

struct Delivery {
    string deliverier;              // 배송기사
    string deliverierTel;           // 배송기사 연란처
    string shippingVehicleNumber;   // 배송 차량 번호
}

struct Agenct {
    string name;                    // 담당자 명
    string memo;                    // 메모
    string specificMemo;            // 특이사항
}

struct RequestBill {
    Country country;
    Place place;
    Distance distance;
    Product product;
    string[] mkt;                   // MKT
    string[] temperature;           // 온도
    string[] humidity;              // 습도
    Delivery delivery;
    Agenct agent;
}

contract ChainExBill {
    event Regist(uint256 indexed index, address indexed writer, uint256 timestamp);
    uint256 private _billIndex = 0;
    mapping(uint256 => Bill) public _bills;

    function regist(Country memory country, Place memory place, Distance memory distance,
                    Product memory product, string[] memory mkt, string[] memory temperature, 
                    string[] memory humidity, Delivery memory delivery, Agenct memory agent) public {
        uint256 index = ++_billIndex;
        _bills[index].writerAddress = msg.sender;
        _bills[index].country = country;
        _bills[index].place = place;
        _bills[index].distance = distance;
        _bills[index].product = product;
        _bills[index].mkt = mkt;
        _bills[index].temperature = temperature;
        _bills[index].humidity = humidity;
        _bills[index].delivery = delivery;
        _bills[index].agent = agent;
        _bills[index].createdDate = block.timestamp;

        emit Regist(index, msg.sender, block.timestamp);
    }

    // function regist(RequestBill memory request) public {
    //     uint256 index = ++_billIndex;
    //     _bills[index].writerAddress = msg.sender;
    //     _bills[index].country = request.country;
    //     _bills[index].place = request.place;
    //     _bills[index].distance = request.distance;
    //     _bills[index].product = request.product;
    //     _bills[index].mkt = request.mkt;
    //     _bills[index].temperature = request.temperature;
    //     _bills[index].humidity = request.humidity;
    //     _bills[index].delivery = request.delivery;
    //     _bills[index].agent = request.agent;
    //     _bills[index].createdDate = block.timestamp;

    //     emit Regist(index, msg.sender, block.timestamp);
    // }

    function getLastIndex() public view returns (uint256) {
        return _billIndex;
    }

}