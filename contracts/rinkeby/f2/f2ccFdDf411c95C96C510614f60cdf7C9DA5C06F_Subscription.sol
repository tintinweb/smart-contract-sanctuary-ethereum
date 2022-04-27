// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Subscription {
  address owner;
  mapping (address => uint) endAt;
  mapping (address => bool) isFreeCouponUsed;

  enum Plans {
    OPTION0, // 첫 가입시 옵션
    OPTION1, // 구매권 옵션1
    OPTION2, // 구매권 옵션2
    OPTION3 // 구매권 옵션3
  }

  constructor() {
    owner = msg.sender;
  }

  // 구독권 구매 함수
  function buy (Plans plan) external payable {
    require(msg.value >= getPrice(plan)); // 구독권 구매 금액 확인
    if (plan == Plans.OPTION0) {  // 무료 쿠폰 사용하는 경우에는
      require(!isFreeCouponUsed[msg.sender], "Free coupon is already used"); // 무료 쿠폰 사용 여부 확인
    }
    if (endAt[msg.sender] > block.timestamp) { // 이용 중인 경우는 기간 연장
      endAt[msg.sender] += getDuration(plan);
    } else { // 만료 되면 현재 시간에서부터 구독기간 시작
      uint startAt = block.timestamp; // 현재 시간
      endAt[msg.sender] = startAt + getDuration(plan);
    }
    payable(owner).transfer(msg.value); // 구매한 금액 우리가 받아가기
    if (plan == Plans.OPTION0) {  // 쿠폰으로 구매한 경우
      isFreeCouponUsed[msg.sender] = true; // 사용했다고 수정
    }
  }
  
  // Plan에 따른 가격
  function getPrice (Plans plan) public pure returns(uint) {
    if(plan == Plans.OPTION0) {
      return 0 ether; // 첫 가입시에는 무료
    } else if (plan == Plans.OPTION1) {
      return 0.01 ether;
    } else if (plan == Plans.OPTION2) {
      return 0.02 ether;
    } else if (plan == Plans.OPTION3) {
      return 0.03 ether;
    } else {
      revert("Cannot get price for wrong plan");
    }
  }

  // Plan에 따른 구독 기간 
  function getDuration (Plans plan) public pure returns(uint) {
    if(plan == Plans.OPTION0) {
      return 30 days;
    } else if (plan == Plans.OPTION1) {
      return 30 days;
    } else if (plan == Plans.OPTION2) {
      return 90 days;
    } else if (plan == Plans.OPTION3) {
      return 180 days;
    } else {
      revert("Cannot get duration for wrong plan");
    }
  }
  
  // 구독 종료 시간 불러오기
  function getEndAt (address user) public view returns(uint) {
    return endAt[user];
  }

  // 구독 종료 시간 불러오기
  function getIsFreeCouponUsed (address user) public view returns(bool) {
    return isFreeCouponUsed[user];
  }
}