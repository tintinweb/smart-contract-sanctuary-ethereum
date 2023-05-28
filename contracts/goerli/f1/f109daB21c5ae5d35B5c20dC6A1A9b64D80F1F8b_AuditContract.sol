/**
 *Submitted for verification at Etherscan.io on 2023-05-28
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

// 감사 보고서 구조체
struct AuditReport {
    string reportHash;      // 보고서 해시값
    string reportContent;   // 보고서 내용
    address auditor;        // 감사자 주소
    uint256 timestamp;      // 작성 시간
}

// 감사 대상 구조체
struct AuditTarget {
    string targetHash;      // 대상 해시값
    string targetContent;   // 대상 내용
    AuditReport[] reports;  // 보고서 리스트
}

// 감사 스마트 컨트랙트
contract AuditContract {
    mapping (string => AuditTarget) private targets;    // 감사 대상 매핑
    mapping(address => uint256) public balances;        // 토큰 발행 및 잔액 관리를 위한 변수

    string public TokenName;
    string public TokenSymbol;
    uint256 public TotalSupply;

    // 감사 대상 등록
    function registerTarget(string memory targetHash, string memory targetContent) public {
        require(bytes(targetHash).length != 0, "Invalid target hash value.");
        require(bytes(targetContent).length != 0, "Invalid target content.");

        AuditTarget storage target = targets[targetHash];
        target.targetHash = targetHash;
        target.targetContent = targetContent;
    }

    // 감사 보고서 작성 및 등록
    function writeReport(string memory targetHash, string memory reportHash, string memory reportContent) public {
        require(bytes(targetHash).length != 0, "Invalid target hash value.");
        require(bytes(reportHash).length != 0, "Invalid report hash value.");
        require(bytes(reportContent).length != 0, "This is an invalid report.");

        AuditTarget storage target = targets[targetHash];
        require(bytes(target.targetHash).length != 0, "Target does not exist.");

        AuditReport memory report;
        report.reportHash = reportHash;
        report.reportContent = reportContent;
        report.auditor = msg.sender;
        report.timestamp = block.timestamp;

        target.reports.push(report);
    }

    // 감사 보고서 검증
    function verifyReport(string memory targetHash, string memory reportHash) public view returns (bool) {
        require(bytes(targetHash).length != 0, "Invalid target hash value.");
        require(bytes(reportHash).length != 0, "Invalid report hash value.");

        AuditTarget storage target = targets[targetHash];
        require(bytes(target.targetHash).length != 0, "Target does not exist.");

        for (uint i = 0; i < target.reports.length; i++) {
            if (keccak256(bytes(target.reports[i].reportHash)) == keccak256(bytes(reportHash))) {
                return true;
            }
        }

        return false;
    }

    // 토큰 파라미터 설정
    function registerToken(string memory name, string memory symbol, uint256 totalSupply, uint256 decimals) public {
        require(bytes(name).length != 0, "Invalid token name.");
        require(bytes(symbol).length != 0, "Invalid token symbol.");
        require(totalSupply > 0, "Total invalid supply.");

        TokenName = name;
        TokenSymbol = symbol;
        TotalSupply = totalSupply;
        decimals = decimals;

        balances[msg.sender] = totalSupply;
    }
}