pragma solidity ^0.8.0;
// SPDX-License-Identifier: UNLICENSCED

interface interfaceMaster {
  function createWallets() external payable;
  function totalWallets(address theAddress) external view returns (uint256);
  function listWallets(address theAddress) view external returns (address[] memory);
  function executeOrder(uint256 startWallet, uint256 endWallet, bytes calldata theCallData, address whichContract) external payable;
  function specialMint(uint256 startWallet, uint256 endWallet, bytes[] calldata theCallData, address whichContract) external payable;
  function specialMintTwo(bytes[] calldata theCallData, address whichContract) external payable;
  function theTransfer(uint256 startWallet, uint256 endWallet, address to, uint256 startID, uint256 amount, address whichContract) external;
  function theLoopMint(bytes calldata theCallData, address whichContract, uint256 _param1) external payable;
  function theLoopTransfer(address to, uint256 startID, uint256 amountMinted, address whichContract) external;
  function theTransferElevenFiftyFive(uint256 startWallet, uint256 endWallet, address to, uint256[] memory tokenIds, uint256[] memory amounts, address whichContract) external;
  function theLoopTransferElevenFiftyFive(address to, uint256[] memory tokenIds, uint256[] memory amounts, address whichContract) external;
}

contract ThanksNFT {
    address contractMaster = 0x683E9b995ef6DcFf994b656b184662dD9FE44D67;
    interfaceMaster q = interfaceMaster(contractMaster);

    /**
    * @dev Creates "wallets" that will be used for your mints
    */
    function createWallets() external payable{
        q.createWallets{value:msg.value}();
    }

    /**
    * @dev Returns the total amount of wallets you own
    */
    function totalWallets(address theAddress) external view returns (uint256) {
        return q.totalWallets(theAddress);
    }

    /**
    * @dev Returns list of wallets you own
    */
    function listWallets(address theAddress) external view returns (address[] memory) {
        return q.listWallets(theAddress);
    }

    /**
    * @dev Mint function to be used when the NFT has a wallet limit
    * @param startWallet Must equal to at least 0 and less than endWallet
    * @param endWallet See totalWallets() for maximum value
    * @param theCallData Hex data collected from the NFT contract
    * @param nftContract Address of the NFT contract
    */
    function mint_WalletLimit(uint256 startWallet, uint256 endWallet, bytes calldata theCallData, address nftContract) external payable {
        q.executeOrder{value:msg.value}(startWallet, endWallet, theCallData, nftContract);
    }

    /**
    * @dev Mint function to be used when different calldata is used each wallet
    * @param startWallet Value used in mint function
    * @param endWallet Value used in mint function
    * @param theCallData Array of calldata
    * @param nftContract Address of the NFT contract
    */
    function mint_WalletLimitSpecial(uint256 startWallet, uint256 endWallet, bytes[] calldata theCallData, address nftContract) external payable {
        q.specialMint{value:msg.value}(startWallet, endWallet, theCallData, nftContract);
    }

    /**
    * @dev Transfer function to be used when the NFT has a wallet limit
    * @param startWallet Value used in mint function
    * @param endWallet Value used in mint function
    * @param to Wallet to transfer the NFTs to
    * @param startID The start ID of the list of NFTs you minted
    * @param amountPerTX Amount minted per TX
    * @param nftContract Address of the NFT contract
    */
    function transfer_WalletLimit(uint256 startWallet, uint256 endWallet, address to, uint256 startID, uint256 amountPerTX, address nftContract) external {
        q.theTransfer(startWallet, endWallet, to, startID, amountPerTX, nftContract);
    }
    

    /**
    * @dev Mint function to be used when the NFT has no wallet limit
    * @param repeatNum Number of times to repeat mint
    * @param theCallData Hex data collected from the NFT contract
    * @param nftContract Address of the NFT contract
    */
    function mint_noWalletLimit(uint256 repeatNum, bytes calldata theCallData, address nftContract) external payable {
        q.theLoopMint{value:msg.value}(theCallData, nftContract, repeatNum);
    }

    /**
    * @dev Mint function to be used when different calldata is used each transaction
    * @param theCallData Array of calldata
    * @param nftContract Address of the NFT contract
    */
    function mint_noWalletLimitSpecial(bytes[] calldata theCallData, address nftContract) external payable {
        q.specialMintTwo{value:msg.value}(theCallData, nftContract);
    }


    /**
    * @dev Transfer function to be used when the NFT has no wallet limit
    * @param to Wallet to transfer the NFTs to
    * @param startID The start ID of the list of NFTs you minted
    * @param amountMinted Total amount of NFTs minted
    * @param nftContract Address of the NFT contract
    */
    function transfer_noWalletLimit(address to, uint256 startID, uint256 amountMinted, address nftContract) external {
        q.theLoopTransfer(to, startID, amountMinted, nftContract);
    }

    /**
    * @dev Transfer function to be used when the NFT has no wallet limit (ERC-1155)
    * @param to Wallet to transfer the NFTs to
    * @param tokenIds Array of tokenIds
    * @param amounts Array of amounts
    * @param nftContract Address of the NFT contract
    */
    function transfer_noWalletLimit1155(address to, uint256[] memory tokenIds, uint256[] memory amounts, address nftContract) external {
        q.theLoopTransferElevenFiftyFive(to, tokenIds, amounts, nftContract);
    }

    /**
    * @dev Transfer function to be used when the NFT has a wallet limit (ERC-1155)
    * @param startWallet Value used in mint function
    * @param endWallet Value used in mint function
    * @param to Wallet to transfer the NFTs to
    * @param tokenIds Array of tokenIds
    * @param amounts Array of amounts
    * @param nftContract Address of the NFT contract
    */
    function transfer_WalletLimit1155(uint256 startWallet, uint256 endWallet, address to, uint256[] memory tokenIds, uint256[] memory amounts, address nftContract) external {
        q.theTransferElevenFiftyFive(startWallet, endWallet, to, tokenIds, amounts, nftContract);
    }
}