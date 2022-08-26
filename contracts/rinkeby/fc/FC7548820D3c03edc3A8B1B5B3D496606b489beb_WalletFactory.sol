pragma solidity ^0.8.9;
import './MultiSigWallet.sol';
contract WalletFactory{
    event newWalletEvent(address addr);
    event params(address[] owners,uint confirmed);
    address[] public wallets;
    mapping(address=>address[]) walletMap;
    function createWallet(address[] memory owners,uint confirmNeed) external returns(address){
        //bytes memory codes=type(MultiSigWallet).creationCode;
        emit params(owners, confirmNeed);
        bytes32 salt=keccak256(abi.encodePacked(owners,confirmNeed,block.timestamp));
        MultiSigWallet wallet=new MultiSigWallet{salt:salt}();
        wallet.initialize(owners,confirmNeed);
        address walletAddr=address(wallet);
        wallets.push(walletAddr);
        emit newWalletEvent(walletAddr);
        for(uint i=0;i<owners.length;i++){
            require(owners[i]!=address(0));
            walletMap[owners[i]].push(walletAddr);
        }
        return walletAddr;
    }
    function getLatestWallet(address creator) external view returns(address){
        if(walletMap[creator].length>0){
            return walletMap[creator][walletMap[creator].length-1];
        }
        return address(0);
    }
}