// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;


// Safe Fees Payment ---* Transfer USDC from Safe Account to Account Advisor *--- //

contract FeesPayment {

    address usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48; // mainnet

    function payAdvisorFeeUSDC(
        address _onBehalf, 
        uint _amount,
        uint __placeholder,
        bytes calldata _data
    ) 
        public 
        returns (bytes memory txData) 
    {
        (address comptroller) = abi.decode(_data,(address));

        address usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48; // mainnet

        // Get user Id
        uint userId = IComp(comptroller).getUserIdFromSafeAddress(_onBehalf);
        address _receiver = IComp(comptroller).getAdvisorAddress(IComp(comptroller).getAccountAdvisor(userId,_onBehalf));
        
        // Pay fee
        txData = abi.encodePacked(uint8(0),usdc,uint256(0),uint256(68),abi.encodeWithSignature(
                "transfer(address,uint256)", _receiver, _amount));
    
        return txData;
    }

}


interface IComp{
    function getUserIdFromSafeAddress(address _address) external view returns (uint); 
    function getAccountAdvisor(uint _userId, address account) 
        external
        view
        returns (uint256);
    function getAdvisorAddress(uint _advisorId) 
        external
        view
        returns (address);
}