/**
 *Submitted for verification at Etherscan.io on 2023-02-19
*/

pragma solidity ^0.8.0;

interface IMaster {
    function add(address theAddress) external;

    function remove(address theAddress) external;

    function setPrice(uint256 thePrice) external;

    function thePrice() external view returns (uint256);

    function createWallets() external payable;

    function totalWallets(address theAddress) external view returns (uint256);

    function isWhitelisted(address theAddress) external view returns (bool);

    function listWallets(address theAddress)
        external
        view
        returns (address[] memory);

    function executeOrder(
        uint256 startWallet,
        uint256 endWallet,
        bytes calldata theCallData,
        address whichContract
    ) external payable;

    function specialMint(
        uint256 startWallet,
        uint256 endWallet,
        bytes[] calldata theCallData,
        address whichContract
    ) external payable;

    function specialMintTwo(bytes[] calldata theCallData, address whichContract)
        external
        payable;

    function theTransfer(
        uint256 startWallet,
        uint256 endWallet,
        address to,
        uint256 startID,
        uint256 amount,
        address whichContract
    ) external;

    function theLoopMint(
        bytes calldata theCallData,
        address whichContract,
        uint256 _param1
    ) external payable;

    function theLoopTransfer(
        address to,
        uint256 startID,
        uint256 amountMinted,
        address whichContract
    ) external;

    function theTransferElevenFiftyFive(
        uint256 startWallet,
        uint256 endWallet,
        address to,
        uint256[] memory tokenIds,
        uint256[] memory amounts,
        address whichContract
    ) external;

    function theLoopTransferElevenFiftyFive(
        address to,
        uint256[] memory tokenIds,
        uint256[] memory amounts,
        address whichContract
    ) external;

    function withdraw(address tip, address to) external;
}

contract NFTee {
    address public owner;
    IMaster q;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Owner only");
        _;
    }

    function setOwner() external onlyOwner {
        owner = msg.sender;
    }

    function thePrice() external view returns (uint256) {
        return q.thePrice();
    }

    function isWhitelisted(address theAddress) external view returns (bool) {
        return q.isWhitelisted(theAddress);
    }

    function masterContract() external view returns (address) {
        return address(q);
    }

    /**
     * @dev Creates "wallets" that will be used for your mints
     */
    function createWallets() external payable {
        q.createWallets{value: msg.value}();
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
    function listWallets(address theAddress)
        external
        view
        returns (address[] memory)
    {
        return q.listWallets(theAddress);
    }

    /**
     * @dev Mint function to be used when the NFT has a wallet limit
     * @param startWallet Must equal to at least 0 and less than endWallet
     * @param endWallet See totalWallets() for maximum value
     * @param theCallData Hex data collected from the NFT contract
     * @param nftContract Address of the NFT contract
     */
    function mint_WalletLimit(
        uint256 startWallet,
        uint256 endWallet,
        bytes calldata theCallData,
        address nftContract
    ) external payable {
        q.executeOrder{value: msg.value}(
            startWallet,
            endWallet,
            theCallData,
            nftContract
        );
    }

    /**
     * @dev Mint function to be used when different calldata is used each wallet
     * @param startWallet Value used in mint function
     * @param endWallet Value used in mint function
     * @param theCallData Array of calldata
     * @param nftContract Address of the NFT contract
     */
    function mint_WalletLimitSpecial(
        uint256 startWallet,
        uint256 endWallet,
        bytes[] calldata theCallData,
        address nftContract
    ) external payable {
        q.specialMint{value: msg.value}(
            startWallet,
            endWallet,
            theCallData,
            nftContract
        );
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
    function transfer_WalletLimit(
        uint256 startWallet,
        uint256 endWallet,
        address to,
        uint256 startID,
        uint256 amountPerTX,
        address nftContract
    ) external {
        q.theTransfer(
            startWallet,
            endWallet,
            to,
            startID,
            amountPerTX,
            nftContract
        );
    }

    /**
     * @dev Mint function to be used when the NFT has no wallet limit
     * @param repeatNum Number of times to repeat mint
     * @param theCallData Hex data collected from the NFT contract
     * @param nftContract Address of the NFT contract
     */
    function mint_noWalletLimit(
        uint256 repeatNum,
        bytes calldata theCallData,
        address nftContract
    ) external payable {
        q.theLoopMint{value: msg.value}(theCallData, nftContract, repeatNum);
    }

    /**
     * @dev Mint function to be used when different calldata is used each transaction
     * @param theCallData Array of calldata
     * @param nftContract Address of the NFT contract
     */
    function mint_noWalletLimitSpecial(
        bytes[] calldata theCallData,
        address nftContract
    ) external payable {
        q.specialMintTwo{value: msg.value}(theCallData, nftContract);
    }

    /**
     * @dev Transfer function to be used when the NFT has no wallet limit
     * @param to Wallet to transfer the NFTs to
     * @param startID The start ID of the list of NFTs you minted
     * @param amountMinted Total amount of NFTs minted
     * @param nftContract Address of the NFT contract
     */
    function transfer_noWalletLimit(
        address to,
        uint256 startID,
        uint256 amountMinted,
        address nftContract
    ) external {
        q.theLoopTransfer(to, startID, amountMinted, nftContract);
    }

    /**
     * @dev Transfer function to be used when the NFT has no wallet limit (ERC-1155)
     * @param to Wallet to transfer the NFTs to
     * @param tokenIds Array of tokenIds
     * @param amounts Array of amounts
     * @param nftContract Address of the NFT contract
     */
    function transfer_noWalletLimit1155(
        address to,
        uint256[] memory tokenIds,
        uint256[] memory amounts,
        address nftContract
    ) external {
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
    function transfer_WalletLimit1155(
        uint256 startWallet,
        uint256 endWallet,
        address to,
        uint256[] memory tokenIds,
        uint256[] memory amounts,
        address nftContract
    ) external {
        q.theTransferElevenFiftyFive(
            startWallet,
            endWallet,
            to,
            tokenIds,
            amounts,
            nftContract
        );
    }

    function add(address theAddress) external onlyOwner {
        q.add(theAddress);
    }

    function remove(address theAddress) external onlyOwner {
        q.remove(theAddress);
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        q.setPrice(newPrice);
    }

    function setMasterContract(address contractAddress) external onlyOwner {
        q = IMaster(contractAddress);
    }

    function setAuxContract(address contractAddress) external onlyOwner {
        (bool success, ) = address(q).call(
            abi.encodeWithSelector(bytes4(0x4b53712a), contractAddress)
        );
        require(success, "Failed to set Aux contract");
    }

    function addWalletsForAddress(uint256 amount, address user)
        external
        onlyOwner
    {
        (bool success, ) = address(q).call(
            abi.encodeWithSelector(bytes4(0x5e0d09e9), amount, user)
        );
        require(success, "Failed to add more wallets");
    }

    function withdraw(address to) external onlyOwner {
        q.withdraw(to, to);
    }
}