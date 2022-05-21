/**
 *Submitted for verification at Etherscan.io on 2022-05-21
*/

// File: github/sherzed/solidityProject-1/work4.sol


pragma solidity ^0.8.7;
interface AirConditioings {
    function getAcDetail(uint256 acId) external view returns (address,uint256,uint256);
    function setAdmin(uint256 acId, uint256 tokenValue) external;
    function setDegree(uint256 acId, uint256 _degree) external;
    event AC_Owner_Changed(address newOwner, uint256 ac_changed);
    event AC_Degree_Changed(uint256 ac_changed,uint256 newDegree);
}
contract SetAirConditioing is AirConditioings {
    uint256 [4] paidToken; uint256 [4] ac_degree; address [4] wallet;

    function getAcDetail(uint256 acId) public view override returns (address,uint256,uint256) {
        return (wallet[acId],paidToken[acId],ac_degree[acId]);
    }

    function setAdmin(uint256 acId, uint256 tokenValue) public override {
        require(acId<4,"We only have 4 air conditioners :( Please choose between 1-4.");
        require(paidToken[acId]<tokenValue,"Don't be afraid to take risks, increase the price :)");
        wallet[acId]= msg.sender;
        paidToken[acId] = tokenValue;
        emit AC_Owner_Changed(msg.sender,acId);
    }

    function setDegree(uint256 acId, uint256 _degree) public override {
        require(acId<4,"We only have 4 air conditioners :( Please choose between 1-4.");
        require(wallet[acId] == msg.sender, "The owner of the air conditioner does not appear here.");
        require(_degree>15&&_degree<33,"Values must be between 16-30.");
        ac_degree[acId]=_degree;
        emit AC_Degree_Changed(acId,ac_degree[acId]);
    }
 }