//SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "Ownable.sol";
import "ECDSA.sol";
import "ERC721A.sol";



interface INft is IERC721A {
    error InvalidEtherAmount();
    error InvalidNewPrice();
    error InvalidSaleState();
    error NonEOA();
    error InvalidTokenCap();
    error InvalidSignature();
    error SupplyExceeded();
    error TokenClaimed();
    error WalletLimitExceeded();
    error WithdrawFailedArtist();
    error WithdrawFailedDev();
    error WithdrawFailedFounder();
    error WithdrawFailedVault();
}


contract TMSG is INft, Ownable, ERC721A {
    using ECDSA for bytes32;

    enum SaleStates {
        CLOSED,
        PUBLIC
    }

    SaleStates public saleState;

    uint256 public maxSupply = 9999;
    uint256 public publicPrice = 0.059 ether;

    uint64 public WALLET_MAX = 20;

    string private _baseTokenURI;
    string private baseExtension = ".json";

    bool public revealed = false;

    event Minted(address indexed receiver, uint256 quantity);
    event SaleStateChanged(SaleStates saleState);

    constructor(address receiver) ERC721A("TestMintSaveGas", "TMSG") {
    }


    /// @notice Function used during the public mint
    /// @param quantity Amount to mint.
    /// @dev checkState to check sale state.
    function Mint(uint64 quantity)
        external
        payable
        checkState(SaleStates.PUBLIC)
    {
        if (msg.value != quantity * publicPrice) revert InvalidEtherAmount();
        if ((_numberMinted(msg.sender) - _getAux(msg.sender)) + quantity > WALLET_MAX)
            revert WalletLimitExceeded();
        if (_totalMinted() + quantity > maxSupply) revert SupplyExceeded();

        (bool success, ) = owner().call{value: msg.value}("");
        require(success, "WITHDRAW FAILED!");

        if(quantity>=10){
            _mintERC2309(msg.sender, quantity);
            }
        else _mint(msg.sender, quantity);


        emit Minted(msg.sender, quantity);
    }

    /// @notice Function used to mint free tokens to any address.
    /// @param receiver address to mint to.
    /// @param quantity number to mint.
    function Airdrop(address receiver, uint256 quantity) external onlyOwner {
        if (_totalMinted() + quantity > maxSupply) revert SupplyExceeded();
        _mintERC2309(receiver, quantity);
    }

    
    /// @notice Fail-safe withdraw function, incase withdraw() causes any issue.
    /// @param receiver address to withdraw to.
    function withdrawTo(address receiver) public onlyOwner {        
        (bool withdrawalSuccess, ) = payable(receiver).call{value: address(this).balance}("");
        if (!withdrawalSuccess) revert WithdrawFailedVault();
    }

    /// @notice Function used to set a new `maxSupply` value.
    /// @param newMaxSupply Newly intended `maxSupply` value.
    function setMaxSupply(uint256 newMaxSupply) external onlyOwner {
        maxSupply = newMaxSupply;
    }

    /// @notice Function used to set a new `WALLET_MAX` value.
    /// @param newMaxWallet Newly intended `WALLET_MAX` value.
    function setMaxWallet(uint64 newMaxWallet) external onlyOwner {
        WALLET_MAX = newMaxWallet;
    }


    /// @notice Function used to change mint public price.
    /// @param newPublicPrice Newly intended `publicPrice` value.
    /// @dev Price can never exceed the initially set mint public price (0.069E), and can never be increased over it's current value.
    function changePublicPrice(uint256 newPublicPrice) external onlyOwner {
        publicPrice = newPublicPrice;
    }

    /// @notice Function used to check the number of tokens `account` has minted.
    /// @param account Account to check balance for.
    function numberMinted(address account) external view returns (uint256) {
        return _numberMinted(account);
    }


    /// @notice Function used to view the current `_baseTokenURI` value.
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /// @notice Sets base token metadata URI.
    /// @param baseURI New base token URI.
    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }


    /// @notice Function used to change the current `saleState` value.
    /// @param newSaleState The new `saleState` value.
    /// @dev 0 = CLOSED, 1 = PUBLIC
    function setSaleState(uint256 newSaleState) external onlyOwner {
        if (newSaleState > uint256(SaleStates.PUBLIC))
            revert InvalidSaleState();

        saleState = SaleStates(newSaleState);

        emit SaleStateChanged(saleState);
    }


    /// @notice Verifies the current state.
    /// @param saleState_ Sale state to verify. 
    modifier checkState(SaleStates saleState_) {
        if (msg.sender != tx.origin) revert NonEOA();
        if (saleState != saleState_) revert InvalidSaleState();
        _;
    }

    /// @notice Sets the revealed flag and updates token base URI.
    /// @param baseURI New base token URI.
    function reveal(string calldata baseURI) external onlyOwner {
        revealed = true;
        _baseTokenURI = baseURI;
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) public view override(ERC721A, IERC721A) returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        if (revealed){
            string memory baseURI = _baseURI();
            return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId),baseExtension)) : ''; 
        } else {
            return _baseURI();
        }
    }
}