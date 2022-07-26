/**
 *Submitted for verification at Etherscan.io on 2022-07-26
*/

// File: caller.sol


pragma solidity ^0.8.7;

interface IERC20 {
    function mint(uint256 _amount, address _mintTo) external;

    function burnFrom(address _burnFrom, uint256 _amount) external;

    function transferFrom(
        address _farmerWallet,
        address _varahaWallet,
        uint256 _amount
    ) external;

    function transferWithRoyalites(address _sender, address _recipient, uint256 _amount) external;
}

interface IERC721 {
    function safeMint(address _creditBuyer, string memory _tokenURI) external;
}

contract VarahaOps {
    uint256 constant varahaRoyalty = 30;
    uint256 constant farmerRoyalty = 70;
    uint256 constant transferRoyalty = 10;
    address varahaWallet;
    address owner;

    IERC20 ccTokenAddress;
    IERC721 ccNftAddress;

    constructor(IERC20 _ccTokenAddress, IERC721 _ccNftAddress) {
        owner = msg.sender;
        ccTokenAddress = _ccTokenAddress;
        ccNftAddress = _ccNftAddress;
    }

    // allow contract to receive ethers for paying gas fees(during allowance and transfer)
    receive() external payable {}

    // set Varaha Wallet
    function setVarahaWalletAddress(address _newWalletAddress)
        external
        onlyOwner
    {
        varahaWallet = _newWalletAddress;
    }

    function mintERC20Token(uint256 _amount, address _mintTo)
        external
        onlyVaraha
    {
        ccTokenAddress.mint(_amount, _mintTo);
    }

    function transferTokens(address _sender, address _recipient, uint256 _amount) external {
        uint256 _varahaTransferRoyaltyAmount = (_amount * transferRoyalty) / 100;
        uint256 _finalTransferAmount = _amount - _varahaTransferRoyaltyAmount;

        ccTokenAddress.transferFrom(
            _sender,
            varahaWallet,
            _varahaTransferRoyaltyAmount
        );

        ccTokenAddress.transferWithRoyalites(_sender, _recipient, _finalTransferAmount);
    }

    // can be called after approval of farmer
    function burnERC20Token(uint256 _burnAmount, address _burnFrom)
        external
        onlyVaraha
    {
        ccTokenAddress.burnFrom(_burnFrom, _burnAmount);
    }

    // mint PDF to customer wallet
    function mintERC721(string memory _tokenURI, address _creditBuyer)
        external
        onlyVaraha
    {
        ccNftAddress.safeMint(_creditBuyer, _tokenURI);
    }

    /**
     * Take allowance of _tokenAmount from farmerWallet
     * Transfer varahaRoyaltyAmount to varahaWallet
     * Burn remaining tokens
     * * * * Figure out rest of tokenomics * * *
     */
    // take royalty first, then burn remaining amount of tokens
    function burnAndTransferTokens(
        uint256 _tokenAmount,
        address _farmerWallet,
        string memory _tokenURI,
        address _creditBuyer
    ) external onlyVaraha {
        uint256 varahaRoyaltyAmount = (_tokenAmount * varahaRoyalty) / 100;
        uint256 finalBurnTokenAmount = _tokenAmount - varahaRoyaltyAmount;
        ccTokenAddress.transferFrom(
            _farmerWallet,
            varahaWallet,
            varahaRoyaltyAmount
        );

        ccTokenAddress.burnFrom(_farmerWallet, finalBurnTokenAmount);
        ccNftAddress.safeMint(_creditBuyer, _tokenURI);
    }

    /** Modifiers */
    modifier onlyOwner() {
        require(owner == msg.sender, "Not Allowed!");
        _;
    }

    modifier onlyVaraha() {
        require(msg.sender == varahaWallet, "Not Allowed!");
        _;
    }
}