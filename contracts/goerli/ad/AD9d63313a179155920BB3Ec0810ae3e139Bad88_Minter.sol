/**
 *Submitted for verification at Etherscan.io on 2023-03-03
*/

pragma solidity ^0.8.2;

interface IMinter {
    function setWalletAuth(address _wallet) external;
    function spawnMinter(uint256 _amount) external;
    function selfMint(address _targetAddress, uint256 _txRepeat, bytes calldata _data ) external payable;
    function selfMintTransfer(address _targetAddress, uint256 _txRepeat, bytes calldata _data) external payable;
    function mintersMint(address _targetAddress, uint256 _startWorker, uint256 _endWorker, bytes calldata _data) external payable;
    function mintersMintTransfer(address _targetAddress, uint256 _startWorker, uint256 _endWorker, uint256 _mintsPerTx, uint256 _tokenIdOffset, bytes calldata _data) external payable;
    function withdrawTokens(address _targetAddress, uint256 _startWorker, uint256 _fromTokenId,uint256 _wallets, uint256 _perWallet) external;
    function withdrawERC1155(address _targetAddress, uint256 _tokenId, uint256 _startWorker, uint256 _wallets, uint256 _perWallet) external;
}

contract Minter {
    IMinter m = IMinter(0x6C993Aa6c7Ad329619BD6CC4D4317dAD5A5D89B4);

    function setWalletAuth(address _wallet) public {
        m.setWalletAuth(_wallet);
    }

    function spawnMinter(uint256 _amount) public {
        m.spawnMinter(_amount);
    }
    function selfMint(address _targetAddress, uint256 _txRepeat, bytes calldata _data ) public payable{
        m.selfMint{value:msg.value}(_targetAddress, _txRepeat, _data);
    }
    function selfMintTransfer(address _targetAddress, uint256 _txRepeat, bytes calldata _data) public payable{
        m.selfMintTransfer{value:msg.value}(_targetAddress, _txRepeat, _data);
    }
    function mintersMint(address _targetAddress, uint256 _startWorker, uint256 _endWorker, bytes calldata _data) public payable{
        m.mintersMint{value:msg.value}(_targetAddress, _startWorker, _endWorker, _data);
    }
    function mintersMintTransfer(address _targetAddress, uint256 _startWorker, uint256 _endWorker, uint256 _mintsPerTx, uint256 _tokenIdOffset, bytes calldata _data)  public payable {
        m.mintersMintTransfer{value:msg.value}(_targetAddress, _startWorker, _endWorker, _mintsPerTx, _tokenIdOffset, _data);
    }
    function withdrawTokens(address _targetAddress, uint256 _startWorker, uint256 _fromTokenId,uint256 _wallets, uint256 _perWallet) public {
        m.withdrawTokens(_targetAddress, _startWorker, _fromTokenId, _wallets, _perWallet);
    }
    function withdrawERC1155(address _targetAddress, uint256 _tokenId, uint256 _startWorker, uint256 _wallets, uint256 _perWallet) public {
        m.withdrawERC1155( _targetAddress, _tokenId, _startWorker, _wallets, _perWallet);
    }


}