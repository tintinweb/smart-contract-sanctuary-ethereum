/**
 *Submitted for verification at Etherscan.io on 2022-06-22
*/

pragma solidity ^0.4.11;

contract voteContract {

    mapping (address => bool) voters; // 每個賬戶只能投一票
    mapping (string => uint) candidates; // 保存投票數
    mapping (uint8 => string) candidateList; // 候選人名單

    uint8 numberOfCandidates; // 候選人總數
    address contractOwner;

    function voteContract() {
        // 將創建合同的人保存為contractOwner
        contractOwner = msg.sender;
    }

    // 添加候選人的功能
    function addCandidate(string cand) {
        bool add = true;
        for (uint8 i = 0; i < numberOfCandidates; i++) {
        
            // 字符串比較可以通過散列函數 (sha3) 完成。
            // Solidity 中沒有用於字符串比較的特殊函數。
            if (sha3(candidateList[i]) == sha3(cand)) {
                add = false; break;
            }
        }

        if (add) {
            candidateList[numberOfCandidates] = cand;
            numberOfCandidates++;
        }
    }

// 投票函數
    function vote(string cand) {
        // 一個帳戶只反映結果中的一票
        if (voters[msg.sender]) { }
        else {
            voters[msg.sender] = true;
            candidates[cand]++;
        }
    }

// 檢查是否已經投票
    function alreadyVoted() constant returns(bool) {
        if (voters[msg.sender])
            return true;
        else
            return false;
    }

// 返回候選的數量
    function getNumOfCandidates() constant returns(uint8) {
        return numberOfCandidates;
    }

// 返回數字對應的候選人姓名
    function getCandidateString(uint8 number) constant returns(string) {
        return candidateList[number];
    }

// 返回候選人的票數
    function getScore(string cand) constant returns(uint) {
        return candidates[cand];
    }

// 刪除合約
    function killContract() {
        if (contractOwner == msg.sender)
            selfdestruct(contractOwner);
    }
}