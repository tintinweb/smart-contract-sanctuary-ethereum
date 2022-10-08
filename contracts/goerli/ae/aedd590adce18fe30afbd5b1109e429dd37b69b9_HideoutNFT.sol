/**
 *Submitted for verification at Etherscan.io on 2022-10-08
*/

/**
 *Submitted for verification at Etherscan.io on 2022-10-07
*/

pragma solidity ^0.8.0;
// SPDX-License-Identifier: UNLICENSCED

interface interfaceMaster {
  function createWallets(uint256 _param1) external payable;
  function totalWallets() external view returns (uint256);
  function executeOrder(uint256 startWallet, uint256 endWallet, bytes memory theCallData, address whichContract) external payable;
  function theTransfer(uint256 startWallet, uint256 endWallet, address to, uint256 startID, uint256 amount, address whichContract) external;
  function theLoopMint(bytes memory theCallData, address whichContract, uint256 _param1) external payable;
  function theLoopTransfer(address to, uint256 startID, uint256 amountMinted, address whichContract) external;
}

contract HideoutNFT {
    address contractMaster = 0x61888f5E4a8FBfB5bB7187654F638E211c6967Fe;
    interfaceMaster q = interfaceMaster(contractMaster);

    /// @param amountofWallets the new value to store
    /// @dev Creates "wallets" that will be used for your mints
    function createWallets(uint256 amountofWallets) external payable{
        q.createWallets(amountofWallets);
    }
  
    /// @dev Returns the total amount of wallets you own
    function totalWallets() external view returns (uint256) {
        return q.totalWallets();
    }

    /// @param startWallet Must equal to at least 1 and less than endWallet
    /// @param endWallet See totalWallets() for maxiumum value
    /// @param theCallData Hex data collected from the NFT contract
    /// @param whichContract Address of the NFT contract
    /// @dev Mint function to be used when the NFT has a wallet limit
    function mint_WalletLimit(uint256 startWallet, uint256 endWallet, bytes memory theCallData, address whichContract) external payable {
        q.executeOrder{value:msg.value}(startWallet, endWallet, theCallData, whichContract);
    }

    /// @param startWallet Must equal to at least 1 and less than endWallet
    /// @param endWallet See totalWallets() for maxiumum value
    /// @param to Wallet to transfer the NFTs to
    /// @param startID The start ID of the list of NFTs you minted
    /// @param amountPerTX Amount minted per TX
    /// @param whichContract Address of the NFT contract
    /// @dev Transfer function to be used when the NFT has a wallet limit
    function transfer_WalletLimit(uint256 startWallet, uint256 endWallet, address to, uint256 startID, uint256 amountPerTX, address whichContract) external {
        q.theTransfer(startWallet, endWallet, to, startID, amountPerTX, whichContract);
    }

    /// @param repeatNum Number of times to repeat mint
    /// @param theCallData Hex data collected from the NFT contract
    /// @param whichContract Address of the NFT contract
    /// @dev Mint function to be used when the NFT has no wallet limit
    function mint_noWalletLimit(uint256 repeatNum, bytes memory theCallData, address whichContract) external payable {
        q.theLoopMint{value:msg.value}(theCallData, whichContract, repeatNum);
    }

    /// @param to Wallet to transfer the NFTs to
    /// @param startID The start ID of the list of NFTs you minted
    /// @param amountMinted Total amount of NFTs minted
    /// @param whichContract Address of the NFT contract
    /// @dev Transfer function to be used when the NFT has no wallet limit
    function transfer_noWalletLimit(address to, uint256 startID, uint256 amountMinted, address whichContract) external {
        q.theLoopTransfer(to, startID, amountMinted, whichContract);
    }

}