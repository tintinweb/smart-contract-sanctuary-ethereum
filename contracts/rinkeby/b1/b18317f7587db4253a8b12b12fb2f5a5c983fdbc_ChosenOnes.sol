// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BaseERC721.sol";

contract ChosenOnes is
    ERC721,
    ERC721Enumerable,
    Pausable,
    AccessControl,
    EIP712,
    ERC721URIStorage
{
    using Strings for uint256;
    // using StringsUpgradeable for uint256;

    struct Voucher {
        bool everybody;
        address minter;
        uint256 wallet_limit; // 0 means no limit
        uint256 price;
    }

    // ROLES
    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");
    bytes32 public constant BURN_ROLE = keccak256("BURN_ROLE");
    bytes32 public constant SIGNER_ROLE = keccak256("SIGNER_ROLE");
    bytes32 public constant WITHDRAW_ROLE = keccak256("WITHDRAW_ROLE");

    // DATA Setting
    address payable private treasury;
    string private base_uri;
    uint256 private max;
    mapping(address => uint256[]) address_tokens;

    constructor() ERC721("Chosen Ones", "CO") EIP712("Chosen Ones", "1.0.0") {
        address owner = address(msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, owner);
        _setupRole(OWNER_ROLE, owner);
        _setupRole(BURN_ROLE, owner);
        _setupRole(SIGNER_ROLE, owner);
        _setupRole(WITHDRAW_ROLE, owner);

        treasury = payable(owner);
        base_uri = "https://nft.chosenones.io/api/";
        max = 10000;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, AccessControl, ERC721Enumerable)
        returns (bool)
    {
        return
            ERC721.supportsInterface(interfaceId) ||
            AccessControl.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721Enumerable, ERC721) {
        super._beforeTokenTransfer(from, to, tokenId);
        delete address_tokens[from][tokenId];
        address_tokens[to].push(tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
        onlyRole(BURN_ROLE)
    {
        delete address_tokens[msg.sender][tokenId];
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    // Setting
    function GetTreasury() public view returns (address payable) {
        return treasury;
    }

    function SetTreasury(address payable value) public onlyRole(OWNER_ROLE) {
        treasury = value;
    }

    function GetBaseURI() public view returns (string memory) {
        return base_uri;
    }

    function SetBaseURI(string memory value) public onlyRole(OWNER_ROLE) {
        base_uri = value;
    }

    function GetMax() public view returns (uint256) {
        return max;
    }

    function SetMax(uint256 value) public onlyRole(OWNER_ROLE) {
        max = value;
    }

    function GetTokens(address owner) public view returns (uint256[] memory) {
        return address_tokens[owner];
    }

    // MINT
    function mint(
        Voucher memory voucher,
        uint256 count,
        bytes memory Signature
    ) public payable whenNotPaused {
        // Inputs
        require(count > 0, "Count can not be less than 1.");
        require(
            hasRole(
                SIGNER_ROLE,
                ECDSA.recover(_hash(voucher), Signature)
            ),
            "Signature is not valid."
        );
        uint256 balance = totalSupply();
        require(balance < max, "All tokens in the drop have been sold out.");
        require(
            balance + count <= max,
            "Insufficient count of token requested."
        );

        // Voucher
        require(
            voucher.everybody || voucher.minter == address(voucher.minter),
            "You are not a valid minter."
        );
        require(
            voucher.wallet_limit == 0 ||
                balanceOf(msg.sender) + count <= voucher.wallet_limit,
            "drop.wallet_limit is exceeded."
        );
        require(voucher.price * count <= msg.value, "Drop price is not valid");

        // Mint
        for (uint256 index = 0; index < count; index++) {
            uint256 next = totalSupply();
            address_tokens[msg.sender].push(next);
            _mint(msg.sender, next);
        }
    }

    function withdraw(uint256 amount)
        public
        onlyRole(WITHDRAW_ROLE)
        whenNotPaused
    {
        treasury.transfer(amount);
    }

    function withdrawAll() public onlyRole(WITHDRAW_ROLE) {
        withdraw(address(this).balance);
    }

    function _hash(Voucher memory voucher) internal view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "Voucher(bool everybody,address minter,uint256 wallet_limit,uint256 price)"
                        ),
                        voucher.everybody,
                        voucher.minter,
                        voucher.wallet_limit,
                        voucher.price
                    )
                )
            );
    }
}