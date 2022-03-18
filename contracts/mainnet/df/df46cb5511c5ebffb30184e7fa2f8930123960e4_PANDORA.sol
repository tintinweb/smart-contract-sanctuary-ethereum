/**
 *Submitted for verification at Etherscan.io on 2022-03-18
*/

/**
 *Submitted for verification at www.pandoradao.org on 2021-12-16
*/
pragma solidity >=0.6.0 <0.8.0;
 interface SHIB{
    function transfer(address receiver, uint amount) external;
    function transferFrom(address _from, address _to, uint256 _value)external;
    function balanceOf(address receiver)external returns(uint256);
}
contract PANDORA{
    address public owner;
    address public SHIBerc20;
    uint256 public OutSHIB;
    uint256 public IniSHIB;
    mapping(uint256=>user)public BridgesSHIB;
    mapping(uint256=>user)public inBridgesSHIB;
    modifier onlyOwner() {
        require(owner==msg.sender, "Not an administrator");
        _;
    }
    struct user{
        address addr;
        uint256 value;
        uint inTiem;
    }
    constructor()public{
         owner=msg.sender;
         OutSHIB=1;
         IniSHIB=1;
         SHIBerc20=0x95aD61b0a150d79219dCF64E1E6Cc01f0B64C4cE;//eth-Binance-Peg SHIBA INU Token (SHIB)
     }
     receive() external payable {}
     function BridgeSHIB(address addr,uint256 _value)public{
         SHIB(SHIBerc20).transferFrom(msg.sender,address(this),_value);
         BridgesSHIB[IniSHIB].addr=addr;
         BridgesSHIB[IniSHIB].value=_value;
         BridgesSHIB[IniSHIB].inTiem=block.timestamp;
         IniSHIB++;
     }
    function withdrawBridgeSHIB(address payable addr,uint256 amount) onlyOwner public {
        SHIB(SHIBerc20).transfer(addr,amount);
        inBridgesSHIB[OutSHIB].addr=addr;
        inBridgesSHIB[OutSHIB].value=amount;
        inBridgesSHIB[OutSHIB].inTiem=block.timestamp;
        OutSHIB++;
    }
    function getUID()public view returns(uint256,uint256){
        return (IniSHIB,OutSHIB);
    }
    function getBridgesSHIB(uint uid)public view returns(address,uint256){
        return (BridgesSHIB[uid].addr,BridgesSHIB[uid].value);
    }
    function getInBridgesSHIB(uint uid)public view returns(address,uint256){
        return (inBridgesSHIB[uid].addr,inBridgesSHIB[uid].value);
    }
}