// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./IJustOG101.sol";
import "./Ownable.sol";
import "./ERC721A.sol";
import "./ECDSA.sol";

contract JustOGBeta101 is Ownable,ERC721A,IJustOG101  {
    using ECDSA for bytes32;

    enum SaleStates{
        CLOSED,
        RAFFLE,
        PUBLIC
    }

    SaleStates public saleState;

    address private _signer;
    string private _baseTokenURI;


    bool public _isSaleActive = false;
    bool public _revealed = false;

    // Constants
    uint256 public constant RESERVED_TOKENS = 50;

    uint256 public MAX_SUPPLY = 100;
    uint256 public raffleSupply = 20;
    uint256 public maxWalletBalance = 3;
    uint256 public maxMint = 3;
    uint256 public publicMintCost = 0.02 ether;
    uint256 public wlPhaseMintCost = 0.01 ether;

    modifier checkState(SaleStates saleState_){
        if(msg.sender != tx.origin) revert NonEOA();
        if(saleState != saleState_) revert InvalidSaleState();
        _;
    }

    mapping(address => uint256) public teamClaim;

    event Minted(address indexed receiver, uint256 quantity);
    event SaleStateChanged(SaleStates saleState);

    constructor(address receciver) ERC721A("Just OG Meta","Just")
    {
        _mintERC2309(receciver, RESERVED_TOKENS);
    }


    /// @notice raffleMint
    function raffleMint(uint256 quantity, bytes calldata signature)
    external
    payable
    checkState(SaleStates.RAFFLE)
    {
        if (msg.value != quantity * wlPhaseMintCost) revert InvalidEtherAmount();
        if (_numberMinted(msg.sender) + quantity > maxWalletBalance) revert WalletLimitExceeded();
        if (_totalMinted() + quantity > raffleSupply) revert SupplyExceeded();
        if (!_verifySignature(signature, "RAFFLE")) revert InvalidSignature();

        _mint(msg.sender, quantity);

        emit Minted(msg.sender, quantity);
    }

    /// @notice Function used to mint tokens during the `PUBLIC` sale state.
    function publicMint(uint256 quantity, bytes calldata signature)
    external
    payable
    checkState(SaleStates.PUBLIC)
    {
        if (msg.value != quantity * publicMintCost) revert InvalidEtherAmount();
        if (_numberMinted(msg.sender) + quantity > maxWalletBalance)  revert WalletLimitExceeded();
        if (_totalMinted() + quantity > MAX_SUPPLY) revert SupplyExceeded();
        if (!_verifySignature(signature, "PUBLIC")) revert InvalidSignature();

        _mint(msg.sender, quantity);

        emit Minted(msg.sender, quantity);
    }

    /// @notice Function used by team members to claim their allocated tokens.
    /// @dev Forces team members to claim all of their allocated tokens at once.
    /// If a user has an invalid value (0) in the `teamClaim` mapping, call will
    /// revert within `_mint`. All team members will claim their tokens prior to
    /// the initiation of `publicMint`. Otherwise, they may be unable to claim.
    function teamMint() external {
        uint256 quantity = teamClaim[msg.sender];

        /// @dev Reset value to 0 for gas refund.
        delete teamClaim[msg.sender];

        if (_totalMinted() + quantity > MAX_SUPPLY) revert SupplyExceeded();

        _mint(msg.sender, quantity);

        emit Minted(msg.sender, quantity);
    }


    /// @notice Function used to mint tokens free of charge.
    function ownerMint(address receiver, uint256 quantity) external onlyOwner {
        if (_totalMinted() + quantity > MAX_SUPPLY) revert SupplyExceeded();

        _mint(receiver, quantity);
    }

    /// @notice Function used to set a new `_signer` value.
    /// @param newSigner Newly desired `_signer` value.
    function setSigner(address newSigner) external onlyOwner {
        _signer = newSigner;
    }

    /// @notice Function used to change the current `saleState` value.
    /// @param newSaleState The new `saleState` value.
    /// @dev 0 = CLOSED, 1 = RAFFLE, 3 = PUBLIC
    function setSaleState(uint256 newSaleState) external onlyOwner {
        if (newSaleState > uint256(SaleStates.PUBLIC))
            revert InvalidSaleState();

        saleState = SaleStates(newSaleState);

        emit SaleStateChanged(saleState);
    }


    /// @notice Function used to check the number of tokens `account` has minted.
    function numberMinted(address account) external view returns (uint256) {
        return _numberMinted(account);
    }

    /// @notice Function used to view the current `_signer` value.
    function signer() external view returns (address) {
        return _signer;
    }

    /// @notice Function used to set the amount of tokens a team member can claim.
    function setTeamClaim(
        address[] calldata members,
        uint256[] calldata quantitys
    ) external onlyOwner {
        if (members.length != quantitys.length) revert ArrayLengthMismatch();

        address member;
        uint256 quantity;

    unchecked {
        for (uint256 i = 0; i < members.length; i++) {
            member = members[i];
            quantity = quantitys[i];

            teamClaim[member] = quantity;
        }
    }
    }
    /// @notice Function used to set a new `MAX_SUPPLY` value.
    /// @param amount Newly intended `MAX_SUPPLY` value.
    /// @dev No more than 10,000 tokens, EVER!
    function setMaxSupply(uint256 amount) external onlyOwner {
        if (amount > 10000) revert InvalidTokenCap();
        MAX_SUPPLY = amount;
    }

    /// @notice Function used to set a new `raffleSupply` value.
    /// @param amount Newly intended `raffleSupply` value.
    function setRaffleSupply(uint256 amount) external onlyOwner {
        if (amount > 5000) revert InvalidTokenCap();
        raffleSupply = amount;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");

        if (!success) revert WithdrawFailed();
    }

    function changePublicPrice(uint256 newPrice) external onlyOwner {
        publicMintCost = newPrice;
    }

    function changeWLPrice(uint256 newPrice) external onlyOwner {
        wlPhaseMintCost = newPrice;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function _verifySignature(bytes memory signature, string memory phase)
    internal
    view
    returns (bool)
    {
        return
        _signer ==
        keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                bytes32(abi.encodePacked(msg.sender, phase))
            )
        ).recover(signature);
    }

}