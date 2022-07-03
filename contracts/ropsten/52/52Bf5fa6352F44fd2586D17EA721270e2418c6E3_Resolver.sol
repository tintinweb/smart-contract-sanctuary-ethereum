//SPDX-License-Identifier: GPL-3.0
pragma solidity  ^ 0.8.0 ;
interface IFakeNewsAPP {

    function calculateResult(uint256 id) external;
    function distribute(uint256 _id)external payable;


     function getArticles() external  view returns (uint256 [] memory );
     function getTime(uint256 id) external  view returns (uint256 );
     function getParticipants (uint256 id) external  view  returns ( address [] memory );
      function getVerdict(uint256 id) external view returns (bool);
     function getCurrentStatus(uint256 id) external view returns (uint8 stat);
}
contract Resolver  {

    address public immutable contract_add;
    //0xd5eF1ec8Cf69D2368c398F939D9a1B9c6D3a900f
    constructor(address _contract) {
        contract_add =  _contract;
    }

    function checker()
        external
        view
        returns (bool canExec, bytes memory execPayload)
       // returns(uint256 []  memory arr)
    {
        
       uint256[] memory ans =  IFakeNewsAPP(contract_add ).getArticles();
       
       for(uint256 i=0;i<ans.length;i++){
           if(IFakeNewsAPP(contract_add).getTime(ans[i])<=block.timestamp-300){
                execPayload = abi.encodeWithSelector(
                IFakeNewsAPP.calculateResult.selector,
                uint256(ans[i])
            );
            return (true, execPayload);
           }
          if(IFakeNewsAPP(contract_add).getTime(ans[i])>block.timestamp-300){
               return(false,bytes("Session is ongoing"));
           }

       }
  
}

     function distributor()
        external
        view
        returns (bool canExec, bytes memory execPayload)
       // returns(uint256 []  memory arr)
    {
        
       uint256[] memory ans =  IFakeNewsAPP(contract_add ).getArticles();
       
       for(uint256 i=0;i<ans.length;i++){
           if(IFakeNewsAPP(contract_add).getCurrentStatus(ans[i])==1){
                execPayload = abi.encodeWithSelector(
                IFakeNewsAPP.distribute.selector,
                uint256(ans[i])
            );
            return (true, execPayload);
           }
           if(IFakeNewsAPP(contract_add).getCurrentStatus(ans[i])!=1){
               return(false,bytes("Session is ongoing"));
           }

       }
       


    }

}