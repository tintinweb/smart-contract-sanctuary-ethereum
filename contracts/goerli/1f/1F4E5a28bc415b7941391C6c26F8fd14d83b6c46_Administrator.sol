/**
 *Submitted for verification at Etherscan.io on 2023-01-11
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.22 <0.9.0;

// import "./ProjectFunding.sol";
// import "./ChangesFunding.sol";

contract Administrator {
    address owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    struct Donator { // 기부자 정보
        address donatorAddr;
        string[] myDonatedPFList; // 기부한 프로젝트 펀딩 리스트 (DB의 ID)
        string[] myDonatedCFList; // 기부한 잔돈 펀딩 컨트랙트 리스트
    }

    mapping (address => Donator) donators; // 기부자들 모음

    // 기부자 등록 -> 맨 처음 기부할 때 한 번만
    function setDonator(address _addr) public {
        if(donators[_addr].donatorAddr == address(0)) {
            donators[_addr].donatorAddr = _addr;
        }
    }

    function getDonator(address _addr) public view returns (Donator memory) {
        return donators[_addr];
    }

    // 기부 시 기부한 펀딩 리스트에 추가(ProjectFunding 컨트랙트에서 사용)
    function addDonatedPFList(address _addr, string memory _docId) public {
        donators[_addr].myDonatedPFList.push(_docId);
    }

    function addDonatedCFList(address _addr, string memory _docId) public { // (ChangesFunding 컨트랙트에서 사용)
        donators[_addr].myDonatedCFList.push(_docId);
    }

    // 기부한 프로젝트 펀딩 컨트랙트 리스트 출력
    function getDonatedPFList(address _addr) public view returns (string[] memory) {
        return donators[_addr].myDonatedPFList;
    }

    function getDonatedCFList(address _addr) public view returns (string[] memory) {
        return donators[_addr].myDonatedCFList;
    }

    // 컨트랙트 쌓인 잔고 보여주는 함수
    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    // 컨트랙트 쌓인 잔고 출금 함수 (오직 owner만)
    function withdrawMoney(address payable _to, uint _amount) public onlyOwner {
        require(getBalance() > _amount);
        _to.transfer(_amount);
    }

    receive() external payable {} // admin 컨트랙트를 payable하게 바꾸어주는 코드
}