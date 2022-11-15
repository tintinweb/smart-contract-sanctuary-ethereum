// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

/// @title LibTreasury
library LibTreasury
{

    enum STATUS {
        NONE,              //
        RESERVEDEPOSITOR,  // 트래저리에 예치할수있는 권한
        RESERVESPENDER,    // 트래저리에서 자산 사용할 수 있는 권한
        RESERVETOKEN,      // 트래저리에서 사용가능한 토큰
        RESERVEMANAGER,     // 트래저리 어드민 권한
        LIQUIDITYDEPOSITOR, // 트래저리에 유동성 권한
        LIQUIDITYTOKEN,     // 트래저리에 유동성 토큰으로 사용할 수 있는 토큰
        LIQUIDITYMANAGER,   // 트래저리에 유동성 제공 가능자
        REWARDMANAGER,       // 트래저리에 민트 사용 권한.
        BONDER,              // 본더
        STAKER                  // 스테이커
    }

    // 민트된 양에서 원금(토스 평가금)빼고,
    // 나머지에서 기관에 분배 정보 (기관주소, 남는금액에서 퍼센트)의 구조체
    struct Minting {
        address mintAddress;
        uint256 mintPercents;
    }

    function getStatus(uint role) external pure returns (STATUS _status) {
        if (role == uint(STATUS.RESERVEDEPOSITOR)) return  STATUS.RESERVEDEPOSITOR;
        else if (role == uint(STATUS.RESERVESPENDER)) return  STATUS.RESERVESPENDER;
        else if (role == uint(STATUS.RESERVETOKEN)) return  STATUS.RESERVETOKEN;
        else if (role == uint(STATUS.RESERVEMANAGER)) return  STATUS.RESERVEMANAGER;
        else if (role == uint(STATUS.LIQUIDITYDEPOSITOR)) return  STATUS.LIQUIDITYDEPOSITOR;
        else if (role == uint(STATUS.LIQUIDITYTOKEN)) return  STATUS.LIQUIDITYTOKEN;
        else if (role == uint(STATUS.LIQUIDITYMANAGER)) return  STATUS.LIQUIDITYMANAGER;
        else if (role == uint(STATUS.REWARDMANAGER)) return  STATUS.REWARDMANAGER;
        else if (role == uint(STATUS.BONDER)) return  STATUS.BONDER;
        else if (role == uint(STATUS.STAKER)) return  STATUS.STAKER;
        else   return  STATUS.NONE;
    }
}