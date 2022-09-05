// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


contract getprice {

struct priceData {
    uint256 id;
    uint256 priceLatest;
}
priceData[] PD;

constructor() {
    PD.push(priceData(1,123));
    PD.push(priceData(2,223));
    PD.push(priceData(3,323));
}
function getPrice(uint256 _id) public view returns(uint256) {
    return PD[_id].priceLatest;
}    
}